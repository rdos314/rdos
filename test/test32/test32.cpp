#include <rdos.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "serial.h"

#include <math.h>

void main()
{
    int i;
    int count;
    char Line[] = "^ CS DC600416 ######## ^4C4AD55E";
    char ans[200];
    char *ptr;
    short int str[100];
    int crc32;

    ptr = strchr(&Line[2], '^');
    count = ptr - Line + 1;

    RdosAnsiToUtf16(Line, str, 50);

/*    

    count = 0;
    
    for (i = 0; i < 42; i++)
    {
        str[2 * i] = Line[i];
        str[2 * i + 1] = 0;

        count += 2;        

        if (i && Line[i] == '^')
            break;
    }

*/

    crc32 = RdosCalcCrc32(0x28348a8f, (char *)str, 2 * count);

    RdosUtf16ToAnsi(str, ans, 50);

    RdosTestGate();
}

