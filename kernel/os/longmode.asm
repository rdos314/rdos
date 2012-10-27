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
; NASM.ASM
; Nasm test device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


%include '..\driver.def'
%include '..\osnasm.def'
%include '..\usernasm.def'

IA32_EFER   equ 0xC0000080

PAE_CR3_LINEAR  equ 2000h
MAP_LINEAR      equ 3000h
UNITY_MAP_SIZE  equ 10000h

IA64_PAE_LINEAR equ 11000h
IA64_CR3_LINEAR equ 12000h

%macro OsGate 1
    db 3Eh
    db 67h
    db 9Ah
    dd %1
    dw 2
%endmacro

%macro UserGate 1
    db 3Eh
    db 67h
    db 9Ah
    dd %1
    dw 3
%endmacro

struc Reg64

reg_rax:    resq 1
reg_rcx:    resq 1
reg_rdx:    resq 1
reg_rbx:    resq 1
reg_rsp:    resq 1
reg_rbp:    resq 1
reg_rsi:    resq 1
reg_rdi:    resq 1
reg_r8:     resq 1
reg_r9:     resq 1
reg_r10:    resq 1
reg_r11:    resq 1
reg_r12:    resq 1
reg_r13:    resq 1
reg_r14:    resq 1
reg_r15:    resq 1
reg_rip:    resq 1
reg_cs:     resw 1
reg_ds:     resw 1
reg_es:     resw 1
reg_fs:     resw 1
reg_gs:     resw 1
reg_ss:     resw 1
reg_flags:  resq 1

reg_end:    resb 1

endstruc
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;   32-bit device driver header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   bits 32

section .header progbits start=0x00000000 vstart=0x00000000 align=1

hdr         dw 0x3252
cip         dd init
code_size   dd text_end - text_start + boot_end
code_sel    dw long_dev_code_sel
data_size   dd 0
data_sel    dw 0
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;    NAME:           Init_task
;
;    DESCRIPTION:    Init tasking
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .boot progbits follows=.header vstart=0x00000000 align=1
    
init_task:
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,test_thread
    mov edi,test_thread_name
    mov ax,4
    mov ecx,0x1000
    OsGate create_process
;
    popad
    pop es
    pop ds    
    retf
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;    NAME:           Init
;
;    DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init:
    OsGate has_long_mode
    jc init_done
;
    mov bx,long_kernel_code_sel
    OsGate create_long_code_sel
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,init_task
    OsGate hook_init_tasking

init_done:    
    retf

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;    NAME:           Test_thread
;
;    DESCRIPTION:    Test thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_thread_name  DB 'Nasm Test Thread', 0

test_thread:
    int 3 
    mov bx,ss
    OsGate get_selector_base_size
    add edx,esp
    mov ax,syscall_data_sel
    mov ss,ax
    mov esp,edx    
;    
    mov esi,boot_end
    mov edi,text_start
    mov ecx,UNITY_MAP_SIZE
    mov bx,cs
    OsGate prepare_long_mode

boot_end:    

section .text progbits follows=.boot vstart=MAP_LINEAR align=1

text_start:
    mov edx,PAE_CR3_LINEAR
    xor ebx,ebx
    mov eax,cr3
    or al,67h
    OsGate set_page_entry
;    
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;
    mov esi,PAE_CR3_LINEAR
    mov edi,IA64_PAE_LINEAR
    mov ecx,400h
    rep movsd
;
    mov edi,IA64_PAE_LINEAR
    mov al,7
    stosb
;    
    add edi,7    
    stosb
;    
    add edi,7    
    stosb
;    
    add edi,7    
    stosb
;
    mov edi,IA64_CR3_LINEAR
    mov eax,IA64_PAE_LINEAR + 7
    stosd
    xor eax,eax
    mov ecx,0x3FF
    rep stosd    
;    
    mov edi,cr3
;
    mov edx,0xB8000
    mov eax,0xB8007
    xor ebx,ebx
    OsGate set_page_entry
;    
    cli
    mov eax,cr0
    and eax,7FFFFFFFh
    mov cr0,eax
;
    mov ecx,IA32_EFER
    rdmsr
    or eax,0x100
    wrmsr
;
    mov eax,IA64_CR3_LINEAR
    mov cr3,eax  
;
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax

    jmp long_kernel_code_sel:test64

test32:        
    mov eax,cr0
    and eax,7FFFFFFFh
    mov cr0,eax
;
    mov ecx,IA32_EFER
    rdmsr
    and eax,0xFFFFFEFF   
    wrmsr
;
    mov cr3,edi
