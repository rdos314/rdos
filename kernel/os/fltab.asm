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
    extrn InitRootDirEntry:near

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
	push cx
	push edi
;
	mov cx,ds:control_sectors
	mov edi,fs:bc_data_ptr

aseSectorLoop:
	mov ebx,es:[edi]
	xor esi,esi

aseLoop:
	mov ax,es:[ebx+esi].le_type
	cmp ax,-1
	jne aseNext
;
	mov ax,es:[ebx+esi].le_physical_sector
	cmp ax,-1
	jne aseNext
;
	mov ax,es:[ebx+esi].le_logical_entry
	cmp ax,-1
	jne aseNext
;
	add esi,ebx
	sub edi,fs:bc_data_ptr
	add edi,fs:bc_handle_ptr
	mov edi,es:[edi]
	mov fs:bc_alloc_handle,edi
	clc
	jmp aseDone

aseNext:
	or cx,cx
	jz aseCheckLast
;
	add esi,8
	test si,1F8h
	jnz aseLoop
;
	add edi,4
	dec cx
	jmp aseSectorLoop

aseCheckLast:
	add esi,8
	mov ax,si
	and ax,1FFh
	cmp ax,fc_logical_block
	jb aseLoop
;
	stc

aseDone:
	pop edi
	pop cx
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
	pushad
;
	mov cx,ds:control_sectors
	mov edi,fs:bc_data_ptr

csaSectorLoop:
	mov ebx,es:[edi]
	xor esi,esi

csaLoop:
	mov ax,es:[ebx+esi].le_type
	or ax,ax
	jnz csaNotDeleted
;
	mov ax,es:[ebx+esi].le_physical_sector
	or ax,ax
	jz csaNext
;
	cmp ax,ds:data_sectors
	ja csaNext
;
	push edi
	dec ax
	movzx eax,ax
	mov edi,fs:bc_phys_sector_ptr
	lea edi,[2*eax+edi]
	mov ax,es:[edi]
	cmp ax,-1
	jne csaPop
;
	mov word ptr es:[edi],0

csaPop:
	pop edi
	jmp csaNext

csaNotDeleted:
	cmp ax,-1
	je csaDone
;
	cmp ax,LOG_ENTRY_OBJECT
	je csaCache
;
	cmp ax,LOG_ENTRY_DIR_DATA
	je csaCache
;
	cmp ax,LOG_ENTRY_DIR_ENTRY
	je csaCache
;
	cmp ax,LOG_ENTRY_FILE_DATA
	jne csaNext

csaCache:
	mov bp,es:[ebx+esi].le_physical_sector
	or bp,bp
	jz csaNext
;
	cmp bp,ds:data_sectors
	ja csaNext
;
	push edi
	movzx edi,es:[ebx+esi].le_logical_entry
	shl edi,2
	add edi,fs:bc_log_sector_ptr
	mov es:[edi].bs_type,ax
	dec bp
	mov es:[edi].bs_physical_sector,bp
;
	movzx edi,bp
	add edi,edi
	mov ax,es:[ebx+esi].le_logical_entry
	add edi,fs:bc_phys_sector_ptr
	mov es:[edi],ax
	pop edi

csaNext:
	or cx,cx
	jz csaCheckLast
;
	add esi,8
	test si,1F8h
	jnz csaLoop
;
	add edi,4
	dec cx
	jmp csaSectorLoop

csaCheckLast:
	add esi,8
	mov ax,si
	and ax,1FFh
	cmp ax,fc_logical_block
	jb csaLoop

csaDone:	
	popad
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
	push es
	push ax
	push edx
	push edi
;
	mov ax,flat_sel
	mov es,ax
	xor edx,edx
	mov cx,ds:data_sectors
	mov edi,fs:bc_phys_sector_ptr

gfbsLoop:
	mov ax,es:[edi]
	cmp ax,-1
	jne gfbsNext
;
	inc edx

gfbsNext:
	add edi,2
	loop gfbsLoop
;
	mov ecx,edx
;
	pop edi
	pop edx
	pop ax
	pop es
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
;		PARAMETERS:		BX			Entry #
;						FS			Block selector
;
;		RETURNS:		EDX			Physical sector
;						AX			Entry type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBlockSector	Proc near
	push edi
;
	cmp bx,ds:data_sectors
	jae gbeFail
