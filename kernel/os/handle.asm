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
; HANDLE.ASM
; User level handles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  handle

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc
INCLUDE handle.inc

MAX_HANDLES = 400h

handle_block	STRUC
hf_prev	DW ?
hf_next	DW ?
hs_prev	DW ?
hs_next	DW ?
handle_block	ENDS

handle_seg	STRUC

handle_section	section_typ <>

handle_list	DW ?
handle_arr	DW MAX_HANDLES DUP (?)

handle_seg	ENDS

handle_info	STRUC

hi_link		DW ?
hi_sign		DW ?
hi_delete	DD ?

handle_info	ENDS

handle_data_seg	STRUC

hd_list		DW ?

handle_data_seg	ENDS

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RegisterHandle
;
;		DESCRIPTION:	Register a handle
;
;		PARAMETERS:		AX		Signature
;				 		ES:DI	Delete callback
;					
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_handle_name	DB 'Register Handle',0

register_handle	PROC far
	push ds
	push es
	push ax
;
	push es
	push eax
	mov eax,SIZE handle_info
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
	pop eax
	pop es
	mov ds:hi_sign,ax
	mov word ptr ds:hi_delete,di
	mov word ptr ds:hi_delete+2,es
;
	mov ax,handle_data_sel
	mov es,ax
	mov ax,es:hd_list
	mov ds:hi_link,ax
	mov es:hd_list,ds
;
	pop ax
	pop es
	pop ds
	ret
register_handle	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			allocate_handle_mem
;
;		DESCRIPTION:	Allocate memory for handle
;
;		PARAMETERS:		AX		Total size of memory block
;
;		RETURNS:		DS:BX	Address to memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_handle_mem	Proc near
	push ax
	push cx
	push si
	push di
;
	add ax,8
	mov si,handle_mem_sel
	mov ds,si
	xor si,si
	xor bx,bx
	mov si,[si].hf_next

allocate_mem_loop:
	mov cx,[si].hs_next
	sub cx,si
	cmp cx,ax
	jnc allocate_mem_found
;
	mov bx,si
	mov si,[si].hf_next
	jmp allocate_mem_loop

allocate_mem_found:
	sub cx,ax
	cmp cx,8
	jc allocate_mem_no_split
;
	mov bx,ax
	add bx,si
;	
	mov di,[si].hs_next
	mov [bx].hs_next,di
	mov [bx].hs_prev,si
	mov [si].hs_next,bx
	mov [di].hs_prev,bx
;
	mov di,[si].hf_next
	mov [bx].hf_next,di
	mov [si].hf_next,bx
	or di,di
	jz allocate_mem_last_free
;
	mov [di].hf_prev,bx

allocate_mem_last_free:
	mov di,[si].hf_prev
	mov [bx].hf_prev,di
	or di,di
	jz allocate_mem_fixup
;
	mov [di].hf_next,bx
	jmp allocate_mem_fixup

allocate_mem_no_split:
	mov di,[si].hf_prev
	mov bx,[si].hf_next
	mov [di].hf_next,bx
	mov [bx].hf_prev,di

allocate_mem_fixup:
	xor di,di
	mov bx,[di].hf_next
	cmp bx,si
	jnz allocate_mem_final
;
	mov bx,[si].hf_next
	mov [di].hf_next,bx

allocate_mem_final:
	xor di,di
	mov bx,[di].hs_prev
	mov cx,[si].hs_next
	cmp bx,cx
	jnc allocate_mem_no_biggest_block
;
	mov [di].hs_prev,cx

allocate_mem_no_biggest_block:	
	dec di
	mov [si].hf_prev,di
	mov [si].hf_next,di
;
	lea bx,[si+8]
;
	pop di
	pop si
	pop cx
	pop ax
	ret
allocate_handle_mem	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			free_handle_mem
;
;		DESCRIPTION:	Free memory for handle
;
;		PARAMETERS:		DS:BX		Offset to memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_handle_mem	PROC near
	push bx
	push si
	push di
;
	mov si,bx
	sub si,8
	mov di,[si].hs_prev
	or di,di
	jz free_handle_no_merge_down
;
	mov di,[di].hf_next
	inc di
	or di,di
	jz free_handle_no_merge_down
;
	mov di,si
	mov si,[di].hs_prev
	mov bx,[di].hs_next
	mov [si].hs_next,bx
	mov [bx].hs_prev,si
	jmp free_handle_test_up

free_handle_no_merge_down:
	xor di,di
	mov [si].hf_prev,di
	mov bx,[di].hf_next
	mov [si].hf_next,bx
	mov [di].hf_next,si
	mov [bx].hf_prev,si

free_handle_test_up:
	mov di,[si].hs_next
	mov di,[di].hf_prev
	inc di
	or di,di
	jz free_handle_no_merge_up
;
	push si
	mov si,[si].hs_next
	mov di,[si].hf_prev
	mov bx,[si].hf_next
	or di,di
	jz fm1_handle_bypass
;
	mov [di].hf_next,bx

fm1_handle_bypass:
	or bx,bx
	jz fm2_handle_bypass
;
	mov [bx].hf_prev,di

fm2_handle_bypass:
	xor di,di
	mov bx,[di].hf_next
	cmp bx,si
	jne fm3_handle_bypass
;
	mov bx,[bx].hf_next
	mov [di].hf_next,bx

fm3_handle_bypass:
	pop si
	mov bx,[si].hs_next
	mov bx,[bx].hs_next
	mov [bx].hs_prev,si
	mov [si].hs_next,bx

