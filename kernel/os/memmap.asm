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
; MEMMAP.ASM
; Memory-mapped file module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME memmap

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.def
INCLUDE protseg.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.inc
INCLUDE ..\fs.inc
INCLUDE ..\handle.inc

memmap_seg		STRUC

memmap_base		handle_header <>

memmap_prev		DW ?
memmap_next		DW ?
memmap_sel		DW ?
view_offset		DD ?
view_base		DD ?
view_size		DD ?

memmap_seg		ENDS

mapped_struc	STRUC

map_prev		DW ?
map_next		DW ?
map_section		section_typ <>
map_owner		DW ?
map_size		DD ?
map_base		DD ?
map_users		DW ?
map_file		DW ?
map_name		DB ?

mapped_struc	ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn map_to_file:near
	extrn sync_memmap:near
	extrn free_memmap:near

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateUnnamed
;
;		DESCRIPTION:	EAX			Size of filemapping object
;
;		RETURNS:		ES			File mapping selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateUnnamed	Proc near
	push ax
	push edx
	push esi
;
	push eax
	mov ax,fs_data_sel
	mov ds,ax
	mov eax,OFFSET map_name
	AllocateSmallGlobalMem
	pop eax
	dec eax
	and ax,0F000h
	add eax,1000h
	mov es:map_size,eax
	AllocateBigLinear
	mov es:map_base,edx
	mov es:map_users,1
	mov es:map_file,0
;
    push ds
    mov ax,es
    mov ds,ax
    mov esi,OFFSET map_section
    InitSection
    EnterSection
    pop ds    
	mov es:map_owner, OFFSET map_list
;
    mov esi,OFFSET sys_section
    EnterSection
	mov ax,ds:map_list
	or ax,ax
	je create_unnamed_empty
;
	push ds
	mov ds,ax
	mov si,ds:map_prev
	mov ds:map_prev,es
	mov ds,si
	mov ds:map_next,es
	mov es:map_next,ax
	mov es:map_prev,si
	pop ds
	jmp create_unnamed_leave

create_unnamed_empty:
	mov es:map_next,es
	mov es:map_prev,es
	mov ds:map_list,es

create_unnamed_leave:
    mov esi,OFFSET sys_section
    LeaveSection    
;
    pop esi
	pop edx
	pop ax
	ret
CreateUnnamed	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateNamed
;
;		DESCRIPTION:	EAX			Size of filemapping object
;						ES:EDI		Name
;
;		RETURNS:		ES			File mapping selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateNamed	Proc near
	push eax
	push ecx
	push edx
	push esi
	push edi
;
	push eax
	push es
	push edi
	xor al,al
	mov ecx,100h
	repnz scas byte ptr es:[edi]
	pop esi
	pop ds
	mov eax,100h
	sub eax,ecx
	xchg eax,ecx
	mov eax,OFFSET map_name
	add eax,ecx
	AllocateSmallGlobalMem
	mov edi,OFFSET map_name
	rep movs byte ptr es:[edi],[esi]
	pop eax
	dec eax
	and ax,0F000h
	add eax,1000h
	mov es:map_size,eax
	AllocateBigLinear
	mov es:map_base,edx
	mov es:map_users,1
	mov es:map_file,0
	mov ax,es
	mov ds,ax
	mov esi,OFFSET map_section
	InitSection
	EnterSection
	mov es:map_owner, OFFSET map_named_list
;
	mov ax,fs_data_sel
	mov ds,ax
	mov esi,OFFSET sys_section
	EnterSection
;	
	mov ax,ds:map_named_list
	or ax,ax
	je create_named_empty
;
	push ds
	push si
	mov ds,ax
	mov si,ds:map_prev
	mov ds:map_prev,es
	mov ds,si
	mov ds:map_next,es
	mov es:map_next,ax
	mov es:map_prev,si
	pop si
	pop ds
	jmp create_named_leave

create_named_empty:
	mov es:map_next,es
	mov es:map_prev,es
	mov ds:map_named_list,es

