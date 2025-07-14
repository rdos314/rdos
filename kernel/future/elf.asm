;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; ELF.ASM
; ELF (LINUX executable) loader
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE int.def
INCLUDE exec.def
INCLUDE elf.def
INCLUDE system.def
INCLUDE system.inc

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateLib
;
;		DESCRIPTION:    Create lib
;
;		PARAMETERS:     FS:ESI	Image name
;						BX		File handle
;						EDX		File offset of program header
;						AX		Object header size
;						CX		Object count
;
;		RETURNS:		ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateLib	Proc near
	push esi
	push edi
;
	push eax
	push ecx
	xor ecx,ecx
	push esi
create_lib_size_loop:
	mov al,fs:[esi]
	or al,al
	jz create_lib_size_ok
;
	cmp al,'.'
	jz create_lib_size_ok
	inc cx
	inc esi
	jmp create_lib_size_loop

create_lib_size_ok:
	pop esi
	movzx eax,cx
	mov edi,OFFSET lib_name
	add eax,edi
	inc eax
	AllocateSmallGlobalMem
;
	rep movs byte ptr es:[edi],fs:[esi]
	mov byte ptr es:[edi],0
	mov es:lib_usage_count,1
	push ds
	mov ax,es
	mov ds,ax
	InitSection ds:lib_section
	pop ds
;	
	mov es:lib_file_handle,bx
	pop ecx
	pop eax
	mov es:lib_file_offset,edx
	mov es:lib_object_size,ax
	mov es:lib_object_count,cx
	mov es:lib_proc_entries,0
	mov es:lib_offset_table,0
	mov es:lib_reloc_entries,0
	mov es:lib_init,0
	mov es:lib_fini,0
;
    mov es:mod_start_wait_for_debug_event_proc,0
    mov es:mod_stop_wait_for_debug_event_proc,0
    mov es:mod_is_debug_event_idle_proc,0
    mov es:mod_get_debug_event_proc,0
    mov es:mod_get_debug_event_data_proc,0
    mov es:mod_clear_debug_event_proc,0
    mov es:mod_continue_debug_event_proc,0
;
	pop edi
	pop esi
	ret
CreateLib	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InsertApp
;
;		DESCRIPTION:    Insert App image into module list
;
;		PARAMETERS:     ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertApp	Proc near
    push ds
    push es
    pushad
;
    GetThread
    mov ds,ax
    mov ds:p_loader,elf_loader_sel
;
;	mov word ptr ds:app_close_proc,OFFSET close_proc
;	mov word ptr ds:app_close_proc+2,cs
;
    popad
    pop es
    pop ds
    ret
InsertApp	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindLib
;
;		DESCRIPTION:    Search for a DLL or app module
;
;		PARAMETERS:     EDX		Virtual adress
;
;		RETURNS:		ES		Lib
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindLib	Proc near
	push ds
	push eax
	push bx
	push ecx
	push si
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov bx,ds:app_mod_id
    ModuleIdToSel
	jc find_lib_done
;
    mov ds,ax
    EnterSection ds:mod_section
;    mov ax,ds:mod_list
    or ax,ax
    jz find_lib_try_app

find_lib_dll_loop:
	mov es,ax
	mov ecx,edx
	sub ecx,es:mod_base
	jc find_lib_dll_next
;
	cmp ecx,es:mod_size
	jc find_lib_ok

find_lib_dll_next:
    mov ax,es:mod_next
    or ax,ax
    jne find_lib_dll_loop

find_lib_try_app:
    mov ax,ds
    mov es,ax
	mov ecx,edx
	sub ecx,es:mod_base
	jc find_lib_fail
;
	cmp ecx,es:mod_size
	jc find_lib_ok

find_lib_fail:
	LeaveSection ds:mod_section
	stc
	jmp find_lib_done

find_lib_ok:
	LeaveSection ds:mod_section
	clc

find_lib_done:
	pop si
	pop ecx
	pop bx
	pop eax
	pop ds
	ret
