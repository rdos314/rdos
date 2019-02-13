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

hid_card   ENDS

mcp_frame	STRUC

mf_da               DB ?
mf_sa               DB ?
mf_pcb              DB ?
mf_len_high         DB ?
mf_len_low          DB ?
mf_hedc             DB ?

mcp_frame	ENDS

mcp_msg         STRUC

ms_header       mcp_frame <>

ms_mtype        DB ?
ms_appl         DB ?
ms_cmnd         DB ?
ms_rc           DB ?

mcp_msg         ENDS

data    SEGMENT byte public 'DATA'

mcp_card_thread     DW ?

mcp_in_size         DW ?
mcp_out_size        DW ?

mcp_control_handle  DW ?
mcp_in_handle       DW ?
mcp_in_req          DW ?
mcp_in_buffer       DW ?

mcp_out_handle      DW ?
mcp_out_req         DW ?
mcp_out_buffer      DW ?

mcp_intr_handle     DW ?
mcp_intr_req        DW ?
mcp_intr_buffer     DW ?

mcp_controller      DW ?
mcp_device          DB ?
mcp_intr            DB ?
mcp_bulk_in         DB ?
mcp_bulk_out        DB ?

mcp_pcb             DB ?
mcp_rec_start       DB ?

card_hid_handle     DW ?
card_dev            DW ?
carddev_thread      DW ?
card_state          DB ?
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
;   NAME:           HandleGoodCard
;
;   DESCRIPTION:    Handle good card
;
;   PARAMETERS:     FS:EBX  Card strip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGoodCard   Proc near
    push ds
    push eax
    push ebx
    push esi
;
    mov al,fs:[ebx]
    cmp al,';'
    jne hgcDone
;
    mov ax,SEG data
    mov ds,eax
    inc ebx
    mov ecx,40
    mov esi,OFFSET track2

hgcLoop:
    mov al,fs:[ebx]
    cmp al,'='
    jne hgcNotSep
;
    mov al,'D'
    jmp hgcNorm

hgcNotSep:
    cmp al,'?'
    je hgcEnd
;
    or al,al
    je hgcEnd

hgcNorm:
    mov ds:[esi],al
;
    inc ebx
    inc esi
    loop hgcLoop

hgcEnd:
    xor al,al
    mov ds:[esi],al
    or ds:card_state,CARD_STATE_GOOD
;
    mov bx,ds:carddev_thread
    Signal

hgcDone:
    pop esi
    pop ebx
    pop eax
    pop ds
    ret
HandleGoodCard	Endp

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
    mov al,gs:hid_device
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
    mov es,ebx
;
    mov bl,3
    call GetPropertyByte
    cmp al,3
    je heConfigOk
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
;
    call ResetDevice
    clc
    jmp heDone

heConfigOk:
    mov bl,4
    call GetPropertyByte
    mov es:hid_inserted,al
    mov es:hid_was_inserted,al
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
    mov bx,es:hid_device_sel
    ResetHid
    jmp hhrDone

hhrValid:
    or al,al
    jz hhrSaveInserted
;
    mov es:hid_was_inserted,al

hhrSaveInserted:
    mov es:hid_inserted,al
    
hhrNoStatus:
    movzx ebx,es:hid_len2_index
    mov al,fs:[ebx+esi]
    or al,al
    jz hhrNotGood2
;
    movzx ebx,es:hid_track2_index
    add ebx,esi
    call HandleGoodCard
    jmp hhrDone

hhrNotGood2:
    movzx ebx,es:hid_encode_index
    mov al,fs:[ebx+esi]
    or al,al
    jz hhrNotBad
;
    call HandleBadCard
    jmp hhrDone

hhrNotBad:
    int 3

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
    mov al,fs:hid_device
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
;           NAME:           OpenMcp
;
;           DESCRIPTION:    Open MCP pipes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_mcp	Proc near
    push es
    pushad
;
    mov bx,ds:mcp_controller
    mov al,ds:mcp_device
    xor dl,dl
    OpenUsbPipe
    mov ds:mcp_control_handle,bx
;
    mov bx,ds:mcp_controller
    mov al,ds:mcp_device
    mov dl,ds:mcp_bulk_in
    OpenUsbPipe
    mov ds:mcp_in_handle,bx
;
    CreateUsbReq
    mov ds:mcp_in_req,bx    
;    
    mov cx,ds:mcp_in_size
    xor ax,ax
    AddReadUsbDataReq
    mov ds:mcp_in_buffer,es
;
    mov bx,ds:mcp_controller
    mov al,ds:mcp_device
    mov dl,ds:mcp_bulk_out
    OpenUsbPipe    
    mov ds:mcp_out_handle,bx
