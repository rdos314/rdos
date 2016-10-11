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
; KDEBUG.ASM
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

    extrn DisAsmCode:near


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Read_mem
;
;           DESCRIPTION:    Read memory in process
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           DS:EBP      Cpu
;
;           RETURNS:        NC  AL  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_mem    Proc near
    push bx
;
    mov bx,ds:[ebp].cpu_thread        
    test word ptr ds:[ebp].reg_eflags+2,2
    jz rdmProt

rdmV86:
    ReadThreadSegment
    jmp rdmDone
    
rdmProt:
    test ds:[ebp].reg_cs.d_access,ACCESS_64
    jnz rdm64

rdm32:    
    ReadThreadSelector
    jmp rdmDone

rdm64:
    ReadThread64

rdmDone:
    pop bx
    ret
read_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Write_mem
;
;           DESCRIPTION:    Write memory in process
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           BX          Thread
;                           DS:EBP      Cpu
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_mem    Proc near
    push bx
;
    mov bx,ds:[ebp].cpu_thread        
    test word ptr ds:[ebp].reg_eflags+2,2
    jz wrmProt

wrmV86:
    WriteThreadSegment
    jmp wrmDone
    
wrmProt:
    test ds:[ebp].reg_cs.d_access,ACCESS_64
    jnz wrm64
    
wrm32:    
    WriteThreadSelector
    jmp wrmDone

wrm64:
    WriteThread64

wrmDone:
    pop bx
    ret
write_mem    Endp

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
    GetThread
    mov ds:[ebp].cpu_thread,ax
    mov ds:[ebp].cpu_read_mem,OFFSET read_mem
    mov ds:[ebp].cpu_write_mem,OFFSET write_mem
;    
    mov bx,cs
    mov ds:[ebp].reg_eip,OFFSET debug_process
    mov ds:[ebp].reg_eip+4,0
    mov ds:[ebp].reg_cs.d_selector,bx
    GetSelectorBitness
    cmp al,16
    je dis16
;
    cmp al,32
    je dis32

dis64:
    mov ds:[ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_64
    jmp disdo

dis32:
    mov ds:[ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_32
    jmp disdo

dis16:
    mov ds:[ebp].reg_cs.d_access,ACCESS_READ

disdo:    
    mov edi,OFFSET buf
    mov ecx,40

dis_next:    
    call DisAsmCode
    add ds:[ebp].reg_eip,eax
    jmp dis_next

marker_loop:
    mov ax,250
    WaitMilliSec
    jmp marker_loop

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
