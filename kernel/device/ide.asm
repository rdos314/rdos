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
; IDE.ASM
; IDE disk driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME ide

GateSize = 16

INCLUDE ..\os\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\user.def
INCLUDE ..\os\virt.def
INCLUDE ..\os\os.def
INCLUDE ..\os\user.inc
INCLUDE ..\os\virt.inc
INCLUDE ..\os\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\int.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\drive.inc

part_struc	STRUC

part_status				DB ?
part_start_head			DB ?
part_start_cyl_sector	DW ?
part_type				DB ?
part_end_head			DB ?
part_end_cyl_sector		DW ?
part_start_sector		DD ?
part_sectors			DD ?

part_struc	ENDS

drive_data		STRUC

drive_lba_mode				DB ?
drive_precomp				DB ?
drive_sectors_per_cyl		DW ?
drive_heads					DW ?
drive_cyls					DW ?
drive_sectors_per_unit		DW ?
disc_sel					DW ?
disc_thread					DW ?
disc_sub_unit				DB ?
disc_nr						DB ?

drive_data		ENDS

ide_data    SEGMENT AT 0

IdeThread		DW ?
DriveSelArr		DW 2 DUP(?)
IdeSection		section_typ <>

ide_data    ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code
	assume ds:ide_data

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IDE_INT
;
;		DESCRIPTION:	IDE INTERRUPT
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ide_int	Proc far
	mov bx,IdeThread
	Signal
	ret
ide_int	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckReady
;
;		DESCRIPTION:	Wait for ready
;
;		PARAMETERS:		DS		IDE_DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckReady	PROC near
	push ax
	push cx
	push dx
;
	mov dx,1F7h
	mov cx,1000
CheckReadyLoop:
	in al,dx
	test al,80h
	clc
	jz CheckReadyDone
	mov ax,50
	WaitMicroSec
	loop CheckReadyLoop
	stc
CheckReadyDone:
	pop dx
	pop cx
	pop ax
	ret
CheckReady	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitDrq
;
;		DESCRIPTION:	Wait for data request
;
;		PARAMETERS:		DS		IDE_DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitDrq	Proc near
	push ax
	push cx
	push dx
;
	mov cx,100h
	mov dx,1F7h
WaitDrqLoop:
	in al,dx
	test al,8
	clc
	jnz WaitDrqDone
	loop WaitDrqLoop
	stc
WaitDrqDone:
	pop dx
	pop cx
	pop ax
	ret
WaitDrq	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckStatus
;
;		DESCRIPTION:	Check transfer status
;
;		PARAMETERS:		DS		IDE_DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckStatus	Proc near
	push ax
	push dx
;
	mov dx,1F7h
	in al,dx
	test al,80h
	jnz CheckStatusFail
	test al,20h
	jnz CheckStatusFail
	test al,40h
	jz CheckStatusFail
	test al,10h
	jz CheckStatusFail
	test al,1
	clc
	jz CheckStatusDone
	mov dx,1F1h
	in al,dx
CheckStatusFail:
	stc
CheckStatusDone:
	pop dx
	pop ax
	ret
CheckStatus	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetupIdeTaskFile
;
;		DESCRIPTION:	Setup IDE comp. task file
;
;		PARAMETERS:		DS		IDE_DATA
;						FS		Disc sel
;						AH		Precomp
;						BH		Head #
;						BL		Sector
;						CX		Number of sectors
;						DX		Cylinder
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupIdeTaskFile	Proc near
	push ax
	push bx
	push dx
;
	call CheckReady
	jc SetupIdeTaskDone
	push dx
	mov dx,1F1h
;
	jmp short $+2
	mov al,ah
	out dx,al
	inc dx
;
	jmp short $+2
	mov ax,cx
	out dx,al
	inc dx
;
	jmp short $+2
	mov al,bl
	out dx,al
	inc dx
;
	pop ax
	jmp short $+2
	out dx,al
	inc dx
;
	jmp short $+2
	mov al,ah
	out dx,al
	inc dx
;
	mov al,fs:disc_sub_unit
	shl al,4
	or al,bh
	or al,0A0h
	out dx,al
	clc
SetupIdeTaskDone:
	pop dx
	pop bx
	pop ax
	ret
SetupIdeTaskFile	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetupLbaTaskFile
;
;		DESCRIPTION:	Setup LBA comp. task file
;
;		PARAMETERS:		DS		IDE_DATA
;						FS		Disc sel
;						AH		Precomp
;						CX		Number of sectors
;						EDX		Sector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupLbaTaskFile	Proc near
	push ax
	push bx
	push dx
