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
; PHYSICAL.ASM
; Physical memory module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME physical

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def

	.386p

	extrn create_data_sel16:near
	extrn create_call_gate_sel16:near
	extrn create_int_gate_sel:near
	extrn create_tss_sel:near
	extrn AllocateRam:near

code	SEGMENT byte public use16 'CODE'

	assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_physical_dir
;
;		DESCRIPTION:	init physical page directories & tables
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_physical_dir

init_physical_dir	Proc near
	mov ax,flat_sel
	mov ds,ax
	mov ax,sys_dir_sel
	mov es,ax
	mov ax,system_data_sel
	mov fs,ax
	mov fs:phys_free_pages,0
;
	call AllocateRam
	mov edx,esi
	mov bx,phys_page_linear SHR 20
	and bl,0FCh
	or si,3
	mov es:[bx],esi
;
	mov cx,400h
	xor eax,eax
init_phys_page_pages:
	mov [edx],eax
	add edx,4
	loop init_phys_page_pages
;
	call AllocateRam
	mov edx,esi
	mov bx,phys_list_linear SHR 20
	and bl,0FCh
	or si,3
	mov es:[bx],esi
;
	mov cx,400h
	xor eax,eax
init_phys_list_pages:
	mov [edx],eax
	add edx,4
	loop init_phys_list_pages
;
	xor ebx,ebx
	xor ebp,ebp
init_free_dir_loop:
	call AllocateRam
	jc init_free_done
;
	mov di,phys_page_linear SHR 20
	mov edx,es:[di]
	xor dl,dl
;
	push esi
	or si,3
	mov [ebx+edx],esi
;
	call AllocateRam
	jc init_free_done
;
	mov edi,phys_list_linear SHR 20
	mov edx,es:[di]
	xor dl,dl
;
	push esi
	or si,3
	mov [ebx+edx],esi
;
	pop edx
	pop edi
	mov cx,400h
init_free_page_loop:
	call AllocateRam
	jc init_free_done
;
	or si,3
	mov [edi],esi
	add ebp,4
	mov [edx],ebp
	add edx,4
	add edi,4
;
	inc fs:phys_free_pages
	loop init_free_page_loop
;	
	add ebx,4
	jmp init_free_dir_loop

init_free_done:
	mov fs:unused_phys_list,-1
	mov fs:free_phys_list,0
	mov fs:free_dma_phys_list,0
	ret
init_physical_dir	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_PHYSICAL
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_physical

init_physical	PROC near
	mov ax,system_data_sel
	mov ds,ax
;
	InitSection ds:phys_section
	mov bx,phys_page_sel
	mov edx,phys_page_linear
	mov ecx,ds:phys_free_pages
	shl ecx,2
	push cs
	call create_data_sel16
;
	mov bx,phys_list_sel
	mov ecx,ds:phys_free_pages
	shl ecx,2
	mov edx,phys_list_linear
	push cs
	call create_data_sel16
	ret
init_physical	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_PHYSICAL_GATES
;
;		DESCRIPTION:	Init module syscalls
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_physical_gates

init_physical_gates	PROC near
	pusha
	push ds
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET get_free_physical_mem
	mov di,OFFSET get_free_physical_name
	xor dx,dx
	mov ax,get_free_physical_nr
	RegisterBimodalUserGate
;	
	mov si,OFFSET free_physical
	mov di,OFFSET free_physical_name
	xor cl,cl
	mov ax,free_physical_nr
	RegisterOsGate
	mov si,OFFSET allocate_physical
	mov di,OFFSET allocate_physical_name
	xor cl,cl
	mov ax,allocate_physical_nr
	RegisterOsGate
	mov si,OFFSET allocate_dma_physical
	mov di,OFFSET allocate_dma_physical_name
	xor cl,cl
	mov ax,allocate_dma_physical_nr
	RegisterOsGate
	mov si,OFFSET allocate_multiple_physical
	mov di,OFFSET allocate_multiple_physical_name
	xor cl,cl
	mov ax,allocate_multiple_physical_nr
	RegisterOsGate
	mov si,OFFSET get_physical_page
	mov di,OFFSET get_physical_page_name
	xor cl,cl
	mov ax,get_physical_page_nr
	RegisterOsGate
	mov si,OFFSET set_physical_page
	mov di,OFFSET set_physical_page_name
	xor cl,cl
	mov ax,set_physical_page_nr
	RegisterOsGate
	mov si,OFFSET get_thread_physical_page
	mov di,OFFSET get_thread_physical_page_name
	xor cl,cl
	mov ax,get_thread_physical_page_nr
	RegisterOsGate
	mov si,OFFSET set_thread_physical_page
	mov di,OFFSET set_thread_physical_page_name
	xor cl,cl
	mov ax,set_thread_physical_page_nr
	RegisterOsGate
	pop ds
	popa
	ret
