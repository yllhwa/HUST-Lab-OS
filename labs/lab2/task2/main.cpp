#include <unistd.h>
#include <stdio.h>
int main()
{
    pid_t p1 = fork();
    if (p1 > 0)
    {
        printf("[father]father pid:%d\n", getpid());
        printf("[father]chile pid:%d\n", p1);
        printf("[father]sleep(2)\n");
        sleep(2);
        printf("[father]end of father process\n");
    }
    else
    {
        printf("[child]child pid:%d\n", getpid());
        printf("[child]get parent pid:%d\n", getppid());
        sleep(4);
        printf("\n[child]get parent pid(again):%d\n", getppid());
        printf("[child]end of child process\n");
        getchar();
    }
    return 0;
}