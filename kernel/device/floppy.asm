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
; FLOPPY.ASM
; Floppy disk driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  floppy

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
INCLUDE ..\os\port.def
INCLUDE ..\os\drive.inc

boot_struc	STRUC

boot_jmp					DB ?,?,?
boot_name					DB 8 DUP(?)
boot_bytes_per_sector		DW ?
boot_sectors_per_cluster	DB ?
boot_resv_sectors			DW ?
boot_fats					DB ?
boot_root_dirs				DW ?
boot_sectors				DW ?
boot_media					DB ?
boot_fat_sectors			DW ?
boot_sectors_per_cyl		DW ?
boot_heads					DW ?
boot_hidden_sectors			DD ?
boot_big_sectors			DD ?
boot_drive_nr				DB ?,?
boot_signature				DB ?
boot_serial					DD ?
boot_volume					DB 11 DUP(?)
boot_fs						DB 8 DUP(?)

disc_fs_handle				DW ?
disc_sel					DW ?
disc_thread					DW ?
disc_sub_unit				DB ?
disc_nr						DB ?

boot_struc		ENDS

MotorOnWait		EQU 500
Spec1			EQU 0DFh
Spec2			EQU 2

floppy_data    SEGMENT AT 0

FloppyIntList	DW ?

DriveControl	DB ?
IntFlag			DB ?
TimeoutCount	DB ?
Gap			  	DB 4 DUP(?)
Tracks			DB 4 DUP(?)
MotorCount		DB 4 DUP(?)

CmdCode			DB ?
DriveHead		DB ?
cTrack			DB ?
cDriveHead		DB ?
cSector			DB ?
cBytesPerSector	DB ?
cTracks			DB ?
cGap			DB ?
cDataLen		DB ?

st0				DB ?
st1				DB ?
st2				DB ?
sTrack			DB ?
sHead			DB ?
sSector			DB ?
sBytesPerSector	DB ?

FloppySection	section_typ <>

floppy_data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

	assume cs:code
    assume ds:floppy_data


.386c

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOPPY_INT
;
;		DESCRIPTION:	Floppy disk interrupt
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

floppy_int	Proc far
	mov al,IntFlag
	or al,al
	jnz floppy_int_done
	inc al
	mov IntFlag,al
	mov si,OFFSET FloppyIntList
	Wake
floppy_int_done:
	ret
floppy_int	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CommandPhase
;
;		DESCRIPTION:	Execute command phase
;
;		PARAMETERS:		CX		Number of bytes to output
;
;		RETURNS:		NC		Performed ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CommandPhase	Proc near
	push ax
	push bx
    push dx
	push si
	mov IntFlag,0
	mov si,2000
	mov bx,OFFSET CmdCode
CommandPhaseLoop:
	push cx
	xor cx,cx
CommandPhaseReqLoop:
	mov dx,3F4h
	in al,dx
	test al,80h
	jnz CommandPhaseReqSet
	mov ax,50
	WaitMicroSec
	sub si,1
	jnc CommandPhaseReqLoop
	pop cx
	jmp CommandPhaseDone
CommandPhaseReqSet:
    pop cx
	test al,40h
	stc
	jnz	CommandPhaseDone
;
    mov dx,3F5h
	mov al,[bx]
	inc bx
	out dx,al			; output data byte
	loop CommandPhaseLoop
	mov ax,30
	WaitMicroSec
	clc
CommandPhaseDone:
	pop si
	pop dx
	pop bx
	pop ax
	ret
CommandPhase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ExecutePhase
;
;		DESCRIPTION:	Wait for execute phase to be ready
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExecutePhase   Proc near
	push es
	push ax
	push dx
	push di
	mov dx,ds
	mov es,dx
    mov dx,3F4h
	in al,dx
	test al,10h
	clc
	jz ExecutePhaseDone
	test al,80h
	clc
	jnz ExecutePhaseDone
	mov di,OFFSET FloppyIntList
	cli
	mov al,IntFlag
	or al,al
	clc
	jnz ExecutePhaseDone
	mov TimeoutCount,20
	Sleep
	sti
	mov al,IntFlag
	or al,al
	clc
	jnz ExecutePhaseDone
	stc
ExecutePhaseDone:
	sti
	pop di
	pop dx
	pop ax
	pop es
	ret
