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
; EMTSS.ASM
; TSS emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat

	NAME emtss

include ..\core\emulate.inc
include ..\core\emcom.inc
include ..\core\empage.inc
include ..\core\emseg.inc

.code

tss16	STRUC

tss16_back_link	DW ?
tss16_sp0		DW ?
tss16_ss0		DW ?
tss16_sp1		DW ?
tss16_ss1		DW ?
tss16_sp2		DW ?
tss16_ss2		DW ?
tss16_ip		DW ?
tss16_flags		DW ?
tss16_ax		DW ?
tss16_cx		DW ?
tss16_dx		DW ?
tss16_bx		DW ?
tss16_sp		DW ?
tss16_bp		DW ?
tss16_si		DW ?
tss16_di		DW ?
tss16_es		DW ?
tss16_cs		DW ?
tss16_ss		DW ?
tss16_ds		DW ?
tss16_ldt		DW ?

tss16	ENDS

tss32	STRUC

tss32_back_link	DW ?,?
tss32_esp0		DD ?
tss32_ss0		DW ?,?
tss32_esp1		DD ?
tss32_ss1		DW ?,?
tss32_esp2		DD ?
tss32_ss2		DW ?,?
tss32_cr3		DD ?
tss32_eip		DD ?
tss32_eflags	DD ?
tss32_eax		DD ?
tss32_ecx		DD ?
tss32_edx		DD ?
tss32_ebx		DD ?
tss32_esp		DD ?
tss32_ebp		DD ?
tss32_esi		DD ?
tss32_edi		DD ?
tss32_es		DW ?,?
tss32_cs		DW ?,?
tss32_ss		DW ?,?
tss32_ds		DW ?,?
tss32_fs		DW ?,?
tss32_gs		DW ?,?
tss32_ldt		DW ?,?
tss32_t			DW ?
tss32_bitmap	DW ?

tss32	ENDS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveTss16
;
;		DESCRIPTION:	Save state in 16-bit TSS
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveTss16	Proc near
	push eax
	push ebx
	mov ebx,[ebp].reg_tr.d_base
;
	add ebx,OFFSET tss16_ip
	mov ax,word ptr [ebp].reg_eip
	call WriteLinearWord	
;
	add ebx,2
	mov ax,word ptr [ebp].reg_eflags
	call WriteLinearWord
;
	add ebx,2
	mov ax,word ptr [ebp].reg_eax
	call WriteLinearWord
;
	add ebx,2
	mov ax,word ptr [ebp].reg_ecx
	call WriteLinearWord
;
	add ebx,2
	mov ax,word ptr [ebp].reg_edx
	call WriteLinearWord
;
	add ebx,2
	mov ax,word ptr [ebp].reg_ebx
	call WriteLinearWord
;
	add ebx,2
	mov ax,word ptr [ebp].reg_esp
	call WriteLinearWord
;
	add ebx,2
	mov ax,word ptr [ebp].reg_ebp
	call WriteLinearWord
;
	add ebx,2
	mov ax,word ptr [ebp].reg_esi
	call WriteLinearWord
;
	add ebx,2
	mov ax,word ptr [ebp].reg_edi
	call WriteLinearWord
;
	add ebx,2
	mov ax,[ebp].reg_es.d_selector
	call WriteLinearWord
;
	add ebx,2
	mov ax,[ebp].reg_cs.d_selector
	call WriteLinearWord
;
	add ebx,2
	mov ax,[ebp].reg_ss.d_selector
	call WriteLinearWord
;
	add ebx,2
	mov ax,[ebp].reg_ds.d_selector
	call WriteLinearWord
;
	pop ebx
	pop eax
	ret
SaveTss16	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveTss32
;
;		DESCRIPTION:	Save state in 32-bit TSS
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveTss32	Proc near
	push eax
	push ebx
	mov ebx,[ebp].reg_tr.d_base
;
	add ebx,OFFSET tss32_eip
	mov eax,[ebp].reg_eip
	call WriteLinearDword	
;
	add ebx,4
	mov eax,[ebp].reg_eflags
	call WriteLinearDword	
;
	add ebx,4
	mov eax,[ebp].reg_eax
	call WriteLinearDword	
;
	add ebx,4
	mov eax,[ebp].reg_ecx
	call WriteLinearDword	
;
	add ebx,4
	mov eax,[ebp].reg_edx
	call WriteLinearDword	
;
	add ebx,4
	mov eax,[ebp].reg_ebx
	call WriteLinearDword	
;
	add ebx,4
	mov eax,[ebp].reg_esp
	call WriteLinearDword	
;
	add ebx,4
	mov eax,[ebp].reg_ebp
	call WriteLinearDword	
;
	add ebx,4
	mov eax,[ebp].reg_esi
	call WriteLinearDword	
;
	add ebx,4
	mov eax,[ebp].reg_edi
	call WriteLinearDword	
;
	add ebx,4
	movzx eax,word ptr [ebp].reg_es.d_selector
	call WriteLinearDword	
;
	add ebx,4
	movzx eax,word ptr [ebp].reg_cs.d_selector
	call WriteLinearDword	
