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

include ..\user.def

UserGate	MACRO gate_nr
	db 9Ah
	dd gate_nr
	dw 2
			ENDM

.data

pCodePage	dd OFFSET genericCP

.data?
    
genericCP	dw 256 dup (?)

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
	pushad
	mov	edx, OFFSET genericCP
	sub	eax, eax

initGCP:
	mov	[edx], ax
	inc	edx
	inc	edx
	inc	al
	jnz	initGCP
;
    popad
	mov	eax, 1
	ret 12
dllMain Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           nlsCharToOEMA
;
;       DESCRIPTION:    character conversion
;
;   	In:  AL =  lower byte of double byte character
;
;       Out: EAX = OEM single byte character
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nlsCharToOEMA PROC near
	movzx eax, al
	push edx
	push ecx
	mov	edx, pCodePage
	mov	ecx, 256

C2OA:
	cmp	al, [edx]
	je	C2OAfound

	add	edx, 2
	loop C2OA

	jmp	C2OAexit

C2OAfound:
	mov	eax, edx
	sub	eax, pCodePage
	shr	eax, 1

C2OAexit:
	pop	ecx
	pop	edx
	ret
nlsCharToOEMA ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           nlsCharToOEMW
;
;       DESCRIPTION:    character conversion
;
;   	In:  AX =  double byte character
;
;       Out: EAX = OEM single byte character
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nlsCharToOEMW PROC near
	movzx eax, ax
	push edx
	push ecx
	mov	edx, pCodePage
	mov	ecx, 256

C2OW:
	cmp	ax, [edx]
	je	C2OWfound

	add	edx, 2
	loop	C2OW

	jmp	C2OWexit

C2OWfound:
	mov	eax, edx
	sub	eax, pCodePage
	shr	eax, 1

C2OWexit:
	sub	ah, ah
	pop	ecx
	pop	edx
	ret
nlsCharToOEMW ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           nlsOEMToChar
;
;       DESCRIPTION:    character conversion
;
;	    In:  AL =  OEM character
;
;       Out: EAX = double byte character
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nlsOEMToChar PROC near
	push edx
	mov	edx, pCOdePage
	and	eax, 0FFh
	mov	ax, [edx + eax * 2]
	pop	edx
	ret
nlsOEMToChar ENDP
	
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
;       NAME:           DestroyWindow
;
;       DESCRIPTION:    Destroy window
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public DestroyWindow

DestroyWindow PROC near
	mov	eax, 1
	ret 4
DestroyWindow ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CharNextA
;
;       DESCRIPTION:    Char next
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CharNextA

CharNextA PROC near
	mov	eax, [esp + 4]
	cmp	byte ptr [eax], 1       ; CF set if 0
	sbb	eax, -1			; Increment if [eax] != 0
	ret 4
CharNextA ENDP
	
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
;       NAME:           IsCharAlphaNumericA
;
;       DESCRIPTION:    Is char alphanum?
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IsCharAlphaNumericA

IsCharAlphaNumericA PROC near
	movzx eax, byte ptr [esp + 4]
	cmp	al, '0'
	jc	ica_no

	cmp	al, '9'
	jna	ica_yes

	cmp	al, 'A'
	jc	ica_no

	cmp	al, 'Z'
	jna	ica_yes

	cmp	al, 'a'
	jc	ica_no

	cmp	al, 'z'
	jna	ica_yes

ica_no:
	sub	eax, eax
	ret 4

ica_yes:
	mov	eax, 1
	ret 4
IsCharAlphaNumericA ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CharToOemBuffA
;
;       DESCRIPTION:    character conversion
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CharToOemBuffA

CharToOemBuffA PROC near
	pushad
	mov	esi, [esp + 32 + 4]
	mov	edi, [esp + 32 + 8]
	mov	ecx, [esp + 32 + 12]
	jecxz	c2obAexit

c2obA:
	mov	al, [esi]
	inc	esi
	call nlsCharToOEMA
	mov	[edi], al
	inc	edi
	loop	c2obA

c2obAexit:
	popad
	mov	eax, 1
	ret 12
CharToOemBuffA ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CharToOemBuffW
;
;       DESCRIPTION:    character conversion
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CharToOemBuffW

CharToOemBuffW PROC near
	pushad
	mov	esi, [esp + 32 + 4]
	mov	edi, [esp + 32 + 8]
	mov	ecx, [esp + 32 + 12]
	jecxz	c2obWexit

c2obW:
	mov	ax, [esi]
	inc	esi
	inc	esi
	call nlsCharToOEMW
	mov	[edi], al
	inc	edi
	loop	c2obW

