
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

int RDOSAPI ServTest();
int RDOSAPI ServGetVfsHandle();
long long RDOSAPI ServGetVfsSectors(int handle);
int RDOSAPI ServCreateVfsReq(int handle);
void RDOSAPI ServCloseVfsReq(int handle);
int RDOSAPI ServReqVfsSectors(int handle, long long sector, int count);
void RDOSAPI ServStartVfsReq(int handle);

#ifdef __cplusplus
}
#endif

#ifdef __WATCOMC__
#include "owserv.h"
#endif

#endif
