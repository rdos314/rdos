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
; EMFLOAT.ASM
; Floating point basics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def

RC_MASK EQU 0C00h
RC_RND  EQU 0000h
RC_DOWN EQU 0400h
RC_UP   EQU 0800h
RC_CHOP EQU 0C00h

COMP_A_GT_B     EQU 0
COMP_A_EQ_B     EQU 4000h
COMP_A_LT_B     EQU 100h
COMP_INV        EQU 4500h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Normalize
;
;               DESCRIPTION:    Normalize macro
;
;               PARAMETERS:             CX:EDX:EAX              Number 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Normalize       MACRO
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

code    SEGMENT byte public 'CODE'

        .386p

        assume cs:code

ConstLn2        DW      079ACh, 0D1CFh, 017F7h, 0B172h, 3FFEh
ConstLg2        DW      0F799h, 0FBCFh, 09A84h, 09A20h, 3FFDh
ConstL2t        DW      08AFEh, 0CD1Bh, 0784Bh, 0D49Ah, 4000h
ConstL2e        DW      0F0BCh, 05C17h, 03B29h, 0B8AAh, 3FFFh
ConstSqrt2      DW      06000h, 0F9DEh, 0F333h, 0B504h, 3FFFh
ConstPi         DW      0C235h, 02168h, 0DAA2h, 0C90Fh, 4000h
ConstPi2        DW      0C235h, 02168h, 0DAA2h, 0C90Fh, 3FFFh

Const0  DT 0.0
Const1  DT 1.0
Const2  DT 2.0
Const3  DT 3.0
Const4  DT 4.0
Const5  DT 5.0
Const6  DT 6.0
Const7  DT 7.0
Const8  DT 8.0
Const9  DT 9.0
Const10 DT 10.0
Const11 DT 11.0
Const12 DT 12.0
Const13 DT 13.0
Const14 DT 14.0
Const15 DT 15.0
Const16 DT 16.0
Const17 DT 17.0
Const18 DT 18.0
Const19 DT 19.0
Const20 DT 20.0
Const21 DT 21.0
Const22 DT 22.0
Const23 DT 23.0
Const24 DT 24.0
Const25 DT 25.0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CmpReal
;
;               DESCRIPTION:    Compare reals
;
;               PARAMETERS:             A               a value
;                                               B               b value
;
;               RETURNS:                AX              compare result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CmpReal_A       EQU 8
CmpReal_B       EQU 4

        public CmpReal

CmpReal Proc near
        push bp
        mov bp,sp
        push ds
        push es
        push ebx
        push ecx
        push edx
        push si
        push di
;
        lds si,[bp].CmpReal_A
        les di,[bp].CmpReal_B
        mov ax,[si+8]
        and ah,7Fh
        cmp ax,7FFFh
        jne cmp_real_a_ok
;
        mov eax,[si]
        or eax,eax
        jnz cmp_real_nan
        mov eax,[si+4]
        shl eax,1
        jnc cmp_real_nan
        or eax,eax
        jnz cmp_real_nan

cmp_real_a_ok:
        mov ax,es:[di+8]
        and ah,7Fh
        cmp ax,7FFFh
        jne cmp_real_b_ok
;
        mov eax,[si]
        or eax,eax
        jnz cmp_real_nan
        mov eax,[si+4]
        shl eax,1
        jnc cmp_real_nan
        or eax,eax
        jnz cmp_real_nan

cmp_real_b_ok:
        mov al,[si+9]
        xor al,es:[di+9]
        test al,80h
        jz cmp_real_same_sign
;
        mov eax,[si]
        or eax,[si+4]
        or eax,es:[di]
        or eax,es:[di+4]
        mov ax,COMP_A_EQ_B
        jz cmp_real_done
;
        mov al,[si+9]
        test al,80h
        mov ax,COMP_A_GT_B
        jz cmp_real_done
;
        mov ax,COMP_A_LT_B
        jmp cmp_real_done

cmp_real_same_sign:
        mov eax,[si]
        mov edx,[si+4]
        mov ebx,es:[di]
        mov ecx,es:[di+4]
        mov si,[si+8]
        mov di,[di+8]
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
        mov si,[bp].CmpReal_A
        mov al,[si+9]
        test al,80h
        mov ax,COMP_A_GT_B
        jz cmp_real_done
        mov ax,COMP_A_LT_B
        jmp cmp_real_done

cmp_real_less:
        mov si,[bp].CmpReal_A
        mov al,[si+9]
        test al,80h
        mov ax,COMP_A_LT_B
        jz cmp_real_done
        mov ax,COMP_A_GT_B
        jmp cmp_real_done

cmp_real_nan:
        mov ax,COMP_INV
        jmp cmp_real_done

cmp_real_done:
        pop di
        pop si
        pop edx
        pop ecx
        pop ebx
        pop es
        pop ds
        pop bp
        ret 8
CmpReal Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   AddBase
;
;               DESCRIPTION:    Add two numbers, ignore sign
;
;               PARAMETERS:             DS:SI   first operand
;                                               ES:DI   second operand
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBase Proc near
        push ebx
;
        mov ax,[si+8]
        and ah,7Fh
        mov dx,es:[di+8]
        and dh,7Fh
        cmp ax,dx
        jc uadd_es_larger

uadd_ds_larger:
        mov bx,ax
        sub bx,dx
        mov cx,ax
        mov eax,es:[di]
        mov edx,es:[di+4]
        cmp bx,64
        jc uadd_ds_not_zero
;
        mov eax,[si]
        mov edx,[si+4]
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
        add eax,[si]
        adc edx,[si+4]
        jmp uadd_check_overflow

uadd_es_larger:
        mov bx,dx
        sub bx,ax
        mov cx,dx
        mov eax,[si]
        mov edx,[si+4]
        cmp bx,64
        jc uadd_es_not_zero
;
        mov eax,es:[di]
        mov edx,es:[di+4]
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
        add eax,es:[di]
        adc edx,es:[di+4]

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
AddBase Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SubBase
;
;               DESCRIPTION:    Subtract two numbers, ignore sign, a > b
;
;               PARAMETERS:             DS:SI   first operand
;                                               ES:DI   second operand
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SubBase Proc near
        push ebx
;
        mov eax,es:[di]
        mov edx,es:[di+4]
        mov cx,[si+8]
        sub cx,es:[di+8]
        jz usub_do_it
;
        cmp cx,64
        jc usub_normalize_loop
;
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
        jmp usub_done

usub_normalize_loop:
        shr edx,1
        rcr eax,1
        loop usub_normalize_loop

usub_do_it:
        mov cx,[si+8]
        mov ebx,eax
        mov eax,[si]
        sub eax,ebx
        mov ebx,edx
        mov edx,[si+4]
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
SubBase Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SubReal
;
;               DESCRIPTION:    Sub two numbers
;
;               PARAMETERS:             P1      first operand
;                                               P2      second operand
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Sub_P1  EQU 8
Sub_P2  EQU 4

        public SubReal

SubReal Proc near
        push bp
        mov bp,sp
        push ds
        push es
        push ebx
        push si
        push di
;
        lds si,[bp].Sub_P1
        les di,[bp].Sub_P2
        xor eax,eax
        xor edx,edx

