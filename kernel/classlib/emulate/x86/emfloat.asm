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
; EMFLOAT.ASM
; Floating point basics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME emfloat

.386
.model flat

RC_MASK	EQU 0C00h
RC_RND	EQU 0000h
RC_DOWN	EQU 0400h
RC_UP	EQU 0800h
RC_CHOP	EQU 0C00h

COMP_A_GT_B	EQU 0
COMP_A_EQ_B	EQU 4000h
COMP_A_LT_B	EQU 100h
COMP_INV	EQU 4500h

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Normalize
;
;		DESCRIPTION:	Normalize macro
;
;		PARAMETERS:		CX:EDX:EAX		Number 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Normalize	MACRO
	local shift
	local found
	local done

shift:
	shl eax,1
	rcl edx,1
	jc found
;
	dec cx
	or cx,cx
	jnz shift
	jmp done

found:
	rcr edx,1
	rcr eax,1

done:
		ENDM

ConstLn2	DW	079ACh,	0D1CFh,	017F7h,	0B172h,	3FFEh
ConstLg2	DW	0F799h,	0FBCFh,	09A84h,	09A20h,	3FFDh
ConstL2t	DW	08AFEh,	0CD1Bh,	0784Bh,	0D49Ah,	4000h
ConstL2e	DW	0F0BCh,	05C17h,	03B29h,	0B8AAh,	3FFFh
ConstSqrt2	DW	06000h,	0F9DEh,	0F333h,	0B504h,	3FFFh
ConstPi		DW	0C235h,	02168h,	0DAA2h,	0C90Fh,	4000h
ConstPi2	DW	0C235h,	02168h,	0DAA2h,	0C90Fh,	3FFFh

Const0	DT 0.0
Const1	DT 1.0
Const2	DT 2.0
Const3	DT 3.0
Const4	DT 4.0
Const5	DT 5.0
Const6	DT 6.0
Const7	DT 7.0
Const8	DT 8.0
Const9	DT 9.0
Const10	DT 10.0
Const11	DT 11.0
Const12	DT 12.0
Const13	DT 13.0
Const14	DT 14.0
Const15	DT 15.0
Const16	DT 16.0
Const17	DT 17.0
Const18	DT 18.0
Const19	DT 19.0
Const20	DT 20.0
Const21	DT 21.0
Const22	DT 22.0
Const23	DT 23.0
Const24	DT 24.0
Const25	DT 25.0

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CmpReal
;
;		DESCRIPTION:	Compare reals
;
;		PARAMETERS:		A		a value
;						B		b value
;
;		RETURNS:		AX		compare result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CmpReal_A	EQU 12
CmpReal_B	EQU 8

	public CmpReal

CmpReal	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov esi,[ebp].CmpReal_A
	mov edi,[ebp].CmpReal_B
	mov ax,[esi+8]
	and ah,7Fh
	cmp ax,7FFFh
	jne cmp_real_a_ok
;
	mov eax,[esi]
	or eax,eax
	jnz cmp_real_nan
	mov eax,[esi+4]
	shl eax,1
	jnc cmp_real_nan
	or eax,eax
	jnz cmp_real_nan

cmp_real_a_ok:
	mov ax,[edi+8]
	and ah,7Fh
	cmp ax,7FFFh
	jne cmp_real_b_ok
;
	mov eax,[esi]
	or eax,eax
	jnz cmp_real_nan
	mov eax,[esi+4]
	shl eax,1
	jnc cmp_real_nan
	or eax,eax
	jnz cmp_real_nan

cmp_real_b_ok:
	mov al,[esi+9]
	xor al,[edi+9]
	test al,80h
	jz cmp_real_same_sign
;
	mov eax,[esi]
	or eax,[esi+4]
	or eax,[edi]
	or eax,[edi+4]
	mov ax,COMP_A_EQ_B
	jz cmp_real_done
;
	mov al,[esi+9]
	test al,80h
	mov ax,COMP_A_GT_B
	jz cmp_real_done
;
	mov ax,COMP_A_LT_B
	jmp cmp_real_done

cmp_real_same_sign:
	mov eax,[esi]
	mov edx,[esi+4]
	mov ebx,[edi]
	mov ecx,[edi+4]
	mov si,[esi+8]
	mov di,[edi+8]
	and si,7FFFh
	and di,7FFFh

cmp_real_a:
	or eax,eax
	jnz cmp_real_a_loop
	or edx,edx
	jnz cmp_real_a_loop
	xor si,si
	jmp cmp_real_b

cmp_real_a_loop:
	inc si
	shl eax,1
	rcl edx,1
	jnc cmp_real_a_loop

cmp_real_b:
	or ecx,ecx
	jnz cmp_real_b_loop
	or ebx,ebx
	jnz cmp_real_b_loop
	xor di,di
	jmp cmp_real_check

cmp_real_b_loop:
	inc di
	shl ebx,1
	rcl ecx,1
	jnc cmp_real_b_loop

cmp_real_check:
	sub si,di
	jnz cmp_real_eval
	sub edx,ecx
	jnz cmp_real_eval
	sub eax,ebx
	jnz cmp_real_eval
	mov ax,COMP_A_EQ_B
	jmp cmp_real_done

cmp_real_eval:
	jc cmp_real_less

cmp_real_above:
	mov si,[ebp].CmpReal_A
	mov al,[esi+9]
	test al,80h
	mov ax,COMP_A_GT_B
	jz cmp_real_done
	mov ax,COMP_A_LT_B
	jmp cmp_real_done

cmp_real_less:
	mov si,[ebp].CmpReal_A
	mov al,[esi+9]
	test al,80h
	mov ax,COMP_A_LT_B
	jz cmp_real_done
	mov ax,COMP_A_GT_B
	jmp cmp_real_done

cmp_real_nan:
	mov ax,COMP_INV
	jmp cmp_real_done

cmp_real_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 8
CmpReal	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddBase
;
;		DESCRIPTION:	Add two numbers, ignore sign
;
;		PARAMETERS:		ESI	first operand
;						EDI	second operand
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBase	Proc near
	push ebx
;
	mov ax,[esi+8]
	and ah,7Fh
	mov dx,[edi+8]
	and dh,7Fh
	cmp ax,dx
	jc uadd_es_larger

uadd_ds_larger:
	mov bx,ax
	sub bx,dx
	mov cx,ax
	mov eax,[edi]
	mov edx,[edi+4]
	cmp bx,64
	jc uadd_ds_not_zero
;
	mov eax,[esi]
	mov edx,[esi+4]
	jmp uadd_done

uadd_ds_not_zero:
	or bx,bx
	jz uadd_add_ds

uadd_normalize_ds:
	shr edx,1
	rcr eax,1
	sub bx,1
	jnz uadd_normalize_ds

uadd_add_ds:
	add eax,[esi]
	adc edx,[esi+4]
	jmp uadd_check_overflow

uadd_es_larger:
	mov bx,dx
	sub bx,ax
	mov cx,dx
	mov eax,[esi]
	mov edx,[esi+4]
	cmp bx,64
	jc uadd_es_not_zero
;
	mov eax,[edi]
	mov edx,[edi+4]
	jmp uadd_done

uadd_es_not_zero:
	or bx,bx
	jz uadd_add_es

uadd_normalize_es:
	shr edx,1
	rcr eax,1
	sub bx,1
	jnz uadd_normalize_es

uadd_add_es:
	add eax,[edi]
	adc edx,[edi+4]

uadd_check_overflow:
	jnc uadd_check_normal
;
	stc
	rcr edx,1
	rcr eax,1
	inc cx

uadd_check_normal:
	mov ebx,eax
	or ebx,edx
	jnz uadd_check_result
;
	xor cx,cx
	jmp uadd_done

uadd_check_result:
	Normalize
	cmp cx,7FFFh
	jne uadd_done
	mov edx,80000000h
	xor eax,eax

uadd_done:
	pop ebx
	ret
AddBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SubBase
;
;		DESCRIPTION:	Subtract two numbers, ignore sign, a > b
;
;		PARAMETERS:		ESI	first operand
;						EDI	second operand
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubBase	Proc near
	push ebx
;
	mov eax,[edi]
	mov edx,[edi+4]
	mov cx,[esi+8]
	sub cx,[edi+8]
	jz usub_do_it
;
	movzx ecx,cx
	cmp cx,64
	jc usub_normalize_loop
;
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	jmp usub_done

usub_normalize_loop:
	shr edx,1
	rcr eax,1
	loop usub_normalize_loop

usub_do_it:
	mov cx,[esi+8]
	mov ebx,eax
	mov eax,[esi]
	sub eax,ebx
	mov ebx,edx
	mov edx,[esi+4]
	sbb edx,ebx

usub_check:
	mov ebx,eax
	or ebx,edx
	jnz usub_check_result
;
	xor cx,cx
	jmp usub_done

usub_check_result:
	Normalize

usub_done:
	pop ebx
	ret
