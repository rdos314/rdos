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
; DISMAIN.ASM
; Main disassembler module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat
						
		NAME dismain

INCLUDE ..\core\emulate.inc

blank_sep			EQU 0
komma_sep			EQU 1000h
kolon_sep			EQU 2000h
lpar_sep			EQU 3000h
rpar_sep			EQU 4000h
lhak_sep			EQU 5000h
rhak_sep			EQU 6000h
plus_sep			EQU 7000h
minus_sep			EQU 8000h
kolon_par_sep		EQU 9000h
par_komma_sep		EQU 0A000h
no_sep				EQU 0B000h

data_8		EQU 0
data_16		EQU 1
data_32		EQU 2
data_48		EQU 3

addr_16		EQU 0
addr_32		EQU 1


.data

op_syntax		DD ?
op_codes		DD 100 DUP(?)
data_mode		DB ?
edata_mode		DB ?
override		DD ?
ignore_ptr		DB ?
op_in_code		DB 50 DUP(?)

.code

	extrn main_tab:near
	extrn mne_tab:near
	extrn sep_tab:near
	extrn txt_noth:near

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			no_adr
;
;		DESCRIPTION:	no address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public no_adr

no_adr	PROC near
	xor eax,eax
	ret
no_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			bx_adr
;
;		DESCRIPTION:	BX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public bx_adr

bx_adr	PROC near
	movzx eax,word ptr [ebp].reg_ebx
	ret
bx_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			bp_adr
;
;		DESCRIPTION:	BP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public bp_adr

bp_adr	PROC near
	movzx eax,word ptr [ebp].reg_ebp
	ret
bp_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			si_adr
;
;		DESCRIPTION:	SI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public si_adr

si_adr	PROC near
	movzx eax,word ptr [ebp].reg_esi
	ret
si_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			di_adr
;
;		DESCRIPTION:	DI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public di_adr

di_adr	PROC near
	movzx eax,word ptr [ebp].reg_edi
	ret
di_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			eax_adr
;
;		DESCRIPTION:	EAX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public eax_adr

eax_adr	PROC near
	mov eax,[ebp].reg_eax
	ret
eax_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ebx_adr
;
;		DESCRIPTION:	EBX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ebx_adr

ebx_adr	PROC near
	mov eax,[ebp].reg_ebx
	ret
ebx_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ecx_adr
;
;		DESCRIPTION:	ECX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ecx_adr

ecx_adr	PROC near
	mov eax,[ebp].reg_ecx
	ret
ecx_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			edx_adr
;
;		DESCRIPTION:	EDX address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public edx_adr

edx_adr	PROC near
	mov eax,[ebp].reg_edx
	ret
edx_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			esi_adr
;
;		DESCRIPTION:	ESI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public esi_adr

esi_adr	PROC near
	mov eax,[ebp].reg_esi
	ret
esi_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			edi_adr
;
;		DESCRIPTION:	EDI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public edi_adr

edi_adr	PROC near
	mov eax,[ebp].reg_edi
	ret
edi_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ebp_adr
;
;		DESCRIPTION:	EBP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ebp_adr

ebp_adr	PROC near
	mov eax,[ebp].reg_ebp
	ret
ebp_adr	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			esp_adr
;
;		DESCRIPTION:	ESP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public esp_adr

esp_adr	PROC near
	mov eax,[ebp].reg_esp
	ret
esp_adr	ENDP
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PUT_HEX_CODE
;
;		DESCRIPTION:	Put hex code
;
;		PARAMETERS:		AL	Value
;						EDI	OP_CODES
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

put_hex_code	PROC near
	push ebx
	xor bh,bh
	mov bl,al
	and bl,0F0h
	shr bl,4
	add ebx,ebx	
	add ebx,no_sep
	movzx ebx,bx
	mov [edi],ebx
	movzx ebx,al
	and bl,0Fh
	add ebx,ebx
	add ebx,no_sep
	mov [edi+4],ebx
	add edi,8
	pop ebx
	ret
put_hex_code	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ADD_HEX_BYTE
;
;		DESCRIPTION:	Add hex byte
;
;		PARAMETERS:		AL	 Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_hex_byte	PROC near
	call put_hex_code
	ret
add_hex_byte	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ADD_HEX_WORD
;
;		DESCRIPTION:	Add hex word
;
;		PARAMETERS:		AX	Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_hex_word	PROC near
	push ax
	mov al,ah
	call put_hex_code
	pop ax
	call put_hex_code
	ret
add_hex_word	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ADD_HEX_DWORD
;
;		DESCRIPTION:	Add hex dword
;
;		PARAMETERS:		EAX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_hex_dword	PROC near
	push eax
	push dx
;
	push eax
	pop dx
	pop ax
	xchg al,ah
	call put_hex_code
	xchg al,ah
	call put_hex_code
	mov al,dh
	call put_hex_code
	mov al,dl
	call put_hex_code
;
	pop dx
	pop eax
	ret
add_hex_dword	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CALC_ADS_OFFSET
;
;		DESCRIPTION:	Calculate adress offset
;
;		PARAMETERS:		EAX		Table index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn adr_16a_tab:near
	extrn adr_32a_tab:near

calc_ads_offset	PROC near
	push eax
	test [ebp].em_flags,a32
	jnz c_a_ad32