sub_test_p1:
        mov ax,[si+8]
        and ax,7FFFh
        jz sub_test_p1_zero
;
        cmp ax,7FFFh
        jne sub_test_p2
;
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
        jmp sub_done

sub_test_p1_zero:
        mov ebx,[si]
        or ebx,[si+4]
        jnz sub_test_p2
;
        mov eax,es:[di]
        mov edx,es:[di+4]
        mov cx,es:[di+8]
        xor ch,80h
        jmp sub_done

sub_test_p2:
        mov dx,es:[di+8]
        and dx,7FFFh
        jz sub_test_p2_zero
;
        cmp dx,7FFFh
        jne sub_do_it
;
        mov eax,es:[di]
        mov edx,es:[di+4]
        mov cx,es:[di+8]
        xor ch,80h
        jmp short sub_done

sub_test_p2_zero:
        mov ebx,es:[di]
        or ebx,es:[di+4]
        jnz sub_do_it
;
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
        jmp sub_done

sub_do_it:
        mov ebx,eax
        sub ebx,edx
        or ebx,ebx
        jnz sub_perform
        mov ebx,[si+4]
        sub ebx,es:[di+4]
        jnz sub_perform
        mov ebx,[si]
        sub ebx,es:[di]
        jnz sub_perform
;
        xor eax,eax
        xor edx,edx
        xor cx,cx
        jmp sub_done

sub_perform:
        mov cl,[si+9]
        xor cl,es:[di+9]
        test cl,80h
        jz sub_same_sign
;
        call AddBase
        push bx
        mov bl,[si+9]
        and bl,80h
        or ch,bl
        pop bx
        jmp sub_done

sub_same_sign:
        shl ebx,1
        pushf
        jnc sub_switch_ok
;
        lds si,[bp].Sub_P2
        les di,[bp].Sub_P1

sub_switch_ok:
        call SubBase
        popf
        push bx
        rcr bh,1
        mov bl,[si+9]
        xor bl,bh
        and bl,80h
        or ch,bl
        pop bx

sub_done:
        pop di
        pop si
        pop ebx
        pop es
        pop ds
        pop bp
        ret 8
SubReal Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   AddReal
;
;               DESCRIPTION:    Add two numbers
;
;               PARAMETERS:             P1      first operand
;                                               P2      second operand
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Add_P1  EQU 8
Add_P2  EQU 4

        public AddReal

AddReal Proc near
        push bp
        mov bp,sp
        push ds
        push es
        push si
        push di
;
        lds si,[bp].Add_P1
        les di,[bp].Add_P2
        mov al,[si+9]
        xor al,es:[di+9]
        test al,80h
        jz add_test_p1
;
        mov al,[si+9]
        test al,80h
        jz add_pn

add_np:
        xor byte ptr [si+9], 80h 
        push es
        push di
        push ds
        push si
        call SubReal
        xor byte ptr [si+9], 80h
        jmp add_done

add_pn:
        xor byte ptr es:[di+9], 80h
        push ds
        push si
        push es
        push di
        call SubReal
        xor byte ptr es:[di+9], 80h
        jmp short add_done

add_test_p1:
        mov ax,[si+8]
        and ax,7FFFh
        jz add_test_p1_zero
;
        cmp ax,7FFFh
        jne add_test_p2
;
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
        jmp add_done

add_test_p1_zero:
        mov eax,[si]
        or eax,[si+4]
        jnz add_test_p2
;
        mov eax,es:[di]
        mov edx,es:[di+4]
        mov cx,es:[di+8]
        jmp add_done

add_test_p2:
        mov ax,es:[di+8]
        and ax,7FFFh
        jz add_test_p2_zero
;
        cmp ax,7FFFh
        jne add_do_it
;
        mov eax,es:[di]
        mov edx,es:[di+4]
        mov cx,es:[di+8]
        jmp add_done

add_test_p2_zero:
        mov eax,es:[di]
        or eax,es:[di+4]
        jnz add_do_it
;
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
        jmp add_done

add_do_it:
        call AddBase
        push bx
        mov bl,[si+9]
        and bl,80h
        or ch,bl
        pop bx

add_done:
        pop di
        pop si
        pop es
        pop ds
        pop bp
        ret 8
AddReal Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   MulReal
;
;               DESCRIPTION:    Multiply two numbers
;
;               PARAMETERS:             P1      first operand
;                                               P2      second operand
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mul_P1  EQU 8
Mul_P2  EQU 4

        public MulReal

MulReal Proc near
        push bp
        mov bp,sp
        push ds
        push es
        push ebx
        push si
        push di
;
        lds si,[bp].Mul_P1
        les di,[bp].Mul_P2
        mov ax,[si+8]
        and ax,7FFFh
        jz mul_test_p1_zero
;
        cmp ax,7FFFh
        jne mul_test_p2
;
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
        jmp mul_done

mul_test_p1_zero:
        mov eax,[si]
        or eax,[si+4]
        jnz mul_test_p2
;
        xor eax,eax
        xor edx,edx
        xor cx,cx
        jmp mul_done

mul_test_p2:
        mov ax,es:[di+8]
        and ax,7FFFh
        jz mul_test_p2_zero
;
        cmp ax,7FFFh
        jne mul_do_it
;
        mov eax,es:[di]
        mov edx,es:[di+4]
        mov cx,es:[di+8]
        jmp mul_done

mul_test_p2_zero:
        mov eax,es:[di]
        or eax,es:[di+4]
        jnz mul_do_it
;
        xor eax,eax
        xor edx,edx
        xor cx,cx
        jmp mul_done

mul_do_it:
        push bp
        xor bp,bp
        mov eax,[si]
        mul dword ptr es:[di+4]
        mov ecx,edx
        mov ebx,eax
        mov eax,[si+4]
        mul dword ptr es:[di]
        add ebx,eax
        adc ecx,edx
        adc bp,0
        mov eax,[si]
        mul dword ptr es:[di]
        add ebx,edx
        adc ecx,0
        adc bp,0
        add ebx,80000000h
        mov ebx,ecx
        adc ebx,0
        movzx ecx,bp
        adc ecx,0
        mov eax,[si+4]
        mul dword ptr es:[di+4]
        add eax,ebx
        adc edx,ecx
        pop bp
;
        mov cx,[si+8]
        and ch,7Fh
        mov bx,es:[di+8]
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
        mov bl,[si+9]
        xor bl,es:[di+9]
        and bl,80h
        or ch,bl

mul_done:
        pop di
        pop si
        pop ebx
        pop es
        pop ds
        pop bp
        ret 8
MulReal Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   DivReal
;
;               DESCRIPTION:    Divide two numbers
;
;               PARAMETERS:             P1      first operand
;                                               P2      second operand
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Div_P1  EQU 8
Div_P2  EQU 4

        public DivReal

DivLow  MACRO bit
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

DivMid  MACRO
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

DivHigh MACRO bit
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

DivReal Proc near
        push bp
        mov bp,sp
        push ds
        push es
        push ebx
        push si
        push di
;
        lds si,[bp].Div_P1
        les di,[bp].Div_P2
        mov ax,[si+8]
        and ax,7FFFh
        jz div_test_p1_zero
;
        cmp ax,7FFFh
        jne div_test_p2
