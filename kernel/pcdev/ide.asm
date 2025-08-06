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
; IDE.ASM
; IDE disk driver
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
INCLUDE ..\acpi\pci.inc

LBA_MODE        = 1
LBA_48          = 2

part_struc      STRUC

part_status         DB ?
part_start_head     DB ?
part_start_cyl_sector   DW ?
part_type           DB ?
part_end_head       DB ?
part_end_cyl_sector     DW ?
part_start_sector       DD ?
part_sectors        DD ?

part_struc      ENDS

drive_data      STRUC

drive_lba_flags         DB ?
drive_precomp           DB ?
drive_sectors_per_cyl       DW ?
drive_heads             DW ?
drive_cyls              DW ?
drive_sectors_per_unit      DW ?
drive_units             DW ?
drive_lba_sectors           DD ?
disc_io_base    DW ?
disc_ide_sel    DW ?
disc_sel            DW ?
disc_thread             DW ?
disc_sub_unit           DB ?
disc_nr             DB ?

disc_model          DB 40 DUP(?)

drive_data      ENDS

ide_data    STRUC

IdeThread       DW ?
IdeIoBase       DW ?
DriveSelArr     DW 2 DUP(?)
IdeSection      section_typ <>
IntFlag     DB ?

ide_data    ENDS

MAX_PCI_COUNT = 16
PCI_NAME_SIZE = 16

data    SEGMENT byte public 'DATA'

pci_thread      DW ?
ide_pci_count   DW ?
ide_io_arr      DW MAX_PCI_COUNT DUP(?)
ide_pci_arr     DW MAX_PCI_COUNT DUP(?)

pci_curr_ptr    DW ?
pci_unit_ptr    DW ?
pci_name_str    DB PCI_NAME_SIZE DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       IDE_INT
;
;       DESCRIPTION:    IDE INTERRUPT
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ide_int Proc far
    mov ds:IntFlag,1
    mov bx,ds:IdeThread
    Signal
    retf32
ide_int Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       IDE_PCI_INT
;
;       DESCRIPTION:    PCI IDE INTERRUPT
;
;       PARAMETERS:     
;
;       RETURNS:        CY           Activity
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ide_pci_int Proc far
    mov dx,ds:IdeIoBase
    or dx,dx
    jz ide_pci_int_base_ok
;
    add dx,7
    in al,dx

ide_pci_int_base_ok:
    mov al,1
    xchg al,ds:IntFlag
    or al,al
    clc
    jnz ide_pci_done
;
    mov bx,ds:IdeThread
    Signal
    stc

ide_pci_done:
    retf32
ide_pci_int Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       CheckReady
;
;       DESCRIPTION:    Wait for ready
;
;       PARAMETERS:     DS      IDE_DATA
;           DX      Io base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckReady      PROC near
    push ax
    push cx
    push dx
;
    add dx,7
    mov cx,10000

CheckBusyLoop:
    in al,dx
    test al,80h
    clc
    jz CheckReadyDone
;       
    mov ax,50
    WaitMicroSec
;       
    loop CheckBusyLoop
    
    stc
    
CheckReadyDone:
    pop dx
    pop cx
    pop ax
    ret
CheckReady      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       WaitReady
;
;       DESCRIPTION:    Wait for DRDY signal
;
;       PARAMETERS:     DS      IDE_DATA
;           DX      Io base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitReady       PROC near
    push ax
    push cx
    push dx
;
    add dx,7
    mov cx,10000

WaitReadyLoop:
    in al,dx
    test al,40h
    clc
    jnz WaitReadyDone
;       
    mov ax,50
    WaitMicroSec
;       
    loop WaitReadyLoop
    
    stc
    
WaitReadyDone:
    pop dx
    pop cx
    pop ax
    ret
WaitReady       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       WaitDrq
;
;       DESCRIPTION:    Wait for data request
;
;       PARAMETERS:     DS      IDE_DATA
;           DX      Disc io base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitDrq Proc near
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
WaitDrq Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       CheckStatus
;
;       DESCRIPTION:    Check transfer status
;
;       PARAMETERS:     DS      IDE_DATA
;           DX      Disc io base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckStatus     Proc near
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
CheckStatus     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       SetupIdeTaskFile
;
;       DESCRIPTION:    Setup IDE comp. task file
;
;       PARAMETERS:     DS      IDE_DATA
;               FS      Disc sel
;               AH      Precomp
;               BH      Head #
;               BL      Sector
;               CX      Number of sectors
;               DX      Cylinder
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupIdeTaskFile    Proc near
    push ax
    push bx
    push dx
