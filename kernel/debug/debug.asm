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
; DEBUG.ASM
; Kernel part kernel debugger
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

.386p
.387

data    SEGMENT byte public 'DATA'

buf    DB 4096 DUP(?)

cpu cpu_struc <>

data    ENDS

code    SEGMENT byte use32 public 'CODE'

    extrn DisAsmCode:near


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddNewLine
;
;           DESCRIPTION:    ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddNewLine Proc near
    push eax
;    
    mov al,13
    stosb
;    
    mov al,10
    stosb
;
    pop eax
    ret
AddNewLine Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddBlank
;
;           DESCRIPTION:    Add blanks
;
;           PARAMETERS:     ES:EDI       Buffer
;                           ECX          Number of blanks to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBlanks   Proc near
    push eax
    push ecx
;
    mov al,' '
    rep stosb
;
    pop ecx
    pop eax
    ret
AddBlanks   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddDelimiter
;
;           DESCRIPTION:    Add delimiter
;  
;           PARAMETERS:     ES:EDI       Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDelimiter       Proc near
    push eax
    push ecx
;    
    mov ecx,60
    mov al,'-'
    rep stosb
;
    mov ecx,19
    call AddBlanks
;
    call AddNewLine    
; 
    pop ecx   
    pop eax
    ret
AddDelimiter       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ToHex
;
;           DESCRIPTION:    
;
;           PARAMETERS:     AL          Number
;
;           RETURNS:        AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ToHex      PROC near

hex_conv_low:
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
;
    add al,7

ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
;    
    add ah,7

ok_high1:
    add ah,30h
    ret
ToHex      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI       Buffer
;                           AL          Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexByte    PROC near
    push eax
;    
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb add_byte_low1
;    
    add al,7

add_byte_low1:
    add al,'0'
    stosb
;
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb add_byte_high1
;
    add al,7

add_byte_high1:
    add al,'0'
    stosb
;
    pop eax
    ret
AddHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI       Buffer
;                           AX           Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexWord    PROC near
    xchg al,ah
    call AddHexByte
    xchg al,ah
    call AddHexByte
    ret
AddHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexDword   PROC near
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    ret
AddHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           EDX:EAX     Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexQword   PROC near
    push eax
;    
    push eax
    mov eax,edx
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
;
    mov al,'_'
    stosb
;
    pop eax
;    
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
;
    pop eax    
    ret
AddHexQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexPtr16
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           DX          Segment
;                           BX          Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexPtr16   PROC near
    push ax
    mov ax,dx
    call AddHexWord
;    
    mov al,':'
    stosb
;
    mov ax,bx
    call AddHexWord
    pop ax
    ret
AddHexPtr16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexPtr32
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           DX          Segment
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexPtr32   PROC near
    push eax
    mov ax,dx
    call AddHexWord
;    
    mov al,':'
    stosb
;
    mov eax,ebx
    call AddHexDword
    pop eax
    ret
AddHexPtr32   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexPtr64
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DX          High offset
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHexPtr64   PROC near
    push eax
;    
    mov ax,dx
    call AddHexWord
;
    mov al,'_'
    stosb
;    
    mov eax,ebx
    call AddHexDword
;
    pop eax
    ret
AddHexPtr64   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddCodeAsciiz
;
;           DESCRIPTION:    Add asciiz string from code
;
;           PARAMETERS:     ES:EDI      Buffer
;                           CS:ESI      String to add
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddCodeAsciiz   PROC near
    push ax

acaLoop:
    lods cs:[esi]
    or al,al
    jz acaDone
;
    stosb
    jmp acaLoop    

acaDone:
    pop ax
    ret
AddCodeAsciiz   ENDP

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
    mov eax,ds:[ebp].reg_eflags
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
    mov ax,word ptr ds:[ebp].reg_eflags
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
    mov ax,ds:[ebp+ebx]
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
    mov eax,ds:[ebp+ebx]
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
    mov eax,ds:[ebp+ebx]
    mov edx,ds:[ebp+ebx+4]
    call AddHexQword
    add esi,2
    jmp aqLoop
    
aqEnd:
    ret
AddQwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddProtDataRow
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           DS:EBP      Cpu
;                           ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddProtDataRow    PROC near
    mov ebx,esi
    call AddHexPtr32
;    
    mov ecx,16
    push esi

apdhLoop:
    mov al,' '
    stosb
;
    call ds:[ebp].cpu_read_mem    
    jc apdhInv
