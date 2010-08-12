/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# ftp.h
# FTP client class
#
########################################################################*/

#ifndef _FTP_H
#define _FTP_H

#include "socket.h"
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
    TSocket *FSocket;
    TSocket *FDataSocket;

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

