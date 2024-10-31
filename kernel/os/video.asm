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
; VIDEO.ASM
; Standard video interface. Hardware independent
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\handle.inc
INCLUDE ..\os\blk.inc
INCLUDE ..\hint.inc
INCLUDE bitmap.inc
INCLUDE video.inc
INCLUDE ..\apicheck.inc

FLAG_GET_MODES   = 1

video_mode_struc       STRUC

vm_next             DW ?

vm_mode_nr          DW ?
vm_bits             DB ?
vm_resv             DB ?
vm_x_size           DW ?
vm_y_size           DW ?
vm_line_size        DW ?
vm_lfb              DD ?

video_mode_struc       ENDS

data    SEGMENT byte public 'DATA'

focus_console   DW ?
update_thread   DW ?
curr_video_mode DW ?

disp_fixed      DW ?
disp_x          DW ?
disp_y          DW ?

fixed_mode      DW ?

flags           DW ?

video_mode_list DW ?

data    ENDS

    .386p

code    SEGMENT byte public 'CODE'

    assume cs:code

    extrn init_bitmap:near
    extrn init_sprite:near
    extrn CreateVideoBitmap:near
    extrn CreateTextBitmap:near
    extrn AllocateVideoBuffer:near
    extrn FreeVideoBuffer:near
    extrn IsMarkerVisible:near
    extrn InitKeyboardConsole:near
    extrn InitMouseConsole:near
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetValue
;
;       Purpose:        Get value from environment
;
;       Parameters:     ES:EDI   Name
;
;       Returns:        NC          Found
;                       EAX         Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
GetValue    Proc near
    push ds
    push bx
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
    xor eax,eax
    stc
    jmp find_val_done

find_val_found:
    pop edi
    inc esi  
    xor eax,eax

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
    movzx ebx,bl
    add eax,ebx
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
    pop bx
    pop ds
    ret
GetValue    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Font8x19
;
;   DESCRIPTION:    8x19 font
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public font8x19
    
font8x19:
f00 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f01 db 000h, 000h, 000h, 07Eh, 081h, 081h, 0A5h, 081h, 081h, 081h, 0BDh, 099h, 081h, 081h, 07Eh, 000h, 000h, 000h, 000h
f02 db 000h, 000h, 000h, 07Eh, 0FFh, 0FFh, 0DBh, 0FFh, 0FFh, 0FFh, 0C3h, 0E7h, 0FFh, 0FFh, 07Eh, 000h, 000h, 000h, 000h
f03 db 000h, 000h, 000h, 000h, 000h, 000h, 06Ch, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h, 000h, 000h, 000h
f04 db 000h, 000h, 000h, 000h, 000h, 000h, 010h, 038h, 07Ch, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h, 000h, 000h, 000h, 000h
f05 db 000h, 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 0E7h, 0E7h, 0E7h, 0E7h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f06 db 000h, 000h, 000h, 000h, 018h, 018h, 03Ch, 07Eh, 0FFh, 0FFh, 0FFh, 07Eh, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f07 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f08 db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0E7h, 0C3h, 0C3h, 0C3h, 0E7h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
f09 db 000h, 000h, 000h, 000h, 000h, 000h, 03Ch, 066h, 042h, 042h, 042h, 066h, 03Ch, 000h, 000h, 000h, 000h, 000h, 000h
f0A db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0C3h, 099h, 0BDh, 0BDh, 0BDh, 099h, 0C3h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
f0B db 000h, 000h, 000h, 01Eh, 006h, 00Eh, 01Ah, 030h, 078h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 078h, 000h, 000h, 000h, 000h
f0C db 000h, 000h, 000h, 03Ch, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h, 018h, 000h, 000h, 000h, 000h
f0D db 000h, 000h, 000h, 03Fh, 033h, 033h, 03Fh, 030h, 030h, 030h, 030h, 030h, 070h, 0F0h, 0E0h, 000h, 000h, 000h, 000h
f0E db 000h, 000h, 000h, 07Fh, 063h, 063h, 07Fh, 063h, 063h, 063h, 063h, 063h, 067h, 0E7h, 0E6h, 0C0h, 000h, 000h, 000h
f0F db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 0DBh, 03Ch, 0E7h, 0E7h, 03Ch, 0DBh, 018h, 018h, 000h, 000h, 000h, 000h
f10 db 000h, 000h, 000h, 080h, 0C0h, 0E0h, 0F0h, 0F8h, 0FEh, 0FEh, 0F8h, 0F0h, 0E0h, 0C0h, 080h, 000h, 000h, 000h, 000h
f11 db 000h, 000h, 000h, 002h, 006h, 00Eh, 01Eh, 03Eh, 0FEh, 0FEh, 03Eh, 01Eh, 00Eh, 006h, 002h, 000h, 000h, 000h, 000h
f12 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 000h, 000h, 000h, 000h
f13 db 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 066h, 066h, 000h, 000h, 000h, 000h
f14 db 000h, 000h, 000h, 07Fh, 0DBh, 0DBh, 0DBh, 0DBh, 07Bh, 01Bh, 01Bh, 01Bh, 01Bh, 01Bh, 01Bh, 000h, 000h, 000h, 000h
f15 db 000h, 000h, 000h, 07Ch, 0C6h, 060h, 038h, 06Ch, 0C6h, 0C6h, 06Ch, 038h, 00Ch, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f16 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0FEh, 0FEh, 000h, 000h, 000h, 000h
f17 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 07Eh, 000h, 000h, 000h
f18 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f19 db 000h, 000h, 000h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 000h, 000h, 000h, 000h
f1A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 00Ch, 0FEh, 00Ch, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1B db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 030h, 060h, 0FEh, 060h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1C db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h
f1D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 024h, 066h, 0FFh, 066h, 024h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1E db 000h, 000h, 000h, 000h, 000h, 010h, 010h, 038h, 038h, 07Ch, 07Ch, 0FEh, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h
f1F db 000h, 000h, 000h, 000h, 000h, 0FEh, 0FEh, 07Ch, 07Ch, 038h, 038h, 010h, 010h, 000h, 000h, 000h, 000h, 000h, 000h
f20 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f21 db 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 03Ch, 018h, 018h, 018h, 018h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f22 db 000h, 000h, 066h, 066h, 066h, 024h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f23 db 000h, 000h, 000h, 06Ch, 06Ch, 06Ch, 0FEh, 06Ch, 06Ch, 06Ch, 06Ch, 0FEh, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h
f24 db 000h, 018h, 018h, 07Ch, 0C6h, 0C2h, 0C0h, 0C0h, 07Ch, 006h, 006h, 006h, 086h, 0C6h, 07Ch, 018h, 018h, 000h, 000h
f25 db 000h, 000h, 000h, 0C6h, 0C6h, 0CCh, 00Ch, 018h, 018h, 030h, 030h, 060h, 066h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f26 db 000h, 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 076h, 0DCh, 0DCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f27 db 000h, 000h, 018h, 018h, 018h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f28 db 000h, 000h, 000h, 00Ch, 018h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 018h, 00Ch, 000h, 000h, 000h, 000h
f29 db 000h, 000h, 000h, 030h, 018h, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 018h, 030h, 000h, 000h, 000h, 000h
f2A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 03Ch, 0FFh, 03Ch, 066h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f2B db 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 0FFh, 018h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 000h
f2C db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 030h, 000h, 000h, 000h
f2D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f2E db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f2F db 000h, 000h, 000h, 006h, 006h, 00Ch, 00Ch, 018h, 018h, 030h, 030h, 060h, 060h, 0C0h, 0C0h, 000h, 000h, 000h, 000h
f30 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0D6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f31 db 000h, 000h, 000h, 018h, 038h, 078h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 000h, 000h, 000h, 000h
f32 db 000h, 000h, 000h, 07Ch, 0C6h, 006h, 006h, 00Ch, 018h, 030h, 060h, 0C0h, 0C0h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f33 db 000h, 000h, 000h, 07Ch, 0C6h, 006h, 006h, 006h, 03Ch, 006h, 006h, 006h, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f34 db 000h, 000h, 000h, 01Ch, 01Ch, 03Ch, 03Ch, 06Ch, 06Ch, 0CCh, 0FEh, 00Ch, 00Ch, 00Ch, 01Eh, 000h, 000h, 000h, 000h
f35 db 000h, 000h, 000h, 0FEh, 0C0h, 0C0h, 0C0h, 0C0h, 0FCh, 006h, 006h, 006h, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f36 db 000h, 000h, 000h, 038h, 060h, 0C0h, 0C0h, 0C0h, 0FCh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f37 db 000h, 000h, 000h, 0FEh, 0C6h, 006h, 006h, 006h, 00Ch, 018h, 018h, 030h, 030h, 030h, 030h, 000h, 000h, 000h, 000h
f38 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f39 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 006h, 006h, 00Ch, 078h, 000h, 000h, 000h, 000h
f3A db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h
f3B db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 030h, 000h, 000h, 000h, 000h
f3C db 000h, 000h, 000h, 000h, 006h, 00Ch, 018h, 030h, 060h, 060h, 030h, 018h, 00Ch, 006h, 000h, 000h, 000h, 000h, 000h
f3D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f3E db 000h, 000h, 000h, 000h, 060h, 030h, 018h, 00Ch, 006h, 006h, 00Ch, 018h, 030h, 060h, 000h, 000h, 000h, 000h, 000h
f3F db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 006h, 006h, 00Ch, 018h, 018h, 018h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f40 db 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0DEh, 0DEh, 0DEh, 0DCh, 0C0h, 0C0h, 07Ch, 000h, 000h, 000h, 000h
f41 db 000h, 000h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f42 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 066h, 066h, 066h, 066h, 066h, 0FCh, 000h, 000h, 000h, 000h
f43 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C2h, 066h, 03Ch, 000h, 000h, 000h, 000h
f44 db 000h, 000h, 000h, 0F8h, 06Ch, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 06Ch, 0F8h, 000h, 000h, 000h, 000h
f45 db 000h, 000h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f46 db 000h, 000h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f47 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0DEh, 0C6h, 0C6h, 0C6h, 066h, 03Ah, 000h, 000h, 000h, 000h
f48 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f49 db 000h, 000h, 000h, 03Ch, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f4A db 000h, 000h, 000h, 00Fh, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f4B db 000h, 000h, 000h, 0E6h, 066h, 066h, 06Ch, 06Ch, 078h, 07Ch, 06Ch, 06Ch, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f4C db 000h, 000h, 000h, 0F0h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f4D db 000h, 000h, 000h, 0C6h, 0EEh, 0FEh, 0FEh, 0D6h, 0D6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f4E db 000h, 000h, 000h, 0C6h, 0C6h, 0E6h, 0E6h, 0F6h, 0F6h, 0DEh, 0DEh, 0CEh, 0CEh, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f4F db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
f50 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f51 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0D6h, 0DEh, 07Ch, 00Ch, 00Eh, 000h, 000h
f52 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 06Ch, 06Ch, 066h, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f53 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C0h, 060h, 038h, 00Ch, 006h, 006h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f54 db 000h, 000h, 000h, 07Eh, 07Eh, 05Ah, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f55 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f56 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 010h, 000h, 000h, 000h, 000h
f57 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0FEh, 06Ch, 06Ch, 000h, 000h, 000h, 000h
f58 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 06Ch, 06Ch, 038h, 038h, 06Ch, 06Ch, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f59 db 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f5A db 000h, 000h, 000h, 0FEh, 0C6h, 086h, 006h, 00Ch, 018h, 030h, 060h, 0C0h, 0C2h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f5B db 000h, 000h, 000h, 03Ch, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 03Ch, 000h, 000h, 000h, 000h
f5C db 000h, 000h, 000h, 0C0h, 0C0h, 060h, 060h, 030h, 030h, 018h, 018h, 00Ch, 00Ch, 006h, 006h, 000h, 000h, 000h, 000h
f5D db 000h, 000h, 000h, 03Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 03Ch, 000h, 000h, 000h, 000h
f5E db 000h, 010h, 038h, 06Ch, 0C6h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f5F db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h
f60 db 000h, 000h, 030h, 018h, 00Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f61 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f62 db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 078h, 06Ch, 066h, 066h, 066h, 066h, 066h, 0DCh, 000h, 000h, 000h, 000h
f63 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f64 db 000h, 000h, 000h, 01Ch, 00Ch, 00Ch, 00Ch, 03Ch, 06Ch, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f65 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f66 db 000h, 000h, 000h, 038h, 06Ch, 064h, 060h, 060h, 0F0h, 060h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f67 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 07Ch, 00Ch, 00Ch, 0CCh, 078h, 000h
f68 db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 06Ch, 076h, 066h, 066h, 066h, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f69 db 000h, 000h, 000h, 018h, 018h, 000h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f6A db 000h, 000h, 000h, 006h, 006h, 000h, 000h, 00Eh, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 066h, 066h, 03Ch, 000h
f6B db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 066h, 066h, 06Ch, 078h, 078h, 06Ch, 066h, 0E6h, 000h, 000h, 000h, 000h
f6C db 000h, 000h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f6D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 0FEh, 0D6h, 0D6h, 0D6h, 0D6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f6E db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 000h, 000h, 000h
f6F db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f70 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 060h, 0F0h, 000h
f71 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 07Ch, 00Ch, 00Ch, 00Ch, 01Eh, 000h
f72 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 076h, 066h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f73 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 060h, 038h, 00Ch, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f74 db 000h, 000h, 000h, 010h, 030h, 030h, 030h, 0FCh, 030h, 030h, 030h, 030h, 030h, 036h, 01Ch, 000h, 000h, 000h, 000h
f75 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f76 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 000h, 000h, 000h, 000h
f77 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0FEh, 06Ch, 000h, 000h, 000h, 000h
f78 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 06Ch, 038h, 038h, 06Ch, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f79 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 00Ch, 078h, 000h
f7A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0C6h, 00Ch, 018h, 030h, 060h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f7B db 000h, 000h, 000h, 00Eh, 018h, 018h, 018h, 018h, 070h, 070h, 018h, 018h, 018h, 018h, 00Eh, 000h, 000h, 000h, 000h
f7C db 000h, 000h, 000h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f7D db 000h, 000h, 000h, 070h, 018h, 018h, 018h, 018h, 00Eh, 00Eh, 018h, 018h, 018h, 018h, 070h, 000h, 000h, 000h, 000h
f7E db 000h, 000h, 000h, 076h, 0DCh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f7F db 000h, 000h, 000h, 000h, 000h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0FEh, 000h, 000h, 000h, 000h, 000h
f80 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C2h, 066h, 03Ch, 018h, 00Ch, 038h, 000h
f81 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f82 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f83 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f84 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f85 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f86 db 000h, 000h, 000h, 038h, 06Ch, 038h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f87 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C6h, 07Ch, 018h, 00Ch, 038h, 000h
f88 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f89 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f8A db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f8B db 000h, 000h, 000h, 000h, 066h, 066h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8C db 000h, 000h, 000h, 018h, 03Ch, 066h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8D db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8E db 0C6h, 0C6h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f8F db 038h, 06Ch, 038h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f90 db 00Ch, 018h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f91 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 036h, 036h, 07Eh, 0D8h, 0D8h, 0D8h, 06Eh, 000h, 000h, 000h, 000h
f92 db 000h, 000h, 000h, 03Eh, 06Ch, 0CCh, 0CCh, 0CCh, 0FEh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CEh, 000h, 000h, 000h, 000h
f93 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f94 db 000h, 000h, 000h, 000h, 0C6h, 0C6h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f95 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f96 db 000h, 000h, 000h, 030h, 078h, 0CCh, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f97 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f98 db 000h, 000h, 000h, 000h, 0C6h, 0C6h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 00Ch, 078h, 000h
f99 db 0C6h, 0C6h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
f9A db 0C6h, 0C6h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f9B db 000h, 000h, 000h, 018h, 018h, 03Ch, 066h, 060h, 060h, 060h, 060h, 066h, 03Ch, 018h, 018h, 000h, 000h, 000h, 000h
f9C db 000h, 000h, 038h, 06Ch, 064h, 060h, 060h, 0F0h, 060h, 060h, 060h, 060h, 060h, 0E6h, 0FCh, 000h, 000h, 000h, 000h
f9D db 000h, 000h, 000h, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h, 018h, 07Eh, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f9E db 000h, 000h, 0F8h, 0CCh, 0CCh, 0CCh, 0F8h, 0C4h, 0CCh, 0DEh, 0CCh, 0CCh, 0CCh, 0CCh, 0C6h, 000h, 000h, 000h, 000h
f9F db 000h, 000h, 00Eh, 01Bh, 018h, 018h, 018h, 018h, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 0D8h, 070h, 000h, 000h
fA0 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
fA1 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
fA2 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
fA3 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
fA4 db 000h, 000h, 000h, 000h, 076h, 0DCh, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 000h, 000h, 000h
fA5 db 076h, 0DCh, 000h, 0C6h, 0C6h, 0E6h, 0E6h, 0F6h, 0F6h, 0DEh, 0DEh, 0CEh, 0CEh, 0C6h, 0C6h, 000h, 000h, 000h, 000h
fA6 db 000h, 000h, 03Ch, 06Ch, 06Ch, 06Ch, 03Eh, 000h, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fA7 db 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 000h, 07Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fA8 db 000h, 000h, 000h, 030h, 030h, 000h, 030h, 030h, 030h, 060h, 0C0h, 0C0h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
fA9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0C0h, 0C0h, 0C0h, 0C0h, 000h, 000h, 000h, 000h, 000h, 000h
fAA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 006h, 006h, 006h, 006h, 000h, 000h, 000h, 000h, 000h, 000h
fAB db 000h, 000h, 0C0h, 0C0h, 0C0h, 0C2h, 0C6h, 0CCh, 018h, 030h, 060h, 0DCh, 0A6h, 00Ch, 018h, 030h, 03Eh, 000h, 000h
fAC db 000h, 000h, 0C0h, 0C0h, 0C0h, 0C2h, 0C6h, 0CCh, 018h, 030h, 060h, 0CCh, 09Ch, 03Ch, 07Eh, 00Ch, 00Ch, 000h, 000h
fAD db 000h, 000h, 000h, 018h, 018h, 000h, 000h, 018h, 018h, 018h, 018h, 03Ch, 03Ch, 03Ch, 018h, 000h, 000h, 000h, 000h
fAE db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 033h, 066h, 0CCh, 0CCh, 066h, 033h, 000h, 000h, 000h, 000h, 000h, 000h
fAF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 066h, 033h, 033h, 066h, 0CCh, 000h, 000h, 000h, 000h, 000h, 000h
fB0 db 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h
fB1 db 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h
fB2 db 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh
fB3 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB4 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB6 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fB7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fB8 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB9 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 006h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBA db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBB db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 006h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBC db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 006h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBD db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBE db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC0 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC1 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC2 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC3 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC4 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC6 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC7 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fC8 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 030h, 03Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 03Fh, 030h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCA db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F7h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fCB db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0F7h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCC db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 030h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCD db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fCE db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F7h, 000h, 0F7h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCF db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD0 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD1 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD2 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD3 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 03Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD4 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 01Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD5 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 01Fh, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD6 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 03Fh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD7 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FFh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD8 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 018h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD9 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fDA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fDB db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
fDC db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
fDD db 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h
fDE db 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh
fDF db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fE0 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 0D8h, 0D8h, 0D8h, 0D8h, 0DCh, 076h, 000h, 000h, 000h, 000h
fE1 db 000h, 000h, 000h, 078h, 0CCh, 0CCh, 0CCh, 0CCh, 0D8h, 0CCh, 0C6h, 0C6h, 0C6h, 0C6h, 0DCh, 000h, 000h, 000h, 000h
fE2 db 000h, 000h, 000h, 0FEh, 0C6h, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 000h, 000h, 000h, 000h
fE3 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h
fE4 db 000h, 000h, 000h, 0FEh, 0C6h, 0C0h, 060h, 030h, 018h, 018h, 030h, 060h, 0C0h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
fE5 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 070h, 000h, 000h, 000h, 000h
fE6 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 0C0h, 000h
fE7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
fE8 db 000h, 000h, 000h, 03Ch, 018h, 03Ch, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 03Ch, 000h, 000h, 000h, 000h
fE9 db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
fEA db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 06Ch, 06Ch, 0EEh, 000h, 000h, 000h, 000h
fEB db 000h, 000h, 000h, 01Eh, 030h, 018h, 00Ch, 03Eh, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 000h, 000h, 000h, 000h
fEC db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 0DBh, 0DBh, 0DBh, 0DBh, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h
fED db 000h, 000h, 000h, 000h, 000h, 003h, 006h, 07Eh, 0CFh, 0DBh, 0DBh, 0F3h, 07Eh, 060h, 0C0h, 000h, 000h, 000h, 000h
fEE db 000h, 000h, 000h, 01Ch, 030h, 060h, 060h, 060h, 07Ch, 060h, 060h, 060h, 060h, 030h, 01Ch, 000h, 000h, 000h, 000h
fEF db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
fF0 db 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h
fF1 db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 07Eh, 018h, 018h, 018h, 000h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF2 db 000h, 000h, 000h, 000h, 060h, 030h, 018h, 00Ch, 006h, 00Ch, 018h, 030h, 060h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF3 db 000h, 000h, 000h, 000h, 006h, 00Ch, 018h, 030h, 060h, 030h, 018h, 00Ch, 006h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF4 db 000h, 000h, 000h, 00Eh, 01Bh, 01Bh, 01Bh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fF5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0D8h, 0D8h, 0D8h, 070h, 000h, 000h, 000h, 000h
fF6 db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 07Eh, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h
fF7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 000h, 000h, 076h, 0DCh, 000h, 000h, 000h, 000h, 000h, 000h
fF8 db 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fF9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFB db 000h, 000h, 00Fh, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 0ECh, 06Ch, 06Ch, 03Ch, 01Ch, 000h, 000h, 000h, 000h
fFC db 000h, 000h, 0D8h, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFD db 000h, 000h, 038h, 06Ch, 00Ch, 018h, 030h, 064h, 07Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFE db 000h, 000h, 000h, 000h, 000h, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 000h, 000h, 000h, 000h, 000h
fFF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

