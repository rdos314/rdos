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
; PAGING.ASM
; Paging & page fault handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  Paging

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE os.def
INCLUDE os.inc
INCLUDE user.def
INCLUDE user.inc
INCLUDE system.inc

	extrn create_data_sel16:near
	extrn create_call_gate_sel16:near
	extrn create_int_gate_sel:near
	extrn create_tss_sel:near

	extrn allocate_physical:near
	extrn free_physical:near
	extrn AllocateRam:near
	extrn prot_exception:near
	
code	SEGMENT byte public 'CODE'

.386p

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_flat_dir
;
;		DESCRIPTION:	Setup flat (identity) mapped page-tables
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_flat_dir	Proc near
	push ds
	push eax
	push bx
	push cx
	push edx
;
	mov bx,sys_dir_sel
	mov ecx,1000h
	mov edx,cr3
	and dx,0F000h
	push cs
	call create_data_sel16
;
	mov ds,bx
	xor eax,eax
	mov cx,400h
	xor bx,bx
init_empty_dir:
	mov [bx],eax
	add bx,4
	loop init_empty_dir
;
	pop edx
	pop cx
	pop bx
	pop eax
	pop ds
	ret
init_flat_dir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			map_dir
;
;		DESCRIPTION:	Map dir selectors
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_dir	Proc near
	mov ax,sys_dir_sel
	mov ds,ax
	mov eax,cr3
	mov bx,sys_page_linear SHR 20
	mov al,3
	mov [bx],eax
	mov bx,process_page_linear SHR 20
	mov [bx],eax
	ret
map_dir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			map_flat
;
;		DESCRIPTION:	Map a page flat
;
;		PARAMETERS:		EDX			Linear base address
;						ECX			Number of bytes to map
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_flat	Proc near
	push ds
	pushad
;
	or ecx,ecx
	jz map_flat_done

map_flat_more:
	mov bx,sys_dir_sel
	mov ds,bx
	mov ebx,edx
	shr ebx,22
	shl bx,2
	mov edi,[bx]
	or edi,edi
	jnz map_flat_do
;
	call AllocateRam
	mov edi,esi
	or si,3
	mov [bx],esi
;
	mov ax,flat_sel
	mov ds,ax
	push cx
	mov cx,400h
	xor eax,eax
map_flat_init_loop:
	mov [edi],eax
	add edi,4
	loop map_flat_init_loop
	sub edi,1000h
	pop cx

map_flat_do:
	mov ax,flat_sel
	mov ds,ax
	mov ebx,edx
	shr ebx,12
	and ebx,3FFh
	mov eax,400h
	shr ecx,12
	sub eax,ebx
	sub ecx,eax
	jnc map_flat_start
;
	add ecx,eax
	mov eax,ecx
	xor ecx,ecx

map_flat_start:
	shl bx,2
	shl ecx,12
	push ecx
	mov cx,ax
	and dx,0F000h
	or dx,803h
	and di,0F000h
	or di,bx

map_flat_loop:
	mov [edi],edx
	add edi,4
	add edx,1000h
	loop map_flat_loop
	pop ecx
	or ecx,ecx
	jnz map_flat_more

map_flat_done:
	popad
	pop ds
	ret
map_flat	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_paging
;
;		DESCRIPTION:	Create initial paging for system process
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_paging

init_paging	PROC near
	mov ax,system_data_sel
	mov es,ax
	call init_flat_dir
	call map_dir
;
	xor edx,edx
	mov ecx,es:alloc_base
	add ecx,1000h
	call map_flat
;
	mov edx,es:rom1_base
	mov ecx,es:rom1_size
	call map_flat
;
	mov edx,es:rom2_base
	mov ecx,es:rom2_size
	call map_flat

init_paging_ram:
	mov ecx,es:ram2_size
	or ecx,ecx
	jz init_paging_done
;
	mov edx,0A0000h
	mov ecx,100000h
	sub ecx,edx
	call map_flat
	
init_paging_done:
	ret
init_paging	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			start_paging
;
;		DESCRIPTION:	Start paging hardware
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public start_paging

start_paging	Proc near
	mov eax,cr0
	or eax,80000000h
	mov cr0,eax
;
	mov bx,sys_dir_sel
	mov ecx,1000h
	mov edx,sys_page_linear + (sys_page_linear SHR 10)
	push cs
	call create_data_sel16
;
	mov bx,sys_page_sel
	mov edx,sys_page_linear
	mov ecx,400000h
	push cs
	call create_data_sel16
