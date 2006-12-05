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

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\drive.inc

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
drive_units					DW ?
drive_lba_sectors			DD ?
disc_io_base                DW ?
disc_ide_sel                DW ?
disc_sel					DW ?
disc_thread					DW ?
disc_sub_unit				DB ?
disc_nr						DB ?

drive_data		ENDS

ide_data    SEGMENT AT 0

IdeThread		DW ?
DriveSelArr		DW 2 DUP(?)
IdeSection		section_typ <>
IntFlag         DB ?

ide_data    ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

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
    mov ds:IntFlag,1
	mov bx,ds:IdeThread
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
;                       DX      Io base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckReady	PROC near
	push ax
	push cx
	push dx
;
	add dx,7
	mov cx,10000
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
;                       DX      Disc io base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitDrq	Proc near
	push ax
	push cx
	push dx
;
	mov cx,10000
	add dx,7
WaitDrqLoop:
	in al,dx
	test al,8
	clc
	jnz WaitDrqDone	
	mov ax,50
	WaitMicroSec
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
;                       DX      Disc io base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckStatus	Proc near
	push ax
	push dx
;
	add dx,7
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
	sub dx,6
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
    push dx
    mov dx,fs:disc_io_base
	call CheckReady
	pop dx
	jc SetupIdeTaskDone
;	
	push dx
	mov dx,fs:disc_io_base
	inc dx
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
    push dx
    mov dx,fs:disc_io_base
	call CheckReady
	pop dx
	jc SetupLbaTaskDone
;
	push edx
	mov dx,fs:disc_io_base
	inc dx
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
	pop dx
	pop bx
	pop ax
	ret
SetupLbaTaskFile	Endp

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
;                       DX      Disc io base
;						ES:EDI	Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadTaskFile	Proc near
	push cx
	push edi
;
	ClearSignal
	push dx
	add dx,7
	out dx,al
	pop dx
	
ReadTaskFileInt:
	WaitForSignal
	push ecx
	mov ecx,256
	rep
	db 67h
	insw
	pop ecx
	call CheckStatus
	jc ReadTaskFileDone
	loop ReadTaskFileInt
	clc
	
ReadTaskFileDone:
	pop edi
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
;                       DX      Disc io base
;						ES:EDI	Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteTaskFile	PROC near
	push ax
	push cx
	push edi
;
	ClearSignal
	push dx
	add dx,7
	out dx,al
	pop dx
	
WriteTaskFileInt:
	call WaitDrq
	jc WriteTaskFileDone
;	
	push cx
	mov cx,256
	
WriteTaskFileLoop:
	mov ax,es:[edi]
	add edi,2
	out dx,ax
	loop WriteTaskFileLoop
	pop cx
;	
	WaitForSignal
	call CheckStatus
	jc WriteTaskFileDone
;	
	loop WriteTaskFileInt
	clc
	
WriteTaskFileDone:
	pop edi
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
	mov ds,fs:disc_ide_sel
	EnterSection ds:IdeSection
	GetThread
	mov ds:IdeThread,ax
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
;
    push dx	
	mov al,20h
	mov dx,fs:disc_io_base
	call ReadTaskFile
	pop dx

ReadDriveDone:
	pushf
	mov ds:IdeThread,0
	LeaveSection ds:IdeSection
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
	mov ds,fs:disc_ide_sel
	EnterSection ds:IdeSection
	GetThread
	mov ds:IdeThread,ax
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
;
    push dx	
	mov al,30h
	mov dx,fs:disc_io_base
	call WriteTaskFile
	pop dx
	
WriteDriveDone:
	pushf
	mov ds:IdeThread,0
	LeaveSection ds:IdeSection
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
	mov dx,fs:disc_io_base
	call ReadTaskFile
	jc get_drive_param_done
;
	mov eax,es:[edi+120]
	mov fs:drive_lba_sectors,eax
	mov ax,word ptr es:[edi+2]
	mov fs:drive_cyls,ax
	mov ax,es:[edi+6]
	mov fs:drive_heads,ax
	mov ax,es:[edi+12]
	mov fs:drive_sectors_per_cyl,ax
;
    mov ax,es:[edi+98]
    test ax,200h
    jz get_drive_param_done
