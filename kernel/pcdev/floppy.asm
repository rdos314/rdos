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
; FLOPPY.ASM
; Floppy disk driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\drive.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\core.inc

boot_struc      STRUC

boot_jmp                    DB ?,?,?
boot_name                       DB 8 DUP(?)
boot_bytes_per_sector       DW ?
boot_sectors_per_cluster    DB ?
boot_resv_sectors               DW ?
boot_fats                       DB ?
boot_root_dirs              DW ?
boot_sectors                DW ?
boot_media                      DB ?
boot_fat_sectors            DW ?
boot_sectors_per_cyl        DW ?
boot_heads                      DW ?
boot_hidden_sectors             DD ?
boot_big_sectors            DD ?
boot_drive_nr               DB ?,?
boot_signature              DB ?
boot_serial                     DD ?
boot_volume                     DB 11 DUP(?)
boot_fs                     DB 8 DUP(?)

boot_struc          ENDS

disc_struc      STRUC

boot_sect                   DB 512 DUP(?)

disc_section            section_typ <>
disc_fs_handle          DW ?
disc_sel                DW ?
disc_thread                 DW ?
disc_sub_unit           DB ?
disc_nr                 DB ?

disc_struc          ENDS

MotorOnWait         EQU 500
Spec1           EQU 0DFh
Spec2           EQU 2

data    SEGMENT byte public 'DATA'

FloppyThread    DW ?

DriveControl    DB ?
IntFlag         DB ?
TimeoutCount    DB ?
Gap                 DB 4 DUP(?)
Tracks          DB 4 DUP(?)
MotorCount          DB 4 DUP(?)
BootValid       DB 4 DUP(?)
DiscArr     DW 2 DUP(?)


CmdCode         DB ?
DriveHead           DB ?
cTrack          DB ?
cDriveHead          DB ?
cSector         DB ?
cBytesPerSector DB ?
cTracks         DB ?
cGap            DB ?
cDataLen        DB ?

st0                 DB ?
st1                 DB ?
st2                 DB ?
sTrack          DB ?
sHead           DB ?
sSector         DB ?
sBytesPerSector DB ?

FloppySpinlock  spinlock_typ <>
FloppySection   section_typ <>

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FLOPPY_INT
;
;           DESCRIPTION:    Floppy disk interrupt
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

floppy_int      Proc far
    mov al,ds:IntFlag
    or al,al
    jnz floppy_int_done
    inc al
    mov ds:IntFlag,al
    mov bx,ds:FloppyThread
    Signal
floppy_int_done:
    retf32
floppy_int      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CommandPhase
;
;           DESCRIPTION:    Execute command phase
;
;           PARAMETERS:         CX          Number of bytes to output
;
;           RETURNS:        NC          Performed ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CommandPhase    Proc near
    push ax
    push bx
    push dx
    push si
    ClearSignal
    mov ds:IntFlag,0
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
;    
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
    jnz     CommandPhaseDone
;
    mov dx,3F5h
    mov al,[bx]
    inc bx
    out dx,al               ; output data byte
;    
    mov ax,5
    WaitMicroSec
    loop CommandPhaseLoop
;
    mov si,2000

CommandPhaseEndLoop:
    mov ax,5
    WaitMicroSec
;
    mov dx,3F4h
    in al,dx
    test al,90h
    clc
    jnz CommandPhaseDone
;
    sub si,1
    jnc CommandPhaseEndLoop
;
    stc    

CommandPhaseDone:
    pop si
    pop dx
    pop bx
    pop ax
    ret
CommandPhase    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ExecutePhase
;
;           DESCRIPTION:    Wait for execute phase to be ready
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
    mov ds:TimeoutCount,20
    WaitForSignal
    mov al,ds:IntFlag
    or al,al
    clc
    jnz ExecutePhaseDone
    stc
ExecutePhaseDone:
    pop di
    pop dx
    pop ax
    pop es
    ret
