#include "bootstrap.h"
#include "start_jailbreakd.h"
#include "stage3.h"
#include "proc.h"

#include <stdio.h>
#include <stdlib.h>
#include <spawn.h>
#include <sys/stat.h>

#define PROC_PIDPATHINFO_MAXSIZE (4*MAXPATHLEN)
uint64_t g_jbd_pid;

int start_jailbreakd(uint64_t kbase, uint64_t allproc, uint64_t kernelsignpost_addr) {
    unlink("/var/tmp/jailbreakd.pid");
    unlink("/var/run/jailbreakd.pid");
    unlink("/var/log/jailbreakd-stderr.log.bak");
    unlink("/var/log/jailbreakd-stdout.log.bak");
    rename("/var/log/jailbreakd-stderr.log", "/var/log/jailbreakd-stderr.log.bak");
    rename("/var/log/jailbreakd-stdout.log", "/var/log/jailbreakd-stdout.log.bak");
    unlink("/var/log/pspawn_payload_launchd.log.bak");
    unlink("/var/log/pspawn_payload_xpcproxy.log.bak");
    rename("/var/log/pspawn_payload_launchd.log", "/var/log/pspawn_payload_launchd.log.bak");
    rename("/var/log/pspawn_payload_xpcproxy.log", "/var/log/pspawn_payload_xpcproxy.log.bak");

    mkdir("/Library/LaunchDaemons", 0755);
    chown("/Library/LaunchDaemons", 0, 0);

    NSData *blob = [NSData dataWithContentsOfFile:@"/chimera/jailbreakd.plist"];
    NSMutableDictionary *job = [NSPropertyListSerialization propertyListWithData:blob options:NSPropertyListMutableContainers format:nil error:nil];

    job[@"EnvironmentVariables"][@"KernelBase"] = [NSString stringWithFormat:@"0x%16llx", kbase];
    job[@"EnvironmentVariables"][@"AllProc"] = [NSString stringWithFormat:@"0x%16llx", get_allproc()];
    job[@"EnvironmentVariables"][@"KernelSignpost"] = [NSString stringWithFormat:@"0x%16llx", kernelsignpost_addr];
    
    [job writeToFile:@"/chimera/jailbreakd.plist" atomically:YES];

    chmod("/chimera/jailbreakd.plist", 0644);
    chown("/chimera/jailbreakd.plist", 0, 0);
    unlink("/Library/LaunchDaemons/jailbreakd.plist");

    pid_t pid;
    char *argv[] = {"launchctl", "load", "/chimera/jailbreakd.plist", NULL};
    int status = posix_spawn(&pid, "/chimera/launchctl", NULL, NULL, argv, NULL);
    g_jbd_pid = pid;
    if (status == 0) {
        LOG(@"posix_spawned pid: %d\n", pid);
        if (waitpid(pid, &status, 0) == -1) {
            perror("waitpid");
        }
    } else {
        LOG(@"posix_spawn: %s\n", strerror(status));
    }

    return 0;
}

static char *searchpath(const char *binaryname){
    if (strstr(binaryname, "/") != NULL){
        if (file_exist(binaryname)){
            char *foundpath = malloc((strlen(binaryname) + 1) * (sizeof(char)));
            strcpy(foundpath, binaryname);
            return foundpath;
        } else {
            return NULL;
        }
    }
    
    char *pathvar = getenv("PATH");
    
    char *dir = strtok(pathvar,":");
    while (dir != NULL){
        char searchpth[PROC_PIDPATHINFO_MAXSIZE];
        strcpy(searchpth, dir);
        strcat(searchpth, "/");
        strcat(searchpth, binaryname);
        
        if (file_exist(searchpth)){
            char *foundpath = malloc((strlen(searchpth) + 1) * (sizeof(char)));
            strcpy(foundpath, searchpth);
            return foundpath;
        }
        
        dir = strtok(NULL, ":");
    }
    return NULL;
}

static int isShellScript(const char *path){
    FILE *file = fopen(path, "r");
    uint8_t header[2];
    if (fread(header, sizeof(uint8_t), 2, file) == 2){
        if (header[0] == '#' && header[1] == '!'){
            fclose(file);
            return 1;
        }
    }
    fclose(file);
    return -1;
}

static char *getInterpreter(char *path){
    FILE *file = fopen(path, "r");
    char *interpreterLine = NULL;
    unsigned long lineSize = 0;
    getline(&interpreterLine, &lineSize, file);
    
    char *rawInterpreter = (interpreterLine+2);
    rawInterpreter = strtok(rawInterpreter, " ");
    rawInterpreter = strtok(rawInterpreter, "\n");
    
    char *interpreter = malloc((strlen(rawInterpreter)+1) * sizeof(char));
    strcpy(interpreter, rawInterpreter);
    
    free(interpreterLine);
    fclose(file);
    return interpreter;
}


static char *fixedCmd(const char *cmdStr){
    char *cmdCpy = malloc((strlen(cmdStr)+1) * sizeof(char));
    strcpy(cmdCpy, cmdStr);
    
    char *cmd = strtok(cmdCpy, " ");
    
    uint8_t size = strlen(cmd) + 1;
    
    char *args = cmdCpy + size;
    if ((strlen(cmdStr) - strlen(cmd)) == 0)
        args = NULL;
    
    char *abs_path = searchpath(cmd);
    if (abs_path){
        int isScript = isShellScript(abs_path);
        if (isScript == 1){
            char *interpreter = getInterpreter(abs_path);
            
            uint8_t commandSize = strlen(interpreter) + 1 + strlen(abs_path);
            
            if (args){
                commandSize += 1 + strlen(args);
            }
            
            char *rawCommand = malloc(sizeof(char) * (commandSize + 1));
            strcpy(rawCommand, interpreter);
            strcat(rawCommand, " ");
            strcat(rawCommand, abs_path);
            
            if (args){
                strcat(rawCommand, " ");
                strcat(rawCommand, args);
            }
            rawCommand[(commandSize)+1] = '\0';
            
            free(interpreter);
            free(abs_path);
            free(cmdCpy);
            
            return rawCommand;
        } else {
            uint8_t commandSize = strlen(abs_path);
            
            if (args){
                commandSize += 1 + strlen(args);
            }
            
            char *rawCommand = malloc(sizeof(char) * (commandSize + 1));
            strcat(rawCommand, abs_path);
            
            if (args){
                strcat(rawCommand, " ");
                strcat(rawCommand, args);
            }
            rawCommand[(commandSize)+1] = '\0';
            
            free(abs_path);
            free(cmdCpy);
            
            return rawCommand;
        }
    }
    return cmdCpy;
}

int run(const char *cmd) {
    char *myenviron[] = {
        "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games",
        "PS1=\\h:\\w \\u\\$ ",
        NULL
    };
    
    pid_t pid;
    char *rawCmd = fixedCmd(cmd);
    char *argv[] = {"sh", "-c", (char*)rawCmd, NULL};
    int status;
    status = posix_spawn(&pid, "/bin/sh", NULL, NULL, argv, (char **)&myenviron);
    if (status == 0) {
        if (waitpid(pid, &status, 0) == -1) {
            perror("waitpid");
        }
    } else {
        printf("posix_spawn: %s\n", strerror(status));
    }
    free(rawCmd);
    return status;
}

char *itoa(long n) {
    int len = n==0 ? 1 : floor(log10l(labs(n)))+1;
    if (n<0) len++; // room for negative sign '-'
    
    char    *buf = calloc(sizeof(char), len+1); // +1 for null
    snprintf(buf, len+1, "%ld", n);
    return   buf;
}