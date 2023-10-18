#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"
#include "rdos.h"
#include "file.h"

void main()
{
    TFile src("y:/1.txt");
    TFile dst("y:/2.txt", 0);
    int count;
    char *buf = new char[512];
    
    count = src.Read(buf, 512);

    while (count)
    {
        count = dst.Write(buf, count);
        count = src.Read(buf, 512);
    }

//    RdosTestGate("");
}
