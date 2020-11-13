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
; SMA.ASM
; SMA speedwire support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.inc

.386p

data    SEGMENT byte public 'DATA'

sma_thread  DW ?
sma_busy    DB ?
sma_msg     DB 600 DUP (?)

data    ENDS

code    SEGMENT byte public use32 'CODE'
    
    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleMsg
;
;       DESCRIPTION:    Handle SMA message
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleMsg	Proc near
    int 3
    ret
HandleMsg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           sma_rec
;
;       DESCRIPTION:    SMA data received
;
;       PARAMETERS:     EDX	IP
;                       CX      Size
;                       ES:EDI  Data
;
;       RETURNS:        CX      Reply size (or 0)
;                       ES:EDI  Reply data           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sma_rec	Proc far
    push ds
    push eax
    push ebx
    push esi
;
    mov eax,SEG data
    mov ds,eax
    mov al,ds:sma_busy
    or al,al
    jnz srDone
;
    cmp cx,600
    ja srDone
;
    mov esi,edi
    movzx ecx,cx
    mov eax,es
    mov ds,eax
    mov eax,SEG data
    mov es,eax
    mov edi,OFFSET sma_msg
    rep movsb
;
    mov es:sma_busy,1
    mov bx,es:sma_thread
    Signal

srDone:
    xor cx,cx
;
    pop esi
    pop ebx
    pop eax
    pop ds
    ret
sma_rec Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           sma_thread
;
;           DESCRIPTION:    SMA thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sma_name	DB 'SMA', 0

sma_pr:
    mov ax,SEG data
    mov ds,eax
    GetThread
    mov ds:sma_thread,ax
    mov ds:sma_busy,0
;
    mov si,9522
    mov eax,cs
    mov es,eax
    mov edi,OFFSET sma_rec
    ListenUdpPort

sLoop:
    WaitForSignal
    call HandleMsg
    mov ds:sma_busy,0
    jmp sLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_sma
;
;           DESCRIPTION:    Init sma
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_sma      PROC far
    push ds
    push es
    pushad
;    
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET sma_pr
    mov edi,OFFSET sma_name
    mov cx,stack0_size
    mov ax,3
    CreateThread
;    
    popad
    pop es
    pop ds
    ret
init_sma      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov eax,cs
    mov ds,eax
    mov es,eax  
    mov edi,OFFSET init_sma
    HookInitTasking
;
    ret
init    ENDP
    

code    ENDS

    END init
