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
; RDFSMISC.ASM
; Untilty functions for RDFS (RDOS File System)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME rdfsmisc

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
	rep movs byte ptr es:[edi],[esi]
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

