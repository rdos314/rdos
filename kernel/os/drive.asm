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

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE int.def
INCLUDE system.inc
INCLUDE ..\drive.inc

MAX_DRIVES = 'Z' - 'A' + 1
DRIVE_WAIT_NUM = 32

POLL_TIMEOUT EQU 119200
MIN_TIMEOUT EQU 119200

drive_wait_struc	STRUC

dws_link			DW ?
dws_thread			DW ?

drive_wait_struc	ENDS

disc_data_seg		STRUC

disc_params			DB ?
disc_curr_param		DW ?
disc_param_arr		DD MAX_DRIVES DUP(?)
disc_def_arr		DW MAX_DRIVES DUP(?)
drive_def_arr		DW MAX_DRIVES DUP(?)
drive_wait_arr		DB 4*DRIVE_WAIT_NUM DUP(?)
drive_wait_free		DW ?

disc_data_seg		ENDS

disc_def_struc		STRUC

disc_nr					DB ?
disc_units				DW ?
disc_bytes_per_sector	DW ?
disc_sectors_per_unit	DW ?
disc_sectors_per_cyl	DW ?
disc_heads				DW ?
disc_thread				DW ?
disc_timer_id			DW ?
disc_data_list			DD ?
disc_handle_list		DD ?
disc_readahead			DD ?
disc_free				DD ?
disc_section			section_typ <>
disc_pend_list			DD ?
disc_pend_first			DD ?
disc_awrite_list		DD ?
disc_awrite_timer		DW ?
disc_awrite_timeout		DD ?,?
disc_seq_list			DW ?
disc_param				DD ?
disc_handle				DW ?
disc_change_proc		DD ?
disc_unit_arr			DD ?

disc_def_struc		ENDS

disc_unit_struc	STRUC

disc_sectors			DW ?
disc_sector_arr			DD ?

disc_unit_struc	ENDS

drive_def_struc	STRUC

drive_disc				DW ?
drive_start_sector		DD ?
drive_sectors			DD ?

drive_def_struc	ENDS

disc_seq_struc	STRUC

dss_prev			DW ?
dss_next			DW ?
dss_buf_sel			DW ?
dss_insert_index	DW ?
dss_perform_index	DW ?

dss_arr				DD ?

disc_seq_struc	ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

CheckPending	Proc near
	xor cx,cx
	mov edi,ds:disc_pend_first
	mov eax,edi
	or edi,edi
	jz cpdone

cploop:
	cmp es:[edi].dh_state,STATE_DIRTY
	je cpvalid
;
	cmp es:[edi].dh_state,STATE_EMPTY
	jne cpfail

cpvalid:
	test es:[edi].dh_flags, FLAG_ASYNC_WRITE
	jz cpnext

cpfail:
	int 3	
	mov al,es:[edi].dh_state
	mov ah,es:[edi].dh_flags
	jmp cpdone

cpnext:
	mov edi,es:[edi].dh_next
	cmp edi,eax
	jz cpdone
;
	loop cploop
;
	int 3

cpdone:
	ret
CheckPending	Endp

CheckAsyncWrite	Proc near
	xor cx,cx
	mov edi,ds:disc_awrite_list
	mov eax,edi
	or edi,edi
	jz cawdone

cawloop:
	test es:[edi].dh_flags, FLAG_ASYNC_WRITE
	jz cawfail
;
	cmp es:[edi].dh_state,STATE_DIRTY
	je cawnext

cawfail:
	int 3	
	mov al,es:[edi].dh_state
	mov ah,es:[edi].dh_flags
	jmp cawdone

cawnext:
	mov edi,es:[edi].dh_next
	cmp edi,eax
	jz cawdone
;
	loop cawloop
;
	int 3

cawdone:
	ret
CheckAsyncWrite	Endp

CheckAll	Proc near
	push es
	push eax
	push ecx
	push edi
;
	mov ax,flat_sel
	mov es,ax
	call CheckPending
	call CheckAsyncWrite
;
	pop edi
	pop ecx
	pop eax
	pop es
	ret
CheckAll	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_DATA
;
;		DESCRIPTION:	Allocate data
;
;		PARAMETERS:		DS		Disc selector
;
;		RETURNS:		EDX		Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_data	PROC near
	push eax
	push ecx
;
	mov edx,ds:disc_data_list
	or edx,edx
	jnz allocate_data_done
;
	mov eax,1000h
	AllocateBigLinear
	movzx ecx,ds:disc_bytes_per_sector
	mov ds:disc_data_list,edx
allocate_init_data_loop:
	mov eax,edx
	add eax,ecx
	mov es:[edx],eax
	mov edx,eax
	test dx,0FFFh
	jnz allocate_init_data_loop
;
	sub edx,ecx
	mov dword ptr es:[edx],0
	mov edx,ds:disc_data_list

allocate_data_done:
	mov eax,es:[edx]
	mov ds:disc_data_list,eax
;
	pop ecx
	pop eax
	ret
allocate_data	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE_DATA
;
;		DESCRIPTION:	Free data
;
;		PARAMETERS:		DS		Disc selector
;						EDX		Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_data	PROC near
	push eax
	mov eax,ds:disc_data_list
	mov es:[edx],eax
	mov ds:disc_data_list,edx
	pop eax
	ret
free_data	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_HANDLE
;
;		DESCRIPTION:	Allocate handle
;
;		PARAMETERS:		DS		Disc selector
;						
;		RETURNS:		EDI		Discbuf handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_handle	PROC near
	push eax
	push edx
;
	mov edi,ds:disc_handle_list
	or edi,edi
	jnz allocate_handle_done
;
	push cx
	mov eax,1000h
	AllocateBigLinear
	mov ds:disc_handle_list,edx
	pop cx

allocate_init_handle_loop:
	add edx,DISC_HANDLE_SIZE
	mov es:[edx-DISC_HANDLE_SIZE].dh_next,edx
	test dx,0FFFh
	jnz allocate_init_handle_loop
;
	mov es:[edx-DISC_HANDLE_SIZE].dh_next,0
	mov edi,ds:disc_handle_list

allocate_handle_done:
	mov eax,es:[edi].dh_next
	mov ds:disc_handle_list,eax
;
	pop edx
	pop eax
	ret
allocate_handle	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE_HANDLE
;
;		DESCRIPTION:	Free handle
;
;		PARAMETERS:		DS		Disc selector
;						EDI		Disc buf handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_handle	PROC near
	push eax
	test es:[edi].dh_flags, FLAG_EXT_DATA
	jnz free_handle_do
;
	push edx
	mov edx,es:[edi].dh_data
	call free_data
	pop edx

free_handle_do:
	mov eax,ds:disc_handle_list
	mov es:[edi],eax
	mov ds:disc_handle_list,edi
	pop eax
	ret
free_handle	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSERT_PENDING
;
;		DESCRIPTION:	Insert block into pending request list
;
;		PARAMETERS:		DS		DiscBuf handle
;						ES		Flat_sel
;						EDI		DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_pending	PROC near
	push eax
	push ebx
	push cx
	push dx
;
	test es:[edi].dh_flags,FLAG_IO_PENDING
	jz insert_pend_do
;
	int 3
	mov eax,ds:disc_pend_first
	or eax,eax
	jz insert_pend_do
;
	mov ebx,eax

insert_pend_check:
	cmp eax,edi
	je insert_pend_err
;
	mov eax,es:[eax].dh_next
	cmp eax,ebx
	jnz insert_pend_check
	jmp insert_pend_do

insert_pend_err:
	int 3
	jmp insert_pend_done

insert_pend_do:
	or es:[edi].dh_flags,FLAG_IO_PENDING
;
	mov eax,ds:disc_pend_first
	or eax,eax
	jne insert_pend_used

insert_pend_empty:
	mov es:[edi].dh_prev,edi
	mov es:[edi].dh_next,edi
	mov ds:disc_pend_list,edi
	mov ds:disc_pend_first,edi
	jmp insert_pend_done

insert_pend_used:
	mov cx,es:[edi].dh_unit
	mov dx,es:[edi].dh_sector
	cmp cx,es:[eax].dh_unit
	jc insert_pend_first
;
	jnz insert_pend_search_loop
	cmp dx,es:[eax].dh_sector
	jnc insert_pend_search_loop

insert_pend_first:
	mov ds:disc_pend_first,edi
	jmp insert_pend_link

insert_pend_search_loop:
	mov eax,es:[eax].dh_next
	cmp eax,ds:disc_pend_first
	je insert_pend_link
;
	cmp cx,es:[eax].dh_unit
	jc insert_pend_link
;
	jnz insert_pend_search_loop
;
	cmp dx,es:[eax].dh_sector
	jnc insert_pend_search_loop

insert_pend_link:	
	mov ebx,es:[eax].dh_prev
	mov es:[eax].dh_prev,edi
	mov es:[ebx].dh_next,edi
	mov es:[edi].dh_prev,ebx
	mov es:[edi].dh_next,eax	

