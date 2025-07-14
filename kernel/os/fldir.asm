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
; FLDIR.ASM
; FLDIR (Flash File System, directory handling)
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

    extrn WriteSector:near
	extrn WriteSectorAlloc:near
	extrn WriteSectorFree:near

	extrn QueryDirEntrySector:near
    extrn QueryObjectSector:near
    extrn QueryDirDataSector:near
    extrn QueryFileDataSector:near
	
    extrn DirEntryLogToPhysSector:near
    extrn ObjectLogToPhysSector:near
    extrn DirDataLogToPhysSector:near
    extrn FileDataLogToPhysSector:near
    
    extrn AllocateSector:near
	extrn AliasSector:near
	extrn FreeSector:near
    extrn GetRootSector:near

	assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateDirSel
;
;		DESCRIPTION:	Allocate dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public allocate_dir_sel

allocate_dir_sel	PROC far
	push es
	push eax
;
	mov eax,SIZE flash_dir_sel_data_struc
	AllocateSmallGlobalMem
	mov es:fds_used_entries,0
	mov es:fds_deleted_entries,0
	mov bx,es
;
	pop eax
	pop es
	ret
allocate_dir_sel	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeDirSel
;
;		DESCRIPTION:	Free dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public free_dir_sel

free_dir_sel	PROC far
	push es
;
	mov es,bx
	FreeMem
;
	pop es
	ret
free_dir_sel	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateDirEntry
;
;		DESCRIPTION:    Create directory entry
;
;		PARAMETERS:		ES:EDI      Dir name
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateFileEntry
;
;		DESCRIPTION:    Create file entry
;
;		PARAMETERS:		ES:EDI      File name
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckDirInfoSpace
;
;		DESCRIPTION:    Check if dir info space exists
;
;		PARAMETERS:		CX			Bytes wanted
;						EDI			Start position
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckDirInfoSpace	Proc near
	push ax
	push cx
	push edi
;
	mov al,-1

cdisLoop:
	and al,es:[edi]
	inc edi
	loop cdisLoop
;
	add al,1
	jz cdisOk
;
	stc
	jmp cdisDone

cdisOk:
	clc

cdisDone:
	pop edi
	pop cx
	pop ax
	ret
CheckDirInfoSpace	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RedoDirEntry
;
;		DESCRIPTION:    Redo dir entry sector (with the same logical sector)
;
;		PARAMETERS:		EDX			Logical sector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RedoDirEntry	Proc near
	push fs
	pushad
;
    push edx
	mov ebx,edx
	mov ecx,fs:fds_owner_sector
	call DirEntryLogToPhysSector
	jc rdeDone
;
	mov ebp,edx
	call AliasSector
	jc rdeDone
;
	mov al,ds:drive_nr
	LockSector
	push ebx
	mov edi,esi
;
	mov edx,ebp
	LockSector
	call MoveDirEntry
	UnlockSector
;
	pop ebx
	call WriteSector
	UnlockSector
;
	mov ebx,gs:bc_op_handle
	call WriteSector
;
    pop edx
    push edx
;
    call FindDirInfo
    jc rdeUnlock
;
	mov dx,ax
	sub dx,si
	mov fs:fds_info_offset,dx
    clc
    jmp rdeDone 

rdeUnlock:
    pushf
    UnlockSector
    popf

rdeDone:
    pop edx
;
	popad
	pop fs
	ret
RedoDirEntry	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindDirInfo
;
;		DESCRIPTION:    Find position of valid dir entry info
;
;		PARAMETERS:		FS			Dir selector
;						EDX			Logical sector
;
;		RETURNS:		EAX			Offset to last valid dir info
;						ESI			Dir entry data
;						EBX			Dir entry handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindDirInfo	Proc near
	push ecx
	push edi
	push ebp
;
	push edx

fdiRedo:
    call QueryDirEntrySector
    jc fdiEnd
;
    call DirEntryLogToPhysSector
	jc fdiEnd
;
	mov al,ds:drive_nr
	LockSector
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
	cmp cl,DIR_ENTRY_RESTRUCT
	jne fdiNotRestruct
;
    call UndoDirEntry
	push edi
	mov edi,esi

