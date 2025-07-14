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
; REMDEBUG.ASM
; Remote debugger interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\user.def
INCLUDE ..\os.inc
INCLUDE ..\user.inc
INCLUDE ipcdebug.inc
INCLUDE system.def

data    SEGMENT byte public 'DATA'

MailslotHandle          DW ?
SendBuf                 debug_req_struc <>
CurrentThreadSel        DW ?
Info                    debug_req_info_struc <>
Mne                     debug_req_instr_struc <>
DataHeader              debug_req_data_struc <>
DataArr                 DB 2 * 16 DUP(?)
MathBuf                 DB 80 DUP(?)
ReplyBuf                DB 1024 DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code

    extrn float_to_string:near
    extrn move_cursor:near

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
;
    mov cx,19
    call Blank    
;
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
;           NAME:           WriteHexQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     EDX:EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexQword   PROC near
    push eax
;    
    push eax
    mov eax,edx
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
;
    mov al,'_'
    WriteChar
;
    pop eax
;    
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
;
    pop eax    
    ret
WriteHexQword   Endp

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
;           NAME:           WriteHex64
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DX          High offset
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHex64   PROC near
    push eax
    mov ax,dx
    call WriteHexWord
    mov al,'_'
    WriteChar
    mov eax,ebx
    call WriteHexDword
    pop eax
    ret
WriteHex64   ENDP

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
    mov ax,word ptr gs:p_rflags
    and ax,200h
    shr ax,7
    or ax,word ptr gs:p_rflags+2
    shl eax,16
    mov ax,word ptr gs:p_rflags
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
    mov ax,word ptr gs:p_rflags
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
;           NAME:           WriteQwordRegs
;
;           DESCRIPTION:    
;
;           PARAMETERS:         ES:DI       Offset to table
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

WriteQwordRegs  PROC near
qword_write_loop:
    mov al,es:[di]
    or al,al
    je qword_write_end
;
    mov cx,5
    WriteSizeString
    add di,5
;    
    mov bx,es:[di]
    mov eax,gs:[bx]
    mov edx,gs:[bx+4]
    call WriteHexQword
    add di,2
    jmp qword_write_loop
    
qword_write_end:
    ret
WriteQwordRegs  ENDP

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
    mov ds:DataHeader.dd_op,DEBUG_REQ_DATA
    test word ptr gs:p_rflags+2,2
    jz write_mode_prot
write_mode_virt:
    mov ds:DataHeader.dd_vm,1
    jmp write_mode_ok
write_mode_prot:
    mov ds:DataHeader.dd_vm,0

write_mode_ok:
    push ax
    mov ds:DataHeader.dd_offset,ebx
    mov ds:DataHeader.dd_sel,ax
    mov ds:DataHeader.dd_count,16
;
    mov ax,ds
    mov es,ax
    pusha
    mov bx,ds:MailslotHandle
    mov si,OFFSET DataHeader
    mov cx,SIZE debug_req_data_struc
    mov di,OFFSET DataHeader
    mov ax,32 + SIZE debug_req_data_struc
    SendMailslot
    cmp cx,32 + SIZE debug_req_data_struc
    popa
    pop dx
    jne write_data_end
;       
    call WriteHexPtr32
    mov cx,16
    mov di,OFFSET DataArr
    push ebx
write_data_loop:
    mov al,' '
    WriteChar
    mov ax,es:[di]
    add di,2
    or ah,ah
    jz write_data_inv
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
    mov di,OFFSET DataArr
write_ascii_loop:
    mov al,es:[di]
    add di,2
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
;           NAME:           WriteDataRow64
;
;           DESCRIPTION:    
;
;           PARAMETERS:     AX          High offset
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDataRow64    PROC near
    mov ds:DataHeader.dd_op,DEBUG_REQ_DATA
    mov ds:DataHeader.dd_vm,2
;
    push ax
    mov ds:DataHeader.dd_offset,ebx
    mov ds:DataHeader.dd_sel,ax
    mov ds:DataHeader.dd_count,16
