#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "rdos.h"

struct TComMsg
{
	int Channel;
	int TimeLSB;
	int TimeMSB;
	char ch;
};

/*##################  GetBase #########################
*   Purpose....: Get io address for port based on port nr             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int GetBase(int Port)
{
	switch (Port)
	{
		case 1:
			return 0x3F8;

		case 2:
			return 0x2F8;

		case 3:
			return 0x3E8;

		case 4:
			return 0x2E8;

		case 5:
			return 0x3A8;

		case 6:
			return 0x2A8;

		default:
			return 0;
	}
}

/*##################  GetIrq ##########################
*   Purpose....: Get irq nr for port based on port nr      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int GetIrq(int Port)
{
	switch (Port)
	{
		case 1:
			return 4;

		case 2:
			return 3;

		case 3:
			return 9;

		case 4:
			return 10;

		case 5:
			return 11;

		case 6:
			return 12;

		default:
			return 0;
	}
}

/*##################  PortAThread ##########################
*   Purpose....: Port A thread								      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
extern "C" void PortAThread(void *Data)
{
	int Handle;
	int Base;
	int Irq;
	int Mailslot;
	TComMsg Msg;
	char Reply;

	Base = GetBase(1);
	Irq = GetIrq(1);
	Handle = RdosOpenCom(Base, Irq, (int)(115200L / 19200), 'N', 8, 1, 1024, 1024);
	Mailslot = RdosGetLocalMailslot("comlog");
	for (;;)
	{
		if (RdosWaitForCom(Handle, 1000))
		{
			Msg.Channel = 1;
			RdosGetTics(&Msg.TimeMSB, &Msg.TimeLSB);
			Msg.ch = RdosReadCom(Handle);
			RdosSendMailslot(Mailslot, &Msg, sizeof(Msg), &Reply, 0);
		}
	}
}

/*##################  PortBThread ##########################
*   Purpose....: Port B thread								      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
extern "C" void PortBThread(void *Data)
{
	int Handle;
	int Base;
	int Irq;
	int Mailslot;
	TComMsg Msg;
	char Reply;

	Base = GetBase(2);
	Irq = GetIrq(2);
	Handle = RdosOpenCom(Base, Irq, (int)(115200L / 19200), 'N', 8, 1, 1024, 1024);
	Mailslot = RdosGetLocalMailslot("comlog");
	for (;;)
	{
		if (RdosWaitForCom(Handle, 1000))
		{
			Msg.Channel = 2;
			RdosGetTics(&Msg.TimeMSB, &Msg.TimeLSB);
			Msg.ch = RdosReadCom(Handle);
			RdosSendMailslot(Mailslot, &Msg, sizeof(Msg), &Reply, 0);
		}
	}
}

/*##################  main ##########################
*   Purpose....: Program entry-point	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void cdecl main()
{
	TComMsg Msg;
	char Str[10];
	int Mapping;
	char *Buf;
	int *BufSize;
	TComMsg *BufMsg;

	Mapping = RdosCreateNamedMapping("comlog", 0x200000);
	Buf = (char *)RdosAllocateMem(0x200000);
	BufSize = (int *)Buf;
	BufMsg = (TComMsg *)(Buf + 4);
	RdosMapView(Mapping, 0, Buf, 0x200000);
	*BufSize = 0;
	RdosDefineMailslot("comlog", sizeof(Msg));
	RdosCreateThread(PortAThread, "PortA", 0, 0x1000);
	RdosCreateThread(PortBThread, "PortB", 0, 0x1000);
	for (;;)
	{
		if (RdosReceiveMailslot(BufMsg) == sizeof(TComMsg))
		{
			switch (BufMsg->Channel)
			{
				case 1:
					RdosSetForeColor(9);
					break;

				case 2:
					RdosSetForeColor(11);
					break;
			}
			sprintf(Str, "%04hX", BufMsg->ch);
			Str[0] = Str[2];
			Str[1] = Str[3];
			Str[2] = ' ';
			Str[3] = ' ';
			Str[4] = 0;
//			sprintf(Str, "%c", BufMsg->ch);
			RdosWriteString(Str);
			BufMsg++;
			(*BufSize)++;
		}
		RdosReplyMailslot(0, 0);
	}
}

