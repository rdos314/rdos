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
; MEM.ASM
; Memory allocation module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME mem

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE system.inc
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc

small_linear_struc	STRUC
slf_prev	DD ?
slf_next	DD ?
sls_prev	DD ?
sls_next	DD ?
small_linear_struc	ENDS

vm_linear_struc	STRUC
vmf_prev	DW ?
vmf_next	DW ?
vms_prev	DW ?
vms_next	DW ?
vm_linear_struc	ENDS

mem_seg	SEGMENT AT 0

big_avail_mem		DD ?
small_avail_mem		DD ?

big_used_mem		DD ?
small_used_mem		DD ?

big_section			section_typ <>
small_section		section_typ <>

system_alloc_base	DD ?
process_alloc_base	DD ?
thread_alloc_base	DD ?
fixed_vm_base		DD ?

mem_seg	ENDS

local_mem_seg	SEGMENT AT 0

local_avail_mem		DD ?
local_used_mem		DD ?

local_big_used_mem	DD ?
local_big_avail_mem	DD ?

vm_avail_mem		DW ?
vm_used_mem			DW ?

local_mem_section	section_typ <>
vm_mem_section		section_typ <>

local_mem_seg	ENDS

	.386p

	extrn create_data_sel16:near
	extrn create_call_gate_sel16:near
	extrn create_int_gate_sel:near
	extrn create_tss_sel:near

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CREATE_MEM
;
;		DESCRIPTION:	Create memory selectors
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public create_mem

	assume ds:mem_seg

create_mem	PROC near
	push ds
	push eax
	push bx
	push edx
;
	mov edx,system_linear
	mov ecx,SIZE mem_seg
	mov bx,mem_sel
	push cs
	call create_data_sel16
;
	mov ds,bx
	add edx,SIZE mem_seg
	mov system_alloc_base,edx
;
	pop edx
	pop bx
	pop eax
	pop ds
	ret
create_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_MEM
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_mem

init_mem	PROC near
	pusha
	push ds
;
	mov bx,small_mem_sel
	mov edx,global_byte_linear
	mov ecx,global_byte_size
	CreateDataSelector16
;
	mov ds,bx
	xor eax,eax
	mov edx,10h
	mov [eax].slf_next,edx
	mov [eax].sls_next,edx
	mov [eax].sls_prev,edx
	mov eax,edx
	mov edx,global_page_size - 10h
	mov [eax].slf_prev,0
	mov [eax].slf_next,0
	mov [eax].sls_prev,0
	mov [eax].sls_next,edx
;
	mov ax,mem_sel
	mov ds,ax
		assume ds:mem_seg
	mov edx,global_page_size
	mov big_avail_mem,edx
	InitSection big_section
;
	mov edx,global_byte_size - 10h
	mov small_avail_mem,edx
	InitSection small_section
;
	mov big_used_mem,0
	mov small_used_mem,0
	mov process_alloc_base,process_linear + SIZE process_seg
	mov thread_alloc_base,thread_linear
	mov fixed_vm_base,fixed_vm_linear
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET allocate_global_mem
	mov di,OFFSET allocate_global_name
	xor cl,cl
	mov ax,allocate_global_mem_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_small_global_mem
	mov di,OFFSET allocate_small_global_name
	xor cl,cl
	mov ax,allocate_small_global_mem_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_small_mem
	mov di,OFFSET allocate_small_mem_name
	xor cl,cl
	mov ax,allocate_small_mem_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_big_mem
	mov di,OFFSET allocate_big_mem_name
	xor cl,cl
	mov ax,allocate_big_mem_nr
	RegisterOsGate
;
	mov si,OFFSET free_mem
	mov di,OFFSET free_name
	xor cl,cl
	mov ax,free_mem_nr
	RegisterUserGate
;
	mov si,OFFSET allocate_big_linear
	mov di,OFFSET allocate_big_linear_name
	xor cl,cl
	mov ax,allocate_big_linear_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_small_linear
	mov di,OFFSET allocate_small_linear_name
	xor cl,cl
	mov ax,allocate_small_linear_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_fixed_vm_linear
	mov di,OFFSET allocate_fixed_vm_linear_name
	xor cl,cl
	mov ax,allocate_fixed_vm_linear_nr
	RegisterOsGate
;
	mov si,OFFSET free_linear
	mov di,OFFSET free_linear_name
	xor cl,cl
	mov ax,free_linear_nr
	RegisterOsGate
;
	mov si,OFFSET resize_linear
	mov di,OFFSET resize_linear_name
	xor cl,cl
	mov ax,resize_linear_nr
	RegisterOsGate
;
	mov si,OFFSET available_big_linear
	mov di,OFFSET available_big_linear_name
	xor cl,cl
	mov ax,available_big_linear_nr
	RegisterOsGate
;
	mov si,OFFSET available_small_linear
	mov di,OFFSET available_small_linear_name
	xor cl,cl
	mov ax,available_small_linear_nr
	RegisterOsGate
;
	mov si,OFFSET used_big_linear
	mov di,OFFSET used_big_linear_name
	xor cl,cl
	mov ax,used_big_linear_nr
	RegisterOsGate
;
	mov si,OFFSET used_small_linear
	mov di,OFFSET used_small_linear_name
	xor cl,cl
	mov ax,used_small_linear_nr
	RegisterOsGate
;
	mov si,OFFSET selector_to_segment
	mov di,OFFSET selector_to_segment_name
	xor cl,cl
	mov ax,selector_to_segment_nr
	RegisterOsGate
;
	mov si,OFFSET segment_to_selector
	mov di,OFFSET segment_to_selector_name
	xor cl,cl
	mov ax,segment_to_selector_nr
	RegisterOsGate
;
	mov si,OFFSET free_selector
	mov di,OFFSET free_selector_name
	xor cl,cl
	mov ax,free_selector_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_thread_linear
	mov di,OFFSET allocate_thread_linear_name
	xor cl,cl
	mov ax,allocate_thread_linear_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_process_linear
	mov di,OFFSET allocate_process_linear_name
	xor cl,cl
	mov ax,allocate_process_linear_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_system_linear
	mov di,OFFSET allocate_system_linear_name
	xor cl,cl
	mov ax,allocate_system_linear_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_fixed_thread_mem
	mov di,OFFSET allocate_fixed_thread_mem_name
	xor cl,cl
	mov ax,allocate_fixed_thread_mem_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_fixed_process_mem
	mov di,OFFSET allocate_fixed_process_mem_name
	xor cl,cl
	mov ax,allocate_fixed_process_mem_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_fixed_system_mem
	mov di,OFFSET allocate_fixed_system_mem_name
	xor cl,cl
	mov ax,allocate_fixed_system_mem_nr
	RegisterOsGate
;
	mov si,OFFSET read_thread_selector
	mov di,OFFSET read_thread_selector_name
	xor cl,cl
	mov ax,read_thread_selector_nr
	RegisterOsGate
;
	mov si,OFFSET write_thread_selector
	mov di,OFFSET write_thread_selector_name
	xor cl,cl
	mov ax,write_thread_selector_nr
	RegisterOsGate
;
	mov si,OFFSET read_thread_segment
	mov di,OFFSET read_thread_segment_name
	xor cl,cl
	mov ax,read_thread_segment_nr
	RegisterOsGate
;
	mov si,OFFSET write_thread_segment
	mov di,OFFSET write_thread_segment_name
	xor cl,cl
	mov ax,write_thread_segment_nr
	RegisterOsGate
;
	mov si,OFFSET alias_code32
	mov di,OFFSET alias_code32_name
	xor cl,cl
	mov ax,alias_code32_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_page
	mov di,OFFSET allocate_page_name
	xor cl,cl
	mov ax,allocate_page_nr
	RegisterOsGate
;
	mov si,OFFSET free_page
	mov di,OFFSET free_page_name
	xor cl,cl
	mov ax,free_page_nr
	RegisterOsGate
;
	mov si,OFFSET read_thread_mem16
	mov di,OFFSET read_thread_mem_name
	xor cl,cl
	mov ax,read_thread_mem_nr
	RegisterUserGate16
;
	mov si,OFFSET read_thread_mem32
	mov di,OFFSET read_thread_mem_name
	xor cl,cl
	mov ax,read_thread_mem_nr
	RegisterUserGate32
;
	mov si,OFFSET write_thread_mem16
	mov di,OFFSET write_thread_mem_name
	xor cl,cl
	mov ax,write_thread_mem_nr
	RegisterUserGate16
;
	mov si,OFFSET write_thread_mem32
	mov di,OFFSET write_thread_mem_name
	xor cl,cl
	mov ax,write_thread_mem_nr
	RegisterUserGate32
;
	mov si,OFFSET allocate_local_linear
	mov di,OFFSET allocate_local_linear_name
	xor cl,cl
	mov ax,allocate_local_linear_nr
	RegisterOsGate
;
	mov si,OFFSET reserve_local_linear
	mov di,OFFSET reserve_local_linear_name
	xor cl,cl
	mov ax,reserve_local_linear_nr
	RegisterOsGate
;
	mov si,OFFSET available_local_linear
	mov di,OFFSET available_local_linear_name
	xor cl,cl
	mov ax,available_local_linear_nr
	RegisterUserGate
;
	mov si,OFFSET used_local_linear
	mov di,OFFSET used_local_linear_name
	xor cl,cl
	mov ax,used_local_linear_nr
	RegisterUserGate
;
	mov si,OFFSET allocate_vm_linear
	mov di,OFFSET allocate_vm_linear_name
	xor cl,cl
	mov ax,allocate_vm_linear_nr
	RegisterOsGate
