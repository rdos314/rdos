;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Em486 CPU emulator
; Copyright (C) 1998-2000, Gilles Gate
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
; EMBUFFER.ASM
; make a circular buffer for the debbugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat
locals

		NAME embuffer
		
INCLUDE ..\core\emulate.inc
		
.data
		
;variables

startbuffer	dd ?	;pointer to the start of the buffer
endbuffer	dd ?	;pointer to the end of the buffer
setbuffer	dd ?	;current set position
readbuffer	dd ?	;current read position
full_flag	db ?	;s'ils sont tous les deux au debut il nous dit
			;si le buffer a deja été rempli au moins 1 fois

		public	initbuffer
		public	getvalue
		public	setvalue
		extrn	DisAssemble:near
		extrn	WriteRegs:near
.code



;++++=+=+=+=+=+=+=+=+=+=+=+=+=+=++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++
;		NAME:		INITBUFFER  			      +
;		PURPOSE:	Init the buffer			      +	
;		PARAMETER:	stack contains 			      +
;				(*buffer ,bufsize)		      +
;		RETURN:						      +
;								      +
;+=+=+=+++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++

initbuffer	proc	near

circularbuffer	equ	[ebp+8]
buffersize	equ	[ebp+0Ch]

	push	ebp
	mov	ebp,esp
	push	ebx
	push	ecx
	push	eax
	push	edi
	mov	eax,circularbuffer
	mov	ecx,eax
	mov	setbuffer,eax
	mov	readbuffer,eax
	mov	startbuffer,eax
	mov	ebx,buffersize 
	
	lea	ebx,[ebx*2+ebx]	;* Tprog_position_
	shl	ebx,1
	
	sub	ebx,Tprog_position_
	add	eax,ebx
	mov	endbuffer,eax
	mov	edi,ecx
	mov	ecx,buffersize 
	lea	ecx,[ecx*2+ecx]
	shl	ecx,1
	mov	ebx,ecx
	shr	ecx,4
	xor	eax,eax
@@1:
	stosd
	loop	@@1
	mov	ecx,ebx
	and	ecx,3
	rep	stosb
	
	mov	full_flag,0
	
	pop	edi
	pop	eax
	pop	ecx
	pop	ebx
	pop	ebp
	ret	8	
initbuffer	endp

;++++=+=+=+=+=+=+=+=+=+=+=+=+=+=++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++
;		NAME:		GETVALUE  			      +
;		PURPOSE:	Get the next offset		      +	
;		PARAMETER:	TCpu *Cpu in the stack 		      +
;								      +
;		RETURN:			                              +
;					                  	      +
;+=+=+=+++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++

getvalue	proc	near

Cpu	equ	[ebp+8]

	push	ebp
	mov	ebp,esp
	push	ecx
	push	esi
	push	eax
	mov	ebp,Cpu
	
	cmp	full_flag,1
	jz	short go_follow
	mov	eax,setbuffer
	sub	eax,startbuffer
	mov	cl,Tprog_position_
	div	cl
	movzx	ecx,al
	mov	eax,startbuffer
	mov	readbuffer,eax
	call	go_get_it		
	jmp	go_end
	
go_follow:	
	mov	eax,endbuffer		;imprime d'abord la partie du dessus
	sub	eax,setbuffer
	mov	cl,Tprog_position_
	div	cl
	movzx	ecx,al
	inc	ecx
	mov	eax,setbuffer
	mov	readbuffer,eax
	call	go_get_it	
	mov	eax,setbuffer		;imprime la partie du dessous
	sub	eax,startbuffer
	mov	cl,Tprog_position_
	div	cl
	movzx	ecx,al
	mov	eax,startbuffer
	mov	readbuffer,eax
	call	go_get_it	
	jmp	go_end
		
go_get_it:
	mov	esi,readbuffer
	lodsd
	mov	[ebp].reg_eip,eax
	lodsw
	mov	[ebp].reg_cs.d_selector,ax
	mov	readbuffer,esi
	push	ebp
	call	DisAssemble
	push	ebp
	call	WriteRegs
	loop	go_get_it	
	ret
go_end:	
	pop	eax
	pop	esi
	pop	ecx
	pop	ebp
	ret	4

getvalue	endp

;++++=+=+=+=+=+=+=+=+=+=+=+=+=+=++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++
;		NAME:		SETVALUE  			      +
;		PURPOSE:	Set an offset in the buffer	      +	
;		PARAMETER:	Tprog_position *position in the stack +
;								      +
;		RETURN:						      +
;								      +
;+=+=+=+++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++

setvalue	proc	near

in_value	equ [ebp+8]
	
	push	ebp
	mov	ebp,esp
	push	ebx
	push	ecx
	push	esi
	push	edi
	mov	ebx,setbuffer
	cmp	ebx,endbuffer
	jbe	short so_set_it
	mov	full_flag,1
	mov	ebx,startbuffer

so_set_it:
	mov	esi,in_value
	mov	edi,ebx
	mov	ecx,SIZE Tprog_position
	cld					;on ne sait jamais au cas où
	rep 	movsb
	mov	setbuffer,edi		
	
so_end:
	pop	edi
	pop	esi
	pop	ecx
	pop	ebx
	pop	ebp
	ret	4
setvalue	endp

	END
