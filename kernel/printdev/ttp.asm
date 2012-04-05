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
; TTP.ASM
; Swecoin / Zebra TTP10xxx and TTP20xx printer driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\os\printer.inc
INCLUDE ..\os\protseg.def

ENQ = 5
ESC = 1Bh
RS = 1Eh
FF = 0Ch
ACK = 06h
NAK = 15h

ttp_printer_struc       STRUC

ttp_base_struc  printer_struc <>

ttp_wait        DW ?
ttp_handle      DW ?
ttp_port        DB ?

ttp_printer_struc       ENDS

data    SEGMENT byte public 'DATA'

ttp_section          section_typ <>

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

        assume cs:code

        .386p


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:                   ClearPort
;
;       DESCRIPTION:    Clear comport before sending command
;
;       PARAMETERS:     
;
;       RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearPort Proc near
    push eax
    push bx
    push cx
    push edx
;    
    mov cx,256

cpLoop:
    push cx
    GetSystemTime
    add eax,100 * 1192
    adc edx,0
    mov bx,ds:ttp_wait
    WaitWithTimeout
    pop cx
;
    mov bx,ds:ttp_handle
    ReadCom
    jc cpOk
;    
    loop cpLoop
;
    stc
    jmp cpDone

cpOk:
    clc

cpDone:
    pop edx
    pop cx
    pop bx
    pop eax   
    ret
ClearPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetChar
;
;       DESCRIPTION:    Get a single response char
;
;       PARAMETERS:     AX      Timeout, ms
;
;       RETURNS:        NC      OK
;                           AL  Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetChar Proc near
    push bx
    push ecx
    push edx
;
    mov dx,1192
    mul dx
    movzx ecx,ax
;    
    GetSystemTime
    add eax,ecx
    adc edx,0
    mov bx,ds:ttp_wait
    WaitWithTimeout
;
    mov bx,ds:ttp_handle
    ReadCom
;
    pop edx
    pop ecx
    pop bx
    ret
GetChar Endp

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

my_name DB 'TTP', 0

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
    stc
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
;       NAME:           print_test
;
;       DESCRIPTION:    Print test page
;
;       PARAMETERS:     DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_test   Proc far
    stc
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
    stc
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
    stc
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
    clc
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
    clc
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
    clc
    ret
wait_for_print    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreatePrinter
;
;   DESCRIPTION:    Create printer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePrinter   Proc near
    xor ax,ax
    xor dx,dx    
    AddPrinter
;
    mov word ptr ds:pr_get_name_proc,OFFSET get_printer_name
    mov word ptr ds:pr_get_name_proc+2,cs
;
    mov word ptr ds:pr_jammed_proc,OFFSET is_jammed
    mov word ptr ds:pr_jammed_proc+2,cs
;    
    mov word ptr ds:pr_paper_low_proc,OFFSET is_paper_low
    mov word ptr ds:pr_paper_low_proc+2,cs
;    
    mov word ptr ds:pr_paper_end_proc,OFFSET is_paper_end
    mov word ptr ds:pr_paper_end_proc+2,cs
;    
    mov word ptr ds:pr_ok_proc,OFFSET is_ok
    mov word ptr ds:pr_ok_proc+2,cs
;    
    mov word ptr ds:pr_head_lifted_proc,OFFSET is_head_lifted
    mov word ptr ds:pr_head_lifted_proc+2,cs
;    
    mov word ptr ds:pr_paper_in_presenter_proc,OFFSET has_paper_in_presenter
    mov word ptr ds:pr_paper_in_presenter_proc+2,cs
;    
    mov word ptr ds:pr_print_test_proc,OFFSET print_test
    mov word ptr ds:pr_print_test_proc+2,cs
;    
    mov word ptr ds:pr_create_bitmap_proc,OFFSET create_bitmap
    mov word ptr ds:pr_create_bitmap_proc+2,cs
;    
    mov word ptr ds:pr_print_bitmap_proc,OFFSET print_bitmap
    mov word ptr ds:pr_print_bitmap_proc+2,cs
;    
    mov word ptr ds:pr_present_media_proc,OFFSET present_media
    mov word ptr ds:pr_present_media_proc+2,cs
;    
    mov word ptr ds:pr_eject_media_proc,OFFSET eject_media
    mov word ptr ds:pr_eject_media_proc+2,cs
;    
    mov word ptr ds:pr_wait_for_print_proc,OFFSET wait_for_print
    mov word ptr ds:pr_wait_for_print_proc+2,cs
    ret
CreatePrinter   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           ttp_thread
;
;   DESCRIPTION:    TTP thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ttp_thread  Proc far
    mov eax,SIZE ttp_printer_struc
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    mov ds:ttp_port,bl
;
    mov cx,6

ttp_loop:
    push cx
;
    mov ax,1000
    WaitMilliSec
;
    CreateWait
    mov ds:ttp_wait,bx
    mov ds:ttp_handle,0
;    
    mov al,ds:ttp_port
    mov ah,8
    mov bl,1
    mov bh,'N'
    mov ecx,9600
    mov si,256
    mov di,256
    OpenCom
    jc ttp_next
;    
    mov ds:ttp_handle,bx
    call ClearPort
    jc ttp_next
;
    mov ax,ds:ttp_handle
    mov bx,ds:ttp_wait
    xor ecx,ecx
    AddWaitForCom
;
    mov bx,ds:ttp_handle
    mov al,ESC
    WriteCom
;
    mov al,ENQ
    WriteCom
;
    mov al,1
    WriteCom
;            
    mov ax,100
    call GetChar
    jc ttp_next
;
    cmp al,ACK
    je ttp_ok
;
    cmp al,NAK
    je ttp_ok

ttp_next:
    mov bx,ds:ttp_handle
    CloseCom
;
    mov bx,ds:ttp_wait
    CloseWait    
;    
    pop cx    
    sub cx,1
    jnz ttp_loop
;
    jmp ttp_exit

ttp_ok:       
    call CreatePrinter
    int 3

ttp_exit:
    xor ax,ax
    mov ds,ax
    FreeMem    
    ret
ttp_thread  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Init_task
;
;   DESCRIPTION:    Create detect-threads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ttp_name1     DB 'TTP COM1',0
ttp_name2     DB 'TTP COM2',0
ttp_name3     DB 'TTP COM3',0
ttp_name4     DB 'TTP COM4',0

init_task      Proc far
    push ds
    push es
;
    mov bx,0
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET ttp_name1
    mov si,OFFSET ttp_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    mov bx,1
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET ttp_name2
    mov si,OFFSET ttp_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    mov bx,2
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET ttp_name3
    mov si,OFFSET ttp_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    mov bx,3
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET ttp_name4
    mov si,OFFSET ttp_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    pop es
    pop ds
    retf32
init_task      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           Init
;
;               description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,SEG data
    mov ds,ax
    InitSection ds:ttp_section
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_task
    HookInitTasking
    clc
    ret
init    Endp

code    ENDS

        END init
