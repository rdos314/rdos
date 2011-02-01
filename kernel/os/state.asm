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
; STATE.ASM
; Thread state interface module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE state.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE system.inc

state_data_seg  STRUC

state_hooks             DW ?
state_arr               DW 2*32 DUP(?)

state_data_size DB ?

state_data_seg  ENDS

code    SEGMENT byte public 'CODE'

.386p

        assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   DEFAULT_STATE
;
;               DESCRIPTION:    Default (unknown) state
;
;               PARAMETERS:             BX          Thread selector
;                       ES:EDI      Buffer
;
;       RETURNS:                NC              processed
;                       CX:EDX      List
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unknown_state   DB 'Unknown State',0

default_state   Proc far
    push ds
    push ax
    push si
;    
    mov si,OFFSET unknown_state

default_copy:
    mov al,cs:[si]
    or al,al
    jz default_copy_done
;
    inc si
    stos byte ptr es:[edi]
    jmp default_copy

default_copy_done:
    xor al,al
    stos byte ptr es:[edi]
;
    mov ds,bx
    mov ds,ds:p_tss_data_sel
    mov cx,ds:tss_cs
    mov edx,dword ptr ds:tss_eip
    clc
;
    pop si
    pop ax
    pop ds
        ret
default_state   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   HOOK_STATE
;
;               DESCRIPTION:    Add a state hook
;
;               PARAMETERS:             ES:DI           Callback
;
;               CALLED WITH:    BX          Thread selector
;                       ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_state_name DB 'Hook State',0

hook_state      Proc far
        push ds
        push bx
        mov bx,state_data_sel
        mov ds,bx
        mov bx,ds:state_hooks
        shl bx,2
        mov ds:[bx].state_arr,di
        mov ds:[bx+2].state_arr,es
        inc ds:state_hooks
        pop ax
        pop ds
        ret
hook_state      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ThreadToSel
;
;               DESCRIPTION:    Convert thread # (p_id) to selector
;
;               PARAMETERS:     BX      Thread #
;
;       RETURNS:        BX      Thread sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

thread_to_sel_name DB 'Thread To Sel',0

thread_to_sel   Proc far
    push ds
    push es
    push ax
    push cx
    push si
;    
    mov cx,256
        mov ax,system_data_sel
        mov ds,ax
        xor si,si

thread_to_sel_loop:
        mov ax,ds:[si].thread_arr
        or ax,ax
        jz thread_to_sel_next
;
    mov es,ax   
    cmp bx,es:p_id
    je thread_to_sel_found

thread_to_sel_next:
    add si,2
    loop thread_to_sel_loop
;
    xor bx,bx
    stc    
    jmp thread_to_sel_done        

thread_to_sel_found:
    mov bx,es
    clc

thread_to_sel_done:
    pop si
    pop cx
    pop ax
    pop es
    pop ds    
        ret
thread_to_sel   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetThreadState
;
;               DESCRIPTION:    Get state of a thread
;
;               PARAMETERS:             ES:(E)DI                BUFFER TO PUT STATE IN
;                                               AX                              THREAD #
;                                               NC                              THREAD EXISTS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_state_name DB 'Get Thread State',0

get_thread_state        Proc far
        push ds
        push eax
        push ebx
        push ecx
        push edx
        push esi
        push edi
        mov bx,ax
        shl bx,1
        mov ax,system_data_sel
        mov ds,ax
        cli
        mov ax,ds:[bx].thread_arr
        or ax,ax
        stc
        jz get_state_done
;
        mov ds,ax
        mov ax,ds:p_id
        mov es:[edi].st_id,ax
        mov esi,OFFSET thread_name
        mov ecx,32
        push edi
        add edi,OFFSET st_name
        rep movs byte ptr es:[edi],ds:[esi]
        pop edi
;       
        mov eax,ds:p_msb_tics
        mov es:[edi].st_time,eax
        mov eax,ds:p_lsb_tics
        mov es:[edi].st_time+4,eax
;
    push edi
        add edi,OFFSET st_list
    mov bx,ds
;    
        sti
        mov ax,state_data_sel
        mov ds,ax
        mov si,OFFSET state_arr
        
get_state_loop:
        call dword ptr [si]
        jnc get_state_found
;
        add si,4
        jmp get_state_loop

get_state_found:
    pop edi
;
        mov es:[edi].st_sel,cx
        mov es:[edi].st_offs,edx
        clc

get_state_done:
        sti
        pop edi
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        pop ds
        ret
get_thread_state        Endp

get_thread_state16      Proc far
        push edi
        movzx edi,di
        call get_thread_state
        pop edi
        ret
get_thread_state16      Endp

get_thread_state32      Proc far
        call get_thread_state
        Retf32
