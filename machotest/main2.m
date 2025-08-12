#include <stdio.h>
#include <dlfcn.h>
#include <pthread.h>

#include <mach-o/dyld_images.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>
#include <mach/mach.h>
#include <mach-o/loader.h>
#include <sys/mman.h>
#include <mach-o/dyld.h>
#include <unistd.h>
#include <fcntl.h>

#define ASSERT(x)

#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64

typedef struct segment_command_64 segment_command_t;
typedef struct nlist_64 nlist_t;
typedef struct mach_header_64 mach_header_t;

typedef struct macho_ctx
{
  bool is_runtime_mode;

  mach_header_t *header;

  uintptr_t slide;
  uintptr_t linkedit_base;

  segment_command_t *segments[64];
  int segments_count;

  segment_command_t *text_seg;
  segment_command_t *data_seg;
  segment_command_t *text_exec_seg;
  segment_command_t *data_const_seg;
  segment_command_t *linkedit_seg;

  struct symtab_command *symtab_cmd;
  struct dysymtab_command *dysymtab_cmd;
  struct dyld_info_command *dyld_info_cmd;
  struct linkedit_data_command *exports_trie_cmd;
  struct linkedit_data_command *chained_fixups_cmd;

  nlist_t *symtab;
  char *strtab;
  uint32_t *indirect_symtab;
} macho_ctx_t;

typedef enum
{
  RESOLVE_SYMBOL_TYPE_SYMBOL_TABLE = 1 << 0,
  RESOLVE_SYMBOL_TYPE_EXPORTED = 1 << 1,
  RESOLVE_SYMBOL_TYPE_ALL = RESOLVE_SYMBOL_TYPE_SYMBOL_TABLE | RESOLVE_SYMBOL_TYPE_EXPORTED
} resolve_symbol_type_t;

