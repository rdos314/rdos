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
; KEY.ASM
; Basic keyboard support module.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME key

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE protseg.def
INCLUDE system.def
INCLUDE driver.def
INCLUDE port.def
INCLUDE user.def
INCLUDE os.def
INCLUDE system.inc
INCLUDE user.inc
INCLUDE os.inc

;
; offset in scan-table
;
normal_code		EQU 0
shift_code		EQU 1
alt_code		EQU 2
alt_shift_code	EQU 3
ctrl_code		EQU 4
xtra_code		EQU 5
syntax_call		EQU 6

;
; ctrl_func data types
;
ctrl_F1		EQU 0
ctrl_F2		EQU 1
ctrl_F3		EQU 2
ctrl_F4		EQU 3
ctrl_F5		EQU 4
ctrl_F6		EQU 5
ctrl_F7		EQU 6
ctrl_F8		EQU 7
ctrl_F9		EQU 8
ctrl_F10	EQU 9

;
; status
;
status_key_req		EQU 1
status_mouse_req	EQU 2
status_key_ack		EQU 4
status_mouse_ack	EQU 8

key_proc_seg	SEGMENT AT 0

key_proc_wait		DW ?
extend_key			DB ?

key_buffer_head		DW ?
key_buffer_tail		DW ?
key_buffer_start	DW 256 DUP(?)
key_buffer_end		DW ?

key_emul_thread		DW ?
key_int_seg			DW ?
key_int_offs		DW ?

key_notify_thread	DW ?
key_notify_sel		DW ?
key_notify_offs		DD ?

key_proc_seg	ENDS

key_data_seg	SEGMENT AT 0

shift_states	DW ?
mode_thread		DW ?
keyboard_thread	DW ?
mouse_thread	DW ?
command			DB ?
scan_code		DB ?
status			DB ?

mouse_timeout	DB ?
mouse_counter	DB ?
mouse_buttons	DB ?
mouse_dx		DB ?
mouse_dy		DB ?

key_data_seg	ENDS

	.386p

PutKeyInBuffer	MACRO
	local no_circ
	local wake_done
	mov bx,ds:key_buffer_tail
	mov si,bx
	inc bx
	inc bx
	cli
	cmp bx,OFFSET key_buffer_end
	jne no_circ
	mov bx,OFFSET key_buffer_start
no_circ:
	mov [si],ax
	mov ds:key_buffer_tail,bx
;
	mov si,OFFSET key_proc_wait
	mov ax,[si]
	or ax,ax
	jz wake_done
	sti
	Wake
wake_done:
	sti
		ENDM

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn scan_code_tab:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			put_key_code
;
;		DESCRIPTION:	Save scan code in buffer
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

put_key_code	PROC near
	xchg ah,al
	cmp al,-1
	je put_key_end
	cmp ah,-1
	je put_key_end
	push ds
	push bx
	push si
	mov bx,key_focus_sel
	mov ds,bx
	PutKeyInBuffer
	pop si
	pop bx
	pop ds
put_key_end:
	ret
put_key_code	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			dummy_scan
;
;		DESCRIPTION:	Handle unsupported keys
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public dummy_scan

dummy_scan	PROC near
	stc 
	ret
dummy_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			del_scan
;
;		DESCRIPTION:	Handle DEL key
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public del_scan

del_scan	PROC near
	mov cx,ds:shift_states
	and cx,alt_pressed OR ctrl_pressed
	cmp cx,alt_pressed OR ctrl_pressed
	jne num_scan
;
	cli
wait_gate1:
	in al,64h
	and al,2
	jnz wait_gate1
	mov al,0D1h
	out 64h,al
wait_gate2:
	in al,64h
	and al,2
	jnz wait_gate2
	mov al,0FEh
	out 60h,al
;
	xor eax,eax
	mov cr3,eax
	ret
del_scan	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			simple_scan
;
;		DESCRIPTION:	Handle normal keys
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public simple_scan

simple_scan	PROC near
	mov cx,ds:shift_states
	and cx,7
	test cx,4
	jz simple_sc_no_ctrl
	mov cx,4
simple_sc_no_ctrl:
	add bx,cx
	mov ah,cs:[bx]
	or ah,ah
	jne simple_sc_no_ext
	sub bx,cx
	add bx,5
	mov al,cs:[bx]
	xor ah,ah
simple_sc_no_ext:
	clc
	ret
simple_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			caps_scan
;
;		DESCRIPTION:	Handle case sensitive keys
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public caps_scan

caps_scan	PROC near
	mov cx,ds:shift_states
	and cx,107h
	xor cl,ch
	and cx,7
	test cx,4
	jz simple_cap_no_ctrl
	mov cx,4
simple_cap_no_ctrl:
	add bx,cx
	mov ah,cs:[bx]
	or ah,ah
	jne simple_cap_no_ext
	sub bx,cx
	add bx,5
	mov al,cs:[bx]
	xor ah,ah
simple_cap_no_ext:
	clc
	ret
caps_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			num_scan
;
;		DESCRIPTION:	Handle numeric keys
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public num_scan

num_scan	PROC near
	mov cx,ds:shift_states
	and cx,205h
	shr ch,1
	xor cl,ch
	xor ch,ch
	add bx,cx
	cmp cx,1
	jne num_sc_no_num
	mov ah,cs:[bx]
	jmp num_sc_end
num_sc_no_num:
	mov al,cs:[bx]
	xor ah,ah
num_sc_end:
	clc
	ret
num_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			f_key_scan
;
;		DESCRIPTION:	Handle function keys
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public f_key_scan

f_key_scan	PROC near
	test ds:shift_states,ctrl_pressed
	jz f_key_scan_norm
	SetFocus
	stc
	ret
f_key_scan_norm:
	mov cx,ds:shift_states
	and cx,7
	test cx,4
	jz simple_fk_no_ctrl
	mov cx,4
simple_fk_no_ctrl:
	add bx,cx
	mov al,cs:[bx]
	xor ah,ah
	clc
	ret
f_key_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ignore_scan
;
;		DESCRIPTION:	Handle unsupported keys
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ignore_scan	PROC near
	clc
	ret
ignore_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			shift_press_scan
;
;		DESCRIPTION:	Handle Shift pressed
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shift_press_scan	PROC near
	or ds:shift_states,shift_pressed
	clc
	ret
shift_press_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			shift_rel_scan
;
;		DESCRIPTION:	Handle Shift released
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shift_rel_scan	PROC near
	and ds:shift_states,NOT shift_pressed
	clc
	ret
shift_rel_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			alt_press_scan
;
;		DESCRIPTION:	Handle Alt pressed
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alt_press_scan	PROC near
	or ds:shift_states,alt_pressed
	clc
	ret
alt_press_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			alt_rel_scan
;
;		DESCRIPTION:	Handle Alt released
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alt_rel_scan	PROC near
	and ds:shift_states,NOT alt_pressed
	clc
	ret