;        
	mov fs:drive_lba_mode,1
	mov cx,1
	mov ah,fs:drive_precomp
	xor edx,edx
	call SetupLbaTaskFile
	jc get_drive_param_done
;
	mov al,20h
	mov dx,fs:disc_io_base
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
	mov dx,fs:disc_io_base
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
;		NAME:			CalcParam
;
;		DESCRIPTION:	Calculate various parameters
;
;		PARAMETERS:		DS		IDE SEGMENT
;						FS		DRIVE SEL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcParam	Proc near
	pushad
;
	mov ax,fs:drive_sectors_per_cyl
	mul fs:drive_heads
	mov fs:drive_sectors_per_unit,ax
;
	movzx eax,ax
	mov esi,eax
	movzx edi,fs:drive_cyls	
	mul edi
	mov edi,eax
;
	mov cl,fs:drive_lba_mode
	or cl,cl
	jz calc_param_chs
;
	cmp edi,fs:drive_lba_sectors
	jae calc_param_chs
;
	mov eax,1
	mov edx,fs:drive_lba_sectors

calc_param_lba_norm_loop:
	shl eax,1
	shr edx,1
	cmp eax,edx
	jc calc_param_lba_norm_loop
;
	mov esi,edx
	mov ebx,esi
	mov ecx,edx

calc_param_lba_chs_loop:
	xor edx,edx
	mov eax,fs:drive_lba_sectors
	div esi
	cmp ecx,edx
	jc calc_param_lba_chs_next
;	
	mov ecx,edx
	mov ebx,esi
	or edx,edx
	jz calc_param_lba_chs_ok

calc_param_lba_chs_next:
	inc esi
	cmp esi,eax
	jbe calc_param_lba_chs_loop
;
	xor edx,edx
	mov eax,fs:drive_lba_sectors
	div ebx

calc_param_lba_chs_ok:
	mov edx,eax
	mov eax,ebx
	jmp calc_param_chs_ok
	
calc_param_chs:
	xor edx,edx
	mov eax,edi
	div esi
	mov edx,esi
	xchg eax,edx

calc_param_chs_ok:
	mov fs:drive_sectors_per_unit,ax
	mov fs:drive_units,dx
	mul dx
	push dx
	push ax
;
	mov eax,fs:drive_lba_sectors
	xor edx,edx
	movzx ecx,fs:drive_sectors_per_cyl
	div ecx
	xor edx,edx
	movzx ecx,fs:drive_heads
	div ecx

calc_param_bios_loop:
	cmp eax,1024
	jbe calc_param_bios_ok
;
	test cx,80h
	jnz calc_param_bios_max_head
;
	shl cx,1
	shr eax,1
	jmp calc_param_bios_loop

calc_param_bios_max_head:
	mov ax,1024
	mov cx,0FFh

calc_param_bios_ok:
	mov fs:drive_heads,cx
	mov fs:drive_cyls,ax
;
	pop fs:drive_lba_sectors
;
	popad
	ret
CalcParam	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ChsToLba
;
;		DESCRIPTION:	Convert CHS to LBA
;
;		PARAMETERS:		DS		IDE SEGMENT
;						FS		DRIVE SEGMENT
;						ES:EDI	CHS address
;
;		RETURNS:		EDX		LBA address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChsToLba	Proc near
	push eax
	push ecx
;
	mov cl,es:[edi+2]
	movzx ax,byte ptr es:[edi+1]
	and al,0C0h
	shl ax,2
	mov ch,ah
	cmp cx,1023
	je chs_to_lba_fail
;
	movzx eax,fs:drive_heads
	movzx ecx,cx
	mul ecx
	movzx ecx,byte ptr es:[edi]
	add ecx,eax
	movzx eax,fs:drive_sectors_per_cyl
	mul ecx
	movzx ecx,byte ptr es:[edi+1]
	and cl,3Fh
	add eax,ecx
	dec eax
	mov edx,eax
	jmp chs_to_lba_done

chs_to_lba_fail:
	xor edx,edx

chs_to_lba_done:
	pop ecx
	pop eax
	ret
