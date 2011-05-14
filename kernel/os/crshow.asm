;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; CRSHOW.ASM
; Crash register dump
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE irq.inc
INCLUDE proc.inc
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE protseg.def

data    SEGMENT byte public 'DATA'

op_in_text      DB 100 DUP(?)
op_text_end     DW ?
op_size         DW ?

big_linear      DD ?
curr_pos        DW ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn dis_ass_one:near
    
    extrn SetIpAds:near
    extrn GetOpBuf:near
    extrn GetIllegalOsGate:near
    extrn GetIllegalUserGate:near
    extrn GetOsCall:near
    extrn GetUserCall:near

    extrn LocalSetPhysicalPage:near
    extrn LocalGetSelectorBaseSize:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowChar
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowChar Proc near
    push ds
    push es
    push ax
    push di
;
    mov di,__B800
    mov es,di
;    
    mov di,SEG data
    mov ds,di
;
    mov di,ds:curr_pos
    mov ah,7
    stosw
    mov ds:curr_pos,di
;
    pop di
    pop ax
    pop es
    pop ds    
    ret
ShowChar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowSizeString
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:DI       String
;                           CX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowSizeString Proc near
    push ds
    push es
    push fs
    push ax 
    push cx
    push si
    push di
;
    mov ax,es
    mov fs,ax
    mov si,di
;    
    mov di,__B800
    mov es,di
;    
    mov di,SEG data
    mov ds,di
;
    mov di,ds:curr_pos
    mov ah,7
    or cx,cx
    jz sssDone

sssLoop:    
    lods byte ptr fs:[si]
    stosw
    loop sssLoop

sssDone:
    mov ds:curr_pos,di
;
    pop di
    pop si
    pop cx
    pop ax
    pop fs
    pop es
    pop ds    
    ret
ShowSizeString Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowAsciiz
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:DI       String
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowAsciiz Proc near
    push ds
    push es
    push fs
    push ax
    push cx
    push si
    push di
;
    mov ax,es
    mov fs,ax
    mov si,di
;    
    mov di,__B800
    mov es,di
;    
    mov di,SEG data
    mov ds,di
;
    mov di,ds:curr_pos
    mov ah,7

saLoop:    
    lods byte ptr fs:[si]
    or al,al
    jz saDone
;    
    stosw
    jmp saLoop

saDone:
    mov ds:curr_pos,di
;
    pop di
    pop si
    pop cx
    pop ax
    pop fs
    pop es
    pop ds    
    ret
ShowAsciiz Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Clear
;
;           DESCRIPTION:    Clear screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Clear Proc near
    push ds
    push es
    push ax
    push cx
    push di
;    
    mov ax,SEG data
    mov ds,ax
;
    mov ds:curr_pos,0
    xor di,di
    mov ax,__B800
    mov es,ax
    mov ax,0720h
    mov cx,80 * 24
    rep stosw
;      
    pop di
    pop cx
    pop ax
    pop es
    pop ds    
    ret
Clear Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NewLine
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NewLine Proc near
    push ds
    push ax
    push cx
    push dx
;    
    mov ax,SEG data
    mov ds,ax
;
    mov ax,ds:curr_pos
    xor dx,dx
    mov cx,160
    div cx
;    
    inc ax
    mul cx
;
    mov dx,ax
    sub ax,ds:curr_pos
    mov cx,ax
    or cx,cx
    jz nlDone
;
    push es
    push di
;
    mov di,ds:curr_pos    
    mov ax,__B800
    mov es,ax
    mov ax,0720h
    rep stosw
;
    pop di
    pop es

nlDone:
    mov ds:curr_pos,dx 
;      
    pop dx
    pop cx
    pop ax
    pop ds    
    ret
NewLine Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delimiter
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delimiter       Proc near
    push ax
    push cx
    mov cx,60
    mov al,'-'
write_delim_loop:
    call ShowChar
    loop write_delim_loop
    pop cx
    call NewLine
    pop ax
    ret
Delimiter       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Blank
;
;           DESCRIPTION:    
;
;           PARAMETERS:         CX          Number of blanks to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Blank   Proc near
    push ax
    push cx
    mov al,' '
blank_loop:
    call ShowChar
    loop blank_loop
    pop cx
    pop ax
    ret