insert_pend_done:
	pop dx
	pop cx
	pop ebx
	pop eax
	ret
insert_pending	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_PENDING
;
;		DESCRIPTION:	Get next pending request
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat_sel
;
;		RETURNS:		EDI		DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pending	PROC near
	mov edi,ds:disc_pend_list
	or edi,edi
	stc
	jz get_pend_done
;
	mov eax,es:[edi].dh_next
	mov ebx,es:[edi].dh_prev
	mov es:[ebx].dh_next,eax
	mov es:[eax].dh_prev,ebx
	cmp eax,edi
	jne get_pend_unlink
;
	mov ds:disc_pend_list,0
	mov ds:disc_pend_first,0
	clc
	jmp get_pend_done

get_pend_unlink:
	mov ds:disc_pend_list,eax
	cmp edi,ds:disc_pend_first
	jne get_pend_first_ok
;
	mov ds:disc_pend_first,eax

get_pend_first_ok:
	clc

get_pend_done:
	ret
get_pending	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSERT_ASYNC_WRITE
;
;		DESCRIPTION:	Insert block into async write request list
;
;		PARAMETERS:		DS		DiscBuf handle
;						ES		Flat_sel
;						EDI		DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_async_write	PROC near
	push eax
	push ebx
;
	test es:[edi].dh_flags, FLAG_ASYNC_WRITE
	jz insert_awrite_do
;
	int 3
	jmp insert_awrite_done

insert_awrite_do:
	or es:[edi].dh_flags, FLAG_ASYNC_WRITE
;
	mov eax,ds:disc_awrite_list
	or eax,eax
	jne insert_awrite_used

insert_awrite_empty:
	mov es:[edi].dh_prev,edi
	mov es:[edi].dh_next,edi
	jmp insert_awrite_done

insert_awrite_used:
	mov ebx,es:[eax].dh_prev
	mov es:[eax].dh_prev,edi
	mov es:[ebx].dh_next,edi
	mov es:[edi].dh_prev,ebx
	mov es:[edi].dh_next,eax	

insert_awrite_done:
	mov ds:disc_awrite_list,edi
;
	pop ebx
	pop eax
	ret
insert_async_write	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UPDATE_ASYNC_WRITE
;
;		DESCRIPTION:	Update async write list
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_async_write	PROC near
	GetSystemTime
	sub eax,ds:disc_awrite_timeout
	sbb edx,ds:disc_awrite_timeout+4
	jc update_async_done

update_async_loop:
	mov edi,ds:disc_awrite_list
	or edi,edi
	jz update_async_done
;
	GetSystemTime
	sub eax,MIN_TIMEOUT
	sbb edx,0
;
	mov edi,es:[edi].dh_prev
	sub eax,es:[edi].dh_time_lsb
	sbb dx,es:[edi].dh_time_msb
	jc update_async_done
;
	mov eax,es:[edi].dh_next
	mov ebx,es:[edi].dh_prev
	mov es:[ebx].dh_next,eax
	mov es:[eax].dh_prev,ebx
	cmp eax,edi
	jne update_async_insert
;
	mov dword ptr ds:disc_awrite_list,0

update_async_insert:
	and es:[edi].dh_flags, NOT FLAG_ASYNC_WRITE
	call insert_pending
	jmp update_async_loop

update_async_done:
	ret
update_async_write	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ASYNC_WRITE_TIMEOUT
;
;		DESCRIPTION:	Async write timeout
;
;		PARAMETERS:		CX		Disc thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

async_write_timeout	Proc far
	mov ds,cx
	mov ds:disc_awrite_timer,0
	mov bx,ds:disc_thread
	Signal
	ret
async_write_timeout	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UPDATE_ASYNC_TIMER
;
;		DESCRIPTION:	Update async write timer
;
;		PARAMETERS:		DS		Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_async_timer	Proc near
	cli
	mov ax,ds:disc_awrite_timer
	or ax,ax
	jnz update_async_timer_done
;
	sti
	mov edi,ds:disc_awrite_list
	or edi,edi
	jz update_async_timer_done
;
	mov ds:disc_awrite_timer,1
	GetSystemTime
	add eax,POLL_TIMEOUT
	adc edx,0
	mov ds:disc_awrite_timeout,eax
	mov ds:disc_awrite_timeout+4,edx
	push es
	mov bx,cs
	mov es,bx
	mov cx,ds
	mov di,OFFSET async_write_timeout
	StartTimer
	pop es

update_async_timer_done:
	sti
	ret
update_async_timer	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UPDATE_DISC_SEQ
;
;		DESCRIPTION:	Update seq write lists
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_disc_seq	PROC far
	mov ax,ds:disc_seq_list
	or ax,ax
	jz update_seq_done
;
	int 3
	push fs
	pushad
;
	mov bp,ax

update_seq_loop:
	mov fs,ax
	movzx ebx,fs:dss_perform_index

update_seq_discard_loop:
	mov edi,fs:[4*ebx].dss_arr
	cmp es:[edi].dh_state,STATE_SEQ
	je update_seq_move_loop
;
	mov fs:[4*ebx].dss_arr,0
	inc bx
	mov fs:dss_perform_index,bx
	cmp bx,fs:dss_insert_index
	jne update_seq_discard_loop	
;
	push es
	mov ax,fs
	mov es,ax
	xor ax,ax
	mov fs,ax
	mov ds:disc_seq_list,es
	push ds
	mov di,es:dss_next
	cmp di,ds:disc_seq_list
	mov ds:disc_seq_list,di
	mov si,es:dss_prev
	mov ds,di
	mov ds:dss_prev,si
	mov ds,si
	mov ds:dss_next,di
	pop ds
	jne update_seq_free
;
	mov ds:disc_seq_list,0

update_seq_free:
	FreeMem
	pop es
	jmp update_seq_next

update_seq_move_loop:
	mov dx,es:[edi].dh_sector
	mov ax,es:[edi].dh_unit
	test es:[edi].dh_flags,FLAG_IO_PENDING
	jnz update_seq_moved
;
	call insert_pending

update_seq_moved:
	inc bx
	inc dx
	mov edi,fs:[4*ebx].dss_arr
	cmp ax,es:[edi].dh_unit
	jne update_seq_next
;
	cmp dx,es:[edi].dh_sector
	je update_seq_move_loop

update_seq_next:
	mov ax,fs:dss_next
	cmp ax,bp
	jne update_seq_loop
;
	popad
	pop fs

update_seq_done:
	ret
update_disc_seq	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CHECK_BUF
;
;		DESCRIPTION:	Check if sector is in buffer cache
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
	push ecx
	push edx
	push esi
;
	movzx esi,es:[edi].dh_unit
	mov edx,ds:[4*esi].disc_unit_arr
	or edx,edx
	jne insert_buf_used
;
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

insert_buf_used:
	mov ax,es:[edi].dh_unit
	inc es:[edx].disc_sectors
	movzx esi,es:[edi].dh_sector
	mov es:[4*esi+edx].disc_sector_arr,edi
;
	pop esi
	pop edx
	pop ecx
	pop eax
	ret
insert_buf	ENDP

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
	push ax
	push bx
	push dx
	mov ax,es:[edi].dh_thread
	or ax,ax
	jnz block_no_signal
;
	GetThread
	mov es:[edi].dh_thread,ax
	mov bx,ds:disc_thread
	Signal
	jmp block_cont

block_no_signal:
	push ds
	mov ax,disc_data_sel
	mov ds,ax
	mov bx,ds:drive_wait_free
	mov ax,[bx]
	mov ds:drive_wait_free,ax
	GetThread
	mov ds:[bx].dws_thread,ax
	mov ax,es:[edi].dh_wait
	mov ds:[bx].dws_link,ax
	mov es:[edi].dh_wait,bx
	pop ds

block_cont:
	LeaveSection ds:disc_section
 	WaitForSignal
;
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
;		NAME:			START_DISC
;
;		DESCRIPTION:	Start disc
;
;		PARAMETERS:		BX		Disc sel
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_disc_name	DB 'Start Disc',0

start_disc	Proc far
	push ds
	push es
	pusha
;
	mov ax,disc_data_sel
	mov ds,ax
	mov cx,MAX_DRIVES
	mov si,OFFSET drive_def_arr

start_drives_loop:
	mov ax,[si]
	or ax,ax
	jz start_drives_next
;
	cmp ax,-1
	je start_drives_next
;
	mov es,ax
	cmp bx,es:drive_disc
	jne start_drives_next
;
	push ecx
	mov ecx,es:drive_sectors
	mov ax,si
	sub ax,OFFSET drive_def_arr
	shr ax,1
	StartFileSystem
	pop ecx

start_drives_next:
	add si,2
	loop start_drives_loop	
;
	popa
	pop es
	pop ds
	ret
