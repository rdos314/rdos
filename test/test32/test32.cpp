#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "disc.h"
#include "serial.h"

void main()
{
    int i;
    int j;
    int c;
    unsigned char m;
    char base[10];

    for (i = 0; i < 256; i++)
    {
        c = 0;
        m = 1;

        for (j = 0; j < 8; j++)
        {
            if (m & i)
                c++;
            m = m << 1;
        }

        base[0] = 'c';
        m = 1;

        for (j = 7; j >= 0; j--)
        {
            if (m & i)
                base[j + 1] = '1';
            else
                base[j + 1] = '0';
            m = m << 1;
        }

        base[9] = 0;

        printf("%s DB %d\r\n", base, c); 
    }



//    RdosTestGate("");
}
