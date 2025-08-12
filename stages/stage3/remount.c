#include "remount.h"
#include "offsets.h"
#include "krw.h"
#include "proc.h"

#include <fcntl.h>
#include <sys/syscall.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/attr.h>
#include <sys/snapshot.h>
#include <mach/mach.h>
#include <sys/mount.h>

int list_snapshots(const char *vol)
{
    int dirfd = get_dirfd(vol);
    
    if (dirfd < 0) {
        perror("get_dirfd");
        return -1;
    }
    
    struct attrlist alist = { 0 };
    char abuf[2048];
    
    alist.commonattr = ATTR_BULK_REQUIRED;
    
    int count = fs_snapshot_list(dirfd, &alist, &abuf[0], sizeof (abuf), 0);
    close(dirfd);

    if (count < 0) {
        perror("fs_snapshot_list");
        return -1;
    }
    
    char *p = &abuf[0];
    for (int i = 0; i < count; i++) {
        char *field = p;
        uint32_t len = *(uint32_t *)field;
        field += sizeof (uint32_t);
        attribute_set_t attrs = *(attribute_set_t *)field;
        field += sizeof (attribute_set_t);
        
        if (attrs.commonattr & ATTR_CMN_NAME) {
            attrreference_t ar = *(attrreference_t *)field;
            char *name = field + ar.attr_dataoffset;
            field += sizeof (attrreference_t);
            (void) printf("%s\n", name);
        }
        
        p += len;
    }
    
    return (0);
}

uint64_t find_rootvnode(void) {
    uint64_t launchd_proc = proc_of_pid(1);

    uint64_t textvp = kread64(launchd_proc + off_p_textvp);
    
    uint64_t sbin_vnode = kread64(textvp + off_vnode_v_parent);
    
    uint64_t root_vnode = kread64(sbin_vnode + off_vnode_v_parent);
    
    return root_vnode;
}

#define MNT_RDONLY      0x00000001      /* read only filesystem */
#define MNT_NOSUID      0x00000008      /* don't honor setuid bits on fs */
#define MNT_ROOTFS      0x00004000      /* identifies the root filesystem */
#define MNT_UPDATE      0x00010000      /* not a real mount, just an update */

int remount_root_as_rw(void){
    uint64_t rootvnode = find_rootvnode();
    uint64_t vmount = kread64(rootvnode + off_vnode_v_mount);
    uint32_t vflag = kread32(vmount + off_mount_mnt_flag);
    
    uint32_t updated_vflag = vflag & ~(MNT_RDONLY);
    kwrite32(vmount + off_mount_mnt_flag, updated_vflag & ~(MNT_ROOTFS));

    char* dev_path = strdup("/dev/disk0s1s1");
    int retval = mount("apfs", "/", MNT_UPDATE, &dev_path);
    free(dev_path);

    kwrite32(vmount + off_mount_mnt_flag, updated_vflag);

    return retval;
}

uint64_t get_vnode_at_path(char* filename) {
    int file_index = open(filename, O_RDONLY);
    if (file_index == -1) return -1;
    
    uint64_t proc = proc_of_pid(getpid());

    uint64_t filedesc = kread64(proc + off_p_pfd);
    uint64_t fileproc = kread64(filedesc + off_fd_ofiles);
    uint64_t openedfile = kread64(fileproc + (8 * file_index));
    uint64_t fileglob = kread64(openedfile + off_fp_glob);
    uint64_t vnode = kread64(fileglob + off_fg_data);
    
    close(file_index);
    
    return vnode;
}