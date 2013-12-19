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

hid_left_index      DW ?
hid_mid_index       DW ?
hid_right_index     DW ?

hid_x_index         DW ?
hid_y_index         DW ?
hid_scroll_index    DW ?

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
;   RETURNS:        BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_begin   Proc far
    push es
    push eax
;    
    mov eax,SIZE hid_mouse
    AllocateSmallGlobalMem
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
;                   CL      Usage ID
;                   CH      Usage page
;                   EDX     Item params
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_define   Proc far
    push ds
    mov ds,ebx
;
    cmp cx,901h
    jne hdNotLeft
;
    mov ds:hid_left_index,si

hdNotLeft:
    cmp cx,902h
    jne hdNotRight
;
    mov ds:hid_right_index,si

hdNotRight:                
    cmp cx,903h
    jne hdNotMid
;
    mov ds:hid_mid_index,si

hdNotMid: 
    cmp cx,130h
    jne hdNotX
;
    test dx,4
    jz hdNotX
;
    mov ds:hid_x_index,si

hdNotX:                   
    cmp cx,131h
    jne hdNotY
;
    test dx,4
    jz hdNotY
;    
    mov ds:hid_y_index,si

hdNotY:                   
    cmp cx,138h
    jne hdNotScroll
;
    mov ds:hid_scroll_index,si

hdNotScroll:                   
    pop ds
    ret
hid_define   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_set_logical
;
;   DESCRIPTION:    Set logical properties
;
;   PARAMETERS:     BX      Handle
;                   SI      Entry #
;                   EAX     Logical min
;                   EDX     Logical max
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_set_logical   Proc far
    int 3
    ret
hid_set_logical   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_set_physical
;
;   DESCRIPTION:    Set physical properties
;
;   PARAMETERS:     BX      Handle
;                   SI      Entry #
;                   EAX     Physical min
;                   EDX     Physical max
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_set_physical   Proc far
    int 3
    ret
hid_set_physical   Endp

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
;   NAME:           hid_begin_report
;
;   DESCRIPTION:    Begin report
;
;   PARAMETERS:     BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_begin_report   Proc far
    int 3
    ret
hid_begin_report   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_add_report
;
;   DESCRIPTION:    Add report item
;
;   PARAMETERS:     BX      Handle
;                   SI      Entry #
;                   EAX     Value
;                   CL      Usage ID
;                   CH      Usage page
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_add_report   Proc far
    int 3
    ret
hid_add_report   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_end_report
;
;   DESCRIPTION:    End report
;
;   PARAMETERS:     BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_end_report   Proc far
    int 3
    ret
hid_end_report   Endp

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
h02 DD OFFSET hid_set_logical,  SEG code
h03 DD OFFSET hid_set_physical, SEG code
h04 DD OFFSET hid_end,          SEG code
h05 DD OFFSET hid_close,        SEG code
h06 DD OFFSET hid_begin_report, SEG code
h07 DD OFFSET hid_add_report,   SEG code
h08 DD OFFSET hid_end_report,   SEG code

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
