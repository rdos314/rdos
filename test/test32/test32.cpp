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
    TSerialDevice serial(count - 6, 9600, 'N', 8, 1);

    for (;;)
    {
        if (RdosPollKeyboard())
        {
            ch = (char)RdosReadKeyboard();
            serial.Write(ch);
            RdosWriteChar(ch);        
        }
        if (serial.WaitForChar(10))
        {
            ch = serial.Read();
            RdosWriteChar(ch);        
        }                       
    }
}

