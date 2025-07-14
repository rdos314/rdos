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
; DMC6000.ASM
; Support for PenMount DMC6000 touch-screen
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
td_max          DW ?
td_state        DB ?
compat          DB ?

x_start         DW ?
y_start         DW ?
x_size          DW ?
y_size          DW ?

td_out_buf      DB 6 DUP(?)
td_in_buf       DB 6 DUP(?)

data    ENDS

        .386p

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
    push cx
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
    pop cx 
    ret
CheckVersion    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetScaling
;
;               DESCRIPTION:    Get scaling
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetScaling    Proc near
    push cx
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
    pop cx
    ret
GetScaling    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EnableController
;
;               DESCRIPTION:    Enable controller
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnableController    Proc near
    push cx
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
    pop cx
    ret
EnableController    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Touch_thread
;
;               DESCRIPTION:    Touch-screen thread
;
;       PARAMETERS:     BL      Com port 
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

touch_thread    Proc far
    push bx
    mov ax,500
    WaitMilliSec
;
    mov eax,1000h
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
    mov cx,16

ttRetry:
    call CheckVersion
    jc ttNext
;
    call GetScaling    
    jc ttNext
;    
    call EnableController
    jnc ttStart

ttNext:
    loop ttRetry
;
    jmp ttEnd        

ttStart:
    mov si,ds:td_port
    mov di,ds:td_wait
    mov ax,ds
    mov es,ax
    mov ax,SEG data
    mov ds,ax
    FreeMem
    mov ds:td_port,si
    mov ds:td_wait,di
;    
    call GetScaling    
    call EnableController

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
    cmp ds:compat,0
    jnz ttCompat
;
    mov ax,word ptr ds:td_in_buf+1
    mov ds:td_x,ax
    mov ax,word ptr ds:td_in_buf+3
    mov ds:td_y,ax
;    
; custom scaling
;
    mov cx,ds:td_x
    sub cx,ds:x_start
    jnc ttXMinOk
;
    xor cx,cx

ttXMinOk:
    cmp cx,ds:x_size
    jb ttXMaxOk
;
    mov cx,ds:x_size

ttXMaxOk:
    xor dx,dx
    mov ax,7FFFh
    mul cx
    mov cx,ds:x_size
    div cx
    mov ds:td_x,ax
;
    mov cx,ds:td_y
    sub cx,ds:y_start
    jnc ttYMinOk
;
    xor cx,cx

ttYMinOk:
    cmp cx,ds:y_size
    jb ttYMaxOk
;
    mov cx,ds:y_size

ttYMaxOk:
    xor dx,dx
    mov ax,7FFFh
    mul cx
    mov cx,ds:y_size
    div cx
    mov ds:td_y,ax
    jmp ttProcess

ttCompat:
    mov cx,ds:td_max
    mov ax,word ptr ds:td_in_buf+1
    cmp ax,cx
    jae ttLoop
;    
    sub cx,ax
    xor dx,dx
    mov ax,7FFFh
    mul cx
    mov cx,ds:td_max
    div cx
    mov ds:td_x,ax
;
    mov cx,ds:td_max
    mov ax,word ptr ds:td_in_buf+3
    cmp ax,cx
    jae ttLoop
;    
    sub cx,ax
    xor dx,dx
    mov ax,7FFFh
    mul cx
    mov cx,ds:td_max
    div cx
    mov ds:td_y,ax

ttProcess:    
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

touch_name3     DB 'PenMount COM3',0
touch_name4     DB 'PenMount COM4',0

init_touch      Proc far
        push ds
        push es
;
    mov bx,2
        mov ax,cs
        mov ds,ax
        mov es,ax
        mov di,OFFSET touch_name3
        mov si,OFFSET touch_thread
        mov ax,4
        mov cx,stack0_size
        CreateThread
;
    mov bx,3
        mov ax,cs
        mov ds,ax
        mov es,ax
        mov di,OFFSET touch_name4
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
    mov ds:compat,1
;
    call GetValue
    or ax,ax
    jz init_done
;
    mov ds:compat,0
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
    jz init_done
;
    mov ds:y_size,ax

init_done:
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