ExecutePhase    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResultPhase
;
;           DESCRIPTION:    Execute result phase
;
;           RETURNS:        NC          Performed ok
;                           CX          Number of bytes in result 
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
;
    test al,80h
    jnz ResultPhaseReqSet

ResultPhaseWait:    
    mov ax,50
    WaitMicroSec
    sub si,1
    jnc ResultPhaseLoop
    jmp ResultPhaseDone

ResultPhaseReqSet:
    test al,40h
    jz ResultPhaseWait
;
    inc cx
    mov dx,3F5h
    in al,dx
    mov [bx],al
    inc bx
    mov ax,5
    WaitMicroSec
    jmp ResultPhaseLoop
    
ResultPhaseDone:
    pop si
    pop dx
    pop bx
    pop ax
    ret
ResultPhase   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RecoverPhase
;
;           DESCRIPTION:    Set controller in idle state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecoverPhase    Proc near
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
    jnz     RecoverPhaseRead
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
RecoverPhase    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DecodeStatus
;
;           DESCRIPTION:    Decode status of previous operation
;
;           RETURNS:        NC      Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeStatus    Proc near
    push ax
    mov al,ds:st0
    test al,0C0h
    clc
    jz DecodeStatusDone
    stc
DecodeStatusDone:
    pop ax
    ret
DecodeStatus    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Command
;
;           DESCRIPTION:    Execute command
;
;           PARAMETERS:         CX          Number of bytes to output
;
;           RETURNS:        NC          Performed ok
;                           CX          Number of bytes in answer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Command   Proc near
    push ax
    GetThread
    mov ds:FloppyThread,ax
    pop ax
;
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
    mov ds:FloppyThread,0
    ret
Command   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SenseIntCmd
;
;           DESCRIPTION:    Sense interrupt command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SenseIntCmd     Proc near
    push ax
    push cx
    mov ax,10
    WaitMilliSec
    mov ds:CmdCode,8
    mov cx,1
    call CommandPhase
    jc SenseIntDone
    call ResultPhase
SenseIntDone:
    pop cx
    pop ax
    ret
SenseIntCmd     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ExecuteSensePhase
;
;           DESCRIPTION:    Execute phase using sense int command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExecuteSensePhase   Proc near
    push es
    push ax
    push di
    mov ax,ds
    mov es,ax
    mov ds:TimeoutCount,20
    WaitForSignal
    mov al,ds:IntFlag
    or al,al
    stc
    jz ExecuteSenseDone
ExecuteSenseCmd:
    call SenseIntCmd
ExecuteSenseDone:
    pop di
    pop ax
    pop es
    ret
ExecuteSensePhase       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SenseDriveStatusCmd
;
;           DESCRIPTION:    Sense drive status command
;
;           PARAMETERS:         AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SenseDriveStatusCmd     Proc near
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
SenseDriveStatusCmd     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SpecifyCmd
;
;           DESCRIPTION:    Specify command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SpecifyCmd      Proc near
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
SpecifyCmd      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RecalibrateCmd
;
;           DESCRIPTION:    Recalibrate command
;
;           PARAMETERS:         AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecalibrateCmd  Proc near
    push cx
    mov ds:CmdCode,7
    mov ds:DriveHead,al
    mov cx,2
    call Command
    jc RecalibrateDone
    call SenseIntCmd
RecalibrateDone:
    pop cx
    ret
RecalibrateCmd  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadIdCmd
;
;           DESCRIPTION:    Read drive ID command
;
;           PARAMETERS:         AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadIdCmd       Proc near
    push cx
    mov ds:CmdCode,4Ah
    mov ds:DriveHead,al
    mov cx,2
    call Command
    mov cl,ds:sBytesPerSector
    mov ds:cBytesPerSector,cl
    pop cx
    ret
ReadIdCmd       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetController
;
;           DESCRIPTION:    ResetController
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetController Proc near
    push es
    push ax
    push cx
    push dx
    push di
    mov ax,ds
    mov es,ax
    mov cx,100
    mov ds:cTrack,-1

