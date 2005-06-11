;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Em486 CPU emulator
; Copyright (C) 1998-2000, Gilles Gate
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage. For information on commercial usage,
; contact em486@rdos.net.
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
; EMDATA.ASM
; print data into  the debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat
locals

		NAME emdata
		
INCLUDE x86\emulate.inc		
		
.data

Cpu	equ	[ebp]

data_buffer		db 16 dup (?)
data_size_copied	dd ?

		public	showdata
		extrn CondReadLinear:near	
		extrn WriteChar:near
		extrn Blank:near
		extrn WriteHexPtr32:near
		extrn WriteHexByte:near
		extrn NewLine:near		
		extrn SegDsTab		

.code

;++++=+=+=+=+=+=+=+=+=+=+=+=+=+=++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++
;		NAME:		GETDATA  			      +
;		PURPOSE:	Read the data pointed by the Cpu      +	
;                               gs:esi register                       +
;					                  	      +
;		PARAMETER:	EBP contient le Cpu		      +
;								      +
;		RETURN:		                                      +
;					                  	      +
;+=+=+=+++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++

getdata	proc	near


	push	esi
	push	edi
	push	ecx
	push	ebx
	
	mov 	data_buffer,0
	mov	data_size_copied,0
;
	movzx 	esi,word ptr Cpu.reg_gs.d_selector
	mov     esi,dword ptr [4*esi].SegDsTab
	
; There is no test to see if the access of the segment is 16 or 32 bits
;you decide that by your on

	mov 	ebx,Cpu.reg_esi
;
	mov 	ecx,ebx
	sub 	ecx,[ebp+esi].d_limit
	ja 	short getdata_done
;
	neg 	ecx
	inc 	ecx
	cmp 	ecx,16
	jb 	short getdata_read_linear
	mov 	ecx,16

getdata_read_linear:
	mov	data_size_copied,ecx
	add 	ebx,[ebp+esi].d_base
	call 	CondReadLinear		;read bytes in [ebp].req_buf
	lea	esi,Cpu.req_buf
	lea	edi,data_buffer
	mov	ecx,4
	rep	movsd
	
getdata_done:
	pop	ebx
	pop	ecx
	pop	edi
	pop	esi
	
	ret 
	
getdata		Endp

;++++=+=+=+=+=+=+=+=+=+=+=+=+=+=++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++
;		NAME:		PRINTDATA  			      +
;		PURPOSE:	Show data to the screen               +	
;                               ds:esi register                       +
;					                  	      +
;		PARAMETER:	                      		      +
;								      +
;		RETURN:			                              +
;					                  	      +
;+=+=+=+++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++


printdata	proc	near

;d'abord on va ecrire l'offset
;a priori les registres sont sauvegardés


	push	esi
	push	ecx
	push	ebx
	push	edx
	
	movzx 	esi,word ptr Cpu.reg_gs.d_selector
	mov     esi,dword ptr [4*esi].SegDsTab
	
	mov 	dx,Cpu.esi.d_selector
	mov	ebx,Cpu.reg_esi
	call	WriteHexPtr32

;un peu d'espace

	mov	ecx,1
	call	Blank
		
;maintenant on va copier les HEX bytes de données	
	mov 	esi,offset data_buffer
	mov	ecx,data_size_copied
	cmp	ecx,0
	jnz	short @@1
	inc	ecx
@@1:
	lodsb
	call	WriteHexByte
	push	ecx
	mov	ecx,1
	call	Blank
	pop	ecx
	loop	@@1		
	
;un peu d'espace
	mov	eax,data_size_copied
	mov	ecx,eax
	shl	eax,1
	add	eax,ecx
	mov	ecx,DISTANCE_DATA 
	inc	eax
	sub	ecx,eax		;pour aligner les instructions * J'ai des problemes pour aligner

	call	Blank

;maintenant on va copier les ASCII bytes de données	
	mov 	esi,offset data_buffer
	mov	ecx,data_size_copied
@@2:
	lodsb
	call	WriteChar
	loop	@@2		

	pop	edx
	pop	ebx
	pop	ecx
	pop	esi
	
	ret
printdata	endp

;++++=+=+=+=+=+=+=+=+=+=+=+=+=+=++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++
;		NAME:		SHOWDATA  			      +
;					                  	      +

;		PURPOSE:	Show data commander                   +	
;					                  	      +
;		PARAMETER:      TCpu *Cpu in the stack		      +
;								      +
;		RETURN:			                              +
;					                  	      +
;+=+=+=+++=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=++
;
;  HOW TO USE THE D COMMAND

; you just type SEG_NBER:OFFSET where SEG_NBER is the rank of the segment 
;registre as on the screen ,the first segment is SEG_NBER = 0
;
showdata	proc	near

;
	push	ebp
	mov	ebp,esp
	push	ecx
	push	esi
	mov	ebp,[ebp+8]
	mov	ecx,DATA_LINES_NR

;	
showdata_loop:
	call	NewLine
	call	getdata
	call	printdata
	mov	eax,Cpu.reg_esi
	add	eax,16
	mov	Cpu.reg_esi,eax
	loop	showdata_loop
;	
	call	NewLine
;
	pop	esi
	pop	ecx
	pop	ebp
;	
	ret	4
		
showdata	endp


	END