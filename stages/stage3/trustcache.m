/*
 *  inject.m
 *  
 *  Created by Sam Bingner on 9/27/2018
 *  Copyright 2018 Sam Bingner. All Rights Reserved.
 *
 */

#include <Foundation/Foundation.h>
#include <mach/mach.h>
#include <dlfcn.h>

#include "trustcache.h"
#include "stage3.h"
#include "krw.h"
#include "CSCommon.h"

OSStatus SecStaticCodeCreateWithPathAndAttributes(CFURLRef path, SecCSFlags flags, CFDictionaryRef attributes, SecStaticCodeRef  _Nullable *staticCode);
OSStatus SecCodeCopySigningInformation(SecStaticCodeRef code, SecCSFlags flags, CFDictionaryRef  _Nullable *information);
CFStringRef (*_SecCopyErrorMessageString)(OSStatus status, void * __nullable reserved) = NULL;
// extern int MISValidateSignatureAndCopyInfo(NSString *file, NSDictionary *options, NSDictionary **info);

extern NSString *MISCopyErrorStringForErrorCode(int err);
extern NSString *kMISValidationOptionRespectUppTrustAndAuthorization;
extern NSString *kMISValidationOptionValidateSignatureOnly;
extern NSString *kMISValidationOptionUniversalFileOffset;
extern NSString *kMISValidationOptionAllowAdHocSigning;
extern NSString *kMISValidationOptionOnlineAuthorization;
 
enum cdHashType {
    cdHashTypeSHA1 = 1,
    cdHashTypeSHA256 = 2
};

static char *cdHashName[3] = {NULL, "SHA1", "SHA256"};

static enum cdHashType requiredHash = cdHashTypeSHA256;

#define TRUST_CDHASH_LEN (20)
 
struct trust_mem {
    uint64_t next; //struct trust_mem *next;
    unsigned char uuid[16];
    unsigned int count;
    //unsigned char data[];
} __attribute__((packed));

struct hash_entry_t {
    uint16_t num;
    uint16_t start;
} __attribute__((packed));

typedef uint8_t hash_t[TRUST_CDHASH_LEN];

NSString *cdhashFor(NSString *file) {
    NSString *cdhash = nil;
    SecStaticCodeRef staticCode;
    OSStatus result = SecStaticCodeCreateWithPathAndAttributes(CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)file, kCFURLPOSIXPathStyle, false), kSecCSDefaultFlags, NULL, &staticCode);
    const char *filename = file.UTF8String;
    if (result != errSecSuccess) {
        if (_SecCopyErrorMessageString != NULL) {
            CFStringRef error = _SecCopyErrorMessageString(result, NULL);
            LOG(@"Unable to generate cdhash for %s: %s\n", filename, [(__bridge id)error UTF8String]);
            CFRelease(error);
        } else {
            LOG(@"Unable to generate cdhash for %s: %d\n", filename, result);
        }
        return nil;
    }
    
    CFDictionaryRef cfinfo;
    result = SecCodeCopySigningInformation(staticCode, kSecCSDefaultFlags, &cfinfo);
    NSDictionary *info = CFBridgingRelease(cfinfo);
    CFRelease(staticCode);
    if (result != errSecSuccess) {
        LOG(@"Unable to copy cdhash info for %s\n", filename);
        return nil;
    }
    NSArray *cdhashes = info[@"cdhashes"];
    NSArray *algos = info[@"digest-algorithms"];
    NSUInteger algoIndex = [algos indexOfObject:@(requiredHash)];
    
    if (cdhashes == nil) {
        LOG(@"%s: no cdhashes\n", filename);
    } else if (algos == nil) {
        LOG(@"%s: no algos\n", filename);
    } else if (algoIndex == NSNotFound) {
        LOG(@"%s: does not have %s hash\n", cdHashName[requiredHash], filename);
    } else {
        cdhash = [cdhashes objectAtIndex:algoIndex];
        if (cdhash == nil) {
            LOG(@"%s: missing %s cdhash entry\n", file.UTF8String, cdHashName[requiredHash]);
        }
    }
    LOG(@"Got cdhash: %@", cdhash);
    return cdhash;
}

