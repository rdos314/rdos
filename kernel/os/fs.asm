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
; FS.ASM
; Basic file system support module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME fs

GateSize = 16

INCLUDE driver.def
INCLUDE protseg.def
INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc
INCLUDE system.def
INCLUDE int.def
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

code	SEGMENT byte public 'CODE'

	.386p

	assume cs:code

	extrn init_file:near
	extrn init_dir:near
	extrn init_memmap:near
	extrn init_file_process:near
	extrn init_dir_process:near
	extrn init_memmap_process:near
	extrn close_file_app:near
	extrn close_memmap_app:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_FILE_SYSTEM
;
;		DESCRIPTION:	Register a file system
;
;		PARAMETERS:		DS:SI		FILE SYSTEM NAME
;						ES:DI		FILE SYSTEM STRUC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_file_system_name	DB 'Register File System',0

register_file_system	Proc far
	push ds
	push ax
	push bx
	push cx
	mov cx,ds
	mov ax,fs_data_sel
	mov ds,ax
	mov al,ds:file_defs
	mov bl,al
	xor bh,bh
	shl bx,3
	add bx,OFFSET file_def_arr
	mov [bx],si
	mov [bx+2],cx
	mov [bx+4],di
	mov [bx+6],es
	inc al
	mov ds:file_defs,al
	pop cx
	pop bx
	pop ax
	pop ds
	ret
register_file_system	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_FILE_SYSTEM
;
;		DESCRIPTION:	Install a file system
;
;		PARAMETERS:		AL			DRIVE #
;						DX			DRIVE UNIT #
;						ES:DI		FILE SYSTEM NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_file_system_name	DB 'Install File System',0

install_file_system	Proc far
	push ds
	push es
	push bx
	push cx
	push si
	push di
;
	mov cx,fs_data_sel
	mov ds,cx
	movzx cx,ds:file_defs
	mov bx,OFFSET file_def_arr
	or cx,cx
	jz install_file_sys_done

install_file_sys_find:
	push ds
	push ax
	push di
	lds si,[bx]
install_file_sys_check:
	lodsb
	or al,al
	jz install_file_sys_ok
	cmp al,es:[di]
	jne install_file_sys_next
	inc di
	jmp install_file_sys_check
install_file_sys_next:
	pop di
	pop ax
	pop ds
	add bx,8
	loop install_file_sys_find
	jmp install_file_sys_done
install_file_sys_ok:
	pop di
	pop ax
	pop ds
	les di,[bx+4]
	movzx bx,al
	add bx,bx
	push ds
	push es
	push eax
	mov si,ds:[bx].fs_sel
	or si,si
	jz init_file_old_freed
;
	CallFileSystem dismount_proc
	mov es,si
	FreeMem

init_file_old_freed:
	mov eax,SIZE fs_drive_seg
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
	pop eax
	pop es
	mov word ptr ds:fs_sys_arr,di
	mov word ptr ds:fs_sys_arr+2,es
	mov dword ptr ds:fs_sys_arr+4,0
	InitSection ds:fs_list_section
	InitReadWriteSection ds:fs_access_section
	mov ds:fs_root_dir_sel,0
	mov si,ds
	pop ds
	mov ds:[bx].fs_sel,si

install_file_sys_done:
	pop di
	pop si
	pop cx
	pop bx
	pop es
	pop ds
	ret
install_file_system	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_FILE_SYSTEM
;
;		DESCRIPTION:	Init file system
;
;		PARAMETERS:		AL			DRIVE NR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_file_system_name	DB 'Init File System',0

init_file_system	Proc far
	push ds
	push es
	push si
	push di
;
	mov si,fs_data_sel
	mov es,si
	movzx di,al
	add di,di
	mov ds,es:[di].fs_sel
	push ds
	lds si,ds:fs_sys_arr
	call ds:[si].mount_proc
	pop es
	mov word ptr es:fs_sys_arr+4,si
	mov word ptr es:fs_sys_arr+6,ds
;
	pop di
	pop si
	pop es
	pop ds
	ret
init_file_system	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_DRIVE_INFO
;
;		DESCRIPTION:	Get drive info
;
;		PARAMETERS:		AL			DRIVE NR
;
;		RETURNS:		EAX			FREE UNITS
;						CX			BYTES / UNIT
;						EDX			TOTAL # OF UNITS
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_drive_info_name	DB 'Get Drive Info',0

get_drive_info:
	CallFileSystem info_proc
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RENAME_FILE
;
;		DESCRIPTION:	Rename file
;
;		PARAMETERS:		DS:(E)SI	CURRENT NAME
;						ES:(E)DI	NEW NAME
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rename_file_name	DB 'Rename File',0

