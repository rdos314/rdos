
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

int RDOSAPI ServTest();
int RDOSAPI ServGetVfsHandle();
long long RDOSAPI ServGetVfsSectors(int handle);
int RDOSAPI ServIsVfsActive(int handle);
int RDOSAPI ServCreateVfsReq(int handle);
void RDOSAPI ServCloseVfsReq(int handle);
int RDOSAPI ServAddVfsSectors(int handle, long long sector, int count);
void RDOSAPI ServRemoveVfsSectors(int handle, int reqid);
char *RDOSAPI ServMapVfsReq(int handle, int reqid);
void RDOSAPI ServUnmapVfsReq(int handle, int reqid);
void RDOSAPI ServStartVfsReq(int handle);
int RDOSAPI ServIsVfsReqDone(int handle);
void RDOSAPI ServAddWaitForVfsReq(int waithandle, int handle, int id);

#ifdef __cplusplus
}
#endif

#ifdef __WATCOMC__
#include "owserv.h"
#endif

#endif
