;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; TS2003.ASM
; Support for TS2003 touch-screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\protseg.def

X_START = 80
Y_START = 110
X_SIZE = 900
Y_SIZE = 880

data    SEGMENT byte public 'DATA'

td_wait         DW ?
td_port         DW ?
td_x            DW ?
td_y            DW ?
td_control      DB ?

data    ENDS

code    SEGMENT byte public use16 'CODE'

        assume cs:code

        .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   HandleTouch
;
;               DESCRIPTION:    Handle touch-screen
;
;       PARAMETERS:     
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
    shl ax,6
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
    test al,0C0h
    jnz htLoop
;
    and ax,3Fh
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
    shl ax,6
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
    test al,0C0h
    jnz htLoop
;
    and ax,3Fh
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
    and al,20h
    shr al,5
;    shl cx,5
;    shl dx,5
;
; upside-down touch
;
    not cx
    not dx
    and ch,7Fh
    and dh,7Fh
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

touch_name      DB 'TS2003',0

touch_thread:
    mov ax,500
    WaitMilliSec
;
    mov ax,SEG data
    mov ds,ax
;    
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
    mov bx,ds:td_port
    CloseCom
;    
    mov bx,ds:td_wait 
    RemoveWait
    jmp HandleTouch

ttDone: 
    mov bx,ds:td_wait
    CloseWait
    pop ax
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
