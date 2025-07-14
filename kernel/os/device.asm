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
; DEVICE.ASM
; Device driver handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
    
code    SEGMENT byte public 'CODE'

.386

    extrn get_sys_page_entry_proc:word
    extrn set_sys_page_entry_proc:word

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           move_kernel_code
;
;           DESCRIPTION:    Move kernel code descriptor high
;
;           PARAMETERS:         EDX         NEW BASE ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_kernel_code    Proc near
    push bx
    push edx
    mov bx,cs
    mov es:[bx+2],edx
    mov byte ptr es:[bx+5],9Ah
    shr edx,16
    xor dl,dl
    mov es:[bx+6],dx
    db 0EAh
    dw OFFSET move_kernel_done
    dw kernel_code
move_kernel_done:
    pop edx
    pop bx
    ret
move_kernel_code    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           move_adapters
;
;           DESCRIPTION:    Move adapters to private address space
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public move_adapters

move_adapters   PROC near
    push ds
    push es
    push fs
    pushad
;
    mov ax,gdt_sel
    mov es,ax
    mov ax,system_data_sel
    mov fs,ax
;
    mov bx,cs
    mov eax,es:[bx+2]
    rol eax,8
    mov al,es:[bx+7]
    ror eax,8
    mov esi,eax
;
    mov cx,fs:rom_modules
    mov bx,OFFSET rom_adapters
move_adapter_loop:
    push cx
    push esi
    push edi
;
    cmp fs:rom_shadow,0
    je move_adapter_shadow_ok
;
    push es
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;
    mov edx,kernel_linear
    mov edi,edx
    mov esi,fs:[bx].adapter_base
    mov ecx,fs:[bx].adapter_size
    dec ecx
    shr ecx,2
    inc ecx
    rep movs dword ptr es:[edi],ds:[esi]
;
    pop es
    jmp move_page_done

move_adapter_shadow_ok:
    mov ecx,fs:[bx].adapter_size
    mov esi,fs:[bx].adapter_base
    mov eax,esi
    and si,0F000h
    sub eax,esi
    add ecx,eax
    mov edi,esi
;
    sub edi,fs:rom1_base
    jc move_adapter_try2
;
    cmp edi,fs:rom1_size
    jc move_adapter_bias

move_adapter_try2:
    add edi,fs:rom1_base
    sub edi,fs:rom2_base

move_adapter_bias:
    add edi,kernel_linear
    mov edx,edi
    and di,0F000h
    and si,0F000h
    dec ecx
    add ecx,1000h
    shr ecx,12
;
    push ebx
    push edx

move_page_loop:
    mov edx,esi
    call cs:get_sys_page_entry_proc
;    
    mov al,7
    mov edx,edi
    call cs:set_sys_page_entry_proc
;
    add esi,1000h
    add edi,1000h
    loop move_page_loop
;
	pop edx
	pop ebx

move_page_done:
    pop edi
    pop esi
    mov eax,esi
    sub eax,fs:[bx].adapter_base
    jc move_not_current_adapter
    cmp eax,fs:[bx].adapter_size
    jnc move_not_current_adapter
;
    push edx
    add edx,eax
    call move_kernel_code
    pop edx

move_not_current_adapter:
    mov fs:[bx].adapter_base,edx
    add bx,SIZE adapter_typ
    pop cx
    sub cx,1
    jnz move_adapter_loop   
;
    popad
    pop fs
    pop es
    pop ds
    ret
move_adapters   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           setup_long_mode
;
;       DESCRIPTION:    Setup long mode memory layout
;
;       PARAMETERS:     ECX     map size
;                       EDI     map position for unity section
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_mode Proc near
    push ebx
    push ecx
    push edx
;
    dec ecx
    and cx,0F000h
    shr ecx,12
    inc cx
;
    mov eax,edi
    xor ebx,ebx
    mov edx,eax
    or ax,803h