SubBase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SubReal
;
;		DESCRIPTION:	Sub two numbers
;
;		PARAMETERS:		P1	first operand
;						P2	second operand
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Sub_P1	EQU 12
Sub_P2	EQU 8

	public SubReal

SubReal	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov esi,[ebp].Sub_P1
	mov edi,[ebp].Sub_P2
	xor eax,eax
	xor edx,edx

sub_test_p1:
	mov ax,[esi+8]
	and ax,7FFFh
	jz sub_test_p1_zero
;
	cmp ax,7FFFh
	jne sub_test_p2
;
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	jmp sub_done

sub_test_p1_zero:
	mov ebx,[esi]
	or ebx,[esi+4]
	jnz sub_test_p2
;
	mov eax,[edi]
	mov edx,[edi+4]
	mov cx,[edi+8]
	xor ch,80h
	jmp sub_done

sub_test_p2:
	mov dx,[edi+8]
	and dx,7FFFh
	jz sub_test_p2_zero
;
	cmp dx,7FFFh
	jne sub_do_it
;
	mov eax,[edi]
	mov edx,[edi+4]
	mov cx,[edi+8]
	xor ch,80h
	jmp sub_done

sub_test_p2_zero:
	mov ebx,[edi]
	or ebx,[edi+4]
	jnz sub_do_it
;
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	jmp sub_done

sub_do_it:
	mov ebx,eax
	sub ebx,edx
	or ebx,ebx
	jnz sub_perform
	mov ebx,[esi+4]
	sub ebx,[edi+4]
	jnz sub_perform
	mov ebx,[esi]
	sub ebx,[edi]
	jnz sub_perform
;
	xor eax,eax
	xor edx,edx
	xor cx,cx
	jmp sub_done

sub_perform:
	mov cl,[esi+9]
	xor cl,[edi+9]
	test cl,80h
	jz sub_same_sign
;
	call AddBase
	push bx
	mov bl,[esi+9]
	and bl,80h
	or ch,bl
	pop bx
	jmp sub_done

sub_same_sign:
	shl ebx,1
	pushf
	jnc sub_switch_ok
;
	mov esi,[ebp].Sub_P2
	mov edi,[ebp].Sub_P1

sub_switch_ok:
	call SubBase
	popf
	push bx
	rcr bh,1
	mov bl,[esi+9]
	xor bl,bh
	and bl,80h
	or ch,bl
	pop bx

sub_done:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 8
SubReal	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddReal
;
;		DESCRIPTION:	Add two numbers
;
;		PARAMETERS:		P1	first operand
;						P2	second operand
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Add_P1	EQU 12
Add_P2	EQU 8

	public AddReal

AddReal	Proc near
	push ebp
	mov ebp,esp
	push esi
	push edi
;
	mov esi,[ebp].Add_P1
	mov edi,[ebp].Add_P2
	mov al,[esi+9]
	xor al,[edi+9]
	test al,80h
	jz add_test_p1
;
	mov al,[esi+9]
	test al,80h
	jz add_pn

add_np:
	xor byte ptr [esi+9], 80h 
	push edi
	push esi
	call SubReal
	xor byte ptr [esi+9], 80h
	jmp add_done

add_pn:
	xor byte ptr [edi+9], 80h
	push esi
	push edi
	call SubReal
	xor byte ptr [edi+9], 80h
	jmp add_done

add_test_p1:
	mov ax,[esi+8]
	and ax,7FFFh
	jz add_test_p1_zero
;
	cmp ax,7FFFh
	jne add_test_p2
;
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	jmp add_done

add_test_p1_zero:
	mov eax,[esi]
	or eax,[esi+4]
	jnz add_test_p2
;
	mov eax,[edi]
	mov edx,[edi+4]
	mov cx,[edi+8]
	jmp add_done

add_test_p2:
	mov ax,[edi+8]
	and ax,7FFFh
	jz add_test_p2_zero
;
	cmp ax,7FFFh
	jne add_do_it
;
	mov eax,[edi]
	mov edx,[edi+4]
	mov cx,[edi+8]
	jmp add_done

add_test_p2_zero:
	mov eax,[edi]
	or eax,[edi+4]
	jnz add_do_it
;
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	jmp add_done

add_do_it:
	call AddBase
	push bx
	mov bl,[esi+9]
	and bl,80h
	or ch,bl
	pop bx

add_done:
	pop edi
	pop esi
	pop ebp
	ret 8
AddReal	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			MulReal
;
;		DESCRIPTION:	Multiply two numbers
;
;		PARAMETERS:		P1	first operand
;						P2	second operand
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mul_P1	EQU 12
Mul_P2	EQU 8

	public MulReal

MulReal	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov esi,[ebp].Mul_P1
	mov edi,[ebp].Mul_P2
	mov ax,[esi+8]
	and ax,7FFFh
	jz mul_test_p1_zero
;
	cmp ax,7FFFh
	jne mul_test_p2
;
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	jmp mul_done

mul_test_p1_zero:
	mov eax,[esi]
	or eax,[esi+4]
	jnz mul_test_p2
;
	xor eax,eax
	xor edx,edx
	xor cx,cx
	jmp mul_done

mul_test_p2:
	mov ax,[edi+8]
	and ax,7FFFh
	jz mul_test_p2_zero
;
	cmp ax,7FFFh
	jne mul_do_it
;
	mov eax,[edi]
	mov edx,[edi+4]
	mov cx,[edi+8]
	jmp mul_done

mul_test_p2_zero:
	mov eax,[edi]
	or eax,[edi+4]
	jnz mul_do_it
;
	xor eax,eax
	xor edx,edx
	xor cx,cx
	jmp mul_done

mul_do_it:
	push bp
	xor bp,bp
	mov eax,[esi]
	mul dword ptr [edi+4]
	mov ecx,edx
	mov ebx,eax
	mov eax,[esi+4]
	mul dword ptr [edi]
	add ebx,eax
	adc ecx,edx
	adc bp,0
	mov eax,[esi]
	mul dword ptr [edi]
	add ebx,edx
	adc ecx,0
	adc bp,0
	add ebx,80000000h
	mov ebx,ecx
	adc ebx,0
	movzx ecx,bp
	adc ecx,0
	mov eax,[esi+4]
	mul dword ptr [edi+4]
	add eax,ebx
	adc edx,ecx
	pop bp
;
	mov cx,[esi+8]
	and ch,7Fh
	mov bx,[edi+8]
	and bh,7Fh
	add cx,bx
	sub cx,3FFFh - 1
	jc mul_underflow
	cmp cx,7FFFh
	jnc mul_overflow

mul_check_result:
	Normalize
	jmp mul_set_sign

mul_overflow:
	mov cx,7FFFh
	mov edx,80000000h	
	xor eax,eax
	jmp mul_set_sign

mul_underflow:
	neg cx
	movzx ecx,cx
	cmp cx,64
	jc mul_unnormal
	xor edx,edx
	xor eax,eax
	xor cx,cx
	jmp mul_set_sign

mul_unnormal:
	shr edx,1
	rcr eax,1
	loop mul_unnormal

mul_set_sign:
	mov bl,[esi+9]
	xor bl,[edi+9]
	and bl,80h
	or ch,bl

mul_done:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 8
MulReal	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DivReal
;
;		DESCRIPTION:	Divide two numbers
;
;		PARAMETERS:		P1	first operand
;						P2	second operand
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Div_P1	EQU 12
Div_P2	EQU 8

	public DivReal

DivLow	MACRO bit
	local div_one_or
	local div_one_ok

	sub eax,ebx
	jnc div_one_or
	add eax,ebx
	jmp div_one_ok

div_one_or:
	or esi,bit

div_one_ok:
	shr ebx,1
		ENDM

DivMid	MACRO
	local div_one_or
	local div_one_ok

	sub eax,ebx
	sbb edx,ecx
	jnc div_one_or
	add eax,ebx
	adc edx,ecx
	jmp div_one_ok

div_one_or:
	or esi,80000000h

div_one_ok:
	shr ecx,1
	rcr ebx,1
		ENDM

DivHigh	MACRO bit
	local div_one_or
	local div_one_ok

	sub eax,ebx
	sbb edx,ecx
	jnc div_one_or
	add eax,ebx
	adc edx,ecx
	jmp div_one_ok

div_one_or:
	or edi,bit

div_one_ok:
	shr ecx,1
	rcr ebx,1
		ENDM

DivReal	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov esi,[ebp].Div_P1
	mov edi,[ebp].Div_P2
	mov ax,[esi+8]
	and ax,7FFFh
	jz div_test_p1_zero
;
	cmp ax,7FFFh
	jne div_test_p2
;
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	jmp div_done

div_test_p1_zero:
	mov eax,[esi]
	or eax,[esi+4]
	jnz div_test_p2
;
	xor eax,eax
	xor edx,edx
	xor cx,cx
	jmp div_done

div_test_p2:
	mov ax,[edi+8]
	and ax,7FFFh
	jz div_test_p2_zero
;
	cmp ax,7FFFh
	jne div_do_it
