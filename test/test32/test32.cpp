#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "modbus.h"
#include "datetime.h"
#include "videodev.h"
#include "table.h"

void main()
{

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


    int i;
    char *buf = new char[1024];
    int size;
    int dummy;
    long long pos;
    int handle = RdosOpenHandle("e:/9.log", O_RDWR);
    int handle1 = RdosOpenHandle("e:/1.log", O_RDWR);
    int handle2 = RdosOpenHandle("e:/2.log", O_RDWR);
    int handle3 = RdosOpenHandle("e:/3.log", O_RDWR);
    int handle4 = RdosOpenHandle("e:/4.log", O_RDWR);
    int handle5 = RdosOpenHandle("e:/5.log", O_RDWR);
    int handle6 = RdosOpenHandle("e:/6.log", O_RDWR);
    int handle7 = RdosOpenHandle("e:/7.log", O_RDWR);
    int handle8 = RdosOpenHandle("e:/8.log", O_RDWR);
    int handle9 = RdosOpenHandle("e:/9.log", O_RDWR);

    RdosSetHandlePos(handle, 25);
    handle2 = RdosDupHandle(handle);

    pos = RdosGetHandlePos(handle);
    pos = RdosGetHandlePos(handle2);

    size = RdosGetHandleSize(handle);
    size = RdosGetHandleSize(handle2);

    size = RdosReadHandle(handle, buf, 267);

    RdosTestGate(buf);

    RdosSetHandlePos(handle, 500234);
    size = RdosReadHandle(handle, buf, 267);

    pos = RdosGetHandlePos(handle);
    pos = RdosGetHandlePos(handle2);

    RdosSetHandlePos(handle, 1000234);
    size = RdosReadHandle(handle, buf, 99);

    RdosSetHandlePos(handle, 1000234);
    size = RdosReadHandle(handle, buf, 567);


    RdosCloseHandle(handle1);
    RdosCloseHandle(handle8);
    RdosCloseHandle(handle2);
    RdosCloseHandle(handle);
    RdosCloseHandle(handle6);
    RdosCloseHandle(handle9);
    RdosCloseHandle(handle7);
    RdosCloseHandle(handle3);
    RdosCloseHandle(handle4);
    RdosCloseHandle(handle5);


//    RdosSetHandleSize(handle, 0);

    scanf("%d", &dummy);

    RdosSetHandlePos(handle, 760234);
    size = RdosReadHandle(handle, buf, 455);

    RdosCloseHandle(handle);
    RdosCloseHandle(handle2);

    handle = RdosOpenHandle("e:/test.txt", O_RDWR);
    RdosCloseHandle(handle);

    delete buf;


/*
    char *buf = new char[1024];

    RdosTestGate(buf);

*/
}



