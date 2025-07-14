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
; ENV.ASM
; Environment string handling module
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
INCLUDE ..\handle.inc
INCLUDE ..\apicheck.inc
INCLUDE exec.def

ENV_MODE_GLOBAL     = 1
ENV_MODE_PROCESS    = 2

env_handle_seg  STRUC

env_handle_base handle_header <>

env_handle_mode DB ?

env_handle_seg  ENDS
    
data    SEGMENT byte public 'DATA'

env_sys_section     section_typ <>

env_sys_raw_sel     DW ?

data  ENDS

env_proc_seg  STRUC

env_proc_section     section_typ <>

env_proc_raw_sel     DW ?

env_proc_seg  ENDS
    
code    SEGMENT byte use16 public 'CODE'

    .386p

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           load_set_var
;
;           DESCRIPTION:    Load SET variables
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_set_var    Proc near
    push ax
    push edx
    push esi
    add edx,SIZE rdos_header
    mov esi,edx     
    
init_set_var_loop:
    lods byte ptr [esi]
    stosb
    or al,al
    jne init_set_var_loop
;
    pop esi
    pop edx
    pop ax
    ret
load_set_var    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           load_path
;
;           DESCRIPTION:    Load PATH variables
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

path_text DB 'PATH'

load_path       Proc near
    push eax
    push edx
    push esi
    add edx,SIZE rdos_header
    mov esi,edx
    mov eax,dword ptr cs:path_text
    stosd
    mov al,'='
    stosb
init_path_var_loop:
    lods byte ptr [esi]
    stosb
    or al,al
    jne init_path_var_loop
    pop esi
    pop edx
    pop eax
    ret
load_path       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           load_adapter_env
;
;           DESCRIPTION:    Install all variables from adapter
;
;           PARAMETERS:         edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_adapter_env    Proc near
    push ds
    push ax
    push bx
    push edx
    mov ax,flat_sel
    mov ds,ax
load_adapter_env_loop:
    mov ax,[edx].typ
    cmp ax,RdosSet
    jne not_load_set
    call load_set_var
    jmp load_adapter_env_next
not_load_set:
    cmp ax,RdosPath
    jne not_load_path
    call load_path
    jmp load_adapter_env_next
not_load_path:
    cmp ax,RdosEnd
    je load_adapter_env_done
load_adapter_env_next:
    add edx,[edx].len
    jmp load_adapter_env_loop
load_adapter_env_done:
    pop edx
    pop bx
    pop ax
    pop ds
    ret
load_adapter_env    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockSysEnv
;
;           DESCRIPTION:    Lock system env and return raw data selector
;
;           RETURNS:        BX              Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_sys_env_name       DB 'Lock Sys Env',0

lock_sys_env    Proc far
    push ds
;
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:env_sys_section
    mov bx,ds:env_sys_raw_sel
;
    pop ds
    retf32
lock_sys_env    Endp
   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockSysEnv
;
;           DESCRIPTION:    Unlock system env
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_sys_env_name     DB 'Unlock Sys Env',0

unlock_sys_env    Proc far
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    LeaveSection ds:env_sys_section
;
    pop bx
    pop ds
    retf32
unlock_sys_env    Endp
   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockProcEnv
;
;           DESCRIPTION:    Lock process env and return raw data selector
;
;           RETURNS:        BX              Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_proc_env_name      DB 'Lock Proc Env',0

lock_proc_env    Proc far
    push ds
;
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_env_sel
    pop ax
;
    EnterSection ds:env_proc_section
    mov bx,ds:env_proc_raw_sel
;
    pop ds
    retf32
lock_proc_env    Endp
   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockProcEnv
;
;           DESCRIPTION:    Unlock process env
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_proc_env_name    DB 'Unlock Proc Env',0

unlock_proc_env    Proc far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_env_sel
    LeaveSection ds:env_proc_section
;
    pop ax
    pop ds
    retf32
unlock_proc_env    Endp
   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenSysEnv
;
;           DESCRIPTION:    Open system envvar handle
;
;           RETURNS:        BX              Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_sys_env_name       DB 'Open Sys Env',0

open_sys_env    Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push cx
;
    mov cx,SIZE env_handle_seg
    AllocateHandle
    mov [ebx].env_handle_mode,ENV_MODE_GLOBAL
    mov [ebx].hh_sign,ENV_HANDLE
    mov bx,[ebx].hh_handle