;
	xor eax,eax
	xor edx,edx
	xor cx,cx
	jmp div_done

div_test_p2_zero:
	mov eax,[edi]
	or eax,[edi+4]
	jnz div_do_it
;
	mov edx,80000000h
	xor eax,eax
	mov cx,7FFFh
	jmp div_done

div_do_it:
	push esi
	push edi
;
	mov eax,[esi]
	mov edx,[esi+4]
	mov ebx,[edi]
	mov ecx,[edi+4]
	xor esi,esi
	xor edi,edi
;
	DivHigh 80000000h
	DivHigh 40000000h
	DivHigh 20000000h
	DivHigh 10000000h
	DivHigh 8000000h
	DivHigh 4000000h
	DivHigh 2000000h
	DivHigh 1000000h
	DivHigh 800000h
	DivHigh 400000h
	DivHigh 200000h
	DivHigh 100000h
	DivHigh 80000h
	DivHigh 40000h
	DivHigh 20000h
	DivHigh 10000h
	DivHigh 8000h
	DivHigh 4000h
	DivHigh 2000h
	DivHigh 1000h
	DivHigh 800h
	DivHigh 400h
	DivHigh 200h
	DivHigh 100h
	DivHigh 80h
	DivHigh 40h
	DivHigh 20h
	DivHigh 10h
	DivHigh 8h
	DivHigh 4h
	DivHigh 2h
	DivHigh 1h
;
	DivMid
;
	DivLow 40000000h
	DivLow 20000000h
	DivLow 10000000h
	DivLow 8000000h
	DivLow 4000000h
	DivLow 2000000h
	DivLow 1000000h
	DivLow 800000h
	DivLow 400000h
	DivLow 200000h
	DivLow 100000h
	DivLow 80000h
	DivLow 40000h
	DivLow 20000h
	DivLow 10000h
	DivLow 8000h
	DivLow 4000h
	DivLow 2000h
	DivLow 1000h
	DivLow 800h
	DivLow 400h
	DivLow 200h
	DivLow 100h
	DivLow 80h
	DivLow 40h
	DivLow 20h
	DivLow 10h
	DivLow 8h
	DivLow 4h
	DivLow 2h
	DivLow 1h
;
	mov edx,edi
	mov eax,esi
;
	pop edi
	pop esi
;
	mov cx,[esi+8]
	and ch,7Fh
	mov bx,[edi+8]
	and bh,7Fh
	sub cx,bx
	jc div_check_underflow
	cmp cx,3FFFh
	jae div_overflow
div_check_underflow:
	add cx,3FFFh
	test ch,80h
	jnz div_underflow

div_check_result:
	Normalize
	jmp div_set_sign

div_overflow:
	mov cx,7FFFh
	mov edx,80000000h	
	xor eax,eax
	jmp div_set_sign

div_underflow:
	neg cx
	cmp cx,64
	movzx ecx,cx
	jc div_unnormal
	xor edx,edx
	xor eax,eax
	xor cx,cx
	jmp div_set_sign

div_unnormal:
	shr edx,1
	rcr eax,1
	loop div_unnormal

div_set_sign:
	mov bl,[esi+9]
	xor bl,[edi+9]
	and bl,80h
	or ch,bl

div_done:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 8
DivReal	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DoubleToReal
;
;		DESCRIPTION:	Convert double to real
;
;		PARAMETERS:		Val		double to convert
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoubleToReal_Val	EQU 8

	public DoubleToReal

DoubleToReal	Proc near
	push ebp
	mov ebp,esp
	push bx
	push esi
;
	mov esi,[ebp].DoubleToReal_Val
	mov eax,[esi]
	mov edx,[esi+4]
	shl edx,1
	or edx,eax
	jnz double_to_real_non_zero
	xor cx,cx
	xor eax,eax
	xor edx,edx
	jmp double_to_real_done

double_to_real_non_zero:
	mov cx,[esi+6]
	and ch,7Fh
	shr cx,4
	add cx,3FFFh - 3FFh
	mov edx,[esi+4]
	rol eax,11
	shl edx,11
	mov bx,ax
	and bx,7FFh
	or dx,bx
	and ax,0F800h
	shl edx,1
	stc
	rcr edx,1
;
	mov bl,[esi+7]
	and bl,80h
	or ch,bl

double_to_real_done:
	pop esi
	pop bx
	pop ebp
	ret 4
DoubleToReal	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FloatToReal
;
;		DESCRIPTION:	Convert float to real
;
;		PARAMETERS:		Val		float to convert
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FloatToReal_Val	EQU 8

	public FloatToReal

FloatToReal	Proc near
	push ebp
	mov ebp,esp
	push bx
	push esi
;
	mov esi,[ebp].FloatToReal_Val
	mov eax,[esi]
	shl eax,1
	jnz float_to_real_non_zero
	xor cx,cx
	xor eax,eax
	xor edx,edx
	jmp float_to_real_done

float_to_real_non_zero:
	mov cx,[esi+2]
	and ch,7Fh
	shr cx,7
	add cx,3FFFh - 7Fh
	mov edx,[esi]
	shl edx,9
	stc
	rcr edx,1
	xor eax,eax
;
	mov bl,[esi+3]
	and bl,80h
	or ch,bl

float_to_real_done:
	pop esi
	pop bx
	pop ebp
	ret 4
FloatToReal	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			QwordToReal
;
;		DESCRIPTION:	Convert 8-byte int to real
;
;		PARAMETERS:		Val		qword to convert
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QwordToReal_Val	EQU 8

	public QwordToReal

QwordToReal	Proc near
	push ebp
	mov ebp,esp
	push bx
	push esi
;
	mov esi,[ebp].QwordToReal_Val
	mov eax,[esi]
	or eax,[esi+4]
	jnz qword_to_real_non_zero
	xor cx,cx
	xor eax,eax
	xor edx,edx
	jmp qword_to_real_done

qword_to_real_non_zero:
	mov eax,[esi]
	mov edx,[esi+4]
	shl eax,1
	rcl edx,1
	pushf
	jnc qword_to_real_pos
	not eax
	not edx
	add eax,1
	adc edx,0

qword_to_real_pos:
	mov cx,3FFFh + 62
qword_to_real_shift:
	shl eax,1
	rcl edx,1
	jc qword_to_real_size_found
	dec cx
	jmp qword_to_real_shift		

qword_to_real_size_found:
	stc
	rcr edx,1
	rcr eax,1
	popf
	rcr bl,1
	and bl,80h
	or ch,bl

qword_to_real_done:
	pop esi
	pop bx
	pop ebp
	ret 4
QwordToReal	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LongToReal
;
;		DESCRIPTION:	Convert long to real
;
;		PARAMETERS:		Val		long to convert
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LongToReal_Val	EQU 8

	public LongToReal

LongToReal	Proc near
	push ebp
	mov ebp,esp
	push esi
;
	mov esi,[ebp].LongToReal_Val
	mov edx,[esi]
	or edx,edx
	jnz long_to_real_non_zero
	xor cx,cx
	xor eax,eax
	xor edx,edx
	jmp long_to_real_done

long_to_real_non_zero:
	shl edx,1
	pushf
	jnc long_to_real_pos
	neg edx

long_to_real_pos:
	mov cx,3FFFh + 30
long_to_real_shift:
	shl edx,1
	jc long_to_real_size_found
	dec cx
	jmp long_to_real_shift		

long_to_real_size_found:
	stc
	rcr edx,1
	popf
	rcr al,1
	and al,80h
	or ch,al
	xor eax,eax

long_to_real_done:
	pop esi
	pop ebp
	ret 4
LongToReal	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			IntToReal
;
;		DESCRIPTION:	Convert int to real
;
;		PARAMETERS:		Val		int to convert
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IntToReal_Val	EQU 8

	public IntToReal

IntToReal	Proc near
	push ebp
	mov ebp,esp
	push esi
;
	mov esi,[ebp].IntToReal_Val
	mov dx,[esi]
	or dx,dx
	jnz int_to_real_non_zero
	xor cx,cx
	xor eax,eax
	xor edx,edx
	jmp int_to_real_done

int_to_real_non_zero:
	shl dx,1
	pushf
	jnc int_to_real_pos
	neg dx

int_to_real_pos:
	mov cx,3FFFh + 14
int_to_real_shift:
	shl dx,1
	jc int_to_real_size_found
	dec cx
	jmp int_to_real_shift		

int_to_real_size_found:
	stc
	rcr dx,1
	popf
	rcr al,1
	and al,80h
	or ch,al
	shl edx,16
	xor eax,eax

int_to_real_done:
	pop esi
	pop ebp
	ret 4
IntToReal	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			BcdToReal
;
;		DESCRIPTION:	Convert 18 digit bcd to real
;
;		PARAMETERS:		Val		bcd string to convert
;
;		RETURNS:		CX		exponent
;						EDX:EAX	mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BcdToReal_Val	EQU 8

	public BcdToReal

