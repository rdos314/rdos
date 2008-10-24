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
; IR.ASM
; IR support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME ir

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc

	.386p

IR_BUF_SIZE = 16

ir_seg    STRUC

ir_section  section_typ <>

ir_wr_ind   DW ?
ir_rd_ind   DW ?

ir_sel_arr  DW IR_BUF_SIZE DUP(?)

ir_seg    ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NotifyIrData
;
;		DESCRIPTION:	Notify new IR data
;
;		PARAMETERS:		ES      IR data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_ir_data_name	DB 'Notify IR data',0

notify_ir_data	Proc far
    push ds
    push es
    push ax
    push bx
    push dx
;    
    mov ax,ir_data_sel
    mov ds,ax
;
    EnterSection ds:ir_section
;    
    mov bx,ds:ir_wr_ind
    add bx,bx
    mov ax,es
    mov dx,ds:[bx].ir_sel_arr
    or dx,dx
    jz nidSave
;
    mov es,dx
    FreeMem

nidSave:
    mov ds:[bx].ir_sel_arr,ax
    mov bx,ds:ir_wr_ind
    inc bx
    cmp bx,IR_BUF_SIZE
    jne nidSaveInd
;
    xor bx,bx

nidSaveInd:
    mov ds:ir_wr_ind,bx
    LeaveSection ds:ir_section
;
    pop dx
    pop bx
    pop ax
    pop es
    pop ds            
	ret
notify_ir_data	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init
;
;		DESCRIPTION:	Init IR module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
	mov bx,ir_code_sel
	InitDevice
;
	mov eax,SIZE ir_seg
	mov bx,ir_data_sel
	AllocateFixedSystemMem
	mov ds,bx
	mov es,bx
	mov cx,SIZE ir_seg
	xor al,al
	xor di,di
	rep stosb
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET notify_ir_data
	mov di,OFFSET notify_ir_data_name
	xor cl,cl
	mov ax,notify_ir_data_nr
	RegisterOsGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
