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
; SDCARD.ASM
; SD card driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\drive.inc
INCLUDE ..\os\protseg.def
INCLUDE pci.inc

MAX_SD_DEVICES      = 32
MAX_NAME_SIZE       = 24

REG_SDMA                    = 0
REG_BLOCK_SIZE              = 4
REG_BLOCK_COUNT             = 6
REG_ARG                     = 8
REG_TRANS_MODE              = 0Ch
REG_CMD                     = 0Eh
REG_RESP0                   = 10h
REG_RESP1                   = 14h
REG_RESP2                   = 18h
REG_RESP3                   = 1Ch
REG_BUF                     = 20h
REG_STATE                   = 24h
REG_CONTROL                 = 28h
REG_POWER                   = 29h
REG_CLK_CONTROL             = 2Ch
REG_TIMEOUT                 = 2Eh
REG_RESET                   = 2Fh
REG_INT_STATUS              = 30h
REG_INT_ERROR_STATUS        = 32h
REG_INT_STATUS_ENABLE       = 34h
REG_INT_ERROR_STATUS_ENABLE = 36h
REG_INT_SIG_ENABLE          = 38h
REG_INT_ERROR_SIG_ENABLE    = 3Ah
REG_CAP                     = 40h

sd_device_struc STRUC

sd_reg_sel          DW ?
sd_serv_thread      DW ?
sd_pend_error       DW ?
sd_pend_int         DB ?
sd_pci_bus          DB ?
sd_pci_device       DB ?
sd_pci_function     DB ?

sd_ocr              DD ?
sd_rca              DD ?
sd_total_sectors    DD ?

sd_device_struc ENDS

data    SEGMENT byte public 'DATA'

sd_dev_count   DW ?
sd_dev_arr     DW MAX_SD_DEVICES DUP (?)

serv_name_ptr        DW ?
serv_name_str        DB MAX_NAME_SIZE DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SdInt
;
;       DESCRIPTION:    IRQ handler
;
;       PARAMETERS:     DS      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SdInt  Proc far
    mov es,ds:sd_reg_sel
    mov ax,es:REG_INT_STATUS
    lock or ds:sd_pend_int,al
    mov es:REG_INT_STATUS,ax
;
    test ah,80h
    jz siNoError
;
    mov ax,es:REG_INT_ERROR_STATUS
    lock or ds:sd_pend_error,ax
    mov es:REG_INT_ERROR_STATUS,ax
    
siNoError:    
    and word ptr es:REG_INT_STATUS_ENABLE, NOT 100h    
    mov es:REG_INT_STATUS,al
    or word ptr es:REG_INT_STATUS_ENABLE, 100h
;
    mov bx,ds:sd_serv_thread
    Signal    
    retf32
SdInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddDevice
;
;       DESCRIPTION:    Add an AHCI-device
;
;       PARAMETERS:     FS      Register selector
;                       EDX     Register linear
;                       BH      PCI Bus
;                       BL      PCI Device
;                       CH      PCI Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDevice   Proc near
    push es
    pushad
;
    push ax
    mov eax,SIZE sd_device_struc
    AllocateSmallGlobalMem
    pop ax
    mov es:sd_reg_sel,fs
    mov es:sd_pci_bus,bh
    mov es:sd_pci_device,bl
    mov es:sd_pci_function,ch
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:sd_dev_count
    shl bx,1
    mov ds:[bx].sd_dev_arr,es    
    inc ds:sd_dev_count
;
    popad
    pop es
    ret
AddDevice   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciDev
;
;           DESCRIPTION:    Init PCI SD-card devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPciDev Proc near
    mov ax,SEG data
    mov ds,ax
    mov ds:sd_dev_count,0
;    
    xor si,si

ipdLoop: 
    mov ax,si
    mov bh,8
    mov bl,5
    FindPciClassAll
    jc ipdDone
;
    push cx
    mov eax,1000h
    AllocateBigLinear
    pop cx
;    
    mov cl,PCI_nbr_base_address0
    ReadPciDword
;    
    push eax
    and ax,0F000h
    push ebx
    xor ebx,ebx
    mov al,67h
    SetPageEntry
    pop ebx
    pop eax
;
    and eax,0E00h
    add edx,eax
;        
    push bx
    AllocateGdt
    push cx
    mov ecx,200h
    CreateDataSelector16
    pop cx
    mov fs,bx
    mov byte ptr fs:REG_RESET,1
    pop bx
    call AddDevice
;
    inc si
    jmp ipdLoop

ipdDone:
    ret
