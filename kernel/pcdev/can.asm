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

CAN_CONT     = 0
CAN_BITT     = 0Ch
CAN_INT      = 10h
CAN_BRPE     = 18h

IF1_CREQ    = 20h
IF1_CMASK   = 24h
IF1_MASK1   = 28h
IF1_MASK2   = 2Ch
IF1_ID1     = 30h
IF1_ID2     = 34h
IF1_MCONT   = 38h
IF1_DATA1   = 3Ch
IF1_DATA2   = 40h
IF1_DATA3   = 44h
IF1_DATA4   = 48h

IF2_CREQ    = 80h
IF2_CMASK   = 84h
IF2_MASK1   = 88h
IF2_MASK2   = 8Ch
IF2_ID1     = 90h
IF2_ID2     = 94h
IF2_MCONT   = 98h
IF2_DATA1   = 9Ch
IF2_DATA2   = 0A0h
IF2_DATA3   = 0A4h
IF2_DATA4   = 0A8h

CAN_TREQ1   = 100h
CAN_TREQ2   = 104h

CAN_NDATA1  = 120h
CAN_NDATA2  = 124h

CAN_IPEND1  = 140h
CAN_IPEND2  = 144h

CAN_MVAL1   = 160h
CAN_MVAL2   = 164h

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
    int 3
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
    mov es:CAN_CONT,eax
    mov es:CAN_BITT,edx
;
    mov eax,0
    mov es:CAN_BRPE,eax
;
    mov eax,1
    mov es:CAN_CONT,eax        
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
;   NAME:           WaitForIf1
;
;   DESCRIPTION:    Wait for IF1 to become ready
;
;   PARAMETERS:     ES      Can sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForIf1  Proc near
    test es:IF1_CREQ,8000h
    jz wf1Done
;
    push ax
    mov ax,1
    WaitMicroSec
    pop ax 
    jmp WaitForIf1   

wf1Done:
    ret
WaitForIf1  Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InitEmptyMsg
;
;   DESCRIPTION:    Init empty message
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitEmptyMsg  Proc near
    push eax
;
    call WaitForIf1
;
    mov eax,0A8h
    mov es:IF1_CMASK,eax
;
    mov eax,0
    mov es:IF1_ID1,eax
;
    mov eax,0
    mov es:IF1_ID2,eax
;
    movzx eax,bx
    mov es:IF1_CREQ,eax
;
    pop eax
    ret
InitEmptyMsg    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InitReceiveMsg
;
;   DESCRIPTION:    Init receive message
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitReceiveMsg  Proc near
    push eax
;
    call WaitForIf1
;    
    mov eax,480h
    mov es:IF1_MCONT,eax
;
    mov eax,0F8h
    mov es:IF1_CMASK,eax
;
    mov eax,0FFFFh
    mov es:IF1_MASK1,eax
;
    mov eax,3FFFh
    mov es:IF1_MASK2,eax
;
    mov eax,0
    mov es:IF1_ID1,eax
;
    mov eax,8000h    
    mov es:IF1_ID2,eax
;
    movzx eax,bx
    mov es:IF1_CREQ,eax
;    
    pop eax
    ret
InitReceiveMsg  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ReadMsg
;
;   DESCRIPTION:    Read message into IF1
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadMsg  Proc near
    push eax
;
    call WaitForIf1
;
    mov eax,7Fh
    mov es:IF1_CMASK,eax
;
    movzx eax,bx
    mov es:IF1_CREQ,eax
;
    call WaitForIf1
;    
    pop eax
    ret
ReadMsg  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           StartSend
;
;   DESCRIPTION:    Start send on IF1
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;                   DS:SI   Message struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartSend  Proc near
    push eax
;
    call WaitForIf1
;
    mov eax,0BFh
    mov es:IF1_CMASK,eax
;    
    mov eax,880h
    add eax,ds:[si].cm_size
    mov es:IF1_MCONT,eax
;
    mov eax,ds:[si].cm_id
    movzx eax,ax
    mov es:IF1_ID1,eax
;
    mov eax,ds:[si].cm_id
    shr eax,16
    or ax,0A000h
    mov es:IF1_ID2,eax
;
    movzx eax,word ptr ds:[si].cm_data
    mov es:IF1_DATA1,eax
;
    movzx eax,word ptr ds:[si+2].cm_data
    mov es:IF1_DATA2,eax
;
    movzx eax,word ptr ds:[si+4].cm_data
    mov es:IF1_DATA3,eax
;
    movzx eax,word ptr ds:[si+6].cm_data
    mov es:IF1_DATA4,eax
;
    movzx eax,bx
    mov es:IF1_CREQ,eax
;    
    pop eax
    ret
StartSend  Endp

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
;
    mov bx,1

init_rx_msg:
    call InitReceiveMsg
    inc bx
    cmp bx,10h
    jbe init_rx_msg

init_tx_msg:
    call InitEmptyMsg
    inc bx
    cmp bx,20h
    jbe init_tx_msg
;
    call WaitForIf1
;    
    WaitForSignal
;
    int 3
    mov eax,0
    mov es:CAN_CONT,eax        

ctLoop:
    int 3
    mov bx,11h
    mov si,OFFSET can_send_arr
    call StartSend
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