NSArray *filteredHashes(uint64_t trust_chain, NSDictionary *hashes) {
#if !__has_feature(objc_arc)
  NSArray *result;
  @autoreleasepool {
#endif
    NSMutableDictionary *filtered = [hashes mutableCopy];

    struct trust_mem search;
    search.next = trust_chain;
    while (search.next != 0) {
        uint64_t searchAddr = search.next;
        kreadbuf(searchAddr, &search, sizeof(struct trust_mem));
        //printf("Checking %d entries at 0x%llx\n", search.count, searchAddr);
        char *data = malloc(search.count * TRUST_CDHASH_LEN);
        kreadbuf(searchAddr + sizeof(struct trust_mem), data, search.count * TRUST_CDHASH_LEN);
        size_t data_size = search.count * TRUST_CDHASH_LEN;

        for (char *dataref = data; dataref <= data + data_size - TRUST_CDHASH_LEN; dataref += TRUST_CDHASH_LEN) {
            NSData *cdhash = [NSData dataWithBytesNoCopy:dataref length:TRUST_CDHASH_LEN freeWhenDone:NO];
            NSString *hashName = filtered[cdhash];
            if (hashName != nil) {
                LOG(@"%s: already in dynamic trustcache, not reinjecting\n", [hashName UTF8String]);
                [filtered removeObjectForKey:cdhash];
                if ([filtered count] == 0) {
                    free(data);
                    return nil;
                }
            }
        }
        free(data);
    }
    LOG(@"Actually injecting %lu keys\n", [[filtered allKeys] count]);
#if __has_feature(objc_arc)
    return [filtered allKeys];
#else
    result = [[filtered allKeys] retain];
  }
  return [result autorelease];
#endif
}

int injectTrustCache(NSArray <NSString*> *files, uint64_t trust_chain) {
    dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_NOW);

    struct trust_mem mem;
    uint64_t kernel_trust = 0;

    mem.next = kread64(trust_chain);
    mem.count = 0;
    *(uint64_t *)&mem.uuid[0] = 0xabadbabeabadbabe;
    *(uint64_t *)&mem.uuid[8] = 0xabadbabeabadbabe;
    NSMutableDictionary *hashes = [NSMutableDictionary new];
    int errors=0;

    for (NSString *file in files) {
        NSString *cdhash = cdhashFor(file);
        if (cdhash == nil) {
            errors++;
        } else {
            if (hashes[cdhash] == nil) {
                LOG(@"%s: OK\n", file.UTF8String);
                hashes[cdhash] = file;
            } else {
                LOG(@"%s: same as %s (ignoring)", file.UTF8String, [hashes[cdhash] UTF8String]);
            }
        }
    }
    unsigned numHashes = (unsigned)[hashes count];

    if (numHashes < 1) {
        LOG(@"Found no hashes to inject\n");
        return errors;
    }


    NSArray *filtered = filteredHashes(mem.next, hashes);
    unsigned hashesToInject = (unsigned)[filtered count];
    LOG(@"%u new hashes to inject\n", hashesToInject);
    if (hashesToInject < 1) {
        return errors;
    }

    size_t length = (sizeof(mem) + hashesToInject * TRUST_CDHASH_LEN + 0xFFFF) & ~0xFFFF;
    char *buffer = malloc(hashesToInject * TRUST_CDHASH_LEN);
    if (buffer == NULL) {
        LOG(@"Unable to allocate memory for cdhashes: %s\n", strerror(errno));
        return -3;
    }
    char *curbuf = buffer;
    for (NSData *hash in filtered) {
        memcpy(curbuf, [hash bytes], TRUST_CDHASH_LEN);
        curbuf += TRUST_CDHASH_LEN;
    }
    kernel_trust = kalloc_wired(length);

    mem.count = hashesToInject;
    kwritebuf(kernel_trust, &mem, sizeof(mem));
    kwritebuf(kernel_trust + sizeof(mem), buffer, mem.count * TRUST_CDHASH_LEN);
    kwrite64(trust_chain, kernel_trust);

    return (int)errors;
}