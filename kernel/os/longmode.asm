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
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;   32-bit device driver header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   bits 32

   org 0xFFFFFFEE

hdr         dw 0x3252
cip         dd init
code_size   dd text_end
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
    jmp unity

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Unity mapped code at 3000h
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

times 0x3012 - ($ - $$) db 0

unity:
    OsGate prepare_long_mode
    int 3 
;
    mov edx,2000h
    xor ebx,ebx
    mov eax,cr3
    or al,67h
    OsGate set_page_entry
;    
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;
    mov esi,2000h
    mov edi,11000h
    mov ecx,400h
    rep movsd
;
    mov edi,11000h
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
    mov edi,12000h
    mov eax,11007h
    stosd
    xor eax,eax
    mov ecx,1023
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
    mov eax,12000h
    mov cr3,eax  
;
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax

    jmp long_kernel_code_sel:test64

test32:        
    mov eax,2000h
    mov ebx,[eax]
    mov ebp,[eax+8]
;    
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

test64:
    mov rbx,0xB8000
    mov eax,0x7310731
    mov [rbx],eax

stopl:
    jmp stopl        

text_end:
