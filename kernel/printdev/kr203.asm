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
; KR203.ASM
; KR203 USB printer driver
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
CMD_FORCE             = 4

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

kr_controller       DW ?
kr_port             DB ?

kr_dev_handle       DW ?

kr_max_in           DW ?
kr_wait             DW ?

kr_in_buffer        DW ?
kr_out_buffer       DW ?

kr_out_pipe         DB ?
kr_in_pipe          DB ?

kr_section          section_typ <>

kr_status           DW ?

kr_width            DW ?

kr_flag             DB ?
kr_cmd              DB ?
kr_present_mm       DB ?

kr_reset_counter    DW ?
kr_status_errors    DW ?

kr_server_thread    DW ?
kr_wait_thread      DW ?
kr_pr_thread        DW ?
kr_bitmap           DW ?

kr_init_count       DW ?

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
    mov bx,ds:kr_wait
    WaitWithTimeout
;
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_in_pipe
    GetUsedUsbBuffers
    or cx,cx
    stc
    jz raDone
;
    mov es,ds:kr_in_buffer
    xor edi,edi
    movzx ecx,ds:kr_max_in
    GetUsbPacketPipe
    jc raDone

raLoop:
    add edi,ecx
    GetSystemTime
    add eax,10 * 1193
    adc edx,0
    mov bx,ds:kr_wait
    WaitWithTimeout
;
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_in_pipe
    GetUsedUsbBuffers
    or cx,cx
    jz raOk
;
    movzx ecx,ds:kr_max_in
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
    mov es,ds:kr_out_buffer
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
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
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
    mov es,ds:kr_out_buffer
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
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
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
;       NAME:           GetWordParam
;
;       DESCRIPTION:    Get a word parameter
;
;       PARAMETERS:     DS      Data
;                       BL      Parameter
;
;       RETURNS:        AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetWordParam   Proc near
    push es
    push ebx
    push ecx
    push edx
    push edi
;
    mov dx,ax
    mov es,ds:kr_out_buffer
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
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
    PostUsbRawPipe
    jc gwpDone
;
    call ReadAnswer
    jc gwpDone
;
    cmp cx,2
    stc
    jne gwpDone
;
    xor di,di
    mov ax,es:[di]
    xchg al,ah
    clc

gwpDone:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
GetWordParam    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetWordParam
;
;       DESCRIPTION:    Set a word parameter
;
;       PARAMETERS:     DS      Data
;                       BL      Parameter
;                       AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetWordParam   Proc near
    push es
    push eax
    push ebx
    push ecx
    push edx
    push edi
;
    mov dx,ax
    mov es,ds:kr_out_buffer
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
    mov ax,dx
    xchg al,ah
    stosw
;
    mov cx,di
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
    PostUsbRawPipe
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
SetWordParam    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckWordParam
;
;       DESCRIPTION:    Check word parameter
;
;       PARAMETERS:     DS      Data
;                       BL      Parameter
;                       AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckWordParam   Proc near
    push dx
;
    mov dx,ax
    call GetWordParam
    jc cwpWrite
;
    cmp ax,dx
    clc
    je cwpDone

cwpWrite:
    mov ax,dx
    call SetWordParam

cwpDone:
    pop dx
    ret
CheckWordParam  Endp

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
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stab:
st00 DW 0
st01 DW STATUS_PAPER_JAM
st02 DW STATUS_CUTTER_JAM
st03 DW STATUS_NO_PAPER
st04 DW STATUS_HEAD_LIFTED
st05 DW STATUS_FEED_ERROR
st06 DW STATUS_TEMP_ERROR
st07 DW 0
st08 DW 0
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
st19 DW STATUS_PAPER_LOW
st20 DW STATUS_PAPER_PRESENTER

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
    xor dx,dx
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
    mov ds:kr_status,dx
    clc
    jmp nsDone

nsReset:
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz nsDone
;    
    mov bx,ds:kr_dev_handle
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
    mov dx,ax
    mov es,ds:kr_out_buffer
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
    mov cx,di
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
    PostUsbRawPipe
    jc usError