;
    pop cx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    retf32
open_sys_env    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       OpenProcEnv
;
;       DESCRIPTION:    Open process envvar handle
;
;       RETURNS:    BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_proc_env_name  DB 'Open Proc Env',0

open_proc_env    Proc far
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push cx
;
    mov cx,SIZE env_handle_seg
    AllocateHandle
    mov [ebx].env_handle_mode,ENV_MODE_PROCESS
    mov [ebx].hh_sign,ENV_HANDLE
    mov bx,[ebx].hh_handle
;
    pop cx
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    retf32
open_proc_env    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       CloseEnv
;
;       DESCRIPTION:    Close envvar handle
;
;       PARAMETERS:     BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_env_name  DB 'Close Env',0

close_env   Proc far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push es
    push ax
    push bx
;
    mov ax,ENV_HANDLE
    DerefHandle
    jc close_env_done
;
    FreeHandle
    clc

close_env_done:
    pop bx
    pop ax
    pop es
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
close_env   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       AddEnvVar
;
;       DESCRIPTION:    Add a envvar
;
;       PARAMETERS:     BX      Handle
;               DS:(E)SI    Env var name buffer
;               ES:(E)DI    Env var data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_env_var_name        DB 'Add Env Var',0
add_sys_env_var_name    DB 'Add Sys Env Var',0

add_env_base    Proc near
    push es
    push edi
;
    mov es,bx
    mov ebp,esi
    xor edi,edi

add_env_search_loop:
    cmps byte ptr [esi],[edi]
    jnz add_env_next
;
    mov al,[esi]
    or al,al
    jnz add_env_search_loop
;
    mov al,es:[edi]
    cmp al,'='
    je add_env_var_found

add_env_next:
    mov al,es:[edi]
    inc edi
    or al,al
    jnz add_env_next
;
    mov al,es:[edi]
    or al,al
    mov esi,ebp
    jne add_env_search_loop
    jmp add_env_new

add_env_var_found:
    inc edi
    push esi
    push edi
;
    xor ebx,ebx
    xor ecx,ecx

add_env_curr_var_loop:
    inc edi
    inc ebx
    mov al,es:[edi]
    or al,al
    jnz add_env_curr_var_loop
;
    inc ecx
    jmp add_env_check_end

add_env_size_var_loop:
    inc edi
    inc ecx
    mov al,es:[edi]
    or al,al
    jnz add_env_size_var_loop

add_env_check_end:
    inc edi
    inc ecx
    mov al,es:[edi]
    or al,al
    jnz add_env_size_var_loop
;
    pop edi
    pop esi
;
    mov edx,ecx
    push esi
    push edi
    mov esi,edi
    add esi,ebx
    rep movs byte ptr es:[edi],es:[esi]
    pop edi
    pop esi
;
    pop esi
    pop ds
;
    push esi
    xor ecx,ecx

add_env_data_size_loop:
    lods byte ptr [esi]
    inc ecx
    or al,al
    jnz add_env_data_size_loop
;
    push ecx
    push edi
;    
    mov esi,edi
    add edi,ecx
    dec edi
    mov ecx,edx
    add esi,ecx
    add edi,ecx
    dec esi
    dec edi
    std
    rep movs byte ptr es:[edi],es:[esi]
    cld
;
    pop edi
    pop ecx
    pop esi
;
    rep movs byte ptr es:[edi],ds:[esi]
    clc
    jmp add_env_base_done

add_env_new:
    mov esi,ebp

add_env_new_var:
    lods byte ptr [esi]
    or al,al
    jz add_env_assign
;
    stos byte ptr es:[edi]
    jmp add_env_new_var

add_env_assign:
    mov al,'='
    stos byte ptr es:[edi]
;
    pop esi
    pop ds

add_env_new_data:
    lods byte ptr [esi]
    stos byte ptr es:[edi]
    or al,al
    jnz add_env_new_data
;
    xor al,al
    stos byte ptr es:[edi]

add_env_base_done:
    ret
add_env_base    Endp

add_env_var    Proc near
    push ds
    push es
    pushad
;
    push ds
    mov ax,ENV_HANDLE
    DerefHandle
    mov al,[ebx].env_handle_mode
    pop ds
    jc add_env_var_done
;
    cmp al,ENV_MODE_GLOBAL
    je add_sys_env
