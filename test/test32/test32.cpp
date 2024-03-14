#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "sockobj.h"
#include "cotex.h"

void main()
{
    int size;
    char *msg;
    TCotex doc(0x1000);
    TSslSocket sock(0x81A977D9, 2091, 5000, 0x2000);

    if (sock.WaitForConnection(5000))
    {
        size = doc.GetSize();
        msg = new char[size + 1];
        doc.GetData(msg);

        sock.Write(msg, size);
    }
  
//    RdosTestGate("");
}



