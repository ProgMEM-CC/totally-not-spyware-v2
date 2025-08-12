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

uint64_t find_symbol_address(uint64_t image_base, const char *symbol_name) {
    /* number of load commands */
    uint64_t ncmds = read32(image_base + 0x10);
    printf("ncmds=%u\n", ncmds);

    uint64_t ptr = image_base + 0x20;//sizeof(struct mach_header_64) = 0x20

    // 1) LC_SYMTAB 커맨드 찾기
    uint64_t symtab_cmd = 0;
    for (uint32_t i = 0; i < ncmds; i++) {
        // struct load_command *lc = (struct load_command *)ptr;
        uint64_t lc = ptr;
        uint32_t lc_cmd = read32(lc + 0);  //offsetof(load_command, cmd)=0
        if (lc_cmd == LC_SYMTAB) {
            printf("found LC_SYMTAB!!!\n");
            symtab_cmd = lc;
            break;
        }

        uint32_t lc_cmdsize = read32(lc + 4); //offsetof(load_command, cmdsize)=4
        ptr += lc_cmdsize;
    }
    printf("symtab_cmd: 0x%llx\n", symtab_cmd);




    // 2) TEXT SEGMENT 찾아서 slide 찾기
	ptr = image_base + 0x20;//sizeof(struct mach_header_64) = 0x20
	uint64_t text_segment = 0;
	for (uint32_t i = 0; i < ncmds; i++) {
        uint64_t sc = ptr;
        char* sc_segname = (char*)(sc + 8); 
        if (strcmp(sc_segname, "__TEXT") == 0) {
            printf("found text_segment!!!\n");
			text_segment = sc;
            break;
        }
        uint32_t sc_cmdsize = read32(sc + 4); //offsetof(segment_command, cmdsize)=4
        ptr += sc_cmdsize;
    }
	printf("text_segment: 0x%llx\n", text_segment);
    uint32_t text_segment_vmaddr = read32(text_segment+0x18);
	uint64_t slide = image_base - text_segment_vmaddr;
	printf("slide: 0x%llx\n", slide);








    // 3) __LINKEDIT segment 찾아서 linkedit_base 구하기
	ptr = image_base + 0x20;//sizeof(struct mach_header_64) = 0x20
	uint64_t linkedit_segment = 0;
	for (uint32_t i = 0; i < ncmds; i++) {
        uint64_t sc = ptr;
        char* sc_segname = (char*)(sc + 8);  //offsetof(segment_command, cmd)=0
        if (strcmp(sc_segname, "__LINKEDIT") == 0) {
			linkedit_segment = sc;
            break;
        }
        uint32_t sc_cmdsize = read32(sc + 4); //offsetof(segment_command, cmdsize)=4
        ptr += sc_cmdsize;
    }
    printf("linkedit_segment: 0x%llx\n", linkedit_segment);
    uint32_t linkedit_segment_vmaddr = read32(linkedit_segment+0x18);
    uint32_t linkedit_segment_fileoff = read32(linkedit_segment+0x28);
	uintptr_t linkedit_base = slide + linkedit_segment_vmaddr - linkedit_segment_fileoff;
	printf("linkedit_base: 0x%llx\n", linkedit_base);







    // 4) 스트링 테이블, 심볼 테이블 포인터 계산
    uint64_t string_table = linkedit_base + read32(symtab_cmd + 0x10);  //0x10 = offsetof(symtab_command, stroff)
    printf("string_table: 0x%llx\n", string_table);
    uint64_t sym_table = linkedit_base + read32(symtab_cmd + 8);  //0x8 = offsetof(symtab_command, symoff)
    printf("sym_table: 0x%llx\n", sym_table);
    uint32_t nsyms = read32(symtab_cmd + 0xc);  //0xc = offsetof(symtab_command, nsyms)
    printf("nsyms: %u\n", nsyms);

    // 3) 모든 심볼 순회하며 이름 비교
    for (uint32_t i = 0; i < nsyms; i++) {
        uint64_t symtable_n_value = read64(sym_table + i * 16 + 8);     //sym_table[i].n_value
        if(symtable_n_value) {
            uint32_t strtab_offset = read64(sym_table + i * 16 + 0);    //ym_table[i].n_un.n_strx;
            // printf("strtab_offset: %u\n", strtab_offset);

            char *current_symbol_name = (char*)(string_table + strtab_offset);
            printf("[+] found symbol: %s\n", current_symbol_name);
            if (strcmp(current_symbol_name, symbol_name) == 0) {
               	uint64_t addr = symtable_n_value;
               	printf("[+] found symbol: %s at 0x%llx\n", current_symbol_name, addr);
               	return addr - text_segment_vmaddr - 0x100000000;
            }
        }
    }



    return -1;
}


int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
		printf("Hello world!\n");
		const char* img_name = "libxpc";

		uint64_t libdyld_base = get_image_base(img_name);
		printf("libdyld_base: 0x%llx\n", libdyld_base);

		const char *sym_to_find = "_dlsyddm";  // Mach-O 심볼명

		uint64_t sym_addr = find_symbol_address(libdyld_base, sym_to_find);
    	if (!sym_addr) {
    	    fprintf(stderr, "[-] failed to find symbol %s\n", sym_to_find);
    	    return 1;
    	}
		printf("found! sym_addr=0x%llx\n", sym_addr);

		return 0;
	}
}