;
	call CheckReady
	jc SetupLbaTaskDone
;
	push edx
	mov dx,1F1h
;
	jmp short $+2
	mov al,ah
	out dx,al
	inc dx
;
	jmp short $+2
	mov al,cl
	out dx,al
	inc dx
;
	pop ax
	jmp short $+2
	out dx,al
	inc dx
;
	mov al,ah
	jmp short $+2
	out dx,al
	inc dx
;
	pop ax
	jmp short $+2
	out dx,al
	inc dx
;
	mov bl,ah
	mov al,fs:disc_sub_unit
	shl al,4
	or al,bl
	or al,0E0h
	out dx,al
	clc
SetupLbaTaskDone:
;
	pop dx
	pop bx
	pop ax
	ret
SetupLbaTaskFile	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RunTaskFile
;
;		DESCRIPTION:	Run command
;
;		PARAMETERS:		DS		IDE SEGMENT
;						AL		COMMAND CODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunTaskFile	Proc near
	push dx
	mov dx,1F7h
	out dx,al
	WaitForSignal
	jc RunTaskFileDone
	call CheckStatus
RunTaskFileDone:
	pop dx
	ret
RunTaskFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadTaskFile
;
;		DESCRIPTION:	Read data from device
;
;		PARAMETERS:		DS		IDE SEGMENT
;						AL		COMMAND CODE
;						CX		Number of sectors
;						ES:EDI	Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadTaskFile	Proc near
	push cx
	push dx
	push di
;
	ClearSignal
	mov dx,1F7h
	out dx,al
ReadTaskFileInt:
	WaitForSignal
	push cx
	mov dx,1F0h
	mov cx,256
	rep
	db 67h
	insw
	pop cx
	call CheckStatus
	jc ReadTaskFileDone
	loop ReadTaskFileInt
	clc
ReadTaskFileDone:
;
	pop di
	pop dx
	pop cx
	ret
ReadTaskFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteTaskFile
;
;		DESCRIPTION:	Write data to device
;
;		PARAMETERS:		DS		IDE SEGMENT
;						AL		Command code
;						CX		Number of sectors
;						ES:EDI	Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteTaskFile	PROC near
	push ax
	push cx
	push dx
	push di
;
	ClearSignal
	mov dx,1F7h
	out dx,al
WriteTaskFileInt:
	call WaitDrq
	jc WriteTaskFileDone
	push cx
	mov dx,1F0h
	mov cx,256
WriteTaskFileLoop:
	mov ax,es:[edi]
	add edi,2
	out dx,ax
	loop WriteTaskFileLoop
	pop cx
	WaitForSignal
	call CheckStatus
	jc WriteTaskFileDone
	loop WriteTaskFileInt
	clc
WriteTaskFileDone:
	pop di
	pop dx
	pop cx
	pop ax
	ret
WriteTaskFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadDrive
;
;		DESCRIPTION:	Read data
;
;		PARAMETERS:		FS		Disc sel
;						BX		Sector #
;						CX		Number of sectors
;						EDX		Unit #
;						EDI		Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadDrive	Proc near
	push bx
	mov bx,ide_data_sel
	mov ds,bx
	EnterSection IdeSection
	GetThread
	mov IdeThread,ax
	pop bx
	cmp fs:drive_lba_mode,0
	jz ReadDriveIde

ReadDriveLba:
	push edx
	movzx eax,fs:drive_sectors_per_unit
	mul edx
	movzx ebx,bx
	add eax,ebx
	mov edx,eax
	mov ah,fs:drive_precomp
	call SetupLbaTaskFile
	pop edx
	jmp ReadDriveStart

ReadDriveIde:
	push bx
	mov ax,bx
	div byte ptr fs:drive_sectors_per_cyl
	mov bh,al
	mov bl,ah
	inc bl
	mov ah,fs:drive_precomp
	call SetupIdeTaskFile
	pop bx

ReadDriveStart:
	jc ReadDriveDone
	mov al,20h
	call ReadTaskFile

ReadDriveDone:
	pushf
	mov IdeThread,0
	LeaveSection IdeSection
	popf
	ret
ReadDrive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteDrive
;
;		DESCRIPTION:	Write data
;
;		PARAMETERS:		FS		Disc sel
;						BX		Sector #
;						CX		Number of sectors
;						EDX		Unit #
;						EDI		Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDrive	Proc near
	push bx
	mov bx,ide_data_sel
	mov ds,bx
	EnterSection IdeSection
	GetThread
	mov IdeThread,ax
	pop bx
	cmp fs:drive_lba_mode,0
	jz WriteDriveIde
