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
	int prevval = 0;
	int prevw = -1;
	int prevr = -1;
	int w;
	int r;
	int change;

	for (;;)
	{
		w = RdosWriteSerialRaw(0x26, 5, 2);
		r = RdosReadSerialRaw(0x26, 1, &val);

		if (r)
		{
			change = val != prevval;
			prevval = val;
		}
		else
			change = FALSE;

		if (!change)
			change = w != prevw;

		if (!change)
			change = r != prevr;

		prevr = r;
		prevw = w;

		if (change)
		{
			if (w)
				printf("ok, ");
			else
				printf("fail, ");

			if (r)
				printf("%ld.%ld\r\n", val / 10, val % 10);
			else
				printf("fail\r\n");
		}

		RdosWaitMilli(1000);
	}
}