fdiRestructLoop:
	mov eax,es:[esi].fde_size
	shr eax,16
	mov ecx,eax
	add esi,SIZE dir_entry_struc
	add esi,eax
	add eax,eax
	add esi,eax
	mov byte ptr es:[esi-1],0

fdiRestructRetry:
	mov eax,es:[esi].fde_size
	shr eax,16
	mov cx,ax
	add cx,cx
	add ax,cx
	mov cl,es:[esi+eax].fde_valid
	cmp cl,DIR_ENTRY_RESTRUCT
	je fdiRestructLoop
;
	cmp cl,DIR_ENTRY_OK
	je fdiRestructSave
;
	add esi,eax
	add esi,SIZE dir_entry_struc
;
	cmp esi,edi
	jb fdiRetry
;
	pop edi
	jmp fdiInit

fdiRestructSave:
    mov edi,ebp
	mov eax,es:[esi].fde_size
	shr eax,16
	mov ecx,eax
	add ecx,SIZE dir_entry_struc
	add eax,eax
	add ecx,eax
	sub edi,ecx
	call CheckDirInfoSpace
	jnc fdiSaveSpaceOk
;
	pop edi
	jmp fdiFail

fdiSaveSpaceOk:	
	push edi
	rep movs byte ptr es:[edi],es:[esi]
	pop esi
	call WriteSector
	pop edi
	jmp fdiDone
	
fdiNotRestruct:
	cmp cl,DIR_ENTRY_OK
	je fdiDone
;
	add esi,eax
	add esi,SIZE dir_entry_struc
;
	cmp esi,edi
	jb fdiRetry

fdiInit:
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
	mov eax,esi
	mov esi,edi
	sub esi,200h
	clc
	jmp fdiEnd

fdiFail:
    int 3
	UnlockSector
	pop edx
	push edx
	call RedoDirEntry
	jnc fdiRedo

fdiEnd:
	pop edx
;
	pop ebp
	pop edi
	pop ecx
	ret
FindDirInfo	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MoveDirData
;
;		DESCRIPTION:    Move dir data sector contents
;
;		PARAMETERS:		ESI			Source buffer
;						EDI			Dest buffer
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveDirData	Proc near
	push eax
	push cx
	push edx
	push esi
	push edi
;
    xor edx,edx
	mov cx,80h

mddLoop:
	mov al,es:[esi].fdd_valid
	cmp al,DIR_DATA_OK
	jne mddNext
;
	mov eax,es:[esi]
	mov es:[edi],eax
	add edi,4
;	
	cmp eax,-1
	je mddNext
;
    inc edx

mddNext:
	add esi,4
	loop mddLoop
; 
    or edx,edx
    stc
    jz mddDone
;
    clc

mddDone:    
	pop edi
	pop esi
	pop edx
	pop cx
	pop eax
	ret
MoveDirData	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MoveObject
;
;		DESCRIPTION:    Move object sector contents
;
;		PARAMETERS:		ESI			Source buffer
;						EDI			Dest buffer
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveObject	Proc near
	push eax
	push cx
	push edx
	push esi
	push edi
;
	mov cx,80h

moLoop:
	mov al,es:[esi].o_valid
	cmp al,OBJECT_OK
	jne moNext
;
	mov eax,es:[esi]
	mov es:[edi],eax
	add edi,4
;	
	cmp eax,-1
	je moNext
;
    inc edx
	
moNext:
	add esi,4
	loop moLoop
; 
    or edx,edx
    stc
    jz moDone
;
    clc

moDone:     
	pop edi
	pop esi
	pop edx
	pop cx
	pop eax
	ret
MoveObject	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MoveDirEntry
;
;		DESCRIPTION:    Move dir entry sector contents
;
;		PARAMETERS:		ESI			Source buffer
;						EDI			Dest buffer
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveDirEntry	Proc near
	pushad
;
	mov ecx,200h
	mov ebp,esi
	add ebp,200h
	mov al,es:[esi]
	mov es:[edi],al
	inc esi
	inc edi
	dec cx

mdeNameLoop:
	mov al,es:[esi]
	mov es:[edi],al
	inc esi
	inc edi
	sub cx,1
	jz mdeFail
;
	or al,al
	jnz mdeNameLoop
;
	and di,0FE00h
	add edi,200h

