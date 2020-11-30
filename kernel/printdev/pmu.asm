;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2010, Leif Ekblad
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
; pmu.ASM
; Citizen pmu USB printer driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\os\printer.inc
INCLUDE ..\os\protseg.def
include ..\usbdev\usb.inc

        .386p

MAX_OUT_SIZE = 260 * 16

FLAG_ATTACHED          = 1
FLAG_STARTED           = 2
FLAG_CLOSED            = 4
FLAG_INIT              = 8
FLAG_STATUS            = 10h

GS_CH                  = 1Dh

usb_printer_struc       STRUC

ups_base_struc  printer_struc <>

usb_printer_struc       ENDS

cmd_session_struc   STRUC

cs_next         DW ?

cs_req_size     DW ?

cs_reply_min    DW ?
cs_reply_size   DW ?
cs_reply_buf    DW ?      

cs_wait         DW ?

cmd_session_struc   ENDS


data    SEGMENT byte public 'DATA'

pmu_controller       DW ?
pmu_device           DB ?
pmu_port             DB ?

pmu_max_in           DW ?

pmu_in_buffer        DW ?
pmu_out_buffer       DW ?

pmu_in_handle        DW ?
pmu_out_handle       DW ?

pmu_in_req           DW ?
pmu_out_req          DW ?

pmu_out_pipe         DB ?
pmu_in_pipe          DB ?

pmu_section          section_typ <>

pmu_flag             DB ?

pmu_session_thread   DW ?

pmu_session_list     DW ?
pmu_session_count    DW ?

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateSessionSel
;
;       DESCRIPTION:    Create a session selector
;
;       PARAMETERS:     CX      Size of send buffer
;
;       RETURNS:        ES      Session sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSessionSel   Proc near
    push eax
    mov ax,SIZE cmd_session_struc
    add ax,cx
    movzx eax,ax
    AllocateSmallGlobalMem
    mov es:cs_next,0
    mov es:cs_req_size,cx
    mov es:cs_reply_min,0
    mov es:cs_reply_size,0
    mov es:cs_reply_buf,0
    mov es:cs_wait,0
    pop eax
    ret
CreateSessionSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeSessionSel
;
;       DESCRIPTION:    Free a session selector
;
;       PARAMETERS:     ES      Session sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeSessionSel   Proc near
    push ax
;    
    mov ax,es:cs_reply_size
    or ax,ax
    jz fssReplyOk
;
    push es
    mov es,es:cs_reply_buf
    FreeMem
    pop es 

fssReplyOk:
    FreeMem
;
    pop ax
    ret
FreeSessionSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateWaitSessionSel
;
;       DESCRIPTION:    Create a wait-for-answer session selector
;
;       PARAMETERS:     CX      Size of send buffer
;
;       RETURNS:        ES      Session sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateWaitSessionSel   Proc near
    push ax
    call CreateSessionSel
    GetThread
    mov es:cs_wait,ax
    pop ax
    ret
CreateWaitSessionSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InsertSessionSel
;
;       DESCRIPTION:    Insert session selector into session list
;
;       PARAMETERS:     DS      Data
;                       ES      Session sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertSessionSel   Proc near
    push bx
    EnterSection ds:pmu_section
;    
    inc ds:pmu_session_count
    mov bx,ds:pmu_session_list
    or bx,bx
    jz issEmpty
;
    push fs

issNext:
    mov fs,bx
    mov bx,fs:cs_next
    or bx,bx
    jnz issNext
;
    mov es:cs_next,0
    mov fs:cs_next,es
    pop fs
    jmp issDone

issEmpty:
    mov es:cs_next,0
    mov ds:pmu_session_list,es

issDone:
    LeaveSection ds:pmu_section
    mov bx,ds:pmu_session_thread
    Signal
    pop bx
    ret
InsertSessionSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DoSession
;
;       DESCRIPTION:    Perform session
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoSession   Proc near
    push es
    push ax

dsLoop:    
    mov ax,ds:pmu_session_list
    or ax,ax
    jz dsDone
;
    EnterSection ds:pmu_section
    mov es,ds:pmu_session_list
    mov ax,es:cs_next
    mov ds:pmu_session_list,ax
    dec ds:pmu_session_count
    LeaveSection ds:pmu_section
;
    test ds:pmu_flag,FLAG_ATTACHED
    jz dsCheckRead
;    
    push ds
    push es
    pusha