;
	add ebx,4
	movzx eax,word ptr [ebp].reg_ss.d_selector
	call WriteLinearDword	
;
	add ebx,4
	movzx eax,word ptr [ebp].reg_ds.d_selector
	call WriteLinearDword	
;
	add ebx,4
	movzx eax,word ptr [ebp].reg_fs.d_selector
	call WriteLinearDword	
;
	add ebx,4
	movzx eax,word ptr [ebp].reg_gs.d_selector
	call WriteLinearDword	
;
	pop ebx
	pop eax
	ret
SaveTss32	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveTss
;
;		DESCRIPTION:	Save state to TSS
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveTss

SaveTss:
	test [ebp].reg_tr.d_access,ACCESS_SIZE
	jnz SaveTss32
	jmp SaveTss16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadTss16
;
;		DESCRIPTION:	Load state from 16-bit TSS (no checks)
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadTss16	Proc near
	push eax
	push ebx
;
	mov ebx,[ebp].reg_tr.d_base
;
	add ebx,OFFSET tss16_ip
	call ReadLinearWord
	mov word ptr [ebp].reg_eip,ax
;
	add ebx,2
	call ReadLinearWord
	mov word ptr [ebp].reg_eflags,ax
;
	add ebx,2
	call ReadLinearWord
	mov word ptr [ebp].reg_eax,ax
;
	add ebx,2
	call ReadLinearWord
	mov word ptr [ebp].reg_ecx,ax
;
	add ebx,2
	call ReadLinearWord
	mov word ptr [ebp].reg_edx,ax
;
	add ebx,2
	call ReadLinearWord
	mov word ptr [ebp].reg_ebx,ax
;
	add ebx,2
	call ReadLinearWord
	mov word ptr [ebp].reg_esp,ax
;
	add ebx,2
	call ReadLinearWord
	mov word ptr [ebp].reg_ebp,ax
;
	add ebx,2
	call ReadLinearWord
	mov word ptr [ebp].reg_esi,ax
;
	add ebx,2
	call ReadLinearWord
	mov word ptr [ebp].reg_edi,ax
;
	add ebx,2
	call ReadLinearWord
	mov [ebp].reg_es.d_selector,ax
	mov [ebp].reg_es.d_access,0
;
	add ebx,2
	call ReadLinearWord
	mov [ebp].reg_cs.d_selector,ax
	mov [ebp].reg_cs.d_access,0
;
	add ebx,2
	call ReadLinearWord
	mov [ebp].reg_ss.d_selector,ax
	mov [ebp].reg_ss.d_access,0
;
	add ebx,2
	call ReadLinearWord
	mov [ebp].reg_ds.d_selector,ax
	mov [ebp].reg_ds.d_access,0
;
	add ebx,2
	call ReadLinearWord
	mov [ebp].reg_ldt.d_selector,ax
	mov [ebp].reg_ldt.d_access,0
;
	pop ebx
	pop eax
	ret
LoadTss16	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadTss32
;
;		DESCRIPTION:	Load state from 32-bit TSS (no checks)
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadTss32	Proc near
	push eax
	push ebx
	mov ebx,[ebp].reg_tr.d_base
;
	add ebx,OFFSET tss32_cr3
	call ReadLinearDword
	cmp eax,[ebp].reg_cr3
	mov [ebp].reg_cr3,eax
	je LoadTss32Flushed
	call FlushTlb

LoadTss32Flushed:
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_eip,eax
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_eflags,eax
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_eax,eax
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_ecx,eax
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_edx,eax
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_ebx,eax
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_esp,eax
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_ebp,eax
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_esi,eax
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_edi,eax
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_es.d_selector,ax
	mov [ebp].reg_es.d_access,0
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_cs.d_selector,ax
	mov [ebp].reg_cs.d_access,0
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_ss.d_selector,ax
	mov [ebp].reg_ss.d_access,0
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_ds.d_selector,ax
	mov [ebp].reg_ds.d_access,0
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_fs.d_selector,ax
	mov [ebp].reg_fs.d_access,0
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_gs.d_selector,ax
	mov [ebp].reg_gs.d_access,0
;
	add ebx,4
	call ReadLinearDword
	mov [ebp].reg_ldt.d_selector,ax
	mov [ebp].reg_ldt.d_access,0
;
	add ebx,4
	call ReadLinearWord
	test al,1
	jz LoadTssNoTrap
	or [ebp].em_flags,trap_fault

LoadTssNoTrap:
	add ebx,2
	call ReadLinearWord
	movzx eax,ax
	add eax,[ebp].reg_tr.d_base
	mov [ebp].bitmap_base,eax
;
	pop ebx
	pop eax
	ret
LoadTss32	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadTss
;
;		DESCRIPTION:	Load state from TSS
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadTss

LoadTss:
	test [ebp].reg_tr.d_access,ACCESS_SIZE
	jnz LoadTss32
	jmp LoadTss16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ValidateTss
;
;		DESCRIPTION:	Validate descriptors in new TSS
;
;		PARAMETERS:		SS:EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ValidateTss

