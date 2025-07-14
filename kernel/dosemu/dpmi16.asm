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
; DPMI16.ASM
; 16-bit DPMI functions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_DESCR
;
;           DESCRIPTION:    ALLOCATE SELECTORS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_descr  PROC far
    push cx
    push dx
    cmp cx,1
    je dpmi_create_one
    AllocateMultipleLdt
    jmp dpmi_create_done
dpmi_create_one: 
    AllocateLdt
dpmi_create_done:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    mov dx,bx
    or dx,7
    xor ax,ax
dpmi_selector_init:
    mov [bx+6],al
    mov [bx],ax
    mov [bx+2],ax
    mov [bx+4],al
    mov byte ptr [bx+5],0F2h
    mov [bx+7],al
    add bx,8
    loop dpmi_selector_init
    mov ax,dx
    pop dx
    pop cx
    mov ebx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
allocate_descr  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FREE_DESCR
;
;           DESCRIPTION:    FREE SELECTOR
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_descr      PROC far
    push ds
    push es
    push fs
    push gs
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    test bl,4
    jz free_descr_fail
    and bl,0F8h
    FreeLdt
    clc
    pop ax
    verr ax
    jnz free_gs
    mov gs,ax
free_gs:
    pop ax
    verr ax
    jnz free_fs
    mov fs,ax
free_fs:
    pop ax
    verr ax
    jnz free_es
    mov es,ax
free_es:
    pop ax
    verr ax
    jnz free_ds
    mov ds,ax
free_ds:
    and byte ptr [bp].vm_eflags,NOT 1
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    retf32
free_descr_fail:
    or byte ptr [bp].vm_eflags,1
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    pop gs
    pop fs
    pop es
    pop ds
    retf32
free_descr      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_DECSR_DIST
;
;           DESCRIPTION:    GET DISTANCE BETWEEN SELECTORS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_descr_dist  PROC far
    mov ax,8
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_descr_dist  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_DECSR_BASE
;
;           DESCRIPTION:    GET SELCTOR BASE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_descr_base  PROC far
    test bl,4
    jz get_descr_base_fail
    push ax
    GetThread
    mov ds,ax
    pop ax
    mov ds,ds:p_ldt_sel
    and bl,0F8h
    mov al,[bx+5]
    and al,70h
    cmp al,70h
    jnz get_descr_base_fail
    mov dx,[bx+2]
    mov cl,[bx+4]
    mov ch,[bx+7]
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_descr_base_fail:
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    or byte ptr [bp].vm_eflags,1
    retf32
get_descr_base  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_DECSR_BASE
;
;           DESCRIPTION:    SET SELCTOR BASE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_descr_base  PROC far
    push es
    push fs
    push gs
    test bl,4
    jz set_descr_base_fail
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    and bl,0F8h
    mov al,[bx+5]
    and al,70h
    cmp al,70h
    jnz set_descr_base_fail
    mov [bx+2],dx
    mov [bx+4],cl
    mov [bx+7],ch
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags,NOT 1
    pop gs
    pop fs
    pop es
    retf32
set_descr_base_fail:
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    or byte ptr [bp].vm_eflags,1
    pop gs
    pop fs
    pop es
    retf32
set_descr_base  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_DECSR_LIMIT
;
;           DESCRIPTION:    SET SELCTOR LIMIT
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_descr_limit PROC far
    push es
    push fs
    push gs
    test bl,4
    jz set_descr_limit_fail
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    and bl,0F8h
    mov al,[bx+5]
    and al,70h
    cmp al,70h
    jnz set_descr_limit_fail
    push cx
    push dx
    pop eax
    cmp eax,100000h
    jc set_descr_small
    shr eax,12
    or byte ptr [bx+6],80h
    jmp set_descr_lim_do
set_descr_small:
    and byte ptr [bx+6],7Fh
set_descr_lim_do:
    mov [bx],ax
    shr eax,16
    mov ah,[bx+6]
    and ah,0F0h
    or al,ah
    mov [bx+6],al
    and byte ptr [bp].vm_eflags,NOT 1
    mov eax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    pop gs
    pop fs
    pop es
    retf32
set_descr_limit_fail:
    mov eax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    or byte ptr [bp].vm_eflags,1
    pop gs
    pop fs
    pop es
    retf32