;
    call AddHexByte
    jmp apdhNext

apdhInv:
    stosb
    stosb

apdhNext:
    inc esi
    loop apdhLoop
;
    pop esi
    mov al,' '
    stosb
;
    mov ecx,16

apdaLoop:
    call ds:[ebp].cpu_read_mem    
    cmp al,20h
    jnc apdaDo
;    
    mov al,' '

apdaDo:
    stosb
    inc esi
    loop apdaLoop
    
apdEnd:
    ret
AddProtDataRow    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddLongDataRow
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DX:ESI      Offset
;                           DS:EBP      Cpu
;                           ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddLongDataRow    PROC near
    mov ebx,esi
    call AddHexPtr64
;
    mov ecx,16
    push esi

aldhLoop:
    mov al,' '
    stosb
;    
    call ds:[ebp].cpu_read_mem    
    jc aldhInv
;
    call AddHexByte
    jmp aldhNext

aldhInv:
    stosb
    stosb

aldhNext:
    inc esi
    loop aldhLoop
;
    pop esi
;
    mov al,' '
    stosb
;    
    mov ecx,16
    
aldaLoop:
    call ds:[ebp].cpu_read_mem    
    cmp al,20h
    jnc aldaDo
;
    mov al,' '

aldaDo:
    stosb
    inc esi
    loop aldaLoop

aldaEnd:
    ret
AddLongDataRow    ENDP

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
    test word ptr ds:[ebp].reg_eflags+2,2
    jnz afEnd
;    
    mov eax,ds:[ebp].cpu_fault
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
    movzx edx,ds:[ebp].cpu_exc_code
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
    push ds
;    
    mov ds,ds:[ebp].cpu_thread
    mov ax,ds:p_id
    call AddHexWord
;    
    mov al,' '
    stosb
    stosb
;    
    mov esi,OFFSET thread_name
    mov ecx,30
    rep movsb
;
    call AddNewLine
;
    pop ds    
    ret
AddThreadInfo     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddFreeMem
;
;           DESCRIPTION:    Add free memory
;
;           PARAMETERS:     ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

phys_mem_comment        DB 'Physical ',0
global_mem_comment      DB '   Global ',0
local_mem_comment       DB '   Local ',0

AddFreeMem    PROC near
    mov esi,OFFSET phys_mem_comment
    call AddCodeAsciiz
;    
    GetFreePhysical
    call AddHexQword
;
    mov esi,OFFSET global_mem_comment
    call AddCodeAsciiz
;    
    UsedBigLinear
    push edx
    push eax
    UsedSmallLinear
    pop edx
    add eax,edx
    pop edx
    call AddHexDword
;
    mov esi,OFFSET local_mem_comment
    call AddCodeAsciiz
;    
    mov bx,ds:[ebp].cpu_thread
    UsedLocalLinearThread
    call AddHexDword
;    
    call AddNewLine
    ret
AddFreeMem    ENDP

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
    mov dx,ds:[ebp].reg_cs.d_selector
    mov esi,ds:[ebp].reg_eip
    call AddProtDataRow
    call AddNewLine
;
    mov dx,ds:[ebp].reg_ss.d_selector
    mov esi,ds:[ebp].reg_esp
    call AddProtDataRow
    call AddNewLine
;
    mov dx,ds:[ebp].reg_es.d_selector
    xor esi,esi
    call AddProtDataRow
    call AddNewLine
;
    xor ecx,ecx
    xchg ecx,ds:[ebp].reg_eflags
    push ecx
    push fs
;
    mov fs,ds:[ebp].cpu_thread
    mov dx,fs:p_pm_deb_sel
    mov esi,fs:p_pm_deb_offs
    call AddProtDataRow
    call AddNewLine
;
    mov ds:[ebp].reg_eflags,20000h
    mov dx,fs:p_vm_deb_sel
    mov esi,fs:p_vm_deb_offs
    call AddProtDataRow
;
    pop fs
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
    mov bx,ds:[ebp].reg_cs.d_selector
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
    mov esi,ds:[ebp].reg_eip
    mov edx,ds:[ebp].reg_eip+4
    call AddLongDataRow
    call AddNewLine
;
    mov esi,ds:[ebp].reg_esp
    mov edx,ds:[ebp].reg_esp+4
    call AddLongDataRow
    call AddNewLine
