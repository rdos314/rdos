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
; CRC.ASM
; CRC calculation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.inc
INCLUDE ..\handle.inc

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

crc_handle_seg      STRUC

crc_handle_base     handle_header <>

crc_handle_sel      DW ?

crc_handle_seg      ENDS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateCrc
;
;           DESCRIPTION:    Creates CRC handle
;
;           PARAMETERS:     AX      CRC polynom
;
;           RETURNS:        BX              Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_crc_name DB 'Create CRC', 0

create_crc      Proc far
    push ds
    push es
    push cx
    push dx
    push si
;
    push eax
    mov eax,200h
    AllocateSmallGlobalMem    
    pop eax
;
    mov cx,SIZE crc_handle_seg
    AllocateHandle
    mov [ebx].crc_handle_sel,es
    mov [ebx].hh_sign,CRC_HANDLE
    mov bx,[ebx].hh_handle
;
    push bx
    xor cl,cl
    xor bx,bx
    
create_crc_loop:   
    xor dx,dx
    xor dh,cl
    shl dx,1
    jnc no_xor0
;
    xor dx,ax

no_xor0:
    shl dx,1
    jnc no_xor1
;
    xor dx,ax 

no_xor1:       
    shl dx,1
    jnc no_xor2
;
    xor dx,ax 

no_xor2:       
    shl dx,1
    jnc no_xor3
;
    xor dx,ax 

no_xor3:       
    shl dx,1
    jnc no_xor4
;
    xor dx,ax 

no_xor4:       
    shl dx,1
    jnc no_xor5
;
    xor dx,ax 

no_xor5:       
    shl dx,1
    jnc no_xor6
;
    xor dx,ax 

no_xor6:       
    shl dx,1
    jnc no_xor7
;
    xor dx,ax 

no_xor7:      
    mov es:[bx],dx
    add bx,2
    inc cx
    or cl,cl
    jnz create_crc_loop
; 
    pop bx      
    clc
;
    pop si
    pop dx
    pop cx
    pop es
    pop ds
    retf32
create_crc      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseCrc
;
;           DESCRIPTION:    Close CRC handle
;
;           PARAMETERS:     BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_crc_name DB 'Close CRC', 0

close_crc       Proc far
    push ds
    push es
    push ebx
;
    mov ax,CRC_HANDLE
    DerefHandle
    jc close_crc_done
;
    mov es,[ebx].crc_handle_sel
    FreeMem    
    FreeHandle
    clc

close_crc_done:
    pop ebx
    pop es
    pop ds
    retf32
close_crc       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CalcCrc
;
;           DESCRIPTION:    Calculate CRC
;
;           PARAMETERS:         BX              Handle
;               AX      CRC in
;                           ES:(E)DI    Data
;                           (E)CX       Size
;
;           RETURNS:        AX      CRC out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

calc_crc_name   DB 'Calc CRC',0

calc_crc Proc near
    push ds
    push es
    push ebx
    push ecx
    push edi
;
    push ax
    mov ax,CRC_HANDLE
    DerefHandle
    pop ax
    jc calc_crc_done
;
    mov ds,[ebx].crc_handle_sel
    or ecx,ecx
    jz calc_crc_done
;
    xor ebx,ebx

calc_crc_loop:
    mov bl,es:[edi]
    xor bl,ah
    shl ax,8
    xor ax,ds:[2*ebx]
;
    inc edi
    sub ecx,1
    jnz calc_crc_loop    

calc_crc_done:
    pop edi
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
calc_crc    Endp

calc_crc32  Proc far
    call calc_crc
    retf32
calc_crc32  Endp

calc_crc16  Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call calc_crc
;
    pop edi
    pop ecx
    retf32
calc_crc16  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete_handle
;
;           DESCRIPTION:    Delete handle (called from handle module)
;
;           PARAMETERS:         BX          CRC HANDLE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push es
    push ebx
;
    mov ax,CRC_HANDLE
    DerefHandle
    jc delete_handle_done
;
    mov es,bx
    FreeMem
    FreeHandle
    clc

delete_handle_done:
    pop ebx
    pop es
    pop ds
    retf32
delete_handle   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_crc
    
init_crc    PROC near
    push ds
    push es
    pusha
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET delete_handle
    mov ax,CRC_HANDLE
    RegisterHandle
;
    mov esi,OFFSET create_crc
    mov edi,OFFSET create_crc_name
    xor dx,dx
    mov ax,create_crc_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_crc
    mov edi,OFFSET close_crc_name
    xor dx,dx
    mov ax,close_crc_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET calc_crc16
    mov esi,OFFSET calc_crc32
    mov edi,OFFSET calc_crc_name
    mov dx,virt_es_in
    mov ax,calc_crc_nr
    RegisterUserGate
;
    popa
    pop es
    pop ds      
    ret
init_crc    ENDP

code    ENDS

    END
