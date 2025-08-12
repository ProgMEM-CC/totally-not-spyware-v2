#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dlfcn.h>
#import <spawn.h>

#import "krw.h"
#import "proc.h"
#import "offsets.h"
#import "csblob.h"
#import "kutils.h"
#import "remount.h"
#import "stage3.h"
#import "bootstrap.h"
#import "start_jailbreakd.h"
#import "rejailbreak.h"
#import "trustcache.h"
#import "alert.h"

int csops(pid_t pid, unsigned int  ops, void * useraddr, size_t usersize);

extern uint64_t g_kbase;
extern uint64_t g_kernproc;

extern uint64_t g_trustcache;

extern uint64_t g_jbd_pid;

NSMutableArray<NSString *> *files = nil;

int rejailbreak_chimera(void) {
    offsets_init();

    set_proc_csflags(getpid());
    set_csblob(getpid());

    uint64_t our_cr_label = borrow_cr_label(getpid(), 0);
    set_ucred_cr_svuid(getpid(), 0);
    setuid(0); setuid(0);

    LOG(@"uid = %d", getuid());
    if(getuid() != 0) goto err;

    uint64_t kernelsignpost_addr = write_kernelsignpost();
    LOG(@"kernelsignpost_addr = 0x%llx", kernelsignpost_addr);
    if(kernelsignpost_addr == 0)   goto err;

    int snapshot_success = list_snapshots("/");
    LOG(@"snapshot_success = %d", snapshot_success);
    if(snapshot_success != 0)   goto err;

    int remount_status = remount_root_as_rw();
    LOG(@"remount_status = %d", remount_status);
    if(remount_status != 0)     goto err;

    // extract_bootstrap(); // we don't need it for rejailbreak.
    files = @[
        @"/chimera/inject_criticald",
        @"/chimera/pspawn_payload.dylib",
        @"/chimera/pspawn_payload-stg2.dylib",
        @"/chimera/jailbreakd",
        @"/chimera/jailbreakd_client",
        @"/chimera/launchctl"
    ];
    injectTrustCache(files, g_trustcache);

    int jailbreakd_status = start_jailbreakd(g_kbase, get_allproc(), kernelsignpost_addr);
    LOG(@"jailbreakd_status = %d", jailbreakd_status);
    // if(jailbreakd_status != 0)     goto err;
    
    while (!file_exist("/var/run/jailbreakd.pid"))
        usleep(100000);
    LOG(@"start_jailbreakd success");


    // jailbreakd_client, launchd_pid, 1 (1 = entitle+platformize the target PID)
    int rv = 0;
    pid_t pd = 0;
    uint32_t flags = 0;
    #define DESIRED_FLAGS  (CS_GET_TASK_ALLOW | CS_PLATFORM_BINARY | CS_DEBUGGED)

    const char* args_jailbreakd_client_2[] = {"jailbreakd_client", "1", "1", NULL};
    rv = posix_spawn(&pd, "/chimera/jailbreakd_client", NULL, NULL, (char **)&args_jailbreakd_client_2, NULL);
    waitpid(pd, NULL, 0);

    flags = 0;
    while (true)
    {
      pid_t launchd_pid = 1;
      csops(launchd_pid, 0, &flags, 0);
      if ((flags & DESIRED_FLAGS) == DESIRED_FLAGS)
        break;
      usleep(100000);
    }
    LOG(@"jailbreakd_client success");

    // inject_criticald, 1, /chimera/pspawn_payload.dylib
    const char* args_inject_criticald[] = {"inject_criticald", "1", "/chimera/pspawn_payload.dylib", NULL};
    rv = posix_spawn(&pd, "/chimera/inject_criticald", NULL, NULL, (char **)&args_inject_criticald, NULL);
    waitpid(pd, NULL, 0);
    LOG(@"inject_criticald called success");

    dlopen("/usr/lib/pspawn_payload-stg2.dylib", RTLD_NOW);

    //maybe_setup_smth
    //not implemented

    //maybe_setup_some_sileo_packages
    run("uicache -p /Applications/Sileo.app");

    update_springboard_plist();
    LOG(@"update_springboard_plist done");

    pid_t cfprefsd_pid = pid_by_name("cfprefsd");
    kill(cfprefsd_pid, 9);
    LOG(@"cfprefsd(%u) killed", cfprefsd_pid);

    uint64_t launchd_vnode = get_vnode_at_path("/sbin/launchd");
    uint32_t launchd_v_use_count = kread32(launchd_vnode + off_vnode_v_usecount);
    kwrite32(launchd_vnode + off_vnode_v_usecount, launchd_v_use_count + 1);
    
    uint64_t xpcproxy_vnode = get_vnode_at_path("/usr/libexec/xpcproxy");
    uint32_t xpcproxy_v_use_count = kread32(xpcproxy_vnode + off_vnode_v_usecount);
    kwrite32(xpcproxy_vnode + off_vnode_v_usecount, xpcproxy_v_use_count + 1);

    unlink("/var/containers/Bundle/stage3");

    bool is_enabled_tweak = true;   // at this moment, always enabled now.
    if(is_enabled_tweak) {
        unlink("/.disable_tweakinject");
        startDaemons();
        LOG(@"done rejailbreak_chimera");
        usleep(100000u);

        unborrow_cr_label(getpid(), our_cr_label);
        int state = popup(CFSTR("re-jailbreak done"), CFSTR("Choose userspace reboot or stay\n"), CFSTR("userspace reboot"), CFSTR("stay"), NULL) + 1;
        if (state == 2) {
            return 0;
        }
        run_userspace_reboot();

    } else {
        int disable_tweakinject_fd = open("/.disable_tweakinject", O_RDWR | O_CREAT);
        close(disable_tweakinject_fd);
        LOG(@"done rejailbreak_chimera, disabled tweak injection...");
        unborrow_cr_label(getpid(), our_cr_label);
    }
    return 0;

err:
    unborrow_cr_label(getpid(), our_cr_label);
    LOG(@"failed rejailbreak_chimera");sleep(3);

    return 1;
}

