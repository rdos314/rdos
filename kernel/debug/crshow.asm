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
; CRSHOW.ASM
; Crash register dump
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\proc.inc
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE ..\os\protseg.def
INCLUDE dis.inc

data    SEGMENT byte public 'DATA'

cpu1 cpu_struc <>
cpu2 cpu_struc <>
cpu3 cpu_struc <>
cpu4 cpu_struc <>
cpu5 cpu_struc <>
cpu6 cpu_struc <>
cpu7 cpu_struc <>
cpu8 cpu_struc <>
cpu9 cpu_struc <>
cpu10 cpu_struc <>
cpu11 cpu_struc <>
cpu12 cpu_struc <>
cpu13 cpu_struc <>
cpu14 cpu_struc <>
cpu15 cpu_struc <>
cpu16 cpu_struc <>

temp_size     DW ?
temp_base     DD ?

map_linear   DD ?
map_sel      DW ?

view_type       DB ?

curr_pos        DW ?

data    ENDS

    .386p

code    SEGMENT byte public use32 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapPhysical
;
;           DESCRIPTION:    Map physical address
;
;           PARAMETERS:     EBX:EAX     physical address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapPhysical       Proc near
    push ds
    push eax
    push ecx
    push edx
;
    mov al,67h
    and ah,0F0h
;
    mov cx,SEG data
    mov ds,cx
    mov edx,ds:map_linear
;    
    mov cx,process_page_sel
    mov ds,cx
;
    mov ecx,cr4
    test cl,20h
    jnz mpPae

mpProt:    
    shr edx,10
    and dl,0FCh
    mov [edx],eax
    jmp mpDone

mpPae:
    shr edx,9
    and dl,0F8h
    mov [edx],eax
    mov [edx+4],ebx

mpDone:
    mov ecx,cr3
    mov cr3,ecx
;    
    pop edx    
    pop ecx
    pop eax
    pop ds
    ret
MapPhysical       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapLinear
;
;           DESCRIPTION:    Map linear address
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                               ES:EBX  Mapping
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapLinear       Proc near
    push eax
    push edx
    push esi
;    
    mov edx,ebx
    mov es,ds:map_sel
    mov eax,ds:[ebp].reg_cr3
    xor ebx,ebx
    call MapPhysical
;
    test ds:[ebp].reg_cr4,20h
    jnz mlPae

mlProt:
    mov esi,edx
    shr esi,20
    and si,0FFFCh
    mov eax,es:[esi]
    test al,1
    jz mlFail
;
    xor ebx,ebx
    call MapPhysical
;
    mov esi,edx
    shr esi,10
    and esi,0FFCh
    mov eax,es:[esi]
    test al,1
    jz mlFail
;
    xor ebx,ebx
    call MapPhysical
;    
    mov ebx,edx
    and ebx,0FFFh    
    clc
    jmp mlDone

mlPae:

mlFail:
    stc

mlDone: 
    pop esi
    pop edx
    pop eax
    ret
MapLinear       Endp           
            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLinearByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                               AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadLinearByte   PROC near
    push ds
    push ebx
;    
    mov ax,flat_sel
    mov ds,ax
    mov al,ds:[ebx]
    clc
;
    pop ebx
    pop ds
    ret
ReadLinearByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLinearByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteLinearByte   PROC near
    push ds
    push edx
;    
    mov dx,flat_sel
    mov ds,dx
    mov ds:[ebx],al
;
    pop edx
    pop ds
    ret
WriteLinearByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLinearWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                               AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadLinearWord   PROC near
    push ebx
    push esi
;
    call ReadLinearByte
    movzx si,al
    jc rlwDone
;
    inc ebx
    call ReadLinearByte
    shl ax,8
    and ax,0FF00h
    or si,ax
    clc

rlwDone: 
    pop esi   
    pop ebx
    ret
ReadLinearWord   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLinearDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                               EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadLinearDword   PROC near
    push ebx
    push esi
;
    call ReadLinearByte
    movzx esi,al
    jc rldDone
;
    inc ebx
    call ReadLinearByte
    jc rldDone
;
    shl ax,8
    and eax,0FF00h
    or esi,eax
;
    inc ebx
    call ReadLinearByte
    jc rldDone
;    
    shl eax,16
    and eax,0FF0000h
    or esi,eax
;
    inc ebx
    call ReadLinearByte
    jc rldDone
;
    shl eax,24
    and eax,0FF000000h
    or esi,eax
;
    mov eax,esi    
    clc

rlddone: 
    pop esi   
    pop ebx
    ret
ReadLinearDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLinearQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                             EDX:EAX  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadLinearQword   PROC near
    call ReadLinearDword
    jc rlqDone    
;
    mov edx,eax
    add ebx,4
    call ReadLinearDword
    jc rlqDone
;
    xchg eax,edx
    clc

rlqDone:
    ret
ReadLinearQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSelectorBaseSizeType
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           BX          Selector
;
;           RETURNS:        NC
;                               EDX     Base
;                               ECX     Size
;                               AL      Type (+5)
;                               AH      Big (+6)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSelectorBaseSizeType   PROC near
    push ebx
    push esi
    push edi
;
    movzx ebx,bx
    and bx,NOT 3
    or bx,bx
    jz get_info_fail
;
    test bx,4
    jz get_info_gdt

get_info_ldt:
    mov ecx,ds:[ebp].reg_ldt.d_limit
    mov eax,ds:[ebp].reg_ldt.d_base
    jmp get_info_do

get_info_gdt:
    mov ecx,ds:[ebp].reg_gdt.d_limit
    mov eax,ds:[ebp].reg_gdt.d_base

get_info_do:
    and bx,0FFF8h
    cmp ecx,ebx
    jc get_info_done
;
    movzx ebx,bx
    add ebx,eax
    xor edi,edi
    call ReadLinearQword
;
    test dh,80h
    jz get_info_fail
;
    mov ecx,edx
    and ecx,0F0000h
    mov cx,ax
    test edx,800000h
    jz get_info_small
;
    shl ecx,12
    or cx,0FFFh

get_info_small:
    mov ebx,edx
    shr ebx,8
;    
    shr eax,16
    and eax,0FFFFh
;
    rol edx,8
    xchg dl,dh
    shl edx,16
    or edx,eax
    mov ax,bx
    clc
    jmp get_info_done

get_info_fail:
    stc

get_info_done:
    pop edi
    pop esi
    pop ebx
    ret
GetSelectorBaseSizeType   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBitness
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           BX          Selector
;
;           RETURNS:        NC
;                               DL      Bitness (0 = 16, 1 = 32)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBitness   PROC near
    push eax
    push ecx
;    
    call GetSelectorBaseSizeType
    jc get_bitness_done
;
    mov dl,ah
    shr dl,6
    and dl,1
    clc

get_bitness_done:
    pop ecx
    pop eax
    ret
GetBitness   ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Font8x19
;
;   DESCRIPTION:    8x19 font
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

