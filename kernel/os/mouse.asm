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
; MOUSE.ASM
; Basic mouse support module.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME mouse

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\driver.def
INCLUDE ..\os\user.def
INCLUDE ..\os\os.def
INCLUDE ..\os\user.inc
INCLUDE ..\os\os.inc
INCLUDE ..\os\system.inc
INCLUDE mouse.inc

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			hide_marker
;
;		DESCRIPTION:	hide marker
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hide_marker	PROC near
	push ds
	push ax
	push bx
	push cx
	push dx
;
	mov ax,ds:m_cursor_flag
	or ax,ax
	jz hide_marker_done
;
	GetCursorPosition
	push cx
	push dx
;
	mov ax,ds:m_horiz_pos
	xor dx,dx
	div ds:m_horiz_mickey
	mov cx,ax
;
	mov ax,ds:m_vert_pos
	xor dx,dx
	div ds:m_vert_mickey
	mov dx,ax
;
	SetCursorPosition
	GetCharAttrib
	push ax
	mov al,bh
	SetForeColor
	mov al,bl
	SetBackColor
	pop ax
	WriteChar
;
	pop dx
	pop cx
	SetCursorPosition

hide_marker_done:
	pop dx
	pop cx
	pop bx
	pop ax
	pop ds
	ret
hide_marker	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			show_marker
;
;		DESCRIPTION:	show marker
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_marker	PROC near
	push ds
	push ax
	push bx
	push cx
	push dx
;
	mov ax,ds:m_cursor_flag
	or ax,ax
	jz show_marker_done
;
	GetCursorPosition
	push cx
	push dx
;
	mov ax,ds:m_horiz_pos
	xor dx,dx
	div ds:m_horiz_mickey
	mov cx,ax
;
	mov ax,ds:m_vert_pos
	xor dx,dx
	div ds:m_vert_mickey
	mov dx,ax
;
	SetCursorPosition
	GetCharAttrib
	push ax
	mov al,bh
	SetForeColor
	mov al,bl
	SetBackColor
	pop ax
	WriteChar
;
	pop dx
	pop cx
	SetCursorPosition

show_marker_done:
	pop dx
	pop cx
	pop bx
	pop ax
	pop ds
	ret
show_marker	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			update_mouse
;
;		DESCRIPTION:	update mouse from IRQ
;
;		PARAMETERS:		AX		Buttons
;						CX		Dx
;  					    DX		Dy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_mouse_name	DB 'Update Mouse',0

update_mouse	PROC far
	push ds
	push bx
;
	mov bx,mouse_data_sel
	mov ds,bx
	mov ds:md_buttons,ax
	add ds:md_dx,cx
	neg dx
	add ds:md_dy,dx
	mov bx,ds:md_mouse_thread
	mov ax,mouse_focus_sel
	mov ds,ax
	mov ax,ds:m_notify_thread
	or ax,ax
	jz mouse_int_signal
	mov bx,ax
mouse_int_signal:
	Signal
;
	pop bx
	pop ds
	ret
update_mouse	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			check_horiz_position
;
;		DESCRIPTION:	check horizontal position
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
check_horiz_position	PROC near
	push ax
	mov ax,ds:m_horiz_pos
	cmp ax,ds:m_horiz_min
	jge set_horiz_min_ok
	mov ax,ds:m_horiz_min
set_horiz_min_ok:
	cmp ax,ds:m_horiz_max
	jle set_horiz_max_ok
	mov ax,ds:m_horiz_max
set_horiz_max_ok:
	mov ds:m_horiz_pos,ax
	pop ax
	ret
check_horiz_position	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			check_vert_position
;
;		DESCRIPTION:	check vertical position
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_vert_position	PROC near
	push ax
	mov ax,ds:m_vert_pos
	cmp ax,ds:m_vert_min
	jge set_vert_min_ok
	mov ax,ds:m_vert_min
set_vert_min_ok:
	cmp ax,ds:m_vert_max
	jle set_vert_max_ok
	mov ax,ds:m_vert_max
set_vert_max_ok:
	mov ds:m_vert_pos,ax
	pop ax
	ret
check_vert_position	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			refresh_mouse
;
;		DESCRIPTION:	refresh mouse parameters
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