alt_rel_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ctrl_press_scan
;
;		DESCRIPTION:	Handle Ctrl pressed
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ctrl_press_scan	PROC near
	or ds:shift_states,ctrl_pressed
	clc
	ret
ctrl_press_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ctrl_rel_scan
;
;		DESCRIPTION:	Handle Ctrl released
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ctrl_rel_scan	PROC near
	and ds:shift_states,NOT ctrl_pressed
	clc
	ret
ctrl_rel_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			caps_press_scan
;
;		DESCRIPTION:	Handle Caps Lock
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

caps_press_scan	PROC near
	xor ds:shift_states,caps_active
	mov bx,ds:mode_thread
	Signal
	stc
	ret
caps_press_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			num_press_scan
;
;		DESCRIPTION:	Handle Num Lock
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

num_press_scan	PROC near
	xor ds:shift_states,num_active
	mov bx,ds:mode_thread
	Signal
	stc
	ret
num_press_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			print_press_scan
;
;		DESCRIPTION:	Handle print press
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_press_scan	PROC near
	or ds:shift_states,print_pressed
	clc
	ret
print_press_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			print_rel_scan
;
;		DESCRIPTION:	Handle print released
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_rel_scan	PROC near
	and ds:shift_states,NOT print_pressed
	clc
	ret
print_rel_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			scroll_press_scan
;
;		DESCRIPTION:	Handle scroll press
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

scroll_press_scan	PROC near
	or ds:shift_states,scroll_pressed
	clc
	ret
scroll_press_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			scroll_rel_scan
;
;		DESCRIPTION:	Handle scroll release
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

scroll_rel_scan	PROC near
	and ds:shift_states,NOT scroll_pressed
	clc
	ret
scroll_rel_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			pause_break_press_scan
;
;		DESCRIPTION:	Pause / break press
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pause_break_press_scan	PROC near
	or ds:shift_states,pause_pressed
	clc
	ret
pause_break_press_scan	ENDP

pause_break_rel_scan	PROC near
	and ds:shift_states,NOT pause_pressed
	int 4Ah
	clc
	ret
pause_break_rel_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			f_press_scan
;
;		DESCRIPTION:	Preview function keys
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

f_press_scan	PROC near
	test ds:shift_states,ctrl_pressed
	clc
	jz f_press_scan_done
;
	mov ds:scan_code,al
	mov bx,ds:keyboard_thread
	Signal
	stc

f_press_scan_done:
	ret
f_press_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			f_rel_scan
;
;		DESCRIPTION:	Preview function keys
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

f_rel_scan	PROC near
	test ds:shift_states,ctrl_pressed
	clc
	jz f_rel_scan_done
	stc
f_rel_scan_done:
	ret
f_rel_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendCommand
;
;		DESCRIPTION:	Send a command to keyboard port
;
;		PARAMETERS:		AL		command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TimeoutCommand	Proc far
	mov ax,key_data_sel
	mov ds,ax
	in al,64h
	test al,2
	jnz timeout_command_retry
	mov al,ds:command
	out 60h,al
	jmp timeout_command_done

timeout_command_retry:
	mov ax,cs
	mov es,ax
	GetSystemTime
	add eax,1193*30
	adc edx,0
	mov bx,ds:mode_thread
	mov di,OFFSET TimeoutCommand
	StartTimer

timeout_command_done:
	ret
TimeoutCommand	Endp

SendCommand	proc near
	mov ds:command,al
send_check_ready:
	in al,64h
	test al,2
	jz send_command_do
	mov eax,10
	WaitMilliSec
	jmp send_check_ready

send_command_do:
	cli
	mov al,ds:status
	or al,status_key_req
	and al,NOT status_key_ack
	mov ds:status,al
	sti
	mov ax,cs
	mov es,ax
	GetSystemTime
	add eax,1193*30
	adc edx,0
	mov bx,ds:mode_thread
	mov di,OFFSET TimeoutCommand
	StopTimer
	StartTimer
	mov al,ds:command
	out 60h,al
send_command_wait:
	WaitForSignal
	test ds:status, status_key_ack
	jz send_command_wait
;
	mov bx,ds:mode_thread
	StopTimer
	ret
SendCommand	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendMouseTimeout
;
;		DESCRIPTION:	Send a command timeout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendMouseTimeout	Proc far
	push ds
	push ax
	push bx
;
	mov ax,key_data_sel
	mov ds,ax
	inc ds:mouse_timeout
	mov bx,ds:mouse_thread
	Signal
;
	pop bx
	pop ax
	pop ds
	ret
SendMouseTimeout	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendMouseCommand
;
;		DESCRIPTION:	Send a command to mouse port
;
;		PARAMETERS:		AL		command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendMouseCommand	proc near
	ClearSignal
	pushad
	mov ds:mouse_timeout,0
	mov bx,ds:mouse_thread
	mov ax,cs
	mov es,ax
	GetSystemTime
	add eax,1193*30
	adc edx,0
	mov di,OFFSET SendMouseTimeout
	StartTimer
	popad
;
	mov ds:command,al
send_mouse_check_ready:
	in al,64h
	test al,2
	jz send_mouse_prefix
	mov eax,10
	WaitMilliSec
	jmp send_mouse_check_ready

send_mouse_prefix:
	mov al,0D4h
	out 64h,al

send_mouse_check_prefix:
	in al,64h
	test al,2
	jz send_mouse_command_do
	mov eax,10
	WaitMilliSec
	jmp send_mouse_check_prefix

send_mouse_command_do:
	cli
	mov al,ds:status
	or al,status_mouse_req
	and al,NOT status_mouse_ack
	mov ds:status,al
	sti
	mov al,ds:command
	out 60h,al

send_mouse_command_wait:
	WaitForSignal
	mov al,ds:mouse_timeout
	or al,al
	jnz send_mouse_cmd_fail
;
	test ds:status, status_mouse_ack
	jz send_mouse_command_wait
;
	clc
	jmp send_mouse_cmd_done

send_mouse_cmd_fail:
	stc

send_mouse_cmd_done:
	pushf
	push bx
	mov bx,ds:mouse_thread
	StopTimer
	pop bx
	popf
	ret
SendMouseCommand	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CheckAux
;
;		DESCRIPTION:	Check for AUX (mouse) port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckAux	Proc near
	mov cx,100
check_aux_wait1:
	in al,64h
	test al,2
	jz check_aux_prefix
;
	mov eax,10
	WaitMilliSec
	loop check_aux_wait1
	jmp check_aux_fail

check_aux_prefix:
	mov al,0D3h
	out 64h,al

check_aux_wait2:
	in al,64h
	test al,2
	jz check_aux_command
;
	mov eax,10
	WaitMilliSec
	jmp check_aux_wait2

check_aux_command:
	mov al,0F4h
	out 60h,al
;
	mov cx,10
check_aux_wait3:
	in al,64h
	test al,1
	jz check_aux_delay
;
	mov ah,al
	in al,60h
	test ah,20h
	jz check_aux_fail
;
	cmp al,0F4h
	jne check_aux_fail
