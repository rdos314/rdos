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
; DOSDEV.ASM
; DOS standard device emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME dosdev

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE driver.def
INCLUDE user.def
INCLUDE os.def
INCLUDE system.inc
INCLUDE user.inc
INCLUDE os.inc
INCLUDE fs.inc

devfe_struc	STRUC

devfe_base		dir_file_entry_data_struc <>
devfe_data		DW ?
devfe_name		DB ?

devfe_struc	ENDS

device_struc	STRUC

device_name		DB 8 DUP(?)
device_read		DW ?
device_write	DW ?
device_code		DW ?
device_attr		DW ?

device_struc	ENDS

device_seg		STRUC

device_chain		DW ?

device_last			DW ?

devices				DB 16*16 DUP(?)

device_size			DB ?
  
device_seg		ENDS

device_process_seg	STRUC

con_buf			DB 256 DUP(?)
con_buf_start	DW ?
con_buf_end		DW ?

device_process_size	DB ?

device_process_seg	ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			REGISTER_DEVICE
;
;		DESCRIPTION:	Register DOS device
;
;		PARAMETERS:		DS:BX		DEVICE HEADER
;						CX			DEVICE SIZE
;						DS:SI		DEVICE READ
;						DS:DI		DEVICE WRITE
;						DX			DEVICE SEGMENT
;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_device_name	DB 'Register Device',0

register_device	PROC far
	push ds
	push es
	push eax
	push ecx
	push esi
	push edi
	mov ax,dosdev_data_sel
	mov es,ax
	push cx
	push si
	mov ax,di
	mov di,es:device_last
	mov si,bx
	add si,4
	mov dx,[si]
	add si,6
	mov cx,8
	rep movsb
	pop si
	pop cx
	xchg ax,si
	stosw
	xchg ax,si
	stosw
	mov ax,ds
	stosw
	mov ax,dx
	stosw
	mov es:device_last,di
	mov ax,flat_sel
	mov es,ax
	movzx ecx,cx
	mov eax,ecx
	AllocateFixedVMLinear
	mov edi,edx
	movzx esi,bx
	rep movs byte ptr es:[edi],[esi]
	shr edx,4
	mov ax,flat_sel
	mov ds,ax
	mov ax,dosdev_data_sel
	mov es,ax
	movzx eax,es:device_chain
	shl eax,4
	push dword ptr [eax]
	shl edx,16
	mov [eax],edx
	pop eax
	shr edx,12
	mov [edx],eax
	shr edx,4
	pop edi
	pop esi
	pop ecx
	pop eax
	pop es
	pop ds
	ret
register_device	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FIND_DEVICE
;
;		DESCRIPTION:	Check if a filename is a device
;
;		PARAMETERS:		ES:EDI		FILE NAME
;						DS:BX		FOUND DEVICE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
ct78 DB 'X',	'Y',	'Z',	'{',	0FFh,	'}',	'~',	0FFh
ct80 DB	0FFh,	0FFh,	0FFh,	0FFh,	'é',	0FFh,	'è',	0FFh
ct88 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	'é',	'è'
ct90 DB	0FFh,	0FFh,	0FFh,	0FFh,	'ô',	0FFh,	0FFh,	0FFh
ct98 DB	0FFh,	'ô',	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
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

find_device	PROC far
	push ax
	push cx
	push si
;
	mov ax,dosdev_data_sel
	mov ds,ax
	mov bx,OFFSET char_tab
	mov si,OFFSET devices
	mov cx,ds:device_last
	sub cx,si
	shr cx,4

find_next_device:
	push cx
	push si
	push edi
	mov cx,8

find_device_loop:
	mov al,es:[edi]
	xlat byte ptr cs:char_tab
	cmp al,[si]
	jne find_device_try_next
	inc si
	inc edi
	loop find_device_loop
	jmp find_device_ok

find_device_try_next:
	mov al,[si]
	cmp al,' '
	jne find_device_not_at_end
;
	mov al,es:[edi]
	or al,al
	clc
	je find_device_ok

find_device_not_at_end:
	pop edi
	pop si
	pop cx
	add si,16
	loop find_next_device

find_device_fail:
	stc
	jmp find_device_done

find_device_ok:
	pop edi
	pop si
	pop cx
	mov bx,si
	clc

