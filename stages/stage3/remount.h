#include <stdint.h>

#define get_dirfd(vol) open(vol, O_RDONLY, 0)

int list_snapshots(const char *vol);
uint64_t find_rootvnode(void);
int remount_root_as_rw(void);

uint64_t get_vnode_at_path(char* filename);