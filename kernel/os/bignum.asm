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
bn_count        DW ?
bn_flags        DW ?

bignum_handle_seg          ENDS

mul_struc       STRUC

mul_in_count1    DD ?
mul_in_data1     DD ?
mul_in_count2    DD ?
mul_in_data2     DD ?
mul_out_count    DD ?
mul_out_data     DD ?

mul_struc       ENDS

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
;                           CX          New entry count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecreateBuf     PROC near
    cmp cx,ds:[ebx].bn_count
    je rbDone
;
    push eax
    push ecx
    push edx
;    
    mov ax,ds:[ebx].bn_count
    or ax,ax
    jz rbCreate
;
    mov edx,ds:[ebx].bn_data
    FreeLinear

rbCreate:
    mov ds:[ebx].bn_count,cx
;    
    or cx,cx
    jz rbCreated
;    
    movzx eax,cx
    shl eax,2
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
;           NAME:           CopyBuf
;
;           DESCRIPTION:    Copy buffer
;
;           PARAMETERS:     DS:EBX      Handle data
;                           DX          Buffer count
;                           ES:ESI      Data
;                           CX          Data count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyBuf     PROC near
    pushad
;    
    cmp dx,ds:[ebx].bn_count
    je cbCopy
;    
    mov ax,ds:[ebx].bn_count
    or ax,ax
    jz cbCreate
;
    push edx
    mov edx,ds:[ebx].bn_data
    FreeLinear
    pop edx

cbCreate:
    mov ds:[ebx].bn_count,dx
;    
    or dx,dx
    jz cbCopy
;    
    push edx
    movzx eax,dx
    shl eax,2
    AllocateSmallLinear
    mov ds:[ebx].bn_data,edx
    pop edx

cbCopy:
    or dx,dx
    jz cbDone
;
    mov edi,ds:[ebx].bn_data
    or cx,cx
    jz cbZeroFill

cbCopyLoop:
    mov eax,es:[esi]    
    mov es:[edi],eax
    add esi,4
    add edi,4
    sub dx,1
    jz cbDone
;
    sub cx,1
    jnz cbCopyLoop

cbZeroFill:
    xor eax,eax

cbZeroFillLoop:    
    mov es:[edi],eax
    add edi,4
    sub dx,1
    jnz cbZeroFillLoop

cbDone:
    popad        
    ret
CopyBuf ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GrowBuf
;
;           DESCRIPTION:    Grow buffer
;
;           PARAMETERS:     DS:EBX      Handle data
;                           CX          Additional count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowBuf     PROC near
    pushad
;    
    mov esi,ds:[ebx].bn_data
    mov ax,ds:[ebx].bn_count
    or ax,ax
    jnz gbSrcOk
;
    xor esi,esi

gbSrcOk:    
    push esi
    add cx,ds:[ebx].bn_count
    movzx eax,cx
    shl eax,2
    AllocateSmallLinear
    mov edi,edx
    mov ds:[ebx].bn_data,edx
;
    mov dx,ds:[ebx].bn_count
    mov ds:[ebx].bn_count,cx
;
    or dx,dx
    jz gbCopyOk

gbCopyLoop:
    mov eax,es:[esi]
    mov es:[edi],eax
    add esi,4
    add edi,4
    sub cx,1
    sub dx,1        
    jnz gbCopyLoop
;
    or cx,cx
    jz gbDone

gbCopyOk:
    xor eax,eax    

gbZeroLoop:    
    mov es:[edi],eax
    add edi,4
    sub cx,1
    jnz gbZeroLoop
;    
    pop edx
    or edx,edx
    jz gbDone
;    
    FreeLinear

gbDone:        
    popad
    ret
GrowBuf ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           OptBuf
;
;           DESCRIPTION:    Possibly shrink buffer
;
;           PARAMETERS:     DS:EBX      Handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OptBuf     PROC near
    pushad
;    
    mov esi,ds:[ebx].bn_data
    mov cx,ds:[ebx].bn_count
    or cx,cx
    jz obDone
;
    movzx eax,cx
    dec eax
    shl eax,2
    add esi,eax
    xor dx,dx

obCheckLoop:
    mov eax,es:[esi]
    or eax,eax
    jnz obCheckDone
;
    sub esi,4
    inc dx
    sub cx,1    
    jnz obCheckLoop

obCheckDone:
    or dx,dx
    jz obDone
;
    mov cx,ds:[ebx].bn_count
    sub cx,dx
    mov ds:[ebx].bn_count,cx
    jz obZero
;
    mov esi,ds:[ebx].bn_data
    push esi
    movzx eax,cx
    shl eax,2
    AllocateSmallLinear
    mov edi,edx
    mov ds:[ebx].bn_data,edx

obCopyLoop:
    mov eax,es:[esi]
    mov es:[edi],eax
    add esi,4
    add edi,4
    sub cx,1
    jnz obCopyLoop    
