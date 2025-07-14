;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; SYSENTER.ASM
; Sysenter device-driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE int.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE gate.def
INCLUDE core.inc

STUB_LINEAR     = 80000h
STUB_PAGES      = 4

MSR_SYSENTER_CS  = 174h
MSR_SYSENTER_ESP = 175h
MSR_SYSENTER_EIP = 176h

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

data    SEGMENT byte public 'DATA'

stub_start          DD ?

process_page_arr    DD STUB_PAGES DUP (?,?)

gate_index_arr      DD usergate_entries DUP (?)

data    ENDS

code    SEGMENT byte public 'CODE'
    
    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateAppStub
;
;       DESCRIPTION:    Create a new app stub
;
;       PARAMETERS:     EAX     Gate number
;
;       RETURN VALUE:   EDX     Linear address of stub (in user-space)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

app_stub_start:

app_stub Proc near
    push ecx
    push edx
;
    mov ecx,esp

ap1:    
    mov edx,0           ; patched to gate #
;        
    db 0Fh
    db 34h

app_leave:
    pop edx
    pop ecx
    ret
app_stub Endp

app_stub_end:

CreateAppStub   Proc near
    push ds
    push es
    push ebx
    push ecx
    push esi
    push edi
;
    mov dx,SEG data
    mov ds,dx
    mov dx,flat_sel
    mov es,dx
    mov edi,ds:stub_start
    mov edx,edi
    mov esi,OFFSET app_stub_start    
    mov ecx,OFFSET app_stub_end - OFFSET app_stub_start
    rep movs byte ptr es:[edi],cs:[esi]
    mov ds:stub_start,edi
;
    mov edi,OFFSET ap1 - OFFSET app_stub_start + 1
    add edi,edx
    mov es:[edi],eax
;
    add edx,OFFSET app_leave - OFFSET app_stub_start    
;
    pop edi
    pop esi
    pop ecx    
    pop ebx
    pop es
    pop ds
    ret
CreateAppStub   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           syscall_patch
;
;       DESCRIPTION:    Patch callback
;
;       PARAMETERS:     EBX     Patch linear address
;                       ES:EDI  Gate entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

syscall_patch_name  DB 'Syscall Patch', 0

syscall_patch   Proc far
    push ds
    push edx
    push edi
;    
    mov edx,es:[edi].user_gate_near_ret
    cmp edx,-1
    stc
    je patch_done
;    
    mov ax,SEG data
    mov ds,ax
    mov eax,edi
;    
    shr edi,USER_GATE_SHIFT
    shl edi,2
    mov edx,ds:[edi].gate_index_arr
    cmp edx,-1
    jne patch_stub_ok
;
    shr eax,USER_GATE_SHIFT
    call CreateAppStub
    mov ds:[edi].gate_index_arr,edx

patch_stub_ok:
    mov ax,flat_sel
    mov ds,ax
    sub edx,ebx
    sub edx,6
    sub edx,OFFSET app_leave - OFFSET app_stub
    xchg edx,ds:[ebx+2]
;
    mov ax,9090h
    xchg ax,ds:[ebx+6]
;
    mov al,0E8h
    xchg al,ds:[ebx+1]
;    
    mov al,90h
    xchg al,ds:[ebx]
    clc

patch_done:
    pop edi
    pop edx
    pop ds
    ret
syscall_patch   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           start_syscall
;
;       DESCRIPTION:    Start syscall. Called once per core
;
;       PARAMETERS:     FS      Processor core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_syscall_name  DB 'Start Syscall', 0

app_leave_rel = OFFSET app_leave - OFFSET app_stub_start

syscall_start:

syscall_entry   Proc far
    sti
;    
    push ecx
    cmp edx,usergate_entries
    jae syscall_fail

sp2:
    mov ecx,cs:[4*edx-1]  ; patched to contain address of gate table    
    push ecx
;
    shl edx,USER_GATE_SHIFT

sp3:    
    add edx,1234h           ; patched to contain base of user-gate selector
    push cs:[edx].user_gate_near_ret
    push dword ptr cs:[edx].user_gate_entry_sel32
    push cs:[edx].user_gate_near_call