WriteDriveLba:
	push edx
	movzx eax,fs:drive_sectors_per_unit
	mul edx
	movzx ebx,bx
	add eax,ebx
	mov edx,eax
	mov ah,fs:drive_precomp
	call SetupLbaTaskFile
	pop edx
	jmp WriteDriveStart

WriteDriveIde:
	push bx
	mov ax,bx
	div byte ptr fs:drive_sectors_per_cyl
	mov bh,al
	mov bl,ah
	inc bl
	mov ah,fs:drive_precomp
	call SetupIdeTaskFile
	pop bx

WriteDriveStart:
	jc WriteDriveDone
	mov al,30h
	call WriteTaskFile
WriteDriveDone:
	pushf
	mov IdeThread,0
	LeaveSection IdeSection
	popf
	ret
WriteDrive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDriveParam
;
;		DESCRIPTION:	Get drive param
;
;		PARAMETERS:		DS		IDE SEGMENT
;						ES		FLAT_SEL
;						FS		DRIVE SEL
;						ES:EDI	200H BUFFER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDriveParam	Proc near
	xor dx,dx
	xor bx,bx
	mov cx,1
	mov ah,fs:drive_precomp
	call SetupIdeTaskFile
	jc get_drive_param_done
;
	mov al,0ECh
	call ReadTaskFile
	jc get_drive_param_done
;
	mov dx,word ptr es:[edi+2]
	mov fs:drive_cyls,dx
	mov bx,es:[edi+6]
	mov fs:drive_heads,bx
	push dx
	mov ax,es:[edi+12]
	mov fs:drive_sectors_per_cyl,ax
	mul fs:drive_heads
	mov fs:drive_sectors_per_unit,ax
	pop dx
	mov bh,byte ptr fs:drive_heads
	dec bh
	mov bl,byte ptr fs:drive_sectors_per_cyl
	mov cx,1
	dec dx
;	call SetupIdeTaskFile
;	jc get_drive_param_done
;
;	push ax
;	mov al,91h
;	call RunTaskFile
;	pop ax
;	jc get_drive_param_done
;
	mov fs:drive_lba_mode,1
	xor edx,edx
	call SetupLbaTaskFile
	jc get_drive_param_done
;
	mov al,20h
	call ReadTaskFile	
	jnc get_drive_param_done
;
	mov fs:drive_lba_mode,0
	mov bh,0
	mov bl,1
	mov cx,1
	xor dx,dx
	call SetupIdeTaskFile
	jc get_drive_param_done
;
	mov al,20h
	call ReadTaskFile
get_drive_param_done:
	ret
GetDriveParam	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InstallPartition
;
;		DESCRIPTION:	Install partition
;
;		PARAMETERS:		DS		IDE SEGMENT
;						ES		FLAT_SEL
;						FS		Disc sel
;						CL		PARTITION TYPE
;						EDX		START SECTOR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fs_unknown	DB 'UNKNOWN '
fs_fat12	DB 'FAT12   '
fs_fat16	DB 'FAT16   '
fs_fat32	DB 'FAT32   '
fs_hpfs		DB 'HPFS    '

FsTab:
fs00	DW OFFSET fs_unknown
fs01	DW OFFSET fs_fat12
fs02	DW OFFSET fs_unknown
fs03	DW OFFSET fs_unknown
fs04	DW OFFSET fs_fat16
fs05	DW OFFSET fs_unknown
fs06	DW OFFSET fs_fat16
fs07	DW OFFSET fs_hpfs
fs08	DW OFFSET fs_unknown
fs09	DW OFFSET fs_unknown
fs0A	DW OFFSET fs_unknown
fs0B	DW OFFSET fs_fat32
fs0C	DW OFFSET fs_fat32
fs0D	DW OFFSET fs_unknown
fs0E	DW OFFSET fs_unknown
fs0F	DW OFFSET fs_unknown

InstallPartition	Proc near
	push es
	push ax
	push di
;
	LeaveSection IdeSection
	push ds
;
	AllocateStaticDrive
	mov ah,fs:disc_nr
	OpenDrive
;
	mov di,cs
	mov es,di
	movzx di,cl
	shl di,1
	mov di,word ptr cs:[di].FsTab
	InstallFileSystem
;
	pop ds
	EnterSection IdeSection
	clc
