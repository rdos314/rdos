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

        NO_MOUSE = 0


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

key_data_seg	STRUC

mode_thread		DW ?
mouse_thread	DW ?
command			DB ?
status			DB ?
focus_req       DB ?

mouse_timeout	DB ?
mouse_counter	DB ?
mouse_buttons	DB ?
mouse_dx		DB ?
mouse_dy		DB ?

key_data_seg	ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn scan_code_tab:near

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
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
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
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
	and cx,7
	test cx,4
	jz simple_sc_no_ctrl
;
	mov cx,4
	
simple_sc_no_ctrl:
	add bx,cx
	mov ah,cs:[bx]
	or ah,ah
	jne simple_sc_no_ext
;
	sub bx,cx
	movzx ax,byte ptr cs:[bx+5]
	
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
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
	and cx,107h
	xor cl,ch
	and cx,7
	test cx,4
	jz simple_cap_no_ctrl
;	
	mov cx,4

simple_cap_no_ctrl:
	add bx,cx
	mov ah,cs:[bx]
	or ah,ah
	jne simple_cap_no_ext
;
	sub bx,cx
	movzx ax,byte ptr cs:[bx+5]

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
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
	and cx,205h
	shr ch,1
	xor cl,ch
	xor ch,ch
	add bx,cx
	cmp cx,1
	jne num_sc_no_num
;
	mov ah,cs:[bx]
	jmp num_sc_end
	
num_sc_no_num:
	movzx ax,byte ptr cs:[bx]

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
	and cx,7
	test cx,4
	jz simple_fk_no_ctrl
;
	mov cx,4

simple_fk_no_ctrl:
	add bx,cx
	movzx ax,byte ptr cs:[bx]
	clc
	ret
f_key_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			default_scan
;
;		DESCRIPTION:	Default scan code handler
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

default_scan	PROC near
    movzx bx,al
    mov dh,al
    push bx
	shl bx,3
	add bx,OFFSET scan_code_tab
	call word ptr cs:[bx].syntax_call
	pop bx
	jc default_scan_done
;
	add bx,bx
	push ax
	GetKeyboardState
	mov cx,ax
	pop ax
	test cx,ext_numpad_active
	jz default_scan_get_vk
;
	inc bx
	
default_scan_get_vk:
	xor bh,bh
	mov dl,byte ptr cs:[bx].virtual_key_code_tab
    PutKeyboardCode

default_scan_done:
	ret
default_scan	ENDP

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
    push ax
    GetKeyboardState
	or ax,shift_pressed
	SetKeyboardState
	pop ax
;
    call default_scan
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
    push ax
    GetKeyboardState
	and ax,NOT shift_pressed
	SetKeyboardState
	pop ax
;
    call default_scan
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
    push ax
    GetKeyboardState
	or ax,alt_pressed
	SetKeyboardState
	pop ax
;
    call default_scan
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
    push ax
    GetKeyboardState
	and ax,NOT alt_pressed
	SetKeyboardState
	pop ax
;
    call default_scan
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
    push ax
    GetKeyboardState
	or ax,ctrl_pressed
	SetKeyboardState
	pop ax
;
    call default_scan
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
    push ax
    GetKeyboardState
	and ax,NOT ctrl_pressed
	SetKeyboardState
	pop ax
;
    call default_scan
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
    push ax
    GetKeyboardState
	xor ax,caps_active
	SetKeyboardState
	pop ax
;
	mov bx,ds:mode_thread
	Signal
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
    push ax
    GetKeyboardState
	xor ax,num_active
	SetKeyboardState
	pop ax
;
	mov bx,ds:mode_thread
	Signal
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
    push ax
    GetKeyboardState
	or ax,print_pressed
	SetKeyboardState
	pop ax
;
    call default_scan
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
    push ax
    GetKeyboardState
	and ax,NOT print_pressed
	SetKeyboardState
	pop ax
;
    call default_scan
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
    push ax
    GetKeyboardState
	or ax,scroll_pressed
	SetKeyboardState
	pop ax
;
    call default_scan
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
    push ax
    GetKeyboardState
	and ax,NOT scroll_pressed
	SetKeyboardState
	pop ax
;
    call default_scan
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
    push ax
    GetKeyboardState
	or ax,pause_pressed
	SetKeyboardState
	pop ax
;
    call default_scan
	ret
pause_break_press_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			pause_break_rel_scan
;
;		DESCRIPTION:	Pause / break rel
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pause_break_rel_scan	PROC near
    push ax
    GetKeyboardState
	and ax,NOT pause_pressed
	SetKeyboardState
	pop ax
	int 4Ah
;
    call default_scan
	ret
pause_break_rel_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			f_press_scan
;
;		DESCRIPTION:	Function key press scan
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

