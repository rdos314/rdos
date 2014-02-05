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
    TSerialDevice serial1(count - 3, 9600, 'N', 8, 1);
    TSerialDevice serial2(count - 2, 9600, 'N', 8, 1);
    TSerialDevice serial3(count - 1, 9600, 'N', 8, 1);
    TSerialDevice serial4(count - 0, 9600, 'N', 8, 1);

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

