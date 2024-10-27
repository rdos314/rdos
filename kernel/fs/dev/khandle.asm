;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2017, Leif Ekblad
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
; KHANDLE.ASM
; Kernel handle module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
include ..\wait.inc
INCLUDE ..\driver.def
INCLUDE ..\os\exec.def
INCLUDE vfs.inc

    .386p

MAX_KERNEL_HANDLES    = 64

;
; this should always be 4 bytes!
;

kernel_handle_struc    STRUC

kh_legacy_sel        DW ?
kh_vfs_sel           DW ?

kernel_handle_struc    ENDS

data    SEGMENT byte public 'DATA'

hd_section       section_typ <>

hd_kernel_arr    DD MAX_KERNEL_HANDLES DUP(?)

data       ENDS

code    SEGMENT byte public 'CODE'
    
    assume cs:code

    extern allocate_proc_handle:near

    extern OpenKernelVfsFile:near
    extern CloseKernelVfsFile:near
    extern ReadKernelVfsFile:near
    extern WriteKernelVfsFile:near
    extern DupKernelVfsFile:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenKernelHandle
;
;           DESCRIPTION:    Open kernel handle
;
;           PARAMETERS:     ES:EDI    Filename
;                           CX        Mode
;
;           RETURNS:        BX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_kernel_handle_name DB 'Open Kernel Handle', 0

open_kernel_handle Proc far
    push ds
    push eax
    push ecx
    push edi
;
    call OpenKernelVfsFile
    jnc okhVfs
;
    OpenLegacyKernelFile
    jc okhDone
;
    movzx ebx,bx
    jmp okhHandle

okhVfs:
    shl ebx,16
    xor bx,bx

okhHandle:
    mov ax,SEG data
    mov ds,eax
    EnterSection ds:hd_section
;
    mov ecx,MAX_KERNEL_HANDLES  
    mov edi,OFFSET hd_kernel_arr

okhLoop:
    mov eax,ds:[edi]
    or eax,eax
    jnz okhNext
;
    mov ds:[edi],ebx
    mov ebx,edi
    sub ebx,OFFSET hd_kernel_arr
    shr ebx,2
    inc ebx
    clc
    jmp okhLeave

okhNext:
    add edi,4
    loop okhLoop
;
    int 3
    stc

okhLeave:
    LeaveSection ds:hd_section

okhDone:
    pop edi
    pop ecx
    pop eax
    pop ds
    ret
open_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseKernelHandle
;
;           DESCRIPTION:    Close kernel handle
;
;           PARAMETERS:     BX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_kernel_handle_name DB 'Close Kernel Handle', 0

close_kernel_handle Proc far
    push ds
    push eax
    push edi
;
    or bx,bx
    jz ckhDone
;
    cmp bx,MAX_KERNEL_HANDLES
    ja ckhDone
;
    movzx edi,bx
    dec edi
    shl edi,2
    add edi,OFFSET hd_kernel_arr
;
    mov ax,SEG data
    mov ds,eax
    EnterSection ds:hd_section
    xor bx,bx
    xchg bx,ds:[edi].kh_legacy_sel
    or bx,bx
    jz ckhVfs
;
    CloseLegacyFile
    jmp ckhLeave

ckhVfs:
    xchg bx,ds:[edi].kh_vfs_sel
    or bx,bx
    jz ckhLeave
;
    call CloseKernelVfsFile
    
ckhLeave:
    LeaveSection ds:hd_section

ckhDone:
    xor bx,bx
;
    pop edi
    pop eax
    pop ds
    ret
close_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadKernelHandle
;
;           DESCRIPTION:    Read with kernel handle
;
;           PARAMETERS:     BX        Handle
;                           EDX:EAX   Position
;                           ES:EDI    Buffer
;                           ECX       Size
;
;           RETURNS:        ECX       Read size
;                           EDX:EAX   New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_kernel_handle_name DB 'Read Kernel Handle', 0

read_kernel_handle Proc far
    push ds
    push ebx
    push esi
;
    or bx,bx
    jz rkhFail
;
    cmp bx,MAX_KERNEL_HANDLES
    ja rkhFail
;
    mov si,SEG data
    mov ds,esi
    movzx esi,bx
    dec esi
    shl esi,2
    add esi,OFFSET hd_kernel_arr
