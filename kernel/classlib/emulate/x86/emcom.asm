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
; EMCOM.ASM
; Common emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat

	NAME emcom

include ..\core\emulate.inc
include ..\core\emseg.inc
include ..\core\empage.inc
include ..\core\emtss.inc

	extrn ReadFromIo:near
	extrn WriteToIo:near

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadByte
;
;		DESCRIPTION:	Read one byte of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;
;		RETURNS:		AL		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadByte

ReadByte	Proc near
	push ebx
	push ecx
;
	test [ebp+esi].d_access,ACCESS_READ
	jz AccessFault
;
	mov ecx,ebx
	sub ecx,[ebp+esi].d_limit
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call ReadLinearByte
;
	pop ecx
	pop ebx
	ret
ReadByte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadWord
;
;		DESCRIPTION:	Read one word of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;
;		RETURNS:		AX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadWord

ReadWord	Proc near
	push ebx
	push ecx
;
	test [ebp+esi].d_access,ACCESS_READ
	jz AccessFault
;
	mov ecx,ebx
	inc ecx
	sub ecx,[ebp+esi].d_limit
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call ReadLinearWord
;
	pop ecx
	pop ebx
	ret
ReadWord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadDword
;
;		DESCRIPTION:	Read one dword of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;
;		RETURNS:		EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadDword

ReadDword	Proc near
	push ebx
	push ecx
;
	test [ebp+esi].d_access,ACCESS_READ
	jz AccessFault
;
	mov ecx,ebx
	add ecx,3
	sub ecx,[ebp+esi].d_limit
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call ReadLinearDword
;
	pop ecx
	pop ebx
	ret
ReadDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadFword
;
;		DESCRIPTION:	Read one 48-bit word of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;
;		RETURNS:		DX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadFword

ReadFword	Proc near
	push ebx
	push ecx
;
	test [ebp+esi].d_access,ACCESS_READ
	jz AccessFault
;
	mov ecx,ebx
	add ecx,5
	sub ecx,[ebp+esi].d_limit
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call ReadLinearFword
;
	pop ecx
	pop ebx
	ret
ReadFword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadQword
;
;		DESCRIPTION:	Read 4 word of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;
;		RETURNS:		EDX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadQword

ReadQword	Proc near
	push ebx
	push ecx
;
	test [ebp+esi].d_access,ACCESS_READ
	jz AccessFault
;
	mov ecx,ebx
	add ecx,5
	sub ecx,[ebp+esi].d_limit
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call ReadLinearQword
;
	pop ecx
	pop ebx
	ret
ReadQword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadTbyte
;
;		DESCRIPTION:	Read one tbyte of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;
;		RETURNS:		CX:EDX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadTbyte

ReadTbyte	Proc near
	push ebx
;
	test [ebp+esi].d_access,ACCESS_READ
	jz AccessFault
;
	mov ecx,ebx
	add ecx,9
	sub ecx,[ebp+esi].d_limit
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call ReadLinearTbyte
;
	pop ebx
	ret
ReadTbyte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteByte
;
;		DESCRIPTION:	Write one byte of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;						AL		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteByte

WriteByte	Proc near
	push ebx
	push ecx
;
	test [ebp+esi].d_access,ACCESS_WRITE
	jz AccessFault
;
	mov ecx,ebx
	sub ecx,[ebp+esi].d_limit
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call WriteLinearByte
;
	pop ecx
	pop ebx
	ret
WriteByte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteWord
;
;		DESCRIPTION:	Write one word of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;						AX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteWord

WriteWord	Proc near
	push ebx
	push ecx
;
	test [ebp+esi].d_access,ACCESS_WRITE
	jz AccessFault
;
	mov ecx,ebx
	inc ecx
	sub ecx,[ebp+esi].d_limit
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call WriteLinearWord
;
	pop ecx
	pop ebx
	ret
WriteWord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteDword
;
;		DESCRIPTION:	Write one dword of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;						EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteDword

WriteDword	Proc near
	push ebx
	push ecx
;
	test [ebp+esi].d_access,ACCESS_WRITE
	jz AccessFault
;
	mov ecx,ebx
	add ecx,3
	sub ecx,[ebp+esi].d_limit
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call WriteLinearDword
;
	pop ecx
	pop ebx
	ret
WriteDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteFword
;
;		DESCRIPTION:	Write one fword of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;						DX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteFword

WriteFword	Proc near
	push ebx
	push ecx
;
	test [ebp+esi].d_access,ACCESS_WRITE
	jz AccessFault
;
	mov ecx,ebx
	add ecx,5
	sub ecx,[ebp+esi].d_limit
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call WriteLinearFword
;
	pop ecx
	pop ebx
	ret
WriteFword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteQword
;
;		DESCRIPTION:	Write one qword of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;						EDX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteQword

