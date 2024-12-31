;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; DEBOS.ASM
; OS-based kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\core.inc
INCLUDE kdebug.inc


debug_row       EQU 0
debug_col       EQU 4
debug_ant       EQU 8
debug_call      EQU 12
debug_size      EQU 16

.386p
.387

data    SEGMENT byte public 'DATA'

cpu cpu_struc <>

sw_func_code     DW ?
sw_col           DB ?
sw_row           DB ?

data    ENDS

code    SEGMENT byte use32 public 'CODE'

    extrn DisAsmCode:near
    extrn AddNewLine:near
    extrn AddBlanks:near
    extrn AddDelimiter:near
    extrn AddHexByte:near
    extrn AddHexWord:near
    extrn AddHexDword:near
    extrn AddHexQword:near
    extrn AddHexPtr16:near
    extrn AddHexPtr32:near
    extrn AddHexPtr64:near
    extrn AddCodeAsciiz:near
    extrn AddProtDataRow:near
    extrn AddLongDataRow:near
    extrn AddPhysDataRow:near
    extrn AddFreeMem:near
    extrn FloatToString:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddEflags
;
;           DESCRIPTION:    Add flags
;
;           PARAMETERS:     ES:EDI      Buffer
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

iopl_text       DB ' IOPL=',0

AddEflags     PROC near
    push eax
    push ecx
    push edx
    push esi
;    
    mov eax,dword ptr gs:p_rflags
    mov esi,OFFSET eflags_tab
    mov ecx,18
    
eflags_loop:
    push esi
;    
    mov dl,cs:[esi]
    or dl,dl
    je eflags_next
;
    test al,1
    jz eflags_write_one
;    
    add esi,3

eflags_write_one:
    push ecx
    mov ecx,3
    rep movs es:[edi],cs:[esi]
    pop ecx
    
eflags_next:
    pop esi
;
    shr eax,1
    add esi,6
;
    loop eflags_loop
;
    mov esi,OFFSET iopl_text
    call AddCodeAsciiz
;    
    mov ax,word ptr gs:p_rflags
    shr ax,12
    and ax,3
    add ax,'0'
    stosb
;
    pop esi
    pop edx
    pop ecx
    pop eax    
    ret
AddEflags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddWordRegs
;
;           DESCRIPTION:    
;
;           PARAMETERS:     CS:ESI      Table
;                           ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddWordRegs   PROC near

awLoop:
    mov al,cs:[esi]
    or al,al
    je awEnd
;    
    mov ecx,4
    rep movs es:[edi],cs:[esi]
;
    movzx ebx,word ptr cs:[esi]
    or ebx,ebx
    jz awThread
;    
    mov ax,gs:[ebx]
    jmp awWrite

awThread:
    mov ax,gs

awWrite:
    call AddHexWord
           
awCont:
    add esi,2
    jmp awLoop
    
awEnd:
    ret
AddWordRegs   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddDwordRegs
;
;           DESCRIPTION:    
;
;           PARAMETERS:     CS:ESI       Table
;                           ES:EDI       Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDwordRegs  PROC near

adLoop:
    mov al,cs:[esi]
    or al,al
    je adEnd
;    
    mov ecx,5
    rep movs byte ptr es:[edi],cs:[esi]
;
    movzx ebx,word ptr cs:[esi]
    mov eax,gs:[ebx]
    call AddHexDword
    add esi,2
    jmp adLoop
    
adEnd:
    ret
AddDwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddQwordRegs
;
;           DESCRIPTION:    
;
;           PARAMETERS:     CS:ESI       Table
;                           ES:EDI       Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddQwordRegs  PROC near

aqLoop:
    mov al,cs:[esi]
    or al,al
    je aqEnd
;
    mov ecx,5
    rep movs byte ptr es:[edi],cs:[esi]
;    
    movzx ebx,cs:[esi]
    mov eax,gs:[ebx]
    mov edx,gs:[ebx+4]
    call AddHexQword
    add esi,2
    jmp aqLoop
    
aqEnd:
    ret
AddQwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddFault
;
;           DESCRIPTION:    Add fault reason
;
;           PARAMETERS:     ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ft_intr DB 'Interrupt fault   ',0
ft_inst DB 'Instruction fault ',0

ft_idt  DB 'idt ',0
ft_ldt  DB 'ldt ',0
ft_gdt  DB 'gdt ',0

AddFault      PROC near
    test word ptr gs:p_rflags+2,2
    jnz afEnd
;    
    mov eax,dword ptr gs:p_fault_code
    cmp ax,3
    je afEnd
;    
    mov esi,OFFSET ft_inst
    or ax,ax
    jz adEnd
;
    test ax,1
    jz afNotInt
;    
    mov esi,OFFSET ft_intr

afNotInt:
    call AddCodeAsciiz
    test ax,2
    jz afNotIdt
;    
    mov esi,OFFSET ft_idt
    jmp afReason

afNotIdt:
    mov esi,OFFSET ft_gdt
    test ax,4
    jz afReason
;    
    mov esi,OFFSET ft_ldt

afReason:
    call AddCodeAsciiz
;    
    and ax,0FFF8h
    call AddHexWord
    jmp afDone

afEnd:
    mov ecx,30
    call AddBlanks

afDone:    
    ret
AddFault      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddExceptionCode
;
;           DESCRIPTION:    Add exception code
;
;           PARAMETERS:     ES:EDI      Buffer
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

AddExceptionCode    Proc near
    movzx edx,gs:p_fault_vector
    mov ebx,edx
    add ebx,ebx
    add ebx,ebx
    add ebx,ebx
    mov ecx,ebx
    add ecx,ecx
    add ebx,ecx
    mov esi,OFFSET error_code_tab
    add esi,ebx
    mov ecx,24
    rep movs byte ptr es:[edi],cs:[esi]
    ret
AddExceptionCode    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddThreadInfo
;
;           DESCRIPTION:    Add thread info
;
;           PARAMETERS:     ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddThreadInfo     Proc near
    mov ax,gs:p_id
    call AddHexWord
;    
    mov al,' '
    stosb
    stosb
;    
    mov esi,OFFSET thread_name
    mov ecx,30
    rep movs byte ptr es:[edi],gs:[esi]
;
    call AddNewLine
    ret
AddThreadInfo     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddProtData
;
;           DESCRIPTION:    Add protected mode data
;
;           PARAMETERS:     ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddProtData       PROC near
    mov al,ds:[ebp].data_valid
    or al,al
    jz apdNoPtr
;
    mov esi,ds:[ebp].data_offset
    mov edx,ds:[ebp].data_sel
    call AddProtDataRow
    jmp apdPtrOk

apdNoPtr:
    mov ecx,79
    call AddBlanks

apdPtrOk:
    call AddNewLine
;
    mov dx,gs:p_cs
    mov esi,dword ptr gs:p_rip
    call AddProtDataRow
    call AddNewLine
;
    mov dx,gs:p_ss
    mov esi,dword ptr gs:p_rsp
    call AddProtDataRow
    call AddNewLine
;
    mov dx,gs:p_es
    xor esi,esi
    call AddProtDataRow
    call AddNewLine
;
    xor ecx,ecx
    xchg ecx,ds:[ebp].reg_eflags
    push ecx
;
    mov dx,gs:p_pm_deb_sel
    mov esi,gs:p_pm_deb_offs
    call AddProtDataRow
    call AddNewLine
;
    mov edx,gs:p_deb_phys+4
    mov esi,gs:p_deb_phys
    call AddPhysDataRow
;
    pop ecx
    mov ds:[ebp].reg_eflags,ecx
    ret
AddProtData       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddLongData
;
;           DESCRIPTION:    Add long-mode data
;
;           PARAMETERS:     ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddLongData       PROC near
    mov al,gs:p_realtime
    or al,al
    jnz wd64_real
;
    mov bx,gs:p_cs
    IsLongCodeSelector
    jc wd64_32

wd64_64:    
    mov al,ds:[ebp].data_valid
    or al,al
    jz data_no_good64_64
;
    mov esi,ds:[ebp].data_offset
    mov edx,ds:[ebp].data_offset+4
    call AddLongDataRow
    jmp data_next64_64

data_no_good64_64:
    mov ecx,79
    call AddBlanks

data_next64_64:
    call AddNewLine
;
    mov esi,dword ptr gs:p_rip
    mov edx,dword ptr gs:p_rip+4
    call AddLongDataRow
    call AddNewLine
;
    mov esi,dword ptr gs:p_rsp
    mov edx,dword ptr gs:p_rsp+4
    call AddLongDataRow
    call AddNewLine
;
    mov esi,dword ptr gs:p_rdi
    mov edx,dword ptr gs:p_rdi+4
    call AddLongDataRow
    call AddNewLine
    jmp wd64_data

wd64_real:    
    mov al,ds:[ebp].data_valid
    or al,al
    jz data_no_good64_real
;
    mov esi,ds:[ebp].data_offset
    mov edx,ds:[ebp].data_offset+4
    call AddLongDataRow
    jmp data_next64_real

data_no_good64_real:
    mov ecx,79
    call AddBlanks

data_next64_real:
    call AddNewLine
;
    mov esi,dword ptr gs:p_rip
    mov edx,dword ptr gs:p_rip+4
    call AddLongDataRow
    call AddNewLine
;
    mov esi,dword ptr gs:p_rsp
    mov edx,dword ptr gs:p_rsp+4
    call AddLongDataRow
    call AddNewLine
;
    mov esi,dword ptr gs:p_rdi
    mov edx,dword ptr gs:p_rdi+4
    call AddLongDataRow
    call AddNewLine
;
    mov dx,gs:p_pm_deb_sel
    mov esi,gs:p_pm_deb_offs
    call AddLongDataRow
    call AddNewLine
    jmp wd64_phys

wd64_32:
    mov al,ds:[ebp].data_valid
    or al,al
    jz data_no_good64_32
;       
    mov esi,ds:[ebp].data_offset
    mov edx,ds:[ebp].data_sel
    call AddProtDataRow
    jmp data_next64_32

data_no_good64_32:
    mov ecx,79
    call AddBlanks

data_next64_32:
    call AddNewLine
;
    mov dx,gs:p_cs
    mov esi,dword ptr gs:p_rip
    call AddProtDataRow
    call AddNewLine
;
    mov dx,gs:p_ss
    mov esi,dword ptr gs:p_rsp
    call AddProtDataRow
    call AddNewLine
;
    mov dx,gs:p_es
    xor esi,esi
    call AddProtDataRow
    call AddNewLine

