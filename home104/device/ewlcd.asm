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
; EWLCD.ASM
; EW LCD driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME ewlcd

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\driver.def
INCLUDE ..\os\user.def
INCLUDE ..\os\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\user.inc
INCLUDE ..\os\os.inc
INCLUDE ..\os\video.inc

	.386p

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
vl_row		        DW ?
vl_col		        DW ?

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
    mov al,28h
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
    mov al,28h
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
    xor si,si

ylo:
    xor di,di

ilo:
    cmp di,1
    je ilo_ff
;
    cmp di,28
    je ilo_ff
;
    cmp si,1
    jle ilo_norm
;
    cmp si,8
    jg ilo_norm

ilo_ff:
    mov al,0FFh
    WriteData
    jmp ilo_next

ilo_norm:
    cmp di,15
    jne ilo_00
    cmp si, 8 * 8
    jge ilo_00
;
    mov al,55h
    WriteData
    jmp ilo_next

ilo_00:
    xor al,al
    WriteData

ilo_next:
    inc di    
    cmp di,40
    jb ilo

ylo_next:
    inc si
    cmp si,16 * 8
    jb ylo
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
    push edx
;
    call ds:vl_set_proc
;
    mov edx,edi
    shr edx,3
    mov al,dl
    WriteData
    mov al,dh
    WriteData
    mov al,24h
    WriteControl
;
    mov al,0B0h
    WriteControl
;
    add edx,ds:v_app_base
    mov al,es:[edx]
    WriteData
	mov al,-1
	WriteData
;    mov al,0C4h
;    WriteControl
;
    mov al,0B2h
    WriteControl
;
    pop edx
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
    push ecx
    push edx
;
    call ds:vl_slab_proc
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
    WriteData
    mov al,dh
    WriteData
    mov al,24h
    WriteControl
;
    mov al,0B0h
    WriteControl
;
    add edx,ds:v_app_base

slab_loop:
    mov al,es:[edx]
    WriteData
    inc edx
    loop slab_loop
;    
    mov al,0B2h
    WriteControl
;
    pop edx
    pop ecx
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
    call ds:vl_copy_proc
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
    call ds:vl_mask_set_proc
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
    call ds:vl_mask_copy_proc
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
	push cx
	push dx
	push si
	push di
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
	mov es:v_mode,3
	mov es:vl_has_focus,0
	mov es:vl_row,0
	mov es:vl_col,0
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
    call InitLCD
	mov ax,es
	clc
;
	pop di
	pop si
	pop dx
	pop cx
	pop es
	pop ds
	ret
init_mode	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_focus
;
;		DESCRIPTION:	Init focus
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
init_focus	PROC far
    push es
	pusha
;    
;	mov ax,3
;	SetVideoMode
;
	popa
	pop es
	ret
init_focus	Endp

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
	mov bx,pc_video_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_focus
	HookEnableFocus
;
	mov ax,cs
	mov es,ax	
	mov ax,3
	mov bl,1
	mov cx,LCD_WIDTH
    mov dx,LCD_HEIGHT
	mov di,OFFSET init_mode
	RegisterVideoMode
;
	popa
	pop ds
	ret
init	ENDP

code	ENDS

	END init

