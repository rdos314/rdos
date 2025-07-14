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
; TTP.ASM
; TTP2030 USB printer driver
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

MAX_IN_SIZE  = 1000h
MAX_OUT_SIZE = 260 * 16

FLAG_ATTACHED          = 1
FLAG_STARTED           = 2
FLAG_CLOSED            = 4
FLAG_WAS_LIFTED        = 8
FLAG_INIT              = 10h
FLAG_STATUS            = 20h

CMD_PRESENT           = 1
CMD_EJECT             = 2

STATUS_PAPER_JAM       = 1h
STATUS_CUTTER_JAM      = 2h
STATUS_NO_PAPER        = 4h
STATUS_HEAD_LIFTED     = 8h
STATUS_FEED_ERROR      = 10h
STATUS_TEMP_ERROR      = 20h
STATUS_PAPER_LOW       = 40h
STATUS_PAPER_PRESENTER = 80h
STATUS_OFFLINE         = 100h

ENQ = 5
ESC = 1Bh
RS = 1Eh
FF = 0Ch
ACK = 06h

bitmap_sel       STRUC

bs_line_size     DW ?
bs_height        DW ?
bs_data          DB ?

bitmap_sel       ENDS

usb_printer_struc       STRUC

ups_base_struc  printer_struc <>

usb_printer_struc       ENDS


data    SEGMENT byte public 'DATA'

tp_controller       DW ?
tp_port             DB ?
tp_type             DW ?

tp_dev_handle       DW ?

tp_max_in           DW ?
tp_wait             DW ?

tp_in_buffer        DW ?
tp_out_buffer       DW ?

tp_out_pipe         DB ?
tp_in_pipe          DB ?

tp_section          section_typ <>

tp_status           DW ?
tp_sensors          DW ?

tp_width            DW ?

tp_flag             DB ?
tp_cmd              DB ?
tp_present_mm       DB ?

tp_reset_counter    DW ?
tp_status_errors    DW ?

tp_server_thread    DW ?
tp_wait_thread      DW ?
tp_pr_thread        DW ?
tp_bitmap           DW ?

tp_init_count       DW ?

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadAnswer
;
;       DESCRIPTION:    Read answer
;
;       PARAMETERS:     DS        Data
;
;       RETURNS:        NC
;                         CX      Answer size
;                         ES      Answer buf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadAnswer   Proc near
    push eax
    push ebx
    push edx
    push edi
;
    GetSystemTime
    add eax,500 * 1193
    adc edx,0
    mov bx,ds:tp_wait
    WaitWithTimeout
;
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_in_pipe
    GetUsedUsbBuffers
    or cx,cx
    stc
    jz raDone
;
    mov es,ds:tp_in_buffer
    xor edi,edi
    movzx ecx,ds:tp_max_in
    GetUsbPacketPipe
    jc raDone

raLoop:
    add edi,ecx
    GetSystemTime
    add eax,10 * 1193
    adc edx,0
    mov bx,ds:tp_wait
    WaitWithTimeout
;
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_in_pipe
    GetUsedUsbBuffers
    or cx,cx
    jz raOk
;
    movzx ecx,ds:tp_max_in
    GetUsbPacketPipe
    jnc raLoop

raOk:
    mov cx,di
    clc

raDone:
    pop edi
    pop edx
    pop ebx
    pop eax
    ret
ReadAnswer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetByteParam
;
;       DESCRIPTION:    Get a byte parameter
;
;       PARAMETERS:     DS      Data
;                       BL      Parameter
;
;       RETURNS:        AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetByteParam   Proc near
    push es
    push ebx
    push ecx
    push edx
    push edi
;
    mov dx,ax
    mov es,ds:tp_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;
    mov al,ENQ
    stosb
;
    mov al,'P'
    stosb
;
    mov al,bl
    stosb
;
    mov cx,di
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
    jc gbpDone
;
    call ReadAnswer
    jc gbpDone
