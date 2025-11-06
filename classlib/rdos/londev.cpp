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
# londev.cpp
# Lon device class
#
########################################################################*/

#include <stdio.h>
#include <memory.h>
#include "rdos.h"
#include "path.h"
#include "direntry.h"
#include "londev.h"

#define LonNiNull           0x00
#define LonNiXOff           0x01        /* software flow control                    */
#define LonNiXOn            0x02
#define LonNiService        0x06        /* Uplink: Service pin has been pressed     */
                                        /* Downlink: to send a service pin message  */
#define LonNiAppInit        0x08        /* Downlink, APPINIT command                */
#define LonNiSiData         0x0A        /* Downlink, SIDATA command                 */
#define LonNiNvInit         0x0B        /* Downlink, NVINIT command                 */
#define LonNiServiceHeld    0x0B        /* Uplink, delayed service pin notification command */
#define LonNiNascentKey     0x0C        /* Downlink, set nascent key                        */
#define LonNiUsop           0x0D        /* Downlink, send an extended local command to Micro Server   */
#define LonNiComm           0x10        /* Data transfer to/from network (lower nibble is   */
                                        /* LonSmipQueue value)                              */
#define LonNiNetManagement  0x20        /* Local network management/diagnostics (lower      */
                                        /* nibble is LonSmipQueue value)                    */
#define LonNiPhase          0x40        /* Lower nibble contains phase reading.                                      */
#define LonNiReset          0x50        /* Uplink: node resets            */
                                        /* Downlink: ask node to reset    */
#define LonNiFlushComplete  0x60        /* Uplink                         */
#define LonNiFlushCancel    0x60        /* Downlink                       */
#define LonNiOnLine         0x70        /* Downlink: Ask node go online   */
#define LonNiOffLine        0x80        /* Downlink: Ask node go offline  */
#define LonNiFlush          0x90        /* Downlink                       */
#define LonNiFlushIgnore    0xA0        /* Downlink                       */
#define LonNiSleep          0xB0        /* Not supported by ShortStack Micro Server   */
#define LonIsiNack          0xBC        /* Uplink: ISI Nack in response to a downlink RPC */
#define LonIsiAck           0xBD        /* Uplink: ISI Ack in response to a downlink RPC */
#define LonIsiCmd           0xBE        /* Downlink: ISI Downlink RPC */
                                        /* Uplink: ISI Uplink RPC */
#define LonNiNv             0xC0        /* Special case for downlink NV updates and polls.
                                       Least significant 6 bits contain NV index. */

#define LonNiTxQueue              2     /* Transaction queue                        */
#define LonNiTxQueuePriority      3     /* Priority transaction queue               */
#define LonNiNonTxQueue           4     /* Non-transaction queue                    */
#define LonNiNonTxQueuePriority   5     /* Priority non-transaction queue           */
#define LonNiResponse             6     /* Response msg & completion event queue    */
#define LonNiIncoming             8     /* Received message queue                   */

#define LonNdQueryStatus                   0x51
#define LonNdProxy                         0x52
#define LonNdClearStatus                   0x53
#define LonNdQueryXcvr                     0x54
#define LonNdQueryStatusFlexDomain         0x56

    /* codes for network management commands */
#define LonNmExpanded                      0x60
#define LonNmQueryId                       0x61
#define LonNmRespondToQuery                0x62
#define LonNmUpdateDomain                  0x63
#define LonNmLeaveDomain                   0x64
#define LonNmUpdateKey                     0x65
#define LonNmUpdateAddr                    0x66
#define LonNmQueryAddr                     0x67
#define LonNmQueryNvConfig                 0x68
#define LonNmUpdateGroupAddr               0x69
#define LonNmQueryDomain                   0x6A
#define LonNmUpdateNvConfig                0x6B
#define LonNmSetNodeMode                   0x6C
#define LonNmReadMemory                    0x6D
#define LonNmWriteMemory                   0x6E
#define LonNmChecksumRecalculation         0x6F
#define LonNmWink                          0x70
#define LonNmInstall                       LonNmWink /* See <LonInstallCommand> */
#define LonNmAppCommand                    LonNmWink
#define LonNmMemoryRefresh                 0x71
#define LonNmQuerySiData                   0x72
#define LonNmQuerySnvt                     LonNmQuerySiData
#define LonNmNvFetch                       0x73
#define LonNmDeviceEscape                  0x7D
#define LonNmRouterEscape                  0x7E
#define LonNmServicePin                    0x7F

