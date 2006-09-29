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
; TS2003.ASM
; Support for TS2003 touch-screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME ts2003

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc

	.386p

touch_data_seg	SEGMENT AT 0

td_wait         DW ?
td_port         DW ?

touch_data_seg	ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Touch_thread
;
;		DESCRIPTION:    Touch-screen thread
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

touch_name	DB 'TS2003',0

touch_thread:
    mov ax,500
    WaitMilliSec
;
    mov ax,touch_data_sel
    mov ds,ax
;    
    int 3
    CreateWait
    mov ds:td_wait,bx
;    
    xor al,al

ttPortLoop:    
    push ax
    mov ah,8
    mov bl,1
    mov bh,'N'
    mov ecx,38400
    mov si,256
    mov di,256
    OpenCom
    or bx,bx
    jz ttDone
;
    mov ds:td_port,bx
    ResetDtr
    ResetRts
;
    mov ax,ds:td_port
    mov bx,ds:td_wait
    xor ecx,ecx
    AddWaitForCom
;        
    mov ax,60
    WaitMilliSec
;   
    mov bx,ds:td_port 
    SetDtr
    SetRts
;  
    GetSystemTime
    add eax,10 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc ttNextPort      
;
    cmp al,'['
    jnz ttNextPort
;  
    GetSystemTime
    add eax,10 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc ttNextPort      
;
    cmp al,'T'
    jnz ttNextPort
;  
    GetSystemTime
    add eax,10 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc ttNextPort      
;
    cmp al,'S'
    jnz ttNextPort
;  
    GetSystemTime
    add eax,10 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc ttNextPort      
;
    cmp al,']'
    jz ttPortOk

ttNextPort:   
    mov bx,ds:td_wait 
    RemoveWait
;    
    pop ax
    inc al
    mov bx,ds:td_port
    CloseCom
    jmp ttPortLoop

ttPortOk:
    pop ax
    mov bx,ds:td_wait
    WaitWithoutTimeout
    int 3

ttDone: 
    mov bx,ds:td_wait
    CloseWait
    pop ax
    retf
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_TOUCH
;
;		DESCRIPTION:	Init touch
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_touch_name	DB 'Init Touch', 0

init_touch	Proc far
	push ds
	push es
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET touch_name
	mov si,OFFSET touch_thread
	mov ax,4
	mov cx,100h
	CreateThread
;
	pop es
	pop ds
	ret
init_touch	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init touch-screen
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	pusha
	push ds
;
	mov bx,touch_code_sel
	InitDevice
;
	mov eax,SIZE touch_data_seg
	mov bx,touch_data_sel
	AllocateFixedSystemMem
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET init_touch
	HookInitTasking
;
	pop ds
	popa
	ret
init	ENDP

code	ENDS

	END init