;
    cmp cx,1
    stc
    jnz gbpDone
;
    xor di,di
    mov al,es:[di]
    clc

gbpDone:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
GetByteParam    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetByteParam
;
;       DESCRIPTION:    Set a byte parameter
;
;       PARAMETERS:     DS      Data
;                       BL      Parameter
;                       AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetByteParam   Proc near
    push es
    push eax
    push ebx
    push ecx
    push edx
    push edi
;
    mov dx,ax
    mov es,ds:tp_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;
    mov al,'&'
    stosb
;
    mov al,'P'
    stosb
;
    mov al,bl
    stosb
;
    mov al,dl
    stosb                
;
    mov cx,di
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
SetByteParam    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckByteParam
;
;       DESCRIPTION:    Check byte parameter
;
;       PARAMETERS:     DS      Data
;                       BL      Parameter
;                       AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckByteParam   Proc near
    push dx
;
    mov dl,al
    call GetByteParam
    jc cbpWrite
;
    cmp al,dl
    clc
    je cbpDone

cbpWrite:
    mov al,dl
    call SetByteParam

cbpDone:
    pop dx
    ret
CheckByteParam  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NotifyStatus
;
;       DESCRIPTION:    Notify status
;
;       PARAMETERS:     DS      Data
;                       ES      Status
;                       CX      Size of status
;                       DX      Paper low
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stab:
st00 DW 0
st01 DW STATUS_PAPER_PRESENTER
st02 DW STATUS_CUTTER_JAM
st03 DW STATUS_NO_PAPER
st04 DW STATUS_HEAD_LIFTED
st05 DW STATUS_FEED_ERROR
st06 DW STATUS_TEMP_ERROR
st07 DW STATUS_PAPER_JAM
st08 DW STATUS_FEED_ERROR
st09 DW 0
st10 DW 0
st11 DW 0
st12 DW 0
st13 DW 0
st14 DW 0
st15 DW 0
st16 DW 0
st17 DW 0
st18 DW 0
st19 DW 0
st20 DW 0

NotifyStatus   Proc near
    push ax
    push bx
    push dx
    push di
;
    xor di,di
    or cx,cx
    jz nsReset
;
    cmp cx,1
    jne nsNext
;
    mov al,es:[di]
    cmp al,6
    je nsSave
    jmp nsDone
    
nsNext:
    mov al,es:[di]
    cmp al,15h
    stc
    jne nsDone
;
    sub cx,1
    stc
    jz nsDone
;
    inc di
    movzx bx,byte ptr es:[di]
    add bx,bx
    or dx,word ptr cs:[bx].stab
;
    inc di    
    sub cx,1
    jnz nsNext

nsSave:
    mov ds:tp_status,dx
    clc
    jmp nsDone

nsReset:
    test ds:tp_flag,FLAG_ATTACHED
    stc
    jz nsDone
;    
    mov bx,ds:tp_dev_handle
    ResetUsbDevice
    stc

nsDone:
    pop di
    pop dx
    pop bx
    pop ax
    ret
NotifyStatus    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UpdateStatus
;
;       DESCRIPTION:    Update printer status
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateStatus   Proc near
    push es
    push eax
    push ebx
    push edx
    push edi
;
    mov es,ds:tp_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;
    mov al,ENQ
    stosb
;
    mov al,2
    stosb
;
    mov cx,di
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
    jc usError
;
    call ReadAnswer
    jc usError

usLow:
    xor dx,dx
    xor di,di
    mov al,es:[di]
    or al,al
    jz usSensors
;
    mov dx,STATUS_PAPER_LOW

usSensors:
    mov es,ds:tp_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;
    mov al,ENQ
    stosb
;
    mov al,5
    stosb
;
    push dx
    mov cx,di
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
    pop dx
    jc usError
;
    call ReadAnswer
    jc usError
;
    xor di,di
    mov ax,es:[di]
    xchg al,ah
    mov ds:tp_sensors,ax

