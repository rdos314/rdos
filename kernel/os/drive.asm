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
; DRIVE.ASM
; Basic physical drive support module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME drive

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
INCLUDE drive.inc

MAX_DRIVES = 'Z' - 'A' + 1

STATE_DIRTY = 9Bh
STATE_USED = 5Ah

CallDrive	Macro call_proc
	push ds
	push bx
	push si
	mov bx,ds:disc_handle
	lds si,ds:disc_proc
	call ds:[si].&call_proc
	pop si
	pop bx
	pop ds
				ENDM

disc_data_seg		STRUC

init_disc_hooks		DB ?

init_disc_hook_arr	DD MAX_DRIVES DUP(?)

disc_def_arr		DW MAX_DRIVES DUP(?)

drive_def_arr		DW MAX_DRIVES DUP(?)

disc_data_seg		ENDS

disc_def_struc		STRUC

disc_sub_unit			DB ?
disc_nr					DB ?
disc_proc				DD ?
disc_handle				DW ?
disc_units				DW ?
disc_bytes_per_sector	DW ?
disc_sectors_per_unit	DW ?
disc_thread				DW ?
disc_block_count		DW ?
disc_timer_id			DW ?
disc_current			DD ?
disc_queue				DD ?
disc_list				DD ?
disc_free				DD ?
disc_section			section_typ <>
disc_unit_arr			DD ?

disc_def_struc		ENDS

disc_unit_struc	STRUC

disc_sectors			DW ?
disc_unit_pad			DW ?
disc_sector_arr			DD ?

disc_unit_struc	ENDS

drive_def_struc	STRUC

drive_disc				DW ?
drive_start_sector		DD ?

drive_def_struc	ENDS

DISC_HANDLE_SIZE	EQU 32

discbuf_handle		STRUC

dh_next				DD ?
dh_prev				DD ?
dh_unit				DW ?
dh_sector			DW ?
dh_wait				DW ?
dh_thread			DW ?
dh_lock_count		DB ?
dh_state			DB ?
dh_usage			DW ?
dh_buf_sel			DW ?
dh_time_lsb			DD ?
dh_time_msb			DW ?
dh_data				DD ?

discbuf_handle		ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code
	assume ds:disc_data_seg

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_LIST
;
;		DESCRIPTION:	Allocate list
;
;		PARAMETERS:		DS		Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_list	PROC near
	push eax
	push ecx
	push edx
	mov eax,1000h
	AllocateBigLinear
	mov ds:disc_list,edx
	pop edx
	pop ecx
	pop eax
	ret
allocate_list	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE
;
;		DESCRIPTION:	Allocate handle
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat_sel
;
;		RETURNS:		EDI		DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate	PROC near
	push eax
	push edx
	mov eax,ds:disc_free
	or eax,eax
	jnz allocate_done
	mov edx,ds:disc_list
	test dx,0FFFh
	jnz allocate_not_full
	call allocate_list
allocate_not_full:
	push ecx
	mov eax,1000h
	AllocateBigLinear
	mov eax,ds:disc_list
	movzx ecx,ds:disc_bytes_per_sector
allocate_init_loop:
	mov es:[eax].dh_data,edx
	add edx,ecx
	add eax,DISC_HANDLE_SIZE
	mov es:[eax-DISC_HANDLE_SIZE].dh_next,eax
	test dx,0FFFh
	jnz allocate_init_loop
	pop ecx
	mov edx,ds:disc_free
	mov es:[eax-DISC_HANDLE_SIZE].dh_next,edx
	xchg eax,ds:disc_list
allocate_done:
	mov edx,es:[eax].dh_next
	mov ds:disc_free,edx
	mov edi,eax
	pop edx
	pop eax
	ret
allocate	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE
;
;		DESCRIPTION:	Free handle
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat_sel
;						EDI		DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free	PROC near
	push edx
	mov edx,ds:disc_free
	mov es:[edi],edx
	mov ds:disc_free,edi
	pop edx
	ret
free	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CHECK
;
;		DESCRIPTION:	Check if sector is in list
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat_sel
;						CX		Unit #
;						DX		Sector #
;						SI		List to look in
;
;		RETURNS:		EDI		DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check	PROC near
	mov edi,ds:[si]
	or edi,edi
	stc
	jz check_done
check_loop:
	cmp cx,es:[edi].dh_unit
