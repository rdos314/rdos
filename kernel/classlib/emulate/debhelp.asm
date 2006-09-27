;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Em486 CPU emulator
; Copyright (C) 1998-2000, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage. For information on commercial usage,
; contact em486@rdos.net.
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
; DEBHELP.ASM
; Debug helpers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat
						
		NAME  DEBHELP

.data

FloatBuffer DB 40 DUP(?)

.code

	extrn ShowChar:near
	extrn ShowSizeString:near
	extrn ShowAsciiz:near
	extrn FloatToString:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IntToStr
;
;		DESCRIPTION:	Convert long to asciiz string
;
;		PARAMETERS:		EAX			Number
;						ECX			Positions
;						EDI			String
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_tab:
	DD 1
	DD 10
	DD 100
	DD 1000
	DD 10000
	DD 100000
	DD 1000000
	DD 10000000
	DD 100000000
	DD 1000000000

	public IntToStr

IntToStr	PROC near
	push ax
	push bx
	push ecx
	push edx
	push edi
	mov edx,eax
	mov ah,cl
	mov ebx,ecx
	dec ebx
	shl ebx,2
loop_omv_dec:
	mov ecx,dword ptr [ebx].dec_tab
	xor al,al
loop_dec_dig:
	inc al
	sub edx,ecx
	jnc loop_dec_dig
	add edx,ecx
	dec al
	sub ebx,4
	add al,'0'
	stosb
	dec ah
	jne loop_omv_dec
	xor al,al
	stosb
	pop edi
	pop edx
	pop ecx
	pop bx
	pop ax
	ret
IntToStr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RemoveLeading
;
;		DESCRIPTION:	Remove leading zeros
;
;		PARAMETERS:		EDI		String
;
;		RETURNS:		CY		Significant digits found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RemoveLeading

RemoveLeading	Proc near
	push ax
	push edi
RemoveLeadingLoop:
	mov al,[edi]
	or al,al
	clc
	jz RemoveLeadingDone
	cmp al,'0'
	stc
	jnz RemoveLeadingDone
	mov byte ptr [edi],' '
	inc edi
	jmp RemoveLeadingLoop
RemoveLeadingDone:
	pop edi
	pop ax
	ret
RemoveLeading	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteChar
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AL		char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteChar

WriteChar	Proc near
	pushad
	push eax
	call ShowChar
	popad
	ret
WriteChar	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteSizeString
;
;		DESCRIPTION:	
;
;		PARAMETERS:		EDI			string
;						ECX			number of chars
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteSizeString

WriteSizeString	Proc near
	pushad
	push ecx
	push edi
	call ShowSizeString
	popad
	ret
WriteSizeString	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteAsciiz
;
;		DESCRIPTION:	
;
;		PARAMETERS:		EDI		string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteAsciiz
    
WriteAsciiz	Proc near
	pushad
	push edi
	call ShowAsciiz
	popad
	ret
WriteAsciiz	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NewLine
;
;		DESCRIPTION:	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public NewLine

NewLine	Proc near
	push ax
	mov al,13
	call WriteChar
	mov al,10
	call WriteChar
	pop ax
	ret
NewLine	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Delimiter
;
;		DESCRIPTION:	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public Delimiter
    
Delimiter	Proc near
	push ax
	push ecx
	mov ecx,60
	mov al,'-'
write_delim_loop:
	call WriteChar
	loop write_delim_loop
	pop ecx
	call NewLine
	pop ax
	ret
Delimiter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Blank
;
;		DESCRIPTION:	
;
;		PARAMETERS:		ECX		Number of blanks to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public Blank

Blank	Proc near
    test ecx,80000000h
    jnz blank_done
;
	push ax
	push ecx
	mov al,' '
blank_loop:
	call WriteChar
	loop blank_loop
	pop ecx
	pop ax

blank_done:
	ret
Blank	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexByte
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AL		Val
;						AX		Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

singel_hex	PROC near
hex_conv_low:
	mov ah,al
	and al,0F0h
	rol al,1
	rol al,1
	rol al,1
	rol al,1
	cmp al,0Ah
	jb ok_low1
	add al,7
ok_low1:
	add al,30h
	and ah,0Fh
	cmp ah,0Ah
	jb ok_high1
	add ah,7
ok_high1:
	add ah,30h
	ret
singel_hex	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexByte
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AL		DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteHexByte

WriteHexByte	PROC near
	push ax
	mov ah,al
	and al,0F0h
	rol al,4
	cmp al,0Ah
	jb write_byte_low1
	add al,7
write_byte_low1:
	add al,'0'
	call WriteChar
	mov al,ah
	and al,0Fh
	cmp al,0Ah
	jb write_byte_high1
	add al,7
write_byte_high1:
	add al,'0'
	call WriteChar
	pop ax
	ret
WriteHexByte	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexWord
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AX		DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteHexWord

WriteHexWord	PROC near
	xchg al,ah
	call WriteHexByte
	xchg al,ah
	call WriteHexByte
	ret
WriteHexWord	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexDword
;
;		DESCRIPTION:	
;
;		PARAMETERS:		EAX		DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteHexDword
    
WriteHexDword	PROC near
	rol eax,8
	call WriteHexByte
	rol eax,8
	call WriteHexByte
	rol eax,8
	call WriteHexByte
	rol eax,8
	call WriteHexByte
	ret
WriteHexDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexPtr16
;
;		DESCRIPTION:	
;
;		PARAMETERS:		DX		SEGMENT
;						BX		OFFSET
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteHexPtr16
    
WriteHexPtr16	PROC near
	push ax
	mov ax,dx
	call WriteHexWord
	mov al,':'
	call WriteChar
	mov ax,bx
	call WriteHexWord
	pop ax
	ret
WriteHexPtr16	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexPtr32
;
;		DESCRIPTION:	
;
;		PARAMETERS:		DX		SEGMENT
;						EBX		OFFSET
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteHexPtr32
    
WriteHexPtr32	PROC near
	push eax
	mov ax,dx
	call WriteHexWord
	mov al,':'
	call WriteChar
	mov eax,ebx
	call WriteHexDword
	pop eax
	ret
WriteHexPtr32	ENDP

	END