create_named_leave:
    mov esi,OFFSET sys_section
    LeaveSection
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop eax
	ret
CreateNamed	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateUnnamedFile
;
;		DESCRIPTION:	EAX			Size of filemapping object
;						BX			File handle
;
;		RETURNS:		ES			File mapping selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateUnnamedFile	Proc near
	push ax
	push edx
	push esi
;
	push eax
	mov ax,fs_data_sel
	mov ds,ax
	mov eax,OFFSET map_name
	AllocateSmallGlobalMem
	pop eax
	dec eax
	and ax,0F000h
	add eax,1000h
	mov es:map_size,eax
	mov es:map_base,0
	mov es:map_users,1
	mov es:map_file,bx
;
    push ds
    mov ax,es
    mov ds,ax
    mov esi,OFFSET map_section
    InitSection
    EnterSection	
    pop ds
	mov es:map_owner, OFFSET map_list
;
    mov esi,OFFSET sys_section
    EnterSection
;    
	mov ax,ds:map_list
	or ax,ax
	je create_unnamed_file_empty
;
	push ds
	push si
	mov ds,ax
	mov si,ds:map_prev
	mov ds:map_prev,es
	mov ds,si
	mov ds:map_next,es
	mov es:map_next,ax
	mov es:map_prev,si
	pop si
	pop ds
	jmp create_unnamed_file_leave

create_unnamed_file_empty:
	mov es:map_next,es
	mov es:map_prev,es
	mov ds:map_list,es

create_unnamed_file_leave:
    mov esi,OFFSET sys_section
    LeaveSection
;
    pop esi
	pop edx
	pop ax
	ret
CreateUnnamedFile	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateNamedFile
;
;		DESCRIPTION:	EAX			Size of filemapping object
;						BX			File handle
;						ES:EDI		Name
;
;		RETURNS:		ES			File mapping selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateNamedFile	Proc near
	push eax
	push ecx
	push edx
	push esi
	push edi
;
	push eax
	push es
	push edi
	xor al,al
	mov ecx,100h
	repnz scas byte ptr es:[edi]
	pop esi
	pop ds
	mov eax,100h
	sub eax,ecx
	xchg eax,ecx
	mov eax,OFFSET map_name
	add eax,ecx
	AllocateSmallGlobalMem
	mov edi,OFFSET map_name
	rep movs byte ptr es:[edi],[esi]
	pop eax
	dec eax
	and ax,0F000h
	add eax,1000h
	mov es:map_size,eax
	mov es:map_base,0
	mov es:map_users,1
	mov es:map_file,bx
	mov ax,es
	mov ds,ax
	mov esi,OFFSET map_section
	InitSection
	EnterSection
	mov es:map_owner, OFFSET map_named_list
;
	mov ax,fs_data_sel
	mov ds,ax
	mov esi,OFFSET sys_section
	EnterSection
;	
	mov ax,ds:map_named_list
	or ax,ax
	je create_named_file_empty
;
	push ds
	push si
	mov ds,ax
	mov si,ds:map_prev
	mov ds:map_prev,es
	mov ds,si
	mov ds:map_next,es
	mov es:map_next,ax
	mov es:map_prev,si
	pop si
	pop ds
	jmp create_named_file_leave

create_named_file_empty:
	mov es:map_next,es
	mov es:map_prev,es
	mov ds:map_named_list,es

create_named_file_leave:
    mov esi,OFFSET sys_section
    LeaveSection
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop eax
	ret
CreateNamedFile	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SyncOnePage
;
;		DESCRIPTION:    BX			Map file
;                       ES:EDX      Page table entry
;                       EDI			File offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SyncOnePage Proc near
	push eax
	push bx
	push edx
;
	or bx,bx
	jz sopDone
;
	test word ptr es:[edx],40h
	jz sopDone
;
	shl edx,10
	mov eax,edi
	call sync_memmap

sopDone:
	pop edx
	pop bx
	pop eax
    ret