init_physical_gates	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocatePhysical
;
;		DESCRIPTION:	Allocate physical page
;
;		PARAMETERS:		EAX		Address
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_physical_name	DB 'Allocate Physical Memory',0

	public allocate_physical

allocate_physical	PROC far
	push ds
	push es
	push ebx
	push edx
	mov bx,system_data_sel
	mov ds,bx
	push ds
	EnterSection ds:phys_section
	dec ds:phys_free_pages
	mov dx,phys_list_sel
	mov es,dx
	mov ebx,ds:free_phys_list
	or ebx,ebx
	jnz allocate_normal
;
	mov ebx,ds:free_dma_phys_list
	mov edx,es:[ebx]
	mov ds:free_dma_phys_list,edx
	jmp allocate_mark

allocate_normal:
	mov edx,es:[ebx]
	mov ds:free_phys_list,edx

allocate_mark:
	mov edx,ds:unused_phys_list
	mov es:[ebx],edx
	mov ds:unused_phys_list,ebx
	mov ax,phys_page_sel
	mov ds,ax
	mov eax,ebx
	mov eax,[eax]
	xor al,al
	pop ds
	LeaveSection ds:phys_section
	pop edx
	pop ebx
	pop es
	pop ds
	ret
allocate_physical	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateDmaPhysical
;
;		DESCRIPTION:	Allocate DMA physical page
;
;		PARAMETERS:		EAX		Address
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dma_physical_name	DB 'Allocate DMA Physical Memory',0

allocate_dma_physical	PROC far
	push ds
	push es
	push ebx
	push edx
	mov bx,system_data_sel
	mov ds,bx
	push ds
	EnterSection ds:phys_section
	dec ds:phys_free_pages
	mov dx,phys_list_sel
	mov es,dx
	mov ebx,ds:free_dma_phys_list
	mov edx,es:[ebx]
	mov ds:free_dma_phys_list,edx
	mov edx,ds:unused_phys_list
	mov es:[ebx],edx
	mov ds:unused_phys_list,ebx
	mov ax,phys_page_sel
	mov ds,ax
	mov eax,ebx
	mov eax,[eax]
	xor al,al
	pop ds
	LeaveSection ds:phys_section
	pop edx
	pop ebx
	pop es
	pop ds
	ret
allocate_dma_physical	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreePhysical
;
;		DESCRIPTION:	Free physical page
;
;		PARAMETERS:		EAX		Address
;						
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_physical_name	DB 'Free Physical Memory',0

	public free_physical

free_physical	PROC far
	push ds
	push es
	push ebx
	push edx
	and ax,0F000h
	mov bx,system_data_sel
	mov ds,bx
	push ds
	EnterSection ds:phys_section
	inc ds:phys_free_pages
	xor ebx,ebx
	mov dx,phys_list_sel
	mov es,dx
	mov ebx,ds:unused_phys_list
	mov edx,es:[ebx]
	mov ds:unused_phys_list,edx
	cmp eax,1000000h
	jc free_dma_phys
;
	mov edx,ds:free_phys_list
	mov es:[ebx],edx
	mov ds:free_phys_list,ebx
	jmp free_link_page

free_dma_phys:
	mov edx,ds:free_dma_phys_list
	mov es:[ebx],edx
	mov ds:free_dma_phys_list,ebx

free_link_page:
	mov dx,phys_page_sel
	mov ds,dx
	mov [ebx],eax
	pop ds
	LeaveSection ds:phys_section
	pop edx
	pop ebx
	pop es
	pop ds	
	ret