AttribBgrTab:
abt00   DD 00000000h
abt01   DD 00000099h
abt02   DD 00009900h
abt03   DD 000066CCh
abt04   DD 00990000h
abt05   DD 00990099h
abt06   DD 00999900h
abt07   DD 00CCCCCCh
abt08   DD 00666666h
abt09   DD 006666FFh
abt0A   DD 0066FF66h
abt0B   DD 0066FFFFh
abt0C   DD 00FF6666h
abt0D   DD 00FF66FFh
abt0E   DD 00FFFF66h
abt0F   DD 00FFFFFFh

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateConsoleEfi
;
;   DESCRIPTION:    Create a new EFI console with fixed font
;
;   RETURNS:        ES      Console sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateConsoleEfi  PROC near
    push ds
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax
    movzx eax,ds:efi_width
    shr eax,3
    mov esi,eax
;
    movzx eax,ds:efi_height
    mov ecx,19
    xor edx,edx
    div ecx
    mov edi,eax
;
    mov ax,SEG data
    mov ds,ax
    movzx ebx,ds:disp_x
    or ebx,ebx
    jz cfeXOk
;
    mov eax,ebx
    shr eax,3
    mov esi,eax

cfeXOk:
    movzx ebx,ds:disp_y
    or ebx,ebx
    jz cfeYOk
;
    mov eax,ebx
    mov ecx,19
    xor edx,edx
    div ecx
    mov edi,eax
    
cfeYOk:
    mul esi
    mov ebp,eax
    shl eax,2
    add eax,OFFSET c_text_data
    AllocateBigLinear
    AllocateGdt
    mov ecx,eax
    CreateDataSelector32
    mov es,bx
    mov es:c_text_entries,bp
;
    mov ax,system_data_sel
    mov ds,ax
    mov es:c_flags,0
    mov es:c_rows,di
    mov es:c_cols,si
    mov es:c_con_row,0
    mov es:c_con_col,0
    mov es:c_curr_row,0
    mov es:c_curr_col,0
    mov es:c_prev_row,0
    mov es:c_prev_col,0
    mov es:c_font,0
    mov es:c_video_handle,0
    mov es:c_video_sel,0
    mov es:c_video_mode,0
    mov es:c_font_width,8
    mov es:c_font_height,19
;    
    push es
    mov al,32
    mov edi,ds:efi_lfb
    mov es:c_lfb,edi
    mov cx,ds:efi_width
    mov es:c_width,cx
    mov dx,ds:efi_height
    mov es:c_height,dx
    mov ebp,ds:efi_scan_size
    mov es:c_scan_size,ebp
    mov es:c_usage,1
    call CreateVideoBitmap
    mov ax,es
    pop es
    mov es:c_video_sel,ax
    mov es:c_video_handle,bx    
;
    mov eax,00070120h
    mov edi,OFFSET c_text_data
    movzx ecx,es:c_text_entries
    rep stosd
;
    call InitKeyboardConsole    
    call InitMouseConsole    
;    
    popad    
    pop ds
    ret
CreateConsoleEfi    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateConsoleBios
;
;   DESCRIPTION:    Create a new BIOS console with fixed font
;
;   RETURNS:        ES      Console sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateConsoleBios  PROC near
    push ds
    pushad
;
    mov eax,25 * 80
    mov ebp,eax
    shl eax,2
    add eax,OFFSET c_text_data
    AllocateBigLinear
    AllocateGdt
    mov ecx,eax
    CreateDataSelector32
    mov es,bx
    mov es:c_text_entries,bp
;
    mov es:c_flags,0
    mov es:c_con_row,0
    mov es:c_con_col,0
    mov es:c_curr_row,0
    mov es:c_curr_col,0
    mov es:c_prev_row,0
    mov es:c_prev_col,0
    mov es:c_font,0
    mov es:c_video_handle,0
    mov es:c_video_sel,0
    mov es:c_font_width,0
    mov es:c_font_height,0
;    
    mov es:c_width,0
    mov es:c_height,0
    mov es:c_usage,1
;
    mov cx,80
    mov es:c_cols,cx
    mov dx,25
    mov es:c_rows,dx
    mov edi,0B8000h    
    push es
    call CreateTextBitmap
    mov ax,es
    pop es
    mov es:c_video_sel,ax
    mov es:c_video_handle,0
    mov es:c_video_mode,3
;
    mov eax,00070120h
    mov edi,OFFSET c_text_data
    movzx ecx,es:c_text_entries
    rep stosd
;
    call InitKeyboardConsole    
    call InitMouseConsole    
;    
    popad    
    pop ds
    ret
CreateConsoleBios    Endp
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteBitmap
;
;           DESCRIPTION:    Write char to video bitmap
;
;           PARAMETERS:     ES    Flat sel
;                           FS    Console
;                           AL    Char
;                           BL    Fore color
;                           BH    Back color
;                           CX    Col
;                           DX    Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteBitmap     PROC near
    push gs
    pushad
;    
    movzx esi,bl
    and esi,0Fh
    shl esi,2
    mov ebp,dword ptr cs:[esi].AttribBgrTab    ; fore color
;    
    movzx esi,bh
    and esi,0Fh
    shl esi,2
    mov esi,dword ptr cs:[esi].AttribBgrTab    ; back color
;    
    push ax
    push cx
    mov ax,fs:c_video_sel
    mov gs,ax
    mov ax,dx
    mov cx,19
    mul cx
    movzx eax,ax
;    
    mov edx,fs:c_scan_size
    mul edx
    mov edi,gs:v_app_base    
    add edi,eax
    pop cx
;    
    movzx eax,cx
    shl eax,5
    add edi,eax
;
    pop ax
;
    mov ah,19
    mul ah
    movzx ebx,ax
    add ebx,OFFSET font8x19
;
    mov ecx,19

wbRowLoop:    
    push ecx
    push edi
    mov ecx,8
    mov al,cs:[ebx]

wbLoop:
    test al,80h
    jz wbBack

wbFore:
    mov es:[edi],ebp
    jmp wbNext

wbBack:
    mov es:[edi],esi

wbNext:
    add edi,4
    shl al,1
;
    loop wbLoop    
;
    pop edi
    pop ecx
    add edi,fs:c_scan_size
    inc ebx
;
    loop wbRowLoop    

wbDone:    
    popad        
    pop gs
    ret
WriteBitmap    Endp
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RedrawRow
;
;           DESCRIPTION:    Redraw row to physical display
;
;           PARAMETERS:     DS    Video sel
;                           ES    Flat sel
;                           FS    Console
;                           DX    Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RedrawRow     PROC near
    pushad
;
    push dx
    mov ax,fs:c_cols
    mul dx
    movzx edi,ax
    shl edi,2
    add edi,OFFSET c_text_data
    pop dx
;
    xor cx,cx

rrLoop:
    mov al,fs:[edi].ct_char
    mov bl,fs:[edi].ct_fore_col
    mov bh,fs:[edi].ct_back_col    
    mov fs:[edi].ct_dirty,0
    call fword ptr ds:v_write_text_proc
;
    add edi,4    
    inc cx
    cmp cx,fs:c_cols
    jc rrLoop
;            
    popad
    ret
RedrawRow     ENDP
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RedrawConsole
;
;           DESCRIPTION:    Redraw console to physical display
;
;           PARAMETERS:     DS    Video sel
;                           ES    Flat sel
;                           FS    Console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RedrawConsole     PROC near
    push dx
;
    xor dx,dx

rcLoop:
    call RedrawRow
    inc dx
    cmp dx,fs:c_rows
    jc rcLoop
;
    pop dx
    ret
RedrawConsole     ENDP
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RedrawVideo
;
;           DESCRIPTION:    Redraw video to physical display
;
;           PARAMETERS:     DS    Video sel
;                           ES    Flat sel
;                           FS    Console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RedrawVideo     PROC near
    pushad
;    
    mov esi,ds:v_app_base
    mov edi,fs:c_lfb
    mov eax,fs:c_scan_size
    movzx edx,fs:c_height
    mul edx
    mov ecx,eax
    shr ecx,2
    rep movs dword ptr es:[edi],es:[esi]
;
    popad    
    ret
RedrawVideo     ENDP
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyRow
;
;           DESCRIPTION:    Copy a row
;
;           PARAMETERS:     ES    Flat sel
;                           FS    Console
;                           SI    Source row
;                           DI    Dest row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyRow     PROC near
    pushad
;
    push di
    mov ax,fs:c_cols
    mul si
    movzx esi,ax
    shl esi,2
    add esi,OFFSET c_text_data
;
    mov ax,fs:c_cols
    mul di
    movzx edi,ax
    shl edi,2
    add edi,OFFSET c_text_data
;
    pop dx
    xor cx,cx

cpyLoop:
    mov al,fs:[esi].ct_char
    mov bl,fs:[esi].ct_fore_col
    mov bh,fs:[esi].ct_back_col    
;
    mov fs:[edi].ct_char,al
    mov fs:[edi].ct_fore_col,bl
    mov fs:[edi].ct_back_col,bh
    mov fs:[edi].ct_dirty,1
;
    add esi,4
    add edi,4    
    inc cx
    cmp cx,fs:c_cols
    jc cpyLoop
;            
    popad
    ret
CopyRow     ENDP
           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearRow
;
;           DESCRIPTION:    Clear a row
;
;           PARAMETERS:     ES    Flat sel
;                           FS    Console
;                           DX    Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearRow     PROC near
    pushad
;
    push dx
    mov ax,fs:c_cols
    mul dx
    movzx edi,ax
    shl edi,2
    add edi,OFFSET c_text_data
    pop dx
