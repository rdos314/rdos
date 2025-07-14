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
; HIDCARD.ASM
; Implements HID card class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
INCLUDE ..\os\protseg.def
include ..\usbdev\usb.inc
INCLUDE ..\handle.inc
include hid.inc
INCLUDE ..\os\carddev.inc

CARD_STATE_GOOD = 1
CARD_STATE_BAD = 2
CARD_STATE_TRACK1 = 4

hid_card   STRUC

hid_device_sel      DW ?

hid_report_offset   DD ?
hid_report_sel      DW ?

hid_feature_offset  DD ?
hid_feature_sel     DW ?

hid_buf_size        DD ?
hid_buf_offset      DD ?
hid_buf_sel         DW ?

hid_stat1_index        DW ?
hid_stat2_index        DW ?
hid_stat3_index        DW ?
hid_len1_index        DW ?
hid_len2_index        DW ?
hid_len3_index        DW ?
hid_track1_index        DW ?
hid_track2_index        DW ?
hid_track3_index        DW ?
hid_encode_index        DW ?
hid_status_index        DW ?

hid_inserted        DB ?
hid_was_inserted    DB ?

hid_reset_req       DB ?
hid_activity        DB ?

hid_card   ENDS

data    SEGMENT byte public 'DATA'


card_hid_handle     DW ?
card_hid_thread     DW ?
card_dev            DW ?
carddev_thread      DW ?
card_retries        DW ?
card_state          DB ?
card_setup          DB ?
card_active         DB ?
card_was_off        DB ?
fatal_error         DB ?
card_dev_reset      DB ?
card_usb_reset      DB ?

track1              DB 80 DUP(?)
track2              DB 40 DUP(?)

data	ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           get_carddev_name
;
;       DESCRIPTION:    Get cardreader name
;
;       PARAMETERS:     ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_carddev_name DB 'USB Card Reader', 0

get_carddev_name    Proc far
    push eax
    push esi
    push edi
;
    mov esi,OFFSET usb_carddev_name

gcnLoop:
    lods byte ptr cs:[esi]
    stos byte ptr es:[edi]
    or al,al
    jnz gcnLoop
;
    pop edi
    pop esi
    pop eax
    ret
get_carddev_name    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           is_ok
;
;       DESCRIPTION:    Check if cardreader is online
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_ok    Proc far
    push ds
    push eax
;
    mov ax,SEG data
    mov ds,eax
    mov ax,ds:card_hid_handle
    or ax,ax
    jz ioOffline

ioOnline:
    clc
    jmp ioDone

ioOffline:
    stc

ioDone:
    pop eax
    pop ds
    ret
is_ok    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           is_busy
;
;       DESCRIPTION:    Check if cardreader is busy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_busy    Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,eax
    mov ax,ds:card_hid_handle
    or ax,ax
    jz ibFail
;
    mov ds,eax
    mov al,ds:hid_inserted
    or al,al
    jz ibFail
;
    clc
    jmp iiDone

ibFail:
    stc

ibDone:
    pop eax
    pop ds
    ret
is_busy    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           is_inserted
;
;       DESCRIPTION:    Check if card is inserted
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_inserted    Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,eax
    mov ax,ds:card_hid_handle
    or ax,ax
    jz iiFail
;
    mov ds,eax
    mov al,ds:hid_inserted
    or al,al
    jz iiFail
;
    clc
    jmp iiDone

iiFail:
    stc

iiDone:
    pop eax
    pop ds
    ret
is_inserted    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           had_inserted
;
;       DESCRIPTION:    Check if card is inserted changed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

had_inserted    Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,eax
    mov ax,ds:card_hid_handle
    or ax,ax
    jz hiFail
;
    mov ds,eax
    mov al,ds:hid_was_inserted
    or al,al
    jz hiFail
;
    clc
    jmp iiDone

hiFail:
    stc

hiDone:
    pop eax
    pop ds
    ret
