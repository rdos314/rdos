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
; PROC.ASM
; Thread & process handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE ..\handle.inc
include proc.inc



    .386p

code    SEGMENT byte public use16 'CODE'

    extrn free_process_proc:word
    extrn init_double_fault:near
    extrn set_page_entry_proc:word

    assume cs:code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           NotifyEndProgram
;
;           DESCRIPTION:    Notify program end
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_end_program_name  DB 'Notify End Program',0

notify_end_program       PROC far
    ExitProcessApp
    retf32
notify_end_program       ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           NotifyInitTasking
;
;           DESCRIPTION:    Notify init tasking
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_init_tasking_name  DB 'Notify Init Tasking',0

notify_init_tasking       PROC far
    call init_double_fault
    retf32
notify_init_tasking       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_THREAD
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_thread

init_thread     PROC near
    pusha
    push ds
;
    mov edx,fixed_process_linear
    mov ecx,SIZE process_seg
    mov bx,process_sel
    CreateDataSelector16
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
;
    mov esi,OFFSET notify_end_program
    mov edi,OFFSET notify_end_program_name
    xor cl,cl
    mov ax,notify_end_program_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_init_tasking
    mov edi,OFFSET notify_init_tasking_name
    xor cl,cl
    mov ax,notify_init_tasking_nr
    RegisterOsGate
;
    pop ds
    popa
    ret
init_thread     ENDP

    
code    ENDS

    END