;
    push dx
    mov dx,fs:disc_io_base
    add dx,7
    in al,dx
    clc
    test al,80h
    jz SetupIdeNotBusy
;
    sub dx,7
    call CheckReady

SetupIdeNotBusy:    
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
;
    mov dx,fs:disc_io_base
    add dx,7
    in al,dx
    test al,40h
    clc
    jnz SetupIdeTaskDone
;
    sub dx,7
    call WaitReady
    
SetupIdeTaskDone:
    pop dx
    pop bx
    pop ax
    ret
SetupIdeTaskFile    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       SetupLbaTaskFile
;
;       DESCRIPTION:    Setup LBA comp. task file
;
;       PARAMETERS:     DS      IDE_DATA
;               FS      Disc sel
;               AH      Precomp
;               CX      Number of sectors
;               EDX     Sector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupLbaTaskFile    Proc near
    push ax
    push bx
    push dx
;
    push dx
    mov dx,fs:disc_io_base
    add dx,7
    in al,dx
    clc
    test al,80h
    jz SetupLbaNotBusy
;
    sub dx,7
    call CheckReady

SetupLbaNotBusy:    
    pop dx
    jc SetupLbaTaskDone
;
    test fs:drive_lba_flags,LBA_48
    jnz SetupLba48

SetupLba24:
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
;
    mov dx,fs:disc_io_base
    add dx,7
    in al,dx
    test al,40h
    clc
    jnz SetupLbaTaskDone
;
    sub dx,7
    call WaitReady
    jmp SetupLbaTaskDone

SetupLba48:
    push edx
;
    mov dx,fs:disc_io_base
    add dx,6
;
    mov al,fs:disc_sub_unit
    shl al,4
    or al,40h
    out dx,al
;
    mov dx,fs:disc_io_base
    add dx,2
;
    mov al,ch
    out dx,al
    inc dx
;
    pop eax
    rol eax,8
;    
    jmp short $+2
    out dx,al
    inc dx
;
    jmp short $+2
    xor al,al
    out dx,al
    inc dx
;
    jmp short $+2
    xor al,al
    out dx,al
;
    sub dx,3
    jmp short $+2
    mov al,cl
    out dx,al
    inc dx
;
    ror eax,8
    jmp short $+2
    out dx,al
    inc dx
;
    ror eax,8
    jmp short $+2
    out dx,al
    inc dx
;
    ror eax,8
    jmp short $+2
    out dx,al
    inc dx
    clc
    
SetupLbaTaskDone:
    pop dx
    pop bx
    pop ax
    ret
SetupLbaTaskFile    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       ReadTaskFile
;
;       DESCRIPTION:    Read data from device
;
;       PARAMETERS:     DS      IDE SEGMENT
;               AL      COMMAND CODE
;               CX      Number of sectors
;           DX      Disc io base
;               ES:EDI  Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadTaskFile    Proc near
    push cx
    push edi
;
    ClearSignal
    push dx
    add dx,7
    out dx,al
    pop dx
    
ReadTaskFileInt:
    push eax
    push edx
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
    WaitForSignalWithTimeout
    pop edx
    pop eax
;       
    push dx
    add dx,7
    in al,dx
    pop dx
    test al,80h
    jnz ReadTaskFileInt
;
    push ecx
    mov ecx,256
    rep ins word ptr es:[edi],dx
    pop ecx
    call CheckStatus
    jc ReadTaskFileDone
    loop ReadTaskFileInt
    clc
    
ReadTaskFileDone:
    pop edi
    pop cx
    ret
ReadTaskFile    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       WriteTaskFile
;
;       DESCRIPTION:    Write data to device
;
;       PARAMETERS:     DS      IDE SEGMENT
;               AL      Command code
;               CX      Number of sectors
;           DX      Disc io base
;               ES:EDI  Logical address of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteTaskFile   PROC near
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

