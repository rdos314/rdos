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
	extrn WriteSectorAlloc:near
    extrn DirEntryLogToPhysSector:near
    extrn ObjectLogToPhysSector:near
    extrn DirDataLogToPhysSector:near
    extrn AllocateSector:near
	extrn FreeSector:near
    extrn GetRootSector:near

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateDirEntry
;
;		DESCRIPTION:    Create directory entry
;
;		PARAMETERS:		BX			Dir selector
;                       ES:EDI      Dir name
;                       CX          Attribute
;
;		RETURNS:		EDX			Dir dir entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDirEntry	Proc near
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

cdeNameSizeLoop:
    mov al,es:[edi]
    inc ecx
    inc edi
    or al,al
    jnz cdeNameSizeLoop

cdeNameSizeDone:
    pop esi
    mov ax,flat_sel
    mov es,ax
;
	mov eax,SIZE fde_struc
	add eax,ecx
	AllocateSmallLinear
	mov edi,edx
	add edx,OFFSET fde_name
	mov es:[edi].de_name,edx
	dec cx
	mov es:[edi].de_name_size,cx
;
	mov al,ds:drive_nr
	mov es:[edi].de_drive,al
	mov es:[edi].de_usage,0

cdeCopyNameLoop:
    mov al,fs:[esi]
    mov es:[edx],al
    inc esi
    inc edx
    or al,al
    jnz cdeCopyNameLoop
;
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
CreateDirEntry	Endp

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
	dec cx
	mov es:[edi].de_name_size,cx
;
	mov al,ds:drive_nr
	mov es:[edi].de_drive,al
	mov es:[edi].de_usage,0

cfeCopyNameLoop:
    mov al,fs:[esi]
    mov es:[edx],al
    inc esi
    inc edx
    or al,al
    jnz cfeCopyNameLoop
;
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
;		NAME:			FindDirInfo
;
;		DESCRIPTION:    Find position of valid dir entry info
;
;		PARAMETERS:		ESI			Dir entry data
;						EBX			Dir entry handle
;
;		RETURNS:		EAX			Offset to last valid dir info
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindDirInfo	Proc near
	push cx
	push esi
	push edi
	push ebp
;
	mov edi,esi
	add edi,200h
	inc esi
	mov cx,1FFh

fdiNameLoop:
	mov al,es:[esi]
	or al,al
	jz fdiNameEnd
;
	inc esi
	loop fdiNameLoop
;
	push edx
	sub esi,SIZE dir_entry_struc
	mov es:[esi].fde_size,0
	GetTime
	mov es:[esi].fde_time,eax
	mov es:[esi].fde_time+4,edx
	pop edx
	mov es:[esi].fde_valid,DIR_ENTRY_OK
	call WriteSector
	jmp fdiDone

fdiNameEnd:
	inc esi
	dec ecx

fdiSpaceLoop:
	mov al,es:[esi]
	cmp al,-1
	jne fdiCheck
;
	inc esi
	loop fdiSpaceLoop
;
	dec esi

fdiCheck:
	mov ebp,esi

fdiRetry:
	mov eax,es:[esi].fde_size
	shr eax,16
	mov cx,ax
	add cx,cx
	add ax,cx
	mov cl,es:[esi+eax].fde_valid
	cmp cl,DIR_ENTRY_OK
	je fdiDone
;
	add esi,eax
	add esi,SIZE dir_entry_struc
;
	cmp esi,edi
	jb fdiRetry
;
	mov esi,ebp
	sub esi,SIZE dir_entry_struc
	mov eax,es:[esi]
	and eax,es:[esi+4]
	and eax,es:[esi+8]
	cmp eax,-1
	jne fdiFail
;
	push edx
	mov es:[esi].fde_size,0
	GetTime
	mov es:[esi].fde_time,eax
	mov es:[esi].fde_time+4,edx
	pop edx
	mov es:[esi].fde_valid,DIR_ENTRY_OK
	call WriteSector

fdiDone:
	clc
	mov eax,esi
	jmp fdiEnd

fdiFail:
	stc

fdiEnd:
	pop ebp
	pop edi
	pop esi
	pop cx
	ret
