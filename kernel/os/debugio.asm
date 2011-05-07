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
; DEBUGIO.ASM
; User interface for kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
;
; offsets in trapgate, vmode
;

vm_edx      EQU -12

data    SEGMENT byte public 'DATA'

op_in_text      DB 100 DUP(?)
op_text_end     DW ?
op_size     DW ?

mouse_pos       DW ?

data    ENDS

code    SEGMENT byte public 'CODE'

    extrn dis_ass_one:near
    extrn float_to_string:near

    extrn GetDataGood:near
    extrn GetDataSel:near
    extrn GetDataOffset:near
    extrn SetIpAds:near
    extrn GetOpBuf:near
    
    extrn ReadData:near
    extrn GetIllegalOsGate:near
    extrn GetIllegalUserGate:near
    extrn GetOsCall:near
    extrn GetUserCall:near

    extrn interact_incr:near
    extrn interact_decr:near
    extrn interact_set_value:near

    extrn incdec_eax:near
    extrn incdec_ebx:near
    extrn incdec_ecx:near
    extrn incdec_edx:near
    extrn incdec_esi:near
    extrn incdec_edi:near
    extrn incdec_esp:near
    extrn incdec_ebp:near
    extrn incdec_epc:near
    extrn incdec_cs:near
    extrn incdec_ds:near
    extrn incdec_es:near
    extrn incdec_fs:near
    extrn incdec_gs:near
    extrn incdec_ss:near

.386p

    assume cs:code

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
    WriteChar
    loop write_delim_loop
    pop cx
    call NewLine
    pop ax
    ret
Delimiter       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NewLine
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NewLine Proc near
    push ax
    mov al,13
    WriteChar
    mov al,10
    WriteChar
    pop ax
    ret
NewLine Endp

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
    WriteChar
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
    WriteChar
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb write_byte_high1
    add al,7
write_byte_high1:
    add al,'0'
    WriteChar
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
    WriteChar
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
    WriteChar
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
et_vi   DB 'PDI',       'PEI'

iopl_text       DB ' IOPL=',0

WriteEflags     PROC near
    push es
    push di
    mov ax,cs
    mov es,ax
    mov ax,word ptr gs:p_tss_eflags
    and ax,200h
    shr ax,7
    or ax,word ptr gs:p_tss_eflags+2
    shl eax,16
    mov ax,word ptr gs:p_tss_eflags
    push ds
    mov ds,gs:tss_thread
    mov ds,ds:p_process_sel
    and ax,NOT 200h
    mov bx,ds:ms_virt_flags
    and bx,200h
    or ax,bx
    pop ds
    mov di,OFFSET eflags_tab
    mov cx,19
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
    WriteSizeString
    pop cx
    pop di
eflags_skip:
    shr eax,1
    add di,6
    loop eflags_loop
    mov di,OFFSET iopl_text
    WriteAsciiz
    mov ax,word ptr gs:p_tss_eflags
    shr ax,12
    and ax,3
    add ax,'0'
    WriteChar
    pop di
    pop es
    ret
WriteEflags     ENDP

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
    DW 0
    DB ' DT='
    DW OFFSET p_tss_ldt
    DB 0
word_reg_tab2:
    DB ' CS='
    DW OFFSET p_tss_cs
    DB ' DS='
    DW OFFSET p_tss_ds
    DB ' ES='
    DW OFFSET p_tss_es
    DB ' FS='
    DW OFFSET p_tss_fs
    DB ' GS='
    DW OFFSET p_tss_gs
    DB ' SS='
    DW OFFSET p_tss_ss
    DB 0

WriteWordRegs   PROC near
word_write_loop:
    mov al,es:[di]
    or al,al
    je word_write_end
    mov cx,4
    WriteSizeString
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

dword_reg_tab1:
    DB ' EAX='
    DW OFFSET p_tss_eax
    DB ' EBX='
    DW OFFSET p_tss_ebx
    DB ' ECX='
    DW OFFSET p_tss_ecx
    DB ' EDX='
    DW OFFSET p_tss_edx
    DB 0
dword_reg_tab2:
    DB ' ESI='
    DW OFFSET p_tss_esi
    DB ' EDI='
    DW OFFSET p_tss_edi
    DB ' ESP='
    DW OFFSET p_tss_esp
    DB ' EBP='
    DW OFFSET p_tss_ebp
    DB 0
dword_reg_tab3:
    DB ' EPC='
    DW OFFSET p_tss_eip
    DB 0

WriteDwordRegs  PROC near
dword_write_loop:
    mov al,es:[di]
    or al,al
    je dword_write_end
    mov cx,5
    WriteSizeString
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
;           NAME:           WriteDataRow
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AX          Segment
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDataRow    PROC near
    mov dx,ax
    mov ax,gs:tss_thread
    mov es,ax
    call WriteHexPtr32
    mov cx,16
    push ebx
write_data_loop:
    mov al,' '
    WriteChar
    call ReadData
    jc write_data_inv
    call WriteHexByte
    jmp write_data_next
write_data_inv:
    WriteChar
    WriteChar
write_data_next:
    inc ebx
    loop write_data_loop
    pop ebx
    mov al,' '
    WriteChar
    mov cx,16
write_ascii_loop:
    call ReadData
    cmp al,20h
    jnc write_ascii_do
    mov al,' '
write_ascii_do:
    WriteChar
    inc ebx
    loop write_ascii_loop
write_data_end:
    ret
WriteDataRow    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteFault
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ft_intr DB 'Interrupt fault   ',0
ft_inst DB 'Instruction fault ',0

ft_idt  DB 'idt ',0
ft_ldt  DB 'ldt ',0
ft_gdt  DB 'gdt ',0

WriteFault      PROC near
    test word ptr gs:p_tss_eflags+2,2
    jnz write_fault_end
    mov es,gs:tss_thread
    mov ax,es:p_error_code
    cmp ax,3
    je write_fault_end
    mov ax,cs
    mov es,ax
    mov di,OFFSET ft_inst
    mov ax,gs:tss_error_code
    or ax,ax
    jz write_fault_end
    test ax,1
    jz fault_not_int
    mov di,OFFSET ft_intr
