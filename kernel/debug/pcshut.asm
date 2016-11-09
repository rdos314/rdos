 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2016, Leif Ekblad
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
; PCSHUT.ASM
; PC platform kernel "panic" module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.def

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;
; switch struc. Should be first.
;

pm_data   pmode_switch_struc <>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupBiosPic
;
;           DESCRIPTION:    Setup PIC to operate in BIOS-compatible mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupBiosPic    Proc near
    mov al,11h
    out 20h,al
    jmp short $+2
;
    mov al,8
    out 21h,al
    jmp short $+2
;
    mov al,04h
    out 21h,al
    jmp short $+2
;
    mov al,0C1h
    out 20h,AL
    jmp short $+2
;
    mov al,1
    out 21h,al
    jmp short $+2
;
    mov al,11h
    out 0A0h,al
    jmp short $+2
;
    mov al,70h
    out 0A1h,al
    jmp short $+2
;
    mov al,2
    out 0A1h,al
    jmp short $+2
;
    mov al,1
    out 0A1h,al
    jmp short $+2
;
    mov al,-1
    out 21h,al
;
    mov al,-1
    out 0A1h,al
    jmp short $+2
    ret
SetupBiosPic    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupBiosPit
;
;           DESCRIPTION:    Setup PIT to operate in BIOS-compatible mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupBiosPit    Proc near
    mov al,30h
    out 43h,al
    jmp short $+2
;
    mov al,-1
    out 40h,al
    jmp short $+2
;
    mov al,-1
    out 40h,al
    jmp short $+2    
    ret
SetupBiosPit    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Switch monitor
;
;           DESCRIPTION:    Switch to monitor
;
;           PARAMETERS:     EDX         Linear base of code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gdt0:
    dw 20h-1        ; real mode GDT
    dd 00000000h
    dw 0
gdt8:               ; 16-bit data selector for real mode
    dw 0FFFFh
    dd 92000000h
    dw 0
gdt10:              ; 16-bit code selector for real mode
    dw 0FFFFh
    dd 9A000000h
    dw 0
gdt18:              ; code selector for protected mode
    dw 0FFFFh
    dd 9A000000h
    dw 0
idt20:              ; real mode IDT
    dw 3FFh
    dd 00000000h
    dw 0

switch_monitor:
    cli
    mov ax,flat_sel
    mov ds,ax
;
    mov edi,OFFSET Gdt0 + 2
    mov eax,edx
    add eax,OFFSET Gdt0
    mov dword ptr ds:[edx+edi],eax
;   
    mov edi,OFFSET gdt10  + 2
    or dword ptr ds:[edx+edi],edx
;
    mov edi,OFFSET gdt18 + 2
    or dword ptr ds:[edx+edi],edx
;        
    mov edi,OFFSET real_seg
    mov eax,edx
    shr eax,4
    mov ds:[edx+edi],ax
;    
    db 0EAh
    dw OFFSET prot_enter_start
    dw shutdown_code_sel
    
prot_enter_start:
    mov eax,cr0
    and eax,7FFFFFFFh
    mov cr0,eax
;
    db 66h
    lgdt fword ptr cs:gdt0
;
    db 66h
    lidt fword ptr cs:idt20
;
    db 0EAh
    dw OFFSET real_enter
    dw 10h

real_enter:
    mov ax,8
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov ax,1000h
    mov sp,ax
;
    mov eax,cr0
    and al,NOT 1
    mov cr0,eax
;
    db 0EAh         ; jmp to real-mode selector
    dw OFFSET real_start
real_seg dw 0
    
real_start:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov sp,1000h
;   
    mov ax,cs:pm_flags
    test ax,PM_FLAG_VIDEO
    jz real_video_done
;    
    call SetupBiosPic
    call SetupBiosPit
    mov ax,3
    int 10h
    cli
;
    mov al,-1
    out 21h,al

real_video_done:
    mov bx,cs:pm_flags
    mov eax,cr4
    and al,NOT 20h
    test bx,PM_FLAG_PAE
    jz real_pae_done
;
    or al,20h

