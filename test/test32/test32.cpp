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
    int handle2 = RdosOpenHandle("e:/test.txt", O_RDWR);
    int handle;

    RdosSetHandlePos(handle2, 25);
    handle = RdosDupHandle(handle2);

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



//    RdosSetHandleSize(handle, 0);

    scanf("%d", &dummy);

    RdosSetHandlePos(handle, 760234);
    size = RdosReadHandle(handle, buf, 455);

    RdosCloseHandle(handle);
    RdosCloseHandle(handle2);

    delete buf;

/*

    char *buf = new char[1024];

    RdosTestGate(buf);

*/
}