WriteQword	Proc near
	push ebx
	push ecx
;
	test [ebp+esi].d_access,ACCESS_WRITE
	jz AccessFault
;
	mov ecx,ebx
	add ecx,7
	sub ecx,[ebp+esi].d_limit
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call WriteLinearQword
;
	pop ecx
	pop ebx
	ret
WriteQword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteTbyte
;
;		DESCRIPTION:	Write one tbyte of data
;
;		PARAMETERS:		SS:EBP	CPU
;						SS:ESI	DESCRIPTOR
;						EBX		OFFSET
;						CX:EDX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteTbyte

WriteTbyte	Proc near
	push ebx
;
	test [ebp+esi].d_access,ACCESS_WRITE
	jz AccessFault
;
	push ecx
	mov ecx,ebx
	add ecx,9
	sub ecx,[ebp+esi].d_limit
	pop ecx
	ja AccessFault
;
	add ebx,[ebp+esi].d_base
	call WriteLinearTbyte
;
	pop ebx
	ret
WriteTbyte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PushWord
;
;		DESCRIPTION:	Push word onto stack
;
;		PARAMETERS:		SS:EBP	CPU
;						AX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public PushWord

PushWord	Proc near
	push esi
	push ebx
;
	mov esi,OFFSET reg_ss
	test word ptr [ebp+esi].d_access,ACCESS_SIZE
	jz push_word16

push_word32:
	mov ebx,[ebp].reg_esp
	sub ebx,2
	push ebx
	call WriteWord
	pop ebx
	mov [ebp].reg_esp,ebx
	jmp push_word_done

push_word16:
	movzx ebx,word ptr [ebp].reg_esp
	sub bx,2
	push bx
	call WriteWord
	pop bx
	mov word ptr [ebp].reg_esp,bx

push_word_done:
	pop ebx
	pop esi
	ret
PushWord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PushDword
;
;		DESCRIPTION:	Push dword onto stack
;
;		PARAMETERS:		SS:EBP	CPU
;						EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public PushDword

PushDword	Proc near
	push esi
	push ebx
;
	mov esi,OFFSET reg_ss
	test word ptr [ebp+esi].d_access,ACCESS_SIZE
	jz push_dword16

push_dword32:
	mov ebx,[ebp].reg_esp
	sub ebx,4
	push ebx
	call WriteDword
	pop ebx
	mov [ebp].reg_esp,ebx
	jmp push_dword_done

push_dword16:
	movzx ebx,word ptr [ebp].reg_esp
	sub bx,4
	push bx
	call WriteDword
	pop bx
	mov word ptr [ebp].reg_esp,bx

push_dword_done:
	pop ebx
	pop esi
	ret
PushDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PopWord
;
;		DESCRIPTION:	pop word from stack
;
;		RETURNS:		AX		data popped
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public PopWord

PopWord	Proc near
	push esi
	push ebx
;
	mov esi,OFFSET reg_ss
	test word ptr [ebp+esi].d_access,ACCESS_SIZE
	jz pop_word16

pop_word32:
	mov ebx,[ebp].reg_esp
	push ebx
	call ReadWord
	pop ebx
	add ebx,2
	mov [ebp].reg_esp,ebx
	jmp pop_word_done

pop_word16:
	movzx ebx,word ptr [ebp].reg_esp
	push ebx
	call ReadWord
	pop ebx
	add bx,2
	mov word ptr [ebp].reg_esp,bx

pop_word_done:
	pop ebx
	pop esi
	ret
PopWord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PopDword
;
;		DESCRIPTION:	pop dword from stack
;
;		RETURNS:		EAX		data popped
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public PopDword

PopDword	Proc near
	push esi
	push ebx
;
	mov esi,OFFSET reg_ss
	test word ptr [ebp+esi].d_access,ACCESS_SIZE
	jz pop_dword16

pop_dword32:
	mov ebx,[ebp].reg_esp
	push ebx
	call ReadDword
	pop ebx
	add ebx,4
	mov [ebp].reg_esp,ebx
	jmp pop_dword_done

pop_dword16:
	movzx ebx,word ptr [ebp].reg_esp
	push ebx
	call ReadDword
	pop ebx
	add bx,4
	mov word ptr [ebp].reg_esp,bx

pop_dword_done:
	pop ebx
	pop esi
	ret
PopDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddToStack
;
;		DESCRIPTION:	add value to stack pointer
;
;		RETURNS:		EAX		value to add to (e)sp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public AddToStack

AddToStack	Proc near
	test word ptr [ebp].reg_ss.d_access,ACCESS_SIZE
	jz AddToStack16

AddToStack32:
	add [ebp].reg_esp,eax
	ret

AddToStack16:
	add word ptr [ebp].reg_esp,ax
	ret
