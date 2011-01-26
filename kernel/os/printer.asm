;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
; PRINTER.ASM
; Printer base class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\handle.inc
include ..\wait.inc
include printer.inc

MAX_PORTS = 32

printer_handle_seg  STRUC

printer_handle_base  handle_header <>

printer_sel     DW ?

printer_handle_seg  ENDS

data    SEGMENT byte public 'DATA'

p_port_count    DW ?
p_port_arr      DW MAX_PORTS DUP(?)

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
;       PARAMETERS:     BX              PRINTER HANDLE
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push es
    push ax
    push dx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc delete_handle_done
;
    FreeHandle

delete_handle_done:
    pop dx
    pop ax
    pop es
    pop ds
    ret
delete_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMaxPrinter
;
;       description:    Get max usable printer #
;
;       RETURNS:        AL      Max port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_max_printer_name DB 'Get Max Printers',0

get_max_printer        Proc far
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:p_port_count
    pop ds
    retf32
get_max_printer    Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenPrinter
;
;       description:    Open printer
;
;       PARAMETERS:     AL              Port #
;
;       RETURNS:        BX              Printer handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_printer_name DB 'Open Printer',0

open_printer       Proc far
    push ds
    push es
    push ax
    push cx
    push dx
;
    mov dx,SEG data
    mov ds,dx
    movzx dx,al
    cmp dx,ds:p_port_count
    jae open_printer_fail
;    
    mov bx,dx
    add bx,bx
    mov es,ds:[bx].p_port_arr
;
    mov ax,PRINTER_HANDLE
    mov cx,SIZE printer_handle_seg
    AllocateHandle
    mov [bx].printer_sel,es
    mov [bx].hh_sign,PRINTER_HANDLE
    mov bx,[bx].hh_handle
    clc
    jmp open_printer_done
    
open_printer_fail:
    xor bx,bx
    stc

open_printer_done:
    pop dx
    pop cx
    pop ax
    pop es
    pop ds
    retf32 
open_printer        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClosePrinter
;
;       description:    Close printer
;
;       PARAMETERS:     BX              Printer handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_printer_name DB 'Close Printer',0

close_printer       Proc far
    push ds
    push ax
    push dx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc close_printer_done
;
    FreeHandle

close_printer_done:
    pop dx
    pop ax
    pop ds
    retf32
close_printer       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsPrinterJammed
;
;       description:    Is printer jammed
;
;       PARAMETERS:     BX              Printer handle
;
;       RETURNS:        CY              Jammed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_printer_jammed_name DB 'Is Printer Jammed?',0

is_printer_jammed       Proc far
    push ds
    push eax
    push bx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc is_printer_jammed_done
;
    mov ds,[bx].printer_sel
    mov eax,ds:pr_jammed_proc
    or eax,eax
    clc
    jz is_printer_jammed_done
;       
    call ds:pr_jammed_proc

is_printer_jammed_done:
    pop bx
    pop eax
    pop ds
    retf32
is_printer_jammed       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsPrinterPaperLow
;
;       description:    Is printer paper low
;
;       PARAMETERS:     BX              Printer handle
;
;       RETURNS:        CY              Low
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_printer_paper_low_name DB 'Is Printer Paper Low?',0

is_printer_paper_low       Proc far
    push ds
    push eax
    push bx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc is_printer_paper_low_done
;
    mov ds,[bx].printer_sel
    mov eax,ds:pr_paper_low_proc
    or eax,eax
    clc
    jz is_printer_paper_low_done
;       
    call ds:pr_paper_low_proc

is_printer_paper_low_done:
    pop bx
    pop eax
    pop ds
    retf32
is_printer_paper_low       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsPrinterPaperEnd
;
;       description:    Is printer paper end
;
;       PARAMETERS:     BX              Printer handle
;
;       RETURNS:        CY              End
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_printer_paper_end_name DB 'Is Printer Paper End?',0

is_printer_paper_end       Proc far
    push ds
    push eax
    push bx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc is_printer_paper_end_done
;
    mov ds,[bx].printer_sel
    mov eax,ds:pr_paper_end_proc
    or eax,eax
    clc
    jz is_printer_paper_end_done
;       
    call ds:pr_paper_end_proc

is_printer_paper_end_done:
    pop bx
    pop eax
    pop ds
    retf32