SyncOnePage Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeOnePage
;
;		DESCRIPTION:    BX			Map file
;                       ES:EDX      Page table entry
;                       EDI			File offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeOnePage Proc near
	push eax
	push bx
	push edx
;
	or bx,bx
	jz fopDone
;
	shl edx,10
	mov eax,edi
	call free_memmap

fopDone:
	pop edx
	pop bx
	pop eax
    ret
FreeOnePage Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeView
;
;		DESCRIPTION:    DS:BX       Mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeView    Proc near
    push es
	pushad
;
    mov si,bx
	mov es,ds:[si].memmap_sel
    mov bx,es:map_file
	mov edi,ds:[si].view_offset
	and di,0F000h
	mov dx,ds:[si].memmap_sel
	or dx,dx
	stc
	jz fw_done
;
	mov edx,ds:[si].view_size
	or edx,edx
	stc 
	jz fw_done
;	
    xor ecx,ecx
	xchg ecx,ds:[si].view_size
	mov edx,ds:[si].view_base
;
	mov ax,process_page_sel
	mov es,ax
;
	add ecx,edx
	and dx,0F000h
	dec ecx
	and cx,0F000h
	add ecx,1000h
	sub ecx,edx
	shr edx,10
	shr ecx,12
	mov eax,2

fw_loop:
	test byte ptr es:[edx],1
	jz fw_next
;
	test word ptr es:[edx],800h
	jnz fw_mark
;
	push eax
	mov eax,es:[edx]
	FreePhysical
	pop eax

fw_mark:
    call SyncOnePage
	mov es:[edx],eax
	call FreeOnePage

fw_next:
	add edi,1000h
	add edx,4
	loop fw_loop

fw_done:
    clc
	popad
    pop es
    ret
FreeView    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UpdateView
;
;		DESCRIPTION:    DS:BX       Mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateView    Proc near
    push es
    push eax
    push bx
    push ecx
    push edx
    push si
    push edi
;
    mov si,bx
	mov es,ds:[si].memmap_sel
    mov bx,es:map_file
    or bx,bx
    jz uw_done
;       
	mov edi,ds:[si].view_offset
	and di,0F000h
	mov dx,ds:[si].memmap_sel
	or dx,dx
	stc
	jz uw_done
;
	mov edx,ds:[si].view_size
	or edx,edx
	stc 
	jz uw_done
;	
	mov ecx,ds:[si].view_size
	mov edx,ds:[si].view_base
;
	mov ax,process_page_sel
	mov es,ax
;
	add ecx,edx
	and dx,0F000h
	dec ecx
	and cx,0F000h
	add ecx,1000h
	sub ecx,edx
	shr edx,10
	shr ecx,12
	mov eax,2

uw_loop:
	test byte ptr es:[edx],1
	jz uw_next
;
	test word ptr es:[edx],800h
	jz uw_next
;
    call SyncOnePage	

uw_next:
	add edi,1000h
	add edx,4
	loop uw_loop

uw_done:
    clc
    pop edi
    pop si
    pop edx
    pop ecx
    pop bx
    pop eax    
    pop es
    ret
UpdateView    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CloseMapped
;
;		DESCRIPTION:	ES			File mapping selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseMapped	Proc near
	sub es:map_users,1
	jnz close_mapped_done
;
	push ax
	push esi
	mov ax,fs_data_sel
	mov ds,ax
	mov esi,OFFSET sys_section
	EnterSection
;	
	mov si,es:map_owner
	mov [si],es
	push ds
	push si
	mov ax,es:p_next
	cmp ax,[si]
	mov [si],ax
	mov si,es:p_prev
	mov ds,ax
	mov ds:p_prev,si
	mov ds,si
	mov ds:p_next,ax
	pop si
	pop ds
	jne close_mapped_leave
;
	mov word ptr [si],0

close_mapped_leave:
    mov esi,OFFSET sys_section
    LeaveSection
;
	mov ecx,es:map_size
	mov edx,es:map_base
	or edx,edx
	jz close_mapped_free_sel
;
	FreeLinear

close_mapped_free_sel:
	FreeMem
	pop esi
	pop ax