set_descr_limit ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CREATE_CODE_DESCR_ALIAS
;
;           DESCRIPTION:    CREATES CODE DESCRIPTOR ALIAS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_code_descr_alias PROC far
    or bl,3
    verr bx
    jnz create_code_alias_fail
    test bl,4
    jz create_code_alias_fail
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    and bl,0F8h
    mov al,[bx+5]
    test al,8
    jz create_code_alias_fail
    push es
    push si
    push di
    mov ax,ds
    mov es,ax
    mov si,bx
    AllocateLdt
    mov di,bx
    movsd
    movsd
    mov byte ptr [bx+5],0F2h
    pop di
    pop si
    pop es
    mov ax,bx
    or al,7
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
create_code_alias_fail:
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    or byte ptr [bp].vm_eflags,1
    retf32
create_code_descr_alias ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SEGMENT_TO_DESCR
;
;           DESCRIPTION:    SEGMENT TO DESCR
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment_to_descr    PROC far
    AllocateLdt
    movzx eax,word ptr[bp].vm_ebx
    shl eax,4
    mov [bx+2],eax
    xor ax,ax
    mov byte ptr [bx+5],0F2h
    mov [bx+6],ax
    dec ax
    mov [bx],ax
    or bx,7
    mov [bp].vm_eax,bx
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
segment_to_descr    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_DECSR_ACCESS
;
;           DESCRIPTION:    SET SELCTOR ACCESS RIGHTS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_descr_access    PROC far
    push es
    push fs
    push gs
    test bl,4
    jz set_descr_access_fail
    mov al,cl
    and al,70h
    cmp al,70h
    jnz set_descr_access_fail
    test cl,8
    jz set_descr_access_ok
    test cl,4
    jnz set_descr_access_fail
    test cl,2
    jz set_descr_access_fail
set_descr_access_ok:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    and bl,0F8h
    mov al,[bx+5]
    and al,70h
    cmp al,70h
    jnz set_descr_access_fail
    mov [bx+5],cl
    and byte ptr [bp].vm_eflags,NOT 1
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    pop gs
    pop fs
    pop es
    retf32
set_descr_access_fail:
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    or byte ptr [bp].vm_eflags,1
    pop gs
    pop fs
    pop es
    retf32
set_descr_access    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_DESCR
;
;           DESCRIPTION:    GET DESCRIPTOR
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_descr       PROC far
    test bl,4
    jz get_descr_fail
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    and bl,0F8h
    mov al,[bx+5]
    and al,70h
    cmp al,70h
    jnz get_descr_fail
    mov eax,[bx]
    mov es:[di],eax
    mov eax,[bx+4]
    mov es:[di+4],eax
    mov eax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_descr_fail:
    mov eax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    or byte ptr [bp].vm_eflags,1
    retf32
get_descr       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_DESCR
;
;           DESCRIPTION:    SET DESCRIPTOR
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_descr       PROC far
    push es
    push fs
    push gs
    test bl,4
    jz set_descr_fail
    mov al,es:[di+6]
    or al,al
    jnz set_descr_fail
    mov al,es:[di+5]
    and al,70h
    cmp al,70h
    jnz set_descr_fail
    mov al,es:[di+5]
    test al,8
    jz set_descr_ok
    test al,4
    jnz set_descr_fail
    test al,2
    jz set_descr_fail
set_descr_ok:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    and bl,0F8h
    mov al,[bx+5]
    and al,70h
    cmp al,70h
    jnz set_descr_fail
    mov eax,es:[di]
    mov [bx],eax
    mov eax,es:[di+4]
    mov [bx+4],eax
    mov eax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags,NOT 1
    pop gs
    pop fs
    pop es
    retf32
set_descr_fail:
    mov eax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    or byte ptr [bp].vm_eflags,1
    pop gs
    pop fs
    pop es
    retf32
set_descr       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_SPECIFIC_DESCR
;
;           DESCRIPTION:    ALLOCATE SPECIFIC DESCRIPTOR
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_specific_descr PROC far
    test bl,4
    jz alloc_spec_descr_fail
    cmp bx,100h
    jnc alloc_spec_descr_fail
    and bl,0F8h     
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    mov al,[bx+5]
    or al,al
    jnz alloc_spec_descr_fail
    xor ax,ax
    mov [bx+6],al
    mov [bx],ax
    mov [bx+2],ax
    mov [bx+4],al
    mov byte ptr [bx+5],0F2h
    mov [bx+7],al
    mov ax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
alloc_spec_descr_fail:
    mov ax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    or byte ptr [bp].vm_eflags,1
    retf32
allocate_specific_descr ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_DOS_MEM
;
;           DESCRIPTION:    
;
;           PARAMETERS:         BX              NUMBER OF PARAGRAPH
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dos_mem    PROC far
    push ds
    push es
    push bx
    movzx eax,bx
    shl eax,4
    AllocateDosMem
    jc allocate_dos_mem_fail
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    mov bx,es
    mov dx,bx
    and bx,0FFF8h
    mov eax,[bx+2]
    shr eax,4
    and eax,0FFFFh
    and byte ptr [bp].vm_eflags,NOT 1
    pop bx
    pop es
    pop ds
    retf32