Blank   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AL          Number
;                           AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

singel_hex      PROC near
hex_conv_low:
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
    add al,7
ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
    add ah,7
ok_high1:
    add ah,30h
    ret
singel_hex      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AL          Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    PROC near
    push ax
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb write_byte_low1
    add al,7
write_byte_low1:
    add al,'0'
    call ShowChar
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb write_byte_high1
    add al,7
write_byte_high1:
    add al,'0'
    call ShowChar
    pop ax
    ret
WriteHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AX          Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    PROC near
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
    ret
WriteHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:         EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword   PROC near
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    ret
WriteHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexPtr16
;
;           DESCRIPTION:    
;
;           PARAMETERS:         DX          Segment
;                           BX          Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr16   PROC near
    push ax
    mov ax,dx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov ax,bx
    call WriteHexWord
    pop ax
    ret
WriteHexPtr16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexPtr32
;
;           DESCRIPTION:    
;
;           PARAMETERS:         DX          Segment
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr32   PROC near
    push eax
    mov ax,dx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov eax,ebx
    call WriteHexDword
    pop eax
    ret
WriteHexPtr32   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteEflags
;
;           DESCRIPTION:    
;
;           PARAMETERS:     GS      Core sel
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

WriteEflags     PROC near
    push es
    push di
    mov ax,cs
    mov es,ax
    mov ax,word ptr gs:cs_eflags
    and ax,200h
    shr ax,7
    or ax,word ptr gs:cs_eflags+2
    shl eax,16
    mov ax,word ptr gs:cs_eflags
    mov di,OFFSET eflags_tab
    mov cx,18
    
eflags_loop:
    mov dl,es:[di]
    or dl,dl
    je eflags_skip
    push di
    test ax,1
    jz eflags_pos_ok
    add di,3
    jmp eflags_write_one
    
eflags_pos_ok:
eflags_write_one:
    push cx
    mov cx,3
    call ShowSizeString
    pop cx
    pop di
eflags_skip:
    shr eax,1
    add di,6
    loop eflags_loop
;    
    mov di,OFFSET iopl_text
    call ShowAsciiz
    mov ax,word ptr gs:cs_eflags
    shr ax,12
    and ax,3
    add ax,'0'
    call ShowChar
    pop di
    pop es
    ret
WriteEflags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCore
;
;           DESCRIPTION:    Write core ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

proc_tab    DB 'Processor=',0    

WriteCore   PROC near
    mov di,OFFSET proc_tab
    call ShowAsciiz
    mov ax,gs:ps_id
    call WriteHexWord
;
    mov al,' '
    call ShowChar
    mov al,'('
    call ShowChar
;
    mov ax,gs
    call WriteHexWord
;
    mov al,')'
    call ShowChar
    mov al,' '
    call ShowChar
    ret
WriteCore   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteThread
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NoName DB 'No thread                       ', 0

WriteThread   PROC near
    push es
    push di
;    
    mov ax,gs:cs_tr
    or ax,ax
    jz wtNoThread
;    
    mov ax,gs:ps_curr_thread
    or ax,ax
    jz wtNoThread
;
    verr ax
    jnz wtNoThread
;
    mov es,ax
    mov di,OFFSET thread_name
    mov cx,32
    call ShowSizeString
    jmp wtDone

wtNoThread:
    mov ax,cs
    mov es,ax
    mov di,OFFSET NoName
    call ShowAsciiz

wtDone:
    pop di
    pop es
    ret
WriteThread Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteTable
;
;           DESCRIPTION:    Write IDT and GDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

table_reg_tab:
    DB ' GDT='
    DW OFFSET cs_gdtr
    DB ' IDT='
    DW OFFSET cs_idtr
    DB 0

WriteTable   PROC near
    mov di,OFFSET table_reg_tab

table_write_loop:
    mov al,es:[di]
    or al,al
    je table_write_end
;
    mov cx,5
    call ShowSizeString
    add di,5
    mov bx,es:[di]
    mov eax,gs:[bx+2]
    call WriteHexDword
    mov al,' '
    call ShowChar
    mov al,'('
    call ShowChar
    mov ax,gs:[bx]
    call WriteHexWord       
    mov al,')'
    call ShowChar
;    
    add di,2
    jmp table_write_loop

