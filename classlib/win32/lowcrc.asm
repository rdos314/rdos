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
