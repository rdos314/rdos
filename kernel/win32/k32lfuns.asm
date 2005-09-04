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
; K32LFUNS.ASM
; 32-bit kernel32.dll string & language support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  k32lfuns

;;;;;;;;; INTERNAL ProcEDURES ;;;;;;;;;;;

.386p
.model flat

include ..\user.def

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
pvResv2				DD ?,?,?,?
pvTLSArray			DD ?

tib_data	ENDS

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           lstrlen
;
;       DESCRIPTION:    lstrlen function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public lstrlen
	public lstrlenA

lstrlen	Proc near
lstrlenA:
	mov	edx,[esp+4]
	sub	eax,eax

lstrlen00:
	cmp	byte ptr [edx+eax],0
	jz	short lstrlen01

	inc	eax
	jmp	short lstrlen00

lstrlen01:
	ret	4
lstrlen	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           lstrcpy
;
;       DESCRIPTION:    lstrcpy function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public lstrcpy
	public lstrcpyA

lstrcpy	Proc near
lstrcpyA:
	mov edx,[esp+4]
	mov ecx,[esp+8]

lstrcpy00:
	mov al,[ecx]
	inc ecx
	mov [edx],al
	inc edx
	test al,al
	jnz short lstrcpy00

	mov eax,[esp+4]
	ret 8
lstrcpy	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           lstrcpyn
;
;       DESCRIPTION:    lstrcpyn function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public lstrcpyn
	public lstrcpynA

lstrcpyn	Proc near
lstrcpynA:
	push ebx
	mov edx,[esp+8]
	mov ecx,[esp+12]
	mov ebx,[esp+16]
	sub eax,eax
	dec ebx
	js short lstrcpyn02

	jz short lstrcpyn01

lstrcpyn00:
	mov al,[ecx]
	inc ecx
	mov [edx],al
	inc edx
	dec ebx
	jnz short lstrcpyn00

lstrcpyn01:
	mov [edx],bl
	mov eax,[esp+8]

lstrcpyn02:
	pop ebx
	ret 12
lstrcpyn	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           lstrcat
;
;       DESCRIPTION:    lstrcat function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public lstrcat
	public lstrcatA

lstrcat	Proc near
lstrcatA:
	push dword ptr [esp+4]
	call lstrlen
	add eax,[esp+4]
	push dword ptr [esp+8]
	push eax
	call lstrcpy
	mov eax,[esp+4]
	ret 8
lstrcat	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           lstrcmp
;
;       DESCRIPTION:    lstrcmp function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public lstrcmp
	public lstrcmpA

lstrcmp	Proc near
lstrcmpA:
	mov edx,[esp+4]
	mov ecx,[esp+8]
	sub eax,eax

lstrcmp00:
	mov al,[edx]
	sub al,[ecx]
	sbb ah,ah
	cmp byte ptr [edx],0
	jz short lstrcmp01

	cmp byte ptr [ecx],0
	jz short lstrcmp01

	inc edx
	inc ecx
	test eax,eax
	jz short lstrcmp00

lstrcmp01:
	movsx eax,ax
	ret 8
lstrcmp	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           lstrcmpi
;
;       DESCRIPTION:    lstrcmpi function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public lstrcmpi
	public lstrcmpiA

lstrcmpi	Proc near
lstrcmpiA:
	mov edx,[esp+4]
	mov ecx,[esp+8]
	sub eax,eax

lstrcmpi00:
	mov al,[edx]
	cmp al,'A'

	jc short lstrcmpi001
	cmp al,'Z'

	ja short lstrcmpi001
	or al,20h

lstrcmpi001:
	mov ah,[ecx]
	cmp ah,'A'
	jc short lstrcmpi002

	cmp ah,'Z'
	ja short lstrcmpi002

	or ah,20h

lstrcmpi002:
	sub al,ah
	sbb ah,ah
	cmp byte ptr [edx],0
	jz short lstrcmpi01

	cmp byte ptr [ecx],0
	jz short lstrcmpi01

	inc edx
	inc ecx
	test eax,eax
	jz short lstrcmpi00

lstrcmpi01:
	movsx eax,ax
	ret 8
lstrcmpi	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           _lread
;
;       DESCRIPTION:    _lread function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _lread
	public _hread

_lread	Proc near
_hread:
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov ebx, [ebp+8]
	mov edi, [ebp+12]
	mov ecx, [ebp+16]
	UserGate read_file_nr
	sbb ecx, ecx
	mov fs:pvLastError, ecx
	and fs:pvLastError, eax
	or eax, ecx
;
	pop edi
	pop ebx
	pop ebp
	ret 12
_lread	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           _lwrite
;
;       DESCRIPTION:    _lwrite function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _lwrite
	public _hwrite

_lwrite	Proc near
_hwrite:
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov ebx, [ebp+8]
	mov edi, [ebp+12]
	mov ecx, [ebp+16]
	UserGate write_file_nr
	sbb ecx, ecx
	mov fs:pvLastError, ecx
	and fs:pvLastError, eax
	or eax, ecx
;
	pop edi
	pop ebx
	pop ebp
	ret 12
_lwrite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           _lcreat
;
;       DESCRIPTION:    _lcreat function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _lcreat

_lcreat	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi, [ebp+8]
	mov ecx, [ebp+12]
	UserGate create_file_nr
	jc create_fail
;
	movzx eax,bx
	mov fs:pvLastError,0
	jmp create_done

create_fail:
	movzx eax,ax
	mov fs:pvLastError,eax
	xor eax,eax

create_done:
	pop edi
	pop ebx
	pop ebp
	ret 8
_lcreat	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           _lopen
;
;       DESCRIPTION:    _lopen function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _lopen

_lopen	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi, [ebp+8]
	mov ecx, [ebp+12]
	UserGate open_file_nr
	jc open_fail
;
	movzx eax,bx
	mov fs:pvLastError,0
	jmp open_done

open_fail:
	movzx eax,ax
	mov fs:pvLastError,eax
	xor eax,eax

open_done:
	pop edi
	pop ebx
	pop ebp
	ret 8
_lopen	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           _lclose
;
;       DESCRIPTION:    _lclose function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _lclose

_lclose	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov ebx, [ebp+8]
	UserGate close_file_nr
	xor eax,eax
	mov fs:pvLastError,eax
;
	pop ebx
	pop ebp
	ret 4
_lclose	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           _llseek
;
;       DESCRIPTION:    _lseek function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _llseek

_llseek	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov ebx,[ebp+8]
	mov edx,[ebp+12]
	mov eax,[ebp+16]
	or al,al
	jnz lseek_not_begin

lseek_begin:
	mov eax,edx
	UserGate set_file_pos_nr
	jnc lseek_ok
	jmp lseek_fail

lseek_not_begin:
	sub al,1
	jnz lseek_not_current

lseek_current:
	UserGate get_file_pos_nr
	add eax,edx
	UserGate set_file_pos_nr
	jnc lseek_ok
	jmp lseek_fail

lseek_not_current:
	sub al,1
	jnz lseek_fail

lseek_end:
	UserGate get_file_size_nr
	add eax,edx
	UserGate set_file_pos_nr
	jnc lseek_ok
	jmp lseek_fail

lseek_fail:
	mov eax,-1
	jmp lseek_done

lseek_ok:
	
lseek_done:
	pop ebx
	ret 12
_llseek	Endp

	END
