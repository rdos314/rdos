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
# serv.h
# RDOS server level interface
#
########################################################################*/

#ifndef _RDOS_SERV_H
#define _RDOS_SERV_H

#pragma pack( __push, 1 )

#define RDOSAPI

#include <stdarg.h>
#include "rds.h"

#pragma pack( __pop )


// API functions

#ifdef __cplusplus
extern "C" {
#endif

struct TShareHeader
{
    short int UsageCount;
    short int PageCount;
};

struct TShareHeader * RDOSAPI ServCreateShareBlock();
struct TShareHeader * RDOSAPI ServGrowShareBlock(struct TShareHeader *b);
struct TShareHeader * RDOSAPI ServForkShareBlock(struct TShareHeader *b);
void RDOSAPI ServFreeShareBlock(struct TShareHeader *b);

int RDOSAPI ServOpenVfsFile(int handle, void *info);
void RDOSAPI ServNotifyVfsFileReq(int FileHandle, long long Pos, int Size);
int RDOSAPI ServVfsFileReadReq(int FileHandle, int ReqIndex, long long Pos, long long *SectorBuf, int SectorCount);
int RDOSAPI ServVfsFileWriteReq(int FileHandle, int ReqIndex, long long Pos, long long *SectorBuf, int SectorCount);
void RDOSAPI ServUpdateVfsFileReq(int FileHandle, int ReqIndex, int Offset, int SectorCount);
void RDOSAPI ServDisableVfsFileReq(int FileHandle, int ReqIndex);
void RDOSAPI ServFreeVfsFileReq(int FileHandle, int ReqIndex);
void RDOSAPI ServUpdateVfsFile(int FileHandle);
void RDOSAPI ServCloseVfsFile(int FileHandle);

int RDOSAPI ServVfsFileReqCount(int handle);
int RDOSAPI ServVfsFileWaitCount(int handle);
int RDOSAPI ServVfsFileBlockCount(int handle);
int RDOSAPI ServVfsFilePhysCount(int handle);

void RDOSAPI ServStartVfsIoServer(int handle, void *buf);
void RDOSAPI ServWaitIoServer(int FileHandle, int CurrPos);
void RDOSAPI ServStopVfsIoServer(int handle);

int RDOSAPI ServLoadVfsPartition(int handle, int FsType, long long StartSector, long long SectorCount);
void RDOSAPI ServDisableVfsPartition(int handle);
void RDOSAPI ServStartVfsPartition(int handle);
void RDOSAPI ServStopVfsPartition(int handle);

void RDOSAPI ServInitPartitions(int handle);
void RDOSAPI ServPartitionsDone(int handle);

int RDOSAPI ServFormatVfsPartition(int handle);

void RDOSAPI ServSignal(int threadid);

int RDOSAPI ServTest();
int RDOSAPI ServGetVfsHandle();
int RDOSAPI ServGetVfsDisc(int handle);
int RDOSAPI ServGetVfsPart(int handle);
int RDOSAPI ServGetVfsPartType(int handle);
char RDOSAPI ServGetVfsPartDrive(int handle);
void RDOSAPI ServSetVfsStartSector(int handle, long long StartSector);
void RDOSAPI ServSetVfsSectors(int handle, long long SectorCount);
long long RDOSAPI ServGetVfsStartSector(int handle);
long long RDOSAPI ServGetVfsSectors(int handle);
int long RDOSAPI ServGetVfsBytesPerSector(int handle);
int RDOSAPI ServIsVfsActive(int handle);
int RDOSAPI ServIsVfsBusy(int handle);
void RDOSAPI ServWriteVfsSectors(int handle, long long sector, int count);
int RDOSAPI ServCreateVfsReq(int handle);
void RDOSAPI ServCloseVfsReq(int handle);
int RDOSAPI ServAddVfsSectors(int handle, long long sector, int count);
int RDOSAPI ServLockVfsSectors(int handle, long long sector, int count);
int RDOSAPI ServZeroVfsSectors(int handle, long long sector, int count);
void RDOSAPI ServRemoveVfsSectors(int handle, int reqid);
char *RDOSAPI ServMapVfsReq(int handle, int reqid);
void RDOSAPI ServUnmapVfsReq(int handle, int reqid);
void RDOSAPI ServStartVfsReq(int handle);
int RDOSAPI ServIsVfsReqDone(int handle);
void RDOSAPI ServAddWaitForVfsReq(int waithandle, int handle, int id);

void RDOSAPI ServNotifyVfsMsg(int Handle, const char *Msg);

void RDOSAPI ServCreateSslConnection(int index, long IP, int LocalPort, int RemotePort, int BufferSize);
void RDOSAPI ServDeleteSslConnection(int index);

void RDOSAPI ServCreateSslListen(int index, int Port, int BufferSize);
void RDOSAPI ServDeleteSslListen(int index);
void RDOSAPI ServAddSslListen(int index, int entry);

void RDOSAPI ServSslStart(int index, int handle);
void RDOSAPI ServSslStop(int index, int handle);

void  RDOSAPI ServSslInitStart(int index);
void  RDOSAPI ServSslInitDone(int index);
int  RDOSAPI ServSslGetReceiveSpace(int index);
void RDOSAPI ServSslAddReceiveBuf(int index, const char *buf, int size);
int RDOSAPI ServSslGetSendCount(int index);
int RDOSAPI ServSslGetSendBuf(int index, char *buf);
void RDOSAPI ServSslClearSendCount(int index, int count);
int RDOSAPI ServSslWaitForChange(int consel);

#ifdef __cplusplus
}
#endif

#ifdef __WATCOMC__
#include "owserv.h"
#endif

#endif
