#include "rdos.h"
#include <string.h>
#include <stdio.h>

void ConnectionThread(void *TcpHandle)
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

void __stdcall NewConnection(int Handle)
{
	RdosCreateThread(ConnectionThread, "HTTP", (void *)Handle, 0x2000);
}

void cdecl main()
{
	RdosListenTcpPort(80, 0x4000, NewConnection);
}