f_press_scan	PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
	test cx,ctrl_pressed
	jz f_press_norm
;
    mov ds:focus_req,al
	mov bx,ds:mode_thread
	Signal
    ret

f_press_norm:
    call default_scan
    ret
f_press_scan    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			f_rel_scan
;
;		DESCRIPTION:	Function key release scan
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

f_rel_scan	PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
	test cx,ctrl_pressed
	jz f_rel_norm
;
    ret

f_rel_norm:
    call default_scan
    ret
f_rel_scan    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			handle_scan_code_tab
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_scan_code_tab:
p00	DW	OFFSET default_scan
p01	DW	OFFSET default_scan
p02	DW	OFFSET default_scan
p03	DW	OFFSET default_scan
p04	DW	OFFSET default_scan
p05	DW	OFFSET default_scan
p06	DW	OFFSET default_scan
p07	DW	OFFSET default_scan
p08	DW	OFFSET default_scan
p09	DW	OFFSET default_scan
p0A	DW	OFFSET default_scan
p0B	DW	OFFSET default_scan
p0C	DW	OFFSET default_scan
p0D	DW	OFFSET default_scan
p0E	DW	OFFSET default_scan
p0F	DW	OFFSET default_scan
p10	DW	OFFSET default_scan
p11	DW	OFFSET default_scan
p12	DW	OFFSET default_scan
p13	DW	OFFSET default_scan
p14	DW	OFFSET default_scan
p15	DW	OFFSET default_scan
p16	DW	OFFSET default_scan
p17	DW	OFFSET default_scan
p18	DW	OFFSET default_scan
p19	DW	OFFSET default_scan
p1A	DW	OFFSET default_scan
p1B	DW	OFFSET default_scan
p1C	DW	OFFSET default_scan
p1D	DW	OFFSET ctrl_press_scan
p1E	DW	OFFSET default_scan
p1F	DW	OFFSET default_scan
p20	DW	OFFSET default_scan
p21	DW	OFFSET default_scan
p22	DW	OFFSET default_scan
p23	DW	OFFSET default_scan
p24	DW	OFFSET default_scan
p25	DW	OFFSET default_scan
p26	DW	OFFSET default_scan
p27	DW	OFFSET default_scan
p28	DW	OFFSET default_scan
p29	DW	OFFSET default_scan
p2A	DW	OFFSET shift_press_scan
p2B	DW	OFFSET default_scan
p2C	DW	OFFSET default_scan
p2D	DW	OFFSET default_scan
p2E	DW	OFFSET default_scan
p2F	DW	OFFSET default_scan
p30	DW	OFFSET default_scan
p31	DW	OFFSET default_scan
p32	DW	OFFSET default_scan
p33	DW	OFFSET default_scan
p34	DW	OFFSET default_scan
p35	DW	OFFSET default_scan
p36	DW	OFFSET shift_press_scan
p37	DW	OFFSET print_press_scan
p38	DW	OFFSET alt_press_scan
p39	DW	OFFSET default_scan
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
p47	DW	OFFSET default_scan
p48	DW	OFFSET default_scan
p49	DW	OFFSET default_scan
p4A	DW	OFFSET default_scan
p4B	DW	OFFSET default_scan
p4C	DW	OFFSET default_scan
p4D	DW	OFFSET default_scan
p4E	DW	OFFSET default_scan
p4F	DW	OFFSET default_scan
p50	DW	OFFSET default_scan
p51	DW	OFFSET default_scan
p52	DW	OFFSET default_scan
p53	DW	OFFSET default_scan
p54	DW	OFFSET default_scan
p55	DW	OFFSET default_scan
p56	DW	OFFSET default_scan
p57	DW	OFFSET default_scan
p58	DW	OFFSET default_scan
p59	DW	OFFSET default_scan
p5A	DW	OFFSET default_scan
p5B	DW	OFFSET default_scan
p5C	DW	OFFSET default_scan
p5D	DW	OFFSET default_scan
p5E	DW	OFFSET default_scan
p5F	DW	OFFSET default_scan
p60	DW	OFFSET default_scan
p61	DW	OFFSET default_scan
p62	DW	OFFSET default_scan
p63	DW	OFFSET default_scan
p64	DW	OFFSET default_scan
p65	DW	OFFSET default_scan
p66	DW	OFFSET default_scan
p67	DW	OFFSET default_scan
p68	DW	OFFSET default_scan
p69	DW	OFFSET default_scan
p6A	DW	OFFSET default_scan
p6B	DW	OFFSET default_scan
p6C	DW	OFFSET default_scan
p6D	DW	OFFSET default_scan
p6E	DW	OFFSET default_scan
p6F	DW	OFFSET default_scan
p70	DW	OFFSET default_scan
p71	DW	OFFSET default_scan
p72	DW	OFFSET default_scan
p73	DW	OFFSET default_scan
p74	DW	OFFSET default_scan
p75	DW	OFFSET default_scan
p76	DW	OFFSET default_scan
p77	DW	OFFSET default_scan
p78	DW	OFFSET default_scan
p79	DW	OFFSET default_scan
p7A	DW	OFFSET default_scan
p7B	DW	OFFSET default_scan
p7C	DW	OFFSET default_scan
p7D	DW	OFFSET default_scan
p7E	DW	OFFSET default_scan
p7F	DW	OFFSET default_scan
p80	DW	OFFSET default_scan
p81	DW	OFFSET default_scan
p82	DW	OFFSET default_scan
p83	DW	OFFSET default_scan
p84	DW	OFFSET default_scan
p85	DW	OFFSET default_scan
p86	DW	OFFSET default_scan
p87	DW	OFFSET default_scan
p88	DW	OFFSET default_scan
p89	DW	OFFSET default_scan
p8A	DW	OFFSET default_scan
p8B	DW	OFFSET default_scan
p8C	DW	OFFSET default_scan
p8D	DW	OFFSET default_scan
p8E	DW	OFFSET default_scan
p8F	DW	OFFSET default_scan
p90	DW	OFFSET default_scan
p91	DW	OFFSET default_scan
p92	DW	OFFSET default_scan
p93	DW	OFFSET default_scan
p94	DW	OFFSET default_scan
p95	DW	OFFSET default_scan
p96	DW	OFFSET default_scan
p97	DW	OFFSET default_scan
p98	DW	OFFSET default_scan
p99	DW	OFFSET default_scan
p9A	DW	OFFSET default_scan
p9B	DW	OFFSET default_scan
p9C	DW	OFFSET default_scan
p9D	DW	OFFSET ctrl_rel_scan
p9E	DW	OFFSET default_scan
p9F	DW	OFFSET default_scan
pA0	DW	OFFSET default_scan
pA1	DW	OFFSET default_scan
pA2	DW	OFFSET default_scan
pA3	DW	OFFSET default_scan
pA4	DW	OFFSET default_scan
pA5	DW	OFFSET default_scan
pA6	DW	OFFSET default_scan
pA7	DW	OFFSET default_scan
pA8	DW	OFFSET default_scan
pA9	DW	OFFSET default_scan
pAA	DW	OFFSET shift_rel_scan
pAB	DW	OFFSET default_scan
pAC	DW	OFFSET default_scan
pAD	DW	OFFSET default_scan
pAE	DW	OFFSET default_scan
pAF	DW	OFFSET default_scan
pB0	DW	OFFSET default_scan
pB1	DW	OFFSET default_scan
pB2	DW	OFFSET default_scan
pB3	DW	OFFSET default_scan
pB4	DW	OFFSET default_scan
pB5	DW	OFFSET default_scan
pB6	DW	OFFSET shift_rel_scan
pB7	DW	OFFSET print_rel_scan
pB8	DW	OFFSET alt_rel_scan
pB9	DW	OFFSET default_scan
pBA	DW	OFFSET default_scan
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
pC5	DW	OFFSET f_rel_scan
pC6	DW	OFFSET scroll_rel_scan
pC7	DW	OFFSET default_scan
pC8	DW	OFFSET default_scan
pC9	DW	OFFSET default_scan
pCA	DW	OFFSET default_scan
pCB	DW	OFFSET default_scan
pCC	DW	OFFSET default_scan
pCD	DW	OFFSET default_scan
pCE	DW	OFFSET default_scan
pCF	DW	OFFSET default_scan
pD0	DW	OFFSET default_scan
pD1	DW	OFFSET default_scan
pD2	DW	OFFSET default_scan
pD3	DW	OFFSET default_scan
pD4	DW	OFFSET default_scan
pD5	DW	OFFSET default_scan
pD6	DW	OFFSET default_scan
pD7	DW	OFFSET default_scan
pD8	DW	OFFSET default_scan
pD9	DW	OFFSET default_scan
pDA	DW	OFFSET default_scan
pDB	DW	OFFSET default_scan
pDC	DW	OFFSET default_scan
pDD	DW	OFFSET default_scan
pDE	DW	OFFSET default_scan
pDF	DW	OFFSET default_scan
pE0	DW	OFFSET default_scan
pE1	DW	OFFSET default_scan
pE2	DW	OFFSET default_scan
pE3	DW	OFFSET default_scan
pE4	DW	OFFSET default_scan
pE5	DW	OFFSET default_scan
pE6	DW	OFFSET default_scan
pE7	DW	OFFSET default_scan
pE8	DW	OFFSET default_scan
pE9	DW	OFFSET default_scan
pEA	DW	OFFSET default_scan
pEB	DW	OFFSET default_scan
pEC	DW	OFFSET default_scan
pED	DW	OFFSET default_scan
pEE	DW	OFFSET default_scan
pEF	DW	OFFSET default_scan
pF0	DW	OFFSET default_scan
pF1	DW	OFFSET default_scan
pF2	DW	OFFSET default_scan
pF3	DW	OFFSET default_scan
pF4	DW	OFFSET default_scan
pF5	DW	OFFSET default_scan
pF6	DW	OFFSET default_scan
pF7	DW	OFFSET default_scan
pF8	DW	OFFSET default_scan
pF9	DW	OFFSET default_scan
pFA	DW	OFFSET default_scan
pFB	DW	OFFSET default_scan
pFC	DW	OFFSET default_scan
pFD	DW	OFFSET default_scan
pFE	DW	OFFSET default_scan
pFF	DW	OFFSET default_scan

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
	mov ax,pc_key_data_sel
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
	mov ax,pc_key_data_sel
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
	mov bx,pc_key_data_sel
	mov ds,bx
	mov ds:mouse_counter,0
	GetThread
	mov ds:mouse_thread,ax
