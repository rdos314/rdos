;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; MATH.ASM
; Math utilities
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

.386p
.387
	
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
	mov cx,14
	rep movsb
	ret
float_normal	ENDP

unsupported_txt	DB 'UNSUPPORTED'
nan_txt			DB 'NAN'
infinity_txt	DB 'INFINITY'
empty_txt		DB 'EMPTY'
denormal_txt	DB 'DENORMAL'
overflow_txt	DB 'TOO BIG NUMBER'

float_unsuported	PROC near
	mov ax,cs
	mov ds,ax
	mov si,OFFSET unsupported_txt
	mov cx,11
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
;		NAME:			FLOAT_GET_CHAR
;
;		DESCRIPTION:	
;
;		PARAMETERS:		ST(0)		NUMBER TO GET CHAR IN
;						CL			SIZE OF STRING
;						CH			POSITION TO RETURN CHAR FOR
;						DL			NUMBER OF DECIMALS
;
;		RETURNS:		AL			TECKEN
;						ST(0)		NUMBER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public float_get_char

float_get_char	PROC near
	push ds
	push bx
	push cx
	push dx
	push si
	push di
	fxam
	fstsw ax
	test ah,2
	clc
	jz float_getch_pos
	fchs
float_getch_pos:
	mov bl,ah
	and bl,7
	and ah,40h
	jz float_getch_zero
	cmp bl,4
	jnz float_getch_end
float_getch_zero:
	call float_split
float_getch_calc:
	push cx
	call float_calc_pos
	pop cx
	jc float_getch_error
	mov bh,ch
	sub bh,dh
	jz float_getch_dot
	jc float_getch_norm
	dec bh
float_getch_norm:
	neg bh
	call float_calc_char
	jmp float_getch_end
float_getch_dot:
	mov al,'.' 
	jmp float_getch_end
float_getch_error:
	finit
	mov al,'E'
float_getch_end:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ds
	ret
float_get_char	ENDP

code	ENDS

	END
