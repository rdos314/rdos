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
; initvid.ASM
; Video reinitialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\user.def
INCLUDE ..\os.inc
INCLUDE ..\user.inc
INCLUDE protseg.def
INCLUDE system.def
INCLUDE port.def
INCLUDE ..\driver.def
INCLUDE system.inc

    .386p
    
code    SEGMENT byte use16 public 'CODE'

    assume cs:code
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           ProtEnterMode
;
;               DESCRIPTION:    Protected mode entry code for video switching
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0800. It should contain no near jumps!
    
prot_enter_start:
    mov ax,flat_sel
    mov ds,ax
    mov bx,0F80h
    mov eax,cr0
    mov ds:[bx].pm_cr0,eax
    mov eax,cr3
    mov ds:[bx].pm_cr3,eax
    mov eax,cr4
    mov ds:[bx].pm_cr4,eax
;    
    mov ds:[bx].pm_ss,ss
    mov ds:[bx].pm_sp,sp
    mov ds:[bx].pm_cs,cs
    sgdt fword ptr ds:[bx].pm_gdtr
    sidt fword ptr ds:[bx].pm_idtr
;    
    mov eax,cr0
    and eax,7FFFFFFFh
    mov cr0,eax
;
    mov bx,0F00h
    db 66h
    lgdt fword ptr ds:[bx]
;
    mov bx,0F20h
    db 66h
    lidt fword ptr ds:[bx]
;
    mov ax,8
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov ax,0F00h
    mov sp,ax
;
    mov eax,cr0
    and eax,NOT 1
    mov cr0,eax
;
    db 0EAh         ; jmp to real-mode selector
    dw 0
    dw 0A0h
              
prot_enter_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           ProtExitMode
;
;               DESCRIPTION:    Protected mode exit code for video switching
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0900. It should contain no near jumps!
    
prot_exit_start:
    mov bx,0F80h
    mov eax,ds:[bx].pm_cr3
    mov cr3,eax
    mov eax,ds:[bx].pm_cr4
    mov cr4,eax
    mov eax,ds:[bx].pm_cr0
    mov cr0,eax
;    
    db 66h
    lgdt fword ptr ds:[bx].pm_gdtr
    db 66h
    lidt fword ptr ds:[bx].pm_idtr
;
    mov ax,flat_sel
    mov ds,ax
;
    xor ax,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
;    
    mov ss,ds:[bx].pm_ss
    mov sp,ds:[bx].pm_sp
    retf
              
prot_exit_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           RealMode
;
;               DESCRIPTION:    Real mode code for video switching
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0A00. It should contain no near jumps!
    
real_start:
    mov ax,0A0h
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov sp,500h
;        
    mov ax,3
    int 10h
    cli
;
    mov al,-1
    out 21h,al
    jmp short $+2
;
    xor ax,ax
    mov ds,ax
    mov bx,0F00h
    lgdt fword ptr ds:[bx]    
;
    mov eax,cr0
    or eax,1
    mov cr0,eax
;    
    db 0EAh         ; jmp to protected mode
    dw 0
    dw 18h
              
real_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           Tables
;
;               DESCRIPTION:    GDT for real-mode switching
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0000:0F00h

table_start:

gdt0:
    dw 20h-1        ; real mode GDT
    dd 00000F00h
    dw 0
gdt8:               ; 16-bit data selector for real mode
    dw 0FFFFh
    dd 92000000h
    dw 0
gdt10:              ; 16-bit code selector for real mode
    dw 0FFFFh
    dd 9A000A00h
    dw 0
gdt18:              ; code selector for protected mode
    dw 3FFh
    dd 9A000900h
    dw 0
idt20:              ; real mode IDT
    dw 3FFh
    dd 00000000h
    dw 0

table_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           Protected mode settings
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 00F80h.

pmode_struc  STRUC

pm_cs   DW ?
pm_ss   DW ?
pm_sp   DW ?
pm_cr0  DD ?
pm_cr3  DD ?
pm_cr4  DD ?
pm_gdtr DB 6 DUP(?)
pm_idtr DB 6 DUP(?)

pmode_struc  ENDS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitVideo
;
;           DESCRIPTION:    Init video adapter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_video_name  DB 'Init Video', 0

init_video Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;    
    xor edx,edx
    xor ebx,ebx
    mov eax,7
    SetPageEntry
;
    mov eax,cr3
    mov cr3,eax
;
    mov ax,cs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;    
    mov di,800h
    mov si,OFFSET prot_enter_start
    mov cx,OFFSET prot_enter_end - OFFSET prot_enter_start
    rep movsb
;    
    mov di,900h
    mov si,OFFSET prot_exit_start
    mov cx,OFFSET prot_exit_end - OFFSET prot_exit_start
    rep movsb
;    
    mov di,0A00h
    mov si,OFFSET real_start
    mov cx,OFFSET real_end - OFFSET real_start
    rep movsb
;    
    mov di,0F00h
    mov si,OFFSET table_start
    mov cx,OFFSET table_end - OFFSET table_start
    rep movsb
;
    mov bx,temp_sel
    mov edx,800h
    mov ecx,10000h
    CreateCodeSelector16
;
    db 9Ah          ; call far temp_sel:0
    dw 0
    dw temp_sel
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
    retf32
init_video   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_video_module
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_video_module

init_video_module    PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET init_video
    mov edi,OFFSET init_video_name
    mov ax,init_video_nr
    RegisterOsGate
    ret
init_video_module    ENDP

code    ENDS

    END