free_physical	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateMultiplePhysical
;
;		DESCRIPTION:	Allocate multiple physical page
;
;		PARAMETERS:		ECX		Number of pages
;
;		RETURN:			EAX		Physical base address
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_multiple_physical_name	DB 'Allocate Multiple Physical Memory',0

; edx address to check for

check_address	Proc near
	push eax
	push ebx
	push esi
;
	mov esi,ds:phys_free_pages
	shl esi,2
	mov ebx,ds:free_dma_phys_list

check_addr_loop:
	or ebx,ebx
	jz check_addr_fail
;	
    cmp ebx,esi
    jae check_addr_fail
;    
	mov eax,fs:[ebx]
	xor al,al
	cmp eax,edx
	je check_addr_found
;
	mov ebx,es:[ebx]
	jmp check_addr_loop

check_addr_fail:
	stc
	jmp check_addr_done

check_addr_found:
	clc

check_addr_done:
    pop esi
	pop ebx
	pop eax
	ret
check_address	Endp

; edx start address
; ecx number of pages

do_one_scan	Proc near
	push ecx
	push edx

do_one_scan_loop:
	call check_address
	jc do_one_scan_done
;
	add edx,1000h
	loop do_one_scan_loop
;
	clc

do_one_scan_done:
	pop edx
	pop ecx	
	ret
do_one_scan	Endp

; ecx number of pages
; edx start address

find_multi_page	Proc near
	push ebx
;
	mov ebx,ds:free_dma_phys_list

find_multi_loop:
	or ebx,ebx
	jz find_multi_fail
;	
	mov edx,fs:[ebx]
	xor dl,dl
	call do_one_scan
	jnc find_multi_done
;
	mov ebx,es:[ebx]
	jmp find_multi_loop

find_multi_fail:
	stc

find_multi_done:
	pop ebx
	ret
find_multi_page	Endp

; edx physical address

allocate_one_entry	Proc near
	push eax
	push ebx
	push esi
;
	xor esi,esi
	mov ebx,ds:free_dma_phys_list

allocate_one_loop:
	or ebx,ebx
	jz allocate_one_fail
;
	mov eax,fs:[ebx]
	xor al,al
	cmp eax,edx
	je allocate_one_do
;
	mov esi,ebx
	mov ebx,es:[ebx]
	jmp allocate_one_loop

allocate_one_do:
	or esi,esi
	jnz allocate_one_not_first
;
	mov eax,es:[ebx]
	mov ds:free_dma_phys_list,eax
	jmp allocate_one_unused

allocate_one_not_first:
	mov eax,es:[ebx]
	mov es:[esi],eax

allocate_one_unused:
	mov eax,ds:unused_phys_list
	mov es:[ebx],eax
	mov ds:unused_phys_list,ebx
	clc
	jmp allocate_one_done

allocate_one_fail:
	stc

allocate_one_done:
	pop esi
	pop ebx
	pop eax
	ret
allocate_one_entry	Endp

; ecx number of pages
; edx physical start address

allocate_multi_entries	Proc near
	push ecx
	push edx

allocate_multi_entry_loop:
	call allocate_one_entry
	add edx,1000h
	loop allocate_multi_entry_loop

allocate_multi_entry_done:
	pop edx
	pop ecx
	ret
allocate_multi_entries	Endp

allocate_multiple_physical	PROC far
	push ds
	push es
	push fs
	push ebx
	push edx
;
	mov ax,system_data_sel
	mov ds,ax
	mov ax,phys_list_sel
	mov es,ax
	mov ax,phys_page_sel
	mov fs,ax
	EnterSection ds:phys_section
	or ecx,ecx
	jz allocate_multi_fail
;
	cmp ecx,ds:phys_free_pages
	ja allocate_multi_fail
;
	call find_multi_page
	jc allocate_multi_fail
;
	call allocate_multi_entries
	sub ds:phys_free_pages,ecx
	mov eax,edx
	clc
;
	LeaveSection ds:phys_section
	jmp allocate_multi_done

allocate_multi_fail:
	LeaveSection ds:phys_section
	stc

allocate_multi_done:
	pop edx
	pop ebx
	pop fs
	pop es
	pop ds
	ret