c_a_ad16:
	mov ebx,OFFSET adr_16a_tab
	cmp eax,18h
	jae calc_out_o_r
	mov [ebp].data_valid,1
	shl eax,3
	add ebx,eax
	call dword ptr [ebx]
	add [ebp].data_offset,eax
	call dword ptr [ebx+4]
	add [ebp].data_offset,eax
	mov word ptr [ebp].data_offset+2,0
	jmp calc_out_o_r
c_a_ad32:
	mov ebx,OFFSET adr_32a_tab
	cmp eax,18h
	jae calc_out_o_r
	mov [ebp].data_valid,1
	shl eax,3
	add ebx,eax
	call dword ptr [ebx]
	add [ebp].data_offset,eax
	call dword ptr [ebx+4]
	add [ebp].data_offset,eax
calc_out_o_r:
	pop eax
	ret
calc_ads_offset	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DECODE_MEM_MODE
;
;		DESCRIPTION:	Decode memory mode
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn mod_rm_tab:near

decode_mem_mode	PROC near
	mov bl,[ebp].em_flags
	and bl,a32
	mov bh,bl
	add bl,bl
	add bl,bh
	mov al,data_mode
	or al,al
	je data_8_sel
	test [ebp].em_flags,d32
	jz data_8_sel
	inc al
data_8_sel:
	mov edata_mode,al
	add bl,al
	movzx ebx,bl
	mov eax,dword ptr [4*ebx].mod_rm_tab
	mov op_syntax,eax
	mov al,[esi+1]
	mov ah,al
	and al,7
	and ah,0C0h
	cmp ah,0C0h
	jne dec_mem_no_ignore
	mov ignore_ptr,1
dec_mem_no_ignore:
	shr ah,3
	or al,ah
	movzx eax,al
	call calc_ads_offset
	inc esi
	call decode_opcode
	ret
decode_mem_mode	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DECODE_MATH_MEM
;
;		DESCRIPTION:	Decode FPU memory
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn st_txt:near

decode_math_mem	PROC near
	mov bl,[ebp].em_flags
	and bl,a32
	mov bh,bl
	add bl,bl
	add bl,bh
	mov al,data_mode
	or al,al
	je mdata_8_sel
	test [ebp].em_flags,d32
	jz mdata_8_sel
	inc al
mdata_8_sel:
	mov edata_mode,al
	add bl,al
	movzx ebx,bl
	mov eax,dword ptr [4*ebx].mod_rm_tab
	mov op_syntax,eax
	mov al,[esi+1]
	mov ah,al
	and al,7
	and ah,0C0h
	cmp ah,0C0h
	jne no_math_reg
	mov ebx,OFFSET st_txt
	sub ebx,OFFSET mne_tab
	or bx,lpar_sep
	mov [edi],ebx
	add edi,4
	mov bl,al
	xor bh,bh
	add ebx,ebx
	or bx,rpar_sep
	mov [edi],ebx	
	add edi,4
	ret
no_math_reg:
	shr ah,3
	or al,ah
	movzx eax,al
	call calc_ads_offset
	inc esi
	call decode_opcode
	ret
decode_math_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DECODE_REG
;
;		DESCRIPTION:	Decode register field
;
;		PARAMETERS:		AL		Register code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn reg_tab:near

decode_reg	PROC near
	mov bl,data_mode
	or bl,bl
	je rdata_8_sel
	test [ebp].em_flags,d32
	jz rdata_8_sel
	inc bl
rdata_8_sel:
	movzx ebx,bl
	mov ecx,dword ptr [4*ebx].reg_tab
	mov op_syntax,ecx
	and eax,38h
	shr eax,3
	mov ignore_ptr,1
	call decode_opcode
	ret
decode_reg	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ADD_KOMMA_TO_MEM
;
;		DESCRIPTION:	Add dot to memory operand
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_komma_to_mem	PROC near
	mov eax,OFFSET txt_noth
	sub eax,OFFSET mne_tab
	or eax,komma_sep
	mov [edi],eax
	add edi,4
	ret
add_komma_to_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			
;
;		DESCRIPTION:	Syntax procedures
;
;		PARAMETERS:		SI	OP_CODE IN
;						DI	OP_CODES out in code form
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	public override_cs
	extrn cs_txt:near

override_cs	PROC near
	mov eax,OFFSET cs_txt
	mov override,eax
	mov ebx,OFFSET main_tab
	mov op_syntax,ebx
	inc esi
	mov al,[esi]
	movzx eax,al
	call decode_opcode
	ret
override_cs	ENDP

	public override_ds
	extrn ds_txt:near

override_ds	PROC near
	mov eax,OFFSET ds_txt
	mov override,eax
	mov ebx,OFFSET main_tab
	mov op_syntax,ebx
	inc esi
	mov al,[esi]
	movzx eax,al
	call decode_opcode
	ret
override_ds	ENDP

	public override_ss
	extrn ss_txt:near

override_ss	PROC near
	mov eax,OFFSET ss_txt
	mov override,eax
	mov ebx,OFFSET main_tab
	mov op_syntax,ebx
	inc esi
	mov al,[esi]
	movzx eax,al
	call decode_opcode
	ret
override_ss	ENDP

	public override_es
	extrn es_txt:near