;
    mov ax,ds
    mov es,ax
    pusha
    mov bx,ds:MailslotHandle
    mov si,OFFSET DataHeader
    mov cx,SIZE debug_req_data_struc
    mov di,OFFSET DataHeader
    mov ax,32 + SIZE debug_req_data_struc
    SendMailslot
    cmp cx,32 + SIZE debug_req_data_struc
    popa
    pop dx
    jne write_data_end
;       
    call WriteHex64
    mov cx,16
    mov di,OFFSET DataArr
    push ebx
write_data_loop64:
    mov al,' '
    WriteChar
    mov ax,es:[di]
    add di,2
    or ah,ah
    jz write_data_inv64
;
    call WriteHexByte
    jmp write_data_next64

write_data_inv64:
    WriteChar
    WriteChar

write_data_next64:
    inc ebx
    loop write_data_loop64
    pop ebx
;    
    mov al,' '
    WriteChar
    mov cx,16
    mov di,OFFSET DataArr

write_ascii_loop64:
    mov al,es:[di]
    add di,2
    cmp al,20h
    jnc write_ascii_do64
;    
    mov al,' '

write_ascii_do64:
    WriteChar
    inc ebx
    loop write_ascii_loop64

write_data_end64:
    ret
WriteDataRow64    ENDP

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
    test word ptr gs:p_rflags+2,2
    jnz write_fault_end
    mov eax,gs:p_fault_code
    cmp ax,3
    je write_fault_end
    mov ax,cs
    mov es,ax
    mov di,OFFSET ft_inst
    mov eax,gs:p_fault_code
    or ax,ax
    jz write_fault_end
    test ax,1
    jz fault_not_int
    mov di,OFFSET ft_intr
fault_not_int:
    WriteAsciiz
;
    mov eax,gs:p_fault_code
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
    mov eax,gs:p_fault_code
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
    movzx dx,gs:p_fault_vector
    cmp dx,18
    ja wicDone
;    
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

wicDone:
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
    mov ax,gs
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

phys_mem_comment        DB 'Physical ',0
global_mem_comment      DB '   Global ',0
local_mem_comment       DB '   Local ',0

WriteFreeMem    PROC near
    mov ax,cs
    mov es,ax
;
    mov di,OFFSET phys_mem_comment
    WriteAsciiz
    mov eax,ds:Info.di_free_physical
    call WriteHexDword
;
    mov di,OFFSET global_mem_comment
    WriteAsciiz
    mov eax,ds:Info.di_used_small
    add eax,ds:Info.di_used_big
    call WriteHexDword
;
    mov di,OFFSET local_mem_comment
    WriteAsciiz
    mov eax,ds:Info.di_used_local
    call WriteHexDword
    call NewLine
    ret
WriteFreeMem    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteData32
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteData32       PROC near
    mov al,ds:Mne.ddi_data_good
    or al,al
    jz data_no_good32
;
    mov ax,ds:Mne.ddi_data_sel
    mov ebx,ds:Mne.ddi_data_offset
    call WriteDataRow
    jmp data_next32

data_no_good32:
    mov cx,79
    call Blank

data_next32:
    call NewLine
;
    mov ax,gs:p_cs
    mov ebx,dword ptr gs:p_rip
    call WriteDataRow
    call NewLine
;
    mov ax,gs:p_ss
    mov ebx,dword ptr gs:p_rsp
    call WriteDataRow
    call NewLine
;
    mov ax,gs:p_es
    xor ebx,ebx
    call WriteDataRow
    call NewLine
;
    push word ptr gs:p_rflags+2
    mov word ptr gs:p_rflags+2,0
    mov ax,fs:p_pm_deb_sel
    mov ebx,fs:p_pm_deb_offs
    call WriteDataRow
    call NewLine
;
    mov word ptr gs:p_rflags+2,2
    mov ax,fs:p_vm_deb_sel
    mov ebx,fs:p_vm_deb_offs
    call WriteDataRow
    pop word ptr gs:p_rflags+2
    ret
