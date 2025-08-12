#include <stdint.h>
#include <unistd.h>
#include <stdbool.h>
#include "offsets.h"
#include "krw.h"

extern uint64_t g_kernproc;
extern uint64_t g_kbase;

uint64_t g_allproc = 0;

uint64_t proc_of_pid(pid_t pid) {
    uint64_t proc = g_kernproc;
    if(pid == 0) return g_kernproc;
    
    while (true) {
        if(kread32(proc + off_p_pid) == pid) {
            return proc;
        }
        proc = kread64(proc + off_p_list_le_prev);
        if(!proc) {
            return -1;
        }
    }
    
    return 0;
}

uint64_t proc_by_name(char* nm) {
    uint64_t proc = g_kernproc;
    
    while (true) {
        uint64_t nameptr = proc + off_p_comm;
        char name[40];
        kreadbuf(nameptr, &name, 40);
        if(strcmp(name, nm) == 0) {
            return proc;
        }
        proc = kread64(proc + off_p_list_le_prev);
        if(!proc) {
            return -1;
        }
    }
    
    return 0;
}

pid_t pid_by_name(char* nm) {
    uint64_t proc = proc_by_name(nm);
    if(proc == -1) return -1;
    return kread32(proc + off_p_pid);
}

uint64_t get_allproc(void) {
    if(g_allproc != 0)  return g_allproc;

    NSData *blob = [NSData dataWithContentsOfFile:@"/chimera/jailbreakd.plist"];
    if (!blob) return 0;

    NSError *err = nil;
    NSDictionary *job = [NSPropertyListSerialization
                         propertyListWithData:blob
                         options:0
                         format:NULL
                         error:&err];

    NSDictionary *env = job[@"EnvironmentVariables"];
    NSString *old_kbaseStr     = env[@"KernelBase"];
    NSString *old_allprocStr = env[@"AllProc"];

    uint64_t old_kbase = strtoull([old_kbaseStr UTF8String], NULL, 0);
    uint64_t old_allproc = strtoull([old_allprocStr UTF8String], NULL, 0);
    uint64_t old_kslide = old_kbase - 0xfffffff007004000;

    uint64_t kslide = g_kbase - 0xfffffff007004000;

    uint64_t allproc = (old_allproc - old_kslide) + kslide;
    g_allproc = allproc;
    return g_allproc;
}