;
	mov si,OFFSET available_vm_linear
	mov di,OFFSET available_vm_linear_name
	xor cl,cl
	mov ax,available_vm_linear_nr
	RegisterUserGate
;
	mov si,OFFSET used_vm_linear
	mov di,OFFSET used_vm_linear_name
	xor cl,cl
	mov ax,used_vm_linear_nr
	RegisterUserGate
;
	mov si,OFFSET used_local_linear_thread
	mov di,OFFSET used_local_linear_thread_name
	xor cl,cl
	mov ax,used_local_linear_thread_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_local_mem16
	mov di,OFFSET allocate_local_mem_name
	xor cl,cl
	mov ax,allocate_local_mem_nr
	RegisterUserGate16
;
	mov si,OFFSET allocate_local_mem32
	mov di,OFFSET allocate_local_mem_name
	xor cl,cl
	mov ax,allocate_local_mem_nr
	RegisterUserGate32
;
	pop ds
	popa
	ret
init_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_PROCESS_MEM
;
;		DESCRIPTION:	Init per-process memory
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	assume ds:local_mem_seg

	public init_process_mem

init_process_mem	PROC near
	push ds
	push es
	push eax
	push edx
	push di
;
	mov ax,local_linear_sel
	mov ds,ax
	xor eax,eax
	mov edx,10h
	mov [eax].slf_next,edx
	mov [eax].sls_next,edx
	mov [eax].sls_prev,edx
	mov eax,edx
	mov edx,local_page_linear - local_byte_linear - 10h
	mov [eax].slf_prev,0
	mov [eax].slf_next,0
	mov [eax].sls_prev,0
	mov [eax].sls_next,edx
;
	mov ax,local_mem_sel
	mov ds,ax
	mov local_avail_mem,edx
	mov local_used_mem,0
	mov local_big_avail_mem,flat_size - local_page_linear
	mov local_big_used_mem,0
	InitSection local_mem_section
	InitSection vm_mem_section
;
	mov ax,process_page_sel
	mov es,ax
	mov di,vm_linear SHR 10
	mov cx,0Fh
	xor eax,eax
	rep stosd
;
	mov ax,vm_linear_sel
	mov ds,ax
	xor bx,bx
	mov dx,8
	mov [bx].vmf_next,dx
	mov [bx].vms_next,dx
	mov [bx].vms_prev,dx
	mov bx,dx
	mov dx,0EFF8h
	mov [bx].vmf_prev,0
	mov [bx].vmf_next,0
	mov [bx].vms_prev,0
	mov [bx].vms_next,dx
;
	mov ax,local_mem_sel
	mov ds,ax
	mov vm_avail_mem,dx
	mov vm_used_mem,0
;
	pop di
	pop edx
	pop eax
	pop es
	pop ds
	ret
init_process_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_MEM_SELS
;
;		DESCRIPTION:	Init selectors
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_mem_sels

init_mem_sels	PROC near
	pusha
	push ds
	push es
;
	mov ax,sys_page_sel
	mov ds,ax
	AllocatePhysical
	mov al,7
	mov ebx,fixed_vm_linear SHR 10
	mov [ebx],eax
;
	mov edx,local_page_linear
	mov ecx,flat_size - local_page_linear
	mov bx,flat_code_sel
	CreateCodeSelector32
;
	mov bx,flat_data_sel
	CreateDataSelector32
;
	mov bx,local_linear_sel
	mov edx,local_byte_linear
	mov ecx,local_page_linear
	CreateDataSelector32
;
	mov bx,vm_linear_sel
	mov edx,vm_linear
	mov ecx,0F000h
	CreateDataSelector16
;
	mov eax,SIZE local_mem_seg
	mov bx,local_mem_sel
	AllocateFixedProcessMem
;
	pop es
	pop ds
	popa
	ret
init_mem_sels	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_BIG_LINEAR
;
;		DESCRIPTION:	Allocate page-aligned kernel memory
;
;		PARAMETERS:		EAX		# of bytes
;
;		RETURNS:		EDX		Linear base address
;						CX		# of pages
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_big_linear_name	DB 'Allocate Big Linear',0

	assume ds:mem_seg

allocate_big_linear	PROC far
	push ds
	push es
	push eax
	push ebx
;
	mov dx,mem_sel
	mov ds,dx
	mov es,dx
		assume ds:mem_seg
	EnterSection big_section
		assume es:mem_seg
	mov ebx,global_page_size
	sub ebx,es:big_avail_mem
    add ebx,global_page_linear
	shr ebx,10
	mov dx,sys_page_sel
	mov ds,dx
	dec eax
	and ax,0F000h
	add eax,1000h
	add es:big_used_mem,eax
	sub es:big_avail_mem,eax
	shr eax,12
	xor dx,dx
allocate_global_loop:
	cmp ebx,(global_page_linear + global_page_size) SHR 10
	jne allocate_global_no_wrap
	mov ebx,global_page_linear SHR 10
	xor dx,dx
allocate_global_no_wrap:
	inc dx
	mov cl,[ebx]
	test cl,7
	jz allocate_global_next
	xor dx,dx
allocate_global_next:
	add ebx,4
	cmp ax,dx
	je allocate_global_end
	jmp allocate_global_loop
allocate_global_end:
	mov cx,ax
	shl eax,2
	sub ebx,eax
	mov dl,2
	push ebx
	push cx
allocate_global_mark:
	mov [ebx],dl
	add ebx,4
	loop allocate_global_mark
	pop cx
	pop edx
;
	mov ax,mem_sel
	mov ds,ax
		assume ds:mem_seg
	LeaveSection big_section
	shl edx,10
	pop ebx
	pop eax
	pop es
	pop ds
	ret
allocate_big_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_SMALL_LINEAR
;
;		DESCRIPTION:	Allocate byte-aligned kernel memory
;
;		PARAMETERS:		EAX		# of bytes
;
;		RETURNS:		EDX		Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_small_linear_name	DB 'Allocate Small Linear',0

allocate_small_linear	PROC far
	push ds
	push es
	push eax
	push ebx
	push ecx
;
	mov dx,mem_sel
	mov ds,dx
	mov es,dx
		assume ds:mem_seg
	EnterSection small_section
		assume es:mem_seg
	mov edx,es:small_avail_mem
	add es:small_used_mem,eax
	sub edx,eax
	sub edx,10h
	add eax,10h
	mov es:small_avail_mem,edx
;
	mov dx,small_mem_sel
	mov ds,dx
	xor edx,edx
	xor ebx,ebx
	mov edx,[edx].slf_next
allocate_small_loop:
	mov ecx,[edx].sls_next
	sub ecx,edx
	cmp ecx,eax
	jnc allocate_small_found
	mov ebx,edx
	mov edx,[edx].slf_next
	jmp allocate_small_loop
allocate_small_found:
	sub ecx,eax
	cmp ecx,16
	jc allocate_small_no_split
	mov ebx,eax
	add ebx,edx
;	
	mov eax,[edx].sls_next
	mov [ebx].sls_next,eax
	mov [ebx].sls_prev,edx
	mov [edx].sls_next,ebx
	mov [eax].sls_prev,ebx
;
	mov eax,[edx].slf_next
	mov [ebx].slf_next,eax
	mov [edx].slf_next,ebx
	or eax,eax
	jz allocate_last_free
	mov [eax].slf_prev,ebx
allocate_last_free:
	mov eax,[edx].slf_prev
	mov [ebx].slf_prev,eax
	or eax,eax
	jz allocate_first_free
	mov [eax].slf_next,ebx
allocate_first_free:
;
	jmp allocate_small_done
allocate_small_no_split:
	mov eax,[edx].slf_prev
	mov ebx,[edx].slf_next
	mov [eax].slf_next,ebx
	mov [ebx].slf_prev,eax
allocate_small_done:
	xor eax,eax
	mov ebx,[eax].slf_next
	cmp ebx,edx
	jnz allocate_small_end
	mov ebx,[edx].slf_next
	mov [eax].slf_next,ebx
allocate_small_end:
	xor eax,eax
	mov ebx,[eax].sls_prev
	mov ecx,[edx].sls_next
	cmp ebx,ecx
	jnc no_small_biggest_block
	mov [eax].sls_prev,ecx
no_small_biggest_block:	
	dec eax
	mov [edx].slf_prev,eax
	mov [edx].slf_next,eax
	mov ax,mem_sel
	mov ds,ax
		assume ds:mem_seg
	LeaveSection small_section
	add edx,global_byte_linear + 10h
	pop ecx
	pop ebx
	pop eax
	pop es
	pop ds
	ret
allocate_small_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_LOCAL_LINEAR
;
;		DESCRIPTION:	Allocate local memory (in process address space)
;
;		PARAMETERS:		EAX		Number of bytes
;
;		RETURNS:		EDX		Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_local_linear_name	DB 'Allocate Local Linear',0

allocate_local_linear	PROC far
	push ds
	push es
	push eax
	push ebx
	push ecx
	test ax,0FFFh
	jz allocate_page_local_linear
	cmp eax,4000h
	jnc allocate_page_local_linear
;
	mov dx,local_mem_sel
	mov ds,dx
	mov es,dx
		assume ds:local_mem_seg
	EnterSection local_mem_section
	mov edx,local_avail_mem
	add local_used_mem,eax
	sub edx,eax
	sub edx,10h
	add eax,10h
	mov local_avail_mem,edx
		assume ds:mem_seg
		assume es:local_mem_seg
;
	mov dx,local_linear_sel
	mov ds,dx
	xor edx,edx
	xor ebx,ebx
	mov edx,[edx].slf_next
