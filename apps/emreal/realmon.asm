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
    jmp init

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InitGdt
;
;   DESCRIPTION:    Init GDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gdt_size   DW 17h
gdt_base   DQ realtime_mon_base + rtm_gdt

InitGdt proc near
    mov rdi,realtime_mon_base
    mov rdx,OFFSET rtm_gdt
    add rdi,rdx
;
    mov rax,OFFSET boot
    mov [rdi],rax
;
    add edi,8
    mov ax,0FFFFh
    mov [rdi],ax
    mov eax,9A000000h
    mov [rdi+2],eax
    mov ax,0AFh
    mov [rdi+6],ax
;
    add edi,8
    mov ax,0FFFFh
    mov [rdi],ax
    mov eax,92000000h
    mov [rdi+2],eax
    mov ax,0
    mov [rdi+6],ax
;
    mov rdi,realtime_mon_base
    mov rax,OFFSET gdt_size
    add rdi,rax
    mov rax,realtime_mon_header_size
    add rdi,rax
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
    mov rdx,realtime_mon_header_size
    add rsi,rdx
;
    mov [rdi],esi
;
    mov dx,[rdi+2]
    mov [rdi+6],dx
;
    mov dx,28h
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
    mov rdx,realtime_mon_header_size
    add rsi,rdx
;
    mov [rdi],esi
;
    mov dx,[rdi+2]
    mov [rdi+6],dx
;
    mov dx,28h
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
    iret

idt_size   DW 1FFh
idt_base   DQ realtime_mon_base + rtm_idt

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
    mov rdi,realtime_mon_base
    mov rax,OFFSET idt_size
    add rdi,rax
    mov rax,realtime_mon_header_size
    add rdi,rax
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
    mov rax,realtime_mon_base
    mov rbx,OFFSET rtm_stack
    add rax,rbx
    mov rsp,[rax]
    call InitGdt
    call InitIdt

Code64  Ends

    end
