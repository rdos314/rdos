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

INCLUDE ..\os.def
INCLUDE ..\user.def
INCLUDE ..\os.inc
INCLUDE ..\user.inc
INCLUDE ..\os\ipcdebug.inc
INCLUDE ..\os\system.def

data    SEGMENT byte public 'DATA'

MailslotHandle          DW ?
SendBuf                 debug_req_struc <>
CurrentThreadSel        DW ?
Info                    debug_req_info_struc <>
Mne                     debug_req_instr_struc <>
DataHeader              debug_req_data_struc <>
DataArr                 DB 2 * 16 DUP(?)
MathBuf                 DB 80 DUP(?)
ReplyBuf                DB 1024 DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code

dt0		DT 1.0e+1
dt1		DT 1.0e+2
dt2		DT 1.0e+4
dt3		DT 1.0e+8
dt4		DT 1.0e+16
dt5		DT 1.0e+32
dt6		DT 1.0e+64
dt7		DT 1.0e+128
dt8		DT 1.0e+256
dt9		DT 1.0e+512
dt10	DT 1.0e+1024
dt11	DT 1.0e+2048
dt12	DT 1.0e+4096

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_POWER10
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AX			Exponent
;
;		RETURNS:		ST(0)		10**AX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_power10	PROC near
	push ax
	push bx
	test ax,8000h
	pushf
	jz float_scale_pos
	neg ax
float_scale_pos:
	mov bx,OFFSET dt0
	sub bx,10
	fld1
float_scale_next:
	add bx,10
	or ax,ax
	jz float_scale_end
	clc
	rcr ax,1
	jnc float_scale_next
	fld tbyte ptr cs:[bx]
	fmulp st(1),st
	jmp float_scale_next
float_scale_end:
	popf
	jz float_scale_no_inv
	fld1
	fdivrp st(1),st
float_scale_no_inv:
	pop bx
	pop ax
	ret
float_power10	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_SPLIT
;
;		DESCRIPTION:	SPLIT NUMBER INTO 10-EXPONENT AND MANTISSA
;
;		PARAMETERS:		ST(0)		NUMBER IN, MANTISSA OUT
;						AX			EXPONENT IN NUMBER
;						DL			NUMBER OF DECIMALS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dt_half	DT 0.5

float_split	PROC near
	pushf
	push cx
	push dx
	push si
	xor dh,dh
	mov ax,dx
	neg ax
	call float_power10
	fld cs:dt_half
	fmulp st(1),st
	faddp st(1),st
	mov si,OFFSET dt12
	mov cx,13
	xor dx,dx
	fld1
	fcomp st(1)
	fstsw ax
	sahf
	jz float_split_end
	jc float_split_no_invert
	fld1
	fdivrp st(1),st
float_split_no_invert:
	pushf
float_split_loop:
	fld tbyte ptr cs:[si]
	fcomp st(1)
	fstsw ax
	sahf
	jz float_split_lower
	jnc float_split_lower
	fld tbyte ptr cs:[si]
	fdivp st(1),st
	stc
	jmp float_split_next
float_split_lower:
	clc
float_split_next:
	rcl dx,1
	sub si,10
	loop float_split_loop
	popf
	jc float_split_end
	fld1
	fdivrp st(1),st
	neg dx
float_split_end:
	mov ax,dx
	pop si
	pop dx
	pop cx
	popf
	ret
float_split	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_CALC_POS
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AX		EXPONENT
;						CL		STRING SIZE
;						DL		NUMBER OF DECIMALS
;
;		RETURNS:		CH		NUMBER OF LEADING BLANKS
;						DH		POSITION OF DECIMAL  "."
;						BL		MANTISSA POSITION
;						NC		OK
;						CY		CANNOT DISPLAY NUMBER ON FORM
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_calc_pos	PROC near
	push ax
	mov bl,al
	neg bl
	test ax,8000h
	jz float_calc_big
	xor ax,ax
	inc bl
