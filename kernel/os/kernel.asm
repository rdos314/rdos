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
; KERNEL.ASM
; Kernel module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  kernel

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE os.def
INCLUDE os.inc

.386p

	extrn create_data_sel16:near
	extrn create_call_gate_sel16:near
	extrn create_int_gate_sel:near
	extrn create_tss_sel:near

	extrn write_hex_dword:near

	extrn create_gdt:near
	extrn create_mem:near
	extrn init_pretask_traps:near

	extrn init_paging:near
	extrn start_paging:near
	extrn init_physical_dir:near
	extrn init_physical:near
	extrn init_paging_trap:near
	extrn init_physical_gates:near
	extrn init_protseg:near
	extrn init_paging_gates:near
	extrn init_mem:near
	extrn init_gdt:near
	extrn init_idt:near
	extrn init_ldt:near
	extrn init_state:near
	extrn init_task:near
	extrn init_thread:near
	extrn init_mem_sels:near
	extrn init_osgate:near
	extrn init_systemgate:near
	extrn init_usergate:near
	extrn init_virtgate:near
	extrn init_virt_pm_usergate:near
	extrn init_io:near
	extrn init_int:near
	extrn init_irq:near
	extrn init_app:near
	extrn init_trap_vectors:near
	extrn move_adapters:near
	extrn init_device:near
	extrn init_env:near

	extrn init_exec:near

	extrn init_first_process:near
	extrn init_first_thread:near
	
code	SEGMENT byte use16 public 'CODE'

	assume cs:code

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ZeroRam
;
;		DESCRIPTION:	zero ram content
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ZeroRam	Proc near
	push ds
	push es
	push eax
	push edx
	push esi
;
    mov ax,flat_sel
    mov ds,ax
	mov ax,system_data_sel
	mov es,ax
;
	xor eax,eax
	mov esi,es:alloc_base

ZeroRamLoop1:
	mov [esi],eax
ZeroRamNext1:
    add esi,1000h
    cmp esi,es:ram1_size
    jc ZeroRamLoop1
;
	mov esi,es:ram2_base
	mov ecx,es:ram2_size
	or ecx,ecx
	jz ZeroRamDone

ZeroRamLoop2:
    mov [esi],eax
ZeroRamNext2:
    add esi,1000h
	sub ecx,1000h
	jnz ZeroRamLoop2

ZeroRamDone:
	pop esi
	pop edx
	pop eax
	pop es
	pop ds
	ret
ZeroRam	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			MarkupRam
;
;		DESCRIPTION:	mark up ram with boot signature
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MarkupRam	Proc near
	push ds
	push es
	push eax
	push edx
	push esi
;
    mov ax,flat_sel
    mov ds,ax
	mov ax,system_data_sel
	mov es,ax
;
	mov esi,es:alloc_base

MarkupRamLoop1:
	mov eax,[esi]
	or eax,eax
	jnz MarkupRamNext1
    mov eax,BootMemSign
    mov [esi],eax
MarkupRamNext1:
    add esi,1000h
    cmp esi,es:ram1_size
    jc MarkupRamLoop1

	mov esi,es:ram2_base
	mov ecx,es:ram2_size
	or ecx,ecx
	jz MarkupRamDone

MarkupRamLoop2:
	mov eax,[esi]
	or eax,eax
	jnz MarkupRamNext2
    mov eax,BootMemSign
    mov [esi],eax
MarkupRamNext2:
    add esi,1000h
	sub ecx,1000h
    jnz MarkupRamLoop2

MarkupRamDone:
	pop esi
	pop edx
	pop eax
	pop es
	pop ds
	ret
MarkupRam	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateRam
;
;		DESCRIPTION:	get free ram during startup
;
;		RETURNS:		NC	ESI		address to use
;						CY			no more free ram
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public AllocateRam

AllocateRam	Proc near
	push ds
	push es
	push eax
;
    mov ax,flat_sel
    mov ds,ax
	mov ax,system_data_sel
	mov es,ax
;
	mov esi,es:alloc_base
	cmp esi,es:ram1_size
	jb AllocRamNext1
;
	mov eax,es:ram2_size
	or eax,eax
	stc
	jz AllocRamDone
;
	cmp esi,es:ram2_base
	jae AllocRamNext2
;
	mov esi,es:ram2_base
	sub esi,1000h
	jmp AllocRamNext2

AllocRamLoop1:
	mov eax,[esi]
	cmp eax,BootMemSign
	jne AllocRamNext1
	mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je AllocRamFound
AllocRamNext1:
    add esi,1000h
    cmp esi,es:ram1_size
    jc AllocRamLoop1

	mov esi,es:ram2_base
	sub esi,1000h
	jmp AllocRamNext2

AllocRamLoop2:
	mov eax,[esi]
	cmp eax,BootMemSign
	jne AllocRamNext2
	mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je AllocRamFound
