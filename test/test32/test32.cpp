#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"

static void SocketHandler(void *Param)
{
    int *handle = (int *)Param;
    RdosHandleSecureConnection(*handle);
}

void main()
{
    int sess;
    int sock;
    int port;
    int ip;
    int n0,n1,n2,n3;
    char host[80];
    int wait = RdosCreateWait();
    int keys = 0;
    char *kbuf = new char[256];
    int count;
    char *rbuf = new char[1025];

//    strcpy(host, "185.20.15.60");
    strcpy(host, "10.8.8.240");

    if (sscanf(host, "%d.%d.%d.%d", &n3, &n2, &n1, &n0) == 4)
        ip = n3 + (n2 + (n1 + n0 * 256) * 256) * 256;
    else
        ip = 0;

//    port = 443;
    port = 6666;

    sess = RdosCreateSecureSession();

    sock = RdosCreateSecureConnection(sess, ip, 0, port, 5000, 0x1000);

    RdosCreateThread(SocketHandler, "SSL 6666", &sock, 0x1000);

    RdosWaitForSecureConnection(sock, 7000);

    RdosAddWaitForSecureConnection(wait, sock, 2);
    RdosAddWaitForKeyboard(wait, 1);

    while (!RdosIsSecureConnectionClosed(sock))
    {
        RdosWaitForever(wait);

        count = RdosPollSecureConnection(sock);
        if (count)
        {
            count = RdosReadSecureConnection(sock, rbuf, 1024);
            rbuf[count] = 0;
            RdosWriteString(rbuf);
        }

        if (RdosPollKeyboard())
        {
            char ch = (char)RdosReadKeyboard();
            RdosWriteChar(ch);

            if (ch == 0xd)
            {
                kbuf[keys] = 0xd;
                kbuf[keys+1] = 0xa;
                RdosWriteSecureConnection(sock, kbuf, keys+2);

                keys = 0;
            }
            else
            {
                kbuf[keys] = ch;
                keys++;
            }
        }
    }

    RdosCloseSecureConnection(sock);

    RdosCloseSecureSession(sess);

//    RdosTestGate("");
}