;
	pop di
	pop ax
	pop es
	ret
InstallPartition	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InstallExtended
;
;		DESCRIPTION:	Install extended partion on drive
;
;		PARAMETERS:		DS		IDE SEGMENT
;						ES		FLAT_SEL
;						FS		Disc sel
;						EDX		Current sector
;						EDI		200H buffer with partition sector
;						ESI		Partition offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallExtended	Proc near
	pushad
;
	push ax
	push edx
	mov eax,200h
	AllocateSmallLinear
	mov edi,edx
	pop edx
	pop ax
;
	mov esi,edx

InstallExtendedLoop:
	push edx
	push eax
	mov eax,esi
	xor edx,edx
	movzx ecx,word ptr fs:drive_sectors_per_unit
	div ecx
	mov bx,dx
	mov edx,eax
	pop eax
;
	mov cx,1
	LeaveSection IdeSection
	call ReadDrive
	EnterSection IdeSection
	pop edx
;
	mov cl,es:[edi+1BEh].part_type
	or cl,cl
	jz InstallExtendedDone
;
	cmp cl,10h
	cmc
	jc InstallExtendedNextPart
;
	push edx
	mov edx,esi
	add edx,es:[edi+1BEh].part_start_sector
	call InstallPartition
	pop edx

InstallExtendedNextPart:
	mov cl,es:[edi+1CEh].part_type
	cmp cl,5
	jne InstallExtendedDone
;
	mov esi,edx
	add esi,es:[edi+1CEh].part_start_sector
	jmp InstallExtendedLoop

InstallExtendedDone:
	mov ecx,200h
	mov edx,edi
	FreeLinear
;
	popad
	ret
InstallExtended	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InstallMain
;
;		DESCRIPTION:	Install main parition on drive
;
;		PARAMETERS:		DS		IDE SEGMENT
;						ES		FLAT_SEL
;						FS		Disc sel
;						EDX		Current sector
;						EDI		200H buffer with partition sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallMain	Proc near
	push ax
	push bx
	push cx
	push edx
	push esi
;
	mov esi,1BEh

InstallMainLoop:
	mov cl,es:[esi+edi].part_type
	or cl,cl
	jz InstallMainDone
;
	cmp cl,10h
	cmc
	jc InstallMainNextPart
;
	push edx
	add edx,es:[esi+edi].part_start_sector
	call InstallPartition
	pop edx

InstallMainNextPart:
	add si,10h
	cmp si,1FEh
	je InstallMainDone
;
	mov cl,es:[esi+edi].part_type
	or cl,cl
	jz InstallMainDone
;
	cmp cl,5
	jne InstallMainLoop
;
	push edx
	add edx,es:[esi+edi].part_start_sector
	call InstallExtended
	pop edx
	jmp InstallMainNextPart

InstallMainDone:
	pop esi
	pop edx
	pop cx
	pop bx
	pop ax
	ret
InstallMain	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			open_drive
;
;		DESCRIPTION:	Open up a drive
;
;		PARAMETERS:		FS		Disc sel
;						
;		RETURNS:		AX		Sectors / unit
;						CX		Bytes / sector
;						EDX		Units
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_drive	Proc near
	push ebx
	push edi
;
	mov ax,ide_data_sel
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
	EnterSection IdeSection
	GetThread
	mov IdeThread,ax
	mov eax,200h
	AllocateSmallLinear
	mov edi,edx
;
	call GetDriveParam
	jc open_drive_done
;
	call InstallMain
	LeaveSection IdeSection
;
	EnterSection IdeSection
	GetThread
	mov IdeThread,ax
	mov ax,fs:drive_sectors_per_cyl
	mul fs:drive_heads
	mov cx,512
	movzx edx,fs:drive_cyls	
	clc

open_drive_done:
	pushf
	mov IdeThread,0
	LeaveSection IdeSection
	push cx
	push edx
	mov ecx,200h
	mov edx,edi
	FreeLinear
	xor dx,dx
	mov ds,dx
	pop edx
	pop cx
	popf
;
	pop edi
	pop ebx
	ret
open_drive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISCINIT_THREAD
;
;		DESCRIPTION:	Thread to open a disc drive
;
;		PARAMETERS:		FS		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

discinit_thread_name	DB 'Disc Init',0

discinit_thread	Proc far
	mov ax,ide_data_sel
	mov ds,ax
	call open_drive
	jc discinit_thread_done
;
	mov bx,fs:disc_thread
	Signal
;
	mov bx,fs:disc_sel
	FlushDisc

