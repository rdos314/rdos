;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; DEBUG.ASM
; Kernel part kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE dis.inc

.386p
.387

data    SEGMENT byte public 'DATA'

buf    DB 4096 DUP(?)

cpu cpu_struc <>

data    ENDS

code    SEGMENT byte use32 public 'CODE'

    extrn GetCpu:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Debug process
;
;           DESCRIPTION:    Debug process
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_name          DB 'New Debug',0

debug_process:
    sti
    mov ax,41h
    EnableFocus
    int 3
;
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    mov ebp,OFFSET cpu
;
    finit
    fld tbyte ptr cs:val
;
    GetThread
    mov edi,OFFSET buf
    call GetCpu
;
    xor al,al
    stosb 
;
    mov edi,OFFSET buf
    WriteAsciiz   

marker_loop:
    mov ax,250
    WaitMilliSec
    jmp marker_loop    

val  DT 156.56

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_debug_process
;
;           DESCRIPTION:    Create kernel debugger process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_debug_process      PROC far
    push ds
    push es
    pushad
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET debug_process
    mov edi,OFFSET debug_name
    mov ecx,stack0_size
    mov ax,26
    CreateProcess
    popad
    pop es
    pop ds
    ret
init_debug_process      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov eax,cs
    mov ds,eax
    mov es,eax  
    mov edi,OFFSET init_debug_process
    HookInitTasking
    clc
    ret
init    Endp
    
code    ENDS

    END init
