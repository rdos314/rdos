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
; KEYLCD.ASM
; Keyboard support for swedish keyboard at 3b3 port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME keylcd

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\os\driver.def
INCLUDE ..\os\user.def
INCLUDE ..\os\os.def
INCLUDE ..\os\user.inc
INCLUDE ..\os\os.inc
INCLUDE ..\os\key.inc


; offset in scan-code table
;
normal_code		EQU 0
shift_code		EQU 1
alt_code		EQU 2
ctrl_code		EQU 3
ext_code		EQU 4
vk_code         EQU 5
scan_code       EQU 6

	.386p


key_data_seg	STRUC

kd_low_key          DW ?
kd_high_key         DW ?

kd_curr_low_line    DB 8 DUP(?)
kd_curr_high_line   DB 8 DUP(?)

kd_prev_low_line    DB 8 DUP(?)
kd_prev_high_line   DB 8 DUP(?)

kd_curr_low_shift   DB ?
kd_curr_high_shift  DB ?

kd_prev_low_shift   DB ?
kd_prev_high_shift  DB ?

kd_key_stable_count DB ?
kd_shift_stable_count DB ?

key_data_seg    ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code
    
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
    
dummy_scan	PROC near
	ret
dummy_scan	ENDP

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
    SetFocus
    ret
f_press_scan    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			del_press_scan
;
;		DESCRIPTION:	Handle DEL key
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
del_press_scan	PROC near
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
del_press_scan	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			handle_scan
;
;		DESCRIPTION:	Handle a scan
;
;		PARAMETERS:		AL      scan code
;                       CX      State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_scan Proc near
    test cx,ctrl_pressed
    jz handle_not_ctrl
;
	mov ah,cs:[bx].ctrl_code
	cmp ah,-1
    jne handle_check

handle_not_ctrl:
    test cx,alt_pressed
    jz handle_not_alt
;
	mov ah,cs:[bx].alt_code
	cmp ah,-1
    jne handle_check

handle_not_alt:
    test cx,shift_pressed
    jz handle_not_shift
;
	mov ah,cs:[bx].shift_code
	cmp ah,-1
    jne handle_check

handle_not_shift:
	mov ah,cs:[bx].normal_code

handle_check:
	or ah,ah
	jne handle_no_ext
;
    mov cl,al
	movzx ax,byte ptr cs:[bx].ext_code
	and cl,80h
	or al,cl
	
handle_no_ext:
    ret
handle_scan Endp

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
    
simple_scan	PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
    call handle_scan
    PutKeyboardCode
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
    
caps_scan	PROC near
    push ax
    GetKeyboardState
    mov cx,ax
    pop ax
;
	and cx,107h
	xor cl,ch
	and cx,7
	call handle_scan
    PutKeyboardCode
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
    
num_scan	PROC near
	movzx ax,byte ptr cs:[bx]
    PutKeyboardCode
	ret
num_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			toggle_caps_scan
;
;		DESCRIPTION:	Handle Caps Lock
;
;		PARAMETERS:		AL		scan code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_caps_scan	PROC near
    push ax
    GetKeyboardState
	xor ax,caps_active
	SetKeyboardState
	pop ax
    clc
	ret
toggle_caps_scan	ENDP

;
;		    normal	shift	alt		ctrl	extend  vk      scan    param
;
k0l:
k0l01	DB	'¯',	'´',	-1,		-1,		-1,     0DCh,	29h,    0
k0l02	DB	52h,	52h,	52h,	52h,	-1,     60h,	52h,    0
k0l04	DB	0,		0,		0,		0,		0,      14h,	3Ah,    0
k0l08	DB	1Bh,	1Bh,	1Bh,	1Bh,	-1,     1Bh,	1,      0
k0l10	DB	'b',	'B',	0,		2,		30h,    'B',	30h,    0
k0l20	DB	'n',	'N',	0,		0Eh,	31h,    'N',	31h,    0