;    
    mov cx,50
    mov bx,ds:pmu_out_req
    IsUsbReqStarted
    jc dsWriteDo

dsWriteWait:    
    IsUsbReqReady
    jnc dsWriteDo
;
    test ds:pmu_flag,FLAG_ATTACHED
    jz dsWritePop
;
    mov ax,5
    WaitMilliSec
    loop dsWriteWait
;
    jmp dsWritePop

dsWriteDo:
    mov ax,es
    mov es,ds:pmu_out_buffer
    mov ds,ax
    mov si,SIZE cmd_session_struc
    xor di,di
    mov cx,ds:cs_req_size
    rep movsb
    mov cx,ds:cs_req_size
    StartUsbReq

dsWritePop:
    popa
    pop es
    pop ds    

dsCheckRead:
    mov ax,es:cs_wait
    or ax,ax
    jz dsFree
;
    push bx
    push cx
;
    test ds:pmu_flag,FLAG_ATTACHED
    jz dsSignal
;
    mov cx,10

dsReadLoop:
    mov bx,ds:pmu_in_req
    IsUsbReqStarted
    jnc dsReadStarted
;
    push es
    StartUsbReq
    pop es

dsReadStarted:    
    mov bx,ds:pmu_in_req
    IsUsbReqReady
    jnc dsGetData
;
    test ds:pmu_flag,FLAG_ATTACHED
    jz dsSignal
;
    mov ax,5
    WaitMilliSec
    loop dsReadLoop
;
    jmp dsSignal

dsGetData:
    push es
    GetUsbReqData
    pop es
    jc dsSignal
;
    push ds
    push es
    push cx
    push si
    push di
    mov ds,ds:pmu_in_buffer
    xor si,si
    mov ax,cx
    cmp ax,es:cs_reply_min
    jae dsAllocReply
;
    mov ax,es:cs_reply_min

dsAllocReply:
    movzx eax,ax
    AllocateSmallGlobalMem
    xor di,di
    rep movsb
    mov ax,es
    pop di
    pop si
    pop cx
    pop es
    pop ds
;
    mov es:cs_reply_buf,ax
    mov es:cs_reply_size,cx

dsReadMore:
    test ds:pmu_flag,FLAG_ATTACHED
    jz dsSignal
;
    cmp cx,es:cs_reply_min
    jae dsSignal
;
    mov bx,ds:pmu_in_req
    push es
    StartUsbReq
    pop es
;    
    mov ax,5
    WaitMilliSec
;    
    IsUsbReqReady
    jc dsSignal
;
    push es
    GetUsbReqData
    pop es
    jc dsSignal
;
    push ds
    push es
    push cx
    push si
    push di
    mov ds,ds:pmu_in_buffer
    xor si,si
    mov di,es:cs_reply_size
    mov ax,di
    add ax,cx
    cmp ax,es:cs_reply_min
    jbe dsCopyMore
;
    mov cx,es:cs_reply_min
    sub cx,di

dsCopyMore:    
    mov es,es:cs_reply_buf
    rep movsb
    pop di
    pop si
    pop cx
    pop es
    pop ds
;
    add es:cs_reply_size,cx
    mov cx,es:cs_reply_size
    jmp dsReadMore

dsSignal:
    mov bx,es:cs_wait
    Signal
    pop cx
    pop bx
    jmp dsLoop

dsFree:
    call FreeSessionSel
    jmp dsLoop

dsDone:
    pop ax
    pop es
    ret
DoSession   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NotifyUsbData
;
;       DESCRIPTION:    Handle incoming data
;
;       PARAMETERS:     DS      SEG data
;                       CX      Size
;                       ES      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyUsbData   Proc near
    int 3
    ret
NotifyUsbData   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetId
;
;       DESCRIPTION:    Get printer ID
;
;       PARAMETERS:     DS      Data
;                       AL      ID #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetId   Proc near
    push es
    push cx
    push di
;
    mov ah,al
    mov bx,ds:pmu_out_req
    mov es,ds:pmu_out_buffer
    xor di,di
;    
    mov al,GS_CH
    stosb
;
    mov al,'I'
    stosb
;
    mov al,ah
    stosb
;
    test ds:pmu_flag,FLAG_ATTACHED
    jz giOffline
;    
    mov cx,3
    StartUsbReq
;
    xor dx,dx
    mov bx,ds:pmu_in_req
    IsUsbReqStarted
    jnc giLoop
;
    StartUsbReq

giLoop:
    mov ax,5
    WaitMilliSec
