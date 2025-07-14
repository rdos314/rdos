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
; EMCONTROL.ASM
; Control transfer functions for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.386p

include emulate.inc
include emcom.inc
include emmem.inc
include emseg.inc

code	SEGMENT byte public use16 'CODE'

	assume cs:code

JccShort	Macro op

	public Em&op&Short

Em&op&Short	Proc near
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	&op Em&op&ShortJump
	call ReadCodeByte
	ret

Em&op&ShortJump:
	call ReadCodeByte
	test byte ptr [ebp].em_flags,cs32
	jz Em&op&ShortJump16

Em&op&ShortJump32:
	movsx eax,al
	add eax,[ebp].reg_eip
	mov [ebp].reg_eip,eax
	mov ebx,eax
	mov si,OFFSET reg_cs
	call ReadByte
	ret

Em&op&ShortJump16:
	movsx ax,al
	add ax,word ptr [ebp].reg_eip
	mov word ptr [ebp].reg_eip,ax
	movzx ebx,ax
	mov si,OFFSET reg_cs
	call ReadByte
	ret
Em&op&Short	Endp

		Endm

JecxShort	Macro op

	public Em&op&Short

Em&op&Short	Proc near
	test byte ptr [ebp].em_flags,a32
	jnz Em&op&Short32

Em&op&Short16:
	mov ecx,[ebp].reg_ecx
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	&op Em&op&ShortJump
	mov [ebp].reg_ecx,ecx
	call ReadCodeByte
	ret

Em&op&Short32:
	mov ecx,[ebp].reg_ecx
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	db 67h
	&op Em&op&ShortJump
	mov [ebp].reg_ecx,ecx
	call ReadCodeByte
	ret

Em&op&ShortJump:
	call ReadCodeByte
	mov [ebp].reg_ecx,ecx
	test byte ptr [ebp].em_flags,cs32
	jz Em&op&ShortJump16

Em&op&ShortJump32:
	movsx eax,al
	add eax,[ebp].reg_eip
	mov [ebp].reg_eip,eax
	mov ebx,eax
	mov si,OFFSET reg_cs
	call ReadByte
	ret

Em&op&ShortJump16:
	movsx ax,al
	add ax,word ptr [ebp].reg_eip
	mov word ptr [ebp].reg_eip,ax
	movzx ebx,ax
	mov si,OFFSET reg_cs
	call ReadByte
	ret
Em&op&Short	Endp

		Endm

JccNear	Macro op

	public Em&op&Near

Em&op&Near	Proc near
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	&op Em&op&NearJump
	test byte ptr [ebp].em_flags,d32
	jz Em&op&NearSkip16

Em&op&NearSkip32:
	call ReadCodeDword
	ret

Em&op&NearSkip16:
	call ReadCodeWord
	ret

Em&op&NearJump:
	test byte ptr [ebp].em_flags,d32
	jz Em&op&Near16

Em&op&Near32:
	call ReadCodeDword
	jmp Em&op&NearEip

Em&op&Near16:
	call ReadCodeWord
	movzx eax,ax

Em&op&NearEip:
	test byte ptr [ebp].em_flags,cs32
	jz Em&op&NearEip16

Em&op&NearEip32:
	add eax,[ebp].reg_eip
	mov [ebp].reg_eip,eax
	mov ebx,eax
	mov si,OFFSET reg_cs
	call ReadByte
	ret

Em&op&NearEip16:
	add ax,word ptr [ebp].reg_eip
	mov word ptr [ebp].reg_eip,ax
	movzx ebx,ax
	mov si,OFFSET reg_cs
	call ReadByte
	ret
Em&op&Near	Endp

		Endm
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmCli
;
;		DESCRIPTION:	EMULATE cli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	public EmCli

EmCli	proc near
	and word ptr [ebp].reg_eflags,NOT 200h
	ret
EmCli	endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmSti
;
;		DESCRIPTION:	EMULATE sti
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmSti

