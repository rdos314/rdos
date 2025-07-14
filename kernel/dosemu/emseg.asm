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
; EMSEG.ASM
; Segment management functions for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os\protseg.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\os\int.def
include ..\os\system.def

include emulate.inc
include emcom.inc

code    SEGMENT byte public 'CODE'

        assume cs:code

        .386p
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmulateError
;
;               DESCRIPTION:    Unemulated instruction
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmulateError

EmulateError    Proc near
        test byte ptr [bp+2].reg_eflags,2
        jz emulate_ret_pm
;
        mov esp,ebp
        pop ebx
        pop ebp
        xchg ebx,ebp
        mov [ebp].trap_ebp,ebx
        pop edi
        pop esi
        pop edx
        pop ecx
        movzx ax,byte ptr [ebp].trap_exc_nr
        ReflectException
        ret

emulate_ret_pm:
        test byte ptr [bp].reg_cs,3
        jz emulate_ret_kernel
;
        mov esp,ebp
        pop ebx
        pop ebp
        xchg ebx,ebp
        mov [ebp].trap_ebp,ebx
        pop edi
        pop esi
        pop edx
        pop ecx
        add esp,24
        pop es
        add esp,2
        pop fs
        pop gs
        xor dx,dx
        movzx ax,byte ptr [ebp].trap_exc_nr
        ReflectException
        ret

emulate_ret_kernel:
        mov eax,[bp].reg_old_ebp
        sub eax,[bp].reg_esp
        je emulate_ret_kernel_stack_ok
        jc emulate_ret_kernel_stack_ok
;
        mov esi,[bp].reg_esp
        mov edi,[bp].reg_old_ebp
        mov cx,ss
        mov es,cx
        add esi,16
        add edi,16
        mov ecx,esi
        sub ecx,esp
        shr ecx,1
        inc ecx
        std
        rep movs word ptr es:[edi],es:[esi]
        cld
        sub esp,eax
        sub ebp,eax

emulate_ret_kernel_stack_ok:
        mov esp,ebp
        pop ebx
        pop ebp
        xchg ebx,ebp
        mov [ebp].trap_ebp,ebx
        pop edi
        pop esi
        pop edx
        pop ecx
        add esp,24
        pop es
        pop word ptr [ebp].trap_pds
        pop fs
        pop gs
        movzx ax,byte ptr [ebp].trap_exc_nr
        DebugException
        ret
EmulateError    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ValidateSegment
;
;               DESCRIPTION:    Validate a selector
;
;               PARAMETERS:             SS:BP           CPU
;                                               AX                      SEGMENT REGISTER TO VALIDATE
;
;               RETURNS:                NC                      VALID
;                                                       EDX:EAX DESCRIPTOR
;                                               CY                      INVALID
;                                                       BX              ERROR CODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ValidateSegment

ValidateSegment Proc near
        test byte ptr [bp+2].reg_eflags,2
        jz EmulateError
;
        ret
ValidateSegment Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   JmpFar
;
;               DESCRIPTION:    Emulate protected mode far jump
;
;               PARAMETERS:             SS:BP           CPU
;                                               BX:ESI          ADDRESS TO JMP TO
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public JmpFar

JmpFar  Proc near
        test byte ptr [bp].reg_eflags+2,2
        jz EmulateError

JmpFarReal:
        cmp esi,10000h
        jnc EmulateError
;       
        mov word ptr [bp].reg_eip,si
        mov [bp].reg_cs,bx
        ret
JmpFar  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CallFar16
;
;               DESCRIPTION:    Emulate protected mode call far
;
;               PARAMETERS:             SS:BP           CPU
;                                               BX:ESI          ADDRESS TO JMP TO
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public CallFar16

CallFar16       Proc near
        test byte ptr [bp].reg_eflags+2,2
        jz EmulateError
;
        mov ax,[bp].reg_cs
        call PushWord
        mov ax,word ptr [bp].reg_eip
        call PushWord

CallFarReal16:
        mov word ptr [bp].reg_eip,si
        mov [bp].reg_cs,bx
        ret
CallFar16       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CallFar32
;
;               DESCRIPTION:    Emulate protected mode call far
;
;               PARAMETERS:             SS:BP           CPU
;                                               BX:ESI          ADDRESS TO JMP TO
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public CallFar32

CallFar32       Proc near
        test byte ptr [bp].reg_eflags+2,2
        jz EmulateError

CallFarReal32:
        cmp esi,10000h
        jnc EmulateError
;       
        mov word ptr [bp].reg_eip,si
        mov [bp].reg_cs,bx
        ret
CallFar32       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   RetFar16
;
;               DESCRIPTION:    Emulate protected mode retf16
;
;               PARAMETERS:             SS:BP           CPU
;                                               CL                      # of params to remove
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public RetFar16

RetFar16        Proc near
        test byte ptr [bp].reg_eflags+2,2
        jz EmulateError
;
        call PopWord
        movzx esi,ax
        call PopWord
        mov bx,ax

RetFarReal16:
        mov word ptr [bp].reg_eip,si
        mov [bp].reg_cs,bx
        ret
RetFar16        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   RetFar32
;
;               DESCRIPTION:    Emulate protected mode retf32
;
;               PARAMETERS:             SS:BP           CPU
;                                               CL                      # of params to remove
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public RetFar32

RetFar32        Proc near
        test byte ptr [bp].reg_eflags+2,2
        jz EmulateError
;
        call PopDword
        mov esi,eax
        call PopDword
        mov bx,ax

RetFarReal32:
        cmp esi,10000h
        jnc EmulateError
;
        mov word ptr [bp].reg_eip,si
        mov [bp].reg_cs,bx
        ret