;
    CreateUsbReq
    mov ds:mcp_out_req,bx
;    
    mov cx,ds:mcp_out_size
    mov ax,1
    AddWriteUsbDataReq
    mov ds:mcp_out_buffer,es
;
    mov bx,ds:mcp_controller
    mov al,ds:mcp_device
    mov dl,ds:mcp_intr
    OpenUsbPipe    
    mov ds:mcp_intr_handle,bx
;    
    CreateUsbReq
    mov ds:mcp_intr_req,bx
;
    mov cx,ds:mcp_in_size
    xor ax,ax
    AddReadUsbDataReq
    mov ds:mcp_intr_buffer,es
;
    popad
    pop es
    ret
open_mcp	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseMcp
;
;           DESCRIPTION:    Close MCP pipes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_mcp	Proc near
    push es
    pushad
;
    mov ax,50
    WaitMilliSec
;    
    xor ax,ax
    mov es,ax
;    
    mov bx,ds:mcp_in_req
    CloseUsbReq
    mov ds:mcp_in_req,0
;
    mov bx,ds:mcp_in_handle
    CloseUsbPipe    
    mov ds:mcp_in_handle,0
;
    mov bx,ds:mcp_out_req
    CloseUsbReq
    mov ds:mcp_out_req,0
;
    mov bx,ds:mcp_out_handle
    CloseUsbPipe    
    mov ds:mcp_out_handle,0
;
    mov bx,ds:mcp_intr_req
    CloseUsbReq
    mov ds:mcp_intr_req,0
;
    mov bx,ds:mcp_intr_handle
    CloseUsbPipe
    mov ds:mcp_intr_handle,0
;
    mov bx,ds:mcp_control_handle
    CloseUsbPipe    
    mov ds:mcp_control_handle,0
;
    mov ds:mcp_in_buffer,0
    mov ds:mcp_out_buffer,0
    mov ds:mcp_intr_buffer,0
;
    popad
    pop es
    ret
close_mcp	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           McpCheckFrame
;
;           DESCRIPTION:    Check received frame
;
;           PARAMETERS:     CX Frame size
;                           FS Frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mcp_check_frame	Proc near
    pushad
;
    mov dx,cx
;
    xor al,al
    xor si,si
    mov cx,OFFSET mf_hedc
    cmp cx,dx
    jae mcfFail

mcfHeaderLrcLoop:
    xor al,fs:[si]
    inc si
    loop mcfHeaderLrcLoop
;
    xor al,fs:[si]
    jnz mcfFail
;
    mov al,fs:mf_pcb
    shr al,6
    and al,3
    cmp al,2
    je mcfCheckLrc
;
    or al,al
    jz mcfCheckI
;
    int 3

mcfCheckI:
    mov al,fs:mf_pcb
    shr al,4
    and al,3
    jz mcfCheckLrcDone
;
    int 3

mcfCheckLrc:
    mov cl,fs:mf_len_low
    mov ch,fs:mf_len_high
    add cx,SIZE mcp_frame
    cmp cx,dx
    jae mcfFail
;
    xor al,al
    xor si,si

mcfWholeLrcLoop:
    xor al,fs:[si]
    inc si
    loop mcfWholeLrcLoop
;
    xor al,fs:[si]
    jnz mcfFail

mcfCheckLrcDone:

mcfOk:
    clc
    jmp mcfDone

mcfFail:
    stc

mcfDone:
    popad
    ret
mcp_check_frame Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           McpWaitForResponse
;
;           DESCRIPTION:    Wait for response
;
;           PARAMETERS:     FS  Answer frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mcp_wait_for_response	Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    mov bx,ds:mcp_in_req
    IsUsbReqStarted
    jnc mwfrStarted
;
    mov ax,ds:mcp_card_thread
    StartUsbReq

mwfrStarted:
    GetSystemTime
    add eax,1193 * 250
    adc edx,0
    WaitForSignalWithTimeout
;
    mov bx,ds:mcp_in_req
    IsUsbReqReady
    jc mwfrDone
;
    mov ds:mcp_rec_start,1
    GetUsbReqData
    mov fs,ds:mcp_in_buffer
    call mcp_check_frame

mwfrDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
mcp_wait_for_response	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mcp_session
;
;           DESCRIPTION:    MCP session
;
;           PARAMETERS:     ES	Frame to send
;
;           RETURNS:        FS answer frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mcp_session	Proc near
    xor al,al
    xor si,si
    mov cx,OFFSET mf_hedc

msHeaderLrcLoop:
    xor al,es:[si]
    inc si
    loop msHeaderLrcLoop
;
    mov es:[si],al