ExecutePhase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ResultPhase
;
;		DESCRIPTION:	Execute result phase
;
;		RETURNS:		NC		Performed ok
;						CX		Number of bytes in result 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResultPhase   Proc near
	push ax
	push bx
    push dx
	push si
	mov si,200
	xor cx,cx
	mov bx,OFFSET st0
ResultPhaseLoop:
	mov dx,3F4h
	in al,dx
	test al,10h
	clc
	jz ResultPhaseDone	
	test al,80h
	jnz ResultPhaseReqSet
	mov ax,50
	WaitMicroSec
	sub si,1
	jnc ResultPhaseLoop
	jmp ResultPhaseDone
ResultPhaseReqSet:
    test al,40h
	stc
    jz ResultPhaseDone
	inc cx
    mov dx,3F5h
	in al,dx
	mov [bx],al
	inc bx
	jmp ResultPhaseLoop
ResultPhaseDone:
	pop si
    pop dx
	pop bx
	pop ax
    ret
ResultPhase   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RecoverPhase
;
;		DESCRIPTION:	Set controller in idle state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecoverPhase	Proc near
	push ax
    push dx
	push si
	mov si,200
RecoverPhaseLoop:
	mov dx,3F4h
	in al,dx
	test al,10h
	jz RecoverPhaseDone
	test al,80h
	jnz RecoverPhaseReqSet
	mov ax,50
	WaitMicroSec
	sub si,1
	jnc RecoverPhaseLoop
	jmp RecoverPhaseDone
RecoverPhaseReqSet:
	test al,40h
	jnz	RecoverPhaseRead
RecoverPhaseWrite:
    mov dx,3F5h
	mov al,0FFh
	out dx,al
	jmp RecoverPhaseLoop
RecoverPhaseRead:
	mov dx,3F5h
	in al,dx
	jmp RecoverPhaseLoop
RecoverPhaseDone:
	pop si
	pop dx
	pop ax
	ret
RecoverPhase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DecodeStatus
;
;		DESCRIPTION:	Decode status of previous operation
;
;		RETURNS:		NC      Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeStatus	Proc near
	push ax
	mov al,st0
    test al,0C0h
	clc
	jz DecodeStatusDone
	stc
DecodeStatusDone:
	pop ax
    ret
DecodeStatus	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Command
;
;		DESCRIPTION:	Execute command
;
;		PARAMETERS:		CX		Number of bytes to output
;
;		RETURNS:		NC		Performed ok
;						CX		Number of bytes in answer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Command   Proc near
	call CommandPhase
	jc CommandDone
	call ExecutePhase
	jc CommandDone
	call ResultPhase
	jc CommandDone
	or cx,cx
	clc
	je CommandDone
	call DecodeStatus
CommandDone:
    ret
Command   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SenseIntCmd
;
;		DESCRIPTION:	Sense interrupt command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SenseIntCmd	Proc near
	push ax
	push cx
	mov ax,10
	WaitMilliSec
	mov CmdCode,8
	mov cx,1
	call CommandPhase
	jc SenseIntDone
	call ResultPhase
SenseIntDone:
	pop cx
	pop ax
	ret
SenseIntCmd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ExecuteSensePhase
;
;		DESCRIPTION:	Execute phase using sense int command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExecuteSensePhase   Proc near
	push es
	push ax
	push di
	mov ax,ds
	mov es,ax
	mov di,OFFSET FloppyIntList
	cli
	mov al,IntFlag
	or al,al
	clc
	jnz ExecuteSenseCmd
	mov TimeoutCount,20
	Sleep
	sti
	mov al,IntFlag
	or al,al
	stc
	jz ExecuteSenseDone
ExecuteSenseCmd:
	sti
	call SenseIntCmd
ExecuteSenseDone:
	pop di
	pop ax
	pop es
	ret
ExecuteSensePhase	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SenseDriveStatusCmd
;
;		DESCRIPTION:	Sense drive status command
;
;		PARAMETERS:		AL		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SenseDriveStatusCmd	Proc near
	push bx
	push cx
	mov bx,OFFSET CmdCode
	mov byte ptr [bx],4
	mov [bx+1],al
	mov cx,2
	call CommandPhase
	jc SenseDriveStatusDone
	call ResultPhase
SenseDriveStatusDone:
	pop cx
	pop bx
	ret