start_disc	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			STOP_DISC
;
;		DESCRIPTION:	Stop disc
;
;		PARAMETERS:		BX		Disc sel
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_disc_name	DB 'Stop Disc',0

stop_disc	Proc far
	push ds
	push es
	pusha
;
	mov ax,disc_data_sel
	mov ds,ax
	mov cx,MAX_DRIVES
	mov si,OFFSET drive_def_arr

stop_drives_loop:
	mov ax,[si]
	or ax,ax
	jz stop_drives_next
;
	cmp ax,-1
	je stop_drives_next
;
	mov es,ax
	cmp bx,es:drive_disc
	jne stop_drives_next
;
	mov ax,si
	sub ax,OFFSET drive_def_arr
	shr ax,1
	StopFileSystem

stop_drives_next:
	add si,2
	loop stop_drives_loop	
;
	popa
	pop es
	pop ds
	ret
stop_disc	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SET_DISC_PARAM
;
;		DESCRIPTION:	Set disc parameters
;
;		PARAMETERS:		AX		Sectors per unit
;						BX		Disc sel
;						CX		Bytes per sector
;						DX		Units
;						SI		BIOS sectors / cylinder
;						DI		BIOS heads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_disc_param_name	DB 'Set Disc Param',0

set_disc_param	Proc far
	push ds
	push es
	push eax
	push ecx
	push si
	push edi
;
	mov ds,bx
	mov ds:disc_sectors_per_unit,ax
	mov ds:disc_bytes_per_sector,cx
	mov ds:disc_units,dx
	mov ds:disc_sectors_per_cyl,si
	mov ds:disc_heads,di
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
	cli
	mov eax,[si]
	xchg eax,[di]
	mov [si],eax
	mov eax,[si+4]
	xchg eax,[di+4]
	mov [si+4],eax
	sti
	jmp short $+2
	mov ds,si
	mov es,di
	FreeMem
;
	pop edi
	pop si
	pop ecx
	pop eax
	pop es
	pop ds
	ret
set_disc_param	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REGISTER_DISC_CHANGE
;
;		DESCRIPTION:	Register disc-change procedure
;
;		PARAMETERS:		BX		Disc sel
;						ES:DI	Disc change proc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_disc_change_name	DB 'Register Disc Change',0

register_disc_change	Proc far
	push ds
	push bx
;
	mov ds,bx
	mov word ptr ds:disc_change_proc,di
	mov word ptr ds:disc_change_proc+2,es
;
	pop bx
	pop ds
	ret
register_disc_change	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			wait_for_disc_request
;
;		DESCRIPTION:	wait for a new disc request
;
;		PARAMETERS:		BX		Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_disc_request_name	DB 'Wait For Disc Request', 0

wait_for_disc_request	Proc far
	push ds
	push es
	pushad
;
	mov ds,bx
	mov ax,flat_sel
	mov es,ax
;
	ClearSignal

wait_for_disc_req_loop:
	EnterSection ds:disc_section
	GetThread
	mov ds:disc_thread,ax
	call update_async_write
	call update_async_timer
	LeaveSection ds:disc_section
;
	cli
	mov ebx,ds:disc_pend_list
	or ebx,ebx
	jnz wait_for_disc_req_done
;
	sti
	WaitForSignal
	mov ds:disc_thread,0
	jmp wait_for_disc_req_loop
		
wait_for_disc_req_done:
	mov ds:disc_thread,0
	sti
;
	popad
	pop es
	pop ds
	ret
wait_for_disc_request	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			poll_disc_request
;
;		DESCRIPTION:	poll for a new disc request
;
;		PARAMETERS:		BX		Disc selector
;
;		RETURNS:		EDI		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_disc_request_name	DB 'Poll Disc Request', 0

poll_disc_request	Proc far
	push ds
;
	mov ds,bx
	mov edi,ds:disc_pend_list
	or edi,edi
	stc
	jz poll_disc_req_done
;
	clc

poll_disc_req_done:
	pop ds
	ret
poll_disc_request	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_disc_request
;
;		DESCRIPTION:	get a disc request
;
;		PARAMETERS:		BX		Disc selector
;
;		RETURNS:		EDI		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_request_name	DB 'Get Disc Request', 0

get_disc_request	Proc far
	push ds
	push es
	push eax
	push ebx
	push ecx
	push edx
	push esi
;
	mov ax,flat_sel
	mov es,ax
	mov ds,bx
	EnterSection ds:disc_section
	call update_async_write
	call update_async_timer
	call update_disc_seq
	call get_pending
	jnc get_disc_req_ok

get_disc_req_fail:
	LeaveSection ds:disc_section
	stc
	jmp get_disc_req_done

get_disc_req_ok:
	or es:[edi].dh_flags,FLAG_IO_BUSY
	LeaveSection ds:disc_section
	clc
	
get_disc_req_done:
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop es
	pop ds
	ret
get_disc_request	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			new_disc_request
;
;		DESCRIPTION:	Create a new disc request and return the handle
;
;		PARAMETERS:		BX		Disc selector
;						AX		Sector
;						DX		Unit
;
;		RETURNS:		EDI		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

new_disc_request_name	DB 'New Disc Request', 0

new_disc_request	Proc far
	push ds
	push es
	push cx
	push dx
;
	mov ds,bx
	mov cx,flat_sel
	mov es,cx
	mov cx,dx
	mov dx,ax
	EnterSection ds:disc_section
;
	call check_buf
	jnc new_disc_req_fail
;
	cmp dx,ds:disc_sectors_per_unit
	jae new_disc_req_fail
;
	cmp cx,ds:disc_units
	jae new_disc_req_fail
;
	call allocate_handle
	push edx
	call allocate_data
	mov es:[edi].dh_data,edx
	pop edx
	mov es:[edi].dh_buf_sel,ds
	mov es:[edi].dh_sector,dx
	mov es:[edi].dh_unit,cx
	mov es:[edi].dh_wait,0
	mov es:[edi].dh_thread,0
	mov es:[edi].dh_lock_count,0
	mov es:[edi].dh_state,STATE_EMPTY
	mov es:[edi].dh_usage,0
	mov es:[edi].dh_flags,0
	mov es:[edi].dh_time_lsb,0
	mov es:[edi].dh_time_msb,0
	call insert_buf
	LeaveSection ds:disc_section
	clc
	jmp new_disc_req_done

new_disc_req_fail:
	LeaveSection ds:disc_section
	stc

new_disc_req_done:
	pop dx
	pop cx
	pop es
	pop ds
	ret
new_disc_request	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			disc_request_completed
;
;		DESCRIPTION:	Disc request completed
;
;		PARAMETERS:		BX		Disc selector
;						EDI		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_request_completed_name	DB 'Disc Request Completed', 0

disc_request_completed	Proc far
	push ds
	push es
	push eax
	push bx
	push dx
;
	mov ax,flat_sel
	mov es,ax
	mov ds,bx
	EnterSection ds:disc_section
	and es:[edi].dh_flags, NOT (FLAG_IO_PENDING OR FLAG_IO_BUSY)
	xor bx,bx
	xchg bx,es:[edi].dh_thread
	Signal
	mov bx,es:[edi].dh_wait
	or bx,bx
	jz completed_wakeup_done
;
	push ds
	mov ax,disc_data_sel
	mov ds,ax

completed_wakeup_loop:
	push bx
	mov bx,ds:[bx].dws_thread
	Signal
	pop bx
;
	mov dx,ds:[bx].dws_link
	mov ax,ds:drive_wait_free
	mov [bx],ax
	mov ds:drive_wait_free,bx
	mov bx,dx
	or bx,bx
	jnz completed_wakeup_loop
;
	pop ds

completed_wakeup_done:
	LeaveSection ds:disc_section
;
	test es:[edi].dh_flags, FLAG_EXT_DATA
	jz completed_done
;
	cmp es:[edi].dh_lock_count,0
	jnz completed_done
;
	EnterSection ds:disc_section
	call remove_buf
	mov es:[edi].dh_state, STATE_EMPTY
	mov eax,ds:disc_handle_list
	mov es:[edi],eax
	mov ds:disc_handle_list,edi
	LeaveSection ds:disc_section

completed_done:
	xor edi,edi
;
	pop dx
	pop bx
	pop eax
	pop es
	pop ds
	ret
disc_request_completed	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_disc_request_array
;
;		DESCRIPTION:	get a disc request array
;
;		PARAMETERS:		BX		Disc selector
;						ECX		Max number of entries
;
;		RETURNS:		ESI		Disc array
;						ECX		Number of entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_request_array_name	DB 'Get Disc Request Array', 0

get_disc_request_array	Proc far
	push ds
	push es
	push eax
	push ebx
	push edx
	push edi
	push ebp
;
	mov ebp,ecx
	mov ax,flat_sel
	mov es,ax
	mov ds,bx
	EnterSection ds:disc_section
	call update_async_write
	call update_async_timer
	call update_disc_seq
	xor ecx,ecx
	mov edi,ds:disc_pend_list
	or edi,edi
	jz get_disc_req_arr_done