usNorm:
    mov es,ds:tp_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;
    mov al,ENQ
    stosb
;
    mov al,1
    stosb
;
    push dx
    mov cx,di
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
    pop dx
    jc usError
;
    call ReadAnswer
    jnc usOk

usError:
    mov ax,ds:tp_status_errors
    inc ds:tp_status_errors
    cmp ax,10
    jb usDone

usResetUsb:
    lock or ds:tp_status,STATUS_OFFLINE
    mov ds:tp_status_errors,0
    mov bx,ds:tp_dev_handle
    ResetUsbDevice
    jmp usDone

usOk:
    mov ds:tp_status_errors,0
    call NotifyStatus

usDone:
    pop edi
    pop edx
    pop ebx
    pop eax
    pop es
    ret
UpdateStatus    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DoHardReset
;
;       DESCRIPTION:    Do hard RESET
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoHardReset   Proc near
    push es
    push eax
    push ebx
    push edx
    push edi
;
    mov es,ds:tp_out_buffer
    xor edi,edi
;    
    mov al,ESC
    stosb
;
    mov al,'?'
    stosb
;
    mov cx,di
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
    jc hrDone
;
    mov ax,250
    WaitMilliSec
    clc

hrDone:
    pop edi
    pop edx
    pop ebx
    pop eax
    pop es
    ret
DoHardReset    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendPrint
;
;       DESCRIPTION:    Send printout
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendPrint   Proc near
    push es
    pushad
;
    mov es,ds:tp_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;    
    mov al,'p'
    stosb
;
    mov cx,di
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
;
    popad
    pop es
    ret
SendPrint    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendCut
;
;       DESCRIPTION:    Send cut command
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCut   Proc near
    push es
    pushad
;
    mov es,ds:tp_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;
    mov al,RS
    stosb
;
    mov cx,di
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
;
    popad
    pop es
    ret
SendCut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendPresent
;
;       DESCRIPTION:    Send present command
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendPresent   Proc near
    push es
    pushad
;
    mov es,ds:tp_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;
    mov al,FF
    stosb
;
    mov al,ds:tp_present_mm
    stosb
    clc
;
    mov cx,di
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
;
    popad
    pop es
    ret
SendPresent    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendEject
;
;       DESCRIPTION:    Send eject command
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendEject   Proc near
    push es
    pushad
;
    mov es,ds:tp_out_buffer
    xor edi,edi
;
    mov al,25
    stosb
;    
    mov al,0
    stosb
;
    mov cx,di
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
;
    popad
    pop es
    ret
SendEject    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendForce
;
;       DESCRIPTION:    Send force eject command
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendForce   Proc near
    push es
    pushad
;
    mov es,ds:tp_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;    
    mov al,FF
    stosb
;
    mov al,50
    stosb
;
    mov cx,di
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
;
    popad
    pop es
    ret
SendForce    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendLine
;
;       DESCRIPTION:    Print a single line
;
;       PARAMETERS:     DS      Data
;                       FS:ESI  Bitmap data
;
;       RETURNS:        FS:ESI  New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendLine   Proc near
    push es
    push eax
    push ebx
    push ecx
    push edx
    push edi
;
    push ds
    mov ax,es
    mov es,ds:tp_out_buffer
    mov ds,ax
    xor edi,edi
;
    mov al,ESC
    stosb
;    
    mov al,'s'
    stosb
;    
    mov ax,fs:bs_line_size
    stosb
;
    mov cx,fs:bs_line_size

poCopy:
    lods byte ptr fs:[esi]
    not al
    mov ah,al
    xor al,al
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    rcr ah,1
    rcl al,1
    stosb
    loop poCopy
;
    mov cx,di
    pop ds
;    
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    PostUsbRawPipe
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
SendLine    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendBitmap
;
;       DESCRIPTION:    Print bitmap
;
;       PARAMETERS:     DS      Printer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendBitmap    Proc near
    pushad
