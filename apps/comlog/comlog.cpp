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
# comlog.cpp
# Com port log utility
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

#define MAX_FILE_SIZE   0x400000 // 4 MB

/*################## GetFile ##########################
*   Purpose....: Get a new file                                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TFile *GetFile()
{
        int num;
        int handle;
        char FileName[40];

        for (num = 0; num < 10000; num++)
        {
                sprintf(FileName, "d:\\comlog\\raw%04d.dat", num);
                handle = RdosOpenHandle(FileName, O_RDWR);
                if (handle > 0)
                        RdosCloseHandle(handle);
                else
                        break;
        }
        return new TFile(FileName, 0);
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
        RdosWaitMilli(5000);

        TSerialDebug Debug;
        char Str[10];
        TWaitDevice *WaitDevice;
        TWait Wait;
        TKeyboardDevice Keyboard;

        TSerialDevice Port1(1, 9600, 'N', 8, 1);
        TSerialDevice Port2(2, 9600, 'N', 8, 1);

        Port1.Open();
        Port2.Open();

        Wait.Add(&Port1);
        Wait.Add(&Port2);
        Wait.Add(&Keyboard);

        TFile *File = GetFile();
//        TFile *File = new TFile("raw.dat", 0);

        for (;;)
        {
                WaitDevice = Wait.WaitForever();
                if (WaitDevice == &Port1)
                {
                        Debug.Time = RdosGetLongTime();
                        Debug.Channel = 1;
                        Debug.ch = Port1.Read();
                        File->Write(&Debug, sizeof(Debug));
                        RdosSetForeColor(9);
                }

                if (WaitDevice == &Port2)
                {
                        Debug.Time = RdosGetLongTime();
                        Debug.Channel = 2;
                        Debug.ch = Port2.Read();
                        File->Write(&Debug, sizeof(Debug));
                        RdosSetForeColor(11);
                }

                if (WaitDevice == &Keyboard)
                {
                        if (Keyboard.Poll())
                        {
                                if (Keyboard.Get() == 0x1b)
                                        return;
                        }
                }

                sprintf(Str, "%04hX", Debug.ch);
                Str[0] = Str[2];
                Str[1] = Str[3];
                Str[2] = ' ';
                Str[3] = ' ';
                Str[4] = 0;
                RdosWriteString(Str);

                if (File->GetSize() > MAX_FILE_SIZE)
                {
                        delete File;
                        File = GetFile();
                }
        }
}
