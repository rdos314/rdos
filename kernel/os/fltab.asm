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
	extrn MoveSector:near

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
	mov al,es:[ebx+esi].le_status
	cmp al,-1
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
	mov fs:bc_op_ads,esi
	sub edi,fs:bc_data_ptr
	add edi,fs:bc_handle_ptr
	mov edi,es:[edi]
	mov fs:bc_op_handle,edi
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
;		NAME:			CacheBlock
;
;		DESCRIPTION:	Cache sector array in block
;
;		PARAMETERS:		FS			Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CacheBlock
    
CacheBlock	Proc near
	pushad
;
	mov cx,ds:control_sectors
	mov edi,fs:bc_data_ptr

csaSectorLoop:
	mov ebx,es:[edi]
	xor esi,esi

csaLoop:
	mov al,es:[ebx+esi].le_status
	or al,al
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
	cmp al,-1
	je csaDone
;
    and al,1Fh
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
	mov bp,es:[ebx+esi].le_physical_sector
	or bp,bp
	jz csaNext
;
	cmp bp,ds:data_sectors
	ja csaNext
;
	push edi
	movzx edi,es:[ebx+esi].le_logical_entry
	shl edi,3
	add edi,fs:bc_log_sector_ptr
	mov es:[edi].bs_type,al
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
CacheBlock	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RedoBlock
;
;		DESCRIPTION:	Redo block (erase & copy)
;
;		PARAMETERS:		FS		Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RedoBlock	Proc near
	pushad
;
	mov edx,ds:spare_sector
	call EraseBlock
;
	mov edi,fs:bc_handle_ptr
	mov ebp,fs:bc_data_ptr
;
	mov cx,ds:control_sectors
	mov ax,ds:block_sectors
	sub ax,cx
	movzx eax,ax
	add edx,eax

rbRelockLoop:
	mov ebx,es:[edi]
	UnlockSector
	mov al,ds:drive_nr
	LockSector
	mov es:[edi],ebx
	mov es:[ebp],esi
	add edi,4
	add ebp,4
	inc edx
	loop rbRelockLoop
;
	mov cx,ds:data_sectors
	mov edi,fs:bc_data_ptr
	mov ebx,fs:bc_log_sector_ptr
	mov esi,es:[edi]
	xor bp,bp

rbLogLoop:
	mov al,es:[ebx].bs_type
	cmp al,LOG_ENTRY_OBJECT
	je rbWriteEntry
;
	cmp al,LOG_ENTRY_DIR_DATA
	je rbWriteEntry
;
	cmp al,LOG_ENTRY_DIR_ENTRY
	je rbWriteEntry
;
	cmp al,LOG_ENTRY_FILE_DATA
	je rbWriteEntry
;
	mov es:[ebx].bs_type,-1
	jmp rbLogNext

rbWriteEntry:
	mov eax,dword ptr es:[ebx].bs_owner
	mov dword ptr es:[esi].le_owner,eax	
	mov es:[esi].le_status,al
	mov ax,bp
	inc ax
	mov es:[esi].le_physical_sector,ax
;
	push ebx
	sub ebx,fs:bc_log_sector_ptr
	shr ebx,3
	mov es:[esi].le_logical_entry,bx
	push esi
	movzx esi,bp
	add esi,esi
	add esi,fs:bc_phys_sector_ptr
	mov es:[esi],bx
	pop esi
	pop ebx
;
	push ebx
	push ecx
	push esi
	push edi
	movzx cx,es:[esi].le_type
	movzx edx,es:[ebx].bs_physical_sector
	mov es:[ebx].bs_physical_sector,bp
	add edx,fs:bc_start_sector
	push edx
	movzx edx,bp
	add edx,ds:spare_sector
	mov al,ds:drive_nr
	LockSector
	mov edi,esi
	pop edx
	push ebx
	LockSector
	mov ax,cx
	call MoveSector
	UnlockSector
	pop ebx
	call WriteSector
	UnlockSector
	pop edi
	pop esi
	pop ecx
	pop ebx
;
	inc bp
	add si,8
	test si,1FFh
	jnz rbLogNext
;
	push ebx
	mov ebx,edi
	sub ebx,fs:bc_data_ptr
	add ebx,fs:bc_handle_ptr
	mov ebx,es:[ebx]
	call WriteSector
	pop ebx
;
	add edi,4
	mov esi,es:[edi]

rbLogNext:
	add ebx,8
	sub cx,1
	jnz rbLogLoop