c2obWexit:
	popad
	mov	eax, 1
	ret 12
CharToOemBuffW ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OemToCharBuffA
;
;       DESCRIPTION:    character conversion
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public OemToCharBuffA

OemToCharBuffA PROC near
	pushad
	mov	esi, [esp + 32 + 4]
	mov	edi, [esp + 32 + 8]
	mov	ecx, [esp + 32 + 12]
	jecxz o2cbAexit

o2cbA:
	mov	al, [esi]
	inc	esi
	call nlsOEMToCHar
	mov	[edi], al
	inc	edi
	loop o2cbA

o2cbAexit:
	popad
	mov	eax, 1
	ret 12
OemToCharBuffA ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OemToCharBuffW
;
;       DESCRIPTION:    character conversion
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public OemToCharBuffW

OemToCharBuffW PROC near
	pushad
	mov	esi, [esp + 32 + 4]
	mov	edi, [esp + 32 + 8]
	mov	ecx, [esp + 32 + 12]
	jecxz	o2cbWexit

o2cbW:
	mov	al, [esi]
	inc	esi
	call nlsOEMToChar
	mov	[edi], ax
	inc	edi
	inc	edi
	loop o2cbW

o2cbWexit:
	popad
	mov	eax, 1
	ret 12
OemToCharBuffW ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OemToCharA
;
;       DESCRIPTION:    character conversion
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public OemToCharA

OemToCharA PROC near
	mov	edx, [esp + 4]
	mov	ecx, [esp + 8]

o2caLoop:
	mov	al, [edx]
	inc	edx
	call nlsOEMToChar
	mov	[ecx], al
	inc	ecx
	test al, al
	jne	o2caLoop

	mov	eax, 1
	ret 8
OemToCharA ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OemToCharW
;
;       DESCRIPTION:    character conversion
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public OemToCharW

OemToCharW PROC near
	mov	edx, [esp + 4]
	mov	ecx, [esp + 8]

o2cwLoop:
	mov	al, [edx]
	inc	edx
	call nlsOEMToChar
	mov	[ecx], ax
	inc	ecx
	inc	ecx
	test al, al
	jne	o2cwLoop

	mov	eax, 1
	retn 8
OemToCharW ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CharToOemA
;
;       DESCRIPTION:    character conversion
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CharToOemA

CharToOemA PROC near
	mov	edx, [esp + 4]
	mov	ecx, [esp + 8]

c2oaLoop:
	mov	al, [edx]
	inc	edx
	call nlsCharToOEMA
	mov	[ecx], al
	inc	ecx
	test al, al
	jne	c2oaLoop

	mov	eax, 1
	ret 8
CharToOemA ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CharToOemW
;
;       DESCRIPTION:    character conversion
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CharToOemW

CharToOemW PROC near
	mov	edx, [esp + 4]
	mov	ecx, [esp + 8]

c2owLoop:
	mov	ax, [edx]
	inc	edx
	inc	edx
	call nlsCharToOEMW
	mov	[ecx], al
	inc	ecx
	test al, al
	jne	c2owLoop

	mov	eax, 1
	ret 8
CharToOemW ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           EnumWindows
;
;       DESCRIPTION:    Enum Windows
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EnumWindows

EnumWindows Proc near
	int 3
	mov eax, 1
	ret 8
EnumWindows Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetClassNameA
;
;       DESCRIPTION:    Get class name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetClassNameA

GetClassNameA Proc near
	int 3
	mov eax, 0
	ret 12
GetClassNameA Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetForegroundWindow
;
;       DESCRIPTION:    Get foreground window
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetForegroundWindow

GetForegroundWindow Proc near
	int 3
	mov eax, 12345678h
	ret
GetForegroundWindow Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetWindowTextA
;
;       DESCRIPTION:    Get window text
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetWindowTextA

GetWindowTextA Proc near
	int 3
	mov eax, 1
	ret 12
GetWindowTextA Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetWindowThreadProcessId
;
;       DESCRIPTION:    Get window thread process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetWindowThreadProcessId

GetWindowThreadProcessId Proc near
	int 3
	mov eax, 23456789h
	ret 8
GetWindowThreadProcessId Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsIconic
;
;       DESCRIPTION:    Is iconic?
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IsIconic

IsIconic Proc near
	int 3
	xor eax,eax
	ret 4
IsIconic Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsWindow
;
;       DESCRIPTION:    Is window?
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IsWindow

IsWindow Proc near
	int 3
	xor eax,eax
	ret 4
IsWindow Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetForegroundWindow
;
;       DESCRIPTION:    Set foreground window
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetForegroundWindow

SetForegroundWindow Proc near
	int 3
	mov eax,1
	ret 4
SetForegroundWindow Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CharUpperBuff
;
;       DESCRIPTION:   	Convert chars to uppercase
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CharUpperBuffA

CharUpperBuffA PROC near
	pushad
	xor	edx, edx
	mov	ecx, [esp+8+32]
	or	ecx, ecx
	jz	cub2

	mov	esi, [esp+4+32]
	mov	edi, esi

cub0:
	mov	al, [esi]
	inc	esi
	cmp	al, 0
	jz	cub2

	cmp	al, 'a'
	jb	cub1

	cmp	al, 'z'
	ja	cub1

	sub	al, 'a'-'A'

cub1:
	mov	[edi], al
	inc	edi
	inc	edx
	dec	ecx
	jnz	cub0

cub2:
	mov	[esp+28], edx
	popad
	ret 8
CharUpperBuffA ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CharUpperA
;
;       DESCRIPTION:   	Convert chars to uppercase
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CharUpperA

CharUpperA PROC near
    pop	ecx
	pop	edx
	mov	eax, edx
	test	edx, 0FFFF0000h
	jnz	cuDoString

	cmp	dl, 'a'
	jc	cuDone

	cmp	dl, 'z'
	ja	cuDone

	add	al, 'A' - 'a'

cuDone:
	jmp	ecx

cuDoString:
	cmp	byte ptr [edx], 0
	je	cuDone

	cmp	byte ptr [edx], 'a'
	jc	cuNext
		
	cmp	byte ptr [edx], 'z'
	ja	cuNext

	add	byte ptr [edx], 'A' - 'a'

cuNext:
	inc	edx
	jmp	cuDoString

CharUpperA ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CharLowerA
;
;       DESCRIPTION:   	Convert chars to lowercase
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CharLowerA

CharLowerA PROC near
	pop	ecx
	pop	edx
	mov	eax, edx
	test	edx, 0FFFF0000h
	jnz	clDoString

	cmp	dl, 'A'
	jc	clDone

	cmp	dl, 'Z'
	ja	clDone

	add	al, 'a' - 'A'

clDone:
	jmp	ecx

clDoString:
	cmp	BYTE PTR [edx], 0
	je	clDone

	cmp	BYTE PTR [edx], 'A'
	jc	clNext
		
	cmp	BYTE PTR [edx], 'Z'
	ja	clNext

	add	BYTE PTR [edx], 'a' - 'A'

clNext:
	inc	edx
	jmp	clDoString

CharLowerA ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CharLowerBuffA
;
;       DESCRIPTION:   	Convert chars to lowercase
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CharLowerBuffA

CharLowerBuffA PROC near
	pushad
	xor	edx, edx
	mov	ecx, [esp+8+32]
	or	ecx, ecx
	jz	clb2

	mov	esi, [esp+4+32]
	mov	edi, esi

clb0:
	mov	al, [esi]
	inc	esi
	cmp	al, 0
	jz	clb2

	cmp	al, 'A'
	jb	clb1

	cmp	al, 'Z'
	ja	clb1

	sub	al, 'A'-'a'

clb1:
	mov	[edi], al
	inc	edi
	inc	edx
	dec	ecx
	jnz	clb0

clb2:
	mov	[esp+28], edx
	popad
	ret 8
CharLowerBuffA ENDP
	
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
;       NAME:           MessageBoxExA
;
;       DESCRIPTION:    Message box
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public MessageBoxExA

MessageBoxExA PROC near
	pop	eax		; return address
	pop	edx		; hWnd
	mov	[esp + 12], eax
	call MessageBoxA	
	ret
MessageBoxExA ENDP
	
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
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           wsprintfA
;
;       DESCRIPTION:    Partial implementation of wsprintf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public wsprintfA

wsprintfA PROC near
	pushad
	cld
	mov	esi, [esp + 8 +  32]		; source
	mov	edi, [esp + 4 +  32]		; destination
	lea	ebx, [esp + 12 + 32]		; argument list

wsp01:
	mov	ebp, OFFSET wsTable_nomofifier
	sub	eax, eax
	lodsb
	cmp	al, '%'
	je	wsp02

	test	al, al
	jne	wsp03

	stosb
	lea	eax, [edi - 1]
	sub	eax, [esp + 4 + 32]
	mov	[esp + 28], eax
	popad
	retn

wsp02:
	lodsb
	cmp	al, '%'
	jne	wsp04

wsp03:
	stosb
	jmp	wsp01

wsp07:
	lodsb

