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
; CARDDEV.ASM
; Card reader base class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\handle.inc
include ..\wait.inc
include carddev.inc

MAX_DEV = 8

carddev_handle_seg  STRUC

carddev_handle_base  handle_header <>

carddev_sel     DW ?

carddev_handle_seg  ENDS

data    SEGMENT byte public 'DATA'

cd_dev_count    DW ?
cd_dev_arr      DW MAX_DEV DUP(?)

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Delete_handle
;
;       DESCRIPTION:    Delete handle (called from handle module)
;
;       PARAMETERS:     BX              CARDDEV HANDLE
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push es
    push ax
    push dx
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc delete_handle_done
;
    FreeHandle

delete_handle_done:
    pop dx
    pop ax
    pop es
    pop ds
    retf32
delete_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMaxCardDev
;
;       description:    Get max usable card reader #
;
;       RETURNS:        AL      Max dev #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_max_carddev_name DB 'Get Max Card Devices',0

get_max_carddev        Proc far
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:cd_dev_count
    pop ds
    retf32
get_max_carddev    Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenCardDev
;
;       description:    Open card device
;
;       PARAMETERS:     AL              Device #
;
;       RETURNS:        BX              Card device handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_carddev_name DB 'Open Card Device',0

open_carddev       Proc far
    push ds
    push es
    push ax
    push cx
    push dx
;
    mov dx,SEG data
    mov ds,dx
    movzx dx,al
    cmp dx,ds:cd_dev_count
    jae open_carddev_fail
;    
    mov bx,dx
    add bx,bx
    mov es,ds:[bx].cd_dev_arr
;
    mov ax,CARDDEV_HANDLE
    mov cx,SIZE carddev_handle_seg
    AllocateHandle
    mov [ebx].carddev_sel,es
    mov [ebx].hh_sign,CARDDEV_HANDLE
    mov bx,[ebx].hh_handle
    clc
    jmp open_carddev_done
    
open_carddev_fail:
    xor bx,bx
    stc

open_carddev_done:
    pop dx
    pop cx
    pop ax
    pop es
    pop ds
    retf32 
open_carddev        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CloseCardDev
;
;       description:    Close card device
;
;       PARAMETERS:     BX              Card device handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_carddev_name DB 'Close Card Device',0

close_carddev       Proc far
    push ds
    push ax
    push dx
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc close_carddev_done
;
    FreeHandle

close_carddev_done:
    pop dx
    pop ax
    pop ds
    retf32
close_carddev       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetCardDevName
;
;       description:    Get card device name
;
;       PARAMETERS:     BX              Card device handle
;                       ES:(E)DI        Card device name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_carddev_name_name DB 'Get Card Device Name',0

get_carddev_name16       Proc far
    push ds
    push eax
    push ebx
    push edi
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc get_carddev_name_done16
;
    movzx edi,di
    mov ds,[ebx].carddev_sel
    mov eax,ds:cd_get_name_proc+4
    or ax,ax
    clc
    jz get_carddev_name_done16
;       
    call fword ptr ds:cd_get_name_proc

get_carddev_name_done16:
    pop edi
    pop ebx
    pop eax
    pop ds
    retf32
get_carddev_name16       Endp

get_carddev_name32       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc get_carddev_name_done32
;
    mov ds,[ebx].carddev_sel
    mov eax,ds:cd_get_name_proc+4
    or ax,ax
    clc
    jz get_carddev_name_done32
;       
    call fword ptr ds:cd_get_name_proc

get_carddev_name_done32:
    pop ebx
    pop eax
    pop ds
    retf32
get_carddev_name32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsCardDevOk
;
;       description:    Is card device OK
;
;       PARAMETERS:     BX              Card device handle
;
;       RETURNS:        NC              OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_carddev_ok_name DB 'Is Card Device Ok?',0

is_carddev_ok       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc is_carddev_ok_done
;
    mov ds,[ebx].carddev_sel
    mov eax,ds:cd_ok_proc+4
    or ax,ax
    stc
    jz is_carddev_ok_done
;       
    call fword ptr ds:cd_ok_proc

is_carddev_ok_done:
    pop ebx
    pop eax
    pop ds
    retf32
