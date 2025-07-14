;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
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
