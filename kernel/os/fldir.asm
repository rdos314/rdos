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
; FLDIR.ASM
; FLDIR (Flash File System, directory handling)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME fldir

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

    extrn WriteSector:near
    extrn DirEntryLogToPhysSector:near
    extrn ObjectLogToPhysSector:near
    extrn AllocateSector:near
    extrn GetRootSector:near

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetEntryNameSize
;
;		DESCRIPTION:	Get size of entryname
;
;		PARAMETERS:		ES:EDI  File name
;
;		RETURNS:		ECX		Size of entry name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetEntryNameSize	Proc near
	push ax
    pop ax
	ret
GetEntryNameSize	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateFileEntry
;
;		DESCRIPTION:    Create file entry
;
;		PARAMETERS:		BX			Dir selector
;                       ES:EDI      File name
;                       CX          Attribute
;
;		RETURNS:		EDX			Dir file entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateFileEntry	Proc near
    push es
    push fs
	push eax
	push bx
	push ecx
	push esi
	push edi
;
    mov ax,es
    mov fs,ax    
	push edi
;
	xor ecx,ecx

cfeNameSizeLoop:
    mov al,es:[edi]
    inc ecx
    inc edi
    or al,al
    jnz cfeNameSizeLoop

cfeNameSizeDone:
    pop esi
    mov ax,flat_sel
    mov es,ax
;
	mov eax,SIZE ffe_struc
	add eax,ecx
	AllocateSmallLinear
	mov edi,edx
	add edx,OFFSET ffe_name
	mov es:[edi].de_name,edx
	mov es:[edi].de_name_size,cx
;
	mov al,ds:drive_nr
	mov es:[edi].de_drive,al
	mov es:[edi].de_usage,0
;	mov es:[edi].ffe_entry_sector,edx

cfeCopyNameLoop:
    mov al,fs:[esi]
    mov es:[edx],al
    inc esi
    inc edx
    or al,al
    jnz cfeCopyNameLoop
;
    GetTime
	mov es:[edi].de_time,eax
	mov es:[edi+4].de_time,edx
;
	mov es:[edi].dfe_data_size,0
	mov es:[edi].dfe_file_sel,0
	mov edx,edi
;
	pop edi
	pop esi
	pop ecx
	pop bx
	pop eax
	pop fs
	pop es
	ret
CreateFileEntry	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindLastDirInfo
;
;		DESCRIPTION:    Find position of last dir entry info
;
;		PARAMETERS:		ESI			Dir entry data
;
;		RETURNS:		EAX			Offset to last valid dir info
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindLastDirInfo	Proc near
	push cx
	push esi
;
	inc esi
	mov cx,1FFh

fldiNameLoop:
	mov al,es:[esi]
	or al,al
	jz fldiNameEnd
;
	inc esi
	loop fldiNameLoop
;
	dec esi
	jmp fldiDone

fldiNameEnd:
	inc esi
	dec ecx

fldiSpaceLoop:
	mov al,es:[esi]
	cmp al,-1
	jne fldiDone
;
	inc esi
	loop fldiSpaceLoop
;
	dec esi

fldiDone:
	mov eax,esi
;
	pop esi
	pop cx
	ret
FindLastDirInfo	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ExtendDir
;
;		DESCRIPTION:    Extend directory, and add entry
;
;		PARAMETERS:		BX			Dir selector
;                       ES:EDI      File name
;                       CX          Attribute
;                       EDX         Dir file entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExtendDir	Proc near
	push es
	push fs
	pushad
;
	mov ax,flat_sel
	mov es,ax
    mov fs,bx
    mov edx,fs:ds_link
    call DirEntryLogToPhysSector
    jc edDone
;
    mov al,ds:drive_nr
    LockSector
	call FindLastDirInfo
	mov esi,eax
;
	mov eax,es:[esi-3]
	cmp eax,-1
	jne edPresent
;
	sub esi,0Fh
	xor ecx,ecx
	jmp edAlloc

edPresent:
	mov ecx,es:[esi].fde_size

edAlloc:
	mov eax,ecx
	shr eax,16
	inc eax	
	mov edi,esi
	sub edi,13
	sub edi,eax
	add eax,eax
	sub edi,eax
;
	push edi
	mov al,-1

edCheckSpace:
	and al,es:[edi]
	inc edi
	cmp esi,edi
	jne edCheckSpace
;
	pop edi
	add al,1
	jz edSpaceOk
;
	int 3

edSpaceOk:	
	mov eax,es:[esi].fde_size
	add eax,20h
	mov es:[edi].fde_size,eax
	mov eax,es:[esi].fde_time
	mov es:[edi].fde_time,eax
	mov eax,es:[esi].fde_time+4
	mov es:[edi].fde_time+4,eax
	add esi,OFFSET fde_log_entry
	add edi,OFFSET fde_log_entry
;
	push ecx
	dec ecx
	shr ecx,16
	inc cx
	or cx,cx
	jz edMoveDone

edMoveLoop:
	mov eax,es:[esi]
	mov es:[edi],eax
	add esi,3
	add edi,3
	loop edMoveLoop	

