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
; EMPAGE.ASM
; Paging emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat

	NAME empage

include x86\emulate.inc
include x86\emseg.inc

	extrn ReadFromMemory:near
	extrn WriteToMemory:near

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FlushTlb
;
;		description:	Flush TLB register
;
;		PARAMETERS:		EBP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FlushTlb

FlushTlb	Proc near
	push ecx
	push edi
;
	mov ecx,32
	lea edi,[ebp].reg_tlb.tlb
	mov [ebp].reg_tlb.tlb_lru,0
	mov [ebp].reg_tlb.tlb_lmask,1
	mov [ebp].reg_tlb.tlb_lptr,edi
FlushTlbLoop:
	mov [edi].t_tag,-1
	add edi,SIZE tlb_entry_struc
	loop FlushTlbLoop
;
	pop edi
	pop ecx
	ret
FlushTlb	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SearchTlb
;
;		description:	search TLB for a physical address
;
;		PARAMETERS:		EBP		CPU
;						EBX			LINEAR ADDRESS
;
;		RETURNS:		NC			OK
;							EAX		PHYSICAL ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SearchTlb Proc near
	mov eax,ebx
	and ax,0F000h
	lea edi,[ebp].reg_tlb.tlb
	mov ecx,32
	mov edx,1
SearchTlbLoop:
	cmp eax,[edi].t_tag
	je SearchEntryFound
	add edi,SIZE tlb_entry_struc
	shl edx,1
	loop SearchTlbLoop
	stc
	ret

SearchEntryFound:
	mov eax,[edi].t_address
	or [ebp].reg_tlb.tlb_lru,edx
	clc
	ret
SearchTlb	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateTlb
;
;		description:	Find a free entry in TLB
;
;		PARAMETERS:		EBP		CPU
;
;		RETURNS:		SI		ADDRESS OF ENTRY			
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateTlb	Proc near
	mov ecx,32
	lea esi,[ebp].reg_tlb.tlb
AllocTlbFreeLoop:
	cmp [esi].t_tag,-1
	je AllocTlbDone
	add esi,SIZE tlb_entry_struc
	loop AllocTlbFreeLoop
;
	mov esi,[ebp].reg_tlb.tlb_lptr
	mov edx,[ebp].reg_tlb.tlb_lmask

	mov eax,[ebp].reg_tlb.tlb_lru
AllocTlbStealLoop:
	test edx,eax
	jz AllocTlbStealDo
	xor eax,edx
	rol edx,1
	add esi,SIZE tlb_entry_struc
	test dl,1
	jz AllocTlbStealLoop
	lea esi,[ebp].reg_tlb.tlb
	jmp AllocTlbStealLoop

AllocTlbStealDo:
	or eax,edx
	mov [ebp].reg_tlb.tlb_lru,eax
	rol edx,1
	mov edi,esi
	add edi,SIZE tlb_entry_struc
	test dl,1
	jz AllocTlbStealSave
	lea edi,[ebp].reg_tlb.tlb

AllocTlbStealSave:
	mov [ebp].reg_tlb.tlb_lptr,edi
	mov [ebp].reg_tlb.tlb_lmask,edx

AllocTlbDone:
	ret
AllocateTlb	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadPhysical
;
;		description:	read from bus
;
;		PARAMETERS:		EBP		CPU
;						EBX		PHYSICAL ADDRESS
;						ESI		BUFFER
;						ECX		NUMBER OF BYTE TO READ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPhysical Proc near
	push ecx
	push ebx
	push esi
	push ebp
	call ReadFromMemory
	ret
ReadPhysical	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WritePhysical
;
;		description:	write to bus
;
;		PARAMETERS:		EBP		CPU
;						EBX		PHYSICAL ADDRESS
;						ESI		BUFFER
;						ECX		SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePhysical Proc near
	push ecx
	push ebx
	push esi
	push ebp
	call WriteToMemory
	ret
WritePhysical	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LinearToPhysical
;
;		description:	Translate a linear address to a physical address
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;
;		RETURNS:		EAX		PHYSICAL ADDRESS & ATTRIBUTES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LinearToPhysical	Proc near
	push ebx
	call SearchTlb
	jnc LinearToPhysicalDone
;
	call AllocateTlb
	push esi
	mov [esi].t_tag,ebx
	add esi,OFFSET t_address
	shr ebx,20
	and ebx,0FFCh
	mov eax,[ebp].reg_cr3
	and ax,0F000h
	add ebx,eax
	push ebx
	mov ecx,4
	call ReadPhysical
	pop ebx
	pop esi
;
	mov ch,byte ptr [esi].t_address
	test ch,1
	jnz LinearToPhysicalDirOk
