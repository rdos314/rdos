#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "serial.h"
#include "rdos.h"

#include "str.h"

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
	TString str1("Part 1");
	TString str2("Part 2");

	str2 = str1 + "," + str2;
	str2.Upper();
	str2.Lower();
	printf(str2.Find(','));

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