override_es	PROC near
	mov eax,OFFSET es_txt
	mov override,eax
	mov ebx,OFFSET main_tab
	mov op_syntax,ebx
	inc esi
	mov al,[esi]
	movzx eax,al
	call decode_opcode
	ret
override_es	ENDP

	public override_fs
	extrn fs_txt:near

override_fs	PROC near
	mov eax,OFFSET fs_txt
	mov override,eax
	mov ebx,OFFSET main_tab
	mov op_syntax,ebx
	inc esi
	mov al,[esi]
	movzx eax,al
	call decode_opcode
	ret
override_fs	ENDP

	public override_gs
	extrn gs_txt:near

override_gs	PROC near
	mov eax,OFFSET gs_txt
	mov override,eax
	mov ebx,OFFSET main_tab
	mov op_syntax,ebx
	inc esi
	mov al,[esi]
	movzx eax,al
	call decode_opcode
	ret
override_gs	ENDP

	public op_byte

op_byte	PROC near
	mov al,[esi+1]
	call add_hex_byte
	inc esi
	ret
op_byte	ENDP

	public op_word

op_word	PROC near
	test [ebp].em_flags,d32
	jz op_w16
op_w32:
	mov eax,[esi+1]
	call add_hex_dword
	add esi,4
	ret
op_w16:	
	mov ax,[esi+1]
	call add_hex_word
	add esi,2
	ret
op_word	ENDP

	public op_word_mem

op_word_mem	PROC near
	test [ebp].em_flags,d32
	jz op_wm16
op_wm32:
	mov eax,[esi+1]
	mov [ebp].data_valid,1
	mov [ebp].data_offset,eax
	call add_hex_dword
	add esi,4
	ret
op_wm16:	
	movzx eax,word ptr [esi+1]
	mov [ebp].data_valid,1
	mov [ebp].data_offset,eax
	call add_hex_word
	add esi,2
	ret
op_word_mem	ENDP

	public op_short

op_short	PROC near
	xor ah,ah
	mov al,[esi+1]
	test al,80h
	jz not_op_back
	mov ah,0FFh
not_op_back:
	add ax,2
	add ax,word ptr [ebp].reg_eip
	call add_hex_word
	add esi,2
	ret
op_short	ENDP

	public op_near

op_near	PROC near
	test [ebp].em_flags,d32
	jz op_near16
op_near32:
	mov eax,[esi+1]
	add eax,3
	add eax,[ebp].reg_eip
	call add_hex_dword
	add esi,4
	ret
op_near16:	
	mov ax,[esi+1]
	add ax,3
	add ax,word ptr [ebp].reg_eip
	call add_hex_word
	add esi,2
	ret
op_near	ENDP

	public op_near2

op_near2	PROC near
	test [ebp].em_flags,d32
	jz op_near16_2
op_near32_2:
	mov eax,[esi+2]
	add eax,4
	add eax,[ebp].reg_eip
	call add_hex_dword
	add esi,5
	ret
op_near16_2:	
	mov ax,[esi+2]
	add ax,4
	add ax,word ptr [ebp].reg_eip
	call add_hex_word
	add esi,3
	ret
op_near2	ENDP

	public op_far

op_far	PROC near
	test [ebp].em_flags,d32
	jz op_far16
op_far32:
	mov ax,[esi+5]
	call add_hex_word
	mov eax,[edi-4]
	and eax,0FFFh
	add eax,kolon_sep
	mov [edi-4],eax
	mov eax,[esi+1]
	add eax,[ebp].reg_eip
	call add_hex_dword
	add esi,6
	ret
op_far16:	
	mov ax,[esi+3]
	call add_hex_word
	mov eax,[edi-4]
	and eax,0FFFh
	add eax,kolon_sep
	mov [edi-4],eax
	mov ax,[esi+1]
	call add_hex_word
	add esi,4
	ret
op_far	ENDP

	public op_enter

op_enter	PROC near
	mov ax,[esi+1]
	call add_hex_word
	mov eax,[edi-4]
	and eax,0FFFh
	add eax,komma_sep
	mov [edi-4],eax
	mov al,[esi+3]
	call add_hex_byte
	add esi,3
	ret
op_enter	ENDP

	public op_address_size

op_address_size	PROC near
	mov ebx,OFFSET main_tab
	mov op_syntax,ebx
	xor [ebp].em_flags,a32
	inc esi
	mov al,[esi]
	movzx eax,al
	call decode_opcode
	ret
op_address_size	ENDP

	public op_data_size

op_data_size	PROC near
	mov ebx,OFFSET main_tab
	mov op_syntax,ebx
	xor [ebp].em_flags,d32
	inc esi
	mov al,[esi]
	movzx eax,al
	call decode_opcode
	ret
op_data_size	ENDP

	public op_wait

op_wait	PROC near
	mov ebx,OFFSET main_tab
	mov op_syntax,ebx
	inc esi
	mov al,[esi]
	movzx eax,al
	call decode_opcode
	ret
op_wait	ENDP

	public op_rep

op_rep	PROC near
	mov ebx,OFFSET main_tab
	mov op_syntax,ebx
	inc esi
	mov al,[esi]
	movzx eax,al
	call decode_opcode
	ret
op_rep	ENDP