;
	movzx edi,bx
	shl edi,2
	add edi,fs:bc_log_sector_ptr
	mov ax,es:[edi].bs_type
	or ax,ax
	jz gbeFail
;
	movzx edx,es:[edi].bs_physical_sector
	add edx,fs:bc_start_sector
	clc
	jmp gbeDone

gbeFail:
	stc

gbeDone:
	pop edi
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
;						AX			Entry type
;
;		RETURNS:		EDX			Physical sector
;						BX			Entry #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlockSector	Proc near
	push eax
	push cx
	push esi
	push edi
	push ebp

absRetry:
	mov cx,ds:data_sectors
	mov ebx,fs:bc_log_sector_ptr

absLogLoop:
	mov bp,es:[ebx].bs_type
	or bp,bp
	jne absLogNext
;
	mov edi,fs:bc_phys_sector_ptr
	mov cx,ds:data_sectors

absPhysLoop:
	mov bp,es:[edi]
	cmp bp,-1
	jne absPhysNext
;
	call AllocateSectorEntry
	jc absDone
;
	mov es:[ebx].bs_type,ax
	mov es:[esi].le_type,ax
	mov eax,edi
	sub eax,fs:bc_phys_sector_ptr
	shr eax,1
	mov es:[ebx].bs_physical_sector,ax
	movzx edx,ax
	add edx,fs:bc_start_sector
	inc ax
	mov es:[esi].le_physical_sector,ax
	sub ebx,fs:bc_log_sector_ptr
	shr ebx,2
	mov es:[edi],bx
	mov es:[esi].le_logical_entry,bx
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
	shl ebx,2
	mov es:[ebx].bs_type,LOG_ENTRY_ERASE
	jmp absRetry

absPhysNext:
	add edi,2
	sub cx,1
	jnz absPhysLoop
;
	stc
	jmp absDone

absLogNext:
	add ebx,4
	sub cx,1
	jnz absLogLoop
;
	stc

absDone:
	pop ebp
	pop edi
	pop esi
	pop cx
	pop eax
	ret
AllocateBlockSector	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateBlockSel
;
;		DESCRIPTION:	Allocate block selector
;
;		RETURNS:		EDX			Physical sector
;
;		RETURNS:		FS			Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlockSel	Proc near
	pushad
;
	push es
	mov eax,SIZE block_seg
	AllocateSmallGlobalMem
	mov ax,es
	mov fs,ax
	pop es
;	
	push edx
	movzx eax,ds:data_sectors
	add eax,eax
	AllocateSmallLinear
	mov fs:bc_phys_sector_ptr,edx
	add eax,eax
	AllocateSmallLinear
	mov fs:bc_log_sector_ptr,edx
;
	movzx eax,ds:control_sectors
	shl eax,2
	AllocateSmallLinear
	mov fs:bc_handle_ptr,edx
	AllocateSmallLinear
	mov fs:bc_data_ptr,edx
	pop edx
;
	mov edi,fs:bc_handle_ptr
	mov ebp,fs:bc_data_ptr
	mov fs:bc_start_sector,edx
;
	mov cx,ds:control_sectors
	mov ax,ds:block_sectors
	sub ax,cx
	movzx eax,ax
	add edx,eax

absLockLoop:
	mov al,ds:drive_nr
	LockSector
	mov es:[edi],ebx
	mov es:[ebp],esi
	add edi,4
	add ebp,4
	inc edx
	loop absLockLoop
;
	mov edi,fs:bc_log_sector_ptr
	movzx ecx,ds:data_sectors
	mov eax,0FFFFh
	rep stos dword ptr es:[edi]
;
	mov edi,fs:bc_phys_sector_ptr
	movzx ecx,ds:data_sectors
	mov ax,-1
	rep stos word ptr es:[edi]
;
	popad
	ret
AllocateBlockSel	Endp

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
	pushad
;
	movzx eax,ds:block_sectors
	push edx
	add edx,eax
	dec edx
	mov al,ds:drive_nr
	LockSector
	pop edx
	mov eax,es:[esi].fc_signature
	UnlockSector
	cmp eax,FLASH_SIGN_OK
	jne cbErase
;
	mov al,es:[esi].fc_logical_block
	push ax
	mov ax,es:[esi].fc_version
	call AllocateBlockSel
	mov fs:bc_version,ax
	pop ax
	mov fs:bc_logical_block,al
	call CacheSectorArr
	clc
	jmp cbDone