;
	mov bx,process_dir_sel
	mov ecx,1000h
	mov edx,process_page_linear + (process_page_linear SHR 10)
	push cs
	call create_data_sel16
;
	mov bx,process_page_sel
	mov edx,process_page_linear
	mov ecx,400000h
	push cs
	call create_data_sel16
	ret
start_paging	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_process_paging
;
;		DESCRIPTION:	Init process paging
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_process_paging

init_process_paging	Proc near
	mov ax,sys_page_sel
	mov ds,ax
	mov ax,system_data_sel
	mov es,ax
	mov ecx,es:rom1_size
	or ecx,ecx
	jz unmap_done1
;
	mov edx,es:rom1_base
	add ecx,edx
	and dx,0F000h
	dec ecx
	and cx,0F000h
	add ecx,1000h
	sub ecx,edx
	shr edx,10
	shr ecx,12

unmap_loop1:
	mov dword ptr [edx],0
	add edx,4
	loop unmap_loop1

unmap_done1:
	mov ecx,es:rom2_size
	or ecx,ecx
	jz unmap_done2
;
	mov edx,es:rom2_base
	add ecx,edx
	and dx,0F000h
	dec ecx
	and cx,0F000h
	add ecx,1000h
	sub ecx,edx
	shr edx,10
	shr ecx,12

unmap_loop2:
	mov dword ptr [edx],0
	add edx,4
	loop unmap_loop2

unmap_done2:
	mov ax,sys_dir_sel
	mov ds,ax
	mov bx,sys_page_linear SHR 20
	mov edx,[bx]
	and dx,0F000h
;
	mov ax,sys_page_sel
	mov ds,ax
	mov ax,process_page_sel
	mov es,ax
	mov ebx,4

free_startup_ram_loop:
	mov eax,[ebx]
	test al,1
	jz free_startup_ram_done
;
	and ax,0F000h
	cmp eax,edx
	jae free_startup_zero
;
	FreePhysical

free_startup_zero:
	xor eax,eax
	mov [ebx],eax
	mov es:[ebx],eax
	add ebx,4
	jmp free_startup_ram_loop

free_startup_ram_done:	
	mov eax,cr3
	mov cr3,eax
	ret
init_process_paging	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			free_process_paging
;
;		DESCRIPTION:	Free process paging
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public free_process_paging

free_process_paging	Proc near
	mov bx,process_page_sel
	mov ds,bx
	mov bx,process_dir_sel
	mov es,bx
	xor esi,esi
	mov cx,flat_size SHR 22
	xor edi,edi

free_process_dir_loop:
	mov eax,es:[edi]
	or eax,eax
	jz free_process_next_dir
;
	push cx
	mov cx,400h

free_process_page_loop:
	xor eax,eax
	xchg eax,[esi]
	test ax,1
	jz free_process_page_next
;
	test ax,800h
	jnz free_process_page_next
;
	FreePhysical

free_process_page_next:
	add esi,4
	loop free_process_page_loop
;
	pop cx
	xor eax,eax
	xchg eax,es:[edi]
	FreePhysical
	jmp free_process_next_dir_page
	
free_process_next_dir:
	add esi,1000h

free_process_next_dir_page:
	add edi,4
	loop free_process_dir_loop
;
	mov cx,400h - (flat_size SHR 22)
	mov bx,sys_dir_sel
	mov ds,bx

free_global_loop:
	mov eax,es:[edi]
	test al,1
	jz free_global_next
;
	and ax,0F000h
	mov ebx,[edi]
	and bx,0F000h
	cmp eax,ebx
	je free_global_next
;
	cmp edi,fixed_process_linear SHR 20
	je free_global_next
;
	cmp edi,process_page_linear SHR 20
	je free_global_next
;
	xor eax,eax
	xchg eax,es:[edi]
	FreePhysical

free_global_next:
	add edi,4
	loop free_global_loop
	ret
free_process_paging	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			sys_dir_fault_user
;
;		DESCRIPTION:	Pagefault in user system page directory
;
;		PARAMETERS:		EAX		page fault address (not in dir)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sys_dir_fault_user	Proc near
	push eax
	mov bx,sys_dir_sel
	mov ds,bx
	shr eax,20
	and ax,0FFCh
	mov bx,ax
	push cs
	call allocate_physical
	mov al,7
	mov [bx],eax	
	pop eax
;
	shr eax,10
	and ax,0F000h
	mov bx,sys_page_sel
	mov ds,bx
	mov cx,400h
	xor ebx,ebx
