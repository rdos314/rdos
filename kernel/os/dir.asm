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
	shl si,3
	lgs bp,ds:[si].file_sys_arr
	lds si,ds:[si].file_sys_arr+4
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
	push si
;
	mov ds,bx
	mov ax,flat_sel
	mov es,ax
;
	mov si,OFFSET ds_file_ptr
	test es:[edx].de_attrib,10h
	jz insert_dir_do
;
	mov si,OFFSET ds_dir_ptr

insert_dir_do:
	mov eax,ds:[si]
	or eax,eax
	jne insert_dir_used

insert_dir_empty:
	mov es:[edx].de_prev,edx
	mov es:[edx].de_next,edx
	mov [si],edx
	jmp insert_dir_done

insert_dir_used:
	mov ebx,es:[eax].de_prev
	mov es:[eax].de_prev,edx
	mov es:[ebx].de_next,edx
	mov es:[edx].de_prev,ebx
	mov es:[edx].de_next,eax	

insert_dir_done:
	pop si
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
	InitReadWriteSection ds:ds_section
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
	mov al,1Ah
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
	mov ax,fs_data_sel
	mov es,ax
	mov di,OFFSET dir_arr
	mov cx,256
	xor eax,eax
	rep stosd
;
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
