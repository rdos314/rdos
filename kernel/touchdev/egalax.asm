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
; EGALAX.ASM
; Support for e-Galax touch-screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\protseg.def

; Auto-detect doesn't seem to work so give COM port here:

COM_PORT = 1
        

X_START = 100
Y_START = 100
X_SIZE = 1850
Y_SIZE = 1850

data    SEGMENT byte public 'DATA'

td_wait         DW ?
td_port         DW ?
td_x            DW ?
td_y            DW ?
td_control      DB ?

data    ENDS


        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   HandleTouch
;
;               DESCRIPTION:    Handle touch-screen
;
;       PARAMETERS:     AL  Port
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleTouch:    
    CreateWait
    mov ds:td_wait,bx
;    
    mov ah,8
    mov bl,1
    mov bh,'N'
    mov ecx,9600
    mov si,256
    mov di,256
    OpenCom
    mov ds:td_port,bx
;
    mov ax,ds:td_port
    mov bx,ds:td_wait
    xor ecx,ecx
    AddWaitForCom

htClearLoop:  
    GetSystemTime
    add eax,10 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc htLoop
;
    test al,80h
    jz htClearLoop
    jmp htControl

htLoop:
    xor ax,ax
    mov es,ax
    mov bx,ds:td_wait
    WaitWithoutTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc htLoop
;
    test al,80h
    jz htLoop    

htControl:
    mov ds:td_control,al
;    
    GetSystemTime
    add eax,10 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc htLoop
;
    test al,0F0h
    jnz htLoop
;
    and ax,0Fh
    shl ax,7
    mov ds:td_x,ax        
;    
    GetSystemTime
    add eax,10 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc htLoop
;
    test al,80h
    jnz htLoop
;
    and ax,7Fh
    or ds:td_x,ax
;    
    GetSystemTime
    add eax,10 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc htLoop
;
    test al,0F0h
    jnz htLoop
;
    and ax,0Fh
    shl ax,7
    mov ds:td_y,ax        
;    
    GetSystemTime
    add eax,10 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc htLoop
;
    test al,80h
    jnz htLoop
;
    and ax,7Fh
    or ds:td_y,ax
;    
; custom scaling
;
    mov cx,ds:td_x
    sub cx,X_START
    jnc htXMinOk
;
    xor cx,cx

htXMinOk:
    cmp cx,X_SIZE
    jb htXMaxOk
;
    mov cx,X_SIZE

htXMaxOk:
    xor dx,dx
    mov ax,7FFFh
    mul cx
    mov cx,X_SIZE
    div cx
    mov ds:td_x,ax
;
    mov cx,ds:td_y
    sub cx,Y_START
    jnc htYMinOk
;
    xor cx,cx

htYMinOk:
    cmp cx,Y_SIZE
    jb htYMaxOk
;
    mov cx,Y_SIZE

htYMaxOk:
    xor dx,dx
    mov ax,7FFFh
    mul cx
    mov cx,Y_SIZE
    div cx
    mov ds:td_y,ax
;    
    mov cx,ds:td_x
    mov dx,ds:td_y
    mov al,ds:td_control
    and al,1
;    shl cx,5
;    shl dx,5
;
; upside-down touch
;
    not cx
;    not dx
    and ch,7Fh
;    and dh,7Fh
;    
    SetMouse
;
    jmp htLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Touch_thread
;
;               DESCRIPTION:    Touch-screen thread
;
;       PARAMETERS:     
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

touch_name      DB 'E-GALAX',0

touch_thread:
    mov ax,500
    WaitMilliSec
;
    mov ax,SEG data
    mov ds,ax
;    
    mov al,COM_PORT
    mov ah,8
    mov bl,1
    mov bh,'N'
    mov ecx,9600
    mov si,256
    mov di,256
    OpenCom
    or bx,bx
    jz ttDone
;
    mov ds:td_port,bx
;   
    mov bx,ds:td_port 
    SetDtr
    SetRts
    CloseCom
;
    mov al,COM_PORT    
    jmp HandleTouch

ttDone: 
    mov bx,ds:td_wait
    CloseWait
    retf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HasTouch
;
;           DESCRIPTION:    Check if touch is available
;
;           RETURNS:        NC      Touch available
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_touch_name DB 'Has Touch',0

has_touch      Proc far
    clc
    retf32    
has_touch  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   INIT_TOUCH
;
;               DESCRIPTION:    Init touch
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_touch_name DB 'Init Touch', 0

init_touch      Proc far
        push ds
        push es
;
        mov ax,cs
        mov ds,ax
        mov es,ax
        mov di,OFFSET touch_name
        mov si,OFFSET touch_thread
        mov ax,4
        mov cx,stack0_size
        CreateThread
;
        pop es
        pop ds
        retf32
init_touch      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   INIT
;
;               DESCRIPTION:    Init touch-screen
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET has_touch
    mov edi,OFFSET has_touch_name
    xor dx,dx
    mov ax,has_touch_nr
    RegisterBimodalUserGate
;    
    mov edi,OFFSET init_touch
    HookInitTasking
    clc
    ret
init    ENDP

code    ENDS

        END init