sys_dir_fault_user_init:
	mov [eax],ebx
	add eax,4
	loop sys_dir_fault_user_init
	ret
sys_dir_fault_user	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			sys_dir_fault_system
;
;		DESCRIPTION:	Pagefault in system system page directory
;
;		PARAMETERS:		EAX		page fault address (not in dir)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sys_dir_fault_system	Proc near
	push eax
	mov bx,sys_dir_sel
	mov ds,bx
	shr eax,20
	and ax,0FFCh
	mov bx,ax
	push cs
	call allocate_physical
	mov al,3
	mov [bx],eax	
	pop eax
;
	shr eax,10
	and ax,0F000h
	mov bx,sys_page_sel
	mov ds,bx
	mov cx,400h
	xor ebx,ebx
sys_dir_fault_system_init:
	mov [eax],ebx
	add eax,4
	loop sys_dir_fault_system_init
	ret
sys_dir_fault_system	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			sys_dir_fault
;
;		DESCRIPTION:	Pagefault in system page directory
;
;		PARAMETERS:		EAX		page fault address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sys_dir_fault_tab:
sf0	DW OFFSET page_fault_error_sys_dir
sf1	DW OFFSET page_fault_error_sys_dir
sf2	DW OFFSET page_fault_error_sys_dir
sf3	DW OFFSET page_fault_error_sys_dir
sf4	DW OFFSET page_fault_error_sys_dir
sf5	DW OFFSET page_fault_error_sys_dir
sf6	DW OFFSET page_fault_error_sys_dir
sf7	DW OFFSET sys_dir_fault_system
sf8	DW OFFSET page_fault_error_sys_dir
sf9	DW OFFSET page_fault_error_sys_dir
sfA	DW OFFSET page_fault_error_sys_dir
sfB	DW OFFSET page_fault_error_sys_dir
sfC	DW OFFSET page_fault_error_sys_dir
sfD	DW OFFSET page_fault_error_sys_dir
sfE	DW OFFSET sys_dir_fault_system
sfF	DW OFFSET sys_dir_fault_system

sys_dir_fault	Proc near
	push edi
	sub eax,sys_page_linear
	shl eax,10
	mov edi,eax
	shr edi,28
	add di,di
	call word ptr cs:[di].sys_dir_fault_tab
	pop edi
	ret
sys_dir_fault	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			process_dir_fault_user
;
;		DESCRIPTION:	Pagefault in user process page directory
;
;		PARAMETERS:		EAX		page fault address (not in dir)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_dir_fault_move	Proc near
	mov bx,sys_dir_sel
	mov ds,bx
	mov ebx,eax
	shr ebx,20
	and bx,0FFCh
	mov ecx,[bx]
	test cl,1
	jnz sys_dir_valid
	push bx
	mov eax,edx
	add eax,sys_page_linear
	call sys_dir_fault
	pop bx
	mov ax,sys_dir_sel
	mov ds,ax
	mov ecx,[bx]
sys_dir_valid:
	mov ax,process_dir_sel
	mov ds,ax
	mov [bx],ecx
	ret
process_dir_fault_move	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			process_dir_fault_local
;
;		DESCRIPTION:	Pagefault in local process page directory
;
;		PARAMETERS:		EAX		page fault address (not in dir)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_dir_fault_local	Proc near
	push eax
	mov bx,process_dir_sel
	mov ds,bx
	shr eax,20
	and ax,0FFCh
	mov bx,ax
	push cs
	call allocate_physical
	mov al,7
	mov [bx],eax	
	pop eax
;
	shr eax,10
	and ax,0F000h
	mov bx,process_page_sel
	mov ds,bx
	mov cx,400h
	xor ebx,ebx
process_dir_fault_local_init:
	mov [eax],ebx
	add eax,4
	loop process_dir_fault_local_init
	ret
process_dir_fault_local	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			process_dir_fault
;
;		DESCRIPTION:	Pagefault in process page directory
;
;		PARAMETERS:		EAX		page fault address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

