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
; The author of this program may be contacted at gnutchat@hotmail.com
;
; KEYFR.ASM
; AZERTY keyboard 
;
;===============================================================================================
;      Following a keyboard hit with RDOS
;      ----------------------------------
; Step 1: Irq1 (os/irq.asm)
; ------
;   - The keyboard Irq handler is in action, just follow the Macro irq&nr in irq.asm with nr=1.
;   - His job is to call the keyboard irq handler: keyb_int located in key.asm 
;
; Step 2: keyb_int (os/key.asm)
; ------
;   - He handle the keyboard hit and (PS) mouse.
;   - For keyboard:
;         - port60h = 0FAh acknowledge keyboad controller
;         - port60h = 0FEh key must be resend
;         - port60h = 0FFh poll the port60h
;         - port60h = 0E0h handle extended keyboard scan code "Make = 0E0h 48h Break = 0E0h C8h"
;         - Alt Ctrl Shift... combinaison handle if necessary
;         - print,num,scroll,del,caps keys handle if necessary
;         - F1 .. F10 handle if necessary
;   - He end by saving the scan code and signal the keyboard thread which is directed by keyboard_pr (os/key.asm)
;     waiting for signal.
;
; Step 3: keyboard_pr (os/key.asm)
; ------
;  - the decision of which country keyboard must be handle is took here
;
;	mov al,ds:scan_code      ;save by keyb_int above
;	xor bh,bh
;	mov bl,al
;	shl bx,3
;	add bx,OFFSET scan_code_tab    ;scan_code_tab is country dependant keybfr.asm ,keybus.asm ...
;	call word ptr cs:[bx].syntax_call  ; scan code specefic
;	jc keyboard_thread_loop            
;	call put_key_code                   ; put the scan correspondance in the keyboard buffer
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME keyfr

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

	.386p

GateSize = 16

INCLUDE ..\os\user.def
INCLUDE ..\os\user.inc

; I've try to use GetKeyboardState but the result was wrong
; that's why I put this here only for shift_states

key_data_seg	SEGMENT AT 0

shift_states	DW ?
mode_thread	DW ?
keyboard_thread	DW ?
mouse_thread	DW ?
command		DB ?
scan_code	DB ?
status		DB ?

mouse_timeout	DB ?
mouse_counter	DB ?
mouse_buttons	DB ?
mouse_dx	DB ?
mouse_dy	DB ?

key_data_seg	ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn dummy_scan:near
	extrn del_scan:near
	extrn simple_scan:near
	extrn caps_scan:near
	extrn num_scan:near
	extrn f_key_scan:near
	
