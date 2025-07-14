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

c_tip_index DW ?

c_x_size    DD ?
c_y_size    DD ?

c_tip       DW ?

c_x1        DW ?
c_y1        DW ?

c_x2        DW ?
c_y2        DW ?

coord_struc ENDS

hid_touch   STRUC

hid_report_offset   DD ?
hid_report_sel      DW ?

hid_coord_count     DW ?

hid_coord_arr       DB MAX_POINTS * 32 DUP(?)

hid_touch   ENDS

data    SEGMENT byte public 'DATA'

ht_installed    DW ?
ht_disable      DB ?

data    ENDS  


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
;
    cmp cl,9
    jne hdNotButton
;    
    cmp al,1
    jne hdDone
;    
    movzx eax,ds:hid_coord_count
    inc ds:hid_coord_count
    mov edx,SIZE coord_struc
    mul edx
    add eax,OFFSET hid_coord_arr
    mov ds:[eax].c_tip_index,si
    mov ds:[eax].c_x_index,-1
    mov ds:[eax].c_y_index,-1
    mov ds:[eax].c_x_index+2,-1
    mov ds:[eax].c_y_index+2,-1
    jmp hdDone

hdNotButton:        
    cmp cl,0Dh
    jne hdNotTip
;
    cmp al,42h
    jne hdDone
;
    movzx eax,ds:hid_coord_count
    or eax,eax
    jz hdAddTip
;
    dec eax
    mov edx,SIZE coord_struc
    mul edx
    add eax,OFFSET hid_coord_arr
    mov dx,ds:[eax].c_tip_index
    add dx,1
    jnc hdAddTip
;
    mov ds:[eax].c_tip_index,si
    jmp hdDone

hdAddTip:
    movzx eax,ds:hid_coord_count
    inc ds:hid_coord_count
    mov edx,SIZE coord_struc
    mul edx
    add eax,OFFSET hid_coord_arr
    mov ds:[eax].c_tip_index,si
    mov ds:[eax].c_x_index,-1
    mov ds:[eax].c_y_index,-1
    mov ds:[eax].c_x_index+2,-1
    mov ds:[eax].c_y_index+2,-1
    jmp hdDone
            
hdNotTip:    
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
    mov ds:[eax].c_tip_index,-1
    mov ds:[eax].c_x_index,si
    mov ds:[eax].c_y_index,-1
    mov ds:[eax].c_x_index+2,-1
    mov ds:[eax].c_y_index+2,-1
    jmp hdDone

hdNotX:                   
    cmp al,31h
    jne hdDone
;
    test dx,4
    jnz hdDone
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
    mov ds:[eax].c_tip_index,-1
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
    cmp bx,-1
    je hePopFail
;    
    GetHidLogMax
    pop ebx
    mov fs:[ebx].c_x_size,eax
;    
    push ebx
    mov edi,fs:hid_report_offset
    mov es,fs:hid_report_sel
    mov bx,fs:[ebx].c_y_index
    cmp bx,-1
    je hePopFail
;    
    GetHidLogMax
    pop ebx
    mov fs:[ebx].c_y_size,eax
;
    pop ecx
;    
    add ebx,SIZE coord_struc
    loop heLoop
;
    mov eax,SEG data
    mov es,eax
    mov al,es:ht_disable
    or al,al
    jnz heDisabled
;
    mov es:ht_installed,1 

heDisabled:
    pop edi  
    pop ecx
    pop ebx
    pop es
    clc
    jmp heDone                

hePopFail:
    pop ebx
    pop ecx
    pop edi  
    pop ecx
    pop ebx
    pop es

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
    mov ax,es:[ebx].c_tip_index
    add ax,1
    jc hhrTipDone
;
    push es
    push ebx
    push ecx
    movzx ebx,es:[ebx].c_tip_index
    mov edi,es:hid_report_offset
    mov es,es:hid_report_sel
    GetUnsignedHidInput    
    pop ecx
    pop ebx
    pop es
;
;    xor ax,1
    mov es:[ebx].c_tip,ax
        
hhrTipDone:
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
    mov es:[ebx].c_x1,ax
    mov es:[ebx].c_x2,ax
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
    mov es:[ebx].c_y1,ax
    mov es:[ebx].c_y2,ax
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
    mov es:[ebx].c_x2,ax
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
    mov es:[ebx].c_y2,ax

hhrNext:
    add ebx,SIZE coord_struc
    sub ecx,1
    jnz hhrLoop    
;
    mov ebx,OFFSET hid_coord_arr
    mov cx,es:[ebx].c_x1
    mov dx,es:[ebx].c_y1
    mov ax,es:[ebx].c_tip
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
;           NAME:           HasTouch
;
;           DESCRIPTION:    Check if touch is available
;
;           RETURNS:        NC      Touch available
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_touch_name DB 'Has Touch',0

has_touch      Proc far
    push ds
    push eax
    mov eax,SEG data
    mov ds,eax
    mov ax,ds:ht_installed
    or ax,ax
    jz htNo

htYes:
    clc
    jmp htDone

htNo:
    stc

htDone:
    pop eax
    pop ds
    ret
has_touch  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetValue
;
;       Purpose:        Get value from environment
;
;       Parameters:     ES:EDI   Name
;
;       Returns:        NC      Found
;                       AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
GetValue    Proc near
    push ds
    push ebx
    push ecx
    push esi
;
    LockSysEnv
    mov ds,bx
    xor esi,esi
    
find_val:
    push edi

find_val_loop:
    cmpsb
    jnz find_val_next
;       
    mov al,es:[edi]
    or al,al
    jnz find_val_loop
    mov al,[esi]
    cmp al,'='
    je find_val_found

find_val_next:
    pop edi

find_val_next_bp:
    lodsb
    or al,al
    jnz find_val_next_bp
;
    mov al,[esi]
    or al,al
    jne find_val
;
    xor ax,ax
    stc
    jmp find_val_done

find_val_found:
    pop edi
    inc esi  
    xor ax,ax

find_val_digit:
    mov bl,[esi]
    inc esi
    sub bl,'0'
    jc find_val_save
;
    cmp bl,10
    jnc find_val_save
;       
    mov ecx,10
    mul ecx
    add al,bl
    adc ah,0
    jmp find_val_digit

find_val_save:
    clc

find_val_done:
    pushf
    UnlockSysEnv
    popf
;
    pop esi
    pop ecx
    pop ebx
    pop ds
    ret
GetValue    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitTouch
;
;           DESCRIPTION:    Init touch
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_touch_name       DB 'DISABLE.TOUCH', 0

hid_tab:
h00 DD OFFSET hid_begin,        SEG code
h01 DD OFFSET hid_define,       SEG code
h02 DD OFFSET hid_end,          SEG code
h03 DD OFFSET hid_close,        SEG code
h04 DD OFFSET hid_handle_report,SEG code

    public InitTouch_
    
InitTouch_   Proc near
    push ds
    push es
    push eax
    push edi
;   
    mov eax,SEG data
    mov ds,eax
    mov ds:ht_installed,0
;
    mov eax,cs
    mov es,eax
    mov edi,OFFSET disable_touch_name
    mov ds:ht_disable,0
    call GetValue       
    jc itDisOk
;
    mov ds:ht_disable,al

itDisOk:
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov edi,OFFSET hid_tab
    RegisterHidInput
;    
    mov esi,OFFSET has_touch
    mov edi,OFFSET has_touch_name
    xor dx,dx
    mov ax,has_touch_nr
    RegisterBimodalUserGate
;
    pop edi
    pop eax
    pop es    
    pop ds
    ret
InitTouch_   Endp
        

code    ENDS

    END
