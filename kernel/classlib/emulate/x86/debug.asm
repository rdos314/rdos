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
; DEBUG.ASM
; Debugger support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat
						
		NAME  DEBUG_

INCLUDE ..\core\emulate.inc
INCLUDE ..\core\emcom.inc

	extrn ShowChar:near
	extrn ShowSizeString:near
	extrn ShowAsciiz:near

.code

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

Blank	Proc near
	push ax
	push ecx
	mov al,' '
blank_loop:
	call WriteChar
	loop blank_loop
	pop ecx
	pop ax
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteEflags
;
;		DESCRIPTION:	
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eflags_tab:
;
;		reset		set
et_cf	DB 'NC ',	'CY '
et_1	DB 0,0,0,	0,0,0
et_pf	DB 'PO ',	'PE '
et_3	DB 0,0,0,	0,0,0
et_af	DB 'NA ',	'AC '
et_5	DB 0,0,0,	0,0,0
et_zf	DB 'NZ ',	'ZR '
et_sf	DB 'PL ',	'NG '
et_tf	DB 0,0,0,	0,0,0
et_if	DB 'DI ',	'EI '
et_df	DB 'UP ',	'DN '
et_of	DB 'NV ',	'OV '
et_12	DB 0,0,0,	0,0,0
et_13	DB 0,0,0,	0,0,0
et_14	DB 'PR ' ,	'NT '
et_15	DB 0,0,0,	0,0,0
et_16	DB 0,0,0,	0,0,0
et_vm	DB 0,0,0,	0,0,0
et_vi	DB 0,0,0,	0,0,0

iopl_text	DB ' IOPL=',0

cpu_rm	DB 'RM '
cpu_pm	DB 'PM '
cpu_vm	DB 'VM '

WriteEflags	PROC near
	push edi
;
	test byte ptr [ebp].reg_cr0,CR0_PE
	jz eflags_rm
	test [ebp].reg_eflags,EFLAGS_VM
	jz eflags_pm

eflags_vm:
	mov edi,OFFSET cpu_vm
	jmp eflags_write_mode

eflags_pm:
	mov edi,OFFSET cpu_pm
	jmp eflags_write_mode

eflags_rm:
	mov edi,OFFSET cpu_rm

eflags_write_mode:
	mov ecx,3
	call WriteSizeString	
;
	mov ax,word ptr [ebp].reg_eflags
	shr ax,7
	or ax,word ptr [ebp].reg_eflags+2
	shl eax,16
	mov ax,word ptr [ebp].reg_eflags
	mov edi,OFFSET eflags_tab
	mov ecx,19
eflags_loop:
	mov dl,[edi]
	or dl,dl
	je eflags_skip
	push edi
	test ax,1
	jz eflags_pos_ok
	add edi,3
	jmp eflags_write_one
eflags_pos_ok:
eflags_write_one:
	push ecx
	mov ecx,3
	call WriteSizeString
	pop ecx
	pop edi
eflags_skip:
	shr eax,1
	add edi,6
	loop eflags_loop
	mov edi,OFFSET iopl_text
	call WriteAsciiz
	mov ax,word ptr [ebp].reg_eflags
	shr ax,12
	and ax,3
	add ax,'0'
	call WriteChar
	mov al,' '
	call WriteChar
	call WriteChar
	pop edi
	ret
