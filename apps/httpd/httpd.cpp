#include "socket.h"
#include "file.h"
#include <string.h>
#include <stdio.h>

#define FALSE 0
#define TRUE !FALSE

class THttpSocketServerFactory : public TSocketServerFactory
{
public:
    virtual char *GetThreadName();
    virtual int GetStackSize();    
	virtual TSocketServer *Create();
};

class THttpSocketServer : public TSocketServer
{
public:
	THttpSocketServer();
	virtual void DeviceName(char *Name, int MaxLen) const;
	virtual void HandleSocket();
};

char *THttpSocketServerFactory::GetThreadName()
{
	return "HTTP";
}

int THttpSocketServerFactory::GetStackSize()
{
	return 0x2000;
}

TSocketServer *THttpSocketServerFactory::Create()
{
	return new THttpSocketServer;
}

THttpSocketServer::THttpSocketServer()
{
}

void THttpSocketServer::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name,"HTTP",MaxLen);
}

void THttpSocketServer::HandleSocket()
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
}

THttpSocketServerFactory Factory;

void cdecl main()
{
    TSocket::Listen(&Factory, 80, 0x4000);
}

