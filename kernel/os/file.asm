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
; FILE.ASM
; File module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME file

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

file_handle_seg		STRUC

file_handle_base	handle_header <>

file_handle_pos		DD ?
file_handle_sel		DW ?
file_handle_access	DB ?
file_handle_drive	DB ?

file_handle_seg		ENDS

CallFileSystem	MACRO	call_proc
	push ds
	push gs
	push bp
	push si
	mov si,fs_data_sel
	mov ds,si
	movzx si,al
	add si,si
	mov ds,ds:[si].fs_sel
	lgs bp,ds:fs_sys_arr
	lds si,ds:fs_sys_arr+4
	call gs:[bp].&call_proc
	pop si
	pop bp
	pop gs
	pop ds
				ENDM

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateFileHandle
;
;		DESCRIPTION:	Creates a file handle
;
;		PARAMETERS:		AL			Drive
;						BX			File selector
;						CL			Access
;
;		RETURNS:		BX			Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CreateFileHandle

CreateFileHandle	Proc near
	push ds
	push es
	push si
;
	mov es,bx
	inc es:file_usage
	push cx
	mov cx,SIZE file_handle_seg
	AllocateHandle
	pop cx
	mov [bx].file_handle_pos,0
	mov [bx].file_handle_sel,es
	mov [bx].file_handle_access,cl
	mov [bx].file_handle_drive,al
	mov [bx].hh_sign,FILE_HANDLE
	mov bx,[bx].hh_handle
	clc
;
	pop si
	pop es
	pop ds
	ret
CreateFileHandle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateListEntry
;
;		DESCRIPTION:	Create a new list entry
;
;		PARAMETERS:		DS			File selector
;						EAX			Position entry
;
;		RETURNS:		EAX			Base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateListEntry	Proc near
	push bx
	push ecx
	push edx
	push esi
	push edi
;
	mov esi,eax
	mov al,ds:file_drive
	mov bx,ds
	CallFileSystem allocate_file_list_proc
;
	mov es:[edi].fl_usage,0
	mov es:[edi].fl_ref_count,1
	mov es:[edi].fl_size,eax
	mov es:[edi].fl_base,0
	mov es:[edi].fl_sel,ds
	mov es:[edi].fl_state, FILE_LIST_STATE_EMPTY
	mov es:[edi].fl_flags,0
	mov es:[edi].fl_prev_small,0
	mov es:[edi].fl_next_small,0
	mov es:[edi].fl_pos,esi
	mov eax,edi
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop bx
	ret
CreateListEntry	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeListEntry
;
;		DESCRIPTION:	Free a list entry
;
;		PARAMETERS:		DS			File selector
;						EAX			Base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeListEntry	Proc near
	push ax
	push bx
	push ecx
	push edx
	push edi
;
	mov edi,eax
	mov eax,es:[edi].fl_pos
	mov dword ptr es:[eax],0
	push edi
	mov edx,es:[edi].fl_base
	or edx,edx
	jz free_list_done
;
	mov es:[edi].fl_state, FILE_LIST_STATE_EMPTY
	mov ecx,ds:file_block_size
	cmp ecx,1000h
	jc free_small_list
;
	FreeLinear
	mov es:[edi].fl_base,0
	jmp free_list_done

free_small_list:
	push esi

free_small_start_loop:
	mov esi,edi
	test dx,0FFFh
	jz free_small_start_found
;
	mov eax,es:[edi].fl_prev_small
	or eax,eax
	jz free_small_fail
;
	mov edi,eax
	mov edx,es:[edi].fl_base
	test es:[edi].fl_state, FILE_LIST_STATE_EMPTY
	je free_small_start_loop
	jmp free_small_fail

free_small_start_found:
	xchg esi,edi

free_small_end_loop:
	mov eax,es:[edi].fl_next_small
	or eax,eax
	jz free_small_do
;
	mov edi,eax
	mov eax,es:[edi].fl_base
	test ax,0FFFh
	jz free_small_do
;
	test es:[edi].fl_state, FILE_LIST_STATE_EMPTY
	jne free_small_fail
	jmp free_small_end_loop

free_small_do:
	mov edi,esi

free_small_unlink_loop:
	mov es:[edi].fl_base,0
	mov es:[edi].fl_prev_small,0
	xor eax,eax
	xchg eax,es:[edi].fl_next_small
	or eax,eax
	jz free_small_unlink_done
;
	mov edi,eax
	mov eax,es:[edi].fl_base
	test ax,0FFFh
	jnz free_small_unlink_loop

free_small_unlink_done:
	mov ecx,1000h
	FreeLinear

free_small_fail:
	pop esi

free_list_done:
	pop edi
	mov al,ds:file_drive
	mov bx,ds
	CallFileSystem free_file_list_proc
;
	pop edi
	pop edx
	pop ecx
	pop bx
	pop ax
	ret
