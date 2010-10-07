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
; DMC6000.ASM
; Support for PenMount DMC6000 touch-screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME dmc6000

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc

touch_data_seg	STRUC

td_wait         DW ?
td_port         DW ?
td_x            DW ?
td_y            DW ?
td_prev_x       DW ?
td_prev_y       DW ?
td_max          DW ?
td_state        DB ?

td_out_buf      DB 6 DUP(?)
td_in_buf       DB 6 DUP(?)

touch_data_seg	ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ClearPort
;
;		DESCRIPTION:    Clear comport before sending command
;
;       PARAMETERS:     
;
;       RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearPort Proc near
    push eax
    push bx
    push cx
    push edx
;    
    mov cx,256

cpLoop:
    push cx
    GetSystemTime
    add eax,100 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
    pop cx
;
    mov bx,ds:td_port
    ReadCom
    jc cpOk
;    
    loop cpLoop
;
    stc
    jmp cpDone

cpOk:
    clc

cpDone:
    pop edx
    pop cx
    pop bx
    pop eax   
    ret
ClearPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendCmd
;
;		DESCRIPTION:    Send t_out_buf
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCmd Proc near
    push ax
    push bx
    push cx
    push si
;    
    mov bx,ds:td_port
    mov ds:td_out_buf+5,0FFh
    mov cx,5
    mov si,OFFSET td_out_buf

scLoop:
    lodsb
    sub ds:td_out_buf+5,al
    WriteCom
    loop scLoop
;
    lodsb
    WriteCom
;
    pop si
    pop cx
    pop bx
    pop ax   
    ret
SendCmd Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetResponse
;
;		DESCRIPTION:    Receive response
;
;       PARAMETERS:     
;
;       RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetResponse Proc near
    push eax
    push bx
    push cx
    push edx
    push si
;    
    mov ds:td_in_buf+5,0FFh
    mov cx,5
    mov si,OFFSET td_in_buf

grLoop:
    push cx
    GetSystemTime
    add eax,100 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
    pop cx
;
    mov bx,ds:td_port
    ReadCom
    jc grDone
;
    mov ds:[si],al
    sub ds:td_in_buf+5,al
    inc si
    loop grLoop
;
    GetSystemTime
    add eax,100 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc grDone
;
    cmp al,ds:[si]
    clc
    jz grDone
;
    stc

grDone:
    pop si
    pop edx
    pop cx
    pop bx
    pop eax   
    ret
GetResponse Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckVersion
;
;		DESCRIPTION:    Check touch version
;
;       PARAMETERS:     
;
;		RETURNS:		NC  Version ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckVersion    Proc near
    call ClearPort
    jc cvDone
;    
    mov ds:td_out_buf,0EEh
    mov ds:td_out_buf+1,0
    mov ds:td_out_buf+2,0
    mov ds:td_out_buf+3,0
    mov ds:td_out_buf+4,0
    call SendCmd
    call GetResponse
    jc cvDone
;
    mov al,ds:td_in_buf
    cmp al,0EEh
    stc
    jne cvDone
;    
    mov ax,word ptr ds:td_in_buf+1
    xchg al,ah
    cmp ax,6000
    stc
    jne cvDone
;
    clc    

cvDone:    
    ret
CheckVersion    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetScaling
;
;		DESCRIPTION:    Get scaling
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetScaling    Proc near
    mov ds:td_out_buf,0FFh
    mov ds:td_out_buf+1,0
    mov ds:td_out_buf+2,0
    mov ds:td_out_buf+3,0
    mov ds:td_out_buf+4,0
    call SendCmd
    call GetResponse
    jc gsDone
;
    mov al,ds:td_in_buf
    cmp al,0FFh
    stc
    jne gsDone
;    
    mov cl,ds:td_in_buf+4
    mov ax,1
    shl ax,cl
    mov ds:td_max,ax
    clc

gsDone:
    ret