ChsToLba	Endp

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
;						EAX		NUMBER OF SECTORS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fs_unknown	DB 'UNKNOWN '
fs_fat12	DB 'FAT12   '
fs_fat16	DB 'FAT16   '
fs_fat32	DB 'FAT32   '
fs_hpfs		DB 'HPFS    '
fs_rdfs     DB 'RDFS    '
fs_flashfs  DB 'FLASHFS '

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
fs10	DW OFFSET fs_unknown
fs11	DW OFFSET fs_unknown
fs12	DW OFFSET fs_unknown
fs13	DW OFFSET fs_unknown
fs14	DW OFFSET fs_unknown
fs15	DW OFFSET fs_unknown
fs16	DW OFFSET fs_unknown
fs17	DW OFFSET fs_unknown
fs18	DW OFFSET fs_unknown
fs19	DW OFFSET fs_unknown
fs1A	DW OFFSET fs_unknown
fs1B	DW OFFSET fs_unknown
fs1C	DW OFFSET fs_unknown
fs1D	DW OFFSET fs_unknown
fs1E	DW OFFSET fs_unknown
fs1F	DW OFFSET fs_unknown
fs20	DW OFFSET fs_unknown
fs21	DW OFFSET fs_unknown
fs22	DW OFFSET fs_unknown
fs23	DW OFFSET fs_unknown
fs24	DW OFFSET fs_unknown
fs25	DW OFFSET fs_unknown
fs26	DW OFFSET fs_unknown
fs27	DW OFFSET fs_unknown
fs28	DW OFFSET fs_unknown
fs29	DW OFFSET fs_unknown
fs2A	DW OFFSET fs_unknown
fs2B	DW OFFSET fs_unknown
fs2C	DW OFFSET fs_unknown
fs2D	DW OFFSET fs_unknown
fs2E	DW OFFSET fs_unknown
fs2F	DW OFFSET fs_unknown
fs30	DW OFFSET fs_unknown
fs31	DW OFFSET fs_unknown
fs32	DW OFFSET fs_unknown
fs33	DW OFFSET fs_unknown
fs34	DW OFFSET fs_unknown
fs35	DW OFFSET fs_unknown
fs36	DW OFFSET fs_unknown
fs37	DW OFFSET fs_unknown
fs38	DW OFFSET fs_unknown
fs39	DW OFFSET fs_unknown
fs3A	DW OFFSET fs_unknown
fs3B	DW OFFSET fs_unknown
fs3C	DW OFFSET fs_unknown
fs3D	DW OFFSET fs_unknown
fs3E	DW OFFSET fs_unknown
fs3F	DW OFFSET fs_unknown
fs40	DW OFFSET fs_unknown
fs41	DW OFFSET fs_unknown
fs42	DW OFFSET fs_unknown
fs43	DW OFFSET fs_unknown
fs44	DW OFFSET fs_unknown
fs45	DW OFFSET fs_unknown
fs46	DW OFFSET fs_unknown
fs47	DW OFFSET fs_unknown
fs48	DW OFFSET fs_unknown
fs49	DW OFFSET fs_unknown
fs4A	DW OFFSET fs_unknown
fs4B	DW OFFSET fs_unknown
fs4C	DW OFFSET fs_unknown
fs4D	DW OFFSET fs_unknown
fs4E	DW OFFSET fs_unknown
fs4F	DW OFFSET fs_unknown
fs50	DW OFFSET fs_unknown
fs51	DW OFFSET fs_unknown
fs52	DW OFFSET fs_unknown
fs53	DW OFFSET fs_unknown
fs54	DW OFFSET fs_unknown
fs55	DW OFFSET fs_unknown
fs56	DW OFFSET fs_unknown
fs57	DW OFFSET fs_unknown
fs58	DW OFFSET fs_unknown
fs59	DW OFFSET fs_unknown
fs5A	DW OFFSET fs_unknown
fs5B	DW OFFSET fs_unknown
fs5C	DW OFFSET fs_unknown
fs5D	DW OFFSET fs_unknown
fs5E	DW OFFSET fs_unknown
fs5F	DW OFFSET fs_unknown
fs60	DW OFFSET fs_unknown
fs61	DW OFFSET fs_unknown
fs62	DW OFFSET fs_unknown
fs63	DW OFFSET fs_unknown
fs64	DW OFFSET fs_unknown
fs65	DW OFFSET fs_unknown
fs66	DW OFFSET fs_unknown
fs67	DW OFFSET fs_unknown
fs68	DW OFFSET fs_unknown
fs69	DW OFFSET fs_unknown
fs6A	DW OFFSET fs_unknown
fs6B	DW OFFSET fs_unknown
fs6C	DW OFFSET fs_unknown
fs6D	DW OFFSET fs_unknown
fs6E	DW OFFSET fs_unknown
fs6F	DW OFFSET fs_unknown
fs70	DW OFFSET fs_unknown
fs71	DW OFFSET fs_unknown
fs72	DW OFFSET fs_unknown
fs73	DW OFFSET fs_unknown
fs74	DW OFFSET fs_unknown
fs75	DW OFFSET fs_unknown
fs76	DW OFFSET fs_unknown
fs77	DW OFFSET fs_unknown
fs78	DW OFFSET fs_unknown
fs79	DW OFFSET fs_unknown
fs7A	DW OFFSET fs_unknown
fs7B	DW OFFSET fs_unknown
fs7C	DW OFFSET fs_unknown
fs7D	DW OFFSET fs_unknown
fs7E	DW OFFSET fs_unknown
fs7F	DW OFFSET fs_unknown
fs80	DW OFFSET fs_unknown
fs81	DW OFFSET fs_unknown
fs82	DW OFFSET fs_unknown
fs83	DW OFFSET fs_unknown
fs84	DW OFFSET fs_unknown
fs85	DW OFFSET fs_unknown
fs86	DW OFFSET fs_unknown
fs87	DW OFFSET fs_unknown
fs88	DW OFFSET fs_unknown
fs89	DW OFFSET fs_unknown
fs8A	DW OFFSET fs_unknown
fs8B	DW OFFSET fs_unknown
fs8C	DW OFFSET fs_unknown
fs8D	DW OFFSET fs_unknown
fs8E	DW OFFSET fs_unknown
fs8F	DW OFFSET fs_unknown
fs90	DW OFFSET fs_unknown
fs91	DW OFFSET fs_unknown
fs92	DW OFFSET fs_unknown
fs93	DW OFFSET fs_unknown
fs94	DW OFFSET fs_unknown
fs95	DW OFFSET fs_unknown
fs96	DW OFFSET fs_unknown
fs97	DW OFFSET fs_unknown
fs98	DW OFFSET fs_unknown
fs99	DW OFFSET fs_unknown
fs9A	DW OFFSET fs_unknown
fs9B	DW OFFSET fs_unknown
fs9C	DW OFFSET fs_unknown
fs9D	DW OFFSET fs_unknown
fs9E	DW OFFSET fs_unknown
fs9F	DW OFFSET fs_unknown
fsA0	DW OFFSET fs_unknown
fsA1	DW OFFSET fs_unknown
fsA2	DW OFFSET fs_unknown
fsA3	DW OFFSET fs_unknown
fsA4	DW OFFSET fs_unknown
fsA5	DW OFFSET fs_unknown
fsA6	DW OFFSET fs_unknown
fsA7	DW OFFSET fs_unknown
fsA8	DW OFFSET fs_unknown
fsA9	DW OFFSET fs_unknown
fsAA	DW OFFSET fs_unknown
fsAB	DW OFFSET fs_unknown
fsAC	DW OFFSET fs_unknown
fsAD	DW OFFSET fs_unknown
fsAE	DW OFFSET fs_rdfs
fsAF	DW OFFSET fs_flashfs
fsB0	DW OFFSET fs_unknown
fsB1	DW OFFSET fs_unknown
fsB2	DW OFFSET fs_unknown
fsB3	DW OFFSET fs_unknown
fsB4	DW OFFSET fs_unknown
fsB5	DW OFFSET fs_unknown
fsB6	DW OFFSET fs_unknown
fsB7	DW OFFSET fs_unknown
fsB8	DW OFFSET fs_unknown
fsB9	DW OFFSET fs_unknown
fsBA	DW OFFSET fs_unknown
fsBB	DW OFFSET fs_unknown
fsBC	DW OFFSET fs_unknown
fsBD	DW OFFSET fs_unknown
fsBE	DW OFFSET fs_unknown
fsBF	DW OFFSET fs_unknown
fsC0	DW OFFSET fs_unknown
fsC1	DW OFFSET fs_unknown
fsC2	DW OFFSET fs_unknown
fsC3	DW OFFSET fs_unknown
fsC4	DW OFFSET fs_unknown
fsC5	DW OFFSET fs_unknown
fsC6	DW OFFSET fs_unknown
fsC7	DW OFFSET fs_unknown
fsC8	DW OFFSET fs_unknown
fsC9	DW OFFSET fs_unknown
fsCA	DW OFFSET fs_unknown
fsCB	DW OFFSET fs_unknown
fsCC	DW OFFSET fs_unknown
fsCD	DW OFFSET fs_unknown
fsCE	DW OFFSET fs_unknown
fsCF	DW OFFSET fs_unknown
fsD0	DW OFFSET fs_unknown
fsD1	DW OFFSET fs_unknown
fsD2	DW OFFSET fs_unknown
fsD3	DW OFFSET fs_unknown
fsD4	DW OFFSET fs_unknown
fsD5	DW OFFSET fs_unknown
fsD6	DW OFFSET fs_unknown
fsD7	DW OFFSET fs_unknown
fsD8	DW OFFSET fs_unknown
fsD9	DW OFFSET fs_unknown
fsDA	DW OFFSET fs_unknown
fsDB	DW OFFSET fs_unknown
fsDC	DW OFFSET fs_unknown
fsDD	DW OFFSET fs_unknown
fsDE	DW OFFSET fs_unknown
fsDF	DW OFFSET fs_unknown
fsE0	DW OFFSET fs_unknown
fsE1	DW OFFSET fs_unknown
fsE2	DW OFFSET fs_unknown
fsE3	DW OFFSET fs_unknown
fsE4	DW OFFSET fs_unknown
fsE5	DW OFFSET fs_unknown
fsE6	DW OFFSET fs_unknown
fsE7	DW OFFSET fs_unknown
fsE8	DW OFFSET fs_unknown
fsE9	DW OFFSET fs_unknown
fsEA	DW OFFSET fs_unknown
fsEB	DW OFFSET fs_unknown
fsEC	DW OFFSET fs_unknown
fsED	DW OFFSET fs_unknown
fsEE	DW OFFSET fs_unknown
fsEF	DW OFFSET fs_unknown
fsF0	DW OFFSET fs_unknown
fsF1	DW OFFSET fs_unknown
fsF2	DW OFFSET fs_unknown
fsF3	DW OFFSET fs_unknown
fsF4	DW OFFSET fs_unknown
fsF5	DW OFFSET fs_unknown
fsF6	DW OFFSET fs_unknown
fsF7	DW OFFSET fs_unknown
fsF8	DW OFFSET fs_unknown
fsF9	DW OFFSET fs_unknown
fsFA	DW OFFSET fs_unknown
fsFB	DW OFFSET fs_unknown
fsFC	DW OFFSET fs_unknown
fsFD	DW OFFSET fs_unknown
fsFE	DW OFFSET fs_unknown
fsFF	DW OFFSET fs_unknown