refresh_mouse	Proc near
	mov ax,es:md_buttons
	mov dx,ds:m_botton_status
	mov dh,al
	xor dl,al
	jz mouse_buttons_done
;
	mov ds:m_botton_status,ax
	test dl,1
	jz mouse_button1_handled
;
	test dh,1
	jz mouse_button1_released
mouse_button1_pressed:
	mov ax,ds:m_horiz_pos
	mov ds:m_horiz_press0,ax
	mov ax,ds:m_vert_pos
	mov ds:m_vert_press0,ax
	jmp mouse_button1_handled

mouse_button1_released:	
	mov ax,ds:m_horiz_pos
	mov ds:m_horiz_rel0,ax
	mov ax,ds:m_vert_pos
	mov ds:m_vert_rel0,ax

mouse_button1_handled:
	test dl,2
	jz mouse_buttons_done
;
	test dh,2
	jz mouse_button2_released

mouse_button2_pressed:
	mov ax,ds:m_horiz_pos
	mov ds:m_horiz_press1,ax
	mov ax,ds:m_vert_pos
	mov ds:m_vert_press1,ax
	jmp mouse_buttons_done

mouse_button2_released:	
	mov ax,ds:m_horiz_pos
	mov ds:m_horiz_rel1,ax
	mov ax,ds:m_vert_pos
	mov ds:m_vert_rel1,ax

mouse_buttons_done:
	xor cx,cx
	xchg cx,es:md_dx
	or cx,cx
	jz update_not_horiz
;
	add ds:m_horiz_motion,cx
	add ds:m_horiz_pos,cx
	call check_horiz_position

update_not_horiz:
	xor dx,dx
	xchg dx,es:md_dy
	or dx,dx
	jz update_not_vert
;
	add ds:m_vert_motion,dx
	add ds:m_vert_pos,dx
	call check_vert_position

update_not_vert:
	ret
refresh_mouse	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			reset
;
;		DESCRIPTION:	reset mouse params
;
;		PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset	PROC near
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	xor ax,ax
	mov ds:m_notify_thread,ax
	mov ds:m_cursor_flag,ax
	mov ds:m_horiz_pos,ax
	mov ds:m_vert_pos,ax
	mov ds:m_botton_status,ax
	mov ds:m_horiz_motion,ax
	mov ds:m_vert_motion,ax
;
	mov ds:m_horiz_mickey,8
	mov ds:m_vert_mickey,8
;
	mov ds:m_horiz_min,ax
	mov ds:m_horiz_max,639
	mov ds:m_vert_min,ax
	mov ds:m_vert_max,199
;
	mov ds:m_horiz_press0,ax
	mov ds:m_vert_press0,ax
	mov ds:m_count_press0,ax
;
	mov ds:m_horiz_press1,ax
	mov ds:m_vert_press1,ax
	mov ds:m_count_press1,ax
;
	mov ds:m_horiz_rel0,ax
	mov ds:m_vert_rel0,ax
	mov ds:m_count_rel0,ax
;
	mov ds:m_horiz_rel1,ax
	mov ds:m_vert_rel1,ax
	mov ds:m_count_rel1,ax
;
	mov ds:m_cursor_type,ax
	mov ds:m_screen_mask,0FFFFh
	mov ds:m_cursor_mask,077FFh
;
	pop ax
	pop ds
	ret
reset	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			int33
;
;		DESCRIPTION:	int 33 support
;
;		PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_param	PROC far
	call reset
	mov ax,0FFFFh
	mov bx,2
	ret
init_param	ENDP

show	PROC far
	mov ax,mouse_local_sel
	mov ds,ax
	call hide_marker
	inc ds:m_cursor_flag
	call show_marker
	mov ax,[bp].vm_eax
	mov ds,[bp].pm_ds
	ret
show	ENDP

hide	PROC far
	mov ax,mouse_local_sel
	mov ds,ax
	call hide_marker
	dec ds:m_cursor_flag
	call show_marker
	mov ax,[bp].vm_eax
	mov ds,[bp].pm_ds
	ret
hide	ENDP

get_position	PROC far
	mov ax,mouse_local_sel
	mov ds,ax
	mov bx,ds:m_botton_status
	mov cx,ds:m_horiz_pos
	mov dx,ds:m_vert_pos	
	mov ax,[bp].vm_eax
	mov ds,[bp].pm_ds
	ret
get_position	ENDP

