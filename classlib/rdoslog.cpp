/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2019, Leif Ekblad
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
# log.cpp
# Log progra
#
########################################################################*/

#include <stdio.h>
#include "str.h"
#include "rdoslog.h"
#include "rdos.h"
#include "path.h"
#include "direntry.h"

static TRdosLogThread *LogThread = 0;
static TSection Section("Log Section");

#define FALSE   0
#define TRUE    !FALSE
#define MAX_STR_SIZE    0x10000

/*##########################################################################
#
#   Name       : TRdosLogThread::TRdosLogThread
#
#   Purpose....: TRdosLogThread constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLogThread::TRdosLogThread()
{
    FFileCount = 0;
    FFileSize = 0;
    FAdjustTime = false;

    Init();
}

/*##########################################################################
#
#   Name       : TRdosLogThread::TRdosLogThread
#
#   Purpose....: TRdosLogThread constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLogThread::TRdosLogThread(const char *path, int filecount, int filesize)
  : FLogPath(path)
{
    FFileCount = filecount;
    FFileSize = filesize;
    FAdjustTime = false;

    Init();
    StartLog("Log Thread");
}

/*##########################################################################
#
#   Name       : TRdosLogThread::TRdosLogThread
#
#   Purpose....: TRdosLogThread constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLogThread::TRdosLogThread(const char *path, int filecount, int filesize, int maxmonths)
  : FLogPath(path)
{
    FFileCount = filecount;
    FFileSize = filesize;
    FAdjustTime = true;
    FMaxMonths = maxmonths;

    Init();
    StartLog("Log Thread");
}

/*##########################################################################
#
#   Name       : TRdosLogThread::TRdosLogThread
#
#   Purpose....: TRdosLogThread constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLogThread::TRdosLogThread(const char *path, int filecount, int filesize, const char *name)
  : FLogPath(path)
{
    FFileCount = filecount;
    FFileSize = filesize;
    FAdjustTime = false;

    Init();
    StartLog(name);
}

/*##########################################################################
#
#   Name       : TRdosLogThread::~TRdosLogThread
#
#   Purpose....: TRdosLogThread destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLogThread::~TRdosLogThread()
{
}

/*##########################################################################
#
#   Name       : TRdosLogThread::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::Init()
{
    FLogLevel = 0;
    FRowNum = 0;
    FCurrFile = 0;
    FInitDone = false;
}

/*##########################################################################
#
#   Name       : TRdosLogThread::Setup
#
#   Purpose....: Setup
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::Setup(const char *path, int filecount, int filesize)
{
    if (IsRunning())
        Stop();

    FLogPath = path;
    FFileCount = filecount;
    FFileSize = filesize;
    FAdjustTime = false;
    StartLog("Log Thread");
}

/*##########################################################################
#
#   Name       : TRdosLogThread::DefineLogLevel
#
#   Purpose....: Define log level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::DefineLogLevel(int Level, const char *name)
{
    if (Level >= 0 && Level < MAX_LOG_LEVELS)
        FLevelArr[Level] = name;
}

/*##########################################################################
#
#   Name       : TRdosLogThread::SetLogLevel
#
#   Purpose....: Set log level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::SetLogLevel(int Level)
{
    FLogLevel = Level;
}

/*##########################################################################
#
#   Name       : TRdosLogThread::GetLogLevel
#
#   Purpose....: Get log level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosLogThread::GetLogLevel()
{
    return FLogLevel;
}

/*##########################################################################
#
#   Name       : TRdosLogThread::StartLog
#
#   Purpose....: Start log
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::StartLog(const char *ThreadName)
{
    if (!IsRunning() && FFileCount && FFileSize)
        Start(ThreadName, 0x8000);
}

/*##########################################################################
#
#   Name       : TRdosLogThread::Add
#
#   Purpose....: Add log entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::Add(int level, TString &str)
{
    bool logit = false;

    if (level >= FLogLevel)
        logit = true;

    if (logit)
        if (!IsRunning() && FFileCount && FFileSize)
            logit = false;

    if (logit)
    {
        FList.AddLast(str);
        FSigDev.Signal();
    }
}

/*##########################################################################
#
#   Name       : TRdosLogThread::Stop
#
#   Purpose....: Stop
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::Stop()
{
    FInstalled = FALSE;
    FSigDev.Signal();

    TThread::Stop();
}

/*##########################################################################
#
#   Name       : TRdosLogThread::Write
#
#   Purpose....: Write log entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::Write(TString &str)
{
    int size;
    TString wrstr;

    wrstr.printf("%04d ", FRowNum);
    wrstr += str;
    wrstr += "\r\n";

    size = wrstr.GetSize();

    if (size >= MAX_STR_SIZE || size < 0)
    {
        wrstr.printf("Too long entry\r\n");
        size = wrstr.GetSize();
    }

    if (size < MAX_STR_SIZE && size > 0)
        FCurrFile->Write(wrstr.GetData(), size);

    FRowNum++;
    if (FRowNum == 10000)
        FRowNum = 0;

    if (FCurrFile->GetSize() >= FFileSize)
        SwitchFile();
}

/*##########################################################################
#
#   Name       : TRdosLogThread::InitFiles
#
#   Purpose....: Init files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::InitFiles()
{
    bool ok;
    TDirList FileList;
    TDirEntry entry;
    TString basename;
    TPathName path;
    TDateTime currtime;
    char *file;
    char *ptr;
    int index;
    TString str;

    FCurrId = 0;

    file = new char[256];

    FileList.AddSortByTime();
    FileList.Add(FLogPath);
    FileList.Sort();

    ok = FileList.GotoFirst();

    FWasEmpty = !ok;

    while (ok)
    {
        entry = FileList.Get();
        basename = entry.GetEntryName();
        strcpy(file, basename.GetData());
        if (strstr(file, ".log"))
        {
            ptr = strchr(file, '.');
            if (ptr)
                *ptr = 0;

            index = atoi(file);

            if (index > FCurrId)
            {
                FCurrId = index;
                FLastTime = entry.GetModifyTime();
            }
        }
        else
        {
            path = entry.GetPathName();
            path.DeleteFile();
        }

        ok = FileList.GotoNext();
    }


    if (FAdjustTime)
    {
        if (FWasEmpty)
            FTimeError = false;
        else
        {
            if (currtime < FLastTime)
            {
                FTimeError = true;
                FLastTime.Set();
            }
            else
            {
                currtime.AddMonth(-FMaxMonths);
                if (currtime > FLastTime)
                {
                    FTimeError = true;
                    FLastTime.Set();
                }
                else
                    FTimeError = false;
            }
        }
    }
    else
        FTimeError = false;

    FInitDone = true;

    delete file;

    CheckFileCount();

    if (FCurrId == 0)
        SwitchFile();
    else
    {
        str.printf("%s/%d.log", FLogPath.GetData(), FCurrId);
        FCurrFile = new TFile(str.GetData());
        FCurrFile->SetPos(FCurrFile->GetSize());
    }
}

/*##########################################################################
#
#   Name       : TRdosLogThread::CheckFileCount
#
#   Purpose....: Check file count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::CheckFileCount()
{
    TDirList FileList;
    TDirEntry entry;
    TPathName path;
    int count;

    FileList.AddSortByTime();
    FileList.Add(FLogPath);
    FileList.Sort();

    count = FileList.GetSize();

    FileList.GotoFirst();

    while (count > FFileCount)
    {
        entry = FileList.Get();
        path = entry.GetPathName();
        path.DeleteFile();

        count--;
        FileList.GotoNext();
    }
}

/*##########################################################################
#
#   Name       : TRdosLogThread::SwitchFile
#
#   Purpose....: Switch file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::SwitchFile()
{
    TString str;

    if (FCurrFile)
        delete FCurrFile;

    FCurrId++;
    str.printf("%s/%d.log", FLogPath.GetData(), FCurrId);
    FCurrFile = new TFile(str.GetData(), 0);

    CheckFileCount();
}

/*##########################################################################
#
#   Name       : TRdosLogThread::Execute
#
#   Purpose....: Thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLogThread::Execute()
{
    TString str;
    TPathName path(FLogPath);

    if (path.MakeDir())
    {
        InitFiles();

        while (FInstalled)
        {
            while (FInstalled && FList.GotoFirst())
            {
                str = FList.Get();
                Write(str);
                FList.RemoveFirst();
            }

            if (FInstalled)
                FSigDev.WaitForever();
        }

        if (FCurrFile)
        {
            delete FCurrFile;
            FCurrFile = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : TRdosLog::TRdosLog
#
#   Purpose....: Log constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLog::TRdosLog(TRdosLogThread *logdev, const char *cl)
  : FClass(cl)
{
    FDev = logdev;
}

/*##########################################################################
#
#   Name       : TRdosLog::TRdosLog
#
#   Purpose....: Log constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLog::TRdosLog(const char *cl)
  : FClass(cl)
{
    Section.Enter();

    if (!LogThread)
        LogThread = new TRdosLogThread;

    Section.Leave();

    FDev = LogThread;
}

/*##########################################################################
#
#   Name       : TRdosLog::~TRdosLog
#
#   Purpose....: Log destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLog::~TRdosLog()
{
}

/*##########################################################################
#
#   Name       : TRdosLog::GetClass
#
#   Purpose....: Get class name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosLog::GetClass()
{
    return FClass;
}

/*##########################################################################
#
#   Name       : TRdosLog::GetLogger
#
#   Purpose....: Get log thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLogThread *TRdosLog::GetLogger()
{
    return FDev;
}

/*##########################################################################
#
#   Name       : TRdosLog::Add
#
#   Purpose....: Add log msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::Add(int level, TString &str)
{
    FDev->Add(level, str);
}

/*##########################################################################
#
#   Name       : TRdosLog::WasLogEmpty
#
#   Purpose....: Was log empty
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TRdosLog::WasLogEmpty()
{
    while (!FDev->FInitDone)
        RdosWaitMilli(50);

    return FDev->FWasEmpty;
}

/*##########################################################################
#
#   Name       : TRdosLog::HasTimeError
#
#   Purpose....: Has time error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TRdosLog::HasTimeError()
{
    while (!FDev->FInitDone)
        RdosWaitMilli(50);

    return FDev->FTimeError;
}

/*##########################################################################
#
#   Name       : TRdosLog::GetLastTime
#
#   Purpose....: Get last time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TRdosLog::GetLastTime()
{
    while (!FDev->FInitDone)
        RdosWaitMilli(50);

    return FDev->FLastTime;
}

/*##########################################################################
#
#   Name       : TRdosLog::Log
#
#   Purpose....: Write log entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::Log(int level, const char *label, const char *msg)
{
    TString str;
    TDateTime time;

    str.printf("%04d-%02d-%02d %02d.%02d.%02d,%03d  ",
                       time.GetYear(), time.GetMonth(), time.GetDay(),
                       time.GetHour(), time.GetMin(), time.GetSec(), time.GetMilliSec());

    if (level >= 0 && level < MAX_LOG_LEVELS)
    {
        if (FDev->FLevelArr[level].GetSize())
        {
            str += "(";
            str += FDev->FLevelArr[level];
            str += ")  ";
        }
    }

    if (strlen(msg) < MAX_STR_SIZE)
        str += msg;
    else
        str += "Too long msg";

    if (FClass.GetSize())
    {
        str += " [";
        str += FClass;
        str += ":";
        str += label;
        str += "]";
    }
    else
    {
        if (strlen(label))
        {
            str += " [";
            str += label;
            str += "]";
        }
    }

    Add(level, str);
}

/*##########################################################################
#
#   Name       : TRdosLog::printf
#
#   Purpose....: Write log entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::printf(int level, const char *label, const char *msg, ...)
{
    va_list args;
    TString str;

    va_start(args, msg);
    str.prtf(msg, args);
    va_end(args);

    Log(level, label, str.GetData());
}

/*##########################################################################
#
#   Name       : TRdosDefaultLog::TRdosDefaultLog
#
#   Purpose....: Default log constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDefaultLog::TRdosDefaultLog(const char *path, int filecount, int filesize, const char *threadname, const char *cl)
 : TRdosLog(0, cl),
   TRdosLogThread(path, filecount, filesize, threadname)
{
    Section.Enter();
    LogThread = this;
    Section.Leave();

    FDev = LogThread;
}

/*##########################################################################
#
#   Name       : TRdosDefaultLog::TRdosDefaultLog
#
#   Purpose....: Default log constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDefaultLog::TRdosDefaultLog(const char *path, int filecount, int filesize, const char *cl)
 : TRdosLog(0, cl),
   TRdosLogThread(path, filecount, filesize)
{
    Section.Enter();
    LogThread = this;
    Section.Leave();

    FDev = LogThread;
}

/*##########################################################################
#
#   Name       : TRdosDefaultLog::TRdosDefaultLog
#
#   Purpose....: Default log constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDefaultLog::TRdosDefaultLog(const char *path, int filecount, int filesize, const char *cl, int maxmonths)
 : TRdosLog(0, cl),
   TRdosLogThread(path, filecount, filesize, maxmonths)
{
    Section.Enter();
    LogThread = this;
    Section.Leave();

    FDev = LogThread;
}

/*##########################################################################
#
#   Name       : TRdosDefaultLog::~TRdosDefaultLog
#
#   Purpose....: Default log destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDefaultLog::~TRdosDefaultLog()
{
}

/*##########################################################################
#
#   Name       : TRdosEventLog::TRdosEventLog
#
#   Purpose....: Event log constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosEventLog::TRdosEventLog(const char *LogPath, int DumpFiles, int EntryCount, TRdosLogThread *logdev, const char *cl)
 : TRdosLog(logdev, cl),
   FLogPath(LogPath),
   FEventSection("EventLog")
{
    Init(DumpFiles, EntryCount);
}

/*##########################################################################
#
#   Name       : TRdosEventLog::TRdosEventLog
#
#   Purpose....: Event log constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosEventLog::TRdosEventLog(const char *LogPath, int DumpFiles, int EntryCount, const char *cl)
 : TRdosLog(cl),
   FLogPath(LogPath),
   FEventSection("EventLog")
{
    Init(DumpFiles, EntryCount);
}

/*##########################################################################
#
#   Name       : TRdosEventLog::~TRdosEventLog
#
#   Purpose....: Event log destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosEventLog::~TRdosEventLog()
{
}

/*##########################################################################
#
#   Name       : TRdosLog::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosEventLog::Init(int DumpFiles, int EntryCount)
{
    int i;
    TString str;

    FEntryCount = EntryCount;
    FEntryArr = new TString *[EntryCount];

    for (i = 0; i < EntryCount; i++)
        FEntryArr[i] = 0;

    FFileCount = DumpFiles;
    FNextPos = 0;
}

/*##########################################################################
#
#   Name       : TRdosEventLog::Add
#
#   Purpose....: Add log msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosEventLog::Add(int level, TString &str)
{
    TRdosLog::Add(level, str);

    FEventSection.Enter();

    if (FEntryArr[FNextPos])
        *FEntryArr[FNextPos] = str;
    else
        FEntryArr[FNextPos] = new TString(str);

    FNextPos++;
    if (FNextPos >= FEntryCount)
        FNextPos = 0;

    FEventSection.Leave();
}

/*##########################################################################
#
#   Name       : TRdosEventLog::DumpEvents
#
#   Purpose....: Dump buffer to file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosEventLog::DumpEvents()
{
    TString str;

    if (FFileCount && !IsRunning())
    {
        str = "EvLog ";
        str += FClass;
        Start(str.GetData(), 0x4000);
    }
}

/*##########################################################################
#
#   Name       : TRdosEventLog::CheckFileCount
#
#   Purpose....: Check file count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosEventLog::CheckFileCount()
{
    TDirList FileList;
    TDirEntry entry;
    TString basename;
    TPathName path;
    char *file;
    int count = 0;
    bool ok;

    file = new char[256];

    FileList.AddSortByTime();
    FileList.Add(FLogPath);
    FileList.Sort();

    ok = FileList.GotoLast();

    while (ok)
    {
        entry = FileList.Get();
        basename = entry.GetEntryName();
        strcpy(file, basename.GetData());
        if (strstr(file, ".ldd"))
        {
            count++;
            if (count > FFileCount)
            {
                path = entry.GetPathName();
                if (path.IsFile())
                    path.DeleteFile();
            }
        }

        ok = FileList.GotoPrev();
    }

    delete file;
}

/*##########################################################################
#
#   Name       : TRdosEventLog::InitFiles
#
#   Purpose....: Init files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosEventLog::InitFiles()
{
    bool ok;
    TDirList FileList;
    TDirEntry entry;
    TString basename;
    TPathName path;
    char *file;
    char *ptr;
    int index;
    TString str;

    FCurrId = 0;

    file = new char[256];

    FileList.AddSortByTime();
    FileList.Add(FLogPath);
    FileList.Sort();

    ok = FileList.GotoFirst();

    while (ok)
    {
        entry = FileList.Get();
        basename = entry.GetEntryName();
        strcpy(file, basename.GetData());
        if (strstr(file, ".ldd"))
        {
            if (entry.GetFileSize() == 0)
            {
                path = entry.GetPathName();
                if (path.IsFile())
                    path.DeleteFile();
            }
            else
            {
                ptr = strchr(file, '.');
                if (ptr)
                    *ptr = 0;

                index = atoi(file);

                if (index > FCurrId)
                    FCurrId = index;
            }
        }

        ok = FileList.GotoNext();
    }

    delete file;

    FCurrId++;
    str.printf("%s/%d.ldd", FLogPath.GetData(), FCurrId);
    FCurrFile = new TFile(str.GetData(), 0);

    CheckFileCount();
}

/*##################  TRdosEventLog::DumpOne  #######################
*   Purpose....: Write dump entry                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRdosEventLog::DumpOne(TString *entry)
{
    int size;
    TString str(*entry);
    str += "\r\n";

    size = str.GetSize();

    if (size >= MAX_STR_SIZE || size < 0)
    {
        str.printf("Too long dump entry\r\n");
        size = str.GetSize();
    }

    if (size < MAX_STR_SIZE)
        FCurrFile->Write(str.GetData(), size);
}

/*##################  TRdosEventLog::Execute  #######################
*   Purpose....: Dump thread                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRdosEventLog::Execute()
{
    int i;
    int pos;
    TString **DumpArr;
    TPathName path(FLogPath);

    if (path.MakeDir())
    {
        InitFiles();

        DumpArr = new TString *[FEntryCount];

        FEventSection.Enter();

        pos = FNextPos;

        for (i = 0; i < FEntryCount; i++)
            if (FEntryArr[i])
                DumpArr[i] = new TString(*FEntryArr[i]);
            else
                DumpArr[i] = 0;

        FEventSection.Leave();

        for (i = pos; i < FEntryCount; i++)
            if (DumpArr[i])
                DumpOne(DumpArr[i]);

        for (i = 0; i < pos; i++)
            if (DumpArr[i])
                DumpOne(DumpArr[i]);

        for (i = 0; i < FEntryCount; i++)
            if (DumpArr[i])
                delete DumpArr[i];

        delete DumpArr;
        delete FCurrFile;
        FCurrFile = 0;
    }
}