float_calc_big:
	or ah,ah
	jnz float_calc_exp
	mov ch,cl
	sub ch,al
	jc float_calc_exp
	sub ch,dl
	jc float_calc_exp
	sub ch,1
	jc float_calc_exp
	mov dh,cl
	sub dh,dl
	dec dh
	add bl,dh
	jmp float_calc_end
float_calc_exp:
	stc
	pop ax
	ret
float_calc_end:
	or dl,dl
	jnz float_calc_dot
	inc ch
	inc dh
	inc bl
float_calc_dot:
	clc
	pop ax
	ret
float_calc_pos	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_INIT_STRING
;
;		DESCRIPTION:	
;
;		PARAMETERS:		ES:DI	STRING
;						AX		EXPONENT
;						CL		STRING SIZE
;						DL		NUMBER OF DECIMALS
;							NC	POSITIVE NUMBER
;							CY	NEGATIVE NUMBER
;
;		RETURN:			ES:DX	OFFSET TO "."
;						ES:DI	ADDRESS WHERE TO START WRITING MANTISSA
;						ES:SI	LAST CHAR IN STRING
;							NC	OK
;							CY	FEL, TO BIG NUMBER
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_init_string	PROC near
	push cx
	push bx
	push ax
	pushf
	jnc float_istr_calc
	dec cl
float_istr_calc:
	dec cl
	call float_calc_pos
	jnc float_istr_do
	jmp float_istr_error
float_istr_do:
	popf
	pushf
	jnc float_istr_noinc
	inc cl
	inc dh
	inc bl
float_istr_noinc:
	xor bh,bh
	add bx,di
	mov si,bx
	mov bl,cl
	xor bh,bh
	add bx,di
	xchg bx,si
	or ch,ch
	jz float_istr_nodot
	push cx
	mov cl,ch
	xor ch,ch
	mov al,' '
	rep stosb	
	pop cx
float_istr_nodot:
	popf
	jnc float_istr_nosign
	mov al,'-'
	stosb
float_istr_nosign:
	mov cl,dl
	xor ch,ch
	sub cx,si
	neg cx
	sub cx,di
	mov al,'0'
	or cx,cx
	jz float_no_lead_zero
	rep stosb
float_no_lead_zero:
	xor ch,ch
	mov cl,dl
	or cx,cx
	jz float_no_dot
	mov dx,di
	mov al,'.'
	stosb
	mov al,'0'
	rep stosb
float_no_dot:
	mov di,bx
	clc
	jmp float_istr_end
float_istr_error:
	popf
	stc
float_istr_end:
	pop ax
	pop bx
	pop cx
	ret
float_init_string	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_STRING
;
;		DESCRIPTION:	WRITE 10-EXPONENT OCH MANTISSA TO STRING
;
;		PARAMETERS:		ST(0)		MANTISSA 0.1-1.0
;						AX			EXPONENT
;						ES:DI		STRING
;						CH			LEADING BLANKS
;						DH			POSITION OF "."
;						ES:SI		LAST CHAR IN STRING
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_string	PROC near
	mov cx,20
	inc si
	fld1
float_string_loop:
	cmp di,si
	je float_string_end
	cmp di,dx
	jne float_string_no_dot
	inc di
	cmp si,di
	je float_string_end
float_string_no_dot:
	mov bl,'0'
float_string_one_loop:
	fcom st(1)
	fstsw ax
	sahf
	jz float_string_next
	jc float_string_one
	jmp float_string_next
float_string_one:
	inc bl
	fsub st(1),st
	jmp float_string_one_loop
float_string_next:
	mov al,'0'
	or cx,cx
	jz float_string_save0
	dec cx
	mov al,bl
float_string_save0:
	stosb
	fld cs:dt0
	fmulp st(2),st
	cmp si,di
	jne float_string_loop
float_string_end:
	ret