mdeStartLoop:
	mov al,es:[esi]
	cmp al,-1
	jnz mdeRetry
;
	inc esi
	cmp esi,ebp
	jne mdeStartLoop
	jmp mdeFail

mdeRetry:
	mov eax,es:[esi].fde_size
	shr eax,16
	mov cx,ax
	add cx,cx
	add ax,cx
	mov cl,es:[esi+eax].fde_valid
	cmp cl,DIR_ENTRY_RESTRUCT
	jne mdeCheckEntry

mdeRestructLoop:
	mov eax,es:[esi].fde_size
	shr eax,16
	mov ecx,eax
	add esi,SIZE dir_entry_struc
	add esi,eax
	add eax,eax
	add esi,eax

mdeRestructRetry:
	mov eax,es:[esi].fde_size
	shr eax,16
	mov cx,ax
	add cx,cx
	add ax,cx
	mov cl,es:[esi+eax].fde_valid
	cmp cl,DIR_ENTRY_RESTRUCT
	je mdeRestructLoop

mdeCheckEntry:
	cmp cl,DIR_ENTRY_OK
	je mdeCopy
;
	add esi,eax
	add esi,SIZE dir_entry_struc
;
	cmp esi,ebp
	jb mdeRetry
	jmp mdeFail

mdeCopy:
	mov eax,es:[esi].fde_size
	shr eax,16
	mov ecx,eax
	add ecx,SIZE dir_entry_struc
	add eax,eax
	add ecx,eax
	sub edi,ecx
	call CheckDirInfoSpace
	jnc mdeSaveSpaceOk

mdeFail:
    stc
	jmp mdeDone

mdeSaveSpaceOk:	
	rep movs byte ptr es:[edi],es:[esi]
	clc

mdeDone:
	popad
	ret
MoveDirEntry	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MoveFileData
;
;		DESCRIPTION:    Move file data sector contents
;
;		PARAMETERS:		ESI			Source buffer
;						EDI			Dest buffer
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveFileData	Proc near
	push ecx
	push esi
	push edi
;
	mov ecx,80h
	rep movs dword ptr es:[edi],es:[esi]
	clc
;
	pop edi
	pop esi
	pop ecx
	ret
MoveFileData	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MoveSector
;
;		DESCRIPTION:    Move sector contents
;
;		PARAMETERS:		AL			Sector type
;						ESI			Source buffer
;						EDI			Dest buffer
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public MoveSector

MoveSector	Proc near
	cmp al,LOG_ENTRY_DIR_DATA
	jz msDirData
;
	cmp al,LOG_ENTRY_OBJECT
	jz msObject
;
	cmp al,LOG_ENTRY_DIR_ENTRY
	jz msDirEntry
;
	cmp al,LOG_ENTRY_FILE_DATA
	jz msFileData
;
	ret

msDirData:
	call MoveDirData
	ret

msObject:
	call MoveObject
	ret

msDirEntry:
	call MoveDirEntry
	ret

msFileData:
	call MoveFileData
	ret
MoveSector	Endp


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
    push ax
    push ebx
	push ecx
    push edx
;
    push ebx
	mov ecx,fs:fds_object_sector
    mov ax,LOG_ENTRY_DIR_DATA
    call AllocateSector
	mov fs:fds_data_sector,ebx
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
	pop ecx
    pop ebx
    pop ax
    ret
AddObjectEntry Endp
    

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
    push eax
    push ebx
    push ecx
    push edx
    push esi
	push edi
;
	mov ecx,fs:fds_object_sector
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
	mov ecx,fs:fds_data_sector
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
	pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
AddDirEntry Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateDirObject
;
;		DESCRIPTION:    Allocate dir entry 
;
;		PARAMETERS:		EDX			Logical object sector
;						EBP         Dir file entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateDirObject	Proc near
    push ax
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
	mov ecx,fs:fds_entry_sector
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
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ax
    ret
AllocateDirObject   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GrowDir
;
;		DESCRIPTION:    Grow directory
;
;		PARAMETERS:		FS			Dir selector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowDir	Proc near
	push es
	pushad
;
	mov ax,flat_sel
	mov es,ax

gdRedo:
	mov ecx,fs:fds_owner_sector
    mov edx,fs:fds_entry_sector
    call DirEntryLogToPhysSector
    jc gdDone
