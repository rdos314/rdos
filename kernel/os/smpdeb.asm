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
INCLUDE system.def
INCLUDE system.inc
INCLUDE irq.inc
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE smpdeb.inc

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn InitKeyboardIrq:near
    extrn UpdateMode:near
    extrn ReadKeyboard:near
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           DelayMs
;
;               DESCRIPTION:    Delay that does not use multitasking functions
;
;       PARAMETERS:     AX      Delay in ms
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DelayMs Proc near
    push ds
    push es
    pushad
;
    mov dx,system_data_sel
    mov ds,dx
    movzx eax,ax
    mov ecx,1193
    mul ecx
;        
    mov ecx,ds:apic_tics
    shl ecx,16
    mov cx,ds:apic_rest
    shl eax,16
    mul ecx
    inc edx
;
    mov ax,apic_mem_sel
    mov es,ax    
    mov es:APIC_INIT_COUNT,edx

dmLoop:
    mov eax,es:APIC_CURR_COUNT
    or eax,eax
    jnz dmLoop
;       
    popad
    pop es
    pop ds
    ret
DelayMs Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Smp_deb_thread
;
;           DESCRIPTION:    SMP debug thread (for test purposes)
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

smp_deb_thread_name     DB 'SMP debug', 0
start_smp_debug_name    DB 'Start SMP Debug', 0

start_smp_debug:
    mov ax,250
    call DelayMs
;    
    call InitKeyboardIrq
    mov ax,__B800
    mov es,ax
    mov di,2*60
    sti

handle_loop:
    hlt
    ReadKeyboard
    jc handle_next
;    
    test ah,80h
    jnz handle_next
;    
    mov ah,7
    stosw

handle_next:        
    call UpdateMode
    jmp handle_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_thread
;
;           DESCRIPTION:    Create thread
;
;           PARAMETERS:         
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
    mov ax,1
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
;           NAME:           Init
;
;           DESCRIPTION:    Module initialization
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
;    HookInitTasking
;
    ret
init    ENDP

code    ENDS

    END init