fault_not_int:
    WriteAsciiz
;
    mov ax,gs:tss_error_code
    test ax,2
    jz fault_not_idt
    mov di,OFFSET ft_idt
    jmp write_fault_reason
fault_not_idt:
    mov di,OFFSET ft_gdt
    test ax,4
    jz write_fault_reason
    mov di,OFFSET ft_ldt
write_fault_reason:
    WriteAsciiz
    mov ax,gs:tss_error_code
    and ax,0FFF8h
    call WriteHexWord
    ret
write_fault_end:
    mov cx,30
    call Blank
    ret
WriteFault      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteIntCode
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

WriteIntCode    Proc near
    mov es,gs:tss_thread
    mov dx,es:p_error_code
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
    WriteSizeString
    ret
WriteIntCode    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteThread
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteThread     Proc near
    mov ax,gs:tss_thread
    mov es,ax
    mov ax,es:p_id
    call WriteHexWord
    mov al,' '
    WriteChar
    WriteChar
    mov di,OFFSET thread_name
    mov cx,30
    WriteSizeString
    call NewLine
    ret
WriteThread     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteFreeMem
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

phys_mem_comment    DB 'Physical ',0
global_mem_comment      DB '   Global ',0
local_mem_comment       DB '   Local ',0

WriteFreeMem    PROC near
    mov ax,cs
    mov es,ax
;
    mov di,OFFSET phys_mem_comment
    WriteAsciiz
    GetFreePhysical
    call WriteHexDword
;
    mov di,OFFSET global_mem_comment
    WriteAsciiz
    UsedBigLinear
    push edx
    push eax
    UsedSmallLinear
    pop edx
    add eax,edx
    pop edx
    call WriteHexDword
;
    mov di,OFFSET local_mem_comment
    WriteAsciiz
    mov bx,gs:tss_thread
    UsedLocalLinearThread
    call WriteHexDword
    call NewLine
    ret
WriteFreeMem    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteData
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteData       PROC near
    push ds
    mov ax,SEG data
    mov ds,ax
    call GetDataGood
    or al,al
    jz data_no_good
;       
    call GetDataSel
    call GetDataOffset
    call WriteDataRow
    jmp data_next
data_no_good:
    mov cx,79
    call Blank
data_next:
    call NewLine
    pop ds
;
    mov ax,gs:p_tss_cs
    mov bx,word ptr gs:p_tss_eip+2
    shl ebx,16
    mov bx,word ptr gs:p_tss_eip
    call WriteDataRow
    call NewLine
;
    mov ax,gs:p_tss_ss
    mov bx,word ptr gs:p_tss_esp+2
    shl ebx,16
    mov bx,word ptr gs:p_tss_esp
    call WriteDataRow
    call NewLine
;
    mov ax,gs:p_tss_es
    xor ebx,ebx
    call WriteDataRow
    call NewLine
;
    mov es,gs:tss_thread
    push word ptr gs:p_tss_eflags+2
    mov word ptr gs:p_tss_eflags+2,0
    mov ax,es:p_pm_deb_sel
    mov ebx,es:p_pm_deb_offs
    call WriteDataRow
    call NewLine
;
    mov word ptr gs:p_tss_eflags+2,2
    mov ax,es:p_vm_deb_sel
    mov ebx,es:p_vm_deb_offs
    call WriteDataRow
    pop word ptr gs:p_tss_eflags+2
    ret
WriteData       ENDP

GetMne  PROC near
    push si
    push di
;
    xor dl,dl
    xor dh,dh
    mov bx,gs:p_tss_cs
    test byte ptr gs:p_tss_eflags+2,2
    jnz get_cs_bitness_done

get_cs_bitness_pm:
    test bx,4
    jz get_cs_bitness_gdt

get_cs_bitness_ldt:
    mov es,gs:tss_thread
    mov es,es:p_ldt_sel
    jmp get_cs_bitness_test

get_cs_bitness_gdt:
    mov ax,gdt_sel
    mov es,ax

get_cs_bitness_test:
    and bx,0FFF8h
    mov dl,es:[bx+6]
    shr dl,6
    and dl,1

get_cs_bitness_done:
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
    add ebx,gs:p_tss_eip
    add ebx,4
;
    push ebx
    mov dx,gs:p_tss_cs
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    pop ebx
    jnc write_special_end
;
    mov dx,gs:p_tss_cs
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
    add bx,word ptr gs:p_tss_eip
    add bx,2
    push bx
    mov dx,gs:p_tss_cs
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    pop bx
    jnc write_special_end
;
    mov dx,gs:p_tss_cs
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
    pop di
    pop si
    ret
GetMne  ENDP

LoadInstr       PROC near
    xor di,di
    mov ax,word ptr gs:p_tss_eflags+2
    test ax,2
    jnz seg_size_ok
    mov bx,gs:p_tss_cs
    test bx,4
    jz code_in_gdt
code_in_ldt:
    and bx,0FFF8h
    xor esi,esi
    mov si,bx
    mov es,gs:tss_thread
    mov es,es:p_ldt_sel
    mov al,es:[bx+6]
    shr al,6
    and ax,1
    mov di,ax
    jmp seg_size_ok
code_in_gdt:
    mov ax,gdt_sel
    mov ds,ax
    and bx,0FFF8h
    mov al,[bx+6]
    shr al,6
    and ax,1
    mov di,ax
seg_size_ok:
    mov ax,SEG data
    mov ds,ax
    mov es,gs:tss_thread
    mov dx,gs:p_tss_cs
    mov ebx,gs:p_tss_eip
    call SetIpAds
    call GetOpBuf
    mov cx,16
get_instr_loop:
    call ReadData
    mov [si],al
    inc ebx
    inc si
    loop get_instr_loop
    ret
LoadInstr       Endp

WriteInstr      Proc near
    call LoadInstr
    call GetMne
    jnc write_instr_do
;
    mov dx,di
    mov di,OFFSET op_in_text    
    call dis_ass_one
    mov ds:op_size,80

