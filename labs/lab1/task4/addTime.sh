# 判断参数是否为空
if [ $# -eq 0 ]; then
    echo "Usage: $0 directory"
    exit 1
fi

str_insert=`date +%Y-%m-%d-%H-%M`

for file in `ls -p $1 | grep -v / `; do
    # 正则判断后缀是否有%Y-%m-%d-%H-%M
    if [[ $file =~ ^.*[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "file $file already has time"
    else
        # 重命名
        mv $1/$file $1/$file-$str_insert
        echo "file $file add time"
    fi
done