;	jc check_done
	jnz check_next
	cmp dx,es:[edi].dh_sector
;	jbe check_done
	je check_done
check_next:
	mov edi,es:[edi].dh_next
	cmp edi,[si]
	jne check_loop
	stc
check_done:
	ret
check	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CHECK_BUF
;
;		DESCRIPTION:	Check if sector is in buffer list
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat_sel
;						CX		Unit #
;						DX		Sector #
;
;		RETURNS:		EDI		DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_buf	PROC near
	push esi
	movzx esi,cx
	mov edi,ds:[4*esi].disc_unit_arr
	or edi,edi
	jz check_buf_fail
;
	movzx esi,dx
	mov edi,es:[4*esi+edi].disc_sector_arr
	or edi,edi
	clc
	jnz check_buf_done
	
check_buf_fail:
	stc

check_buf_done:
	pop esi
	ret
check_buf	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CHECK_CURRENT
;
;		DESCRIPTION:	Check if sector is current sector
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat_sel
;						CX		Unit #
;						DX		Sector #
;
;		RETURNS:		EDI		DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_current	PROC near
	mov edi,ds:disc_current
	or edi,edi
	stc
	jz check_current_done
	cmp cx,es:[edi].dh_unit
	stc
	jnz check_current_done
	cmp dx,es:[edi].dh_sector
	stc
	jnz check_current_done
	clc
check_current_done:
	ret
check_current	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSERT
;
;		DESCRIPTION:	Insert block in list
;
;		PARAMETERS:		DS		DiscBuf handle
;						ES		Flat_sel
;						SI		List address
;						EDI		DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert	PROC near
	push eax
	push ebx
	push cx
	push dx
;
	mov eax,ds:[si]
	or eax,eax
	jne insert_used

insert_empty:
	mov es:[edi].dh_prev,edi
	mov es:[edi].dh_next,edi
	mov ds:[si],edi
	jmp insert_done

insert_used:
	mov cx,es:[edi].dh_unit
	mov dx,es:[edi].dh_sector
	cmp cx,es:[eax].dh_unit
	jc insert_first
	jnz insert_search_loop
	cmp dx,es:[eax].dh_sector
	jnc insert_search_loop

insert_first:
	mov ds:[si],edi
	jmp insert_link

insert_search_loop:
	mov eax,es:[eax].dh_next
	cmp eax,ds:[si]
	je insert_link
	cmp cx,es:[eax].dh_unit
	jc insert_link
	jnz insert_search_loop
	cmp dx,es:[eax].dh_sector
	jnc insert_search_loop

insert_link:	
	mov ebx,es:[eax].dh_prev
	mov es:[eax].dh_prev,edi
	mov es:[ebx].dh_next,edi
	mov es:[edi].dh_prev,ebx
	mov es:[edi].dh_next,eax	

insert_done:
	pop dx
	pop cx
	pop ebx
	pop eax
	ret
insert	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSERT_BUF
;
;		DESCRIPTION:	Insert block in buffer list
;
;		PARAMETERS:		DS		DiscBuf handle
;						ES		Flat_sel
;						EDI		DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_buf	PROC near
	push eax
	push edx
	push esi
;
	movzx esi,es:[edi].dh_unit
	mov edx,ds:[4*esi].disc_unit_arr
	or edx,edx
	jne insert_buf_used
;
	push ecx
	push edi
	mov edi,OFFSET disc_sector_arr
	movzx ecx,ds:disc_sectors_per_unit
	mov eax,ecx
	shl eax,2
	add eax,edi
	AllocateSmallLinear
	mov ds:[4*esi].disc_unit_arr,edx
	mov es:[edx].disc_sectors,0
	add edi,edx
	xor eax,eax
	rep stos dword ptr es:[edi]
	pop edi
	pop ecx

insert_buf_used:
	inc es:[edx].disc_sectors
	movzx esi,es:[edi].dh_sector
	mov es:[4*esi+edx].disc_sector_arr,edi
;
	pop esi
	pop edx
	pop eax
	ret
insert_buf	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REMOVE
;
;		DESCRIPTION:	Remove block from list
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat_sel
;						SI		List address
;						EDI		DiscBlock handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove	PROC near
	push eax
	push ebx