had_inserted    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           clear_inserted
;
;       DESCRIPTION:    Clear card is inserted changed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_inserted    Proc far
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,eax
    mov ax,ds:card_hid_handle
    or ax,ax
    jz ciDone
;
    mov ds,eax
    mov ds:hid_was_inserted,0

ciDone:
    pop eax
    pop ds
    ret
clear_inserted    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           wait_for_card
;
;       DESCRIPTION:    Wait for card
;
;       PARAMETERS:     ES:EDI      Strip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_card    Proc far
    push ds
    push eax
    push esi
    push edi
;    
    mov ax,SEG data
    mov ds,eax
    GetThread
    mov ds:carddev_thread,ax

wfcRetry:
    test ds:card_state,CARD_STATE_GOOD
    jz wfcNotGood
;    
    and ds:card_state,NOT CARD_STATE_GOOD
    mov esi,OFFSET track2

wfcLoop:
    lodsb
    stos byte ptr es:[edi]
    or al,al
    jnz wfcLoop
;
    clc 
    jmp wfcDone

wfcNotGood:
    test ds:card_state,CARD_STATE_BAD
    jnz wfcBad
;
    WaitForSignal
    jmp wfcRetry

wfcBad:
    and ds:card_state,NOT CARD_STATE_BAD
    stc

wfcDone:
    mov ds:carddev_thread,0
;
    pop edi
    pop esi
    pop eax
    pop ds        
    ret
wait_for_card    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           get_track1
;
;       DESCRIPTION:    get track 1
;
;       PARAMETERS:     ES:EDI      Track 1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_track1    Proc far
    push ds
    push eax
    push esi
    push edi
;    
    mov ax,SEG data
    mov ds,eax
;
    test ds:card_state,CARD_STATE_TRACK1
    stc
    jz gt1Done
;    
    and ds:card_state,NOT CARD_STATE_TRACK1
    mov esi,OFFSET track1

gt1Loop:
    lodsb
    stos byte ptr es:[edi]
    or al,al
    jnz gt1Loop
;
    clc 

gt1Done:
    pop edi
    pop esi
    pop eax
    pop ds        
    ret
get_track1    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddCardReader
;
;       DESCRIPTION:    Add card reader device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddCardReader	Proc near
    push ds
    push es
    pushad
;
    mov eax,SIZE carddev_struc
    AllocateSmallGlobalMem
    mov es:cd_device,0
;    
    xor ax,ax
    xor dx,dx
    mov bx,es
    mov ds,bx
    AddCardDev
;
    mov es:cd_get_name_proc,OFFSET get_carddev_name
    mov es:cd_get_name_proc+4,cs
;    
    mov es:cd_ok_proc,OFFSET is_ok
    mov es:cd_ok_proc+4,cs
;    
    mov es:cd_busy_proc,OFFSET is_busy
    mov es:cd_busy_proc+4,cs
;    
    mov es:cd_inserted_proc,OFFSET is_inserted
    mov es:cd_inserted_proc+4,cs
;    
    mov es:cd_had_inserted_proc,OFFSET had_inserted
    mov es:cd_had_inserted_proc+4,cs
;    
    mov es:cd_clear_inserted_proc,OFFSET clear_inserted
    mov es:cd_clear_inserted_proc+4,cs
;    
    mov es:cd_wait_for_card_proc,OFFSET wait_for_card
    mov es:cd_wait_for_card_proc+4,cs
;    
    mov es:cd_get_track1_proc,OFFSET get_track1
    mov es:cd_get_track1_proc+4,cs
;
    mov ax,SEG data
    mov ds,eax
    mov ds:card_dev,es
;
    popad
    pop es
    pop ds
    ret
AddCardReader	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleTrack1
;
;   DESCRIPTION:    Handle track 1
;
;   PARAMETERS:     FS:EBX  Track 1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleTrack1   Proc near
    push ds
    push eax
    push ebx
    push esi