WriteData32       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteData64_32
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteData64_32       PROC near
    mov al,ds:Mne.ddi_data_good
    or al,al
    jz data_no_good64_32
;
    mov ax,ds:Mne.ddi_data_sel
    mov ebx,ds:Mne.ddi_data_offset
    call WriteDataRow
    jmp data_next64_32

data_no_good64_32:
    mov cx,79
    call Blank

data_next64_32:
    call NewLine
;
    mov ax,gs:p_cs
    mov ebx,dword ptr gs:p_rip
    call WriteDataRow
    call NewLine
;
    mov ax,gs:p_ss
    mov ebx,dword ptr gs:p_rsp
    call WriteDataRow
    call NewLine
;
    mov ax,gs:p_es
    xor ebx,ebx
    call WriteDataRow
    call NewLine
;
    push word ptr gs:p_rflags+2
    mov word ptr gs:p_rflags+2,0
    mov ax,fs:p_pm_deb_sel
    mov ebx,fs:p_pm_deb_offs
    call WriteDataRow
    call NewLine
;
    mov word ptr gs:p_rflags+2,2
    mov ax,fs:p_vm_deb_sel
    mov ebx,fs:p_vm_deb_offs
    call WriteDataRow64
    pop word ptr gs:p_rflags+2
    ret
WriteData64_32       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteData64
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteData64       PROC near
    mov al,ds:Mne.ddi_data_good
    or al,al
    jz data_no_good64
;
    mov ax,ds:Mne.ddi_data_sel
    mov ebx,ds:Mne.ddi_data_offset
    call WriteDataRow64
    jmp data_next64

data_no_good64:
    mov cx,79
    call Blank

data_next64:
    call NewLine
;
    mov ax,word ptr gs:p_rip+4
    mov ebx,dword ptr gs:p_rip
    call WriteDataRow64
    call NewLine
;
    mov ax,word ptr gs:p_rsp+4
    mov ebx,dword ptr gs:p_rsp
    call WriteDataRow64
    call NewLine
;
    mov ax,word ptr gs:p_rdi+4
    mov ebx,dword ptr gs:p_rdi
    call WriteDataRow64
    call NewLine
;
    push word ptr gs:p_rflags+2
    mov word ptr gs:p_rflags+2,0
    mov ax,fs:p_pm_deb_sel
    mov ebx,fs:p_pm_deb_offs
    call WriteDataRow
    call NewLine
;
    mov word ptr gs:p_rflags+2,2
    mov ax,fs:p_vm_deb_sel
    mov ebx,fs:p_vm_deb_offs
    call WriteDataRow64
    pop word ptr gs:p_rflags+2
    ret
WriteData64       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteInstr
;
;               DESCRIPTION:    Write instruction
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInstr      Proc near
    mov ax,ds
    mov es,ax
    mov bx,ds:MailslotHandle
    mov ds:Mne.ddi_op,DEBUG_REQ_INSTR
    mov si,OFFSET Mne
    mov cx,1
    mov di,OFFSET Mne
    mov ax,SIZE debug_req_instr_struc
    SendMailslot
;
    cmp cx,SIZE debug_req_instr_struc
    jne write_instr_done
;
    mov di,OFFSET Mne.ddi_mne
    mov cx,40
    WriteSizeString

write_instr_done:
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

zero    DB 'Zero                              ',0
nan     DB 'NAN                               ',0
empty   DB 'EMPTY                             ',0

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
    pop es
    jmp write_math_done

write_math_nan:
    push es
    mov di,cs
    mov es,di
    mov di,OFFSET nan
    WriteAsciiz
    pop es
    jmp write_math_done

write_math_zero:
    push es
    mov di,cs
    mov es,di
    mov di,OFFSET zero
    WriteAsciiz
    pop es
    jmp write_math_done