;
	mov eax,-1
	xchg eax,[esi].t_tag
	mov [ebp].reg_cr2,eax
	xor bx,bx
	jmp PageFault

LinearToPhysicalDirOk:
	push ecx
	test ch,20h
	jnz LinearToPhysicalDirAccessed
	push esi
	or byte ptr [esi].t_address,20h
	mov ecx,4
	add esi,OFFSET t_address
	call WritePhysical
	pop esi

LinearToPhysicalDirAccessed:
	mov ebx,[esi].t_tag
	shr ebx,10
	and ebx,0FFCh
	mov eax,[esi].t_address
	and ax,0F000h
	add ebx,eax
	push esi
	add esi,OFFSET t_address
	push ebx
	mov ecx,4
	call ReadPhysical
	pop ebx
	pop esi
;
	pop ecx
	mov cl,byte ptr [esi].t_address
	test cl,1
	jnz LinearToPhysicalPageOk
;
	mov eax,-1
	xchg eax,[esi].t_tag
	mov [ebp].reg_cr2,eax
	xor bx,bx
	jmp PageFault

LinearToPhysicalPageOk:
	and ch,cl
	and ch,3
	and cl,NOT 3
	or cl,ch
	push ecx
	test cl,20h
	jnz LinearToPhysicalPageAccessed
	push esi
	or byte ptr [esi].t_address,20h
	mov ecx,4
	add esi,OFFSET t_address
	call WritePhysical
	pop esi

LinearToPhysicalPageAccessed:
	pop ecx
;
	mov eax,[esi].t_tag
	and ax,0F000h
	mov [esi].t_tag,eax
;	
	mov eax,[esi].t_address
	and ax,0F000h
	or al,cl
	mov [esi].t_address,eax

LinearToPhysicalDone:
	pop ebx
	ret
LinearToPhysical	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CondLinearToPhysical
;
;		description:	Translate a linear address to a physical address
;						no page faults
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;
;		RETURNS:		EAX		PHYSICAL ADDRESS & ATTRIBUTES
;						NC		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondLinearToPhysical	Proc near
	push ebx
	call SearchTlb
	jnc CondLinearToPhysicalDone
;
	call AllocateTlb
	push esi
	mov [esi].t_tag,ebx
	add esi,OFFSET t_address
	shr ebx,20
	and ebx,0FFCh
	mov eax,[ebp].reg_cr3
	and ax,0F000h
	add ebx,eax
	push ebx
	mov ecx,4
	call ReadPhysical
	pop ebx
	pop esi
;
	mov ch,byte ptr [esi].t_address
	test ch,1
	jnz CondLinearToPhysicalDirOk
;
	mov [esi].t_tag,-1
	stc
	jmp CondLinearToPhysicalDone

CondLinearToPhysicalDirOk:
	push ecx
	test ch,20h
	jnz CondLinearToPhysicalDirAccessed
	push esi
	or byte ptr [esi].t_address,20h
	mov ecx,4
	add esi,OFFSET t_address
	call WritePhysical
	pop esi

CondLinearToPhysicalDirAccessed:
	mov ebx,[esi].t_tag
	shr ebx,10
	and ebx,0FFCh
	mov eax,[esi].t_address
	and ax,0F000h
	add ebx,eax
	push esi
	add esi,OFFSET t_address
	push ebx
	mov ecx,4
	call ReadPhysical
	pop ebx
	pop esi
;
	pop ecx
	mov cl,byte ptr [esi].t_address
	test cl,1
	jnz CondLinearToPhysicalPageOk
;
	mov [esi].t_tag,-1
	stc
	jmp CondLinearToPhysicalDone

CondLinearToPhysicalPageOk:
	and ch,cl
	and ch,3
	and cl,NOT 3
	or cl,ch
	push ecx
	test cl,20h
	jnz CondLinearToPhysicalPageAccessed
	push esi
	or byte ptr [esi].t_address,20h
	mov ecx,4
	add esi,OFFSET t_address
	call WritePhysical
	pop esi

CondLinearToPhysicalPageAccessed:
	pop ecx
;
	mov eax,[esi].t_tag
	and ax,0F000h
	mov [esi].t_tag,eax
;	
	mov eax,[esi].t_address
	and ax,0F000h
	or al,cl
	mov [esi].t_address,eax
	clc

CondLinearToPhysicalDone:
	pop ebx
	ret
CondLinearToPhysical	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadPaged
;
;		description:	Read paged
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;						ECX		NUMBER OF BYTE TO READ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPaged	Proc near
	lea esi,[ebp].req_buf
ReadPagedLoop:
	push ebx
	push ecx
	push esi
;
	call LinearToPhysical
	test al,4
	jnz ReadLinearPrivOk
	test [ebp].em_pl,ACCESS_RPL
	jz ReadLinearPrivOk