is_carddev_ok       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsCardDevBusy
;
;       description:    Is card device busy
;
;       PARAMETERS:     BX              Card device handle
;
;       RETURNS:        NC              Busy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_carddev_busy_name DB 'Is Card Device Busy?',0

is_carddev_busy       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc is_carddev_busy_done
;
    mov ds,[ebx].carddev_sel
    mov eax,ds:cd_busy_proc+4
    or ax,ax
    stc
    jz is_carddev_busy_done
;       
    call fword ptr ds:cd_busy_proc

is_carddev_busy_done:
    pop ebx
    pop eax
    pop ds
    retf32
is_carddev_busy       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsCardDevInserted
;
;       description:    Is card device inserted
;
;       PARAMETERS:     BX              Card device handle
;
;       RETURNS:        NC              Inserted
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_carddev_inserted_name DB 'Is Card Device Inserted?',0

is_carddev_inserted       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc is_carddev_inserted_done
;
    mov ds,[ebx].carddev_sel
    mov eax,ds:cd_inserted_proc+4
    or ax,ax
    stc
    jz is_carddev_inserted_done
;       
    call fword ptr ds:cd_inserted_proc

is_carddev_inserted_done:
    pop ebx
    pop eax
    pop ds
    retf32
is_carddev_inserted       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HadCardDevInserted
;
;       description:    Had card device inserted
;
;       PARAMETERS:     BX              Card device handle
;
;       RETURNS:        NC              Inserted
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

had_carddev_inserted_name DB 'Had Card Device Inserted?',0

had_carddev_inserted       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc had_carddev_inserted_done
;
    mov ds,[ebx].carddev_sel
    mov eax,ds:cd_had_inserted_proc+4
    or ax,ax
    stc
    jz had_carddev_inserted_done
;       
    call fword ptr ds:cd_had_inserted_proc

had_carddev_inserted_done:
    pop ebx
    pop eax
    pop ds
    retf32
had_carddev_inserted       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClearCardDevInserted
;
;       description:    Clear card device inserted
;
;       PARAMETERS:     BX              Card device handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_carddev_inserted_name DB 'Clear Card Device Inserted',0

clear_carddev_inserted       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc clear_carddev_inserted_done
;
    mov ds,[ebx].carddev_sel
    mov eax,ds:cd_clear_inserted_proc+4
    or ax,ax
    stc
    jz clear_carddev_inserted_done
;       
    call fword ptr ds:cd_clear_inserted_proc

clear_carddev_inserted_done:
    pop ebx
    pop eax
    pop ds
    retf32
clear_carddev_inserted       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitForCard
;
;       description:    Wait for card
;
;       PARAMETERS:     BX              Card device handle
;                       ES:(E)DI        Strip buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_card_name DB 'Wait For Card',0

wait_for_card16       Proc far
    push ds
    push eax
    push ebx
    push edi
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc wait_for_card_done16
;
    movzx edi,di
    mov ds,[ebx].carddev_sel
    mov eax,ds:cd_wait_for_card_proc+4
    or ax,ax
    clc
    jz wait_for_card_done16
;       
    call fword ptr ds:cd_wait_for_card_proc

wait_for_card_done16:
    pop edi
    pop ebx
    pop eax
    pop ds
    retf32
wait_for_card16       Endp

wait_for_card32       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc wait_for_card_done32
;
    mov ds,[ebx].carddev_sel
    mov eax,ds:cd_wait_for_card_proc+4
    or ax,ax
    clc
    jz wait_for_card_done32
;       
    call fword ptr ds:cd_wait_for_card_proc

wait_for_card_done32:
    pop ebx
    pop eax
    pop ds
    retf32
wait_for_card32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetCardDevTrack1
;
;       description:    Get track 1 from previous read
;
;       PARAMETERS:     BX              Card device handle
;                       ES:(E)DI        Track 1 buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_carddev_track1_name DB 'Get Card Track 1',0

get_carddev_track1_16       Proc far
    push ds
    push eax
    push ebx
    push edi
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc gct1_16
;
    movzx edi,di
    mov ds,[ebx].carddev_sel
    mov eax,ds:cd_get_track1_proc+4
    or ax,ax
    clc
    jz gct1_16
;       
    call fword ptr ds:cd_get_track1_proc