add_mne	MACRO com_txt, sep
	mov eax,OFFSET com_txt
	sub eax,OFFSET mne_tab
	add eax,sep
	mov [edi],eax
	add edi,4
		ENDM

	extrn b_txt:near
	extrn w_txt:near
	extrn d_txt:near

	public op_string2b

op_string2b	PROC near
	test [ebp].em_flags,a32
	jz op_stringb16

op_stringb32:
	mov eax,6
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET ds_txt
	add_mne b_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne edi_txt, par_komma_sep
	add_mne ds_txt, kolon_par_sep
	add_mne esi_txt, rhak_sep
	ret
op_stringb16:
	mov eax,4
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET ds_txt
	add_mne b_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne di_txt, par_komma_sep
	add_mne ds_txt, kolon_par_sep
	add_mne si_txt, rhak_sep
	ret	
op_string2b	ENDP

	public op_string2w

op_string2w	PROC near
	test [ebp].em_flags,d32
	jnz op_string2d
	test [ebp].em_flags,a32
	jz op_string2w16

op_string2w32:
	mov eax,6
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET ds_txt
	add_mne w_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne edi_txt, par_komma_sep
	add_mne ds_txt, kolon_par_sep
	add_mne esi_txt, rhak_sep
	ret
op_string2w16:
	mov eax,4
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET ds_txt
	add_mne w_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne di_txt, par_komma_sep
	add_mne ds_txt, kolon_par_sep
	add_mne si_txt, rhak_sep
	ret
op_string2d:
	test [ebp].em_flags,a32
	jz op_string2d16

op_string2d32:
	mov eax,6
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET ds_txt
	add_mne d_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne edi_txt, par_komma_sep
	add_mne ds_txt, kolon_par_sep
	add_mne esi_txt, rhak_sep
	ret
op_string2d16:
	mov eax,4
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET ds_txt
	add_mne d_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne di_txt, par_komma_sep
	add_mne ds_txt, kolon_par_sep
	add_mne si_txt, rhak_sep
	ret	
op_string2w	ENDP


	public op_string1b

op_string1b	PROC near
	test [ebp].em_flags,a32
	jz op_string1b16
op_string1b32:
	mov eax,7
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET es_txt
	add_mne b_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne edi_txt, rhak_sep
	ret
op_string1b16:
	mov eax,5
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET es_txt
	add_mne b_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne di_txt, rhak_sep
	ret	
op_string1b	ENDP

	public op_string1w

op_string1w	PROC near
	test [ebp].em_flags,d32
	jnz op_string1d
	test [ebp].em_flags,a32
	jz op_string1w16
op_string1w32:
	mov eax,7
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET es_txt
	add_mne w_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne edi_txt, rhak_sep
	ret
op_string1w16:
	mov eax,5
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET es_txt
	add_mne w_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne di_txt, rhak_sep
	ret
op_string1d:
	test [ebp].em_flags,a32
	jz op_string1d16
op_string1d32:
	mov eax,7
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET es_txt
	add_mne d_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne edi_txt, rhak_sep
	ret
op_string1d16:
	mov eax,5
	call calc_ads_offset
	mov [ebp].data_sel,OFFSET es_txt
	add_mne d_txt, blank_sep
	add_mne es_txt, kolon_par_sep
	add_mne di_txt, rhak_sep
	ret	
op_string1w	ENDP

	extrn txt_16:near
	extrn txt_32:near

	public op_add_opsize

op_add_opsize	PROC near
	test [ebp].em_flags,d32
	jz op_add16
op_add32:
	add_mne txt_32, blank_sep
	ret
op_add16:
	add_mne txt_16, blank_sep
	ret
op_add_opsize	ENDP

	public op_word16

op_word16	PROC near
	call op_add_opsize
	mov ax,[esi+1]
	call add_hex_word
	add esi,2
	ret
op_word16	ENDP

	public op_math_reg

op_math_reg	PROC near
	mov data_mode,data_16
	call decode_math_mem
	ret
op_math_reg	ENDP

	public opmr_mem8

opmr_mem8	PROC near
	mov data_mode,data_8
	call decode_mem_mode
	ret
opmr_mem8	ENDP

	public opmr_mem16

opmr_mem16	PROC near
	mov data_mode,data_16
	call decode_mem_mode
	ret
opmr_mem16	ENDP

	public opmr_mem2

opmr_mem2	PROC near
	mov data_mode,data_8
	inc esi
	call decode_mem_mode
	ret
opmr_mem2	ENDP

	public opmr_mem3

opmr_mem3	PROC near
	mov data_mode,data_8
	inc esi
	call decode_mem_mode
	mov edata_mode,data_48
	ret
opmr_mem3	ENDP

	public op_mem_byte3

op_mem_byte3	PROC near
	inc esi
	call opmr_mem_im8
	ret
op_mem_byte3	ENDP

	public opmr_mem_im8

opmr_mem_im8	PROC near
	mov data_mode,data_8
	call decode_mem_mode
	call add_komma_to_mem
	mov al,[esi+1]
	call add_hex_byte
	inc esi
	ret
opmr_mem_im8	ENDP

	public opmr_mem_im16

opmr_mem_im16	PROC near
	mov data_mode,data_16
	call decode_mem_mode
	call add_komma_to_mem
	mov al,edata_mode
	cmp al,data_32
	jne not_opmr32
	mov eax,[esi+1]
	call add_hex_dword
	add esi,4
	ret
