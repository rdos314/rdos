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
; 16-bit user.dll emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                
		NAME user

GateSize = 16

INCLUDE ..\user.def
INCLUDE ..\user.inc

.386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitApp
;
;       DESCRIPTION:    Inits app
;
;		PARAMETERS:		hInst	Instance handle
;
;	    RETURNS:		AX		0 for failure, 1 for success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public InitApp

InitApp	Proc far
	mov ax,1
	ret 2
InitApp	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MessageBox
;
;       DESCRIPTION:    Display message box
;
;		PARAMETERS:		WndParent		parent window or 0
;						Txt				text to display
;						Caption			caption to use
;						Style			typ of box
;
;	    RETURNS:		0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public MessageBox

MessageBox	Proc far
	int 3
	push bp
	mov bp,sp
	les di,[bp+12]
	xor ax,ax
	pop bp
	ret 12
MessageBox	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LoadString
;
;       DESCRIPTION:    Load string resource
;
;		PARAMETERS:		hInst	Instance handle
;						ID		String #
;						buffer	string buffer
;						size	size of buffer
;
;	    RETURNS:		AX		0 for failure, otherwise string length
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public LoadString

LoadString	Proc far
	push bp
	mov bp,sp
	mov ax,[bp+12]
	xor ax,ax
	pop bp
	ret 10
LoadString	Endp	

init	Proc far
	ret
init	Endp

code	ENDS

	END init