;
    LockProcEnv
    call add_env_base
    pushf
    UnlockProcEnv
    popf
    jmp add_env_var_done

add_sys_env:
    LockSysEnv
    call add_env_base
    pushf
    UnlockSysEnv
    popf

add_env_var_done:    
    popad
    pop es
    pop ds
    ret
add_env_var    Endp

add_env_var16  Proc far
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    call add_env_var
;
    pop edi
    pop esi
    retf32
add_env_var16  Endp

add_env_var32:
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    call add_env_var

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32

add_sys_env_var:
    push ds
    push es
    pushad
;    
    LockSysEnv
    call add_env_base
    pushf
    UnlockSysEnv
    popf
;
    popad
    pop es
    pop ds
    retf32   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       DeleteEnvVar
;
;       DESCRIPTION:    Delete an envvar
;
;       PARAMETERS:     BX      Handle
;               DS:(E)SI    Env var name buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_env_var_name     DB 'Delete Env Var',0
delete_sys_env_var_name DB 'Delete Sys Env Var',0

delete_env_base Proc near
    mov ebp,esi
    xor edi,edi
    xor ecx,ecx
    xor ebx,ebx

del_env_search_loop:
    cmps byte ptr [esi],[edi]
    jnz del_env_next
;
    inc ebx
    mov al,[esi]
    or al,al
    jnz del_env_search_loop
;
    mov al,es:[edi]
    cmp al,'='
    je del_env_var_found

del_env_next:
    mov al,es:[edi]
    inc edi
    or al,al
    jnz del_env_next
;
    mov esi,ebp
    xor ebx,ebx
    mov al,es:[edi]
    or al,al
    jne del_env_search_loop
;
    stc
    jmp del_env_base_done

del_env_var_found:
    mov eax,edi
    sub eax,ebx
    push eax
    inc edi
    inc ebx

del_env_data_loop:
    inc edi
    inc ebx
    mov al,es:[edi]
    or al,al
    jnz del_env_data_loop
;
    inc ebx
    jmp del_env_check_end

del_env_size_var_loop:
    inc edi
    inc ecx
    mov al,es:[edi]
    or al,al
    jnz del_env_size_var_loop

del_env_check_end:
    inc edi
    inc ecx
    mov al,es:[edi]
    or al,al
    jnz del_env_size_var_loop
;
    pop edi
;
    mov edx,ecx
    mov esi,edi
    add esi,ebx
    rep movs byte ptr es:[edi],es:[esi]
    clc

del_env_base_done:
    ret
delete_env_base Endp    

delete_env_var    Proc near
    push ds
    push es
    pushad
;
    push ds
    mov ax,ENV_HANDLE
    DerefHandle
    mov al,[ebx].env_handle_mode
    pop ds
    jc del_env_var_done
;
    cmp al,ENV_MODE_GLOBAL
    je del_sys_env
;
    LockProcEnv
    mov es,bx
    call delete_env_base
    pushf
    UnlockProcEnv
    popf
    jmp del_env_var_done

del_sys_env:
    LockSysEnv
    mov es,bx
    call delete_env_base
    pushf
    UnlockSysEnv
    popf

del_env_var_done:    
    popad
    pop es
    pop ds
    ret
delete_env_var    Endp

delete_env_var16  Proc far
    push esi
    movzx esi,si
    call delete_env_var
    pop esi
    retf32
delete_env_var16  Endp

delete_env_var32:
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    call delete_env_var

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32


delete_sys_env_var:
    push ds
    push es
    pushad
;    
    LockSysEnv
    mov es,bx
    call delete_env_base
    pushf
    UnlockSysEnv
    popf
;
    popad
    pop es
    pop ds
    retf32
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       FindEnvVar
;
;       DESCRIPTION:    Find a envvar
;
;       PARAMETERS:     BX      Handle
;               DS:(E)SI    Env var name buffer
;               ES:(E)DI    Env var data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_env_var_name       DB 'Find Env Var',0
find_sys_env_var_name   DB 'Find Sys Env Var',0

find_env_base   Proc near
    push es
    push edi
;
    mov es,bx
    mov ebp,esi
    xor edi,edi

find_env_search_loop:
    cmps byte ptr [esi],[edi]
    jnz find_env_next
;
    mov al,[esi]
    or al,al
    jnz find_env_search_loop
