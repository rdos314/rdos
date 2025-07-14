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
; RAND.ASM
; Random number generator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
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
uuid_nr DW ?
    
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
;       NAME:           CreateUuid
;
;       DESCRIPTION:    Create UUID
;
;       PARAMETERS:     ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_uuid_name    DB 'Create UUID', 0

create_uuid Proc near
    push ds
    push eax
    push edx
    push esi
;    
    mov ax,random_proc_sel
    mov ds,ax
;
    GetSystemTime
    stos dword ptr es:[edi]
    mov eax,edx
    stos word ptr es:[edi]
;
    ror eax,16
    and ah,0Fh
    or ah,10h
    stos word ptr es:[edi]
;
    EnterSection ds:mtsect
    mov ax,ds:uuid_nr
    inc ax
    mov ds:uuid_nr,ax
    LeaveSection ds:mtsect    
;
    and ah,1Fh
    or ah,80h
    xchg al,ah
    stos byte ptr es:[edi]
    xchg al,ah
    stos byte ptr es:[edi]
;
    UserGateForce32 get_mac_address_nr
    jnc cuDone
;
    GetRandom
    stos dword ptr es:[edi]
;
    GetRandom
    stos word ptr es:[edi]

cuDone:
    pop esi
    pop edx
    pop eax
    pop ds
    ret
create_uuid Endp    

create_uuid32   Proc far
    push edi
    call create_uuid
    pop edi
    retf32
create_uuid32   Endp

create_uuid16   Proc far
    push edi
    movzx edi,di
    call create_uuid
    pop edi
    retf32
create_uuid16   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   INIT_PROCESS
;
;               DESCRIPTION:    Init random process
;
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    retf32
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
    mov edi,OFFSET init_process
    HookCreateProcess
;
    mov esi,OFFSET get_random
    mov edi,OFFSET get_random_name
    xor dx,dx
    mov ax,get_random_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET create_uuid16
    mov esi,OFFSET create_uuid32
    mov edi,OFFSET create_uuid_name
    mov dx,virt_es_in
    mov ax,create_uuid_nr
    RegisterUserGate
;
    popa
    pop es
    pop ds
    ret
init_random     ENDP

code    ENDS

        END