AllocRamNext2:
    add esi,1000h
	mov eax,es:ram2_base
	add eax,es:ram2_size
    cmp esi,eax
    jc AllocRamLoop2
	stc
	jmp AllocRamDone

AllocRamFound:
	mov es:alloc_base,esi
	clc

AllocRamDone:
	pop eax
	pop es
	pop ds
	ret
AllocateRam	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_PRE_TASKING
;
;		DESCRIPTION:	Init pretasking
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

virt_thread_name DB 'Pretasking                      '

init_pre_tasking	PROC near
	call AllocateRam
	mov bx,virt_thread_sel
	mov ecx,1000h
	mov edx,esi
	push cs
	call create_data_sel16
	mov es,bx
;
	call AllocateRam
	mov cr3,esi
		assume es:thread_seg
	mov es:p_thread_sel,es
	mov es:p_tss_sel,kernel_tss
	mov es:p_tss_data_sel,0
	mov es:p_cr3,esi
	mov ax,cs
	mov ds,ax
	mov si,OFFSET virt_thread_name
	mov di,OFFSET thread_name
	mov cx,32
	rep movsb
	ret
init_pre_tasking	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_BOOT_SYSTEM
;
;		DESCRIPTION:	Init system_data_sel
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	assume ds:system_seg

init_boot_system	PROC near
	mov ax,system_data_sel
	mov ds,ax
	xor ax,ax
	mov debug_list,ax
	mov math_tss,ax
	mov check_point,0
	ret
init_boot_system	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_SYSTEM
;
;		DESCRIPTION:	Move system_data_sel from boot area
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_system	Proc near
	push ds
	push es
	pusha
	mov bx,system_data_sel
	mov ds,bx
	mov cx,OFFSET system_size
	movzx eax,cx
	mov bx,temp_sel
	AllocateFixedSystemMem
	xor si,si
	xor di,di
	rep movsb
	mov si,bx
	mov di,system_data_sel
	mov ax,gdt_sel
	mov ds,ax
	mov es,ax
	movsd
	movsd	
	popa
	pop es
	pop ds
	ret
init_system	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:	Kernel startup procedure
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init:
	call ZeroRam
	call MarkupRam
;
    mov ax,flat_sel
    mov ds,ax
	mov ax,gdt_sel
	mov es,ax
;
	call AllocateRam
	mov bx,idt_sel
	mov word ptr es:[bx],7FFh
	mov es:[bx+2],esi
	lidt fword ptr es:[bx]
	mov ah,92h
	xchg ah,es:[bx+5]
	xor al,al
	mov es:[bx+6],ax
;
	call init_pretask_traps
;
	call AllocateRam
	mov edx,esi
	mov bx,kernel_stack
	mov ecx,800h
	push cs
	call create_data_sel16
;
	add edx,800h
	mov bx,virt_tss
	mov ecx,400h
	push cs
	call create_tss_sel
	ltr bx
;
	add edx,400h
	mov bx,kernel_tss
	mov ecx,400h
	push cs
	call create_data_sel16
;
	mov ds,bx
	mov ds:tss_cs,cs
	mov dword ptr ds:tss_eip,OFFSET prot_init
	mov ds:tss_ss,kernel_stack
	mov ds:tss_esp,800h
	mov ds:tss_ds,0
	mov ds:tss_es,0
	mov ds:tss_fs,0
	mov ds:tss_gs,0
	mov ds:tss_ldt,0
	mov dword ptr ds:tss_eflags,0
	mov dword ptr ds:tss_back_link,0
	mov ds:tss_t,0
	mov ds:tss_bitmap,800h
	xor ax,ax
	mov ds,ax
	push cs
	call create_tss_sel
;
	xor ax,ax
	mov ds,ax
	mov es,ax
	mov fs,ax
	mov gs,ax
	lldt ax
;
	db 0EAh
	dw 0,kernel_tss

prot_init:
	cli
	call init_pre_tasking
	call init_boot_system
	call init_paging
	call init_physical_dir
	call start_paging
	call init_physical
	call init_paging_trap
	call create_mem
	call create_gdt
	call init_osgate
	call init_protseg
	call init_usergate
	call init_virtgate
	call init_virt_pm_usergate
	call init_mem
	call init_gdt
	call init_idt
	call init_system
	call move_adapters
	call init_paging_gates
	call init_physical_gates
	call init_mem_sels
	call init_systemgate
	call init_state
	call init_task
	call init_io
	call init_ldt
	call init_app
	call init_thread
	call init_int
	call init_irq
	call init_trap_vectors
	call init_env
	call init_exec
	call init_device
	call init_first_process
	call init_first_thread
	int 3
stop_l:
	int 3
	jmp stop_l
	
code	ENDS

.186

	END init