allocate_local_loop:
	mov ecx,[edx].sls_next
	sub ecx,edx
	cmp ecx,eax
	jnc allocate_local_found
	mov ebx,edx
	mov edx,[edx].slf_next
	jmp allocate_local_loop
allocate_local_found:
	sub ecx,eax
	cmp ecx,16
	jc allocate_local_no_split
	mov ebx,eax
	add ebx,edx
;	
	mov eax,[edx].sls_next
	mov [ebx].sls_next,eax
	mov [ebx].sls_prev,edx
	mov [edx].sls_next,ebx
	mov [eax].sls_prev,ebx
;
	mov eax,[edx].slf_next
	mov [ebx].slf_next,eax
	mov [edx].slf_next,ebx
	or eax,eax
	jz allocate_local_last_free
	mov [eax].slf_prev,ebx
allocate_local_last_free:
	mov eax,[edx].slf_prev
	mov [ebx].slf_prev,eax
	or eax,eax
	jz allocate_local_first_free
	mov [eax].slf_next,ebx
allocate_local_first_free:
;
	jmp allocate_local_done
allocate_local_no_split:
	mov eax,[edx].slf_prev
	mov ebx,[edx].slf_next
	mov [eax].slf_next,ebx
	mov [ebx].slf_prev,eax
allocate_local_done:
	xor eax,eax
	mov ebx,[eax].slf_next
	cmp ebx,edx
	jnz allocate_local_end
	mov ebx,[edx].slf_next
	mov [eax].slf_next,ebx
allocate_local_end:
	xor eax,eax
	mov ebx,[eax].sls_prev
	mov ecx,[edx].sls_next
	cmp ebx,ecx
	jnc no_local_biggest_block
	mov [eax].sls_prev,ecx
no_local_biggest_block:	
	dec eax
	mov [edx].slf_prev,eax
	mov [edx].slf_next,eax
	mov ax,local_mem_sel
	mov ds,ax
		assume ds:local_mem_seg
	LeaveSection local_mem_section
	add edx,local_byte_linear + 10h
	pop ecx
	pop ebx
	pop eax
	pop es
	pop ds
	ret
allocate_page_local_linear:
	dec eax
	and ax,0F000h
	add eax,1000h
	mov dx,local_mem_sel
	mov ds,dx
	mov es,dx
		assume ds:local_mem_seg
	EnterSection local_mem_section
	mov ebx,local_page_linear
	shr ebx,10
	add ebx,4
	add local_big_used_mem,eax
	sub local_big_avail_mem,eax
	shr eax,12
		assume ds:mem_seg
		assume es:local_mem_seg
	mov dx,process_page_sel
	mov ds,dx
	xor dx,dx
allocate_blocal_loop:
	cmp ebx,flat_size SHR 10
	jne allocate_blocal_no_wrap
	mov ebx,local_page_linear SHR 10 + 4
	xor dx,dx
allocate_blocal_no_wrap:
	inc dx
	mov cl,[ebx]
	test cl,7
	jz allocate_blocal_next
	xor dx,dx
allocate_blocal_next:
	add ebx,4
	cmp ax,dx
	je allocate_blocal_end
	jmp allocate_blocal_loop
allocate_blocal_end:
	mov cx,ax
	shl eax,2
	sub ebx,eax
	mov dl,2
	push ebx
	push cx
allocate_blocal_mark:
	mov [ebx],dl
	add ebx,4
	loop allocate_blocal_mark
	pop cx
	pop edx
;
	mov ax,local_mem_sel
	mov ds,ax
		assume ds:local_mem_seg
	LeaveSection local_mem_section
	shl edx,10
	pop ecx
	pop ebx
	pop eax
	pop es
	pop ds
	ret
allocate_local_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReserveLocalLinear
;
;		DESCRIPTION:	Reserve local memory
;
;		PARAMETERS:		EAX		Number of bytes
;						EDX		Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reserve_local_linear_name	DB 'Reserve Local Linear',0

reserve_local_linear	PROC far
	push ds
	push eax
	push ebx
	push ecx
	push edx
;
	dec eax
	and ax,0F000h
	add eax,1000h
	mov bx,local_mem_sel
	mov ds,bx
		assume ds:local_mem_seg
	EnterSection local_mem_section
	cmp edx,local_page_linear
	jc reserve_local_linear_inv_range
	cmp edx,flat_size
	jae reserve_local_linear_inv_range
	mov ecx,eax
	add ecx,edx
	cmp ecx,local_page_linear
	jc reserve_local_linear_inv_range
	cmp ecx,flat_size
	jae reserve_local_linear_inv_range
;
	shr edx,10
	shr eax,12
	mov bx,process_page_sel
	mov ds,bx
	mov ebx,eax
	push edx
reserve_local_linear_loop:
	mov cl,[edx]
	test cl,7
	jnz reserve_local_linear_fail
	add edx,4
	sub ebx,1
	jnz reserve_local_linear_loop
	pop edx
;
	mov ebx,eax
	mov cl,2
reserve_local_linear_mark:
	mov [edx],cl
	add edx,4
	sub ebx,1
	jnz reserve_local_linear_mark
	clc
	jmp reserve_local_linear_done

reserve_local_linear_fail:
	pop edx

reserve_local_linear_inv_range:
	stc

reserve_local_linear_done:
	pushf
	mov ax,local_mem_sel
	mov ds,ax
		assume ds:local_mem_seg
	LeaveSection local_mem_section
	popf
;
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ds
	ret
reserve_local_linear	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_VM_LINEAR
;
;		DESCRIPTION:	Allocate V86 mode addressable memory
;
;		PARAMETERS:		EAX		Number of bytes
;
;		RETURNS:		EDX		Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_vm_linear_name	DB 'Allocate VM Linear',0

allocate_vm_linear	PROC far
	push ds
	push es
	push bx
	push cx
	push si
	push di
;
	mov dx,local_mem_sel
	mov ds,dx
	mov es,dx
		assume ds:local_mem_seg
	EnterSection vm_mem_section
		assume es:local_mem_seg
	mov dx,es:vm_avail_mem
	add es:vm_used_mem,ax
	sub dx,ax
	sub dx,8
	add ax,8
	mov es:vm_avail_mem,dx
;
	mov dx,vm_linear_sel
	mov ds,dx
	xor si,si
	xor bx,bx
	mov si,[si].vmf_next
allocate_vm_loop:
	mov cx,[si].vms_next
	sub cx,si
	cmp cx,ax
	jnc allocate_vm_found
	mov bx,si
	mov si,[si].vmf_next
	jmp allocate_vm_loop
allocate_vm_found:
	sub cx,ax
	cmp cx,8
	jc allocate_vm_no_split
	mov bx,ax
	add bx,si
;	
	mov di,[si].vms_next
	mov [bx].vms_next,di
	mov [bx].vms_prev,si
	mov [si].vms_next,bx
;
	mov di,[si].vmf_next
	mov [bx].vmf_next,di
	mov [si].vmf_next,bx
	or di,di
	jz allocate_vm_last_free
	mov [di].vmf_prev,bx
allocate_vm_last_free:
	mov di,[si].vmf_prev
	mov [bx].vmf_prev,di
	or di,di
	jz allocate_vm_first_free
	mov [di].vmf_next,bx
allocate_vm_first_free:
;
	jmp allocate_vm_done
allocate_vm_no_split:
	mov di,[si].vmf_prev
	mov bx,[si].vmf_next
	mov [di].vmf_next,bx
	mov [bx].vmf_prev,di
allocate_vm_done:
	xor di,di
	mov bx,[di].vmf_next
	cmp bx,si
	jnz allocate_vm_end
	mov bx,[si].vmf_next
	mov [di].vmf_next,bx
allocate_vm_end:
	xor di,di
	mov bx,[di].vms_prev
	mov cx,[si].vms_next
	cmp bx,cx
	jnc no_vm_biggest_block
	mov [di].vms_prev,cx
no_vm_biggest_block:	
	dec di
	mov [si].vmf_prev,di
	mov [si].vmf_next,di
	mov bx,local_mem_sel
	mov ds,bx
		assume local_mem_seg
	LeaveSection vm_mem_section
	movzx edx,si
	add edx,vm_linear + 8
	pop di
	pop si
	pop cx
	pop bx
	pop es
	pop ds
	ret
allocate_vm_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AVAILABLE_BIG_LINEAR
;
;		DESCRIPTION:	Available page-aligned kernel memory
;
;		RETURNS:		EAX		Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

available_big_linear_name	DB 'Available Big Linear',0

	assume ds:mem_seg

available_big_linear	PROC far
	push ds
	mov ax,mem_sel
	mov ds,ax
	mov eax,big_avail_mem
	pop ds
	ret
available_big_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AVAILABLE_SMALL_LINEAR
;
;		DESCRIPTION:	Available byte-aligned kernel memory
;
;		RETURNS:		EAX		Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

available_small_linear_name	DB 'Available Small Linear',0

available_small_linear	PROC far
	push ds
	mov ax,mem_sel
	mov ds,ax
	mov eax,small_avail_mem
	pop ds
	ret
available_small_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AVAILABLE_LOCAL_LINEAR
;
;		DESCRIPTION:	Available local (process) memory
;
;		RETURNS:		EAX		Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

available_local_linear_name	DB 'Available Local Linear',0

available_local_linear	PROC far
	push ds
	mov ax,local_mem_sel
	mov ds,ax
		assume ds:local_mem_seg
	mov eax,local_avail_mem
	pop ds
	retf32