;
	stc
	call CheckAux
	jc init_mouse_done
;
    
init_check_aux_loop:
	in al,64h
	test al,2
	jz init_check_aux_do
	mov eax,10
	WaitMilliSec
	jmp init_check_aux_loop

init_check_aux_do:
	mov al,0A9h
	out 64h,al

init_check_loop1:
	in al,64h
	test al,2
	jz init_check_read
;
	mov eax,10
	WaitMilliSec
	jmp init_check_loop1

init_check_read:
    in al,60h
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

IFDEF NO_MOUSE
	jmp init_mouse_revoke ; activate this to disable non-existent mouse !!
ENDIF
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
    GetKeyboardState
    mov dx,ax
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
	mov ax,pc_key_data_sel
	mov ds,ax
	GetThread
	mov ds:mode_thread,ax
	in al,60h

mode_thread_loop:
	WaitForSignal
	mov al,ds:focus_req
	or al,al
	jz mode_thread_mode
;
    mov ds:focus_req,0
    SetFocus
    jmp mode_thread_loop

mode_thread_mode:
	call UpdateMode
	jmp mode_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			keyb_int
;
;		DESCRIPTION:	Keyboard and PS/2 mouse hardware int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
	push ax
	GetKeyboardState
	or ax,ext_numpad_active
	and ax, NOT ext_numpad_handled
	SetKeyboardState
	pop ax
	jmp keyb_int_loop	

