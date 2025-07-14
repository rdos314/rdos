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
;           NAME:           INIT_IO
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
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
    mov eax,2000h
    AllocateFixedSystemMem
    xor di,di
    mov cx,400h
    xor eax,eax
init_in_hooks:
    mov es:[di],eax
    mov es:[di+4],eax
    add di,8
    loop init_in_hooks
;
    mov bx,hook_out_sel
    mov eax,2000h
    AllocateFixedSystemMem
    xor di,di
    mov cx,400h
    xor eax,eax
init_out_hooks:
    mov es:[di],eax
    mov es:[di+4],eax
    add di,8
    loop init_out_hooks
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET hook_in
    mov edi,OFFSET hook_in_name
    xor cl,cl
    mov ax,hook_in_nr
    RegisterOsGate
;    
    mov esi,OFFSET hook_out
    mov edi,OFFSET hook_out_name
    xor cl,cl
    mov ax,hook_out_nr
    RegisterOsGate
;    
    pop ds
    popa
    ret
init_io ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_IN
;
;           DESCRIPTION:    Add hook for IN
;
;           PARAMETERS:     DX       Port number
;                           ES:EDI   Callback
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
    shl bx,3
    mov [bx],edi
    mov [bx+4],es
    mov ax,io_bitmap_sel
    mov ds,ax
    xor bx,bx
    bts [bx],dx
    pop bx
    pop ax
    pop ds
    retf32
hook_in ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_OUT
;
;           DESCRIPTION:    Add hook for OUT
;
;           PARAMETERS:     DX          Port number
;                           ES:EDI      Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_out_name   DB 'Hook Out',0

hook_out    PROC far
    push ds
    push ax
    push bx
    mov ax,hook_out_sel
    mov ds,ax
    mov bx,dx
    shl bx,3
    mov [bx],edi
    mov [bx+4],es
    mov ax,io_bitmap_sel
    mov ds,ax
    xor bx,bx
    bts [bx],dx
    pop bx
    pop ax
    pop ds
    retf32
hook_out    ENDP

code    ENDS

.186

END
