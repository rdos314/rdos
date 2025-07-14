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
; FATVERI.ASM
; Cluster verification for FAT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\fs.inc
INCLUDE fat.inc

        .386p

code    SEGMENT byte public use16 'CODE'

    extrn allocate_cluster_no_verify:near
    extrn bad_cluster:near

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ALLOCATE_CLUSTER
;
;               DESCRIPTION:    Allocate & verify cluster
;
;               PARAMETERS:             AL                      Drive #
;
;               RETURNS:                EDX                     Cluster #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public allocate_cluster

allocate_cluster        PROC near

acRetry:
        call allocate_cluster_no_verify
;       jc acDone       ; remore to deactivate test
        jmp acDone      ; remove to activiate test
;
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;    
    push ax
        sub edx,2
        mov eax,1
        mov cl,ds:fat_cluster_shift
        shl edx,cl
        shl eax,cl
        mov ecx,eax
        add edx,ds:start_sector
;
    push edx
    mov eax,ecx
    shl eax,2
    AllocateSmallLinear
    mov ebp,edx
    pop edx
    pop ax
;        
    push ecx    

acVeriWrite:
    LockSector
    jc acVeriFailPop
;
    push ax
    push ecx    
    mov edi,esi
    mov ecx,80h
    xor eax,eax
    stos dword ptr es:[edi]
;    
    ModifySector
    FlushSector
    mov es:[ebp],ebx
    add ebp,4
    inc edx
    pop ecx
    pop ax
    loop acVeriWrite
;    
    pop ecx
    push ecx

acVeriWait:
    dec edx
    sub ebp,4
    mov ebx,es:[ebp]
    WaitForSector
    UnlockSector
    loop acVeriWait
;
    pop ecx
;    
    push ecx
    push edx
    mov edx,ebp
    shl ecx,2
    FreeLinear
    pop edx
    pop ecx

acVeriLock:        
    LockSector
    jc acVeriDone
;
    UnlockSector
    loop acVeriLock
;
    clc
    jmp acVeriDone

acVeriFailPop:
    pop ecx

acVeriDone:        
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    jnc acDone
;
    call bad_cluster
    jmp acRetry    
       
acDone: 
        ret
allocate_cluster        Endp

code    ENDS

        END