;
    mov al,fs:[ebx]
    cmp al,'%'
    jne ht1Done
;
    mov ax,SEG data
    mov ds,eax
    inc ebx
    mov ecx,80
    mov esi,OFFSET track1

ht1Loop:
    mov al,fs:[ebx]
    mov ds:[esi],al
;
    or al,al
    je ht1End
;
    inc ebx
    inc esi
    loop ht1Loop

ht1End:
    or ds:card_state,CARD_STATE_TRACK1

ht1Done:
    pop esi
    pop ebx
    pop eax
    pop ds
    ret
HandleTrack1	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleTrack2
;
;   DESCRIPTION:    Handle track 2
;
;   PARAMETERS:     FS:EBX  Track 2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleTrack2   Proc near
    push ds
    push eax
    push ebx
    push esi
;
    mov al,fs:[ebx]
    cmp al,';'
    jne ht2Done
;
    mov ax,SEG data
    mov ds,eax
    inc ebx
    mov ecx,40
    mov esi,OFFSET track2

ht2Loop:
    mov al,fs:[ebx]
    cmp al,'='
    jne ht2NotSep
;
    mov al,'D'
    jmp ht2Norm

ht2NotSep:
    cmp al,'?'
    je ht2End
;
    or al,al
    je ht2End

ht2Norm:
    mov ds:[esi],al
;
    inc ebx
    inc esi
    loop ht2Loop

ht2End:
    xor al,al
    mov ds:[esi],al
    or ds:card_state,CARD_STATE_GOOD
;
    mov bx,ds:carddev_thread
    Signal

ht2Done:
    pop esi
    pop ebx
    pop eax
    pop ds
    ret
HandleTrack2	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleBadCard
;
;   DESCRIPTION:    Handle bad card
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleBadCard   Proc near
    push ds
    push eax
    push ebx
;
    mov ax,SEG data
    mov ds,eax
;
    or ds:card_state,CARD_STATE_BAD
;
    mov bx,ds:carddev_thread
    Signal
;
    pop ebx
    pop eax
    pop ds
    ret
HandleBadCard	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetPropertyString
;
;   DESCRIPTION:    Get property string
;
;   Parameters:     BL        ID
;
;   RETURNS:        AL        Result code
;                   ECX       Data size
;                   ES:EDI    Property data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPropertyString   Proc near
    push ds
    push fs
    push ebx
    push edx
    push esi
;
    mov eax,SEG data
    mov es,eax
    mov es,es:card_hid_handle
;
    push es
;
    mov ecx,es:hid_buf_size
    mov edi,es:hid_buf_offset
    mov es,es:hid_buf_sel
;
    push edi
    xor al,al
    rep stosb
    pop edi
;
    xor al,al
    stosb
;
    mov al,1
    stosb
;
    mov al,bl
    stosb
;
    pop es
;
    mov esi,es:hid_feature_offset
    mov fs,es:hid_feature_sel
    WriteHidFeature
    ReadHidFeature
;
    mov edi,es:hid_buf_offset
    mov es,es:hid_buf_sel
    mov al,es:[edi]
    movzx ecx,byte ptr es:[edi+1]
    add edi,2
;
    pop esi
    pop edx
    pop ebx
    pop fs
    pop ds
    ret
GetPropertyString	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetPropertyByte
;
;   DESCRIPTION:    Get property byte
;
;   Parameters:     BL        ID
;
;   RETURNS:        NC
;                       AL        Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPropertyByte   Proc near
    push ds
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov eax,SEG data
    mov es,eax
    mov es,es:card_hid_handle
;
    push es
;
    mov ecx,es:hid_buf_size
    mov edi,es:hid_buf_offset
    mov es,es:hid_buf_sel
;
    push edi
    xor al,al
    rep stosb
    pop edi
;
    xor al,al
    stosb
