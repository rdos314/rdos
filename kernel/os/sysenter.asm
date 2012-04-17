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
INCLUDE exec.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE gate.def

STUB_LINEAR     = 80000h
STUB_PAGES      = 4

.386p

data    SEGMENT byte public 'DATA'

stub_start      DD ?

process_page_arr    DD STUB_PAGES DUP (?)

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

app_gate_ind    DD ?

app_stub Proc near
    push eax
    push ecx
    push edx
    db 0Fh
    db 34h
    pop edx
    pop ecx
    pop eax
    ret
app_stub Endp

app_stub_end:

CreateAppStub   Proc near
    push ds
    push es
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
    mov esi,OFFSET app_gate_ind + 4
    stosd
    mov ecx,OFFSET app_stub_end - OFFSET app_stub_start - 4
    rep movs byte ptr es:[edi],cs:[esi]
    mov ds:stub_start,edi
;
    add edx,OFFSET app_stub - OFFSET app_stub_start    
;
    pop edi
    pop esi
    pop ecx    
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
;    
    mov edx,es:[edi].user_gate_syscall_index
    cmp edx,-1
    jne patch_stub_ok
;
    mov eax,edi
    call CreateAppStub
    mov es:[edi].user_gate_syscall_index,edx

patch_stub_ok:
    mov ax,flat_sel
    mov ds,ax
    sub edx,ebx
    sub edx,6
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
;
    pop edx
    pop ds
    ret
syscall_patch   Endp

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
    call CreateAppStub
    int 3
    push syscall_code_sel
    push STUB_LINEAR
    retf

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
    mov ax,process_page_sel
    mov es,ax
    mov ecx,STUB_PAGES
    mov edx,STUB_LINEAR SHR 10
    mov edi,OFFSET process_page_arr

setup_page_loop:
    mov eax,ds:[edi]
    mov es:[edx],eax
    add edx,4
    add edi,4
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
    mov ax,SEG data
    mov ds,ax
    mov ds:stub_start,STUB_LINEAR
;
    mov ax,process_page_sel
    mov es,ax
    mov ecx,STUB_PAGES
    mov edx,STUB_LINEAR SHR 10
    mov edi,OFFSET process_page_arr

alloc_page_loop:
    AllocatePhysical
    or al,5
    mov es:[edx],eax
    mov ds:[edi],eax
    add edx,4
    add edi,4
    loop alloc_page_loop        
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
        

init_done:    
    ret
init    ENDP

code    ENDS

    END init
