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
; PICLCD.ASM
; PIC LCD driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME piclcd

GateSize = 16

INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\video.inc

	.386p

NODE_CNT            = 40h

DQE_STAT_DONE       = 1
DQE_STAT_TIMEOUT    = 2
DQE_STAT_SUCCESS    = 4
DQE_STAT_COMPLETE   = 8

digio_queue_entry   STRUC

dqe_prev    DW ?
dqe_next    DW ?

dqe_stat    DB ?
dqe_device  DB ?
dqe_val     DB ?
dqe_node    DB ?
dqe_cmd     DB ?
dqe_line    DB ?
dqe_timeout DD ?
dqe_data    DD ?
dqe_proc    DW ?
dqe_action  DW ?
dqe_thread  DW ?

digio_queue_entry   ENDS

data_seg    STRUC

DcfThread   DW ?
DcfVal      DB ?

PicThread   DW ?
PicStatus   DB ?

SernetThread    DW ?

ListSection section_typ <>

DioQueue    DW ?,?,?
DioCurr     DW ?,?,?

NodeArr     DB NODE_CNT DUP(?)

data_seg    ENDS

    LCD_WIDTH = 240
    LCD_HEIGHT = 128

video_object	STRUC

v_base		        video_api_struc <>
vl_set_proc         DD ?
vl_slab_proc        DD ?
vl_copy_proc        DD ?
vl_mask_set_proc    DD ?
vl_mask_copy_proc   DD ?
vl_has_focus        DB ?

video_object	ENDS

WriteControl    Macro
    local wait
    
    push ax
    mov dx,3B1h

wait:
    in al,dx
    and al,3
    cmp al,3
    jne wait    
;
    pop ax
    out dx,al
                Endm

                
WriteData    Macro
    local wait

    push ax
    mov dx,3B1h

wait:
    in al,dx
    and al,3
    cmp al,3
    jne wait
;
    pop ax        
    dec dx
    out dx,al
                Endm

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReverseTab
;
;		DESCRIPTION:	Reverse bits in a byte
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReverseTab:
r00	DB 00000000b, 10000000b, 01000000b, 11000000b, 00100000b, 10100000b, 01100000b, 11100000b
r08	DB 00010000b, 10010000b, 01010000b, 11010000b, 00110000b, 10110000b, 01110000b, 11110000b
r10	DB 00001000b, 10001000b, 01001000b, 11001000b, 00101000b, 10101000b, 01101000b, 11101000b
r18	DB 00011000b, 10011000b, 01011000b, 11011000b, 00111000b, 10111000b, 01111000b, 11111000b
r20	DB 00000100b, 10000100b, 01000100b, 11000100b, 00100100b, 10100100b, 01100100b, 11100100b
r28	DB 00010100b, 10010100b, 01010100b, 11010100b, 00110100b, 10110100b, 01110100b, 11110100b
r30	DB 00001100b, 10001100b, 01001100b, 11001100b, 00101100b, 10101100b, 01101100b, 11101100b
r38	DB 00011100b, 10011100b, 01011100b, 11011100b, 00111100b, 10111100b, 01111100b, 11111100b
r40	DB 00000010b, 10000010b, 01000010b, 11000010b, 00100010b, 10100010b, 01100010b, 11100010b
r48	DB 00010010b, 10010010b, 01010010b, 11010010b, 00110010b, 10110010b, 01110010b, 11110010b
r50	DB 00001010b, 10001010b, 01001010b, 11001010b, 00101010b, 10101010b, 01101010b, 11101010b
r58	DB 00011010b, 10011010b, 01011010b, 11011010b, 00111010b, 10111010b, 01111010b, 11111010b
r60	DB 00000110b, 10000110b, 01000110b, 11000110b, 00100110b, 10100110b, 01100110b, 11100110b
r68	DB 00010110b, 10010110b, 01010110b, 11010110b, 00110110b, 10110110b, 01110110b, 11110110b
r70	DB 00001110b, 10001110b, 01001110b, 11001110b, 00101110b, 10101110b, 01101110b, 11101110b
r78	DB 00011110b, 10011110b, 01011110b, 11011110b, 00111110b, 10111110b, 01111110b, 11111110b
r80	DB 00000001b, 10000001b, 01000001b, 11000001b, 00100001b, 10100001b, 01100001b, 11100001b
r88	DB 00010001b, 10010001b, 01010001b, 11010001b, 00110001b, 10110001b, 01110001b, 11110001b
r90	DB 00001001b, 10001001b, 01001001b, 11001001b, 00101001b, 10101001b, 01101001b, 11101001b
r98	DB 00011001b, 10011001b, 01011001b, 11011001b, 00111001b, 10111001b, 01111001b, 11111001b
rA0	DB 00000101b, 10000101b, 01000101b, 11000101b, 00100101b, 10100101b, 01100101b, 11100101b
rA8	DB 00010101b, 10010101b, 01010101b, 11010101b, 00110101b, 10110101b, 01110101b, 11110101b
rB0	DB 00001101b, 10001101b, 01001101b, 11001101b, 00101101b, 10101101b, 01101101b, 11101101b
rB8	DB 00011101b, 10011101b, 01011101b, 11011101b, 00111101b, 10111101b, 01111101b, 11111101b
rC0	DB 00000011b, 10000011b, 01000011b, 11000011b, 00100011b, 10100011b, 01100011b, 11100011b
rC8	DB 00010011b, 10010011b, 01010011b, 11010011b, 00110011b, 10110011b, 01110011b, 11110011b
rD0	DB 00001011b, 10001011b, 01001011b, 11001011b, 00101011b, 10101011b, 01101011b, 11101011b
rD8	DB 00011011b, 10011011b, 01011011b, 11011011b, 00111011b, 10111011b, 01111011b, 11111011b
rE0	DB 00000111b, 10000111b, 01000111b, 11000111b, 00100111b, 10100111b, 01100111b, 11100111b
rE8	DB 00010111b, 10010111b, 01010111b, 11010111b, 00110111b, 10110111b, 01110111b, 11110111b
rF0	DB 00001111b, 10001111b, 01001111b, 11001111b, 00101111b, 10101111b, 01101111b, 11101111b
rF8	DB 00011111b, 10011111b, 01011111b, 11011111b, 00111111b, 10111111b, 01111111b, 11111111b

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			switch_to
;
;		DESCRIPTION:	Enter focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switch_to	Proc far
    push es
	pushad
