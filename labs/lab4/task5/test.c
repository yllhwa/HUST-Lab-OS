#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <stdio.h>

int main(char argc, char *argv[])
{
    int fd;
    int ret;
    int num[2] = {114, 514};
    char *num_p = (char *)num;

    fd = open("/dev/my_device", O_RDWR);
    if (fd < 0)
    {
        perror("fail to open file");
        return -1;
    }
    ret = write(fd, num_p, sizeof(num));
    if (ret < 0)
    {
        printf("read err!");
        return -1;
    }

    ret = read(fd, num_p, sizeof(num));
    if (ret < 0)
    {
        printf("read err!");
        return -1;
    }
    printf("result = %d\n", num[0]);
    close(fd);
    return 0;
}