allocate_dos_mem_fail:
    pop bx
    pop es
    pop ds
    push eax
    push edx
    AvailableDosLinear
    shr edx,4
    mov bx,dx
    pop edx
    pop eax
    or byte ptr [bp].vm_eflags,1
    retf32
allocate_dos_mem    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_REAL_INT
;
;           DESCRIPTION:    GET REAL MODE INT VECTOR
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_real_int    PROC far
    mov al,bl
    GetVMInt
    mov cx,dx
    mov dx,bx
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_real_int    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_REAL_INT
;
;           DESCRIPTION:    SET REAL MODE INT VECTOR
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_real_int    PROC far
    mov al,bl
    mov bx,dx
    mov dx,cx
    SetVMInt
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
set_real_int    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_EXCEPTION
;
;           DESCRIPTION:    GET EXCEPTION VECTOR
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exception   PROC far
    push es
    push di
    mov al,bl
    GetException
    mov cx,es
    mov dx,di
    pop di
    pop es
    mov ax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_exception   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_EXCEPTION
;
;           DESCRIPTION:    SET EXCEPTION VECTOR
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_exception   PROC far
    push es
    push di
    mov al,bl
    mov es,cx
    mov di,dx
    SetException
    pop di
    pop es
    mov ax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
set_exception   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_VECTOR
;
;           DESCRIPTION:    GET INT VECTOR
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vector      PROC far
    push es
    push di
    mov al,bl
    GetPMInt
    mov cx,es
    mov dx,di
    pop di
    pop es
    mov ax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_vector      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_VECTOR
;
;           DESCRIPTION:    SET INT VECTOR
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_vector      PROC far
    push es
    push di
    mov al,bl
    mov es,cx
    mov di,dx
    SetPMInt
    pop di
    pop es
    mov ax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
set_vector      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SIM_REAL_INT
;
;           DESCRIPTION:    SIMULERA REAL MODE INT
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_real_int    PROC far
    push si
    mov ds,[bp].vm_ss
    mov si,[bp].vm_esp
    mov al,bl
    DpmiInt
    pop si
    mov ds,[bp].pm_ds
    mov eax,[bp].vm_eax
    and byte ptr [bp].vm_eflags, NOT 1
    retf32
sim_real_int    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SIM_REAL_CALL
;
;           DESCRIPTION:    SIMULERA REAL MODE CALL
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_real_call   PROC far
    push si
    mov ds,[bp].vm_ss
    mov si,[bp].vm_esp
    DpmiCall
    pop si
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags, NOT 1
    retf32
sim_real_call   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SIM_REAL_CALL_INT
;
;           DESCRIPTION:    SIMULERA REAL MODE CALL WITH IRET
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_real_call_int       PROC far
    push si
    mov ds,[bp].vm_ss
    mov si,[bp].vm_esp
    DpmiCallInt
    pop si
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags, NOT 1
    retf32
sim_real_call_int       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_VM_CALLBACK
;
;           DESCRIPTION:    ALLOKERA VM CALLBACK
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_vm_callback    PROC far
    AllocateVMCallback
    mov cx,dx
    mov dx,ax
    mov ax,[bp].vm_eax
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags, NOT 1
    retf32
allocate_vm_callback    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FREE_VM_CALLBACK
;
;           DESCRIPTION:    FRIG™R VM CALLBACK
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_vm_callback    PROC far
    push cx
    push dx
    mov ax,dx
    mov dx,cx
    FreeVMCallback
    pop dx
    pop cx
    and byte ptr [bp].vm_eflags, NOT 1
    retf32
