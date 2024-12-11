#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "rdos.h"
#include "keyboard.h"
#include "modbus.h"
#include "datetime.h"
#include "videodev.h"
#include "table.h"

long long TimeoutCallback(void *param, long long expire)
{
    return 0;
}

void main()
{
    RdosCreateTimerThread();

/*

    int handle = open("e:/test.txt", O_RDWR);
    int count;
    char buf[10];

    count = read(handle, buf, 10);

    while (count)
        count = read(handle, buf, 10);

    close(handle);

*/    



/*    TFile file("e:/test.bin");
    char *buf = new char[1024];
    int size;
    int dummy;

    file.SetPos(500234);
    size = file.Read(buf, 267);

    file.SetPos(1000234);
    size = file.Read(buf, 99);

    file.SetPos(100234);
    size = file.Read(buf, 567);

    scanf("%d", &dummy);

    file.SetPos(760234);
    size = file.Read(buf, 455);

*/

/*

    int i;
    char *buf = new char[1024];
    int size;
    int dummy;
    long long pos;
    int handle = RdosOpenHandle("e:/test.bin", O_RDWR);
    int handle2;

    handle2 = RdosDupHandle(handle);
    RdosSetHandlePos(handle, 25);

    size = RdosReadHandle(handle, buf, 267);

    if (!RdosFork())
    {
        pos = RdosGetHandlePos(handle);
        printf("Pos 1: %lld\r\n", pos);

        pos = RdosGetHandlePos(handle2);
        printf("Pos 2: %lld\r\n", pos);

        size = RdosGetHandleSize(handle);
        printf("Size 1: %d\r\n", size);

        size = RdosGetHandleSize(handle2);
        printf("Size 2: %d\r\n", size);

        size = RdosReadHandle(handle, buf, 267);
        printf("Read: %d\r\n", size);

//        RdosCloseHandle(handle2);
//        RdosCloseHandle(handle);

        exit(0);
    }

    pos = RdosGetHandlePos(handle);
    pos = RdosGetHandlePos(handle2);

    size = RdosGetHandleSize(handle);
    size = RdosGetHandleSize(handle2);

    RdosTestGate(buf);

    RdosSetHandlePos(handle, 500234);
    size = RdosReadHandle(handle, buf, 267);

    pos = RdosGetHandlePos(handle);
    pos = RdosGetHandlePos(handle2);

    RdosSetHandlePos(handle, 1000234);
    size = RdosReadHandle(handle, buf, 99);

    RdosSetHandlePos(handle, 1000234);
    size = RdosReadHandle(handle, buf, 567);


    RdosCloseHandle(handle2);
    RdosCloseHandle(handle);


//    RdosSetHandleSize(handle, 0);

    scanf("%d", &dummy);

    RdosSetHandlePos(handle, 760234);
    size = RdosReadHandle(handle, buf, 455);

    RdosCloseHandle(handle);
    RdosCloseHandle(handle2);

    handle = RdosOpenHandle("e:/test.txt", O_RDWR);
    RdosCloseHandle(handle);

    delete buf;


*/

/*
    char *buf = new char[1024];

    RdosTestGate(buf);

*/

}