InstallPartition	Proc near
	push es
	pushad
;
	cmp cl,7
	jne install_check_type
;
	push eax
;
	push edx
	mov eax,200h
	AllocateSmallLinear
	mov edi,edx
	pop edx
;
	push edx
	mov eax,edx
	xor edx,edx
	movzx ecx,word ptr fs:drive_sectors_per_unit
	div ecx
	mov bx,dx
	mov edx,eax
	mov ecx,1
	call ReadDrive
	pop edx
;
	push ds
	push edx
	mov eax,10h
	AllocateSmallGlobalMem
	mov ax,flat_sel
	mov ds,ax
	mov edx,edi
	lea esi,[edi+36h]
	xor edi,edi
	movs dword ptr es:[edi],[esi]
	movs dword ptr es:[edi],[esi]
	movs dword ptr es:[edi],[esi]
	movs dword ptr es:[edi],[esi]
	xor ecx,ecx
	FreeLinear
;
	pop edx
	pop ds
;
	pop ecx
	xor di,di
	IsFileSystemAvailable
	jc install_part_free
;
	AllocateStaticDrive
	mov ah,fs:disc_nr
	OpenDrive
;
	InstallFileSystem
	clc

install_part_free:
	pushf
	FreeMem
	popf
	jmp install_part_done

