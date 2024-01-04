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
    int keys = 0;
    char *kbuf = new char[256];
    int count;
    char *rbuf = new char[1025];
    char str[10];
    TWait wait;
    TSslSocket *sock;
    TKeyboardDevice Keyboard;

    strcpy(host, "185.20.15.60");
//    strcpy(host, "10.8.8.240");

    if (sscanf(host, "%d.%d.%d.%d", &n3, &n2, &n1, &n0) == 4)
        ip = n3 + (n2 + (n1 + n0 * 256) * 256) * 256;
    else
        ip = 0;

    port = 443;
//    port = 6666;

    sock = new TSslSocket(ip, port, 5000, 0x1000, "SSL 6666");
    sock->WaitForConnection(7000);

    wait.Add(sock);
    wait.Add(&Keyboard);

    if (sock->IsOpen())
        printf("connected\r\n");

    while (sock->IsOpen())
    {
        wait.WaitForever();

        count = sock->GetSize();
        if (count)
        {
            count = sock->Read(rbuf, count);
            rbuf[count] = 0;
            printf(rbuf);
        }

        if (Keyboard.Poll())
        {
            char ch = (char)Keyboard.Get();
            str[0] = ch;
            str[1] = 0;
            printf(str);

            if (ch == 0xd)
            {
                printf("\r\n");

                kbuf[keys] = 0xd;
                kbuf[keys+1] = 0xa;
                sock->Write(kbuf, keys+2);

                keys = 0;
            }
            else
            {
                kbuf[keys] = ch;
                keys++;
            }
        }
    }

    printf("closed\r\n");

    delete sock;


//    RdosTestGate("");
}