gct1_16:
    pop edi
    pop ebx
    pop eax
    pop ds
    retf32
get_carddev_track1_16       Endp

get_carddev_track1_32       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,CARDDEV_HANDLE
    DerefHandle
    jc gct1_32
;
    mov ds,[ebx].carddev_sel
    mov eax,ds:cd_get_track1_proc+4
    or ax,ax
    clc
    jz gct1_32
;       
    call fword ptr ds:cd_get_track1_proc

gct1_32:
    pop ebx
    pop eax
    pop ds
    retf32
get_carddev_track1_32       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddCardDevice
;
;       DESCRIPTION:    Add a card reader
;
;       PARAMETERS:     AX      Controller #
;                       DX      Device #
;                       DS      Card device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_carddev_name       DB 'Add Card Device',0

add_carddev    Proc far
    push ds
    push bx
    push dx
;
    mov ds:cd_ok_proc,0
    mov ds:cd_ok_proc+4,0
    mov ds:cd_busy_proc,0
    mov ds:cd_busy_proc+4,0
    mov ds:cd_inserted_proc,0
    mov ds:cd_inserted_proc+4,0
    mov ds:cd_had_inserted_proc,0
    mov ds:cd_had_inserted_proc+4,0
    mov ds:cd_clear_inserted_proc,0
    mov ds:cd_clear_inserted_proc+4,0
    mov ds:cd_wait_for_card_proc,0
    mov ds:cd_wait_for_card_proc+4,0
    mov ds:cd_get_track1_proc,0
    mov ds:cd_get_track1_proc+4,0
    mov ds:cd_get_name_proc,0
    mov ds:cd_get_name_proc+4,0
;
    mov dx,ds
    mov bx,SEG data
    mov ds,bx
;
    mov bx,ds:cd_dev_count
    add bx,bx
    mov ds:[bx].cd_dev_arr,dx
    inc ds:cd_dev_count
;
    pop dx
    pop bx
    pop ds    
    retf32
add_carddev    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init
;
;       description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET delete_handle
    mov ax,CARDDEV_HANDLE
    RegisterHandle
;
    mov esi,OFFSET add_carddev
    mov edi,OFFSET add_carddev_name
    xor cl,cl
    mov ax,add_carddev_nr
    RegisterOsGate
;
    mov esi,OFFSET get_max_carddev
    mov edi,OFFSET get_max_carddev_name
    xor dx,dx
    mov ax,get_max_carddev_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_carddev
    mov edi,OFFSET open_carddev_name
    xor dx,dx
    mov ax,open_carddev_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_carddev
    mov edi,OFFSET close_carddev_name
    xor dx,dx
    mov ax,close_carddev_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_carddev_ok
    mov edi,OFFSET is_carddev_ok_name
    xor dx,dx
    mov ax,is_carddev_ok_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_carddev_busy
    mov edi,OFFSET is_carddev_busy_name
    xor dx,dx
    mov ax,is_carddev_busy_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_carddev_inserted
    mov edi,OFFSET is_carddev_inserted_name
    xor dx,dx
    mov ax,is_carddev_inserted_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET had_carddev_inserted
    mov edi,OFFSET had_carddev_inserted_name
    xor dx,dx
    mov ax,had_carddev_inserted_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET clear_carddev_inserted
    mov edi,OFFSET clear_carddev_inserted_name
    xor dx,dx
    mov ax,clear_carddev_inserted_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET wait_for_card16
    mov esi,OFFSET wait_for_card32
    mov edi,OFFSET wait_for_card_name
    mov dx,virt_es_in
    mov ax,wait_for_card_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_carddev_track1_16
    mov esi,OFFSET get_carddev_track1_32
    mov edi,OFFSET get_carddev_track1_name
    mov dx,virt_es_in
    mov ax,get_carddev_track1_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_carddev_name16
    mov esi,OFFSET get_carddev_name32
    mov edi,OFFSET get_carddev_name_name
    mov dx,virt_es_in
    mov ax,get_carddev_name_nr
    RegisterUserGate
;
    mov bx,SEG data
    mov es,bx
    mov cx,2 + 2 * MAX_DEV
    xor di,di
    xor al,al
    rep stosb
    clc
    ret
init    Endp


code    ENDS

    END init