process_dir_fault_tab:
jf0	DW OFFSET process_dir_fault_local
jf1	DW OFFSET process_dir_fault_local
jf2	DW OFFSET process_dir_fault_local
jf3	DW OFFSET process_dir_fault_local
jf4	DW OFFSET process_dir_fault_local
jf5	DW OFFSET process_dir_fault_local
jf6	DW OFFSET process_dir_fault_local
jf7	DW OFFSET process_dir_fault_move
jf8	DW OFFSET process_dir_fault_local
jf9	DW OFFSET process_dir_fault_move
jfA	DW OFFSET process_dir_fault_move
jfB	DW OFFSET process_dir_fault_move
jfC	DW OFFSET process_dir_fault_move
jfD	DW OFFSET process_dir_fault_move
jfE	DW OFFSET process_dir_fault_move
jfF	DW OFFSET process_dir_fault_move

process_dir_fault	Proc near
	push edx
	push edi
	sub eax,process_page_linear
	mov edx,eax
	shl eax,10
	mov edi,eax
	shr edi,28
	add di,di
	call word ptr cs:[di].process_dir_fault_tab
	pop edi
	pop edx
	ret
process_dir_fault	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			alias_dir_fault_user
;
;		DESCRIPTION:	Pagefault in user alias page directory
;
;		PARAMETERS:		EAX		page fault address (not in dir)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alias_dir_fault_move	Proc near
	mov bx,sys_dir_sel
	mov ds,bx
	mov ebx,eax
	shr ebx,20
	and bx,0FFCh
	mov ecx,[bx]
	test cl,1
	jnz alias_sys_dir_valid
	push bx
	mov eax,edx
	add eax,sys_page_linear
	call sys_dir_fault
	pop bx
	mov ax,sys_dir_sel
	mov ds,ax
	mov ecx,[bx]
alias_sys_dir_valid:
	mov ax,process_page_sel
	mov ds,ax
	mov [ebx+esi],ecx
	ret
alias_dir_fault_move	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			alias_dir_fault_local
;
;		DESCRIPTION:	Pagefault in local alias page directory
;
;		PARAMETERS:		EAX		page fault address (not in dir)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alias_dir_fault_local	Proc near
	push eax
	mov bx,process_page_sel
	mov ds,bx
	shr eax,20
	and ax,0FFCh
	mov ebx,eax
	push cs
	call allocate_physical
	mov al,7
	mov [ebx+esi],eax	
	pop eax
;
	mov ebx,esi
	shl ebx,10
	shr eax,10
	add eax,ebx
	and ax,0F000h
	mov bx,flat_sel
	mov ds,bx
	mov cx,400h
	xor ebx,ebx
alias_dir_fault_local_init:
	mov [eax],ebx
	add eax,4
	loop alias_dir_fault_local_init
	ret
alias_dir_fault_local	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			alias_dir_fault
;
;		DESCRIPTION:	Pagefault in alias page directory
;
;		PARAMETERS:		EAX		page fault address
;						ESI		page directory base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alias_dir_fault_tab:
af0	DW OFFSET alias_dir_fault_local
af1	DW OFFSET alias_dir_fault_local
af2	DW OFFSET alias_dir_fault_local
af3	DW OFFSET alias_dir_fault_local
af4	DW OFFSET alias_dir_fault_local
af5	DW OFFSET alias_dir_fault_local
af6	DW OFFSET alias_dir_fault_local
af7	DW OFFSET alias_dir_fault_move
af8	DW OFFSET alias_dir_fault_local
af9	DW OFFSET alias_dir_fault_move
afA	DW OFFSET alias_dir_fault_move
afB	DW OFFSET alias_dir_fault_move
afC	DW OFFSET alias_dir_fault_move
afD	DW OFFSET alias_dir_fault_move
afE	DW OFFSET alias_dir_fault_move
afF	DW OFFSET alias_dir_fault_move

alias_dir_fault	Proc near
	push edx
	push esi
	push edi
	mov esi,eax
	and esi,0FFC00000h
	sub eax,esi
	shr esi,10
	mov edx,eax
	shl eax,10
	mov edi,eax
	shr edi,28
	add di,di
	call word ptr cs:[di].alias_dir_fault_tab
	pop edi
	pop esi
	pop edx
	ret
alias_dir_fault	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			page_fault_user
;
;		DESCRIPTION:	Pagefault in global memory
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pm_es	EQU -12
pm_ecx	EQU -16
pm_di	EQU -18

page_fault_user	PROC near
	mov ax,[bp].vm_eflags
	and ax,NOT 4500h
	push ax
	mov eax,cr2
	popf
	mov bx,process_page_sel
	mov ds,bx
	mov ebx,eax
	shr ebx,10
	and bx,0FFFCh
	mov ecx,[ebx]
	test cl,1
	jnz page_fault_user_retry
	test cl,2
	jnz page_fault_user_valid
