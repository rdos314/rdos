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
; FLASH.ASM
; Flash disk driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  flash

GateSize = 16

INCLUDE \rdos\kernel\driver.def
INCLUDE \rdos\kernel\user.def
INCLUDE \rdos\kernel\os.def
INCLUDE \rdos\kernel\user.inc
INCLUDE \rdos\kernel\os.inc
INCLUDE \rdos\kernel\drive.inc
INCLUDE \rdos\kernel\os\port.def

boot_struc	STRUC

boot_jmp					DB ?,?,?
boot_name					DB 8 DUP(?)
boot_bytes_per_sector		DW ?
boot_sectors_per_cluster	DB ?
boot_resv_sectors			DW ?
boot_fats					DB ?
boot_root_dirs				DW ?
boot_sectors				DW ?
boot_media					DB ?
boot_fat_sectors			DW ?
boot_sectors_per_cyl		DW ?
boot_heads					DW ?
boot_hidden_sectors			DD ?
boot_big_sectors			DD ?
boot_drive_nr				DB ?,?
boot_signature				DB ?
boot_serial					DD ?
boot_volume					DB 11 DUP(?)
boot_fs						DB 8 DUP(?)

boot_struc		ENDS

disc_struc	STRUC

disc_section			section_typ <>
disc_fs_handle			DW ?
disc_sel				DW ?
disc_thread				DW ?
disc_sub_unit			DB ?
disc_nr					DB ?

disc_struc		ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

	assume cs:code

.386c

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DEMAND_MOUNT
;
;		DESCRIPTION:	Mount disc drive on demand
;
;		PARAMETERS:		BX		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

demand_mount	Proc far
	ret
demand_mount	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ERASE
;
;		DESCRIPTION:	Erase sectors
;
;		PARAMETERS:		BX		Disc handle
;                       EDX     Start sector
;                       ECX     Number of sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

erase	Proc far
    clc
	ret
erase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			check_media
;
;		DESCRIPTION:	Check for media change
;
;		PARAMETERS:		BX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_media	Proc far
    clc
	ret
check_media	Endp

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_drive
;
;		DESCRIPTION:	Read drive
;
;		PARAMETERS:		FS		Disc selector
;						EDI		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_drive	Proc near
    clc
	ret
read_drive	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_drive
;
;		DESCRIPTION:	Perform a write request
;
;		PARAMETERS:		DS		Disc selector
;						EDI		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive	Proc near
    clc
	ret
write_drive	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			perform_one
;
;		DESCRIPTION:	Perform one request
;
;		PARAMETERS:		FS		Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_one	Proc near

perform_one_loop:
	GetDiscRequest
	jc perform_one_done
;
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	je perform_one_read
;
	cmp al,STATE_DIRTY
	je perform_one_write
;
	cmp al,STATE_SEQ
	jne perform_one_done

perform_one_write:
	call write_drive
	jc perform_one_fail
	jmp perform_one_completed

perform_one_read:
	call read_drive
	jc perform_one_fail

perform_one_completed:
	mov bx,fs:disc_sel
	DiscRequestCompleted
	jmp perform_one_loop

perform_one_fail:
	int 3
	mov bx,fs:disc_sel
	DiscRequestCompleted
;	FlushDisc

perform_one_done:
	ret
perform_one	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISCBUF_THREAD
;
;		DESCRIPTION:	Thread to handle disc buffer queue
;
;		PARAMETERS:		FS		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

discbuf_thread:
    int 3
	GetThread
	mov fs:disc_thread,ax
	mov bx,fs:disc_sel
;
	mov ax,flat_sel
	mov es,ax
	WaitForSignal

discbuf_thread_loop:
	WaitForDiscRequest
	call perform_one
	jmp discbuf_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_UNIT
;
;		DESCRIPTION:	Install a disk unit
;
;		PARAMETERS:		AL		UNIT #
;						DI		NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_unit	Proc near
	push ax
	mov eax,SIZE disc_struc
	AllocateSmallGlobalMem
	mov bx,es
	mov fs,bx
	pop ax
	mov fs:disc_sub_unit,al
	InitSection fs:disc_section
;
	mov ecx,200h
	mov bx,fs
	InstallDisc
	mov fs:disc_sel,bx
	mov fs:disc_nr,al
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET discbuf_thread
	mov ax,4
	mov cx,100h
	CreateThread
	ret
install_unit	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			disc_assign
;
;		DESCRIPTION:	Assign discs
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flash0	DB 'Flash disc 0',0
flash1	DB 'Flash disc 1',0

disc_assign	Proc far
	push ds
	push es
	pusha
;
	mov al,0
	mov di,OFFSET flash0
	call install_unit
	mov al,1
	mov di,OFFSET flash1
	call install_unit
;
	popa
	pop es
	pop ds	
	ret
disc_assign	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DRIVE_ASSIGN1
;
;		DESCRIPTION:	Assign disc drives, pass 1
;
;		PARAMETERS:		BX		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drive_assign1	Proc far
	ret
drive_assign1	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DRIVE_ASSIGN2
;
;		DESCRIPTION:	Assign disc drives, pass 2
;
;		PARAMETERS:		BX		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drive_assign2	Proc far
	ret
drive_assign2	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_ctrl:
dct00	DW OFFSET disc_assign,		flash_disc_code_sel
dct01	DW OFFSET drive_assign1,	flash_disc_code_sel
dct02	DW OFFSET drive_assign2,	flash_disc_code_sel
dct03	DW OFFSET demand_mount,		flash_disc_code_sel
dct04   DW OFFSET erase,            flash_disc_code_sel

init	PROC far
	push ds
	push es
	pusha
	mov bx,flash_disc_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET disc_ctrl
	HookInitDisc
;	
	popa
	pop es
	pop ds
	ret
init	ENDP

code ENDS

END init