discinit_thread_done:
	ret
discinit_thread	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_drive
;
;		DESCRIPTION:	Read drive
;
;		PARAMETERS:		FS		Disc selector
;						ESI		Disc handle array
;						ECX		Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_drive	Proc near
	mov ax,ide_data_sel
	mov ds,ax
	EnterSection IdeSection
;
	cmp ecx,256
	jb read_drive_retry_in_range
;
	mov ecx,255

read_drive_retry_in_range:
	push ecx
	push esi

read_drive_retry_loop:
	ClearSignal
	GetThread
	mov IdeThread,ax
;
	cmp fs:drive_lba_mode,0
	jz read_drive_ide

read_drive_lba:
	movzx edx,es:[edi].dh_unit
	movzx eax,fs:drive_sectors_per_unit
	mul edx
	movzx ebx,es:[edi].dh_sector
	add eax,ebx
	mov edx,eax
	mov ah,fs:drive_precomp
	call SetupLbaTaskFile
	jmp read_drive_start

read_drive_ide:
	mov dx,es:[edi].dh_unit
	mov ax,es:[edi].dh_sector
	div byte ptr fs:drive_sectors_per_cyl
	mov bh,al
	mov bl,ah
	inc bl
	mov ah,fs:drive_precomp
	call SetupIdeTaskFile

read_drive_start:
	jc read_drive_fail
;
	mov bp,3
	mov al,20h
	mov dx,1F7h
	out dx,al

read_sector_loop:
	WaitForSignal
	call CheckStatus
	jc read_drive_retry
;
	push cx
	push edi
	mov edi,es:[edi].dh_data
	mov dx,1F0h
	mov ecx,256
	rep
	db 67h
	insw
	pop edi
	pop cx
	jmp read_drive_ok

read_drive_retry:
	sub bp,1
	jnz read_drive_retry_loop

read_drive_fail:
	mov es:[edi].dh_state,STATE_BAD
	mov bx,fs:disc_sel
	DiscRequestCompleted
	jmp read_drive_done

read_drive_ok:
	mov es:[edi].dh_state,STATE_USED
	mov bx,fs:disc_sel
	DiscRequestCompleted

read_drive_check_next:
	add esi,4
	mov edi,es:[esi]
	sub cx,1
	jnz read_sector_loop

read_drive_done:
	LeaveSection IdeSection
	pop esi
	pop ecx
	mov bx,fs:disc_sel
	DiscRequestArrayDone	
	ret
read_drive	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_drive
;
;		DESCRIPTION:	Perform a write request
;
;		PARAMETERS:		DS		Disc selector
;						ESI		Disc handle array
;						ECX		Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive	Proc near
	mov ax,ide_data_sel
	mov ds,ax
	EnterSection IdeSection
;
	mov ax,es:[edi].dh_sector
	or ax,es:[edi].dh_unit
	jnz write_drive_not_zero
;
	int 3

write_drive_not_zero:
	cmp ecx,256
	jb write_drive_retry_in_range
;
	mov ecx,255

write_drive_retry_in_range:
	push ecx
	push esi

write_drive_retry_loop:
	ClearSignal
	GetThread
	mov IdeThread,ax
;
	cmp fs:drive_lba_mode,0
	jz write_drive_ide

write_drive_lba:
	movzx edx,es:[edi].dh_unit
	movzx eax,fs:drive_sectors_per_unit
	mul edx
	movzx ebx,es:[edi].dh_sector
	add eax,ebx
	mov edx,eax
	mov ah,fs:drive_precomp
	call SetupLbaTaskFile
	jmp write_drive_start

write_drive_ide:
	mov dx,es:[edi].dh_unit
	mov ax,es:[edi].dh_sector
	div byte ptr fs:drive_sectors_per_cyl
	mov bh,al
	mov bl,ah
	inc bl
	mov ah,fs:drive_precomp
	call SetupIdeTaskFile

write_drive_start:
	jc write_drive_retry
;
	mov bp,3
	mov al,30h
	mov dx,1F7h
	out dx,al

write_sector_loop:
	call WaitDrq
	jc write_drive_retry
;
	push cx
	push esi
	mov esi,es:[edi].dh_data
	mov dx,1F0h
	mov ecx,256
	rep
	db 26h
	db 67h
	outsw
	pop esi
	pop cx
;
	WaitForSignal
	call CheckStatus
	jnc write_drive_ok

write_drive_retry:
	sub bp,1
	jnz write_drive_retry_loop