not_opmr32:
	mov ax,[esi+1]
	call add_hex_word
	add esi,2
	ret
opmr_mem_im16	ENDP

	public opmr_mem_extend_im16

opmr_mem_extend_im16	PROC near
	mov data_mode,data_16
	call decode_mem_mode
	call add_komma_to_mem
	mov al,edata_mode
	cmp al,data_32
	jne not_eopmr32
	movzx eax,byte ptr [esi+1]
	call add_hex_dword
	inc esi
	ret
not_eopmr32:
	movzx ax,byte ptr [esi+1]
	call add_hex_word
	inc esi
	ret
opmr_mem_extend_im16	ENDP

	public op_reg_mem_byte

op_reg_mem_byte	PROC near
	mov data_mode,data_8
	mov al,[esi+1]
	call decode_reg
	mov eax,[edi-4]
	and eax,0FFFh
	or eax,komma_sep
	mov [edi-4],eax
	call decode_mem_mode
	inc esi
	ret
op_reg_mem_byte	ENDP

	public op_reg_mem_byte2

op_reg_mem_byte2	PROC near
	inc esi
	call op_reg_mem_byte
	ret
op_reg_mem_byte2	ENDP

	public op_reg_mem_word

op_reg_mem_word	PROC near
	mov data_mode,data_16
	mov al,[esi+1]
	call decode_reg
	mov eax,[edi-4]
	and eax,0FFFh
	or eax,komma_sep
	mov [edi-4],eax
	call decode_mem_mode
	inc esi
	ret
op_reg_mem_word	ENDP

	public op_reg_mem2_byte

op_reg_mem2_byte	PROC near
	inc esi
	call op_reg_mem_byte
	ret
op_reg_mem2_byte	ENDP

	public op_reg_mem2_word

op_reg_mem2_word	PROC near
	inc esi
	call op_reg_mem_word
	ret
op_reg_mem2_word	ENDP

	public op_mem_reg_byte

op_mem_reg_byte PROC near
	mov data_mode,data_8
	mov al,[esi+1]
	push ax
	call decode_mem_mode
	call add_komma_to_mem
	pop ax
	call decode_reg
	ret
op_mem_reg_byte	ENDP

	public op_mem_reg_word

op_mem_reg_word	PROC near
	mov data_mode,data_16
	mov al,[esi+1]
	push ax
	call decode_mem_mode
	call add_komma_to_mem
	pop ax
	call decode_reg
	ret
op_mem_reg_word	ENDP

	public op_mem_reg2

op_mem_reg2	PROC near
	inc esi
	call op_mem_reg_word
	ret
op_mem_reg2	ENDP

	public mem_im8

mem_im8	PROC near
	movsx eax,byte ptr [esi+1]
	add [ebp].data_offset,eax
	test al,80h
	je mem_im8_pos
	neg eax
	push eax
	mov eax,[edi-4]
	and eax,0FFFh
	or eax,minus_sep
	mov [edi-4],eax
	pop eax
	jmp mem_im8_j
mem_im8_pos:
	push eax
	mov eax,[edi-4]
	and eax,0FFFh
	or eax,plus_sep
	mov [edi-4],eax
	pop eax
mem_im8_j:
	call add_hex_byte
	inc esi	
	ret
mem_im8	ENDP

	public mem_im16

mem_im16	PROC near
	movsx eax,word ptr [esi+1]
	add [ebp].data_offset,eax
	test ax,8000h
	je mem_im16_pos
	neg eax
	push eax
	mov eax,[edi-4]
	and eax,0FFFh
	or eax,minus_sep
	mov [edi-4],eax
	pop eax
	jmp mem_im16_j
mem_im16_pos:
	push eax
	mov eax,[edi-4]
	and eax,0FFFh
	or eax,plus_sep
	mov [edi-4],eax
	pop eax
mem_im16_j:
	call add_hex_word
	add esi,2
	ret
mem_im16	ENDP

	public mem_im32

mem_im32	PROC near
	mov eax,[esi+1]
	add [ebp].data_offset,eax
	test eax,80000000h
	jz mem_im32_pos
	neg eax
	push eax
	mov eax,[edi-4]
	and eax,0FFFh
	or eax,minus_sep
	mov [edi-4],eax
	pop eax
	jmp mem_im32_save
mem_im32_pos:	
	push eax
	mov eax,[edi-4]
	and eax,0FFFh
	or eax,plus_sep
	mov [edi-4],eax
	pop eax
mem_im32_save:
	call add_hex_dword
	add esi,4
	ret
mem_im32	ENDP

sib_im8	PROC near
	call mem_im8
	mov eax,[edi-4]
	and eax,0FFFh
	or eax,rhak_sep
	mov [edi-4],eax
	ret
sib_im8	ENDP

sib_im32	PROC near
	call mem_im32
	mov eax,[edi-4]
	and eax,0FFFh
	or eax,rhak_sep
	mov [edi-4],eax
	ret
sib_im32	ENDP

	extrn adr_sib_tab:near
	extrn adr_sib_index_tab:near

