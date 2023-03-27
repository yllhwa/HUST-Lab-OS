#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

#define GAP 0.2*1000*1000

void *ThreadA(void *)
{
    for (int i = 1; i <= 1000; i++)
    {
        printf("A:%d\n", i);
        usleep(GAP);
    }
    return NULL;
}

void *ThreadB(void *)
{
    for (int i = 1000; i >=1; i--)
    {
        printf("B:%d\n", i);
        usleep(GAP);
    }
    return NULL;
}

int main()
{
    pthread_t id[2];
    pthread_create(&id[0], NULL, ThreadA, NULL);
    pthread_create(&id[1], NULL, ThreadB, NULL);
    pthread_join(id[0], NULL);
    pthread_join(id[1], NULL);
    return 0;
}