h0l:
h0l01	DW	OFFSET simple_scan,	        OFFSET simple_scan
h0l02	DW	OFFSET num_scan,			OFFSET num_scan
h0l04	DW	OFFSET toggle_caps_scan,	OFFSET dummy_scan
h0l08	DW	OFFSET simple_scan,	        OFFSET simple_scan
h0l10	DW	OFFSET caps_scan,			OFFSET caps_scan
h0l20	DW	OFFSET caps_scan,			OFFSET caps_scan

k0h:
k0h01	DB	4Fh,	4Fh,	4Fh,	4Fh,	-1,     61h,	4Fh,    0
k0h02	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0
k0h04	DB	'+',	'?',	'\',	-1,		-1,     0BBh,	0Ch,    0
k0h08	DB	58h,	5Fh,	8Ch,	8Ah,	-1,     7Bh,	58h,    0
k0h10	DB	4Dh,	4Dh,	4Dh,	4Dh,	-1,     66h,	4Dh,    0

h0h:
h0h01	DW	OFFSET num_scan,			OFFSET num_scan
h0h02	DW	OFFSET dummy_scan,			OFFSET dummy_scan
h0h04	DW	OFFSET simple_scan,	        OFFSET simple_scan
h0h08	DW	OFFSET f_press_scan,		OFFSET dummy_scan
h0h10	DW	OFFSET num_scan,			OFFSET num_scan

k1l:
k1l01	DB	3Dh,	56h,	6Ah,	60h,	0,      72h,	3Dh,    0
k1l02	DB	50h,	50h,	50h,	50h,	-1,     62h,	50h,    0
k1l04	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0
k1l08	DB	3Bh,	54h,	68h,	5Eh,	0,      70h,	3Bh,    0
k1l10	DB	'g',	'G',	0,		7,		22h,    'G',	22h,    0
k1l20	DB	'h',	'H',	0,		8,		23h,    'H',	23h,    0

h1l:
h1l01	DW	OFFSET f_press_scan,		OFFSET dummy_scan
h1l02	DW	OFFSET num_scan,			OFFSET num_scan
h1l04	DW	OFFSET dummy_scan,			OFFSET dummy_scan
h1l08	DW	OFFSET f_press_scan,		OFFSET dummy_scan
h1l10	DW	OFFSET caps_scan,			OFFSET caps_scan
h1l20	DW	OFFSET caps_scan,			OFFSET caps_scan

k1h:
k1h01	DB	51h,	51h,	51h,	51h,	-1,     63h,	51h,    0
k1h02	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0
k1h04	DB	'\',	'^',	'~',	-1,		-1,     0BAh,	1Bh,    0
k1h08	DB	8,		8,		8,		8,		-1,     8,		0Eh,    0
k1h10	DB	4Bh,	4Bh,	4Bh,	4Bh,	-1,     64h,	4Bh,    0

h1h:
h1h01	DW	OFFSET num_scan,			OFFSET num_scan
h1h02	DW	OFFSET dummy_scan,			OFFSET dummy_scan
h1h04	DW	OFFSET simple_scan,	        OFFSET simple_scan
h1h08	DW	OFFSET simple_scan,	        OFFSET simple_scan
h1h10	DW	OFFSET num_scan,			OFFSET num_scan

k2l:
k2l01	DB	'1',	'!',	-1,		-1,		78h,    '1',	2,      0
k2l02	DB	47h,	47h,	47h,	47h,	-1,     67h,	47h,    0
k2l04	DB	'2',	'"',	'@',	-1,		79h,    '2',	3,      0
k2l08	DB	'3',	'#',	'ú',	-1,		7Ah,    '3',	4,      0
k2l10	DB	'f',	'F',	0,		6,		21h,    'F',	21h,    0
k2l20	DB	'j',	'J',	0,	    0Ah,	24h,    'J',	24h,    0

h2l:
h2l01	DW	OFFSET simple_scan,	        OFFSET simple_scan
h2l02	DW	OFFSET num_scan,			OFFSET num_scan
h2l04	DW	OFFSET simple_scan,	        OFFSET simple_scan
h2l08	DW	OFFSET simple_scan,	        OFFSET simple_scan
h2l10	DW	OFFSET caps_scan,			OFFSET caps_scan
h2l20	DW	OFFSET caps_scan,			OFFSET caps_scan

