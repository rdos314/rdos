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
; DIR.ASM
; Dir module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME dir

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

dir_handle_seg	STRUC

dir_handle_base	handle_header <>

dir_handle_sel	DW ?

dir_handle_seg	ENDS

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

	extrn CreateFileHandle:near
	extrn CreateFileSel:near
	extrn FreeFileSel:near
	extrn FreeFile:near

char_tab:
ct00 DB	0,		0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct08 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct10 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct18 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct20 DB ' ',	'!',	0FFh,	'#',	'$',	'%',	'&',	27h
ct28 DB '(',	')',	0FFh,	0FFh,	0FFh,	'-',	'.',	0
ct30 DB '0',	'1',	'2',	'3',	'4',	'5',	'6',	'7'
ct38 DB '8',	'9',	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct40 DB '@',	'A',	'B',	'C',	'D',	'E',	'F',	'G'
ct48 DB 'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O'
ct50 DB 'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W'
ct58 DB	'X',	'Y',	'Z',	0FFh,	0,		0FFh,	'^',	'_'
ct60 DB 60h,	'A',	'B',	'C',	'D',	'E',	'F',	'G'
ct68 DB 'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O'
ct70 DB 'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W'
ct78 DB 'X',	'Y',	'Z',	'{',	0FFh,	'}',	7Eh,	0FFh
ct80 DB	0FFh,	0FFh,	0FFh,	0FFh,	8Eh,	0FFh,	8Fh,	0FFh
ct88 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	8Eh,	8Fh
ct90 DB	0FFh,	0FFh,	0FFh,	0FFh,	99h,	0FFh,	0FFh,	0FFh
ct98 DB	0FFh,	99h,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctA0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctA8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctB0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctB8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctC0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctC8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctD0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctD8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctE0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctE8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctF0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctF8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ValidateDrive
;
;		DESCRIPTION:	Validate drive
;
;		PARAMETERS:		AL			Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ValidateDrive	Proc near
	push ds
	push bx
	push si
;
	mov si,fs_data_sel
	mov ds,si
	movzx si,al
	add si,si

validate_drive_retry:
	mov bx,ds:[si].fs_sel
	or bx,bx
	jnz validate_drive_defined
;
	mov bl,ds:fs_init_done
	or bl,bl
	stc
	jnz validate_drive_done
;
    push esi
    mov esi,OFFSET fs_init_section
    EnterSection
    LeaveSection
    pop esi
	jmp validate_drive_retry

validate_drive_defined:
	cmp bx,-1
	jnz validate_drive_media
;
	DemandLoadDrive
	jmp validate_drive_retry

validate_drive_media:
	mov bx,ds:[si].media_check_handle
	or bx,bx
	clc
	jz validate_drive_done
;
	add si,si
	call ds:[si].media_check_proc
	clc

validate_drive_done:
	pop si
	pop bx
	pop ds
	ret
ValidateDrive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CacheDirEntry
;
;		DESCRIPTION:	Cache dir entry structure
;
;		PARAMETERS:		BX			Dir selector
;						EDX			Dir entry
;
;		RETURNS:		BX			Cached dir selector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_dir_name DB 'Cache Dir', 0

cache_dir	PROC far
	push ds
	push es
	push fs
	push ax
	push si
	push ebp
;
	mov ds,bx
	mov ax,flat_sel
	mov es,ax
;
	mov bx,es:[edx].de_sel
	or bx,bx
	jnz cache_dir_done
;
	mov al,ds:ds_drive
	mov bx,ds
;
	mov si,fs_data_sel
	mov ds,si
	movzx si,al
	add si,si
	mov si,ds:[si].fs_sel
	mov ds,si
	mov ebp,ds:fs_mount_id
;
	call CreateDirSel
	CallFileSystem cache_dir_proc
	mov es:[edx].de_sel,bx

cache_dir_done:
	pop ebp
	pop si
	pop ax
	pop fs
	pop es
	pop ds
	ret
cache_dir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InsertDirEntry
;
;		DESCRIPTION:	Insert dir entry structure
;
;		PARAMETERS:		BX			Dir selector
;						EDX			Dir entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_dir_entry_name DB 'Insert Dir Entry', 0

insert_dir_entry	PROC far
	push ds
	push es
	push eax
	push ebx
;
	mov ds,bx
	mov ax,flat_sel
	mov es,ax
;
	mov es:[edx].de_sel,0
;
	mov eax,ds:ds_dir_ptr
	or eax,eax
	jne insert_dir_used

insert_dir_empty:
	mov es:[edx].de_prev,edx
	mov es:[edx].de_next,edx
	mov ds:ds_dir_ptr,edx
	jmp insert_dir_done

insert_dir_used:
	mov ebx,es:[eax].de_prev
	mov es:[eax].de_prev,edx
	mov es:[ebx].de_next,edx
	mov es:[edx].de_prev,ebx
	mov es:[edx].de_next,eax	

insert_dir_done:
	pop ebx
	pop eax
	pop es
	pop ds
	ret
insert_dir_entry	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InsertFileEntry
;
;		DESCRIPTION:	Insert file entry structure
;
;		PARAMETERS:		BX			Dir selector
;						EDX			File entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_file_entry_name DB 'Insert File Entry', 0

insert_file_entry	PROC far
	push ds
	push es
	push eax
	push ebx
;
	mov ds,bx
	mov ax,flat_sel
	mov es,ax
;
	mov eax,ds:ds_file_ptr
	or eax,eax
	jne insert_file_used

insert_file_empty:
	mov es:[edx].de_prev,edx
	mov es:[edx].de_next,edx
	mov ds:ds_file_ptr,edx
	jmp insert_file_done

insert_file_used:
	mov ebx,es:[eax].de_prev
	mov es:[eax].de_prev,edx
	mov es:[ebx].de_next,edx
	mov es:[edx].de_prev,ebx
	mov es:[edx].de_next,eax	

insert_file_done:
	pop ebx
	pop eax
	pop es
	pop ds
	ret
insert_file_entry	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateDirSel
;
;		DESCRIPTION:	Create a dir selector
;
;		PARAMETERS:		AL			Drive
;						BX			Parent dir selector
;						EDX			Parent dir entry
;						EBP			Mount id
;
;		RETURNS:		BX			Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDirSel	PROC near
	push ds
;
	push bx
	CallFileSystem allocate_dir_sel_proc
	mov ds,bx
	pop bx
;
    push esi
    mov esi,OFFSET ds_access_section
    InitNewReadWriteSection
;    
    mov esi,OFFSET ds_list_section
    InitSection	
    pop esi
;
	mov ds:ds_dir_ptr,0
	mov ds:ds_file_ptr,0
	mov ds:ds_usage,0
	mov ds:ds_drive,al
	mov ds:ds_parent,bx
	mov ds:ds_handle,edx
	mov ds:ds_mount_id,ebp
	mov bx,ds
;
	pop ds
	ret
CreateDirSel	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeDirSel
;
;		DESCRIPTION:	Free dir selector
;
;		PARAMETERS:		DS			Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDirSel	PROC near
	push eax
	push bx
	push ecx
	push edx
;
	mov ax,flat_sel
	mov es,ax
;
	mov edx,ds:ds_dir_ptr
	or edx,edx
	jz free_dir_file

free_dir_dir_loop:
	mov eax,es:[edx].de_next
	mov cx,es:[edx].de_usage
	or cx,cx
	jnz free_dir_dir_next
;
	xor ecx,ecx
	FreeLinear

