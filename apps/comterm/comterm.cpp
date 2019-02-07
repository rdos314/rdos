#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "serial.h"
#include "rdos.h"
#include "keyboard.h"

#include "str.h"
#include "path.h"

/*##################  main ##########################
*   Purpose....: Program entry-point                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
    int port;
    int baud;
    char ch;
    TKeyboardDevice Keyboard;
    TSerialDevice *Serial;
    int ok;
    int ExtKey;
    int State;
    int VirtKey;
    int ScanCode;
    char str[10];

    switch (argc)
    {
        case 2:
            port = atoi(argv[1]);
            baud = 9600;
            break;

        case 3:
            port = atoi(argv[1]);
            baud = atoi(argv[2]);
            break;

        default:
            port = 0;
            baud = 0;
            break;
    }

    if (port && baud)
    {
        printf("\r\n");
        
        Serial = new TSerialDevice(port, baud, 'O', 7, 1);

        for (;;)
        {
            while (Serial->WaitForChar(100))
            {
                ch = Serial->Read();
                str[0] = ch;
                str[1] = 0;
                RdosWriteString(str);
            }

            if (Keyboard.Poll())
            {
                ok = Keyboard.ReadEvent(&ExtKey, &State, &VirtKey, &ScanCode);
                if (ok)
                    ok = Keyboard.IsStdKey(ExtKey, VirtKey);

                if (ok)
                {
                    ch = (char)ExtKey;

                    if (ch == 0x1b)
                        return 0;
                    else
                        Serial->Write(ch);
                }
            }
        }
    }
    else
        printf("usage: comterm port [baud]\r\n");

    return 0;
}