;
    mov al,1
    stosb
;
    mov al,bl
    stosb
;
    pop es
;
    mov esi,es:hid_feature_offset
    mov fs,es:hid_feature_sel
    WriteHidFeature
    ReadHidFeature
;
    mov edi,es:hid_buf_offset
    mov es,es:hid_buf_sel
    mov al,es:[edi]
    or al,al
    stc
    jnz gpbDone
;
    mov al,es:[edi+2]
    clc

gpbDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    pop ds
    ret
GetPropertyByte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetPropertyByte
;
;   DESCRIPTION:    Set property byte
;
;   Parameters:     BL        ID
;                   AL        Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPropertyByte   Proc near
    push ds
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov edx,SEG data
    mov es,edx
    mov es,es:card_hid_handle
;
    push es
;
    mov ecx,es:hid_buf_size
    mov edi,es:hid_buf_offset
    mov es,es:hid_buf_sel
;
    push eax
;
    push edi
    xor al,al
    rep stosb
    pop edi
;
    mov al,1
    stosb
;
    mov al,2
    stosb
;
    mov al,bl
    stosb
;
    pop eax
    stosb
;
    pop es
;
    mov esi,es:hid_feature_offset
    mov fs,es:hid_feature_sel
    WriteHidFeature
    ReadHidFeature
;
    mov edi,es:hid_buf_offset
    mov es,es:hid_buf_sel
    mov al,es:[edi]
    or al,al
    stc
    jnz spbDone
;
    clc

spbDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    pop ds
    ret
SetPropertyByte	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ResetDevice
;
;   DESCRIPTION:    Reset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetDevice   Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ebx,SEG data
    mov es,ebx
    mov es,es:card_hid_handle
;
    push es
;
    mov ecx,es:hid_buf_size
    mov edi,es:hid_buf_offset
    mov es,es:hid_buf_sel
;
    push edi
    xor al,al
    rep stosb
    pop edi
;
    mov al,2
    stosb
;
    xor al,al
    stosb
;
    pop es
;
    mov esi,es:hid_feature_offset
    mov fs,es:hid_feature_sel
    WriteHidFeature
    ReadHidFeature
;
    popad
    pop fs
    pop es
    pop ds
    ret
ResetDevice	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_card_thread
;
;   DESCRIPTION:    Hid card thread
;
;   PARAMETERS:     BX      Handle
;
;   RETURNS:        NC      Use
;                   CY      Discard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_card_thread_name DB 'Hid Card Reader', 0

hid_card_thread:
    mov eax,SEG data
    mov ds,eax
    GetThread
    mov ds:card_hid_thread,ax
;
    mov bx,ds:card_hid_handle
    mov es,ebx

hcInit:
    mov ds:card_setup,0
    mov ds:card_retries,0
;
    mov bl,3
    call GetPropertyByte
    cmp al,3
    je hcGetConfig
;
    mov bl,2
    mov al,1
    call SetPropertyByte
;
    mov bl,5
    mov al,32
    call SetPropertyByte
;
    mov bl,3
    mov al,3
    call SetPropertyByte
    jmp hcReset

hcGetConfig:
    mov ds:card_active,1
    mov bl,4
    call GetPropertyByte
    jnc hcOn

hcConfigFail:
    mov ax,ds:card_retries
    inc ax
    mov ds:card_retries,ax
    cmp ax,25
    jae hcReset
;
    xor eax,eax
    mov es,eax
;
    mov ax,100
    WaitMilliSec
    mov bx,ds:card_hid_handle
    or bx,bx
    jz hcOff
;
    mov es,ebx
    jmp hcGetConfig
   
hcOn:
    mov bx,ds:card_hid_handle
    or bx,bx
    jz hcOff
;
    mov es,ebx
    mov ds:card_retries,0
    or al,al
    jz hcSaveInserted
;
    mov es:hid_was_inserted,al

