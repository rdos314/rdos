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
REG_CONTROL2                = 3Eh
REG_CAP                     = 40h
REG_VER                     = 0FEh

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

sd_device_struc STRUC

sd_reg_sel          DW ?
sd_serv_thread      DW ?
sd_pend_error       DW ?
sd_pend_int         DB ?
sd_ok               DB ?
sd_pci_bus          DB ?
sd_pci_device       DB ?
sd_pci_function     DB ?

sd_disc_nr          DB ?
sd_disc_sel         DW ?

sd_ocr              DD ?
sd_rca              DD ?
sd_cid              DD ?,?,?,?

sd_cap              DD ?
sd_ver              DW ?
sd_ccc              DW ?

sd_power            DW ?
sd_grp1             DW ?
sd_grp2             DW ?
sd_grp3             DW ?
sd_grp4             DW ?
sd_grp5             DW ?
sd_grp6             DW ?

sd_func1            DB ?
sd_func2            DB ?
sd_func3            DB ?
sd_func4            DB ?
sd_func5            DB ?
sd_func6            DB ?

sd_total_sectors    DD ?
sd_sectors_per_unit DW ?
sd_units            DW ?

sd_device_struc ENDS

SERV_NAME_SIZE = 16

data    SEGMENT byte public 'DATA'

sd_dev_count    DW ?
sd_dev_arr      DW MAX_SD_DEVICES DUP (?)

unit_ptr        DW ?
name_str        DB SERV_NAME_SIZE DUP(?)

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
    cmp al,1
    jne siIrqOk
;
    mov al,10h

siIrqOk:    
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
;           NAME:           SetDefaultSdClock1
;
;           DESCRIPTION:    Set default SDIO clk rate for version 1 controller
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetDefaultSdClock1  Proc near
    mov cx,25
    mov eax,fs:REG_CAP
    shr ax,8
    and ax,3Fh
    xor dx,dx
    div cx
;
    or dx,dx
    jz sdscMultOk1
;
    inc ax

sdscMultOk1:
    xor cl,cl

sdscExpLoop1:
    test ax,8000h
    jnz sdscExpOk1
;
    shl ax,1
    inc cl
;
    or ax,ax
    jnz sdscExpLoop1

sdscExpOk1:
    test ax,7FFFh
    jz sdscWhole1
;
    dec cl

sdscWhole1:
    mov ax,0FFFFh
    shr ax,cl
    inc ax
    shr ax,2
;
    mov ah,al
    mov al,1
    mov fs:REG_CLK_CONTROL,ax
    mov cx,100    

sdscWait1:
    mov ax,1
    WaitMilliSec
;
    mov ax,fs:REG_CLK_CONTROL
    test al,2
    jnz sdscOk1
;
    loop sdscWait1
;
    stc
    jmp sdscDone1

sdscOk1:
    or ax,4
    mov fs:REG_CLK_CONTROL,ax       
    clc
    
sdscDone1:
    ret
SetDefaultSdClock1  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetDefaultSdClock2
;
;           DESCRIPTION:    Set default SDIO clk rate for version 2 controller
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetDefaultSdClock2  Proc near
    mov cx,25
    mov eax,fs:REG_CAP
    shr ax,8
    xor ah,ah
    xor dx,dx
    div cx
;
    xchg al,ah
    shl al,6
    or al,1
    mov fs:REG_CLK_CONTROL,ax
    mov cx,100    

sdscWait2:
    mov ax,1
    WaitMilliSec
;
    mov ax,fs:REG_CLK_CONTROL
    test al,2
    jnz sdscOk2
;
    loop sdscWait2
;
    stc
    jmp sdscDone2

sdscOk2:
    or ax,4
    mov fs:REG_CLK_CONTROL,ax       
    clc
    
sdscDone2:
    ret
SetDefaultSdClock2  Endp

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

SetDefaultSdClock   Proc near
    mov al,fs:REG_VER
    cmp al,2
    jb SetDefaultSdClock1
    je SetDefaultSdClock2
;
    int 3
    stc
    ret    
SetDefaultSdClock   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetSdClock1
;
;           DESCRIPTION:    Set SDIO clk rate for version 1 controller
;
;           PARAMETERS:     FS      SD io space
;                           CX      Clk freq in MHz 
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSdClock1  Proc near
    mov eax,fs:REG_CAP
    shr ax,8
    and ax,3Fh
    xor dx,dx
    div cx
;
    or dx,dx
    jz sscMultOk1
;
    inc ax

sscMultOk1:
    xor cl,cl

sscExpLoop1:
    test ax,8000h
    jnz sscExpOk1
;
    shl ax,1
    inc cl
;
    or ax,ax
    jnz sscExpLoop1

sscExpOk1:
    test ax,7FFFh
    jz sscWhole1
;
    dec cl

sscWhole1:
    mov ax,0FFFFh
    shr ax,cl
    inc ax
    shr ax,2
;
    mov ah,al
    mov al,1
    mov fs:REG_CLK_CONTROL,ax
    mov cx,100    

sscWait1:
    mov ax,1
    WaitMilliSec
;
    mov ax,fs:REG_CLK_CONTROL
    test al,2
    jnz sscOk1
;
    loop sscWait1
;
    stc
    jmp sscDone1

sscOk1:
    or ax,4
    mov fs:REG_CLK_CONTROL,ax       
    clc
    
sscDone1:
    ret
SetSdClock1  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetSdClock2
;
;           DESCRIPTION:    Set SDIO clk rate for version 2 controller
;
;           PARAMETERS:     FS      SD io space
;                           CX      Clk freq in MHz 
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSdClock2  Proc near
    mov eax,fs:REG_CAP
    shr ax,8
    xor ah,ah
    xor dx,dx
    div cx
;
    xchg al,ah
    shl al,6
    or al,1
    mov fs:REG_CLK_CONTROL,ax
    mov cx,100    

sscWait2:
    mov ax,1
    WaitMilliSec
;
    mov ax,fs:REG_CLK_CONTROL
    test al,2
    jnz sscOk2
