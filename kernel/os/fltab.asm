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
; FLTAB.ASM
; FLTAB (Flash File System, logical sector handling)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME fltab

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

    extrn EraseBlock:near
    extrn WriteSector:near

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateSectorEntry
;
;		DESCRIPTION:	Allocate a new sector entry
;
;		PARAMETERS:		FS			Block selector
;
;		RETURNS:		ESI			Disc address			
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateSectorEntry	Proc near
	push ax
	push ebx
;
	mov ebx,fs:bc_ptr
	xor esi,esi

aseLoop:
	mov al,es:[ebx+esi].le_type
	cmp al,-1
	jne aseNext
;
	mov al,es:[ebx+esi].le_physical_sector
	cmp al,-1
	jne aseNext
;
	mov al,es:[ebx+esi].le_logical_entry
	cmp al,-1
	jne aseNext
;
	add esi,ebx
	clc
	jmp aseDone

aseNext:
	add esi,3
	cmp esi,fc_logical_block
	jb aseLoop
;
	stc

aseDone:
	pop ebx
	pop ax
	ret
AllocateSectorEntry	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CacheSectorArr
;
;		DESCRIPTION:	Cache sector array in block
;
;		PARAMETERS:		FS			Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CacheSectorArr	Proc near
	push ax
	push ebx
	push cx
	push esi
	push edi
;
	push es
	mov ax,fs
	mov es,ax
	mov di,OFFSET bc_log_sector_arr
	mov cx,127
	mov ax,0FFh
	rep stosw
;
	mov di,OFFSET bc_phys_sector_arr
	mov cx,127
	mov al,-1
	rep stosb
	pop es
;
	mov ebx,fs:bc_ptr
	xor esi,esi

csaLoop:
	mov al,es:[ebx+esi].le_type
	or al,al
	jnz csaNotDeleted
;
	mov al,es:[ebx+esi].le_physical_sector
	or al,al
	jz csaNext
;
	test al,80h
	jnz csaNext
;
	dec al
	movzx di,al
	mov al,fs:[di].bc_phys_sector_arr
	cmp al,-1
	jne csaNext
;
	mov fs:[di].bc_phys_sector_arr,0
	jmp csaNext

csaNotDeleted:
	cmp al,-1
	je csaDone
;
	cmp al,LOG_ENTRY_OBJECT
	je csaCache
;
	cmp al,LOG_ENTRY_DIR_DATA
	je csaCache
;
	cmp al,LOG_ENTRY_DIR_ENTRY
	je csaCache
;
	cmp al,LOG_ENTRY_FILE_DATA
	jne csaNext

csaCache:
	movzx di,es:[ebx+esi].le_logical_entry
	add di,di
	mov ah,es:[ebx+esi].le_physical_sector
	or ah,ah
	jz csaNext
;
	test ah,80h
	jnz csaNext
;
	mov fs:[di].bc_log_sector_arr.bs_type,al
	dec ah
	mov fs:[di].bc_log_sector_arr.bs_physical_sector,ah
;
	movzx di,ah
	mov al,es:[ebx+esi].le_logical_entry
	mov fs:[di].bc_phys_sector_arr,al

csaNext:
	add esi,3
	cmp esi,fc_logical_block
	jb csaLoop

csaDone:	
	pop edi
	pop esi
	pop cx
	pop ebx
	pop ax
	ret
CacheSectorArr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetFreeBlockSectors
;
;		DESCRIPTION:	Get free sectors in block
;
;		PARAMETERS:		FS		Block selector
;
;		RETURNS:		ECX		Free sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetFreeBlockSectors

GetFreeBlockSectors	Proc near
	push ax
	push edx
	push di
;
	xor edx,edx
	mov cx,127
	mov di,OFFSET bc_phys_sector_arr

gfbsLoop:
	mov al,fs:[di]
	cmp al,-1
	jne gfbsNext
;
	inc edx

gfbsNext:
	inc di
	loop gfbsLoop
;
	mov ecx,edx
;
	pop di
	pop edx
	pop ax
	ret
