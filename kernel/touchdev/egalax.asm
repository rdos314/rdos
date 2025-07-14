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

data    SEGMENT byte public 'DATA'

td_wait         DW ?
td_port         DW ?
td_x            DW ?
td_y            DW ?
td_prev_x       DW ?
td_prev_y       DW ?

x_start         DW ?
y_start         DW ?
x_size          DW ?
y_size          DW ?

td_control      DB ?
ComPort         DB ?

Param           DD ?,?

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
    test al,1
    jz ttUp

ttDown:
    mov ds:td_control,1
    jmp ttGetPos

ttUp:
    mov al,ds:td_control
    or al,al
    jz ttGetPos
;
    mov ds:td_control,0
    mov ds:td_prev_x,-1
    mov ds:td_prev_y,-1

ttGetPos:
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
    test al,80h
    jnz htLoop
;
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
    or ds:td_y,ax
;
; invert
;
    mov dx,ds:y_size
    add dx,ds:y_start
    add dx,ds:y_start
    sub dx,ds:td_y
    mov ds:td_y,dx    
;    
; custom scaling
;
    mov cx,ds:td_x
    sub cx,ds:x_start
    jnc htXMinOk
;
    xor cx,cx

htXMinOk:
    cmp cx,ds:x_size
    jb htXMaxOk
;
    mov cx,ds:x_size

htXMaxOk:
    xor dx,dx
    mov ax,7FFFh
    mul cx
    mov cx,ds:x_size
    div cx
    mov ds:td_x,ax
;
    mov cx,ds:td_y
    sub cx,ds:y_start
    jnc htYMinOk
;
    xor cx,cx

htYMinOk:
    cmp cx,ds:y_size
    jb htYMaxOk
;
    mov cx,ds:y_size

htYMaxOk:
    xor dx,dx
    mov ax,7FFFh
    mul cx
    mov cx,ds:y_size
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
    jz htLoop
;
    mov ds:td_prev_x,cx
    mov ds:td_prev_y,dx    
    mov al,ds:td_control
    and ax,1
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
    mov al,ds:ComPort
    dec al
;    
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
    mov al,ds:ComPort
    dec al
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
;ù
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
    mov ax,SEG data
    mov ds,ax
;    
    mov ds:ComPort,1
    mov ds:x_start,100
    mov ds:y_start,100
    mov ds:x_size,1850
    mov ds:y_size,1850
    mov ds:td_prev_x,-1
    mov ds:td_prev_y,-1
;        
    call GetValue
    mov ds:ComPort,al
;
    call GetValue
    or ax,ax
    jz x_start_ok
;
    mov ds:x_start,ax
    mov ds:y_start,ax

x_start_ok:    
    call GetValue
    or ax,ax
    jz x_size_ok
;
    mov ds:x_size,ax
    mov ds:y_size,ax

x_size_ok:
    call GetValue
    or ax,ax
    jz y_start_ok
;
    mov ds:y_start,ax

y_start_ok:
    call GetValue
    or ax,ax
    jz y_size_ok
;
    mov ds:y_size,ax

y_size_ok:
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
    clc
    ret
init    ENDP

code    ENDS

        END init
