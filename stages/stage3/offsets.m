#include "offsets.h"
#include "stage3.h"
#include <stdint.h>
#include <UIKit/UIKit.h>
#include <Foundation/Foundation.h>

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

uint32_t off_ipc_object_io_bits = 0;
uint32_t off_ipc_port_ip_receiver = 0;
uint32_t off_ipc_port_ip_kobject = 0;

uint32_t off_p_list_le_prev = 0;
uint32_t off_p_task = 0;
uint32_t off_p_pid = 0;
uint32_t off_p_ucred = 0;
uint32_t off_p_pfd = 0;
uint32_t off_p_textvp = 0;
uint32_t off_p_comm = 0;
uint32_t off_p_csflags = 0;

uint32_t off_fd_ofiles = 0;

uint32_t off_fp_glob = 0;

uint32_t off_fg_data = 0;

uint32_t off_task_itk_space = 0;
uint32_t off_task_t_flags = 0;

uint32_t off_ipc_space_is_table = 0;

uint32_t off_vnode_v_usecount = 0;
uint32_t off_vnode_v_iocount = 0;
uint32_t off_vnode_v_type = 0;
uint32_t off_vnode_vu_ubcinfo = 0;
uint32_t off_vnode_v_parent = 0;
uint32_t off_vnode_v_mount = 0;

uint32_t off_mount_mnt_flag = 0;

uint32_t off_ubc_info_cs_blobs = 0;

uint32_t off_cs_blob_csb_platform_binary = 0;

uint32_t off_u_cr_svuid = 0;
uint32_t off_u_cr_label = 0;

void offsets_init(void) {
    if (!(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"12.0"))) {
        LOG(@"Only supported offset for iOS 12.0+");
        exit(EXIT_FAILURE);
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"12.0")) {
        LOG(@"offsets selected for iOS 12.0+\n");

        off_ipc_object_io_bits = 0x0;
        off_ipc_port_ip_receiver = 0x60;
        off_ipc_port_ip_kobject = 0x68;

        off_p_list_le_prev = 0x8;
        off_p_task = 0x10;
        off_p_pid = 0x60;
        off_p_ucred = 0xf8;
        off_p_pfd = 0x100;
        off_p_textvp = 0x230;
        off_p_comm = 0x250;
        off_p_csflags = 0x290;

        off_fd_ofiles = 0x0;

        off_fp_glob = 0x8;

        off_fg_data = 0x38;

        off_task_itk_space = 0x300;
        off_task_t_flags = 0x390;

        off_ipc_space_is_table = 0x20;

        off_vnode_v_usecount = 0x60;
        off_vnode_v_iocount = 0x64;
        off_vnode_v_type = 0x70;
        off_vnode_vu_ubcinfo = 0x78;
        off_vnode_v_parent = 0xc0;
        off_vnode_v_mount = 0xd8;

        off_mount_mnt_flag = 0x70;

        off_ubc_info_cs_blobs = 0x50;

        off_cs_blob_csb_platform_binary = 0xa8;

        off_u_cr_svuid = 0x20;
        off_u_cr_label = 0x78;
    }
}