ResetControllerLoop:
    GetThread
    mov ds:FloppyThread,ax
    ClearSignal
    mov ds:IntFlag,0
    mov al,8
    mov dx,3F2h
    out dx,al
    mov ax,250
    WaitMicroSec
;
    mov al,0Ch
    mov dx,3F2h
    out dx,al
    mov ds:DriveControl,al
;
    mov ds:TimeoutCount,20
    WaitForSignal
    mov al,ds:IntFlag
    or al,al
    jz ResetControllerFailed

ResetControllerStart:
    mov al,0Ch
    out dx,al
    mov ds:DriveControl,al
ResetControllerSense:
    call SenseIntCmd
    jc ResetControllerFailed
;
    call SenseIntCmd
    jc ResetControllerFailed
;
    call SenseIntCmd
    jc ResetControllerFailed
;    
    call SenseIntCmd
    jc ResetControllerFailed
;
    call SpecifyCmd
    jnc ResetControllerDone
ResetControllerFailed:
    mov ax,250
    WaitMicroSec
    call RecoverPhase
    call SenseIntCmd
    mov ax,10
    WaitMilliSec
    sub cx,1
    jnz ResetControllerLoop
    stc
ResetControllerDone:
    mov ds:FloppyThread,0
;    
    pop di
    pop dx
    pop cx
    pop ax
    pop es
    ret
ResetController Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TestDrive
;
;           DESCRIPTION:    Test drive with a specified data rate
;
;           PARAMETERS:         AL          Drive #
;                           AH          Data rate
;
;           RETURNS:        NC          Success
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitDrive
;
;           DESCRIPTION:    Init drive and setup data rate
;
;           PARAMETERS:         AL          Drive #
;
;           RETURNS:        NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitDrive       Proc near
    push ax
    push bx
    movzx bx,al
;
    mov ah,0
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
;    int 3
    stc
InitDriveOk:
    mov ds:[bx].Gap,al
    mov ds:[bx].Tracks,ah
    pop bx
    pop ax
    ret
InitDrive       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SelectDrive
;
;           DESCRIPTION:    Set current drive
;
;           PARAMETERS:         AL          Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SelectDrive     Proc near
    push ax
    push bx
    push cx
    push dx
    movzx bx,al
    mov cl,al
    mov ah,10h
    rol ah,cl
;
    RequestSpinlock ds:FloppySpinlock
    mov al,ds:DriveControl
    test al,ah
    jnz SelectDriveMotorOn
;
    ReleaseSpinlock ds:FloppySpinlock
    call ResetController
    jc SelectDriveDone
;
    RequestSpinlock ds:FloppySpinlock
    mov ds:[bx].MotorCount,255
    mov al,ds:DriveControl
    and al,0F0h
    or al,ah
    or al,ds:DriveControl       
    mov ds:DriveControl,al
    mov dx,3F2h
    out dx,al
    ReleaseSpinlock ds:FloppySpinlock
;
    mov ax,MotorOnWait
    WaitMilliSec
;    
    RequestSpinlock ds:FloppySpinlock
    mov al,ds:DriveControl
    jmp SelectDriveInit

SelectDriveMotorOn:
    mov al,ds:DriveControl
    mov ah,al
    and ah,3
    cmp ah,cl
    clc
    jne SelectDriveInit
;    
    ReleaseSpinlock ds:FloppySpinlock
    jmp SelectDriveDone

SelectDriveInit:
    and al,NOT 3
    or al,cl
    mov dx,3F2h
    out dx,al
    mov ds:DriveControl,al
    ReleaseSpinlock ds:FloppySpinlock
;
    mov ax,100
    WaitMicroSec
    mov al,ds:[bx].Gap
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
    mov ds:[bx].MotorCount,25
    pop dx
    pop cx
    pop bx
    pop ax
    ret
SelectDrive     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupDMA
;
;           DESCRIPTION:    Setup DMA controller
;
;           PARAMETERS:         AL          Mode
;                                   42h = Verify
;                                   46h = Read
;                                   4Ah = Write
;                           EBX         Linear Address (must be within same page)
;                           CX          Number of bytes to transfer
;
;           RETURNS:        NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDMA    Proc near
    push ax
    push ebx
    push edx
