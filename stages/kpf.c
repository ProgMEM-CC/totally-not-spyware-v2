#include <dlfcn.h>
#include <compression.h>
#include <mach-o/fat.h>
#include <mach/mach.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#include <stdio.h>
#include <mach-o/loader.h>

#include "kpf.h"
#include "log.h"
#include "physpuppet/libprejailbreak.h"

#define IS_ADR(a) (((a) & 0x9F000000U) == 0x10000000U)
#define IS_ADRP(a) (((a) & 0x9F000000U) == 0x90000000U)
#define IS_LDR_X(a) (((a) & 0xFF000000U) == 0x58000000U)
#define IS_ADD_X(a) (((a) & 0xFFC00000U) == 0x91000000U)
#define IS_SUBS_X(a) (((a) & 0xFF200000U) == 0xEB000000U)
#define LDR_W_UNSIGNED_IMM(a) (extract32(a, 10, 12) << 2U)
#define LDR_X_UNSIGNED_IMM(a) (extract32(a, 10, 12) << 3U)
#define IS_LDR_W_UNSIGNED_IMM(a) (((a) & 0xFFC00000U) == 0xB9400000U)
#define IS_LDR_X_UNSIGNED_IMM(a) (((a) & 0xFFC00000U) == 0xF9400000U)

static kern_return_t
kreadbuf_wrapper(kaddr_t addr, void *buf, size_t sz) {
    kreadbuf(addr, buf, sz);
    return KERN_SUCCESS;
}

void
sec_reset(sec_64_t *sec) {
    memset(&sec->s64, '\0', sizeof(sec->s64));
    sec->data = NULL;
}

void
sec_term(sec_64_t *sec) {
    free(sec->data);
}

static kern_return_t
sec_read_buf(sec_64_t sec, kaddr_t addr, void *buf, size_t sz) {
    size_t off;

    if(addr < sec.s64.addr || sz > sec.s64.size || (off = addr - sec.s64.addr) > sec.s64.size - sz) {
        return KERN_FAILURE;
    }
    memcpy(buf, sec.data + off, sz);
    return KERN_SUCCESS;
}

void
pfinder_reset(pfinder_t *pfinder) {
    pfinder->data = NULL;
    pfinder->kernel = NULL;
    pfinder->kernel_sz = 0;
    sec_reset(&pfinder->sec_text);
    sec_reset(&pfinder->sec_cstring);
}

void
pfinder_term(pfinder_t *pfinder) {
    free(pfinder->data);
    sec_term(&pfinder->sec_text);
    sec_term(&pfinder->sec_cstring);
    pfinder_reset(pfinder);
}

kern_return_t
pfinder_init(pfinder_t *pfinder) {
    kern_return_t ret = KERN_FAILURE;
    
    pfinder_reset(pfinder);
    
    if((ret = pfinder_init_kernel(pfinder, 0)) != KERN_SUCCESS) {
        LOG("pfinder_init_kernel ret: 0x%x", ret);
        pfinder_term(pfinder);
    }
    return ret;
}

static kern_return_t
find_section_kernel(kaddr_t p, struct segment_command_64 sg64, const char *sect_name, struct section_64 *sp) {
    for(; sg64.nsects-- != 0; p += sizeof(*sp)) {
        if(kreadbuf_wrapper(p, sp, sizeof(*sp)) != KERN_SUCCESS) {
            break;
        }
        if((sp->flags & SECTION_TYPE) != S_ZEROFILL) {
            if(sp->offset < sg64.fileoff || sp->size > sg64.filesize || sp->offset - sg64.fileoff > sg64.filesize - sp->size) {
                break;
            }
            if(sp->size != 0 && strncmp(sp->segname, sg64.segname, sizeof(sp->segname)) == 0 && strncmp(sp->sectname, sect_name, sizeof(sp->sectname)) == 0) {
                return KERN_SUCCESS;
            }
        }
    }
    return KERN_FAILURE;
}

static int
kstrcmp(kaddr_t p, const char *s0) {
    size_t len = strlen(s0);
    int ret = 1;
    char *s;

    if((s = malloc(len + 1)) != NULL) {
        s[len] = '\0';
        if(kreadbuf_wrapper(p, s, len) == KERN_SUCCESS) {
            ret = strcmp(s, s0);
        }
        free(s);
    }
    return ret;
}

