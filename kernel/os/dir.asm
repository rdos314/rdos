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

INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE system.def
INCLUDE protseg.def
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc
INCLUDE user.inc
INCLUDE driver.def
INCLUDE system.inc
INCLUDE fs.inc

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

dir_to_offset	MACRO reg
	shl reg,1
	add reg,OFFSET dir_list	
					ENDM

offset_to_dir	MACRO reg
	sub reg,OFFSET dir_list
	shr reg,1
					ENDM

allocate_dir	MACRO
	push ax
	cli
	mov bx,ds:dir_free_list
	mov ax,[bx]
	mov ds:dir_free_list,ax
	sti
	pop ax
				ENDM

free_dir	MACRO
	push ax
	cli
	mov ax,ds:dir_free_list
	mov [bx],ax
	mov ds:dir_free_list,bx
	sti
	pop ax
			ENDM

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn CreateFileHandle:near
	extrn CreateFileSel:near

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
;		NAME:			CreateDirSelector
;
;		DESCRIPTION:	Create a dir selector
;
;		PARAMETERS:		AL			Drive
;
;		RETURNS:		BX			Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDirSel	PROC near
	push ds
	push es
	push eax
;
	mov bl,al
	mov eax,SIZE dir_sel_data_struc
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
	InitReadWriteSection ds:ds_access_section
	InitSection ds:ds_list_section
	mov ds:ds_dir_ptr,0
	mov ds:ds_file_ptr,0
	mov ds:ds_deleted_ptr,0
	mov ds:ds_free_ptr,0
	mov ds:ds_usage,0
	mov ds:ds_drive,bl
	mov bx,ds
;
	pop eax
	pop es
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
	push es
	push ax
;
	mov ax,ds
	mov es,ax
	xor ax,ax
	mov ds,ax
	FreeMem
;
	pop ax
	pop es
	ret
FreeDirSel	ENDP

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
	push si
	mov si,fs_process_sel
	mov ds,si
	mov si,bx
	allocate_dir
	mov ds:[bx],si
	offset_to_dir bx
	pop si
	pop ds
	ret
CreateDirHandle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UpdateDirEntry
;
;		DESCRIPTION:	Update dir entry
;
;		PARAMETERS:		FS		Flat sel
;						EDX		Dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateDirEntry	Proc near
	ret
UpdateDirEntry	Endp

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
	jc parse_drive_done
;
	cmp bl,26
	jc parse_drive_ok
;
	sub bl,20h
	jc parse_drive_done
;
	cmp bl,26
	jnc parse_drive_done

parse_drive_ok:
	mov al,bl
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
	mov si,fs_data_sel
	mov ds,si
	movzx si,al
	add si,si
	mov ds,ds:[si].fs_sel
	EnterReadSection ds:fs_access_section
	jmp parse_dir_start

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
	EnterSection ds:fs_list_section
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
	mov dx,fs_process_sel
	mov ds,dx
	mov ds:[si].cur_dir_sel,bx
	pop ds

parse_dir_buffered:
	EnterReadSection ds:fs_access_section
	LeaveSection ds:fs_list_section

parse_dir_start:
	mov ds,bx
	mov bx,flat_sel
	mov fs,bx
	EnterReadSection ds:ds_access_section

parse_dir_tree_loop:
	mov bx,OFFSET char_tab
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

parse_dir_next:
	pop edi
	pop esi
	mov esi,fs:[esi].de_next
	cmp esi,ds:ds_dir_ptr
	jne parse_dir_entry_loop
	jmp parse_dir_ok

parse_dir_tree_next:
	pop esi
	pop esi
	EnterSection ds:ds_list_section
	mov bx,fs:[esi].de_sel
	or bx,bx
	jz parse_dir_tree_cached
;
	mov edx,esi
	call CreateDirSel
	CallFileSystem cache_dir_proc

parse_dir_tree_cached:
	LeaveSection ds:ds_list_section
	mov ax,ds
	mov ds,bx
	EnterReadSection ds:ds_access_section
	mov ds,ax
	LeaveReadSection ds:ds_access_section
	mov ds,bx
	mov al,es:[edi]
	or al,al
	jnz parse_dir_tree_loop

parse_dir_ok:
	inc ds:ds_usage
	LeaveReadSection ds:ds_access_section
	clc
	jmp parse_dir_done

parse_dir_fail:
	stc