available_local_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AVAILABLE_VM_LINEAR
;
;		DESCRIPTION:	Available V86 mode addressable memory
;
;		RETURNS:		EAX		Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

available_vm_linear_name	DB 'Available VM Linear',0

available_vm_linear	PROC far
	push ds
	mov ax,local_mem_sel
	mov ds,ax
		assume ds:local_mem_seg
	movzx eax,vm_avail_mem
	pop ds
	retf32
available_vm_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			USED_BIG_LINEAR
;
;		DESCRIPTION:	Used page-aligned kernel memory
;
;		PARAMETERS:		EAX		Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

used_big_linear_name	DB 'Used Big Linear',0

	assume ds:mem_seg

used_big_linear	PROC far
	push ds
	mov ax,mem_sel
	mov ds,ax
	mov eax,big_used_mem
	pop ds
	ret
used_big_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			USED_SMALL_LINEAR
;
;		DESCRIPTION:	Used byte-aligned kernel memory
;
;		PARAMETERS:		EAX		Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

used_small_linear_name	DB 'Used Small Linear',0

used_small_linear	PROC far
	push ds
	mov ax,mem_sel
	mov ds,ax
	mov eax,small_used_mem
	pop ds
	ret
used_small_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			USED_LOCAL_LINEAR
;
;		DESCRIPTION:	User local (process) memory
;
;		PARAMETERS:		EAX	ANTAL BYTE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

used_local_linear_name	DB 'Used Local Linear',0

	assume ds:local_mem_seg

used_local_linear	PROC far
	push ds
	mov ax,local_mem_sel
	mov ds,ax
	mov eax,local_used_mem
	pop ds
	retf32
used_local_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			USED_VM_LINEAR
;
;		DESCRIPTION:	Used V86 addressable memory
;
;		PARAMETERS:		EAX		Number of bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

used_vm_linear_name	DB 'Used VM Linear',0

	assume ds:local_mem_seg

used_vm_linear	PROC far
	push ds
	mov ax,local_mem_sel
	mov ds,ax
	movzx eax,vm_used_mem
	pop ds
	retf32
used_vm_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			USED_LOCAL_LINEAR_THREAD
;
;		DESCRIPTION:	User local (process) memory in other thread
;
;		PARAMETERS:		BX		Thread
;
;		RETURNS:		EAX		Number of bytes
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

used_local_linear_thread_name	DB 'Used Local Linear Thread',0

used_local_linear_thread	PROC far
	push ds
	push es
	push cx
	push dx
	push esi
;
	mov dx,local_mem_sel
	xor esi,esi
	ReadThreadSelector
	mov cx,ax
	inc esi
	ReadThreadSelector
	mov ah,al
	mov al,cl
	push ax
	inc esi
	ReadThreadSelector
	mov cx,ax
	inc esi
	ReadThreadSelector
	mov ah,al
	mov al,cl
	shl eax,16
	pop ax
;
	pop esi
	pop dx
	pop cx
	pop es
	pop ds
	ret
used_local_linear_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_GLOBAL_MEM
;
;		DESCRIPTION:	Allocate page-aligned kernel memory
;
;		PARAMETERS:		EAX		Number of bytes
;
;		RETURNS:		ES		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_global_name	DB 'Allocate Global Memory',0

	assume ds:mem_seg

allocate_global_mem	PROC far
	push ds
	push bx
	push ecx
	push edx
;
	AllocateBigLinear
	AllocateGdt
	mov ecx,eax
	CreateDataSelector16
	mov es,bx
;
	pop edx
	pop ecx
	pop bx
	pop ds
	ret
allocate_global_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_PAGE
;
;		DESCRIPTION:	Allocate a page in kernel memory
;
;		RETURNS:		ES		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_page_name	DB 'Allocate Page',0

	assume ds:mem_seg

allocate_page	PROC far
	push ds
	push bx
	push ecx
	push edx
;
	mov eax,1000h
	AllocateBigLinear
	AllocateGdt
	mov ecx,eax
	CreateDataSelector32
	mov es,bx
;
	pop edx
	pop ecx
	pop bx
	pop ds
	ret
allocate_page	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FREE_PAGE
;
;		DESCRIPTION:	Free page and return physical address
;
;		PARAMETERS:		ES		Selector
;						
;		RETURNS:		EAX		Physical address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_page_name	DB 'Free Page',0

	assume ds:mem_seg

free_page	PROC far
	push ds
	push bx
	push edx
	mov ax,gdt_sel
	mov ds,ax
	mov bx,es
	mov edx,[bx+2]
	rol edx,8
	mov dl,[bx+7]
	ror edx,8
	mov ax,sys_page_sel
	mov ds,ax
	shr edx,10
	xor eax,eax
	xchg eax,[edx]
	FreeMem
	pop edx
	pop bx
	pop ds
	ret
free_page	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_SMALL_GLOBAL_MEM
;
;		DESCRIPTION:	Allocate byte-aligned kernel memory
;
;		PARAMETERS:		EAX		Number of bytes
;
;		RETURNS:		ES		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_small_global_name	DB 'Allocate Small Global Memory',0

allocate_small_global_mem	PROC far
	push ds
	push eax
	push bx
	push ecx
	push edx
;
	cmp eax,100000h
	jc alloc_small_g_not_page
	dec eax
	and ax,0F000h
	add eax,1000h
alloc_small_g_not_page:
	AllocateSmallLinear
	AllocateGdt
	mov ecx,eax
	CreateDataSelector16
	mov es,bx
;
	pop edx
	pop ecx
	pop bx
	pop eax
	pop ds
	ret
allocate_small_global_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FREE_PAGES
;
;		DESCRIPTION:	Free used physical memory pages for linear region
;
;		PARAMETERS:		EDX		Start linear address
;						EAX		End linear address
;						DS		Page table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_pages	PROC near
	dec edx
	shr edx,10
	and dx,NOT 3
	add dx,4
	mov bx,dx
	mov edx,eax
	shr edx,10
	and dx,NOT 3
	mov cx,dx
	sub cx,bx
	jc no_free_pages
	jz no_free_pages
	shr cx,2
free_pages_loop:
	xor eax,eax
	xchg eax,[bx]
	test al,1
	jz free_pages_nopage
	FreePhysical
free_pages_nopage:
	add bx,4
	loop free_pages_loop
no_free_pages:
	ret
free_pages	ENDP


PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FREE_MEM
;
;		DESCRIPTION:	Free memory
;
;		PARAMETERS:		ES		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_name	DB 'Free Memory',0

free_big_mem	PROC near
	shr edx,10
	dec ecx
	and cx,0F000h
	add ecx,1000h
	mov ax,mem_sel
	mov ds,ax
		assume ds:mem_seg
	EnterSection big_section
		assume es:mem_seg
	add es:big_avail_mem,ecx
	sub es:big_used_mem,ecx
	shr ecx,12
	mov ax,sys_page_sel
	mov ds,ax
free_big_loop:
	xor eax,eax
	xchg eax,[edx]
	test al,1
	jz free_big_nopage
	FreePhysical
free_big_nopage:
	add edx,4
	loop free_big_loop
	mov ax,mem_sel
	mov ds,ax
		assume ds:mem_seg
	LeaveSection big_section
	mov edx,cr3
	mov cr3,edx
	ret
free_big_mem	ENDP

free_small_mem	PROC near
	sub edx,global_byte_linear + 10h
	mov ax,mem_sel
	mov ds,ax
		assume ds:mem_seg
	EnterSection small_section
		assume es:mem_seg
	mov ax,small_mem_sel
	mov ds,ax
	mov eax,[edx].sls_next
	sub eax,edx
	mov ebx,es:small_avail_mem
	add ebx,eax
	mov es:small_avail_mem,ebx
	add es:small_used_mem,10h
	sub es:small_used_mem,eax
;
	mov eax,[edx].sls_prev
	or eax,eax
	jz free_small_no_merge_down
;
	mov eax,[eax].slf_next
	inc eax
	or eax,eax
	jz free_small_no_merge_down
;
	mov eax,edx
	mov edx,[eax].sls_prev
	mov ebx,[eax].sls_next
	mov [edx].sls_next,ebx
	mov [ebx].sls_prev,edx
	jmp free_small_test_up

free_small_no_merge_down:
	xor eax,eax
	mov ebx,[eax].slf_next
	cmp edx,ebx
	jc free_small_insert_first

free_small_insert_loop:
	mov ebx,[ebx].slf_next
	cmp edx,ebx
	jnc free_small_insert_loop
;
	mov eax,[ebx].slf_prev
	mov [edx].slf_prev,eax
	mov [eax].slf_next,edx
	mov [edx].slf_next,ebx
	mov [ebx].slf_prev,edx
	jmp free_small_test_up

free_small_insert_first:
	mov [edx].slf_prev,eax
	mov ebx,[eax].slf_next
	mov [edx].slf_next,ebx
	mov [eax].slf_next,edx
	mov [ebx].slf_prev,edx

free_small_test_up:
	mov eax,[edx].sls_next
	mov eax,[eax].slf_prev
	inc eax
	or eax,eax
	jz free_small_no_merge_up
	push edx
	mov edx,[edx].sls_next
	mov eax,[edx].slf_prev
	mov ebx,[edx].slf_next
	or eax,eax
	jz fm1_bypass
	mov [eax].slf_next,ebx
fm1_bypass:
	or ebx,ebx
	jz fm2_bypass
	mov [ebx].slf_prev,eax
fm2_bypass:
	xor eax,eax
	mov ebx,[eax].slf_next
	cmp ebx,edx
	jne fm3_bypass
	mov ebx,[ebx].slf_next
	mov [eax].slf_next,ebx
