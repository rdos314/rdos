#include "rdos.h"
#include <string.h>
#include <stdio.h>

extern "C" void ConnectionThread(void *TcpHandle)
{
	int count;
	char Buf[513];
	int FileHandle;

	int Handle = (int)TcpHandle;

	if (RdosWaitForTcpConnection(Handle, 6000))
	{
		do
		{
			count = RdosReadTcpConnection(Handle, Buf, 512);
			Buf[count] = 0;
			printf(Buf);
		}
		while (count == 512);

		FileHandle = RdosOpenFile("z:\\index.htm", 0);
		if (FileHandle)
		{
			do
			{
				count = RdosReadFile(FileHandle, Buf, 512);
				RdosWriteTcpConnection(Handle, Buf, count);
			}
			while (count);
			RdosCloseFile(FileHandle);
		}
		RdosPushTcpConnection(Handle);
		RdosCloseTcpConnection(Handle);
		RdosDeleteTcpConnection(Handle);
	}
}

extern "C" void NewConnection(int Handle)
{
	RdosCreateThread(ConnectionThread, "HTTP", (void *)Handle, 0x2000);
}

extern "C" void TestThread(void *)
{
	_asm int 3
	printf("Test thread");
}

void cdecl main()
{
	_asm int 3
	RdosCreateThread(TestThread, "Test", (void *)0x12345678, 0x2000);
	RdosListenTcpPort(80, 0x4000, NewConnection);
}

