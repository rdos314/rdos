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
; KDEBUG.ASM
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
    pop ax
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
;           DESCRIPTION:    ES:EDI      Buffer
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
    mov ds:[ebp].reg_eip,OFFSET debug_process
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
    mov edi,OFFSET buf
    mov ecx,40

dis_next:    
    call DisAsmCode
;
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
    mov edi,OFFSET buf
    mov ds:[ebp].cpu_fault,0EEFh
    call AddFault    

marker_loop:
    mov ax,250
    WaitMilliSec
    jmp marker_loop    

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
