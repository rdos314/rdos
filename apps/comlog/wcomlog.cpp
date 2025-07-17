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
# wcomlog.cpp
# Windows based com log utility
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "serial.h"
#include "win32.h"

#include "str.h"
#include "file.h"


void Log(TSerialDebug *Debug)
{
        char Str[10];

        sprintf(Str, "%04hX", Debug->ch);
        Str[0] = Str[2];
        Str[1] = Str[3];
        Str[2] = ' ';
        Str[3] = ' ';
        Str[4] = 0;
        printf(Str);
}

/*##################  main ##########################
*   Purpose....: Program entry-point                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void cdecl main()
{
        HANDLE console = GetStdHandle(STD_OUTPUT_HANDLE);
        TSerialDebug Debug;
        TSerialDevice Port1(4, 9600, 'O', 8, 1);
//      TSerialDevice Port2(2, 9600, 'O', 8, 1);

        TFile *File = new TFile("c:\\cap\\raw.dat", 0);
        Port1.Open();
//        Port2.Open();

        for (;;)
        {
                if (Port1.Poll())
                {
                        Win32GetTics(GetTickCount(), &Debug.TimeMSB, &Debug.TimeLSB);
                        Debug.Channel = 1;
                        Debug.ch = Port1.Read();
                        File->Write(&Debug, sizeof(Debug));
                        SetConsoleTextAttribute(console, 9);
                        Log(&Debug);
                }

/*              if (Port2.Poll())
                {
                        Win32GetTics(GetTickCount(), &Debug.TimeMSB, &Debug.TimeLSB);
                        Debug.Channel = 2;
                        Debug.ch = Port2.Read();
                        File->Write(&Debug, sizeof(Debug));
                        SetConsoleTextAttribute(console, 11);
                        Log(&Debug);
                } */
        }
}

