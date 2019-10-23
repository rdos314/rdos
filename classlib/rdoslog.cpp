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

#define FALSE	0
#define TRUE	!FALSE
#define MAX_STR_SIZE	0x1000

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

    Init();
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
    {
        Stop();

        FLogPath = path;
        FFileCount = filecount;
        FFileSize = filesize;
        StartLog();
    }
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
void TRdosLogThread::StartLog()
{
    if (!IsRunning() && FFileCount && FFileSize)
        Start("Log Thread", 0x8000);
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
    char rowstr[10];

    sprintf(rowstr, "%04d ", FRowNum);
    FCurrFile->Write(rowstr, strlen(rowstr));
    FCurrFile->Write(str.GetData(), str.GetSize());

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
        if (strstr(file, ".log"))
        {
            ptr = strchr(file, '.');
            if (ptr)
                *ptr = 0;

            index = atoi(file);            

            if (index > FCurrId)
                FCurrId = index;
        }
        else
        {
            path = entry.GetPathName();
            path.DeleteFile();
        }
            
        ok = FileList.GotoNext();
    }    

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
    Init();
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

    Init();
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
#   Name       : TRdosLog::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::Init()
{
    FEntryCount = 0;
    FFileCount = 0;
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
#   Name       : TRdosLog::Setup
#
#   Purpose....: Setup log location
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::Setup(const char *Path, int FileCount, int FileSize)
{
    FDev->Setup(Path, FileCount, FileSize);
}

/*##########################################################################
#
#   Name       : TRdosLog::DefineLogLevel
#
#   Purpose....: Define log level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::DefineLogLevel(int Level, const char *name)
{
    FDev->DefineLogLevel(Level, name);
}

/*##########################################################################
#
#   Name       : TRdosLog::SetLogLevel
#
#   Purpose....: Set log level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::SetLogLevel(int Level)
{
    FDev->SetLogLevel(Level);
}

/*##########################################################################
#
#   Name       : TRdosLog::GetLogLevel
#
#   Purpose....: Get log level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosLog::GetLogLevel()
{
    return FDev->GetLogLevel();
}

/*##########################################################################
#
#   Name       : TRdosLog::ShutDown
#
#   Purpose....: Shutdown log thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::ShutDown()
{
    FDev->Stop();
}

/*##########################################################################
#
#   Name       : TRdosLog::Write
#
#   Purpose....: Write log entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::Write(int level, const char *label, const char *msg) 
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

    str += " [";
    str += FClass;
    str += ":";
    str += label;
    str += "]";

    FDev->Add(level, str);

    if (FFileCount && FEntryCount)
    {
        FEventSection->Enter();

        if (FEntryArr[FNextPos])
            *FEntryArr[FNextPos] = str;
        else
            FEntryArr[FNextPos] = new TString(str);

        FNextPos++;
        if (FNextPos >= FEntryCount)
            FNextPos = 0;

        FEventSection->Leave();
    }
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
    str.printf(msg, args);
    va_end(args);

    Write(level, label, str.GetData());
}

/*##########################################################################
#
#   Name       : TRdosLog::DefineEventDebug
#
#   Purpose....: Define event debug
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount)
{
    int i;
    TString str;

    str = "EventLog.";
    str += FClass;
    FEventSection = new TSection(str.GetData());

    FLogPath = LogPath;

    FEntryCount = EntryCount;
    FEntryArr = new TString *[EntryCount];

    for (i = 0; i < EntryCount; i++)
        FEntryArr[i] = 0;

    FFileCount = DumpFiles;
    FNextPos = 0;
}

/*##########################################################################
#
#   Name       : TRdosLog::DumpEvents
#
#   Purpose....: Dump buffer to file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::DumpEvents()
{
    if (FFileCount && !IsRunning())
        Start("Log Dump", 0x4000);
}

/*##########################################################################
#
#   Name       : TRdosLog::CheckFileCount
#
#   Purpose....: Check file count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::CheckFileCount()
{
    TDirList FileList;
    TDirEntry entry;
    TPathName path;
    int count;
    TString LogPath(FLogPath);

    LogPath += "/*.ldd";

    FileList.AddSortByTime();
    FileList.Add(LogPath);
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
#   Name       : TRdosLog::InitFiles
#
#   Purpose....: Init files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosLog::InitFiles()
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
            ptr = strchr(file, '.');
            if (ptr)
                *ptr = 0;

            index = atoi(file);            

            if (index > FCurrId)
                FCurrId = index;
        }
            
        ok = FileList.GotoNext();
    }    

    delete file;

    FCurrId++;
    str.printf("%s/%d.log", FLogPath.GetData(), FCurrId);
    FCurrFile = new TFile(str.GetData(), 0);

    CheckFileCount();        
}

/*##################  TRdosLog::Execute  #######################
*   Purpose....: Dump thread                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRdosLog::Execute()
{
    int i;
    int pos;
    TString **DumpArr;

    InitFiles();

    DumpArr = new TString *[FEntryCount];

    FEventSection->Enter();

    pos = FNextPos;

    for (i = 0; i < FEntryCount; i++)
        if (FEntryArr[i])
            DumpArr[i] = new TString(*FEntryArr[i]);
        else
            DumpArr[i] = 0;
        
    FEventSection->Leave();
        
    for (i = pos; i < FEntryCount; i++) 
        if (FEntryArr[i])
            FCurrFile->Write(DumpArr[i]->GetData(), DumpArr[i]->GetSize());

    for (i = 0; i < pos; i++)
        if (FEntryArr[i])
            FCurrFile->Write(DumpArr[i]->GetData(), DumpArr[i]->GetSize());

    for (i = 0; i < FEntryCount; i++)
        if (DumpArr[i])
            delete DumpArr[i];

    delete DumpArr;
    delete FCurrFile;
    FCurrFile = 0;
}
