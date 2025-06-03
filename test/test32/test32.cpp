#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "rdos.h"

void main()
{
    int dev = RdosFindPciProtocol(0, 12, 3, 48);
    unsigned char val8 = RdosReadPciConfigByte(dev, 0x10);
    short int val16 = RdosReadPciConfigWord(dev, 0x10);
    int val32 = RdosReadPciConfigDword(dev, 0x10);

    RdosWritePciConfigByte(dev, 0x10, val8);
    RdosWritePciConfigWord(dev, 0x10, val16);
    RdosWritePciConfigDword(dev, 0x10, val32);
    

//    RdosTestGate(buf);
}