wd64_data:    
    mov dx,gs:p_pm_deb_sel
    mov esi,gs:p_pm_deb_offs
    call AddProtDataRow
    call AddNewLine

wd64_phys:
    mov edx,gs:p_deb_phys+4
    mov esi,gs:p_deb_phys
    call AddPhysDataRow
    ret
AddLongData       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddMathOne
;
;           DESCRIPTION:    Add math register
;
;           PARAMETERS:     CS:ESI      Register name
;                           AX          Tag value
;                           EBX         Register data index
;                           ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

zero    DB 'Zero                              ',0
nan     DB 'NAN                               ',0
empty   DB 'Empty                             ',0

AddMathOne      PROC near       
    push eax
    push ebx
    push esi
;    
    call AddCodeAsciiz
;
    mov cl,al
    and cl,3
    jz AddMathNorm
;
    cmp cl,1
    je AddMathZero
;
    cmp cl,2
    je AddMathNan

AddMathEmpty:
    mov esi,OFFSET Empty
    call AddCodeAsciiz
    jmp AddMathDone

AddMathNan:
    mov esi,OFFSET nan
    call AddCodeAsciiz
    jmp AddMathDone

AddMathZero:
    mov esi,OFFSET zero
    call AddCodeAsciiz
    jmp AddMathDone

AddMathNorm:
    and ebx,7
    mov eax,10
    mul ebx
    fld tbyte ptr gs:[eax].p_math_st0
;    
    mov cl,35
    mov dl,18
    call FloatToString

AddMathDone:
    mov ecx,35
    call AddBlanks
    call AddNewLine
;
    pop esi
    pop ebx    
    pop eax
    ret
AddMathOne      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddCoproc
;
;           DESCRIPTION:    Add co-processor state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

math0   DB 'ST(0)=  ',0
math1   DB 'ST(1)=  ',0
math2   DB 'ST(2)=  ',0
math3   DB 'ST(3)=  ',0
math4   DB 'ST(4)=  ',0
math5   DB 'ST(5)=  ',0
math6   DB 'ST(6)=  ',0
math7   DB 'ST(7)=  ',0

AddCoproc     Proc near
    finit
    mov dx,gs:p_math_tag
    mov ax,gs:p_math_status
    shr ax,3
    mov cl,ah
    and cl,7
    add cl,cl
    ror dx,cl
    mov ebx,cr0
    test bx,4
    jz acReal
;
    movzx ebx,cl
    jmp acDo

acReal:
    xor ebx,ebx

acDo:    
    mov ax,dx
;
    mov esi,OFFSET math0
    call AddMathOne
;    
    ror ax,2
    inc ebx
    mov esi,OFFSET math1
    call AddMathOne
;    
    ror ax,2
    inc ebx
    mov esi,OFFSET math2
    call AddMathOne
;    
    ror ax,2
    inc ebx
    mov esi,OFFSET math3
    call AddMathOne
;    
    ror ax,2
    inc ebx
    mov esi,OFFSET math4
    call AddMathOne
;    
    ror ax,2
    inc ebx
    mov esi,OFFSET math5
    call AddMathOne
;    
    ror ax,2
    inc ebx
    mov esi,OFFSET math6
    call AddMathOne
;    
    ror ax,2
    inc ebx
    mov esi,OFFSET math7
    call AddMathOne
;    
    ret
AddCoproc     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           word reg tab
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

word_reg_tab1:
    DB ' TR='
    DW 0
    DB ' DT='
    DW OFFSET p_ldt
    DB 0

word_reg_tab2:
    DB ' CS='
    DW OFFSET p_cs
    DB ' DS='
    DW OFFSET p_ds
    DB ' ES='
    DW OFFSET p_es
    DB ' FS='
    DW OFFSET p_fs
    DB ' GS='
    DW OFFSET p_gs
    DB ' SS='
    DW OFFSET p_ss
    DB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dword reg tab
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dword_reg_tab1:
    DB ' EAX='
    DW OFFSET p_rax
    DB ' EBX='
    DW OFFSET p_rbx
    DB ' ECX='
    DW OFFSET p_rcx
    DB ' EDX='
    DW OFFSET p_rdx
    DB 0

dword_reg_tab2:
    DB ' ESI='
    DW OFFSET p_rsi
    DB ' EDI='
    DW OFFSET p_rdi
    DB ' ESP='
    DW OFFSET p_rsp
    DB ' EBP='
    DW OFFSET p_rbp
    DB 0

dword_reg_tab3:
    DB ' EPC='
    DW OFFSET p_rip
    DB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           qword reg tab
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

qword_reg_tab1:
    DB ' RAX='
    DW OFFSET p_rax
    DB ' RBX='
    DW OFFSET p_rbx
    DB ' RCX='
    DW OFFSET p_rcx
    DB 0

qword_reg_tab2:
    DB ' RDX='
    DW OFFSET p_rdx
    DB ' RSI='
    DW OFFSET p_rsi
    DB ' RDI='
    DW OFFSET p_rdi
    DB 0

qword_reg_tab3:
    DB '  R8='
    DW OFFSET p_r8
    DB '  R9='
    DW OFFSET p_r9
    DB ' R10='
    DW OFFSET p_r10
    DB 0

qword_reg_tab4:
    DB ' R11='
    DW OFFSET p_r11
    DB ' R12='
    DW OFFSET p_r12
    DB ' R13='
    DW OFFSET p_r13
    DB 0

qword_reg_tab5:
    DB ' R14='
    DW OFFSET p_r14
    DB ' R15='
    DW OFFSET p_r15
    DB 0

qword_reg_tab6:
    DB ' RIP='
    DW OFFSET p_rip
    DB ' RSP='
    DW OFFSET p_rsp
    DB ' RBP='
    DW OFFSET p_rbp
    DB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddProtCpuReg
;
;           DESCRIPTION:    Add protected mode registers
;
;           PARAMETERS:     ES:EDI              Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddProtCpuReg     Proc near
    mov esi,OFFSET dword_reg_tab1
    call AddDwordRegs    
    mov ecx,16
    call AddBlanks
    call AddNewLine
;
    mov esi,OFFSET dword_reg_tab2
    call AddDwordRegs
    mov ecx,16
    call AddBlanks
    call AddNewLine
;
    mov esi,OFFSET dword_reg_tab3
    call AddDwordRegs
;
    mov esi,OFFSET word_reg_tab1
    call AddWordRegs
    mov ecx,40
    call AddBlanks
    call AddNewLine
;
    mov esi,OFFSET word_reg_tab2
    call AddWordRegs
    call AddNewLine
;
    call AddEflags
    call AddNewLine
    ret
AddProtCpuReg     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddLongCpuReg
;
;           DESCRIPTION:    Add long mode CPU regs
;
;           PARAMETERS:     ES:EDI              Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddLongCpuReg     Proc near
    mov esi,OFFSET qword_reg_tab1
    call AddQwordRegs
    call AddNewLine
;
    mov esi,OFFSET qword_reg_tab2
    call AddQwordRegs
    call AddNewLine
;
    mov esi,OFFSET qword_reg_tab3
    call AddQwordRegs
    call AddNewLine
;
    mov esi,OFFSET qword_reg_tab4
    call AddQwordRegs
    call AddNewLine
;
    mov esi,OFFSET qword_reg_tab5
    call AddQwordRegs
    mov ecx,20
    call AddBlanks
    call AddNewLine
;
    mov esi,OFFSET qword_reg_tab6
    call AddQwordRegs
    call AddNewLine
;
    mov esi,OFFSET word_reg_tab2
    call AddWordRegs
    call AddNewLine
;
    call AddEflags
    call AddNewLine
    ret
AddLongCpuReg     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddStatus
;
;           DESCRIPTION:    Add status line
;
;           PARAMETERS:     ES:EDI              Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatus     Proc near
    call AddExceptionCode
;    
    mov al,' '
    stosb
;    
    call AddFault
    call AddNewLine
    ret
AddStatus     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddInstr
;
;           DESCRIPTION:    Add instruction
;
;           PARAMETERS:     ES:EDI              Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddInstr    Proc near
    mov ecx,40
    call DisAsmCode
    ret
AddInstr    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetProtCpu
;
;           DESCRIPTION:    Get prot CPU info
;
;           PARAMETERS:     ES:EDI              Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetProtCpu    PROC near
    call AddCoproc
    call AddDelimiter
    call AddProtCpuReg
    call AddDelimiter
    call AddFreeMem
    call AddStatus
    call AddInstr
    call AddThreadInfo
    call AddDelimiter
    call AddProtData
    ret
GetProtCpu    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetLongCpu
;
;           DESCRIPTION:    Get long CPU info
;
;           PARAMETERS:     ES:EDI              Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetLongCpu    PROC near
    mov ecx,5

glcPadLoop:
    push ecx
    mov ecx,70
    call AddBlanks
    call AddNewLine
    pop ecx
    loop glcPadLoop
;    
    call AddDelimiter
    call AddLongCpuReg
    call AddDelimiter
    call AddFreeMem
    call AddStatus
    call AddInstr
    call AddThreadInfo
    call AddDelimiter
    call AddLongData
    ret
GetLongCpu    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetRealCpu
;
;           DESCRIPTION:    Get realtime CPU info
;
;           PARAMETERS:     ES:EDI              Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRealCpu    PROC near
    mov ecx,5

grcPadLoop:
    push ecx
    mov ecx,70
    call AddBlanks
    call AddNewLine
    pop ecx
    loop grcPadLoop
;    
    call AddDelimiter
    call AddLongCpuReg
    call AddDelimiter
    call AddFreeMem
    call AddStatus
    call AddInstr
    call AddThreadInfo
    call AddDelimiter
    call AddLongData
    ret
GetRealCpu    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Read_mem
;
;           DESCRIPTION:    Read memory in process
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           DS:EBP      Cpu
;                           GS          Thread
;
;           RETURNS:        NC  AL  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_mem    Proc near
    push bx
;
    mov bx,gs
    test word ptr ds:[ebp].reg_eflags+2,2
    jz rdmProt

rdmV86:
    ReadThreadSegment
    jmp rdmDone
    
rdmProt:
    test ds:[ebp].reg_cs.d_access,ACCESS_64
    jnz rdm64

rdm32:    
    ReadThreadSelector
    jmp rdmDone

rdm64:
    ReadThread64

rdmDone:
    pop bx
    ret
read_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Write_mem
;
;           DESCRIPTION:    Write memory in process
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           GS          Thread
;                           DS:EBP      Cpu
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_mem    Proc near
    push bx
