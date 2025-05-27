
#ifndef _RDOS_ACPI_SERV_H
#define _RDOS_ACPI_SERV_H

#pragma pack( __push, 1 )

#define RDOSAPI

#include <stdarg.h>
#include "rdacpi.h"

#pragma pack( __pop )


// API functions

#ifdef __cplusplus
extern "C" {
#endif

long long RDOSAPI ServUacpiGetAcpi();
void *RDOSAPI ServUacpiMap(long long phys, int size);
void RDOSAPI ServUacpiUnmap(void *base, int size);
void RDOSAPI ServUacpiEnableIo(int base, int size);
char RDOSAPI ServUacpiReadPciByte(int dev);
short RDOSAPI ServUacpiReadPciWord(int dev);
int RDOSAPI ServUacpiReadPciDword(int dev);
void RDOSAPI ServUacpiWritePciByte(int dev, char val);
void RDOSAPI ServUacpiWritePciWord(int dev, short val);
void RDOSAPI ServUacpiWritePciDword(int dev, int val);
void RDOSAPI ServUacpiStartPci();

#ifdef __cplusplus
}
#endif

#ifdef __WATCOMC__
#include "owacpi.h"
#endif

#endif
