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
; DOSDEV.ASM
; DOS standard device emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc

data    SEGMENT byte public 'DATA'

device_chain        DW ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           REGISTER_DEVICE
;
;           DESCRIPTION:    Register DOS device
;
;           PARAMETERS:     DS:BX       DEVICE HEADER
;                           CX          DEVICE SIZE
;                           DX          DEVICE SEGMENT
;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_device_name    DB 'Register Dos Device',0

register_device PROC far
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov ax,flat_sel
    mov es,ax
    movzx ecx,cx
    mov eax,ecx
    AllocateFixedVMLinear
    mov edi,edx
    movzx esi,bx
    rep movs byte ptr es:[edi],ds:[esi]
    shr edx,4
    mov ax,flat_sel
    mov ds,ax
    mov ax,SEG data
    mov es,ax
    movzx eax,es:device_chain
    shl eax,4
    push dword ptr [eax]
    shl edx,16
    mov [eax],edx
    pop eax
    shr edx,12
    mov [edx],eax
    shr edx,4
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    retf32
register_device ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CLOCK_DEVICE
;
;           DESCRIPTION:    Clock$ device
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clock_device_begin:
    dd -1
    dw 08008h
    dw OFFSET clock_strat - OFFSET clock_device_begin
    dw OFFSET clock_int - OFFSET clock_device_begin
    db 'CLOCK$  '
clock_strat:
    retf
clock_int:
    retf
clock_device_end:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           PRN_DEVICE
;
;           DESCRIPTION:    PRN device
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

prn_device_begin:
    dd -1
    dw 080C0h
    dw OFFSET prn_strat - OFFSET prn_device_begin
    dw OFFSET prn_int - OFFSET prn_device_begin
    db 'PRN     '
prn_strat:
    retf
prn_int:
    retf
prn_device_end:

lpt1_device_begin:
    dd -1
    dw 080C0h
    dw OFFSET lpt1_strat - OFFSET lpt1_device_begin
    dw OFFSET lpt1_int - OFFSET lpt1_device_begin
    db 'LPT1    '
lpt1_strat:
    retf
lpt1_int:
    retf
lpt1_device_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AUX_DEVICE
;
;           DESCRIPTION:    AUX device
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

aux_device_begin:
    dd -1
    dw 080C0h
    dw OFFSET aux_strat - OFFSET aux_device_begin
    dw OFFSET aux_int - OFFSET aux_device_begin
    db 'AUX     '
aux_strat:
    retf
aux_int:
    retf
aux_device_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CON_DEVICE
;
;           DESCRIPTION:    CON device
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

con_device_begin:
    dd -1
    dw 080D3h
    dw OFFSET con_strat - OFFSET con_device_begin
    dw OFFSET con_int - OFFSET con_device_begin
    db 'CON     '
con_strat:
    retf
con_int:
    retf
con_device_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init driver
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nul_device_begin:
    dd -1
    dw 08004h
    dw OFFSET nul_strat - OFFSET nul_device_begin
    dw OFFSET nul_int - OFFSET nul_device_begin
    db 'NUL     '
nul_strat:
    retf
nul_int:
    retf
nul_device_end:

    public init_dosdev
    
init_dosdev     PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET register_device
    mov edi,OFFSET register_device_name
    mov ax,register_dos_device_nr
    RegisterOsGate
;
    mov ax,flat_sel
    mov es,ax
    mov eax,OFFSET nul_device_end - OFFSET nul_device_begin
    AllocateFixedVMLinear
    mov ecx,eax
    mov edi,edx
    mov esi,OFFSET nul_device_begin
    rep movs byte ptr es:[edi],ds:[esi]
    shr edx,4
    mov ax,SEG data
    mov es,ax
    mov es:device_chain,dx
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov bx,OFFSET clock_device_begin
    mov cx,OFFSET clock_device_end - OFFSET clock_device_begin
    RegisterDosDevice
;
    mov bx,OFFSET prn_device_begin
    mov cx,OFFSET prn_device_end - OFFSET prn_device_begin
    RegisterDosDevice
;
    mov bx,OFFSET aux_device_begin
    mov cx,OFFSET aux_device_end - OFFSET aux_device_begin
    RegisterDosDevice
;
    mov bx,OFFSET con_device_begin
    mov cx,OFFSET con_device_end - OFFSET con_device_begin
    RegisterDosDevice
;
    mov bx,OFFSET lpt1_device_begin
    mov cx,OFFSET lpt1_device_end - OFFSET lpt1_device_begin
    RegisterDosDevice
    ret
init_dosdev     ENDP

code    ENDS

    END
