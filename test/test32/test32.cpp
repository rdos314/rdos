#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

#include "rdos.h"
#include "sockobj.h"

static char ipstr[] = "192.168.10.133";

void HandleSocket(TTcpSocket *Socket)
{
    bool ok;
    char ch;

    while (Socket->IsOpen())
    {
        ok = Socket->WaitForData(100);
        if (ok)
        {
            ch = Socket->Read();
            RdosWriteChar(ch);
        }
    }
}

void main()
{
    int n1, n2, n3, n4;
    int count;
    long Ip;
    TTcpSocket *Socket;   

    count = sscanf(ipstr, "%d.%d.%d.%d", &n1, &n2, &n3, &n4);

    if (count == 4)
    {
        Ip = n4;
        Ip = (Ip << 8) | n3;
        Ip = (Ip << 8) | n2;
        Ip = (Ip << 8) | n1;

        Socket = new TTcpSocket(Ip, 10097, 6000, 0x4000);

        if (Socket->WaitForConnection(10000))
            HandleSocket(Socket);
    }

    delete Socket;


//    char *buf = new char[1024];

//    RdosTestGate(buf);
}



