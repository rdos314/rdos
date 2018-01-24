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
; KEY.ASM
; Basic keyboard support module.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE port.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc

data SEGMENT byte public 'DATA'

port         DW ?

com_handle   DW ?
wait_handle  DW ?

data ENDS

code SEGMENT byte public 'CODE'

    .386p

    assume cs:code

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetValue
;
;       Purpose:        Get value from string
;
;       Parameters:     ES:EDI      String
;
;       Returns:        NC          Found
;                           AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetValue    Proc near
    push bx
    push cx
    push dx
;    
    xor ax,ax

find_first_loop:
    mov bl,es:[edi]
    cmp bl,' '
    je find_first_next
;
    cmp bl,','
    je find_first_next
;
    cmp bl,8
    je find_first_next
;
    or bl,bl
    jnz find_val_digit  

find_first_next:
    inc edi
    jmp find_first_loop      

find_val_digit:
    mov bl,es:[edi]
    or bl,bl
    jz find_val_save
;    
    inc edi
    sub bl,'0'
    jc find_val_save
;
    cmp bl,10
    jnc find_val_save
;       
    mov cx,10
    mul cx
    add al,bl
    adc ah,0
    jmp find_val_digit

find_val_save:
    pop dx
    pop cx
    pop bx
    ret
GetValue    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           OpenPort
;
;       Purpose:        Open com port and create wait handle
;
;       Parameters:     ES:EDI      String
;
;       Returns:        NC          Found
;                           AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPort Proc near
    pushad
;
    mov ds:com_handle,0
    mov ds:wait_handle,0
;
    mov ax,ds:port
    mov ah,8
    mov bl,1
    mov bh,'N'
    mov ecx,9600
    mov si,100h
    mov di,100h
    OpenCom
    jc opDone
;
    mov ds:com_handle,bx
;
    CreateWait
    mov ds:wait_handle,bx
;
    mov ax,ds:com_handle
    AddWaitForCom
;
    clc

opDone:
    popad
    ret
OpenPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           test_gate
;
;           DESCRIPTION:    Test gate
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_gate_name   DB 'Test Gate',0

test_gate    PROC far
    int 3
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    call OpenPort
;
    pop ax
    pop ds
    retf32
test_gate   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;    NAME:	        init
;
;    DESCRIPTION:	Init device-driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
    mov ax,SEG data
    mov ds,ax
;
    call GetValue
    mov ds:port,ax

init_reg:
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET test_gate
    mov edi,OFFSET test_gate_name
    xor dx,dx
    mov ax,test_gate_nr
    RegisterBimodalUserGate
    ret
init	ENDP

code	ENDS

    END init