;
	clc
	jmp check_aux_done

check_aux_delay:
	mov eax,10
	WaitMilliSec
	loop check_aux_wait3

check_aux_fail:
	stc

check_aux_done:
	ret
CheckAux	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_mouse
;
;		DESCRIPTION:	Init mouse hardware
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mouse_name	DB 'Init Mouse', 0

init_mouse	Proc far
	push ds
	push es
	push ax
	push bx
	push di
;
	mov bx,key_data_sel
	mov ds,bx
	mov ds:mouse_counter,0
	GetThread
	mov ds:mouse_thread,ax
;
	stc
	call CheckAux
	jc init_mouse_done
;
	mov al,12
	mov bx,cs
	mov es,bx
	mov di,OFFSET keyb_int
	RequestPrivateIrqHandler

init_enable_aux_loop:
	in al,64h
	test al,2
	jz init_enable_aux_do
	mov eax,10
	WaitMilliSec
	jmp init_enable_aux_loop

init_enable_aux_do:
	mov al,0A8h
	out 64h,al

init_enable_loop1:
	in al,64h
	test al,2
	jz init_enable_prefix
	mov eax,10
	WaitMilliSec
	jmp init_enable_loop1

init_enable_prefix:
	mov al,60h
	out 64h,al

init_enable_loop2:
	in al,64h
	test al,2
	jz init_enable_do
	mov eax,10
	WaitMilliSec
	jmp init_enable_loop2

init_enable_do:
	mov al,47h
	out 60h,al
	jmp init_mouse_revoke
;
	mov al,0F3h
	call SendMouseCommand
	jc init_mouse_revoke
;
	mov al,100
	call SendMouseCommand
	jc init_mouse_revoke
;
	mov al,0E8h
	call SendMouseCommand
	jc init_mouse_revoke
;
	mov al,3
	call SendMouseCommand
	jc init_mouse_revoke
;
	mov al,0E6h
	call SendMouseCommand
	jc init_mouse_revoke
;
	mov al,0F4h
	call SendMouseCommand
	jc init_mouse_revoke
	jmp init_mouse_done

init_mouse_revoke:
	mov al,60h
	out 64h,al

init_disable_loop2:
	in al,64h
	test al,2
	jz init_disable_do
	mov eax,10
	WaitMilliSec
	jmp init_disable_loop2

init_disable_do:
	mov al,65h
	out 60h,al
;
	mov al,12
	ReleasePrivateIrqHandler

init_mouse_done:
	pop di
	pop bx
	pop ax
	pop es
	pop ds
	ret
init_mouse	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UpdateMode
;
;		DESCRIPTION:	Update mode indicators
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMode	PROC near
	mov al,0EDh
	call SendCommand
;
	mov dx,ds:shift_states
	xor al,al
	test dx,num_active
	jz num_off
	or al,2
num_off:
	test dx,caps_active
	jz caps_off
	or al,4
caps_off:
	call SendCommand
	ret
UpdateMode	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			mode_pr
;
;		DESCRIPTION:	Keyboard LED thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mode_name	DB 'Keyboard LEDs',0

mode_pr:
	sti
	mov ax,key_data_sel
	mov ds,ax
	GetThread
	mov ds:mode_thread,ax
	in al,60h

mode_thread_loop:
	WaitForSignal
	call UpdateMode
	jmp mode_thread_loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			keyboard_pr
;
;		DESCRIPTION:	Keyboard handling thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

keyboard_name	DB 'Keyboard',0

keyboard_pr:
	sti
	mov ax,key_data_sel
	mov ds,ax
	GetThread
	mov ds:keyboard_thread,ax
keyboard_thread_loop:
	WaitForSignal
	mov al,ds:scan_code
	xor bh,bh
	mov bl,al
	shl bx,3
	add bx,OFFSET scan_code_tab
	call word ptr cs:[bx].syntax_call
	jc keyboard_thread_loop
	call put_key_code
	jmp keyboard_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			keyb_int
;
;		DESCRIPTION:	Keyboard and PS/2 mouse hardware int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

