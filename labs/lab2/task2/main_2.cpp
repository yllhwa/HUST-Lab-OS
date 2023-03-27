#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>
#include <stdlib.h>
int main()
{
    pid_t p1 = fork();
    if (p1 > 0)
    {
        printf("[father]father pid:%d\n", getpid());
        printf("[father]chile pid:%d\n", p1);
        // 等待子进程结束，获取子进程的退出状态
        int status;
        wait(&status);
        printf("[father]child exit status:*%d*\n", WEXITSTATUS(status));
        printf("[father]end of father process\n");
    }
    else
    {
        printf("[child]child pid:%d\n", getpid());
        printf("[child]get parent pid:%d\n", getppid());
        printf("[child]sleep(5)\n");
        sleep(5);
        printf("[child]end of child process\n");
        exit(66);
    }
    return 0;
}