k2h:
k2h01	DB	'8',	'(',	'[',	-1,		7Fh,    '8',	9,      0
k2h02	DB	'9',	')',	']',	-1,		80h,    '9',	0Ah,    0
k2h04	DB	'0',	'=',	'}',	-1,		81h,    '0',	0Bh,    0
k2h08	DB	44h,	5Dh,	71h,	67h,	0,      79h,	44h,    0
k2h10	DB	43h,	5Ch,	70h,	66h,	0,      78h,	43h,    0

h2h:
h2h01	DW	OFFSET simple_scan,	        OFFSET simple_scan
h2h02	DW	OFFSET simple_scan,	        OFFSET simple_scan
h2h04	DW	OFFSET simple_scan,	        OFFSET simple_scan
h2h08	DW	OFFSET f_press_scan,		OFFSET dummy_scan
h2h10	DW	OFFSET f_press_scan,		OFFSET dummy_scan

k3l:
k3l01	DB	'a',	'A',	0,		-1,		1Eh,    'A',	1Eh,    0
k3l02	DB	40h,	59h,	6Dh,	63h,	0,      75h,	40h,    0
k3l04	DB	's',	'S',	0,		13h,	1Fh,    'S',	1Fh,    0
k3l08	DB	'd',	'D',	0,		4,		20h,    'D',	20h,    0
k3l10	DB	'4',	'$',	'$',	-1,		7Bh,    '4',	5,      0
k3l20	DB	'7',	'/',	'{',	-1,		7Eh,    '7',	8,      0

h3l:
h3l01	DW	OFFSET caps_scan,			OFFSET caps_scan
h3l02	DW	OFFSET f_press_scan,		OFFSET dummy_scan
h3l04	DW	OFFSET caps_scan,			OFFSET caps_scan
h3l08	DW	OFFSET caps_scan,			OFFSET caps_scan
h3l10	DW	OFFSET simple_scan,	        OFFSET simple_scan
h3l20	DW	OFFSET simple_scan,	        OFFSET simple_scan

k3h:
k3h01	DB	'k',	'K',	0,		0Bh,	25h,    'K',	25h,    0
k3h02	DB	'l',	'L',	0,		0Ch,	26h,    'L',	26h,    0
k3h04	DB	'î',	'ô',	0,		-1,		27h,    0C0h,	27h,    0
k3h08	DB	'Ü',	'è',	0,		-1,		1Ah,    0DDh,	1Ah,    0
k3h10	DB	27h,	60h,	-1,		-1,		-1,     0DBh,	0Dh,    0

h3h:
h3h01	DW	OFFSET caps_scan,			OFFSET caps_scan
h3h02	DW	OFFSET caps_scan,			OFFSET caps_scan
h3h04	DW	OFFSET caps_scan,			OFFSET caps_scan
h3h08	DW	OFFSET caps_scan,			OFFSET caps_scan
h3h10	DW	OFFSET simple_scan,	        OFFSET simple_scan

k4l:
k4l01	DB	'<',	'>',	'|',	-1,		-1,     0E2h,	56h,    0
k4l02	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0
k4l04	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0
k4l08	DB	3Fh,	58h,	6Ch,	62h,	0,      74h,	3Fh,    0
k4l10	DB	'5',	'%',	-1,		-1,		7Ch,    '5',	6,      0
k4l20	DB	'6',	'&',	-1,		-1,		7Dh,    '6',	7,      0

h4l:
h4l01	DW	OFFSET simple_scan,	        OFFSET simple_scan
h4l02	DW	OFFSET dummy_scan,			OFFSET dummy_scan
h4l04	DW	OFFSET dummy_scan,			OFFSET dummy_scan
h4l08	DW	OFFSET f_press_scan,		OFFSET dummy_scan
h4l10	DW	OFFSET simple_scan,	        OFFSET simple_scan
h4l20	DW	OFFSET simple_scan,	        OFFSET simple_scan

k4h:
k4h01	DB	'Ñ',	'é',	0,		-1,		28h,    0DEh,	28h,    0
k4h02	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0
k4h04	DB	'-',	'_',	-1,		-1,		-1,     0BDh,	35h,    0
k4h08	DB	48h,	48h,	48h,	48h,	-1,     68h,	48h,    0
k4h10	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0