no_ext_scan_code_tab:
;		handle extended key           handle not extended key
nesc00	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc01	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc02	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc03	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc04	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc05	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc06	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc07	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc08	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc09	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc0A	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc0B	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc0C	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc0D	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc0E	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc0F	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc10	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc11	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc12	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc13	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc14	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc15	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc16	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc17	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc18	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc19	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc1A	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc1B	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc1C	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc1D	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc1E	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc1F	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc20	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc21	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc22	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc23	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc24	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc25	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc26	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc27	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc28	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc29	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc2A	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc2B	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc2C	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc2D	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc2E	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc2F	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc30	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc31	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc32	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc33	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc34	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc35	DW	OFFSET num35_scan,		OFFSET caps_scan
nesc36	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc37	DW	OFFSET extended_scan,		OFFSET num37_scan
nesc38	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc39	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc3A	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc3B	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc3C	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc3D	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc3E	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc3F	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc40	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc41	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc42	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc43	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc44	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc45	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc46	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc47	DW	OFFSET extended_scan,		OFFSET num_scan
nesc48	DW	OFFSET extended_scan,		OFFSET num_scan
nesc49	DW	OFFSET extended_scan,		OFFSET num_scan
nesc4A	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc4B	DW	OFFSET extended_scan,		OFFSET num_scan
nesc4C	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc4D	DW	OFFSET extended_scan,		OFFSET num_scan
nesc4E	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc4F	DW	OFFSET extended_scan,		OFFSET num_scan
nesc50	DW	OFFSET extended_scan,		OFFSET num_scan
nesc51	DW	OFFSET extended_scan,		OFFSET num_scan
nesc52	DW	OFFSET extended_scan,		OFFSET num_scan
nesc53	DW	OFFSET extended_scan,		OFFSET del_scan
nesc54	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc55	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc56	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc57	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc58	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc59	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc5A	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc5B	DW	OFFSET extended_scan,		OFFSET ignore_scan
nesc5C	DW	OFFSET extended_scan,		OFFSET ignore_scan
nesc5D	DW	OFFSET extended_scan,		OFFSET ignore_scan
nesc5E	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc5F	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc60	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc61	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc62	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc63	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc64	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc65	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc66	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc67	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc68	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc69	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc6A	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc6B	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc6C	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc6D	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc6E	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc6F	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc70	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc71	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc72	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc73	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc74	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc75	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc76	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc77	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc78	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc79	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc7A	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc7B	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc7C	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc7D	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc7E	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc7F	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc80	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc81	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc82	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc83	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc84	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc85	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc86	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc87	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc88	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc89	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc8A	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc8B	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc8C	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc8D	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc8E	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc8F	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc90	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc91	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc92	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc93	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc94	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc95	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc96	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc97	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc98	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc99	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc9A	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc9B	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc9C	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc9D	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc9E	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nesc9F	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescA0	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescA1	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescA2	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescA3	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescA4	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescA5	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescA6	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescA7	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescA8	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescA9	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescAA	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescAB	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescAC	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescAD	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescAE	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescAF	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescB0	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescB1	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescB2	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescB3	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescB4	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescB5	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescB6	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescB7	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescB8	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescB9	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescBA	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescBB	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescBC	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescBD	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescBE	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescBF	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescC0	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescC1	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescC2	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescC3	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescC4	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescC5	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescC6	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescC7	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescC8	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescC9	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescCA	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescCB	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescCC	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescCD	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescCE	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescCF	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescD0	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescD1	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescD2	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescD3	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescD4	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescD5	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescD6	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescD7	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescD8	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescD9	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescDA	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescDB	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescDC	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescDD	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescDE	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescDF	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescE0	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescE1	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescE2	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescE3	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescE4	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescE5	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescE6	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescE7	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescE8	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescE9	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescEA	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescEB	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescEC	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescED	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescEE	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescEF	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescF0	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescF1	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescF2	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescF3	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescF4	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescF5	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescF6	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescF7	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescF8	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescF9	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescFA	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescFB	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescFC	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescFD	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescFE	DW	OFFSET ignore_scan,		OFFSET ignore_scan
nescFF	DW	OFFSET ignore_scan,		OFFSET ignore_scan

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			extended_scan
;
;		DESCRIPTION:	*
;
;		PARAMETERS:	*
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extended_scan	PROC near
	mov al,ds:scan_code
	xor ah,ah
	clc
	ret
extended_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ignore_scan
;
;		DESCRIPTION:	Handle unsupported extended keys
;
;		PARAMETERS:	*
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ignore_scan	PROC near
	clc
	ret
ignore_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			num35_scan
;
;		DESCRIPTION:	Handle scan 35 for numeric case
;
;		PARAMETERS:	*
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

num35_scan	PROC near
	mov al,35h
	mov ah,'/'
	clc
	ret
num35_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			num37_scan
;
;		DESCRIPTION:	Handle scan 37 for numeric case
;
;		PARAMETERS:	*
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

num37_scan	PROC near
	mov al,37h
	mov ah,'*'
	clc
	ret
