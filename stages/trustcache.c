#include <CoreFoundation/CoreFoundation.h>
#include <mach/mach.h>
#include <dlfcn.h>
#include <Security/Security.h>

#include "trustcache.h"
#include "CSCommon.h"
#include "physpuppet/libprejailbreak.h"
#include "log.h"

OSStatus SecStaticCodeCreateWithPathAndAttributes(CFURLRef path, SecCSFlags flags, CFDictionaryRef attributes, SecStaticCodeRef  _Nullable *staticCode);
OSStatus SecCodeCopySigningInformation(SecStaticCodeRef code, SecCSFlags flags, CFDictionaryRef  _Nullable *information);
CFStringRef (*_SecCopyErrorMessageString)(OSStatus status, void * __nullable reserved) = NULL;
 
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

uint8_t *cdhashFor(const char *filePath) {
    CFStringRef cfFile = CFStringCreateWithCString(kCFAllocatorDefault, filePath, kCFStringEncodingUTF8);
    CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, cfFile,
                                                 kCFURLPOSIXPathStyle, false);
    CFRelease(cfFile);
    if (!url) {
        return NULL;
    }

    SecStaticCodeRef staticCode = NULL;
    OSStatus status = SecStaticCodeCreateWithPathAndAttributes(url,
                          kSecCSDefaultFlags, NULL, &staticCode);
    CFRelease(url);
    if (status != errSecSuccess) {
        if (_SecCopyErrorMessageString) {
            CFStringRef errStr = _SecCopyErrorMessageString(status, NULL);
            char buf[256] = {0};
            if (errStr &&
                CFStringGetCString(errStr, buf, sizeof(buf), kCFStringEncodingUTF8)) {
            }
            if (errStr) CFRelease(errStr);
        }
        return NULL;
    }

    CFDictionaryRef info = NULL;
    status = SecCodeCopySigningInformation(staticCode,
                                           kSecCSDefaultFlags, &info);
    CFRelease(staticCode);
    if (status != errSecSuccess || !info) {
        if (info) CFRelease(info);
        return NULL;
    }

    CFArrayRef cdhashes = CFDictionaryGetValue(info, CFSTR("cdhashes"));
    CFArrayRef algos    = CFDictionaryGetValue(info, CFSTR("digest-algorithms"));
    char *hexResult = NULL;
    uint8_t *bytes = NULL;

    if (!cdhashes) {
        return NULL;
    } else if (!algos) {
        return NULL;
    } else {
        CFIndex count = CFArrayGetCount(algos);
        CFIndex idx = -1;
        for (CFIndex i = 0; i < count; i++) {
            CFNumberRef num = CFArrayGetValueAtIndex(algos, i);
            int algoVal = -1;
            if (CFNumberGetValue(num, kCFNumberIntType, &algoVal)
                && algoVal == requiredHash) {
                idx = i;
                break;
            }
        }

        if (idx < 0) {
            // LOG("%s: does not have %s hash\n",
            //     filePath, cdHashName[requiredHash]);
        } else {
            CFTypeRef obj = CFArrayGetValueAtIndex(cdhashes, idx);
            if (CFGetTypeID(obj) != CFDataGetTypeID()) {
                // LOG("%s: expected CFDataRef for cdhash\n", filePath);
            } else {
                CFDataRef data = (CFDataRef)obj;
                CFIndex len = CFDataGetLength(data);
                bytes = CFDataGetBytePtr(data);
            }
        }
    }

    CFRelease(info);
    return bytes;
}

int inject_trustcache(char *path, uint64_t trust_chain) {
    dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_NOW);

    struct trust_mem mem;
    uint64_t kernel_trust = 0;

    mem.next = kread64(trust_chain);
    mem.count = 1;
    *(uint64_t *)&mem.uuid[0] = 0xabadbabeabadbabe;
    *(uint64_t *)&mem.uuid[8] = 0xabadbabeabadbabe;

    int errors=0;

    char *cdhash = cdhashFor(path);

    size_t length = (sizeof(mem) + TRUST_CDHASH_LEN + 0xFFFF) & ~0xFFFF;
    char *buffer = malloc(TRUST_CDHASH_LEN);
    if (buffer == NULL) {
        return -3;
    }
    char *curbuf = buffer;
    memcpy(curbuf, cdhash, TRUST_CDHASH_LEN);
    curbuf += TRUST_CDHASH_LEN;
    kernel_trust = kalloc(length);

    kwritebuf(kernel_trust, &mem, sizeof(mem));
    kwritebuf(kernel_trust + sizeof(mem), buffer, TRUST_CDHASH_LEN);
    kwrite64(trust_chain, kernel_trust);

    return (int)errors;
}