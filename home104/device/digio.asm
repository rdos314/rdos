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
; DIGIO.ASM
; Digital IO module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME digio

GateSize = 16

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\wait.inc
INCLUDE ..\..\kernel\handle.inc

IO_OUT	= 3B3h
IO_IN	= 3B3h

digio_seg	STRUC

io_section	section_typ <>
out_val		DB ?

digio_seg	ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UpdateCrc
;
;		DESCRIPTION:	Update CRC with a single bit
;
;		PARAMETERS:		BL			CRC
;						AL			bit 0 is bit
;
;		RETURNS: 		BL			Update CRC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CRC_POLY = 26h

UpdateCrc	Proc near
	push ax
	movzx bx,bl
	shl bx,1
	and al,1
	xor al,bh
	jz update_crc_done
;
	xor bl,CRC_POLY

update_crc_done:
	pop ax
	ret
UpdateCrc	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Delay
;
;		DESCRIPTION:	Delay until line settles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delay	Proc near
	push cx
	mov cx,10
DelayLoop:
	Swap
	loop DelayLoop
	pop cx
	ret
Delay	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			OutputBit
;
;		DESCRIPTION:	Output a single bit
;
;		PARAMETERS:		AL, bit 0, bit to output
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputBit	Proc near
	push ax
	push dx
;
	mov ah,al
	and ah,1
	shl ah,2
;
	mov dx,IO_OUT
	cli
	mov al,ds:out_val
	and al,NOT 4
	or al,ah
	out dx,al
	mov ds:out_val,al
	sti
	call Delay
;
	cli
	mov al,ds:out_val
	or al,2
	out dx,al
	mov ds:out_val,al
	sti
	call Delay
;
	cli
	mov al,ds:out_val
	and al,NOT 2
	out dx,al
	mov ds:out_val,al
	sti
	call Delay
;
	pop dx
	pop ax
	ret
OutputBit	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InputBit
;
;		DESCRIPTION:	Input a single bit
;
;		PARAMETERS:		AL, bit 0, bit to output
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InputBit	Proc near
	push bx
	push dx
	mov bl,al
;
	call Delay
	mov dx,IO_IN
	in al,dx
	and al,1
	and bl,NOT 1
	or bl,al
	mov dx,IO_OUT
;
	cli
	mov al,ds:out_val
	or al,2
	out dx,al
	mov ds:out_val,al
	sti
	call Delay
;
	cli
	mov al,ds:out_val
	and al,NOT 2
	out dx,al
	mov ds:out_val,al
	sti
	call Delay
;
	mov al,bl
	pop dx
	pop bx
	ret
InputBit	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Output6
;
;		DESCRIPTION:	Output 6 bits
;
;		PARAMETERS:		AL		Value to output
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Output6	Proc near
	push ax
	push bx
	push cx
	push dx
;
	mov cx,6
	xor bl,bl
	and al,3Fh

out6_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop out6_loop	
;
	xor al,al
	call OutputBit
;
	mov cx,6
	mov al,bl

out6_crc_loop:
	call OutputBit
	shr al,1
	loop out6_crc_loop
;
	xor al,al
	call OutputBit
;
	mov dx,IO_IN
	in al,dx
	and al,1
	stc
	jz out6_done
;
	clc

out6_done:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
Output6	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Input24
;
;		DESCRIPTION:	Input 24 bits
;
;		RETURNS:		EAX		24 bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Input24	Proc near
	push bx
	push cx
	push dx
;
	mov cx,24
	xor eax,eax
	xor bl,bl

in24_loop:
	call InputBit
	call UpdateCrc
	ror eax,1
	loop in24_loop
;
	shr eax,8
	push eax
;
	mov cx,8
	xor al,al

in24_crc_loop:
	call InputBit
	ror al,1
	loop in24_crc_loop
;
	xor bl,0A5h
	cmp al,bl
	pop eax
	stc
	jne in24_done
;
	clc

in24_done:
	pop dx
	pop cx
	pop bx
	ret
Input24	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Output24
;
;		DESCRIPTION:	Output 24 bits
;
;		PARAMETERS:		EAX		24 bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Output24	Proc near
	push ax
	push bx
	push cx
	push dx
	push edi
;
	mov edi,eax
;
	mov cx,6
	xor bl,bl
	mov ax,di
	shr edi,6
	and al,3Fh

out24_loop0:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop out24_loop0
;
	xor al,al
	call OutputBit
;
	mov dx,IO_IN
	in al,dx
	and al,1
	stc
	jz out24_done
;
	mov cx,6
	mov ax,di
	shr edi,6
	and al,3Fh

out24_loop1:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop out24_loop1	
;
	xor al,al
	call OutputBit
;
	mov dx,IO_IN
	in al,dx
	and al,1
	stc
	jz out24_done
;
	mov cx,6
	mov ax,di
	shr edi,6
	and al,3Fh

out24_loop2:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop out24_loop2	
;
	xor al,al
	call OutputBit
;
	mov dx,IO_IN
	in al,dx
	and al,1
	stc
	jz out24_done