free_dir_dir_next:
	mov edx,eax
	cmp edx,ds:ds_dir_ptr
	jne free_dir_dir_loop

free_dir_file:
	mov edx,ds:ds_file_ptr
	or edx,edx
	jz free_dir_del

free_dir_file_loop:
	mov eax,es:[edx].de_next
	mov cx,es:[edx].de_usage
	or cx,cx
	jnz free_dir_file_next
;
	xor ecx,ecx
	FreeLinear

free_dir_file_next:
	mov edx,eax
	cmp edx,ds:ds_file_ptr
	jne free_dir_file_loop

free_dir_del:
	mov al,ds:ds_drive
	mov bx,ds
	xor dx,dx
	mov ds,dx
	CallFileSystem free_dir_sel_proc
;
	pop edx
	pop ecx
	pop bx
	pop eax
	ret
FreeDirSel	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeDir
;
;		DESCRIPTION:	Free dir if idle
;
;		PARAMETERS:		BX			Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDir	PROC near
	push ds
	push ax
;
	mov ds,bx
	mov ax,ds:ds_usage
	or ax,ax
	stc
	jnz free_dir_done
;
	call FreeDirSel
	clc

free_dir_done:
	pop ax
	pop ds
	ret
FreeDir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateDirHandle
;
;		DESCRIPTION:	Create dir handle
;
;		PARAMETERS:		BX		Dir search selector
;
;		RETURNS:		BX		Dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDirHandle	Proc near
	push ds
	push cx
	push si
;
	mov si,bx
	mov cx,SIZE dir_handle_seg
	AllocateHandle
	mov [bx].dir_handle_sel,si
	mov [bx].hh_sign,DIR_HANDLE
	mov bx,[bx].hh_handle
;
	pop si
	pop cx
	pop ds
	ret
CreateDirHandle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ParseDir
;
;		DESCRIPTION:	Parse pathname
;
;		PARAMETERS:		ES:EDI	Pathname
;
;		RETURNS:		DS		Dir selector
;						ES:EDI	Remaining part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseDir	Proc near
	push fs
	push ax
	push bx
	push cx
	push edx
	push esi
	push ebp
;
	mov bx,fs_process_sel
	mov ds,bx
	mov al,ds:curr_drive
	mov bx,es:[edi]
	or bl,bl
	je parse_drive_done
;
	cmp bh,':'
	jne parse_drive_done
;
	sub bl,'A'
	jc parse_dir_fail
;
	cmp bl,26
	jc parse_drive_ok
;
	sub bl,20h
	jc parse_dir_fail
;
	cmp bl,26
	jnc parse_dir_fail

parse_drive_ok:
	mov al,bl
	call ValidateDrive
	jc parse_dir_fail
;
	add edi,2

parse_drive_done:
	mov ah,es:[edi]
	cmp ah,'\'
	je parse_dir_abs
;
	cmp ah,'/'
	jne parse_dir_rel

parse_dir_abs:
	inc edi
	jmp parse_dir_root

parse_dir_rel:
	movzx si,al
	add si,si
	mov bx,ds:[si].cur_dir_sel
	or bx,bx
	jz parse_dir_root
;
	mov ds,bx
	mov ebp,ds:ds_mount_id
	mov si,fs_data_sel
	mov ds,si
	movzx si,al
	add si,si
	mov ds,ds:[si].fs_sel
	cmp ebp,ds:fs_mount_id
	jne parse_dir_root
;
    push esi
    mov esi,OFFSET fs_access_section
    EnterNewReadSection
    pop esi    
	jmp parse_dir_start

parse_dir_old:
	int 3
	mov ds,bx
	sub ds:ds_usage,1
	jnz parse_dir_old_zero
;
	call FreeDir

parse_dir_old_zero:
	mov bx,fs_process_sel
	mov ds,bx
	movzx si,al
	add si,si
	mov ds:[si].cur_dir_sel,0

parse_dir_root:
	mov bx,fs_data_sel
	mov ds,bx
	movzx si,al
	add si,si
	mov bx,ds:[si].fs_sel
	or bx,bx
	jz parse_dir_fail
;
	mov ds,bx
	push esi
	mov esi,OFFSET fs_list_section
	EnterSection
	pop esi
;	
	mov ebp,ds:fs_mount_id
	mov bx,ds:fs_root_dir_sel
	or bx,bx
	jnz parse_dir_buffered
;
	xor edx,edx
	call CreateDirSel
	CallFileSystem cache_dir_proc
	mov ds:fs_root_dir_sel,bx
;
	push ds
	mov ds,bx
	inc ds:ds_usage
	mov dx,fs_process_sel
	mov ds,dx
	mov ds:[si].cur_dir_sel,bx
	pop ds

parse_dir_buffered:
    push esi
    mov esi,OFFSET fs_access_section
    EnterNewReadSection
;
	mov esi,OFFSET fs_list_section
	LeaveSection
	pop esi

parse_dir_start:
	mov ds:fs_access_parse,1
	mov ds,bx
	mov bx,flat_sel
	mov fs,bx
;
	push esi
    mov esi,OFFSET ds_access_section
    EnterNewReadSection
    pop esi

parse_dir_tree_loop:
	mov bx,OFFSET char_tab
;
	mov al,es:[edi]
	cmp al,'.'
	je parse_dir_dot
;
	mov esi,ds:ds_dir_ptr
	or esi,esi
	jz parse_dir_ok

parse_dir_entry_loop:
	mov cx,fs:[esi].de_name_size	
	push esi
	push edi
	mov esi,fs:[esi].de_name

parse_dir_name_loop:
	mov al,es:[edi]
	xlat byte ptr cs:char_tab
	mov ah,al
	mov al,fs:[esi]
	xlat byte ptr cs:char_tab
	cmp al,ah
	jne parse_dir_next
;
	inc esi
	inc edi
	loop parse_dir_name_loop
;
	mov al,es:[edi]
	or al,al
	jz parse_dir_tree_next
;
	inc edi
	cmp al,'\'
	je parse_dir_tree_next
;
	cmp al,'/'
	je parse_dir_tree_next
	jmp parse_dir_next

parse_dir_dot:
	inc edi

parse_dir_dot_loop:
	mov al,es:[edi]
	cmp al,'.'
	jne parse_dir_dot_ended
;
	inc edi
	push esi
	mov esi,OFFSET ds_list_section
	EnterSection
	mov bx,ds:ds_parent
	LeaveSection
	pop esi
	or bx,bx
	jz parse_dir_fail
;
    push esi
	mov ax,ds
	mov ds,bx
	mov esi,OFFSET ds_access_section
	EnterNewReadSection	
	mov ds,ax
	LeaveNewReadSection
	mov ds,bx
	pop esi
	jmp parse_dir_dot_loop

parse_dir_dot_ended:
	or al,al
	jz parse_dir_ok
;
	inc edi
	cmp al,'\'
	je parse_dir_tree_loop
;
	cmp al,'/'
	je parse_dir_tree_loop

parse_dir_dot_fail:
    push esi
	mov esi,OFFSET ds_access_section
	LeaveNewReadSection	
	pop esi
	jmp parse_dir_fail

parse_dir_next:
	pop edi
	pop esi
	mov esi,fs:[esi].de_next
	cmp esi,ds:ds_dir_ptr
	jne parse_dir_entry_loop
	jmp parse_dir_ok

parse_dir_tree_next:
	mov esi,OFFSET ds_list_section
	EnterSection