;
	cmp eax,local_page_linear
	jb page_fault_user_valid
	cmp eax,flat_size
	jb page_fault_user_invalid

page_fault_user_valid:
	and cl,7
	cmp cl,6
	jne page_fault_user_normal
;
	test ch,80h
	jz page_fault_em_normal
;
	pop ax
	pop di
	pop ecx
	pop es
	push ax
	mov al,0Eh
	EmulateOpcode
	pop ax
	pop ds
	pop ebx	
	pop eax
	and byte ptr [bp+2].vm_eflags, NOT 1
	pop bp
	add sp,4
	iretd

page_fault_em_normal:
	push edx
	mov edx,eax
	push cs
	push OFFSET page_fault_user_hook_end
	mov ax,[ebx]
	and ax,0FFF8h
	push ax
	push word ptr [ebx+2]
	retf
page_fault_user_hook_end:
	pop edx
	jmp page_fault_user_retry

page_fault_user_invalid:
	mov al,14
	call prot_exception

page_fault_user_normal:
	push cs
	call allocate_physical
	mov al,7
	mov [ebx],eax
page_fault_user_retry:
	ret
page_fault_user	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			page_fault_system
;
;		DESCRIPTION:	pagefault in system memory
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_system	PROC near
	mov ax,[bp].vm_eflags
	and ax,NOT 4500h
	push ax
	mov eax,cr2
	popf
	cmp eax,sys_page_linear
	jz page_fault_in_sys_dir
	jc page_fault_not_sys_dir
	cmp eax,sys_page_linear+400000h
	jnc page_fault_not_sys_dir
page_fault_in_sys_dir:
	jmp sys_dir_fault
page_fault_not_sys_dir:
	cmp eax,process_page_linear
	jz page_fault_in_process_dir
	jc page_fault_not_process_dir
	cmp eax,process_page_linear+400000h
	jnc page_fault_not_process_dir
page_fault_in_process_dir:
	jmp process_dir_fault
page_fault_not_process_dir:
	mov bx,process_page_sel
	mov ds,bx
	mov ebx,eax
	shr ebx,10
	and bx,0FFFCh
	mov al,[ebx]
	test al,1
	jnz page_fault_system_retry
	push cs
	call allocate_physical
	mov al,7
	mov [ebx],eax
page_fault_system_retry:
	ret
page_fault_system	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			page_fault_alias
;
;		DESCRIPTION:	Pagefault in aliased memory
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_alias	PROC near
	mov ax,[bp].vm_eflags
	and ax,NOT 4500h
	push ax
	mov eax,cr2
	popf
	mov bx,process_page_sel
	mov ds,bx
	mov ebx,eax
	shr ebx,10
	and bx,0FFFCh
	mov al,[ebx]
	test al,1
	jnz page_fault_alias_retry
	call alias_dir_fault
page_fault_alias_retry:
	ret
page_fault_alias	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			page_fault_dir
;
;		DESCRIPTION:	pagefault in page-alloc memory
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_dir	PROC near
	mov ax,[bp].vm_eflags
	and ax,NOT 4500h
	push ax
	mov eax,cr2
	popf
	mov bx,process_page_sel
	mov ds,bx
	mov ebx,eax
	shr ebx,10
	and bx,0FFFCh
	mov eax,[ebx]
	ret
page_fault_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			pagefault_error
;
;		DESCRIPTION:	pagefault error
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_error_alias_dir:
	pop edi
	pop esi
	pop edx
	jmp page_fault_error2

page_fault_error_proc_dir:
	pop edi
	pop edx
	jmp page_fault_error2

page_fault_error_sys_dir:
	pop edi
	jmp page_fault_error2

page_fault_error2:
	pop ax
	mov eax,cr2
	pop di
	pop ecx
	pop es
	pop ds
	pop ebx
	pop eax
	pop bp
	add sp,12
	int 3
	mov al,14
	int 46h

page_fault_error:
	pop ax
	mov eax,cr2
	sti
	int 3
	pop di
	pop cx
	pop es
	mov al,14
	call prot_exception
	pop ds
	pop ebx	
	pop eax
	and byte ptr [bp+2].vm_eflags, NOT 1
	pop bp
	add sp,4
	iretd

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PAGEFAULT_TRAP
;
;		DESCRIPTION:	Pagefault handler
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