is_printer_paper_end       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsPrinterOk
;
;       description:    Is printer OK
;
;       PARAMETERS:     BX              Printer handle
;
;       RETURNS:        NC              OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_printer_ok_name DB 'Is Printer Ok?',0

is_printer_ok       Proc far
    push ds
    push eax
    push bx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc is_printer_ok_done
;
    mov ds,[bx].printer_sel
    mov eax,ds:pr_ok_proc
    or eax,eax
    stc
    jz is_printer_ok_done
;       
    call ds:pr_ok_proc

is_printer_ok_done:
    pop bx
    pop eax
    pop ds
    retf32
is_printer_ok       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsPrinterHeadLifted
;
;       description:    Is printer head lifted
;
;       PARAMETERS:     BX              Printer handle
;
;       RETURNS:        CY              Lifted
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_printer_head_lifted_name DB 'Is Printer Head Lifted?',0

is_printer_head_lifted       Proc far
    push ds
    push eax
    push bx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc is_printer_head_lifted_done
;
    mov ds,[bx].printer_sel
    mov eax,ds:pr_head_lifted_proc
    or eax,eax
    clc
    jz is_printer_head_lifted_done
;       
    call ds:pr_head_lifted_proc

is_printer_head_lifted_done:
    pop bx
    pop eax
    pop ds
    retf32
is_printer_head_lifted       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasPrinterPaperInPresenter
;
;       description:    Has printer paper in presenter
;
;       PARAMETERS:     BX              Printer handle
;
;       RETURNS:        CY              Paper
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_printer_paper_in_presenter_name DB 'Has Printer Paper In Presenter?',0

has_printer_paper_in_presenter       Proc far
    push ds
    push eax
    push bx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc has_printer_paper_in_presenter_done
;
    mov ds,[bx].printer_sel
    mov eax,ds:pr_paper_in_presenter_proc
    or eax,eax
    clc
    jz has_printer_paper_in_presenter_done
;       
    call ds:pr_paper_in_presenter_proc

has_printer_paper_in_presenter_done:
    pop bx
    pop eax
    pop ds
    retf32
has_printer_paper_in_presenter       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PrintTest
;
;       description:    Print a test page
;
;       PARAMETERS:     BX              Printer handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_test_name DB 'Print Test',0

print_test       Proc far
    push ds
    push eax
    push bx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc print_test_done
;
    mov ds,[bx].printer_sel
    mov eax,ds:pr_print_test_proc
    or eax,eax
    jz print_test_done
;       
    call ds:pr_print_test_proc

print_test_done:
    pop bx
    pop eax
    pop ds
    retf32
print_test       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateBitmap
;
;       description:    Create printer bitmap
;
;       PARAMETERS:     BX              Printer handle
;                       DX              Height
;
;       RETURNS:        AX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_bitmap_name DB 'Create Printer Bitmap',0

create_bitmap       Proc far
    push ds
    push bx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc create_bitmap_done
;
    mov ds,[bx].printer_sel
    mov eax,ds:pr_create_bitmap_proc
    or eax,eax
    stc
    jz create_bitmap_done
;       
    call ds:pr_create_bitmap_proc
    mov ax,bx

create_bitmap_done:
    pop bx
    pop ds
    retf32
create_bitmap      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PrintBitmap
;
;       description:    Print bitmap
;
;       PARAMETERS:     BX              Printer handle
;                       AX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_bitmap_name DB 'Print Bitmap',0

print_bitmap       Proc far
    push ds
    push eax
    push bx
;
    push ax
    mov ax,PRINTER_HANDLE
    DerefHandle
    pop ax
    jc print_bitmap_done
;
    mov ds,[bx].printer_sel
    mov bx,ax
    mov eax,ds:pr_print_bitmap_proc
    or eax,eax
    jz print_bitmap_done
;       
    call ds:pr_print_bitmap_proc

print_bitmap_done:
    pop bx
    pop eax
    pop ds
    retf32
print_bitmap      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PresentMedia
;
;       description:    Present media
;
;       PARAMETERS:     BX              Printer handle
;                       AX              Amount to present in mm
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

present_media_name DB 'Present Media',0

present_media       Proc far
    push ds
    push ax
    push ebx
;
    push ax
    mov ax,PRINTER_HANDLE
    DerefHandle
    pop ax
    jc present_media_done
;
    mov ds,[bx].printer_sel
    mov ebx,ds:pr_present_media_proc
    or ebx,ebx
    jz present_media_done
