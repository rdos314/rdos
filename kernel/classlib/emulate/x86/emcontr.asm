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
; EMCONTR.ASM
; Control transfer emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat
						
		NAME emcontr

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

include ..\core\emulate.inc
include ..\core\emcom.inc
include ..\core\emmem.inc
include ..\core\emseg.inc

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			JccShort
;
;		DESCRIPTION:	Emulate jcc short
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
	movsx eax,al
	add eax,[ebp].reg_eip
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	mov [ebp].reg_eip,eax
	ret
Em&op&Short	Endp

		Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			JecxShort
;
;		DESCRIPTION:	Emulate jecx short
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JecxShort	Macro op

	public Em&op&Short

Em&op&Short	Proc near
	test byte ptr [ebp].em_flags,a32
	jnz Em&op&Short32

Em&op&Short16:
	mov ecx,[ebp].reg_ecx
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	db 67h
	&op Em&op&ShortJump
	mov [ebp].reg_ecx,ecx
	call ReadCodeByte
	ret

Em&op&Short32:
	mov ecx,[ebp].reg_ecx
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	&op Em&op&ShortJump
	mov [ebp].reg_ecx,ecx
	call ReadCodeByte
	ret

Em&op&ShortJump:
	mov [ebp].reg_ecx,ecx
;
	call ReadCodeByte
	movsx eax,al
	add eax,[ebp].reg_eip
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	mov [ebp].reg_eip,eax
	ret
Em&op&Short	Endp

		Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			JccNear
;
;		DESCRIPTION:	Emulate jcc near
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
	add eax,[ebp].reg_eip
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	mov [ebp].reg_eip,eax
	ret

Em&op&Near16:
	call ReadCodeWord
	add ax,word ptr [ebp].reg_eip
	movzx eax,ax
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	mov word ptr [ebp].reg_eip,ax
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
	test [ebp].reg_cr0,CR0_PE
	jz EmCliDo
;
	test byte ptr [ebp].reg_eflags+2,2
	jz EmCliPm
;
	mov ecx,[ebp].reg_eflags
	and ecx,EFLAGS_IOPL
	cmp ecx,EFLAGS_IOPL
	jne PrivilegeFault
	jmp EmCliDo

EmCliPm:
	mov ecx,[ebp].reg_eflags
	ror cx,4
	mov	ch,[ebp].reg_cs.d_access
	and cx,303h
	cmp cl,ch
	jc PrivilegeFault

EmCliDo:
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
	test [ebp].reg_cr0,CR0_PE
	jz EmStiDo
;
	test byte ptr [ebp].reg_eflags+2,2
	jz EmStiPm
;
	mov ecx,[ebp].reg_eflags
	and ecx,EFLAGS_IOPL
	cmp ecx,EFLAGS_IOPL
	jne PrivilegeFault
	jmp EmStiDo

EmStiPm:
	mov ecx,[ebp].reg_eflags
	ror cx,4
	mov	ch,[ebp].reg_cs.d_access
	and cx,303h
	cmp cl,ch
	jc PrivilegeFault

EmStiDo:
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
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	mov [ebp].reg_eip,eax
	ret

EmJmpNearMem16:
	mov bl,al
	call LoadWordMemReg
	movzx eax,ax
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	mov word ptr [ebp].reg_eip,ax
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
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	xchg eax,[ebp].reg_eip
	call PushDword
	ret

EmCallNear16:
	call ReadCodeWord
	add ax,word ptr [ebp].reg_eip
	movzx eax,ax
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	xchg ax,word ptr [ebp].reg_eip
	call PushWord
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
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	xchg eax,[ebp].reg_eip
	call PushDword
	ret

EmCallNearMem16:
	mov bl,al
	call LoadWordMemReg
	movzx eax,ax
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	xchg ax,word ptr [ebp].reg_eip
	call PushWord
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
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	mov word ptr [ebp].reg_eip,ax
	ret

EmRetNear32:
	call PopDword
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
	mov [ebp].reg_eip,eax
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
	test byte ptr [ebp].em_flags,d32
	jnz EmRetNearN32

EmRetNearN16:
	call ReadCodeWord
	push ax
	call PopWord
	movzx eax,ax
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
;
	mov word ptr [ebp].reg_eip,ax
	pop ax
	movzx eax,ax
	call AddToStack	
	ret

EmRetNearN32:
	call ReadCodeWord
	push ax
	call PopDword
	cmp eax,[ebp].reg_cs.d_limit
	jnc AccessFault
;
	mov [ebp].reg_eip,eax
	pop ax
	movzx eax,ax
	call AddToStack	
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
;		NAME:			EmRetFarN
;
;		DESCRIPTION:	EMULATE retf n
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmRetFarN

EmRetFarN	proc near
	test byte ptr [ebp].em_flags,d32
	jnz EmRetFarN32

EmRetFarN16:
	call ReadCodeWord
	push ax
	xor cl,cl
	call RetFar16
	pop ax
	movzx eax,ax
	call AddToStack	
	ret

EmRetFarN32:
	call ReadCodeWord
	push ax
	xor cl,cl
	call RetFar32
	pop ax
	movzx eax,ax
	call AddToStack	
	ret
EmRetFarN	endp
	
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
	call IntFar
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
	test [ebp].reg_cr0,CR0_PE
	jz EmIretNotTss
;
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

	END
