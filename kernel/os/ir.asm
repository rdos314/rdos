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

IR_BUF_SIZE = 512

ir_seg    STRUC

ir_section  section_typ <>

ir_count	  	DW ?
ir_head		    DW ?
ir_tail		    DW ?
ir_buf          DB IR_BUF_SIZE DUP(?)

ir_seg    ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddVal
;
;		DESCRIPTION:	Add value to in-buffer
;
;		PARAMETERS:		AL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddVal  Proc near
    push bx
    push cx
;    
	mov cx,ds:ir_count
	cmp cx,IR_BUF_SIZE
	je avDone
;	
	inc cx
	mov ds:ir_count,cx
;	
	mov bx,ds:ir_tail		; get tail pointer
	mov ds:[bx].ir_buf,al				; store char
	inc bx
	cmp bx,IR_BUF_SIZE
	jnz avSavePtr
;
	xor bx,bx
	
avSavePtr:
	mov ds:ir_tail,bx

avDone:
    pop cx
    pop bx
    ret
AddVal  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NotifyIrData
;
;		DESCRIPTION:	Notify new IR data
;
;		PARAMETERS:		ES:DI       Data buffer
;                       CX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_ir_data_name	DB 'Notify IR data',0

notify_ir_data	Proc far
    push ds
    push ax
    push cx
    push esi
    push di
;    
    mov ax,ir_data_sel
    mov ds,ax
    mov esi,OFFSET ir_section
    EnterSection
;
    or cx,cx
    jz nidLeave

nidLoop:    
    mov al,es:[di]
    call AddVal
    inc di        
    loop nidLoop

nidLeave:
    mov esi,OFFSET ir_section
    LeaveSection
;
    pop di
    pop esi
    pop cx
    pop ax
    pop ds            
	ret
notify_ir_data	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ir
;
;		DESCRIPTION:    IR handler thread
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ir_name DB 'IR', 0

ir_thread:
    int 3
    mov ax,ir_data_sel
    mov ds,ax
    mov bx,OFFSET ir_buf
    mov cx,ds:ir_count

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_ir
;
;		DESCRIPTION:    init IR module
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
init_ir	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET ir_name
	mov si,OFFSET ir_thread
	mov ax,4
	mov cx,100h
	CreateThread
;	
	popa
	pop es
	pop ds
	ret
init_ir	Endp

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
    mov esi,OFFSET ir_section
    InitSection
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_ir
	HookInitTasking
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
