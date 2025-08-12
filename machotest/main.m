#include <stdio.h>
#include <mach/mach.h>
#include <sys/syscall.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <mach-o/nlist.h>


typedef struct segment_command_64 segment_command_t;

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

// Mach-O 헤더를 파싱하여 심볼 이름(symbol_name)에 해당하는 주소를 찾음
uint64_t find_symbol_address(uint64_t image_base, const char *symbol_name) {
    const struct mach_header_64 *hdr = (struct mach_header_64 *)image_base;
    uint8_t *ptr = (uint8_t *)hdr + sizeof(struct mach_header_64);
    struct symtab_command *symtab_cmd = NULL;

    // 1) LC_SYMTAB 커맨드 찾기
    for (uint32_t i = 0; i < hdr->ncmds; i++) {
        struct load_command *lc = (struct load_command *)ptr;
        if (lc->cmd == LC_SYMTAB) {
            symtab_cmd = (struct symtab_command *)lc;
            break;
        }
        ptr += lc->cmdsize;
    }
    if (!symtab_cmd) {
        fprintf(stderr, "[-] LC_SYMTAB not found\n");
        return 0;
    }
	printf("symtab_cmd: 0x%llx\n", symtab_cmd);

	// 2) TEXT SEGMENT 찾아서 slide 찾기
	ptr = (uint8_t *)hdr + sizeof(struct mach_header_64);
	segment_command_t *text_segment = 0;
	for (uint32_t i = 0; i < hdr->ncmds; i++) {
        segment_command_t *sc = (segment_command_t *)ptr;
        if (strcmp(sc->segname, "__TEXT") == 0) {
			text_segment = sc;
            break;
        }
        ptr += sc->cmdsize;
    }
	printf("text_segment: 0x%llx\n", text_segment);
	uintptr_t slide = (uintptr_t)hdr - (uintptr_t)text_segment->vmaddr;
	printf("slide: 0x%llx\n", slide);

	// 3) __LINKEDIT segment 찾아서 linkedit_base 구하기
	ptr = (uint8_t *)hdr + sizeof(struct mach_header_64);
	segment_command_t *linkedit_segment = 0;
	for (uint32_t i = 0; i < hdr->ncmds; i++) {
        segment_command_t *sc = (segment_command_t *)ptr;
        if (strcmp(sc->segname, "__LINKEDIT") == 0) {
			linkedit_segment = sc;
            break;
        }
        ptr += sc->cmdsize;
    }
	printf("linkedit_segment: 0x%llx\n", linkedit_segment);
	uintptr_t linkedit_base = (uintptr_t)slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
	printf("linkedit_base: 0x%llx\n", linkedit_base);


    // 2) 스트링 테이블, 심볼 테이블 포인터 계산
    const char *string_table = (const char *)(linkedit_base + symtab_cmd->stroff);
	printf("string_table: %p\n", string_table);
    const struct nlist_64 *sym_table = (const struct nlist_64 *)(linkedit_base + symtab_cmd->symoff);
	printf("sym_table: %p\n", sym_table);

	printf("symtab_cmd->nsyms=symtab_count: %u\n", symtab_cmd->nsyms);

    // 3) 모든 심볼 순회하며 이름 비교
    for (uint32_t i = 0; i < symtab_cmd->nsyms; i++) {

		if (sym_table[i].n_value) {
			uint32_t strtab_offset = sym_table[i].n_un.n_strx;
			char *current_symbol_name = string_table + strtab_offset;

			if (strstr(current_symbol_name, symbol_name) != NULL) {
            	uint64_t addr = sym_table[i].n_value;
            	// printf("[+] found symbol: %s at 0x%llx\n", current_symbol_name, addr);
            	return addr - (uint64_t)text_segment->vmaddr;;
        	}
		}
    }

    fprintf(stderr, "[-] symbol %s not found\n", symbol_name);
    return 0;
}

int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
		printf("Hello world!\n");
        dlopen("/System/Library/Frameworks/JavaScriptCore.framework/JavaScriptCore", RTLD_NOW);
		const char* img_name = "JavaScriptCore";

		uint64_t libdyld_base = get_image_base(img_name);
		printf("libdyld_base: 0x%llx\n", libdyld_base);

		const char *sym_to_find = "MergedGlobals";  // Mach-O 심볼명

		uint64_t sym_addr = find_symbol_address(libdyld_base, sym_to_find);
    	if (!sym_addr) {
    	    fprintf(stderr, "[-] failed to find symbol %s\n", sym_to_find);
    	    return 1;
    	}
		printf("found! sym_addr=0x%llx\n", sym_addr);

		return 0;
	}
}