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
include ..\pcdev\apic.inc

Code64 segment byte public use64 'code64'

sgn  dw 657Ah
eip  dq OFFSET init
apic dd 0

gdt_descr:
    dw 1Fh
    dd OFFSET rtm_gdt
    dd 0FFFFFF80h

idt_descr:
    dw 3FFh
    dd OFFSET rtm_idt
    dd 0FFFFFF80h

pad  db 14 DUP(?)

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
     dw 0FFFFh
     dd 92000000h
     dw 0CFh

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
    dw OFFSET apic_spur_int
    dw 8
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

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
    dw OFFSET run_int
    dw 8
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt22:
    dw OFFSET msg_int
    dw 8
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

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
    sti
    add rsp,40
    jmp startup

run_int:
    jmp load_and_restart

msg_int:
    jmp handle_msg

div_0:
    push 0
    push rax
    push rbx
    mov rbx,realtime_thread_base
    mov [rbx].p_fault_vector,0
    jmp save_and_wait
    
trap_1:
    push 0
    push rax
    push rbx
    mov rbx,realtime_thread_base
    mov [rbx].p_fault_vector,1
    jmp save_and_wait

trap_nmi:
    push 0
    push rax
    push rbx
    mov rbx,realtime_thread_base
    mov [rbx].p_fault_vector,2
    jmp save_and_wait

trap_3:
    push 0
    push rax
    push rbx
    mov rbx,realtime_thread_base
    mov [rbx].p_fault_vector,3
    jmp save_and_wait

invalid_opcode:
    push 0
    push rax
    push rbx
    mov rbx,realtime_thread_base
    mov [rbx].p_fault_vector,6
    jmp save_and_wait

protection_fault:
    push rax
    push rbx
    mov rbx,realtime_thread_base
    mov [rbx].p_fault_vector,0Dh
    jmp save_and_wait

page_fault:
    push rax
    push rbx
    mov rbx,realtime_thread_base
    mov [rbx].p_fault_vector,0Eh
    mov rbx,[rsp+10h]
    test bl,1
    jz handle_page_fault
    jmp save_and_wait

apic_spur_int:
    iretq

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           Save state and wait for interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

save_and_wait:
    mov rbx,realtime_thread_base
    pop rax
    mov [rbx].p_rbx,rax
;
    pop rax
    mov [rbx].p_rax,rax
;
    pop rax
    mov [rbx].p_fault_code,rax
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
;
    mov rbx,realtime_data_base
    lock or [rbx].rds_notify_flags,RDS_NOTIFY_FLAG_DEBUG
    call SendInt

waitl:
    sti
    hlt
    jmp waitl

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           Load and restart
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_and_restart:
    mov rbx,realtime_apic_base
    xor eax,eax
    mov [rbx].APIC_EOI,eax    
;
    mov rbx,realtime_thread_base
    mov ax,[rbx].p_ss
    push rax
;
    mov rax,[rbx].p_rsp
    push rax
;
    mov rax,[rbx].p_rflags
    push rax
;
    mov ax,[rbx].p_cs
    push rax
;
    mov rax,[rbx].p_rip
    push rax
;
    mov rcx,[rbx].p_rcx
    mov rdx,[rbx].p_rdx
    mov rsi,[rbx].p_rsi
    mov rdi,[rbx].p_rdi
    mov rbp,[rbx].p_rbp
    mov r8,[rbx].p_r8
    mov r9,[rbx].p_r9
    mov r10,[rbx].p_r10
    mov r11,[rbx].p_r11
    mov r12,[rbx].p_r12
    mov r13,[rbx].p_r13
    mov r14,[rbx].p_r14
    mov r15,[rbx].p_r15
;
    mov ds,[rbx].p_ds
    mov es,[rbx].p_es
    mov fs,[rbx].p_fs
    mov gs,[rbx].p_gs
;
    mov rax,[rbx].p_dr0
    mov dr0,rax
;
    mov rax,[rbx].p_dr1
    mov dr1,rax
;
    mov rax,[rbx].p_dr2
    mov dr2,rax
;
    mov rax,[rbx].p_dr3
    mov dr3,rax
;
    mov rax,[rbx].p_dr7
    mov dr7,rax
;
    mov rax,[rbx].p_rax
    mov rbx,[rbx].p_rbx
    iretq

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           Handle page fault
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_page_fault:
    mov rbx,cr2
    sti
    mov rax,rbx
    shr rax,32
