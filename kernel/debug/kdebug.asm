;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; KDEBUG.ASM
; Kernel part kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE kdebug.inc

.386p
.387

code    SEGMENT byte use32 public 'CODE'

    extrn init_local_debug:near
    extrn init_ipc_debug:near
    extrn init_crash_driver:near
    extrn init_crash_tasking:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateDataSelector
;
;           DESCRIPTION:    Create 32-bit data selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDataSelector       PROC near
    push ds
    push ax
    push bx
    push ecx
;
    mov ax,gdt_sel
    mov ds,ax
;
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_data32_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [bx+6],cx
    jmp create_data32_done

create_data32_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [bx+6],cx

create_data32_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
CreateDataSelector       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCodeSelector
;
;           DESCRIPTION:    Create 32-bit code selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateCodeSelector       PROC near
    push ds
    push ax
    push bx
    push ecx
;
    mov ax,gdt_sel
    mov ds,ax
;
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_code32_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [bx+6],cx
    jmp create_code32_done

create_code32_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [bx+6],cx

create_code32_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
CreateCodeSelector       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           install_debug
;
;           DESCRIPTION:    install 32-bit debug device
;
;           PARAMETERS:     edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_debug Proc near
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
    mov bp,bx
    call CreateCodeSelector
;
    xor bx,bx
    add edx,ecx
    mov ecx,[esi].dev32_data_size
    or ecx,ecx
    jz install_device32_sel_ok
;
    mov bx,[esi].dev32_data_sel
    call CreateDataSelector

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
    retf

install_device32_end:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
install_debug   Endp

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
    cmp ax,RdosDevice32
    jne install_adapter_next
;       
    push edx
    add edx,SIZE rdos_header
    mov dx,[edx].dev32_code_sel
    cmp dx,kdebug_code_sel
    pop edx
    jne install_adapter_next
;    
    call install_debug

install_adapter_next:
    cmp ax,RdosEnd
    je install_adapter_done
;    
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
;           NAME:           init_test
;
;           DESCRIPTION:    Init test
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_test_name  DB 'Init Test', 0

init_test:
    int 3
    mov ax,system_data_sel
    mov ds,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters

init_device_loop:
    mov edx,[bx].adapter_base
    call install_adapter
    add bx,SIZE adapter_typ
    loop init_device_loop   
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_debug_process
;
;           DESCRIPTION:    Create kernel debugger process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_debug_process      PROC far
    push ds
    push es
    pushad
;    
    call init_local_debug
    call init_ipc_debug
    call init_crash_tasking
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET init_test
    mov edi,OFFSET init_test_name
    mov eax,4
    mov ecx,stack0_size
    CreateThread
;    
    popad
    pop es
    pop ds
    ret
init_debug_process      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    push ebp
    movzx ebp,sp
    mov ax,[ebp+8]
    cmp ax,30h
    je init_boot
;
    int 3
    jmp init_done

init_boot:    
    call init_crash_driver
;    
    mov eax,cs
    mov ds,eax
    mov es,eax  
    mov edi,OFFSET init_debug_process
    HookInitTasking

init_done:
    clc
    pop ebp
    ret
init    Endp
    
code    ENDS

    END init