#define LonUsopPing                 0x01        /* Ping  */
#define LonUsopNvIsBound            0x02        /* Is Bound Nv   */
#define LonUsopMtIsBound            0x03        /* Is Bound Mt   */
#define LonUsopGoUcfg               0x04        /* Go Unconfigured   */
#define LonUsopGoCfg                0x05        /* Go Configured   */
#define LonUsopQueryAppSignature    0x06        /* Query App Signature  */
#define LonUsopVersion              0x07        /* Query Micro Server version details */
#define LonUsopEcho                 0x0A        /* Request Echo */

#define LonAddressUnassigned    0
#define LonAddressSubnetNode    1
#define LonAddressUniqueId      2
#define LonAddressBroadcast     3
#define LonAddressLocal         127

#define FALSE 0
#define TRUE    !FALSE

struct LonSendSubnetNode
{
    unsigned char               Type;           /* should be LonAddressSubnetNode for subnet/node addressing */
    unsigned char               DomainNode;     /* contains domain, node. See LON_SENDSN_DOMAIN_* and _NODE_* macros */
    unsigned char               RepeatRetry;    /* contains repeat, retry. See LON_SENDSN_REPEAT_* and _RETRY_* macros */
    unsigned char               RsvdTransmit;   /* contains transmit (top 4 bits are unused). See LON_SENDSN_TRANSMIT_TIMER_* macros */
    unsigned char               Subnet;         /* destination subnet number, 1..255    */
};

struct LonExplicitMessage
{
    unsigned char      Attributes_1;   /* contains msgType, serviceType, authenticated, tag. Use LON_EXPMSG_* macros */
    unsigned char      Attributes_2;   /* contains priority, path, completionCode, explicitAddressing, altPath, pool, response. Use LON_-_* macros */
    unsigned char      Length;         /* Length of message code and data to follow    */
                                       /* not including any explicit address field.    */
    unsigned char      Address[11];    /* Optional explicit addressing information   */
    unsigned char      Code;           /* Message code                                 */
    unsigned char      Data;
};

/*##########################################################################
#
#   Name       : StartLonDump
#
#   Purpose....: Start lon dump thread
#
##########################################################################*/
static void StartLonDump(void *ptr)
{
    ((TLonDevice *)ptr)->DumpThread();
}

/*##########################################################################
#
#   Name       : TLonDevice::TLonDevice
#
#   Purpose....: Constructor for TLonDevice
#
#   In params..: Height         requested font height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLonDevice::TLonDevice(int lonid)
  : FSection("LonDevice"),
    FEventSection("LonEvent"),
    FSendSection("LonSend")
{
    char str[80];

    FNmPending = FALSE;
    FNdPending = FALSE;
    FDomainReq = FALSE;
    FGoConfiguredReq = FALSE;

    FCurrFile = 0;
    FNextPos = 0;
    FEntryCount = 0;
    FFileCount = 0;
    FCurrId = 0;
    FDumpRunning = false;
    FNewData = false;

    FResponseCounter = 0;
    FResetLimit = 0;

    FLonId = lonid;
    FLonHandle = RdosOpenLonModule(lonid, 20, 10);

    if (FLonHandle)
    {
        sprintf(str, "Lon Handler #%d", lonid);
        Start(str, 0x6000);
    }
}

/*##########################################################################
#
#   Name       : TLonDevice::~TLonDevice
#
#   Purpose....: Destructor for TLonDevice
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLonDevice::~TLonDevice()
{
    if (FLonHandle)
    {
        Stop();

        while (IsRunning())
            RdosWaitMilli(25);

        RdosCloseLonModule(FLonHandle);
    }
}

/*##########################################################################
#
#   Name       : TLonDevice::SetResetLimit
#
#   Purpose....: Set number of unacked packets before RESET
#
##########################################################################*/
void TLonDevice::SetResetLimit(int ResetLimit)
{
    FResetLimit = ResetLimit;
}

/*##########################################################################
#
#   Name       : TLonDevice::Reset
#
#   Purpose....: Reset lon module
#
##########################################################################*/
void TLonDevice::Reset()
{
    FResetReq = TRUE;
}