close_mapped_done:
	ret
CloseMapped	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FindNamed
;
;		DESCRIPTION:	ES:EDI		Name
;
;		RETURNS:		ES			File mapping selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindNamed	Proc near
	push ax
	push ebx
	push dx
	push esi
;
	mov ax,fs_data_sel
	mov ds,ax
	mov esi,OFFSET sys_section
	EnterSection
;	
	mov ax,ds:map_named_list
	or ax,ax
	je find_named_fail
;
	mov dx,ax

find_named_list:
	mov ds,ax
	mov si,OFFSET map_name
	mov ebx,edi

find_named_loop:
	lodsb
	mov ah,es:[ebx]
	inc ebx
	or al,al
	jnz find_named_match
;
	or ah,ah
	jz find_named_ok
	jmp find_named_next

find_named_match:
	cmp al,ah
	je find_named_loop

find_named_next:
	mov ax,ds:map_next
	cmp ax,dx
	jne find_named_list

find_named_fail:
	mov ax,fs_data_sel
	mov ds,ax
	mov esi,OFFSET sys_section
	LeaveSection
	stc
	jmp find_named_done

find_named_ok:
	mov dx,ds
	mov es,dx
	inc es:map_users
	mov ax,fs_data_sel
	mov ds,ax
	mov esi,OFFSET sys_section
	LeaveSection
	clc

find_named_done:
	pop esi
	pop dx
	pop ebx
	pop ax
	ret
FindNamed	Endp
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateHandle
;
;		DESCRIPTION:	ES			File mapping selector
;
;		RETURNS:		BX			File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateHandle	Proc near
	push es
	push ax
	push cx
	push si
	push di
;
	mov cx,SIZE memmap_seg
	AllocateHandle
	mov [bx].memmap_sel,es
	mov [bx].view_offset,0
	mov [bx].view_base,0
	mov [bx].view_size,0
;
	cli
	mov ax,fs_process_sel
	mov es,ax
	mov di,es:memmap_list
	or di,di
	je create_ins_empty
;
	mov si,[di].memmap_prev
	mov [di].memmap_prev,bx
	mov [si].memmap_next,bx
	mov [bx].memmap_next,di
	mov [bx].memmap_prev,si
	jmp create_ins_done

create_ins_empty:
	mov [bx].memmap_next,bx
	mov [bx].memmap_prev,bx
	mov es:memmap_list,bx

create_ins_done:
	sti
	mov [bx].hh_sign,MEMMAP_HANDLE
	mov bx,[bx].hh_handle
;
	pop di
	pop si
	pop cx
	pop ax
	pop es
	ret
CreateHandle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateMapping
;
;		DESCRIPTION:	EAX			Size of filemapping object
;
;		RETURNS:		BX			File mapping handle
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_mapping_name DB 'Create Mapping',0

create_mapping	Proc far
	push ds
	push es
	push esi
;	
	call CreateUnnamed
	call CreateHandle
	push es
	pop ds
	mov esi,OFFSET map_section
	LeaveSection
	clc
;	
	pop esi
	pop es
	pop ds
	retf32
create_mapping	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateNamedMapping
;
;		DESCRIPTION:	EAX			Size of filemapping object
;						ES;(E)DI	Name of file mapping
;
;		RETURNS:		BX			File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_named_mapping_name DB 'Create Named Mapping',0

create_named_mapping	Proc near
	push ds
	push es
	call FindNamed
	jnc create_named_ok
;
	call CreateNamed
	push ds
	push esi
	push es
	pop ds
	mov esi,OFFSET map_section
	LeaveSection
	pop esi
	pop ds

create_named_ok:
	call CreateHandle
	clc
	pop es
	pop ds
	ret
create_named_mapping	Endp

create_named_mapping32	Proc far
	call create_named_mapping
	retf32
create_named_mapping32	Endp

create_named_mapping16	Proc far
	push edi
	movzx edi,di
	call create_named_mapping
	pop edi
	ret
