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

INCLUDE system.def
INCLUDE protseg.def
INCLUDE user.def
INCLUDE os.def
INCLUDE system.inc
INCLUDE user.inc
INCLUDE os.inc

	.386p

	extrn create_data_sel16:near
	extrn create_call_gate_sel16:near
	extrn create_int_gate_sel:near
	extrn create_tss_sel:near
	extrn AllocateRam:near

code	SEGMENT byte public use16 'CODE'

	assume cs:code,ds:system_seg

PAGE

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

PAGE

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
	InitSection phys_section
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

PAGE

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
	xor cl,cl
	mov ax,get_free_physical_nr
	RegisterOsGate
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

PAGE

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
	EnterSection phys_section
	dec ds:phys_free_pages
	mov dx,phys_list_sel
	mov es,dx
	mov ebx,free_phys_list
	or ebx,ebx
	jnz allocate_normal
;
	mov ebx,free_dma_phys_list
	mov edx,es:[ebx]
	mov free_dma_phys_list,edx
	jmp allocate_mark

allocate_normal:
	mov edx,es:[ebx]
	mov free_phys_list,edx

allocate_mark:
	mov edx,unused_phys_list
	mov es:[ebx],edx
	mov unused_phys_list,ebx
	mov ax,phys_page_sel
	mov ds,ax
	mov eax,ebx
	mov eax,[eax]
	xor al,al
	pop ds
	LeaveSection phys_section
	pop edx
	pop ebx
	pop es
	pop ds
	ret
allocate_physical	ENDP

PAGE

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
	EnterSection phys_section
	dec ds:phys_free_pages
	mov dx,phys_list_sel
	mov es,dx
	mov ebx,free_dma_phys_list
	mov edx,es:[ebx]
	mov free_dma_phys_list,edx
	mov edx,unused_phys_list
	mov es:[ebx],edx
	mov unused_phys_list,ebx
	mov ax,phys_page_sel
	mov ds,ax
	mov eax,ebx
	mov eax,[eax]
	xor al,al
	pop ds
	LeaveSection phys_section
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
	EnterSection phys_section
	inc ds:phys_free_pages
	xor ebx,ebx
	mov dx,phys_list_sel
	mov es,dx
	mov ebx,unused_phys_list
	mov edx,es:[ebx]
	mov unused_phys_list,edx
	cmp eax,1000000h
	jc free_dma_phys
;
	mov edx,free_phys_list
	mov es:[ebx],edx
	mov free_phys_list,ebx
	jmp free_link_page

free_dma_phys:
	mov edx,free_dma_phys_list
	mov es:[ebx],edx
	mov free_dma_phys_list,ebx

free_link_page:
	mov dx,phys_page_sel
	mov ds,dx
	mov [ebx],eax
	pop ds
	LeaveSection phys_section
	pop edx
	pop ebx
	pop es
	pop ds	
	ret
free_physical	ENDP

PAGE

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
	ret
get_free_physical_mem	ENDP

PAGE

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

PAGE

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

PAGE

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
	cmp edx,thread_block_linear
	jne get_thread_phys_not_thread_block
;
	mov es,bx
	mov eax,es:p_thread_page
	jmp get_thread_phys_done

get_thread_phys_not_thread_block:
	cmp edx,app_linear
	jne get_thread_phys_not_client
;
	mov es,bx
	mov eax,es:p_app_page
	jmp get_thread_phys_done

get_thread_phys_not_client:
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

PAGE

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

