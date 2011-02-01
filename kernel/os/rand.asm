;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2006, Leif Ekblad
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
; RAND.ASM
; Random number generator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def


N = 624
M = 397

random_proc_seg STRUC

mtsect   section_typ <>
mt      DD N DUP(?)
mti     DW ?
    
random_proc_seg ENDS

code    SEGMENT byte public 'CODE'

        .386p

        assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GenArr
;
;               DESCRIPTION:    Generate array
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gen_arr PROC near
    push eax
    push bx
    push cx
    push edx
    push si
    push di
;
    mov cx,N - 1
    mov bx,OFFSET mt
    xor si,si
    mov di,4 * M

gr_loop:
    mov eax,[bx+si]
    and eax,80000000h
    mov edx,[bx+si+4]
    and edx,7FFFFFFFh
    or eax,edx
    mov dl,al
    shr  eax,1
    jnc grno_xor
;
    xor eax,9908B0DFh

grno_xor:
    xor eax,[bx+di]
    mov [bx+si],eax
;
    add si,4
    add di,4
    sub cx,1
    or cx,cx
    jz grok
;    
    cmp di,4 * N
    jb gr_loop
;
    sub di,4 * N
    jmp gr_loop

grok:
    mov ds:mti,0
;    
    pop di
    pop si
    pop edx
    pop cx
    pop bx
    pop eax
    ret
gen_arr Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetRandom
;
;               DESCRIPTION:    Get random number
;
;       RETURNS:        EAX     Number
;
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_random_name    DB 'Get Random Number', 0

get_random      PROC far
    push ds
    push bx
    push edx
;    
    mov bx,random_proc_sel
    mov ds,bx
        EnterSection ds:mtsect
;
    mov bx,ds:mti
    cmp bx,4 * N
    jb get_random_do
;
    call gen_arr
    xor bx,bx

get_random_do:
    mov eax,ds:[bx].mt
    add bx,4
    mov ds:mti,bx
;
    mov edx,eax
    shr edx,11
    xor eax,edx
;    
    mov edx,eax
    shl edx,7
    and edx,9D2C5680h
    xor eax,edx
;
    mov edx,eax
    shl edx,15
    and edx,0EFC60000h
    xor eax,edx
;
    mov edx,eax
    shr edx,18
    xor eax,edx
;
        LeaveSection ds:mtsect
    pop edx
    pop bx
    pop ds    
    retf32
get_random    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   INIT_PROCESS
;
;               DESCRIPTION:    Init random process
;
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public init_process

init_process    PROC far
    push ds
    pushad
;
    mov bx,random_proc_sel
    mov ds,bx
;    
    GetTime
    mov si,OFFSET mt
    mov [si],eax
;
    add si,4
    mul edx
    inc eax
    mov [si],eax
;    
    mov ecx,2

init_genrand_loop:
    mov edx,eax
    shr edx,30
    xor eax,edx
    mov edx,1812433253
    mul edx
    add eax,ecx
    add si,4
    mov [si],eax
    inc ecx
    cmp ecx,N
    jb init_genrand_loop    
;
    shl ecx,2
    mov ds:mti,cx
        InitSection ds:mtsect
;
    popad
    pop ds
    ret
init_process    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   INIT_RANDOM
;
;               DESCRIPTION:    Init random module
;
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public init_random

init_random     PROC near
        push ds
        push es
        pusha
;
        mov bx,random_proc_sel
        mov eax,SIZE random_proc_seg
        AllocateFixedProcessMem
;
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov di,OFFSET init_process
        HookCreateProcess
;
        mov esi,OFFSET get_random
        mov edi,OFFSET get_random_name
        xor dx,dx
        mov ax,get_random_nr
        RegisterBimodalUserGateNew
;
        popa
        pop es
        pop ds
        ret
init_random     ENDP

code    ENDS

        END