;
;	EnterSection ds:v_section
	mov ds:vl_has_focus,1
;
    mov ax,flat_sel
    mov es,ax
;
    xor al,al
    WriteData
    xor al,al
    WriteData
    mov al,24h
    WriteControl
;
    mov al,0B0h
    WriteControl
;
	mov cx,(LCD_WIDTH / 8) * LCD_HEIGHT
    mov esi,ds:v_app_base
	mov bx,OFFSET ReverseTab

switch_to_loop:
    mov al,es:[esi]
	xlat byte ptr cs:ReverseTab 
    WriteData
    inc esi
    loop switch_to_loop
;    
    mov al,0B2h
    WriteControl
;
;	LeaveSection ds:v_section
;
	popad
	pop es
	ret
switch_to	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SwitchFrom
;
;		DESCRIPTION:	Leave focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switch_from	Proc far
	mov ds:vl_has_focus,0
	ret
switch_from	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetBase
;
;		DESCRIPTION:	Basic set pixel
;
;		PARAMETER:		EAX         Color
;						EDI         Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_base	Proc far
    push ax
	push bx
    push edx
;
    call ds:vl_set_proc
    mov al,ds:vl_has_focus
    or al,al
    jz set_base_done
;
    mov edx,edi
    shr edx,3
;
    mov al,dl
	push dx
    WriteData
	pop dx
;
    mov al,dh
	push dx
    WriteData
	pop dx
;
    mov al,24h
	push dx
    WriteControl
	pop dx
;
    mov al,0B0h
	push dx
    WriteControl
	pop dx
;
    add edx,ds:v_app_base
	mov bx,OFFSET ReverseTab
    mov al,es:[edx]
	xlat byte ptr cs:ReverseTab 
    WriteData
;
    mov al,0B2h
    WriteControl

set_base_done:
    pop edx
	pop bx
    pop ax
    ret
set_base    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Slab
;
;		DESCRIPTION:	Fill line
;
;		PARAMETERS:		AX			Color
;					    EDI		    position
;						CX			number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

slab	Proc far
    push ax
	push bx
    push ecx
    push edx
	push esi
;
    call ds:vl_slab_proc
    mov al,ds:vl_has_focus
    or al,al
    jz slab_done
;
    mov edx,edi
    shr edx,3
;
    movzx ecx,cx
    add ecx,edi
    dec ecx
    shr ecx,3
    inc ecx
    sub ecx,edx
;    
    mov al,dl
	push dx
    WriteData
	pop dx
;
    mov al,dh
	push dx
    WriteData
	pop dx
;
    mov al,24h
	push dx
    WriteControl
	pop dx
;
    mov al,0B0h
	push dx
    WriteControl
	pop dx
;
	mov bx,OFFSET ReverseTab
    add edx,ds:v_app_base
	mov esi,edx

slab_loop:
    mov al,es:[esi]
	xlat byte ptr cs:ReverseTab 
    WriteData
    inc esi
    loop slab_loop
;    
    mov al,0B2h
    WriteControl

slab_done:
	pop esi
    pop edx
    pop ecx
	pop bx
    pop ax
	ret
slab	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Copy
;
;		DESCRIPTION:	Copy line
;
;		PARAMETERS:		EAX         Source base
;                       FS:ESI      Source position
;					    EDI		    Dest position
;						CX			number of pixels
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy	Proc far
    push ax
	push bx
    push ecx
    push edx
	push esi
;
    call ds:vl_copy_proc
    mov al,ds:vl_has_focus
    or al,al
    jz copy_done