;
    loop sscWait2
;
    stc
    jmp sscDone2

sscOk2:
    or ax,4
    mov fs:REG_CLK_CONTROL,ax       
    clc
    
sscDone2:
    ret
SetSdClock2  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetSdClock
;
;           DESCRIPTION:    Set default SDIO clk rate
;
;           PARAMETERS:     FS      SD io space
;                           CX      Clk freq in MHz 
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSdClock   Proc near
    mov ax,fs:REG_CLK_CONTROL
    and al,NOT 1
    mov fs:REG_CLK_CONTROL,ax
;    
;    mov al,fs:REG_CONTROL
;    or al,4
;    mov fs:REG_CONTROL,ax
;
    mov al,fs:REG_VER
    cmp al,2
    jb SetSdClock1
    je SetSdClock2
;
    int 3
    stc
    ret    
SetSdClock   Endp

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
;           NAME:           Set8Bit
;
;           DESCRIPTION:    Set 8-bit mode (if supported)
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Set8Bit  Proc near
    mov eax,fs:REG_CAP
    test eax,40000h
    jz s8bDone
;        
    mov al,fs:REG_CONTROL
    or al,20h
    mov fs:REG_CONTROL,al

s8bDone:
    ret
Set8Bit Endp

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
;           NAME:           WaitForTransferComplete
;
;           DESCRIPTION:    Wait for transfer complete
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForTransferComplete   Proc near

wftcWait:
    WaitForSignal
    test ds:sd_pend_error,1FFh
    stc
    jnz wftcDone
;    
    test ds:sd_pend_int,2
    jz wftcWait
;
    clc

wftcDone:    
    ret
WaitForTransferComplete   Endp

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
    mov dword ptr fs:REG_ARG,1AAh
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,802h
    call WaitForCompletion
;
    mov eax,fs:REG_RESP0
    cmp eax,1AAh
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
;                           EAX     OCR
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendAcmd41    Proc near
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
    mov dword ptr fs:REG_ARG,eax
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,2902h
    call WaitForCompletion
    mov eax,fs:REG_RESP0

sac41Done:
    ret
SendAcmd41    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendCmd11
;
;           DESCRIPTION:    Send CMD11
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCmd11    Proc near
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
    mov dword ptr fs:REG_ARG,0
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,1102h
    call WaitForCompletion
    ret
SendCmd11    Endp

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
    mov word ptr fs:REG_CMD,209h
    call WaitForCompletion
    jc sc2Done
;    
    mov eax,fs:REG_RESP0
    mov ds:sd_cid,eax
    mov eax,fs:REG_RESP1
    mov ds:sd_cid+4,eax
    mov eax,fs:REG_RESP2
    mov ds:sd_cid+8,eax
    mov eax,fs:REG_RESP3
    mov ds:sd_cid+12,eax
    clc

sc2Done:    
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
;           NAME:           SwitchFunction
;
;           DESCRIPTION:    Switch function
;
;           PARAMETERS:     FS      SD io space
;                           BX      Group
;                           AL      Value
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SwitchFunction    Proc near
    push eax
    push ebx
    push ecx
    push edx
;    
    mov cl,bl
    and cl,7
    shl cl,4
    mov edx,0Fh
    shl edx,cl
    movzx eax,al
    shl eax,cl
    not edx
    and edx,0FFFFFFh
    or eax,edx
    or eax,80000000h
;
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
    mov dword ptr fs:REG_ARG,eax
    mov word ptr fs:REG_TRANS_MODE,0
    mov word ptr fs:REG_CMD,61Ah
    call WaitForCompletion
;    
    mov eax,fs:REG_RESP0
    and eax,edx
    shr eax,cl
    and al,0Fh
;
    pop edx
    pop ecx
    pop ebx
    pop eax    
    ret
SwitchFunction    Endp

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
    mov ds:sd_ccc,0
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
;
    mov ax,fs:REG_RESP0+9
    shr ax,4
    mov ds:sd_ccc,ax
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
    mov dword ptr fs:REG_ARG,2
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
;           NAME:           GetOcr
;
;           DESCRIPTION:    Get OCR
;
;           PARAMETERS:     FS      SD io space
;
;           RETURNS:        EAX     OCR
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetOcr    Proc near
    xor eax,eax
    call SendAcmd41
    jc goDone
;
    mov ds:sd_ocr,eax

goDone:    
    ret
GetOcr    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SelectVoltage
;
;           DESCRIPTION:    Select voltage
;
;           PARAMETERS:     FS      SD io space
;                           EAX     OCR detected
;
;           RETURNS:        EAX     OCR to setup
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SelectVoltage    Proc near
    mov edx,eax
    and edx,0FFFF80h
    stc
    jz svDone
;    
    mov ecx,fs:REG_CAP
    test ecx,2000000h
    jnz sv30Ok
;
    and edx,0F80000h

sv30Ok:    
    mov cx,31

svLoop:    
    test edx,80000000h
    jnz svBitOk
;
    shl edx,1
    loop svLoop    

svBitOk:
    dec cl
    mov edx,3
    shl edx,cl
    and eax,edx
    clc

svDone:
    ret
SelectVoltage   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetOcr
;
;           DESCRIPTION:    Set OCR
;
;           PARAMETERS:     FS      SD io space
;                           EAX     OCR
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetOcr    Proc near
    mov esi,eax
;    
    mov edx,50000000h
    mov eax,fs:REG_CAP+4
    test al,7
    jz soUhs1Done
;
    mov edx,51000000h

soUhs1Done:
    or esi,edx

soHasOcr:
    mov cx,100

soRetry:    
    mov eax,esi
    call SendAcmd41
    jc soDone
;    
    test eax,80000000h    
    jnz soPowerOk
;
    mov ax,10
    WaitMilliSec
;
    loop soRetry
;
    stc
    jmp soDone        
    
soPowerOk:
    mov ds:sd_ocr,eax
    clc

soDone:    
    ret
SetOcr    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCmd6Par
;
;           DESCRIPTION:    Get cmd6 params
;
;           PARAMETERS:     FS      SD io space
;                           DS      Device
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCmd6Par  Proc near
    push eax
    push ecx