free_handle_no_merge_up:
	xor di,di
	mov bx,[di].hs_prev
	mov di,[si].hs_next
	cmp di,bx
	jc free_handle_not_limit_page
;
	mov di,bx
	add di,1000h
	xor bx,bx
	mov [bx].hs_prev,si

free_handle_not_limit_page:
	pop di
	pop si
	pop bx
	ret
free_handle_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateHandle
;
;		DESCRIPTION:	Allocate a handle
;
;		PARAMETERS:		CX		Size of data
;					
;
;		RETURNS:		DS:BX	Address to handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_handle_name	DB 'Allocate Handle',0

allocate_handle	PROC far
	push ax
	push si
;
	mov si,handle_sel
	mov ds,si
	EnterSection ds:handle_section
	mov ax,cx
	call allocate_handle_mem
	mov [bx].hh_sign,0
;
	mov ax,handle_sel
	mov ds,ax
	mov si,ds:handle_list
	mov ax,[si]
	mov ds:handle_list,ax
	mov [si],bx
	LeaveSection ds:handle_section
;	
	mov ax,handle_mem_sel
	mov ds,ax
;
	sub si,OFFSET handle_arr
	shr si,1
	mov [bx].hh_handle,si
;
	pop si
	pop ax
	ret
allocate_handle	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeHandle
;
;		DESCRIPTION:	Free a handle
;
;		PARAMETERS:		BX		Offset to handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_handle_name	DB 'Free Handle',0

free_handle	PROC far
	push ds
	push ax
	push si
;
	mov ax,handle_sel
	mov ds,ax
	EnterSection ds:handle_section
	mov ax,handle_mem_sel
	mov ds,ax
	mov si,[bx].hh_handle
	call free_handle_mem
	mov [bx].hh_sign,0
	mov [bx].hh_handle,0
;
	mov ax,handle_sel
	mov ds,ax
	shl si,1
	add si,OFFSET handle_arr
	mov ax,ds:handle_list
	mov [si],ax
	mov ds:handle_list,si
	LeaveSection ds:handle_section
	xor bx,bx
;
	pop si
	pop ax
	pop ds
	ret
free_handle	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DerefHandle
;
;		DESCRIPTION:	Deref a handle
;
;		PARAMETERS:		AX		Signature
;						BX		Handle
;
;		RETURNS:		NC
;						DS:BX	Address to handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

deref_handle_name	DB 'Deref Handle',0

deref_handle	PROC far
	push dx
	push si
;
	cmp bx,MAX_HANDLES
	jae deref_fail
;
	mov dx,handle_sel
	mov ds,dx
	mov si,bx
	EnterSection ds:handle_section
	mov bx,word ptr [bx+si].handle_arr
	LeaveSection ds:handle_section
	mov dx,handle_mem_sel
	mov ds,dx
	cmp ax,[bx].hh_sign
	jne deref_fail
;
	cmp si,[bx].hh_handle
	clc
	je deref_done

deref_fail:
	xor bx,bx
	mov ds,bx
	stc

deref_done:	
	pop si
	pop dx
	ret
deref_handle	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_PROCESS
;
;		DESCRIPTION:	Init per-process data
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process	PROC far
	push ds
	push es
	pushad
;
	mov ax,handle_mem_sel
	mov ds,ax
	xor bx,bx
	mov dx,8
	mov [bx].hf_next,dx
	mov [bx].hs_next,dx
	mov [bx].hs_prev,dx
	mov bx,dx
	mov dx,0FFF8h
	mov [bx].hf_prev,0
	mov [bx].hf_next,0
	mov [bx].hs_prev,0
	mov [bx].hs_next,dx
;
	mov ax,handle_sel
	mov ds,ax
	InitSection ds:handle_section
;
	mov cx,MAX_HANDLES
	mov di,2 * MAX_HANDLES + OFFSET handle_arr

init_handle_loop:
	mov ax,di
	sub di,2
	mov [di],ax
	loop init_handle_loop
;
	mov ds:handle_list,di
;
	popad
	pop es
	pop ds
	ret
init_process	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_handle
;
;		DESCRIPTION:    Init handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_handle

init_handle	PROC near
	push ds
	push es
	pusha
;
	mov eax,SIZE handle_data_seg
	mov bx,handle_data_sel
	AllocateFixedSystemMem
	mov es:hd_list,0
;
	mov eax,SIZE handle_seg
	mov bx,handle_sel
	AllocateFixedProcessMem
;
	mov edx,handle_linear
	mov ecx,10000h
	mov bx,handle_mem_sel
	CreateDataSelector16
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_process
	HookCreateProcess
;
	mov si,OFFSET register_handle
	mov di,OFFSET register_handle_name
	xor cl,cl
	mov ax,register_handle_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_handle
	mov di,OFFSET allocate_handle_name
	xor cl,cl
	mov ax,allocate_handle_nr
	RegisterOsGate
;
	mov si,OFFSET free_handle
	mov di,OFFSET free_handle_name
	xor cl,cl
	mov ax,free_handle_nr
	RegisterOsGate
;
	mov si,OFFSET deref_handle
	mov di,OFFSET deref_handle_name
	xor cl,cl
	mov ax,deref_handle_nr
	RegisterOsGate
;
	popa
	pop es
	pop ds
	ret
init_handle	ENDP

code    ENDS

        END