FreeListEntry	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateListDir
;
;		DESCRIPTION:	Create a new list directory
;
;		PARAMETERS:		DS			File selector
;
;		RETURNS:		EBX			Base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateListDir	Proc near
	push ecx
	push edx
	push edi
;
	mov eax,1000h
	AllocateBigLinear
	mov edi,edx
	mov ecx,400h
	xor eax,eax
	rep stos dword ptr es:[edi]
	mov ebx,edx
;
	pop edi
	pop edx
	pop ecx
	ret
CreateListDir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeListDir
;
;		DESCRIPTION:	Free a list directory
;
;		PARAMETERS:		DS			File selector
;						EBX			Base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeListDir	Proc near
	push es
	push ax
	push ebx
	push ecx
	push edx
	push edi
;
	mov ax,flat_sel
	mov es,ax
;
	mov edx,ebx
	mov cx,400h

free_list_dir_loop:
	mov eax,es:[ebx]
	or eax,eax
	jz free_list_dir_next
;
	call FreeListEntry

free_list_dir_next:
	add ebx,4
	loop free_list_dir_loop
;
	mov ecx,1000h
	FreeLinear
;
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop ax
	pop es
	ret
FreeListDir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateFileSelector
;
;		DESCRIPTION:	Open a file handle
;
;		PARAMETERS:		AL			Drive
;						AH			Attribute
;						ECX			File size
;						EDX			File dir entry
;
;		RETURNS:		BX			File selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CreateFileSel

CreateFileSel	PROC near
	push ds
	push es
	push eax
	push di
;
	push ecx
	push edx
;
	mov bx,ax
	test ah,80h
	jnz crfs_skip_lists
;
	mov al,bl
	GetDriveParam
	jnc crfs_ok_params
;
	mov eax,1000h
	mov ecx,1000h

crfs_ok_params:
	mov edx,ecx
	dec eax
	xor cl,cl

crfs_block_loop:
	inc cl
	shr eax,1
	jnz crfs_block_loop
;
	mov eax,1
	shl eax,cl
	dec edx
	add cl,10
	shr edx,cl
	inc edx
;
	push eax
	mov eax,edx
	shl eax,2
	add eax,SIZE file_data_struc - 4
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
	pop eax
;
	mov ds:file_block_size,eax
	mov ds:file_dir_entries,dx
	mov ds:file_dir_shift,cl
	sub cl,10
	mov ds:file_entry_shift,cl
;
	mov cx,dx
	mov di,OFFSET file_entries
	xor eax,eax
	rep stosd
	jmp crfs_init

crfs_skip_lists:
	mov eax,SIZE file_data_struc - 4
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
	mov ds:file_block_size,0
	mov ds:file_dir_entries,0

crfs_init:
	pop edx
	pop ecx
	InitReadWriteSection ds:file_size_section
	InitSection ds:file_list_section
	mov ds:file_usage,0
	mov ds:file_drive,bl
	mov ds:file_attrib,bh
	mov ds:file_size,ecx
	mov ds:file_dir_entry,edx
	mov bx,ds
;
	pop di
	pop eax
	pop es
	pop ds
	ret
CreateFileSel	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeFileSel
;
;		DESCRIPTION:	Free file selector
;
;		PARAMETERS:		DS			File selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FreeFileSel

FreeFileSel	PROC near
	push es
	push ax
	push ebx
	push ecx
	push si
;
	mov ecx,ds:file_block_size
	or ecx,ecx
	jz free_file_sel
;
	mov ax,flat_sel
	mov es,ax
	mov cx,ds:file_dir_entries
	mov si,OFFSET file_entries

free_file_dir_loop:
	mov ebx,[si]
	or ebx,ebx
	jz free_file_dir_next
;
	call FreeListDir

free_file_dir_next:
	add si,4
	loop free_file_dir_loop

free_file_sel:
	mov ax,ds
	mov es,ax
	xor ax,ax
	mov ds,ax
	FreeMem
;
	pop si
	pop ecx
	pop ebx
	pop ax
	pop es
	ret
FreeFileSel	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeFile
;
;		DESCRIPTION:	Free file selector
;
;		PARAMETERS:		BX		File selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FreeFile

FreeFile	PROC near
	push ds
	push ax
;
	mov ds,bx
	mov ax,ds:file_usage
	or ax,ax
	stc
	jnz free_file_done
;
	call FreeFileSel

free_file_done:
	pop ax
	pop ds
	ret
FreeFile	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetFileListEntry
;
;		DESCRIPTION:	Get list entry
;
;		PARAMETERS:		BX			File selector
;						EDX			Position
;
;		RETURNS:		EAX			List selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_list_entry_name	DB 'Get File List Entry',0

get_file_list_entry	Proc far
	push ds
	push es
	push ebx
	push cx
	push esi