find_device_done:
	pop si
	pop cx
	pop ax
	ret
find_device	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CHECK_DEVICE
;
;		DESCRIPTION:	Check if file is a DOS device
;
;		PARAMETERS:		ES:EDI		FILE NAME
;						AL			DRIVE IN/OUT
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_device_name	DB 'Check Device',0

check_device	PROC far
	push ds
	push bx
	call find_device
	jc check_device_not_found
	mov al,80h
check_device_not_found:
	pop bx
	pop ds
	clc
	ret
check_device	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Cache_dir
;
;		DESCRIPTION:	Cache dir
;
;		PARAMETERS:		EDX			Dir entry to cache or 0
;						BX			Cached dir selector
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_dir	PROC far
	push es
	pushad
;
	mov ax,dosdev_data_sel
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
;
	mov esi,OFFSET devices
	mov cx,ds:device_last
	sub cx,si
	shr cx,4

cache_dir_loop:
	push cx
;
	mov eax,SIZE devfe_struc + 8
	AllocateSmallLinear
	mov es:[edx].de_drive,80h
	mov es:[edx].de_usage,0
	push esi
	push edi
	lea edi,[edx].devfe_name
	mov es:[edx].de_name,edi
	mov cx,8
	mov es:[edx].de_name_size,0

cache_name_loop:
	lods byte ptr [esi]
	cmp al,' '
	je cache_name_done
;
	inc es:[edx].de_name_size
	stos byte ptr es:[edi]
	loop cache_name_loop

cache_name_done:
	xor al,al
	stos byte ptr es:[edi]
	pop edi
	pop esi
	mov es:[edx].de_sel,bx
	mov es:[edx].de_attrib,80h
	mov es:[edx].de_time,0
	mov es:[edx+4].de_time,0
	mov es:[edx].dfe_data_size,0
	mov es:[edx].dfe_file_sel,0
	mov es:[edx].devfe_data,si
	InsertFileEntry
;
	add esi,16
	pop cx
	sub cx,1
	jnz cache_dir_loop
;
	popad
	pop es
	clc
	ret
cache_dir	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			OPEN_FILE
;
;		DESCRIPTION:	Open file
;
;		PARAMETERS:		ES:EDI		FILE NAME
;
;		RETURNS:		AH			FILE ATTRIBUTE
;						ECX			FILE SIZE
;						DX			FILE PTR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_file	PROC far
	call find_device
	jc open_file_done
;
	mov dx,bx
	xor ecx,ecx
	mov ah,80h
	clc

open_file_done:
	ret
open_file	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CLOSE_FILE
;
;		DESCRIPTION:	Close file
;
;		PARAMETERS:		ES:EDI		FILE NAME
;						CL			ACCESS MODE
;
;		RETURNS:		BX			FILE HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_file	PROC far
	clc
	ret
close_file	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			READ_FILE
;
;		DESCRIPTION:	Read from device
;
;		PARAMETERS:		BX			HANDLE TO DEVICE
;						ES:EDI		BUFFER
;						ECX			NUMBER OF BYTES TO READ
;						EDX			POSITION
;
;		RETURNS:		EAX			NUMBER OF BYTES READ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_file	PROC far
	mov ds,bx
	mov ebx,ds:file_dir_entry
	mov ax,flat_sel
	mov ds,ax
	mov bx,[ebx].devfe_data
	mov ax,dosdev_data_sel
	mov ds,ax
	push [bx].device_code
	push [bx].device_read
	ret
read_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_FILE
;
;		DESCRIPTION:	Write to device
;
;		PARAMETERS:		BX			HANDLE TO DEVICE
;						ES:EDI		BUFFER
;						ECX			NUMBER OF BYTES TO READ
;						EDX			POSITION
;
;		RETURNS:		EAX			NUMBER OF BYTES WRITTEN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_file	PROC far
	mov ds,bx
	mov ebx,ds:file_dir_entry
	mov ax,flat_sel
	mov ds,ax
	mov bx,[ebx].devfe_data
	mov ax,dosdev_data_sel
	mov ds,ax
	push [bx].device_code
	push [bx].device_write
 	ret
