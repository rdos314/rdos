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
    TRdosLogThread(const char *path, int filecount, int filesize);
    TRdosLogThread();
    ~TRdosLogThread();

    void Setup(const char *path, int filecount, int filesize);
    void DefineLogLevel(int Level, const char *name);
    void SetLogLevel(int Level);
    int GetLogLevel();

    void StartLog();
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

class TRdosLog : public TThread
{
public:
    TRdosLog(TRdosLogThread *logdev, const char *cl);
    TRdosLog(const char *cl);
    ~TRdosLog();

    void Setup(const char *path, int filecount, int filesize);
    void DefineLogLevel(int Level, const char *name);
    void SetLogLevel(int Level);
    int GetLogLevel();
    void ShutDown();

    void Write(int level, const char *label, const char *msg);
    void printf(int level, const char *label, const char *msg, ...);

    TString GetClass();
    TRdosLogThread *GetLogger();

    void DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount);
    void DumpEvents();

protected:
    void Init();
    void CheckFileCount();
    void InitFiles();
    virtual void Execute();

    TRdosLogThread *FDev;
    TString FClass;

    int FEntryCount;
    TString **FEntryArr;

    TSection *FEventSection;
    TSignalDevice FDumpSignal;
    int FFileCount;
    int FNextPos;
    TString FLogPath;
    int FCurrId;
    TFile *FCurrFile;
};

#endif