;
	movzx edx,es:[edi].dh_sector
	movzx esi,es:[edi].dh_unit
	mov esi,ds:[4*esi].disc_unit_arr
	lea ebx,[4*edx+esi].disc_sector_arr
	mov edi,es:[4*edx+esi].disc_sector_arr
	or edi,edi
	jz get_disc_req_arr_done
;
	or es:[edi].dh_flags,FLAG_IO_BUSY
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	je get_disc_req_arr_read

get_disc_req_arr_write:
	inc edx
	inc ecx
	cmp ecx,ebp
	jnc get_disc_req_arr_unlink
;
	cmp dx,ds:disc_sectors_per_unit
	jae get_disc_req_arr_unlink
;
	mov edi,es:[4*edx+esi].disc_sector_arr
	or edi,edi
	jz get_disc_req_arr_unlink
;
	mov al,es:[edi].dh_flags
	test al,FLAG_IO_PENDING
	jz get_disc_req_arr_unlink
;
	test al,FLAG_IO_BUSY
	jnz get_disc_req_arr_unlink
;
	mov al,es:[edi].dh_state
	cmp al,STATE_DIRTY
	jne get_disc_req_arr_check_seq
;
	or es:[edi].dh_flags,FLAG_IO_BUSY
	jmp get_disc_req_arr_write

get_disc_req_arr_check_seq:
	cmp al,STATE_SEQ
	je get_disc_req_arr_write
	jmp get_disc_req_arr_unlink

get_disc_req_arr_read:
	inc edx
	inc ecx
	cmp ecx,ebp
	jnc get_disc_req_arr_unlink
;
	cmp dx,ds:disc_sectors_per_unit
	jae get_disc_req_arr_unlink
;
	mov edi,es:[4*edx+esi].disc_sector_arr
	or edi,edi
	jz get_disc_req_arr_unlink
;
	mov al,es:[edi].dh_flags
	test al,FLAG_IO_PENDING
	jz get_disc_req_arr_unlink
;
	test al,FLAG_IO_BUSY
	jnz get_disc_req_arr_unlink
;
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	jne get_disc_req_arr_unlink
;
	or es:[edi].dh_flags,FLAG_IO_BUSY
	jmp get_disc_req_arr_read

get_disc_req_arr_unlink:
	mov esi,ebx
	mov edx,es:[esi]
	mov edi,es:[esi+4*ecx-4]
	mov eax,es:[edi].dh_next
	mov ebx,es:[edx].dh_prev
	mov es:[ebx].dh_next,eax
	mov es:[eax].dh_prev,ebx
	cmp eax,edx
	jne get_disc_req_arr_unlinked
;
	mov ds:disc_pend_list,0
	mov ds:disc_pend_first,0
	clc
	jmp get_disc_req_arr_done

get_disc_req_arr_unlinked:
	mov ds:disc_pend_list,eax
	cmp edx,ds:disc_pend_first
	jne get_disc_req_arr_done
;
	mov ds:disc_pend_first,eax

get_disc_req_arr_done:
	LeaveSection ds:disc_section
	or ecx,ecx
	stc
	jz get_disc_req_arr_end
;
	clc

get_disc_req_arr_end:
	pop ebp
	pop edi
	pop edx
	pop ebx
	pop eax
	pop es
	pop ds
	ret
get_disc_request_array	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_DISC
;
;		DESCRIPTION:	Install disc unit
;
;		PARAMETERS:		BX		Handle
;						ECX		Readahead
;
;		RETURNS:		AL		Disc #
;						BX		Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_disc_name	DB 'Install Disc',0

install_disc	Proc far
	push ds
	push es
	push cx
	push si
	push di
;
	push cx
	mov ax,disc_data_sel
	mov ds,ax
	mov si,OFFSET disc_def_arr
	mov cx,MAX_DRIVES
install_disc_loop:
	mov ax,[si]
	or ax,ax
	jnz install_disc_next
;
	push bx
	mov bx,ds:disc_curr_param
	push dword ptr [bx]
	mov eax,SIZE disc_def_struc
	AllocateSmallGlobalMem
	xor di,di
	mov cx,ax
	xor al,al
	rep stosb
	mov [si],es
	mov ax,es
	mov ds,ax
	mov ax,si
	sub ax,OFFSET disc_def_arr
	shr ax,1
	mov ds:disc_nr,al
	mov ds:disc_handle_list,0
	mov ds:disc_data_list,0
	mov ds:disc_pend_list,0
	mov ds:disc_pend_first,0
	mov ds:disc_awrite_list,0
	mov ds:disc_awrite_timer,0
	mov ds:disc_awrite_timeout,0
	mov ds:disc_awrite_timeout+4,0
	mov ds:disc_seq_list,0
	mov ds:disc_free,0
	mov ds:disc_timer_id,0
	mov ds:disc_thread,0
	mov ds:disc_change_proc,0
	pop ds:disc_param
	pop ds:disc_handle
	pop cx
	mov ds:disc_readahead,ecx
	InitSection ds:disc_section
	mov bx,ds
	mov al,ds:disc_nr
	clc
	jmp install_disc_done

install_disc_next:
	add si,2
	sub cx,1
	jnz install_disc_loop
	add sp,2
	stc

install_disc_done:
	pop di
	pop si
	pop cx
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
;						ECX		Sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_drive_name	DB 'Open Drive',0

open_drive	Proc far
	push ds
	push es
	push bx
	push si
	push di
;
	push ax
	mov ax,disc_data_sel
	mov ds,ax
;
	mov eax,SIZE drive_def_struc
	AllocateSmallGlobalMem
	mov es:drive_start_sector,edx
	mov es:drive_sectors,ecx
	pop ax
	movzx bx,ah
	shl bx,1
	mov bx,ds:[bx].disc_def_arr
	mov es:drive_disc,bx
;
	movzx si,al
	shl si,1
	mov [si].drive_def_arr,es
;
	mov ds,bx
	mov di,word ptr ds:disc_change_proc+2
	or di,di
	jz open_drive_done
;
	mov es,di
	mov di,word ptr ds:disc_change_proc
	mov bx,ds:disc_handle
	DefineMediaCheck

open_drive_done:
	clc
;
	pop di
	pop si
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
	FlushDrive
	ret
close_drive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FlushDrive
;
;		DESCRIPTION:	Flush drive
;
;		PARAMETERS:		AL		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_drive_name	DB 'Flush Drive',0

flush_drive	Proc far
	push ds
	push es
	pushad
;
	movzx bx,al
	shl bx,1
	mov ax,disc_data_sel
	mov ds,ax
	mov ds,ds:[bx].drive_def_arr
	mov ax,flat_sel
	mov es,ax
	mov edx,ds:drive_start_sector
	mov ecx,ds:drive_sectors
	mov ds,ds:drive_disc
;
	EnterSection ds:disc_section
	movzx ebp,ds:disc_sectors_per_unit
	push edx
	pop ax
	pop dx
	div bp
	movzx esi,ax
	movzx ebx,dx

flush_loop:
	mov edx,ds:[4*esi].disc_unit_arr
	or edx,edx
	jz flush_next_unit
;
	push ecx
	lea edi,[4*ebx+edx].disc_sector_arr
	mov eax,ebp
	sub eax,ebx
	cmp eax,ecx
	ja flush_sector_loop
;
	mov ecx,eax

flush_sector_loop:
	xor eax,eax
	repe scas dword ptr es:[edi]
	sub edi,4
	xchg eax,es:[edi]
	or eax,eax
	jz flush_unit_done
;
	push edi
	mov edi,eax
	call free_handle
	pop edi
	sub es:[edx].disc_sectors,1
	jnz flush_sector_loop
;
	mov ds:[4*esi].disc_unit_arr,0
	movzx ecx,ds:disc_sectors_per_unit
	shl ecx,2
	add ecx,OFFSET disc_sector_arr
	FreeLinear
	xor ecx,ecx

flush_unit_done:
	mov eax,ebp
	sub eax,ebx
	sub eax,ecx
	pop ecx
	sub ecx,eax
	jz flush_leave
;
	xor ebx,ebx
	inc esi
	jmp flush_loop

flush_next_unit:
	mov edx,ebp
	sub edx,ebx
	sub ecx,edx
	jbe flush_leave
;
	xor ebx,ebx
	inc esi
	jmp flush_loop

flush_next:
	inc ebx
	cmp si,ds:disc_sectors_per_unit
	jne flush_unit_ok

flush_adv_unit:
	xor esi,esi
	inc ebx

flush_unit_ok:
	sub ecx,1
	jnz flush_loop

flush_leave:
	LeaveSection ds:disc_section
;
	popad
	pop es
	pop ds
	ret
