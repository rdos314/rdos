;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; REMDEBUG.ASM
; Remote debugger interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME remdebug

GateSize = 16

INCLUDE ..\os\os.def
INCLUDE ..\os\user.def
INCLUDE ..\os\user.inc
INCLUDE ..\os\ipcdebug.inc
INCLUDE ..\os\system.def
INCLUDE remdebug.inc

.model small

gate_entry	STRUC
gate_name_sel		DW ?
gate_name_offset	DD ?
virt_gate_nr		DW ?
gate_entry	ENDS

virt_gate_entry	STRUC
vg_sel			DW ?
vg_offset		DW ?
vg_name_offset	DW ?
vg_seg_transfer	DW ?
virt_gate_entry	ENDS

.stack
.data

MailslotHandle		DW ?
SendBuf				debug_req_struc <>
CurrentTssSel		DW ?
CurrentThreadSel	DW ?
Info				debug_req_info_struc <>
Mne					debug_req_instr_struc <>
DataHeader			debug_req_data_struc <>
DataArr				DB 2 * 16 DUP(?)
ReplyBuf			DB 1024 DUP(?)

code	SEGMENT byte public 'CODE'

	assume cs:code

	extrn dis_ass_one:near

.386p

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
	push cx
	mov cx,60
	mov al,'-'
write_delim_loop:
	WriteChar
	loop write_delim_loop
	pop cx
	call NewLine
	pop ax
	ret
Delimiter	Endp

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
	WriteChar
	mov al,10
	WriteChar
	pop ax
	ret
NewLine	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Blank
;
;		DESCRIPTION:	
;
;		PARAMETERS:		CX		Number of blanks to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Blank	Proc near
	push ax
	push cx
	mov al,' '
blank_loop:
	WriteChar
	loop blank_loop
	pop cx
	pop ax
	ret
Blank	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			single_hex
;
;		DESCRIPTION:	Convert to hex
;
;		PARAMETERS:		AL		Value
;
;		RETURNS:		AX		Hex value
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
;		DESCRIPTION:	Write hex byte
;
;		PARAMETERS:		AL		Value
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
	WriteChar
	mov al,ah
	and al,0Fh
	cmp al,0Ah
	jb write_byte_high1
	add al,7
write_byte_high1:
	add al,'0'
	WriteChar
	pop ax
	ret
WriteHexByte	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexWord
;
;		DESCRIPTION:	Write hex word
;
;		PARAMETERS:		AX		Value
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
;		DESCRIPTION:	Write hex dword
;
;		PARAMETERS:		EAX		Value
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
;		DESCRIPTION:	Write hex 16:16 pointer
;
;		PARAMETERS:		DX		Selector
;						BX		Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr16	PROC near
	push ax
	mov ax,dx
	call WriteHexWord
	mov al,':'
	WriteChar
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
;		DESCRIPTION:	Write hex 16:32 pointer
;
;		PARAMETERS:		DX		Selector
;						EBX		Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr32	PROC near
	push eax
	mov ax,dx
	call WriteHexWord
	mov al,':'
	WriteChar
	mov eax,ebx
	call WriteHexDword
	pop eax
	ret
WriteHexPtr32	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteFault
;
;		DESCRIPTION:	Write fault
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ft_intr	DB 'Interrupt fault   ',0
ft_inst	DB 'Instruction fault ',0

ft_idt	DB 'idt ',0
ft_ldt	DB 'ldt ',0
ft_gdt	DB 'gdt ',0

WriteFault	PROC near
	test gs:tss_eflags+2,2
	jnz write_fault_end
	mov ax,fs:p_error_code
	cmp ax,3
	je write_fault_end
	mov ax,cs
	mov es,ax
	mov di,OFFSET ft_inst
	mov ax,gs:tss_error_code
	or ax,ax
	jz write_fault_end
	test ax,1
	jz fault_not_int
	mov di,OFFSET ft_intr
fault_not_int:
	WriteAsciiz
;
	mov ax,gs:tss_error_code
	test ax,2
	jz fault_not_idt
	mov di,OFFSET ft_idt
	jmp write_fault_reason