;
	mov ds,bx
	mov ax,flat_sel
	mov es,ax
;
	mov eax,ds:file_size
	dec eax
	and ax,0F000h
	add eax,1000h
	cmp edx,eax
	jnc get_list_fail
;
	mov esi,edx
	mov cl,ds:file_dir_shift
	shr esi,cl
	shl si,2
	mov ebx,ds:[si].file_entries
	or ebx,ebx
	jnz get_list_check_mid
;
	call CreateListDir
	mov ds:[si].file_entries,ebx

get_list_check_mid:
	mov esi,edx
	mov cl,ds:file_entry_shift
	shr esi,cl
	shl si,2
	and esi,0FFCh
	mov eax,es:[ebx+esi]
	or eax,eax
	clc
	jnz get_list_done
;
	lea eax,[ebx+esi]
	call CreateListEntry
	mov es:[ebx+esi],eax
	clc
	jmp get_list_done

get_list_fail:
	stc

get_list_done:
	pop esi
	pop cx
	pop ebx
	pop es
	pop ds
	ret
get_file_list_entry	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeFileListEntry
;
;		DESCRIPTION:	Free a file list entry
;
;		PARAMETERS:		BX			File selector
;						EDI			File list entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_file_list_entry_name	DB 'Free File List Entry',0

free_file_list_entry	Proc far
	push ds
	push eax
;
	mov ds,bx
	mov eax,edi
	call FreeListEntry
;
	pop eax
	pop ds
	ret
free_file_list_entry	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadFileListEntry
;
;		DESCRIPTION:	Read a file list entry
;
;		PARAMETERS:		DS			File selector
;						EDI			File list entry
;						EDX			File position						
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadFileListEntry	Proc near
	mov eax,es:[edi].fl_base
	or eax,eax
	jnz read_file_list_do
;
	mov eax,ds:file_block_size
	cmp eax,1000h
	jc read_alloc_small
;
	push ecx
	push edx
	AllocateBigLinear
	mov es:[edi].fl_base,edx
	pop edx
	pop ecx
	jmp read_file_list_do

read_alloc_small:
	push bx
	push edx
	push esi
	push edi
;
	push ecx
	push edx
	mov eax,1000h
	AllocateBigLinear
	mov esi,edx
	pop edx
	pop ecx
;
	mov bx,ds
	mov eax,ds:file_block_size
	neg eax
	and edx,eax

read_small_start_loop:
	test dx,0FFFh
	jz read_small_start_found
;
	sub edx,ds:file_block_size
	GetFileListEntry
	mov edi,eax
	jmp read_small_start_loop

read_small_start_found:
	mov es:[edi].fl_prev_small,0

read_small_loop:
	mov es:[edi].fl_next_small,0
	mov es:[edi].fl_base,esi
	add esi,ds:file_block_size
	add edx,ds:file_block_size
	test dx,0FFFh
	jz read_small_done
;
	GetFileListEntry
	jc read_small_done
;
	mov es:[edi].fl_next_small,eax
	mov es:[eax].fl_prev_small,edi
	mov edi,eax
	jmp read_small_loop

read_small_done:
	pop edi
	pop esi
	pop edx
	pop bx
	
read_file_list_do:
	mov es:[edi].fl_state, FILE_LIST_STATE_USED
	push edx
	mov eax,ds:file_block_size
	neg eax
	and edx,eax
	push bx
	mov al,ds:file_drive
	mov bx,ds
	CallFileSystem read_file_block_proc
	pop bx
	pop edx
	ret
ReadFileListEntry	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			read file
;
;		DESCRIPTION:	Reads from a file
;
;		PARAMETERS:		AL			Drive
;						DS			File selector
;						ECX			Size
;						EDX			Position
;						ES:EDI		Data buffer
;
;		RETURNS:		EAX			Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_file	Proc near
	push es
	push fs
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
;
	xor ebp,ebp
	mov ax,es
	mov fs,ax
	mov ax,flat_sel
	mov es,ax
;
	EnterReadSection ds:file_size_section
	cmp edx,ds:file_size
	jnc read_file_done
;
	mov eax,edx
	add eax,ecx
	sub eax,ds:file_size
	jc read_file_size_ok
;
	sub ecx,eax

read_file_size_ok:
	or ecx,ecx
	jz read_file_done

read_file_loop:
	push cx
	mov esi,edx
	mov cl,ds:file_dir_shift
	shr esi,cl
	shl si,2
	mov ebx,ds:[si].file_entries
	EnterSection ds:file_list_section
	or ebx,ebx
	jnz read_file_check_mid
;
	call CreateListDir
	mov ds:[si].file_entries,ebx

read_file_check_mid:
	mov esi,edx
	mov cl,ds:file_entry_shift
	shr esi,cl
	shl si,2
	and esi,0FFCh
	pop cx
	mov eax,es:[ebx+esi]
	or eax,eax
	jnz read_file_check_base
;
	lea eax,[ebx+esi]
	call CreateListEntry
	mov es:[ebx+esi],eax

read_file_check_base:
	cmp es:[eax].fl_state, FILE_LIST_STATE_EMPTY
	jne read_file_do_first
;
	push edi
	mov edi,eax
	call ReadFileListEntry
	pop edi
	jnc read_file_do_first
;
	mov dword ptr es:[ebx+esi],0
	LeaveSection ds:file_list_section
	jmp read_file_done

read_file_do_first:
	mov esi,es:[ebx+esi]
	inc es:[esi].fl_usage
	inc es:[esi].fl_ref_count
	LeaveSection ds:file_list_section
;
	push ds
	push es
	push edx
	push esi
;
	mov ebx,ds:file_block_size
	mov esi,es:[esi].fl_base
	mov ax,fs
	mov es,ax
	mov ax,flat_sel
	mov ds,ax
;
	mov eax,ebx
	dec eax
	and edx,eax
	add esi,edx
;
	sub ebx,edx
	cmp ecx,ebx
	jnc read_file_do
;
	mov ebx,ecx

read_file_do:
	push ecx
	mov ecx,ebx
	shr ecx,2
	rep movs dword ptr es:[edi],[esi]
	mov ecx,ebx
	and ecx,3
	rep movs byte ptr es:[edi],[esi]
	pop ecx
;
	pop esi
	pop edx
	pop es
	pop ds
	dec es:[esi].fl_usage
;
	add edx,ebx
	add ebp,ebx
	sub ecx,ebx
	jnz read_file_loop
;
	clc

read_file_done:
	pushf
	LeaveReadSection ds:file_size_section
	popf
	mov eax,ebp
;
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop fs
	pop es
	ret
read_file	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			write file
;
;		DESCRIPTION:	Write to a file
;
;		PARAMETERS:		AL			Drive
;						DS			File selector
;						ECX			Size
;						EDX			Position
;						ES:EDI		Data buffer
;
;		RETURNS:		EAX			Bytes written
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_file	Proc near
	push es
	push fs
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
;
	xor ebp,ebp
	mov ax,es
	mov fs,ax
	mov ax,flat_sel
	mov es,ax
;
	EnterWriteSection ds:file_size_section
	cmp edx,ds:file_size
	jnc write_file_extend
;
	mov eax,edx
	add eax,ecx
	sub eax,ds:file_size
	jc write_file_size_ok

write_file_extend:
	push edx
	add edx,ecx
	mov bx,ds
	mov al,ds:file_drive
	CallFileSystem set_file_size_proc
	pop edx

write_file_size_ok:
	or ecx,ecx
	jz write_file_done

write_file_loop:
	push cx
	mov esi,edx
	mov cl,ds:file_dir_shift
	shr esi,cl
	shl si,2
	mov ebx,ds:[si].file_entries
	or ebx,ebx
	jnz write_file_check_mid
;
	call CreateListDir
	mov ds:[si].file_entries,ebx

write_file_check_mid:
	mov esi,edx
	mov cl,ds:file_entry_shift
	shr esi,cl
	shl si,2
	and esi,0FFCh
	pop cx
	mov eax,es:[ebx+esi]
	or eax,eax
	jnz write_file_check_base
;
	lea eax,[ebx+esi]
	call CreateListEntry
	mov es:[ebx+esi],eax

write_file_check_base:
	cmp es:[eax].fl_base,0
	jnz write_file_do_first
;
	push edx
	push edi
	mov edi,eax
	mov eax,ds:file_block_size
	push ecx
	push edx
	AllocateBigLinear
	mov es:[edi].fl_base,edx
	pop edx
	pop ecx
	neg eax
	and edx,eax
	push bx
	mov al,ds:file_drive
	mov bx,ds
	CallFileSystem read_file_block_proc
	pop bx
	pop edi
	pop edx
	jnc write_file_do_first
;
	mov dword ptr es:[ebx+esi],0
	jmp write_file_done

write_file_do_first:
	mov esi,es:[ebx+esi]
	inc es:[esi].fl_usage
	inc es:[esi].fl_ref_count
	push ds
	push es
	push edx
	push esi
	push edi
;
	mov ebx,ds:file_block_size
	mov esi,es:[esi].fl_base
	xchg esi,edi
	mov ax,fs
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
;
	mov eax,ebx
	dec eax
	and edx,eax
	add edi,edx
;
	sub ebx,edx
	cmp ecx,ebx
	jnc write_file_do
;
	mov ebx,ecx

write_file_do:
	push ecx
	mov ecx,ebx
	shr ecx,2
	rep movs dword ptr es:[edi],[esi]
	mov ecx,ebx
	and ecx,3
	rep movs byte ptr es:[edi],[esi]
	pop ecx