GetFreeBlockSectors	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetBlockSector
;
;		DESCRIPTION:	Get a sector
;
;		PARAMETERS:		BL			Entry #
;						FS			Block selector
;
;		RETURNS:		EDX			Physical sector
;						AL			Entry type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBlockSector	Proc near
	push di
;
	cmp bl,7Fh
	jae gbeFail
;
	movzx di,bl
	add di,di
	mov al,fs:[di].bc_log_sector_arr.bs_type
	or al,al
	jz gbeFail
;
	movzx edx,fs:[di].bc_log_sector_arr.bs_physical_sector
	add edx,fs:bc_start_sector
	clc
	jmp gbeDone

gbeFail:
	stc

gbeDone:
	pop di
	ret
GetBlockSector	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateBlockSector
;
;		DESCRIPTION:	Allocate a sector in block
;
;		PARAMETERS:		FS			Block selector
;						AL			Entry type
;
;		RETURNS:		EDX			Physical sector
;						BL			Entry #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlockSector	Proc near
	push eax
	push cx
	push esi
	push di
	push ebp

absRetry:
	mov cx,127
	xor bx,bx

absLogLoop:
	mov ah,fs:[bx].bc_log_sector_arr.bs_type
	or ah,ah
	jne absLogNext
;
	xor di,di
	mov cx,127

absPhysLoop:
	mov ah,fs:[di].bc_phys_sector_arr
	cmp ah,-1
	jne absPhysNext
;
	call AllocateSectorEntry
	jc absDone
;
	mov fs:[bx].bc_log_sector_arr.bs_type,al
	mov es:[esi].le_type,al
	mov ax,di
	mov fs:[bx].bc_log_sector_arr.bs_physical_sector,al
	movzx edx,al
	add edx,fs:bc_start_sector
	inc al
	mov es:[esi].le_physical_sector,al
	shr bx,1
	mov fs:[di].bc_phys_sector_arr,bl
	mov es:[esi].le_logical_entry,bl
;
	push ebx
	push esi
	push ax
	mov al,ds:drive_nr
	LockSector
	pop ax
	mov ebp,-1
	mov cx,80h

absBlankLoop:
	and ebp,es:[esi]
	add esi,4
	loop absBlankLoop
;
	UnlockSector
	pop esi
	pop ebx
	inc ebp
	or ebp,ebp
	clc
	jz absDone
;
	mov fs:[bx].bc_log_sector_arr.bs_type,LOG_ENTRY_ERASE
	clc
	jmp absRetry

absPhysNext:
	inc di
	loop absPhysLoop
;
	stc
	jmp absDone

absLogNext:
	add bx,2
	sub cx,1
	jnz absLogLoop
;
	stc

absDone:
	pop ebp
	pop di
	pop esi
	pop cx
	pop eax
	ret
AllocateBlockSector	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CacheBlock
;
;		DESCRIPTION:	Cache a block
;
;		PARAMETERS:		EDX			Start sector of block
;
;		RETURNS:		FS			Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CacheBlock

CacheBlock	Proc near
	push eax
	push ebx
	push esi
;
	mov al,ds:drive_nr
	add edx,7Fh
	LockSector
	sub edx,7Fh
	mov ax,es:[esi].fc_signature
	cmp ax,FLASH_SIGN_OK
	jne cbErase
;
	mov ax,es:[esi].fc_logical_block
	push ax
	mov ax,es:[esi].fc_version
	push ax
	push es
	mov eax,SIZE block_seg
	AllocateSmallGlobalMem
	mov ax,es
	mov fs,ax
	pop es
;	
	mov fs:bc_handle,ebx
	mov fs:bc_ptr,esi
	mov fs:bc_start_sector,edx
	pop ax
	mov fs:bc_version,ax
	pop ax
	mov fs:bc_logical_block,ax
	call CacheSectorArr
	clc
	jmp cbDone

cbErase:
    UnlockSector
    call EraseBlock
    xor ax,ax
    mov fs,ax
    jmp cbDone

cbFail:
	UnlockSector
	xor ax,ax
	mov fs,ax
	stc

cbDone:
	pop esi
	pop ebx
	pop eax
	ret
