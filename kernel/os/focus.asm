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
; FOCUS.ASM
; Virtual console handling
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc

focus_process_seg   STRUC

fp_key          DB ?

focus_process_seg   ENDS

data    SEGMENT byte public 'DATA'

focus_thread            DW 256 DUP(?)

focus_current_thread    DW ?
focus_section           section_typ <>
focus_switched          DB ?

focus_alloc_rel         DD ?

enable_focus_hooks      DB ?
lost_focus_hooks        DB ?
got_focus_hooks         DB ?

enable_focus_arr        DD 2*16 DUP(?)
lost_focus_arr          DD 2*16 DUP(?)
got_focus_arr           DD 2*16 DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetFocusThread
;
;           DESCRIPTION:    Get focus thread
;
;           RETURNS:        AX          Focus thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_focus_thread_name   DB 'Get Focus Thread',0

get_focus_thread    PROC far
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:focus_current_thread
    pop ds
    retf32
get_focus_thread    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetThreadFocusKey
;
;           DESCRIPTION:    Get thread switch key
;
;           PARAMETERS:         BX          Thread
;
;           RETURNS:        AL          Switch key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_focus_key_name       DB 'Get Thread Focus Key',0

get_thread_focus_key    PROC far
    push ds
    push cx
    push si
;
    mov ax,SEG data
    mov ds,ax
    mov cx,256
    mov si,OFFSET focus_thread

get_thread_key_loop:
    cmp bx,[si]
    je get_thread_key_ok
;
    add si,2
    loop get_thread_key_loop
;
    xor ax,ax
    stc
    jmp get_thread_key_done

get_thread_key_ok:
    mov ax,si
    sub ax,OFFSET focus_thread
    shr ax,1
    clc

get_thread_key_done:
    pop si
    pop cx
    pop ds
    retf32
get_thread_focus_key    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_FOCUS_LINEAR
;
;           DESCRIPTION:    Allocate focus memory
;
;           PARAMETERS:         EAX         Bytes
;
;           RETURNS:        EDX         Focus fixed address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_focus_linear_name      DB 'Allocate Focus Linear',0

allocate_focus_linear   PROC far
    push ds
    mov dx,SEG data
    mov ds,dx
    mov edx,ds:focus_alloc_rel
    add ds:focus_alloc_rel,eax
    pop ds
    retf32
allocate_focus_linear   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_FIXED_FOCUS_MEM
;
;           DESCRIPTION:    Allocate focus selector
;
;           PARAMETERS:         EAX         Bytes
;
;           RETURNS:        BX          Local selector
;                           DX          Focus selector
;                           ES          Local selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_focus_mem_name   DB 'Allocate Fixed Focus Mem',0

allocate_fixed_focus_mem    PROC far
    push ds
    push eax
    push ecx
    push edx
;
    push bx
    push dx
    AllocateFocusLinear
    mov ecx,eax
    push edx
    add edx,io_local_linear
    CreateDataSelector16
    pop edx
;
    add edx,io_focus_linear
    pop bx
    CreateDataSelector16
    pop bx
    mov es,bx
;
    pop edx
    pop ecx
    pop eax
    pop ds
    retf32
allocate_fixed_focus_mem    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Free_thread
;
;           DESCRIPTION:    Handle thread termination
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_thread     Proc far
    mov bx,SEG data
    mov ds,bx
    mov bx,OFFSET focus_thread
    mov cx,100h
    GetThread

free_thread_loop:
    cmp ax,[bx]
    jne free_thread_next
;
    mov word ptr [bx],0
    cmp ax,ds:focus_current_thread
    jne free_thread_done
;
    mov ds:focus_switched,0
    mov ds:focus_current_thread,0
    jmp free_thread_done

free_thread_next:
    add bx,2
    loop free_thread_loop

free_thread_done:
    retf32
free_thread     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_FOCUS_PROCESS
;
;           DESCRIPTION:    Init per-process data
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_focus_process      Proc far
    push ds
    push eax
    push ebx
    push cx
    push edx
;
    mov ax,focus_process_sel
    mov ds,ax
    mov ds:fp_key,0
;       
    mov edx,io_local_linear
    mov cx,400h
    xor eax,eax
    xor ebx,ebx
    
init_local_loop:
    SetPhysicalPage
    add edx,1000h
    loop init_local_loop    
;
    pop edx
    pop cx
    pop ebx
    pop eax
    pop ds
    retf32
