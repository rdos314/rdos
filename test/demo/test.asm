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

response	DB 20 DUP(?)

data	ENDS

code    SEGMENT byte public 'CODE'

	.386p

	assume cs:code

host_name	DB 'www.rdos.net',0
host_ip		DB 192,168,12,108

init:
	int 3
	mov ax,12h
	SetVideoMode
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