num37_scan	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HandleExtScan
;
;		DESCRIPTION:	Handle extended scan code ,thos prefix by 0E0h
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
HandleExtScan proc near
	mov cx,ds:shift_states
	xor si,si
	movzx si,al
	shl si,2
	add si,OFFSET no_ext_scan_code_tab
	test cx,ext_numpad_active
	jz short handle_ext_scan_no
	call word ptr cs:[si]
	jmp short handle_ext_scan_ret
handle_ext_scan_no:
	add si,2
	call word ptr cs:[si]
handle_ext_scan_ret:
	ret
HandleExtScan endp

	public scan_code_tab

scan_code_tab:
;
;		normal	shift	alt	alt-shift	ctrl	extend code
;
c00	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c01	DB	1Bh,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c02	DB	'&',	'1',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c03	DB	'é',	'2',	'~',	-1,		-1,		-1
	DW	OFFSET caps_scan

c04	DB	'"',	'3',	'#',	-1,		-1,		-1
	DW	OFFSET caps_scan

c05	DB	27h,	'4',	'{',	-1,		-1,		-1
	DW	OFFSET caps_scan

c06	DB	'(',	'5',	'[',	-1,		-1,		-1
	DW	OFFSET caps_scan

c07	DB	'-',	'6',	'|',	-1,		-1,		-1
	DW	OFFSET caps_scan

c08	DB	'è',	'7',	'`',	-1,		-1,		-1
	DW	OFFSET caps_scan

c09	DB	'_',	'8',	'\',	-1,		-1,		-1
	DW	OFFSET caps_scan

c0A	DB	'ç',	'9',	'^',	-1,		-1,		-1
	DW	OFFSET caps_scan

c0B	DB	'à',	'0',	'@',	-1,		-1,		-1
	DW	OFFSET caps_scan

c0C	DB	')',	'°',	']',	-1,		-1,		-1
	DW	OFFSET caps_scan

c0D	DB	'=',	'+',	'}',	-1,		-1,		-1
	DW	OFFSET caps_scan

c0E	DB	8,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c0F	DB	9,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c10	DB	'a',	'A',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c11	DB	'z',	'Z',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c12	DB	'e',	'E',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c13	DB	'r',	'R',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c14	DB	't',	'T',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan
	
c15	DB	'y',	'Y',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c16	DB	'u',	'U',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c17	DB	'i',	'I',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c18	DB	'o',	'O',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c19	DB	'p',	'P',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c1A	DB	5Eh,	0A8h,	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c1B	DB	'$',	0A3h,	'¤',	-1,		-1,		-1
	DW	OFFSET caps_scan

c1C	DB	0Dh,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c1D	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c1E	DB	'q',	'Q',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c1F	DB	's',	'S',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c20	DB	'd',	'D',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c21	DB	'f',	'F',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c22	DB	'g',	'G',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c23	DB	'h',	'H',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c24	DB	'j',	'J',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c25	DB	'k',	'K',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c26	DB	'l',	'L',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c27	DB	'm',	'M',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c28	DB	'ù',	'%',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c29	DB	'²',	-1,	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c2A	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c2B	DB	'*',	'µ',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c2C	DB	'w',	'W',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c2D	DB	'x',	'X',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c2E	DB	'c',	'C',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c2F	DB	'v',	'V',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c30	DB	'b',	'B',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c31	DB	'n',	'N',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c32	DB	',',	'?',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c33	DB	';',	'.',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c34	DB	':',	'/',	-1,	-1,		-1,		-1
	DW	OFFSET caps_scan

c35	DB	'!',	0A7h,	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c36	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c37	DB	'*',	-1,	37h,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c38	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c39	DB	' ',	-1,	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c3A	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c3B	DB	3Bh,	54h,	68h,	5Eh,		5Eh,		-1
	DW	OFFSET f_key_scan

c3C	DB	3Ch,	55h,	69h,	5Fh,		5Fh,		-1
	DW	OFFSET f_key_scan

c3D	DB	3Dh,	56h,	6Ah,	60h,		60h,		-1
	DW	OFFSET f_key_scan