FindDirInfo	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddObjectEntry
;
;		DESCRIPTION:    Add entry to object sector
;
;		PARAMETERS:		EBX         Object sector handle
;                       ESI         Object sector address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddObjectEntry	Proc near
    push fs
    push ax
    push ebx
    push edx
;
    push ebx
    mov ax,LOG_ENTRY_DIR_DATA
    call AllocateSector
    mov eax,ebx
    pop ebx
    jc adoeDone
;
    mov es:[esi],eax
    mov byte ptr es:[esi+3],OBJECT_OK
    call WriteSectorAlloc
    clc

adoeDone:
    pop edx
    pop ebx
    pop ax
    pop fs
    ret
AddObjectEntry Endp
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddDirEntry
;
;		DESCRIPTION:    Add entry to dir data sector
;
;		PARAMETERS:		ESI         Object sector address
;                       EBP         Dir file entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDirEntry	Proc near
    push fs
    push ax
    push ebx
    push cx
    push edx
    push esi
;
    mov edx,es:[esi]
    and edx,0FFFFFFh
    call DirDataLogToPhysSector
    jc adeDone
;
    mov al,ds:drive_nr
    LockSector
;
    add esi,200h
    mov cx,80h

adeSectorLoop:    
    sub esi,4
    mov edx,es:[esi]
    cmp edx,-1
    je adeNext
;
	add esi,4
	jmp adeTake

adeNext:
    loop adeSectorLoop

adeTake:
	mov edx,es:[esi]
    cmp edx,-1
    stc
    jne adeUnlock
;
    push ebx
    mov ax,LOG_ENTRY_DIR_ENTRY
    call AllocateSector
    mov eax,ebx
    pop ebx
    jc adeUnlock
;
    mov es:[esi],eax
    mov es:[ebp].ffe_entry_sector,eax
    mov byte ptr es:[esi+3],DIR_DATA_OK
    call WriteSectorAlloc
    clc

adeUnlock:
    pushf    
    UnlockSector
    popf

adeDone:
    pop esi
    pop edx
    pop cx
    pop ebx
    pop ax
    pop fs
    ret
AddDirEntry Endp
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateDirObject
;
;		DESCRIPTION:    Allocate dir entry 
;
;		PARAMETERS:		EDX			Logical object sector
;                       EBP         Dir file entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateDirObject	Proc near
    push ax
    push ebx
    push ecx
    push edx
    push esi
;
    call ObjectLogToPhysSector
    jc adoDone
;
    mov al,ds:drive_nr
    LockSector
;
    add esi,200h
    mov cx,80h

adoSectorLoop:    
    sub esi,4
    mov edx,es:[esi]
    cmp edx,-1
    jne adoTake
;
    loop adoSectorLoop

adoTake:
    mov al,es:[esi+3]
    cmp al,-1
    je adoTakeThis
;
    cmp al,OBJECT_OK
    jne adoTakeNext
;
    call AddDirEntry
    jnc adoUnlock

adoTakeNext:
    add esi,4
    test si,1FFh
    stc
    jz adoUnlock

adoTakeThis:
    call AddObjectEntry
    jc adoUnlock
;
    call AddDirEntry

adoUnlock:
    pushf
    UnlockSector
    popf

adoDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ax
    ret
AllocateDirObject   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GrowDir
;
;		DESCRIPTION:    Grow directory
;
;		PARAMETERS:		BX			Dir selector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowDir	Proc near
	push es
	push fs
	push gs
	pushad
;
	mov ax,flat_sel
	mov es,ax
    mov gs,bx
    mov edx,gs:ds_link
    call DirEntryLogToPhysSector
    jc gdDone
;
    mov al,ds:drive_nr
    LockSector
	call FindDirInfo
	mov esi,eax
	mov ecx,es:[esi].fde_size
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

gdCheckSpace:
	and al,es:[edi]
	inc edi
	cmp esi,edi
	jne gdCheckSpace
;
	pop edi
	add al,1
	jz gdSpaceOk
;
	int 3

gdSpaceOk:	
	mov eax,es:[esi].fde_size
	add eax,10000h
	mov es:[edi].fde_size,eax
	mov eax,es:[esi].fde_time
	mov es:[edi].fde_time,eax
	mov eax,es:[esi].fde_time+4
	mov es:[edi].fde_time+4,eax
	add esi,OFFSET fde_valid
	add edi,OFFSET fde_valid