cbErase:
    call EraseBlock
    xor ax,ax
    mov fs,ax

cbDone:
	popad
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
;		PARAMETERS:		BL		Logical block #
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
	movzx cx,ds:block_count

gbScanLoop:
	mov ax,ds:[di]
	or ax,ax
	jz gbScanNext
;
	mov fs,ax
	cmp bl,fs:bc_logical_block
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
;		PARAMETERS:		BL		Logical block #
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
	movzx cx,ds:block_count
	xor edx,edx

abScanLoop:
	mov ax,ds:[di]
	or ax,ax
	jnz abScanNext
;
	push bx
	push edx
	movzx eax,ds:block_sectors
	add edx,eax
	dec edx
	mov al,ds:drive_nr
	LockSector
	pop edx
	pop ax
	mov es:[esi].fc_logical_block,al
	mov word ptr es:[esi].fc_version,1
	mov dword ptr es:[esi].fc_signature,FLASH_SIGN_OK
;
	call AllocateBlockSel
	mov fs:bc_logical_block,al
	mov ds:[di],fs
;
	call WriteSector
	clc
	jmp abDone

abScanNext:
	movzx eax,ds:block_sectors
	add edx,eax
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
;       PARAMETERS:     AX          Entry type
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
    mov bx,si

asBlockLoop:
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
	mov bx,si
    cmp bl,ds:block_count
    jnz asBlockLoop
;
    stc
    jmp asDone

asOk:
    shl esi,16
	mov si,bx
	mov ebx,esi
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
	shr ebx,16
	call GetBlock
	pop ebx
	jc fsDone
;
	movzx edi,bx
	shl edi,2
	add edi,fs:bc_log_sector_ptr
	mov es:[edi].bs_type,0
	movzx edi,es:[edi].bs_physical_sector
	add edi,edi
	add edi,fs:bc_phys_sector_ptr
	mov word ptr es:[edi],0
;
	mov cx,ds:control_sectors
	mov edi,fs:bc_data_ptr

fsSectorLoop:
	mov ebp,es:[edi]
	xor esi,esi

fsLoop:
	mov ax,es:[esi+ebp].le_type
	or ax,ax
	jz fsNext
;
	cmp ax,-1
	je fsDone
;
	cmp bx,es:[esi+ebp].le_logical_entry
	jne fsNext
;
    push ebx
	mov es:[esi+ebp].le_type,0
    mov ebx,edi
	sub ebx,fs:bc_data_ptr
	add ebx,fs:bc_handle_ptr
	mov ebx,es:[ebx]
	call WriteSector
	pop ebx

fsNext:
	or cx,cx
	jz fsCheckLast
;
	add esi,8
	test si,1F8h
	jnz fsLoop
;
	add edi,4
	dec cx
	jmp fsSectorLoop

fsCheckLast:
	add esi,8
	mov ax,si
	and ax,1FFh
	cmp ax,fc_logical_block
	jb fsLoop

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
	xor bx,bx
	call GetBlockSector
	jnc grsCheckEntry
;
	mov ax,LOG_ENTRY_DIR_ENTRY
	call AllocateBlockSector	
	jc grsDone
;
	mov ebx,fs:bc_alloc_handle
	call WriteSector
;
    call InitRootDirEntry
	jmp grsEntry

grsCheckEntry:
	cmp ax,LOG_ENTRY_DIR_ENTRY
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
    shr ebx,16
    call GetBlock
    jc delpDone
;
    mov bx,dx
    call GetBlockSector
    jc delpDone
;
    cmp ax,LOG_ENTRY_DIR_ENTRY
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
    shr ebx,16
    call GetBlock
    jc olpDone
;
    mov bx,dx
    call GetBlockSector
    jc olpDone
;
    cmp ax,LOG_ENTRY_OBJECT
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
    shr ebx,16
    call GetBlock
    jc ddlpDone
;
    mov bx,dx
    call GetBlockSector
    jc ddlpDone
;
    cmp ax,LOG_ENTRY_DIR_DATA
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
    shr ebx,16
    call GetBlock
    jc fdlpDone
;
    mov bx,dx
    call GetBlockSector
    jc fdlpDone
;
    cmp ax,LOG_ENTRY_FILE_DATA
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