/*##########################################################################
#
#   Name       : TLonDevice::UpdateDomainConfig
#
#   Purpose....: Update domain config
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::UpdateDomainConfig(unsigned char Index, TLonDomain *Domain)
{
    char Buf[40] = {0x20, 0x7F, 0xA, 0x11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x63};

    FSection.Enter();

    FSignal.Clear();
    FDomainReq = TRUE;

    Buf[16] = Index;
    memcpy(Buf + 17, Domain, sizeof(TLonDomain));
    SendMsgNoWait(Buf, 17 + sizeof(TLonDomain));

    FSignal.WaitTimeout(10000);

    FDomainReq = FALSE;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TLonDevice::GoConfigured
#
#   Purpose....: Go configured
#
##########################################################################*/
void TLonDevice::GoConfigured()
{
    char Buf[] = {0xd, 5, 0};

    FSection.Enter();

    FSignal.Clear();
    FGoConfiguredReq = TRUE;

    SendMsgNoWait(Buf, 3);

    FSignal.WaitTimeout(10000);

    FGoConfiguredReq = FALSE;

    FSection.Leave();
}

/*##########################################################################
#
#   Name       : TLonDevice::SendMsg
#
#   Purpose....: Send a message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::SendMsg(const char *msg, int size, int timeout)
{
    int dumpsize;

    if (FLonHandle)
    {
        FSendSection.Enter();
        FSendSignal.Clear();
        FResponseCounter++;
        RdosSendLonModuleMsg(FLonHandle, msg, size);
        FSendSignal.WaitTimeout(timeout);
        FSendSection.Leave();
    }

    if (FFileCount && FEntryCount)
    {
        FEventSection.Enter();

        FNewData = true;

        if (size > 118)
            dumpsize = 118;
        else
            dumpsize = size;

        FEntryArr[FNextPos].Time = RdosGetLongTime();
        FEntryArr[FNextPos].Src = 'T';
        FEntryArr[FNextPos].Len = (unsigned char)size;
        memcpy(FEntryArr[FNextPos].Data, msg, dumpsize);

        FNextPos++;
        if (FNextPos >= FEntryCount)
            FNextPos = 0;

        FEventSection.Leave();
    }
}

/*##########################################################################
#
#   Name       : TLonDevice::SendMsgNoWait
#
#   Purpose....: Send a message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::SendMsgNoWait(const char *msg, int size)
{
    int dumpsize;

    if (FLonHandle)
        RdosSendLonModuleMsg(FLonHandle, msg, size);

    if (FFileCount && FEntryCount)
    {
        FEventSection.Enter();

        FNewData = true;

        if (size > 118)
            dumpsize = 118;
        else
            dumpsize = size;

        FEntryArr[FNextPos].Time = RdosGetLongTime();
        FEntryArr[FNextPos].Src = 'T';
        FEntryArr[FNextPos].Len = (unsigned char)size;
        memcpy(FEntryArr[FNextPos].Data, msg, dumpsize);

        FNextPos++;
        if (FNextPos >= FEntryCount)
            FNextPos = 0;

        FEventSection.Leave();
    }
}

/*##########################################################################
#
#   Name       : TLonDevice::CreateExplicitMsg
#
#   Purpose....: Create an explicit message
#
#   In params..: Buffer     Message buffer
#                Domain     Lon domain
#                SubNet     Destination subnet
#                Node       Destination node
#                Service    Service field
#                Tag        Tag field
#                Auth       Authentication field
#                RepeatTimer
#                Retries
#                TransmitTimer
#                Code       Lon message code
#                Size       Size of data
#   Returns....: Address to data buffer
#
##########################################################################*/
char *TLonDevice::CreateExplicitMsg(char *Buffer,
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
                                    unsigned char Size)
{
    LonExplicitMessage *expl = (LonExplicitMessage *)&Buffer[1];
    LonSendSubnetNode *dest = (LonSendSubnetNode *)expl->Address;

    Buffer[0] = LonNiComm | LonNiNonTxQueue;
    memset(expl->Address, 0, 11);

    expl->Attributes_1 = 0;
    expl->Attributes_1 |= (Service << 5) & 0x60;
    expl->Attributes_1 |= Tag & 0xF;
    expl->Attributes_1 |= (Auth << 4) & 0x10;

    expl->Attributes_2 = 8;

    dest->Type = LonAddressSubnetNode;
    dest->Subnet = SubNet;
    dest->DomainNode = Node & 0x7F;
    dest->DomainNode |= (Domain << 7) & 0x80;
    dest->RepeatRetry = Retries & 0xF;
    dest->RepeatRetry |= (RepeatTimer << 4) & 0xF0;
    dest->RsvdTransmit = TransmitTimer & 0xF;

    expl->Code = Code;
    expl->Length = Size;

    return (char *)&expl->Data;
}

