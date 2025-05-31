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

.x64p

include realmon.def
include ..\realtime.inc
include system.def
include ..\acpi\apic.inc

mon_code_sel     = 8
mon_data_sel     = 10h
mon_ss0_sel      = 18h
app_sys_sel      = 1Bh
app_data_sel     = 23h
app_code_sel     = 2Bh
tr_sel           = 30h

IA32_STAR       = 0C0000081h
IA32_LSTAR      = 0C0000082h
IA32_CSTAR      = 0C0000083h
IA32_FMASK      = 0C0000084h

Code64 segment byte public use64 'code64'

sgn  dw 657Ah
eip  dq OFFSET init
apic dd 0

gdt_descr:
    dw 3Fh
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

gdt20:
     dw 0FFFFh
     dd 0F2000000h
     dw 0CFh

gdt28:
     dw 0FFFFh
     dd 0FA000000h
     dw 0AFh

gdt30:
     dw 111
     dw OFFSET rtm_tr
     dw 8900h
     dw 0
     dd 0FFFFFF80h
     dd 0

rtm_idt:
idt0:
    dw OFFSET div_0
    dw mon_code_sel
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt1:
    dw OFFSET trap_1
    dw mon_code_sel
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt2:
    dw OFFSET trap_nmi
    dw mon_code_sel
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt3:
    dw OFFSET trap_3
    dw mon_code_sel
    dw 0EE00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt4:
    dq 0,0

idt5:
    dq 0,0

idt6:
    dw OFFSET invalid_opcode
    dw mon_code_sel
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
    dw mon_code_sel
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt0E:
    dw OFFSET page_fault
    dw mon_code_sel
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt0F:
    dw OFFSET apic_spur_int
    dw mon_code_sel
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
    dw mon_code_sel
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt21:
    dw OFFSET run_int
    dw mon_code_sel
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt22:
    dw OFFSET msg_int
    dw mon_code_sel
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt23:
    dw OFFSET get_page_int
    dw mon_code_sel
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

idt24:
    dw OFFSET start_int
    dw mon_code_sel
    dw 8E00h
    dw 0
    dd 0FFFFFF80h
    dd 0

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

rtm_tr:
    dd 0

tr_rsp0:
    dq realtime_stack_base + 1000h

tr_rsp1:
    dq 0

tr_rsp2:
    dq 0

    dq 0

tr_ist1:
    dq 0

tr_ist2:
    dq 0

tr_ist3:
    dq 0

tr_ist4:
    dq 0

tr_ist5:
    dq 0

tr_ist6:
    dq 0

tr_ist7:
    dq 0

    dq 0
    dw 0

tr_io_offset:
    dw 104

tr_io_bitmap:
    dq -1

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

get_page_int:
    jmp handle_get_page

start_int:
    jmp handle_start

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
;               NAME:           HandleGetPage
;
;               DESCRIPTION:    Handle get page for linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_get_page:
    push rax
    push rbx
    push rdx
;
    mov rbx,realtime_apic_base
    xor eax,eax
    mov [rbx].APIC_EOI,eax    
;
    sti
    mov rbx,realtime_data_base
    mov rax,[rbx].rds_linear_page
    shr rax,12
    shl rax,3
    mov rbx,realtime_page_table
    add rbx,rax
    mov rdx,[rbx]
    test dl,1
    jnz handle_page_send_back
;
    call AllocatePhys
    or dl,67h
    mov [rbx],rdx

handle_page_send_back:
    mov rbx,realtime_data_base
    mov [rbx].rds_linear_page,rdx
    lock or [rbx].rds_notify_flags,RDS_NOTIFY_FLAG_LINEAR
    call SendInt
;
    pop rdx
    pop rbx
    pop rax
    iretq

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           HandleStart
;
;               DESCRIPTION:    Handle start application
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_start:
    mov rbx,realtime_apic_base
    xor eax,eax
    mov [rbx].APIC_EOI,eax    
;
    sti
    mov ax,tr_sel
    ltr ax
;
    mov eax,OFFSET syscall_start
    mov edx,0FFFFFF80h
    mov ecx,IA32_LSTAR
    wrmsr
;
    mov eax,200h
    xor edx,edx
    mov ecx,IA32_FMASK
    wrmsr
;
    xor eax,eax
    mov edx,mon_code_sel + (app_sys_sel SHL 16)
    mov ecx,IA32_STAR
    wrmsr
;
    mov rbx,realtime_data_base
    mov eax,apic
    mov [rbx].rds_apic,eax
;
    mov ax,app_data_sel
    push rax
;
    mov rax,realtime_app_stack
    shr rax,12
    shl rax,3
    mov rbx,realtime_page_table
    add rbx,rax
;
    call AllocatePhys
    or dl,67h
    mov [rbx],rdx
;
    mov rax,realtime_data_base
    mov rbx,0FFFFFFFFFFFFh
    and rax,rbx
    shr rax,12
    shl rax,3
    mov rbx,realtime_page_table
    mov rdx,[rbx+rax]
    or dl,4
    mov rax,realtime_local_data
    shr rax,12
    shl rax,3
    mov [rbx+rax],rdx
;
    mov rax,realtime_apic_base
    mov rbx,0FFFFFFFFFFFFh
    and rax,rbx
    shr rax,12
    shl rax,3
    mov rbx,realtime_page_table
    mov rdx,[rbx+rax]
    or dl,4
    mov rax,realtime_local_apic
    shr rax,12
    shl rax,3
    mov [rbx+rax],rdx
;
    mov ebx,1000h
    mov rax,realtime_app_stack
    add rax,rbx
    push rax
;
    pushfq
    or word ptr [rsp],3000h
;
    mov ax,app_code_sel
    push rax
;
    mov rbx,realtime_data_base
    mov rbx,[rbx].rds_linear_page
    push rbx
;
    mov ax,app_data_sel
    mov ds,ax
    mov es,ax
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
SendInt Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           AllocatePhys
;
;               DESCRIPTION:    Allocate a physical page
;
;               RETURNS:        RDX     Physical address
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
AllocatePhys    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           syscall handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

syscall_start:
    push rcx
    push r11
;
    mov rcx,rsp
    mov rsp,realtime_stack_base + 1000h
    sti
    push rcx
;
;
    cli
    pop rsp
    pop r11
    pop rcx
    db 48h
    sysret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           startup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

startup:
    mov rbx,realtime_page_pml
    xor rax,rax
    mov [rbx],eax
    mov rax,cr3
    mov cr3,rax
;
    mov rbx,realtime_data_base
    mov [rbx].rds_notify_flags,RDS_NOTIFY_FLAG_BOOTED
    call SendInt

wait_load:
    hlt
    jmp wait_load

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
    mov ax,mon_data_sel
    mov ds,eax
    mov es,eax
    mov ss,eax
    int 20h

stop:
    hlt
    jmp stop

Code64  Ends

    end
