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
INCLUDE dis.inc

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
    mov eax,gs:p_fault_code
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
    mov ds:[ebp].reg_eflags,20000h
    mov dx,gs:p_vm_deb_sel
    mov esi,gs:p_vm_deb_offs
    call AddProtDataRow
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
;
    mov dx,gs:p_vm_deb_sel
    mov esi,gs:p_vm_deb_offs
    call AddLongDataRow
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
;           NAME:           Read_mem
;
;           DESCRIPTION:    Read memory in process
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           DS:EBP      Cpu
;
;           RETURNS:        NC  AL  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_mem    Proc near
    push bx
;
    mov bx,ds:[ebp].cpu_thread        
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
;                           BX          Thread
;                           DS:EBP      Cpu
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_mem    Proc near
    push bx
;
    mov bx,ds:[ebp].cpu_thread        
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
;           NAME:           GetDebugThreadData
;
;           DESCRIPTION:    Get debug thread data
;
;           PARAMETERS:     GS          Debugged thread
;                           DS:EBP      Cpu
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDebugThreadData      Proc near
    push es
    pushad
;    
    mov ax,ds
    mov es,ax
;    
    mov es:[ebp].cpu_read_mem,OFFSET read_mem
    mov es:[ebp].cpu_write_mem,OFFSET write_mem
    mov es:[ebp].cpu_thread,gs
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
;           NAME:           interact_inc
;
;           DESCRIPTION:    Interact increment
;
;           PARAMETERS:     GS          Thread
;                           DX:ESI      Adress to data
;                           CL          Number of digits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
interact_incr   PROC near
    push eax
    push bx
    push esi
    xor eax,eax
    clc
    rcr cl,1
    mov al,cl
    pushf
    add esi,eax
    mov bx,gs
    test word ptr ds:[ebp].reg_eflags+2,2
    jz interact_inc_read_prot

interact_inc_read_virt:
    ReadThreadSegment
    jmp interact_inc_read_done

interact_inc_read_prot:
    ReadThreadSelector

interact_inc_read_done:
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
    test word ptr ds:[ebp].reg_eflags+2,2
    jz interact_inc_write_prot

interact_inc_write_virt:
    WriteThreadSegment
    jmp interact_inc_write_done

interact_inc_write_prot:
    WriteThreadSelector

interact_inc_write_done:
    pop esi
    pop bx
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
    
interact_decr   PROC near
    push eax
    push bx
    push esi
    xor eax,eax
    clc
    rcr cl,1
    mov al,cl
    pushf
    add esi,eax
    mov bx,gs
    test word ptr ds:[ebp].reg_eflags+2,2
    jz interact_dec_read_prot

interact_dec_read_virt:
    ReadThreadSegment
    jmp interact_dec_read_done

interact_dec_read_prot:
    ReadThreadSelector

interact_dec_read_done:
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
    test word ptr ds:[ebp].reg_eflags+2,2
    jz interact_dec_write_prot

interact_dec_write_virt:
    WriteThreadSegment
    jmp interact_dec_write_done

interact_dec_write_prot:
    WriteThreadSelector

interact_dec_write_done:
    pop esi
    pop bx
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

interact_set_value     PROC near
    push eax
    push bx
    push esi
    xor eax,eax
    clc
    rcr cl,1
    mov al,cl
    pushf
    add esi,eax
    mov bx,gs
    test word ptr ds:[ebp].reg_eflags+2,2
    jz interact_set_read_prot

interact_set_read_virt:
    ReadThreadSegment
    jmp interact_set_read_done

interact_set_read_prot:
    ReadThreadSelector

interact_set_read_done:
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
    test word ptr ds:[ebp].reg_eflags+2,2
    jz interact_set_write_prot

interact_set_write_virt:
    WriteThreadSegment
    jmp interact_set_write_done

interact_set_write_prot:
    WriteThreadSelector

interact_set_write_done:
    pop esi
    pop bx
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
    
incdec_eax:
    mov edx,gs
    mov esi,OFFSET p_rax
    jmp incdec32

