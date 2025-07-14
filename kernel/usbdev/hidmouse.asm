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
; HIDMOUSE.ASM
; Implements HID mouse class
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

hid_mouse   STRUC

hid_report_offset   DD ?
hid_report_sel      DW ?

hid_left_index      DW ?
hid_mid_index       DW ?
hid_right_index     DW ?

hid_x_index         DW ?
hid_y_index         DW ?
hid_scroll_index    DW ?

hid_buttons         DW ?
hid_delta_x         DW ?
hid_delta_y         DW ?

hid_mouse   ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_begin
;
;   DESCRIPTION:    Begin initialization
;
;   Parameters:     FS:ESI    Report struct
;
;   RETURNS:        BX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_begin   Proc far
    push es
    push eax
;    
    mov eax,SIZE hid_mouse
    AllocateSmallGlobalMem
;
    mov es:hid_report_offset,esi
    mov es:hid_report_sel,fs    
;
    mov es:hid_left_index,-1
    mov es:hid_mid_index,-1
    mov es:hid_right_index,-1
;    
    mov es:hid_x_index,-1
    mov es:hid_y_index,-1
    mov es:hid_scroll_index,-1
    mov ebx,es
;
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
    mov ds,ebx
;
    cmp cl,9
    jne hdNotButton
;
    cmp al,1
    jne hdNotLeft
;
    mov ds:hid_left_index,si

hdNotLeft:
    cmp al,2
    jne hdNotRight
;
    mov ds:hid_right_index,si

hdNotRight:                
    cmp al,3
    jne hdDone
;
    mov ds:hid_mid_index,si
    jmp hdDone

hdNotButton:
    cmp cl,1 
    jne hdDone
;
    cmp al,30h
    jne hdNotX
;
    test dx,4
    jz hdNotX
;
    mov ds:hid_x_index,si

hdNotX:                   
    cmp al,31h
    jne hdNotY
;
    test dx,4
    jz hdNotY
;    
    mov ds:hid_y_index,si

hdNotY:                   
    cmp al,38h
    jne hdDone
;
    mov ds:hid_scroll_index,si

hdDone:                   
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
    push es
    push eax
;
    mov es,ebx
    mov ax,es:hid_left_index
    add ax,1
    jc heFail
;
    mov ax,es:hid_right_index
    add ax,1
    jc heFail
;
    mov ax,es:hid_x_index
    add ax,1
    jc heFail
;
    mov ax,es:hid_y_index
    add ax,1
    jc heFail
;
    clc
    jmp heDone                

heFail:
    FreeMem
    stc
        
heDone:
    pop eax    
    pop es
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
    mov es,ebx
    FreeMem
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
    push ds
    push es
    push fs
    pushad
;    
    mov ds,ebx
    mov edi,ds:hid_report_offset
    mov es,ds:hid_report_sel
    movzx ebx,ds:hid_x_index
    GetSignedHidInput
    mov ds:hid_delta_x,ax
;
    mov edi,ds:hid_report_offset
    mov es,ds:hid_report_sel
    movzx ebx,ds:hid_y_index
    GetSignedHidInput
    mov ds:hid_delta_y,ax
;
    mov ds:hid_buttons,0    
;
    mov edi,ds:hid_report_offset
    mov es,ds:hid_report_sel
    movzx ebx,ds:hid_left_index
    GetUnsignedHidInput
    or ds:hid_buttons,ax
;
    mov edi,ds:hid_report_offset
    mov es,ds:hid_report_sel
    movzx ebx,ds:hid_right_index
    GetUnsignedHidInput
    shl ax,1
    or ds:hid_buttons,ax
;   
    mov ax,ds:hid_buttons
    mov cx,ds:hid_delta_x
    mov dx,ds:hid_delta_y
    neg dx
    UpdateMouse
;
    popad
    pop fs
    pop es
    pop ds
    ret
hid_handle_report   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitMouse
;
;           DESCRIPTION:    Init mouse
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_tab:
h00 DD OFFSET hid_begin,        SEG code
h01 DD OFFSET hid_define,       SEG code
h02 DD OFFSET hid_end,          SEG code
h03 DD OFFSET hid_close,        SEG code
h04 DD OFFSET hid_handle_report,SEG code

    public InitMouse_
    
InitMouse_   Proc near
    push es
    push eax
    push edi
;
    mov eax,cs
    mov es,eax
    mov edi,OFFSET hid_tab
    RegisterHidInput
;
    pop edi
    pop eax
    pop es    
    ret
InitMouse_   Endp
        

code    ENDS

    END
