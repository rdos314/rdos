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
drive_lba_sectors			DD ?
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
	push edi
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
	pop edi
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
	push edi
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
	pop edi
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
;		NAME:			GetDriveParams
;
;		DESCRIPTION:	Get drive param
;
;		PARAMETERS:		DS		IDE SEGMENT
;						FS		DRIVE SEL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDriveParams	Proc near
	push es
	pushad
;
	mov ax,flat_sel
	mov es,ax
	mov eax,200h
	AllocateSmallLinear
	mov edi,edx
;
	mov fs:drive_precomp,0FFh
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
	mov eax,es:[edi+120]
	mov fs:drive_lba_sectors,eax
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
	pushf
	mov ecx,200h
	mov edx,edi
	FreeLinear
	popf
;
	popad
	pop es
	ret
GetDriveParams	Endp

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
	push esi
	push edi
;
	cmp cl,10h
	jnc install_part_done
;
	mov di,cs
	mov es,di
	movzx di,cl
	shl di,1
	mov di,word ptr cs:[di].FsTab
	IsFileSystemAvailable
	jc install_part_done
;
	AllocateStaticDrive
	mov ah,fs:disc_nr
	OpenDrive
;
	InstallFileSystem
	clc

install_part_done:
	pop edi
	pop esi
	pop ax
	pop es
	ret
InstallPartition	Endp

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
	mov eax,es:[edi].dh_data
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
	int 3
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
	mov ecx,255
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
	mov ax,flat_sel
	mov es,ax
;
	GetThread
	mov fs:disc_thread,ax
	mov bx,fs:disc_sel

discbuf_thread_loop:
	WaitForDiscRequest
	call perform_one
	jmp discbuf_thread_loop

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_TIMEOUT
;
;		DESCRIPTION:	Install unit timeout
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_timeout	Proc far
	push ds
	push ax
	push bx
;
	mov ax,ide_data_sel
	mov ds,ax
	mov bx,ds:IdeThread
	Signal
;
	pop bx
	pop ax
	pop ds
	ret
install_timeout	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_UNIT
;
;		DESCRIPTION:	Install a unit
;
;		PARAMETERS:		AL		UNIT #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc0	DB 'Ide Drive 0',0
disc1	DB 'Ide Drive 1',0

disc_name_tab:
dnt00	DW OFFSET disc0
dnt01	DW OFFSET disc1

install_unit	Proc near
	ClearSignal
	call CheckReady
	jc install_unit_done
;
	push ax
	GetSystemTime
	add eax,119300
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET install_timeout
	mov bx,cs
	StartTimer
	pop ax
;
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
	StopTimer
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
	call GetDriveParams
	jnc install_unit_ok
;
	xor ax,ax
	mov fs,ax
	FreeMem
	stc
	jmp install_unit_done

install_unit_ok:
	movzx bx,al
	shl bx,1
	mov ds:[bx].DriveSelArr,fs
;
	mov ecx,10000h
	mov bx,fs
	InstallDisc
	mov fs:disc_sel,bx
	mov fs:disc_nr,al
;
	mov ax,fs:drive_sectors_per_cyl
	mul fs:drive_heads
	movzx eax,ax
	mov esi,eax
	movzx edi,fs:drive_cyls	
	mul edi
	mov edi,eax
;
	mov cl,fs:drive_lba_mode
	or cl,cl
	jz install_unit_chs
;
	cmp edi,fs:drive_lba_sectors
	jae install_unit_chs
;
	mov eax,1
	mov edx,fs:drive_lba_sectors

install_unit_lba_norm_loop:
	shl eax,1
	shr edx,1
	cmp eax,edx
	jc install_unit_lba_norm_loop

install_unit_lba_normed:
	mov esi,edx
	mov ebx,esi
	mov ecx,edx

install_unit_lba_loop:
	xor edx,edx
	mov eax,fs:drive_lba_sectors
	div esi
	cmp ecx,edx
	jc install_unit_lba_next
;	
	mov ecx,edx
	mov ebx,esi
	or edx,edx
	jz install_unit_lba_do

install_unit_lba_next:
	inc esi
	cmp esi,eax
	jbe install_unit_lba_loop

install_unit_lba_do:
	mov edx,eax
	mov eax,ebx
	jmp install_unit_set_param
	
install_unit_chs:
	xor edx,edx
	mov eax,edi
	div esi
	mov edx,esi
	xchg eax,edx

install_unit_set_param:
	mov fs:drive_sectors_per_unit,ax
	mov cx,512
	mov si,fs:drive_sectors_per_cyl
	mov di,fs:drive_heads
	mov bx,fs:disc_sel
	SetDiscParam