;
    mov cl,es:mf_len_low
    mov ch,es:mf_len_high
    add cx,SIZE mcp_frame
;
    mov dl,es:mf_pcb
    shr dl,6
    and dl,3
    cmp dl,2
    jne msSend

msAddLrc:
    push cx
    xor al,al
    xor si,si

msWholeLrcLoop:
    xor al,es:[si]
    inc si
    loop msWholeLrcLoop
;
    mov es:[si],al
    pop cx
    inc cx

msSend:
    xor al,al
    xchg al,ds:mcp_rec_start
    or al,al
    jz msRecStarted
;
    mov bx,ds:mcp_in_req
    IsUsbReqStarted
    jnc msRecStarted
;
    StartUsbReq

msRecStarted:
    mov bx,ds:mcp_out_req
    StartUsbReq

msWait:
    call mcp_wait_for_response
    jc msDone
;
    mov es,ds:mcp_out_buffer
    cmp dl,2
    je msCheckS
;
    or dl,dl
    jz msCheckI

msCheckS:
    mov al,fs:mf_pcb
    shr al,6
    and al,3
    cmp al,2
    je msCompS
;
    int 3
    jmp msWait

msCompS:
    mov al,es:mf_pcb
    and al,0Fh
    mov ah,fs:mf_pcb
    and ah,0Fh
    cmp al,ah
    je msOk
    jmp msFail

msCheckI:
    mov al,fs:ms_mtype
    cmp al,40h
    jne msFail
;
    mov al,es:ms_appl
    cmp al,fs:ms_appl
    jne msFail
;
    mov al,es:ms_cmnd
    cmp al,fs:ms_cmnd
    jne msFail
;
    jmp msOk

msFail:
    int 3
    mov es,ds:mcp_out_buffer
    stc
    jmp msDone

msOk:
    clc

msDone:
    ret
mcp_session Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendMcpResync
;
;           DESCRIPTION:    Send resync
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_mcp_resync	Proc near
    mov es,ds:mcp_out_buffer
    mov es:mf_da,1
    mov es:mf_sa,0
    mov es:mf_pcb,90h
    mov es:mf_len_high,0
    mov es:mf_len_low,0
    call mcp_session
    ret
send_mcp_resync Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitMcpMsg
;
;           DESCRIPTION:    Init mcp message
;
;           PARAMETERS:     AL    Application
;                           DL    Command
;                           CX    Size of data
;
;           RETURNS:        ES:DI Data buffer
;                           CX    Send size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mcp_msg	Proc near
    push ax
    push dx
;
    add cx,4
    mov es,ds:mcp_out_buffer
    mov es:mf_da,1
    mov es:mf_sa,0
    mov es:mf_len_high,ch
    mov es:mf_len_low,cl
    mov es:ms_mtype,0
    mov es:ms_appl,al
    mov es:ms_cmnd,dl
    add cx,SIZE mcp_frame
    mov di,SIZE mcp_msg
;
    mov al,ds:mcp_pcb
    mov es:mf_pcb,al
    xor al,2
    mov ds:mcp_pcb,al
;
    pop dx
    pop ax
    ret
init_mcp_msg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetMcpDevStringProp
;
;           DESCRIPTION:    Get mcp device string property
;
;           PARAMETERS:     AL    property ID
;
;           RETURNS:        ES:DI Property string
;                           CX    Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_mcp_dev_string_prop	Proc near
    push fs
    push ax
    push dx
;
    mov al,0
    mov dl,0
    mov cx,2
    call init_mcp_msg
;
    pop dx
    pop ax
;
    mov byte ptr es:[di],2
    mov es:[di+1],al
;
    call mcp_session
    jc gmdspDone
;
    mov es,ds:mcp_in_buffer
    mov al,es:ms_rc
    or al,al
    stc
    jnz gmdspDone
;
    mov cl,es:mf_len_low
    mov ch,es:mf_len_high
    sub cx,6
    mov di,SIZE mcp_msg
    add di,2
    clc

gmdspDone:
    pop fs
    ret
get_mcp_dev_string_prop     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetMcpStripDwordProp
;
;           DESCRIPTION:    Get mcp strip dword property
;
;           PARAMETERS:     AL    property ID
;
;           RETURNS:        EAX   Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_mcp_strip_dword_prop	Proc near
    push fs
;
    push ax
    push dx
;
    mov al,1
    mov dl,0
    mov cx,2
    call init_mcp_msg
;
    pop dx
    pop ax
;
    mov byte ptr es:[di],1
    mov es:[di+1],al
;
    call mcp_session
    jc gmsdpDone
;
    mov es,ds:mcp_in_buffer
    mov al,es:ms_rc
    or al,al
    stc
    jnz gmsdpDone
