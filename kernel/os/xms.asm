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
; XMS.ASM
; XMS emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME xms

GateSize = 16

MaxHandles	= 16
HandleBias = 0A560h

INCLUDE protseg.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE driver.def
INCLUDE os.def
INCLUDE user.def
INCLUDE virt.def
INCLUDE os.inc
INCLUDE user.inc
INCLUDE virt.inc

xms_handle	SEGMENT AT 0

block_base		DD ?
block_size		DD ?
lock_count		DB ?

xms_handle	ENDS

xms_system_seg	SEGMENT AT 0

xms_handler_seg	DW ?

xms_system_seg	ENDS

xms_local_seg	SEGMENT AT 0

xms_hma_state	DB ?
xms_free_mem	DD ?
xms_handles		DW MaxHandles DUP(?)

xms_local_seg	ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

init	PROC far
	pusha
	push ds
;
	mov bx,xms_code_sel
	InitDevice
	mov eax,SIZE xms_system_seg
	mov bx,xms_system_sel
	AllocateFixedSystemMem
;
	mov ax,cs
	mov ds,ax
	mov bx,OFFSET xmm_device_begin
	mov cx,OFFSET xmm_device_end - OFFSET xmm_device_begin
	mov si,OFFSET xmm_read
	mov di,OFFSET xmm_write
	RegisterDevice
	mov ax,xms_system_sel
	mov ds,ax
	mov ds:xms_handler_seg,dx
;
	mov eax,SIZE xms_local_seg
	mov bx,xms_local_sel
	AllocateFixedProcessMem
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET init_xms_process
	HookCreateProcess
;
	mov si,OFFSET xms_handler
	mov di,OFFSET xms_name
	xor cl,cl
	mov ax,xms_handler_nr
	mov dx,virt_ds_in
	RegisterVirtGate
;
	mov si,OFFSET query_xms
	mov di,OFFSET query_xms_name
	xor cl,cl
	mov ax,query_xms_nr
	RegisterOsGate
	pop ds
	popa
	ret
init	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_XMS_PROCESS
;
;		DESCRIPTION:	Init per process memory
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_xms_process	PROC far
	mov ax,xms_local_sel
	mov ds,ax
	mov es,ax
	mov ds:xms_hma_state,1
	GetFreePhysical
	sub eax,100000h
	mov ds:xms_free_mem,eax
	mov di,OFFSET xms_handles
	xor ax,ax
	mov cx,MaxHandles
	rep stosw
	ret
init_xms_process	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DEREF_HANDLE
;
;		DESCRIPTION:	DEREFERENCE XMS-HANDLE
;
;		PARAMETERS:		DX		XMS HANDLE
;
;		RETURNS:		DS		XMS_LOCAL_SEL
;						NC	ES	XMS SELECTOR
;						CY	BL	ERROR CODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

deref_handle	MACRO
	Local deref_handle_inv
	Local deref_handle_done
	push bx
	mov bx,xms_local_sel
	mov ds,bx
	mov bx,dx
	sub bx,HandleBias
	jc deref_handle_inv
	cmp bx,MaxHandles
	jz deref_handle_inv
	jnc deref_handle_inv
	add bx,bx	
	mov bx,ds:[bx].xms_handles
	or bx,bx
	jz deref_handle_inv
	mov es,bx
	pop bx
	clc
	jmp deref_handle_done
deref_handle_inv:
	pop bx
	mov bl,0A2h
	stc
deref_handle_done:
				ENDM

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_HANDLE
;
;		DESCRIPTION:	ALLOKERA XMS-HANDLE
;
;		PARAMETERS:		DS		XMS_LOCAL_SEL
;
;		RETURNS:		NC	DX		XMS HANDLE
;							ES		XMS SELECTOR
;						CY	BL		ERROR CODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
allocate_handle	MACRO
	Local allocate_handle_loop
	Local allocate_handle_done
	Local allocate_handle_end
	push eax
	push bx
	push cx
	mov bx,OFFSET xms_handles
	mov cx,MaxHandles
allocate_handle_loop:
	mov ax,[bx]
	or ax,ax
	jz allocate_handle_done
	add bx,2
	loop allocate_handle_loop
	mov bl,0A1h
	xor dx,dx
	stc
	pop cx
	pop ax
	pop eax
	jmp allocate_handle_end
allocate_handle_done:
	mov eax,SIZE xms_handle
	AllocateSmallGlobalMem
	mov [bx],es
	mov dx,bx
	sub dx,OFFSET xms_handles
	shr dx,1
	add dx,HandleBias
	clc
	pop cx
	pop bx
	pop eax
allocate_handle_end:
		ENDM