;
	push ds
	mov ax,cs
	mov ds,ax
	mov es,ax
	movzx di,fs:disc_nr
	add di,di
	mov di,word ptr cs:[di].disc_name_tab
	mov si,OFFSET discbuf_thread
	mov ax,4
	mov cx,100h
	CreateThread
	pop ds
	clc

install_unit_done:
	ret
install_unit	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISC_ASSIGN
;
;		DESCRIPTION:	Assign discs
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_assign	Proc far
	mov ax,ide_data_sel
	mov ds,ax
	GetThread
	mov IdeThread,ax
	mov al,0
	call install_unit
	mov al,1
	call install_unit
	mov IdeThread,0
	ret
disc_assign	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DRIVE_ASSIGN1
;
;		DESCRIPTION:	Drive assign, pass 1
;
;		PARAMETERS:		BX		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drive_assign1	Proc far
	mov ax,ide_data_sel
	mov ds,ax
	mov fs,bx
;
	mov ax,flat_sel
	mov es,ax
	mov eax,200h
	AllocateSmallLinear
	mov edi,edx
;
	mov cx,1
	xor bx,bx
	xor edx,edx
	call ReadDrive
;
	mov esi,1BEh

drive_assign_loop1:
	mov cl,es:[esi+edi].part_type
	or cl,cl
	jz drive_assign_free1
;
	mov edx,es:[esi+edi].part_start_sector
	call InstallPartition

drive_assign_next_part1:
	add si,10h
	cmp si,1FEh
	jne drive_assign_loop1

drive_assign_free1:
	mov ecx,200h
	mov edx,edi
	FreeLinear
;
	ret
drive_assign1	Endp

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
	mov ebp,edx
	mov eax,200h
	AllocateSmallLinear
	mov edi,edx
;
	mov eax,ebp
	xor edx,edx
	movzx ecx,word ptr fs:drive_sectors_per_unit
	div ecx
	mov bx,dx
	mov edx,eax
;
	mov cx,1
	call ReadDrive
;
	mov esi,1BEh

install_ext_loop1:
	mov cl,es:[esi+edi].part_type
	or cl,cl
	jz install_ext_next_part1
;
	cmp cl,5
	je install_ext_next_part1
;
	cmp cl,0Fh
	je install_ext_next_part1
;
	push ebp
	mov edx,es:[esi+edi].part_start_sector
	add edx,ebp
	call InstallPartition
	pop ebp

install_ext_next_part1:
	add si,10h
	cmp si,1FEh
	jne install_ext_loop1
;
	mov esi,1BEh

install_ext_loop2:
	mov cl,es:[esi+edi].part_type
	or cl,cl
	jz install_ext_next_part2
;
	cmp cl,5
	je install_ext_install2
;
	cmp cl,0Fh
	jne install_ext_next_part2

install_ext_install2:
	push esi
	push edi
	push ebp
	mov edx,es:[esi+edi].part_start_sector
	add edx,ebp
	call InstallExtended
	pop ebp
	pop edi
	pop esi

install_ext_next_part2:
	add si,10h
	cmp si,1FEh
	jne install_ext_loop2
;
	mov ecx,200h
	mov edx,edi
	FreeLinear
	ret
InstallExtended	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DRIVE_ASSIGN2
;
;		DESCRIPTION:	Assign disc drives, pass 2
;
;		PARAMETERS:		BX		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drive_assign2	Proc far
	mov ax,ide_data_sel
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
;
	mov eax,200h
	AllocateSmallLinear
	mov edi,edx
;
	mov cx,1
	xor bx,bx
	xor edx,edx
	call ReadDrive
;
	mov esi,1BEh

drive_assign_loop2:
	mov cl,es:[esi+edi].part_type
	or cl,cl
	jz drive_assign_next_part2
;
	cmp cl,5
	je drive_assign_install2
;
	cmp cl,0Fh
	jne drive_assign_next_part2

drive_assign_install2:
	push esi
	push edi
	mov edx,es:[esi+edi].part_start_sector
	call InstallExtended
	pop edi
	pop esi

drive_assign_next_part2:
	add si,10h
	cmp si,1FEh
	jne drive_assign_loop2
;
	mov ecx,200h
	mov edx,edi
	FreeLinear
;
	mov bx,fs:disc_sel
	StartDisc
	clc
	ret
drive_assign2	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DEMAND_MOUNT
;
;		DESCRIPTION:	Mount disc drive on demand
;
;		PARAMETERS:		BX		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

demand_mount	Proc far
	ret
demand_mount	Endp

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

disc_ctrl:
dct00	DW OFFSET disc_assign,		ide_code_sel
dct01	DW OFFSET drive_assign1,	ide_code_sel
dct02	DW OFFSET drive_assign2,	ide_code_sel
dct03	DW OFFSET demand_mount,		ide_code_sel

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
	mov di,OFFSET disc_ctrl
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