;
    mov bx,ds:[esi].kh_legacy_sel
    or bx,bx
    jz rkhVfs
;
    ReadLegacyFile
    jmp rkhDone

rkhVfs:
    mov bx,ds:[esi].kh_vfs_sel
    or bx,bx
    jz rkhFail
;
    call ReadKernelVfsFile
    jmp rkhDone

rkhFail:
    xor ecx,ecx
    stc

rkhDone:
    pop esi
    pop ebx
    pop ds
    ret
read_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteKernelHandle
;
;           DESCRIPTION:    Write with kernel handle
;
;           PARAMETERS:     BX        Handle
;                           EDX:EAX   Position
;                           ES:EDI    Buffer
;                           ECX       Size
;
;           RETURNS:        ECX       Read size
;                           EDX:EAX   New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_kernel_handle_name DB 'Write Kernel Handle', 0

write_kernel_handle Proc far
    push ds
    push ebx
    push esi
;
    or bx,bx
    jz wkhFail
;
    cmp bx,MAX_KERNEL_HANDLES
    ja wkhFail
;
    mov si,SEG data
    mov ds,esi
    movzx esi,bx
    dec esi
    shl esi,2
    add esi,OFFSET hd_kernel_arr
;
    mov bx,ds:[esi].kh_legacy_sel
    or bx,bx
    jz wkhVfs
;
    WriteLegacyFile
    jmp wkhDone

wkhVfs:
    mov bx,ds:[esi].kh_vfs_sel
    or bx,bx
    jz wkhFail
;
    call WriteKernelVfsFile
    jmp wkhDone

wkhFail:
    xor ecx,ecx
    stc

wkhDone:
    pop esi
    pop ebx
    pop ds
    ret
write_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dupl_kernel_handle
;
;           DESCRIPTION:    Dupl kernel handle
;
;           PARAMETERS:     EBX          File handle entry
;                           
;           RETURNS:        EBX          File handle
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dupl_kernel_handle_name  DB 'Dupl Kernel Handle',0

dupl_kernel_handle    Proc far
    push ds
    push esi
;
    or bx,bx
    jz dupkhFail
;
    cmp bx,MAX_KERNEL_HANDLES
    ja dupkhFail
;
    mov si,SEG data
    mov ds,esi
    movzx esi,bx
    dec esi
    shl esi,2
    add esi,OFFSET hd_kernel_arr
;
    mov bx,ds:[esi].kh_legacy_sel
    or bx,bx
    jnz dupkhLegacy
;
    mov bx,ds:[esi].kh_vfs_sel
    call DupKernelVfsFile
    jmp dupkhDone

dupkhLegacy:
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    RefLegacyKernelFile
;
    mov cx,IO_READ OR IO_WRITE
    xor eax,eax
    xor edx,edx
    call allocate_proc_handle
    jnc dupkhDone

dupkhFail:
    xor ebx,ebx

dupkhDone:
    pop esi
    pop ds
    ret
dupl_kernel_handle    Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_kernel_handle
;
;           DESCRIPTION:    Init kernel handle module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_kernel_handle

init_kernel_handle     PROC near
    push ds
    push es
    pushad
;
    mov bx,SEG data
    mov es,bx
    InitSection es:hd_section
;
    mov edi,OFFSET hd_kernel_arr
    xor eax,eax
    mov ecx,MAX_KERNEL_HANDLES
    rep stosd
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET open_kernel_handle
    mov edi,OFFSET open_kernel_handle_name
    xor cl,cl
    mov ax,open_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET read_kernel_handle
    mov edi,OFFSET read_kernel_handle_name
    xor cl,cl
    mov ax,read_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET write_kernel_handle
    mov edi,OFFSET write_kernel_handle_name
    xor cl,cl
    mov ax,write_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET close_kernel_handle
    mov edi,OFFSET close_kernel_handle_name
    xor cl,cl
    mov ax,close_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET dupl_kernel_handle
    mov edi,OFFSET dupl_kernel_handle_name
    xor cl,cl
    mov ax,dupl_kernel_handle_nr
    RegisterOsGate
;
    popad
    pop es
    pop ds
    ret
init_kernel_handle     ENDP

code    ENDS

    END
