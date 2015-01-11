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
; DEBUG.ASM
; Debugger support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat

INCLUDE \rdos\classlib\emulate\x86\emulate.inc
INCLUDE \rdos\classlib\emulate\x86\emcom.inc
INCLUDE \rdos\classlib\emulate\debhelp.inc

.data

FloatBuffer DB 40 DUP(?)

.code
        extrn FloatToString:near
;        extrn _debugflag:dword                ;the underscore because of the C language
        extrn op_code_size:dword
        extrn op_in_code:byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteEflags
;
;               DESCRIPTION:    
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eflags_tab:
;
;               reset           set
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
et_vm   DB 0,0,0,       0,0,0
et_vi   DB 0,0,0,       0,0,0

iopl_text       DB ' IOPL=',0

cpu_rm  DB 'RM '
cpu_pm  DB 'PM '
cpu_vm  DB 'VM '

WriteEflags     PROC near
        push edi
;
        test byte ptr [ebp].reg_cr0,CR0_PE
        jz eflags_rm
        test [ebp].reg_eflags,EFLAGS_VM
        jz eflags_pm

eflags_vmc:
        mov edi,OFFSET cpu_vm
        jmp eflags_write_mode

eflags_pm:
        mov edi,OFFSET cpu_pm
        jmp eflags_write_mode

eflags_rm:
        mov edi,OFFSET cpu_rm

eflags_write_mode:
        mov ecx,3
        call WriteSizeString    
;
        mov ax,word ptr [ebp].reg_eflags
        shr ax,7
        or ax,word ptr [ebp].reg_eflags+2
        shl eax,16
        mov ax,word ptr [ebp].reg_eflags
        mov edi,OFFSET eflags_tab
        mov ecx,19
eflags_loop:
        mov dl,[edi]
        or dl,dl
        je eflags_skip
        push edi
        test ax,1
        jz eflags_pos_ok
        add edi,3
        jmp eflags_write_one
eflags_pos_ok:
eflags_write_one:
        push ecx
        mov ecx,3
        call WriteSizeString
        pop ecx
        pop edi
eflags_skip:
        shr eax,1
        add edi,6
        loop eflags_loop
        mov edi,OFFSET iopl_text
        call WriteAsciiz
        mov ax,word ptr [ebp].reg_eflags
        shr ax,12
        and ax,3
        add ax,'0'
        call WriteChar
        mov al,' '
        call WriteChar
        call WriteChar
        pop edi
        ret
WriteEflags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteCr0
;
;               DESCRIPTION:    
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cr0_tab:
;
;               reset           set
cr0_pe  DB 0,0,0,       0,0,0
cr0_mp  DB 'FP ',       'MP '
cr0_em  DB 0,0,0,       'EM '
cr0_ts  DB 0,0,0,       'TS '
cr0_4   DB 0,0,0,       0,0,0
cr0_ne  DB 0,0,0,       'NE '
cr0_6   DB 0,0,0,       0,0,0
cr0_7   DB 0,0,0,       0,0,0
cr0_8   DB 0,0,0,       0,0,0
cr0_9   DB 0,0,0,       0,0,0
cr0_10  DB 0,0,0,       0,0,0
cr0_11  DB 0,0,0,       0,0,0
cr0_12  DB 0,0,0,       0,0,0
cr0_13  DB 0,0,0,       0,0,0
cr0_14  DB 0,0,0,       0,0,0
cr0_15  DB 0,0,0,       0,0,0
cr0_wp  DB 0,0,0,       'WP '
cr0_17  DB 0,0,0,       0,0,0
cr0_am  DB 0,0,0,       'AM '
cr0_19  DB 0,0,0,       0,0,0
cr0_20  DB 0,0,0,       0,0,0
cr0_21  DB 0,0,0,       0,0,0
cr0_22  DB 0,0,0,       0,0,0
cr0_23  DB 0,0,0,       0,0,0
cr0_24  DB 0,0,0,       0,0,0
cr0_25  DB 0,0,0,       0,0,0
cr0_26  DB 0,0,0,       0,0,0
cr0_27  DB 0,0,0,       0,0,0
cr0_28  DB 0,0,0,       0,0,0
cr0_nw  DB 'WT ',       'NW '
cr0_cd  DB 'CE ',       'CD '
cr0_pg  DB 'PD ',       'PE '

WriteCr0        PROC near
        push edi
        mov eax,[ebp].reg_cr0
        mov edi,OFFSET cr0_tab
        mov ecx,32
