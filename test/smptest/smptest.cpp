#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "rdos.h"

struct TSenderInfo
{
	int Ip;
	char MailslotName[256];
	char SenderName[256];
	int Row;
	int Col;
};

struct TReceiverInfo
{
	char MailslotName[256];
	char ReceiverName[256];
	int Row;
	int Col;
};

extern "C" void SenderThread(void *Data)
{
	char Msg[512];
	char Buf[512];
	int Handle;
	int Count = 0;
	TSenderInfo *SenderInfo = (TSenderInfo *)Data;

	Handle = 0;
	while (!Handle)
	{
		if (SenderInfo->Ip)
			Handle = RdosGetRemoteMailslot(SenderInfo->Ip, SenderInfo->MailslotName);
		else
			Handle = RdosGetLocalMailslot(SenderInfo->MailslotName);
		if (!Handle)
			RdosWaitMilli(100);
	}

	for (;;)
	{
		sprintf(Msg, "%s %d", SenderInfo->SenderName, Count);
		RdosSendMailslot(Handle, Msg, strlen(Msg) + 1, Buf, sizeof(Buf));
		if (Count % 10 == 0)
		{
			RdosSetCursorPosition(SenderInfo->Row, SenderInfo->Col);
			RdosWriteString(Buf);
		}
		Count++;
	}
}

extern "C" void ReceiverThread(void *Data)
{
	char Buf[512];
	char Reply[512];
	int Size;
	TReceiverInfo *ReceiverInfo = (TReceiverInfo *)Data;

	RdosDefineMailslot(ReceiverInfo->MailslotName, sizeof(Buf));
	for (;;)
	{
		Size = RdosReceiveMailslot(Buf);
//		RdosSetCursorPosition(ReceiverInfo->Row, ReceiverInfo->Col);
//		RdosWriteString(Buf);
		strcpy(Reply, ReceiverInfo->ReceiverName);
		strcat(Reply, Buf);
		RdosReplyMailslot(Reply, strlen(Reply) + 1);
	}
}

void CreateSender(const char *MailslotName, const char *SenderName, int Row, int Col)
{
	TSenderInfo *SenderInfo;

	SenderInfo = new TSenderInfo;
	strcpy(SenderInfo->MailslotName, MailslotName);
	strcpy(SenderInfo->SenderName, SenderName);
	SenderInfo->Row = Row;
	SenderInfo->Col = Col;
	SenderInfo->Ip = 0;
	RdosCreateThread(SenderThread, SenderName, SenderInfo, 0x2000);
}


void CreateSender(int Ip, const char *MailslotName, const char *SenderName, int Row, int Col)
{
	TSenderInfo *SenderInfo;

	SenderInfo = new TSenderInfo;
	strcpy(SenderInfo->MailslotName, MailslotName);
	strcpy(SenderInfo->SenderName, SenderName);
	SenderInfo->Row = Row;
	SenderInfo->Col = Col;
	SenderInfo->Ip = Ip;
	RdosCreateThread(SenderThread, SenderName, SenderInfo, 0x2000);
}

void CreateReceiver(const char *MailslotName, const char *ReceiverName, int Row, int Col)
{
	TReceiverInfo *ReceiverInfo;

	ReceiverInfo = new TReceiverInfo;
	strcpy(ReceiverInfo->MailslotName, MailslotName);
	strcpy(ReceiverInfo->ReceiverName, ReceiverName);
	ReceiverInfo->Row = Row;
	ReceiverInfo->Col = Col;
	RdosCreateThread(ReceiverThread, ReceiverName, ReceiverInfo, 0x2000);
}

void WriteHeader(const char *Comment)
{
	RdosSetCursorPosition(22,0);
	RdosWriteString("                                                                                 ");
	RdosSetCursorPosition(23,0);
	RdosWriteString("                                                                                 ");
	RdosSetCursorPosition(22,0);
	RdosWriteString(Comment);
}

void WriteError(const char *Error)
{
	RdosSetCursorPosition(22,0);
	RdosWriteString("                                                                                 ");
	RdosSetCursorPosition(23,0);
	RdosWriteString("                                                                                 ");
	RdosSetCursorPosition(23,0);
	RdosWriteString(Error);
	RdosWaitMilli(1000);
}