InitPciDev  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupInts
;
;           DESCRIPTION:    Setup device ints
;
;           PARAMETERS:     DS     Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts Proc near
    pushad
;    
    mov bh,ds:sd_pci_bus
    mov bl,ds:sd_pci_device
    mov ch,ds:sd_pci_function
    GetPciMsi
    jc siIrq
;    
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc siIrq    
;    
    SetupPciMsi
    mov di,cs
    mov es,di
    mov edi,OFFSET SdInt
    RequestMsiHandler
    jmp siOk

siIrq:
    GetPciIrqNr
    mov ah,14h
    mov di,cs
    mov es,di
    mov edi,OFFSET SdInt
    RequestIrqHandler

siOk:    
    popad
    ret
SetupInts   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetDefaultSdClock
;
;           DESCRIPTION:    Set default SDIO clk rate
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetDefaultSdClock  Proc near
    mov cx,25
    mov eax,fs:REG_CAP
    shr ax,8
    and ax,3Fh
    xor dx,dx
    div cx
;
    or dx,dx
    jz sdscMultOk
;
    inc ax

sdscMultOk:
    xor cl,cl

sdscExpLoop:
    test ax,8000h
    jnz sdscExpOk
;
    shl ax,1
    inc cl
;
    or ax,ax
    jnz sdscExpLoop                

sdscExpOk:
    test ax,7FFFh
    jz sdscWhole
;
    dec cl

sdscWhole:
    mov ax,0FFFFh
    shr ax,cl
    inc ax
    shr ax,2
;
    mov ah,al
    mov al,1
    mov fs:REG_CLK_CONTROL,ax
    mov cx,100    

sdscWait:
    mov ax,1
    WaitMilliSec
;
    mov ax,fs:REG_CLK_CONTROL
    test al,2
    jnz sdscOk
;
    loop sdscWait
;
    stc
    jmp sdscDone

sdscOk:
    or ax,4
    mov fs:REG_CLK_CONTROL,ax       
    clc
    
sdscDone:
    ret
SetDefaultSdClock  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetDataTimeout
;
;           DESCRIPTION:    Set SDIO data timeout
;
;           PARAMETERS:     FS      SD io space
;                           ECX      ms timeout
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetDataTimeout  Proc near
    mov eax,fs:REG_CAP
    mov dx,ax
    and eax,3Fh
    test dl,80h
    jz sdtFreqOk
;
    mov edx,1000
    mul edx

sdtFreqOk:
    mul ecx                
;
    shr eax,13
    xor dl,dl
    or eax,eax
    jz sdtDo

sdtShift:
    inc dl
    shr eax,1
    jnz sdtShift                
;
    cmp dl,0Eh
    jbe sdtDo
;
    mov dl,0Eh

sdtDo:
    mov fs:REG_TIMEOUT,dl    
    ret
SetDataTimeout  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetPower
;
;           DESCRIPTION:    Turn on power
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPower  Proc near
    mov eax,fs:REG_CAP
    mov al,0Eh
    test eax,1000000h
    jnz spDo
;
    mov al,0Ch
    test eax,2000000h    
    jnz spDo
;
    mov al,0Ah

spDo:
    mov ah,fs:REG_POWER
    or ah,al
    mov al,fs:REG_CONTROL
    and al,NOT 9Fh
    mov fs:REG_CONTROL,ax
;
    or ah,1
    mov fs:REG_CONTROL,ax
    clc
    ret
SetPower    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForCompletion
;
;           DESCRIPTION:    Wait for completion
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCompletion   Proc near

wfcWait:
    WaitForSignal
    test ds:sd_pend_error,1FFh
    stc
    jnz wfcDone
;    
    test ds:sd_pend_int,1
    jz wfcWait
;
    clc

wfcDone:    
    ret
WaitForCompletion   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForRead
;
;           DESCRIPTION:    Wait for read data
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForRead   Proc near

wfrWait:
    WaitForSignal
    test ds:sd_pend_error,1FFh
    stc
    jnz wfcDone
;    
    test ds:sd_pend_int,20h
    jz wfrWait
;
    clc

wfrDone:    
    ret
WaitForRead   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendCmd0
;
;           DESCRIPTION:    Send CMD0
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCmd0    Proc near
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
    mov dword ptr fs:REG_ARG,0
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,0
    call WaitForCompletion
    ret
SendCmd0    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendCmd8
;
;           DESCRIPTION:    Send CMD8
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCmd8    Proc near
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
    mov dword ptr fs:REG_ARG,1A5h
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,802h
    call WaitForCompletion
;
    mov eax,fs:REG_RESP0
    cmp eax,1A5h
    clc
    je sc8Done