;
	pop esi
	pop esi
	mov bx,fs:[esi].de_sel
	or bx,bx
	jnz parse_dir_tree_cached
;
	mov al,ds:ds_drive
	mov bx,ds
	mov edx,esi
	call CreateDirSel
	CallFileSystem cache_dir_proc
	mov fs:[esi].de_sel,bx

parse_dir_tree_cached:
    push esi
    mov esi,OFFSET ds_list_section
    LeaveSection    
	mov ax,ds
	mov ds,bx
	mov esi,OFFSET ds_access_section
	EnterNewReadSection
	mov ds,ax
	LeaveNewReadSection
	mov ds,bx
    pop esi
;
	mov al,es:[edi]
	or al,al
	jnz parse_dir_tree_loop

parse_dir_ok:
	inc ds:ds_usage
	push esi
	mov esi,OFFSET ds_access_section
	LeaveNewReadSection
	pop esi
	clc
	jmp parse_dir_done

parse_dir_fail:
	stc

parse_dir_done:
	pop ebp
	pop esi
	pop edx
	pop cx
	pop bx
	pop ax
	pop fs
	ret
ParseDir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ParseEnd
;
;		DESCRIPTION:	End parsing
;
;		PARAMETERS:		DS		Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseEnd	Proc near
	push ds
	push ax
	push esi
;
	movzx si,ds:ds_drive
	add si,si
	mov ax,fs_data_sel
	mov ds,ax
	mov ds,ds:[si].fs_sel
	cli
	mov ds:fs_access_parse,0
;
    mov esi,OFFSET fs_access_section
    LeaveNewReadSection
;
	pop esi
	pop ax
	pop ds
	ret
ParseEnd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDeviceRoot
;
;		DESCRIPTION:	Get device root
;
;		RETURNS:		DS		Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDeviceRoot	Proc near
	push ax
	push bx
	push cx
	push edx
	push esi
	push ebp
;
	mov al,80h
	mov bx,fs_data_sel
	mov ds,bx
	movzx si,al
	add si,si
	mov ds,ds:[si].fs_sel
;	
	push esi
	mov esi,OFFSET fs_access_section
    EnterNewReadSection
;
	mov esi,OFFSET fs_list_section
	EnterSection
	pop esi
;	
	mov bx,ds:fs_root_dir_sel
	or bx,bx
	jnz get_device_root_done
;
	xor ebp,ebp
	xor edx,edx
	call CreateDirSel
	CallFileSystem cache_dir_proc
	mov ds:fs_root_dir_sel,bx
;
	push ds
	mov dx,fs_process_sel
	mov ds,dx
	mov ds:[si].cur_dir_sel,bx
	pop ds

get_device_root_done:
    mov esi,OFFSET fs_list_section
    LeaveSection
	mov ds,bx
;
	pop ebp
	pop esi
	pop edx
	pop cx
	pop bx
	pop ax
	ret
GetDeviceRoot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ParseFile
;
;		DESCRIPTION:	Parse pathname for a valid file
;
;		PARAMETERS:		DS		Dir selector
;						FS		Flat sel
;						ES:EDI	Pathname
;
;		RETURNS:		EDX		File dir entry
;						ES:EDI	Remaining part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseFile	Proc near
	push ax
	push bx
	push cx
	push esi
;
	mov bx,OFFSET char_tab
	mov edx,ds:ds_file_ptr
	or edx,edx
	stc
	jz parse_file_done

parse_file_entry_loop:
	mov cx,fs:[edx].de_name_size	
	mov esi,fs:[edx].de_name
	push edi

parse_file_name_loop:
	mov al,es:[edi]
	xlat byte ptr cs:char_tab
	mov ah,al
	mov al,fs:[esi]
	xlat byte ptr cs:char_tab
	cmp al,ah
	jne parse_file_next
;
	inc esi
	inc edi
	loop parse_file_name_loop
;
	mov al,es:[edi]
	or al,al
	jz parse_file_ok

parse_file_next:
	pop edi
	mov edx,fs:[edx].de_next
	cmp edx,ds:ds_file_ptr
	jnz parse_file_entry_loop
;
	xor edx,edx
	stc
	jmp parse_file_done	

parse_file_ok:
	pop esi
	clc

parse_file_done:
	pop esi
	pop cx
	pop bx
	pop ax
	ret
ParseFile	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ParseName
;
;		DESCRIPTION:	Parse pathname for a valid name
;
;		PARAMETERS:		FS		Flat sel
;						ES:EDI	Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseName	Proc near
	push ax
	push bx
	push edi
;
	mov bx,OFFSET char_tab
	mov al,es:[edi]
	or al,al
	jz parse_name_fail

parse_name_loop:
	mov al,es:[edi]
	inc edi
	xlat byte ptr cs:char_tab
	or al,al
	jz parse_name_ok
;
	add al,1
	jnc parse_name_loop

parse_name_fail:
	stc
	jmp parse_name_done

parse_name_ok:
	clc

parse_name_done:
	pop edi
	pop bx
	pop ax
	ret
ParseName	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SearchDir
;
;		DESCRIPTION:	Search dir for files
;
;		PARAMETERS:		DS		Dir selector
;						FS		Flat sel
;
;		RETURNS:		BX		Dir search selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SearchDir	Proc near
	push es
	push eax
	push cx
	push di
;
	xor cx,cx
	mov eax,ds:ds_dir_ptr
	or eax,eax
	jz search_scan_dir_done

search_scan_dir_loop:
	inc cx
	mov eax,fs:[eax].de_next
	cmp eax,ds:ds_dir_ptr
	jne search_scan_dir_loop

search_scan_dir_done:	
	mov eax,ds:ds_file_ptr
	or eax,eax
	jz search_scan_file_done

search_scan_file_loop:
	inc cx
	mov eax,fs:[eax].de_next
	cmp eax,ds:ds_file_ptr
	jne search_scan_file_loop

search_scan_file_done:	
	movzx eax,cx
	shl eax,2
	add eax,OFFSET dhs_data
	AllocateGlobalMem
	mov es:dhs_count,cx
	mov al,ds:ds_drive
	mov es:dhs_drive,al
	mov eax,ds:ds_mount_id
	mov es:dhs_mount_id,eax
	mov di,OFFSET dhs_data
;
	mov eax,ds:ds_dir_ptr
	or eax,eax
	jz search_move_dir_done

search_move_dir_loop:
	inc fs:[eax].de_usage
	stosd
	mov eax,fs:[eax].de_next
	cmp eax,ds:ds_dir_ptr
	jne search_move_dir_loop

search_move_dir_done:
	mov eax,ds:ds_file_ptr
	or eax,eax
	jz search_move_file_done

search_move_file_loop:
	inc fs:[eax].de_usage
	stosd
	mov eax,fs:[eax].de_next
	cmp eax,ds:ds_file_ptr
	jne search_move_file_loop

search_move_file_done:	
	mov bx,es
;
	pop di
	pop cx
	pop eax
	pop es
	ret
SearchDir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetCurDirBase
;
;		DESCRIPTION:	Set current directory
;
;		PARAMETERS:		AL			Drive
;						ES:EDI		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCurDirBase	Proc near
	push ds
	push fs
	push eax
	push bx
	push ecx
	push edx
	push esi
;
	call ValidateDrive
	jc get_cur_dir_done
;
	mov bx,fs_data_sel
	mov ds,bx
	movzx bx,al
	add bx,bx
	mov ds,ds:[bx].fs_sel
;
	mov esi,OFFSET fs_access_section
    EnterNewReadSection