;
	push ecx
	dec ecx
	shr ecx,16
	inc cx
	or cx,cx
	jz gdMoveDone

gdMoveLoop:
	mov eax,es:[esi]
	mov es:[edi],eax
	add esi,3
	add edi,3
	loop gdMoveLoop	

gdMoveDone:
	xor ax,ax
	mov fs,ax
	pop ecx
	or cx,cx
	jnz gdMakeValid

gdAllocObjectSector:
    push ebx
	mov ax,LOG_ENTRY_OBJECT
	call AllocateSector
	mov eax,ebx
	pop ebx
	jc gdUnlock
;
	mov es:[edi],eax
	add edi,3

gdMakeValid:
	mov byte ptr es:[edi],DIR_ENTRY_OK	
	mov ax,fs
	or ax,ax
	jz gdWrite
;
	call WriteSectorAlloc
	clc
	jmp gdUnlock

gdWrite:
	call WriteSector
	clc

gdUnlock:
    pushf
    UnlockSector
    popf	

gdDone:
	popad
	pop gs
	pop fs
	pop es
	ret
GrowDir	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddToDir
;
;		DESCRIPTION:    Add entry to directory
;
;		PARAMETERS:		BX			Dir selector
;                       EDX         Dir file entry
;
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddToDir	Proc near
    push es
    push fs
    pushad
;
    mov ebp,edx
	mov ax,flat_sel
	mov es,ax
    mov fs,bx

atdRetry:    
    mov edx,fs:ds_link
    call DirEntryLogToPhysSector
    jc atdDone
;    
    mov al,ds:drive_nr
    LockSector
	call FindDirInfo
	mov esi,eax
	mov ecx,es:[esi].fde_size
    shr ecx,16
    or ecx,ecx
    jz atdGrow
;
    lea edi,[esi].fde_valid
    add edi,ecx
    add ecx,ecx
    add edi,ecx
    sub edi,3
;
    mov edx,es:[edi]
    and edx,0FFFFFFh
    call AllocateDirObject
    jnc atdUnlock

atdGrow: 
	int 3   
    push bx
    mov bx,fs
    call GrowDir
    pop bx
    UnlockSector
    jnc atdRetry
    jmp atdDone

atdUnlock:
    pushf
    UnlockSector
    popf

atdDone:
    popad
    pop fs
    pop es
    ret
AddToDir   Endp

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
	call AddToDir
	jc afeDone
;
    mov ebp,edx
    mov ax,es
    mov gs,ax
    mov ax,flat_sel
    mov es,ax
;
    mov edx,es:[ebp].ffe_entry_sector
    call DirEntryLogToPhysSector    
;
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
    add esi,1F3h
    mov es:[esi].fde_size,0
    mov eax,es:[ebp].de_time
    mov es:[esi].fde_time,eax
    mov eax,es:[ebp].de_time+4
    mov es:[esi].fde_time+4,eax
    mov es:[esi].fde_valid,DIR_ENTRY_OK
    call WriteSector
    UnlockSector
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
    add esi,1F3h
    mov es:[esi].fde_size,0
    GetTime
    mov es:[esi].fde_time,eax
    mov es:[esi].fde_time+4,edx
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
;		DESCRIPTION:    Cache a single dir entry
;
;		PARAMETERS:		EDX			Logical dir entry sector
;						FS			Dir selector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CacheDirEntry	Proc near
    push ax
    push ebx
    push cx
    push edx
    push esi
	push edi
	push ebp
;
	mov ebp,edx
    call DirEntryLogToPhysSector
    jc cdeDone
;
    mov al,ds:drive_nr
    LockSector
;
	mov cl,es:[esi]
	test cl,10h
	jne cdeAddDir

cdeAddFile:
	lea edi,[esi].deh_name
	movzx cx,cl
	push bx
	mov bx,fs
	call CreateFileEntry
	pop bx
;
	mov es:[edx].ffe_entry_sector,ebp
	call FindDirInfo
	mov esi,eax
	mov eax,es:[esi].fde_size
	mov es:[edx].dfe_data_size,eax
	mov eax,es:[esi].fde_time
	mov es:[edx].de_time,eax
	mov eax,es:[esi].fde_time+4
	mov es:[edx].de_time+4,eax