void macho_ctx_init(macho_ctx_t *ctx, mach_header_t *header, bool is_runtime_mode)
{
  memset(ctx, 0, sizeof(macho_ctx_t));

  ctx->is_runtime_mode = is_runtime_mode;

  ctx->header = header;
  segment_command_t *curr_seg_cmd;
  segment_command_t *text_segment = 0, *text_exec_segment = 0, *data_segment = 0, *data_const_segment = 0,
                    *linkedit_segment = 0;
  struct symtab_command *symtab_cmd = 0;
  struct dysymtab_command *dysymtab_cmd = 0;
  struct dyld_info_command *dyld_info_cmd = 0;
  struct linkedit_data_command *exports_trie_cmd = 0;
  struct linkedit_data_command *chained_fixups_cmd = NULL;

  curr_seg_cmd = (segment_command_t *)((uintptr_t)header + sizeof(mach_header_t));
  for (int i = 0; i < header->ncmds; i++)
  {
    if (curr_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT)
    {
      //  BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB and REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB
      ctx->segments[ctx->segments_count++] = curr_seg_cmd;

      if (strcmp(curr_seg_cmd->segname, "__LINKEDIT") == 0)
      {
        linkedit_segment = curr_seg_cmd;
        printf("linkedit_segment!!! 0x%llx\n", linkedit_segment);
      }
      else if (strcmp(curr_seg_cmd->segname, "__DATA") == 0)
      {
        data_segment = curr_seg_cmd;
      }
      else if (strcmp(curr_seg_cmd->segname, "__DATA_CONST") == 0)
      {
        data_const_segment = curr_seg_cmd;
      }
      else if (strcmp(curr_seg_cmd->segname, "__TEXT") == 0)
      {
        text_segment = curr_seg_cmd;
        printf("text_segment!!! 0x%llx\n", text_segment);
      }
      else if (strcmp(curr_seg_cmd->segname, "__TEXT_EXEC") == 0)
      {
        text_exec_segment = curr_seg_cmd;
      }
    }
    else if (curr_seg_cmd->cmd == LC_SYMTAB)
    {
      symtab_cmd = (struct symtab_command *)curr_seg_cmd;
      printf("symtab_cmd: 0x%llx\n", symtab_cmd);
    }
    else if (curr_seg_cmd->cmd == LC_DYSYMTAB)
    {
      dysymtab_cmd = (struct dysymtab_command *)curr_seg_cmd;
    }
    else if (curr_seg_cmd->cmd == LC_DYLD_INFO || curr_seg_cmd->cmd == LC_DYLD_INFO_ONLY)
    {
      dyld_info_cmd = (struct dyld_info_command *)curr_seg_cmd;
    }
    else if (curr_seg_cmd->cmd == LC_DYLD_EXPORTS_TRIE)
    {
      exports_trie_cmd = (struct linkedit_data_command *)curr_seg_cmd;
    }
    else if (curr_seg_cmd->cmd == LC_DYLD_CHAINED_FIXUPS)
    {
      chained_fixups_cmd = (struct linkedit_data_command *)curr_seg_cmd;
    }
    curr_seg_cmd = (segment_command_t *)((uintptr_t)curr_seg_cmd + curr_seg_cmd->cmdsize);
  }

  uintptr_t slide = (uintptr_t)header - (uintptr_t)text_segment->vmaddr;
  printf("slide: 0x%llx\n", slide);
  uintptr_t linkedit_base = (uintptr_t)slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
  printf("linkedit_base: 0x%llx\n", linkedit_base);
  printf("is_runtime_mode: %d\n", is_runtime_mode);
  if (is_runtime_mode == false)
  {
    // as mmap, all segment is close
    uintptr_t linkedit_segment_vmaddr = linkedit_segment->fileoff;
    linkedit_base = (uintptr_t)slide + linkedit_segment_vmaddr - linkedit_segment->fileoff;
  }

  ctx->text_seg = text_segment;
  ctx->text_exec_seg = text_exec_segment;
  ctx->data_seg = data_segment;
  ctx->data_const_seg = data_const_segment;
  ctx->linkedit_seg = linkedit_segment;

  ctx->symtab_cmd = symtab_cmd;
  ctx->dysymtab_cmd = dysymtab_cmd;
  ctx->dyld_info_cmd = dyld_info_cmd;
  ctx->exports_trie_cmd = exports_trie_cmd;
  ctx->chained_fixups_cmd = chained_fixups_cmd;

  ctx->slide = slide;
  ctx->linkedit_base = linkedit_base;
  

  ctx->symtab = (nlist_t *)(ctx->linkedit_base + ctx->symtab_cmd->symoff);
  ctx->strtab = (char *)(ctx->linkedit_base + ctx->symtab_cmd->stroff);
  ctx->indirect_symtab = (uint32_t *)(ctx->linkedit_base + ctx->dysymtab_cmd->indirectsymoff);
}

uintptr_t macho_ctx_iterate_symbol_table(macho_ctx_t *ctx, const char *symbol_name_pattern)
{
  nlist_t *symtab = ctx->symtab; //XXX
  uint32_t symtab_count = ctx->symtab_cmd->nsyms;
  char *strtab = ctx->strtab;

  for (uint32_t i = 0; i < symtab_count; i++)
  {
    // printf("symtab_count=%u\n", symtab_count);
    if (symtab[i].n_value)
    {
      uint32_t strtab_offset = symtab[i].n_un.n_strx;
      char *symbol_name = strtab + strtab_offset;
      printf("symbol_name: %s\n", symbol_name);
#if 0
      printf("> %s", symbol_name);
#endif
      if (strcmp(symbol_name_pattern, symbol_name) == 0)
      {
        return symtab[i].n_value;
      }
      if (symbol_name[0] == '_')
      {
        if (strcmp(symbol_name_pattern, &symbol_name[1]) == 0)
        {
          return symtab[i].n_value;
        }
      }
    }
  }
  return 0;
}

uint64_t read_uleb128(const uint8_t **pp, const uint8_t *end)
{
  uint8_t *p = (uint8_t *)*pp;
  uint64_t result = 0;
  int bit = 0;
  do
  {
    if (p == end)
      ASSERT(p == end);

    uint64_t slice = *p & 0x7f;

    if (bit > 63)
      ASSERT(bit > 63);
    else
    {
      result |= (slice << bit);
      bit += 7;
    }
  } while (*p++ & 0x80);

  *pp = p;

  return (uintptr_t)result;
}

