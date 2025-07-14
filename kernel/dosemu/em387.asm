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
; EM387.ASM
; FPU emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\os\system.def

include emulate.inc
include emcom.inc
include emseg.inc
include emfloat.inc
include emmem.inc

RC_MASK EQU 0C00h
RC_RND  EQU 0000h
RC_DOWN EQU 0400h
RC_UP   EQU 0800h
RC_CHOP EQU 0C00h

STATUS_B =              8000h
STATUS_C3 =             4000h
STATUS_TOP =    3800h
STATUS_C2 =              400h
STATUS_C1 =              200h
STATUS_C0 =              100h
STATUS_ES =               80h
STATUS_SF =               40h
STATUS_PE =               20h
STATUS_UE =               10h
STATUS_OE =                8h
STATUS_ZE =                4h
STATUS_DE =                2h
STATUS_IE =                1h

CONTROL_X =     1000h
CONTROL_RC =    0C00h
CONTROL_PC =     300h
CONTROL_PM =      20h
CONTROL_UM =      10h
CONTROL_OM =       8h
CONTROL_ZM =       4h
CONTROL_DM =       2h
CONTROL_IM =       1h

TAG_VALID = 00b
TAG_ZERO =      01b
TAG_NAN =       10b
TAG_EMPTY = 11b

code    SEGMENT byte public 'CODE'

        assume cs:code

        .386p