write_instr_do:
    mov ax,SEG data
    mov es,ax
    mov cx,40
    mov di,OFFSET op_in_text
    WriteSizeString
    ret
WriteInstr      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCoproc
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; dx = skrivposition
; di = math str„ng offset
; si = math register offset

math0   DB 'ST(0)=  ',0
math1   DB 'ST(1)=  ',0
math2   DB 'ST(2)=  ',0
math3   DB 'ST(3)=  ',0
math4   DB 'ST(4)=  ',0
math5   DB 'ST(5)=  ',0
math6   DB 'ST(6)=  ',0
math7   DB 'ST(7)=  ',0

zero    DB 'Zero                        ',0
nan     DB 'NAN                         ',0
empty   DB 'EMPTY                       ',0

; ax = tag word

write_math      PROC near       
    WriteAsciiz
    mov cl,al
    and cl,3
    jz write_math_norm
;
    cmp cl,1
    je write_math_zero
;
    cmp cl,2
    je write_math_nan

write_math_empty:
    push es
    mov di,cs
    mov es,di
    mov di,OFFSET Empty
    WriteAsciiz
    call NewLine
    pop es
    ret

write_math_nan:
    push es
    mov di,cs
    mov es,di
    mov di,OFFSET nan
    WriteAsciiz
    call NewLine
    pop es
    ret

write_math_zero:
    push es
    mov di,cs
    mov es,di
    mov di,OFFSET zero
    WriteAsciiz
    call NewLine
    pop es
    ret

write_math_norm:    
    fld tbyte ptr gs:[si]
    push es
    push ax
;
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET op_in_text
    mov al,' '
    mov cx,35
    rep stosb
    mov cx,35
    mov di,OFFSET op_in_text    
    mov dl,18
    call float_to_string
    WriteSizeString
    pop ax
    pop es
    call NewLine
    ret
write_math      ENDP

WriteCoproc     Proc near
    mov ax,cs
    mov es,ax
    finit
    mov dx,gs:p_math_tag
    mov ax,gs:p_math_status
    shr ax,3
    mov cl,ah
    and cl,7
    add cl,cl
    ror dx,cl
    mov edi,cr0
    test di,4
    jz write_real_math
;
    movzx si,cl
    mov ax,si
    shl ax,2
    add si,ax
    add si,OFFSET p_math_st0
    jmp write_math_do

write_real_math:
    mov si,OFFSET p_math_st0

write_math_do:
    mov ax,dx
    mov di,OFFSET math0
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st1
;
    mov si,OFFSET p_math_st0
    jmp write_st1

write_inc_st1:
    add si,10

write_st1:
    mov di,OFFSET math1
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st2
;
    mov si,OFFSET p_math_st0
    jmp write_st2

write_inc_st2:
    add si,10

write_st2:
    mov di,OFFSET math2
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st3
;
    mov si,OFFSET p_math_st0
    jmp write_st3

write_inc_st3:
    add si,10

write_st3:
    mov di,OFFSET math3
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st4
;
    mov si,OFFSET p_math_st0
    jmp write_st4

write_inc_st4:
    add si,10

write_st4:
    mov di,OFFSET math4
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st5
;
    mov si,OFFSET p_math_st0
    jmp write_st5

write_inc_st5:
    add si,10

write_st5:
    mov di,OFFSET math5
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st6
;
    mov si,OFFSET p_math_st0
    jmp write_st6

write_inc_st6:
    add si,10

write_st6:
    mov di,OFFSET math6
    call write_math
;
    ror ax,2
    cmp si,OFFSET p_math_st7
    jne write_inc_st7
;
    mov si,OFFSET p_math_st0
    jmp write_st7

write_inc_st7:
    add si,10

write_st7:
    mov di,OFFSET math7
    call write_math
    ret
WriteCoproc     Endp

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
;           NAME:           WriteStatus
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteStatus     Proc near
    call WriteIntCode
    mov al,' '
    WriteChar
    call WriteFault
    call NewLine
    ret
WriteStatus     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCpu
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpu    PROC near
    xor dx,dx
    xor cx,cx
    SetCursorPosition
    call WriteCoproc
    call Delimiter
    call WriteCpuReg
    call Delimiter
    call WriteFreeMem
    call WriteStatus
    call WriteInstr
    call WriteThread
    call Delimiter
    call WriteData
    xor dx,dx
    xor cx,cx
    SetCursorPosition
    ret
WriteCpu    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           interact_set
;
;           DESCRIPTION:    Interact set new value
;
;           PARAMETERS:         GS              TSS
;                           DX:ESI      Adress to data
;                           CL          Digit #
;                           CH              Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

interact_set    PROC near
    call interact_set_value
    inc word ptr [bp].vm_edx
    ret
interact_set    ENDP

change_eax      PROC near
    mov dx,gs
    mov esi,OFFSET p_tss_eax
    push di
    ret
    ret
change_eax      ENDP

change_ebx      PROC near
    mov dx,gs
    mov esi,OFFSET p_tss_ebx
    push di
    ret
    ret
change_ebx      ENDP

change_ecx      PROC near
    mov dx,gs
    mov esi,OFFSET p_tss_ecx
    push di
    ret
    ret
change_ecx      ENDP

change_edx      PROC near
    mov dx,gs
    mov esi,OFFSET p_tss_edx
    push di
    ret
    ret
change_edx      ENDP

change_esi      PROC near
    mov dx,gs
    mov esi,OFFSET p_tss_esi
    push di
    ret
    ret
change_esi      ENDP

change_edi      PROC near
    mov dx,gs
    mov esi,OFFSET p_tss_edi
    push di
    ret
    ret
change_edi      ENDP

change_esp      PROC near
    mov dx,gs
    mov esi,OFFSET p_tss_esp
    push di
    ret
    ret
change_esp      ENDP

change_ebp      PROC near
    mov dx,gs
    mov esi,OFFSET p_tss_ebp
    push di
    ret
    ret
change_ebp      ENDP

change_epc      PROC near
    mov dx,gs
    mov esi,OFFSET p_tss_eip
    push di
    ret
    ret
change_epc      ENDP

change_cs       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET p_tss_cs
    push di
    ret
    ret