;
;    mov edx,usergate_sel
;    mov gs,edx
;    
    mov ecx,ss:[esp+16]
    mov edx,ds:[ecx].syscall_edx
    mov ecx,ds:[ecx].syscall_ecx
;
    ret
syscall_entry   Endp

syscall_fail:
    int 3

syscall_end:


start_syscall   Proc far
    push ds
    push es
    pushad
;    
    mov edx,fs:cs_syscall_eip
    or edx,edx
    jnz start_syscall_load_msr
;    
    mov bx,usergate_sel
    GetSelectorBaseSize
    push edx
;    
    mov bx,SEG data
    GetSelectorBaseSize
    push edx
;        
    mov ax,flat_sel
    mov es,ax
    mov eax,OFFSET syscall_end - OFFSET syscall_start
    AllocateBigLinear
    mov edi,edx
    mov esi,OFFSET syscall_start
    mov ecx,eax
    rep movs byte ptr es:[edi],cs:[esi]
;
    pop eax
    add eax,OFFSET gate_index_arr
    mov edi,OFFSET sp2 - OFFSET syscall_start + 4
    mov es:[edx+edi],eax
;    
    pop eax
    mov edi,OFFSET sp3 - OFFSET syscall_start + 2
    mov es:[edx+edi],eax
;
    add edx,OFFSET syscall_entry - OFFSET syscall_start
    mov fs:cs_syscall_eip,edx

start_syscall_load_msr:    
    mov eax,edx
    xor edx,edx
    mov ecx,MSR_SYSENTER_EIP
    wrmsr
;
    mov eax,syscall_code_sel
    mov ecx,MSR_SYSENTER_CS
    wrmsr
;
    popad
    pop es 
    pop ds   
    ret
start_syscall   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           test_thread
;
;           DESCRIPTION:    Test thread
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_thread_name  DB 'Sysenter thread', 0

test_thread:
    int 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_process
;
;           DESCRIPTION:    Init process
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process    PROC far
    mov ax,SEG data
    mov ds,ax
    mov ecx,STUB_PAGES
    mov edx,STUB_LINEAR
    mov esi,OFFSET process_page_arr

setup_page_loop:
    mov eax,ds:[esi]
    mov ebx,ds:[esi+4]
    SetPageEntry
;    
    add edx,1000h
    add esi,8
    loop setup_page_loop        
    ret
init_process    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_module
;
;           DESCRIPTION:    Init module
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_module    PROC far
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
    mov ecx,stack0_size
    CreateThread
;
    popad
    pop es
    pop ds
    ret
init_module    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    init module
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov bx,system_data_sel
    mov ds,bx
    mov edx,ds:flat_base
    or edx,edx
    jnz init_done
;    
    mov eax,ds:cpu_feature_flags
    test ax,800h
    jz init_done
;
    mov ax,SEG data
    mov ds,ax
    mov ds:stub_start,STUB_LINEAR
;
    mov ecx,STUB_PAGES
    mov edx,STUB_LINEAR
    mov edi,OFFSET process_page_arr

alloc_page_loop:
    AllocatePhysical64
    or al,5
;    
    mov ds:[edi],eax
    mov ds:[edi+4],ebx
    SetPageEntry
;
    add edx,1000h
    add edi,8
    loop alloc_page_loop        
;
    mov ecx,usergate_entries
    mov edi,OFFSET gate_index_arr
    mov eax,-1

init_index_loop:
    mov ds:[edi],eax
    add edi,4
    loop init_index_loop  
;         
    mov ax,flat_sel
    mov es,ax
    mov edi,STUB_LINEAR    
    mov eax,90909090h
    mov ecx,STUB_PAGES SHL 10
    rep stosd
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_module
    HookInitTasking
;
    mov edi,OFFSET init_process
    HookCreateProcess    
;
    mov esi,OFFSET syscall_patch
    mov edi,OFFSET syscall_patch_name
    xor cl,cl
    mov ax,syscall_patch_nr
    RegisterOsGate
;
    mov esi,OFFSET start_syscall
    mov edi,OFFSET start_syscall_name
    xor cl,cl
    mov ax,start_syscall_nr
    RegisterOsGate
;    
    GetCore
    StartSyscall
        
init_done:    
    ret
init    ENDP

code    ENDS

    END init
