#include <fcntl.h>
#include<io.h>
#include<stdio.h>

#include "swap.h"

struct TIpHeader
{
	char HdrVer;
	char Tos;
	short int Size;
	short int Id;
	short int Frags;
	char Ttl;
	char Proto;
	short int CheckSum;
	long Source;
	long Dest;
};

struct TTcpHeader
{
	short int Source;
	short int Dest;
	long Seq;
	long Ack;
	char HeaderLen;
	char Flags;
	short int Window;
	short int CheckSum;
	short int Urgent;
};

#define REORDER_ENTRIES	8

struct TConnection
{
	long Section;
	short int Next;
	short int ListenLink;
	short int Owner;
	short int Port;
	long RemoteIp;
	short int RemotePort;
	short int ChecksumBase;
	long Timeout;
	short int BufferSize;
	short int ReceiveBuffer;
	short int ReceiveCount;
	short int ReceiveHead;
	short int ReceiveTail;
	short int SendBuffer;
	short int SendCount;
	short int SendHead;
	short int SendTail;
	short int Id;
	long Iss;
	char State;
	long SendUna;
	long SendNext;
	short int SendWnd;
	short int SendMaxWnd;
	long SendWl1;
	long SendWl2;
	short int RcvWnd;
	long RcvNext;
	short int ReorderCount;
	long ReorderArr[2 * REORDER_ENTRIES];
	short int Mtu;
	long Cwnd;
	long Ssthresh;
	short int DupAcks;
	short int Pending;
	long Rto;
	long Rts;
	long Rtm;
	long FinSeq;
	long TimeVal;
	long TimeSeq;
	char DeleteOk;
	char AckTimeout;
	char PushTimeout;
	short int UserTimeout;
	short int ResendTimeout;
	short int ZeroTimeout;
	char Options;
};

#define	FIN			1
#define SYN			2
#define RST			4
#define PSH			8
#define ACK			0x10
#define URG			0x20

#define STATE_SYN_SENT		0
#define STATE_SYN_RCVD		1
#define STATE_ESTAB			2
#define STATE_FIN_WAIT1		3
#define STATE_FIN_WAIT2		4
#define STATE_CLOSE_WAIT	5
#define STATE_LAST_ACK		6
#define STATE_CLOSING		7
#define STATE_TIME_WAIT		8

#define FLAG_REC_FIN		1
#define FLAG_CLOSING		2
#define FLAG_SEND_PUSH		4
#define FLAG_WAIT			8
#define FLAG_REC_PUSH		0x10
#define FLAG_ACK			0x20
#define FLAG_DELETE			0x40
#define FLAG_DELAY_ACK		0x80
#define FLAG_RESENT			0x100
#define FLAG_CLOSED			0x200

void DumpTcp(int Handle)
{
	TIpHeader IpHeader;
	TTcpHeader TcpHeader;
	char Message[1700];
	int size, count;

	read(Handle, &IpHeader, sizeof(IpHeader));
	IpHeader.Size = SwapWord(IpHeader.Size);
	IpHeader.Id = SwapWord(IpHeader.Id);
	IpHeader.Frags = SwapWord(IpHeader.Frags);
	count = (IpHeader.HdrVer & 0xF) << 2;
	if (count != sizeof(IpHeader))
		read(Handle, Message, count - sizeof(IpHeader));
	size = IpHeader.Size - count;
	read(Handle, &TcpHeader, sizeof(TTcpHeader));
	TcpHeader.Source = SwapWord(TcpHeader.Source);
	TcpHeader.Dest = SwapWord(TcpHeader.Dest);
	TcpHeader.Seq = SwapDword(TcpHeader.Seq);
	TcpHeader.Ack = SwapDword(TcpHeader.Ack);
	TcpHeader.Window = SwapWord(TcpHeader.Window);
	count = (TcpHeader.HeaderLen >> 2) & 0x3C;
	if (count != sizeof(TcpHeader))
		read(Handle, Message, count - sizeof(TcpHeader));
	size -= count;
	if (size)
	{
		read(Handle, Message, size);
		Message[size] = 0;
	}
	else
		Message[0] = 0;
	printf("From: %4hX To: %4hX\r\n", TcpHeader.Source, TcpHeader.Dest);
	printf("%08lX ", TcpHeader.Seq);
	if (TcpHeader.Flags & FIN)
		printf("FIN ");
	if (TcpHeader.Flags & SYN)
		printf("SYN ");
	if (TcpHeader.Flags & RST)
		printf("RST ");
	if (TcpHeader.Flags & PSH)
		printf("PSH ");
	if (TcpHeader.Flags & ACK)
		printf("ACK %08lX", TcpHeader.Ack);
	printf("\r\n");
	Message[20] = 0;
	printf("%s\r\n", Message);
}