install_check_type:
	mov di,cs
	mov es,di
	movzx di,cl
	shl di,1

install_part_test_avail:
	mov ecx,eax
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
	popad
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
	mov ds,fs:disc_ide_sel
	EnterSection ds:IdeSection
	mov bp,3

read_drive_retry_loop:
	ClearSignal
	GetThread
	mov ds:IdeThread,ax
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
	mov al,20h
	mov dx,fs:disc_io_base
    add dx,7
	out dx,al

read_sector_loop:
    push edx
    push eax
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
	WaitForSignalWithTimeout
	pop eax
	pop edx
;	
	mov dx,fs:disc_io_base
	call CheckStatus
	jc read_drive_retry
;
	push cx
	push edi
	mov edi,es:[edi].dh_data
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
    int 3
	mov es:[edi].dh_state,STATE_BAD
	mov bx,fs:disc_sel
	DiscRequestCompleted
;
    mov bp,3
	add esi,4
	mov edi,es:[esi]
	sub cx,1
	jnz read_drive_retry_loop
	jmp read_drive_done

read_drive_ok:
	mov eax,es:[edi].dh_data
	mov es:[edi].dh_state,STATE_USED
	mov bx,fs:disc_sel
	DiscRequestCompleted
;
	add esi,4
	mov edi,es:[esi]
	sub cx,1
	jnz read_sector_loop