get_thread_state32      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SuspendThread
;
;               DESCRIPTION:    Suspend thread (put it in debugger)
;
;               PARAMETER:              AX              Thread ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

suspend_thread_name     DB 'Suspend Thread',0

suspend_thread  PROC far
        push ds
        push es
        push ax
        push bx
        push si
;
    mov bx,ax
    mov cx,256
        mov ax,system_data_sel
        mov ds,ax
        xor si,si

suspend_thread_loop:
        mov ax,ds:[si].thread_arr
        or ax,ax
        jz suspend_thread_next
;
    mov es,ax   
    cmp bx,es:p_id
    je suspend_thread_found

suspend_thread_next:
    add si,2
    loop suspend_thread_loop
;
    stc    
    jmp suspend_thread_done        

suspend_thread_found:
    or es:p_flags,THREAD_FLAG_SUSPEND
        clc

suspend_thread_done:
    pop si
        pop bx
        pop ax
        pop es
        pop ds
        retf32
suspend_thread  ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SuspendAndSignalThread
;
;               DESCRIPTION:    Suspend and signal thread (put it in debugger)
;
;               PARAMETER:              AX              Thread #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

suspend_and_signal_thread_name  DB 'Suspend and Signal Thread',0

suspend_and_signal_thread       PROC far
        push ds
        push es
        push ax
        push bx
        push si
;
    mov bx,ax
    mov cx,256
        mov ax,system_data_sel
        mov ds,ax
        xor si,si

suspend_signal_loop:
        mov ax,ds:[si].thread_arr
        or ax,ax
        jz suspend_signal_next
;
    mov es,ax   
    cmp bx,es:p_id
    je suspend_signal_found

suspend_signal_next:
    add si,2
    loop suspend_signal_loop
;
    stc    
    jmp suspend_signal_done        

suspend_signal_found:
    mov bx,es
    or es:p_flags,THREAD_FLAG_SUSPEND
    Signal
        sti
        clc

suspend_signal_done:
    pop si
        pop bx
        pop ax
        pop es
        pop ds
        retf32
suspend_and_signal_thread       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetThreadTss
;
;               DESCRIPTION:    Get thread TSS
;
;               PARAMETERS:             ES:(E)DI                Buffer for TSS
;                                               BX                              Thread handle
;                                               NC                              Thread exists
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_tss_name DB 'Get Thread TSS',0

get_thread_tss  Proc near
        push ds
        push ax
        push dx
        push si
;
        mov ax,system_data_sel
        mov ds,ax
        mov si,OFFSET debug_list
        mov ax,[si]
        or ax,ax
        stc
        jz get_thread_tss_done
;
        mov dx,ax

get_thread_tss_loop:
        mov ds,ax
        cmp bx,ds:p_id
        je get_thread_tss_found
;
        mov ax,ds:p_next
        cmp ax,dx
        jne get_thread_tss_loop
        stc
        jmp get_thread_tss_done

get_thread_tss_found:
    fnop
        push ecx
        push esi
        push edi
        mov ds,ax
        mov ds,ds:p_tss_data_sel
        xor esi,esi
        mov ecx,OFFSET math_st0
        rep movs byte ptr es:[edi],ds:[esi]
;
    mov eax,cr0
    test al,4
    jz get_thread_real_fpu

get_thread_emul_fpu:
        mov ax,ds:math_status
        shr ax,3
        mov al,ah
        and ax,7
        add ax,ax
        mov si,ax
        shl ax,2
        add si,ax
        add si,OFFSET math_st0
        shr ax,3
        mov dx,8

get_thread_emul_loop:
    mov ecx,10
    rep movs byte ptr es:[edi],ds:[esi]
;
    inc al
    cmp al,8
    jne get_thread_emul_next
;
    xor al,al
    mov si,OFFSET math_st0

get_thread_emul_next:
    sub dx,1
    jnz get_thread_emul_loop   
    jmp get_thread_fpu_done

get_thread_real_fpu:
    mov ecx,2 * 10
        rep movs dword ptr es:[edi],ds:[esi]

get_thread_fpu_done:
        pop edi
        pop esi
        pop ecx
        clc

get_thread_tss_done:
        pop si
        pop dx
        pop ax
        pop ds
        ret
get_thread_tss  Endp

get_thread_tss16        Proc far
        push edi
        movzx edi,di
        call get_thread_tss
        pop edi
        ret
get_thread_tss16        Endp

get_thread_tss32        Proc far
        call get_thread_tss
        retf32
get_thread_tss32        Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SetThreadTss
;
;               DESCRIPTION:    Set thread TSS
;
;               PARAMETERS:             ES:(E)DI                Buffer for TSS
;                                               BX                              Thread handle
;                                               NC                              Thread exists
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_thread_tss_name DB 'Set Thread TSS',0