slPageLoop:
    SetSysPageEntry
    add edx,1000h
    add eax,1000h
    loop slPageLoop
;
    pop edx
    pop ecx
    pop ebx
    ret
setup_long_mode Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           setup_long_idt
;
;       DESCRIPTION:    Setup long mode IDT
;
;       PARAMETERS:     EDI     map position
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_idt Proc near
    push ds
    push es
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax
    mov ds:long_idt_ads,edi
;    
    mov ax,flat_sel
    mov es,ax
;
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;    
    popad
    pop es
    pop ds
    ret
setup_long_idt  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           install_long_mode
;
;           DESCRIPTION:    install long mode
;
;           PARAMETERS:     DS:EDX  device header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_long_mode   PROC near
    push ds
    push es
    pushad
;    
    mov ecx,[edx].len
    sub ecx,SIZE rdos_header
    add edx,SIZE rdos_header
    push ecx
    push edx
;
    mov bx,long_kernel_code_sel
    CreateLongCodeSelector
;
    mov bx,long_user_code_sel
    CreateLongCodeSelector
;
    push ecx
    push edx
    xor ecx,ecx
    xor edx,edx    
    mov bx,long_kernel_data_sel
    CreateDataSelector32
;
    mov bx,long_user_data_sel
    CreateDataSelector32
    pop edx
    pop ecx
;
    mov edi,[edx].lm_image_base
    mov ecx,[edx].lm_image_size    
    call setup_long_mode
;    
    mov edi,[edx].lm_idt_base
    call setup_long_idt
;
    mov edi,[edx].lm_image_base
    mov ebp,[edx].lm_init_ip
;    
    pop edx
    pop ecx
    sub ecx,[edx].lm_size
;
    mov ax,flat_sel
    mov es,ax
;    
    mov esi,edx
    add esi,[edx].lm_size
;
    push ecx    
    rep movs es:[edi],ds:[esi]
    pop ecx
;
    mov ecx,edi
    xor edx,edx
    mov bx,long_dev_code_sel
    CreateCodeSelector32
;
    mov eax,cs
    push eax
;    
    mov eax,OFFSET inst_long_ret
    push eax
;    
    push ebx
    push ebp
    retf32

inst_long_ret:    
    popad
    pop es
    pop ds
    ret
install_long_mode   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           install_simple_device
;
;           DESCRIPTION:    install simple device
;
;           PARAMETERS:         DS:EDX  device header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_simple_device   PROC near
    push ds
    push es
    pushad
    mov ecx,[edx].len
    sub ecx,SIZE rdos_header
    add edx,SIZE rdos_header
    mov ax,[edx].init_ip
    sub ecx,SIZE simple_device_header
    add edx,SIZE simple_device_header
    mov bx,device_code_sel
    CreateCodeSelector16
;
    push cs
    push OFFSET install_simple_device_end
    push bx
    push ax
    retf
install_simple_device_end:
    popad
    pop es
    pop ds
    ret
install_simple_device   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           install_dos_device
;
;           DESCRIPTION:    install dos device
;
;           PARAMETERS:         DS:EDX  device header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_dos_device      PROC near
    push ds
    push es
    pushad
    mov ecx,[edx].len
    sub ecx,SIZE rdos_header
    add edx,SIZE rdos_header
    mov ax,[edx].dos_dev_init_ip
    movzx ebx,[edx].dos_dev_size
    sub ecx,ebx
    add edx,ebx
    mov bx,device_code_sel
    CreateCodeSelector16
;
    push cs
    push OFFSET install_dos_device_end
    push bx
    push ax
    retf

install_dos_device_end:
    popad
    pop es
    pop ds
    ret
install_dos_device      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           device16_thread
;
;           DESCRIPTION:    Device16 test thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_device16    Proc near
    push ds
    push es
    pushad
