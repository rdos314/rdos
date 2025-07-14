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
; CPU.ASM
; CPU properties module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def

        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetCpuVersion
;
;               DESCRIPTION:    Get CPU version
;
;               PARAMETERS:         ES:(E)DI)     CPU vendor string buffer
;
;       RETURNS:        AL            CPU version
;                       EBX           CPU frequency
;                       EDX           Feature flags
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cpu_version_name DB 'Get Cpu Version', 0

get_cpu_version Proc near
    push ds
    push ecx
    push esi
    push edi
;    
    mov ax,system_data_sel
    mov ds,ax
;    
    xor ebx,ebx
    test ds:cpu_feature_flags, 10h
    jz gcvFreqOk
;    
    mov edx,10000h
    xor eax,eax
    mov ecx,ds:sys_tsc_tics
    shl ecx,16
    mov cx,ds:sys_tsc_rest
    div ecx    
;
    mov ecx,1193182
    movzx eax,ds:sys_tsc_rest
    shl eax,16
    mul ecx
    mov esi,edx
;    
    mov eax,ds:sys_tsc_tics
    mul ecx
    add eax,esi
    adc edx,0    
    add eax,1000000
    adc edx,0
;
    mov ecx,2000000
    div ecx
    mov ebx,eax

gcvFreqOk:    
    mov ecx,13
    mov esi,OFFSET cpu_vendor
    rep movs byte ptr es:[edi],ds:[esi]
;    
    mov al,ds:cpu_type
    mov edx,ds:cpu_feature_flags
;
    pop edi
    pop esi
    pop ecx
    pop ds
    ret
get_cpu_version Endp

get_cpu_version16   Proc far
    push edi
    movzx edi,di
    call get_cpu_version
    pop esi
    retf32
get_cpu_version16   Endp

get_cpu_version32   Proc far
    call get_cpu_version
    retf32
get_cpu_version32   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   InitCpuGates
;
;               DESCRIPTION:    Init cpu module call-gates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_cpu_gates
    
init_cpu_gates  PROC near
    push ds
    push es
    pusha
;    
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov ebx,OFFSET get_cpu_version16
        mov esi,OFFSET get_cpu_version32
        mov edi,OFFSET get_cpu_version_name
        mov dx,virt_es_in
        mov ax,get_cpu_version_nr
        RegisterUserGate
;
    popa
    pop es
    pop ds      
        ret
init_cpu_gates  ENDP


code    ENDS

        END