WriteTaskFileWait:       
    push eax
    push edx
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
    WaitForSignalWithTimeout
    pop edx
    pop eax
;       
    push dx
    add dx,7
    in al,dx
    pop dx
    test al,80h
    jnz WriteTaskFileWait
;
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
WriteTaskFile   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       GetDriveParams
;
;       DESCRIPTION:    Get drive param
;
;       PARAMETERS:     DS      IDE SEGMENT
;               FS      DRIVE SEL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDriveParams  Proc near
    push es
    pushad
;
    mov ax,flat_sel
    mov es,ax
    mov eax,200h
    AllocateSmallLinear
    mov edi,edx
;
    mov fs:drive_lba_flags,0
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
    xor edx,edx
    mov ecx,10

get_drive_copy_model:
    mov eax,es:[edi+edx+36h]
    mov dword ptr fs:[edx].disc_model,eax
    add edx,4
    loop get_drive_copy_model    
;
    mov ax,es:[edi+166]
    test ax,4000h
    jz get_drive_param24

get_drive_param48:
    mov edx,es:[edi+204]
    mov eax,es:[edi+200]
    or edx,edx
    jz get_drive_param_save48
;
    mov eax,0FFFFFFFFh

get_drive_param_save48:
    cmp eax,es:[edi+120]
    jb get_drive_param24
;    
    or fs:drive_lba_flags,LBA_48
    jmp get_drive_param_sectors_ok

get_drive_param24:
    mov eax,es:[edi+120]

get_drive_param_sectors_ok:
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
    or fs:drive_lba_flags,LBA_MODE
    mov cx,1
    mov ah,fs:drive_precomp
    xor edx,edx
    call SetupLbaTaskFile
    jc get_drive_param_done
;
    mov al,20h
    test fs:drive_lba_flags,LBA_48
    jz get_drive_param_check
;
    or al,4

get_drive_param_check:    
    mov dx,fs:disc_io_base
    call ReadTaskFile       
    jnc get_drive_param_done
;
    mov fs:drive_lba_flags,0
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
GetDriveParams  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       CalcParam
;
;       DESCRIPTION:    Calculate various parameters
;
;       PARAMETERS:     DS      IDE SEGMENT
;               FS      DRIVE SEL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcParam       Proc near
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
CalcParam       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       read_drive
;
;       DESCRIPTION:    Read drive
;
;       PARAMETERS:     FS      Disc selector
;               ESI     Disc handle array
;               ECX     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_drive      Proc near
    mov ds,fs:disc_ide_sel
    EnterSection ds:IdeSection
    mov bp,3

read_drive_retry_loop:
    ClearSignal
    GetThread
    mov ds:IdeThread,ax
    mov ax,fs:disc_io_base
    mov ds:IdeIoBase,ax
;
    test fs:drive_lba_flags,LBA_MODE
    jz read_drive_ide

read_drive_lba:
    mov edx,es:[edi].dh_unit
    movzx eax,fs:drive_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    mov ah,fs:drive_precomp
    call SetupLbaTaskFile
    jmp read_drive_start

read_drive_ide:
    mov edx,es:[edi].dh_unit
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
    test fs:drive_lba_flags,LBA_48
    jz read_drive_lba_ok
;
    or al,4

read_drive_lba_ok:    
    mov dx,fs:disc_io_base
    add dx,7
    out dx,al

read_sector_loop:
    push eax
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
    WaitForSignalWithTimeout
    pop eax
;       
    mov dx,fs:disc_io_base
    add dx,7
    in al,dx
    test al,80h
    jnz read_sector_loop
;    
    mov dx,fs:disc_io_base
    call CheckStatus
    jc read_drive_retry
;       
    mov dx,fs:disc_io_base
    add dx,7
    in al,dx
    test al,8
    clc
    jnz read_drive_drq_ok
;
    call WaitDrq
    jc read_drive_retry

read_drive_drq_ok:
    mov dx,fs:disc_io_base
    push cx
    push edi
    mov edi,es:[edi].dh_data
    mov ecx,256
    rep ins word ptr es:[edi],dx
    pop edi
    pop cx
    jmp read_drive_ok