;
    xor bx,bx
    xchg bx,ds:tp_bitmap
    or bx,bx
    jz sbDone
;
    push fs
    mov fs,bx
;
    mov esi,OFFSET bs_data
    xor bp,bp
    xor dx,dx

sbLoop:
    inc bp
    cmp bp,128
    jne sbDo
;
    call UpdateStatus
;
    test ds:tp_flag,FLAG_ATTACHED
    stc
    jz sbFree

sbDo:
    call SendLine
    inc dx
;
    cmp dx,fs:bs_height
    jnz sbLoop

sbCut:
    call SendPrint
    call SendPrint
    call SendCut
    call UpdateStatus

sbFree:
    push es
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
    pop es
;
    pop fs
;
    mov bx,ds:tp_pr_thread
    Signal

sbDone:
    popad
    ret
SendBitmap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendCommand
;
;       DESCRIPTION:    Send print commands
;
;       PARAMETERS:     DS      Printer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCommand    Proc near
    pushad
;
    test ds:tp_cmd,CMD_PRESENT
    jz scNotPresent
;
    call SendPresent
    jc scNotPresent
;
    lock and ds:tp_cmd,NOT CMD_PRESENT

scNotPresent:
    test ds:tp_cmd,CMD_EJECT
    jz scNotEject
;
    call SendEject
    jc scNotEject
;
    lock and ds:tp_cmd,NOT CMD_EJECT

scNotEject:
    mov ax,ds:tp_sensors
    test ax,10h
    jz scNotClear
;
    call SendForce

scNotClear:
    popad
    ret
SendCommand  Endp

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
;               NAME:                   OpenPipes
;
;               DESCRIPTION:    Open USB pipes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPipes   Proc near
    push es
    mov eax,MAX_IN_SIZE
    AllocateSmallGlobalMem
    mov ds:tp_in_buffer,es
    pop es
;
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_in_pipe
    mov cx,10
    OpenUsbPacketPipe
;
    push es
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    mov cx,MAX_OUT_SIZE
    mov ax,25
    OpenUsbRawPipe
    mov ds:tp_out_buffer,es
    pop es
;
    CreateWait
    mov ds:tp_wait,bx
;
    mov ax,ds:tp_dev_handle
    mov dl,ds:tp_in_pipe
    mov ecx,ds
    AddWaitForUsbDevicePipe
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
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_in_pipe
    CloseUsbPipe
;
    mov bx,ds:tp_dev_handle
    mov dl,ds:tp_out_pipe
    CloseUsbPipe
;
    mov bx,ds:tp_wait
    CloseWait
;
    mov ds:tp_out_buffer,0
;
    lock or ds:tp_flag,FLAG_CLOSED
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

my_ttp_name DB 'TTP2030', 0

get_printer_name   Proc far
    push esi
    push edi
;
    mov esi,OFFSET my_ttp_name

get_pr_name_loop:    
    lods byte ptr cs:[esi]
    stos byte ptr es:[edi]
    or al,al
    jnz get_pr_name_loop
;
    pop edi
    pop esi    
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
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:tp_flag,FLAG_ATTACHED
    clc
    jz ijDone
;    
    mov ax,ds:tp_server_thread
    or ax,ax
    clc
    jz ijDone
;
    mov ax,ds:tp_status
    test ax,STATUS_PAPER_JAM
    clc
    jz ijDone
;
    stc
    
ijDone:
    pop ax
    pop ds
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
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:tp_flag,FLAG_ATTACHED
    clc
    jz iplDone
;
    mov ax,ds:tp_server_thread
    or ax,ax
    clc
    jz iplDone
;
    mov ax,ds:tp_status
    test ax,STATUS_PAPER_LOW
    clc
    jz iplDone
;
    stc
    
iplDone:
    pop ax
    pop ds
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
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:tp_flag,FLAG_ATTACHED
    clc
    jz ipeDone
