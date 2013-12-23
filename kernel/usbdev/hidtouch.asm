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
; HIDTOUCH.ASM
; Implements HID touch class
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

MAX_POINTS  = 10

coord_struc STRUC

c_x_index   DW ?,?
c_y_index   DW ?,?

c_x_size    DD ?
c_y_size    DD ?

c_x1        DD ?
c_y1        DD ?

c_x2        DD ?
c_y2        DD ?

coord_struc ENDS

hid_touch   STRUC

hid_report_offset   DD ?
hid_report_sel      DW ?

hid_coord_count     DW ?

hid_coord_arr       DB MAX_POINTS * 32 DUP(?)

hid_touch   ENDS

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
    mov eax,SIZE hid_touch
    AllocateSmallGlobalMem
;
    mov es:hid_report_offset,esi
    mov es:hid_report_sel,fs    
    mov es:hid_coord_count,0
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
    push eax
    push edx
;    
    mov ds,ebx    
    cmp cl,1 
    jne hdDone
;
    cmp al,30h
    jne hdNotX
;
    test dx,4
    jnz hdNotX
;
    movzx eax,ds:hid_coord_count
    or eax,eax
    jz hdAddX
;
    dec eax
    mov edx,SIZE coord_struc
    mul edx
    add eax,OFFSET hid_coord_arr
    mov dx,ds:[eax].c_x_index
    add dx,1
    jnc hdCheckY
;
    mov ds:[eax].c_x_index,si
    jmp hdDone

hdCheckY:
    mov dx,ds:[eax].c_y_index
    add dx,1
    jc hdX2
;
    mov dx,ds:[eax].c_y_index+2
    add dx,1
    jc hdAddX

hdX2:
    mov dx,ds:[eax].c_x_index+2
    add dx,1
    jnc hdAddX
;    
    mov ds:[eax].c_x_index+2,si
    jmp hdDone
        
hdAddX:
    movzx eax,ds:hid_coord_count
    inc ds:hid_coord_count
    mov edx,SIZE coord_struc
    mul edx
    add eax,OFFSET hid_coord_arr
    mov ds:[eax].c_x_index,si
    mov ds:[eax].c_y_index,-1
    mov ds:[eax].c_x_index+2,-1
    mov ds:[eax].c_y_index+2,-1
    jmp hdDone

hdNotX:                   
    cmp al,31h
    jne hdDone
;
    movzx eax,ds:hid_coord_count
    or eax,eax
    jz hdAddY
;
    dec eax
    mov edx,SIZE coord_struc
    mul edx
    add eax,OFFSET hid_coord_arr
    mov dx,ds:[eax].c_y_index
    add dx,1
    jnc hdCheckX
;
    mov ds:[eax].c_y_index,si
    jmp hdDone

hdCheckX:
    mov dx,ds:[eax].c_x_index
    add dx,1
    jc hdY2
;
    mov dx,ds:[eax].c_x_index+2
    add dx,1
    jc hdAddY

hdY2:
    mov dx,ds:[eax].c_y_index+2
    add dx,1
    jnc hdAddY
;    
    mov ds:[eax].c_y_index+2,si
    jmp hdDone
        
hdAddY:
    movzx eax,ds:hid_coord_count
    inc ds:hid_coord_count
    mov edx,SIZE coord_struc
    mul edx
    add eax,OFFSET hid_coord_arr
    mov ds:[eax].c_x_index,-1
    mov ds:[eax].c_y_index,si
    mov ds:[eax].c_x_index+2,-1
    mov ds:[eax].c_y_index+2,-1

hdDone:    
    pop edx
    pop eax               
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
    push fs
    pushad
;
    mov fs,ebx
    mov ax,fs:hid_coord_count
    or ax,ax
    jz heFail
;    
    push es
    push ebx
    push ecx
    push edi
;    
    movzx ecx,ax
    mov ebx,OFFSET hid_coord_arr

heLoop:
    push ecx
;    
    push ebx
    mov edi,fs:hid_report_offset
    mov es,fs:hid_report_sel
    mov bx,fs:[ebx].c_x_index
    GetHidLogMax
    pop ebx
    mov fs:[ebx].c_x_size,eax
;    
    push ebx
    mov edi,fs:hid_report_offset
    mov es,fs:hid_report_sel
    mov bx,fs:[ebx].c_y_index
    GetHidLogMax
    pop ebx
    mov fs:[ebx].c_y_size,eax
;
    pop ecx
;    
    add ebx,SIZE coord_struc
    loop heLoop
;
    pop edi  
    pop ecx
    pop ebx
    pop es
    clc
    jmp heDone                

heFail:
    mov eax,fs
    mov es,eax
    xor eax,eax
    mov fs,eax
    FreeMem
    stc
        
heDone:
    popad
    pop fs
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
    mov es,ebx
    movzx ecx,es:hid_coord_count
    mov ebx,OFFSET hid_coord_arr

hhrLoop:
    push es
    push ebx
    push ecx
    movzx ebx,es:[ebx].c_x_index
    mov edi,es:hid_report_offset
    mov es,es:hid_report_sel
    GetUnsignedHidInput
    pop ecx
    pop ebx
    pop es
    mov edx,32767
    mul edx
    div es:[ebx].c_x_size    
    mov es:[ebx].c_x1,eax
    mov es:[ebx].c_x2,eax
;
    push es
    push ebx
    push ecx
    movzx ebx,es:[ebx].c_y_index
    mov edi,es:hid_report_offset
    mov es,es:hid_report_sel
    GetUnsignedHidInput
    pop ecx
    pop ebx
    pop es
    mov edx,32767
    mul edx
    div es:[ebx].c_y_size    
    mov es:[ebx].c_y1,eax
    mov es:[ebx].c_y2,eax
;
    mov ax,es:[ebx].c_x_index+2
    add ax,1
    jc hhrNext
;    
    push es
    push ebx
    push ecx
    movzx ebx,es:[ebx].c_x_index+2
    mov edi,es:hid_report_offset
    mov es,es:hid_report_sel
    GetUnsignedHidInput
    pop ecx
    pop ebx
    pop es
    mov edx,32767
    mul edx
    div es:[ebx].c_x_size    
    mov es:[ebx].c_x2,eax
;
    push es
    push ebx
    push ecx
    movzx ebx,es:[ebx].c_y_index+2
    mov edi,es:hid_report_offset
    mov es,es:hid_report_sel
    GetUnsignedHidInput
    pop ecx
    pop ebx
    pop es
    mov edx,32767
    mul edx
    div es:[ebx].c_y_size    
    mov es:[ebx].c_y2,eax

hhrNext:
    add ebx,SIZE coord_struc
    sub ecx,1
    jnz hhrLoop    
;
    mov ebx,OFFSET hid_coord_arr
    mov ecx,es:[ebx].c_x1
    mov edx,es:[ebx].c_y1
    mov ax,1
    SetMouse
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
;           NAME:           InitTouch
;
;           DESCRIPTION:    Init touch
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_tab:
h00 DD OFFSET hid_begin,        SEG code
h01 DD OFFSET hid_define,       SEG code
h02 DD OFFSET hid_end,          SEG code
h03 DD OFFSET hid_close,        SEG code
h04 DD OFFSET hid_handle_report,SEG code

    public InitTouch_
    
InitTouch_   Proc near
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
InitTouch_   Endp
        

code    ENDS

    END