parse_dir_done:
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
	push si
;
	movzx si,ds:ds_drive
	add si,si
	mov ax,fs_data_sel
	mov ds,ax
	mov ds,ds:[si].fs_sel
	LeaveReadSection ds:fs_access_section
;
	pop si
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
	push si
;
	mov al,80h
	mov bx,fs_data_sel
	mov ds,bx
	movzx si,al
	add si,si
	mov ds,ds:[si].fs_sel
	EnterReadSection ds:fs_access_section
	EnterSection ds:fs_list_section
	mov bx,ds:fs_root_dir_sel
	or bx,bx
	jnz get_device_root_done
;
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
	LeaveSection ds:fs_list_section
	mov ds,bx
;
	pop si
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
	jmp parse_file_fail

parse_file_next:
	pop edi
	mov edx,fs:[edx].de_next
	cmp edx,ds:ds_file_ptr
	jnz parse_file_entry_loop
;
	xor edx,edx
	stc
	jmp parse_file_done	

parse_file_fail:
	pop edi
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
	add eax,4
	AllocateGlobalMem
	movzx eax,cx
	xor di,di
	stosd
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
;		PARAMETERS:		ES:EDI		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCurDirBase	Proc near
	int 3
	CallFileSystem get_cur_dir_proc
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
	int 3
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
	push dx
	mov bx,fs_process_sel
	mov es,bx
	mov bx,ds
	mov al,ds:ds_drive
	movzx si,al
	add si,si
	mov es:[si].cur_dir_sel,bx
	pop dx
	pop es
	call ParseEnd
	clc
	jmp set_cur_dir_done

set_cur_dir_fail:
	dec ds:ds_usage
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
	push edi
;
	call ParseDir
	jc open_dir_done
;
	EnterReadSection ds:ds_access_section
	dec ds:ds_usage
	mov al,es:[edi]
	or al,al
	je open_dir_do
;
	LeaveReadSection ds:ds_access_section
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
	LeaveReadSection ds:ds_access_section
	call ParseEnd
	pop fs
	clc

open_dir_done:
	pop edi
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
	mov ax,flat_sel
	mov fs,ax
	mov ax,fs_process_sel
	mov ds,ax
	dir_to_offset bx
	mov bx,ds:[bx]
	or bx,bx
	jz read_dir_fail
;
	mov ds,bx
	mov bx,dx
	cmp bx,ds:[0]
	jnc read_dir_fail
;
	shl bx,2
	add bx,4
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
;
	mov ax,flat_sel
	mov fs,ax
	mov es,bx
	mov cx,es:[0]
	mov bx,4

close_dir_unlock_loop:
	mov edx,es:[bx]
	sub fs:[edx].de_usage,1
	jnz close_dir_next
;
	call UpdateDirEntry

close_dir_next:
	add bx,4
	loop close_dir_unlock_loop
;
	FreeMem
;
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
	EnterReadSection ds:ds_access_section
	jmp open_file_do

open_file_normal:
	call ParseEnd
	push edi
	call ParseDir
	jc open_file_pop_failed
;
	EnterReadSection ds:ds_access_section
	dec ds:ds_usage
	call ParseFile
	jc open_file_leave_failed
;
	pop edi

open_file_do:
	mov al,ds:ds_drive
	EnterSection ds:ds_list_section
	mov bx,fs:[edx].dfe_file_sel
	or bx,bx
	jnz open_file_ok
;
	push ecx
	mov ah,fs:[edx].de_attrib
	mov ecx,fs:[edx].dfe_data_size
	call CreateFileSel
	mov fs:[edx].dfe_file_sel,bx
	pop ecx

open_file_ok:
	LeaveSection ds:ds_list_section
	LeaveReadSection ds:ds_access_section
	call CreateFileHandle
	call ParseEnd
	clc
	jmp open_file_done

open_file_leave_failed:
	LeaveReadSection ds:ds_access_section
	call ParseEnd

open_file_pop_failed:
	pop edi
	stc

open_file_done:
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
	mov ds:curr_drive,al
	clc
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
	int 3
	push ds
	push bx
	push si
	mov ax,fs_process_sel
	mov ds,ax
	dir_to_offset bx
	mov si,bx
	mov bx,ds:[bx]
	or bx,bx
	stc
	jz close_dir_done