kern_return_t
pfinder_init_kernel(pfinder_t *pfinder, size_t off) {
    struct fileset_entry_command fec;
    struct segment_command_64 sg64;
    uint64_t kbase = (0xFFFFFFF007004000 + kinfo(slide));
    kaddr_t p = kbase + off, e;
    struct mach_header_64 mh64;
    struct load_command lc;
    struct section_64 s64;

    if(kreadbuf_wrapper(p, &mh64, sizeof(mh64)) == KERN_SUCCESS && mh64.magic == MH_MAGIC_64 && mh64.cputype == CPU_TYPE_ARM64 &&
       (mh64.filetype == MH_EXECUTE || (off == 0 && mh64.filetype == MH_FILESET))
       ) {
        for(p += sizeof(mh64), e = p + mh64.sizeofcmds; mh64.ncmds-- != 0 && e - p >= sizeof(lc); p += lc.cmdsize) {
            if(kreadbuf_wrapper(p, &lc, sizeof(lc)) != KERN_SUCCESS || lc.cmdsize < sizeof(lc) || e - p < lc.cmdsize) {
                break;
            }
            if(lc.cmd == LC_SEGMENT_64) {
                if(lc.cmdsize < sizeof(sg64) || kreadbuf_wrapper(p, &sg64, sizeof(sg64)) != KERN_SUCCESS) {
                    break;
                }
                if(sg64.vmsize == 0) {
                    continue;
                }
                if(sg64.nsects != (lc.cmdsize - sizeof(sg64)) / sizeof(s64)) {
                    break;
                }
                if(mh64.filetype == MH_EXECUTE) {
                    if(strncmp(sg64.segname, SEG_TEXT_EXEC, sizeof(sg64.segname)) == 0) {
                        if(find_section_kernel(p + sizeof(sg64), sg64, SECT_TEXT, &s64) != KERN_SUCCESS || s64.size == 0 || (pfinder->sec_text.data = malloc(s64.size)) == NULL || kreadbuf_wrapper(s64.addr, pfinder->sec_text.data, s64.size) != KERN_SUCCESS) {
                            break;
                        }
                        pfinder->sec_text.s64 = s64;
                    } else if(strncmp(sg64.segname, SEG_TEXT, sizeof(sg64.segname)) == 0) {
                        if(find_section_kernel(p + sizeof(sg64), sg64, SECT_CSTRING, &s64) != KERN_SUCCESS || s64.size == 0 || (pfinder->sec_cstring.data = calloc(1, s64.size + 1)) == NULL || kreadbuf_wrapper(s64.addr, pfinder->sec_cstring.data, s64.size) != KERN_SUCCESS) {
                            break;
                        }
                        pfinder->sec_cstring.s64 = s64;
                    }
                }
            }
            else if(mh64.filetype == MH_FILESET && lc.cmd == LC_FILESET_ENTRY) {
                if(lc.cmdsize < sizeof(fec) || kreadbuf_wrapper(p, &fec, sizeof(fec)) != KERN_SUCCESS) {
                    break;
                }
                if(fec.fileoff == 0 || fec.entry_id.offset > fec.cmdsize) {
                    break;
                }
                if(kstrcmp(p + fec.entry_id.offset, "com.apple.kernel") == 0 && pfinder_init_kernel(pfinder, fec.fileoff) == KERN_SUCCESS) {
                    return KERN_SUCCESS;
                }
            }
            if(pfinder->sec_text.s64.size != 0 && pfinder->sec_cstring.s64.size != 0) {
                return KERN_SUCCESS;
            }
        }
    }
    return KERN_FAILURE;
}

static kaddr_t
follow_adrp_ldr(kaddr_t ref, uint32_t adrp_op, uint32_t ldr_op)
{
    uint64_t imm_hi_lo = (uint64_t)((adrp_op >> 3)  & 0x1FFFFC);
    imm_hi_lo |= (uint64_t)((adrp_op >> 29) & 0x3);
    if ((adrp_op & 0x800000) != 0) {
        imm_hi_lo |= 0xFFFFFFFFFFE00000;
    }
    
    uint64_t imm = imm_hi_lo << 12;
    uint64_t ret = (ref & ~0xFFF) + imm;
    
    uint64_t imm12 = ((ldr_op >> 10) & 0xFFF) << 3;
    ret += imm12;
    
    return ret;
}

kaddr_t
pfinder_trustcache(pfinder_t pfinder)
{
    bool found = false;
    
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[4];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        // 4A FD 41 D3 6A F2 FF B5 08 01 40 F9 A8 F1 FF B5
        if (insns[0] == 0xD341FD4A
            && insns[1] == 0xB5FFF26A
            && insns[2] == 0xF9400108
            && insns[3] == 0xB5FFF1A8) {
            found = true;
            break;
        }
    }
    if(!found)
        return 0;
    
    // step into high address
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if(IS_ADRP(insns[0])) {
            break;
        }
    }
    
    return follow_adrp_ldr(ref, insns[0], insns[1]);
}

kaddr_t
pfinder_zone_map_ref(pfinder_t pfinder)
{
    bool found = false;
    
    kaddr_t ref = pfinder.sec_text.s64.addr;
    uint32_t insns[4];
    
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        // 08 50 4F A9 96 0A C8 9A C8 C2 21 8B 15 05 00 D1
        if ((insns[0] & 0xffff0000) == 0xa94f0000   //ldp something
            && insns[1] == 0x9AC80A96
            && insns[2] == 0x8B21C2C8
            && insns[3] == 0xD1000515) {
            found = true;
            break;
        }
    }
    if(!found)
        return 0;
    
    // step into high address
    for(; sec_read_buf(pfinder.sec_text, ref, insns, sizeof(insns)) == KERN_SUCCESS; ref += sizeof(*insns)) {
        if(IS_ADRP(insns[0])) {
            break;
        }
    }
    
    return follow_adrp_ldr(ref, insns[0], insns[1]);
}