uint8_t *tail_walk(const uint8_t *start, const uint8_t *end, const char *symbol)
{
  uint32_t visitedNodeOffsets[128];
  int visitedNodeOffsetCount = 0;
  visitedNodeOffsets[visitedNodeOffsetCount++] = 0;
  const uint8_t *p = start;
  while (p < end)
  {
    uint64_t terminalSize = *p++;
    if (terminalSize > 127)
    {
      // except for re-export-with-rename, all terminal sizes fit in one byte
      --p;
      terminalSize = read_uleb128(&p, end);
    }
    if ((*symbol == '\0') && (terminalSize != 0))
    {
      return (uint8_t *)p;
    }
    const uint8_t *children = p + terminalSize;
    if (children > end)
    {
      // diag.error("malformed trie node, terminalSize=0x%llX extends past end of trie\n", terminalSize);
      return NULL;
    }
    uint8_t childrenRemaining = *children++;
    p = children;
    uint64_t nodeOffset = 0;

    for (; childrenRemaining > 0; --childrenRemaining)
    {
      const char *ss = symbol;
      bool wrongEdge = false;
      // scan whole edge to get to next edge
      // if edge is longer than target symbol name, don't read past end of symbol name
      char c = *p;
      while (c != '\0')
      {
        if (!wrongEdge)
        {
          if (c != *ss)
            wrongEdge = true;
          ++ss;
        }
        ++p;
        c = *p;
      }
      if (wrongEdge)
      {
        // advance to next child
        ++p; // skip over zero terminator
        // skip over uleb128 until last byte is found
        while ((*p & 0x80) != 0)
          ++p;
        ++p; // skip over last byte of uleb128
        if (p > end)
        {
          // diag.error("malformed trie node, child node extends past end of trie\n");
          return NULL;
        }
      }
      else
      {
        // the symbol so far matches this edge (child)
        // so advance to the child's node
        ++p;
        nodeOffset = read_uleb128(&p, end);
        if ((nodeOffset == 0) || (&start[nodeOffset] > end))
        {
          // diag.error("malformed trie child, nodeOffset=0x%llX out of range\n", nodeOffset);
          return NULL;
        }
        symbol = ss;
        break;
      }
    }

    if (nodeOffset != 0)
    {
      if (nodeOffset > (uint64_t)(end - start))
      {
        // diag.error("malformed trie child, nodeOffset=0x%llX out of range\n", nodeOffset);
        return NULL;
      }
      for (int i = 0; i < visitedNodeOffsetCount; ++i)
      {
        if (visitedNodeOffsets[i] == nodeOffset)
        {
          // diag.error("malformed trie child, cycle to nodeOffset=0x%llX\n", nodeOffset);
          return NULL;
        }
      }
      visitedNodeOffsets[visitedNodeOffsetCount++] = (uint32_t)nodeOffset;
      p = &start[nodeOffset];
    }
    else
      p = end;
  }
  return NULL;
}

uint64_t macho_ctx_iterate_exported_symbol(macho_ctx_t *ctx, const char *symbol_name, uint64_t *out_flags)
{
  if (ctx->text_seg == NULL || ctx->linkedit_seg == NULL)
  {
    return 0;
  }

  struct dyld_info_command *dyld_info_cmd = ctx->dyld_info_cmd;
  struct linkedit_data_command *exports_trie_cmd = ctx->exports_trie_cmd;
  if (exports_trie_cmd == NULL && dyld_info_cmd == NULL)
    return 0;

  uint32_t trieFileOffset = dyld_info_cmd ? dyld_info_cmd->export_off : exports_trie_cmd->dataoff;
  uint32_t trieFileSize = dyld_info_cmd ? dyld_info_cmd->export_size : exports_trie_cmd->datasize;

  void *exports = (void *)(ctx->linkedit_base + trieFileOffset);
  if (exports == NULL)
    return 0;

  uint8_t *exports_start = (uint8_t *)exports;
  uint8_t *exports_end = exports_start + trieFileSize;
  uint8_t *node = (uint8_t *)tail_walk(exports_start, exports_end, symbol_name);
  if (node == NULL)
    return 0;
  const uint8_t *p = node;
  const uint64_t flags = read_uleb128(&p, exports_end);
  if (out_flags)
    *out_flags = flags;
  if (flags & EXPORT_SYMBOL_FLAGS_REEXPORT)
  {
    const uint64_t ordinal = read_uleb128(&p, exports_end);
    const char *importedName = (const char *)p;
    if (importedName[0] == '\0')
    {
      importedName = symbol_name;
      return 0;
    }
    // trick
    // printf("reexported symbol: %s\n", importedName);
    return (uint64_t)importedName;
  }
  uint64_t trieValue = read_uleb128(&p, exports_end);
  return trieValue;
}