/*##########################################################################
#
#   Name       : TLonDevice::CreateBroadcastMsg
#
#   Purpose....: Create a broadcast message
#
#   In params..: Buffer     Message buffer
#                Service    Service field
#                Tag        Tag field
#                Auth       Authentication field
#                RepeatTimer
#                Retries
#                TransmitTimer
#                Code       Lon message code
#                Size       Size of data
#   Returns....: Address to data buffer
#
##########################################################################*/
char *TLonDevice::CreateBroadcastMsg(char *Buffer,
                                    unsigned char Code,
                                    unsigned char Size)
{
    LonExplicitMessage *expl = (LonExplicitMessage *)&Buffer[1];

    Buffer[0] = LonNiComm | LonNiNonTxQueue;
    memset(expl->Address, 0, 11);

    expl->Attributes_1 = 0x4F;
    expl->Attributes_2 = 8;

    expl->Address[0] = 3;
    expl->Address[1] = 0x80;
    expl->Address[2] = 4;
    expl->Address[3] = 6;
    expl->Address[4] = 0;
    expl->Address[5] = 0;
    expl->Address[6] = 0;
    expl->Address[7] = 0;
    expl->Address[8] = 0;
    expl->Address[9] = 0;
    expl->Address[10] = 0;

    expl->Code = Code;
    expl->Length = Size;

    return (char *)&expl->Data;
}

/*##########################################################################
#
#   Name       : TLonDevice::NotifyStarted
#
#   Purpose....: Notify that lon handler has started
#
##########################################################################*/
void TLonDevice::NotifyStarted()
{
}