set_position	PROC far
	mov ax,mouse_local_sel
	mov ds,ax
	call hide_marker
	mov ds:m_horiz_pos,cx
	mov ds:m_vert_pos,dx
	call check_horiz_position
	call check_vert_position
	call show_marker
	mov ax,[bp].vm_eax
	mov ds,[bp].pm_ds
	ret
set_position	ENDP

get_press_info	PROC far
	mov ax,mouse_local_sel
	mov ds,ax
	mov ax,ds:m_botton_status
	or bl,bl
	jz get_press0
get_press1:
	mov bx,ds:m_count_press1
	mov cx,ds:m_horiz_press1
	mov dx,ds:m_vert_press1
	mov ds,[bp].pm_ds
	ret
get_press0:
	mov bx,ds:m_count_press0
	mov cx,ds:m_horiz_press0
	mov dx,ds:m_vert_press0
	mov ds,[bp].pm_ds
	ret
get_press_info	ENDP

get_rel_info	PROC far
	mov ax,mouse_local_sel
	mov ds,ax
	mov ax,ds:m_botton_status
	or bl,bl
	jz get_rel0
get_rel1:
	mov bx,ds:m_count_rel1
	mov cx,ds:m_horiz_rel1
	mov dx,ds:m_vert_rel1
	mov ds,[bp].pm_ds
	ret
get_rel0:
	mov bx,ds:m_count_rel0
	mov cx,ds:m_horiz_rel0
	mov dx,ds:m_vert_rel0
	mov ds,[bp].pm_ds
	ret
get_rel_info	ENDP

set_horiz_area	PROC far
	mov ax,mouse_local_sel
	mov ds,ax
	call hide_marker
	cmp dx,cx
	jge set_horiz_noswap
	mov ds:m_horiz_min,dx
	mov ds:m_horiz_max,cx
	jmp set_horiz_test_pos
set_horiz_noswap:
	mov ds:m_horiz_min,cx
	mov ds:m_horiz_max,dx
set_horiz_test_pos:
	call check_horiz_position
	call show_marker
	mov ax,[bp].vm_eax
	mov ds,[bp].pm_ds
	ret
set_horiz_area	ENDP

set_vert_area	PROC far
	mov ax,mouse_local_sel
	mov ds,ax
	call hide_marker
	cmp dx,cx
	jge set_vert_noswap
	mov ds:m_vert_min,dx
	mov ds:m_vert_max,cx
	jmp set_vert_test_pos
set_vert_noswap:
	mov ds:m_vert_min,cx
	mov ds:m_vert_max,dx
set_vert_test_pos:
	call check_vert_position
	call show_marker
	mov ax,[bp].vm_eax
	mov ds,[bp].pm_ds
	ret
set_vert_area	ENDP

dummy	PROC far
	ret
dummy	ENDP

set_cursor_type	PROC far
	mov ax,mouse_local_sel
	mov ds,ax
	call hide_marker
	mov ax,[bp].vm_ebx
	or ax,ax
	jnz set_cursor_not_supported
	mov ds:m_cursor_type,ax
	mov ds:m_screen_mask,cx
	mov ds:m_cursor_mask,dx
set_cursor_not_supported:
	call show_marker
	mov ax,[bp].vm_eax
	mov ds,[bp].pm_ds
	ret
set_cursor_type	ENDP

read_motion_counter	PROC far
	mov ax,mouse_local_sel
	mov ds,ax
	xor cx,cx
	xchg cx,ds:m_horiz_motion
	xor dx,dx
	xchg dx,ds:m_vert_motion
	mov ax,[bp].vm_eax
	mov ds,[bp].pm_ds
	ret
read_motion_counter	ENDP

set_mickey	PROC far
	mov ax,mouse_local_sel
	mov ds,ax
	mov ds:m_horiz_mickey,cx
	mov ds:m_vert_mickey,dx
	mov ax,[bp].vm_eax
	mov ds,[bp].pm_ds
	ret
set_mickey	ENDP

