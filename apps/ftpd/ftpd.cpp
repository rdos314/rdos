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
# ftpd.cpp
# FTP server application for RDOS
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "rdos.h"
#include "sockobj.h"
#include "ftpfact.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  WriteCommand ##########################
*   Purpose....: Write command echo                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteCommand(TFtpSocketServer *server, const char *str)
{
    printf(str);
}

/*##################  GetIwsIp ##########################
*   Purpose....: Get IWS local IP                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
long GetIwsIp()
{
    TTcpSocket IwsSocket(RdosGetGateway(), 5000, 2500, 0x4000);
    char Buf[64];
    int count;
    char ch;
    int startok;
    long ipdig[4];

    IwsSocket.WaitForConnection(2500);

    if (IwsSocket.IsOpen())
    {
        IwsSocket.Write("AT%GETIP\r\n");
        IwsSocket.Push();

        startok = FALSE;

        while (IwsSocket.WaitForData(2500) && !startok)
        {
            ch = IwsSocket.Read();
            if (ch == '=')
                startok = TRUE;
        }

        count = 0;

        while (IwsSocket.WaitForData(100))
        {
            Buf[count] = IwsSocket.Read();
            count++;
        }

        Buf[count] = 0;

        count = sscanf(Buf, "%d.%d.%d.%d", &ipdig[0], &ipdig[1], &ipdig[2], &ipdig[3]);
        if (count == 4)
            return (ipdig[3] << 24) | (ipdig[2] << 16) | (ipdig[1] << 8) | ipdig[0];

    }
    return 0;
}

/*##################  main ##########################
*   Purpose....: Program entry-point                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int cdecl main()
{
//    long IwsIp = GetIwsIp();

    TFtpSocketServerFactory Factory(21, 50, 0x4000);

//    if (IwsIp)
//        Factory.SetMyIp(IwsIp);

    Factory.AddUser("b-drive", "rdos", "b:\\");
    Factory.AddUser("c-drive", "rdos", "c:\\");
    Factory.AddUser("d-drive", "rdos", "d:\\");
    Factory.AddUser("e-drive", "rdos", "e:\\");
    Factory.AddUser("f-drive", "rdos", "f:\\");
    Factory.AddUser("g-drive", "rdos", "g:\\");
    Factory.AddUser("h-drive", "rdos", "h\\");
    Factory.AddUser("i-drive", "rdos", "i:\\");
    Factory.AddUser("j-drive", "rdos", "j:\\");
    Factory.AddUser("k-drive", "rdos", "k:\\");
    Factory.AddUser("l-drive", "rdos", "l:\\");
    Factory.AddUser("m-drive", "rdos", "m:\\");
    Factory.AddUser("n-drive", "rdos", "n:\\");
    Factory.AddUser("x-drive", "rdos", "x:\\");
    Factory.AddUser("y-drive", "rdos", "y:\\");
    Factory.AddUser("z-drive", "rdos", "z:\\");
    Factory.OnCommand = WriteCommand;
    Factory.SetDataPort(2100);

    for (;;)
        Factory.WaitForever();
}