;
    stc

sc8Done:    
    ret
SendCmd8    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendAcmd41
;
;           DESCRIPTION:    Send ACMD41
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendAcmd41    Proc near
    mov esi,51100000h
    mov eax,fs:REG_CAP
    test eax,1000000h
    jnz sac41HasOcr
;
    mov esi,51040000h
    test eax,2000000h    
    jnz sac41HasOcr
;
    stc
    jmp sac41Done

sac41HasOcr:
    mov cx,100

sac41Retry:    
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
;
    mov dword ptr fs:REG_ARG,0
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,3702h
    call WaitForCompletion
    jc sac41Done
;
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
;    
    mov dword ptr fs:REG_ARG,esi
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,2902h
    call WaitForCompletion
;
    mov eax,fs:REG_RESP0
    test eax,80000000h    
    jnz sac41PowerOk
;
    mov ax,25
    WaitMilliSec
;
    loop sac41Retry
;
    stc
    jmp sac41Done        
    
sac41PowerOk:
    mov ds:sd_ocr,eax
    clc

sac41Done:    
    ret
SendAcmd41    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendCmd2
;
;           DESCRIPTION:    Send CMD2
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCmd2    Proc near
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
    mov dword ptr fs:REG_ARG,0
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,202h
    call WaitForCompletion
    ret
SendCmd2    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendCmd3
;
;           DESCRIPTION:    Send CMD3
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCmd3    Proc near
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
    mov dword ptr fs:REG_ARG,0
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,31Ah
    call WaitForCompletion
    mov eax,fs:REG_RESP0
    xor ax,ax
    mov ds:sd_rca,eax
    ret
SendCmd3    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendCmd9
;
;           DESCRIPTION:    Send CMD9
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCmd9    Proc near
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
;
    mov eax,ds:sd_rca
    mov dword ptr fs:REG_ARG,eax
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,901h
    call WaitForCompletion
    jc sc9Done
;
    mov al,fs:REG_RESP0+0Eh
    cmp al,40h
    jne sc9Fail
;
    mov eax,fs:REG_RESP0+5
    and eax,3FFFFh
    shl eax,10
    mov ds:sd_total_sectors,eax
    clc
    jmp sc9Done
    
sc9Fail:
    stc

sc9Done:        
    ret
SendCmd9    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendCmd7
;
;           DESCRIPTION:    Send CMD7
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCmd7    Proc near
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
;
    mov eax,ds:sd_rca
    mov dword ptr fs:REG_ARG,eax
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,71Ah
    call WaitForCompletion
    jc sc7Done
;
    mov eax,fs:REG_RESP0
    clc
       
sc7Done:
    ret
SendCmd7    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendAcmd6
;
;           DESCRIPTION:    Send ACMD6
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendAcmd6    Proc near
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
;
    mov eax,ds:sd_rca
    mov dword ptr fs:REG_ARG,eax
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,371Ah
    call WaitForCompletion
    jc sac6Done
;
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
;    
    mov dword ptr fs:REG_ARG,4
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,61Ah
    call WaitForCompletion
    jc sac6Done
;
    mov al,fs:REG_CONTROL
    or al,2
    mov fs:REG_CONTROL,al

sac6Done:
    ret
SendAcmd6    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DisconnectPullup
;
;           DESCRIPTION:    Disconnect pullup
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisconnectPullup    Proc near
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
;
    mov eax,ds:sd_rca
    mov dword ptr fs:REG_ARG,eax
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,371Ah
    call WaitForCompletion
    jc dpDone
;
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
;    
    mov dword ptr fs:REG_ARG,0
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,2A1Ah
    call WaitForCompletion

dpDone:
    ret
DisconnectPullup    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPioSector
;
;           DESCRIPTION:    Read sectors using PIO method
;
;           PARAMETERS:     FS      SD io space
;                           EDX     Sector #
;                           ECX     Sector count
;                           ES:EDI  Buffer
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPioSector    Proc near
    push eax
    push ecx
    push edi
;    
    mov fs:REG_BLOCK_COUNT,cx
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
    mov dword ptr fs:REG_ARG,edx
    mov word ptr fs:REG_TRANS_MODE,30h
    mov word ptr fs:REG_CMD,123Ah

rpsSectorLoop:    
    call WaitForRead
    jc rpsDone
;
    mov ds:sd_pend_int,0
    push ecx
    mov ecx,128

rpsLoop:    
    mov eax,fs:REG_BUF
    stos dword ptr es:[edi]
    loop rpsLoop        
