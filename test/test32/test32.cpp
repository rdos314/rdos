#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <math.h>
#include "json.h"

#include "rdos.h"
#include "datetime.h"
#include "sockobj.h"

void main()
{
    TUdpSocketListner listner("mDNS", 5353, 100);
    char *msg;
    int size;
    int ip;
    char str[40];

    while (listner.WaitForMsg())
    {
        ip = listner.GetIP();
        IpToString(str, ip);
        printf("IP: %s\r\n", str);

        size = listner.GetMsgSize();
        msg = new char[size + 1];
        msg[size] = 0;
        listner.GetMsg(msg, size);
        delete msg;

        listner.ClearMsg();
    }

    RdosTestGate("");
}



