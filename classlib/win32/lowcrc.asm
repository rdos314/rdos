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
; LOWCRC.ASM
; CRC calculation basis
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME lowcrc


	.386
	.model flat

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

	.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Win32InitCrc
;
;		DESCRIPTION:	Init CRC buffer
;
;		PARAMETERS:	    256 word Buf
;                       Poly
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _Win32InitCrc@8

ccBuf		EQU 8
ccPoly		EQU 12

_Win32InitCrc@8	Proc
	push ebp
	mov ebp,esp
	push esi
;	
	mov esi,[ebp].ccBuf
	mov ax,[ebp].ccPoly
;
    xor cl,cl
    
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
    mov [esi],dx
    add esi,2
;
    inc cl
    or cl,cl
    jnz create_crc_loop
; 
    pop esi
    pop ebp
    ret 8
_Win32InitCrc@8	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Win32CalcCrc
;
;		DESCRIPTION:	Calculate CRC
;
;		PARAMETERS:		256 word Buf
;                       CRC in
;						Data
;						Size
;
;		RETURNS:		CRC out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	public _Win32CalcCrc@16

cacBuf		EQU 8
cacCrc		EQU 12
cacData     EQU 16
cacSize     EQU 20

_Win32CalcCrc@16	Proc
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;	
    mov ax,[ebp].cacCrc
	mov esi,[ebp].cacBuf
    mov ecx,[ebp].cacSize
    mov edi,[ebp].cacData
;
    or ecx,ecx
    jz calc_crc_done
;    
    xor ebx,ebx

calc_crc_loop:
    mov bl,[edi]    
    xor bl,ah
    shl ax,8
    xor ax,ds:[esi+2*ebx]
;
    inc edi
    sub ecx,1
    jnz calc_crc_loop    

calc_crc_done:
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret 16
_Win32CalcCrc@16	Endp

	END
