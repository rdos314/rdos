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
; USER32.ASM
; 32-bit user32.dll emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  user32

;;;;;;;;; INTERNAL ProcEDURES ;;;;;;;;;;;

.386p
.model flat

include ..\os\user.def

UserGate	MACRO gate_nr
	db 0Fh
	db 0Bh
	db 0D7h
	dd gate_nr
	nop
			ENDM

.code
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DllMain
;
;       DESCRIPTION:    DLL entry point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DllMain Proc near
	mov	eax, 1
	ret 12
dllMain Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           Borland32
;
;       DESCRIPTION:    Borland32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public Borland32

Borland32:
	int 3
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           EnumThreadWindows
;
;       DESCRIPTION:    Enum thread Windows
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EnumThreadWindows

EnumThreadWindows Proc near
	mov eax, 1
	ret 12
EnumThreadWindows Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CharUpperBuff
;
;       DESCRIPTION:   	Convert chars to uppercase
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CharUpperBuffA

cubBuf		EQU 8
cubSize		EQU 12

UCaseTab:
ct00 DB	0,		0,		0,		0,		0,		0,		0,		0
ct08 DB	0,		0,		0,		0,		0,		0,		0,		0
ct10 DB	0,		0,		0,		0,		0,		0,		0,		0
ct18 DB	0,		0,		0,		0,		0,		0,		0,		0
ct20 DB ' ',	'!',	0,		'#',	'$',	'%',	'&',	27h
ct28 DB '(',	')',	0,		0,		0,		'-',	0,		'/'
ct30 DB '0',	'1',	'2',	'3',	'4',	'5',	'6',	'7'
ct38 DB '8',	'9',	0,		0,		0,		0,		0,		0
ct40 DB '@',	'A',	'B',	'C',	'D',	'E',	'F',	'G'
ct48 DB 'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O'
ct50 DB 'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W'
ct58 DB	'X',	'Y',	'Z',	0,		'\',	0,		'^',	'_'
ct60 DB 60h,	'A',	'B',	'C',	'D',	'E',	'F',	'G'
ct68 DB 'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O'
ct70 DB 'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W'
ct78 DB 'X',	'Y',	'Z',	'{',	0,		'}',	'~',	0
ct80 DB	0,		0,		0,		0,		'é',	0,		'è',	0
ct88 DB	0,		0,		0,		0,		0,		0,		'é',	'è'
ct90 DB	0,		0,		0,		0,		'ô',	0,		0,		0
ct98 DB	0,		'ô',	0,		0,		0,		0,		0,		0
ctA0 DB	0,		0,		0,		0,		0,		0,		0,		0
ctA8 DB	0,		0,		0,		0,		0,		0,		0,		0
ctB0 DB	0,		0,		0,		0,		0,		0,		0,		0
ctB8 DB	0,		0,		0,		0,		0,		0,		0,		0
ctC0 DB	0,		0,		0,		0,		0,		0,		0,		0
ctC8 DB	0,		0,		0,		0,		0,		0,		0,		0
ctD0 DB	0,		0,		0,		0,		0,		0,		0,		0
ctD8 DB	0,		0,		0,		0,		0,		0,		0,		0
ctE0 DB	0,		0,		0,		0,		0,		0,		0,		0
ctE8 DB	0,		0,		0,		0,		0,		0,		0,		0
ctF0 DB	0,		0,		0,		0,		0,		0,		0,		0
ctF8 DB	0,		0,		0,		0,		0,		0,		0,		0

CharUpperBuffA Proc near
	push ebp
	mov ebp,esp
;
	xor eax,eax
	mov ecx,[ebp].cubSize
	mov edx,[ebp].cubBuf
cubLoop:
	mov al,[edx]
	mov al,byte ptr [eax].UCaseTab
	or al,al
	jnz cubOk
	mov al,[edx]
cubOk:
	mov [edx],al
	inc edx
	loop cubLoop
	mov eax,[ebp].cubSize	
;
	pop ebp
	ret 8
CharUpperBuffA ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MessageBox
;
;       DESCRIPTION:    Message box
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public MessageBoxA

MessageBoxA Proc near
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+16]
	UserGate write_asciiz_nr
	mov al,0Dh
	UserGate write_char_nr
	mov al,0Ah
	UserGate write_char_nr
;
	mov edi,[ebp+12]
	UserGate write_asciiz_nr
	mov al,0Dh
	UserGate write_char_nr
	mov al,0Ah
	UserGate write_char_nr
	mov eax, 1
;
	pop edi
	pop ebp
	ret 16
MessageBoxA Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetKeyboardType
;
;       DESCRIPTION:    Get keyboard type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetKeyboardType

GetKeyboardType Proc near
	mov eax, 4
	cmp byte ptr [esp+4], 2
	jz short gkbt00
	mov eax, 12

gkbt00:
	ret 4
GetKeyboardType Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSystemMetrics
;
;       DESCRIPTION:    Get system metrics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetSystemMetrics

GetSystemMetrics Proc near
	sub eax, eax
	ret 4
GetSystemMetrics Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LoadString
;
;       DESCRIPTION:    Load string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadStringA

LoadStringA Proc near
	int 3
	xor eax,eax
	ret 16
LoadStringA Endp

END DllMain
