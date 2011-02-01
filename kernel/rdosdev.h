
#ifndef _RDOSDEV_H
#define _RDOSDEV_H

#ifdef __cplusplus
extern "C" {
#endif

#include "rdk.h"

int RdosIsValidOsGate(int gate);

int RdosAllocateGdt();
void RdosFreeGdt(int sel);

int RdosGetSelectorBaseSize(int sel, long *base, long *limit);
void RdosCreateDataSelector16(int sel, long base, long limit);
void RdosCreateDataSelector32(int sel, long base, long limit);
void RdosCreateCodeSelector16(int sel, long base, long limit);
void RdosCreateCodeSelector32(int sel, long base, long limit);
void RdosCreateConformSelector16(int sel, long base, long limit);
void RdosCreateConformSelector32(int sel, long base, long limit);
void RdosCreateCallGateSelector(int sel, void *dest, int count);
void RdosCreateIntGateSelector(int intnum, int dpl, void (*dest)());
void RdosCreateTrapGateSelector(int intnum, int dpl, void (*dest)());

 
/* 32-bit compact memory model (device-drivers) */

// check carry flag, and set eax=0 if set and eax=1 if clear
#define CarryToBool 0x73 4 0x33 0xC0 0xEB 5 0xB8 1 0 0 0

// check carry flag, and set ebx=0 if set and ebx=bx if clear
#define ValidateHandle 0x73 2 0x33 0xDB 0xF 0xB7 0xDB

// check carry flag, and set eax=0 if set
#define ValidateEax 0x73 2 0x33 0xC0

// check carry flag, and set ecx=0 if set
#define ValidateEcx 0x73 2 0x33 0xC9

// check carry flag, and set edx=0 if set
#define ValidateEdx 0x73 2 0x33 0xD2

// check carry flag, and set esi=0 if set
#define ValidateEsi 0x73 2 0x33 0xF6

// check carry flag, and set edi=0 if set
#define ValidateEdi 0x73 2 0x33 0xFF

#pragma aux RdosIsValidOsGate = \
    OsGate_is_valid_osgate  \
    CarryToBool \
    parm [eax] \
    value [eax];

#pragma aux RdosAllocateGdt = \
    OsGate_allocate_gdt  \
    "movzx ebx,bx" \
    value [ebx];

#pragma aux RdosFreeGdt = \
    OsGate_free_gdt  \
    parm [ebx];

#pragma aux RdosGetSelectorBaseSize = \
    OsGate_get_selector_base_size  \
    CarryToBool \
    "mov fs:[esi],edx" \
    "mov es:[edi],ecx" \
    parm [ebx] [fs esi] [es edi] \
    value [eax];

#pragma aux RdosCreateDataSelector16 = \
    OsGate_create_data_sel16  \
    parm [ebx] [edx] [ecx];

#pragma aux RdosCreateDataSelector32 = \
    OsGate_create_data_sel32  \
    parm [ebx] [edx] [ecx];

#pragma aux RdosCreateCodeSelector16 = \
    OsGate_create_code_sel16  \
    parm [ebx] [edx] [ecx];

#pragma aux RdosCreateCodeSelector32 = \
    OsGate_create_code_sel32  \
    parm [ebx] [edx] [ecx];

#pragma aux RdosCreateConformSelector16 = \
    OsGate_create_conform_sel16  \
    parm [ebx] [edx] [ecx];

#pragma aux RdosCreateConformSelector32 = \
    OsGate_create_conform_sel32  \
    parm [ebx] [edx] [ecx];

#pragma aux RdosCreateCallGateSelector = \
    "push ds" \
    "push ax" \
    "mov ax,cs" \
    "mov ds,ax" \
    OsGate_create_call_gate_sel32  \
    "pop ax" \
    "pop ds" \
    parm [ebx] [esi] [ecx];

#pragma aux RdosCreateCallGateSelector = \
    "push ds" \
    "push ax" \
    "mov ax,cs" \
    "mov ds,ax" \
    OsGate_create_call_gate_sel32  \
    "pop ax" \
    "pop ds" \
    parm [eax] [ebx] [esi];

#pragma aux RdosCreateTrapGateSelector = \
    "push ds" \
    "push ax" \
    "mov ax,cs" \
    "mov ds,ax" \
    OsGate_create_call_gate_sel32  \
    "pop ax" \
    "pop ds" \
    parm [eax] [ebx] [esi];

#ifdef __cplusplus
}
#endif

#endif
