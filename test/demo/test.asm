;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; TEST.ASM
; Test application
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME test

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\user.def
INCLUDE ..\os\user.inc
INCLUDE ..\os\state.def

data	SEGMENT byte public 'DATA'

float_string	DB 256 DUP(?)

buf		DW 4096 DUP(?)

data	ENDS

code    SEGMENT byte public 'CODE'

	.386p

	assume cs:code

	extrn float_to_string:near

host_name	DB 'www.rdos.net',0
host_ip		DB 192,168,12,108

val	DT 4.566

FilemapName	DB 'Test', 0

filename	DB 'e:\rdos\test\kernel.map',0

test_name	DB 'Test Section Thread', 0

test_thread:
	int 3
;
	LeaveUserSection
	EnterUserSection
	jmp test_thread

divi	DW 1111h
	
init:
	int 3
	mov cx,800
	mov dx,600
	SetVgaMode
	int 3
	mov ax,3
	SetVideoMode
	int 3
	mov ax,-5050
	mov bl,-4
;	div cs:divi
	idiv bl
	CreateBlockedUserSection
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET test_thread
	mov di,OFFSET test_name
	mov ax,2
	mov cx,1000h
	CreateThread
;	
	EnterUserSection
	EnterUserSection
	LeaveUserSection
	LeaveUserSection
	int 3
;
	DeleteUserSection
	mov ax,cs
	mov es,ax
	mov di,OFFSET filename
	OpenFile
;
	mov eax,22222h
	SetFileSize
;
	mov eax,22221h
	SetFileSize
;
	mov eax,22223h
	SetFileSize
;
	mov eax,1C001h
	SetFileSize
;
	mov eax,1C000h
	SetFileSize
;
	mov eax,1C001h
	SetFileSize
;
	CloseFile
;
	xor cx,cx
	mov ax,cs
	mov es,ax
	mov di,OFFSET filename
	CreateFile
;
	mov eax,12345h
	SetFilePos
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET host_name
	mov cx,13
	WriteFile
;
	mov eax,12345h
	SetFilePos
;
	mov ax,SEG data
	mov es,ax
	mov di,OFFSET buf
	mov cx,13
	ReadFile
;
	CloseFile
;
	mov eax,3000h
	CreateMapping
	push bx
	mov ax,cs
	mov es,ax
	mov di,OFFSET FilemapName
	mov eax,3000h
	CreateNamedMapping
	push bx
	OpenNamedMapping
	CloseMapping
	pop bx
	mov eax,3000h
	AllocateAppMem
	xor di,di
	xor eax,eax
	mov ecx,3000h
	MapView
	mov di,1FFFh
	mov ax,2345h
	stosw
	SyncMapping
	UnmapView
	FreeMem
	CloseMapping
	pop bx
	CloseMapping
	int 3

	mov ax,cs
	mov es,ax
	mov di,OFFSET host_name
	NameToIp
	int 3
;
	mov eax,6000
	mov edx,dword ptr cs:host_ip
	mov ecx,4000h
	xor si,si
	mov di,80
	OpenTcpConnection
;
	mov eax,50
	WaitMilliSec
	jmp init

code    ENDS

	END init