;
    mov esi,ds:[ebp].reg_edi
    mov edx,ds:[ebp].reg_edi+4
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
    mov dx,ds:[ebp].reg_cs.d_selector
    mov esi,ds:[ebp].reg_eip
    call AddProtDataRow
    call AddNewLine
;
    mov dx,ds:[ebp].reg_ss.d_selector
    mov esi,ds:[ebp].reg_esp
    call AddProtDataRow
    call AddNewLine
;
    mov dx,ds:[ebp].reg_es.d_selector
    xor esi,esi
    call AddProtDataRow
    call AddNewLine

wd64_data:    
    push fs
    mov fs,ds:[ebp].cpu_thread
    mov dx,fs:p_pm_deb_sel
    mov esi,fs:p_pm_deb_offs
    call AddProtDataRow
    call AddNewLine
;
    mov dx,fs:p_vm_deb_sel
    mov esi,fs:p_vm_deb_offs
    call AddLongDataRow
    pop fs
    ret
AddLongData       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:                   FLOAT_POWER10
;
;       DESCRIPTION:    
;
;       PARAMETERS:             AX              Exponent
;
;       RETURNS:                ST(0)           10**AX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dt0  DT 1.0e+1
dt1  DT 1.0e+2
dt2  DT 1.0e+4
dt3  DT 1.0e+8
dt4  DT 1.0e+16
dt5  DT 1.0e+32
dt6  DT 1.0e+64
dt7  DT 1.0e+128
dt8  DT 1.0e+256
dt9  DT 1.0e+512
dt10 DT 1.0e+1024
dt11 DT 1.0e+2048
dt12 DT 1.0e+4096

float_power10   PROC near
    push ax
    push ebx
    test ax,8000h
    pushf
    jz float_scale_pos
;
    neg ax

float_scale_pos:
    mov ebx,OFFSET dt0
    sub ebx,10
    fld1
    
float_scale_next:
    add ebx,10
    or ax,ax
    jz float_scale_end
;
    clc
    rcr ax,1
    jnc float_scale_next
;    
    fld tbyte ptr cs:[ebx]
    fmulp st(1),st
    jmp float_scale_next

float_scale_end:
    popf
    jz float_scale_no_inv
;    
    fld1
    fdivrp st(1),st

float_scale_no_inv:
    pop ebx
    pop ax
    ret
float_power10   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FLOAT_SPLIT
;
;       DESCRIPTION:    SPLIT NUMBER INTO 10-EXPONENT AND MANTISSA
;
;       PARAMETERS:     ST(0)           NUMBER IN, MANTISSA OUT
;                       DL              NUMBER OF DECIMALS
;
;       RETURNS:        ST(0)           MANTISSA
;                       AX              EXPONENT IN NUMBER
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dt_half DT 0.5

float_split     PROC near
    pushf
    push ecx
    push edx
    push esi
;    
    xor dh,dh
    mov ax,dx
    neg ax
    call float_power10
    fld cs:dt_half
    fmulp st(1),st
    faddp st(1),st
    mov esi,OFFSET dt12
    mov ecx,13
    xor dx,dx
    fld1
    fcomp st(1)
    fstsw ax
    sahf
    jz float_split_end    
    jc float_split_no_invert
;    
    fld1
    fdivrp st(1),st

float_split_no_invert:
    pushf
    
float_split_loop:
    fld tbyte ptr cs:[esi]
    fcomp st(1)
    fstsw ax
    sahf
    jz float_split_lower
    jnc float_split_lower
;    
    fld tbyte ptr cs:[esi]
    fdivp st(1),st
    stc
    jmp float_split_next

float_split_lower:
    clc
    
float_split_next:
    rcl dx,1
    sub esi,10
    loop float_split_loop
;
    popf
    jc float_split_end
;    
    fld1
    fdivrp st(1),st
    neg dx
    
float_split_end:
    mov ax,dx
;    
    pop esi
    pop edx
    pop ecx
    popf
    ret
float_split     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:                   FLOAT_CALC_POS
;
;       DESCRIPTION:    
;
;       PARAMETERS:             AX              EXPONENT
;                               CL              STRING SIZE
;                               DL              NUMBER OF DECIMALS
;
;       RETURNS:                CH              NUMBER OF LEADING BLANKS
;                               DH              POSITION OF DECIMAL  "."
;                               BL              MANTISSA POSITION
;                               NC              OK
;                               CY              CANNOT DISPLAY NUMBER ON FORM
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_calc_pos  PROC near
    push ax
    mov bl,al
    neg bl
    test ax,8000h
    jz float_calc_big
