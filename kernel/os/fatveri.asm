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
INCLUDE blk.inc
INCLUDE ..\hint.inc
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