;
    call ReadAnswer
    jnc usOk

usError:
    mov ax,ds:kr_status_errors
    inc ds:kr_status_errors
    cmp ax,10
    jb usDone

usResetUsb:
    lock or ds:kr_status,STATUS_OFFLINE
    mov ds:kr_status_errors,0
    mov bx,ds:kr_dev_handle
    ResetUsbDevice
    jmp usDone

usOk:
    mov ds:kr_status_errors,0
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
    mov es,ds:kr_out_buffer
    xor edi,edi
;    
    mov al,ESC
    stosb
;
    mov al,'?'
    stosb
;
    mov cx,di
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
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
    mov es,ds:kr_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;    
    mov al,'p'
    stosb
;
    mov cx,di
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
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
    mov es,ds:kr_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;
    mov al,RS
    stosb
;
    mov cx,di
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
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
    mov es,ds:kr_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;
    mov al,FF
    stosb
;
    mov al,ds:kr_present_mm
    stosb
    clc
;
    mov cx,di
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
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
    mov es,ds:kr_out_buffer
    xor edi,edi
;
    mov al,ENQ
    stosb
;
    mov cx,di
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
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
    mov es,ds:kr_out_buffer
    xor edi,edi
;
    mov al,ESC
    stosb
;    
    mov al,ACK
    stosb
;    
    mov al,0FEh
    stosb
;
    mov cx,di
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
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
    mov es,ds:kr_out_buffer
    mov ds,ax
    xor edi,edi
;
    mov al,ESC
    stosb
;    
    mov al,'S'
    stosb
;    
    mov ax,fs:bs_line_size
    add ax,2
    stosw
;
    mov al,80h
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
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
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
    xchg bx,ds:kr_bitmap
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
    cmp bp,256
    jne sbDo
;
    call SendPrint
;
    mov ax,10
    WaitMilliSec
    xor bp,bp
;
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz sbFree

sbDo:
    call SendLine
    inc dx
;
    test dl,0Fh
    jnz sbNext
;
    call SendPrint

sbNext:
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
    mov bx,ds:kr_pr_thread
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
    test ds:kr_cmd,CMD_PRESENT
    jz scNotPresent
;
    lock and ds:kr_cmd,NOT CMD_PRESENT
    call SendPresent

scNotPresent:
    test ds:kr_cmd,CMD_EJECT
    jz scNotEject
;
    lock and ds:kr_cmd,NOT CMD_EJECT
    call SendEject

scNotEject:
    test ds:kr_cmd,CMD_FORCE
    jz scNotForce
;
    lock and ds:kr_cmd,NOT CMD_FORCE
    call SendForce

scNotForce:
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
    mov ds:kr_in_buffer,es
    pop es
;
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_in_pipe
    mov cx,10
    OpenUsbPacketPipe
;
    push es
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
    mov cx,MAX_OUT_SIZE
    mov ax,25
    OpenUsbRawPipe
    mov ds:kr_out_buffer,es
    pop es
;
    CreateWait
    mov ds:kr_wait,bx
;
    mov ax,ds:kr_dev_handle
    mov dl,ds:kr_in_pipe
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
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_in_pipe
    CloseUsbPipe
;
    mov bx,ds:kr_dev_handle
    mov dl,ds:kr_out_pipe
    CloseUsbPipe
;
    mov bx,ds:kr_wait
    CloseWait
;
    mov ds:kr_out_buffer,0
;
    lock or ds:kr_flag,FLAG_CLOSED
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

my_name DB 'KR203', 0

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
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz ijDone
;    
    mov ax,ds:kr_server_thread
    or ax,ax
    clc
    jz ijDone
;
    mov ax,ds:kr_status
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
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz iplDone
;
    mov ax,ds:kr_server_thread
    or ax,ax
    clc
    jz iplDone
;
    mov ax,ds:kr_status
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
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz ipeDone
;    
    mov ax,ds:kr_server_thread
    or ax,ax
    clc
    jz ipeDone
;
    mov ax,ds:kr_status
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
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz icjDone
;
    mov ax,ds:kr_server_thread
    or ax,ax
    clc
    jz icjDone