;
	pop edi
	pop esi
	pop edx
	pop es
	pop ds
;
	push bx
	push ecx
	push edi
	mov edi,esi
	mov ecx,ebx
	mov al,ds:file_drive
	mov bx,ds
	CallFileSystem write_file_block_proc
	pop edi
	pop ecx
	pop bx	
;
	dec es:[esi].fl_usage
	add edx,ebx
	add ebp,ebx
	add edi,ebx
	sub ecx,ebx
	jnz write_file_loop
;
	clc

write_file_done:
	pushf
	LeaveWriteSection ds:file_size_section
	popf
	mov eax,ebp
;
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop fs
	pop es
	ret
write_file	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetFileInfo
;
;		DESCRIPTION:	Get file info
;
;		PARAMETERS:		BX			FILE HANDLE
;
;		RETURNS:		AX			FILE SYSTEM HANDLE
;						CL			ACCESS
;						CH			DRIVE
;						NC			SUCCESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_info_name	DB 'Get File info',0

get_file_info	PROC far
	push ds
	push bx
	mov ax,FILE_HANDLE
	DerefHandle
	jc get_file_info_done
;
	mov ax,[bx].file_handle_sel
	mov cl,[bx].file_handle_access
	mov ch,[bx].file_handle_drive
	clc

get_file_info_done:
	pop bx
	pop ds
	ret
get_file_info	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DuplFileInfo
;
;		DESCRIPTION:	Duplicate handle using file-info
;
;		PARAMETERS:		AX			FILE SYSTEM HANDLE
;						CL			ACCESS
;						CH			DRIVE
;
;		RETURNS:		BX			FILE HANDLE
;						NC			SUCCESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dupl_file_info_name	DB 'Duplicate File info',0

dupl_file_info	PROC far
	push ds
	push ax
	mov ds,ax
	inc ds:file_usage
	pop ax
	push cx
	mov cx,SIZE file_handle_seg
	AllocateHandle
	pop cx
	mov [bx].file_handle_pos,0
	mov [bx].file_handle_sel,ax
	mov [bx].file_handle_access,cl
	mov [bx].file_handle_drive,ch
	mov [bx].hh_sign,FILE_HANDLE
	mov bx,[bx].hh_handle
	clc
	pop ds
	ret
dupl_file_info	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CLOSE_FILE
;
;		DESCRIPTION:	Close file
;
;		PARAMETERS:		BX			FILE HANDLE
;						NC			SUCCESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_file_name	DB 'Close File',0

close_file:	
	push ds
	push bx
	push si
;
	mov ax,FILE_HANDLE
	DerefHandle
	jc close_file_done
;
	mov si,bx
	mov al,[bx].file_handle_drive
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz close_file_done
;
	mov ds,bx
	sub ds:file_usage,1
	jnz close_file_handle
;
;	CallFileSystem close_file_proc
;	call FreeFileSel

close_file_handle:
	mov bx,si
	FreeHandle
	clc

close_file_done:
	pop si
	pop bx
	pop ds
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DUPL_FILE
;
;		DESCRIPTION:	Duplicate file handle
;
;		PARAMETERS:		AX			OLD FILE HANDLE
;
;		RETURNS:		BX			NEW FILE HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dupl_file_name	DB 'Duplicate File Handle',0

dupl_file:
	push ds
	push es
	push eax
	push cx
	push si
;
	mov bx,ax
	mov ax,FILE_HANDLE
	DerefHandle
	jc dupl_file_done
;
	mov si,bx
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz dupl_file_done
;
	mov ds,bx
	inc ds:file_usage
;
	mov cx,SIZE file_handle_seg
	AllocateHandle
	mov eax,[si].file_handle_pos
	mov [bx].file_handle_pos,eax
	mov ax,[si].file_handle_sel
	mov [bx].file_handle_sel,ax
	mov al,[si].file_handle_access
	mov [bx].file_handle_access,al
	mov al,[si].file_handle_drive
	mov [bx].file_handle_drive,al
	mov [bx].hh_sign,FILE_HANDLE
	mov bx,[bx].hh_handle
	clc

dupl_file_done:
	pop si
	pop cx
	pop eax
	pop es
	pop ds
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_IOCTL_DATA
;
;		DESCRIPTION:	Get IOCTL data
;
;		PARAMETERS:		BX			FILE HANDLE
;
;		RETURNS:		DX			DEVICE ATTRIBUTE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ioctl_data_name	DB 'Get IOCTL Data',0

get_ioctl_data:
	push ds
	push ax
	push bx
;
	mov ax,FILE_HANDLE
	DerefHandle
	jc get_ioctl_data_done
;
	mov al,[bx].file_handle_drive
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz get_ioctl_data_done
;
	CallFileSystem get_ioctl_data_proc