;
    mov al,es:[edi]
    cmp al,'='
    je find_env_var_found

find_env_next:
    mov al,es:[edi]
    inc edi
    or al,al
    jnz find_env_next
;
    mov esi,ebp
    mov al,es:[edi]
    or al,al
    jne find_env_search_loop
;
    pop edi
    pop es
;
    xor al,al
    stos byte ptr es:[edi]
    stc
    jmp find_env_base_done

find_env_var_found:    
    mov bx,es
    mov ds,bx
    mov esi,edi
;
    pop edi
    pop es
;
    inc esi

find_env_copy_loop:
    lods byte ptr [esi]
    stos byte ptr es:[edi]
    or al,al
    jnz find_env_copy_loop
;
    clc

find_env_base_done:
    ret
find_env_base   Endp    

find_env_var    Proc near
    push ds
    push es
    pushad
;
    push ds
    mov ax,ENV_HANDLE
    DerefHandle
    mov al,[ebx].env_handle_mode
    pop ds
    jc find_env_var_done
;
    cmp al,ENV_MODE_GLOBAL
    je find_sys_env
;
    LockProcEnv
    call find_env_base
    pushf
    UnlockProcEnv
    popf
    jmp find_env_var_done

find_sys_env:
    LockSysEnv
    call find_env_base
    pushf
    UnlockSysEnv
    popf

find_env_var_done:    
    popad
    pop es
    pop ds
    ret
find_env_var    Endp

find_env_var16  Proc far
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    call find_env_var
;
    pop edi
    pop esi
    retf32
find_env_var16  Endp

find_env_var32:
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    call find_env_var

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32

find_sys_env_var:
    push ds
    push es
    pushad
;    
    LockSysEnv
    call find_env_base
    pushf
    UnlockSysEnv
    popf
;
    popad
    pop es
    pop ds
    retf32
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       GetEnvSize
;
;       DESCRIPTION:    Get size raw env data 
;
;       PARAMETERS:     BX      Handle
;
;       RETURNS:    (E)AX       Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_env_size_name   DB 'Get Env Size',0

get_env_size_base   Proc near   
    xor esi,esi
    xor ecx,ecx

get_env_var_size_loop:
    lods byte ptr [esi]
    inc ecx
    or al,al
    jnz get_env_var_size_loop
;
    mov al,[esi]
    or al,al
    jnz get_env_var_size_loop
;
    inc ecx
    ret
get_env_size_base   Endp

get_env_size:
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push es
    push ebx
    push ecx
    push esi
;
    mov ax,ENV_HANDLE
    DerefHandle
    jc get_env_size_done
;
    mov al,ds:[ebx].env_handle_mode
    cmp al,ENV_MODE_GLOBAL
    je get_sys_env_size
;
    LockProcEnv
    mov ds,bx
    call get_env_size_base
    UnlockProcEnv
    clc
    jmp get_env_size_done

get_sys_env_size:
    LockSysEnv
    mov ds,bx
    call get_env_size_base
    UnlockSysEnv
    clc

get_env_size_done:
    mov eax,ecx
;    
    pop esi
    pop ecx
    pop ebx
    pop es
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       GetEnvData
;
;       DESCRIPTION:    Get raw env data
;
;       PARAMETERS:     BX      Handle
;               ES:(E)DI    Env data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_env_data_name   DB 'Get Env Data',0

get_env_data_base   Proc near   
    xor esi,esi

get_env_var_data_loop:
    lods byte ptr [esi]
    stos byte ptr es:[edi]
    or al,al
    jnz get_env_var_data_loop
;
    mov al,[esi]
    or al,al
    jnz get_env_var_data_loop
;
    stos byte ptr es:[edi]
    ret
get_env_data_base   Endp

get_env_data    Proc near
    push ds
    push es
    pushad
;
    mov ax,ENV_HANDLE
    DerefHandle
    jc get_env_data_done
;
    mov al,ds:[ebx].env_handle_mode
    cmp al,ENV_MODE_GLOBAL
    je get_sys_env
;
    LockProcEnv
    mov ds,bx
    call get_env_data_base
    UnlockProcEnv
    clc
    jmp get_env_data_done

get_sys_env:
    LockSysEnv
    mov ds,bx
    call get_env_data_base
    UnlockSysEnv
    clc

get_env_data_done:
    popad
    pop es
    pop ds
    ret