;	
	mov ds:fs_access_parse,1
	mov edx,ds:fs_mount_id
;
	mov si,fs_process_sel
	mov ds,si
	mov si,flat_sel
	mov fs,si
	mov bx,ds:[bx].cur_dir_sel
	xor ecx,ecx
	mov byte ptr es:[edi],0
	or bx,bx
	je get_cur_dir_ok
;
	mov ds,bx
	cmp edx,ds:ds_mount_id
	jne get_cur_dir_ok
;
	mov esi,OFFSET ds_access_section
	EnterNewReadSection

get_cur_dir_loop:
	mov bx,ds:ds_parent
	or bx,bx
	jz get_cur_dir_leave
;
	push ds
	mov ds,bx
	mov esi,OFFSET ds_access_section
	EnterNewReadSection
	pop ds
;
	LeaveNewReadSection
	mov ds,bx
	mov eax,ds:ds_dir_ptr

get_cur_dir_node_loop:
	cmp si,fs:[eax].de_sel
	je get_cur_dir_node_found
;
	mov eax,fs:[eax].de_next
	jmp get_cur_dir_node_loop

get_cur_dir_node_found:
	push eax
	push ecx
	push edi
	movzx eax,fs:[eax].de_name_size
	inc eax
	mov esi,edi
	add edi,eax
	add esi,ecx
	add edi,ecx
	dec esi
	dec edi
	std
	rep movs byte ptr es:[edi],es:[esi]
	cld
	pop edi
	pop ecx
	pop esi
	movzx eax,fs:[esi].de_name_size
	add ecx,eax
	inc ecx
;
	push ecx
	push edi
	mov esi,fs:[esi].de_name
	mov ecx,eax
	mov al,es:[edi]
	rep movs byte ptr es:[edi],fs:[esi]
	or al,al
	je get_cur_dir_no_slash
;
	mov al,'\'

get_cur_dir_no_slash:
	stos byte ptr es:[edi]
	pop edi
	pop ecx
	jmp get_cur_dir_loop

get_cur_dir_leave:
	mov esi,OFFSET ds_access_section
	LeaveNewReadSection
	mov al,ds:ds_drive

get_cur_dir_ok:
	mov bx,fs_data_sel
	mov ds,bx
	movzx bx,al
	add bx,bx
	mov ds,ds:[bx].fs_sel
	cli
	mov ds:fs_access_parse,0
;
	mov esi,OFFSET fs_access_section
    LeaveNewReadSection
	clc

get_cur_dir_done:
	pop esi
	pop edx
	pop ecx
	pop bx
	pop eax
	pop fs
	pop ds
	ret
GetCurDirBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetCurDirBase
;
;		DESCRIPTION:	Set current directory
;
;		PARAMETERS:		ES:EDI		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetCurDirBase	Proc near
	push ds
	push ax
	push edi
;
	call ParseDir
	jc set_cur_dir_done
;
	mov al,es:[edi]
	or al,al
	jne set_cur_dir_fail
;
	push es
	push bx
	push si
;
	mov bx,fs_process_sel
	mov es,bx
	mov bx,ds
	mov al,ds:ds_drive
	movzx si,al
	add si,si
	xchg bx,es:[si].cur_dir_sel
	or bx,bx
	jz set_cur_dir_setup
;
	push ds
	mov ds,bx
	dec ds:ds_usage	
	pop ds

set_cur_dir_setup:
	pop si
	pop bx
	pop es
	call ParseEnd
	clc
	jmp set_cur_dir_done

set_cur_dir_fail:
	call ParseEnd
	stc

set_cur_dir_done:
	pop edi
	pop ax
	pop ds
	ret
SetCurDirBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateDirBase
;
;		DESCRIPTION:	Create a new directory
;
;		PARAMETERS:		ES:EDI		Pathname
;
;		RETURNS:		CX			FILE ATTRIBUTE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDirBase	Proc near
	push ds
	push fs
	push eax
	push ebx
	push edx
;
	mov bx,flat_sel
	mov fs,bx
;
	push edi
	call ParseDir
	jc create_dir_pop_failed
;
    push esi
	mov esi,OFFSET ds_access_section
	EnterNewWriteSection
    pop esi
;
	dec ds:ds_usage
	call ParseFile
	jc create_dir_check

create_dir_leave_fail:
    push esi
	mov esi,OFFSET ds_access_section
	LeaveNewWriteSection
    pop esi    
	call ParseEnd
	jmp create_dir_pop_failed

create_dir_check:
	call ParseName
	jc create_dir_pop_failed
;
	mov al,ds:ds_drive
	mov bx,ds
	CallFileSystem create_dir_proc
	jc create_dir_leave_fail
;
    push esi
	mov esi,OFFSET ds_access_section
	LeaveNewWriteSection
    pop esi    
	pop edi
	call ParseEnd
	clc
	jmp create_dir_done

create_dir_pop_failed:
	pop edi
	stc

create_dir_done:
	pop edx
	pop ebx
	pop eax
	pop fs
	pop ds
	ret
CreateDirBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DeleteDirBase
;
;		DESCRIPTION:	Delete a directory
;
;		PARAMETERS:		ES:EDI		Pathname
;
;		RETURNS:		NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteDirBase	Proc near
	push ds
	push es
	push fs
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov ax,flat_sel
	mov fs,ax
;
	call ParseDir
	jc delete_dir_done
;
	mov esi,OFFSET ds_access_section
	EnterNewWriteSection
;
	dec ds:ds_usage
	mov edx,ds:ds_handle
	mov bx,ds:ds_parent
	or bx,bx
	jz delete_dir_fail
;
	mov ax,ds:ds_usage
	or ax,ax
	jnz delete_dir_fail
;
	mov eax,ds:ds_dir_ptr
	or eax,eax
	jnz delete_dir_fail
;
	mov eax,ds:ds_file_ptr
	or eax,eax
	jnz delete_dir_fail
;
	push ds
	mov ds,bx
	mov esi,OFFSET ds_access_section
	EnterNewWriteSection
;
	mov ax,fs:[edx].de_usage
	or ax,ax
	jnz delete_dir_pop_fail
;
	push ebx
	mov eax,fs:[edx].de_next
	mov ebx,fs:[edx].de_prev
	mov fs:[ebx].de_next,eax
	mov fs:[eax].de_prev,ebx
	pop ebx
	cmp eax,edx
	jne delete_dir_unlink
;
	mov ds:ds_dir_ptr,0
	jmp delete_dir_leave

delete_dir_unlink:
	cmp edx,ds:ds_dir_ptr
	jne delete_dir_leave
;
	mov ds:ds_dir_ptr,eax
	
delete_dir_leave:
	mov esi,OFFSET ds_access_section
	LeaveNewWriteSection
;
	mov al,ds:ds_drive
	CallFileSystem delete_dir_proc
	pop ds
	call ParseEnd
	call FreeDirSel
	clc
	jmp delete_dir_done

delete_dir_pop_fail:
	mov esi,OFFSET ds_access_section
	LeaveNewWriteSection
	pop ds

delete_dir_fail:
	mov esi,OFFSET ds_access_section
	LeaveNewWriteSection
	call ParseEnd
	stc

delete_dir_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop fs
	pop es
	pop ds
	ret
DeleteDirBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetFileAttribBase
;
;		DESCRIPTION:	Get file attribute
;
;		PARAMETERS:		ES:EDI		Pathname
;
;		RETURNS:		CX			FILE ATTRIBUTE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFileAttribBase	Proc near
	push ds
	push es
	push fs
	push ax
	push edx
	push esi
	push edi
