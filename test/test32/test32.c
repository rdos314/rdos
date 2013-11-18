#include <rdos.h>
#include <stdio.h>
#include <stdlib.h>

#include <math.h>

void main()
{
    int i;
    char *str[50];
    int *param;

    RdosTestGate();

    for (;;)
        RdosWaitMilli(1000); 

}