BcdToReal	Proc near
	push ebp
	mov ebp,esp
	push esi
;
	mov esi,[ebp].BcdToReal_Val
	xor edx,edx
	xor eax,eax
	add esi,8
	stc
	mov ecx,18
	pushf

bcd_to_real_loop:
	push ecx
	add eax,eax
	adc edx,edx
	mov ecx,edx
	mov ebx,eax
	add eax,eax
	adc edx,edx
	add eax,eax
	adc edx,edx
	add eax,ebx
	adc edx,ecx
	pop ecx
	popf
	jc bcd_to_real_high
;
	mov bl,[esi]
	and bl,0Fh
	movzx ebx,bl
	add eax,ebx
	adc edx,0
	dec esi
	stc
	jmp bcd_to_real_next

bcd_to_real_high:
	mov bl,[esi]
	shr bl,4
	movzx ebx,bl
	add eax,ebx
	adc edx,0
	clc

bcd_to_real_next:
	pushf
	loop bcd_to_real_loop
;
	popf
	mov esi,[ebp].BcdToReal_Val
	test byte ptr [esi+9],80h
	jz bcd_to_real_conv
;
	not eax
	not edx
	add eax,1
	adc edx,0

bcd_to_real_conv:
	push edx
	push eax
	mov ebp,esp
	push ebp
	call QwordToReal
	add esp,8

bcd_to_real_done:
	pop esi
	pop ebp
	ret 4
BcdToReal	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RealToDouble
;
;		DESCRIPTION:	Convert real to double
;
;		PARAMETERS:		Val		real to convert
;
;		RETURNS:		EDX:EAX	returned double
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToDouble_Val	EQU 8

	public RealToDouble

RealToDouble	Proc near
	push ebp
	mov ebp,esp
	push ecx
	push esi
;
	mov esi,[ebp].RealToDouble_Val
	mov eax,[esi]
	shr eax,11
	mov edx,[esi+4]
	and edx,7FFh
	ror edx,11
	or eax,edx
	mov edx,[esi+4]
	mov cx,[esi+8]
	and cx,7FFFh
	sub cx,3FFFh
	add cx,3FFh
	test ch,80h
	jnz real_to_double_underflow
;
	cmp cx,7FFh
	jnc real_to_double_overflow
;
	movzx ecx,cx
	shl ecx,20
	shl edx,1
	shr edx,12
	or edx,ecx
	shl edx,1
	mov ch,[esi+9]
	shl ch,1
	rcr edx,1
	clc
	jmp real_to_double_done

real_to_double_underflow:
	xor eax,eax
	xor edx,edx
	clc
	jmp real_to_double_done

real_to_double_overflow:
	mov edx,7FF80000h
	xor eax,eax
	stc

real_to_double_done:
	pop esi
	pop ecx
	pop ebp
	ret 4
RealToDouble	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RealToFloat
;
;		DESCRIPTION:	Convert real to float
;
;		PARAMETERS:		Val		real to convert
;
;		RETURNS:		EAX	returned float
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToFloat_Val	EQU 8

	public RealToFloat

RealToFloat	Proc near
	push ebp
	mov ebp,esp
	push ecx
	push esi
;
	mov esi,[ebp].RealToFloat_Val
	mov cx,[esi+8]
	and cx,7FFFh
	sub cx,3FFFh
	add cx,7Fh
	test ch,80h
	jnz real_to_float_underflow
;
	cmp cx,0FFh
	jnc real_to_float_overflow
;
	movzx ecx,cx
	shl ecx,23
	mov eax,[esi+4]
	shl eax,1
	shr eax,9
	or eax,ecx
	shl eax,1
	mov ch,[esi+9]
	shl ch,1
	rcr eax,1
	clc
	jmp real_to_float_done

real_to_float_underflow:
	xor eax,eax
	clc
	jmp real_to_float_done

real_to_float_overflow:
	mov eax,7FC00000h
	stc

real_to_float_done:
	pop esi
	pop ecx
	pop ebp
	ret 4
RealToFloat	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RealToQword
;
;		DESCRIPTION:	Convert real to 8-byte int
;						Mode	rounding mode
;
;		PARAMETERS:		Val		real to round
;
;		RETURNS:		EDX:EAX	8-byte int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToQword_Val		EQU 12
RealToQword_mode	EQU 8

	public RealToQword

RealToQword	Proc near
	push ebp
	mov ebp,esp
	push ecx
	push esi
;
	mov esi,[ebp].RealToQword_Val
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	and cx,7FFFh
	sub cx,3FFFh
	jnc real_to_qword_check_overflow
;
	cmp cx,-1
	je real_to_qword_valid
;	
	or eax,edx
	mov cx,ax
	shr eax,16
	or cx,ax
	or ch,cl
;
	xor eax,eax
	xor edx,edx
	clc
	jmp real_to_qword_shifted

real_to_qword_check_overflow:
	cmp cx,64
	jc real_to_qword_valid
;
	mov edx,80000000h
	xor eax,eax
	jmp real_to_qword_done

real_to_qword_valid:
	xor ch,ch
real_to_qword_shift_loop:
	cmp cl,62
	je real_to_qword_check
	shr edx,1
	rcr eax,1
	adc ch,0
	inc cl
	jmp real_to_qword_shift_loop

real_to_qword_check:
	cmp cl,63
	je real_to_qword_shifted
;
	shr edx,1
	rcr eax,1

real_to_qword_shifted:
	jc real_to_qword_check_half_or_more
;
	or ch,ch
	jz real_to_qword_rounded
	mov cl,[ebp+1].RealToQword_mode
	and cl,RC_MASK shr 8
	jmp real_to_qword_round_updown

real_to_qword_check_half_or_more:
	mov cl,[ebp+1].RealToQword_mode
	and cl,RC_MASK shr 8
	cmp cl,RC_CHOP shr 8
	je real_to_qword_rounded
	cmp cl,RC_RND shr 8
	je real_to_qword_round

real_to_qword_round_updown:
	cmp cl,RC_DOWN shr 8
	je real_to_qword_down
	cmp cl,RC_UP shr 8
	jne real_to_qword_rounded

real_to_qword_up:
	test byte ptr [esi+9],80h
	jnz real_to_qword_rounded
	jmp real_to_qword_round_up
 
real_to_qword_down:
	test byte ptr [esi+9],80h
	jz real_to_qword_rounded
	jmp real_to_qword_round_up

real_to_qword_round:
	or ch,ch
	jnz real_to_qword_round_up
;
	test al,1
	jz real_to_qword_rounded

real_to_qword_round_up:
	add eax,1
	adc edx,0

real_to_qword_rounded:
	mov cl,[esi+9]
	test cl,80h
	clc
	jz real_to_qword_done
	not eax
	not edx
	add eax,1
	adc edx,0
	clc

real_to_qword_done:
	pop esi
	pop ecx
	pop ebp
	ret 8
RealToQword	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RealToLong
;
;		DESCRIPTION:	Convert real to long
;
;		PARAMETERS:		Val		real to round
;						Mode	rounding mode
;
;		RETURNS:		EAX	long
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToLong_Val	EQU 12
RealToLong_mode	EQU 8

	public RealToLong

RealToLong	Proc near
	push ebp
	mov ebp,esp
	push ecx
	push esi
;
	mov esi,[ebp].RealToLong_Val
	mov eax,[esi+4]
	mov cx,[esi+8]
	and cx,7FFFh
	sub cx,3FFFh
	jnc real_to_long_check_overflow
;
	cmp cx,-1
	je real_to_long_valid
;	
	mov cx,ax
	shr eax,16
	or cx,ax
	or ch,cl
;
	xor eax,eax
	clc
	jmp real_to_long_shifted

real_to_long_check_overflow:
	cmp cx,32
	jc real_to_long_valid
;
	mov eax,80000000h
	stc
	jmp real_to_long_done

real_to_long_valid:
	mov ch,[esi]
	or ch,[esi+1]
	or ch,[esi+2]
	or ch,[esi+3]
real_to_long_shift_loop:
	cmp cl,30
	je real_to_long_check
	shr eax,1
	adc ch,0
	inc cl
	jmp real_to_long_shift_loop

real_to_long_check:
	cmp cl,31
	je real_to_long_shifted
;
	shr eax,1

real_to_long_shifted:
	jc real_to_long_check_half_or_more
;
	or ch,ch
	jz real_to_long_rounded
	mov cl,[ebp+1].RealToLong_mode
	and cl,RC_MASK shr 8
	jmp real_to_long_round_updown

real_to_long_check_half_or_more:
	mov cl,[ebp+1].RealToLong_mode
	and cl,RC_MASK shr 8
	cmp cl,RC_CHOP shr 8
	je real_to_long_rounded
	cmp cl,RC_RND shr 8
	je real_to_long_round

real_to_long_round_updown:
	cmp cl,RC_DOWN shr 8
	je real_to_long_down
	cmp cl,RC_UP shr 8
	jne real_to_long_rounded

