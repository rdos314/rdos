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
# wdserv.h
# WD socket server class
#
########################################################################*/

#ifndef _WDSERV_H
#define _WDSERV_H

#include "str.h"
#include "sockobj.h"
#include "debug.h"

#define MAX_MSG_SIZE    1024

class TWdSupplService;
class TWdSocketServerFactory;

class TWdSocketServer : public TSocketServer
{
friend class TWdSupplService;

public:
    TWdSocketServer(TWdSocketServerFactory *fact, const char *Name, int StackSize, TTcpSocket *Socket);
    ~TWdSocketServer();

    void AddSuppl(TWdSupplService *service);

    void LogMsg(const char *msg);
    void DebugLog(const char *msg);
    void (*OnMsg)(TWdSocketServer *wd, const char *msg);

protected:
    char GetByte();
    short int GetWord();
    long GetDword();
    void GetString(char *str, int maxsize);
    void GetData(void *ptr, int size);
    void *GetData(int *size);

    void PutByte(char val);
    void PutWord(short int val);
    void PutDword(long val);
    void PutString(const char *str);
    void PutData(void *ptr, int size);

    TDebug *GetDebug();

    TString CheckFileExt(const char *path, const char *ext);
    TString CheckFileExt(const char *path, const char *name, const char *ext);
    TString CheckPathFileExt(char *path, const char *name, const char *ext);
    TString GetFullPathName(char *name, const char *ext);

    void ReqError();

    void ReqConnect();
    void ReqDisconnect();    
    void ReqSuspend();
    void ReqResume();
    void ReqGetSupplService();
    void ReqPerformSupplService();
    void ReqGetSysConfig();
    void ReqMapAddr();
    void ReqAddrInfo();
    void ReqChecksumMem();
    void ReqReadMem();
    void ReqWriteMem();
    void ReqReadIo();
    void ReqWriteIo();
    void ReqReadCpu();
    void ReqReadFpu();
    void ReqWriteCpu();
    void ReqWriteFpu();
    void ReqProgGo();
    void ReqProgStep();
    void ReqProgLoad();
    void ReqProgKill();
         void ReqSetWatch();
    void ReqClearWatch();
    void ReqSetBreak();
    void ReqClearBreak();
    void ReqGetNextAlias();
    void ReqSetUserScreen();
    void ReqSetDebugScreen();
    void ReqReadUserKeyboard();
    void ReqGetLibName();
    void ReqGetErrText();
    void ReqGetMsgText();
    void ReqRedirStdin();
    void ReqRedirStdout();
         void ReqSplitCmd();
         void ReqReadReg();
         void ReqWriteReg();
    void ReqMachineData();
    
    void NotifyMsg19();
    void NotifyMsg20();
    void NotifyMsg();

        virtual void HandleSocket();

    int FInSize;
        char FInBuf[MAX_MSG_SIZE];
        char *FInPtr;

    int FOutSize;
    char FOutBuf[MAX_MSG_SIZE]; 
    char *FOutPtr;

    int FSuppressAnswer;
    int FIs19;
    int FIs20;

    int FRunning;

    TWdSocketServerFactory *FFactory;
    TWdSupplService *FSupplList;
    TDebug *FDebug;
    TDebugThread *FMainThread;
    TDebugThread *FCurrentThread;
    TDebugModule *FMainModule;
};

#endif
