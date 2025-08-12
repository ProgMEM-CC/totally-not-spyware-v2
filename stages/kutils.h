#include <stdint.h>
#include <mach/mach.h>
#include <unistd.h>

void set_csflags(uint64_t proc);

void set_tfplatform(uint64_t proc);

void kmemcpy(uint64_t dest, uint64_t src, uint32_t length);

uint64_t borrow_ucreds(pid_t to_pid, pid_t from_pid);
void unborrow_ucreds(pid_t to_pid, uint64_t to_ucred); 