real_pae_done:
    mov cr4,eax
;
    mov eax,cs:pm_cr3
    mov cr3,eax
;    
    db 66h
    lgdt fword ptr cs:pm_gdtr
    db 66h
    lidt fword ptr cs:pm_idtr
;
    mov eax,cr0
    or al,1
    mov cr0,eax
;    
    mov ax,cs:pm_ss
    mov ss,ax
    mov esp,cs:pm_esp
;    
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
;    
    movzx eax,cs:pm_cs
    push eax
    mov eax,cs:pm_eip
    push eax
    retf32
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetTextBase
;
;           DESCRIPTION:    Get text mode buffer segment
;
;           RETURNS:        BX          video selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetTextBase       Proc near
    push ds
    mov ax,flat_sel
    mov ds,ax
    mov edx,0A0000h
    mov ax,720h

get_video_loop:
    mov [edx],ax
    cmp ax,[edx]
    je get_video_sel
;    
    add edx,1000h
    cmp edx,0C0000h
    jne get_video_loop
;    
    mov edx,0F0000h

get_video_sel:
    mov ax,gdt_sel
    mov ds,ax
    mov bx,dosB800
    mov word ptr [bx],0FFFh
    mov [bx+2],edx
    mov byte ptr [bx+5],92h
    mov word ptr [bx+6],0
    pop ds
    ret
GetTextBase       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Font8x19
;
;   DESCRIPTION:    8x19 font
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           GetLfb
;
;   DESCRIPTION:    Get LFB base
;
;   PARAMETERS:     DS   System data sel
;
;   RETURNS:        EDI  LFB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetLfb  Proc near
    mov edi,cr0
    test edi,80000000h
    jz glfbPhys
;
    mov edi,boot_efi_linear
    ret

glfbPhys:
    mov edi,ds:efi_lfb
    ret
GetLfb  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           LocalWriteChar
;
;   DESCRIPTION:    Write a single character
;
;   PARAMETERS:     AL          Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalWriteChar       Proc near
    push ds
    push es
    pushad
;   
    push ax
    mov ax,system_data_sel
    mov ds,ax
;
    mov eax,ds:efi_lfb
    or eax,ds:efi_lfb+4
    pop ax
    jnz wcLfb

wcText:    
    push ax
    mov ax,dosB800
    mov es,ax
;
    mov ax,ds:efi_text_row
    mov cx,80
    mul cx
    add ax,ds:efi_text_col
    add ax,ax
    mov di,ax
    pop ax
    mov ah,7
    stosw
    jmp wcDone
    
wcLfb: 
    push ax
    mov ax,flat_sel
    mov es,ax
;    
    mov ax,ds:efi_text_row
    mov cx,19
    mul cx
    add ax,4
    movzx eax,ax
    movzx edx,ds:efi_text_col
    shl edx,3
    xchg eax,edx
;
    push eax
    mov eax,ds:efi_scan_size
    mul edx
    call GetLfb
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
    pop ax
;
    mov ah,19
    mul ah
    mov bx,ax
    add bx,OFFSET font8x19
;
    mov cx,19

wcRowLoop:    
    push cx
    push edi
    mov cx,8
    mov al,cs:[bx]

wcLoop:
    test al,80h
    jz wcBack

wcFore:
    mov edx,dword ptr ds:efi_fore_col
    mov es:[edi],edx
    jmp wcNext

wcBack:
    mov edx,dword ptr ds:efi_back_col
    mov es:[edi],edx

wcNext:
    add edi,4
    shl al,1
;
    loop wcLoop    
;
    pop edi
    pop cx
    add edi,ds:efi_scan_size
    inc bx
;
    loop wcRowLoop    

wcDone:    
    mov ax,ds:efi_text_col
    inc ax
    cmp ax,80
    jb wcSaveCol
;
    xor ax,ax
    inc ds:efi_text_row

wcSaveCol:        
    mov ds:efi_text_col,ax
;
    popad        
    pop es
    pop ds
    ret