SenseDriveStatusCmd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SpecifyCmd
;
;		DESCRIPTION:	Specify command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SpecifyCmd	Proc near
	push bx
	push cx
	mov bx,OFFSET CmdCode
	mov byte ptr [bx],3
	mov byte ptr [bx+1],Spec1
	mov byte ptr [bx+2],Spec2
	mov cx,3
	call Command
	pop cx
	pop bx
	ret
SpecifyCmd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RecalibrateCmd
;
;		DESCRIPTION:	Recalibrate command
;
;		PARAMETERS:		AL		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecalibrateCmd	Proc near
	push cx
	mov CmdCode,7
	mov DriveHead,al
	mov cx,2
	call Command
	jc RecalibrateDone
	call SenseIntCmd
RecalibrateDone:
	pop cx
	ret
RecalibrateCmd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadIdCmd
;
;		DESCRIPTION:	Read drive ID command
;
;		PARAMETERS:		AL		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadIdCmd	Proc near
	push cx
	mov CmdCode,4Ah
	mov DriveHead,al
	mov cx,2
	call Command
	mov cl,sBytesPerSector
	mov cBytesPerSector,cl
	pop cx
	ret
ReadIdCmd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ResetController
;
;		DESCRIPTION:	ResetController
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetController	Proc near
	push es
	push ax
	push cx
	push dx
	push di
	mov ax,ds
	mov es,ax
	mov cx,100
	mov cTrack,-1
ResetControllerLoop:
	mov di,OFFSET FloppyIntList
	cli
	mov IntFlag,0
	mov al,8
	mov dx,3F2h
	out dx,al
	sti
	mov ax,250
	WaitMicroSec
;
	mov al,0Ch
    mov dx,3F2h
    out dx,al
	mov DriveControl,al
;
	mov al,IntFlag
	or al,al
	jnz ResetControllerStart
	mov TimeoutCount,20
	Sleep
	mov al,IntFlag
	or al,al
	jz ResetControllerFailed
ResetControllerStart:
	mov al,0Ch
	out dx,al
	mov DriveControl,al
ResetControllerSense:
	call SenseIntCmd
	jc ResetControllerFailed
	call SpecifyCmd
	jnc ResetControllerDone
ResetControllerFailed:
	mov ax,250
	WaitMicroSec
	call RecoverPhase
	call SenseIntCmd
	mov ax,10
	WaitMilliSec
	loop ResetControllerLoop
	stc
ResetControllerDone:
	pop di
	pop dx
	pop cx
	pop ax
	pop es
	ret
ResetController	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TestDrive
;
;		DESCRIPTION:	Test drive with a specified data rate
;
;		PARAMETERS:		AL		Drive #
;						AH		Data rate
;
;		RETURNS:		NC		Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TestDrive   Proc near
	push ax
	push cx
	push dx
;
	xchg al,ah
    mov dx,3F7h
    out dx,al
	xchg al,ah
;
	call RecalibrateCmd
	jnc TestDriveStart
	call RecalibrateCmd
	jc TestDriveDone
TestDriveStart:
	mov cx,3
TestDriveLoop:
	call ReadIdCmd
	jnc TestDriveDone
    loop TestDriveLoop
	stc
TestDriveDone:
	pop dx
	pop cx
	pop ax
    ret
TestDrive   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitDrive
;
;		DESCRIPTION:	Init drive and setup data rate
;
;		PARAMETERS:		AL		Drive #
;
;		RETURNS:		NC		Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitDrive	Proc near
	push ax
	push bx
	movzx bx,al
;
	call TestDrive
	mov al,7
	mov ah,18
	jnc InitDriveOk
;
    mov ah,1
    call TestDrive
    mov al,4
	mov ah,42
    jnc InitDriveOk
;
    mov ah,2
    call TestDrive
    mov al,7
	mov ah,35
    jnc InitDriveOk
;
    mov ah,3
    call TestDrive
    mov al,7
	mov ah,27
	jnc InitDriveOk
	xor al,al
	stc
InitDriveOk:
	mov [bx].Gap,al
	mov [bx].Tracks,ah
	pop bx
	pop ax
	ret