preview_scan_code_tab:
p00	DW	OFFSET ignore_scan
p01	DW	OFFSET ignore_scan
p02	DW	OFFSET ignore_scan
p03	DW	OFFSET ignore_scan
p04	DW	OFFSET ignore_scan
p05	DW	OFFSET ignore_scan
p06	DW	OFFSET ignore_scan
p07	DW	OFFSET ignore_scan
p08	DW	OFFSET ignore_scan
p09	DW	OFFSET ignore_scan
p0A	DW	OFFSET ignore_scan
p0B	DW	OFFSET ignore_scan
p0C	DW	OFFSET ignore_scan
p0D	DW	OFFSET ignore_scan
p0E	DW	OFFSET ignore_scan
p0F	DW	OFFSET ignore_scan
p10	DW	OFFSET ignore_scan
p11	DW	OFFSET ignore_scan
p12	DW	OFFSET ignore_scan
p13	DW	OFFSET ignore_scan
p14	DW	OFFSET ignore_scan
p15	DW	OFFSET ignore_scan
p16	DW	OFFSET ignore_scan
p17	DW	OFFSET ignore_scan
p18	DW	OFFSET ignore_scan
p19	DW	OFFSET ignore_scan
p1A	DW	OFFSET ignore_scan
p1B	DW	OFFSET ignore_scan
p1C	DW	OFFSET ignore_scan
p1D	DW	OFFSET ctrl_press_scan
p1E	DW	OFFSET ignore_scan
p1F	DW	OFFSET ignore_scan
p20	DW	OFFSET ignore_scan
p21	DW	OFFSET ignore_scan
p22	DW	OFFSET ignore_scan
p23	DW	OFFSET ignore_scan
p24	DW	OFFSET ignore_scan
p25	DW	OFFSET ignore_scan
p26	DW	OFFSET ignore_scan
p27	DW	OFFSET ignore_scan
p28	DW	OFFSET ignore_scan
p29	DW	OFFSET ignore_scan
p2A	DW	OFFSET shift_press_scan
p2B	DW	OFFSET ignore_scan
p2C	DW	OFFSET ignore_scan
p2D	DW	OFFSET ignore_scan
p2E	DW	OFFSET ignore_scan
p2F	DW	OFFSET ignore_scan
p30	DW	OFFSET ignore_scan
p31	DW	OFFSET ignore_scan
p32	DW	OFFSET ignore_scan
p33	DW	OFFSET ignore_scan
p34	DW	OFFSET ignore_scan
p35	DW	OFFSET ignore_scan
p36	DW	OFFSET shift_press_scan
p37	DW	OFFSET print_press_scan
p38	DW	OFFSET alt_press_scan
p39	DW	OFFSET ignore_scan
p3A	DW	OFFSET caps_press_scan
p3B	DW	OFFSET f_press_scan
p3C	DW	OFFSET f_press_scan
p3D	DW	OFFSET f_press_scan
p3E	DW	OFFSET f_press_scan
p3F	DW	OFFSET f_press_scan
p40	DW	OFFSET f_press_scan
p41	DW	OFFSET f_press_scan
p42	DW	OFFSET f_press_scan
p43	DW	OFFSET f_press_scan
p44	DW	OFFSET f_press_scan
p45	DW	OFFSET num_press_scan
p46	DW	OFFSET scroll_press_scan
p47	DW	OFFSET ignore_scan
p48	DW	OFFSET ignore_scan
p49	DW	OFFSET ignore_scan
p4A	DW	OFFSET ignore_scan
p4B	DW	OFFSET ignore_scan
p4C	DW	OFFSET ignore_scan
p4D	DW	OFFSET ignore_scan
p4E	DW	OFFSET ignore_scan
p4F	DW	OFFSET ignore_scan
p50	DW	OFFSET ignore_scan
p51	DW	OFFSET ignore_scan
p52	DW	OFFSET ignore_scan
p53	DW	OFFSET ignore_scan
p54	DW	OFFSET ignore_scan
p55	DW	OFFSET ignore_scan
p56	DW	OFFSET ignore_scan
p57	DW	OFFSET ignore_scan
p58	DW	OFFSET ignore_scan
p59	DW	OFFSET ignore_scan
p5A	DW	OFFSET ignore_scan
p5B	DW	OFFSET ignore_scan
p5C	DW	OFFSET ignore_scan
p5D	DW	OFFSET ignore_scan
p5E	DW	OFFSET ignore_scan
p5F	DW	OFFSET ignore_scan
p60	DW	OFFSET ignore_scan
p61	DW	OFFSET ignore_scan
p62	DW	OFFSET ignore_scan
p63	DW	OFFSET ignore_scan
p64	DW	OFFSET ignore_scan
p65	DW	OFFSET ignore_scan
p66	DW	OFFSET ignore_scan
p67	DW	OFFSET ignore_scan
p68	DW	OFFSET ignore_scan
p69	DW	OFFSET ignore_scan
p6A	DW	OFFSET ignore_scan
p6B	DW	OFFSET ignore_scan
p6C	DW	OFFSET ignore_scan
p6D	DW	OFFSET ignore_scan
p6E	DW	OFFSET ignore_scan
p6F	DW	OFFSET ignore_scan
p70	DW	OFFSET ignore_scan
p71	DW	OFFSET ignore_scan
p72	DW	OFFSET ignore_scan
p73	DW	OFFSET ignore_scan
p74	DW	OFFSET ignore_scan
p75	DW	OFFSET ignore_scan
p76	DW	OFFSET ignore_scan
p77	DW	OFFSET ignore_scan
p78	DW	OFFSET ignore_scan
p79	DW	OFFSET ignore_scan
p7A	DW	OFFSET ignore_scan
p7B	DW	OFFSET ignore_scan
p7C	DW	OFFSET ignore_scan
p7D	DW	OFFSET ignore_scan
p7E	DW	OFFSET ignore_scan
p7F	DW	OFFSET ignore_scan
p80	DW	OFFSET ignore_scan
p81	DW	OFFSET ignore_scan
p82	DW	OFFSET ignore_scan
p83	DW	OFFSET ignore_scan
p84	DW	OFFSET ignore_scan
p85	DW	OFFSET ignore_scan
p86	DW	OFFSET ignore_scan
p87	DW	OFFSET ignore_scan
p88	DW	OFFSET ignore_scan
p89	DW	OFFSET ignore_scan
p8A	DW	OFFSET ignore_scan
p8B	DW	OFFSET ignore_scan
p8C	DW	OFFSET ignore_scan
p8D	DW	OFFSET ignore_scan
p8E	DW	OFFSET ignore_scan
p8F	DW	OFFSET ignore_scan
p90	DW	OFFSET ignore_scan
p91	DW	OFFSET ignore_scan
p92	DW	OFFSET ignore_scan
p93	DW	OFFSET ignore_scan
p94	DW	OFFSET ignore_scan
p95	DW	OFFSET ignore_scan
p96	DW	OFFSET ignore_scan
p97	DW	OFFSET ignore_scan
p98	DW	OFFSET ignore_scan
p99	DW	OFFSET ignore_scan
p9A	DW	OFFSET ignore_scan
p9B	DW	OFFSET ignore_scan
p9C	DW	OFFSET ignore_scan
p9D	DW	OFFSET ctrl_rel_scan
p9E	DW	OFFSET ignore_scan
p9F	DW	OFFSET ignore_scan
pA0	DW	OFFSET ignore_scan
pA1	DW	OFFSET ignore_scan
pA2	DW	OFFSET ignore_scan
pA3	DW	OFFSET ignore_scan
pA4	DW	OFFSET ignore_scan
pA5	DW	OFFSET ignore_scan
pA6	DW	OFFSET ignore_scan
pA7	DW	OFFSET ignore_scan
pA8	DW	OFFSET ignore_scan
pA9	DW	OFFSET ignore_scan
pAA	DW	OFFSET shift_rel_scan
pAB	DW	OFFSET ignore_scan
pAC	DW	OFFSET ignore_scan
pAD	DW	OFFSET ignore_scan
pAE	DW	OFFSET ignore_scan
pAF	DW	OFFSET ignore_scan
pB0	DW	OFFSET ignore_scan
pB1	DW	OFFSET ignore_scan
pB2	DW	OFFSET ignore_scan
pB3	DW	OFFSET ignore_scan
pB4	DW	OFFSET ignore_scan
pB5	DW	OFFSET ignore_scan
pB6	DW	OFFSET shift_rel_scan
pB7	DW	OFFSET print_rel_scan
pB8	DW	OFFSET alt_rel_scan
pB9	DW	OFFSET ignore_scan
pBA	DW	OFFSET ignore_scan
pBB	DW	OFFSET f_rel_scan
pBC	DW	OFFSET f_rel_scan
pBD	DW	OFFSET f_rel_scan
pBE	DW	OFFSET f_rel_scan
pBF	DW	OFFSET f_rel_scan
pC0	DW	OFFSET f_rel_scan
pC1	DW	OFFSET f_rel_scan
pC2	DW	OFFSET f_rel_scan
pC3	DW	OFFSET f_rel_scan
pC4	DW	OFFSET f_rel_scan
pC5	DW	OFFSET ignore_scan
pC6	DW	OFFSET scroll_rel_scan
pC7	DW	OFFSET ignore_scan
pC8	DW	OFFSET ignore_scan
pC9	DW	OFFSET ignore_scan
pCA	DW	OFFSET ignore_scan
pCB	DW	OFFSET ignore_scan
pCC	DW	OFFSET ignore_scan
pCD	DW	OFFSET ignore_scan
pCE	DW	OFFSET ignore_scan
pCF	DW	OFFSET ignore_scan
pD0	DW	OFFSET ignore_scan
pD1	DW	OFFSET ignore_scan
pD2	DW	OFFSET ignore_scan
pD3	DW	OFFSET ignore_scan
pD4	DW	OFFSET ignore_scan
pD5	DW	OFFSET ignore_scan
pD6	DW	OFFSET ignore_scan
pD7	DW	OFFSET ignore_scan
pD8	DW	OFFSET ignore_scan
pD9	DW	OFFSET ignore_scan
pDA	DW	OFFSET ignore_scan
pDB	DW	OFFSET ignore_scan
pDC	DW	OFFSET ignore_scan
pDD	DW	OFFSET ignore_scan
pDE	DW	OFFSET ignore_scan
pDF	DW	OFFSET ignore_scan
pE0	DW	OFFSET ignore_scan
pE1	DW	OFFSET ignore_scan
pE2	DW	OFFSET ignore_scan
pE3	DW	OFFSET ignore_scan
pE4	DW	OFFSET ignore_scan
pE5	DW	OFFSET ignore_scan
pE6	DW	OFFSET ignore_scan
pE7	DW	OFFSET ignore_scan
pE8	DW	OFFSET ignore_scan
pE9	DW	OFFSET ignore_scan
pEA	DW	OFFSET ignore_scan
pEB	DW	OFFSET ignore_scan
pEC	DW	OFFSET ignore_scan
pED	DW	OFFSET ignore_scan
pEE	DW	OFFSET ignore_scan
pEF	DW	OFFSET ignore_scan
pF0	DW	OFFSET ignore_scan
pF1	DW	OFFSET ignore_scan
pF2	DW	OFFSET ignore_scan
pF3	DW	OFFSET ignore_scan
pF4	DW	OFFSET ignore_scan
pF5	DW	OFFSET ignore_scan
pF6	DW	OFFSET ignore_scan
pF7	DW	OFFSET ignore_scan
pF8	DW	OFFSET ignore_scan
pF9	DW	OFFSET ignore_scan
pFA	DW	OFFSET ignore_scan
pFB	DW	OFFSET ignore_scan
pFC	DW	OFFSET ignore_scan
pFD	DW	OFFSET ignore_scan
pFE	DW	OFFSET ignore_scan
pFF	DW	OFFSET ignore_scan