LocalWriteChar       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SingleHex
;
;           DESCRIPTION:
;
;           PARAMETERS:         AL          Value in
;                           AX          Value out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SingleHex       Proc near
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb shLow1
;
    add al,7

shLow1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb shHigh1
;
    add ah,7

shHigh1:
    add ah,30h
    ret
SingleHex  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteHexByte
;
;       DESCRIPTION:
;
;       PARAMETERS:     AL          HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    Proc near
    push ax
    push di
;
    call SingleHex
    mov di,ax
    mov al,ah
    call LocalWriteChar
    mov ax,di
    call LocalWriteChar
;
    pop di
    pop ax
    ret
WriteHexByte  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteHexWord
;
;       DESCRIPTION:
;
;       PARAMETERS:     AX          HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    Proc near
    push ax
    push si
    push di
;
    mov si,ax
    shr ax,8
    call SingleHex
    mov di,ax
    call LocalWriteChar
    mov ax,di
    mov al,ah
    call LocalWriteChar
    mov ax,si
    call SingleHex
    mov di,ax
    call LocalWriteChar
    mov ax,di
    mov al,ah
    call LocalWriteChar
;
    pop di
    pop si
    pop ax
    ret
WriteHexWord  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteHexDword
;
;       DESCRIPTION:
;
;       PARAMETERS:     EAX          HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword    Proc near
    push eax
    shr eax,16
    call WriteHexWord
    pop eax
    call WriteHexWord
    ret
WriteHexDword   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteString
;
;           DESCRIPTION:    Write string to screen
;
;           PARAMETERS:     ES:DI       String
;                           CX          Number of characters
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteString       PROC near
    push ds
    push ax
    push di
;    
    mov ax,system_data_sel
    mov ds,ax
    
wsLoop:
    mov al,es:[di]
    cmp al,13
    jne wsNotCr
;
    mov ds:efi_text_col,0
    jmp wsNext
    
wsNotCr:
    cmp al,10
    jne wsNotLf
;
    inc ds:efi_text_row 
    jmp wsNext   

wsNotLf:
    call LocalWriteChar
    
wsNext:
    mov ax,ds:efi_text_col
    cmp ax,80
    jne wsLineOk
;
    inc ds:efi_text_row
    mov ds:efi_text_col,0

wsLineOk:
    inc di
    loop wsLoop
;
    pop di
    pop ax
    pop ds
    ret
WriteString      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteDwordReg
;
;   DESCRIPTION:    Write 32-bit registers
;
;   PARAMETERS:     ES:DI       Table
;                   GS          Tss
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDwordReg PROC near
    mov cx,4
    call WriteString
;
    add di,4
    mov bx,es:[di]
    mov eax,gs:[bx]
    call WriteHexDword
;    
    add di,2
    mov al,es:[di]
    or al,al
    jz WriteDwordRegDone
;
    inc ds:efi_text_col
    jmp WriteDwordReg

WriteDwordRegDone:    
    ret
WriteDwordReg ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WRITE_WORD_REG
;
;   DESCRIPTION:    Write 16-bit registers
;
;   PARAMETERS:     ES:DI   Table
;                   GS      TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteWordReg  PROC near
    mov cx,3
    call WriteString
;    
    add di,3
    mov bx,es:[di]
    mov ax,gs:[bx]
    call WriteHexWord
;    
    add di,2
    mov al,es:[di]
    or al,al
    jz WriteWordRegDone
;
    inc ds:efi_text_col
    jmp WriteWordReg

WriteWordRegDone:    
    ret
WriteWordReg  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteEflags
;
;   DESCRIPTION:    Write EFLAGS
;
;   PARAMETERS:     GS          TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eflags_tab:
;
;           reset       set
et_cf   DB 'NC ',       'CY '
et_1    DB 0,0,0,       0,0,0
et_pf   DB 'PO ',       'PE '
et_3    DB 0,0,0,       0,0,0
et_af   DB 'NA ',       'AC '
et_5    DB 0,0,0,       0,0,0
et_zf   DB 'NZ ',       'ZR '
et_sf   DB 'PL ',       'NG '
et_tf   DB 0,0,0,       0,0,0
et_if   DB 'DI ',       'EI '
et_df   DB 'UP ',       'DN '
et_of   DB 'NV ',       'OV '
et_12   DB 0,0,0,       0,0,0
et_13   DB 0,0,0,       0,0,0
et_14   DB 'PR ' ,      'NT '
et_15   DB 0,0,0,       0,0,0
et_16   DB 0,0,0,       0,0,0
et_vm   DB 'PM ',       'VM '
et_end  DB 0FFh

