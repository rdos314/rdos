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
; RUN.ASM
; Runs (detaches) a program in a new virtual console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME run

.model Small

GateSize = 16

INCLUDE ..\user.def
INCLUDE ..\user.inc

psp_seg		STRUC
psp_int20		DW ?
psp_memend		DW ?
psp_res1		DB ?
psp_dispatch	DB 5 DUP(?)
psp_int22		DW ?,?
psp_int23		DW ?,?
psp_int24		DW ?,?
psp_parent		DW ?
psp_handletab	DB 20 DUP(?)
psp_enviro		DW ?
psp_res2		DW ?,?
psp_handlesize	DW ?
psp_handleads	DW ?,?
psp_parent_sp	DW ?
psp_parent_ss	DW ?
psp_ret_code	DW ?
psp_res3		DB 18 DUP(?)
psp_doscall		DW ?
psp_retf		DB ?
psp_res4		DB 9 DUP(?)
psp_fcb1		DB 16 DUP(?)
psp_fcb2		DB 20 DUP(?)
psp_line		DB 80 DUP(?)
psp_seg		ENDS

.stack

.data

FileName	DB 256 DUP(0)
CmdLine		DB 256 DUP(0)
SearchName	DB 256 DUP(?)
CurrDir		DB 256 DUP(?)

.code

.386c

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitParam
;
;		DESCRIPTION:   	Init file name & cmd line
;
;		RETURNS:		NC		OK	
;			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitParam	Proc
	mov ah,62h
	int 21h
	mov ds,bx
	mov si,80h
	mov ax,SEG FileName
	mov es,ax
	mov di,OFFSET FileName
	mov cl,[si]
	inc si
	xor ch,ch
init_check:
	lodsb
	cmp al,' '
	je init_bypass
	cmp al,'	'
	je init_bypass
	jmp init_move

init_bypass:
	loop init_check
	jmp init_fail

init_move:
	dec si

init_move_loop:
	lodsb
	cmp al,' '
	je init_cmd_check
	cmp al,'	'
	je init_cmd_check
	cmp al,'.'
	je init_bypass_ext
	stosb
	loop init_move_loop
	jmp init_ok

init_bypass_ext:
	dec si

init_bypass_ext_loop:
	lodsb
	cmp al,' '
	je init_cmd_check
	cmp al,'	'
	je init_cmd_check
	loop init_bypass_ext_loop
	jmp init_ok

init_cmd_check:
	dec si

init_cmd_check_loop:
	lodsb
	cmp al,' '
	je init_cmd_bypass
	cmp al,'	'
	je init_cmd_bypass
	jmp init_cmd_move

init_cmd_bypass:
	loop init_cmd_check_loop
	jmp init_ok

init_cmd_move:
	dec si
	mov di,OFFSET CmdLine
	rep movsb

init_ok:
	clc
	jmp init_done

init_fail:
	stc	

init_done:
	ret
InitParam	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckPath
;
;		DESCRIPTION:   	Check if path is a valid .com or .exe file
;
;		RETURNS:		NC		path ok
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckPath	Proc
	mov ax,SEG SearchName
	mov ds,ax
	mov es,ax
	mov di,OFFSET SearchName

check_path_end_loop:
	mov al,es:[di]
	or al,al
	jz check_path_append
	inc di
	jmp check_path_end_loop

check_path_append:
	mov al,es:[di-1]
	cmp al,'\'
	je check_path_slash_ok
;
	mov al,'\'
	stosb

check_path_slash_ok:
	mov si,OFFSET FileName

check_path_append_loop:
	lodsb
	or al,al
	jz check_path_do
	stosb
	jmp check_path_append_loop

check_path_do:
	mov si,di
	mov eax,'EXE.'
	stosd
	xor al,al
	stosb
	mov di,OFFSET SearchName
	xor cx,cx
	OpenFile
	jnc check_path_ok
;
	mov di,si
	mov eax,'MOC.'
	stosd
	xor al,al
	stosb
	mov di,OFFSET SearchName
	xor cx,cx
	OpenFile
	jc check_path_done

check_path_ok:
	CloseFile
	clc

check_path_done:
	ret
CheckPath	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindEnvPath
;
;		DESCRIPTION:   	Find environment path variable
;
;		RETURNS:		NC		path ok
;						DS:SI	pointer to path string
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PathName		DB 'PATH',0

FindEnvPath	Proc
	mov ah,62h
	int 21h
	mov ds,bx
	mov ds,ds:psp_enviro
	xor si,si
	mov ax,cs
	mov es,ax
	mov di,OFFSET PathName
find_path_loop:
	cmpsb
	jnz find_path_next
	mov al,es:[di]
	or al,al
	jnz find_path_loop
	mov al,[si]
	cmp al,'='
	je find_path_found

find_path_next:
	lodsb
	or al,al
	jnz find_path_next
	mov al,[si]
	or al,al
	mov di,OFFSET PathName
	jne find_path_loop
	stc
	ret

find_path_found:
	inc si
	clc
	ret
FindEnvPath	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetupNextPath
;
;		DESCRIPTION:   	Setup next path
;
;		PARAMETERS:		DS:SI	pointer to path string

;		RETURNS:		NC		path ok
;						DS:SI	pointer to path string
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupNextPath	Proc
	mov ax,SEG SearchName
	mov es,ax
	mov di,OFFSET SearchName
	mov al,[si]
	or al,al
	stc
	jz setup_next_done

setup_next_move_loop:
	lodsb
	or al,al
	jz setup_next_ok
	cmp al,';'
	je setup_next_ok
	stosb
	jmp setup_next_move_loop	

setup_next_ok:
	xor al,al
	stosb
	clc

setup_next_done:
	ret
SetupNextPath	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		DESCRIPTION:   	Main procedure
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init:
	call InitParam
	jc failed
;
	mov di,OFFSET CurrDir
	GetCurDrive
	push ax
	add al,'A'
	stosb
	mov ax,'\:'
	stosw
	pop ax
	GetCurDir
;
	mov di,OFFSET SearchName
	GetCurDrive
	push ax
	add al,'A'
	stosb
	mov ax,'\:'
	stosw
	pop ax
	GetCurDir
;
	call CheckPath
	jnc spawn_do
;
	call FindEnvPath
	jc failed

path_loop:
	call SetupNextPath
	jc failed
;
	push ds
	push si
	call CheckPath
	pop si
	pop ds
	jc path_loop

spawn_do:
	mov ax,SEG SearchName
	mov ds,ax
	mov si,OFFSET SearchName
	mov ax,SEG CmdLine
	mov es,ax
	mov di,OFFSET CmdLine 
	mov ax,SEG CurrDir
	mov fs,ax
	mov bx,OFFSET CurrDir
	xor dx,dx
	SpawnExe
	mov ax,4C00h
	int 21h

failed:
	mov ax,4C01h
	int 21h

	END init