fault_not_idt:
	mov di,OFFSET ft_gdt
	test ax,4
	jz write_fault_reason
	mov di,OFFSET ft_ldt
write_fault_reason:
	WriteAsciiz
	mov ax,gs:tss_error_code
	and ax,0FFF8h
	call WriteHexWord
	ret
write_fault_end:
	mov cx,30
	call Blank
	ret
WriteFault	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteDataRow
;
;		DESCRIPTION:	Write a data row
;
;		PARAMETERS:		AX		Selector
;						EBX		Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDataRow	PROC near
	mov DataHeader.dd_op,DEBUG_REQ_DATA
	test gs:tss_eflags+2,2
	jz write_mode_prot
write_mode_virt:
	mov DataHeader.dd_vm,1
	jmp write_mode_ok
write_mode_prot:
	mov DataHeader.dd_vm,0

write_mode_ok:
	push ax
	mov DataHeader.dd_offset,ebx
	mov DataHeader.dd_sel,ax
	mov ax,gs:tss_thread
	mov DataHeader.dd_thread,ax
	mov DataHeader.dd_count,16
;
	mov ax,SEG _data
	mov es,ax
	pusha
	mov bx,MailslotHandle
	mov si,OFFSET DataHeader
	mov cx,SIZE debug_req_data_struc
	mov di,OFFSET DataHeader
	mov ax,32 + SIZE debug_req_data_struc
	SendMailslot
	cmp cx,32 + SIZE debug_req_data_struc
	popa
	pop dx
	jne write_data_end
;	
	call WriteHexPtr32
	mov cx,16
	mov di,OFFSET DataArr
	push ebx
write_data_loop:
	mov al,' '
	WriteChar
	mov ax,es:[di]
	add di,2
	or ah,ah
	jz write_data_inv
	call WriteHexByte
	jmp write_data_next
write_data_inv:
	WriteChar
	WriteChar
write_data_next:
	inc ebx
	loop write_data_loop
	pop ebx
	mov al,' '
	WriteChar
	mov cx,16
	mov di,OFFSET DataArr
write_ascii_loop:
	mov al,es:[di]
	add di,2
	cmp al,20h
	jnc write_ascii_do
	mov al,' '
write_ascii_do:
	WriteChar
	inc ebx
	loop write_ascii_loop
write_data_end:
	ret
WriteDataRow	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteData
;
;		DESCRIPTION:	Write data rows
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteData	PROC near
	mov al,Mne.ddi_data_good
	or al,al
	jz data_no_good
;
	mov ax,Mne.ddi_data_sel
	mov ebx,Mne.ddi_data_offset
	call WriteDataRow
	jmp data_next

data_no_good:
	mov cx,79
	call Blank
data_next:
	call NewLine
;
	mov ax,gs:tss_cs
	mov bx,gs:tss_eip+2
	shl ebx,16
	mov bx,gs:tss_eip
	call WriteDataRow
	call NewLine
;
	mov ax,gs:tss_ss
	mov bx,gs:tss_esp+2
	shl ebx,16
	mov bx,gs:tss_esp
	call WriteDataRow
	call NewLine
;
	mov ax,gs:tss_es
	xor ebx,ebx
	call WriteDataRow
	call NewLine
;
	push gs:tss_eflags+2
	mov gs:tss_eflags+2,0
	mov ax,fs:p_pm_deb_sel
	mov ebx,fs:p_pm_deb_offs
	call WriteDataRow
	call NewLine
;
	mov gs:tss_eflags+2,2
	mov ax,fs:p_vm_deb_sel
	mov ebx,fs:p_vm_deb_offs
	call WriteDataRow
	pop gs:tss_eflags+2
	ret