write_drive_fail:
	mov es:[edi].dh_state,STATE_BAD
	mov bx,fs:disc_sel
	DiscRequestCompleted
	jmp write_drive_done

write_drive_ok:
	mov es:[edi].dh_state,STATE_USED
	mov bx,fs:disc_sel
	DiscRequestCompleted

write_drive_check_next:
	add esi,4
	mov edi,es:[esi]
	sub cx,1
	jnz write_sector_loop

write_drive_done:
	LeaveSection IdeSection
	pop esi
	pop ecx
	mov bx,fs:disc_sel
	DiscRequestArrayDone
	ret
write_drive	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			perform_one
;
;		DESCRIPTION:	Perform one request
;
;		PARAMETERS:		FS		Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_one	Proc near

perform_one_loop:
	GetDiscRequestArray
	jc perform_one_done
;
	mov edi,es:[esi]
	mov al,es:[edi].dh_state
	cmp al,STATE_EMPTY
	je perform_one_read
;
	cmp al,STATE_DIRTY
	je perform_one_write
;
	cmp al,STATE_SEQ
	jne perform_one_done

perform_one_write:
	call write_drive
	jmp perform_one_loop

perform_one_read:
	call read_drive
	jmp perform_one_loop

perform_one_done:
	ret
perform_one	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISCBUF_THREAD
;
;		DESCRIPTION:	Thread to handle disc buffer queue
;
;		PARAMETERS:		FS		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

discbuf_thread:
	mov ax,ide_data_sel
	mov ds,ax
	InstallDisc
	mov fs:disc_sel,bx
	mov fs:disc_nr,al
	GetThread
	mov fs:disc_thread,ax
	push ds
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET discinit_thread
	mov di,OFFSET discinit_thread_name
	mov ax,4
	mov cx,100h
	CreateThread
	pop ds
;
	mov ax,flat_sel
	mov es,ax
	WaitForSignal

discbuf_thread_loop:
	WaitForDiscRequest
	call perform_one
	jmp discbuf_thread_loop

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_UNIT
;
;		DESCRIPTION:	Install a unit
;
;		PARAMETERS:		AL		UNIT #
;						DI		NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_unit	Proc near
	ClearSignal
	call CheckReady
	jc install_unit_done
	push ax
;
	mov dx,1F6h
	shl al,4
	or al,0A0h
	out dx,al
	inc dx
;
	jmp short $+2
	mov al,0ECh
	out dx,al
;
	WaitForSignal
	pop ax
;
	push ax
	mov dx,1F0h
	mov cx,256
install_unit_read:
	in ax,dx
	loop install_unit_read
	call CheckStatus
	pop ax
	jc install_unit_done
;
	push ax
	mov eax,SIZE drive_data
	AllocateSmallGlobalMem
	mov ax,es
	mov fs,ax
	pop ax
;
	mov fs:disc_sub_unit,al
	mov fs:drive_precomp,0FFh
	mov fs:drive_cyls,-1
	mov fs:drive_heads,-1
	mov fs:drive_sectors_per_cyl,-1
;
	movzx bx,al
	shl bx,1
	mov ds:[bx].DriveSelArr,es
;
	push ds
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET discbuf_thread
	mov ax,4
	mov cx,100h
	CreateThread
	pop ds

install_unit_done:
	ret
install_unit	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_DISC
;
;		DESCRIPTION:	Init disc callback
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc0	DB 'Ide Drive 0',0
disc1	DB 'Ide Drive 1',0

init_disc	Proc far
	mov ax,ide_data_sel
	mov ds,ax
	EnterSection IdeSection
	GetThread
	mov IdeThread,ax
	mov al,0
	mov di,OFFSET disc0
	call install_unit
	mov al,1
	mov di,OFFSET disc1
;	call install_unit
	mov IdeThread,0
	LeaveSection IdeSection
	ret
init_disc	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	push ds
	push es
	pusha
	mov bx,ide_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov dx,1F7h
	in al,dx
	cmp al,-1
	je init_ide_done
;
	mov di,OFFSET init_disc
	HookInitDisc
;
	mov eax,SIZE ide_data
	mov bx,ide_data_sel
	AllocateFixedSystemMem
	InitSection es:IdeSection
	mov es:IdeThread,0
;
	mov al,0Eh
	mov bx,ide_data_sel
	mov ds,bx
	mov bx,cs
	mov es,bx
	mov di,OFFSET ide_int
	RequestPrivateIrqHandler

init_ide_done:
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init

