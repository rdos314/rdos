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
    int val;
    
	for (;;)
	{
		if (RdosWriteSerialRaw(0x26, 5, 2))
			printf("ok, ");
		else
        	printf("fail, ");

		if (RdosReadSerialRaw(0x26, 1, &val))
			printf("%ld.%ld\r\n", val / 10, val % 10);
		else
			printf("fail\r\n");
		RdosWaitMilli(1000);
	}
}