hcSaveInserted:
    mov es:hid_inserted,al
    jz hcWait

hcWaitInserted:
    xor eax,eax
    mov es,eax
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    WaitForSignalWithTimeout
;
    mov bx,ds:card_hid_handle
    or bx,bx
    jz hcOff
;
    mov es,ebx
    xor al,al
    xchg al,es:hid_activity
    or al,al
    jnz hcWait
;
    mov ds:card_active,1
    mov bl,4
    call GetPropertyByte
    jc hcConfigFail
;
    or al,al
    jnz hcWaitInserted
;
    mov ebp,20

hcWaitReport:
    xor eax,eax
    mov es,eax
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    WaitForSignalWithTimeout
;
    mov bx,ds:card_hid_handle
    or bx,bx
    jz hcOff
;
    mov es,ebx
    xor al,al
    xchg al,es:hid_activity
    or al,al
    jnz hcWait
;
    mov ds:card_active,1
    mov bl,4
    call GetPropertyByte
    jc hcConfigFail
;
    sub ebp,1
    jnz hcWaitReport
;
    jmp hcReset

hcWait:
    xor eax,eax
    mov es,eax
;
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    WaitForSignalWithTimeout
;
    mov bx,ds:card_hid_handle
    or bx,bx
    jz hcOff
;
    mov es,ebx
    xor al,al
    xchg al,es:hid_reset_req
    or al,al
    jz hcNotReset

hcReset:
    mov ds:card_dev_reset,1
    mov ds:card_was_off,0
    call ResetDevice
    mov ax,1000
    WaitMilliSec
;
    mov al,ds:card_was_off
    or al,al
    jz hcResetHid
;
    mov bx,ds:card_hid_handle
    or bx,bx
    jz hcOff
;
    mov es,ebx
    jmp hcInit

hcResetHid:
    mov ds:card_usb_reset,1
    mov ds:card_was_off,0
    mov es,ebx
    mov ax,es
    or ax,ax
    jz hcFatalError
;
    mov bx,es:hid_device_sel
    ResetHid
;
    mov ax,1000
    WaitMilliSec
;
    mov al,ds:card_was_off
    or al,al
    jz hcFatalError
;
    mov bx,ds:card_hid_handle
    or bx,bx
    jz hcOff
;
    mov es,ebx
    jmp hcInit

hcNotReset:
    mov al,ds:card_setup
    or al,al
    jz hcGetConfig
;
    jmp hcInit

hcOff:
    mov cx,100

hcOffWait:
    mov ds:card_active,1
    mov ax,100
    WaitMilliSec
;
    mov bx,ds:card_hid_handle
    or bx,bx
    jnz hcInit
;
    sub cx,1
    jnz hcOffWait

hcFatalError:
    mov ds:fatal_error,1
    mov ax,100
    WaitMilliSec
    jmp hcFatalError

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_card_super
;
;   DESCRIPTION:    Hid card supervisor
;
;   PARAMETERS:     BX      Handle
;
;   RETURNS:        NC      Use
;                   CY      Discard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_card_super_name DB 'Hid Card Super', 0

hid_card_super:
    mov eax,SEG data
    mov ds,eax
    xor ecx,ecx

hcsLoop:
    xor al,al
    xchg al,ds:card_active
    or al,al
    jz hcsWait
;
    xor ecx,ecx

hcsWait:
    inc ecx
    cmp ecx,100
    jae hcsFailed
;
    mov ax,100
    WaitMilliSec
    jmp hcsLoop

hcsFailed:
    mov ds:fatal_error,1
    mov ax,100
    WaitMilliSec
    jmp hcsLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_begin
;
;   DESCRIPTION:    Begin initialization
;
;   Parameters:     FS:ESI    Report struct
;                   GS:EBX    Device
;
;   RETURNS:        BX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_begin   Proc far
    push es
    push eax
    push ecx
    push edi