add_sib_ads	PROC near
	mov ah,[esi-1]
	and ah,0C0h
	mov al,[esi]
	and al,7
	shr ah,3
	or al,ah
	movzx eax,al
	shl eax,3
	mov ebx,eax
	call dword ptr [ebx].adr_sib_tab
	add [ebp].data_offset,eax
	mov al,[esi]
	and al,38h
	shr al,3
	movzx eax,al
	shl ax,3
	mov ebx,eax
	call dword ptr [ebx].adr_sib_index_tab
	mov cl,[esi]
	and cl,0C0h
	shr cl,6
	shl eax,cl
	add [ebp].data_offset,eax
	ret
add_sib_ads	ENDP

	public mem_sib

	extrn mem_sib0_tab:near
	extrn sib_scale_tab:near
	extrn sib_index_tab:near

sib_d_none	PROC near
	mov al,[esi]
	and al,7
	cmp al,5
	je sib_im32
	mov eax,[edi-4]
	and eax,0FFFh
	or eax,rhak_sep
	mov [edi-4],eax
	ret
sib_d_none	ENDP

mem_disp_tab:
sib_dn	DD OFFSET sib_d_none
sib_d8	DD OFFSET sib_im8
sib_d32	DD OFFSET sib_im32

mem_sib	PROC near
	mov eax,OFFSET mem_sib0_tab
	mov op_syntax,eax
	mov ax,[esi]
; al = mod
; ah = sib-byte
	and ah,7
	and al,0C0h	
	shr al,3
	or al,ah
	movzx eax,al
	inc esi
	call decode_opcode
	mov eax,OFFSET sib_index_tab
	mov op_syntax,eax
	mov al,[esi]
	and eax,38h
	shr eax,3
	call decode_opcode	
	mov eax,OFFSET sib_scale_tab
	mov op_syntax,eax
	mov al,[esi]
	and eax,0C0h
	shr eax,6
	call decode_opcode
	call add_sib_ads
	mov bl,[esi-1]
	and bx,0C0h
	movzx ebx,bx
	shr ebx,5
	call dword ptr [2*ebx].mem_disp_tab
	ret
mem_sib	ENDP

	public op_illegal

op_illegal	PROC near
	ret
op_illegal	ENDP

	public op_math

op_math	PROC near
	ret
op_math	ENDP

	public op_one

op_one	PROC near
	ret
op_one	ENDP

;
; ej implementerade f n
;

	public op_reg_cr

op_reg_cr	PROC near	
	ret
op_reg_cr	ENDP

	public op_cr_reg

op_cr_reg	PROC near
	ret
op_cr_reg	ENDP

	public op_reg_dr

op_reg_dr	PROC near
	ret
op_reg_dr	ENDP

	public op_dr_reg

op_dr_reg	PROC near
	ret
op_dr_reg	ENDP

	public op_reg_tr

op_reg_tr	PROC near
	ret
op_reg_tr	ENDP

	public op_tr_reg

op_tr_reg	PROC near
	ret
op_tr_reg	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			
;
;		DESCRIPTION:	Next table procedures
;
;		PARAMETERS:		DI			Instruction buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_next	PROC near
	ret
error_next	ENDP

null_next	PROC near
	call dword ptr op_syntax
	ret
null_next	ENDP

math_one_next	PROC near
	mov al,[esi+1]
	and eax,7
	call decode_opcode
	ret
math_one_next	ENDP

math2_next	PROC near
	mov al,[esi+1]
	and eax,0C0h
	shr eax,6
	call decode_opcode
	ret
math2_next	ENDP

math_reg_next	PROC near
	mov al,[esi+1]
	and eax,38h
	shr eax,3
	call decode_opcode
	ret
math_reg_next	ENDP

mem_reg_next	PROC near
	mov al,[esi+1]
	and eax,38h
	shr eax,3
	call decode_opcode
	ret
mem_reg_next	ENDP

protect_next	PROC near
	mov al,[esi+1]
	movzx eax,al
	call decode_opcode
	ret
protect_next	ENDP

prot2_next		PROC near
	mov al,[esi+2]
	and eax,38h
	shr eax,3
	call decode_opcode
	ret
prot2_next		ENDP

cdt_next		PROC near
	mov al,[esi+2]
	and eax,0C0h
	shr eax,6
	call decode_opcode
	ret
cdt_next		ENDP

mem_op_next		PROC near
	ret
mem_op_next		ENDP

	extrn ax_txt:near
	extrn eax_txt:near
	extrn bx_txt:near
	extrn ebx_txt:near
	extrn cx_txt:near
	extrn ecx_txt:near
	extrn dx_txt:near
	extrn edx_txt:near
	extrn sp_txt:near
	extrn esp_txt:near
	extrn bp_txt:near
	extrn ebp_txt:near
	extrn si_txt:near
	extrn esi_txt:near
	extrn di_txt:near
	extrn edi_txt:near

ax_next	PROC near
	test [ebp].em_flags,d32
	jnz op_eax
op_ax:
	mov eax,OFFSET ax_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
op_eax:
	mov eax,OFFSET eax_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
ax_next	ENDP

bx_next	PROC near
	test [ebp].em_flags,d32
	jnz op_ebx
op_bx:
	mov eax,OFFSET bx_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
op_ebx:
	mov eax,OFFSET ebx_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
bx_next	ENDP

cx_next	PROC near
	test [ebp].em_flags,d32
	jnz op_ecx