;       
    mov ecx,[edx].len
    sub ecx,SIZE rdos_header
    add edx,SIZE rdos_header
    mov esi,edx
    mov ebx,[esi].dev16_size
    mov edi,esi
    add edi,SIZE device16_header

install_device16_param_loop:
    mov al,[edi]
    inc edi
    or al,al
    jnz install_device16_param_loop
;       
    movzx ecx,[esi].dev16_code_size
    add edx,ebx
    mov bx,[esi].dev16_code_sel
    or bx,bx
    jnz install_device16_cr_code
;
    mov bx,device_code_sel

install_device16_cr_code:
    mov bp,bx
    CreateCodeSelector16
;
    xor bx,bx
    add edx,ecx
    movzx ecx,[esi].dev16_data_size
    or ecx,ecx
    jz install_device16_sel_ok
;
    mov bx,[esi].dev16_data_sel
    CreateDataSelector16

install_device16_sel_ok:
    mov ax,system_data_sel
    mov es,ax
    mov es:load_param_offset,edi
    mov es:load_param_sel,ds
;
    mov ax,ds
    mov es,ax
    mov ax,[esi].dev16_init_ip
    mov ds,bx
    push cs
    push OFFSET install_device16_end
    push bp
    push ax
    retf

install_device16_end:
    popad
    pop es
    pop ds
    ret
install_device16    Endp

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
    mov ax,system_data_sel
    mov es,ax
    mov es:load_param_offset,edi
    mov es:load_param_sel,ds
;
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
;           PARAMETERS:         edx         base address
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
    cmp ax,RdosSimpleDevice
    jne not_install_simple_device
;       
    call install_simple_device
    jmp install_adapter_next

not_install_simple_device:
    cmp ax,RdosDosDevice
    jne not_install_dos_device
;       
    call install_dos_device
    jmp install_adapter_next
    
not_install_dos_device:
    cmp ax,RdosDevice16
    jne not_install_dev16
;       
    call install_device16
    jmp install_adapter_next

not_install_dev16:
    cmp ax,RdosDevice32
    jne not_install_dev32
;       
    push edx
    add edx,SIZE rdos_header
    mov dx,[edx].dev32_code_sel
    cmp dx,debug_dev32_code_sel
    pop edx
    je install_adapter_next
;    
    call install_device32
    jmp install_adapter_next

not_install_dev32:
    cmp ax,RdosLongMode
    jne not_install_long_mode
;
    call install_long_mode
    jmp install_adapter_next

not_install_long_mode:
    cmp ax,RdosEnd
    je install_adapter_done

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
;           NAME:           GetImageHeader
;
;           DESCRIPTION:    Get image header
;
;           PARAMETERS:         AL              Adapter # (0..)
;               DL      Entry # (0..)
;               ES:(E)DI    Header buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_image_header_name   DB 'Get Image Header',0

get_image_header    Proc near
    push ds
    push ax
    push bx
    push ecx
    push dx
    push edi
    push esi
;    
    movzx ax,al
;    
    mov bx,system_data_sel
    mov ds,bx
    cmp ax,ds:rom_modules
    jae gihFail
;       
    mov bx,ax
    add bx,bx
    add bx,OFFSET rom_adapters
    mov esi,[bx].adapter_base
;
    mov ax,flat_sel
    mov ds,ax

gihLoop:
    mov ax,[esi].typ
    cmp ax,RdosEnd
    je gihFail
;
    or dl,dl
    jz gihOk
;
    add esi,[esi].len
    dec dl
    jmp gihLoop

gihOk:
    mov ecx,SIZE rdos_header
    rep movs byte ptr es:[edi],ds:[esi]
    clc
    jmp gihDone

gihFail:
    stc

gihDone:
    pop edi
    pop esi
    pop dx
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
get_image_header    Endp

get_image_header32  Proc far
    call get_image_header
    retf32
get_image_header32  Endp

