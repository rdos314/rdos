#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"
#include "rdos.h"
#include "file.h"

void main()
{
    int h1;
    int h2;
    int count;
    char *buf = new char[512];
    TFile file("y:/1.txt");
    TFile dup(file);

    count = file.Read(buf, 512);
    count = dup.Read(buf, 512);


//    RdosTestGate("");
}