WriteData	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteIntCode
;
;		DESCRIPTION:	Write interrupt code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_code_tab:
ke00	DB 'Divide error            '
ke01	DB 'Single step             '
ke02	DB 'NMI                     '
ke03	DB 'Breakpoint              '
ke04	DB 'Overflow                '
ke05	DB 'Array bounds error      '
ke06	DB 'Invalid OP-code         '
ke07	DB '80387 not present       '
ke08	DB 'Double fault            '
ke09	DB '80387 overrun           '
ke0A	DB 'Invalid TSS             '
ke0B	DB 'Segment not present     '
ke0C	DB 'Stack fault             '
ke0D	DB 'Protection fault        '
ke0E	DB 'Page fault              '
ke0F	DB '                        '
ke10	DB '80387 error             '
ke11	DB 'Cannot emulate          '
ke12	DB 'Cannot emulate 80387    '
ke13	DB 'Now in real mode        '
ke14	DB '----------------------- '
ke15	DB 'Illegal int request     '
ke16	DB 'Undefined method        '
ke17	DB 'Invalid handle          '
ke18	DB 'Invalid selector        '

WriteIntCode	Proc near
	mov dx,fs:p_error_code
	mov bx,dx
	add bx,bx
	add bx,bx
	add bx,bx
	mov cx,bx
	add cx,cx
	add bx,cx
	mov ax,cs
	mov es,ax
	mov di,OFFSET error_code_tab
	add di,bx
	mov cx,24
	WriteSizeString
	ret
WriteIntCode	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteThread
;
;		DESCRIPTION:	Write thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteThread	Proc near
	mov ax,fs:p_id
	call WriteHexWord
	mov al,' '
	WriteChar
	WriteChar
	mov ax,fs
	mov es,ax
	mov di,OFFSET thread_name
	mov cx,30
	WriteSizeString
	call NewLine
	ret
WriteThread	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteFreeMem
;
;		DESCRIPTION:	Write free memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

phys_mem_comment	DB 'Physical ',0
global_mem_comment	DB '   Global ',0
local_mem_comment	DB '   Local ',0

WriteFreeMem	PROC near
	mov ax,cs
	mov es,ax
;
	mov di,OFFSET phys_mem_comment
	WriteAsciiz
	mov eax,Info.di_free_physical
	call WriteHexDword
;
	mov di,OFFSET global_mem_comment
	WriteAsciiz
	mov eax,Info.di_used_small
	add eax,Info.di_used_big
	call WriteHexDword
;
	mov di,OFFSET local_mem_comment
	WriteAsciiz
	mov eax,Info.di_used_local
	call WriteHexDword
	call NewLine
	ret
WriteFreeMem	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteEflags
;
;		DESCRIPTION:	Write EFLAGS
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
et_vm	DB 'PM ',	'VM '
et_vi	DB 'PDI',	'PEI'

iopl_text	DB ' IOPL=',0

WriteEflags	PROC near
	push es
	push di
	mov ax,cs
	mov es,ax
	mov ax,gs:tss_eflags
	and ax,200h
	shr ax,7
	or ax,gs:tss_eflags+2
	shl eax,16
	mov ax,gs:tss_eflags
;
	mov di,OFFSET eflags_tab
	mov cx,19
eflags_loop:
	mov dl,es:[di]
	or dl,dl
	je eflags_skip
	push di
	test ax,1
	jz eflags_pos_ok
	add di,3
	jmp eflags_write_one
eflags_pos_ok:
eflags_write_one:
	push cx
	mov cx,3
	WriteSizeString
	pop cx
	pop di
eflags_skip:
	shr eax,1
	add di,6
	loop eflags_loop
	mov di,OFFSET iopl_text
	WriteAsciiz
	mov ax,gs:tss_eflags
	shr ax,12
	and ax,3
	add ax,'0'
	WriteChar
	pop di
	pop es
	ret
WriteEflags	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteWordRegs
;
;		DESCRIPTION:	Write word registers
;
;		PARAMETERS:		ES:DI		Offset to table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

word_reg_tab1:
	DB ' TR=',0
	DB ' DT=',OFFSET tss_ldt,0
word_reg_tab2:
	DB ' CS=',OFFSET tss_cs,' DS=',OFFSET tss_ds
	DB ' ES=',OFFSET tss_es,' FS=',OFFSET tss_fs
	DB ' GS=',OFFSET tss_gs,' SS=',OFFSET tss_ss,0

WriteWordRegs	PROC near
word_write_loop:
	mov al,es:[di]
	or al,al
	je word_write_end
	mov cx,4
	WriteSizeString
	add di,4
	mov bl,es:[di]
	or bl,bl
	jnz word_write_norm
	mov ax,fs:p_tss_sel
	call WriteHexWord
	jmp word_write_cont
