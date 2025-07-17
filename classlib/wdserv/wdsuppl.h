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
# wdsuppl.h
# WD supplementary service base class
#
########################################################################*/

#ifndef _WDSUPPL_H
#define _WDSUPPL_H

#include "str.h"
#include "wdfact.h"
#include "wdserv.h"

class TWdSupplService;

class TWdSupplFactory
{
public:
	 TWdSupplFactory(TWdSocketServerFactory *factory, const char *Name);
	virtual ~TWdSupplFactory();

	virtual TWdSupplService *Create(TWdSocketServer *server) = 0;

    char *FName;
	TWdSupplFactory *FNext;
};

class TWdSupplService
{
public:
    TWdSupplService(TWdSocketServer *server);
	virtual ~TWdSupplService();

    virtual void NotifyMsg() = 0;

    TWdSupplService *FNext;

protected:
    void LogMsg(const char *msg);
    void DebugLog(const char *msg);

    char GetByte();
    short int GetWord();
    long GetDword();
    void GetString(char *str, int maxsize);

    void PutByte(char val);
    void PutWord(short int val);
    void PutDword(long val);
    void PutString(const char *str);
    void PutData(void *ptr, int size);

    void SetCurrentThread(TDebugThread *thread);

    TDebug *GetDebug();
    TString GetFullPathName(char *name, const char *ext);

    TWdSocketServer *FServer;
};

#endif
