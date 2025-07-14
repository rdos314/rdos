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