word_write_norm:
	xor bh,bh
	mov ax,gs:[bx]
	call WriteHexWord	
word_write_cont:
	inc di
	jmp word_write_loop
word_write_end:
	ret
WriteWordRegs	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteDwordRegs
;
;		DESCRIPTION:	Write dword registers
;
;		PARAMETERS:		ES:DI		Offset to table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dword_reg_tab1:
	DB ' EAX=',OFFSET tss_eax,' EBX=',OFFSET tss_ebx
	DB ' ECX=',OFFSET tss_ecx,' EDX=',OFFSET tss_edx,0
dword_reg_tab2:
	DB ' ESI=',OFFSET tss_esi,' EDI=',OFFSET tss_edi
	DB ' ESP=',OFFSET tss_esp,' EBP=',OFFSET tss_ebp,0
dword_reg_tab3:
	DB ' EPC=',OFFSET tss_eip,0

WriteDwordRegs	PROC near
dword_write_loop:
	mov al,es:[di]
	or al,al
	je dword_write_end
	mov cx,5
	WriteSizeString
	add di,5
	mov bl,es:[di]
	xor bh,bh
	mov eax,gs:[bx]
	call WriteHexDword
	inc di
	jmp dword_write_loop
dword_write_end:
	ret
WriteDwordRegs	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteInstr
;
;		DESCRIPTION:	Write instruction
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInstr	Proc near
	mov ax,SEG _data
	mov es,ax
	mov bx,MailslotHandle
	mov Mne.ddi_op,DEBUG_REQ_INSTR
	mov si,OFFSET Mne
	mov cx,1
	mov di,OFFSET Mne
	mov ax,SIZE debug_req_instr_struc
	SendMailslot
;
	cmp cx,SIZE debug_req_instr_struc
	jne write_instr_done
;
	mov di,OFFSET Mne.ddi_mne
	mov cx,40
	WriteSizeString

write_instr_done:
	ret
WriteInstr	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteCoproc
;
;		DESCRIPTION:	Write coprocessor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

math0	DB 'ST(0)=  ',0
math1	DB 'ST(1)=  ',0
math2	DB 'ST(2)=  ',0
math3	DB 'ST(3)=  ',0
math4	DB 'ST(4)=  ',0
math5	DB 'ST(5)=  ',0
math6	DB 'ST(6)=  ',0
math7	DB 'ST(7)=  ',0

write_math	PROC near	
	WriteAsciiz
	jmp write_math_end		; fix this !!!
	finit
	fld tbyte ptr gs:[si]
	push ax
	mov ax,SEG _data
	mov es,ax
	mov di,OFFSET ReplyBuf
	mov al,' '
	mov cx,35
	rep stosb
	mov di,OFFSET ReplyBuf	
	mov dl,18
;	call float_to_string
	WriteSizeString
	pop ax
write_math_end:
	call NewLine
	ret
write_math	ENDP

WriteCoproc	Proc near
	mov ax,cs
	mov es,ax
	mov dx,gs:math_tag
	mov ax,gs:math_status
	shr ax,3
	mov cl,ah
	and cl,7
	add cl,cl
	ror dx,cl
	mov ax,dx
	mov si,OFFSET math_st0
	mov di,OFFSET math0
	call write_math
	ror ax,2
	mov si,OFFSET math_st1
	mov di,OFFSET math1
	call write_math
	ror ax,2
	mov si,OFFSET math_st2
	mov di,OFFSET math2
	call write_math
	ror ax,2
	mov si,OFFSET math_st3
	mov di,OFFSET math3
	call write_math
	ror ax,2
	mov si,OFFSET math_st4
	mov di,OFFSET math4
	call write_math
	ror ax,2
	mov si,OFFSET math_st5
	mov di,OFFSET math5
	call write_math
	ror ax,2
	mov si,OFFSET math_st6
	mov di,OFFSET math6
	call write_math
	ror ax,2
	mov si,OFFSET math_st7
	mov di,OFFSET math7
	call write_math
	ret
WriteCoproc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteCpuReg
;
;		DESCRIPTION:	Write CPU registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg	Proc near
	push es
	mov ax,cs
	mov es,ax
