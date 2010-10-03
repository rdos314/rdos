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

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE int.def
INCLUDE system.inc
INCLUDE ..\fs.inc

CallFileSystem	MACRO	call_proc
	push ds
	push gs
	push bp
	push si
	mov si,fs_sys_data_sel
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
	extrn init_dir_process:near
	extrn init_memmap_process:near
	extrn init_inifile:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HOOK_INIT_FILE_SYSTEM
;
;		DESCRIPTION:	Hook init file system
;
;		PARAMETERS:		ES:DI		CALLBACK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_init_file_system_name	DB 'Hook Init File System',0

hook_init_file_system	Proc far
	push ds
	push ax
	push bx
	push cx
	mov cx,ds
	mov ax,fs_sys_data_sel
	mov ds,ax
	mov al,ds:fs_init_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET fs_init_hook_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:fs_init_hooks,al
	pop cx
	pop bx
	pop ax
	pop ds
	ret
hook_init_file_system	Endp

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
	mov ax,fs_sys_data_sel
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
;		NAME:			DEFINE_MEDIA_CHECK
;
;		DESCRIPTION:	Define media check procedure for drive
;
;		PARAMETERS:		AL			DRIVE #
;						BX			HANDLE
;						ES:DI		MEDIA CHECK PROC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_media_check_name	DB 'Define Media Check',0

define_media_check	Proc far
	push ds
	push si
;
	mov si,fs_sys_data_sel
	mov ds,si
;
	movzx si,al
	add si,si
	mov ds:[si].media_check_handle,bx
	add si,si
	mov word ptr ds:[si].media_check_proc,di
	mov word ptr ds:[si+2].media_check_proc,es
;
	pop si
	pop ds
	ret
define_media_check	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DEMAND_LOAD_FILE_SYSTEM
;
;		DESCRIPTION:	Set file-system to demand-load mode
;
;		PARAMETERS:		AL			DRIVE #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

demand_load_file_system_name	DB 'Demand Load File System',0

demand_load_file_system	Proc far
	push ds
	push es
	push bx
	push si
;
	mov bx,fs_sys_data_sel
	mov ds,bx
;
	movzx bx,al
	add bx,bx
	mov si,ds:[bx].fs_sel
	or si,si
	jz demand_load_old_freed
;
	cmp si,-1
	je demand_load_old_freed
;
	CallFileSystem dismount_proc
	mov es,si
	FreeMem

demand_load_old_freed:
	mov ds:[bx].fs_sel,-1
;
	pop si
	pop bx
	pop es
	pop ds
	ret
demand_load_file_system	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetFileSystem
;
;		DESCRIPTION:	Get a file system
;
;		PARAMETERS:		ES:DI		FILE SYSTEM NAME
;
;		RETURNS:		ED:DI		FILE SYSTEM CONTROL TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFileSystem	Proc near
	push ds
	push ax
	push bx
	push cx
;
	mov cx,fs_sys_data_sel
	mov ds,cx
	movzx cx,ds:file_defs
	mov bx,OFFSET file_def_arr
	or cx,cx
	jz get_file_sys_fail

get_file_sys_find:
	push ds
	push di
	lds si,[bx]

get_file_sys_check:
	lodsb
	or al,al
	jz get_file_sys_ok
;
	cmp al,es:[di]
	jne get_file_sys_next
;
	inc di
	jmp get_file_sys_check

get_file_sys_next:
	pop di
	pop ds
	add bx,8
	loop get_file_sys_find
;
	jmp get_file_sys_fail

get_file_sys_ok:
	pop di
	pop ds
	les di,[bx+4]
	clc
	jmp get_file_sys_done

get_file_sys_fail:
	stc

get_file_sys_done:
	pop cx
	pop bx
	pop ax
	pop ds
	ret
GetFileSystem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IS_FILE_SYSTEM_AVAILABLE
;
;		DESCRIPTION:	Check if file system is available
;
;		PARAMETERS:		AL			DRIVE #
;						ES:DI		FILE SYSTEM NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_file_system_available_name	DB 'Is File System Available',0

is_file_system_available	Proc far
	push es
	push di
	call GetFileSystem
	pop di
	pop es
	ret
is_file_system_available	Endp

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
	mov cx,fs_sys_data_sel
	mov ds,cx
	call GetFileSystem
	jc install_file_sys_done
;
	movzx bx,al
	add bx,bx
	push ds
	push es
	push eax
	mov si,ds:[bx].fs_sel
	or si,si
	jz init_file_old_freed
;
	cmp si,-1
	je init_file_old_freed
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
;	EnterWriteSection ds:fs_access_section
	mov ds:fs_access_parse,0
	mov ds:fs_root_dir_sel,0
	mov ds:fs_mount_id,1
	mov si,ds
	pop ds
	mov ds:[bx].fs_sel,si
	clc

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
;		NAME:			FORMAT_FILE_SYSTEM
;
;		DESCRIPTION:	Format a file system
;
;		PARAMETERS:		AL			Drive #
;						ECX			Drive size
;						ES:DI		File system name
;                       FS:EDX      Format data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

format_file_system_name	DB 'Format File System',0

format_file_system	Proc far
	push es
	push di
;
	call GetFileSystem
	call es:[di].format_proc
;
	pop di
	pop es
	ret
format_file_system	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			START_FILE_SYSTEM
;
;		DESCRIPTION:	Start file system
;
;		PARAMETERS:		AL			Drive #
;						ECX			Number of sectors to mount
;                       FS:EDX      Mount data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_file_system_name	DB 'Start File System',0

start_file_system	Proc far
	push ds
	push es
	push si
	push di
;
	mov si,fs_sys_data_sel
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
	mov ax,es
	mov ds,ax