;
	push ebx
	mov ebx,edi
	sub ebx,fs:bc_data_ptr
	add ebx,fs:bc_handle_ptr
	mov ebx,es:[ebx]
	call WriteSector
	pop ebx
;
    int 3
    mov edx,ds:spare_sector
	movzx eax,ds:block_sectors
	add edx,eax
	dec edx
	mov al,ds:drive_nr
	LockSector
	mov al,fs:bc_logical_block
	mov es:[esi].fc_logical_block,al
	mov ax,fs:bc_version
	inc ax
	mov es:[esi].fc_version,ax
	mov dword ptr es:[esi].fc_signature,FLASH_SIGN_OK
	call WriteSector
    UnlockSector
;
	movzx eax,bp
	mov edi,fs:bc_phys_sector_ptr
	add edi,eax
	add edi,eax
	movzx ecx,ds:data_sectors
	sub ecx,eax
	mov ax,-1
	rep stos word ptr es:[edi]
;
	mov edx,ds:spare_sector
	xchg edx,fs:bc_start_sector
	mov ds:spare_sector,edx
	clc
;
	popad
	ret
RedoBlock	Endp

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
;						AL			Entry type
;                       ECX         Owner
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBlockSector	Proc near
	push edi
;
	cmp bx,ds:data_sectors
	jae gbeFail
;
	movzx edi,bx
	shl edi,3
	add edi,fs:bc_log_sector_ptr
	mov al,es:[edi].bs_status
	mov ecx,es:[edi].bs_owner
	or al,al
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
;                       ECX         Owner logical sector
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
;
    mov edx,ecx

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
    mov dword ptr es:[esi].le_owner,edx
    mov es:[ebx].bs_owner,edx
	mov es:[ebx].bs_status,al
	or al,LOG_STATUS_BEFORE_ALLOC
	mov es:[esi].le_status,al
;	
	mov eax,edi
	sub eax,fs:bc_phys_sector_ptr
	shr eax,1
	mov es:[ebx].bs_physical_sector,ax
	movzx edx,ax
	add edx,fs:bc_start_sector
	inc ax
	mov es:[esi].le_physical_sector,ax
	sub ebx,fs:bc_log_sector_ptr
	shr ebx,3
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
	shl ebx,3
	mov es:[ebx].bs_status,LOG_ENTRY_ERASE
;
	mov es:[esi].le_status,0
	mov ebx,fs:bc_op_handle
	call WriteSector
	jmp absRetry

absPhysNext:
	add edi,2
	sub cx,1
	jnz absPhysLoop
;
	stc
	jmp absDone

absLogNext:
	add ebx,8
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
;		NAME:			AliasBlockSector
;
;		DESCRIPTION:	Alias a sector in block
;
;		PARAMETERS:		FS			Block selector
;						AX			Entry type
;						BX			Entry #
;                       ECX         Owner logical sector
;
;		RETURNS:		EDX			Physical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AliasBlockSector	Proc near
	push eax
	push cx
	push esi
	push edi
	push ebp
;
    mov edx,ecx

albsRetry:
	mov cx,ds:data_sectors
	mov edi,fs:bc_phys_sector_ptr

albsPhysLoop:
	mov bp,es:[edi]
	cmp bp,-1
	jne albsPhysNext
;
	call AllocateSectorEntry
	jc albsDone
;
    mov es:[esi].le_owner,edx
    or al,LOG_STATUS_BEFORE_ALLOC
	mov es:[esi].le_status,al
;
	mov eax,edi
	sub eax,fs:bc_phys_sector_ptr
	shr eax,1
	movzx edx,ax
	add edx,fs:bc_start_sector
	inc ax
	mov es:[esi].le_physical_sector,ax
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

albsBlankLoop:
	and ebp,es:[esi]
	add esi,4
	loop albsBlankLoop
;
	UnlockSector
	pop esi
	pop ebx
	inc ebp
	or ebp,ebp
	clc
	jz albsDone
;
	mov es:[esi].le_type,0
	push ebx
	mov ebx,fs:bc_op_handle
	call WriteSector
	pop ebx
	jmp albsRetry

albsPhysNext:
	add edi,2
	sub cx,1
	jnz albsPhysLoop
;
	stc

albsDone:
	pop ebp
	pop edi
	pop esi
	pop cx
	pop eax
	ret
AliasBlockSector	Endp

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
	shl eax,2
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
	mov cx,ds:data_sectors

