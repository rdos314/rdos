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
; WINUSER.ASM
; 16-bit toolhelp.dll emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                
		NAME toolhelp

GateSize = 16

INCLUDE \rdos\os\user.def
INCLUDE \rdos\os\user.inc

.386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalEntryHandle
;
;       DESCRIPTION:    Get info about global memory block
;
;		PARAMETERS:		lpGlobal		structure
;						hItem			handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GlobalEntryHandle

GlobalEntryHandle	Proc far
	push bp
	mov bp,sp
	int 3
	push es
	push di
	les di,[bp+8]
	mov ax,36
	stosw
	xor ax,ax
	stosw
	stosw
	mov ax,[bp+6]
	stosw
    lsl eax,[bp+6]
	stosd
	mov ax,[bp+6]
	stosw
	xor ax,ax
	stosw
	stosw
	stosw
	stosw
	stosw
	stosw
	stosw
	mov ax,1
	pop di
	pop es
	pop bp
	ret 6
GlobalEntryHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ModuleFindHandle
;
;       DESCRIPTION:    Get info about module
;
;		PARAMETERS:		lpModule		structure
;						handle			handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public ModuleFindHandle

ModuleFindHandle	Proc far
	push bp
	mov bp,sp
	int 3
	xor ax,ax
	pop bp
	ret 6
ModuleFindHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           TerminateApp
;
;       DESCRIPTION:    Terminate app
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public TerminateApp

TerminateApp:
	mov ax,4C00h
	int 21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InterruptRegister
;
;       DESCRIPTION:    Register interrupt handler
;
;		PARAMETERS:		hTask		task handle
;						lpfnCall	callback procedure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public InterruptRegister

InterruptRegister	Proc far
	mov ax,1
	ret 6
InterruptRegister	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InterruptUnregister
;
;       DESCRIPTION:    Register interrupt handler
;
;		PARAMETERS:		hTask		task handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public InterruptUnregister

InterruptUnregister	Proc far
	mov ax,1
	ret 6
InterruptUnregister	Endp

init	Proc far
	ret
init	Endp

code	ENDS

	END init
