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
; MATH.ASM
; Math utilities
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.387
.model flat
						
		NAME  math

.code

dt0		DT 1e1
dt1		DT 1e2
dt2		DT 1e4
dt3		DT 1e8
dt4		DT 1e16
dt5		DT 1e32
dt6		DT 1e64
dt7		DT 1e128
dt8		DT 1e256
dt9		DT 1e512
dt10	DT 1e1024
dt11	DT 1e2048
dt12	DT 1e4096

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
	push ebx
	test ax,8000h
	pushf
	jz float_scale_pos
	neg ax
float_scale_pos:
	mov ebx,OFFSET dt0
	sub ebx,10
	fld1
float_scale_next:
	add ebx,10
	or ax,ax
	jz float_scale_end
	clc
	rcr ax,1
	jnc float_scale_next
	fld tbyte ptr [ebx]
	fmulp st(1),st
	jmp float_scale_next
float_scale_end:
	popf
	jz float_scale_no_inv
	fld1
	fdivrp st(1),st
float_scale_no_inv:
	pop ebx
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
	push ecx
	push edx
	push esi
	xor dh,dh
	mov ax,dx
	neg ax
	call float_power10
	fld dt_half
	fmulp st(1),st
	faddp st(1),st
	mov esi,OFFSET dt12
	mov ecx,13
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
	fld tbyte ptr [esi]
	fcomp st(1)
	fstsw ax
	sahf
	jz float_split_lower
	jnc float_split_lower
	fld tbyte ptr [esi]
	fdivp st(1),st
	stc
	jmp float_split_next
float_split_lower:
	clc
float_split_next:
	rcl dx,1
	sub esi,10
	loop float_split_loop
	popf
	jc float_split_end
	fld1
	fdivrp st(1),st
	neg dx
float_split_end:
	mov ax,dx
	pop esi
	pop edx
	pop ecx
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
;		PARAMETERS:		ES:EDI	STRING
;						AX		EXPONENT
;						CL		STRING SIZE
;						DL		NUMBER OF DECIMALS
;							NC	POSITIVE NUMBER
;							CY	NEGATIVE NUMBER
;
;		RETURN:			ES:EDX	OFFSET TO "."
;						ES:EDI	ADDRESS WHERE TO START WRITING MANTISSA
;						ES:ESI	LAST CHAR IN STRING
;							NC	OK
;							CY	FEL, TO BIG NUMBER
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_init_string	PROC near
	push ecx
	push ebx
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
	movzx ebx,bl
	add ebx,edi
	mov esi,ebx
	movzx ebx,cl
	add ebx,edi
	xchg ebx,esi
	or ch,ch
	jz float_istr_nodot
	push ecx
	movzx ecx,ch
	mov al,' '
	rep stosb	
	pop ecx
float_istr_nodot:
	popf
	jnc float_istr_nosign
	mov al,'-'
	stosb
float_istr_nosign:
	movzx ecx,dl
	sub ecx,esi
	neg ecx
	sub ecx,edi
	mov al,'0'
	or ecx,ecx
	jz float_no_lead_zero
	rep stosb
float_no_lead_zero:
	movzx ecx,dl
	or ecx,ecx
	jz float_no_dot
	mov edx,edi
	mov al,'.'
	stosb
	mov al,'0'
	rep stosb
float_no_dot:
	mov edi,ebx
	clc
	jmp float_istr_end
float_istr_error:
	popf
	stc
float_istr_end:
	pop ax
	pop ebx
	pop ecx
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
;						ES:EDI		STRING
;						CH			LEADING BLANKS
;						DH			POSITION OF "."
;						ES:ESI		LAST CHAR IN STRING
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_string	PROC near
	mov ecx,20
	inc esi
	fld1
float_string_loop:
	cmp edi,esi
	je float_string_end
	cmp edi,edx
	jne float_string_no_dot
	inc edi
	cmp esi,edi
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
	or ecx,ecx
	jz float_string_save0
	dec ecx
	mov al,bl
float_string_save0:
	stosb
	fld dt0
	fmulp st(2),st
	cmp esi,edi
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
	fld dt0
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
	fld dt0
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
	mov esi,OFFSET overflow_txt
	mov ecx,13
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
	mov esi,OFFSET unsuported_txt
	mov ecx,10
	rep movsb
	ret
float_unsuported	ENDP

float_nan	PROC near
	mov ax,cs
	mov ds,ax
	mov esi,OFFSET nan_txt
	mov ecx,3
	rep movsb
	ret
float_nan	ENDP

float_infinity	PROC near
	mov ax,cs
	mov ds,ax
	mov esi,OFFSET infinity_txt
	mov ecx,8
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
	mov esi,OFFSET empty_txt
	mov ecx,5
	rep movsb
	ret
float_empty	ENDP

float_denormal	PROC near
	mov ax,cs
	mov ds,ax
	mov esi,OFFSET denormal_txt
	mov ecx,8
	rep movsb
	ret
float_denormal	ENDP

float_type_tab:
ftt0 DD OFFSET float_unsuported
ftt1 DD OFFSET float_nan
ftt2 DD OFFSET float_unsuported
ftt3 DD OFFSET float_nan
ftt4 DD OFFSET float_normal
ftt5 DD OFFSET float_infinity
ftt6 DD OFFSET float_normal
ftt7 DD OFFSET float_infinity
ftt8 DD OFFSET float_zero
ftt9 DD OFFSET float_empty
fttA DD OFFSET float_zero
fttB DD OFFSET float_empty
fttC DD OFFSET float_denormal
fttD DD OFFSET float_unsuported
fttE DD OFFSET float_denormal
fttF DD OFFSET float_unsuported

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FloatToString
;
;		DESCRIPTION:
;
;		PARAMETERS:		ST(0)		NUMBER TO CONVERT
;						CL			SIZE OF STRING
;						DL			NUMBER OF DECIMALS
;						ES:EDI		STRING
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FloatToString

FloatToString	PROC near
	push ds
	pushad
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
	movzx ebx,bl
	shl ebx,2
	popf
	call dword ptr [ebx].float_type_tab
	xor al,al
	stosb
	popad
	pop ds
	ret
FloatToString	ENDP

	END