FindLib	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load_object
;
;		DESCRIPTION:    Demand load object
;
;		PARAMETERS:     EDX		LINEAR ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_object	Proc far
	push ds
	push es
	pushad
	mov eax,1
	UnhookPage
	mov ax,system_data_sel
	mov ds,ax
	sub edx,ds:flat_base
	mov ax,flat_data_sel
	mov ds,ax
;
	call FindLib
	jc load_object_done
;
	mov ds,es:lib_objects
	mov cx,es:lib_object_count
	xor si,si

load_object_loop:
	push cx
	mov eax,[si].ep_va
	cmp edx,eax
	jb load_object_next
;
	add eax,[si].ep_mem_size
	cmp edx,eax
	jae load_object_next
;
	and dx,0F000h
	mov bx,es:lib_file_handle
	mov edi,edx
	cmp edi,[si].ep_va
	jae load_object_start_ok
;
	mov edi,[si].ep_va

load_object_start_ok:
	mov eax,edi
	sub eax,[si].ep_va
	mov ecx,[si].ep_file_size
	sub ecx,eax
	cmp ecx,1000h
	jc load_object_size_ok
;
	mov ecx,1000h

load_object_size_ok:
	add eax,[si].ep_offset
	SetFilePos	
;
	push es
	mov ax,flat_data_sel
	mov es,ax
	UserGateForce32 read_file_nr
	add edi,eax
	mov ecx,1000h
	sub ecx,eax
	mov eax,[si].ep_mem_size
	sub eax,[si].ep_file_size
	cmp ecx,eax
	jc pad_object_size_ok
;
	mov ecx,eax

pad_object_size_ok:
	push ecx
	shr ecx,2
	xor eax,eax
	rep stos dword ptr es:[edi]
	pop ecx
	and ecx,3
	rep stos byte ptr es:[edi]
	pop es

load_object_next:
	pop cx
	add si,es:lib_object_size	
	sub cx,1
	jnz load_object_loop

load_object_done:
	popad
	pop es
	pop ds
	ret
load_object	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateImage
;
;		DESCRIPTION:    Create image
;
;		PARAMETERS:     ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateImage	Proc near
	push ds
	push es
	push fs
	push eax
	push cx
	push edx
	push si
	push edi
	push ebp
;
    mov ax,system_data_sel
    mov fs,ax
    mov ebp,fs:flat_base
;    
	mov ax,es
	mov fs,ax
	mov ax,fs:lib_object_size
	mul fs:lib_object_count
	push dx
	push ax
	pop eax
	AllocateSmallGlobalMem
	mov fs:lib_objects,es
	xor di,di
	mov cx,ax
	ReadFile
	cmp ax,cx
	jne create_image_fail
;
	mov cx,fs:lib_object_count
	or cx,cx
	jz create_image_fail
;
	mov edx,es:ep_va
	mov eax,es:ep_mem_size
	add eax,edx
	sub cx,1
	jz create_image_size_ok
;
	mov si,fs:lib_object_size

create_image_size_loop:
	mov edi,es:[si].ep_va
	cmp edi,edx
	ja create_image_size_not_before
;
	mov edx,edi

create_image_size_not_before:
	add edi,es:[si].ep_mem_size
	cmp edi,eax
	jb create_image_size_not_after
;
	mov eax,edi

create_image_size_not_after:
	add si,fs:lib_object_size	
	loop create_image_size_loop

create_image_size_ok:
	and dx,0F000h
	sub eax,edx
	dec eax
	and ax,0F000h
	add eax,1000h
	push edx
    add edx,ebp
	ReserveLocalLinear
	jnc create_image_alloced
;
	AllocateLocalLinear

create_image_alloced:
	sub edx,ebp
	SetFlatLinearInvalid
;
	mov fs:mod_base,edx
	mov fs:mod_size,eax	
	pop edx
	sub edx,fs:mod_base
	neg edx
	mov fs:lib_reloc,edx