;
	mov [ebp].reg_cr2,ebx
	mov bx,4
	jmp PageFault

ReadLinearPrivOk:
	and ax,0F000h
	and ebx,0FFFh
	or eax,ebx
	mov ebx,eax
	pop esi
	pop ecx
;
	push ecx
	push esi
	not eax
	and eax,0FFFh
	inc eax
	cmp ecx,eax
	jbe ReadPagedWhole
	mov ecx,eax
ReadPagedWhole:
	push ecx
	call ReadPhysical
	pop eax
	pop esi
	pop ecx
	pop ebx
	sub ecx,eax
	jz ReadPagedDone
	add esi,eax
	add ebx,eax
	jmp ReadPagedLoop

ReadPagedDone:
	ret
ReadPaged	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WritePaged
;
;		description:	Write paged
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;						ECX		NUMBER OF BYTE TO WRITE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePaged	Proc near
	lea esi,[ebp].req_buf
WritePagedLoop:
	push ebx
	push ecx
	push esi
;
	call LinearToPhysical
	test al,4
	jnz WritePagedUserOk
	test [ebp].em_pl,ACCESS_RPL
	jz WritePagedUserOk
;
	mov [ebp].reg_cr2,ebx
	mov bx,4
	jmp PageFault

WritePagedUserOk:
	test al,2
	jnz WritePagedPrivOk
	test [ebp].em_pl,ACCESS_RPL
	jnz WritePagedPrivFault
	test [ebp].reg_cr0,CR0_WP
	jz WritePagedPrivOk

WritePagedPrivFault:
	mov [ebp].reg_cr2,ebx
	mov bx,2
	jmp PageFault
	
WritePagedPrivOk:
	and ax,0F000h
	and ebx,0FFFh
	or eax,ebx
	mov ebx,eax
	pop esi
	pop ecx
;
	push ecx
	push esi
	not eax
	and eax,0FFFh
	inc eax
	cmp ecx,eax
	jbe WritePagedWhole
	mov ecx,eax
WritePagedWhole:
	push ecx
	call WritePhysical
	pop eax
	pop esi
	pop ecx
	pop ebx
	sub ecx,eax
	jz WritePagedDone
	add esi,eax
	add ebx,eax
	jmp WritePagedLoop

WritePagedDone:
	ret
WritePaged	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadLinear
;
;		description:	read from linear memory
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;						ECX		NUMBER OF BYTE TO READ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadLinear Proc near
	test [ebp].reg_cr0,CR0_PG
	jz ReadLinearNormal
	call ReadPaged
	ret

ReadLinearNormal:
	lea esi,[ebp].req_buf
	call ReadPhysical
	ret
ReadLinear	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteLinear
;
;		description:	write to linear address
;
;		PARAMETERS:		EBP		CPU
;						EBX		PHYSICAL ADDRESS
;						ECX		SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteLinear Proc near
	test [ebp].reg_cr0,CR0_PG
	jz WriteLinearNormal
	call WritePaged
	ret

WriteLinearNormal:
	lea esi,[ebp].req_buf
	call WritePhysical
	ret
WriteLinear	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CondReadPaged
;
;		description:	Read paged without page faults
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;						ECX		NUMBER OF BYTE TO READ
;
;		RETURNS:		ECX		NUBER OF BYTES READ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondReadPaged	Proc near
	lea esi,[ebp].req_buf
CondReadPagedLoop:
	push ebx
	push ecx
	push esi
;
	call CondLinearToPhysical
	jc CondReadPagedFailed
;
	test al,4
	jnz CondReadLinearPrivOk
	test [ebp].reg_cs.d_access,ACCESS_RPL
	jz CondReadLinearPrivOk
	jmp CondReadPagedDone

CondReadLinearPrivOk:
	and ax,0F000h
	and ebx,0FFFh
	or eax,ebx
	mov ebx,eax
	pop esi
	pop ecx
;
	push ecx
	push esi
	not eax
	and eax,0FFFh
	inc eax
	cmp ecx,eax
	jbe CondReadPagedWhole
	mov ecx,eax
CondReadPagedWhole:
	push ecx
	call ReadPhysical
	pop eax
	pop esi
	pop ecx
	pop ebx
	add esi,eax
	add ebx,eax
	sub ecx,eax
	jz CondReadPagedDone
	jmp CondReadPagedLoop

CondReadPagedFailed:
	pop esi
	pop ecx
	pop ebx

CondReadPagedDone:
	mov ecx,esi
	lea esi,[ebp].req_buf
	sub ecx,esi
	ret
