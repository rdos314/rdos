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
; VIDEO.ASM
; Standard video interface. Hardware independent
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME video

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\driver.def
INCLUDE ..\os\user.def
INCLUDE ..\os\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\user.inc
INCLUDE ..\os\os.inc
INCLUDE handle.inc
INCLUDE bitmap.inc
INCLUDE video.inc

video_mode_entry	STRUC

mode_link		DW ?
mode_nr			DW ?
mode_create		DD ?

video_mode_entry	ENDS

video_data_seg	STRUC

v_list			DW ?

video_data_seg	ENDS

video_focus_seg	STRUC

v_handle		DW ?

video_focus_seg	ENDS

video_thread_seg	STRUC

vt_forecolor	DB ?
vt_backcolor	DB ?
vt_row			DW ?
vt_col			DW ?

video_thread_seg	ENDS

CallVideo	MACRO	call_proc
	push ds
	push ax
	mov ax,video_local_sel
	mov ds,ax
	pop ax
	mov ds,ds:v_handle
	call ds:&call_proc
	pop ds
				ENDM

CallBitmap	MACRO	call_proc
	local bmp
	local done
	local fail

	or bx,bx
	jnz bmp
;
	push ds
	push ax
	mov ax,video_local_sel
	mov ds,ax
	pop ax
	mov ds,ds:v_handle
	call ds:&call_proc
	pop ds
	jmp done

fail:
	pop bx
	pop ax
	pop ds
	jmp done

bmp:
	push ds
	push ax
	push bx
;
	mov ax,BITMAP_HANDLE
	DerefHandle
	jc fail
;
	mov ds,[bx].bm_sel
	pop bx
	pop ax
	call ds:&call_proc
	pop ds	

done:
				ENDM

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn init_bitmap:near

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RegisterVideoMode
;
;		DESCRIPTION:	Register a video mode
;
;		PARAMETERS:		AX		Mode
;						ES:DI	Mode constructor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_video_mode_name	DB 'Register Video Mode',0

register_video_mode	PROC far
	push ds
	push es
	push bx
;
	mov bx,es
	push eax
	mov ax,video_data_sel
	mov ds,ax
	mov eax,SIZE video_mode_entry
	AllocateSmallGlobalMem
	pop eax
	mov es:mode_nr,ax
	mov word ptr es:mode_create,di
	mov word ptr es:mode_create+2,bx
;
	mov bx,ds:v_list
	mov es:mode_link,bx
	mov ds:v_list,es
;
	pop bx
	pop es
	pop ds
	ret
register_video_mode	ENDP

page
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetVideoMode
;
;		DESCRIPTION:	Set video mode
;
;		PARAMETERS:		AX		Mode
;
;		RETURNS:		AX		bits / pixel
;						BX		bitmap handle
;						CX		x-resolution
;						DX		y-resolution
;						SI		line size
;						ES:EDI	user buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_video_mode_name	DB 'Set Video Mode',0

set_video_mode	PROC far
	push ds
;
	mov bx,video_data_sel
	mov ds,bx
	mov bx,ds:v_list

set_video_mode_loop:
	or bx,bx
	stc
	jz set_video_mode_done
;
	mov es,bx
	cmp ax,es:mode_nr
	jnz set_video_mode_next
;
	call es:mode_create
	jc set_video_mode_done
;
	mov bx,video_local_sel
	mov ds,bx
	mov bx,ds:v_handle
	or bx,bx
	jz set_mode_no_descruct
;
	push ds
	mov ds,bx
	call ds:destruct_proc
	pop ds

set_mode_no_descruct:
	mov ds:v_handle,ax
	GetFocusThread
	or ax,ax
	jz set_video_mode_ok
;
	push es
	push edx
	mov es,ax
	mov edx,es:p_cr3
	GetThread
	mov es,ax
	cmp edx,es:p_cr3
	pop edx
	pop es
	jne set_video_mode_ok
;
	push ds
	mov ds,ds:v_handle
	call ds:switch_to_proc
	pop ds
	jmp set_video_mode_ok

set_video_mode_next:
	mov bx,es:mode_link
	jmp set_video_mode_loop

set_video_mode_ok:
	mov ds,ds:v_handle
	mov bx,ds:v_bitmap
	mov cx,ds:v_width
	mov dx,ds:v_height
	mov si,ds:v_row_size
	mov edi,ds:v_app_base
	sub edi,local_page_linear
	mov ax,flat_data_sel
	mov es,ax
	movzx ax,ds:v_bpp

set_video_mode_done:
	pop ds
	retf32
set_video_mode	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetCursorPosition
;
;		DESCRIPTION:	Set cursor position
;
;		PARAMETERS:		CX		COL (x)
;						DX		ROW (y)
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cursor_pos_name	DB 'Set Cursor Position',0

set_cursor_position	PROC far
	CallVideo set_cursor_position_proc
	push ds
	push ax
	mov ax,video_thread_sel
	mov ds,ax
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	pop ax
	pop ds
	retf32
