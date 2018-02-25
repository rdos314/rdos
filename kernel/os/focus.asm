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

focus_current_console    DW ?
focus_section            section_typ <>

focus_console            DW 256 DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public 'CODE'

    assume cs:code

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
    mov bx,ds:[bx].focus_console
    or bx,bx
    jz set_focus_done
;    
    mov ds:focus_current_console,bx
    SetFocusConsole

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
;           PARAMETERS:     AL      KEY NUMBER
;
;       RETURNS:            AL      Actual key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_focus_name       DB 'Enable Focus',0

enable_focus    PROC far
    push ds
    push bx
    push si
;
    mov bx,SEG data
    mov ds,bx
;
    movzx si,al
    add si,si

enable_focus_loop:
    mov bx,ds:[si].focus_console
    or bx,bx
    jnz enable_focus_next
;
    CreateConsole
    mov ds:[si].focus_console,bx
;
    GetThread
    mov ds,ax
    mov ds:p_console,bx
;
    mov ax,si
    shr ax,1
    clc
    jmp enable_focus_done

enable_focus_next:
    add si,2
    cmp si,200h
    jne enable_focus_loop
;
    stc

enable_focus_done:
    pop si
    pop bx
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
    mov edi,OFFSET focus_console
    mov ecx,256
    xor ax,ax
    rep stosw
    mov ds:focus_current_console,0
    InitSection ds:focus_section
;
    mov ax,cs
    mov ds,ax
    mov es,ax
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
    ret
init_focus      ENDP

code    ENDS

END