;
    mov edx,ebx
    push es
    push eax
    mov ax,flat_sel
    mov es,ax
;
    GetPageEntry
    and ax,0F000h
    or eax,eax
    jz setup_dma_alloc
;
    cmp eax,1000000h
    jc setup_dma_inrange
;
    FreePhysical

setup_dma_alloc:
    AllocateDmaPhysical
    or al,13h
    SetPageEntry
    and ax,0F000h
    cmp eax,1000000h
    jc setup_dma_inrange
;
    int 3

setup_dma_inrange:
    and dx,0FFFh
    or ax,dx
    mov edx,eax
    pop eax
    pop es
;
    RequestSpinlock ds:FloppySpinlock    
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
    ReleaseSpinlock ds:FloppySpinlock    
;
    pop edx
    pop ebx
    pop ax
    ret
SetupDMA    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SeekCmd
;
;           DESCRIPTION:    Seek to track
;
;           PARAMETERS:         AL          Drive #
;                           AH          Cylinder #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SeekCmd Proc near
    push ax
    GetThread
    mov ds:FloppyThread,ax
    pop ax
    push cx
    mov ds:CmdCode,0Fh
    mov ds:DriveHead,al
    mov ds:cTrack,ah
    mov cx,3
    call CommandPhase
    jc SeekDone
    call ExecuteSensePhase
SeekDone:
    mov ds:FloppyThread,0
    pop cx
    ret
SeekCmd Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadCmd
;
;           DESCRIPTION:    Read sectors
;
;           PARAMETERS:         AL          Drive #
;                           DH          Head #
;                           DL          Sector
;                           AH          Cylinder
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCmd Proc near
    push bx
    push cx
    movzx bx,al
    mov ds:CmdCode,0E6h
    mov ds:cTrack,ah
    mov ds:cDriveHead,dh
    mov ds:cSector,dl
    mov cl,dh
    shl cl,2
    or cl,al
    mov ds:DriveHead,cl
    mov cl,ds:[bx].Gap
    mov ds:cGap,cl
    mov cl,ds:[bx].Tracks
    mov ds:cTracks,cl
    mov ds:cDataLen,0FFh
    mov cx,9
    call Command
    pop cx
    pop bx
    ret
ReadCmd Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCmd
;
;           DESCRIPTION:    Write sectors
;
;           PARAMETERS:         AL          Drive #
;                           DH          Head #
;                           DL          Sector
;                           AH          Cylinder #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCmd    Proc near
    push bx
    push cx
    movzx bx,al
    mov ds:CmdCode,0C5h
    mov ds:cTrack,ah
    mov ds:cDriveHead,dh
    mov ds:cSector,dl
    mov cl,dh
    shl cl,2
    or cl,al
    mov ds:DriveHead,cl
    mov cl,ds:[bx].Gap
    mov ds:cGap,cl
    mov cl,ds:[bx].Tracks
    mov ds:cTracks,cl
    mov ds:cDataLen,0FFh
    mov cx,9
    call Command
    pop cx
    pop bx
    ret
WriteCmd    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadDrive
;
;           DESCRIPTION:    Read sectors
;
;           PARAMETERS:         AL          Drive #
;                           CX          Number of bytes
;                           EBX         Logical address of buffer
;                           AH          Cylinder #
;                           DL          Sector
;                           DH          Head
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadDrive       Proc near
    push si
    mov si,3
    call SelectDrive
    jc ReadDriveRetry
    cmp ah,ds:cTrack
    je ReadDriveSetup

ReadDriveLoop:
    call SeekCmd
    pushf
    call check_media
    jnc ReadDriveMediaOk
;
    popf
    jmp ReadDriveRetry

ReadDriveMediaOk:
    popf
    jc ReadDriveRetry

ReadDriveSetup:
    push ax
    mov al,46h
    call SetupDMA
    pop ax
    call ReadCmd
    jnc ReadDriveDone