page_fault_tab:
pf0	DW OFFSET page_fault_user
pf1	DW OFFSET page_fault_user
pf2	DW OFFSET page_fault_user
pf3	DW OFFSET page_fault_user
pf4	DW OFFSET page_fault_user
pf5	DW OFFSET page_fault_user
pf6	DW OFFSET page_fault_user
pf7	DW OFFSET page_fault_user
pf8	DW OFFSET page_fault_user
pf9	DW OFFSET page_fault_alias
pfA	DW OFFSET page_fault_alias
pfB	DW OFFSET page_fault_error2
pfC	DW OFFSET page_fault_error2
pfD	DW OFFSET page_fault_error2
pfE	DW OFFSET page_fault_system
pfF	DW OFFSET page_fault_system

pagefault_trap:
	push bp
	mov bp,sp
	push eax
	push ebx
	push ds
	push es
	push ecx
	push di
	mov eax,[bp].vm_err
	test ax,1
	jz trap_not_present
trap_error_do:
	call page_fault_error
	jmp trap_14_done
trap_not_present:
	mov eax,cr2
	shr eax,28
	and ax,0Fh
	mov di,ax
	add di,di
	call word ptr cs:[di].page_fault_tab
trap_14_done:
	pop di
	pop ecx
	pop es
	pop ds
	pop ebx	
	pop eax
	and byte ptr [bp+2].vm_eflags, NOT 1
	pop bp
	add sp,4
	iretd

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_PAGE
;
;		DESCRIPTION:	Hook for a specified linear address range
;
;		PARAMETERS:		EAX		Size
;						EDX		Linear base
;						ES:DI	Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_page_name	DB 'Hook Page',0

hook_page	PROC far
	push ds
	push eax
	push ecx
	push edx
;
	mov cx,process_page_sel
	mov ds,cx
;
	or eax,eax
	jz hook_page_done
;
	mov ecx,eax
	add ecx,edx
	and dx,0F000h
	dec ecx
	and cx,0F000h
	add ecx,1000h
	sub ecx,edx
	shr edx,10
	shr ecx,12

hook_pagef_mark:
	mov eax,[edx]
	test al,1
	jz hook_pagef_do
;
	push cs
	call free_physical
	mov eax,cr3
	mov cr3,eax
	mov eax,2

hook_pagef_do:
	and al,6
	jz hook_pagef_next
;
	mov ax,es
	or al,6
	mov [edx],ax
	mov [edx+2],di

hook_pagef_next:
	add edx,4
	loop hook_pagef_mark

hook_page_done:
	pop edx
	pop ecx
	pop eax
	pop ds
	ret
hook_page	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UNHOOK_PAGE
;
;		DESCRIPTION:	Unhook for a specified linear address range
;
;		PARAMETERS:		EAX		Size
;						EDX		Linear base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unhook_page_name	DB 'Unhook Page',0

unhook_page	PROC far
	push ds
	push eax
	push ecx
	push edx
;
	mov cx,process_page_sel
	mov ds,cx
;
	or eax,eax
	jz unhook_pagef_done
;
	mov ecx,eax
	add ecx,edx
	and dx,0F000h
	dec ecx
	and cx,0F000h
	add ecx,1000h
	sub ecx,edx
	shr edx,10
	shr ecx,12

unhook_pagef_mark:
	mov eax,[edx]
	test al,1
	jnz unhook_pagef_next
;
	and al,6
	cmp al,6
	jne unhook_pagef_next
;
	mov dword ptr [edx],2

unhook_pagef_next:
	add edx,4
	loop unhook_pagef_mark

unhook_pagef_done:
	pop edx
	pop ecx
	pop eax
	pop ds
	ret
unhook_page	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SET_PAGE_EMULATE
;
;		DESCRIPTION:	Hook page to emulate contents
;
;		PARAMETERS:		EAX		Size
;						EDX		Linear base
;						ES:DI	Emulation callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_page_emulate_name	DB 'Set Page Emulate',0

set_page_emulate	PROC far
	push ds
	push eax
	push ecx
	push edx
;
	mov cx,sys_page_sel
	mov ds,cx
	mov ecx,eax
	dec ecx
	shr ecx,12
	inc cx
	shr edx,10
	and dx,0FFFCh
	mov ax,es
	or ax,8006h
set_emul_mark:
	mov [edx],ax
	mov word ptr [edx+2],di
	add edx,4
	loop set_emul_mark
	pop edx
	pop ecx
	pop eax
	pop ds
	ret
set_page_emulate	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SET_PAGE_KERNEL	
;
;		DESCRIPTION:	Set page access to kernel only
;
;		PARAMETERS:		EAX		Size
;						EDX		Linear base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_page_kernel_name	DB 'Set Page Kernel',0