;
	mov ax,flat_sel
	mov fs,ax
;
	call ParseDir
	jc get_file_attrib_done
;
    mov esi,OFFSET ds_access_section
    EnterNewReadSection
;    
	dec ds:ds_usage
	mov al,es:[edi]
	or al,al
	je get_file_attrib_dir

get_file_attrib_file:
	call ParseFile
	jc get_file_attrib_fail
;
	movzx cx,fs:[edx].de_attrib
	jmp get_file_attrib_ok

get_file_attrib_dir:
	mov edx,ds:ds_handle
	or edx,edx
	jz get_file_attrib_root
;
	movzx cx,fs:[edx].de_attrib
	jmp get_file_attrib_ok

get_file_attrib_root:
	mov cx,FILE_ATTRIB_DIR
	jmp get_file_attrib_ok

get_file_attrib_fail:
    mov esi,OFFSET ds_access_section
    LeaveNewReadSection
	call ParseEnd
	stc
	jmp get_file_attrib_done

get_file_attrib_ok:
    mov esi,OFFSET ds_access_section
    LeaveNewReadSection
	call ParseEnd
	clc

get_file_attrib_done:
	pop edi
	pop esi
	pop edx
	pop ax
	pop fs
	pop es
	pop ds
	ret
GetFileAttribBase	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetFileAttribBase
;
;		DESCRIPTION:	Set file attributes
;
;		PARAMETERS:		ES:EDI		FILENAME
;						CX			FILE ATTRIBUTE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetFileAttribBase	Proc near
	push ds
	push es
	push fs
	push ax
	push edx
	push esi
	push edi
;
	mov ax,flat_sel
	mov fs,ax
;
	call ParseDir
	jc set_file_attrib_done
;
    mov esi,OFFSET ds_access_section
    EnterNewWriteSection
;    
	dec ds:ds_usage
	mov al,es:[edi]
	or al,al
	je set_file_attrib_dir

set_file_attrib_file:
	call ParseFile
	jc set_file_attrib_fail
;
	test cl,10h
	jnz set_file_attrib_fail
;
	mov fs:[edx].de_attrib,cl
	mov al,ds:ds_drive
	CallFileSystem update_file_proc
	jmp set_file_attrib_ok

set_file_attrib_dir:
	mov edx,ds:ds_handle
	test cl,10h
	jz set_file_attrib_fail
;
	mov fs:[edx].de_attrib,cl
	mov al,ds:ds_drive
	CallFileSystem update_dir_proc
	jmp set_file_attrib_ok

set_file_attrib_fail:
    mov esi,OFFSET ds_access_section
    LeaveNewWriteSection
	call ParseEnd
	stc
	jmp set_file_attrib_done

set_file_attrib_ok:
    mov esi,OFFSET ds_access_section
    LeaveNewWriteSection
	call ParseEnd
	clc

set_file_attrib_done:
	pop edi
	pop esi
	pop edx
	pop ax
	pop fs
	pop es
	pop ds
	ret
SetFileAttribBase	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DeleteFilePhysical
;
;		DESCRIPTION:	Delete file in physical file system
;
;		PARAMETERS:		EDX			Dir entry
;						DS			Directory selector
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteFilePhysical	Proc near
	push ds
	push ax
	push bx
	push ecx
;
	mov al,ds:ds_drive
	mov bx,fs:[edx].dfe_file_sel
	or bx,bx
	jnz delete_file_phys_opened
;
	mov ah,fs:[edx].de_attrib
	mov ecx,fs:[edx].dfe_data_size
	call CreateFileSel
	mov fs:[edx].dfe_file_sel,bx

delete_file_phys_opened:
	push edx
	xor edx,edx
	CallFileSystem set_file_size_proc
	pop edx
;
	push bx
	mov bx,ds
	CallFileSystem delete_file_proc
	pop bx
;
	mov ds,bx
	call FreeFileSel
;
	pop ecx
	pop bx
	pop ax
	pop ds
	ret
DeleteFilePhysical	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DeleteFileBase
;
;		DESCRIPTION:	Delete file
;
;		PARAMETERS:		ES:EDI		FILE NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteFileBase	Proc near
	push ds
	push es
	push fs
	push eax
	push edx
	push esi
	push edi
;
	mov ax,flat_sel
	mov fs,ax
;
	call ParseDir
	jc delete_file_done
;
    mov esi,OFFSET ds_access_section
    EnterNewWriteSection
;
	dec ds:ds_usage
	mov al,es:[edi]
	or al,al
	je delete_file_fail
;
	call ParseFile
	jc delete_file_fail
;
	mov ax,fs:[edx].de_usage
	or ax,ax
	jnz delete_file_fail
;
	push ebx
	mov eax,fs:[edx].de_next
	mov ebx,fs:[edx].de_prev
	mov fs:[ebx].de_next,eax
	mov fs:[eax].de_prev,ebx
	pop ebx
	cmp eax,edx
	jne delete_file_unlink
;
	mov ds:ds_file_ptr,0
	jmp delete_file_leave

delete_file_unlink:
	cmp edx,ds:ds_file_ptr
	jne delete_file_leave
;
	mov ds:ds_file_ptr,eax

delete_file_leave:
    mov esi,OFFSET ds_access_section
    LeaveNewWriteSection
	call ParseEnd
;
	call DeleteFilePhysical
	jmp delete_file_done

delete_file_fail:
    mov esi,OFFSET ds_access_section
    LeaveNewWriteSection
	call ParseEnd
	stc

delete_file_done:
	pop edi
	pop esi
	pop edx
	pop eax
	pop fs
	pop es
	pop ds
	ret
DeleteFileBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenDirBase
;
;		DESCRIPTION:	Open a directory
;
;		PARAMETERS:		ES:EDI		Pathname
;
;		RETURNS:		BX			FILE HANDLE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenDirBase	Proc near
	push ds
	push es
	push esi
	push edi
;
	call ParseDir
	jc open_dir_done
;
    mov esi,OFFSET ds_access_section
    EnterNewReadSection
;
	dec ds:ds_usage
	mov al,es:[edi]
	or al,al
	je open_dir_do
;
    mov esi,OFFSET ds_access_section
    LeaveNewReadSection
	call ParseEnd
	stc
	jmp open_dir_done

open_dir_do:
	push fs
	mov ax,flat_sel
	mov fs,ax
	call SearchDir
	mov al,ds:ds_drive
	call CreateDirHandle
;	
    mov esi,OFFSET ds_access_section
    LeaveNewReadSection
	call ParseEnd
	pop fs
	clc

open_dir_done:
	pop edi
	pop esi
	pop es
	pop ds
	ret
OpenDirBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadDirBase
;
;		DESCRIPTION:	Retrieves a directory entry
;
;		PARAMETERS:		BX			HANDLE TO DIR
;						DX			ENTRY #
;						CX			MAX SIZE OF FILENAME
;						ES:EDI		BUFFER
;
;		RETURNS:		ECX			FILE SIZE
;						BX			FILE ATTRIBUTE
;						EDX:EAX		FILE TIME/DATE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadDirBase	Proc near
	push ds
	push fs
	push esi
;
	mov ax,DIR_HANDLE
	DerefHandle
	jc read_dir_fail
;
	mov bx,[bx].dir_handle_sel
	or bx,bx
	jz read_dir_fail