;    
    mov eax,fs:REG_BUF
    xchg al,ah
    mov ds:sd_power,ax
    shr eax,16
    xchg al,ah
    mov ds:sd_grp6,ax
;    
    mov eax,fs:REG_BUF
    xchg al,ah
    mov ds:sd_grp5,ax
    shr eax,16
    xchg al,ah
    mov ds:sd_grp4,ax
;    
    mov eax,fs:REG_BUF
    xchg al,ah
    mov ds:sd_grp3,ax
    shr eax,16
    xchg al,ah
    mov ds:sd_grp2,ax
;
    mov eax,fs:REG_BUF
    xchg al,ah
    mov ds:sd_grp1,ax
    shr eax,16
    mov cl,al
    and cl,0Fh
    mov ds:sd_func3,cl
    mov cl,al
    shr cl,4
    and cl,0Fh
    mov ds:sd_func4,cl
;    
    mov cl,ah
    and cl,0Fh
    mov ds:sd_func5,cl
    mov cl,ah
    shr cl,4
    and cl,0Fh
    mov ds:sd_func6,cl
;
    mov eax,fs:REG_BUF
    mov cl,al
    and cl,0Fh
    mov ds:sd_func1,cl
    mov cl,al
    shr cl,4
    and cl,0Fh
    mov ds:sd_func2,cl
;
    pop ecx
    pop eax
    ret
GetCmd6Par  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           QueryCmd6
;
;           DESCRIPTION:    Query CMD6
;
;           PARAMETERS:     FS      SD io space
;                           DS      Device
;                           EAX     Function selection
;
;           RETURNS:        EAX     Resp0
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QueryCmd6    Proc near
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
    mov dword ptr fs:REG_ARG,eax
    mov word ptr fs:REG_TRANS_MODE,10h
    mov word ptr fs:REG_CMD,63Ah
    WaitForSignal
    call GetCmd6Par
    mov eax,fs:REG_RESP0
    ret
QueryCmd6   Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetCmd6
;
;           DESCRIPTION:    Set CMD6
;
;           PARAMETERS:     FS      SD io space
;                           DS      Device
;                           EAX     Function selection
;
;           RETURNS:        EAX     Resp0
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetCmd6    Proc near
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
    or eax,80000000h
    mov dword ptr fs:REG_ARG,eax
    mov word ptr fs:REG_TRANS_MODE,10h
    mov word ptr fs:REG_CMD,63Ah
    WaitForSignal
    call GetCmd6Par
    mov eax,fs:REG_RESP0
    ret
SetCmd6   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCmd6Func
;
;           DESCRIPTION:    Get cmd6 function selected
;
;           PARAMETERS:     FS      SD io space
;                           DS      Device
;
;           RETURNS:        EAX     Function selected
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCmd6Func    Proc near
    push cx
;    
    xor eax,eax
    mov al,ds:sd_func6
    shl al,4
    or al,ds:sd_func5
    shl eax,8
;
    mov al,ds:sd_func4
    shl al,4
    or al,ds:sd_func3
    shl eax,8
;
    mov al,ds:sd_func2
    shl al,4
    or al,ds:sd_func1
;
    pop cx
    ret
GetCmd6Func Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHighSpeed
;
;           DESCRIPTION:    Set high speed
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetHighSpeed    Proc near
    mov ax,ds:sd_ccc
    test ax,400h
    stc
    jz shsDone
;    
    mov eax,fs:REG_CAP
    test eax,200000h
    stc
    jz shsDone
;    
    mov eax,0FF0001h
    call QueryCmd6
    mov ax,10
    WaitMilliSec
    call GetCmd6Func
;    
    mov eax,0FF0001h
    call SetCmd6
    mov ax,10
    WaitMilliSec
    call GetCmd6Func
    cmp eax,1
    stc
    jne shsDone
;
    clc

shsDone:    
    ret
SetHighSpeed    Endp

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
    mov word ptr fs:REG_TRANS_MODE,36h
    mov word ptr fs:REG_CMD,123Ah

rpsSectorLoop:    
    test word ptr fs:REG_STATE,800h
    jnz rpsDo
;    
    WaitForSignal
    test ds:sd_pend_error,1FFh
    jz rpsSectorLoop
;    
    stc   
    jmp rpsDone

rpsDo:
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
;           NAME:           WritePioSector
;
;           DESCRIPTION:    Write sectors using PIO method
;
;           PARAMETERS:     FS      SD io space
;                           EDX     Sector #
;                           ECX     Sector count
;                           ES:EDI  Buffer
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePioSector    Proc near
    push eax
    push ecx
    push edi
;    
    mov fs:REG_BLOCK_COUNT,cx
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
    mov dword ptr fs:REG_ARG,edx
    mov word ptr fs:REG_TRANS_MODE,26h
    mov word ptr fs:REG_CMD,193Ah

wpsSectorLoop:    
    test word ptr fs:REG_STATE,400h
    jnz wpsDo
;    
    WaitForSignal
    test ds:sd_pend_error,1FFh
    jz wpsSectorLoop
;    
    stc   
    jmp wpsDone

wpsDo:
    mov ds:sd_pend_int,0
    push ecx
    mov ecx,128

wpsLoop: 
    mov eax,es:[edi]
    mov fs:REG_BUF,eax
    add edi,4
    loop wpsLoop        
;
    pop ecx
    loop wpsSectorLoop    
;
    call WaitForTransferComplete

wpsDone:
    pop edi
    pop ecx
    pop eax
    ret
WritePioSector    Endp

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
    mov eax,fs:REG_CAP
    mov ds:sd_cap,eax
    movzx ax,byte ptr fs:REG_VER
    mov ds:sd_ver,ax
;
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
    jmp idFailed

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
;
    mov ax,ds:sd_ver
    cmp ax,2
    jb idOcr
;    
    call SendCmd8

idOcr:    
    call GetOcr
    jc idFailed
;
    call SelectVoltage
    jc idFailed