WriteEflags    PROC near
    mov bx,OFFSET p_rflags
    mov eax,gs:[bx]
    mov di,OFFSET eflags_tab
    mov cx,cs
    mov es,cx
    
eflags_loop:
    mov ch,es:[di]
    or ch,ch
    je eflags_next
;    
    cmp ch,0FFh
    je eflags_done
;    
    push di
    test ax,1
    jz eflags_pos_ok
;    
    add di,3

eflags_pos_ok:
    push ax
    mov cx,3
    call WriteString
    pop ax
    pop di

eflags_next:
    add di,6
    shr eax,1
    jmp eflags_loop
    
eflags_done:
    ret
WriteEflags    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteFault
;
;   DESCRIPTION:    Write fault string
;
;   PARAMETERS:     GS          TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ft_idt  DB 'Idt '
ft_ldt  DB 'Ldt '
ft_gdt  DB 'Gdt '

WriteFault     PROC near
    mov ax,cs
    mov es,ax
    mov eax,gs:p_fault_code
    test ax,2
    jz fault_not_idt
;    
    mov di,OFFSET ft_idt
    jmp write_fault_reason
    
fault_not_idt:
    mov di,OFFSET ft_gdt
    test ax,4
    jz write_fault_reason
;    
    mov di,OFFSET ft_ldt

write_fault_reason:
    mov cx,4
    call WriteString
;
    mov eax,gs:p_fault_code
    and ax,0FFF8h
    call WriteHexWord
    
write_fault_end:
    ret
WriteFault     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ABORT_PR
;
;   DESCRIPTION:    Abort app and display dump
;
;   PARAMETERS:     DS          Readable TSS for thread
;                   ES          Readable GDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_code_tab:
ke00    DB 'Divide error            '
ke01    DB 'Single step             '
ke02    DB 'NMI                     '
ke03    DB 'Breakpoint              '
ke04    DB 'Overflow                '
ke05    DB 'Array bounds error      '
ke06    DB 'Invalid OP-code         '
ke07    DB '80387 not present       '
ke08    DB 'Double fault            '
ke09    DB '80387 overrun           '
ke0A    DB 'Invalid TSS             '
ke0B    DB 'Segment not present     '
ke0C    DB 'Stack fault             '
ke0D    DB 'Protection fault        '
ke0E    DB 'Page fault              '
ke0F    DB 'Unknown Fault           '
ke10    DB '80387 error             '
ke11    DB 'Cannot emulate          '
ke12    DB 'Cannot emulate 80387    '
ke13    DB 'Now in real mode        '
ke14    DB '----------------------- '
ke15    DB 'Illegal int request     '
ke16    DB 'Undefined method        '
ke17    DB 'Invalid handle          '
ke18    DB 'Invalid selector        '

dword_reg_tab1:
    DB 'EAX='
    DW OFFSET p_rax
    DB 'EBX='
    DW OFFSET p_rbx
    DB 'ECX='
    DW OFFSET p_rcx
    DB 'EDX='
    DW OFFSET p_rdx
    DB 'ESI='
    DW OFFSET p_rsi
    DB 'EDI='
    DW OFFSET p_rdi
    DB 0
dword_reg_tab2:
    DB 'EPC='
    DW OFFSET p_rip
    DB 'ESP='
    DW OFFSET p_rsp
    DB 'EBP='
    DW OFFSET p_rbp
    DB 0

word_reg_tab:
    DB 'CS='
    DW OFFSET p_cs
    DB 'SS='
    DW OFFSET p_ss
    DB 'DS='
    DW OFFSET p_ds
    DB 'ES='
    DW OFFSET p_es
    DB 'FS='
    DW OFFSET p_fs
    DB 'GS='
    DW OFFSET p_gs
    DB 0

