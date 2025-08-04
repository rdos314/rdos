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
INCLUDE ..\os\system.def
INCLUDE ..\os\core.inc
INCLUDE ..\acpi\pci.inc

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

sd_device_struc STRUC

sd_reg_sel          DW ?
sd_serv_thread      DW ?
sd_pend_error       DW ?
sd_pend_int         DB ?
sd_ok               DB ?
sd_pci_handle       DW ?
sd_has_int          DW ?

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
    push ax
    mov ax,es:REG_INT_ERROR_STATUS
    lock or ds:sd_pend_error,ax
    mov es:REG_INT_ERROR_STATUS,ax
    pop ax
    
siNoError:    
    and word ptr es:REG_INT_STATUS_ENABLE, NOT 100h    
    mov es:REG_INT_STATUS,al
    or word ptr es:REG_INT_STATUS_ENABLE, 100h
    or al,al
    jz sdiDone
;
;    and word ptr es:REG_INT_STATUS_ENABLE, NOT 100h    
;    mov es:REG_INT_STATUS,al
;    or word ptr es:REG_INT_STATUS_ENABLE, 100h
;    
    mov bx,ds:sd_serv_thread
    mov ds:sd_has_int,1
    Signal    

sdiDone:    
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
;                       BX      PCI handle
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
    mov es:sd_pci_handle,bx
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

DevName DB 'SD-card', 0

InitPciDev Proc near
    mov ax,cs
    mov es,ax
    mov ax,SEG data
    mov ds,ax
    mov ds:sd_dev_count,0
;    
    xor bx,bx

ipdLoop: 
    mov ah,8
    mov al,5
    FindPciClassHandle
    jc ipdDone
;
    xor al,al
    GetPciBarPhys
    jc ipdLoop
;
    push ebx
;
    push eax
    push edx
;
    mov edi,OFFSET DevName
    LockPciHandle
;
    mov eax,1000h
    AllocateBigLinear
;    
    pop ebx
    pop eax
;
    mov al,13h
    SetPageEntry
;
    and eax,0E00h
    add edx,eax
;        
    AllocateGdt
    mov ecx,200h
    CreateDataSelector16
    mov fs,bx
;
    mov byte ptr fs:REG_RESET,1
    pop ebx
;
    call AddDevice
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
    mov bx,ds:sd_pci_handle
    mov al,12h
    mov di,cs
    mov es,di
    mov edi,OFFSET SdInt
    SetupPciHandleIrq
;
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
    and al,60h  ; NOT 9Fh
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
    push eax
    push edx
    push esi
    push edi
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov esi,eax
    mov edi,edx

wftcWait:
    WaitForSignalWithTimeout
    test ds:sd_pend_error,1FFh
    stc
    jnz wftcDone
;    
    GetSystemTime
    sub eax,esi
    sbb edx,edi
    cmc
    jc wftcDone
;
    test ds:sd_pend_int,2
    jz wftcWait
;
    clc

wftcDone:    
    pop edi
    pop esi
    pop edx
    pop eax
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
    mov word ptr fs:REG_CMD,0B02h
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
    mov ax,10
    WaitMilliSec
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
    mov ax,10
    WaitMilliSec 
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
;           NAME:           SetSdr25
;
;           DESCRIPTION:    Set SDR25 mode
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSdr25    Proc near
    mov eax,0FF0001h
    call SetCmd6
    mov ax,10
    WaitMilliSec
    call GetCmd6Func
    cmp eax,1h
    stc
    jne ss25Done
;
    mov cx,50
    call SetSdClock
    clc

ss25Done:    
    ret
SetSdr25    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetSdr50
;
;           DESCRIPTION:    Set SDR50 mode
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSdr50    Proc near
    mov eax,0FF1002h
    call SetCmd6
    mov ax,10
    WaitMilliSec
    call GetCmd6Func
    cmp eax,100002h
    stc
    jne ss50Done
;
    mov cx,100
    call SetSdClock
;
    mov ax,fs:REG_CONTROL2
    and al,NOT 7
    or al,2
    mov fs:REG_CONTROL2,ax
    clc

ss50Done:    
    ret
SetSdr50    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetSdr104
;
;           DESCRIPTION:    Set SDR104 mode
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSdr104    Proc near
    mov eax,0FF3003h
    call SetCmd6
    mov ax,10
    WaitMilliSec
    call GetCmd6Func
    cmp eax,100003h
    stc
    jne ss104Done
;
    mov cx,200
    call SetSdClock
;
    mov ax,fs:REG_CONTROL2
    and al,NOT 7
    or al,2
    mov fs:REG_CONTROL2,ax
    clc

ss104Done:    
    ret
SetSdr104    Endp

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
    mov ax,ds:sd_grp1
    test al,8
    jz shsNot104
;
    call SetSdr104
    jnc shsDone

shsNot104:
    mov ax,ds:sd_grp1
    test al,4
    jz shsNot50
;
    call SetSdr50
    jnc shsDone