mouse_tab:
mo00	DW OFFSET init_param
mo01	DW OFFSET show
mo02	DW OFFSET hide
mo03	DW OFFSET get_position
mo04	DW OFFSET set_position
mo05	DW OFFSET get_press_info
mo06	DW OFFSET get_rel_info
mo07	DW OFFSET set_horiz_area
mo08	DW OFFSET set_vert_area
mo09	DW OFFSET dummy
mo0A	DW OFFSET set_cursor_type
mo0B	DW OFFSET read_motion_counter
mo0C	DW OFFSET dummy
mo0D	DW OFFSET dummy
mo0E	DW OFFSET dummy
mo0F	DW OFFSET set_mickey
mo10	DW OFFSET dummy
mo11	DW OFFSET dummy
mo12	DW OFFSET dummy
mo13	DW OFFSET dummy
mo14	DW OFFSET dummy
mo15	DW OFFSET dummy
mo16	DW OFFSET dummy
mo17	DW OFFSET dummy
mo18	DW OFFSET dummy
mo19	DW OFFSET dummy
mo1A	DW OFFSET dummy
mo1B	DW OFFSET dummy
mo1C	DW OFFSET dummy
mo1D	DW OFFSET dummy
mo1E	DW OFFSET dummy
mo1F	DW OFFSET dummy
mo20	DW OFFSET dummy

int33:
	SimSti
	mov bx,ax
	add bx,bx
	cmp bx,40h
	jc mouse_call_do
	mov bx,40h
mouse_call_do:
	push word ptr cs:[bx].mouse_tab
	mov bx,[bp].vm_ebx
	retn

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			show_mouse
;
;		DESCRIPTION:	show mouse
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_mouse_name	DB 'Show Mouse',0

show_mouse	PROC far
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	call hide_marker
	inc ds:m_cursor_flag
	call show_marker
;
	pop ax
	pop ds
	retf32
show_mouse	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			hide_mouse
;
;		DESCRIPTION:	hide mouse
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hide_mouse_name	DB 'Hide Mouse',0

hide_mouse	PROC far
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	call hide_marker
	dec ds:m_cursor_flag
	call show_marker
;
	pop ax
	pop ds
	retf32
hide_mouse	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			get_mouse_position
;
;		DESCRIPTION:	get position
;
;		RETURNS:		CX		X
;						DX		Y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_mouse_position_name	DB 'Get Mouse Position',0

get_mouse_position	PROC far
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	mov cx,ds:m_horiz_pos
	mov dx,ds:m_vert_pos	
;
	pop ax
	pop ds
	retf32
get_mouse_position	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			set_position
;
;		DESCRIPTION:	set position
;
;		PARAMETERS:		CX		X
;						DX		Y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_mouse_position_name	DB 'Set Mouse Position',0

set_mouse_position	PROC far
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	call hide_marker
	mov ds:m_horiz_pos,cx
	mov ds:m_vert_pos,dx
	call check_horiz_position
	call check_vert_position
	call show_marker
;
	pop ax
	pop ds
	retf32
set_mouse_position	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			get_left_button
;
;		DESCRIPTION:	check if left mouse button is pressed
;
;		RETURNS:		NC		pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_left_button_name	DB 'Get Left Button',0

get_left_button	PROC far
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	mov ax,ds:m_botton_status
	rcr al,1
	cmc
;
	pop ax
	pop ds
	retf32
get_left_button	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			get_right_button
;
;		DESCRIPTION:	check if right mouse button is pressed
;
;		RETURNS:		NC		pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_right_button_name	DB 'Get Right Button',0

get_right_button	PROC far
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	mov ax,ds:m_botton_status
	rcr al,2
	cmc
;
	pop ax
	pop ds
	retf32
get_right_button	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			get_left_button_press_position
;
;		DESCRIPTION:	get position of last left button press
;
;		RETURNS:		CX		x
;						DX		y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_left_button_press_position_name	DB 'Get Left Button Press Position',0

get_left_button_press_position	PROC far
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	mov cx,ds:m_horiz_press0
	mov dx,ds:m_vert_press0
;
	pop ax
	pop ds
	retf32
get_left_button_press_position	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			get_right_button_press_position
;
;		DESCRIPTION:	get position of last right button press
;
;		RETURNS:		CX		x
;						DX		y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_right_button_press_position_name	DB 'Get Right Button Press Position',0

get_right_button_press_position	PROC far
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	mov cx,ds:m_horiz_press1
	mov dx,ds:m_vert_press1
;
	pop ax
	pop ds
	retf32
