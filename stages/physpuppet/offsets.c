#include "offsets.h"
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <sys/utsname.h>
#include <sys/sysctl.h>
#include <mach/mach.h>

struct KernelOffsets gOffsets = { 0 };

bool gOffsetsInitialised = false;

uint64_t offsets_find(const char *name, uint64_t value) {
    if (!gOffsetsInitialised) {
        value = -1;
    }
    return value;
}

#define CPUFAMILY_ARM_CYCLONE               0x37a09642 // A7
#define CPUFAMILY_ARM_TYPHOON               0x2c91a47e // A8
#define CPUFAMILY_ARM_TWISTER               0x92fb37c8 // A9
#define CPUFAMILY_ARM_HURRICANE             0x67ceee93 // A10
#define CPUFAMILY_ARM_MONSOON_MISTRAL       0xe81e7ef6 // A11
#define CPUFAMILY_ARM_VORTEX_TEMPEST        0x07d34b9f // A12
#define CPUFAMILY_ARM_LIGHTNING_THUNDER     0x462504d2 // A13
#define CPUFAMILY_ARM_FIRESTORM_ICESTORM    0x1b588bb3 // A14
#define CPUFAMILY_ARM_BLIZZARD_AVALANCHE    0xda33d83d // A15
#define CPUFAMILY_ARM_EVEREST_SAWTOOTH      0x8765edea // A16
#define CPUFAMILY_ARM_COLL                  0x2876f5b5 // A17

void offsets_init(void) {
    if (gOffsetsInitialised) return;

    memset(&gOffsets, -1, sizeof(struct KernelOffsets));
    gOffsets.isArm64e = false;
    struct utsname u;
    uname(&u);

    if (sscanf(u.release, "%d.%d.%d", &gOffsets.major, &gOffsets.minor, &gOffsets.patch) != 3) {
        return;
    }

    cpu_subtype_t cpu_family = 0;
    size_t cpu_size = sizeof(cpu_family);
    sysctlbyname("hw.cpufamily", &cpu_family, &cpu_size, 0, 0);

    switch (cpu_family) {
        case CPUFAMILY_ARM_VORTEX_TEMPEST:
        case CPUFAMILY_ARM_LIGHTNING_THUNDER:
        case CPUFAMILY_ARM_FIRESTORM_ICESTORM:
        case CPUFAMILY_ARM_BLIZZARD_AVALANCHE:
        case CPUFAMILY_ARM_EVEREST_SAWTOOTH:
        case CPUFAMILY_ARM_COLL:
            gOffsets.isArm64e = true;
            break;
        default:
            break;
    }

    gOffsets.proc.next = 0x0;
    gOffsets.proc.prev = 0x8;
    gOffsets.proc.pid = 0x60;
    gOffsets.proc.task = 0x10;
    gOffsets.proc.ucred = 0xF8;
    gOffsets.proc.fd = 0x100;
    gOffsets.proc.csflags = 0x290;

    gOffsets.task.lck_mtx_type = 0xb;
    gOffsets.task.ref_count = 0x10;
    gOffsets.task.active = 0x14;
    gOffsets.task.vm_map = 0x20;
    gOffsets.task.itk_self = 0xD8;
    gOffsets.task.itk_space = 0x300;
    gOffsets.task.bsd_info = gOffsets.isArm64e ? 0x368 : 0x358;
    gOffsets.task.flags = gOffsets.isArm64e ? 0x400 : 0x390;

    gOffsets.vm_map.pmap = 0x48;

    gOffsets.pmap.tte = 0x0;
    gOffsets.pmap.ttep = 0x8;

    gOffsets.ipc_space.table = 0x20;
    
    gOffsets.ipc_port.io_bits = 0x0;
    gOffsets.ipc_port.kobject = 0x68;
    gOffsets.ipc_port.receiver = 0x60;
    gOffsets.ipc_port.ikmq_base = 0x40;
    gOffsets.ipc_port.srights = 0xA0;
    gOffsets.ipc_port.references = 0x4;

    gOffsets.ucred.uid = 0x18;
    gOffsets.ucred.ruid = 0x1C;
    gOffsets.ucred.svuid = 0x20;
    gOffsets.ucred.groups = 0x28;
    gOffsets.ucred.rgid = 0x68;
    gOffsets.ucred.svgid = 0x6C;
    gOffsets.ucred.label = 0x78;

    gOffsets.vnode.ubcinfo = 0x78;
    gOffsets.vnode.specinfo = 0x78;
    gOffsets.vnode.name = 0xB8;
    gOffsets.vnode.parent = 0xC0;
    gOffsets.vnode.mount = 0xD8;
    gOffsets.vnode.data = 0xE0;
    gOffsets.vnode.nclinks = 0x40;
    gOffsets.vnode.holdcount = 0xB4;

    gOffsets.ubcinfo.csblobs = 0x50;

    gOffsets.csblob.cputype = 0x8;
    gOffsets.csblob.flags = 0x12;
    gOffsets.csblob.signer_type = 0xA0;
    gOffsets.csblob.platform_binary = 0xA4;

    gOffsetsInitialised = true;
}