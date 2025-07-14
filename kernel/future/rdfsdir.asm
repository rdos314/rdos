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
; RDFSDIR.ASM
; RDFS (RDOS File System) directory support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE rdfs.inc

	extrn decrypt:near

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CACHE_DIR
;
;		DESCRIPTION:	Cache directory structure
;
;		PARAMETERS:		EDX			Dir entry to cache or 0
;						BX			Cached dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public cache_dir

cache_dir	Proc far
	pushad
	or edx,edx
	jnz cache_dir_subdir
;
	int 3
	mov ax,flat_sel
	mov es,ax
	mov al,ds:drive_nr
	mov edx,ds:ri_root_dir
	LockSector
	mov eax,es:[esi].rc_size
	add eax,eax
	and ax,0F000h
	add eax,1000h
	AllocateBigLinear
	push edx
	mov ecx,es:[esi].rc_size
	mov edx,es:[esi].rc_sector_arr
	mov bp,es:[esi].rc_key_offset
	UnlockSector
	pop esi
;
	shr ecx,8
	mov eax,ecx
	shl eax,2
	AllocateSmallMem
	xor edi,edi
	push ecx
	mov al,ds:drive_nr

req_dir_loop:
	ReqSector
	mov es:[edi],ebx
	inc edx
	add edi,4
	add esi,200h
	sub ecx,1
	jnz req_dir_loop
;
	pop ecx
;
	sub edi,4

wait_dir_loop:
	mov ebx,es:[edi]
	WaitForSector
	sub edi,4
	sub ecx,1
	jnz wait_dir_loop
;
	FreeMem
;
	mov ax,flat_sel
	mov es,ax
	mov edi,esi
	mov cx,es:[esi]
	call decrypt
	xor ah,es:[edi]
	xor ah,es:[edi+1]
	mov word ptr es:[edi],0
	cmp cl,ah
	jne cache_dir_free_fail
;
	not ah
	cmp ch,ah
	jne cache_dir_free_fail
;
	mov esi,8
;	
	mov eax,dword ptr es:[esi+edi].rdss_dir_list
	cmp eax,-1
	je cache_dir_dir_done
;
	int 3

cache_dir_dir_done:
	mov eax,dword ptr es:[esi+edi].rdss_dir_list
	cmp eax,-1
	je cache_dir_file_done
;
	int 3

cache_dir_file_done:
	clc
	jmp cache_dir_done

cache_dir_free_fail:
	mov edx,edi
	xor ecx,ecx
	FreeLinear
	jmp cache_dir_fail

cache_dir_subdir:

cache_dir_fail:
	int 3
	stc

cache_dir_done:
	popad
	ret
cache_dir	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_DIR
;
;		DESCRIPTION:	Create directory
;
;		PARAMETERS:		ES:EDI		DIRECTORY NAME
;						BX			DIR SELECTOR
;	
;		RETURNS:		EDX			DIR ENTRY
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public create_dir

create_dir	PROC far
	int 3
	stc
	ret
create_dir	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DELETE_DIR
;
;		DESCRIPTION:	Delete directory
;
;		PARAMETERS:		BX			DIR SELECTOR
;						EDX			DIR ENTRY TO DELETE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public delete_dir

delete_dir	PROC far
	int 3
	stc
delete_dir	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DELETE_FILE
;
;		DESCRIPTION:	Delete file
;
;		PARAMETERS:		BX			DIR SELECTOR
;						EDX			FILE ENTRY TO DELETE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public delete_file

delete_file	PROC far
	int 3
	stc
	ret
delete_file	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RENAME_FILE
;
;		DESCRIPTION:	Rename file
;
;		PARAMETERS:		FS:EBX		CURRENT NAME
;						ES:EDI		NEW NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public rename_file

rename_file	PROC far
	int 3
	stc
	ret
rename_file	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_FILE
;
;		DESCRIPTION:	Create a file
;
;		PARAMETERS:		ES:EDI		Filename
;						BX			Dir
;						CX			Attribute
;
;		RETURNS:		EDX			Dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public create_file

create_file	PROC far
	int 3
	stc
	ret
create_file	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			update_dir
;
;		DESCRIPTION:	Update dir entry
;
;		PARAMETERS:		EDX			Dir dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public update_dir

update_dir	PROC far
	int 3
	stc
	ret
update_dir	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			update_file_entry
;
;		DESCRIPTION:	Update file entry
;
;		PARAMETERS:		EDX			Dir file entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public update_file

update_file	PROC far
	int 3
	stc
	ret
update_file	ENDP

code	ENDS

	END