keyb_int	Proc far
	cld
keyb_int_loop:
	cli
	in al,64h
	test al,1
	jz keyb_int_done
;
	test al,20h
	jz keyb_int_keyboard

keyb_int_mouse:
	in al,60h
	sti
;
	test ds:status,status_mouse_req
	jz mouse_int_not_resend
;
	cmp al,0FAh
	jnz mouse_int_not_ack
;
	cli
	mov al,ds:status
	or al,status_mouse_ack
	and al,NOT status_mouse_req
	mov ds:status,al
	mov bx,ds:mouse_thread
	Signal
	jmp keyb_int_loop

mouse_int_not_ack:
	cmp al,0FEh
	jnz mouse_int_not_resend
;
	mov al,ds:command
	out 60h,al
	jmp keyb_int_loop

mouse_int_not_resend:
	movzx bx,ds:mouse_counter
	mov ds:[bx].mouse_buttons,al
	inc bl
	mov ds:mouse_counter,bl
	cmp bl,3
	jne keyb_int_loop
;
	movzx ax,ds:mouse_buttons
	movzx cx,ds:mouse_dx
	movzx dx,ds:mouse_dy
;
	test al,10h
	clc
	jz mouse_xpos
	stc
mouse_xpos:
	sbb ch,ch
	test al,20h
	clc
	jz mouse_ypos
	stc
mouse_ypos:
	sbb dh,dh
	and al,3
	UpdateMouse
	mov ds:mouse_counter,0
	jmp keyb_int_loop

keyb_int_keyboard:
	in al,60h
	sti
	or al,al
	je keyb_int_loop
;
	test ds:status,status_key_req
	jz keyb_int_not_resend
;
	cmp al,0FAh
	jnz keyb_int_not_ack
;
	cli
	mov al,ds:status
	or al,status_key_ack
	and al,NOT status_key_req
	mov ds:status,al
	mov bx,ds:mode_thread
	Signal
	jmp keyb_int_loop

keyb_int_not_ack:
	cmp al,0FEh
	jnz keyb_int_not_resend
;
	mov al,ds:command
	out 60h,al
	jmp keyb_int_loop

keyb_int_not_resend:
	cmp al,0FFh
	je keyb_int_loop
;
	cmp al,0E0h
	jnz keyb_int_not_numpad
;
	or ds:shift_states,ext_numpad_active
	and ds:shift_states, NOT ext_numpad_handled
	jmp keyb_int_loop	

keyb_int_not_numpad:
	test ds:shift_states,ext_numpad_active
	jz keyb_int_numpad_handled
;
	test ds:shift_states, ext_numpad_handled
	jz keyb_int_numpad_mark_handled
;
	and ds:shift_states, NOT ext_numpad_active
	jmp keyb_int_numpad_handled

keyb_int_numpad_mark_handled:
	or ds:shift_states, ext_numpad_handled

keyb_int_numpad_handled:
	movzx bx,al
	add bx,bx
	call word ptr cs:[bx].preview_scan_code_tab
	jc keyb_int_loop
;
	mov ds:scan_code,al
	mov bx,ds:keyboard_thread
	mov ax,key_focus_sel
	mov ds,ax
	mov ax,ds:key_notify_thread
	or ax,ax
	jz keyb_int_signal
	mov bx,ax
keyb_int_signal:
	Signal

keyb_int_done:
	ret
keyb_int	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Keyboard software int
;
;		DESCRIPTION:	Emulates int 16
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	ds		key_local_sel

keyb_io_read	PROC far
keyb_io_wait:
	cli
	mov bx,ds:key_buffer_head
	cmp bx,ds:key_buffer_tail
	jne keyb_io_get_ch
	sti
	push di
	mov di,OFFSET key_proc_wait
	Sleep
	pop di
	jmp keyb_io_wait
keyb_io_get_ch:
	mov ax,[bx]
	inc bx
	inc bx
	cmp bx,OFFSET key_buffer_end
	jne kr_no_circ_buff
	mov bx,OFFSET key_buffer_start
kr_no_circ_buff:
	mov ds:key_buffer_head,bx
	sti
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	ret
keyb_io_read	ENDP

keyb_io_poll	PROC far
	mov bx,ds:key_buffer_head
	cmp bx,ds:key_buffer_tail
	je keyb_p_empty
	and word ptr [bp].vm_eflags,NOT 40h
	mov ax,[bx]
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	ret
keyb_p_empty:
	or word ptr [bp].vm_eflags,40h
	mov bx,[bp].vm_ebx
	mov ds,[bp].pm_ds
	ret
keyb_io_poll	ENDP

keyb_io_state	PROC far
	xor ax,ax
	mov ds,[bp].pm_ds
	ret
keyb_io_state	ENDP

keyb_error:
	int 3
	mov ds,[bp].pm_ds
	ReflectPmToVm

keyb_write	PROC far
	mov al,1
	mov ds,[bp].pm_ds
	ret
keyb_write	ENDP