h4h:
h4h01	DW	OFFSET caps_scan,			OFFSET caps_scan
h4h02	DW	OFFSET dummy_scan,			OFFSET dummy_scan
h4h04	DW	OFFSET simple_scan,	        OFFSET simple_scan
h4h08	DW	OFFSET num_scan,			OFFSET num_scan
h4h10	DW	OFFSET dummy_scan,			OFFSET dummy_scan

k5l:
k5l01	DB	3Ch,	55h,	69h,	5Fh,	0,      71h,	3Ch,    0
k5l02	DB	' ',	' ',	' ',	' ',	-1,     20h,	39h,    0
k5l04	DB	3Eh,	57h,	6Bh,	61h,	0,      73h,	3Eh,    0
k5l08	DB	9,  	0,		9,  	9,  	0Fh,    9,		0Fh,    0
k5l10	DB	'v',	'V',	0,		16h,	2Fh,    'V',	2Fh,    0
k5l20	DB	'm',	'M',	0,		0Dh,	32h,    'M',	32h,    0

h5l:
h5l01	DW	OFFSET f_press_scan,		OFFSET dummy_scan
h5l02	DW	OFFSET simple_scan,	        OFFSET simple_scan
h5l04	DW	OFFSET f_press_scan,		OFFSET dummy_scan
h5l08	DW	OFFSET simple_scan,     	OFFSET simple_scan
h5l10	DW	OFFSET caps_scan,			OFFSET caps_scan
h5l20	DW	OFFSET caps_scan,			OFFSET caps_scan

k5h:
k5h01	DB	41h,	5Ah,	6Eh,	64h,	0,      76h,	41h,    0
k5h02	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0
k5h04	DB	42h,	5Bh,	6Fh,	65h,	0,      77h,	42h,    0
k5h08	DB	57h,	5Eh,	8Bh,	89h,	-1,     7Ah,	57h,    0
k5h10	DB	49h,	49h,	49h,	49h,	-1,     69h,	49h,    0

h5h:
h5h01	DW	OFFSET f_press_scan,		OFFSET dummy_scan
h5h02	DW	OFFSET dummy_scan,			OFFSET dummy_scan
h5h04	DW	OFFSET f_press_scan,		OFFSET dummy_scan
h5h08	DW	OFFSET f_press_scan,		OFFSET dummy_scan
h5h10	DW	OFFSET num_scan,			OFFSET num_scan

k6l:
k6l01	DB	'z',	'Z',	0,		1Ah,	2Ch,    'Z',	2Ch,    0
k6l02	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0
k6l04	DB	'x',	'X',	0,		18h,	2Dh,    'X',	2Dh,    0
k6l08	DB	'c',	'C',	0,		3,		2Eh,    'C',	2Eh,    0
k6l10	DB	't',	'T',	0,		14h,	14h,    'T',	14h,    0
k6l20	DB	'y',	'Y',	0,		19h,	15h,    'Y',	15h,    0

h6l:
h6l01	DW	OFFSET caps_scan,			OFFSET caps_scan
h6l02	DW	OFFSET dummy_scan,			OFFSET dummy_scan
h6l04	DW	OFFSET caps_scan,			OFFSET caps_scan
h6l08	DW	OFFSET caps_scan,			OFFSET caps_scan
h6l10	DW	OFFSET caps_scan,			OFFSET caps_scan
h6l20	DW	OFFSET caps_scan,			OFFSET caps_scan

k6h:
k6h01	DB	',',	';',	-1,		-1,		-1,     0BCh,	33h,    0
k6h02	DB	'.',	':',	-1,		-1,		-1,     0BEh,	34h,    0
k6h04	DB	'*',	'*',	-1,		-1,		-1,     2Ch,	37h,    0
k6h08	DB	0Dh,	0Dh,	0Dh,	0Ah,	-1,     0Dh,	1Ch,    0
k6h10	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0

h6h:
h6h01	DW	OFFSET simple_scan,	        OFFSET simple_scan
h6h02	DW	OFFSET simple_scan,	        OFFSET simple_scan
h6h04	DW	OFFSET simple_scan,	        OFFSET simple_scan
h6h08	DW	OFFSET simple_scan,     	OFFSET simple_scan
h6h10	DW	OFFSET dummy_scan,			OFFSET dummy_scan

