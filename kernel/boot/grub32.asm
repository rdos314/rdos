;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; GRUB32.ASM
; 32-bit part of GRUB dummy kernel (OS loader)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                NAME  grub32

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.386p

INCLUDE ..\driver.def

IMAGE_BASE = 110000h

MY_OFFSET       = 40h

code    SEGMENT byte public USE32 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   init
;
;               DESCRIPTION:    GRUB entry-point
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init:
    mov edx,IMAGE_BASE + OFFSET gdt10 + MY_OFFSET
    db 66h
    lgdt fword ptr [edx]
;
    mov edx,IMAGE_BASE + OFFSET gdt8 + MY_OFFSET
    db 66h
    lidt fword ptr [edx]
;
    db 0EAh
    dd OFFSET prot_init
    dd device_code_sel

code    ENDS

    extrn prot_init:near
    extrn gdt8:near
    extrn gdt10:near

    END init

