#include <iostream>
#include <time.h>
using namespace std;

// 页大小
#define PAGE_SIZE 16
// 页框数
#define PAGE_NUM 8
// 访问序列长度
#define INSTRUCTION_NUM 1000

// 进程大小
#define PROCESS_SIZE ((PAGE_SIZE)*150)
int process[PROCESS_SIZE];
int page[PAGE_NUM][PAGE_SIZE];
typedef struct
{
    int page_num;
    int count;
} PageItem;
PageItem page_table[PAGE_NUM];
int instruction[INSTRUCTION_NUM];
int miss_count = 0;
int hit_count = 0;

// LRU算法查询页表
int SearchPageTable(int page_num)
{
    for (int i = 0; i < PAGE_NUM; i++)
    {
        if (page_table[i].page_num == page_num)
        {
            // 自身计数器置为0，其他计数器加1
            page_table[i].count = 0;
            for (int j = 0; j < PAGE_NUM; j++)
            {
                if (j != i)
                {
                    page_table[j].count++;
                }
            }
            return i;
        }
    }
    return -1;
}

// 加载页
int LoadPage(int page_num)
{
    int page_table_index;
    // 查找页表
    page_table_index = SearchPageTable(page_num);
    // 页表中有该页
    if (page_table_index != -1)
    {
        printf("hit page %d,", page_num);
        hit_count++;
        return page_table_index;
    }
    // 页表中没有该页
    else
    {
        printf("miss page %d,", page_num);
        miss_count++;
        // 查找是否有空闲页框
        for (int i = 0; i < PAGE_NUM; i++)
        {
            if (page_table[i].page_num == -1)
            {
                // 将页框号赋给页表
                page_table[i].page_num = page_num;
                // 将页框计数器置为0
                page_table[i].count = 0;
                // 加载页
                for (int j = 0; j < PAGE_SIZE; j++)
                {
                    page[i][j] = process[page_num * PAGE_SIZE + j];
                }
                // 其他页框计数器加1
                for (int j = 0; j < PAGE_NUM; j++)
                {
                    if (j != i)
                    {
                        page_table[j].count++;
                    }
                }
                return i;
            }
        }
        // 查找计数器最大的页
        int max_count = 0;
        for (int i = 0; i < PAGE_NUM; i++)
        {
            if (page_table[i].count > max_count)
            {
                max_count = page_table[i].count;
                page_table_index = i;
            }
        }
        // 将该页替换
        page_table[page_table_index].page_num = page_num;
        page_table[page_table_index].count = 0;
        for (int i = 0; i < PAGE_SIZE; i++)
        {
            page[page_table_index][i] = process[page_num * PAGE_SIZE + i];
        }
        for (int i = 0; i < PAGE_NUM; i++)
        {
            if (i != page_table_index)
            {
                page_table[i].count++;
            }
        }
        return page_table_index;
    }
}

void InitProcess()
{
    for (int i = 0; i < PROCESS_SIZE; i++)
    {
        process[i] = rand();
    }
}

void InitPageTable()
{
    for (int i = 0; i < PAGE_NUM; i++)
    {
        page_table[i].page_num = -1;
        page_table[i].count = 0;
    }
}

#define RAND_SIZE 50
void InitInstruction()
{
    for (int i = 0; i < INSTRUCTION_NUM; i++)
    {
        instruction[i] = (i + (rand() % RAND_SIZE - RAND_SIZE / 2)) % PROCESS_SIZE;
        if (instruction[i] < 0)
        {
            instruction[i] += PROCESS_SIZE;
        }
    }
}

int main()
{
    srand((unsigned)time(NULL));
    InitProcess();
    InitPageTable();
    InitInstruction();
    // 访问指令序列
    for (int i = 0; i < INSTRUCTION_NUM; i++)
    {
        int page_num = instruction[i] / PAGE_SIZE;
        int offset = instruction[i] % PAGE_SIZE;
        int page_table_index = LoadPage(page_num);
        printf("content: %d\n", page[page_table_index][offset]);
    }
    printf("hit rate: %.2f%%\n", hit_count * 100 / (float)(hit_count + miss_count));
}