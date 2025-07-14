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
; RDFSMISC.ASM
; Untilty functions for RDFS (RDOS File System)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE rdfs.inc

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn CryptTab:near
	extrn KeyTab:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			decrypt
;
;		DESCRIPTION:	Decrypt a sector
;
;		PARAMETERS:		BP			Offset & bias
;						ES:ESI		Crypted sector data
;						ES:EDI		Decrypted sector data
;
;		RETURNS:		AH			Checksum
;						BP			Updated offset
;		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public decrypt

decrypt	Proc near
	push ebx
	push cx
	push edx
	push esi
	push edi
;
	mov ax,bp
	and ah,0F0h
	shr ah,4
	and al,3
	shl al,4
	or al,ah
	mov cx,80h
	mov dl,al
	shl dx,8
	mov dl,al
	shl edx,8
	mov dl,al
	shl edx,8
	mov dl,al
	xor ebx,ebx
	
decrypt_loop:
	and bp,0FFCh
	lods dword ptr es:[esi]
	xor eax,dword ptr cs:[bp].CryptTab
	xor eax,edx
	stos dword ptr es:[edi]
	xor ebx,eax
	add bp,4
	loop decrypt_loop
;
	mov ah,bl
	shr ebx,8
	xor ah,bl
	shr ebx,8
	xor ah,bl
	shr bx,8
	xor ah,bl
;
	pop edi
	pop esi
	pop edx
	pop cx
	pop ebx
	ret
decrypt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_PARAM
;
;		DESCRIPTION:	READ DRIVE PARAMS FROM BOOT RECORD
;
;		RETRUNS:		DS			ADDRESS TO DRIVE DATA
;						ES			FLAT_SEL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public get_param

get_param	Proc near
	push ax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov ds:drive_nr,al
	mov edx,1
	LockSector
	push ds
	push es
	mov ax,ds
	mov dx,es
	mov ds,dx
	mov es,ax
	mov edi,OFFSET info_sector
	mov ecx,SIZE rdfs_info_struc
	rep movs byte ptr es:[edi],ds:[esi]
	pop es
	pop ds
	UnlockSector
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ax
	ret
get_param	Endp

code	ENDS

	END

