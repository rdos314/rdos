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
; BITMODE.ASM
; PC based bitplane-mode support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE video.inc

        .386p

video_object    STRUC

v_base          video_api_struc <>
v_buf_sel       DW ?
v_mem_sel       DW ?
v_mem_base      DD ?
v_has_focus     DB ?

video_object    ENDS

    extrn GetVideoObj:near
    extrn SetVideoObj:near

code    SEGMENT byte public use16 'CODE'

        assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   switch_to
;
;               DESCRIPTION:    Enter focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switch_to       Proc far
        push es
        pushad
;
        call GetVideoObj
        or ax,ax
        jz switch_set_mode
;
        mov es,ax
        mov ax,es:v_mode
        cmp ax,ds:v_mode
        je switch_mode_done

switch_set_mode:
        push ds
        mov ax,ds:v_mode
        xor bx,bx
        mov ds,bx
        mov es,bx
        push 10h
        V86BiosInt
        pop ds

switch_mode_done:
    mov ax,ds
    call SetVideoObj
;
        EnterSection ds:v_section
        push ds
        mov ds:v_has_focus,1
        mov es,ds:v_mem_sel
        mov ds,ds:v_buf_sel
        xor edi,edi
        mov eax,77AA55AAh
        mov ecx,1000h
        rep stos dword ptr es:[edi]
        pop ds
        LeaveSection ds:v_section

switch_to_done:
        popad
        pop es
        retf32
switch_to       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SwitchFrom
;
;               DESCRIPTION:    Leave focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

switch_from     Proc far
        push es
        pushad
;
        EnterSection ds:v_section
        push ds
        mov ds:v_has_focus,0
        mov es,ds:v_buf_sel
        pop ds
        LeaveSection ds:v_section
;
        popad
        pop es
        retf32
switch_from     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   init_mode12
;
;               DESCRIPTION:    Init video-mode 12
;
;               RETURNS:                AX              Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mode12     Proc far
        push ds
        push es
        push cx
        push si
        push di
;
        mov eax,SIZE video_object
        AllocateSmallGlobalMem
        mov cx,35
        mov ax,cs
        mov ds,ax
        mov si,OFFSET ModeTab
        xor di,di
        rep movsd
        push es
;
        mov eax,40000h
        AllocateGlobalMem
        xor eax,eax
        xor edi,edi
        mov ecx,10000h
        rep stos dword ptr es:[edi]
        int 3
;
        mov eax,10000h
        AllocateBigLinear
        AllocateGdt
        mov ecx,eax
        CreateDataSelector16
;
        pop ds
        mov ds:v_mode,12h
        mov ds:v_buf_sel,es
        mov ds:v_has_focus,0
        InitSection ds:v_section
        mov ds:v_mem_sel,bx
        mov ds:v_mem_base,edx
;
        mov cx,10h
        mov edx,0A0000h
        xor eax,eax
        xor ebx,ebx

init_org_bit_loop:
        SetPageEntry
        add edx,1000h
        loop init_org_bit_loop
;
        mov cx,10h
        mov edx,ds:v_mem_base
        xor ebx,ebx
        mov eax,0A000Bh

init_alias_bit_loop:
        SetPageEntry
        add eax,1000h
        add edx,1000h
        loop init_alias_bit_loop
;
        mov ax,ds
        clc
;
        pop di
        pop si
        pop cx
        pop es
        pop ds
        retf32
init_mode12     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   delete_mode12
;
;               DESCRIPTION:    Delete video-mode 12
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_mode12   Proc far
        push ax
        push ebx
        push ecx
        push edx
;
        mov edx,ds:v_mem_base
        xor ebx,ebx
        xor eax,eax
        mov cx,10h

delete_bit_loop:
        SetPageEntry
        add edx,1000h
        loop delete_bit_loop
;
        mov es,ds:v_buf_sel
        FreeMem
        mov bx,ds:v_mem_sel
        FreeGdt
        mov edx,ds:v_mem_base
        mov ecx,10000h
        FreeLinear
        mov ax,ds
        mov es,ax
        xor ax,ax
        mov ds,ax
        FreeMem
;
        pop edx
        pop ecx
        pop ebx
        pop ax
        retf32
delete_mode12   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ModeTab
;
;               DESCRIPTION:    Dispatch table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error   Proc far
        stc
        retf32
error   Endp

ModeTab:
mt00 DD OFFSET delete_mode12,   SEG code
mt01 DD OFFSET switch_to,               SEG code
mt02 DD OFFSET switch_from,             SEG code
mt03 DD OFFSET error,                   SEG code
mt04 DD OFFSET error,                   SEG code
mt05 DD OFFSET error,                   SEG code
mt06 DD OFFSET error,                   SEG code
mt07 DD OFFSET error,                   SEG code
mt08 DD OFFSET error,                   SEG code
mt09 DD OFFSET error,                   SEG code
mt0A DD OFFSET error,                   SEG code
mt0B DD OFFSET error,                   SEG code
mt0C DD OFFSET error,                   SEG code
mt0D DD OFFSET error,                   SEG code
mt0E DD OFFSET error,                   SEG code
mt0F DD OFFSET error,                   SEG code
mt10 DD OFFSET error,                   SEG code
mt11 DD OFFSET error,                   SEG code
mt12 DD OFFSET error,                   SEG code
mt13 DD OFFSET error,                   SEG code
mt14 DD OFFSET error,                   SEG code
mt15 DD OFFSET error,                   SEG code
mt16 DD OFFSET error,                   SEG code
mt17 DD OFFSET error,                   SEG code
mt18 DD OFFSET error,                   SEG code
mt19 DD OFFSET error,                   SEG code
mt1A DD OFFSET error,                   SEG code
mt1B DD OFFSET error,                   SEG code
mt1C DD OFFSET error,                   SEG code
mt1D DD OFFSET error,                   SEG code
mt1E DD OFFSET error,                   SEG code
mt1F DD OFFSET error,                   SEG code
mt20 DD OFFSET error,                   SEG code
mt21 DD OFFSET error,                   SEG code
mt22 DD OFFSET error,                   SEG code
mt23 DD OFFSET error,                   SEG code
mt24 DD OFFSET error,                   SEG code
mt25 DD OFFSET error,                   SEG code
mt26 DD OFFSET error,                   SEG code
mt27 DD OFFSET error,                   SEG code
mt28 DD OFFSET error,                   SEG code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   init_bit_mode
;
;               DESCRIPTION:    Init bit-mode support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public init_bit_mode

init_bit_mode   Proc near       
        mov ax,cs
        mov es,ax       
        mov ax,12h
        xor bl,bl
        mov cx,640
        mov dx,480
        mov edi,OFFSET init_mode12
;       RegisterVideoMode
        ret
init_bit_mode   Endp

code    ENDS

        END