op_cx:
	mov eax,OFFSET cx_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
op_ecx:
	mov eax,OFFSET ecx_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
cx_next	ENDP

dx_next	PROC near
	test [ebp].em_flags,d32
	jnz op_edx
op_dx:
	mov eax,OFFSET dx_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
op_edx:
	mov eax,OFFSET edx_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
dx_next	ENDP

sp_next	PROC near
	test [ebp].em_flags,d32
	jnz op_esp
op_sp:
	mov eax,OFFSET sp_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
op_esp:
	mov eax,OFFSET esp_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
sp_next	ENDP

bp_next	PROC near
	test [ebp].em_flags,d32
	jnz op_ebp
op_bp:
	mov eax,OFFSET bp_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
op_ebp:
	mov eax,OFFSET ebp_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
bp_next	ENDP

si_next	PROC near
	test [ebp].em_flags,d32
	jnz op_esi
op_si:
	mov eax,OFFSET si_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
op_esi:
	mov eax,OFFSET esi_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
si_next	ENDP

di_next	PROC near
	test [ebp].em_flags,d32
	jnz op_edi
op_di:
	mov eax,OFFSET di_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
op_edi:
	mov eax,OFFSET edi_txt
	sub eax,OFFSET mne_tab
	add eax,blank_sep
	mov [edi],eax
	add edi,4
	ret
di_next	ENDP
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TEST_FOR_TAB
;
;		DESCRIPTION:	Test for more tables, and execute
;
;		PARAMETERS:		EDI		Code buffer
;						EBX		opcode
;						EAX		Table code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_tab:
nt00	DD OFFSET error_next
nt01	DD OFFSET error_next
nt02	DD OFFSET error_next
nt03	DD OFFSET error_next
nt04	DD OFFSET error_next
nt05	DD OFFSET error_next
nt06	DD OFFSET error_next
nt07	DD OFFSET error_next
nt08	DD OFFSET ax_next
nt09	DD OFFSET cx_next
nt0A	DD OFFSET dx_next
nt0B	DD OFFSET bx_next
nt0C	DD OFFSET sp_next
nt0D	DD OFFSET bp_next
nt0E	DD OFFSET si_next
nt0F	DD OFFSET di_next
nt10	DD OFFSET null_next
nt11	DD OFFSET math_one_next
nt12	DD OFFSET math2_next
nt13	DD OFFSET math_reg_next
nt14	DD OFFSET mem_reg_next
nt15	DD OFFSET protect_next
nt16	DD OFFSET prot2_next
nt17	DD OFFSET cdt_next
nt18	DD OFFSET error_next
nt19	DD OFFSET error_next
nt1A	DD OFFSET error_next
nt1B	DD OFFSET error_next
nt1C	DD OFFSET error_next
nt1D	DD OFFSET error_next
nt1E	DD OFFSET error_next
nt1F	DD OFFSET error_next
	
test_for_tab	PROC near
	add edi,4
	add ebx,4
	push ebx
	mov ebx,eax
	and eax,0FE0h
	cmp eax,0FE0h
	jne not_tab_n
	push ebx
	sub edi,4
	and ebx,1Fh
	cmp ebx,1Fh
	je no_add_kom
	shl ebx,2
	call dword ptr [ebx].next_tab
	pop eax
	and ax,0F000h
	jz no_add_kom
	add eax,OFFSET txt_noth
	sub eax,OFFSET mne_tab
	mov [edi],eax
	add edi,4
	jmp not_tab_n
no_add_kom:
	pop eax
not_tab_n:
	pop ebx
	ret
test_for_tab	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DECODE_OPCODE
;
;		DESCRIPTION:	Decode opcode
;
;		PARAMETERS:		EDI		Coded buffer
;						EAX		Table index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
decode_opcode	PROC near
	mov ebx,eax
	add ebx,ebx
	add ebx,ebx
	add ebx,eax
	add ebx,ebx
	add ebx,ebx
	add ebx,op_syntax
	mov eax,[ebx]
	mov op_syntax,eax
	add ebx,4
	mov eax,[ebx]
	mov [edi],eax
	call test_for_tab
	mov eax,[ebx]
	mov [edi],eax
	call test_for_tab
	mov eax,[ebx]
	mov [edi],eax
	call test_for_tab
	mov eax,[ebx]
	mov [edi],eax
	call test_for_tab
	ret
decode_opcode	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MOVE_MNE_TO_BUF
;
;		DESCRIPTION:	Move mnemonic to buffer
;
;		PARAMETERS:		EBX		MNE IN
;						EDI		Coded buffer
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_mne_to_buf	PROC near
	push eax
	push edi
move_mne_loop:
	mov al,[ebx]
	inc ebx
	or al,al
	jne move_mne_not_end
	pop eax
	jmp move_mne_end
move_mne_not_end:
	cmp al,' '
	jne move_mne_ok
	mov ah,ignore_ptr
	or ah,ah
	je move_mne_ok
	mov ah,[ebx]
	cmp ah,'p'
	jne move_mne_ok
	pop edi
	dec edi
	jmp move_mne_end
move_mne_ok:
	mov [edi],al
	inc edi
	jmp move_mne_loop
move_mne_end:
	pop eax
	ret