;	LeaveWriteSection ds:fs_access_section
;
	pop di
	pop si
	pop es
	pop ds
	ret
start_file_system	Endp

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
	push si
	push di
;
	mov si,fs_sys_data_sel
	mov es,si
;
	pop di
	pop si
	pop es
	pop ds
	ret
stop_file_system	Endp

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
;		NAME:			Hook_thread
;
;		DESCRIPTION:	Run all init file system hooks
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_thread_name DB 'Init File System', 0

hook_thread	PROC far
	mov ax,fs_sys_data_sel
	mov ds,ax
	mov cl,ds:fs_init_hooks
	or cl,cl
	je hook_thread_done
;
	mov bx,OFFSET fs_init_hook_arr
hook_thread_loop:
	push ds
	push bx
	push cx
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
	dec cl
	jnz hook_thread_loop

hook_thread_done:
	mov ds:fs_init_done,1
	LeaveSection ds:fs_init_section
	ret
hook_thread	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_hook_thread
;
;		DESCRIPTION:	Create hook thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_hook_thread	Proc far
	push ds
	push es
	pushad
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET hook_thread
	mov di,OFFSET hook_thread_name
	mov ax,3
	mov cx,256
	CreateThread
;
	popad
	pop es
	pop ds
init_hook_thread	Endp

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
df00 DW OFFSET default_proc,	SEG code
df01 DW OFFSET default_proc,	SEG code
df02 DW OFFSET default_proc,	SEG code
df03 DW OFFSET default_proc,	SEG code
df04 DW OFFSET default_proc,	SEG code
df05 DW OFFSET default_proc,	SEG code
df06 DW OFFSET default_proc,	SEG code
df07 DW OFFSET default_proc,	SEG code
df08 DW OFFSET default_proc,	SEG code
df09 DW OFFSET default_proc,	SEG code
df0A DW OFFSET default_proc,	SEG code
df0B DW OFFSET default_proc,	SEG code
df0C DW OFFSET default_proc,	SEG code
df0D DW OFFSET default_proc,	SEG code
df0E DW OFFSET default_proc,	SEG code
df0F DW OFFSET default_proc,	SEG code
df10 DW OFFSET default_proc,	SEG code
df11 DW OFFSET default_proc,	SEG code
df12 DW OFFSET default_proc,	SEG code
df13 DW OFFSET default_proc,	SEG code
df14 DW OFFSET default_proc,	SEG code
df15 DW OFFSET default_proc,	SEG code
df16 DW OFFSET default_proc,	SEG code
df17 DW OFFSET default_proc,	SEG code
df18 DW OFFSET default_proc,	SEG code
df19 DW OFFSET default_proc,	SEG code
df1A DW OFFSET default_proc,	SEG code
df1B DW OFFSET default_proc,	SEG code
df1C DW OFFSET default_proc,	SEG code
df1D DW OFFSET default_proc,	SEG code
df1E DW OFFSET default_proc,	SEG code
df1F DW OFFSET default_proc,	SEG code

init	PROC far
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET hook_init_file_system
	mov di,OFFSET hook_init_file_system_name
	mov ax,hook_init_file_system_nr
	RegisterOsGate
;
	mov si,OFFSET register_file_system
	mov di,OFFSET register_file_system_name
	mov ax,register_file_system_nr
	RegisterOsGate
;
	mov si,OFFSET define_media_check
	mov di,OFFSET define_media_check_name
	mov ax,define_media_check_nr
	RegisterOsGate
;
	mov si,OFFSET demand_load_file_system
	mov di,OFFSET demand_load_file_system_name
	mov ax,demand_load_file_system_nr
	RegisterOsGate
;
	mov si,OFFSET format_file_system
	mov di,OFFSET format_file_system_name
	mov ax,format_file_system_nr
	RegisterOsGate
;
	mov si,OFFSET is_file_system_available
	mov di,OFFSET is_file_system_available_name
	mov ax,is_file_system_available_nr
	RegisterOsGate
;
	mov si,OFFSET install_file_system
	mov di,OFFSET install_file_system_name
	mov ax,install_file_system_nr
	RegisterOsGate
;
	mov si,OFFSET start_file_system
	mov di,OFFSET start_file_system_name
	mov ax,start_file_system_nr
	RegisterOsGate
;
	mov si,OFFSET stop_file_system
	mov di,OFFSET stop_file_system_name
	mov ax,stop_file_system_nr
	RegisterOsGate
;
	mov bx,OFFSET rename_file16
	mov si,OFFSET rename_file32
	mov di,OFFSET rename_file_name
	mov dx,virt_ds_in OR virt_es_in
	mov ax,rename_file_nr
	RegisterUserGate
;
	mov di,OFFSET init_hook_thread
	HookInitTasking
;
	mov di,OFFSET init_process
	HookCreateProcess
;
	mov eax,SIZE fs_process_seg
	mov bx,fs_process_sel
	AllocateFixedProcessMem
;	
	mov eax,SIZE fs_data_seg
	mov bx,fs_sys_data_sel
	AllocateFixedSystemMem
;
    push ds
    mov ds,bx
    InitSection ds:fs_init_section
    EnterSection ds:fs_init_section
;    
	mov ds:fs_init_done,0
	mov ds:file_defs,0
	mov ds:fs_init_hooks,0
	pop ds
;
	mov di,OFFSET fs_sel
	mov cx,256
	xor ax,ax
	rep stosw
;
	mov di,OFFSET media_check_handle
	mov cx,256
	xor ax,ax
	rep stosw
;
	mov di,OFFSET media_check_proc
	mov cx,256
	xor eax,eax
	rep stosd
;
	call init_dir
	call init_file
	call init_memmap
	call init_inifile
	clc
	ret
init	ENDP

code	ENDS

	END init