get_image_header16  Proc far
    push edi
    movzx edi,di
    call get_image_header
    pop edi
    retf32
get_image_header16  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetImageData
;
;           DESCRIPTION:    Get image data
;
;           PARAMETERS:         AL              Adapter # (0..)
;               DL      Entry # (0..)
;               ES:(E)DI    Data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_image_data_name     DB 'Get Image Data',0

get_image_data    Proc near
    push ds
    push ax
    push bx
    push ecx
    push dx
    push edi
    push esi
;    
    movzx ax,al
;    
    mov bx,system_data_sel
    mov ds,bx
    cmp ax,ds:rom_modules
    jae gidFail
;       
    mov bx,ax
    add bx,bx
    add bx,OFFSET rom_adapters
    mov esi,[bx].adapter_base
;
    mov ax,flat_sel
    mov ds,ax

gidLoop:
    mov ax,[esi].typ
    cmp ax,RdosEnd
    je gidFail
;
    or dl,dl
    jz gidOk
;
    add esi,[esi].len
    dec dl
    jmp gidLoop

gidOk:
    mov ecx,[esi].len
    sub ecx,SIZE rdos_header
    jc gidFail
;
    add esi,SIZE rdos_header
    rep movs byte ptr es:[edi],ds:[esi]
    clc
    jmp gidDone

gidFail:
    stc

gidDone:
    pop edi
    pop esi
    pop dx
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
get_image_data    Endp

get_image_data32  Proc far
    call get_image_data
    retf32
get_image_data32  Endp

get_image_data16  Proc far
    push edi
    movzx edi,di
    call get_image_data
    pop edi
    retf32
get_image_data16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FindDevice
;
;           DESCRIPTION:    Find device from code-selector
;
;           PARAMETERS:         BX      Selector
;               EDX         base address
;               ES:EDI  Name buffer
;
;       RETURNS:    EAX     Code size
;               EDX     Data size
;               BX      Data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_device     Proc near
    push ds
    push esi
;       
    mov ax,flat_sel
    mov ds,ax
    
find_dev_loop:
    mov ax,[edx].typ
    cmp ax,RdosDevice16
    jne find_not_dev16
;       
    cmp bx,kernel_code
    je find_not_dev16
;
    mov esi,edx
    add esi,SIZE rdos_header
    cmp bx,[esi].dev16_code_sel
    jne find_next_dev
;
    movzx eax,[esi].dev16_code_size    
    movzx edx,[esi].dev16_data_size
    mov bx,[esi].dev16_data_sel
    add esi,SIZE device16_header

find_copy_name16:
    lods byte ptr [esi]
    stos byte ptr es:[edi]
    or al,al
    jnz find_copy_name16
;    
    clc
    jmp find_dev_done
    
find_not_dev16:
    cmp ax,RdosDevice32
    jne find_not_dev32
;
    mov esi,edx
    add esi,SIZE rdos_header
    cmp bx,[esi].dev32_code_sel
    jne find_next_dev
;
    mov eax,[esi].dev32_code_size    
    mov edx,[esi].dev32_data_size
    mov bx,[esi].dev32_data_sel
    add esi,SIZE device32_header

find_copy_name32:
    lods byte ptr [esi]
    stos byte ptr es:[edi]
    or al,al
    jnz find_copy_name32
;    
    clc
    jmp find_dev_done

find_not_dev32:
    cmp ax,RdosKernel
    jne find_not_kernel
;
    cmp bx,kernel_code
    jne find_not_kernel
;
    GetSelectorBaseSize
    mov eax,ecx
    xor edx,edx
    xor bx,bx
    xor al,al
    stos byte ptr es:[edi]
    clc
    jmp find_dev_done
    
find_not_kernel:
    cmp ax,RdosEnd
    stc
    je find_dev_done
    
find_next_dev:
    add edx,[edx].len
    jmp find_dev_loop

find_dev_found:
    clc

