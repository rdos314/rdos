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


include ..\driver.def
include ..\os.def
include ..\user.def
include ..\os.inc
include ..\user.inc

IA32_EFER       = 0C0000080h

MAP_LINEAR      = 110000h

IDT_LINEAR      = 11C000h
PAE_CR3_LINEAR  = 11D000h
IA64_PAE_LINEAR = 11E000h
IA64_CR3_LINEAR = 11F000h

UNITY_MAP_SIZE  = 10000h

pushq0  Macro
    db 6Ah
    db 0
        Endm

Reg64   struc

reg_fault   dw ?
reg_rax     dq ?
reg_rcx     dq ?
reg_rdx     dq ?
reg_rbx     dq ?
reg_rsp     dq ?
reg_rbp     dq ?
reg_rsi     dq ?
reg_rdi     dq ?
reg_r8      dq ?
reg_r9      dq ?
reg_r10     dq ?
reg_r11     dq ?
reg_r12     dq ?
reg_r13     dq ?
reg_r14     dq ?
reg_r15     dq ?
reg_rip     dq ?
reg_cs      dw ?
reg_ds      dw ?
reg_es      dw ?
reg_fs      dw ?
reg_gs      dw ?
reg_ss      dw ?
reg_flags   dq ?

reg_end     db ?

Reg64   Ends
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;   32-bit device driver header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.686p

Code32 segment byte public use32 'code32'

sign dw 6452h
eip  dd OFFSET init
ib   dd MAP_LINEAR
ic   dd UNITY_MAP_SIZE

    org MAP_LINEAR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateTrapGate
;
;   DESCRIPTION:    Create trap gate
;
;   PARAMETERS:     AL      Interrupt #
;                   BL      Dpl
;                   ESI     Entry point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   db 'Start of driver', 0
    
CreateTrapGate:
    push ds
    push eax
    push edx
    push edi
;
    mov dx,flat_sel
    mov ds,dx
;
    movzx edi,al
    shl edi,4
    add edi,IDT_LINEAR
;
    mov edx,esi
    mov [edi],dx
;
    shr edx,16
    mov [edi+6],dx
;
    mov dx,long_kernel_code_sel
    mov [edi+2],dx
;
    xor edx,edx    
    mov [edi+8],edx
    mov [edi+12],edx
;
    xor al,al
    mov ah,bl
    shl ah,5
    or ah,8Fh
    mov [edi+4],ax
;
    pop edi
    pop edx
    pop eax
    pop ds
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InitIdt
;
;   DESCRIPTION:    Init 64-bit IDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pretask_int_tab:
;
;               int #   Entry
;
pg0     DD      0,          pretask0
pg1     DD      1,          pretask1
pg2     DD      2,          pretask2
pg3     DD      3,          pretask3
pg4     DD      4,          pretask4
pg5     DD      5,          pretask5
pg6     DD      6,          pretask6
pg7     DD      7,          pretask7
pg8     DD      8,          pretask8
pg9     DD      9,          pretask9
pg10    DD      10,         pretask10
pg11    DD      11,         pretask11
pg12    DD      12,         pretask12
pg13    DD      13,         pretask13
pg14    DD      14,         pretask14
pg16    DD      16,         pretask16
pg7_end DD      0FFFFFFFFh

InitIdt:
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
;    
    mov ax,flat_sel
    mov es,ax
;
    mov edi,IDT_LINEAR
    mov ecx,400h
    xor eax,eax
    rep stosd
;
    mov edi,pretask_int_tab

iiLoop:
    mov eax,[edi]
    cmp eax,0FFFFFFFFh
    jz iiDone
;    
    mov esi,[edi+4]
    xor bl,bl
    call CreateTrapGate
;
    add edi,8
    jmp iiLoop

iiDone:
    popad
    pop es
    pop ds
    ret
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;    NAME:           Init
;
;    DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init:
    HasLongMode
    jnc init_ok
;
    retf

init_ok:
    mov bx,long_kernel_code_sel
    CreateLongCodeSelector
;    
    mov ecx,UNITY_MAP_SIZE
    mov edi,MAP_LINEAR
    SetupLongMode
;    
    call InitIdt
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,init_task
    HookInitTasking    
;    
    mov esi,boot_end
    mov edi,text_start
    mov ecx,UNITY_MAP_SIZE
    mov bx,cs
    StartLongMode

boot_end:    

text_start:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;    NAME:           Init_task
;
;    DESCRIPTION:    Init tasking
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init_task:
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET test_thread
    mov edi,OFFSET test_thread_name
    mov ax,4
    mov ecx,1000h
    CreateThread
;
    popad
    pop es
    pop ds
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

long_idt_size   DW 0FFFh
long_idt_base   DD IDT_LINEAR

test_thread:
    mov bx,ss
    GetSelectorBaseSize
    add edx,esp
    mov ax,syscall_data_sel
    mov ss,ax
    mov esp,edx    
;    
    mov edx,PAE_CR3_LINEAR
    xor ebx,ebx
    mov eax,cr3
    or al,67h
    SetPageEntry
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
    mov ecx,3FFh
    rep stosd    
;    
    mov edi,cr3
;
    int 3 
    mov edx,0B8000h
    mov eax,0B8007h
    xor ebx,ebx
    SetPageEntry
;    
    cli
    mov eax,cr0
    and eax,7FFFFFFFh
    mov cr0,eax
;
    mov ecx,IA32_EFER
    rdmsr
    or eax,100h
    wrmsr
;
    mov eax,IA64_CR3_LINEAR
    mov cr3,eax  
;
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
;
    lidt fword ptr ds:long_idt_size
    db 0EAh
    dd test64
    dw long_kernel_code_sel