allocate_multiple_physical	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_FREE_PHYSICAL_MEM
;
;		DESCRIPTION:	Get free physical memory
;
;		PARAMETERS:		EAX		# of free bytes
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_physical_name	DB 'Get Free Physical Memory',0

get_free_physical_mem	PROC far
	push ds
	mov ax,system_data_sel
	mov ds,ax
	mov eax,ds:phys_free_pages
	shl eax,12
	pop ds
	retf32
get_free_physical_mem	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetPhysicalPage
;
;		DESCRIPTION:	Get physical page for linear address
;
;		PARAMETERS:		EDX		linear address
;
;		RETURNS:		EAX		physical address or 0						
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_physical_page_name	DB 'Get Physical Page',0

get_physical_page	Proc far
	push ds
	mov ax,process_page_sel
	mov ds,ax
	mov eax,edx
	shr eax,10
	and al,0FCh
	mov eax,[eax]
	pop ds
	ret
get_physical_page	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetPhysicalPage
;
;		DESCRIPTION:	Set physical page for linear address
;
;		PARAMETERS:		EDX		linear address
;						EAX		physical address or 0						
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_physical_page_name	DB 'Set Physical Page',0

set_physical_page	Proc far
	push ds
	push ebx
	mov bx,process_page_sel
	mov ds,bx
	mov ebx,edx
	shr ebx,10
	and bl,0FCh
	mov [ebx],eax
	mov ebx,cr3
	mov cr3,ebx
	pop ebx
	pop ds
	ret
set_physical_page	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetThreadPhysicalPage
;
;		DESCRIPTION:	Get physical page for linear address in other thread.
;
;		PARAMETERS:		BX		Thread
;						EDX		Linear address
;
;		RETURNS:		EAX		Physical address or 0						
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_physical_page_name	DB 'Get Thread Physical Page',0

get_thread_physical_page	Proc far
	push ds
	push es
	push ebx
	push edx
	push si
;
	and dx,0F000h
	SimCli
	mov ax,process_dir_sel
	mov ds,ax
	mov si,alias_linear SHR 20
	mov es,bx
	mov eax,es:p_cr3
	or ax,803h
	mov [si],eax
	mov eax,cr3
	mov cr3,eax
;
	mov eax,alias_linear
	shr edx,10
	and dl,0FCh
	add edx,eax
	mov ebx,edx
	shr edx,10
	and dl,0FCh
	mov ax,process_page_sel
	mov ds,ax
	mov eax,[edx]
	test al,1
	jnz get_thread_phys_do
;
	xor eax,eax
	jmp get_thread_phys_done

get_thread_phys_do:	
    mov ax,flat_sel
    mov ds,ax
	mov eax,[ebx]

get_thread_phys_done:
	SimSti
	pop si
	pop edx
	pop ebx
	pop es
	pop ds
	ret
get_thread_physical_page	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetThreadPhysicalPage
;
;		DESCRIPTION:	Set physical page for linear address in other thread.
;
;		PARAMETERS:		BX		Thread
;						EDX		Linear address
;						EAX		Physical address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_thread_physical_page_name	DB 'Set Thread Physical Page',0

set_thread_physical_page	Proc far
	push ds
	push es
	push ebx
	push edx
	push si
;
	push eax
	SimCli
	mov ax,process_dir_sel
	mov ds,ax
	mov si,alias_linear SHR 20
	mov es,bx
	mov eax,es:p_cr3
	or ax,803h
	mov [si],eax
	mov eax,cr3
	mov cr3,eax
;
	mov eax,alias_linear
	shr edx,10
	and dl,0FCh
	add edx,eax
	mov ebx,edx
	shr edx,10
	and dl,0FCh
	mov ax,process_page_sel
	mov ds,ax
	mov eax,[edx]
	test al,1
	jnz set_thread_phys_do
;
	pop eax
	jmp set_thread_phys_done

set_thread_phys_do:	
    mov ax,flat_sel
    mov ds,ax
	pop eax
	mov [ebx],eax

set_thread_phys_done:
	SimSti
;
	pop si
	pop edx
	pop ebx
	pop es
	pop ds
	ret
set_thread_physical_page	Endp

code	ENDS

	END

