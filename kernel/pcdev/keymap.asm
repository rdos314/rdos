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
; KEYMAP.ASM
; Keyboard mapper module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                
                NAME keymap

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\os\port.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE key.inc

scan_table_entry    STRUC

st_offs DW ?
st_sel  DW ?
st_next DW ?
st_name DB 3 DUP(?)

scan_table_entry    ENDS

data    SEGMENT byte public 'DATA'

curr_scan   DW ?
scan_list   DW ?

data    ENDS

        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:               AddScanTable
;
;               DESCRIPTION:    Adds new scan-table
;
;       PARAMETERS:     DS:BX      Table offset
;                       ES:DI      Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddScanTable    Proc near
    push ds
    push es
    push fs
    push eax
    push si
    push di
;    
    mov ax,es
    mov fs,ax
    mov eax,SIZE scan_table_entry
    AllocateSmallGlobalMem
    mov es:st_offs,bx
    mov es:st_sel,ds
;
    mov ax,fs:[di]
    mov word ptr es:st_name,ax
    mov byte ptr es:st_name+2,0
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:scan_list    
    mov es:st_next,ax
    mov ds:scan_list,es
;
    pop di
    pop si
    pop eax
    pop fs
    pop es
    pop ds    
    ret
AddScanTable    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:               AddInternal
;
;               DESCRIPTION:    Add internal scan-tables
;
;       PARAMETERS:     DS:BX      Table offset
;                       ES:DI      Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        extrn scan_tab_fr:near
        extrn scan_tab_sw:near
        extrn scan_tab_uk:near
        extrn scan_tab_us:near

name_fr DB 'FR', 0
name_sw DB 'SW', 0
name_uk DB 'UK', 0
name_us DB 'US', 0

AddInternal    Proc near
    push ds
    push es
    push bx
    push di
;
    mov bx,cs
    mov ds,bx
    mov es,bx
;    
    mov bx,OFFSET scan_tab_fr
    mov di,OFFSET name_fr
    call AddScanTable
;    
    mov bx,OFFSET scan_tab_sw
    mov di,OFFSET name_sw
    call AddScanTable
;    
    mov bx,OFFSET scan_tab_uk
    mov di,OFFSET name_uk
    call AddScanTable
;    
    mov bx,OFFSET scan_tab_us
    mov di,OFFSET name_us
    call AddScanTable
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:scan_list
    mov ds:curr_scan,ax    
;
    pop di
    pop bx
    pop es
    pop ds    
    ret
AddInternal    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:               Get keyboard layout
;
;               DESCRIPTION:    Get current keyboard layout
;
;       PARAMETERS:     ES:(E)DI      Buffer (must be at least 3 bytes)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_key_layout_name DB 'Get Keyboard Layout', 0

get_key_layout  Proc near
    push ds
    push ax
;    
    mov byte ptr es:[edi],0
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:curr_scan
    or ax,ax
    jz gklDone
;
    mov ds,ax
    mov ax,word ptr ds:st_name
    mov es:[edi],ax
    mov byte ptr es:[edi+2],0

gklDone:
    pop ax
    pop ds
    ret
get_key_layout  Endp

get_key_layout16    Proc far
    push edi
    movzx edi,di
    call get_key_layout
    pop edi
    ret
get_key_layout16    Endp

get_key_layout32    Proc far
    call get_key_layout
    retf32
get_key_layout32    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:               Set keyboard layout
;
;               DESCRIPTION:    Set current keyboard layout
;
;       PARAMETERS:     ES:(E)DI      Requested layout name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_key_layout_name DB 'Set Keyboard Layout', 0

set_key_layout  Proc near
    push ds
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:scan_list

sklLoop:
    or ax,ax
    stc
    jz sklDone
;
    mov ds,ax
    mov ax,word ptr ds:st_name
    cmp ax,es:[edi]
    je sklSet
;
    mov ax,ds:st_next
    jmp sklLoop

sklSet:
    push ds
    mov ax,SEG data
    mov ds,ax
    pop ax
    mov ds:curr_scan,ax
    clc
    
sklDone:
    pop ax
    pop ds
    ret
set_key_layout  Endp

set_key_layout16    Proc far
    push edi
    movzx edi,di
    call set_key_layout
    pop edi
    ret
set_key_layout16    Endp

set_key_layout32    Proc far
    call set_key_layout
    retf32
set_key_layout32    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   init_keymap
;
;               DESCRIPTION:    Init device-driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

keymap_name     DB 'Keymap', 0

keymap_thread:
    int 3
    retf

init_keymap     Proc far
        push ds
        push es
;
        mov ax,cs
        mov ds,ax
        mov es,ax
        mov di,OFFSET keymap_name
        mov si,OFFSET keymap_thread
        mov ax,4
        mov cx,100h
        CreateThread
;
        pop es
        pop ds
        ret
init_keymap     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   init
;
;               DESCRIPTION:    Init device-driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov es,ax
    mov di,OFFSET init_keymap
    HookInitTasking
;
    call AddInternal
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov bx,OFFSET get_key_layout16
    mov si,OFFSET get_key_layout32
    mov di,OFFSET get_key_layout_name
    mov dx,virt_es_in
    mov ax,get_key_layout_nr
    RegisterUserGate
;
    mov bx,OFFSET set_key_layout16
    mov si,OFFSET set_key_layout32
    mov di,OFFSET set_key_layout_name
    mov dx,virt_es_in
    mov ax,set_key_layout_nr
    RegisterUserGate
        
        clc
        ret
init    ENDP

code    ENDS

        END init