;
    mov edx,edi
    shr edx,3
;
    movzx ecx,cx
    add ecx,edi
    dec ecx
    shr ecx,3
    inc ecx
    sub ecx,edx
;    
    mov al,dl
	push dx
    WriteData
	pop dx
;
    mov al,dh
	push dx
    WriteData
	pop dx
;
    mov al,24h
	push dx
    WriteControl
	pop dx
;
    mov al,0B0h
	push dx
    WriteControl
	pop dx
;
	mov bx,OFFSET ReverseTab
    add edx,ds:v_app_base
	mov esi,edx

copy_loop:
    mov al,es:[esi]
	xlat byte ptr cs:ReverseTab 
    WriteData
    inc esi
    loop copy_loop
;    
    mov al,0B2h
    WriteControl

copy_done:
	pop esi
    pop edx
    pop ecx
	pop bx
    pop ax
    ret
copy    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			MaskSet
;
;		DESCRIPTION:	Set mask line
;
;		PARAMETERS:		EAX         Color
;						CX			number of pixels
;                       DL          Start bit number
;                       GS:EBX      Mask bits
;						ES:EDI		Dest buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mask_set	Proc far
    push ax
	push bx
    push ecx
    push edx
	push esi
;
    call ds:vl_mask_set_proc
    mov al,ds:vl_has_focus
    or al,al
    jz mask_set_done
;
    mov edx,edi
    shr edx,3
;
    movzx ecx,cx
    add ecx,edi
    dec ecx
    shr ecx,3
    inc ecx
    sub ecx,edx
;    
    mov al,dl
	push dx
    WriteData
	pop dx
;
    mov al,dh
	push dx
    WriteData
	pop dx
;
    mov al,24h
	push dx
    WriteControl
	pop dx
;
    mov al,0B0h
	push dx
    WriteControl
	pop dx
;
	mov bx,OFFSET ReverseTab
    add edx,ds:v_app_base
	mov esi,edx

mask_set_loop:
    mov al,es:[esi]
	xlat byte ptr cs:ReverseTab 
    WriteData
    inc esi
    loop mask_set_loop
;    
    mov al,0B2h
    WriteControl

mask_set_done:
	pop esi
    pop edx
    pop ecx
	pop bx
    pop ax
    ret
mask_set    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			MaskCopy
;
;		DESCRIPTION:	Copy mask line
;
;		PARAMETERS:		CX			number of pixels
;                       DL          Start bit number
;                       FS:ESI      Source pixels
;                       GS:EBX      Mask bits 
;						ES:EDI		Dest buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mask_copy	Proc far
    push ax
	push bx
    push ecx
    push edx
	push esi
;
    call ds:vl_mask_copy_proc
    mov al,ds:vl_has_focus
    or al,al
    jz mask_copy_done
;
    mov edx,edi
    shr edx,3
;
    movzx ecx,cx
    add ecx,edi
    dec ecx
    shr ecx,3
    inc ecx
    sub ecx,edx
;    
    mov al,dl
	push dx
    WriteData
	pop dx
;
    mov al,dh
	push dx
    WriteData
	pop dx
;
    mov al,24h
	push dx
    WriteControl
	pop dx
;
    mov al,0B0h
	push dx
    WriteControl
	pop dx
;
	mov bx,OFFSET ReverseTab
    add edx,ds:v_app_base
	mov esi,edx

mask_copy_loop:
    mov al,es:[esi]
	xlat byte ptr cs:ReverseTab 
    WriteData
    inc esi
    loop mask_copy_loop
;    
    mov al,0B2h
    WriteControl

mask_copy_done:
	pop esi
    pop edx
    pop ecx
	pop bx
    pop ax
    ret
mask_copy    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_mode
;
;		DESCRIPTION:	Init video-mode
;
;		RETURNS:		AX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mode	Proc far
	push ds
	push es
	push ecx
	push dx
	push si
	push edi
;
	mov ax,es
	mov ds,ax
	mov ax,128
	shl ax,2
	add ax,SIZE video_object
	movzx eax,ax
	AllocateSmallGlobalMem
    mov es:v_sprite_lines,SIZE video_object
;
	mov al,1
	mov cx,LCD_WIDTH
	mov dx,LCD_HEIGHT
	InitVideoBitmap
;
	mov es:v_mode,1000h
	mov es:vl_has_focus,0
;
	mov eax,LCD_WIDTH / 8
	mov es:v_row_size,ax
;
	mov edx,LCD_HEIGHT
	mul edx
	dec eax
	and ax,0F000h
	add eax,1000h
	mov es:v_app_size,eax
	AllocateSmallLinear
	mov es:v_app_base,edx
;
	push es
	mov edi,edx
	mov ecx,eax
	mov ax,flat_sel
	mov es,ax
	xor al,al
	rep stos byte ptr es:[edi]
	pop es
;
    mov bx,cs
    shl ebx,16
;
	mov eax,es:set_proc
	mov es:vl_set_proc,eax
	mov bx,OFFSET set_base
	mov es:set_proc,ebx