;
    mov bx,gs
    test word ptr ds:[ebp].reg_eflags+2,2
    jz wrmProt

wrmV86:
    WriteThreadSegment
    jmp wrmDone
    
wrmProt:
    test ds:[ebp].reg_cs.d_access,ACCESS_64
    jnz wrm64
    
wrm32:    
    WriteThreadSelector
    jmp wrmDone

wrm64:
    WriteThread64

wrmDone:
    pop bx
    ret
write_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapLinear
;
;           DESCRIPTION:    Map linear address for read
;
;           PARAMETERS:     EDX         Map address
;                           EDI:ESI     Linear address
;                           GS          Thread
;                           ES          Flat sel
;
;           RETURNS:        NC
;                               ES:EBX  Mapping
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapLinear       Proc near
    push eax
    push ebp
    push edi
    push esi
    mov ebp,esp
;
    mov eax,gs:p_cr3
    xor ebx,ebx
    or al,7
    SetPageEntry
;
    mov esi,[ebp+4]
    shr esi,4
    and esi,0FF8h
    add esi,edx
    mov eax,es:[esi]
    test al,1
    jz mlFail
;
    mov ebx,es:[esi+4]
    SetPageEntry
;    
    mov esi,[ebp]
    shr esi,27
    mov eax,[ebp+4]
    shl eax,5
    or si,ax
    and esi,0FF8h
    add esi,edx
    mov eax,es:[esi]
    test al,1
    jz mlFail
;
    mov ebx,es:[esi+4]
    SetPageEntry
;
    mov esi,[ebp]
    shr esi,18
    and esi,0FF8h
    add esi,edx
    mov eax,es:[esi]
    test al,1
    jz mlFail
;
    test al,80h
    jz mlGetPage
;
    mov ebx,es:[esi+4]
    mov esi,[ebp]
    shr esi,9
    and esi,0FF8h
    shl esi,9
    add eax,esi
    SetPageEntry
;
    mov ebx,[ebp]
    and ebx,0FFFh    
    add ebx,edx
    clc
    jmp mlDone

mlGetPage:
    mov ebx,es:[esi+4]
    SetPageEntry
;
    mov esi,[ebp]
    shr esi,9
    and esi,0FF8h
    add esi,edx
    mov eax,es:[esi]
    test al,1
    jz mlFail
;
    mov ebx,es:[esi+4]
    SetPageEntry
    mov ebx,[ebp]
    and ebx,0FFFh    
    add ebx,edx
    clc
    jmp mlDone

mlFail:
    stc

mlDone: 
    pop esi
    pop edi
    pop ebp
    pop eax
    ret
MapLinear       Endp           
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Read_real_mem
;
;           DESCRIPTION:    Read realtime memory
;
;           PARAMETERS:     DX:ESI      Address
;                           GS          Thread
;
;           RETURNS:        NC  AL  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_real_mem    Proc near
    push es
    push ebx
    push ecx
    push edx
    push edi
;
    mov ax,flat_sel
    mov es,eax
    mov edi,edx
    mov eax,1000h
    AllocateBigLinear
    call MapLinear
    jc rrmFail
;
    mov al,es:[ebx]
    jmp rrmDone

rrmFail:
    mov al,'%'

rrmDone:
    pushf
    push eax
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
    pop eax
;
    mov ecx,1000h
    FreeLinear
    popf
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
read_real_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Write_real_mem
;
;           DESCRIPTION:    Write realtime memory
;
;           PARAMETERS:     DX:ESI      Address
;                           GS          Thread
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_real_mem    Proc near
    push es
    push ebx
    push ecx
    push edx
    push edi
;
    push eax
    mov ax,flat_sel
    mov es,eax
    mov edi,edx
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    call MapLinear
    jc wrrmFail
;
    mov es:[ebx],al
    jmp wrrmDone

wrrmFail:
    mov al,'%'

wrrmDone:
    pushf
    push eax
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
    pop eax
;
    mov ecx,1000h
    FreeLinear
    popf
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
write_real_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Read_phys
;
;           DESCRIPTION:    Read physical memory
;
;           PARAMETERS:     EDX:ESI     Physical address
;
;           RETURNS:        NC  AL  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_phys    Proc near
    push ds
    push ebx
    push ecx
    push edx
    push esi
;
    mov ebx,flat_sel
    mov ds,ebx
;
    mov ebx,edx
    mov eax,1000h
    AllocateBigLinear
;
    mov eax,esi
    and ax,0F000h
    or al,7
    SetPageEntry
;
    and esi,0FFFh
    mov al,ds:[edx+esi]
;
    push ax
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
;
    mov ecx,1000h
    FreeLinear
    pop ax
    clc
;
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
read_phys    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Write_phys
;
;           DESCRIPTION:    Write physical memory
;
;           PARAMETERS:     EDX:ESI     Physical address
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_phys    Proc near
    push ds
    pushad
;
    mov ebx,flat_sel
    mov ds,ebx
;
    push eax
    mov ebx,edx
    mov eax,1000h
    AllocateBigLinear
;
    mov eax,esi
    and ax,0F000h
    or al,7
    SetPageEntry
    pop eax
;
    and esi,0FFFh
    mov ds:[edx+esi],al
;
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
;
    mov ecx,1000h
    FreeLinear
    clc
;
    popad
    pop ds
    ret
write_phys    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDebugThreadData
;
;           DESCRIPTION:    Get debug thread data
;
;           PARAMETERS:     GS          Debugged thread
;                           DS:EBP      Cpu
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetDebugThreadData

GetDebugThreadData      Proc near
    push es
    pushad
;    
    mov ax,ds
    mov es,ax
;    
    mov al,gs:p_realtime
    or al,al
    jnz getreal
;    
    mov es:[ebp].cpu_read_mem,OFFSET read_mem
    mov es:[ebp].cpu_write_mem,OFFSET write_mem
;
    mov es:[ebp].cpu_read_phys,OFFSET read_phys
    mov es:[ebp].cpu_write_phys,OFFSET write_phys
;    
    mov bx,gs:p_cs
    mov es:[ebp].reg_cs.d_selector,bx
    GetSelectorBitness
    cmp al,16
    je dis16
;
    cmp al,32
    je dis32

