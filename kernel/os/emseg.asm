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
; EMSEG.ASM
; Segment management functions for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	NAME emseg

GateSize = 16

include protseg.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include int.def
include system.def

include emulate.inc
include emcom.inc

code	SEGMENT byte public 'CODE'

	assume cs:code

	.386p
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmulateError
;
;		DESCRIPTION:	Unemulated instruction
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmulateError

EmulateError	Proc near
	test byte ptr [bp+2].reg_eflags,2
	jz emulate_ret_pm
;
	mov sp,bp
	pop bx
	pop ebp
	xchg bx,bp
	mov [bp].vm_bp,bx
	pop edi
	pop esi
	pop edx
	pop ecx
	movzx ax, byte ptr [bp+2].vm_err
	ReflectException
	ret

emulate_ret_pm:
	test byte ptr [bp].reg_cs,3
	jz emulate_ret_kernel
;
	mov sp,bp
	pop bx
	pop ebp
	xchg bx,bp
	mov [bp].vm_bp,bx
	pop edi
	pop esi
	pop edx
	pop ecx
	add sp,24
	pop es
	add sp,2
	pop fs
	pop gs
	xor dx,dx
	movzx ax, byte ptr [bp+2].vm_err
	ReflectException
	ret

emulate_ret_kernel:
	mov ax,[bp].reg_old_bp
	sub ax,word ptr [bp].reg_esp
	je emulate_ret_kernel_stack_ok
	jc emulate_ret_kernel_stack_ok
;
	mov si,word ptr [bp].reg_esp
	mov di,[bp].reg_old_bp
	mov cx,ss
	mov es,cx
	add si,16
	add di,16
	mov cx,si
	sub cx,sp
	shr cx,1
	inc cx
	std
	rep movs word ptr es:[di],es:[si]
	cld
	sub sp,ax
	sub bp,ax

emulate_ret_kernel_stack_ok:
	mov sp,bp
	pop bx
	pop ebp
	xchg bx,bp
	mov [bp].vm_bp,bx
	pop edi
	pop esi
	pop edx
	pop ecx
	add sp,24
	pop es
	pop word ptr [bp].pm_ds
	pop fs
	pop gs
	xor dx,dx
	movzx ax, byte ptr [bp+2].vm_err
	DebugBreak
	ret
EmulateError	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ValidateSegment
;
;		DESCRIPTION:	Validate a selector
;
;		PARAMETERS:		SS:BP		CPU
;						AX			SEGMENT REGISTER TO VALIDATE
;
;		RETURNS:		NC			VALID
;							EDX:EAX	DESCRIPTOR
;						CY			INVALID
;							BX		ERROR CODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ValidateSegment

ValidateSegment	Proc near
	test byte ptr [bp+2].reg_eflags,2
	jz EmulateError
;
	ret
ValidateSegment	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			JmpFar
;
;		DESCRIPTION:	Emulate protected mode far jump
;
;		PARAMETERS:		SS:BP		CPU
;						BX:ESI		ADDRESS TO JMP TO
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public JmpFar

JmpFar	Proc near
	test byte ptr [bp].reg_eflags+2,2
	jz EmulateError

JmpFarReal:
	cmp esi,10000h
	jnc EmulateError
;	
	mov word ptr [bp].reg_eip,si
	mov [bp].reg_cs,bx
	ret
JmpFar	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CallFar16
;
;		DESCRIPTION:	Emulate protected mode call far
;
;		PARAMETERS:		SS:BP		CPU
;						BX:ESI		ADDRESS TO JMP TO
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CallFar16

CallFar16	Proc near
	test byte ptr [bp].reg_eflags+2,2
	jz EmulateError
;
	mov ax,[bp].reg_cs
	call PushWord
	mov ax,word ptr [bp].reg_eip
	call PushWord

CallFarReal16:
	mov word ptr [bp].reg_eip,si
	mov [bp].reg_cs,bx
	ret
CallFar16	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CallFar32
;
;		DESCRIPTION:	Emulate protected mode call far
;
;		PARAMETERS:		SS:BP		CPU
;						BX:ESI		ADDRESS TO JMP TO
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CallFar32

CallFar32	Proc near
	test byte ptr [bp].reg_eflags+2,2
	jz EmulateError

CallFarReal32:
	cmp esi,10000h
	jnc EmulateError
;	
	mov word ptr [bp].reg_eip,si
	mov [bp].reg_cs,bx
	ret
CallFar32	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RetFar16
;
;		DESCRIPTION:	Emulate protected mode retf16
;
;		PARAMETERS:		SS:BP		CPU
;						CL			# of params to remove
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RetFar16

RetFar16	Proc near
	test byte ptr [bp].reg_eflags+2,2
	jz EmulateError
;
	call PopWord
	movzx esi,ax
	call PopWord
	mov bx,ax

RetFarReal16:
	mov word ptr [bp].reg_eip,si
	mov [bp].reg_cs,bx
	ret
RetFar16	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RetFar32
;
;		DESCRIPTION:	Emulate protected mode retf32
;
;		PARAMETERS:		SS:BP		CPU
;						CL			# of params to remove
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RetFar32

RetFar32	Proc near
	test byte ptr [bp].reg_eflags+2,2
	jz EmulateError
;
	call PopDword
	mov esi,eax
	call PopDword
	mov bx,ax

RetFarReal32:
	cmp esi,10000h
	jnc EmulateError
