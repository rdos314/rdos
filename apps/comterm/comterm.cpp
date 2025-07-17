/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# comterm.cpp
# Serial port terminal tool 
#
########################################################################*/

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

        Serial = new TSerialDevice(port, baud, 'N', 8, 1);

        for (;;)
        {
            while (Serial->WaitForChar(100))
            {
                ch = Serial->Read();

                sprintf(str, "%04hX", ch);
                str[0] = str[2];
                str[1] = str[3];
                str[2] = ' ';
                str[3] = ' ';
                str[4] = 0;

//                str[0] = ch;
//                str[1] = 0;
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
                    {
                        delete Serial;
                        return 0;
                    }
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