dis64:
    mov es:[ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_64
    jmp disdo

dis32:
    mov es:[ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_32
    jmp disdo

dis16:
    mov es:[ebp].reg_cs.d_access,ACCESS_READ
    jmp disdo

getreal:
    mov es:[ebp].cpu_read_mem,OFFSET read_real_mem
    mov es:[ebp].cpu_write_mem,OFFSET write_real_mem
;
    mov es:[ebp].cpu_read_phys,OFFSET read_phys
    mov es:[ebp].cpu_write_phys,OFFSET write_phys
;    
    mov bx,gs:p_cs
    mov es:[ebp].reg_cs.d_selector,bx
    mov es:[ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_64

disdo:    
    mov eax,dword ptr gs:p_rflags
    mov es:[ebp].reg_eflags,eax
;
    mov ax,gs:p_ldt
    mov es:[ebp].reg_ldt.d_selector,ax
;
    mov ax,gs:p_ss
    mov es:[ebp].reg_ss.d_selector,ax
;
    mov ax,gs:p_ds
    mov es:[ebp].reg_ds.d_selector,ax
;
    mov ax,gs:p_es
    mov es:[ebp].reg_es.d_selector,ax
;
    mov ax,gs:p_fs
    mov es:[ebp].reg_fs.d_selector,ax
;
    mov ax,gs:p_gs
    mov es:[ebp].reg_gs.d_selector,ax
;
    mov eax,dword ptr gs:p_rax
    mov es:[ebp].reg_eax,eax
    mov eax,dword ptr gs:p_rax+4
    mov es:[ebp].reg_eax+4,eax
;
    mov eax,dword ptr gs:p_rbx
    mov es:[ebp].reg_ebx,eax
    mov eax,dword ptr gs:p_rbx+4
    mov es:[ebp].reg_ebx+4,eax
;
    mov eax,dword ptr gs:p_rcx
    mov es:[ebp].reg_ecx,eax
    mov eax,dword ptr gs:p_rcx+4
    mov es:[ebp].reg_ecx+4,eax
;
    mov eax,dword ptr gs:p_rdx
    mov es:[ebp].reg_edx,eax
    mov eax,dword ptr gs:p_rdx+4
    mov es:[ebp].reg_edx+4,eax
;
    mov eax,dword ptr gs:p_rsi
    mov es:[ebp].reg_esi,eax
    mov eax,dword ptr gs:p_rsi+4
    mov es:[ebp].reg_esi+4,eax
;
    mov eax,dword ptr gs:p_rdi
    mov es:[ebp].reg_edi,eax
    mov eax,dword ptr gs:p_rdi+4
    mov es:[ebp].reg_edi+4,eax
;
    mov eax,dword ptr gs:p_rbp
    mov es:[ebp].reg_ebp,eax
    mov eax,dword ptr gs:p_rbp+4
    mov es:[ebp].reg_ebp+4,eax
;
    mov eax,dword ptr gs:p_rsp
    mov es:[ebp].reg_esp,eax
    mov eax,dword ptr gs:p_rsp+4
    mov es:[ebp].reg_esp+4,eax
;
    mov eax,dword ptr gs:p_rip
    mov es:[ebp].reg_eip,eax
    mov eax,dword ptr gs:p_rip+4
    mov es:[ebp].reg_eip+4,eax
;
    mov eax,dword ptr gs:p_r8
    mov es:[ebp].reg_r8,eax
    mov eax,dword ptr gs:p_r8+4
    mov es:[ebp].reg_r8+4,eax
;
    mov eax,dword ptr gs:p_r9
    mov es:[ebp].reg_r9,eax
    mov eax,dword ptr gs:p_r9+4
    mov es:[ebp].reg_r9+4,eax
;
    mov eax,dword ptr gs:p_r10
    mov es:[ebp].reg_r10,eax
    mov eax,dword ptr gs:p_r10+4
    mov es:[ebp].reg_r10+4,eax
;
    mov eax,dword ptr gs:p_r11
    mov es:[ebp].reg_r11,eax
    mov eax,dword ptr gs:p_r11+4
    mov es:[ebp].reg_r11+4,eax
;
    mov eax,dword ptr gs:p_r12
    mov es:[ebp].reg_r12,eax
    mov eax,dword ptr gs:p_r12+4
    mov es:[ebp].reg_r12+4,eax
;
    mov eax,dword ptr gs:p_r13
    mov es:[ebp].reg_r13,eax
    mov eax,dword ptr gs:p_r13+4
    mov es:[ebp].reg_r13+4,eax
;
    mov eax,dword ptr gs:p_r14
    mov es:[ebp].reg_r14,eax
    mov eax,dword ptr gs:p_r14+4
    mov es:[ebp].reg_r14+4,eax
;
    mov eax,dword ptr gs:p_r15
    mov es:[ebp].reg_r15,eax
    mov eax,dword ptr gs:p_r15+4
    mov es:[ebp].reg_r15+4,eax
;
    popad
    pop es
    ret
GetDebugThreadData      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCpu
;
;           DESCRIPTION:    Get CPU info
;
;           PARAMETERS:     GS                  Debug thread
;                           ES:EDI              Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetCpu
    
GetCpu  Proc near
    pushad
;    
    mov al,gs:p_realtime
    or al,al
    jnz gcReal
;
    mov ebp,OFFSET cpu
    call GetDebugThreadData
;
    mov ax,gs:p_tss_sel
    or ax,ax
    jz gcLong

gcProt:
    call GetProtCpu
    jmp gcDone

gcLong:
    call GetLongCpu
    jmp gcDone

gcReal:
    mov ebp,OFFSET cpu
    call GetDebugThreadData
    call GetRealCpu

gcDone:
    xor al,al
    stosb 
;
    popad
    ret
GetCpu  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadByte
;
;           DESCRIPTION:    Read byte value
;
;           PARAMETERS:     GS                  Debug thread
;                           DX:ESI              Address
;                           EDXH                Operation type (0000, F000 = long, 1000 = prot, 2000 = virt, 3000 = phys, 4000 = reg)
;
;           RETURNS:        AL                  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_long	Proc near
    mov al,gs:p_realtime
    or al,al
    jz read_long_norm
;
    call read_real_mem
    ret

read_long_norm:
    int 3
    ret
read_long	Endp

read_prot	Proc near
    push bx
    mov bx,gs
    ReadThreadSelector
    pop bx
    ret
read_prot	Endp

read_virt	Proc near
    push bx
    mov bx,gs
    ReadThreadSegment
    pop bx
    ret
read_virt	Endp

read_ph	Proc near
    push edx
    and edx,0FFFFFFFh
    call read_phys
    pop edx
    ret
read_ph	Endp

read_reg	Proc near
    mov al,gs:[esi]
    ret
read_reg	Endp

read_error	Proc near
    xor al,al
    ret
read_error	Endp

read_table:
ir0	DD OFFSET read_long
ir1	DD OFFSET read_prot
ir2	DD OFFSET read_virt
ir3	DD OFFSET read_ph
ir4	DD OFFSET read_reg
ir5	DD OFFSET read_error
ir6	DD OFFSET read_error
ir7	DD OFFSET read_error
ir8	DD OFFSET read_error
ir9	DD OFFSET read_error
irA	DD OFFSET read_error
irB	DD OFFSET read_error
irC	DD OFFSET read_error
irD	DD OFFSET read_error
irE	DD OFFSET read_error
irF	DD OFFSET read_long

read_byte	Proc near
    push ebx
;
    mov ebx,edx
    shr ebx,28
    shl ebx,2
    call near ptr cs:[ebx].read_table
;
    pop ebx
    ret
read_byte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteByte
;
;           DESCRIPTION:    write byte value
;
;           PARAMETERS:     GS                  Debug thread
;                           DX:ESI              Address
;                           EDXH                Operation type (0000, F000 = long, 1000 = prot, 2000 = virt, 3000 = phys, 4000 = reg)
;                           AL                  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_long	Proc near
    push eax
    mov al,gs:p_realtime
    or al,al
    pop eax
    jz write_long_norm
;
    call write_real_mem
    ret

write_long_norm:
    int 3
    ret
write_long	Endp

write_prot	Proc near
    push bx
    mov bx,gs
    WriteThreadSelector
    pop bx
    ret
write_prot	Endp

write_virt	Proc near
    push bx
    mov bx,gs
    WriteThreadSegment
    pop bx
    ret
write_virt	Endp

write_ph	Proc near
    push edx
    and edx,0FFFFFFFh
    call write_phys
    pop edx
    ret
write_ph	Endp

write_reg	Proc near
    mov gs:[esi],al
    ret
write_reg	Endp

write_error	Proc near
    ret
write_error	Endp

write_table:
iw0	DD OFFSET write_long
iw1	DD OFFSET write_prot
iw2	DD OFFSET write_virt
iw3	DD OFFSET write_ph
iw4	DD OFFSET write_reg
iw5	DD OFFSET write_error
iw6	DD OFFSET write_error
iw7	DD OFFSET write_error
iw8	DD OFFSET write_error
iw9	DD OFFSET write_error
iwA	DD OFFSET write_error
iwB	DD OFFSET write_error
iwC	DD OFFSET write_error
iwD	DD OFFSET write_error
iwE	DD OFFSET write_error
iwF	DD OFFSET write_long

write_byte	Proc near
    push ebx
;
    mov ebx,edx
    shr ebx,28
    shl ebx,2
    call near ptr cs:[ebx].write_table
;
    pop ebx
    ret
write_byte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           interact_inc
;
;           DESCRIPTION:    Interact increment
;
;           PARAMETERS:     GS          Thread
;                           DX:ESI      Adress to data
;                           CL          Number of digits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public interact_incr
    
interact_incr   PROC near
    push eax
    push esi
;
    xor eax,eax
    clc
    rcr cl,1
    mov al,cl
    pushf
    add esi,eax
    call read_byte
    popf
    jnc inc_low

inc_hi:
    add al,10h
    jmp inc_j

inc_low:
    mov ah,al
    inc al
    and al,0Fh
    and ah,0F0h
    or al,ah

inc_j:
    call write_byte
;
    pop esi
    pop eax
    ret
interact_incr   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           interact_dec
;
;           DESCRIPTION:    Interact decrement
;
;           PARAMETERS:     GS          Thread
;                           DX:ESI      Adress to data
;                           CL          Number of digits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public interact_decr
    
interact_decr   PROC near
    push eax
    push esi
;
    xor eax,eax
    clc
    rcr cl,1
    mov al,cl
    pushf
    add esi,eax
    call read_byte
    popf
    jnc dec_low

dec_hi:
    sub al,10h
    jmp dec_j

dec_low:
    mov ah,al
    dec al
    and al,0Fh
    and ah,0F0h
    or al,ah
    
dec_j:
    call write_byte
;
    pop esi
    pop eax
    ret
interact_decr   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           interact_set_value
;
;           DESCRIPTION:    Interact set new value
;
;           PARAMETERS:     GS          Thread
;                           DX:ESI      Adress to data
;                           CL          Digit #
;                           CH              Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public interact_set_value

interact_set_value     PROC near
    push eax
    push esi
;
    xor eax,eax
    clc
    rcr cl,1
    mov al,cl
    pushf
    add esi,eax
    call read_byte
    popf
    jnc set_low

set_hi:
    and al,0Fh
    mov ah,ch
    shl ah,4
    or al,ah
    jmp set_j

set_low:
    and al,0F0h
    or al,ch

set_j:
    call write_byte
;
    pop esi
    pop eax
    ret
interact_set_value      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           incdec16
;
;       DESCRIPTION:    INC / DEC
;
;       PARAMETERS:     GS      Thread
;                       DX:ESI  Address to data
;                       AL      operation ('+' och '-')
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

incdec16  PROC near
    mov fs,dx
    cmp al,'+'
    jne not_inc_reg16
;
    inc word ptr fs:[esi]
    ret
    
not_inc_reg16:
    cmp al,'-'
    jne not_dec_reg16
;
    dec word ptr fs:[esi]
    ret

not_dec_reg16:
    ret
incdec16  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           incdec32
;
;       DESCRIPTION:    INC / DEC
;
;       PARAMETERS:     GS      Thread
;                       DX:ESI  Address to data
;                       AL      operation ('+' och '-')
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

incdec32  PROC near
    mov fs,dx
    cmp al,'+'
    jne not_inc_reg32
;
    inc dword ptr fs:[esi]
    ret

not_inc_reg32:
    cmp al,'-'
    jne not_dec_reg32
;
    dec dword ptr fs:[esi]
    ret

not_dec_reg32:
    ret
incdec32  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           incdec64
;
;       DESCRIPTION:    INC / DEC
;
;       PARAMETERS:     GS      Thread
;                       DX:ESI  Address to data
;                       AL      operation ('+' och '-')
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

incdec64  PROC near
    mov fs,dx
    cmp al,'+'
    jne not_inc_reg64
;
    add dword ptr fs:[esi],1
    adc dword ptr fs:[esi+4],0
    ret

not_inc_reg64:
    cmp al,'-'
    jne not_dec_reg64
;
    sub dword ptr fs:[esi],1
    sbb dword ptr fs:[esi+4],0
    ret

not_dec_reg64:
    ret
incdec64  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           incdec_xx
;
;       DESCRIPTION:    INC / DEC reg
;
;       PARAMETERS:     GS      Thread
;                       AL      Operation ('+' och '-')
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public incdec_eax
        
incdec_eax:
    mov edx,gs
    mov esi,OFFSET p_rax
    jmp incdec32

    public incdec_ebx

incdec_ebx:
    mov edx,gs
    mov esi,OFFSET p_rbx
    jmp incdec32

    public incdec_ecx

incdec_ecx:
    mov edx,gs
    mov esi,OFFSET p_rcx
    jmp incdec32

    public incdec_edx

incdec_edx:
    mov edx,gs
    mov esi,OFFSET p_rdx
    jmp incdec32

    public incdec_esi

incdec_esi:
    mov edx,gs
    mov esi,OFFSET p_rsi
    jmp incdec32

    public incdec_edi

incdec_edi:
    mov edx,gs
    mov esi,OFFSET p_rdi
    jmp incdec32

    public incdec_esp

incdec_esp:
    mov edx,gs
    mov esi,OFFSET p_rsp
    jmp incdec32

    public incdec_ebp

incdec_ebp:
    mov edx,gs
    mov esi,OFFSET p_rbp
    jmp incdec32

    public incdec_epc

incdec_epc:
    mov edx,gs
    mov esi,OFFSET p_rip
    jmp incdec32

    public incdec_rip

incdec_rip:
    mov edx,gs
    mov esi,OFFSET p_rip
    jmp incdec64

    public incdec_rax

incdec_rax:
    mov edx,gs
    mov esi,OFFSET p_rax
    jmp incdec64

    public incdec_rbx

incdec_rbx:
    mov edx,gs
    mov esi,OFFSET p_rbx
    jmp incdec64

    public incdec_rcx

incdec_rcx:
    mov edx,gs
    mov esi,OFFSET p_rcx
    jmp incdec64

    public incdec_rdx

incdec_rdx:
    mov edx,gs
    mov esi,OFFSET p_rdx
    jmp incdec64

    public incdec_rsi

incdec_rsi:
    mov edx,gs
    mov esi,OFFSET p_rsi
    jmp incdec64

    public incdec_rdi

incdec_rdi:
    mov edx,gs
    mov esi,OFFSET p_rdi
    jmp incdec64

    public incdec_r8

incdec_r8:
    mov edx,gs
    mov esi,OFFSET p_r8
    jmp incdec64

    public incdec_r9

incdec_r9:
    mov edx,gs
    mov esi,OFFSET p_r9
    jmp incdec64

    public incdec_r10

incdec_r10:
    mov edx,gs
    mov esi,OFFSET p_r10
    jmp incdec64

    public incdec_r11

incdec_r11:
    mov edx,gs
    mov esi,OFFSET p_r11
    jmp incdec64

    public incdec_r12

incdec_r12:
    mov edx,gs
    mov esi,OFFSET p_r12
    jmp incdec64

    public incdec_r13

incdec_r13:
    mov edx,gs
    mov esi,OFFSET p_r13
    jmp incdec64

    public incdec_r14

incdec_r14:
    mov edx,gs
    mov esi,OFFSET p_r14
    jmp incdec64

    public incdec_r15

incdec_r15:
    mov edx,gs
    mov esi,OFFSET p_r15
    jmp incdec64

    public incdec_rbp

incdec_rbp:
    mov edx,gs
    mov esi,OFFSET p_rbp
    jmp incdec64

    public incdec_rsp

incdec_rsp:
    mov edx,gs
    mov esi,OFFSET p_rsp
    jmp incdec64

    public incdec_cs

incdec_cs:
    mov edx,gs
    mov esi,OFFSET p_cs
    jmp incdec16

    public incdec_ds

incdec_ds:
    mov edx,gs
    mov esi,OFFSET p_ds
    jmp incdec16

    public incdec_es

incdec_es:
    mov edx,gs
    mov esi,OFFSET p_es
    jmp incdec16

    public incdec_fs

incdec_fs:
    mov edx,gs
    mov esi,OFFSET p_fs
    jmp incdec16

    public incdec_gs

incdec_gs:
    mov edx,gs
    mov esi,OFFSET p_gs
    jmp incdec16

    public incdec_ss

incdec_ss:
    mov edx,gs
    mov esi,OFFSET p_ss
    jmp incdec16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Change_xxx
;
;           DESCRIPTION:    Change field callbacks
;
;           PARAMETERS:     GS          Thread
;                           EDI         Change procedure
;                           CL          Digit #
;                           CH          Value
;
;           RETURNS:        DX:ESI      Address to data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public change_eax
    
change_eax      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rax
    push edi
    ret
change_eax      ENDP

    public change_ebx

change_ebx      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rbx
    push edi
    ret
change_ebx      ENDP

    public change_ecx

change_ecx      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rcx
    push edi
    ret
change_ecx      ENDP

    public change_edx

change_edx      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rdx
    push edi
    ret
change_edx      ENDP

    public change_esi

change_esi      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rsi
    push edi
    ret
change_esi      ENDP

    public change_edi

change_edi      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rdi
    push edi
    ret
change_edi      ENDP

    public change_esp

change_esp      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rsp
    push edi
    ret
change_esp      ENDP

    public change_ebp

change_ebp      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rbp
    push edi
    ret
change_ebp      ENDP

    public change_epc

change_epc      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rip
    push edi
    ret
change_epc      ENDP

    public change_raxl

change_raxl      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rax
    push edi
    ret
change_raxl      ENDP

    public change_raxh

change_raxh      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rax + 4
    push edi
    ret
change_raxh      ENDP

    public change_rbxl

change_rbxl      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rbx
    push edi
    ret
change_rbxl      ENDP

    public change_rbxh

change_rbxh      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rbx + 4
    push edi
    ret
change_rbxh      ENDP

    public change_rcxl

change_rcxl      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rcx
    push edi
    ret
change_rcxl      ENDP

    public change_rcxh

change_rcxh      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rcx + 4
    push edi
    ret
change_rcxh      ENDP

    public change_rdxl

change_rdxl      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rdx
    push edi
    ret
change_rdxl      ENDP

    public change_rdxh

change_rdxh      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rdx + 4
    push edi
    ret
change_rdxh      ENDP

    public change_rsil

change_rsil      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rsi
    push edi
    ret
change_rsil      ENDP

    public change_rsih

change_rsih      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rsi + 4
    push edi
    ret
change_rsih      ENDP

    public change_rdil

change_rdil      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rdi
    push edi
    ret
change_rdil      ENDP

    public change_rdih

change_rdih      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rdi + 4
    push edi
    ret
change_rdih      ENDP

    public change_r8l

change_r8l      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r8
    push edi
    ret
change_r8l      ENDP

    public change_r8h

change_r8h      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r8 + 4
    push edi
    ret
change_r8h      ENDP

    public change_r9l

change_r9l      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r9
    push edi
    ret
change_r9l      ENDP

    public change_r9h

change_r9h      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r9 + 4
    push edi
    ret
change_r9h      ENDP

    public change_r10l

change_r10l      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r10
    push edi
    ret
change_r10l      ENDP

    public change_r10h

change_r10h      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r10 + 4
    push edi
    ret
change_r10h      ENDP

    public change_r11l

change_r11l      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r11
    push edi
    ret
change_r11l      ENDP

    public change_r11h

change_r11h      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r11 + 4
    push edi
    ret
change_r11h      ENDP

    public change_r12l

change_r12l      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r12
    push edi
    ret
change_r12l      ENDP

    public change_r12h

change_r12h      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r12 + 4
    push edi
    ret
change_r12h      ENDP

    public change_r13l

change_r13l      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r13
    push edi
    ret
change_r13l      ENDP

    public change_r13h

change_r13h      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r13 + 4
    push edi
    ret
change_r13h      ENDP

    public change_r14l

change_r14l      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r14
    push edi
    ret
change_r14l      ENDP

    public change_r14h

change_r14h      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r14 + 4
    push edi
    ret
change_r14h      ENDP

    public change_r15l

change_r15l      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r15
    push edi
    ret
change_r15l      ENDP

    public change_r15h

change_r15h      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_r15 + 4
    push edi
    ret
change_r15h      ENDP

    public change_ripl

change_ripl      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rip
    push edi
    ret
change_ripl      ENDP

    public change_riph

change_riph      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rip + 4
    push edi
    ret
change_riph      ENDP

    public change_rspl

change_rspl      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rsp
    push edi
    ret
change_rspl      ENDP

    public change_rsph

change_rsph      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rsp + 4
    push edi
    ret
change_rsph      ENDP

    public change_rbpl

change_rbpl      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rbp
    push edi
    ret
change_rbpl      ENDP

    public change_rbph

change_rbph      PROC near
    mov edx,40000000h
    mov esi,OFFSET p_rbp + 4
    push edi
    ret
change_rbph      ENDP

    public change_cs

change_cs       PROC near
    and cl,3
    mov edx,40000000h
    mov esi,OFFSET p_cs
    push edi
    ret
change_cs       ENDP

    public change_ds

change_ds       PROC near
    and cl,3
    mov edx,40000000h
    mov esi,OFFSET p_ds
    push edi
    ret
change_ds       ENDP

    public change_es

change_es       PROC near
    and cl,3
    mov edx,40000000h
    mov esi,OFFSET p_es
    push edi
    ret
change_es       ENDP

    public change_fs

change_fs       PROC near
    and cl,3
    mov edx,40000000h
    mov esi,OFFSET p_fs
    push edi
    ret
change_fs       ENDP

    public change_gs

change_gs       PROC near
    and cl,3
    mov edx,40000000h
    mov esi,OFFSET p_gs
    push edi
    ret
change_gs       ENDP

    public change_ss

change_ss       PROC near
    and cl,3
    mov edx,40000000h
    mov esi,OFFSET p_ss
    push edi
    ret
change_ss       ENDP

    public change_pm_sel
   
change_pm_sel   PROC near
    mov edx,40000000h
    and cl,3
    mov esi,OFFSET p_pm_deb_sel
    push cx
;    
    push OFFSET change_pm_sel_ret
    push edi
    ret
    
change_pm_sel_ret:
    pop cx
    or cl,cl
    jnz change_pm_sel_error
;
    inc ds:sw_col

change_pm_sel_error:
    ret
change_pm_sel   ENDP

    public change_pm_offs

change_pm_offs  PROC near
    mov edx,40000000h
    mov esi,OFFSET p_pm_deb_offs
    push cx
    push OFFSET change_pm_offs_ret
    push edi
    ret
    
change_pm_offs_ret:
    pop cx
    or cl,cl
    jnz change_pm_offs_error
;    
    inc ds:sw_col

change_pm_offs_error:
    ret
change_pm_offs  ENDP

    public change_phys_high

change_phys_high   PROC near
    mov edx,40000000h
    and cl,3
    mov esi,OFFSET p_deb_phys + 4
    push cx
;    
    push OFFSET change_phys_high_ret
    push edi
    ret
    
change_phys_high_ret:
    pop cx
;    
    or cl,cl
    jnz change_phys_high_error
;    
    inc ds:sw_col
    
change_phys_high_error:
    ret
change_phys_high   ENDP

    public change_phys_low

change_phys_low  PROC near
    mov edx,40000000h
    mov esi,OFFSET p_deb_phys
    push cx
;    
    push OFFSET change_phys_low_ret
    push edi
    ret
    
change_phys_low_ret:
    pop cx
;    
    or cl,cl
    jnz change_phys_low_error
;    
    inc ds:sw_col
    
change_phys_low_error:
    ret
change_phys_low  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Toggle_xxx
;
;           DESCRIPTION:    Toggle flag field callbacks
;
;           PARAMETERS:     GS          Thread
;                           EDI         Change procedure
;                           CL          Digit #
;                           CH          Value
;
;           RETURNS:        DX:ESI      Address to data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public toggle_cy

toggle_cy       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],1
    ret
toggle_cy       ENDP

    public toggle_pa

toggle_pa       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],4
    ret
toggle_pa       ENDP

    public toggle_ac

toggle_ac       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],10h
    ret