;
	mov eax,es:[edi].dh_next
	mov ebx,es:[edi].dh_prev
	mov es:[ebx].dh_next,eax
	mov es:[eax].dh_prev,ebx
	cmp eax,edi
	jne remove_more
	mov dword ptr ds:[si],0
	jmp remove_done
remove_more:
	cmp edi,ds:[si]
	jne remove_done
	mov ds:[si],eax
remove_done:
	pop ebx
	pop eax
	ret
remove	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REMOVE_BUF
;
;		DESCRIPTION:	Remove block from buffer list
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat_sel
;						EDI		DiscBlock handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_buf	PROC near
	push ecx
	push edx
	push esi
;
	movzx esi,es:[edi].dh_unit
	mov edx,ds:[4*esi].disc_unit_arr
	or edx,edx
	jz remove_buf_done
;
	movzx ecx,es:[edi].dh_sector
	mov es:[4*ecx+edx].disc_sector_arr,0
	sub es:[edx].disc_sectors,1
	jnz remove_buf_done
;
	mov ds:[4*esi].disc_unit_arr,0
	movzx ecx,ds:disc_sectors_per_unit
	shl ecx,2
	add ecx,OFFSET disc_sector_arr
	FreeLinear

remove_buf_done:
	pop esi
	pop edx
	pop ecx
	ret
remove_buf	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Block
;
;		DESCRIPTION:	Block until IO complete
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat_sel
;						EDI		DiscBlock handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

block	Proc near
	LeaveSection ds:disc_section
	push ax
	push bx
	push dx
	mov bx,ds:disc_thread
	cli
	mov ax,es:[edi].dh_thread
	or ax,ax
	jnz block_no_signal
	inc ds:disc_block_count
	GetThread
	mov es:[edi].dh_thread,ax
	sti
	mov bx,ds:disc_thread
	Signal
	WaitForSignal
	jmp block_cont

block_no_signal:
	push ds
	push edi
	mov ax,es
	mov ds,ax
	add edi,OFFSET dh_wait
	Sleep32
	pop edi
	pop ds
block_cont:
	sti
	pop dx
	pop bx
	pop ax
	EnterSection ds:disc_section
	ret
block	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_DRIVES
;
;		DESCRIPTION:	Init all drives assocated with a disc #
;
;		PARAMETERS:		DS		Disc def struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_drives	Proc near
	push ds
	push es
	push ax
	push bx
	push cx
	push si
;
	mov bx,ds
	mov ax,disc_data_sel
	mov ds,ax
	mov cx,MAX_DRIVES
	mov si,OFFSET drive_def_arr
init_drives_loop:
	mov ax,[si]
	or ax,ax
	jz init_drives_next
	cmp ax,-1
	je init_drives_next
	mov es,ax
	cmp bx,es:drive_disc
	jne init_drives_next
	mov ax,si
	sub ax,OFFSET drive_def_arr
	shr ax,1
	InitFileSystem
init_drives_next:
	add si,2
	loop init_drives_loop	
;
	pop si
	pop cx
	pop bx
	pop ax
	pop es
	pop ds
	ret
init_drives	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_DISC
;
;		DESCRIPTION:	Open disc
;
;		PARAMETERS:		DS		Disc def struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_disc	Proc near
	push ds
	push si
	mov al,ds:disc_sub_unit
	mov ah,ds:disc_nr
	mov bx,ds:disc_handle
	lds si,ds:disc_proc
	call ds:[si].open_disc_proc
	pop si
	pop ds
	jc open_disc_done
;
	mov ds:disc_sectors_per_unit,ax
	mov ds:disc_bytes_per_sector,cx
	mov ds:disc_units,dx
;
	push es
	push ecx
	push si
	push di
;
	mov ecx,OFFSET disc_unit_arr
	movzx eax,dx
	shl eax,2
	add eax,ecx
	AllocateSmallGlobalMem
	xor di,di
	xor si,si
	rep movsb
;
	xor eax,eax
	movzx edi,di
	movzx ecx,dx
	rep stos dword ptr es:[edi]
;
	mov si,ds
	mov di,es
	mov ax,gdt_sel
	mov ds,ax
	mov eax,[si]
	xchg eax,[di]
	mov [si],eax
	mov eax,[si+4]
	xchg eax,[di+4]
	mov [si+4],eax
	mov ds,si
	mov es,di
	FreeMem
;
	pop di
	pop si
	pop ecx
	pop es
;
	push es
	push di
	call init_drives
	pop di
	pop es
	clc
