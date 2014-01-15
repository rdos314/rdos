;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2000, Leif Ekblad
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
; CAN.ASM
; CAN-bus driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\drive.inc
INCLUDE ..\os\protseg.def
INCLUDE pci.inc

MAX_CAN_HOOKS   = 16

CANCONT     = 0
CANBITT     = 0Ch
CANBRPE     = 18h

can_msg_struc   STRUC

cm_id       DD ?
cm_data     DD ?,?
cm_size     DD ?

can_msg_struc   ENDS

data    SEGMENT byte public 'DATA'

can_sel             DW ?

can_thread          DW ?

can_send_section    section_typ <>

can_send_used       DD ?
can_send_arr        DB 32 * 16 DUP(?)

can_hook_count      DW ?
can_hook_arr        DD MAX_CAN_HOOKS DUP(?,?)

data    ENDS


IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CanInt
;
;           DESCRIPTION:    CAN-bus interrupt
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CanInt  Proc far
    retf32
CanInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupBitTiming
;
;   DESCRIPTION:    Setup bit timing
;
;   PARAMETERS:     ES      CAN sel
;                   AL      TSEG1
;                   AH      TSEG2
;                   CL      Baud divisor
;                   BL      SJW
;
;   RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupBitTiming  Proc near
    pushad
;    
    xor edx,edx
    dec cl
    mov dl,cl
    dec bl
    shl bl,6
    or dl,bl
    dec al
    mov dh,al
    dec ah
    shl ah,4
    or dh,ah
;
    mov eax,41h
    mov es:CANCONT,eax
    mov es:CANBITT,edx
;
    mov eax,0
    mov es:CANBRPE,eax
;
    mov eax,1
    mov es:CANCONT,eax        
;
    popad  
    ret
SetupBitTiming  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupDevice
;
;   DESCRIPTION:    Setup device
;
;   RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDevice  Proc near
    xor ax,ax
    mov bh,0Ch
    mov bl,9
    FindPciClassAll
    jc sdDone
;
    push cx
    mov eax,1000h    
    AllocateBigLinear
    pop cx
;        
    mov cl,14h
    ReadPciDword
;
    push ebx
    push ecx
;
    mov si,ax
    and si,0E00h
    and ax,0F000h
    mov al,67h
    xor ebx,ebx
    SetPageEntry
;
    AllocateGdt
    or dx,si
    mov ecx,200h
    CreateDataSelector16
    mov ds,bx
;    
    pop ecx
    pop ebx    
;
    GetPciMsi
    jc sdIrq

sdMsi:
    push cx
    mov cx,1
    mov al,12h
    AllocateInts
    pop cx
    jc sdIrq
;    
    mov dl,1
    SetupPciMsi
;    
    mov di,cs
    mov es,di
    mov edi,OFFSET CanInt
    RequestMsiHandler
    jmp sdConf

sdIrq:
    GetPciIrqNr
    mov ah,12h
    mov bx,cs
    mov es,bx
    mov edi,OFFSET CanInt    
    RequestIrqHandler

sdConf:
    mov ax,ds
    mov es,ax
    mov ax,SEG data
    mov ds,ax
    mov ds:can_sel,es
;
    mov al,8
    mov ah,8
    mov bl,4
    mov cl,1
    call SetupBitTiming
    clc

sdDone:
    ret
SetupDevice Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CanThread
;
;           DESCRIPTION:    CAN thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

can_thread_name DB 'CAN-bus', 0

can_thread_pr:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:can_thread,ax
    mov es,ds:can_sel
    WaitForSignal
;
    int 3
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SendCanBusMsg
;
;   DESCRIPTION:    Send CAN bus message
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_can_bus_msg_name   DB 'Send CAN Bus Message', 0

send_can_bus_msg    Proc far
    push ds
    push ecx
    push esi
    push edi
;    
    mov si,SEG data
    mov ds,si

scRetry:    
    EnterSection ds:can_send_section
;    
    mov esi,ds:can_send_used
    not esi
    bsf edi,esi
    jnz scDo
;
    LeaveSection ds:can_send_section
;
    mov ax,10
    WaitMilliSec
    jmp scRetry

scDo:    
    bts ds:can_send_used,edi
    shl edi,4
    add edi,OFFSET can_send_arr
;
    movzx ecx,cl
    mov ds:[edi].cm_id,ebx
    mov ds:[edi].cm_data,eax
    mov ds:[edi].cm_data+4,edx
    mov ds:[edi].cm_size,ecx
;
    LeaveSection ds:can_send_section
    mov bx,ds:can_thread
    Signal
;
    pop edi
    pop esi
    pop ecx
    pop ds    
    retf32
send_can_bus_msg    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HookCanBusMsg
;
;   DESCRIPTION:    Register callback for received CAN bus messages
;
;   PARAMETERS:     ES:EDI      Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_can_bus_msg_name   DB 'Hook CAN Bus Message', 0

hook_can_bus_msg    Proc far
    push ds
    push bx
;    
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:can_hook_count
    shl bx,3
    add bx,OFFSET can_hook_arr
    mov ds:[bx],edi
    mov ds:[bx+4],es
    inc ds:can_hook_count
;
    pop bx
    pop ds    
    retf32
hook_can_bus_msg    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_can
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_can    Proc far
    push ds
    push es
    pusha
;
    call SetupDevice
    jc icDone
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET can_thread_name
    mov esi,OFFSET can_thread_pr
    mov ax,2
    mov cx,stack0_size
    CreateThread

icDone:
    popa
    pop es
    pop ds
    retf32
init_can    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_net
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,SEG data
    mov ds,ax
    mov ds:can_hook_count,0
    InitSection ds:can_send_section
    mov ds:can_send_used,0
;    
    mov ax,cs
    mov es,ax
    mov ds,ax
    mov edi,OFFSET init_can
    HookInitPci
;
    mov esi,OFFSET send_can_bus_msg
    mov edi,OFFSET send_can_bus_msg_name
    mov ax,send_can_bus_msg_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_can_bus_msg
    mov edi,OFFSET hook_can_bus_msg_name
    mov ax,hook_can_bus_msg_nr
    RegisterOsGate
;    
    clc
    ret
init    ENDP

code    ENDS

    END init