create_named_mapping16	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateFileMapping
;
;		DESCRIPTION:	EAX			Size of filemapping object
;						BX			File handle to map
;
;		RETURNS:		BX			File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_file_mapping_name DB 'Create File Mapping',0

create_file_mapping	Proc near
	push ds
	push es
;
	push ax
	push bx
	mov ax,FILE_HANDLE
	DerefHandle
	pop bx
	pop ax
	jc create_file_mapping_done
;
	call CreateUnnamedFile
	call CreateHandle
	push es
	pop ds
	push esi
	mov esi,OFFSET map_section
	LeaveSection
	pop esi
	clc

create_file_mapping_done:
	pop es
	pop ds
	retf32
create_file_mapping	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateNamedFileMapping
;
;		DESCRIPTION:	EAX			Size of filemapping object
;						BX			File handle to map
;						ES:(E)DI	Name of file mapping
;
;		RETURNS:		BX			File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_named_file_mapping_name DB 'Create Named File Mapping',0

create_named_file_mapping	Proc near
	push ds
	push es
;
	push ax
	push bx
	mov ax,FILE_HANDLE
	DerefHandle
	pop bx
	pop ax
	jc create_named_file_done
;
	call FindNamed
	jnc create_named_file_ok
;
	call CreateNamedFile
	push ds
	push esi
	push es
	pop ds
	mov esi,OFFSET map_section
	LeaveSection
	pop esi
	pop ds

create_named_file_ok:
	call CreateHandle
	clc

create_named_file_done:
	pop es
	pop ds
	ret
create_named_file_mapping	Endp

create_named_file_mapping32	Proc far
	call create_named_file_mapping
	retf32
create_named_file_mapping32	Endp

create_named_file_mapping16	Proc far
	push edi
	movzx edi,di
	call create_named_file_mapping
	pop edi
	ret
create_named_file_mapping16	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			OpenNamedMapping
;
;		DESCRIPTION:	ES;(E)DI	Name of file mapping
;
;		RETURNS:		BX			File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_named_mapping_name DB 'Open Named Mapping',0

open_named_mapping	Proc near
	push ds
	push es
	call FindNamed
	jc open_named_done
	call CreateHandle
	clc
open_named_done:
	pop es
	pop ds
	ret
open_named_mapping	Endp

open_named_mapping32	Proc far
	call open_named_mapping
	retf32
open_named_mapping32	Endp

open_named_mapping16	Proc far
	push edi
	movzx edi,di
	call open_named_mapping
	pop edi
	ret
open_named_mapping16	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SyncMapping
;
;		DESCRIPTION:	BX			File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sync_mapping_name DB 'Sync Mapping',0

sync_mapping	Proc far
	push ds
	push ax
	push bx
;
	mov ax,MEMMAP_HANDLE
	DerefHandle
	jc sm_done
;
    call UpdateView

sm_done:
    pop bx
    pop ax
    pop ds
	retf32
sync_mapping	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CloseMapping
;
;		DESCRIPTION:	BX			File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_mapping_name DB 'Close Mapping',0

close_mapping	Proc far
	push ds
	push es
	push ax
	push si
	push di
;
	mov ax,MEMMAP_HANDLE
	DerefHandle
	jc cfm_done
;
    call FreeView
;
	mov ax,fs_process_sel
	mov es,ax
	cli
	mov es:memmap_list,bx
	mov di,[bx].memmap_next
	cmp di,bx
	mov es:memmap_list,di
	mov si,[bx].memmap_prev
	mov [di].memmap_prev,si
	mov [si].memmap_next,di
	jne close_rem_done
;
	mov es:memmap_list,0

close_rem_done:
	sti
	mov ax,ds:[bx].memmap_sel
	or ax,ax
	jz cfm_done
;
	mov es,ax
	call CloseMapped
	clc

cfm_done:
	FreeHandle
	pop di
	pop si
	pop ax
	pop es
	pop ds
	retf32