get_env_data    Endp

get_env_data16  Proc far
    push edi
;
    movzx edi,di
    call get_env_data
;
    pop edi
    retf32
get_env_data16  Endp

get_env_data32:
    call get_env_data
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       SetEnvData
;
;       DESCRIPTION:    Set raw env data
;
;       PARAMETERS:     BX      Handle
;               ES:(E)DI    Env data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_env_data_name   DB 'Set Env Data',0

set_env_data_base   Proc near   
    xor edi,edi

set_env_var_data_loop:
    lods byte ptr [esi]
    stos byte ptr es:[edi]
    or al,al
    jnz set_env_var_data_loop
;
    mov al,[esi]
    or al,al
    jnz set_env_var_data_loop
;
    stos byte ptr es:[edi]
    ret
set_env_data_base   Endp

set_env_data    Proc near
    push ds
    push es
    pushad
;
    mov esi,edi
    push es
    mov ax,ENV_HANDLE
    DerefHandle
    mov al,ds:[ebx].env_handle_mode
    pop ds
    jc set_env_data_done
;
    cmp al,ENV_MODE_GLOBAL
    je set_sys_env
;
    LockProcEnv
    mov es,bx
    call set_env_data_base
    UnlockProcEnv
    clc
    jmp set_env_data_done

set_sys_env:
    LockSysEnv
    mov es,bx
    call set_env_data_base
    UnlockSysEnv
    clc

set_env_data_done:
    popad
    pop es
    pop ds
    ret
set_env_data    Endp

set_env_data16  Proc far
    push edi
;
    movzx edi,di
    call set_env_data
;
    pop edi
    retf32
set_env_data16  Endp

set_env_data32:
    call set_env_data
    retf32


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       Delete_handle
;
;       DESCRIPTION:    Delete handle (called from handle module)
;
;       PARAMETERS:     BX      ENV HANDLE
;               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push es
    push ebx
;
    mov ax,ENV_HANDLE
    DerefHandle
    jc delete_handle_done
;
    FreeHandle
    clc

delete_handle_done:
    pop ebx
    pop es
    pop ds
    retf32
delete_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           CreateEnvSel
;
;       DESCRIPTION:    Create environment for program
;
;       RETURNS:        AX		Env sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_env_sel_name DB 'Create Env Sel', 0

create_env_sel    Proc far
    push ds
    push es
    push ebx
    push esi
    push edi
;
    LockSysEnv
    mov ds,bx
    xor si,si
;
    mov eax,4000h
    AllocateGlobalMem
    xor di,di

cresLoop:
    lodsb
    stosb
    or al,al
    jnz cresLoop
;
    mov al,[si]
    or al,al
    jnz cresLoop
;
    xor al,al
    stosb
;
    UnlockSysEnv
;
    push es
    mov eax,SIZE env_proc_seg
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    pop es
;
    InitSection ds:env_proc_section
    mov ds:env_proc_raw_sel,es
    mov ax,ds
;
    pop edi
    pop esi
    pop ebx
    pop es
    pop ds
    retf32
create_env_sel    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           CloneEnvSel
;
;       DESCRIPTION:    Clone environment for program
;
;       PARAMETERS:     AX              Env sel to clone
;
;       RETURNS:        AX		New env sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clone_env_sel_name DB 'Clone Env Sel', 0

clone_env_sel    Proc far
    push ds
    push es
    push ecx
    push esi
    push edi
;
    mov ds,ax
    mov ds,ds:env_proc_raw_sel
    xor si,si
;
    mov eax,4000h
    AllocateGlobalMem
    xor di,di
    mov cx,ax
    rep movsb
;
    push es
    mov eax,SIZE env_proc_seg
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    pop es
;
    InitSection ds:env_proc_section
    mov ds:env_proc_raw_sel,es
    mov ax,ds
;
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
    retf32
clone_env_sel    Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           DeleteEnvSel
;
;       DESCRIPTION:    Delete environment for program
;
;       PARAMETERS:     AX          Env sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_env_sel_name DB 'Delete Env Sel', 0

delete_env_sel    Proc far
    push ds
    push es
    pushad
;
    mov ds,ax
    mov es,ds:env_proc_raw_sel
    FreeMem
;
    mov es,ax
    FreeMem
;
    popad
    pop es
    pop ds
    retf32
