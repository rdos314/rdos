#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "serial.h"
#include "rdos.h"

#include "str.h"
#include "path.h"

struct TComMsg
{
	int Channel;
	long TimeLSB;
	long TimeMSB;
	char ch;
};

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void cdecl main()
{
	TPathName dst("d:\\neander");
	TPathName src("c:\\rdos\\apps\\neander");

	printf(src.GetBaseName().GetData());
    printf(src.GetEntryName().GetData());

	if (dst.MakeDir())
		printf("Directory %s created\r\n", dst.GetFullPathName().GetData());

	TDir dir = src.Find();
    TDirEntry entry;

	entry = dir.GotoFirst();
	while (entry.Valid)
	{
		printf(entry.PathName.GetFullPathName().GetData());
		printf(" %04d-%02d-%02d %02d.%02d.%02d,%03d",
				entry.Time.GetYear(),
				entry.Time.GetMonth(),
				entry.Time.GetDay(),
				entry.Time.GetHour(),
				entry.Time.GetMin(),
				entry.Time.GetSec(),
				entry.Time.GetMilliSec());
		printf(" %d", entry.FileSize);
		if (entry.PathName.CopyFile(dst))
			printf(", copied");
		printf("\r\n");
		entry = dir.GotoNext();
	}

	TComMsg Msg;
	char Str[10];
	int Mapping;
	char *Buf;
	int *BufSize;
	TComMsg *BufMsg;
	TWaitDevice *WaitDevice;
	TWait Wait;
	TSerialDevice Port1(&Wait, 1, 9600);
	TSerialDevice Port2(&Wait, 2, 9600);

	Mapping = RdosCreateNamedMapping("comlog", 0x800000);
	Buf = (char *)RdosAllocateMem(0x800000);
	BufSize = (int *)Buf;
	BufMsg = (TComMsg *)(Buf + 4);
	RdosMapView(Mapping, 0, Buf, 0x800000);
	*BufSize = 0;

	for (;;)
	{
		WaitDevice = Wait.WaitForever();
		RdosGetTics(&BufMsg->TimeMSB, &BufMsg->TimeLSB);
		if (WaitDevice == &Port1)
		{
			BufMsg->Channel = 1;
			BufMsg->ch = Port1.Read();
			RdosSetForeColor(9);
		}

		if (WaitDevice == &Port2)
		{
			BufMsg->Channel = 2;
			BufMsg->ch = Port2.Read();
			RdosSetForeColor(11);
		}

		sprintf(Str, "%04hX", BufMsg->ch);
		Str[0] = Str[2];
		Str[1] = Str[3];
		Str[2] = ' ';
		Str[3] = ' ';
		Str[4] = 0;
		RdosWriteString(Str);
		BufMsg++;
		(*BufSize)++;
	}
}

