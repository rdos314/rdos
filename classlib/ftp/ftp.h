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
# ftp.h
# FTP client class
#
########################################################################*/

#ifndef _FTP_H
#define _FTP_H

#include "sockobj.h"
#include "thread.h"
#include "sigdev.h"
#include "file.h"
#include "str.h"

class TFtpEntry
{
public:
    TFtpEntry(int year, int month, int day, int hour, int min, const char *name);
    virtual ~TFtpEntry();

    virtual int IsDir() = 0;

    TDateTime time;
    TString name;
};    

class TFtpDirEntry : public TFtpEntry
{
public:
    TFtpDirEntry(int year, int month, int day, int hour, int min, const char *name);
    virtual ~TFtpDirEntry();

    virtual int IsDir();

    TFtpDirEntry *next;
};    

class TFtpFileEntry : public TFtpEntry
{
public:
    TFtpFileEntry(int year, int month, int day, int hour, int min, const char *name, int size);
    virtual ~TFtpFileEntry();

    virtual int IsDir();

    int size;

    TFtpFileEntry *next;
};    


class TFtp : public TThread
{
public:
    TFtp(long IP, int port, const char *user, const char *passw);
    virtual ~TFtp();

    void (*OnMsg)(TFtp *ftp, const char *msg);

    void Enable();
    void Disable();

    int SetDir(const char *path);
    void SetAsciiMode();
    void SetBinaryMode();
    int GetFile(const char *remote, TFile *file);

    int MkDir(const char *path);
    int CreateFile(const char *remote, TFile *file);

    int GotoFirstDir();
    int GotoFirstFile();
    int GotoNextDir();
    int GotoNextFile();
    TString GetCurrDirName();
    int GetDir(TString &name, TDateTime &time);
    int GetFile(TString &name, TDateTime &time, int *size);

    void HandleDataSocket();

protected:
    void NotifyMsg(const char *msg);
    void SendUser();
    void SendPassword();
    void SendPwd();
    void SendCwd(const char *path);
    void SendMkd(const char *path);
    void DecodePwd(const char *param);
    void SendList();
    void SendRetr();
    void SendStor();
    void SendPasv();
    void SendType(char type);
    void DecodePasv(const char *param);
    void HandleResponse(int code, const char *param);
    void HandleResponse(const char *msg);
    void HandleOpen();
    void HandleClosed();
    void ClearEntries();
    void AddDir(TFtpDirEntry *entry);
    void AddFile(TFtpFileEntry *entry);
    void HandleDirEntry(char *data);
    void HandleDirData(char *data, int size);
    virtual void Execute();
    void CacheDir();

    long FIp;
    int FPort;
    TString FUser;
    TString FPassw;
    TTcpSocket *FSocket;
    TTcpSocket *FDataSocket;

    TSection FAppSection;
    TSignalDevice FAppSignal;
    int FAborted;
    int FReady;
    int FDirCached;
    int FGetDir;
    int FSetDir;
    int FGetFile;
    int FWriteFile;
    int FWriteWait;
    int FStorSent;
    int FMkDir;
    char *FDirData;
    int FDirCount;
    int FSuccess;
    TFile *FFile;
    TString FRemoteFile;

    int FEnabled;

    int FCloseData;    
    int FLastCode;
    TString FCurrDirName;

    TSection FSection;
    TFtpDirEntry *FDirList;
    TFtpFileEntry *FFileList;

    TFtpDirEntry *FCurrDir;
    TFtpFileEntry *FCurrFile;
};

#endif