;
	mov eax,es:slab_proc
	mov es:vl_slab_proc,eax
	mov bx,OFFSET slab
	mov es:slab_proc,ebx
;
	mov eax,es:copy_proc
	mov es:vl_copy_proc,eax
	mov bx,OFFSET copy
	mov es:copy_proc,ebx
;
	mov eax,es:mask_set_proc
	mov es:vl_mask_set_proc,eax
	mov bx,OFFSET mask_set
	mov es:mask_set_proc,ebx
;
	mov eax,es:mask_copy_proc
	mov es:vl_mask_copy_proc,eax
	mov bx,OFFSET mask_copy
	mov es:mask_copy_proc,ebx
;
    mov bx,OFFSET switch_to
    mov es:switch_to_proc,ebx
;
    mov bx,OFFSET switch_from
    mov es:switch_from_proc,ebx
	mov ax,es
	clc
;
	pop edi
	pop si
	pop dx
	pop ecx
	pop es
	pop ds
	ret
init_mode	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitLCD
;
;		DESCRIPTION:	Init LCD module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitLCD Proc near
    mov al,81h      ; CGROM mode, OR mode
    WriteControl
;
    xor al,al
    WriteData
    xor al,al
    WriteData
    mov al,42h
    WriteControl    ; set graphics home = 0000
;
    mov al,LCD_WIDTH / 8
    WriteData
    xor al,al
    WriteData
    mov al,43h
    WriteControl    ; set graphics area = 001E
;
    xor al,al
    WriteData
    mov al,20h
    WriteData
    mov al,40h
    WriteControl    ; set text home = 2000
;
    mov al,LCD_WIDTH / 8
    WriteData
    xor al,al
    WriteData
    mov al,41h
    WriteControl    ; set text area = 0028
;
    mov al,3
    WriteData
    xor al,al
    WriteData
    mov al,22h
    WriteControl    ; set CGRAM offset = 03
;
    mov al,9Ah
    WriteControl    ; graphics on, text on, cursor off
;
    xor al,al
    WriteData
    xor al,al
    WriteData
    mov al,24h
    WriteControl
;
    mov al,0B0h
    WriteControl
;
	mov cx,(LCD_WIDTH / 8) * LCD_HEIGHT

zero_lcd_loop:
	xor al,al
	WriteData
	loop zero_lcd_loop
;    
    mov al,0B2h
    WriteControl
;
	ret
InitLCD Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			pic_int
;
;		DESCRIPTION:	PIC interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pic_int Proc far

pic_int_loop:
    mov dx,3B2h
    in al,dx
    test al,1
    jnz pic_int_not0
;
    mov dx,3B6h
    out dx,al
;    
    mov bx,ds:SernetThread
    Signal
    jmp pic_int_loop    

pic_int_not0:    
    test al,2
    jnz pic_int_not1
;
    mov dx,3BAh
	in al,dx
    mov dx,ds:DioCurr
    or dx,dx
    jz pic_int_loop
;
    mov es,dx
    and al,3Fh
    mov es:dqe_val,al
    or es:dqe_stat,DQE_STAT_DONE    	
;    
	mov bx,ds:PicThread
	Signal
	jmp pic_int_loop

pic_int_not1:
    test al,4
    jnz pic_int_not2
;    
    mov dx,3BCh
	in al,dx
	mov dx,ds:DioCurr+2
	or dx,dx
	jz pic_int_loop
;	
    mov es,dx
    and al,3Fh
    mov es:dqe_val,al
    or es:dqe_stat,DQE_STAT_DONE
;	
	mov bx,ds:PicThread
	Signal
	jmp pic_int_loop

pic_int_not2:
    test al,8
    jnz pic_int_not3
;    
    mov dx,3BEh
	in al,dx
	mov dx,ds:DioCurr+4
	or dx,dx
	jz pic_int_loop
;
    mov es,dx
    and al,3Fh
    mov es:dqe_val,al
    or es:dqe_stat,DQE_STAT_DONE
;	
	mov bx,ds:PicThread
	Signal
	jmp pic_int_loop


pic_int_not3:
    test al,10h
    jnz pic_int_done    
;
    mov dx,3B4h
    in al,dx
    mov ds:DcfVal,al
    mov bx,ds:DcfThread
    Signal
    jmp pic_int_loop
    
pic_int_done:
    ret
pic_int Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DioInsert
;
;		DESCRIPTION:	Insert entry into digital-io queue
;
;       PARAMETERS:     DS:DI       Queue
;                       ES          Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioInsert	Proc near
	push di
	mov di,[di]
	or di,di
	je ins_empty
;	
	push ds
	push si
	mov ds,di
	mov si,ds:dqe_prev
	mov ds:dqe_prev,es
	mov ds,si
	mov ds:dqe_next,es
	mov es:dqe_next,di
	mov es:dqe_prev,si
	pop si
	pop ds
	pop di
	jmp ins_done
	
ins_empty:
	mov es:dqe_next,es
	mov es:dqe_prev,es
	pop di
	mov [di],es