Const1  DT 1.0
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SaveFp
;
;               DESCRIPTION:    Save FP instruction & CS:EIP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveFp  MACRO
        GetThread
        mov fs,ax
        mov dx,word ptr fs:p_math_op
        mov word ptr fs:p_math_prev_op,dx
        and al,7
        mov fs:p_math_op,al
        mov ebx,[ebp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov fs:p_math_eip,eax
        mov ax,[ebp].reg_cs
        mov fs:p_math_cs,ax
        mov fs:p_math_data_offs,0
        mov fs:p_math_data_sel,0
                ENDM
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SaveFp2
;
;               DESCRIPTION:    Save FP second operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveFp2 MACRO
        mov fs:p_math_op+1,al
                ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OpWord
;
;               DESCRIPTION:    Emulate op word ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpWord  MACRO op

EmFi&op&Word    Proc near
        mov bl,al
        call LoadWordMem
        push ax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call IntToReal
        add sp,2
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call op&Real
        add sp,20
;
        xor bl,bl
        call PutReal
        ret
EmFi&op&Word    Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OpDword
;
;               DESCRIPTION:    Emulate op dword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpDword MACRO op

EmFi&op&Dword   Proc near
        mov bl,al
        call LoadDwordMem
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call LongToReal
        add sp,4
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call op&Real
        add sp,20
;
        xor bl,bl
        call PutReal
        ret
EmFi&op&Dword   Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OpSingle
;
;               DESCRIPTION:    Emulate op single ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpSingle        MACRO op

EmF&op&Single   Proc near
        mov bl,al
        call LoadDwordMem
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call FloatToReal
        add sp,4
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call op&Real
        add sp,20
;
        xor bl,bl
        call PutReal
        ret
EmF&op&Single   Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OpDouble
;
;               DESCRIPTION:    Emulate op qword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpDouble        MACRO op

EmF&op&Double   Proc near
        mov bl,al
        call LoadQwordMem
        push edx
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call DoubleToReal
        add sp,8
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call op&Real
        add sp,20
;
        xor bl,bl
        call PutReal
        ret
EmF&op&Double   Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OpStiSt
;
;               DESCRIPTION:    Emulate op st(i),st(0)
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpStiSt MACRO op

EmF&op&StiSt    Proc near
        push ax
        mov bl,al
        call GetReal
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push bx
        push ss
        push ax
        call op&Real
        add sp,20
;
        pop bx
        call PutReal
        ret
EmF&op&StiSt    Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OpStSti
;
;               DESCRIPTION:    Emulate op st(0),st(i)
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpStSti MACRO op

EmF&op&StSti    Proc near
        mov bl,al
        call GetReal
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call op&Real
        add sp,20
;
        xor bl,bl
        call PutReal
        ret
EmF&op&StSti    Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OppStiSt
;
;               DESCRIPTION:    Emulate opp st(i),st(0)
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OppStiSt        MACRO op

EmF&op&pStiSt   Proc near
        call EmF&op&StiSt
        call PopReal
        ret
EmF&op&pStiSt   Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OprWord
;
;               DESCRIPTION:    Emulate op word ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OprWord MACRO op

EmFi&op&rWord   Proc near
        mov bl,al
        call LoadWordMem
        push ax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call IntToReal
        add sp,2
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push bx
        push ss
        push ax
        call op&Real
        add sp,20
;
        xor bl,bl
        call PutReal
        ret
EmFi&op&rWord   Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OprDword
;
;               DESCRIPTION:    Emulate op dword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OprDword        MACRO op

EmFi&op&rDword  Proc near
        mov bl,al
        call LoadDwordMem
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call LongToReal
        add sp,4
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push bx
        push ss
        push ax
        call op&Real
        add sp,20
;
        xor bl,bl
        call PutReal
        ret
EmFi&op&rDword  Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OprSingle
;
;               DESCRIPTION:    Emulate op single ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OprSingle       MACRO op

EmF&op&rSingle  Proc near
        mov bl,al
        call LoadDwordMem
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call FloatToReal
        add sp,4
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push bx
        push ss
        push ax
        call op&Real
        add sp,20
;
        xor bl,bl
        call PutReal
        ret
EmF&op&rSingle  Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OprDouble
;
;               DESCRIPTION:    Emulate op qword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OprDouble       MACRO op

EmF&op&rDouble  Proc near
        mov bl,al
        call LoadQwordMem
        push edx
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call DoubleToReal
        add sp,8
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push bx
        push ss
        push ax
        call op&Real
        add sp,20
;
        xor bl,bl
        call PutReal
        ret
EmF&op&rDouble  Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OprStiSt
;
;               DESCRIPTION:    Emulate op st(i),st(0)
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OprStiSt        MACRO op

EmF&op&rStiSt   Proc near
        push ax
        mov bl,al
        call GetReal
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call op&Real
        add sp,20
;
        pop bx
        call PutReal
        ret
EmF&op&rStiSt   Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OprStSti
;
;               DESCRIPTION:    Emulate op st(0),st(i)
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OprStSti        MACRO op

EmF&op&rStSti   Proc near
        mov bl,al
        call GetReal
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push bx
        push ss
        push ax
        call op&Real
        add sp,20
;
        xor bl,bl
        call PutReal
        ret
EmF&op&rStSti   Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OprpStiSt
;
;               DESCRIPTION:    Emulate opp st(i),st(0)
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OprpStiSt       MACRO op

EmF&op&rpStiSt  Proc near
        call EmF&op&rStiSt
        call PopReal
        ret
EmF&op&rpStiSt  Endp

        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   InvalidFault
;
;               DESCRIPTION:    Invalid number exception
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InvalidFault    Proc near
        or fs:p_math_status, STATUS_IE
        and fs:p_math_status, NOT STATUS_SF
        test fs:p_math_control, CONTROL_IM
        jz FpFault
        ret
InvalidFault    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   StackOverflowFault
;
;               DESCRIPTION:    Stack overflow exception
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StackOverflowFault      Proc near
        or fs:p_math_status, STATUS_IE OR STATUS_SF OR STATUS_C1
        test fs:p_math_control, CONTROL_IM
        jz FpFault
        ret
StackOverflowFault      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   StackUnderflowFault
;
;               DESCRIPTION:    Stack underflow exception
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StackUnderflowFault     Proc near
        or fs:p_math_status, STATUS_IE OR STATUS_SF
        and fs:p_math_status, NOT STATUS_C1
        test fs:p_math_control, CONTROL_IM
        jz FpFault
        ret
StackUnderflowFault     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetReal
;
;               DESCRIPTION:    Get real from stack
;
;               PARAMETERS:             BL              index
;
;               RETURNS:                CX:EDX:EAX              Real
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetReal Proc near
        mov al,bl
        movzx ebx,fs:p_math_status
        rol bx,5
        add bl,al
        and bx,7
        mov cl,bl
        add cl,cl
        mov ax,11b
        shl ax,cl
        mov cx,fs:p_math_tag
        and cx,ax
        cmp ax,cx
        jne GetRealOk
;
        call InvalidFault

GetRealOk:
        add bx,bx
        mov ax,bx
        add bx,bx
        add bx,bx
        add bx,ax
        mov eax,dword ptr fs:[bx].p_math_st0
        mov edx,dword ptr fs:[bx+4].p_math_st0
        mov cx,word ptr fs:[bx+8].p_math_st0
        ret
GetReal Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   PutReal
;
;               DESCRIPTION:    Put real onto stack
;
;               PARAMETERS:             BL                              Register
;                                               CX:EDX:EAX              Real
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PutReal Proc near
        push ax
        push cx
        mov al,bl
        movzx ebx,fs:p_math_status
        rol bx,5
        add bl,al
        and bx,7
        mov si,bx
        add bx,bx
        mov cx,bx
        add bx,bx
        add bx,bx
        add bx,cx
        pop cx
        pop ax
        mov dword ptr fs:[bx].p_math_st0,eax
        mov dword ptr fs:[bx+4].p_math_st0,edx
        mov word ptr fs:[bx+8].p_math_st0,cx
;
        and cx,7FFFh
        jz PutRealZero
;
        cmp cx,7FFFh
        jne PutRealNormal

PutRealZero:
        or eax,edx
        jnz PushRealNan
;
        mov dx,1
        jmp PutRealTag

PutRealNan:
        mov dx,2
        jmp PutRealTag

PutRealNormal:
        mov dx,0

PutRealTag:
        mov cx,si
        add cl,cl
        mov ax,11b
        shl ax,cl
        shl dx,cl
        mov bx,fs:p_math_tag
        not ax
        and bx,ax
        or bx,dx
        mov fs:p_math_tag,bx
        ret
PutReal Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   PushReal
;
;               DESCRIPTION:    Push real onto stack
;
;               PARAMETERS:             CX:EDX:EAX              Real
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PushReal        Proc near
        push ax
        push cx
        mov ax,fs:p_math_status
        mov bx,ax
        rol bx,5
        dec bx
        and bx,7
        mov cl,bl
        mov si,bx
        ror bx,5
        and ax,NOT STATUS_TOP
        or ax,bx
        mov fs:p_math_status,ax
        add cl,cl
        mov ax,11b
        shl ax,cl
        mov bx,fs:p_math_tag
        and bx,ax
        cmp ax,bx
        je PushNoOv
;
        call StackOverflowFault

PushNoOv:
        mov bx,si
        add bx,bx
        mov cx,bx
        add bx,bx
        add bx,bx
        add bx,cx
        pop cx
        pop ax
        mov dword ptr fs:[bx].p_math_st0,eax
        mov dword ptr fs:[bx+4].p_math_st0,edx
        mov word ptr fs:[bx+8].p_math_st0,cx
;
        and cx,7FFFh
        jz PushRealZero
;
        cmp cx,7FFFh
        jne PushRealNormal

PushRealZero:
        or eax,edx
        jnz PushRealNan
;
        mov dx,1
        jmp PushRealTag

PushRealNan:
        mov dx,2
        jmp PushRealTag

PushRealNormal:
        mov dx,0

PushRealTag:
        mov cx,si
        add cl,cl
        mov ax,11b
        shl ax,cl
        shl dx,cl
        mov bx,fs:p_math_tag
        not ax
        and bx,ax
        or bx,dx
        mov fs:p_math_tag,bx
        ret
PushReal        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   PopReal
;
;               DESCRIPTION:    Pop from stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PopReal Proc near
        mov ax,fs:p_math_status
        mov bx,ax
        rol bx,5
        mov cl,bl
        and cl,7
        add cl,cl
        mov ax,11b
        shl ax,cl
        or fs:p_math_tag,ax
        inc bx
        and bx,7
        mov cl,bl
        ror bx,5
        mov ax,fs:p_math_status
        and ax,NOT STATUS_TOP
        or ax,bx
        mov fs:p_math_status,ax
        ret
PopReal Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmWait
;
;               DESCRIPTION:    Emulate fwait 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmWait

EmWait  Proc near
        ret
EmWait  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFinit
;
;               DESCRIPTION:    Emulate finit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFinit Proc near
        mov fs:p_math_control,37Fh
        mov fs:p_math_status,0
        mov fs:p_math_tag,0FFFFh
        mov fs:p_math_eip,0
        mov fs:p_math_cs,0
        mov fs:p_math_data_offs,0
        mov fs:p_math_data_sel,0
        ret
EmFinit Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFclex
;
;               DESCRIPTION:    Emulate fclex
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFclex Proc near
        and fs:p_math_status, 0FF00h
        ret
EmFclex Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFnop
;
;               DESCRIPTION:    Emulate fnop
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFnop  Proc near
        ret
EmFnop  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFdecstp
;
;               DESCRIPTION:    Emulate fdecstp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFdecstp       Proc near
        mov ax,fs:p_math_status
        mov bx,ax
        rol bx,5
        dec bx
        and bx,7
        ror bx,5
        and ax,NOT STATUS_TOP
        or ax,bx
        mov fs:p_math_status,ax
        ret
EmFdecstp       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFincstp
;
;               DESCRIPTION:    Emulate fincstp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFincstp       Proc near
        mov ax,fs:p_math_status
        mov bx,ax
        rol bx,5
        inc bx
        and bx,7
        ror bx,5
        and ax,NOT STATUS_TOP
        or ax,bx
        mov fs:p_math_status,ax
        ret
EmFincstp       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFfreeSt
;
;               DESCRIPTION:    Emulate ffree
;
;               PARAMETERS:             AL              param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFfreeSt       Proc near
        mov cx,fs:p_math_status
        rol cx,5
        add cl,al
        and cl,7
        add cl,cl
        mov ax,11b
        shl ax,cl
        or fs:p_math_tag,ax
        ret
EmFfreeSt       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldcw
;
;               DESCRIPTION:    Emulate fldcw
;
;               PARAMETERS:             AL              param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFldcw Proc near
        mov bl,al
        call LoadWordMem
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov fs:p_math_control,ax
        ret
EmFldcw Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFstcw
;
;               DESCRIPTION:    Emulate fstcw
;
;               PARAMETERS:             AL              param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFstcw Proc near
        mov bl,al
        mov ax,fs:p_math_control
        call SaveWordMem
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        ret
EmFstcw Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFstsw
;
;               DESCRIPTION:    Emulate fstsw
;
;               PARAMETERS:             AL              param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFstsw Proc near
        mov bl,al
        mov ax,fs:p_math_status
        call SaveWordMem
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        ret
EmFstsw Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFstswAx
;
;               DESCRIPTION:    Emulate fstsw ax
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFstswAx       Proc near
        mov ax,fs:p_math_status
        mov word ptr [ebp].reg_eax,ax
        ret
EmFstswAx       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   LoadEnvPm16
;
;               DESCRIPTION:    Load 16-bit protected mode environment
;
;               PARAMETERS:             SI                      Selector
;                                               EBX                     Offset
;
;               RETURNS:                EBX                     Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadEnvPm16     Proc near
        call ReadWord
        add ebx,2
        mov fs:p_math_control,ax
;
        call ReadWord
        add ebx,2
        mov fs:p_math_status,ax
;
        call ReadWord
        add ebx,2
        mov fs:p_math_tag,ax
;
        call ReadWord
        add ebx,2
        mov word ptr fs:p_math_eip,ax
;
        call ReadWord
        add ebx,2
        mov fs:p_math_cs,ax
;
        call ReadWord
        add ebx,2
        mov word ptr fs:p_math_data_offs,ax
;
        call ReadWord
        add ebx,2
        mov fs:p_math_data_sel,ax
        ret
LoadEnvPm16     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SaveEnvPm16
;
;               DESCRIPTION:    Save 16-bit protected mode environment
;
;               PARAMETERS:             SI                      Selector
;                                               EBX                     Offset
;
;               RETURNS:                EBX                     Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveEnvPm16     Proc near
        mov ax,fs:p_math_control
        call WriteWord
        add ebx,2
;
        mov ax,fs:p_math_status
        call WriteWord
        add ebx,2
;
        mov ax,fs:p_math_tag
        call WriteWord
        add ebx,2
;
        mov eax,fs:p_math_eip
        call WriteWord
        add ebx,2
;
        mov ax,fs:p_math_cs
        call WriteWord
        add ebx,2
;
        mov eax,fs:p_math_data_offs
        call WriteWord
        add ebx,2
;
        mov ax,fs:p_math_data_sel
        call WriteWord
        add ebx,2
        ret
SaveEnvPm16     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   LoadEnvPm32
;
;               DESCRIPTION:    Load 32-bit protected mode environment
;
;               PARAMETERS:             SI                      Selector
;                                               EBX                     Offset
;
;               RETURNS:                EBX                     Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadEnvPm32     Proc near
        call ReadDword
        add ebx,4
        mov fs:p_math_control,ax
;
        call ReadDword
        add ebx,4
        mov fs:p_math_status,ax
;
        call ReadDword
        add ebx,4
        mov fs:p_math_tag,ax
;
        call ReadDword
        add ebx,4
        mov fs:p_math_eip,eax
;
        call ReadDword
        add ebx,4
        mov fs:p_math_cs,ax
        shr eax,16
        mov fs:p_math_op,ah
        mov fs:p_math_op+1,al
;
        call ReadDword
        add ebx,4
        mov fs:p_math_data_offs,eax
;
        call ReadDword
        add ebx,4
        mov fs:p_math_data_sel,ax
        ret
LoadEnvPm32     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SaveEnvPm32
;
;               DESCRIPTION:    Save 32-bit protected mode environment
;
;               PARAMETERS:             SI                      Selector
;                                               EBX                     Offset
;
;               RETURNS:                EBX                     Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveEnvPm32     Proc near
        mov eax,-1
        mov ax,fs:p_math_control
        call WriteDword
        add ebx,4
;
        mov eax,-1
        mov ax,fs:p_math_status
        call WriteDword
        add ebx,4
;
        mov eax,-1
        mov ax,fs:p_math_tag
        call WriteDword
        add ebx,4
;
        mov eax,fs:p_math_eip
        call ReadDword
        add ebx,4
;
        mov ah,fs:p_math_op
        and ah,7
        mov al,fs:p_math_op+1
        shl eax,16
        mov ax,fs:p_math_cs
        call WriteDword
        add ebx,4
;
        mov eax,fs:p_math_data_offs
        call ReadDword
        add ebx,4
;
        mov eax,-1
        mov ax,fs:p_math_data_sel
        call ReadDword
        add ebx,4
        ret
SaveEnvPm32     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   LoadEnvRm16
;
;               DESCRIPTION:    Load 16-bit real mode environment
;
;               PARAMETERS:             SI                      Selector
;                                               EBX                     Offset
;
;               RETURNS:                EBX                     Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadEnvRm16     Proc near
        call ReadWord
        add ebx,2
        mov fs:p_math_control,ax
;
        call ReadWord
        add ebx,2
        mov fs:p_math_status,ax
;
        call ReadWord
        add ebx,2
        mov fs:p_math_tag,ax
;
        call ReadWord
        add ebx,2
        mov word ptr fs:p_math_eip,ax
;
        call ReadWord
        add ebx,2
        mov fs:p_math_op,ah
        mov fs:p_math_op+1,al
        and ax,0F000h
        mov fs:p_math_cs,ax
;
        call ReadWord
        add ebx,2
        mov word ptr fs:p_math_data_offs,ax
;
        call ReadWord
        add ebx,2
        and ax,0F000h
        mov fs:p_math_data_sel,ax
        ret
LoadEnvRm16     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   SaveEnvRm16
;
;               DESCRIPTION:    Save 16-bit real mode environment
;
;               PARAMETERS:             SI                      Selector
;                                               EBX                     Offset
;
;               RETURNS:                EBX                     Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveEnvRm16     Proc near
        mov ax,fs:p_math_control
        call WriteWord
        add ebx,2
;
        mov ax,fs:p_math_status
        call WriteWord
        add ebx,2
;
        mov ax,fs:p_math_tag
        call WriteWord
        add ebx,2
;
        movzx eax,word ptr fs:p_math_eip
        movzx edx,fs:p_math_cs
        shl edx,4
        add eax,edx
        call WriteWord
        add ebx,2
;
        movzx eax,word ptr fs:p_math_eip
        movzx edx,fs:p_math_cs
        shl edx,4
        add eax,edx
        shr eax,4
        and ah,0F0h
        mov al,fs:p_math_op
        and al,7
        or ah,al
        mov al,fs:p_math_op+1
        call WriteWord
        add ebx,2
;
        movzx eax,word ptr fs:p_math_data_offs
        movzx edx,fs:p_math_data_sel
        shl edx,4
        add eax,edx
        call WriteWord
        add ebx,2
;
        movzx eax,word ptr fs:p_math_data_offs
        movzx edx,fs:p_math_data_sel
        shl edx,4
        add eax,edx
        shr eax,4
        and ax,0F000h
        call WriteWord
        add ebx,2
        ret
SaveEnvRm16     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldenv
;
;               DESCRIPTION:    Emulate fldenv
;
;               PARAMETERS:             AL              param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFldenv        Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr [ebp].em_flags,a32
        jz EmFldenvA16
        or bl,40h       
EmFldenvA16:
        movzx ebx,bl
        call dword ptr [2*ebx].MemTab
;
        test byte ptr [ebp].reg_eflags+2,2
        jnz EmFlenvRm

EmFldenvPm:
        test byte ptr [ebp].em_flags,d32
        jnz EmFldenvPm32

EmFldenvPm16:
        call LoadEnvPm16
        jmp EmFldenvDone

EmFldenvPm32:
        call LoadEnvPm32
        jmp EmFldenvDone

EmFlenvRm:
        test byte ptr [ebp].em_flags,d32
        jnz EmulateError

EmFldenvRm16:
        call LoadEnvRm16

EmFldenvDone:
        ret
EmFldenv        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFstenv
;
;               DESCRIPTION:    Emulate fstenv
;
;               PARAMETERS:             AL              param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFstenv        Proc near
        mov bx,word ptr fs:p_math_prev_op
        mov word ptr fs:p_math_op,bx
;
        mov bl,al
        mov bh,bl
        and bl,0C0h
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr [ebp].em_flags,a32
        jz EmFstenvA16
        or bl,40h       
EmFstenvA16:
        movzx ebx,bl
        call dword ptr [2*ebx].MemTab
;
        test byte ptr [ebp].reg_eflags+2,2
        jnz EmFstenvRm

EmFstenvPm:
        test byte ptr [ebp].em_flags,d32
        jnz EmFstenvPm32

EmFstenvPm16:
        call SaveEnvPm16
        jmp EmFstenvDone

EmFstenvPm32:
        call SaveEnvPm32
        jmp EmFstenvDone

EmFstenvRm:
        test byte ptr [ebp].em_flags,d32
        jnz EmulateError

EmFstenvRm16:
        call SaveEnvRm16

EmFstenvDone:
        ret
EmFstenv        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFRstor
;
;               DESCRIPTION:    Emulate frstor
;
;               PARAMETERS:             AL              param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFRstor        Proc near
        mov bl,al
        mov bh,bl
        and bl,0C0h
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr [ebp].em_flags,a32
        jz EmFrstorA16
        or bl,40h       
EmFrstorA16:
        movzx ebx,bl
        call dword ptr [2*ebx].MemTab
;
        test byte ptr [ebp].reg_eflags+2,2
        jnz EmFrstorRm

EmFrstorPm:
        test byte ptr [ebp].em_flags,d32
        jnz EmFrstorPm32

EmFrstorPm16:
        call LoadEnvPm16
        jmp EmFrstorSt

EmFrstorPm32:
        call LoadEnvPm32
        jmp EmFrstorSt

EmFrstorRm:
        test byte ptr [ebp].em_flags,d32
        jnz EmulateError

EmFrstorRm16:
        call LoadEnvRm16

EmFrstorSt:
        mov cx,8
        lea di,fs:p_math_st0

EmFrstorLoop:
        push cx
        call ReadTbyte
        mov fs:[di],eax
        mov fs:[di+4],edx
        mov fs:[di+8],cx
        add di,10
        add ebx,10
        pop cx
        loop EmFrstorLoop
;
        ret
EmFRstor        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFSave
;
;               DESCRIPTION:    Emulate fsave
;
;               PARAMETERS:             AL              param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFSave Proc near
        mov bx,word ptr fs:p_math_prev_op
        mov word ptr fs:p_math_op,bx
;
        mov bl,al
        mov bh,bl
        and bl,0C0h
        shr bl,2
        and bh,7
        shl bh,1
        or bl,bh
        test byte ptr [ebp].em_flags,a32
        jz EmFsaveA16
        or bl,40h       
EmFsaveA16:
        movzx ebx,bl
        call dword ptr [2*ebx].MemTab
;
        test byte ptr [ebp].reg_eflags+2,2
        jnz EmFsaveRm

EmFsavePm:
        test byte ptr [ebp].em_flags,d32
        jnz EmFsavePm32

EmFsavePm16:
        call SaveEnvPm16
        jmp EmFsaveSt

EmFsavePm32:
        call SaveEnvPm32
        jmp EmFsaveSt

EmFsaveRm:
        test byte ptr [ebp].em_flags,d32
        jnz EmulateError

EmFsaveRm16:
        call SaveEnvRm16

EmFsaveSt:
        mov cx,8
        lea di,fs:p_math_st0

EmFsaveLoop:
        push cx
        mov eax,fs:[di]
        mov edx,fs:[di+4]
        mov cx,fs:[di+8]
        call WriteTbyte
        add di,10
        add ebx,10
        pop cx
        loop EmFsaveLoop
;
        ret
EmFSave Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFld1
;
;               DESCRIPTION:    Emulate fld1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFld1  Proc near
        mov eax,dword ptr cs:Const1
        mov edx,dword ptr cs:Const1+4
        mov cx,word ptr cs:Const1+8
        call PushReal
        ret
EmFld1  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldl2t
;
;               DESCRIPTION:    Emulate fldl2t
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConstL2t        DW      08AFEh, 0CD1Bh, 0784Bh, 0D49Ah, 4000h

EmFldl2t        Proc near
        mov eax,dword ptr cs:ConstL2t
        mov edx,dword ptr cs:ConstL2t+4
        mov cx,word ptr cs:ConstL2t+8
        call PushReal
        ret
EmFldl2t        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldl2e
;
;               DESCRIPTION:    Emulate fldl2e
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConstL2e        DW      0F0BCh, 05C17h, 03B29h, 0B8AAh, 3FFFh

EmFldl2e        Proc near
        mov eax,dword ptr cs:ConstL2e
        mov edx,dword ptr cs:ConstL2e+4
        mov cx,word ptr cs:ConstL2e+8
        call PushReal
        ret
EmFldl2e        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldpi
;
;               DESCRIPTION:    Emulate fldpi
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConstPi         DW      0C235h, 02168h, 0DAA2h, 0C90Fh, 4000h

EmFldpi Proc near
        mov eax,dword ptr cs:ConstPi
        mov edx,dword ptr cs:ConstPi+4
        mov cx,word ptr cs:ConstPi+8
        call PushReal
        ret
EmFldpi Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldlg2
;
;               DESCRIPTION:    Emulate fldlg2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConstLg2        DW      0F799h, 0FBCFh, 09A84h, 09A20h, 3FFDh

EmFldlg2        Proc near
        mov eax,dword ptr cs:ConstLg2
        mov edx,dword ptr cs:ConstLg2+4
        mov cx,word ptr cs:ConstLg2+8
        call PushReal
        ret
EmFldlg2        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldln2
;
;               DESCRIPTION:    Emulate fldln2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConstLn2        DW      079ACh, 0D1CFh, 017F7h, 0B172h, 3FFEh

EmFldln2        Proc near
        mov eax,dword ptr cs:ConstLn2
        mov edx,dword ptr cs:ConstLn2+4
        mov cx,word ptr cs:ConstLn2+8
        call PushReal
        ret
EmFldln2        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldz
;
;               DESCRIPTION:    Emulate fldz
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Const0          DT 0.0

EmFldz  Proc near
        mov eax,dword ptr cs:Const0
        mov edx,dword ptr cs:Const0+4
        mov cx,word ptr cs:Const0+8
        call PushReal
        ret
EmFldz  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFildWord
;
;               DESCRIPTION:    Emulate fild word ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFildWord      Proc near
        mov bl,al
        call LoadWordMem
        push ax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call IntToReal
        add sp,2
        call PushReal
        ret
EmFildWord      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFildDword
;
;               DESCRIPTION:    Emulate fild dword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFildDword     Proc near
        mov bl,al
        call LoadDwordMem
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call LongToReal
        add sp,4
        call PushReal
        ret
EmFildDword     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFildQword
;
;               DESCRIPTION:    Emulate fild qword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFildQword     Proc near
        mov bl,al
        call LoadQwordMem
        push edx
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call QwordToReal
        add sp,8
        call PushReal
        ret
EmFildQword     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldSingle
;
;               DESCRIPTION:    Emulate fld single
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFldSingle     Proc near
        mov bl,al
        call LoadDwordMem
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call FloatToReal
        add sp,4
        call PushReal
        ret
EmFldSingle     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldDouble
;
;               DESCRIPTION:    Emulate fld double
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFldDouble     Proc near
        mov bl,al
        call LoadQwordMem
        push edx
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call DoubleToReal
        add sp,8
        call PushReal
        ret
EmFldDouble     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldExtended
;
;               DESCRIPTION:    Emulate fld extended
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFldExtended   Proc near
        mov bl,al
        call LoadTbyteMem
        call PushReal
        ret
EmFldExtended   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFbld
;
;               DESCRIPTION:    Emulate fbld
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFbld  Proc near
        mov bl,al
        call LoadTbyteMem
        push cx
        push edx
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call BcdToReal
        add sp,10
        call PushReal
        ret
EmFbld  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFldSt
;
;               DESCRIPTION:    Emulate fld st(i)
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFldSt Proc near
        and al,7
        mov bl,al
        call GetReal
        call PushReal
        ret
EmFldSt Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFistWord
;
;               DESCRIPTION:    Emulate fist word ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFistWord      Proc near
        push ax
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push fs:p_math_control
        call RealToInt
        jnc EmFistWordSave
;
        call InvalidFault

EmFistWordSave:
        add sp,10
        pop bx
        call SaveWordMem
        ret
EmFistWord      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFistpWord
;
;               DESCRIPTION:    Emulate fistp word ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFistpWord     Proc near
        call EmFistWord
        call PopReal
        ret
EmFistpWord     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFistDword
;
;               DESCRIPTION:    Emulate fist dword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFistDword     Proc near
        push ax
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push fs:p_math_control
        call RealToLong
        jnc EmFistDwordSave
;
        call InvalidFault

EmFistDwordSave:
        add sp,10
        pop bx
        call SaveDwordMem
        ret
EmFistDword     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFistpDword
;
;               DESCRIPTION:    Emulate fistp dword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFistpDword    Proc near
        call EmFistDword
        call PopReal
        ret
EmFistpDword    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFistpQword
;
;               DESCRIPTION:    Emulate fistp qword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFistpQword    Proc near
        push ax
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push fs:p_math_control
        call RealToQword
        jnc EmFistpQwordSave
;
        call InvalidFault

EmFistpQwordSave:
        add sp,10
        pop bx
        call SaveQwordMem
        call PopReal
        ret
EmFistpQword    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFstSingle
;
;               DESCRIPTION:    Emulate fst dword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFstSingle     Proc near
        push ax
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        call RealToFloat
        jnc EmFstSingleSave
;
        call InvalidFault

EmFstSingleSave:
        add sp,10
        pop bx
        call SaveDwordMem
        ret
EmFstSingle     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFstpSingle
;
;               DESCRIPTION:    Emulate fstp dword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFstpSingle    Proc near
        call EmFstSingle
        call PopReal
        ret
EmFstpSingle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFstDouble
;
;               DESCRIPTION:    Emulate fst qword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFstDouble     Proc near
        push ax
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        call RealToDouble
        jnc EmFstDoubleSave
;
        call InvalidFault

EmFstDoubleSave:
        add sp,10
        pop bx
        call SaveQwordMem
        ret
EmFstDouble     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFstpDouble
;
;               DESCRIPTION:    Emulate fstp qword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFstpDouble    Proc near
        call EmFstDouble
        call PopReal
        ret
EmFstpDouble    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFstpExtended
;
;               DESCRIPTION:    Emulate fstp tbyte ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFstpExtended  Proc near
        push ax
        xor bl,bl
        call GetReal
        pop bx
        call SaveTbyteMem
        call PopReal
        ret
EmFstpExtended  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFbstp
;
;               DESCRIPTION:    Emulate fbstp
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFbstp Proc near
        push ax
        xor bl,bl
        call GetReal
        xor ebx,ebx
        push bx
        push ebx
        push ebx
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call RealToBcd
        jnc EmFbstpSave
;
        call InvalidFault

EmFbstpSave:
        add sp,10
        pop eax
        pop edx
        pop cx
        pop bx
        call SaveTbyteMem
        call PopReal
        ret
EmFbstp Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFstSt
;
;               DESCRIPTION:    Emulate fst st(i)
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFstSt Proc near
        movzx ebx,fs:p_math_status
        rol bx,5
        and bl,7
        mov bh,bl
        add bl,al
        and bl,7
        mov cl,bh
        add cl,cl
        mov ax,11b
        shl ax,cl
        mov dx,fs:p_math_tag
        mov si,dx
        and dx,ax
        cmp ax,dx
        jne EmFstStOk
;
        call InvalidFault

EmFstStOk:
        shr dx,cl
        mov cl,bl
        add cl,cl
        mov ax,11b
        shl ax,cl
        shl dx,cl
        not ax
        and si,ax
        or si,dx
        mov fs:p_math_tag,si
;
        movzx si,bh
        add si,si
        mov ax,si
        add si,si
        add si,si
        add si,ax
;
        movzx di,bl
        add di,di
        mov ax,di
        add di,di
        add di,di
        add di,ax
;
        mov eax,dword ptr fs:[si].p_math_st0
        mov dword ptr fs:[di].p_math_st0,eax
        mov eax,dword ptr fs:[si+4].p_math_st0
        mov dword ptr fs:[di+4].p_math_st0,eax
        mov ax,word ptr fs:[si+8].p_math_st0
        mov word ptr fs:[di+8].p_math_st0,ax
        ret
EmFstSt Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFstpSt
;
;               DESCRIPTION:    Emulate fstp st(i)
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFstpSt        Proc near
        call EmFstSt
        call PopReal
        ret
EmFstpSt        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFxch
;
;               DESCRIPTION:    Emulate fxch st(0), st(i)
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFxch  Proc near
        push ax
        mov bl,al
        call GetReal
        pop bx
        push cx
        push edx
        push eax
        push bx
        xor bl,bl
        call GetReal
        pop bx
        call PutReal
        pop eax
        pop edx
        pop cx
        xor bl,bl
        call PutReal
        ret
EmFxch  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFiComWord
;
;               DESCRIPTION:    Emulate ficom word ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFiComWord     Proc near
        mov bl,al
        call LoadWordMem
        push ax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call IntToReal
        add sp,2
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call CmpReal
        add sp,20
;
        mov dx,fs:p_math_status
        and dx,NOT (STATUS_C0 OR STATUS_C1 OR STATUS_C2 OR STATUS_C3)
        or dx,ax
        mov fs:p_math_status,dx
        ret
EmFiComWord     Endp

EmFiCompWord    Proc near
        call EmFiComWord
        call PopReal
        ret
EmFiCompWord    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFiComDword
;
;               DESCRIPTION:    Emulate ficom dword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFiComDword    Proc near
        mov bl,al
        call LoadDwordMem
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call LongToReal
        add sp,4
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call CmpReal
        add sp,20
;
        mov dx,fs:p_math_status
        and dx,NOT (STATUS_C0 OR STATUS_C1 OR STATUS_C2 OR STATUS_C3)
        or dx,ax
        mov fs:p_math_status,dx
        ret
EmFiComDword    Endp

EmFiCompDword   Proc near
        call EmFiComDword
        call PopReal
        ret
EmFiCompDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFComSingle
;
;               DESCRIPTION:    Emulate fcom single ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFComSingle    Proc near
        mov bl,al
        call LoadDwordMem
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call FloatToReal
        add sp,4
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call CmpReal
        add sp,20
;
        mov dx,fs:p_math_status
        and dx,NOT (STATUS_C0 OR STATUS_C1 OR STATUS_C2 OR STATUS_C3)
        or dx,ax
        mov fs:p_math_status,dx
        ret
EmFComSingle    Endp

EmFCompSingle   Proc near
        call EmFComSingle
        call PopReal
        ret
EmFCompSingle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFComDouble
;
;               DESCRIPTION:    Emulate fcom qword ptr
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFComDouble    Proc near
        mov bl,al
        call LoadQwordMem
        push edx
        push eax
        mov fs:p_math_data_offs,ebx
        mov fs:p_math_data_sel,si
        mov ax,sp
        push ss
        push ax
        call DoubleToReal
        add sp,8
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call CmpReal
        add sp,20
;
        mov dx,fs:p_math_status
        and dx,NOT (STATUS_C0 OR STATUS_C1 OR STATUS_C2 OR STATUS_C3)
        or dx,ax
        mov fs:p_math_status,dx
        ret
EmFComDouble    Endp

EmFCompDouble   Proc near
        call EmFComDouble
        call PopReal
        ret
EmFCompDouble   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFComStSti
;
;               DESCRIPTION:    Emulate fcom st(0),st(i)
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFComStSti     Proc near
        mov bl,al
        call GetReal
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call CmpReal
        add sp,20
;
        mov dx,fs:p_math_status
        and dx,NOT (STATUS_C0 OR STATUS_C1 OR STATUS_C2 OR STATUS_C3)
        or dx,ax
        mov fs:p_math_status,dx
        ret
EmFComStSti     Endp

EmFCompStSti    Proc near
        call EmFComStSti
        call PopReal
        ret
EmFCompStSti    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFTst
;
;               DESCRIPTION:    Emulate ftst st(0)
;
;               PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFTst  Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
;
    xor eax,eax
    xor edx,edx
    xor cx,cx
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call CmpReal
        add sp,20
;
        mov dx,fs:p_math_status
        and dx,NOT (STATUS_C0 OR STATUS_C1 OR STATUS_C2 OR STATUS_C3)
        or dx,ax
        mov fs:p_math_status,dx
        ret
EmFTst  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFCompp
;
;               DESCRIPTION:    Emulate fcom st(0),st(1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFCompp        Proc near
        mov bl,1
        call GetReal
        push cx
        push edx
        push eax
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call CmpReal
        add sp,20
;
        mov dx,fs:p_math_status
        and dx,NOT (STATUS_C0 OR STATUS_C1 OR STATUS_C2 OR STATUS_C3)
        or dx,ax
        mov fs:p_math_status,dx
;
        call PopReal
        call PopReal
        ret
EmFCompp        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFxam
;
;               DESCRIPTION:    Emulate fxam
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFxam  Proc near
        mov cx,fs:p_math_status
        rol cx,5
        and cl,7
        add cl,cl
        mov ax,11b
        shl ax,cl
        and ax,fs:p_math_tag
        shr ax,cl
        and ax,3
        cmp ax,TAG_EMPTY
        je EmFxamEmpty
;
        cmp ax,TAG_NAN
        je EmFxamNan
;
        cmp ax,TAG_ZERO
        je EmFxamZero

EmFxamNormal:
        xor bl,bl
        call GetReal
        test cx,7FFFh
        jz EmFxamDenormal
;
        mov bx,STATUS_C2
        jmp EmFxamSign

EmFxamDenormal:
        mov bx,STATUS_C3 OR STATUS_C2
        jmp EmFxamSign

EmFxamEmpty:
        mov bx,STATUS_C3 OR STATUS_C0
        jmp EmFxamDone

EmFxamNan:
        xor bl,bl
        call GetReal
        and edx,7FFFFFFFh
        or eax,edx
        jz EmFxamInfinit
;
        mov bx,STATUS_C0
        jmp EmFxamSign

EmFxamInfinit:
        mov bx,STATUS_C2 OR STATUS_C0
        jmp EmFxamSign

EmFxamZero:
        xor bl,bl
        call GetReal
        mov bx,STATUS_C3

EmFxamSign:
        test ch,80h
        jz EmFxamDone
;
        or bx,STATUS_C1 

EmFxamDone:
        mov dx,fs:p_math_status
        and dx,NOT (STATUS_C0 OR STATUS_C1 OR STATUS_C2 OR STATUS_C3)
        or dx,bx
        mov fs:p_math_status,dx
        ret
EmFxam  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFchs
;
;               DESCRIPTION:    Emulate fchs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFchs  Proc near
        xor bl,bl
        call GetReal
        xor ch,80h
        xor bl,bl
        call PutReal
        ret
EmFchs  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFabs
;
;               DESCRIPTION:    Emulate fabs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFabs  Proc near
        xor bl,bl
        call GetReal
        and ch,7Fh
        xor bl,bl
        call PutReal
        ret
EmFabs  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFrndint
;
;               DESCRIPTION:    Emulate frndint
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFrndint       Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push fs:p_math_control
        call RealToQword
        jnc EmFrndintDo
;
        call InvalidFault
        add sp,10
        jmp EmFrndintDone

EmFrndintDo:
        add sp,10
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        call QwordToReal
        add sp,8
        xor bl,bl
        call PutReal

EmFrndintDone:
        ret
EmFrndint       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   fadd, fiadd, faddp
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        OpWord Add
        OpDword Add
        OpSingle Add
        OpDouble Add
        OpStiSt Add
        OpStSti Add
        OppStiSt Add

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   fsub, fisub, fsubp
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        OpWord Sub
        OpDword Sub
        OpSingle Sub
        OpDouble Sub
        OpStiSt Sub
        OpStSti Sub
        OppStiSt Sub

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   fsubr, fisubr, fsubrp
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        OprWord Sub
        OprDword Sub
        OprSingle Sub
        OprDouble Sub
        OprStiSt Sub
        OprStSti Sub
        OprpStiSt Sub

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   fmul, fimul, fmulp
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        OpWord Mul
        OpDword Mul
        OpSingle Mul
        OpDouble Mul
        OpStiSt Mul
        OpStSti Mul
        OppStiSt Mul

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   fdiv, fidiv, fdivp
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        OpWord Div
        OpDword Div
        OpSingle Div
        OpDouble Div
        OpStiSt Div
        OpStSti Div
        OppStiSt Div

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   fdivr, fidivr, fdivrp
;
;               PARAMETERS:             AL              operand
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        OprWord Div
        OprDword Div
        OprSingle Div
        OprDouble Div
        OprStiSt Div
        OprStSti Div
        OprpStiSt Div

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFsqrt
;
;               DESCRIPTION:    emulate fsqrt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFsqrt Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        call CalcSqrt
        add sp,10
        xor bl,bl
        call PutReal
        ret
EmFsqrt Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFscale
;
;               DESCRIPTION:    emulate fscale
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFscale        Proc near
        mov bl,1
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        mov eax,RC_CHOP
        push ax
        call RealToInt
        jnc EmFscaleIntOk
;
        call InvalidFault

EmFscaleIntOk:
        add sp,10
        push ax
        xor bl,bl
        call GetReal
        pop bx
        test bh,80h
        jz EmFscaleUp

EmFscaleDown:
        neg bx
        push cx
        and cx,7FFFh
        sub cx,bx
        jnc EmFscaleDownOk
;
        pop cx
        xor cx,cx
        xor edx,edx
        xor eax,eax
        jmp EmFscaleDone

EmFscaleDownOk:
        mov bx,cx
        pop cx
        and cx,8000h
        or cx,bx
        jmp EmFscaleDone

EmFscaleUp:
        push cx
        and cx,7FFFh
        or cx,8000h
        add cx,bx
        jnc EmFscaleUpOk
;
        pop cx
        or cx,7FFFh
        mov edx,80000000h       
        xor eax,eax
        call InvalidFault
        jmp EmFscaleDone

EmFscaleUpOk:
        mov bx,cx
        and bx,7FFFh
        pop cx
        and cx,8000h
        or cx,bx

EmFscaleDone:
        xor bl,bl
        call PutReal
        ret
EmFscale        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFxtract
;
;               DESCRIPTION:    emulate fxtract
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFxtract       Proc near
        xor bl,bl
        call GetReal
        mov ebx,eax
        or ebx,edx
        jz EmFxtractZero
;
        mov bx,cx
        and bx,7FFFh
        sub bx,3FFFh
        and cx,8000h
        or cx,3FFFh
        push cx
        push edx
        push eax
        push bx
        mov ax,sp
        push ss
        push ax
        call IntToReal
        add sp,2
        xor bl,bl
        call PutReal
        pop eax
        pop edx
        pop cx
        call PushReal
        jmp EmFxtractDone
        
EmFxtractZero:
        push cx
        mov cx,0FFFFh
        mov edx,80000000h       
        xor eax,eax
        xor bl,bl
        call PutReal
        pop cx
        xor eax,eax
        xor edx,edx
        call PushReal
        
EmFxtractDone:
        ret
EmFxtract       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFprem
;
;               DESCRIPTION:    emulate fprem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFprem Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov bl,1
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        push fs:p_math_control
        call CalcPartialRemainder
        add sp,20
        xor bl,bl
        call PutReal
        ret
EmFprem Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFprem1
;
;               DESCRIPTION:    emulate fprem1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFprem1        Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov bl,1
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        push fs:p_math_control
        call CalcPartialRemainder
        add sp,20
        xor bl,bl
        call PutReal
        ret
EmFprem1        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmF2xm1
;
;               DESCRIPTION:    emulate f2xm1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmF2xm1 Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        call CalcExp2M1
        add sp,10
        xor bl,bl
        call PutReal
        ret
EmF2xm1 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFyl2x
;
;               DESCRIPTION:    emulate fyl2x
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFyl2x Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        call CalcLog2
        add sp,10
;
        push cx
        push edx
        push eax
        call PopReal
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call MulReal
        add sp,20
;
        xor bl,bl
        call PutReal    
        ret
EmFyl2x Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFyl2xp1
;
;               DESCRIPTION:    emulate fyl2xp1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFyl2xp1       Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov bx,sp
        push word ptr cs:Const1+8
        push dword ptr cs:Const1+4
        push dword ptr cs:Const1
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call AddReal
        add sp,20
;
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        call CalcLog2
        add sp,10
;
        push cx
        push edx
        push eax
        call PopReal
;
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call MulReal
        add sp,20
;
        xor bl,bl
        call PutReal    
        ret
EmFyl2xp1       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFsin
;
;               DESCRIPTION:    emulate fsin
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFsin  Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        call CalcSin
        add sp,10
        xor bl,bl
        call PutReal
        ret
EmFsin  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFcos
;
;               DESCRIPTION:    emulate fcos
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFcos  Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        call CalcCos
        add sp,10
        xor bl,bl
        call PutReal
        ret
EmFcos  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFsincos
;
;               DESCRIPTION:    emulate fsincos
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFsincos       Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        call CalcSin
        xor bl,bl
        call PutReal
        mov ax,sp
        push ss
        push ax
        call CalcCos
        add sp,10
        call PushReal
        ret
EmFsincos       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFptan
;
;               DESCRIPTION:    emulate fptan
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFptan Proc near
        xor bl,bl
        call GetReal
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        call CalcCos
;
        mov bx,sp
        push cx
        push edx
        push eax
        push ss
        push bx
        call CalcSin
;
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call DivReal
;
        add sp,30
        xor bl,bl
        call PutReal
;
        mov eax,dword ptr cs:Const1
        mov edx,dword ptr cs:Const1+4
        mov cx,word ptr cs:Const1+8
        call PushReal
        ret
EmFptan Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmFpatan
;
;               DESCRIPTION:    emulate fpatan
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFpatan        Proc near
        mov bl,1
        call GetReal
        push cx
        push edx
        push eax
        xor bl,bl
        call GetReal
        mov bx,sp
        push cx
        push edx
        push eax
        mov ax,sp
        push ss
        push ax
        push ss
        push bx
        call CalcAtan
        add sp,20
        mov bl,1
        call PutReal
        call PopReal
        ret
EmFpatan        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMD8
;
;               DESCRIPTION:    EMULATE D8 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmD8

EmD8HiTab:
EmD8C0  DW OFFSET EmFAddStSti,                  OFFSET EmFAddStSti
EmD8C2  DW OFFSET EmFAddStSti,                  OFFSET EmFAddStSti
EmD8C4  DW OFFSET EmFAddStSti,                  OFFSET EmFAddStSti
EmD8C6  DW OFFSET EmFAddStSti,                  OFFSET EmFAddStSti
EmD8C8  DW OFFSET EmFMulStSti,                  OFFSET EmFMulStSti
EmD8CA  DW OFFSET EmFMulStSti,                  OFFSET EmFMulStSti
EmD8CC  DW OFFSET EmFMulStSti,                  OFFSET EmFMulStSti
EmD8CE  DW OFFSET EmFMulStSti,                  OFFSET EmFMulStSti
EmD8D0  DW OFFSET EmFComStSti,                  OFFSET EmFComStSti
EmD8D2  DW OFFSET EmFComStSti,                  OFFSET EmFComStSti
EmD8D4  DW OFFSET EmFComStSti,                  OFFSET EmFComStSti
EmD8D6  DW OFFSET EmFComStSti,                  OFFSET EmFComStSti
EmD8D8  DW OFFSET EmFCompStSti,                 OFFSET EmFCompStSti
EmD8DA  DW OFFSET EmFCompStSti,                 OFFSET EmFCompStSti
EmD8DC  DW OFFSET EmFCompStSti,                 OFFSET EmFCompStSti
EmD8DE  DW OFFSET EmFCompStSti,                 OFFSET EmFCompStSti
EmD8E0  DW OFFSET EmFSubStSti,                  OFFSET EmFSubStSti
EmD8E2  DW OFFSET EmFSubStSti,                  OFFSET EmFSubStSti
EmD8E4  DW OFFSET EmFSubStSti,                  OFFSET EmFSubStSti
EmD8E6  DW OFFSET EmFSubStSti,                  OFFSET EmFSubStSti
EmD8E8  DW OFFSET EmFSubrStSti,                 OFFSET EmFSubrStSti
EmD8EA  DW OFFSET EmFSubrStSti,                 OFFSET EmFSubrStSti
EmD8EC  DW OFFSET EmFSubrStSti,                 OFFSET EmFSubrStSti
EmD8EE  DW OFFSET EmFSubrStSti,                 OFFSET EmFSubrStSti
EmD8F0  DW OFFSET EmFDivStSti,                  OFFSET EmFDivStSti
EmD8F2  DW OFFSET EmFDivStSti,                  OFFSET EmFDivStSti
EmD8F4  DW OFFSET EmFDivStSti,                  OFFSET EmFDivStSti
EmD8F6  DW OFFSET EmFDivStSti,                  OFFSET EmFDivStSti
EmD8F8  DW OFFSET EmFDivrStSti,                 OFFSET EmFDivrStSti
EmD8FA  DW OFFSET EmFDivrStSti,                 OFFSET EmFDivrStSti
EmD8FC  DW OFFSET EmFDivrStSti,                 OFFSET EmFDivrStSti
EmD8FE  DW OFFSET EmFDivrStSti,                 OFFSET EmFDivrStSti

EmD8:
        SaveFp
        call ReadCodeByte
        SaveFp2
        cmp al,0C0h
        jc EmD8Low

EmD8Hi:
        sub al,0C0h
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmD8HiTab

EmD8LowTab:
EmD8_000        DW OFFSET EmFAddSingle
EmD8_001        DW OFFSET EmFMulSingle
EmD8_010        DW OFFSET EmFComSingle
EmD8_011        DW OFFSET EmFCompSingle
EmD8_100        DW OFFSET EmFSubSingle
EmD8_101        DW OFFSET EmFSubrSingle
EmD8_110        DW OFFSET EmFDivSingle
EmD8_111        DW OFFSET EmFDivrSingle

EmD8Low:
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmD8LowTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMD9
;
;               DESCRIPTION:    EMULATE D9 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmD9

EmD9HiTab:
emD9C0  DW OFFSET EmFldSt,                              OFFSET EmFldSt
emD9C2  DW OFFSET EmFldSt,                              OFFSET EmFldSt
emD9C4  DW OFFSET EmFldSt,                              OFFSET EmFldSt
emD9C6  DW OFFSET EmFldSt,                              OFFSET EmFldSt
emD9C8  DW OFFSET EmFxch,                               OFFSET EmFxch
emD9CA  DW OFFSET EmFxch,                               OFFSET EmFxch
emD9CC  DW OFFSET EmFxch,                               OFFSET EmFxch
emD9CE  DW OFFSET EmFxch,                               OFFSET EmFxch
emD9D0  DW OFFSET EmFnop,                               OFFSET EmulateError
emD9D2  DW OFFSET EmulateError,                 OFFSET EmulateError
emD9D4  DW OFFSET EmulateError,                 OFFSET EmulateError
emD9D6  DW OFFSET EmulateError,                 OFFSET EmulateError
emD9D8  DW OFFSET EmulateError,                 OFFSET EmulateError
emD9DA  DW OFFSET EmulateError,                 OFFSET EmulateError
emD9DC  DW OFFSET EmulateError,                 OFFSET EmulateError
emD9DE  DW OFFSET EmulateError,                 OFFSET EmulateError
emD9E0  DW OFFSET EmFchs,                               OFFSET EmFabs
emD9E2  DW OFFSET EmulateError,                 OFFSET EmulateError
emD9E4  DW OFFSET EmFtst,                       OFFSET EmFxam
emD9E6  DW OFFSET EmulateError,                 OFFSET EmulateError
emD9E8  DW OFFSET EmFld1,                               OFFSET EmFldl2t
emD9EA  DW OFFSET EmFldl2e,                             OFFSET EmFldpi
emD9EC  DW OFFSET EmFldlg2,                             OFFSET EmFldln2
emD9EE  DW OFFSET EmFldz,                               OFFSET EmulateError
emD9F0  DW OFFSET EmF2xm1,                              OFFSET EmFyl2x
emD9F2  DW OFFSET EmFptan,                              OFFSET EmFpatan
emD9F4  DW OFFSET EmFxtract,                    OFFSET EmFprem1
emD9F6  DW OFFSET EmFdecstp,                    OFFSET EmFincstp
emD9F8  DW OFFSET EmFprem,                              OFFSET EmFyl2xp1
emD9FA  DW OFFSET EmFsqrt,                              OFFSET EmFsincos
emD9FC  DW OFFSET EmFrndint,                    OFFSET EmFscale
emD9FE  DW OFFSET EmFsin,                               OFFSET EmFcos

EmD9:
        SaveFp
        call ReadCodeByte
        SaveFp2
        cmp al,0C0h
        jc EmD9Low

EmD9Hi:
        sub al,0C0h
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmD9HiTab

EmD9LowTab:
emD9_000        DW OFFSET EmFldSingle
emD9_001        DW OFFSET EmulateError
emD9_010        DW OFFSET EmFstSingle
emD9_011        DW OFFSET EmFstpSingle
emD9_100        DW OFFSET EmFldenv
emD9_101        DW OFFSET EmFldcw
emD9_110        DW OFFSET EmFstenv
emD9_111        DW OFFSET EmFstcw

EmD9Low:
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmD9LowTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMDA
;
;               DESCRIPTION:    EMULATE DA instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmDA

EmDAHiTab:
EmDAC0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAC2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAC4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAC6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAC8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDACA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDACC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDACE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAD0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAD2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAD4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAD6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAD8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDADA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDADC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDADE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAE0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAE2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAE4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAE6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAE8  DW OFFSET EmulateError,                 OFFSET EmFCompp
EmDAEA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAEC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAEE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAF0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAF2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAF4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAF6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAF8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAFA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAFC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDAFE  DW OFFSET EmulateError,                 OFFSET EmulateError

EmDA:
        SaveFp
        call ReadCodeByte
        SaveFp2
        cmp al,0C0h
        jc EmDALow

EmDAHi:
        sub al,0C0h
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmDAHiTab

EmDALowTab:
EmDA_000        DW OFFSET EmFiAddDword
EmDA_001        DW OFFSET EmFiMulDword
EmDA_010        DW OFFSET EmFiComDword
EmDA_011        DW OFFSET EmFiCompDword
EmDA_100        DW OFFSET EmFiSubDword
EmDA_101        DW OFFSET EmFiSubrDword
EmDA_110        DW OFFSET EmFiDivDword
EmDA_111        DW OFFSET EmFiDivrDword

EmDALow:
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmDALowTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMDB
;
;               DESCRIPTION:    EMULATE DB instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmDB

EmDBHiTab:
EmDBC0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBC2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBC4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBC6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBC8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBCA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBCC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBCE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBD0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBD2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBD4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBD6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBD8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBDA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBDC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBDE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBE0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBE2  DW OFFSET EmFclex,                              OFFSET EmFinit
EmDBE4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBE6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBE8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBEA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBEC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBEE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBF0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBF2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBF4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBF6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBF8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBFA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBFC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDBFE  DW OFFSET EmulateError,                 OFFSET EmulateError

EmDB:
        SaveFp
        call ReadCodeByte
        SaveFp2
        cmp al,0C0h
        jc EmDBLow

EmDBHi:
        sub al,0C0h
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmDBHiTab

EmDBLowTab:
emDB_000        DW OFFSET EmFildDword
emDB_001        DW OFFSET EmulateError
emDB_010        DW OFFSET EmFistDword
emDB_011        DW OFFSET EmFistpDword
emDB_100        DW OFFSET EmulateError
emDB_101        DW OFFSET EmFldExtended
emDB_110        DW OFFSET EmulateError
emDB_111        DW OFFSET EmFstpExtended

EmDBLow:
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmDBLowTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMDC
;
;               DESCRIPTION:    EMULATE DC instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmDC

EmDCHiTab:
EmDCC0  DW OFFSET EmFAddStiSt,                  OFFSET EmFAddStiSt
EmDCC2  DW OFFSET EmFAddStiSt,                  OFFSET EmFAddStiSt
EmDCC4  DW OFFSET EmFAddStiSt,                  OFFSET EmFAddStiSt
EmDCC6  DW OFFSET EmFAddStiSt,                  OFFSET EmFAddStiSt
EmDCC8  DW OFFSET EmFMulStiSt,                  OFFSET EmFMulStiSt
EmDCCA  DW OFFSET EmFMulStiSt,                  OFFSET EmFMulStiSt
EmDCCC  DW OFFSET EmFMulStiSt,                  OFFSET EmFMulStiSt
EmDCCE  DW OFFSET EmFMulStiSt,                  OFFSET EmFMulStiSt
EmDCD0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDCD2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDCD4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDCD6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDCD8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDCDA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDCDC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDCDE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDCE0  DW OFFSET EmFSubrStiSt,                 OFFSET EmFSubrStiSt
EmDCE2  DW OFFSET EmFSubrStiSt,                 OFFSET EmFSubrStiSt
EmDCE4  DW OFFSET EmFSubrStiSt,                 OFFSET EmFSubrStiSt
EmDCE6  DW OFFSET EmFSubrStiSt,                 OFFSET EmFSubrStiSt
EmDCE8  DW OFFSET EmFSubStiSt,                  OFFSET EmFSubStiSt
EmDCEA  DW OFFSET EmFSubStiSt,                  OFFSET EmFSubStiSt
EmDCEC  DW OFFSET EmFSubStiSt,                  OFFSET EmFSubStiSt
EmDCEE  DW OFFSET EmFSubStiSt,                  OFFSET EmFSubStiSt
EmDCF0  DW OFFSET EmFDivrStiSt,                 OFFSET EmFDivrStiSt
EmDCF2  DW OFFSET EmFDivrStiSt,                 OFFSET EmFDivrStiSt
EmDCF4  DW OFFSET EmFDivrStiSt,                 OFFSET EmFDivrStiSt
EmDCF6  DW OFFSET EmFDivrStiSt,                 OFFSET EmFDivrStiSt
EmDCF8  DW OFFSET EmFDivStiSt,                  OFFSET EmFDivStiSt
EmDCFA  DW OFFSET EmFDivStiSt,                  OFFSET EmFDivStiSt
EmDCFC  DW OFFSET EmFDivStiSt,                  OFFSET EmFDivStiSt
EmDCFE  DW OFFSET EmFDivStiSt,                  OFFSET EmFDivStiSt

EmDC:
        SaveFp
        call ReadCodeByte
        SaveFp2
        cmp al,0C0h
        jc EmDCLow

EmDCHi:
        sub al,0C0h
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmDCHiTab

EmDCLowTab:
EmDC_000        DW OFFSET EmFAddDouble
EmDC_001        DW OFFSET EmFMulDouble
EmDC_010        DW OFFSET EmFComDouble
EmDC_011        DW OFFSET EmFCompDouble
EmDC_100        DW OFFSET EmFSubDouble
EmDC_101        DW OFFSET EmFSubrDouble
EmDC_110        DW OFFSET EmFDivDouble
EmDC_111        DW OFFSET EmFDivrDouble

EmDCLow:
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmDCLowTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMDD
;
;               DESCRIPTION:    EMULATE DD instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmDD

EmDDHiTab:
EmDDC0  DW OFFSET EmFfreeSt,                    OFFSET EmFfreeSt
EmDDC2  DW OFFSET EmFfreeSt,                    OFFSET EmFfreeSt
EmDDC4  DW OFFSET EmFfreeSt,                    OFFSET EmFfreeSt
EmDDC6  DW OFFSET EmFfreeSt,                    OFFSET EmFfreeSt
EmDDC8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDDCA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDDCC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDDCE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDDD0  DW OFFSET EmFstSt,                              OFFSET EmFstSt
EmDDD2  DW OFFSET EmFstSt,                              OFFSET EmFstSt
EmDDD4  DW OFFSET EmFstSt,                              OFFSET EmFstSt
EmDDD6  DW OFFSET EmFstSt,                              OFFSET EmFstSt
EmDDD8  DW OFFSET EmFstpSt,                             OFFSET EmFstpSt
EmDDDA  DW OFFSET EmFstpSt,                             OFFSET EmFstpSt
EmDDDC  DW OFFSET EmFstpSt,                             OFFSET EmFstpSt
EmDDDE  DW OFFSET EmFstpSt,                             OFFSET EmFstpSt
EmDDE0  DW OFFSET EmFComStSti,                  OFFSET EmFComStSti
EmDDE2  DW OFFSET EmFComStSti,                  OFFSET EmFComStSti
EmDDE4  DW OFFSET EmFComStSti,                  OFFSET EmFComStSti
EmDDE6  DW OFFSET EmFComStSti,                  OFFSET EmFComStSti
EmDDE8  DW OFFSET EmFCompStSti,                 OFFSET EmFCompStSti
EmDDEA  DW OFFSET EmFCompStSti,                 OFFSET EmFCompStSti
EmDDEC  DW OFFSET EmFCompStSti,                 OFFSET EmFCompStSti
EmDDEE  DW OFFSET EmFCompStSti,                 OFFSET EmFCompStSti
EmDDF0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDDF2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDDF4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDDF6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDDF8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDDFA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDDFC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDDFE  DW OFFSET EmulateError,                 OFFSET EmulateError

EmDD:
        SaveFp
        call ReadCodeByte
        SaveFp2
        cmp al,0C0h
        jc EmDDLow

EmDDHi:
        sub al,0C0h
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmDDHiTab

EmDDLowTab:
EmDD_000        DW OFFSET EmFldDouble
EmDD_001        DW OFFSET EmulateError
EmDD_010        DW OFFSET EmFstDouble
EmDD_011        DW OFFSET EmFstpDouble
EmDD_100        DW OFFSET EmFRstor
EmDD_101        DW OFFSET EmulateError
EmDD_110        DW OFFSET EmFSave
EmDD_111        DW OFFSET EmFstsw

EmDDLow:
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmDDLowTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMDE
;
;               DESCRIPTION:    EMULATE DE instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmDE

EmDEHiTab:
EmDEC0  DW OFFSET EmFAddpStiSt,                 OFFSET EmFAddpStiSt
EmDEC2  DW OFFSET EmFAddpStiSt,                 OFFSET EmFAddpStiSt
EmDEC4  DW OFFSET EmFAddpStiSt,                 OFFSET EmFAddpStiSt
EmDEC6  DW OFFSET EmFAddpStiSt,                 OFFSET EmFAddpStiSt
EmDEC8  DW OFFSET EmFMulpStiSt,                 OFFSET EmFMulpStiSt
EmDECA  DW OFFSET EmFMulpStiSt,                 OFFSET EmFMulpStiSt
EmDECC  DW OFFSET EmFMulpStiSt,                 OFFSET EmFMulpStiSt
EmDECE  DW OFFSET EmFMulpStiSt,                 OFFSET EmFMulpStiSt
EmDED0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDED2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDED4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDED6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDED8  DW OFFSET EmulateError,                 OFFSET EmFCompp
EmDEDA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDEDC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDEDE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDEE0  DW OFFSET EmFSubrpStiSt,                OFFSET EmFSubrpStiSt
EmDEE2  DW OFFSET EmFSubrpStiSt,                OFFSET EmFSubrpStiSt
EmDEE4  DW OFFSET EmFSubrpStiSt,                OFFSET EmFSubrpStiSt
EmDEE6  DW OFFSET EmFSubrpStiSt,                OFFSET EmFSubrpStiSt
EmDEE8  DW OFFSET EmFSubpStiSt,                 OFFSET EmFSubpStiSt
EmDEEA  DW OFFSET EmFSubpStiSt,                 OFFSET EmFSubpStiSt
EmDEEC  DW OFFSET EmFSubpStiSt,                 OFFSET EmFSubpStiSt
EmDEEE  DW OFFSET EmFSubpStiSt,                 OFFSET EmFSubpStiSt
EmDEF0  DW OFFSET EmFDivrpStiSt,                OFFSET EmFDivrpStiSt
EmDEF2  DW OFFSET EmFDivrpStiSt,                OFFSET EmFDivrpStiSt
EmDEF4  DW OFFSET EmFDivrpStiSt,                OFFSET EmFDivrpStiSt
EmDEF6  DW OFFSET EmFDivrpStiSt,                OFFSET EmFDivrpStiSt
EmDEF8  DW OFFSET EmFDivpStiSt,                 OFFSET EmFDivpStiSt
EmDEFA  DW OFFSET EmFDivpStiSt,                 OFFSET EmFDivpStiSt
EmDEFC  DW OFFSET EmFDivpStiSt,                 OFFSET EmFDivpStiSt
EmDEFE  DW OFFSET EmFDivpStiSt,                 OFFSET EmFDivpStiSt

EmDE:
        SaveFp
        call ReadCodeByte
        SaveFp2
        cmp al,0C0h
        jc EmDELow

EmDEHi:
        sub al,0C0h
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmDEHiTab

EmDELowTab:
EmDE_000        DW OFFSET EmFiAddWord
EmDE_001        DW OFFSET EmFiMulWord
EmDE_010        DW OFFSET EmFiComWord
EmDE_011        DW OFFSET EmFiCompWord
EmDE_100        DW OFFSET EmFiSubWord
EmDE_101        DW OFFSET EmFiSubrWord
EmDE_110        DW OFFSET EmFiDivWord
EmDE_111        DW OFFSET EmFiDivrWord

EmDELow:
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmDELowTab
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMDF
;
;               DESCRIPTION:    EMULATE DF instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmDF

EmDFHiTab:
EmDFC0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFC2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFC4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFC6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFC8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFCA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFCC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFCE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFD0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFD2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFD4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFD6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFD8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFDA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFDC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFDE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFE0  DW OFFSET EmFstswAx,                    OFFSET EmulateError
EmDFE2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFE4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFE6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFE8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFEA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFEC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFEE  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFF0  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFF2  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFF4  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFF6  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFF8  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFFA  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFFC  DW OFFSET EmulateError,                 OFFSET EmulateError
EmDFFE  DW OFFSET EmulateError,                 OFFSET EmulateError

EmDF:
        SaveFp
        call ReadCodeByte
        SaveFp2
        cmp al,0C0h
        jc EmDFLow

EmDFHi:
        sub al,0C0h
        movzx bx,al
        add bx,bx
        jmp word ptr cs:[bx].EmDFHiTab

EmDFLowTab:
EmDF_000        DW OFFSET EmFildWord
EmDF_001        DW OFFSET EmulateError
EmDF_010        DW OFFSET EmFistWord
EmDF_011        DW OFFSET EmFistpWord
EmDF_100        DW OFFSET EmFbld
EmDF_101        DW OFFSET EmFildQword
EmDF_110        DW OFFSET EmFbstp
EmDF_111        DW OFFSET EmFistpQword

EmDFLow:
        movzx bx,al
        shr bl,2
        and bl,0Eh
        jmp word ptr cs:[bx].EmDFLowTab

code    ENDS

        END
