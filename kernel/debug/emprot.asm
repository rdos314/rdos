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
; EMPROT.ASM
; Protected instruction emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include kdebug.inc
include emcom.inc
include empage.inc
include emmem.inc
include emseg.inc

.386p
.387

code    SEGMENT byte use32 public 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LoadRegAcc
;
;               DESCRIPTION:    Load eax,reg
;
;               PARAMETERS:     DS:EBP  CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadRegAcc      Macro reg, name

EmLoad&name     Proc near
        mov eax,ds:[ebp].reg_&reg
        ret
EmLoad&name     Endp

                        Endm
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmClts
;
;               DESCRIPTION:    EMULATE clts
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmClts

EmClts  Proc near
        test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
        jnz PrivilegeFault
;
        and byte ptr ds:[ebp].reg_cr0,NOT CR0_TS
        ret
EmClts  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveCrReg
;
;               DESCRIPTION:    EMULATE mov cr,reg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveCrReg

EmSaveCr0       Proc near
        mov ds:[ebp].reg_cr0,eax
        ret
EmSaveCr0       Endp

EmSaveCr2       Proc near
        mov ds:[ebp].reg_cr2,eax
        ret
EmSaveCr2       Endp

EmSaveCr3       Proc near
        mov ds:[ebp].reg_cr3,eax
        ret
EmSaveCr3       Endp

EmSaveCr4       Proc near
        mov ds:[ebp].reg_cr4,eax
        ret
EmSaveCr4       Endp

EmSaveCrTab:
scr000  DD OFFSET EmSaveCr0
scr001  DD OFFSET EmulateError
scr010  DD OFFSET EmSaveCr2
scr011  DD OFFSET EmSaveCr3
scr100  DD OFFSET EmSaveCr4
scr101  DD OFFSET EmulateError
scr110  DD OFFSET EmulateError
scr111  DD OFFSET EmulateError

EmMoveCrReg     Proc near
        test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
        jnz PrivilegeFault
;
        call ReadCodeByte
        mov bl,al
        and al,0C0h
        cmp al,0C0h
        jne EmulateError
;
        movzx esi,bl
        and esi,3
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov eax,ds:[ebp+esi]
        shr bl,2
        and ebx,0Eh
        call dword ptr cs:[2*ebx].EmSaveCrTab
        ret
EmMoveCrReg     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveRegCr
;
;               DESCRIPTION:    EMULATE mov reg,cr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveRegCr

        LoadRegAcc      cr0,    Cr0
        LoadRegAcc      cr2,    Cr2
        LoadRegAcc      cr3,    Cr3
        LoadRegAcc      cr4,    Cr4

EmLoadCrTab:
lcr000  DD OFFSET EmLoadCr0
lcr001  DD OFFSET EmulateError
lcr010  DD OFFSET EmLoadCr2
lcr011  DD OFFSET EmLoadCr3
lcr100  DD OFFSET EmLoadCr4
lcr101  DD OFFSET EmulateError
lcr110  DD OFFSET EmulateError
lcr111  DD OFFSET EmulateError

EmMoveRegCr     Proc near
        test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
        jnz PrivilegeFault
;
        call ReadCodeByte
        mov bl,al
        and al,0C0h
        cmp al,0C0h
        jne EmulateError
;
        movzx esi,bl
        shr bl,2
        and ebx,0Eh
        call dword ptr cs:[2*ebx].EmLoadCrTab
        and esi,3
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov ds:[ebp+esi],eax
        ret
EmMoveRegCr     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveDrReg
;
;               DESCRIPTION:    EMULATE mov dr,reg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveDrReg

EmSaveDr0       Proc near
        mov ds:[ebp].reg_dr0,eax
        ret
EmSaveDr0       Endp

EmSaveDr1       Proc near
        mov ds:[ebp].reg_dr1,eax
        ret
EmSaveDr1       Endp

EmSaveDr2       Proc near
        mov ds:[ebp].reg_dr2,eax
        ret