table_write_end:
    ret
WriteTable   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteSel
;
;           DESCRIPTION:    
;
;           PARAMETERS:         ES:DI       Offset to table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sel_reg_tr:
    DB ' TR='
    DW OFFSET cs_tr

sel_reg_ldt:
    DB ' DT='
    DW OFFSET cs_ldt

sel_reg_cs:
    DB ' CS='
    DW OFFSET cs_cs

sel_reg_ds:
    DB ' DS='
    DW OFFSET cs_ds

sel_reg_es:    
    DB ' ES='
    DW OFFSET cs_es

sel_reg_fs:    
    DB ' FS='
    DW OFFSET cs_fs

sel_reg_gs:
    DB ' GS='
    DW OFFSET cs_gs

sel_reg_ss:    
    DB ' SS='
    DW OFFSET cs_ss

sel_reg_us:    
    DB ' US='
    DW OFFSET cs_usel

sel_type_tab:
st00 DB 'Invalid         '
st01 DB 'TSS 16, avail   '
st02 DB 'LDT             '
st03 DB 'TSS 16, busy    '
st04 DB 'Call gate 16    '
st05 DB 'Task gate       '
st06 DB 'Int gate 16     '
st07 DB 'Trap gate 16    '
st08 DB 'Invalid         '
st09 DB 'TSS 32, avail   '
st0A DB 'Invalid         '
st0B DB 'TSS 32, busy    '
st0C DB 'Call gate 32    '
st0D DB 'Invalid         '
st0E DB 'Int gate 32     '
st0F DB 'Trap gate 32    '
st10 DB 'Read, up        '
st11 DB 'Read, up        '
st12 DB 'Read/write, up  '
st13 DB 'Read/write, up  '
st14 DB 'Read, down      '
st15 DB 'Read, down      '
st16 DB 'Read/write, down'
st17 DB 'Read/write, down'
st18 DB 'Code            '
st19 DB 'Code            '
st1A DB 'Code/read       '
st1B DB 'Code/read       '
st1C DB 'Code conf       '
st1D DB 'Code conf       '
st1E DB 'Code/read conf  ' 
st1F DB 'Code/read conf  ' 

WriteSelReg   PROC near
    mov cx,4
    call ShowSizeString
;
    add di,4
    mov bx,es:[di]
    mov bx,gs:[bx]
;    
    mov ax,bx
    call WriteHexWord
    mov al,' '
    call ShowChar
;    
    and bx,NOT 3
    or bx,bx
    jz write_sel_done
;
    test bx,4
    jz write_sel_gdt

write_sel_ldt:
    mov si,gs:cs_ldt
    or si,si
    jz write_sel_done
;
    test si,4
    jnz write_sel_done
;
    push bx
    mov bx,cx
    call LocalGetSelectorBaseSize
    pop bx        
    jc write_sel_done
;
    dec ecx    
    jmp write_sel_do

write_sel_gdt:
    movzx ecx,word ptr gs:cs_gdtr
    mov edx,dword ptr gs:cs_gdtr+2

write_sel_do:
    and bx,0FFF8h
    cmp bx,cx
    ja write_sel_done
;
    mov ax,flat_sel
    mov ds,ax
    movzx ebx,bx
    add ebx,edx
;
    mov al,[ebx+5]
    test al,80h
    jz write_sel_done
