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
; FLTAB (Flash File System, cluster handling)
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
INCLUDE flashfs.inc

	.386p

code	SEGMENT byte public use16 'CODE'

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
	jz csaNext
;
	cmp al,-1
	je csaDone
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
;		NAME:			GetSector
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

GetSector	Proc near
	push di
;
	cmp bl,7Fh
	jae geFail
;
	movzx di,bl
	add di,di
	mov al,fs:[di].bc_log_sector_arr.bs_type
	or al,al
	jz geFail
;
	movzx edx,fs:[di].bc_log_sector_arr.bs_physical_sector
	add edx,fs:bc_start_sector
	clc
	jmp geDone

geFail:
	stc

geDone:
	pop di
	ret
GetSector	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateSector
;
;		DESCRIPTION:	Allocate a sector
;
;		PARAMETERS:		FS			Block selector
;						AL			Entry type
;
;		RETURNS:		EDX			Physical sector
;						BL			Entry #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateSector	Proc near
	push ax
	push cx
	push si
	push di
;
	mov cx,127
	xor bx,bx

asLogLoop:
	mov ah,fs:[bx].bc_log_sector_arr.bs_type
	or ah,ah
	jne asLogNext
;
	xor di,di
	mov cx,127

asPhysLoop:
	mov ah,fs:[di].bc_phys_sector_arr
	cmp ah,-1
	jne asPhysNext
;
	call AllocateSectorEntry
	jc asDone
;
	mov fs:[bx].bc_log_sector_arr.bs_type,al
	mov es:[esi].le_type,al
	mov ax,di
	mov fs:[bx].bc_log_sector_arr.bs_physical_sector,al
	inc al
	mov es:[esi].le_physical_sector,al
	shr bx,1
	mov fs:[di].bc_phys_sector_arr,bl
	mov es:[esi].le_logical_entry,bl
;
	push ebx
	mov ebx,fs:bc_handle
	ModifySector
	pop ebx
	clc
	jmp asDone

asPhysNext:
	inc si
	loop asPhysLoop
;
	stc
	jmp asDone

asLogNext:
	add bx,2
	loop asLogLoop
;
	stc

asDone:
	pop di
	pop si
	pop cx
	pop ax
	ret
AllocateSector	Endp

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
	jne cbFail
;
	mov ax,es:[esi].fc_logical_block
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
	mov fs:bc_logical_block,ax
	call CacheSectorArr
	clc
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
	ModifySector
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
;		NAME:			CacheRootDir
;
;		DESCRIPTION:	Cache root dir
;
;		PARAMETERS:		EDX		Sector (0)
;						BX		Dir sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CacheRootDir

CacheRootDir	PROC near
	push fs
	push eax
	push ebx
	push ecx
;
	xor bx,bx
	call GetBlock
	jnc crdEntry
;
	call AllocateBlock
	jc crdDone

crdEntry:
	xor bl,bl
	call GetSector
	jnc crdCheckEntry
;
	mov al,LOG_ENTRY_DIR_ENTRY
	call AllocateSector	
	jnc crdEntry
	jmp crdDone

crdCheckEntry:
	cmp al,LOG_ENTRY_DIR_ENTRY
	stc
	jne crdDone
;
	clc

crdDone:
	pop ecx
	pop ebx
	pop eax
	pop fs
	ret
CacheRootDir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CacheSubDir
;
;		DESCRIPTION:	Cache sub dir
;
;		PARAMETERS:		EDX		Sector
;						BX		Dir sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CacheSubDir

CacheSubDir	PROC near
	ret
CacheSubDir	Endp

code	ENDS

	END