/*##########################################################################
#
#   Name       : TLonDevice::NotifyLonReset
#
#   Purpose....: Notify lon RESET
#
##########################################################################*/
void TLonDevice::NotifyLonReset()
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleReset
#
#   Purpose....: Handle RESET message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleReset(const char *msg, int size)
{
    FNmPending = FALSE;
    FNdPending = FALSE;
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleService
#
#   Purpose....: Handle service PIN message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleService(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleServiceHeld
#
#   Purpose....: Handle service PIN held message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleServiceHeld(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleIncomingNvMsg
#
#   Purpose....: Handle incoming NV message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleIncomingNvMsg(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNmSetNodeMode
#
#   Purpose....: Handle Nm Set Node Mode
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNmSetNodeMode(const char *Msg, unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNmNvFetch
#
#   Purpose....: Handle Nm Nv fetch
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNmNvFetch(const char *Msg, unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNmReadMemory
#
#   Purpose....: Handle Nm Read Memory
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNmReadMemory(const char *Msg, unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNmWriteMemory
#
#   Purpose....: Handle Nm Write Memory
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNmWriteMemory(const char *Msg, unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNmQuerySiData
#
#   Purpose....: Handle Nm Query si Data
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNmQuerySiData(const char *Msg, unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNmWink
#
#   Purpose....: Handle Nm Wink
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNmWink()
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleIncomingMsg
#
#   Purpose....: Handle incoming message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleIncomingMsg(  const char *Address,
                                     unsigned char Priority,
                                     unsigned char Service,
                                     unsigned char Auth,
                                     unsigned char Code,
                                     const char *Data,
                                     unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleIncomingExpMsg
#
#   Purpose....: Handle incoming explicit message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleIncomingExpMsg(const char *msg, int size)
{
    LonExplicitMessage *Expl = (LonExplicitMessage*)(msg + 1);
    unsigned char Priority = (Expl->Attributes_2 & 0x80) >> 7;
    unsigned char Service = (Expl->Attributes_1 & 0x60) >> 5;
    unsigned char Auth = (Expl->Attributes_1 & 0x10) >> 4;
    unsigned char Len = Expl->Length - 1;
    const char *Data = (const char *)&Expl->Data;

    switch (Expl->Code)
    {
        case LonNmSetNodeMode:
            HandleNmSetNodeMode(Data, Len);
            break;

        case LonNmNvFetch:
            HandleNmNvFetch(Data, Len);
            break;

        case LonNmReadMemory:
            HandleNmReadMemory(Data, Len);
            break;

        case LonNmWriteMemory:
            HandleNmWriteMemory(Data, Len);
            break;

        case LonNmQuerySiData:
            HandleNmQuerySiData(Data, Len);
            break;

        case LonNmWink:
            HandleNmWink();
            break;

        default:
            HandleIncomingMsg(  (const char *)Expl->Address,
                                Priority,
                                Service,
                                Auth,
                                Expl->Code,
                                Data,
                                Len);
            break;
    }
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleCompletedNvMsg
#
#   Purpose....: Handle completed NV message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleCompletedNvMsg(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleCompletedExpMsg
#
#   Purpose....: Handle completed explicit message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleCompletedExpMsg(unsigned char Tag, unsigned char CompletionCode)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleResponseNvMsg
#
#   Purpose....: Handle response NV message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleResponseNvMsg(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNmQueryDomainResponse
#
#   Purpose....: Handle Nm query domain response
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNmQueryDomainResponse(const char *Msg, unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNmQueryNvConfigResponse
#
#   Purpose....: Handle Nm query Nv config
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNmQueryNvConfigResponse(const char *Msg, unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNmQueryAddrResponse
#
#   Purpose....: Handle Nm query address response
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNmQueryAddrResponse(const char *Msg, unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNmReadMemoryResponse
#
#   Purpose....: Handle Nm read memory response
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNmReadMemoryResponse(const char *Msg, unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNdQueryStatusResponse
#
#   Purpose....: Handle Nd query status response
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNdQueryStatusResponse(const char *Msg, unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNdQueryXcvrResponse
#
#   Purpose....: Handle Nd query transceiver response
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleNdQueryXcvrResponse(const char *Msg, unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleResponseMsg
#
#   Purpose....: Handle response message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleResponseMsg(  const char *Address,
                                     unsigned char Tag,
                                     unsigned char Code,
                                     const char *Data,
                                     unsigned char Size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleResponseExpMsg
#
#   Purpose....: Handle response explicit message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleResponseExpMsg(const char *msg, int size)
{
    LonExplicitMessage *Expl = (LonExplicitMessage*)(msg + 1);
    unsigned char Tag = Expl->Attributes_1 & 0xF;
    unsigned char Len = Expl->Length - 1;
    const char *Data = (const char *)&Expl->Data;

    if (Tag == 0xF)
    {
        if (FNmPending)
        {
            switch ((Expl->Code & 0x1F) | 0x60)
            {
                case LonNmQueryDomain:
                    HandleNmQueryDomainResponse(Data, Len);
                    break;

                case LonNmQueryNvConfig:
                    HandleNmQueryNvConfigResponse(Data, Len);
                    break;

                case LonNmQueryAddr:
                    HandleNmQueryAddrResponse(Data, Len);
                    break;

                case LonNmReadMemory:
                    HandleNmReadMemoryResponse(Data, Len);
                    break;

                default:
                    break;
            }
        }

        if (FNdPending)
        {
            switch ((Expl->Code & 0xF) | 0x50)
            {
                case LonNdQueryStatus:
                    HandleNdQueryStatusResponse(Data, Len);
                    break;

                case LonNdQueryXcvr:
                    HandleNdQueryXcvrResponse(Data, Len);
                    break;

                default:
                    break;
            }
        }

        if (FDomainReq)
        {
            FDomainReq = FALSE;
            FSignal.Signal();
        }

        FNmPending = FALSE;
        FNdPending = FALSE;
    }
    else
    {
        HandleResponseMsg(  (const char *)Expl->Address,
                            Tag,
                            Expl->Code,
                            Data,
                            Len);
    }
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleIsiNack
#
#   Purpose....: Handle ISI NACK message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleIsiNack(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleIsiAck
#
#   Purpose....: Handle ISI ACK message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleIsiAck(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleIsiCmd
#
#   Purpose....: Handle ISI CMD message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::HandleIsiCmd(const char *msg, int size)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandlePingReceived
#
#  The ShortStack Micro Server has sent a ping command.
#
#  Remarks:
#  The ShortStack Micro Server has sent a ping command. This command can be
#  a response to the ping command sent by the host application
#  to the Micro Server. This callback is part of the optional
#  utility API.
#
##########################################################################*/
void TLonDevice::HandlePingReceived()
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleNvIsBoundReceived
#
#   Callback following a call to <LonNvIsBound>.
#
#   Parameters:
#    index - index of the network variable
#    bound - indicates whether the network variable is bound
#
#  Remarks:
#  The Micro Server has responded to the <LonNvIsBound> request. The boolean
#  variable *bound* tells whether the network variable identified by index
#  is bound. This callback is part of the optional
#  utility API.
#
##########################################################################*/
void TLonDevice::HandleNvIsBoundReceived(unsigned char index, unsigned char bound)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleMtIsBoundReceived
#
#  Callback following a call to <LonMtIsBound>.
#
#  Parameters:
#   index - index of the message tag
#   bound - indicates whether the message tag is bound
#
#  Remarks:
#  The Micro Server has responded to the <LonMtIsBound> request. The boolean
#  variable *bound* tells whether the message tag identified by index
#  is bound. This callback is part of the optional
#  utility API.
#
##########################################################################*/
void TLonDevice::HandleMtIsBoundReceived(unsigned char index, unsigned char bound)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleGoUnconfiguredReceived
#
#   Callback following a call to <LonGoUnconfigured>.
#
#   Remarks:
#   The Micro Server has responded to the <LonGoUnconfigured> request.
#   If the Micro Server was in a configured state before the <LonGoUnconfigured>
#   request was sent, it will reset after going to the unconfigured state.
#   This callback is part of the optional utility API.
#
##########################################################################*/
void TLonDevice::HandleGoUnconfiguredReceived()
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleGoConfiguredReceived
#
#   Callback following a call to <LonGoConfigured>.
#
#   Remarks:
#   The Micro Server has responded to the <LonGoConfigured> request.
#   The Micro Server will not reset after going into the configured state unless
#   some serious error, such as an application checksum error, is detected in the
#   process.
#   This callback is part of the optional utility API.
#
##########################################################################*/
void TLonDevice::HandleGoConfiguredReceived()
{
    if (FGoConfiguredReq)
    {
        FGoConfiguredReq = FALSE;
        FSignal.Signal();
    }

    FNmPending = FALSE;
    FNdPending = FALSE;
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleAppSignatureReceived
#
#   Callback following a call to <LonQueryAppSignature>.
#
#   Parameter:
#   appSignature - Micro Server's copy of the host's application signature
#
#   Remarks:
#   The Micro Server has responded to the <LonQueryAppSignature> request.
#   If the *bInvalidate* flag was set to TRUE in the <LonQueryAppSignature>
#   request, the Micro Server has already invalidated the signature by the time
#   this callback is called.
#   This callback is part of the optional utility API.
#
##########################################################################*/
void TLonDevice::HandleAppSignatureReceived(short int AppSignature)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleVersionReceived
#
#   Callback following a call to <LonQueryVersion>.
#
#   Parameters:
#    appMajor - the major version number for the Micro Server application, 0..255
#    appMinor - the minor version number for the Micro Server application, 0..255
#    appBuild - the build number for the Micro Server application, 0..255
#    coreMajor - the major version number for the Micro Server core library, 0..255
#    coreMinor - the minor version number for the Micro Server core library, 0..255
#    coreBuild - the build number for the Micro Server core library, 0..255
#
#   Remarks:
#   The Micro Server has responded to a <LonQueryVersion> request.
#   This callback is part of the optional utility API.
#
##########################################################################*/
void TLonDevice::HandleVersionReceived(unsigned char AppMajor, unsigned char AppMinor, unsigned char AppBuild,
                                       unsigned char CoreMajor, unsigned char CoreMinor, unsigned char CoreBuild)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::HandleEchoReceived
#
#   Callback following a call to <LonRequestEcho>.
#
#   Parameters:
#   LON_ECHO_SIZE payload bytes, as sent through <LonRequestEcho>, but modified by the
#    Micro Server by adding one to each byte, using an unsigned 8-bit addition without
#   overflow detection.
#
#   Remarks:
#   The Micro Server has responded to a <LonRequestEcho> request. The host application
#   should now confirm that the echoed data matches the expectations; mismatching data
#   can indicate an incorrect host application or link layer driver, or permanent or
#   transient link layer errors. These link layer errors could, for example, be
#   introduced by incorrect line termination, excessive coupling or cross-talk, or by
#   excessive or out-of-sync link layer bit rates.
#   This callback is part of the optional utility API.
#
##########################################################################*/
void TLonDevice::HandleEchoReceived(const char *msg)
{
}

/*##########################################################################
#
#   Name       : TLonDevice::NotifyMsg
#
#   Purpose....: Notify message
#
#   In params..: msg        Lon message
#   Out params.: size       Size of lon message
#   Returns....: *
#
##########################################################################*/
void TLonDevice::NotifyMsg(const char *msg, int size)
{
    LonExplicitMessage *Expl = (LonExplicitMessage*)(msg + 1);
    unsigned char Tag;
    unsigned char CompletionCode;
    unsigned char NvMsg;
    short int appSignature;

    switch (msg[0])
    {
        case LonNiComm | LonNiIncoming:
            NvMsg = (Expl->Attributes_1 & 0x80) >> 7;
            if (NvMsg)
                HandleIncomingNvMsg(msg, size);
            else
                HandleIncomingExpMsg(msg, size);
            break;

        case LonNiComm | LonNiResponse:
            NvMsg = (Expl->Attributes_1 & 0x80) >> 7;
            CompletionCode = (Expl->Attributes_2 & 0x30) >> 6;

            FSendSignal.Signal();

            if (CompletionCode)
            {
                if (NvMsg)
                    HandleCompletedNvMsg(msg, size);
                else
                {
                    Tag = Expl->Attributes_1 & 0xF;
                    HandleCompletedExpMsg(Tag, CompletionCode);
                }
            }
            else
            {
                if (NvMsg)
                    HandleResponseNvMsg(msg, size);
                else
                    HandleResponseExpMsg(msg, size);
            }
            break;

        case LonNiReset:
            HandleReset(msg, size);
            break;

        case LonNiService:
            HandleService(msg, size);
            break;

        case LonNiServiceHeld:
            HandleServiceHeld(msg, size);
            break;

        case LonNiUsop:
            switch (msg[1])
            {
                case LonUsopPing:
                    HandlePingReceived();
                    break;

                case LonUsopNvIsBound:
                    HandleNvIsBoundReceived(msg[2], msg[3]);
                    break;

                case LonUsopMtIsBound:
                    HandleMtIsBoundReceived(msg[2], msg[3]);
                    break;

                case LonUsopGoUcfg:
                    HandleGoUnconfiguredReceived();
                    break;

                case LonUsopGoCfg:
                    HandleGoConfiguredReceived();
                    break;

                case LonUsopQueryAppSignature:
                    appSignature = RdosSwapShort((short int)msg[1]);
                    HandleAppSignatureReceived(appSignature);
                    break;

                case LonUsopVersion:
                    HandleVersionReceived(msg[2], msg[3], msg[4],
                                          msg[5], msg[6], msg[7]);
                    break;

                case LonUsopEcho:
                    HandleEchoReceived(&msg[2]);
                    break;
            }
            break;

        case LonIsiNack:
            HandleIsiNack(msg, size);
            break;

        case LonIsiAck:
            HandleIsiAck(msg, size);
            break;

        case LonIsiCmd:
            HandleIsiCmd(msg, size);
            break;
    }
}

/*##########################################################################
#
#   Name       : TLonDevice::CheckFileCount
#
#   Purpose....: Check file count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLonDevice::CheckFileCount()
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
        if (strstr(file, ".sdd"))
        {
            if (entry.GetFileSize() == 0)
            {
                path = entry.GetPathName();
                if (path.IsFile())
                    path.DeleteFile();
            }
            else
            {
                count++;
                if (count > FFileCount)
                {
                    path = entry.GetPathName();
                    if (path.IsFile())
                        path.DeleteFile();
                }
            }
        }
            
        ok = FileList.GotoPrev();
    }    

    delete file;
}

/*##########################################################################
#
#   Name       : TLonDevice::InitFiles
#
#   Purpose....: Init files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLonDevice::InitFiles()
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

    CheckFileCount();        

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
        if (strstr(file, ".sdd"))
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
    str.printf("%s/%d.sdd", FLogPath.GetData(), FCurrId);
    FCurrFile = new TFile(str.GetData(), 0);
}

/*##########################################################################
#
#   Name       : TLonDevice::DefineEventDebug
#
#   Purpose....: Define event debug
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TLonDevice::DefineEventDebug(const char *LogPath, int DumpFiles, int EntryCount)
{
    int i;

    FLogPath = LogPath;
    FFileCount = DumpFiles;

    TPathName path(FLogPath);

    if (path.MakeDir())
    {        
        CheckFileCount();

        FEntryCount = EntryCount;
        FEntryArr = new struct TLonDebug[EntryCount];

        // initialize cache to empty
        for (i = 0; i < EntryCount; i++) 
        {
            FEntryArr[i].Time = 0; 
            FEntryArr[i].Src = 0;
            FEntryArr[i].Len = 0;
        }

        return TRUE;
    }
    else
    {
        FFileCount = 0;
        return FALSE;
    }
}

/*##########################################################################
#
#   Name       : TLonDevice::DumpEvents
#
#   Purpose....: Dump buffer to file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TLonDevice::DumpEvents()
{
    if (FFileCount && !FDumpRunning && FNewData)
    {
        RdosCreateThread(StartLonDump, "Lon Dump", this, 0x8000);
        return TRUE;
    }
    else
        return FALSE;
}

/*##################  TLonDevice::DumpThread  #######################
*   Purpose....: Dump thread                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TLonDevice::DumpThread()
{
    int pos;
    struct TLonDebug *DumpArr;
    TPathName path(FLogPath);

    FDumpRunning = true;

    RdosWaitMilli(100);

    if (path.MakeDir())
    {        
        InitFiles();

        DumpArr = new struct TLonDebug[FEntryCount];

        FEventSection.Enter();

        FNewData = false;

        pos = FNextPos;

        for (int i = 0; i < FEntryCount; i++)
            DumpArr[i] = FEntryArr[i];

        for (int i = 0; i < pos; i++)
            if (FEntryArr[i].Time)
                FCurrFile->Write(&DumpArr[i], sizeof(struct TLonDebug));

        FNewData = false;
        
        FEventSection.Leave();

        for (int i = 0; i < FEntryCount; i++)
            DumpArr[i] = FEntryArr[i];
        

        delete DumpArr;
        delete FCurrFile;
        FCurrFile = 0;
    }

    FDumpRunning = false;
}

/*##########################################################################
#
#   Name       : TLonDevice::Execute
#
#   Purpose....: Message handler loop
#
##########################################################################*/
void TLonDevice::Execute()
{
    char *buf;
    int size;
    int dumpsize;
    int wait = RdosCreateWait();

    FResetReq = FALSE;

    buf = new char[255];

    RdosAddWaitForLonModule(wait, FLonHandle, (int)this);

    while (FInstalled && !IsOpen())
        RdosWaitMilli(100);

    if (IsOpen())
        NotifyStarted();

    while (FInstalled)
    {
        if (IsOpen())
        {
            if (FResetLimit)
            {
                if (FResetLimit < FResponseCounter)
                {
                    FResetReq = TRUE;
                    FResponseCounter = 0;
                }
            }

            if (FResetReq)
            {
                NotifyLonReset();
                RdosCloseLonModule(FLonHandle);
                FLonHandle = 0;
                RdosCloseWait(wait);
                RdosResetLonModule(FLonId);

                RdosWaitMilli(15000);

                FLonHandle = RdosOpenLonModule(FLonId, 20, 10);
                wait = RdosCreateWait();
                RdosAddWaitForLonModule(wait, FLonHandle, (int)this);

                FResetReq = FALSE;
            }

            RdosWaitTimeout(wait, 1000);

            if (RdosHasLonModuleMsg(FLonHandle))
            {
                FResponseCounter = 0;

                size = RdosReceiveLonModuleMsg(FLonHandle, buf);
                NotifyMsg(buf, size);

                if (FFileCount && FEntryCount)
                {
                    FEventSection.Enter();

                    FNewData = true;

                    if (size > 118)
                        dumpsize = 118;
                    else
                        dumpsize = size;

                    FEntryArr[FNextPos].Time = RdosGetLongTime();
                    FEntryArr[FNextPos].Src = 'R';
                    FEntryArr[FNextPos].Len = (unsigned char)size;
                    memcpy(FEntryArr[FNextPos].Data, buf, dumpsize);

                    FNextPos++;
                    if (FNextPos >= FEntryCount)
                        FNextPos = 0;

                    FEventSection.Leave();
                }
            }
        }
        else
            RdosWaitMilli(100);
    }

    RdosCloseWait(wait);
    delete buf;
}
