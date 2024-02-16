#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "httpsfact.h"
#include "hhcn818.h"
#include "keyboard.h"

void main()
{
    THhcRelay relay("192.168.1.118:5000");

    relay.On(0);
    relay.On(1);
    relay.On(2);
    relay.On(3);
    relay.On(4);
    relay.On(5);
    relay.On(6);
    relay.On(7);

    relay.Off(0);
    relay.Off(1);
    relay.Off(2);
    relay.Off(3);
    relay.Off(4);
    relay.Off(5);
    relay.Off(6);
    relay.Off(7);

//    RdosTestGate("");
}