write_file	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CLOCK_DEVICE
;
;		DESCRIPTION:	Clock$ device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clock_device_begin:
	dd -1
	dw 08008h
	dw OFFSET clock_strat - OFFSET clock_device_begin
	dw OFFSET clock_int - OFFSET clock_device_begin
	db 'CLOCK$  '
clock_strat:
	retf
clock_int:
	retf
clock_device_end:

clock_read	PROC far
	stc
	ret
clock_read	ENDP

clock_write	PROC far
	stc
	ret
clock_write	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			PRN_DEVICE
;
;		DESCRIPTION:	PRN device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

prn_device_begin:
	dd -1
	dw 080C0h
	dw OFFSET prn_strat - OFFSET prn_device_begin
	dw OFFSET prn_int - OFFSET prn_device_begin
	db 'PRN     '
prn_strat:
	retf
prn_int:
	retf
prn_device_end:

lpt1_device_begin:
	dd -1
	dw 080C0h
	dw OFFSET lpt1_strat - OFFSET lpt1_device_begin
	dw OFFSET lpt1_int - OFFSET lpt1_device_begin
	db 'LPT1    '
lpt1_strat:
	retf
lpt1_int:
	retf
lpt1_device_end:

prn_read	PROC far
	stc
	ret
prn_read	ENDP

prn_write	PROC far
	push dx
	xor dx,dx
	push edi
	push ecx
	push cx
	xor cx,cx
prn_loop:
	CheckPrinter
	test al,80h
	jz prn_output
	loop prn_loop
prn_output:
	pop cx
prn_write_loop:
	mov al,es:[edi]
	WritePrinter
	jc prn_fail
	inc edi
	sub ecx,1
	jnz prn_write_loop
	pop ecx
	pop edi
	pop dx
	mov eax,ecx
	clc
	ret
prn_fail:
	mov eax,ecx
	pop ecx
	sub eax,ecx
	neg eax
	pop edi
	pop dx
	stc
	ret
prn_write	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AUX_DEVICE
;
;		DESCRIPTION:	AUX device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

aux_device_begin:
	dd -1
	dw 080C0h
	dw OFFSET aux_strat - OFFSET aux_device_begin
	dw OFFSET aux_int - OFFSET aux_device_begin
	db 'AUX     '
aux_strat:
	retf
aux_int:
	retf
aux_device_end:

aux_read	PROC far
	stc
	ret
aux_read	ENDP

aux_write	PROC far
	stc
	ret
aux_write	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CON_IO
;
;		DESCRIPTION:	Console IO
;
;		PARAMETERS:		ES:EDI			BUFFER
;						ECX				MAX NUMBER OF CHARS
;						EAX				NUMBER OF READ CHARS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cursor_pos	Proc near
	push cx
	GetCursorPosition
	mov dh,dl
	mov dl,cl
	pop cx
	ret
get_cursor_pos	Endp

set_cursor_pos	Proc near
	push cx
	movzx cx,dl
	movzx dx,dh
	SetCursorPosition
	pop cx
	ret
set_cursor_pos	Endp

con_io_tab:
	mov al,' '
	jmp con_io_normal

con_io_normal	PROC near
	or ecx,ecx
	jz con_io_full
	cmp esi,edi
	jne con_io_insert
	WriteChar
	stos byte ptr es:[edi]
	dec ecx
	mov esi,edi
con_io_full:
	clc
	ret
con_io_insert:
	push ecx
	push esi
	push dx
	call get_cursor_pos
	mov ecx,edi
	sub ecx,esi
con_io_move_loop:
	WriteChar
	xchg al,es:[esi]
	inc esi
	sub ecx,1
	jne con_io_move_loop
	WriteChar
	mov es:[esi],al
	call set_cursor_pos
	pop dx
	pop esi
	pop ecx
	mov al,es:[esi]
	WriteChar
	mov eax,edi
	sub eax,esi
	sub eax,ecx
	jnc con_io_overflow
	inc esi
	inc edi
	dec ecx	
	clc
	ret
con_io_overflow:
	inc esi
	dec ecx
	push ecx
	push esi
	push dx
	call get_cursor_pos
con_io_overflow_loop:
	cmp esi,edi
	je con_io_overflow_done
	mov al,es:[esi]
	WriteChar
	inc esi
	dec ecx
	jmp con_io_overflow_loop