flush_drive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDriveParam
;
;		DESCRIPTION:	Get drive param
;
;		PARAMETERS:		AL		Drive #
;
;		RETURNS:		EAX		Readahead
;						ECX		Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_drive_param_name	DB 'Get Drive Param',0

get_drive_param	PROC far
	push ds
	push bx
	push edx
;
	cmp al,MAX_DRIVES
	jnc get_drive_param_fail
;
	movzx bx,al
	shl bx,1
	mov ax,disc_data_sel
	mov ds,ax
	mov ax,ds:[bx].drive_def_arr
	cmp ax,-1
	je get_drive_param_fail
;
	mov ds,ax
	mov ax,ds:drive_disc
	or ax,ax
	jz get_drive_param_fail
;
	mov ds,ax
	mov ax,ds:disc_bytes_per_sector
	mov dx,ds:disc_sectors_per_unit
	mul dx
	push dx
	push ax
	pop eax
	movzx edx,ds:disc_units
	mul edx
	or edx,edx
	jz get_param_size_ok
;
	mov eax,-1

get_param_size_ok:
	mov ecx,eax
	mov eax,ds:disc_readahead
	clc
	jmp get_drive_param_done

get_drive_param_fail:
	xor eax,eax
	xor ecx,ecx
	stc

get_drive_param_done:
	pop edx
	pop bx
	pop ds
	ret
get_drive_param	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NEW_SECTOR
;
;		DESCRIPTION:	Create a new sector cache entry without reading
;
;		PARAMETERS:		AL		Drive #
;						EDX		Sector #
;
;		RETURNS:		EBX		Handle
;						ESI		Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

new_sector_name	DB 'New Sector',0

new_sector	PROC far
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
	cmp edx,ds:drive_sectors
	jc new_inrange
;
	int 3
	stc
	jmp new_leave

new_inrange:
	add edx,ds:drive_start_sector
	mov ds,ds:drive_disc
	push edx
	pop ax
	pop dx
	div ds:disc_sectors_per_unit
	mov cx,ax
	EnterSection ds:disc_section

new_loop:
	call check_buf
	jnc new_done
;
	call allocate_handle
	push edx
	call allocate_data
	mov es:[edi].dh_data,edx
	pop edx
	mov es:[edi].dh_buf_sel,ds
	mov es:[edi].dh_sector,dx
	mov es:[edi].dh_unit,cx
	mov es:[edi].dh_wait,0
	mov es:[edi].dh_thread,0
	mov es:[edi].dh_lock_count,0
	mov es:[edi].dh_state,STATE_USED
	mov es:[edi].dh_usage,0
	mov es:[edi].dh_flags,0
	mov es:[edi].dh_time_lsb,0
	mov es:[edi].dh_time_msb,0
	call insert_buf

new_done:
	LeaveSection ds:disc_section
	mov esi,es:[edi].dh_data
	mov ebx,edi

new_leave:
	pop edi
	pop edx
	pop cx
	pop ax
	pop es
	pop ds
	ret
new_sector	ENDP

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
	cmp edx,ds:drive_sectors
	jc lock_inrange
;
	int 3
	stc
	jmp lock_done

lock_inrange:
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
;
	ClearSignal
	call allocate_handle
	push edx
	call allocate_data
	mov es:[edi].dh_data,edx
	pop edx
	mov es:[edi].dh_buf_sel,ds
	mov es:[edi].dh_sector,dx
	mov es:[edi].dh_unit,cx
	mov es:[edi].dh_wait,0
	mov es:[edi].dh_thread,0
	mov es:[edi].dh_lock_count,0
	mov es:[edi].dh_state,STATE_EMPTY
	mov es:[edi].dh_usage,0
	mov es:[edi].dh_flags,0
	mov es:[edi].dh_time_lsb,0
	mov es:[edi].dh_time_msb,0
	mov es:[edi].dh_flags,0
	call insert_buf
	call insert_pending

lock_read_ahead:
	push dx
	push edi
	inc dx
	cmp dx,ds:disc_sectors_per_unit
	je lock_read_ahead_done
;
	call check_buf
	jnc lock_read_ahead_done
	jmp lock_read_ahead_done
;
	call allocate_handle
	push edx
	call allocate_data
	mov es:[edi].dh_data,edx
	pop edx
	mov es:[edi].dh_buf_sel,ds
	mov es:[edi].dh_sector,dx
	mov es:[edi].dh_unit,cx
	mov es:[edi].dh_wait,0
	mov es:[edi].dh_thread,0
	mov es:[edi].dh_lock_count,0
	mov es:[edi].dh_state,STATE_EMPTY
	mov es:[edi].dh_usage,0
	mov es:[edi].dh_flags,FLAGS_READ_AHEAD
	mov es:[edi].dh_time_lsb,0
	mov es:[edi].dh_time_msb,0
	call insert_buf
	call insert_pending
	
lock_read_ahead_done:
	pop edi
	pop dx

lock_read_signal:
	test es:[edi].dh_flags,FLAGS_READ_AHEAD
	jz lock_read_check_empty
;
	and es:[edi].dh_flags, NOT FLAGS_READ_AHEAD
	jmp lock_read_ahead

lock_read_check_empty:
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	clc
	jne lock_found

lock_read_block:
	call block
	jmp lock_loop

lock_found:
	test es:[edi].dh_flags, FLAG_IO_BUSY
	jnz lock_read_block
;
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	je lock_read_signal
;	
	inc es:[edi].dh_lock_count
	inc es:[edi].dh_usage
	LeaveSection ds:disc_section
	mov al,es:[edi].dh_state
	cmp al,STATE_USED
	je lock_get_adds
;
	cmp al,STATE_DIRTY
	je lock_get_adds
;
	cmp al,STATE_SEQ
	je lock_get_adds
;
	stc
	jmp lock_done

lock_get_adds:
	mov esi,es:[edi].dh_data
	mov ebx,edi

lock_done:
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
;		PARAMETERS:		EBX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

modify_sector_name	DB 'Modify Sector',0

modify_sector	PROC far
	push ds
	push es
	pushad
;
	mov ax,flat_sel
	mov es,ax
	mov edi,ebx
	mov ds,es:[edi].dh_buf_sel
	ClearSignal
	EnterSection ds:disc_section

modify_try_again:
	test es:[edi].dh_flags, FLAG_IO_BUSY
	jz modify_not_busy
;
	call block
	jmp modify_try_again

modify_not_busy:
	mov al,es:[edi].dh_state
	cmp al,STATE_USED
	jne modify_done

modify_clean:
	GetSystemTime
	mov es:[edi].dh_time_lsb,eax
	mov es:[edi].dh_time_msb,dx
	mov es:[edi].dh_state,STATE_DIRTY
	call insert_async_write
	call update_async_timer

modify_done:
	LeaveSection ds:disc_section
	clc
;
	popad
	pop es
	pop ds
	ret
modify_sector	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_DISC_SEQ
;
;		DESCRIPTION:	Create a sequence
;
;		PARAMETERS:		CX		Max number of sectors in sequence
;
;		RETURNS:		AX		Sequence handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_disc_seq_name	DB 'Create Disc Seq',0

create_disc_seq	PROC far
	push es
	push cx
	push di
;
	movzx eax,cx
	lea eax,[4*eax].dss_arr
	AllocateSmallGlobalMem
	mov di,OFFSET dss_arr
	xor eax,eax
	rep stos dword ptr es:[edi]
	mov es:dss_buf_sel,0
	mov es:dss_insert_index,0
	mov es:dss_perform_index,0
	mov ax,es
;
	pop di
	pop cx
	pop es
	ret
create_disc_seq	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MODIFY_SEQ_SECTOR
;
;		DESCRIPTION:	Modify sequential sector contents
;
;		PARAMETERS:		AX			Seq handle
;						EBX			Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

modify_seq_sector_name	DB 'Modify Seq Sector',0

modify_seq_sector	PROC far
	push ds
	push es
	push fs
	pushad
;
	mov fs,ax
	mov ax,flat_sel
	mov es,ax
	mov edi,ebx
	mov ds,es:[edi].dh_buf_sel
	ClearSignal
	EnterSection ds:disc_section

modify_seq_try_again:
	test es:[edi].dh_flags, FLAG_IO_BUSY
	jz modify_seq_not_busy

modify_seq_block:
	call block
	jmp modify_seq_try_again

modify_seq_not_busy:
	mov al,es:[edi].dh_state
	cmp al,STATE_USED
	jne modify_seq_block

modify_seq_clean:
	mov es:[edi].dh_state,STATE_SEQ
	mov bx,fs:dss_insert_index
	shl bx,2
	mov fs:[bx].dss_arr,edi
	inc fs:dss_insert_index
	mov fs:dss_buf_sel,ds

modify_seq_done:
	LeaveSection ds:disc_section
	clc
;
	popad
	pop fs
	pop es
	pop ds
	ret