k7l:
k7l01	DB	'q',	'Q',	0,		11h,	10h,    'Q',	10h,    0
k7l02	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0
k7l04	DB	'w',	'W',	0,		17h,	11h,    'W',	11h,    0
k7l08	DB	'e',	'E',	0,		5,		12h,    'E',	12h,    0
k7l10	DB	'r',	'R',	0,		12h,	13h,    'R',	13h,    0
k7l20	DB	'u',	'U',	0,	    15h,	16h,    'U',	16h,    0

h7l:
h7l01	DW	OFFSET caps_scan,			OFFSET caps_scan
h7l02	DW	OFFSET dummy_scan,			OFFSET dummy_scan
h7l04	DW	OFFSET caps_scan,			OFFSET caps_scan
h7l08	DW	OFFSET caps_scan,			OFFSET caps_scan
h7l10	DW	OFFSET caps_scan,			OFFSET caps_scan
h7l20	DW	OFFSET caps_scan,			OFFSET caps_scan

k7h:
k7h01	DB	'i',	'I',	0,		9,		17h,    'I',	17h,    0
k7h02	DB	'o',	'O',	0,		0Fh,	18h,    'O',	18h,    0
k7h04	DB	'p',	'P',	0,		10h,	19h,    'P',	19h,    0
k7h08	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      0
k7h10	DB	53h,	',',	-1,		-1,		-1,     6Ch,	53h,    0

h7h:
h7h01	DW	OFFSET caps_scan,			OFFSET caps_scan
h7h02	DW	OFFSET caps_scan,			OFFSET caps_scan
h7h04	DW	OFFSET caps_scan,			OFFSET caps_scan
h7h08	DW	OFFSET dummy_scan,			OFFSET dummy_scan
h7h10	DW	OFFSET del_press_scan,		OFFSET num_scan

low_tab:
lt00	DW OFFSET k0l,	OFFSET h0l
lt01	DW OFFSET k1l,	OFFSET h1l
lt02	DW OFFSET k2l,	OFFSET h2l
lt03	DW OFFSET k3l,	OFFSET h3l
lt04	DW OFFSET k4l,	OFFSET h4l
lt05	DW OFFSET k5l,	OFFSET h5l
lt06	DW OFFSET k6l,	OFFSET h6l
lt07	DW OFFSET k7l,	OFFSET h7l

high_tab:
ht00	DW OFFSET k0h,	OFFSET h0h
ht01	DW OFFSET k1h,	OFFSET h1h
ht02	DW OFFSET k2h,	OFFSET h2h
ht03	DW OFFSET k3h,	OFFSET h3h
ht04	DW OFFSET k4h,	OFFSET h4h
ht05	DW OFFSET k5h,	OFFSET h5h
ht06	DW OFFSET k6h,	OFFSET h6h
ht07	DW OFFSET k7h,	OFFSET h7h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			low_key_pressed
;
;		DESCRIPTION:	Handle a pressed key in low-line
;
;		PARAMETERS:		AL		Y-line (0..7)
;						AH		Pressed line (0..4)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

low_key_pressed	PROC near
	movzx di,al
	shl di,2
	mov bx, word ptr cs:[di].low_tab	; ktab
	mov di, word ptr cs:[di+2].low_tab  ; htab
	movzx ax,ah
	shl ax,2
	add di,ax
	add ax,ax
	add bx,ax
	mov al,cs:[bx].scan_code
	mov dl,byte ptr cs:[bx].vk_code
	mov dh,al
	call word ptr cs:[di]
	ret
low_key_pressed	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			high_key_pressed
;
;		DESCRIPTION:	Handle a pressed key in high-line
;
;		PARAMETERS:		AL		Y-line (0..7)
;						AH		Pressed line (0..3)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

