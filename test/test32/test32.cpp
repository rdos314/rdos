#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "modbus.h"
#include "datetime.h"


void main()
{
    TFile file("e:/test.bin");
    char *buf = new char[1024];
    int size;
    int dummy;

    file.SetPos(500234);
    size = file.Read(buf, 267);
    
    file.SetPos(1000234);
    size = file.Read(buf, 99);
    
    file.SetPos(100234);
    size = file.Read(buf, 567);

    file.SetSize(0);

    scanf("%d", &dummy);

    file.SetPos(760234);
    size = file.Read(buf, 455);

//    RdosTestGate("");
}