;
	mov ax,es
	mov ds,ax
	mov ax,cs
	mov es,ax
	mov di,OFFSET load_object
	mov cx,fs:lib_object_count
	xor si,si

hook_object_loop:
	mov edx,[si].ep_va
	add edx,fs:lib_reloc
	mov [si].ep_va,edx
	add edx,ebp
	mov eax,[si].ep_mem_size
	HookPage
	add si,fs:lib_object_size	
	loop hook_object_loop
;
	clc
	jmp create_image_done

create_image_fail:
	stc

create_image_done:
    pop ebp
	pop edi
	pop si
	pop edx
	pop cx
	pop eax
	pop fs
	pop es
	pop ds
	ret
CreateImage	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitStack
;
;		DESCRIPTION:    Init stack
;
;		PARAMETERS:     ES	Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitStack	Proc near
	push eax
	push edx
;
	push fs
	mov eax,SIZE app_fs_data
	AllocateLocalLinear
	AllocateLdt
	or bx,7
	mov ecx,eax	
	CreateDataSelector32
	mov [bp].load_fs,bx
	mov fs,bx
	pop fs
;
    push ds
    mov ax,system_data_sel
    mov ds,ax
	mov eax,100000h
	AllocateLocalLinear
	sub edx,ds:flat_base
	add edx,eax
	mov word ptr [bp].load_ss,flat_data_sel
	mov [bp].load_esp,edx
	pop ds
;
	pop edx
	pop eax
	ret
InitStack	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitDynamic
;
;		DESCRIPTION:    Init dynamic section
;
;		PARAMETERS:     ES	Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DummyDynamic	Proc near
	ret
DummyDynamic	Endp

SetupRelocTable	Proc near
	mov eax,[edx+4]
	add eax,es:lib_reloc
	mov es:lib_reloc_table,eax
	ret
SetupRelocTable	Endp

SetupRelocEntries	Proc near
	mov eax,[edx+4]
	mov es:lib_reloc_entries,eax
	ret
SetupRelocEntries	Endp

SetupRelocSize	Proc near
	mov eax,[edx+4]
	mov es:lib_reloc_size,eax
	ret
SetupRelocSize	Endp

SetupProcTable	Proc near
	mov eax,[edx+4]
	add eax,es:lib_reloc
	mov es:lib_proc_table,eax
	ret
SetupProcTable	Endp

SetupProcEntries	Proc near
	mov eax,[edx+4]
	mov es:lib_proc_entries,eax
	ret
SetupProcEntries	Endp

SetupOffsetTable	Proc near
	mov eax,[edx+4]
	add eax,es:lib_reloc
	mov es:lib_offset_table,eax
	ret
SetupOffsetTable	Endp

SetupInit	Proc near
	mov eax,[edx+4]
	add eax,es:lib_reloc
	mov es:lib_init,eax
	ret
SetupInit	Endp

SetupFini	Proc near
	mov eax,[edx+4]
	add eax,es:lib_reloc
	mov es:lib_fini,eax
	ret
SetupFini	Endp

dynamic_tab:
dt00	DW OFFSET DummyDynamic
dt01	DW OFFSET DummyDynamic
dt02	DW OFFSET SetupProcEntries
dt03	DW OFFSET SetupOffsetTable
dt04	DW OFFSET DummyDynamic
dt05	DW OFFSET DummyDynamic
dt06	DW OFFSET DummyDynamic
dt07	DW OFFSET DummyDynamic
dt08	DW OFFSET DummyDynamic
dt09	DW OFFSET DummyDynamic
dt10	DW OFFSET DummyDynamic
dt11	DW OFFSET DummyDynamic
dt12	DW OFFSET SetupInit
dt13	DW OFFSET SetupFini
dt14	DW OFFSET DummyDynamic
dt15	DW OFFSET DummyDynamic
dt16	DW OFFSET DummyDynamic
dt17	DW OFFSET SetupRelocTable
dt18	DW OFFSET SetupRelocEntries
dt19	DW OFFSET SetupRelocSize
dt20	DW OFFSET DummyDynamic
dt21	DW OFFSET DummyDynamic
dt22	DW OFFSET DummyDynamic
dt23	DW OFFSET SetupProcTable

