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
	cli
	in al,dx
	and al,NOT 4
	or al,ah
	out dx,al
	sti
	call Delay
;
	cli
	in al,dx
	or al,2
	out dx,al
	sti
	call Delay
;
	cli
	in al,dx
	and al,NOT 2
	out dx,al
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
	mov dx,28Ah
	in al,dx
	and al,1
	and bl,NOT 1
	or bl,al
	sub dx,2
;
	cli
	in al,dx
	or al,2
	out dx,al
	sti
	call Delay
;
	cli
	in al,dx
	and al,NOT 2
	out dx,al
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
;		NAME:			ReadDigitalLine
;
;		DESCRIPTION:	Read digital input
;
;		PARAMETERS:		DH		Device #
;
;		RETURNS:		AL		State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_digital_name	DB 'Read Digital', 0

read_digital	Proc far
	push bx
	push dx
	push si
;
	mov si,dx
	mov dx,288h
;
	cli
	in al,dx
	or al,1
	out dx,al
	sti
	call Delay
;
	mov cx,14

rpreamp_loop:
	mov al,1
	call OutputBit
	loop rpreamp_loop
;
	xor al,al
	call OutputBit
;
	mov cx,6
	xor bl,bl
	mov ax,si
	mov al,ah
	and al,3Fh

rnode_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop rnode_loop	
;
	xor al,al
	call OutputBit
;
	mov cx,6
	mov al,bl

rnode_crc_loop:
	call OutputBit
	shr al,1
	loop rnode_crc_loop
;
	xor al,al
	call OutputBit
;
	add dx,2
	in al,dx
	sub dx,2
	and al,1
	stc
	jz read_digital_leave
;
	mov cx,3
	xor bl,bl
	mov al,5 ; READ CMD

rcmd_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop rcmd_loop	
;
	mov cx,3
	xor al,al ; sub-cmd
	and al,7

rsub_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop rsub_loop	
;
	xor al,al
	call OutputBit
;
	mov cx,6
	mov al,bl

rdev_crc_loop:
	call OutputBit
	shr al,1
	loop rdev_crc_loop
;
	xor al,al
	call OutputBit
;
	mov cx,8
	xor al,al
	xor bl,bl

rin_loop:
	call InputBit
	call UpdateCrc
	ror al,1
	loop rin_loop
;
	mov ah,al
;
	mov cx,8
	xor al,al

rin_crc_loop:
	call InputBit
	ror al,1
	loop rin_crc_loop
;
	xor bl,5Ah
	cmp al,bl
	stc
	jne read_digital_leave
;
	clc
	mov al,ah

read_digital_leave:
	push ax
	pushf
;
	cli
	in al,dx
	and al,NOT 6
	out dx,al
	sti
	call Delay
;
	cli
	in al,dx
	and al,NOT 7
	out dx,al
	sti
	popf
	pop ax
;
	pop si
	pop dx
	pop bx
	retf32
read_digital	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ToggleDigitalLine
;
;		DESCRIPTION:	Toggle digital input line
;
;		PARAMETERS:		DL		Line #
;						DH		Device #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_digital_line_name	DB 'Toggle Digital Line', 0

toggle_digital_line	Proc far
	push ax
	push bx
	push dx
	push si
;
	mov si,dx
	mov dx,288h
;
	cli
	in al,dx
	or al,1
	out dx,al
	sti
	call Delay
;
	mov cx,14

tpreamp_loop:
	mov al,1
	call OutputBit
	loop tpreamp_loop
;
	xor al,al
	call OutputBit
;
	mov cx,6
	xor bl,bl
	mov ax,si
	mov al,ah
	and al,3Fh

tnode_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop tnode_loop	
;
	xor al,al
	call OutputBit
;
	mov cx,6
	mov al,bl

tnode_crc_loop:
	call OutputBit
	shr al,1
	loop tnode_crc_loop
;
	xor al,al
	call OutputBit
;
	add dx,2
	in al,dx
	sub dx,2
	and al,1
	stc
	jz toggle_digital_done
;
	mov cx,3
	xor bl,bl
	mov al,4 ; TOGGLE CMD

tcmd_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop tcmd_loop	
;
	mov cx,3
	mov ax,si
	and al,7

tchan_loop:
	call UpdateCrc
	call OutputBit
	shr al,1
	loop tchan_loop	
;
	xor al,al
	call OutputBit
;
	mov cx,6
	mov al,bl

tdev_crc_loop:
	call OutputBit
	shr al,1
	loop tdev_crc_loop
;
	xor al,al
	call OutputBit
	call Delay
;
	add dx,2
	in al,dx
	sub dx,2
	and al,1
	stc
	jz toggle_digital_done
;
	clc

toggle_digital_done:
	pushf
	cli
	in al,dx
	and al,NOT 6
	out dx,al
	sti
	call Delay
;
	cli
	in al,dx
	and al,NOT 7
	out dx,al
	sti
	popf
;
	pop si
	pop dx
	pop bx
	pop ax
	retf32
toggle_digital_line	Endp

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
    mov dx,28Bh
    mov al,8Bh
    out dx,al
;
	mov dx,288h
	in al,dx
	and al,NOT 7
	out dx,al
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET read_digital
	mov di,OFFSET read_digital_name
	mov ax,read_digital_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET toggle_digital_line
	mov di,OFFSET toggle_digital_line_name
	mov ax,toggle_digital_line_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