ReadDriveRetry:
    mov ds:cTrack,-1
    push ax
    push dx
;    
    RequestSpinlock ds:FloppySpinlock
    mov al,0Ch
    mov ds:DriveControl,al
    mov dx,3F2h
    out dx,al
    ReleaseSpinlock ds:FloppySpinlock
;    
    pop dx
    pop ax
    sub si,1
    jc ReadDriveDone
;
    call check_media
    jc ReadDriveRetry
;
    push ax
    mov ax,250
    WaitMilliSec
    pop ax
    jmp ReadDriveLoop

ReadDriveDone:
    pop si
    ret
ReadDrive       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteDrive
;
;           DESCRIPTION:    Write sectors
;
;           PARAMETERS:         AL          Drive #
;                           CX          Number of bytes
;                           EBX         Logical address of buffer
;                           AH          Cylinder #
;                           DL          Sector
;                           DH          Head
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDrive      Proc near
    push si
    mov si,3
    call SelectDrive
    jc WriteDriveRetry
    cmp ah,ds:cTrack
    je WriteDriveSetup
WriteDriveLoop:
    call SeekCmd
    pushf
    call check_media
    jnc WriteDriveMediaOk
;
    popf
    jmp WriteDriveRetry

WriteDriveMediaOk:
    popf
    jc WriteDriveRetry

WriteDriveSetup:
    push ax
    mov al,4Ah
    call SetupDMA
    pop ax
    call WriteCmd
    jnc WriteDriveDone
WriteDriveRetry:
    mov ds:cTrack,-1
    push ax
    push dx
;
    RequestSpinlock ds:FloppySpinlock
    mov al,0Ch
    mov ds:DriveControl,al
    mov dx,3F2h
    out dx,al
    ReleaseSpinlock ds:FloppySpinlock
;    
    pop dx
    pop ax
    sub si,1
    jc WriteDriveDone
;
    call check_media
    jc WriteDriveRetry
;
    push ax
    mov ax,250
    WaitMilliSec
    pop ax
    jmp WriteDriveLoop

WriteDriveDone:
    pop si
    ret
WriteDrive      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadBootSector
;
;           DESCRIPTION:    Get boot-record and drive parameters
;
;           PARAMETERS:         AL          Sub-unit #
;                           ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadBootSector  Proc near
    push ds
    push ax
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    mov ax,SEG data
    mov ds,ax
    mov eax,1000h
    AllocateBigLinear
    pop ax
;
    push edx
    mov ebx,edx
    call SelectDrive
    jnc read_boot_sector_read

read_boot_sector_retry:
    push ax
    mov al,0Ch
    mov ds:DriveControl,al
    mov dx,3F2h
    out dx,al
    pop ax
;
    push ax
    mov ax,250
    WaitMilliSec
    pop ax
;
    call SelectDrive
    jc read_boot_sector_done

read_boot_sector_read:
    mov ah,1
    call SeekCmd
    mov ds:cTrack,-1
    jc read_boot_sector_retry
;
    mov ah,0
    call SeekCmd
    mov ds:cTrack,-1
    jc read_boot_sector_retry
;
    mov dh,0
    mov dl,1
    mov cx,200h
    push ax
    mov al,46h
    call SetupDMA
    pop ax
;
    call ReadCmd
    jc read_boot_sector_retry
;
    mov cx,flat_sel
    mov ds,cx
    mov esi,ebx
    mov ecx,128
    rep movs dword ptr es:[edi],ds:[esi]
    mov cx,SEG data
    mov ds,cx
    movzx bx,al
    mov es:boot_drive_nr,al
    mov cl,ds:cBytesPerSector
    mov ax,80h
    shl ax,cl
    cmp ax,es:boot_bytes_per_sector
    stc
    jne read_boot_sector_done
;
    mov ax,es:boot_sectors_per_cyl
    mov ds:[bx].Tracks,al
    clc

read_boot_sector_done:
    pop edx
    pushf
    mov ecx,1000h
    FreeLinear
    popf
    jc read_boot_sector_end