con_io_overflow_done:
	mov al,' '
	WriteChar
	call set_cursor_pos
	xor al,al
	WriteChar
	pop dx
	pop esi
	pop ecx
	clc
	ret
con_io_normal	ENDP

con_io_del		PROC near
	cmp ecx,edx
	je con_io_del_empty
	cmp esi,edi
	jne con_io_del_move
	dec edi
	dec esi
	inc ecx
	push dx
	call get_cursor_pos
	sub dl,1
	jnc con_io_del_do
	mov dl,79
	sub dh,1
	jnc con_io_del_do
	xor dx,dx
con_io_del_do:
	push dx
	call set_cursor_pos
	mov al,' '
	WriteChar
	pop dx
	call set_cursor_pos
	pop dx
con_io_del_empty:
	clc
	ret
con_io_del_move:
	dec esi
	dec edi
	inc ecx
	push ecx
	push esi
	push dx
	call get_cursor_pos
	sub dl,1
	jnc con_io_del_do_move
	mov dl,79
	sub dh,1
	jnc con_io_del_do_move
	xor dx,dx
con_io_del_do_move:
	call set_cursor_pos
	mov ecx,edi
	sub ecx,esi
con_io_del_loop:
	mov al,es:[esi+1]
	mov es:[esi],al
	WriteChar
	inc esi
	sub ecx,1
	jne con_io_del_loop
	mov al,' '
	WriteChar
	call set_cursor_pos
	pop dx
	pop esi
	pop ecx
	clc
	ret
con_io_del		ENDP

con_io_cr		PROC near
	cmp ecx,2
	jc con_io_cr_full
	mov al,0Dh
	mov es:[esi],al
	dec ecx
	inc esi
	inc edi
	WriteChar
	stc
	ret
con_io_cr_full:
	clc
	ret
con_io_cr		ENDP

con_io_clear_buf	PROC near
con_clear_home_loop:
	cmp ecx,edx
	je con_clear_home_done
	push dx
	call get_cursor_pos
	sub dl,1
	jnc con_clear_home_do
	mov dl,79
	sub dh,1
	jnc con_clear_home_do
	xor dx,dx
con_clear_home_do:
	call set_cursor_pos
	pop dx
	dec esi
	inc ecx
	jmp con_clear_home_loop
con_clear_home_done:
	push dx
	call get_cursor_pos
	push dx
	push ecx
	mov ecx,edi
	sub ecx,esi
	mov al,' '
con_clear_loop:
	WriteChar
	sub ecx,1
	jnz con_clear_loop
	pop ecx
	pop dx
	call set_cursor_pos
	xor al,al
	WriteChar
	pop dx
	mov edi,esi
	clc
	ret
con_io_clear_buf	ENDP

con_io_skip	PROC near
	clc
	ret
con_io_skip	ENDP

con_left_arrow	PROC near
	cmp edx,ecx
	je con_left_fail
	inc ecx
	dec esi
	push dx
	call get_cursor_pos
	sub dl,1
	jnc con_left_arrow_do
	mov dl,79
	sub dh,1
	jnc con_left_arrow_do
	xor dx,dx
con_left_arrow_do:
	call set_cursor_pos
	pop dx
	xor al,al
	WriteChar
con_left_fail:
	clc
	ret
con_left_arrow	ENDP

con_right_arrow	PROC near
	cmp edi,esi
	je con_right_fail
	mov al,es:[esi]
	cmp edi,esi
	jne con_right_write
	mov al,' '
con_right_write:
	WriteChar
	dec ecx
	inc esi
con_right_fail:
	clc
	ret
con_right_arrow	ENDP

con_home_key	PROC near
con_home_loop:
	cmp ecx,edx
	je con_home_done
	push dx
	call get_cursor_pos
	sub dl,1
	jnc con_home_do
	mov dl,79
	sub dh,1
	jnc con_home_do
	xor dx,dx
con_home_do:
	call set_cursor_pos
	pop dx
	dec esi
	inc ecx
	jmp con_home_loop
con_home_done:
	xor al,al
	WriteChar
	clc
	ret
con_home_key	ENDP

con_end_key	PROC near
con_end_loop:
	cmp esi,edi
	je con_end_done
	mov al,es:[esi]
	WriteChar
	inc esi
	dec ecx
	jmp con_end_loop