InitDrive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SelectDrive
;
;		DESCRIPTION:	Set current drive
;
;		PARAMETERS:		AL		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SelectDrive	Proc near
	push ax
	push bx
	push cx
	push dx
	movzx bx,al
	mov cl,al
	mov ah,10h
	rol ah,cl
	cli
	mov al,DriveControl
	test al,ah
	jnz SelectDriveMotorOn
	sti
	call ResetController
	jc SelectDriveDone
	cli
	mov [bx].MotorCount,255
	mov al,DriveControl
	and al,0F0h
	or al,ah
	or al,DriveControl		
	mov DriveControl,al
    mov dx,3F2h
    out dx,al
	sti
	mov ax,MotorOnWait
	WaitMilliSec
	mov al,DriveControl
	jmp SelectDriveInit
SelectDriveMotorOn:
	cli
	mov al,DriveControl
	mov ah,al
	and ah,3
	cmp ah,cl
	clc
	je SelectDriveDone
SelectDriveInit:
	and al,NOT 3
	or al,cl
    mov dx,3F2h
    out dx,al
	mov DriveControl,al
	sti
	mov ax,100
	WaitMicroSec
	mov al,[bx].Gap
	or al,al
	mov al,bl
	jnz SelectDriveRecal
	call InitDrive
	jc SelectDriveDone
SelectDriveRecal:
	mov ax,100
	WaitMilliSec
	mov al,bl
	call RecalibrateCmd
	jnc SelectDriveDone
	call RecalibrateCmd
SelectDriveDone:
	sti
	mov [bx].MotorCount,25
	pop dx
	pop cx
	pop bx
	pop ax
	ret
SelectDrive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetupDMA
;
;		DESCRIPTION:	Setup DMA controller
;
;		PARAMETERS:		AL		Mode
;								42h = Verify
;								46h = Read
;								4Ah = Write
;						EBX		Linear Address (must be within same page)
;						CX		Number of bytes to transfer
;
;		RETURNS:		NC		Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDMA	Proc near
    push ax
	push edx
;
	mov edx,ebx
	push es
	push eax
	mov ax,flat_sel
	mov es,ax
	mov al,es:[edx]
	GetPhysicalPage
	and ax,0F000h
	and dx,0FFFh
	or ax,dx
	mov edx,eax
	pop eax
	pop es
    cli
    out 0Ch,al
    jcxz short $+2
    jcxz short $+2
    out 0Bh,al
    jcxz short $+2
    jcxz short $+2
	dec cx
    mov al,cl
    out 5,al
    jcxz short $+2
    jcxz short $+2
    mov al,ch
    out 5,al
    jcxz short $+2
    jcxz short $+2
	inc cx
    mov al,dl
    out 4,al
    jcxz short $+2
    jcxz short $+2
    mov al,dh
    out 4,al
    jcxz short $+2
    jcxz short $+2
	shr edx,16
	mov al,dl
    out 81h,al
    jcxz short $+2
    jcxz short $+2
    mov al,2
	out 0Ah,al
    sti
	pop edx
    pop ax
    ret
SetupDMA	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SeekCmd
;
;		DESCRIPTION:	Seek to track
;
;		PARAMETERS:		AL		Drive #
;						AH		Cylinder #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SeekCmd	Proc near
	push cx
	mov CmdCode,0Fh
	mov DriveHead,al
	mov cTrack,ah
	mov cx,3
	call CommandPhase
	jc SeekDone
	call ExecuteSensePhase
SeekDone:
	pop cx
	ret
SeekCmd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadCmd
;
;		DESCRIPTION:	Read sectors
;
;		PARAMETERS:		AL		Drive #
;						DH		Head #
;						DL		Sector
;						AH		Cylinder
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCmd	Proc near
	push bx
	push cx
	movzx bx,al
	mov CmdCode,0E6h
	mov cTrack,ah
	mov cDriveHead,dh
	mov cSector,dl
	mov cl,dh
	shl cl,2
	or cl,al
	mov DriveHead,cl
    mov cl,[bx].Gap
	mov cGap,bl
	mov cl,[bx].Tracks
	mov cTracks,cl
	mov cDataLen,0FFh
	mov cx,9
	call Command
	pop cx
	pop bx
	ret