keyb_io_tab:
k00		DW OFFSET keyb_io_read
k01		DW OFFSET keyb_io_poll
k02		DW OFFSET keyb_io_state
k03		DW OFFSET keyb_error
k04		DW OFFSET keyb_error
k05		DW OFFSET keyb_write
k06		DW OFFSET keyb_error
k07		DW OFFSET keyb_error
k08		DW OFFSET keyb_error
k09		DW OFFSET keyb_error
k0A		DW OFFSET keyb_error
k0B		DW OFFSET keyb_error
k0C		DW OFFSET keyb_error
k0D		DW OFFSET keyb_error
k0E		DW OFFSET keyb_error
k0F		DW OFFSET keyb_error
k10		DW OFFSET keyb_io_read
k11		DW OFFSET keyb_io_poll
k12		DW OFFSET keyb_io_state
k13		DW OFFSET keyb_error

int16:
	SimSti
	mov bx,key_local_sel
	mov ds,bx
	mov bl,ah
	xor bh,bh
	add bx,bx
	cmp bx,26h
	jc key_call_do
	mov bx,26h
key_call_do:
	push word ptr cs:[bx].keyb_io_tab
	mov bx,[bp].vm_ebx
	retn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			PollKeyboardSerial
;
;		DESCRIPTION:	Fix for DOS
;
;		PARAMETERS:		NC		Char available
;						CY		Buffer empty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_keyboard_serial_name	DB 'Poll Keyboard Serial',0

poll_keyboard_serial	PROC far
	push ds
	push ax
	sti
	mov ax,key_local_sel
	mov ds,ax
	mov al,ds:extend_key
	or al,al
	clc
	jnz poll_key_serial_end
	PollKeyboard
poll_key_serial_end:
	pop ax
	pop ds
	ret
poll_keyboard_serial	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadKeyboardSerial
;
;		DESCRIPTION:	Special fix for DOS
;
;		PARAMETERS:		AL			Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_keyboard_serial_name	DB 'Read Keyboard Serial',0

read_keyboard_serial	PROC far
	push ds
	push bx
	sti
	mov bx,key_local_sel
	mov ds,bx
	mov al,ds:extend_key
	or al,al
	jz key_serial_wait
	mov ds:extend_key,0
	jmp key_serial_end
key_serial_wait:
	ReadKeyboard
	or al,al
	jnz key_serial_end
	mov ds:extend_key,ah
key_serial_end:
	pop bx
	pop ds
	ret
read_keyboard_serial	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			PollKeyboard
;
;		DESCRIPTION:	Poll keyboard
;
;		PARAMETERS:		NC		Char available
;						CY		Buffer empty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_keyboard_name	DB 'Poll Keyboard',0

poll_keyboard	PROC far
	push ds
	push bx
	sti
	mov bx,key_local_sel
	mov ds,bx
	mov bx,ds:key_buffer_head
	cmp bx,ds:key_buffer_tail
	je poll_key_empty
poll_key_avail:
	clc
	pop bx
	pop ds
	retf32
poll_key_empty:
	stc
	pop bx
	pop ds
	retf32
poll_keyboard	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadKeyboard
;
;		DESCRIPTION:	Read a char from keyboard
;
;		RETURNS:		AX			Char read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_keyboard_name	DB 'Read Keyboard',0

read_keyboard	PROC far
	push ds
	push bx
	sti
	mov bx,key_local_sel
	mov ds,bx
read_key_wait:
	cli
	mov bx,ds:key_buffer_head
	cmp bx,ds:key_buffer_tail
	jne read_key_get
	sti
	push di
	mov di,OFFSET key_proc_wait
	Sleep
	pop di
	jmp read_key_wait
read_key_get:
	mov ax,[bx]
	inc bx
	inc bx
	cmp bx,OFFSET key_buffer_end
	jne read_key_no_circ_buff
	mov bx,OFFSET key_buffer_start
read_key_no_circ_buff:
	mov ds:key_buffer_head,bx
	sti
	pop bx
	pop ds
	retf32
read_keyboard	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FlushKeyboard
;
;		DESCRIPTION:	Flush keyboard buffer
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_keyboard_name	DB 'Flush Keyboard',0

flush_keyboard	PROC far
	push ds
	push bx
	mov bx,key_local_sel
	mov ds,bx
	cli
	mov bx,ds:key_buffer_head
	mov ds:key_buffer_tail,bx
	sti
	pop bx
	pop ds
	retf32
flush_keyboard	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetKeyboardState
;
;		DESCRIPTION:	Get state of keyboard
;
;		RETURNS:		AX		Keyboard state		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_keyboard_state_name	DB 'Get Keyboard State',0

get_keyboard_state	PROC far
	push ds
	push bx
	mov bx,key_local_sel
	mov ds,bx
	mov ax,ds:shift_states
	pop bx
	pop ds
	retf32
get_keyboard_state	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Keyboard callback thread
;
;		DESCRIPTION:	Implements the keyboard hooks
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_thread_name	DB 'Keyboard Hook',0

virtual_key_code_tab:

v00	DB	0,		0
v01	DB	1Bh,	1Bh
v02	DB	'1',	'1'
v03	DB	'2',	'2'
v04	DB	'3',	'3'
v05	DB	'4',	'4'
v06	DB	'5',	'5'
v07	DB	'6',	'6'
v08	DB	'7',	'7'
v09	DB	'8',	'8'
v0A	DB	'9',	'9'
v0B	DB	'0',	'0'
v0C	DB	0B8h,	0B8h
v0D	DB	0DBh,	0DBh
v0E	DB	8,		8
v0F	DB	9,		9
v10	DB	'Q',	'Q'
v11	DB	'W',	'W'
v12	DB	'E',	'E'
v13	DB	'R',	'R'
v14	DB	'T',	'T'
v15	DB	'Y',	'Y'
v16	DB	'U',	'U'
v17	DB	'I',	'I'
v18	DB	'O',	'O'
v19	DB	'P',	'P'
v1A	DB	0DDh,	0DDh
v1B	DB	0BAh,	0BAh
v1C	DB	0Dh,	0Dh
v1D	DB	11h,	11h
v1E	DB	'A',	'A'
v1F	DB	'S',	'S'
v20	DB	'D',	'D'
v21	DB	'F',	'F'
v22	DB	'G',	'G'
v23	DB	'H',	'H'
v24	DB	'J',	'J'
v25	DB	'K',	'K'
v26	DB	'L',	'L'
v27	DB	0C0h,	0C0h
v28	DB	0DEh,	0DEh
v29	DB	0BFh,	0BFh
v2A	DB	10h,	10h
v2B	DB	0E2h,	0E2h
v2C	DB	'Z',	'Z'
v2D	DB	'X',	'X'
v2E	DB	'C',	'C'
v2F	DB	'V',	'V'
v30	DB	'B',	'B'
v31	DB	'N',	'N'
v32	DB	'M',	'M'
v33	DB	0BCh,	0BCh
v34	DB	0BEh,	0BEh
v35	DB	0BDh,	0BDh
v36	DB	10h,	10h
v37	DB	2Ch,	2Ch
v38	DB	12h,	12h
v39	DB	20h,	20h
v3A	DB	14h,	14h
v3B	DB	70h,	70h
v3C	DB	71h,	71h
v3D	DB	72h,	72h
v3E	DB	73h,	73h
v3F	DB	74h,	74h
v40	DB	75h,	75h
v41	DB	76h,	76h
v42	DB	77h,	77h
v43	DB	78h,	78h
v44	DB	79h,	79h
v45	DB	90h,	90h
v46	DB	91h,	91h
v47	DB	67h,	24h
v48	DB	68h,	26h
v49	DB	69h,	21h
v4A	DB	6Dh,	6Dh
v4B	DB	64h,	25h
v4C	DB	65h,	65h
v4D	DB	66h,	27h
v4E	DB	6Bh,	6Bh
v4F	DB	61h,	23h
v50	DB	62h,	28h
v51	DB	63h,	22h
v52	DB	60h,	2Dh
v53	DB	6Ch,	2Eh
v54	DB	6Eh,	6Eh
v55	DB	0,		0
v56	DB	0,		0
v57	DB	7Ah,	7Ah
v58	DB	7Bh,	7Bh
v59	DB	0,		0
v5A	DB	0,		0
v5B	DB	0,		0
v5C	DB	0,		0
v5D	DB	0,		0
v5E	DB	0,		0
v5F	DB	0,		0
v60	DB	0,		0
v61	DB	0,		0
v62	DB	0,		0
v63	DB	0,		0
v64	DB	0,		0
v65	DB	0,		0
v66	DB	0,		0
v67	DB	0,		0
v68	DB	0,		0
v69	DB	0,		0
v6A	DB	0,		0
v6B	DB	0,		0
v6C	DB	0,		0
v6D	DB	0,		0
v6E	DB	0,		0
v6F	DB	0,		0
v70	DB	0,		0
v71	DB	0,		0
v72	DB	0,		0
v73	DB	0,		0
v74	DB	0,		0
v75	DB	0,		0
v76	DB	0,		0
v77	DB	0,		0
v78	DB	0,		0
v79	DB	0,		0
v7A	DB	0,		0
v7B	DB	0,		0
v7C	DB	0,		0
v7D	DB	0,		0
v7E	DB	0,		0
v7F	DB	0,		0

hook_thread	Proc far
	mov ax,key_local_sel
	mov ds,ax
	GetThread
	mov ds:key_notify_thread,ax

hook_thread_loop:
	mov ax,key_data_sel
	mov ds,ax
	mov ax,key_local_sel
	mov es,ax
;
	WaitForSignal
	GetThread
	cmp ax,es:key_notify_thread
	jne hook_thread_end	
;
	movzx ax,ds:scan_code
	push ax
	mov dl,al
	xor bh,bh
	mov bl,al
	and bl,7Fh
	shl bx,3
	add bx,OFFSET scan_code_tab
	call word ptr cs:[bx].syntax_call
	jnc hook_thread_scan_ok
	xor ax,ax
hook_thread_scan_ok:
	mov al,ah
	mov ah,dl
	pop bx
;
	add bx,bx
	mov cx,ds:shift_states
	test cx,ext_numpad_active
	jz hook_thread_get_vk
	inc bx
hook_thread_get_vk:
	xor bh,bh
	movzx dx,byte ptr cs:[bx].virtual_key_code_tab
	push es:key_notify_offs
	CallPm32
	jmp hook_thread_loop

hook_thread_end:
	ret
hook_thread	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HookKeyboard
;
;		DESCRIPTION:	Create a keyboard callback
;
;		PARAMETERS:		ES:(E)DI	Callback
;							AX		Scan code
;							DX		Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_keyboard_name	DB 'Hook Keyboard',0

hook_keyboard	PROC near
	push ds
	push es
	push ax
	push bx
	push si
	push di
;
	mov bx,key_local_sel
	mov ds,bx
	mov ax,ds:key_notify_thread
	or ax,ax
	jz hook_keyb_do
	UnhookKeyboard

hook_keyb_do:
	mov ds:key_notify_sel,es
	mov ds:key_notify_offs,edi
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET hook_thread
	mov di,OFFSET hook_thread_name
	mov cx,100h
	mov ax,3
	CreateThread
;
	pop di
	pop si
	pop bx
	pop ax
	pop es
	pop ds
	ret
hook_keyboard	ENDP

hook_keyboard16	Proc far
	push edi
	movzx edi,di
	call hook_keyboard
	pop edi
	ret
hook_keyboard16	Endp

hook_keyboard32	Proc far
	call hook_keyboard
	retf32
hook_keyboard32	Endp	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UnhookKeyboard
;
;		DESCRIPTION:	Delete a keyboard callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unhook_keyboard_name	DB 'Unhook Keyboard',0

unhook_keyboard	PROC near
	push ds
	push bx
;
	mov bx,key_local_sel
	mov ds,bx
	xor bx,bx
	xchg bx,ds:key_notify_thread
	Signal
;
	pop bx
	pop ds
	retf32
unhook_keyboard	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			KEYBOARD EMULATOR FOR BAD DOS APPS
;
;		DESCRIPTION:	EMULATES KEYBOARD TO ILL BEHAVED DOS APPS
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

keyboard_emul_name	DB 'Keyboard Emulator',0

keyboard_emul_pr:
	mov ax,key_local_sel
	mov ds,ax
	GetThread
	mov ds:key_emul_thread,ax
	mov eax,110h
	AllocateVMLinear
	add edx,10h
	shr edx,4
; gs
	push 0
	push 0F000h
; fs
	push 0
	push 0F000h
; ds
	push 0
	push 0F000h
; es
	push 0
	push 0F000h
; ss
	push edx
; esp
	push 0
	push 0FAh
; eflags
	push 2
	push 200h
; cs
	push 0
	push 0
; eip
	push 0
	push 0
;
	sub sp,4
	push bp
	mov bp,sp
	push eax
	push ebx
	push ds
	sub sp,6
key_emul_loop:
	mov ax,key_local_sel
	mov ds,ax
	GetThread
	cmp ds:key_int_seg,0E000h
	jnz key_wait_loop
	mov ds:key_emul_thread,0
	TerminateThread
key_wait_loop:
	WaitForSignal
;
	mov ax,ds:key_int_seg
	cmp ax,0E000h
	jnz key_emul_start
	PutKeyInBuffer
	jmp key_emul_loop
key_emul_start:
	int 3
	mov [bp].vm_cs,ax
	mov ax,ds:key_int_offs
	mov [bp].vm_eip,ax
;
	mov ax,flat_sel
	mov ds,ax
	movzx edx,word ptr [bp].vm_ss
	shl edx,4
	mov word ptr [edx+0FAh],8*4
	mov word ptr [edx+0FCh],0E000h
	mov word ptr [edx+0FEh],200h
	mov word ptr [bp].vm_esp,0FAh
	add sp,6
	pop ds
	pop ebx
	pop eax
	pop bp
	add sp,4
	iretd