init_focus_process      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FREE_FOCUS_PROCESS
;
;           DESCRIPTION:    Free per-process data
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_focus_process      Proc far
    push eax
    push ebx
    push cx
    push edx
;
    mov edx,io_local_linear
    mov cx,400h

free_local_loop:
    GetPhysicalPage
    or eax,eax
    jz free_local_next
;
    FreePhysical

free_local_next:
    add edx,1000h
    loop free_local_loop    
;
    pop edx
    pop cx
    pop ebx
    pop eax
    retf32
free_focus_process      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_ENABLE_FOCUS
;
;           DESCRIPTION:    Run hooks for EnableFocus
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_enable_focus       PROC near
    mov ax,SEG data
    mov ds,ax
    mov cl,ds:enable_focus_hooks
    or cl,cl
    je trap_enable_focus_done
    mov bx,OFFSET enable_focus_arr
trap_enable_focus_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_enable_focus_loop
trap_enable_focus_done:
    ret
trap_enable_focus       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_LOST_FOCUS
;
;           DESCRIPTION:    Run hooks for LostFocus (before the switch)
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_lost_focus PROC near
    mov cl,ds:lost_focus_hooks
    or cl,cl
    je trap_lost_focus_done
    mov bx,OFFSET lost_focus_arr
trap_lost_focus_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_lost_focus_loop
trap_lost_focus_done:
    ret
trap_lost_focus ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRAP_GOT_FOCUS
;
;           DESCRIPTION:    Run hooks for GotFocus (after the switch)
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_got_focus  PROC near
    mov cl,ds:got_focus_hooks
    or cl,cl
    je trap_got_focus_done
    mov bx,OFFSET got_focus_arr
trap_got_focus_loop:
    push ds
    push bx
    push cx
    call fword ptr [bx]
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz trap_got_focus_loop
trap_got_focus_done:
    ret
trap_got_focus  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_ENABLE_FOCUS
;
;           DESCRIPTION:    Add hook for EnableFocus
;
;           PARAMETERS:     ES:EDI       CALLBACK ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_enable_focus_name  DB 'Hook Enable Focus',0

hook_enable_focus       PROC far
    push ds
    push ax
    push bx
    mov ax,SEG data
    mov ds,ax
    mov al,ds:enable_focus_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET enable_focus_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:enable_focus_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_enable_focus       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_LOST_FOCUS
;
;           DESCRIPTION:    Add hook for LostFocus
;
;           PARAMETERS:     ES:EDI       CALLBACK ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_lost_focus_name    DB 'Hook Lost Focus',0

hook_lost_focus PROC far
    push ds
    push ax
    push bx
    mov ax,SEG data
    mov ds,ax
    mov al,ds:lost_focus_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET lost_focus_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:lost_focus_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_lost_focus ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_GOT_FOCUS
;
;           DESCRIPTION:    Add hook for GotFocus
;
;           PARAMETERS:     ES:EDI       CALLBACK ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_got_focus_name     DB 'Hook Got Focus',0

hook_got_focus  PROC far
    push ds
    push ax
    push bx
    mov ax,SEG data
    mov ds,ax
    mov al,ds:got_focus_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET got_focus_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:got_focus_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_got_focus  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_FOCUS
;
;           DESCRIPTION:    Set input focus
;
;           PARAMETERS:         AL      KEY NUMBER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_focus_name  DB 'Set Focus',0

set_focus       PROC far
    push ds
    push es
    pushad
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:focus_section
    xor bh,bh
    mov bl,al
    add bx,bx
    mov ax,ds:[bx].focus_thread
    or ax,ax
    jz set_focus_done
    mov bx,ax
    cmp ds:focus_switched,0
    jz set_focus_no_lost
    push bx
    call trap_lost_focus
    pop bx
set_focus_no_lost:
    mov ds:focus_switched,1
    mov ds:focus_current_thread,bx
    mov ds,bx
;    
    LockTask
    mov eax,cr3
    push eax
    mov eax,ds:p_cr3
    mov bx,process_dir_sel
    mov ds,bx
    mov ebx,io_local_linear
    shr ebx,20
    cli
    mov cr3,eax
    mov edx,[bx]
    pop eax
    mov cr3,eax
    sti
    mov ebx,io_focus_linear
    shr ebx,20
    mov [bx],edx
    mov ax,sys_dir_sel
    mov ds,ax
    mov [bx],edx
    UnlockTask