cr0_loop:
        push edi
        test ax,1
        jz cr0_pos_ok
        add edi,3

cr0_pos_ok:
        mov dl,[edi]
        or dl,dl
        je cr0_skip
        push ecx
        mov ecx,3
        call WriteSizeString
        pop ecx
cr0_skip:
        shr eax,1
        pop edi
        add edi,6
        loop cr0_loop
        call NewLine
        pop edi
        ret
WriteCr0        ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteInstr
;
;               DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInstr      Proc near

;d'abord on va ecrire l'offset
;a priori les registres sont sauvegardés

        lea     ebx,[ebp].reg_cs
        mov     dx,[ebx].d_selector
        mov     ebx,[ebp].reg_eip
        call    WriteHexPtr32

;un peu d'espace

        mov     ecx,1
        call    Blank
                
;maintenant on va copier les bytes d'istruction 
        mov     esi,offset op_in_code
        mov     ecx,op_code_size
@@1:
        lodsb
        call    WriteHexByte
        push    ecx
        mov     ecx,1
        call    Blank
        pop     ecx
        loop    @@1             
        
;un peu d'espace
        mov     eax,op_code_size
        mov     ecx,eax
        shl     eax,1
        add     eax,ecx
        mov     ecx,DISTANCE_INSTRUCTION 
        inc     eax
        sub     ecx,eax         ;pour aligner les instructions * J'ai des problemes pour aligner

        call    Blank
;                                       ##GIL END##     
        lea     edi,[ebp].opcode_text
        call    WriteAsciiz
        call    NewLine
        ret
WriteInstr      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteCpuReg
;
;               DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg     Proc near
        call WriteEflags
        call WriteCr0
        call WriteInstr
        ret
WriteCpuReg     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteRegs_
;
;               DESCRIPTION:    Write CPU registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _WriteRegs

_WriteRegs       Proc near
        push ebp
        mov ebp,esp
        pushad
        mov ebp,[ebp+8]
;
        call WriteCpuReg
;
        popad
        pop ebp
        ret 4
_WriteRegs       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteOneFpu
;
;               DESCRIPTION:    Write one FPU register
;
;       PARAMETERS:     ESI     Offset to FPU register
;                       EDI     Text
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


WriteOneFpu Proc near
        call WriteAsciiz
        finit
        fld tbyte ptr [ebp+esi]
        push eax
        mov edi,OFFSET FloatBuffer
        mov al,' '
        mov ecx,35
        rep stosb
        mov ecx,35
        mov edi,OFFSET FloatBuffer
        mov dl,18
        call FloatToString
        call WriteSizeString
        pop eax
        call NewLine
    ret
WriteOneFpu Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteFpuRegs_
;
;               DESCRIPTION:    Write FPU registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _WriteFpuRegs

math0   DB 'ST(0)=', 0
math1   DB 'ST(1)=', 0
math2   DB 'ST(2)=', 0
math3   DB 'ST(3)=', 0
math4   DB 'ST(4)=', 0
math5   DB 'ST(5)=', 0
math6   DB 'ST(6)=', 0
math7   DB 'ST(7)=', 0

_WriteFpuRegs    Proc near
        push ebp
        mov ebp,esp
        pushad
        mov ebp,[ebp+8]
;
    mov dx,[ebp].math_tag
    mov ax,[ebp].math_status
        shr ax,3
        mov cl,ah
        and cl,7
        add cl,cl
        ror dx,cl
        mov ax,dx
;
        mov esi,OFFSET math_st0
        mov edi,OFFSET math0
        call WriteOneFpu
;
        ror ax,2
        mov esi,OFFSET math_st1
        mov edi,OFFSET math1
        call WriteOneFpu
;
        ror ax,2
        mov esi,OFFSET math_st2
        mov edi,OFFSET math2
        call WriteOneFpu
;
        ror ax,2
        mov esi,OFFSET math_st3
        mov edi,OFFSET math3
        call WriteOneFpu
;
        ror ax,2
        mov esi,OFFSET math_st4
        mov edi,OFFSET math4
        call WriteOneFpu
;
        ror ax,2
        mov esi,OFFSET math_st5
        mov edi,OFFSET math5
        call WriteOneFpu
;
        ror ax,2
        mov esi,OFFSET math_st6
        mov edi,OFFSET math6
        call WriteOneFpu
;
        ror ax,2
        mov esi,OFFSET math_st7
        mov edi,OFFSET math7
        call WriteOneFpu
;
        popad
        pop ebp
        ret 4
_WriteFpuRegs    Endp


        END