incdec_ebx:
    mov edx,gs
    mov esi,OFFSET p_rbx
    jmp incdec32

incdec_ecx:
    mov edx,gs
    mov esi,OFFSET p_rcx
    jmp incdec32

incdec_edx:
    mov edx,gs
    mov esi,OFFSET p_rdx
    jmp incdec32

incdec_esi:
    mov edx,gs
    mov esi,OFFSET p_rsi
    jmp incdec32

incdec_edi:
    mov edx,gs
    mov esi,OFFSET p_rdi
    jmp incdec32

incdec_esp:
    mov edx,gs
    mov esi,OFFSET p_rsp
    jmp incdec32

incdec_ebp:
    mov edx,gs
    mov esi,OFFSET p_rbp
    jmp incdec32

incdec_epc:
    mov edx,gs
    mov esi,OFFSET p_rip
    jmp incdec32

incdec_rip:
    mov edx,gs
    mov esi,OFFSET p_rip
    jmp incdec64

incdec_rax:
    mov edx,gs
    mov esi,OFFSET p_rax
    jmp incdec64

incdec_rbx:
    mov edx,gs
    mov esi,OFFSET p_rbx
    jmp incdec64

incdec_rcx:
    mov edx,gs
    mov esi,OFFSET p_rcx
    jmp incdec64

incdec_rdx:
    mov edx,gs
    mov esi,OFFSET p_rdx
    jmp incdec64

incdec_rsi:
    mov edx,gs
    mov esi,OFFSET p_rsi
    jmp incdec64

incdec_rdi:
    mov edx,gs
    mov esi,OFFSET p_rdi
    jmp incdec64

incdec_r8:
    mov edx,gs
    mov esi,OFFSET p_r8
    jmp incdec64

incdec_r9:
    mov edx,gs
    mov esi,OFFSET p_r9
    jmp incdec64

incdec_r10:
    mov edx,gs
    mov esi,OFFSET p_r10
    jmp incdec64

incdec_r11:
    mov edx,gs
    mov esi,OFFSET p_r11
    jmp incdec64

incdec_r12:
    mov edx,gs
    mov esi,OFFSET p_r12
    jmp incdec64

incdec_r13:
    mov edx,gs
    mov esi,OFFSET p_r13
    jmp incdec64

incdec_r14:
    mov edx,gs
    mov esi,OFFSET p_r14
    jmp incdec64

incdec_r15:
    mov edx,gs
    mov esi,OFFSET p_r15
    jmp incdec64

incdec_rbp:
    mov edx,gs
    mov esi,OFFSET p_rbp
    jmp incdec64

incdec_rsp:
    mov edx,gs
    mov esi,OFFSET p_rsp
    jmp incdec64

incdec_cs:
    mov edx,gs
    mov esi,OFFSET p_cs
    jmp incdec16

incdec_ds:
    mov edx,gs
    mov esi,OFFSET p_ds
    jmp incdec16

incdec_es:
    mov edx,gs
    mov esi,OFFSET p_es
    jmp incdec16

incdec_fs:
    mov edx,gs
    mov esi,OFFSET p_fs
    jmp incdec16

incdec_gs:
    mov edx,gs
    mov esi,OFFSET p_gs
    jmp incdec16

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

change_eax      PROC near
    mov edx,gs
    mov esi,OFFSET p_rax
    push edi
    ret
change_eax      ENDP

change_ebx      PROC near
    mov edx,gs
    mov esi,OFFSET p_rbx
    push edi
    ret
change_ebx      ENDP

change_ecx      PROC near
    mov edx,gs
    mov esi,OFFSET p_rcx
    push edi
    ret
change_ecx      ENDP

change_edx      PROC near
    mov edx,gs
    mov esi,OFFSET p_rdx
    push edi
    ret
change_edx      ENDP

change_esi      PROC near
    mov edx,gs
    mov esi,OFFSET p_rsi
    push edi
    ret
change_esi      ENDP

change_edi      PROC near
    mov edx,gs
    mov esi,OFFSET p_rdi
    push edi
    ret
change_edi      ENDP