uint64_t macho_ctx_symbol_resolve_options(macho_ctx_t *ctx, const char *symbol_name_pattern,
                                          resolve_symbol_type_t type)
{
  if (type & RESOLVE_SYMBOL_TYPE_SYMBOL_TABLE)
  {
    uint64_t result = macho_ctx_iterate_symbol_table(ctx, symbol_name_pattern);
    if (result)
    {
	  printf("ok1\n");
      result = result + (ctx->is_runtime_mode ? ctx->slide : 0);
      return result;
    }
  }

  

  if (type & RESOLVE_SYMBOL_TYPE_EXPORTED)
  {
    // binary exported table(uleb128)
    uint64_t flags;
    uint64_t result = macho_ctx_iterate_exported_symbol(ctx, symbol_name_pattern, &flags);
    if (result)
    {
      switch (flags & EXPORT_SYMBOL_FLAGS_KIND_MASK)
      {
      case EXPORT_SYMBOL_FLAGS_KIND_REGULAR:
      {
        result += (uint64_t)ctx->header;
      }
      break;
      case EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL:
      {
        result += (uint64_t)ctx->header;
      }
      break;
      case EXPORT_SYMBOL_FLAGS_KIND_ABSOLUTE:
      {
      }
      break;
      default:
        break;
      }
      return result;
    }
  }
  return 0;
}

uintptr_t macho_symbol_resolve_options(mach_header_t *header, const char *symbol_name_pattern,
                                       resolve_symbol_type_t type)
{
  macho_ctx_t ctx;
  macho_ctx_init(&ctx, header, true);
  return macho_ctx_symbol_resolve_options(&ctx, symbol_name_pattern, type);
}

uint64_t macho_symbol_resolve(mach_header_t *header, const char *symbol_name_pattern)
{
  return macho_symbol_resolve_options(header, symbol_name_pattern, RESOLVE_SYMBOL_TYPE_ALL);
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

uint64_t find_image_header(const char *image_name)
{
  uint32_t count = _dyld_image_count();
  uint64_t hdr = 0;
  for (uint32_t i = 0; i < count; i++)
  {
    const char *dyld = _dyld_get_image_name(i);
    if (strcmp(dyld, image_name) == 0)
    {
      printf("Found image_name: %s, hdr: %p\n", dyld, _dyld_get_image_header(i));
      hdr = (uint64_t)_dyld_get_image_header(i);
    }
  }
  return hdr;
}

int main(void)
{
  // dlopen("/usr/lib/system/libdyld.dylib", RTLD_NOW);
  // const char *image_name = "/usr/lib/system/libxpc.dylib";
  const char *symbol_name = "dlopen_internal";

  // dlopen(image_name, RTLD_NOW);

  const char* libPath = "/var/mobile/libxpc.dylib";
	int fd = open(libPath, O_RDONLY);
	if(fd == -1) {
		return -1;
	}

	/* Get filesize for mmap */
	size_t filesize = lseek(fd, 0, SEEK_END);
	lseek(fd, 0, SEEK_SET);

	/* Map the file */
	void* map = mmap(NULL, filesize, PROT_READ, MAP_PRIVATE, fd, 0);
	if(map == MAP_FAILED) {
		perror("mmap");
		close(fd);
		return -1;
	}



  uint64_t libdyld_hdr = (uint64_t)map;//find_image_header(image_name);

  print_symbols(map);

  // uint64_t address = macho_symbol_resolve((struct mach_header_64 *)libdyld_hdr, symbol_name);
  // printf("_dlsym address: 0x%llx\n", address);

  return 0;
}