fm3_bypass:
	pop edx
	mov ebx,[edx].sls_next
	mov ebx,[ebx].sls_next
	mov [ebx].sls_prev,edx
	mov [edx].sls_next,ebx
free_small_no_merge_up:
	xor eax,eax
	mov ebx,[eax].sls_prev
	mov eax,[edx].sls_next
	cmp eax,ebx
	jc free_small_not_limit_page
	mov eax,ebx
	add eax,1000h
	xor ebx,ebx
	mov [ebx].sls_prev,edx
free_small_not_limit_page:
	add edx,10h
    add edx,global_byte_linear SHR 10
	mov bx,sys_page_sel
	mov ds,bx
;	call free_pages
	mov bx,mem_sel
	mov ds,bx
		assume ds:mem_seg
	LeaveSection small_section
	ret
free_small_mem	ENDP

free_system:
	cmp edx,global_byte_linear
	jc free_error
	cmp edx,global_page_linear
	jc free_small_mem
	cmp edx,global_page_linear + global_page_size
	jc free_big_mem
	jmp free_error

free_local_mem	PROC near
	cmp edx,local_byte_linear
	jc free_low_mem
	cmp edx,local_page_linear
	jnc free_big_local_mem
	mov ax,local_mem_sel
	mov ds,ax
	mov es,ax
		assume ds:local_mem_seg
	EnterSection local_mem_section
	sub edx,local_byte_linear
	sub edx,10h
		assume es:local_mem_seg
	mov ax,local_linear_sel
	mov ds,ax
	mov eax,[edx].sls_next
	sub eax,edx
	mov ebx,es:local_avail_mem
	add ebx,eax
	mov es:local_avail_mem,ebx
	add es:local_used_mem,10h
	sub es:local_used_mem,eax
;
	mov eax,[edx].sls_prev
	or eax,eax
	jz free_local_no_merge_down
	mov eax,[eax].slf_next
	inc eax
	or eax,eax
	jz free_local_no_merge_down
	mov eax,edx
	mov edx,[eax].sls_prev
	mov ebx,[eax].sls_next
	mov [edx].sls_next,ebx
	mov [ebx].sls_prev,edx
	jmp free_local_test_up
free_local_no_merge_down:
	xor eax,eax
	mov ebx,[eax].slf_next
	cmp edx,ebx
	jc free_local_insert_first

free_local_insert_loop:
	mov ebx,[ebx].slf_next
	cmp edx,ebx
	jnc free_local_insert_loop
;
	mov eax,[ebx].slf_prev
	mov [edx].slf_prev,eax
	mov [eax].slf_next,edx
	mov [edx].slf_next,ebx
	mov [ebx].slf_prev,edx
	jmp free_local_test_up

free_local_insert_first:
	mov [edx].slf_prev,eax
	mov ebx,[eax].slf_next
	mov [edx].slf_next,ebx
	mov [eax].slf_next,edx
	mov [ebx].slf_prev,edx

free_local_test_up:
	mov eax,[edx].sls_next
	mov eax,[eax].slf_prev
	inc eax
	or eax,eax
	jz free_local_no_merge_up
	push edx
	mov edx,[edx].sls_next
	mov eax,[edx].slf_prev
	mov ebx,[edx].slf_next
	or eax,eax
	jz fm1_local_bypass
	mov [eax].slf_next,ebx
fm1_local_bypass:
	or ebx,ebx
	jz fm2_local_bypass
	mov [ebx].slf_prev,eax
fm2_local_bypass:
	xor eax,eax
	mov ebx,[eax].slf_next
	cmp ebx,edx
	jne fm3_local_bypass
	mov ebx,[ebx].slf_next
	mov [eax].slf_next,ebx
fm3_local_bypass:
	pop edx
	mov ebx,[edx].sls_next
	mov ebx,[ebx].sls_next
	mov [ebx].sls_prev,edx
	mov [edx].sls_next,ebx
free_local_no_merge_up:
	xor eax,eax
	mov ebx,[eax].sls_prev
	mov eax,[edx].sls_next
	cmp eax,ebx
	jc free_local_not_limit_page
	mov eax,ebx
	add eax,1000h
	xor ebx,ebx
	mov [ebx].sls_prev,edx
free_local_not_limit_page:
	add edx,local_byte_linear + 10h
	add eax,local_byte_linear
	mov bx,process_page_sel
	mov ds,bx
;	call free_pages
	mov bx,local_mem_sel
	mov ds,bx
		assume ds:local_mem_seg
	LeaveSection local_mem_section
	ret
free_local_mem	ENDP

free_low_mem	Proc near
	cmp edx,vm_linear
	jnc free_vm_mem
;
	FreeDosLinear
	ret
free_low_mem	Endp

free_vm_mem	PROC near
	mov ax,local_mem_sel
	mov ds,ax
	mov es,ax
		assume ds:local_mem_seg
	EnterSection vm_mem_section
		assume es:local_mem_seg
	sub edx,vm_linear
	mov si,dx
	sub si,8
	mov ax,vm_linear_sel
	mov ds,ax
	mov di,[si].vms_next
	sub di,si
	mov bx,es:vm_avail_mem
	add bx,di
	mov es:vm_avail_mem,bx
	add es:vm_used_mem,8
	sub es:vm_used_mem,di
;
	mov di,[si].vms_prev
	or di,di
	jz free_vm_no_merge_down
	mov di,[di].vmf_next
	inc di
	or di,di
	jz free_vm_no_merge_down
	mov di,si
	mov si,[di].vms_prev
	mov bx,[di].vms_next
	mov [si].vms_next,bx
	mov [bx].vms_prev,si
	jmp free_vm_test_up
free_vm_no_merge_down:
	xor di,di
	mov [si].vmf_prev,di
	mov bx,[di].vmf_next
	mov [si].vmf_next,bx
	mov [di].vmf_next,si
	mov [bx].vmf_prev,si
free_vm_test_up:
	mov di,[si].vms_next
	mov di,[di].vmf_prev
	inc di
	or di,di
	jz free_vm_no_merge_up
	push si
	mov si,[si].vms_next
	mov di,[si].vmf_prev
	mov bx,[si].vmf_next
	or di,di
	jz fm1_vm_bypass
	mov [di].vmf_next,bx
fm1_vm_bypass:
	or bx,bx
	jz fm2_vm_bypass
	mov [bx].vmf_prev,di
fm2_vm_bypass:
	xor di,di
	mov bx,[di].vmf_next
	cmp bx,si
	jne fm3_vm_bypass
	mov bx,[bx].vmf_next
	mov [di].vmf_next,bx
fm3_vm_bypass:
	pop si
	mov bx,[si].vms_next
	mov bx,[bx].vms_next
	mov [bx].vms_prev,si
	mov [si].vms_next,bx
free_vm_no_merge_up:
	xor di,di
	mov bx,[di].vms_prev
	mov di,[si].vms_next
	cmp di,bx
	jc free_vm_not_limit_page
	mov di,bx
	add di,1000h
	xor bx,bx
	mov [bx].vms_prev,si
free_vm_not_limit_page:
	movzx edx,si
	movzx eax,di
	add edx,vm_linear + 8
	add eax,vm_linear
	mov bx,process_page_sel
	mov ds,bx
;	call free_pages
	mov bx,local_mem_sel
	mov ds,bx
		assume ds:local_mem_seg
	LeaveSection vm_mem_section
	ret
free_vm_mem	ENDP

	assume es:thread_seg

free_big_local_mem	PROC near
	mov ax,local_mem_sel
	mov ds,ax
	mov es,ax
		assume ds:local_mem_seg
	EnterSection local_mem_section
		assume es:local_mem_seg
	shr edx,10
	dec ecx
	and cx,0F000h
	add ecx,1000h
	add es:local_big_avail_mem,ecx
	sub es:local_big_used_mem,ecx
	shr ecx,12
	mov ax,process_page_sel
	mov ds,ax
free_blocal_loop:
	xor eax,eax
	xchg eax,[edx]
	test al,1
	jz free_blocal_nopage
	FreePhysical
free_blocal_nopage:
	add edx,4
	loop free_blocal_loop
	mov bx,local_mem_sel
	mov ds,bx
		assume ds:local_mem_seg
	LeaveSection local_mem_section
	mov edx,cr3
	mov cr3,edx
	ret
free_big_local_mem	ENDP
	
free_error	PROC near
	int 3
	ret
free_error	ENDP

free_mem_tab:
f0	DW OFFSET free_local_mem
f1	DW OFFSET free_local_mem
f2	DW OFFSET free_local_mem
f3	DW OFFSET free_local_mem
f4	DW OFFSET free_local_mem
f5	DW OFFSET free_local_mem
f6	DW OFFSET free_error
f7	DW OFFSET free_error
f8	DW OFFSET free_error
f9	DW OFFSET free_error
fA	DW OFFSET free_error
fB	DW OFFSET free_error
fC	DW OFFSET free_error
fD	DW OFFSET free_error
fE	DW OFFSET free_system
fF	DW OFFSET free_system

		assume es:mem_seg

free_mem	PROC far
	push ds
	pushad
;
	mov bx,es
	mov ax,mem_sel
	mov es,ax
	and bx,0FFFCh
	jz free_mem_end
	test bx,4
	pushf
	jz free_in_gdt
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bx,0FFF8h
	jmp free_descr
free_in_gdt:
	mov ax,gdt_sel
	mov ds,ax	
