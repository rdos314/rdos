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
; FONT.ASM
; Font handling
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME font

GateSize = 16

INCLUDE system.def
INCLUDE system.inc
INCLUDE protseg.def
INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc
INCLUDE driver.def

mask_struc	STRUC

mask_width	DW ?
mask_height	DW ?
mask_data	DB ?

mask_struc	ENDS

font_seg	SEGMENT AT 0

font_id					DW ?
font_point_size			DW ?
font_name				DB 32 DUP(?)
font_minch				DW ?
font_maxch				DW ? 
font_topline			DW ?
font_ascent				DW ?
font_halfline			DW ?
font_descent			DW ?
font_botline			DW ?
font_maxwidth			DW ?
font_cellsize			DW ?
font_leftofs			DW ?
font_right_ofs			DW ?
font_thicken			DW ?
font_ulwidth			DW ?
font_lightmask			DW ?
font_skewmask			DW ?
font_flags				DW ?
font_hotptr				DD ?
font_cotptr				DD ?
font_bufptr				DD ?
font_fwidth				DW ?
font_fheight			DW ?

font_org_data			DB ?

	ORG 0E0h
font_next				DD ?
font_type				DW ?

font_data				DB ?

font_seg	ENDS

font_thread_struc	STRUC

current_font			DW ?

font_thread_struc	ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INSTALL_FONT
;
;		DESCRIPTION:	Install a font
;
;		PARAMETERS:		DS:EDX	font header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	assume ds:font_seg

install_font	PROC near
	push ds
	push ax
	push bx
	push ecx
	push edx
	push si
;
	mov ecx,[edx].len
	sub ecx,SIZE rdos_header
	add edx,SIZE rdos_header
	AllocateGdt
	CreateDataSelector16
;
	mov ds,bx
	mov si,font_fheight
	add si,si
	mov ax,font_data_sel
	mov ds,ax
	mov [si],bx
	mov cx,200h
	sub cx,si
	shr cx,1
	dec cx
	mov dx,si
fill_font_loop:
	add si,2
	mov ax,[si]
	or ax,ax
	jz fill_font_do
	push ds
	mov ds,ax
	mov ax,font_fheight
	add ax,ax
	pop ds
	cmp ax,dx
	ja fill_font_next
fill_font_do:
	mov [si],bx
fill_font_next:
	loop fill_font_loop
	pop si
	pop edx
	pop ecx
	pop bx
	pop ax
	pop ds
	ret
install_font	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			load_adapter_fonts
;
;		DESCRIPTION:	install all fonts in adapter
;
;		PARAMETERS:		edx		base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_adapter_fonts	Proc near
	push ds
	push ax
	push bx
	push edx
	mov ax,flat_sel
	mov ds,ax
load_adapter_fonts_loop:
	mov ax,[edx].typ
	cmp ax,RdosFont
	jne not_install_font
	call install_font
	jmp load_adapter_fonts_next
not_install_font:
	cmp ax,RdosEnd
	je load_adapter_fonts_done
load_adapter_fonts_next:
	add edx,[edx].len
	jmp load_adapter_fonts_loop
load_adapter_fonts_done:
	pop edx
	pop bx
	pop ax
	pop ds
	ret
load_adapter_fonts	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetFont
;
;		DESCRIPTION:	Set graphics mode font
;
;		PARAMETERS:		AX		Font height
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_font_name	DB 'Set Font',0

set_font	Proc far
	push ds
	push ax
	push si
;
	mov si,ax
	add si,si
	mov ax,font_data_sel
	mov ds,ax
set_font_loop:
	mov ax,[si]
	or ax,ax
	jnz set_font_found
	sub si,2
	jc set_font_end
	jmp set_font_loop	

set_font_found:
	mov si,font_thread_sel
	mov ds,si
	mov ds:current_font,ax
set_font_end:
	pop si
	pop ax
	pop ds
	retf32
set_font	Endp
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetCharWidth
;
;		DESCRIPTION:	Get width of char in current font
;
;		PARAMETERS:		AL		char
;
;		RETURNS:		CX		width
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_char_width_name	DB 'Get Char Width',0

get_char_width	Proc far
	push ds
	push ax
	push ebx
;
	mov bx,font_thread_sel
	mov ds,bx
	mov bx,ds:current_font
	or bx,bx
	jz get_char_width_fail
	mov ds,bx
	xor ah,ah
	cmp ax,ds:font_maxch
	ja get_char_width_fail
	sub ax,ds:font_minch
	jb get_char_width_fail
	movzx ebx,al
	add ebx,ebx
	add ebx,ds:font_cotptr
	mov cx,[ebx+2]
	sub cx,[ebx]
	jmp get_char_width_done

get_char_width_fail:
	xor cx,cx
get_char_width_done:
	pop ebx	
	pop ax
	pop ds
	retf32
get_char_width	Endp
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetStringWidth
;
;		DESCRIPTION:	Get width of string in current font
;
;		PARAMETERS:		ES:(E)DI	String 
;
;		RETURNS:		CX			Width
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_string_width_name	DB 'Get String Width',0