;
    mov cl,es:mf_len_low
    mov ch,es:mf_len_high
    sub cx,6
    mov di,SIZE mcp_msg
    add di,2
    clc

gmsdpDone:
    pop fs
    ret
get_mcp_strip_dword_prop     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           McpCardThread
;
;           DESCRIPTION:    USB MCP card thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mcp_card_thread_name  DB 'USB MCP Card Reader', 0

mcp_card_thread_pr:
    int 3
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:mcp_card_thread,ax
;
    call open_mcp

mctLoop:
    mov bx,ds:mcp_in_req
    IsUsbReqStarted
    jnc mctIntrStarted
;
    StartUsbReq

mctIntrStarted:
    mov bx,ds:mcp_in_req
    IsUsbReqReady
    jc mctNext
;
    int 3
    GetUsbReqData
    mov es,ds:mcp_in_buffer

mctNext:
    call send_mcp_resync
;
    mov al,0
    call get_mcp_dev_string_prop
;
    mov al,0
    call get_mcp_strip_dword_prop

    jmp mctLoop



    call close_mcp
    TerminateThread


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_attach
;
;           description:    USB attach callback
;
;           Parameters:     BX      Controller #
;               AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

devTab:
dt00    DW 0801h,       0Ah

usb_attach  Proc far
    push ds
    push es
    pushad
;    
    push ax
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop ax
    xor di,di
    push ax
    GetUsbDevice
    cmp ax,cx
    pop ax
    jne uaDone
;
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,1
    mov bp,OFFSET devTab

uaLoop:
    cmp si,cs:[bp]
    jne uaNext
;
    cmp di,cs:[bp+2]
    je uaFound

uaNext:
    add bp,4
    loop uaLoop    
;
    jmp uaDone    

uaFound:
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz uaDone
;
    mov dl,es:ucd_config_id
    ConfigUsbDevice
    jc uaDone
;
    mov dx,SEG data
    mov ds,dx
    mov ds:mcp_intr,0
    mov ds:mcp_bulk_in,0
    mov ds:mcp_bulk_out,0
    mov ds:mcp_in_size,0
    mov ds:mcp_out_size,0
;
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,4
    jne uaDescrNext
; 
    movzx cx,es:[di].uid_len
    add di,cx

uaIntLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne uaStart
;
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,3
    je uaIntr
;
    cmp cl,2
    jne uaIntNext
;
    mov cl,es:[di].ued_address
    test cl,80h    
    jnz uaBulkIn

uaBulkOut:
    and cl,0Fh
    mov ds:mcp_bulk_out,cl
    mov cx,es:[di].ued_maxsize
    mov ds:mcp_out_size,cx
    jmp uaIntNext

uaBulkIn:
    and cl,8Fh
    mov ds:mcp_bulk_in,cl
    mov cx,es:[di].ued_maxsize
    mov ds:mcp_in_size,cx
    jmp uaIntNext

uaIntr:
    mov cl,es:[di].ued_address
    and cl,8Fh
    mov ds:mcp_intr,cl
    
uaIntNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb uaIntLoop    

uaStart:
    mov cl,ds:mcp_bulk_in
    or cl,cl
    jz uaDone
;
    mov cl,ds:mcp_bulk_out
    or cl,cl
    jz uaDone
;
    mov cl,ds:mcp_intr
    or cl,cl
    jz uaDone
;
    mov ds:mcp_controller,bx
    mov ds:mcp_device,al
;
    mov ax,ds:mcp_card_thread
    or ax,ax
    jnz uaThreadStarted
;
    mov ds:mcp_card_thread,-1
    push ds
    push es
    push eax
    push esi
    push edi    
;    
    mov edx,cs
    mov ds,edx
    mov es,edx
    mov edi,OFFSET mcp_card_thread_name
    mov esi,OFFSET mcp_card_thread_pr
    mov ax,2
    mov ecx,stack0_size
    CreateThread
;
    pop edi
    pop esi
    pop eax
    pop es
    pop ds
        
uaThreadStarted:
    jmp uaDone

uaDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb uaDescrLoop    

uaDone:
    FreeMem
;
    popad
    pop es
    pop ds
    ret
usb_attach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_detach
;
;           description:    USB detach callback
;
;           Parameters:     BX      Controller #
;               AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    pushad
;    
;
    popad
    pop es
    pop ds
    ret
usb_detach  Endp

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
    mov ds:carddev_thread,0
    mov ds:card_state,0
    mov ds:mcp_card_thread,0
    mov ds:mcp_pcb,0
    mov ds:mcp_rec_start,0
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
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
    ret
Init    Endp
        
code    ENDS

    END Init
