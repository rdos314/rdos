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
; INI.ASM
; Ini file handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME ini

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\handle.inc

handle_seg	STRUC

ih_base	handle_header <>

ih_sel	DB ?

handle_seg	ENDS

ini_sect_seg    STRUC

is_file_pos     DD ?
is_file_size    DD ?
is_sel          DW ?

ini_sect_seg    ENDS

ini_file_seg STRUC

if_section       section_typ <>
if_access        DB ?
if_file_sel      DW ?
if_sect_list     DW ?

ini_file_seg ENDS

ini_sys_seg  STRUC

is_section      section_typ <>

is_sys_sel      DW ?
is_ini_list     DW ?

ini_sys_seg  ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenSystemIni
;
;       DESCRIPTION:    Opens system ini file
;
;		RETURNS:		BX			ini file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SysIniName	DB 'z:\system.ini',0

OpenSystemIni	Proc near
	mov ax,cs
	mov es,ax
	mov di,OFFSET SysIniName
OpenSystemIniLoop:
	mov cl,0
	OpenFile
	jnc OpenSystemIniDone
	inc byte ptr es:[di]
	jmp OpenSystemIniLoop
	
OpenSystemIniDone:
	ret
OpenSystemIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindIniSection
;
;       DESCRIPTION:    Find section in .ini file
;
;		PARAMETERS:		BX			ini file handle
;						DS:ESI		Section to find
;						ES:EDI		Buffer
;
;		RETURNS:		EAX			Size of section
;						EDX			File position
;						NC			Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindIniSection	Proc near
	mov eax,100h
	AllocateBigGlobalMem
	xor edx,edx
FindIniSectionNext:
	mov eax,edx
	SetFilePos
	mov cx,1000h
	xor edi,edi
	ReadFile
	or ax,ax
	stc
	jz FindIniSectionDone
	
FindIniSectionScan:
	mov cx,ax
	mov al,'['
	repne scasb
	add edx,edi
	cmp byte ptr es:[di-1],'['
	je FindIniSectionTest
;
	mov eax,edx
	SetFilePos
	mov cx,1000h
	xor di,di
	ReadFile
	or ax,ax
	stc
	jnz FindIniSectionScan
	jmp FindIniSectionDone
	
FindIniSectionTest:
	mov eax,edx
	SetFilePos
	mov cx,1000h
	xor di,di
	ReadFile
	or ax,ax
	stc
	jz FindIniSectionDone
;
	push esi
	repe cmps byte ptr es:[edi],ds:[esi]
	dec esi
	dec edi
	lods byte ptr es:[esi]
	or al,al
	jne FindIniSectionWrongName
;
	mov al,es:[di]
	cmp al,']'
	jne FindIniSectionWrongName
;
	pop esi
	inc di
	add edx,edi
	push edx
FindIniSectionSize:
	mov eax,edx
	SetFilePos
	mov cx,1000h
	xor edi,edi
	ReadFile
	mov cx,ax
	mov al,'['
	repne scasb
	add edx,edi
	dec edx
	or cx,cx
	je FindIniSectionSize
;
	mov eax,edx
	pop edx
	sub eax,edx
	clc
	jmp FindIniSectionDone	
	
FindIniSectionWrongName:
	pop esi
	add edx,edi
	inc edx
	jmp FindIniSectionNext
	
FindIniSectionDone:
	pushf
	FreeMem
	popf
	ret
FindIniSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindIniKey
;
;       DESCRIPTION:    Find key in section
;
;		PARAMETERS:		BX			ini file handle
;						DS:ESI		Key to find
;						EDX			File position
;						EAX			Size of section
;						ES:EDI		Key value
;						NC			Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindIniKey	Proc near
	mov ecx,eax
	AllocateBigGlobalMem
	mov eax,edx
	SetFilePos
	xor edi,edi
	ReadFile	
	
FindIniKeyControl:
	mov al,es:[edi]
	cmp al,0Dh
	je FindIniKeyControlPass
	cmp al,0Ah
	je FindIniKeyControlPass
	cmp al,' '
	je FindIniKeyControlPass
	cmp al,9
	jne FindIniKeyScan
	
FindIniKeyControlPass:
	inc edi
	sub ecx,1
	jne FindIniKeyControl
	stc
	jmp FindIniKeyDone
	
FindIniKeyScan:
	push esi
	repe cmps byte ptr es:[edi],ds:[esi]
	dec esi
	dec edi
	inc ecx
	lods byte ptr ds:[esi]
	pop esi
	or al,al
	jne FindIniKeyWrongName
	
