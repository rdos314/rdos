/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2018, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# websock.cpp
# Web socket class
#
########################################################################*/

#include <string.h>
#include "rdos.h"
#include "base64.h"
#include "sha1.h"
#include "websock.h"

/*##########################################################################
#
#   Name       : TWebSocketServer::TWebSocketServer
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWebSocketServer::TWebSocketServer(const char *Name, int StackSize, TTcpSocket *Socket)
  : TSocketServer(Name, StackSize, Socket)
{
}

/*##########################################################################
#
#   Name       : TWebSocketServer::~TWebSocketServer
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWebSocketServer::~TWebSocketServer()
{
}

/*##########################################################################
#
#   Name       : TWebSocketServer::GetUrl
#
#   Purpose....: Get URL as a string value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TWebSocketServer::GetUrl(char *str)
{
    TString valstr;
    char *start;
    char ch;
    char *ptr = str;

    while (*ptr != ' ' && *ptr != 0x9)
        ptr++;

    while (*ptr == ' ' || *ptr == 0x9)
        ptr++;

    start = ptr;

    while (*ptr != ' ' && *ptr != 0xd && *ptr != 0xa)
        ptr++;

    ch = *ptr;
    *ptr = 0;
    valstr = start;
    *ptr = ch;

    return valstr;
}

/*##########################################################################
#
#   Name       : TWebSocketServer::GetValue
#
#   Purpose....: Get a string value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TWebSocketServer::GetValue(char *str)
{
    TString valstr;
    char *start;
    char ch;
    char *ptr = str;

    if (ptr)
        ptr = strchr(ptr, ':');

    if (ptr)
    {
        ptr++;

        while (*ptr == ' ' || *ptr == 0x9)
            ptr++;

        start = ptr;

        while (*ptr != ' ' && *ptr != 0xd && *ptr != 0xa)
            ptr++;

        ch = *ptr;
        *ptr = 0;
        valstr = start;
        *ptr = ch;
    }

    return valstr;
}

/*##########################################################################
#
#   Name       : TWebSocketServer::CalcAccept
#
#   Purpose....: Calc accept string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::CalcAccept(const char *str)
{
    TSha1Hash sha1;
    char data[20];

    strcpy(FHashStr, str);
    strcat(FHashStr, "258EAFA5-E914-47DA-95CA-C5AB0DC85B11");

    sha1.Add(FHashStr, strlen(FHashStr));
    sha1.GetHashData(data);

    CodeBase64(data, FAcceptStr, 20);
}

/*##########################################################################
#
#   Name       : TWebSocketServer::SendAccept
#
#   Purpose....: Send accept
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::SendAccept(const char *prot)
{
    strcpy(FBuf, "HTTP/1.1 101 Switching Protocols\r\n");
    strcat(FBuf, "Upgrade: websocket\r\n");
    strcat(FBuf, "Connection: Upgrade\r\n");
    strcat(FBuf, "Sec-Websocket-Accept: ");
    strcat(FBuf, FAcceptStr);
    strcat(FBuf, "\r\n");
    strcat(FBuf, "Sec-Websocket-Protocol: ");
    strcat(FBuf, prot);
    strcat(FBuf, "\r\n");
    strcat(FBuf, "\r\n");

    FSocket->Write(FBuf, strlen(FBuf));
    FSocket->Push();
}

/*##########################################################################
#
#   Name       : TWebSocketServer::SendReject
#
#   Purpose....: Send reject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::SendReject()
{
    strcpy(FBuf, "HTTP/1.1 101 Switching Protocols\r\n");
    strcat(FBuf, "Upgrade: websocket\r\n");
    strcat(FBuf, "Connection: Upgrade\r\n");
    strcat(FBuf, "Sec-Websocket-Accept: ");
    strcat(FBuf, FAcceptStr);
    strcat(FBuf, "\r\n");
    strcat(FBuf, "\r\n");

    FSocket->Write(FBuf, strlen(FBuf));
    FSocket->Push();
}

/*##########################################################################
#
#   Name       : TWebSocketServer::SendHttpError
#
#   Purpose....: Send HTTP error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::SendHttpError()
{
    strcpy(FBuf, "HTTP/1.1 404 NOT FOUND\r\n");
    strcat(FBuf, "\r\n");

    FSocket->Write(FBuf, strlen(FBuf));
    FSocket->Push();
}

/*##########################################################################
#
#   Name       : TWebSocketServer::Unmask
#
#   Purpose....: Unmask message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::Unmask(char *buf, int size, char *mask)
{
    int i;
    int m = 0;

    for (i = 0; i < size; i++)
    {
        buf[i] = buf[i] ^ mask[m];
        m++;
        if (m == 4)
            m = 0;
    }
}
   
/*##########################################################################
#
#   Name       : TWebSocketServer::HandleWebSocket
#
#   Purpose....: Handle web socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::HandleWebSocket()
{
    int size;
    int len;
    char op;
    bool masked;
    char mask[4];
    bool ok;

    while (FSocket->IsOpen())
    {
        if (FSocket->WaitForData(5000))
        {
            size = FSocket->Read(FBuf, 2);

            if (size == 2)
            {
                ok = true;

                op = FBuf[0] & 0xF;

                if (FBuf[1] & 0x80)
                    masked = true;
                else
                    masked = false;

                len = FBuf[1] & 0x7F;

                if (len == 126)
                {
                    size = FSocket->Read(FBuf, 2);
                    if (size == 2)
                        len = RdosSwapShort(*(short int*)FBuf);
                    else
                        ok = false;
                }
                else
                {
                    if (len == 127)
                    {
                        size = FSocket->Read(FBuf, 4);
                        if (size == 4)
                            len = RdosSwapLong(*(int *)FBuf);
                        else
                            ok = false;
                    }
                }
            }
            else
                ok = false;

            if (ok)
            {
                if (masked)
                    FSocket->Read(mask, 4);

                size = FSocket->Read(FBuf, len);
                if (len == size)
                {
                    if (masked)
                        Unmask(FBuf, size, mask);

                    switch (op)
                    {
                        case 1:
                            FBuf[size] = 0;
                            ReceivedText(FBuf);
                            break;

                        case 2:
                            ReceivedBinary(FBuf, size);
                            break;
                    }
                }
            }
        }
    }
}
                  
/*##########################################################################
#
#   Name       : TWebSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::HandleSocket()
{
    int size;
    char *ptr;
    const char *prot;
    TString key;
    TString str;
    bool ok = false;

    while (FSocket->IsOpen())
    {
        if (FSocket->WaitForData(5000))
        {
            size = FSocket->Read(FBuf, 512);
            FBuf[size] = 0;

            ptr = FBuf;
            FReqUrl = GetUrl(ptr);

            ptr = strstr(FBuf, "Sec-WebSocket-Key");

            if (ptr)
                key = GetValue(ptr);

            if (key.GetSize())
                ok = true;
            else
                ok = false;

            if (ok)
            {
                ptr = strstr(FBuf, "Sec-WebSocket-Protocol");
  
                if (ptr)
                    FProtocol = GetValue(ptr);
                else
                    ok = false;
            }

            if (ok)
            {
                ptr = strstr(FBuf, "Sec-WebSocket-Version");

                if (ptr)
                {
                    str = GetValue(ptr);
                    FVersion = atoi(str.GetData());
                }
                else
                    ok = false;
            }

            if (ok)
            {
                CalcAccept(key.GetData());

                prot = GetProtocol();
                if (prot)
                {
                    SendAccept(prot);
                    HandleWebSocket();
                }
                else
                    SendReject();
            }
            else
                SendHttpError();
                
            FSocket->Close();
            break;
        }
        else
            RdosWaitMilli(250);
    }
}
