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
; RDFSTAB.ASM
; Tables for RDFS (RDOS File System)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME rdfstab

GateSize = 16

INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc
INCLUDE system.def
INCLUDE int.def
INCLUDE system.inc
INCLUDE rdfs.inc


	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FormatInfoSector
;
;		DESCRIPTION:	Format info sector
;
;		PARAMETERS:		DS			Drive
;						ECX			Number of sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FormatInfoSector

FormatInfoSector	Proc near
	pushad
;
	mov al,ds:drive_nr
	mov edx,1
	NewSector
;
	mov edi,esi
	mov ecx,128
	xor eax,eax
	rep stos dword ptr es:[edi]
;
	mov edi,esi
	mov esi,OFFSET info_sector
	mov ecx,SIZE rdfs_info_struc
	rep movs byte ptr es:[edi],[esi]
;
	ModifySector
	UnlockSector
;
	popad
	ret
FormatInfoSector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FormatAllocationArr
;
;		DESCRIPTION:	Format allocation array
;
;		PARAMETERS:		DS			Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FormatAllocationArr

FormatAllocationArr	Proc near
	pushad
;
	mov al,ds:drive_nr
	mov edx,2
	NewSector
;
	mov eax,-1
	mov ecx,ds:info_sector.ri_root_dir
format_alloc_used_loop:
	mov dword ptr es:[esi],eax
	add esi,4
	test si,01FFh
	jnz format_alloc_used_next
;
	ModifySector
	UnlockSector
	inc edx
	push ax
	mov al,ds:drive_nr
	NewSector
	pop ax

format_alloc_used_next:
	loop format_alloc_used_loop
;
	xor eax,eax

format_alloc_free_loop:
	mov dword ptr es:[esi],eax
	add esi,4
	test si,01FFh
	jnz format_alloc_free_loop
;
	ModifySector
	UnlockSector
	inc edx
	cmp edx,ds:info_sector.ri_root_dir
	je format_alloc_done
;
	push ax
	mov al,ds:drive_nr
	NewSector
	pop ax
	jmp format_alloc_free_loop

format_alloc_done:
	popad
	ret
FormatAllocationArr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteInfoSector
;
;		DESCRIPTION:	Write info sector
;
;		PARAMETERS:		DS			Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInfoSector	Proc near
	pushad
;
	mov al,ds:drive_nr
	mov edx,1
	LockSector
;
	mov edi,esi
	mov esi,OFFSET info_sector
	mov ecx,SIZE rdfs_info_struc
	rep movs byte ptr es:[edi],[esi]
;
	ModifySector
	UnlockSector
;
	popad
	ret
WriteInfoSector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeAllocationArr
;
;		DESCRIPTION:	Free allocation array
;
;		PARAMETERS:		DS			Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FreeAllocationArr

FreeAllocationArr	Proc near
	push es
	push fs
	push ecx
	push edx
	push edi
;
	mov cx,ds:alloc_sel
	or cx,cx
	jz free_alloc_done
;
	mov fs,cx
	mov ecx,fs:as_sectors
	mov edi,SIZE alloc_struc

free_alloc_unlock_loop:
	mov ebx,fs:[edi]
	or ebx,ebx
	jz free_alloc_unlock_next
;
	UnlockSector

free_alloc_unlock_next:
	add edi,4
	sub ecx,80h
	ja free_alloc_unlock_loop
;
	mov edx,fs:as_base
	mov ecx,fs:as_size
	FreeLinear
	mov ax,fs
	mov es,ax
	xor ax,ax
	mov fs,ax
	FreeMem
	mov ds:alloc_sel,0

free_alloc_done:
	pop edi
	pop edx
	pop ecx
	pop fs
	pop es
	ret
FreeAllocationArr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadAllocSectors
;
;		DESCRIPTION:	Req & wait for allocate sectors
;
;		PARAMETERS:		DS			Drive
;						FS			Alloc segment
;						ESI			Alloc buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadAllocSectors	Proc near
	mov edi,SIZE alloc_struc
	mov edx,ds:info_sector.ri_hole_start
	shr edx,7
	add edx,ds:info_sector.ri_free_arr
	mov ecx,fs:as_sectors

read_alloc_req_loop:
	mov al,ds:drive_nr
	ReqSector
	mov fs:[edi],ebx
	add edi,4
	add esi,200h
	inc edx
	sub ecx,80h
	ja read_alloc_req_loop
;
	mov ecx,fs:as_sectors

read_alloc_wait_loop:
	sub esi,200h
	sub edi,4
	mov ebx,fs:[edi]
	WaitForSector
	jc read_alloc_fail
;
	sub ecx,80h
	ja read_alloc_wait_loop
;
	clc
	jmp read_alloc_done

read_alloc_fail:
	lea eax,[edi + 4 - SIZE alloc_struc]
	shl eax,5
	mov edx,ds:info_sector.ri_hole_start
	and dl,80h
	add edx,eax
	sub edx,ds:info_sector.ri_hole_start
	add ds:info_sector.ri_hole_start,edx
	sub ds:info_sector.ri_hole_size,edx
	sub ds:info_sector.ri_free_sectors,edx	
	stc

read_alloc_done:
	ret
ReadAllocSectors	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetAllocArr
;
;		DESCRIPTION:	Get allocation array
;
;		PARAMETERS:		DS			Drive
;						ECX			Number of sectors wanted
;
;		RETURNS:		FS			Alloc segment
;						ESI			Alloc buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAllocArr	Proc near
	push eax
	push ebx
	push ecx
	push edx
	push edi