real_to_long_up:
	test byte ptr [esi+9],80h
	jnz real_to_long_rounded
	jmp real_to_long_round_up
 
real_to_long_down:
	test byte ptr [esi+9],80h
	jz real_to_long_rounded
	jmp real_to_long_round_up

real_to_long_round:
	or ch,ch
	jnz real_to_long_round_up
;
	test al,1
	jz real_to_long_rounded

real_to_long_round_up:
	inc eax

real_to_long_rounded:
	mov cl,[esi+9]
	test cl,80h
	clc
	jz real_to_long_done
	clc
	neg eax

real_to_long_done:
	pop esi
	pop ecx
	pop ebp
	ret 8
RealToLong	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RealToInt
;
;		DESCRIPTION:	Convert real to int
;
;		PARAMETERS:		Val		real to round
;						Mode	rounding mode
;
;		RETURNS:		AX	int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToInt_Val	EQU 12
RealToInt_mode	EQU 8

	public RealToInt

RealToInt	Proc near
	push ebp
	mov ebp,esp
	push ecx
	push esi
;
	mov esi,[ebp].RealToInt_Val
	mov ax,[esi+6]
	mov cx,[esi+8]
	and cx,7FFFh
	sub cx,3FFFh
	jnc real_to_int_check_overflow
;
	cmp cx,-1
	je real_to_int_valid
;	
	mov cx,ax
	or ch,cl
;
	xor ax,ax
	clc
	jmp real_to_int_shifted

real_to_int_check_overflow:
	cmp cx,16
	jc real_to_int_valid
;
	mov ax,8000h
	stc
	jmp real_to_int_done

real_to_int_valid:
	mov ch,[esi]
	or ch,[esi+1]
	or ch,[esi+2]
	or ch,[esi+3]
	or ch,[esi+4]
	or ch,[esi+5]
real_to_int_shift_loop:
	cmp cl,14
	je real_to_int_check
	shr ax,1
	adc ch,0
	inc cl
	jmp real_to_int_shift_loop

real_to_int_check:
	cmp cl,15
	je real_to_int_shifted
;
	shr ax,1

real_to_int_shifted:
	jc real_to_int_check_half_or_more
;
	or ch,ch
	jz real_to_int_rounded
	mov cl,[ebp+1].RealToInt_mode
	and cl,RC_MASK shr 8
	jmp real_to_int_round_updown

real_to_int_check_half_or_more:
	mov cl,[ebp+1].RealToInt_mode
	and cl,RC_MASK shr 8
	cmp cl,RC_CHOP shr 8
	je real_to_int_rounded
	cmp cl,RC_RND shr 8
	je real_to_int_round

real_to_int_round_updown:
	cmp cl,RC_DOWN shr 8
	je real_to_int_down
	cmp cl,RC_UP shr 8
	jne real_to_int_rounded

real_to_int_up:
	test byte ptr [esi+9],80h
	jnz real_to_int_rounded
	jmp real_to_int_round_up
 
real_to_int_down:
	test byte ptr [esi+9],80h
	jz real_to_int_rounded
	jmp real_to_int_round_up

real_to_int_round:
	or ch,ch
	jnz real_to_int_round_up
;
	test al,1
	jz real_to_int_rounded

real_to_int_round_up:
	inc ax

real_to_int_rounded:
	mov cl,[esi+9]
	test cl,80h
	clc
	jz real_to_int_done
	neg ax
	clc

real_to_int_done:
	pop esi
	pop ecx
	pop ebp
	ret 8
RealToInt	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RealToBcd
;
;		DESCRIPTION:	Convert real to 10-byte bcd string
;
;		PARAMETERS:		Val		real to round
;						Result	bcd string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToBcd_Val		EQU 12
RealToBcd_Result	EQU 8

	public RealToBcd

BcdTab:
bcd18	DQ 1000000000000000000

bcd17	DQ 100000000000000000
bcd16	DQ 10000000000000000
bcd15	DQ 1000000000000000
bcd14	DQ 100000000000000
bcd13	DQ 10000000000000
bcd12	DQ 1000000000000
bcd11	DQ 100000000000
bcd10	DQ 10000000000
bcd9	DQ 1000000000
bcd8	DQ 100000000

bcd7	DD 10000000
bcd6	DD 1000000
bcd5	DD 100000
bcd4	DD 10000
bcd3	DD 1000
bcd2	DD 100
bcd1	DD 10
bcd0	DD 1

RealToBcd	Proc near
	push ebp
	mov ebp,esp
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov esi,[ebp].RealToBcd_Val
	mov edi,[ebp].RealToBcd_Result
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	and cx,7FFFh
	sub cx,3FFFh
	jc real_to_bcd_underflow
;
	cmp cx,64
	jnc real_to_bcd_overflow

	clc
	pushf
real_to_bcd_shift_loop:
	cmp cx,63
	je real_to_bcd_check_sign
	popf
	shr edx,1
	rcr eax,1
	pushf
	inc cx
	jmp real_to_bcd_shift_loop

real_to_bcd_check_sign:
	popf
	adc eax,0
	adc edx,0
	jmp real_to_bcd_output
	
real_to_bcd_overflow:
	mov al,0FFh
	mov ecx,10
	rep stosb
	stc
	jmp real_to_bcd_done
	
real_to_bcd_underflow:
	cmp cx,-1
	jne real_to_bcd_zero
;
	mov al,[esi+7]
	shr al,7
	movzx eax,al
	xor edx,edx
	jmp real_to_bcd_output

real_to_bcd_zero:
	xor al,al
	mov ecx,10
	rep stosb
	jmp real_to_bcd_sign

real_to_bcd_output:
	mov ebx,OFFSET BcdTab
	sub eax,[ebx]
	sbb edx,[ebx+4]
	jnc real_to_bcd_overflow
;
	push ax
	mov ecx,10
	xor al,al
	rep stosb
	pop ax
	dec edi
;
	mov ecx,5
real_to_bcd8_loop:
	add eax,[ebx]
	adc edx,[ebx+4]
	add ebx,8
	dec edi
real_to_bcd8_high_loop:
	sub eax,[ebx]
	sbb edx,[ebx+4]
	jc real_to_bcd8_high_found
	add byte ptr [edi],10h
	jmp real_to_bcd8_high_loop

real_to_bcd8_high_found:
	add eax,[ebx]
	adc edx,[ebx+4]
;
	add ebx,8
real_to_bcd8_low_loop:
	sub eax,[ebx]
	sbb edx,[ebx+4]
	jc real_to_bcd8_low_found
	inc byte ptr [edi]
	jmp real_to_bcd8_low_loop

real_to_bcd8_low_found:
	loop real_to_bcd8_loop
;
	add eax,[ebx]
	add ebx,4
	mov ecx,4
real_to_bcd4_loop:
	add eax,[ebx]
	add ebx,4
	dec edi
real_to_bcd4_high_loop:
	sub eax,[ebx]
	jc real_to_bcd4_high_found
	add byte ptr [edi],10h
	jmp real_to_bcd4_high_loop

real_to_bcd4_high_found:
	add eax,[ebx]
;
	add ebx,4
real_to_bcd4_low_loop:
	sub eax,[ebx]
	jc real_to_bcd4_low_found
	inc byte ptr [edi]
	jmp real_to_bcd4_low_loop

real_to_bcd4_low_found:
	loop real_to_bcd4_loop

real_to_bcd_sign:
	mov cl,[esi+9]
	test cl,80h
	clc
	jz real_to_bcd_done
;
	mov edi,[ebp].RealToBcd_Result
	mov byte ptr [edi+9],80h
	clc

real_to_bcd_done:
	pop esi
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret 8
RealToBcd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CalcExp2M1
;
;		DESCRIPTION:	2^X - 1
;
;		PARAMETERS:		Val		real
;
;		RETURNS:		CX		Exponnent
;						EDX:EAX	Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcExp2M1_Par	EQU 8
CalcExp2M1_xloga	EQU -10
CalcExp2M1_val	EQU -20
CalcExp2M1_rv		EQU -30
CalcExp2M1_tmp	EQU -40

	public CalcExp2M1

CalcExp2M1	Proc near
	push ebp
	mov ebp,esp
	sub esp,40
	push esi
;
	push dword ptr [ebp].CalcExp2M1_Par
	push OFFSET ConstLn2
	call MulReal
;
	mov [ebp].CalcExp2M1_xloga,eax
	mov [ebp+4].CalcExp2M1_xloga,edx
	mov [ebp+8].CalcExp2M1_xloga,cx
;
	mov [ebp].CalcExp2M1_val,eax
	mov [ebp+4].CalcExp2M1_val,edx
	mov [ebp+8].CalcExp2M1_val,cx
;
	mov [ebp].CalcExp2M1_rv,eax
	mov [ebp+4].CalcExp2M1_rv,edx
	mov [ebp+8].CalcExp2M1_rv,cx
;		
	mov ecx,14
	mov esi,OFFSET Const2
calc_exp2m1_loop:
	push ecx