high_key_pressed	PROC near
	movzx di,al
	shl di,2
	mov bx, word ptr cs:[di].high_tab	; ktab
	mov di, word ptr cs:[di+2].high_tab  ; htab
	movzx ax,ah
	shl ax,2
	add di,ax
	add ax,ax
	add bx,ax
	mov al,cs:[bx].scan_code
	mov dl,byte ptr cs:[bx].vk_code
	mov dh,al
	call word ptr cs:[di]
	ret
high_key_pressed	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			low_key_released
;
;		DESCRIPTION:	Handle a released key in low-line
;
;		PARAMETERS:		AL		Y-line (0..7)
;						AH		Released line (0..4)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

low_key_released	PROC near
	movzx di,al
	shl di,2
	mov bx, word ptr cs:[di].low_tab	; ktab
	mov di, word ptr cs:[di+2].low_tab  ; htab
	movzx ax,ah
	shl ax,2
	add di,ax
	add ax,ax
	add bx,ax
	mov al,cs:[bx].scan_code
	mov dl,byte ptr cs:[bx].vk_code
	mov dh,al
	or dh,80h
	call word ptr cs:[di+2]
	ret
low_key_released	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			high_key_released
;
;		DESCRIPTION:	Handle a released key in high-line
;
;		PARAMETERS:		AL		Y-line (0..7)
;						AH		Released line (0..3)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

high_key_released	PROC near
	movzx di,al
	shl di,2
	mov bx, word ptr cs:[di].high_tab	; ktab
	mov di, word ptr cs:[di+2].high_tab  ; htab
	movzx ax,ah
	shl ax,2
	add di,ax
	add ax,ax
	add bx,ax
	mov al,cs:[bx].scan_code
	mov dl,byte ptr cs:[bx].vk_code
	mov dh,al
	or dh,80h
	call word ptr cs:[di+2]
	ret
high_key_released	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadShiftLines
;
;		DESCRIPTION:	Read all shift lines
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadShiftLines    Proc near
    mov dx,3B3h
    mov al,10h
    out dx,al
	Swap
	Swap
	Swap
	Swap
	Swap
;
    in al,dx
    and al,3Fh
    mov ds:kd_curr_low_shift,al
;
    mov al,0
    out dx,al
	Swap
;
    in al,dx
    and al,1Fh
    mov ds:kd_curr_high_shift,al
;        
    ret
ReadShiftLines    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DebounceShift
;
;		DESCRIPTION:	Debounce shift keys
;
;       RETURNS:        NC      Shift keys stable
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DebounceShift    Proc near
    xor dx,dx
    mov al,ds:kd_curr_low_shift
    cmp al,ds:kd_prev_low_shift
    je debounce_shift_high
;
    inc dx

debounce_shift_high:
    mov al,ds:kd_curr_high_shift
    cmp al,ds:kd_prev_high_shift
    je debounce_shift_check
;
    inc dx

debounce_shift_check:
    or dx,dx
    jz debounce_shift_same
;
    mov ds:kd_shift_stable_count,0
    stc
    ret

debounce_shift_same:
    mov al,ds:kd_shift_stable_count
    inc al
    cmp al,2
    jbe debounce_shift_more
;
    clc
    ret

debounce_shift_more:
    mov ds:kd_shift_stable_count,al
    stc
    ret
DebounceShift    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ScanShift
;
;		DESCRIPTION:	Scan shift keys
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ScanShift    Proc near
    call ReadShiftLines
    call DebounceShift
    jc scan_shift_done
;
    GetKeyboardState
;
    mov cl,ds:kd_curr_low_shift
    mov ch,ds:kd_curr_high_shift
    test cx,21h
    jz scan_alt_rel
;
  	or ax,alt_pressed
  	jmp scan_alt_done

scan_alt_rel:
    and ax,NOT alt_pressed

scan_alt_done:
    test cx,102h
    jz scan_ctrl_rel
;
    or ax,ctrl_pressed
    jmp scan_ctrl_done

scan_ctrl_rel:
	and ax,NOT ctrl_pressed

scan_ctrl_done:
    test cx,18h
    jz scan_shift_rel
;
    or ax,shift_pressed
    jmp scan_shift_set

scan_shift_rel:
	and ax,NOT shift_pressed

scan_shift_set:
	SetKeyboardState

scan_shift_done:
    ret