;
	mov dx,ds:alloc_sel
	or dx,dx
	jz get_alloc_new
;
	mov fs,dx
	mov edx,ds:info_sector.ri_hole_start
	sub edx,fs:as_start
	jc get_alloc_realloc
;
	add edx,ecx
	cmp edx,fs:as_sectors
	ja get_alloc_realloc
;
	mov esi,fs:as_base
	clc
	jmp get_alloc_ok

get_alloc_realloc:
	xor ax,ax
	mov fs,ax
	call FreeAllocationArr

get_alloc_new:
	mov edx,ds:info_sector.ri_hole_start
	mov eax,edx
	and dl,80h
	and eax,7Fh
	add eax,ecx
	dec eax
	shr eax,7
	and al,0F8h
	add eax,8
	mov ecx,eax
	shl eax,2
	add eax,SIZE alloc_struc
	push es
	AllocateSmallGlobalMem
	push ecx
	mov edi,SIZE alloc_struc
	xor eax,eax
	rep stos dword ptr es:[edi]
	pop ecx
	mov bx,es
	mov ds:alloc_sel,bx
	mov fs,bx
	pop es
	mov fs:as_start,edx
	shl ecx,7
	mov fs:as_sectors,ecx
;
	mov eax,ecx
	shl eax,2
	AllocateBigLinear	
	mov esi,edx
	mov fs:as_base,esi
	mov fs:as_size,eax
	call ReadAllocSectors

get_alloc_ok:
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
GetAllocArr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MarkAllocSectors
;
;		DESCRIPTION:	Markup allocate sectors
;
;		PARAMETERS:		DS			Drive
;						FS			Alloc segment
;						ESI			Alloc buffer
;						ECX			Sectors to mark
;						EBP			Markup value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MarkAllocSectors	Proc near
	push eax
	push ebx
	push ecx
	push esi
	push edi
;
	mov eax,ds:info_sector.ri_hole_start
	shl eax,2
	and eax,1FCh
	add esi,eax	
	mov edi,SIZE alloc_struc
	xor ebx,ebx

mark_alloc_loop:
	mov eax,es:[esi]
	or eax,eax	
	jnz mark_alloc_fail
;
	inc ebx
	mov es:[esi],ebp
	add esi,4
	sub ecx,1
	jnz mark_alloc_loop
;
	clc
	jmp mark_alloc_done

mark_alloc_fail:
	or ebx,ebx
	jz mark_alloc_advance
;
	push ebx
	push esi
	xor eax,eax

mark_alloc_revert:
	sub esi,4
	mov es:[esi],eax
	sub ebx,1
	jnz mark_alloc_revert
;
	pop esi
	pop ebx

mark_alloc_advance:
	inc ebx
	add esi,4
	test si,1FFh
	jz mark_alloc_fail_done
;
	mov eax,es:[esi]
	or eax,eax	
	jnz mark_alloc_advance

mark_alloc_fail_done:
	add ds:info_sector.ri_hole_start,ebx
	sub ds:info_sector.ri_hole_size,ebx
	sub ds:info_sector.ri_free_sectors,ebx	
	stc

mark_alloc_done:
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop eax
	ret
MarkAllocSectors	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteAllocSectors
;
;		DESCRIPTION:	Write allocate sectors
;
;		PARAMETERS:		DS			Drive
;						FS			Alloc segment
;						ECX			Sectors to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteAllocSectors	Proc near
	push eax
	push ebx
	push ecx
	push edi
;
	mov eax,ds:info_sector.ri_hole_start
	sub eax,fs:as_start
	shr eax,7
	lea edi,[4*eax + SIZE alloc_struc]
;
	add ecx,ds:info_sector.ri_hole_start
	dec ecx
	sub ecx,fs:as_start
	shr ecx,7
	sub ecx,eax
	inc ecx	

write_alloc_loop:
	mov ebx,fs:[edi]
	ModifySeqSector
	add edi,4
	sub ecx,1
	jnz write_alloc_loop
;
	pop edi
	pop ecx
	pop ebx
	pop eax
	ret
WriteAllocSectors	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateSectors
;
;		DESCRIPTION:	Allocate sectors
;
;		PARAMETERS:		DS			Drive
;						ECX			Number of sectors
;						EAX			Control sector
;
;		RETURNS:		EDX			Sector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public AllocateSectors

AllocateSectors	Proc near
	push es
	push fs
	push eax
	push ebx
	push ecx
	push esi
	push edi
	push ebp
;
	mov ebp,eax
	EnterSection ds:alloc_section

alloc_retry:
	cmp ecx,ds:info_sector.ri_hole_size
	ja alloc_sectors_fail
;
	call GetAllocArr
	jc alloc_retry
;
	call MarkAllocSectors
	jc alloc_retry
;
	call WriteAllocSectors
;
	mov edx,ds:info_sector.ri_hole_start
	add ds:info_sector.ri_hole_start,ecx
	sub ds:info_sector.ri_hole_size,ecx
	sub ds:info_sector.ri_free_sectors,ecx
	clc
	jmp alloc_sectors_done

alloc_sectors_fail:
	stc

alloc_sectors_done:
	call WriteInfoSector
	LeaveSection ds:alloc_section
;
	pop ebp
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop eax
	pop fs
	pop es
	ret
AllocateSectors	Endp

code	ENDS

	END