;
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
        jmp div_done

div_test_p1_zero:
        mov eax,[si]
        or eax,[si+4]
        jnz div_test_p2
;
        xor eax,eax
        xor edx,edx
        xor cx,cx
        jmp div_done

div_test_p2:
        mov ax,es:[di+8]
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
        mov eax,es:[di]
        or eax,es:[di+4]
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
        mov eax,[si]
        mov edx,[si+4]
        mov ebx,es:[di]
        mov ecx,es:[di+4]
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
        mov cx,[si+8]
        and ch,7Fh
        mov bx,es:[di+8]
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
        mov bl,[si+9]
        xor bl,es:[di+9]
        and bl,80h
        or ch,bl

div_done:
        pop di
        pop si
        pop ebx
        pop es
        pop ds
        pop bp
        ret 8
DivReal Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   DoubleToReal
;
;               DESCRIPTION:    Convert double to real
;
;               PARAMETERS:             Val             double to convert
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoubleToReal_Val        EQU 4

        public DoubleToReal

DoubleToReal    Proc near
        push bp
        mov bp,sp
        push ds
        push bx
        push si
;
        lds si,[bp].DoubleToReal_Val
        mov eax,[si]
        mov edx,[si+4]
        shl edx,1
        or edx,eax
        jnz double_to_real_non_zero
        xor cx,cx
        xor eax,eax
        xor edx,edx
        jmp double_to_real_done

double_to_real_non_zero:
        mov cx,[si+6]
        and ch,7Fh
        shr cx,4
        add cx,3FFFh - 3FFh
        mov edx,[si+4]
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
        mov bl,[si+7]
        and bl,80h
        or ch,bl

double_to_real_done:
        pop si
        pop bx
        pop ds
        pop bp
        ret 4
DoubleToReal    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   FloatToReal
;
;               DESCRIPTION:    Convert float to real
;
;               PARAMETERS:             Val             float to convert
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FloatToReal_Val EQU 4

        public FloatToReal

FloatToReal     Proc near
        push bp
        mov bp,sp
        push ds
        push bx
        push si
;
        lds si,[bp].FloatToReal_Val
        mov eax,[si]
        shl eax,1
        jnz float_to_real_non_zero
        xor cx,cx
        xor eax,eax
        xor edx,edx
        jmp float_to_real_done

float_to_real_non_zero:
        mov cx,[si+2]
        and ch,7Fh
        shr cx,7
        add cx,3FFFh - 7Fh
        mov edx,[si]
        shl edx,9
        stc
        rcr edx,1
        xor eax,eax
;
        mov bl,[si+3]
        and bl,80h
        or ch,bl

float_to_real_done:
        pop si
        pop bx
        pop ds
        pop bp
        ret 4
FloatToReal     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   QwordToReal
;
;               DESCRIPTION:    Convert 8-byte int to real
;
;               PARAMETERS:             Val             qword to convert
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QwordToReal_Val EQU 4

        public QwordToReal

QwordToReal     Proc near
        push bp
        mov bp,sp
        push ds
        push bx
        push si
;
        lds si,[bp].QwordToReal_Val
        mov eax,[si]
        or eax,[si+4]
        jnz qword_to_real_non_zero
        xor cx,cx
        xor eax,eax
        xor edx,edx
        jmp qword_to_real_done

qword_to_real_non_zero:
        mov eax,[si]
        mov edx,[si+4]
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
        pop si
        pop bx
        pop ds
        pop bp
        ret 4
QwordToReal     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   LongToReal
;
;               DESCRIPTION:    Convert long to real
;
;               PARAMETERS:             Val             long to convert
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LongToReal_Val  EQU 4

        public LongToReal

LongToReal      Proc near
        push bp
        mov bp,sp
        push ds
        push si
;
        lds si,[bp].LongToReal_Val
        mov edx,[si]
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
        pop si
        pop ds
        pop bp
        ret 4
LongToReal      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   IntToReal
;
;               DESCRIPTION:    Convert int to real
;
;               PARAMETERS:             Val             int to convert
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IntToReal_Val   EQU 4

        public IntToReal

IntToReal       Proc near
        push bp
        mov bp,sp
        push ds
        push si
;
        lds si,[bp].IntToReal_Val
        mov dx,[si]
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
        pop si
        pop ds
        pop bp
        ret 4
IntToReal       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   BcdToReal
;
;               DESCRIPTION:    Convert 18 digit bcd to real
;
;               PARAMETERS:             Val             bcd string to convert
;
;               RETURNS:                CX              exponent
;                                               EDX:EAX mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BcdToReal_Val   EQU 4

        public BcdToReal

BcdToReal       Proc near
        push bp
        mov bp,sp
        push ds
        push si
;
        lds si,[bp].BcdToReal_Val
        xor edx,edx
        xor eax,eax
        add si,8
        stc
        mov cx,18
        pushf

bcd_to_real_loop:
        push cx
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
        pop cx
        popf
        jc bcd_to_real_high
;
        mov bl,[si]
        and bl,0Fh
        movzx ebx,bl
        add eax,ebx
        adc edx,0
        dec si
        stc
        jmp bcd_to_real_next

bcd_to_real_high:
        mov bl,[si]
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
        mov si,[ebp].BcdToReal_Val
        test byte ptr [si+9],80h
        jz bcd_to_real_conv
;
        not eax
        not edx
        add eax,1
        adc edx,0

bcd_to_real_conv:
        push edx
        push eax
        mov bp,sp
        push ss
        push bp
        call QwordToReal
        add sp,8

bcd_to_real_done:
        pop si
        pop ds
        pop bp
        ret 4
BcdToReal       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RealToDouble
;
;               DESCRIPTION:    Convert real to double
;
;               PARAMETERS:             Val             real to convert
;
;               RETURNS:                EDX:EAX returned double
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToDouble_Val        EQU 4

        public RealToDouble

RealToDouble    Proc near
        push bp
        mov bp,sp
        push ds
        push ecx
        push si
;
        lds si,[bp].RealToDouble_Val
        mov eax,[si]
        shr eax,11
        mov edx,[si+4]
        and edx,7FFh
        ror edx,11
        or eax,edx
        mov edx,[si+4]
        mov cx,[si+8]
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
        mov ch,[si+9]
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
        pop si
        pop ecx
        pop ds
        pop bp
        ret 4
RealToDouble    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RealToFloat
;
;               DESCRIPTION:    Convert real to float
;
;               PARAMETERS:             Val             real to convert
;
;               RETURNS:                EAX     returned float
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToFloat_Val EQU 4

        public RealToFloat

RealToFloat     Proc near
        push bp
        mov bp,sp
        push ds
        push ecx
        push si
;
        lds si,[bp].RealToFloat_Val
        mov cx,[si+8]
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
        mov eax,[si+4]
        shl eax,1
        shr eax,9
        or eax,ecx
        shl eax,1
        mov ch,[si+9]
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
        pop si
        pop ecx
        pop ds
        pop bp
        ret 4
RealToFloat     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RealToQword
;
;               DESCRIPTION:    Convert real to 8-byte int
;                                               Mode    rounding mode
;
;               PARAMETERS:             Val             real to round
;
;               RETURNS:                EDX:EAX 8-byte int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToQword_Val         EQU 6
RealToQword_mode        EQU 4

        public RealToQword