ScanShift    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadKeyLines
;
;		DESCRIPTION:	Read all normal key lines
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadKeyLines    Proc near
    mov cx,8
    xor bl,bl
    mov si,OFFSET kd_curr_low_line
    mov di,OFFSET kd_curr_high_line

read_key_line_loop:
    mov dx,3B3h
    mov al,bl
    or al,18h
    out dx,al
	Swap
	Swap
	Swap
	Swap
	Swap
;
    in al,dx
    and al,3Fh
    mov [si],al
;
    mov al,bl
    or al,8
    out dx,al
	Swap
;
    in al,dx
    and al,1Fh
    mov [di],al
;
    inc si
    inc di
    inc bl
;
    loop read_key_line_loop
;        
    ret
ReadKeyLines    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DebounceKeys
;
;		DESCRIPTION:	Debounce keys
;
;       RETURNS:        NC      Keys stable
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DebounceKeys    Proc near
    xor dx,dx
    mov cx,8
    mov si,OFFSET kd_curr_low_line
    mov di,OFFSET kd_prev_low_line

debounce_keys_low_loop:
    mov al,[si]
    cmp al,[di]
    mov [di],al
    je debounce_keys_low_next
;
    inc dx

debounce_keys_low_next:
    inc si
    inc di
    loop debounce_keys_low_loop
;
    mov cx,8
    mov si,OFFSET kd_curr_high_line
    mov di,OFFSET kd_prev_high_line

debounce_keys_high_loop:
    mov al,[si]
    cmp al,[di]
    mov [di],al
    je debounce_keys_high_next
;
    inc dx

debounce_keys_high_next:
    inc si
    inc di
    loop debounce_keys_high_loop
;
    or dx,dx
    jz debounce_keys_same
;
    mov ds:kd_key_stable_count,0
    stc
    ret

debounce_keys_same:
    mov al,ds:kd_key_stable_count
    inc al
    cmp al,2
    jbe debounce_keys_more
;
    clc
    ret

debounce_keys_more:
    mov ds:kd_key_stable_count,al
    stc
    ret
DebounceKeys    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetPressedKeys
;
;		DESCRIPTION:	Get number of pressed keys
;
;       RETURNS:        AX      Number of pressed keys
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPressedKeys    Proc near
    xor dx,dx
    mov cx,8
    mov si,OFFSET kd_curr_low_line
    mov di,OFFSET kd_curr_high_line

get_pressed_keys_loop:
    mov al,[si]
    or al,al
    jz get_pressed_keys_check_high

get_pressed_low_loop:
    clc
    rcr al,1
    jnc get_pressed_low_loop
;
    inc dx
    or al,al
    jnz get_pressed_low_loop

get_pressed_keys_check_high:
    mov al,[di]
    or al,al
    jz get_pressed_keys_next
;

get_pressed_high_loop:
    clc
    rcr al,1
    jnc get_pressed_high_loop
;
    inc dx
    or al,al
    jnz get_pressed_high_loop

get_pressed_keys_next:
    inc si
    inc di
    inc bl
;
    loop get_pressed_keys_loop
;        
    mov ax,dx
    ret
GetPressedKeys    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetLowKey
;
;		DESCRIPTION:	Get first low key
;
;       RETURNS:        NC      OK
;                           AL  Y-line (0..7)
;						    AH	Released line (0..4)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetLowKey    Proc near
    xor al,al
    mov cx,8
    mov si,OFFSET kd_curr_low_line

get_low_key_loop:
    mov ah,[si]
    or ah,ah
    jz get_low_key_next
;
    mov cl,ah
    xor ah,ah

get_low_key_scan:
    clc
    rcr cl,1
    jc get_low_key_found
;
    inc ah
    jmp get_low_key_scan

get_low_key_found:    
    clc
    ret

get_low_key_next:
    inc si
    inc di
    inc al
    loop get_low_key_loop
;
    stc
    ret
GetLowKey    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetHighKey
;
;		DESCRIPTION:	Get first high key
;
;       RETURNS:        NC      OK
;                           AL  Y-line (0..7)
;						    AH	Released line (0..4)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetHighKey    Proc near
    xor al,al
    mov cx,8
    mov si,OFFSET kd_curr_high_line

