#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <math.h>

#include "rdos.h"

#define DISTANCE  100
#define PI 3.1415926373

void CalcDist(int angle)
{
    int seg = angle / 120;
    int i;
    int alfa = (angle % 120) - 60;
    double a;
    double diff[3];

    a = (double)alfa * PI / 180.0;
    diff[seg] = DISTANCE * sin(a); 

    a = (double)(60 - alfa) * PI / 180.0;
    if (seg == 2)
        i = 0;
    else
        i = seg + 1;
    diff[i] = DISTANCE * sin(a); 

    a = (double)(-60 + alfa) * PI / 180.0;
    if (seg == 0)
        i = 2;
    else
        i = seg - 1;
    diff[i] = DISTANCE * sin(a); 

    printf("%d: %d (%d) %5.1Lf %5.1Lf %5.1Lf\r\n", angle, seg, alfa, diff[0], diff[1], diff[2]);
}

void main()
{
    int i;

    for (i = 0; i < 360; i++)
        CalcDist(i);

//    RdosTestGate("");
}