;
    mov eax,SIZE usb_device_descr
    AllocateSmallGlobalMem
;
    mov bx,gs:hid_controller
    mov al,gs:hid_port
;
    mov ecx,SIZE usb_device_descr
    xor edi,edi
    GetUsbDevice
    cmp eax,ecx
    jne hbFail
;
    mov ax,es:udd_vendor
    cmp ax,801h
    jne hbFail
;
    mov ax,es:udd_prod
    cmp ax,3
    jne hbFail
;
    FreeMem
;    
    mov eax,SIZE hid_card
    AllocateSmallGlobalMem
;
    mov es:hid_report_offset,esi
    mov es:hid_report_sel,fs    
    mov es:hid_device_sel,gs
    mov es:hid_reset_req,0
    mov es:hid_activity,0
    mov es:hid_stat1_index,-1
    mov es:hid_stat2_index,-1
    mov es:hid_stat3_index,-1
    mov es:hid_len1_index,-1
    mov es:hid_len2_index,-1
    mov es:hid_len3_index,-1
    mov es:hid_track1_index,-1
    mov es:hid_track2_index,-1
    mov es:hid_track3_index,-1
    mov es:hid_encode_index,-1
    mov es:hid_status_index,-1
    mov ebx,es
    jmp hbDone

hbFail:
    FreeMem
    xor ebx,ebx

hbDone:
    pop edi
    pop ecx
    pop eax
    pop es
    ret
hid_begin   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_define
;
;   DESCRIPTION:    Define entry
;
;   PARAMETERS:     BX      Handle
;                   SI      Entry #
;                   AL      Usage ID low
;                   AH      Usage ID high
;                   CL      Usage page
;                   EDX     Item params
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_define   Proc far
    push ds
    push ebx
    mov ds,ebx
;
    cmp cx,0FF00h
    jne hdDone
;
    cmp al,20h
    jne hdNot20
;
    mov bx,ds:hid_stat1_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_stat1_index,si
    jmp hdDone

hdNot20:
    cmp al,21h
    jne hdNot21
;
    mov bx,ds:hid_stat2_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_stat2_index,si
    jmp hdDone

hdNot21:
    cmp al,22h
    jne hdNot22
;
    mov bx,ds:hid_stat3_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_stat3_index,si
    jmp hdDone

hdNot22:
    cmp al,28h
    jne hdNot28
;
    mov bx,ds:hid_len1_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_len1_index,si
    jmp hdDone

hdNot28:
    cmp al,29h
    jne hdNot29
;
    mov bx,ds:hid_len2_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_len2_index,si
    jmp hdDone

hdNot29:
    cmp al,2Ah
    jne hdNot2A
;
    mov bx,ds:hid_len3_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_len3_index,si
    jmp hdDone

hdNot2A:
    cmp al,30h
    jne hdNot30
;
    mov bx,ds:hid_track1_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_track1_index,si
    jmp hdDone

hdNot30:
    cmp al,31h
    jne hdNot31
;
    mov bx,ds:hid_track2_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_track2_index,si
    jmp hdDone

hdNot31:
    cmp al,32h
    jne hdNot32
;
    mov bx,ds:hid_track3_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_track3_index,si
    jmp hdDone

hdNot32:
    cmp al,38h
    jne hdNot38
;
    mov bx,ds:hid_encode_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_encode_index,si
    jmp hdDone

hdNot38:
    cmp al,39h
    jne hdDone
;
    mov bx,ds:hid_status_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_status_index,si

hdDone:
    pop ebx
    pop ds
    ret
hid_define   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_end
;
;   DESCRIPTION:    End initialization
;
;   PARAMETERS:     BX      Handle
;
;   RETURNS:        NC      Use
;                   CY      Discard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_end   Proc far
    push fs
    push es
    push eax
    push ecx
    push edx
    push esi
    mov es,ebx