float_string	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_CALC_CHAR
;
;		DESCRIPTION:	CALCULATE CHAR AT POSITION
;
;		PARAMETERS:		ST(0)		MANTISSA 0.1-1.0
;						AX			EXPONENT
;						CL			SIZE OF STRING
;						CH			POSITION IN STRING TO RETRIEVE
;						DH			POSITION OF "."
;						BL			MANTISSA POSITION
;						BH			EXPONENT
;
;		RETURNS:		AL			CHAR
;						ST(0)		TAL UT
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_calc_char	PROC near
	push bx
	push cx
	push dx
	test ax,8000h
	jz float_calc_ch_big
	fld cs:dt0
	fmulp st(1),st
float_calc_ch_big:
	mov dl,'0'
	mov cl,ch
	cmp dh,cl
	jc float_calc_before_dot
	inc cl
float_calc_before_dot:
	sub cl,bl
	jc float_calc_char_end
	xor ch,ch
	fld1
	or cx,cx
	jz float_calc_char_get
float_calc_char_loop:
	fcom st(1)
	fstsw ax
	sahf
	jz float_calc_char_next
	jc float_calc_char_sub
	jmp float_calc_char_next
float_calc_char_sub:
	fsub st(1),st
	jmp float_calc_char_loop
float_calc_char_next:
	fld cs:dt0
	fmulp st(2),st
	loop float_calc_char_loop
float_calc_char_get:
	mov dl,'0'
float_calc_char_conv_loop:
	fcom st(1)
	fstsw ax
	sahf
	jz float_calc_char_end
	jc float_calc_char_subc
	jmp float_calc_char_end
float_calc_char_subc:
	inc dl
	fsub st(1),st
	jmp float_calc_char_conv_loop
float_calc_char_end:
	mov al,dl
	pop dx
	pop cx
	push ax
	mov ah,0FFh
	mov al,dh
	sub al,ch
	jc float_calc_get_exp
	xor ah,ah
	dec ax
float_calc_get_exp:
	finit
	call float_power10
	pop ax
	pop bx
	ret
float_calc_char	ENDP

float_normal	PROC near
	pushf
	call float_split
	call float_init_string
	jc float_error_decode
	popf
	call float_string
	ret
float_error_decode:
	popf
	mov ax,cs
	mov ds,ax
	mov si,OFFSET overflow_txt
	mov cx,13
	rep movsb
	ret
float_normal	ENDP

unsuported_txt	DB 'UNSUPORTED'
nan_txt			DB 'NAN'
infinity_txt	DB 'INFINITY'
empty_txt		DB 'EMPTY'
denormal_txt	DB 'DENORMAL'
overflow_txt	DB 'TO BIG NUMBER'

float_unsuported	PROC near
	mov ax,cs
	mov ds,ax
	mov si,OFFSET unsuported_txt
	mov cx,10
	rep movsb
	ret
float_unsuported	ENDP

float_nan	PROC near
	mov ax,cs
	mov ds,ax
	mov si,OFFSET nan_txt
	mov cx,3
	rep movsb
	ret
float_nan	ENDP

float_infinity	PROC near
	mov ax,cs
	mov ds,ax
	mov si,OFFSET infinity_txt
	mov cx,8
	rep movsb
	ret
float_infinity	ENDP

float_zero	PROC near
	mov al,'0'
	stosb
	ret
float_zero	ENDP

float_empty	PROC near
	mov ax,cs
	mov ds,ax
	mov si,OFFSET empty_txt
	mov cx,5
	rep movsb
	ret
float_empty	ENDP

float_denormal	PROC near
	mov ax,cs
	mov ds,ax
	mov si,OFFSET denormal_txt
	mov cx,8
	rep movsb
	ret
float_denormal	ENDP