free_descr:
	xor ecx,ecx
	mov cl,[bx+6]
	and cl,0Fh
	shl ecx,16
	mov cx,[bx]
	inc ecx
	test byte ptr [bx+6],80h
	jz free_not_huge
	shl ecx,12
free_not_huge:
	mov edx,[bx+2]
	rol edx,8
	mov dl,[bx+7]
	ror edx,8
	mov ax,[bx+6]
	mov byte ptr [bx+5],0
	popf
	jz free_descr_gdt
	FreeLdt
	jmp free_lin_mem
free_descr_gdt:
	FreeGdt
free_lin_mem:
	test al,10h
	jnz free_mem_end
	mov al,ah
	and ax,0F0h
	shr ax,3
	mov si,OFFSET free_mem_tab
	add si,ax
	call word ptr cs:[si]
	xor ax,ax
	mov es,ax
free_mem_end:
	popad
	pop ds
	retf32
free_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FREE_SELECTOR
;
;		DESCRIPTION:	Free selector but not covered linear memory
;
;		PARAMETERS:		ES		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_selector_name	DB 'Free Selector',0

free_selector	PROC far
	push ds
	pushf
	push ax
	push bx
;
	mov bx,es
	xor ax,ax
	mov es,ax
	and bx,0FFFCh
	jz free_selector_end
	test bx,4
	jz free_selector_in_gdt
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bx,0FFF8h
	FreeLdt
	jmp free_selector_done
free_selector_in_gdt:
	FreeGdt
free_selector_done:
free_selector_end:
	pop bx
	pop ax
	popf
	pop ds
	ret
free_selector	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FREE_LINEAR
;
;		DESCRIPTION:	Free linear memory
;
;		PARAMETERS:		ECX		Size
;						EDX		Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_linear_name	DB 'Free Linear',0

free_linear	PROC far
	push ds
	push es
	push eax
	push ebx
	push ecx
	push si
;
	mov ax,mem_sel
	mov es,ax
	mov eax,edx
	shr eax,24
	and ax,0F0h
	shr ax,3
	mov bx,OFFSET free_mem_tab
	add bx,ax
	call word ptr cs:[bx]
	xor edx,edx
	pop si
	pop ecx
	pop ebx
	pop eax
	pop es
	pop ds
	ret
free_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RESIZE_LINEAR
;
;		DESCRIPTION:	Resize linear memory block
;
;		PARAMETERS:		EAX		New size
;						ECX		Old size
;						EDX		Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

resize_linear_name	DB 'Resize Linear',0

resize_local_mem	PROC near
	cmp edx,local_byte_linear
	jc resize_low_mem
	jmp resize_error
resize_low_mem:
	cmp edx,vm_linear
	jc resize_dos_mem
	jmp resize_error
resize_local_mem	ENDP

resize_dos_mem	Proc near
	ResizeDosLinear
	ret
resize_dos_mem	ENDP
	
resize_error	PROC near
	int 3
	stc
	ret
resize_error	ENDP

resize_mem_tab:
r0	DW OFFSET resize_local_mem
r1	DW OFFSET resize_error
r2	DW OFFSET resize_error
r3	DW OFFSET resize_error
r4	DW OFFSET resize_error
r5	DW OFFSET resize_error
r6	DW OFFSET resize_error
r7	DW OFFSET resize_error
r8	DW OFFSET resize_error
r9	DW OFFSET resize_error
rA	DW OFFSET resize_error
rB	DW OFFSET resize_error
rC	DW OFFSET resize_error
rD	DW OFFSET resize_error
rE	DW OFFSET resize_error
rF	DW OFFSET resize_error

resize_linear	PROC far
	push ds
	push es
	push ecx
	push esi
;
	mov si,mem_sel
	mov es,si
	mov esi,edx
	shr esi,24
	and si,0F0h
	shr si,3
	call word ptr cs:[si].resize_mem_tab
	pop esi
	pop ecx
	pop es
	pop ds
	ret
resize_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_SMALL_MEM
;
;		DESCRIPTION:	Allocate byte-aligned process memory
;
;		PARAMETERS:		EAX		Number of bytes
;
;		RETURNS:		ES		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_small_mem_name	DB 'Allocate Small Memory',0

allocate_small_mem	PROC far
	push ds
	push eax
	push bx
	push cx
	push edx
	cmp eax,100000h
	jc alloc_small_not_page
	dec eax
	and ax,0F000h
	add eax,1000h
alloc_small_not_page:
	AllocateSmallLinear
	AllocateLdt
	cmp eax,100000h
	jnc alloc_small_big_seg
	dec eax
	mov [bx],ax
	mov [bx+2],edx
	mov dl,0F2h
	xchg dl,[bx+5]
	shr eax,16
	and ax,0Fh
	or ah,dl
	mov [bx+6],ax
	jmp alloc_small_big_seg_ok
alloc_small_big_seg:
	shr eax,12
	dec ax
	mov [bx],ax
	mov [bx+2],edx
	mov ah,0F2h
	xchg ah,[bx+5]
	mov al,80h
	mov [bx+6],ax
alloc_small_big_seg_ok:
	or bx,7
	mov es,bx
	pop edx
	pop cx
	pop bx
	pop eax
	pop ds
	ret
allocate_small_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_BIG_MEM
;
;		DESCRIPTION:	Allocate page-aligned process memory
;
;		PARAMETERS:		EAX		Number of bytes
;
;		RETURNS:		ES		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_big_mem_name	DB 'Allocate Big Memory',0

allocate_big_mem	PROC far
	push ds
	push eax
	push bx
	push cx
	push edx
	AllocateBigLinear
	AllocateLdt
	cmp eax,100000h
	jnc alloc_big_big_seg
	dec eax
	mov [bx],ax
	mov [bx+2],edx
	mov dl,0F2h
	xchg dl,[bx+5]
	shr eax,16
	and ax,0Fh
	or ah,dl
	mov [bx+6],ax
	jmp alloc_big_big_seg_ok
alloc_big_big_seg:
	dec cx
	mov [bx],cx
	mov [bx+2],edx
	mov ah,0F2h
	xchg ah,[bx+5]
	mov al,80h
	mov [bx+6],ax
alloc_big_big_seg_ok:
	or bx,7
	mov es,bx
	pop edx
	pop cx
	pop bx
	pop eax
	pop ds
	ret
allocate_big_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_LOCAL_MEM16
;
;		DESCRIPTION:	Allocate process memory
;
;		PARAMETERS:		EAX		Number of bytes
;
;		RETURNS:		ES		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_mem_name	DB 'Allocate Memory',0

allocate_local_mem_name	DB 'Allocate Local Memory',0

allocate_local_mem16	PROC far
	push ds
	push eax
	push bx
	push cx
	push edx
	cmp eax,100000h
	jc alloc_local_not_page16
	dec eax
	and ax,0F000h
	add eax,1000h
alloc_local_not_page16:
	AllocateLocalLinear
	AllocateLdt
	cmp eax,100000h
	jnc alloc_local_big_seg16
	dec eax
	mov [bx],ax
	mov [bx+2],edx
	mov dl,0F2h
	xchg dl,[bx+5]
	shr eax,16
	and ax,0Fh
	or ah,dl
	mov [bx+6],ax
	jmp alloc_local_big_seg_ok16
alloc_local_big_seg16:
	shr eax,12
	dec ax
	mov [bx],ax
	mov [bx+2],edx
	mov ah,0F2h
	xchg ah,[bx+5]
	mov al,80h
	mov [bx+6],ax
alloc_local_big_seg_ok16:
	or bx,7
	mov es,bx
	pop edx
	pop cx
	pop bx
	pop eax
	pop ds
	ret
allocate_local_mem16	ENDP

allocate_local_mem32	PROC far
	push ds
	push eax
	push bx
	push cx
	push edx
	cmp eax,100000h
	jc alloc_local_not_page32
	dec eax
	and ax,0F000h
	add eax,1000h
alloc_local_not_page32:
	AllocateLocalLinear
	AllocateLdt
	cmp eax,100000h
	jnc alloc_local_big_seg32
	dec eax
	mov [bx],ax
	mov [bx+2],edx
	mov dl,0F2h
	xchg dl,[bx+5]
	shr eax,16
	and ax,0Fh
	or al,40h
	or ah,dl
	mov [bx+6],ax
	jmp alloc_local_big_seg_ok32
alloc_local_big_seg32:
	shr eax,12
	dec ax
	mov [bx],ax
	mov [bx+2],edx
	mov ah,0F2h
	xchg ah,[bx+5]
	mov al,0C0h
	mov [bx+6],ax
alloc_local_big_seg_ok32:
	or bx,7
	mov es,bx
	pop edx
	pop cx
	pop bx
	pop eax
	pop ds
	retf32
allocate_local_mem32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SELECTOR_TO_SEGMENT
;
;		DESCRIPTION:	Convert a selector to a segment if possible	
;
;		PARAMETERS:		AX		Selector
;
;		RETURNS:		NC	EAX SEGMENT
;						CY	EAX = F000	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

selector_to_segment_name	DB 'Selector to Segment',0

selector_to_segment	PROC far
	push ds
	push bx
	mov bx,ax
	test bx,4
	jz get_in_gdt
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bx,0FFF8h
	jmp get_seg_do
get_in_gdt:
	mov ax,gdt_sel
	mov ds,ax	
get_seg_do:
	mov ax,[bx+6]
	or ax,ax
	jnz get_seg_error
	mov eax,[bx+2]
	shr eax,4
	and eax,0FFFFh
	clc
	jmp get_seg_end
get_seg_error:
	stc
	mov eax,0F000h