pm_es   EQU -16

abort_pretask:
    cli
    cld
;
    mov bx,ss
    cmp bx,gdt_sel
    jne abort_norm_pretask
;
    push bp
    mov bp,sp
    mov bx,[bp+4]
    cmp bx,device_code_sel
    pop bp
    jnz abort_norm_pretask
;
    push es
    movzx bx,al
    mov ax,system_data_sel
    mov es,ax
    mov eax,[bp+2]
    mov es:p_fault_code,eax
    mov eax,[bp+6]
    mov dword ptr es:p_rip,eax
    mov eax,[bp+14]
    mov dword ptr es:p_rflags,eax
    mov eax,[bp-4]
    mov dword ptr es:p_rax,eax
    mov dword ptr es:p_rcx,ecx
    mov dword ptr es:p_rdx,edx
    mov eax,[bp-8]
    mov dword ptr es:p_rbx,eax
    movzx eax,bp
    add eax,18
    mov dword ptr es:p_rsp,eax
    mov dword ptr es:p_rsi,esi
    mov dword ptr es:p_rdi,edi
    mov ax,[bp+10]
    mov es:p_cs,ax
    mov es:p_ss,ss
    mov ax,[bp-10]
    mov es:p_ds,ax
    pop ax
    mov es:p_es,ax
    mov es:p_fs,fs
    mov es:p_gs,gs
    mov bp,[bp]
    mov dword ptr es:p_rbp,ebp
    sldt ax
    mov es:p_ldt,ax       
    mov ax,es
    mov gs,ax
    jmp abort_fatal_write

abort_norm_pretask:        
    mov ax,system_data_sel
    mov ds,ax
    mov ax,1
    xchg ax,ds:shut_spinlock
    or ax,ax
    jz abort_pretask_do

abort_pretask_block:
    jmp abort_pretask_block    

abort_pretask_do:    
    push es
    movzx bx,byte ptr [ebp].trap_exc_nr
;
    mov ax,system_data_sel
    mov es,ax
    mov eax,[ebp].trap_err
    mov es:p_fault_code,eax
    mov eax,[ebp].trap_eip
    mov dword ptr es:p_rip,eax
    mov eax,[ebp].trap_eflags
    mov dword ptr es:p_rflags,eax
    mov eax,[ebp].trap_eax
    mov dword ptr es:p_rax,eax
    mov dword ptr es:p_rcx,ecx
    mov dword ptr es:p_rdx,edx
    mov eax,[ebp].trap_ebx
    mov dword ptr es:p_rbx,eax
    mov eax,ebp
    add eax,20
    mov dword ptr es:p_rsp,eax
    mov dword ptr es:p_rsi,esi
    mov dword ptr es:p_rdi,edi
    mov ax,[ebp].trap_cs
    mov es:p_cs,ax
    mov es:p_ss,ss
    mov ax,[ebp].trap_pds
    mov es:p_ds,ax
    pop ax
    mov es:p_es,ax
    mov es:p_fs,fs
    mov es:p_gs,gs
    mov ebp,[ebp].trap_ebp
    mov dword ptr es:p_rbp,ebp
    sldt ax
    mov es:p_ldt,ax       
    mov ax,es
    mov gs,ax

abort_fatal_write:
    mov eax,ds:efi_lfb
    or eax,ds:efi_lfb+4
    pop ax
    jnz abort_fatal_lfb

abort_fatal_text:
    push bx
    call GetTextBase
    mov es,bx
    xor di,di
    xor dx,dx
    mov cx,80*25
    xor ax,ax
    rep stosw
    pop bx
    jmp abort_fatal_do

abort_fatal_lfb:
    mov ax,system_data_sel
    mov ds,ax 
    mov ax,flat_sel
    mov es,ax
;
    call GetLfb
    mov cx,ds:efi_height

