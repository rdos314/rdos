;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; EMSEG.ASM
; Segment register and fault emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat

PAGE

	NAME emseg

include ..\core\emulate.inc
include ..\core\emcom.inc
include ..\core\empage.inc
include ..\core\emtss.inc

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ResetFault
;
;		DESCRIPTION:	Reset fault macro
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetFault	Macro
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	mov eax,[ebp].org_esp
	mov [ebp].reg_esp,eax
	mov eax,[ebp].org_stack
	mov esp,eax
			Endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadDescriptor
;
;		DESCRIPTION:	Load descriptor macro
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		Selector
;
;		RETURNS:		AX		Selector
;						ESI		Offset
;						EAX		Base
;						ECX		Limit/word count
;						DX		Access rights
;						EDI		Descriptor address
;						NC		Normal descriptor
;						CY		Gate descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadDescriptor	MACRO FaultHandler
	local InLdt
	local InGdt
	local LoadIt
	local LoadAsNormal
	local LoadCheckAccessed
	local LoadAsGate
	local PageGranular
	local ByteGranular
	local Done
	local EplOk

	test bx,0FFFCh
	jz FaultHandler
;
	test bl,4
	jz InGdt

InLdt:
	test [ebp].reg_ldt.d_access, ACCESS_READ
	jz FaultHandler
;
	mov edi,OFFSET reg_ldt
	jmp LoadIt

InGdt:
	mov edi,OFFSET reg_gdt

LoadIt:
	movzx ecx,bx
	or cl,7
	dec ecx
	sub ecx,[ebp+edi].d_limit
	jnc FaultHandler
;
	push bx
	movzx ebx,bx
	and bl,0F8h
	add ebx,[ebp+edi].d_base
	mov edi,ebx
	call ReadLinearQword
	pop bx
	test dh,80h
	jz SegmentFault
;
	test dh,10h
	jnz LoadCheckAccessed
;
	test dh,4
	jz LoadAsNormal

LoadAsGate:
	xchg ax,dx
	mov esi,edx
	movzx dx,ah
	mov cl,al
	and cl,0Fh
	shr eax,16
;
	push cx
	mov	cl,byte ptr [ebp].reg_cs.d_access
	mov ch,bl
	and cx,303h
	cmp ch,cl
	jc EplOk
	mov cl,ch
EplOk:
	mov ch,dl
	shr ch,5
	and ch,3
	cmp cl,ch
	ja FaultHandler
	pop cx
	stc
	jmp Done

LoadCheckAccessed:
	test dh,1
	jnz LoadAsNormal
;
	or dh,1
	push ax
	push ebx
	mov al,dh
	mov ebx,edi
	add ebx,5
	call WriteLinearByte
	pop ebx
	pop ax

LoadAsNormal:	
	mov ecx,edx
	mov cx,ax
	rol edx,8
	mov ax,dx
	xchg al,ah
	ror eax,16
	ror edx,16
	test dh,80h
	jz ByteGranular

PageGranular:
	shl ecx,12
	or cx,0FFFh
	clc
	jmp Done
	
ByteGranular:
	and ecx,0FFFFFh
	clc

Done:
			ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AssertDataDpl
;
;		DESCRIPTION:	Assert that a selector is visible for selector load
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		Selector
;						DX		Access rights
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AssertDataDpl	Macro
	local EplOk

	push cx
	mov	cl,byte ptr [ebp].reg_cs.d_access
	mov ch,bl
	and cx,303h
	cmp ch,cl
	jc EplOk
	mov cl,ch
EplOk:
	mov ch,dl
	shr ch,5
	and ch,3
	cmp cl,ch
	ja LoadFault
	pop cx

		Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AssertCallDpl
;
;		DESCRIPTION:	Assert that a selector is visible for control transfer
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		Selector
;						DX		Access rights
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AssertCallDpl	Macro
	local EplOk
	local Done

	test [ebp].reg_eflags,EFLAGS_VM
	jnz Done
;
	push cx
	mov	cl,byte ptr [ebp].reg_cs.d_access
	mov ch,bl
	and cx,303h
	cmp ch,cl
	jc EplOk
	mov cl,ch
EplOk:
	mov ch,dl
	shr ch,5
	and ch,3
	cmp cl,ch
	jb ProtectionFault
	pop cx

Done:
		Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UserBreak
;
;		DESCRIPTION:	User break
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public UserBreak

UserBreak	Proc near
	push ebp
	mov ebp,[esp+8]
	test [ebp].em_debug, DEBUG_RESUME
	jnz user_break_done
;
	or [ebp].em_debug, DEBUG_BREAK OR DEBUG_RESUME
	ResetFault
	ret

user_break_done:
	pop ebp
	ret 4
UserBreak	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TripleFault
;
;		DESCRIPTION:	Triple fault
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public TripleFault

TripleFault	Proc near
	int 3
	or [ebp].em_flags,triple_faulted
	or [ebp].em_debug,DEBUG_BREAK
	ResetFault
	ret
TripleFault	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TrapFault
;
;		DESCRIPTION:	Trap (single step) fault
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public TrapFault

TrapFault	Proc near
	xor cx,cx
	mov al,1
	call ExcFar	
	ret
TrapFault	Endp
	
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
	int 3
	ResetFault
	or [ebp].em_flags,triple_faulted
	or [ebp].em_debug,DEBUG_BREAK
	ret
EmulateError	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DivFault
;
;		DESCRIPTION:	Div fault
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public DivFault

DivFault	Proc near
	int 3
	ResetFault
	xor cx,cx
	mov al,0
	call ExcFar	
	ret
DivFault	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpcodeFault
;
;		DESCRIPTION:	Invalid opcode fault
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public OpcodeFault

OpcodeFault	Proc near
	or [ebp].em_flags,single_faulted
	ResetFault
	xor cx,cx
	mov al,6
	call ExcFar	
	ret
OpcodeFault	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DoubleFault
;
;		DESCRIPTION:	Double fault
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public DoubleFault

DoubleFault	Proc near
	int 3
	test [ebp].em_flags,double_faulted
	jnz TripleFault
	or [ebp].em_flags,double_faulted
;
	ResetFault
	xor cx,cx
	mov al,8
	call ExcFar	
	ret
DoubleFault	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SegmentFault
;
;		DESCRIPTION:	Segment not present fault
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		Error code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SegmentFault

SegmentFault	Proc near
	int 3
	test [ebp].em_flags,single_faulted
	jnz DoubleFault
	or [ebp].em_flags,single_faulted
;
	ResetFault
	mov cx,1
	mov al,11
	call ExcFar	
	ret
SegmentFault	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StackFault
;
;		DESCRIPTION:	Stack fault
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		Error code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public StackFault

StackFault	Proc near
	int 3
	test [ebp].em_flags,single_faulted
	jnz DoubleFault
	or [ebp].em_flags,single_faulted
	ResetFault
	mov cx,1
	mov al,12
	call ExcFar	
	ret
StackFault	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ProtectionFault
;
;		DESCRIPTION:	General segment protection exception
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		Error code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ProtectionFault

ProtectionFault	Proc near
	int 3
	test [ebp].em_flags,single_faulted
	jnz DoubleFault
	or [ebp].em_flags,single_faulted
	ResetFault
	mov cx,1
	mov al,13
	call ExcFar	
	ret
ProtectionFault	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PageFault
;
;		DESCRIPTION:	Page fault exception
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		Error code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public PageFault

PageFault	Proc near
	test [ebp].em_flags,single_faulted
	jnz DoubleFault
	or [ebp].em_flags,single_faulted
	ResetFault
	mov cx,1
	mov al,14
	call ExcFar	
	ret
PageFault	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InvalidTssFault
;
;		DESCRIPTION:	Invalid TSS fault
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		Error code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InvalidTssFault

