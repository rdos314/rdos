#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "datetime.h"
#include "device.h"

#define FALSE	0
#define TRUE	!FALSE

class TRad : public TDevice
{
public:
	TRad(int Address, int Row);

	void DeviceName(char *Name, int Size) const;

protected:
	virtual void Execute();

	int FAddress;
	int FRow;

};

TRad::TRad(int Address, int Row)
{
	char str[40];

	FAddress = Address;
	FRow = Row;

	sprintf(str, "RAD %d", Address);
	Start(str, 0x2000);
}

void TRad::DeviceName(char *Name, int Size) const
{
	strcpy(Name, "RAD");
}

void TRad::Execute()
{
	int val;

	while (FInstalled)
	{
		RdosSetCursorPosition(FRow + 1,0);

		if (RdosWriteSerialRaw(FAddress, 5, 2))
			printf("ok ");
		else
			printf("-- ");

		if (RdosReadSerialRaw(FAddress, 0, &val))
			printf("%4ld.%ld ", val / 10, val % 10);
		else
			printf("------ ");

		if (RdosReadSerialRaw(FAddress, 1, &val))
			printf("%4ld.%ld ", val / 10, val % 10);
		else
			printf("------ ");

		if (RdosReadSerialRaw(FAddress, 2, &val))
		{
			val = val * 10 / 25;
			printf("%4ld.%ld ", val / 10, val % 10);
		}
		else
			printf("------ ");

		if (RdosReadSerialRaw(FAddress, 3, &val))
			printf("%4ld.%ld ", val / 10, val % 10);
		else
			printf("------ ");

		if (RdosReadSerialRaw(FAddress, 4, &val))
			printf("%4ld.%ld ", val / 10, val % 10);
		else
			printf("------ ");

		RdosWaitMilli(1000);
	}
}

void cdecl main()
{
	TRad *RadArr[8];
	int i;
	int diostat;
	int mask;
	TDateTime CurrTime;

	for (i = 0; i < 8; i++)
		RadArr[8] = new TRad(0x20 + i, i);

	for (;;)
	{
		RdosSetCursorPosition(0,0);

		if (RdosReadSerialLines(1, &diostat))
		{
			mask = 0x80;
			for (i = 0; i < 8; i++)
			{
				if (diostat & mask)
					printf("1");
				else
					printf("0");
				mask = mask >> 1;
			}

			if (CurrTime.GetHour() >= 21 || CurrTime.GetHour() <= 2)
			{
				if ((diostat & 1) == 0)
					RdosToggleSerialLine(1, 0);

				if ((diostat & 0x80) == 0)
					RdosToggleSerialLine(1, 7);
			}
			else
			{
				if (diostat & 1)
					RdosToggleSerialLine(1, 0);

				if (diostat & 0x80)
					RdosToggleSerialLine(1, 7);
			}
		}
		else
			printf("------");
		RdosWaitMilli(1000);
	}
}