delete_env_sel    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:       INIT
;
;       DESCRIPTION:    Init module
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_env

init_env    PROC near
    mov eax,4000h
    AllocateGlobalMem
;
    xor di,di
    mov ax,system_data_sel
    mov ds,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters
    
init_device_loop:
    mov edx,[bx].adapter_base
    call load_adapter_env
    add bx,SIZE adapter_typ
    loop init_device_loop   
;
    xor al,al
    stosb
    stosb
    stosb
;
    mov dx,es
    mov bx,SEG data
    mov ds,bx
    InitSection ds:env_sys_section
    mov ds:env_sys_raw_sel,dx
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET delete_handle
    mov ax,ENV_HANDLE
    RegisterHandle
;
    mov esi,OFFSET create_env_sel
    mov edi,OFFSET create_env_sel_name
    xor cl,cl
    mov ax,create_env_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET delete_env_sel
    mov edi,OFFSET delete_env_sel_name
    xor cl,cl
    mov ax,delete_env_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET clone_env_sel
    mov edi,OFFSET clone_env_sel_name
    xor cl,cl
    mov ax,clone_env_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET lock_sys_env
    mov edi,OFFSET lock_sys_env_name
    xor cl,cl
    mov ax,lock_sys_env_nr
    RegisterOsGate
;
    mov esi,OFFSET unlock_sys_env
    mov edi,OFFSET unlock_sys_env_name
    xor cl,cl
    mov ax,unlock_sys_env_nr
    RegisterOsGate
;
    mov esi,OFFSET lock_proc_env
    mov edi,OFFSET lock_proc_env_name
    xor cl,cl
    mov ax,lock_proc_env_nr
    RegisterOsGate
;
    mov esi,OFFSET unlock_proc_env
    mov edi,OFFSET unlock_proc_env_name
    xor cl,cl
    mov ax,unlock_proc_env_nr
    RegisterOsGate
;
    mov esi,OFFSET add_sys_env_var
    mov edi,OFFSET add_sys_env_var_name
    xor cl,cl
    mov ax,add_sys_env_var_nr
    RegisterOsGate
;
    mov esi,OFFSET delete_sys_env_var
    mov edi,OFFSET delete_sys_env_var_name
    xor cl,cl
    mov ax,delete_sys_env_var_nr
    RegisterOsGate
;
    mov esi,OFFSET find_sys_env_var
    mov edi,OFFSET find_sys_env_var_name
    xor cl,cl
    mov ax,find_sys_env_var_nr
    RegisterOsGate
;
    mov esi,OFFSET open_sys_env
    mov edi,OFFSET open_sys_env_name
    xor dx,dx
    mov ax,open_sys_env_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_proc_env
    mov edi,OFFSET open_proc_env_name
    xor dx,dx
    mov ax,open_proc_env_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_env
    mov edi,OFFSET close_env_name
    xor dx,dx
    mov ax,close_env_nr
    RegisterBimodalUserGate
;    
    mov ebx,OFFSET add_env_var16
    mov esi,OFFSET add_env_var32
    mov edi,OFFSET add_env_var_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,add_env_var_nr
    RegisterUserGate
;    
    mov ebx,OFFSET delete_env_var16
    mov esi,OFFSET delete_env_var32
    mov edi,OFFSET delete_env_var_name
    mov dx,virt_ds_in
    mov ax,delete_env_var_nr
    RegisterUserGate
;    
    mov ebx,OFFSET find_env_var16
    mov esi,OFFSET find_env_var32
    mov edi,OFFSET find_env_var_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,find_env_var_nr
    RegisterUserGate
;
    mov esi,OFFSET get_env_size
    mov edi,OFFSET get_env_size_name
    xor dx,dx
    mov ax,get_env_size_nr
    RegisterBimodalUserGate
;    
    mov ebx,OFFSET get_env_data16
    mov esi,OFFSET get_env_data32
    mov edi,OFFSET get_env_data_name
    mov dx,virt_es_in
    mov ax,get_env_data_nr
    RegisterUserGate
;    
    mov ebx,OFFSET set_env_data16
    mov esi,OFFSET set_env_data32
    mov edi,OFFSET set_env_data_name
    mov dx,virt_es_in
    mov ax,set_env_data_nr
    RegisterUserGate
;   
    ret
init_env    ENDP

code    ENDS

    END