read_drive_done:
	LeaveSection ds:IdeSection
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
;		PARAMETERS:		FS		Disc selector
;						ESI		Disc handle array
;						ECX		Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive	Proc near
	mov ds,fs:disc_ide_sel
	EnterSection ds:IdeSection
	mov bp,3

write_drive_retry_loop:
	ClearSignal
	GetThread
	mov ds:IdeThread,ax
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
	mov al,30h
	mov dx,fs:disc_io_base
	add dx,7
	out dx,al

write_sector_loop:
    mov dx,fs:disc_io_base
	call WaitDrq
	jc write_drive_retry
;
	push cx
	push esi
	mov esi,es:[edi].dh_data
	mov ecx,256
	rep
	db 26h
	db 67h
	outsw
	pop esi
	pop cx
;
    push edx
    push eax
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
	WaitForSignalWithTimeout
	pop eax
	pop edx
;	
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
;	
	mov bp,3
	add esi,4
	mov edi,es:[esi]
	sub cx,1
	jnz write_drive_retry_loop
	jmp write_drive_done

write_drive_ok:
	mov es:[edi].dh_state,STATE_USED
	mov bx,fs:disc_sel
	DiscRequestCompleted
;
	add esi,4
	mov edi,es:[esi]
	sub cx,1
	jnz write_sector_loop

write_drive_done:
	LeaveSection ds:IdeSection
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
	mov ax,flat_sel
	mov es,ax
;
	GetThread
	mov fs:disc_thread,ax
	mov bx,fs:disc_sel
	mov ds,fs:disc_ide_sel

discbuf_thread_loop:
	WaitForDiscRequest
	call perform_one
	jmp discbuf_thread_loop

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_TIMEOUT1
;
;		DESCRIPTION:	Install unit timeout
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_timeout1	Proc far
	push ds
	push ax
	push bx
;
	mov ax,ide_data_sel1
	mov ds,ax
	mov bx,ds:IdeThread
	Signal
;
	pop bx
	pop ax
	pop ds
	ret
install_timeout1	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_TIMEOUT2
;
;		DESCRIPTION:	Install unit timeout
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_timeout2	Proc far
	push ds
	push ax
	push bx
;
	mov ax,ide_data_sel2
	mov ds,ax
	mov bx,ds:IdeThread
	Signal
;
	pop bx
	pop ax
	pop ds
	ret
