;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2015, Leif Ekblad
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
; BIOS.ASM
; Emulated UEFI BIOS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.686p

IA32_EFER       = 0C0000080h


IDT_BASE    EQU 10000h
CR3_BASE    EQU 11000h
PML4_BASE   EQU 12000h
PTR_BASE    EQU 13000h
DIR_BASE    EQU 14000h
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;   32-bit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Code32 segment byte public use32 'code32'

gdt0:
    dw 0
    dd 0
    dw 0
gdt8:
    dw 0FFFFh
    dd 9A000000h
    dw 0CFh
gdt10:
    dw 0FFFFh
    dd 92000000h
    dw 0CFh
gdt18:
    dw 0FFFFh
    dd 9A000000h
    dw 0EFh

Init32:
    mov ax,10h
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov esp,IDT_BASE - 10h
;
    mov edi,CR3_BASE    
    mov eax,PML4_BASE + 67h
    stosd
    xor eax,eax
    mov ecx,3FFh
    rep stosd
;
    mov edi,PML4_BASE
    mov eax,PTR_BASE + 67h
    stosd
    xor eax,eax
    mov ecx,3FFh
    rep stosd
;
    mov edi,PTR_BASE
    mov edx,DIR_BASE
    mov ecx,400h

init_page_ptr_loop:    
    mov eax,edx
    or al,67h
    stosd
    xor eax,eax
    stosd
    add edx,1000h
    sub ecx,2
    cmp edx,0A0000h
    jne init_page_ptr_loop    
;
    rep stosd
;
    mov edi,DIR_BASE
    xor edx,edx

init_page_dir_loop:    
    mov eax,edx
    or al,67h
    stosd
    xor eax,eax
    stosd
    add edx,1000h
    cmp edi,0A0000h
    jne init_page_dir_loop
;
    int 3
    mov eax,CR3_BASE
    mov cr3,eax
;
    mov eax,cr4
    or al,20h
    mov cr4,eax
;
    mov ecx,IA32_EFER
    rdmsr
    or eax,101h
    wrmsr
;
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
;
    db 0EAh
    dd OFFSET Init64
    dw 18h
    
    
option PROCALIGN:32 

code32_end  Proc near
code32_end  Endp

Code32  Ends    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  64-bit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.x64

Code64 segment byte public use64 'code64'

org OFFSET code32_end    
option PROCALIGN:1

Init64:
    push r15
    
option PROCALIGN:32

code64_end  Proc near
code64_end  Endp

Code64  Ends    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  16-bit bootstrap code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386p

Code16 segment byte public use16 'code16'

org OFFSET code64_end
option PROCALIGN:1

gdt:
    dw 1Fh
    dd OFFSET gdt0

Start:
    mov ax,cs
    mov ds,ax
    xor ax,ax
    mov es,ax
    xor si,si
    xor di,di
    mov cx,8000h
    rep movsw
;
    mov bx,OFFSET gdt
    lgdt fword ptr cs:[bx]
;
    mov eax,cr0
    or al,1
    mov cr0,eax
;
    db 0EAh
    dw OFFSET Init32
    dw 8
    
option PROCALIGN:32

Boot    Proc near
Boot    Endp

filler db 0FEB0h dup (0FFh)

init:
    db 0EAh
    dw OFFSET start
    dw 0F000h    

    db 0FFh
    dw 0FFFFh
    dw 4 DUP(0FFFFh)

Code16  Ends    

    end
