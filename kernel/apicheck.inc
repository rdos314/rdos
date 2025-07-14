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
; Apicheck.inc
; API validation module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; DEFINE DO_API_CHECK       ; decomment to enable API checks 

IFDEF DO_API_CHECK

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

ELSE

ApiSaveEax  Macro
            Endm

ApiCheckEax Macro
            Endm

ApiSaveEbx  Macro
            Endm

ApiCheckEbx Macro
            Endm

ApiSaveEcx  Macro
            Endm

ApiCheckEcx Macro
            Endm

ApiSaveEdx  Macro
            Endm

ApiCheckEdx Macro
            Endm

ApiSaveEsi  Macro
            Endm

ApiCheckEsi Macro
            Endm

ApiSaveEdi  Macro
            Endm

ApiCheckEdi Macro
            Endm


ApiSaveEbp  Macro
            Endm

ApiCheckEbp Macro
            Endm

ENDIF