;
	lea eax,[ebp].CalcExp2M1_val
	push eax
	lea eax,[ebp].CalcExp2M1_xloga
	push eax
	call MulReal		
	mov [ebp].CalcExp2M1_tmp,eax
	mov [ebp+4].CalcExp2M1_tmp,edx
	mov [ebp+8].CalcExp2M1_tmp,cx
;
	lea eax,[ebp].CalcExp2M1_tmp
	push eax
	push esi
	call DivReal
	mov [ebp].CalcExp2M1_val,eax
	mov [ebp+4].CalcExp2M1_val,edx
	mov [ebp+8].CalcExp2M1_val,cx
;
	lea eax,[ebp].CalcExp2M1_val
	push eax
	lea eax,[ebp].CalcExp2M1_rv
	push eax
	call AddReal
	mov [ebp].CalcExp2M1_rv,eax
	mov [ebp+4].CalcExp2M1_rv,edx
	mov [ebp+8].CalcExp2M1_rv,cx
;
	pop ecx
	add esi,10
	loop calc_exp2m1_loop
;
	mov cx,[ebp+8].CalcExp2M1_rv
;
	pop esi
	add esp,40
	pop ebp
	ret 4
CalcExp2M1	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CalcLog2
;
;		DESCRIPTION:	log2(x)
;
;		PARAMETERS:		x
;
;		RETURNS:		CX		Exponnent
;						EDX:EAX	Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcLog2_x		EQU 8
CalcLog2_z		EQU -10
CalcLog2_nom	EQU -20
CalcLog2_denom	EQU -30
CalcLog2_x1		EQU -40
CalcLog2_x2		EQU -50
CalcLog2_pow	EQU -60
CalcLog2_sum	EQU -70

	public CalcLog2

CalcLog2	Proc near
	push ebp
	mov ebp,esp
	sub esp,70
	push esi
	push edi
;
	mov esi,[ebp].CalcLog2_x
	mov eax,[esi]
	or eax,[esi+4]
	jz calc_log2_invalid
;
	mov al,[esi+9]
	and al,80h
	jz calc_log2_valid

calc_log2_invalid:
	mov edx,80000000h
	xor eax,eax
	mov cx,7FFFh
	jmp calc_log2_done

calc_log2_valid:
	mov eax,[esi]
	mov [ebp].CalcLog2_z,eax
	mov eax,[esi+4]
	mov [ebp+4].CalcLog2_z,eax
	mov word ptr [ebp+8].CalcLog2_z,3FFFh
	mov di,[esi+8]
	movzx edi,di
	sub edi,3FFFh
;
	lea eax,[ebp].CalcLog2_z
	push eax
	push OFFSET ConstSqrt2
	call CmpReal
	cmp ax,COMP_A_GT_B
	jne calc_log2_exp_ok
	dec word ptr [ebp+8].CalcLog2_z
	inc edi

calc_log2_exp_ok:
	lea eax,[ebp].CalcLog2_z
	push eax
	push OFFSET Const1
	call SubReal
	mov [ebp].CalcLog2_nom,eax
	mov [ebp+4].CalcLog2_nom,edx
	mov [ebp+8].CalcLog2_nom,cx
;
	lea eax,[ebp].CalcLog2_z
	push eax
	push OFFSET Const1
	call AddReal
	mov [ebp].CalcLog2_denom,eax
	mov [ebp+4].CalcLog2_denom,edx
	mov [ebp+8].CalcLog2_denom,cx
;
	lea eax,[ebp].CalcLog2_nom
	push eax
	lea eax,[ebp].CalcLog2_denom
	push eax
	call DivReal
	mov [ebp].CalcLog2_x1,eax
	mov [ebp+4].CalcLog2_x1,edx
	mov [ebp+8].CalcLog2_x1,cx
;
	mov [ebp].CalcLog2_pow,eax
	mov [ebp+4].CalcLog2_pow,edx
	mov [ebp+8].CalcLog2_pow,cx
;
	mov [ebp].CalcLog2_sum,eax
	mov [ebp+4].CalcLog2_sum,edx
	mov [ebp+8].CalcLog2_sum,cx
;
	lea eax,[ebp].CalcLog2_x1
	push eax
	push eax
	call MulReal
	mov [ebp].CalcLog2_x2,eax
	mov [ebp+4].CalcLog2_x2,edx
	mov [ebp+8].CalcLog2_x2,cx
;
	mov esi,OFFSET Const3
	mov ecx,11
calc_log2_loop:
	push ecx
;
	lea eax,[ebp].CalcLog2_pow
	push eax
	lea eax,[ebp].CalcLog2_x2
	push eax
	call MulReal
	mov [ebp].CalcLog2_pow,eax
	mov [ebp+4].CalcLog2_pow,edx
	mov [ebp+8].CalcLog2_pow,cx
;
	lea eax,[ebp].CalcLog2_pow
	push eax
	push esi
	call DivReal
	mov [ebp].CalcLog2_denom,eax
	mov [ebp+4].CalcLog2_denom,edx
	mov [ebp+8].CalcLog2_denom,cx
;
	lea eax,[ebp].CalcLog2_denom
	push eax
	lea eax,[ebp].CalcLog2_sum
	push eax
	call AddReal
	mov [ebp].CalcLog2_sum,eax
	mov [ebp+4].CalcLog2_sum,edx
	mov [ebp+8].CalcLog2_sum,cx
;
	add esi,20
	pop ecx
	loop calc_log2_loop
;
	lea eax,[ebp].CalcLog2_sum
	push eax
	push OFFSET ConstLn2
	call DivReal
	inc cx
	or edi,edi
	jz calc_log2_done
;
	mov [ebp].CalcLog2_sum,eax
	mov [ebp+4].CalcLog2_sum,edx
	mov [ebp+8].CalcLog2_sum,cx
;
	push edi
	mov eax,esp
	push eax
	call LongToReal
	add esp,4
	mov [ebp].CalcLog2_denom,eax
	mov [ebp+4].CalcLog2_denom,edx
	mov [ebp+8].CalcLog2_denom,cx
;
	lea eax,[ebp].CalcLog2_sum
	push eax
	lea eax,[ebp].CalcLog2_denom
	push eax
	call AddReal

calc_log2_done:
	pop edi
	pop esi
	add esp,70
	pop ebp
	ret 4
CalcLog2	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CalcSqrt
;
;		DESCRIPTION:	square root
;
;		PARAMETERS:		x
;
;		RETURNS:		CX		Exponnent
;						EDX:EAX	Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcSqrt_x		EQU 8
CalcSqrt_side	EQU -8
CalcSqrt_left	EQU -16	
CalcSqrt_result	EQU -24

	public CalcSqrt

CalcSqrt	Proc near
	push ebp
	mov ebp,esp
	sub esp,24
	push esi
	push edi
;
	mov esi,[ebp].CalcSqrt_x
	mov eax,[esi]
	or eax,[esi+4]
	jz calc_sqrt_ret
	mov ax,[esi+8]
	test ah,80h
	jnz calc_sqrt_illegal
	and ah,7Fh
	cmp ax,7FFFh
	jne calc_sqrt_start

calc_sqrt_ret:
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	jmp calc_sqrt_done

calc_sqrt_illegal:
	mov edx,80000000h
	xor eax,eax
	mov cx,7FFFh
	jmp calc_sqrt_done

calc_sqrt_start:
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	test cl,1
	jz calc_sqrt_even
;
	shr edx,1
	rcr eax,1
	inc cx

calc_sqrt_even:
	sub cx,4000h
	shr cx,1
	sub cx,64
	mov dword ptr [ebp].CalcSqrt_side,0
	mov dword ptr [ebp+4].CalcSqrt_side,0
	mov dword ptr [ebp].CalcSqrt_left,0
	mov dword ptr [ebp+4].CalcSqrt_left,0
	mov dword ptr [ebp].CalcSqrt_result,0
	mov dword ptr [ebp+4].CalcSqrt_result,0

calc_sqrt_loop:
	inc cx
	shl eax,1
	rcl edx,1
	rcl dword ptr [ebp].CalcSqrt_left,1
	rcl dword ptr [ebp+4].CalcSqrt_left,1
	shl eax,1
	rcl edx,1
	rcl dword ptr [ebp].CalcSqrt_left,1
	rcl dword ptr [ebp+4].CalcSqrt_left,1
;
	mov esi,[ebp].CalcSqrt_side
	mov edi,[ebp+4].CalcSqrt_side
	shl esi,1
	rcl edi,1
	add esi,1
	adc edi,0
	sub [ebp].CalcSqrt_left,esi
	sbb [ebp+4].CalcSqrt_left,edi
	jc calc_sqrt_ge
;
	add dword ptr [ebp].CalcSqrt_side,1
	adc dword ptr [ebp+4].CalcSqrt_side,0
	shl dword ptr [ebp].CalcSqrt_side,1
	rcl dword ptr [ebp+4].CalcSqrt_side,1
	stc
	jmp calc_sqrt_next

