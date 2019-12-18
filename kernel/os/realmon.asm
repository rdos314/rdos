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

include \rdos\kernel\os\realtime.def

Code64 segment byte public use64 'code64'

boot:

sgn  dw 657Ah
eip  dq OFFSET init
stt  dq OFFSET mon_stack_top

pad  db 14 DUP(?)

mon_stack       DQ 200h DUP(?)
mon_stack_top   DQ 10h DUP(?)

rtm_gdt:
     dq 0
;
     dw 0FFFFh
     dd 9A000000h
     dw 0AFh
;
     dw 0FFFFh
     dd 92000000h
     dw 0CFh
;
     dq 0

rtm_idt         DQ 2*20h DUP(?)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InitGdt
;
;   DESCRIPTION:    Init GDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gdt_size   DW 17h
gdt_base   DQ 0

InitGdt proc near
    mov rdi,realtime_mon_base
    mov rdx,OFFSET rtm_gdt
    add rdx,rdi
;
    mov rax,OFFSET gdt_size
    add rdi,rax
    mov [rdi+2],rdx
    lgdt [rdi]
    ret
InitGdt Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupIntGate
;
;   DESCRIPTION:    Setup int gate
;
;   PARAMETERS:     RAX     Interrupt #
;                   ESI     Entry point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
SetupIntGate  proc near
    push rax
    push rdx
    push rdi
;
    add rax,rax
    add rax,rax
    add rax,rax
    add rax,rax
    mov rdi,realtime_mon_base
    mov rdx,OFFSET rtm_idt
    add rdi,rdx
    add rdi,rax
;
    mov [rdi],esi
;
    mov dx,[rdi+2]
    mov [rdi+6],dx
;
    mov dx,8
    mov [rdi+2],dx
;
    mov edx,0FFFFFF80h
    mov [rdi+8],edx
;
    mov edx,0
    mov [rdi+12],edx
;
    mov ax,8E00h
    mov [rdi+4],ax
;
    pop rdi
    pop rdx
    pop rax
    ret
SetupIntGate  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupTrapGate
;
;   DESCRIPTION:    Setup trap gate
;
;   PARAMETERS:     RAX      Interrupt #
;                   ESI     Entry point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
SetupTrapGate  proc near
    push rax
    push rdx
    push rdi
;
    add rax,rax
    add rax,rax
    add rax,rax
    add rax,rax
    mov rdi,realtime_mon_base
    mov rdx,OFFSET rtm_idt
    add rdi,rdx
    add rdi,rax
;
    mov [rdi],esi
;
    mov dx,[rdi+2]
    mov [rdi+6],dx
;
    mov dx,8
    mov [rdi+2],dx
;
    mov edx,0FFFFFF80h
    mov [rdi+8],edx
;
    mov edx,0
    mov [rdi+12],edx
;
    mov ax,8F00h
    mov [rdi+4],ax
;
    pop rdi
    pop rdx
    pop rax
    ret
SetupTrapGate  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InitIdt
;
;   DESCRIPTION:    Init IDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

div_0:
trap_1:
trap_3:
invalid_opcode:
protection_fault:
page_fault:
    iretq

idt_size   DW 1FFh
idt_base   DQ 0

InitIdt proc near
    mov rax,OFFSET boot
;
    mov al,0
    mov rsi,OFFSET div_0
    call SetupTrapGate
;
    mov al,1
    mov rsi,OFFSET trap_1
    call SetupTrapGate
;
    mov al,3
    mov rsi,OFFSET trap_3
    call SetupTrapGate
;
    mov al,6
    mov rsi,OFFSET invalid_opcode
    call SetupTrapGate
;
    mov al,13
    mov rsi,OFFSET protection_fault
    call SetupTrapGate
;
    mov al,14
    mov rsi,OFFSET page_fault
    call SetupTrapGate
;
    mov rdx,realtime_mon_base
    mov rax,OFFSET rtm_idt
    add rdx,rax
;
    mov rdi,realtime_mon_base
    mov rax,OFFSET idt_size
    add rdi,rax
    mov [rdi+2],rdx
    lidt [rdi]
;
    ret
InitIdt Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init:
    call InitGdt
    call InitIdt
;
    mov rbx,rsp
    mov rax,OFFSET boot
    mov ax,10h
    push rax
    push rbx
;
    mov rbx,realtime_mon_base
    mov rax,OFFSET start
    add rbx,rax
    mov ax,8
    pushf
    push rax
    push rbx
;
    iretq

start:
    mov ax,10h
    mov ds,ax
    mov es,ax
    sti
    hlt

Code64  Ends

    end