get_ioctl_data_done:
	pop bx
	pop ax
	pop ds
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_FILE_SIZE
;
;		DESCRIPTION:	Get file size
;
;		PARAMETERS:		BX			FILE HANDLE
;				
;		RETURNS:		EAX			SIZE OF FILE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_size_name	DB 'Get File Size',0

get_file_size:
	push ds
	push bx
	push edx
;
	mov ax,FILE_HANDLE
	DerefHandle
	jc get_file_size_done
;
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz get_file_size_done
;
	mov ds,bx
	EnterReadSection ds:file_size_section
	mov eax,ds:file_size
	LeaveReadSection ds:file_size_section
	clc

get_file_size_done:
	pop edx
	pop bx
	pop ds
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_FILE_SIZE
;
;		DESCRIPTION:	Set file size
;
;		PARAMETERS:		BX			FILE HANDLE
;						EAX			SIZE OF FILE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_file_size_name	DB 'Set File Size',0

set_file_size:
	push ds
	push eax
	push bx
	push edx
;
	mov edx,eax
	mov ax,FILE_HANDLE
	DerefHandle
	jc set_file_size_done
;
	mov al,[bx].file_handle_drive
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz set_file_size_done
;
	mov ds,bx
	EnterWriteSection ds:file_size_section
	CallFileSystem set_file_size_proc
	LeaveWriteSection ds:file_size_section

set_file_size_done:
	pop edx
	pop bx
	pop eax
	pop ds
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_FILE_POS
;
;		DESCRIPTION:	Get file position
;
;		PARAMETERS:		BX			FILE HANDLE
;			
;		RETURNS:		EAX			FILE POSITION
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_pos_name	DB 'Get File Position',0

get_file_pos:
	push ds
	push bx
;
	mov ax,FILE_HANDLE
	DerefHandle
	jc get_file_pos_done
;
	mov ax,[bx].file_handle_sel
	or ax,ax
	stc
	jz get_file_pos_done
;
	mov eax,[bx].file_handle_pos
	clc

get_file_pos_done:
	pop bx
	pop ds
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_FILE_POS
;
;		DESCRIPTION:	Set file position
;
;		PARAMETERS:		BX			FILE HANDLE
;						EAX			FILE POSITION
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_file_pos_name	DB 'Set File Position',0

set_file_pos:
	push ds
	push bx
	push eax
	push edx
;
	mov edx,eax
	mov ax,FILE_HANDLE
	DerefHandle
	jc set_file_pos_done
;
	mov [bx].file_handle_pos,edx
	clc

set_file_pos_done:
	pop edx
	pop eax
	pop bx
	pop ds
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_FILE_TIME
;
;		DESCRIPTION:	Get file time & date
;
;		PARAMETERS:		BX			FILE HANDLE
;			
;		RETURNS:		EDX:EAX		CURRENT FILE TIME
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_time_name	DB 'Get File Time',0

get_file_time:
	push ds
	push es
	push bx
	push ecx
;
	mov ax,FILE_HANDLE
	DerefHandle
	jc get_file_time_done
;
	mov dx,flat_sel
	mov es,dx
	mov al,[bx].file_handle_drive
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz get_file_time_done
;
	mov ds,bx
	mov edx,ds:file_dir_entry
	mov eax,es:[edx].de_time
	mov edx,es:[edx].de_time+4
	clc

get_file_time_done:
	pop ecx
	pop bx
	pop es
	pop ds
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_FILE_TIME
;
;		DESCRIPTION:	Set file time & date
;
;		PARAMETERS:		BX			FILE HANDLE
;						EDX:EAX		NEW FILE TIME
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_file_time_name	DB 'Set File Time',0

set_file_time:
	push ds
	push es
	push fs
	push ax
	push bx
	push ecx
	push edx
	push edi
;
	mov cx,flat_sel
	mov es,cx
	mov ecx,eax
	mov ax,FILE_HANDLE
	DerefHandle
	jc set_file_time_done
;
	mov al,[bx].file_handle_drive
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz set_file_time_done
;
	mov fs,bx
	mov edi,fs:file_dir_entry
	mov es:[edi].de_time,ecx
	mov es:[edi].de_time+4,edx
	mov edx,edi
	CallFileSystem update_file_proc
	clc

set_file_time_done:
	pop edi
	pop edx
	pop ecx
	pop bx
	pop ax
	pop fs
	pop es
	pop ds
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			READ_FILE
;
;		DESCRIPTION:	Read file
;
;		PARAMETERS:		ES:(E)DI	BUFFER
;						BX			HANDLE
;						(E)CX		NUMBER OF BYTES TO READ
;
;		RETURNS:		(E)AX		NUMBER OF BYTES READ
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_file_name	DB 'Read File',0

read_file32:
	push ds
	push bx
	push edx
	push si