modify_seq_sector	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PERFORM_DISC_SEQ
;
;		DESCRIPTION:	Perform a sequence
;
;		PARAMETERS:		AX			Sequence handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_disc_seq_name	DB 'Perform Disc Seq',0

perform_disc_seq	PROC far
	push ds
	push es
	push eax
	push ebx
;
	int 3
	mov es,ax
	mov ax,es:dss_buf_sel
	or ax,ax
	jz perform_disc_fail
;
	mov ds,ax
	EnterSection ds:disc_section
;
	mov bx,ds:disc_seq_list
	or bx,bx
	je perform_disc_empty
;
	push ds
	push si
	mov ds,bx
	mov si,ds:dss_prev
	mov ds:dss_prev,es
	mov ds,si
	mov ds:dss_next,es
	mov es:dss_next,bx
	mov es:dss_prev,si
	pop si
	pop ds
	jmp perform_disc_do

perform_disc_empty:
	mov es:dss_next,es
	mov es:dss_prev,es
	mov ds:disc_seq_list,es

perform_disc_do:
	mov ax,flat_sel
	mov es,ax
	call update_disc_seq
	jmp perform_disc_leave

perform_disc_fail:
	FreeMem
	jmp perform_disc_done

perform_disc_leave:
	LeaveSection ds:disc_section
	mov bx,ds:disc_thread
	Signal

perform_disc_done:
	pop ebx
	pop eax
	pop es
	pop ds
	ret
perform_disc_seq	ENDP

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
	push ds
	push es
	push eax
	push edi
;
	mov ax,flat_sel
	mov es,ax
	mov edi,ebx
	mov ds,es:[edi].dh_buf_sel
	EnterSection ds:disc_section
;
	sub es:[edi].dh_lock_count,1
	jnz unlock_done
;
	test es:[edi].dh_flags, FLAG_EXT_DATA
	jz unlock_done
;
	cmp es:[edi].dh_state, STATE_USED
	jne unlock_done
;
	call remove_buf
	mov es:[edi].dh_state, STATE_EMPTY
	mov eax,ds:disc_handle_list
	mov es:[edi],eax
	mov ds:disc_handle_list,edi

unlock_done:
	LeaveSection ds:disc_section
	xor ebx,ebx
;
	pop edi
	pop eax
	pop es
	pop ds
	clc
	ret
unlock_sector	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReqSector
;
;		DESCRIPTION:	Request a sector, but don't block
;
;		PARAMETERS:		AL		Drive #
;						EDX		Sector #
;						ESI		Logical address of buffer
;
;		RETURNS:		EBX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_sector_name	DB 'Req Sector',0

req_sector	PROC far
	push ds
	push es
	push ax
	push ecx
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
	cmp edx,ds:drive_sectors
	jc req_inrange
;
	int 3
	stc
	jmp req_done

req_inrange:
	add edx,ds:drive_start_sector
	mov ds,ds:drive_disc
	push edx
	pop ax
	pop dx
	div ds:disc_sectors_per_unit
	mov cx,ax
	EnterSection ds:disc_section

req_loop:
	call check_buf
	jnc req_found
;
	call allocate_handle
	mov es:[edi].dh_data,esi
	mov es:[edi].dh_buf_sel,ds
	mov es:[edi].dh_sector,dx
	mov es:[edi].dh_unit,cx
	mov es:[edi].dh_wait,0
	mov es:[edi].dh_thread,0
	mov es:[edi].dh_lock_count,0
	mov es:[edi].dh_state,STATE_EMPTY
	mov es:[edi].dh_usage,0
	mov es:[edi].dh_time_lsb,0
	mov es:[edi].dh_time_msb,0
	mov es:[edi].dh_flags,FLAG_EXT_DATA
	call insert_buf
	call insert_pending
	jmp req_ok

req_read_signal:
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	clc
	jne req_found

req_read_block:
	call block
	jmp req_loop

req_found:
	test es:[edi].dh_flags, FLAG_IO_BUSY
	jnz req_read_block
;
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	je req_read_signal
;
	mov edx,es:[edi].dh_data
	cmp edx,esi
	je req_ok
;
	or edx,edx
	jz req_new_save
;
	movzx ecx,ds:disc_bytes_per_sector
	shr ecx,2
	push esi
	push edi
	mov edi,esi
	mov esi,edx
	rep movs dword ptr es:[edi],es:[esi]
	pop edi
	pop esi
;
	test es:[edi].dh_flags, FLAG_EXT_DATA
	jnz req_new_save
;
	call free_data

req_new_save:
	mov es:[edi].dh_data,esi
	or es:[edi].dh_flags,FLAG_EXT_DATA
	
req_ok:
	inc es:[edi].dh_lock_count
	inc es:[edi].dh_usage
	LeaveSection ds:disc_section
;
	mov bx,ds:disc_thread
	Signal
	clc
	mov ebx,edi

req_done:
	pop edi
	pop edx
	pop ecx
	pop ax
	pop es
	pop ds
	ret
req_sector	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DefineSector
;
;		DESCRIPTION:	Define sector contents, don't block or read
;
;		PARAMETERS:		AL		Drive #
;						EDX		Sector #
;						ESI		Logical address of buffer
;
;		RETURNS:		EBX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_sector_name	DB 'Define Sector',0

define_sector	PROC far
	push ds
	push es
	push ax
	push ecx
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
	cmp edx,ds:drive_sectors
	jc define_inrange
;
	int 3
	stc
	jmp define_done

define_inrange:
	add edx,ds:drive_start_sector
	mov ds,ds:drive_disc
	push edx
	pop ax
	pop dx
	div ds:disc_sectors_per_unit
	mov cx,ax
	EnterSection ds:disc_section

define_loop:
	call check_buf
	jnc define_found
;
	ClearSignal
	call allocate_handle
	mov es:[edi].dh_data,esi
	mov es:[edi].dh_buf_sel,ds
	mov es:[edi].dh_sector,dx
	mov es:[edi].dh_unit,cx
	mov es:[edi].dh_wait,0
	mov es:[edi].dh_thread,0
	mov es:[edi].dh_lock_count,0
	mov es:[edi].dh_state,STATE_USED
	mov es:[edi].dh_usage,0
	mov es:[edi].dh_time_lsb,0
	mov es:[edi].dh_time_msb,0
	mov es:[edi].dh_flags,FLAG_EXT_DATA
	call insert_buf
	jmp define_found

define_read_signal:
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	clc
	jne define_found

define_read_block:
	call block
	jmp define_loop

define_found:
	test es:[edi].dh_flags, FLAG_IO_BUSY
	jnz define_read_block
;
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	je define_read_signal
;
	mov edx,es:[edi].dh_data
	cmp edx,esi
	je define_ok
;
	or edx,edx
	jz define_new_save
;
	movzx ecx,ds:disc_bytes_per_sector
	shr ecx,2
	push esi
	push edi
	mov edi,esi
	mov esi,edx
	rep movs dword ptr es:[edi],es:[esi]
	pop edi
	pop esi
;
	test es:[edi].dh_flags, FLAG_EXT_DATA
	jnz define_new_save
;
	call free_data

define_new_save:
	mov es:[edi].dh_data,esi
	or es:[edi].dh_flags,FLAG_EXT_DATA
	
define_ok:
	inc es:[edi].dh_lock_count
	inc es:[edi].dh_usage
	LeaveSection ds:disc_section
	mov al,es:[edi].dh_state
	cmp al,STATE_USED
	je define_valid
;
	cmp al,STATE_DIRTY
	je define_valid
;
	cmp al,STATE_SEQ
	je define_valid
;
	stc
	jmp define_done

define_valid:
	mov ebx,edi
	clc

define_done:
	pop edi
	pop edx
	pop ecx
	pop ax
	pop es
	pop ds
	ret
define_sector	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitForSector
;
;		DESCRIPTION:	Wait until sector is available
;
;		PARAMETERS:		AL		Drive #
;						EBX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_sector_name	DB 'Wait For Sector',0

wait_for_sector	PROC far
	push ds
	push es
	push ax
	push edi
;
	mov ax,flat_sel
	mov es,ax
	mov edi,ebx
	mov ds,es:[edi].dh_buf_sel
	EnterSection ds:disc_section

wait_sector_loop:
	cmp es:[edi].dh_state,STATE_EMPTY
	clc
	jne wait_sector_found
;
	call block
	jmp wait_sector_loop

wait_sector_found:
	LeaveSection ds:disc_section
	clc
;
	pop edi
	pop ax
	pop es
	pop ds
	ret
wait_for_sector	ENDP

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
;		NAME:			GET_DISC_INFO
;
;		DESCRIPTION:	Get disc info
;
;		PARAMETERS:		AL			Disc #
;
;		RETURNS;		CX			Bytes / sector
;						EDX			Total sectors
;						SI			BIOS sectors / cylinder
;						DI			BIOS heads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_info_name	DB 'Get Disc Info',0

