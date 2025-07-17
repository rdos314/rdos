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
# websock.h
# Web socket class
#
########################################################################*/

#ifndef _WEBSOCK_H
#define _WEBSOCK_H

#include "httpserv.h"
#include "httpopt.h"
#include "str.h"
#include "section.h"

class TWebSocketServer : public THttpSocketServer
{
public:
    TWebSocketServer(const char *Name, int StackSize, TTcpSocket *Socket);
    virtual ~TWebSocketServer();
    
protected:
    void CalcAccept(const char *str);
    void SendAccept(THttpCommand *Cmd, const char *prot);
    void SendReject(THttpCommand *Cmd);
    void HandleWebSocket();
    void Unmask(char *buf, int size, char *mask);

    virtual void HandleUpgrade(const char *Name, THttpCommand *Cmd, const char *prot);
    virtual void StartWebSocket();
    virtual void EndWebSocket();
    virtual void PollWebSocket();
    
    virtual const char *GetProtocol() = 0;
    virtual void ReceivedText(char *str) = 0;
    virtual void ReceivedBinary(char *str, int size) = 0;
    virtual void ReceivedPing(char *str);
    virtual void ReceivedPong(char *str);

    void SendText(const char *str);
    void SendBinary(const char *str, int size);

    void SendControl(char op, const char *str);
    void SendPing(const char *str);
    void SendPong(const char *str);

    TString FHost;
    TString FReqUrl;
    THttpOption *FProtocols;
    int FVersion;
    char FAcceptStr[30];

    TSection FSection;
};

#endif

