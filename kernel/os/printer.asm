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

    .386p

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
    clc
    pop ds
    ret
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
    mov [ebx].printer_sel,es
    mov [ebx].hh_sign,PRINTER_HANDLE
    mov bx,[ebx].hh_handle
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
    ret
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
    ret
close_printer       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetPrinterName
;
;       description:    Get printer name
;
;       PARAMETERS:     BX              Printer handle
;                       ES:(E)DI        Printer name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_printer_name_name DB 'Get Printer Name',0

get_printer_name16       Proc far
    push ds
    push eax
    push ebx
    push edi
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc get_printer_name_done16
;
    movzx edi,di
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_get_name_proc
    or eax,ds:pr_get_name_proc+4
    clc
    jz get_printer_name_done16
;       
    call fword ptr ds:pr_get_name_proc

get_printer_name_done16:
    pop edi
    pop ebx
    pop eax
    pop ds
    ret
get_printer_name16       Endp

get_printer_name32       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc get_printer_name_done32
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_get_name_proc
    or eax,ds:pr_get_name_proc+4
    clc
    jz get_printer_name_done32
;       
    call fword ptr ds:pr_get_name_proc

get_printer_name_done32:
    pop ebx
    pop eax
    pop ds
    ret
get_printer_name32       Endp

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
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc is_printer_jammed_done
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_jammed_proc
    or eax,ds:pr_jammed_proc+4
    clc
    jz is_printer_jammed_done
;       
    call fword ptr ds:pr_jammed_proc

is_printer_jammed_done:
    pop ebx
    pop eax
    pop ds
    ret
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
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc is_printer_paper_low_done
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_paper_low_proc
    or eax,ds:pr_paper_low_proc+4
    clc
    jz is_printer_paper_low_done
;       
    call fword ptr ds:pr_paper_low_proc

is_printer_paper_low_done:
    pop ebx
    pop eax
    pop ds
    ret
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
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc is_printer_paper_end_done
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_paper_end_proc
    or eax,ds:pr_paper_end_proc+4
    clc
    jz is_printer_paper_end_done
;       
    call fword ptr ds:pr_paper_end_proc

is_printer_paper_end_done:
    pop ebx
    pop eax
    pop ds
    ret
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
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc is_printer_ok_done
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_ok_proc
    or eax,ds:pr_ok_proc+4
    stc
    jz is_printer_ok_done
;       
    call fword ptr ds:pr_ok_proc

is_printer_ok_done:
    pop ebx
    pop eax
    pop ds
    ret
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
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc is_printer_head_lifted_done
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_head_lifted_proc
    or eax,ds:pr_head_lifted_proc+4
    clc
    jz is_printer_head_lifted_done
;       
    call fword ptr ds:pr_head_lifted_proc

is_printer_head_lifted_done:
    pop ebx
    pop eax
    pop ds
    ret
is_printer_head_lifted       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsPrinterCutterJammed
;
;       description:    Is printer cutter jammed
;
;       PARAMETERS:     BX              Printer handle
;
;       RETURNS:        CY              Cutter jammed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_printer_cutter_jammed_name DB 'Is Printer Cutter Jammed?',0

is_printer_cutter_jammed       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc is_printer_cutter_jammed_done
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_cutter_jammed_proc
    or eax,ds:pr_cutter_jammed_proc+4
    clc
    jz is_printer_cutter_jammed_done
;       
    call fword ptr ds:pr_cutter_jammed_proc

is_printer_cutter_jammed_done:
    pop ebx
    pop eax
    pop ds
    ret
is_printer_cutter_jammed       Endp

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
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc has_printer_paper_in_presenter_done
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_paper_in_presenter_proc
    or eax,ds:pr_paper_in_presenter_proc+4
    clc
    jz has_printer_paper_in_presenter_done
;       
    call fword ptr ds:pr_paper_in_presenter_proc

has_printer_paper_in_presenter_done:
    pop ebx
    pop eax
    pop ds
    ret
has_printer_paper_in_presenter       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasPrinterTempError
;
;       description:    Has printer temperature error
;
;       PARAMETERS:     BX              Printer handle
;
;       RETURNS:        CY              Temp error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_printer_temp_error_name DB 'Has Printer Temperature Error?',0

has_printer_temp_error       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc has_printer_temp_error_done
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_temp_error_proc
    or eax,ds:pr_temp_error_proc+4
    clc
    jz has_printer_temp_error_done
