#include <stdint.h>

extern uint32_t off_ipc_object_io_bits;
extern uint32_t off_ipc_port_ip_receiver;
extern uint32_t off_ipc_port_ip_kobject;

extern uint32_t off_p_list_le_prev;
extern uint32_t off_p_task;
extern uint32_t off_p_pid;
extern uint32_t off_p_ucred;
extern uint32_t off_p_pfd;
extern uint32_t off_p_textvp;
extern uint32_t off_p_comm;
extern uint32_t off_p_csflags;

extern uint32_t off_fd_ofiles;

extern uint32_t off_fp_glob;

extern uint32_t off_fg_data;

extern uint32_t off_task_itk_space;
extern uint32_t off_task_t_flags;

extern uint32_t off_ipc_space_is_table;

extern uint32_t off_vnode_v_usecount;
extern uint32_t off_vnode_v_iocount;
extern uint32_t off_vnode_v_type;
extern uint32_t off_vnode_vu_ubcinfo;
extern uint32_t off_vnode_v_parent;
extern uint32_t off_vnode_v_mount;

extern uint32_t off_mount_mnt_flag;

extern uint32_t off_ubc_info_cs_blobs;

extern uint32_t off_cs_blob_csb_platform_binary;

extern uint32_t off_u_cr_svuid;
extern uint32_t off_u_cr_label;

void offsets_init(void);