#include <stdio.h>
#include <mach/mach.h>
#include <sys/syscall.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <mach-o/nlist.h>

void hexdump(const void* data, size_t size) {
    char ascii[17];
    size_t i, j;
    ascii[16] = '\0';
    for (i = 0; i < size; ++i) {
        if ((i % 16) == 0)
        {
            printf("[0x%016llx+0x%03zx] ", (long long unsigned int)&data, i);
        }

        printf("%02X ", ((unsigned char*)data)[i]);
        if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
            ascii[i % 16] = ((unsigned char*)data)[i];
        }
        else
            ascii[i % 16] = '.';

        if ((i + 1) % 8 == 0 || i + 1 == size) {
            printf(" ");
            if ((i + 1) % 16 == 0)
                printf("|  %s \n", ascii);
            else if (i + 1 == size) {
                ascii[(i + 1) % 16] = '\0';
                if ((i + 1) % 16 <= 8) {
                    printf(" ");
                }
                for (j = (i + 1) % 16; j < 16; ++j)
                    printf("   ");

                printf("|  %s \n", ascii);
            }
        }
    }
}

int readbuf(uint64_t addr, void* output, size_t size) {
    memcpy((void*)output, (void*)addr, size);
    return 0;
}

uint64_t read64(uint64_t what) {
    uint64_t value = 0;
    readbuf(what, &value, sizeof(value));
    return value;
}

uint32_t read32(uint64_t what) {
    uint32_t value = 0;
    readbuf(what, &value, sizeof(value));
    return value;
}

uint8_t read8(uint64_t what) {
    uint8_t value = 0;
    readbuf(what, &value, sizeof(value));
    return value;
}

uint16_t read16(uint64_t what) {
    uint16_t value = 0;
    readbuf(what, &value, sizeof(value));
    return value;
}

uint64_t get_image_base(char* image_name) {
	uint32_t count = _dyld_image_count();
	NSString* imageName = [NSString stringWithUTF8String: image_name];

	for(uint32_t i = 0; i < count; i++)
	{
		const char *dyld = _dyld_get_image_name(i);
		NSString *nsdyld = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:dyld length:strlen(dyld)];
		if([nsdyld containsString:imageName]) {
			printf("found image: %s\n", nsdyld.UTF8String);
			return (uint64_t)_dyld_get_image_header(i);
		}
	}
	return -1;
}

/* Get the next load command from the current one */
#define NEXTCMD(cmd) ({ \
	__typeof__(cmd) _cmd = (cmd); \
	(struct load_command*)((char*)_cmd + _cmd->cmdsize); \
})

/* Iterate through all load commands */
#define ITERCMDS(i, cmd, cmds, ncmds) \
for(i = 0, cmd = (cmds); i < (ncmds); i++, cmd = NEXTCMD(cmd))


static int print_symbols(void* map) {
	bool is64bit = false;
	uint32_t i, ncmds;
	struct load_command* cmd, *cmds;
	struct mach_header* mh = (struct mach_header*)map;

	/* Parse mach_header to get the first load command and the number of commands */
	if(mh->magic != MH_MAGIC) {
		if(mh->magic == MH_MAGIC_64) {
			is64bit = true;
			struct mach_header_64* mh64 = (struct mach_header_64*)mh;
			cmds = (struct load_command*)&mh64[1];
			ncmds = mh64->ncmds;
		}
		else {
			fprintf(stderr, "Invalid magic number: %08X\n", mh->magic);
			return -1;
		}
	}
	else {
		cmds = (struct load_command*)&mh[1];
		ncmds = mh->ncmds;
	}

	/* Keep track of the symtab if found. */
	struct symtab_command* symtab_cmd = NULL;

	/* Iterate through the Mach-O's load commands */
	ITERCMDS(i, cmd, cmds, ncmds) {
		/* Make sure we don't loop infinitely */
		if(cmd->cmdsize == 0) {
			fprintf(stderr, "Load command too small!\n");
			return -1;
		}

		/* Process the load command */
		if(cmd->cmd == LC_SYMTAB) {
			symtab_cmd = (struct symtab_command*)cmd;
			break;
		}
	}

	const char* strtab = (const char*)map + symtab_cmd->stroff;
	if(is64bit) {
		struct nlist_64* symtab = (struct nlist_64*)((char*)map + symtab_cmd->symoff);

		/* Print all symbols */
		for(i = 0; i < symtab_cmd->nsyms; i++) {
			struct nlist_64* nl = &symtab[i];

			/* Skip debug symbols */
			if(nl->n_type & N_STAB) {
				continue;
			}

			/* Get name of symbol type */
			const char* type = NULL;
			switch(nl->n_type & N_TYPE) {
				case N_UNDF: type = "N_UNDF"; break;
				case N_ABS:  type = "N_ABS"; break;
				case N_SECT: type = "N_SECT"; break;
				case N_PBUD: type = "N_PBUD"; break;
				case N_INDR: type = "N_INDR"; break;

				default:
					fprintf(stderr, "Invalid symbol type: 0x%x\n", nl->n_type & N_TYPE);
					return -1;
			}

			const char* symname = &strtab[nl->n_un.n_strx];
            printf("symname: %s\n", symname);
		}
	}

	return 0;
}

int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
		printf("Hello world!\n");
		const char* img_name = "libdyld";

		uint64_t libdyld_base = get_image_base(img_name);
		printf("libdyld_base: 0x%llx\n", libdyld_base);

        print_symbols((void*)libdyld_base);

		// const char *sym_to_find = "_dlsym";  // Mach-O 심볼명

		// uint64_t sym_addr = find_symbol_address(libdyld_base, sym_to_find);
    	// if (!sym_addr) {
    	//     fprintf(stderr, "[-] failed to find symbol %s\n", sym_to_find);
    	//     return 1;
    	// }
		// printf("found! sym_addr=0x%llx\n", sym_addr);

		return 0;
	}
}