InvalidTssFault	Proc near
	int 3
	test [ebp].em_flags,single_faulted
	jnz DoubleFault
	or [ebp].em_flags,single_faulted
	ResetFault
	mov cx,1
	mov al,10
	call ExcFar	
	ret
InvalidTssFault	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FpFault
;
;		DESCRIPTION:	Floating point fault
;
;		PARAMETERS:		SS:EBP	CPU
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
;		NAME:			LoadFault
;
;		DESCRIPTION:	Segment register load fault
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		Error code
;						ESI		Descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadFault

LoadFault:
	and bl,0FCh
	cmp esi,OFFSET reg_ss
	jne ProtectionFault
	jmp StackFault

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IdtFault
;
;		DESCRIPTION:	Segment register idt fault
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		Error code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IdtFault

IdtFault:
	and bl,0F8h
	or bl,2
	jmp ProtectionFault

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AccessFault
;
;		description:	Fault during access (no error code)
;
;		PARAMETERS:		SS:EBP		CPU
;						ESI			REFERENCED DESCRIPTOR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public AccessFault

AccessFault:
	xor bx,bx
	cmp esi,OFFSET reg_ss
	jne ProtectionFault
	jmp StackFault

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PrivilegeFault
;
;		DESCRIPTION:	Privilege fault
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public PrivilegeFault

PrivilegeFault:
	xor bx,bx
	jmp ProtectionFault


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TransferReal
;
;		DESCRIPTION:	Transfer control within real or v86 mode
;
;		PARAMETERS:		SS:EBP	CPU
;						BX:ESI	New CS:EIP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TransferReal	Proc near
	cmp esi,[ebp].reg_cs.d_limit
	ja ProtectionFault
