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
# hhcn818.h
# HHC-N818OP class
#
########################################################################*/

#ifndef _HHCN818_H
#define _HHCN818_H

#include "sockobj.h"
#include "thread.h"
#include "str.h"
#include "sigdev.h"
#include "section.h"

class THhcRelay : public TThread
{
public:
    THhcRelay(char *HostStr);
    virtual ~THhcRelay();

    bool IsOnline();

    bool IsOn(int relay);
    void On(int relay);
    void Off(int relay);

    bool ReadInput(int input);

protected:
    void HandleName(char *str);
    void HandleRelay(char *str);
    void HandleInput(char *str);
    void HandleOn(char *str);
    void HandleOff(char *str);
    void HandleData();

    virtual void Execute();

    bool FOnline;
    long FIP;
    int FPort;
    TString FName;
    bool FRelayArr[8];
    bool FInputArr[8];
    char *FHostStr;
    TTcpSocket *FSocket;
    TSignalDevice FSignal;
    TSection FSection;
};

#endif