RealToQword     Proc near
        push bp
        mov bp,sp
        push ds
        push cx
        push si
;
        lds si,[bp].RealToQword_Val
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
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
        jmp short real_to_qword_done

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
        mov cl,[bp+1].RealToQword_mode
        and cl,RC_MASK shr 8
        jmp real_to_qword_round_updown

real_to_qword_check_half_or_more:
        mov cl,[bp+1].RealToQword_mode
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
        test byte ptr [si+9],80h
        jnz real_to_qword_rounded
        jmp real_to_qword_round_up
 
real_to_qword_down:
        test byte ptr [si+9],80h
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
        mov cl,[si+9]
        test cl,80h
        clc
        jz real_to_qword_done
        not eax
        not edx
        add eax,1
        adc edx,0
        clc

real_to_qword_done:
        pop si
        pop cx
        pop ds
        pop bp
        ret 6
RealToQword     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RealToLong
;
;               DESCRIPTION:    Convert real to long
;
;               PARAMETERS:             Val             real to round
;                                               Mode    rounding mode
;
;               RETURNS:                EAX     long
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToLong_Val  EQU 6
RealToLong_mode EQU 4

        public RealToLong

RealToLong      Proc near
        push bp
        mov bp,sp
        push ds
        push cx
        push si
;
        lds si,[bp].RealToLong_Val
        mov eax,[si+4]
        mov cx,[si+8]
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
        jmp short real_to_long_done

real_to_long_valid:
        mov ch,[si]
        or ch,[si+1]
        or ch,[si+2]
        or ch,[si+3]
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
        mov cl,[bp+1].RealToLong_mode
        and cl,RC_MASK shr 8
        jmp real_to_long_round_updown

real_to_long_check_half_or_more:
        mov cl,[bp+1].RealToLong_mode
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
        test byte ptr [si+9],80h
        jnz real_to_long_rounded
        jmp real_to_long_round_up
 
real_to_long_down:
        test byte ptr [si+9],80h
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
        mov cl,[si+9]
        test cl,80h
        clc
        jz real_to_long_done
        neg eax
        clc

real_to_long_done:
        pop si
        pop cx
        pop ds
        pop bp
        ret 6
RealToLong      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RealToInt
;
;               DESCRIPTION:    Convert real to int
;
;               PARAMETERS:             Val             real to round
;                                               Mode    rounding mode
;
;               RETURNS:                AX      int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToInt_Val   EQU 6
RealToInt_mode  EQU 4

        public RealToInt

RealToInt       Proc near
        push bp
        mov bp,sp
        push ds
        push cx
        push si
;
        lds si,[bp].RealToInt_Val
        mov ax,[si+6]
        mov cx,[si+8]
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
        jmp short real_to_int_done

real_to_int_valid:
        mov ch,[si]
        or ch,[si+1]
        or ch,[si+2]
        or ch,[si+3]
        or ch,[si+4]
        or ch,[si+5]
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
        mov cl,[bp+1].RealToInt_mode
        and cl,RC_MASK shr 8
        jmp real_to_int_round_updown

real_to_int_check_half_or_more:
        mov cl,[bp+1].RealToInt_mode
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
        test byte ptr [si+9],80h
        jnz real_to_int_rounded
        jmp real_to_int_round_up
 
real_to_int_down:
        test byte ptr [si+9],80h
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
        mov cl,[si+9]
        test cl,80h
        clc
        jz real_to_int_done
        neg ax
        clc

real_to_int_done:
        pop si
        pop cx
        pop ds
        pop bp
        ret 6
RealToInt       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RealToBcd
;
;               DESCRIPTION:    Convert real to 10-byte bcd string
;
;               PARAMETERS:             Val             real to round
;                                               Result  bcd string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RealToBcd_Val           EQU 8
RealToBcd_Result        EQU 4

        public RealToBcd

BcdTab:
bcd18   DQ 1000000000000000000

bcd17   DQ 100000000000000000
bcd16   DQ 10000000000000000
bcd15   DQ 1000000000000000
bcd14   DQ 100000000000000
bcd13   DQ 10000000000000
bcd12   DQ 1000000000000
bcd11   DQ 100000000000
bcd10   DQ 10000000000
bcd9    DQ 1000000000
bcd8    DQ 100000000

bcd7    DD 10000000
bcd6    DD 1000000
bcd5    DD 100000
bcd4    DD 10000
bcd3    DD 1000
bcd2    DD 100
bcd1    DD 10
bcd0    DD 1

RealToBcd       Proc near
        push bp
        mov bp,sp
        push ds
        push es
        push eax
        push bx
        push cx
        push edx
        push si
        push di
;
        lds si,[bp].RealToBcd_Val
        les di,[bp].RealToBcd_Result
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
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
        mov cx,10
        rep stosb
        stc
        jmp real_to_bcd_done
        
real_to_bcd_underflow:
        cmp cx,-1
        jne real_to_bcd_zero
;
        mov al,[si+7]
        shr al,7
        movzx eax,al
        xor edx,edx
        jmp real_to_bcd_output

real_to_bcd_zero:
        xor al,al
        mov cx,10
        rep stosb
        jmp real_to_bcd_done

real_to_bcd_output:
        mov bx,OFFSET BcdTab
        sub eax,cs:[bx]
        sbb edx,cs:[bx+4]
        jnc real_to_bcd_overflow
;
        push ax
        mov cx,10
        xor al,al
        rep stosb
        pop ax
        dec edi
;
        mov cx,5
real_to_bcd8_loop:
        add eax,cs:[bx]
        adc edx,cs:[bx+4]
        add bx,8
        dec di
real_to_bcd8_high_loop:
        sub eax,cs:[bx]
        sbb edx,cs:[bx+4]
        jc real_to_bcd8_high_found
        add byte ptr es:[di],10h
        jmp real_to_bcd8_high_loop

real_to_bcd8_high_found:
        add eax,cs:[bx]
        adc edx,cs:[bx+4]
;
        add bx,8
real_to_bcd8_low_loop:
        sub eax,cs:[bx]
        sbb edx,cs:[bx+4]
        jc real_to_bcd8_low_found
        inc byte ptr es:[di]
        jmp real_to_bcd8_low_loop

real_to_bcd8_low_found:
        loop real_to_bcd8_loop
;
        add eax,cs:[bx]
        add bx,4
        mov cx,4
real_to_bcd4_loop:
        add eax,cs:[bx]
        add bx,4
        dec di
real_to_bcd4_high_loop:
        sub eax,cs:[bx]
        jc real_to_bcd4_high_found
        add byte ptr es:[di],10h
        jmp real_to_bcd4_high_loop

real_to_bcd4_high_found:
        add eax,cs:[bx]
;
        add bx,4
real_to_bcd4_low_loop:
        sub eax,cs:[bx]
        jc real_to_bcd4_low_found
        inc byte ptr es:[di]
        jmp real_to_bcd4_low_loop

real_to_bcd4_low_found:
        loop real_to_bcd4_loop

real_to_bcd_sign:
        mov cl,[si+9]
        test cl,80h
        clc
        jz real_to_bcd_done