change_esp      PROC near
    mov edx,gs
    mov esi,OFFSET p_rsp
    push edi
    ret
change_esp      ENDP

change_ebp      PROC near
    mov edx,gs
    mov esi,OFFSET p_rbp
    push edi
    ret
change_ebp      ENDP

change_epc      PROC near
    mov edx,gs
    mov esi,OFFSET p_rip
    push edi
    ret
change_epc      ENDP

change_raxl      PROC near
    mov edx,gs
    mov esi,OFFSET p_rax
    push edi
    ret
change_raxl      ENDP

change_raxh      PROC near
    mov edx,gs
    mov esi,OFFSET p_rax + 4
    push edi
    ret
change_raxh      ENDP

change_rbxl      PROC near
    mov edx,gs
    mov esi,OFFSET p_rbx
    push edi
    ret
change_rbxl      ENDP

change_rbxh      PROC near
    mov edx,gs
    mov esi,OFFSET p_rbx + 4
    push edi
    ret
change_rbxh      ENDP

change_rcxl      PROC near
    mov edx,gs
    mov esi,OFFSET p_rcx
    push edi
    ret
change_rcxl      ENDP

change_rcxh      PROC near
    mov edx,gs
    mov esi,OFFSET p_rcx + 4
    push edi
    ret
change_rcxh      ENDP

change_rdxl      PROC near
    mov edx,gs
    mov esi,OFFSET p_rdx
    push edi
    ret
change_rdxl      ENDP

change_rdxh      PROC near
    mov edx,gs
    mov esi,OFFSET p_rdx + 4
    push edi
    ret
change_rdxh      ENDP

change_rsil      PROC near
    mov edx,gs
    mov esi,OFFSET p_rsi
    push edi
    ret
change_rsil      ENDP

change_rsih      PROC near
    mov edx,gs
    mov esi,OFFSET p_rsi + 4
    push edi
    ret
change_rsih      ENDP

change_rdil      PROC near
    mov edx,gs
    mov esi,OFFSET p_rdi
    push edi
    ret
change_rdil      ENDP

change_rdih      PROC near
    mov edx,gs
    mov esi,OFFSET p_rdi + 4
    push edi
    ret
change_rdih      ENDP

change_r8l      PROC near
    mov edx,gs
    mov esi,OFFSET p_r8
    push edi
    ret
change_r8l      ENDP

change_r8h      PROC near
    mov edx,gs
    mov esi,OFFSET p_r8 + 4
    push edi
    ret
change_r8h      ENDP

change_r9l      PROC near
    mov edx,gs
    mov esi,OFFSET p_r9
    push edi
    ret
change_r9l      ENDP

change_r9h      PROC near
    mov edx,gs
    mov esi,OFFSET p_r9 + 4
    push edi
    ret
change_r9h      ENDP

change_r10l      PROC near
    mov edx,gs
    mov esi,OFFSET p_r10
    push edi
    ret
change_r10l      ENDP

change_r10h      PROC near
    mov edx,gs
    mov esi,OFFSET p_r10 + 4
    push edi
    ret
change_r10h      ENDP

change_r11l      PROC near
    mov edx,gs
    mov esi,OFFSET p_r11
    push edi
    ret
change_r11l      ENDP

change_r11h      PROC near
    mov edx,gs
    mov esi,OFFSET p_r11 + 4
    push edi
    ret
change_r11h      ENDP

change_r12l      PROC near
    mov edx,gs
    mov esi,OFFSET p_r12
    push edi
    ret
change_r12l      ENDP

change_r12h      PROC near
    mov edx,gs
    mov esi,OFFSET p_r12 + 4
    push edi
    ret
change_r12h      ENDP

change_r13l      PROC near
    mov edx,gs
    mov esi,OFFSET p_r13
    push edi
    ret
change_r13l      ENDP

change_r13h      PROC near
    mov edx,gs
    mov esi,OFFSET p_r13 + 4
    push edi
    ret
change_r13h      ENDP

change_r14l      PROC near
    mov edx,gs
    mov esi,OFFSET p_r14
    push edi
    ret