;
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
    sti
    int 3
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  64-bit test code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    bits 64

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteChar
;
;   DESCRIPTION:    Write a char to screen
;
;   PARAMETERS:     DL          Char
;                   DH          Attrib
;                   AL          Row
;                   AH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteChar:
    push rax
    push rbx
    push rcx
;    
    mov cx,ax
    mov al,80
    mul ch
    add al,cl
    adc ah,0
    add ax,ax
    movzx rbx,ax
    mov [r8+rbx],dx
;
    pop rcx
    pop rbx
    pop rax
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SingleHex
;
;   DESCRIPTION:    Convert number to printable hex
;
;   PARAMETERS:     AL          Value
;
;   RETURNS:        AX          Hex value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SingelHex:
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb shLow1
    
    add al,7

shLow1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb shHigh1
    
    add ah,7

shHigh1:
    add ah,30h
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteSpace
;
;   DESCRIPTION:    Write space
;
;   PARAMETERS:     CL          Attrib
;                   DL          Row
;                   DH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSpace:
    push rax
    push rcx
    push rdx
;
    mov ah,cl    
    xchg rax,rdx
    mov dl,'_'
    call WriteChar
;    
    pop rdx
    pop rcx
    pop rax
    add dl,1
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteHexByte
;
;   DESCRIPTION:    Write a hex byte to screen
;
;   PARAMETERS:     AL          Data
;                   CL          Attrib
;                   DL          Row
;                   DH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte:
    push rax
    push rcx
    push rdx
;
    mov ah,cl
    mov cx,ax
    call SingelHex
;    
    push rax
    xchg rax,rdx
    mov dh,ch
    call WriteChar
    pop rdx
;    
    inc al
    mov dl,dh
    mov dh,ch
    call WriteChar
    pop rdx
    add dl,2
;    
    pop rcx
    pop rax
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteHexWord
;
;   DESCRIPTION:    Write a hex word to screen
;
;   PARAMETERS:     AX          Data
;                   CL          Attrib
;                   DL          Row
;                   DH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord:
    push rax
    rol ax,8
    call WriteHexByte
    rol ax,8
    call WriteHexByte
    pop rax
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteHexDword
;
;   DESCRIPTION:    Write a hex dword to screen
;
;   PARAMETERS:     EAX         Data
;                   CL          Attrib
;                   DL          Row
;                   DH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword:
    push rax
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    pop rax
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteHexQword
;
;   DESCRIPTION:    Write a hex qword to screen
;
;   PARAMETERS:     RAX         Data
;                   CL          Attrib
;                   DL          Row
;                   DH          Col
;                   R8          Screen base
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexQword:
    push rax
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
;  
    call WriteSpace
;    
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
    rol rax,8
    call WriteHexByte
    pop rax
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteString
;
;   DESCRIPTION:    Write string to screen
;
;   PARAMETERS:     RDI         String
;                   AH          Attrib
;                   DH          Row
;                   DL          Col
;                   RCX         Characters
;                   R8          Screen base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteString:
    xchg rax,rdx
    push rdi
    push rbx

wsLoop:
    push rax
    mov bh,al
    mov al,ah
    mov bl,80
    mul bl
    add al,bh
    adc ah,0
    add ax,ax
    movzx rbx,ax
    pop rax
    mov dl,[rdi]
    cmp dl,13
    jne wsNotCr

    xor al,al
    jmp wsEnd

wsNotCr:
    cmp dl,10
    jne wsNotLf

    inc ah
    jmp wsEnd
    
wsNotLf:
    mov [r8+rbx],dx
    
    inc al

wsEnd:
    cmp al,80
    jne wsLineShiftOk

    inc ah
    mov al,0

wsLineShiftOk:
    cmp ah,24
    jb wsPageShiftOk
    
    mov ah,24       

wsPageShiftOk:
    inc rdi
    loop wsLoop

    pop rbx
    pop rdi
    xchg rax,rdx
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteQwordReg
;
;   DESCRIPTION:    Write 64-bit registers
;
;   PARAMETERS:     RDI     Register table
;                   CL      Attrib
;                   DH      Row
;                   DL      Col
;                   R8      Video
;                   R15     Register state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteQwordReg:
    push rcx
    mov ah,cl
    mov rcx,4
    call WriteString
    pop rcx   
    add rdi,4
;
    xor rbx,rbx
    mov ebx,[rdi]
    mov rax,[r15+rbx]
    call WriteHexQword
    add rdi,4
    inc dl
    mov al,[rdi]
    or al,al
    jnz WriteQwordReg
