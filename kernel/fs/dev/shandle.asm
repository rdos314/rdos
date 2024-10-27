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
; SHANDLE.ASM
; Sys handle module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
include ..\wait.inc
INCLUDE ..\os\blk.inc
INCLUDE ..\hint.inc
INCLUDE ..\driver.def
INCLUDE ..\os\exec.def
INCLUDE vfs.inc

    .386p

SYS_HANDLE_COUNT      = 1024
SYS_BITMAP_COUNT      = SYS_HANDLE_COUNT SHR 5
PROC_HANDLE_COUNT     = 512

;
; this should always be 16 bytes!
;

sys_handle_struc    STRUC

sh_sel               DW ?
sh_ref_count         DW ?
sh_read_wait_sel     DW ?
sh_write_wait_sel    DW ?
sh_exc_wait_sel      DW ?
sh_resv              DW ?,?,?

sys_handle_struc    ENDS

;
; this should always be 8 bytes!

proc_entry_struc       STRUC

pe_sel          DW ?
pe_handle       DW ?
pe_access       DW ?
pe_resv         DW ?

proc_entry_struc       ENDS

proc_handle_struc    STRUC

ph_section       section_typ <>
ph_arr           DD 2 * PROC_HANDLE_COUNT DUP(?)

proc_handle_struc    ENDS

data    SEGMENT byte public 'DATA'

hd_section       section_typ <>
hd_proc_count    DW ?

hd_proc_arr      DD MAX_PROC_COUNT DUP(?)
hd_sys_bitmap    DD SYS_BITMAP_COUNT DUP(?)
hd_sys_arr       DD 4 * SYS_HANDLE_COUNT DUP(?)

data       ENDS

code    SEGMENT byte public 'CODE'
    
    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSysHandle
;
;           DESCRIPTION:    Create sys handle
;
;           PARAMETERS:     ES          New process thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_sys_handle_name DB 'Create Sys Handle', 0

create_sys_handle Proc far
    push ds
    pushad
;    
    mov eax,SEG data
    mov ds,eax
;
    mov edi,OFFSET hd_sys_arr
    inc ds:[edi].sh_ref_count
;
    add edi,16
    add ds:[edi].sh_ref_count,2
;
    mov eax,flat_sel
    mov ds,eax
;
    mov eax,SIZE proc_handle_struc
    AllocateSmallLinear
;    
    lea edi,[edx].ph_arr
    mov ds:[edi].pe_sel,0
    mov ds:[edi].pe_handle,1
    mov ds:[edi].pe_access,IO_READ OR IO_ISTTY
;
    add edi,8
    mov ds:[edi].pe_sel,0
    mov ds:[edi].pe_handle,2
    mov ds:[edi].pe_access,IO_WRITE OR IO_ISTTY
;
    add edi,8
    mov ds:[edi].pe_sel,0
    mov ds:[edi].pe_handle,2
    mov ds:[edi].pe_access,IO_WRITE OR IO_ISTTY
;    
    mov ecx,PROC_HANDLE_COUNT - 3

nsLoop:
    add edi,8
    mov ds:[edi].pe_sel,0
    mov ds:[edi].pe_handle,0
    mov ds:[edi].pe_access,0
    loop nsLoop
;    
    InitSection ds:[edx].ph_section
;    
    mov eax,SEG data
    mov ds,eax
;
    EnterSection ds:hd_section
    movzx ebx,ds:hd_proc_count
    shl ebx,2
    mov ds:[ebx].hd_proc_arr,edx
    inc ds:hd_proc_count
    LeaveSection ds:hd_section
;
    mov ds,es:p_proc_sel
    mov ds:pf_handle_linear,edx
;
    popad
    pop ds
    ret
create_sys_handle Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_shandle
;
;           DESCRIPTION:    Init sys handle module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_sys_handle

init_sys_handle     PROC near
    push ds
    push es
    pushad
;
    mov bx,SEG data
    mov es,bx
;
    mov edi,OFFSET hd_proc_arr
    xor eax,eax
    mov ecx,MAX_PROC_COUNT
    rep stosd
;
    mov edi,OFFSET hd_sys_bitmap
    xor eax,eax
    mov ecx,SYS_BITMAP_COUNT
    rep stosd
;
    mov edi,OFFSET hd_sys_arr
    xor eax,eax
    mov ecx,4 * SYS_HANDLE_COUNT
    rep stosd
;
    InitSection es:hd_section
    mov es:hd_sys_bitmap,3
    mov es:hd_proc_count,0
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET create_sys_handle
    mov edi,OFFSET create_sys_handle_name
    xor cl,cl
    mov ax,create_sys_handle_nr
    RegisterOsGate
;
    popad
    pop es
    pop ds
    ret
init_sys_handle     ENDP

code    ENDS

    END
