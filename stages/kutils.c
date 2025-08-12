#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <mach/mach.h>
#include <asl.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CommonCrypto/CommonDigest.h>
#include <sys/stat.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <spawn.h>

#include "common.h"
#include "csblob.h"
#include "physpuppet/libprejailbreak.h"
#include "physpuppet/utils.h"

void set_csflags(uint64_t proc) {
    uint32_t csflags = kread32(proc + koffsetof(proc, csflags));
    csflags = (csflags | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW | CS_DEBUGGED) & ~(CS_RESTRICT | CS_HARD | CS_KILL);
    kwrite32(proc + koffsetof(proc, csflags), csflags);
}

void set_tfplatform(uint64_t proc) {
    // task.t_flags & TF_PLATFORM
    uint64_t task = kread64(proc + koffsetof(proc, task));
    uint32_t t_flags = kread32(task + koffsetof(task, flags));
    
    t_flags |= TF_PLATFORM;
    kwrite32(task+koffsetof(task, flags), t_flags);
}

const uint64_t kernel_address_space_base = 0xffff000000000000;
void kmemcpy(uint64_t dest, uint64_t src, uint32_t length) {
    if (dest >= kernel_address_space_base) {
        // copy to kernel:
        kwritebuf(dest, (void*) src, length);
    } else {
        // copy from kernel
        kreadbuf(src, (void*)dest, length);
    }
}

uint64_t borrow_ucreds(pid_t to_pid, pid_t from_pid) {
    uint64_t to_proc = proc_find(to_pid);
    uint64_t from_proc = proc_find(from_pid);
    
    uint64_t to_ucred = kread64(to_proc + koffsetof(proc, ucred));
    uint64_t from_ucred = kread64(from_proc + koffsetof(proc, ucred));
    
    kwrite64(to_proc + koffsetof(proc, ucred), from_ucred);
    
    return to_ucred;
}

void unborrow_ucreds(pid_t to_pid, uint64_t to_ucred) {
    uint64_t to_proc = proc_find(to_pid);
    
    kwrite64(to_proc + koffsetof(proc, ucred), to_ucred);
}