set_thread_tss  Proc near
        push ds
        push ax
        push dx
        push si
;
        mov ax,system_data_sel
        mov ds,ax
        mov si,OFFSET debug_list
        mov ax,[si]
        or ax,ax
        stc
        jz set_thread_tss_done
;
        mov dx,ax

set_thread_tss_loop:
        mov ds,ax
        cmp bx,ds:p_id
        je set_thread_tss_found
;
        mov ax,ds:p_next
        cmp ax,dx
        jne set_thread_tss_loop
        stc
        jmp set_thread_tss_done

set_thread_tss_found:
        push ds
        push es
        push ecx
        push esi
        push edi
        mov cx,es
        mov ds,cx
        mov es,ax
        mov es,es:p_tss_data_sel
        mov esi,edi
        xor edi,edi
        mov ecx,OFFSET math_st0
        rep movs byte ptr es:[edi],ds:[esi]
;
    mov eax,cr0
    test al,4
    jz set_thread_real_fpu

set_thread_emul_fpu:
        mov ax,es:math_status
        shr ax,3
        mov al,ah
        and ax,7
        add ax,ax
        mov di,ax
        shl ax,2
        add di,ax
        add di,OFFSET math_st0
        shr ax,3
        mov dx,8

set_thread_emul_loop:
    mov ecx,10
    rep movs byte ptr es:[edi],ds:[esi]
;
    inc al
    cmp al,8
    jne set_thread_emul_next
;
    xor al,al
    mov di,OFFSET math_st0

set_thread_emul_next:
    sub dx,1
    jnz set_thread_emul_loop   
    jmp set_thread_fpu_done

set_thread_real_fpu:
    mov ecx,2 * 10
        rep movs dword ptr es:[edi],ds:[esi]

set_thread_fpu_done:
        pop edi
        pop esi
        pop ecx
        pop es
        pop ds
        clc

set_thread_tss_done:
        pop si
        pop dx
        pop ax
        pop ds
        ret
set_thread_tss  Endp

set_thread_tss16        Proc far
        push edi
        movzx edi,di
        call set_thread_tss
        pop edi
        ret
set_thread_tss16        Endp

set_thread_tss32        Proc far
        call set_thread_tss
        retf32
set_thread_tss32        Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   Init
;
;               DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public init_state

init_state      PROC near
        push ds
        push es
        pusha
;
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov esi,OFFSET hook_state
        mov edi,OFFSET hook_state_name
        xor cl,cl
        mov ax,hook_state_nr
        RegisterOsGate
;
        mov esi,OFFSET thread_to_sel
        mov edi,OFFSET thread_to_sel_name
        xor cl,cl
        mov ax,thread_to_sel_nr
        RegisterOsGate
;
        mov ebx,OFFSET get_thread_state16
        mov esi,OFFSET get_thread_state32
        mov edi,OFFSET get_thread_state_name
        mov dx,virt_es_in
        mov ax,get_thread_state_nr
        RegisterUserGateNew
;
        mov ebx,OFFSET get_thread_tss16
        mov esi,OFFSET get_thread_tss32
        mov edi,OFFSET get_thread_tss_name
        mov dx,virt_es_in
        mov ax,get_thread_tss_nr
        RegisterUserGateNew
;
        mov ebx,OFFSET set_thread_tss16
        mov esi,OFFSET set_thread_tss32
        mov edi,OFFSET set_thread_tss_name
        mov dx,virt_es_in
        mov ax,set_thread_tss_nr
        RegisterUserGateNew
;
        mov esi,OFFSET suspend_thread
        mov edi,OFFSET suspend_thread_name
        xor dx,dx
        mov ax,suspend_thread_nr
        RegisterBimodalUserGateNew
;
        mov esi,OFFSET suspend_and_signal_thread
        mov edi,OFFSET suspend_and_signal_thread_name
        xor dx,dx
        mov ax,suspend_and_signal_thread_nr
        RegisterBimodalUserGateNew
;
        mov eax,OFFSET state_data_size
        mov bx,state_data_sel
        AllocateFixedSystemMem
        mov es:state_hooks,0
        mov cx,32
        mov di,OFFSET state_arr
init_state_hooks:
        mov word ptr es:[di],OFFSET default_state
        mov es:[di+2],cs
        add di,4
        loop init_state_hooks
;
    mov ax,system_data_sel
    mov es,ax
    mov di,OFFSET thread_arr
    xor ax,ax
    mov cx,256
    rep stosw
;
        popa
        pop es
        pop ds
        ret
init_state      ENDP

code    ENDS

        END