;
	mov ds,bx
	mov al,ds:dhs_drive
	mov si,fs_data_sel
	mov fs,si
	movzx si,al
	add si,si
	mov si,fs:[si].fs_sel
	or si,si
	jz read_dir_fail
;
	mov fs,si
	mov esi,fs:fs_mount_id
	cmp esi,ds:dhs_mount_id
	jne read_dir_fail
;
	mov ax,flat_sel
	mov fs,ax
	mov bx,dx
	cmp bx,ds:dhs_count
	jnc read_dir_fail
;
	shl bx,2
	add bx,OFFSET dhs_data
	mov esi,[bx]
	mov ax,fs:[esi].de_name_size
	cmp ax,cx
	jnc read_dir_size_ok
;
	mov cx,ax

read_dir_size_ok:
	movzx ecx,cx
	push esi
	push edi
	mov esi,fs:[esi].de_name
	rep movs byte ptr es:[edi],fs:[esi]
	xor al,al
	stos byte ptr es:[edi]
	pop edi
	pop esi
	mov edx,fs:[esi].de_time+4
	mov eax,fs:[esi].de_time
	movzx bx,fs:[esi].de_attrib
	and bx,7Fh
	test bl,10h
	jz read_dir_file
;
	xor ecx,ecx
	clc
	jmp read_dir_done

read_dir_file:
	mov ecx,fs:[esi].dfe_data_size
	clc	
	jmp read_dir_done

read_dir_fail:
	stc

read_dir_done:
	pop esi
	pop fs
	pop ds
	ret
ReadDirBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CloseDirBase
;
;		DESCRIPTION:	Close a directory
;
;		PARAMETERS:		BX			Dir search sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseDirBase	Proc near
	push es
	push fs
	push ax
	push bx
	push cx
	push edx
	push ebp
;
	mov ebp,-1
	mov es,bx
	mov al,es:dhs_drive
	mov bx,fs_data_sel
	mov fs,bx
	movzx bx,al
	add bx,bx
	mov bx,fs:[bx].fs_sel
	or bx,bx
	jz close_dir_do
;
	mov fs,bx
	mov ebp,fs:fs_mount_id

close_dir_do:
	mov ax,flat_sel
	mov fs,ax
	mov cx,es:dhs_count
	or cx,cx
	jz close_dir_unlock_free
;
	mov bx,OFFSET dhs_data

close_dir_unlock_loop:
	mov edx,es:[bx]
	sub fs:[edx].de_usage,1
	jnz close_dir_next
;
	cmp ebp,es:dhs_mount_id
	je close_dir_next
;
	int 3
;	FreeMem

close_dir_next:
	add bx,4
	loop close_dir_unlock_loop

close_dir_unlock_free:
	FreeMem
;
	pop ebp
	pop edx	
	pop cx
	pop bx
	pop ax
	pop fs
	pop es
	ret
CloseDirBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetupFileSel
;
;		DESCRIPTION:	Setup file selector
;
;		PARAMETERS:		DS		Dir
;						EDX		Dir file entry
;
;		RETURNS:		BX		File sel
;						AL		Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupFileSel	Proc near
	push ecx
	push esi
;
	mov al,ds:ds_drive
	mov esi,OFFSET ds_list_section
	EnterSection
;	
	mov bx,fs:[edx].dfe_file_sel
	or bx,bx
	jnz setup_file_sel_leave
;
	mov ah,fs:[edx].de_attrib
	mov ecx,fs:[edx].dfe_data_size
	call CreateFileSel
	mov fs:[edx].dfe_file_sel,bx

setup_file_sel_leave:
    mov esi,OFFSET ds_list_section
    LeaveSection
;
    pop esi
	pop ecx
	ret
SetupFileSel	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenFileBase
;
;		DESCRIPTION:	Open a file
;
;		PARAMETERS:		ES:EDI		Pathname
;
;		RETURNS:		BX			FILE HANDLE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenFileBase	Proc near
	push ds
	push fs
	push ax
	push edx
	push esi
;
	mov bx,flat_sel
	mov fs,bx
;
	push edi
	call GetDeviceRoot
	call ParseFile
	pop edi
	jc open_file_normal
;
    mov esi,OFFSET ds_access_section
    EnterNewReadSection
;
	call SetupFileSel
;	
    mov esi,OFFSET ds_access_section
    LeaveNewReadSection
	jmp open_file_handle

open_file_normal:
	call ParseEnd
	push edi
	call ParseDir
	jc open_file_pop_failed
;
    mov esi,OFFSET ds_access_section
    EnterNewReadSection
;    
	dec ds:ds_usage
	call ParseFile
	jc open_file_leave_failed
;
	pop edi
	call SetupFileSel
;
    mov esi,OFFSET ds_access_section
    LeaveNewReadSection

open_file_handle:
	call CreateFileHandle
	call ParseEnd
	clc
	jmp open_file_done

open_file_leave_failed:
    mov esi,OFFSET ds_access_section
    LeaveNewReadSection
	call ParseEnd

open_file_pop_failed:
	pop edi
	stc

open_file_done:
    pop esi
	pop edx
	pop ax
	pop fs
	pop ds
	ret
OpenFileBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateFileBase
;
;		DESCRIPTION:	Create a file
;
;		PARAMETERS:		ES:EDI		Pathname
;						CX			Attribute
;
;		RETURNS:		BX			FILE HANDLE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateFileBase	Proc near
	push ds
	push fs
	push ax
	push edx
	push esi
;
	mov bx,flat_sel
	mov fs,bx
;
	push edi
	call GetDeviceRoot
	call ParseFile
	pop edi
	jc create_file_normal
;
    mov esi,OFFSET ds_access_section
    EnterNewReadSection
;    
	call SetupFileSel
;	
    mov esi,OFFSET ds_access_section
    LeaveNewReadSection
	jmp create_file_handle

create_file_normal:
	call ParseEnd
	push edi
	call ParseDir
	jc create_file_pop_failed
;
    mov esi,OFFSET ds_access_section
    EnterNewReadSection
;    
	dec ds:ds_usage
	call ParseFile
	jnc create_file_truncate
;
	call ParseName
	jc create_file_leave_failed
;
	mov al,ds:ds_drive
	mov bx,ds
	CallFileSystem create_file_proc
	call SetupFileSel
;	
    mov esi,OFFSET ds_access_section
    LeaveNewReadSection
	pop edi
	jmp create_file_handle

create_file_truncate:
	pop edi
	call SetupFileSel
	push edx
	xor edx,edx
	CallFileSystem set_file_size_proc
	pop edx
;
    mov esi,OFFSET ds_access_section
    LeaveNewReadSection

create_file_handle:
	call CreateFileHandle
	call ParseEnd
	clc
	jmp create_file_done

create_file_leave_failed:
    mov esi,OFFSET ds_access_section
    LeaveNewReadSection
	call ParseEnd

create_file_pop_failed:
	pop edi
	stc

create_file_done:
    pop esi
	pop edx
	pop ax
	pop fs
	pop ds
	ret
CreateFileBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_DRIVE_INFO
;
;		DESCRIPTION:	Get drive info
;
;		PARAMETERS:		AL			DRIVE NR
;
;		RETURNS:		EAX			Free units
;						CX			Bytes per unit
;						EDX			Total # of units
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_drive_info_name	DB 'Get Drive Info',0

get_drive_info:
	call ValidateDrive
	jc get_drive_info_done
;
	CallFileSystem info_proc
	jc get_drive_info_done
;