;
    mov al,ds:drive_nr
    LockSector
	add si,fs:fds_info_offset
	mov ecx,es:[esi].fde_size
	mov eax,ecx
	shr eax,16
	inc eax	
	mov edi,esi
	sub edi,13
	sub edi,eax
	add eax,eax
	sub edi,eax
	push ecx
	mov ecx,esi
	sub ecx,edi
	call CheckDirInfoSpace
	jnc gdSpaceOk
;
	pop ecx
	UnlockSector
	call RedoDirEntry
	jc gdDone
	jmp gdRedo

gdSpaceOk:	
	pop ecx
	mov ax,di
	and ax,1FFh
	mov fs:fds_info_offset,ax
;
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
	mov gs,ax
	pop ecx
	or cx,cx
	jnz gdMakeValid

gdAllocObjectSector:
    push ebx
	mov ecx,edx
	mov ax,LOG_ENTRY_OBJECT
	call AllocateSector
	mov eax,ebx
	pop ebx
	jc gdUnlock
;
	mov es:[edi],eax
	add edi,3

gdMakeValid:
    mov al,es:[esi]
	mov es:[edi],al	
	mov ax,gs
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
	pop es
	ret
GrowDir	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddToDir
;
;		DESCRIPTION:    Add entry to directory
;
;		PARAMETERS:		FS			Dir selector
;                       EDX         Dir file entry
;
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddToDir	Proc near
    push es
    pushad
;
    mov ebp,edx
	mov ax,flat_sel
	mov es,ax

atdRetry:    
	mov ecx,fs:fds_owner_sector
    mov edx,fs:fds_entry_sector
    call DirEntryLogToPhysSector
    jc atdDone
;    
    mov al,ds:drive_nr
    LockSector
	add si,fs:fds_info_offset
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
	mov fs:fds_object_sector,edx
    call AllocateDirObject
    jnc atdUnlock

atdGrow: 
    call GrowDir
    pushf
    UnlockSector
    popf
    jnc atdRetry
    jmp atdDone

atdUnlock:
    pushf
    UnlockSector
    popf

atdDone:
    popad
    pop es
    ret
AddToDir   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddFileEntry
;
;		DESCRIPTION:    Add file entry
;
;		PARAMETERS:		FS			Dir selector
;                       ES:EDI      File name
;                       CX          Attribute
;                       EDX         Dir file entry
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFileEntry  Proc near
    push es
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
    push ecx
    mov ecx,fs:fds_data_sector
    mov edx,es:[ebp].ffe_entry_sector
    call DirEntryLogToPhysSector    
    pop ecx
    jc afeDone
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
    pop es
    ret
AddFileEntry  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitRootDirEntry
;
;		DESCRIPTION:    Init root dir entry
;
;		PARAMETERS:		FS			Dir selector
;                       EDX         Logical sector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitRootDirEntry
    
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UndoDirObject
;
;		DESCRIPTION:    Undo (free) dir object entries
;
;		PARAMETERS:		EDX			Logical object sector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UndoDirObject	Proc near
    push ax
    push ebx
    push ecx
    push edx
    push esi
;
	mov ecx,fs:fds_entry_sector
    call ObjectLogToPhysSector
    jc udoDone
;
    mov al,ds:drive_nr
    LockSector
    push ebx
;
    mov cx,80h

udoSectorLoop:    
    mov edx,es:[esi]
    cmp edx,-1
    je udoNext
;
    and edx,0FFFFFFh
	push ecx
    push edx
	mov ecx,fs:fds_object_sector
    call DirDataLogToPhysSector
    pop edx
	pop ecx
	jnc udoFree

udoZero:
    mov dword ptr es:[esi],0
    call WriteSector
    jmp udoNext

udoFree:    
	push ecx
	mov ecx,fs:fds_object_sector
    call FreeSector
	pop ecx
	jc udoZero
;
    mov dword ptr es:[esi],0
    call WriteSectorFree

udoNext:
    add esi,4
    loop udoSectorLoop
;    
    pop ebx
    UnlockSector
    clc

udoDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ax
    ret