;    
    xor ax,ax
    inc bl
    
float_calc_big:
    or ah,ah
    jnz float_calc_exp
;    
    mov ch,cl
    sub ch,al
    jc float_calc_exp
;    
    sub ch,dl
    jc float_calc_exp
;    
    sub ch,1
    jc float_calc_exp
;
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
;    
    inc ch
    inc dh
    inc bl

float_calc_dot:
    clc
    pop ax
    ret
float_calc_pos  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:                   FLOAT_INIT_STRING
;
;       DESCRIPTION:    
;
;       PARAMETERS:             ES:EDI  STRING
;                               AX      EXPONENT
;                               CL      STRING SIZE
;                               DL      NUMBER OF DECIMALS
;                               NC      POSITIVE NUMBER
;                               CY      NEGATIVE NUMBER
;
;       RETURN:                 ES:EDX  OFFSET TO "."
;                               ES:EDI  ADDRESS WHERE TO START WRITING MANTISSA
;                               ES:ESI  LAST CHAR IN STRING
;                               NC      OK
;                               CY      FEL, TO BIG NUMBER
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_init_string       PROC near
    push ecx
    push ebx
    push eax
    pushf
    jnc float_istr_calc
;    
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
;
    inc cl
    inc dh
    inc bl
    
float_istr_noinc:
    movzx ebx,bl
    add ebx,edi
    mov esi,ebx
    mov bl,cl
;
    movzx ebx,bl
    add ebx,edi
    xchg ebx,esi
    or ch,ch
    jz float_istr_nodot
;
    push ecx
    movzx ecx,ch
    mov al,' '
    rep stosb   
    pop ecx
    
float_istr_nodot:
    popf
    jnc float_istr_nosign
;    
    mov al,'-'
    stosb

float_istr_nosign:
    movzx ecx,dl
    sub ecx,esi
    neg ecx
    sub ecx,edi
    mov al,'0'
    or ecx,ecx
    jz float_no_lead_zero
;    
    rep stosb

float_no_lead_zero:
    movzx ecx,dl
    or ecx,ecx
    jz float_no_dot
;    
    mov edx,edi
    mov al,'.'
    stosb
    mov al,'0'
    rep stosb

float_no_dot:
    mov edi,ebx
    clc
    jmp float_istr_end

float_istr_error:
    popf
    stc
    
float_istr_end:
    pop eax
    pop ebx
    pop ecx
    ret
float_init_string       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FLOAT_STRING
;
;       DESCRIPTION:    WRITE 10-EXPONENT OCH MANTISSA TO STRING
;
;       PARAMETERS:     ST(0)           MANTISSA 0.1-1.0
;                       AX              EXPONENT
;                       ES:EDI          STRING
;                       CH              LEADING BLANKS
;                       DH              POSITION OF "."
;                       ES:ESI          LAST CHAR IN STRING
;
;       RETURNS:        ES:EDI          Next pos
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_string    PROC near
    mov ecx,20
    inc esi
    fld1
    
float_string_loop:
    cmp edi,esi
    je float_string_end
;    
    cmp edi,edx
    jne float_string_no_dot
;    
    inc edi
    cmp esi,edi
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
    or ecx,ecx
    jz float_string_save0
;    
    dec ecx
    mov al,bl

float_string_save0:
    stosb
    fld cs:dt0
    fmulp st(2),st
    cmp esi,edi
    jne float_string_loop

float_string_end:
    ret
float_string    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_normal
;
;        DESCRIPTION:           Normal float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

overflow_txt    DB 'TOO BIG NUMBER'

float_normal    PROC near
    pushf
    call float_split
    call float_init_string
    jc float_error_decode
;
    popf
    call float_string
    ret
    
float_error_decode:
    popf
    mov esi,OFFSET overflow_txt
    mov ecx,14
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_normal    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_unsupported
;
;        DESCRIPTION:           Unsupported float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unsupported_txt DB 'UNSUPPORTED'

float_unsuported        PROC near
    mov esi,OFFSET unsupported_txt
    mov ecx,11
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_unsuported        ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_nan
;
;        DESCRIPTION:           NAN float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nan_txt                 DB 'NAN'

float_nan       PROC near
    mov esi,OFFSET nan_txt
    mov ecx,3
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_nan       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_infinity
;
;        DESCRIPTION:           Infinite float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

