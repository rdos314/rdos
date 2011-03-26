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
; SWAP.ASM
; Memory swap module 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.inc

swap_data_seg   STRUC

swap_level      DB ?
swap_hooks          DB ?

swap_arr            DD 2*32 DUP(?)

swap_data_seg   ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RegisterSwapProc
;
;           DESCRIPTION:    Register a new swap-callback
;
;           PARAMETERS:     ES:EDI   Callback address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_swap_proc_name         DB 'Register Swap Proc',0

register_swap_proc      PROC far
    push ds
    push ax
    push bx
;
    mov ax,swap_data_sel
    mov ds,ax
    mov al,ds:swap_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET swap_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:swap_hooks,al
;
    pop bx
    pop ax
    pop ds
    retf32
register_swap_proc      ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           run_hooks
;
;           DESCRIPTION:    Run hooks
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_hooks       Proc near
    mov ax,swap_data_sel
    mov ds,ax
    mov cl,ds:swap_hooks
    or cl,cl
    je run_hooks_done
;
    mov bx,OFFSET swap_arr

run_hooks_loop:
    push ds
    push bx
    push cx
;
    mov al,ds:swap_level    
    call fword ptr [bx]
;       
    pop cx
    pop bx
    pop ds
    add bx,8
    dec cl
    jnz run_hooks_loop

run_hooks_done:
    ret
run_hooks       Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           swap_thread
;
;           DESCRIPTION:    swap thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_name   DB 'Swap', 0

swap_pr:
    int 3

swap_loop:
    mov bx,swap_data_sel
    mov ds,bx
    mov ds:swap_level,0
    call run_hooks
    mov eax,10
    WaitMilliSec
    jmp swap_loop

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_swap_thread
;
;           DESCRIPTION:    Init swap thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_swap_thread    PROC far
    push ds
    push es
    pusha
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET swap_pr
    mov di,OFFSET swap_name
    mov cx,256
    mov ax,3
;       CreateThread
;
    popa
    pop es
    pop ds
    retf32
init_swap_thread    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init_swap
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_swap
    
init_swap       PROC near
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_swap_thread
    HookInitTasking
;
    mov esi,OFFSET register_swap_proc
    mov edi,OFFSET register_swap_proc_name
    xor cl,cl
    mov ax,register_swap_proc_nr
    RegisterOsGate
;
    mov bx,swap_data_sel
    mov eax,SIZE swap_data_seg
    AllocateFixedSystemMem
    mov ds,bx
    mov ds:swap_hooks,0
;
    popad
    pop es
    pop ds
    ret
init_swap       ENDP

code    ENDS

    END
