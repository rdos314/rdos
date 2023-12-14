#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"

void main()
{
    int sess;
    int sock;
    int port;
    int ip;
    int n0,n1,n2,n3;
    char host[80];

    strcpy(host, "185.20.15.60");

    if (sscanf(host, "%d.%d.%d.%d", &n3, &n2, &n1, &n0) == 4)
        ip = n3 + (n2 + (n1 + n0 * 256) * 256) * 256;
    else
        ip = 0;

    port = 443;

    sess = RdosCreateSecureSession();

    sock = RdosCreateSecureConnection(sess, ip, 0, port, 5000, 0x1000);
    RdosPollSecureConnection(sock);
    RdosCloseSecureConnection(sock);

    RdosCloseSecureSession(sess);

//    RdosTestGate("");
}