InitDynamic	Proc near
	push ds
	push eax
	push ebx
	push cx
	push edx
	push si
;
	mov ds,es:lib_objects
	mov cx,es:lib_object_count
	xor si,si

init_dynamic_loop:
	mov eax,[si].ep_type
	cmp eax,PT_DYNAMIC
	jne init_dynamic_next
;
	push ds
	push ecx
	push edx
	mov edx,[si].ep_va
	mov ecx,[si].ep_mem_size
	mov ax,flat_data_sel
	mov ds,ax

init_dynamic_entry_loop:
	mov ebx,[edx]
	cmp ebx,23
	ja init_dynamic_entry_next
;
	add bx,bx
	call word ptr cs:[bx].dynamic_tab

init_dynamic_entry_next:
	add edx,8
	sub ecx,8
	ja init_dynamic_entry_loop
;
	pop edx
	pop ecx
	pop ds

init_dynamic_next:
	add si,es:lib_object_size	
	sub cx,1
	jnz init_dynamic_loop
;
	pop si
	pop edx
	pop cx
	pop ebx
	pop eax
	pop ds
	ret
InitDynamic	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RunImage
;
;		DESCRIPTION:    Setup registers to run image
;
;		PARAMETERS:     EDX		Entry point
;						ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunImage	Proc near
	push eax
	push ebx
	push edx
;
	mov dword ptr [bp].load_cs,flat_code_sel
	mov [bp].load_eip,edx
	mov dword ptr [bp].load_esi,0
	mov dword ptr [bp].load_edi,0
	mov word ptr [bp+2].load_eflags,0
	mov ax,7202h
	SetFlags
	mov [bp].load_eflags,ax
	mov dword ptr [bp].load_ds,flat_data_sel
	mov dword ptr [bp].load_es,flat_data_sel
;
	pop edx
	pop ebx
	pop eax
	ret
RunImage	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load_elf
;
;		DESCRIPTION:    Load ELF executable file
;
;		PARAMETERS:     BX		file handle
;						DS:ESI	File name
;						ES:EDI	Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_elf	Proc far
	push ds
	push es
	push fs
	push esi
	push edi
;
	mov ax,ds
	mov fs,ax
	mov ax,flat_data_sel
	mov ds,ax
;
	xor eax,eax
	SetFilePos
	mov eax,SIZE elf_header
	AllocateSmallGlobalMem
	mov cx,ax
	xor di,di
	ReadFile
	jc load_elf_fail
;
	cmp ax,SIZE elf_header
	jne load_elf_fail
;
	mov eax,dword ptr es:elf_magic
	cmp al,7Fh
	jne load_elf_fail
;
	shr eax,8
	cmp ax,'LE'
	jne load_elf_fail
;
	shr eax,16
	cmp al,'F'
	jne load_elf_fail
;
	mov al,es:elf_file_class
	cmp al,EFC32
	jne load_elf_fail
;
	mov al,es:elf_endian
	cmp al,EELSB
	jne load_elf_fail
;
	mov ax,es:elf_type
	cmp ax,ET_EXEC
	jne load_elf_fail
;
	mov ax,es:elf_machine
	cmp ax,EM_386
	jne load_elf_fail
;
	push es:elf_entry
	mov edx,es:elf_phoff
	mov ax,es:elf_phentsize
	mov cx,es:elf_phnum
	FreeMem
	call CreateLib
	mov ax,es
	SetModule	
;
	call CreateImage
	pop edx
	jc load_elf_fail
	mov eax,es:lib_reloc
	or eax,eax
	jnz load_elf_fail
