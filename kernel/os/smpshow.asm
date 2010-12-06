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
; SMPSHOW.ASM
; SMP register dump
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
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE smpdeb.inc

data    SEGMENT byte public 'DATA'

curr_pos    DW ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

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

core_tab:
    DB ' Core=',0

WriteCore   PROC near
    mov di,OFFSET core_tab
    call ShowAsciiz
    mov ax,gs:cs_id
    call WriteHexWord
    ret
WriteCore   ENDP

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
;           NAME:           WriteWordRegs
;
;           DESCRIPTION:    
;
;           PARAMETERS:         ES:DI       Offset to table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

word_reg_tab1:
    DB ' TR='
    DW OFFSET cs_tr
    DB ' DT='
    DW OFFSET cs_ldt
    DB 0

word_reg_tab2:
    DB ' CS='
    DW OFFSET cs_cs
    DB ' DS='
    DW OFFSET cs_ds
    DB ' ES='
    DW OFFSET cs_es
    DB ' FS='
    DW OFFSET cs_fs
    DB ' GS='
    DW OFFSET cs_gs
    DB ' SS='
    DW OFFSET cs_ss
    DB 0

WriteWordRegs   PROC near
word_write_loop:
    mov al,es:[di]
    or al,al
    je word_write_end
    mov cx,4
    call ShowSizeString
    add di,4
    mov bx,es:[di]
    or bx,bx
    jnz word_write_norm
    mov ax,gs
    call WriteHexWord
    jmp word_write_cont
word_write_norm:
    mov ax,gs:[bx]
    call WriteHexWord       
word_write_cont:
    add di,2
    jmp word_write_loop
word_write_end:
    ret
WriteWordRegs   ENDP

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
    call NewLine    
;
    call WriteTable
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
;
    mov di,OFFSET word_reg_tab1
    call WriteWordRegs
    call NewLine
;
    mov di,OFFSET word_reg_tab2
    call WriteWordRegs
    call NewLine
;
    call WriteEflags
    call NewLine
    pop es
    ret
WriteCpuReg     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowCore
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ShowCore
    
ShowCore    Proc near
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ds:curr_pos,0
    call WriteCpuReg
    pop ds
    ret
ShowCore    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitShow
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitShow

InitShow    Proc near
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ds:curr_pos,0
    pop ds
    ret
InitShow    Endp

code    ENDS

    END