read_drive_retry:
    int 3
    sub bp,1
    jnz read_drive_retry_loop

read_drive_fail:
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
read_drive      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       write_drive
;
;       DESCRIPTION:    Perform a write request
;
;       PARAMETERS:     FS      Disc selector
;               ESI     Disc handle array
;               ECX     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive     Proc near
    mov ds,fs:disc_ide_sel
    EnterSection ds:IdeSection
    mov bp,3

write_drive_retry_loop:
    ClearSignal
    GetThread
    mov ds:IdeThread,ax
    mov ax,fs:disc_io_base
    mov ds:IdeIoBase,ax
;
    test fs:drive_lba_flags,LBA_MODE
    jz write_drive_ide

write_drive_lba:
    mov edx,es:[edi].dh_unit
    movzx eax,fs:drive_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    mov ah,fs:drive_precomp
    call SetupLbaTaskFile
    jmp write_drive_start

write_drive_ide:
    mov edx,es:[edi].dh_unit
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
    test fs:drive_lba_flags,LBA_48
    jz write_drive_lba_ok
;
    or al,4

write_drive_lba_ok:    
    mov dx,fs:disc_io_base
    add dx,7
    out dx,al

write_sector_loop:
    mov dx,fs:disc_io_base
    call WaitDrq
    jc write_drive_retry
;       
    mov dx,fs:disc_io_base
    push cx
    push esi
    mov esi,es:[edi].dh_data
    mov ecx,256
    rep outs word ptr dx,es:[esi]
    pop esi
    pop cx

write_sector_wait:
    push eax
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
    WaitForSignalWithTimeout
    pop eax
;       
    mov dx,fs:disc_io_base
    add dx,7
    in al,dx
    test al,80h
    jnz write_sector_wait
;       
    mov dx,fs:disc_io_base
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
write_drive     Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       perform_one
;
;       DESCRIPTION:    Perform one request
;
;       PARAMETERS:     FS      Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_one     Proc near

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
perform_one     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       DISCBUF_THREAD
;
;       DESCRIPTION:    Thread to handle disc buffer queue
;
;       PARAMETERS:     FS      Disc handle
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       INSTALL_TIMEOUT1
;
;       DESCRIPTION:    Install unit timeout
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_timeout1    Proc far
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
    retf32
install_timeout1    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       INSTALL_TIMEOUT2
;
;       DESCRIPTION:    Install unit timeout
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_timeout2    Proc far
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
    retf32
install_timeout2    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       INSTALL_UNIT
;
;       DESCRIPTION:    Install a unit
;
;       PARAMETERS:     AL      UNIT #
;           DX      IO BASE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc0   DB 'Ide Drive 0',0
disc1   DB 'Ide Drive 1',0
disc2   DB 'Ide Drive 2',0
disc3   DB 'Ide Drive 3',0

disc_name_tab1:
dnt100  DW OFFSET disc0
dnt101  DW OFFSET disc1

disc_name_tab2:
dnt200  DW OFFSET disc2
dnt201  DW OFFSET disc3

install_unit    Proc near
    mov ds:IntFlag,0
    ClearSignal
    call CheckReady
    jc install_unit_done
;
    cmp dx,1F0h
    je inst_timeout_primary
;       
    mov edi,OFFSET install_timeout2
    jmp inst_timeout_start

inst_timeout_primary:   
    mov edi,OFFSET install_timeout1

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
    InstallStaticDisc
    mov fs:disc_sel,bx
    mov fs:disc_nr,al
    mov fs:disc_ide_sel,ds
;
    test fs:drive_lba_flags,LBA_MODE
    jz install_chs

install_lba:
    mov eax,fs:drive_lba_sectors
    xor edx,edx
    mov cx,512
    SetDiscLbaParam
    mov fs:drive_sectors_per_unit,ax
    mov fs:drive_units,dx
    jmp install_common

install_chs:
    call CalcParam
    mov ax,fs:drive_sectors_per_unit
    movzx edx,fs:drive_units
    mov cx,512
    mov si,fs:drive_sectors_per_cyl
    mov di,fs:drive_heads
    mov bx,fs:disc_sel
    SetDiscParam