edMoveDone:
	xor ax,ax
	mov fs,ax
	pop ecx
	or cx,cx
	jnz edMakeValid

edAllocObjectSector:
	push ebx
	mov al,LOG_ENTRY_OBJECT
	call AllocateSector
	mov eax,ebx
	pop ebx
	jc edDone
;
	mov es:[edi],eax
	add edi,3

edMakeValid:
	mov byte ptr es:[edi],DIR_ENTRY_OK	
	ModifySector
;
	mov ax,fs
	or ax,ax
	jz edObjectOk
;
	push ebx
	mov ebx,fs:bc_handle
	ModifySector
	pop ebx
    UnlockSector
	clc

edObjectOk:

edDone:
	popad
	pop fs
	pop es
	ret
ExtendDir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddFileEntry
;
;		DESCRIPTION:    Add file entry
;
;		PARAMETERS:		BX			Dir selector
;                       ES:EDI      File name
;                       CX          Attribute
;                       EDX         Dir file entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFileEntry  Proc near
    push es
    push fs
	push gs
    push ax
    push ebx
    push edx
    push esi
    push edi
    push ebp
;
	call ExtendDir
	jc afeDone
;
    mov ebp,edx
    mov ax,es
    mov gs,ax
    mov ax,flat_sel
    mov es,ax
;
	mov al,LOG_ENTRY_DIR_ENTRY
	push ebx
	call AllocateSector
	pop ebx
	jc afeDone
;
	push ebx
    mov al,ds:drive_nr
    LockSector
;
    mov es:[esi],cl
    inc esi

afeLoop:
    mov al,gs:[edi]
    mov es:[esi],al
    inc esi
    inc edi
    or al,al
    jnz afeLoop
;
    and si,0FE00h
    add esi,1F0h
    mov es:[esi].fde_size,0
    mov eax,es:[ebp].de_time
    mov es:[esi].fde_time,eax
    mov eax,es:[ebp].de_time+4
    mov es:[esi].fde_time+4,eax
    mov es:[esi].fde_log_entry,-1
    mov es:[esi].fde_log_block,-1
    mov es:[esi].fde_valid,DIR_ENTRY_OK
    call WriteSector
    UnlockSector
	pop ebx
;
	mov ebx,fs:bc_handle
	call WriteSector
    clc
    
afeDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop ax
	pop gs
    pop fs
    pop es
    ret
AddFileEntry  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitRootDirEntry
;
;		DESCRIPTION:    Init root dir entry
;
;		PARAMETERS:		BX			Dir selector
;                       EDX         Logical sector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitRootDirEntry   Proc near
    pushad
;
    mov al,ds:drive_nr
    LockSector
    mov es:[esi].deh_attrib,10h
    mov es:[esi].deh_name,0
    add esi,1F0h
    mov es:[esi].fde_size,0
    GetTime
    mov es:[esi].fde_time,eax
    mov es:[esi].fde_time+4,edx
    mov es:[esi].fde_log_entry,-1
    mov es:[esi].fde_log_block,-1
    mov es:[esi].fde_valid,DIR_ENTRY_OK
    call WriteSector
    UnlockSector
;
    popad
    ret
InitRootDirEntry   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CacheDirEntry
;
;		DESCRIPTION:    Cache dir entry
;
;		PARAMETERS:		BX			Dir selector
;                       EDX         Logical sector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CacheDirEntry   Proc near
	push fs
    pushad
;
    mov fs,bx
    mov fs:ds_link,edx
    call DirEntryLogToPhysSector
    jc cdeFail
;
    mov al,ds:drive_nr
    LockSector
    mov al,es:[esi+1FFh]
    cmp al,-1
    je cdeFail
;
    UnlockSector
    clc
    jmp cdeDone

cdeFail:
    UnlockSector
    stc

cdeDone:
    popad
    pop fs
    ret
CacheDirEntry   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Cache_dir
;
;		DESCRIPTION:	Cache dir
;
;		PARAMETERS:		EDX			Dir entry to cache or 0
;						BX			Cached dir selector
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public cache_dir

cache_dir	PROC far
	push es
	push eax
	push edx
;
	mov ax,flat_sel
	mov es,ax
;
	or edx,edx
	jnz cache_sub_dir
;
	call GetRootSector
    jc cache_dir_done
;
    call CacheDirEntry
    jnc cache_dir_done
;
    call InitRootDirEntry
    call CacheDirEntry
	jmp cache_dir_done

cache_sub_dir:
;	call CacheSubDir

cache_dir_done:
    pop edx
	pop eax
	pop es
	ret
cache_dir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_FILE
;
;		DESCRIPTION:	Create file
;
;		PARAMETERS:		ES:EDI		Filename
;						BX			Dir
;						CX			Attribute
;
;		RETURNS:		EDX			Dir entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public create_file
    
create_file	PROC far
    int 3
    call CreateFileEntry
    call AddFileEntry
    jc cfFail
;    
	InsertFileEntry	
	jmp cfDone

cfFail:
    FreeLinear
    xor edx,edx
    stc

cfDone:
	ret
create_file	ENDP

code	ENDS

	END