;
        mov di,[bp].RealToBcd_Result
        mov byte ptr es:[di+9],80h
        clc

real_to_bcd_done:
        pop si
        pop di
        pop edx
        pop cx
        pop bx
        pop eax
        pop es
        pop ds
        pop bp
        ret 8
RealToBcd       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CalcExp2M1
;
;               DESCRIPTION:    2^X - 1
;
;               PARAMETERS:             Val             real
;
;               RETURNS:                CX              Exponnent
;                                               EDX:EAX Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcExp2M1_Par  EQU 4 
CalcExp2M1_xloga        EQU -10
CalcExp2M1_val  EQU -20
CalcExp2M1_rv           EQU -30
CalcExp2M1_tmp  EQU -40

        public CalcExp2M1

CalcExp2M1      Proc near
        push bp
        mov bp,sp
        sub sp,40
        push si
;
        push dword ptr [bp].CalcExp2M1_Par
        push cs
        push OFFSET ConstLn2
        call MulReal
;
        mov [bp].CalcExp2M1_xloga,eax
        mov [bp+4].CalcExp2M1_xloga,edx
        mov [bp+8].CalcExp2M1_xloga,cx
;
        mov [bp].CalcExp2M1_val,eax
        mov [bp+4].CalcExp2M1_val,edx
        mov [bp+8].CalcExp2M1_val,cx
;
        mov [bp].CalcExp2M1_rv,eax
        mov [bp+4].CalcExp2M1_rv,edx
        mov [bp+8].CalcExp2M1_rv,cx
;               
        mov cx,14
        mov si,OFFSET Const2
calc_exp2m1_loop:
        push cx
;
        push ss
        lea ax,[bp].CalcExp2M1_val
        push ax
        push ss
        lea ax,[bp].CalcExp2M1_xloga
        push ax
        call MulReal            
        mov [bp].CalcExp2M1_tmp,eax
        mov [bp+4].CalcExp2M1_tmp,edx
        mov [bp+8].CalcExp2M1_tmp,cx
;
        push ss
        lea ax,[bp].CalcExp2M1_tmp
        push ax
        push cs
        push si
        call DivReal
        mov [bp].CalcExp2M1_val,eax
        mov [bp+4].CalcExp2M1_val,edx
        mov [bp+8].CalcExp2M1_val,cx
;
        push ss
        lea ax,[bp].CalcExp2M1_val
        push ax
        push ss
        lea ax,[bp].CalcExp2M1_rv
        push ax
        call AddReal
        mov [bp].CalcExp2M1_rv,eax
        mov [bp+4].CalcExp2M1_rv,edx
        mov [bp+8].CalcExp2M1_rv,cx
;
        pop cx
        add si,10
        loop calc_exp2m1_loop
;
        mov cx,[bp+8].CalcExp2M1_rv
;
        pop si
        add sp,40
        pop bp
        ret 4
CalcExp2M1      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CalcLog2
;
;               DESCRIPTION:    log2(x)
;
;               PARAMETERS:             x
;
;               RETURNS:                CX              Exponnent
;                                               EDX:EAX Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcLog2_x              EQU 4
CalcLog2_z              EQU -10
CalcLog2_nom    EQU -20
CalcLog2_denom  EQU -30
CalcLog2_x1             EQU -40
CalcLog2_x2             EQU -50
CalcLog2_pow    EQU -60
CalcLog2_sum    EQU -70

        public CalcLog2

CalcLog2        Proc near
        push bp
        mov bp,sp
        sub sp,70
        push ds
        push si
        push edi
;
        lds si,[bp].CalcLog2_x
        mov eax,[si]
        or eax,[si+4]
        jz calc_log2_invalid
;
        mov al,[si+9]
        and al,80h
        jz calc_log2_valid

calc_log2_invalid:
        mov edx,80000000h
        xor eax,eax
        mov cx,7FFFh
        jmp calc_log2_done

calc_log2_valid:
        mov eax,[si]
        mov [bp].CalcLog2_z,eax
        mov eax,[si+4]
        mov [bp+4].CalcLog2_z,eax
        mov word ptr [bp+8].CalcLog2_z,3FFFh
        mov di,[si+8]
        movzx edi,di
        sub edi,3FFFh
;
        push ss
        lea ax,[bp].CalcLog2_z
        push ax
        push cs
        push OFFSET ConstSqrt2
        call CmpReal
        cmp ax,COMP_A_GT_B
        jne calc_log2_exp_ok
        dec word ptr [bp+8].CalcLog2_z
        inc edi

calc_log2_exp_ok:
        push ss
        lea ax,[bp].CalcLog2_z
        push ax
        push cs
        push OFFSET Const1
        call SubReal
        mov [bp].CalcLog2_nom,eax
        mov [bp+4].CalcLog2_nom,edx
        mov [bp+8].CalcLog2_nom,cx
;
        push ss
        lea ax,[bp].CalcLog2_z
        push ax
        push cs
        push OFFSET Const1
        call AddReal
        mov [bp].CalcLog2_denom,eax
        mov [bp+4].CalcLog2_denom,edx
        mov [bp+8].CalcLog2_denom,cx
;
        push ss
        lea ax,[bp].CalcLog2_nom
        push ax
        push ss
        lea ax,[bp].CalcLog2_denom
        push ax
        call DivReal
        mov [bp].CalcLog2_x1,eax
        mov [bp+4].CalcLog2_x1,edx
        mov [bp+8].CalcLog2_x1,cx
;
        mov [bp].CalcLog2_pow,eax
        mov [bp+4].CalcLog2_pow,edx
        mov [bp+8].CalcLog2_pow,cx
;
        mov [bp].CalcLog2_sum,eax
        mov [bp+4].CalcLog2_sum,edx
        mov [bp+8].CalcLog2_sum,cx
;
        lea ax,[bp].CalcLog2_x1
        push ss
        push ax
        push ss
        push ax
        call MulReal
        mov [bp].CalcLog2_x2,eax
        mov [bp+4].CalcLog2_x2,edx
        mov [bp+8].CalcLog2_x2,cx
;
        mov si,OFFSET Const3
        mov cx,11
calc_log2_loop:
        push cx
;
        push ss
        lea ax,[bp].CalcLog2_pow
        push ax
        push ss
        lea ax,[bp].CalcLog2_x2
        push ax
        call MulReal
        mov [bp].CalcLog2_pow,eax
        mov [bp+4].CalcLog2_pow,edx
        mov [bp+8].CalcLog2_pow,cx
;
        push ss
        lea ax,[bp].CalcLog2_pow
        push ax
        push cs
        push si
        call DivReal
        mov [bp].CalcLog2_denom,eax
        mov [bp+4].CalcLog2_denom,edx
        mov [bp+8].CalcLog2_denom,cx
;
        push ss
        lea ax,[bp].CalcLog2_denom
        push ax
        push ss
        lea ax,[bp].CalcLog2_sum
        push ax
        call AddReal
        mov [bp].CalcLog2_sum,eax
        mov [bp+4].CalcLog2_sum,edx
        mov [bp+8].CalcLog2_sum,cx
;
        add si,20
        pop cx
        loop calc_log2_loop