ins_done:
    ret
DioInsert   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DioRemove
;
;		DESCRIPTION:	Remove head entry from digital-io queue
;
;       PARAMETERS:     DS:SI       Queue
;
;       RETURNS:        ES          Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioRemove	Proc near
	push si
	mov es,[si]
	push di
	push ds
	mov di,es:dqe_next
	cmp di,[si]
	mov [si],di
	mov si,es:dqe_prev
	mov ds,di
	mov ds:dqe_prev,si
	mov ds,si
	mov ds:dqe_next,di
	pop ds
	pop di
	pop si
	jne rem_done
	
	mov word ptr [si],0

rem_done:
    ret
DioRemove   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DioTimeout
;
;		description:	Sends a signal when a timeout expires
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioTimeout	Proc far
    push es
;    
    mov es,cx
    or es:dqe_stat,DQE_STAT_TIMEOUT
;
	mov bx,piclcd_data_sel
	mov ds,bx
    mov bx,ds:PicThread
    Signal
;
    pop es    
    ret
DioTimeout  Endp
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DioRun
;
;		description:	Run dio-command
;
;       PARAMETERS:     ES      Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioRun  Proc near 
    push es
    pushad
;
    movzx ax,es:dqe_device    
   
drClearLoop:
    push ax
    mov cl,al
    mov ah,2
    shl ah,cl
;    
    mov dx,3B2h
    in al,dx
    test al,ah
    pop ax
    jnz drDo
;
    mov dx,3BAh
    add dx,ax
    add dx,ax
    push ax
    in al,dx
    pop ax
    jmp drClearLoop

drDo:
    and es:dqe_stat,NOT (DQE_STAT_DONE OR DQE_STAT_TIMEOUT)
    mov di,ax
    add di,di
    add di,OFFSET DioCurr
    mov [di],es
;   
    mov dx,3BAh
    add dx,ax
    add dx,ax
    mov al,es:dqe_val
    out dx,al
;
    mov cx,es
	GetSystemTime
	add eax,es:dqe_timeout
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET DioTimeout
	mov bx,cx
	StartTimer
;
    popad
    pop es
    ret
DioRun  Endp
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioStartReq
;
;		description:	Start a request
;
;       PARAMETERS:     AX      Queue #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioStartReq Proc near
    push es
    push si
    push di
;    
    mov si,ax
    add si,si
    add si,OFFSET DioQueue
    mov di,[si]
    or di,di
    jz dsrDone
;
    call DioRemove
    call DioRun

dsrDone:
    pop di
    pop si
    pop es
    ret
DioStartReq Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioCheckReq
;
;		description:	Check current req
;
;       PARAMETERS:     AX      Queue #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioCheckReq Proc near
    push es
    pushad
;    
    mov si,ax
    add si,si
    add si,OFFSET DioCurr
    mov es,[si]
;
    test es:dqe_stat,DQE_STAT_DONE
    jnz dcrRemove
;
    test es:dqe_stat,DQE_STAT_TIMEOUT
    jz dcrDone
;
    push ax
    mov cl,al
    mov ah,2
    shl ah,cl
;    
    mov dx,3B2h
    in al,dx
    test al,ah
    pop ax
    jnz dcrRemove
;
    mov dx,3BAh
    add dx,ax
    add dx,ax
    in al,dx
    and al,3Fh
    mov es:dqe_val,al
    or es:dqe_stat,DQE_STAT_DONE

dcrRemove:
    mov word ptr [si],0
    mov bx,es
    StopTimer
    call es:dqe_proc
    jc dcrFree
;
    mov ds:[si],es
    call DioRun
    jmp dcrDone

dcrFree:
    or es:dqe_stat,DQE_STAT_COMPLETE
    mov bx,es:dqe_thread
    Signal

dcrDone:
    popad
    pop es
    ret
DioCheckReq Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioUpdate
;
;		description:	Dio Update
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioUpdate   Proc near
    push ax
    push cx
    push dx
    push si
;    
    mov cx,3
    xor ax,ax
    mov si,OFFSET DioCurr

duLoop:
    mov dx,[si]
    or dx,dx
    jz duFree
;
    call DioCheckReq
    mov dx,[si]
    or dx,dx
    jnz duNext

duFree:
    call DioStartReq

duNext:   
    add si,2
    inc ax
    loop duLoop
;
    pop si
    pop dx
    pop cx
    pop ax
    ret
DioUpdate   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioOneReq
;
;		description:	Dio req, specified queue
;
;       PARAMETERS:     AX      Queue #
;                       EDX     Timeout in tics
;                       EBP     Data
;                       BL      Cmd #
;                       CL      Line #
;                       CH      Node #
;                       DI      Action proc
;
;       RETURNS:        EAX     Data returned
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioOneReq   Proc near
    push ds
    push es
    push bx
    push di