;    
    mov ds:[bx].BootValid,1

read_boot_sector_end:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ax
    pop ds
    ret
ReadBootSector  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InstallMain
;
;           DESCRIPTION:    Install main drive
;
;           PARAMETERS:         AL          Sub-unit #
;                           ES          Boot sector
;                           FS          Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat12   DB 'FAT12   '

InstallMain     Proc near
    push es
    push ax
    push bx
    push cx
    push edx
    push edi
;
    mov cl,es:boot_media
    cmp cl,0F0h
    je install_main_fat12
    mov edi,OFFSET boot_fs
    jmp install_main_fs
install_main_fat12:
    mov cx,cs
    mov es,cx
    mov edi,OFFSET fat12
install_main_fs:
    InstallFileSystem
;
    pop edi
    pop edx
    pop cx
    pop bx
    pop ax
    pop es
    ret
InstallMain     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DEMAND_MOUNT
;
;           DESCRIPTION:    Mount disc drive on demand
;
;           PARAMETERS:         BX          Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

demand_mount_proc    Proc far
    push ds
    push es
    pushad
;
    mov es,bx
    mov ax,SEG data
    mov ds,ax
    mov al,es:disc_sub_unit
    mov edi,OFFSET boot_sect
    EnterSection ds:FloppySection
    call ReadBootSector
    LeaveSection ds:FloppySection
    jc drive_assign_done1
;
    call InstallMain
    pushf
    mov ax,es:boot_sectors_per_cyl
    mul es:boot_heads
    mov cx,es:boot_bytes_per_sector
    mov edx,80
    mov si,es:boot_sectors_per_cyl
    mov di,es:boot_heads
    mov bx,es:disc_sel
    SetDiscParam
;
    mov bx,es:disc_thread
    Signal
    popf
    jc drive_assign_done1
;
    mov bx,es:disc_sel
    StartDisc

drive_assign_done1:
    popad
    pop es
    pop ds
    retf32
demand_mount_proc    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           check_media
;
;           DESCRIPTION:    Check for media change
;
;           PARAMETERS:         FS          Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_media     Proc near
    push ds
    push eax
    push bx
    push dx
;
    mov bx,fs
    mov ds,bx
    EnterSection ds:disc_section
;
    mov al,fs:boot_drive_nr
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    mov bl,ds:[bx].Gap
    or bl,bl
    stc
    jz check_media_done
;
    call SelectDrive
    jc check_media_do
;
    push ax
    mov dx,3F7h
    in al,dx
    shl al,1
    pop ax
    jnc check_media_done

check_media_do:
    push es
    push ecx
    push esi
    push edi
;
    push eax
    mov eax,200h
    AllocateSmallGlobalMem
    pop eax

check_media_retry:
    xor edi,edi
    call ReadBootSector
;
    mov esi,OFFSET boot_sect
    mov ecx,80h
    repe cmps dword ptr fs:[esi],[edi]
    clc
    jz check_media_free
;
    mov bx,fs:disc_sel
    StopDisc
    push ax
    mov ax,250
    WaitMilliSec
    pop ax
    jmp check_media_retry

check_media_free:
    pushf
    FreeMem
    popf
    pop edi
    pop esi
    pop ecx
    pop es
    
check_media_done:
    mov bx,fs
    mov ds,bx
    LeaveSection ds:disc_section
;
    pop dx
    pop bx
    pop eax
    pop ds
    ret
check_media     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           check_media_proc
;
;           DESCRIPTION:    Check for media change
;
;           PARAMETERS:         BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_media_proc    Proc far
    push ds
    push fs
    push ax
;
    mov ax,SEG data
    mov ds,ax
    mov fs,bx
    EnterSection ds:FloppySection
    call check_media
    LeaveSection ds:FloppySection
;
    pop ax
    pop fs
    pop ds
    retf32
check_media_proc    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FLOPPY_SUPER
;
;           DESCRIPTION:    Supervisor thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

floppy_super_name       DB 'Floppy Supervisor',0

floppy_super:
    mov ax,SEG data
    mov ds,ax