float_type_tab:
ftt0 DW OFFSET float_unsuported
ftt1 DW OFFSET float_nan
ftt2 DW OFFSET float_unsuported
ftt3 DW OFFSET float_nan
ftt4 DW OFFSET float_normal
ftt5 DW OFFSET float_infinity
ftt6 DW OFFSET float_normal
ftt7 DW OFFSET float_infinity
ftt8 DW OFFSET float_zero
ftt9 DW OFFSET float_empty
fttA DW OFFSET float_zero
fttB DW OFFSET float_empty
fttC DW OFFSET float_denormal
fttD DW OFFSET float_unsuported
fttE DW OFFSET float_denormal
fttF DW OFFSET float_unsuported

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_TO_STRING
;
;		DESCRIPTION:	
;
;		PARAMETERS:		ST(0)		NUMBER TO CONVERT
;						CL			SIZE OF STRING
;						DL			NUMBER OF DECIMALS
;						ES:DI		STRING
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public float_to_string

float_to_string	PROC near
	push ds
	pusha
	fxam
	fstsw ax
	test ah,2
	clc
	jz float_sign_klar
	fchs
	stc
float_sign_klar:
	pushf
	mov bl,ah
	and bl,7
	and ah,40h
	jz fl_c3_zero
	or bl,8
fl_c3_zero:
	xor bh,bh
	add bx,bx
	popf
	call word ptr cs:[bx].float_type_tab
	xor al,al
	stosb
	popa
	pop ds
	ret
float_to_string	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delimiter
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delimiter       Proc near
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
Delimiter       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NewLine
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NewLine Proc near
    push ax
    mov al,13
    WriteChar
    mov al,10
    WriteChar
    pop ax
    ret
NewLine Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Blank
;
;           DESCRIPTION:    
;
;           PARAMETERS:         CX          Number of blanks to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Blank   Proc near
    push ax
    push cx
    mov al,' '
blank_loop:
    WriteChar
    loop blank_loop
    pop cx
    pop ax
    ret
Blank   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AL          Number
;                           AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

singel_hex      PROC near
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
singel_hex      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AL          Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    PROC near
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
WriteHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AX          Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    PROC near
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
    ret
WriteHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:         EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword   PROC near
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    ret
WriteHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexPtr16
;
;           DESCRIPTION:    
;
;           PARAMETERS:         DX          Segment
;                           BX          Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr16   PROC near
    push ax
    mov ax,dx
    call WriteHexWord
    mov al,':'
    WriteChar
    mov ax,bx
    call WriteHexWord
    pop ax
    ret
WriteHexPtr16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexPtr32
;
;           DESCRIPTION:    
;
;           PARAMETERS:         DX          Segment
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr32   PROC near
    push eax
    mov ax,dx
    call WriteHexWord
    mov al,':'
    WriteChar
    mov eax,ebx
    call WriteHexDword
    pop eax
    ret
WriteHexPtr32   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteEflags
;
;           DESCRIPTION:    
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eflags_tab:
;
;           reset       set
et_cf   DB 'NC ',       'CY '
et_1    DB 0,0,0,       0,0,0
et_pf   DB 'PO ',       'PE '
et_3    DB 0,0,0,       0,0,0
et_af   DB 'NA ',       'AC '
et_5    DB 0,0,0,       0,0,0
et_zf   DB 'NZ ',       'ZR '
et_sf   DB 'PL ',       'NG '
et_tf   DB 0,0,0,       0,0,0
et_if   DB 'DI ',       'EI '
et_df   DB 'UP ',       'DN '
et_of   DB 'NV ',       'OV '
et_12   DB 0,0,0,       0,0,0
et_13   DB 0,0,0,       0,0,0
et_14   DB 'PR ' ,      'NT '
et_15   DB 0,0,0,       0,0,0
et_16   DB 0,0,0,       0,0,0
et_vm   DB 'PM ',       'VM '
et_vi   DB 'PDI',       'PEI'

iopl_text       DB ' IOPL=',0

