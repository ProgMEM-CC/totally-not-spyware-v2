#include <stdio.h>
#include <mach/mach.h>
#include "krw.h"
#include "alert.h"
#include "rejailbreak.h"
#include "stage3.h"

#define IS_UNJAILBROKEN_DEVICE 1

mach_port_t g_hsp4;
uint64_t g_kbase;
uint64_t g_kernproc;
uint64_t g_trustcache;

uint64_t hex_to_u64(const char *s) {
    return (uint64_t)strtoull(s, NULL, 0);
}

int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
#if IS_UNJAILBROKEN_DEVICE
		sleep(1);
		setuid(0); setuid(0);	//needed setuid to get hsp4 port
		
		LOG(@"loaded.");
		
  		host_get_special_port(mach_host_self(), HOST_LOCAL_NODE, 4, &g_hsp4);
		LOG(@"hsp4: 0x%x", g_hsp4);

		int fd = open("/tmp/stage3_got_hsp4", O_CREAT | O_WRONLY, 0644);
    	if (fd >= 0) close(fd);

		// save global kernel info
		char* kbase_str = argv[1];
		g_kbase = hex_to_u64(kbase_str);
		LOG(@"kbase: 0x%llx", g_kbase);
		char* kernproc_str = argv[2];
		g_kernproc = hex_to_u64(kernproc_str);
		LOG(@"kernproc: 0x%llx", g_kernproc);
		char* trustcache_str = argv[3];
		g_trustcache = hex_to_u64(trustcache_str);
		LOG(@"trustcache: 0x%llx", g_trustcache);

		// test krw
		if(kread64(g_kbase) == 0x100000cfeedfacf) LOG(@"confirmed krw works");
#endif

		rejailbreak_chimera();

		return 0;
	}
}