install_timeout2	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_UNIT
;
;		DESCRIPTION:	Install a unit
;
;		PARAMETERS:		AL		UNIT #
;                       DX      IO BASE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc0	DB 'Ide Drive 0',0
disc1	DB 'Ide Drive 1',0
disc2	DB 'Ide Drive 2',0
disc3	DB 'Ide Drive 3',0

disc_name_tab1:
dnt100	DW OFFSET disc0
dnt101	DW OFFSET disc1

disc_name_tab2:
dnt200	DW OFFSET disc2
dnt201	DW OFFSET disc3

install_unit	Proc near
    mov ds:IntFlag,0
	ClearSignal
	call CheckReady
	jc install_unit_done
;
	cmp dx,1F0h
	je inst_timeout_primary
;	
	mov di,OFFSET install_timeout2
	jmp inst_timeout_start

inst_timeout_primary:	
	mov di,OFFSET install_timeout1

inst_timeout_start:
	push ax
    push dx
	GetSystemTime
	add eax,119300
	adc edx,0
	mov bx,cs
	mov es,bx
	mov bx,cs
	StartTimer
	pop dx
	pop ax
;
	push ax
;
    push dx
    add dx,6
	shl al,4
	or al,0A0h
	out dx,al
	inc dx
;
	jmp short $+2
	mov al,0ECh
	out dx,al
	pop dx
;
	WaitForSignal
	StopTimer
	pop ax
;
	push ax
	mov cx,256
	
install_unit_read:
	in ax,dx
	loop install_unit_read
;
    mov al,ds:IntFlag
    or al,al
    stc
    jz install_unit_check_done
;    	
	call CheckStatus

install_unit_check_done:
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
	mov fs:disc_io_base,dx
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
	mov fs:disc_ide_sel,ds
;
	call CalcParam
	mov ax,fs:drive_sectors_per_unit
	mov dx,fs:drive_units
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
	movzx di,fs:disc_sub_unit
	add di,di
	mov dx,fs:disc_io_base
	cmp dx,1F0h
	je install_primary
;	
	mov di,word ptr cs:[di].disc_name_tab2
	jmp install_cr_thread

install_primary:	
	mov di,word ptr cs:[di].disc_name_tab1

install_cr_thread:
	mov si,OFFSET discbuf_thread
	mov ax,2
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
;		NAME:			DISC_ASSIGN1
;
;		DESCRIPTION:	Assign discs on primary adapter
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_assign1	Proc far
    mov dx,1F7h
    in al,dx
    and al,7Fh
    cmp al,7Fh
    je disc_assign1_done
;    
	mov ax,ide_data_sel1
	mov ds,ax
	GetThread
	mov ds:IdeThread,ax
;	
	mov al,0
	mov dx,1F0h
	call install_unit
;	
	mov al,1
	mov dx,1F0h
	call install_unit
	mov ds:IdeThread,0

disc_assign1_done:
	ret
disc_assign1	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DISC_ASSIGN2
;
;		DESCRIPTION:	Assign discs
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_assign2	Proc far
    mov dx,177h
    in al,dx
    and al,7Fh
    cmp al,7Fh
    je disc_assign2_done
;    
	mov ax,ide_data_sel2
	mov ds,ax
	GetThread
	mov ds:IdeThread,ax
;	    
	mov al,0
	mov dx,170h
	call install_unit
;	
	mov al,1
	mov dx,170h
	call install_unit
	mov ds:IdeThread,0

disc_assign2_done:
	ret
disc_assign2	Endp

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
	mov fs,bx
	mov ds,fs:disc_ide_sel
;
	mov ax,flat_sel
	mov es,ax
	mov eax,200h
	AllocateSmallLinear
	mov edi,edx
;
	mov ecx,1
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
	mov eax,es:[esi+edi].part_sectors
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
	mov ecx,1
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
	push edi
;
	mov eax,es:[esi+edi].part_sectors
	lea edi,[esi+edi+1]
	call ChsToLba
	or edx,edx
	jnz install_ext_do
;
	mov edx,es:[edi+7]
	add edx,ebp

install_ext_do:
	call InstallPartition
	pop edi
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
;
	lea edi,[esi+edi+1]
	call ChsToLba
	or edx,edx
	jnz install_ext_link
;
	mov edx,es:[edi+7]
	add edx,ebp