free_vm_callback    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DPMI_GET_STATE_SR_ADDR
;
;           DESCRIPTION:    GET STATE SAVE/RESTORE ADDRESS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_get_save_restore_addr      PROC far
    mov ax,state_save_sel
    mov ds,ax
    xor ax,ax
    xor si,si
    mov cx,ds:[si]
    mov bx,ds:[si+2]
    mov si,ds
    mov di,4
    add cx,4
    mov ds,[bp].pm_ds       
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
dpmi_get_save_restore_addr      ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DPMI_GET_RAW_SWITCH_ADDR
;
;           DESCRIPTION:    GET RAW MODE SWITCH ADDRESS
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_get_raw_switch_addr    PROC far
    GetRawSwitchAds
    xor ax,ax
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
dpmi_get_raw_switch_addr    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_VERSION
;
;           DESCRIPTION:    GET DPMI VERSION
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
get_version     PROC far
    mov ax,9
    mov bx,5
    mov cl,3
    mov dx,2838h
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_version     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_FREE_MEM
;
;           DESCRIPTION:    GET FREE MEMORY INFO
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
get_free_mem    PROC far
    push eax
    push edx
    UsedLocalLinear
    mov edx,eax
    AvailableSmallLocalLinear
    mov eax,800000h
    add edx,eax
    shr edx,12
    mov es:[di],eax
    shr eax,12
    mov es:[di+4],eax
    mov es:[di+8],eax
    mov es:[di+12],edx
    mov es:[di+28],edx
    mov dword ptr es:[di+16],-1
    GetFreePhysical
    shr eax,12
    mov es:[di+20],eax
    mov dword ptr es:[di+24],-1
    mov dword ptr es:[di+32],-1
    pop edx     
    pop eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_free_mem    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_MEM
;
;           DESCRIPTION:    ALLOCATE LOCAL MEMORY
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_mem    PROC far
    push edx
    push ecx
    mov eax,8
    AllocateLocalLinear
    push edx
    mov di,dx
    shr edx,16
    mov si,dx
    mov ax,flat_sel
    mov ds,ax       
    mov ax,bx
    shl eax,16
    mov ax,cx
    AllocateLocalLinear
    pop ecx
    mov [ecx],eax
    mov [ecx+4],edx
    pop ecx
    mov cx,dx
    shr edx,16
    mov bx,dx
    pop edx
    mov eax,[bp].vm_eax
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
allocate_mem    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FREE_MEM
;
;           DESCRIPTION:    FREE LOCAL MEMORY
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_mem    PROC far
    push ecx
    push edx
    mov dx,si
    shl edx,16
    mov dx,di
    mov ax,flat_sel
    mov ds,ax
    mov ecx,[edx]
    mov edx,[edx+4]
    FreeLinear
    pop edx
    pop ecx
    mov eax,[bp].vm_eax
    mov ds,[bp].pm_ds
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
free_mem    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DPMI_PAGE_SIZE
;
;           DESCRIPTION:    GET PAGE SIZE 16 AND 32-BIT
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_page_size  PROC far
    xor bx,bx
    mov cx,1000h
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
dpmi_page_size  ENDP
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_INT
;
;           DESCRIPTION:    GET VIRTUAL INTERRUPT STATE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


get_int PROC far
    xor ax,ax
    GetFlags
    shr ax,9
    and al,1
    mov ah,9
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_int ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_DISABLE_INT
;
;           DESCRIPTION:    GET AND DISABLE VIRTUAL INTERRUPT STATE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disable_int PROC far
    xor ax,ax
    GetFlags
    SimCli
    shr ax,9
    and al,1
    mov ah,9
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_disable_int ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_ENABLE_INT
;
;           DESCRIPTION:    GET AND ENABLE VIRTUAL INTERRUPT STATE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_enable_int  PROC far
    xor ax,ax
    GetFlags
    SimSti
    shr ax,9
    and al,1
    mov ah,9
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_enable_int  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DPMI_DUMMY
;
;           DESCRIPTION:    DUMMY DPMI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dpmi_dummy      PROC far
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
dpmi_dummy      ENDP

dpmi_error      PROC far
    int 3
    or byte ptr [bp].vm_eflags,1
    retf32
dpmi_error      ENDP

dpmi_descriptor:
dd_ant  DW 0Dh
dd00    DW OFFSET allocate_descr
dd01    DW OFFSET free_descr
dd02    DW OFFSET segment_to_descr
dd03    DW OFFSET get_descr_dist
dd04    DW OFFSET dpmi_error
dd05    DW OFFSET dpmi_error
dd06    DW OFFSET get_descr_base
dd07    DW OFFSET set_descr_base
dd08    DW OFFSET set_descr_limit
dd09    DW OFFSET set_descr_access
dd0A    DW OFFSET create_code_descr_alias
dd0B    DW OFFSET get_descr
dd0C    DW OFFSET set_descr
dd0D    DW OFFSET allocate_specific_descr

dpmi_dosmem:
ds_ant  DW 2
ds00    DW OFFSET allocate_dos_mem
ds01    DW OFFSET dpmi_error
ds02    DW OFFSET dpmi_error