;
	mov al,32
	SetBitness
	call InsertApp
	call InitStack
	call InitDynamic
	add edx,es:lib_reloc
	call RunImage
;
	pop edi
	pop esi
	pop fs
	pop es
	pop ds
;
	push ds
	push es
	push fs
	push esi
	push edi
;
    GetThread
    mov fs,ax
    mov fs,fs:p_app_sel
;
	xor ecx,ecx
	push edi

load_elf_cmd_size:
	mov al,es:[edi]
	inc edi
	inc ecx
	or al,al
	jnz load_elf_cmd_size
;
	pop edi
	xor ebx,ebx
	push esi

load_elf_name_size:
	mov al,[esi]
	inc esi
	inc ebx
	or al,al
	jnz load_elf_name_size
;
	pop esi
;
	mov eax,ecx
	add eax,ebx
	UserGateForce32 allocate_app_mem_nr	
	mov fs:app_cmd_line,edx
	mov fs:app_options,0
;
	push es
	push ecx
	push edi
	mov ax,flat_data_sel
	mov es,ax
	mov edi,edx
	mov ecx,ebx
	rep movs byte ptr es:[edi],ds:[esi]
	mov edx,edi
	pop edi
	pop ecx
	pop es	
;
	mov esi,edi
	mov edi,edx
	mov ax,es
	mov ds,ax
	mov ax,flat_data_sel
	mov es,ax
	mov byte ptr es:[edi-1],' '
	rep movs byte ptr es:[edi],ds:[esi]
	clc
	jmp load_elf_done

load_elf_fail:
	FreeMem
	stc

load_elf_done:
	pop edi
	pop esi
	pop fs
	pop es
	pop ds
	retf32
load_elf	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenApp
;
;		DESCRIPTION:    open app callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_app	Proc far
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds:app_mem_blocks,0
	pop ds
	retf32
open_app	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			close_app
;
;		DESCRIPTION:    Close app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_app	Proc far
	retf32
close_app	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateMem
;
;		DESCRIPTION:	Allocate memory
;
;		PARAMETERS:		EAX	Number of bytes
;
;		RETURNS:		EDX Offset within flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_mem	PROC far
	push ds
	push es
	push eax
	push ecx
;
	dec eax
	and ax,0F000h
	add eax,1000h
	mov ecx,eax
	push ecx
	AllocateLocalLinear
	mov ax,system_data_sel
	mov ds,ax
	sub edx,ds:flat_base
;
	mov eax,SIZE elf_mem_struc
	AllocateLocalMem
	pop ecx
	mov es:mem_base,edx
	mov es:mem_size,ecx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    EnterSection ds:app_lib_section	
;
	mov ax,ds:app_mem_blocks
	or ax,ax
	je alloc_ins_empty
;
	push ds
	push si
	mov ds,ax
	mov si,ds:mem_prev
	mov ds:mem_prev,es
	mov ds,si
	mov ds:mem_next,es
	mov es:mem_next,ax
	mov es:mem_prev,si
	pop si
	pop ds
	jmp alloc_ins_done

alloc_ins_empty:
	mov es:mem_next,es
	mov es:mem_prev,es

alloc_ins_done:
	mov ds:app_mem_blocks,es
	LeaveSection ds:app_lib_section
;
	pop ecx
	pop eax
	pop es
	pop ds
	ret
allocate_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeMem
;
;		DESCRIPTION:	Free memory
;
;		PARAMETERS:		EDX Offset within flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_mem	PROC far
	push ds
	push es
	push eax
	push ecx
	push edx
	push si
	push edi
	push ebp
;
    mov ax,system_data_sel
    mov ds,ax
    mov ebp,ds:flat_base
;    
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    EnterSection ds:app_lib_section	

free_mem_more:
	mov ax,ds:app_mem_blocks
	or ax,ax
	jz free_mem_failed
	mov si,ax
free_mem_loop:
	mov es,ax

    cmp edx,es:mem_base
    je free_mem_ok

