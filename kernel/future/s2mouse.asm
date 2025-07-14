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
; S2MOUSE.ASM
; Support for serial mouse on COM2:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IRQ = 3
IO_BASE = 2F8h
;                       ##GIL ##
GREET_BYTE_COUNT = 0Dh
;                       ##GIL END##

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc

	.386p

mouse_data_seg	SEGMENT AT 0

md_buttons		DB ?
md_dx			DB ?
md_dy			DB ?
md_pos			DW ?
;                                       ##GIL ##
greeting_mouse          DB ?            ;indicator
greet_count             DW ?            ;number of byte for greeting
mouse_init2             DB ?            ;for hot initialisation of the mouse 
                                        ;without restarting the machine
;                                       ##GIL ##
mouse_data_seg	ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			mus_int
;
;		DESCRIPTION:	int handler
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mus_int	proc far
;			##GIL ##
	mov 	dx,IO_BASE + 5
	in	al,dx
	test	al,1
	jz	mus_not_moved
;                       ##GIL END##

	mov dx,IO_BASE
	in al,dx
;                       ##GIL ##
;GREET_BYTE_COUNT = SIZE (4D 33 08 01 24 2C 27 29 18 10 10 11 09)  this is my mouse sequence of greeting
;greeting  my mouse

        cmp     ds:greeting_mouse,0
        jnz     short mus_go_on

        cmp     al,'M'                  ;is it a reinitialiation ?
        jz      short mus_init

        cmp     ds:mouse_init2,1
        jz      short  mus_reinit

        mov     ds:greeting_mouse,1
        jmp     mus_go_on
;
mus_init:
        mov     ds:mouse_init2,1           ;this is for hot reinitialisation

mus_reinit:
;        
        mov     bx,ds:greet_count
        inc     bx
        cmp     bx,GREET_BYTE_COUNT
        jb      short mus_greet
        mov     ds:greeting_mouse,1
        jmp     short mus_not_moved
;
mus_greet:
        mov     ds:greet_count,bx
        jmp     short mus_not_moved

;come here only when greeting is ok

mus_go_on:

;                       ##GIL END##

	mov bx,ds:md_pos
	test al,40h
	jz mus_int_coord
	xor bx,bx
mus_int_coord:
	mov [bx],al		;620:11 is here  the protected fault
	inc bx
	mov ds:md_pos,bx
	cmp bx,3
	jne mus_not_moved
	mov cl,ds:md_dx
	and cl,3Fh
	test cl,20h
	jz mus_x_pos
	or cl,0C0h
mus_x_pos:
	mov ch,ds:md_dy	
	and ch,3Fh
	test ch,20h
	jz mus_y_pos
	or ch,0C0h
mus_y_pos:
	or cx,cx
	jz mus_not_moved
;
	movzx ax,ds:md_buttons
	movzx cx,cl
	movzx dx,ch
	UpdateMouse

mus_not_moved:
	ret
mus_int	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_MOUSE
;
;		DESCRIPTION:	Init mouse
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mouse_name	DB 'Init Mouse', 0

init_mouse	Proc far
	push ds
	push es
;
	mov al,IRQ
	mov bx,mousedev_data_sel
	mov ds,bx
	mov bx,cs
	mov es,bx
	mov di,OFFSET mus_int
	RequestPrivateIrqHandler
;
	mov dx,IO_BASE+3
	mov al,83h
	out dx,al				; set line control to divisor access
;
	mov dx,IO_BASE
	mov al,96
	out dx,al				; output LSB divisor latch
;
	mov dx,IO_BASE+1
	mov al,0
	out dx,al				; output MSB divisor latch
;
	mov dx,IO_BASE+3
	mov al,2
	out dx,al				; set line control to 7 bits, 1 stop and no parity
;
	mov dx,IO_BASE+1
	mov al,1
	out dx,al				; enable rx ints, disable tx, line and modem ints
;
	mov dx,IO_BASE+4
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
;
;			##GIL ##
	mov dx,IO_BASE+2
	mov al,3
	out dx,al				; enable FIFO  trigger level set to 1,clear received FIFO

;			##GIL END ##
	pop es
	pop ds
	ret
init_mouse	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init mouse device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	pusha
	push 	ds
;
	mov 	bx,mousedev_code_sel
	InitDevice
;
	mov 	eax,SIZE mouse_data_seg
	mov 	bx,mousedev_data_sel
	AllocateFixedSystemMem
	mov 	es:md_pos,0
;                                       ##GIL ##
        mov     es:greeting_mouse,0
        mov     es:greet_count,0
        mov     es:mouse_init2,0
;                                       ##GIL END ##
;
	mov 	ax,cs
	mov 	ds,ax
	mov 	es,ax
	mov 	si,OFFSET init_mouse
	mov 	di,OFFSET init_mouse_name
	xor 	cl,cl
	mov 	ax,init_mouse_nr
	RegisterOsGate
;
	pop 	ds
	popa
	ret
init	ENDP

code	ENDS

	END init