;
	mov [ebp].reg_cs.d_selector,bx
	mov [ebp].reg_eip,esi
	movzx ebx,bx
	shl ebx,4
	mov [ebp].reg_cs.d_base,ebx
	mov [ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_WRITE
	ret
TransferReal	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TransferProt
;
;		DESCRIPTION:	Transfer control to protected mode
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		CS selector
;						ESI		EIP
;						EAX		CS base
;						ECX		CS limit
;						DX		CS access
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TransferProt	Proc near
	mov [ebp].reg_cs.d_base,eax
	mov [ebp].reg_cs.d_limit,ecx
	mov ax,bx
	mov [ebp].reg_cs.d_selector,ax
	and al,3
	test dh,40h
	jz TransferProtSizeOk
	or al,ACCESS_SIZE

TransferProtSizeOk:
	test dl,2
	jz TransferProtReadOk
	or al,ACCESS_READ

TransferProtReadOk:
	mov [ebp].reg_cs.d_access,al
	mov [ebp].reg_eip,esi
	ret
TransferProt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadStackSelector
;
;		DESCRIPTION:	Load stack segment register
;
;		PARAMETERS:		SS:EBP		CPU
;						AX			VALUE TO LOAD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadStackSelector	Proc near
	mov [ebp].em_pl,0
	mov bx,ax
	and ax,0FFFCh
	jz ProtectionFault
;
	LoadDescriptor StackFault
	test dl,10h
	jz StackFault
;
	push cx
	mov cl,dl
	and cl,1Ah
	cmp cl,12h
	jnz StackFault
;
	mov cl,bl
	mov ch,byte ptr [ebp].reg_cs.d_selector
	and cx,303h
	cmp cl,ch
	jne StackFault
	pop cx
;
	mov [ebp].reg_ss.d_base,eax
	mov [ebp].reg_ss.d_limit,ecx
	mov [ebp].reg_ss.d_selector,bx
;
	and bl,3
	test dh,40h
	jz LoadStackSizeOk
;
	or bl,ACCESS_SIZE

LoadStackSizeOk:
	or bl,ACCESS_READ OR ACCESS_WRITE
;
	test dl,4
	jz LoadStackDirOk
;
	or bl,ACCESS_DIR

LoadStackDirOk:
	mov [ebp].reg_ss.d_access,bl
	ret
LoadStackSelector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SwitchStackSelector
;
;		DESCRIPTION:	Switch stack segment register
;
;		PARAMETERS:		SS:EBP		CPU
;						AX			VALUE TO LOAD
;						BX			NEW CS REGISTER (RPL=DPL)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SwitchStackSelector	Proc near
	push si
	mov [ebp].em_pl,0
	push bx
	mov bx,ax
	and ax,0FFFCh
	jz ProtectionFault
;
	LoadDescriptor StackFault
	test dl,10
	jz StackFault
;
	and dl,1Ah
	cmp dl,12h
	jnz StackFault
;
	pop si
	push cx
	mov cx,si
	mov ch,bl
	and cx,303h
	cmp cl,ch
	jne StackFault
	pop cx
;
	mov [ebp].reg_ss.d_base,eax
	mov [ebp].reg_ss.d_limit,ecx
	mov [ebp].reg_ss.d_selector,bx
;
	and bl,3
	test dh,40h
	jz SwitchStackSizeOk
;
	or bl,ACCESS_SIZE

SwitchStackSizeOk:
	or bl,ACCESS_READ OR ACCESS_WRITE
;
	test dl,4
	jz SwitchStackDirOk
;
	or bl,ACCESS_DIR

SwitchStackDirOk:
	mov [ebp].reg_ss.d_access,bl
	mov bx,si                        ;restore bx
	pop si
	ret
SwitchStackSelector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadSelector
;
;		DESCRIPTION:	Load segment register
;
;		PARAMETERS:		SS:EBP		CPU
;						ESI			SEGMENT REGISTER TO LOAD
;						AX			VALUE TO LOAD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadSelector	Proc near
	mov [ebp].em_pl,0
	mov bx,ax
;
	and ax,0FFFCh
	jnz LoadNotNull
;
	mov [ebp+esi].d_selector,bx
	mov [ebp+esi].d_access,0
	ret
	
LoadNotNull:
	LoadDescriptor ProtectionFault
	test dl,10h
	jz ProtectionFault
;
	AssertDataDpl
	mov [ebp+esi].d_base,eax
	mov [ebp+esi].d_limit,ecx
	mov [ebp+esi].d_selector,bx
;
	and bl,3
	test dh,40h
	jz LoadSelectorSizeOk
;
	or bl,ACCESS_SIZE

LoadSelectorSizeOk:
	test dl,8
	jz LoadDataSelector

LoadCodeSelector:
	test dl,2
	jz ProtectionFault
;
	or bl,ACCESS_READ
	mov [ebp+esi].d_access,bl
	jmp LoadSelectorDone

LoadDataSelector:
	or bl,ACCESS_READ
	test dl,2
	jz LoadWriteableOk
;
	or bl,ACCESS_WRITE

LoadWriteableOk:
	test dl,4
	jz LoadDirOk
;
	or bl,ACCESS_DIR

LoadDirOk:
	mov [ebp+esi].d_access,bl

LoadSelectorDone:
	ret
LoadSelector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadSegment
;
;		DESCRIPTION:	Load segment register
;
;		PARAMETERS:		SS:EBP		CPU
;						ESI			SEGMENT REGISTER TO LOAD
;						AX			VALUE TO LOAD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadSegment

LoadSegment	Proc near
	test word ptr [ebp].reg_cr0, CR0_PE
	jz LoadRealSegment
;
	test byte ptr [ebp+2].reg_eflags, 2
	jnz LoadRealSegment

	cmp esi,OFFSET reg_ss
	je LoadStackSelector
	jmp LoadSelector

LoadRealSegment:
	mov [ebp+esi].d_selector,ax
	movzx ebx,ax
	shl ebx,4
	mov [ebp+esi].d_base,ebx
	ret
LoadSegment	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TransferEqual
;
;		DESCRIPTION:	Transfer control to equal priority (jmp)
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		New CS
;						ESI		New EIP
;						EAX		CS Base
;						ECX		CS Limit
;						DX		Access
;						EDI		Descriptor address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TransferEqual	Proc near
	push cx
	cmp esi,ecx
	ja ProtectionFault
;
	test dl,8
	jz ProtectionFault
;
	test dl,4
	jz EqualNormalCode
;
	AssertCallDpl
	and bx,0FFFCh
	mov cl,[ebp].reg_cs.d_access
	and cl,3
	or bl,cl

EqualNormalCode:
	mov cl,bl
	mov ch,[ebp].reg_cs.d_access
	and cx,303h
	cmp cl,ch
	jne ProtectionFault
;
	mov cl,dl
	shr cl,5
	and cl,3
	cmp cl,ch
	jne ProtectionFault
;
	pop cx
	call TransferProt
	ret
TransferEqual	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TransferHigher
;
;		DESCRIPTION:	Transfer control to higher or equal priority (ret, iret)
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		New CS
;						ESI		New EIP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TransferHigher	Proc near
	test [ebp].em_transfer,TRANSFER_FLAGS
	jz TransferHigherProt
;
	test byte ptr [ebp].em_flags,d32
	jz TransferHigherProt             ;16 bit protected mode

	call PopDword
	mov ecx,eax
	test ecx,EFLAGS_VM
	jnz short TransferHigherVm
;
        call PushDword
	test [ebp].em_transfer,TRANSFER_32
	jnz TransferHigherProt

	test byte ptr [ebp].reg_cs.d_access, ACCESS_RPL
	jnz TransferHigherProt

TransferHigherVm:
	cmp esi,10000h
	jae ProtectionFault
	call PopDword
	cmp eax,10000h
	jae ProtectionFault
	push esi
	push bx
	push ecx
	push eax
	call PopWord
	push ax
	mov eax,2
	call AddToStack
;
	call PopWord
	push ax
	mov eax,2
	call AddToStack
;
	call PopWord
	push ax
	mov eax,2
	call AddToStack
;
	call PopWord
	push ax
	mov eax,2
	call AddToStack
;
	call PopWord
	push ax
	mov eax,2
	call AddToStack
;	
	pop ax
	mov [ebp].reg_gs.d_selector,ax
	movzx eax,ax
	shl eax,4
	mov [ebp].reg_gs.d_base,eax
	mov [ebp].reg_gs.d_limit,0FFFFh
	mov [ebp].reg_gs.d_access,ACCESS_READ OR ACCESS_WRITE OR ACCESS_RPL
;	
	pop ax
	mov [ebp].reg_fs.d_selector,ax
	movzx eax,ax
	shl eax,4
	mov [ebp].reg_fs.d_base,eax
	mov [ebp].reg_fs.d_limit,0FFFFh
	mov [ebp].reg_fs.d_access,ACCESS_READ OR ACCESS_WRITE OR ACCESS_RPL
;	
	pop ax
	mov [ebp].reg_ds.d_selector,ax
	movzx eax,ax
	shl eax,4
	mov [ebp].reg_ds.d_base,eax
	mov [ebp].reg_ds.d_limit,0FFFFh
	mov [ebp].reg_ds.d_access,ACCESS_READ OR ACCESS_WRITE OR ACCESS_RPL
;	
	pop ax
	mov [ebp].reg_es.d_selector,ax
	movzx eax,ax
	shl eax,4
	mov [ebp].reg_es.d_base,eax
	mov [ebp].reg_es.d_limit,0FFFFh
	mov [ebp].reg_es.d_access,ACCESS_READ OR ACCESS_WRITE OR ACCESS_RPL
;	
	pop ax
	mov [ebp].reg_ss.d_selector,ax
	movzx eax,ax
	shl eax,4
	mov [ebp].reg_ss.d_base,eax
	mov [ebp].reg_ss.d_limit,0FFFFh
	mov [ebp].reg_ss.d_access,ACCESS_READ OR ACCESS_WRITE OR ACCESS_RPL
;
	pop eax
	mov [ebp].reg_esp,eax
;
	pop eax
	and eax,NOT EFLAGS_UNDEF
	or al,2
	mov [ebp].reg_eflags,eax
;	
	pop ax
	mov [ebp].reg_cs.d_selector,ax
	movzx eax,ax
	shl eax,4
	mov [ebp].reg_cs.d_base,eax
	mov [ebp].reg_cs.d_limit,0FFFFh
	mov [ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_WRITE OR ACCESS_RPL
;
	pop eax
	mov [ebp].reg_eip,eax
	ret

TransferHigherProt:
	LoadDescriptor ProtectionFault
	test dl,10h
	jz ProtectionFault
;
	push ecx
	push eax
	cmp esi,ecx
	ja ProtectionFault
;
	test dl,8                       ;must be a code segment
	jz ProtectionFault
;
	test dl,4                         ;conforming or not
	jz HigherNormalCode

HigherConformingCode:
	AssertDataDpl
	and bx,0FFFCh
	mov cl,dl
	shr cl,5
	and cl,3
	or bl,cl
	jmp HigherCheckSize

HigherNormalCode:
	mov cl,dl
	shr cl,5
	mov ch,bl
	and cx,303h
	cmp cl,ch
	jne ProtectionFault
;
	or [ebp].em_transfer,cl
	mov ch,[ebp].reg_cs.d_access
	and ch,3
	cmp cl,ch
	je HigherCheckSize
	jb ProtectionFault
;
	or [ebp].em_transfer,TRANSFER_SWITCH

HigherCheckSize:
	test [ebp].em_transfer,TRANSFER_32
	jnz Higher32

Higher16:
	mov ecx,[ebp].reg_eflags
	test [ebp].em_transfer,TRANSFER_FLAGS
	jz HigherFlagsDone16
;
	call PopWord
	mov cx,ax

HigherFlagsDone16:
	push ecx
	movzx eax,[ebp].em_params
	shl eax,1
	call AddToStack
;
	test [ebp].em_transfer,TRANSFER_SWITCH
	jz HigherStackDone16
;
	call PopWord
	push ax
	call PopWord
	pop word ptr [ebp].reg_esp
	call SwitchStackSelector

HigherStackDone16:
	jmp HigherLoadIt

Higher32:
	mov ecx,[ebp].reg_eflags
	test [ebp].em_transfer,TRANSFER_FLAGS
	jz HigherFlagsDone32
;
	call PopDword
	mov ecx,eax
	test byte ptr [ebp].reg_cs.d_access, ACCESS_RPL
	jz HigherFlagsDone32
;
	and ecx,NOT EFLAGS_VM

HigherFlagsDone32:
	push ecx
	movzx eax,[ebp].em_params
	shl eax,2
	call AddToStack
;
	test [ebp].em_transfer,TRANSFER_SWITCH
	jz HigherStackDone32
;
	call PopDword
	push eax
	call PopWord
	pop dword ptr [ebp].reg_esp
	call SwitchStackSelector
	
HigherStackDone32:

HigherLoadIt:
	mov ecx,[ebp].reg_eflags
	ror cx,4
	mov	ch,[ebp].reg_cs.d_access
	and cx,303h
	cmp cl,ch
	pop ecx
	jc TransferHigherFlagsDone
;
	and ecx,NOT EFLAGS_UNDEF
	or cl,2
	mov [ebp].reg_eflags,ecx

TransferHigherFlagsDone:
	pop eax
	pop ecx
	call TransferProt
	ret
TransferHigher	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TransferLower
;
;		DESCRIPTION:	Transfer control to lower or equal priority (call, int)
;
;		PARAMETERS:		SS:EBP	CPU
;						BX		New CS
;						ESI		New EIP
;						EDX:EAX	CS Descriptor
;						ECX		Descriptor address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TransferLower	Proc near
	cmp esi,ecx
	ja ProtectionFault
;
	push eax
	push ecx
;
	test dl,8
	jz ProtectionFault
;
	test dl,4
	jz LowerNormalCode		;conforming or not ?
;
	AssertCallDpl		;make sur that the call is from a less privilege segment
;
	and bx,0FFFCh
	mov cl,[ebp].reg_cs.d_access
	and cl,3			
	or bl,cl			;take the privilege of the caller (to be conform :-)
	or [ebp].em_transfer,cl
	jmp LowerPush

LowerNormalCode:
	mov cl,dl		;cl = DPL of the gate
	shr cl,5
	mov ch,bl		; ch = RPL 
	and cx,303h
	jne ProtectionFault		
;
	or [ebp].em_transfer,cl
	mov ch,[ebp].reg_cs.d_access
	and ch,3
	cmp cl,ch
	je LowerPush
	ja ProtectionFault
;
	or [ebp].em_transfer,TRANSFER_SWITCH
LowerPush:
	mov al, [ebp].em_transfer
        and al,3
	test [ebp].em_transfer,TRANSFER_32
	jnz Lower32

Lower16:
	test [ebp].reg_eflags,EFLAGS_VM
	jz LowerProt16

LowerVm16:
	push word ptr [ebp].reg_esp
	push [ebp].reg_ss.d_selector
	call GetStack
	push eax
	mov ax,dx
	call SwitchStackSelector
	pop [ebp].reg_esp
;
	mov ax,[ebp].reg_gs.d_selector
	call PushWord
;
	mov ax,[ebp].reg_fs.d_selector
	call PushWord
;
	mov ax,[ebp].reg_ds.d_selector
	call PushWord
;
	mov ax,[ebp].reg_es.d_selector
	call PushWord
;
	pop ax
	call PushWord
;
	pop ax
	call PushWord
;
	mov ax,word ptr [ebp].reg_eflags
	call PushWord
;
	mov ax,word ptr [ebp].reg_cs.d_selector
	call PushWord
;
	mov ax,word ptr [ebp].reg_eip
	call PushWord
;
	test [ebp].em_transfer,TRANSFER_CODE
	jz LowerZeroSelectors
;
	mov ax,[ebp].em_errorcode
	call PushWord
	jmp LowerZeroSelectors

LowerProt16:
	mov al,[ebp].em_transfer
	test al,TRANSFER_SWITCH
	jz LowerStackPushed16
;
	and al,3
	cmp al,3
	je ProtectionFault
;
	push word ptr [ebp].reg_ss.d_access
	push [ebp].reg_ss.d_base
	push [ebp].reg_ss.d_limit
	push [ebp].reg_esp
	push [ebp].reg_ss.d_selector
;
	push bx
	call GetStack
	push eax
	mov ax,dx
	call SwitchStackSelector
	pop eax
	mov [ebp].reg_esp,eax
	pop bx
;
	pop ax
	call PushWord
	pop eax
	mov edi,eax
	call PushWord
;
	pop ecx
	pop edx
	pop ax
;
	mov ah,[ebp].em_params
	or ah,ah
	jz LowerStackPushed16
;
	push bx
	mov ebx,edx
	mov dl,ah
;
	test al,ACCESS_SIZE
	jnz LowerCopy16
;
	movzx esi,si

LowerCopy16:
	add ebx,edi

LowerCopyLoop16:
	inc edi
	cmp edi,ecx
	jbe StackFault
	xor bx,bx
	jmp StackFault

LowerCopyLoopDo16:
	call ReadWord
	call PushWord
	inc edi
	add ebx,2
	sub dl,1
	jnz LowerCopyLoop16

LowerStackPushed16:
	test [ebp].em_transfer,TRANSFER_FLAGS
	jz LowerFlagsPushed16
;
	mov ax,word ptr [ebp].reg_eflags
	call PushWord

LowerFlagsPushed16:
	mov ax,[ebp].reg_cs.d_selector
	call PushWord
	mov ax,word ptr [ebp].reg_eip
	call PushWord
;
	test [ebp].em_transfer,TRANSFER_CODE
	jz LowerLoadIt
;
	mov ax,[ebp].em_errorcode
	call PushWord
	jmp LowerLoadIt

Lower32:
	test [ebp].reg_eflags,EFLAGS_VM
	jz LowerProt32

;state of the stack before and after switch by processor to exception or interrupt handler
;
; 32 bits case
;
;esp before switch
;       | old gs selector
;       | old fs selector
;       | old ds selector
;       | old es selector
;       | old ss selector
;   old esp
;   old eflags
;       | old cs selector
;   old eip
;   error code if exist
;esp after switch

LowerVm32:
	push [ebp].reg_esp
	push [ebp].reg_ss.d_selector
	call GetStack
	push eax
	mov ax,dx
	call SwitchStackSelector
	pop [ebp].reg_esp
;
	mov eax,2
	call SubFromStack
	mov ax,[ebp].reg_gs.d_selector
	call PushWord
;
	mov eax,2
	call SubFromStack
	mov ax,[ebp].reg_fs.d_selector
	call PushWord
;
	mov eax,2
	call SubFromStack
	mov ax,[ebp].reg_ds.d_selector
	call PushWord
;
	mov eax,2
	call SubFromStack
	mov ax,[ebp].reg_es.d_selector
	call PushWord
;
	mov eax,2
	call SubFromStack
	pop ax                  ;old ss
	call PushWord
;	
	pop eax                 ;old esp
	call PushDword
;
	mov eax,[ebp].reg_eflags
	call PushDword
;
	mov eax,2
	call SubFromStack
	mov ax,[ebp].reg_cs.d_selector   ;old cs
	call PushWord
;
	mov eax,[ebp].reg_eip             ;old eip
	call PushDword
;
	test [ebp].em_transfer,TRANSFER_CODE
	jz LowerZeroSelectors
;
	movzx eax,[ebp].em_errorcode
	call PushDword
	jmp LowerZeroSelectors

LowerProt32:
	mov al,[ebp].em_transfer
	test al,TRANSFER_SWITCH
	jz LowerStackPushed32
;
	and al,3                   ;select the RPL with TRANSFER_RPL
;
	push word ptr [ebp].reg_ss.d_access
	push [ebp].reg_ss.d_base
	push [ebp].reg_ss.d_limit
	push [ebp].reg_esp
	push [ebp].reg_ss.d_selector
;
	call GetStack
	push eax
	mov ax,dx
	call SwitchStackSelector
	pop [ebp].reg_esp
;
	mov eax,2
	call SubFromStack
	pop ax
	call PushWord
;
	pop eax
	mov edi,eax
	call PushDword
;
	pop ecx
	pop edx
	pop ax
;
	mov ah,[ebp].em_params
	or ah,ah
	jz LowerStackPushed32
;
	push bx
	mov ebx,edx
	mov dl,ah
;
	test al,ACCESS_SIZE
	jnz LowerCopy32
	movzx edi,di

LowerCopy32:
	add ebx,edi

LowerCopyLoop32:
	add edi,3
	cmp edi,ecx
	jbe LowerCopyLoopDo32
	xor bx,bx
	jmp StackFault

LowerCopyLoopDo32:
	call ReadDword
	call PushDword
	inc edi
	add ebx,4
	sub dl,1
	jnz LowerCopyLoop32

LowerStackPushed32:
	test [ebp].em_transfer,TRANSFER_FLAGS
	jz LowerFlagsPushed32
;
	mov eax,[ebp].reg_eflags
	call PushDword

LowerFlagsPushed32:
	mov eax,2
	call SubFromStack
	mov ax,[ebp].reg_cs.d_selector
	call PushWord
;
	mov eax,[ebp].reg_eip
	call PushDword
;
	test [ebp].em_transfer,TRANSFER_CODE
	jz LowerLoadIt
;
	movzx eax,[ebp].em_errorcode
	call PushDword
	jmp LowerLoadIt

LowerZeroSelectors:
	mov [ebp].reg_ds.d_selector,0
	mov [ebp].reg_ds.d_access,0
;
	mov [ebp].reg_es.d_selector,0
	mov [ebp].reg_es.d_access,0
;
	mov [ebp].reg_fs.d_selector,0
	mov [ebp].reg_fs.d_access,0
;
	mov [ebp].reg_gs.d_selector,0
	mov [ebp].reg_gs.d_access,0
;
	and [ebp].reg_eflags, NOT EFLAGS_VM

LowerLoadIt:
	pop ecx
	pop eax
	call TransferProt
	ret
TransferLower	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			JmpTss
;
;		DESCRIPTION:	Jump to a new TSS
;
;		PARAMETERS:		SS:EBP		CPU
;						BX			TSS SELECTOR
;						EAX			Base
;						ECX			Limit
;						EDI			ADDRESS OF DESCRIPTOR TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JmpTss	Proc near
	test dl,8
	jz short JmpTssCheck16

JmpTssCheck32:
	mov dh,ACCESS_SIZE
	cmp ecx,103
	jc InvalidTssFault
	jmp short JmpTssSizeOk

JmpTssCheck16:
	xor dh,dh
	cmp ecx,44
	jc InvalidTssFault

JmpTssSizeOk:
	call SaveTss
	push [ebp].reg_tr.d_selector
	mov [ebp].reg_tr.d_access,dh
	mov [ebp].reg_tr.d_selector,bx
	mov [ebp].reg_tr.d_base,eax
	mov [ebp].reg_tr.d_limit,ecx
	call LoadTss
;
	mov al,dl
	or al,2
	mov ebx,edi
	add ebx,5
	call WriteLinearByte     ;must set the new task as busy 
;
	pop bx                  ;we have the two tasks visible here
;
        movzx eax,[ebp].reg_tr.d_selector
        push eax                           ;task2
        movzx eax,bx
        push eax                           ;task1
;	call NotifyTaskSwitch
;	
	LoadDescriptor ProtectionFault
	jc ProtectionFault
;
	mov al,dl
	and al,NOT 2
	mov ebx,edi
	add ebx,5
	call WriteLinearByte     ;must clear the old task as busy'ness 
;
	mov bx,[ebp].reg_tr.d_selector
	and [ebp].reg_eflags,NOT EFLAGS_NT
	call ValidateTss
	ret
JmpTss	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CallTss
;
;		DESCRIPTION:	Call to a new TSS
;
;		PARAMETERS:		SS:EBP		CPU
;						BX			TSS SELECTOR
;						EAX			Base
;						ECX			Limit
;						EDI			ADDRESS OF DESCRIPTOR TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CallTss	Proc near
	test dl,8
	jz short CallTssCheck16

CallTssCheck32:
	mov dh,ACCESS_SIZE
	cmp ecx,103
	jc InvalidTssFault
	jmp short CallTssSizeOk

CallTssCheck16:
	xor dh,dh
	cmp ecx,44
	jc InvalidTssFault

CallTssSizeOk:
	call SaveTss
	push [ebp].reg_tr.d_selector
	mov [ebp].reg_tr.d_access,dh
	mov [ebp].reg_tr.d_selector,bx
	mov [ebp].reg_tr.d_base,eax
	mov [ebp].reg_tr.d_limit,ecx
	call LoadTss
        pop ax        ;the call tak selector
	push ax       ;used below
	call SetBacklink
;
	mov al,dl
	or al,2              ;the busy byte must be set
	mov ebx,edi
	add ebx,5
	call WriteLinearByte
;
	pop bx                  ;we have the two tasks visible here
;
        movzx eax,[ebp].reg_tr.d_selector
        push eax                           ;task2
        movzx eax,bx
        push eax                           ;task1
;	call NotifyTaskSwitch
;	
	LoadDescriptor ProtectionFault
	jc ProtectionFault
;
	mov al,dl
	or al,2         ;the busy byte must be left set
	mov ebx,edi
	add ebx,5
	call WriteLinearByte
;
	mov bx,[ebp].reg_tr.d_selector
	or [ebp].reg_eflags,EFLAGS_NT
	call ValidateTss
	ret
CallTss	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RetTss
;
;		DESCRIPTION:	Ret to a new TSS
;
;		PARAMETERS:		SS:EBP		CPU
;						BX			TSS SELECTOR
;						EAX			Base
;						ECX			Limit
;						EDI			ADDRESS OF DESCRIPTOR TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RetTss	Proc near
	test dl,8
	jz short RetTssCheck16

RetTssCheck32:
	mov dh,ACCESS_SIZE
	cmp ecx,103
	jc InvalidTssFault
	jmp short RetTssSizeOk

RetTssCheck16:
	xor dh,dh
	cmp ecx,44
	jc InvalidTssFault

RetTssSizeOk:
	and [ebp].reg_eflags,NOT EFLAGS_NT  ;the NT flag must be cleared
	call SaveTss
	push [ebp].reg_tr.d_selector
	mov [ebp].reg_tr.d_access,dh
	mov [ebp].reg_tr.d_selector,bx
	mov [ebp].reg_tr.d_base,eax
	mov [ebp].reg_tr.d_limit,ecx
	call LoadTss
;
	mov al,dl
	or al,2               ;the busy byte must be left set
	mov ebx,edi
	add ebx,5
	call WriteLinearByte
;
	pop bx                  ;we have the two tasks visible here
;
        movzx eax,[ebp].reg_tr.d_selector
        push eax                           ;task2
        movzx eax,bx
        push eax                           ;task1
;	call NotifyTaskSwitch
;	
	LoadDescriptor ProtectionFault
	jc ProtectionFault
;
	mov al,dl
	and al,NOT 2       ;the busy byte must be clear for the old task
	mov ebx,edi
	add ebx,5
	call WriteLinearByte
;
	mov bx,[ebp].reg_tr.d_selector
	call ValidateTss
	ret
RetTss	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CondLoadDescriptor
;
;		DESCRIPTION:	Load descriptor if privilege allows, no faults
;
;		PARAMETERS:		SS:EBP		CPU
;						BX			SELECTOR TO LOAD
;
;		RETURNS:		NC			VALID
;							EDX:EAX	DESCRIPTOR
;						CY			INVALID
;							BX		ERROR CODE FOR GPF (SELECTOR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondLoadDescriptor	Proc near
	test bx,0FFFCh
	jnz cond_load_descr_not_null
	stc
	ret

cond_load_descr_not_null:
	test bl,4
	jz cond_load_descr_gdt

cond_load_descr_ldt:
	test [ebp].reg_ldt.d_access,ACCESS_READ
	mov edi,OFFSET reg_ldt
	stc
	jnz cond_load_descr_do
	ret

cond_load_descr_gdt:
	mov edi,OFFSET reg_gdt

cond_load_descr_do:
	mov [ebp].em_pl,0
	movzx ecx,bx
	or cl,7
	dec ecx
	sub ecx,[ebp+edi].d_limit
	jc cond_load_descr_limit_ok
	stc
	ret

cond_load_descr_limit_ok:
	movzx ecx,bx
	and cl,0F8h
	add ecx,[ebp+edi].d_base
	push bx
	mov ebx,ecx
	call ReadLinearQword
	pop bx
	test dh,80h
	jnz cond_load_descr_present
	stc
	ret

cond_load_descr_present:
	test dh,1
	jnz cond_load_descr_accessed
	or dh,1
	push bx
	mov ebx,ecx
	call WriteLinearQword
	pop bx

cond_load_descr_accessed:
	clc
	ret
CondLoadDescriptor	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ValidateSegment
;
;		DESCRIPTION:	Validate a selector
;
;		PARAMETERS:		SS:EBP		CPU
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
	mov bx,ax
	call CondLoadDescriptor
	jnc ValidateSegmentDescrOk
	ret

ValidateSegmentDescrOk:
	mov	cl,byte ptr [ebp].reg_cs.d_access
	mov ch,bl
	and cx,303h
	cmp ch,cl
	jc ValidateSegmentEplOk
	mov cl,ch
ValidateSegmentEplOk:
	mov ch,dh
	shr ch,5
	and ch,3
	cmp cl,ch
	jbe ValidateSegmentDplOk
	stc
	ret

ValidateSegmentDplOk:
	test dh,10h
	jz ValidateSegmentNotAccessible
	clc
	ret

ValidateSegmentNotAccessible:
	stc	
	ret
ValidateSegment	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ValidateTssLdt
;
;		DESCRIPTION:	Validate LDT loaded from TSS, and load base & limit
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ValidateTssLdt

ValidateTssLdt	Proc near
	mov [ebp].em_pl,0
	mov bx,[ebp].reg_ldt.d_selector
	or bx,bx
	jz ValidateTssLdtDone
;
	test bx,4
	jnz InvalidTssFault
	LoadDescriptor InvalidTssFault
	and dl,1Fh
	cmp dl,2
	jne InvalidTssFault
;
	mov [ebp].reg_ldt.d_base,eax
	mov [ebp].reg_ldt.d_limit,ecx	
	mov [ebp].reg_ldt.d_access,ACCESS_READ
ValidateTssLdtDone:
	ret
ValidateTssLdt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ValidateTssCs
;
;		DESCRIPTION:	Validate CS loaded from TSS, and load descriptor
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ValidateTssCs

ValidateTssCs	Proc near
	mov [ebp].em_pl,0
	mov bx,[ebp].reg_cs.d_selector
	LoadDescriptor InvalidTssFault
	test dl,10h
	jz InvalidTssFault
;
	push cx
	mov cl,dl
	and cl,18h
	cmp cl,18h
	jne InvalidTssFault
;
	mov cl,dl
	shr cl,5
	mov ch,byte ptr [ebp].reg_cs.d_selector
	and cx,0303h
	cmp cl,ch
	pop cx
	jne InvalidTssFault
;
	mov [ebp].reg_cs.d_base,eax
	mov [ebp].reg_cs.d_limit,ecx
;
	mov ax,[ebp].reg_cs.d_selector
	and al,3
	test dh,40h
	jz ValidateTssCsSizeOk
	or al,ACCESS_SIZE

ValidateTssCsSizeOk:
	test dl,2
	jz ValidateTssCsReadOk
	or al,ACCESS_READ

ValidateTssCsReadOk:
	mov [ebp].reg_cs.d_access,al
	ret
ValidateTssCs	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadLdt
;
;		DESCRIPTION:	Load a ldt selector
;
;		PARAMETERS:		SS:EBP		CPU
;						AX			SEGMENT REGISTER TO VALIDATE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadLdt

LoadLdt	Proc near
	mov [ebp].em_pl,0
	mov bx,ax
	test bx,7
	jnz ProtectionFault
;
	or bx,bx
	jnz LoadLdtNonzero
	mov [ebp].reg_ldt.d_selector,bx
	mov [ebp].reg_ldt.d_access,0
	ret

LoadLdtNonzero:
	test bx,4
	jnz ProtectionFault
;
	LoadDescriptor ProtectionFault
	and dl,1Fh
	cmp dl,2
	jne ProtectionFault
;
	mov [ebp].reg_ldt.d_selector,bx
	mov [ebp].reg_ldt.d_base,eax
	mov [ebp].reg_ldt.d_limit,ecx	
	mov [ebp].reg_ldt.d_access,ACCESS_READ
	ret
LoadLdt	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadTr
;
;		DESCRIPTION:	Load a tr selector
;
;		PARAMETERS:		SS:EBP		CPU
;						AX			SEGMENT REGISTER TO VALIDATE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadTr

LoadTr	Proc near
	mov [ebp].em_pl,0
	mov bx,ax
	test bx,7
	jnz InvalidTssFault
;
	or bx,bx
	jz ProtectionFault
;
	test bx,4
	jnz ProtectionFault
;
	LoadDescriptor ProtectionFault
	mov dh,dl
	and dh,1Fh
	cmp dh,1
	je LoadTr16
	cmp dh,9
	je LoadTr32
	jmp ProtectionFault

LoadTr16:
	cmp ecx,44
	jc InvalidTssFault
;
	mov [ebp].reg_tr.d_selector,bx
	mov [ebp].reg_tr.d_base,eax
	mov [ebp].reg_tr.d_limit,ecx	
	mov [ebp].reg_tr.d_access,ACCESS_READ
;
	mov ebx,edi
	add ebx,5
	mov al,dl
	or al,2
	call WriteLinearByte
	ret

LoadTr32:
	cmp ecx,104
	jc InvalidTssFault
;
	mov [ebp].reg_tr.d_selector,bx
	mov [ebp].reg_tr.d_base,eax
	mov [ebp].reg_tr.d_limit,ecx	
	mov [ebp].reg_tr.d_access,ACCESS_READ OR ACCESS_SIZE
;
	mov ebx,edi
	add ebx,5
	mov al,dl
	or al,2
	call WriteLinearByte
	ret
LoadTr	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			JmpFar
;
;		DESCRIPTION:	Emulate protected mode far jump
;
;		PARAMETERS:		SS:EBP		CPU
;						BX:ESI		ADDRESS TO JMP TO
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public JmpFar

JmpFar	Proc near
	test [ebp].reg_cr0,CR0_PE
	jz JmpFarReal
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz JmpFarReal
;
	mov [ebp].em_pl,0
	LoadDescriptor ProtectionFault
	jc short JmpFarGate
;
	test dl,10h
	jnz JmpFarCodeOrData
;
	push cx
	mov cl,dl
	and cl,0Fh
	cmp cl,1
	je JmpFarTssCheckDpl
;
	cmp cl,9
	je JmpFarTssCheckDpl
	pop cx
	jmp ProtectionFault

JmpFarGate:
	and dl,0Fh
;
	cmp dl,4
	je short JmpFarCallGate
;
	cmp dl,0Ch
	je short JmpFarCallGate
;
	cmp dl,5
	je JmpFarTssGate
	jmp ProtectionFault

JmpFarCallGate:
	mov bx,ax
	LoadDescriptor ProtectionFault
	test dl,10h
	jnz JmpFarCodeOrData
	jmp ProtectionFault

JmpFarTssGate:
	mov bx,ax
	LoadDescriptor ProtectionFault
	test dl,10h
	jnz ProtectionFault
;
	push cx
	mov cl,dl
	and cl,0Fh	
	cmp cl,1                           ;16 bit available TSS
	je short JmpFarTss
;
	cmp cl,9
	je JmpFarTss                         ;32 bit available TSS
	pop cx
	jmp ProtectionFault

JmpFarTssCheckDpl:
	AssertDataDpl

JmpFarTss:
	pop cx
	call JmpTss
	ret

JmpFarCodeOrData:
	call TransferEqual
	ret

JmpFarReal:
	call TransferReal
	ret
JmpFar	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CallFar16
;
;		DESCRIPTION:	Emulate protected mode call far
;
;		PARAMETERS:		SS:EBP		CPU
;						BX:ESI		ADDRESS TO JMP TO
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CallFar16

CallFar16	Proc near
	test [ebp].reg_cr0,CR0_PE
	jz CallFarReal16
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz CallFarReal16
;
	mov [ebp].em_pl,0
	LoadDescriptor ProtectionFault
	jc CallFarGate16
	test dl,10h
	jnz CallFarNormal16
;
	AssertDataDpl
	push cx                   
	mov cl,dl
	and cl,0Fh
	cmp cl,1
	je CallFarTss16
	cmp cl,9
	je CallFarTss16
	pop cx                    
	jmp ProtectionFault

CallFarGate16:	
	and dl,0Fh
	cmp dl,4
	jne CallFarGate16Not4
;
	mov [ebp].em_params,cl
	mov [ebp].em_transfer,0
	mov bx,ax
	LoadDescriptor ProtectionFault
	test dl,10h
	jz ProtectionFault
	call TransferLower
	ret

CallFarGate16Not4:
	cmp dl,0Ch
	jne CallFarGate16NotC
;
	mov [ebp].em_params,cl
	mov [ebp].em_transfer,TRANSFER_32
	mov bx,ax
	LoadDescriptor ProtectionFault
	test dl,10h
	jz ProtectionFault
	call TransferLower
	ret

CallFarGate16NotC:
	cmp dl,5
	jne ProtectionFault
;	
	mov bx,ax
	LoadDescriptor InvalidTssFault
	test dl,10h
	jnz ProtectionFault
;
        push cx
        mov cl,dl
	and cl,0Fh
	cmp cl,1
	je CallFarTss16
;
	cmp cl,9
	je CallFarTss16
;
        pop cx              
	jmp ProtectionFault

CallFarTss16:
	pop cx	           
	call CallTss
	ret

CallFarNormal16:
	mov [ebp].em_params,0
	mov [ebp].em_transfer,0
	call TransferLower
	ret

CallFarReal16:
	push eax
	mov ax,[ebp].reg_cs.d_selector
	call PushWord
	mov ax,word ptr [ebp].reg_eip
	call PushWord
	pop eax
	call TransferReal
	ret
CallFar16	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CallFar32
;
;		DESCRIPTION:	Emulate protected mode call far
;
;		PARAMETERS:		SS:EBP		CPU
;						BX:ESI		ADDRESS TO JMP TO
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CallFar32

CallFar32	Proc near
	test [ebp].reg_cr0,CR0_PE
	jz CallFarReal32
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz CallFarReal32
;
	mov [ebp].em_pl,0
	LoadDescriptor ProtectionFault
	jc CallFarGate32
;
	test dl,10h
	jnz CallFarNormal32
;
	AssertDataDpl
	
	push cx
	mov cl,dl
	and cl,0Fh
	cmp cl,1
	je CallFarTss32
	cmp cl,9
	je CallFarTss32
	pop cx                    
	jmp ProtectionFault

CallFarGate32:	
	and dl,0Fh
	cmp dl,4
	jne CallFarGate32Not4
;
	mov [ebp].em_params,cl
	mov [ebp].em_transfer,0
	mov bx,ax
	LoadDescriptor ProtectionFault
	test dl,10h
	jz ProtectionFault
	call TransferLower
	ret

CallFarGate32Not4:
	cmp dl,0Ch
	jne CallFarGate32NotC
;
	mov [ebp].em_params,cl
	mov [ebp].em_transfer,TRANSFER_32
	mov bx,ax
	LoadDescriptor ProtectionFault
	test dl,10h
	jz ProtectionFault
	call TransferLower
	ret

CallFarGate32NotC:
	cmp dl,5
	jne ProtectionFault
;	
	mov bx,ax
	LoadDescriptor InvalidTssFault
	test dl,10h
	jnz ProtectionFault
;
        push cx
        mov cl,dl
	and cl,0Fh
	cmp cl,1
	je CallFarTss32
;
	cmp cl,9
	je CallFarTss32
;
        pop cx                   
	jmp ProtectionFault

CallFarTss32:	
        pop cx                   
	call CallTss
	ret

CallFarNormal32:
	mov [ebp].em_params,0
	mov [ebp].em_transfer,TRANSFER_32
	call TransferLower
	ret

CallFarReal32:
	push eax
	mov eax,2
	call SubFromStack
	mov ax,[ebp].reg_cs.d_selector
	call PushWord
;
	mov eax,[ebp].reg_eip
	call PushDword
;
	pop eax
	call TransferReal
	ret
CallFar32	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RetFar16
;
;		DESCRIPTION:	Emulate protected mode retf16
;
;		PARAMETERS:		SS:EBP		CPU
;						CL			# of params to remove
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RetFar16

RetFar16	Proc near
	call PopWord
	push ax
	call PopWord
	mov bx,ax
	pop si
	movzx esi,si
;
	test [ebp].reg_cr0,CR0_PE
	jz RetFarReal16
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz RetFarReal16
;
	mov [ebp].em_pl,0
	mov [ebp].em_params,cl
	mov [ebp].em_transfer,0
	call TransferHigher
	ret

RetFarReal16:
	call TransferReal
	ret
RetFar16	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RetFar32
;
;		DESCRIPTION:	Emulate protected mode retf32
;
;		PARAMETERS:		SS:EBP		CPU
;						CL			# of params to remove
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RetFar32

RetFar32	Proc near
	call PopDword
	push eax
	call PopDword
	mov bx,ax
	pop esi
;
	test [ebp].reg_cr0,CR0_PE
	jz RetFarReal32
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz RetFarReal32
;
	mov [ebp].em_pl,0
	mov [ebp].em_params,cl
	mov [ebp].em_transfer,TRANSFER_32
	call TransferHigher
	ret

RetFarReal32:
	call TransferReal
	ret
RetFar32	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ExcFar
;
;		DESCRIPTION:	Emulate protected mode exception
;
;		PARAMETERS:		SS:EBP		CPU
;						AL			EXCEPTION #
;						CX			0 IF NO ERROR CODE
;						BX			ERROR CODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ExcFar

ExcFar	Proc near
	test [ebp].reg_cr0,CR0_PE
	jz ExcFarReal

ExcFarPm:
	mov [ebp].em_pl,0
	mov [ebp].em_transfer,TRANSFER_FLAGS
	mov [ebp].em_params,0
	or cx,cx
	jz ExcPmErrorOk
;
	or [ebp].em_transfer,TRANSFER_CODE
	mov [ebp].em_errorcode,bx

ExcPmErrorOk:
	movzx bx,al
	shl bx,3
;
	movzx ecx,bx
	or cl,7
	dec ecx
	sub ecx,[ebp].reg_idt.d_limit
	jnc ProtectionFault
;
	movzx ecx,bx
	add ecx,[ebp].reg_idt.d_base
	mov ebx,ecx
	call ReadLinearQword
	test dh,80h
	jz IdtFault
;
	test dh,10h
	jnz IdtFault
;
	mov cl,dh
	and cl,0Fh
	cmp cl,5
	je ExcFarTssGate
;
	cmp cl,6
	je ExcFarInt16
;
	cmp cl,7
	je ExcFarTrap16
;
	cmp cl,0Eh
	je ExcFarInt32
;
	cmp cl,0Fh
	je ExcFarTrap32
;
	jmp IdtFault

ExcFarInt16:
	mov cx,EFLAGS_IF OR EFLAGS_TF
	jmp ExcFarLoad

ExcFarTrap16:
	mov cx,EFLAGS_TF
	jmp ExcFarLoad

ExcFarInt32:
	mov cx,EFLAGS_IF OR EFLAGS_TF
	or [ebp].em_transfer,TRANSFER_32
	jmp ExcFarLoad

ExcFarTrap32:
	mov cx,EFLAGS_TF
	or [ebp].em_transfer,TRANSFER_32

ExcFarLoad:
	push cx
	mov dx,ax
	shr eax,16
	xchg eax,edx	
	mov esi,eax
	mov bx,dx
	LoadDescriptor ProtectionFault
	test dl,10h
	jz ProtectionFault
;
	call TransferLower
;
	pop cx
	not cx
	and word ptr [ebp].reg_eflags,cx
	ret

ExcFarTssGate:
	shr eax,16
	mov bx,ax
	LoadDescriptor InvalidTssFault
;
	test dl,10h
	jnz ProtectionFault
;
	and dl,0Fh
	cmp dl,1
	je ExcFarTss
;
	cmp dl,9
	je ExcFarTss
;
	jmp ProtectionFault

ExcFarTss:	
	call CallTss
	ret

ExcFarReal:
	push ax
;
	mov ax,word ptr [ebp].reg_eflags
	call PushWord
;
	mov ax,[ebp].reg_cs.d_selector
	call PushWord
;
	mov ax,word ptr [ebp].reg_eip
	call PushWord
;
	or cx,cx
	jz ExcRealErrorOk
;
	mov ax,bx
	call PushWord

ExcRealErrorOk:
	pop bx
	movzx ebx,bl
	shl ebx,2
	add ebx,[ebp].reg_idt.d_base
	call ReadLinearDword
	movzx esi,ax
	shr eax,16
	mov bx,ax
	call TransferReal
	and word ptr [ebp].reg_eflags,NOT (EFLAGS_IF AND EFLAGS_TF)
	ret
ExcFar	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IntFar, HwInt
;
;		DESCRIPTION:	Emulate protected mode int
;
;		PARAMETERS:		SS:EBP		CPU
;						AL			INT #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IntFar
	public HwInt

HwInt	Proc near
	test [ebp].reg_cr0,CR0_PE
	jz IntFarReal
;
	test byte ptr [ebp].reg_eflags+2,2
	jnz IntFarVm
	jmp IntFarPm
HwInt	Endp

IntFar	Proc near
	test [ebp].reg_cr0,CR0_PE
	jz IntFarReal
;
	test byte ptr [ebp].reg_eflags+2,2		;test The VM indicator
	jnz IntFarVm
;
	mov ecx,[ebp].reg_eflags			;what is this verification for ? ### GIL ????###
	ror cx,4
	mov ch,[ebp].reg_cs.d_access
	and cx,303h
	cmp cl,ch
	jc PrivilegeFault
	jmp IntFarPm

IntFarVm:
	mov ecx,[ebp].reg_eflags
	and ecx,EFLAGS_IOPL
	cmp ecx,EFLAGS_IOPL
	jne PrivilegeFault

IntFarPm:
	mov [ebp].em_pl,0
	mov [ebp].em_transfer,TRANSFER_FLAGS
	mov [ebp].em_params,0
;
	movzx bx,al
	shl bx,3
;
	movzx ecx,bx
	or cl,7				;adjust the size of the interrupt number
	dec ecx				; 0..7FFh but 0FFh*8=7F8h + 7 = 7FFh
	sub ecx,[ebp].reg_idt.d_limit
	jnc ProtectionFault
;
	movzx ecx,bx
	add ecx,[ebp].reg_idt.d_base
	mov ebx,ecx
	call ReadLinearQword
	test dh,80h			;Is the descriptor present ?
	jz IdtFault
;
	test dh,10h			;descriptor type ? 1=Code or Data and 0= System
	jnz IdtFault
;
	xor bx,bx
	mov cl,byte ptr [ebp].reg_cs.d_access 	
	mov ch,dh
	shr ch,5				; target DPL
	and cx,303h
	cmp cl,ch				;CPL <= DPL 
	ja ProtectionFault
;
	mov cl,dh
	and cl,0Fh
	cmp cl,5
	je IntFarTssGate
;
	cmp cl,6
	je IntFarInt16
;
	cmp cl,7
	je IntFarTrap16
;
	cmp cl,0Eh
	je IntFarInt32
;
	cmp cl,0Fh
	je IntFarTrap32
;
	jmp IdtFault

IntFarInt16:
	mov cx,EFLAGS_IF OR EFLAGS_TF
	jmp IntFarLoad

IntFarTrap16:
	mov cx,EFLAGS_TF
	jmp IntFarLoad

IntFarInt32:
	mov cx,EFLAGS_IF OR EFLAGS_TF
	or [ebp].em_transfer,TRANSFER_32
	jmp IntFarLoad

IntFarTrap32:
	mov cx,EFLAGS_TF
	or [ebp].em_transfer,TRANSFER_32

IntFarLoad:
	push cx
	mov dx,ax
	shr eax,16
	xchg eax,edx	
	mov esi,eax			;get the offset in ESI
	mov bx,dx			;get the selector in BX
	LoadDescriptor ProtectionFault
	test dl,10h
	jz ProtectionFault
;
	call TransferLower
;
	pop cx
	not cx
	and word ptr [ebp].reg_eflags,cx
	ret

IntFarTssGate:
	shr eax,16
	mov bx,ax
	LoadDescriptor InvalidTssFault
;
        push cx
        mov cl,dl 
	test cl,10h
	jnz ProtectionFault
;
	and cl,0Fh
	cmp cl,1
	je IntFarTss
;
	cmp cl,9
	je IntFarTss
;
        pop cx                     
	jmp ProtectionFault

IntFarTss:	
        pop cx                     
	call CallTss
	ret

IntFarReal:
	push ax
	mov ax,word ptr [ebp].reg_eflags
	call PushWord
	mov ax,[ebp].reg_cs.d_selector
	call PushWord
	mov ax,word ptr [ebp].reg_eip
	call PushWord
	pop bx
        movzx ebx,bl
	shl ebx,2
	add ebx,[ebp].reg_idt.d_base
	call ReadLinearDword
	movzx esi,ax
	shr eax,16
	mov bx,ax
	call TransferReal
	and word ptr [ebp].reg_eflags,NOT (EFLAGS_IF AND EFLAGS_TF)
	ret
IntFar	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IretFar16
;
;		DESCRIPTION:	Emulate protected mode iret16
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IretFar16

IretFar16	Proc near
	call PopWord
	movzx esi,ax
	call PopWord
	mov bx,ax
;
	test [ebp].reg_cr0,CR0_PE
	jz IretFarReal16
;
	test byte ptr [ebp].reg_eflags+2,2
	jz IretFarPm16

IretFarVm16:
	mov ecx,[ebp].reg_eflags
	and ecx,EFLAGS_IOPL
	cmp ecx,EFLAGS_IOPL
	jne PrivilegeFault
	jmp IretFarReal16

IretFarPm16:
	mov [ebp].em_pl,0
	mov [ebp].em_params,0
	mov [ebp].em_transfer,TRANSFER_FLAGS
	call TransferHigher
	ret

IretFarReal16:
	call TransferReal
	call PopWord
	and eax,NOT EFLAGS_UNDEF
	or al,2
	mov word ptr [ebp].reg_eflags,ax
	ret
IretFar16	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IretFar32
;
;		DESCRIPTION:	Emulate protected mode iret32
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IretFar32

IretFar32	Proc near
	call PopDword
	mov esi,eax
	call PopDword
	mov bx,ax
;
	test [ebp].reg_cr0,CR0_PE
	jz RetFarReal32
;
	test byte ptr [ebp].reg_eflags+2,2
	jz IretFarPm32

IretFarVm32:
	mov ecx,[ebp].reg_eflags
	and ecx,EFLAGS_IOPL
	cmp ecx,EFLAGS_IOPL
	jne PrivilegeFault
	jmp IretFarReal32

IretFarPm32:
	mov [ebp].em_pl,0
	mov [ebp].em_params,0
	mov [ebp].em_transfer,TRANSFER_32 OR TRANSFER_FLAGS
	call TransferHigher
	ret

IretFarReal32:
	call TransferReal
	ret
IretFar32	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IretTss
;
;		DESCRIPTION:	IRET back to a TSS
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public IretTss

IretTss	Proc near
	mov [ebp].em_pl,0
	call GetBacklink
	mov bx,ax
	LoadDescriptor ProtectionFault
	test dl,10h
	jnz ProtectionFault
;
	push cx
	mov cl,dl
	and cl,0Fh	
	cmp cl,3
	je IretTssDo
;
	cmp cl,0Bh
	je IretTssDo
	pop cx
	jmp ProtectionFault

IretTssDo:
	pop cx
	call RetTss
	ret
IretTss	Endp

	END
