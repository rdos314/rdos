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
; K32MEM.ASM
; 32-bit kernel32.dll memory support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  k32mem

;;;;;;;;; INTERNAL ProcEDURES ;;;;;;;;;;;

.386p
.model flat

include ..\os\user.def

UserGate	MACRO gate_nr
	db 9Ah
	dd gate_nr
	dw 2
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

PAGE_NOACCESS = 1
PAGE_READONLY = 2
PAGE_READWRITE = 4
PAGE_WRITECOPY = 8
PAGE_EXECUTE = 10h
PAGE_EXECUTE_READ = 20h
PAGE_EXECUTE_READWRITE = 40h
PAGE_EXECUTE_WRITECOPY = 80h
PAGE_GUARD = 100h
PAGE_NOCACHE = 200h

MEM_COMMIT = 1000h
MEM_RESERVE = 2000h
MEM_DECOMMIT = 4000h
MEM_RELEASE = 8000h
MEM_FREE = 10000h
MEM_PRIVATE = 20000h
MEM_MAPPED = 40000h
MEM_TOP_DOWN = 100000h

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           VirtualAlloc
;
;       DESCRIPTION:    Allocate linear memory
;
;		PARAMETERS:	    LPVOID lpAddress,		address of region to reserve or commit  
;					    DWORD dwSize			size of region 
;					    DWORD flAllocationType	type of allocation 
;					    DWORD flProtect 		type of access protection 
;
;		RETURNS:		Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public VirtualAlloc

VirtualAlloc_lpAddress			EQU 8
VirtualAlloc_dwSize				EQU 12
VirtualAlloc_flAllocationType	EQU 16
VirtualAlloc_flProtect			EQU 20

VirtualAlloc	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov eax,[ebp].VirtualAlloc_flAllocationType
	test eax,MEM_COMMIT OR MEM_RESERVE
	jz VirtualAllocFail
;
	mov eax,[ebp].VirtualAlloc_dwSize
	mov edx,[ebp].VirtualAlloc_lpAddress
	or edx,edx
	jne VirtualAllocSetAccess
;
	UserGate allocate_app_mem_nr	

VirtualAllocSetAccess:
	mov ebx,[ebp].VirtualAlloc_flAllocationType
	test ebx,MEM_COMMIT
	jnz VirtualAllocOk
	UserGate set_flat_linear_invalid_nr
	mov ebx,[ebp].VirtualAlloc_flProtect
	jmp VirtualAllocProtectCheckRead

VirtualAllocOk:
	mov ebx,[ebp].VirtualAlloc_flProtect
	test ebx,PAGE_NOACCESS OR PAGE_GUARD
	jz VirtualAllocProtectValid
	UserGate set_flat_linear_invalid_nr
	jmp VirtualAllocProtectCheckRead

VirtualAllocProtectValid:
	UserGate set_flat_linear_valid_nr

VirtualAllocProtectCheckRead:
	test ebx,PAGE_READONLY OR PAGE_EXECUTE OR PAGE_EXECUTE_READ
	jz VirtualAllocProtectWrite
	UserGate set_flat_linear_read_nr
	jmp VirtualAllocProtectDone

VirtualAllocProtectWrite:
	UserGate set_flat_linear_readwrite_nr

VirtualAllocProtectDone:
	mov eax,edx
	jmp VirtualAllocDone

VirtualAllocFail:
	xor eax,eax

VirtualAllocDone:
;
	pop edi
	pop ebx
	pop ebp
	ret 16
VirtualAlloc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           VirtualFree
;
;       DESCRIPTION:    Free linear memory
;
;		PARAMETERS:	    LPVOID lpAddress		address of region of committed pages  
;						DWORD dwSize			size of region 
;						DWORD dwFreeType		type of free operation 
;
;		RETURNS:		0 if failed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public VirtualFree

VirtualFree_lpAddress		EQU 8
VirtualFree_dwSize			EQU 12
VurtualFree_dwFreeType		EQU 16

VirtualFree	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov edx,[ebp].VirtualFree_lpAddress
	mov eax,[ebp].VirtualFree_dwSize
	UserGate free_app_mem_nr
	mov eax,1
