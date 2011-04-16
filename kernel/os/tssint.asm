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
; TSSINT.ASM
; TSS gate handling
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE protseg.def


.386p

	extrn double_fault:near

code	SEGMENT byte use16 public 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_TSS_GATES
;
;           DESCRIPTION:    Init TSS gates
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


init_tss_gates_name DB 'Init TSS Gates', 0

init_tss_gates	Proc far
    push ds
    push es
    pushad
;    
    mov eax,400h
    AllocateSmallLinear
;
    mov bx,double_tss_sel
	mov ecx,400h
	CreateTssSelector
;
    mov bx,double_tss_data_sel
    mov ecx,400h
    CreateDataSelector16
    mov ds,bx
    mov es,bx
;    
    xor di,di
    mov cx,100h
    xor eax,eax
    rep stosd
;
    mov eax,200h
    AllocateSmallGlobalMem
    mov ds:tss_ss,es
    mov dword ptr ds:tss_esp,200h
    mov eax,cr3
    mov dword ptr ds:tss_cr3,eax
;
    mov ds:tss_bitmap, OFFSET tss_bitmap_space
    mov bx,3FFh
    mov byte ptr ds:[bx],-1    
;
    mov ds:tss_cs,cs
    mov dword ptr ds:tss_eip,OFFSET double_fault
;
	mov ax,idt_sel
	mov ds,ax
	mov bx,8 * 8
	mov word ptr [bx],0
	mov word ptr [bx+2],double_tss_sel
	mov byte ptr [bx+4],0
	mov byte ptr [bx+5],85h
	mov word ptr [bx+6],0    
;
    popad
    pop es
    pop ds
	retf32
init_tss_gates	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_TSS_INT
;
;           DESCRIPTION:    Init TSS int
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_tss_int

init_tss_int       PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET init_tss_gates
    mov edi,OFFSET init_tss_gates_name
    xor cl,cl
    mov ax,init_tss_gates_nr
    RegisterOsGate
    ret
init_tss_int    Endp
	
code	ENDS

	END
