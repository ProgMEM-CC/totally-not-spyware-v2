#include <stdint.h>

int run(const char *cmd);
static char *fixedCmd(const char *cmdStr);
int start_jailbreakd(uint64_t kbase, uint64_t allproc, uint64_t kernelsignpost_addr);
char *itoa(long n);