change_cs       ENDP

change_ds       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET p_tss_ds
    push di
    ret
    ret
change_ds       ENDP

change_es       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET p_tss_es
    push di
    ret
    ret
change_es       ENDP

change_fs       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET p_tss_fs
    push di
    ret
    ret
change_fs       ENDP

change_gs       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET p_tss_gs
    push di
    ret
    ret
change_gs       ENDP

change_ss       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET p_tss_ss
    push di
    ret
    ret
change_ss       ENDP

toggle_cy       PROC near
    mov bx,OFFSET p_tss_eflags
    xor word ptr gs:[bx],1
    ret
toggle_cy       ENDP

toggle_pa       PROC near
    mov bx,OFFSET p_tss_eflags
    xor word ptr gs:[bx],4
    ret
toggle_pa       ENDP

toggle_ac       PROC near
    mov bx,OFFSET p_tss_eflags
    xor word ptr gs:[bx],10h
    ret
toggle_ac       ENDP

toggle_zr       PROC near
    mov bx,OFFSET p_tss_eflags
    xor word ptr gs:[bx],40h
    ret
toggle_zr       ENDP

toggle_pl       PROC near
    mov bx,OFFSET p_tss_eflags
    xor word ptr gs:[bx],80h
    ret
toggle_pl       ENDP

toggle_im       PROC near
    mov bx,OFFSET p_tss_eflags
    xor word ptr gs:[bx],200h
    ret
toggle_im       ENDP

toggle_dir      PROC near
    mov bx,OFFSET p_tss_eflags
    xor word ptr gs:[bx],400h
    ret
toggle_dir      ENDP

toggle_ov       PROC near
    mov bx,OFFSET p_tss_eflags
    xor word ptr gs:[bx],800h
    ret
toggle_ov       ENDP

toggle_nt       PROC near
    mov bx,OFFSET p_tss_eflags
    xor word ptr gs:[bx],4000h
    ret
toggle_nt       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           
;
;           DESCRIPTION:    Memory operations
;
;           PARAMETERS:         GS              TSS
;                           DX:ESI      Adress to data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_do  PROC near
    mov cl,[bp].vm_edx
    sub cl,cs:[bx+debug_col]
    mov bx,gs:tss_thread
mem_do_next:
    cmp cl,3
    jc mem_do_alloc
    sub cl,3
    inc esi
    jmp mem_do_next
mem_do_alloc:
    cmp cl,2
    je mem_do_end
    xor cl,1
    push cx
    push OFFSET mem_do_free
    push di
    ret
mem_do_free:
    pop cx
    or cl,cl
    jnz mem_do_end
    inc byte ptr [bp].vm_edx
mem_do_end:     
    ret
mem_do  ENDP

mem_ads PROC near
    ret
mem_ads ENDP

mem_cs  PROC near
    mov dx,gs:p_tss_cs
    mov si,OFFSET p_tss_eip
    mov esi,gs:[si]
    call mem_do
    ret
mem_cs  ENDP

mem_ss  PROC near
    mov dx,gs:p_tss_ss
    mov si,OFFSET p_tss_esp
    mov esi,gs:[si]
    call mem_do
    ret
mem_ss  ENDP

mem_es  PROC near
    mov dx,gs:p_tss_es
    xor esi,esi
    call mem_do
    ret
mem_es  ENDP

mem_pm  PROC near
    push word ptr gs:p_tss_eflags+2
    mov word ptr gs:p_tss_eflags+2,0
    mov es,gs:tss_thread
    mov dx,es:p_pm_deb_sel
    mov esi,es:p_pm_deb_offs
    call mem_do
    pop word ptr gs:p_tss_eflags+2
    ret
mem_pm  ENDP

change_pm_sel   PROC near
    push word ptr gs:p_tss_eflags+2
    mov word ptr gs:p_tss_eflags+2,0
    mov dx,gs:tss_thread
    and cl,3
    mov esi,OFFSET p_pm_deb_sel
    push cx
    push OFFSET change_pm_sel_ret
    push di
    ret
change_pm_sel_ret:
    pop cx
    or cl,cl
    jnz change_pm_sel_error
    inc byte ptr [bp].vm_edx
change_pm_sel_error:
    pop word ptr gs:p_tss_eflags+2
    ret
change_pm_sel   ENDP

change_pm_offs  PROC near
    push word ptr gs:p_tss_eflags+2
    mov word ptr gs:p_tss_eflags+2,0
    mov dx,gs:tss_thread
    mov esi,OFFSET p_pm_deb_offs
    push cx
    push OFFSET change_pm_offs_ret
    push di
    ret
change_pm_offs_ret:
    pop cx
    or cl,cl
    jnz change_pm_offs_error
    inc byte ptr [bp].vm_edx
change_pm_offs_error:
    pop word ptr gs:p_tss_eflags+2
    ret
change_pm_offs  ENDP

mem_vm  PROC near
    push word ptr gs:p_tss_eflags+2
    mov word ptr gs:p_tss_eflags+2,2
    mov es,gs:tss_thread
    mov dx,es:p_vm_deb_sel
    mov esi,es:p_vm_deb_offs
    call mem_do
    pop word ptr gs:p_tss_eflags+2
    ret
mem_vm  ENDP

change_vm_sel   PROC near
    push word ptr gs:p_tss_eflags+2
    mov word ptr gs:p_tss_eflags+2,0
    mov dx,gs:tss_thread
    and cl,3
    mov esi,OFFSET p_vm_deb_sel
    push cx
    push OFFSET change_vm_sel_ret
    push di
    ret
change_vm_sel_ret:
    pop cx
    or cl,cl
    jnz change_vm_sel_error
    inc byte ptr [bp].vm_edx
change_vm_sel_error:
    pop word ptr gs:p_tss_eflags+2
    ret
change_vm_sel   ENDP

change_vm_offs  PROC near
    push word ptr gs:p_tss_eflags+2
    mov word ptr gs:p_tss_eflags+2,0
    mov dx,gs:tss_thread
    mov esi,OFFSET p_vm_deb_offs
    push cx
    push OFFSET change_vm_offs_ret
    push di
    ret
