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
		RdosSetCursorPosition(6,0);

		if (RdosWriteSerialRaw(0x26, 5, 2))
			printf("ok ");
		else
			printf("-- ");

		if (RdosReadSerialRaw(0x26, 0, &val))
			printf("%4ld.%ld ", val / 10, val % 10);
		else
			printf("------ ");

		if (RdosReadSerialRaw(0x26, 1, &val))
			printf("%4ld.%ld ", val / 10, val % 10);
		else
			printf("------ ");

		if (RdosReadSerialRaw(0x26, 2, &val))
		{
			val = val * 10 / 25;
			printf("%4ld.%ld ", val / 10, val % 10);
		}
		else
			printf("------ ");

		if (RdosReadSerialRaw(0x26, 3, &val))
			printf("%4ld.%ld ", val / 10, val % 10);
		else
			printf("------ ");

		if (RdosReadSerialRaw(0x26, 4, &val))
			printf("%4ld.%ld ", val / 10, val % 10);
		else
			printf("------ ");

		RdosWaitMilli(1000);
	}
}