;
    mov bx,SEG data
    mov ds,bx
    call trap_got_focus
set_focus_done:
    LeaveSection ds:focus_section
    popad
    pop es
    pop ds
    retf32
set_focus       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ENABLE_FOCUS
;
;           DESCRIPTION:    Enable focus
;
;           PARAMETERS:         AL      KEY NUMBER
;
;       RETURNS:    Actual key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_focus_name       DB 'Enable Focus',0

enable_focus    PROC far
    push ds
    push es
    push bx
;
    mov bx,SEG data
    mov ds,bx
    xor bh,bh
    mov bl,al
    GetThread
    add bx,bx

enable_focus_loop:
    cmp ds:[bx].focus_thread,0
    jne enable_focus_next
;
    mov ds:[bx].focus_thread,ax
    jmp enable_focus_done

enable_focus_next:
    add bx,2
    cmp bx,200h
    jne enable_focus_loop

enable_focus_done:
    pushad
    call trap_enable_focus
    popad
;
    mov ax,bx
    shr ax,1
;       
    mov bx,focus_process_sel
    mov ds,bx
    mov ds:fp_key,al
;
    pop bx
    pop es
    pop ds
    retf32
enable_focus    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_FOCUS
;
;           DESCRIPTION:    Get input focus key
;
;           RETURN:         AL      KEY NUMBER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_focus_name  DB 'Get Focus',0

get_focus       PROC far
    push ds
    mov ax,focus_process_sel
    mov ds,ax
    mov al,ds:fp_key
    pop ds
    retf32
get_focus   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init driver
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_focus
    
init_focus      PROC near
    mov bx,video_mem_focus_sel
    mov edx,video_mem_focus_linear
    mov ecx,100000h
    CreateDataSelector16
;
    mov bx,video_mem_local_sel
    mov edx,video_mem_local_linear
    mov ecx,100000h
    CreateDataSelector16
;
    mov bx,video_focus_sel
    mov edx,video_focus_linear
    mov ecx,20000h
    CreateDataSelector16
;
    mov bx,video_local_sel
    mov edx,video_local_linear
    mov ecx,20000h
    CreateDataSelector16
;
    mov bx,SEG data
    mov es,bx
    mov ds,bx
    mov di,OFFSET focus_thread
    mov cx,256
    xor ax,ax
    rep stosw
    mov ds:lost_focus_hooks,0
    mov ds:got_focus_hooks,0
    mov ds:enable_focus_hooks,0
    mov ds:focus_switched,0
    mov ds:focus_alloc_rel,0
    mov ds:focus_current_thread,0
    InitSection ds:focus_section
;       
    mov bx,focus_process_sel
    mov eax,SIZE focus_process_seg
    AllocateFixedProcessMem
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_focus_process
    HookCreateProcess
;
    mov edi,OFFSET free_focus_process
    HookTerminateProcess
;
    mov edi,OFFSET free_thread
    HookTerminateThread
;
    mov esi,OFFSET set_focus
    mov edi,OFFSET set_focus_name
    xor dx,dx
    mov ax,set_focus_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_focus
    mov edi,OFFSET get_focus_name
    xor dx,dx
    mov ax,get_focus_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET enable_focus
    mov edi,OFFSET enable_focus_name
    xor dx,dx
    mov ax,enable_focus_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET hook_enable_focus
    mov edi,OFFSET hook_enable_focus_name
    xor cl,cl
    mov ax,hook_enable_focus_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_lost_focus
    mov edi,OFFSET hook_lost_focus_name
    xor cl,cl
    mov ax,hook_lost_focus_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_got_focus
    mov edi,OFFSET hook_got_focus_name
    xor cl,cl
    mov ax,hook_got_focus_nr
    RegisterOsGate
;
    mov esi,OFFSET get_focus_thread
    mov edi,OFFSET get_focus_thread_name
    xor cl,cl
    mov ax,get_focus_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET get_thread_focus_key
    mov edi,OFFSET get_thread_focus_key_name
    xor cl,cl
    mov ax,get_thread_focus_key_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_focus_linear
    mov edi,OFFSET allocate_focus_linear_name
    xor cl,cl
    mov ax,allocate_focus_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_fixed_focus_mem
    mov edi,OFFSET allocate_fixed_focus_mem_name
    xor cl,cl
    mov ax,allocate_fixed_focus_mem_nr
    RegisterOsGate
    ret
init_focus      ENDP

code    ENDS

END

