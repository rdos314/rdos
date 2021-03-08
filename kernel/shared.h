
#ifndef _RDOS_SHARED_H
#define _RDOS_SHARED_H

#pragma pack( __push, 1 )

#define RDOSAPI

#include <stdarg.h>
#include "rds.h"

#pragma pack( __pop )


// API functions

#ifdef __cplusplus
extern "C" {
#endif

int RDOSAPI SharedTest();

#ifdef __cplusplus
}
#endif

#ifdef __WATCOMC__
#include "owshared.h"
#endif

#endif