;
        push ss
        lea ax,[bp].CalcLog2_sum
        push ax
        push cs
        push OFFSET ConstLn2
        call DivReal
        inc cx
        or edi,edi
        jz calc_log2_done
;
        mov [bp].CalcLog2_sum,eax
        mov [bp+4].CalcLog2_sum,edx
        mov [bp+8].CalcLog2_sum,cx
;
        push edi
        mov ax,sp
        push ss
        push ax
        call LongToReal
        add sp,4
        mov [bp].CalcLog2_denom,eax
        mov [bp+4].CalcLog2_denom,edx
        mov [bp+8].CalcLog2_denom,cx
;
        push ss
        lea ax,[bp].CalcLog2_sum
        push ax
        push ss
        lea ax,[bp].CalcLog2_denom
        push ax
        call AddReal

calc_log2_done:
        pop edi
        pop si
        pop ds
        add sp,70
        pop bp
        ret 4
CalcLog2        Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CalcSqrt
;
;               DESCRIPTION:    square root
;
;               PARAMETERS:             x
;
;               RETURNS:                CX              Exponnent
;                                               EDX:EAX Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcSqrt_x              EQU 4
CalcSqrt_side   EQU -8
CalcSqrt_left   EQU -16 
CalcSqrt_result EQU -24

        public CalcSqrt

CalcSqrt        Proc near
        push bp
        mov bp,sp
        sub sp,24
        push ds
        push esi
        push edi
;
        lds si,[bp].CalcSqrt_x
        mov eax,[si]
        or eax,[si+4]
        jz calc_sqrt_ret
        mov ax,[si+8]
        test ah,80h
        jnz calc_sqrt_illegal
        and ah,7Fh
        cmp ax,7FFFh
        jne calc_sqrt_start

calc_sqrt_ret:
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
        jmp calc_sqrt_done

calc_sqrt_illegal:
        mov edx,80000000h
        xor eax,eax
        mov cx,7FFFh
        jmp calc_sqrt_done

calc_sqrt_start:
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
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
        mov dword ptr [bp].CalcSqrt_side,0
        mov dword ptr [bp+4].CalcSqrt_side,0
        mov dword ptr [bp].CalcSqrt_left,0
        mov dword ptr [bp+4].CalcSqrt_left,0
        mov dword ptr [bp].CalcSqrt_result,0
        mov dword ptr [bp+4].CalcSqrt_result,0

calc_sqrt_loop:
        inc cx
        shl eax,1
        rcl edx,1
        rcl dword ptr [bp].CalcSqrt_left,1
        rcl dword ptr [bp+4].CalcSqrt_left,1
        shl eax,1
        rcl edx,1
        rcl dword ptr [bp].CalcSqrt_left,1
        rcl dword ptr [bp+4].CalcSqrt_left,1
;
        mov esi,[bp].CalcSqrt_side
        mov edi,[bp+4].CalcSqrt_side
        shl esi,1
        rcl edi,1
        add esi,1
        adc edi,0
        sub [bp].CalcSqrt_left,esi
        sbb [bp+4].CalcSqrt_left,edi
        jc calc_sqrt_ge
;
        add dword ptr [bp].CalcSqrt_side,1
        adc dword ptr [bp+4].CalcSqrt_side,0
        shl dword ptr [bp].CalcSqrt_side,1
        rcl dword ptr [bp+4].CalcSqrt_side,1
        stc
        jmp calc_sqrt_next

calc_sqrt_ge:
        add [bp].CalcSqrt_left,esi
        adc [bp+4].CalcSqrt_left,edi
        shl dword ptr [bp].CalcSqrt_side,1
        rcl dword ptr [bp+4].CalcSqrt_side,1
        clc

calc_sqrt_next:
        rcl dword ptr [bp].CalcSqrt_result,1
        rcl dword ptr [bp+4].CalcSqrt_result,1
        jnc calc_sqrt_loop
;
        add cx,3FFFh - 1
        mov eax,[bp].CalcSqrt_result
        mov edx,[bp+4].CalcSqrt_result
        stc
        rcr edx,1
        rcr eax,1
        
calc_sqrt_done:
        pop edi
        pop esi
        pop ds
        add sp,24
        pop bp
        ret 4
CalcSqrt        Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CalcPartialRemainder
;
;               DESCRIPTION:    partial remainder of x / y
;
;               PARAMETERS:             x               first parameter
;                                               y               second parameter
;                                               mode    rounding mode
;
;               RETURNS:                CX              Exponnent
;                                               EDX:EAX Mantissa
;                                               EBX             Quot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcPRem_x              EQU 10
CalcPRem_y              EQU 6
CalcPRem_mode   EQU 4
CalcPRem_tmp    EQU -10

        public CalcPartialRemainder

CalcPartialRemainder    Proc near
        push bp
        mov bp,sp
        sub sp,10
        push ds
        push es
        push si
        push di
;
        lds si,[bp].CalcPRem_x
        les di,[bp].CalcPRem_y
        mov ax,[si+8]
        and ax,7FFFh
        mov dx,es:[di+8]
        and dx,7FFFh
        sub ax,dx
        jc calc_prem_small
        cmp ax,64
        jnc calc_prem_big       

calc_prem_small:
        push ds
        push si
        push es
        push di
        call DivReal
        mov [bp].CalcPRem_tmp,eax
        mov [bp+4].CalcPRem_tmp,edx
        mov [bp+8].CalcPRem_tmp,cx
;
        push ss
        lea ax,[bp].CalcPRem_tmp
        push ax
        push word ptr [bp].CalcPRem_mode
        call RealToQword
        mov ebx,eax
        mov [bp].CalcPRem_tmp,eax
        mov [bp+4].CalcPRem_tmp,edx
;
        push ss
        lea ax,[bp].CalcPRem_tmp
        push ax
        call QwordToReal
        mov [bp].CalcPRem_tmp,eax
        mov [bp+4].CalcPRem_tmp,edx
        mov [bp+8].CalcPRem_tmp,cx
;
        push ss
        lea ax,[bp].CalcPRem_tmp
        push ax
        push es
        push di
        call MulReal
        mov [bp].CalcPRem_tmp,eax
        mov [bp+4].CalcPRem_tmp,edx
        mov [bp+8].CalcPRem_tmp,cx
;
        push ds
        push si
        push ss
        lea ax,[bp].CalcPRem_tmp
        push ax
        call SubReal
;
        lds si,[bp].CalcPRem_y
        mov si,[si+8]
        and si,8000h
        and cx,7FFFh
        or cx,si
        jmp calc_prem_done

calc_prem_big:
        push ds
        push si
        push es
        push di
        call DivReal
        mov bx,cx
        and cx,803Fh
        mov [bp].CalcPRem_tmp,eax
        mov [bp+4].CalcPRem_tmp,edx
        mov [bp+8].CalcPRem_tmp,cx
;
        push ss
        lea ax,[bp].CalcPRem_tmp
        push ax
        push word ptr [bp].CalcPRem_mode
        call RealToQword
        mov [bp].CalcPRem_tmp,eax
        mov [bp+4].CalcPRem_tmp,edx
;
        push ss
        lea ax,[bp].CalcPRem_tmp
        push ax
        call QwordToReal
        mov cx,bx
        mov [bp].CalcPRem_tmp,eax
        mov [bp+4].CalcPRem_tmp,edx
        mov [bp+8].CalcPRem_tmp,cx