write_math_norm:    
    fld tbyte ptr gs:[si]
    push es
    push ax
;
    mov ax,ds
    mov es,ax
    mov di,OFFSET MathBuf
    mov al,' '
    mov cx,35
    rep stosb
    mov cx,35
    mov di,OFFSET MathBuf
    mov dl,18
    call float_to_string
    WriteSizeString
    pop ax
    pop es

write_math_done:
    mov cx,35
    call Blank
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
;           NAME:           WriteCpuReg32
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg32     Proc near
    push es
    mov ax,cs
    mov es,ax
;
    mov di,OFFSET dword_reg_tab1
    call WriteDwordRegs
    mov cx,16
    call Blank
    call NewLine
;
    mov di,OFFSET dword_reg_tab2
    call WriteDwordRegs
    mov cx,16
    call Blank
    call NewLine
;
    mov di,OFFSET dword_reg_tab3
    call WriteDwordRegs
;
    mov di,OFFSET word_reg_tab1
    call WriteWordRegs
    mov cx,40
    call Blank
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
WriteCpuReg32     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCpuReg64
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg64     Proc near
    push es
    mov ax,cs
    mov es,ax
;
    mov di,OFFSET qword_reg_tab1
    call WriteQwordRegs
    call NewLine
;
    mov di,OFFSET qword_reg_tab2
    call WriteQwordRegs
    call NewLine
;
    mov di,OFFSET qword_reg_tab3
    call WriteQwordRegs
    call NewLine
;
    mov di,OFFSET qword_reg_tab4
    call WriteQwordRegs
    call NewLine
;
    mov di,OFFSET qword_reg_tab5
    call WriteQwordRegs
    mov cx,20
    call Blank
    call NewLine
;
    mov di,OFFSET qword_reg_tab6
    call WriteQwordRegs
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
WriteCpuReg64     Endp

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
;           NAME:           WriteCpu32
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpu32    PROC near
    ClearText
    call WriteCoproc
    call Delimiter
    call WriteCpuReg32
    call Delimiter
    call WriteFreeMem
    call WriteStatus
    call WriteInstr
    call WriteThread
    call Delimiter
    call WriteData32
    xor dx,dx
    xor cx,cx
    call move_cursor
    ret
WriteCpu32    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCpu64_32
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpu64_32    PROC near
    ClearText
    mov cx,5*80
    call Blank
;    
    call Delimiter
    call WriteCpuReg64
    call Delimiter
    call WriteFreeMem
    call WriteStatus
    call WriteInstr
    call WriteThread
    call Delimiter
    call WriteData64_32
    xor dx,dx
    xor cx,cx
    call move_cursor
    ret
WriteCpu64_32    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCpu64_64
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpu64_64    PROC near
    ClearText
    mov cx,5*80
    call Blank
;    
    call Delimiter
    call WriteCpuReg64
    call Delimiter
    call WriteFreeMem
    call WriteStatus
    call WriteInstr
    call WriteThread
    call Delimiter
    call WriteData64
    xor dx,dx
    xor cx,cx
    call move_cursor
    ret
WriteCpu64_64    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           get_thread
;
;       DESCRIPTION:    Get current thread block
;
;       RETURNS:        NC              ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread      Proc near
    push es
    mov bx,ds:MailslotHandle
    mov ds:SendBuf.db_op,DEBUG_REQ_THREAD
    mov si,OFFSET SendBuf
    mov cx,1
    mov es,ds:CurrentThreadSel
    xor di,di
    mov ax,SIZE thread_seg
    SendMailslot
    cmp cx,SIZE thread_seg
    clc
    je get_thread_done
;
    stc

get_thread_done:
    pop es
    ret
get_thread      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           get_info
;
;               DESCRIPTION:    Get info block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_info        Proc near
    mov bx,ds:MailslotHandle
    mov ds:Info.di_op,DEBUG_REQ_INFO
    mov si,OFFSET Info
    mov cx,3
    mov di,OFFSET Info
    mov ax,SIZE debug_req_info_struc
    SendMailslot
    cmp cx,SIZE debug_req_info_struc
    clc
    je get_info_done
