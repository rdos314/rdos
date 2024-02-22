#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "httpsfact.h"
#include "hhcn818.h"
#include "keyboard.h"
#include "serial.h"

void main()
{
    TSerialDevice serial(7, 9600, 'N', 8, 1);

    for (;;)
    {
        serial.Write("Hej");
        while (serial.WaitForChar(100))
            serial.Read();
    }
  
//    RdosTestGate("");
}