WriteEflags	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteCr0
;
;		DESCRIPTION:	
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cr0_tab:
;
;		reset		set
cr0_pe	DB 0,0,0,	0,0,0
cr0_mp	DB 'FP ',	'MP '
cr0_em	DB 0,0,0,	'EM '
cr0_ts	DB 0,0,0,	'TS '
cr0_4	DB 0,0,0,	0,0,0
cr0_ne	DB 0,0,0,	'NE '
cr0_6	DB 0,0,0,	0,0,0
cr0_7	DB 0,0,0,	0,0,0
cr0_8	DB 0,0,0,	0,0,0
cr0_9	DB 0,0,0,	0,0,0
cr0_10	DB 0,0,0,	0,0,0
cr0_11	DB 0,0,0,	0,0,0
cr0_12	DB 0,0,0,	0,0,0
cr0_13	DB 0,0,0,	0,0,0
cr0_14	DB 0,0,0,	0,0,0
cr0_15	DB 0,0,0,	0,0,0
cr0_wp	DB 0,0,0,	'WP '
cr0_17	DB 0,0,0,	0,0,0
cr0_am	DB 0,0,0,	'AM '
cr0_19	DB 0,0,0,	0,0,0
cr0_20	DB 0,0,0,	0,0,0
cr0_21	DB 0,0,0,	0,0,0
cr0_22	DB 0,0,0,	0,0,0
cr0_23	DB 0,0,0,	0,0,0
cr0_24	DB 0,0,0,	0,0,0
cr0_25	DB 0,0,0,	0,0,0
cr0_26	DB 0,0,0,	0,0,0
cr0_27	DB 0,0,0,	0,0,0
cr0_28	DB 0,0,0,	0,0,0
cr0_nw	DB 'WT ',	'NW '
cr0_cd	DB 'CE ',	'CD '
cr0_pg	DB 'PD ',	'PE '

WriteCr0	PROC near
	push edi
	mov eax,[ebp].reg_cr0
	mov edi,OFFSET cr0_tab
	mov ecx,32
cr0_loop:
	push edi
	test ax,1
	jz cr0_pos_ok
	add edi,3

cr0_pos_ok:
	mov dl,[edi]
	or dl,dl
	je cr0_skip
	push ecx
	mov ecx,3
	call WriteSizeString
	pop ecx
cr0_skip:
	shr eax,1
	pop edi
	add edi,6
	loop cr0_loop
	call NewLine
	pop edi
	ret
WriteCr0	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteDescriptors
;
;		DESCRIPTION:	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

descr_tr:
	DB ' TR'
	DD OFFSET reg_tr

descr_ldt:
	DB 'LDT'
	DD OFFSET reg_ldt

descr_es:
	DB ' ES'
	DD OFFSET reg_es

descr_cs:
	DB ' CS'
	DD OFFSET reg_cs

descr_ss:
	DB ' SS'
	DD OFFSET reg_ss

descr_ds:
	DB ' DS'
	DD OFFSET reg_ds

descr_fs:
	DB ' FS'
	DD OFFSET reg_fs

descr_gs:
	DB ' GS'
	DD OFFSET reg_gs

	DB 0

selector_text:
	DB ' SELECTOR=',0

base_text:
	DB ' BASE=',0

limit_text:
	DB ' LIMIT=',0

rpl_text:
	DB ' RPL=',0

down_text:
	DB ' DN',0

read_text:
	DB ' RD',0

write_text:
	DB ' WR',0

d16_text:
	DB ' 16',0

d32_text:
	DB ' 32',0

WriteDescriptors	PROC near
	mov edi,OFFSET descr_tr
write_descr_loop:
	mov al,[edi]
	or al,al
	je write_descr_done
	mov ecx,3
	call WriteSizeString
	add edi,3
	mov esi,[edi]
	push edi
;
	mov edi,OFFSET selector_text
	call WriteAsciiz
;
	mov ax,[ebp+esi].d_selector
	call WriteHexWord
;
	mov edi,OFFSET base_text
	call WriteAsciiz
;
	mov eax,[ebp+esi].d_base
	call WriteHexDword
;
	mov edi,OFFSET limit_text
	call WriteAsciiz
;
	mov eax,[ebp+esi].d_limit
	call WriteHexDword
;
	mov edi,OFFSET rpl_text
	call WriteAsciiz
;
	mov al,[ebp+esi].d_access
	push ax
	and al,3
	call WriteHexByte
	pop ax
;
	test al,ACCESS_DIR
	jz write_descr_not_down