infinity_txt    DB 'INFINITY'

float_infinity  PROC near
    mov esi,OFFSET infinity_txt
    mov ecx,8
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_infinity  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_zero
;
;        DESCRIPTION:           Zero float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_zero      PROC near
    mov al,'0'
    stosb
    ret
float_zero      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_empty
;
;        DESCRIPTION:           Empty float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

empty_txt               DB 'EMPTY'

float_empty     PROC near
    mov esi,OFFSET empty_txt
    mov ecx,5
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_empty     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_denormal
;
;        DESCRIPTION:           Denormal float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

denormal_txt    DB 'DENORMAL'

float_denormal  PROC near
    mov esi,OFFSET denormal_txt
    mov ecx,8
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_denormal  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 FloadToString
;
;        DESCRIPTION:   
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_type_tab:
ftt0 DD OFFSET float_unsuported
ftt1 DD OFFSET float_nan
ftt2 DD OFFSET float_unsuported
ftt3 DD OFFSET float_nan
ftt4 DD OFFSET float_normal
ftt5 DD OFFSET float_infinity
ftt6 DD OFFSET float_normal
ftt7 DD OFFSET float_infinity
ftt8 DD OFFSET float_zero
ftt9 DD OFFSET float_empty
fttA DD OFFSET float_zero
fttB DD OFFSET float_empty
fttC DD OFFSET float_denormal
fttD DD OFFSET float_unsuported
fttE DD OFFSET float_denormal
fttF DD OFFSET float_unsuported

FloatToString   PROC near
    fxam
    fstsw ax
    test ah,2
    clc
    jz ftsSignOk
;    
    fchs
    stc

ftsSignOk:
    pushf
    mov bl,ah
    and bl,7
    and ah,40h
    jz ftsC3Zero
;    
    or bl,8

ftsC3Zero:
    movzx ebx,bl
    shl ebx,2
    popf
    call dword ptr cs:[ebx].float_type_tab
;
    finit    
    ret
FloatToString   ENDP

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
    fld tbyte ptr ds:[ebp+eax].math_st0
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
    mov dx,ds:[ebp].math_tag
    mov ax,ds:[ebp].math_status
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
    DW OFFSET cpu_thread
    DB ' DT='
    DW OFFSET reg_ldt.d_selector
    DB 0

word_reg_tab2:
    DB ' CS='
    DW OFFSET reg_cs.d_selector
    DB ' DS='
    DW OFFSET reg_ds.d_selector
    DB ' ES='
    DW OFFSET reg_es.d_selector
    DB ' FS='
    DW OFFSET reg_fs.d_selector
    DB ' GS='
    DW OFFSET reg_gs.d_selector
    DB ' SS='
    DW OFFSET reg_ss.d_selector
    DB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dword reg tab
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dword_reg_tab1:
    DB ' EAX='
    DW OFFSET reg_eax
    DB ' EBX='
    DW OFFSET reg_ebx
    DB ' ECX='
    DW OFFSET reg_ecx
    DB ' EDX='
    DW OFFSET reg_edx
    DB 0

dword_reg_tab2:
    DB ' ESI='
    DW OFFSET reg_esi
    DB ' EDI='
    DW OFFSET reg_edi
    DB ' ESP='
    DW OFFSET reg_esp
    DB ' EBP='
    DW OFFSET reg_ebp
    DB 0

dword_reg_tab3:
    DB ' EPC='
    DW OFFSET reg_eip
    DB 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           qword reg tab
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

qword_reg_tab1:
    DB ' RAX='
    DW OFFSET reg_eax
    DB ' RBX='
    DW OFFSET reg_ebx
    DB ' RCX='
    DW OFFSET reg_ecx
    DB 0

qword_reg_tab2:
    DB ' RDX='
    DW OFFSET reg_edx
    DB ' RSI='
    DW OFFSET reg_esi
    DB ' RDI='
    DW OFFSET reg_edi
    DB 0

qword_reg_tab3:
    DB '  R8='
    DW OFFSET reg_r8
    DB '  R9='
    DW OFFSET reg_r9
    DB ' R10='
    DW OFFSET reg_r10
    DB 0

qword_reg_tab4:
    DB ' R11='
    DW OFFSET reg_r11
    DB ' R12='
    DW OFFSET reg_r12
    DB ' R13='
    DW OFFSET reg_r13
    DB 0

qword_reg_tab5:
    DB ' R14='
    DW OFFSET reg_r14
    DB ' R15='
    DW OFFSET reg_r15
    DB 0