;
    mov ax,es:hid_stat1_index
    and ax,es:hid_stat2_index
    and ax,es:hid_stat3_index
    and ax,es:hid_len1_index
    and ax,es:hid_len2_index
    and ax,es:hid_len3_index
    and ax,es:hid_track1_index
    and ax,es:hid_track2_index
    and ax,es:hid_track3_index
    and ax,es:hid_encode_index
    and ax,es:hid_status_index
    cmp ax,-1
    je heFail
;
    push ebx
    mov bx,es:hid_device_sel
    mov cx,0FF00h
    mov dl,20h
    FindHidFeatureReport
    pop ebx
    jc heFail
;
    mov es:hid_feature_offset,esi
    mov es:hid_feature_sel,dx
    mov fs,dx
;
    GetHidReportSize
    mov es:hid_buf_size,ecx
;
    GetHidReportBuf
    mov es:hid_buf_offset,eax
    mov es:hid_buf_sel,dx
;
    mov ax,SEG data
    mov es,eax
    mov ax,es:card_dev
    or ax,ax
    jnz heHasDev
;
    call AddCardReader

heHasDev:
    mov es:card_hid_handle,bx 
    mov es:card_was_off,1
;
    push ebx
    mov bx,es:card_hid_thread
    or bx,bx
    jnz heHasThread
;
    push ds
    push es
    pushad
;
    mov edx,cs
    mov ds,edx
    mov es,edx
    mov edi,OFFSET hid_card_thread_name
    mov esi,OFFSET hid_card_thread
    mov ax,2
    mov ecx,stack0_size
    CreateThread
;
    mov edi,OFFSET hid_card_super_name
    mov esi,OFFSET hid_card_super
    mov ax,2
    mov ecx,stack0_size
    CreateThread
;
    popad
    pop es
    pop ds
;
    pop ebx
    jmp heDone

heHasThread:
    mov es:card_setup,1
    Signal
    pop ebx
    clc
    jmp heDone

heFail:
    FreeMem
    stc
        
heDone:
    pop esi
    pop edx
    pop ecx
    pop eax    
    pop es
    pop fs
    ret
hid_end   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_close
;
;   DESCRIPTION:    Close
;
;   PARAMETERS:     BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_close   Proc far
    push es
    push ebx
;
    mov es,ebx
    FreeMem
;
    mov bx,SEG data
    mov es,ebx
    mov es:card_hid_handle,0
    mov es:card_was_off,1
    mov bx,es:card_hid_thread
    Signal
;
    pop ebx
    pop es
    ret
hid_close   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_handle_report
;
;   DESCRIPTION:    Handle report
;
;   PARAMETERS:     BX      Handle
;                   FS:ESI  Report data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_handle_report   Proc far
    push es
    push eax
    push ebx
    mov es,ebx
;
    movzx ebx,es:hid_status_index
    cmp ebx,-1
    je hhrNoStatus
;
    mov al,fs:[ebx+esi]
    test al,0FEh
    jz hhrValid
;
    mov es:hid_reset_req,1
    jmp hhrDone

hhrValid:
    mov es:hid_activity,1
    or al,al
    jz hhrSaveInserted
;
    mov es:hid_was_inserted,al

hhrSaveInserted:
    mov es:hid_inserted,al
    
hhrNoStatus:
    movzx ebx,es:hid_len1_index
    mov al,fs:[ebx+esi]
    or al,al
    jz hhrNotTrack1
;
    movzx ebx,es:hid_track1_index
    add ebx,esi
    call HandleTrack1

hhrNotTrack1:
    movzx ebx,es:hid_len2_index
    mov al,fs:[ebx+esi]
    or al,al
    jz hhrNotGood2
;
    movzx ebx,es:hid_track2_index
    add ebx,esi
    call HandleTrack2
    jmp hhrDone

hhrNotGood2:
    movzx ebx,es:hid_encode_index
    mov al,fs:[ebx+esi]
    or al,al
    jz hhrDone