open_disc_done:
	ret
open_disc	Endp
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PERFORM_IO
;
;		DESCRIPTION:	Perform I/O requests
;
;		PARAMETERS:		DS		Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_io	Proc near
	xor cx,cx
perform_io_loop:
	mov si,OFFSET disc_queue
	mov edi,[si]
	or edi,edi
	jz perform_io_done	
perform_io_check:
	cmp cx,es:[edi].dh_unit
	jbe perform_io_start
	mov edi,es:[edi].dh_next
	cmp edi,[si]
	jne perform_io_check	
	jmp perform_io
perform_io_start:
	mov [si],edi
	push es:[edi].dh_unit
	mov ds:disc_current,edi
	call remove
	LeaveSection ds:disc_section
;
	CallDrive check_media_proc
	jc perform_io_media_change
perf_redo:
	mov ax,es:[edi].dh_sector
	movzx edx,es:[edi].dh_unit
	mov cx,1
	cmp es:[edi].dh_state,0
	je perform_io_read
;
	cmp es:[edi].dh_state,STATE_DIRTY
	je perform_io_write
;
	int 3
	jmp perform_io_completed

perform_io_write:
	or dx,dx
	jnz perform_io_do_write
	or ax,ax
	jnz perform_io_do_write
;
	int 3
	jmp perform_io_completed

perform_io_do_write:
	mov edi,es:[edi].dh_data
	CallDrive write_disc_proc
	pushf
	EnterSection ds:disc_section
	popf
	mov edi,ds:disc_current
	mov es:[edi].dh_state,STATE_USED
	jmp perform_io_completed
perform_io_read:
	mov edi,es:[edi].dh_data
	CallDrive read_disc_proc
perform_io_validate:
	jnc perform_io_cont1
	int 3
	mov edi,ds:disc_current
	jmp perf_redo
perform_io_cont1:
	pushf
	EnterSection ds:disc_section
	popf
	mov edi,ds:disc_current
	jc perform_io_completed
	mov es:[edi].dh_state,STATE_USED
perform_io_completed:
	mov ds:disc_current,0
;
	xor bx,bx
	xchg bx,es:[edi].dh_thread
	Signal
	push ds
	mov ax,es
	mov ds,ax
	lea esi,[edi].dh_wait
perform_io_wake:
	mov ax,[esi]
	or ax,ax
	jz perform_io_wake_done
	Wake32
	jmp perform_io_wake
perform_io_wake_done:
	pop ds
	pop cx
	jmp perform_io_loop

perform_io_media_change:
	pop cx
	int 3

perform_io_done:
	ret
perform_io	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISCINIT_THREAD
;
;		DESCRIPTION:	Thread to open a disc drive
;
;		PARAMETERS:		FS		Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

discinit_thread_name	DB 'Disc Init',0

discinit_thread	Proc far
	mov ax,fs
	mov ds,ax
	call open_disc
	jc discinit_thread_done
	mov bx,ds:disc_thread
	Signal
discinit_thread_done:
	ret
discinit_thread	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISCBUF_THREAD
;
;		DESCRIPTION:	Thread to handle disc buffer queue
;
;		PARAMETERS:		FS		Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

discbuf_thread:
	mov ax,fs
	mov ds,ax
	GetThread
	mov ds:disc_thread,ax
;
	push ds
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET discinit_thread
	mov di,OFFSET discinit_thread_name
	mov ax,4
	mov cx,100h
	CreateThread
	pop ds
	WaitForSignal
	mov ax,flat_sel
	mov es,ax

discbuf_thread_loop:
	cli
	cmp ds:disc_block_count,0
	jne discbuf_thread_process
	WaitForSignal
discbuf_thread_process:
	sti
	EnterSection ds:disc_section
	mov ds:disc_block_count,0
	call perform_io
	LeaveSection ds:disc_section
	jmp discbuf_thread_loop

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_DISC
;
;		DESCRIPTION:	Install disc unit
;
;		PARAMETERS:		AL		Sub-unit
;						BX		Disc handle
;						DS:SI	Disc name
;						ES:DI	Disc struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_disc_name	DB 'Install Disc',0

install_disc	Proc far
	push ds
	push es
	push ax
	push cx
	push si
	push di
;
	push ds
	push si
	push ax
	mov ax,disc_data_sel
	mov ds,ax
	mov si,OFFSET disc_def_arr
	mov cx,MAX_DRIVES