FindIniKeySpacePass:
	mov al,es:[edi]
	cmp al,'='
	je FindIniKeyCorrectName
	cmp al,' '
	je FindIniKeySpacePass
	cmp al,9
	jne FindIniKeyWrongName
;	
	inc edi
	sub ecx,1
	jc FindIniKeyDone
	jmp FindIniKeySpacePass
	
FindIniKeyWrongName:
	mov al,es:[edi]
	cmp al,0Dh
	je FindIniKeyControl
	inc edi	
	sub ecx,1
	jc FindIniKeyDone
	jmp FindIniKeyWrongName
	
FindIniKeyCorrectName:
	inc edi
	clc
FindIniKeyDone:
	ret
FindIniKey	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetIniInt
;
;		DESCRIPTION:	Read ini file key as integer
;
;		PARAMETERS:		ES:DI	String
;						(E)AX	Size of section
;						AX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIniInt	PROC near
	push bx
	mov bx,ax
	xor ax,ax
	xor ch,ch
GetIniIntPass:
	mov cl,es:[di]
	inc di
	sub bx,1
	jz GetIniIntEnd
	cmp cl,' '
	je GetIniIntPass
	cmp cl,'	'
	je GetIniIntPass
	cmp cl,'+'
	je GetIniIntPass
	cmp cl,'-'
	jne GetIniIntDecode
	mov ch,80h
	jmp GetIniIntPass
GetIniIntDecode:
	dec di
	inc bx
GetIniIntLoop:
	mov cl,es:[di]
	sub cl,30h
	jc GetIniIntEnd
	cmp cl,0Ah
	jnc GetIniIntEnd
	mov dx,10
	mul dx
	add al,cl
	adc ah,0
	inc di
	sub bx,1
	jnz GetIniIntLoop
GetIniIntEnd:
	test ch,80h
	jz GetIniIntPos
	neg ax
GetIniIntPos:
	pop bx
	ret
GetIniInt	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProfileInt
;
;       DESCRIPTION:    Get .ini file integer
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Default		default value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetProfileInt

GetProfileInt	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push si
	push di
	call OpenSystemIni
	lds si,[bp+12]
	call FindIniSection
	jc GetProfileIntSectionFail
	lds si,[bp+8]
	call FindIniKey
	jc GetProfileIntKeyFail
	call GetIniInt
	FreeMem
	jmp GetProfileIntEnd
GetProfileIntKeyFail:
	FreeMem
GetProfileIntSectionFail:
	mov ax,[bp+6]
GetProfileIntEnd:
	push ax
	CloseFile
	pop ax
	pop di
	pop si
	pop es
	pop ds
	pop bp
	ret 10
GetProfileInt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProfileString
;
;       DESCRIPTION:    Get .ini file string
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Default		default value
;						ReturnedStr	returned string
;						Size		size of ReturnedStr string 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetProfileString

GetProfileString	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push si
	push di
	call OpenSystemIni
	lds si,[bp+20]
	call FindIniSection
	jc GetProfileStringSectionFail
	lds si,[bp+16]
	call FindIniKey
	jc GetProfileStringKeyFail
	mov cx,ax
	xor dx,dx
	cmp cx,[bp+6]
	jc GetProfileStringWhole
	mov cx,[bp+6]
	dec cx
GetProfileStringWhole:
	push es
	mov ax,es
	mov ds,ax
	mov si,di
	les di,[bp+8]
GetProfileStringCopy:
	lodsb
	cmp al,0Dh
	je GetProfileStringCopied
	cmp al,0Ah
	je GetProfileStringCopied
	inc dx
	stosb
	loop GetProfileStringCopy
GetProfileStringCopied:
	xor ax,ax
	stosb
	mov ds,ax
	pop es
	FreeMem
	jmp GetProfileStringEnd
GetProfileStringKeyFail:
	FreeMem
GetProfileStringSectionFail:
	lds si,[bp+12]
	les di,[bp+8]
	mov cx,[bp+6]
	dec cx
	xor dx,dx
GetProfileStringDefault:
	lodsb
	stosb
	or al,al
	je GetProfileStringEnd
	inc dx
	loop GetProfileStringDefault
GetProfileStringEnd:
	CloseFile
	mov ax,dx
	pop di
	pop si
	pop es
	pop ds
	pop bp
	ret 18
GetProfileString	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteProfileInt
;
;       DESCRIPTION:    Write .ini file string
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Value		value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public WriteProfileString

WriteProfileString	Proc far
	xor ax,ax
	ret 12
WriteProfileString	Endp

code	ENDS

	END init