EmSti	proc near
	or word ptr [ebp].reg_eflags,200h
	ret
EmSti	endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmJccShort
;
;		DESCRIPTION:	EMULATE jcc short
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	JccShort Jmp
	JccShort Jo	
	JccShort Jno
	JccShort Jb	
	JccShort Jnb
	JccShort Je
	JccShort Jne
	JccShort Jbe
	JccShort Jnbe
	JccShort Js
	JccShort Jns
	JccShort Jp
	JccShort Jnp
	JccShort Jl
	JccShort Jnl
	JccShort Jle
	JccShort Jnle
	JecxShort Jcxz
	JecxShort Loop
	JecxShort Loopz
	JecxShort Loopnz
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmJccNear
;
;		DESCRIPTION:	EMULATE jcc near
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	JccNear Jmp
	JccNear Jo	
	JccNear Jno
	JccNear Jb	
	JccNear Jnb
	JccNear Je
	JccNear Jne
	JccNear Jbe
	JccNear Jnbe
	JccNear Js
	JccNear Jns
	JccNear Jp
	JccNear Jnp
	JccNear Jl
	JccNear Jnl
	JccNear Jle
	JccNear Jnle
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmJmpNearMem
;
;		DESCRIPTION:	EMULATE jmp near mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmJmpNearMem

EmJmpNearMem	Proc near
	test byte ptr [ebp].em_flags,d32
	jz EmJmpNearMem16

EmJmpNearMem32:
	mov bl,al
	call LoadDwordMemReg
	mov [ebp].reg_eip,eax
	mov si,OFFSET reg_cs
	mov ebx,eax
	call ReadByte
	ret

EmJmpNearMem16:
	mov bl,al
	call LoadWordMemReg
	mov word ptr [ebp].reg_eip,ax
	mov si,OFFSET reg_cs
	movzx ebx,ax
	call ReadByte
	ret
EmJmpNearMem	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmCallNear
;
;		DESCRIPTION:	EMULATE call near
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmCallNear

EmCallNear	Proc near
	test byte ptr [ebp].em_flags,d32
	jz EmCallNear16

EmCallNear32:
	call ReadCodeDword
	add eax,[ebp].reg_eip
	xchg eax,[ebp].reg_eip
	call PushDword
	mov si,OFFSET reg_cs
	mov ebx,[ebp].reg_eip
	call ReadByte
	ret

EmCallNear16:
	call ReadCodeWord
	add ax,word ptr [ebp].reg_eip
	xchg ax,word ptr [ebp].reg_eip
	call PushWord
	mov si,OFFSET reg_cs
	movzx ebx,word ptr [ebp].reg_eip
	call ReadByte	
	ret
EmCallNear	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmCallNearMem
;
;		DESCRIPTION:	EMULATE call near mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmCallNearMem

EmCallNearMem	Proc near
	test byte ptr [ebp].em_flags,d32
	jz EmCallNearMem16

EmCallNearMem32:
	mov bl,al
	call LoadDwordMemReg
	xchg eax,[ebp].reg_eip
	call PushDword
	mov si,OFFSET reg_cs
	mov ebx,[ebp].reg_eip
	call ReadByte
	ret

EmCallNearMem16:
	mov bl,al
	call LoadWordMemReg
	movzx eax,ax
	xchg ax,word ptr [ebp].reg_eip
	call PushWord
	mov si,OFFSET reg_cs
	movzx ebx,word ptr [ebp].reg_eip
	call ReadByte	
	ret
EmCallNearMem	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmRetNear
;
;		DESCRIPTION:	EMULATE retn
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmRetNear

EmRetNear	proc near
	test byte ptr [ebp].em_flags,d32
	jnz EmRetNear32

EmRetNear16:
	call PopWord
	movzx eax,ax
	mov word ptr [ebp].reg_eip,ax
	mov si,OFFSET reg_cs
	movzx ebx,ax
	call ReadByte
	ret