abort_clear_loop:
    push cx    
    mov ecx,ds:efi_scan_size    
    xor ax,ax
    rep stos byte ptr es:[edi]
    pop cx
    loop abort_clear_loop

abort_fatal_do:
    mov di,bx
    shl di,3
    mov ax,di
    add ax,ax
    add di,ax
    mov ax,cs
    mov es,ax
    add di,OFFSET error_code_tab
    mov cx,24
    call WriteString
; 
    add ds:efi_text_col,2
    call WriteFault
;    
    inc ds:efi_text_row
    mov ds:efi_text_col,0   
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET dword_reg_tab1
    call WriteDwordReg
;    
    inc ds:efi_text_row
    mov ds:efi_text_col,0   
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET dword_reg_tab2
    call WriteDwordReg    
    inc ds:efi_text_col
    call WriteEflags
;    
    inc ds:efi_text_row
    mov ds:efi_text_col,0   
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET word_reg_tab
    call WriteWordReg
    
halt_sys:
    hlt
    jmp halt_sys
    
abort_task:
    mov ax,wd_code_sel
    verr ax
    jnz abort_task_no_wd

abort_task_wd:
    FaultReset
    SoftReset

abort_task_no_wd:
    cli
    cld
;
    mov ax,system_data_sel
    mov ds,ax
    mov ax,1
    xchg ax,ds:shut_spinlock
    or ax,ax
    jz abort_task_do

abort_task_block:
    jmp abort_task_block    

abort_task_do:   
    mov eax,ds:efi_lfb
    or eax,ds:efi_lfb+4
    pop ax
    jnz abort_task_lfb

abort_task_text:
    mov ax,gdt_sel
    mov ds,ax
    mov bx,dosB800
    mov edx,[bx+2]
    and edx,0FFFFFFh
    mov eax,edx
    or al,7
    xor ebx,ebx
    SetPageEntry
;
    mov ecx,cr3
    mov cr3,ecx
;
    mov ax,dosB800
    mov es,ax
    xor di,di
    mov cx,80*25
    mov ax,0
    rep stosw
;
    xor dx,dx
    mov ax,system_data_sel
    mov ds,ax
    jmp remove_next_waiting

abort_task_lfb:
    mov ax,system_data_sel
    mov ds,ax 
    mov ax,flat_sel
    mov es,ax
;
    call GetLfb
    mov cx,ds:efi_height

abort_clear_lfb_loop:
    push cx    
    mov ecx,ds:efi_scan_size    
    xor ax,ax
    rep stos byte ptr es:[edi]
    pop cx
    loop abort_clear_lfb_loop

remove_next_waiting:
    mov si,OFFSET debug_list
    mov ax,[si]
    or ax,ax
    jz abort_system
;    
    push si
    mov es,[si]
    push di
    push ds
    mov di,es:p_prev
    cmp di,[si]
    mov [si],di
    mov si,es:p_next
    mov ds,di
    mov ds:p_next,si
    mov ds,si
    mov ds:p_prev,di
    pop ds
    pop di
    pop si
    jne not_empty_r
;    
    mov word ptr [si],0

not_empty_r:
    push si
    mov ax,es
    call WriteHexWord
;
    add ds:efi_text_col,2
    mov di,OFFSET thread_name
    mov cx,30
    call WriteString
;
    movzx di,es:p_fault_vector
    mov ax,es
    mov gs,ax
    shl di,3
    mov ax,di
    add ax,ax
    add di,ax
    mov ax,cs
    mov es,ax
    add di,OFFSET error_code_tab
    mov cx,24
    call WriteString
;    
    add ds:efi_text_col,2
    call WriteFault
;    
    inc ds:efi_text_row
    mov ds:efi_text_col,0   
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET dword_reg_tab1
    call WriteDwordReg
;    
    inc ds:efi_text_row
    mov ds:efi_text_col,0   
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET dword_reg_tab2
    call WriteDwordReg
    call WriteEflags
;    
    inc ds:efi_text_row
    mov ds:efi_text_col,0   
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET word_reg_tab
    call WriteWordReg