get_right_button_press_position	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			get_left_button_release_position
;
;		DESCRIPTION:	get position of last left button release
;
;		RETURNS:		CX		x
;						DX		y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_left_button_release_position_name	DB 'Get Left Button Release Position',0

get_left_button_release_position	PROC far
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	mov cx,ds:m_horiz_rel0
	mov dx,ds:m_vert_rel0
;
	pop ax
	pop ds
	retf32
get_left_button_release_position	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			get_right_button_release_position
;
;		DESCRIPTION:	get position of last right button release
;
;		RETURNS:		CX		x
;						DX		y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_right_button_release_position_name	DB 'Get Right Button Release Position',0

get_right_button_release_position	PROC far
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	mov cx,ds:m_horiz_rel1
	mov dx,ds:m_vert_rel1
;
	pop ax
	pop ds
	retf32
get_right_button_release_position	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			set_mouse_window
;
;		DESCRIPTION:	set window of mouse movement
;
;		PARAMETERS:		AX		start x
;						BX		start y
;						CX		end x
;						DX		end y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_mouse_window_name	DB 'Set Mouse Window',0

set_mouse_window	PROC far
	push ds
;
	push mouse_local_sel
	pop ds
	call hide_marker
	mov ds:m_horiz_min,ax
	mov ds:m_horiz_max,cx
	mov ds:m_vert_min,bx
	mov ds:m_vert_max,dx
;
	call check_horiz_position
	call check_vert_position
	call show_marker
;
	pop ds
	retf32
set_mouse_window	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			set_mouse_mickey
;
;		DESCRIPTION:	set mouse mickeys
;
;		PARAMETERS:		CX		mickeys in x-direction
;						DX		mickeys in y-direction
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_mouse_mickey_name	DB 'Set Mouse Mickey',0

set_mouse_mickey	PROC far
	push ds
	push ax
;
	mov ax,mouse_local_sel
	mov ds,ax
	mov ds:m_horiz_mickey,cx
	mov ds:m_vert_mickey,dx
;
	pop ax
	pop ds
	retf32
set_mouse_mickey	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Mouse callback thread
;
;		DESCRIPTION:	Implements the mouse hooks
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_thread_name	DB 'Mouse Hook',0

hook_thread	Proc far
	mov ax,mouse_local_sel
	mov ds,ax
	GetThread
	mov ds:m_notify_thread,ax

hook_thread_loop:
	mov bx,mouse_local_sel
	mov ds,bx
	mov ax,mouse_data_sel
	mov es,ax
;
	WaitForSignal
	GetThread
	cmp ax,ds:m_notify_thread
	jne hook_thread_end	
;
	call hide_marker
	call refresh_mouse
	call show_marker
;
	mov ax,ds:m_botton_status
	mov cx,ds:m_horiz_pos
	mov dx,ds:m_vert_pos
	push ds:m_notify_offs
	CallPm32
	jmp hook_thread_loop

hook_thread_end:
	ret
hook_thread	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HookMouse
;
;		DESCRIPTION:	Create a mouse callback
;
;		PARAMETERS:		ES:(E)DI	Callback
;							AX		Mouse buttons
;							CX		x
;							DX		y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_mouse_name	DB 'Hook Mouse',0

hook_mouse	PROC near
	push ds
	push es
	push ax
	push bx
	push si
	push di
;
	mov bx,mouse_local_sel
	mov ds,bx
	mov ax,ds:m_notify_thread
	or ax,ax
	jz hook_mouse_do
	UnhookMouse

hook_mouse_do:
	mov ds:m_notify_sel,es
	mov ds:m_notify_offs,edi
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET hook_thread
	mov di,OFFSET hook_thread_name
	mov cx,100h
	mov ax,4
	CreateThread
;
	pop di
	pop si
	pop bx
	pop ax
	pop es
	pop ds
	ret
hook_mouse	ENDP

hook_mouse16	Proc far
	push edi
	movzx edi,di
	call hook_mouse
	pop edi
	ret
hook_mouse16	Endp

hook_mouse32	Proc far
	call hook_mouse
	retf32
hook_mouse32	Endp	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UnhookMouse
;
;		DESCRIPTION:	Delete a mouse callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unhook_mouse_name	DB 'Unhook Mouse',0

unhook_mouse	PROC near
	push ds
	push bx
;
	mov bx,mouse_local_sel
	mov ds,bx
	xor bx,bx
	xchg bx,ds:m_notify_thread
	Signal