ReadCmd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteCmd
;
;		DESCRIPTION:	Write sectors
;
;		PARAMETERS:		AL		Drive #
;						DH		Head #
;						DL		Sector
;						AH		Cylinder #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCmd	Proc near
	push bx
	push cx
	movzx bx,al
	mov CmdCode,0C5h
	mov cTrack,ah
	mov cDriveHead,dh
	mov cSector,dl
	mov cl,dh
	shl cl,2
	or cl,al
	mov DriveHead,cl
    mov cl,[bx].Gap
	mov cGap,bl
	mov cl,[bx].Tracks
	mov cTracks,cl
	mov cDataLen,0FFh
	mov cx,9
	call Command
	pop cx
	pop bx
	ret
WriteCmd	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadDrive
;
;		DESCRIPTION:	Read sectors
;
;		PARAMETERS:		AL		Drive #
;						CX		Number of bytes
;						EBX		Logical address of buffer
;						AH		Cylinder #
;						DL		Sector
;						DH		Head
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadDrive	Proc near
	EnterSection FloppySection
	push si
	mov si,3
	call SelectDrive
	jc ReadDriveRetry
	cmp ah,cTrack
	je ReadDriveSetup
ReadDriveLoop:
	call SeekCmd
	jc ReadDriveRetry
ReadDriveSetup:
	push ax
	mov al,46h
	call SetupDMA
	pop ax
	call ReadCmd
	jnc ReadDriveDone
ReadDriveRetry:
	push ax
	push dx
	cli
	mov al,0Ch
	mov DriveControl,al
	mov dx,3F2h
	out dx,al
	sti
	pop dx
	pop ax
	sub si,1
	jc ReadDriveDone
	call SelectDrive
	jc ReadDriveRetry
	push ax
	mov ax,250
	WaitMilliSec
	pop ax
	jmp ReadDriveLoop
ReadDriveDone:
	pushf
	LeaveSection FloppySection
	popf
	pop si
	ret
ReadDrive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteDrive
;
;		DESCRIPTION:	Write sectors
;
;		PARAMETERS:		AL		Drive #
;						CX		Number of bytes
;						EBX		Logical address of buffer
;						AH		Cylinder #
;						DL		Sector
;						DH		Head
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDrive	Proc near
	EnterSection FloppySection
	push si
	mov si,3
	call SelectDrive
	jc WriteDriveRetry
	cmp ah,cTrack
	je WriteDriveSetup
WriteDriveLoop:
	call SeekCmd
	jc WriteDriveRetry
WriteDriveSetup:
	push ax
	mov al,4Ah
	call SetupDMA
	pop ax
	call WriteCmd
	jnc WriteDriveDone
WriteDriveRetry:
	push ax
	push dx
	cli
	mov al,0Ch
	mov DriveControl,al
	mov dx,3F2h
	out dx,al
	sti
	pop dx
	pop ax
	sub si,1
	jc WriteDriveDone
	call SelectDrive
	jc WriteDriveRetry
	push ax
	mov ax,250
	WaitMilliSec
	pop ax
	jmp WriteDriveLoop
WriteDriveDone:
	pushf
	LeaveSection FloppySection
	popf
	pop si
	ret
WriteDrive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDriveParam
;
;		DESCRIPTION:	Get boot-record and drive parameters
;
;		PARAMETERS:		AL		Sub-unit #
;						AH		Disc #
;						ES		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDriveParam	Proc near
	push ds
	push ax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	push ax
	mov ax,floppy_data_sel
	mov ds,ax
	mov eax,1000h
	AllocateBigLinear
	pop ax
	mov ebx,edx
	mov dh,0
	mov dl,1
	mov ah,0
	mov cx,200h
	call ReadDrive
	mov edx,ebx
	jc get_drive_param_done
;
	mov cx,flat_sel
	mov ds,cx
	mov esi,edx
	xor edi,edi
	mov ecx,OFFSET disc_fs_handle
	rep movs byte ptr es:[edi],[esi]
	mov cx,floppy_data_sel
	mov ds,cx
	movzx bx,al
	mov es:boot_drive_nr,al
	mov cl,ds:cBytesPerSector
	mov ax,80h
	shl ax,cl
	cmp ax,es:boot_bytes_per_sector
	stc
	jne get_drive_param_done
;
	mov ax,es:boot_sectors_per_cyl
	mov ds:[bx].Tracks,al
	clc
get_drive_param_done:
	pushf
	mov ecx,1000h
	FreeLinear
	popf
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ax
	pop ds
	ret
