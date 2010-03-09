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
; MP.ASM
; Multiprocessing module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME mp

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE mp.inc

mp_data_seg	STRUC

mp_thread   DW ?

mp_data_seg ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			mp_pr
;
;		DESCRIPTION:	MP test thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mp_name	DB 'MP Test',0

mp_pr:
    int 3
;	
	cli
;
    mov al,0Fh
    out 70h,al
	jmp short $+2
;
    in al,71h	
	jmp short $+2
    sti
    int 3



    mov eax,100000h
    AllocateBigLinear
;
    mov cx,100h
    mov eax,63h
    push edx

alloc_loop:
    SetPhysicalPage
    add eax,1000h
    add edx,1000h
    loop alloc_loop
;
    pop edx    
    AllocateGdt
    mov ecx,100000h
    CreateDataSelector32
    mov gs,bx
;
    mov eax,05F504D5Fh
;
    mov ebx,40Eh
    mov bx,gs:[bx]
    movzx ebx,bx
    shl ebx,4
;    
;    mov ebx,09FC00h
    mov cx,40h

find_mp_bda:
    cmp eax,gs:[ebx]
    je find_ok
;
    add ebx,10h
    loop find_mp_bda
;    
    mov ebx,0E0000h
    mov cx,2000h

find_mp_bios:
    cmp eax,gs:[ebx]
    je find_ok
;
    add ebx,10h
    loop find_mp_bios
;
    int 3
    stc
    jmp find_fail

find_ok:
    int 3
    mov eax,gs:[ebx]

find_fail:
    int 3
            

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_mp_thread
;
;		DESCRIPTION:	Init mp threads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mp_thread	PROC far
	push ds
	push es
	pusha
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET mp_pr
	mov di,OFFSET mp_name
	mov cx,500
	mov ax,4
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_mp_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitMpGates
;
;		DESCRIPTION:	Init mp module call-gates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_mp_gates
    
init_mp_gates	PROC near
    push ds
    push es
    pusha
;    
	mov ax,cs
	mov ds,ax
	mov es,ax
;
    popa
    pop es
    pop ds	
	ret
init_mp_gates	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitMpTasks
;
;		DESCRIPTION:	Init mp module tasks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_mp_tasks
    
init_mp_tasks	PROC near
    push ds
    push es
    pusha
;
	mov eax,SIZE mp_data_seg
	mov bx,mp_data_sel
	AllocateFixedSystemMem
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET init_mp_thread
	HookInitTasking
;
    popa
    pop es
    pop ds	
	ret
init_mp_tasks	ENDP


code	ENDS

	END