EmSaveDr2       Endp

EmSaveDr3       Proc near
        mov ds:[ebp].reg_dr3,eax
        ret
EmSaveDr3       Endp

EmSaveDr6       Proc near
        mov ds:[ebp].reg_dr6,eax
        ret
EmSaveDr6       Endp

EmSaveDr7       Proc near
        mov ds:[ebp].reg_dr7,eax
        ret
EmSaveDr7       Endp

EmSaveDrTab:
sdr000  DD OFFSET EmSaveDr0
sdr001  DD OFFSET EmSaveDr1
sdr010  DD OFFSET EmSaveDr2
sdr011  DD OFFSET EmSaveDr3
sdr100  DD OFFSET EmulateError
sdr101  DD OFFSET EmulateError
sdr110  DD OFFSET EmSaveDr6
sdr111  DD OFFSET EmSaveDr7

EmMoveDrReg     Proc near
        test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
        jnz TrapFault
;
        call ReadCodeByte
        mov bl,al
        and al,0C0h
        cmp al,0C0h
        jne EmulateError
;
        movzx esi,bl
        and esi,3
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov eax,ds:[ebp+esi]
        shr bl,2
        and ebx,0Eh
        call dword ptr cs:[2*ebx].EmSaveDrTab
        ret
EmMoveDrReg     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveRegDr
;
;               DESCRIPTION:    EMULATE mov reg,dr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMoveRegDr

        LoadRegAcc      dr0,    Dr0
        LoadRegAcc      dr1,    Dr1
        LoadRegAcc      dr2,    Dr2
        LoadRegAcc      dr3,    Dr3
        LoadRegAcc      dr6,    Dr6
        LoadRegAcc      dr7,    Dr7

EmLoadDrTab:
ldr000  DD OFFSET EmLoadDr0
ldr001  DD OFFSET EmLoadDr1
ldr010  DD OFFSET EmLoadDr2
ldr011  DD OFFSET EmLoadDr3
ldr100  DD OFFSET EmulateError
ldr101  DD OFFSET EmulateError
ldr110  DD OFFSET EmLoadDr6
ldr111  DD OFFSET EmLoadDr7

EmMoveRegDr     Proc near
        test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
        jnz TrapFault
;
        call ReadCodeByte
        mov bl,al
        and al,0C0h
        cmp al,0C0h
        jne EmulateError
;
        movzx esi,bl
        shr bl,2
        and ebx,0Eh
        call dword ptr cs:[2*ebx].EmLoadDrTab
        and esi,3
        mov esi,dword ptr cs:[4*esi].DwordRegTab
        mov ds:[ebp+esi],eax
        ret
EmMoveRegDr     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmLmswMem
;
;               DESCRIPTION:    EMULATE lmsw mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLmswMem

EmLmswMem       Proc near
        test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
        jnz PrivilegeFault
;
        mov bl,al
        call LoadWordMemReg
        mov bl,byte ptr ds:[ebp].reg_cr0
        and bl,CR0_PE
        or al,bl
        mov word ptr ds:[ebp].reg_cr0,ax
        ret
EmLmswMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmSmswMem
;
;               DESCRIPTION:    EMULATE smsw mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmSmswMem

EmSmswMem       Proc near
        mov bl,al
        mov ax,word ptr ds:[ebp].reg_cr0
        call SaveWordMemReg
        ret
EmSmswMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmLgdtMem
;
;               DESCRIPTION:    EMULATE lgdt mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLgdtMem

EmLgdtMem       Proc near
        test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
        jnz PrivilegeFault
;
        mov bl,al
        call LoadFwordMem
        mov word ptr ds:[ebp].reg_gdt.d_limit,ax
        ror edx,16
        ror eax,16
        mov dx,ax
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmLgdtMem32
;
        and edx,0FFFFFFh

EmLgdtMem32:
        mov ds:[ebp].reg_gdt.d_base,edx
        ret
EmLgdtMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmSgdtMem
;
;               DESCRIPTION:    EMULATE sgdt mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmSgdtMem

EmSgdtMem       Proc near
        mov bl,al
        mov eax,ds:[ebp].reg_gdt.d_base
        ror eax,16
        mov dx,ax
        mov ax,word ptr ds:[ebp].reg_gdt.d_limit
        call SaveFwordMem
        ret
EmSgdtMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmLidtMem
;
;               DESCRIPTION:    EMULATE lidt mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLidtMem

EmLidtMem       Proc near
        test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
        jnz PrivilegeFault
;
        mov bl,al
        call LoadFwordMem
        mov word ptr ds:[ebp].reg_idt.d_limit,ax
        ror edx,16
        ror eax,16
        mov dx,ax
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmLidtMem32
;
        and edx,0FFFFFFh

EmLidtMem32:
        mov ds:[ebp].reg_idt.d_base,edx
        ret
EmLidtMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmSidtMem
;
;               DESCRIPTION:    EMULATE sidt mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmSidtMem

EmSidtMem       Proc near
        mov bl,al
        mov eax,ds:[ebp].reg_idt.d_base
        ror eax,16
        mov dx,ax
        mov ax,word ptr ds:[ebp].reg_idt.d_limit
        call SaveFwordMem
        ret
EmSidtMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmLldtMem
;
;               DESCRIPTION:    EMULATE lldt mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLldtMem

EmLldtMem       Proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmulateError
;
        test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
        jnz PrivilegeFault
;
        mov bl,al
        call LoadWordMemReg
        call LoadLdt
        ret
EmLldtMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmSldtMem
;
;               DESCRIPTION:    EMULATE sldt mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmSldtMem

EmSldtMem       Proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmulateError
;
        mov bl,al
        mov ax,ds:[ebp].reg_ldt.d_selector
        call SaveWordMemReg
        ret
EmSldtMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmLtrMem
;
;               DESCRIPTION:    EMULATE ltr mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLtrMem

EmLtrMem        Proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmulateError
;
        test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
        jnz PrivilegeFault
;
        mov bl,al
        call LoadWordMemReg
        call LoadTr
        ret
EmLtrMem        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmStrMem
;
;               DESCRIPTION:    EMULATE str mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmStrMem

EmStrMem        Proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmulateError
;
        mov bl,al
        mov ax,ds:[ebp].reg_tr.d_selector
        call SaveWordMemReg
        ret
EmStrMem        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveArplRegMem
;
;               DESCRIPTION:    EMULATE arpl reg,mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmArplRegMem

EmArplRegMem    Proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmulateError
;
        test ds:[ebp].reg_eflags,EFLAGS_VM
        jnz EmulateError
;
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordReg
        pop bx
        push bx
        push ax
        call LoadWordMemReg
        mov dx,ax
        pop ax
        mov dh,al
        and dx,0303h
        cmp dl,dh
        jc EmArplRegMemNoChange 
;
        and al,NOT 3
        or al,dl
        or byte ptr ds:[ebp].reg_eflags,EFLAGS_ZF          
        jmp EmArplRegMemSave

EmArplRegMemNoChange:
        and byte ptr ds:[ebp].reg_eflags, NOT EFLAGS_ZF

EmArplRegMemSave:
        pop bx
        call SaveWordReg
        ret
EmArplRegMem    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveLarRegMem
;
;               DESCRIPTION:    EMULATE lar reg,mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLarRegMem

EmLarRegMem     Proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmulateError
;
        test ds:[ebp].reg_eflags,EFLAGS_VM
        jnz EmulateError
;
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmLarRegMem32

EmLarRegMem16:
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordMemReg
        call ValidateSegment
        jc EmLarRegMemFailed
;
        or byte ptr ds:[ebp].reg_eflags,EFLAGS_ZF          
        mov ax,dx
        and ax,0FF00h   
        pop bx
        call SaveWordReg
        ret

EmLarRegMem32:
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordMemReg
        call ValidateSegment
        jc EmLarRegMemFailed