GetDriveParam	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InstallMain
;
;		DESCRIPTION:	Install main drive
;
;		PARAMETERS:		AL		Sub-unit #
;						AH		Disc #
;						ES		Boot sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat12	DB 'FAT12   '

InstallMain	Proc near
	push es
	push ax
	push bx
	push cx
	push edx
	push di
;
	mov bx,es
	xor edx,edx
	OpenDrive
;
	mov cl,es:boot_media
	cmp cl,0F0h
	je install_main_fat12
	mov di,OFFSET boot_fs
	jmp install_main_fs
install_main_fat12:
	mov cx,cs
	mov es,cx
	mov di,OFFSET fat12
install_main_fs:
	InstallFileSystem
	clc
;
	pop di
	pop edx
	pop cx
	pop bx
	pop ax
	pop es
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
;		PARAMETERS:		AL		Sub-unit #
;						AH		Disc #
;						ES		Disc handle
;					
;		RETURNS:		AX		Sectors / unit
;						CX		Bytes / sector
;						EDX		Units
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_drive	Proc near
	call GetDriveParam
	jc open_drive_done
;
	call InstallMain
	mov ax,es:boot_sectors_per_cyl
	mul es:boot_heads
	mov cx,es:boot_bytes_per_sector
	mov edx,80
	clc

open_drive_done:
	ret
open_drive	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			check_media
;
;		DESCRIPTION:	Check for media change
;
;		PARAMETERS:		FS		Disc selector
;
;		RETURNS:		AX      Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_media	Proc near
	push ax
	push bx
	push dx
;
	mov al,fs:boot_drive_nr
	mov bx,floppy_data_sel
	mov ds,bx
	EnterSection FloppySection
	movzx bx,al
	mov bl,[bx].Gap
	or bl,bl
	stc
	jz check_media_done
	call SelectDrive
	jc check_media_done
    mov dx,3F7h
    in al,dx
    shl al,1
check_media_done:
	clc
	pushf
	LeaveSection FloppySection
	popf
	pop dx
	pop bx
	pop ax
	ret
check_media	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOPPY_SUPER
;
;		DESCRIPTION:	Supervisor thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

floppy_super_name	DB 'Floppy Supervisor',0

floppy_super:
	mov ax,floppy_data_sel
	mov ds,ax
floppy_super_loop:
	xor bx,bx
	mov cx,4
	mov ah,NOT 10h
floppy_super_motor_loop:
	cli
	mov al,[bx].MotorCount
	or al,al
	jz floppy_super_motor_next
	sub al,1
	mov [bx].MotorCount,al
	sti
	jnz floppy_super_motor_next
	cli
	mov al,DriveControl
	and al,ah
	mov dx,3F2h
	mov al,0
	out dx,al
	mov DriveControl,al
floppy_super_motor_next:
	sti
	inc bx
	shl ah,1
	loop floppy_super_motor_loop
;
	mov si,OFFSET FloppyIntList
	mov ax,[si]
	or ax,ax
	jz floppy_super_wait
	cli
	mov al,IntFlag
	or al,al
	jnz floppy_super_wake
	mov al,TimeoutCount
	sub al,1
	mov TimeoutCount,al
	jnz floppy_super_wait
floppy_super_wake:
	Wake
floppy_super_wait:
	sti
	mov ax,100
	WaitMilliSec
	jmp floppy_super_loop

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
	int 3
	mov ax,fs
	mov es,ax
	mov ax,floppy_data_sel
	mov ds,ax
	mov al,es:disc_sub_unit
	mov ah,es:disc_nr
	call open_drive
	jc discinit_thread_done
;
	mov bx,es:disc_sel
	FlushDisc
;
	mov bx,es:disc_thread
	Signal

discinit_thread_done:
	ret
discinit_thread	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_drive
;
;		DESCRIPTION:	Read drive
;
;		PARAMETERS:		FS		Disc selector
;						EDI		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_drive	Proc near
	push cx
	mov cx,3

read_drive_loop:
	push eax
	push cx
	push edx
	push edi
;
	movzx eax,es:[edi].dh_sector
	movzx edx,es:[edi].dh_unit
	mov edi,es:[edi].dh_data
;
	div byte ptr fs:boot_sectors_per_cyl
	mov dh,al
	xchg ah,dl
	inc dl
	mov al,fs:boot_drive_nr