test32:        
    mov eax,cr0
    and eax,7FFFFFFFh
    mov cr0,eax
;
    mov ecx,IA32_EFER
    rdmsr
    and eax,0FFFFFEFFh   
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
;  32-bit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

compat_test:
    retf

code32  Ends    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  64-bit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.x64

Code64 segment byte public use64 'code64'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LocalWriteChar
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

LocalWriteChar  proc near
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
LocalWriteChar  Endp

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
    call LocalWriteChar
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
    call LocalWriteChar
    pop rdx
;    
    inc al
    mov dl,dh
    mov dh,ch
    call LocalWriteChar
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteFault
;
;   DESCRIPTION:    Write fault
;
;   PARAMETERS:     AX      Fault #
;                   DH      Row
;                   DL      Col
;                   R8      Video
;                   R15     Register state
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
ke0F    DB 'Unknown Fault           '
ke10    DB '80387 error             '
ke11    DB 'Cannot emulate          '
ke12    DB 'Cannot emulate 80387    '
ke13    DB 'Now in real mode        '
ke14    DB '----------------------- '
ke15    DB 'Illegal int request     '
ke16    DB 'Undefined method        '
ke17    DB 'Invalid handle          '
ke18    DB 'Invalid selector        '

WriteFault:
    movzx edi,ax
    shl edi,3
    mov eax,edi
    add eax,eax
    add edi,eax
    add edi,error_code_tab
    mov ecx,24
    mov ah,11
    call WriteString
;
    add dl,2
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteErrorCode
;
;   DESCRIPTION:    Write error code
;
;   PARAMETERS:     EAX     Error code
;                   DH      Row
;                   DL      Col
;                   R8      Video
;                   R15     Register state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ft_idt  DB 'Idt '
ft_ldt  DB 'Ldt '
ft_gdt  DB 'Gdt '

WriteErrorCode:
    or eax,eax
    jz wecDone
;    
    test ax,2
    jz wecNotIdt
;    
    mov edi,OFFSET ft_idt
    jmp wecDo

wecNotIdt:
    mov edi,OFFSET ft_gdt
    test ax,4
    jz wecDo
;    
    mov edi,OFFSET ft_ldt

wecDo:
    push rax
    mov ah,11
    mov cx,4
    call WriteString
    pop rax
;    
    and ax,0FFF8h
    mov cl,11
    call WriteHexWord

wecDone:
    inc dh
    xor dl,dl
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           do_fault
;
;   DESCRIPTION:    Write fault info
;
;   PARAMETERS:     RBP     Frame pointer
;                   AX      Vector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fault_ss            equ 48
fault_rsp           equ 40
fault_rflags        equ 32
fault_cs            equ 24
fault_rip           equ 16
fault_error_code    equ 8
fault_rbp           equ 0
fault_rax           equ -8
fault_rbx           equ -16

do_fault:
    push r15
    mov r15,regs
    mov [r15+reg_fault],ax
    mov [r15+reg_rcx],rcx
    mov [r15+reg_rdx],rdx
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
;    
    mov rax,[rbp+fault_rip]
    mov [r15+reg_rip],rax
;    
    mov ax,[rbp+fault_cs]
    mov [r15+reg_cs],ax
;
    mov rax,[rbp+fault_rflags]
    mov [r15+reg_flags],rax
;   
    mov rax,[rbp+fault_rsp]
    mov [r15+reg_rsp],rax
;
    mov ax,[rbp+fault_ss]
    mov [r15+reg_ss],ax
;
    mov rax,[rbp+fault_rax]
    mov [r15+reg_rax],rax
;
    mov rax,[rbp+fault_rbx]
    mov [r15+reg_rbx],rax
;
    mov rax,[rbp+fault_rbp]
    mov [r15+reg_rbp],rax
;     
    mov [r15+reg_ds],ds
    mov [r15+reg_es],es
    mov [r15+reg_fs],fs
    mov [r15+reg_gs],gs
;
    mov r8,0B8000h
    xor rdx,rdx
;
    mov ax,[r15+reg_fault]
    call WriteFault
;
    mov eax,[rbp+fault_error_code]
    call WriteErrorCode    
;    
    mov rdi,OFFSET qword_reg_tab1
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,OFFSET qword_reg_tab2
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,OFFSET qword_reg_tab3
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,OFFSET qword_reg_tab4
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,OFFSET qword_reg_tab5
    mov cl,10
    xor dl,dl
    call WriteQwordReg
    inc dh
    xor dl,dl
;    
    mov rdi,OFFSET qword_reg_tab6
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

trap3_loop:
    jmp trap3_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           trap vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

regs  Reg64 <>

pretask0:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,0
    jmp do_fault

pretask1:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,1
    jmp do_fault

pretask2:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,2
    jmp do_fault

pretask3:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,3
    jmp do_fault

pretask4:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,4
    jmp do_fault

pretask5:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,5
    jmp do_fault

pretask6:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,6
    jmp do_fault

pretask7:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,7
    jmp do_fault

pretask8:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,8
    jmp do_fault

pretask9:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,9
    jmp do_fault

pretask10:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,10
    jmp do_fault

pretask11:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,11
    jmp do_fault

pretask12:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,12
    jmp do_fault

pretask13:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,13
    jmp do_fault

pretask14:
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,14
    jmp do_fault

pretask16:
    pushq0
    push rbp
    mov rbp,rsp
    push rax
    push rbx
    mov ax,9
    jmp do_fault


comp_dest:
    dd compat_test
    dw long_dev_code_sel
    
test64:
    mov rax,12345678h
    db 0FFh
    db 1Ch
    db 25h
    dd comp_dest
    int 3

stopl:
    jmp stopl        


text_end:

Code64  Ends

    end