;
    mov ds:sd_ocr,eax
;
    call SendCmd8
    jc idFailed
;
    mov eax,ds:sd_ocr
    call SetOcr    
;
    test ds:sd_ocr,01000000h
    jz idVoltOk
;
    mov ax,fs:REG_CONTROL2
    or ax,8
    mov fs:REG_CONTROL2,ax
;
    call SendCmd11    
    jc idFailed
;    
    mov ax,100
    WaitMilliSec

idVoltOk:
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
    mov ax,ds:sd_ver
    cmp ax,2
    jb idSpeedDone
;
    call SendAcmd6

idSpeedDone:
    mov ax,ds:sd_ccc
    and ax,14h
    cmp ax,14h
    jne idFailed
;    
    call SetHighSpeed
    jc idNoHs
;
    mov cx,50
    call SetSdClock
    
idNoHs:    
    mov ecx,1000
    call SetDataTimeout
    call DisconnectPullup
;    
    mov ax,100
    WaitMilliSec
    clc
    jmp idDone

idFailed:
    mov ds:sd_ok,0

idDone:
    ret
InitDevice  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       read_drive
;
;       DESCRIPTION:    Read drive
;
;       PARAMETERS:     DS      Device sel
;                       FS      IO sel
;                       ESI     Disc handle array
;                       ECX     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_drive      Proc near

read_drive_loop:
    mov edx,es:[edi].dh_unit
    movzx eax,ds:sd_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
;    
    push ecx
    push edi
    mov ecx,1
    mov edi,es:[edi].dh_data
    call ReadPioSector
    pop edi
    pop ecx
    jnc read_drive_ok

read_drive_fail:
    int 3
    mov es:[edi].dh_state,STATE_BAD
    mov bx,ds:sd_disc_sel
    DiscRequestCompleted
;
    add esi,4
    mov edi,es:[esi]
    sub cx,1
    jnz read_drive_loop
    jmp read_drive_done

read_drive_ok:
    mov eax,es:[edi].dh_data
    mov es:[edi].dh_state,STATE_USED
    mov bx,ds:sd_disc_sel
    DiscRequestCompleted
;
    add esi,4
    mov edi,es:[esi]
    sub cx,1
    jnz read_drive_loop

read_drive_done:
    ret
read_drive      Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       write_drive
;
;       DESCRIPTION:    Perform a write request
;
;       PARAMETERS:     DS      Device sel
;                       FS      IO sel
;                       ESI     Disc handle array
;                       ECX     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive     Proc near
    mov edi,es:[esi]

write_drive_loop:
    mov ebp,1
    mov edx,es:[edi].dh_unit
    movzx eax,ds:sd_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov ebx,eax

write_drive_more:
    cmp ecx,ebp
    jbe write_drive_do
;
    mov edx,es:[edi].dh_data
    add edx,200h
;
    mov eax,ebp
    shl eax,2
    mov edi,es:[esi+eax]
;
    cmp edx,es:[edi].dh_data
    jnz write_drive_do
;    
    mov edx,es:[edi].dh_unit
    movzx eax,ds:sd_sectors_per_unit
    mul edx
    movzx edx,es:[edi].dh_sector
    add eax,edx
    inc ebx
    cmp eax,ebx
    jne write_drive_do
;
    inc ebp
    jmp write_drive_more        

write_drive_do:    
    mov edi,es:[esi]
    mov edx,es:[edi].dh_unit
    movzx eax,ds:sd_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
;
    push ecx
    mov ecx,ebp
    mov edi,es:[edi].dh_data
    call WritePioSector    
    pop ecx
    mov edi,es:[esi]
    jnc write_drive_ok

write_drive_fail:
    int 3
    mov edi,es:[esi]
    mov es:[edi].dh_state,STATE_BAD
    mov bx,ds:sd_disc_sel
    DiscRequestCompleted
    add esi,4
    dec cx
    sub bp,1
    jnz write_drive_fail
;
    or cx,cx
    jnz write_drive_loop
    jmp write_drive_done

write_drive_ok:
    mov edi,es:[esi]
    mov es:[edi].dh_state,STATE_USED
    mov bx,ds:sd_disc_sel
    DiscRequestCompleted
    add esi,4
    dec cx
    sub bp,1
    jnz write_drive_ok
;
    or cx,cx
    jnz write_drive_loop

write_drive_done:
    ret
write_drive     Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       perform_one
;
;       DESCRIPTION:    Perform one request
;
;       PARAMETERS:     DS      Device sel
;                       FS      IO sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_one     Proc near

perform_one_loop:
    GetThread
    mov ds:sd_serv_thread,ax
;
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
;       PARAMETERS:     FS      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

discbuf_thread:
    mov ax,fs
    mov ds,ax
    mov fs,ds:sd_reg_sel    
    mov ax,flat_sel
    mov es,ax
    mov bx,ds:sd_disc_sel

discbuf_thread_loop:
    WaitForDiscRequest    
    call perform_one
    jmp discbuf_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       CalcParam
;
;       DESCRIPTION:    Calculate various parameters
;
;       PARAMETERS:     DS      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcParam       Proc near
    pushad
;
    mov eax,1
    mov edx,ds:sd_total_sectors

calc_param_norm_loop:
    shl eax,1
    shr edx,1
    cmp eax,edx
    jc calc_param_norm_loop
;
    mov esi,edx
    mov ebx,esi
    mov ecx,edx

calc_param_chs_loop:
    xor edx,edx
    mov eax,ds:sd_total_sectors
    div esi
    cmp ecx,edx
    jc calc_param_chs_next
;       
    mov ecx,edx
    mov ebx,esi
    or edx,edx
    jz calc_param_chs_ok

calc_param_chs_next:
    inc esi
    cmp esi,eax
    jbe calc_param_chs_loop
;
    xor edx,edx
    mov eax,ds:sd_total_sectors
    div ebx

calc_param_chs_ok:
    mov edx,eax
    mov eax,ebx
