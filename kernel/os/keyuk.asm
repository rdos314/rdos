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
; KEYUK.ASM
; UK keyboard support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME keyus

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn dummy_scan:near
	extrn del_scan:near
	extrn simple_scan:near
	extrn caps_scan:near
	extrn num_scan:near
	extrn f_key_scan:near

	public scan_code_tab

scan_code_tab:
;
;		normal	shift	alt		alt-shift	ctrl	extend code
;
c00	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c01	DB	1Bh,	1Bh,	1Bh,	1Bh,	1Bh,	-1
	DW	OFFSET simple_scan

c02	DB	'1',	'!',	'!',	0,		-1,		78h
	DW	OFFSET simple_scan

c03	DB	'2',	'"',	'"',	0,		-1,		79h
	DW	OFFSET simple_scan

c04	DB	'3',	'œ',	'œ',	0,		-1,		7Ah
	DW	OFFSET simple_scan

c05	DB	'4',	'$',	'$',	0,		-1,		7Bh
	DW	OFFSET simple_scan

c06	DB	'5',	'%',	'%',	0,		-1,		7Ch
	DW	OFFSET simple_scan

c07	DB	'6',	'^',	'^',	0,		-1,		7Dh
	DW	OFFSET simple_scan

c08	DB	'7',	'&',	'&',	0,		-1,		7Eh
	DW	OFFSET simple_scan

c09	DB	'8',	'*',	'*',	0,		-1,		7Fh
	DW	OFFSET simple_scan

c0A	DB	'9',	'(',	'(',	0,		-1,		80h
	DW	OFFSET simple_scan

c0B	DB	'0',	')',	')',	0,		-1,		81h
	DW	OFFSET simple_scan

c0C	DB	'-',	'_',	'_',	-1,		-1,		-1
	DW	OFFSET simple_scan

c0D	DB	'=',	'+',	'+',	-1,		-1,		-1
	DW	OFFSET simple_scan

c0E	DB	8,		8,		8,		8,		7Fh,	-1
	DW	OFFSET simple_scan

c0F	DB	'	',	0,		'	',	-1,		-1,		0Fh
	DW	OFFSET simple_scan

c10	DB	'q',	'Q',	0,		-1,		11h,	10h
	DW	OFFSET caps_scan

c11	DB	'w',	'W',	0,		-1,		17h,	11h
	DW	OFFSET caps_scan

c12	DB	'e',	'E',	0,		-1,		5,		12h
	DW	OFFSET caps_scan

c13	DB	'r',	'R',	0,		-1,		12h,	13h
	DW	OFFSET caps_scan

c14	DB	't',	'T',	0,		-1,		14h,	14h
	DW	OFFSET caps_scan

c15	DB	'y',	'Y',	0,		-1,		19h,	15h
	DW	OFFSET caps_scan

c16	DB	'u',	'U',	0,		-1,		15h,	16h
	DW	OFFSET caps_scan

c17	DB	'i',	'I',	0,		-1,		9,		17h
	DW	OFFSET caps_scan

c18	DB	'o',	'O',	0,		-1,		0Fh,	18h
	DW	OFFSET caps_scan

c19	DB	'p',	'P',	0,		-1,		10h,	19h
	DW	OFFSET caps_scan

c1A	DB	'[',	'{',	-1,		-1,		1Bh,	-1
	DW	OFFSET caps_scan

c1B	DB	']',	'}',	-1,		-1,		1Dh,	-1
	DW	OFFSET simple_scan

c1C	DB	0Dh,	0Dh,	-1,		-1,		0Ah,	-1
	DW	OFFSET simple_scan

c1D	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c1E	DB	'a',	'A',	0,		-1,		1,		1Eh
	DW	OFFSET caps_scan

c1F	DB	's',	'S',	0,		-1,		13h,	1Fh
	DW	OFFSET caps_scan

c20	DB	'd',	'D',	0,		-1,		4,		20h
	DW	OFFSET caps_scan

c21	DB	'f',	'F',	0,		-1,		6,		21h
	DW	OFFSET caps_scan

c22	DB	'g',	'G',	0,		-1,		7,		22h
	DW	OFFSET caps_scan

c23	DB	'h',	'H',	0,		-1,		8,		23h
	DW	OFFSET caps_scan

c24	DB	'j',	'J',	0,		-1,		0Ah,	24h
	DW	OFFSET caps_scan

c25	DB	'k',	'K',	0,		-1,		0Bh,	25h
	DW	OFFSET caps_scan

c26	DB	'l',	'L',	0,		-1,		0Ch,	26h
	DW	OFFSET caps_scan

c27	DB	';',	':',	-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c28	DB	60h,	22h,	-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c29	DB	'`',	'ª',	-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c2A	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c2B	DB	'#',	'~',	-1,		-1,		1Ch,	-1
	DW	OFFSET simple_scan

c2C	DB	'z',	'Z',	0,		-1,		1Ah,	2Ch
	DW	OFFSET caps_scan

c2D	DB	'x',	'X',	0,		-1,		18h,	2Dh
	DW	OFFSET caps_scan

c2E	DB	'c',	'C',	0,		-1,		3,		2Eh
	DW	OFFSET caps_scan

c2F	DB	'v',	'V',	0,		-1,		16h,	2Fh
	DW	OFFSET caps_scan