install_ext_link:
	call InstallExtended
;
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
	mov ax,flat_sel
	mov es,ax
	mov fs,bx
	mov ds,fs:disc_ide_sel
;
	mov eax,200h
	AllocateSmallLinear
	mov edi,edx
;
	mov ecx,1
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
;
	lea edi,[esi+edi+1]
	call ChsToLba
	or edx,edx
	jnz drive_assign_ext
;
	mov edx,es:[edi+7]

drive_assign_ext:
	call InstallExtended
;
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
;		NAME:			ERASE
;
;		DESCRIPTION:	Erase sectors
;
;		PARAMETERS:		BX		Disc handle
;                       EDX     Start sector
;                       ECX     Number of sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

erase	Proc far
	stc
	ret
erase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetIdeDisc
;
;		description:	Get disc # for a physical disc unit
;
;		PARAMETERS:		BL          IDE disc #
;
;       RETURNS:        AL          disc #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ide_disc_name DB 'Get IDE Disc',0

get_ide_disc	Proc far
    push ds
    push bx
;
    cmp bl,2
    jae get_ide_second
;    
    mov ax,ide_data_sel1
	verr ax
	jnz get_ide_fail
;
    mov ds,ax
    movzx bx,bl
    add bx,bx
    mov bx,ds:[bx].DriveSelArr
    or bx,bx
    jz get_ide_fail
;
    mov ds,bx
    mov al,ds:disc_nr
    clc
    jmp get_ide_done

get_ide_second:
    sub bl,2
    cmp bl,2
    jae get_ide_fail
;    
    mov ax,ide_data_sel2
	verr ax
	jnz get_ide_fail
;
    mov ds,ax
    movzx bx,bl
    add bx,bx
    mov bx,ds:[bx].DriveSelArr
    or bx,bx
    jz get_ide_fail
;
    mov ds,bx
    mov al,ds:disc_nr
    clc
    jmp get_ide_done

get_ide_fail:
    stc
    
get_ide_done:    
    pop bx
    pop ds    
	retf32
get_ide_disc	Endp

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

disc_ctrl1:
dct100	DW OFFSET disc_assign1,		ide_code_sel
dct101	DW OFFSET drive_assign1,	ide_code_sel
dct102	DW OFFSET drive_assign2,	ide_code_sel
dct103	DW OFFSET demand_mount,		ide_code_sel
dct104  DW OFFSET erase,            ide_code_sel

disc_ctrl2:
dct200	DW OFFSET disc_assign2,		ide_code_sel
dct201	DW OFFSET drive_assign1,	ide_code_sel
dct202	DW OFFSET drive_assign2,	ide_code_sel
dct203	DW OFFSET demand_mount,		ide_code_sel
dct204  DW OFFSET erase,            ide_code_sel

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
	mov si,OFFSET get_ide_disc
	mov di,OFFSET get_ide_disc_name
	xor dx,dx
	mov ax,get_ide_disc_nr
	RegisterBimodalUserGate

init_ide_primary:
	mov dx,1F7h
	in al,dx
	and al,7Fh
	cmp al,7Fh
	je init_ide_second
;
	mov di,OFFSET disc_ctrl1
	HookInitDisc
;
	mov eax,SIZE ide_data
	mov bx,ide_data_sel1
	AllocateFixedSystemMem
	InitSection es:IdeSection
	mov es:IdeThread,0
	mov es:DriveSelArr,0
	mov es:DriveSelArr+2,0
;
	mov al,0Eh
	mov bx,ide_data_sel1
	mov ds,bx
	mov bx,cs
	mov es,bx
	mov di,OFFSET ide_int
	RequestPrivateIrqHandler

init_ide_second:
    mov dx,177h
    in al,dx
    and al,7Fh
    cmp al,7Fh
	je init_ide_done
;
	mov di,OFFSET disc_ctrl2
	HookInitDisc
;
	mov eax,SIZE ide_data
	mov bx,ide_data_sel2
	AllocateFixedSystemMem
	InitSection es:IdeSection
	mov es:IdeThread,0
	mov es:DriveSelArr,0
	mov es:DriveSelArr+2,0
;
	mov al,0Fh
	mov bx,ide_data_sel2
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