;
    mov ds:sd_sectors_per_unit,ax
    mov ds:sd_units,dx
    mul dx
    push dx
    push ax
    pop ds:sd_total_sectors
;
    popad
    ret
CalcParam       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Install unit
;
;       PARAMETERS:     AL      UNIT #
;                       DS      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddHex  Proc near
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ahLow
;
    add al,7

ahLow:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ahHigh
;    
    add ah,7

ahHigh:
    add ah,30h
    stosw
    ret
AddHex  Endp

AddDec  Proc near
    push cx
    push dx
;   
    xor dx,dx 
    mov cx,1000
    div cx
    add al,30h
    stosb
;
    mov ax,dx
    xor dx,dx 
    mov cx,100
    div cx
    add al,30h
    stosb    
;
    mov ax,dx
    xor dx,dx 
    mov cx,10
    div cx
    add al,30h
    stosb
;
    mov al,dl
    add al,30h
    stosb
;        
    pop dx
    pop cx
    ret
AddDec  Endp    

InstallUnit    Proc near
    push gs
    pushad
;    
    mov bx,SEG data
    mov gs,bx
    mov bx,gs:unit_ptr
    add al,'0'
    mov gs:[bx],al
;
    mov bx,ds
    mov ecx,10000h
    InstallDisc    
    mov ds:sd_disc_nr,al
    mov ds:sd_disc_sel,bx
;
    call CalcParam
    mov ax,ds:sd_sectors_per_unit
    movzx edx,ds:sd_units
    mov cx,512
    mov si,-1
    mov di,-1
    mov bx,ds:sd_disc_sel
    SetDiscParam
;
    push es
    push edi
;   
    GetDiscVendorInfoBuf
    
    mov al,'S'
    stosb
    mov al,'D'
    stosb
    mov al,':'
    stosb
;
    mov al,byte ptr ds:sd_cid+11
    stosb
    mov al,byte ptr ds:sd_cid+10
    stosb
    mov al,byte ptr ds:sd_cid+9
    stosb
    mov al,byte ptr ds:sd_cid+8
    stosb
    mov al,byte ptr ds:sd_cid+7
    stosb
;
    mov al,'-'
    stosb    
;
    mov al,byte ptr ds:sd_cid+6
    shr al,4
    and al,0Fh
    add al,30h    
    stosb
;
    mov al,'.'
    stosb    
;
    mov al,byte ptr ds:sd_cid+6
    and al,0Fh
    add al,30h    
    stosb
;
    mov al,byte ptr ds:sd_cid+14
    or al,al
    jz iuMidOk
;
    mov al,';'
    stosb        
    mov al,'M'
    stosb        
    mov al,'I'
    stosb        
    mov al,'D'
    stosb        
    mov al,':'
    stosb        
;
    mov al,byte ptr ds:sd_cid+14
    call AddHex

iuMidOk:
    mov al,byte ptr ds:sd_cid+13
    or al,al
    jz iuOidOk
;
    mov al,';'
    stosb
    mov al,'O'
    stosb
    mov al,'I'
    stosb
    mov al,'D'
    stosb
    mov al,':'
    stosb
;
    mov al,byte ptr ds:sd_cid+13
    stosb
;    
    mov al,byte ptr ds:sd_cid+12
    or al,al
    jz iuOidOk
;
    stosb

iuOidOk:
    mov al,';'
    stosb
    mov al,'S'
    stosb
    mov al,'E'
    stosb
    mov al,'R'
    stosb
    mov al,':'
    stosb
;
    mov al,byte ptr ds:sd_cid+5
    call AddHex    
;
    mov al,byte ptr ds:sd_cid+4
    call AddHex    
;
    mov al,byte ptr ds:sd_cid+3
    call AddHex    
;
    mov al,byte ptr ds:sd_cid+2
    call AddHex    
;
    mov al,';'
    stosb
    mov al,'D'
    stosb
    mov al,'A'
    stosb
    mov al,'T'
    stosb
    mov al,'E'
    stosb
    mov al,':'
    stosb
;
    mov ax,word ptr ds:sd_cid
    shr ax,4
    add ax,2000
    call AddDec
;
    mov al,'-'
    stosb
;    
    mov al,byte ptr ds:sd_cid
    and al,0Fh
    cmp al,10
    jb iuLowMonth
;
    mov al,'1'
    stosb
    mov al,byte ptr ds:sd_cid
    and al,0Fh
    sub al,10
    add al,'0'
    stosb
    jmp iuMonthOk

iuLowMonth:
    mov al,'0'
    stosb
    mov al,byte ptr ds:sd_cid
    and al,0Fh
    add al,'0'
    stosb

iuMonthOk:    
    xor al,al
    stosb
;
    pop edi
    pop es   
;
    push ds
    push es
    push fs
;    
    mov ax,ds
    mov fs,ax
    mov ax,cs
    mov ds,ax
;
    mov ax,SEG data    
    mov es,ax
    mov di,OFFSET name_str
    mov si,OFFSET discbuf_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    pop fs    
    pop es
    pop ds
    clc
;
    popad
    pop gs
    ret
InstallUnit    Endp
    
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
    mov ds:sd_ok,1
    mov fs,ds:sd_reg_sel
    mov al,fs:REG_RESET
    and al,1
    clc
    jz stdDone
;
    mov ds:sd_ok,0
    stc
    
stdDone:    
    ret
SetupDev    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartAllDevices
;
;           DESCRIPTION:    Start all SD devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartAllDevices Proc near
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:sd_dev_count
    mov bx,OFFSET sd_dev_arr
    xor dl,dl
    or cx,cx
    jz sadvDone

sadvLoop:
    push ds
    push bx
    push cx
    push dx
;
    mov ds,ds:[bx]
    GetThread
    mov ds:sd_serv_thread,ax    
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
    loop sadvLoop

sadvDone:
    ret
StartAllDevices    Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitAllDevices
;
;           DESCRIPTION:    Init all SD devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitAllDevices Proc near
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:sd_dev_count
    mov bx,OFFSET sd_dev_arr
    xor dl,dl
    or cx,cx
    jz iadvDone