;
	mov ax,FILE_HANDLE
	DerefHandle
	jc read_file32_done
;
	mov si,bx
	mov al,[bx].file_handle_drive
	mov edx,[bx].file_handle_pos
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz read_file32_done
;
	push ds
	mov ds,bx
	test ds:file_attrib, FILE_ATTRIB_NOBUFFER
	jz read_file32_buf
;
	CallFileSystem read_file_proc
	jmp read_file32_save

read_file32_buf:
	call read_file

read_file32_save:
	pop ds
	pushf
	add [si].file_handle_pos,eax
	popf

read_file32_done:
	pop si
	pop edx
	pop bx
	pop ds
	retf32

read_file16	PROC far
	push ds
	push bx
	push ecx
	push edx
	push si
	push edi
;
	movzx ecx,cx
	movzx edi,di
	mov ax,FILE_HANDLE
	DerefHandle
	jc read_file16_done
;
	mov si,bx
	mov al,[bx].file_handle_drive
	mov edx,[bx].file_handle_pos
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz read_file16_done
;
	push ds
	mov ds,bx
	test ds:file_attrib, FILE_ATTRIB_NOBUFFER
	jz read_file16_buf
;
	CallFileSystem read_file_proc
	jmp read_file16_save

read_file16_buf:
	call read_file

read_file16_save:
	pop ds
	pushf
	add [si].file_handle_pos,eax
	popf

read_file16_done:
	pop edi
	pop si
	pop edx
	pop ecx
	pop bx
	pop ds
	ret
read_file16	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WRITE_FILE
;
;		DESCRIPTION:	Write file
;
;		PARAMETERS:		ES:(E)DI	BUFFER
;						BX			HANDLE
;						(E)CX		NUMBER OF BYTES TO WRITE
;		
;		RETURNS:		(E)AX		NUMBER OF BYTES WRITTEN
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_file_name	DB 'Write File',0

write_file32:
	push ds
	push bx
	push edx
	push si
;
	mov ax,FILE_HANDLE
	DerefHandle
	jc write_file32_done
;
	mov si,bx
	mov al,[bx].file_handle_drive
	mov edx,[bx].file_handle_pos
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz write_file32_done
;
	push ds
	mov ds,bx
	test ds:file_attrib, FILE_ATTRIB_NOBUFFER
	jz write_file32_buf
;
	CallFileSystem write_file_proc
	jmp write_file32_save

write_file32_buf:
	call write_file

write_file32_save:
	pop ds
	pushf
	add [si].file_handle_pos,eax
	popf

write_file32_done:
	pop si
	pop edx
	pop bx
	pop ds
	retf32

write_file16	PROC far
	push ds
	push bx
	push ecx
	push edx
	push si
	push edi
;
	movzx ecx,cx
	movzx edi,di
	mov ax,FILE_HANDLE
	DerefHandle
	jc write_file16_done
;
	mov si,bx
	mov al,[bx].file_handle_drive
	mov edx,[bx].file_handle_pos
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz write_file16_done
;
	push ds
	mov ds,bx
	test ds:file_attrib, FILE_ATTRIB_NOBUFFER
	jz write_file16_buf
;
	CallFileSystem write_file_proc
	jmp write_file16_save

write_file16_buf:
	call write_file

write_file16_save:
	pop ds
	pushf
	add [si].file_handle_pos,eax
	popf

write_file16_done:
	pop edi
	pop si
	pop edx
	pop ecx
	pop bx
	pop ds
	ret
write_file16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			map_to_file
;
;		DESCRIPTION:	Map page from file to memory object
;
;		PARAMETERS:		EAX			Offset within object
;						BX			File handle
;						EDX			Pagefault base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public map_to_file

map_to_file	Proc near
	push ds
	push es
	pushad
;
	mov edi,edx
	mov edx,eax
	mov ax,FILE_HANDLE
	DerefHandle
	jc map_to_file_done
;
	mov si,bx
	mov al,[bx].file_handle_drive
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz map_to_file_done
;
	mov ds,bx
	test ds:file_attrib, FILE_ATTRIB_NOBUFFER
	jnz map_to_file_read
;
	mov ax,flat_sel
	mov es,ax
;
	EnterReadSection ds:file_size_section
	cmp edx,ds:file_size
	jnc map_to_file_leave
;
	mov esi,edx
	mov cl,ds:file_dir_shift
	shr esi,cl
	shl si,2
	mov ebx,ds:[si].file_entries
	EnterSection ds:file_list_section
	or ebx,ebx
	jnz map_to_file_check_mid
;
	call CreateListDir
	mov ds:[si].file_entries,ebx

map_to_file_check_mid:
	mov esi,edx
	mov cl,ds:file_entry_shift
	shr esi,cl
	shl si,2
	and esi,0FFCh
	mov eax,es:[ebx+esi]
	or eax,eax
	jnz map_to_file_check_base
