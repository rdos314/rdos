#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#define FALSE	0
#define TRUE	!FALSE

void cdecl main()
{
    for (;;)
	{
		if (RdosWriteSerialRaw(0x26, 5, 2))
			printf("1");
		else
        	printf("0");
		RdosWaitMilli(1000);
    }
}

