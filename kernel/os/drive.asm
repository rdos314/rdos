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

POLL_TIMEOUT EQU 2 * 1192000
MIN_TIMEOUT EQU 2 * 1192000

disc_data_seg		STRUC

init_disc_hooks		DB ?

init_disc_hook_arr	DD MAX_DRIVES DUP(?)

disc_def_arr		DW MAX_DRIVES DUP(?)

drive_def_arr		DW MAX_DRIVES DUP(?)

disc_data_seg		ENDS

disc_def_struc		STRUC

disc_nr					DB ?
disc_units				DW ?
disc_bytes_per_sector	DW ?
disc_sectors_per_unit	DW ?
disc_thread				DW ?
disc_block_count		DW ?
disc_timer_id			DW ?
disc_current			DD ?
disc_list				DD ?
disc_free				DD ?
disc_section			section_typ <>
disc_pend_list			DD ?
disc_awrite_list		DD ?
disc_awrite_timer		DW ?
disc_awrite_timeout		DD ?,?
disc_swrite_list		DD ?
disc_swrite_first		DD ?
disc_unit_arr			DD ?

disc_def_struc		ENDS

disc_unit_struc	STRUC

disc_sectors			DW ?
disc_sector_arr			DD ?

disc_unit_struc	ENDS

drive_def_struc	STRUC

drive_disc				DW ?
drive_start_sector		DD ?

drive_def_struc	ENDS

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
	mov eax,ds:disc_pend_list
	or eax,eax
	jne insert_pend_used

insert_pend_empty:
	mov es:[edi].dh_prev,edi
	mov es:[edi].dh_next,edi
	mov ds:disc_pend_list,edi
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
	mov ds:disc_pend_list,edi
	jmp insert_pend_link

insert_pend_search_loop:
	mov eax,es:[eax].dh_next
	cmp eax,ds:disc_pend_list
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
	mov dword ptr ds:disc_pend_list,0
	clc
	jmp get_pend_done

get_pend_unlink:
	mov ds:disc_pend_list,eax
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

update_async_write	PROC far
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
	mov ax,flat_sel
	mov es,ax
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
;		NAME:			INSERT_SEQ_WRITE
;
;		DESCRIPTION:	Insert block into seq write request list
;
;		PARAMETERS:		DS		DiscBuf handle
;						ES		Flat_sel
;						EDI		DiscBlock handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_seq_write	PROC near
	push eax
	push ebx
;
	mov eax,ds:disc_swrite_first
	or eax,eax
	jnz insert_seq_list
;
	mov ds:disc_swrite_first,edi
	call insert_pending
	jmp insert_seq_done

insert_seq_list:
	mov eax,ds:disc_swrite_list
	or eax,eax
	jne insert_seq_used

insert_seq_empty:
	mov es:[edi].dh_prev,edi
	mov es:[edi].dh_next,edi
	jmp insert_seq_save

insert_seq_used:
	mov ebx,es:[eax].dh_prev
	mov es:[eax].dh_prev,edi
	mov es:[ebx].dh_next,edi
	mov es:[edi].dh_prev,ebx
	mov es:[edi].dh_next,eax	

insert_seq_save:
	mov ds:disc_swrite_list,edi

insert_seq_done:
	pop ebx
	pop eax
	ret
insert_seq_write	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UPDATE_SEQ_WRITE
;
;		DESCRIPTION:	Update seq write list
;
;		PARAMETERS:		DS		Disc selector
;						ES		Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_seq_write	PROC far
	mov edi,ds:disc_swrite_list
	or edi,edi
	mov ds:disc_swrite_first,edi
	jz update_seq_done
;
	mov edi,es:[edi].dh_prev
	mov eax,es:[edi].dh_next
	mov ebx,es:[edi].dh_prev
	mov es:[ebx].dh_next,eax
	mov es:[eax].dh_prev,ebx
	cmp eax,edi
	jne update_seq_insert
;
	mov dword ptr ds:disc_swrite_list,0

