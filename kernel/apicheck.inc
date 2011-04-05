;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
; Apicheck.inc
; API validation module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ApiSaveEax  Macro
    push eax
            Endm

ApiCheckEax Macro
    local check_ok
    
    push bp
    mov bp,sp
    pushf
    cmp eax,[bp+2]
    je check_ok
;
    int 3

check_ok:
    popf
    pop bp
    pop eax
            Endm

ApiSaveEbx  Macro
    push ebx
            Endm

ApiCheckEbx Macro
    local check_ok
    
    push bp
    mov bp,sp
    pushf
    cmp ebx,[bp+2]
    je check_ok
;
    int 3

check_ok:
    popf
    pop bp
    pop ebx
            Endm


ApiSaveEcx  Macro
    push ecx
            Endm

ApiCheckEcx Macro
    local check_ok
    
    push bp
    mov bp,sp
    pushf
    cmp ecx,[bp+2]
    je check_ok
;
    int 3

check_ok:
    popf
    pop bp
    pop ecx
            Endm


ApiSaveEdx  Macro
    push edx
            Endm

ApiCheckEdx Macro
    local check_ok
    
    push bp
    mov bp,sp
    pushf
    cmp edx,[bp+2]
    je check_ok
;
    int 3

check_ok:
    popf
    pop bp
    pop edx
            Endm

ApiSaveEsi  Macro
    push esi
            Endm

ApiCheckEsi Macro
    local check_ok
    
    push bp
    mov bp,sp
    pushf
    cmp esi,[bp+2]
    je check_ok
;
    int 3

check_ok:
    popf
    pop bp
    pop esi
            Endm


ApiSaveEdi  Macro
    push edi
            Endm

ApiCheckEdi Macro
    local check_ok
    
    push bp
    mov bp,sp
    pushf
    cmp edi,[bp+2]
    je check_ok
;
    int 3

check_ok:
    popf
    pop bp
    pop edi
            Endm


ApiSaveEbp  Macro
    push ebp
            Endm

ApiCheckEbp Macro
    local check_ok

    push eax    
    mov eax,ebp
;    
    push bp
    pushf
    mov bp,sp
    cmp eax,[bp+6]
    je check_ok
;
    int 3

check_ok:
    popf
    pop bp
    pop eax
    pop ebp
            Endm