dpmi_int:
di_ant  DW 10h
di00    DW OFFSET get_real_int
di01    DW OFFSET set_real_int
di02    DW OFFSET get_exception
di03    DW OFFSET set_exception
di04    DW OFFSET get_vector
di05    DW OFFSET set_vector
di06    DW OFFSET dpmi_error
di07    DW OFFSET dpmi_error
di08    DW OFFSET dpmi_error
di09    DW OFFSET dpmi_error
di0A    DW OFFSET dpmi_error
di0B    DW OFFSET dpmi_error
di0C    DW OFFSET dpmi_error
di0D    DW OFFSET dpmi_error
di0E    DW OFFSET dpmi_error
di0F    DW OFFSET dpmi_error
di10    DW OFFSET get_exception

dpmi_translate:
dt_ant  DW 6
dt00    DW OFFSET sim_real_int
dt01    DW OFFSET sim_real_call
dt02    DW OFFSET sim_real_call_int
dt03    DW OFFSET allocate_vm_callback
dt04    DW OFFSET free_vm_callback
dt05    DW OFFSET dpmi_get_save_restore_addr
dt06    DW OFFSET dpmi_get_raw_switch_addr

dpmi_ver:
dv_ant  DW 0
dv00    DW OFFSET get_version

dpmi_mem:
dm_ant  DW 3
dm00    DW OFFSET get_free_mem
dm01    DW OFFSET allocate_mem
dm02    DW OFFSET free_mem
dm03    DW OFFSET dpmi_error

dpmi_page:
dp_ant  DW 4
dp00    DW OFFSET dpmi_dummy
dp01    DW OFFSET dpmi_dummy
dp02    DW OFFSET dpmi_dummy
dp03    DW OFFSET dpmi_dummy
dp04    DW OFFSET dpmi_page_size

dpmi_paging:
dg_ant  DW 3
dg00    DW OFFSET dpmi_error
dg01    DW OFFSET dpmi_error
dg02    DW OFFSET dpmi_dummy
dg03    DW OFFSET dpmi_dummy

dpmi_physical:
dy_ant  DW 0
dy00    DW OFFSET dpmi_dummy

dpmi_virtint:
dr_ant  DW 2
dr00    DW OFFSET get_disable_int
dr01    DW OFFSET get_enable_int
dr02    DW OFFSET get_int

dpmi_vendorapi:
da_ant  DW 0
da00    DW OFFSET dpmi_error

dpmi_debug:
de_ant  DW 3
de00    DW OFFSET dpmi_error
de01    DW OFFSET dpmi_error
de02    DW OFFSET dpmi_error
de03    DW OFFSET dpmi_error

dpmi_tab:
dpmi00  DW OFFSET dpmi_descriptor
dpmi01  DW OFFSET dpmi_dosmem
dpmi02  DW OFFSET dpmi_int
dpmi03  DW OFFSET dpmi_translate
dpmi04  DW OFFSET dpmi_ver
dpmi05  DW OFFSET dpmi_mem
dpmi06  DW OFFSET dpmi_page
dpmi07  DW OFFSET dpmi_paging
dpmi08  DW OFFSET dpmi_physical
dpmi09  DW OFFSET dpmi_virtint
dpmi0A  DW OFFSET dpmi_vendorapi
dpmi0B  DW OFFSET dpmi_debug

int31:
    mov bl,ah
    xor bh,bh
    add bx,bx
    mov bx,word ptr cs:[bx].dpmi_tab
    cmp al,cs:[bx]
    jz int31_ok
    jc int31_ok
    mov bx,OFFSET dpmi_error
    jmp int31_do
int31_ok:
    add bx,2
    add bl,al
    adc bh,0
    add bl,al
    adc bh,0
    mov bx,cs:[bx]
int31_do:
    push bx
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    retn


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_DPMI16
;
;           DESCRIPTION:    Init 16-bit DPMI
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_dpmi16

state_save_begin:
    DW ?
    DW ?
    retf
state_save_end:

init_dpmi16     PROC near
    push ds
    push es
    pushad
;
    mov al,31h
    mov edi,OFFSET int31
    HookProt16Int
;
    mov eax,OFFSET state_save_end - OFFSET state_save_begin
    mov ecx,eax
    AllocateFixedVMLinear
    mov bx,state_save_sel
    CreateDataSelector16
    mov es,bx
;
    xor di,di
    mov ax,dx
    and ax,0Fh
    stosw
    mov eax,edx
    shr eax,4
    stosw
;
    push cx
    mov cx,OFFSET state_save_end - OFFSET state_save_begin - 4
    mov ax,cs
    mov ds,ax
    mov si,OFFSET state_save_begin + 4
    rep movsb
    pop cx
    xor ax,ax
    mov es,ax
    CreateCodeSelector16
;
    popad
    pop es
    pop ds
    ret
init_dpmi16     ENDP

code    ENDS

    END

