#include <mach-o/loader.h>

typedef struct {
    struct section_64 s64;
    char *data;
} sec_64_t;

typedef struct {
    sec_64_t sec_text, sec_cstring;
    const char *kernel;
    size_t kernel_sz;
    char *data;
} pfinder_t;

#ifndef SECT_CSTRING
#    define SECT_CSTRING "__cstring"
#endif

#ifndef SEG_TEXT_EXEC
#    define SEG_TEXT_EXEC "__TEXT_EXEC"
#endif

#    define KADDR_FMT "0x%" PRIX64

typedef uint64_t kaddr_t;

struct fileset_entry_command {
    uint32_t        cmd;        /* LC_FILESET_ENTRY */
    uint32_t        cmdsize;    /* includes id string */
    uint64_t        vmaddr;     /* memory address of the dylib */
    uint64_t        fileoff;    /* file offset of the dylib */
    union lc_str    entry_id;   /* contained entry id */
    uint32_t        reserved;   /* entry_id is 32-bits long, so this is the reserved padding */
};

#define	MH_FILESET	0xc		/* set of mach-o's */

#define LC_REQ_DYLD 0x80000000
#define LC_FILESET_ENTRY      (0x35 | LC_REQ_DYLD) /* used with fileset_entry_command */

kern_return_t
pfinder_init(pfinder_t *pfinder);

kern_return_t
pfinder_init_kernel(pfinder_t *pfinder, size_t off);

kaddr_t
pfinder_trustcache(pfinder_t pfinder);

kaddr_t
pfinder_zone_map_ref(pfinder_t pfinder);