;
	mov cx,6
	mov ax,di
	and al,3Fh

out24_loop3:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop out24_loop3	
;
	xor al,al
	call OutputBit
;
	mov dx,IO_IN
	in al,dx
	and al,1
	stc
	jz out24_done
;
	mov cx,6
	mov al,bl

out24_crc_loop:
	call OutputBit
	shr al,1
	loop out24_crc_loop
;
	xor al,al
	call OutputBit
;
	mov dx,IO_IN
	in al,dx
	and al,1
	stc
	jz out24_done

	clc

out24_done:
	pop edi
	pop dx
	pop cx
	pop bx
	pop ax
	ret
Output24	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			OutputCmdLine
;
;		DESCRIPTION:	Output cmd & line #
;
;		PARAMETERS:		AH			Cmd #
;						AL			Line #			
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputCmdLine	Proc near
	push ax
	push bx
	push cx
	push dx
;
	push ax
	mov cx,3
	xor bl,bl
	mov al,ah
	and al,7

cmd_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop cmd_loop	
;
	pop ax
	mov cx,3
	and al,7

line_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop line_loop	
;
	xor al,al
	call OutputBit
;
	mov cx,6
	mov al,bl

cmdline_crc_loop:
	call OutputBit
	shr al,1
	loop cmdline_crc_loop
;
	xor al,al
	call OutputBit
;
	mov dx,IO_IN
	in al,dx
	and al,1
	stc
	jz cmdline_done
;
	clc

cmdline_done:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
OutputCmdLine	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			OpenSession
;
;		DESCRIPTION:	Output common message header
;
;		PARAMETERS:		AL			Device #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenSession	Proc near
	push ax
	push cx
	push dx
;
	mov cx,digio_data_sel
	mov ds,cx
	EnterSection ds:io_section
;
	push ax
	mov dx,IO_OUT
	cli
	mov al,ds:out_val
	or al,1
	out dx,al
	mov ds:out_val,al
	sti
	call Delay
;
	mov cx,14

preamp_loop:
	mov al,1
	call OutputBit
	loop preamp_loop
;
	xor al,al
	call OutputBit
;
	pop ax
	call Output6
;
	pop dx
	pop cx
	pop ax
	ret
OpenSession	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CloseSession
;
;		DESCRIPTION:	Close a session
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseSession	Proc near
	push ax
	push dx
	pushf
;
	xor al,al
	call OutputBit
;
	cli
	mov dx,IO_OUT
	mov al,ds:out_val
	and al,NOT 6
	out dx,al
	mov ds:out_val,al
	sti
	call Delay
;
	cli
	mov al,ds:out_val
	and al,NOT 7
	out dx,al
	mov ds:out_val,al
	sti
	LeaveSection ds:io_section
	popf
	pop dx
	pop ax
	ret
CloseSession	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadSerialLines
;
;		DESCRIPTION:	Read serial lines
;
;		PARAMETERS:		DH		Device #
;
;		RETURNS:		AL		State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_serial_lines_name	DB 'Read Serial Lines', 0

read_serial_lines	Proc far
	push ds
	push bx
	push dx
	push si
;
	mov si,digio_data_sel
	mov ds,si
	EnterSection ds:io_section
;
	mov si,dx
	mov dx,IO_OUT
;
	cli
	mov al,ds:out_val
	or al,1
	out dx,al
	mov ds:out_val,al
	sti
	call Delay
;
	mov cx,14

rslpreamp_loop:
	mov al,1
	call OutputBit
	loop rslpreamp_loop
;
	xor al,al
	call OutputBit
;
	mov cx,6
	xor bl,bl
	mov ax,si
	mov al,ah
	and al,3Fh

rslnode_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop rslnode_loop	
;
	xor al,al
	call OutputBit
;
	mov cx,6
	mov al,bl

rslnode_crc_loop:
	call OutputBit
	shr al,1
	loop rslnode_crc_loop
;
	xor al,al
	call OutputBit
;
	mov dx,IO_IN
	in al,dx
	mov dx,IO_OUT
	and al,1
	stc
	jz rsl_leave
;
	mov cx,3
	xor bl,bl
	mov al,5 ; READ CMD

rslcmd_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop rslcmd_loop	
;
	mov cx,3
	xor al,al ; sub-cmd
	and al,7

rslsub_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop rslsub_loop	
;
	xor al,al
	call OutputBit
;
	mov cx,6
	mov al,bl

rsldev_crc_loop:
	call OutputBit
	shr al,1
	loop rsldev_crc_loop
;
	xor al,al
	call OutputBit
;
	mov cx,8
	xor al,al
	xor bl,bl

rslin_loop:
	call InputBit
	call UpdateCrc
	ror al,1
	loop rslin_loop
;
	mov ah,al
;
	mov cx,8
	xor al,al

rslin_crc_loop:
	call InputBit
	ror al,1
	loop rslin_crc_loop
;
	xor bl,5Ah
	cmp al,bl
	stc
	jne rsl_leave
;
	clc
	mov al,ah