;
	push ax
	mov edi,OFFSET down_text
	call WriteAsciiz
	pop ax
	
write_descr_not_down:
	test al,ACCESS_READ
	jz write_descr_not_read
;
	push ax
	mov edi,OFFSET read_text
	call WriteAsciiz
	pop ax

write_descr_not_read:
	test al,ACCESS_WRITE
	jz write_descr_not_write
;
	push ax
	mov edi,OFFSET write_text
	call WriteAsciiz
	pop ax

write_descr_not_write:
	test al,ACCESS_SIZE
	jz write_descr16

write_descr32:
	mov edi,OFFSET d32_text
	call WriteAsciiz
	jmp write_descr_next

write_descr16:
	mov edi,oFFSET d16_text
	call WriteAsciiz

write_descr_next:
	pop edi
	add edi,4
	call NewLine
	jmp write_descr_loop

write_descr_done:
	ret
WriteDescriptors	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteTlb
;
;		DESCRIPTION:	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TlbUndef DB '[Unused  ]=xxxxxxxx ',0

WriteTlb	PROC near
	lea edi,[ebp].reg_tlb.tlb
	mov ecx,8
WriteTlbRow:
	push ecx
	mov ecx,4
WriteTlbLoop:
	test [ebp].reg_cr0,CR0_PG
	jz WriteTlbUndef
	mov eax,ss:[edi].t_tag
	cmp eax,-1
	jne WriteTlbEntry

WriteTlbUndef:
	push edi
	mov edi,OFFSET TlbUndef
	call WriteAsciiz
	pop edi
	jmp WriteTlbNext

WriteTlbEntry:
	push ax
	mov al,'['
	call WriteChar
	pop ax
	call WriteHexDword
	mov al,']'
	call WriteChar
	mov al,'='
	call WriteChar
	mov eax,[edi].t_address
	call WriteHexDword
	mov al,' '
	call WriteChar

WriteTlbNext:
	add edi,SIZE tlb_entry_struc
	loop WriteTlbLoop
	pop ecx
	loop WriteTlbRow
	ret
WriteTlb	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteSystemRegs
;
;		DESCRIPTION:	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sysreg_gdt:
	DB 'GDT'
	DD OFFSET reg_gdt

sysreg_idt:
	DB 'IDT'
	DD OFFSET reg_idt

	DB 0

WriteSystemRegs	PROC near
	mov edi,OFFSET sysreg_gdt
write_sysreg_loop:
	mov al,[edi]
	or al,al
	je write_sysreg_done
	mov ecx,3
	call WriteSizeString
	add edi,3
	mov esi,[edi]
	push edi
;
	mov edi,OFFSET base_text
	call WriteAsciiz
;
	mov eax,[ebp+esi].d_base
	call WriteHexDword
;
	mov edi,OFFSET limit_text
	call WriteAsciiz
;
	mov eax,[ebp+esi].d_limit
	call WriteHexWord
	pop edi
	add edi,4
	call NewLine
	jmp write_sysreg_loop

write_sysreg_done:
	ret
WriteSystemRegs	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteDwordRegs
;
;		DESCRIPTION:	
;
;		PARAMETERS:		EDI		OFFSET TO TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dword_reg_tab1:
	DB ' EAX='
	DD OFFSET reg_eax
	DB ' EBX='
	DD OFFSET reg_ebx
	DB ' ECX='
	DD OFFSET reg_ecx
	DB ' EDX='
	DD OFFSET reg_edx
	DB 0

dword_reg_tab2:
	DB ' ESI='
	DD OFFSET reg_esi
	DB ' EDI='
	DD OFFSET reg_edi
	DB ' ESP='
	DD OFFSET reg_esp
	DB ' EBP='
	DD OFFSET reg_ebp
	DB 0

dword_reg_tab3:
	DB ' EPC='
	DD OFFSET reg_eip
	DB ' CR2='
	DD OFFSET reg_cr2
	DB ' CR3='
	DD OFFSET reg_cr3
	DB ' CR4='
	DD OFFSET reg_cr4
	DB 0