;
	mov word ptr [bp].reg_eip,si
	mov [bp].reg_cs,bx
	ret
RetFar32	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IntFar
;
;		DESCRIPTION:	Emulate protected mode int
;
;		PARAMETERS:		SS:BP		CPU
;						AL			INT #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IntFar

IntFar	Proc near
	test byte ptr [bp+2].reg_eflags,2
	jz IntFarPm
;
	push ax
	mov ax,word ptr [bp].reg_eflags
	GetFlags
	call PushWord
	mov ax,[bp].reg_cs
	rol eax,16
	mov ax,word ptr [bp].reg_eip
	call PushDword
	pop ax
	GetVmInt
	mov [bp].reg_cs,dx
	mov word ptr [bp].reg_eip,bx
	jmp IntFarDone

IntFarPm:
	test byte ptr [bp].reg_cs,3
	jz EmulateError
;
	push ax
	mov ax,thread_app_sel
	mov ds,ax
	mov al,ds:app_bitness
	or al,al
	pop ax
	jnz IntFarPm32

IntFarPm16:
	push ax
	mov ax,word ptr [bp].reg_eflags
	call PushWord
	mov ax,[bp].reg_cs
	rol eax,16
	mov ax,word ptr [bp].reg_eip
	call PushDword
	pop ax
	GetPMInt
	mov [bp].reg_cs,es
	mov word ptr [bp].reg_eip,di
	jmp IntFarDone

IntFarPm32:
	push ax
	mov eax,[bp].reg_eflags
	call PushDword
	mov ax,[bp].reg_cs
	call PushDword
	mov eax,[bp].reg_eip
	call PushDword
	pop ax
	UserGateForce32 get_pm_int_nr
	mov [bp].reg_cs,es
	mov [bp].reg_eip,edi

IntFarDone:
	ret
IntFar	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ExcFar
;
;		DESCRIPTION:	Emulate protected mode exception
;
;		PARAMETERS:		SS:BP		CPU
;						AL			Exception #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ExcFar

ExcFar	Proc near
	test byte ptr [bp+2].reg_eflags,2
	jnz IntFar
;
	test byte ptr [bp].reg_cs,3
	jz EmulateError
;
	push ax
	mov ax,thread_app_sel
	mov ds,ax
	mov al,ds:app_bitness
	or al,al
	jnz ExcFarPm32

ExcFarPm16:
	mov ax,[bp].reg_ss
	mov bx,word ptr [bp].reg_esp
	call PushWord
	mov ax,bx
	call PushWord
;	
	mov ax,word ptr [bp].reg_eflags
	call PushWord
;
	mov ax,[bp].reg_cs
	call PushWord
;
	mov ax,word ptr [bp].reg_eip
	call PushWord
;
	xor ax,ax
	call PushWord
;
	mov ax,callb_exc16_sel
	call PushWord
;
	pop ax
	push ax
	movzx ax,al
	shl ax,3
	call PushWord
;
	pop ax
	GetException
	mov [bp].reg_cs,es
	mov word ptr [bp].reg_eip,di
	jmp ExcFarDone

ExcFarPm32:
	movzx eax,[bp].reg_ss
	mov ebx,[bp].reg_esp
	call PushDword
	mov eax,ebx
	call PushDword
;	
	mov eax,[bp].reg_eflags
	call PushDword
;
	movzx eax,[bp].reg_cs
	call PushDword
;
	mov eax,[bp].reg_eip
	call PushDword
;
	xor eax,eax
	call PushDword
;
	mov eax,callb_exc32_sel
	call PushDword
;
	pop ax
	push ax
	movzx eax,al
	shl eax,3
	call PushDword
;
	pop ax
	UserGateForce32 get_exception_nr
	mov [bp].reg_cs,es
	mov [bp].reg_eip,edi

ExcFarDone:
	ret
ExcFar	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FpFault
;
;		DESCRIPTION:	Floating point fault
;
;		PARAMETERS:		SS:BP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FpFault

FpFault	Proc near
	xor cx,cx
	mov al,7
	call ExcFar	
	ret
FpFault	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IretFar16
;
;		DESCRIPTION:	Emulate protected mode iret16
;
;		PARAMETERS:		SS:BP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IretFar16

IretFar16	Proc near
	test byte ptr [bp].reg_eflags+2,2
	jz EmulateError
;
	call PopWord
	movzx esi,ax
	call PopWord
	mov bx,ax

IretFarReal16:
	mov word ptr [bp].reg_eip,si
	mov [bp].reg_cs,bx
	call PopWord
	SetFlags
	mov word ptr [bp].reg_eflags,ax
	ret
IretFar16	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IretFar32
;
;		DESCRIPTION:	Emulate protected mode iret32
;
;		PARAMETERS:		SS:BP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IretFar32

IretFar32	Proc near
	test byte ptr [bp].reg_eflags+2,2
	jz EmulateError
;
	call PopDword
	mov esi,eax
	call PopDword
	mov bx,ax

IretFarReal32:
	cmp esi,10000h
	jnc EmulateError
	mov word ptr [bp].reg_eip,si
	mov [bp].reg_cs,bx
	call PopDword
	SetFlags
	mov word ptr [bp].reg_eflags,ax
	ret
IretFar32	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IretTss
;
;		DESCRIPTION:	IRET back to a TSS
;
;		PARAMETERS:		SS:BP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IretTss

IretTss	Proc near
	jmp EmulateError
IretTss	Endp

code	ENDS

	END