;
        push ss
        lea ax,[bp].CalcPRem_tmp
        push ax
        push es
        push di
        call MulReal
        mov [bp].CalcPRem_tmp,eax
        mov [bp+4].CalcPRem_tmp,edx
        mov [bp+8].CalcPRem_tmp,cx
;
        push ds
        push si
        push ss
        lea ax,[bp].CalcPRem_tmp
        push ax
        call SubReal
        mov ebx,-1

calc_prem_done:
        pop di
        pop si
        pop es
        pop ds
        add sp,10
        pop bp
        ret 10
CalcPartialRemainder    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CalcSin
;
;               DESCRIPTION:    sin(x)
;
;               PARAMETERS:             x               argument
;
;               RETURNS:                CX              Exponnent
;                                               EDX:EAX Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcSin_x               EQU 4
CalcSin_tmp             EQU -10
CalcSin_val             EQU -20
CalcSin_x2              EQU -30
CalcSin_rv              EQU -40

        public CalcSin

CalcSin Proc near
        push bp
        mov bp,sp
        sub sp,40
        push ebx
        push esi
;
        push dword ptr [bp].CalcSin_x
        push cs
        push OFFSET ConstPi2
        push RC_CHOP
        call CalcPartialRemainder
        test bl,1
        jz calc_sin_calc
;
        mov [bp].CalcSin_tmp,eax
        mov [bp+4].CalcSin_tmp,edx
        mov [bp+8].CalcSin_tmp,cx
        push cs
        push OFFSET ConstPi2
        push ss
        lea ax,[bp].CalcSin_tmp
        push ax
        call SubReal

calc_sin_calc:
        mov [bp].CalcSin_val,eax
        mov [bp+4].CalcSin_val,edx
        mov [bp+8].CalcSin_val,cx
;
        mov [bp].CalcSin_rv,eax
        mov [bp+4].CalcSin_rv,edx
        mov [bp+8].CalcSin_rv,cx
;
        lea ax,[bp].CalcSin_val
        push ss
        push ax
        push ss
        push ax
        call MulReal
        mov [bp].CalcSin_x2,eax
        mov [bp+4].CalcSin_x2,edx
        mov [bp+8].CalcSin_x2,cx
;
        xor esi,esi
calc_sin_loop:
        xor byte ptr [bp+9].CalcSin_val,80h
;
        push ss
        lea ax,[bp].CalcSin_val
        push ax
        push ss
        lea ax,[bp].CalcSin_x2
        push ax
        call MulReal
        mov [bp].CalcSin_val,eax
        mov [bp+4].CalcSin_val,edx
        mov [bp+8].CalcSin_val,cx
;
        mov eax,esi
        shl eax,1
        add eax,2
        mov edx,eax
        inc eax
        mul edx
        mov [bp].CalcSin_tmp,eax
;
        push ss
        lea ax,[bp].CalcSin_tmp
        push ax
        call LongToReal
        mov [bp].CalcSin_tmp,eax
        mov [bp+4].CalcSin_tmp,edx
        mov [bp+8].CalcSin_tmp,cx
;
        push ss
        lea ax,[bp].CalcSin_val
        push ax
        push ss
        lea ax,[bp].CalcSin_tmp
        push ax
        call DivReal
        mov [bp].CalcSin_val,eax
        mov [bp+4].CalcSin_val,edx
        mov [bp+8].CalcSin_val,cx
;
        push ss
        lea ax,[bp].CalcSin_val
        push ax
        push ss
        lea ax,[bp].CalcSin_rv
        push ax
        call AddReal
        mov [bp].CalcSin_rv,eax
        mov [bp+4].CalcSin_rv,edx
        mov [bp+8].CalcSin_rv,cx
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
        add sp,40
        pop bp
        ret 4
CalcSin Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CalcCos
;
;               DESCRIPTION:    cos(x)
;
;               PARAMETERS:             x               argument
;
;               RETURNS:                CX              Exponnent
;                                               EDX:EAX Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcCos_x               EQU 4
CalcCos_tmp             EQU -10
CalcCos_val             EQU -20
CalcCos_x2              EQU -30
CalcCos_rv              EQU -40

        public CalcCos

CalcCos Proc near
        push bp
        mov bp,sp
        sub sp,40
        push ebx
        push esi
;
        push dword ptr [bp].CalcCos_x
        push cs
        push OFFSET ConstPi2
        push RC_CHOP
        call CalcPartialRemainder
        test bl,1
        jz calc_cos_calc
;
        mov [bp].CalcCos_tmp,eax
        mov [bp+4].CalcCos_tmp,edx
        mov [bp+8].CalcCos_tmp,cx
        push cs
        push OFFSET ConstPi2
        push ss
        lea ax,[bp].CalcCos_tmp
        push ax
        call SubReal

calc_cos_calc:
        mov [bp].CalcCos_val,eax
        mov [bp+4].CalcCos_val,edx
        mov [bp+8].CalcCos_val,cx
;
        lea ax,[bp].CalcCos_val
        push ss
        push ax
        push ss
        push ax
        call MulReal
        mov [bp].CalcCos_x2,eax
        mov [bp+4].CalcCos_x2,edx
        mov [bp+8].CalcCos_x2,cx
;
        mov si,OFFSET Const1
        mov eax,cs:[si]
        mov edx,cs:[si+4]
        mov cx,cs:[si+8]
;
        mov [bp].CalcCos_rv,eax
        mov [bp+4].CalcCos_rv,edx
        mov [bp+8].CalcCos_rv,cx
;
        mov [bp].CalcCos_val,eax
        mov [bp+4].CalcCos_val,edx
        mov [bp+8].CalcCos_val,cx
;
        xor esi,esi
calc_cos_loop:
        xor byte ptr [bp+9].CalcCos_val,80h
;
        push ss
        lea ax,[bp].CalcCos_val
        push ax
        push ss
        lea ax,[bp].CalcCos_x2
        push ax
        call MulReal
        mov [bp].CalcCos_val,eax
        mov [bp+4].CalcCos_val,edx
        mov [bp+8].CalcCos_val,cx
;
        mov eax,esi
        shl eax,1
        inc eax
        mov edx,eax
        inc eax
        mul edx
        mov [bp].CalcCos_tmp,eax
;
        push ss
        lea ax,[bp].CalcCos_tmp
        push ax
        call LongToReal
        mov [bp].CalcCos_tmp,eax
        mov [bp+4].CalcCos_tmp,edx
        mov [bp+8].CalcCos_tmp,cx
;
        push ss
        lea ax,[bp].CalcCos_val
        push ax
        push ss
        lea ax,[bp].CalcCos_tmp
        push ax
        call DivReal
        mov [bp].CalcCos_val,eax
        mov [bp+4].CalcCos_val,edx
        mov [bp+8].CalcCos_val,cx
;
        push ss
        lea ax,[bp].CalcCos_val
        push ax
        push ss
        lea ax,[bp].CalcCos_rv
        push ax
        call AddReal
        mov [bp].CalcCos_rv,eax
        mov [bp+4].CalcCos_rv,edx
        mov [bp+8].CalcCos_rv,cx
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
        add sp,40
        pop bp
        ret 4