toggle_ac       ENDP

    public toggle_zr

toggle_zr       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],40h
    ret
toggle_zr       ENDP

    public toggle_pl

toggle_pl       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],80h
    ret
toggle_pl       ENDP

    public toggle_im

toggle_im       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],200h
    ret
toggle_im       ENDP

    public toggle_dir

toggle_dir      PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],400h
    ret
toggle_dir      ENDP

    public toggle_ov

toggle_ov       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],800h
    ret
toggle_ov       ENDP

    public toggle_nt

toggle_nt       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],4000h
    ret
toggle_nt       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           interact_set
;
;           DESCRIPTION:    Interact set new value
;
;           PARAMETERS:     GS          Thread
;                           DX:ESI      Adress to data
;                           CL          Digit #
;                           CH          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public interact_set

interact_set    PROC near
    call interact_set_value
    inc ds:sw_col
    ret
interact_set    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_xx
;
;           DESCRIPTION:    Memory operations
;
;           PARAMETERS:     GS          Thread
;                           DX:ESI      Adress to data
;                           EDXH        Type of operation (0000/F000 = long, 1000 = pm, 2000 = vm, 3000 = physical, 4000h = reg)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_do  PROC near
    mov cl,ds:sw_col
    sub cl,cs:[ebx+debug_col]
    mov bx,gs

