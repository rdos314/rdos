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
debug_col       EQU 2
debug_ant       EQU 4
debug_call      EQU 6
debug_size      EQU 8

.386p
.387

data    SEGMENT byte public 'DATA'

cpu cpu_struc <>

intr_dl     DB ?

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
;           PARAMETERS:     AX                  Debug thread
;                           ES:EDI              Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetCpu
    
GetCpu  Proc near
    push gs
    pushad
;
    mov gs,ax
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
    pop gs    
    ret
GetCpu  Endp

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
;    call interact_set_value
    inc ds:intr_dl
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
    mov cl,ds:intr_dl
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
    inc ds:intr_dl

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
    
code    ENDS

    END
