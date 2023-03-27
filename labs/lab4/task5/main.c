#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/cdev.h>
#include <linux/fs.h>
#include <asm/uaccess.h>

dev_t devno;
int major = 255;
const char DEVNAME[] = "my_device";
char data[64] = "";
char data2[64] = "";

int my_open(struct inode *ip, struct file *fp)
{
    return 0;
}

int my_close(struct inode *ip, struct file *fp)
{
    return 0;
}

ssize_t my_read(struct file *fp, char __user *buf, size_t count, loff_t *loff)
{
    int ret;
    int *_data = (int *)data;
    int *_data2 = (int *)data2;
    _data2[0] = _data[0] + _data[1];
    if ((ret = copy_to_user(buf, data2, count)))
    {
        return -1;
    }
    return count;
}

ssize_t my_write(struct file *fp, const char __user *buf, size_t count, loff_t *loff)
{
    int ret;
    if ((ret = copy_from_user(data, buf, count)))
    {
        return -1;
    }
    return count;
}

struct file_operations my_fops = {
    .owner = THIS_MODULE,
    .open = my_open,
    .release = my_close,
    .read = my_read,
    .write = my_write};
struct cdev cdev;

static int my_init(void)
{
    int ret;
    devno = MKDEV(major, 0);
    ret = register_chrdev_region(devno, 1, DEVNAME);
    if (ret != 0)
    {
        return -1;
    }
    cdev.owner = THIS_MODULE;
    ret = cdev_add(&cdev, devno, 1);
    cdev_init(&cdev, &my_fops);
    if (ret < 0)
    {
        return -1;
    }
    printk("success!\n");
    return 0;
}

static void my_exit(void)
{
    cdev_del(&cdev);
    unregister_chrdev_region(devno, 1);
}

MODULE_LICENSE("GPL");
module_init(my_init);
module_exit(my_exit);