;
    xor cx,cx
    mov al,' '
    mov bl,7
    mov bh,0

clrLoop:
    mov fs:[edi].ct_char,al
    mov fs:[edi].ct_fore_col,bl
    mov fs:[edi].ct_back_col,bh
    mov fs:[edi].ct_dirty,1
;
    add edi,4    
    inc cx
    cmp cx,fs:c_cols
    jc clrLoop
;            
    popad
    ret
ClearRow     ENDP
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ScrollBitmap
;
;           DESCRIPTION:    Scroll bitmap one row
;
;           PARAMETERS:     ES    Flat sel
;                           FS    Console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ScrollBitmap     PROC near
    push ds
    pushad
;
    mov ax,fs:c_video_sel
    mov ds,ax
;
    mov edi,ds:v_app_base
    mov eax,fs:c_scan_size
    mov edx,19
    mul edx
    mov esi,edi
    add esi,eax
;
    push eax
    movzx edx,fs:c_rows
    dec edx
    mul edx
    mov ecx,eax
    shr ecx,2
    rep movs dword ptr es:[edi],es:[esi]
    pop ecx
;    
    shr ecx,2
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    popad
    pop ds
    ret
ScrollBitmap     ENDP
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteConsole
;
;           DESCRIPTION:    Write char to buffer
;
;           PARAMETERS:     DS    Thread sel
;                           ES    Flat sel
;                           FS    Console
;                           AL    Char
;                           BL    Fore color
;                           BH    Back color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteConsole     PROC near
    push edi
    push eax
    push edx
;    
    push ax
    mov dx,ds:p_row
    mov ax,fs:c_cols
    mul dx
    add ax,ds:p_col
    movzx edi,ax
    shl edi,2
    add edi,OFFSET c_text_data
    mov ax,bx
    shl eax,16
    pop ax
    mov ah,1
    mov fs:[edi],eax
;
    pop edx
    pop eax
;    
    test fs:c_flags,CONSOLE_FLAG_BITMAP
    jz wcText

wcBitmap:
    push cx
    push dx
;    
    mov fs:[edi].ct_dirty,0
    mov cx,ds:p_col
    mov dx,ds:p_row
    call WriteBitmap
;
    pop dx
    pop cx
;    
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz wcDone
;
    push cx
    push dx
;    
    push ds
    mov fs:[edi].ct_dirty,0
    mov cx,ds:p_col
    mov dx,ds:p_row
    mov ds,fs:c_video_sel
    call fword ptr ds:v_write_text_proc
    pop ds
;
    pop dx
    pop cx
    jmp wcDone

wcText:
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz wcDone
;    
    lock or fs:c_flags,CONSOLE_FLAG_NEW_WRITES
    test fs:c_flags,CONSOLE_FLAG_TEXT_BUFFER
    jnz wcDone
;
    push cx
    push dx
;    
    push ds
    mov fs:[edi].ct_dirty,0
    mov cx,ds:p_col
    mov dx,ds:p_row
    mov ds,fs:c_video_sel
    call fword ptr ds:v_write_text_proc
    pop ds
;    
    pop dx
    pop cx

wcDone:    
    inc ds:p_col
;
    pop edi
    ret
WriteConsole    Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UpdateRow
;
;           DESCRIPTION:    Update row to physical display
;
;           PARAMETERS:     DS    Video sel
;                           ES    Flat sel
;                           FS    Console
;                           DX    Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateRow     PROC near
    pushad
;
    push dx
    mov ax,fs:c_cols
    mul dx
    movzx edi,ax
    shl edi,2
    add edi,OFFSET c_text_data
    pop dx
;
    xor cx,cx

urLoop:
    test fs:[edi].ct_dirty,1
    jz urNext
;
    lock or fs:c_flags,CONSOLE_FLAG_NEW_WRITES    
;
    mov al,fs:[edi].ct_char
    mov bl,fs:[edi].ct_fore_col
    mov bh,fs:[edi].ct_back_col    
    mov fs:[edi].ct_dirty,0
    call fword ptr ds:v_write_text_proc

urNext:
    add edi,4    
    inc cx
    cmp cx,fs:c_cols
    jc urLoop
;            
    popad
    ret
UpdateRow     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           UpdateThread
;
;   DESCRIPTION:    Update thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_thread_name  DB 'Video Sync', 0

update_thread_pr:

utLoop:    
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:update_thread,ax
;    
    mov ax,flat_sel
    mov es,ax
    mov ax,ds:focus_console
    or ax,ax
    jz utNext
;    
    mov fs,ax
    mov ds,fs:c_video_sel
    test fs:c_flags,CONSOLE_FLAG_TEXT_BUFFER
    jz utMarker
;
    xor dx,dx
    lock and fs:c_flags,NOT CONSOLE_FLAG_NEW_WRITES

utRedrawLoop:
    call UpdateRow
    inc dx
    cmp dx,fs:c_rows
    jc utRedrawLoop
;
    test fs:c_flags,CONSOLE_FLAG_NEW_WRITES
    jnz utNext
;
    lock and fs:c_flags,NOT CONSOLE_FLAG_TEXT_BUFFER
    
utMarker:    
    mov cx,fs:c_curr_col
    mov dx,fs:c_curr_row
    cmp cx,fs:c_prev_col
    jnz utSave
;
    cmp dx,fs:c_prev_row
    jnz utSave

utUpdate:    
    test fs:c_flags,CONSOLE_FLAG_BITMAP
    jnz utNext
;    
    call IsMarkerVisible
    jnc utNext
;    
    call fword ptr ds:v_toggle_marker_proc
    jmp utNext

utSave:
    xchg cx,fs:c_prev_col
    xchg dx,fs:c_prev_row
;
    push dx
    mov ax,fs:c_cols
    mul dx
    mov di,ax
    pop dx
;
    add di,cx
    movzx edi,di
    shl edi,2
    add edi,OFFSET c_text_data
;
    mov al,fs:[edi].ct_char
    mov bl,fs:[edi].ct_fore_col
    mov bh,fs:[edi].ct_back_col    
    mov fs:[edi].ct_dirty,0
    call fword ptr ds:v_write_text_proc

utNext:
    GetSystemTime
    add eax,1193 * 200
    adc edx,0
    WaitForSignalWithTimeout
    jmp utLoop
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateConsole
;
;   DESCRIPTION:    Create a new console
;
;   RETURNS:        BX		Console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_console_name DB 'Create Console', 0
    
create_console  PROC far
    push ds
    push es
    push eax
;    
    mov ax,SEG data
    mov ds,ax

ccRetry:
    mov ax,ds:flags
    test ax,FLAG_GET_MODES
    jz ccDo
;
    mov ax,100
    WaitMilliSec
    jmp ccRetry
    
ccDo:    
    mov ax,system_data_sel
    mov ds,ax    
    mov eax,ds:efi_lfb
    or eax,eax
    jz ccText

ccVideo:
    call CreateConsoleEfi
    jmp ccDone

ccText:
    call CreateConsoleBios

ccDone:
    GetThread
    mov es:c_thread,ax
    mov bx,es
;
    pop eax
    pop es
    pop ds
    ret
create_console   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           DeleteConsole
;
;   DESCRIPTION:    Delete console
;
;   PARAMETERS:     ES      Console sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteConsole  PROC near
    FreeMem
    ret
DeleteConsole   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetFocusConsole
;
;           DESCRIPTION:    Get focus console
;
;           RETURNS:        BX          Console
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_focus_console_name DB 'Get Focus Console', 0

get_focus_console     PROC far
    push ds
;
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:focus_console
    or bx,bx
    clc
    jnz gfcDone
;
    stc 

gfcDone: 
    pop ds
    ret
get_focus_console     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetFocusThread
;
;           DESCRIPTION:    Get focus thread
;
;           RETURNS:        AX       Thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_focus_thread_name DB 'Get Focus Thread', 0

get_focus_thread     PROC far
    push ds
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:focus_console
    or ax,ax
    jz gftFail
;
    mov ds,ax
    mov ax,ds:c_thread
    clc
    jmp gftDone

gftFail:
    stc 

gftDone: 
    pop ds
    ret
get_focus_thread     ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           SetFocusConsole
;
;   DESCRIPTION:    Set console focus
;
;   PARAMETERS:     BX      Console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_focus_console_name DB 'Set Focus Console', 0

set_focus_console Proc far
    push ds
    push es
    push fs
    push ax
    push bx
;
    mov ax,SEG data
    mov ds,ax
    mov fs,bx
;
    xor ax,ax
    xchg ax,ds:focus_console
    or ax,ax
    jz scfEnable
;
    mov ds,ax
    lock and ds:c_flags,NOT (CONSOLE_FLAG_ACTIVE OR CONSOLE_FLAG_TEXT_BUFFER OR CONSOLE_FLAG_NEW_WRITES)
;    
    test ds:c_flags,CONSOLE_FLAG_BITMAP
    jz scfEnable
;
    mov ax,ds:c_video_sel
    mov ds,ax
    mov ds:v_has_focus,0    
        
scfEnable:
    mov ax,SEG data
    mov ds,ax
;
    mov ax,fs:c_video_mode
    cmp ax,ds:curr_video_mode
    je scfModeOk
;
    mov ds:curr_video_mode,ax
    push bx
    mov bx,ax
    SwitchVideoMode
    pop bx

scfModeOk:
    lock or fs:c_flags,CONSOLE_FLAG_ACTIVE
    mov ds:focus_console,bx
;
    test fs:c_flags,CONSOLE_FLAG_BITMAP
    jz scfRedraw
;
    mov ds,fs:c_video_sel
    mov ds:v_has_focus,1
    mov ax,flat_sel
    mov es,ax
    call RedrawVideo
    jmp scfDone

scfRedraw:
    mov ax,flat_sel
    mov es,ax
    mov ds,fs:c_video_sel
    call RedrawConsole    
;
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz scfDone
;
    push cx
    push dx
    mov dx,fs:c_curr_row
    mov cx,fs:c_curr_col
    call fword ptr ds:v_update_cursor_pos_proc
    pop dx
    pop cx
        
scfDone:
    pop bx
    pop ax
    pop fs
    pop es
    pop ds    
    ret
set_focus_console Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetLocalConsole
;
;           DESCRIPTION:    Get local console
;
;           RETURNS:        DS          Console
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetLocalConsole

GetLocalConsole     PROC near
    push ax
;
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    mov ds,ax
    or ax,ax
    clc
    jnz glcDone
;
    stc 

glcDone: 
    pop ax
    ret
GetLocalConsole     ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FindMode
;
;           DESCRIPTION:    Find a video mode
;
;           PARAMETERS:     AX      mode #
;
;           RETURNS:        ES      Video sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindMode  PROC near
    push ds
    push bx
;    
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:video_mode_list

fmLoop:
    or bx,bx
    jz fmFail
;
    mov es,bx
;
    cmp ax,es:vm_mode_nr
    je fmOk
;
    mov bx,es:vm_next
    jmp fmLoop

fmOk:
    clc
    jmp fmDone

fmFail:
    stc

fmDone:
    pop bx
    pop ds
    ret
FindMode    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           QueryVideoMode
;
;           DESCRIPTION:    Query video mode
;
;           PARAMETERS:     AX      mode # or 0    
;
;           RETURNS:        AX          bits / pixel
;                           CX          x-resolution
;                           DX          y-resolution
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

query_video_mode_name     DB 'Query Video Mode',0

query_video_mode  PROC far
    push es
;    
    call FindMode
    jc qvmDone
;    
    movzx ax,es:vm_bits
    mov cx,es:vm_y_size
    mov dx,es:vm_x_size

qvmDone:
    pop es
    ret
query_video_mode    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetVideoMode
;
;           DESCRIPTION:    Get video mode
;
;           PARAMETERS:         AX          bits / pixel
;                           CX          x-resolution
;                           DX          y-resolution
;
;       RETURNS:    AX      mode # or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_video_mode_name     DB 'Get Video Mode',0

get_video_mode  Proc far
    push ds
    push es
    push bx
    push si
    push di
;
    mov bx,system_data_sel
    mov ds,bx    
    mov ebx,ds:efi_lfb
    or ebx,ebx
    jz get_video_bios
;
    mov ax,1
    jmp get_video_leave

get_video_bios:
    mov si,cx
    add si,dx
    xor di,di
    xor ah,ah
;
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:video_mode_list

get_video_loop:
    or bx,bx
    jz get_video_done
;
    mov es,bx
;
    mov bl,es:vm_bits
    or bl,bl
    jz get_video_next
;
    push ax
    mov ax,cx
    sub ax,es:vm_x_size
    jnc get_video_x_ok
;
    neg ax

get_video_x_ok:
    mov bx,ax
;
    mov ax,dx
    sub ax,es:vm_y_size
    jnc get_video_y_ok
;
    neg ax 

get_video_y_ok:
    add bx,ax
    pop ax
;
    cmp bx,si
    ja get_video_next
    jne get_video_select
;
    cmp al,ah
    je get_video_next
    jb get_video_want_smaller

get_video_want_larger:
    cmp ah,es:vm_bits
    jc get_video_select
    jmp get_video_next

get_video_want_smaller:
    cmp ah,es:vm_bits
    jc get_video_next
;
    cmp al,es:vm_bits
    jbe get_video_select
    jmp get_video_next

get_video_select:
    mov ah,es:vm_bits
    mov si,bx
    mov di,es

get_video_next:
    mov bx,es:vm_next
    or bx,bx
    jnz get_video_loop

get_video_done:
    xor ax,ax
    or di,di
    jz get_video_leave
;
    mov es,di
    mov ax,es:vm_mode_nr

get_video_leave:
    pop di
    pop si
    pop bx
    pop es    
    pop ds
    ret
get_video_mode  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetVideoMode
;
;           DESCRIPTION:    Set video mode
;
;           PARAMETERS:     AX          Mode (3 = text, 1 = video)
;
;           RETURNS:        AX          bits / pixel
;                           BX          bitmap handle
;                           CX          x-resolution
;                           DX          y-resolution
;                           SI          line size
;                           ES:EDI  user buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_video_mode_name     DB 'Set Video Mode',0

set_video_mode  PROC far
    push ds
    push fs
;
    push ax
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    mov fs,ax    
    or ax,ax
    pop ax
    jz svmDone
;
    cmp ax,1
    je svmFixedVideo
;
    mov bx,system_data_sel
    mov ds,bx    
    mov ebx,ds:efi_lfb
    or ebx,ebx
    jnz svmFixedText
;
    cmp ax,fs:c_video_mode
    je svmDone
;    
    mov bx,fs:c_video_handle
    or bx,bx
    jz svmFreeText

svmFreeLfb:
    mov es,fs:c_video_sel
    call FreeVideoBuffer
;    
    xor ax,ax
    mov es,ax
    CloseBitmap
    jmp svmFreeOk

svmFreeText:
    mov es,fs:c_video_sel
    FreeMem

svmFreeOk:    
    mov fs:c_video_sel,0
    mov fs:c_video_handle,0
;    
    cmp ax,3
    jne svmVideo

svmText:
    lock and fs:c_flags,NOT CONSOLE_FLAG_BITMAP
;    
    mov cx,fs:c_cols
    mov dx,fs:c_rows
    mov edi,0B8000h    
    call CreateTextBitmap
    mov fs:c_video_sel,es
    mov fs:c_video_handle,0
    mov fs:c_video_mode,3
;
    xor ax,ax
    xor cx,cx
    xor dx,dx
    xor si,si
    xor edi,edi
;    
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz svmDone
;
    mov es:v_has_focus,1
    mov bx,fs:c_video_mode
    SwitchVideoMode
;    
    mov ax,SEG data
    mov ds,ax
    mov ds:curr_video_mode,bx
    jmp svmDone
    
svmVideo:
    call FindMode
    jc svmText
;    
    mov fs:c_video_mode,ax
;
    movzx edx,es:vm_line_size
    movzx eax,es:vm_y_size
    mul edx
    AllocateBigLinear
    mov edi,edx