qword_reg_tab6:
    DB ' RIP='
    DW OFFSET reg_eip
    DB ' RSP='
    DW OFFSET reg_esp
    DB ' RBP='
    DW OFFSET reg_ebp
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
;           NAME:           GetCpu
;
;           DESCRIPTION:    Get CPU info
;
;           PARAMETERS:     ES:EDI              Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCpu  Proc near
    mov ax,ds:[ebp].cpu_tss
    or ax,ax
    jz gcLong

gcProt:
    call GetProtCpu
    ret

gcLong:
    call GetLongCpu
    ret
GetCpu  Endp

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
;           NAME:           Debug process
;
;           DESCRIPTION:    Debug process
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_name          DB 'New Debug',0

debug_process:
    sti
    mov ax,41h
    EnableFocus
    int 3
;
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    mov ebp,OFFSET cpu
;
    GetThread
    mov ds:[ebp].cpu_thread,ax
    mov ds:[ebp].cpu_read_mem,OFFSET read_mem
    mov ds:[ebp].cpu_write_mem,OFFSET write_mem
;    
    mov bx,cs
    mov ds:[ebp].reg_eip,OFFSET dis64
    mov ds:[ebp].reg_eip+4,0
    mov ds:[ebp].reg_cs.d_selector,bx
    GetSelectorBitness
    cmp al,16
    je dis16
;
    cmp al,32
    je dis32

dis64:
    mov ds:[ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_64
    jmp disdo

dis32:
    mov ds:[ebp].reg_cs.d_access,ACCESS_READ OR ACCESS_32
    jmp disdo

dis16:
    mov ds:[ebp].reg_cs.d_access,ACCESS_READ

disdo:    
    pushfd
    pop eax
    mov ds:[ebp].reg_eflags,eax
;
    sldt ax
    mov ds:[ebp].reg_ldt.d_selector,ax
;
    mov ax,cs
    mov ds:[ebp].reg_cs.d_selector,ax
;
    mov ax,ss
    mov ds:[ebp].reg_ss.d_selector,ax
;
    mov ax,ds
    mov ds:[ebp].reg_ds.d_selector,ax
;
    mov ax,es
    mov ds:[ebp].reg_es.d_selector,ax
;
    mov ax,fs
    mov ds:[ebp].reg_fs.d_selector,ax
;
    mov ax,gs
    mov ds:[ebp].reg_gs.d_selector,ax
;
    mov ds:[ebp].reg_eax,eax
    mov ds:[ebp].reg_ebx,ebx
    mov ds:[ebp].reg_ecx,ecx
    mov ds:[ebp].reg_edx,edx
;
    mov ds:[ebp].reg_esi,esi
    mov ds:[ebp].reg_edi,edi
    mov ds:[ebp].reg_esp,esp
    mov ds:[ebp].reg_ebp,ebp
;
    mov ds:[ebp].cpu_fault,0EEFh
    mov ds:[ebp].cpu_exc_code,3
;
    finit
    fld tbyte ptr cs:val
;    
    push ds
    mov ax,ds
    mov es,ax
    GetThread
    mov ds,ax
;    
    mov ax,ds:p_tss_sel
    mov es:[ebp].cpu_tss,ax
;
    mov ax,ds:p_math_tag
    mov es:[ebp].math_tag,ax
;
    mov ax,ds:p_math_status
    mov es:[ebp].math_status,ax
;    
    mov esi,OFFSET p_math_st0
    lea edi,[ebp].math_st0
    mov ecx,20
    rep movsd
    pop ds
;
    mov edi,OFFSET buf
    call GetCpu
;
    xor al,al
    stosb 
;
    mov edi,OFFSET buf
    WriteAsciiz   

marker_loop:
    mov ax,250
    WaitMilliSec
    jmp marker_loop    

val  DT 156.56

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_debug_process
;
;           DESCRIPTION:    Create kernel debugger process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_debug_process      PROC far
    push ds
    push es
    pushad
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET debug_process
    mov edi,OFFSET debug_name
    mov ecx,stack0_size
    mov ax,26
    CreateProcess
    popad
    pop es
    pop ds
    ret
init_debug_process      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov eax,cs
    mov ds,eax
    mov es,eax  
    mov edi,OFFSET init_debug_process
    HookInitTasking
    clc
    ret
init    Endp
    
code    ENDS

    END init