WriteEflags     PROC near
    push es
    push di
    mov ax,cs
    mov es,ax
    mov ax,word ptr gs:p_tss_eflags
    and ax,200h
    shr ax,7
    or ax,word ptr gs:p_tss_eflags+2
    shl eax,16
    mov ax,word ptr gs:p_tss_eflags
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
    mov ax,word ptr gs:p_tss_eflags
    shr ax,12
    and ax,3
    add ax,'0'
    WriteChar
    pop di
    pop es
    ret
WriteEflags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteWordRegs
;
;           DESCRIPTION:    
;
;           PARAMETERS:         ES:DI       Offset to table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

word_reg_tab1:
    DB ' TR='
    DW 0
    DB ' DT='
    DW OFFSET p_tss_ldt
    DB 0
word_reg_tab2:
    DB ' CS='
    DW OFFSET p_tss_cs
    DB ' DS='
    DW OFFSET p_tss_ds
    DB ' ES='
    DW OFFSET p_tss_es
    DB ' FS='
    DW OFFSET p_tss_fs
    DB ' GS='
    DW OFFSET p_tss_gs
    DB ' SS='
    DW OFFSET p_tss_ss
    DB 0

WriteWordRegs   PROC near
word_write_loop:
    mov al,es:[di]
    or al,al
    je word_write_end
    mov cx,4
    WriteSizeString
    add di,4
    mov bx,es:[di]
    or bx,bx
    jnz word_write_norm
    mov ax,gs
    call WriteHexWord
    jmp word_write_cont
word_write_norm:
    mov ax,gs:[bx]
    call WriteHexWord       
word_write_cont:
    add di,2
    jmp word_write_loop
word_write_end:
    ret
WriteWordRegs   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteDwordRegs
;
;           DESCRIPTION:    
;
;           PARAMETERS:         ES:DI       Offset to table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dword_reg_tab1:
    DB ' EAX='
    DW OFFSET p_tss_eax
    DB ' EBX='
    DW OFFSET p_tss_ebx
    DB ' ECX='
    DW OFFSET p_tss_ecx
    DB ' EDX='
    DW OFFSET p_tss_edx
    DB 0
dword_reg_tab2:
    DB ' ESI='
    DW OFFSET p_tss_esi
    DB ' EDI='
    DW OFFSET p_tss_edi
    DB ' ESP='
    DW OFFSET p_tss_esp
    DB ' EBP='
    DW OFFSET p_tss_ebp
    DB 0
dword_reg_tab3:
    DB ' EPC='
    DW OFFSET p_tss_eip
    DB 0

WriteDwordRegs  PROC near
dword_write_loop:
    mov al,es:[di]
    or al,al
    je dword_write_end
    mov cx,5
    WriteSizeString
    add di,5
    mov bx,es:[di]
    mov eax,gs:[bx]
    call WriteHexDword
    add di,2
    jmp dword_write_loop
dword_write_end:
    ret
WriteDwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteDataRow
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AX          Segment
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDataRow    PROC near
    mov ds:DataHeader.dd_op,DEBUG_REQ_DATA
    test word ptr gs:p_tss_eflags+2,2
    jz write_mode_prot
write_mode_virt:
    mov ds:DataHeader.dd_vm,1
    jmp write_mode_ok
write_mode_prot:
    mov ds:DataHeader.dd_vm,0

write_mode_ok:
    push ax
    mov ds:DataHeader.dd_offset,ebx
    mov ds:DataHeader.dd_sel,ax
    mov ds:DataHeader.dd_count,16
;
    mov ax,ds
    mov es,ax
    pusha
    mov bx,ds:MailslotHandle
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
WriteDataRow    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteFault
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ft_intr DB 'Interrupt fault   ',0
ft_inst DB 'Instruction fault ',0

ft_idt  DB 'idt ',0
ft_ldt  DB 'ldt ',0
ft_gdt  DB 'gdt ',0