;
    pop ecx
    loop rpsSectorLoop    
;
    clc    

rpsDone:
    pop edi
    pop ecx
    pop eax
    ret
ReadPioSector    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitDevice
;
;           DESCRIPTION:    Init device from RESET state
;
;           PARAMETERS:     DS      Device
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitDevice    Proc near
    mov fs,ds:sd_reg_sel
    mov dword ptr fs:REG_BLOCK_SIZE,200h
    mov word ptr fs:REG_INT_STATUS_ENABLE,1FFh
    mov word ptr fs:REG_INT_SIG_ENABLE,1FFh
;
    mov word ptr fs:REG_INT_ERROR_STATUS_ENABLE,3FFh
    mov word ptr fs:REG_INT_ERROR_SIG_ENABLE,3FFh

idOff:
    test dword ptr fs:REG_STATE,10000h
    jnz idInserted
;
    WaitForSignal    
    jmp idOff

idInserted:
    call SetDefaultSdClock
    jc idFailed
;
    call SetPower
    jc idFailed
;
    mov ax,50
    WaitMilliSec
;
    call SendCmd0        
    call SendCmd8
    jc idFailed
;    
    call SendAcmd41
    jc idFailed
;    
    call SendCmd2
    jc idFailed
;    
    call SendCmd3
    jc idFailed
;    
    call SendCmd9
    jc idFailed
;
    call SendCmd7
    jc idFailed
;
    mov ecx,1000
    call SetDataTimeout
    call DisconnectPullup
    clc

idFailed:
    ret
InitDevice  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ServThread
;
;           DESCRIPTION:    SDIO device server thread
;
;           PARAMETERS:     FS      SD device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_thread_name   DB 'SDIO ',0

serv_thread:
    mov ax,fs
    mov ds,ax
    GetThread
    mov ds:sd_serv_thread,ax
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0

stOff:    
    call InitDevice
    jc stFailed
;    
    mov eax,1000h
    AllocateBigLinear
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
;
    mov ecx,1
    xor edx,edx
    call ReadPioSector
    int 3

stFailed: 
    mov byte ptr fs:REG_RESET,1
;    
    WaitForSignal
    test dword ptr fs:REG_STATE,10000h
    jnz stFailed
    jmp stOff       
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupDev
;
;           DESCRIPTION:    Setup device
;
;           PARAMETERS:     DS      Device sel
;                           DL      Device #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDev    Proc near
    mov fs,ds:sd_reg_sel
    mov al,fs:REG_RESET
    and al,1
    jz stdResetOk
;
    mov ax,100
    WaitMilliSec
    mov al,fs:REG_RESET
    and al,1
    jnz stdDone

stdResetOk:
    mov ax,ds
    mov fs,ax
    mov ax,cs
    mov ds,ax
    mov ax,SEG data    
    mov es,ax
;    
    mov al,dl
    add al,'0'
    mov si,es:serv_name_ptr
    mov es:[si],al
    mov edi,OFFSET serv_name_str
    mov esi,OFFSET serv_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
    
stdDone:    
    ret
SetupDev    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartDevices
;
;           DESCRIPTION:    Start SD device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartDevices Proc near
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:sd_dev_count
    mov bx,OFFSET sd_dev_arr
    xor dl,dl
    or cx,cx
    jz sdvDone

sdvLoop:
    push ds
    push bx
    push cx
    push dx
;
    mov ds,ds:[bx]
    call SetupInts
    call SetupDev
;
    pop dx
    pop cx
    pop bx
    pop ds
;
    add bx,2
    inc dl
    loop sdvLoop

sdvDone:
    ret
StartDevices    Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_sd_thread
;
;           DESCRIPTION:    SD init thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_sd_name DB 'SD Card',0

init_sd_thread:
    mov ax,SEG data
    mov ds,ax
    mov es,ax
;    
    mov di,OFFSET serv_name_str
    mov si,OFFSET serv_thread_name

stdNameLoop:    
    lods byte ptr cs:[si]
    stosb
    or al,al
    jnz stdNameLoop
;
    dec di
    mov ds:serv_name_ptr,di
    mov al,'0'
    stosb
    xor al,al
    stosb
;    
    call StartDevices
    TerminateThread
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_sd
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_sd    Proc far
    push ds
    push es
    pusha
;
    call InitPciDev
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET init_sd_name
    mov si,OFFSET init_sd_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    popa
    pop es
    pop ds
    retf32
init_sd    Endp

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
    mov ax,SEG data
    mov ds,ax
;    
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_sd
    HookInitPci
    clc
    ret
init    ENDP

code    ENDS

    END init