shsNot50:
    mov ax,ds:sd_grp1
    test al,2
    jz shsDone
;
    call SetSdr25    

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
;           NAME:           InitDevice
;
;           DESCRIPTION:    Init device from RESET state
;
;           PARAMETERS:     DS      Device
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitDevice    Proc near
    mov ds:sd_ok,0
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
    mov eax,fs:REG_STATE
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
    jc idFailed    mov ds:sd_ocr,eax
;
    mov ax,ds:sd_ver
    cmp ax,2
    jae idsOcr
;
    call SendCmd8
    jc idFailed

idsOcr:
    mov eax,ds:sd_ocr
    call SetOcr    
;
    test ds:sd_ocr,01000000h
    jz idVoltOk
;
    call SendCmd11    
    jc idFailed
;
    mov word ptr fs:REG_INT_STATUS_ENABLE,0
    mov word ptr fs:REG_INT_SIG_ENABLE,0
;
    mov word ptr fs:REG_INT_ERROR_STATUS_ENABLE,0
    mov word ptr fs:REG_INT_ERROR_SIG_ENABLE,0
;
    mov ax,fs:REG_CLK_CONTROL
    and ax,NOT 4
    mov fs:REG_CLK_CONTROL,ax
;
    mov eax,fs:REG_STATE
    shr eax,20
    and al,0Fh
    jnz idFailed
;
    mov ax,fs:REG_CONTROL2
    or ax,8
    mov fs:REG_CONTROL2,ax
;
    mov ax,10
    WaitMilliSec
;
    mov ax,fs:REG_CONTROL2        
    test ax,8
    jz idFailed
;
    mov ax,fs:REG_CLK_CONTROL
    or ax,4
    mov fs:REG_CLK_CONTROL,ax
;
    mov ax,5
    WaitMilliSec
;
    mov eax,fs:REG_STATE
    shr eax,20
    and al,0Fh
    cmp al,0Fh
    jne idFailed
;
    mov word ptr fs:REG_INT_STATUS_ENABLE,1FFh
    mov word ptr fs:REG_INT_SIG_ENABLE,1FFh
;
    mov word ptr fs:REG_INT_ERROR_STATUS_ENABLE,3FFh
    mov word ptr fs:REG_INT_ERROR_SIG_ENABLE,3FFh

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
    jb idNoHs
;
    call SendAcmd6
;
    mov ax,ds:sd_ccc
    and ax,14h
    cmp ax,14h
    jne idFailed
;    
    call SetHighSpeed
    
idNoHs:    
    mov ecx,1000
    call SetDataTimeout
    call DisconnectPullup
;    
    mov ax,100
    WaitMilliSec
    mov ds:sd_ok,1
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
;           NAME:           ResetDev
;
;           DESCRIPTION:    Reset device
;
;           PARAMETERS:     DS      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_super_thread_name   DB 'SD Reset Super', 0

reset_super_thread:
    mov ds,bx
    mov cx,15 * 20

rtLoop:
    mov al,ds:sd_ok
    or al,al
    jnz rtDone
;
    mov ax,50
    WaitMilliSec
    loop rtLoop
;
    CrashGate

rtDone:
    TerminateThread
     
ResetDev    Proc near
    push es
    push fs
    pushad
;    
    mov fs,ds:sd_reg_sel
    mov byte ptr fs:REG_RESET,1
;
    mov cx,100

rdResetLoop:    
    mov ax,100
    WaitMilliSec
;   
    mov al,fs:REG_RESET
    and al,1
    clc
    jz rdResetOk
;
    sub cx,1
    jnz rdResetLoop
;
    CrashGate

rdResetOk:        
    mov ds:sd_ok,0
;    
    push ds
    push es
;    
    mov bx,ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET reset_super_thread_name
    mov esi,OFFSET reset_super_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    pop es    
    pop ds
;
    call InitDevice
    mov al,ds:sd_ok
    or al,al
    jnz rdDone

rdFail:
    CrashGate        

rdDone:
    popad
    pop fs
    pop es
    ret
ResetDev    Endp

    
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

rdLoop:    
    push ecx
    mov edi,es:[esi]
;
    mov edx,es:[edi].dh_unit
    movzx eax,ds:sd_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    mov ebx,edx
    mov ebp,1
;
    push esi    

rdSizeLoop:
    cmp ecx,ebp
    jbe rdDoTrans
;
    add esi,4
    mov edi,es:[esi]
;
    push ebx
    mov edx,es:[edi].dh_unit
    movzx eax,ds:sd_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    pop ebx
;
    inc ebx
    cmp ebx,edx
    jne rdDoTrans
;
    inc ebp
    jmp rdSizeLoop            

rdDoTrans:
    pop esi
;    
    push ebp
    push esi

rdDoRetry:
    mov edi,es:[esi]
    mov edx,es:[edi].dh_unit
    movzx eax,ds:sd_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
;       
    mov fs:REG_BLOCK_COUNT,bp
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    mov ds:sd_has_int,0
;
    ClearSignal
    mov dword ptr fs:REG_ARG,edx
    mov word ptr fs:REG_TRANS_MODE,36h
    mov word ptr fs:REG_CMD,123Ah