;    
    ClearSignal
    push ax
    mov ax,piclcd_data_sel
    mov ds,ax    
    mov eax,SIZE digio_queue_entry
    AllocateSmallGlobalMem
    GetThread
    mov es:dqe_thread,ax
    pop ax
    mov es:dqe_device,al
    mov es:dqe_stat,0
    mov es:dqe_timeout,edx
    mov es:dqe_proc,OFFSET node_proc
    mov es:dqe_node,ch
    mov es:dqe_line,cl
    mov es:dqe_cmd,bl
    mov es:dqe_data,ebp
    mov es:dqe_action,di
    EnterSection ds:ListSection
    push ax
    call es:dqe_proc
    pop ax
;
    mov di,OFFSET DioQueue
    add di,ax
    add di,ax
    call DioInsert
    LeaveSection ds:ListSection
;
    mov bx,ds:PicThread
    Signal    
    WaitForSignal
;
    mov eax,es:dqe_data
    mov bl,es:dqe_stat
    FreeMem
    test bl,DQE_STAT_SUCCESS
    stc
    jz dorDone
;
    clc

dorDone:
    pop di
    pop bx
    pop es
    pop ds
    ret
DioOneReq    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioAllReq
;
;		description:	Broadcase dio req
;
;       PARAMETERS:     EDX     Timeout in tics
;                       EBP     Data
;                       BL      Cmd #
;                       CL      Line #
;                       CH      Node #
;                       DI      Action proc
;
;       RETURNS:        EAX     Data returned
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioAllReq   Proc near
    push ds
    push es
    push fs
    push bx
    push si
    push di
;    
    ClearSignal
    mov ax,piclcd_data_sel
    mov ds,ax    
    mov eax,6
    AllocateSmallGlobalMem
    mov ax,es
    mov fs,ax
    xor si,si
;
    xor ax,ax    

darAllocLoop:
    push ax
    mov eax,SIZE digio_queue_entry
    AllocateSmallGlobalMem
    GetThread
    mov fs:[si],es
    mov es:dqe_thread,ax
    pop ax
    mov es:dqe_device,al
    mov es:dqe_stat,0
    mov es:dqe_timeout,edx
    mov es:dqe_proc,OFFSET node_proc
    mov es:dqe_node,ch
    mov es:dqe_line,cl
    mov es:dqe_cmd,bl
    mov es:dqe_data,ebp
    mov es:dqe_action,di
    EnterSection ds:ListSection
    push ax
    call es:dqe_proc
    pop ax
;
    push di
    mov di,OFFSET DioQueue
    add di,ax
    add di,ax
    call DioInsert
    pop di
    LeaveSection ds:ListSection
;    
    add si,2
    inc ax
    cmp ax,3
    jne darAllocLoop    
;
    mov bx,ds:PicThread
    Signal

darSignalLoop:
    WaitForSignal
;   
    mov cx,3
    xor si,si

darCheckLoop:
    mov es,fs:[si]
    test es:dqe_stat, DQE_STAT_COMPLETE
    jz darSignalLoop
;
    add si,2
    loop darCheckLoop    
; 
    mov cx,3
    xor si,si

darFreeLoop:
    mov es,fs:[si]
    mov eax,es:dqe_data
    mov bl,es:dqe_stat
    test bl,DQE_STAT_SUCCESS
    jnz darOk
;
    FreeMem
    add si,2
    loop darFreeLoop    
;
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
    stc
    jmp darDone

darOk:
    movzx bx,es:dqe_node
    push ax
    mov ax,si
    shr ax,1
    mov ds:[bx].NodeArr,al
    pop ax
    FreeMem
    add si,2
    sub cx,1
    jz darOkDone

darOkLoop:
    mov es,fs:[si]
    FreeMem
    add si,2
    loop darOkLoop

darOkDone:
    mov dx,fs
    mov es,dx
    xor dx,dx
    mov fs,dx
    FreeMem
    clc    

darDone:
    pop di
    pop si
    pop bx
    pop fs
    pop es
    pop ds
    ret
DioAllReq    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DioReq
;
;		description:    Dio req
;
;       PARAMETERS:     EDX     Timeout in tics
;                       EBP     Data
;                       BL      Cmd #
;                       CL      Line #
;                       CH      Node #
;                       DI      Action proc
;
;       RETURNS:        EAX     Data returned
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DioReq  Proc near
    push ds
;    
    mov ax,piclcd_data_sel
    mov ds,ax
    push bx
    movzx bx,ch
    mov al,ds:[bx].NodeArr
    pop bx
    cmp al,-1
    je drAll
;
    movzx ax,al
    call DioOneReq
    jnc drDone
;
    push bx
    movzx bx,ch
    mov byte ptr ds:[bx].NodeArr,-1
    pop bx
    stc
    jmp drDone
    
drAll:
    call DioAllReq 

drDone:   
    pop ds
    ret
DioReq  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			node_proc
;
;       PARAMETERS:     ES      Req block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

node_proc   Proc near
    mov al,es:dqe_node
    mov es:dqe_val,al
    mov es:dqe_proc, OFFSET cmd_proc
    clc
    ret