get_high_key_loop:
    mov ah,[si]
    or ah,ah
    jz get_high_key_next
;
    mov cl,ah
    xor ah,ah

get_high_key_scan:
    clc
    rcr cl,1
    jc get_high_key_found
;
    inc ah
    jmp get_high_key_scan

get_high_key_found:    
    clc
    ret

get_high_key_next:
    inc si
    inc di
    inc al
    loop get_high_key_loop
;
    stc
    ret
GetHighKey    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			IsKeyPressed
;
;		DESCRIPTION:	Is key pressed?
;
;		RETURN:			NC		Key is pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsKeyPressed	Proc Near
    mov ax,ds:kd_low_key
    and ax,ds:kd_high_key
    cmp ax,-1
    je is_key_press_no
;
	clc
	ret

is_key_press_no:
	stc
	ret
IsKeyPressed	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			IsSameKey
;
;		DESCRIPTION:	Is same key pressed?
;
;		RETURN:			NC		Same key is pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsSameKey	Proc Near
	call GetLowKey
	jc is_same_key_high
;
	cmp ax,ds:kd_low_key
	je is_same_key_ok
;
	stc
	ret

is_same_key_high:
	call GetHighKey
	cmp ax,ds:kd_high_key
	je is_same_key_ok
;
	stc
	ret

is_same_key_ok:
	clc
	ret
IsSameKey	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			KeyPress
;
;		DESCRIPTION:	Handle key press
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

KeyPress	Proc near
    call GetLowKey
    jc key_high_press
;
    mov ds:kd_low_key,ax
    call low_key_pressed
	ret

key_high_press:
    call GetHighKey
;
    mov ds:kd_high_key,ax
    call high_key_pressed

key_press_done:
	ret
KeyPress	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			KeyRelease
;
;		DESCRIPTION:	Handle key release
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

KeyRelease	Proc near
    mov ax,ds:kd_low_key
    cmp ax,-1
    je key_high_rel
;
    call low_key_released
    mov ds:kd_low_key,-1
    jmp key_rel_done

key_high_rel:
    mov ax,ds:kd_high_key
    call high_key_released
    mov ds:kd_high_key,-1

key_rel_done:
	ret
KeyRelease	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ScanKeys
;
;		DESCRIPTION:	Scan normal keys
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ScanKeys    Proc near
    call ReadKeyLines
    call DebounceKeys
    jc scan_keys_done
;
    call GetPressedKeys
    or ax,ax
    je scan_keys_no_key
;
    cmp ax,1
    jne scan_keys_done

scan_keys_one_key:
	call IsKeyPressed
	jc scan_keys_press
;
	call IsSameKey
	jnc scan_keys_done
;
	call KeyRelease

scan_keys_press:
	call KeyPress
    jmp scan_keys_done

scan_keys_no_key:
	call IsKeyPressed
	jc scan_keys_done
;
	call KeyRelease

scan_keys_done:
    ret
ScanKeys    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			keyb_thread
;
;		DESCRIPTION:	Keyboard thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

keyb_name   DB 'Keyboard', 0

keyb_thread:
    mov ax,pc_key_data_sel
    mov ds,ax

keyb_thread_loop:
	mov ax,10
	WaitMilliSec
	call ScanShift
	call ScanKeys
	jmp keyb_thread_loop

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
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET keyb_thread
	mov di,OFFSET keyb_name
	mov cx,500
	mov ax,1
	CreateThread
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
	mov ax,pc_key_data_sel
	mov ds,ax
	mov es,ax
;
    xor al,al
;
    mov cx,8
    mov di,OFFSET kd_prev_low_line
    rep stosb
;
    mov cx,8
    mov di,OFFSET kd_prev_high_line
    rep stosb
;
    mov ds:kd_low_key,-1
    mov ds:kd_high_key,-1
    mov ds:kd_key_stable_count,0
;
    mov ds:kd_prev_low_shift,0
    mov ds:kd_prev_high_shift,0
    mov ds:kd_shift_stable_count,0
;
	popa
	pop es
	pop ds
	ret
init	ENDP
 
code	ENDS

	END init