UndoDirObject   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UndoDirEntry
;
;		DESCRIPTION:    Undo dir entry
;
;		PARAMETERS:		EBX			Sector handle
;                       ESI         Offset to dir info
;
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UndoDirEntry	Proc near
    push ebx
    push ecx
    push edx
    push esi
;    
	mov ecx,es:[esi].fde_size
    shr ecx,16
    or ecx,ecx
    jz udeDone
;
    add esi,OFFSET fde_valid

udeLoop:
    mov edx,es:[esi]
    and edx,0FFFFFFh
	mov fs:fds_object_sector,edx
    call UndoDirObject
    jc udeNext
;
	push ecx
	mov ecx,fs:fds_entry_sector
    call FreeSector
	pop ecx
    jc udeNext
;
    mov dword ptr es:[esi],0
    call WriteSectorFree

udeNext:
    add esi,4
    loop udeLoop

udeDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
UndoDirEntry   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RedoAddDirEntry
;
;		DESCRIPTION:    Add entry to dir data sector
;
;		PARAMETERS:		ESI         Object sector address
;                       EBP         Dir entry logical sector 
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RedoAddDirEntry	Proc near
    push fs
    push ax
    push ebx
    push ecx
    push edx
    push esi
;
    mov edx,es:[esi]
    and edx,0FFFFFFh
	mov ecx,fs:fds_object_sector
    call DirDataLogToPhysSector
    jc radeDone
;
    mov al,ds:drive_nr
    LockSector
;
    add esi,200h
    mov cx,80h

radeSectorLoop:    
    sub esi,4
    mov edx,es:[esi]
    cmp edx,-1
    je radeNext
;
	add esi,4
	jmp radeTake

radeNext:
    loop radeSectorLoop

radeTake:
	mov edx,es:[esi]
    cmp edx,-1
    stc
    jne radeUnlock
;
    mov es:[esi],ebp
    mov byte ptr es:[esi+3],DIR_DATA_OK
    call WriteSector
    clc

radeUnlock:
    pushf    
    UnlockSector
    popf

radeDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ax
    pop fs
    ret
RedoAddDirEntry Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RedoAddObject
;
;		DESCRIPTION:    Add to dir object
;
;		PARAMETERS:		EDX			Logical object sector
;                       EBP         Dir entry logical sector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RedoAddObject	Proc near
    push ax
    push ebx
    push ecx
    push edx
    push esi
;
	mov ecx,fs:fds_entry_sector
    call ObjectLogToPhysSector
    jc raoDone
;
    mov al,ds:drive_nr
    LockSector
;
    add esi,200h
    mov cx,80h

raoSectorLoop:    
    sub esi,4
    mov edx,es:[esi]
    cmp edx,-1
    jne raoTake
;
    loop raoSectorLoop

raoTake:
    mov al,es:[esi+3]
    cmp al,-1
    je raoTakeThis
;
    cmp al,OBJECT_OK
    jne raoTakeNext
;
    call RedoAddDirEntry
    jnc raoUnlock

raoTakeNext:
    add esi,4
    test si,1FFh
    stc
    jz raoUnlock

raoTakeThis:
    call AddObjectEntry
    jc adoUnlock
;
    call RedoAddDirEntry

raoUnlock:
    pushf
    UnlockSector
    popf

raoDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ax
    ret
RedoAddObject   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RedoAddToDir
;
;		DESCRIPTION:    Add entry to directory
;
;		PARAMETERS:		FS			Dir selector
;                       EDX         Dir entry logical sector
;
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RedoAddToDir	Proc near
    pushad
;
    mov ebp,edx

ratdRetry:
	mov ecx,fs:fds_owner_sector
    mov edx,fs:fds_entry_sector
    call DirEntryLogToPhysSector
    jc ratdDone
;    
    mov al,ds:drive_nr
    LockSector
	add si,fs:fds_info_offset
	mov ecx,es:[esi].fde_size
    shr ecx,16
    or ecx,ecx
    jz ratdGrow
;
    lea edi,[esi].fde_valid
    add edi,ecx
    add ecx,ecx
    add edi,ecx
    sub edi,3
;
    mov edx,es:[edi]
    and edx,0FFFFFFh
	mov fs:fds_object_sector,edx
    call RedoAddObject
    jnc ratdUnlock

