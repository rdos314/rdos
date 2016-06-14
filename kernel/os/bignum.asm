;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage in embedded systems. For information on
; usage in commercial embedded systems, contact embedded@rdos.net
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;
; The author of this program may be contacted at leif@rdos.net
;
; BIGNUM.ASM
; Big number support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.inc
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc

BN_FLAG_NEGATIVE = 1

bignum_handle_seg          STRUC

bn_base         handle_header <>

bn_data         DD ?
bn_size         DW ?
bn_flags        DW ?

bignum_handle_seg          ENDS

.386p

data    SEGMENT byte public 'DATA'

filler      DB ?

data    ENDS

code    SEGMENT byte public use32 'CODE'
    
    assume cs:code
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RecreateBuf
;
;           DESCRIPTION:    Recreate buffer
;
;           PARAMETERS:     DS:EBX      Handle data
;                           CX          New buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecreateBuf     PROC near
    cmp cx,ds:[ebx].bn_size
    je rbDone
;
    push eax
    push ecx
    push edx
;    
    mov ax,ds:[ebx].bn_size
    or ax,ax
    jz rbCreate
;
    mov edx,ds:[ebx].bn_data
    FreeLinear

rbCreate:
    mov ds:[ebx].bn_size,cx
;    
    or cx,cx
    jz rbCreated
;    
    movzx eax,cx
    AllocateSmallLinear
    mov ds:[ebx].bn_data,edx

rbCreated:
    pop edx
    pop ecx
    pop eax

rbDone:    
    ret
RecreateBuf ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateBigNum
;
;           DESCRIPTION:    Create big number
;
;           RETURNS:        BX          Big number handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_bignum_name    DB 'Create Big Number',0

create_bignum     PROC far
    push ds
    push es
    push eax
    push cx
;
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_size,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
    mov bx,[ebx].hh_handle
    clc
;
    pop cx
    pop eax
    pop es
    pop ds
    ret
create_bignum     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DeleteBigNum
;
;           DESCRIPTION:    Delete big num
;
;           PARAMETERS:     BX          Big num handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_bignum_name    DB 'Delete Big Number',0

delete_bignum     PROC far
    push ds
    push ebx
    push ecx
    push edx
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc cbnDone
;
    movzx ecx,ds:[ebx].bn_size
    or ecx,ecx
    jz cbnFree
;
    mov edx,ds:[ebx].bn_data
    FreeLinear    

cbnFree:    
    FreeHandle
    clc

cbnDone:
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
delete_bignum     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LoadBigNum
;
;           DESCRIPTION:    Load big num
;
;           PARAMETERS:     BX          Big num handle
;                           EDX:EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_bignum64_name    DB 'Load 64-bit Big Number',0

load_bignum64     PROC far
    push ds
    push es
    push ebx
    push ecx
    push edi
;
    push ax
    mov ax,flat_sel
    mov es,ax    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    pop ax
    jc lbn64Done
;
    test edx,80000000h
    jz lbn64Pos

lbn64Neg:
    not eax
    not edx
    add eax,1
    adc edx,0
    mov ds:[ebx].bn_flags,BN_FLAG_NEGATIVE
    jmp lbn64SignOk

lbn64Pos:    
    mov ds:[ebx].bn_flags,0

lbn64SignOk:
    or edx,edx
    jz lbn64Small

lbn64Big:
    mov cx,8
    call RecreateBuf
;
    mov edi,ds:[ebx].bn_data
    stosd
    mov eax,edx
    stosd
    clc   
    jmp lbn64Done

lbn64Small:
    or eax,eax
    jz ln64Zero
;    
    mov cx,4
    call RecreateBuf
;
    mov edi,ds:[ebx].bn_data
    stosd
    clc   
    jmp lbn64Done

ln64Zero:
    xor cx,cx
    call RecreateBuf

lbn64Done: 
    pop edi
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
load_bignum64     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    Delete syslog handle
;
;           PARAMETERS:     BX          Syslog handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle     PROC far
    push ds
    push ebx
    push ecx
    push edx
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc dbnDone
;
    movzx ecx,ds:[ebx].bn_size
    or ecx,ecx
    jz dbnFree
;
    mov edx,ds:[ebx].bn_data
    FreeLinear    

dbnFree:       
    FreeHandle
    clc

dbnDone:
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
delete_handle     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov ax,BIGNUM_HANDLE
    mov edi,OFFSET delete_handle
    RegisterHandle
;
    mov esi,OFFSET create_bignum
    mov edi,OFFSET create_bignum_name
    xor dx,dx
    mov ax,create_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET delete_bignum
    mov edi,OFFSET delete_bignum_name
    xor dx,dx
    mov ax,delete_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET load_bignum64
    mov edi,OFFSET load_bignum64_name
    xor dx,dx
    mov ax,load_bignum64_nr
    RegisterBimodalUserGate
;
    ret
init    ENDP
    

code    ENDS

    END init