;
	jmp key_emul_loop

check_key_state	PROC near
	cli
	cmp ds:key_int_seg,0E000h
	je check_key_done
	cmp ds:key_emul_thread,0
	jne check_key_done
	sti
	dec ds:key_emul_thread
	push ds
	push es
	pusha
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET keyboard_emul_pr
	mov di,OFFSET keyboard_emul_name
	mov cx,100h
	mov ax,3
	CreateThread
	popa
	pop es
	pop ds
check_key_done:
	sti
	ret
check_key_state	ENDP

get_vm_key	PROC far
	mov bx,key_local_sel
	mov ds,bx
	mov bx,ds:key_int_offs
	mov dx,ds:key_int_seg
	ret
get_vm_key	ENDP

set_vm_key	PROC far
	push ax
	mov ax,key_local_sel
	mov ds,ax
	pop ax
	mov ds:key_int_offs,bx
	mov ds:key_int_seg,dx
	call check_key_state
	ret
set_vm_key	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CHECK_LIST
;
;		DESCRIPTION:	Check if thread is in a keyboard list
;
;		PARAMETERS:		BX:EAX   	address of list
;						CX:EDX   	cs:eip
;						BX:EAX   	returned data to write
;						ES:EDI   	state string
;						NC	    	processed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Key_state DB 'Keyboard',0

check_list	Proc far
	cmp bx,key_local_sel
	jne check_not_local
	mov ax,cs
	mov es,ax
	mov edi,OFFSET Key_state
	xor bx,bx
	xor eax,eax
	clc
	ret
check_not_local:
	stc
	ret
check_list	Endp

init_local_sel	PROC far
	mov ax,key_local_sel
	mov ds,ax
	mov ax,OFFSET key_buffer_start
	mov ds:key_buffer_head,ax
	mov ds:key_buffer_tail,ax
	mov ds:key_proc_wait,0
	mov ds:key_notify_thread,0
	mov ds:key_emul_thread,0
	mov ds:key_int_seg,0E000h
	mov ds:key_int_offs,9*4
	ret
init_local_sel	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			get_status1
;
;		DESCRIPTION:	Get keyboard status 1
;
;		RETURNS:		AL	status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_status1	Proc far
	push ds
	push bx
	mov ax,key_data_sel
	mov ds,ax
	mov bx,ds:shift_states
	xor al,al
	test bx,shift_pressed
	jz get1_not_shift
;
	or al,1

get1_not_shift:
	test bx,ctrl_pressed
	jz get1_not_ctrl
;
	or al,4

get1_not_ctrl:
	test bx,alt_pressed
	jz get1_not_alt
;
	or al,8

get1_not_alt:
	test bx,num_active
	jz get1_not_num
;
	or al,20h	

get1_not_num:
	test bx,caps_active
	jz get1_not_caps
;
	or al,40h

get1_not_caps:	
	pop bx
	pop ds
	ret
get_status1	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			get_status2
;
;		DESCRIPTION:	Get keyboard status 2
;
;		RETURNS:		AL	status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_status2	Proc far
	push ds
	push bx
	mov ax,key_data_sel
	mov ds,ax
	mov bx,ds:shift_states
	xor al,al
;
	test bx,print_pressed
	jz get2_not_print
;
	or al,4

get2_not_print:
	test bx,scroll_pressed
	jz get2_not_scroll
;
	or al,10h

get2_not_scroll:
	pop bx
	pop ds
	ret
get_status2	Endp

init_keyb_thread	PROC far
	push ds
	push es
	pusha
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET keyboard_pr
	mov di,OFFSET keyboard_name
	mov cx,500
	mov ax,4
	CreateThread
;
	mov si,OFFSET mode_pr
	mov di,OFFSET mode_name
	mov cx,500
	mov ax,4
	CreateThread
;
	mov bx,key_data_sel
	mov ds,bx
	mov al,1
	mov bx,cs
	mov es,bx
	mov di,OFFSET keyb_int
	RequestPrivateIrqHandler
;
	popa
	pop es
	pop ds
	ret
init_keyb_thread	ENDP

init	PROC far
	push ds
	push es
	pusha
	mov bx,key_code_sel
	InitDevice
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET init_keyb_thread
	HookInitTasking
;
	mov di,OFFSET init_local_sel
	HookEnableFocus
;
	mov di,OFFSET get_vm_key
	mov al,9
	HookGetVMInt
;
	mov di,OFFSET set_vm_key
	mov al,9
	HookSetVMInt
;
	mov di,OFFSET get_status1
	mov bx,17h
	HookGetBiosData
;
	mov di,OFFSET get_status2
	mov bx,18h
	HookGetBiosData
;
	mov bx,key_local_sel
	mov dx,key_focus_sel
	mov eax,SIZE key_proc_seg
	AllocateFixedFocusMem
;
	mov bx,key_data_sel
	mov eax,SIZE key_data_seg
	AllocateFixedSystemMem
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET check_list
	HookState
;
	mov si,OFFSET read_keyboard
	mov di,OFFSET read_keyboard_name
	xor dx,dx
	mov ax,read_keyboard_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET poll_keyboard
	mov di,OFFSET poll_keyboard_name
	xor dx,dx
	mov ax,poll_keyboard_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET flush_keyboard
	mov di,OFFSET flush_keyboard_name
	xor dx,dx
	mov ax,flush_keyboard_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_keyboard_state
	mov di,OFFSET get_keyboard_state_name
	xor dx,dx
	mov ax,get_keyboard_state_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET hook_keyboard16
	mov si,OFFSET hook_keyboard32
	mov di,OFFSET hook_keyboard_name
	xor dx,dx
	mov ax,hook_keyboard_nr
	RegisterUserGate
;
	mov si,OFFSET unhook_keyboard
	mov di,OFFSET unhook_keyboard_name
	xor dx,dx
	mov ax,unhook_keyboard_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET read_keyboard_serial
	mov di,OFFSET read_keyboard_serial_name
	xor cl,cl
	mov ax,read_keyboard_serial_nr
	RegisterOsGate
;
	mov si,OFFSET poll_keyboard_serial
	mov di,OFFSET poll_keyboard_serial_name
	xor cl,cl
	mov ax,poll_keyboard_serial_nr
	RegisterOsGate
;
	mov si,OFFSET init_mouse
	mov di,OFFSET init_mouse_name
	xor cl,cl
	mov ax,init_mouse_nr
	RegisterOsGate
;
	mov ax,key_data_sel
	mov ds,ax
	xor ax,ax
	mov ds:shift_states,ax
	mov ds:mode_thread,ax
	mov ds:mouse_thread,ax
	mov ds:keyboard_thread,ax
	mov ds:status,0
;
	mov ax,cs
	mov ds,ax
	mov al,16h
	mov di,OFFSET int16
	HookVMInt
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init