RetFar32        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   IntFar
;
;               DESCRIPTION:    Emulate protected mode int
;
;               PARAMETERS:             SS:BP           CPU
;                                               AL                      INT #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public IntFar

IntFar  Proc near
        test byte ptr [bp+2].reg_eflags,2
        jz IntFarPm
;
        push ax
        mov ax,word ptr [bp].reg_eflags
        GetFlags
        call PushWord
        mov ax,[bp].reg_cs
        rol eax,16
        mov ax,word ptr [bp].reg_eip
        call PushDword
        pop ax
        GetVmInt
        mov [bp].reg_cs,dx
        mov word ptr [bp].reg_eip,bx
        jmp IntFarDone

IntFarPm:
        test byte ptr [bp].reg_cs,3
        jz EmulateError
;
        push ax
        mov ax,[bp].reg_cs
        cmp ax,flat_code_sel
        pop ax
        je IntFarPm32

IntFarPm16:
        push ax
        mov ax,word ptr [bp].reg_eflags
        call PushWord
        mov ax,[bp].reg_cs
        rol eax,16
        mov ax,word ptr [bp].reg_eip
        call PushDword
        pop ax
        GetPMInt
        mov [bp].reg_cs,es
        mov word ptr [bp].reg_eip,di
        jmp IntFarDone

IntFarPm32:
        push ax
        mov eax,[bp].reg_eflags
        call PushDword
        mov ax,[bp].reg_cs
        call PushDword
        mov eax,[bp].reg_eip
        call PushDword
        pop ax
        UserGateForce32 get_pm_int_nr
        mov [bp].reg_cs,es
        mov [bp].reg_eip,edi

IntFarDone:
        ret
IntFar  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ExcFar
;
;               DESCRIPTION:    Emulate protected mode exception
;
;               PARAMETERS:             SS:BP           CPU
;                                               AL                      Exception #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ExcFar

ExcFar  Proc near
        test byte ptr [bp+2].reg_eflags,2
        jnz IntFar
;
        test byte ptr [bp].reg_cs,3
        jz EmulateError
;
        push ax
        mov ax,[bp].reg_cs
        cmp ax,flat_code_sel
        pop ax
        je ExcFarPm32

ExcFarPm16:
        push ax
        GetExceptionStack16
;
        mov ax,[bp].reg_ss
        cmp ax,bx
        je exc16_same_stack
;
        mov ax,bx
        mov bx,800h
        jmp exc16_stack_ok

exc16_same_stack:
        mov bx,word ptr [bp].reg_esp
        
exc16_stack_ok:
        xchg ax,[bp].reg_ss
        xchg bx,word ptr [bp].reg_esp
;
        call PushWord
;
        mov ax,bx
        call PushWord
;       
        mov ax,word ptr [bp].reg_eflags
        call PushWord
;
        mov ax,[bp].reg_cs
        call PushWord
;
        mov ax,word ptr [bp].reg_eip
        call PushWord
;
        mov ax,[bp].vm_err
        call PushWord
;
        mov ax,callb_exc16_sel
        call PushWord
;
        pop ax
;
        push ax
        movzx ax,al
        shl ax,3
        call PushWord
        pop ax
;
        GetException
        mov [bp].reg_cs,es
        mov word ptr [bp].reg_eip,di
        jmp ExcFarDone

ExcFarPm32:
        push ax
        movzx eax,[bp].reg_ss
        mov ebx,[bp].reg_esp
        call PushDword
        mov eax,ebx
        add eax,12
        call PushDword
;       
        mov eax,[bp].reg_eflags
        call PushDword
;
        movzx eax,[bp].reg_cs
        call PushDword
;
        mov eax,[bp].reg_eip
        call PushDword
;
        xor eax,eax
        call PushDword
;
        mov eax,callb_exc32_sel
        call PushDword
;
        pop ax
        push ax
        movzx eax,al
        shl eax,3
        call PushDword
;
        pop ax
        UserGateForce32 get_exception_nr
        mov [bp].reg_cs,es
        mov [bp].reg_eip,edi

ExcFarDone:
        ret
ExcFar  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   FpFault
;
;               DESCRIPTION:    Floating point fault
;
;               PARAMETERS:             SS:BP   CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public FpFault

FpFault Proc near
        xor cx,cx
        mov al,7
        call ExcFar     
        ret
FpFault Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   IretFar16
;
;               DESCRIPTION:    Emulate protected mode iret16
;
;               PARAMETERS:             SS:BP           CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public IretFar16

IretFar16       Proc near
        test byte ptr [bp].reg_eflags+2,2
        jz EmulateError
;
        call PopWord
        movzx esi,ax
        call PopWord
        mov bx,ax

IretFarReal16:
        mov word ptr [bp].reg_eip,si
        mov [bp].reg_cs,bx
        call PopWord
        SetFlags
        mov word ptr [bp].reg_eflags,ax
        ret
IretFar16       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   IretFar32
;
;               DESCRIPTION:    Emulate protected mode iret32
;
;               PARAMETERS:             SS:BP           CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public IretFar32

IretFar32       Proc near
        test byte ptr [bp].reg_eflags+2,2
        jz EmulateError
;
        call PopDword
        mov esi,eax
        call PopDword
        mov bx,ax

IretFarReal32:
        cmp esi,10000h
        jnc EmulateError
        mov word ptr [bp].reg_eip,si
        mov [bp].reg_cs,bx
        call PopDword
        SetFlags
        mov word ptr [bp].reg_eflags,ax
        ret
IretFar32       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   IretTss
;
;               DESCRIPTION:    IRET back to a TSS
;
;               PARAMETERS:             SS:BP           CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public IretTss

IretTss Proc near
        jmp EmulateError
IretTss Endp

code    ENDS

        END