set_page_kernel	PROC far
	push ds
	push eax
	push ecx
	push edx
;
	mov cx,process_page_sel
	mov ds,cx
;
	or eax,eax
	jz set_kernel_done
;
	mov ecx,eax
	add ecx,edx
	and dx,0F000h
	dec ecx
	and cx,0F000h
	add ecx,1000h
	sub ecx,edx
	shr edx,10
	shr ecx,12

set_kernel_mark:
	mov eax,[edx]
	test al,1
	jnz set_kernel_allocated
	push cs
	call allocate_physical
	and ax,0F000h
	or ax,803h
	mov [edx],eax
set_kernel_allocated:
	mov eax,[edx]
	and al,NOT 4
	mov [edx],eax
	add edx,4
	loop set_kernel_mark

set_kernel_done:
	pop edx
	pop ecx
	pop eax
	pop ds
	ret
set_page_kernel	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SET_FLAT_LINEAR_VALID
;
;		DESCRIPTION:	Set flat page to valid
;
;		PARAMETERS:		EAX		Size
;						EDX		Offset in user-mode flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_flat_linear_valid_name	DB 'Set Flat Linear Valid',0

set_flat_linear_valid	PROC far
	push ds
	push eax
	push ecx
	push edx
;
	mov cx,process_page_sel
	mov ds,cx
;
	or eax,eax
	jz set_valid_done
;
	add edx,local_page_linear
	cmp edx,local_page_linear
	jc set_valid_done
;
	cmp edx,flat_size
	jae set_valid_done
;
	mov ecx,eax
	add ecx,edx
	and dx,0F000h
	dec ecx
	and cx,0F000h
	add ecx,1000h
	sub ecx,edx
	shr edx,10
	shr ecx,12

set_valid_mark:
	mov eax,[edx]
	test al,1
	jnz set_valid_next
;
	and al,6
	jz set_valid_next
;
	cmp al,6
	je set_valid_next
;
	mov eax,[edx]
	and al,NOT 6
	or al,2
	mov [edx],eax

set_valid_next:
	add edx,4
	loop set_valid_mark

set_valid_done:
	pop edx
	pop ecx
	pop eax
	pop ds
	retf32
set_flat_linear_valid	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SET_FLAT_LINEAR_INVALID
;
;		DESCRIPTION:	Set flat page to invalid
;
;		PARAMETERS:		EAX		Size
;						EDX		Offset in user-mode flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_flat_linear_invalid_name	DB 'Set Flat Linear Invalid',0

set_flat_linear_invalid	PROC far
	push ds
	push eax
	push ecx
	push edx
;
	mov cx,process_page_sel
	mov ds,cx
;
	or eax,eax
	jz short set_inv_done
;
	add edx,local_page_linear
	cmp edx,local_page_linear
	jc set_inv_done
;
	cmp edx,flat_size
	jae set_inv_done
;
	mov ecx,eax
	add ecx,edx
	and dx,0F000h
	dec ecx
	and cx,0F000h
	add ecx,1000h
	sub ecx,edx
	shr edx,10
	shr ecx,12

set_inv_mark:
	mov eax,[edx]
	test al,1
	jz set_inv_free
;
	push ax
	push cs
	call free_physical
	pop ax
	not al
	and al,2
	shl al,4
	or al,4
	movzx eax,al
	mov [edx],eax
	jmp set_inv_next

set_inv_free:	
	and al,6
	jz set_inv_next
;
	cmp al,6
	je set_inv_next
;
	mov eax,[edx]
	and al,NOT 6
	or al,4
	mov [edx],eax

set_inv_next:
	add edx,4
	loop set_inv_mark

set_inv_done:
	mov eax,cr3
	mov cr3,eax
;
	pop edx
	pop ecx
	pop eax
	pop ds
	retf32
set_flat_linear_invalid	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SET_FLAT_LINEAR_READWRITE
;
;		DESCRIPTION:	Set flat page access to read/write
;
;		PARAMETERS:		EAX		Size
;						EDX		Offset in user-mode flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_flat_linear_readwrite_name	DB 'Set Flat Linear Read/Write',0

set_flat_linear_readwrite	PROC far
	push ds
	push eax
	push ecx
	push edx
;
	mov cx,process_page_sel
	mov ds,cx
;
	or eax,eax
	jz set_readwrite_done