iadvLoop:
    push ds
    push bx
    push cx
    push dx
;
    mov ds,ds:[bx]
    mov al,ds:sd_ok
    or al,al
    jz iadvNext
;    
    call InitDevice

iadvNext:
    pop dx
    pop cx
    pop bx
    pop ds
;
    add bx,2
    inc dl
    loop iadvLoop

iadvDone:
    ret
InitAllDevices    Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InstallAllDevices
;
;           DESCRIPTION:    Install all SD devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallAllDevices Proc near
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:sd_dev_count
    mov bx,OFFSET sd_dev_arr
    xor dl,dl
    or cx,cx
    jz iadDone

iadLoop:
    push ds
    push bx
    push cx
    push dx
    push edi
;
    mov ds,ds:[bx]
    mov al,ds:sd_ok
    or al,al
    jz iadNext
;    
    mov ax,bx
    sub ax,OFFSET sd_dev_arr
    shr ax,1
    call InstallUnit

iadNext:
    pop edi
    pop dx
    pop cx
    pop bx
    pop ds
;
    add bx,2
    inc dl
    loop iadLoop

iadDone:
    ret
InstallAllDevices    Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       DISC_ASSIGN
;
;       DESCRIPTION:    Assign SD discs
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_name   DB 'SDIO ',0

disc_assign    Proc far
    mov ax,SEG data
    mov es,ax
    mov di,OFFSET name_str
    mov si,OFFSET disc_name

disc_assign_name_loop:    
    lods byte ptr cs:[si]
    stosb
    or al,al
    jnz disc_assign_name_loop
;
    dec di
    mov es:unit_ptr,di
    mov al,'0'
    stosb
    xor al,al
    stosb
;
    call StartAllDevices
    call InitAllDevices
    call InstallAllDevices
    retf32
disc_assign    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InstallPartition
;
;   DESCRIPTION:    Install partition
;
;   PARAMETERS:     DS      Device sel
;                   ES      FLAT_SEL
;                   FS      Device op sel
;                   CL      PARTITION TYPE
;                   EDX     START SECTOR
;                   EAX     NUMBER OF SECTORS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fs_unknown      DB 'UNKNOWN '
fs_fat12    DB 'FAT12   '
fs_fat16    DB 'FAT16   '
fs_fat32    DB 'FAT32   '
fs_hpfs     DB 'HPFS    '
fs_rdfs     DB 'RDFS    '
fs_flashfs  DB 'FLASHFS '

