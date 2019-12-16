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
    mov rdi,realtime_mon_base
    mov rdx,OFFSET rtm_idt
    add rdi,rdx
    add rdi,rax
;
    mov rdx,realtime_mon_header_size
    add rsi,rdx
;
    mov edx,esi
    mov [rdi],dx
;
    shr edx,16
    mov [rdi+6],dx
;
    mov dx,28h
    mov [rdi+2],dx
;
    mov edx,0FFFFFF80h
    mov [rdi+8],edx
;
    xor edx,edx    
    mov [rdi+12],edx
;
    mov ax,8Eh
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
    mov rdi,realtime_mon_base
    mov rdx,OFFSET rtm_idt
    add rdi,rdx
    add rdi,rax
;
    mov rdx,realtime_mon_header_size
    add rsi,rdx
;
    mov edx,esi
    mov [rdi],dx
;
    shr edx,16
    mov [rdi+6],dx
;
    mov dx,28h
    mov [rdi+2],dx
;
    mov edx,0FFFFFF80h
    mov [rdi+8],edx
;
    xor edx,edx    
    mov [rdi+12],edx
;
    mov ax,8Fh
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

InitIdt proc near
    xor rax,rax
;
    mov eax,0
    mov rsi,OFFSET div_0
    call SetupTrapGate
;
    mov eax,1
    mov rsi,OFFSET trap_1
    call SetupTrapGate
;
    mov eax,3
    mov rsi,OFFSET trap_3
    call SetupTrapGate
;
    mov eax,6
    mov rsi,OFFSET invalid_opcode
    call SetupTrapGate
;
    mov eax,13
    mov rsi,OFFSET protection_fault
    call SetupTrapGate
;
    mov eax,14
    mov rsi,OFFSET page_fault
    call SetupTrapGate
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
    call InitIdt

Code64  Ends

    end
