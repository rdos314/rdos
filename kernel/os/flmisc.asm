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
    push ax
    push ecx
;
    mov al,ds:drive_nr
    movzx ecx,ds:block_sectors
    EraseSectors
;
    pop ecx
    pop ax
	ret
EraseBlock	Endp


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
    mov cx,1
    CreateDiscSeq
    ModifySeqSector
    PerformDiscSeq
;    
    pop cx
    pop ax
	ret
WriteSector	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteSectorAlloc
;
;		DESCRIPTION:	Write a sector & allocation table
;
;		PARAMETERS:		EBX     Sector handle
;						GS		Allocate selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteSectorAlloc
    
WriteSectorAlloc	Proc near
    push ax
    push ebx
    push cx
    push esi
;
    mov esi,gs:bc_op_ads
	mov al,es:[esi].le_status
	and al,1Fh
	or al,LOG_STATUS_BEFORE_ALLOC
	mov es:[esi].le_status,al
; 
    push ebx
    mov cx,1
    CreateDiscSeq
    mov ebx,gs:bc_op_handle
    ModifySeqSector
    PerformDiscSeq
    pop ebx
;
    mov cx,1
    CreateDiscSeq
    ModifySeqSector
    PerformDiscSeq
;    
    mov ebx,gs:bc_op_handle
	WaitForSector
;
	mov al,es:[esi].le_status
	and al,1Fh
	or al,LOG_STATUS_AFTER_ALLOC
    mov es:[esi].le_status,al
;
    mov cx,1
    CreateDiscSeq
    ModifySeqSector
    PerformDiscSeq
;
    pop esi
    pop cx
    pop ebx
    pop ax
	ret
WriteSectorAlloc	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteSectorFree
;
;		DESCRIPTION:	Write a sector & allocation table
;
;		PARAMETERS:		EBX     Sector handle
;						GS		Free selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteSectorFree
    
WriteSectorFree	Proc near
    push ax
    push ebx
    push cx
    push esi
;
    mov esi,gs:bc_op_ads
	mov al,es:[esi].le_status
	and al,1Fh
	or al,LOG_STATUS_BEFORE_FREE
	mov es:[esi].le_status,al
;    
    push ebx
    mov cx,1
    CreateDiscSeq
    mov ebx,gs:bc_op_handle
    ModifySeqSector
    PerformDiscSeq
    pop ebx
;
    mov cx,1
    CreateDiscSeq
    ModifySeqSector
    PerformDiscSeq
;    
    mov ebx,gs:bc_op_handle
	WaitForSector
;
    mov es:[esi].le_status,0
;
    mov cx,1
    CreateDiscSeq
    ModifySeqSector
    PerformDiscSeq
;
    pop esi
    pop cx
    pop ebx
    pop ax
	ret
WriteSectorFree	Endp

code	ENDS

	END