find_dev_done:
    pop esi
    pop ds
    ret
find_device     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetDeviceInfo
;
;           DESCRIPTION:    Get info about a device
;
;           PARAMETERS:     BX      Code segment selector
;               ES:(E)DI    Device name
;
;       RETURNS:    EAX     Code segment limit
;               EDX     Data segment limit
;               BX      Data segment selector (or 0)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_device_info_name    DB 'Get Device Info',0

get_device_info    Proc near
    push ds
    push ecx
    push esi
    push edi
;    
    mov ax,system_data_sel
    mov ds,ax
;       
    mov cx,ds:rom_modules
    mov si,OFFSET rom_adapters
gdiAdapterLoop:
    mov edx,[si].adapter_base
    call find_device
    jnc gdiDone
;       
    add si,SIZE adapter_typ
    loop gdiAdapterLoop     
;
    stc 

gdiDone:
    pop edi
    pop esi
    pop ecx
    pop ds
    ret
get_device_info    Endp

get_device_info32  Proc far
    call get_device_info
    retf32
get_device_info32  Endp

get_device_info16  Proc far
    push edi
    movzx edi,di
    call get_device_info
    pop edi
    retf32
get_device_info16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           load_device32
;
;           DESCRIPTION:    Load 32-bit device from application
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_device32_name    DB 'Load Dev32', 0

load_device32 Proc far
    push ds
    push es
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters

start_dev32_loop:
    mov edx,[bx].adapter_base
;
    push ds
    push bx
    push cx
    push edx    
;    
    mov ax,flat_sel
    mov ds,ax

start_dev32_adapter_loop:
    mov ax,[edx].typ
;    
    cmp ax,RdosEnd
    je start_dev32_adapter_done
;
    cmp ax,RdosDevice32
    jne start_dev32_adapter_next
;       
    push edx
    add edx,SIZE rdos_header
    mov dx,[edx].dev32_code_sel
    cmp dx,debug_dev32_code_sel
    pop edx
    jne start_dev32_adapter_next
;    
    call install_device32

start_dev32_adapter_next:
    add edx,[edx].len
    jmp start_dev32_adapter_loop

start_dev32_adapter_done:
    pop edx
    pop cx
    pop bx
    pop ds
;    
    add bx,SIZE adapter_typ
    loop start_dev32_loop   
;
    popad
    pop es
    pop ds
    retf32  
load_device32 Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetDeviceCmdLine
;
;           DESCRIPTION:    Get device cmd line
;
;           RETURNS:        ES:EDI	Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_device_cmd_line_name DB 'Get Device Cmd Line', 0

get_device_cmd_line    Proc far
    mov ax,system_data_sel
    mov es,ax
    mov edi,es:load_param_offset
    mov es,es:load_param_sel
    retf32
get_device_cmd_line    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_device
;
;           DESCRIPTION:    Init module (devices)
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_device

init_device     PROC near
    push ds
    push es
    pusha
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_device_cmd_line
    mov edi,OFFSET get_device_cmd_line_name
    xor cl,cl
    mov ax,get_device_cmd_line_nr
    RegisterOsGate
;
    mov esi,OFFSET load_device32
    mov edi,OFFSET load_device32_name
    xor dx,dx
    mov ax,load_device32_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_image_header16
    mov esi,OFFSET get_image_header32
    mov edi,OFFSET get_image_header_name
    mov dx,virt_es_in
    mov ax,get_image_header_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_image_data16
    mov esi,OFFSET get_image_data32
    mov edi,OFFSET get_image_data_name
    mov dx,virt_es_in
    mov ax,get_image_data_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_device_info16
    mov esi,OFFSET get_device_info32
    mov edi,OFFSET get_device_info_name
    mov dx,virt_es_in
    mov ax,get_device_info_nr
    RegisterUserGate
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
    popa
    pop es
    pop ds
    ret
init_device     ENDP
    
code    ENDS

    END
