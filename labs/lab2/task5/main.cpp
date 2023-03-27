#include <unistd.h>
#include <signal.h>
#include <iostream>

using namespace std;

void child_handler(int sig)
{
    printf("Bye, Wolrd!\n");
    exit(0);
}

int main()
{
    pid_t p1 = fork();
    // 父子进程用信号量通信,当子进程收到信号时exit
    if (p1 > 0)
    {
        // 父进程
        while (1)
        {
            printf("To terminate Child Process. Yes or No?\n");
            char c;
            cin >> c;
            if (c == 'Y' || c == 'y')
            {
                kill(p1, SIGUSR1);
                exit(0);
            }
            else if (c == 'N' || c == 'n')
            {
                sleep(2);
            }
        }
    }
    else
    {
        // 子进程
        signal(SIGUSR1, child_handler);
        while (1)
        {
            printf("I am Child Process, alive!\n");
            sleep(2);
        }
    }
    return 0;
}