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

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

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

	public init_task_tasks

init_task_tasks	Proc near
    mov eax,400h
    AllocateSmallLinear
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
	ret
init_task_tasks	Endp
	
code	ENDS

	END
