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
# websock.cpp
# Web socket class
#
########################################################################*/

#include <string.h>
#include "rdos.h"
#include "base64.h"
#include "sha1.h"
#include "websock.h"
#include "httpcmd.h"

static const char sign[] = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

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
  : THttpSocketServer(Name, StackSize, Socket),
    FSection("WebSocket")
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
    char *buf;
    int size;

    size = strlen(str) + strlen(sign) + 1;
    buf = new char[size];

    strcpy(buf, str);
    strcat(buf, sign);

    sha1.Add(buf, strlen(buf));
    sha1.GetHashData(data);
    CodeBase64(data, FAcceptStr, 20);

    delete buf;
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
void TWebSocketServer::SendAccept(THttpCommand *Cmd, const char *prot)
{
    Cmd->WriteStartHeader(101);
    Cmd->WriteOption("Upgrade", "websocket");
    Cmd->WriteOption("Connection", "Upgrade");
    Cmd->WriteOption("Sec-Websocket-Accept", FAcceptStr);
    Cmd->WriteOption("Sec-Websocket-Protocol", prot);
    Cmd->WriteEndHeader();
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
void TWebSocketServer::SendReject(THttpCommand *Cmd)
{
    Cmd->WriteStartHeader(101);
    Cmd->WriteOption("Upgrade", "websocket");
    Cmd->WriteOption("Connection", "Upgrade");
    Cmd->WriteOption("Sec-Websocket-Accept", FAcceptStr);
    Cmd->WriteEndHeader();
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
#   Name       : TWebSocketServer::StartWebSocket
#
#   Purpose....: Start web socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::StartWebSocket()
{
}
   
/*##########################################################################
#
#   Name       : TWebSocketServer::EndWebSocket
#
#   Purpose....: End web socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::EndWebSocket()
{
}
   
/*##########################################################################
#
#   Name       : TWebSocketServer::PollWebSocket
#
#   Purpose....: Poll web socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::PollWebSocket()
{
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
    int start;
    int size;
    int len;
    char op;
    bool masked;
    char mask[4];
    char str[10];
    bool ok;
    char *buf;

    StartWebSocket();

    while (FSocket->IsOpen())
    {
        if (FSocket->WaitForData(500))
        {
            size = FSocket->Read(str, 2);

            if (size == 2)
            {
                ok = true;

                op = str[0] & 0xF;

                if (str[1] & 0x80)
                    masked = true;
                else
                    masked = false;

                len = str[1] & 0x7F;

                if (len == 126)
                {
                    size = FSocket->Read(str, 2);
                    if (size == 2)
                        len = RdosSwapShort(*(short int*)str);
                    else
                        ok = false;
                }
                else
                {
                    if (len == 127)
                    {
                        size = FSocket->Read(str, 4);
                        if (size == 4)
                            len = RdosSwapLong(*(int *)str);
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

                buf = new char[len + 1];
                size = FSocket->Read(buf, len);

                if (size < len)
                {
                    start = size;

                    while (FSocket->WaitForData(500) && start < len)
                    {
                        size = FSocket->Read(buf + start, len - start);
                        start += size;
                    }
                    size = start;
                }

                if (len == size)
                {
                    if (masked)
                        Unmask(buf, size, mask);

                    switch (op)
                    {
                        case 1:
                            buf[size] = 0;
                            ReceivedText(buf);
                            break;

                        case 2:
                            ReceivedBinary(buf, size);
                            break;

                        case 0x9:
                            buf[size] = 0;
                            ReceivedPing(buf);
                            break;

                        case 0xA:
                            buf[size] = 0;
                            ReceivedPong(buf);
                            break;

                        default:
                            break;
                    }
                }
                delete buf;
            }
        }

        PollWebSocket();
    }

    FSection.Enter();
    EndWebSocket();
    FSection.Leave();
}
   
/*##########################################################################
#
#   Name       : TWebSocketServer::SendText
#
#   Purpose....: Send text 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::SendText(const char *str)
{
    int size = strlen(str);
    int hsize;
    short int ssize;
    int lsize;
    char header[16];

    header[0] = 0x81;

    if (size >= 65536)
    {
        header[1] = 127;
        header[2] = 0xFF;
        header[3] = 0xFF;

        lsize = RdosSwapLong(size);
        memcpy(header + 4, &lsize, 4);
        hsize = 6;
    }
    else
    {
        if (size >= 126)
        {
            header[1] = 126;

            ssize = RdosSwapShort((short int)size);
            memcpy(header + 2, &ssize, 2);
            hsize = 4;
        }
        else
        {
            header[1] = (char)size;
            hsize = 2;
        }
    }

    FSection.Enter();
    
    if (FSocket && FSocket->IsOpen())
    {
        FSocket->Write(header, hsize);
        FSocket->Write(str, size);
        FSocket->Push();
    }

    FSection.Leave();
}
   
/*##########################################################################
#
#   Name       : TWebSocketServer::SendBinary
#
#   Purpose....: Send binary
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::SendBinary(const char *str, int size)
{
    int hsize;
    short int ssize;
    int lsize;
    char header[16];

    header[0] = 0x82;

    if (size >= 65536)
    {
        header[1] = 127;
        header[2] = 0xFF;
        header[3] = 0xFF;

        lsize = RdosSwapLong(size);
        memcpy(header + 4, &ssize, 4);
        hsize = 6;
    }
    else
    {
        if (size >= 126)
        {
            header[1] = 126;

            ssize = RdosSwapShort((short int)size);
            memcpy(header + 2, &ssize, 2);
            hsize = 4;
        }
        else
        {
            header[1] = (char)size;
            hsize = 2;
        }
    }

    FSection.Enter();
    
    if (FSocket && FSocket->IsOpen())
    {
        FSocket->Write(header, hsize);
        FSocket->Write(str, size);
        FSocket->Push();
    }

    FSection.Leave();
}
   
/*##########################################################################
#
#   Name       : TWebSocketServer::SendControl
#
#   Purpose....: Send control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::SendControl(char op, const char *str)
{
    int size = strlen(str);
    int hsize;
    short int ssize;
    int lsize;
    char header[16];

    header[0] = op;

    if (size >= 65536)
    {
        header[1] = 127;
        header[2] = 0xFF;
        header[3] = 0xFF;

        lsize = RdosSwapLong(size);
        memcpy(header + 4, &lsize, 4);
        hsize = 6;
    }
    else
    {
        if (size >= 126)
        {
            header[1] = 126;

            ssize = RdosSwapShort((short int)size);
            memcpy(header + 2, &ssize, 2);
            hsize = 4;
        }
        else
        {
            header[1] = (char)size;
            hsize = 2;
        }
    }

    FSection.Enter();
    
    if (FSocket && FSocket->IsOpen())
    {
        FSocket->Write(header, hsize);
        FSocket->Write(str, size);
        FSocket->Push();
    }

    FSection.Leave();
}
   
/*##########################################################################
#
#   Name       : TWebSocketServer::SendPing
#
#   Purpose....: Send ping
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::SendPing(const char *str)
{
    SendControl(0x89, str);
}
   
/*##########################################################################
#
#   Name       : TWebSocketServer::SendPong
#
#   Purpose....: Send ping
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::SendPong(const char *str)
{
    SendControl(0x8A, str);
}
   
/*##########################################################################
#
#   Name       : TWebSocketServer::ReceivedPing
#
#   Purpose....: Received ping
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::ReceivedPing(char *str)
{
    SendPong(str);
}
   
/*##########################################################################
#
#   Name       : TWebSocketServer::ReceivedPong
#
#   Purpose....: Received pong
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWebSocketServer::ReceivedPong(char *str)
{
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
void TWebSocketServer::HandleUpgrade(const char *Name, THttpCommand *Cmd, const char *upgrade)
{
    THttpOption *opt;
    const char *prot;
    TString key;
    TString str;
    bool ok = false;

    if (strstr(upgrade, "websocket"))
        ok = true;
    else
        ok = false;

    if (ok)
    {
        FReqUrl = Name;

        opt = Cmd->FindOption("Sec-WebSocket-Key");
        if (opt)
            key = opt->GetArg(0);

         if (key.GetSize() == 0)
            ok = false;
    }

    if (ok)
    {
        FProtocols = Cmd->FindOption("Sec-WebSocket-Protocol");
        if (!FProtocols)
            ok = false;
    }

    if (ok)
    {
        opt = Cmd->FindOption("Sec-WebSocket-Version");
        if (opt)
        {
            str = opt->GetArg(0);
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
            SendAccept(Cmd, prot);
            HandleWebSocket();
        }
        else
            SendReject(Cmd);
    }
    else
        THttpSocketServer::HandleUpgrade(Name, Cmd, upgrade);
}