;
	pop ebx
	pop ebp
	ret 12
VirtualFree	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           VirtualQuery
;
;       DESCRIPTION:    Query status of memory
;
;		PARAMETERS:		LPCVOID lpAddress					address of region 
;						PMEMORY_BASIC_INFORMATION lpBuffer	address of information buffer  
;						DWORD dwLength						size of buffer 
;
;		RETURNS:		0 if failed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public VirtualQuery

VirtualQuery_lpAddress			EQU 8
VirtualQuery_lpBuffer			EQU 12
VirtualQuery_dwLength			EQU 16

VirtualQuery	Proc
	push ebp
	mov ebp,esp
;
	xor eax,eax
;
	pop ebp
	ret 12
VirtualQuery	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalAlloc
;
;       DESCRIPTION:    Global alloc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 public GlobalAlloc

GlobalAlloc Proc near
	int 3
	xor eax,eax
	ret 8
GlobalAlloc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalReAlloc
;
;       DESCRIPTION:    Global realloc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GlobalReAlloc

GlobalReAlloc Proc near
	int 3
	xor eax,eax
	ret 12
GlobalReAlloc Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalFree
;
;       DESCRIPTION:    Global free
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GlobalFree

GlobalFree Proc near
	int 3
	xor eax,eax
	ret 4
GlobalFree Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalLock
;
;       DESCRIPTION:    Global lock
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GlobalLock

GlobalLock Proc near
	int 3
	xor eax,eax
	ret 4
GlobalLock Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalUnlock
;
;       DESCRIPTION:    Global unlock
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GlobalUnlock

GlobalUnlock Proc near
	int 3
	xor eax,eax
	ret 4
GlobalUnlock Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalSize
;
;       DESCRIPTION:    Global size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GlobalSize

GlobalSize Proc near
	int 3
	xor eax,eax
	ret 4
GlobalSize Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalHandle
;
;       DESCRIPTION:    Global handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GlobalHandle

GlobalHandle Proc near
	int 3
	xor eax,eax
	ret 4
GlobalHandle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalFlags
;
;       DESCRIPTION:    Global flags
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GlobalFlags

GlobalFlags Proc near
	int 3
	mov eax,8000h
	ret 4
GlobalFlags Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalAlloc
;
;       DESCRIPTION:    Local alloc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LocalAlloc

laFlags EQU 8
laBytes EQU 12

LocalAlloc Proc near
	push ebp
	mov ebp,esp
;
	int 3
	mov eax,[ebp].laBytes
	push es
	push ecx
	push edi
	UserGate allocate_local_mem_nr
	mov ecx,eax
	xor al,al
	xor edi,edi
	rep stosb
	mov ax,es
	movzx eax,ax
	pop edi
	pop ecx
	pop es
;
	pop ebp
	ret 8
LocalAlloc Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalFree
;
;       DESCRIPTION:    Free memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LocalFree

lfMem EQU 8

LocalFree Proc near
	push ebp
	mov ebp,esp
;
	int 3
	push es
	mov es,[ebp].lfMem
	UserGate free_mem_nr
	pop es
	xor eax,eax
;
	pop ebp
	ret 4
LocalFree Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HeapCreate
;
;       DESCRIPTION:    Create a heap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public HeapCreate

HeapCreate PROC near
	int 3
	mov eax,1 
	ret 12
HeapCreate ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HeapDestroy
;
;       DESCRIPTION:    Destroy a heap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public HeapDestroy

HeapDestroy Proc near
	int 3
	mov eax,1
	ret 4
HeapDestroy ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HeapAlloc
;
;       DESCRIPTION:    Allocate on heap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public HeapAlloc

HeapAlloc PROC near
	int 3
	pop edx
	pop eax
	push edx
	jmp LocalAlloc
HeapAlloc ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HeapFree
;
;       DESCRIPTION:    Free on heap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public HeapFree

HeapFree PROC near
	int 3
	pop edx
	pop eax
	pop eax
	push edx
	jmp LocalFree
HeapFree ENDP

	END