AddToStack	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SubFromStack
;
;		DESCRIPTION:	sub value from stack pointer
;
;		RETURNS:		EAX		value to sub from (e)sp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SubFromStack

SubFromStack	Proc near
	test word ptr [ebp].reg_ss.d_access,ACCESS_SIZE
	jz SubFromStack16

SubFromStack32:
	sub [ebp].reg_esp,eax
	ret

SubFromStack16:
	sub word ptr [ebp].reg_esp,ax
	ret
SubFromStack	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadCodeByte
;
;		DESCRIPTION:	Read byte from cs:eip, update to next position
;
;		RETURNS:		AL		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadCodeByte

ReadCodeByte	Proc near
	mov esi,OFFSET reg_cs
	test word ptr [ebp+esi].d_access,ACCESS_SIZE
	jz read_code_byte16

read_code_byte32:
	mov ebx,[ebp].reg_eip
	push ebx
	call ReadByte
	pop ebx
	inc ebx
	mov [ebp].reg_eip,ebx
	ret

read_code_byte16:
	movzx ebx,word ptr [ebp].reg_eip
	push bx
	call ReadByte
	pop bx
	inc bx
	mov word ptr [ebp].reg_eip,bx
	ret
ReadCodeByte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadCodeWord
;
;		DESCRIPTION:	Read word from cs:eip, update to next position
;
;		RETURNS:		AX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadCodeWord

ReadCodeWord	Proc near
	mov esi,OFFSET reg_cs
	test word ptr [ebp+esi].d_access,ACCESS_SIZE
	jz read_code_word16

read_code_word32:
	mov ebx,[ebp].reg_eip
	push ebx
	call ReadWord
	pop ebx
	add ebx,2
	mov [ebp].reg_eip,ebx
	ret

read_code_word16:
	movzx ebx,word ptr [ebp].reg_eip
	push bx
	call ReadWord
	pop bx
	add bx,2
	mov word ptr [ebp].reg_eip,bx
	ret
ReadCodeWord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadCodeDword
;
;		DESCRIPTION:	Read dword from cs:eip, update to next position
;
;		RETURNS:		EAX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadCodeDword

ReadCodeDword	Proc near
	mov esi,OFFSET reg_cs
	test word ptr [ebp+esi].d_access,ACCESS_SIZE
	jz read_code_dword16

read_code_dword32:
	mov ebx,[ebp].reg_eip
	push ebx
	call ReadDword
	pop ebx
	add ebx,4
	mov [ebp].reg_eip,ebx
	ret

read_code_dword16:
	movzx ebx,word ptr [ebp].reg_eip
	push bx
	call ReadDword
	pop bx
	add bx,4
	mov word ptr [ebp].reg_eip,bx
	ret
ReadCodeDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadCodeFword
;
;		DESCRIPTION:	Read fword from cs:eip, update to next position
;
;		RETURNS:		DX:EAX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadCodeFword

ReadCodeFword	Proc near
	mov esi,OFFSET reg_cs
	test word ptr [ebp+esi].d_access,ACCESS_SIZE
	jz read_code_fword16

read_code_fword32:
	mov ebx,[ebp].reg_eip
	push ebx
	call ReadFword
	pop ebx
	add ebx,6
	mov [ebp].reg_eip,ebx
	ret

read_code_fword16:
	movzx ebx,word ptr [ebp].reg_eip
	push bx
	call ReadFword
	pop bx
	add bx,6
	mov word ptr [ebp].reg_eip,bx
	ret
ReadCodeFword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InPort
;
;		description:	read from I/O port
;
;		PARAMETERS:		SS:EBP		CPU
;						DX			IO PORT
;						SS:ESI		BUFFER
;						ECX			SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InPort

InPort Proc near
	push ecx
	push edx
	push esi
	push ebp
	call ReadFromIo
	ret
InPort	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OutPort
;
;		description:	write to I/O port
;
;		PARAMETERS:		SS:EBP		CPU
;						DX			IO PORT
;						SS:ESI		BUFFER
;						ECX			SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public OutPort

OutPort Proc near
	push ecx
	push edx
	push esi
	push ebp
	call WriteToIo
	ret
OutPort	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Inbyte
;
;		description:	read a byte from I/O port
;
;		PARAMETERS:		SS:EBP		CPU
;						DX			IO PORT
;
;		RETURNS:		AL			DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InByte

InByte Proc near
	push ecx
	push esi
;
	test [ebp].reg_cr0,CR0_PE
	jz InByteDo
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz InByteVm
;
	mov ecx,[ebp].reg_eflags
	ror cx,4
	mov	ch,[ebp].reg_cs.d_access
	and cx,303h
	cmp cl,ch
	jnc InByteDo
;
	mov ecx,1
	call CheckBitmap
	jmp InByteDo