get_drive_info_done:
	retf32

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_CUR_DRIVE
;
;		DESCRIPTION:	Set current drive
;
;		PARAMETERS:		AL			DRIVE NR
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cur_drive_name	DB 'Set Current Drive',0

set_cur_drive:
	push ds
	push si
	mov si,fs_process_sel
	mov ds,si
	call ValidateDrive
	jc set_cur_drive_done
;
	mov ds:curr_drive,al

set_cur_drive_done:
	pop si
	pop ds
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_CUR_DRIVE
;
;		DESCRIPTION:	Get current drive
;
;		PARAMETERS:		AL			DRIVE NR. 0 = DEFAULT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cur_drive_name	DB 'Get Current Drive',0

get_cur_drive:
	push ds
	push si
	mov si,fs_process_sel
	mov ds,si
	mov al,ds:curr_drive
	clc
	pop si
	pop ds
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_CUR_DIR
;
;		DESCRIPTION:	Set current directory
;
;		PARAMETERS:		ES:E(DI)	PATH NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cur_dir_name	DB 'Set Current Directory',0

set_cur_dir32:
	call SetCurDirBase
	retf32

set_cur_dir16	PROC far
	push edi
	movzx edi,di
	call SetCurDirBase
	pop edi
	ret
set_cur_dir16	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_CUR_DIR
;
;		DESCRIPTION:	Get current directory
;
;		PARAMETERS:		ES:E(DI)	PATH NAME
;						AL			DRIVE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cur_dir_name	DB 'Get Current Directory',0

get_cur_dir32:
	call GetCurDirBase
	retf32

get_cur_dir16	PROC far
	push edi
	movzx edi,di
	call GetCurDirBase
	pop edi
	ret
get_cur_dir16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MAKE_DIR
;
;		DESCRIPTION:	Create directory
;
;		PARAMETERS:		ES:(E)DI	DIRECTORY NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

make_dir_name	DB 'Make Directory',0

make_dir32:
	call CreateDirBase
	retf32

make_dir16	PROC far
	push edi
	movzx edi,di
	call CreateDirBase
	pop edi
	ret
make_dir16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REMOVE_DIR
;
;		DESCRIPTION:	Remove directory
;
;		PARAMETERS:		ES:(E)DI	DIRECTORY NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_dir_name	DB 'Remove Directory',0

remove_dir32:
	call DeleteDirBase
	retf32

remove_dir16	PROC far
	push edi
	movzx edi,di
	call DeleteDirBase
	pop edi
	ret
remove_dir16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_FILE_ATTRIBUTE
;
;		DESCRIPTION:	Get file attributes
;
;		PARAMETERS:		ES:(E)DI	FILENAME
;
;		RETURNS:		CX			FILE ATTRIBUTE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
get_file_attribute_name	DB 'Get File Attribute',0

get_file_attrib32:
	call GetFileAttribBase
	retf32

get_file_attrib16	PROC far
	push edi
	movzx edi,di
	call GetFileAttribBase
	pop edi
	ret
get_file_attrib16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_FILE_ATTRIBUTE
;
;		DESCRIPTION:	Set file attributes
;
;		PARAMETERS:		ES:(E)DI	FILENAME
;						CX			FILE ATTRIBUTE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
set_file_attribute_name	DB 'Set File Attribute',0

set_file_attrib32:
	call SetFileAttribBase
	retf32

set_file_attrib16	PROC far
	push edi
	movzx edi,di
	call SetFileAttribBase
	pop edi
	ret
set_file_attrib16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DELETE_FILE
;
;		DESCRIPTION:	Delete file
;
;		PARAMETERS:		ES:(E)DI	FILE NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_file_name	DB 'Delete File',0

delete_file32:
	call DeleteFileBase
	retf32

delete_file16	PROC far
	push edi
	movzx edi,di
	call DeleteFileBase
	pop edi
	ret
delete_file16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_DIR
;
;		DESCRIPTION:	Opens a directory
;
;		PARAMETERS:		ES:(E)DI	PATH NAME
;						NC			SUCCESS
;
;		RETURNS:		BX			HANDLE TO DIR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_dir_name	DB 'Open Directory',0

open_dir32:
	call OpenDirBase
	retf32

open_dir16	PROC far
	push edi
	movzx edi,di
	call OpenDirBase
	pop edi
	ret
open_dir16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			READ_DIR
;
;		DESCRIPTION:	Retrieves a directory entry
;
;		PARAMETERS:		BX			HANDLE TO DIR
;						DX			ENTRY #
;						CX			MAX SIZE OF FILENAME
;						ES:(E)DI	BUFFER
;
;		RETURNS:		ECX			FILE SIZE
;						BX			FILE ATTRIBUTE
;						EDX:EAX		FILE TIME/DATE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_dir_name	DB 'Read Directory',0

read_dir32:
	call ReadDirBase
	retf32

read_dir16	PROC far
	push edi
	movzx edi,di
	call ReadDirBase
	pop edi
	ret
read_dir16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CLOSE_DIR
;
;		DESCRIPTION:	Close a directory
;
;		PARAMETERS:		BX			HANDLE TO DIR
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_dir_name	DB 'Close Directory',0

close_dir	Proc far
	push ds
	push ax
	push bx
	push si
;
	mov ax,DIR_HANDLE
	DerefHandle
	jc close_dir_done
;
	mov si,bx
	mov bx,[bx].dir_handle_sel
	or bx,bx
	stc
	jz close_dir_done
;
	call CloseDirBase
	mov bx,si
	FreeHandle
	clc

close_dir_done:
	pop si
	pop bx
	pop ax
	pop ds
	retf32
close_dir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_FILE
;
;		DESCRIPTION:	Open file
;
;		PARAMETERS:		ES:(E)DI	FILENAME
;						CL			ACCESS CODE
;						
;		RETURNS:		BX			FILE HANDLE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_file_name	DB 'Open File',0

open_file32:
	call OpenFileBase
	retf32

open_file16	PROC far
	push edi
	movzx edi,di
	call OpenFileBase
	pop edi
	ret
open_file16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_FILE
;
;		DESCRIPTION:	Create file
;
;		PARAMETERS:		ES:(E)DI	FILENAME
;						CX			ATTRIBUTE
;
;		RETURNS:		BX			FILE HANDLE
;						NC			SUCCESS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_file_name	DB 'Create File',0

create_file32_done:
	pop edi
	pop ds

create_file32:
	call CreateFileBase
	retf32

create_file16	PROC far
	push edi
	movzx edi,di
	call CreateFileBase
	pop edi
	ret
create_file16	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IsFlushable
;
;		DESCRIPTION:	Check if directory is flushable
;
;		PARAMETERS:		BX		Dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsFlushable	Proc near
	mov fs,bx

isflush_dir_list_loop:
	mov edi,fs:ds_dir_ptr
	or edi,edi
	jz isflush_dir_list_done

isflush_dir_list_check:
	mov bx,es:[edi].de_sel
	or bx,bx
	jz isflush_dir_list_next
;
	push fs
	push edi
	call IsFlushable
	pop edi
	pop fs
	jc isflush_dir_done

isflush_dir_list_next:
	mov edi,es:[edi].de_next
	cmp edi,fs:ds_dir_ptr
	jne isflush_dir_list_check

isflush_dir_list_done:
	mov edi,fs:ds_file_ptr
	or edi,edi
	jz isflush_file_list_done

isflush_file_list_check:
	mov bx,es:[edi].dfe_file_sel
	or bx,bx
	jz isflush_file_list_next