;
	mov di,OFFSET dword_reg_tab1
	call WriteDwordRegs
	call NewLine
;
	mov di,OFFSET dword_reg_tab2
	call WriteDwordRegs
	call NewLine
;
	mov di,OFFSET dword_reg_tab3
	call WriteDwordRegs
;
	mov di,OFFSET word_reg_tab1
	call WriteWordRegs
	call NewLine
;
	mov di,OFFSET word_reg_tab2
	call WriteWordRegs
	call NewLine
;
	call WriteEflags
	call NewLine
	pop es
	ret
WriteCpuReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteStatus
;
;		DESCRIPTION:	Write status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteStatus	Proc near
	call WriteIntCode
	mov al,' '
	WriteChar
	call WriteFault
	call NewLine
	ret
WriteStatus	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteCpu
;
;		DESCRIPTION:	Write CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpu	PROC near
	xor dx,dx
	xor cx,cx
	SetCursorPosition
	call WriteCoproc
	call Delimiter
	call WriteCpuReg
	call Delimiter
	call WriteFreeMem
	call WriteStatus
	call WriteInstr
	call WriteThread
	call Delimiter
	call WriteData
	xor dx,dx
	xor cx,cx
	SetCursorPosition
	ret
WriteCpu	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_tss
;
;		DESCRIPTION:	Get current TSS
;
;		RETURNS:		NC		ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_tss	Proc near
	push es
	mov bx,MailslotHandle
	mov SendBuf.db_op,DEBUG_REQ_TSS
	mov si,OFFSET SendBuf
	mov cx,1
	mov es,CurrentTssSel
	xor di,di
	mov ax,SIZE tss_seg
	SendMailslot
	cmp cx,SIZE tss_seg
	clc
	je get_tss_done
;
	stc

get_tss_done:
	pop es
	ret
get_tss	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_thread
;
;		DESCRIPTION:	Get current thread block
;
;		RETURNS:		NC		ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread	Proc near
	push es
	mov bx,MailslotHandle
	mov SendBuf.db_op,DEBUG_REQ_THREAD
	mov si,OFFSET SendBuf
	mov cx,1
	mov es,CurrentThreadSel
	xor di,di
	mov ax,SIZE thread_seg
	SendMailslot
	cmp cx,SIZE thread_seg
	clc
	je get_thread_done
;
	stc

get_thread_done:
	pop es
	ret
get_thread	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_info
;
;		DESCRIPTION:	Get info block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_info	Proc near
	mov bx,MailslotHandle
	mov Info.di_op,DEBUG_REQ_INFO
	mov ax,gs:tss_thread
	mov Info.di_thread,ax
	mov si,OFFSET Info
	mov cx,3
	mov di,OFFSET Info
	mov ax,SIZE debug_req_info_struc
	SendMailslot
	cmp cx,SIZE debug_req_info_struc
	clc
	je get_info_done
;
	stc

get_info_done:
	ret
get_info	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteAll
;
;		DESCRIPTION:	Write state
;
;		PARAMETERS:	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteAll	Proc near
	pusha
	call get_tss
	jc write_all_done
;
	call get_thread
	jc write_all_done
;
	call get_info
	call WriteCpu

write_all_done:
	popa
	ret
WriteAll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DoFunc
;
;		DESCRIPTION:	Do a function
;
;		PARAMETERS:		AL		Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoFunc	Proc near
	pusha
	mov SendBuf.db_op,al
	GetMousePosition
	shr cx,3
	shr dx,3
	mov SendBuf.db_x,cl
	mov SendBuf.db_y,dl
	mov bx,MailslotHandle
	mov si,OFFSET SendBuf
	mov cx,SIZE debug_req_struc
	mov di,OFFSET ReplyBuf
	mov ax,1024
	SendMailslot
	movzx cx,ReplyBuf.db_x
	movzx dx,ReplyBuf.db_y
	shl cx,3
	shl dx,3
	SetMousePosition
	mov ax,10
	WaitMilliSec
	call WriteAll
	popa
	ret