;
    call HandleBadCard

hhrDone:
    pop ebx
    pop eax
    pop es
    ret
hid_handle_report   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           valid_custom_hid
;
;   DESCRIPTION:    Check for custom hid device
;
;   PARAMETERS:     FS:ESI  Hid device
;
;   RETURNS:        NC		Accept
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

valid_custom_hid   Proc far
    push es
    push eax
    push ebx
    push ecx
    push edi
;
    mov eax,SIZE usb_device_descr
    AllocateSmallGlobalMem
;
    mov bx,fs:hid_controller
    mov al,fs:hid_port
;
    mov ecx,SIZE usb_device_descr
    xor edi,edi
    GetUsbDevice
    cmp eax,ecx
    jne vchFail
;
    mov ax,es:udd_vendor
    cmp ax,801h
    jne vchFail
;
    mov ax,es:udd_prod
    cmp ax,3
    jne vchFail
;
    FreeMem
    clc
    jmp vchDone

vchFail:
    FreeMem
    stc

vchDone:
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
valid_custom_hid   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Has USB card error
;
;           DESCRIPTION:    Has usb card error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_usb_card_reader_error_name	DB 'Has USB Cardreader error', 0

has_usb_card_reader_error	Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,ebx
    mov al,ds:fatal_error
    or al,al
    stc
    jz hucreDone
;
    clc

hucreDone:
    pop ebx
    pop ds
    ret
has_usb_card_reader_error	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Has USB card device RESET
;
;           DESCRIPTION:    Has usb card device reset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_usb_card_dev_reset_name	DB 'Has USB Card Device Reset', 0

has_usb_card_dev_reset	Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,ebx
    xor al,al
    xchg al,ds:card_dev_reset
    or al,al
    stc
    jz hucdrDone
;
    clc

hucdrDone:
    pop ebx
    pop ds
    ret
has_usb_card_dev_reset	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Has USB card USB RESET
;
;           DESCRIPTION:    Has usb card USB reset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_usb_card_usb_reset_name	DB 'Has USB Card USB Reset', 0

has_usb_card_usb_reset	Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,ebx
    xor al,al
    xchg al,ds:card_usb_reset
    or al,al
    stc
    jz hucurDone
;
    clc

hucurDone:
    pop ebx
    pop ds
    ret
has_usb_card_usb_reset	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_tab:
h00 DD OFFSET hid_begin,        SEG code
h01 DD OFFSET hid_define,       SEG code
h02 DD OFFSET hid_end,          SEG code
h03 DD OFFSET hid_close,        SEG code
h04 DD OFFSET hid_handle_report,SEG code

Init    Proc far
    mov ax,SEG data
    mov ds,eax
    mov ds:card_hid_handle,0
    mov ds:card_dev,0
    mov ds:card_setup,0
    mov ds:card_hid_thread,0
    mov ds:carddev_thread,0
    mov ds:card_state,0
    mov ds:fatal_error,0
    mov ds:card_dev_reset,1
    mov ds:card_usb_reset,1
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov edi,OFFSET valid_custom_hid
    RegisterCustomHid
;
    mov edi,OFFSET hid_tab
    RegisterHidInput
;
    mov esi,OFFSET has_usb_card_reader_error
    mov edi,OFFSET has_usb_card_reader_error_name
    xor dx,dx
    mov ax,has_usb_card_reader_error_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET has_usb_card_dev_reset
    mov edi,OFFSET has_usb_card_dev_reset_name
    xor dx,dx
    mov ax,has_usb_card_dev_reset_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET has_usb_card_usb_reset
    mov edi,OFFSET has_usb_card_usb_reset_name
    xor dx,dx
    mov ax,has_usb_card_usb_reset_nr
    RegisterBimodalUserGate
    ret
Init    Endp
        
code    ENDS

    END Init