ratdGrow: 
    call GrowDir
    pushf
    UnlockSector
    popf
    jnc ratdRetry
    jmp ratdDone

ratdUnlock:
    pushf
    UnlockSector
    popf

ratdDone:
    popad
    ret
RedoAddToDir   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RedoDirEntries
;
;		DESCRIPTION:    Recreate directory entries
;
;		PARAMETERS:		FS			Dir selector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RedoDirEntries	Proc near
    push edi
    push ebp
;
    mov edi,fs:ds_dir_ptr
    mov ebp,edi
    or edi,edi
    jz rdesDone

rdesLoop:
    mov edx,es:[edi].fde_entry_sector
    call RedoAddToDir
;
    mov edi,es:[edi].de_next
    cmp edi,ebp
    jne rdesLoop

rdesDone:
    pop ebp
    pop edi
    ret
RedoDirEntries  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RedoFileEntries
;
;		DESCRIPTION:    Recreate file entries
;
;		PARAMETERS:		FS			Dir selector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RedoFileEntries	Proc near
    push edi
    push ebp
;
    mov edi,fs:ds_file_ptr
    mov ebp,edi
    or edi,edi
    jz rfeDone

rfeLoop:
    mov edx,es:[edi].ffe_entry_sector
    call RedoAddToDir
;
    mov edi,es:[edi].de_next
    cmp edi,ebp
    jne rfeLoop

rfeDone:
    pop ebp
    pop edi
    ret
RedoFileEntries  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RedoDirSel
;
;		DESCRIPTION:    Recreate directory selector
;
;		PARAMETERS:		FS			Dir selector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RedoDirSel	Proc near
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi

rdsRedo:
    mov ecx,fs:fds_owner_sector
	mov edx,fs:fds_entry_sector
    call DirEntryLogToPhysSector
    jc rdsDone
;
    mov al,ds:drive_nr
    LockSector
	add si,fs:fds_info_offset
	mov edi,esi
	sub edi,13
	mov ecx,esi
	sub ecx,edi
	call CheckDirInfoSpace
	jnc upsSpaceOk
;
    int 3
	UnlockSector
	call RedoDirEntry
	jc rdsDone
	jmp rdsRedo

upsSpaceOk:
    mov ax,di
	and ax,1FFh
	mov fs:fds_info_offset,ax
;	
	mov es:[edi].fde_size,0
	mov eax,es:[esi].fde_time
	mov es:[edi].fde_time,eax
	mov eax,es:[esi].fde_time+4
	mov es:[edi].fde_time+4,eax
	mov es:[edi].fde_valid,DIR_ENTRY_RESTRUCT
	call WriteSector
    UnlockSector
	int 3
    call RedoDirEntries
    call RedoFileEntries
	clc

rdsDone:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
RedoDirSel	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UpdateDirSel
;
;		DESCRIPTION:    Update directory selector (possible restructure)
;
;		PARAMETERS:		FS			Dir selector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateDirSel	Proc near
	push eax
;
	mov eax,fs:fds_deleted_entries
	cmp eax,128
	jc udsDone
;
	call RedoDirSel
	
udsDone:
	pop eax
	ret
UpdateDirSel	Endp


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
    call FindDirInfo
    jc cdeDone
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
	inc fs:fds_used_entries
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
	mov esi,eax
	mov eax,es:[esi].fde_time
	mov es:[edx].de_time,eax
	mov eax,es:[esi].fde_time+4
	mov es:[edx].de_time+4,eax
;
	push bx
	mov bx,fs
	InsertDirEntry
	inc fs:fds_used_entries
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
    push ecx
    push edx
    push esi
;
    mov ecx,fs:fds_object_sector
    call DirDataLogToPhysSector
    jc cddDone
;
    mov al,ds:drive_nr
    LockSector
;
    mov cx,80h

cddSectorLoop:
	mov al,es:[esi].fdd_valid
	or al,al
	jnz cddNotDeleted
;
	inc fs:fds_deleted_entries
	jmp cddNext
	
cddNotDeleted:
	cmp al,DIR_DATA_OK
	jnz cddNext
;
	mov edx,es:[esi]
	and edx,0FFFFFFh
	call CacheDirEntry
	jnc cddNext
