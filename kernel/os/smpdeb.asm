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
; SMPDEB.ASM
; SMP debugger/monitor module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.inc
INCLUDE irq.inc

        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   KeyboardInt
;
;               DESCRIPTION:    Keyboard int
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

KeyboardInt:
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   InitKeyboardIrq
;
;               DESCRIPTION:    Init keyboard IRQ
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitKeyboardIrq Proc near
    push ds
    push esi
;
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET KeyboardInt
    mov al,29h
    xor bl,bl
    CreateIntGateSelector
;    
    mov ax,irq_sys_sel
    mov ds,ax
    mov si,OFFSET irq_arr + SIZE irq_struc
    EnterSection ds:[si].usage_section
    mov word ptr ds:[si].user_data,0
    mov dword ptr ds:[si].user_handler,0
;
    mov al,1
    call ds:[si].irq_enable_proc    
;
    pop esi
    pop ds
    ret
InitKeyboardIrq Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Smp_deb_thread
;
;               DESCRIPTION:    SMP debug thread (for test purposes)
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

smp_deb_thread_name     DB 'SMP debug', 0
start_smp_debug_name    DB 'Start SMP Debug', 0

start_smp_debug:
    int 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Init_thread
;
;               DESCRIPTION:    Create thread
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread     Proc far
        push ds
        push es
        pushad
;
        mov ax,cs
        mov ds,ax
        mov es,ax
        mov si,OFFSET start_smp_debug
        mov di,OFFSET smp_deb_thread_name
        mov ax,3
        mov cx,256
        CreateThread
;
        popad
        pop es
        pop ds
init_thread     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:               Init
;
;               DESCRIPTION:    Module initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov si,OFFSET start_smp_debug
        mov di,OFFSET start_smp_debug_name
        xor cl,cl
        mov ax,start_smp_debug_nr
        RegisterOsGate
;
        mov di,OFFSET init_thread
        HookInitTasking
;
        ret
init    ENDP

code    ENDS

        END init