rename_file32:
	int 3
	stc
	retf32

rename_file16	PROC far
	int 3
	stc
	ret
rename_file16	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_PROCESS
;
;		DESCRIPTION:	Init per-process data
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process	PROC far
	push ds
	push es
	pushad
;
	mov ax,fs_process_sel
	mov es,ax
;
	mov es:curr_drive,MAX_DRIVES - 1
;
	call init_dir_process
	call init_file_process
	call init_memmap_process
;
	popad
	pop es
	pop ds
	ret
init_process	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CLOSE_APP
;
;		DESCRIPTION:	Close app
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_app	PROC far
	push ds
	push es
	pushad
;
	call close_file_app
	call close_memmap_app
;
	popad
	pop es
	pop ds
	ret
close_app	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init driver
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_proc	Proc far
	stc
	ret
default_proc	Endp

default_fs:
df00 DW OFFSET default_proc,	fs_code_sel
df01 DW OFFSET default_proc,	fs_code_sel
df02 DW OFFSET default_proc,	fs_code_sel
df03 DW OFFSET default_proc,	fs_code_sel
df04 DW OFFSET default_proc,	fs_code_sel
df05 DW OFFSET default_proc,	fs_code_sel
df06 DW OFFSET default_proc,	fs_code_sel
df07 DW OFFSET default_proc,	fs_code_sel
df08 DW OFFSET default_proc,	fs_code_sel
df09 DW OFFSET default_proc,	fs_code_sel
df0A DW OFFSET default_proc,	fs_code_sel
df0B DW OFFSET default_proc,	fs_code_sel
df0C DW OFFSET default_proc,	fs_code_sel
df0D DW OFFSET default_proc,	fs_code_sel
df0E DW OFFSET default_proc,	fs_code_sel
df0F DW OFFSET default_proc,	fs_code_sel
df10 DW OFFSET default_proc,	fs_code_sel
df11 DW OFFSET default_proc,	fs_code_sel
df12 DW OFFSET default_proc,	fs_code_sel
df13 DW OFFSET default_proc,	fs_code_sel
df14 DW OFFSET default_proc,	fs_code_sel
df15 DW OFFSET default_proc,	fs_code_sel
df16 DW OFFSET default_proc,	fs_code_sel
df17 DW OFFSET default_proc,	fs_code_sel
df18 DW OFFSET default_proc,	fs_code_sel
df19 DW OFFSET default_proc,	fs_code_sel
df1A DW OFFSET default_proc,	fs_code_sel
df1B DW OFFSET default_proc,	fs_code_sel
df1C DW OFFSET default_proc,	fs_code_sel
df1D DW OFFSET default_proc,	fs_code_sel
df1E DW OFFSET default_proc,	fs_code_sel
df1F DW OFFSET default_proc,	fs_code_sel

init	PROC far
	mov bx,fs_code_sel
	InitDevice
;
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET register_file_system
	mov di,OFFSET register_file_system_name
	mov ax,register_file_system_nr
	RegisterOsGate
;
	mov si,OFFSET install_file_system
	mov di,OFFSET install_file_system_name
	mov ax,install_file_system_nr
	RegisterOsGate
;
	mov si,OFFSET init_file_system
	mov di,OFFSET init_file_system_name
	mov ax,init_file_system_nr
	RegisterOsGate
;
	mov si,OFFSET get_drive_info
	mov di,OFFSET get_drive_info_name
	xor cl,cl
	mov ax,get_drive_info_nr
	RegisterUserGate
;
	mov bx,ax
	xor dx,dx
	mov ax,get_virt_drive_info_nr
	RegisterVirtUserGate
;
	mov si,OFFSET rename_file32
	mov di,OFFSET rename_file_name
	xor cl,cl
	mov ax,rename_file_nr
	RegisterUserGate32
;
	mov si,OFFSET rename_file16
	mov di,OFFSET rename_file_name
	xor cl,cl
	mov ax,rename_file_nr
	RegisterUserGate16
;
	mov bx,ax
	mov dx,virt_ds_in OR virt_es_in
	mov ax,rename_virt_file_nr
	RegisterVirtUserGate
;
	mov di,OFFSET init_process
	HookCreateProcess
;
	mov di,OFFSET close_app
	HookCloseApp
;
	mov eax,SIZE fs_process_seg
	mov bx,fs_process_sel
	AllocateFixedProcessMem
;	
	mov eax,SIZE fs_data_seg
	mov bx,fs_data_sel
	AllocateFixedSystemMem
;
	mov es:file_defs,0
;
	mov di,OFFSET fs_sel
	mov cx,256
	xor ax,ax
	rep stosw
;
	call init_dir
	call init_file
	call init_memmap
;	
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init

