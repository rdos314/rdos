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
; DISASM.ASM
; Dissambler support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat

	NAME emulate

include x86\emulate.inc
include x86\empage.inc

   extrn dis_ass_one:near
   extrn op_code_size
   extrn data_code_size
   extrn WriteRegs:near

.code
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DisAssemble
;
;		DESCRIPTION:	Disassemble current instruction
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public DisAssemble

DisAssemble	Proc near
	push ebp
	mov ebp,esp
	pushad
	mov ebp,[ebp+8]
	mov [ebp].opcode_text,0
;
	mov esi,OFFSET reg_cs
	test word ptr [ebp+esi].d_access,ACCESS_SIZE
	jz disass_byte16

disass_byte32:
	mov ebx,[ebp].reg_eip
	jmp disass_read

disass_byte16:
	movzx ebx,word ptr [ebp].reg_eip

disass_read:
	mov ecx,ebx
	sub ecx,[ebp+esi].d_limit
	ja disass_done
;
	neg ecx
	inc ecx
	cmp ecx,16
	jb disass_read_linear
	mov ecx,16

disass_read_linear:
	add ebx,[ebp+esi].d_base
	call CondReadLinear
	call dis_ass_one
disass_done:
	popad
	pop ebp
	ret 4
DisAssemble	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DIS_ASS_MORE
;
;		DESCRIPTION:	DISASSEMBLERA EN INSTRUCTION
;
;		CALL			DIS_ASS_MORE (TCpu *cpu,long instruction_nber);
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public Dis_ass_more
	
Dis_ass_more	proc near


	push 	ebp
	mov 	ebp,esp
	pushad
	mov	ecx,[ebp+0Ch]	;nombre d'instruction à decoder	
	mov 	ebp,[ebp+8]
	
;préparons nous
	
@@1:
	push	ebp
	call	DisAssemble
	push	ebp
	call	WriteRegs
	mov	eax,op_code_size
	add	eax,[ebp].reg_eip
	mov	[ebp].reg_eip,eax
	loop	@@1
	
;On remet tout en place
		
	popad
	pop	 ebp
	ret 8
			
Dis_ass_more	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadInstruction
;
;		DESCRIPTION:	Read next instruction
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadInstruction

ReadInstruction	Proc near
	push ebp
	mov ebp,esp
	pushad
	mov ebp,[ebp+8]
;
	mov esi,OFFSET reg_cs
	test word ptr [ebp+esi].d_access,ACCESS_SIZE
	jz read_instr_byte16

read_instr_byte32:
	mov ebx,[ebp].reg_eip
	jmp read_instr_read

read_instr_byte16:
	movzx ebx,word ptr [ebp].reg_eip

read_instr_read:
	mov ecx,ebx
	sub ecx,[ebp+esi].d_limit
	ja read_instr_done
;
	neg ecx
	inc ecx
	cmp ecx,16
	jb read_instr_linear
	mov ecx,16

read_instr_linear:	
	add ebx,[ebp+esi].d_base
	call CondReadLinear

read_instr_done:
	popad
	pop ebp
	ret 4
ReadInstruction	Endp

	END