;
    sub eax,realtime_page_table SHR 32
    jc save_and_wait
;
    cmp eax,80h
    jnc save_and_wait   

handle_page_fault_ok:
    mov rax,0FFFFFFFFFFFFh
    and rbx,rax
    shr rbx,12
    shl rbx,3
    mov rax,realtime_page_table
    add rbx,rax
    mov rax,[rbx]
    test al,1
    jnz handle_page_retry
;
    push rcx
    push rdx
    push rdi
;
    call AllocatePhys
    or dl,67h
    mov [rbx],rdx
;
    mov rax,realtime_page_table
    sub rbx,rax
    shl rbx,9
    mov rax,800000000000h
    test rax,rbx
    jz handle_page_zero
;
    mov rax,0FFFF000000000000h
    or rbx,rax    

handle_page_zero:
    mov rdi,rbx
    mov rcx,200h
    xor rax,rax
    rep stosq
;
    pop rdi
    pop rdx
    pop rcx

handle_page_retry:
    pop rbx
    pop rax
    add rsp,8
    iretq

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           HandleMsg
;
;               DESCRIPTION:    Handle msg int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_msg:
    push rax
    push rbx
;
    mov rbx,realtime_apic_base
    xor eax,eax
    mov [rbx].APIC_EOI,eax    
;
    pop rbx
    pop rax
    iretq

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SetupLocalApic
;
;               DESCRIPTION:    Setup local APIC
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupLocalApic    Proc near
    mov rbx,realtime_apic_base
;
    mov eax,10000h
    mov [rbx].APIC_LINT0,eax
;
    mov eax,10000h
    mov [rbx].APIC_LINT1,eax 
;   
    mov eax,10000h
    mov [rbx].APIC_LERROR,eax
;
    mov eax,10000h
    mov [rbx].APIC_THERMAL,eax
;
    mov eax,10000h
    mov [rbx].APIC_PERF,eax
;
    mov eax,10000h
    mov [rbx].APIC_TIMER,eax
;
    mov eax,[rbx].APIC_SPUR
    and eax,NOT 1000h
    or eax,100h
    mov al,0Fh
    mov [rbx].APIC_SPUR,eax    
;
    mov eax,0Bh
    mov [rbx].APIC_DIV_CONFIG,eax
;
    mov eax,-1
    mov [rbx].APIC_DEST_FORMAT,eax
;
    mov eax,10000000h    
    mov [rbx].APIC_LOG_DEST,eax
;
    xor eax,eax
    mov [rbx].APIC_TPR,eax
    ret
SetupLocalApic    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SendInt
;
;               DESCRIPTION:    Send int 85h
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInt    Proc near
    push rax
    push rbx
    push rcx
    push rdx
;
    mov edx,apic
    shl edx,24
;
    mov rbx,realtime_apic_base

siLoop:
    mov ecx,[rbx].APIC_ICR
    test cx,1000h
    jz siDo
;
    pause
    jmp siLoop

siDo:    
    mov [rbx].APIC_ICR+10h,edx
;
    mov eax,4085h
    mov [rbx].APIC_ICR,eax
;
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
SendInt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           AllocatePhys
;
;               DESCRIPTION:    Allocate a physical page
;
;               RETURNS:        RDX	Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocatePhys    Proc near
    push rbx
;
    mov rbx,realtime_data_base
    mov [rbx].rds_phys_page,0
    lock or [rbx].rds_notify_flags,RDS_NOTIFY_FLAG_PHYS
    call SendInt

apWait:
    hlt
;
    xor rdx,rdx
    xchg rdx,[rbx].rds_phys_page
    or rdx,rdx
    jz apWait
;
    pop rbx
    ret
AllocatePhys	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           startup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


startup:
    int 3
    mov rbx,realtime_heap_base
    shr rbx,12
    shl rbx,3
    mov rax,realtime_page_table
    add rbx,rax
    mov rax,[rbx]
;
    mov rbx,realtime_data_base
    mov [rbx].rds_notify_flags,RDS_NOTIFY_FLAG_BOOTED
    call SendInt

wait_load:
    hlt
;
    mov edx,[rdx].rds_req_flags
    or edx,edx
    jz wait_load
;
    test edx,RDS_REQ_FLAG_START
    jnz loadit
;
    int 3

loadit:
    int 3
    mov rax,1235h
    int 3
    mov rax,3


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    call SetupLocalApic
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
