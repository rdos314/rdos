#include "socket.h"
#include "file.h"
#include <string.h>
#include <stdio.h>

#define FALSE 0
#define TRUE !FALSE

class THttpSocketServerFactory : public TSocketServerFactory
{
public:
	virtual TSocketServer *Create(int Handle);
};

class THttpSocketServer : public TSocketServer
{
public:
	THttpSocketServer(const char *ThreadName, int Handle);
	virtual void DeviceName(char *Name, int MaxLen) const;
	virtual void Execute();
};

TSocketServer *THttpSocketServerFactory::Create(int Handle)
{
	return new THttpSocketServer("HTTP", Handle);
}

THttpSocketServer::THttpSocketServer(const char *ThreadName, int Handle)
  : TSocketServer(ThreadName, Handle)
{
}

void THttpSocketServer::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name,"HTTP",MaxLen);
}

void THttpSocketServer::Execute()
{
	int count;
	char Buf[513];

	if (FSocket->WaitForConnection(6000))
	{
		do
		{
			count = FSocket->Read(Buf, 512);
			Buf[count] = 0;
			printf(Buf);
		}
		while (count == 512);

		TFile file("z:\\index.htm");

		if (file.IsOpen())
		{
			do
			{
				count = file.Read(Buf, 512);
				FSocket->Write(Buf, count);
			}
			while (count);
		}
		FSocket->Push();
	}
	FSocket->Close();

	FInstalled = FALSE;

	delete this;
}

void cdecl main()
{
	THttpSocketServerFactory Factory;
    TSocket::Listen(&Factory, 80, 0x4000);
}