c3E	DB	3Eh,	57h,	6Bh,	61h,		61h,		-1
	DW	OFFSET f_key_scan

c3F	DB	3Fh,	58h,	6Ch,	62h,		62h,		-1
	DW	OFFSET f_key_scan

c40	DB	40h,	59h,	6Dh,	63h,		63h,		-1
	DW	OFFSET f_key_scan

c41	DB	41h,	5Ah,	6Eh,	64h,		64h,		-1
	DW	OFFSET f_key_scan

c42	DB	42h,	5Bh,	6Fh,	65h,		65h,		-1
	DW	OFFSET f_key_scan

c43	DB	43h,	5Ch,	70h,	66h,		66h,		-1
	DW	OFFSET f_key_scan

c44	DB	44h,	5Dh,	71h,	67h,		67h,		-1
	DW	OFFSET f_key_scan

c45	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c46	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c47	DB	47h,	'7',	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c48	DB	48h,	'8',	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c49	DB	49h,	'9',	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c4A	DB	'-',	-1,	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c4B	DB	4Bh,	'4',	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c4C	DB	'5',	'5',	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c4D	DB	4Dh,	'6',	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c4E	DB	'+',	'+',	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c4F	DB	4Fh,	'1',	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c50	DB	50h,	'2',	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c51	DB	51h,	'3',	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c52	DB	52h,	'0',	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c53	DB	'.',	53h,	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c54	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c55	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c56	DB	'<',	'>',	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c57	DB	57h,	5Eh,	8Bh,	89h,		89h,		-1
	DW	OFFSET f_key_scan

c58	DB	58h,	5Fh,	8Ch,	8Ah,		8Ah,		-1
	DW	OFFSET f_key_scan

c59	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c5A	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c5B	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c5C	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c5D	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET HandleExtScan

c5E	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c5F	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c60	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c61	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c62	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c63	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c64	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c65	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c66	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c67	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c68	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c69	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c6A	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c6B	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c6C	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c6D	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c6E	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c6F	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c70	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c71	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c72	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c73	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c74	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c75	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c76	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c77	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c78	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c79	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c7A	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c7B	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c7C	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c7D	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c7E	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c7F	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c80	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c81	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c82	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c83	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c84	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c85	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c86	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c87	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c88	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c89	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c8A	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c8B	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c8C	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c8D	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c8E	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c8F	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c90	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c91	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c92	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c93	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c94	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c95	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c96	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c97	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c98	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c99	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c9A	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c9B	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c9C	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c9D	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c9E	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

c9F	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cA0	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cA1	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cA2	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cA3	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cA4	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cA5	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cA6	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cA7	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cA8	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cA9	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cAA	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cAB	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cAC	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cAD	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cAE	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cAF	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cB0	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cB1	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cB2	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cB3	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cB4	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cB5	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cB6	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cB7	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cB8	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cB9	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cBA	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cBB	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cBC	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cBD	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cBE	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cBF	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cC0	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cC1	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cC2	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cC3	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cC4	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cC5	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cC6	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cC7	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cC8	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cC9	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cCA	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cCB	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cCC	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cCD	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cCE	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cCF	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cD0	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cD1	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cD2	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cD3	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cD4	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cD5	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cD6	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cD7	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cD8	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cD9	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cDA	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cDB	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cDC	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cDD	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cDE	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cDF	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cE0	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cE1	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cE2	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cE3	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cE4	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cE5	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cE6	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cE7	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cE8	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cE9	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cEA	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cEB	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cEC	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cED	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cEE	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cEF	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cF0	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cF1	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cF2	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cF3	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cF4	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cF5	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cF6	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cF7	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cF8	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cF9	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cFA	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cFB	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cFC	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cFD	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cFE	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

cFF	DB	-1,	-1,	-1,	-1,		-1,		-1
	DW	OFFSET dummy_scan

code	ENDS

	END