FsTab:
fs00    DW OFFSET fs_unknown
fs01    DW OFFSET fs_fat12
fs02    DW OFFSET fs_unknown
fs03    DW OFFSET fs_unknown
fs04    DW OFFSET fs_fat16
fs05    DW OFFSET fs_unknown
fs06    DW OFFSET fs_fat16
fs07    DW OFFSET fs_hpfs
fs08    DW OFFSET fs_unknown
fs09    DW OFFSET fs_unknown
fs0A    DW OFFSET fs_unknown
fs0B    DW OFFSET fs_fat32
fs0C    DW OFFSET fs_fat32
fs0D    DW OFFSET fs_unknown
fs0E    DW OFFSET fs_unknown
fs0F    DW OFFSET fs_unknown
fs10    DW OFFSET fs_unknown
fs11    DW OFFSET fs_unknown
fs12    DW OFFSET fs_unknown
fs13    DW OFFSET fs_unknown
fs14    DW OFFSET fs_unknown
fs15    DW OFFSET fs_unknown
fs16    DW OFFSET fs_unknown
fs17    DW OFFSET fs_unknown
fs18    DW OFFSET fs_unknown
fs19    DW OFFSET fs_unknown
fs1A    DW OFFSET fs_unknown
fs1B    DW OFFSET fs_unknown
fs1C    DW OFFSET fs_unknown
fs1D    DW OFFSET fs_unknown
fs1E    DW OFFSET fs_unknown
fs1F    DW OFFSET fs_unknown
fs20    DW OFFSET fs_unknown
fs21    DW OFFSET fs_unknown
fs22    DW OFFSET fs_unknown
fs23    DW OFFSET fs_unknown
fs24    DW OFFSET fs_unknown
fs25    DW OFFSET fs_unknown
fs26    DW OFFSET fs_unknown
fs27    DW OFFSET fs_unknown
fs28    DW OFFSET fs_unknown
fs29    DW OFFSET fs_unknown
fs2A    DW OFFSET fs_unknown
fs2B    DW OFFSET fs_unknown
fs2C    DW OFFSET fs_unknown
fs2D    DW OFFSET fs_unknown
fs2E    DW OFFSET fs_unknown
fs2F    DW OFFSET fs_unknown
fs30    DW OFFSET fs_unknown
fs31    DW OFFSET fs_unknown
fs32    DW OFFSET fs_unknown
fs33    DW OFFSET fs_unknown
fs34    DW OFFSET fs_unknown
fs35    DW OFFSET fs_unknown
fs36    DW OFFSET fs_unknown
fs37    DW OFFSET fs_unknown
fs38    DW OFFSET fs_unknown
fs39    DW OFFSET fs_unknown
fs3A    DW OFFSET fs_unknown
fs3B    DW OFFSET fs_unknown
fs3C    DW OFFSET fs_unknown
fs3D    DW OFFSET fs_unknown
fs3E    DW OFFSET fs_unknown
fs3F    DW OFFSET fs_unknown
fs40    DW OFFSET fs_unknown
fs41    DW OFFSET fs_unknown
fs42    DW OFFSET fs_unknown
fs43    DW OFFSET fs_unknown
fs44    DW OFFSET fs_unknown
fs45    DW OFFSET fs_unknown
fs46    DW OFFSET fs_unknown
fs47    DW OFFSET fs_unknown
fs48    DW OFFSET fs_unknown
fs49    DW OFFSET fs_unknown
fs4A    DW OFFSET fs_unknown
fs4B    DW OFFSET fs_unknown
fs4C    DW OFFSET fs_unknown
fs4D    DW OFFSET fs_unknown
fs4E    DW OFFSET fs_unknown
fs4F    DW OFFSET fs_unknown
fs50    DW OFFSET fs_unknown
fs51    DW OFFSET fs_unknown
fs52    DW OFFSET fs_unknown
fs53    DW OFFSET fs_unknown
fs54    DW OFFSET fs_unknown
fs55    DW OFFSET fs_unknown
fs56    DW OFFSET fs_unknown
fs57    DW OFFSET fs_unknown
fs58    DW OFFSET fs_unknown
fs59    DW OFFSET fs_unknown
fs5A    DW OFFSET fs_unknown
fs5B    DW OFFSET fs_unknown
fs5C    DW OFFSET fs_unknown
fs5D    DW OFFSET fs_unknown
fs5E    DW OFFSET fs_unknown
fs5F    DW OFFSET fs_unknown
fs60    DW OFFSET fs_unknown
fs61    DW OFFSET fs_unknown
fs62    DW OFFSET fs_unknown
fs63    DW OFFSET fs_unknown
fs64    DW OFFSET fs_unknown
fs65    DW OFFSET fs_unknown
fs66    DW OFFSET fs_unknown
fs67    DW OFFSET fs_unknown
fs68    DW OFFSET fs_unknown
fs69    DW OFFSET fs_unknown
fs6A    DW OFFSET fs_unknown
fs6B    DW OFFSET fs_unknown
fs6C    DW OFFSET fs_unknown
fs6D    DW OFFSET fs_unknown
fs6E    DW OFFSET fs_unknown
fs6F    DW OFFSET fs_unknown
fs70    DW OFFSET fs_unknown
fs71    DW OFFSET fs_unknown
fs72    DW OFFSET fs_unknown
fs73    DW OFFSET fs_unknown
fs74    DW OFFSET fs_unknown
fs75    DW OFFSET fs_unknown
fs76    DW OFFSET fs_unknown
fs77    DW OFFSET fs_unknown
fs78    DW OFFSET fs_unknown
fs79    DW OFFSET fs_unknown
fs7A    DW OFFSET fs_unknown
fs7B    DW OFFSET fs_unknown
fs7C    DW OFFSET fs_unknown
fs7D    DW OFFSET fs_unknown
fs7E    DW OFFSET fs_unknown
fs7F    DW OFFSET fs_unknown
fs80    DW OFFSET fs_unknown
fs81    DW OFFSET fs_unknown
fs82    DW OFFSET fs_unknown
fs83    DW OFFSET fs_unknown
fs84    DW OFFSET fs_unknown
fs85    DW OFFSET fs_unknown
fs86    DW OFFSET fs_unknown
fs87    DW OFFSET fs_unknown
fs88    DW OFFSET fs_unknown
fs89    DW OFFSET fs_unknown
fs8A    DW OFFSET fs_unknown
fs8B    DW OFFSET fs_unknown
fs8C    DW OFFSET fs_unknown
fs8D    DW OFFSET fs_unknown
fs8E    DW OFFSET fs_unknown
fs8F    DW OFFSET fs_unknown
fs90    DW OFFSET fs_unknown
fs91    DW OFFSET fs_unknown
fs92    DW OFFSET fs_unknown
fs93    DW OFFSET fs_unknown
fs94    DW OFFSET fs_unknown
fs95    DW OFFSET fs_unknown
fs96    DW OFFSET fs_unknown
fs97    DW OFFSET fs_unknown
fs98    DW OFFSET fs_unknown
fs99    DW OFFSET fs_unknown
fs9A    DW OFFSET fs_unknown
fs9B    DW OFFSET fs_unknown
fs9C    DW OFFSET fs_unknown
fs9D    DW OFFSET fs_unknown
fs9E    DW OFFSET fs_unknown
fs9F    DW OFFSET fs_unknown
fsA0    DW OFFSET fs_unknown
fsA1    DW OFFSET fs_unknown
fsA2    DW OFFSET fs_unknown
fsA3    DW OFFSET fs_unknown
fsA4    DW OFFSET fs_unknown
fsA5    DW OFFSET fs_unknown
fsA6    DW OFFSET fs_unknown
fsA7    DW OFFSET fs_unknown
fsA8    DW OFFSET fs_unknown
fsA9    DW OFFSET fs_unknown
fsAA    DW OFFSET fs_unknown
fsAB    DW OFFSET fs_unknown
fsAC    DW OFFSET fs_unknown
fsAD    DW OFFSET fs_unknown
fsAE    DW OFFSET fs_rdfs
fsAF    DW OFFSET fs_flashfs
fsB0    DW OFFSET fs_unknown
fsB1    DW OFFSET fs_unknown
fsB2    DW OFFSET fs_unknown
fsB3    DW OFFSET fs_unknown
fsB4    DW OFFSET fs_unknown
fsB5    DW OFFSET fs_unknown
fsB6    DW OFFSET fs_unknown
fsB7    DW OFFSET fs_unknown
fsB8    DW OFFSET fs_unknown
fsB9    DW OFFSET fs_unknown
fsBA    DW OFFSET fs_unknown
fsBB    DW OFFSET fs_unknown
fsBC    DW OFFSET fs_unknown
fsBD    DW OFFSET fs_unknown
fsBE    DW OFFSET fs_unknown
fsBF    DW OFFSET fs_unknown
fsC0    DW OFFSET fs_unknown
fsC1    DW OFFSET fs_unknown
fsC2    DW OFFSET fs_unknown
fsC3    DW OFFSET fs_unknown
fsC4    DW OFFSET fs_unknown
fsC5    DW OFFSET fs_unknown
fsC6    DW OFFSET fs_unknown
fsC7    DW OFFSET fs_unknown
fsC8    DW OFFSET fs_unknown
fsC9    DW OFFSET fs_unknown
fsCA    DW OFFSET fs_unknown
fsCB    DW OFFSET fs_unknown
fsCC    DW OFFSET fs_unknown
fsCD    DW OFFSET fs_unknown
fsCE    DW OFFSET fs_unknown
fsCF    DW OFFSET fs_unknown
fsD0    DW OFFSET fs_unknown
fsD1    DW OFFSET fs_unknown
fsD2    DW OFFSET fs_unknown
fsD3    DW OFFSET fs_unknown
fsD4    DW OFFSET fs_unknown
fsD5    DW OFFSET fs_unknown
fsD6    DW OFFSET fs_unknown
fsD7    DW OFFSET fs_unknown
fsD8    DW OFFSET fs_unknown
fsD9    DW OFFSET fs_unknown
fsDA    DW OFFSET fs_unknown
fsDB    DW OFFSET fs_unknown
fsDC    DW OFFSET fs_unknown
fsDD    DW OFFSET fs_unknown
fsDE    DW OFFSET fs_unknown
fsDF    DW OFFSET fs_unknown
fsE0    DW OFFSET fs_unknown
fsE1    DW OFFSET fs_unknown
fsE2    DW OFFSET fs_unknown
fsE3    DW OFFSET fs_unknown
fsE4    DW OFFSET fs_unknown
fsE5    DW OFFSET fs_unknown
fsE6    DW OFFSET fs_unknown
fsE7    DW OFFSET fs_unknown
fsE8    DW OFFSET fs_unknown
fsE9    DW OFFSET fs_unknown
fsEA    DW OFFSET fs_unknown
fsEB    DW OFFSET fs_unknown
fsEC    DW OFFSET fs_unknown
fsED    DW OFFSET fs_unknown
fsEE    DW OFFSET fs_unknown
fsEF    DW OFFSET fs_unknown
fsF0    DW OFFSET fs_unknown
fsF1    DW OFFSET fs_unknown
fsF2    DW OFFSET fs_unknown
fsF3    DW OFFSET fs_unknown
fsF4    DW OFFSET fs_unknown
fsF5    DW OFFSET fs_unknown
fsF6    DW OFFSET fs_unknown
fsF7    DW OFFSET fs_unknown
fsF8    DW OFFSET fs_unknown
fsF9    DW OFFSET fs_unknown
fsFA    DW OFFSET fs_unknown
fsFB    DW OFFSET fs_unknown
fsFC    DW OFFSET fs_unknown
fsFD    DW OFFSET fs_unknown
fsFE    DW OFFSET fs_unknown
fsFF    DW OFFSET fs_unknown

