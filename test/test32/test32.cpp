#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "realtime.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : main
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void main()
{
    int i;
    int start = 0x7FAE00;
    int a = start;
    int bit;

    for (;;)
    {
        printf("%04hX\r\n", (a >> 9) & 0x3FFF);

        for (i = 0; i < 14; i++)
        {
            bit = (((a >> 22) ^ (a >> 17)) & 1); 
            a = (a << 1) | bit;
        }
    }
}