InByteVm:
	mov ecx,1
	call CheckBitmap

InByteDo:
	mov ecx,1
	lea esi,[ebp].req_buf
	call InPort
	lea esi,[ebp].req_buf
	mov al,[esi]
;
	pop esi
	pop ecx
	ret
InByte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InWord
;
;		description:	read a word from I/O port
;
;		PARAMETERS:		SS:EBP		CPU
;						DX			IO PORT
;
;		RETURNS:		AX			DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InWord

InWord Proc near
	push ecx
	push esi
;
	test [ebp].reg_cr0,CR0_PE
	jz InWordDo
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz InWordVm
;
	mov ecx,[ebp].reg_eflags
	ror cx,4
	mov	ch,[ebp].reg_cs.d_access
	and cx,303h
	cmp cl,ch
	jnc InWordDo
;
	mov ecx,2
	call CheckBitmap
	jmp InWordDo

InWordVm:
	mov ecx,2
	call CheckBitmap

InWordDo:
	mov ecx,2
	lea esi,[ebp].req_buf
	call InPort
	lea esi,[ebp].req_buf
	mov ax,[esi]
;
	pop esi
	pop ecx
	ret
InWord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InDword
;
;		description:	read a dword from I/O port
;
;		PARAMETERS:		SS:EBP		CPU
;						DX			IO PORT
;
;		RETURNS:		EAX			DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InDword

InDword Proc near
	push ecx
	push esi
;
	test [ebp].reg_cr0,CR0_PE
	jz InDwordDo
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz InDwordVm
;
	mov ecx,[ebp].reg_eflags
	ror cx,4
	mov	ch,[ebp].reg_cs.d_access
	and cx,303h
	cmp cl,ch
	jnc InDwordDo
;
	mov ecx,4
	call CheckBitmap
	jmp InDwordDo

InDwordVm:
	mov ecx,4
	call CheckBitmap

InDwordDo:
	mov ecx,4
	lea esi,[ebp].req_buf
	call InPort
	lea esi,[ebp].req_buf
	mov eax,[esi]
;
	pop esi
	pop ecx
	ret
InDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OutByte
;
;		description:	write a byte to I/O port
;
;		PARAMETERS:		SS:EBP		CPU
;						DX			IO PORT
;						AL			DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public OutByte

OutByte Proc near
	push ecx
	push esi
;
	test [ebp].reg_cr0,CR0_PE
	jz OutByteDo
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz OutByteVm
;
	mov ecx,[ebp].reg_eflags
	ror cx,4
	mov	ch,[ebp].reg_cs.d_access
	and cx,303h
	cmp cl,ch
	jnc OutByteDo
;
	mov ecx,1
	call CheckBitmap
	jmp OutByteDo

OutByteVm:
	mov ecx,1
	call CheckBitmap

OutByteDo:
	lea esi,[ebp].req_buf
	mov [esi],al
	mov ecx,1
	call OutPort
;
	pop esi
	pop ecx
	ret
OutByte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OutWord
;
;		description:	write a word to I/O port
;
;		PARAMETERS:		SS:EBP		CPU
;						DX			IO PORT
;						AX			DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public OutWord

OutWord Proc near
	push ecx
	push esi
;
	test [ebp].reg_cr0,CR0_PE
	jz OutWordDo
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz OutWordVm
;
	mov ecx,[ebp].reg_eflags
	ror cx,4
	mov	ch,[ebp].reg_cs.d_access
	and cx,303h
	cmp cl,ch
	jnc OutWordDo
;
	mov ecx,2
	call CheckBitmap
	jmp OutWordDo

OutWordVm:
	mov ecx,2
	call CheckBitmap

OutWordDo:
	lea esi,[ebp].req_buf
	mov [esi],ax
	mov ecx,2
	call OutPort
;
	pop esi
	pop ecx
	ret
OutWord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OutDword
;
;		description:	write a dword to I/O port
;
;		PARAMETERS:		SS:EBP		CPU
;						DX			IO PORT
;						EAX			DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public OutDword

OutDword Proc near
	push ecx
	push esi
;
	test [ebp].reg_cr0,CR0_PE
	jz OutDwordDo
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz OutDwordVm
;
	mov ecx,[ebp].reg_eflags
	ror cx,4
	mov	ch,[ebp].reg_cs.d_access
	and cx,303h
	cmp cl,ch
	jnc OutDwordDo
;
	mov ecx,4
	call CheckBitmap
	jmp OutDwordDo

OutDwordVm:
	mov ecx,4
	call CheckBitmap

OutDwordDo:
	lea esi,[ebp].req_buf
	mov [esi],eax
	mov ecx,4
	call OutPort
;
	pop esi
	pop ecx
	ret
OutDword	Endp

	END