update_seq_insert:
	mov ds:disc_swrite_first,edi
	call insert_pending

update_seq_done:
	ret
update_seq_write	ENDP

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
	LeaveSection ds:disc_section
	push ax
	push bx
	push dx
	mov bx,ds:disc_thread
	cli
	mov ax,es:[edi].dh_thread
	or ax,ax
	jnz block_no_signal
;
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
;		NAME:			FLUSH_DRIVES
;
;		DESCRIPTION:	Flush all drives assocated with a disc #
;
;		PARAMETERS:		DS		Disc def struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_drives	Proc near
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

flush_drives_loop:
	mov ax,[si]
	or ax,ax
	jz flush_drives_next
;
	cmp ax,-1
	je flush_drives_next
;
	mov es,ax
	cmp bx,es:drive_disc
	jne flush_drives_next
;
	mov ax,si
	sub ax,OFFSET drive_def_arr
	shr ax,1
	InitFileSystem

flush_drives_next:
	add si,2
	loop flush_drives_loop	
;
	pop si
	pop cx
	pop bx
	pop ax
	pop es
	pop ds
	ret
flush_drives	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLUSH_DISC
;
;		DESCRIPTION:	Flush disc
;
;		PARAMETERS:		AX		Sectors per unit
;						BX		Disc sel
;						CX		Bytes per sector
;						DX		Units
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_disc_name	DB 'Flush Disc',0

flush_disc	Proc far
	push ds
	mov ds,bx
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
	call flush_drives
	pop di
	pop es
;
	pop ds
	ret
flush_disc	Endp
	
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
	GetThread
	mov ds:disc_thread,ax

wait_for_disc_req_loop:
	EnterSection ds:disc_section
	call update_async_write
	call update_async_timer
	LeaveSection ds:disc_section
;
	mov ebx,ds:disc_pend_list
	or ebx,ebx
	jnz wait_for_disc_req_done
;
	WaitForSignal
	jmp wait_for_disc_req_loop
		
wait_for_disc_req_done:
	mov ds:disc_thread,0
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
	call get_pending
	jc get_disc_req_fail
;
	mov al,es:[edi].dh_state
	cmp al,STATE_SEQ
	jne get_disc_req_ok
;
	call update_seq_write
	jmp get_disc_req_ok

get_disc_req_fail:
	LeaveSection ds:disc_section
	stc
	jmp get_disc_req_done

get_disc_req_ok:
	mov ds:disc_current,edi
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
	call allocate
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
	push ax
	push bx
	push esi
;
	mov ds,bx
	mov ds:disc_current,0
	xor bx,bx
	xchg bx,es:[edi].dh_thread
	Signal
;
	mov ax,flat_sel
	mov ds,ax
	lea esi,[edi].dh_wait

completed_wakeup_loop:
	mov ax,[esi]
	or ax,ax
	jz completed_wakeup_done
;
	Wake32
	jmp completed_wakeup_loop

completed_wakeup_done:
	pop esi
	pop bx
	pop ax
	pop ds
	ret
disc_request_completed	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_DISC
;
;		DESCRIPTION:	Install disc unit
;
;		RETURNS:		BX		Disc sel
;						AL		Disc #
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
	push ds
	push si
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
	mov ds:disc_current,0
	mov ds:disc_list,0
	mov ds:disc_pend_list,0
	mov ds:disc_awrite_list,0
	mov ds:disc_awrite_timer,0
	mov ds:disc_awrite_timeout,0
	mov ds:disc_awrite_timeout+4,0
	mov ds:disc_swrite_list,0
	mov ds:disc_swrite_first,0
	mov ds:disc_free,0
	mov ds:disc_timer_id,0
	mov ds:disc_block_count,0
	mov ds:disc_thread,0
	InitSection ds:disc_section
	pop di
	pop es
	mov bx,ds
	mov al,ds:disc_nr
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
;		NAME:			NEW_SECTOR
;
;		DESCRIPTION:	Create a new sector cache entry without reading
;
;		PARAMETERS:		AL		Drive #
;						EDX		Sector #
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
	call allocate
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
;
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
	add edx,ds:drive_start_sector
	mov ds,ds:drive_disc
	push edx
	pop ax
	pop dx
	div ds:disc_sectors_per_unit
	mov cx,ax
	EnterSection ds:disc_section

