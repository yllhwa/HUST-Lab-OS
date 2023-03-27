#include <pthread.h>
#include <unistd.h>
#include <iostream>
#include <mutex>

#define BUFFER_SIZE 10

using namespace std;

// 使用数组实现队列(线程安全)
typedef struct
{
    int data[BUFFER_SIZE];
    int front; // 队头
    int rear;  // 队尾
    mutex mtx; // 互斥锁
} Queue;

// 初始化队列
void initQueue(Queue *q)
{
    q->front = 0;
    q->rear = 0;
}

// 判断队列是否为空
bool isEmpty(Queue *q)
{
    return q->front == q->rear;
}

// 判断队列是否已满
bool isFull(Queue *q)
{
    return (q->rear + 1) % BUFFER_SIZE == q->front;
}

// 入队
int enqueue(Queue *q, int x)
{
    q->mtx.lock();
    int status = 0;
    if (isFull(q))
    {
        status = -1;
    }
    else
    {
        q->data[q->rear] = x;
        q->rear = (q->rear + 1) % BUFFER_SIZE;
    }
    q->mtx.unlock();
    return status;
}

// 出队
int dequeue(Queue *q)
{
    q->mtx.lock();
    int data;
    if (isEmpty(q))
    {
        data = -1;
    }
    else
    {
        data = q->data[q->front];
        q->front = (q->front + 1) % BUFFER_SIZE;
    }
    q->mtx.unlock();
    return data;
}

Queue q;

void *producer_1(void *)
{
    for (;;)
    {
        // 数据1000-1999
        int data = rand() % 1000 + 1000;
        enqueue(&q, data);
        printf("producer 1: %d\n", data);
        // 随机等待100ms-1000ms
        usleep(rand() % 1000 * 1000 + 100 * 1000);
    }
    return NULL;
}

void *producer_2(void *)
{
    for (;;)
    {
        // 数据2000-2999
        int data = rand() % 1000 + 2000;
        enqueue(&q, data);
        printf("producer 2: %d\n", data);
        // 随机等待100ms-1000ms
        usleep(rand() % 1000 * 1000 + 100 * 1000);
    }
    return NULL;
}

void *consumer(void *)
{
    for (;;)
    {
        int data = dequeue(&q);
        if (data != -1)
        {
            printf("consumer: %d\n", data);
        }
        // 随机等待100ms-1000ms
        usleep(rand() % 1000 * 1000 + 100 * 1000);
    }
    return NULL;
}

int main()
{
    // 两个线程，2个生产者，3个消费者
    initQueue(&q);
    pthread_t id[5];
    // 生产者
    pthread_create(&id[0], NULL, producer_1, NULL);
    pthread_create(&id[1], NULL, producer_2, NULL);
    // 消费者
    pthread_create(&id[2], NULL, consumer, NULL);
    pthread_create(&id[3], NULL, consumer, NULL);
    pthread_create(&id[4], NULL, consumer, NULL);
    for (int i = 0; i < 5; i++)
    {
        pthread_join(id[i], NULL);
    }
    return 0;
}