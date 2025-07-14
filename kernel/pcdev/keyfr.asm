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
;   TODO:   Extended_scan refers to (previous) scan code.
;           This is no longer supported since key.asm doesn't
;           save scan-codes anymore. Should be fixed by adding
;           this functionality to key.asm, and by providing
;           an interface function. GetKeyboardState used instead
;           of data-segment layout of key.asm
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.386p

INCLUDE key.inc

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	public scan_tab_fr

scan_tab_fr:
;
;		normal	shift	alt		ctrl	extend  vk      vk-num  type
;
c00	DB	-1,		-1,		-1,		-1,		-1,     0,  	0,      NO_KEY
c01	DB	1Bh,	1Bh,	1Bh,	1Bh,	-1,     1Bh,	1Bh,    ESC_KEY
c02	DB	'&',	'1',	-1,		-1,		78h,    '1',	'1',    SIMPLE_KEY
c03	DB	'é',	'2',	'~',	-1,		79h,    '2',	'2',    SIMPLE_KEY
c04	DB	'"',	'3',	'#',	-1,		7Ah,    '3',	'3',    SIMPLE_KEY
c05	DB	27h,	'4',	'{',	-1,		7Bh,    '4',	'4',    SIMPLE_KEY
c06	DB	'(',	'5',	'[',	-1,		7Ch,    '5',	'5',    SIMPLE_KEY
c07	DB	'-',	'6',	'|',	-1,		7Dh,    '6',	'6',    SIMPLE_KEY
c08	DB	'è',	'7',	'`',	-1,		7Eh,    '7',	'7',    SIMPLE_KEY
c09	DB	'_',	'8',	'\',	-1,		7Fh,    '8',	'8',    SIMPLE_KEY
c0A	DB	'ç',	'9',	'^',	-1,		80h,    '9',	'9',    SIMPLE_KEY
c0B	DB	'à',	'0',	'@',	-1,		81h,    '0',	'0',    SIMPLE_KEY
c0C	DB	')',	'°',	']',	-1,		-1,     0BBh,	0BBh,   SIMPLE_KEY
c0D	DB	'=',	'+',	'}',	-1,		-1,     0DBh,	0DBh,   SIMPLE_KEY
c0E	DB	8,		8,		8,		8,		-1,     8,		8,      SIMPLE_KEY
c0F	DB	9,  	0,		9,  	9,  	0Fh,    9,		9,      SIMPLE_KEY
c10	DB	'a',	'A',	0,		-1,		1Eh,    'A',	'A',    CAPS_KEY
c11	DB	'z',	'Z',	0,		1Ah,	2Ch,    'Z',	'Z',    CAPS_KEY
c12	DB	'e',	'E',	0,		5,		12h,    'E',	'E',    CAPS_KEY
c13	DB	'r',	'R',	0,		12h,	13h,    'R',	'R',    CAPS_KEY
c14	DB	't',	'T',	0,		14h,	14h,    'T',	'T',    CAPS_KEY
c15	DB	'y',	'Y',	0,		19h,	15h,    'Y',	'Y',    CAPS_KEY
c16	DB	'u',	'U',	0,	    15h,	16h,    'U',	'U',    CAPS_KEY
c17	DB	'i',	'I',	0,		9,		17h,    'I',	'I',    CAPS_KEY
c18	DB	'o',	'O',	0,		0Fh,	18h,    'O',	'O',    CAPS_KEY
c19	DB	'p',	'P',	0,		10h,	19h,    'P',	'P',    CAPS_KEY
c1A	DB	5Eh,	0A8h,	-1,		-1,		1Ah,    0DDh,	0DDh,   CAPS_KEY
c1B	DB	'$',	0A3h,	'¤',	-1,		-1,     0BAh,	0BAh,   SIMPLE_KEY
c1C	DB	0Dh,	0Dh,	0Dh,	0Ah,	-1,     0Dh,	0Dh,    SIMPLE_KEY
c1D	DB	0,		0,		0,		0,		0,      11h,	11h,    STATE_KEY
c1E	DB	'q',	'Q',	0,		11h,	10h,    'Q',	'Q',    CAPS_KEY
c1F	DB	's',	'S',	0,		13h,	1Fh,    'S',	'S',    CAPS_KEY
c20	DB	'd',	'D',	0,		4,		20h,    'D',	'D',    CAPS_KEY
c21	DB	'f',	'F',	0,		6,		21h,    'F',	'F',    CAPS_KEY
c22	DB	'g',	'G',	0,		7,		22h,    'G',	'G',    CAPS_KEY
c23	DB	'h',	'H',	0,		8,		23h,    'H',	'H',    CAPS_KEY
c24	DB	'j',	'J',	0,	    0Ah,	24h,    'J',	'J',    CAPS_KEY
c25	DB	'k',	'K',	0,		0Bh,	25h,    'K',	'K',    CAPS_KEY
c26	DB	'l',	'L',	0,		0Ch,	26h,    'L',	'L',    CAPS_KEY
c27	DB	'm',	'M',	0,		0Dh,	32h,    'M',	'M',    CAPS_KEY
c28	DB	'ù',	'%',	-1,		-1,		28h,    0DEh,	0DEh,   CAPS_KEY
c29	DB	'²',	-1,		-1,		-1,		-1,     0DCh,	0DCh,   SIMPLE_KEY
c2A	DB	0,		0,		0,		0,		0,      10h,	10h,    STATE_KEY
c2B	DB	'*',	'µ',	-1,		-1,		-1,     0BFh,	0BFh,   SIMPLE_KEY
c2C	DB	'w',	'W',	0,		17h,	11h,    'W',	'W',    CAPS_KEY
c2D	DB	'x',	'X',	0,		18h,	2Dh,    'X',	'X',    CAPS_KEY
c2E	DB	'c',	'C',	0,		3,		2Eh,    'C',	'C',    CAPS_KEY
c2F	DB	'v',	'V',	0,		16h,	2Fh,    'V',	'V',    CAPS_KEY
c30	DB	'b',	'B',	0,		2,		30h,    'B',	'B',    CAPS_KEY
c31	DB	'n',	'N',	0,		0Eh,	31h,    'N',	'N',    CAPS_KEY
c32	DB	',',	'?',	-1,		-1,		-1,     0BCh,	0BCh,   SIMPLE_KEY
c33	DB	';',	'.',	-1,		-1,		-1,     0BCh,	0BCh,   SIMPLE_KEY
c34	DB	':',	'/',	-1,		-1,		-1,     0BEh,	0BEh,   SIMPLE_KEY
c35	DB	'!',	0A7h,	-1,		-1,		-1,     0BDh,	6Fh,    SIMPLE_KEY
c36	DB	0,		0,		0,		0,		0,      10h,	10h,    STATE_KEY
c37	DB	'*',	-1,	    37h,	-1,		-1,     2Ch,	6Ah,    SIMPLE_KEY
c38	DB	0,		0,		0,		0,		0,      12h,	12h,    STATE_KEY
c39	DB	' ',	' ',	' ',	' ',	-1,     20h,	20h,    SIMPLE_KEY
c3A	DB	0,		0,		0,		0,		0,      14h,	14h,    STATE_KEY
c3B	DB	3Bh,	54h,	68h,	5Eh,	0,      70h,	70h,    FUNC_KEY
c3C	DB	3Ch,	55h,	69h,	5Fh,	0,      71h,	71h,    FUNC_KEY
c3D	DB	3Dh,	56h,	6Ah,	60h,	0,      72h,	72h,    FUNC_KEY
c3E	DB	3Eh,	57h,	6Bh,	61h,	0,      73h,	73h,    FUNC_KEY
c3F	DB	3Fh,	58h,	6Ch,	62h,	0,      74h,	74h,    FUNC_KEY
c40	DB	40h,	59h,	6Dh,	63h,	0,      75h,	75h,    FUNC_KEY
c41	DB	41h,	5Ah,	6Eh,	64h,	0,      76h,	76h,    FUNC_KEY
c42	DB	42h,	5Bh,	6Fh,	65h,	0,      77h,	77h,    FUNC_KEY
c43	DB	43h,	5Ch,	70h,	66h,	0,      78h,	78h,    FUNC_KEY
c44	DB	44h,	5Dh,	71h,	67h,	0,      79h,	79h,    FUNC_KEY
c45	DB	0,		0,		0,		0,		0,      90h,	90h,    STATE_KEY
c46	DB	0,		0,		0,		0,		0,      91h,	91h,    STATE_KEY
c47	DB	47h,	'7',	-1,		77h,	-1,     67h,	24h,    NUM_KEY
c48	DB	48h,	'8',	-1,		-1,		-1,     68h,	26h,    NUM_KEY
c49	DB	49h,	'9',	-1,		84h,	-1,     69h,	21h,    NUM_KEY
c4A	DB	'-',	-1,		-1,		-1,		-1,     6Dh,	6Dh,    SIMPLE_KEY
c4B	DB	4Bh,	'4',	-1,		73h,	-1,     64h,	25h,    NUM_KEY
c4C	DB	'5',	'5',	-1,		-1,		-1,     65h,	65h,    SIMPLE_KEY
c4D	DB	4Dh,	'6',	-1,		74h,	-1,     66h,	27h,    NUM_KEY
c4E	DB	'+',	-1,		-1,		-1,		-1,     6Bh,	6Bh,    SIMPLE_KEY
c4F	DB	4Fh,	'1',	-1,		75h,	-1,     61h,	23h,    NUM_KEY
c50	DB	50h,	'2',	-1,		-1,		-1,     62h,	28h,    NUM_KEY
c51	DB	51h,	'3',	-1,		76h,	-1,     63h,	22h,    NUM_KEY
c52	DB	52h,	'0',	-1,		-1,		-1,     60h,	2Dh,    NUM_KEY
c53	DB	'.',	53h,	-1,		-1,		-1,     6Ch,	2Eh,    DEL_KEY
c54	DB	0,		0,		0,		0,		0,      6Eh,	6Eh,    SIMPLE_KEY
c55	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c56	DB	'<',	'>',	'|',	-1,		-1,     0E2h,	0E2h,   SIMPLE_KEY
c57	DB	57h,	5Eh,	8Bh,	89h,	-1,     7Ah,	7Ah,    FUNC_KEY
c58	DB	58h,	5Fh,	8Ch,	8Ah,	-1,     7Bh,	7Bh,    FUNC_KEY
c59	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c5A	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c5B	DB	0,		0,		0,		0,		0,      5Bh,	5Bh,    STATE_KEY
c5C	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c5D	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c5E	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c5F	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c60	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c61	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c62	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c63	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c64	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c65	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c66	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c67	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c68	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c69	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c6A	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c6B	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c6C	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c6D	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c6E	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c6F	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c70	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c71	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c72	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c73	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c74	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c75	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c76	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c77	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c78	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c79	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c7A	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c7B	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c7C	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c7D	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c7E	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY
c7F	DB	-1,		-1,		-1,		-1,		-1,     0,		0,      NO_KEY


code	ENDS

	END