;
    xor ecx,ecx
    mov cl,[ebx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[ebx]
    test byte ptr [ebx+6],80h
    jz write_sel_small
;
    shl ecx,12
    or cx,0FFFh

write_sel_small:
    mov edx,[ebx+2]
    rol edx,8
    mov dl,[ebx+7]
    ror edx,8
;
    mov eax,edx
    call WriteHexDword
;
    mov al,' '
    call ShowChar
    mov al,'('
    call ShowChar
;
    mov eax,ecx
    call WriteHexDword
;
    mov al,')'
    call ShowChar    
    mov al,' '
    call ShowChar
;
    push di
    mov al,[ebx+5]
    and al,1Fh
    movzx di,al
    shl di,4
    add di,OFFSET sel_type_tab
    mov cx,16
    call ShowSizeString
    pop di

write_sel_done:
    ret
WriteSelReg   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteDwordRegs
;
;           DESCRIPTION:    
;
;           PARAMETERS:         ES:DI       Offset to table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dword_irq_tab:
    DB ' IRQ='
    DW OFFSET cs_irq
    DW 0

dword_cr_reg_tab:
    DB ' CR0='
    DW OFFSET cs_cr0
    DB ' CR2='
    DW OFFSET cs_cr2
    DB ' CR3='
    DW OFFSET cs_cr3
    DB ' CR4='
    DW OFFSET cs_cr4
    DB 0

dword_dr_reg_tab:
    DB ' DR0='
    DW OFFSET cs_dr0
    DB ' DR1='
    DW OFFSET cs_dr1
    DB ' DR2='
    DW OFFSET cs_dr2
    DB ' DR3='
    DW OFFSET cs_dr3
    DB 0

dword_reg_tab1:
    DB ' EAX='
    DW OFFSET cs_eax
    DB ' EBX='
    DW OFFSET cs_ebx
    DB ' ECX='
    DW OFFSET cs_ecx
    DB ' EDX='
    DW OFFSET cs_edx
    DB 0

dword_reg_tab2:
    DB ' ESI='
    DW OFFSET cs_esi
    DB ' EDI='
    DW OFFSET cs_edi
    DB ' ESP='
    DW OFFSET cs_esp
    DB ' EBP='
    DW OFFSET cs_ebp
    DB 0

dword_reg_tab3:
    DB ' EPC='
    DW OFFSET cs_eip
    DB 0

WriteDwordRegs  PROC near
dword_write_loop:
    mov al,es:[di]
    or al,al
    je dword_write_end
    mov cx,5
    call ShowSizeString
    add di,5
    mov bx,es:[di]
    mov eax,gs:[bx]
    call WriteHexDword
    add di,2
    jmp dword_write_loop
dword_write_end:
    ret
WriteDwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteFault
;
;           DESCRIPTION:    
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

WriteFault    Proc near
    mov al,' '
    call ShowChar
;    
    mov edx,gs:cs_fault
    cmp dx,18h
    jbe wfDo
;
    mov dx,14h    

wfDo:
    mov bx,dx
    add bx,bx
    add bx,bx
    add bx,bx
    mov cx,bx
    add cx,cx
    add bx,cx
    mov ax,cs
    mov es,ax
    mov di,OFFSET error_code_tab
    add di,bx
    mov cx,24
    call ShowSizeString
    ret
WriteFault    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteProcFlags
;
;           DESCRIPTION:    Write processor flag registers
;
;           PARAMETERS:     GS      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nest_text       DB 'Nesting=',0
flag_preempt    DB 'Preempt ',0
flag_prio       DB 'Prio ',0
flag_timer      DB 'Timer ',0

WriteProcFlags     PROC near
    push fs
;    
    mov ax,cs
    mov es,ax
    mov di,OFFSET nest_text
    call ShowAsciiz
    mov ax,gs:ps_nesting
    call WriteHexWord
;
    mov al,' '
    call ShowChar
;
    test gs:ps_flags,PS_FLAG_PREEMPT
    jz wpfNoPreempt
;
    mov di, OFFSET flag_preempt
    call ShowAsciiz

wpfNoPreempt:    
    test gs:ps_flags,PS_FLAG_PRIO_CHANGE
    jz wpfNoPrio
;
    mov di, OFFSET flag_prio
    call ShowAsciiz

wpfNoPrio:
    test gs:ps_flags,PS_FLAG_TIMER
    jz wpfNoTimer
;
    mov di, OFFSET flag_timer
    call ShowAsciiz

wpfNoTimer:
    pop fs
    ret
WriteProcFlags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBaseSize
;
;           DESCRIPTION:    
;
;           PARAMETERS:     GS          Core regs
;                           BX:EDX      Address
;
;           RETURNS:        NC
;                               EDX     Base
;                               ECX     Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBaseSize   PROC near
    push eax
    push ebx
    push esi
    push edi
;
    mov edi,edx 
;       
    and bx,NOT 3
    or bx,bx
    jz get_info_fail
;
    test bx,4
    jz get_info_gdt

get_info_ldt:
    mov si,gs:cs_ldt
    or si,si
    jz get_info_fail
;
    test si,4
    jnz get_info_fail
;
    push bx
    mov bx,si
    call LocalGetSelectorBaseSize
    pop bx        
    jc get_info_fail
;
    dec ecx    
    jmp get_info_do

get_info_gdt:
    movzx ecx,word ptr gs:cs_gdtr
    mov edx,dword ptr gs:cs_gdtr+2

get_info_do:
    and bx,0FFF8h
    cmp bx,cx
    ja get_info_fail
;
    mov ax,flat_sel
    mov ds,ax
    movzx ebx,bx
    add ebx,edx
;
    mov al,[ebx+5]
    test al,80h
    jz get_info_fail
;
    xor ecx,ecx
    mov cl,[ebx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[ebx]
    test byte ptr [ebx+6],80h
    jz get_info_small
;
    shl ecx,12
    or cx,0FFFh

get_info_small:
    mov edx,[ebx+2]
    rol edx,8
    mov dl,[ebx+7]
    ror edx,8
;
    sub ecx,edi
    jc get_info_fail
;
    add edx,edi
    clc
    jmp get_info_done

get_info_fail:
    stc

get_info_done:
    pop edi
    pop esi
    pop ebx
    pop eax
    ret
GetBaseSize   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBitness
;
;           DESCRIPTION:    
;
;           PARAMETERS:     GS          Core regs
;                           BX          Selector
;
;           RETURNS:        NC
;                               DL      Bitness (0 = 16, 1 = 32)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBitness   PROC near
    push ds
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    and bx,NOT 3
    or bx,bx
    jz get_bitness_fail
;
    test bx,4
    jz get_bitness_gdt

get_bitness_ldt:
    mov si,gs:cs_ldt
    or si,si
    jz get_bitness_fail
;
    test si,4
    jnz get_bitness_fail
;
    push bx
    mov bx,si
    call LocalGetSelectorBaseSize
    pop bx        
    jc get_bitness_fail
;
    dec ecx    
    jmp get_bitness_do

get_bitness_gdt:
    movzx ecx,word ptr gs:cs_gdtr
    mov edx,dword ptr gs:cs_gdtr+2

get_bitness_do:
    and bx,0FFF8h
    cmp bx,cx
    ja get_bitness_fail
;
    mov ax,flat_sel
    mov ds,ax
    movzx ebx,bx
    add ebx,edx
;
    mov dl,ds:[ebx+6]
    shr dl,6
    and dl,1
    clc
    jmp get_bitness_done
    
get_bitness_fail:
    stc

get_bitness_done:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
GetBitness   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadData
;
;       DESCRIPTION:    Read data item
;
;       PARAMETERS:     GS              Core regs
;                       EDX             Linear address
;
;       RETURNS:        NC
;                           AL  Data
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadData        Proc near
    push ds
    push ebx
;
    mov ebx,gs:cs_cr3
    mov cr3,ebx
    mov bx,flat_sel
    mov ds,bx
    mov al,[edx]
    clc
;
    pop ebx
    pop ds
    ret
        

    push ds
    push ebx
    push edx
    push si
    push di
;
    mov di,dx
    and di,0FFFh
;    
    and dx,0F000h
    mov ax,process_dir_sel
    mov ds,ax
    mov si,(alias_linear SHR 20) AND 0FFFh
    mov eax,gs:cs_cr3
    or ax,803h
    mov [si],eax
    mov eax,cr3
    mov cr3,eax
;
    mov eax,alias_linear
    shr edx,10
    and dl,0FCh
    add edx,eax
    mov ebx,edx
    shr edx,10
    and dl,0FCh
    mov ax,process_page_sel
    mov ds,ax
    mov eax,[edx]
    test al,1
    stc
    jz read_data_done
;       
    mov ax,flat_sel
    mov ds,ax
    mov eax,ds:[ebx]
;       
    mov bx,SEG data
    mov ds,bx
    mov edx,ds:big_linear
    mov bx,process_page_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,10
    and bl,0FCh
    mov [ebx],eax
;
    mov bx,SEG data
    mov ds,bx
    movzx edx,di
    add edx,ds:big_linear
    mov ax,flat_sel
    mov ds,ax
    mov al,ds:[edx]
    clc
    
read_data_done:
    pop di
    pop si
    pop edx
    pop ebx
    pop ds
    ret
ReadData        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteDataRow
;
;       DESCRIPTION:    Write a data row
;
;       PARAMETERS:     GS          Core regs
;                       BX:EDX      Address
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDataRow    Proc near
    mov ax,bx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov eax,edx
    call WriteHexDword
    mov al,' '
    call ShowChar
;
    push bx
    push edx
;    
    mov bp,16
    call GetBaseSize
    jc wdrDataInv

wdrDataLoop:
    call ReadData
    jc wdrDataUndef
;
    call WriteHexByte
    jmp wdrDataNext

wdrDataUndef:
    mov al,'%'
    call ShowChar
    call ShowChar

wdrDataNext:
    mov al,' '
    call ShowChar
;
    sub bp,1
    jz wdrChar
;
    add edx,1
    sub ecx,1
    jnc wdrDataLoop            

wdrDataInv:
    mov al,'!'
    call ShowChar
    call ShowChar
    mov al,' '
    call ShowChar
;
    sub bp,1
    jnz wdrDataInv

wdrChar:  
    pop edx
    pop bx
;    
    mov bp,16
    call GetBaseSize
    jc wdrCharInv

wdrCharLoop:
    call ReadData
    jnc wdrCharDo
;
    mov al,'%'

wdrCharDo:    
    call ShowChar
;
    add edx,1
    sub ecx,1
    jc wdrCharInv
;    
    sub bp,1
    jnz wdrCharLoop            
    jmp wdrDone

wdrCharInv:
    mov al,'!'
    call ShowChar
;
    sub bp,1
    jnz wdrCharInv

wdrDone:  
    ret
WriteDataRow    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMne
;
;       DESCRIPTION:    Get instruction text
;
;       PARAMETERS:     GS          Core regs
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


GetMne  PROC near
    push si
    push di
;    
    mov ax,SEG data
    mov ds,ax
    xor dh,dh
;
    mov bx,gs:cs_cs
    call GetBitness
    jc get_mne_done
;   
    mov di,OFFSET op_in_text
    call GetOpBuf
;
    mov bp,si

remove_ov_loop:
    mov al,[si]
    cmp al,66h
    je remove_ads16
;
    cmp al,67h
    jne remove_ov_done
;    
    inc dh
    inc si
    jmp remove_ov_loop

remove_ads16:
    inc dh
    inc si
    xor dl,1
    jmp remove_ov_loop

remove_ov_done:
    mov al,[si]
    cmp al,9Ah
    jne not_call_far
;
    test dl,1
    jz write_call_far16
;
    mov dx,[si+5]
    cmp dx,2
    je oscall
;        
    cmp dx,3
    je usercall_32
;
    cmp dx,1
    jne not_call32

usercall_32:
    mov eax,[si+1]
    cmp eax,usergate_entries
    jnc write_special_fail
;
    shl eax,5
    mov ebx,eax
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetIllegalUserGate
    mov ds:op_size,bx
    clc
    jmp write_special_end

oscall:
    mov eax,[si+1]
    cmp eax,osgate_entries
    jnc write_special_fail
;
    shl eax,4
    mov ebx,eax
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetIllegalOsGate
    mov ds:op_size,bx
    clc
    jmp write_special_end
    
not_call32:
    mov bx,[si+1]
    mov dx,[si+5]
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    jnc write_special_end
;
    mov bx,[si+1]
    mov dx,[si+5]
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end

write_call_far16:
    mov bx,[si+1]
    mov dx,[si+3]
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    jnc write_special_end
;
    mov bx,[si+1]
    mov dx,[si+3]
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end

not_call_far:
    cmp al,0E8h
    jne write_special_fail
;
    test dl,1
    jz write_call_near16
;
    inc si
    inc dh    
    movzx ebx,dh
    add ebx,[si]
    add ebx,dword ptr gs:cs_eip
    add ebx,4
;
    push ebx
    mov dx,gs:cs_cs
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    pop ebx
    jnc write_special_end
;
    mov dx,gs:cs_cs
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end
    
write_call_near16:
    inc si
    inc dh
    movzx bx,dh
    add bx,[si]
    add bx,word ptr gs:cs_eip
    add bx,2
    push bx
    mov dx,gs:cs_cs
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    pop bx
    jnc write_special_end
;
    mov dx,gs:cs_cs
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end

write_special_fail:
    stc

write_special_end:
        
get_mne_done:
    pop di
    pop si
    ret
GetMne  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetInstr
;
;       DESCRIPTION:    Fill instruction buffer
;
;       PARAMETERS:     GS          Core regs
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadInstr    Proc near
    mov ebx,dword ptr gs:cs_eip
    call SetIpAds
    call GetOpBuf
;
    mov bx,gs:cs_cs
    mov edx,dword ptr gs:cs_eip
;    
    call GetBaseSize
    jc read_instr_done
;    
    add ecx,1
    jc read_instr_full
;
    cmp ecx,16
    jb read_instr_loop

read_instr_full:
    mov ax,SEG data
    mov ds,ax
;    
    mov cx,16

read_instr_loop:
    call ReadData
    mov [si],al    
    inc edx
    inc si
    loop read_instr_loop
    clc

read_instr_done:
    ret
ReadInstr    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteInstr
;
;       DESCRIPTION:    Write instruction
;
;       PARAMETERS:     GS          Core regs
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInstr  Proc near
    push ds
    push es
    push fs
    pushad
;
    mov al,' '
    call ShowChar
;
    call ReadInstr
    jc write_instr_done
;
    call GetMne    
    jnc write_instr_do
;    
    mov bx,gs:cs_cs
    call GetBitness
    jc write_instr_done
;
    mov ax,SEG data
    mov ds,ax
    mov di,OFFSET op_in_text    
    call dis_ass_one
;
    mov ds:op_size,80

write_instr_do:
    mov ax,SEG data
    mov es,ax
    mov cx,40
    mov di,OFFSET op_in_text
    call ShowSizeString

write_instr_done:
    popad
    pop fs
    pop es
    pop ds 
    ret   
WriteInstr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCpuReg
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg     Proc near
    push es
    mov ax,cs
    mov es,ax
;
    call WriteCore
    call WriteThread
    call NewLine    
;
    call WriteTable
    mov di,OFFSET dword_irq_tab
    call WriteDwordRegs
    call NewLine    
;
    mov di,OFFSET dword_cr_reg_tab
    call WriteDwordRegs
    call NewLine
;
    mov di,OFFSET dword_dr_reg_tab
    call WriteDwordRegs
    call NewLine
;
    mov di,OFFSET dword_reg_tab1
    call WriteDwordRegs
    call NewLine
;
    mov di,OFFSET dword_reg_tab2
    call WriteDwordRegs
    call NewLine
;
    mov di,OFFSET dword_reg_tab3
    call WriteDwordRegs
    call WriteFault
    call WriteInstr
    call NewLine
;
    mov di,OFFSET sel_reg_tr
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_ldt
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_cs
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_ds
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_es
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_fs
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_gs
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_ss
    call WriteSelReg
    call NewLine
;
    mov di,OFFSET sel_reg_us
    call WriteSelReg
    call NewLine
;
    call WriteEflags
    call NewLine
;
    call WriteProcFlags
    call NewLine
;
    call Delimiter
;    
    mov bx,gs:cs_ss
    movzx edx,word ptr gs:cs_esp
    call WriteDataRow
    call NewLine    
;    
    mov bx,gs:cs_cs
    movzx edx,word ptr gs:cs_eip
    call WriteDataRow
    call NewLine    
;    
    mov bx,gs:cs_usel
    mov edx,gs:cs_uoffs
    call WriteDataRow
    call NewLine    
    pop es
    ret
WriteCpuReg     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowCrashCore
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ShowCrashCore
    
ShowCrashCore    Proc near
    push ds
    mov ax,SEG data
    mov ds,ax
    call Clear
    call WriteCpuReg
    pop ds
    ret
ShowCrashCore    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitCrashShow
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitCrashShow

InitCrashShow    Proc near
    push ds
;    
    mov ax,SEG data
    mov ds,ax
    mov ds:curr_pos,0
;
;    mov eax,1000h
;    AllocateBigLinear
    mov edx,global_page_linear + global_page_size - 1000h
    mov ds:big_linear,edx
;        
    pop ds
    ret
InitCrashShow    Endp

code    ENDS

    END