calc_sqrt_ge:
	add [ebp].CalcSqrt_left,esi
	adc [ebp+4].CalcSqrt_left,edi
	shl dword ptr [ebp].CalcSqrt_side,1
	rcl dword ptr [ebp+4].CalcSqrt_side,1
	clc

calc_sqrt_next:
	rcl dword ptr [ebp].CalcSqrt_result,1
	rcl dword ptr [ebp+4].CalcSqrt_result,1
	jnc calc_sqrt_loop
;
	add cx,3FFFh - 1
	mov eax,[ebp].CalcSqrt_result
	mov edx,[ebp+4].CalcSqrt_result
	stc
	rcr edx,1
	rcr eax,1
	
calc_sqrt_done:
	pop edi
	pop esi
	add esp,24
	pop ebp
	ret 4
CalcSqrt	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CalcPartialRemainder
;
;		DESCRIPTION:	partial remainder of x / y
;
;		PARAMETERS:		x		first parameter
;						y		second parameter
;						mode	rounding mode
;
;		RETURNS:		CX		Exponnent
;						EDX:EAX	Mantissa
;						EBX		Quot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcPRem_x		EQU 16
CalcPRem_y		EQU 12
CalcPRem_mode	EQU 8
CalcPRem_tmp	EQU -10

	public CalcPartialRemainder

CalcPartialRemainder	Proc near
	push ebp
	mov ebp,esp
	sub esp,10
	push esi
	push edi
;
	mov esi,[ebp].CalcPRem_x
	mov edi,[ebp].CalcPRem_y
	mov ax,[esi+8]
	and ax,7FFFh
	mov dx,[edi+8]
	and dx,7FFFh
	sub ax,dx
	jc calc_prem_small
	cmp ax,64
	jnc calc_prem_big	

calc_prem_small:
	push esi
	push edi
	call DivReal
	mov [ebp].CalcPRem_tmp,eax
	mov [ebp+4].CalcPRem_tmp,edx
	mov [ebp+8].CalcPRem_tmp,cx
;
	lea eax,[ebp].CalcPRem_tmp
	push eax
	push dword ptr [ebp].CalcPRem_mode
	call RealToQword
	mov ebx,eax
	mov [ebp].CalcPRem_tmp,eax
	mov [ebp+4].CalcPRem_tmp,edx
;
	lea eax,[ebp].CalcPRem_tmp
	push eax
	call QwordToReal
	mov [ebp].CalcPRem_tmp,eax
	mov [ebp+4].CalcPRem_tmp,edx
	mov [ebp+8].CalcPRem_tmp,cx
;
	lea eax,[ebp].CalcPRem_tmp
	push eax
	push edi
	call MulReal
	mov [ebp].CalcPRem_tmp,eax
	mov [ebp+4].CalcPRem_tmp,edx
	mov [ebp+8].CalcPRem_tmp,cx
;
	push esi
	lea eax,[ebp].CalcPRem_tmp
	push eax
	call SubReal
	jmp calc_prem_done

calc_prem_big:
	push esi
	push edi
	call DivReal
	mov bx,cx
	and cx,803Fh
	mov [ebp].CalcPRem_tmp,eax
	mov [ebp+4].CalcPRem_tmp,edx
	mov [ebp+8].CalcPRem_tmp,cx
;
	lea eax,[ebp].CalcPRem_tmp
	push eax
	push dword ptr [ebp].CalcPRem_mode
	call RealToQword
	mov [ebp].CalcPRem_tmp,eax
	mov [ebp+4].CalcPRem_tmp,edx
;
	lea eax,[ebp].CalcPRem_tmp
	push eax
	call QwordToReal
	mov cx,bx
	mov [ebp].CalcPRem_tmp,eax
	mov [ebp+4].CalcPRem_tmp,edx
	mov [ebp+8].CalcPRem_tmp,cx
;
	lea eax,[ebp].CalcPRem_tmp
	push eax
	push edi
	call MulReal
	mov [ebp].CalcPRem_tmp,eax
	mov [ebp+4].CalcPRem_tmp,edx
	mov [ebp+8].CalcPRem_tmp,cx
;
	push esi
	lea eax,[ebp].CalcPRem_tmp
	push eax
	call SubReal
	mov ebx,-1

calc_prem_done:
	pop edi
	pop esi
	add esp,10
	pop ebp
	ret 12
CalcPartialRemainder	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CalcSin
;
;		DESCRIPTION:	sin(x)
;
;		PARAMETERS:		x		argument
;
;		RETURNS:		CX		Exponnent
;						EDX:EAX	Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcSin_x		EQU 8
CalcSin_tmp		EQU -10
CalcSin_val		EQU -20
CalcSin_x2		EQU -30
CalcSin_rv		EQU -40

	public CalcSin

CalcSin	Proc near
	push ebp
	mov ebp,esp
	sub esp,40
	push ebx
	push esi
;
	push dword ptr [ebp].CalcSin_x
	push OFFSET ConstPi2
	push RC_CHOP
	call CalcPartialRemainder
	test bl,1
	jz calc_sin_calc
;
	mov [ebp].CalcSin_tmp,eax
	mov [ebp+4].CalcSin_tmp,edx
	mov [ebp+8].CalcSin_tmp,cx
	push OFFSET ConstPi2
	lea eax,[ebp].CalcSin_tmp
	push eax
	call SubReal

calc_sin_calc:
	mov [ebp].CalcSin_val,eax
	mov [ebp+4].CalcSin_val,edx
	mov [ebp+8].CalcSin_val,cx
;
	mov [ebp].CalcSin_rv,eax
	mov [ebp+4].CalcSin_rv,edx
	mov [ebp+8].CalcSin_rv,cx
;
	lea eax,[ebp].CalcSin_val
	push eax
	push eax
	call MulReal
	mov [ebp].CalcSin_x2,eax
	mov [ebp+4].CalcSin_x2,edx
	mov [ebp+8].CalcSin_x2,cx
;
	xor esi,esi
calc_sin_loop:
	xor byte ptr [ebp+9].CalcSin_val,80h
;
	lea eax,[ebp].CalcSin_val
	push eax
	lea eax,[ebp].CalcSin_x2
	push eax
	call MulReal
	mov [ebp].CalcSin_val,eax
	mov [ebp+4].CalcSin_val,edx
	mov [ebp+8].CalcSin_val,cx
;
	mov eax,esi
	shl eax,1
	add eax,2
	mov edx,eax
	inc eax
	mul edx
	mov [ebp].CalcSin_tmp,eax
;
	lea eax,[ebp].CalcSin_tmp
	push eax
	call LongToReal
	mov [ebp].CalcSin_tmp,eax
	mov [ebp+4].CalcSin_tmp,edx
	mov [ebp+8].CalcSin_tmp,cx
;
	lea eax,[ebp].CalcSin_val
	push eax
	lea eax,[ebp].CalcSin_tmp
	push eax
	call DivReal
	mov [ebp].CalcSin_val,eax
	mov [ebp+4].CalcSin_val,edx
	mov [ebp+8].CalcSin_val,cx
;
	lea eax,[ebp].CalcSin_val
	push eax
	lea eax,[ebp].CalcSin_rv
	push eax
	call AddReal
	mov [ebp].CalcSin_rv,eax
	mov [ebp+4].CalcSin_rv,edx
	mov [ebp+8].CalcSin_rv,cx
;
	inc si
	cmp si,11
	jc calc_sin_loop
;
	test bl,2
	jz calc_sin_done
	xor ch,80h

calc_sin_done:
	pop esi
	pop ebx
	add esp,40
	pop ebp
	ret 4
CalcSin	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CalcCos
;
;		DESCRIPTION:	cos(x)
;
;		PARAMETERS:		x		argument
;
;		RETURNS:		CX		Exponnent
;						EDX:EAX	Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcCos_x		EQU 8
CalcCos_tmp		EQU -10
CalcCos_val		EQU -20
CalcCos_x2		EQU -30
CalcCos_rv		EQU -40

	public CalcCos

CalcCos	Proc near
	push ebp
	mov ebp,esp
	sub esp,40
	push ebx
	push esi
;
	push dword ptr [ebp].CalcCos_x
	push OFFSET ConstPi2
	push RC_CHOP
	call CalcPartialRemainder
	test bl,1
	jz calc_cos_calc
;
	mov [ebp].CalcCos_tmp,eax
	mov [ebp+4].CalcCos_tmp,edx
	mov [ebp+8].CalcCos_tmp,cx
	push OFFSET ConstPi2
	lea eax,[ebp].CalcCos_tmp
	push eax
	call SubReal

calc_cos_calc:
	mov [ebp].CalcCos_val,eax
	mov [ebp+4].CalcCos_val,edx
	mov [ebp+8].CalcCos_val,cx
;
	lea eax,[ebp].CalcCos_val
	push eax
	push eax
	call MulReal
	mov [ebp].CalcCos_x2,eax
	mov [ebp+4].CalcCos_x2,edx
	mov [ebp+8].CalcCos_x2,cx
