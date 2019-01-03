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

hid_card   STRUC

hid_report_offset   DD ?
hid_report_sel      DW ?

hid_card   ENDS

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
    mov eax,SIZE hid_card
    AllocateSmallGlobalMem
;
    mov es:hid_report_offset,esi
    mov es:hid_report_sel,fs    
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
    int 3
;
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
    int 3
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
    int 3
    stc
    ret
valid_custom_hid   Endp

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
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov edi,OFFSET valid_custom_hid
    RegisterCustomHid
;
    mov edi,OFFSET hid_tab
    RegisterHidInput
    ret
Init    Endp
        
code    ENDS

    END Init