absLoop:
    mov es:[edi].bs_owner,0
    mov es:[edi].bs_physical_sector,0
    mov es:[edi].bs_status,-1
    add edi,8
    loop absLoop
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
;		NAME:			InitBlock
;
;		DESCRIPTION:	Init a block
;
;		PARAMETERS:		EDX			Start sector of block
;
;		RETURNS:		FS			Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InitBlock

InitBlock	Proc near
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
	jne ibErase
;
	mov al,es:[esi].fc_logical_block
	push ax
	mov ax,es:[esi].fc_version
	call AllocateBlockSel
	mov fs:bc_version,ax
	pop ax
	mov fs:bc_logical_block,al
	clc
    jmp ibDone

ibErase:
    call EraseBlock
    xor ax,ax
    mov fs,ax
    stc

ibDone:
	popad
	ret
InitBlock	Endp

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
;                       ECX         Owner logical sector
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
;		NAME:			AliasSector
;
;		DESCRIPTION:	Alias a sector
;
;       PARAMETERS:     EBX			Logical sector #
;
;       RETURNS:        EBX         Logical sector #
;                       EDX         Physical sector #
;						FS			Block (for modify operation)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public AliasSector

AliasSector	PROC near
	push eax
	push ebx
	push ecx
;
    mov edx,edx
    shr ebx,16
    call GetBlock
    jc alsDone
;
    mov bx,dx
    call GetBlockSector
    jc alsDone
;
	call AliasBlockSector
	jnc alsOk
;
	call RedoBlock
	jc alsDone
;
	call AliasBlockSector
	jc alsDone

alsOk:
    clc

alsDone:
    pop ecx
	pop ebx
	pop eax
	ret
AliasSector	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeSector
;
;		DESCRIPTION:	Free a sector
;
;       PARAMETERS:     EDX			Logical sector #
;
;       RETURNS:        FS          Block for modify operation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FreeSector

FreeSector	PROC near
	pushad
;
    mov ebx,edx
	shr ebx,16
	call GetBlock
	jc fsDone
;
	movzx edi,dx
	shl edi,3
	add edi,fs:bc_log_sector_ptr
	mov es:[edi].bs_status,0
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
	stc
	je fsDone
;
	cmp bx,es:[esi+ebp].le_logical_entry
	jne fsNext
;
    add esi,ebp
    mov fs:bc_op_ads,esi
    mov ebx,edi
	sub ebx,fs:bc_data_ptr
	add ebx,fs:bc_handle_ptr
	mov ebx,es:[ebx]
	mov fs:bc_op_handle,ebx
	clc
	jmp fsDone

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
;
    stc

fsDone:	
	popad
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
	push esi
;
	xor bx,bx
	call GetBlock
	jnc grsEntry
;
	call AllocateBlock
	jc grsDone

grsEntry:
    push ecx
	xor bx,bx
	call GetBlockSector
	pop ecx
	jnc grsCheckEntry
;
    xor ecx,ecx
	mov ax,LOG_ENTRY_DIR_ENTRY
	call AllocateBlockSector	
	jc grsDone
;
    mov esi,fs:bc_op_ads
    mov al,es:[esi].le_status
    and al,1Fh
    or al,LOG_STATUS_AFTER_ALLOC
    mov es:[esi].le_status
	mov ebx,fs:bc_op_handle
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
    pop esi
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
;		PARAMETERS:	    ECX         Owner logical sector
;                       EDX         Logical sector
;
;		RETURNS:		EDX			Physical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DirEntryLogToPhysSector
    
DirEntryLogToPhysSector Proc near
    push fs
    push ax
    push ebx
    push ecx
    push ebp
;
    mov ebp,ecx
    mov ebx,edx
    shr ebx,16
    call GetBlock
    jc delpDone
;
    mov bx,dx
    call GetBlockSector
    jc delpDone
;
    cmp al,LOG_ENTRY_DIR_ENTRY
    stc
    jne delpDone
;
    cmp ebp,ecx
    stc
    jne delpDone
;
    clc

delpDone:
    pop ebp
    pop ecx
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
;		PARAMETERS:	    ECX         Owner logical sector
;                       EDX         Logical sector
;
;		RETURNS:		EDX			Physical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ObjectLogToPhysSector
    
ObjectLogToPhysSector Proc near
    push fs
    push ax
    push ebx
    push ecx
    push ebp
;
    mov ebp,ecx
    mov ebx,edx
    shr ebx,16
    call GetBlock
    jc olpDone
;
    mov bx,dx
    call GetBlockSector
    jc olpDone