;
	call CloseDirBase
	mov bx,si
	mov word ptr ds:[bx],0
	free_dir
	clc

close_dir_done:
	pop si
	pop bx
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
;		NAME:			Test pr
;
;		DESCRIPTION:	TEST
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_name	DB 'Test',0

test_pr	PROC far
	int 3
	mov al,19h
	call CreateDirSel
	xor edx,edx
	CallFileSystem cache_dir_proc
	retf32
test_pr	Endp

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
;
	mov cx,dir_num
	mov di,2*dir_num + OFFSET dir_list
init_dir_tab_loop:
	mov ax,di
	sub di,2
	mov es:[di],ax
	loop init_dir_tab_loop
	mov es:dir_free_list,di
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
	mov si,OFFSET set_cur_drive
	mov di,OFFSET set_cur_drive_name
	xor cl,cl
	mov ax,set_cur_drive_nr
	RegisterUserGate
;
	mov bx,ax
	xor dx,dx
	mov ax,set_virt_cur_drive_nr
	RegisterVirtUserGate
;
	mov si,OFFSET get_cur_drive
	mov di,OFFSET get_cur_drive_name
	xor cl,cl
	mov ax,get_cur_drive_nr
	RegisterUserGate
;
	mov bx,ax
	xor dx,dx
	mov ax,get_virt_cur_drive_nr
	RegisterVirtUserGate
;
	mov si,OFFSET set_cur_dir32
	mov di,OFFSET set_cur_dir_name
	xor cl,cl
	mov ax,set_cur_dir_nr
	RegisterUserGate32
;
	mov si,OFFSET set_cur_dir16
	mov di,OFFSET set_cur_dir_name
	xor cl,cl
	mov ax,set_cur_dir_nr
	RegisterUserGate16
;
	mov bx,ax
	mov dx,virt_es_in
	mov ax,set_virt_cur_dir_nr
	RegisterVirtUserGate
;
	mov si,OFFSET get_cur_dir32
	mov di,OFFSET get_cur_dir_name
	xor cl,cl
	mov ax,get_cur_dir_nr
	RegisterUserGate32
;
	mov si,OFFSET get_cur_dir16
	mov di,OFFSET get_cur_dir_name
	xor cl,cl
	mov ax,get_cur_dir_nr
	RegisterUserGate16
;
	mov bx,ax
	mov dx,virt_es_in
	mov ax,get_virt_cur_dir_nr
	RegisterVirtUserGate
;
	mov si,OFFSET open_dir32
	mov di,OFFSET open_dir_name
	xor cl,cl
	mov ax,open_dir_nr
	RegisterUserGate32
;
	mov si,OFFSET open_dir16
	mov di,OFFSET open_dir_name
	xor cl,cl
	mov ax,open_dir_nr
	RegisterUserGate16
;
	mov bx,ax
	mov dx,virt_es_in
	mov ax,open_virt_dir_nr
	RegisterVirtUserGate
;
	mov si,OFFSET read_dir32
	mov di,OFFSET read_dir_name
	xor cl,cl
	mov ax,read_dir_nr
	RegisterUserGate32
;
	mov si,OFFSET read_dir16
	mov di,OFFSET read_dir_name
	xor cl,cl
	mov ax,read_dir_nr
	RegisterUserGate16
;
	mov bx,ax
	mov dx,virt_es_in
	mov ax,read_virt_dir_nr
	RegisterVirtUserGate
;
	mov si,OFFSET close_dir
	mov di,OFFSET close_dir_name
	xor cl,cl
	mov ax,close_dir_nr
	RegisterUserGate
;
	mov bx,ax
	xor dx,dx
	mov ax,close_virt_dir_nr
	RegisterVirtUserGate
;
	mov si,OFFSET open_file32
	mov di,OFFSET open_file_name
	xor cl,cl
	mov ax,open_file_nr
	RegisterUserGate32
;
	mov si,OFFSET open_file16
	mov di,OFFSET open_file_name
	xor cl,cl
	mov ax,open_file_nr
	RegisterUserGate16
;
	mov bx,ax
	mov dx,virt_es_in
	mov ax,open_virt_file_nr
	RegisterVirtUserGate
;
	mov si,OFFSET test_pr
	mov di,OFFSET test_name
	xor cl,cl
	mov ax,test_nr
	RegisterUserGate
;
	ret
init_dir	ENDP

code	ENDS

	END