CalcCos Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CalcTan
;
;               DESCRIPTION:    tan(x)
;
;               PARAMETERS:             x               argument
;
;               RETURNS:                CX              Exponnent
;                                               EDX:EAX Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcTan_x               EQU 4
CalcTan_sin             EQU -10
CalcTan_cos             EQU -20

CalcTan Proc near
        push bp
        mov bp,sp
        sub sp,20
;
        push dword ptr [bp].CalcTan_x
        call CalcSin
        mov [bp].CalcTan_sin,eax
        mov [bp+4].CalcTan_sin,edx
        mov [bp+8].CalcTan_sin,cx
;
        push dword ptr [bp].CalcTan_x
        call CalcCos
        mov [bp].CalcTan_cos,eax
        mov [bp+4].CalcTan_cos,edx
        mov [bp+8].CalcTan_cos,cx
;
        push ss
        lea ax,[bp].CalcTan_sin
        push ax
        push ss
        lea ax,[bp].CalcTan_cos
        push ax
        call DivReal
;
        add sp,20
        pop bp
        ret 4
CalcTan Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CalcAtan
;
;               DESCRIPTION:    atan(y/x)
;
;               PARAMETERS:             x               argument
;                                               y               argument
;
;               RETURNS:                CX              Exponnent
;                                               EDX:EAX Mantissa
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcAtan_x              EQU 8
CalcAtan_y              EQU 4
CalcAtan_sum    EQU -10
CalcAtan_pow    EQU -20
CalcAtan_x2             EQU -30
CalcAtan_tmp    EQU -40

        public CalcAtan

CalcAtan        Proc near
        push bp
        mov bp,sp
        sub sp,40
        push ds
        push es
        push si
        push di
;
        lds si,[bp].CalcAtan_x
        les di,[bp].CalcAtan_y
        mov eax,[si]
        or eax,[si+4]
        jnz calc_atan_x_nonzero
;
        mov si,OFFSET ConstPi2
        mov eax,cs:[si]
        mov edx,cs:[si+4]
        mov cx,es:[di+8]
        and cx,8000h
        or cx,cs:[si+8]
        jmp calc_atan_done

calc_atan_x_nonzero:
        mov eax,es:[di]
        or eax,es:[di+4]
        jnz calc_atan_normal
;
        mov cl,[si+9]
        test cl,80h
        jz calc_atan_pos_a
        mov si,OFFSET ConstPi
        mov eax,cs:[si]
        mov edx,cs:[si+4]
        mov cx,cs:[si+8]
        jmp calc_atan_done

calc_atan_pos_a:
        xor eax,eax
        xor edx,edx
        xor cx,cx
        jmp calc_atan_done

calc_atan_normal:
        xor bl,bl
        test byte ptr es:[di+9],80h
        jz calc_atan_not_quad1
        or bl,1
calc_atan_not_quad1:
        test byte ptr [si+9],80h
        jz calc_atan_not_quad2
        or bl,2
calc_atan_not_quad2:
        mov eax,[si]
        mov edx,[si+4]
        mov cx,[si+8]
        and cx,7FFFh
;
        mov [bp].CalcAtan_sum,eax
        mov [bp+4].CalcAtan_sum,edx
        mov [bp+8].CalcAtan_sum,cx
;       
        mov eax,es:[di]
        mov edx,es:[di+4]
        mov cx,es:[di+8]
        and cx,7FFFh
;
        mov [bp].CalcAtan_pow,eax
        mov [bp+4].CalcAtan_pow,edx
        mov [bp+8].CalcAtan_pow,cx
;
        push ss
        lea ax,[bp].CalcAtan_pow
        push ax
        push ss
        lea ax,[bp].CalcAtan_sum
        push ax
        call CmpReal
        cmp ax,COMP_A_GT_B
        jne calc_atan_not_quad4
;
        or bl,4
        mov eax,[bp].CalcAtan_sum
        xchg eax,[bp].CalcAtan_pow
        mov [bp].CalcAtan_sum,eax
        mov eax,[bp+4].CalcAtan_sum
        xchg eax,[bp+4].CalcAtan_pow
        mov [bp+4].CalcAtan_sum,eax
        mov ax,[bp+8].CalcAtan_sum
        xchg ax,[bp+8].CalcAtan_pow
        mov [bp+8].CalcAtan_sum,ax
calc_atan_not_quad4:
        push ss
        lea ax,[bp].CalcAtan_pow
        push ax
        push ss
        lea ax,[bp].CalcAtan_sum
        push ax
        call DivReal
        mov [bp].CalcAtan_sum,eax
        mov [bp+4].CalcAtan_sum,edx
        mov [bp+8].CalcAtan_sum,cx
        mov [bp].CalcAtan_pow,eax
        mov [bp+4].CalcAtan_pow,edx
        mov [bp+8].CalcAtan_pow,cx
;
        lea ax,[bp].CalcAtan_sum
        push ss
        push ax
        push ss
        push ax
        call MulReal
        xor ch,80h
        mov [bp].CalcAtan_x2,eax
        mov [bp+4].CalcAtan_x2,edx
        mov [bp+8].CalcAtan_x2,cx

        mov si,OFFSET Const3
calc_atan_loop:
        push ss
        lea ax,[bp].CalcAtan_pow
        push ax
        push ss
        lea ax,[bp].CalcAtan_x2
        push ax
        call MulReal
        mov [bp].CalcAtan_pow,eax
        mov [bp+4].CalcAtan_pow,edx
        mov [bp+8].CalcAtan_pow,cx
;
        push ss
        lea ax,[bp].CalcAtan_pow
        push ax
        push cs
        push si
        call DivReal
        mov [bp].CalcAtan_tmp,eax
        mov [bp+4].CalcAtan_tmp,edx
        mov [bp+8].CalcAtan_tmp,cx
;
        push ss
        lea ax,[bp].CalcAtan_tmp
        push ax
        push ss
        lea ax,[bp].CalcAtan_sum
        push ax
        call AddReal
        mov [bp].CalcAtan_sum,eax
        mov [bp+4].CalcAtan_sum,edx
        mov [bp+8].CalcAtan_sum,cx
        add si,20
        cmp si,OFFSET Const25
        jne calc_atan_loop
;
        test bl,4
        jz calc_atan_not4
;
        push cs
        push OFFSET ConstPi2
        push ss
        lea ax,[bp].CalcAtan_sum
        push ax
        call SubReal
        mov [bp].CalcAtan_sum,eax
        mov [bp+4].CalcAtan_sum,edx
        mov [bp+8].CalcAtan_sum,cx

calc_atan_not4:
        test bl,2
        jz calc_atan_not2
;
        push cs
        push OFFSET ConstPi
        push ss
        lea ax,[bp].CalcAtan_sum
        push ax
        call SubReal
        mov [bp].CalcAtan_sum,eax
        mov [bp+4].CalcAtan_sum,edx
        mov [bp+8].CalcAtan_sum,cx

calc_atan_not2:
        test bl,1
        jz calc_atan_done
        xor ch,80h

calc_atan_done:
        pop di
        pop si
        pop es
        pop ds
        add sp,40
        pop bp
        ret 8
CalcAtan        Endp

        
code    ENDS

        END