mem_do_next:
    cmp cl,3
    jc mem_do_alloc
;    
    sub cl,3
    inc esi
    jmp mem_do_next

mem_do_alloc:
    cmp cl,2
    je mem_do_end
;
    xor cl,1
    push cx
;    
    push OFFSET mem_do_free
    push edi
    ret

mem_do_free:
    pop cx
    or cl,cl
    jnz mem_do_end
;    
    inc ds:sw_col

mem_do_end:     
    ret
mem_do  ENDP

    public mem_ads

mem_ads PROC near
    ret
mem_ads ENDP

    public mem_cs
    
mem_cs  PROC near
    mov al,gs:p_realtime
    or al,al
    jnz mem_cs64
;
    mov bx,gs:p_cs
    IsLongCodeSelector
    jc mem_cs32

mem_cs64:    
    mov edx,dword ptr gs:p_rip+4
    mov esi,dword ptr gs:p_rip
    call mem_do
    ret

mem_cs32:
    test word ptr ds:[ebp].reg_eflags+2,2
    jz mem_cspm
;
    mov edx,20000000h
    mov dx,gs:p_cs
    movzx esi,word ptr gs:p_rip
    call mem_do
    ret

mem_cspm:
    mov edx,10000000h
    mov dx,gs:p_cs
    mov esi,dword ptr gs:p_rip
    call mem_do
    ret
mem_cs  ENDP

    public mem_ss

mem_ss  PROC near
    mov al,gs:p_realtime
    or al,al
    jnz mem_ss64
;
    mov bx,gs:p_cs
    IsLongCodeSelector
    jc mem_ss32

mem_ss64:    
    mov edx,dword ptr gs:p_rsp+4
    mov esi,dword ptr gs:p_rsp
    call mem_do
    ret

mem_ss32:
    test word ptr ds:[ebp].reg_eflags+2,2
    jz mem_sspm
;
    mov edx,20000000h
    mov dx,gs:p_ss
    movzx esi,word ptr gs:p_rsp
    call mem_do
    ret

mem_sspm:
    mov edx,10000000h
    mov dx,gs:p_ss
    mov esi,dword ptr gs:p_rsp
    call mem_do
    ret
mem_ss  ENDP

    public mem_es

mem_es  PROC near
    mov al,gs:p_realtime
    or al,al
    jnz mem_es64
;
    mov bx,gs:p_cs
    IsLongCodeSelector
    jc mem_es32

mem_es64:    
    mov edx,dword ptr gs:p_rdi+4
    mov esi,dword ptr gs:p_rdi
    call mem_do
    ret

mem_es32:
    test word ptr ds:[ebp].reg_eflags+2,2
    jz mem_espm
;
    mov edx,20000000h
    mov dx,gs:p_es
    xor esi,esi
    call mem_do
    ret

mem_espm:
    mov edx,10000000h
    mov dx,gs:p_es
    xor esi,esi
    call mem_do
    ret
mem_es  ENDP

    public mem_pm

mem_pm  PROC near
    mov al,gs:p_realtime
    or al,al
    jnz mem_real
;    
    mov edx,10000000h
    mov dx,gs:p_pm_deb_sel
    mov esi,gs:p_pm_deb_offs
    call mem_do
    ret

mem_real:
    movsx edx,gs:p_pm_deb_sel
    mov esi,gs:p_pm_deb_offs
    call mem_do
    ret
mem_pm  ENDP

    public mem_phys

mem_phys  PROC near
    mov eax,30000000h
    mov edx,gs:p_deb_phys+4
    and edx,0FFFFFFFh
    or edx,eax
    mov esi,gs:p_deb_phys
    call mem_do
    ret
mem_phys  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           debug_call_do32
;
;           DESCRIPTION:    Perform a function
;
;           PARAMETERS:     GS              Thread
;                           EDI             Offset to debug-function
;                           CH              Digit / param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
debug_table32:
;
;           rad     kolumn  antal   action
;
meax32 DD 9,          1,          3,          OFFSET incdec_eax
deax32 DD 9,          5,          8,          OFFSET change_eax
mebx32 DD 9,          14,         3,          OFFSET incdec_ebx
debx32 DD 9,          18,         8,          OFFSET change_ebx
mecx32 DD 9,          27,         3,          OFFSET incdec_ecx
decx32 DD 9,          31,         8,          OFFSET change_ecx
medx32 DD 9,          40,         3,          OFFSET incdec_edx
dedx32 DD 9,          44,         8,          OFFSET change_edx
mesi32 DD 10,         1,          3,          OFFSET incdec_esi
desi32 DD 10,         5,          8,          OFFSET change_esi
medi32 DD 10,         14,         3,          OFFSET incdec_edi
dedi32 DD 10,         18,         8,          OFFSET change_edi
mesp32 DD 10,         27,         3,          OFFSET incdec_esp
desp32 DD 10,         31,         8,          OFFSET change_esp
mebp32 DD 10,         40,         3,          OFFSET incdec_ebp
debp32 DD 10,         44,         8,          OFFSET change_ebp
mepc32 DD 11,         1,          3,          OFFSET incdec_epc
depc32 DD 11,         5,          8,          OFFSET change_epc
mcs32  DD 12,         1,          2,          OFFSET incdec_cs
dcs32  DD 12,         4,          4,          OFFSET change_cs
mds32  DD 12,         9,          2,          OFFSET incdec_ds
dds32  DD 12,         12,         4,          OFFSET change_ds
mes32  DD 12,         17,         2,          OFFSET incdec_es
des32  DD 12,         20,         4,          OFFSET change_es
mfs32  DD 12,         25,         2,          OFFSET incdec_fs
dfs32  DD 12,         28,         4,          OFFSET change_fs
mgs32  DD 12,         33,         2,          OFFSET incdec_gs
dgs32  DD 12,         36,         4,          OFFSET change_gs
mss32  DD 12,         41,         2,          OFFSET incdec_ss
dss32  DD 12,         44,         4,          OFFSET change_ss
dcy32  DD 13,         0,          2,          OFFSET toggle_cy
dpa32  DD 13,         3,          2,          OFFSET toggle_pa
dac32  DD 13,         6,          2,          OFFSET toggle_ac
dzr32  DD 13,         9,          2,          OFFSET toggle_zr
dplc32 DD 13,         12,         2,          OFFSET toggle_pl
disf32 DD 13,         15,         2,          OFFSET toggle_im
ddir32 DD 13,         18,         2,          OFFSET toggle_dir
dov32  DD 13,         21,         2,          OFFSET toggle_ov
dnt32  DD 13,         24,         2,          OFFSET toggle_nt
mdad32 DD 19,         14,         47,         OFFSET mem_ads
mdcs32 DD 20,         14,         47,         OFFSET mem_cs
mdss32 DD 21,         14,         47,         OFFSET mem_ss
mdes32 DD 22,         14,         47,         OFFSET mem_es
pms32  DD 23,         0,          4,          OFFSET change_pm_sel
pmo32  DD 23,         5,          8,          OFFSET change_pm_offs
pdat32 DD 23,         14,         47,         OFFSET mem_pm
vms32  DD 24,         0,          4,          OFFSET change_phys_high
vmo32  DD 24,         5,          8,          OFFSET change_phys_low
vdat32 DD 24,         14,         47,         OFFSET mem_phys
dend32 DD 0FFFFFFFFh, 0FFFFFFFFh

debug_call_do32   PROC near
    mov ebx,OFFSET debug_table32
    mov al,ds:sw_col
    mov ah,ds:sw_row

d_c_loop32:
    mov cl,cs:[ebx+debug_row]
    cmp cl,0FFh
    je d_c_end32
;    
    cmp cl,ah
    jne not_this_entry32
;    
    mov cl,al
    sub cl,cs:[ebx+debug_col]
    cmp cl,cs:[ebx+debug_ant]
    jnc not_this_entry32
;
    xor cl,7
    and cl,7
    mov ax,ds:sw_func_code
    jmp dword ptr cs:[ebx+debug_call]
    
not_this_entry32:
    add ebx,debug_size
    jmp d_c_loop32

d_c_end32:
    ret
debug_call_do32   ENDP

inc_sw32  PROC near
    pushad
    mov edi,OFFSET interact_incr
    call debug_call_do32
    popad
    ret
inc_sw32  ENDP

dec_sw32  PROC near
    pushad
    mov edi,OFFSET interact_decr
    call debug_call_do32
    popad
    ret
dec_sw32  ENDP

;
; ch = siffra
;
set_base_sw32     PROC near
    pushad
    mov edi,OFFSET interact_set
    call debug_call_do32
    popad
    ret