DoFunc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HandleKeyboard
;
;		DESCRIPTION:	Keyboard
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleKeyboard	Proc near
	mov ax,25
	WaitMilliSec
;
	PollKeyboard
	jc handle_key_end
;
	ReadKeyboard
	or al,al
	jz handle_key_special
	call DoFunc
	jmp handle_key_end

handle_key_special:  
	cmp ah,72
	jnz no_up_arrow

up_arrow:
	GetMousePosition
	sub dx,8
	SetMousePosition
	jmp handle_key_end

no_up_arrow:
	cmp ah,80
	jnz no_down_arrow

down_arrow:
	GetMousePosition
	add dx,8
	SetMousePosition
	jmp handle_key_end

no_down_arrow:
	cmp ah,75
	jnz no_left_arrow

left_arrow:
	GetMousePosition
	sub cx,8
	SetMousePosition
	jmp handle_key_end

no_left_arrow:
	cmp ah,77
	jnz handle_key_end

right_arrow:
	GetMousePosition
	add cx,8
	SetMousePosition

handle_key_end:
	GetMousePosition
	shr cx,3
	shr dx,3
	SetCursorPosition
	ret
HandleKeyboard	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HandleMouse
;
;		DESCRIPTION:	Mouse handler
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleMouse	Proc near
	GetLeftButton
	jc handle_not_left

left_button:
	GetLeftButtonPressPosition
	mov al,'+'
	call DoFunc
left_rel_loop:
	call HandleKeyboard
	GetLeftButton
	jnc left_rel_loop

handle_not_left:
	GetRightButton
	jc handle_mouse_done

right_button:
	GetRightButtonPressPosition
	mov al,'-'
	call DoFunc
right_rel_loop:
	call HandleKeyboard
	GetRightButton
	jnc right_rel_loop
handle_mouse_done:
	ret
HandleMouse	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadNode
;
;		DESCRIPTION:	Read node to debug
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

node_string		DB 'Input IP address to debug> ',0
mailslot_name	DB 'Debug',0

ReadNode	Proc near
	xor cx,cx
	xor dx,dx
	SetCursorPosition
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET node_string
	WriteAsciiz
;
	mov ax,SEG _data
	mov ds,ax
	mov es,ax
	mov cx,1024
	mov di,OFFSET ReplyBuf
	ReadConsole
;
	or ax,ax
	jz read_node_local
;
	add di,ax
	mov byte ptr [di],0
;
	mov si,OFFSET ReplyBuf
	xor ebx,ebx
	mov cx,4
read_ip_decode:
	xor al,al
read_ip_digit:
	mov dl,[si]
	inc si
	sub dl,'0'
	jc read_ip_save
	cmp dl,10
	jnc read_ip_save
	mov ah,10
	mul ah
	add al,dl
	jmp read_ip_digit

read_ip_save:
	mov bl,al
	ror ebx,8
	loop read_ip_decode		
;
	mov edx,ebx
	mov ax,cs
	mov es,ax
	mov di,OFFSET mailslot_name
	GetRemoteMailslot
	mov ds:MailslotHandle,bx
	jmp read_node_init

read_node_local:
	mov ax,cs
	mov es,ax
	mov di,OFFSET mailslot_name
	GetLocalMailslot
	mov ds:MailslotHandle,bx

read_node_init:	
	mov eax,SIZE tss_seg
	AllocateLocalMem
	mov ds:CurrentTssSel,es
	mov gs,ds:CurrentTssSel
	mov eax,SIZE thread_seg
	AllocateLocalMem
	mov ds:CurrentThreadSel,es
	mov fs,ds:CurrentThreadSel
;
	mov ax,SEG _data
	mov ds,ax
	mov es,ax
	ret
ReadNode	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:	Main program
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init:
	xor ax,ax
	xor bx,bx
	mov cx,639
	mov dx,199
	SetMouseWindow
	mov cx,8
	mov dx,8
	SetMouseMickey
;	
;	ShowMouse
state_start:
	mov ax,100
	WaitMilliSec
	mov ax,_data
	mov ds,ax
	mov es,ax
	call ReadNode
	call WriteAll

state_loop:
	call HandleKeyboard
	call HandleMouse
	jmp state_loop

code	ENDS

	END init
