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
# keysend.cpp
# Key send tool
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

TSerialDevice *Serial = 0;

/*##################  KeyPress ##########################
*   Purpose....: Key press                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void KeyPress(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    char str[120];

    sprintf(str, "P%04hX%04hX%02hX%02hX\r\n", ExtKey, KeyState, VirtualKey, ScanCode);
    printf(str);

    if (Serial)
        Serial->Write(str);
}

/*##################  KeyRelease ##########################
*   Purpose....: Key release                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void KeyRelease(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
    char str[120];

    sprintf(str, "R%04hX%04hX%02hX%02hX\r\n", ExtKey, KeyState, VirtualKey, ScanCode);
    printf(str);

    if (Serial)
        Serial->Write(str);
}

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
    char ch;
    TKeyboardDevice Keyboard;
    int ok;
    int ExtKey;
    int State;
    int VirtKey;
    int ScanCode;
    TWait Wait;

    if (argc == 2)
        port = atoi(argv[1]);
    else
        port = 0;

    if (port)
    {
        Serial = new TSerialDevice(port, 9600, 'N', 8, 1);

        Keyboard.OnKeyPress = KeyPress;
        Keyboard.OnKeyRelease = KeyRelease;

        Wait.Add(&Keyboard);

        for (;;)
            Wait.WaitForever();
    }
    else
        printf("usage: keysend port\r\n");

    return 0;
}
