;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2019, Leif Ekblad
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
; realmon.ASM
; Long mode realtime monitor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.x64

include realtime.def
include system.def

Code64 segment byte public use64 'code64'

boot:

sgn  dw 657Ah
eip  dq OFFSET init

pad  db 6 DUP(?)

rtm_gdt:
gdt0:
     dq 0

gdt8:
     dw 0FFFFh
     dd 9A000000h
     dw 0AFh

gdt10:
     dw 0FFFFh
     dd 92000000h
     dw 0CFh

gdt18:
     dq 0

rtm_idt:
idt0:
    dw OFFSET div_0
    dw 8
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt1:
    dw OFFSET trap_1
    dw 8
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt2:
    dw OFFSET trap_nmi
    dw 8
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt3:
    dw OFFSET trap_3
    dw 8
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt4:
    dq 0,0

idt5:
    dq 0,0

idt6:
    dw OFFSET invalid_opcode
    dw 8
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt7:
    dq 0,0

idt8:
    dq 0,0

idt9:
    dq 0,0

idt0A:
    dq 0,0

idt0B:
    dq 0,0

idt0C:
    dq 0,0

idt0D:
    dw OFFSET protection_fault
    dw 8
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt0E:
    dw OFFSET page_fault
    dw 8
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt0F:
    dq 0,0

idt10:
    dq 0,0

idt11:
    dq 0,0

idt12:
    dq 0,0

idt13:
    dq 0,0

idt14:
    dq 0,0

idt15:
    dq 0,0

idt16:
    dq 0,0

idt17:
    dq 0,0

idt18:
    dq 0,0

idt19:
    dq 0,0

idt1A:
    dq 0,0

idt1B:
    dq 0,0

idt1C:
    dq 0,0

idt1D:
    dq 0,0

idt1E:
    dq 0,0

idt1F:
    dq 0,0

idt20:
    dw OFFSET reset_int
    dw 8
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt21:
    dq 0,0

idt22:
    dq 0,0

idt23:
    dq 0,0

idt24:
    dq 0,0

idt25:
    dq 0,0

idt26:
    dq 0,0

idt27:
    dq 0,0

idt28:
    dq 0,0

idt29:
    dq 0,0

idt2A:
    dq 0,0

idt2B:
    dq 0,0

idt2C:
    dq 0,0

idt2D:
    dq 0,0

idt2E:
    dq 0,0

idt2F:
    dq 0,0

idt30:
    dq 0,0

idt31:
    dq 0,0

idt32:
    dq 0,0

idt33:
    dq 0,0

idt34:
    dq 0,0

idt35:
    dq 0,0

idt36:
    dq 0,0

idt37:
    dq 0,0

idt38:
    dq 0,0

idt39:
    dq 0,0

idt3A:
    dq 0,0

idt3B:
    dq 0,0

idt3C:
    dq 0,0

idt3D:
    dq 0,0

idt3E:
    dq 0,0

idt3F:
    dq 0,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           Interrupt handlers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_int:
    add rsp,40
    int 3

div_0:
trap_1:
trap_nmi:
trap_3:
invalid_opcode:
protection_fault:
page_fault:

    push rax
    push rbx
    mov rbx,realtime_thread_base
;
    pop rax
    mov [rbx].p_rbx,rax
;
    pop rax
    mov [rbx].p_rax,rax
;
    pop rax
    mov [rbx].p_rip,rax
;
    pop rax
    mov [rbx].p_cs,ax
;
    pop rax
    mov [rbx].p_rflags,rax
;
    pop rax
    mov [rbx].p_rsp,rax
;
    pop rax
    mov [rbx].p_ss,ax
;
    mov [rbx].p_rcx,rcx
    mov [rbx].p_rdx,rdx
    mov [rbx].p_rsi,rsi
    mov [rbx].p_rdi,rdi
    mov [rbx].p_rbp,rbp
    mov [rbx].p_r8,r8
    mov [rbx].p_r9,r9
    mov [rbx].p_r10,r10
    mov [rbx].p_r11,r11
    mov [rbx].p_r12,r12
    mov [rbx].p_r13,r13
    mov [rbx].p_r14,r14
    mov [rbx].p_r15,r15
;
    mov [rbx].p_ds,ds
    mov [rbx].p_es,es
    mov [rbx].p_fs,fs
    mov [rbx].p_gs,gs

stl:
    jmp stl

    iretq

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gdt_descr:
gdt_size:
    dw 17h

gdt_base:
    dd OFFSET rtm_gdt
    dd 0FFFFFF80h

idt_descr:
idt_size:
    dw 3FFh

idt_base:
    dd OFFSET rtm_idt
    dd 0FFFFFF80h

init:
    mov rdi,realtime_mon_base
    mov rdx,OFFSET gdt_descr
    add rdi,rdx
    lgdt [rdi]
;
    mov rdi,realtime_mon_base
    mov rdx,OFFSET idt_descr
    add rdi,rdx
    lidt [rdi]
;
    mov ax,10h
    mov ds,ax
    mov es,ax
    int 20h

stop:
    hlt
    jmp stop

Code64  Ends

    end