ValidateTss	Proc near
	call ValidateTssLdt
	or [ebp].reg_cr0,CR0_TS
;
	test [ebp].reg_eflags,EFLAGS_VM
	jz ValidatePmTss

ValidateVmTss:
	mov [ebp].reg_cs.d_limit,0FFFFh
	mov [ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_WRITE OR 3
	mov ax,[ebp].reg_cs.d_selector
	mov esi,OFFSET reg_cs
	call LoadSegment
;
	mov [ebp].reg_ss.d_limit,0FFFFh
	mov [ebp].reg_ss.d_access,ACCESS_READ OR ACCESS_WRITE OR 3
	mov ax,[ebp].reg_ss.d_selector
	mov esi,OFFSET reg_ss
	call LoadSegment
;
	mov [ebp].reg_ds.d_limit,0FFFFh
	mov [ebp].reg_ds.d_access,ACCESS_READ OR ACCESS_WRITE OR 3
	mov ax,[ebp].reg_ds.d_selector
	mov esi,OFFSET reg_ds
	call LoadSegment
;
	mov [ebp].reg_es.d_limit,0FFFFh
	mov [ebp].reg_es.d_access,ACCESS_READ OR ACCESS_WRITE OR 3
	mov ax,[ebp].reg_es.d_selector
	mov esi,OFFSET reg_es
	call LoadSegment
;
	mov [ebp].reg_fs.d_limit,0FFFFh
	mov [ebp].reg_fs.d_access,ACCESS_READ OR ACCESS_WRITE OR 3
	mov ax,[ebp].reg_fs.d_selector
	mov esi,OFFSET reg_fs
	call LoadSegment
;
	mov [ebp].reg_gs.d_limit,0FFFFh
	mov [ebp].reg_gs.d_access,ACCESS_READ OR ACCESS_WRITE OR 3
	mov ax,[ebp].reg_gs.d_selector
	mov esi,OFFSET reg_gs
	call LoadSegment
	ret

ValidatePmTss:
	mov al,[ebp].reg_cs.d_access
	and al,3
	mov [ebp].em_pl,al
;
	call ValidateTssCs
;
	mov ax,[ebp].reg_ss.d_selector
	mov esi,OFFSET reg_ss
	call LoadSegment
;
	mov ax,[ebp].reg_ds.d_selector
	mov esi,OFFSET reg_es
	call LoadSegment
;
	mov ax,[ebp].reg_es.d_selector
	mov esi,OFFSET reg_ds
	call LoadSegment
;
	mov ax,[ebp].reg_fs.d_selector
	mov esi,OFFSET reg_fs
	call LoadSegment
;
	mov ax,[ebp].reg_gs.d_selector
	mov esi,OFFSET reg_gs
	call LoadSegment
;
	test [ebp].em_flags,trap_fault
	jz ValidateNoTrap
	or [ebp].reg_dr6,8000h
	jmp TrapFault

ValidateNoTrap:
	ret
ValidateTss	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetBacklink
;
;		DESCRIPTION:	Get backlink in current TSS
;
;		PARAMETERS:		SS:EBP		CPU
;
;		RETRUNS:		AX			BACKLINK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetBacklink

GetBacklink	Proc near
	push ebx
	mov ebx,[ebp].reg_tr.d_base
	call ReadLinearWord
	pop ebx
	ret
GetBacklink	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetBacklink
;
;		DESCRIPTION:	Set backlink in current TSS
;
;		PARAMETERS:		SS:EBP		CPU
;						AX			BACKLINK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetBacklink

SetBacklink	Proc near
	push ebx
	mov ebx,[ebp].reg_tr.d_base
	call WriteLinearWord
	pop ebx
	ret
SetBacklink	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetStack
;
;		DESCRIPTION:	Get stack from TSS
;
;		PARAMETERS:		SS:EBP		CPU
;						AL			STACK # (0..2)
;
;		RETRUNS:		DX:EAX		STACK POINTER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetStack

GetStack	Proc near
	push ebx
	test [ebp].reg_tr.d_access,ACCESS_SIZE
	jnz GetStack32

GetStack16:
	mov ebx,[ebp].reg_tr.d_base
	add ebx,OFFSET tss16_sp0
	movzx eax,al
	shl eax,2
	add ebx,eax
	call ReadLinearDword
	mov edx,eax
	shr edx,16
	movzx eax,ax
	jmp GetStackDone

GetStack32:
	mov ebx,[ebp].reg_tr.d_base
	add ebx,OFFSET tss32_esp0
	movzx eax,al
	shl eax,3
	add ebx,eax
	call ReadLinearFword

GetStackDone:
	pop ebx
	ret
GetStack	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckBitmap
;
;		DESCRIPTION:	Check I/O permission bitmap
;
;		PARAMETERS:		SS:EBP		CPU
;						ECX			Number of ports
;						DX			I/O port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CheckBitmap

CheckBitmap	Proc near
	jmp PrivilegeFault
	ret
CheckBitmap	Endp

	END