install_common:
    GetDiscVendorInfoBuf
    mov al,'I'
    stosb
    mov al,'D'
    stosb
    mov al,'E'
    stosb
    mov al,':'
    stosb
    mov cx,10
    mov si,OFFSET disc_model
    rep movs dword ptr es:[di],fs:[si]
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
    mov cx,stack0_size
    CreateThread
    pop ds
    clc

install_unit_done:
    ret
install_unit    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       INSTALL_PCI_TIMEOUT
;
;       DESCRIPTION:    Install unit timeout
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_pci_timeout    Proc far
    push ds
    push ax
    push bx
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:pci_thread
    Signal
;
    pop bx
    pop ax
    pop ds
    retf32
install_pci_timeout    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       INSTALL_PCI_UNIT
;
;       DESCRIPTION:    Install a PCI unit
;
;       PARAMETERS:     AL      UNIT #
;                       DX      IO BASE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_pci_unit    Proc near
    push es
    pushad
;    
    mov di,es:pci_unit_ptr
    push ax
    add al,'0'
    mov es:[di],al
    pop ax
;    
    mov ds:IntFlag,0
    ClearSignal
    call CheckReady
    jc install_pci_unit_done
;
    push ax
    push dx
;
    GetThread
    mov ds:IdeThread,ax
    mov ds:IdeIoBase,dx
;    
    GetSystemTime
    add eax,119300
    adc edx,0
    mov bx,cs
    mov es,bx
    mov bx,cs
    mov edi,OFFSET install_pci_timeout
    StartTimer
;    
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
    
install_pci_unit_read:
    in ax,dx
    loop install_pci_unit_read
;
    mov al,ds:IntFlag
    or al,al
    stc
    jz install_pci_unit_check_done
;       
    call CheckStatus

install_pci_unit_check_done:
    pop ax
    jc install_pci_unit_done
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
    jnc install_pci_unit_ok
;
    xor ax,ax
    mov fs,ax
    FreeMem
    stc
    jmp install_pci_unit_done

install_pci_unit_ok:
    movzx bx,al
    shl bx,1
    mov ds:[bx].DriveSelArr,fs
;
    mov ecx,10000h
    mov bx,fs
    InstallStaticDisc
    mov fs:disc_sel,bx
    mov fs:disc_nr,al
    mov fs:disc_ide_sel,ds
;
    test fs:drive_lba_flags,LBA_MODE
    jz install_pci_chs

install_pci_lba:
    mov eax,fs:drive_lba_sectors
    xor edx,edx
    mov cx,512
    SetDiscLbaParam
    mov fs:drive_sectors_per_unit,ax
    mov fs:drive_units,dx
    jmp install_pci_common

install_pci_chs:
    call CalcParam
    mov ax,fs:drive_sectors_per_unit
    movzx edx,fs:drive_units
    mov cx,512
    mov si,fs:drive_sectors_per_cyl
    mov di,fs:drive_heads
    mov bx,fs:disc_sel
    SetDiscParam

install_pci_common:
    push ds
    mov ax,cs
    mov ds,ax
;
    mov ax,SEG data    
    mov es,ax
    mov di,OFFSET pci_name_str
    mov si,OFFSET discbuf_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
    pop ds
    clc

install_pci_unit_done:
    mov ds:IdeThread,0
;
    popad
    pop es
    ret
install_pci_unit    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       GetIdeDisc
;
;       description:    Get disc # for a physical disc unit
;
;       PARAMETERS:     BL      IDE disc #
;
;       RETURNS:    AL      disc #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ide_disc_name DB 'Get IDE Disc',0

get_ide_disc    Proc far
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
    cmp bl,4
    jae get_ide_pci
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

get_ide_pci:
    sub bl,2
    push cx
    push si
;    
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:ide_pci_count
    or cx,cx
    jz get_ide_pci_fail
;    
    mov si,OFFSET ide_pci_arr

get_ide_pci_loop:
    cmp bl,2
    jb get_ide_pci_check
;
    sub bl,2
    add si,2
    sub cx,1
    jnz get_ide_pci_loop

get_ide_pci_fail:
    stc
    jmp get_ide_pci_done

get_ide_pci_check:
    mov ds,ds:[si]
    movzx bx,bl
    add bx,bx
    mov bx,ds:[bx].DriveSelArr
    or bx,bx
    jz get_ide_pci_fail
