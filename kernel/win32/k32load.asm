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
; K32LOAD.ASM
; 32-bit kernel32.dll loader support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  k32load

;;;;;;;;; INTERNAL ProcEDURES ;;;;;;;;;;;

.386p
.model flat

include ..\os\user.def

UserGate	MACRO gate_nr
	db 0Fh
	db 0Bh
	db 0D7h
	dd gate_nr
	nop
			ENDM

tib_data	STRUC

pvFirstExcept		DD ?
pvStackUserTop		DD ?
pvStackUserBottom	DD ?
pvLastError			DD ?
pvResv1				DD ?
pvArbitrary			DD ?
pvTEB				DD ?
pvResv2				DD ?,?
pvModuleHandle		DD ?
pvTLSBitmap			DD ?
pvTLSArray			DD ?

tib_data	ENDS

.code
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeLibrary
;
;       DESCRIPTION:    Free library
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FreeLibrary

flHandle	EQU 8

FreeLibrary Proc near
	push ebp
	mov ebp,esp
	push ebx
	mov ebx,[ebp].flHandle
	UserGate free_dll_nr
;
	pop ebx
	pop ebp
	ret 4
FreeLibrary	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LoadLibraryEx
;
;       DESCRIPTION:    Load libary extended
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadLibraryExA

lleFile		EQU 8
llehFile	EQU 12
lleFlags	EQU 16

LoadLibraryExA Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp].lleFile
	UserGate load_dll_nr
	jc lleFailed
;
	mov eax,ebx
	jmp lleDone

lleFailed:
	xor eax,eax
	jmp lleDone

lleDone:
	pop edi
	pop ebx
	pop ebp
	ret 12
LoadLibraryExA Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LoadLibrary
;
;       DESCRIPTION:    Load libary
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadLibraryA

llFile		EQU 8

LoadLibraryA Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp].llFile
	UserGate load_dll_nr
	jc llFailed
;
	mov eax,ebx
	jmp llDone

llFailed:
	xor eax,eax
	jmp llDone

llDone:
	pop edi
	pop ebx
	pop ebp
	ret 4
LoadLibraryA Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetModuleHandleA
;
;       DESCRIPTION:    Get module handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetModuleHandleA

gmhFile	EQU 8

GetModuleHandleA Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp].gmhFile
	or edi,edi
	jnz gmhNotDefault
;
	mov eax,fs:pvModuleHandle
	jmp gmhDone

gmhNotDefault:
	UserGate get_dll_nr
	jc gmhFailed
;
	mov eax,ebx
	jmp gmhDone

gmhFailed:
	xor eax,eax
	jmp gmhDone

gmhDone:
	pop edi
	pop ebx
	pop ebp
	ret 4
GetModuleHandleA Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetModuleFileName
;
;       DESCRIPTION:    Get module file name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetModuleFileNameA
	public GetModuleFileNameW

gmfHandle	EQU 8
gmfBuf		EQU 12
gmfSize		EQU 16

GetModuleFileNameA Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov ebx,[ebp].gmfHandle
	mov ecx,[ebp].gmfSize
	mov edi,[ebp].gmfBuf
	UserGate get_dll_name_nr
	jnc gmfaDone
;
	xor eax,eax

gmfaDone:
	pop edi
	pop ebx
	pop ebp
	ret 12
GetModuleFileNameA Endp

GetModuleFileNameW Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
	mov ecx,256
	sub esp,ecx
;
	int 3
	mov ebx,[ebp].gmfHandle
	mov edi,esp
	UserGate get_dll_name_nr
	jnc gmfwCopy
;
	xor eax,eax
	jmp gmfwDone

gmfwCopy:
	mov edx,eax
	xor eax,eax
	mov esi,esp
	mov ecx,[ebp].gmfSize
	mov edi,[ebp].gmfBuf
	or ecx,ecx
	jz gmfwCopied

gmfwLoop:
	or edx,edx
	jz gmfwCopied
	lodsb
	stosw
	loop gmfwLoop	

gmfwCopied:
	mov eax,[ebp].gmfSize
	sub eax,ecx
	
gmfwDone:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 12
GetModuleFileNameW Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProcAddress
;
;       DESCRIPTION:    Get proc address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetProcAddress

gpaHandle	EQU 8
gpaProc		EQU 12

GetProcAddress Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov ebx,[ebp].gpaHandle
	mov edi,[ebp].gpaProc
	UserGate get_dll_proc_nr
	jc gpaFail
;
	mov eax,esi
	jmp gpaDone

gpaFail:
	xor eax,eax

gpaDone:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 8
GetProcAddress Endp

		END