floppy_super_loop:
    xor bx,bx
    mov cx,4
    mov ah,NOT 10h
floppy_super_motor_loop:
    RequestSpinlock ds:FloppySpinlock
    mov al,ds:[bx].MotorCount
    or al,al
    jz floppy_super_motor_next
;
    sub al,1
    mov ds:[bx].MotorCount,al
    jnz floppy_super_motor_next
;    
    mov al,ds:DriveControl
    and al,ah
    mov dx,3F2h
    mov al,0
    out dx,al
    mov ds:DriveControl,al

floppy_super_motor_next:
    ReleaseSpinlock ds:FloppySpinlock
    inc bx
    shl ah,1
    loop floppy_super_motor_loop
;
    mov bx,ds:FloppyThread
    or bx,bx
    jz floppy_super_wait
;
    RequestSpinlock ds:FloppySpinlock
    mov al,ds:IntFlag
    or al,al
    jnz floppy_super_signal
;
    mov al,ds:TimeoutCount
    sub al,1
    mov ds:TimeoutCount,al
    jnz floppy_super_wait_release

floppy_super_signal:
    ReleaseSpinlock ds:FloppySpinlock
    Signal
    jmp floppy_super_wait

floppy_super_wait_release:
    ReleaseSpinlock ds:FloppySpinlock

floppy_super_wait:
    mov ax,100
    WaitMilliSec
    jmp floppy_super_loop

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           read_drive
;
;           DESCRIPTION:    Read drive
;
;           PARAMETERS:         FS          Disc selector
;                           EDI         Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_drive      Proc near
    push cx
    mov cx,3

read_drive_loop:
    push eax
    push cx
    push edx
    push edi
;
    movzx eax,es:[edi].dh_sector
    mov edx,es:[edi].dh_unit
    mov edi,es:[edi].dh_data
;
    div byte ptr fs:boot_sectors_per_cyl
    mov dh,al
    xchg ah,dl
    inc dl
    mov al,fs:boot_drive_nr
;
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
read_drive      Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           write_drive
;
;           DESCRIPTION:    Perform a write request
;
;           PARAMETERS:         DS          Disc selector
;                           EDI         Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive     Proc near
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
    mov edx,es:[edi].dh_unit
    mov edi,es:[edi].dh_data
;
    div byte ptr fs:boot_sectors_per_cyl
    mov dh,al
    xchg ah,dl
    inc dl
    mov al,fs:boot_drive_nr
;
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
write_drive     Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           perform_one
;
;           DESCRIPTION:    Perform one request
;
;           PARAMETERS:         FS          Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_one     Proc near

perform_one_loop:
    mov ecx,1
    GetDiscRequestArray
    jc perform_one_done
;
    cmp ecx,1
    jne perform_one_done
;
    mov edi,es:[esi]
    mov al,fs:disc_sub_unit
    movzx bx,al
    mov bl,ds:[bx].BootValid
    or bl,bl
    jnz perform_mounted
;
    push es
    push edi
    mov bx,fs
    mov es,bx
    mov al,es:disc_sub_unit
    mov edi,OFFSET boot_sect
    call ReadBootSector
    pop edi
    pop es

perform_mounted:
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
    jc perform_one_fail
    jmp perform_one_completed

perform_one_read:
    call check_media
    jc perform_one_fail
;
    call read_drive
    jc perform_one_fail

perform_one_completed:
    mov bx,fs:disc_sel
    DiscRequestCompleted
    jmp perform_one_loop

perform_one_fail:
    int 3
    mov bx,fs:disc_sel
    DiscRequestCompleted
;       FlushDisc

perform_one_done:
    ret
perform_one     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFloppyDisc
;
;           description:    Get disc # for a physical disc unit
;
;           PARAMETERS:         BL      Floppy disc #
;
;       RETURNS:    AL      disc #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_floppy_disc_name DB 'Get Floppy Disc',0

get_floppy_disc Proc far
    push ds
    push bx
;
    mov ax,SEG data
    mov ds,ax
    cmp bl,2
    jae get_floppy_fail