node_proc   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			cmd_proc
;
;       PARAMETERS:     ES      Req block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cmd_proc   Proc near
    mov al,es:dqe_val
    and al,3Fh
    cmp al,1Ah
    stc
    jnz cmd_done
;    
    mov ah,es:dqe_cmd
    mov al,es:dqe_line
    shl al,3
    or al,ah
    mov es:dqe_val,al
    mov ax,es:dqe_action
    mov es:dqe_proc,ax
    clc

cmd_done:
    ret
cmd_proc   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			PIC thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pic_name	DB 'PICLCD',0

pic_thread:
    mov ax,piclcd_data_sel
    mov ds,ax    
    GetThread
    mov ds:PicThread,ax    
    ClearSignal

pic_thread_loop: 
    EnterSection ds:ListSection
    call DioUpdate   
    LeaveSection ds:ListSection
	WaitForSignal
    jmp pic_thread_loop

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

toggle_proc    Proc near
    or es:dqe_stat,DQE_STAT_SUCCESS
    stc
    ret
toggle_proc    Endp

toggle_serial_line	Proc far
	push bx
	push cx
    push edx
    push di
;
    push ebp
    mov ebp,5000
    mov cx,dx
    mov edx,1193 * 100
    mov di,OFFSET toggle_proc
    mov bl,4
    call DioReq
    pop ebp
;
	pop di
	pop edx
	pop cx
	pop bx
	retf32
toggle_serial_line  Endp

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

rl0_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz rl0_done
;    
    mov es:dqe_data,0
    mov es:dqe_val,1
    mov es:dqe_proc,OFFSET rl1_proc
    clc

rl0_done:
    ret
rl0_proc    Endp

rl1_proc    Proc near
    mov al,es:dqe_val
    test al,30h
    stc
    jz rl1_done
;    
    and eax,0Fh
    or es:dqe_data,eax
    mov es:dqe_val,2
    mov es:dqe_proc,OFFSET rl2_proc
    clc

rl1_done:
    ret
rl1_proc    Endp

rl2_proc    Proc near
    mov al,es:dqe_val
    test al,30h
    stc
    jz rl2_done
;    
    and eax,0Fh
    shl eax,4
    or es:dqe_data,eax
    mov es:dqe_val,3
    or es:dqe_stat,DQE_STAT_SUCCESS

rl2_done:
    stc
    ret
rl2_proc    Endp

read_serial_lines	Proc far
	push bx
	push cx
    push edx
    push di
;
    push ebp
    mov ebp,5000
    mov ch,dh
    xor cl,cl
    mov edx,1193 * 100
    mov di,OFFSET rl0_proc
    mov bl,5
    call DioReq
    pop ebp
;
	pop di
	pop edx
	pop cx
	pop bx
	retf32
read_serial_lines	Endp

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

wr0_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz wr0_done
;    
    mov eax,es:dqe_data
    and al,3Fh
    mov es:dqe_val,al
    mov es:dqe_proc,OFFSET wr1_proc
    clc

wr0_done:
    ret
wr0_proc    Endp

wr1_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz wr1_done
;    
    mov eax,es:dqe_data
    shr eax,6
    and al,3Fh
    mov es:dqe_val,al
    mov es:dqe_proc,OFFSET wr2_proc
    clc

wr1_done:
    ret
wr1_proc    Endp

wr2_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz wr1_done
;    
    mov eax,es:dqe_data
    shr eax,12
    and al,3Fh
    mov es:dqe_val,al
    mov es:dqe_proc,OFFSET wr3_proc
    clc

wr2_done:
    ret
wr2_proc    Endp

wr3_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz wr3_done
;    
    mov eax,es:dqe_data
    shr eax,18
    and al,3Fh
    mov es:dqe_val,al
    mov es:dqe_proc,OFFSET wr_check_proc
    clc

wr3_done:
    ret
wr3_proc    Endp

wr_check_proc    Proc near
    mov al,es:dqe_val
    or al,al
    jz wr_check_done
;    
    or es:dqe_stat,DQE_STAT_SUCCESS

wr_check_done:    
    stc
    ret
wr_check_proc    Endp

write_serial_val	Proc far
	push eax
	push bx
	push cx
    push edx
    push di
    push ebp
;
    mov ebp,eax
    mov cx,dx
    mov edx,1193 * 100
    mov di,OFFSET wr0_proc
    mov bl,3
    call DioReq
;
	pop ebp
	pop di
	pop edx
	pop cx
	pop bx
	pop eax
	retf32
write_serial_val	Endp

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

rd0_proc    Proc near
    mov al,es:dqe_val
    or al,al
    stc
    jz rd0_done
;    
    mov es:dqe_data,0
    mov es:dqe_val,1
    mov es:dqe_proc,OFFSET rd1_proc
    clc

rd0_done:
    ret
rd0_proc    Endp

rd1_proc    Proc near
    mov al,es:dqe_val
    and eax,3Fh
    or es:dqe_data,eax
    mov es:dqe_val,2
    mov es:dqe_proc,OFFSET rd2_proc
    clc
    ret