void DumpConnection(int Handle)
{
	TConnection Connection;

	read(Handle, &Connection, sizeof(Connection));

	switch (Connection.State)
	{
		case STATE_SYN_SENT:
			printf("SYN-SENT ");
			break;

		case STATE_SYN_RCVD:
			printf("SYN-RCVD ");
			break;

		case STATE_ESTAB:
			printf("ESTAB ");
			break;

		case STATE_FIN_WAIT1:
			printf("FIN-WAIT1 ");
			break;

		case STATE_FIN_WAIT2:
			printf("FIN-WAIT2 ");
			break;

		case STATE_CLOSE_WAIT:
			printf("CLOSE-WAIT ");
			break;

		case STATE_LAST_ACK:
			printf("LAST-ACK ");
			break;

		case STATE_CLOSING:
			printf("CLOSING ");
			break;

		case STATE_TIME_WAIT:
			printf("TIME-WAIT ");
			break;
	}

	if (Connection.Pending & FLAG_REC_FIN)
		printf("REC-FIN ");

	if (Connection.Pending & FLAG_CLOSING)
		printf("CLOSING ");

	if (Connection.Pending & FLAG_SEND_PUSH)
		printf("SEND-PUSH ");

	if (Connection.Pending & FLAG_WAIT)
		printf("WAIT ");

	if (Connection.Pending & FLAG_REC_PUSH)
		printf("REC-PUSH ");

	if (Connection.Pending & FLAG_ACK)
		printf("ACK ");

	if (Connection.Pending & FLAG_DELETE)
		printf("DELETE ");

	if (Connection.Pending & FLAG_DELAY_ACK)
		printf("DELAY-ACK ");

	if (Connection.Pending & FLAG_RESENT)
		printf("RESENT ");

	if (Connection.Pending & FLAG_CLOSED)
		printf("CLOSED ");

	printf("\r\n");
	printf("SEND UNA: %08lX, NEXT: %08lX, COUNT: %4hX\r\n",
				Connection.SendUna, Connection.SendNext, Connection.SendCount);
	printf("SEND WND: %04hX, MAX WND: %04hX, WL1: %08lX, WL2: %08lX\r\n",
				Connection.SendWnd, Connection.SendMaxWnd,
				Connection.SendWl1, Connection.SendWl2);
	printf("RCV NEXT: %08lX, COUNT: %4hX, WND: %04hX\r\n",
				Connection.RcvNext, Connection.ReceiveCount, Connection.RcvWnd);
	printf("MTU: %hu, CWND: %lu, SSTHRESH: %lu, DUPACKS: %hu\r\n",
				Connection.Mtu, Connection.Cwnd, Connection.Ssthresh, Connection.DupAcks);
}

void cdecl main()
{
	int Handle;
	char ThreadName[33];
	long TimeLsb;
	int count;
	int size;
	long BaseTime = 0;
	char Op;

	Handle = open("z:\\tcp.log", O_BINARY);
	do
	{
		count = read(Handle, ThreadName, 32);
		if (count)
		{
			ThreadName[32] = 0;
			printf("---------------------------------------------\r\n");
			printf("Thread: %s\r\n", ThreadName);
			read(Handle, &TimeLsb, 4);
			if (!BaseTime)
				BaseTime = TimeLsb;
			printf("Time: %ld.%03ldms\r\n", (TimeLsb - BaseTime) / 1193, (TimeLsb - BaseTime) % 1193);
			read(Handle, &Op, 1);
			switch (Op)
			{
				case 0:
					DumpTcp(Handle);
					break;

				case 1:
					DumpConnection(Handle);
					break;
			}
		}
	}
	while (count);
	close(Handle);
}