WriteFault      PROC near
    test word ptr gs:p_tss_eflags+2,2
    jnz write_fault_end
    mov eax,gs:p_fault_code
    cmp ax,3
    je write_fault_end
    mov ax,cs
    mov es,ax
    mov di,OFFSET ft_inst
    mov eax,gs:p_fault_code
    or ax,ax
    jz write_fault_end
    test ax,1
    jz fault_not_int
    mov di,OFFSET ft_intr
fault_not_int:
    WriteAsciiz
;
    mov eax,gs:p_fault_code
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
    mov eax,gs:p_fault_code
    and ax,0FFF8h
    call WriteHexWord
    ret
write_fault_end:
    mov cx,30
    call Blank
    ret
WriteFault      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteIntCode
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_code_tab:
ke00    DB 'Divide error            '
ke01    DB 'Single step             '
ke02    DB 'NMI                     '
ke03    DB 'Breakpoint              '
ke04    DB 'Overflow                '
ke05    DB 'Array bounds error      '
ke06    DB 'Invalid OP-code         '
ke07    DB '80387 not present       '
ke08    DB 'Double fault            '
ke09    DB '80387 overrun           '
ke0A    DB 'Invalid TSS             '
ke0B    DB 'Segment not present     '
ke0C    DB 'Stack fault             '
ke0D    DB 'Protection fault        '
ke0E    DB 'Page fault              '
ke0F    DB '                        '
ke10    DB '80387 error             '
ke11    DB 'Cannot emulate          '
ke12    DB 'Cannot emulate 80387    '
ke13    DB 'Now in real mode        '
ke14    DB '----------------------- '
ke15    DB 'Illegal int request     '
ke16    DB 'Undefined method        '
ke17    DB 'Invalid handle          '
ke18    DB 'Invalid selector        '

WriteIntCode    Proc near
    movzx dx,gs:p_fault_vector
    cmp dx,18
    ja wicDone
;    
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

wicDone:
    ret
WriteIntCode    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteThread
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteThread     Proc near
    mov ax,gs
    mov es,ax
    mov ax,es:p_id
    call WriteHexWord
    mov al,' '
    WriteChar
    WriteChar
    mov di,OFFSET thread_name
    mov cx,30
    WriteSizeString
    call NewLine
    ret
WriteThread     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteFreeMem
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

phys_mem_comment        DB 'Physical ',0
global_mem_comment      DB '   Global ',0
local_mem_comment       DB '   Local ',0

WriteFreeMem    PROC near
    mov ax,cs
    mov es,ax
;
    mov di,OFFSET phys_mem_comment
    WriteAsciiz
    mov eax,ds:Info.di_free_physical
    call WriteHexDword
;
    mov di,OFFSET global_mem_comment
    WriteAsciiz
    mov eax,ds:Info.di_used_small
    add eax,ds:Info.di_used_big
    call WriteHexDword
;
    mov di,OFFSET local_mem_comment
    WriteAsciiz
    mov eax,ds:Info.di_used_local
    call WriteHexDword
    call NewLine
    ret
WriteFreeMem    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteData
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteData       PROC near
    mov al,ds:Mne.ddi_data_good
    or al,al
    jz data_no_good
;
    mov ax,ds:Mne.ddi_data_sel
    mov ebx,ds:Mne.ddi_data_offset
    call WriteDataRow
    jmp data_next

data_no_good:
    mov cx,79
    call Blank
data_next:
    call NewLine
;
    mov ax,gs:p_tss_cs
    mov ebx,gs:p_tss_eip
    call WriteDataRow
    call NewLine
;
    mov ax,gs:p_tss_ss
    mov ebx,gs:p_tss_esp
    call WriteDataRow
    call NewLine
;
    mov ax,gs:p_tss_es
    xor ebx,ebx
    call WriteDataRow
    call NewLine
;
    push gs:p_tss_eflags+2
    mov word ptr gs:p_tss_eflags+2,0
    mov ax,fs:p_pm_deb_sel
    mov ebx,fs:p_pm_deb_offs
    call WriteDataRow
    call NewLine