move_mne_to_buf	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PUT_OPCODE_IN_TEXT
;
;		DESCRIPTION:	Put opcodes in text form
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn word_ptr_txt:near
	extrn dword_ptr_txt:near

put_opcode_in_text	PROC near
	mov esi,OFFSET op_codes
	lea edi,[ebp].opcode_text
wr_op_next:
	mov eax,[esi]
	cmp eax,0FFFFFFFFh
	je wr_op_end
	mov ebx,eax
	and ebx,0FFFh
	add ebx,OFFSET mne_tab
	cmp ebx,OFFSET word_ptr_txt
	jne not_put_dwptr
	mov al,edata_mode
	cmp al,data_32
	jne not_put_dwptr
	mov ebx,OFFSET dword_ptr_txt
not_put_dwptr:
	cmp ebx,OFFSET ds_txt
	je seg_reg_ov
	cmp ebx,OFFSET ss_txt
	jne not_seg_reg
seg_reg_ov:
	mov [ebp].data_sel,ebx
	mov ecx,override
	or ecx,ecx
	jz not_seg_reg
	cmp ecx,0FFFFFFFFh
	jz not_seg_reg
	mov ebx,ecx
	mov override,0FFFFFFFFh
	mov [ebp].data_sel,ebx
not_seg_reg:
	call move_mne_to_buf
	add esi,4
	and ax,0F000h
	rol ax,5
	mov ebx,eax
	add ebx,OFFSET sep_tab
	mov ax,[ebx]
	cmp al,0
	je wr_op_sep_empt
	mov [edi],al
	inc edi
wr_op_sep_empt:
	cmp ah,0
	je wr_op_sep_null
	mov [edi],ah
	inc edi
wr_op_sep_null:
	jmp wr_op_next
wr_op_end:
	mov eax,override
	or eax,eax
	je wr_ov_klar
	cmp eax,0FFFFFFFFh
	je wr_ov_klar
	mov ebx,eax
	mov al,[edi-1]
	cmp al,20h
	je wr_ov_space
	mov al,20h
	mov [edi],al
	inc al
wr_ov_space:
	call move_mne_to_buf
	mov al,':'
	mov [edi],al
	inc edi
wr_ov_klar:
	mov byte ptr [edi],0
	ret
put_opcode_in_text	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DECODE_DATA_SEL
;
;		DESCRIPTION:	Get data selector for addressing
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


decode_data_sel	PROC near
	mov eax,[ebp].data_sel
	cmp eax,OFFSET ds_txt
	jnz not_ds_ads
	movzx eax,[ebp].reg_ds.d_selector
	mov [ebp].data_sel,eax
	ret
not_ds_ads:
	cmp eax,OFFSET ss_txt
	jnz not_ss_ads
	movzx eax,[ebp].reg_ss.d_selector
	mov [ebp].data_sel,eax
	ret
not_ss_ads:
	cmp eax,OFFSET cs_txt
	jnz not_cs_ads
	movzx eax,[ebp].reg_cs.d_selector
	mov [ebp].data_sel,eax
	ret
not_cs_ads:
	cmp eax,OFFSET es_txt
	jnz not_es_ads
	movzx eax,[ebp].reg_es.d_selector
	mov [ebp].data_sel,eax
	ret
not_es_ads:
	cmp eax,OFFSET fs_txt
	jnz not_fs_ads
	movzx eax,[ebp].reg_fs.d_selector
	mov [ebp].data_sel,eax
	ret
not_fs_ads:
	cmp eax,OFFSET gs_txt
	jnz not_gs_ads
	movzx eax,[ebp].reg_gs.d_selector
	mov [ebp].data_sel,eax
	ret
not_gs_ads:
	ret
decode_data_sel	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DIS_ASS_ONE
;
;		DESCRIPTION:	Disassemble one
;
;		PARAMETERS:		ECX		Size of code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public dis_ass_one

dis_ass_one	PROC near
	push eax
	push ebx
	push edx
	push esi
	push edi
;
	lea esi,[ebp].req_buf
	mov eax,ecx
	mov edi,OFFSET op_in_code
	rep movsb
	mov ecx,10h
	sub ecx,eax
	xor al,al
	rep stosb
;
	xor edi,edi
	test word ptr [ebp].reg_cs.d_access,ACCESS_SIZE
	jz disass_one
	mov edi,1

disass_one:
	mov edx,edi
	mov esi,OFFSET op_in_code
	mov al,[esi]
	movzx eax,al
	mov ebx,OFFSET main_tab
	mov op_syntax,ebx
	mov edi,OFFSET op_codes
	mov [ebp].em_flags,0
	or dl,dl
	jz dis_ass_code_ok
	mov [ebp].em_flags,a32 OR d32

dis_ass_code_ok:
	mov ignore_ptr,0
	mov override,0
	mov [ebp].data_sel,0
	mov [ebp].data_offset,0
	mov [ebp].data_valid,0
;
; esi = opcode
; edi = resultat
; eax = index i tabell
;
	call decode_opcode
	push esi
	mov dword ptr [edi],0FFFFFFFFh
	call put_opcode_in_text
	call decode_data_sel
	pop ecx
	sub ecx,OFFSET op_in_code
	inc ecx
	pop edi
	add edi,ecx
	pop esi
	pop edx
	pop ebx
	pop eax
	ret
dis_ass_one	ENDP

	END 