get_string_width	Proc near
	push ds
	push ax
	push ebx
	push edi
;
	mov bx,font_thread_sel
	mov ds,bx
	mov bx,ds:current_font
	or bx,bx
	jz get_string_width_fail
	mov ds,bx
	xor cx,cx
get_string_width_loop:
	xor ah,ah
	mov al,es:[edi]
	inc edi
	or al,al
	jz get_string_width_done
	cmp ax,ds:font_maxch
	ja get_string_width_loop
	sub ax,ds:font_minch
	jb get_string_width_loop
	movzx ebx,al
	add ebx,ebx
	add ebx,ds:font_cotptr
	add cx,[ebx+2]
	sub cx,[ebx]
	jmp get_string_width_loop

get_string_width_fail:
	xor cx,cx
get_string_width_done:
	pop edi
	pop ebx
	pop ax
	pop ds
	ret
get_string_width	Endp

get_string_width32	Proc far
	call get_string_width
	retf32
get_string_width32	Endp

get_string_width16	Proc far
	push edi
	movzx edi,di
	call get_string_width
	pop edi
	ret
get_string_width16	Endp	

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetCharMask
;
;		DESCRIPTION:	Get mask for char
;
;		PARAMETERS:		AL		char
;
;		RETURNS:		BX		mask selector
;						CX		width
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_char_mask_name	DB 'Get Char Mask',0

get_char_mask	Proc far
	push ds
	push es
	push eax
	push dx
	push esi
	push di
;
	mov bx,font_thread_sel
	mov ds,bx
	mov bx,ds:current_font
	or bx,bx
	jz get_char_mask_fail
	mov ds,bx
	xor cx,cx
	xor ah,ah
	cmp ax,ds:font_maxch
	ja get_char_mask_alloc
	sub ax,ds:font_minch
	jb get_char_mask_alloc
	movzx ebx,al
	add ebx,ebx
	add ebx,ds:font_cotptr
	mov cx,[ebx+2]
	sub cx,[ebx]
get_char_mask_alloc:
	mov ax,cx
	dec ax
	shr ax,3
	inc ax
	push ax
	mul ds:font_fheight
	push dx
	push ax
	pop eax
	add eax,OFFSET mask_data + 1
	AllocateSmallGlobalMem
	pop ax
	push cx
	mov es:mask_width,ax
	mov cx,ax
	mov dx,ds:font_fheight
	mov es:mask_height,dx
	or cx,cx
	jz get_char_mask_copied
	mov di,OFFSET mask_data	
	xor esi,esi
	mov si,[ebx]
	mov ax,si
	shr si,3
	and al,7
	mov ch,cl
	mov cl,al
	add esi,ds:font_bufptr
get_char_mask_loop:
	push cx
	push esi
get_char_mask_row_loop:
	mov ax,[esi]
	xchg al,ah
	shl ax,cl
	mov es:[di],ah
	inc esi
	inc di
	sub ch,1
	jnz get_char_mask_row_loop	
	pop esi
	pop cx
;
	movzx eax,ds:font_fwidth
	add esi,eax
	sub dx,1
	jnz get_char_mask_loop
get_char_mask_copied:
	pop cx
	mov bx,es
	jmp get_char_mask_done

get_char_mask_fail:
	xor cx,cx
	xor bx,bx
get_char_mask_done:
	pop di
	pop esi
	pop dx
	pop eax
	pop es
	pop ds
	ret
get_char_mask	Endp
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetStringMask
;
;		DESCRIPTION:	Get mask for string
;
;		PARAMETERS:		ES:EDI		string
;
;		RETURNS:		BX			mask selector
;						CX			width
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_string_mask_name	DB 'Get String Mask',0

get_string_mask	Proc far
	push ds
	push es
	push fs
	push eax
	push dx
	push esi
	push edi
	push ebp
;
	mov ebp,edi
	mov bx,es
	mov fs,bx
	mov bx,font_thread_sel
	mov ds,bx
	mov bx,ds:current_font
	or bx,bx
	jz get_string_mask_fail
	mov ds,bx
	xor cx,cx
	xor ah,ah
get_string_mask_size_loop:
	mov al,es:[edi]
	inc edi
	or al,al
	jz get_string_mask_alloc
	cmp ax,ds:font_maxch
	ja get_string_mask_size_loop
	sub ax,ds:font_minch
	jb get_string_mask_size_loop
	movzx ebx,al
	add ebx,ebx
	add ebx,ds:font_cotptr
	add cx,[ebx+2]
	sub cx,[ebx]
	jmp get_string_mask_size_loop
get_string_mask_alloc:
	push cx
	mov ax,cx
	dec ax
	shr ax,3
	inc ax
	push ax
	mul ds:font_fheight
	push dx
	push ax
	pop eax
	add eax,OFFSET mask_data + 1
	AllocateSmallGlobalMem
	xor di,di
	mov cx,ax
	xor al,al
	rep stosb
	pop ax
	mov es:mask_width,ax
	mov cx,ax
	mov dx,ds:font_fheight
	mov es:mask_height,dx
	or cx,cx
	jz get_string_mask_copied
	xor cx,cx