lock_loop:
	call check_current
	jnc lock_read_signal
;
	call check_buf
	jnc lock_found
;
	ClearSignal
	call allocate
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
;
	call allocate
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
;
	call block
	jmp lock_loop

lock_found:
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
;		PARAMETERS:		EDI		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

modify_sector_name	DB 'Modify Sector',0

modify_sector	PROC far
	push ds
	push es
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov ax,flat_sel
	mov es,ax
	mov edi,ebx
	mov ds,es:[edi].dh_buf_sel
	EnterSection ds:disc_section

modify_try_again:
	mov al,es:[edi].dh_state
	cmp al,STATE_DIRTY
	je modify_dirty
;
	cmp al,STATE_SEQ
	je modify_dirty
;
	cmp al,STATE_USED
	jne modify_done

modify_clean:
	GetSystemTime
	mov es:[edi].dh_time_lsb,eax
	mov es:[edi].dh_time_msb,dx
	mov es:[edi].dh_state,STATE_DIRTY
	call insert_async_write
	call update_async_timer
	jmp modify_done

modify_dirty:
	call check_current
	jc modify_done
;
	ClearSignal
	call block
	jmp modify_try_again

modify_done:
	LeaveSection ds:disc_section
	clc
;
	pop edi
	pop esi
	pop edx
	pop ecx
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
;		NAME:			LOCK_SEQ_SECTOR
;
;		DESCRIPTION:	Lock sector for sequential write access and return address
;
;		PARAMETERS:		AL		Drive #
;						EDX		Sector #
;
;		RETURNS:		EBX		Handle
;						ESI		Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_seq_sector_name	DB 'Lock Seq Write Access Sector',0

lock_seq_sector	PROC far
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

lock_seq_loop:
	call check_current
	jnc lock_seq_signal
;
	call check_buf
	jnc lock_seq_found
;
	ClearSignal
	call allocate
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
	call insert_pending

lock_seq_signal:
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	clc
	jne lock_seq_found
;
	call block
	jmp lock_seq_loop

lock_seq_found:
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	je lock_seq_signal
;	
	inc es:[edi].dh_lock_count
	inc es:[edi].dh_usage
	LeaveSection ds:disc_section
	mov al,es:[edi].dh_state
;
	cmp al,STATE_USED
	je lock_seq_get_adds
;
	cmp al,STATE_DIRTY
	je lock_seq_get_adds
;
	cmp al,STATE_SEQ
	je lock_seq_get_adds
;
	stc
	jmp lock_seq_done

lock_seq_get_adds:
	mov esi,es:[edi].dh_data
	mov ebx,edi

lock_seq_done:
	pop edi
	pop edx
	pop cx
	pop ax
	pop es
	pop ds
	ret
lock_seq_sector	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UNLOCK_SEQ_SECTOR
;
;		DESCRIPTION:	Unlock sequential sector
;
;		PARAMETERS:		EBX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_seq_sector_name	DB 'Unlock Seq Write Access Sector',0

unlock_seq_sector	PROC far
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
unlock_seq_sector	ENDP

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
	mov si,OFFSET flush_disc
	mov di,OFFSET flush_disc_name
	mov ax,flush_disc_nr
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
	mov si,OFFSET new_sector
	mov di,OFFSET new_sector_name
	mov ax,new_sector_nr
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
	mov si,OFFSET lock_seq_sector
	mov di,OFFSET lock_seq_sector_name
	mov ax,lock_seq_sector_nr
	RegisterOsGate
;
	mov si,OFFSET unlock_seq_sector
	mov di,OFFSET unlock_seq_sector_name
	mov ax,unlock_seq_sector_nr
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