change_r14l      ENDP

change_r14h      PROC near
    mov edx,gs
    mov esi,OFFSET p_r14 + 4
    push edi
    ret
change_r14h      ENDP

change_r15l      PROC near
    mov edx,gs
    mov esi,OFFSET p_r15
    push edi
    ret
change_r15l      ENDP

change_r15h      PROC near
    mov edx,gs
    mov esi,OFFSET p_r15 + 4
    push edi
    ret
change_r15h      ENDP

change_ripl      PROC near
    mov edx,gs
    mov esi,OFFSET p_rip
    push edi
    ret
change_ripl      ENDP

change_riph      PROC near
    mov edx,gs
    mov esi,OFFSET p_rip + 4
    push edi
    ret
change_riph      ENDP

change_rspl      PROC near
    mov edx,gs
    mov esi,OFFSET p_rsp
    push edi
    ret
change_rspl      ENDP

change_rsph      PROC near
    mov edx,gs
    mov esi,OFFSET p_rsp + 4
    push edi
    ret
change_rsph      ENDP

change_rbpl      PROC near
    mov edx,gs
    mov esi,OFFSET p_rbp
    push edi
    ret
change_rbpl      ENDP

change_rbph      PROC near
    mov edx,gs
    mov esi,OFFSET p_rbp + 4
    push edi
    ret
change_rbph      ENDP

change_cs       PROC near
    and cl,3
    mov edx,gs
    mov esi,OFFSET p_cs
    push edi
    ret
change_cs       ENDP

change_ds       PROC near
    and cl,3
    mov edx,gs
    mov esi,OFFSET p_ds
    push edi
    ret
change_ds       ENDP

change_es       PROC near
    and cl,3
    mov edx,gs
    mov esi,OFFSET p_es
    push edi
    ret
change_es       ENDP

change_fs       PROC near
    and cl,3
    mov edx,gs
    mov esi,OFFSET p_fs
    push edi
    ret
change_fs       ENDP

change_gs       PROC near
    and cl,3
    mov edx,gs
    mov esi,OFFSET p_gs
    push edi
    ret
change_gs       ENDP

change_ss       PROC near
    and cl,3
    mov edx,gs
    mov esi,OFFSET p_ss
    push edi
    ret
change_ss       ENDP

change_pm_sel   PROC near
    xor ecx,ecx
    xchg ecx,ds:[ebp].reg_eflags
    push ecx
;    
    mov dx,gs
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
    pop ecx
    mov ds:[ebp].reg_eflags,ecx
    ret
change_pm_sel   ENDP

change_pm_offs  PROC near
    xor ecx,ecx
    xchg ecx,ds:[ebp].reg_eflags
    push ecx
;
    mov dx,gs
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
    pop ecx
    mov ds:[ebp].reg_eflags,ecx
    ret
change_pm_offs  ENDP

change_vm_sel   PROC near
    mov ecx,20000h
    xchg ecx,ds:[ebp].reg_eflags
    push ecx
;    
    mov dx,gs
    and cl,3
    mov esi,OFFSET p_vm_deb_sel
    push cx
;    
    push OFFSET change_vm_sel_ret
    push edi
    ret
    
change_vm_sel_ret:
    pop cx
;    
    or cl,cl
    jnz change_vm_sel_error
;    
    inc ds:sw_col
    
change_vm_sel_error:
    pop ecx
    mov ds:[ebp].reg_eflags,ecx
    ret
change_vm_sel   ENDP

change_vm_offs  PROC near
    mov ecx,20000h
    xchg ecx,ds:[ebp].reg_eflags
    push ecx
;    
    mov dx,gs
    mov esi,OFFSET p_vm_deb_offs
    push cx
;    
    push OFFSET change_vm_offs_ret
    push edi
    ret
    
change_vm_offs_ret:
    pop cx
;    
    or cl,cl
    jnz change_vm_offs_error
;    
    inc ds:sw_col
    
change_vm_offs_error:
    pop ecx
    mov ds:[ebp].reg_eflags,ecx
    ret
change_vm_offs  ENDP

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