;
    test ds:pmu_flag,FLAG_ATTACHED
    jz giOffline
;
    mov bx,ds:pmu_in_req
    IsUsbReqReady
    jnc giRead
;
    inc dx
    cmp dx,30
    jne giLoop
;
    jmp giOffline

giRead:
    GetUsbReqData
    mov es,ds:pmu_in_buffer
;
    StartUsbReq
;
    mov ax,5
    WaitMilliSec
;
    test ds:pmu_flag,FLAG_ATTACHED
    jz giOffline
;
    mov bx,ds:pmu_in_req
    IsUsbReqReady
    jnc giRead
    jmp giOk

giOffline:    

giOk:
    pop di
    pop cx
    pop es
    ret
GetId    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClearReceiver
;
;       DESCRIPTION:    Clear receiver
;
;       PARAMETERS:     DS      SEG data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearReceiver    Proc near
    mov bx,ds:pmu_in_req
    IsUsbReqStarted
    jnc crLoop

    StartUsbReq
    mov ax,50
    WaitMilliSec

crLoop:
    IsUsbReqReady
    jc crDone
;
    push es
    GetUsbReqData
    pop es
    jc crDone
;
    StartUsbReq
;
    mov ax,50
    WaitMilliSec
    jmp crLoop

crDone:
    ret
ClearReceiver    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   OpenPipes
;
;               DESCRIPTION:    Open USB pipes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPipes   Proc near
    mov bx,ds:pmu_controller
    mov al,ds:pmu_device
    mov dl,ds:pmu_in_pipe
    OpenUsbPipe
    mov ds:pmu_in_handle,bx
;
    CreateUsbReq
    mov ds:pmu_in_req,bx    
    mov cx,ds:pmu_max_in
    AddReadUsbDataReq
    mov ds:pmu_in_buffer,es
;
    mov bx,ds:pmu_controller
    mov al,ds:pmu_device
    mov dl,ds:pmu_out_pipe
    OpenUsbPipe    
    mov ds:pmu_out_handle,bx
;
    CreateUsbReq
    mov ds:pmu_out_req,bx
    mov cx,MAX_OUT_SIZE
    AddWriteUsbDataReq
    mov ds:pmu_out_buffer,es
;
    ret
OpenPipes   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               ClosePipes
;
;               DESCRIPTION:    Close pipes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePipes    Proc near
    mov ax,SEG data
    mov ds,ax
    xor ax,ax
    mov es,ax
    mov fs,ax
;    
    mov bx,ds:pmu_in_req
    CloseUsbReq
    mov ds:pmu_in_req,0
;
    mov bx,ds:pmu_in_handle
    CloseUsbPipe    
    mov ds:pmu_in_handle,0
;
    mov bx,ds:pmu_out_req
    CloseUsbReq
    mov ds:pmu_out_req,0
;
    mov bx,ds:pmu_out_handle
    CloseUsbPipe    
    mov ds:pmu_out_handle,0
    mov ds:pmu_in_buffer,0
    mov ds:pmu_out_buffer,0
;
    lock or ds:pmu_flag,FLAG_CLOSED
    ret
ClosePipes   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetPrinterName
;
;       DESCRIPTION:    Get printer name
;
;       PARAMETERS:     DS          Printer sel
;                       ES:EDI      Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

my_name DB 'PMU', 0

get_printer_name   Proc far
    push si
    push edi
;
    mov si,OFFSET my_name

get_pr_name_loop:    
    lods byte ptr cs:[si]
    stos byte ptr es:[edi]
    or al,al
    jnz get_pr_name_loop
;
    pop edi
    pop si    
    ret
get_printer_name   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsJammed
;
;       DESCRIPTION:    Check if printer is jammed
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Jammed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_jammed   Proc far
    clc
    ret
is_jammed   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsPaperLow
;
;       DESCRIPTION:    Check if paper is low
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Low
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_paper_low   Proc far
    clc
    ret
is_paper_low   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsPaperEnd
;
;       DESCRIPTION:    Check if paper is end
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          End
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_paper_end   Proc far
    clc
    ret
is_paper_end   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsCutterJammed
;
;       DESCRIPTION:    Check if cutter is jammed
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Cutter jammed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_cutter_jammed   Proc far
    clc
    ret
is_cutter_jammed   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsOk
;
;       DESCRIPTION:    Check if printer is ok (functional)
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        NC          OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_ok   Proc far
    clc
    ret