;
	inc fs:fds_deleted_entries
    mov es:[esi].fdd_valid,0    
    call WriteSector

cddNext:
	add esi,4
	loop cddSectorLoop
;
    UnlockSector
	clc

cddDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ax
    ret
CacheDirData Endp
    

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
    mov ecx,fs:fds_entry_sector
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
	mov fs:fds_data_sector,edx
	call CacheDirData
	jnc cdoNext
;
    int 3
    mov dword ptr es:[esi],0    
    call WriteSector

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CacheDirSel
;
;		DESCRIPTION:    Cache dir
;
;		PARAMETERS:		FS			Dir selector
;                       EDX         Logical sector
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CacheDirSel   Proc near
    pushad
;
    mov fs:fds_entry_sector,edx
    call FindDirInfo
    jc cdDone
;    
	mov dx,ax
	sub dx,si
	mov fs:fds_info_offset,dx
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
	mov fs:fds_object_sector,edx
    call CacheDirObject
	add edi,4
	loop cdCacheLoop
;
	call UpdateDirSel
	clc

cdUnlock:
    pushf
    UnlockSector
    popf

cdDone:
    popad
    ret
CacheDirSel   Endp


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
	push fs
	push gs
	push eax
	push edx
;
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
;
	or edx,edx
	jnz cache_sub_dir
;
	mov fs:fds_owner_sector,-1
	call GetRootSector
    jc cache_dir_done
;
    call CacheDirSel
	jmp cache_dir_done

cache_sub_dir:
	int 3
	mov edx,es:[edx].fde_entry_sector
	call CacheDirSel

cache_dir_done:
    pop edx
	pop eax
	pop gs
	pop fs
	pop es
	ret
cache_dir	Endp


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
    push ecx
    push edx
;
    mov ecx,fs:fds_object_sector
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
    pop ecx
    pop eax
    ret
FindDirData Endp
    
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
    mov ecx,fs:fds_entry_sector
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
	jnz fdoNext
;
	push ebx
	push esi
	mov edx,es:[esi]
	and edx,0FFFFFFh
	mov fs:fds_data_sector,edx
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindDirSel
;
;		DESCRIPTION:    Find director entry from dir selector
;
;		PARAMETERS:		FS			Dir selector
;						BX			Dir selector
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
    mov ecx,fs:fds_owner_sector
    mov edx,fs:fds_entry_sector
    call DirEntryLogToPhysSector
    jc fdsDone
;    
    mov al,ds:drive_nr
    LockSector
	add si,fs:fds_info_offset
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
	mov fs:fds_object_sector,edx
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitFileEntry
;
;		DESCRIPTION:    Init file entry time to current date & time
;
;		PARAMETERS:		EDX			Dir entry 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitFileEntry   Proc near
    push es
	push eax
	push edx
	push edi
;
	mov ax,flat_sel
	mov es,ax
	mov edi,edx
    GetTime
	mov es:[edi].de_time,eax
	mov es:[edi+4].de_time,edx
	mov es:[edi].dfe_data_size,0
;
	pop edi
	pop edx
	pop eax
	pop es
	ret
InitFileEntry    Endp


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
	push gs
	push eax
	push ecx
	push edi
;
    int 3
	mov ax,flat_sel
	mov es,ax
	mov edi,es:[edx].ffe_entry_sector
	mov fs,bx
	call FindDirSel
	jc dfDone
;
	push edx
	mov ecx,fs:fds_data_sector
	mov edx,edi
	call FreeSector
	pop edx
	jc dfUnlock
;
	mov es:[esi].fdd_valid,0
    call WriteSectorFree

dfUnlock:
	UnlockSector
;
	inc fs:fds_deleted_entries
;	call UpdateDirSel
	clc

dfDone:
	pop edi
	pop ecx
	pop eax
	pop gs
	pop fs
	pop es
	ret
delete_file	ENDP


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
	push fs
	push gs
;
	mov fs,bx
    call CreateFileEntry
    call InitFileEntry
    call AddFileEntry
    jc cfFail
;    
	InsertFileEntry	
	inc fs:fds_used_entries
	jmp cfDone

cfFail:
    FreeLinear
    xor edx,edx
    stc

cfDone:
	pop gs
	pop fs
	ret
create_file	ENDP

code	ENDS

	END