toggle_cy       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],1
    ret
toggle_cy       ENDP

toggle_pa       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],4
    ret
toggle_pa       ENDP

toggle_ac       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],10h
    ret
toggle_ac       ENDP

toggle_zr       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],40h
    ret
toggle_zr       ENDP

toggle_pl       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],80h
    ret
toggle_pl       ENDP

toggle_im       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],200h
    ret
toggle_im       ENDP

toggle_dir      PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],400h
    ret
toggle_dir      ENDP

toggle_ov       PROC near
    mov ebx,OFFSET p_rflags
    xor word ptr gs:[ebx],800h
    ret
toggle_ov       ENDP

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

mem_ads PROC near
    ret
mem_ads ENDP

mem_cs  PROC near
    mov dx,gs:p_cs
    mov esi,OFFSET p_rip
    mov esi,gs:[esi]
    call mem_do
    ret
mem_cs  ENDP

mem_ss  PROC near
    mov dx,gs:p_ss
    mov esi,OFFSET p_rsp
    mov esi,gs:[esi]
    call mem_do
    ret
mem_ss  ENDP

mem_es  PROC near
    mov dx,gs:p_es
    xor esi,esi
    call mem_do
    ret
mem_es  ENDP

mem_pm  PROC near
    xor ecx,ecx
    xchg ecx,ds:[ebp].reg_eflags
    push ecx
;    
    mov dx,gs:p_pm_deb_sel
    mov esi,gs:p_pm_deb_offs
    call mem_do
;
    pop ecx    
    mov ds:[ebp].reg_eflags,ecx
    ret
mem_pm  ENDP

mem_vm  PROC near
    mov ecx,20000h
    xchg ecx,ds:[ebp].reg_eflags
    push ecx
;    
    mov dx,gs:p_vm_deb_sel
    mov esi,gs:p_vm_deb_offs
    call mem_do
;    
    pop ecx    
    mov ds:[ebp].reg_eflags,ecx
    ret