CondReadPaged	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CondReadLinear
;
;		description:	conditional read from linear memory
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;						ECX		NUMBER OF BYTE TO READ
;
;		RETURNS:		ECX		NUMBER OF VALID BYTES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CondReadLinear

CondReadLinear Proc near
	test [ebp].reg_cr0,CR0_PG
	jz CondReadLinearNormal
	call CondReadPaged
	ret

CondReadLinearNormal:
	lea esi,[ebp].req_buf
	push ecx
	call ReadPhysical
	pop ecx
	ret
CondReadLinear	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadLinearByte
;
;		DESCRIPTION:	Read one byte of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;
;		RETURNS:		AL		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadLinearByte

ReadLinearByte	Proc near
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov ecx,1
	call ReadLinear
	lea esi,[ebp].req_buf
	mov al,[esi]
;	
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	ret
ReadLinearByte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadLinearWord
;
;		DESCRIPTION:	Read one word of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;
;		RETURNS:		AX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadLinearWord

ReadLinearWord	Proc near
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov ecx,2
	call ReadLinear
	lea esi,[ebp].req_buf
	mov ax,[esi]
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	ret
ReadLinearWord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadLinearDword
;
;		DESCRIPTION:	Read one dword of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;
;		RETURNS:		EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadLinearDword

ReadLinearDword	Proc near
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov ecx,4
	call ReadLinear
	lea esi,[ebp].req_buf
	mov eax,[esi]
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	ret
ReadLinearDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadLinearFword
;
;		DESCRIPTION:	Read one fword of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;
;		RETURNS:		DX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadLinearFword

ReadLinearFword	Proc near
	push ebx
	push ecx
	push esi
	push edi
;
	mov ecx,6
	call ReadLinear
	lea esi,[ebp].req_buf
	mov eax,[esi]
	mov dx,[esi+4]
;
	pop edi
	pop esi
	pop ecx
	pop ebx
	ret
ReadLinearFword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadLinearQword
;
;		DESCRIPTION:	Read one qword of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;
;		RETURNS:		EDX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadLinearQword

ReadLinearQword	Proc near
	push ebx
	push ecx
	push esi
	push edi
;
	mov ecx,8
	call ReadLinear
	lea esi,[ebp].req_buf
	mov eax,[esi]
	mov edx,[esi+4]
;
	pop edi
	pop esi
	pop ecx
	pop ebx
	ret
ReadLinearQword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadLinearTbyte
;
;		DESCRIPTION:	Read one tbyte of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;
;		RETURNS:		CX:EDX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadLinearTbyte

ReadLinearTbyte	Proc near
	push ebx
	push esi
	push edi
;
	mov ecx,10
	call ReadLinear
	lea esi,[ebp].req_buf
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
;
	pop edi
	pop esi
	pop ebx
	ret
ReadLinearTbyte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteLinearByte
;
;		DESCRIPTION:	write one byte of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;						AL		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteLinearByte

WriteLinearByte	Proc near
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	lea esi,[ebp].req_buf
	mov [esi],al
	mov ecx,1
	call WriteLinear
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
WriteLinearByte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteLinearWord
;
;		DESCRIPTION:	Write one word of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;						AX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteLinearWord

WriteLinearWord	Proc near
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	lea esi,[ebp].req_buf
	mov [esi],ax
	mov ecx,2
	call WriteLinear
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
WriteLinearWord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteLinearDword
;
;		DESCRIPTION:	Write one dword of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;						EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteLinearDword

WriteLinearDword	Proc near
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	lea esi,[ebp].req_buf
	mov [esi],eax
	mov ecx,4
	call WriteLinear
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
WriteLinearDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteLinearFword
;
;		DESCRIPTION:	Write one fword of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;						DX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteLinearFword

WriteLinearFword	Proc near
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	lea esi,[ebp].req_buf
	mov [esi],eax
	mov [esi+4],dx
	mov ecx,6
	call WriteLinear
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
WriteLinearFword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteLinearQword
;
;		DESCRIPTION:	Write one qword of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;						EDX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteLinearQword

WriteLinearQword	Proc near
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	lea esi,[ebp].req_buf
	mov [esi],eax
	mov [esi+4],edx
	mov ecx,8
	call WriteLinear
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
WriteLinearQword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteLinearTbyte
;
;		DESCRIPTION:	Write one tbyte of data
;
;		PARAMETERS:		EBP		CPU
;						EBX		LINEAR ADDRESS
;						CX:EDX:EAX		DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteLinearTbyte

WriteLinearTbyte	Proc near
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	lea esi,[ebp].req_buf
	mov [esi],eax
	mov [esi+4],edx
	mov [esi+8],cx
	mov ecx,10
	call WriteLinear
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
WriteLinearTbyte	Endp

	END