set_base_sw32     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           debug_call_do64
;
;           DESCRIPTION:    Perform a function
;
;           PARAMETERS:     GS              Thread
;                           EDI             Offset to debug-function
;                           CH              Digit / param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
debug_table64:
;
;           rad     kolumn  antal   action
;
mrax   DD 6,          1,          3,          OFFSET incdec_rax
draxh  DD 6,          5,          8,          OFFSET change_raxh
draxl  DD 6,          14,         8,          OFFSET change_raxl
mrbx   DD 6,          23,         3,          OFFSET incdec_rbx
drbxh  DD 6,          27,         8,          OFFSET change_rbxh
drbxl  DD 6,          36,         8,          OFFSET change_rbxl
mrcx   DD 6,          45,         3,          OFFSET incdec_rcx
drcxh  DD 6,          49,         8,          OFFSET change_rcxh
drcxl  DD 6,          58,         8,          OFFSET change_rcxl
mrdx   DD 7,          1,          3,          OFFSET incdec_rdx
drdxh  DD 7,          5,          8,          OFFSET change_rdxh
drdxl  DD 7,          14,         8,          OFFSET change_rdxl
mrsi   DD 7,          23,         3,          OFFSET incdec_rsi
drsih  DD 7,          27,         8,          OFFSET change_rsih
drsil  DD 7,          36,         8,          OFFSET change_rsil
mrdi   DD 7,          45,         3,          OFFSET incdec_rdi
drdih  DD 7,          49,         8,          OFFSET change_rdih
drdil  DD 7,          58,         8,          OFFSET change_rdil
mr8    DD 8,          2,          2,          OFFSET incdec_r8
dr8h   DD 8,          5,          8,          OFFSET change_r8h
dr8l   DD 8,          14,         8,          OFFSET change_r8l
mr9    DD 8,          24,         2,          OFFSET incdec_r9
dr9h   DD 8,          27,         8,          OFFSET change_r9h
dr9l   DD 8,          36,         8,          OFFSET change_r9l
mr10   DD 8,          45,         3,          OFFSET incdec_r10
dr10h  DD 8,          49,         8,          OFFSET change_r10h
dr10l  DD 8,          58,         8,          OFFSET change_r10l
mr11   DD 9,          1,          3,          OFFSET incdec_r11
dr11h  DD 9,          5,          8,          OFFSET change_r11h
dr11l  DD 9,          14,         8,          OFFSET change_r11l
mr12   DD 9,          23,         3,          OFFSET incdec_r12
dr12h  DD 9,          27,         8,          OFFSET change_r12h
dr12l  DD 9,          36,         8,          OFFSET change_r12l
mr13   DD 9,          45,         3,          OFFSET incdec_r13
dr13h  DD 9,          49,         8,          OFFSET change_r13h
dr13l  DD 9,          58,         8,          OFFSET change_r13l
mr14   DD 10,         1,          3,          OFFSET incdec_r14
dr14h  DD 10,         5,          8,          OFFSET change_r14h
dr14l  DD 10,         14,         8,          OFFSET change_r14l
mr15   DD 10,         23,         3,          OFFSET incdec_r15
dr15h  DD 10,         27,         8,          OFFSET change_r15h
dr15l  DD 10,         36,         8,          OFFSET change_r15l
mrip64 DD 11,         1,          3,          OFFSET incdec_rip
driph  DD 11,         5,          8,          OFFSET change_riph
dripl  DD 11,         14,         8,          OFFSET change_ripl
mrsp64 DD 11,         23,         3,          OFFSET incdec_rsp
drsph  DD 11,         27,         8,          OFFSET change_rsph
drspl  DD 11,         36,         8,          OFFSET change_rspl
mrsb64 DD 11,         45,         3,          OFFSET incdec_rbp
drbph  DD 11,         49,         8,          OFFSET change_rbph
drbpl  DD 11,         58,         8,          OFFSET change_rbpl
mcs64  DD 12,         1,          2,          OFFSET incdec_cs
dcs64  DD 12,         4,          4,          OFFSET change_cs
mds64  DD 12,         9,          2,          OFFSET incdec_ds
dds64  DD 12,         12,         4,          OFFSET change_ds
mes64  DD 12,         17,         2,          OFFSET incdec_es
des64  DD 12,         20,         4,          OFFSET change_es
mfs64  DD 12,         25,         2,          OFFSET incdec_fs
dfs64  DD 12,         28,         4,          OFFSET change_fs
mgs64  DD 12,         33,         2,          OFFSET incdec_gs
dgs64  DD 12,         36,         4,          OFFSET change_gs
mss64  DD 12,         41,         2,          OFFSET incdec_ss
dss64  DD 12,         44,         4,          OFFSET change_ss
dcy64  DD 13,         0,          2,          OFFSET toggle_cy
dpa64  DD 13,         3,          2,          OFFSET toggle_pa
dac64  DD 13,         6,          2,          OFFSET toggle_ac
dzr64  DD 13,         9,          2,          OFFSET toggle_zr
dplc64 DD 13,         12,         2,          OFFSET toggle_pl
disf64 DD 13,         15,         2,          OFFSET toggle_im
ddir64 DD 13,         18,         2,          OFFSET toggle_dir
dov64  DD 13,         21,         2,          OFFSET toggle_ov
dnt64  DD 13,         24,         2,          OFFSET toggle_nt
mdad64 DD 19,         14,         47,         OFFSET mem_ads
mdcs64 DD 20,         14,         47,         OFFSET mem_cs
mdss64 DD 21,         14,         47,         OFFSET mem_ss
mdes64 DD 22,         14,         47,         OFFSET mem_es
pms64  DD 23,         0,          4,          OFFSET change_pm_sel
pmo64  DD 23,         5,          8,          OFFSET change_pm_offs
pdat64 DD 23,         14,         47,         OFFSET mem_pm
vms64  DD 24,         0,          4,          OFFSET change_phys_high
vmo64  DD 24,         5,          8,          OFFSET change_phys_low
vdat64 DD 24,         14,         47,         OFFSET mem_phys
dend64 DD 0FFFFFFFFh, 0FFFFFFFFh

debug_call_do64   PROC near
    mov ebx,OFFSET debug_table64
    mov al,ds:sw_col
    mov ah,ds:sw_row

d_c_loop64:
    mov cl,cs:[ebx+debug_row]
    cmp cl,0FFh
    je d_c_end64
;    
    cmp cl,ah
    jne not_this_entry64
;
    mov cl,al
    sub cl,cs:[ebx+debug_col]
    cmp cl,cs:[ebx+debug_ant]
    jnc not_this_entry64
;
    xor cl,7
    and cl,7
    mov ax,ds:sw_func_code
    jmp dword ptr cs:[ebx+debug_call]
    
not_this_entry64:
    add ebx,debug_size
    jmp d_c_loop64
    
d_c_end64:
    ret
debug_call_do64   ENDP

inc_sw64  PROC near
    pushad
    mov edi,OFFSET interact_incr
    call debug_call_do64
    popad
    ret
inc_sw64  ENDP

dec_sw64  PROC near
    pushad
    mov edi,OFFSET interact_decr
    call debug_call_do64
    popad
    ret
dec_sw64  ENDP

;
; ch = siffra
;
set_base_sw64     PROC near
    pushad
    mov edi,OFFSET interact_set
    call debug_call_do64
    popad
    ret
set_base_sw64     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Interact functions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public inc_sw

inc_sw:
    mov ax,gs:p_tss_sel
    or ax,ax
    jz inc_sw64
    jmp inc_sw32

    public dec_sw

dec_sw:
    mov ax,gs:p_tss_sel
    or ax,ax
    jz dec_sw64
    jmp dec_sw32

    public set0_sw

set0_sw:
    mov ch,0
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public set1_sw

set1_sw:
    mov ch,1
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public set2_sw

set2_sw:
    mov ch,2
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public set3_sw

set3_sw:
    mov ch,3
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public set4_sw

set4_sw:
    mov ch,4
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public set5_sw

set5_sw:
    mov ch,5
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public set6_sw

set6_sw:
    mov ch,6
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public set7_sw

set7_sw:
    mov ch,7
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public set8_sw

set8_sw:
    mov ch,8
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public set9_sw

set9_sw:
    mov ch,9
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public setA_sw

setA_sw:
    mov ch,0Ah
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public setB_sw

setB_sw:
    mov ch,0Bh
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public setC_sw

setC_sw:
    mov ch,0Ch
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public setD_sw

setD_sw:
    mov ch,0Dh
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public setE_sw

setE_sw:
    mov ch,0Eh
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

    public setF_sw

setF_sw:
    mov ch,0Fh
    mov ax,gs:p_tss_sel
    or ax,ax
    jz set_base_sw64
    jmp set_base_sw32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_os_pos
;
;           DESCRIPTION:    Set os pos
;
;           PARAMETERS:     DS      Data 
;                           AX      Function #
;                           DL      Col
;                           DH      Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public set_os_pos

set_os_pos    Proc near
    mov ds:sw_func_code,ax
    mov ds:sw_row,dh
    mov ds:sw_col,dl
    ret
set_os_pos    Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_os_pos
;
;           DESCRIPTION:    Get os pos
;
;           PARAMETERS:     DS      Data
; 
;           RETURNS:        AX      Function #
;                           DL      Col
;                           DH      Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_os_pos

get_os_pos    Proc near
    mov ax,ds:sw_func_code
    mov dl,ds:sw_col
    mov dh,ds:sw_row
    ret
get_os_pos    Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugReadByte
;
;           DESCRIPTION:    Read byte in target process
;
;           PARAMETERS:     EDX:ESI	Address
;                           BX		Selector
;                           GS		Thread
; 
;           RETURNS:        AL		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DebugReadByte    Proc near
    mov al,gs:p_realtime
    or al,al
    jnz drbReal
;
    push bx
    mov bx,gs:p_cs
    IsLongCodeSelector
    pop bx
    jc drb32

drb64:    
    int 3
    ret

drb32:
    mov dx,bx
    test word ptr gs:p_rflags+2,2
    jz drbPm

drbVm:
    push bx
    mov bx,gs
    ReadThreadSegment
    pop bx
    ret

drbPm:
    push bx
    mov bx,gs
    ReadThreadSelector
    pop bx
    ret

drbReal:
    call read_real_mem
    ret
DebugReadByte	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugReadWord
;
;           DESCRIPTION:    Read word in target process
;
;           PARAMETERS:     EDX:ESI	Address
;                           BX		Selector
;                           GS		Thread
; 
;           RETURNS:        AX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DebugReadWord    Proc near
    push edx
    push esi
;
    call DebugReadByte
;
    push eax
    inc esi
    call DebugReadByte
    mov dl,al
    pop eax
    mov ah,dl
;
    pop esi
    pop edx
    ret
DebugReadWord	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugWriteWord
;
;           DESCRIPTION:    Write word in target process
;
;           PARAMETERS:     EDX:ESI	Address
;                           BX		Selector
;                           GS		Thread
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DebugWriteByte    Proc near
    push ax
    mov al,gs:p_realtime
    or al,al
    pop ax
    jnz dwbReal