con_end_done:
	clc
	ret
con_end_key	ENDP

con_ext_key_buf_tab:
dek00	DW OFFSET con_io_skip
dek01	DW OFFSET con_io_skip
dek02	DW OFFSET con_io_skip
dek03	DW OFFSET con_io_skip
dek04	DW OFFSET con_io_skip
dek05	DW OFFSET con_io_skip
dek06	DW OFFSET con_io_skip
dek07	DW OFFSET con_io_skip
dek08	DW OFFSET con_io_skip
dek09	DW OFFSET con_io_skip
dek0A	DW OFFSET con_io_skip
dek0B	DW OFFSET con_io_skip
dek0C	DW OFFSET con_io_skip
dek0D	DW OFFSET con_io_skip
dek0E	DW OFFSET con_io_skip
dek0F	DW OFFSET con_io_skip
dek10	DW OFFSET con_io_skip
dek11	DW OFFSET con_io_skip
dek12	DW OFFSET con_io_skip
dek13	DW OFFSET con_io_skip
dek14	DW OFFSET con_io_skip
dek15	DW OFFSET con_io_skip
dek16	DW OFFSET con_io_skip
dek17	DW OFFSET con_io_skip
dek18	DW OFFSET con_io_skip
dek19	DW OFFSET con_io_skip
dek1A	DW OFFSET con_io_skip
dek1B	DW OFFSET con_io_skip
dek1C	DW OFFSET con_io_skip
dek1D	DW OFFSET con_io_skip
dek1E	DW OFFSET con_io_skip
dek1F	DW OFFSET con_io_skip
dek20	DW OFFSET con_io_skip
dek21	DW OFFSET con_io_skip
dek22	DW OFFSET con_io_skip
dek23	DW OFFSET con_io_skip
dek24	DW OFFSET con_io_skip
dek25	DW OFFSET con_io_skip
dek26	DW OFFSET con_io_skip
dek27	DW OFFSET con_io_skip
dek28	DW OFFSET con_io_skip
dek29	DW OFFSET con_io_skip
dek2A	DW OFFSET con_io_skip
dek2B	DW OFFSET con_io_skip
dek2C	DW OFFSET con_io_skip
dek2D	DW OFFSET con_io_skip
dek2E	DW OFFSET con_io_skip
dek2F	DW OFFSET con_io_skip
dek30	DW OFFSET con_io_skip
dek31	DW OFFSET con_io_skip
dek32	DW OFFSET con_io_skip
dek33	DW OFFSET con_io_skip
dek34	DW OFFSET con_io_skip
dek35	DW OFFSET con_io_skip
dek36	DW OFFSET con_io_skip
dek37	DW OFFSET con_io_skip
dek38	DW OFFSET con_io_skip
dek39	DW OFFSET con_io_skip
dek3A	DW OFFSET con_io_skip
dek3B	DW OFFSET con_io_skip
dek3C	DW OFFSET con_io_skip
dek3D	DW OFFSET con_io_skip
dek3E	DW OFFSET con_io_skip
dek3F	DW OFFSET con_io_skip
dek40	DW OFFSET con_io_skip
dek41	DW OFFSET con_io_skip
dek42	DW OFFSET con_io_skip
dek43	DW OFFSET con_io_skip
dek44	DW OFFSET con_io_skip
dek45	DW OFFSET con_io_skip
dek46	DW OFFSET con_io_skip
dek47	DW OFFSET con_home_key
dek48	DW OFFSET con_io_skip
dek49	DW OFFSET con_io_skip
dek4A	DW OFFSET con_io_skip
dek4B	DW OFFSET con_left_arrow
dek4C	DW OFFSET con_io_skip
dek4D	DW OFFSET con_right_arrow
dek4E	DW OFFSET con_io_skip
dek4F	DW OFFSET con_end_key
dek50	DW OFFSET con_io_skip
dek51	DW OFFSET con_io_skip
dek52	DW OFFSET con_io_skip
dek53	DW OFFSET con_io_skip
dek54	DW OFFSET con_io_skip
dek55	DW OFFSET con_io_skip
dek56	DW OFFSET con_io_skip
dek57	DW OFFSET con_io_skip
dek58	DW OFFSET con_io_skip
dek59	DW OFFSET con_io_skip
dek5A	DW OFFSET con_io_skip
dek5B	DW OFFSET con_io_skip
dek5C	DW OFFSET con_io_skip
dek5D	DW OFFSET con_io_skip
dek5E	DW OFFSET con_io_skip
dek5F	DW OFFSET con_io_skip
dek60	DW OFFSET con_io_skip
dek61	DW OFFSET con_io_skip
dek62	DW OFFSET con_io_skip
dek63	DW OFFSET con_io_skip
dek64	DW OFFSET con_io_skip
dek65	DW OFFSET con_io_skip
dek66	DW OFFSET con_io_skip
dek67	DW OFFSET con_io_skip
dek68	DW OFFSET con_io_skip
dek69	DW OFFSET con_io_skip
dek6A	DW OFFSET con_io_skip
dek6B	DW OFFSET con_io_skip
dek6C	DW OFFSET con_io_skip
dek6D	DW OFFSET con_io_skip
dek6E	DW OFFSET con_io_skip
dek6F	DW OFFSET con_io_skip
dek70	DW OFFSET con_io_skip
dek71	DW OFFSET con_io_skip
dek72	DW OFFSET con_io_skip
dek73	DW OFFSET con_io_skip
dek74	DW OFFSET con_io_skip
dek75	DW OFFSET con_io_skip
dek76	DW OFFSET con_io_skip
dek77	DW OFFSET con_io_skip
dek78	DW OFFSET con_io_skip
dek79	DW OFFSET con_io_skip
dek7A	DW OFFSET con_io_skip
dek7B	DW OFFSET con_io_skip
dek7C	DW OFFSET con_io_skip
dek7D	DW OFFSET con_io_skip
dek7E	DW OFFSET con_io_skip
dek7F	DW OFFSET con_io_skip
dek80	DW OFFSET con_io_skip
dek81	DW OFFSET con_io_skip
dek82	DW OFFSET con_io_skip
dek83	DW OFFSET con_io_skip
dek84	DW OFFSET con_io_skip