xms_version	PROC near
	mov ax,300h
	mov bx,307h
	mov dx,1
	ret
xms_version	ENDP

xms_req_hma	PROC near
	mov ax,xms_local_sel
	mov ds,ax
	xor ax,ax
	mov al,ds:xms_hma_state
	cmp al,1
	je xms_req_hma_ok
	mov bl,91h
	ret
xms_req_hma_ok:
	mov ds:xms_hma_state,0
	ret
xms_req_hma	ENDP

xms_rel_hma	PROC near
	mov ax,xms_local_sel
	mov ds,ax
	mov ax,1
	mov ds:xms_hma_state,al	
	ret
xms_rel_hma	ENDP

xms_ena_a20	PROC near
	mov ax,1
	ret
xms_ena_a20	ENDP

xms_dis_a20	PROC near
	mov ax,1
	ret
xms_dis_a20	ENDP

xms_query_a20	PROC near
	mov ax,1
	ret
xms_query_a20	ENDP

xms_query_size	PROC near
	push ds
	push bx
	mov bx,xms_local_sel
	mov ds,bx
	mov eax,ds:xms_free_mem
	pop bx
	pop ds
	shr eax,10
	mov dx,ax
	xor bl,bl
	ret
xms_query_size	ENDP

xms_allocate	PROC near
	push es
	mov bx,xms_local_sel
	mov ds,bx
	movzx eax,dx
	shl eax,10
	sub ds:xms_free_mem,eax
	jnc xms_allocate_do
	add ds:xms_free_mem,eax
	mov bl,0A0h
xms_allocate_fail:
	pop es
	xor ax,ax
	ret
xms_allocate_do:
	allocate_handle
	jc xms_allocate_fail
	or eax,eax
	jz xms_allocate_zero
	push edx
	AllocateLocalLinear
	mov es:block_base,edx
	pop edx
xms_allocate_zero:
	mov es:block_size,eax
	mov es:lock_count,0
	pop es
	mov ax,1
	ret
xms_allocate	ENDP

xms_free	PROC near
	push es
	deref_handle
	jc xms_free_fail
	mov al,es:lock_count
	or al,al
	mov bl,0ABh
	jnz xms_free_fail
	push bx
	push ecx
	push edx
	mov bx,dx
	sub bx,HandleBias
	add bx,bx
	mov word ptr ds:[bx].xms_handles,0
	mov ecx,es:block_size
	mov edx,es:block_base
	add ds:xms_free_mem,ecx
	or ecx,ecx
	jz xms_free_global
	FreeLinear
xms_free_global:
	FreeMem
	pop edx
	pop ecx
	pop bx
	mov ax,1
	jmp xms_free_done
xms_free_fail:
	mov ax,0
xms_free_done:
	pop es
	ret
xms_free	ENDP

xms_move	PROC near
	push es
	push ebx
	push ecx
	push edx
	push esi
	push edi
	mov bx,si
	mov ecx,[bx]
	mov dx,[bx+4]
	or dx,dx	
	jnz xms_source_high
	movzx eax,word ptr [bx+8]
	shl eax,4
	movzx esi,word ptr [bx+6]
	add esi,eax
	jmp xms_dest
xms_source_high:
	push ds
	push bx
	deref_handle
	pop bx
	pop ds
	mov al,0A3h
	jc xms_move_error
	mov esi,es:block_base
	mov edx,es:block_size
	mov al,0A4h
	sub edx,ecx
	jc xms_move_error
	mov al,0A7h
	sub edx,[bx+6]
	jc xms_move_error
	add esi,[bx+6]
xms_dest:
	mov dx,[bx+10]
	or dx,dx
	jnz xms_dest_high
	movzx eax,word ptr [bx+14]
	shl eax,4
	movzx edi,word ptr [bx+12]
	add edi,eax
	jmp xms_move_do
xms_dest_high:
	push ds
	push bx
	deref_handle
	pop bx
	pop ds
	mov al,0A5h
	jc xms_move_error
	mov edi,es:block_base
	mov edx,es:block_size
	mov al,0A6h
	sub edx,ecx
	jc xms_move_error
	mov al,0A7h
	sub edx,[bx+12]
	jc xms_move_error
	add edi,[bx+12]
xms_move_do:
	push ds
	mov ax,flat_sel
	mov ds,ax
	mov es,ax
	mov dx,cx
	shr ecx,2
	or ecx,ecx
	jz xms_move_done
	rep movs dword ptr es:[edi],[esi]
xms_move_done:
	mov cx,dx
	and cx,3
	jz xms_move_ok
xms_small_move_loop:
	mov al,[esi]
	mov es:[edi],al
	inc esi
	inc edi
	loop xms_small_move_loop