is_ok   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsHeadLifted
;
;       DESCRIPTION:    Check if printer head is lifted
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Head lifted
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_head_lifted   Proc far
    clc
    ret
is_head_lifted   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasPaperInPresenter
;
;       DESCRIPTION:    Check if printer has paper in presenter
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Paper in presenter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_paper_in_presenter   Proc far
    clc
    ret
has_paper_in_presenter   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasTempError
;
;       DESCRIPTION:    Check for temperature error
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Temperature error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_temp_error   Proc far
    clc
    ret
has_temp_error   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasFeedError
;
;       DESCRIPTION:    Check for feed error
;
;       PARAMETERS:     DS          Printer sel
;
;       RETURNS:        CY          Feed error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_feed_error   Proc far
    ret
has_feed_error   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           print_test
;
;       DESCRIPTION:    Print test page
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_test   Proc far
    ret
print_test    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           create_bitmap
;
;       DESCRIPTION:    Create printer bitmap
;
;       PARAMETERS:     DS      Data
;                       DX      Height
;
;       RETURNS:        BX      Bitmap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_bitmap   Proc far
    ret
create_bitmap    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           print_bitmap
;
;       DESCRIPTION:    Print bitmap
;
;       PARAMETERS:     DS      Data
;                       BX      Bitmap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_bitmap   Proc far
    ret
print_bitmap    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PresentMedia
;
;       DESCRIPTION:    Present media
;
;       PARAMETERS:     DS      Data
;                       AX      Amount in mm to present
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

present_media   Proc far
    ret
present_media    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           EjectMedia
;
;       DESCRIPTION:    Eject media
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eject_media   Proc far
    ret
eject_media    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitForPrint
;
;       DESCRIPTION:    Wait for print to complete
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_print   Proc far
    ret
wait_for_print    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ResetPrinter
;
;       DESCRIPTION:    Reset printer (USB)
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_printer   Proc far
    push ds
    push es
    push ax
    push cx
    push di
;
    mov ax,SEG data
    mov ds,ax
    test ds:pmu_flag,FLAG_ATTACHED
    stc
    jz reset_done
;    
    lock and ds:pmu_flag,NOT FLAG_ATTACHED
    mov bx,ds:pmu_controller
    mov al,ds:pmu_port
    OpenUsbDevice
    ResetUsbDevice
    CloseUsbDevice
    clc

reset_done:    
    pop di
    pop cx
    pop ax
    pop es
    pop ds
    ret
reset_printer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StatusTimeout
;
;       DESCRIPTION:    Timer that signals control thread in order to read status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StatusTimeout  Proc far
    mov ax,SEG data
    mov ds,ax
    lock or ds:pmu_flag,FLAG_STATUS
;
    mov bx,ds:pmu_session_thread
    or bx,bx
    jz stDone
;    
    Signal    
;    
    add eax,1193000 * 2 ; 2s to next call
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET StatusTimeout
    mov bx,ds:pmu_session_thread
    StartTimer

stDone:    
    ret
StatusTimeout  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           InitKrThread
;
;               DESCRIPTION:    Init PMU printer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread_name  DB 'Init PMU ', 0

init_thread Proc far
    mov ax,SEG data
    mov ds,ax
    int 3
    ret
init_thread Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HexToAscii
;
;   DESCRIPTION:    
;
;   PARAMETERS:     AL      Number to convert
;
;   RETURNS:        AX      Ascii result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HexToAscii      PROC near
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
;
    add al,7

ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
;
    add ah,7

ok_high1:
    add ah,30h
    ret
HexToAscii      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartThread
;
;       DESCRIPTION:    Start thread
;
;       PARAMETERS:     DS      Data seg
;                       AX      Prio
;                       ESI     Entry
;                       EDI     Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartThread Proc near
    push ds
    push es            
;
    push ax
    push esi
;
    mov esi,edi
    mov eax,100h
    AllocateSmallGlobalMem
    xor edi,edi

sfCopyLoop:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz sfCopyDone
;
    stosb
    jmp sfCopyLoop

sfCopyDone:
    mov ax,ds:pmu_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,ds:pmu_port
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;
    pop esi         
;
    mov ebx,ds
    xor edi,edi
    mov eax,cs
    mov ds,eax
    pop ax
    mov ecx,stack0_size
    CreateThread
;
    FreeMem
;
    pop es
    pop ds
    ret
StartThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PmuThread
;
;               DESCRIPTION:    Printer handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pmu_thread_name  DB 'PMU ', 0

