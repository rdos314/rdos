#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "sockobj.h"
#include "keyboard.h"

void main()
{
    int port;
    int ip;
    int n0,n1,n2,n3;
    char host[80];
    int count;
    int i;
    char *rbuf = new char[1025];
    char buf[80];
    TWait wait;
    TSslSocket *sock;
    TKeyboardDevice keyboard;

    strcpy(host, "185.20.15.60");
//    strcpy(host, "10.8.8.244");

    if (sscanf(host, "%d.%d.%d.%d", &n3, &n2, &n1, &n0) == 4)
        ip = n3 + (n2 + (n1 + n0 * 256) * 256) * 256;
    else
        ip = 0;

    port = 443;

    sock = new TSslSocket(ip, port, 5000, 0x1000);
    sock->WaitForConnection(7000);

    wait.Add(sock);
    wait.Add(&keyboard);

    if (sock->IsOpen())
    {
        printf("connected\r\n");

        if (sock->GetCertificate(rbuf, 0x1000))
        {
            printf("Certificate: \r\n");
            printf(rbuf);
            printf("\r\n");
        }

        for (i = 0; i < 100; i++)
        {
            if (sock->GetCertificateChain(i, rbuf, 0x1000))
            {
                printf("Chain: %d: \r\n", i + 1);
                printf(rbuf);
                printf("\r\n");
            }
            else
                break;
        }

        ip = sock->GetRemoteIP();
        IpToString(buf, ip);
        printf("IP: %s\r\n", buf);
        port = sock->GetRemotePort();
        printf("Remote port: %d\r\n", port);
        port = sock->GetLocalPort();
        printf("Local port: %d\r\n", port);
    }

    while (sock->IsOpen())
    {
        wait.WaitForever();

        if (keyboard.Poll())
        {
            printf(" cmd> ");
            gets(buf);
            strcat(buf, "\r\n");
            sock->Write(buf);
            sock->Push();
        }

        count = sock->GetSize();
        if (count)
        {
            count = sock->Read(rbuf, count);
            rbuf[count] = 0;
            printf(rbuf);
        }
    }

    printf("closed\r\n");

    delete sock;
}