close_mapping	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			map_to_user
;
;		DESCRIPTION:	Map page from object to user memory
;
;		PARAMETERS:		EAX			Offset within object
;						EBX			Source linear address
;						EDX			Pagefault base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_to_user	Proc near
	push es
	push eax
	push ebx
	push edx
;
	mov ax,process_page_sel
	mov es,ax
	shr ebx,10
	shr edx,10
;
	mov eax,es:[ebx]
	test al,1
	jnz map_to_user_do
;
	push es
	push ecx
	push edi
	mov ax,flat_sel
	mov es,ax
	mov edi,ebx
	shl edi,10
	xor eax,eax
	mov ecx,400h
	rep stos dword ptr es:[edi]	
	pop edi
	pop ecx
	pop es
	mov eax,es:[ebx]

map_to_user_do:
	or ax,807h
	mov es:[edx],eax
;
	pop edx
	pop ebx
	pop eax
	pop es
	ret
map_to_user	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			MapFault
;
;		DESCRIPTION:	Page-fault handler for memory mapped object
;
;		PARAMETERS:		EDX		Page fault address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_fault	Proc far
	push ds
	push eax
	push bx
	push cx
	push edx
	push esi
;
	mov ax,fs_process_sel
	mov es,ax
	mov ax,handle_mem_sel
	mov ds,ax
	mov bx,es:memmap_list
	or bx,bx
	jz map_fault_fail
;
	mov si,bx

map_fault_loop:
	mov ax,ds:[bx].memmap_sel
	or ax,ax
	jz map_fault_find_next
;
	mov eax,ds:[bx].view_size
	or eax,eax
	jz map_fault_find_next
;
	mov eax,edx	
	sub eax,ds:[bx].view_base
	jc map_fault_find_next
;
	cmp eax,ds:[bx].view_size
	jnc map_fault_find_next
;
	add eax,ds:[bx].view_offset
	and ax,0F000h
	and dx,0F000h
	mov ds,ds:[bx].memmap_sel
	mov esi,OFFSET map_section
	EnterSection
;
	mov bx,ds:map_file
	or bx,bx
	jz map_fault_mem
;
	call map_to_file
	jmp map_fault_leave

map_fault_mem:
	mov ebx,ds:map_base
	add ebx,eax
	call map_to_user

map_fault_leave:
    mov esi,OFFSET map_section
    LeaveSection
	jmp map_fault_done

map_fault_find_next:
	mov bx,[bx].memmap_next
	cmp bx,si
	jnz map_fault_loop

map_fault_fail:
	int 3

map_fault_done:
	pop esi
	pop edx
	pop cx
	pop bx
	pop eax
	pop ds
	ret
map_fault	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			MapView
;
;		DESCRIPTION:	BX			File mapping handle
;						EAX			Offset
;						(E)CX		Size
;						ES:(E)DI	Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_view_name DB 'Map View',0

map_view	Proc near
	push ds
	push es
	push eax
	push bx
	push ecx
	push edx
	push di
;
	push ax
	mov ax,MEMMAP_HANDLE
	DerefHandle
	pop ax
	jc mfm_done
;
	mov dx,ds:[bx].memmap_sel
	or dx,dx
	stc
	jz mfm_done
;
	mov edx,ds:[bx].view_size
	or edx,edx
	stc 
	jnz mfm_done
;
	mov ds:[bx].view_offset,eax
	dec ecx
	and cx,0F000h
	add ecx,1000h
	mov eax,ecx
	push bx
	mov bx,es
	GetSelectorBaseSize
	pop bx
	jc mfm_done
;
	cmp ecx,eax
	jc mfm_done
;
	add edx,edi
	test dx,0FFFh
	stc
	jnz mfm_done
;
	mov ecx,eax
	mov es,ds:[bx].memmap_sel
	cmp es:map_size,eax
	jc mfm_done
;
	mov ds:[bx].view_base,edx
	mov ds:[bx].view_size,ecx
	mov ax,cs
	mov es,ax
	mov di,OFFSET map_fault
	mov eax,ecx
	HookPage
	clc