;       
    call fword ptr ds:pr_temp_error_proc

has_printer_temp_error_done:
    pop ebx
    pop eax
    pop ds
    ret
has_printer_temp_error       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HasPrinterFeedError
;
;       description:    Has printer feed error
;
;       PARAMETERS:     BX              Printer handle
;
;       RETURNS:        CY              Feed error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_printer_feed_error_name DB 'Has Printer Feed Error?',0

has_printer_feed_error       Proc far
    push ds
    push eax
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc has_printer_feed_error_done
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_feed_error_proc
    or eax,ds:pr_feed_error_proc+4
    clc
    jz has_printer_feed_error_done
;       
    call fword ptr ds:pr_feed_error_proc

has_printer_feed_error_done:
    pop ebx
    pop eax
    pop ds
    ret
has_printer_feed_error       Endp

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
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc print_test_done
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_print_test_proc
    or eax,ds:pr_print_test_proc+4
    jz print_test_done
;       
    call fword ptr ds:pr_print_test_proc

print_test_done:
    pop ebx
    pop eax
    pop ds
    ret
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
    push ebx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc create_bitmap_done
;
    mov ds,[ebx].printer_sel
    mov eax,ds:pr_create_bitmap_proc
    or eax,ds:pr_create_bitmap_proc+4
    stc
    jz create_bitmap_done
;       
    call fword ptr ds:pr_create_bitmap_proc
    mov ax,bx

create_bitmap_done:
    pop ebx
    pop ds
    ret
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
    push ebx
;
    push ax
    mov ax,PRINTER_HANDLE
    DerefHandle
    pop ax
    jc print_bitmap_done
;
    mov ds,[ebx].printer_sel
    mov bx,ax
    mov eax,ds:pr_print_bitmap_proc
    or eax,ds:pr_print_bitmap_proc+4
    jz print_bitmap_done
;       
    call fword ptr ds:pr_print_bitmap_proc

print_bitmap_done:
    pop ebx
    pop eax
    pop ds
    ret
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
    mov ds,[ebx].printer_sel
    mov ebx,ds:pr_present_media_proc
    or ebx,ds:pr_present_media_proc+4
    jz present_media_done
;       
    call fword ptr ds:pr_present_media_proc

present_media_done:
    pop ebx
    pop ax
    pop ds
    ret
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
    mov ds,[ebx].printer_sel
    mov ebx,ds:pr_eject_media_proc
    or ebx,ds:pr_eject_media_proc+4
    jz eject_media_done
;       
    call fword ptr ds:pr_eject_media_proc

eject_media_done:
    pop ebx
    pop ax
    pop ds
    ret
eject_media      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Reset
;
;       description:    Reset printer
;
;       PARAMETERS:     BX              Printer handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_printer_name DB 'Reset Printer',0

reset_printer       Proc far
    push ds
    push ax
    push ebx
;
    push ax
    mov ax,PRINTER_HANDLE
    DerefHandle
    pop ax
    jc reset_done
;
    mov ds,[ebx].printer_sel
    mov ebx,ds:pr_reset_proc
    or ebx,ds:pr_reset_proc+4
    jz reset_done
;       
    call fword ptr ds:pr_reset_proc

reset_done:
    pop ebx
    pop ax
    pop ds
    ret
reset_printer      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitForPrint
;
;       description:    Wait for printout to finish
;
;       PARAMETERS:     BX              Printer handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_print_name DB 'WaitForPrint',0

wait_for_print       Proc far
    push ds
    push ax
    push ebx
;
    push ax
    mov ax,PRINTER_HANDLE
    DerefHandle
    pop ax
    jc wait_for_print_done
;
    mov ds,[ebx].printer_sel
    mov ebx,ds:pr_wait_for_print_proc
    or ebx,ds:pr_wait_for_print_proc+4
    jz wait_for_print_done
;       
    call fword ptr ds:pr_wait_for_print_proc

wait_for_print_done:
    pop ebx
    pop ax
    pop ds
    ret
wait_for_print      Endp
    
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
    mov ds:pr_jammed_proc+4,0

    mov ds:pr_paper_low_proc,0
    mov ds:pr_paper_low_proc+4,0

    mov ds:pr_paper_end_proc,0
    mov ds:pr_paper_end_proc+4,0
;
    mov ds:pr_cutter_jammed_proc,0
    mov ds:pr_cutter_jammed_proc+4,0
;
    mov ds:pr_ok_proc,0
    mov ds:pr_ok_proc+4,0
