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
    virtual void SendMsg(const char *msg, int size);

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
    int GetNextDumpFile();
    void DumpOnce();

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

    TSection FDumpSection;
    TSection FEventSection;
    TSignalDevice FDumpSignal;
    int FDumpFiles;
    int FWriteDump;
    int FDumpStarted;
    int FNextPos;
    TString FLogPath;
    int FResetReq;
    int FResponseCounter;
    int FResetLimit;
};

#endif

