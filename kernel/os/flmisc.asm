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
; FLMISC.ASM
; FLMISC (Flash File System, misc functions)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME flmisc

GateSize = 16

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\fs.inc
INCLUDE flashfs.inc

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EraseBlock
;
;		DESCRIPTION:	Erase a block
;
;		PARAMETERS:		EDX     start sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public EraseBlock
    
EraseBlock	Proc near
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push bp
;
    int 3
    mov ax,flat_sel
    mov es,ax
;
    mov al,ds:drive_nr
    mov ecx,128
    EraseSectors
    CreateDiscSeq
    mov bp,ax

erase_loop:
    mov al,ds:drive_nr
    NewSector
    mov edi,esi
    push ecx
    mov eax,-1
    mov ecx,80h
    rep stos dword ptr es:[edi]
    pop ecx 
    mov ax,bp   
    ModifySeqSector
;
    inc edx
    loop erase_loop
;    
    mov ax,bp
    PerformDiscSeq
;
    pop bp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
	ret
EraseBlock	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteSector
;
;		DESCRIPTION:	Write a sector
;
;		PARAMETERS:		EBX     Sector handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteSector
    
WriteSector	Proc near
    push ax
    push cx
;
    int 3
    mov cx,1
    CreateDiscSeq
    ModifySeqSector
    PerformDiscSeq
;    
    pop cx
    pop ax
	ret
WriteSector	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteSectorAlloc
;
;		DESCRIPTION:	Write a sector & allocation table
;
;		PARAMETERS:		EBX     Sector handle
;						FS		Allocate selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteSectorAlloc
    
WriteSectorAlloc	Proc near
    push ax
    push ebx
    push cx
;
    int 3
    mov cx,2
    CreateDiscSeq
    ModifySeqSector
    mov ebx,fs:bc_handle
    ModifySeqSector
    PerformDiscSeq
;    
    pop cx
    pop ebx
    pop ax
	ret
WriteSectorAlloc	Endp

code	ENDS

	END
