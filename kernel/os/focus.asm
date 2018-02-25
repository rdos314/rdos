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
; FOCUS.ASM
; Virtual console handling
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc

data    SEGMENT byte public 'DATA'

focus_thread            DW 256 DUP(?)

focus_current_thread    DW ?
focus_section           section_typ <>

data    ENDS

    .386p

code    SEGMENT byte public 'CODE'

    assume cs:code

    extrn CreateConsole:near
    extrn DisableConsoleFocus:near
    extrn EnableConsoleFocus:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetFocusThread
;
;           DESCRIPTION:    Get focus thread
;
;           RETURNS:        AX          Focus thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_focus_thread_name   DB 'Get Focus Thread',0

get_focus_thread    PROC far
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:focus_current_thread
    pop ds
    ret
get_focus_thread    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetThreadFocusKey
;
;           DESCRIPTION:    Get thread switch key
;
;           PARAMETERS:         BX          Thread
;
;           RETURNS:        AL          Switch key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_focus_key_name       DB 'Get Thread Focus Key',0

get_thread_focus_key    PROC far
    push ds
    push cx
    push si
;
    mov ax,SEG data
    mov ds,ax
    mov cx,256
    mov si,OFFSET focus_thread

get_thread_key_loop:
    cmp bx,[si]
    je get_thread_key_ok
;
    add si,2
    sub cx,1
    jnz get_thread_key_loop
;
    xor ax,ax
    stc
    jmp get_thread_key_done

get_thread_key_ok:
    mov ax,si
    sub ax,OFFSET focus_thread
    shr ax,1
    clc

get_thread_key_done:
    pop si
    pop cx
    pop ds
    ret
get_thread_focus_key    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Free_thread
;
;           DESCRIPTION:    Handle thread termination
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_thread     Proc far
    mov bx,SEG data
    mov ds,bx
    mov bx,OFFSET focus_thread
    mov cx,100h
    GetThread

free_thread_loop:
    cmp ax,[bx]
    jne free_thread_next
;
    mov word ptr [bx],0
    cmp ax,ds:focus_current_thread
    jne free_thread_done
;
    mov ds:focus_current_thread,0
    jmp free_thread_done

free_thread_next:
    add bx,2
    sub cx,1
    jnz free_thread_loop

free_thread_done:
    ret
free_thread     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_FOCUS
;
;           DESCRIPTION:    Set input focus
;
;           PARAMETERS:     AL      KEY NUMBER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_focus_name  DB 'Set Focus',0

set_focus       PROC far
    push ds
    push es
    pushad
;
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:focus_section
;
    movzx bx,al
    add bx,bx
    mov ax,ds:[bx].focus_thread
    or ax,ax
    jz set_focus_done
;
    call DisableConsoleFocus
;    
    mov ds:focus_current_thread,ax
    mov es,ax
    mov bx,es:p_console
    or bx,bx
    jz set_focus_done
;
    call EnableConsoleFocus

set_focus_done:
    LeaveSection ds:focus_section
;
    popad
    pop es
    pop ds
    ret
set_focus       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ENABLE_FOCUS
;
;           DESCRIPTION:    Enable focus
;
;           PARAMETERS:         AL      KEY NUMBER
;
;       RETURNS:    Actual key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_focus_name       DB 'Enable Focus',0

enable_focus    PROC far
    push ds
    push es
    push bx
;
    mov bx,SEG data
    mov ds,bx
    xor bh,bh
    mov bl,al
    GetThread
    add bx,bx

enable_focus_loop:
    cmp ds:[bx].focus_thread,0
    jne enable_focus_next
;
    mov ds:[bx].focus_thread,ax
    jmp enable_focus_done

enable_focus_next:
    add bx,2
    cmp bx,200h
    jne enable_focus_loop

enable_focus_done:
    call CreateConsole
;
    mov ax,bx
    shr ax,1
    pop bx
    pop es
    pop ds
    ret
enable_focus    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init driver
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_focus
    
init_focus      PROC near
    mov bx,SEG data
    mov es,bx
    mov ds,bx
    mov edi,OFFSET focus_thread
    mov ecx,256
    xor ax,ax
    rep stosw
    mov ds:focus_current_thread,0
    InitSection ds:focus_section
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET free_thread
    HookTerminateThread
;
    mov esi,OFFSET set_focus
    mov edi,OFFSET set_focus_name
    xor dx,dx
    mov ax,set_focus_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET enable_focus
    mov edi,OFFSET enable_focus_name
    xor dx,dx
    mov ax,enable_focus_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_focus_thread
    mov edi,OFFSET get_focus_thread_name
    xor cl,cl
    mov ax,get_focus_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET get_thread_focus_key
    mov edi,OFFSET get_thread_focus_key_name
    xor cl,cl
    mov ax,get_thread_focus_key_nr
    RegisterOsGate
    ret
init_focus      ENDP

code    ENDS

END