wsp04:
	cmp	al, '0'
	jb	wsp06
	cmp	al, '9'
	jbe	wsp07
wsp06:
	mov	edx, OFFSET wsTable_codes

wsp05:
	cmp	BYTE PTR [edx], 0
	je	wsp03

	cmp	al, [edx]
	lea	edx, [edx + 1]
	jne	wsp05

	sub	edx, OFFSET wsTable_codes
	jmp	DWORD PTR [ebp + edx * 4 - 4]


; -------------------------------

outChar:
	mov	al, [ebx]
	test	al, al
	jz	wsNextArg

	stosb
	jmp	wsNextArg

; -------------------------------

outWChar:
	mov	ax, [ebx]
	test	ax, ax
	jz	wsNextArg

	call	nlsCharToOEMW
	stosb
	jmp	wsNextArg

; -------------------------------

outString:
	push	esi
	mov	esi, [ebx]

wsOsNext:
	lodsb
	test	al, al
	jz	wsOsDone

	stosb
	jmp	wsOsNext

wsOsDone:
	pop	esi
	jmp	wsNextArg

; -------------------------------

outWString:
	push	esi
	mov	esi, [ebx]

wsOswNext:
	lodsw
	test	ax, ax
	jz	wsOswDone

	call	nlsCharToOEMW
	stosb
	jmp	wsOswNext

wsOswDone:
	pop	esi
	jmp	wsNextArg

; -------------------------------

outInteger:
	mov	eax, [ebx]
	test	eax, eax
	jns	outUsEAX

	neg	eax
	mov	BYTE PTR [edi], '-'
	inc	edi
	jmp	outUsEAX

; -------------------------------

outUnsigned:
	mov	eax, [ebx]

outUsEAX:
	push	ebx
	mov	ebx, 10
	call	NextDigit
	pop	ebx
	jmp	wsNextArg

; -------------------------------

outHexLower:
	mov	ebp, OFFSET htable_l	
	jmp	outHex

; -------------------------------

outHexUpper:
	mov	ebp, OFFSET htable_h

outHex:
	mov	edx, [ebx]
	mov	ecx, 8

outHexLoop:
	sub	eax, eax
	shld	eax, edx, 4
	shl	edx, 4
	mov	al, [ebp + eax]
	stosb
	loop	outHexLoop

	jmp	wsNextArg

; -------------------------------

setLTable:
	mov	ebp, OFFSET wsTable_l
	jmp	wsp07

setHTable:
	mov	ebp, OFFSET wsTable_h
	jmp	wsp07	

ignoreChar:
	jmp	wsp07	

wsNextArg:
	add	ebx, 4
	jmp	wsp01


wsTable_codes LABEL BYTE
	db	'cCsSdiuxXlh-#.'
	db	0

	align DWORD

wsTable_nomofifier LABEL DWORD
	dd	OFFSET outChar
	dd	OFFSET outWChar
	dd	OFFSET outString
	dd	OFFSET outWString
	dd	OFFSET outInteger
	dd	OFFSET outInteger
	dd	OFFSET outUnsigned
	dd	OFFSET outHexLower
	dd	OFFSET outHexUpper
	dd	OFFSET setLTable
	dd	OFFSET setHTable
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar

wsTable_l LABEL DWORD
	dd	OFFSET outWChar
	dd	OFFSET outWChar
	dd	OFFSET outWString
	dd	OFFSET outWString
	dd	OFFSET outInteger
	dd	OFFSET outInteger
	dd	OFFSET outUnsigned
	dd	OFFSET outHexLower
	dd	OFFSET outHexUpper
	dd	OFFSET setLTable
	dd	OFFSET setHTable
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar

wsTable_h LABEL DWORD
	dd	OFFSET outChar
	dd	OFFSET outChar
	dd	OFFSET outString
	dd	OFFSET outString
	dd	OFFSET outInteger
	dd	OFFSET outInteger
	dd	OFFSET outUnsigned
	dd	OFFSET outHexLower
	dd	OFFSET outHexUpper
	dd	OFFSET setLTable
	dd	OFFSET setHTable
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar
	dd	OFFSET ignoreChar

htable_l LABEL BYTE
	db	'0123456789abcdef'

htable_h LABEL BYTE
	db	'0123456789ABCDEF'

wsprintfA ENDP

;----------------------------------------------------------------------------
; Helper for wsprintfA
;
NextDigit PROC NEAR

	xor	edx, edx
	div	ebx
	test	eax, eax
	push	edx
	jz	@@all

	call	NextDigit

@@all:
	pop	eax
	add	al, 30h
	stosb
	retn

NextDigit ENDP


END DllMain