;
    mov word ptr gs:p_tss_eflags+2,2
    mov ax,fs:p_vm_deb_sel
    mov ebx,fs:p_vm_deb_offs
    call WriteDataRow
    pop gs:p_tss_eflags+2
    ret
WriteData       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteInstr
;
;               DESCRIPTION:    Write instruction
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInstr      Proc near
    mov ax,ds
    mov es,ax
    mov bx,ds:MailslotHandle
    mov ds:Mne.ddi_op,DEBUG_REQ_INSTR
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
WriteInstr      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCoproc
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; dx = skrivposition
; di = math str„ng offset
; si = math register offset

math0   DB 'ST(0)=  ',0
math1   DB 'ST(1)=  ',0
math2   DB 'ST(2)=  ',0
math3   DB 'ST(3)=  ',0
math4   DB 'ST(4)=  ',0
math5   DB 'ST(5)=  ',0
math6   DB 'ST(6)=  ',0
math7   DB 'ST(7)=  ',0

zero    DB 'Zero                        ',0
nan     DB 'NAN                         ',0
empty   DB 'EMPTY                       ',0

; ax = tag word

write_math      PROC near       
    WriteAsciiz
    mov cl,al
    and cl,3
    jz write_math_norm
;
    cmp cl,1
    je write_math_zero
;
    cmp cl,2
    je write_math_nan

write_math_empty:
    push es
    mov di,cs
    mov es,di
    mov di,OFFSET Empty
    WriteAsciiz
    call NewLine
    pop es
    ret

write_math_nan:
    push es
    mov di,cs
    mov es,di
    mov di,OFFSET nan
    WriteAsciiz
    call NewLine
    pop es
    ret

write_math_zero:
    push es
    mov di,cs
    mov es,di
    mov di,OFFSET zero
    WriteAsciiz
    call NewLine
    pop es
    ret

write_math_norm:    
    fld tbyte ptr gs:[si]
    push es
    push ax
;
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET MathBuf
    mov al,' '
    mov cx,35
    rep stosb
    mov cx,35
    mov di,OFFSET MathBuf
    mov dl,18
    call float_to_string
    WriteSizeString
    pop ax
    pop es
    call NewLine
    ret
write_math      ENDP

WriteCoproc     Proc near
    mov ax,cs
    mov es,ax
    finit
    mov dx,gs:p_math_tag
    mov ax,gs:p_math_status
    shr ax,3
    mov cl,ah
    and cl,7
    add cl,cl
    ror dx,cl
    mov edi,cr0
    test di,4
    jz write_real_math
;
    movzx si,cl
    mov ax,si
    shl ax,2
    add si,ax
    add si,OFFSET p_math_st0
    jmp write_math_do

write_real_math:
    mov si,OFFSET p_math_st0

write_math_do:
    mov ax,dx
    mov di,OFFSET math0
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st1
;
    mov si,OFFSET p_math_st0
    jmp write_st1

write_inc_st1:
    add si,10

write_st1:
    mov di,OFFSET math1
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st2
;
    mov si,OFFSET p_math_st0
    jmp write_st2

write_inc_st2:
    add si,10

write_st2:
    mov di,OFFSET math2
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st3
;
    mov si,OFFSET p_math_st0
    jmp write_st3

write_inc_st3:
    add si,10

write_st3:
    mov di,OFFSET math3
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st4
;
    mov si,OFFSET p_math_st0
    jmp write_st4

write_inc_st4:
    add si,10

write_st4:
    mov di,OFFSET math4
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st5
;
    mov si,OFFSET p_math_st0
    jmp write_st5

write_inc_st5:
    add si,10

write_st5:
    mov di,OFFSET math5
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st6
;
    mov si,OFFSET p_math_st0
    jmp write_st6

write_inc_st6:
    add si,10