con_io_extend	PROC near
	mov bl,ah
	xor bh,bh
	add bx,bx
	call cs:word ptr [bx].con_ext_key_buf_tab
	ret
con_io_extend	ENDP

con_key_buf_tab:
ckb0	DW OFFSET con_io_extend
ckb1	DW OFFSET con_io_normal
ckb2	DW OFFSET con_io_normal
ckb3	DW OFFSET con_io_normal
ckb4	DW OFFSET con_io_normal
ckb5	DW OFFSET con_io_normal
ckb6	DW OFFSET con_io_normal
ckb7	DW OFFSET con_io_normal
ckb8	DW OFFSET con_io_del
ckb9	DW OFFSET con_io_tab
ckbA	DW OFFSET con_io_normal
ckbB	DW OFFSET con_io_normal
ckbC	DW OFFSET con_io_normal
ckbD	DW OFFSET con_io_cr
ckbE	DW OFFSET con_io_normal
ckbF	DW OFFSET con_io_normal
ckb10	DW OFFSET con_io_normal
ckb11	DW OFFSET con_io_normal
ckb12	DW OFFSET con_io_normal
ckb13	DW OFFSET con_io_normal
ckb14	DW OFFSET con_io_normal
ckb15	DW OFFSET con_io_normal
ckb16	DW OFFSET con_io_normal
ckb17	DW OFFSET con_io_normal
ckb18	DW OFFSET con_io_normal
ckb19	DW OFFSET con_io_normal
ckb1A	DW OFFSET con_io_normal
ckb1B	DW OFFSET con_io_clear_buf
ckb1C	DW OFFSET con_io_normal
ckb1D	DW OFFSET con_io_normal
ckb1E	DW OFFSET con_io_normal
ckb1F	DW OFFSET con_io_normal
ckbend	DW OFFSET con_io_normal

con_io	PROC near
	push ds
	push ecx
	push edx
	push esi
	push edi
	mov edx,ecx
	mov esi,edi
	mov ax,dosdev_process_sel
	mov ds,ax
con_io_loop:
	ReadKeyboard
	movzx bx,al
	cmp bx,20h
	jc con_io_in_tab
	mov bx,20h