;
    push bx
    mov bx,gs:p_cs
    IsLongCodeSelector
    pop bx
    jc dwb32

dwb64:    
    int 3
    ret

dwb32:
    mov dx,bx
    test word ptr gs:p_rflags+2,2
    jz dwbPm

dwbVm:
    push bx
    mov bx,gs
    WriteThreadSegment
    pop bx
    ret

dwbPm:
    push bx
    mov bx,gs
    WriteThreadSelector
    pop bx
    ret

dwbReal:
    call write_real_mem
    ret
DebugWriteByte	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugWriteWord
;
;           DESCRIPTION:    Write word in target process
;
;           PARAMETERS:     EDX:ESI	Address
;                           BX		Selector
;                           GS		Thread
;                           AX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DebugWriteWord    Proc near
    push eax
    push esi
;
    call DebugWriteByte
;
    mov al,ah
    inc esi
    call DebugWriteByte
;
    pop esi
    pop eax
    ret
DebugWriteWord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugWakeup
;
;           DESCRIPTION:    Wakeup debugged thread
;
;           PARAMETERS:     GS      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DebugWakeup    Proc near
    push ax
;
    mov al,gs:p_realtime
    or al,al
    jz dwLocal
;
    push fs
    mov fs,gs:p_core
    RunRealtime
;
    cli
    mov al,21h
    SendLockedInt
    pop fs
    jmp dwDone

dwLocal:
    push ds
    push es
    pushad
;
    mov bx,gs
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov [si],bx
    mov es,ax
    Wake
;
    popad
    pop es
    pop ds

dwDone:
    pop ax
    ret
DebugWakeup	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_trace
;
;           DESCRIPTION:    Trace
;
;           PARAMETERS:     GS      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_trace

do_trace    Proc near
    pushad
;
    push fs
    mov fs,gs:p_core
    mov bx,fs:cs_null_thread
    pop fs
;
    mov ax,gs
    cmp ax,bx
    jne debug_trace_normal
;
    mov al,gs:p_realtime
    or al,al
    jz debug_trace_done

debug_trace_normal:
    mov bx,gs:p_cs
    mov esi,dword ptr gs:p_rip
    mov edx,dword ptr gs:p_rip+4
    call DebugReadWord
;
    cmp ax,485Ch
    jne debug_trace_not_sysret
;
    push ax
    add esi,2
    call DebugReadWord
    mov dx,ax
    pop ax
    cmp dx,070Fh
    jne debug_trace_not_sysret  
;
    or word ptr gs:p_r11,100h      
    mov ax,word ptr gs:p_rflags
    and ax,NOT 100h
    mov word ptr gs:p_rflags,ax
    jmp debug_trace_go

debug_trace_not_sysret:        
    cmp al,0CDh
    jne debug_trace_not_int
;
    test word ptr gs:p_rflags+2,2
    jz debug_trace_trace
;
    int 3
    jmp debug_trace_done

debug_trace_not_int:
    cmp ax,0CF48h
    jne debug_trace_trace
;
    mov al,gs:p_realtime
    or al,al
    jz debug_trace_trace
;
    mov bx,gs:p_ss
    mov esi,dword ptr gs:p_rsp
    mov edx,dword ptr gs:p_rsp+4
    add esi,10h
    call DebugReadWord
    or ax,100h
    call DebugWriteWord
    jmp debug_trace_trace

debug_trace_trace:
    mov eax,dword ptr gs:p_dr7
    and ax,0FFFCh
    mov dword ptr gs:p_dr7,eax
    mov ax,word ptr gs:p_rflags
    or ax,100h
    mov word ptr gs:p_rflags,ax

debug_trace_go:
    call DebugWakeup

debug_trace_done:
    popad
    ret
do_trace     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_pace
;
;           DESCRIPTION:    Pace
;
;           PARAMETERS:     GS      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_pace

do_pace    Proc near
    pushad
;
    push fs
    mov fs,gs:p_core
    mov bx,fs:cs_null_thread
    pop fs
;
    mov ax,gs
    cmp ax,bx
    jne debug_pace_normal
;
    mov cl,1
    mov al,gs:p_realtime
    or al,al
    jnz debug_pace_bitness_done
    jz debug_pace_done

debug_pace_normal:
    xor cl,cl
    mov bx,gs:p_cs
    test byte ptr gs:p_rflags+2,2
    jnz debug_pace_bitness_done
;
    push ds
    test bx,4
    jz debug_pace_bitness_gdt

debug_pace_bitness_ldt:
    mov ds,gs:p_ldt_sel
    jmp debug_pace_bitness_get

debug_pace_bitness_gdt:
    mov ax,gdt_sel
    mov ds,ax

debug_pace_bitness_get:
    and bx,0FFF8h
    mov cl,ds:[bx+6]
    mov ch,cl
    shr cl,6
    and cl,1
    shr ch,5
    and ch,1
    or cl,ch
    pop ds

debug_pace_bitness_done:
    mov bx,gs:p_cs
    mov esi,dword ptr gs:p_rip
    mov edx,dword ptr gs:p_rip+4
    call DebugReadWord
;
    cmp ax,485Ch
    jne debug_pace_not_sysret
;
    push ax
    push esi
    add esi,2
    adc edx,0
    call DebugReadWord
    cmp ax,070Fh
    pop esi
    pop ax  
    jne debug_pace_not_sysret  
;
    or word ptr gs:p_r11,100h      
    mov ax,word ptr gs:p_rflags
    and ax,NOT 100h
    mov word ptr gs:p_rflags,ax
    jmp debug_pace_go

debug_pace_not_sysret:            
    xor ebx,ebx
    add bx,2
    cmp ax,50Fh
    je debug_pace_step
;    
    cmp al,0E2h
    je debug_pace_step
;
    cmp al,0CDh
    je debug_pace_step
;    
    inc bx
    test cl,1
    jz debug_pace_size_ok
;
    add bx,2

debug_pace_size_ok:    
    cmp al,0E8h
    je debug_pace_step
;
    xor ebx,ebx

debug_pace_far_loop:
    mov esi,dword ptr gs:p_rip
    mov edx,dword ptr gs:p_rip+4
    add esi,ebx
    push ebx
    mov bx,gs:p_cs
    call DebugReadWord
    pop ebx
;
    cmp al,66h
    je debug_pace_far_ov66
;
    cmp al,3Eh
    je debug_pace_far_ov3e    
;   
    cmp al,67h
    je debug_pace_far_ov67 
;
    cmp al,9Ah
    je debug_pace_far_call
;
    jmp debug_pace_trace   

debug_pace_far_ov66:
    inc ebx
    xor cl,1
    jmp debug_pace_far_loop

debug_pace_far_ov67:
    inc ebx
    jmp debug_pace_far_loop

debug_pace_far_ov3e:
    inc ebx
    jmp debug_pace_far_loop    

debug_pace_far_call:
    add ebx,5
    test cl,1
    jz debug_pace_step
;
    add ebx,2
    
debug_pace_step:
    mov al,gs:p_realtime
    or al,al
    jz debug_pace_local
;
    mov eax,dword ptr gs:p_rip
    jmp debug_pace_step_go

debug_pace_local:
    mov ax,word ptr gs:p_rflags+2
    test ax,2
    jz debug_pace_step_prot    
;
    xor eax,eax
    xor edx,edx
    mov ax,gs:p_cs
    shl eax,4
    mov dx,word ptr gs:p_rip
    add eax,edx
    jmp debug_pace_step_go
    
debug_pace_step_prot:
    mov si,gs:p_cs
    test si,4
    jz debug_pace_step_gdt
;
    push ds
    xor eax,eax
    mov ds,gs:p_ldt_sel
    mov si,gs:p_cs
    and si,0FFF8h
    mov eax,[si+2]
    rol eax,8
    mov al,[si+7]
    ror eax,8
    add eax,dword ptr gs:p_rip
    pop ds
    jmp debug_pace_step_go

debug_pace_step_gdt:
    push ds
    and si,0FFF8h
    mov ax,gdt_sel
    mov ds,ax    
    mov eax,[si+2]
    rol eax,8
    mov al,[si+7]
    ror eax,8
    add eax,dword ptr gs:p_rip
    pop ds

debug_pace_step_go:
    add eax,ebx
    mov dword ptr gs:p_dr0,eax
    mov eax,dword ptr gs:p_rip+4
    mov dword ptr gs:p_dr0+4,eax    
    mov eax,dword ptr gs:p_dr7
    and eax,0FFF0FFFCh
    or ax,1
    mov dword ptr gs:p_dr7,eax
    mov ax,word ptr gs:p_rflags
    and ax,NOT 100h
    mov word ptr gs:p_rflags,ax
    or gs:p_flags,THREAD_FLAG_BP
    jmp debug_pace_go
    
debug_pace_trace:
    mov eax,dword ptr gs:p_dr7
    and ax,0FFFCh
    mov dword ptr gs:p_dr7,eax
    mov ax,word ptr gs:p_rflags
    or ax,100h
    mov word ptr gs:p_rflags,ax

debug_pace_go:
    call DebugWakeup

debug_pace_done:
    popad
    ret
do_pace	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_go
;
;           DESCRIPTION:    Go
;
;           PARAMETERS:     GS      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_go

do_go    Proc near
    pushad
;
    push fs
    mov fs,gs:p_core
    mov bx,fs:cs_null_thread
    pop fs
;
    mov ax,gs
    cmp ax,bx
    jne debug_go_normal
;
    mov al,gs:p_realtime
    or al,al
    jz debug_go_done

debug_go_normal:
    mov eax,dword ptr gs:p_dr7
    and ax,0FFFCh
    mov dword ptr gs:p_dr7,eax
    mov ax,word ptr gs:p_rflags
    and ax,NOT 100h
    mov word ptr gs:p_rflags,ax

debug_go_go:
    call DebugWakeup

debug_go_done:
    popad
    ret
do_go     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_run
;
;           DESCRIPTION:    Run
;
;           PARAMETERS:     GS      Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_run

do_run    Proc near
    pushad
;
    push fs
    mov fs,gs:p_core
    mov bx,fs:cs_null_thread
    pop fs
;
    mov ax,gs
    cmp ax,bx
    jne debug_run_normal
;
    mov al,gs:p_realtime
    or al,al
    jz debug_run_done

debug_run_normal:
    mov ax,word ptr gs:p_rflags
    and ax,NOT 100h
    mov word ptr gs:p_rflags,ax

debug_run_go:
    call DebugWakeup

debug_run_done:
    popad
    ret
do_run     ENDP

code    ENDS

    END