font8x19:
f00 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f01 db 000h, 000h, 000h, 07Eh, 081h, 081h, 0A5h, 081h, 081h, 081h, 0BDh, 099h, 081h, 081h, 07Eh, 000h, 000h, 000h, 000h
f02 db 000h, 000h, 000h, 07Eh, 0FFh, 0FFh, 0DBh, 0FFh, 0FFh, 0FFh, 0C3h, 0E7h, 0FFh, 0FFh, 07Eh, 000h, 000h, 000h, 000h
f03 db 000h, 000h, 000h, 000h, 000h, 000h, 06Ch, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h, 000h, 000h, 000h
f04 db 000h, 000h, 000h, 000h, 000h, 000h, 010h, 038h, 07Ch, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h, 000h, 000h, 000h, 000h
f05 db 000h, 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 0E7h, 0E7h, 0E7h, 0E7h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f06 db 000h, 000h, 000h, 000h, 018h, 018h, 03Ch, 07Eh, 0FFh, 0FFh, 0FFh, 07Eh, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f07 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f08 db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0E7h, 0C3h, 0C3h, 0C3h, 0E7h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
f09 db 000h, 000h, 000h, 000h, 000h, 000h, 03Ch, 066h, 042h, 042h, 042h, 066h, 03Ch, 000h, 000h, 000h, 000h, 000h, 000h
f0A db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0C3h, 099h, 0BDh, 0BDh, 0BDh, 099h, 0C3h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
f0B db 000h, 000h, 000h, 01Eh, 006h, 00Eh, 01Ah, 030h, 078h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 078h, 000h, 000h, 000h, 000h
f0C db 000h, 000h, 000h, 03Ch, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h, 018h, 000h, 000h, 000h, 000h
f0D db 000h, 000h, 000h, 03Fh, 033h, 033h, 03Fh, 030h, 030h, 030h, 030h, 030h, 070h, 0F0h, 0E0h, 000h, 000h, 000h, 000h
f0E db 000h, 000h, 000h, 07Fh, 063h, 063h, 07Fh, 063h, 063h, 063h, 063h, 063h, 067h, 0E7h, 0E6h, 0C0h, 000h, 000h, 000h
f0F db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 0DBh, 03Ch, 0E7h, 0E7h, 03Ch, 0DBh, 018h, 018h, 000h, 000h, 000h, 000h
f10 db 000h, 000h, 000h, 080h, 0C0h, 0E0h, 0F0h, 0F8h, 0FEh, 0FEh, 0F8h, 0F0h, 0E0h, 0C0h, 080h, 000h, 000h, 000h, 000h
f11 db 000h, 000h, 000h, 002h, 006h, 00Eh, 01Eh, 03Eh, 0FEh, 0FEh, 03Eh, 01Eh, 00Eh, 006h, 002h, 000h, 000h, 000h, 000h
f12 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 000h, 000h, 000h, 000h
f13 db 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 066h, 066h, 000h, 000h, 000h, 000h
f14 db 000h, 000h, 000h, 07Fh, 0DBh, 0DBh, 0DBh, 0DBh, 07Bh, 01Bh, 01Bh, 01Bh, 01Bh, 01Bh, 01Bh, 000h, 000h, 000h, 000h
f15 db 000h, 000h, 000h, 07Ch, 0C6h, 060h, 038h, 06Ch, 0C6h, 0C6h, 06Ch, 038h, 00Ch, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f16 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0FEh, 0FEh, 000h, 000h, 000h, 000h
f17 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 07Eh, 000h, 000h, 000h
f18 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f19 db 000h, 000h, 000h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 000h, 000h, 000h, 000h
f1A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 00Ch, 0FEh, 00Ch, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1B db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 030h, 060h, 0FEh, 060h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1C db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h
f1D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 024h, 066h, 0FFh, 066h, 024h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1E db 000h, 000h, 000h, 000h, 000h, 010h, 010h, 038h, 038h, 07Ch, 07Ch, 0FEh, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h
f1F db 000h, 000h, 000h, 000h, 000h, 0FEh, 0FEh, 07Ch, 07Ch, 038h, 038h, 010h, 010h, 000h, 000h, 000h, 000h, 000h, 000h
f20 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f21 db 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 03Ch, 018h, 018h, 018h, 018h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f22 db 000h, 000h, 066h, 066h, 066h, 024h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f23 db 000h, 000h, 000h, 06Ch, 06Ch, 06Ch, 0FEh, 06Ch, 06Ch, 06Ch, 06Ch, 0FEh, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h
f24 db 000h, 018h, 018h, 07Ch, 0C6h, 0C2h, 0C0h, 0C0h, 07Ch, 006h, 006h, 006h, 086h, 0C6h, 07Ch, 018h, 018h, 000h, 000h
f25 db 000h, 000h, 000h, 0C6h, 0C6h, 0CCh, 00Ch, 018h, 018h, 030h, 030h, 060h, 066h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f26 db 000h, 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 076h, 0DCh, 0DCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f27 db 000h, 000h, 018h, 018h, 018h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f28 db 000h, 000h, 000h, 00Ch, 018h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 018h, 00Ch, 000h, 000h, 000h, 000h
f29 db 000h, 000h, 000h, 030h, 018h, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 018h, 030h, 000h, 000h, 000h, 000h
f2A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 03Ch, 0FFh, 03Ch, 066h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f2B db 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 0FFh, 018h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 000h
f2C db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 030h, 000h, 000h, 000h
f2D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f2E db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f2F db 000h, 000h, 000h, 006h, 006h, 00Ch, 00Ch, 018h, 018h, 030h, 030h, 060h, 060h, 0C0h, 0C0h, 000h, 000h, 000h, 000h
f30 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0D6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f31 db 000h, 000h, 000h, 018h, 038h, 078h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 000h, 000h, 000h, 000h
f32 db 000h, 000h, 000h, 07Ch, 0C6h, 006h, 006h, 00Ch, 018h, 030h, 060h, 0C0h, 0C0h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f33 db 000h, 000h, 000h, 07Ch, 0C6h, 006h, 006h, 006h, 03Ch, 006h, 006h, 006h, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f34 db 000h, 000h, 000h, 01Ch, 01Ch, 03Ch, 03Ch, 06Ch, 06Ch, 0CCh, 0FEh, 00Ch, 00Ch, 00Ch, 01Eh, 000h, 000h, 000h, 000h
f35 db 000h, 000h, 000h, 0FEh, 0C0h, 0C0h, 0C0h, 0C0h, 0FCh, 006h, 006h, 006h, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f36 db 000h, 000h, 000h, 038h, 060h, 0C0h, 0C0h, 0C0h, 0FCh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f37 db 000h, 000h, 000h, 0FEh, 0C6h, 006h, 006h, 006h, 00Ch, 018h, 018h, 030h, 030h, 030h, 030h, 000h, 000h, 000h, 000h
f38 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f39 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 006h, 006h, 00Ch, 078h, 000h, 000h, 000h, 000h
f3A db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h
f3B db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 030h, 000h, 000h, 000h, 000h
f3C db 000h, 000h, 000h, 000h, 006h, 00Ch, 018h, 030h, 060h, 060h, 030h, 018h, 00Ch, 006h, 000h, 000h, 000h, 000h, 000h
f3D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f3E db 000h, 000h, 000h, 000h, 060h, 030h, 018h, 00Ch, 006h, 006h, 00Ch, 018h, 030h, 060h, 000h, 000h, 000h, 000h, 000h
f3F db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 006h, 006h, 00Ch, 018h, 018h, 018h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f40 db 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0DEh, 0DEh, 0DEh, 0DCh, 0C0h, 0C0h, 07Ch, 000h, 000h, 000h, 000h
f41 db 000h, 000h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f42 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 066h, 066h, 066h, 066h, 066h, 0FCh, 000h, 000h, 000h, 000h
f43 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C2h, 066h, 03Ch, 000h, 000h, 000h, 000h
f44 db 000h, 000h, 000h, 0F8h, 06Ch, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 06Ch, 0F8h, 000h, 000h, 000h, 000h
f45 db 000h, 000h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f46 db 000h, 000h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f47 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0DEh, 0C6h, 0C6h, 0C6h, 066h, 03Ah, 000h, 000h, 000h, 000h
f48 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f49 db 000h, 000h, 000h, 03Ch, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f4A db 000h, 000h, 000h, 00Fh, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f4B db 000h, 000h, 000h, 0E6h, 066h, 066h, 06Ch, 06Ch, 078h, 07Ch, 06Ch, 06Ch, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f4C db 000h, 000h, 000h, 0F0h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f4D db 000h, 000h, 000h, 0C6h, 0EEh, 0FEh, 0FEh, 0D6h, 0D6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f4E db 000h, 000h, 000h, 0C6h, 0C6h, 0E6h, 0E6h, 0F6h, 0F6h, 0DEh, 0DEh, 0CEh, 0CEh, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f4F db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
f50 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f51 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0D6h, 0DEh, 07Ch, 00Ch, 00Eh, 000h, 000h
f52 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 06Ch, 06Ch, 066h, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f53 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C0h, 060h, 038h, 00Ch, 006h, 006h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f54 db 000h, 000h, 000h, 07Eh, 07Eh, 05Ah, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f55 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f56 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 010h, 000h, 000h, 000h, 000h
f57 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0FEh, 06Ch, 06Ch, 000h, 000h, 000h, 000h
f58 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 06Ch, 06Ch, 038h, 038h, 06Ch, 06Ch, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f59 db 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f5A db 000h, 000h, 000h, 0FEh, 0C6h, 086h, 006h, 00Ch, 018h, 030h, 060h, 0C0h, 0C2h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f5B db 000h, 000h, 000h, 03Ch, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 03Ch, 000h, 000h, 000h, 000h
f5C db 000h, 000h, 000h, 0C0h, 0C0h, 060h, 060h, 030h, 030h, 018h, 018h, 00Ch, 00Ch, 006h, 006h, 000h, 000h, 000h, 000h
f5D db 000h, 000h, 000h, 03Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 03Ch, 000h, 000h, 000h, 000h
f5E db 000h, 010h, 038h, 06Ch, 0C6h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f5F db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h
f60 db 000h, 000h, 030h, 018h, 00Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f61 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f62 db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 078h, 06Ch, 066h, 066h, 066h, 066h, 066h, 0DCh, 000h, 000h, 000h, 000h
f63 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f64 db 000h, 000h, 000h, 01Ch, 00Ch, 00Ch, 00Ch, 03Ch, 06Ch, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f65 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f66 db 000h, 000h, 000h, 038h, 06Ch, 064h, 060h, 060h, 0F0h, 060h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f67 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 07Ch, 00Ch, 00Ch, 0CCh, 078h, 000h
f68 db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 06Ch, 076h, 066h, 066h, 066h, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f69 db 000h, 000h, 000h, 018h, 018h, 000h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f6A db 000h, 000h, 000h, 006h, 006h, 000h, 000h, 00Eh, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 066h, 066h, 03Ch, 000h
f6B db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 066h, 066h, 06Ch, 078h, 078h, 06Ch, 066h, 0E6h, 000h, 000h, 000h, 000h
f6C db 000h, 000h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f6D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 0FEh, 0D6h, 0D6h, 0D6h, 0D6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f6E db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 000h, 000h, 000h
f6F db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f70 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 060h, 0F0h, 000h
f71 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 07Ch, 00Ch, 00Ch, 00Ch, 01Eh, 000h
f72 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 076h, 066h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f73 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 060h, 038h, 00Ch, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f74 db 000h, 000h, 000h, 010h, 030h, 030h, 030h, 0FCh, 030h, 030h, 030h, 030h, 030h, 036h, 01Ch, 000h, 000h, 000h, 000h
f75 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f76 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 000h, 000h, 000h, 000h
f77 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0FEh, 06Ch, 000h, 000h, 000h, 000h
f78 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 06Ch, 038h, 038h, 06Ch, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f79 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 00Ch, 078h, 000h
f7A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0C6h, 00Ch, 018h, 030h, 060h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f7B db 000h, 000h, 000h, 00Eh, 018h, 018h, 018h, 018h, 070h, 070h, 018h, 018h, 018h, 018h, 00Eh, 000h, 000h, 000h, 000h
f7C db 000h, 000h, 000h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f7D db 000h, 000h, 000h, 070h, 018h, 018h, 018h, 018h, 00Eh, 00Eh, 018h, 018h, 018h, 018h, 070h, 000h, 000h, 000h, 000h
f7E db 000h, 000h, 000h, 076h, 0DCh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f7F db 000h, 000h, 000h, 000h, 000h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0FEh, 000h, 000h, 000h, 000h, 000h
f80 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C2h, 066h, 03Ch, 018h, 00Ch, 038h, 000h
f81 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f82 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f83 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f84 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f85 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f86 db 000h, 000h, 000h, 038h, 06Ch, 038h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f87 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C6h, 07Ch, 018h, 00Ch, 038h, 000h
f88 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f89 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f8A db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f8B db 000h, 000h, 000h, 000h, 066h, 066h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8C db 000h, 000h, 000h, 018h, 03Ch, 066h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8D db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8E db 0C6h, 0C6h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f8F db 038h, 06Ch, 038h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f90 db 00Ch, 018h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f91 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 036h, 036h, 07Eh, 0D8h, 0D8h, 0D8h, 06Eh, 000h, 000h, 000h, 000h
f92 db 000h, 000h, 000h, 03Eh, 06Ch, 0CCh, 0CCh, 0CCh, 0FEh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CEh, 000h, 000h, 000h, 000h
f93 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f94 db 000h, 000h, 000h, 000h, 0C6h, 0C6h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f95 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f96 db 000h, 000h, 000h, 030h, 078h, 0CCh, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f97 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f98 db 000h, 000h, 000h, 000h, 0C6h, 0C6h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 00Ch, 078h, 000h
f99 db 0C6h, 0C6h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
f9A db 0C6h, 0C6h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f9B db 000h, 000h, 000h, 018h, 018h, 03Ch, 066h, 060h, 060h, 060h, 060h, 066h, 03Ch, 018h, 018h, 000h, 000h, 000h, 000h
f9C db 000h, 000h, 038h, 06Ch, 064h, 060h, 060h, 0F0h, 060h, 060h, 060h, 060h, 060h, 0E6h, 0FCh, 000h, 000h, 000h, 000h
f9D db 000h, 000h, 000h, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h, 018h, 07Eh, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f9E db 000h, 000h, 0F8h, 0CCh, 0CCh, 0CCh, 0F8h, 0C4h, 0CCh, 0DEh, 0CCh, 0CCh, 0CCh, 0CCh, 0C6h, 000h, 000h, 000h, 000h
f9F db 000h, 000h, 00Eh, 01Bh, 018h, 018h, 018h, 018h, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 0D8h, 070h, 000h, 000h
fA0 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
fA1 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
fA2 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
fA3 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
fA4 db 000h, 000h, 000h, 000h, 076h, 0DCh, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 000h, 000h, 000h
fA5 db 076h, 0DCh, 000h, 0C6h, 0C6h, 0E6h, 0E6h, 0F6h, 0F6h, 0DEh, 0DEh, 0CEh, 0CEh, 0C6h, 0C6h, 000h, 000h, 000h, 000h
fA6 db 000h, 000h, 03Ch, 06Ch, 06Ch, 06Ch, 03Eh, 000h, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fA7 db 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 000h, 07Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fA8 db 000h, 000h, 000h, 030h, 030h, 000h, 030h, 030h, 030h, 060h, 0C0h, 0C0h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
fA9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0C0h, 0C0h, 0C0h, 0C0h, 000h, 000h, 000h, 000h, 000h, 000h
fAA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 006h, 006h, 006h, 006h, 000h, 000h, 000h, 000h, 000h, 000h
fAB db 000h, 000h, 0C0h, 0C0h, 0C0h, 0C2h, 0C6h, 0CCh, 018h, 030h, 060h, 0DCh, 0A6h, 00Ch, 018h, 030h, 03Eh, 000h, 000h
fAC db 000h, 000h, 0C0h, 0C0h, 0C0h, 0C2h, 0C6h, 0CCh, 018h, 030h, 060h, 0CCh, 09Ch, 03Ch, 07Eh, 00Ch, 00Ch, 000h, 000h
fAD db 000h, 000h, 000h, 018h, 018h, 000h, 000h, 018h, 018h, 018h, 018h, 03Ch, 03Ch, 03Ch, 018h, 000h, 000h, 000h, 000h
fAE db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 033h, 066h, 0CCh, 0CCh, 066h, 033h, 000h, 000h, 000h, 000h, 000h, 000h
fAF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 066h, 033h, 033h, 066h, 0CCh, 000h, 000h, 000h, 000h, 000h, 000h
fB0 db 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h
fB1 db 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h
fB2 db 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh
fB3 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB4 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB6 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fB7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fB8 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB9 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 006h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBA db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBB db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 006h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBC db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 006h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBD db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBE db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC0 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC1 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC2 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC3 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC4 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC6 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC7 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fC8 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 030h, 03Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 03Fh, 030h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCA db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F7h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fCB db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0F7h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCC db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 030h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCD db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fCE db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F7h, 000h, 0F7h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCF db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD0 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD1 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD2 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD3 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 03Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD4 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 01Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD5 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 01Fh, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD6 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 03Fh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD7 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FFh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD8 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 018h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD9 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fDA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fDB db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
fDC db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
fDD db 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h
fDE db 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh
fDF db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fE0 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 0D8h, 0D8h, 0D8h, 0D8h, 0DCh, 076h, 000h, 000h, 000h, 000h
fE1 db 000h, 000h, 000h, 078h, 0CCh, 0CCh, 0CCh, 0CCh, 0D8h, 0CCh, 0C6h, 0C6h, 0C6h, 0C6h, 0DCh, 000h, 000h, 000h, 000h
fE2 db 000h, 000h, 000h, 0FEh, 0C6h, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 000h, 000h, 000h, 000h
fE3 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h
fE4 db 000h, 000h, 000h, 0FEh, 0C6h, 0C0h, 060h, 030h, 018h, 018h, 030h, 060h, 0C0h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
fE5 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 070h, 000h, 000h, 000h, 000h
fE6 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 0C0h, 000h
fE7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
fE8 db 000h, 000h, 000h, 03Ch, 018h, 03Ch, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 03Ch, 000h, 000h, 000h, 000h
fE9 db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
fEA db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 06Ch, 06Ch, 0EEh, 000h, 000h, 000h, 000h
fEB db 000h, 000h, 000h, 01Eh, 030h, 018h, 00Ch, 03Eh, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 000h, 000h, 000h, 000h
fEC db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 0DBh, 0DBh, 0DBh, 0DBh, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h
fED db 000h, 000h, 000h, 000h, 000h, 003h, 006h, 07Eh, 0CFh, 0DBh, 0DBh, 0F3h, 07Eh, 060h, 0C0h, 000h, 000h, 000h, 000h
fEE db 000h, 000h, 000h, 01Ch, 030h, 060h, 060h, 060h, 07Ch, 060h, 060h, 060h, 060h, 030h, 01Ch, 000h, 000h, 000h, 000h
fEF db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
fF0 db 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h
fF1 db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 07Eh, 018h, 018h, 018h, 000h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF2 db 000h, 000h, 000h, 000h, 060h, 030h, 018h, 00Ch, 006h, 00Ch, 018h, 030h, 060h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF3 db 000h, 000h, 000h, 000h, 006h, 00Ch, 018h, 030h, 060h, 030h, 018h, 00Ch, 006h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF4 db 000h, 000h, 000h, 00Eh, 01Bh, 01Bh, 01Bh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fF5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0D8h, 0D8h, 0D8h, 070h, 000h, 000h, 000h, 000h
fF6 db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 07Eh, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h
fF7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 000h, 000h, 076h, 0DCh, 000h, 000h, 000h, 000h, 000h, 000h
fF8 db 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fF9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFB db 000h, 000h, 00Fh, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 0ECh, 06Ch, 06Ch, 03Ch, 01Ch, 000h, 000h, 000h, 000h
fFC db 000h, 000h, 0D8h, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFD db 000h, 000h, 038h, 06Ch, 00Ch, 018h, 030h, 064h, 07Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFE db 000h, 000h, 000h, 000h, 000h, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 000h, 000h, 000h, 000h, 000h
fFF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           move_cursor
;
;           DESCRIPTION:    
;
;           PARAMETERS      CX              Column number (x)
;                           DX              Row number (y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_cursor Proc near
    push ds
    push eax
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:efi_text_row,cx
    mov ds:efi_text_col,dx    
;
    mov eax,ds:efi_lfb
    or eax,ds:efi_lfb+4
    pop ax
    jnz mcDone
;    
    SetCursorPosition

mcDone:
    pop eax
    pop ds
    ret
move_cursor Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowChar
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowChar Proc near
    push ds
    push es
    pushad
;   
    push eax
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:efi_lfb
    or eax,ds:efi_lfb+4
    pop eax
    jnz scLfb

scText:
    push eax
    mov ax,__B800
    mov es,ax
;
    mov ax,ds:efi_text_row
    mov cx,80
    mul cx
    add ax,ds:efi_text_col
    add ax,ax
    mov di,ax
    pop eax
    mov ah,7
    stosw
    jmp scUpdate

scLfb:
    push eax
    mov ax,flat_sel
    mov es,ax
; 
    mov ax,ds:efi_text_row
    mov cx,19
    mul cx
    add ax,4
    movzx eax,ax
    movzx edx,ds:efi_text_col
    shl edx,3
    xchg eax,edx
;
    push eax
    mov eax,ds:efi_scan_size
    mul edx
    mov edi,ds:efi_lfb
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
    pop eax
;
    mov ah,19
    mul ah
    movzx ebx,ax
    add ebx,OFFSET font8x19
;
    mov ecx,19

scRowLoop:    
    push ecx
    push edi
    mov ecx,8
    mov al,cs:[ebx]

scLoop:
    test al,80h
    jz scBack

scFore:
    mov edx,dword ptr ds:efi_fore_col
    mov es:[edi],edx
    jmp scNext

scBack:
    mov edx,dword ptr ds:efi_back_col
    mov es:[edi],edx

scNext:
    add edi,4
    shl al,1
;
    loop scLoop    
;
    pop edi
    pop ecx
    add edi,ds:efi_scan_size
    inc ebx
;
    loop scRowLoop    

scUpdate:
    inc ds:efi_text_col
    mov ax,ds:efi_text_col
    cmp ax,80
    jne scDone
;
    mov ds:efi_text_col,0
    inc ds:efi_text_row    

scDone:
    popad        
    pop es
    pop ds
    ret
ShowChar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InvertChar
;
;           DESCRIPTION:    CX  Col
;                           DX  Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
InvertChar Proc near
    push ds
    push es
    pushad
;   
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:efi_lfb
    or eax,ds:efi_lfb+4
    jz icDone

icLfb:
    mov ax,flat_sel
    mov es,ax
; 
    push cx
    mov ax,dx
    mov cx,19
    mul cx
    add ax,4
    movzx eax,ax
    pop dx
    movzx edx,dx
    shl edx,3
    xchg eax,edx
;
    push eax
    mov eax,ds:efi_scan_size
    mul edx
    mov edi,ds:efi_lfb
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
;
    mov ecx,19

icRowLoop:    
    push ecx
    push edi
    mov ecx,8

icLoop:
    mov eax,es:[edi]
    not eax
    mov es:[edi],eax
    add edi,4
    loop icLoop    
;
    pop edi
    pop ecx
    add edi,ds:efi_scan_size
;
    loop icRowLoop    

icDone:
    popad        
    pop es
    pop ds
    ret
InvertChar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Clear
;
;           DESCRIPTION:    Clear screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Clear Proc near
    push ds
    push es
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax 
    mov eax,ds:efi_lfb
    or eax,ds:efi_lfb+4
    jnz cLfb

cText:
    xor edi,edi
    mov ax,__B800
    mov es,ax
    mov ax,0720h
    mov ecx,80 * 24
    rep stosw
    jmp cUpdate

cLfb:
    mov ax,flat_sel
    mov es,ax
;
    mov edi,ds:efi_lfb
    movzx ecx,ds:efi_height

cLoop:
    push ecx    
    mov ecx,ds:efi_scan_size    
    xor ax,ax
    rep stos byte ptr es:[edi]
    pop ecx
    loop cLoop

cUpdate:
    mov ds:efi_text_col,0
    mov ds:efi_text_row,0
;
    popad
    pop es
    pop ds    
    ret
Clear Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NewLine
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NewLine Proc near
    push ds
    push ax
    push dx
;
    mov ax,system_data_sel
    mov ds,ax

nlRetry:    
    mov al,' '
    call ShowChar
;
    mov dx,ds:efi_text_col
    or dx,dx
    jnz nlRetry
;
    pop dx
    pop ax
    pop ds
    ret
NewLine Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delimiter
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delimiter       Proc near
    push ax
    push ecx
    mov ecx,60
    mov al,'-'
    
write_delim_loop:
    call ShowChar
    loop write_delim_loop
;    
    pop ecx
    call NewLine
    pop ax
    ret
Delimiter       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Blank
;
;           DESCRIPTION:    
;
;           PARAMETERS:         ECX          Number of blanks to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Blank   Proc near
    push eax
    push ecx
    mov al,' '
    
blank_loop:
    call ShowChar
    loop blank_loop
    pop ecx
    pop eax
    ret
Blank   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowCodeAsciiz
;
;           DESCRIPTION:    Show asciiz string from code
;
;           PARAMETERS:     CS:ESI      String to add
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowCodeAsciiz   PROC near
    push ax

scaLoop:
    lods cs:[esi]
    or al,al
    jz scaDone
;
    call ShowChar
    jmp scaLoop    

scaDone:
    pop ax
    ret
ShowCodeAsciiz   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowCodeSizeString
;
;           DESCRIPTION:    
;
;           PARAMETERS:     CS:ESI       String
;                           ECX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowCodeSizeString Proc near
    push eax
    push ecx
    push esi
;
    or ecx,ecx
    jz scssDone

scssLoop:
    lods byte ptr cs:[esi]
    call ShowChar
    loop scssLoop    

scssDone:
    pop esi
    pop ecx
    pop eax    
    ret
ShowCodeSizeString Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AL          Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    PROC near
    push ax
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb write_byte_low1
;    
    add al,7

write_byte_low1:
    add al,'0'
    call ShowChar
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb write_byte_high1
;    
    add al,7

write_byte_high1:
    add al,'0'
    call ShowChar
    pop ax
    ret
WriteHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AX          Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    PROC near
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
    ret
WriteHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:         EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword   PROC near
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    ret
WriteHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     EDX:EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexQword   PROC near
    push eax
;    
    push eax
    mov eax,edx
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
;
    mov al,'_'
    call ShowChar
;
    pop eax
;    
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
;
    pop eax    
    ret
WriteHexQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexPtr16
;
;           DESCRIPTION:    
;
;           PARAMETERS:         DX          Segment
;                           BX          Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr16   PROC near
    push ax
    mov ax,dx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov ax,bx
    call WriteHexWord
    pop ax
    ret
WriteHexPtr16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexPtr32
;
;           DESCRIPTION:    
;
;           PARAMETERS:         DX          Segment
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr32   PROC near
    push eax
    mov ax,dx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov eax,ebx
    call WriteHexDword
    pop eax
    ret
WriteHexPtr32   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteEflags
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eflags_tab:
;
;           reset       set
et_cf   DB 'NC ',       'CY '
et_1    DB 0,0,0,       0,0,0
et_pf   DB 'PO ',       'PE '
et_3    DB 0,0,0,       0,0,0
et_af   DB 'NA ',       'AC '
et_5    DB 0,0,0,       0,0,0
et_zf   DB 'NZ ',       'ZR '
et_sf   DB 'PL ',       'NG '
et_tf   DB 0,0,0,       0,0,0
et_if   DB 'DI ',       'EI '
et_df   DB 'UP ',       'DN '
et_of   DB 'NV ',       'OV '
et_12   DB 0,0,0,       0,0,0
et_13   DB 0,0,0,       0,0,0
et_14   DB 'PR ' ,      'NT '
et_15   DB 0,0,0,       0,0,0
et_16   DB 0,0,0,       0,0,0
et_vm   DB 'PM ',       'VM '

iopl_text       DB ' IOPL=',0

WriteEflags     PROC near
    push eax
    push ecx
    push edx
    push esi
;    
    mov eax,dword ptr ds:[ebp].reg_eflags
    mov esi,OFFSET eflags_tab
    mov ecx,18
    
eflags_loop:
    push esi
;    
    mov dl,cs:[esi]
    or dl,dl
    je eflags_next
;
    test al,1
    jz eflags_write_one
;    
    add esi,3

eflags_write_one:
    call ShowCodeSizeString
    
eflags_next:
    pop esi
;
    shr eax,1
    add esi,6
;
    loop eflags_loop
;
    mov esi,OFFSET iopl_text
    call showCodeAsciiz
;    
    mov ax,word ptr ds:[ebp].reg_eflags
    shr ax,12
    and ax,3
    add al,'0'
    call ShowChar
;
    pop esi
    pop edx
    pop ecx
    pop eax    
    ret
WriteEflags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCore
;
;           DESCRIPTION:    Write core ID
;
;           PARAMETERS:     DS:EBP      Registers
;                           GS          Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

proc_tab    DB 'Processor=',0    

WriteCore   PROC near
    mov esi,OFFSET proc_tab
    call ShowCodeAsciiz
;
    mov ax,gs:ps_id
    call WriteHexWord
;    
    mov al,' '
    call ShowChar
    ret
WriteCore   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteThread
;
;           DESCRIPTION:    Write current thread
;
;           PARAMETERS:     DS:EBP      Registers
;                           GS          Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NoName DB 'No thread                       ', 0

WriteThread   PROC near
    push ds
    push esi
;    
    mov ax,gs:ps_curr_thread
    or ax,ax
    jz wtNoThread
;
    mov ds,ax
    mov esi,OFFSET thread_name
    mov ecx,32

wtLoop:
    lodsb
    call ShowChar
    loop wtLoop
;
    jmp wtDone

wtNoThread:
    mov esi,OFFSET NoName
    call ShowCodeAsciiz

wtDone:
    pop esi
    pop ds
    ret
WriteThread Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteTable
;
;           DESCRIPTION:    Write IDT and GDT
;
;           PARAMETERS:     DS:EBP      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

table_reg_tab:
    DB ' GDT='
    DD OFFSET reg_gdt
    DB ' IDT='
    DD OFFSET reg_idt
    DB 0

WriteTable   PROC near
    mov esi,OFFSET table_reg_tab

table_write_loop:
    mov al,cs:[esi]
    or al,al
    je table_write_end
;
    mov ecx,5
    call ShowCodeSizeString
;
    add esi,5
    mov ebx,cs:[esi]
    mov eax,ds:[ebx+ebp].d_base   
    call WriteHexDword
;    
    mov al,' '
    call ShowChar
;
    mov al,'('
    call ShowChar
;
    mov eax,ds:[ebx+ebp].d_limit
    call WriteHexWord       
;
    mov al,')'
    call ShowChar
;    
    add esi,4
    jmp table_write_loop

table_write_end:
    ret
WriteTable   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteSel
;
;           DESCRIPTION:    
;
;           PARAMETERS:     CS:ESI       Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sel_reg_tr:
    DB ' TR='
    DD OFFSET reg_tr

sel_reg_ldt:
    DB ' DT='
    DD OFFSET reg_ldt

sel_reg_cs:
    DB ' CS='
    DD OFFSET reg_cs

sel_reg_ds:
    DB ' DS='
    DD OFFSET reg_ds

sel_reg_es:    
    DB ' ES='
    DD OFFSET reg_es

sel_reg_fs:    
    DB ' FS='
    DD OFFSET reg_fs

sel_reg_gs:
    DB ' GS='
    DD OFFSET reg_gs

sel_reg_ss:    
    DB ' SS='
    DD OFFSET reg_ss

sel_reg_us:    
    DB ' US='
    DD OFFSET reg_usel

sel_type_tab:
st00 DB 'Invalid         '
st01 DB 'TSS 16, avail   '
st02 DB 'LDT             '
st03 DB 'TSS 16, busy    '
st04 DB 'Call gate 16    '
st05 DB 'Task gate       '
st06 DB 'Int gate 16     '
st07 DB 'Trap gate 16    '
st08 DB 'Invalid         '
st09 DB 'TSS 32, avail   '
st0A DB 'Invalid         '
st0B DB 'TSS 32, busy    '
st0C DB 'Call gate 32    '
st0D DB 'Invalid         '
st0E DB 'Int gate 32     '
st0F DB 'Trap gate 32    '
st10 DB 'Read, up        '
st11 DB 'Read, up        '
st12 DB 'Read/write, up  '
st13 DB 'Read/write, up  '
st14 DB 'Read, down      '
st15 DB 'Read, down      '
st16 DB 'Read/write, down'
st17 DB 'Read/write, down'
st18 DB 'Code            '
st19 DB 'Code            '
st1A DB 'Code/read       '
st1B DB 'Code/read       '
st1C DB 'Code conf       '
st1D DB 'Code conf       '
st1E DB 'Code/read conf  ' 
st1F DB 'Code/read conf  ' 

WriteSelReg   PROC near
    mov ecx,4
    call ShowCodeSizeString
;
    add esi,4
    mov ebx,cs:[esi]
;    
    movzx ebx,ds:[ebx+ebp].d_selector
    mov ax,bx
    call WriteHexWord
    mov al,' '
    call ShowChar
;    
    and bx,NOT 3
    or bx,bx
    jz write_sel_done
;
    call GetSelectorBaseSizeType
    mov bl,al
    mov eax,edx
    call WriteHexDword
;
    mov al,' '
    call ShowChar
    mov al,'('
    call ShowChar
;
    mov eax,ecx
    call WriteHexDword
;
    mov al,')'
    call ShowChar    
    mov al,' '
    call ShowChar
;
    movzx esi,bl
    and si,01Fh
    shl esi,4
    add esi,OFFSET sel_type_tab
    mov ecx,16
    call ShowCodeSizeString

write_sel_done:
    ret
WriteSelReg   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteDwordRegs
;
;           DESCRIPTION:    Write 32-bit registers
;
;           PARAMETERS:     CS:ESI       Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dword_irq_tab:
    DB ' IRQ='
    DD OFFSET curr_irq
    DW 0

dword_cr_reg_tab:
    DB ' CR0='
    DD OFFSET reg_cr0
    DB ' CR2='
    DD OFFSET reg_cr2
    DB ' CR3='
    DD OFFSET reg_cr3
    DB ' CR4='
    DD OFFSET reg_cr4
    DB 0

dword_dr_reg_tab:
    DB ' DR0='
    DD OFFSET reg_dr0
    DB ' DR1='
    DD OFFSET reg_dr1
    DB ' DR2='
    DD OFFSET reg_dr2
    DB ' DR3='
    DD OFFSET reg_dr3
    DB 0

dword_reg_tab1:
    DB ' EAX='
    DD OFFSET reg_eax
    DB ' EBX='
    DD OFFSET reg_ebx
    DB ' ECX='
    DD OFFSET reg_ecx
    DB ' EDX='
    DD OFFSET reg_edx
    DB 0

dword_reg_tab2:
    DB ' ESI='
    DD OFFSET reg_esi
    DB ' EDI='
    DD OFFSET reg_edi
    DB ' ESP='
    DD OFFSET reg_esp
    DB ' EBP='
    DD OFFSET reg_ebp
    DB 0

dword_reg_tab3:
    DB ' EPC='
    DD OFFSET reg_eip
    DB 0

WriteDwordRegs  PROC near

dword_write_loop:
    mov al,cs:[esi]
    or al,al
    je dword_write_end
;
    mov ecx,5
    call ShowCodeSizeString
    add esi,5
    mov ebx,cs:[esi]
    mov eax,ds:[ebx+ebp]
    call WriteHexDword
    add esi,4
    jmp dword_write_loop

dword_write_end:
    ret
WriteDwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteQwordRegs
;
;           DESCRIPTION:    Write 64-bit register
;
;           PARAMETERS:     CS:ESI       Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

qword_reg_tab1:
    DB ' RAX='
    DD OFFSET reg_eax
    DB ' RBX='
    DD OFFSET reg_ebx
    DB ' RCX='
    DD OFFSET reg_ecx
    DB 0

qword_reg_tab2:
    DB ' RDX='
    DD OFFSET reg_edx
    DB ' RSI='
    DD OFFSET reg_esi
    DB ' RDI='
    DD OFFSET reg_edi
    DB 0

qword_reg_tab3:
    DB '  R8='
    DD OFFSET reg_r8
    DB '  R9='
    DD OFFSET reg_r9
    DB ' R10='
    DD OFFSET reg_r10
    DB 0

qword_reg_tab4:
    DB ' R11='
    DD OFFSET reg_r11
    DB ' R12='
    DD OFFSET reg_r12
    DB ' R13='
    DD OFFSET reg_r13
    DB 0

qword_reg_tab5:
    DB ' R14='
    DD OFFSET reg_r14
    DB ' R15='
    DD OFFSET reg_r15
    DB 0

qword_reg_tab6:
    DB ' RIP='
    DD OFFSET reg_eip
    DB ' RSP='
    DD OFFSET reg_esp
    DB ' RBP='
    DD OFFSET reg_ebp
    DB 0

WriteQwordRegs  PROC near

qword_write_loop:
    mov al,cs:[esi]
    or al,al
    je qword_write_end
;
    mov ecx,5
    call ShowCodeSizeString
    add esi,5
    mov ebx,cs:[esi]
    mov eax,ds:[ebx+ebp]
    mov edx,ds:[ebx+ebp+4]
    call WriteHexQword
    add esi,4
    jmp qword_write_loop

qword_write_end:
    ret
WriteQwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteFault
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_code_tab:
ke00    DB 'Divide error            '
ke01    DB 'Single step             '
ke02    DB 'NMI                     '
ke03    DB 'Breakpoint              '
ke04    DB 'Overflow                '
ke05    DB 'Array bounds error      '
ke06    DB 'Invalid OP-code         '
ke07    DB '80387 not present       '
ke08    DB 'Double fault            '
ke09    DB '80387 overrun           '
ke0A    DB 'Invalid TSS             '
ke0B    DB 'Segment not present     '
ke0C    DB 'Stack fault             '
ke0D    DB 'Protection fault        '
ke0E    DB 'Page fault              '
ke0F    DB '                        '
ke10    DB '80387 error             '
ke11    DB 'Cannot emulate          '
ke12    DB 'Cannot emulate 80387    '
ke13    DB 'Now in real mode        '
ke14    DB '----------------------- '
ke15    DB 'Illegal int request     '
ke16    DB 'Undefined method        '
ke17    DB 'Invalid handle          '
ke18    DB 'Invalid selector        '
ke19    DB 'NMI                     '
ke1A    DB 'Crash Gate              '

WriteFault    Proc near
    mov al,' '
    call ShowChar
;    
    movzx edx,ds:[ebp].fault_vect
    cmp dl,1Ah
    jbe wfDo
;
    mov dl,14h    

wfDo:
    mov ebx,edx
    add ebx,ebx
    add ebx,ebx
    add ebx,ebx
    mov ecx,ebx
    add ecx,ecx
    add ebx,ecx
    mov esi,OFFSET error_code_tab
    add esi,ebx
    mov ecx,24
    call ShowCodeSizeString
    ret
WriteFault    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteProcFlags
;
;           DESCRIPTION:    Write processor flag registers
;
;           PARAMETERS:     DS:EBP      Registers
;                           GS          Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nest_text       DB 'Nesting=',0
flag_preempt    DB 'Preempt ',0
flag_prio       DB 'Prio ',0
flag_timer      DB 'Timer ',0

WriteProcFlags     PROC near
    push fs
;    
    mov esi,OFFSET nest_text
    call ShowCodeAsciiz
;    
    mov ax,gs:ps_nesting
    call WriteHexWord
;
    mov al,' '
    call ShowChar
;
    test gs:ps_flags,PS_FLAG_PREEMPT
    jz wpfNoPreempt
;
    mov esi, OFFSET flag_preempt
    call ShowCodeAsciiz

wpfNoPreempt:    
    test gs:ps_flags,PS_FLAG_PRIO_CHANGE
    jz wpfNoPrio
;
    mov esi, OFFSET flag_prio
    call ShowCodeAsciiz

wpfNoPrio:
    pop fs
    ret
WriteProcFlags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteDataRow
;
;       DESCRIPTION:    Write a data row
;
;       PARAMETERS:     DS:EBP      Cpu registers
;                       GS          Core regs
;                       BX:EDX      Address
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDataRow    Proc near
    mov ax,bx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov eax,edx
    call WriteHexDword
    mov al,' '
    call ShowChar
;    
    push edx
    call GetSelectorBaseSizeType
    mov ebx,edx    
    pop edx
;
    pushf
    add ebx,edx
    popf
;    
    mov esi,ecx
;
    push ebx
    push esi
;    
    mov ecx,16    
    pushf

wrDataLoop:
    popf
    jc wrDataInv
;    
    cmp esi,eax
    jc wrDataInv 
;    
    push edx
;
    xor edi,edi
    call ReadLinearByte
    jc wrDataUndef
;    
    call WriteHexByte
    jmp wrDataPop

wrDataUndef:
    mov al,'%'
    call ShowChar
    call ShowChar

wrDataPop:
    pop edx
    clc
    jmp wrDataNext

wrDataInv:
    mov al,'!'
    call ShowChar
    call ShowChar
    stc

wrDataNext:
    pushf
    add ebx,1
    loop wrDataLoop
;
    popf    
    pop esi
    pop ebx
;    
    mov ecx,16    
    pushf

wrCharLoop:
    popf
    jc wrCharInv
;    
    cmp esi,ebx
    jc wrCharInv 
;    
    push edx
;
    xor edi,edi
    call ReadLinearByte
    jc wrCharUndef
;    
    call ShowChar
    jmp wrCharPop

wrCharUndef:
    mov al,'%'
    call ShowChar

wrCharPop:
    pop edx
    clc
    jmp wrCharNext

wrCharInv:
    mov al,'!'
    call ShowChar
    stc

wrCharNext:
    pushf
    add ebx,1
    loop wrCharLoop
;
    popf    
    ret
WriteDataRow    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCpuReg32
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg32     Proc near
    call WriteCore
    call WriteThread
    call NewLine    
;
    call WriteTable
    mov esi,OFFSET dword_irq_tab
    call WriteDwordRegs
    call NewLine    
;
    mov esi,OFFSET dword_cr_reg_tab
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET dword_dr_reg_tab
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET dword_reg_tab1
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET dword_reg_tab2
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET dword_reg_tab3
    call WriteDwordRegs
    call WriteFault
;    call WriteInstr
    call NewLine
;
    mov esi,OFFSET sel_reg_tr
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ldt
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_cs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ds
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_es
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_fs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_gs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ss
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_us
    call WriteSelReg
    call NewLine
;
    call WriteEflags
    call NewLine
;
    call WriteProcFlags
    call NewLine
;
    call Delimiter
;    
    mov bx,ds:[ebp].reg_ss.d_selector
    mov edx,ds:[ebp].reg_esp
    call WriteDataRow
    call NewLine    
;    
    mov bx,ds:[ebp].reg_cs.d_selector
    mov edx,ds:[ebp].reg_eip
    call WriteDataRow
    call NewLine    
;    
    mov bx,ds:[ebp].reg_usel.d_selector
    mov edx,ds:[ebp].reg_uoffs
    call WriteDataRow
    call NewLine    
    ret
WriteCpuReg32     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCpuReg64
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg64     Proc near
    call WriteCore
    call WriteThread
    call NewLine    
;
    call WriteTable
    mov esi,OFFSET dword_irq_tab
    call WriteDwordRegs
    call NewLine    
;
    mov esi,OFFSET dword_cr_reg_tab
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab1
    call WriteQwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab2
    call WriteQwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab3
    call WriteQwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab4
    call WriteQwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab5
    call WriteQwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab6
    call WriteQwordRegs
    call NewLine
;
    call WriteFault
;    call WriteInstr
    call NewLine
;
    mov esi,OFFSET sel_reg_tr
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ldt
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_cs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ds
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_es
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_fs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_gs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ss
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_us
    call WriteSelReg
    call NewLine
;
    call WriteEflags
    call NewLine
;
    call WriteProcFlags
    call NewLine
;
    call Delimiter
;    
    mov bx,ds:[ebp].reg_ss
    mov edx,ds:[ebp].reg_esp
    call WriteDataRow
    call NewLine    
;    
    mov bx,ds:[ebp].reg_cs
    mov edx,ds:[ebp].reg_eip
    call WriteDataRow
    call NewLine    
;    
    mov bx,ds:[ebp].reg_usel
    mov edx,ds:[ebp].reg_uoffs
    call WriteDataRow
    call NewLine    
    pop es
    ret
WriteCpuReg64     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Read_mem
;
;           DESCRIPTION:    Read memory in process
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           DS:EBP      Cpu
;                           GS          Core sel
;
;           RETURNS:        NC  AL  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_mem    Proc near
    push ebx
    push ecx
    push edx
    push edi
;
    mov bx,dx
    call GetSelectorBaseSizeType
    jc rmDone
;
    cmp ecx,esi 
    jc rmDone
;
    add edx,esi
    mov ebx,edx
    xor edi,edi
    call ReadLinearByte    

rmDone:
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret
read_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Write_mem
;
;           DESCRIPTION:    Write memory in process
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           GS          Thread
;                           DS:EBP      Cpu
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_mem    Proc near
    push eax
    push ebx
    push ecx
    push edx
    push edi
;
    push ax
    mov bx,dx
    call GetSelectorBaseSizeType
    jc wmPop
;
    cmp ecx,esi 
    jc wmPop
;
    add edx,esi
    mov ebx,edx
    xor edi,edi
    pop ax
    call WriteLinearByte    
    jmp wmDone

wmPop:
    pop ax

wmDone:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
write_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ConvertSelector
;
;           DESCRIPTION:    Convert selector to descriptor
;
;           PARAMETERS:     DS:EBP      Cpu
;                           DS:ESI      Descriptor
;                           BX          Selector 
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvertSelector      Proc near
    mov ds:[esi].d_selector,bx
;
    call GetSelectorBaseSizeType
    jc csFail
;
    mov ds:[esi].d_limit,ecx
    mov ds:[esi].d_base,edx
;
    xor dx,dx
    test ah,40h
    jz csSizeOk
;
    or dx,ACCESS_32    

csSizeOk:
    test al,8
    jz csDataSel

csCodeSel:
    test ah,20h
    jz csLongOK
;
    or dx,ACCESS_64

csLongOk:
    test al,2
    jz csSaveAccess
;
    or dx,ACCESS_READ
    jmp csSaveAccess

csDataSel:    
    or dx,ACCESS_READ
    test al,2
    jz csSaveAccess
;
    or dx,ACCESS_WRITE    

csSaveAccess:
    mov ds:[esi].d_access,dx
    jmp csDone

csFail:
    mov ds:[esi].d_limit,0
    mov ds:[esi].d_base,0
    mov ds:[esi].d_access,0

csDone:        
    ret
ConvertSelector      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDebugCoreData
;
;           DESCRIPTION:    Get debug core data
;
;           PARAMETERS:     DS:EBP      Cpu data
;                           GS          Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDebugCoreData      Proc near
    pushad
;    
    mov ds:[ebp].cpu_read_mem,OFFSET read_mem
    mov ds:[ebp].cpu_write_mem,OFFSET write_mem
;    
    mov eax,cr0
    mov ds:[ebp].reg_cr0,eax
;
    mov eax,cr2
    mov ds:[ebp].reg_cr2,eax
;
    mov eax,cr3
    mov ds:[ebp].reg_cr3,eax
;
    mov eax,cr4
    mov ds:[ebp].reg_cr4,eax
;
    mov eax,dr0
    mov ds:[ebp].reg_dr0,eax               
;
    mov eax,dr1
    mov ds:[ebp].reg_dr1,eax               
;
    mov eax,dr2
    mov ds:[ebp].reg_dr2,eax               
;
    mov eax,dr6
    mov ds:[ebp].reg_dr6,eax               
;
    mov eax,dr7
    mov ds:[ebp].reg_dr7,eax               
;
    mov eax,dr0
    mov ds:[ebp].reg_dr0,eax               
;
    sgdt fword ptr ds:temp_size
    movzx eax,ds:temp_size
    mov ds:[ebp].reg_gdt.d_limit,eax
    mov eax,ds:temp_base
    mov ds:[ebp].reg_gdt.d_base,eax
;
    sidt fword ptr ds:temp_size
    movzx eax,ds:temp_size
    mov ds:[ebp].reg_idt.d_limit,eax
    mov eax,ds:temp_base
    mov ds:[ebp].reg_idt.d_base,eax
;
    mov ds:[ebp].reg_ldt.d_limit,0
    mov ds:[ebp].reg_ldt.d_base,0
    sldt bx
    mov ds:[ebp].reg_ldt.d_selector,bx
    call GetSelectorBaseSizeType
    jc gdcLdtDone
;
    mov ds:[ebp].reg_ldt.d_limit,ecx
    mov ds:[ebp].reg_ldt.d_base,edx

gdcLdtDone:    
    mov ds:[ebp].reg_tr.d_limit,0
    mov ds:[ebp].reg_tr.d_base,0
    str bx
    mov ds:[ebp].reg_tr.d_selector,bx
    call GetSelectorBaseSizeType
    jc gdcTrDone
;
    mov ds:[ebp].reg_tr.d_limit,ecx
    mov ds:[ebp].reg_tr.d_base,edx

gdcTrDone:    
    mov bx,cs
    lea esi,[ebp].reg_cs
    call ConvertSelector
;
    mov bx,ss
    lea esi,[ebp].reg_ss
    call ConvertSelector
;
    mov bx,ds
    lea esi,[ebp].reg_ds
    call ConvertSelector
;
    mov bx,es
    lea esi,[ebp].reg_es
    call ConvertSelector
;
    mov bx,fs
    lea esi,[ebp].reg_fs
    call ConvertSelector
;
    mov bx,gs
    lea esi,[ebp].reg_gs
    call ConvertSelector
;
    mov bx,flat_sel
    lea esi,[ebp].reg_usel
    call ConvertSelector
;
    popad
    ret
GetDebugCoreData      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           test_pr
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_name  DB 'Crash Thread', 0

test_pr:
    int 3
    mov ax,SEG data
    mov ds,ax
;    
    mov ebp,OFFSET cpu1
    GetCore
;
    mov ax,fs
    mov gs,ax
    call GetDebugCoreData
;
    mov bx,cs
    call GetSelectorBaseSizeType
    mov ebx,edx
    add ebx,OFFSET test_pr
    xor edi,edi
    call MapLinear

        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitCrashShow
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_crash

init_crash    Proc near
    push ds
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov ds:curr_pos,0
    mov ds:view_type,'R'
;
    mov eax,1000h
    AllocateBigLinear
    mov ds:map_linear,edx    
    xor ebx,ebx
    mov eax,67h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov ds:map_sel,bx    
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET test_pr
    mov edi,OFFSET test_name
    mov ecx,stack0_size
    mov ax,26
    CreateProcess
;        
    popad
    pop ds
    ret
init_crash    Endp

code    ENDS

    END