;
    pop edx
    FreeLinear
    jmp obDone

obZero:        
    mov edx,ds:[ebx].bn_data
    FreeLinear

obDone:    
    popad
    ret
OptBuf ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DoAdd
;
;           DESCRIPTION:    Do an add
;
;           PARAMETERS:     ES:ESI      Source data
;                           ES:EDI      Dest data
;                           CX          Buffer count
;
;           RETURNS:        CY          overflow
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoAdd     PROC near
    push eax
    push ecx
    push esi
    push edi
;
    or cx,cx
    clc
    jz daDone
;
    pushf    

daLoop:
    popf
    mov eax,es:[esi]
    adc es:[edi],eax
    pushf
;
    add esi,4
    add edi,4
    sub cx,1
    jnz daLoop        
;
    popf    
    
daDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
DoAdd     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DoSub
;
;           DESCRIPTION:    Do a sub
;
;           PARAMETERS:     ES:ESI      Source data to subtract
;                           ES:EDI      Dest data and result
;                           CX          Buffer count
;
;           RETURNS:        CY          overflow
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoSub     PROC near
    push eax
    push ecx
    push esi
    push edi
;
    or cx,cx
    clc
    jz dsDone
;
    pushf    

dsLoop:
    popf
    mov eax,es:[esi]
    sbb es:[edi],eax
    pushf
;
    add esi,4
    add edi,4
    sub cx,1
    jnz dsLoop        
;
    popf    
    
dsDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
DoSub     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DoNeg
;
;           DESCRIPTION:    Do a not
;
;           PARAMETERS:     ES:EDI      Dest data
;                           CX          Buffer count
;
;           RETURNS:        CY          overflow
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoNeg     PROC near
    push eax
    push ecx
    push edi
;
    or cx,cx
    clc
    jz dnDone
;
    stc
    pushf    

dnLoop:
    mov eax,es:[edi]
    not eax
    popf
    adc eax,0
    mov es:[edi],eax
    pushf
;
    add edi,4    
    sub cx,1
    jnz dnLoop        
;
    popf    
    
dnDone:
    pop edi
    pop ecx
    pop eax
    ret
DoNeg     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DoMul
;
;           DESCRIPTION:    Do a mul
;
;           PARAMETERS:     SS:EBP      Mul params
;                           ES          Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoMul     PROC near
    pushad
;
    mov ecx,[ebp].mul_out_count
    or ecx,ecx
    jz dmDone
;    
    xor eax,eax
    mov edi,[ebp].mul_out_data    

dmInitResLoop:
    mov es:[edi],eax
    add edi,4
    loop dmInitResLoop
;
    mov eax,[ebp].mul_in_count1
    or eax,eax
    jz dmDone
;    
    mov eax,[ebp].mul_in_count2
    or eax,eax
    jz dmDone
;
    xor ebx,ebx
    xor ecx,ecx
    mov esi,[ebp].mul_in_data1
    mov edi,[ebp].mul_in_data2

dmLoop:
    mov eax,es:[esi]
    mul es:[edi]
;
    push ebx    
    add ebx,ecx
    shl ebx,2
    add ebx,[ebp].mul_out_data
    add es:[ebx],eax
    adc es:[ebx+4],edx
    jnc dmNext
;    
    mov eax,1
    add ebx,4

dmCy:
    add ebx,4
    add es:[ebx],eax
    jc dmCy

dmNext:
    add esi,4
    pop ebx
    inc ebx
    cmp ebx,[ebp].mul_in_count1
    jne dmLoop
;
    mov esi,[ebp].mul_in_data1
    add edi,4
    xor ebx,ebx
    inc ecx            
    cmp ecx,[ebp].mul_in_count2
    jne dmLoop
    
dmDone:
    popad
    ret
DoMul     ENDP
    
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
    mov ds:[ebx].bn_count,0
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
    movzx ecx,ds:[ebx].bn_count
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
    mov cx,2
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
    mov cx,1
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
;           NAME:           AddBigNum
;
;           DESCRIPTION:    Add big num
;
;           PARAMETERS:     BX          Big num handle 1
;                           AX          Big num handle 2
;
;           RETURNS:        BX          Result big num handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_bignum_name    DB 'Add Big Number',0

add_bignum     PROC far
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    mov ax,flat_sel
    mov es,ax    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    pop ax
    jc anDone
;
    mov esi,ebx
    mov bx,ax
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc anDone
;
    mov edi,ebx
;    
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
;
    mov ax,ds:[esi].bn_flags
    xor ax,ds:[edi].bn_flags
    test ax,BN_FLAG_NEGATIVE
    jnz anSub

anAdd:
    mov cx,ds:[esi].bn_count
    cmp cx,ds:[edi].bn_count
    ja anAddUse2

anAddUse1:
    push esi
    push edi