get_string_mask_char_loop:
	xor ah,ah
	mov al,fs:[ebp]
	inc ebp
	or al,al
	jz get_string_mask_copied
	cmp ax,ds:font_maxch
	ja get_string_mask_char_loop
	sub ax,ds:font_minch
	jb get_string_mask_char_loop
	movzx ebx,al
	add ebx,ebx
	add ebx,ds:font_cotptr
;
; cx bit #
;
	mov di,cx
	shr di,3
	add di,OFFSET mask_data
	mov dx,cx
	and dx,7
	add cx,[ebx+2]
	sub cx,[ebx]
	push cx
;
	mov cx,[ebx+2]
	mov ax,[ebx]
	sub cx,ax
	mov dh,cl
	dec cx
	shr cx,3
	mov ch,cl
	inc ch
	movzx esi,ax
	shr si,3
	mov cl,dh
	and cl,7
	neg cl
	add cl,8
	and cl,7
	mov dh,0FFh
	shl dh,cl
	and al,7
	mov cl,al
	add esi,ds:font_bufptr
;
; cl shift count from font
; ch number of bytes in char
; dl shift count to mask
; dh mask of last byte
;
	mov bx,es:mask_height
get_string_mask_loop:
	push cx
	push esi
	push di
get_string_mask_row_loop:
	mov ax,[esi]
	xchg al,ah
	shl ax,cl
	xor al,al
	xchg cl,dl
	cmp ch,1
	jne get_string_mask_shift
	and ah,dh
get_string_mask_shift:
	shr ax,cl
	xchg cl,dl
	or es:[di],ah
	inc di
	or es:[di],al
	inc esi
	sub ch,1
	jnz get_string_mask_row_loop	
	pop di
	pop esi
	pop cx
;
	movzx eax,ds:font_fwidth
	add esi,eax
	add di,es:mask_width
	sub bx,1
	jnz get_string_mask_loop
	pop cx
	jmp get_string_mask_char_loop

get_string_mask_copied:
	pop cx
	mov bx,es
	jmp get_string_mask_done

get_string_mask_fail:
	xor cx,cx
	xor bx,bx
get_string_mask_done:
	pop ebp
	pop edi
	pop esi
	pop dx
	pop eax
	pop fs
	pop es
	pop ds
	ret
get_string_mask	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_THREAD
;
;		DESCRIPTION:	Init per thread font info
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread	PROC far
	mov ax,font_thread_sel
	mov ds,ax
	mov ds:current_font,0
	ret
init_thread	ENDP

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
	mov bx,font_code_sel
	InitDevice
	mov bx,font_data_sel
	mov eax,512
	AllocateFixedSystemMem
	mov ds,bx
	xor bx,bx
	mov cx,256
	xor ax,ax
init_system_font_loop:
	mov [bx],ax
	add bx,2
	loop init_system_font_loop
;
	mov ax,system_data_sel
	mov ds,ax
	mov cx,ds:rom_modules
	mov bx,OFFSET rom_adapters
init_font_loop:
	mov edx,[bx].adapter_base
	call load_adapter_fonts
	add bx,SIZE adapter_typ
	loop init_font_loop	
;
	mov eax,SIZE font_thread_struc
	mov bx,font_thread_sel
	AllocateFixedThreadMem
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET init_thread
	HookCreateThread
;
	mov si,OFFSET get_char_mask
	mov di,OFFSET get_char_mask_name
	xor cl,cl
	mov ax,get_char_mask_nr
	RegisterOsGate
;
	mov si,OFFSET get_string_mask
	mov di,OFFSET get_string_mask_name
	xor cl,cl
	mov ax,get_string_mask_nr
	RegisterOsGate
;
	mov si,OFFSET set_font
	mov di,OFFSET set_font_name
	xor cl,cl
	mov ax,set_font_nr
	RegisterUserGate
	mov bx,ax
	mov dx,0
	mov ax,set_virt_font_nr
	RegisterVirtUserGate
;
	mov si,OFFSET get_char_width
	mov di,OFFSET get_char_width_name
	xor cl,cl
	mov ax,get_char_width_nr
	RegisterUserGate
	mov bx,ax
	mov dx,0
	mov ax,get_virt_char_width_nr
	RegisterVirtUserGate
;
	mov si,OFFSET get_string_width32
	mov di,OFFSET get_string_width_name
	xor cl,cl
	mov ax,get_string_width_nr
	RegisterUserGate32
	mov si,OFFSET get_string_width16
	mov di,OFFSET get_string_width_name
	xor cl,cl
	mov ax,get_string_width_nr
	RegisterUserGate16
	mov bx,ax
	mov dx,virt_es_in
	mov ax,get_virt_string_width_nr
	RegisterVirtUserGate
;
	popa
	pop ds
	ret
init	ENDP
	
code	ENDS

	END init