;
        or byte ptr ds:[ebp].reg_eflags,EFLAGS_ZF          
        mov eax,edx
        and eax,0FFFF00h
        pop bx
        call SaveDwordReg
        ret

EmLarRegMemFailed:
        and byte ptr ds:[ebp].reg_eflags, NOT EFLAGS_ZF
        pop bx
        ret
EmLarRegMem     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmMoveLslRegMem
;
;               DESCRIPTION:    EMULATE lsl reg,mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLslRegMem

EmLslRegMem     Proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmulateError
;
        test ds:[ebp].reg_eflags,EFLAGS_VM
        jnz EmulateError
;
        test byte ptr ds:[ebp].em_flags,d32
        jnz EmLslRegMem32

EmLslRegMem16:
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordMemReg
        call ValidateSegment
        jc EmLslRegMemFailed
;
        or byte ptr ds:[ebp].reg_eflags,EFLAGS_ZF
        mov ebx,edx
        mov bx,ax
        mov eax,ebx
        and eax,0FFFFFh
        ror edx,8
        test dh,80h
        jz EmLslRegMemByte16

EmLslRegMemPage16:
        shr eax,12
        or ax,0FFFh

EmLslRegMemByte16:
        pop bx
        call SaveWordReg
        ret

EmLslRegMem32:
        call ReadCodeByte
        mov bl,al
        push bx
        call LoadWordMemReg
        call ValidateSegment
        jc EmLslRegMemFailed
;
        or byte ptr ds:[ebp].reg_eflags,EFLAGS_ZF
        mov ebx,edx
        mov bx,ax
        mov eax,ebx
        and eax,0FFFFFh
        ror edx,8
        test dh,80h
        jz EmLslRegMemByte32

EmLslRegMemPage32:
        shr eax,12
        or ax,0FFFh

EmLslRegMemByte32:
        pop bx
        call SaveDwordReg
        ret

EmLslRegMemFailed:
        and byte ptr ds:[ebp].reg_eflags, NOT EFLAGS_ZF
        pop bx
        ret
EmLslRegMem     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmVerrMem
;
;               DESCRIPTION:    EMULATE verr mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmVerrMem

EmVerrMem       Proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmulateError
;
        test ds:[ebp].reg_eflags,EFLAGS_VM
        jnz EmulateError
;
        mov bl,al
        call LoadWordMemReg
        call ValidateSegment
        jc EmVerrMemFailed;
;
        test dh,8
        jz EmVerrMemOk
;
        test dh,2
        jz EmVerrMemFailed

EmVerrMemOk:
        or byte ptr ds:[ebp].reg_eflags, EFLAGS_ZF
        ret

EmVerrMemFailed:
        and byte ptr ds:[ebp].reg_eflags, NOT EFLAGS_ZF
        ret
EmVerrMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmVerwMem
;
;               DESCRIPTION:    EMULATE verw mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmVerwMem

EmVerwMem       Proc near
        test ds:[ebp].reg_cr0,CR0_PE
        jz EmulateError
;
        test ds:[ebp].reg_eflags,EFLAGS_VM
        jnz EmulateError
;
        mov bl,al
        call LoadWordMemReg
        call ValidateSegment
        jc EmVerwMemFailed
;
        test dh,8
        jnz EmVerwMemFailed
;
        test dh,2
        jz EmVerwMemFailed
;
        or byte ptr ds:[ebp].reg_eflags, EFLAGS_ZF
        ret

EmVerwMemFailed:
        and byte ptr ds:[ebp].reg_eflags, NOT EFLAGS_ZF
        ret
EmVerwMem       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           EmInlvpg
;
;               DESCRIPTION:    EMULATE invlpg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmInvlpg

EmInvlpg       Proc near
        test byte ptr ds:[ebp].reg_cs.d_access, ACCESS_RPL
        jnz PrivilegeFault
;
        ret
EmInvlpg    Endp

code    ENDS        

        END