change_vm_offs_ret:
    pop cx
    or cl,cl
    jnz change_vm_offs_error
    inc byte ptr [bp].vm_edx
change_vm_offs_error:
    pop word ptr gs:p_tss_eflags+2
    ret
change_vm_offs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           debug_call_do
;
;           DESCRIPTION:    Perform a function
;
;           PARAMETERS:         GS              TSS
;                           DI              Offset to debug-function
;                           CH              Digit / param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
debug_table:
;
;           rad     kolumn  antal   action
;
meax DW 9,          1,          3,          OFFSET incdec_eax
deax DW 9,          5,          8,          OFFSET change_eax
mebx DW 9,          14,         3,          OFFSET incdec_ebx
debx DW 9,          18,         8,          OFFSET change_ebx
mecx DW 9,          27,         3,          OFFSET incdec_ecx
decx DW 9,          31,         8,          OFFSET change_ecx
medx DW 9,          40,         3,          OFFSET incdec_edx
dedx DW 9,          44,         8,          OFFSET change_edx
mesi DW 10,         1,          3,          OFFSET incdec_esi
desi DW 10,         5,          8,          OFFSET change_esi
medi DW 10,         14,         3,          OFFSET incdec_edi
dedi DW 10,         18,         8,          OFFSET change_edi
mesp DW 10,         27,         3,          OFFSET incdec_esp
desp DW 10,         31,         8,          OFFSET change_esp
mebp DW 10,         40,         3,          OFFSET incdec_ebp
debp DW 10,         44,         8,          OFFSET change_ebp
mepc DW 11,         1,          3,          OFFSET incdec_epc
depc DW 11,         5,          8,          OFFSET change_epc
mcs  DW 12,         1,          2,          OFFSET incdec_cs
dcs      DW 12,     4,          4,          OFFSET change_cs
mds  DW 12,         9,          2,          OFFSET incdec_ds
dds      DW 12,     12,         4,          OFFSET change_ds
mes      DW 12,     17,         2,          OFFSET incdec_es
des  DW 12,         20,         4,          OFFSET change_es
mfs      DW 12,     25,         2,          OFFSET incdec_fs
dfs  DW 12,         28,         4,          OFFSET change_fs
mgs      DW 12,     33,         2,          OFFSET incdec_gs
dgs  DW 12,         36,         4,          OFFSET change_gs
mss      DW 12,     41,         2,          OFFSET incdec_ss
dss  DW 12,         44,         4,          OFFSET change_ss
dcy  DW 13,         0,          2,          OFFSET toggle_cy
dpa  DW 13,         3,          2,          OFFSET toggle_pa
dac  DW 13,         6,          2,          OFFSET toggle_ac
dzr  DW 13,         9,          2,          OFFSET toggle_zr
dplc DW 13,         12,         2,          OFFSET toggle_pl
disf DW 13,         15,         2,          OFFSET toggle_im
ddir DW 13,         18,         2,          OFFSET toggle_dir
dov  DW 13,         21,         2,          OFFSET toggle_ov
dnt  DW 13,         24,         2,          OFFSET toggle_nt
dgo  DW 16,         0,          30,         OFFSET go_sw
dtra DW 17,         0,          40,         OFFSET trace_sw
dnex DW 17,         40,         40,         OFFSET next_sw
mdad DW 19,         14,         47,         OFFSET mem_ads
mdcs DW 20,         14,         47,         OFFSET mem_cs
mdss DW 21,         14,         47,         OFFSET mem_ss
mdes DW 22,         14,         47,         OFFSET mem_es
pms  DW 23,         0,          4,          OFFSET change_pm_sel
pmo  DW 23,         5,          8,          OFFSET change_pm_offs
pdat DW 23,         14,         47,         OFFSET mem_pm
vms  DW 24,         0,          4,          OFFSET change_vm_sel
vmo  DW 24,         5,          8,          OFFSET change_vm_offs
vdat DW 24,         14,         47,         OFFSET mem_vm
dend DW 0FFFFh, 0FFFFh

debug_row       EQU 0
debug_col       EQU 2
debug_ant       EQU 4
debug_call      EQU 6
debug_size      EQU 8

debug_call_do   PROC near
    mov ax,[bp].vm_edx
    mov bx,OFFSET debug_table
d_c_loop:
    mov cl,cs:[bx+debug_row]
    cmp cl,0FFh
    je d_c_end
    cmp cl,ah
    jne not_this_entry
    mov cl,al
    sub cl,cs:[bx+debug_col]
    cmp cl,cs:[bx+debug_ant]
    jnc not_this_entry
    xor cl,7
    and cl,7
    mov ax,[bp].vm_eax
    call word ptr cs:[bx+debug_call]
    jmp d_c_end
not_this_entry:
    add bx,debug_size
    jmp d_c_loop
d_c_end:
    ret
debug_call_do   ENDP

inc_sw  PROC near
    pusha
    mov di,OFFSET interact_incr
    call debug_call_do
    popa
    ret
inc_sw  ENDP

dec_sw  PROC near
    pusha
    mov di,OFFSET interact_decr
    call debug_call_do
    popa
    ret
dec_sw  ENDP

;
; ch = siffra
;
set_base_sw     PROC near
    pusha
    mov di,OFFSET interact_set
    call debug_call_do
    popa
    ret
set_base_sw     ENDP

set0_sw PROC near
    mov ch,0
    call set_base_sw
    ret
set0_sw ENDP

set1_sw PROC near
    mov ch,1
    call set_base_sw
    ret
set1_sw ENDP

set2_sw PROC near
    mov ch,2
    call set_base_sw
    ret
set2_sw ENDP

set3_sw PROC near
    mov ch,3
    call set_base_sw
    ret
set3_sw ENDP

set4_sw PROC near
    mov ch,4
    call set_base_sw
    ret
set4_sw ENDP

set5_sw PROC near
    mov ch,5
    call set_base_sw
    ret
set5_sw ENDP

set6_sw PROC near
    mov ch,6
    call set_base_sw
    ret
set6_sw ENDP