rd1_proc    Endp

rd2_proc    Proc near
    mov al,es:dqe_val
    and eax,3Fh
    shl eax,6    
    or es:dqe_data,eax
    mov es:dqe_val,3
    mov es:dqe_proc,OFFSET rd3_proc
    clc
    ret
rd2_proc    Endp

rd3_proc    Proc near
    mov al,es:dqe_val
    and eax,3Fh
    shl eax,12  
    or es:dqe_data,eax
    mov es:dqe_val,4
    mov es:dqe_proc,OFFSET rd4_proc
    clc
    ret
rd3_proc    Endp

rd4_proc    Proc near
    mov al,es:dqe_val
    and eax,3Fh
    shl eax,18  
    or es:dqe_data,eax
    mov es:dqe_val,5
    mov es:dqe_proc,OFFSET rd_check_proc
    clc
    ret
rd4_proc    Endp

rd_check_proc    Proc near
    mov al,es:dqe_val
    or al,al
    jz rd_check_done
;    
    or es:dqe_stat,DQE_STAT_SUCCESS

rd_check_done:
    stc
    ret
rd_check_proc    Endp

read_serial_val	Proc far
	push bx
	push cx
    push edx
    push di
;
    push ebp
    mov ebp,5000
    mov cx,dx
    mov edx,1193 * 100
    mov di,OFFSET rd0_proc
    mov bl,2
    call DioReq
    pop ebp
;
	pop di
	pop edx
	pop cx
	pop bx
	retf32
read_serial_val	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			Sernet thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sernet_name	DB 'SERNET',0

sernet_thread:
    mov ax,25
    WaitMilliSec
;
    mov al,30h
    mov dx,3B2h
    out dx,al    
;
    mov ax,piclcd_data_sel
    mov ds,ax    
    GetThread
    mov ds:SernetThread,ax    
    ClearSignal

sernet_thread_loop:
    WaitForSignal
    mov dx,3B2h
    mov al,20h
    out dx,al
    mov al,30h
    out dx,al
    jmp sernet_thread_loop

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			DCF thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dcf_name	DB 'DCF',0

dcf_thread:
	mov ax,43h
	EnableFocus
;
    mov ax,piclcd_data_sel
    mov ds,ax    
    GetThread
    mov ds:DcfThread,ax    
    ClearSignal

dcf_thread_loop: 
	WaitForSignal
	mov al,ds:DcfVal
	WriteChar
    jmp dcf_thread_loop

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitDriver
;
;		DESCRIPTION:	Init Driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitDriver  Proc far
    push ds
    push es
    pushad
;    
	mov al,10
	mov bx,piclcd_data_sel
	mov ds,bx
	mov bx,cs
	mov es,bx
	mov di,OFFSET pic_int
	RequestPrivateIrqHandler
;    
    mov dx,3B4h
    in al,dx
;
    mov dx,3B2h
    in al,dx
;	
    mov dx,3B6h
    out dx,al
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET pic_name
	mov si,OFFSET pic_thread
	mov ax,4
	mov cx,100h
	CreateThread
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET sernet_name
	mov si,OFFSET sernet_thread
	mov ax,4
	mov cx,100h
	CreateThread
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET dcf_name
	mov si,OFFSET dcf_thread
	mov ax,4
	mov cx,100h
	CreateProcess
;
    popad
    pop es
    pop ds
    ret
InitDriver  Endp

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
			
init	PROC far
	push ds
	pusha
;
	mov bx,piclcd_code_sel
	InitDevice
;
	mov eax,SIZE data_seg
	mov bx,piclcd_data_sel
	AllocateFixedSystemMem
;	
    mov es:DcfThread,0
	mov es:PicThread,0
	mov es:SernetThread,0
	mov es:DioQueue,0
	mov es:DioQueue+2,0
	mov es:DioQueue+4,0
	mov es:DioCurr,0
	mov es:DioCurr+2,0
	mov es:DioCurr+4,0
	InitSection es:ListSection
;
    mov di,NodeArr
    mov cx,NODE_CNT
    mov al,-1
    rep stosb
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov dx,3B3h
	xor al,al
	out dx,al
;	
    mov dx,3B6h
    out dx,al
;    
    mov al,0
    mov dx,3B2h
    out dx,al
;
	mov ax,cs
	mov es,ax	
	mov ax,1000h
	mov bl,1
	mov cx,LCD_WIDTH
    mov dx,LCD_HEIGHT
	mov di,OFFSET init_mode
	RegisterVideoMode
;
    call InitLCD
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET InitDriver
	HookInitTasking
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
	mov si,OFFSET write_serial_val
	mov di,OFFSET write_serial_val_name
	mov ax,write_serial_val_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET read_serial_val
	mov di,OFFSET read_serial_val_name
	mov ax,read_serial_val_nr
	RegisterBimodalUserGate
;
	popa
	pop ds
	ret
init	ENDP

code	ENDS

	END init