;
	lea eax,[ebx+esi]
	call CreateListEntry
	mov es:[ebx+esi],eax

map_to_file_check_base:
	cmp es:[eax].fl_state, FILE_LIST_STATE_EMPTY
	jne map_to_file_do_first
;
	push edi
	mov edi,eax
	call ReadFileListEntry
	pop edi
	jnc map_to_file_do_first
;
	mov dword ptr es:[ebx+esi],0
	LeaveSection ds:file_list_section
	stc
	jmp map_to_file_leave

map_to_file_do_first:
	mov esi,es:[ebx+esi]
	inc es:[esi].fl_ref_count
	mov ebx,ds:file_block_size
	mov esi,es:[esi].fl_base
	mov eax,ebx
	dec eax
	and edx,eax
	add esi,edx
;
	mov ax,process_page_sel
	mov es,ax
	shr esi,10
	shr edi,10
	mov eax,es:[esi]
	or ax,807h
	mov es:[edi],eax
;
	LeaveSection ds:file_list_section
	clc

map_to_file_leave:
	LeaveReadSection ds:file_size_section
	jmp map_to_file_done

map_to_file_read:
	push edi
	mov si,process_page_sel
	mov es,si
	shr edi,10
	mov dword ptr es:[edi],2
	pop edi
	mov si,flat_sel
	mov es,si
	mov ecx,1000h
	CallFileSystem read_file_proc

map_to_file_done:
	popad
	pop es
	pop ds
	ret
map_to_file	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Delete_handle
;
;		DESCRIPTION:	Delete handle (called from handle module)
;
;		PARAMETERS:		BX			FILE HANDLE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	push ds
	push bx
	push si
;
	mov ax,FILE_HANDLE
	DerefHandle
	jc delete_handle_done
;
	mov si,bx
	mov al,[bx].file_handle_drive
	mov bx,[bx].file_handle_sel
	or bx,bx
	stc
	jz delete_handle_done
;
	mov ds,bx
	sub ds:file_usage,1
	jnz delete_handle_handle
;
;	CallFileSystem close_file_proc
;	call FreeFileSel

delete_handle_handle:
	mov bx,si
	FreeHandle
	clc

delete_handle_done:
	pop si
	pop bx
	pop ds
	ret
delete_handle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Init
;
;		DESCRIPTION:	Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_file

init_file	PROC near
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET delete_handle
	mov ax,FILE_HANDLE
	RegisterHandle
;
	mov si,OFFSET get_file_list_entry
	mov di,OFFSET get_file_list_entry_name
	xor cl,cl
	mov ax,get_file_list_entry_nr
	RegisterOsGate
;
	mov si,OFFSET free_file_list_entry
	mov di,OFFSET free_file_list_entry_name
	xor cl,cl
	mov ax,free_file_list_entry_nr
	RegisterOsGate
;
	mov si,OFFSET get_file_info
	mov di,OFFSET get_file_info_name
	xor cl,cl
	mov ax,get_file_info_nr
	RegisterOsGate
;
	mov si,OFFSET dupl_file_info
	mov di,OFFSET dupl_file_info_name
	xor cl,cl
	mov ax,dupl_file_info_nr
	RegisterOsGate
;
	mov si,OFFSET close_file
	mov di,OFFSET close_file_name
	xor dx,dx
	mov ax,close_file_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET dupl_file
	mov di,OFFSET dupl_file_name
	xor dx,dx
	mov ax,dupl_file_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_ioctl_data
	mov di,OFFSET get_ioctl_data_name
	xor dx,dx
	mov ax,get_ioctl_data_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_file_size
	mov di,OFFSET get_file_size_name
	xor dx,dx
	mov ax,get_file_size_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_file_size
	mov di,OFFSET set_file_size_name
	xor dx,dx
	mov ax,set_file_size_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_file_pos
	mov di,OFFSET get_file_pos_name
	xor dx,dx
	mov ax,get_file_pos_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_file_pos
	mov di,OFFSET set_file_pos_name
	xor dx,dx
	mov ax,set_file_pos_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_file_time
	mov di,OFFSET get_file_time_name
	xor dx,dx
	mov ax,get_file_time_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_file_time
	mov di,OFFSET set_file_time_name
	xor dx,dx
	mov ax,set_file_time_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET read_file16
	mov si,OFFSET read_file32
	mov di,OFFSET read_file_name
	mov dx,virt_es_in
	mov ax,read_file_nr
	RegisterUserGate
;
	mov bx,OFFSET write_file16
	mov si,OFFSET write_file32
	mov di,OFFSET write_file_name
	mov dx,virt_es_in
	mov ax,write_file_nr
	RegisterUserGate
	ret
init_file	ENDP

code	ENDS

	END