CacheBlock	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetBlock
;
;		DESCRIPTION:	Get a block
;
;		PARAMETERS:		BX		Logical block #
;
;		RETURNS:		FS		Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBlock	Proc near
	push ax
	push cx
	push di
;
	mov di,SIZE drive_data_seg
	mov cx,ds:block_count

gbScanLoop:
	mov ax,ds:[di]
	or ax,ax
	jz gbScanNext
;
	mov fs,ax
	cmp bx,fs:bc_logical_block
	clc
	je gbDone

gbScanNext:
	add di,2
	loop gbScanLoop
;
	xor ax,ax
	mov fs,ax
	stc

gbDone:
	pop di
	pop cx
	pop ax
	ret
GetBlock	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateBlock
;
;		DESCRIPTION:	Allocate a new block
;
;		PARAMETERS:		BX		Logical block #
;
;		RETURNS:		FS		Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateBlock
    
AllocateBlock	Proc near
	push ax
	push ebx
	push cx
	push edx
	push esi
	push di
;
	mov di,SIZE drive_data_seg
	mov cx,ds:block_count
	xor edx,edx

abScanLoop:
	mov ax,ds:[di]
	or ax,ax
	jnz abScanNext
;
	push bx
	add edx,7Fh
	mov al,ds:drive_nr
	LockSector
	sub edx,7Fh
	pop ax
	mov es:[esi].fc_logical_block,ax
	mov byte ptr es:[esi].fc_version,1
	mov word ptr es:[esi].fc_signature,FLASH_SIGN_OK
;
	push ax
	push es
	mov eax,SIZE block_seg
	AllocateSmallGlobalMem
;
	push cx
	push di
	mov di,OFFSET bc_log_sector_arr
	mov ax,0FFh
	mov cx,127
	rep stosw
;
	mov di,OFFSET bc_phys_sector_arr
	mov al,-1
	mov cx,127
	rep stosb
	pop di
	pop cx
;
	mov ax,es
	mov fs,ax
	pop es
;
	mov fs:bc_handle,ebx
	mov fs:bc_ptr,esi
	mov fs:bc_start_sector,edx
	pop ax
	mov fs:bc_logical_block,ax
	mov ds:[di],fs
;
	call WriteSector
	clc
	jmp abDone

abScanNext:
	add edx,80h
	add di,2
	sub cx,1
	jnz abScanLoop
;
	stc

abDone:
	pop di
	pop esi
	pop edx
	pop cx
	pop ebx
	pop ax
	ret
AllocateBlock	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateSector
;
;		DESCRIPTION:	Allocate a sector in any block
;
;       PARAMETERS:     AL          Entry type
;
;       RETURNS:        EBX         Logical sector #
;                       EDX         Physical sector #
;						FS			Block (for modify operation)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public AllocateSector

AllocateSector	PROC near
	push eax
	push esi
;
    xor esi,esi

asBlockLoop:
    mov bx,si
	call GetBlock
	jnc asEntry
;
	call AllocateBlock
	jc asDone

asEntry:
	call AllocateBlockSector	
	jnc asOk
;
    inc si
    cmp si,ds:block_count
    jnz asBlockLoop
;
    stc
    jmp asDone

asOk:
    shl esi,8
    movzx ebx,bl
    or ebx,esi
    clc

asDone:
    pop esi
	pop eax
	ret
AllocateSector	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeSector
;
;		DESCRIPTION:	Free a sector
;
;       PARAMETERS:     EBX			Logical sector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FreeSector

FreeSector	PROC near
	push fs
	pushad
;
	push ebx
	shr ebx,8
	call GetBlock
	pop ebx
	jc fsDone
;
	movzx di,bl
	add di,di
	mov fs:[di].bc_log_sector_arr.bs_type,0
	movzx di,fs:[di].bc_log_sector_arr.bs_physical_sector
	mov fs:[di].bc_phys_sector_arr,0
;
	mov edi,fs:bc_ptr
	xor esi,esi

fsLoop:
	mov al,es:[esi+edi].le_type
	or al,al
	jz fsNext
;
	cmp al,-1
	je fsUpdate
;
	cmp bl,es:[esi+edi].le_logical_entry
	jne fsNext
;
	mov es:[esi+edi].le_type,0