;
    mov eax,es:vm_lfb
    xor ebx,ebx
    mov al,0Bh

svmPageLoop:
    SetPageEntry
    add edx,1000h
    add eax,1000h
    loop svmPageLoop
;    
    mov fs:c_lfb,edi    
    mov al,es:vm_bits
    mov cx,es:vm_x_size
    mov fs:c_width,cx
    mov dx,es:vm_y_size
    mov fs:c_height,dx
    movzx ebp,es:vm_line_size
    mov fs:c_scan_size,ebp
    mov fs:c_usage,1
    call CreateVideoBitmap
    call AllocateVideoBuffer
    mov fs:c_video_sel,es
    mov fs:c_video_handle,bx
    lock or fs:c_flags,CONSOLE_FLAG_BITMAP

svmSetMode:
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz svmFocusOk
;    
    mov es:v_has_focus,1
    mov bx,fs:c_video_mode
    SwitchVideoMode
;    
    mov ax,SEG data
    mov ds,ax
    mov ds:curr_video_mode,bx
;
    mov ecx,es:v_app_size
    shr ecx,2
    mov edi,es:v_phys_base
;
    push es    
    mov ax,flat_sel
    mov es,ax
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop es
    jmp svmFocusOk

svmFixedText:
    lock and fs:c_flags,NOT CONSOLE_FLAG_BITMAP
    mov es,fs:c_video_sel
    call FreeVideoBuffer
    jmp svmDone
    
svmFixedVideo:
    lock or fs:c_flags,CONSOLE_FLAG_BITMAP
    mov es,fs:c_video_sel
    call AllocateVideoBuffer
;
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz svmFocusOk
;    
    mov es:v_has_focus,1

svmFocusOk:   
    movzx ax,es:v_bpp
    mov cx,es:v_width
    mov dx,es:v_height
    mov si,es:v_row_size
    mov edi,es:v_app_base
;
    mov bx,system_data_sel
    mov ds,bx
    sub edi,ds:flat_base
    mov bx,flat_data_sel
    mov es,bx
    mov bx,fs:c_video_handle
    SetMouseLimit
    
svmDone:
    pop fs
    pop ds    
    ret
set_video_mode  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           BeginGetVideoModes
;
;           DESCRIPTION:    Begin to get video modes
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin_get_video_modes_name       DB 'Begin Get Video Modes',0

begin_get_video_modes  PROC far
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    lock or ds:flags,FLAG_GET_MODES
    pop ax
    pop ds
    ret
begin_get_video_modes  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddVideoMode
;
;           DESCRIPTION:    Add video mode
;
;           PARAMETERS:     AX      bits / pixel
;                           BX      Mode nr
;                           CX      x-resolution
;                           DX      y-resolution
;                           SI      line size
;                           EDI     LFB
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_video_mode_name       DB 'Add Video Mode',0

add_video_mode  PROC far
    push ds
    push es
    push bp
;
    mov bp,SEG data
    mov ds,bp
    mov bp,ds:disp_fixed
    or bp,bp
    jnz avFixed

avAdd:
    push eax
    mov eax,SIZE video_mode_struc
    AllocateSmallGlobalMem
    pop eax
;
    mov es:vm_bits,al
    mov es:vm_mode_nr,bx
    mov es:vm_x_size,cx
    mov es:vm_y_size,dx
    mov es:vm_line_size,si
    mov es:vm_lfb,edi
;    
    push ax
    mov ax,ds:video_mode_list
    mov es:vm_next,ax
    mov ds:video_mode_list,es
    pop ax
    jmp avDone

avFixed:
    cmp ax,32
    jne avDone
;    
    mov ax,system_data_sel
    mov ds,ax
    cmp bp,1
    je avHighest

avPart:
    cmp bp,cx
    je avSet
;
    mov eax,ds:efi_lfb
    or eax,ds:efi_lfb+4
    jz avSet
;    
    cmp bp,ds:efi_width
    je avDone
    jmp avCmp

avHighest:
    mov eax,ds:efi_lfb
    or eax,ds:efi_lfb+4
    jz avSet

avCmp:
    cmp cx,ds:efi_width
    jc avDone

avSet:
    mov ds:efi_lfb,edi
    mov ds:efi_lfb+4,0
    mov ds:efi_width,cx
    mov ds:efi_height,dx
    movzx esi,si
    mov ds:efi_scan_size,esi
;
    mov ax,SEG data
    mov ds,ax
    mov ds:fixed_mode,bx

avDone:
    pop bp
    pop es
    pop ds    
    ret
add_video_mode  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           EndGetVideoModes
;
;           DESCRIPTION:    End to get video modes
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

end_get_video_modes_name       DB 'End Get Video Modes',0

end_get_video_modes  PROC far
    push ds
    push es
    pushad
;    
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:disp_fixed
    or ax,ax
    jz egvDone
;   
    mov ax,system_data_sel
    mov es,ax
    mov edx,es:efi_scan_size
    movzx eax,es:efi_height
    mul edx
    AllocateBigLinear
;
    mov eax,es:efi_lfb
    mov ebx,es:efi_lfb+4
    mov al,0Bh
    mov es:efi_lfb,edx

egvMoveLoop:
    SetPageEntry
    add edx,1000h
    add eax,1000h
    loop egvMoveLoop
;
    mov bx,ds:fixed_mode
    SwitchVideoMode 

egvDone:    
    lock and ds:flags,NOT FLAG_GET_MODES
    popad
    pop es
    pop ds
    ret
end_get_video_modes  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InvertMouse
;
;           DESCRIPTION:    Invert colors for mouse-pointer
;
;           PARAMETERS:     CX          COL (x)
;                           DX          ROW (y)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

invert_mouse_name       DB 'InvertMouse',0

invert_mouse    PROC far
    push ds
    push es
    push fs
    pushad
;
    mov ax,flat_sel
    mov es,ax
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    mov fs,ax    
    or ax,ax
    jz imDone
;
    mov ds,fs:c_video_sel
    push dx
    mov ax,fs:c_cols
    mul dx
    add ax,cx
    movzx edi,ax
    shl edi,2
    add edi,OFFSET c_text_data
    mov al,fs:[edi].ct_fore_col
    xchg al,fs:[edi].ct_back_col
    mov fs:[edi].ct_fore_col,al
    pop dx
;
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz imDone
;    
    mov al,fs:[edi].ct_char
    mov bl,fs:[edi].ct_fore_col
    mov bh,fs:[edi].ct_back_col    
    call fword ptr ds:v_write_text_proc

imDone:
    popad
    pop fs
    pop es
    pop ds
    ret
invert_mouse    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UpdatePos
;
;           DESCRIPTION:    Update cursor position
;
;           PARAMETERS:     DS    Thread sel
;                           FS    Console sel
;                           AL    Char
;                           BL    Fore color
;                           BH    Back color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePos       Proc near
    push ax
;    
    mov ax,fs:c_cols
    dec ax
    cmp ds:p_col,-1
    jne upNotRowWrap
;
    mov ds:p_col,ax

upNotRowWrap:
    cmp ds:p_col,ax
    jbe upSameRow
;
    mov ds:p_col,0
    inc ds:p_row

upSameRow:
    mov ax,fs:c_rows
    cmp ds:p_row,ax
    jc upUpdate
;
    push dx
    push si
    push di
;    
    dec ds:p_row
    mov si,1
    mov di,0

upScrollLoop:
    call CopyRow
;
    inc si
    inc di
    cmp si,fs:c_rows
    jc upScrollLoop 
;
    mov dx,di
    call ClearRow
;
    test fs:c_flags,CONSOLE_FLAG_BITMAP
    jz upText

upBitmap:
    call ScrollBitmap
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz upScrollDone
;
    push ds
    mov ds,fs:c_video_sel
    call RedrawVideo    
    pop ds
    jmp upScrollDone

upText:
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz upScrollDone
;
    lock or fs:c_flags,CONSOLE_FLAG_TEXT_BUFFER OR CONSOLE_FLAG_NEW_WRITES
;
    push ds
    push bx
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:update_thread
    Signal
    pop bx
    pop ds

upScrollDone:
    pop di
    pop si
    pop dx    

upUpdate:
    mov ax,ds:p_row
    mov fs:c_curr_row,ax
    mov ax,ds:p_col
    mov fs:c_curr_col,ax
;
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz upDone

;    
    push ds    
    push cx
    push dx
;
    mov dx,fs:c_curr_row
    mov cx,fs:c_curr_col
    mov ds,fs:c_video_sel
    call fword ptr ds:v_update_cursor_pos_proc
;
    pop dx
    pop cx
    pop ds

upDone:
    pop ax
    ret
UpdatePos       ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteSkip
;
;           DESCRIPTION:    Write NUL char
;
;           PARAMETERS:     DS    Thread sel
;                           ES    Flat sel
;                           FS    Console sel
;                           AL    Char
;                           BL    Fore color
;                           BH    Back color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSkip       PROC near
    push ax
    mov al,' '
    call WriteConsole
    pop ax
    ret
WriteSkip       ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteTab
;
;           DESCRIPTION:    Write TAB char
;
;           PARAMETERS:     DS    Thread sel
;                           ES    Flat sel
;                           FS    Console
;                           AL    Char
;                           BL    Fore color
;                           BH    Back color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteTab    PROC near
    push ax
    mov al,' '

write_tab_more:
    call WriteConsole
    test ds:p_col,3
    jnz write_tab_more
;
    pop ax
    ret
WriteTab    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteDel
;
;           DESCRIPTION:    Write DEL char
;
;           PARAMETERS:     DS    Thread sel
;                           AL    Char
;                           BL    Fore color
;                           BH    Back color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDel    PROC near
    dec ds:p_col
    ret
WriteDel    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteLf
;
;           DESCRIPTION:    Write LF char
;
;           PARAMETERS:     DS    Thread sel
;                           FS    Console
;                           AL    Char
;                           BL    Fore color
;                           BH    Back color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteLf PROC near
    inc ds:p_row
    ret
WriteLf ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteCr
;
;           DESCRIPTION:    Write CR char
;
;           PARAMETERS:     DS    Thread sel
;                           FS    Console
;                           AL    Char
;                           BL    Fore color
;                           BH    Back color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCr PROC near
    mov ds:p_col,0
    ret
WriteCr ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteOne
;
;           DESCRIPTION:    Write one character to screen
;
;           PARAMETERS:     DS    Thread sel
;                           ES    Flat sel
;                           FS    Console
;                           AL    Char
;                           BL    Fore color
;                           BH    Back color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_tab:
wct00   DD OFFSET WriteSkip
wct01   DD OFFSET WriteConsole
wct02   DD OFFSET WriteConsole
wct03   DD OFFSET WriteConsole
wct04   DD OFFSET WriteConsole
wct05   DD OFFSET WriteConsole
wct06   DD OFFSET WriteConsole
wct07   DD OFFSET WriteConsole
wct08   DD OFFSET WriteDel
wct09   DD OFFSET WriteTab
wct0A   DD OFFSET WriteLf
wct0B   DD OFFSET WriteConsole
wct0C   DD OFFSET WriteConsole
wct0D   DD OFFSET WriteCr
wct0E   DD OFFSET WriteConsole
wct0F   DD OFFSET WriteConsole

WriteOne    PROC near
    push esi
    movzx esi,al
    cmp esi,0Fh
    jc write_char_doit
;
    mov esi,0Fh

write_char_doit:
    shl esi,2
    call dword ptr cs:[esi].write_tab
    call UpdatePos

write_ansi_done:
    pop esi
    ret
WriteOne    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetTextSize
;
;           DESCRIPTION:    Get rows and cols
;
;           RETURNS:        CX          Cols
;                           DX          Rows
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_text_size_name     DB 'Get Text Size',0

get_text_size     PROC far
    push ds
    push fs
    push ax
;
    mov cx,80
    mov dx,25
;
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    mov fs,ax    
    or ax,ax
    jz gtsDone
;
    mov cx,fs:c_cols
    mov dx,fs:c_rows

gtsDone:
    pop ax
    pop fs
    pop ds
    ret
get_text_size     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearText
;
;           DESCRIPTION:    Clear text screen
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_text_name     DB 'Clear Text',0

clear_text     PROC far
    push ds
    push es
    push fs
    push ax
    push bx
    push dx
;
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    mov fs,ax    
    or ax,ax
    jz ctDone
;
    xor dx,dx
    mov ax,flat_sel
    mov es,ax

ctLoop:
    call ClearRow
    inc dx
    cmp dx,fs:c_rows
    jc ctLoop
;
    mov ds:p_row,0
    mov ds:p_col,0    
;
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz ctDone
;
    test fs:c_flags,CONSOLE_FLAG_BITMAP
    jnz ctDone
;     
    lock or fs:c_flags,CONSOLE_FLAG_TEXT_BUFFER OR CONSOLE_FLAG_NEW_WRITES
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:update_thread
    Signal

ctDone:
    pop dx
    pop bx
    pop ax
    pop fs
    pop es
    pop ds
    ret
clear_text     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetCursorPosition
;
;           DESCRIPTION:    Set cursor position
;
;           PARAMETERS:         CX          COL (x)
;                           DX          ROW (y)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cursor_pos_name     DB 'Set Cursor Position',0

set_cursor_position     PROC far
    push ds
    push fs
    push ax
;
    GetThread
    mov ds,ax
    mov ds:p_row,dx
    mov ds:p_col,cx
;
    mov ax,ds:p_console
    mov fs,ax    
    or ax,ax
    jz scpDone
;
    mov fs:c_curr_row,dx
    mov fs:c_curr_col,cx

    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz scpDone
;
    mov ds,fs:c_video_sel
    call fword ptr ds:v_update_cursor_pos_proc

scpDone:
    pop ax
    pop fs
    pop ds
    ret