con_io_in_tab:
	add bx,bx
	call cs:word ptr [bx].con_key_buf_tab
	jnc con_io_loop
	pop edi
	mov eax,esi
	sub eax,edi
	clc
	pop esi
	pop edx
	pop ecx
	pop ds
	ret
con_io	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadConsole
;
;		DESCRIPTION:	Read from console
;
;		PARAMETERS:		ES:(E)DI		BUFFER
;						(E)CX			MAX NUMBER OF CHARS
;						
;		RETURNS;		(E)AX			NUMBER OF READ CHARS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_con_name	DB 'Read Console',0

read_con16	PROC far
	push ecx
	push eax
	push edi
	movzx ecx,cx
	movzx edi,di
	call con_io
	pop edi
	mov ecx,eax
	pop eax
	mov ax,cx
	pop ecx	
	ret
read_con16	ENDP

read_con32	PROC far
	call con_io
	retf32
read_con32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CON_DEVICE
;
;		DESCRIPTION:	CON device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

con_device_begin:
	dd -1
	dw 080D3h
	dw OFFSET con_strat - OFFSET con_device_begin
	dw OFFSET con_int - OFFSET con_device_begin
	db 'CON     '
con_strat:
	retf
con_int:
	retf
con_device_end:

con_read_line	PROC near
	push es
	push ecx
	push edi
	mov ax,dosdev_process_sel
	mov es,ax
	mov edi,OFFSET con_buf
	mov ds:con_buf_start,di
	mov ecx,256
	call con_io
	add di,ax
	inc ax
	mov al,0Ah
	stosb
	WriteChar
	mov ds:con_buf_end,di
	pop edi
	pop ecx
	pop es
	ret
con_read_line	ENDP

con_read	PROC far
	push ds
	push esi
	push ecx
	push edi
	mov ax,dosdev_process_sel
	mov ds,ax
	movzx esi,ds:con_buf_start
	movzx eax,ds:con_buf_end
	sub eax,esi
	or eax,eax
	jnz con_read_do
	call con_read_line
	movzx esi,ds:con_buf_start
	movzx eax,ds:con_buf_end
	sub eax,esi
con_read_do:
	pop edi
	pop ecx
	cmp eax,ecx
	jnc con_read_partial
con_read_all:
	push ecx
	push edi
	mov ecx,eax
	rep movs byte ptr es:[edi],[esi]
	pop edi
	pop ecx
	mov ds:con_buf_start,OFFSET con_buf
	mov ds:con_buf_end,OFFSET con_buf
	jmp con_read_done
con_read_partial:
	push ecx
	push edi
	mov eax,ecx
	rep movs byte ptr es:[edi],[esi]
	mov ds:con_buf_start,si
	pop edi
	pop ecx
con_read_done:
	clc
	pop esi
	pop ds
	ret
con_read	ENDP

con_write	PROC far
	UserGateForce32 write_size_string_nr
	mov eax,ecx
	clc
	ret
con_write	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_DEVICE_PROCESS
;
;		DESCRIPTION:	Init per-process data
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

aux_device	DB 'AUX',0
con_device	DB 'CON',0
prn_device	DB 'PRN',0

init_device_process	PROC far
	push ds
	pusha
	mov ax,dosdev_process_sel
	mov ds,ax
	mov ds:con_buf_start,OFFSET con_buf
	mov ds:con_buf_end,OFFSET con_buf
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET aux_device
	OpenFile
	mov di,OFFSET con_device
	OpenFile
	mov di,OFFSET prn_device
	OpenFile
;
	popa
	pop ds
	ret
init_device_process	ENDP

PAGE

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

nul_device_begin:
	dd -1
	dw 08004h
	dw OFFSET nul_strat - OFFSET nul_device_begin
	dw OFFSET nul_int - OFFSET nul_device_begin
	db 'NUL     '
nul_strat:
	retf
nul_int:
	retf
nul_device_end:

nul_read	PROC far
	stc
	ret
nul_read	ENDP

nul_write	PROC far
	stc
	ret
nul_write	ENDP

dummy	Proc far
	stc
	ret
dummy	Endp

fs_name	DB 'DEVICE',0

