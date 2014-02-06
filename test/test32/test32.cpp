#include <rdos.h>
#include <stdio.h>
#include <stdlib.h>
#include "serial.h"

#include <math.h>

void main()
{
    int i;
    char ch;
    int count = RdosGetMaxComPort();
    TSerialDevice serial1(count - 3, 9600, 'O', 8, 1);
    TSerialDevice serial2(count - 2, 9600, 'N', 8, 1);
    TSerialDevice serial3(count - 1, 9600, 'N', 8, 1);
    TSerialDevice serial4(count - 0, 9600, 'N', 8, 1);

    int FirstPort;
    int PortCount;
    int ModuleId;

    for (i = 1; i <= 100; i++)
    {
        if (RdosGetCanModuleInfo(i, &FirstPort, &PortCount, &ModuleId))
            printf("Module: %d, Port: %d-%d, ID: %d", i, FirstPort, FirstPort + PortCount - 1, ModuleId);
        else
            break;            
    }

    for (;;)
    {
        serial1.Write('a');
        serial2.Write('b');
        serial3.Write('c');
        serial4.Write('d');
        RdosWaitMilli(2);
    }       

    for (;;)
    {
        if (RdosPollKeyboard())
        {
            ch = (char)RdosReadKeyboard();
            if (ch == 0x1b)
                return;

            serial1.Write(ch);
            RdosWriteChar(ch);        
        }
        if (serial1.WaitForChar(10))
        {
            ch = serial1.Read();
            RdosWriteChar(ch);        
        }                       
    }
}

