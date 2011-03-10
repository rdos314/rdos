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
; IO.ASM
; I/O trapping module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
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
;               NAME:                   INIT_IO
;
;               DESCRIPTION:    Init module
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public init_io

init_io PROC near
        pusha
        push ds
        mov bx,io_bitmap_sel
        mov eax,80h
        AllocateFixedSystemMem
        mov cx,ax
        xor al,al
        xor di,di
        rep stosb
;
        mov bx,hook_in_sel
        mov eax,1000h
        AllocateFixedSystemMem
        xor di,di
        mov cx,400h
        xor eax,eax
init_in_hooks:
        mov es:[di],eax
        add di,4
        loop init_in_hooks
;
        mov bx,hook_out_sel
        mov eax,1000h
        AllocateFixedSystemMem
        xor di,di
        mov cx,400h
        xor eax,eax
init_out_hooks:
        mov es:[di],eax
        add di,4
        loop init_out_hooks
;
        mov ax,cs
        mov ds,ax
        mov es,ax
        mov esi,OFFSET hook_in
        mov edi,OFFSET hook_in_name
        xor cl,cl
        mov ax,hook_in_nr
        RegisterOldOsGate
        mov esi,OFFSET hook_out
        mov edi,OFFSET hook_out_name
        xor cl,cl
        mov ax,hook_out_nr
        RegisterOldOsGate
        pop ds
        popa
        ret
init_io ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   HOOK_IN
;
;               DESCRIPTION:    Add hook for IN
;
;               PARAMETERS:             DX              Port number
;                                               ES:DI   Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_in_name    DB 'Hook In',0

hook_in PROC far
        push ds
        push ax
        push bx
        mov ax,hook_in_sel
        mov ds,ax
        mov bx,dx
        shl bx,2
        mov [bx],di
        mov [bx+2],es
        mov ax,io_bitmap_sel
        mov ds,ax
        xor bx,bx
        bts [bx],dx
        pop bx
        pop ax
        pop ds
        ret
hook_in ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   HOOK_OUT
;
;               DESCRIPTION:    Add hook for OUT
;
;               PARAMETERS:             DX              Port number
;                                               ES:DI   Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_out_name   DB 'Hook Out',0

hook_out        PROC far
        push ds
        push ax
        push bx
        mov ax,hook_out_sel
        mov ds,ax
        mov bx,dx
        shl bx,2
        mov [bx],di
        mov [bx+2],es
        mov ax,io_bitmap_sel
        mov ds,ax
        xor bx,bx
        bts [bx],dx
        pop bx
        pop ax
        pop ds
        ret
hook_out        ENDP

code    ENDS

.186

END
