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
; SERKEY.ASM
; Basic serial keyboard support module.
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

ext_key      DW ?
key_state    DW ?
virt_key     DB ?
scan_code    DB ?
press_type   DB ?

msg          DB 14 DUP(?)

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
;       Name:           DecodeHexByte
;
;       Purpose:        Get hex byte from string
;
;       Parameters:     DS:SI       String in
;
;       Returns:        DS:SI       String out
;                       NC          OK
;                           AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeHexByte Proc near
    push dx
;
    xor dl,dl
    lodsb
    sub al,'0'
    jc dbFail
;
    cmp al,10
    jb dbSave1
;
    sub al,7
    jc dbFail
;
    cmp al,10h
    jae dbFail

dbSave1:
    shl al,4
    mov dl,al
;
    lodsb
    sub al,'0'
    jc dbFail
;
    cmp al,10
    jb dbSave2
;
    sub al,7
    jc dbFail
;
    cmp al,10h
    jae dbFail

dbSave2:
    or al,dl
    clc
    jmp dbDone

dbFail:
    stc

dbDone:
    pop dx    
    ret
DecodeHexByte    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DecodeHexWord
;
;       Purpose:        Get hex word from string
;
;       Parameters:     DS:SI       String in
;
;       Returns:        DS:SI       String out
;                       NC          OK
;                           AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeHexWord Proc near
    push dx
;
    call DecodeHexByte
    jc dhwDone
;
    mov dl,al
    call DecodeHexByte
    jc dhwDone
;
    mov ah,dl
    clc

dhwDone:
    pop dx
    ret
DecodeHexWord Endp
            
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
    or ax,ax
    stc
    jz opDone
;
    dec al
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReadPort
;
;       Purpose:        Read a single char from serial port
;
;       Returns:        AL	Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPort Proc near
    push bx
    push ecx
;
    mov bx,ds:wait_handle
    WaitWithoutTimeout
;
    mov bx,ds:com_handle
    ReadCom
;
    pop ecx
    pop bx
    ret
ReadPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetMsg
;
;       Purpose:        Get a message
;
;       Returns:        NC    OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMsg Proc near
    push ax
    push cx
    push di
;
    mov di,OFFSET msg
    mov cx,14

gmLoop:
    call ReadPort
    cmp al,0Dh
    je gmWaitLf
;
    stosb
    loop gmLoop
;
    stc
    jmp gmDone

gmWaitLf:
    call ReadPort
    cmp al,0Ah
    stc
    jne gmDone
;
    cmp cx,1
    stc
    jne gmDone
;
    xor al,al
    stosb
    clc

gmDone:
    pop di
    pop cx
    pop ax
    ret
GetMsg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;    NAME:		keyboard_thread
;
;    DESCRIPTION:	Keyboard thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

keyboard_name DB 'Serial Keyboard', 0

keyboard_pr:
    mov ax,500
    WaitMilliSec
;
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    call OpenPort
    jc ktDone

ktLoop:
    call GetMsg
    jc ktLoop
;
    mov si,OFFSET msg
    lodsb
    mov ds:press_type,al
;
    call DecodeHexWord   
    jc ktLoop
;
    mov ds:ext_key,ax
;
    call DecodeHexWord
    jc ktLoop
;
    mov ds:key_state,ax
;
    call DecodeHexByte
    jc ktLoop
;
    mov ds:virt_key,al
;
    call DecodeHexByte
    jc ktLoop
;
    mov ds:scan_code,al
;
    mov ax,ds:key_state
    SetKeyboardState
;
    mov ax,ds:ext_key
    xchg al,ah
    mov dl,ds:virt_key
    mov dh,ds:scan_code
    mov cl,ds:press_type
    cmp cl,'P'
    je ktSend
;
    cmp cl,'R'
    jne ktLoop
;
    or al,80h
    or dh,80h

ktSend:
    PutKeyboardCode
;
    mov al,'P'
    jne ktLoop
;    
    mov ax,ds:key_state
    test ax,2
    jz ktLoop
;
    mov al,ds:scan_code
    cmp al,3Bh
    jc ktLoop
;
    cmp al,44h
    ja ktLoop
;
    SetFocus
    jmp ktLoop

ktDone:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;    NAME:		init_keyb_thread
;
;    DESCRIPTION:	Init keyboard threads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_keyb_thread	PROC far
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET keyboard_pr
    mov edi,OFFSET keyboard_name
    mov ecx,stack0_size
    mov ax,4
    CreateThread
;
    popad
    pop es
    pop ds
    retf32
init_keyb_thread	ENDP

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
    mov edi,OFFSET init_keyb_thread
    HookInitTasking
    ret
init	ENDP

code	ENDS

    END init