set_cursor_position     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetCursorPosition
;
;           DESCRIPTION:    Get cursor position
;
;           RETURNS:        CX          COL (x)
;                           DX          Row (y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cursor_pos_name     DB 'Get Cursor Position',0

get_cursor_position     PROC far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov dx,ds:p_row
    mov cx,ds:p_col
;
    pop ax
    pop ds
    ret
get_cursor_position     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetConsoleCursorPosition
;
;           DESCRIPTION:    Get console cursor position
;
;           RETURNS:        CX          COL (x)
;                           DX          Row (y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_console_cursor_pos_name     DB 'Get Console Cursor Position',0

get_console_cursor_position     PROC far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov dx,ds:p_row
    mov cx,ds:p_col
;    
    mov ax,ds:p_console
    mov ds,ax    
    or ax,ax
    jz gccpDone
;
    mov dx,ds:c_con_row
    mov cx,ds:c_con_col

gccpDone:
    pop ax
    pop ds
    ret
get_console_cursor_position     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetConsoleCursorPosition
;
;           DESCRIPTION:    Set console cursor position
;
;           PARAMETERS:     CX          COL (x)
;                           DX          ROW (y)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_console_cursor_pos_name     DB 'Set Console Cursor Position',0

set_console_cursor_position     PROC far
    push ds
    push fs
    push ax
;
    GetThread
    mov ds,ax
    mov ds:p_row,dx
    mov ds:p_col,cx
;
    mov ax,ds:p_console
    mov fs,ax    
    or ax,ax
    jz scpDone
;
    mov fs:c_con_row,dx
    mov fs:c_con_col,cx
    mov fs:c_curr_row,dx
    mov fs:c_curr_col,cx

    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz sccpDone
;
    mov ds,fs:c_video_sel
    call fword ptr ds:v_update_cursor_pos_proc

sccpDone:
    pop ax
    pop fs
    pop ds
    ret
set_console_cursor_position     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetForeColor
;
;           DESCRIPTION:    Set text mode fore color
;
;           PARAMETERS:         AL          Color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_forecolor_name      DB 'Set Fore Color',0

set_forecolor   PROC far
    push ds
    push ax
    push bx
;
    mov bl,al
    GetThread
    mov ds,ax    
    mov ds:p_forecolor,bl
;
    pop bx
    pop ax
    pop ds
    ret
set_forecolor   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetBackColor
;
;           DESCRIPTION:    Set text mode back color
;
;           PARAMETERS:         AL          Color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_backcolor_name      DB 'Set Back Color',0

set_backcolor   PROC far
    push ds
    push ax
    push bx
;
    mov bl,al
    GetThread
    mov ds,ax    
    mov ds:p_backcolor,bl
;
    pop bx
    pop ax
    pop ds
    ret
set_backcolor   ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetCharAttrib
;
;           DESCRIPTION:    Get char & attribute
;
;           PARAMETERS:         AL          Character
;                           BL          Back color
;                           BH          Fore color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_char_attrib_name    DB 'Get Character & Attribute',0

get_char_attrib PROC far
    int 3
    ret
get_char_attrib ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteChar
;
;           DESCRIPTION:    Write one character to screen
;
;           PARAMETERS:         AL          Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_char_name DB 'Write Char',0

write_char      PROC far
    push ds
    push es
    push fs
    push bx
;
    push ax
    mov ax,flat_sel
    mov es,ax
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    mov fs,ax    
    or ax,ax
    pop ax
    jz write_char_done
;
    mov bl,ds:p_forecolor
    mov bh,ds:p_backcolor
    HideMouse
    call WriteOne
    ShowMouse

write_char_done:
    pop bx
    pop fs
    pop es
    pop ds
    ret
write_char      ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteAsciiz
;
;           DESCRIPTION:    Write NULL terminated string
;
;           PARAMETERS:         ES:(E)DI    Null terminated string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_asciiz_name       DB 'Write Asciiz String',0

write_asciiz16  PROC far
    push ds
    push es
    push fs
    push gs
    push ax
    push bx
    push di
;
    mov ax,es
    mov gs,ax
    mov ax,flat_sel
    mov es,ax
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    or ax,ax
    jz write_asciiz_done16
;
    mov fs,ax    
    mov bl,ds:p_forecolor
    mov bh,ds:p_backcolor
    HideMouse

write_asciiz_loop16:
    mov al,gs:[di]
    inc edi
    or al,al
    jz write_asciiz_done16
;
    call WriteOne
    jmp write_asciiz_loop16

write_asciiz_done16:
    ShowMouse
;
    pop di
    pop bx
    pop ax
    pop gs
    pop fs
    pop es
    pop ds
    ret
write_asciiz16  ENDP

write_asciiz32  PROC far
    push ds
    push es
    push fs
    push gs
    push ax
    push bx
    push edi
;
    mov ax,es
    mov gs,ax
    mov ax,flat_sel
    mov es,ax
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    or ax,ax
    jz write_asciiz_done32
;
    mov fs,ax    
    mov bl,ds:p_forecolor
    mov bh,ds:p_backcolor
    HideMouse

write_asciiz_loop32:
    mov al,gs:[edi]
    inc edi
    or al,al
    jz write_asciiz_done32
;
    call WriteOne
    jmp write_asciiz_loop32

write_asciiz_done32:
    ShowMouse
;
    pop edi
    pop bx
    pop ax
    pop gs
    pop fs
    pop es
    pop ds
    ret
write_asciiz32  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteDosString
;
;           DESCRIPTION:    Write '$'-terminated string
;
;           PARAMETERS:         ES:EDI  Adress to string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_dos_string_name   DB 'Write Dos String',0

write_dos_string    PROC far
    int 3
    ret
write_dos_string    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteSizeString
;
;           DESCRIPTION:    Write a number of characters
;
;           PARAMETERS:         ES:(E)DI    String
;                           (E)CX       Number of characters            
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_size_string_name  DB 'Write Size String',0

write_size_string16     PROC far
    push ds
    push es
    push fs
    push gs
    push ax
    push bx
    push cx
    push di
;    
    HideMouse
    or cx,cx
    jz write_size_string_done16
;
    mov ax,es
    mov gs,ax
    mov ax,flat_sel
    mov es,ax
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    or ax,ax
    jz write_size_string_done16
;
    mov fs,ax    
    mov bl,ds:p_forecolor
    mov bh,ds:p_backcolor

write_size_string_loop16:
    mov al,gs:[di]
    inc di
    call WriteOne
    sub cx,1
    jnz write_size_string_loop16

write_size_string_done16:
    ShowMouse
;       
    pop di
    pop cx
    pop bx
    pop ax
    pop gs
    pop fs
    pop es
    pop ds
    ret
write_size_string16     ENDP

write_size_string32     PROC far
    push ds
    push es
    push fs
    push gs
    push ax
    push bx
    push ecx
    push edi
;    
    HideMouse
    or ecx,ecx
    jz write_size_string_done32
;
    mov ax,es
    mov gs,ax
    mov ax,flat_sel
    mov es,ax
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    or ax,ax
    jz write_size_string_done32
;
    mov fs,ax    
    mov bl,ds:p_forecolor
    mov bh,ds:p_backcolor

write_size_string_loop32:
    mov al,gs:[edi]
    inc edi
    call WriteOne
    sub ecx,1
    jnz write_size_string_loop32

write_size_string_done32:
    ShowMouse
;       
    pop edi
    pop ecx
    pop bx
    pop ax
    pop gs
    pop fs
    pop es
    pop ds
    ret
write_size_string32     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteAttributeString
;
;           DESCRIPTION:    Write a number of characters & attributes
;
;           PARAMETERS:     AX          Col
;                           DX          Row
;                           ES:(E)DI    String
;                           (E)CX       Number of characters            
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_attr_string_name  DB 'Write Attribute String',0

write_attr_string       Proc near
    push ds
    push es
    push fs
    push gs
    push eax
    push ebx
    push ecx
    push edi
;
    push ax
    mov ax,es
    mov gs,ax
    mov ax,flat_sel
    mov es,ax
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    mov fs,ax    
    pop ax
;
    push ds:p_row
    push ds:p_col
;    
    mov ds:p_row,dx
    mov ds:p_col,ax
    HideMouse
    or ecx,ecx
    jz write_attr_show

write_attr_loop:
    mov al,gs:[edi]
    mov bl,gs:[edi+1]
    mov bh,bl
    and bl,0Fh
    shr bh,4
    call WriteConsole        
    add edi,2
    loop write_attr_loop

write_attr_show:    
    pop ds:p_col
    pop ds:p_row
    ShowMouse

write_attr_done:
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    ret
write_attr_string       Endp

write_attr_string16     PROC far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call write_attr_string
;
    pop edi
    pop ecx        
    ret
write_attr_string16     ENDP

write_attr_string32     PROC far
    call write_attr_string
    ret
write_attr_string32     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetClipRect
;
;           DESCRIPTION:    Set clipping rectangle
;
;           PARAMETERS:         BX              Bitmap handle
;               CX      X min
;               DX      Y min
;               SI      X max
;               DI      Y max
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_clip_rect_name      DB 'Set Clip Rect',0

set_clip_rect   PROC far
    push ds
    push es
    push ebx
    push cx
    push dx
    push si
    push di
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_clip_rect_done
;
    mov es,[ebx].bm_sel
;
    test ch,80h
    jz set_clip_xmin_pos
;
    xor cx,cx

set_clip_xmin_pos:
    test dh,80h
    jz set_clip_ymin_pos
;
    xor dx,dx

set_clip_ymin_pos:
    test si,8000h
    jz set_clip_xmax_pos
;
    xor si,si

set_clip_xmax_pos:
    test di,8000h
    jz set_clip_ymax_pos
;
    xor di,di

set_clip_ymax_pos:
    cmp cx,si
    jc set_clip_x_ok
;
    xchg cx,si

set_clip_x_ok:
    cmp dx,di
    jc set_clip_y_ok
;
    xchg dx,di

set_clip_y_ok:
    cmp cx,es:v_width
    jc set_clip_xmin_noov
;
    mov cx,es:v_width
    dec cx

set_clip_xmin_noov:
    cmp dx,es:v_height
    jc set_clip_ymin_noov
;
    mov dx,es:v_height
    dec dx

set_clip_ymin_noov:
    cmp si,es:v_width
    jc set_clip_xmax_noov
;
    mov si,es:v_width
    dec si

set_clip_xmax_noov:
    cmp di,es:v_height
    jc set_clip_ymax_noov
;
    mov di,es:v_height
    dec di

set_clip_ymax_noov:
    mov [ebx].bm_x_min,cx
    mov [ebx].bm_y_min,dx
    mov [ebx].bm_x_max,si
    mov [ebx].bm_y_max,di
    
set_clip_rect_done:
    pop di
    pop si
    pop dx
    pop cx
    pop ebx
    pop es
    pop ds
    ret
set_clip_rect   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearClipRect
;
;           DESCRIPTION:    Clear clipping rectangle
;
;           PARAMETERS:         BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_clip_rect_name    DB 'Clear Clip Rect',0

clear_clip_rect PROC far
    push ds
    push es
    push ax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc clear_clip_rect_done
;
    mov es,[ebx].bm_sel
    mov [ebx].bm_x_min,0
    mov [ebx].bm_y_min,0
    mov ax,es:v_width
    dec ax
    mov [ebx].bm_x_max,ax
    mov ax,es:v_height
    dec ax
    mov [ebx].bm_y_max,ax
    clc
    
clear_clip_rect_done:
    pop ebx
    pop ax
    pop es
    pop ds
    ret
clear_clip_rect ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetDrawColor
;
;           DESCRIPTION:    Set draw color
;
;           PARAMETERS:         EAX             RGB color
;                           BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_draw_color_name     DB 'Set Draw Color',0

set_draw_color  PROC far
    push ds
    push eax
    push ebx
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_draw_color_done
;
    push ds
    mov ds,[ebx].bm_sel
    call fword ptr ds:v_translate_color_proc
    pop ds
    mov [ebx].bm_color,eax
    
set_draw_color_done:
    pop ebx
    pop eax
    pop ds
    ret
set_draw_color  ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetLgop
;
;           DESCRIPTION:    Set LGOP
;
;           PARAMETERS:         AX              LGOP
;                           BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_lgop_name   DB 'Set LGOP',0

set_lgop    PROC far
    cmp ax,13
    jbe set_lgop_ok
    mov ax,1

set_lgop_ok:
    push ds
    push ebx
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_lgop_done
;
    mov [ebx].bm_lgop,ax
    
set_lgop_done:
    pop ebx
    pop ds
    ret
set_lgop    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetHollowStyle
;
;           DESCRIPTION:    Set hollow style
;
;           PARAMETERS:         BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_hollow_style_name   DB 'Set Hollow Style',0

set_hollow_style    PROC far
    push ds
    push ebx
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_hollow_done
;
    mov [ebx].bm_style,STYLE_HOLLOW
    
set_hollow_done:
    pop ebx
    pop ds
    ret
set_hollow_style    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetFilledStyle
;
;           DESCRIPTION:    Set filled style
;
;           PARAMETERS:         BX              Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_filled_style_name   DB 'Set Filled Style',0

set_filled_style    PROC far
    push ds
    push ebx
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_filled_done
;
    mov [ebx].bm_style,STYLE_FILLED
    
set_filled_done:
    pop ebx
    pop ds
    ret
set_filled_style    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetFont
;
;           DESCRIPTION:    Set font
;
;           PARAMETERS:         BX              Bitmap handle
;                           AX              Font
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_font_name   DB 'Set Font',0

set_font    PROC far
    push ds
    push ebx
;
    push ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc set_font_done
;
    mov [ebx].bm_font,ax
    
set_font_done:
    pop ebx
    pop ds
    ret
set_font    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetPixel
;
;           DESCRIPTION:    Get pixel
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x
;                           DX          y
;
;           RETURNS:        EAX         RGB color
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_pixel_name  DB 'Get Pixel',0

get_pixel       PROC far
    push ds
    push ax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc get_pixel_fail
;
    mov ds,[ebx].bm_sel
    pop bx
    pop ax
    EnterSection ds:v_section
    call fword ptr ds:v_get_pixel_proc
    LeaveSection ds:v_section
    pop ds  
    ret

get_pixel_fail:
    pop ebx
    pop ax
    pop ds
    ret
get_pixel       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetPixel
;
;           DESCRIPTION:    Set pixel
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x
;                           DX          y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_pixel_name  DB 'Set Pixel',0

set_pixel       PROC far
    push ds
    push eax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc set_pixel_fail
;
    mov eax,[bx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_lgop
    mov ds:v_color,eax
    pop ebx
    pop eax
    call fword ptr ds:v_set_pixel_proc
    LeaveSection ds:v_section
    pop ds
    ret  

set_pixel_fail:
    pop ebx
    pop eax
    pop ds
    ret
set_pixel       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Blit
;
;           DESCRIPTION:    Blit
;
;           PARAMETERS:     AX          Source bitmap handle
;                           BX          Dest bitmap handle
;                           CX          Width
;                           DX          Height
;                           ESI         Source x + y << 16
;                           EDI         Dest x + y << 16
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

blit_name       DB 'Blit',0

blit_src_y          EQU -4
blit_src_x          EQU -6
blit_dest_y         EQU -8
blit_dest_x         EQU -10
blit_width          EQU -12
blit_height         EQU -14
blit_src_sel        EQU -16
blit_dest_sel       EQU -18

blit_pr PROC far
    push ebp
    mov ebp,esp
    sub esp,20
    push ds
    push es
    pushad
;
    mov [ebp].blit_src_x,esi
    mov [ebp].blit_dest_x,edi
;
    or cx,cx
    jz blit_done
;
    or dx,dx
    jz blit_done
;
    mov [ebp].blit_width,cx
    mov [ebp].blit_height,dx
;
    mov cx,bx
    push ax
    mov bx,ax
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc blit_failed
;
    mov dx,[ebx].bm_sel
    mov [ebp].blit_src_sel,dx
;
    push ax
    mov bx,cx
    mov ax,BITMAP_HANDLE
    DerefHandle
    pop ax
    jc blit_failed
;
    mov dx,[ebx].bm_sel
    mov [ebp].blit_dest_sel,dx
;
    push [ebx].bm_lgop
    push [ebx].bm_color
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
;
    mov ax,[ebp].blit_src_sel
    cmp ax,[ebp].blit_dest_sel
    je blit_same_bitmap
;
    jae blit_take_dest_first

blit_take_src_first:
    mov ds,[ebp].blit_src_sel
    EnterSection ds:v_section
;
    mov ds,[ebp].blit_dest_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_color
    pop ds:v_lgop
    jmp blit_entered

blit_take_dest_first:
    mov ds,[ebp].blit_dest_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_color
    pop ds:v_lgop
;
    mov ds,[ebp].blit_src_sel
    EnterSection ds:v_section
    
blit_entered:
    mov ds,[ebp].blit_src_sel
    mov al,ds:v_alpha
    cmp al,1
    je blit_alpha
;    
    mov al,ds:v_bpp
    cmp al,1
    je blit_check1
;
    mov ds,[ebp].blit_dest_sel
    cmp al,ds:v_bpp
    je blit_same_bpp
    jmp blit_diff_bpp

blit_check1:
    mov ds,[ebp].blit_dest_sel
    cmp al,ds:v_bpp
    jne blit1

blit_diff_bpp:
    movzx eax,word ptr [ebp].blit_width
    shl eax,2
    AllocateGlobalMem

blit_diff_loop:
    mov ds,[ebp].blit_src_sel
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    cmp dx,0
    jl blit_diff_next
;
    cmp dx,ds:v_height
    jge blit_diff_next
;
    mov di,cx
    add di,ax
    cmp di,ds:v_width
    jle blit_diff_get
;
    mov ax,ds:v_width
    sub ax,cx

blit_diff_get:
    xor edi,edi
    call fword ptr ds:v_get_rgb_row_proc
;
    mov ds,[ebp].blit_dest_sel
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    xor edi,edi
    call fword ptr ds:v_set_rgb_row_proc

blit_diff_next:
    inc word ptr [ebp].blit_src_y
    inc word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_diff_loop
;
    FreeMem 
    mov ds,[ebp].blit_dest_sel
    LeaveSection ds:v_section
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_same_bpp:
    mov ds,[ebp].blit_src_sel
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    call fword ptr ds:v_get_line_proc
;
    mov ds,[ebp].blit_dest_sel
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    call fword ptr ds:v_set_native_row_proc
;
    inc word ptr [ebp].blit_src_y
    inc word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_same_bpp
;
    mov ds,[ebp].blit_dest_sel
    LeaveSection ds:v_section
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_same_bitmap:
    mov ds,[ebp].blit_src_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_color
    pop ds:v_lgop
;
    mov dx,[ebp].blit_src_y
    cmp dx,[ebp].blit_dest_y
    je blit_same_line
    ja blit_forward

blit_reverse:
    mov ax,[ebp].blit_height
    dec ax
    add [ebp].blit_src_y,ax
    add [ebp].blit_dest_y,ax

blit_reverse_loop:
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    call fword ptr ds:v_get_line_proc
;
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    call fword ptr ds:v_set_native_row_proc
;
    dec word ptr [ebp].blit_src_y
    dec word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_reverse_loop
;
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_forward:
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    call fword ptr ds:v_get_line_proc
;
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    call fword ptr ds:v_set_native_row_proc
;
    inc word ptr [ebp].blit_src_y
    inc word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_forward
;
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_same_line:
    movzx eax,word ptr [ebp].blit_width
    shl eax,2
    AllocateGlobalMem

blit_same_line_loop:
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    xor edi,edi
    call fword ptr ds:v_get_native_row_proc
;
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    xor edi,edi
    call fword ptr ds:v_set_native_row_proc
;
    inc word ptr [ebp].blit_src_y
    inc word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_same_line_loop
;
    FreeMem
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_alpha:
    movzx eax,word ptr [ebp].blit_width
    shl eax,2
    AllocateGlobalMem

blit_alpha_loop:
    mov ds,[ebp].blit_src_sel
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_src_x
    mov dx,[ebp].blit_src_y
    cmp dx,0
    jl blit_alpha_next
;
    cmp dx,ds:v_height
    jge blit_alpha_next
;
    mov di,cx
    add di,ax
    cmp di,ds:v_width
    jle blit_alpha_get
;
    mov ax,ds:v_width
    sub ax,cx

blit_alpha_get:
    xor edi,edi
    call fword ptr ds:v_get_rgba_row_proc
;
    mov ds,[ebp].blit_dest_sel
    mov ax,[ebp].blit_width
    mov cx,[ebp].blit_dest_x
    mov dx,[ebp].blit_dest_y
    xor edi,edi
    call fword ptr ds:v_set_rgba_row_proc

blit_alpha_next:
    inc word ptr [ebp].blit_src_y
    inc word ptr [ebp].blit_dest_y
    sub word ptr [ebp].blit_height,1
    jnz blit_alpha_loop
;
    FreeMem 
    mov ds,[ebp].blit_dest_sel
    LeaveSection ds:v_section
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done



blit1:
    mov ds,[ebp].blit_src_sel
    mov ax,flat_sel
    mov es,ax
    mov edi,ds:v_app_base
    mov ax,ds:v_row_size
    mov ecx,[ebp].blit_src_x
    mov edx,[ebp].blit_dest_x
    mov si,[ebp].blit_width
    mov ds,[ebp].blit_dest_sel
    mov ebx,ds:v_color

blit1_line_loop:
    call fword ptr ds:v_draw_mask_line_proc
    add ecx,10000h
    add edx,10000h
    sub word ptr [ebp].blit_height,1
    jnz blit1_line_loop
;
    mov ds,[ebp].blit_dest_sel
    LeaveSection ds:v_section
    mov ds,[ebp].blit_src_sel
    LeaveSection ds:v_section
    clc
    jmp blit_done

blit_failed:
    stc

blit_done:
    popad
    pop es
    pop ds
    add esp,20
    pop ebp
    ret
blit_pr ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawMask
;
;           DESCRIPTION:    Draw a mask line
;
;           PARAMETERS:         AX          row size
;                           BX          Bitmap handle
;                           ECX         source x + y << 16
;                           EDX         dest x + y << 16
;                           ESI         width + height << 16
;                           ES:EDI  1-bit mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_mask_name  DB 'Draw Mask',0

draw_mask       PROC far
    push ecx
    push edx
    push esi
    push edi
;
    push ds
    push eax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_mask_fail
;
    mov eax,[ebx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_lgop
    mov ds:v_color,eax
    pop ebx
    pop eax

    movzx eax,ax

draw_mask_loop:
    ror esi,16
    or si,si
    jz draw_mask_leave
;
    ror esi,16
    call fword ptr ds:v_draw_mask_line_proc
    add ecx,10000h
    add edx,10000h
    sub esi,10000h
    jmp draw_mask_loop

draw_mask_leave:
    LeaveSection ds:v_section
    pop ds  
    jmp draw_mask_done

draw_mask_fail:
    pop ebx
    pop eax
    pop ds

draw_mask_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    ret
draw_mask       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawString
;
;           DESCRIPTION:    Draw a string
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x
;                           DX          y
;                           ES:EDI  string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_string_name    DB 'Draw String',0

draw_string16   PROC far
    push edi
    movzx edi,di
;
    push ds
    push eax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_string16_fail
;
    mov eax,[ebx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_font
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_font
    pop ds:v_lgop
    mov ds:v_color,eax
    pop ebx
    pop eax
    call fword ptr ds:v_draw_string_proc
    LeaveSection ds:v_section
    pop ds  
    jmp draw_string16_done

draw_string16_fail:
    pop ebx
    pop eax
    pop ds

draw_string16_done:
    pop edi
    ret
draw_string16   ENDP

draw_string32   PROC far
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push eax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_string32_fail
;
    mov eax,[bx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_font
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_font
    pop ds:v_lgop
    mov ds:v_color,eax
    pop ebx
    pop eax
    call fword ptr ds:v_draw_string_proc
    LeaveSection ds:v_section
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ret

draw_string32_fail:
    pop ebx
    pop eax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ret
draw_string32   ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawLine
;
;           DESCRIPTION:    Draw a line
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x1
;                           DX          y1
;                           SI          x2
;                           DI          y2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_line_name  DB 'Draw Line',0

draw_line       PROC far
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push eax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_line_fail
;
    mov eax,[bx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_lgop
    mov ds:v_color,eax
    pop ebx
    pop eax
    call fword ptr ds:v_draw_line_proc
    LeaveSection ds:v_section
    pop ds  

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ret

draw_line_fail:
    pop ebx
    pop eax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ret
draw_line       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawRect
;
;           DESCRIPTION:    Draw a rectangle
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x
;                           DX          y
;                           SI          w
;                           DI          b
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_rect_name  DB 'Draw Rect',0

draw_rect       PROC far
    push ds
    push ax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_rect_fail
;
    push [ebx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov al,[ebx].bm_style
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    mov ds:v_style,al
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_lgop
    pop ds:v_color
    pop ebx
    pop ax
    call fword ptr ds:v_draw_rect_proc
    LeaveSection ds:v_section
    pop ds  
    ret

draw_rect_fail:
    pop ebx
    pop ax
    pop ds
    ret
draw_rect       ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DrawEllipse
;
;           DESCRIPTION:    Draw a ellipse
;
;           PARAMETERS:         BX          Bitmap handle
;                           CX          x
;                           DX          y
;                           SI          w
;                           DI          b
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

draw_ellipse_name       DB 'Draw Ellipse',0

draw_ellipse    PROC far
    push ds
    push ax
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc draw_ellipse_fail
;
    push [ebx].bm_color
    push [ebx].bm_lgop
    push [ebx].bm_x_min
    push [ebx].bm_y_min
    push [ebx].bm_x_max
    push [ebx].bm_y_max
    mov al,[ebx].bm_style
    mov ds,[ebx].bm_sel
    EnterSection ds:v_section
    mov ds:v_style,al
    pop ds:v_y_max
    pop ds:v_x_max
    pop ds:v_y_min
    pop ds:v_x_min
    pop ds:v_lgop
    pop ds:v_color
    pop ebx
    pop ax
    call fword ptr ds:v_draw_ellipse_proc
    LeaveSection ds:v_section
    pop ds  
    ret

draw_ellipse_fail:
    pop ebx
    pop ax
    pop ds
    ret
draw_ellipse    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ExtractValidBitmapMask
;
;           DESCRIPTION:    Extract valid mask from bitmap
;
;           PARAMETERS:     BX          Bitmap handle
;
;           RETURNS:        AX          Mask bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extract_valid_bitmap_mask_name  DB 'Extract Valid Bitmap Mask',0

emask_width          EQU -4
emask_height         EQU -6
emask_src_sel        EQU -8
emask_dest_sel       EQU -10
emask_bitmap         EQU -12

extract_valid_bitmap_mask       PROC far
    push ebp
    mov ebp,esp
    sub esp,12
    push ds
    push es
    push ebx
    push ecx
    push edx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc extract_vmask_fail
;
    mov ds,[ebx].bm_sel
    call fword ptr ds:v_has_alpha_proc
    jc extract_vmask_fail
;
    mov [ebp].emask_src_sel,ds
;
    mov al,1
    mov cx,ds:v_width
    mov dx,ds:v_height
    CreateBitmap
    jc extract_vmask_fail
;
    mov [ebp].emask_bitmap,bx
    mov [ebp].emask_width,cx
    mov [ebp].emask_height,dx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc extract_vmask_fail
;
    mov ax,[ebx].bm_sel
    mov [ebp].emask_dest_sel,ax
;    
    xor dx,dx

extract_vy_loop:
    xor cx,cx

extract_vx_loop:
    mov ds,[ebp].emask_src_sel
    call fword ptr ds:v_get_alpha_proc
    mov ds,[ebp].emask_dest_sel
    cmp al,80h
    ja extract_vset
;
    mov ds:v_color,0
    jmp extract_vdo

extract_vset:
    mov ds:v_color,1

extract_vdo:    
    call fword ptr ds:v_set_pixel_proc    
;
    inc cx
    cmp cx,[ebp].emask_width
    jb extract_vx_loop
;
    inc dx
    cmp dx,[ebp].emask_height
    jb extract_vy_loop    
;        
    mov ax,[ebp].emask_bitmap
    clc

extract_vmask_fail:
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    add esp,12
    pop ebp
    ret
extract_valid_bitmap_mask       ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ExtractInvalidBitmapMask
;
;           DESCRIPTION:    Extract invalid mask from bitmap
;
;           PARAMETERS:     BX          Bitmap handle
;
;           RETURNS:        AX          Mask bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extract_invalid_bitmap_mask_name  DB 'Extract Invalid Bitmap Mask',0

extract_invalid_bitmap_mask       PROC far
    push ebp
    mov ebp,esp
    sub esp,12
    push ds
    push es
    push ebx
    push ecx
    push edx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc extract_ivmask_fail
;
    mov ds,[ebx].bm_sel
    call fword ptr ds:v_has_alpha_proc
    jc extract_ivmask_fail
;
    mov [ebp].emask_src_sel,ds
;
    mov al,1
    mov cx,ds:v_width
    mov dx,ds:v_height
    CreateBitmap
    jc extract_ivmask_fail
;
    mov [ebp].emask_bitmap,bx
    mov [ebp].emask_width,cx
    mov [ebp].emask_height,dx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc extract_ivmask_fail
;
    mov ax,[ebx].bm_sel
    mov [ebp].emask_dest_sel,ax
;    
    xor dx,dx

extract_ivy_loop:
    xor cx,cx

extract_ivx_loop:
    mov ds,[ebp].emask_src_sel
    call fword ptr ds:v_get_alpha_proc
    mov ds,[ebp].emask_dest_sel
    cmp al,80h
    ja extract_ivreset
;
    mov ds:v_color,1
    jmp extract_ivdo

extract_ivreset:
    mov ds:v_color,0

extract_ivdo:    
    call fword ptr ds:v_set_pixel_proc    
;
    inc cx
    cmp cx,[ebp].emask_width
    jb extract_ivx_loop
;
    inc dx
    cmp dx,[ebp].emask_height
    jb extract_ivy_loop    
;        
    mov ax,[ebp].emask_bitmap
    clc

extract_ivmask_fail:
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    add esp,12
    pop ebp
    ret
extract_invalid_bitmap_mask       ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ExtractAlphaBitmap
;
;           DESCRIPTION:    Extract alpha channel from bitmap
;
;           PARAMETERS:     BX          Bitmap handle
;
;           RETURNS:        AX          Alpha bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extract_alpha_bitmap_name  DB 'Extract Alpha Bitmap',0

extract_alpha_bitmap       PROC far
    push ds
    push ebx
;
    mov ax,BITMAP_HANDLE
    DerefHandle
    jc extract_alpha_fail
;
    mov al,[ebx].bm_style
    mov ds,[ebx].bm_sel
    mov ds:v_style,al
    call fword ptr ds:v_has_alpha_proc
    jc extract_alpha_fail
;
    stc

extract_alpha_fail:
    pop ebx
    pop ds
    ret
extract_alpha_bitmap       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       DESCRIPTION:    Console output functions
;
;       PARAMETERS:     ES    Flat sel
;                       FS    Console sel
;                       AL    Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateConPos      Proc near
    push ax
;    
    mov ax,fs:c_cols
    dec ax
    cmp fs:c_con_col,-1
    jne updNotRowWrap
;
    mov fs:c_con_col,ax

updNotRowWrap:
    cmp fs:c_con_col,ax
    jbe updSameRow
;
    mov fs:c_con_col,0
    inc fs:c_con_row

updSameRow:
    mov ax,fs:c_rows
    cmp fs:c_con_row,ax
    jc updUpdate
;
    push dx
    push si
    push di
;    
    dec fs:c_con_row
    mov si,1
    mov di,0

updScrollLoop:
    call CopyRow
;
    inc si
    inc di
    cmp si,fs:c_rows
    jc updScrollLoop 
;
    mov dx,di
    call ClearRow
;
    test fs:c_flags,CONSOLE_FLAG_BITMAP
    jz updText

updBitmap:
    call ScrollBitmap
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz updScrollDone
;
    push ds
    mov ds,fs:c_video_sel
    call RedrawVideo    
    pop ds
    jmp updScrollDone

updText:
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz updScrollDone
;
    lock or fs:c_flags,CONSOLE_FLAG_TEXT_BUFFER OR CONSOLE_FLAG_NEW_WRITES
;
    push ds
    push bx
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:update_thread
    Signal
    pop bx
    pop ds

updScrollDone:
    pop di
    pop si
    pop dx    

updUpdate:
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz updDone
;    
    push ds    
    push cx
    push dx
;
    mov dx,fs:c_con_row
    mov cx,fs:c_con_col
    mov ds,fs:c_video_sel
    call fword ptr ds:v_update_cursor_pos_proc
;
    pop dx
    pop cx
    pop ds

updDone:
    mov ax,fs:c_con_row
    mov fs:c_curr_row,ax
    mov ax,fs:c_con_col
    mov fs:c_curr_col,ax
    pop ax
    ret
UpdateConPos       ENDP

WriteConOne     PROC near
    push edi
    push eax
    push edx
;    
    push ax
    mov dx,fs:c_con_row
    mov ax,fs:c_cols
    mul dx
    add ax,fs:c_con_col
    movzx edi,ax
    shl edi,2
    add edi,OFFSET c_text_data
    mov ax,bx
    shl eax,16
    pop ax
    mov ah,1
    mov fs:[edi],eax
;
    pop edx
    pop eax
;    
    test fs:c_flags,CONSOLE_FLAG_BITMAP
    jz wctText

wctBitmap:
    push cx
    push dx
;    
    mov fs:[edi].ct_dirty,0
    mov cx,fs:c_con_col
    mov dx,fs:c_con_row
    call WriteBitmap
;
    pop dx
    pop cx
;    
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz wctDone
;
    push cx
    push dx
;    
    push ds
    mov fs:[edi].ct_dirty,0
    mov cx,fs:c_con_col
    mov dx,fs:c_con_row
    mov ds,fs:c_video_sel
    call fword ptr ds:v_write_text_proc
    pop ds
;
    pop dx
    pop cx
    jmp wctDone

wctText:
    test fs:c_flags,CONSOLE_FLAG_ACTIVE
    jz wctDone
;    
    lock or fs:c_flags,CONSOLE_FLAG_NEW_WRITES
    test fs:c_flags,CONSOLE_FLAG_TEXT_BUFFER
    jnz wctDone
;
    push cx
    push dx
;    
    push ds
    mov fs:[edi].ct_dirty,0
    mov cx,fs:c_con_col
    mov dx,fs:c_con_row
    mov ds,fs:c_video_sel
    call fword ptr ds:v_write_text_proc
    pop ds
;    
    pop dx
    pop cx

wctDone:    
    inc fs:c_con_col
    pop edi
    ret
WriteConOne    Endp

WriteConSkip       PROC near
    push ax
    mov al,' '
    call WriteConOne
    pop ax
    ret
WriteConSkip       ENDP

WriteConTab    PROC near
    push ax
    mov al,' '

write_con_tab_more:
    call WriteConOne
    test fs:c_con_col,3
    jnz write_con_tab_more
;
    pop ax
    ret
WriteConTab    ENDP

WriteConDel    PROC near
    dec fs:c_con_col
    ret
WriteConDel    ENDP

WriteConLf PROC near
    inc fs:c_con_row
    ret
WriteConLf ENDP

WriteConCr PROC near
    mov fs:c_con_col,0
    ret
WriteConCr ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteCConsole
;
;           DESCRIPTION:    Write to C console
;
;           PARAMETERS:     ES:EDI        Buffer
;                           ECX           Byte to write
;                           
;           RETURNS:        EAX           Number of written bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_c_console_name  DB 'Write C Console',0

write_con_tab:
wcct00   DD OFFSET WriteConSkip
wcct01   DD OFFSET WriteConOne
wcct02   DD OFFSET WriteConOne
wcct03   DD OFFSET WriteConOne
wcct04   DD OFFSET WriteConOne
wcct05   DD OFFSET WriteConOne
wcct06   DD OFFSET WriteConOne
wcct07   DD OFFSET WriteConOne
wcct08   DD OFFSET WriteConDel
wcct09   DD OFFSET WriteConTab
wcct0A   DD OFFSET WriteConLf
wcct0B   DD OFFSET WriteConOne
wcct0C   DD OFFSET WriteConOne
wcct0D   DD OFFSET WriteConCr
wcct0E   DD OFFSET WriteConOne
wcct0F   DD OFFSET WriteConOne

write_c_console     PROC far
    push ds
    push es
    push fs
    push gs
    push bx
    push ecx
    push esi
    push edi
;    
    HideMouse
    or ecx,ecx
    jz write_c_done
;
    mov ax,es
    mov gs,ax
    mov ax,flat_sel
    mov es,ax
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    or ax,ax
    jz write_c_done
;
    mov fs,ax    
    mov bl,7
    mov bh,0

write_c_loop:
    mov al,gs:[edi]
    inc edi
    movzx esi,al
    cmp esi,0Fh
    jc write_c_doit
;
    mov esi,0Fh

write_c_doit:
    shl esi,2
    call dword ptr cs:[esi].write_con_tab
    call UpdateConPos

write_c_next:
    loop write_c_loop

write_c_done:
    ShowMouse
;       
    pop edi
    pop esi
    pop ecx
    pop bx
    mov eax,ecx
;
    pop gs
    pop fs
    pop es
    pop ds
    ret
write_c_console     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;       DESCRIPTION:    Console input functions
;
;       PARAMETERS:     ES:EDI         Buffer end
;                       ES:ESI         Current buffer pos
;                       ECX            Remaining characters
;                       EDX            Total buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    

con_write       Proc near
    push es
    push bx
;
    mov bx,flat_sel
    mov es,bx
    mov bl,7
    mov bh,0
    call WriteConOne
;
    pop bx
    pop es
    ret
con_write       Endp
    
con_io_tab:
    mov al,' '
    jmp con_io_normal

con_io_normal   PROC near
    or ecx,ecx
    jz con_io_full
;
    cmp esi,edi
    jne con_io_insert
;
    call con_write
    stosb
    dec ecx
    mov esi,edi

con_io_full:
    clc
    ret

con_io_insert:
    push ecx
    push esi
    push edx
;
    mov cx,fs:c_con_col
    mov dx,fs:c_con_row
    push ecx
;
    mov ecx,edi
    sub ecx,esi

con_io_move_loop:
    call con_write
    xchg al,es:[esi]
    inc esi
    loop con_io_move_loop
;
    call con_write
    mov es:[esi],al
;
    pop ecx
    mov fs:c_con_row,dx
    mov fs:c_con_col,cx
;
    pop edx
    pop esi
    pop ecx
;
    mov al,es:[esi]
    call con_write
    mov eax,edi
    sub eax,esi
    sub eax,ecx
    jnc con_io_overflow
;
    inc esi
    inc edi
    dec ecx 
    clc
    ret

con_io_overflow:
    inc esi
    dec ecx
;
    push ecx
    push esi
    push edx
;
    mov cx,fs:c_con_col
    mov dx,fs:c_con_row

con_io_overflow_loop:
    cmp esi,edi
    je con_io_overflow_done
;
    mov al,es:[esi]
    call con_write
    inc esi
    jmp con_io_overflow_loop

con_io_overflow_done:
    mov al,' '
    call con_write
    mov fs:c_con_row,dx
    mov fs:c_con_col,cx
;
    pop edx
    pop esi
    pop ecx
    clc
    ret
con_io_normal   ENDP

con_io_del          PROC near
    cmp ecx,edx
    je con_io_del_empty
;
    cmp esi,edi
    jne con_io_del_move
;
    dec edi
    dec esi
    inc ecx
;
    push ecx
    push edx
;
    mov cx,fs:c_con_col
    mov dx,fs:c_con_row
    sub cx,1
    jnc con_io_del_do
;
    mov cx,fs:c_cols
    dec cx
;
    sub dx,1
    jnc con_io_del_do
;
    xor cx,cx
    xor dx,dx

con_io_del_do:
    mov fs:c_con_row,dx
    mov fs:c_con_col,cx
    mov al,' '
    call con_write
    mov fs:c_con_row,dx
    mov fs:c_con_col,cx
;
    pop edx
    pop ecx

con_io_del_empty:
    clc
    ret

con_io_del_move:
    dec esi
    dec edi
    inc ecx
;
    push ecx
    push esi
    push edx
;
    mov cx,fs:c_con_col
    mov dx,fs:c_con_row
    sub cx,1
    jnc con_io_del_do_move
;
    mov cx,fs:c_cols
    dec cx
;
    sub dx,1
    jnc con_io_del_do_move
;
    xor cx,cx
    xor dx,dx

con_io_del_do_move:
    mov fs:c_con_row,dx
    mov fs:c_con_col,cx
    push ecx
;
    mov ecx,edi
    sub ecx,esi

con_io_del_loop:
    mov al,es:[esi+1]
    mov es:[esi],al
    call con_write
    inc esi
    loop con_io_del_loop
;
    mov al,' '
    call con_write
;
    pop ecx
    mov fs:c_con_row,dx
    mov fs:c_con_col,cx
;
    pop edx
    pop esi
    pop ecx
    clc
    ret
con_io_del          ENDP

con_io_cr           PROC near
    cmp ecx,2
    jc con_io_cr_full
;
    mov al,0Dh
    mov es:[esi],al
    dec ecx
    inc esi
    inc edi
;
    mov al,0Ah
    mov es:[esi],al
    dec ecx
    inc esi
    inc edi
;
    mov fs:c_con_col,0
    inc fs:c_con_row
    call UpdateConPos    
    stc
    ret

con_io_cr_full:
    clc
    ret
con_io_cr           ENDP

con_io_clear_buf    PROC near

con_clear_home_loop:
    cmp ecx,edx
    je con_clear_home_done
;
    push ecx
    push edx
;
    mov cx,fs:c_con_col
    mov dx,fs:c_con_row
    sub cx,1
    jnc con_clear_home_do
;
    mov cx,fs:c_cols
    dec cx
;
    sub dx,1
    jnc con_clear_home_do
;
    xor cx,cx
    xor dx,dx

con_clear_home_do:
    mov fs:c_con_row,dx
    mov fs:c_con_col,cx
;
    pop edx
    pop ecx
;
    dec esi
    inc ecx
    jmp con_clear_home_loop

con_clear_home_done:
    push ecx
    push edx
;
    mov cx,fs:c_con_col
    mov dx,fs:c_con_row
    push ecx    
;
    mov ecx,edi
    sub ecx,esi
    mov al,' '
    or ecx,ecx
    jz con_clear_done

con_clear_loop:
    call con_write
    loop con_clear_loop

con_clear_done:
    pop ecx
    mov fs:c_con_row,dx
    mov fs:c_con_col,cx
;
    pop edx
    pop ecx
;
    mov edi,esi
    clc
    ret
con_io_clear_buf    ENDP

con_io_skip     PROC near
    clc
    ret
con_io_skip     ENDP

con_left_arrow  PROC near
    cmp edx,ecx
    je con_left_fail
;
    inc ecx
    dec esi
;
    push ecx
    push edx
;
    mov cx,fs:c_con_col
    mov dx,fs:c_con_row
    sub cx,1
    jnc con_left_arrow_do
;
    mov cx,fs:c_cols
    dec cx
;
    sub dx,1
    jnc con_left_arrow_do
;
    xor cx,cx
    xor dx,dx

con_left_arrow_do:
    mov fs:c_con_row,dx
    mov fs:c_con_col,cx
;
    pop edx
    pop ecx

con_left_fail:
    clc
    ret
con_left_arrow  ENDP

con_right_arrow PROC near
    cmp edi,esi
    je con_right_fail
;
    mov al,es:[esi]
    cmp edi,esi
    jne con_right_write
;
    mov al,' '

con_right_write:
    call con_write
    dec ecx
    inc esi

con_right_fail:
    clc
    ret
con_right_arrow ENDP

con_home_key    PROC near

con_home_loop:
    cmp ecx,edx
    je con_home_done
;
    push ecx
    push edx
;
    mov cx,fs:c_con_col
    mov dx,fs:c_con_row
    sub cx,1
    jnc con_home_do
;
    mov cx,fs:c_cols
    dec cx
    sub dx,1
    jnc con_home_do
;
    xor cx,cx
    xor dx,dx

con_home_do:
    mov fs:c_con_row,dx
    mov fs:c_con_col,cx
;
    pop edx
    pop ecx
;
    dec esi
    inc ecx
    jmp con_home_loop

con_home_done:
    clc
    ret
con_home_key    ENDP

con_end_key     PROC near

con_end_loop:
    cmp esi,edi
    je con_end_done
;
    mov al,es:[esi]
    call con_write
    inc esi
    dec ecx
    jmp con_end_loop

con_end_done:
    clc
    ret
con_end_key     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadCConsole
;
;           DESCRIPTION:    Read from console
;
;           PARAMETERS:     ES:EDI        BUFFER
;                           ECX           MAX NUMBER OF CHARS
;                           
;           RETURNS:        ECX           NUMBER OF READ CHARS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_c_console_name   DB 'Read C Console',0

con_ext_key_buf_tab:
dek00   DD OFFSET con_io_skip
dek01   DD OFFSET con_io_skip
dek02   DD OFFSET con_io_skip
dek03   DD OFFSET con_io_skip
dek04   DD OFFSET con_io_skip
dek05   DD OFFSET con_io_skip
dek06   DD OFFSET con_io_skip
dek07   DD OFFSET con_io_skip
dek08   DD OFFSET con_io_skip
dek09   DD OFFSET con_io_skip
dek0A   DD OFFSET con_io_skip
dek0B   DD OFFSET con_io_skip
dek0C   DD OFFSET con_io_skip
dek0D   DD OFFSET con_io_skip
dek0E   DD OFFSET con_io_skip
dek0F   DD OFFSET con_io_skip
dek10   DD OFFSET con_io_skip
dek11   DD OFFSET con_io_skip
dek12   DD OFFSET con_io_skip
dek13   DD OFFSET con_io_skip
dek14   DD OFFSET con_io_skip
dek15   DD OFFSET con_io_skip
dek16   DD OFFSET con_io_skip
dek17   DD OFFSET con_io_skip
dek18   DD OFFSET con_io_skip
dek19   DD OFFSET con_io_skip
dek1A   DD OFFSET con_io_skip
dek1B   DD OFFSET con_io_skip
dek1C   DD OFFSET con_io_skip
dek1D   DD OFFSET con_io_skip
dek1E   DD OFFSET con_io_skip
dek1F   DD OFFSET con_io_skip
dek20   DD OFFSET con_io_skip
dek21   DD OFFSET con_io_skip
dek22   DD OFFSET con_io_skip
dek23   DD OFFSET con_io_skip
dek24   DD OFFSET con_io_skip
dek25   DD OFFSET con_io_skip
dek26   DD OFFSET con_io_skip
dek27   DD OFFSET con_io_skip
dek28   DD OFFSET con_io_skip
dek29   DD OFFSET con_io_skip
dek2A   DD OFFSET con_io_skip
dek2B   DD OFFSET con_io_skip
dek2C   DD OFFSET con_io_skip
dek2D   DD OFFSET con_io_skip
dek2E   DD OFFSET con_io_skip
dek2F   DD OFFSET con_io_skip
dek30   DD OFFSET con_io_skip
dek31   DD OFFSET con_io_skip
dek32   DD OFFSET con_io_skip
dek33   DD OFFSET con_io_skip
dek34   DD OFFSET con_io_skip
dek35   DD OFFSET con_io_skip
dek36   DD OFFSET con_io_skip
dek37   DD OFFSET con_io_skip
dek38   DD OFFSET con_io_skip
dek39   DD OFFSET con_io_skip
dek3A   DD OFFSET con_io_skip
dek3B   DD OFFSET con_io_skip
dek3C   DD OFFSET con_io_skip
dek3D   DD OFFSET con_io_skip
dek3E   DD OFFSET con_io_skip
dek3F   DD OFFSET con_io_skip
dek40   DD OFFSET con_io_skip
dek41   DD OFFSET con_io_skip
dek42   DD OFFSET con_io_skip
dek43   DD OFFSET con_io_skip
dek44   DD OFFSET con_io_skip
dek45   DD OFFSET con_io_skip
dek46   DD OFFSET con_io_skip
dek47   DD OFFSET con_home_key
dek48   DD OFFSET con_io_skip
dek49   DD OFFSET con_io_skip
dek4A   DD OFFSET con_io_skip
dek4B   DD OFFSET con_left_arrow
dek4C   DD OFFSET con_io_skip
dek4D   DD OFFSET con_right_arrow
dek4E   DD OFFSET con_io_skip
dek4F   DD OFFSET con_end_key
dek50   DD OFFSET con_io_skip
dek51   DD OFFSET con_io_skip
dek52   DD OFFSET con_io_skip
dek53   DD OFFSET con_io_clear_buf
dek54   DD OFFSET con_io_skip
dek55   DD OFFSET con_io_skip
dek56   DD OFFSET con_io_skip
dek57   DD OFFSET con_io_skip
dek58   DD OFFSET con_io_skip
dek59   DD OFFSET con_io_skip
dek5A   DD OFFSET con_io_skip
dek5B   DD OFFSET con_io_skip
dek5C   DD OFFSET con_io_skip
dek5D   DD OFFSET con_io_skip
dek5E   DD OFFSET con_io_skip
dek5F   DD OFFSET con_io_skip
dek60   DD OFFSET con_io_skip
dek61   DD OFFSET con_io_skip
dek62   DD OFFSET con_io_skip
dek63   DD OFFSET con_io_skip
dek64   DD OFFSET con_io_skip
dek65   DD OFFSET con_io_skip
dek66   DD OFFSET con_io_skip
dek67   DD OFFSET con_io_skip
dek68   DD OFFSET con_io_skip
dek69   DD OFFSET con_io_skip
dek6A   DD OFFSET con_io_skip
dek6B   DD OFFSET con_io_skip
dek6C   DD OFFSET con_io_skip
dek6D   DD OFFSET con_io_skip
dek6E   DD OFFSET con_io_skip
dek6F   DD OFFSET con_io_skip
dek70   DD OFFSET con_io_skip
dek71   DD OFFSET con_io_skip
dek72   DD OFFSET con_io_skip
dek73   DD OFFSET con_io_skip
dek74   DD OFFSET con_io_skip
dek75   DD OFFSET con_io_skip
dek76   DD OFFSET con_io_skip
dek77   DD OFFSET con_io_skip
dek78   DD OFFSET con_io_skip
dek79   DD OFFSET con_io_skip
dek7A   DD OFFSET con_io_skip
dek7B   DD OFFSET con_io_skip
dek7C   DD OFFSET con_io_skip
dek7D   DD OFFSET con_io_skip
dek7E   DD OFFSET con_io_skip
dek7F   DD OFFSET con_io_skip
dek80   DD OFFSET con_io_skip
dek81   DD OFFSET con_io_skip
dek82   DD OFFSET con_io_skip
dek83   DD OFFSET con_io_skip
dek84   DD OFFSET con_io_skip

con_io_extend   PROC near
    movzx ebx,ah
    shl ebx,2
    call cs:dword ptr [ebx].con_ext_key_buf_tab
    ret
con_io_extend   ENDP

con_key_buf_tab:
ckb0    DD OFFSET con_io_extend
ckb1    DD OFFSET con_io_normal
ckb2    DD OFFSET con_io_normal
ckb3    DD OFFSET con_io_normal
ckb4    DD OFFSET con_io_normal
ckb5    DD OFFSET con_io_normal
ckb6    DD OFFSET con_io_normal
ckb7    DD OFFSET con_io_normal
ckb8    DD OFFSET con_io_del
ckb9    DD OFFSET con_io_tab
ckbA    DD OFFSET con_io_normal
ckbB    DD OFFSET con_io_normal
ckbC    DD OFFSET con_io_normal
ckbD    DD OFFSET con_io_cr
ckbE    DD OFFSET con_io_normal
ckbF    DD OFFSET con_io_normal
ckb10   DD OFFSET con_io_normal
ckb11   DD OFFSET con_io_normal
ckb12   DD OFFSET con_io_normal
ckb13   DD OFFSET con_io_normal
ckb14   DD OFFSET con_io_normal
ckb15   DD OFFSET con_io_normal
ckb16   DD OFFSET con_io_normal
ckb17   DD OFFSET con_io_normal
ckb18   DD OFFSET con_io_normal
ckb19   DD OFFSET con_io_normal
ckb1A   DD OFFSET con_io_normal
ckb1B   DD OFFSET con_io_clear_buf
ckb1C   DD OFFSET con_io_normal
ckb1D   DD OFFSET con_io_normal
ckb1E   DD OFFSET con_io_normal
ckb1F   DD OFFSET con_io_normal
ckbend  DD OFFSET con_io_normal

read_c_console  PROC far
    push ds
    push fs
    push ebx
    push esi
;
    push edi
    mov edx,ecx
    mov esi,edi
;
    GetThread
    mov ds,ax
    mov ax,ds:p_console
    or ax,ax
    jz con_io_done
;
    mov fs,ax    

con_io_loop:
    call UpdateConPos
    PollKeyboard
    jnc con_io_get
;
    mov ax,25
    WaitMilliSec
    jmp con_io_loop

con_io_get:
    ReadKeyboard
    movzx ebx,al
    cmp ebx,20h
    jc con_io_in_tab
;
    mov ebx,20h

con_io_in_tab:
    shl ebx,2
    call cs:dword ptr [ebx].con_key_buf_tab
    jnc con_io_loop
;
    pop edi
    mov eax,esi
    sub eax,edi
    mov ecx,eax
    xor eax,eax
    xor edx,edx
    clc

con_io_done:
    pop esi
    pop ebx
    pop fs
    pop ds
    ret
read_c_console  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_THREAD
;
;           DESCRIPTION:    init thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            
init_thread     PROC far
    push ds
    push ax
;
    GetThread
    mov ds,ax
    mov ds:p_forecolor,7
    mov ds:p_backcolor,0
    mov ds:p_row,0
    mov ds:p_col,0
;
    pop ax
    pop ds
    ret
init_thread     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseConsole
;
;           DESCRIPTION:    Close console
;
;           PARAMETERS:     BX        Console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_console_name DB 'Close Console', 0

close_console        Proc far
    push es
;
    mov es,bx
    sub es:c_usage,1
    jnz ccsDone
;    
    call DeleteConsole
    
ccsDone:
    pop es
    ret
close_console     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Handle methods
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

device_ok      Proc far
    clc
    ret
device_ok      Endp

input_size     Proc far
    PollKeyboard
    jnc is1
;
    xor ecx,ecx
    clc
    ret

is1:
    mov ecx,1
    clc
    ret
input_size     Endp

eof_input      Proc far
    PollKeyboard
    jc eiOk
;
    xor eax,eax
    ret

eiOk:
    mov eax,1
    ret
eof_input      Endp

eof_output      Proc far
    mov eax,1
    ret
eof_output      Endp

output_size       Proc far
    mov ecx,1
    clc
    ret
output_size       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateInputHandle
;
;           DESCRIPTION:    Create consolse input handle
;
;           RETURNS:        AX         Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_input_handle_name DB 'Create Input Handle', 0

create_input_handle        Proc far
    push ds
    push es
    push ebx
    push ecx
;
    mov eax,SIZE handle_entry_interface
    AllocateSmallGlobalMem
;
    InitHandle
;
    mov es:hei_read_proc,OFFSET read_c_console
    mov es:hei_read_proc+4,cs
;
    mov es:hei_is_eof_proc,OFFSET eof_input
    mov es:hei_is_eof_proc+4,cs
;
    mov es:hei_is_device_proc,OFFSET device_ok
    mov es:hei_is_device_proc+4,cs
;
    mov es:hei_input_size_proc,OFFSET input_size
    mov es:hei_input_size_proc+4,cs
;
    mov eax,es
;
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
create_input_handle        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateOutputHandle
;
;           DESCRIPTION:    Create consolse output handle
;
;           RETURNS:        AX         Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_output_handle_name DB 'Create Output Handle', 0

create_output_handle        Proc far
    push ds
    push es
    push ebx
    push ecx
;
    mov eax,SIZE handle_entry_interface
    AllocateSmallGlobalMem
;
    InitHandle
;
    mov es:hei_write_proc,OFFSET write_c_console
    mov es:hei_write_proc+4,cs
;
    mov es:hei_is_eof_proc,OFFSET eof_output
    mov es:hei_is_eof_proc+4,cs
;
    mov es:hei_is_device_proc,OFFSET device_ok
    mov es:hei_is_device_proc+4,cs
;
    mov es:hei_output_size_proc,OFFSET output_size
    mov es:hei_output_size_proc+4,cs
;
    mov eax,es
;
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
create_output_handle        Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_tasking
;
;           DESCRIPTION:    init tasking
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init_tasking      Proc far
    push ds
    push es
    pusha
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET update_thread_name
    mov esi,OFFSET update_thread_pr
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    popa
    pop es
    pop ds
    ret
init_tasking      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init driver
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_video

disp_x_text DB 'DISP.X', 0
disp_y_text DB 'DISP.Y', 0
disp_fixed_text  DB 'DISP.FIXED', 0
            
init_video      PROC near
    mov ax,SEG data
    mov ds,ax
    mov ds:focus_console,0
    mov ds:video_mode_list,0
    mov ds:flags,0
    mov ds:curr_video_mode,0
;    
    mov ax,cs
    mov es,ax
    mov edi,OFFSET disp_x_text
    call GetValue
    mov ds:disp_x,ax
;
    mov edi,OFFSET disp_y_text
    call GetValue    
    mov ds:disp_y,ax
;
    mov edi,OFFSET disp_fixed_text
    call GetValue    
    mov ds:disp_fixed,ax
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov edi,OFFSET init_tasking
    HookInitTasking
;
    mov edi,OFFSET init_thread
    HookCreateThread
;
    mov esi,OFFSET get_focus_thread
    mov edi,OFFSET get_focus_thread_name
    xor cl,cl
    mov ax,get_focus_thread_nr
    RegisterOsGate
;
    mov esi,OFFSET get_focus_console
    mov edi,OFFSET get_focus_console_name
    xor cl,cl
    mov ax,get_focus_console_nr
    RegisterOsGate
;
    mov esi,OFFSET set_focus_console
    mov edi,OFFSET set_focus_console_name
    xor cl,cl
    mov ax,set_focus_console_nr
    RegisterOsGate
;
    mov esi,OFFSET create_console
    mov edi,OFFSET create_console_name
    xor cl,cl
    mov ax,create_console_nr
    RegisterOsGate
;
    mov esi,OFFSET close_console
    mov edi,OFFSET close_console_name
    xor cl,cl
    mov ax,close_console_nr
    RegisterOsGate
;
    mov esi,OFFSET invert_mouse
    mov edi,OFFSET invert_mouse_name
    xor cl,cl
    mov ax,invert_mouse_nr
    RegisterOsGate
;
    mov esi,OFFSET begin_get_video_modes
    mov edi,OFFSET begin_get_video_modes_name
    xor cl,cl
    mov ax,begin_get_video_modes_nr
    RegisterOsGate
;
    mov esi,OFFSET end_get_video_modes
    mov edi,OFFSET end_get_video_modes_name
    xor cl,cl
    mov ax,end_get_video_modes_nr
    RegisterOsGate
;
    mov esi,OFFSET add_video_mode
    mov edi,OFFSET add_video_mode_name
    xor cl,cl
    mov ax,add_video_mode_nr
    RegisterOsGate
;
    mov esi,OFFSET create_input_handle
    mov edi,OFFSET create_input_handle_name
    xor cl,cl
    mov ax,create_input_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET create_output_handle
    mov edi,OFFSET create_output_handle_name
    xor cl,cl
    mov ax,create_output_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET read_c_console
    mov edi,OFFSET read_c_console_name
    xor cl,cl
    mov ax,read_c_console_nr
    RegisterOsGate
;
    mov esi,OFFSET write_c_console
    mov edi,OFFSET write_c_console_name
    xor cl,cl
    mov ax,write_c_console_nr
    RegisterOsGate
;
    mov esi,OFFSET query_video_mode
    mov edi,OFFSET query_video_mode_name
    xor dx,dx
    mov ax,query_video_mode_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_video_mode
    mov edi,OFFSET get_video_mode_name
    xor dx,dx
    mov ax,get_video_mode_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_video_mode
    mov edi,OFFSET set_video_mode_name
    xor dx,dx
    mov ax,set_video_mode_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_text_size
    mov edi,OFFSET get_text_size_name
    xor dx,dx
    mov ax,get_text_size_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET clear_text
    mov edi,OFFSET clear_text_name
    xor dx,dx
    mov ax,clear_text_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_cursor_position
    mov edi,OFFSET set_cursor_pos_name
    xor dx,dx
    mov ax,set_cursor_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_cursor_position
    mov edi,OFFSET get_cursor_pos_name
    xor dx,dx
    mov ax,get_cursor_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_console_cursor_position
    mov edi,OFFSET get_console_cursor_pos_name
    xor dx,dx
    mov ax,get_console_cursor_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_console_cursor_position
    mov edi,OFFSET set_console_cursor_pos_name
    xor dx,dx
    mov ax,set_console_cursor_position_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_forecolor
    mov edi,OFFSET set_forecolor_name
    xor dx,dx
    mov ax,set_forecolor_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_backcolor
    mov edi,OFFSET set_backcolor_name
    xor dx,dx
    mov ax,set_backcolor_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_char_attrib
    mov edi,OFFSET get_char_attrib_name
    xor dx,dx
    mov ax,get_char_attrib_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_char
    mov edi,OFFSET write_char_name
    xor dx,dx
    mov ax,write_char_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET write_asciiz16
    mov esi,OFFSET write_asciiz32
    mov edi,OFFSET write_asciiz_name
    mov dx,virt_es_in
    mov ax,write_asciiz_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_size_string16
    mov esi,OFFSET write_size_string32
    mov edi,OFFSET write_size_string_name
    mov dx,virt_es_in
    mov ax,write_size_string_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_attr_string16
    mov esi,OFFSET write_attr_string32
    mov edi,OFFSET write_attr_string_name
    mov dx,virt_es_in
    mov ax,write_attrib_string_nr
    RegisterUserGate
;
    mov esi,OFFSET set_clip_rect
    mov edi,OFFSET set_clip_rect_name
    xor dx,dx
    mov ax,set_clip_rect_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET clear_clip_rect
    mov edi,OFFSET clear_clip_rect_name
    xor dx,dx
    mov ax,clear_clip_rect_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_draw_color
    mov edi,OFFSET set_draw_color_name
    xor dx,dx
    mov ax,set_drawcolor_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_lgop
    mov edi,OFFSET set_lgop_name
    xor dx,dx
    mov ax,set_lgop_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_hollow_style
    mov edi,OFFSET set_hollow_style_name
    xor dx,dx
    mov ax,set_hollow_style_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_filled_style
    mov edi,OFFSET set_filled_style_name
    xor dx,dx
    mov ax,set_filled_style_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_font
    mov edi,OFFSET set_font_name
    xor dx,dx
    mov ax,set_font_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_pixel
    mov edi,OFFSET get_pixel_name
    xor dx,dx
    mov ax,get_pixel_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_pixel
    mov edi,OFFSET set_pixel_name
    xor dx,dx
    mov ax,set_pixel_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET blit_pr
    mov edi,OFFSET blit_name
    xor dx,dx
    mov ax,blit_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET draw_mask
    mov edi,OFFSET draw_mask_name
    xor dx,dx
    mov ax,draw_mask_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET draw_string16
    mov esi,OFFSET draw_string32
    mov edi,OFFSET draw_string_name
    mov dx,virt_es_in
    mov ax,draw_string_nr
    RegisterUserGate
;
    mov esi,OFFSET draw_line
    mov edi,OFFSET draw_line_name
    xor dx,dx
    mov ax,draw_line_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET draw_rect
    mov edi,OFFSET draw_rect_name
    xor dx,dx
    mov ax,draw_rect_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET draw_ellipse
    mov edi,OFFSET draw_ellipse_name
    xor dx,dx
    mov ax,draw_ellipse_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET extract_valid_bitmap_mask
    mov edi,OFFSET extract_valid_bitmap_mask_name
    xor dx,dx
    mov ax,extract_valid_bitmap_mask_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET extract_invalid_bitmap_mask
    mov edi,OFFSET extract_invalid_bitmap_mask_name
    xor dx,dx
    mov ax,extract_invalid_bitmap_mask_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET extract_alpha_bitmap
    mov edi,OFFSET extract_alpha_bitmap_name
    xor dx,dx
    mov ax,extract_alpha_bitmap_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_dos_string
    mov edi,OFFSET write_dos_string_name
    xor cl,cl
    mov ax,write_dos_string_nr
    RegisterOsGate
;
    call init_bitmap
    call init_sprite
    ret
init_video      ENDP

code    ENDS

    END