install_disc_loop:
	mov ax,[si]
	or ax,ax
	jnz install_disc_next
	push es
	mov eax,SIZE disc_def_struc
	AllocateSmallGlobalMem
	push di
	xor di,di
	mov cx,ax
	xor al,al
	rep stosb
	pop di
	mov [si],es
	mov ax,es
	mov ds,ax
	mov ax,si
	sub ax,OFFSET disc_def_arr
	shr ax,1
	mov ds:disc_nr,al
	pop cx
	pop ax
	mov ds:disc_handle,bx
	mov ds:disc_sub_unit,al
	mov word ptr ds:disc_proc,di
	mov word ptr ds:disc_proc+2,cx
	mov ds:disc_current,0
	mov ds:disc_queue,0
	mov ds:disc_list,0
	mov ds:disc_free,0
	mov ds:disc_thread,-1
	mov ds:disc_timer_id,0
	mov ds:disc_block_count,0
	InitSection ds:disc_section
	pop di
	pop es
;
	push fs
	mov ax,ds
	mov fs,ax
	mov ax,cs
	mov ds,ax
	mov si,OFFSET discbuf_thread
	mov ax,4
	mov cx,100h
	CreateThread
	pop fs
	clc
	jmp install_disc_done
install_disc_next:
	add si,2
	sub cx,1
	jnz install_disc_loop
	add sp,6
	stc
install_disc_done:
	pop di
	pop si
	pop cx
	pop ax
	pop es
	pop ds
	ret
install_disc	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_FIXED_DRIVE
;
;		DESCRIPTION:	Allocate fixed drive
;
;		PARAMETERS:		AL		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_drive_name	DB 'Allocate Fixed Drive',0

allocate_fixed_drive	Proc far
	push ds
	push bx
;
	mov bx,disc_data_sel
	mov ds,bx
	movzx bx,al
	shl bx,1
	mov word ptr [bx].drive_def_arr,-1
;
	pop bx
	pop ds
	ret
allocate_fixed_drive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_STATIC_DRIVE
;
;		DESCRIPTION:	Allocate static drive (first)
;
;		RETURNS:		AL		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_static_drive_name	DB 'Allocate Static Drive',0

allocate_static_drive	Proc far
	push ds
	push cx
	push si
;
	mov ax,disc_data_sel
	mov ds,ax
	mov si,OFFSET drive_def_arr
	mov cx,MAX_DRIVES
allocate_static_drive_loop:
	mov ax,[si]
	or ax,ax
	jnz allocate_static_drive_next
	mov word ptr [si],-1
	mov ax,si
	sub ax,OFFSET drive_def_arr
	shr ax,1
	clc
	jmp allocate_static_drive_done
allocate_static_drive_next:
	add si,2
	loop allocate_static_drive_loop
	stc
allocate_static_drive_done:
;
	pop si
	pop cx
	pop ds
	ret
allocate_static_drive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_DYNAMIC_DRIVE
;
;		DESCRIPTION:	Allocate dynamic drive (last)
;
;		RETURNS:		AL		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dynamic_drive_name	DB 'Allocate Dynamic Drive',0

allocate_dynamic_drive	Proc far
	push ds
	push cx
	push si
;
	mov ax,disc_data_sel
	mov ds,ax
	mov si,OFFSET drive_def_arr + 2 * (MAX_DRIVES - 1)
	mov cx,MAX_DRIVES
allocate_dynamic_drive_loop:
	mov ax,[si]
	or ax,ax
	jnz allocate_dynamic_drive_next
	mov word ptr [si],-1
	mov ax,si
	sub ax,OFFSET drive_def_arr
	shr ax,1
	clc
	jmp allocate_dynamic_drive_done
allocate_dynamic_drive_next:
	sub si,2
	loop allocate_dynamic_drive_loop
	stc
allocate_dynamic_drive_done:
;
	pop si
	pop cx
	pop ds
	ret
allocate_dynamic_drive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OPEN_DRIVE
;
;		DESCRIPTION:	Open drive
;
;		PARAMETERS:		AL		Drive #
;						AH		Disc #
;						EDX		Start sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_drive_name	DB 'Open Drive',0

open_drive	Proc far
	push ds
	push es
	push bx
;
	push ax
	mov ax,disc_data_sel
	mov ds,ax