;
	mov esi,OFFSET Const1
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
;
	mov [ebp].CalcCos_rv,eax
	mov [ebp+4].CalcCos_rv,edx
	mov [ebp+8].CalcCos_rv,cx
;
	mov [ebp].CalcCos_val,eax
	mov [ebp+4].CalcCos_val,edx
	mov [ebp+8].CalcCos_val,cx
;
	xor esi,esi
calc_cos_loop:
	xor byte ptr [ebp+9].CalcCos_val,80h
;
	lea eax,[ebp].CalcCos_val
	push eax
	lea eax,[ebp].CalcCos_x2
	push eax
	call MulReal
	mov [ebp].CalcCos_val,eax
	mov [ebp+4].CalcCos_val,edx
	mov [ebp+8].CalcCos_val,cx
;
	mov eax,esi
	shl eax,1
	inc eax
	mov edx,eax
	inc eax
	mul edx
	mov [ebp].CalcCos_tmp,eax
;
	lea eax,[ebp].CalcCos_tmp
	push eax
	call LongToReal
	mov [ebp].CalcCos_tmp,eax
	mov [ebp+4].CalcCos_tmp,edx
	mov [ebp+8].CalcCos_tmp,cx
;
	lea eax,[ebp].CalcCos_val
	push eax
	lea eax,[ebp].CalcCos_tmp
	push eax
	call DivReal
	mov [ebp].CalcCos_val,eax
	mov [ebp+4].CalcCos_val,edx
	mov [ebp+8].CalcCos_val,cx
;
	lea eax,[ebp].CalcCos_val
	push eax
	lea eax,[ebp].CalcCos_rv
	push eax
	call AddReal
	mov [ebp].CalcCos_rv,eax
	mov [ebp+4].CalcCos_rv,edx
	mov [ebp+8].CalcCos_rv,cx
;
	inc si
	cmp si,11
	jc calc_cos_loop
;
	and bl,3
	jz calc_cos_done
	cmp bl,3
	je calc_cos_done
	xor ch,80h

calc_cos_done:
	pop esi
	pop ebx
	add esp,40
	pop ebp
	ret 4
CalcCos	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CalcTan
;
;		DESCRIPTION:	tan(x)
;
;		PARAMETERS:		x		argument
;
;		RETURNS:		CX		Exponnent
;						EDX:EAX	Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcTan_x		EQU 8
CalcTan_sin		EQU -10
CalcTan_cos		EQU -20

	public CalcTan

CalcTan	Proc near
	push ebp
	mov ebp,esp
	sub esp,20
;
	push dword ptr [ebp].CalcTan_x
	call CalcSin
	mov [ebp].CalcTan_sin,eax
	mov [ebp+4].CalcTan_sin,edx
	mov [ebp+8].CalcTan_sin,cx
;
	push dword ptr [ebp].CalcTan_x
	call CalcCos
	mov [ebp].CalcTan_cos,eax
	mov [ebp+4].CalcTan_cos,edx
	mov [ebp+8].CalcTan_cos,cx
;
	lea eax,[ebp].CalcTan_sin
	push eax
	lea eax,[ebp].CalcTan_cos
	push eax
	call DivReal
;
	add esp,20
	pop ebp
	ret 4
CalcTan	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CalcAtan
;
;		DESCRIPTION:	atan(y/x)
;
;		PARAMETERS:		x		argument
;						y		argument
;
;		RETURNS:		CX		Exponnent
;						EDX:EAX	Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcAtan_x		EQU 12
CalcAtan_y		EQU 8
CalcAtan_sum	EQU -10
CalcAtan_pow	EQU -20
CalcAtan_x2		EQU -30
CalcAtan_tmp	EQU -40

	public CalcAtan

CalcAtan	Proc near
	push ebp
	mov ebp,esp
	sub esp,40
	push esi
	push edi
;
	mov esi,[ebp].CalcAtan_x
	mov edi,[ebp].CalcAtan_y
	mov eax,[esi]
	or eax,[esi+4]
	jnz calc_atan_x_nonzero
;
	mov esi,OFFSET ConstPi2
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[edi+8]
	and cx,8000h
	or cx,[esi+8]
	jmp calc_atan_done

calc_atan_x_nonzero:
	mov eax,[edi]
	or eax,[edi+4]
	jnz calc_atan_normal
;
	mov cl,[esi+9]
	test cl,80h
	jz calc_atan_pos_a
	mov esi,OFFSET ConstPi
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	jmp calc_atan_done

calc_atan_pos_a:
	xor eax,eax
	xor edx,edx
	xor cx,cx
	jmp calc_atan_done

calc_atan_normal:
	xor bl,bl
	test byte ptr [edi+9],80h
	jz calc_atan_not_quad1
	or bl,1
calc_atan_not_quad1:
	test byte ptr [esi+9],80h
	jz calc_atan_not_quad2
	or bl,2
calc_atan_not_quad2:
	mov eax,[esi]
	mov edx,[esi+4]
	mov cx,[esi+8]
	and cx,7FFFh
;
	mov [ebp].CalcAtan_sum,eax
	mov [ebp+4].CalcAtan_sum,edx
	mov [ebp+8].CalcAtan_sum,cx
;	
	mov eax,[edi]
	mov edx,[edi+4]
	mov cx,[edi+8]
	and cx,7FFFh
;
	mov [ebp].CalcAtan_pow,eax
	mov [ebp+4].CalcAtan_pow,edx
	mov [ebp+8].CalcAtan_pow,cx
;
	lea eax,[ebp].CalcAtan_pow
	push eax
	lea eax,[ebp].CalcAtan_sum
	push eax
	call CmpReal
	cmp ax,COMP_A_GT_B
	jne calc_atan_not_quad4
;
	or bl,4
	mov eax,[ebp].CalcAtan_sum
	xchg eax,[ebp].CalcAtan_pow
	mov [ebp].CalcAtan_sum,eax
	mov eax,[ebp+4].CalcAtan_sum
	xchg eax,[ebp+4].CalcAtan_pow
	mov [ebp+4].CalcAtan_sum,eax
	mov ax,[ebp+8].CalcAtan_sum
	xchg ax,[ebp+8].CalcAtan_pow
	mov [ebp+8].CalcAtan_sum,ax
calc_atan_not_quad4:
	lea eax,[ebp].CalcAtan_pow
	push eax
	lea eax,[ebp].CalcAtan_sum
	push eax
	call DivReal
	mov [ebp].CalcAtan_sum,eax
	mov [ebp+4].CalcAtan_sum,edx
	mov [ebp+8].CalcAtan_sum,cx
	mov [ebp].CalcAtan_pow,eax
	mov [ebp+4].CalcAtan_pow,edx
	mov [ebp+8].CalcAtan_pow,cx
;
	lea eax,[ebp].CalcAtan_sum
	push eax
	push eax
	call MulReal
	xor ch,80h
	mov [ebp].CalcAtan_x2,eax
	mov [ebp+4].CalcAtan_x2,edx
	mov [ebp+8].CalcAtan_x2,cx

	mov esi,OFFSET Const3
calc_atan_loop:
	lea eax,[ebp].CalcAtan_pow
	push eax
	lea eax,[ebp].CalcAtan_x2
	push eax
	call MulReal
	mov [ebp].CalcAtan_pow,eax
	mov [ebp+4].CalcAtan_pow,edx
	mov [ebp+8].CalcAtan_pow,cx
;
	lea eax,[ebp].CalcAtan_pow
	push eax
	push esi
	call DivReal
	mov [ebp].CalcAtan_tmp,eax
	mov [ebp+4].CalcAtan_tmp,edx
	mov [ebp+8].CalcAtan_tmp,cx
;
	lea eax,[ebp].CalcAtan_tmp
	push eax
	lea eax,[ebp].CalcAtan_sum
	push eax
	call AddReal
	mov [ebp].CalcAtan_sum,eax
	mov [ebp+4].CalcAtan_sum,edx
	mov [ebp+8].CalcAtan_sum,cx
	add esi,20
	cmp esi,OFFSET Const25
	jne calc_atan_loop
;
	test bl,4
	jz calc_atan_not4
;
	push OFFSET ConstPi2
	lea eax,[ebp].CalcAtan_sum
	push eax
	call SubReal
	mov [ebp].CalcAtan_sum,eax
	mov [ebp+4].CalcAtan_sum,edx
	mov [ebp+8].CalcAtan_sum,cx

calc_atan_not4:
	test bl,2
	jz calc_atan_not2
;
	push OFFSET ConstPi
	lea eax,[ebp].CalcAtan_sum
	push eax
	call SubReal
	mov [ebp].CalcAtan_sum,eax
	mov [ebp+4].CalcAtan_sum,edx
	mov [ebp+8].CalcAtan_sum,cx

calc_atan_not2:
	test bl,1
	jz calc_atan_done
	xor ch,80h

calc_atan_done:
	pop edi
	pop esi
	add esp,40
	pop ebp
	ret 8
CalcAtan	Endp

	END