;
    mov ax,ds:kr_status
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
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz ioDone
;
    mov ax,ds:kr_server_thread
    or ax,ax
    stc
    jz ioDone
;
    mov ax,ds:kr_status
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
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz ihlDone
;    
    mov ax,ds:kr_server_thread
    or ax,ax
    clc
    jz ihlDone
;
    mov ax,ds:kr_status
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
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz hppDone
;
    mov ax,ds:kr_server_thread
    or ax,ax
    clc
    jz hppDone
;
    mov ax,ds:kr_status
    test ax,STATUS_PAPER_PRESENTER
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
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz hteDone
;
    mov ax,ds:kr_server_thread
    or ax,ax
    clc
    jz hteDone
;
    mov ax,ds:kr_status
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
    test ds:kr_flag,FLAG_ATTACHED
    clc
    jz hfeDone
;
    mov ax,ds:kr_server_thread
    or ax,ax
    clc
    jz hfeDone
;
    mov ax,ds:kr_status
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
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:kr_width
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
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz pbDone
;
    mov ax,ds:kr_server_thread
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
    mov ds:kr_pr_thread,ax
    mov ds:kr_bitmap,bx
;
    mov bx,ds:kr_wait_thread
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
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz pmDone
;
    mov ds:kr_present_mm,al
    lock or ds:kr_cmd,CMD_PRESENT
    mov bx,ds:kr_wait_thread
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
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz emDone
;
    lock or ds:kr_cmd,CMD_EJECT
    mov bx,ds:kr_wait_thread
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
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz fpDone
;
    lock or ds:kr_cmd,CMD_FORCE
    mov bx,ds:kr_wait_thread
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
    test ds:kr_flag,FLAG_ATTACHED
    stc
    jz reset_done
;    
    mov bx,ds:kr_dev_handle
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
;               NAME:           Kr203Thread
;
;               DESCRIPTION:    Printer handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kr203_thread_name  DB 'KR203 ', 0

kr203_thread:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:kr_server_thread,ax
    mov ds:kr_pr_thread,0
    mov ds:kr_bitmap,0
    mov ds:kr_wait_thread,0
    mov ds:kr_reset_counter,0
    mov ds:kr_status_errors,0
;
    mov eax,SIZE usb_printer_struc
    AllocateSmallGlobalMem
    mov es:printer_device,0
;    
    mov ax,ds:kr_controller
    movzx dx,ds:kr_port
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

krRestart:
    mov bx,ds:kr_controller
    mov al,ds:kr_port
    OpenUsbDevice
    mov ds:kr_dev_handle,bx
;
    call OpenPipes
;    
    lock or ds:kr_status,STATUS_OFFLINE
;
    mov cx,10

krInitLoop:
    mov bx,ds:kr_dev_handle
    IsUsbDeviceConnected
    jc krDetached
;
    test ds:kr_flag,FLAG_ATTACHED
    jz krDetached
;
    mov bl,66
    xor al,al
    call SetByteParam
    jc krRetry
;    
    mov bl,65
    xor al,al
    call SetByteParam
    jc krRetry
;
    mov bl,6
    mov ax,250
    call CheckWordParam
    jc krRetry
;    
    mov bl,7
    mov ax,1000
    call CheckWordParam
    jc krRetry
;    
    mov bl,8
    mov al,75
    call CheckByteParam
    jc krRetry
;
    mov bl,69
    call GetByteParam
    jc krRetry
;
    mov cl,8
    mul cl
    mov ds:kr_width,ax
    jmp krLoop

krRetry:
    loop krInitLoop
;
    mov ax,ds:kr_reset_counter
    cmp ax,10
    jb krResetUsb
;
    mov ax,1000
    WaitMilliSec
;
    mov ax,ds:kr_reset_counter
    cmp ax,20
    jb krResetPrinter
;
    HasHardReset
    jc krDetached
;
    HardReset
    jmp krDetached

krResetPrinter:
    inc ds:kr_reset_counter
;
    call DoHardReset
    jmp krDetached

