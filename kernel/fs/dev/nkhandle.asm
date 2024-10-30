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
; NKHANDLE.ASM
; New, temporay kernel handle module
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

data    SEGMENT byte public 'DATA'

hd_section       section_typ <>

hd_kernel_arr    DW MAX_KERNEL_HANDLES DUP(?)

data       ENDS

code    SEGMENT byte public 'CODE'
    
    assume cs:code

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
    ret
close_kernel_handle Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_new_kernel_handle
;
;           DESCRIPTION:    Init new kernel handle module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_new_kernel_handle

init_new_kernel_handle     PROC near
    push ds
    push es
    pushad
;
    mov bx,SEG data
    mov es,bx
    InitSection es:hd_section
;
    mov edi,OFFSET hd_kernel_arr
    xor ax,ax
    mov ecx,MAX_KERNEL_HANDLES
    rep stosw
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET open_kernel_handle
    mov edi,OFFSET open_kernel_handle_name
    xor cl,cl
    mov ax,open_new_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET close_kernel_handle
    mov edi,OFFSET close_kernel_handle_name
    xor cl,cl
    mov ax,close_new_kernel_handle_nr
    RegisterOsGate
;
    popad
    pop es
    pop ds
    ret
init_new_kernel_handle     ENDP

code    ENDS

    END