;
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteSegReg
;
;   DESCRIPTION:    Write segment registers
;
;   PARAMETERS:     CL      Attrib
;                   DH      Row
;                   DL      Col
;                   R8      Video
;                   R15     Register state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

seg_reg_tab:
    db 'CS='
    dd reg_cs
    db 'DS='
    dd reg_ds
    db 'ES='
    dd reg_es
    db 'FS='
    dd reg_fs
    db 'GS='
    dd reg_gs
    db 'SS='
    dd reg_ss
    db 0

WriteSegReg:
    mov rdi,seg_reg_tab

wsrLoop:
    push rcx
    mov ah,cl
    mov rcx,3
    call WriteString
    pop rcx   
    add rdi,3
;
    xor rbx,rbx
    mov ebx,[rdi]
    mov ax,[r15+rbx]
    call WriteHexWord
    add rdi,4
    inc dl
    mov al,[rdi]
    or al,al
    jnz wsrLoop
;
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteFlags
;
;   DESCRIPTION:    Write FLAGS
;
;   PARAMETERS:     DH      Row
;                   DL      Col
;                   R8      Video
;                   R15     Register state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


flags_tab:
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
et_end  DB 0FFh

WriteFlags:
    mov rbx,reg_flags
    mov rax,[r15+rbx]
    mov rdi,flags_tab

wfLoop:
    mov ch,[rdi]
    or ch,ch
    je wfNext
;    
    cmp ch,0FFh
    je wfDone
;    
    push rdi
    mov cl,10
    test ax,1
    jz wfPosOk
;
    add rdi,3
    mov cl,12

wfPosOk:
    push rax
    mov ah,cl
    mov rcx,3
    call WriteString
    pop rax
    pop rdi
    
wfNext:
    add rdi,6
    shr rax,1
    jmp wfLoop
    
wfDone:
    ret
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   qword reg tables
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

qword_reg_tab1:
    db 'RAX='
    dd reg_rax
    db 'RBX='
    dd reg_rbx
    db 'RCX='
    dd reg_rcx
    db 0

qword_reg_tab2:
    db 'RDX='
    dd reg_rdx
    db 'RSI='
    dd reg_rsi
    db 'RDI='
    dd reg_rdi
    db 0

qword_reg_tab3:
    db ' R8='
    dd reg_r8
    db ' R9='
    dd reg_r9
    db 'R10='
    dd reg_r10
    db 0

qword_reg_tab4:
    db 'R11='
    dd reg_r11
    db 'R12='
    dd reg_r12
    db 'R13='
    dd reg_r13
    db 0

qword_reg_tab5:
    db 'R14='
    dd reg_r14
    db 'R15='
    dd reg_r15
    db 0

qword_reg_tab6:
    db 'RIP='
    dd reg_rip
    db 'RSP='
    dd reg_rsp
    db 'RBP='
    dd reg_rbp
    db 0


test_str    DB 'Long mode test string', 0

regs  times reg_end db 0

test64:
    push r15
    mov r15,regs
    mov [r15+reg_rax],rax
    mov [r15+reg_rcx],rcx
    mov [r15+reg_rdx],rdx
    mov [r15+reg_rbx],rbx
    mov [r15+reg_rbp],rbp
    mov [r15+reg_rsi],rsi
    mov [r15+reg_rdi],rdi
    mov [r15+reg_r8],r8
    mov [r15+reg_r9],r9
    mov [r15+reg_r10],r10
    mov [r15+reg_r11],r11
    mov [r15+reg_r12],r12
    mov [r15+reg_r13],r13
    mov [r15+reg_r14],r14
    pop rax
    mov [r15+reg_r15],rax
    mov [r15+reg_rsp],rsp
    mov qword [r15+reg_rip],test64
;
    mov word [r15+reg_cs],cs
    mov word [r15+reg_ds],ds
    mov word [r15+reg_es],es
    mov word [r15+reg_fs],fs
    mov word [r15+reg_gs],gs
    mov word [r15+reg_ss],ss
;
    pushfq
    pop qword rax
    mov qword [r15+reg_flags],rax
;
    mov r8,0xB8000
    xor rdx,rdx
;    
    mov rdi,qword_reg_tab1
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,qword_reg_tab2
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,qword_reg_tab3
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,qword_reg_tab4
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,qword_reg_tab5
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,qword_reg_tab6
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov cl,10
    xor dl,dl
    call WriteSegReg
    inc dh
    xor dl,dl
;    
    mov cl,10
    xor dl,dl
    call WriteFlags
    inc dh
    xor dl,dl

stopl:
    jmp stopl        


text_end:
