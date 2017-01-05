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
; CHANDLE.ASM
; C-library handle compatibility layer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def

;
; iomode constants
;

IO_READ         = 1
IO_WRITE        = 2
IO_EOF          = 10h
IO_BINARY       = 40h
IO_APPEND       = 80h
IO_FBF          = 100h
IO_LBF          = 200h
IO_NBF          = 400h
IO_ISTTY        = 1000h

HANDLE_ENTRY_SIZE     = 16
MAX_HANDLES           = 256

handle_entry_struc    STRUC

he_rdos_handle   DW ?
he_io_mode       DW ?
he_ref_count     DW ?
he_close_proc    DW ?
he_dup_proc      DW ?

he_space         DW ?,?,?

handle_entry_struc    ENDS

handle_struc    STRUC

h_section       section_typ <>

h_sel           DW ?
h_bitmap        DD ?,?

h_arr           DW MAX_HANDLES DUP(?)

handle_struc    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'
    
    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Create C handle
;
;           DESCRIPTION:    Create std-C handle selector
;
;           RETURNS:        AX          C handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_c_handle_name  DB 'Create C Handle', 0

create_c_handle    PROC far
    push ds
    push es
    push bx
    push cx
    push dx
    push si
    push di
;    
    mov eax,SIZE handle_struc
    AllocateSmallGlobalMem
;
    mov di,OFFSET h_arr
    xor ax,ax
    mov cx,MAX_HANDLES
    rep stosw
;    
    mov ax,es
    mov ds,ax
;    
    InitSection ds:h_section
    mov ds:h_bitmap,0
    mov ds:h_bitmap+4,0
;
    mov eax,1000h
    AllocateGlobalMem
    xor di,di
    xor ax,ax
    mov cx,800h
    rep stosw
    mov ds:h_sel,es
;    
    mov ax,ds
;
    pop di
    pop si
    pop dx
    pop cx
    pop bx    
    pop es
    pop ds
    retf32
create_c_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_chandle
;
;           DESCRIPTION:    Init C handle module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_chandle

init_chandle     PROC near
    push ds
    push es
    pushad
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET create_c_handle
    mov edi,OFFSET create_c_handle_name
    xor cl,cl
    mov ax,create_c_handle_nr
    RegisterOsGate
;
    popad
    pop es
    pop ds
    ret
init_chandle     ENDP

code    ENDS

    END