mfm_done:
	pop di
	pop edx
	pop ecx
	pop bx
	pop eax
	pop es
	pop ds
	ret
map_view	Endp

map_view32	Proc far
	call map_view
	retf32
map_view32	Endp

map_view16	Proc far
	push ecx
	push edi
	movzx ecx,cx
	movzx edi,di
	call map_view
	pop edi
	pop ecx
	ret
map_view16	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UnmapView
;
;		DESCRIPTION:	BX			File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unmap_view_name DB 'Unmap View',0

unmap_view	Proc far
	push ds
	push ax
	push bx
;
	mov ax,MEMMAP_HANDLE
	DerefHandle
	jc ufm_done
;
    call FreeView
	clc

ufm_done:
	pop bx
	pop ax
	pop ds
	retf32
unmap_view	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_handle
;
;		DESCRIPTION:	BX			File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	push ds
	push es
	push ax
;
	mov ax,MEMMAP_HANDLE
	DerefHandle
	jc delete_handle_done
;
    call FreeView
;
	mov ax,fs_process_sel
	mov es,ax
	cli
	mov es:memmap_list,bx
	mov di,[bx].memmap_next
	cmp di,bx
	mov es:memmap_list,di
	mov si,[bx].memmap_prev
	mov [di].memmap_prev,si
	mov [si].memmap_next,di
	jne delete_handle_rem_done
;
	mov es:memmap_list,0

delete_handle_rem_done:
	sti
	mov ax,ds:[bx].memmap_sel
	or ax,ax
	jz delete_handle_done
;
	mov es,ax
	call CloseMapped
	clc

delete_handle_done:
	FreeHandle
	pop ax
	pop es
	pop ds
	ret
delete_handle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Open app
;
;		DESCRIPTION:	Init per-process data
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_memmap_process

init_memmap_process	PROC near
	mov ax,fs_process_sel
	mov es,ax
	mov es:memmap_list,0
	ret
init_memmap_process	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Init
;
;		DESCRIPTION:	Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_memmap

init_memmap	PROC near
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov ax,MEMMAP_HANDLE
	mov di,OFFSET delete_handle
	RegisterHandle
;
	mov si,OFFSET create_mapping
	mov di,OFFSET create_mapping_name
	xor dx,dx
	mov ax,create_mapping_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET create_named_mapping16
	mov si,OFFSET create_named_mapping32
	mov di,OFFSET create_named_mapping_name
	mov dx,virt_es_in
	mov ax,create_named_mapping_nr
	RegisterUserGate
;
	mov si,OFFSET create_file_mapping
	mov di,OFFSET create_file_mapping_name
	xor dx,dx
	mov ax,create_file_mapping_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET create_named_file_mapping16
	mov si,OFFSET create_named_file_mapping32
	mov di,OFFSET create_named_file_mapping_name
	mov dx,virt_es_in
	mov ax,create_named_file_mapping_nr
	RegisterUserGate
;
	mov bx,OFFSET open_named_mapping16
	mov si,OFFSET open_named_mapping32
	mov di,OFFSET open_named_mapping_name
	mov dx,virt_es_in
	mov ax,open_named_mapping_nr
	RegisterUserGate
;
	mov si,OFFSET sync_mapping
	mov di,OFFSET sync_mapping_name
	xor dx,dx
	mov ax,sync_mapping_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_mapping
	mov di,OFFSET close_mapping_name
	xor dx,dx
	mov ax,close_mapping_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET map_view16
	mov si,OFFSET map_view32
	mov di,OFFSET map_view_name
	mov dx,virt_es_in
	mov ax,map_view_nr
	RegisterUserGate
;
	mov si,OFFSET unmap_view
	mov di,OFFSET unmap_view_name
	xor dx,dx
	mov ax,unmap_view_nr
	RegisterBimodalUserGate
;
	mov ax,fs_data_sel
	mov ds,ax
	mov ds:map_list,0
	mov ds:map_named_list,0
	mov esi,OFFSET sys_section
	InitSection
	ret
init_memmap	ENDP

code	ENDS

	END