InstallPartition    Proc near
    push es
    pushad
;
    cmp cl,7
    jne install_check_type
;
    push eax
;
    push edx
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    pop edx
;
    mov ecx,1
    call ReadPioSector
;
    push ds
    push edx
;    
    mov eax,10h
    AllocateSmallGlobalMem
    mov ax,flat_sel
    mov ds,ax
    mov edx,edi
    lea esi,[edi+36h]
    xor edi,edi
    movs dword ptr es:[edi],ds:[esi]
    movs dword ptr es:[edi],ds:[esi]
    movs dword ptr es:[edi],ds:[esi]
    movs dword ptr es:[edi],ds:[esi]
    mov ecx,1000h
    FreeLinear
;
    pop edx
    pop ds
;
    pop ecx
    xor edi,edi
    IsFileSystemAvailable
    jc install_part_free
;
    AllocateStaticDrive
    mov ah,ds:sd_disc_nr
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
    movzx edi,di
    IsFileSystemAvailable
    jc install_part_done
;
    AllocateStaticDrive
    mov ah,ds:sd_disc_nr
    OpenDrive
;
    InstallFileSystem
    clc

install_part_done:
;
    popad
    pop es
    ret
InstallPartition    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       DRIVE_ASSIGN1
;
;       DESCRIPTION:    Drive assign, pass 1
;
;       PARAMETERS:     BX      Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drive_assign1   Proc far
    mov ds,bx
    mov fs,ds:sd_reg_sel
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
;
    mov ecx,1
    xor edx,edx
    call ReadPioSector
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
    mov ecx,1000h
    mov edx,edi
    FreeLinear
    retf32
drive_assign1   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InstallExtended
;
;   DESCRIPTION:    Install extended partion on drive
;
;   PARAMETERS:     DS      Device sel
;                   ES      FLAT_SEL
;                   FS      Disc sel
;                   EDX     Current sector
;                   EDI     200H buffer with partition sector
;                   ESI     Partition offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallExtended Proc near
    mov ebp,edx
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
;
    mov ecx,1
    mov edx,ebp
    call ReadPioSector
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
    mov edx,es:[esi+edi].part_start_sector
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
    mov edx,es:[esi+edi].part_start_sector
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

install_ext_done:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
    ret
InstallExtended Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       DRIVE_ASSIGN2
;
;       DESCRIPTION:    Drive assign, pass 2
;
;       PARAMETERS:     BX      Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drive_assign2   Proc far
    mov ds,bx
    mov fs,ds:sd_reg_sel
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
    mov edx,es:[esi+edi].part_start_sector

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
    mov ecx,1000h
    mov edx,edi
    FreeLinear
;    
    mov bx,ds:sd_disc_sel
    StartDisc
;    
    retf32
drive_assign2   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       DEMAND_MOUNT
;
;       DESCRIPTION:    Mount disc drive on demand
;
;       PARAMETERS:     BX      Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

demand_mount    Proc far
    retf32
demand_mount    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       ERASE
;
;       DESCRIPTION:    Erase sectors
;
;       PARAMETERS:     BX      Disc handle
;           EDX     Start sector
;           ECX     Number of sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

erase   Proc far
    stc
    retf32
erase   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       disc_ctrl
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_ctrl:
dcp0  DD OFFSET disc_assign,    SEG code
dc01  DD OFFSET drive_assign1,  SEG code
dc02  DD OFFSET drive_assign2,  SEG code
dc03  DD OFFSET demand_mount,   SEG code
dc04  DD OFFSET erase,          SEG code
    
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
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:sd_dev_count
    or cx,cx
    jz init_sd_exit
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET disc_ctrl
    HookInitDisc

init_sd_exit:
    EndDiscHandler
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
    mov ds:sd_dev_count,0
    BeginDiscHandler
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