fs_ctrl:
fs00	DW OFFSET dummy,			dosdev_code_sel
fs01	DW OFFSET dummy,			dosdev_code_sel
fs02	DW OFFSET dummy,			dosdev_code_sel
fs03	DW OFFSET dummy,			dosdev_code_sel
fs04	DW OFFSET dummy,			dosdev_code_sel
fs05	DW OFFSET cache_dir,		dosdev_code_sel
fs06	DW OFFSET dummy,			dosdev_code_sel
fs07	DW OFFSET dummy,			dosdev_code_sel
fs08	DW OFFSET dummy,			dosdev_code_sel
fs09	DW OFFSET dummy,			dosdev_code_sel
fs10	DW OFFSET dummy,			dosdev_code_sel
fs11	DW OFFSET dummy,			dosdev_code_sel
fs12	DW OFFSET dummy,			dosdev_code_sel
fs13	DW OFFSET dummy,			dosdev_code_sel
fs14	DW OFFSET dummy,			dosdev_code_sel
fs15	DW OFFSET read_file,		dosdev_code_sel
fs16	DW OFFSET write_file,		dosdev_code_sel
fs17	DW OFFSET dummy,			dosdev_code_sel
fs18	DW OFFSET dummy,			dosdev_code_sel
fs19	DW OFFSET dummy,			dosdev_code_sel
fs20	DW OFFSET dummy,			dosdev_code_sel
	
init	PROC far
	pusha
	push ds
	push es
	mov bx,dosdev_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_device_process
	HookCreateProcess
;
	mov si,OFFSET register_device
	mov di,OFFSET register_device_name
	mov ax,register_device_nr
	RegisterOsGate
;
	mov si,OFFSET check_device
	mov di,OFFSET check_device_name
	mov ax,check_device_nr
	RegisterOsGate
;
	mov bx,OFFSET read_con16
	mov si,OFFSET read_con32
	mov di,OFFSET read_con_name
	mov dx,virt_es_in
	mov ax,read_con_nr
	RegisterUserGate
;
	mov ax,OFFSET device_size
	mov bx,dosdev_data_sel
	AllocateFixedSystemMem
;
	mov ax,OFFSET device_process_size
	mov bx,dosdev_process_sel
	AllocateFixedProcessMem
;
	mov ax,flat_sel
	mov es,ax
	mov eax,OFFSET nul_device_end - OFFSET nul_device_begin
	AllocateFixedVMLinear
	mov ecx,eax
	mov edi,edx
	mov esi,OFFSET nul_device_begin
	rep movs byte ptr es:[edi],[esi]
	shr edx,4
	mov ax,dosdev_data_sel
	mov es,ax
	mov es:device_chain,dx
	mov ax,cs
	mov ds,ax
	mov si,OFFSET nul_device_begin + 10
	mov di,OFFSET devices
	mov cx,8
	rep movsb
	mov ax,OFFSET nul_read
	stosw
	mov ax,OFFSET nul_write
	stosw
	mov ax,cs
	stosw
	mov ax,8004h
	stosw
	mov es:device_last,di
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov bx,OFFSET clock_device_begin
	mov cx,OFFSET clock_device_end - OFFSET clock_device_begin
	mov si,OFFSET clock_read
	mov di,OFFSET clock_write
	RegisterDevice
;
	mov bx,OFFSET prn_device_begin
	mov cx,OFFSET prn_device_end - OFFSET prn_device_begin
	mov si,OFFSET prn_read
	mov di,OFFSET prn_write
	RegisterDevice
;
	mov bx,OFFSET aux_device_begin
	mov cx,OFFSET aux_device_end - OFFSET aux_device_begin
	mov si,OFFSET aux_read
	mov di,OFFSET aux_write
	RegisterDevice
;
	mov bx,OFFSET con_device_begin
	mov cx,OFFSET con_device_end - OFFSET con_device_begin
	mov si,OFFSET con_read
	mov di,OFFSET con_write
	RegisterDevice
;
	mov bx,OFFSET lpt1_device_begin
	mov cx,OFFSET lpt1_device_end - OFFSET lpt1_device_begin
	mov si,OFFSET prn_read
	mov di,OFFSET prn_write
	RegisterDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET fs_name
	mov di,OFFSET fs_ctrl
	RegisterFileSystem
;	
	mov al,80h
	mov di,OFFSET fs_name
	InstallFileSystem
;
	pop es
	pop ds
	popa
	ret
init	ENDP

code	ENDS

	END init