set7_sw PROC near
    mov ch,7
    call set_base_sw
    ret
set7_sw ENDP

set8_sw PROC near
    mov ch,8
    call set_base_sw
    ret
set8_sw ENDP

set9_sw PROC near
    mov ch,9
    call set_base_sw
    ret
set9_sw ENDP

setA_sw PROC near
    mov ch,0Ah
    call set_base_sw
    ret
setA_sw ENDP

setB_sw PROC near
    mov ch,0Bh
    call set_base_sw
    ret
setB_sw ENDP

setC_sw PROC near
    mov ch,0Ch
    call set_base_sw
    ret
setC_sw ENDP

setD_sw PROC near
    mov ch,0Dh
    call set_base_sw
    ret
setD_sw ENDP

setE_sw PROC near
    mov ch,0Eh
    call set_base_sw
    ret
setE_sw ENDP

setF_sw PROC near
    mov ch,0Fh
    call set_base_sw
    ret
setF_sw ENDP

go_sw   PROC near
    DebugGo
    ret
go_sw   ENDP

trace_sw    PROC near
    DebugTrace
    ret
trace_sw    ENDP

pace_sw PROC near
    DebugPace
    ret
pace_sw ENDP

reg_sw  PROC near
    mov ax,gs:tss_thread
    mov es,ax
    mov gs,ax
    call WriteCpu
    ret
reg_sw  ENDP

next_sw PROC near
    DebugNext
    ret
next_sw ENDP

error_sw    PROC near
    ret
error_sw    ENDP
    
virt_sw_run     PROC near
    xor edx,edx
    mov dx,[bp].vm_edx
    shl edx,4
    push ds
    mov ax,gdt_sel
    mov ds,ax
    mov bx,temp_sel
    mov word ptr [bx],0FFFFh
    mov [bx+2],edx
    mov byte ptr [bx+5],9Ah
    shr edx,16
    xor dl,dl
    mov [bx+6],dx   
    pop ds
    mov ax,[bp].vm_ebx
    xchg ax,word ptr ds:p_tss_eip
    xchg bx,ds:p_tss_cs
    push es
    push bx
    mov bx,ds:p_tss_ss
    mov es,bx
    pop bx
    xor edx,edx
    mov dx,word ptr ds:p_tss_esp
    sub dx,4
    mov word ptr ds:p_tss_esp,dx
    mov es:[edx],ax
    mov es:[edx+2],bx
    pop es
    ret