;
	push bx
	mov bx,fs
	InsertFileEntry
	pop bx
	jmp cdeUnlock

cdeAddDir:
	lea edi,[esi].deh_name
	movzx cx,cl
	push bx
	mov bx,fs
	call CreateDirEntry
	pop bx
;
	mov es:[edx].fde_entry_sector,ebp
	call FindDirInfo
	mov esi,eax
	mov eax,es:[esi].fde_time
	mov es:[edx].de_time,eax
	mov eax,es:[esi].fde_time+4
	mov es:[edx].de_time+4,eax
;
	push bx
	mov bx,fs
	InsertDirEntry
	pop bx

cdeUnlock:
	UnlockSector
	clc

cdeDone:
	pop ebp
	pop edi
    pop esi
    pop edx
    pop cx
    pop ebx
    pop ax
	ret
CacheDirEntry	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CacheDirData
;
;		DESCRIPTION:    Cache dir data entries
;
;		PARAMETERS:		EDX			Logical object sector
;						FS			Dir selector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CacheDirData	Proc near
    push ax
    push ebx
    push cx
    push edx
    push esi
;
    call DirDataLogToPhysSector
    jc cddDone
;
    mov al,ds:drive_nr
    LockSector
;
    mov cx,80h

cddSectorLoop:
	mov al,es:[esi].fdd_valid
	cmp al,DIR_DATA_OK
	jnz cddNext
;
	mov edx,es:[esi]
	and edx,0FFFFFFh
	call CacheDirEntry

cddNext:
	add esi,4
	loop cddSectorLoop
;
    UnlockSector
	clc

cddDone:
    pop esi
    pop edx
    pop cx
    pop ebx
    pop ax
    ret
CacheDirData Endp
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CacheDirObject
;
;		DESCRIPTION:    Cache dir entry 
;
;		PARAMETERS:		EDX			Logical object sector
;						FS			Dir selector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CacheDirObject	Proc near
    push ax
    push ebx
    push ecx
    push edx
    push esi
;
    call ObjectLogToPhysSector
    jc cdoDone
;
    mov al,ds:drive_nr
    LockSector
;
    mov cx,80h

cdoSectorLoop:
	mov al,es:[esi].o_valid
	cmp al,OBJECT_OK
	jnz cdoNext
;
	mov edx,es:[esi]
	and edx,0FFFFFFh
	call CacheDirData

cdoNext:
	add esi,4
	loop cdoSectorLoop
;
    UnlockSector
	clc

cdoDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ax
    ret
CacheDirObject   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CacheDirSel
;
;		DESCRIPTION:    Cache dir
;
;		PARAMETERS:		BX			Dir selector
;                       EDX         Logical sector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CacheDirSel   Proc near
	push fs
    pushad
;
    mov fs,bx
    mov fs:ds_link,edx
    call DirEntryLogToPhysSector
    jc cdDone
;    
    mov al,ds:drive_nr
    LockSector
	call FindDirInfo
	mov esi,eax
	mov ecx,es:[esi].fde_size
    shr ecx,16
    or ecx,ecx
	clc
    jz cdUnlock
;
    lea edi,[esi].fde_valid

cdCacheLoop:
    mov edx,es:[edi]
    and edx,0FFFFFFh
    call CacheDirObject
	add edi,4
	loop cdCacheLoop
;
	clc

cdUnlock:
    pushf
    UnlockSector
    popf

cdDone:
    popad
    pop fs
    ret
CacheDirSel   Endp

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
	int 3
	mov ax,flat_sel
	mov es,ax
;
	or edx,edx
	jnz cache_sub_dir
;
	call GetRootSector
    jc cache_dir_done
;
    call CacheDirSel
    jnc cache_dir_done
;
    call InitRootDirEntry
    call CacheDirSel
	jmp cache_dir_done

cache_sub_dir:
	int 3
	mov edx,es:[edx].fde_entry_sector
	call CacheDirSel

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
;		NAME:			FindDirData
;
;		DESCRIPTION:    Find dir data entry
;
;		PARAMETERS:		EDX			Logical object sector
;						FS			Dir selector
;						EDI			Logical dir entry sector
;
;		RETURNS:		EBX			Sector handle
;						ESI			Offset into dir data
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindDirData	Proc near
    push eax
    push cx
    push edx