;
    mov ds,bx
    mov al,ds:disc_nr
    clc
        
get_ide_pci_done:
    pop si
    pop cx    
    jmp get_ide_done

get_ide_fail:
    stc
    
get_ide_done:    
    pop bx
    pop ds    
    retf32
get_ide_disc    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckPciBar
;
;           DESCRIPTION:    Check single PCI bar for valid IDE drive
;
;       PARAMETERS:         BX      PCI handle
;                           DX      IO port
;                           FS      Data sel
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckPciBar    Proc near
    push ds
    push di
;
    or dx,dx
    stc
    jz cpbDone
;    
    push dx
    add dx,7
    in al,dx
    pop dx
    and al,7Fh
    jz cpbFailPop
;    
    cmp al,7Fh
    jne cpbOk

cpbFailPop:    
    stc
    jmp cpbDone

cpbOk:
    mov di,fs:ide_pci_count
    add di,di
    mov fs:[di].ide_io_arr,dx
;
    mov eax,SIZE ide_data
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    InitSection ds:IdeSection
;       
    mov ds:IdeThread,0
    mov ds:IdeIoBase,0
    mov ds:DriveSelArr,0
    mov ds:DriveSelArr+2,0
    mov fs:[di].ide_pci_arr,ds
;    
    mov al,12h
    mov di,cs
    mov es,di
    mov edi,OFFSET ide_pci_int
    SetupPciIrq
;
    inc fs:ide_pci_count
    clc

cpbDone:
    pop di
    pop ds
    ret
CheckPciBar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckPciIde
;
;           DESCRIPTION:    Check for PCI IDE devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DevName1 DB 'IDE-1', 0
DevName2 DB 'IDE-2', 0

CheckPciIde Proc near
    mov ax,cs
    mov es,ax
;
    xor bx,bx

cpiLoop:
    mov ah,1
    mov al,1
    FindPciClass
    jc cpiDone
;
    xor al,al
    GetPciBarIo
    jc cpiBar1Done
;    
    cmp dx,1F0h
    je cpiBar1Done
;
    mov edi,OFFSET DevName1
    LockPci
;
    call CheckPciBar

cpiBar1Done:
    mov al,2
    GetPciBarIo
    jc cpiBar3Done
;    
    cmp dx,170h
    je cpiBar3Done
;    
    mov edi,OFFSET DevName2
    LockPci
;
    call CheckPciBar

cpiBar3Done:
    jmp cpiLoop
    
cpiDone:
    ret
CheckPciIde Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckPciSata
;
;           DESCRIPTION:    Check for PCI SATA devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SataName1 DB 'SATA-1', 0
SataName2 DB 'SATA-2', 0

CheckPciSata Proc near
    mov ax,cs
    mov es,ax
;
    xor bx,bx

cpaLoop:
    mov ah,1
    mov al,6
    FindPciClass
    jc cpaDone
;
    xor al,al
    GetPciBarIo
    jc cpaBar1Done
;    
    cmp dx,1F0h
    je cpaBar1Done
;
    mov edi,OFFSET SataName1
    LockPci
;
    call CheckPciBar

cpaBar1Done:
    mov al,2
    GetPciBarIo
    jc cpaBar3Done
;
    cmp dx,170h
    je cpaBar3Done
;
    mov edi,OFFSET SataName2
    LockPci
;    
    call CheckPciBar

cpaBar3Done:
    jmp cpaLoop
    
cpaDone:
    ret
CheckPciSata Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitIde1
;
;       DESCRIPTION:    Start primary IDE
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_ide1_name DB 'Init Ide 1', 0

init_ide1:
    mov dx,1F7h
    in al,dx
    and al,7Fh
    cmp al,7Fh
    je ii1Done
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

ii1Done:
    EndDiscHandler
    TerminateThread


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitIde2
;
;       DESCRIPTION:    Start secondary IDE
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_ide2_name DB 'Init Ide 2', 0

init_ide2:
    mov dx,177h
    in al,dx
    and al,7Fh
    cmp al,7Fh
    je ii2Done
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