pmu_thread:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:pmu_session_thread,ax
;
    mov eax,SIZE usb_printer_struc
    AllocateSmallGlobalMem
    mov es:printer_device,0
;    
    mov ax,ds:pmu_controller
    movzx dx,ds:pmu_device
    push ds
    mov bx,es
    mov ds,bx
    AddPrinter
    pop ds
;
    mov es:pr_get_name_proc,OFFSET get_printer_name
    mov es:pr_get_name_proc+4,cs
;
    mov es:pr_jammed_proc,OFFSET is_jammed
    mov es:pr_jammed_proc+4,cs
;    
    mov es:pr_paper_low_proc,OFFSET is_paper_low
    mov es:pr_paper_low_proc+4,cs
;    
    mov es:pr_paper_end_proc,OFFSET is_paper_end
    mov es:pr_paper_end_proc+4,cs
;    
    mov es:pr_cutter_jammed_proc,OFFSET is_cutter_jammed
    mov es:pr_cutter_jammed_proc+4,cs
;    
    mov es:pr_ok_proc,OFFSET is_ok
    mov es:pr_ok_proc+4,cs
;    
    mov es:pr_head_lifted_proc,OFFSET is_head_lifted
    mov es:pr_head_lifted_proc+4,cs
;    
    mov es:pr_paper_in_presenter_proc,OFFSET has_paper_in_presenter
    mov es:pr_paper_in_presenter_proc+4,cs
;    
    mov es:pr_temp_error_proc,OFFSET has_temp_error
    mov es:pr_temp_error_proc+4,cs
;    
    mov es:pr_feed_error_proc,OFFSET has_feed_error
    mov es:pr_feed_error_proc+4,cs
;    
    mov es:pr_print_test_proc,OFFSET print_test
    mov es:pr_print_test_proc+4,cs
;    
    mov es:pr_create_bitmap_proc,OFFSET create_bitmap
    mov es:pr_create_bitmap_proc+4,cs
;    
    mov es:pr_print_bitmap_proc,OFFSET print_bitmap
    mov es:pr_print_bitmap_proc+4,cs
;    
    mov es:pr_present_media_proc,OFFSET present_media
    mov es:pr_present_media_proc+4,cs
;    
    mov es:pr_eject_media_proc,OFFSET eject_media
    mov es:pr_eject_media_proc+4,cs
;    
    mov es:pr_wait_for_print_proc,OFFSET wait_for_print
    mov es:pr_wait_for_print_proc+4,cs
;    
    mov es:pr_reset_proc,OFFSET reset_printer
    mov es:pr_reset_proc+4,cs
;    
    GetSystemTime
    add eax,1193000 * 2  ; 2s
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET StatusTimeout
    mov bx,ds:pmu_session_thread
    mov cx,ds       
    StartTimer

pmuRestart:
    mov ax,250
    WaitMilliSec
;
    call OpenPipes
    call ClearReceiver
;    
    int 3
    mov al,'1'
    call GetId

    lock or ds:pmu_flag, FLAG_INIT
;    
    mov esi,OFFSET init_thread
    mov edi,OFFSET init_thread_name
    mov ax,2
    call StartThread
    
pmuLoop:
    test ds:pmu_flag,FLAG_ATTACHED
    jz pmuDetached

pmuDoSession:
    call DoSession
;
    test ds:pmu_flag,FLAG_INIT
    jz pmuDoStatus
;
    mov ax,50
    WaitMilliSec
    jmp pmuLoop        

pmuDoStatus:
    mov bx,ds:pmu_session_list
    or bx,bx
    jnz pmuLoop

pmuWait:    
    WaitForSignal
    jmp pmuLoop
        
pmuDetached:
    mov ax,5
    WaitMilliSec
;    
    mov ax,ds:pmu_session_list
    or ax,ax
    jz pmuDetachClose
;
    EnterSection ds:pmu_section
    mov es,ds:pmu_session_list
    mov ax,es:cs_next
    mov ds:pmu_session_list,ax
    dec ds:pmu_session_count
    LeaveSection ds:pmu_section
;
    mov bx,es:cs_wait
    or bx,bx
    jz pmuFreeSession
;
    Signal
    xor ax,ax
    mov es,ax
    jmp pmuDetached
        
pmuFreeSession:
    call FreeSessionSel
    xor ax,ax
    mov es,ax
    jmp pmuDetached