;
	add edx,local_page_linear
	cmp edx,local_page_linear
	jc set_readwrite_done
;
	cmp edx,flat_size
	jae set_readwrite_done
;
	mov ecx,eax
	add ecx,edx
	and dx,0F000h
	dec ecx
	and cx,0F000h
	add ecx,1000h
	sub ecx,edx
	shr edx,10
	shr ecx,12

set_readwrite_mark:
	mov eax,[edx]
	test al,1
	jnz set_readwrite_allocated
	and al,6
	jz set_readwrite_next
;
	cmp al,6
	je set_readwrite_next
;
	and byte ptr [edx],NOT 20h
	jmp set_readwrite_next

set_readwrite_allocated:
	or al,2
	mov [edx],al

set_readwrite_next:
	add edx,4
	loop set_readwrite_mark

set_readwrite_done:
	mov eax,cr3
	mov cr3,eax
;
	pop edx
	pop ecx
	pop eax
	pop ds
	retf32
set_flat_linear_readwrite	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SET_FLAT_LINEAR_READ
;
;		DESCRIPTION:	Set flat page access to read-only
;
;		PARAMETERS:		EAX		Size
;						EDX		Offset in user-mode flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_flat_linear_read_name	DB 'Set Flat Linear Read',0

set_flat_linear_read	PROC far
	push ds
	push eax
	push ecx
	push edx
;
	mov cx,process_page_sel
	mov ds,cx
;
	or eax,eax
	jz set_read_done
;
	add edx,local_page_linear
	cmp edx,local_page_linear
	jc set_read_done
;
	cmp edx,flat_size
	jae set_read_done
;
	mov ecx,eax
	add ecx,edx
	and dx,0F000h
	dec ecx
	and cx,0F000h
	add ecx,1000h
	sub ecx,edx
	shr edx,10
	shr ecx,12

set_read_mark:
	mov eax,[edx]
	test al,1
	jnz set_read_allocated
;
	and al,6
	jz set_read_mark_next
;
	cmp al,6
	je set_read_mark_next
;
	or byte ptr [edx],20h
	jmp set_read_mark_next

set_read_allocated:
	and al,NOT 2
	mov [edx],al

set_read_mark_next:
	add edx,4
	loop set_read_mark

set_read_done:
	pop edx
	pop ecx
	pop eax
	pop ds
	retf32
set_flat_linear_read	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_paging_gates
;
;		DESCRIPTION:	Init paging call-gates
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_paging_gates

init_paging_gates	PROC near
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET hook_page
	mov di,OFFSET hook_page_name
	xor cl,cl
	mov ax,hook_page_nr
	RegisterOsGate
;
	mov si,OFFSET unhook_page
	mov di,OFFSET unhook_page_name
	xor cl,cl
	mov ax,unhook_page_nr
	RegisterOsGate
;
	mov si,OFFSET set_page_emulate
	mov di,OFFSET set_page_emulate_name
	xor cl,cl
	mov ax,set_page_emulate_nr
	RegisterOsGate
;
	mov si,OFFSET set_page_kernel
	mov di,OFFSET set_page_kernel_name
	xor cl,cl
	mov ax,set_page_kernel_nr
	RegisterOsGate
;
	mov si,OFFSET set_flat_linear_invalid
	mov di,OFFSET set_flat_linear_invalid_name
	xor cl,cl
	mov ax,set_flat_linear_invalid_nr
	RegisterUserGate
;
	mov si,OFFSET set_flat_linear_valid
	mov di,OFFSET set_flat_linear_valid_name
	xor cl,cl
	mov ax,set_flat_linear_valid_nr
	RegisterUserGate
;
	mov si,OFFSET set_flat_linear_read
	mov di,OFFSET set_flat_linear_read_name
	xor cl,cl
	mov ax,set_flat_linear_read_nr
	RegisterUserGate
;
	mov si,OFFSET set_flat_linear_readwrite
	mov di,OFFSET set_flat_linear_readwrite_name
	xor cl,cl
	mov ax,set_flat_linear_readwrite_nr
	RegisterUserGate
;
	ret
init_paging_gates	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_paging_trap
;
;		DESCRIPTION:	Setup page-fault handler
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_paging_trap

init_paging_trap	PROC near
	mov ax,cs
	mov ds,ax
	mov esi,OFFSET pagefault_trap
	xor bl,bl
	mov al,14
	push cs
	call create_int_gate_sel
	ret
init_paging_trap	ENDP
	
code	ENDS

	END
