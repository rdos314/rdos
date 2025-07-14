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
; DMC9000.ASM
; Support for PenMount DMC9000 touch-screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\protseg.def

    .386p

; Auto-detect doesn't seem to work so give COM port here:

COM_PORT = 1
    

X_START = 0
Y_START = 0
X_SIZE = 1024
Y_SIZE = 1024

touch_data_seg  STRUC

td_wait         DW ?
td_port         DW ?
td_x            DW ?
td_y            DW ?
td_control      DB ?
td_in_buf       DB 6 DUP(?)
td_out_buf      DB 6 DUP(?)

touch_data_seg  ENDS

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ClearPort
;
;               DESCRIPTION:    Clear comport before sending command
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
;               NAME:                   SendCmd
;
;               DESCRIPTION:    Send t_out_buf
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
;               NAME:                   GetResponse
;
;               DESCRIPTION:    Receive response
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
;               NAME:                   CheckVersion
;
;               DESCRIPTION:    Check touch version
;
;       PARAMETERS:     
;
;               RETURNS:                NC  Version ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckVersion    Proc near
    call ClearPort
    jc cvDone
;    
    mov ds:td_out_buf,0F2h
    mov ds:td_out_buf+1,0
    mov ds:td_out_buf+2,0
    mov ds:td_out_buf+3,0
    mov ds:td_out_buf+4,0
    call SendCmd
    call GetResponse
    jc cvDone
;
    mov al,ds:td_in_buf
    cmp al,0F2h
    stc
    jne cvDone
;    
    mov al,ds:td_in_buf+1
    cmp al,0D9h
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
;           NAME:           HandleTouch
;
;           DESCRIPTION:    Handle touch-screen
;
;       PARAMETERS:     AL  Port
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleTouch:    
    CreateWait
    mov ds:td_wait,bx
;    
    mov ah,8
    mov bl,1
    mov bh,'N'
    mov ecx,19200
    mov si,256
    mov di,256
    OpenCom
    mov ds:td_port,bx
;
    mov ax,ds:td_port
    mov bx,ds:td_wait
    xor ecx,ecx
    AddWaitForCom
    ResetRts
    ResetDtr
;
    mov ax,50
    WaitMilliSec
;        
    SetRts
    SetDtr
;
    call CheckVersion    

htLoop:
    GetSystemTime
    add eax,10000 * 1192
    adc edx,0
    mov bx,ds:td_wait
    WaitWithTimeout
;
    mov bx,ds:td_port
    ReadCom
    jc htLoop

htSyn:    
    cmp al,0BFh
    mov ds:td_control,0
    je htOk
;
    cmp al,0FFh
    mov ds:td_control,1
    jne htLoop

htOk:    
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
    jnz htSyn
;
    and ax,7
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
    jnz htSyn
;
    or byte ptr ds:td_x,al
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
    jnz htSyn
;    
    and ax,7
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
    jnz htSyn
;
    or byte ptr ds:td_y,al
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
;
; upside-down touch
;
    not cx
;    not dx
    and ch,7Fh
    mov bx,cx
    shr bx,4
    add cx,bx
;    and dh,7Fh
;    
    SetMouse
    jmp htLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Touch_thread
;
;           DESCRIPTION:    Touch-screen thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

touch_name      DB 'PenMount',0

touch_thread:
    mov ax,500
    WaitMilliSec
;
    mov ax,touch_data_sel
    mov ds,ax
;
    mov al,COM_PORT    
    jmp HandleTouch

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
;           NAME:           INIT_TOUCH
;
;           DESCRIPTION:    Init touch
;
;           PARAMETERS:         
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
;           NAME:           INIT
;
;           DESCRIPTION:    Init touch-screen
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov eax,SIZE touch_data_seg
    mov bx,touch_data_sel
    AllocateFixedSystemMem
;
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
    