EmRetNear32:
	call PopDword
	mov [ebp].reg_eip,eax
	mov si,OFFSET reg_cs
	mov ebx,eax
	call ReadByte
	ret
EmRetNear	endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmRetNearN
;
;		DESCRIPTION:	EMULATE retn n
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmRetNearN

EmRetNearN	proc near
	int 3
	ret
EmRetNearN	endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmJmpFar
;
;		DESCRIPTION:	EMULATE jmp far
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmJmpFar

EmJmpFar	Proc near
	test byte ptr [ebp].em_flags,d32
	jz EmJmpFar16

EmJmpFar32:
	call ReadCodeFword
	mov bx,dx
	mov esi,eax
	call JmpFar
	ret

EmJmpFar16:
	call ReadCodeDword
	mov ebx,eax
	movzx esi,ax
	ror ebx,16
	call JmpFar
	ret
EmJmpFar	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmJmpFarMem
;
;		DESCRIPTION:	EMULATE jmp far mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmJmpFarMem

EmJmpFarMem	Proc near
	test byte ptr [ebp].em_flags,d32
	jz EmJmpFarMem16

EmJmpFarMem32:
	mov bl,al
	call LoadFwordMem
	mov bx,dx
	mov esi,eax
	call JmpFar
	ret

EmJmpFarMem16:
	mov bl,al
	call LoadDwordMem
	mov ebx,eax
	movzx esi,ax
	ror ebx,16
	call JmpFar
	ret
EmJmpFarMem	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmCallFar
;
;		DESCRIPTION:	EMULATE call far
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmCallFar

EmCallFar	Proc near
	test byte ptr [ebp].em_flags,d32
	jz EmCallFar16

EmCallFar32:
	call ReadCodeFword
	mov bx,dx
	mov esi,eax
	call CallFar32
	ret

EmCallFar16:
	call ReadCodeDword
	mov ebx,eax
	movzx esi,ax
	ror ebx,16
	call CallFar16
	ret
EmCallFar	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmCallFarMem
;
;		DESCRIPTION:	EMULATE call far mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmCallFarMem

EmCallFarMem	Proc near
	test byte ptr [ebp].em_flags,d32
	jz EmCallFarMem16

EmCallFarMem32:
	mov bl,al
	call LoadFwordMem
	mov bx,dx
	mov esi,eax
	call CallFar32
	ret

EmCallFarMem16:
	mov bl,al
	call LoadDwordMem
	mov ebx,eax
	movzx esi,ax
	ror ebx,16
	call CallFar16
	ret
EmCallFarMem	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmRetFar
;
;		DESCRIPTION:	EMULATE retf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmRetFar

EmRetFar	proc near
	test byte ptr [ebp].em_flags,d32
	jnz EmRetFar32

EmRetFar16:
	xor cl,cl
	call RetFar16
	ret

EmRetFar32:
	xor cl,cl
	call RetFar32
	ret
EmRetFar	endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmInt3, EmInt
;
;		DESCRIPTION:	EMULATE int 3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmInt3
	public EmInt

EmInt3	Proc near
	mov al,3
	call ExcFar
	ret
EmInt3	Endp

	public EmInt

EmInt	Proc near
	call ReadCodeByte
	call IntFar
	ret
EmInt	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmIret / EmIretd
;
;		DESCRIPTION:	EMULATE iret / iretd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmIret

EmIret	proc near
	test byte ptr [ebp].reg_eflags+2,2
	jnz EmIretNotTss
;
	test [ebp].reg_eflags,EFLAGS_NT
	jz EmIretNotTss
;
	call IretTss
	ret

EmIretNotTss:
	test byte ptr [ebp].em_flags,d32
	jnz EmIret32

EmIret16:
	call IretFar16
	ret

EmIret32:
	call IretFar32
	ret
EmIret	endp

code	ENDS

	END