WriteDwordRegs	PROC near
dword_write_loop:
	mov al,[edi]
	or al,al
	je dword_write_end
	mov ecx,5
	call WriteSizeString
	add edi,5
	mov esi,[edi]
	mov eax,[ebp+esi]
	call WriteHexDword
	add edi,4
	jmp dword_write_loop
dword_write_end:
	call NewLine
	ret
WriteDwordRegs	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteInstr
;
;		DESCRIPTION:	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInstr	Proc near
	lea edi,[ebp].opcode_text
	call WriteAsciiz
	call NewLine
	ret
WriteInstr	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteTime
;
;		DESCRIPTION:	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteTime	Proc near
	pushad
	lea edi,[ebp].opcode_text
	mov eax,[ebp].total_cycles
	xor edx,edx
	mov ecx,10
	div ecx
	push edx
	xor edx,edx
	push eax
	mov eax,edx
	xor edx,edx
	mov ecx,24
	div ecx
	mov ecx,3
	call IntToStr
	call RemoveLeading
	pushf
	call WriteAsciiz
	mov al,' '
	call WriteChar
	mov eax,edx
	mov ecx,2
	call IntToStr
	mov al,'.'
	popf
	jc SignHour
	call RemoveLeading
	jc SignHour
	mov al,' '
SignHour:
	pushf
	call WriteAsciiz
	call WriteChar
	popf
	pop eax
;
	pushf
	mov edx,60
	mul edx
	popf
	push eax
	pushf
	mov eax,edx
	mov ecx,2
	call IntToStr
	mov al,'.'
	popf
	jc MinSign
	call RemoveLeading
	jc MinSign
	mov al,' '
MinSign:
	pushf
	call WriteAsciiz
	call WriteChar
	popf
	pop eax
;
	pushf
	mov edx,60
	mul edx
	popf
	push eax
	pushf
	mov eax,edx
	mov ecx,2
	call IntToStr
	mov al,','
	popf
	jc SecSign
	call RemoveLeading
	jc SecSign
	mov al,' '
SecSign:
	pushf
	call WriteAsciiz
	call WriteChar
	popf
	pop eax
;
	pushf
	mov edx,1000
	mul edx
	popf
	push eax
	pushf
	mov eax,edx
	mov ecx,3
	call IntToStr
	mov al,' '
	popf
	jc MilliSign
	call RemoveLeading
MilliSign:
	pushf
	call WriteAsciiz
	call WriteChar
	popf
	pop eax
;
	pushf
	mov edx,1000
	mul edx
	mov eax,edx
	mov ecx,3
	call IntToStr
	popf
	jc MikroSign
	call RemoveLeading
MikroSign:
	call WriteAsciiz
	mov al,' '
	call WriteChar
	pop eax
	mov edx,100
	mul edx	
	mov ecx,3
	call IntToStr
	call WriteAsciiz
	call NewLine
	popad
	ret
WriteTime	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteCpuReg
;
;		DESCRIPTION:	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg	Proc near
	call WriteTlb
	call WriteSystemRegs
	call WriteDescriptors
;
	mov edi,OFFSET dword_reg_tab1
	call WriteDwordRegs
;
	mov edi,OFFSET dword_reg_tab2
	call WriteDwordRegs
;
	mov edi,OFFSET dword_reg_tab3
	call WriteDwordRegs
;
	call WriteEflags
	call WriteCr0
	call WriteInstr
	call WriteTime
	ret
WriteCpuReg	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteRegs
;
;		DESCRIPTION:	Write CPU registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteRegs

WriteRegs	Proc near
	push ebp
	mov ebp,esp
	pushad
	mov ebp,[ebp+8]
;
	call WriteCpuReg
;
	popad
	pop ebp
	ret 4
WriteRegs	Endp

	END