xms_move_ok:
	pop ds
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	mov ax,1
	jmp xms_move_end
xms_move_error:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	mov bl,al
	mov ax,0
xms_move_end:
	pop es
	ret
xms_move	ENDP

xms_lock	PROC near
	push es
	deref_handle
	mov ax,0
	jc xms_lock_end
	mov al,es:lock_count
	add al,1
	jnz xms_lock_do
	mov bl,0ACh
	jmp xms_lock_end
xms_lock_do:
	mov es:lock_count,al
	mov dx,word ptr es:block_base+2
	mov bx,word ptr es:block_base
	mov ax,1
xms_lock_end:
	pop es
	ret
xms_lock	ENDP

xms_unlock	PROC near
	push es
	deref_handle
	mov ax,0
	jc xms_unlock_end
	mov al,es:lock_count
	or al,al
	jnz xms_unlock_do
	mov bl,0AAh
	jmp xms_unlock_end
xms_unlock_do:
	dec al
	mov es:lock_count,al
	mov ax,1
xms_unlock_end:
	pop es
	ret
xms_unlock	ENDP

xms_info	PROC near
	push es
	deref_handle
	mov ax,0
	jc xms_info_end
	mov bh,es:lock_count
	mov edx,es:block_size
	shr edx,10
	push si
	push cx
	xor bl,bl
	mov si,OFFSET xms_handles
xms_info_free_loop:
	lodsw
	or ax,ax
	jnz xms_info_free_next
	inc bl
xms_info_free_next:
	loop xms_info_free_loop
	mov ax,1
xms_info_end:
	pop es
	ret
xms_info	ENDP

xms_reallocate	PROC near
	xor ax,ax
	mov bl,0A2h
	ret
xms_reallocate	ENDP

xms_req_upper	PROC near
	xor ax,ax
	mov bl,0B1h
	ret
xms_req_upper	ENDP

xms_rel_upper	PROC near
	xor ax,ax
	mov bl,0B2h
	ret
xms_rel_upper	ENDP

xms_invalid	PROC near
	xor ax,ax
	mov bl,80h
	ret
xms_invalid	ENDP

xms_call_tab:
xms0	DW OFFSET xms_version
xms1	DW OFFSET xms_req_hma
xms2	DW OFFSET xms_rel_hma
xms3	DW OFFSET xms_ena_a20
xms4	DW OFFSET xms_dis_a20
xms5	DW OFFSET xms_ena_a20
xms6	DW OFFSET xms_dis_a20
xms7	DW OFFSET xms_query_a20
xms8	DW OFFSET xms_query_size
xms9	DW OFFSET xms_allocate
xmsA	DW OFFSET xms_free
xmsB	DW OFFSET xms_move
xmsC	DW OFFSET xms_lock
xmsD	DW OFFSET xms_unlock
xmsE	DW OFFSET xms_info
xmsF	DW OFFSET xms_reallocate
xms10	DW OFFSET xms_req_upper
xms11	DW OFFSET xms_rel_upper
xmsend	DW OFFSET xms_invalid

xms_name	DB 'Xms Request',0

xms_handler	PROC far
	mov al,ah
	xor ah,ah
	cmp ah,11h
	jbe xms_impl
	mov ah,12h
xms_impl:
	push si
	add ax,ax
	mov si,ax
	mov ax,word ptr [si].xms_call_tab
	pop si
	push OFFSET xms_handle_ret
	push ax
	retn
xms_handle_ret:
	ret
xms_handler	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			QUERY_XMS
;
;		DESCRIPTION:	Query XMS info
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

query_xms_name	DB 'Query Xms',0

query_xms	PROC far
	or al,al
	jne not_xms_inst
	mov al,80h
	ret
not_xms_inst:
	cmp al,10h
	jne not_xms_entry
	mov bx,xms_system_sel
	mov ds,bx
	mov bx,ds:xms_handler_seg
	mov [bp].vm_es,bx
	mov bx,OFFSET xmm_handler - OFFSET xmm_device_begin
	ret
not_xms_entry:
	ret
query_xms	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init XMS
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

xmm_device_begin:
	dd -1
	dw 08000h
	dw OFFSET xmm_strat - OFFSET xmm_device_begin
	dw OFFSET xmm_int - OFFSET xmm_device_begin
	db 'XMSXXXX0'
xmm_handler:
	jmp xmm_handle
	nop
	nop
	nop
xmm_handle:
	XmsHandler
	retf
xmm_strat:
	retf
xmm_int:
	retf
xmm_device_end:

xmm_read	PROC far
	stc
	ret
xmm_read	ENDP

xmm_write	PROC far
	stc
	ret
xmm_write	ENDP

code	ENDS

	END init
