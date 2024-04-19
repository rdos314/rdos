#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "cotex.h"
#include "sockobj.h"


void main()
{
    int size;
    char *msg;
    TCotex doc(0x1000);
    TSslSocket sock(0x81A977D9, 2091, 5000, 0x2000);

    if (sock.WaitForConnection(5000))
    {
        msg = new char[0x1000];
        size = sock.GetCertificate(msg, 0x1000);
        msg[size] = 0;
        printf(msg);
        delete msg;

        size = doc.GetSize();
        msg = new char[size + 1];
        doc.GetData(msg);

        sock.Write(msg, size);
    }

    RdosTestGate("");
}