fsNext:
	add esi,3
	cmp esi,fc_logical_block
	jb fsLoop

fsUpdate:
	mov ebx,fs:bc_handle
	call WriteSector

fsDone:	
	popad
	pop fs
	ret
FreeSector	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetRootDir
;
;		DESCRIPTION:	Get root dir
;
;		PARAMETERS:		BX		Dir sel
;
;       RETURNS:        EDX     Logical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetRootSector

GetRootSector	PROC near
	push fs
	push eax
	push ebx
	push ecx
;
	xor bx,bx
	call GetBlock
	jnc grsEntry
;
	call AllocateBlock
	jc grsDone

grsEntry:
	xor bl,bl
	call GetBlockSector
	jnc grsCheckEntry
;
	mov al,LOG_ENTRY_DIR_ENTRY
	call AllocateBlockSector	
	jc grsDone
;
	mov ebx,fs:bc_handle
	call WriteSector
	jmp grsEntry

grsCheckEntry:
	cmp al,LOG_ENTRY_DIR_ENTRY
	stc
	jne grsDone
;
    xor edx,edx
	clc

grsDone:
	pop ecx
	pop ebx
	pop eax
	pop fs
	ret
GetRootSector	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DirEntryLogToPhysSector
;
;		DESCRIPTION:	Convert dir entry log sector to physical sector
;
;		PARAMETERS:	    EDX         Logical sector
;
;		RETURNS:		EDX			Physical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DirEntryLogToPhysSector
    
DirEntryLogToPhysSector Proc near
    push fs
    push ax
    push ebx
;
    mov ebx,edx
    shr ebx,8
    call GetBlock
    jc delpDone
;
    mov bl,dl
    call GetBlockSector
    jc delpDone
;
    cmp al,LOG_ENTRY_DIR_ENTRY
    stc
    jne delpDone
;
    clc

delpDone:
    pop ebx
    pop ax
    pop fs
    ret
DirEntryLogToPhysSector Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ObjectLogToPhysSector
;
;		DESCRIPTION:	Convert object log sector to physical sector
;
;		PARAMETERS:	    EDX         Logical sector
;
;		RETURNS:		EDX			Physical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ObjectLogToPhysSector
    
ObjectLogToPhysSector Proc near
    push fs
    push ax
    push ebx
;
    mov ebx,edx
    shr ebx,8
    call GetBlock
    jc olpDone
;
    mov bl,dl
    call GetBlockSector
    jc olpDone
;
    cmp al,LOG_ENTRY_OBJECT
    stc
    jne olpDone
;
    clc

olpDone:
    pop ebx
    pop ax
    pop fs
    ret
ObjectLogToPhysSector Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DirDataLogToPhysSector
;
;		DESCRIPTION:	Convert dir data log sector to physical sector
;
;		PARAMETERS:	    EDX         Logical sector
;
;		RETURNS:		EDX			Physical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DirDataLogToPhysSector
    
DirDataLogToPhysSector Proc near
    push fs
    push ax
    push ebx
;
    mov ebx,edx
    shr ebx,8
    call GetBlock
    jc ddlpDone
;
    mov bl,dl
    call GetBlockSector
    jc ddlpDone
;
    cmp al,LOG_ENTRY_DIR_DATA
    stc
    jne ddlpDone
;
    clc

ddlpDone:
    pop ebx
    pop ax
    pop fs
    ret
DirDataLogToPhysSector Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FileDataLogToPhysSector
;
;		DESCRIPTION:	Convert file data log sector to physical sector
;
;		PARAMETERS:	    EDX         Logical sector
;
;		RETURNS:		EDX			Physical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FileDataLogToPhysSector
    
FileDataLogToPhysSector Proc near
    push fs
    push ax
    push ebx
;
    mov ebx,edx
    shr ebx,8
    call GetBlock
    jc fdlpDone
;
    mov bl,dl
    call GetBlockSector
    jc fdlpDone
;
    cmp al,LOG_ENTRY_FILE_DATA
    stc
    jne fdlpDone
;
    clc

fdlpDone:
    pop ebx
    pop ax
    pop fs
    ret
FileDataLogToPhysSector Endp


code	ENDS

	END
