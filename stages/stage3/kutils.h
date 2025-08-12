#include <stdint.h>
#include <unistd.h>
#include <mach/mach.h>

void set_proc_csflags(pid_t pid);
void set_csblob(pid_t pid);

uint64_t borrow_cr_label(pid_t to_pid, pid_t from_pid);
void unborrow_cr_label(pid_t to_pid, uint64_t to_cr_label);

void set_ucred_cr_svuid(pid_t pid, uint64_t val);

uint64_t write_kernelsignpost(void);

mach_port_t fake_host_priv(void);
uint64_t find_port(mach_port_name_t port);
uint64_t ipc_space_kernel(void);