;
    call DirDataLogToPhysSector
    jc fddDone
;
    mov al,ds:drive_nr
    LockSector
;
    mov cx,80h

fddSectorLoop:
	mov al,es:[esi].fdd_valid
	cmp al,DIR_DATA_OK
	jnz fddNext
;
	mov edx,es:[esi]
	and edx,0FFFFFFh
	cmp edi,edx
	je fddOk

fddNext:
	add esi,4
	loop fddSectorLoop
;
    UnlockSector
	stc
	jmp fddDone

fddOk:
	clc

fddDone:
    pop edx
    pop cx
    pop eax
    ret
FindDirData Endp
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindDirObject
;
;		DESCRIPTION:    Find dir entry from object table
;
;		PARAMETERS:		EDX			Logical object sector
;						FS			Dir selector
;						EDI			Logical dir entry sector
;
;		RETURNS:		EBX			Sector handle
;						ESI			Offset into dir data
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindDirObject	Proc near
    push eax
    push ecx
    push edx
;
    call ObjectLogToPhysSector
    jc fdoDone
;
    mov al,ds:drive_nr
    LockSector
;
    mov cx,80h

fdoSectorLoop:
	mov al,es:[esi].o_valid
	cmp al,OBJECT_OK
	jnz cdoNext
;
	push ebx
	push esi
	mov edx,es:[esi]
	and edx,0FFFFFFh
	call FindDirData
	jnc fdoOk
;
	pop esi
	pop ebx

fdoNext:
	add esi,4
	loop fdoSectorLoop

fdoFail:
    UnlockSector
	clc
	jmp fdoDone

fdoOk:
	mov eax,ebx
	add sp,4
	pop ebx
	UnlockSector
	mov ebx,eax
	clc

fdoDone:
    pop edx
    pop ecx
    pop eax
    ret
FindDirObject   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindDirSel
;
;		DESCRIPTION:    Find director entry from dir selector
;
;		PARAMETERS:		BX			Dir selector
;                       EDX         Logical sector
;						EDI			Logical dir entry sector
;
;		RETURNS:		EBX			Sector handle
;						ESI			Offset into dir data
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindDirSel   Proc near
    push eax
	push ecx
	push edx
	push edi
	push ebp
;
    call DirEntryLogToPhysSector
    jc fdsDone
;    
    mov al,ds:drive_nr
    LockSector
	call FindDirInfo
	mov esi,eax
	mov ecx,es:[esi].fde_size
    shr ecx,16
    or ecx,ecx
    jz fdsFail
;
    lea esi,[esi].fde_valid

fdsFindLoop:
    mov edx,es:[esi]
    and edx,0FFFFFFh
	push ebx
	push esi
    call FindDirObject
	jnc fdsOk
;
	pop esi
	pop ebx
	add esi,4
	loop fdsFindLoop

fdsFail:
    UnlockSector
	stc
	jmp fdsDone

fdsOk:
	mov eax,ebx
	add sp,4
	pop ebx
	UnlockSector
	mov ebx,eax
	clc

fdsDone:
	pop ebp
    pop edi
	pop edx
	pop ecx
	pop eax
    ret
FindDirSel   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DELETE_FILE
;
;		DESCRIPTION:	Delete file
;
;		PARAMETERS:		BX			DIR SELECTOR
;						EDX			FILE ENTRY TO DELETE
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public delete_file

delete_file	PROC far
	push es
	push fs
	push eax
	push edx
	push edi
;
    int 3
	mov ax,flat_sel
	mov es,ax
	mov edi,es:[edx].ffe_entry_sector
	mov fs,bx
    mov edx,fs:ds_link
	call FindDirSel
	jc dfDone
;
	push ebx
	mov ebx,edi
	call FreeSector
	pop ebx
;
	mov es:[esi].fdd_valid,0
	call WriteSector
	UnlockSector
	clc

dfDone:
	pop edi
	pop edx
	pop eax
	pop fs
	pop es
	ret
delete_file	ENDP

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
;
	push eax
	push edx
	push edi
	mov edi,edx
    GetTime
	mov es:[edi].de_time,eax
	mov es:[edi+4].de_time,edx
	mov es:[edi].dfe_data_size,0
	pop edi
	pop edx
	pop eax
;
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