get_seg_end:
	pop bx
	pop ds
	ret
selector_to_segment	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			TRANSLATE_SEGMENT
;
;		DESCRIPTION:	Translate a segment into a selector
;
;		PARAMETERS:		BX		Segment
;
;		RETURNS:		BX		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public translate_segment

translate_segment_base	PROC near
	push ds
	push ax
	push edx
	xor edx,edx
	mov dx,bx
	shl edx,4
	AllocateLdt
	mov word ptr [bx],0FFFFh
	mov [bx+2],edx
	mov byte ptr [bx+5],0F2h
	mov word ptr [bx+6],10h
	or bx,7
	pop edx
	pop ax
	pop ds
	ret
translate_segment_base	ENDP


translate_segment	PROC near
	push si
	xor si,si
	call translate_segment_base
	pop si
	ret
translate_segment	ENDP

	public translate_dpl_segment

translate_dpl_segment	PROC near
	push si
	mov si,ax
	call translate_segment_base
	pop si
	ret
translate_dpl_segment	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SEGMENT_TO_SELECTOR
;
;		DESCRIPTION:	Convert a segment into a selector
;
;		PARAMETERS:		BX		Segment
;
;		RETURNS:		BX		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment_to_selector_name	DB 'Segment To Selector',0

segment_to_selector	PROC far
	call translate_segment
	ret
segment_to_selector	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			TRANSLATE_SELECTOR
;
;		DESCRIPTION:	Translate selector to segment
;
;		PARAMETERS:		BX		SELECTOR
;
;		RETURNS:		NC		BX	Segment
;						CY		Invalid
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public translate_selector

translate_selector	PROC near
	test bx,4
	jz translate_in_gdt
	mov ax,thread_sel
	mov ds,ax
	mov ds,ds:p_ldt_sel
	and bx,0FFF8h
	mov ax,[bx+6]
	and ax,0FF00h
	or ax,ax
	stc
	jnz translate_sel_end
	mov eax,[bx+2]
	shr eax,4
	push ax
	mov ax,[bx+6]
	test ax,10h
	jz translate_no_ldt_free
	FreeLdt
translate_no_ldt_free:
	pop bx
	clc
	jmp translate_sel_end
translate_in_gdt:
	mov ax,gdt_sel
	mov ds,ax	
	mov ax,[bx+6]
	and ax,0FF00h
	stc
	jnz translate_sel_end
	mov eax,[bx+2]
	shr eax,4
	mov bx,ax
	clc
translate_sel_end:
	ret
translate_selector	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_THREAD_LINEAR
;
;		DESCRIPTION:	Allocate fixed thread linear
;
;		PARAMETERS:		EAX		Number of bytes
;
;		RETURNS:		EDX		Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_thread_linear_name	DB 'Allocate Thread Linear',0

	assume ds:mem_seg

allocate_thread_linear	PROC far
	push ds
	mov dx,mem_sel
	mov ds,dx
	mov edx,thread_alloc_base
	add thread_alloc_base,eax
	pop ds
	ret
allocate_thread_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_PROCESS_LINEAR
;
;		DESCRIPTION:	Allocate fixed process linear
;
;		PARAMETERS:		EAX		Number of bytes
;
;		RETURNS:		EDX		Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_process_linear_name	DB 'Allocate Process Linear',0

allocate_process_linear	PROC far
	push ds
	mov dx,mem_sel
	mov ds,dx
	mov edx,process_alloc_base
	add process_alloc_base,eax
	pop ds
	ret
allocate_process_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_SYSTEM_LINEAR
;
;		DESCRIPTION:	Allocate fixed system memory
;
;		PARAMETERS:		EAX		Number of bytes
;
;		RETURNS:		EDX		Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_system_linear_name	DB 'Allocate System Linear',0

allocate_system_linear	PROC near
	push ds
	mov dx,mem_sel
	mov ds,dx
	mov edx,system_alloc_base
	add system_alloc_base,eax
	pop ds
	retf
allocate_system_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_FIXED_VM_LINEAR
;
;		DESCRIPTION:	Allocate fixed V86 mode linear
;
;		PARAMETERS:		EAX		Number of bytes
;
;		RETURNS:		EDX		Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_vm_linear_name	DB 'Allocate Fixed VM Linear',0

allocate_fixed_vm_linear	PROC near
	push ds
	push eax
	mov dx,mem_sel
	dec eax
	and al,0F0h
	add eax,10h
	mov ds,dx
	mov edx,fixed_vm_base
	add fixed_vm_base,eax
	pop eax
	pop ds
	retf
allocate_fixed_vm_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_FIXED_THREAD_MEM
;
;		DESCRIPTION:	Allocate fixed thread memory
;
;		PARAMETERS:		EAX		Number of bytes
;						BX		Selector
;
;		RETURNS:		ES		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_thread_mem_name	DB 'Allocate Fixed Thread Mem',0

allocate_fixed_thread_mem	PROC far
	push ds
	push ecx
	push edx
;
	AllocateThreadLinear
	mov ecx,eax
	CreateDataSelector16
	mov es,bx
;
	pop edx
	pop ecx
	pop ds
	ret
allocate_fixed_thread_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_FIXED_PROCESS_MEM
;
;		DESCRIPTION:	Allocate fixed process memory
;
;		PARAMETERS:		EAX		Number of bytes
;						BX		Selector
;						
;		RETURNS:		ES		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_process_mem_name	DB 'Allocate Fixed Process Mem',0

allocate_fixed_process_mem	PROC far
	push ds
	push ecx
	push edx
;
	AllocateProcessLinear
	mov ecx,eax
	CreateDataSelector16
	mov es,bx
;
	pop edx
	pop ecx
	pop ds
	ret
allocate_fixed_process_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_FIXED_SYSTEM_MEM
;
;		DESCRIPTION:	Allocate fixed system memory
;
;		PARAMETERS:		EAX		Number of bytes
;						BX		Selector
;
;		RETURNS:		ES		Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_system_mem_name	DB 'Allocate Fixed System Mem',0

	public allocate_fixed_system_mem

allocate_fixed_system_mem	PROC far
	push ds
	push ecx
	push edx
;
	push cs
	call allocate_system_linear
	mov ecx,eax
	push cs
	call create_data_sel16
	mov es,bx
;
	pop edx
	pop ecx
	pop ds
	ret
allocate_fixed_system_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			VALIDATE_DESCRIPTOR
;
;		DESCRIPTION:	Validate descriptor
;
;		PARAMETERS:		DS:BX		Descriptor
;						ESI			Offset within descriptor
;
;		RETURNS:		NC			Valid
;							EDX		Linear address (including offset)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

validate_descriptor	PROC near
	mov dl,[bx+5]
	test dl,80h
	stc
	jz validate_descriptor_done
	test dl,10h
	jz validate_system_descriptor
validate_code_data_descriptor:
	test dl,8
	jnz validate_descriptor_up
	test dl,4
	jz validate_descriptor_up
	jmp validate_descriptor_down
validate_system_descriptor:
	and dl,0Fh
	cmp dl,2
	je validate_descriptor_up
	cmp dl,9
	je validate_descriptor_up
	cmp dl,0Bh
	je validate_descriptor_up
	stc
	jmp validate_descriptor_done
validate_descriptor_up:
	xor edx,edx
	mov dl,[bx+6]
	and dl,0Fh
	shl edx,16
	mov dx,[bx]
	test byte ptr [bx+6],80h
	jz validate_descriptor_byte_up
	shl edx,12
	or dx,0FFFh
validate_descriptor_byte_up:
	cmp edx,esi
	jc validate_descriptor_done
	mov edx,[bx+2]
	rol edx,8
	mov dl,[bx+7]
	ror edx,8
	add edx,esi
	clc
	jmp validate_descriptor_done
validate_descriptor_down:
	xor edx,edx
	mov dl,[bx+6]
	and dl,0Fh
	shl edx,16
	mov dx,[bx]
	test byte ptr [bx+6],80h
	jz validate_descriptor_byte_down
	shl edx,12
	or dx,0FFFh
validate_descriptor_byte_down:
	cmp esi,edx
	jc validate_descriptor_done
	mov edx,[bx+2]
	rol edx,8
	mov dl,[bx+7]
	ror edx,8
	add edx,esi
	clc
validate_descriptor_done:
	ret
validate_descriptor	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			VALIDATE_THREAD_SELECTOR
;
;		DESCRIPTION:	Validate descriptor in other thread
;
;		PARAMETERS:		DX:ESI		Selector:Offset
;						BX			Thread
;
;		RETURNS:		NC			Valid
;							EDX		Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

validate_thread_selector	Proc near
	test dx,4
	jz validate_thread_gdt
validate_thread_ldt:
	push ds
	push ax
	push bx
	mov ds,bx
	mov bx,ds:p_ldt_sel
	mov ax,gdt_sel
	mov ds,ax
	mov ax,[bx]
	cmp ax,dx
	jc validate_ldt_thread_done
	mov ds,bx
	mov bx,dx
	and bx,0FFF8h
	call validate_descriptor
validate_ldt_thread_done:
	pop bx
	pop ax
	pop ds
	jmp validate_thread_done
validate_thread_gdt:
	cmp dx,gdt_size
	jnc validate_thread_fail
	push ds
	push bx
	mov bx,gdt_sel
	mov ds,bx
	mov bx,dx	
	and bx,0FFF8h
	call validate_descriptor
	pop bx
	pop ds
	jmp validate_thread_done
validate_thread_fail:
	stc
validate_thread_done:
	mov al,'!'
	ret