;    
    mov cx,ds:[esi].bn_count
    mov dx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov cx,ds:[ebx].bn_count
    call DoAdd
;
    pop edi
    pop esi    
    jmp anFixupAdd

anAddUse2:  
    push esi
    push edi
;      
    xchg esi,edi
    mov cx,ds:[esi].bn_count
    mov dx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov cx,ds:[ebx].bn_count
    call DoAdd
;
    pop edi
    pop esi

anFixupAdd:
    jnc anAddSign
;
    mov cx,1
    call GrowBuf
;
    movzx edx,ds:[ebx].bn_count
    dec edx
    shl edx,2
    add edx,ds:[ebx].bn_data
    mov eax,1
    mov es:[edx],eax

anAddSign:    
    mov ax,ds:[esi].bn_flags
    or ax,ds:[edi].bn_flags
    mov ds:[ebx].bn_flags,ax
    jmp anDone

anSub:
    mov cx,ds:[esi].bn_count
    cmp cx,ds:[edi].bn_count
    ja anSubUse2

anSubUse1:
    push esi
    push edi
;    
    mov cx,ds:[esi].bn_count
    mov dx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov cx,ds:[ebx].bn_count
    call DoSub
;
    pop edi
    pop esi    
    jnc anSubFixup1
;
    push edi
    mov edi,ds:[ebx].bn_data
    mov cx,ds:[ebx].bn_count
    call DoNeg
    pop edi
;
    mov ax,ds:[edi].bn_flags
    mov dx,ds:[esi].bn_flags
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;
    call OptBuf
    jmp anDone

anSubFixup1:
    mov ax,ds:[esi].bn_flags
    mov dx,ds:[edi].bn_flags
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;    
    call OptBuf
    jmp anDone

anSubUse2:  
    push esi
    push edi
;      
    xchg esi,edi
    mov cx,ds:[esi].bn_count
    mov dx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov cx,ds:[ebx].bn_count
    call DoSub
;
    pop edi
    pop esi
    jnc anSubFixup2
;
    push edi
    mov edi,ds:[ebx].bn_data
    mov cx,ds:[ebx].bn_count
    call DoNeg
    pop edi
;
    mov ax,ds:[esi].bn_flags
    mov dx,ds:[edi].bn_flags
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;    
    call OptBuf
    jmp anDone

anSubFixup2:
    mov ax,ds:[edi].bn_flags
    mov dx,ds:[esi].bn_flags
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;    
    call OptBuf

anDone:        
    mov bx,[ebx].hh_handle
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret    
add_bignum     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MulBigNum
;
;           DESCRIPTION:    Multiply big num
;
;           PARAMETERS:     BX          Big num handle 1
;                           AX          Big num handle 2
;
;           RETURNS:        BX          Result big num handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mul_bignum_name    DB 'Mul Big Number',0

mul_bignum     PROC far
    push ebp
    sub esp,SIZE mul_struc
    mov ebp,esp
;    
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    mov ax,flat_sel
    mov es,ax    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    pop ax
    jc anDone
;
    push ax
    mov esi,ebx
    movzx eax,ds:[ebx].bn_count
    mov [ebp].mul_in_count1,eax
    mov eax,ds:[ebx].bn_data
    mov [ebp].mul_in_data1,eax
    pop bx
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc anDone
;
    mov edi,ebx
    movzx eax,ds:[ebx].bn_count
    mov [ebp].mul_in_count2,eax
    mov eax,ds:[ebx].bn_data
    mov [ebp].mul_in_data2,eax
;    
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
;
    mov eax,[ebp].mul_in_count1
    add eax,[ebp].mul_in_count2
    mov [ebp].mul_out_count,eax
;
    mov cx,ax
    call RecreateBuf
;
    mov ax,ds:[esi].bn_flags
    or ax,ds:[edi].bn_flags
    and ax,NOT BN_FLAG_NEGATIVE
    mov ds:[ebx].bn_flags,ax
;
    mov ax,ds:[esi].bn_flags
    xor ax,ds:[edi].bn_flags
    and ax,BN_FLAG_NEGATIVE
    or ds:[ebx].bn_flags,ax
;    
    mov eax,ds:[ebx].bn_data
    mov [ebp].mul_out_data,eax
;    
    call DoMul
    call OptBuf
    mov bx,[ebx].hh_handle
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
;
    add esp,SIZE mul_struc
    pop ebp
    ret
mul_bignum  ENDP
    
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
    movzx ecx,ds:[ebx].bn_count
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
    mov esi,OFFSET add_bignum
    mov edi,OFFSET add_bignum_name
    xor dx,dx
    mov ax,add_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET mul_bignum
    mov edi,OFFSET mul_bignum_name
    xor dx,dx
    mov ax,mul_bignum_nr
    RegisterBimodalUserGate
;
    ret
init    ENDP
    

code    ENDS

    END init
