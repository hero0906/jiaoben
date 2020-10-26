#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
main()
{
    int fd;
    char s[] = "just test open flag truncate!\n";

    fd = open("/mnt/yrfs/vdb_control.file", O_WRONLY|O_TRUNC);
    write(fd, s, sizeof(s));
    close(fd);

    printf("write ok!\n");

    return 0;
}