;
    mov ds:pr_head_lifted_proc,0
    mov ds:pr_head_lifted_proc+4,0
;
    mov ds:pr_paper_in_presenter_proc,0
    mov ds:pr_paper_in_presenter_proc+4,0
;
    mov ds:pr_temp_error_proc,0
    mov ds:pr_temp_error_proc+4,0
;
    mov ds:pr_feed_error_proc,0
    mov ds:pr_feed_error_proc+4,0
;
    mov ds:pr_print_test_proc,0
    mov ds:pr_print_test_proc+4,0
;
    mov ds:pr_create_bitmap_proc,0
    mov ds:pr_create_bitmap_proc+4,0
;
    mov ds:pr_print_bitmap_proc,0
    mov ds:pr_print_bitmap_proc+4,0
;
    mov ds:pr_present_media_proc,0
    mov ds:pr_present_media_proc+4,0
;
    mov ds:pr_eject_media_proc,0
    mov ds:pr_eject_media_proc+4,0
;
    mov ds:pr_wait_for_print_proc,0
    mov ds:pr_wait_for_print_proc+4,0
;
    mov ds:pr_get_name_proc,0
    mov ds:pr_get_name_proc+4,0
;
    mov ds:pr_reset_proc,0
    mov ds:pr_reset_proc+4,0
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
    mov edi,OFFSET delete_handle
    mov ax,PRINTER_HANDLE
    RegisterHandle
;
    mov esi,OFFSET add_printer
    mov edi,OFFSET add_printer_name
    xor cl,cl
    mov ax,add_printer_nr
    RegisterOsGate
;
    mov esi,OFFSET get_max_printer
    mov edi,OFFSET get_max_printer_name
    xor dx,dx
    mov ax,get_max_printer_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_printer
    mov edi,OFFSET open_printer_name
    xor dx,dx
    mov ax,open_printer_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_printer
    mov edi,OFFSET close_printer_name
    xor dx,dx
    mov ax,close_printer_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_printer_jammed
    mov edi,OFFSET is_printer_jammed_name
    xor dx,dx
    mov ax,is_printer_jammed_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_printer_paper_low
    mov edi,OFFSET is_printer_paper_low_name
    xor dx,dx
    mov ax,is_printer_paper_low_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_printer_paper_end
    mov edi,OFFSET is_printer_paper_end_name
    xor dx,dx
    mov ax,is_printer_paper_end_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_printer_ok
    mov edi,OFFSET is_printer_ok_name
    xor dx,dx
    mov ax,is_printer_ok_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_printer_head_lifted
    mov edi,OFFSET is_printer_head_lifted_name
    xor dx,dx
    mov ax,is_printer_head_lifted_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_printer_cutter_jammed
    mov edi,OFFSET is_printer_cutter_jammed_name
    xor dx,dx
    mov ax,is_printer_cutter_jammed_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET has_printer_paper_in_presenter
    mov edi,OFFSET has_printer_paper_in_presenter_name
    xor dx,dx
    mov ax,has_printer_paper_in_presenter_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET has_printer_temp_error
    mov edi,OFFSET has_printer_temp_error_name
    xor dx,dx
    mov ax,has_printer_temp_error_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET has_printer_feed_error
    mov edi,OFFSET has_printer_feed_error_name
    xor dx,dx
    mov ax,has_printer_feed_error_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET reset_printer
    mov edi,OFFSET reset_printer_name
    xor dx,dx
    mov ax,reset_printer_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET print_test
    mov edi,OFFSET print_test_name
    xor dx,dx
    mov ax,print_test_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_bitmap
    mov edi,OFFSET create_bitmap_name
    xor dx,dx
    mov ax,create_printer_bitmap_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET print_bitmap
    mov edi,OFFSET print_bitmap_name
    xor dx,dx
    mov ax,print_bitmap_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET present_media
    mov edi,OFFSET present_media_name
    xor dx,dx
    mov ax,present_printer_media_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET eject_media
    mov edi,OFFSET eject_media_name
    xor dx,dx
    mov ax,eject_printer_media_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_for_print
    mov edi,OFFSET wait_for_print_name
    xor dx,dx
    mov ax,wait_for_print_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_printer_name16
    mov esi,OFFSET get_printer_name32
    mov edi,OFFSET get_printer_name_name
    mov dx,virt_es_in
    mov ax,get_printer_name_nr
    RegisterUserGate
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
