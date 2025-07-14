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
# hhcn818.cpp
# HHC-N818OP relay driver
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <arpa/inet.h>
#include <netdb.h>
#include "rdos.h"
#include "hhcn818.h"

/*##########################################################################
#
#   Name       : THhcRelay::THhcRelay
#
#   Purpose....: HHC-N818 constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THhcRelay::THhcRelay(char *HostStr)
  : FSection("HHC")
{
    int size = strlen(HostStr);
    char *ptr;
    int i;

    FOnline = false;

    for (i = 0; i < 8; i++)
    {
        FRelayArr[i] = false;
        FInputArr[i] = false;
    }

    FHostStr = new char[size + 1];
    strcpy(FHostStr, HostStr);

    ptr = strchr(FHostStr, ':');
    if (ptr)
    {
        *ptr = 0;
        ptr++;
        FPort = atoi(ptr);
    }
    else
        FPort = 5000;

    FIP = 0;

    Start("HHC-N818OP", 0x8000);
}

/*##########################################################################
#
#   Name       : THhcRelay::~THhcRelay
#
#   Purpose....: HHC-N818 destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THhcRelay::~THhcRelay()
{
}

/*##########################################################################
#
#   Name       : THhcRelay::IsOnline
#
#   Purpose....: Is online?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THhcRelay::IsOnline()
{
    return FOnline;
}

/*##########################################################################
#
#   Name       : THhcRelay::IsOn
#
#   Purpose....: Read relay status
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THhcRelay::IsOn(int relay)
{
    if (relay >= 0 && relay < 8)
        return FRelayArr[relay];
    else
        return false;
}

/*##########################################################################
#
#   Name       : THhcRelay::On
#
#   Purpose....: Turn on relay
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::On(int relay)
{
    char str[10];

    FSection.Enter();

    if (FOnline && relay >= 0 && relay < 8)
    {
        RdosWaitMilli(50);

        sprintf(str, "on%d", relay + 1);
        FSocket->Write(str);
        FSignal.WaitTimeout(1000);

        RdosWaitMilli(150);
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : THhcRelay::Off
#
#   Purpose....: Turn off relay
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::Off(int relay)
{
    char str[10];

    FSection.Enter();

    if (FOnline && relay >= 0 && relay < 8)
    {
        RdosWaitMilli(50);

        sprintf(str, "off%d", relay + 1);
        FSocket->Write(str);
        FSignal.WaitTimeout(1000);

        RdosWaitMilli(150);
    }

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : THhcRelay::ReadInput
#
#   Purpose....: Read input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool THhcRelay::ReadInput(int chan)
{
    if (chan >= 0 && chan < 8)
        return FInputArr[chan];
    else
        return false;
}

/*##########################################################################
#
#   Name       : THhcRelay::HandleName
#
#   Purpose....: Handle device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::HandleName(char *str)
{
    char *ptr;
    int size;

    if (str[4] == '=')
    {
        str[4] = 0;
        if (!strcmp(str, "name"))
        {
            ptr = str + 5;
            size = strlen(ptr);
            if (ptr[0] == '"' && ptr[size - 1] == '"')
            {
                ptr[size - 1] = 0;
                ptr++;
                FName = ptr;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : THhcRelay::HandleRelay
#
#   Purpose....: Handle relay state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::HandleRelay(char *str)
{
    char *ptr;
    int i;
    char ch;

    ch = str[5];
    str[5] = 0;

    if (!strcmp(str, "relay"))
    {
        ptr = str + 5;
        *ptr = ch;

        for (i = 7; i >= 0; i--)
        {
            switch (*ptr)
            {
                case '0':
                    FRelayArr[i] = false;
                    break;

                case '1':
                    FRelayArr[i] = true;
                    break;

                default:
                    return;
            }
            ptr++;
        }
    }
}

/*##########################################################################
#
#   Name       : THhcRelay::HandleInput
#
#   Purpose....: Handle input state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::HandleInput(char *str)
{
    char *ptr;
    int i;
    char ch;

    ch = str[5];
    str[5] = 0;

    if (!strcmp(str, "input"))
    {
        ptr = str + 5;
        *ptr = ch;

        for (i = 7; i >= 0; i--)
        {
            switch (*ptr)
            {
                case '0':
                    FInputArr[i] = false;
                    break;

                case '1':
                    FInputArr[i] = true;
                    break;

                default:
                    return;
            }
            ptr++;
        }
    }
}

/*##########################################################################
#
#   Name       : THhcRelay::HandleOn
#
#   Purpose....: Handle on
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::HandleOn(char *str)
{
    char *ptr;
    int chan;
    char ch;

    ch = str[2];
    str[2] = 0;

    if (!strcmp(str, "on"))
    {
        ptr = str + 2;
        *ptr = ch;
        chan = atoi(ptr);

        if (chan > 0 && chan <= 8)
        {
            FRelayArr[chan - 1] = true;
            FSignal.Signal();
        }
    }
}

/*##########################################################################
#
#   Name       : THhcRelay::HandleOff
#
#   Purpose....: Handle off
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::HandleOff(char *str)
{
    char *ptr;
    int chan;
    char ch;

    ch = str[3];
    str[3] = 0;

    if (!strcmp(str, "off"))
    {
        ptr = str + 3;
        *ptr = ch;
        chan = atoi(ptr);

        if (chan > 0 && chan <= 8)
        {
            FRelayArr[chan - 1] = false;
            FSignal.Signal();
        }
    }
}

/*##########################################################################
#
#   Name       : THhcRelay::HandleData
#
#   Purpose....: Handle device data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::HandleData()
{
    char str[80];
    int count;
    int size = FSocket->GetSize();

    if (size > 0 && size < 80)
    {
        count = FSocket->Read(str, size);
        if (size == count)
        {
            str[size] = 0;

            switch (str[0])
            {
                case 'n':
                    HandleName(str);
                    break;

                case 'r':
                    HandleRelay(str);
                    break;

                case 'i':
                    HandleInput(str);
                    break;

                case 'o':
                    if (str[1] == 'n')
                        HandleOn(str);

                    if (str[1] == 'f')
                        HandleOff(str);
                    break;
            }
        }
    }
    else
    {
        FSocket->Close();
        delete FSocket;
        FSocket = 0;
    }
}

/*##########################################################################
#
#   Name       : THhcRelay::Execute
#
#   Purpose....: Execute method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THhcRelay::Execute()
{
    struct hostent *host;

    FOnline = false;

    while (FIP == 0)
    {
        host = gethostbyname(FHostStr);
        if (host)
            FIP = *(long *)host->h_addr_list[0];
        else
            RdosWaitMilli(500);
    }

    for (;;)
    {
        FSocket = new TTcpSocket(FIP, FPort, 5000, 0x2000);
        FSocket->WaitForConnection(5000);

        if (FSocket->IsOpen())
        {
            FSocket->Write("name");
            FSocket->Push();
            if (FSocket->WaitForData(1000))
                HandleData();

            FOnline = true;
        }

        while (FSocket->IsOpen())
        {
            if (FSocket->WaitForData(2500))
                HandleData();
            else
            {
                FSection.Enter();

                FSocket->Write("read");
                FSocket->Push();
                if (FSocket->WaitForData(1000))
                    HandleData();

                FSocket->Write("input");
                FSocket->Push();
                if (FSocket->WaitForData(1000))
                    HandleData();

                FSection.Leave();
            }
        }

        FOnline = false;
        delete FSocket;
        FSocket = 0;
    }
}