;
    cmp al,LOG_ENTRY_OBJECT
    stc
    jne olpDone
;
    cmp ebp,ecx
    stc
    jne olpDone
;
    clc

olpDone:
    pop ebp
    pop ecx
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
;		PARAMETERS:	    ECX         Owner logical sector
;                       EDX         Logical sector
;
;		RETURNS:		EDX			Physical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DirDataLogToPhysSector
    
DirDataLogToPhysSector Proc near
    push fs
    push ax
    push ebx
    push ecx
    push ebp
;
    mov ebp,ecx
    mov ebx,edx
    shr ebx,16
    call GetBlock
    jc ddlpDone
;
    mov bx,dx
    call GetBlockSector
    jc ddlpDone
;
    cmp al,LOG_ENTRY_DIR_DATA
    stc
    jne ddlpDone
;
    cmp ebp,ecx
    stc
    jne ddlpDone
;
    clc

ddlpDone:
    pop ebp
    pop ecx
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
;		PARAMETERS:	    ECX         Owner logical sector
;                       EDX         Logical sector
;
;		RETURNS:		EDX			Physical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FileDataLogToPhysSector
    
FileDataLogToPhysSector Proc near
    push fs
    push ax
    push ebx
    push ecx
    push ebp
;
    mov ebp,ecx
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
    cmp ebp,ecx
    stc
    jne fdlpDone
;
    clc

fdlpDone:
    pop ebp
    pop eax
    pop ebx
    pop ax
    pop fs
    ret
FileDataLogToPhysSector Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			QueryDirEntrySector
;
;		DESCRIPTION:	Query dir entry sector
;
;		PARAMETERS:	    EDX         Logical sector
;
;		RETURNS:		ECX         Owner logical sector
;                       
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public QueryDirEntrySector
    
QueryDirEntrySector Proc near
    push fs
    push ax
    push ebx
    push edx
;
    mov ebx,edx
    shr ebx,16
    call GetBlock
    jc qdesDone
;
    mov bx,dx
    call GetBlockSector
    jc qdesDone
;
    cmp al,LOG_ENTRY_DIR_ENTRY
    stc
    jne qdesDone
;
    clc

qdesDone:
    pop edx
    pop ebx
    pop ax
    pop fs
    ret
QueryDirEntrySector Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			QueryObjectSector
;
;		DESCRIPTION:	Query object sector
;
;		PARAMETERS:	    EDX         Logical sector
;
;		RETURNS:		ECX         Owner logical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public QueryObjectSector
    
QueryObjectSector Proc near
    push fs
    push ax
    push ebx
    push edx
;
    mov ebx,edx
    shr ebx,16
    call GetBlock
    jc qosDone
;
    mov bx,dx
    call GetBlockSector
    jc qosDone
;
    cmp al,LOG_ENTRY_OBJECT
    stc
    jne qosDone
;
    clc

qosDone:
    pop edx
    pop ebx
    pop ax
    pop fs
    ret
QueryObjectSector Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			QueryDirDataSector
;
;		DESCRIPTION:	Query dir data sector
;
;		PARAMETERS:	    EDX         Logical sector
;
;		RETURNS:		ECX         Owner logical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public QueryDirDataSector
    
QueryDirDataSector Proc near
    push fs
    push ax
    push ebx
    push edx
;
    mov ebx,edx
    shr ebx,16
    call GetBlock
    jc qddsDone
;
    mov bx,dx
    call GetBlockSector
    jc qddsDone
;
    cmp al,LOG_ENTRY_DIR_DATA
    stc
    jne qddsDone
;
    clc

qddsDone:
    pop edx
    pop ebx
    pop ax
    pop fs
    ret
QueryDirDataSector Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			QueryFileDataSector
;
;		DESCRIPTION:	Query file data sector
;
;		PARAMETERS:	    EDX         Logical sector
;
;		RETURNS:		ECX         Owner logical sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public QueryFileDataSector
    
QueryFileDataSector Proc near
    push fs
    push ax
    push ebx
    push edx
;
    mov ebx,edx
    shr ebx,16
    call GetBlock
    jc qfdsDone
;
    mov bx,dx
    call GetBlockSector
    jc qfdsDone
;
    cmp ax,LOG_ENTRY_FILE_DATA
    stc
    jne qfdsDone
;
    clc

qfdsDone:
    pop edx
    pop ebx
    pop ax
    pop fs
    ret
QueryFileDataSector Endp


code	ENDS

	END
