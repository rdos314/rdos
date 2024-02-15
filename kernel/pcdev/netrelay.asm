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
; netrelay.ASM
; Network relay support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc

data    SEGMENT byte public 'DATA'

dum    DB ?

data    ENDS

    .386p

code    SEGMENT byte public use32 'CODE'

    assume cs:code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetIPNumber
;
;       Purpose:        received IP data
;
;       Parameters:         ES:DI   Name
;
;       Returns:        NC          Found
;                       EAX         IP number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIPNumber     Proc near
    push ds
    push ebx
    push cx
    push si
;
    LockSysEnv
    mov ds,bx
    xor si,si
find_ip:
    push di
find_ip_loop:
    cmpsb
    jnz find_ip_next
    mov al,es:[di]
    or al,al
    jnz find_ip_loop
    mov al,[si]
    cmp al,'='
    je find_ip_found

find_ip_next:
    pop di

find_ip_next_bp:
    lodsb
    or al,al
    jnz find_ip_next_bp
    mov al,[si]
    or al,al
    jne find_ip
    xor eax,eax
    stc
    jmp find_ip_done

find_ip_found:
    pop di
    xor ebx,ebx
    inc si
    mov cx,4
find_ip_decode:
    xor al,al
find_ip_digit:
    mov dl,[si]
    inc si
    sub dl,'0'
    jc find_ip_save
    cmp dl,10
    jnc find_ip_save
    mov ah,10
    mul ah
    add al,dl
    jmp find_ip_digit

find_ip_save:
    mov bl,al
    ror ebx,8
    loop find_ip_decode         
;
    mov eax,ebx
    clc

find_ip_done:
    pushf
    UnlockSysEnv
    popf
;
    pop si
    pop cx
    pop ebx
    pop ds
    ret
GetIPNumber     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_relay_thread
;
;           DESCRIPTION:    Init_relay_thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_relay_thread_name DB 'Init Relay', 0

init_relay_thread Proc far
    int 3
    ret
init_relay_thread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_relay
;
;           DESCRIPTION:    Create hook thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_relay    Proc far
    push ds
    push es
    pushad
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET init_relay_thread
    mov di,OFFSET init_relay_thread_name
    mov ax,3
    mov cx,stack0_size
    CreateThread
;
    popad
    pop es
    pop ds
    ret
init_relay    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init
;
;           DESCRIPTION:    INIT net relay DEVICE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_relay
    HookInitTasking
;
    clc
    ret
init    Endp

code    ENDS

    END init