;    
    movzx bx,bl
    add bx,bx
    mov bx,ds:[bx].DiscArr
    or bx,bx
    jz get_floppy_fail
;
    mov ds,bx
    mov al,ds:disc_nr
    clc
    jmp get_floppy_done

get_floppy_fail:
    stc
    
get_floppy_done:    
    pop bx
    pop ds    
    retf32
get_floppy_disc Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DISCBUF_THREAD
;
;           DESCRIPTION:    Thread to handle disc buffer queue
;
;           PARAMETERS:         FS          Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

discbuf_thread:
    GetThread
    mov fs:disc_thread,ax
    mov bx,fs:disc_sel
;
    mov ax,SEG data
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;       WaitForSignal

discbuf_thread_loop:
    WaitForDiscRequest
    EnterSection ds:FloppySection
    call perform_one
    LeaveSection ds:FloppySection
    jmp discbuf_thread_loop
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INSTALL_UNIT
;
;           DESCRIPTION:    Install a disk unit
;
;           PARAMETERS:         AL          UNIT #
;                           DI          NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_unit    Proc near
    movzx si,al
    add si,si
    add si,OFFSET DiscArr
    push ax
    mov eax,SIZE disc_struc
    AllocateSmallGlobalMem
;
    push ax
    push di
    xor di,di
    mov cx,128
    mov eax,0FFFFFFFFh
    rep stosd
    pop di
    pop ax
;
    mov bx,es
    mov fs,bx
    pop ax
    mov fs:disc_sub_unit,al
    push ds
    push ax
    mov ax,fs
    mov ds,ax
    InitSection ds:disc_section
    pop ax
    pop ds
;       
    mov ecx,200h
    mov bx,fs
    InstallFixedDisc
;
    mov fs:disc_sel,bx
    mov fs:disc_nr,al
    mov ds:[si],fs
;
    push edi
    mov ax,cs
    mov es,ax
    mov edi,OFFSET check_media_proc
    RegisterDiscChange
;
    mov edi,OFFSET demand_mount_proc
    RegisterDemandMount
;
    pop edi
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET discbuf_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    mov al,fs:disc_sub_unit
    mov ah,fs:disc_nr
    xor edx,edx
    mov ecx,-1
    OpenDrive
    DemandLoadFileSystem
    ret
install_unit    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_floppy
;
;           DESCRIPTION:    Init floppy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_floppy_name DB 'Init Floppy', 0

floppy0 DB 'Floppy Drive 0',0
floppy1 DB 'Floppy Drive 1',0

init_floppy:
    mov ax,SEG data
    mov ds,ax
    call ResetController
;
    mov al,0
    AllocateFixedDrive
;
    mov al,0
    mov di,OFFSET floppy0
    call install_unit
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_floppy_thread
;
;           DESCRIPTION:    Init floppy thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_floppy_thread    PROC far
    push ds
    push es
    pushad
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET init_floppy
    mov edi,OFFSET init_floppy_name
    mov cx,stack0_size
    mov ax,4
    CreateThread
;
    mov esi,OFFSET floppy_super
    mov edi,OFFSET floppy_super_name
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    mov al,6
    mov ah,14h
    mov bx,floppy_data_sel
    mov ds,bx
    mov bx,cs
    mov es,bx
    mov edi,OFFSET floppy_int
    RequestIrqHandler
;
    popad
    pop es
    pop ds
    retf32
init_floppy_thread    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init device
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov dx,3F4h
    in al,dx
    cmp al,-1
    stc
    je init_floppy_done
;
    mov ax,SEG data
    mov ds,ax
    InitSection ds:FloppySection    
    InitSpinlock ds:FloppySpinlock
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_floppy_disc
    mov edi,OFFSET get_floppy_disc_name
    xor dx,dx
    mov ax,get_floppy_disc_nr
    RegisterBimodalUserGate
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET init_floppy_thread
    HookInitTasking
    clc

init_floppy_done:
    ret
init    ENDP

code ENDS

END init