virt_sw_run     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           debug_call_pr
;
;           DESCRIPTION:    Main debug entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    
virt_sw_func_tab:
vs_00   DW OFFSET error_sw
vs_01   DW OFFSET error_sw
vs_02   DW OFFSET error_sw
vs_03   DW OFFSET error_sw
vs_04   DW OFFSET error_sw
vs_05   DW OFFSET error_sw
vs_06   DW OFFSET error_sw
vs_07   DW OFFSET error_sw
vs_08   DW OFFSET error_sw
vs_09   DW OFFSET error_sw
vs_0A   DW OFFSET error_sw
vs_0B   DW OFFSET error_sw
vs_0C   DW OFFSET error_sw
vs_0D   DW OFFSET error_sw
vs_0E   DW OFFSET error_sw
vs_0F   DW OFFSET error_sw
vs_10   DW OFFSET error_sw
vs_11   DW OFFSET error_sw
vs_12   DW OFFSET error_sw
vs_13   DW OFFSET error_sw
vs_14   DW OFFSET error_sw
vs_15   DW OFFSET error_sw
vs_16   DW OFFSET error_sw
vs_17   DW OFFSET error_sw
vs_18   DW OFFSET error_sw
vs_19   DW OFFSET error_sw
vs_1A   DW OFFSET error_sw
vs_1B   DW OFFSET error_sw
vs_1C   DW OFFSET error_sw
vs_1D   DW OFFSET error_sw
vs_1E   DW OFFSET error_sw
vs_1F   DW OFFSET error_sw
vs_20   DW OFFSET error_sw
vs_21   DW OFFSET error_sw
vs_22   DW OFFSET error_sw
vs_23   DW OFFSET error_sw
vs_24   DW OFFSET error_sw
vs_25   DW OFFSET error_sw
vs_26   DW OFFSET error_sw
vs_27   DW OFFSET error_sw
vs_28   DW OFFSET error_sw
vs_29   DW OFFSET error_sw
vs_2A   DW OFFSET error_sw
vs_2B   DW OFFSET inc_sw
vs_2C   DW OFFSET error_sw
vs_2D   DW OFFSET dec_sw
vs_2E   DW OFFSET error_sw
vs_2F   DW OFFSET error_sw
vs_30   DW OFFSET set0_sw
vs_31   DW OFFSET set1_sw
vs_32   DW OFFSET set2_sw
vs_33   DW OFFSET set3_sw
vs_34   DW OFFSET set4_sw
vs_35   DW OFFSET set5_sw
vs_36   DW OFFSET set6_sw
vs_37   DW OFFSET set7_sw
vs_38   DW OFFSET set8_sw
vs_39   DW OFFSET set9_sw
vs_3A   DW OFFSET error_sw
vs_3B   DW OFFSET error_sw
vs_3C   DW OFFSET error_sw
vs_3D   DW OFFSET error_sw
vs_3E   DW OFFSET error_sw
vs_3F   DW OFFSET error_sw
vs_40   DW OFFSET error_sw
vs_41   DW OFFSET setA_sw
vs_42   DW OFFSET setB_sw
vs_43   DW OFFSET setC_sw
vs_44   DW OFFSET setD_sw
vs_45   DW OFFSET setE_sw
vs_46   DW OFFSET setF_sw
vs_47   DW OFFSET go_sw
vs_48   DW OFFSET error_sw
vs_49   DW OFFSET error_sw
vs_4A   DW OFFSET error_sw
vs_4B   DW OFFSET error_sw
vs_4C   DW OFFSET error_sw
vs_4D   DW OFFSET error_sw
vs_4E   DW OFFSET next_sw
vs_4F   DW OFFSET error_sw
vs_50   DW OFFSET pace_sw
vs_51   DW OFFSET error_sw
vs_52   DW OFFSET reg_sw
vs_53   DW OFFSET error_sw
vs_54   DW OFFSET trace_sw
vs_55   DW OFFSET error_sw
vs_56   DW OFFSET error_sw
vs_57   DW OFFSET error_sw
vs_58   DW OFFSET error_sw
vs_59   DW OFFSET error_sw
vs_5A   DW OFFSET error_sw
vs_5B   DW OFFSET error_sw
vs_5C   DW OFFSET error_sw
vs_5D   DW OFFSET error_sw
vs_5E   DW OFFSET error_sw
vs_5F   DW OFFSET error_sw
vs_60   DW OFFSET error_sw
vs_61   DW OFFSET setA_sw
vs_62   DW OFFSET setB_sw
vs_63   DW OFFSET setC_sw
vs_64   DW OFFSET setD_sw
vs_65   DW OFFSET setE_sw
vs_66   DW OFFSET setF_sw
vs_67   DW OFFSET go_sw
vs_68   DW OFFSET error_sw
vs_69   DW OFFSET error_sw
vs_6A   DW OFFSET error_sw
vs_6B   DW OFFSET error_sw
vs_6C   DW OFFSET error_sw
vs_6D   DW OFFSET error_sw
vs_6E   DW OFFSET next_sw
vs_6F   DW OFFSET error_sw
vs_70   DW OFFSET pace_sw
vs_71   DW OFFSET error_sw
vs_72   DW OFFSET reg_sw
vs_73   DW OFFSET error_sw
vs_74   DW OFFSET trace_sw
vs_75   DW OFFSET error_sw
vs_76   DW OFFSET error_sw
vs_77   DW OFFSET error_sw
vs_78   DW OFFSET error_sw
vs_79   DW OFFSET error_sw
vs_7A   DW OFFSET error_sw
vs_7B   DW OFFSET error_sw
vs_7C   DW OFFSET error_sw
vs_7D   DW OFFSET error_sw
vs_7E   DW OFFSET error_sw
vs_7F   DW OFFSET error_sw
vs_80   DW OFFSET error_sw
vs_81   DW OFFSET error_sw
vs_82   DW OFFSET error_sw
vs_83   DW OFFSET error_sw
vs_84   DW OFFSET error_sw
vs_85   DW OFFSET error_sw
vs_86   DW OFFSET error_sw
vs_87   DW OFFSET error_sw
vs_88   DW OFFSET error_sw
vs_89   DW OFFSET error_sw
vs_8A   DW OFFSET error_sw
vs_8B   DW OFFSET error_sw
vs_8C   DW OFFSET error_sw
vs_8D   DW OFFSET error_sw
vs_8E   DW OFFSET error_sw
vs_8F   DW OFFSET error_sw
vs_90   DW OFFSET error_sw
vs_91   DW OFFSET error_sw
vs_92   DW OFFSET error_sw
vs_93   DW OFFSET error_sw
vs_94   DW OFFSET error_sw
vs_95   DW OFFSET error_sw
vs_96   DW OFFSET error_sw
vs_97   DW OFFSET error_sw
vs_98   DW OFFSET error_sw
vs_99   DW OFFSET error_sw
vs_9A   DW OFFSET error_sw
vs_9B   DW OFFSET error_sw
vs_9C   DW OFFSET error_sw
vs_9D   DW OFFSET error_sw
vs_9E   DW OFFSET error_sw
vs_9F   DW OFFSET error_sw
vs_A0   DW OFFSET error_sw
vs_A1   DW OFFSET error_sw
vs_A2   DW OFFSET error_sw
vs_A3   DW OFFSET error_sw
vs_A4   DW OFFSET error_sw
vs_A5   DW OFFSET error_sw
vs_A6   DW OFFSET error_sw
vs_A7   DW OFFSET error_sw
vs_A8   DW OFFSET error_sw
vs_A9   DW OFFSET error_sw
vs_AA   DW OFFSET error_sw
vs_AB   DW OFFSET error_sw
vs_AC   DW OFFSET error_sw
vs_AD   DW OFFSET error_sw
vs_AE   DW OFFSET error_sw
vs_AF   DW OFFSET error_sw
vs_B0   DW OFFSET error_sw
vs_B1   DW OFFSET error_sw
vs_B2   DW OFFSET error_sw
vs_B3   DW OFFSET error_sw
vs_B4   DW OFFSET error_sw
vs_B5   DW OFFSET error_sw
vs_B6   DW OFFSET error_sw
vs_B7   DW OFFSET error_sw
vs_B8   DW OFFSET error_sw
vs_B9   DW OFFSET error_sw
vs_BA   DW OFFSET error_sw
vs_BB   DW OFFSET error_sw
vs_BC   DW OFFSET error_sw
vs_BD   DW OFFSET error_sw
vs_BE   DW OFFSET error_sw
vs_BF   DW OFFSET error_sw
vs_C0   DW OFFSET error_sw
vs_C1   DW OFFSET error_sw
vs_C2   DW OFFSET error_sw
vs_C3   DW OFFSET error_sw
vs_C4   DW OFFSET error_sw
vs_C5   DW OFFSET error_sw
vs_C6   DW OFFSET error_sw
vs_C7   DW OFFSET error_sw
vs_C8   DW OFFSET error_sw
vs_C9   DW OFFSET error_sw
vs_CA   DW OFFSET error_sw
vs_CB   DW OFFSET error_sw
vs_CC   DW OFFSET error_sw
vs_CD   DW OFFSET error_sw
vs_CE   DW OFFSET error_sw
vs_CF   DW OFFSET error_sw
vs_D0   DW OFFSET error_sw
vs_D1   DW OFFSET error_sw
vs_D2   DW OFFSET error_sw
vs_D3   DW OFFSET error_sw
vs_D4   DW OFFSET error_sw
vs_D5   DW OFFSET error_sw
vs_D6   DW OFFSET error_sw
vs_D7   DW OFFSET error_sw
vs_D8   DW OFFSET error_sw
vs_D9   DW OFFSET error_sw
vs_DA   DW OFFSET error_sw
vs_DB   DW OFFSET error_sw
vs_DC   DW OFFSET error_sw
vs_DD   DW OFFSET error_sw
vs_DE   DW OFFSET error_sw
vs_DF   DW OFFSET error_sw
vs_E0   DW OFFSET error_sw
vs_E1   DW OFFSET error_sw
vs_E2   DW OFFSET error_sw
vs_E3   DW OFFSET error_sw
vs_E4   DW OFFSET error_sw
vs_E5   DW OFFSET error_sw
vs_E6   DW OFFSET error_sw
vs_E7   DW OFFSET error_sw
vs_E8   DW OFFSET error_sw
vs_E9   DW OFFSET error_sw
vs_EA   DW OFFSET error_sw
vs_EB   DW OFFSET error_sw
vs_EC   DW OFFSET error_sw
vs_ED   DW OFFSET error_sw
vs_EE   DW OFFSET error_sw
vs_EF   DW OFFSET error_sw
vs_F0   DW OFFSET error_sw
vs_F1   DW OFFSET error_sw
vs_F2   DW OFFSET error_sw
vs_F3   DW OFFSET error_sw
vs_F4   DW OFFSET error_sw
vs_F5   DW OFFSET error_sw
vs_F6   DW OFFSET error_sw
vs_F7   DW OFFSET error_sw
vs_F8   DW OFFSET error_sw
vs_F9   DW OFFSET error_sw
vs_FA   DW OFFSET error_sw
vs_FB   DW OFFSET error_sw
vs_FC   DW OFFSET error_sw
vs_FD   DW OFFSET error_sw
vs_FE   DW OFFSET error_sw
vs_FF   DW OFFSET error_sw


    public debug_call_pr