krResetUsb:
    inc ds:kr_reset_counter
;
    mov bx,ds:kr_dev_handle
    ResetUsbDevice
    jmp krDetached

krLoop:
    mov ds:kr_reset_counter,0
;
    mov bx,ds:kr_dev_handle
    IsUsbDeviceConnected
    jc krDetached
;
    test ds:kr_flag,FLAG_ATTACHED
    jz krDetached
;
    call UpdateStatus
;
    test ds:kr_status,STATUS_CUTTER_JAM
    jz krClearCutter
;
    test ds:kr_status,STATUS_HEAD_LIFTED
    jnz krSetLifted
;
    test ds:kr_flag,FLAG_WAS_LIFTED
    jz krClearDone
;
    mov ax,1000
    WaitMilliSec
;    
    call DoHardReset
    jmp krClearCutter

krSetLifted:
    lock or ds:kr_flag,FLAG_WAS_LIFTED
    jmp krClearDone

krClearCutter:
    lock and ds:kr_flag,NOT FLAG_WAS_LIFTED

krClearDone:    
    call SendBitmap
    call SendCommand
;
    GetThread
    mov ds:kr_wait_thread,ax
;
    GetSystemTime
    add eax,1500 * 1193
    adc edx,0
    WaitForSignalWithTimeout
;
    mov ds:kr_wait_thread,0
    jmp krLoop
        
krDetached:
    mov ax,5
    WaitMilliSec
;
    call ClosePipes
;
    xor bx,bx
    xchg bx,ds:kr_dev_handle
    CloseUsbDevice
;
    test ds:kr_flag,FLAG_ATTACHED
    jz krWaitAttach
;
    mov ecx,100

krWaitDetach:
    mov ax,25
    WaitMilliSec
;
    test ds:kr_flag,FLAG_ATTACHED
    jz krWaitAttach
;
    loop krWaitDetach

krWaitAttach:
    test ds:kr_flag,FLAG_ATTACHED
    jnz krRestart
;
    GetSystemTime
    add eax,250 * 1193
    adc edx,0
    WaitForSignalWithTimeout
    jmp krWaitAttach
       
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
    mov ax,ds:kr_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,ds:kr_port
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
    mov ds:kr_controller,bx
    mov ds:kr_port,al
    mov ds:kr_out_pipe,0
    mov ds:kr_in_pipe,0
    mov ds:kr_max_in,0
;
    lock or ds:kr_flag,FLAG_ATTACHED
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
    mov ds:kr_out_pipe,cl
    jmp opDescrNext

opBulkIn:
    and cl,8Fh
    mov ds:kr_in_pipe,cl
    mov ax,es:[di].ued_maxsize
    mov ds:kr_max_in,ax
    
opDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb opDescrLoop    
        
opDescrDone:
    mov al,ds:kr_in_pipe
    or al,al
    jz opDone
;    
    mov al,ds:kr_out_pipe
    or al,al
    jz opDone
;    
    test ds:kr_flag,FLAG_STARTED
    jnz opDone
;
    lock or ds:kr_flag,FLAG_STARTED    
;
    mov esi,OFFSET kr203_thread
    mov edi,OFFSET kr203_thread_name
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
a00     DW 0A5Fh,       00B3h   ; KR203, app mode

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
    test ds:kr_flag,FLAG_ATTACHED
    jz udDone
;    
    cmp al,byte ptr ds:kr_port
    jne udDone
;
    cmp bx,ds:kr_controller
    jne udDone
;
    mov ax,5
    WaitMilliSec
;        
    mov cx,100
    lock and ds:kr_flag,NOT FLAG_ATTACHED

udWaitLoop:    
    mov bx,ds:kr_server_thread
    Signal
;
    mov ax,5
    WaitMilliSec
;
    test ds:kr_flag,FLAG_CLOSED
    jnz udWaitDone
;
    loop udWaitLoop    

udWaitDone:
    lock and ds:kr_flag,NOT FLAG_CLOSED
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
    InitSection ds:kr_section
    mov ds:kr_flag,0
    mov ds:kr_cmd,0
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