;    
    mov ax,ds:tp_server_thread
    or ax,ax
    clc
    jz ipeDone
;
    mov ax,ds:tp_status
    test ax,STATUS_NO_PAPER
    clc
    jz ipeDone
;
    stc
    
ipeDone:
    pop ax
    pop ds
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
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:tp_flag,FLAG_ATTACHED
    clc
    jz icjDone
;
    mov ax,ds:tp_server_thread
    or ax,ax
    clc
    jz icjDone
;
    mov ax,ds:tp_status
    test ax,STATUS_CUTTER_JAM
    clc
    jz icjDone
;
    stc
    
icjDone:
    pop ax
    pop ds
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
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:tp_flag,FLAG_ATTACHED
    stc
    jz ioDone
;
    mov ax,ds:tp_server_thread
    or ax,ax
    stc
    jz ioDone
;
    mov ax,ds:tp_status
    test ax,STATUS_OFFLINE
    clc
    jz ioDone
;
    stc
    
ioDone:
    pop ax
    pop ds
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
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:tp_flag,FLAG_ATTACHED
    clc
    jz ihlDone
;    
    mov ax,ds:tp_server_thread
    or ax,ax
    clc
    jz ihlDone
;
    mov ax,ds:tp_status
    test ax,STATUS_HEAD_LIFTED
    clc
    jz ihlDone
;
    stc
    
ihlDone:
    pop ax
    pop ds
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
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:tp_flag,FLAG_ATTACHED
    clc
    jz hppDone
;
    mov ax,ds:tp_server_thread
    or ax,ax
    clc
    jz hppDone
;
    mov ax,ds:tp_sensors
    test ax,10h
    clc
    jz hppDone
;
    stc
    
hppDone:
    pop ax
    pop ds
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
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:tp_flag,FLAG_ATTACHED
    clc
    jz hteDone
;
    mov ax,ds:tp_server_thread
    or ax,ax
    clc
    jz hteDone
;
    mov ax,ds:tp_status
    test ax,STATUS_TEMP_ERROR
    clc
    jz hteDone
;
    stc
    
hteDone:
    pop ax
    pop ds
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
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:tp_flag,FLAG_ATTACHED
    clc
    jz hfeDone
;
    mov ax,ds:tp_server_thread
    or ax,ax
    clc
    jz hfeDone
;
    mov ax,ds:tp_status
    test ax,STATUS_FEED_ERROR
    clc
    jz hfeDone
;
    stc
    
hfeDone:
    pop ax
    pop ds
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
    push ds
    push ax
    push cx
;
    add dx,80
    cmp dx,1000
    ja create_bitmap_size_ok
;
    mov dx,1000

create_bitmap_size_ok:
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:tp_width
    mov ax,1
    CreateBitmap
    clc

create_bitmap_done:    
    pop cx
    pop ax
    pop ds
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
    push ds
    push es
    push fs
    pushad
;
    mov ax,SEG data
    mov ds,ax
    test ds:tp_flag,FLAG_ATTACHED
    stc
    jz pbDone
;
    mov ax,ds:tp_server_thread
    or ax,ax
    stc
    jz pbDone
;
    GetBitmapInfo
    jc pbDone
;
    cmp al,1
    jne pbDone
;
    or dx,dx
    jz pbDone
;
    mov ax,es
    mov ds,ax
    movzx ebp,si
;
    push edx
    movzx eax,dx
    mul ebp
    mov ecx,eax
    add eax,OFFSET bs_data
    mov esi,edi
    AllocateSmallGlobalMem
    pop edx
;
    mov es:bs_line_size,bp
    mov es:bs_height,dx
    mov edi,OFFSET bs_data
    rep movsb
    mov bx,es
;
    mov ax,SEG data
    mov ds,ax
    ClearSignal
    GetThread
    mov ds:tp_pr_thread,ax
    mov ds:tp_bitmap,bx
;
    mov bx,ds:tp_wait_thread
    signal