free_mem_next:
	mov ax,es:mem_next
	cmp ax,si
	jne free_mem_loop

free_mem_failed:
	jmp free_mem_done

free_mem_ok:
	mov edx,es:mem_base
	add edx,ebp
	mov ecx,es:mem_size
	FreeLinear
	mov ds:app_mem_blocks,es
	mov ax,es:mem_prev
	cmp ax,ds:app_mem_blocks
	pushf
	push ds
	mov ds:app_mem_blocks,ax
	mov si,es:mem_next
	mov ds,ax
	mov ds:mem_next,si
	mov ds,si
	mov ds:mem_prev,ax
	pop ds
	FreeMem
	popf
	jne free_mem_more

free_mem_last_block:
	mov ds:app_mem_blocks,0

free_mem_done:
	LeaveSection ds:app_lib_section
;
    pop ebp
	pop edi
	pop si
	pop edx
	pop ecx
	pop eax
	pop es
	pop ds
	ret
free_mem	ENDP
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetExeName
;
;		DESCRIPTION:    Get exe-file name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exe_name	Proc far
	push ds
	push eax
	push ebx
	push ecx
	push edx
	push esi
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
;
	mov edi,ds:app_name
	or edi,edi
	jnz get_exe_done
;	
	mov si,OFFSET app_exe_name

get_exe_size_loop:
	lodsb
	or al,al
	jnz get_exe_size_loop
;
	mov ax,si
	sub ax,OFFSET app_exe_name
	movzx eax,ax
	mov ecx,eax
	UserGateForce32 allocate_app_mem_nr
	mov edi,edx
	mov esi,OFFSET app_exe_name
	rep movs byte ptr es:[edi],ds:[esi]
;
	mov ds:app_name,edx
	mov edi,edx

get_exe_done:
    clc
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ds
	ret
get_exe_name	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetEnv
;
;		DESCRIPTION:    Get environment block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_env	Proc far
	push ds
	push eax
	push ebx
	push ecx
	push edx
	push esi
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
	mov edi,ds:app_env
	or edi,edi
	jnz get_env_done
;	
    LockProcEnv
	mov ds,bx
	xor si,si

get_env_size_loop:
	lodsb
	or al,al
	jnz get_env_size_loop
;
	lodsb
	or al,al
	jnz get_env_size_loop
;
	movzx ecx,si
	mov eax,ecx
	UserGateForce32 allocate_app_mem_nr
	mov edi,edx
	xor esi,esi
	rep movs byte ptr es:[edi],ds:[esi]
;
	mov ds:app_env,edx
	mov edi,edx
;
    UnlockProcEnv

get_env_done:
    clc
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ds
	ret
get_env	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetCmdLine
;
;		DESCRIPTION:    Get command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cmd_line	Proc far
	push ds
	push ax
;	
	GetThread
	mov ds,ax
	mov ds,ds:p_app_sel
	mov edi,ds:app_cmd_line
;
    pop ax	
	pop ds
	ret
get_cmd_line	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		DESCRIPTION:    Init elf loader module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

loader_tab:
l00 DD OFFSET get_exe_name,    SEG code
l01 DD OFFSET get_cmd_line,    SEG code
l02 DD OFFSET get_env,         SEG code
l03 DD OFFSET allocate_mem,    SEG code
l04 DD OFFSET free_mem,        SEG code
l05 DD OFFSET allocate_mem,    SEG code
l06 DD OFFSET free_mem,        SEG code

init	PROC far
    push ds
    push es
    pusha
;
    mov eax,SIZE loader_interface_struc
    mov bx,elf_loader_sel
    AllocateFixedSystemMem
    xor di,di
    mov si,OFFSET loader_tab
    mov cx,SIZE loader_interface_struc
    rep movs byte ptr es:[di],cs:[si]
;
    mov bx,elf_code_sel
    InitDevice
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    popa
    pop es
    pop ds
    ret
init	ENDP

code    ENDS

        END init
