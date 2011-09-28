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
; LOAD32.ASM
; 32-bit device-driver loader
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           install_device32
;
;           DESCRIPTION:    Install 32-bit device
;
;           PARAMETERS:     DS:EDX      Data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_device32    Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;       
    mov ecx,[edx].len
    sub ecx,SIZE rdos_header
    add edx,SIZE rdos_header
    mov esi,edx
    mov ebx,[esi].dev32_size
    mov edi,esi
    add edi,SIZE device32_header

install_device32_param_loop:
    mov al,[edi]
    inc edi
    or al,al
    jnz install_device32_param_loop
;       
    mov ecx,[esi].dev32_code_size
    add edx,ebx
    mov bx,[esi].dev32_code_sel
    or bx,bx
    jnz install_device32_cr_code
;
    mov bx,device_code_sel

install_device32_cr_code:
    mov bp,bx
    CreateCodeSelector32
;
    xor bx,bx
    add edx,ecx
    mov ecx,[esi].dev32_data_size
    or ecx,ecx
    jz install_device32_sel_ok
;
    mov bx,[esi].dev32_data_sel
    CreateDataSelector32

install_device32_sel_ok:
    mov ax,ds
    mov es,ax
    mov eax,[esi].dev32_init_ip
    mov ds,bx
    mov ebx,cs
    push ebx
    mov ebx,OFFSET install_device32_end
    push ebx
    push ebp
    push eax
    retf32

install_device32_end:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
install_device32    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           install_adapter
;
;           DESCRIPTION:    install devices in adapter
;
;           PARAMETERS:     edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_adapter Proc near
    push ds
    push ax
    push bx
    push edx
    mov ax,flat_sel
    mov ds,ax

install_adapter_loop:
    mov ax,[edx].typ
    cmp ax,RdosEnd
    je install_adapter_done
;    
    cmp ax,RdosDevice32
    jne install_adapter_next
;       
    call install_device32

install_adapter_next:
    add edx,[edx].len
    jmp install_adapter_loop

install_adapter_done:
    pop edx
    pop bx
    pop ax
    pop ds
    ret
install_adapter Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           load_device32
;
;           DESCRIPTION:    load device32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_device32_name       DB 'Load Device32',0
    
load_device32   Proc far
    push ds
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters
    
init_device_loop:
    mov edx,[bx].adapter_base
    call install_adapter
    add bx,SIZE adapter_typ
    loop init_device_loop   
;
    popad
    pop ds        
    retf32
load_device32   Endp

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
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET load_device32
    mov edi,OFFSET load_device32_name
    xor dx,dx
    mov ax,load_device32_nr
    RegisterBimodalUserGate
    ret
init    ENDP

code    ENDS

    END init