ii2Done:
    EndDiscHandler
    TerminateThread


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartPci
;
;       DESCRIPTION:    Start PCI discs
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_pci_name   DB 'Ide Pci ',0
init_pci_name   DB 'Init Pci', 0

init_pci:
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET pci_name_str
    mov si,OFFSET disc_pci_name

ipNameLoop:    
    lods byte ptr cs:[si]
    stosb
    or al,al
    jnz ipNameLoop
;
    dec di
    mov es:pci_curr_ptr,di
    mov al,'0'
    stosb
    mov al,':'
    stosb
    mov es:pci_unit_ptr,di
    mov al,'0'
    stosb
    xor al,al
    stosb
;
    xor bx,bx
    mov cx,es:ide_pci_count
    or cx,cx
    jz ipDone

ipLoop:    
    mov dx,es:[bx].ide_io_arr
    mov ds,es:[bx].ide_pci_arr
;    
    GetThread
    mov es:pci_thread,ax
;       
    mov al,0
    call install_pci_unit
;       
    mov al,1
    call install_pci_unit
    mov es:pci_thread,0
;
    mov di,es:pci_curr_ptr
    inc byte ptr es:[di]
;
    add bx,2
    loop ipLoop

ipDone:
    EndDiscHandler
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_ide
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_ide    Proc far
    push ds
    push es
    push fs
    pusha
;
    mov ax,cs
    mov ds,ax
    mov es,ax

init_ide_primary:
    mov dx,1F7h
    in al,dx
    and al,7Fh
    cmp al,7Fh
    je init_ide_second
;
    mov eax,SIZE ide_data
    mov bx,ide_data_sel1
    AllocateFixedSystemMem
    mov ax,es
    mov ds,ax
    InitSection ds:IdeSection
;       
    mov ds:IdeThread,0
    mov ds:IdeIoBase,0
    mov ds:DriveSelArr,0
    mov ds:DriveSelArr+2,0
;
    mov al,0Eh
    mov ah,12h
    mov bx,ide_data_sel1
    mov ds,bx
    mov bx,cs
    mov es,bx
    mov edi,OFFSET ide_int
    RequestIrqHandler
;
    BeginDiscHandler
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET init_ide1_name
    mov si,OFFSET init_ide1
    mov ax,2
    mov cx,stack0_size
    CreateThread

init_ide_second:
    mov dx,177h
    in al,dx
    and al,7Fh
    cmp al,7Fh
    je init_ide_done
;
    inc bp
;
    mov eax,SIZE ide_data
    mov bx,ide_data_sel2
    AllocateFixedSystemMem
    mov ax,es
    mov ds,ax
    InitSection ds:IdeSection
    mov ds:IdeThread,0
    mov ds:IdeIoBase,0
    mov ds:DriveSelArr,0
    mov ds:DriveSelArr+2,0
;
    mov al,0Fh
    mov ah,12h
    mov bx,ide_data_sel2
    mov ds,bx
    mov bx,cs
    mov es,bx
    mov edi,OFFSET ide_int
    RequestIrqHandler
;
    BeginDiscHandler
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET init_ide2_name
    mov si,OFFSET init_ide2
    mov ax,2
    mov cx,stack0_size
    CreateThread

init_ide_done:
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET get_ide_disc
    mov edi,OFFSET get_ide_disc_name
    xor dx,dx
    mov ax,get_ide_disc_nr
    RegisterBimodalUserGate

init_ide_pci:
    mov ax,SEG data
    mov fs,ax
    mov fs:ide_pci_count,0
;
    call CheckPciIde
    mov ax,ahci_code_sel
    verr ax
    jz init_ide_check_count
;
    call CheckPciSata

init_ide_check_count:    
    mov cx,fs:ide_pci_count
    or cx,cx
    jz init_ide_exit
;    
    BeginDiscHandler
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET init_pci_name
    mov si,OFFSET init_pci
    mov ax,2
    mov cx,stack0_size
    CreateThread

init_ide_exit:
    EndDiscHandler
;
    popa
    pop fs
    pop es
    pop ds
    retf32
init_ide    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_net
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    BeginDiscHandler
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_ide
    HookInitPci
    clc
    ret
init    ENDP

code    ENDS

    END init