rsl_leave:
	push ax
	pushf
;
	mov dx,IO_OUT
	cli
	mov al,ds:out_val
	and al,NOT 6
	out dx,al
	mov ds:out_val,al
	sti
	call Delay
;
	cli
	mov al,ds:out_val
	and al,NOT 7
	out dx,al
	mov ds:out_val,al
	sti
	popf
	pop ax
	LeaveSection ds:io_section
;
	pop si
	pop dx
	pop bx
	pop ds
	retf32
read_serial_lines	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ToggleSerialLine
;
;		DESCRIPTION:	Toggle serial input line
;
;		PARAMETERS:		DL		Line #
;						DH		Device #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_serial_line_name	DB 'Toggle Serial Line', 0

toggle_serial_line	Proc far
	push ds
	push ax
	push bx
	push dx
	push si
;
	mov si,digio_data_sel
	mov ds,si
	EnterSection ds:io_section
;
	mov si,dx
	mov dx,IO_OUT
;
	cli
	mov al,ds:out_val
	or al,1
	out dx,al
	mov ds:out_val,al
	sti
	call Delay
;
	mov cx,14

tslpreamp_loop:
	mov al,1
	call OutputBit
	loop tslpreamp_loop
;
	xor al,al
	call OutputBit
;
	mov cx,6
	xor bl,bl
	mov ax,si
	mov al,ah
	and al,3Fh

tslnode_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop tslnode_loop	
;
	xor al,al
	call OutputBit
;
	mov cx,6
	mov al,bl

tslnode_crc_loop:
	call OutputBit
	shr al,1
	loop tslnode_crc_loop
;
	xor al,al
	call OutputBit
;
	mov dx,IO_IN
	in al,dx
	mov dx,IO_OUT
	and al,1
	stc
	jz tsl_done
;
	mov cx,3
	xor bl,bl
	mov al,4 ; TOGGLE CMD

tslcmd_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop tslcmd_loop	
;
	mov cx,3
	mov ax,si
	and al,7

tslchan_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop tslchan_loop	
;
	xor al,al
	call OutputBit
;
	mov cx,6
	mov al,bl

tsldev_crc_loop:
	call OutputBit
	shr al,1
	loop tsldev_crc_loop
;
	xor al,al
	call OutputBit
	call Delay
;
	mov dx,IO_IN
	in al,dx
	mov dx,IO_OUT
	and al,1
	stc
	jz tsl_done
;
	clc

tsl_done:
	pushf
	mov dx,IO_OUT
	cli
	mov al,ds:out_val
	and al,NOT 6
	out dx,al
	mov ds:out_val,al
	sti
	call Delay
;
	cli
	mov al,ds:out_val
	and al,NOT 7
	out dx,al
	mov ds:out_val,al
	sti
	popf
	LeaveSection ds:io_section
;
	pop si
	pop dx
	pop bx
	pop ax
	pop ds
	retf32
toggle_serial_line	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadSerialVal
;
;		DESCRIPTION:	Read serial val
;
;		PARAMETERS:		DL		Line #
;						DH		Device #
;
;		RETURNS:		EAX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_serial_val_name	DB 'Read Serial Value', 0

read_serial_val	Proc far
	push ds
;
	mov al,dh
	call OpenSession
	jc rsv_leave
;
	mov ah,2	; READ VAL CMD
	mov al,dl
	call OutputCmdLine
;
	call Input24

rsv_leave:
	call CloseSession
;
	pop ds
	retf32
read_serial_val	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteSerialVal
;
;		DESCRIPTION:	Write serial value
;
;		PARAMETERS:		DL		Line #
;						DH		Device #
;						EAX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_serial_val_name	DB 'Write Serial Value', 0

write_serial_val	Proc far
	push ds
	push ax
	push edi
;
	mov edi,eax
	mov al,dh
	call OpenSession
	jc wsv_leave	
;
	mov ah,3	; WRITE VAL CMD
	mov al,dl
	call OutputCmdLine
	jc wsv_leave
;
	mov eax,edi
	call Output24
	
wsv_leave:
	call CloseSession
;
	pop edi
	pop ax
	pop ds
	retf32
write_serial_val	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:	Initialize module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
;
	mov bx,digio_code_sel
	InitDevice
;
	mov eax,SIZE digio_seg
	mov bx,digio_data_sel
	AllocateFixedSystemMem
	InitSection es:io_section
;
;    mov dx,28Bh
;    mov al,89h
;    out dx,al
;
	mov al,-1
	mov dx,IO_OUT
	and al,NOT 7
	mov es:out_val,al
	out dx,al
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET read_serial_lines
	mov di,OFFSET read_serial_lines_name
	mov ax,read_serial_lines_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET toggle_serial_line
	mov di,OFFSET toggle_serial_line_name
	mov ax,toggle_serial_line_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET read_serial_val
	mov di,OFFSET read_serial_val_name
	mov ax,read_serial_val_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET write_serial_val
	mov di,OFFSET write_serial_val_name
	mov ax,write_serial_val_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