rdSectorLoop:    
    mov cx,8

rdSectorRetry:
    push eax
    push edx
;
    GetSystemTime
    add eax,1193 * 250
    adc edx,0
    WaitForSignalWithTimeout
;
    xor ax,ax
    xchg ax,ds:sd_has_int
    or ax,ax
    jz rdReset
;
    test word ptr fs:REG_STATE,800h
    jnz rdReadBuf
;
    pop edx
    pop eax
;
    sub cx,1
    jnz rdSectorRetry
;
    push eax
    push edx
    nop
    nop
    nop

rdReset:
    call ResetDev
;
    pop edx
    pop eax
    jmp rdDoRetry

rdReadBuf:
    pop edx
    pop eax
;   
    mov ds:sd_pend_int,0
    mov ecx,128
    mov edi,es:[esi]
    mov edi,es:[edi].dh_data

rdBufLoop:    
    mov eax,fs:REG_BUF
    stos dword ptr es:[edi]
    loop rdBufLoop        
;
    add esi,4
    sub ebp,1
    jnz rdSectorLoop
;
    pop esi
    pop ebp 
    pop ecx

rdOkLoop:
    mov edi,es:[esi]
    mov eax,es:[edi].dh_data
    mov es:[edi].dh_state,STATE_USED
    mov bx,ds:sd_disc_sel
    DiscRequestCompleted
    add esi,4
    sub ecx,1
    sub ebp,1
    jnz rdOkLoop

rdNext:
    or ecx,ecx
    jnz rdLoop
;
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

action_write_start DB 'Write', 0
action_write_reset DB 'Write Reset', 0

write_drive     Proc near

wrLoop:    
    push ecx
    mov edi,es:[esi]
;
    mov edx,es:[edi].dh_unit
    movzx eax,ds:sd_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    mov ebx,edx
    mov ebp,1
;
    push esi    

wrSizeLoop:
    cmp ecx,ebp
    jbe wrDoTrans
;
    add esi,4
    mov edi,es:[esi]
;
    push ebx
    mov edx,es:[edi].dh_unit
    movzx eax,ds:sd_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    pop ebx
;
    inc ebx
    cmp ebx,edx
    jne wrDoTrans
;
    inc ebp
    jmp wrSizeLoop            

wrDoTrans:
    pop esi
;    
    push ebp
    push esi

wrDoRetry:
    mov edi,es:[esi]
    mov edx,es:[edi].dh_unit
    movzx eax,ds:sd_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
;    
    mov fs:REG_BLOCK_COUNT,bp
    mov ds:sd_pend_int,0
    mov ds:sd_pend_error,0
    ClearSignal
    mov dword ptr fs:REG_ARG,edx
    mov word ptr fs:REG_TRANS_MODE,26h
    mov word ptr fs:REG_CMD,193Ah

wrSectorLoop:    
    mov cx,8

wrSectorRetry:
    push eax
    push edx
;
    GetSystemTime
    add eax,1193 * 250
    adc edx,0
    WaitForSignalWithTimeout
;
    mov ax,ds:sd_has_int
    or ax,ax
    jz wrReset
;
    test word ptr fs:REG_STATE,400h
    jnz wrWriteBuf
;
    pop edx
    pop eax
;
    sub cx,1
    jnz wrSectorRetry
;
    push eax
    push edx    

wrReset:
    call ResetDev
;
    pop edx
    pop eax
    jmp wrDoRetry

wrWriteBuf:
    pop edx
    pop eax
;   
    mov ds:sd_pend_int,0
    mov ecx,128
    mov edi,es:[esi]
    mov edi,es:[edi].dh_data

wrBufLoop:    
    mov eax,es:[edi]
    mov fs:REG_BUF,eax
    add edi,4
    loop wrBufLoop        
;
    add esi,4
    sub ebp,1
    jnz wrSectorLoop
;
    pop esi
    pop ebp 
;
    call WaitForTransferComplete
    pop ecx

wrOkLoop:
    mov edi,es:[esi]
    mov eax,es:[edi].dh_data
    mov es:[edi].dh_state,STATE_USED
    mov bx,ds:sd_disc_sel
    DiscRequestCompleted
    add esi,4
    sub ecx,1
    sub ebp,1
    jnz wrOkLoop

wrNext:
    or ecx,ecx
    jnz wrLoop
;
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

action_idle DB 'Idle', 0

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
    InstallStaticDisc    
    mov ds:sd_disc_nr,al
    mov ds:sd_disc_sel,bx
;
    mov eax,ds:sd_total_sectors
    xor edx,edx
    mov cx,512
    SetDiscLbaParam
    mov ds:sd_sectors_per_unit,ax
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
;       NAME:           SetupSd
;
;       DESCRIPTION:    Setup SD discs
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_name   DB 'SDIO ',0

SetupSd    Proc near
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
    ret
SetupSd    Endp
    
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
    call SetupSd

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