;
    GetSystemTime
    add eax,5000 * 1193
    adc edx,0
    WaitForSignalWithTimeout
    clc

pbDone:
    popad
    pop fs
    pop es
    pop ds
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
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    test ds:tp_flag,FLAG_ATTACHED
    stc
    jz pmDone
;
    mov ds:tp_present_mm,al
    lock or ds:tp_cmd,CMD_PRESENT
    mov bx,ds:tp_wait_thread
    signal

pmDone:
    pop bx
    pop ds
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
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    test ds:tp_flag,FLAG_ATTACHED
    stc
    jz emDone
;
    lock or ds:tp_cmd,CMD_EJECT
    mov bx,ds:tp_wait_thread
    signal

emDone:
    pop bx
    pop ds
    ret
eject_media  Endp

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
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    test ds:tp_flag,FLAG_ATTACHED
    stc
    jz fpDone
;
    mov bx,ds:tp_wait_thread
    signal

fpDone:
    pop bx
    pop ds
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
    test ds:tp_flag,FLAG_ATTACHED
    stc
    jz reset_done
;    
    mov bx,ds:tp_dev_handle
    ResetUsbDevice
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
;               NAME:           PrinterThread
;
;               DESCRIPTION:    Printer handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ttp2030_thread_name  DB 'TTP2030 ', 0

printer_thread:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:tp_server_thread,ax
    mov ds:tp_pr_thread,0
    mov ds:tp_bitmap,0
    mov ds:tp_wait_thread,0
    mov ds:tp_reset_counter,0
    mov ds:tp_status_errors,0
    mov ds:tp_status,0
    mov ds:tp_sensors,0
;
    mov eax,SIZE usb_printer_struc
    AllocateSmallGlobalMem
    mov es:printer_device,0
;    
    mov ax,ds:tp_controller
    movzx dx,ds:tp_port
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

prRestart:
    mov bx,ds:tp_controller
    mov al,ds:tp_port
    OpenUsbDevice
    mov ds:tp_dev_handle,bx
;
    call OpenPipes
;    
    lock or ds:tp_status,STATUS_OFFLINE
;
    mov cx,10

prInitLoop:
    mov bx,ds:tp_dev_handle
    IsUsbDeviceConnected
    jc prDetached
;
    test ds:tp_flag,FLAG_ATTACHED
    jz prDetached
;
    mov bl,48
    call GetByteParam
    jc prRetry
;
    or al,al
    jnz prCalc
;
    mov al,80
    mov bl,48
    call SetByteParam

prCalc:
    mov cl,8
    mul cl
    mov ds:tp_width,ax
    jmp prLoop

prRetry:
    loop prInitLoop
;
    mov bx,ds:tp_dev_handle
    IsUsbDeviceConnected
    jc prDetached
;
    test ds:tp_flag,FLAG_ATTACHED
    jz prDetached
;
    mov ax,ds:tp_reset_counter
    cmp ax,10
    jb prResetUsb
;
    mov ax,1000
    WaitMilliSec
;
    mov ax,ds:tp_reset_counter
    cmp ax,20
    jb prResetPrinter
;
    HasHardReset
    jc prDetached
;
    HardReset
    jmp prDetached

prResetPrinter:
    inc ds:tp_reset_counter
;
    call DoHardReset
    jmp prDetached

prResetUsb:
    inc ds:tp_reset_counter
;
    mov bx,ds:tp_dev_handle
    ResetUsbDevice
    jmp prDetached

prLoop:
    mov ds:tp_reset_counter,0
;
    mov bx,ds:tp_dev_handle
    IsUsbDeviceConnected
    jc prDetached
;
    test ds:tp_flag,FLAG_ATTACHED
    jz prDetached
;
    call UpdateStatus
;
    test ds:tp_status,STATUS_CUTTER_JAM
    jz prClearCutter
;
    test ds:tp_status,STATUS_HEAD_LIFTED
    jnz prSetLifted
