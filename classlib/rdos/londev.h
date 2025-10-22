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
# londev.h
# Lon device class
#
########################################################################*/

#ifndef _LONDEV_H
#define _LONDEV_H

#include "device.h"
#include "sigdev.h"
#include "str.h"

struct TLonDebug
{
    long long Time;
    char Src;
    unsigned char Len;
    char Data[118];
};

struct TLonDomain
{
    unsigned char           Id[6];
    unsigned char           Subnet;
    unsigned char           NodeClone;          /* contains nonclone, node. Use LON_DOMAIN_* macros */
    unsigned char           InvalidIdLength;    /* use LON_DOMAIN_INVALID_* and LON_DOMAIN_ID_LENGTH_* macros */
    unsigned char           Key[6];
};

class TLonDevice : public TDevice
{
public:
    TLonDevice(int lonid);
    virtual ~TLonDevice();

    virtual void NotifyMsg(const char *msg, int size);
    virtual void SendMsg(const char *msg, int size, int timeout);
    virtual void SendMsgNoWait(const char *msg, int size);

    char *CreateExplicitMsg(char *Buffer,
                            unsigned char Domain,
                            unsigned char SubNet,
                            unsigned char Node,
                            unsigned char Service,
                            unsigned char Tag,
                            unsigned char Auth,
                            unsigned char RepeatTimer,
                            unsigned char Retries,
                            unsigned char TransmitTimer,
                            unsigned char Code,
                            unsigned char Size);

    char *CreateBroadcastMsg(char *Buffer,
                             unsigned char Code,
                             unsigned char Size);

    void UpdateDomainConfig(unsigned char Index, TLonDomain *Domain);
    void GoConfigured();

    void Reset();
    void SetResetLimit(int ResetLimit);

    int DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount);
    int DumpEvents();

    void DumpThread();

protected:
    virtual void NotifyStarted();
    virtual void NotifyLonReset();

    virtual void HandleIncomingNvMsg(const char *msg, int size);
    virtual void HandleIncomingExpMsg(const char *msg, int size);
    virtual void HandleCompletedNvMsg(const char *msg, int size);
    virtual void HandleCompletedExpMsg(unsigned char Tag, unsigned char CompletionCode);
    virtual void HandleResponseNvMsg(const char *msg, int size);
    virtual void HandleResponseExpMsg(const char *msg, int size);

    virtual void HandleReset(const char *msg, int size);
    virtual void HandleService(const char *msg, int size);
    virtual void HandleServiceHeld(const char *msg, int size);
    virtual void HandleIsiNack(const char *msg, int size);
    virtual void HandleIsiAck(const char *msg, int size);
    virtual void HandleIsiCmd(const char *msg, int size);

    virtual void HandlePingReceived();
    virtual void HandleNvIsBoundReceived(unsigned char index, unsigned char bound);
    virtual void HandleMtIsBoundReceived(unsigned char index, unsigned char bound);
    virtual void HandleGoUnconfiguredReceived();
    virtual void HandleGoConfiguredReceived();
    virtual void HandleAppSignatureReceived(short int AppSignature);
    virtual void HandleVersionReceived(unsigned char AppMajor, unsigned char AppMinor, unsigned char AppBuild,
                                       unsigned char CoreMajor, unsigned char CoreMinor, unsigned char CoreBuild);
    virtual void HandleEchoReceived(const char *msg);

    virtual void HandleNmSetNodeMode(const char *Msg, unsigned char Size);
    virtual void HandleNmNvFetch(const char *Msg, unsigned char Size);
    virtual void HandleNmReadMemory(const char *Msg, unsigned char Size);
    virtual void HandleNmWriteMemory(const char *Msg, unsigned char Size);
    virtual void HandleNmQuerySiData(const char *Msg, unsigned char Size);
    virtual void HandleNmWink();
    virtual void HandleIncomingMsg(  const char *Address,
                                     unsigned char Priority,
                                     unsigned char Service,
                                     unsigned char Auth,
                                     unsigned char Code,
                                     const char *Data,
                                     unsigned char Size);

    virtual void HandleNmQueryDomainResponse(const char *Msg, unsigned char Size);
    virtual void HandleNmQueryNvConfigResponse(const char *Msg, unsigned char Size);
    virtual void HandleNmQueryAddrResponse(const char *Msg, unsigned char Size);
    virtual void HandleNmReadMemoryResponse(const char *Msg, unsigned char Size);
    virtual void HandleNdQueryStatusResponse(const char *Msg, unsigned char Size);
    virtual void HandleNdQueryXcvrResponse(const char *Msg, unsigned char Size);
    virtual void HandleResponseMsg(  const char *Address,
                                     unsigned char Tag,
                                     unsigned char Code,
                                     const char *Data,
                                     unsigned char Size);

    virtual void Execute();
    void CheckFileCount();
    void InitFiles();

    int FNmPending;
    int FNdPending;

    int FLonHandle;
    int FLonId;

    int FDomainReq;
    int FGoConfiguredReq;
    
    TSection FSection;
    TSignalDevice FSignal;

    int FEntryCount;
    struct TLonDebug *FEntryArr;

    TSection FEventSection;
    int FCurrId;
    TFile *FCurrFile;
    int FFileCount;
    int FNextPos;
    bool FDumpRunning;
    bool FNewData;

    TString FLogPath;
    int FResetReq;
    int FResponseCounter;
    int FResetLimit;

    TSection FSendSection;
    TSignalDevice FSendSignal;
};

#endif