c30	DB	'b',	'B',	0,		-1,		2,		30h
	DW	OFFSET caps_scan

c31	DB	'n',	'N',	0,		-1,		0Eh,	31h
	DW	OFFSET caps_scan

c32	DB	'm',	'M',	0,		-1,		0Dh,	32h
	DW	OFFSET caps_scan

c33	DB	',',	'<',	-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c34	DB	'.',	'>',	-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c35	DB	'/',	'?',	-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c36	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c37	DB	'*',	-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c38	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c39	DB	' ',	' ',	' ',	' ',	' ',	-1
	DW	OFFSET simple_scan

c3A	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c3B	DB	3Bh,	54h,	68h,	5Eh,	5Eh,	0
	DW	OFFSET f_key_scan

c3C	DB	3Ch,	55h,	69h,	5Fh,	5Fh,	0
	DW	OFFSET f_key_scan

c3D	DB	3Dh,	56h,	6Ah,	60h,	60h,	0
	DW	OFFSET f_key_scan

c3E	DB	3Eh,	57h,	6Bh,	61h,	61h,	0
	DW	OFFSET f_key_scan

c3F	DB	3Fh,	58h,	6Ch,	62h,	62h,	0
	DW	OFFSET f_key_scan

c40	DB	40h,	59h,	6Dh,	63h,	63h,	0
	DW	OFFSET f_key_scan

c41	DB	41h,	5Ah,	6Eh,	64h,	64h,	0
	DW	OFFSET f_key_scan

c42	DB	42h,	5Bh,	6Fh,	65h,	65h,	0
	DW	OFFSET f_key_scan

c43	DB	43h,	5Ch,	70h,	66h,	66h,	0
	DW	OFFSET f_key_scan

c44	DB	44h,	5Dh,	71h,	67h,	67h,	0
	DW	OFFSET f_key_scan

c45	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c46	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c47	DB	47h,	'7',	-1,		-1,		77h,	-1
	DW	OFFSET num_scan

c48	DB	48h,	'8',	-1,		-1,		-1,		-1
	DW	OFFSET num_scan

c49	DB	49h,	'9',	-1,		-1,		84h,	-1
	DW	OFFSET num_scan

c4A	DB	'-',	-1,		-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c4B	DB	4Bh,	'4',	-1,		-1,		73h,	-1
	DW	OFFSET num_scan

c4C	DB	'5',	'5',	-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c4D	DB	4Dh,	'6',	-1,		-1,		74h,	-1
	DW	OFFSET num_scan

c4E	DB	'+',	-1,		-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c4F	DB	4Fh,	'1',	-1,		-1,		75h,	-1
	DW	OFFSET num_scan

c50	DB	50h,	'2',	-1,		-1,		-1,		-1
	DW	OFFSET num_scan

c51	DB	51h,	'3',	-1,		-1,		76h,	-1
	DW	OFFSET num_scan

c52	DB	52h,	'0',	-1,		-1,		-1,		-1
	DW	OFFSET num_scan

c53	DB	53h,	',',	-1,		-1,		-1,		-1
	DW	OFFSET del_scan

c54	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c55	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c56	DB	'\',	'|',	-1,	-1,		-1,		-1
	DW	OFFSET simple_scan

c57	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c58	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET simple_scan

c59	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c5A	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c5B	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c5C	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c5D	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c5E	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c5F	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c60	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c61	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c62	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c63	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c64	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c65	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c66	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c67	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c68	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c69	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c6A	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c6B	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c6C	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c6D	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c6E	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c6F	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c70	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c71	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c72	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c73	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c74	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c75	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c76	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c77	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c78	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c79	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c7A	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c7B	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c7C	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c7D	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c7E	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c7F	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c80	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c81	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c82	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c83	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c84	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c85	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c86	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c87	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c88	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c89	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c8A	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c8B	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c8C	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c8D	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c8E	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c8F	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c90	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c91	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c92	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c93	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c94	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c95	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c96	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c97	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c98	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c99	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c9A	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c9B	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c9C	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c9D	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c9E	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

c9F	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cA0	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cA1	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cA2	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cA3	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cA4	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cA5	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cA6	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cA7	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cA8	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cA9	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cAA	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cAB	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cAC	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cAD	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cAE	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cAF	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cB0	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cB1	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cB2	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cB3	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cB4	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cB5	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cB6	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cB7	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cB8	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cB9	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cBA	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cBB	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cBC	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cBD	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cBE	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cBF	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cC0	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cC1	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cC2	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cC3	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cC4	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cC5	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cC6	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cC7	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cC8	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cC9	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cCA	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cCB	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cCC	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cCD	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cCE	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cCF	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cD0	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cD1	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cD2	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cD3	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cD4	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cD5	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cD6	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cD7	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cD8	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cD9	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cDA	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cDB	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cDC	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cDD	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cDE	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cDF	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cE0	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cE1	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cE2	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cE3	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cE4	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cE5	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cE6	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cE7	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cE8	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cE9	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cEA	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cEB	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cEC	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cED	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cEE	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cEF	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cF0	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cF1	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cF2	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cF3	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cF4	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cF5	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cF6	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cF7	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cF8	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cF9	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cFA	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cFB	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cFC	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cFD	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cFE	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

cFF	DB	-1,		-1,		-1,		-1,		-1,		-1
	DW	OFFSET dummy_scan

code	ENDS

	END