debug_call_pr   PROC near
    push bp
    mov bp,sp
    push eax
    push ebx
    push edx
;
    mov ax,[bp].vm_eax
    cmp al,'r'
    jz wait_regs
    cmp al,'R'
    jnz no_wait_debug
wait_regs:
    mov ax,10
    WaitMilliSec
no_wait_debug:
    cmp al,'n'
    je debug_next
    cmp al,'N'
    je debug_next 
;
    GetDebugThreadSel
    or ax,ax
    jnz debug_do
;    
    mov ax,[bp].vm_eax
    mov al,'R'
    mov [bp].vm_eax,ax
    jmp debug_end

debug_do:
    mov ds,ax
    mov gs,ax

debug_next:
    mov ax,[bp].vm_eax
    mov bl,al
    xor bh,bh
    add bx,bx
    call word ptr cs:[bx].virt_sw_func_tab

debug_end:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    pop edx
    pop ebx
    pop eax
    pop bp
    ret
debug_call_pr   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoFunc
;
;           DESCRIPTION:    Do function
;
;           PARAMETERS:         CX          X
;                           DX          Y
;                           AL          CHAR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoFunc  PROC near
    HideMouse
    shr cx,3
    shr dx,3
    mov dh,dl
    mov dl,cl
    call debug_call_pr
    mov al,'r'
    call debug_call_pr
    movzx cx,dl
    movzx dx,dh
    shl cx,3
    shl dx,3
    SetMousePosition
    ShowMouse
    ret
DoFunc  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleKeyboard
;
;           DESCRIPTION:    Keyboard
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleKeyboard  Proc near
    mov eax,25
    WaitMilliSec
;
    PollKeyboard
    jc handle_key_end
;
    ReadKeyboard
    or al,al
    jz handle_key_special
    call DoFunc
    jmp handle_key_end

handle_key_special:  
    cmp ah,72
    jnz no_up_arrow

up_arrow:
    GetMousePosition
    sub dx,8
    SetMousePosition
    jmp handle_key_end

no_up_arrow:
    cmp ah,80
    jnz no_down_arrow

down_arrow:
    GetMousePosition
    add dx,8
    SetMousePosition
    jmp handle_key_end

no_down_arrow:
    cmp ah,75
    jnz no_left_arrow

left_arrow:
    GetMousePosition
    sub cx,8
    SetMousePosition
    jmp handle_key_end

no_left_arrow:
    cmp ah,77
    jnz handle_key_end

right_arrow:
    GetMousePosition
    add cx,8
    SetMousePosition

handle_key_end:
    ret
HandleKeyboard  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleMouse
;
;           DESCRIPTION:    Mouse handler
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleMouse     Proc near
    GetLeftButton
    jc handle_not_left

left_button:
    GetLeftButtonPressPosition
    mov al,'+'
    call DoFunc
left_rel_loop:
    call HandleKeyboard
    GetLeftButton
    jnc left_rel_loop

handle_not_left:
    GetRightButton
    jc handle_mouse_done

right_button:
    GetRightButtonPressPosition
    mov al,'-'
    call DoFunc
right_rel_loop:
    call HandleKeyboard
    GetRightButton
    jnc right_rel_loop
handle_mouse_done:
    ret
HandleMouse     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MARKER
;
;           DESCRIPTION:    ANROP AV MARK™R
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


debug_name          DB 'Debug',0

debug_process:
    sti
    mov ax,42h
    EnableFocus
    mov ax,250
    WaitMilliSec
    xor ax,ax
    xor bx,bx
    mov cx,639
    mov dx,199
    SetMouseWindow
    mov cx,8
    mov dx,8
    SetMouseMickey
;       
    ShowMouse
marker_loop:
    call HandleKeyboard
    call HandleMouse
    GetMousePosition
    SetMousePosition
    jmp marker_loop

init_debug_process      PROC far
    push ds
    push es
    pusha
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET debug_process
    mov di,OFFSET debug_name
    mov ecx,512
    mov ax,26
    CreateProcess
    popa
    pop es
    pop ds
    retf32
init_debug_process      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_local
;
;           DESCRIPTION:    Init local
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_local
    
init_local      PROC near
    mov ax,cs
    mov es,ax
;
    mov edi,OFFSET init_debug_process
    HookInitTasking
;
    mov bx,SEG data
    mov es,bx
    mov es:mouse_pos,0
    clc
    ret
init_local      ENDP

code    ENDS

    END
