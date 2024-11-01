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
    int handle2 = RdosOpenNewHandle("b:/safe.bin", O_RDWR);
    int handle = RdosOpenNewHandle("b:/safe.bin", O_RDWR);

//    size = RdosReadNewHandle(0, buf, 267);
    RdosWriteNewHandle(1, "Test of output\r\n", 16);
    RdosWriteNewHandle(2, "Test of error\r\n", 15);

    size = RdosReadNewHandle(handle, buf, 267);

    RdosTestGate(buf);

    RdosSetNewHandlePos(handle, 500234);
    size = RdosReadNewHandle(handle, buf, 267);

    pos = RdosGetNewHandlePos(handle);
    pos = RdosGetNewHandlePos(handle2);

    RdosSetNewHandlePos(handle, 1000234);
    size = RdosReadNewHandle(handle, buf, 99);

    RdosSetNewHandlePos(handle, 1000234);
    size = RdosReadNewHandle(handle, buf, 567);



//    RdosSetHandleSize(handle, 0);

    scanf("%d", &dummy);

    RdosSetNewHandlePos(handle, 760234);
    size = RdosReadNewHandle(handle, buf, 455);

    RdosCloseNewHandle(handle);
    RdosCloseNewHandle(handle2);

    delete buf;

/*

    char *buf = new char[1024];

    RdosTestGate(buf);

*/
}