mem_vm  ENDP

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
vms32  DD 24,         0,          4,          OFFSET change_vm_sel
vmo32  DD 24,         5,          8,          OFFSET change_vm_offs
vdat32 DD 24,         14,         47,         OFFSET mem_vm
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
mrax   DW 6,          1,          3,          OFFSET incdec_rax
draxh  DW 6,          5,          8,          OFFSET change_raxh
draxl  DW 6,          14,         8,          OFFSET change_raxl
mrbx   DW 6,          23,         3,          OFFSET incdec_rbx
drbxh  DW 6,          27,         8,          OFFSET change_rbxh
drbxl  DW 6,          36,         8,          OFFSET change_rbxl
mrcx   DW 6,          45,         3,          OFFSET incdec_rcx
drcxh  DW 6,          49,         8,          OFFSET change_rcxh
drcxl  DW 6,          58,         8,          OFFSET change_rcxl
mrdx   DW 7,          1,          3,          OFFSET incdec_rdx
drdxh  DW 7,          5,          8,          OFFSET change_rdxh
drdxl  DW 7,          14,         8,          OFFSET change_rdxl
mrsi   DW 7,          23,         3,          OFFSET incdec_rsi
drsih  DW 7,          27,         8,          OFFSET change_rsih
drsil  DW 7,          36,         8,          OFFSET change_rsil
mrdi   DW 7,          45,         3,          OFFSET incdec_rdi
drdih  DW 7,          49,         8,          OFFSET change_rdih
drdil  DW 7,          58,         8,          OFFSET change_rdil
mr8    DW 8,          2,          2,          OFFSET incdec_r8
dr8h   DW 8,          5,          8,          OFFSET change_r8h
dr8l   DW 8,          14,         8,          OFFSET change_r8l
mr9    DW 8,          24,         2,          OFFSET incdec_r9
dr9h   DW 8,          27,         8,          OFFSET change_r9h
dr9l   DW 8,          36,         8,          OFFSET change_r9l
mr10   DW 8,          45,         3,          OFFSET incdec_r10
dr10h  DW 8,          49,         8,          OFFSET change_r10h
dr10l  DW 8,          58,         8,          OFFSET change_r10l
mr11   DW 9,          1,          3,          OFFSET incdec_r11
dr11h  DW 9,          5,          8,          OFFSET change_r11h
dr11l  DW 9,          14,         8,          OFFSET change_r11l
mr12   DW 9,          23,         3,          OFFSET incdec_r12
dr12h  DW 9,          27,         8,          OFFSET change_r12h
dr12l  DW 9,          36,         8,          OFFSET change_r12l
mr13   DW 9,          45,         3,          OFFSET incdec_r13
dr13h  DW 9,          49,         8,          OFFSET change_r13h
dr13l  DW 9,          58,         8,          OFFSET change_r13l
mr14   DW 10,         1,          3,          OFFSET incdec_r14
dr14h  DW 10,         5,          8,          OFFSET change_r14h
dr14l  DW 10,         14,         8,          OFFSET change_r14l
mr15   DW 10,         23,         3,          OFFSET incdec_r15
dr15h  DW 10,         27,         8,          OFFSET change_r15h
dr15l  DW 10,         36,         8,          OFFSET change_r15l
mrip64 DW 11,         1,          3,          OFFSET incdec_rip
driph  DW 11,         5,          8,          OFFSET change_riph
dripl  DW 11,         14,         8,          OFFSET change_ripl
mrsp64 DW 11,         23,         3,          OFFSET incdec_rsp
drsph  DW 11,         27,         8,          OFFSET change_rsph
drspl  DW 11,         36,         8,          OFFSET change_rspl
mrsb64 DW 11,         45,         3,          OFFSET incdec_rbp
drbph  DW 11,         49,         8,          OFFSET change_rbph
drbpl  DW 11,         58,         8,          OFFSET change_rbpl
mcs64  DW 12,         1,          2,          OFFSET incdec_cs
dcs64  DW 12,         4,          4,          OFFSET change_cs
mds64  DW 12,         9,          2,          OFFSET incdec_ds
dds64  DW 12,         12,         4,          OFFSET change_ds
mes64  DW 12,         17,         2,          OFFSET incdec_es
des64  DW 12,         20,         4,          OFFSET change_es
mfs64  DW 12,         25,         2,          OFFSET incdec_fs
dfs64  DW 12,         28,         4,          OFFSET change_fs
mgs64  DW 12,         33,         2,          OFFSET incdec_gs
dgs64  DW 12,         36,         4,          OFFSET change_gs
mss64  DW 12,         41,         2,          OFFSET incdec_ss
dss64  DW 12,         44,         4,          OFFSET change_ss
dcy64  DW 13,         0,          2,          OFFSET toggle_cy
dpa64  DW 13,         3,          2,          OFFSET toggle_pa
dac64  DW 13,         6,          2,          OFFSET toggle_ac
dzr64  DW 13,         9,          2,          OFFSET toggle_zr
dplc64 DW 13,         12,         2,          OFFSET toggle_pl
disf64 DW 13,         15,         2,          OFFSET toggle_im
ddir64 DW 13,         18,         2,          OFFSET toggle_dir
dov64  DW 13,         21,         2,          OFFSET toggle_ov
dnt64  DW 13,         24,         2,          OFFSET toggle_nt
mdad64 DW 19,         14,         47,         OFFSET mem_ads
mdcs64 DW 20,         14,         47,         OFFSET mem_cs
mdss64 DW 21,         14,         47,         OFFSET mem_ss
mdes64 DW 22,         14,         47,         OFFSET mem_es
pms64  DW 23,         0,          4,          OFFSET change_pm_sel
pmo64  DW 23,         5,          8,          OFFSET change_pm_offs
pdat64 DW 23,         14,         47,         OFFSET mem_pm
vms64  DW 24,         0,          4,          OFFSET change_vm_sel
vmo64  DW 24,         5,          8,          OFFSET change_vm_offs
vdat64 DW 24,         14,         47,         OFFSET mem_vm
dend64 DW 0FFFFh, 0FFFFh

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
    
code    ENDS

    END