;
    stc

get_info_done:
    ret
get_info        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WriteAll
;
;               DESCRIPTION:    Write state
;
;               PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cpu_tab:
c00 DW OFFSET WriteCpu32
c01 DW OFFSET WriteCpu64_32
c02 DW OFFSET WriteCpu64_64

WriteAll        Proc near
    pusha
    call get_thread
    jc write_all_done
;
    call get_info
    mov bx,ds:Info.di_mode
    add bx,bx
    call word ptr cs:[bx].cpu_tab    

write_all_done:
    popa
    ret
WriteAll        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DoFunc
;
;               DESCRIPTION:    Do a function
;
;               PARAMETERS:             AL              Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoFunc  Proc near
    pusha
    mov ds:SendBuf.db_op,al
    GetMousePosition
    shr cx,3
    shr dx,3
    mov ds:SendBuf.db_x,cl
    mov ds:SendBuf.db_y,dl
    mov bx,ds:MailslotHandle
    mov si,OFFSET SendBuf
    mov cx,SIZE debug_req_struc
    mov di,OFFSET ReplyBuf
    mov ax,1024
    SendMailslot
    movzx cx,ds:ReplyBuf.db_x
    movzx dx,ds:ReplyBuf.db_y
    shl cx,3
    shl dx,3
    SetMousePosition
    mov ax,10
    WaitMilliSec
    call WriteAll
    popa
    ret
DoFunc  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   HandleKeyboard
;
;               DESCRIPTION:    Keyboard
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleKeyboard  Proc near
    mov ax,25
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
    GetMousePosition
    shr cx,3
    shr dx,3
    call move_cursor
    ret
HandleKeyboard  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           HandleMouse
;
;               DESCRIPTION:    Mouse handler
;
;               PARAMETERS:             
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
;               NAME:           DebugThread
;
;               DESCRIPTION:    Debug thread
;
;               PARAMETERS:     EDX     IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_name   DB 'Remote Debug', 0
mailslot_name       DB 'Debug',0

debug_process:
    mov ax,43h
    EnableFocus
    SetFocus
;    
    push edx
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

    
state_start:
    mov ax,100
    WaitMilliSec
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    pop edx
;
    or edx,edx
    jz debug_local

debug_remote:    
    mov ax,cs
    mov es,ax
    mov di,OFFSET mailslot_name
    GetRemoteMailslot
    mov ds:MailslotHandle,bx
    jmp debug_init

debug_local:
    mov ax,cs
    mov es,ax
    mov di,OFFSET mailslot_name
    GetLocalMailslot
    mov ds:MailslotHandle,bx

debug_init: 
    mov eax,SIZE thread_seg
    AllocateLocalMem
    mov ds:CurrentThreadSel,es
    mov fs,ds:CurrentThreadSel
    mov gs,ds:CurrentThreadSel
;
    mov ax,ds
    mov es,ax
;    
    call WriteAll

state_loop:
    call HandleKeyboard
    call HandleMouse
    GetMousePosition
    SetMousePosition
    jmp state_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           RemoteDebug
;
;               DESCRIPTION:    Remote debug task
;
;               PARAMETERS:     EDX     IP address to debug
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remote_debug_name   DB 'Remote Debug', 0

remote_debug    Proc far
    push ds
    push es
    pusha
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET debug_process
    mov edi,OFFSET debug_name
    mov ecx,stack0_size
    mov ax,20
    mov bx,1
    CreateProcess
    popa
    pop es
    pop ds
    retf32
remote_debug    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_remote
;
;           DESCRIPTION:    Init remote debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_remote

init_remote Proc near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET remote_debug
    mov edi,OFFSET remote_debug_name
    xor dx,dx
    mov ax,remote_debug_nr
    RegisterBimodalUserGate
    ret
init_remote    Endp

code    ENDS

    END