pmuDetachClose:
    test ds:pmu_flag,FLAG_INIT
    jnz pmuDetached
;    
    call ClosePipes

pmuWaitAttach:
    test ds:pmu_flag,FLAG_ATTACHED
    jnz pmuRestart
;
    WaitForSignal
    jmp pmuWaitAttach        
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenPrinterPipes
;
;       description:    Create printer pipes
;
;       PARAMETERS:     AL      Device address
;                       AH      Port #
;                       BX      Controller id
;                       DX      Device type
;                       ES:DI   Interface descriptor + endpoints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPrinterPipes Proc near
    push ds
    push es
    pushad
;    
    mov si,SEG data
    mov ds,si
;    
    mov ds:pmu_controller,bx
    mov ds:pmu_device,al
    mov ds:pmu_port,ah
    mov ds:pmu_out_pipe,0
    mov ds:pmu_in_pipe,0
    mov ds:pmu_max_in,0
    mov ds:pmu_session_list,0
    mov ds:pmu_session_count,0
;
    lock or ds:pmu_flag,FLAG_ATTACHED
;
    movzx cx,es:[di].uid_len
    add di,cx

opDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne opDescrDone
;
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,2
    jne opDescrNext
;
    mov cl,es:[di].ued_address
    test cl,80h    
    jnz opBulkIn

opDescrBulkOut:
    and cl,0Fh
    mov ds:pmu_out_pipe,cl
    jmp opDescrNext

opBulkIn:
    and cl,8Fh
    mov ds:pmu_in_pipe,cl
    mov ax,es:[di].ued_maxsize
    mov ds:pmu_max_in,ax
    
opDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb opDescrLoop    
        
opDescrDone:
    mov al,ds:pmu_in_pipe
    or al,al
    jz opDone
;    
    mov al,ds:pmu_out_pipe
    or al,al
    jz opDone
;    
    test ds:pmu_flag,FLAG_STARTED
    jnz opDone
;
    lock or ds:pmu_flag,FLAG_STARTED    
;
    mov esi,OFFSET pmu_thread
    mov edi,OFFSET pmu_thread_name
    mov ax,2
    call StartThread
    
opDone:
    popad
    pop es
    pop ds
    ret
OpenPrinterPipes Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           usb_attach
;
;               description:    USB attach callback
;
;               Parameters:     BX      Controller #
;                               AL      Device address
;                               AH      Device port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

aTab:
a00     DW 1D90h,       211Bh   ; PMU

usb_attach  Proc far
    push es
;    
    push ax
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop ax
    xor di,di
    push ax
    mov al,ah
    GetUsbDevice
    cmp ax,cx
    pop ax
    jne aDone
;
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,1
    mov bp,OFFSET aTab

aLoop:
    cmp si,cs:[bp]
    jne aNext
;
    cmp di,cs:[bp+2]
    je aFound

aNext:
    add bp,4
    loop aLoop        
;
    jmp aDone    

aFound:
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    mov al,ah
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz aDone
;
    mov dl,es:ucd_config_id
    ConfigUsbDevice
    jc aDone
;
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

aDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,4
    jne aDescrNext
; 
    call OpenPrinterPipes
    jmp aDone

aDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb aDescrLoop    
    
aDone:
    FreeMem
;
    pop es    
    ret
usb_attach  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           usb_detach
;
;               description:    USB detach callback
;
;               Parameters:     BX      Controller #
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    mov si,SEG data
    mov ds,si
    test ds:pmu_flag,FLAG_ATTACHED
    jz udDone
;    
    cmp al,byte ptr ds:pmu_device
    jne udDone
;
    cmp bx,ds:pmu_controller
    jne udDone
;
    mov ax,5
    WaitMilliSec
;        
    mov cx,100
    lock and ds:pmu_flag,NOT FLAG_ATTACHED

udWaitLoop:    
    mov bx,ds:pmu_session_thread
    Signal
;
    mov ax,5
    WaitMilliSec
;
    test ds:pmu_flag,FLAG_CLOSED
    jnz udWaitDone
;
    loop udWaitLoop    

udWaitDone:
    lock and ds:pmu_flag,NOT FLAG_CLOSED
    mov ax,25
    WaitMilliSec

udDone:    
    ret
usb_detach  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   init
;
;               description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
;
    mov ax,SEG data
    mov ds,ax
    InitSection ds:pmu_section
    mov ds:pmu_flag,0
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
    clc
    ret
init    Endp


code    ENDS

        END init