get_disc_info	PROC far
	push ds
	push ax
	push bx
;
	cmp al,MAX_DRIVES
	jae get_disc_info_fail
;
	mov bx,disc_data_sel
	mov ds,bx
	movzx bx,al
	add bx,bx
	mov bx,ds:[bx].disc_def_arr
	or bx,bx
	jz get_disc_info_fail
;
	mov ds,bx
	mov ax,ds:disc_units
	mul ds:disc_sectors_per_unit
	push dx
	push ax
	pop edx
	mov cx,ds:disc_bytes_per_sector
	mov si,ds:disc_sectors_per_cyl
	mov di,ds:disc_heads
	clc
	jmp get_disc_info_done

get_disc_info_fail:
	xor cx,cx
	xor edx,edx
	xor si,si
	xor di,di
	stc

get_disc_info_done:
	pop bx
	pop ax
	pop ds	
	retf32
get_disc_info	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			READ_DISC
;
;		DESCRIPTION:	Read disc
;
;		PARAMETERS:		AL			Disc #
;						EDX			Sector #
;						(E)CX		Size
;						ES:(E)DI	Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_disc_name	DB 'Read Disc',0

read_disc	PROC near
	push ds
	push es
	pushad
;
	cmp al,MAX_DRIVES
	jae read_disc_fail
;
	mov bx,disc_data_sel
	mov ds,bx
	movzx bx,al
	add bx,bx
	mov bx,ds:[bx].disc_def_arr
	or bx,bx
	jz read_disc_fail
;
	mov ds,bx
	push ds
	push es
	push ecx
	push edi
;
	mov ax,flat_sel
	mov es,ax
	push edx
	pop ax
	pop dx
	div ds:disc_sectors_per_unit
	mov cx,ax
	EnterSection ds:disc_section

read_disc_loop:
	call check_buf
	jnc read_disc_found
;
	ClearSignal
	call allocate_handle
	push edx
	call allocate_data
	mov es:[edi].dh_data,edx
	pop edx
	mov es:[edi].dh_buf_sel,ds
	mov es:[edi].dh_sector,dx
	mov es:[edi].dh_unit,cx
	mov es:[edi].dh_wait,0
	mov es:[edi].dh_thread,0
	mov es:[edi].dh_lock_count,0
	mov es:[edi].dh_state,STATE_EMPTY
	mov es:[edi].dh_usage,0
	mov es:[edi].dh_flags,0
	mov es:[edi].dh_time_lsb,0
	mov es:[edi].dh_time_msb,0
	mov es:[edi].dh_flags,0
	call insert_buf
	call insert_pending

read_disc_signal:
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	clc
	jne read_disc_found

read_disc_block:
	call block
	jmp read_disc_loop

read_disc_found:
	test es:[edi].dh_flags, FLAG_IO_BUSY
	jnz read_disc_block
;
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	je read_disc_signal
;	
	mov esi,es:[edi].dh_data
	mov ax,es
	mov ds,ax
	pop edi
	pop ecx
	pop es
;
	shr ecx,2
	rep movs dword ptr es:[edi],[esi]
	pop ds
	LeaveSection ds:disc_section
	clc
	jmp read_disc_done

read_disc_fail:
	stc

read_disc_done:
	popad
	pop es
	pop ds
	ret
read_disc	ENDP

read_disc32	Proc far
	call read_disc
	retf32
read_disc32	Endp

read_disc16	Proc far
	push ecx
	push edi
;
	movzx ecx,cx
	movzx edi,di
	call read_disc
;
	pop edi
	pop ecx
	ret
read_disc16	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WRITE_DISC
;
;		DESCRIPTION:	Write disc
;
;		PARAMETERS:		AL			Disc #
;						EDX			Sector #
;						(E)CX		Size
;						ES:(E)DI	Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_disc_name	DB 'Write Disc',0

write_disc	PROC near
	push ds
	push es
	pushad
;
	cmp al,MAX_DRIVES
	jae write_disc_fail
;
	mov bx,disc_data_sel
	mov ds,bx
	movzx bx,al
	add bx,bx
	mov bx,ds:[bx].disc_def_arr
	or bx,bx
	jz write_disc_fail
;
	mov ds,bx
	push ds
	push es
	push ecx
	push edi
;
	mov ax,flat_sel
	mov es,ax
	push edx
	pop ax
	pop dx
	div ds:disc_sectors_per_unit
	mov cx,ax
	EnterSection ds:disc_section

write_disc_loop:
	call check_buf
	jnc write_disc_found
;
	ClearSignal
	call allocate_handle
	push edx
	call allocate_data
	mov es:[edi].dh_data,edx
	pop edx
	mov es:[edi].dh_buf_sel,ds
	mov es:[edi].dh_sector,dx
	mov es:[edi].dh_unit,cx
	mov es:[edi].dh_wait,0
	mov es:[edi].dh_thread,0
	mov es:[edi].dh_lock_count,0
	mov es:[edi].dh_state,STATE_EMPTY
	mov es:[edi].dh_usage,0
	mov es:[edi].dh_flags,0
	mov es:[edi].dh_time_lsb,0
	mov es:[edi].dh_time_msb,0
	mov es:[edi].dh_flags,0
	call insert_buf
	call insert_pending

write_disc_signal:
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	clc
	jne write_disc_found

write_disc_block:
	call block
	jmp write_disc_loop

write_disc_found:
	test es:[edi].dh_flags, FLAG_IO_BUSY
	jnz write_disc_block
;
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	je write_disc_signal
;	
	mov ebx,edi
	mov edi,es:[edi].dh_data
	pop esi
	pop ecx
	pop ds
;
	shr ecx,2
	rep movs dword ptr es:[edi],[esi]
;
	mov edi,ebx
	pop ds
	GetSystemTime
	mov es:[edi].dh_time_lsb,eax
	mov es:[edi].dh_time_msb,dx
	mov es:[edi].dh_state,STATE_DIRTY
	call insert_async_write
	call update_async_timer
	LeaveSection ds:disc_section
	clc
	jmp write_disc_done

write_disc_fail:
	stc

write_disc_done:
	popad
	pop es
	pop ds
	ret
write_disc	ENDP

write_disc32	Proc far
	call write_disc
	retf32
write_disc32	Endp

write_disc16	Proc far
	push ecx
	push edi
;
	movzx ecx,cx
	movzx edi,di
	call write_disc
;
	pop edi
	pop ecx
	ret
write_disc16	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FormatDrive
;
;		DESCRIPTION:	Format a drive
;
;		PARAMETERS:		AL			Disc #
;						EDX			Start sector
;						ECX			Number of sectors
;						ES:(E)DI	FS name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

format_drive_name	DB 'Format Drive',0

format_drive	Proc near
	push ds
	push es
	push fs
	pushad
;
	push ax
	mov ax,es
	mov ds,ax
	mov esi,edi
	mov eax,10h
	AllocateSmallGlobalMem
	xor edi,edi
	movs dword ptr es:[edi],[esi]
	movs dword ptr es:[edi],[esi]
	movs dword ptr es:[edi],[esi]
	movs dword ptr es:[edi],[esi]
	pop ax
	xor di,di
	IsFileSystemAvailable
	jc format_fail
;
	mov bx,disc_data_sel
	mov ds,bx
	movzx di,al
	shl di,1
	mov di,ds:[di].disc_def_arr
	mov si,OFFSET drive_def_arr
	mov bp,MAX_DRIVES

format_find_drive_loop:
	mov bx,[si]
	or bx,bx
	je format_find_drive_next
;
	cmp bx,-1
	je format_find_drive_next
;
	mov fs,bx
	cmp di,fs:drive_disc
	jne format_find_drive_next
;
	mov ebx,edx
	sub ebx,fs:drive_start_sector
	jz format_drive_found
	ja format_find_drive_above

format_find_drive_below:
	add ebx,fs:drive_sectors
	jc format_fail
	jmp format_find_drive_next

format_find_drive_above:
	sub ebx,fs:drive_sectors
	jc format_fail

format_find_drive_next:
	add si,2
	sub bp,1
	jnz format_find_drive_loop
;
	mov ah,al
	AllocateStaticDrive
	OpenDrive
	jmp format_do

format_drive_found:
	sub si,OFFSET drive_def_arr
	mov ax,si
	shr al,1
	FlushDrive

format_do:
	cmp ecx,fs:drive_sectors
	jbe format_perf
;
	mov ecx,fs:drive_sectors

format_perf:
	xor di,di
	FormatFileSystem
	jc format_fail
;
	FreeMem
	clc
	jmp format_done

format_fail:
	FreeMem
	stc

format_done:
	popad
	pop fs
	pop es
	pop ds
	ret
format_drive	Endp

format_drive32	Proc far
	call format_drive
	retf32
format_drive32	Endp

format_drive16	Proc far
	push edi
	movzx edi,di
	call format_drive
	pop edi
	ret