void update_springboard_plist(void){
    NSDictionary *springBoardPlist = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"];
    [springBoardPlist setValue:@YES forKey:@"SBShowNonDefaultSystemApps"];
    [springBoardPlist writeToFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist" atomically:YES];
    
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithShort:0755], NSFilePosixPermissions,@"mobile",NSFileOwnerAccountName,NULL];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:@"/var/mobile/Library/Preferences/com.apple.springboard.plist" error:&error];
}

void startDaemons(){    
    pid_t pd;
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/LaunchDaemons/" error:nil];
    for (NSString *fileName in files){
        if ([fileName isEqualToString:@"jailbreakd.plist"])
            continue;
        if ([fileName isEqualToString:@"com.openssh.sshd.plist"])
            continue;
        
        NSString *fullPath = [@"/Library/LaunchDaemons" stringByAppendingPathComponent:fileName];
        
        posix_spawn(&pd, "/bin/launchctl", NULL, NULL, (char **)&(const char*[]){ "launchctl", "load", [fullPath UTF8String], NULL }, NULL);
        waitpid(pd, NULL, 0);
    }
}

int run_userspace_reboot(void) {
    pid_t pid;
    char *argv[] = {"launchctl", "reboot", "userspace", NULL};
    int status = posix_spawn(&pid, "/chimera/launchctl", NULL, NULL, argv, NULL);
    if (status == 0) {
        LOG(@"posix_spawned pid: %d\n", pid);
        if (waitpid(pid, &status, 0) == -1) {
            perror("waitpid");
        }
    } else {
        LOG(@"posix_spawn: %d(%s)\n", status, strerror(status));
    }
}

int log_launchctl_list(void) {
    pid_t pid;
    int status;

    int fd = open("/var/launchctl_log.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd == -1) {
        LOG(@"open");
        return 1;
    }

    posix_spawn_file_actions_t file_actions;
    posix_spawn_file_actions_init(&file_actions);
    posix_spawn_file_actions_adddup2(&file_actions, fd, STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&file_actions, fd, STDERR_FILENO);

    char *argv[] = {"/chimera/launchctl", "list", NULL};

    int ret = posix_spawn(&pid, argv[0], &file_actions, NULL, argv, NULL);
    if (ret != 0) {
        LOG(@"posix_spawn ret: %d", ret);
        close(fd);
        return 1;
    }
    LOG(@"posix_spawn ret: %d", ret);

    waitpid(pid, &status, 0);

    posix_spawn_file_actions_destroy(&file_actions);
    close(fd);

    if (WIFEXITED(status)) {
        LOG(@"launchctl list exited with status %d\n", WEXITSTATUS(status));
    } else {
        LOG(@"launchctl list did not exit normally\n");
    }

    return 0;
}