;
	mov bx,floppy_data_sel
	mov ds,bx
	mov cx,200h
	mov ebx,edi
	call ReadDrive
;
	pop edi
	pop edx
	pop cx
	pop eax
	jnc read_drive_ok
;
	call check_media
	jc read_drive_done
;
	loop read_drive_loop
;
	mov es:[edi].dh_state,STATE_BAD
	stc
	jmp read_drive_done

read_drive_ok:
	mov es:[edi].dh_state,STATE_USED

read_drive_done:
	pop cx
	ret
read_drive	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_drive
;
;		DESCRIPTION:	Perform a write request
;
;		PARAMETERS:		DS		Disc selector
;						EDI		Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive	Proc near
	mov es:[edi].dh_state,STATE_USED
	push cx
;
	or dx,dx
	jnz write_drive_do
;
	or ax,ax
	jnz write_drive_do
;
	int 3
	stc
	jmp write_drive_done

write_drive_do:
	mov cx,3

write_drive_loop:
	push eax
	push cx
	push edx
	push edi
;
	movzx eax,es:[edi].dh_sector
	movzx edx,es:[edi].dh_unit
	mov edi,es:[edi].dh_data
;
	div byte ptr fs:boot_sectors_per_cyl
	mov dh,al
	xchg ah,dl
	inc dl
	mov al,fs:boot_drive_nr
;
	mov bx,floppy_data_sel
	mov ds,bx
	mov cx,200h
	mov ebx,edi
	call WriteDrive
;
	pop edi
	pop edx
	pop cx
	pop eax
	jnc write_drive_done
;
	call check_media
	jc write_drive_done
;
	loop write_drive_loop
;
	stc

write_drive_done:
	pop cx
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
	GetDiscRequest
	jc perform_one_done
;
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
	call check_media
	jc perform_one_fail
;
	call write_drive
	jmp perform_one_completed

perform_one_read:
	call check_media
	jc perform_one_done
;
	call read_drive

perform_one_completed:
	DiscRequestCompleted
	jmp perform_one_loop

perform_one_fail:
	DiscRequestCompleted
	FlushDisc

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
	int 3
	mov ax,floppy_data_sel
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INSTALL_UNIT
;
;		DESCRIPTION:	Install a disk unit
;
;		PARAMETERS:		AL		UNIT #
;						DI		NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_unit	Proc near
	push ax
	mov eax,SIZE boot_struc
	AllocateSmallGlobalMem
	mov bx,es
	mov fs,bx
	pop ax
	mov fs:disc_sub_unit,al
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET discbuf_thread
	mov ax,4
	mov cx,100h
	CreateThread
	ret
install_unit	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_DISC
;
;		DESCRIPTION:	Init disc callbacks
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

floppy0	DB 'Floppy Drive 0',0
floppy1	DB 'Floppy Drive 1',0

init_disc	Proc far
	int 3
	in al,INT0_MASK
	and al,NOT 40h
	out INT0_MASK,al
;
	mov ax,floppy_data_sel
	mov ds,ax
	call ResetController
;
	mov al,0
	mov di,OFFSET floppy0
	call install_unit
	mov al,1
	mov di,OFFSET floppy1
;	call install_unit
	ret
init_disc	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_FLOPPY
;
;		DESCRIPTION:	Init local threads
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_floppy	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET floppy_super
	mov di,OFFSET floppy_super_name
	mov ax,4
	mov cx,256
	CreateThread
;
	popa
	pop es
	pop ds	
	ret
init_floppy	Endp

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
	mov bx,floppy_code_sel
	InitDevice
;
	mov al,0
	AllocateFixedDrive
	mov al,1
	AllocateFixedDrive
;
	mov dx,3F4h
	in al,dx
	cmp al,-1
	je init_floppy_done
;
	mov eax,SIZE floppy_data
	mov bx,floppy_data_sel
	AllocateFixedSystemMem
	xor di,di
	mov cx,ax
	xor al,al
	rep stosb
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_floppy
	HookInitTasking
;
	mov di,OFFSET init_disc
	HookInitDisc
;
	mov al,6
	mov bx,floppy_data_sel
	mov ds,bx
	mov bx,cs
	mov es,bx
	mov di,OFFSET floppy_int
	RequestPrivateIrqHandler
;
init_floppy_done:
	popa
	pop es
	pop ds
	ret
init	ENDP


code ENDS

END init


