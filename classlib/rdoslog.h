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
# log.h
# Log class
#
########################################################################*/

#ifndef _RDOS_LOG_H
#define _RDOS_LOG_H

#include <string.h>
#include "strlist.h"
#include "thread.h"
#include "file.h"
#include "sigdev.h"

#define MAX_LOG_LEVELS	50

class TRdosLogThread : public TThread
{
    friend class TRdosLog;
public:
    TRdosLogThread(const char *path, int filecount, int filesize, int MaxFutureMonths);
    TRdosLogThread(const char *path, int filecount, int filesize, const char *ThreadName);
    TRdosLogThread(const char *path, int filecount, int filesize);
    TRdosLogThread();
    virtual ~TRdosLogThread();

    void Setup(const char *path, int filecount, int filesize);
    void DefineLogLevel(int Level, const char *name);
    void SetLogLevel(int Level);
    int GetLogLevel();

    void StartLog(const char *ThreadName);
    void Add(int level, TString &str);

    virtual void Stop();

protected:
    void Init();
    void InitFiles();
    void CheckFileCount();
    void SwitchFile();

    void Write(TString &str);
    virtual void Execute();

    TSignalDevice FSigDev;
    TStringList FList;
    TString FLogPath;
    int FFileCount;
    int FFileSize;
    int FLogLevel;

    TString FLevelArr[MAX_LOG_LEVELS];

    int FCurrId;
    TFile *FCurrFile;
    int FRowNum;
    bool FInitDone;
    bool FWasEmpty;
    bool FTimeError;
    TDateTime FLastTime;
    bool FAdjustTime;
    int FMaxMonths;
};

class TRdosLog
{
public:
    TRdosLog(TRdosLogThread *logdev, const char *cl);
    TRdosLog(const char *cl);
    virtual ~TRdosLog();

    void Log(int level, const char *label, const char *msg);
    void printf(int level, const char *label, const char *msg, ...);

    TString GetClass();
    TRdosLogThread *GetLogger();
    bool WasLogEmpty();
    bool HasTimeError();
    TDateTime GetLastTime();

protected:
    virtual void Add(int level, TString &str);

    TRdosLogThread *FDev;
    TString FClass;
};

class TRdosDefaultLog : public TRdosLog, public TRdosLogThread
{
public:
    TRdosDefaultLog(const char *path, int filecount, int filesize, const char *threadname, const char *cl);
    TRdosDefaultLog(const char *path, int filecount, int filesize, const char *cl);
    TRdosDefaultLog(const char *path, int filecount, int filesize, const char *cl, int MaxMonths);
    virtual ~TRdosDefaultLog();
};

class TRdosEventLog : public TRdosLog, public TThread
{
public:
    TRdosEventLog(const char *LogPath, int DumpFiles, int EntryCount, TRdosLogThread *logdev, const char *cl);
    TRdosEventLog(const char *LogPath, int DumpFiles, int EntryCount, const char *cl);
    virtual ~TRdosEventLog();

    void DumpEvents();

protected:
    void Init(int DumpFiles, int EntryCount);
    void CheckFileCount();
    void InitFiles();
    void DumpOne(TString *entry);

    virtual void Add(int level, TString &str);
    virtual void Execute();

    TString FLogPath;
    int FFileCount;

    int FEntryCount;
    TString **FEntryArr;

    TSection FEventSection;
    TSignalDevice FDumpSignal;
    int FNextPos;
    int FCurrId;
    TFile *FCurrFile;
};

#endif