;
	mov eax,SIZE drive_def_struc
	AllocateSmallGlobalMem
	mov es:drive_start_sector,edx
	pop ax
	movzx bx,ah
	shl bx,1
	mov bx,ds:[bx].disc_def_arr
	mov es:drive_disc,bx
	movzx bx,al
	shl bx,1
	mov [bx].drive_def_arr,es
	clc
;
	pop bx
	pop es
	pop ds
	ret
open_drive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CLOSE_DRIVE
;
;		DESCRIPTION:	Close drive
;
;		PARAMETERS:		AL		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_drive_name	DB 'Close Drive',0

close_drive	Proc far
	int 3
	ret
close_drive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LOCK_SECTOR
;
;		DESCRIPTION:	Lock sector and return address
;
;		PARAMETERS:		AL		Drive #
;						EDX		Sector #
;
;		RETURNS:		EBX		Handle
;						ESI		Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_sector_name	DB 'Lock Sector',0

lock_sector	PROC far
	push ds
	push es
	push ax
	push cx
	push edx
	push edi
;
	movzx bx,al
	shl bx,1
	mov ax,disc_data_sel
	mov ds,ax
	mov ds,ds:[bx].drive_def_arr
	mov ax,flat_sel
	mov es,ax
	add edx,ds:drive_start_sector
	mov ds,ds:drive_disc
	push edx
	pop ax
	pop dx
	div ds:disc_sectors_per_unit
	mov cx,ax
	EnterSection ds:disc_section
lock_loop:
	call check_buf
	jnc lock_found
	call check_current
	jnc lock_read_signal
	mov si,OFFSET disc_queue
	call check
	jnc lock_read_signal
	ClearSignal
	call allocate
	mov es:[edi].dh_buf_sel,ds
	mov es:[edi].dh_sector,dx
	mov es:[edi].dh_unit,cx
	mov es:[edi].dh_wait,0
	mov es:[edi].dh_thread,0
	mov es:[edi].dh_lock_count,0
	mov es:[edi].dh_state,0
	mov es:[edi].dh_usage,0
	mov es:[edi].dh_time_lsb,0
	mov es:[edi].dh_time_msb,0
	mov si,OFFSET disc_queue
	call insert
lock_read_signal:
	cmp es:[edi].dh_state,0
	clc
	jne lock_found
	call block
	jmp lock_loop
lock_found:
	inc es:[edi].dh_lock_count
	inc es:[edi].dh_usage
	LeaveSection ds:disc_section
	cmp es:[edi].dh_state,0
	clc
	jne lock_get_adds
	stc
lock_get_adds:
	mov esi,es:[edi].dh_data
	mov ebx,edi
;
	pop edi
	pop edx
	pop cx
	pop ax
	pop es
	pop ds
	ret
lock_sector	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MODIFY_SECTOR
;
;		DESCRIPTION:	Modify sector contents
;
;		PARAMETERS:		EDI		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

modify_sector_name	DB 'Modify Sector',0

modify_sector	PROC far
	push ds
	push es
	push eax
	push ebx
	push cx
	push edx
	push si
	push edi
;
	mov ax,flat_sel
	mov es,ax
	mov edi,ebx
	mov ds,es:[edi].dh_buf_sel
	EnterSection ds:disc_section
	cmp es:[edi].dh_state,STATE_USED
	je modify_do
	cmp es:[edi].dh_state,STATE_DIRTY
	jne modify_done

modify_do:
	GetSystemTime
	mov es:[edi].dh_time_lsb,eax
	mov es:[edi].dh_time_msb,dx
	mov es:[edi].dh_state,STATE_DIRTY
	mov cx,es:[edi].dh_unit
	mov dx,es:[edi].dh_sector
	ClearSignal
modify_try_again:
	call check_current
	jc modify_not_current
	call block
	jmp modify_try_again
modify_not_current:
	call check_buf
	jc modify_done
;
	mov bx,ds:disc_thread
	Signal
modify_done:
	LeaveSection ds:disc_section
	clc
;
	pop edi
	pop si
	pop edx
	pop cx
	pop ebx
	pop eax
	pop es
	pop ds
	ret
modify_sector	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UNLOCK_SECTOR
;
;		DESCRIPTION:	UNlock sector
;
;		PARAMETERS:		EBX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_sector_name	DB 'Unlock Sector',0