;    
    add ds:efi_text_row,2
    mov ds:efi_text_col,0   
    jmp remove_next_waiting

abort_system:
    hlt
    jmp abort_system

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateDataSelector
;
;           DESCRIPTION:    Create 32-bit data selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDataSelector       PROC near
    push ds
    push ax
    push bx
    push ecx
;
    mov ax,gdt_sel
    mov ds,ax
;
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_data32_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [bx+6],cx
    jmp create_data32_done

create_data32_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [bx+6],cx

create_data32_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
CreateDataSelector       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCodeSelector
;
;           DESCRIPTION:    Create 32-bit code selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateCodeSelector       PROC near
    push ds
    push ax
    push bx
    push ecx
;
    mov ax,gdt_sel
    mov ds,ax
;
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae create_code32_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [bx+6],cx
    jmp create_code32_done

create_code32_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [bx+6],cx

create_code32_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
CreateCodeSelector       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartDebug
;
;           DESCRIPTION:    Start debug device
;
;           PARAMETERS:     edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartDebug Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ecx,[edx].len
    sub ecx,SIZE rdos_header
    add edx,SIZE rdos_header
    mov esi,edx
    mov ebx,[esi].dev32_size
    mov edi,esi
    add edi,SIZE device32_header

sdParamLoop:
    mov al,[edi]
    inc edi
    or al,al
    jnz sdParamLoop
;       
    mov ecx,[esi].dev32_code_size
    add edx,ebx
    mov bx,[esi].dev32_code_sel
    mov bp,bx
    call CreateCodeSelector
;
    xor bx,bx
    add edx,ecx
    mov ecx,[esi].dev32_data_size
    or ecx,ecx
    jz sdDataSelOk
;
    mov bx,[esi].dev32_data_sel
    call CreateDataSelector

sdDataSelOk:
    mov edi,OFFSET switch_monitor
    mov ax,ds
    mov es,ax
    mov eax,[esi].dev32_init_ip
    mov ds,bx
    mov ebx,cs
    push ebx
    mov ebx,OFFSET sdRet
    push ebx
    push ebp
    push eax
    retf32

sdRet:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
StartDebug   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SearchDebugAdapter
;
;           DESCRIPTION:    Search for debug adapter
;
;           PARAMETERS:     edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SearchDebugAdapter Proc near
    push ds
    push ax
    push bx
    push edx
    mov ax,flat_sel
    mov ds,ax

sdaLoop:
    mov ax,[edx].typ
    cmp ax,RdosDevice32
    jne sdaNext
;       
    push edx
    add edx,SIZE rdos_header
    mov dx,[edx].dev32_code_sel
    cmp dx,kdebug_code_sel
    pop edx
    jne sdaNext
;    
    call StartDebug

sdaNext:
    cmp ax,RdosEnd
    je sdaDone
;    
    add edx,[edx].len
    jmp sdaLoop

sdaDone:
    pop edx
    pop bx
    pop ax
    pop ds
    ret
SearchDebugAdapter Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SearchDebug
;
;           DESCRIPTION:    Search for debug
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SearchDebug     Proc near
    push ds
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters

sdAdapterLoop:
    mov edx,[bx].adapter_base
    call SearchDebugAdapter
    add bx,SIZE adapter_typ
    loop sdAdapterLoop   
;
    popad
    pop ds
    ret
SearchDebug     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    Initialize module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    mov ds:efi_text_col,0
    mov ds:efi_text_row,0
;
    mov ax,gdt_sel
    mov ds,ax
;
    mov bx,shutdown_pretask_gate
    mov word ptr ds:[bx],OFFSET abort_pretask
    mov ds:[bx+2],cs
    mov word ptr ds:[bx+4],8400h
    mov word ptr ds:[bx+6],0
;
    mov bx,shutdown_task_gate
    mov word ptr ds:[bx],OFFSET abort_task
    mov ds:[bx+2],cs
    mov word ptr ds:[bx+4],8400h
    mov word ptr ds:[bx+6],0
;
    call SearchDebug    
    ret
init    Endp

code    ENDS

.186

END init
