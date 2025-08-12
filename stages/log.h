#include <asl.h>

#define LOG(fmt, ...) \
    asl_log(NULL, NULL, ASL_LEVEL_ERR, "[stage2] " fmt, ##__VA_ARGS__);