;
    test ds:tp_flag,FLAG_WAS_LIFTED
    jz prClearDone
;
    mov ax,1000
    WaitMilliSec
;    
    call DoHardReset
    jmp prClearCutter

prSetLifted:
    lock or ds:tp_flag,FLAG_WAS_LIFTED
    jmp prClearDone

prClearCutter:
    lock and ds:tp_flag,NOT FLAG_WAS_LIFTED

prClearDone:    
    call SendBitmap
    call SendCommand
;
    GetThread
    mov ds:tp_wait_thread,ax
;
    GetSystemTime
    add eax,1500 * 1193
    adc edx,0
    WaitForSignalWithTimeout
;
    mov ds:tp_wait_thread,0
    jmp prLoop
        
prDetached:
    mov ax,5
    WaitMilliSec
;
    call ClosePipes
;
    xor bx,bx
    xchg bx,ds:tp_dev_handle
    CloseUsbDevice
;
    test ds:tp_flag,FLAG_ATTACHED
    jz prWaitAttach
;
    mov ecx,100

prWaitDetach:
    mov ax,25
    WaitMilliSec
;
    test ds:tp_flag,FLAG_ATTACHED
    jz prWaitAttach
;
    loop prWaitDetach

prWaitAttach:
    test ds:tp_flag,FLAG_ATTACHED
    jnz prRestart
;
    GetSystemTime
    add eax,250 * 1193
    adc edx,0
    WaitForSignalWithTimeout
    jmp prWaitAttach
       
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
    mov ax,ds:tp_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,ds:tp_port
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
;       NAME:           OpenPrinterPipes
;
;       description:    Create printer pipes
;
;       PARAMETERS:     AL      Device address
;                       AH      Port #
;                       BX      Controller id
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
    mov ds:tp_controller,bx
    mov ds:tp_port,al
    mov ds:tp_out_pipe,0
    mov ds:tp_in_pipe,0
    mov ds:tp_max_in,0
;
    lock or ds:tp_flag,FLAG_ATTACHED
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
    mov ds:tp_out_pipe,cl
    jmp opDescrNext

opBulkIn:
    and cl,8Fh
    mov ds:tp_in_pipe,cl
    mov ax,es:[di].ued_maxsize
    mov ds:tp_max_in,ax
    
opDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb opDescrLoop    
        
opDescrDone:
    mov al,ds:tp_in_pipe
    or al,al
    jz opDone
;    
    mov al,ds:tp_out_pipe
    or al,al
    jz opDone
;    
    test ds:tp_flag,FLAG_STARTED
    jnz opDone
;
    lock or ds:tp_flag,FLAG_STARTED    
;
    mov esi,OFFSET printer_thread
    mov edi,OFFSET ttp2030_thread_name
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
;                               AL      Device port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

aTab:
a01     DW 088Ch,       2030h   ; TTP2010

usb_attach  Proc far
    push es
;    
    push ax
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop ax
;
    push ax
    xor di,di
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
    mov dx,bp
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
;                               AL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    mov si,SEG data
    mov ds,si
    test ds:tp_flag,FLAG_ATTACHED
    jz udDone
;    
    cmp al,byte ptr ds:tp_port
    jne udDone
;
    cmp bx,ds:tp_controller
    jne udDone
;
    mov ax,5
    WaitMilliSec
;        
    mov cx,100
    lock and ds:tp_flag,NOT FLAG_ATTACHED

udWaitLoop:    
    mov bx,ds:tp_server_thread
    Signal
;
    mov ax,5
    WaitMilliSec
;
    test ds:tp_flag,FLAG_CLOSED
    jnz udWaitDone
;
    loop udWaitLoop    

udWaitDone:
    lock and ds:tp_flag,NOT FLAG_CLOSED
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
    mov ax,SEG data
    mov ds,ax
    InitSection ds:tp_section
    mov ds:tp_flag,0
    mov ds:tp_cmd,0
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