unlock_sector	PROC far
	push es
	push ax
	mov ax,flat_sel
	mov es,ax
	dec es:[ebx].dh_lock_count
	xor ebx,ebx
	pop ax
	pop es
	clc
	ret
unlock_sector	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ResetDrive
;
;		DESCRIPTION:	Try to reset drive
;
;		PARAMETERS:		AL		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_drive_name	DB 'Reset Disc',0

reset_drive	PROC far
	push ds
	push ax
	push bx
;
	movzx bx,al
	shl bx,1
	mov ax,disc_data_sel
	mov ds,ax
	mov ax,ds:[bx].drive_def_arr
	or ax,ax
	jz reset_drive_done
;
	mov ds,ax
	mov bx,ds:disc_thread
	Signal

reset_drive_done:
	pop bx
	pop ax
	pop ds
	ret
reset_drive	ENDP
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HOOK_INIT_DISC
;
;		DESCRIPTION:	Add an InitDisc hook
;
;		PARAMETERS:		ES:DI		Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_init_disc_name	DB 'Hook Init Disc',0

hook_init_disc	Proc far
	push ds
	push ax
	push bx
	push cx
	mov ax,disc_data_sel
	mov ds,ax
	mov al,ds:init_disc_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET init_disc_hook_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:init_disc_hooks,al
	pop cx
	pop bx
	pop ax
	pop ds
	ret
hook_init_disc	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISC_HOOK_THREAD
;
;		DESCRIPTION:	Disc callback thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_thread_name DB 'Disc',0

disc_hook_thread	Proc far
	mov ax,disc_data_sel
	mov ds,ax
	movzx cx,ds:init_disc_hooks
	mov bx,OFFSET init_disc_hook_arr
	jcxz disc_hook_thread_done
disc_hook_thread_init_loop:
	push ds
	push bx
	push cx
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
	loop disc_hook_thread_init_loop	
disc_hook_thread_done:
	ret
disc_hook_thread	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_DISC_THREAD
;
;		DESCRIPTION:	Create disc thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_disc_thread	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET disc_hook_thread
	mov di,OFFSET disc_thread_name
	mov ax,3
	mov cx,256
	CreateThread
;
	popa
	pop es
	pop ds	
	ret
init_disc_thread	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init drive
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	push ds
	push es
	pusha
	mov bx,disc_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET hook_init_disc
	mov di,OFFSET hook_init_disc_name
	mov ax,hook_init_disc_nr
	RegisterOsGate
;
	mov si,OFFSET install_disc
	mov di,OFFSET install_disc_name
	mov ax,install_disc_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_fixed_drive
	mov di,OFFSET allocate_fixed_drive_name
	mov ax,allocate_fixed_drive_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_static_drive
	mov di,OFFSET allocate_static_drive_name
	mov ax,allocate_static_drive_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_dynamic_drive
	mov di,OFFSET allocate_dynamic_drive_name
	mov ax,allocate_dynamic_drive_nr
	RegisterOsGate
;
	mov si,OFFSET open_drive
	mov di,OFFSET open_drive_name
	mov ax,open_drive_nr
	RegisterOsGate
;
	mov si,OFFSET close_drive
	mov di,OFFSET close_drive_name
	mov ax,close_drive_nr
	RegisterOsGate
;
	mov si,OFFSET lock_sector
	mov di,OFFSET lock_sector_name
	mov ax,lock_sector_nr
	RegisterOsGate
;
	mov si,OFFSET unlock_sector
	mov di,OFFSET unlock_sector_name
	mov ax,unlock_sector_nr
	RegisterOsGate
;
	mov si,OFFSET modify_sector
	mov di,OFFSET modify_sector_name
	mov ax,modify_sector_nr
	RegisterOsGate
;
	mov si,OFFSET reset_drive
	mov di,OFFSET reset_drive_name
	mov ax,reset_drive_nr
	RegisterOsGate
;
	mov di,OFFSET init_disc_thread
	HookInitTasking
;
	mov eax,SIZE disc_data_seg
	mov bx,disc_data_sel
	AllocateFixedSystemMem
	mov es:init_disc_hooks,0
	mov cx,MAX_DRIVES
	mov di,OFFSET disc_def_arr
	xor ax,ax
	rep stosw
	mov cx,MAX_DRIVES
	mov di,OFFSET drive_def_arr
	xor ax,ax
	rep stosw
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init