;
	pop bx
	pop ds
	retf32
unhook_mouse	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			mouse_thread
;
;		DESCRIPTION:	Mouse handling thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mouse_thread_name	DB 'Mouse' ,0

mouse_thread	Proc far
	InitMouse
	mov ax,mouse_data_sel
	mov es,ax
	GetThread
	mov es:md_mouse_thread,ax
mouse_thread_loop:
	mov bx,mouse_focus_sel
	mov ds,bx
	mov ax,mouse_data_sel
	mov es,ax
;
	WaitForSignal
	call hide_marker
	call refresh_mouse
	call show_marker
	jmp mouse_thread_loop
	ret
mouse_thread	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_FOCUS
;
;		DESCRIPTION:	focus init of mouse
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_focus	PROC far
	call reset
	ret
init_focus	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_MOUSE
;
;		DESCRIPTION:	focus init of mouse
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mouse	PROC far
	push ds
	push es
	pusha
;
	mov ax,mouse_data_sel
	mov ds,ax
	mov ds:md_buttons,0
	mov ds:md_dx,0
	mov ds:md_dy,0
	mov ds:md_mouse_thread,0
;
	mov ax,init_mouse_nr
	IsValidOsGate
	jc init_mouse_done
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET mouse_thread
	mov di,OFFSET mouse_thread_name
	mov ax,3
	mov cx,256
	CreateThread

init_mouse_done:
	popa
	pop es
	pop ds
	ret
init_mouse	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT
;
;		DESCRIPTION:	INITIERA driver
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init

init	PROC far
	push ds
	push es
	pusha
;
	mov bx,mouse_code_sel
	InitDevice
;
	mov bx,mouse_local_sel
	mov dx,mouse_focus_sel
	mov eax,OFFSET m_end
	AllocateFixedFocusMem
;
	mov bx,mouse_data_sel
	mov eax,OFFSET md_end
	AllocateFixedSystemMem
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_focus
	HookEnableFocus
;
	mov di,OFFSET init_mouse
	HookInitTasking
;
	mov al,33h
	mov di,OFFSET int33
	HookVMInt
;
	mov si,OFFSET update_mouse
	mov di,OFFSET update_mouse_name
	xor cl,cl
	mov ax,update_mouse_nr
	RegisterOsGate
;
	mov si,OFFSET show_mouse
	mov di,OFFSET show_mouse_name
	xor dx,dx
	mov ax,show_mouse_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET hide_mouse
	mov di,OFFSET hide_mouse_name
	xor dx,dx
	mov ax,hide_mouse_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_mouse_position
	mov di,OFFSET get_mouse_position_name
	xor dx,dx
	mov ax,get_mouse_position_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_mouse_position
	mov di,OFFSET set_mouse_position_name
	xor dx,dx
	mov ax,set_mouse_position_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_mouse_window
	mov di,OFFSET set_mouse_window_name
	xor dx,dx
	mov ax,set_mouse_window_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_mouse_mickey
	mov di,OFFSET set_mouse_mickey_name
	xor dx,dx
	mov ax,set_mouse_mickey_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_left_button
	mov di,OFFSET get_left_button_name
	xor dx,dx
	mov ax,get_left_button_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_right_button
	mov di,OFFSET get_right_button_name
	xor dx,dx
	mov ax,get_right_button_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_left_button_press_position
	mov di,OFFSET get_left_button_press_position_name
	xor dx,dx
	mov ax,get_left_button_press_position_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_right_button_press_position
	mov di,OFFSET get_right_button_press_position_name
	xor dx,dx
	mov ax,get_right_button_press_position_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_left_button_release_position
	mov di,OFFSET get_left_button_release_position_name
	xor dx,dx
	mov ax,get_left_button_release_position_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_right_button_release_position
	mov di,OFFSET get_right_button_release_position_name
	xor dx,dx
	mov ax,get_right_button_release_position_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET hook_mouse16
	mov si,OFFSET hook_mouse32
	mov di,OFFSET hook_mouse_name
	xor dx,dx
	mov ax,hook_mouse_nr
	RegisterUserGate
;
	mov si,OFFSET unhook_mouse
	mov di,OFFSET unhook_mouse_name
	xor dx,dx
	mov ax,unhook_mouse_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init