format_drive16	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HOOK_INIT_DISC
;
;		DESCRIPTION:	Add an InitDisc hook
;
;		PARAMETERS:		ES:DI		Parameter block
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
	mov al,ds:disc_params
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET disc_param_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:disc_params,al
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
;		NAME:			RUN_DISC_ASSIGN
;
;		DESCRIPTION:	Run all disc-assign hooks
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_disc_assign	Proc near
	push ds
	push ax
	push bx
	push cx
;
	mov ax,disc_data_sel
	mov ds,ax
	movzx cx,ds:disc_params
	mov bx,OFFSET disc_param_arr
	jcxz run_disc_assign_done

run_disc_assign_loop:
	push ds
	push bx
	push cx
	mov ds:disc_curr_param,bx
	lds bx,[bx]
	call [bx].disc_assign_proc
	pop cx
	pop bx
	pop ds
	add bx,4
	loop run_disc_assign_loop	

run_disc_assign_done:
	pop cx
	pop bx
	pop ax
	pop ds	
	ret
run_disc_assign	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RUN_DRIVE_ASSIGN1
;
;		DESCRIPTION:	Run drive assign pass 1 for all discs
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_drive_assign1	Proc near
	push ds
	push ax
	push bx
	push cx
	push si
;
	mov ax,disc_data_sel
	mov ds,ax
	xor si,si
	mov cx,MAX_DRIVES

run_drive_assign1_loop:
	mov bx,[si].disc_def_arr
	or bx,bx
	jz run_drive_assign1_next
;
	push ds
	push bx
	push cx
	push si
;
	mov ds,bx
	mov bx,ds:disc_handle
	lds si,ds:disc_param
	call [si].drive_assign1_proc
;
	pop si
	pop cx
	pop bx
	pop ds

run_drive_assign1_next:
	add si,2
	sub cx,1
	jnz run_drive_assign1_loop
;
	pop si
	pop cx
	pop bx
	pop ax
	pop ds
	ret
run_drive_assign1	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RUN_DRIVE_ASSIGN2
;
;		DESCRIPTION:	Run drive assign pass 2 for all discs
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_drive_assign2	Proc near
	push ds
	push ax
	push bx
	push cx
	push si
;
	mov ax,disc_data_sel
	mov ds,ax
	xor si,si
	mov cx,MAX_DRIVES

run_drive_assign2_loop:
	mov bx,[si].disc_def_arr
	or bx,bx
	jz run_drive_assign2_next
;
	push ds
	push bx
	push cx
	push si
;
	mov ds,bx
	mov bx,ds:disc_handle
	lds si,ds:disc_param
	call [si].drive_assign2_proc
;
	pop si
	pop cx
	pop bx
	pop ds

run_drive_assign2_next:
	add si,2
	sub cx,1
	jnz run_drive_assign2_loop
;
	pop si
	pop cx
	pop bx
	pop ax
	pop ds
	ret
run_drive_assign2	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DEMAND_LOAD_DRIVE
;
;		DESCRIPTION:	Run demand-load for disc exporting drive
;
;		PARAMETERS:		AL		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

demand_load_drive_name	DB 'Demand Load Drive', 0

demand_load_drive	Proc far
	push ds
	pushad
;
	mov bx,disc_data_sel
	mov ds,bx
	movzx bx,al
	add bx,bx
	mov ax,[bx].drive_def_arr
	or ax,ax
	jz demand_load_drive_fail
;
	cmp ax,-1
	je demand_load_drive_fail
;
	mov ds,ax
	mov ds,ds:drive_disc
	mov bx,ds:disc_handle
	lds si,ds:disc_param
	call [si].demand_mount_proc
	jmp demand_load_drive_done

demand_load_drive_fail:
	stc

demand_load_drive_done:
	popad
	pop ds
	ret
demand_load_drive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_DISC
;
;		DESCRIPTION:	Init discs
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_disc	Proc far
	call run_disc_assign
	call run_drive_assign1
	call run_drive_assign2
	ret
init_disc	Endp

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
	mov si,OFFSET set_disc_param
	mov di,OFFSET set_disc_param_name
	mov ax,set_disc_param_nr
	RegisterOsGate
;
	mov si,OFFSET register_disc_change
	mov di,OFFSET register_disc_change_name
	mov ax,register_disc_change_nr
	RegisterOsGate
;
	mov si,OFFSET start_disc
	mov di,OFFSET start_disc_name
	mov ax,start_disc_nr
	RegisterOsGate
;
	mov si,OFFSET stop_disc
	mov di,OFFSET stop_disc_name
	mov ax,stop_disc_nr
	RegisterOsGate
;
	mov si,OFFSET wait_for_disc_request
	mov di,OFFSET wait_for_disc_request_name
	mov ax,wait_for_disc_request_nr
	RegisterOsGate
;
	mov si,OFFSET poll_disc_request
	mov di,OFFSET poll_disc_request_name
	mov ax,poll_disc_request_nr
	RegisterOsGate
;
	mov si,OFFSET get_disc_request
	mov di,OFFSET get_disc_request_name
	mov ax,get_disc_request_nr
	RegisterOsGate
;
	mov si,OFFSET new_disc_request
	mov di,OFFSET new_disc_request_name
	mov ax,new_disc_request_nr
	RegisterOsGate
;
	mov si,OFFSET disc_request_completed
	mov di,OFFSET disc_request_completed_name
	mov ax,disc_request_completed_nr
	RegisterOsGate
;
	mov si,OFFSET get_disc_request_array
	mov di,OFFSET get_disc_request_array_name
	mov ax,get_disc_request_array_nr
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
	mov si,OFFSET demand_load_drive
	mov di,OFFSET demand_load_drive_name
	mov ax,demand_load_drive_nr
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
	mov si,OFFSET flush_drive
	mov di,OFFSET flush_drive_name
	mov ax,flush_drive_nr
	RegisterOsGate
;
	mov si,OFFSET new_sector
	mov di,OFFSET new_sector_name
	mov ax,new_sector_nr
	RegisterOsGate
;
	mov si,OFFSET get_drive_param
	mov di,OFFSET get_drive_param_name
	mov ax,get_drive_param_nr
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
	mov si,OFFSET create_disc_seq
	mov di,OFFSET create_disc_seq_name
	mov ax,create_disc_seq_nr
	RegisterOsGate
;
	mov si,OFFSET modify_seq_sector
	mov di,OFFSET modify_seq_sector_name
	mov ax,modify_seq_sector_nr
	RegisterOsGate
;
	mov si,OFFSET perform_disc_seq
	mov di,OFFSET perform_disc_seq_name
	mov ax,perform_disc_seq_nr
	RegisterOsGate
;
	mov si,OFFSET req_sector
	mov di,OFFSET req_sector_name
	mov ax,req_sector_nr
	RegisterOsGate
;
	mov si,OFFSET define_sector
	mov di,OFFSET define_sector_name
	mov ax,define_sector_nr
	RegisterOsGate
;
	mov si,OFFSET wait_for_sector
	mov di,OFFSET wait_for_sector_name
	mov ax,wait_for_sector_nr
	RegisterOsGate
;
	mov si,OFFSET reset_drive
	mov di,OFFSET reset_drive_name
	mov ax,reset_drive_nr
	RegisterOsGate
;
	mov si,OFFSET get_disc_info
	mov di,OFFSET get_disc_info_name
	xor dx,dx
	mov ax,get_disc_info_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET format_drive16
	mov si,OFFSET format_drive32
	mov di,OFFSET format_drive_name
	mov dx,virt_es_in
	mov ax,format_drive_nr
	RegisterUserGate
;
	mov bx,OFFSET read_disc16
	mov si,OFFSET read_disc32
	mov di,OFFSET read_disc_name
	mov dx,virt_es_in
	mov ax,read_disc_nr
	RegisterUserGate
;
	mov bx,OFFSET write_disc16
	mov si,OFFSET write_disc32
	mov di,OFFSET write_disc_name
	mov dx,virt_es_in
	mov ax,write_disc_nr
	RegisterUserGate
;
	mov di,OFFSET init_disc
	HookInitFileSystem
;
	mov eax,SIZE disc_data_seg
	mov bx,disc_data_sel
	AllocateFixedSystemMem
	mov es:disc_params,0
;
	mov cx,MAX_DRIVES
	mov di,OFFSET disc_def_arr
	xor ax,ax
	rep stosw
;
	mov cx,MAX_DRIVES
	mov di,OFFSET drive_def_arr
	xor ax,ax
	rep stosw
;
	mov cx,DRIVE_WAIT_NUM
	mov di,4*DRIVE_WAIT_NUM + OFFSET drive_wait_arr
init_drive_wait_loop:
	mov ax,di
	sub di,4
	mov es:[di],ax
	loop init_drive_wait_loop
	mov es:drive_wait_free,di
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init