;       
    call ds:pr_present_media_proc

present_media_done:
    pop ebx
    pop ax
    pop ds
    retf32
present_media      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           EjectMedia
;
;       description:    Eject media
;
;       PARAMETERS:     BX              Printer handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eject_media_name DB 'Eject Media',0

eject_media       Proc far
    push ds
    push ax
    push ebx
;
    push ax
    mov ax,PRINTER_HANDLE
    DerefHandle
    pop ax
    jc eject_media_done
;
    mov ds,[bx].printer_sel
    mov ebx,ds:pr_eject_media_proc
    or ebx,ebx
    jz eject_media_done
;       
    call ds:pr_eject_media_proc

eject_media_done:
    pop ebx
    pop ax
    pop ds
    retf32
eject_media      Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddPrinter
;
;       DESCRIPTION:    Add a printer port
;
;       PARAMETERS:     AX      Controller #
;                       DX      Device #
;                       DS      Printer device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_printer_name       DB 'Add Printer',0

add_printer    Proc far
    push ds
    push bx
    push dx
;
    mov ds:pr_jammed_proc,0
    mov ds:pr_paper_low_proc,0
    mov ds:pr_paper_end_proc,0
    mov ds:pr_ok_proc,0
    mov ds:pr_head_lifted_proc,0
    mov ds:pr_paper_in_presenter_proc,0
    mov ds:pr_print_test_proc,0
    mov ds:pr_create_bitmap_proc,0
    mov ds:pr_print_bitmap_proc,0
    mov ds:pr_present_media_proc,0
    mov ds:pr_eject_media_proc,0
;
    mov dx,ds
    mov bx,SEG data
    mov ds,bx
;
    mov bx,ds:p_port_count
    add bx,bx
    mov ds:[bx].p_port_arr,dx
    inc ds:p_port_count
;
    pop dx
    pop bx
    pop ds    
    ret
add_printer    Endp

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
    mov di,OFFSET delete_handle
    mov ax,PRINTER_HANDLE
    RegisterHandle
;
    mov si,OFFSET add_printer
    mov di,OFFSET add_printer_name
    xor cl,cl
    mov ax,add_printer_nr
    RegisterOsGate
;
    mov si,OFFSET get_max_printer
    mov di,OFFSET get_max_printer_name
    xor dx,dx
    mov ax,get_max_printer_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET open_printer
    mov di,OFFSET open_printer_name
    xor dx,dx
    mov ax,open_printer_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET close_printer
    mov di,OFFSET close_printer_name
    xor dx,dx
    mov ax,close_printer_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET is_printer_jammed
    mov di,OFFSET is_printer_jammed_name
    xor dx,dx
    mov ax,is_printer_jammed_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET is_printer_paper_low
    mov di,OFFSET is_printer_paper_low_name
    xor dx,dx
    mov ax,is_printer_paper_low_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET is_printer_paper_end
    mov di,OFFSET is_printer_paper_end_name
    xor dx,dx
    mov ax,is_printer_paper_end_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET is_printer_ok
    mov di,OFFSET is_printer_ok_name
    xor dx,dx
    mov ax,is_printer_ok_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET is_printer_head_lifted
    mov di,OFFSET is_printer_head_lifted_name
    xor dx,dx
    mov ax,is_printer_head_lifted_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET has_printer_paper_in_presenter
    mov di,OFFSET has_printer_paper_in_presenter_name
    xor dx,dx
    mov ax,has_printer_paper_in_presenter_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET print_test
    mov di,OFFSET print_test_name
    xor dx,dx
    mov ax,print_test_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET create_bitmap
    mov di,OFFSET create_bitmap_name
    xor dx,dx
    mov ax,create_printer_bitmap_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET print_bitmap
    mov di,OFFSET print_bitmap_name
    xor dx,dx
    mov ax,print_bitmap_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET present_media
    mov di,OFFSET present_media_name
    xor dx,dx
    mov ax,present_printer_media_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET eject_media
    mov di,OFFSET eject_media_name
    xor dx,dx
    mov ax,eject_printer_media_nr
    RegisterBimodalUserGate
;
    mov bx,SEG data
    mov es,bx
    mov cx,2 + 2 * MAX_PORTS
    xor di,di
    xor al,al
    rep stosb
    clc
    ret
init    Endp


code    ENDS

    END init