keyb_int_not_numpad:
	push ax
	GetKeyboardState
	mov cx,ax
	pop ax
	test cx,ext_numpad_active
	jz keyb_int_numpad_handled
;
	test cx, ext_numpad_handled
	jz keyb_int_numpad_mark_handled
;
	and cx, NOT ext_numpad_active
	push ax
	mov ax,cx
	SetKeyboardState
	pop ax
	jmp keyb_int_numpad_handled

keyb_int_numpad_mark_handled:
	or cx, ext_numpad_handled
	push ax
	mov ax,cx
	SetKeyboardState
	pop ax

keyb_int_numpad_handled:
	movzx bx,al
	add bx,bx
	call word ptr cs:[bx].handle_scan_code_tab

keyb_int_done:
	ret
keyb_int	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_keyb_thread
;
;		DESCRIPTION:	Init keyboard threads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_keyb_thread	PROC far
	push ds
	push es
	pusha
	mov ax,cs
	mov ds,ax
	mov es,ax
;
    mov ax,start_keyboard_nr
    IsValidOsGate
    jc keyb_started
;
    StartKeyboard

keyb_started:    
	mov si,OFFSET mode_pr
	mov di,OFFSET mode_name
	mov cx,500
	mov ax,4
	CreateThread
;
	mov bx,pc_key_data_sel
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init
;
;		DESCRIPTION:	Init device-driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	push ds
	push es
	pusha
	mov bx,pc_key_code_sel
	InitDevice
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET init_keyb_thread
	HookInitTasking
;
	mov bx,pc_key_data_sel
	mov eax,SIZE key_data_seg
	AllocateFixedSystemMem
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET init_mouse
	mov di,OFFSET init_mouse_name
	xor cl,cl
	mov ax,init_mouse_nr
	RegisterOsGate
;
	mov ax,pc_key_data_sel
	mov ds,ax
	xor ax,ax
	mov ds:mode_thread,ax
	mov ds:mouse_thread,ax
	mov ds:status,0
	mov ds:focus_req,0
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init
