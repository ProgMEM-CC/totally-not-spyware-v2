#include "bootstrap.h"
#include "NSData+GZip.h"
#include "stage3.h"
#include "trustcache.h"

#include <sys/stat.h>
#include <stdlib.h>
#include <stdio.h>
#include <mach-o/dyld.h>
#include <copyfile.h>
#include <spawn.h>
#include <unistd.h>
#include <sys/errno.h>

#define PREPARE_BOOTSTRAP 0

// we don't need bootstrap for rejailbreak
#if PREPARE_BOOTSTRAP
#include "chimera/basebinaries_tar.h"
#include "chimera/launchctl_gz.h"
#include "chimera/rm_gz.h"
#include "chimera/tar_gz.h"
#include "chimera/jailbreakd_arm64.h"
#endif

extern uint64_t g_trustcache;

#define cp(to, from) copyfile(from, to, 0, COPYFILE_ALL)

void write_file(const char *path, const unsigned char *data, size_t size) {
    FILE *f = fopen(path, "wb");
    if (f) {
        fwrite(data, 1, size, f);
        fclose(f);
    }
}

int prepare_bootstrap() {
#if PREPARE_BOOTSTRAP
    unlink("/tmp/rm.gz");
    unlink("/tmp/basebinaries.tar");
    unlink("/tmp/tar.gz");
    unlink("/tmp/launchctl.gz");

    write_file("/tmp/rm.gz", rm_gz, sizeof(rm_gz));
    write_file("/tmp/basebinaries.tar", basebinaries_tar, sizeof(basebinaries_tar));
    write_file("/tmp/tar.gz", tar_gz, sizeof(tar_gz));
    write_file("/tmp/launchctl.gz", launchctl_gz, sizeof(launchctl_gz));

    chmod("/tmp/rm.gz", 0777);
    chmod("/tmp/basebinaries.tar", 0777);
    chmod("/tmp/tar.gz", 0777);
    chmod("/tmp/launchctl.gz", 0777);

    if(!file_exist("/tmp/rm.gz"))   return 1;
    if(!file_exist("/tmp/basebinaries.tar"))   return 2;
    if(!file_exist("/tmp/tar.gz"))   return 3;
    if(!file_exist("/tmp/launchctl.gz"))   return 4;
#endif
    return 0;
}


void extract_bootstrap() {
    //we need tar, rm, basebinaries.tar, and launchctl
    //we don't need actually this function for rejailbreak, but leave here.

    int status = prepare_bootstrap();
    LOG(@"prepare_bootstrap ret = %d", status);

    mkdir("/chimera", 0755);
    extractGz("/tmp/tar.gz", "/chimera/tar");
    chmod("/chimera/tar", 0755);
    NSMutableArray<NSString *> *tc_files = @[
        @"/chimera/tar"
    ];
    injectTrustCache(tc_files, g_trustcache);

    unlink("/chimera/jailbreakd");
    unlink("/chimera/jailbreakd_client");
    unlink("/chimera/pspawn_payload.dylib");

    extractGz("/tmp/rm.gz", "/chimera/rm");
    chmod("/chimera/rm", 0755);

    pid_t pd;
    posix_spawn(&pd, "/chimera/tar", NULL, NULL, (char **)&(const char*[]){ "/chimera/tar", "-xpf", "/tmp/basebinaries.tar", "-C", "/chimera", NULL }, NULL);
    waitpid(pd, NULL, 0);

    unlink("/chimera/launchctl");
    extractGz("/tmp/launchctl.gz", "/chimera/launchctl");
    chmod("/chimera/launchctl", 0755);

    if (!file_exist("/bin/launchctl"))
    {
        cp("/bin/launchctl", "/chimera/launchctl");
        chmod("/bin/launchctl", 0755);
    }

    unlink("/usr/lib/pspawn_payload-stg2.dylib");
    cp("/usr/lib/pspawn_payload-stg2.dylib", "/chimera/pspawn_payload-stg2.dylib");

    tc_files = @[
        @"/chimera/inject_criticald",
        @"/chimera/pspawn_payload.dylib",
        @"/chimera/pspawn_payload-stg2.dylib",
        @"/chimera/jailbreakd",
        @"/chimera/jailbreakd_client",
        @"/chimera/launchctl"
    ];
    injectTrustCache(tc_files, g_trustcache);
}

void extractGz(const char *from, const char *to) {
    NSData *gz = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:from]];
    NSData *extracted = [gz gunzippedData];
    int fd = open(to, O_CREAT | O_WRONLY, 0755);
    write(fd, [extracted bytes], [extracted length]);
    close(fd);
}

const char* realPath() {
    char path[4096];
    uint32_t size = sizeof(path);
    _NSGetExecutablePath(path, &size);
    char *pt = realpath(path, NULL);
    return pt;
}

const char* progname(const char* prog) {
    NSString *execpath = [[NSString stringWithUTF8String:realPath()] stringByDeletingLastPathComponent];

    NSString *bootstrap = [execpath stringByAppendingPathComponent:[NSString stringWithUTF8String:prog]];
    return [bootstrap UTF8String];
}

int file_exist(const char *filename) {
    struct stat buffer;
    int r = stat(filename, &buffer);
    return (r == 0);
}