validate_thread_selector	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			READ_THREAD_SELECTOR
;
;		DESCRIPTION:	Read byte from another thread
;
;		PARAMETERS:		DX:ESI		Selector:offset in thread
;						BX			Thread
;
;		RETURNS:		NC			Valid
;							AL		Value
;						CY			Invalid
;							AL		Error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_thread_selector_name	DB 'Read Thread Selector',0

read_thread_selector	PROC far
	push ds
	push es
	push ecx
	push edx
	push esi
;
	mov ax,process_page_sel
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
;
read_thread_selector_retry:
	call validate_thread_selector
	jc read_thread_selector_done
	movzx esi,dx
	and dx,0F000h
	or edx,edx
	jnz read_thread_selector_normal
	mov dx,flat_sel
	movzx esi,si
	add esi,page0_linear
	jmp read_thread_selector_retry

read_thread_selector_normal:
	and si,0FFFh
	GetThreadPhysicalPage
;
	test al,1
	jnz read_thread_selector_ok
	stc
	mov al,'%'
	jmp read_thread_selector_done

read_thread_selector_ok:
	push eax
	mov eax,1000h
	AllocateLocalLinear
	pop eax
	shr edx,10
	mov [edx],eax
	shl edx,10
	mov al,es:[edx+esi]
	shr edx,10
	mov dword ptr [edx],0
	shl edx,10
	mov ecx,1000h
	FreeLinear
	clc
read_thread_selector_done:
	pop esi
	pop edx
	pop ecx
	pop es
	pop ds
	ret
read_thread_selector	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_THREAD_SELECTOR
;
;		DESCRIPTION:	Write byte to another thread
;
;		PARAMETERS:		DX:EAX		Selector:offset in thread
;						BX			Thread
;						AL			Value to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_thread_selector_name	DB 'Write Thread Selector',0

write_thread_selector	PROC far
	push ds
	push es
	push eax
	push ecx
	push edx
	push esi
;
	mov cl,al
	mov ax,process_page_sel
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
;
write_thread_selector_retry:
	call validate_thread_selector
	jc write_thread_selector_done
	movzx esi,dx
	and dx,0F000h
	or edx,edx
	jnz write_thread_selector_normal
	mov dx,flat_sel
	movzx esi,si
	add esi,page0_linear
	jmp write_thread_selector_retry

write_thread_selector_normal:
	and si,0FFFh
	GetThreadPhysicalPage
;
	test al,1
	jnz write_thread_selector_do
	AllocatePhysical
	or al,7
	SetThreadPhysicalPage
write_thread_selector_do:
	push eax
	mov eax,1000h
	AllocateLocalLinear
	pop eax
	shr edx,10
	mov [edx],eax
	shl edx,10
	mov es:[edx+esi],cl
	shr edx,10
	mov dword ptr [edx],0
	shl edx,10
	mov ecx,1000h
	FreeLinear
	clc
write_thread_selector_done:
	pop esi
	pop edx
	pop ecx
	pop eax
	pop es
	pop ds
	ret
write_thread_selector	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			READ_THREAD_MEM
;
;		DESCRIPTION:	Read data from another thread
;
;		PARAMETERS:		DX:ESI		Selector:offset in thread
;						BX			Thread
;						ES:(E)DI	Buffer
;						ECX			Size
;						
;		RETURNS:		(E)AX		Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_thread_mem_name	DB 'Read Thread Mem',0

read_thread_mem	PROC near
	push ecx
	push esi
	push edi
;
	mov al,dl
	and al,3
	cmp al,3
	jne read_thread_mem_done
;
	or ecx,ecx
	jz read_thread_mem_done

read_thread_mem_loop:
	ReadThreadSelector
	jc read_thread_mem_done
;
	mov es:[edi],al
	inc esi
	inc edi
	sub ecx,1
	jnz read_thread_mem_loop

read_thread_mem_done:
	mov eax,ecx
	pop edi
	pop esi
	pop ecx
	sub eax,ecx
	neg eax
	ret
read_thread_mem	ENDP

read_thread_mem16	Proc far
	push edi
	push ecx
;
	movzx ecx,cx
	movzx edi,di
	call read_thread_mem
;
	pop ecx
	pop edi
	ret
read_thread_mem16	Endp

read_thread_mem32	Proc far
	call read_thread_mem
	retf32
read_thread_mem32	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteThreadMem
;
;		DESCRIPTION:	Write data to another thread
;
;		PARAMETERS:		DX:ESI		Selector:offset in thread
;						BX			Thread
;						ES:(E)DI	Buffer
;						ECX			Size
;						
;		RETURNS:		(E)AX		Bytes written
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_thread_mem_name	DB 'Write Thread Mem',0

write_thread_mem	PROC near
	push ecx
	push esi
	push edi
;
	mov al,dl
	and al,3
	cmp al,3
	jne write_thread_mem_done
;
	or ecx,ecx
	jz write_thread_mem_done

write_thread_mem_loop:
	mov al,es:[edi]
	WriteThreadSelector
	jc write_thread_mem_done
;
	inc esi
	inc edi
	sub ecx,1
	jnz write_thread_mem_loop

write_thread_mem_done:
	mov eax,ecx
	pop edi
	pop esi
	pop ecx
	sub eax,ecx
	neg eax
	ret
write_thread_mem	ENDP

write_thread_mem16	Proc far
	push edi
	push ecx
;
	movzx ecx,cx
	movzx edi,di
	call write_thread_mem
;
	pop ecx
	pop edi
	ret
write_thread_mem16	Endp

write_thread_mem32	Proc far
	call write_thread_mem
	retf32
write_thread_mem32	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			READ_THREAD_SEGMENT
;
;		DESCRIPTION:	Read data from another thread
;
;		PARAMETERS:		DX:ESI		Segment:offset in thread
;						BX			Thread
;
;		RETURNS:		NC			Valid
;							AL		Value
;						CY			Invalid
;							AL		Error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_thread_segment_name	DB 'Read Thread Segment',0

read_thread_segment	PROC far
	push ds
	push es
	push ecx
	push edx
	push esi
;
	mov ax,process_page_sel
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
;
	cmp esi,10000h
	jnc read_thread_segment_out_of_range
;
	movzx edx,dx
	shl edx,4
	add edx,esi
read_thread_segment_retry:
	movzx esi,dx
	and dx,0F000h
	or edx,edx
	jnz read_thread_segment_normal
	mov dx,flat_sel
	movzx esi,si
	add esi,page0_linear
	call validate_thread_selector
	jc read_thread_selector_done
	jmp read_thread_segment_retry

read_thread_segment_normal:
	and si,0FFFh
	GetThreadPhysicalPage
;
	test al,1
	jnz read_thread_segment_ok
	stc
	mov al,'%'
	jmp read_thread_segment_done

read_thread_segment_out_of_range:
	stc
	mov al,'!'
	jmp read_thread_segment_done

read_thread_segment_ok:
	push eax
	mov eax,1000h
	AllocateLocalLinear
	pop eax
	shr edx,10
	mov [edx],eax
	shl edx,10
	mov al,es:[edx+esi]
	shr edx,10
	mov dword ptr [edx],0
	shl edx,10
	mov ecx,1000h
	FreeLinear
	clc
read_thread_segment_done:
	pop esi
	pop edx
	pop ecx
	pop es
	pop ds
	ret
read_thread_segment	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_THREAD_SEGMENT
;
;		DESCRIPTION:	Write data to another thread
;
;		PARAMETERS:		DX:ESI		Segment:offset
;						BX			Thread
;						AL			Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_thread_segment_name	DB 'Write Thread Segment',0

write_thread_segment	PROC far
	push ds
	push es
	push eax
	push ecx
	push edx
	push esi
;
	mov cl,al
	mov ax,process_page_sel
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
;
	movzx edx,dx
	shl edx,4
	add edx,esi
write_thread_segment_retry:
	movzx esi,dx
	and dx,0F000h
	or edx,edx
	jnz write_thread_segment_normal
	mov dx,flat_sel
	movzx esi,si
	add esi,page0_linear
	call validate_thread_selector
	jc write_thread_selector_done
	jmp write_thread_segment_retry

write_thread_segment_normal:
	and si,0FFFh
	GetThreadPhysicalPage
;
	test al,1
	jnz write_thread_segment_do
	AllocatePhysical
	or al,7
	SetThreadPhysicalPage
write_thread_segment_do:
	push eax
	mov eax,1000h
	AllocateLocalLinear
	pop eax
	shr edx,10
	mov [edx],eax
	shl edx,10
	mov es:[edx+esi],cl
	shr edx,10
	mov dword ptr [edx],0
	shl edx,10
	mov ecx,1000h
	FreeLinear
	clc
	pop esi
	pop edx
	pop ecx
	pop eax
	pop es
	pop ds
	ret
write_thread_segment	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALIAS_CODE32
;
;		DESCRIPTION:	Create a 32-bit segment within a 16-bit device-driver
;
;		PARAMETERS:		AX		16-bit code selector
;						BX		32-bit code selector
;						SI		Offset of 32-bit init code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alias_code32_name	DB 'Alias Code32',0

alias_code32	PROC far
	push ds
	push eax
	push si
	mov si,ax
	mov ax,gdt_sel
	mov ds,ax
	mov eax,[si]
	mov [bx],eax
	mov eax,[si+4]
	mov [bx+4],eax
	or byte ptr [bx+6],40h
	pop si
	push 0
	push cs
	push 0
	push OFFSET alias_ret32
	push bx
	push si
	ret
alias_ret32:
	pop eax
	pop ds	
	ret
alias_code32	ENDP

code	ENDS

.186

END