GetScaling    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EnableController
;
;		DESCRIPTION:    Enable controller
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnableController    Proc near
    mov ds:td_out_buf,0F1h
    mov ds:td_out_buf+1,0
    mov ds:td_out_buf+2,0
    mov ds:td_out_buf+3,0
    mov ds:td_out_buf+4,0
    call SendCmd
    call GetResponse
    jc ecDone
;
    mov al,ds:td_in_buf
    cmp al,0F1h
    stc
    jne ecDone
;    
    clc

ecDone:
    ret
EnableController    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Touch_thread
;
;		DESCRIPTION:    Touch-screen thread
;
;       PARAMETERS:     BL      Com port 
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

touch_thread    Proc far
    push bx
    mov ax,500
    WaitMilliSec
;
    mov eax,SIZE touch_data_seg
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
;
    CreateWait
    mov ds:td_wait,bx
;    
    pop ax
    mov ah,8
    mov bl,1
    mov bh,'N'
    mov ecx,9600
    mov si,256
    mov di,256
    OpenCom
    mov ds:td_port,bx
    mov ds:td_state,0
    mov ds:td_prev_x,-1
    mov ds:td_prev_y,-1
;
    mov ax,ds:td_port
    mov bx,ds:td_wait
    xor ecx,ecx
    AddWaitForCom
;
    call CheckVersion
    jc ttEnd
;
    call GetScaling    
    jc ttEnd
;    
    call EnableController
    jc ttEnd

ttLoop:
    mov bx,ds:td_wait
    WaitWithoutTimeout
;
    call GetResponse
    jc ttLoop
;
    mov al,ds:td_in_buf
    cmp al,30h
    je ttUp
;
    cmp al,70h
    jne ttLoop

ttDown:
    mov ds:td_state,1
    jmp ttDecodePos

ttUp:
    mov al,ds:td_state
    or al,al
    jz ttLoop
;
    mov ds:td_state,0
    mov ds:td_prev_x,-1
    mov ds:td_prev_y,-1

ttDecodePos:
    mov cx,ds:td_max
    sub cx,word ptr ds:td_in_buf+1
    xor dx,dx
    mov ax,7FFFh
    mul cx
    mov cx,ds:td_max
    div cx
    mov ds:td_x,ax
;
    mov cx,ds:td_max
    sub cx,word ptr ds:td_in_buf+3
    xor dx,dx
    mov ax,7FFFh
    mul cx
    mov cx,ds:td_max
    div cx
    mov ds:td_y,ax
;    
    mov cx,ds:td_x
    mov dx,ds:td_y
;
    mov bx,ds:td_prev_x
    sub bx,cx
    mov ax,ds:td_prev_y
    sub ax,dx
    or ax,bx
    jz ttLoop
;
    mov ds:td_prev_x,cx
    mov ds:td_prev_y,dx    
    mov al,ds:td_state    
    SetMouse
    jmp ttLoop

ttEnd:
    mov bx,ds:td_port
    CloseCom
;
    mov bx,ds:td_wait
    CloseWait    
;
    xor ax,ax
    mov ds,ax
    FreeMem
    ret
touch_thread    Endp
        
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

touch_name1	DB 'PenMount COM1',0
touch_name2	DB 'PenMount COM2',0
touch_name3	DB 'PenMount COM3',0
touch_name4	DB 'PenMount COM4',0

init_touch	Proc far
	push ds
	push es
;
    mov bx,0
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET touch_name1
	mov si,OFFSET touch_thread
	mov ax,4
	mov cx,100h
	CreateThread
;
    mov bx,1
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET touch_name2
	mov si,OFFSET touch_thread
	mov ax,4
	mov cx,100h
	CreateThread
;
    mov bx,2
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET touch_name3
	mov si,OFFSET touch_thread
	mov ax,4
	mov cx,100h
	CreateThread
;
    mov bx,3
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET touch_name4
	mov si,OFFSET touch_thread
	mov ax,4
	mov cx,100h
	CreateThread
;
	pop es
	pop ds
	ret
init_touch	Endp


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
	mov ax,cs
	mov es,ax
	mov di,OFFSET init_touch
	HookInitTasking
	clc
	ret
init	ENDP

code	ENDS

	END init