;
	call FreeFile
	jc isflush_dir_done
;
	mov es:[edi].dfe_file_sel,0

isflush_file_list_next:
	mov edi,es:[edi].de_next
	cmp edi,fs:ds_file_ptr
	jne isflush_file_list_check

isflush_file_list_done:
	clc

isflush_dir_done:
	ret
IsFlushable	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Flush
;
;		DESCRIPTION:	Flush directory
;
;		PARAMETERS:		BX		Dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Flush	Proc near
	mov fs,bx

flush_dir_list_loop:
	mov edi,fs:ds_dir_ptr
	or edi,edi
	jz flush_dir_list_done

flush_dir_list_check:
	mov bx,es:[edi].de_sel
	or bx,bx
	jz flush_dir_list_next
;
	push fs
	push edi
	call Flush
	pop edi
	pop fs
	mov es:[edi].de_sel,0

flush_dir_list_next:
	mov edi,es:[edi].de_next
	cmp edi,fs:ds_dir_ptr
	jne flush_dir_list_check

flush_dir_list_done:
	mov bx,fs
	xor di,di
	mov fs,di
	call FreeDir

flush_dir_done:
	ret
Flush	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			STOP_FILE_SYSTEM
;
;		DESCRIPTION:	Stop file system
;
;		PARAMETERS:		AL			DRIVE NR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_file_system_name	DB 'Stop File System',0

stop_file_system	Proc far
	push ds
	push es
	push fs
	pushad
;
	mov bx,fs_data_sel
	mov ds,bx
	mov bx,flat_sel
	mov es,bx
	cli
	mov al,ds:fs_access_parse
	or al,al
	jz stop_file_enter
;
	sti
	stc
	jmp stop_done

stop_file_enter:
	mov esi,OFFSET fs_access_section
    EnterNewWriteSection
;
	CallFileSystem flush_proc
	jc stop_leave_done
;
	movzx si,al
	add si,si
	mov bx,ds:[si].fs_sel
	or bx,bx
	clc
	jz stop_leave_done
;
	push ds
	mov ds,bx
	mov bx,ds:fs_root_dir_sel
	or bx,bx
	clc
	jz stop_leave_pop_done
;
	int 3
	push bx
	call IsFlushable
	pop bx
	jc stop_leave_pop_done
;
	call Flush
	mov ds:fs_root_dir_sel,0
	inc ds:fs_mount_id
	clc

stop_leave_pop_done:
	pop ds

stop_leave_done:
	mov esi,OFFSET fs_access_section
    LeaveNewWriteSection
	
stop_done:
	popad
	pop fs
	pop es
	pop ds
	ret
stop_file_system	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Delete handle
;
;		DESCRIPTION:	Delete a handle (called from handle module)
;
;		PARAMETERS:		BX			HANDLE TO DIR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	push ds
	push ax
	push bx
	push si
;
	mov ax,DIR_HANDLE
	DerefHandle
	jc delete_handle_done
;
	mov si,bx
	mov bx,[bx].dir_handle_sel
	or bx,bx
	stc
	jz delete_handle_done
;
	call CloseDirBase
	mov bx,si
	FreeHandle
	clc

delete_handle_done:
	pop si
	pop bx
	pop ax
	pop ds
	ret
delete_handle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init process
;
;		DESCRIPTION:	Init per-process data
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_dir_process

init_dir_process	PROC near
	mov ax,fs_process_sel
	mov es,ax
	mov di,OFFSET cur_dir_sel
	mov cx,256
	xor ax,ax
	rep stosw
	ret
init_dir_process	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Init
;
;		DESCRIPTION:	Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_dir

init_dir	PROC near
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET delete_handle
	mov ax,DIR_HANDLE
	RegisterHandle
;
	mov si,OFFSET stop_file_system
	mov di,OFFSET stop_file_system_name
	mov ax,stop_file_system_nr
	RegisterOsGate
;
	mov si,OFFSET cache_dir
	mov di,OFFSET cache_dir_name
	xor cl,cl
	mov ax,cache_dir_nr
	RegisterOsGate
;
	mov si,OFFSET insert_dir_entry
	mov di,OFFSET insert_dir_entry_name
	xor cl,cl
	mov ax,insert_dir_entry_nr
	RegisterOsGate
;
	mov si,OFFSET insert_file_entry
	mov di,OFFSET insert_file_entry_name
	xor cl,cl
	mov ax,insert_file_entry_nr
	RegisterOsGate
;
	mov si,OFFSET get_drive_info
	mov di,OFFSET get_drive_info_name
	xor dx,dx
	mov ax,get_drive_info_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_cur_drive
	mov di,OFFSET set_cur_drive_name
	xor dx,dx
	mov ax,set_cur_drive_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_cur_drive
	mov di,OFFSET get_cur_drive_name
	xor dx,dx
	mov ax,get_cur_drive_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET set_cur_dir16
	mov si,OFFSET set_cur_dir32
	mov di,OFFSET set_cur_dir_name
	mov dx,virt_es_in
	mov ax,set_cur_dir_nr
	RegisterUserGate
;
	mov bx,OFFSET get_cur_dir16
	mov si,OFFSET get_cur_dir32
	mov di,OFFSET get_cur_dir_name
	mov dx,virt_es_in
	mov ax,get_cur_dir_nr
	RegisterUserGate
;
	mov bx,OFFSET make_dir16
	mov si,OFFSET make_dir32
	mov di,OFFSET make_dir_name
	mov dx,virt_es_in
	mov ax,make_dir_nr
	RegisterUserGate
;
	mov bx,OFFSET remove_dir16
	mov si,OFFSET remove_dir32
	mov di,OFFSET remove_dir_name
	mov dx,virt_es_in
	mov ax,remove_dir_nr
	RegisterUserGate
;
	mov bx,OFFSET get_file_attrib16
	mov si,OFFSET get_file_attrib32
	mov di,OFFSET get_file_attribute_name
	mov dx,virt_es_in
	mov ax,get_file_attribute_nr
	RegisterUserGate
;
	mov bx,OFFSET set_file_attrib16
	mov si,OFFSET set_file_attrib32
	mov di,OFFSET set_file_attribute_name
	mov dx,virt_es_in
	mov ax,set_file_attribute_nr
	RegisterUserGate
;
	mov bx,OFFSET delete_file16
	mov si,OFFSET delete_file32
	mov di,OFFSET delete_file_name
	mov dx,virt_es_in
	mov ax,delete_file_nr
	RegisterUserGate
;
	mov bx,OFFSET open_dir16
	mov si,OFFSET open_dir32
	mov di,OFFSET open_dir_name
	mov dx,virt_es_in
	mov ax,open_dir_nr
	RegisterUserGate
;
	mov bx,OFFSET read_dir16
	mov si,OFFSET read_dir32
	mov di,OFFSET read_dir_name
	mov dx,virt_es_in
	mov ax,read_dir_nr
	RegisterUserGate
;
	mov si,OFFSET close_dir
	mov di,OFFSET close_dir_name
	xor dx,dx
	mov ax,close_dir_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET open_file16
	mov si,OFFSET open_file32
	mov di,OFFSET open_file_name
	mov dx,virt_es_in
	mov ax,open_file_nr
	RegisterUserGate
;
	mov bx,OFFSET create_file16
	mov si,OFFSET create_file32
	mov di,OFFSET create_file_name
	mov dx,virt_es_in
	mov ax,create_file_nr
	RegisterUserGate
;
	ret
init_dir	ENDP

code	ENDS

	END
