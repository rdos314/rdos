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
    TRdosLogThread(const char *path, int filecount, int filesize, const char *ThreadName);
    TRdosLogThread(const char *path, int filecount, int filesize);
    TRdosLogThread();
    ~TRdosLogThread();

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
};

class TRdosLog
{
public:
    TRdosLog(TRdosLogThread *logdev, const char *cl);
    TRdosLog(const char *cl);
    ~TRdosLog();

    void Write(int level, const char *label, const char *msg);
    void printf(int level, const char *label, const char *msg, ...);

    TString GetClass();
    TRdosLogThread *GetLogger();

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
    ~TRdosDefaultLog();
};

class TRdosEventLog : public TRdosLog, public TThread
{
public:
    TRdosEventLog(const char *LogPath, int DumpFiles, int EntryCount, TRdosLogThread *logdev, const char *cl);
    TRdosEventLog(const char *LogPath, int DumpFiles, int EntryCount, const char *cl);
    ~TRdosEventLog();

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