set_cursor_position	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetCursorPosition
;
;		DESCRIPTION:	Get cursor position
;
;		RETURNS:		CX		COL (x)
;						DX		Row (y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cursor_pos_name	DB 'Get Cursor Position',0

get_cursor_position	PROC far
	push ds
;
	mov cx,video_thread_sel
	mov ds,cx
	mov dx,ds:vt_row
	mov cx,ds:vt_col
;
	pop ds
	retf32
get_cursor_position	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetForeColor
;
;		DESCRIPTION:	Set text mode fore color
;
;		PARAMETERS:		AL		Color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_forecolor_name	DB 'Set Fore Color',0

set_forecolor	PROC far
	push ds
	push bx
;
	mov bx,video_thread_sel
	mov ds,bx
	mov ds:vt_forecolor,al
;
	pop bx
	pop ds
	retf32
set_forecolor	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetBackColor
;
;		DESCRIPTION:	Set text mode back color
;
;		PARAMETERS:		AL		Color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_backcolor_name	DB 'Set Back Color',0

set_backcolor	PROC far
	push ds
	push bx
;
	mov bx,video_thread_sel
	mov ds,bx
	mov ds:vt_backcolor,al
;
	pop bx
	pop ds
	retf32
set_backcolor	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UpdatePos
;
;		DESCRIPTION:	Update cursor position
;
;		PARAMETERS:		AL		Char
;						BL		Fore color
;						BH		Back color
;						CX		Column
;						DX		Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePos	Proc near
	cmp cx,-1
	jne update_not_row_wrap
;
	mov cx,79

update_not_row_wrap:
	cmp cx,79
	jbe update_video_same_row
;
	xor cx,cx
	inc dx

update_video_same_row:
	cmp dx,25
	jc update_video_end
;
	dec dx
;
	pusha
	mov ax,1
	xor cx,cx
	xor dx,dx
	mov si,79
	mov di,24
	CallVideo scroll_up_proc
	popa

update_video_end:
	ret
UpdatePos	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteNormal
;
;		DESCRIPTION:	Write normal char
;
;		PARAMETERS:		AL		Char
;						BL		Fore color
;						BH		Back color
;						CX		Column
;						DX		Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteNormal	PROC near
	CallVideo write_char_proc
	inc cx
	ret
WriteNormal	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteSkip
;
;		DESCRIPTION:	Write NUL char
;
;		PARAMETERS:		AL		Char
;						BL		Fore color
;						BH		Back color
;						CX		Column
;						DX		Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSkip	PROC near
	push ax
	mov al,' '
	CallVideo write_char_proc
	inc cx
	pop ax
	ret
WriteSkip	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteTab
;
;		DESCRIPTION:	Write TAB char
;
;		PARAMETERS:		AL		Char
;						BL		Fore color
;						BH		Back color
;						CX		Column
;						DX		Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteTab	PROC near
	push ax
	mov al,' '

write_tab_more:
	CallVideo write_char_proc
	inc cx
	test cx,3
	jnz write_tab_more
;
	pop ax
	ret
WriteTab	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteDel
;
;		DESCRIPTION:	Write DEL char
;
;		PARAMETERS:		AL		Char
;						BL		Fore color
;						BH		Back color
;						CX		Column
;						DX		Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDel	PROC near
	dec cx
	ret
WriteDel	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteLf
;
;		DESCRIPTION:	Write LF char
;
;		PARAMETERS:		AL		Char
;						BL		Fore color
;						BH		Back color
;						CX		Column
;						DX		Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteLf	PROC near
	inc dx
	ret
WriteLf	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteCr
;
;		DESCRIPTION:	Write CR char
;
;		PARAMETERS:		AL		Char
;						BL		Fore color
;						BH		Back color
;						CX		Column
;						DX		Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCr	PROC near
	xor cx,cx
	ret
WriteCr	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteOne
;
;		DESCRIPTION:	Write one character to screen
;
;		PARAMETERS:		AL		Char
;						BL		Fore color
;						BH		Back color
;						CX		Column
;						DX		Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_tab:
wct00	DW OFFSET WriteSkip
wct01	DW OFFSET WriteNormal
wct02	DW OFFSET WriteNormal
wct03	DW OFFSET WriteNormal
wct04	DW OFFSET WriteNormal
wct05	DW OFFSET WriteNormal
wct06	DW OFFSET WriteNormal
wct07	DW OFFSET WriteNormal
wct08	DW OFFSET WriteDel
wct09	DW OFFSET WriteTab
wct0A	DW OFFSET WriteLf
wct0B	DW OFFSET WriteNormal
wct0C	DW OFFSET WriteNormal
wct0D	DW OFFSET WriteCr
wct0E	DW OFFSET WriteNormal
wct0F	DW OFFSET WriteNormal

WriteOne	PROC near
	push si
	movzx si,al
	cmp si,0Fh
	jc write_char_doit
;
	mov si,0Fh

write_char_doit:
	add si,si
	call word ptr cs:[si].write_tab
	call UpdatePos

write_ansi_done:
	pop si
	ret
WriteOne	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteChar
;
;		DESCRIPTION:	Write one character to screen
;
;		PARAMETERS:		AL		Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_char_name	DB 'Write Char',0

write_char	PROC far
	cmp al,8
	jnz wnd
	int 3
wnd:

	push ds
	push bx
	push cx
	push dx
;
	mov bx,video_thread_sel
	mov ds,bx
	mov bl,ds:vt_forecolor
	mov bh,ds:vt_backcolor
	mov dx,ds:vt_row
	mov cx,ds:vt_col
	call WriteOne
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	CallVideo set_cursor_position_proc
;
	pop dx
	pop cx
	pop bx
	pop ds
	retf32
write_char	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteAsciiz
;
;		DESCRIPTION:	Write NULL terminated string
;
;		PARAMETERS:		ES:(E)DI	Null terminated string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_asciiz_name	DB 'Write Asciiz String',0

write_asciiz16	PROC far
	push ds
	push ax
	push bx
	push cx
	push dx
	push di
;
	mov bx,video_thread_sel
	mov ds,bx
	mov bl,ds:vt_forecolor
	mov bh,ds:vt_backcolor
	mov dx,ds:vt_row
	mov cx,ds:vt_col

write_asciiz_loop16:
	mov al,es:[di]
	inc di
	or al,al
	jz write_asciiz_done16
;
	call WriteOne
	jmp write_asciiz_loop16

write_asciiz_done16:
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	CallVideo set_cursor_position_proc
;
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop ds
	ret
write_asciiz16	ENDP

write_asciiz32	PROC far
	push ds
	push ax
	push bx
	push cx
	push dx
	push edi
;
	mov bx,video_thread_sel
	mov ds,bx
	mov bl,ds:vt_forecolor
	mov bh,ds:vt_backcolor
	mov dx,ds:vt_row
	mov cx,ds:vt_col

write_asciiz_loop32:
	mov al,es:[edi]
	inc edi
	or al,al
	jz write_asciiz_done32
;
	call WriteOne
	jmp write_asciiz_loop32

write_asciiz_done32:
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	CallVideo set_cursor_position_proc
;
	pop edi
	pop dx
	pop cx
	pop bx
	pop ax
	pop ds
	retf32
write_asciiz32	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteDosString
;
;		DESCRIPTION:	Write '$'-terminated string
;
;		PARAMETERS:		ES:EDI	Adress to string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_dos_string_name	DB 'Write Dos String',0

write_dos_string	PROC far
	push ds
	push ax
	push bx
	push cx
	push dx
	push edi
;
	mov bx,video_thread_sel
	mov ds,bx
	mov bl,ds:vt_forecolor
	mov bh,ds:vt_backcolor
	mov dx,ds:vt_row
	mov cx,ds:vt_col

write_dos_string_loop:
	mov al,es:[edi]
	inc edi
	cmp al,'$'
	jz write_dos_string_done
;
	call WriteOne
	jmp write_dos_string_loop

write_dos_string_done:
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	CallVideo set_cursor_position_proc
;
	pop edi
	pop dx
	pop cx
	pop bx
	pop ax
	pop ds
	ret
write_dos_string	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteSizeString
;
;		DESCRIPTION:	Write a number of characters
;
;		PARAMETERS:		ES:(E)DI	String
;						(E)CX		Number of characters			
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_size_string_name	DB 'Write Size String',0

write_size_string16	PROC far
	push ds
	pusha
;
	mov si,cx
	mov bx,video_thread_sel
	mov ds,bx
	mov bl,ds:vt_forecolor
	mov bh,ds:vt_backcolor
	mov dx,ds:vt_row
	mov cx,ds:vt_col
;
	or si,si
	je write_size_string_done16

write_size_string_loop16:
	mov al,es:[di]
	inc di
	call WriteOne
	sub si,1
	jnz write_size_string_loop16

write_size_string_done16:
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	CallVideo set_cursor_position_proc
;
	popa
	pop ds
	ret
write_size_string16	ENDP

write_size_string32	PROC far
	push ds
	pushad
;
	mov esi,ecx
	mov bx,video_thread_sel
	mov ds,bx
	mov bl,ds:vt_forecolor
	mov bh,ds:vt_backcolor
	mov dx,ds:vt_row
	mov cx,ds:vt_col
;
	or esi,esi
	je write_size_string_done32

write_size_string_loop32:
	mov al,es:[edi]
	inc edi
	call WriteOne
	sub esi,1
	jnz write_size_string_loop32

write_size_string_done32:
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	CallVideo set_cursor_position_proc
;
	popad
	pop ds
	retf32
write_size_string32	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetDrawColor
;
;		DESCRIPTION:	Set draw color
;
;		PARAMETERS:		EAX			RGB color
;						BX			Bitmap handle or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_draw_color_name	DB 'Set Draw Color',0

set_draw_color	PROC far
	CallBitmap set_color_proc
	retf32
set_draw_color	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetLgop
;
;		DESCRIPTION:	Set LGOP
;
;		PARAMETERS:		AX			LGOP
;						BX			Bitmap handle or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_lgop_name	DB 'Set LGOP',0

set_lgop	PROC far
	cmp ax,13
	jbe set_lgop_ok
	mov ax,1

set_lgop_ok:
	or bx,bx
	jnz set_lgop_bmp
;
	push ds
	push ax
	mov ax,video_local_sel
	mov ds,ax
	pop ax
	mov ds,ds:v_handle
	mov ds:v_lgop,ax
	pop ds
	jmp set_lgop_done

set_lgop_fail:
	pop bx
	pop ax
	pop ds
	jmp set_lgop_done

set_lgop_bmp:
	push ds
	push ax
	push bx
;
	mov ax,BITMAP_HANDLE
	DerefHandle
	jc set_lgop_fail
;
	mov ds,[bx].bm_sel
	pop bx
	pop ax
	mov ds:v_lgop,ax
	pop ds	

set_lgop_done:
	retf32
set_lgop	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetHollowStyle
;
;		DESCRIPTION:	Set hollow style
;
;		PARAMETERS:		BX			Bitmap handle or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_hollow_style_name	DB 'Set Hollow Style',0

set_hollow_style	PROC far
	or bx,bx
	jnz set_hollow_bmp
;
	push ds
	push ax
	mov ax,video_local_sel
	mov ds,ax
	pop ax
	mov ds,ds:v_handle
	mov ds:v_style,STYLE_HOLLOW
	pop ds
	jmp set_hollow_done

set_hollow_fail:
	pop bx
	pop ax
	pop ds
	jmp set_hollow_done

set_hollow_bmp:
	push ds
	push ax
	push bx
;
	mov ax,BITMAP_HANDLE
	DerefHandle
	jc set_hollow_fail
;
	mov ds,[bx].bm_sel
	pop bx
	pop ax
	mov ds:v_style,STYLE_HOLLOW
	pop ds	

set_hollow_done:
	retf32
set_hollow_style	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetFilledStyle
;
;		DESCRIPTION:	Set filled style
;
;		PARAMETERS:		BX			Bitmap handle or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_filled_style_name	DB 'Set Filled Style',0

set_filled_style	PROC far
	or bx,bx
	jnz set_filled_bmp
;
	push ds
	push ax
	mov ax,video_local_sel
	mov ds,ax
	pop ax
	mov ds,ds:v_handle
	mov ds:v_style,STYLE_FILLED
	pop ds
	jmp set_filled_done

set_filled_fail:
	pop bx
	pop ax
	pop ds
	jmp set_filled_done

set_filled_bmp:
	push ds
	push ax
	push bx
;
	mov ax,BITMAP_HANDLE
	DerefHandle
	jc set_filled_fail
;
	mov ds,[bx].bm_sel
	pop bx
	pop ax
	mov ds:v_style,STYLE_FILLED
	pop ds	

set_filled_done:
	retf32
set_filled_style	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetFont
;
;		DESCRIPTION:	Set font
;
;		PARAMETERS:		BX			Bitmap handle or 0
;						AX			Font
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_font_name	DB 'Set Font',0

set_font	PROC far
	or bx,bx
	jnz set_font_bmp
;
	push ds
	push ax
	mov ax,video_local_sel
	mov ds,ax
	pop ax
	mov ds,ds:v_handle
	mov ds:v_font,ax
	pop ds
	jmp set_font_done

set_font_fail:
	pop bx
	pop ax
	pop ds
	jmp set_font_done

set_font_bmp:
	push ds
	push ax
	push bx
;
	mov ax,BITMAP_HANDLE
	DerefHandle
	jc set_font_fail
;
	mov ds,[bx].bm_sel
	pop bx
	pop ax
	mov ds:v_font,ax
	pop ds	

set_font_done:
	retf32
set_font	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetPixel
;
;		DESCRIPTION:	Get pixel
;
;		PARAMETERS:		BX		Bitmap handle or 0
;						CX		x
;						DX		y
;
;		RETURNS:		EAX		RGB color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pixel_name	DB 'Get Pixel',0

get_pixel	PROC far
	CallBitmap get_pixel_proc
	retf32
get_pixel	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetPixel
;
;		DESCRIPTION:	Set pixel
;
;		PARAMETERS:		BX		Bitmap handle or 0
;						CX		x
;						DX		y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_pixel_name	DB 'Set Pixel',0

set_pixel	PROC far
	CallBitmap set_pixel_proc
	retf32
set_pixel	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Blit
;
;		DESCRIPTION:	Blit
;
;		PARAMETERS:		AX		Source bitmap handle or 0
;						BX		Dest bitmap handle or 0
;						CX		Width
;						DX		Height
;						ESI		Source x + y << 16
;						EDI		Dest x + y << 16
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

blit_name	DB 'Blit',0

blit_src_y		EQU -2
blit_src_x		EQU -4
blit_dest_y		EQU -6
blit_dest_x		EQU -8
blit_width		EQU -10
blit_height		EQU -12
blit_src_sel	EQU -14
blit_dest_sel	EQU -16

blit_pr	PROC far
	push bp
	mov bp,sp
	sub sp,16
	push ds
	push es
	pushad
;
	mov [bp].blit_src_x,esi
	mov [bp].blit_dest_x,edi
;
	or cx,cx
	jz blit_done
;
	or dx,dx
	jz blit_done
;
	mov [bp].blit_width,cx
	mov [bp].blit_height,dx
;
	or bx,bx
	jnz blit_dest_bmp
	mov dx,video_local_sel
	mov ds,dx
	mov dx,ds:v_handle
	mov [bp].blit_dest_sel,dx
	jmp blit_get_src

blit_dest_bmp:
	push ax
	mov ax,BITMAP_HANDLE
	DerefHandle
	pop ax
	jc blit_failed
;
	mov dx,[bx].bm_sel
	mov [bp].blit_dest_sel,dx

blit_get_src:
	mov bx,ax
	or bx,bx
	jnz blit_src_bmp
;
	mov dx,video_local_sel
	mov ds,dx
	mov dx,ds:v_handle
	mov [bp].blit_src_sel,dx
	jmp blit_do

blit_src_bmp:
	mov ax,BITMAP_HANDLE
	DerefHandle
	jc blit_failed
;
	mov dx,[bx].bm_sel
	mov [bp].blit_src_sel,dx

blit_do:
	mov ax,[bp].blit_src_sel
	cmp ax,[bp].blit_dest_sel
	je blit_same_bitmap
;
	mov ds,[bp].blit_dest_sel
	mov al,ds:v_bpp
	mov ds,[bp].blit_src_sel
	cmp al,ds:v_bpp
	je blit_same_bpp
;
	movzx eax,word ptr [bp].blit_width
	shl eax,2
	AllocateSmallGlobalMem

blit_diff_loop:
	mov ds,[bp].blit_src_sel
	mov ax,[bp].blit_width
	mov cx,[bp].blit_src_x
	mov dx,[bp].blit_src_y
	xor edi,edi
	call ds:get_rgb_row_proc
;
	mov ds,[bp].blit_dest_sel
	mov ax,[bp].blit_width
	mov cx,[bp].blit_dest_x
	mov dx,[bp].blit_dest_y
	xor edi,edi
	call ds:set_rgb_row_proc
;
	inc word ptr [bp].blit_src_y
	inc word ptr [bp].blit_dest_y
	sub word ptr [bp].blit_height,1
	jnz blit_diff_loop
;
	FreeMem	
	clc
	jmp blit_done

blit_same_bpp:
	mov ds,[bp].blit_src_sel
	mov cx,[bp].blit_src_x
	mov dx,[bp].blit_src_y
	call ds:get_line_proc
;
	mov ds,[bp].blit_dest_sel
	mov ax,[bp].blit_width
	mov cx,[bp].blit_dest_x
	mov dx,[bp].blit_dest_y
	call ds:set_native_row_proc
;
	inc word ptr [bp].blit_src_y
	inc word ptr [bp].blit_dest_y
	sub word ptr [bp].blit_height,1
	jnz blit_same_bpp
;
	clc
	jmp blit_done

blit_same_bitmap:
	mov ds,[bp].blit_src_sel
	mov dx,[bp].blit_src_y
	cmp dx,[bp].blit_dest_y
	je blit_same_line
	ja blit_forward

blit_reverse:
	mov ax,[bp].blit_height
	dec ax
	add [bp].blit_src_y,ax
	add [bp].blit_dest_y,ax

blit_reverse_loop:
	mov cx,[bp].blit_src_x
	mov dx,[bp].blit_src_y
	call ds:get_line_proc
;
	mov ax,[bp].blit_width
	mov cx,[bp].blit_dest_x
	mov dx,[bp].blit_dest_y
	call ds:set_native_row_proc
;
	dec word ptr [bp].blit_src_y
	dec word ptr [bp].blit_dest_y
	sub word ptr [bp].blit_height,1
	jnz blit_reverse_loop
	clc
	jmp blit_done

blit_forward:
	mov cx,[bp].blit_src_x
	mov dx,[bp].blit_src_y
	call ds:get_line_proc
;
	mov ax,[bp].blit_width
	mov cx,[bp].blit_dest_x
	mov dx,[bp].blit_dest_y
	call ds:set_native_row_proc
;
	inc word ptr [bp].blit_src_y
	inc word ptr [bp].blit_dest_y
	sub word ptr [bp].blit_height,1
	jnz blit_forward
;
	clc
	jmp blit_done

blit_same_line:
	movzx eax,word ptr [bp].blit_width
	shl eax,2
	AllocateSmallGlobalMem

blit_same_line_loop:
	mov ax,[bp].blit_width
	mov cx,[bp].blit_src_x
	mov dx,[bp].blit_src_y
	xor edi,edi
	call ds:get_native_row_proc
;
	mov ax,[bp].blit_width
	mov cx,[bp].blit_dest_x
	mov dx,[bp].blit_dest_y
	xor edi,edi
	call ds:set_native_row_proc
;
	inc word ptr [bp].blit_src_y
	inc word ptr [bp].blit_dest_y
	sub word ptr [bp].blit_height,1
	jnz blit_same_line_loop
;
	FreeMem
	clc
	jmp blit_done

blit_failed:
	stc

blit_done:
	popad
	pop es
	pop ds
	add sp,16
	pop bp
	retf32
blit_pr	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DrawMask
;
;		DESCRIPTION:	Draw a mask line
;
;		PARAMETERS:		AX		row size
;						BX		Bitmap handle or 0
;						ECX		source x + y << 16
;						EDX		dest x + y << 16
;						ESI		width + height << 16
;						ES:EDI	1-bit mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_mask_name	DB 'Draw Mask',0

draw_mask	PROC far
	push ecx
	push edx
	push esi
	push edi
;
	movzx eax,ax

draw_mask_loop:
	ror esi,16
	or si,si
	jz draw_mask_done
;
	ror esi,16
	CallBitmap draw_mask_line_proc
	add ecx,10000h
	add edx,10000h
	sub esi,10000h
	jmp draw_mask_loop

draw_mask_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	retf32
draw_mask	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DrawString
;
;		DESCRIPTION:	Draw a string
;
;		PARAMETERS:		BX		Bitmap handle or 0
;						CX		x
;						DX		y
;						ES:EDI	string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_string_name	DB 'Draw String',0

draw_string16	PROC far
	push edi
	movzx edi,di
	CallBitmap draw_string_proc
	pop edi
	ret
draw_string16	ENDP

draw_string32	PROC far
	CallBitmap draw_string_proc
	retf32
draw_string32	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DrawLine
;
;		DESCRIPTION:	Draw a line
;
;		PARAMETERS:		BX		Bitmap handle or 0
;						CX		x1
;						DX		y1
;						SI		x2
;						DI		y2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_line_name	DB 'Draw Line',0

draw_line	PROC far
	CallBitmap draw_line_proc
	retf32
draw_line	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DrawRect
;
;		DESCRIPTION:	Draw a rectangle
;
;		PARAMETERS:		BX		Bitmap handle or 0
;						CX		x
;						DX		y
;						SI		w
;						DI		b
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_rect_name	DB 'Draw Rect',0

draw_rect	PROC far
	CallBitmap draw_rect_proc
	retf32
draw_rect	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DrawEllipse
;
;		DESCRIPTION:	Draw a ellipse
;
;		PARAMETERS:		BX		Bitmap handle or 0
;						CX		x
;						DX		y
;						SI		w
;						DI		b
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_ellipse_name	DB 'Draw Ellipse',0

draw_ellipse	PROC far
	CallBitmap draw_ellipse_proc
	retf32
draw_ellipse	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetCursorPosition
;
;		DESCRIPTION:	Set cursor position
;
;		PARAMETERS:		DH		ROW
;						DL		COL
;						BH		PAGE NUMBER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cursor_pos	PROC far
	push cx
	push dx
	movzx cx,dl
	movzx dx,dh
	CallVideo set_cursor_position_proc
	push ds
	push ax
	mov ax,video_thread_sel
	mov ds,ax
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	pop ax
	pop ds
	pop dx
	pop cx
	ret
set_cursor_pos	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadCursorPosition
;
;		DESCRIPTION:	Read cursor position
;
;		PARAMETERS:		DH		ROW
;						DL		COL
;						BH		PAGE NUMBER
;						CH		START LINE
;						CL		END LINE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_cursor_pos	PROC far
	mov dx,video_thread_sel
	mov ds,dx
	mov dh,byte ptr ds:vt_row
	mov dl,byte ptr ds:vt_col
	xor bh,bh
	mov cl,1
	mov ch,8
	ret
read_cursor_pos	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadLightPen
;
;		DESCRIPTION:	Read light pen
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_light_pen	PROC far
	xor ah,ah
	ret
read_light_pen	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			READ_VIDEO_ATTRIB
;
;		DESCRIPTION:	Read video attribute
;
;		PARAMETERS:		BH		PAGE NUMBER
;						AL		ASCCI CODE
;						AH		ATTRIBUTE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_video_attrib	PROC far
	push bx
	push cx
	push dx
	mov ax,video_thread_sel
	mov ds,ax
	mov dx,ds:vt_row
	mov cx,ds:vt_col
	CallVideo read_char_proc
	mov ah,bh
	shl ah,4
	or ah,bl
	pop dx
	pop cx
	pop bx
	ret
read_video_attrib	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_CH_ATTR
;
;		DESCRIPTION:	Write char + attribute
;
;		PARAMETERS:		BH		PAGE NUMBER
;						AL		ASCCI CODE
;						BL		ATTRIBUTE
;						CX		NUMBER OF COPIES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_ch_attr	PROC far
	push ds
	pusha
;
	mov si,cx
	mov dx,video_thread_sel
	mov ds,dx
	mov dx,ds:vt_row
	mov cx,ds:vt_col
	mov bx,[bp].vm_ebx
	mov bh,bl
	shr bh,4
	and bl,0Fh
;
	or si,si
	jz write_ch_attr_done

write_ch_attr_loop:
	CallVideo write_char_proc
	inc cx
	call UpdatePos
	sub si,1
	jnz write_ch_attr_loop

write_ch_attr_done:
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	CallVideo set_cursor_position_proc
;
	popa
	pop ds
	ret
write_ch_attr	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_CH
;
;		DESCRIPTION:	Write char
;
;		PARAMETERS:		BH		PAGE NUMBER
;						AL		ASCCI CODE
;						CX		NUMBER OF COPIES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_ch	PROC far
	push ds
	pusha
;
	mov si,cx
	mov dx,video_thread_sel
	mov ds,dx
	mov bl,ds:vt_forecolor
	mov bh,ds:vt_backcolor
	mov dx,ds:vt_row
	mov cx,ds:vt_col
	or si,si
	jz write_ch_done

write_ch_loop:
	CallVideo write_char_proc
	inc cx
	call UpdatePos
	sub si,1
	jnz write_ch_loop

write_ch_done:
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	CallVideo set_cursor_position_proc
;
	popa
	pop ds
	ret
write_ch	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SCROLL_VIDEO_UP
;
;		DESCRIPTION:	Scroll screen up
;
;		PARAMETERS:		BH		PAGE NUMBER
;						AL		Number of lines
;						BH		Attribute for new lines
;						CH		Upper row
;						CL		Left columnn
;						DH		Bottom row
;						DL		Right column
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

scroll_video_up	PROC far
	pusha
;
	movzx si,dl
	movzx di,dh
	movzx dx,ch
	movzx cx,cl
	mov bh,[bp].vm_ebx+1
	mov bl,bh
	and bl,0Fh
	shr bh,4
;
	or al,al
	jnz scroll_video_up_do
;
	CallVideo clear_proc
	jmp scroll_video_up_done

scroll_video_up_do:
	movzx ax,al
	CallVideo scroll_up_proc

scroll_video_up_done:
	popa		
	ret
scroll_video_up	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SCROLL_VIDEO_DOWN
;
;		DESCRIPTION:	Scroll screen down
;
;		PARAMETERS:		BH		PAGE NUMBER
;						AL		Number of lines
;						BH		Attribute for new lines
;						CH		Upper row
;						CL		Left columnn
;						DH		Bottom row
;						DL		Right column
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

scroll_video_down	PROC far
	pusha
;
	movzx si,dl
	movzx di,dh
	movzx dx,ch
	movzx cx,cl
	mov bh,[bp].vm_ebx+1
	mov bl,bh
	and bl,0Fh
	shr bh,4
;
	or al,al
	jnz scroll_video_down_do
;
	CallVideo clear_proc
	jmp scroll_video_down_done

scroll_video_down_do:
	movzx ax,al
	CallVideo scroll_down_proc

scroll_video_down_done:
	popa		
	ret
scroll_video_down	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_STG_ONE
;
;		DESCRIPTION:	Write string
;
;		PARAMETERS:		AX		Attribute + char
;						CX		Column
;						DX		Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_stg_one	PROC near
	push bx
	mov bl,ah
	mov bh,ah
	and bl,0Fh
	shr bh,4
;
	cmp al,0Dh
	jne write_stg_not_cr
;
	xor cx,cx
	jmp write_stg_one_done

write_stg_not_cr:
	cmp al,0Ah
	jne write_stg_not_lf
;
	inc dx
	jmp write_stg_one_done

write_stg_not_lf:
	cmp al,8
	jne write_stg_not_del
;
	dec cx
	jmp write_stg_one_done

write_stg_not_del:
	CallVideo write_char_proc
	inc cx

write_stg_one_done:
	call UpdatePos
	pop bx
	ret
write_stg_one	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_STG
;
;		DESCRIPTION:	Write string (BIOS)
;
;		PARAMETERS:		FS:EBX	String
;						CX		Column
;						DX		Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_char_no_move	PROC near
write_char_nm_loop:
	or si,si
	jz write_ch_no_m_end
;
	dec si
	mov al,fs:[ebx]
	inc ebx
	mov ah,[bp].vm_ebx
	call write_stg_one
	jmp write_char_nm_loop

write_ch_no_m_end:
	ret
write_char_no_move	ENDP

write_char_move	PROC near
write_char_m_loop:
	or si,si
	jz write_ch_m_end
;
	dec si
	mov al,fs:[ebx]
	inc ebx
	mov ah,[bp].vm_ebx
	call write_stg_one
	jmp write_char_m_loop

write_ch_m_end:
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	CallVideo set_cursor_position_proc
	ret
write_char_move	ENDP

write_attr_no_move	PROC near
write_attr_nm_loop:
	or si,si
	jz write_attr_no_m_end
;
	dec si
	or si,si
	jz write_attr_no_m_end
;
	dec si
	mov ax,fs:[ebx]
	add ebx,2
	call write_stg_one
	jmp write_attr_nm_loop

write_attr_no_m_end:
	ret
write_attr_no_move	ENDP

write_attr_move	PROC near
write_attr_m_loop:
	or si,si
	jz write_attr_m_end
;
	dec si
	or si,si
	jz write_attr_m_end
;
	dec si
	mov ax,fs:[ebx]
	add ebx,2
	call write_stg_one
	jmp write_attr_m_loop

write_attr_m_end:
	mov ds:vt_row,dx
	mov ds:vt_col,cx
	CallVideo set_cursor_position_proc
	ret
write_attr_move	ENDP

write_stg_tab:
ws0	DW OFFSET write_char_no_move
ws1	DW OFFSET write_char_move
ws2 DW OFFSET write_attr_no_move
ws3 DW OFFSET write_attr_move

write_stg	PROC far
	push ds
	push es
	push fs
	pusha
	mov al,[bp+2].vm_eflags
	test al,2
	jz write_stg_pm
;
	mov ax,flat_sel
	mov fs,ax
	xor eax,eax
	xor ebx,ebx
	mov ax,[bp].vm_es
	shl eax,4
	mov bx,[bp].vm_bp
	add ebx,eax
	jmp write_stg_do

write_stg_pm:
	xor ebx,ebx
	mov bx,[bp].vm_bp
	mov ax,es
	mov fs,ax

write_stg_do:
	mov ax,video_thread_sel
	mov ds,ax
	mov si,cx
	movzx cx,dl
	movzx dx,dh
;
	movzx di,byte ptr [bp].vm_eax
	call cs:word ptr [di].write_stg_tab
;
	popa
	pop fs
	pop es
	pop ds
	ret
write_stg	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_TELETYPE
;
;		DESCRIPTION:	Write teletype (BIOS)
;
;		PARAMETERS:		AL		Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_teletype	PROC far
	WriteChar
	ret
write_teletype	ENDP

dummy_video	PROC far
	ret
dummy_video	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GET_VIDEO_STATE
;
;		DESCRIPTION:	Get video state
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_video_state	PROC far
	mov al,3
	mov ah,80
	mov bh,0
	ret
get_video_state	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FONT_INFO
;
;		DESCRIPTION:	Read font info
;
;		PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

font_info	Proc far
	cmp al,30h
	je font_info_30
	ret
font_info_30:
	mov dl,24
	mov cx,2
	ret
font_info	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			VIDEO_IO
;
;		DESCRIPTION:	INT 10
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
							
video_tab:
v0	DW OFFSET dummy_video
v1	DW OFFSET dummy_video
v2	DW OFFSET set_cursor_pos
v3	DW OFFSET read_cursor_pos
v4	DW OFFSET read_light_pen
v5	DW OFFSET dummy_video
v6	DW OFFSET scroll_video_up
v7	DW OFFSET scroll_video_down
v8	DW OFFSET read_video_attrib
v9	DW OFFSET write_ch_attr
v10	DW OFFSET write_ch
v11	DW OFFSET dummy_video
v12	DW OFFSET dummy_video
v13	DW OFFSET dummy_video
v14	DW OFFSET write_teletype
v15	DW OFFSET get_video_state
v16	DW OFFSET dummy_video
v17	DW OFFSET font_info
v18	DW OFFSET dummy_video
v19	DW OFFSET write_stg
vend	DW OFFSET dummy_video

int10:
	SimSti
	mov bl,ah
	xor bh,bh
	add bx,bx
	cmp bx,40
	jc video_call_do
	mov bx,40
video_call_do:
	push word ptr cs:[bx].video_tab
	mov bx,[bp].vm_ebx
	retn

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			lost_focus_hook
;
;		DESCRIPTION:	Lost focus hook
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
lost_focus_hook	PROC far
	push ds
	push ax
	mov ax,video_focus_sel
	mov ds,ax
	pop ax
	mov ds,ds:v_handle
	call ds:switch_from_proc
	pop ds
	ret
lost_focus_hook	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			got_focus_hook
;
;		DESCRIPTION:	Got focus hook
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
got_focus_hook	PROC far
	push ds
	push ax
	mov ax,video_focus_sel
	mov ds,ax
	pop ax
	mov ds,ds:v_handle
	call ds:switch_to_proc
	pop ds
	ret
got_focus_hook	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			bda_get_mode
;
;		DESCRIPTION:	Get video mode
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bda_get_mode	Proc far
	mov al,3
	ret
bda_get_mode	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			bda_set_mode
;
;		DESCRIPTION:	Set video mode
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bda_set_mode	Proc far
	ret
bda_set_mode	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			bda_get_width
;
;		DESCRIPTION:	Get display width
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bda_get_width	Proc far
	mov al,80
	ret
bda_get_width	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			bda_set_width
;
;		DESCRIPTION:	Set display width
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bda_set_width	Proc far
	ret
bda_set_width	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			bda_get_cursor_col
;
;		DESCRIPTION:	Get cursor column
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bda_get_cursor_col	Proc far
	push ds
	push bx
	mov bx,video_thread_sel
	mov ds,bx
	mov al,byte ptr ds:vt_col
	pop bx
	pop ds
	ret
bda_get_cursor_col	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			bda_set_cursor_col
;
;		DESCRIPTION:	Set cursor column
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bda_set_cursor_col	Proc far
	push ds
	push bx
	mov bx,video_thread_sel
	mov ds,bx
	mov byte ptr ds:vt_col,al
	pop bx
	pop ds
	ret
bda_set_cursor_col	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			bda_get_cursor_row
;
;		DESCRIPTION:	Get cursor row
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bda_get_cursor_row	Proc far
	push ds
	push bx
	mov bx,video_thread_sel
	mov ds,bx
	mov al,byte ptr ds:vt_row
	pop bx
	pop ds
	ret
bda_get_cursor_row	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			bda_set_cursor_row
;
;		DESCRIPTION:	Set cursor row
;
;		PARAMETERS:		AL		Value
;						BX		Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bda_set_cursor_row	Proc far
	push ds
	push bx
	mov bx,video_thread_sel
	mov ds,bx
	mov byte ptr ds:vt_row,al
	pop bx
	pop ds
	ret
bda_set_cursor_row	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_THREAD
;
;		DESCRIPTION:	init thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
init_thread	PROC far
	push ds
	push ax
;
	mov ax,video_thread_sel
	mov ds,ax
	mov ds:vt_forecolor,7
	mov ds:vt_backcolor,0
	mov ds:vt_row,0
	mov ds:vt_col,0
;
	pop ax
	pop ds
	ret
init_thread	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Free_process
;
;		DESCRIPTION:	free process
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_process	Proc far
	push ds
	push bx
;
	mov bx,video_local_sel
	mov ds,bx
	mov bx,ds:v_handle
	or bx,bx
	jz free_process_done
;
	mov ds,bx
	call ds:destruct_proc

free_process_done:
	pop bx
	pop ds
	ret
free_process	Endp

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
	mov ax,video_local_sel
	mov ds,ax
	mov ds:v_handle,0
	ret
init_focus	Endp

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
			
init	PROC far
	pusha
	push ds
	mov bx,video_code_sel
	InitDevice
;
	mov eax,SIZE video_data_seg
	mov bx,video_data_sel
	AllocateFixedSystemMem
	mov es:v_list,0
;
	mov eax,SIZE video_thread_seg
	mov bx,video_thread_sel
	AllocateFixedThreadMem
;
	mov eax,SIZE video_focus_seg
	mov bx,video_local_sel
	mov dx,video_focus_sel
	AllocateFixedFocusMem
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_thread
	HookCreateThread
;
	mov di,OFFSET init_thread
	HookTerminateProcess
;
	mov di,OFFSET init_focus
	HookEnableFocus
;
	mov di,OFFSET lost_focus_hook
	HookLostFocus
;
	mov di,OFFSET got_focus_hook
	HookGotFocus
;
	mov si,OFFSET register_video_mode
	mov di,OFFSET register_video_mode_name
	xor cl,cl
	mov ax,register_video_mode_nr
	RegisterOsGate
;
	mov si,OFFSET set_video_mode
	mov di,OFFSET set_video_mode_name
	xor dx,dx
	mov ax,set_video_mode_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_cursor_position
	mov di,OFFSET set_cursor_pos_name
	xor dx,dx
	mov ax,set_cursor_position_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_cursor_position
	mov di,OFFSET get_cursor_pos_name
	xor dx,dx
	mov ax,get_cursor_position_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_forecolor
	mov di,OFFSET set_forecolor_name
	xor dx,dx
	mov ax,set_forecolor_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_backcolor
	mov di,OFFSET set_backcolor_name
	xor dx,dx
	mov ax,set_backcolor_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET write_char
	mov di,OFFSET write_char_name
	xor dx,dx
	mov ax,write_char_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET write_asciiz16
	mov si,OFFSET write_asciiz32
	mov di,OFFSET write_asciiz_name
	mov dx,virt_es_in
	mov ax,write_asciiz_nr
	RegisterUserGate
;
	mov bx,OFFSET write_size_string16
	mov si,OFFSET write_size_string32
	mov di,OFFSET write_size_string_name
	mov dx,virt_es_in
	mov ax,write_size_string_nr
	RegisterUserGate
;
	mov si,OFFSET set_draw_color
	mov di,OFFSET set_draw_color_name
	xor dx,dx
	mov ax,set_drawcolor_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_lgop
	mov di,OFFSET set_lgop_name
	xor dx,dx
	mov ax,set_lgop_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_hollow_style
	mov di,OFFSET set_hollow_style_name
	xor dx,dx
	mov ax,set_hollow_style_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_filled_style
	mov di,OFFSET set_filled_style_name
	xor dx,dx
	mov ax,set_filled_style_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_font
	mov di,OFFSET set_font_name
	xor dx,dx
	mov ax,set_font_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_pixel
	mov di,OFFSET get_pixel_name
	xor dx,dx
	mov ax,get_pixel_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_pixel
	mov di,OFFSET set_pixel_name
	xor dx,dx
	mov ax,set_pixel_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET blit_pr
	mov di,OFFSET blit_name
	xor dx,dx
	mov ax,blit_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET draw_mask
	mov di,OFFSET draw_mask_name
	xor dx,dx
	mov ax,draw_mask_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET draw_string16
	mov si,OFFSET draw_string32
	mov di,OFFSET draw_string_name
	mov dx,virt_es_in
	mov ax,draw_string_nr
	RegisterUserGate
;
	mov si,OFFSET draw_line
	mov di,OFFSET draw_line_name
	xor dx,dx
	mov ax,draw_line_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET draw_rect
	mov di,OFFSET draw_rect_name
	xor dx,dx
	mov ax,draw_rect_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET draw_ellipse
	mov di,OFFSET draw_ellipse_name
	xor dx,dx
	mov ax,draw_ellipse_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET write_dos_string
	mov di,OFFSET write_dos_string_name
	xor cl,cl
	mov ax,write_dos_string_nr
	RegisterOsGate
;
	mov ax,cs
	mov ds,ax
	mov al,10h
	mov di,OFFSET int10
	HookVMInt
;
	mov ax,cs
	mov es,ax
;
	mov bx,49h
	mov di,OFFSET bda_get_mode
	HookGetBiosData
	mov di,OFFSET bda_set_mode
	HookSetBiosData
;
	mov bx,4Ah
	mov di,OFFSET bda_get_width
	HookGetBiosData
	mov di,OFFSET bda_set_width
	HookSetBiosData
;
	mov bx,50h
	mov di,OFFSET bda_get_cursor_col
	HookGetBiosData
	mov di,OFFSET bda_set_cursor_col
	HookSetBiosData
;
	mov bx,51h
	mov di,OFFSET bda_get_cursor_row
	HookGetBiosData
	mov di,OFFSET bda_set_cursor_row
	HookSetBiosData
;
	call init_bitmap
;
	pop ds
	popa
	ret
init	ENDP

code	ENDS

	END init
