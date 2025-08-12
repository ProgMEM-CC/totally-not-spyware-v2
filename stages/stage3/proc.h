#include <stdio.h>
#include <unistd.h>

pid_t pid_by_name(char* nm);
uint64_t proc_by_name(char* nm);
uint64_t proc_of_pid(pid_t pid);
uint64_t get_allproc(void);