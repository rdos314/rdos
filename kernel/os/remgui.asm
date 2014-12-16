;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; REMGUI.ASM
; Remote GUI interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\user.def
INCLUDE ..\os.inc
INCLUDE ..\user.inc
INCLUDE system.def

    .386p

data    SEGMENT byte public 'DATA'

MailslotHandle          DW ?

data    ENDS

code    SEGMENT byte public 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           DebugThread
;
;               DESCRIPTION:    Debug thread
;
;               PARAMETERS:     EDX     IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rem_gui_name   DB 'Remote GUI', 0
mailslot_name       DB 'GUI',0

rem_gui_process:
    mov ax,44h
    EnableFocus
    SetFocus
;    
    int 3
    mov ax,SEG data
    mov ds,ax
;
    or edx,edx
    jz rem_gui_local
;    
    mov ax,cs
    mov es,ax
    mov di,OFFSET mailslot_name
    GetRemoteMailslot
    mov ds:MailslotHandle,bx
    jmp rem_gui_init

rem_gui_local:
    mov ax,cs
    mov es,ax
    mov di,OFFSET mailslot_name
    GetLocalMailslot
    mov ds:MailslotHandle,bx

rem_gui_init: 
    int 3
    jmp rem_gui_init

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           RemoteGui
;
;               DESCRIPTION:    Remote GUI task
;
;               PARAMETERS:     EDX     IP address to debug
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remote_gui_name   DB 'Remote Gui', 0

remote_gui    Proc far
    push ds
    push es
    pusha
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET rem_gui_process
    mov edi,OFFSET rem_gui_name
    mov ecx,stack0_size
    mov ax,5
    CreateProcess
    popa
    pop es
    pop ds
    ret
remote_gui    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_remote
;
;           DESCRIPTION:    Init remote GUI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_remote

init_remote Proc near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET remote_gui
    mov edi,OFFSET remote_gui_name
    xor dx,dx
    mov ax,remote_gui_nr
    RegisterBimodalUserGate
    ret
init_remote    Endp

code    ENDS

    END