void WriteNode(int Col, int Node)
{
	unsigned long Temp;
	int n0,n1,n2,n3;
	char buf[256];
	int count;

	RdosSetCursorPosition(0, Col);
	RdosWriteString("                    ");
	RdosSetCursorPosition(1, Col);
	RdosWriteString("                    ");

	RdosSetCursorPosition(0, Col);

	Temp = (unsigned long)Node;
	n3 = Temp & 0xFF;
	Temp = Temp >> 8;
	n2 = Temp & 0xFF;
	Temp = Temp >> 8;
	n1 = Temp & 0xFF;
	Temp = Temp >> 8;
	n0 = Temp & 0xFF;
	printf("%d.%d.%d.%d", n3, n2, n1, n0);
	count = RdosIpToName(Node, buf, 256);
	if (count)
	{
		RdosSetCursorPosition(1, Col);
		buf[count] = 0;
		RdosWriteString(buf);
	}
}

void WriteMailslot(int Col, const char *MailslotName)
{
	RdosSetCursorPosition(2, Col);
	RdosWriteString("                    ");

	RdosSetCursorPosition(2, Col);
	RdosWriteString(MailslotName);
}

void InputMailslot(int Index)
{
	int Receivers;
	int Node;
	char buf[256];
	char MailslotName[256];
	int n0,n1,n2,n3;
	int LocalSenders;
	int SmpSenders;
	char Name[32];
	int Col = Index * 20;
	int i;
	char ch;

	Node = 0;

	while (!Node)
	{
		RdosClearKeyboard();
		WriteHeader("Define a receiver?> ");
		ch = (char)RdosReadKeyboard();
		switch (ch)
		{
			case 'y':
			case 'Y':
				Receivers = 1;
				Node = 127;
				break;

			case 'n':
			case 'N':
				Receivers = 0;
				Node = 127;
				break;
		}

		if (Node)
		{
			if (!Receivers)
			{
				Node = 0;
				WriteHeader("Input host to send to> ");
				buf[0] = 0;
				scanf("%s", buf);
				if (strlen(buf))
				{
					if (isdigit(buf[0]))
					{
						if (sscanf(buf, "%d.%d.%d.%d", &n3, &n2, &n1, &n0) == 4)
							Node = n3 + (n2 + (n1 + n0 * 256) * 256) * 256;
						else
						{
							Node = 0;
							WriteError("Not a legal IP address");
						}
					}
					else
					{
						Node = RdosNameToIp(buf);
						if (Node == 0)
							WriteError("Cannot locate host");
					}

				}
				else
					Node = 127;
			}
		}

		if (Node)
			WriteNode(Col, Node);

		if (Node)
		{
			WriteHeader("Input mailslot name> ");
			MailslotName[0] = 0;
			scanf("%s", MailslotName);
			if (strlen(MailslotName))
				WriteMailslot(Col, MailslotName);
			else
				Node = 0;
		}

		if (Node == 127)
		{
			WriteHeader("Input number of local senders> ");
			if (scanf("%d", &LocalSenders) == 1)
			{
				if (LocalSenders < 0 || LocalSenders >= 10)
				{
					Node = 0;
					WriteError("Value out of range");
				}
			}
			else
				Node = 0;
		}
		else
			LocalSenders = 0;

		if (Node)
		{
			WriteHeader("Input number of senders> ");
			if (scanf("%d", &SmpSenders) == 1)
			{
				printf("\r\n");
				if (SmpSenders < 0 || SmpSenders >= 10)
				{
					Node = 0;
					WriteError("Value out of range");
				}
			}
			else
				Node = 0;
		}

	}

	if (Node)
	{

		if (Receivers)
		{
			sprintf(Name, "R%d", Index);
			CreateReceiver(MailslotName, Name, 4, Col);
		}

		for (i = 0; i < LocalSenders; i++)
		{
			sprintf(Name, "L%d.%d", Index, i);
			CreateSender(MailslotName, Name, 5 + i, Col);
		}

		for (i = 0; i < SmpSenders; i++)
		{
			sprintf(Name, "S%d.%d", Index, i);
			CreateSender(Node, MailslotName, Name, 5 + LocalSenders + i, Col);
		}
	}
}

void cdecl main()
{
	int i;

	for (i = 0; i < 4; i++)
		InputMailslot(i);

	for (;;)
		RdosWaitMilli(1000);
}