write_st6:
    mov di,OFFSET math6
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st7
;
    mov si,OFFSET p_math_st0
    jmp write_st7

write_inc_st7:
    add si,10

write_st7:
    mov di,OFFSET math7
    call write_math
    ret
WriteCoproc     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCpuReg
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg     Proc near
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
WriteCpuReg     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteStatus
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteStatus     Proc near
    call WriteIntCode
    mov al,' '
    WriteChar
    call WriteFault
    call NewLine
    ret
WriteStatus     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCpu
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpu    PROC near
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
WriteCpu    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           get_thread
;
;       DESCRIPTION:    Get current thread block
;
;       RETURNS:        NC              ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread      Proc near
    push es
    mov bx,ds:MailslotHandle
    mov ds:SendBuf.db_op,DEBUG_REQ_THREAD
    mov si,OFFSET SendBuf
    mov cx,1
    mov es,ds:CurrentThreadSel
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
get_thread      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           get_info
;
;               DESCRIPTION:    Get info block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_info        Proc near
    mov bx,ds:MailslotHandle
    mov ds:Info.di_op,DEBUG_REQ_INFO
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
get_info        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteAll
;
;               DESCRIPTION:    Write state
;
;               PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteAll        Proc near
    pusha
    call get_thread
    jc write_all_done
;
    call get_info
    call WriteCpu

write_all_done:
    popa
    ret
WriteAll        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DoFunc
;
;               DESCRIPTION:    Do a function
;
;               PARAMETERS:             AL              Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoFunc  Proc near
    pusha
    mov ds:SendBuf.db_op,al
    GetMousePosition
    shr cx,3
    shr dx,3
    mov ds:SendBuf.db_x,cl
    mov ds:SendBuf.db_y,dl
    mov bx,ds:MailslotHandle
    mov si,OFFSET SendBuf
    mov cx,SIZE debug_req_struc
    mov di,OFFSET ReplyBuf
    mov ax,1024
    SendMailslot
    movzx cx,ds:ReplyBuf.db_x
    movzx dx,ds:ReplyBuf.db_y
    shl cx,3
    shl dx,3
    SetMousePosition
    mov ax,10
    WaitMilliSec
    call WriteAll
    popa
    ret
DoFunc  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   HandleKeyboard
;
;               DESCRIPTION:    Keyboard
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleKeyboard  Proc near
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
HandleKeyboard  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           HandleMouse
;
;               DESCRIPTION:    Mouse handler
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleMouse     Proc near
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
HandleMouse     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ReadNode
;
;               DESCRIPTION:    Read node to debug
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

node_string     DB 'Input IP address to debug> ',0
mailslot_name   DB 'Debug',0

ReadNode        Proc near
    xor cx,cx
    xor dx,dx
    SetCursorPosition
    jmp read_node_local
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET node_string
    WriteAsciiz
;
    mov ax,ds
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
    mov eax,SIZE thread_seg
    AllocateLocalMem
    mov ds:CurrentThreadSel,es
    mov fs,ds:CurrentThreadSel
    mov gs,ds:CurrentThreadSel
;
    mov ax,ds
    mov es,ax
    ret
ReadNode        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           RemoteDebug
;
;               DESCRIPTION:    Remote debug task
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remote_debug_name   DB 'Remote Debug', 0

remote_debug:
    xor ax,ax
    xor bx,bx
    mov cx,639
    mov dx,199
    SetMouseWindow
    mov cx,8
    mov dx,8
    SetMouseMickey
;       
;   ShowMouse
state_start:
    mov ax,100
    WaitMilliSec
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    call ReadNode
    call WriteAll

state_loop:
    call HandleKeyboard
    call HandleMouse
    jmp state_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
;
    mov si,OFFSET remote_debug
    mov di,OFFSET remote_debug_name
    xor dx,dx
    mov ax,test_gate_nr
    RegisterBimodalUserGate
    ret
init    Endp

code    ENDS

    END init
