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
; CRASHDEB.ASM
; Crash debugger/monitor module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\pcdev\key.inc
INCLUDE port.def
INCLUDE proc.inc

data    SEGMENT byte public 'DATA'

curr_num        DW ?

debug_core      DW ?
debug_active    DW ?

curr_row        DW ?
curr_col        DW ?

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

StopSys Macro
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownTask
        Endm

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn InitCrashKeyboard:near
    extrn GetCrashKey:near

    extrn InitCrashShow:near
    extrn ShowCrashCore:near

    extrn LocalOsGate:near
    extrn LocalUserGate:near
    
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
;           NAME:           InitVideo
;
;           DESCRIPTION:    Init video adapter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitVideo Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;    
    mov ax,process_page_sel
    mov ds,ax
    xor bx,bx
    mov eax,7
    mov ds:[bx],eax
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
    ret
InitVideo   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowMarker
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowMarker Proc near
    push ds
    push es
    push ax
    push dx
    push di
;
    mov di,__B800
    mov es,di
;    
    mov di,SEG data
    mov ds,di
;
    mov ax,ds:curr_row
    mov dx,80
    mul dx
    add ax,ds:curr_col
    add ax,ax
    mov di,ax
    inc di
    mov al,70h
    stosb
;
    pop di
    pop dx
    pop ax
    pop es
    pop ds    
    ret
ShowMarker Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HideMarker
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HideMarker Proc near
    push ds
    push es
    push ax
    push dx
    push di
;
    mov di,__B800
    mov es,di
;    
    mov di,SEG data
    mov ds,di
;
    mov ax,ds:curr_row
    mov dx,80
    mul dx
    add ax,ds:curr_col
    add ax,ax
    mov di,ax
    inc di
    mov al,7
    stosb
;
    pop di
    pop dx
    pop ax
    pop es
    pop ds    
    ret
HideMarker Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   exec table structure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

exec_s  STRUC

exec_row    DW ?
exec_col    DW ?
exec_size   DW ?
exec_reg    DW ?
exec_inc    DW ?
exec_dec    DW ?
exec_set    DW ?

exec_s  ENDS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ignore
;
;           DESCRIPTION:    Ignore
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ignore  Proc near
    ret
ignore  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_reg_byte
;
;           DESCRIPTION:    Perform inc on byte in core reg
;
;           PARAMETERS:     GS      Core state
;                           SI      Register offset
;                           BX      Table entry
;                           CX      Digit #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_reg_byte    Proc near
    mov ax,cs:[bx].exec_size
    sub ax,cx
    dec ax
    mov cl,al
    shl cl,2
    mov edx,0Fh
    shl edx,cl
;    
    mov eax,gs:[si]
    and eax,edx
    shr eax,cl
    inc al
    and al,0Fh
    shl eax,cl
    not edx
    and edx,gs:[si]
    or eax,edx
    mov gs:[si],eax
    ret
inc_reg_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_reg_byte
;
;           DESCRIPTION:    Perform dec on byte in core reg
;
;           PARAMETERS:     GS      Core state
;                           SI      Register offset
;                           BX      Table entry
;                           CX      Digit #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_reg_byte    Proc near
    mov ax,cs:[bx].exec_size
    sub ax,cx
    dec ax
    mov cl,al
    shl cl,2
    mov edx,0Fh
    shl edx,cl
;    
    mov eax,gs:[si]
    and eax,edx
    shr eax,cl
    dec al
    and al,0Fh
    shl eax,cl
    not edx
    and edx,gs:[si]
    or eax,edx
    mov gs:[si],eax
    ret
dec_reg_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_reg4
;
;           DESCRIPTION:    Perform dword inc on core reg
;
;           PARAMETERS:     GS      Core state
;                           SI      Register offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_reg4    Proc near
    inc dword ptr gs:[si]
    ret
inc_reg4  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_reg4
;
;           DESCRIPTION:    Perform dword dec on core reg
;
;           PARAMETERS:     GS      Core state
;                           SI      Register offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_reg4    Proc near
    dec dword ptr gs:[si]
    ret
dec_reg4  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_reg_byte
;
;           DESCRIPTION:    Perform set on core reg
;
;           PARAMETERS:     GS      Core state
;                           SI      Register offset
;                           BX      Table entry
;                           AL      Value to set
;                           CX      Digit number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_reg_byte    Proc near
    mov dx,cs:[bx].exec_size
    sub dx,cx
    dec dx
    mov cl,dl
    shl cl,2
    mov edx,0Fh
    shl edx,cl
    not edx
    and edx,gs:[si]
    movzx eax,al
    shl eax,cl
    or eax,edx
    mov gs:[si],eax
    inc ds:curr_col
    ret
set_reg_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ExecFunc
;
;           DESCRIPTION:    Execute function
;
;           PARAMETERS:     DI      Function callback
;                           AL      Param
;                           GS      Core state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
exec_table:
meax  exec_s <4,  1,  3, OFFSET cs_eax,  OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
deax  exec_s <4,  5,  8, OFFSET cs_eax,  OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mebx  exec_s <4,  14, 3, OFFSET cs_ebx,  OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
debx  exec_s <4,  18, 8, OFFSET cs_ebx,  OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mecx  exec_s <4,  27, 3, OFFSET cs_ecx,  OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
decx  exec_s <4,  31, 8, OFFSET cs_ecx,  OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
medx  exec_s <4,  40, 3, OFFSET cs_edx,  OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
dedx  exec_s <4,  44, 8, OFFSET cs_edx,  OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mesi  exec_s <5,  1,  3, OFFSET cs_esi,  OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
desi  exec_s <5,  5,  8, OFFSET cs_esi,  OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
medi  exec_s <5,  14, 3, OFFSET cs_edi,  OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
dedi  exec_s <5,  18, 8, OFFSET cs_edi,  OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mesp  exec_s <5,  27, 3, OFFSET cs_esp,  OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
desp  exec_s <5,  31, 8, OFFSET cs_esp,  OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mebp  exec_s <5,  40, 3, OFFSET cs_ebp,  OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
debp  exec_s <5,  44, 8, OFFSET cs_ebp,  OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
meip  exec_s <6,  1,  3, OFFSET cs_eip,  OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
deip  exec_s <6,  5,  8, OFFSET cs_eip,  OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dtr   exec_s <7,  4,  4, OFFSET cs_tr,   OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dldt  exec_s <8,  4,  4, OFFSET cs_ldt,  OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dcs   exec_s <9,  4,  4, OFFSET cs_cs,   OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dds   exec_s <10, 4,  4, OFFSET cs_ds,   OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
des   exec_s <11, 4,  4, OFFSET cs_es,   OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dfs   exec_s <12, 4,  4, OFFSET cs_fs,   OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dgs   exec_s <13, 4,  4, OFFSET cs_gs,   OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dss   exec_s <14, 4,  4, OFFSET cs_ss,   OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dus   exec_s <15, 4,  4, OFFSET cs_usel, OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
duss  exec_s <21, 0,  4, OFFSET cs_usel, OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
duso  exec_s <21, 5,  8, OFFSET cs_uoffs,OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dend DW     0FFFFh, 0FFFFh

ExecFunc    Proc near
    mov bx,OFFSET exec_table

d_c_loop:
    mov cx,cs:[bx].exec_row
    cmp cx,0FFFFh
    je d_c_end
;    
    cmp cx,ds:curr_row
    jne not_this_entry
;
    mov cx,ds:curr_col
    sub cx,cs:[bx].exec_col
    jc not_this_entry
;    
    cmp cx,cs:[bx].exec_size
    jnc not_this_entry
;    
    mov si,cs:[bx].exec_reg
    call word ptr cs:[bx+di]
    jmp d_c_end
    
not_this_entry:
    add bx,SIZE exec_s
    jmp d_c_loop
    
d_c_end:
    ret
ExecFunc  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_func
;
;           DESCRIPTION:    Inc function
;
;           PARAMETERS:     GS      Core state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_func    Proc near
    pushad
    mov di,OFFSET exec_inc
    call ExecFunc
    popad
    ret
inc_func    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_func
;
;           DESCRIPTION:    Dec function
;
;           PARAMETERS:     GS      Core state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_func    Proc near
    pushad
    mov di,OFFSET exec_dec
    call ExecFunc
    popad
    ret
dec_func    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_func
;
;           DESCRIPTION:    Set function
;
;           PARAMETERS:     AL      Value
;                           GS      Core state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_func    Proc near
    pushad
    mov di,OFFSET exec_set
    call ExecFunc
    popad
    ret
set_func    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setx_func
;
;           DESCRIPTION:    Set functions
;
;           PARAMETERS:     GS      Core state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set0_func   Proc near
    mov al,0
    call set_func
    ret
set0_func   Endp

set1_func   Proc near
    mov al,1
    call set_func
    ret
set1_func   Endp

set2_func   Proc near
    mov al,2
    call set_func
    ret
set2_func   Endp

set3_func   Proc near
    mov al,3
    call set_func
    ret
set3_func   Endp

set4_func   Proc near
    mov al,4
    call set_func
    ret
set4_func   Endp

set5_func   Proc near
    mov al,5
    call set_func
    ret
set5_func   Endp

set6_func   Proc near
    mov al,6
    call set_func
    ret
set6_func   Endp

set7_func   Proc near
    mov al,7
    call set_func
    ret
set7_func   Endp

set8_func   Proc near
    mov al,8
    call set_func
    ret
set8_func   Endp

set9_func   Proc near
    mov al,9
    call set_func
    ret
set9_func   Endp

setA_func   Proc near
    mov al,0Ah
    call set_func
    ret
setA_func   Endp

setB_func   Proc near
    mov al,0Bh
    call set_func
    ret
setB_func   Endp

setC_func   Proc near
    mov al,0Ch
    call set_func
    ret
setC_func   Endp

setD_func   Proc near
    mov al,0Dh
    call set_func
    ret
setD_func   Endp

setE_func   Proc near
    mov al,0Eh
    call set_func
    ret
setE_func   Endp

setF_func   Proc near
    mov al,0Fh
    call set_func
    ret
setF_func   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoFunc
;
;           DESCRIPTION:    Do a function
;
;           PARAMETERS:     AL      VK_KEY
;                           GS      Core state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

no_func Proc near
    ret
no_func Endp

trace_func  Proc near
    ret
trace_func  Endp

pace_func  Proc near
    ret
pace_func  Endp

go_func  Proc near
    ret
go_func  Endp

func_tab:
ft00   DW OFFSET no_func
ft01   DW OFFSET no_func
ft02   DW OFFSET no_func
ft03   DW OFFSET no_func
ft04   DW OFFSET no_func
ft05   DW OFFSET no_func
ft06   DW OFFSET no_func
ft07   DW OFFSET no_func
ft08   DW OFFSET no_func
ft09   DW OFFSET no_func
ft0A   DW OFFSET no_func
ft0B   DW OFFSET no_func
ft0C   DW OFFSET no_func
ft0D   DW OFFSET no_func
ft0E   DW OFFSET no_func
ft0F   DW OFFSET no_func
ft10   DW OFFSET no_func
ft11   DW OFFSET no_func
ft12   DW OFFSET no_func
ft13   DW OFFSET no_func
ft14   DW OFFSET no_func
ft15   DW OFFSET no_func
ft16   DW OFFSET no_func
ft17   DW OFFSET no_func
ft18   DW OFFSET no_func
ft19   DW OFFSET no_func
ft1A   DW OFFSET no_func
ft1B   DW OFFSET no_func
ft1C   DW OFFSET no_func
ft1D   DW OFFSET no_func
ft1E   DW OFFSET no_func
ft1F   DW OFFSET no_func
ft20   DW OFFSET no_func
ft21   DW OFFSET no_func
ft22   DW OFFSET no_func
ft23   DW OFFSET no_func
ft24   DW OFFSET no_func
ft25   DW OFFSET no_func
ft26   DW OFFSET no_func
ft27   DW OFFSET no_func
ft28   DW OFFSET no_func
ft29   DW OFFSET no_func
ft2A   DW OFFSET no_func
ft2B   DW OFFSET no_func
ft2C   DW OFFSET no_func
ft2D   DW OFFSET no_func
ft2E   DW OFFSET no_func
ft2F   DW OFFSET no_func
ft30   DW OFFSET set0_func
ft31   DW OFFSET set1_func
ft32   DW OFFSET set2_func
ft33   DW OFFSET set3_func
ft34   DW OFFSET set4_func
ft35   DW OFFSET set5_func
ft36   DW OFFSET set6_func
ft37   DW OFFSET set7_func
ft38   DW OFFSET set8_func
ft39   DW OFFSET set9_func
ft3A   DW OFFSET no_func
ft3B   DW OFFSET no_func
ft3C   DW OFFSET no_func
ft3D   DW OFFSET no_func
ft3E   DW OFFSET no_func
ft3F   DW OFFSET no_func
ft40   DW OFFSET no_func
ft41   DW OFFSET setA_func
ft42   DW OFFSET setB_func
ft43   DW OFFSET setC_func
ft44   DW OFFSET setD_func
ft45   DW OFFSET setE_func
ft46   DW OFFSET setF_func
ft47   DW OFFSET go_func
ft48   DW OFFSET no_func
ft49   DW OFFSET no_func
ft4A   DW OFFSET no_func
ft4B   DW OFFSET no_func
ft4C   DW OFFSET no_func
ft4D   DW OFFSET no_func
ft4E   DW OFFSET no_func
ft4F   DW OFFSET no_func
ft50   DW OFFSET pace_func
ft51   DW OFFSET no_func
ft52   DW OFFSET no_func
ft53   DW OFFSET no_func
ft54   DW OFFSET trace_func
ft55   DW OFFSET no_func
ft56   DW OFFSET no_func
ft57   DW OFFSET no_func
ft58   DW OFFSET no_func
ft59   DW OFFSET no_func
ft5A   DW OFFSET no_func
ft5B   DW OFFSET no_func
ft5C   DW OFFSET no_func
ft5D   DW OFFSET no_func
ft5E   DW OFFSET no_func
ft5F   DW OFFSET no_func
ft60   DW OFFSET no_func
ft61   DW OFFSET setA_func
ft62   DW OFFSET setB_func
ft63   DW OFFSET setC_func
ft64   DW OFFSET setD_func
ft65   DW OFFSET setE_func
ft66   DW OFFSET setF_func
ft67   DW OFFSET go_func
ft68   DW OFFSET no_func
ft69   DW OFFSET no_func
ft6A   DW OFFSET no_func
ft6B   DW OFFSET inc_func
ft6C   DW OFFSET no_func
ft6D   DW OFFSET dec_func
ft6E   DW OFFSET no_func
ft6F   DW OFFSET no_func
ft70   DW OFFSET pace_func
ft71   DW OFFSET no_func
ft72   DW OFFSET no_func
ft73   DW OFFSET no_func
ft74   DW OFFSET trace_func
ft75   DW OFFSET no_func
ft76   DW OFFSET no_func
ft77   DW OFFSET no_func
ft78   DW OFFSET no_func
ft79   DW OFFSET no_func
ft7A   DW OFFSET no_func
ft7B   DW OFFSET no_func
ft7C   DW OFFSET no_func
ft7D   DW OFFSET no_func
ft7E   DW OFFSET no_func
ft7F   DW OFFSET no_func
ft80   DW OFFSET no_func
ft81   DW OFFSET no_func
ft82   DW OFFSET no_func
ft83   DW OFFSET no_func
ft84   DW OFFSET no_func
ft85   DW OFFSET no_func
ft86   DW OFFSET no_func
ft87   DW OFFSET no_func
ft88   DW OFFSET no_func
ft89   DW OFFSET no_func
ft8A   DW OFFSET no_func
ft8B   DW OFFSET no_func
ft8C   DW OFFSET no_func
ft8D   DW OFFSET no_func
ft8E   DW OFFSET no_func
ft8F   DW OFFSET no_func
ft90   DW OFFSET no_func
ft91   DW OFFSET no_func
ft92   DW OFFSET no_func
ft93   DW OFFSET no_func
ft94   DW OFFSET no_func
ft95   DW OFFSET no_func
ft96   DW OFFSET no_func
ft97   DW OFFSET no_func
ft98   DW OFFSET no_func
ft99   DW OFFSET no_func
ft9A   DW OFFSET no_func
ft9B   DW OFFSET no_func
ft9C   DW OFFSET no_func
ft9D   DW OFFSET no_func
ft9E   DW OFFSET no_func
ft9F   DW OFFSET no_func
ftA0   DW OFFSET no_func
ftA1   DW OFFSET no_func
ftA2   DW OFFSET no_func
ftA3   DW OFFSET no_func
ftA4   DW OFFSET no_func
ftA5   DW OFFSET no_func
ftA6   DW OFFSET no_func
ftA7   DW OFFSET no_func
ftA8   DW OFFSET no_func
ftA9   DW OFFSET no_func
ftAA   DW OFFSET no_func
ftAB   DW OFFSET no_func
ftAC   DW OFFSET no_func
ftAD   DW OFFSET no_func
ftAE   DW OFFSET no_func
ftAF   DW OFFSET no_func
ftB0   DW OFFSET no_func
ftB1   DW OFFSET no_func
ftB2   DW OFFSET no_func
ftB3   DW OFFSET no_func
ftB4   DW OFFSET no_func
ftB5   DW OFFSET no_func
ftB6   DW OFFSET no_func
ftB7   DW OFFSET no_func
ftB8   DW OFFSET no_func
ftB9   DW OFFSET no_func
ftBA   DW OFFSET no_func
ftBB   DW OFFSET no_func
ftBC   DW OFFSET no_func
ftBD   DW OFFSET no_func
ftBE   DW OFFSET no_func
ftBF   DW OFFSET no_func
ftC0   DW OFFSET no_func
ftC1   DW OFFSET no_func
ftC2   DW OFFSET no_func
ftC3   DW OFFSET no_func
ftC4   DW OFFSET no_func
ftC5   DW OFFSET no_func
ftC6   DW OFFSET no_func
ftC7   DW OFFSET no_func
ftC8   DW OFFSET no_func
ftC9   DW OFFSET no_func
ftCA   DW OFFSET no_func
ftCB   DW OFFSET no_func
ftCC   DW OFFSET no_func
ftCD   DW OFFSET no_func
ftCE   DW OFFSET no_func
ftCF   DW OFFSET no_func
ftD0   DW OFFSET no_func
ftD1   DW OFFSET no_func
ftD2   DW OFFSET no_func
ftD3   DW OFFSET no_func
ftD4   DW OFFSET no_func
ftD5   DW OFFSET no_func
ftD6   DW OFFSET no_func
ftD7   DW OFFSET no_func
ftD8   DW OFFSET no_func
ftD9   DW OFFSET no_func
ftDA   DW OFFSET no_func
ftDB   DW OFFSET no_func
ftDC   DW OFFSET no_func
ftDD   DW OFFSET no_func
ftDE   DW OFFSET no_func
ftDF   DW OFFSET no_func
ftE0   DW OFFSET no_func
ftE1   DW OFFSET no_func
ftE2   DW OFFSET no_func
ftE3   DW OFFSET no_func
ftE4   DW OFFSET no_func
ftE5   DW OFFSET no_func
ftE6   DW OFFSET no_func
ftE7   DW OFFSET no_func
ftE8   DW OFFSET no_func
ftE9   DW OFFSET no_func
ftEA   DW OFFSET no_func
ftEB   DW OFFSET no_func
ftEC   DW OFFSET no_func
ftED   DW OFFSET no_func
ftEE   DW OFFSET no_func
ftEF   DW OFFSET no_func
ftF0   DW OFFSET no_func
ftF1   DW OFFSET no_func
ftF2   DW OFFSET no_func
ftF3   DW OFFSET no_func
ftF4   DW OFFSET no_func
ftF5   DW OFFSET no_func
ftF6   DW OFFSET no_func
ftF7   DW OFFSET no_func
ftF8   DW OFFSET no_func
ftF9   DW OFFSET no_func
ftFA   DW OFFSET no_func
ftFB   DW OFFSET no_func
ftFC   DW OFFSET no_func
ftFD   DW OFFSET no_func
ftFE   DW OFFSET no_func
ftFF   DW OFFSET no_func

DoFunc   PROC near
    movzx bx,al
    add bx,bx
    call word ptr cs:[bx].func_tab
    ret
DoFunc   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupFaultHandlers
;
;           DESCRIPTION:    Crash debugger fault handlers
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cint0:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,0
    push ax
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

cint4:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,4
    push ax
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

cint5:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,5
    push ax
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

cint6:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,6
    push ax
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

cint7:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,7
    push ax
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

cint8:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,8
    push ax
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

cint9:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,9
    push ax
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

cint10:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    push ds
    mov ax,10
    push ax
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

cint11:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,11
    push ax
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

cint12:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,12
    push ax
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

cint13:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,13
    push ax
    push ds
;
    test byte ptr [ebp+2].trap_eflags,2
    jnz c13_default
;
    mov ds,[ebp].trap_cs
    mov ebx,[ebp].trap_eip
    mov al,[ebx]
;
    cmp al,67h
    jne c13_default
;
    mov al,[ebx+2]
    cmp al,9Ah
    jne c13_default
;
    mov ax,[ebx+7]
    cmp ax,1
    je c13_user
;
    cmp ax,2
    je c13_os
;
    jmp c13_default

c13_user:
    jmp LocalUserGate

c13_os:
    jmp LocalOsGate

c13_default:
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

c13_retry:
    pop eax
    mov ds,ax
    pop ebx
    pop eax
    and byte ptr [ebp+2].trap_eflags, NOT 1
    pop ebp
    add esp,4
    iretd

cint16:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,16
    push ax
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
    ShutDownPreTask

hwint:
    iretd

crash_int_tab:
;
;               int #       Entry          
;
ci0     DW      0,          OFFSET cint0
ci4     DW      4,          OFFSET cint4
ci5     DW      5,          OFFSET cint5
ci6     DW      6,          OFFSET cint6
ci7     DW      7,          OFFSET cint7
ci8     DW      8,          OFFSET cint8
ci9     DW      9,          OFFSET cint9
ci10    DW      10,         OFFSET cint10
ci11    DW      11,         OFFSET cint11
ci12    DW      12,         OFFSET cint12
ci13    DW      13,         OFFSET cint13
ci16    DW      16,         OFFSET cint16
ci40    DW      40h,        OFFSET hwint
ci80    DW      80h,        OFFSET hwint
ci81    DW      81h,        OFFSET hwint
ci82    DW      82h,        OFFSET hwint
ci83    DW      83h,        OFFSET hwint
ci_end  DW      0FFFFh

SetupFaultHandlers      PROC near
    push ds
    pushad
;
    mov ax,cs
    mov ds,ax
    mov di,OFFSET crash_int_tab

init_fault_next:
    mov ax,[di]
    cmp ax,0FFFFh
    jz init_fault_done
;
    xor bl,bl
    movzx esi,word ptr [di+2]
    SetupIntGate
    add di,4
    jmp init_fault_next

init_fault_done:
    popad
    pop ds
    ret
SetupFaultHandlers      ENDP
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           Nmi
;
;               DESCRIPTION:    NMI handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nmi_gs  EQU 48
nmi_fs  EQU 44
nmi_ds  EQU 40
nmi_es  EQU 36
nmi_ss  EQU 32
nmi_esp EQU 28
nmi_efl EQU 24
nmi_cs  EQU 20
nmi_eip EQU 16
nmi_sfs EQU 14
nmi_sgs EQU 12
nmi_eax EQU 8
nmi_ebx EQU 4
nmi_ebp EQU 0

nmi_handler:
    push fs
    push gs
    push eax
    push ebx
    push ebp
    mov ebp,esp
;
    GetCore
    test fs:ps_flags,PS_FLAG_NMI
    jnz nmi_ret
;
    or fs:ps_flags,PS_FLAG_NMI    
    mov ax,fs
    mov gs,ax
;    
    call SaveCore
    mov gs:cs_fault,-1
    mov gs:cs_irq,0
;    
    mov eax,[ebp].nmi_ebp
    mov gs:cs_ebp,eax
    mov eax,[ebp].nmi_ebx
    mov gs:cs_ebx,eax
    mov eax,[ebp].nmi_eax
    mov gs:cs_eax,eax
    mov eax,[ebp].nmi_eip
    mov gs:cs_eip,eax
    mov ax,[ebp].nmi_cs
    mov gs:cs_cs,ax
    mov ebx,[ebp].nmi_efl
    mov gs:cs_eflags,ebx
    test ebx,20000h
    jnz nmi_v86
;    
    mov bx,[ebp].nmi_sfs
    mov gs:cs_fs,bx
    mov bx,[ebp].nmi_sgs
    mov gs:cs_gs,bx
;    
    and al,3
    or al,al
    jz nmi_kernel
;
    mov eax,[ebp].nmi_esp
    mov gs:cs_esp,eax
    mov ax,[ebp].nmi_ss
    mov gs:cs_ss,ax
    jmp nmi_block

nmi_kernel:
    mov eax,ebp
    add eax,nmi_esp
    mov gs:cs_esp,eax
    jmp nmi_block

nmi_v86:
    mov eax,[ebp].nmi_esp
    mov gs:cs_esp,eax
    mov ax,[ebp].nmi_ss
    mov gs:cs_ss,ax
    mov ax,[ebp].nmi_ds
    mov gs:cs_ds,ax
    mov ax,[ebp].nmi_es
    mov gs:cs_es,ax
    mov ax,[ebp].nmi_fs
    mov gs:cs_fs,ax
    mov ax,[ebp].nmi_gs
    mov gs:cs_gs,ax

nmi_block:
    jmp nmi_block

nmi_ret:
    pop ebp
    pop ebx
    pop eax
    pop gs
    pop fs
    iretd

   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           DelayMs
;
;               DESCRIPTION:    Delay that does not use multitasking functions
;
;       PARAMETERS:     AX      Delay in ms
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DelayMs Proc near
    pushad
;
    movzx eax,ax
    mov ecx,1193
    mul ecx
    mov ebx,eax
    or ebx,ebx
    jz dmDone
;
    mov ax,10h
    out TIMER_CONTROL,al
    jmp short $+2
;
    mov al,0FFh
    out TIMER0,al
    jmp short $+2
;    
    in al,TIMER0
    mov cl,al
    jmp short $+2
;
    xor edx,edx

dmLoop:    
    in al,TIMER0
    mov dl,cl
    mov cl,al
    sub dl,al
    sub ebx,edx
    jnc dmLoop    

dmDone:       
    popad
    ret
DelayMs Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           SaveCore
;
;               DESCRIPTION:    Save core state
;
;       PARAMETERS:     FS      Code selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveCore Proc near
    push eax
;    
    mov fs:cs_eax,eax
    mov fs:cs_ecx,ecx
    mov fs:cs_edx,edx
    mov fs:cs_ebx,ebx
    mov fs:cs_esp,esp
    mov fs:cs_ebp,ebp
    mov fs:cs_esi,esi
    mov fs:cs_edi,edi
;
    mov fs:cs_es,es
    mov fs:cs_cs,cs
    mov fs:cs_ss,ss
    mov fs:cs_ds,ds
    mov fs:cs_fs,fs
    mov fs:cs_gs,gs
;
    pushfd
    pop fs:cs_eflags
    mov fs:cs_eip, OFFSET SaveCore
;
    mov eax,cr0
    mov fs:cs_cr0,eax
    mov eax,cr2
    mov fs:cs_cr2,eax
    mov eax,cr3
    mov fs:cs_cr3,eax
    mov eax,cr4
    mov fs:cs_cr4,eax
;
    mov eax,dr0
    mov fs:cs_dr0,eax
    mov eax,dr1
    mov fs:cs_dr1,eax
    mov eax,dr2
    mov fs:cs_dr2,eax
    mov eax,dr3
    mov fs:cs_dr3,eax
    mov eax,dr7
    mov fs:cs_dr7,eax
;
    sldt fs:cs_ldt
    str fs:cs_tr
    sgdt fword ptr fs:cs_gdtr
    sidt fword ptr fs:cs_idtr
;
    pop eax
    ret
SaveCore Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CrashHandler
;
;           DESCRIPTION:    Crash handler
;
;           PARAMETERS:     GS      Core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CrashHandler:
;    call SetupBiosPic
;    call SetupBiosPit
;    call InitVideo
    call InitCrashShow
    call InitCrashKeyboard
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
;
    mov ax,SEG data
    mov ds,ax
    mov ds:curr_row,0
    mov ds:curr_col,0
;
    GetCore
    mov ax,fs
    mov gs,ax
    call ShowCrashCore
;
    sti
    mov ax,ds:curr_num
    GetCoreNumber
    mov ax,fs
    mov gs,ax
    GetCore
;    
    mov al,'R'
    jmp handle_func

handle_loop:
    call GetCrashKey
    jc handle_next
;    
    test ah,80h
    jnz handle_next
;    
    cmp al,25h
    je left_arrow
;
    cmp al,27h
    je right_arrow
;        
    cmp al,26h
    je up_arrow
;
    cmp al,28h
    je down_arrow
;        
    cmp al,'N'
    jne handle_func
;
    mov ax,ds:curr_num
    inc ax
    GetCoreNumber
    jnc handle_next_set
;
    xor ax,ax
    GetCoreNumber
        
handle_next_set:
    mov ds:curr_num,ax
    mov ax,fs
    mov gs,ax
    xor ax,ax

handle_func:
    call HideMarker
    call DoFunc
    call ShowCrashCore
    call ShowMarker
    jmp handle_next

handle_next:        
    jmp handle_loop


up_arrow:
    mov dx,ds:curr_row
    or dx,dx
    jz handle_loop
;    
    call HideMarker
    dec ds:curr_row
    call ShowMarker
    jmp handle_loop

down_arrow:
    mov dx,ds:curr_row
    cmp dx,24
    je handle_loop
;
    call HideMarker
    inc ds:curr_row
    call ShowMarker
    jmp handle_loop

left_arrow:
    mov dx,ds:curr_col
    or dx,dx
    jz handle_loop
;
    call HideMarker
    dec ds:curr_col
    call ShowMarker
    jmp handle_loop    

right_arrow:
    mov dx,ds:curr_col
    cmp dx,79
    je handle_loop
;
    call HideMarker
    inc ds:curr_col
    call ShowMarker
    jmp handle_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowHere
;
;           DESCRIPTION:    Show here
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowHere    Proc near
    push es
    push ax
    push di
;    
    mov di,__B800
    mov es,di
;
    mov di,2 * 80 * 23    
    mov ax,0731h
    stosw
    mov ax,0F32h
    stosw
;    
    pop di
    pop ax
    pop es
    ret
ShowHere    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnterHandler
;
;           DESCRIPTION:    Enter crash handler
;
;           RETURNS:        FS      Current processor
;                           CY      Chain to NMI
;                           NC
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnterHandler    Proc near 
    push ds
    push ax
;       
    cli
    mov ax,wd_code_sel
    verr ax
    jnz enter_do
;
    SoftReset

enter_do:
    mov ax,system_data_sel
    mov ds,ax
    mov ax,1
    xchg ax,ds:shut_spinlock
    or ax,ax
    jz enter_fault_do
;
    GetCore
    or fs:ps_flags,PS_FLAG_NMI
    stc
    jmp enter_done

enter_fault_do:
    mov ax,SEG data    
    mov ds,ax
;
    mov ax,ds:debug_core
    or ax,ax
    jz enter_first
;
    GetCore
    or fs:ps_flags,PS_FLAG_NMI
    stc
    jmp enter_done

enter_first:    
    DisableAllIrq    
    push eax
    sti
    GetCore
    or fs:ps_flags,PS_FLAG_NMI
    pop eax
    mov fs:cs_irq,eax
    mov fs:cs_fault,-1
;    
    mov ax,fs:ps_id
    mov ds:curr_num,ax
    mov ds:debug_core,fs
;
    push ds
    push es
    push bx
    push esi
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov al,2
    xor bl,bl
    mov esi,OFFSET nmi_handler
    SetupIntGate
;
    pop esi
    pop bx
    pop es
    pop ds    
;
    mov ax,5
    call DelayMs
;
    xor ax,ax

handle_int_loop:    
    GetCoreNumber
    jc handle_int_done
;
    test fs:ps_flags,PS_FLAG_NMI
    jnz handle_int_next
;        
    push ax
    mov al,2
    Sendint
    pop ax
    xor cx,cx    

handle_wait_int_loop:
    test fs:ps_flags,PS_FLAG_NMI
    jnz handle_int_next
;
    loop handle_wait_int_loop
        
handle_int_next:
    inc ax
    jmp handle_int_loop

handle_int_done:
    xor ax,ax

handle_nmi_loop:    
    GetCoreNumber
    jc handle_nmi_done
;
    test fs:ps_flags,PS_FLAG_NMI
    jnz handle_nmi_next
;        
    SendNmi
    xor cx,cx    

handle_wait_nmi_loop:
    test fs:ps_flags,PS_FLAG_NMI
    jnz handle_nmi_next
;
    loop handle_wait_nmi_loop
        
handle_nmi_next:
    inc ax
    jmp handle_nmi_loop

handle_nmi_done:
    call SetupFaultHandlers
    GetCore
    clc

enter_done:
    pop ax
    pop ds
    ret
EnterHandler    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartCrashCore
;
;           DESCRIPTION:    Start crash core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_crash_core_name    DB 'Start Crash Core', 0

start_crash_core:
    GetCore
    call SaveCore
;    
    call InitCrashKeyboard

start_crash_loop:
    call GetCrashKey
    jc start_crash_loop
;    
    test ah,80h
    jnz start_crash_loop
;    
    cmp al,1Bh
    jne start_crash_loop
;
    call EnterHandler
    jc start_crash_chain
;
    jmp CrashHandler

start_crash_chain:
    jmp nmi_block            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CrashGate
;
;           DESCRIPTION:    Crash with a gate
;
;           PARAMETERS:     CS:EIP on stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crash_gate_name    DB 'Crash Gate', 0

crash_gate:
    cli    
    push fs
    call EnterHandler
    jc crash_gate_chain
;
    call SaveCore    
    pop ax
    mov fs:cs_fs,ax
;    
    pop eax
    mov fs:cs_eip,eax
;
    pop eax
    mov fs:cs_cs,ax
    jmp CrashHandler

crash_gate_chain:
    call SaveCore    
    pop ax
    mov fs:cs_fs,ax
;    
    pop eax
    mov fs:cs_eip,eax
;
    pop eax
    mov fs:cs_cs,ax
    jmp nmi_block

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CrashFault
;
;           DESCRIPTION:    Crash with a fault stack
;
;           PARAMETERS:     SS:EBP      Fault context
;                           EAX         Fault ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crash_fault_name    DB 'Crash Fault', 0
    
crash_fault:
    cli    
    push eax
    push fs
    call EnterHandler
    jc crash_fault_chain
;
    call SaveCore    
    pop ax
    mov fs:cs_fs,ax
;
    pop eax    
    mov fs:cs_fault,eax
;
    mov ax,[ebp].trap_pds
    mov fs:cs_ds,ax
;    
    mov eax,[ebp].trap_eax
    mov fs:cs_eax,eax
;    
    mov eax,[ebp].trap_ebx
    mov fs:cs_ebx,eax
;
    mov eax,[ebp].trap_ebp
    mov fs:cs_ebp,eax
;    
    mov eax,[ebp].trap_eflags
    mov fs:cs_eflags,eax
;
    mov ax,[ebp].trap_cs
    mov fs:cs_cs,ax
;    
    mov eax,[ebp].trap_eip
    mov fs:cs_eip,eax
;
    test dword ptr [ebp].trap_eflags,20000h
    jnz crash_fault_vm

crash_fault_pm:
    mov al,[ebp].trap_cs
    test al,3
    jz crash_fault_kernel
;
    mov ax,[ebp].trap_ss
    mov fs:cs_ss,ax
;    
    mov eax,[ebp].trap_esp
    mov fs:cs_esp,eax
    jmp CrashHandler
    
crash_fault_kernel:
    mov eax,ebp
    add eax,trap_esp
    mov fs:cs_esp,eax
    jmp CrashHandler

crash_fault_vm:
    mov ax,[ebp].trap_gs
    mov fs:cs_gs,ax
;
    mov ax,[ebp].trap_fs
    mov fs:cs_fs,ax
;
    mov ax,[ebp].trap_ds
    mov fs:cs_ds,ax
;    
    mov ax,[ebp].trap_es
    mov fs:cs_es,ax
;    
    mov ax,[ebp].trap_ss
    mov fs:cs_ss,ax
;    
    mov eax,[ebp].trap_esp
    mov fs:cs_esp,eax
    jmp CrashHandler

crash_fault_chain:
    call SaveCore    
    pop ax
    mov fs:cs_fs,ax
;
    pop eax    
    mov fs:cs_fault,eax
;
    mov ax,[ebp].trap_pds
    mov fs:cs_ds,ax
;    
    mov eax,[ebp].trap_eax
    mov fs:cs_eax,eax
;    
    mov eax,[ebp].trap_ebx
    mov fs:cs_ebx,eax
;
    mov eax,[ebp].trap_ebp
    mov fs:cs_ebp,eax
;    
    mov eax,[ebp].trap_eflags
    mov fs:cs_eflags,eax
;
    mov ax,[ebp].trap_cs
    mov fs:cs_cs,ax
;    
    mov eax,[ebp].trap_eip
    mov fs:cs_eip,eax
;
    test dword ptr [ebp].trap_eflags,20000h
    jnz crash_fault_chain_vm

crash_fault_chain_pm:
    mov al,[ebp].trap_cs
    test al,3
    jz crash_fault_chain_kernel
;
    mov ax,[ebp].trap_ss
    mov fs:cs_ss,ax
;    
    mov eax,[ebp].trap_esp
    mov fs:cs_esp,eax
    jmp nmi_block
    
crash_fault_chain_kernel:
    mov eax,ebp
    add eax,trap_esp
    mov fs:cs_esp,eax
    jmp nmi_block

crash_fault_chain_vm:
    mov ax,[ebp].trap_gs
    mov fs:cs_gs,ax
;
    mov ax,[ebp].trap_fs
    mov fs:cs_fs,ax
;
    mov ax,[ebp].trap_ds
    mov fs:cs_ds,ax
;    
    mov ax,[ebp].trap_es
    mov fs:cs_es,ax
;    
    mov ax,[ebp].trap_ss
    mov fs:cs_ss,ax
;    
    mov eax,[ebp].trap_esp
    mov fs:cs_esp,eax
    jmp nmi_block


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CrashTss
;
;           DESCRIPTION:    Crash with a TSS
;
;           PARAMETERS:     DS      Readable TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crash_tss_name    DB 'Crash Tss', 0
    
crash_tss:
    call EnterHandler
    jc crash_tss_chain
;    
    mov ax,double_tss_data_sel
    mov ds,ax
    mov bx,word ptr ds:c_tss_back_link
    mov fs:cs_tr,bx
;
    mov ax,gdt_sel
    mov ds,ax
    and bx,0FFF8h
    xor ecx,ecx
    mov cl,[bx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[bx]
    inc ecx
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
;       
    AllocateGdt
    CreateDataSelector16
    mov ds,bx
    mov eax,ds:c_tss_eax
    mov fs:cs_eax,eax
;    
    mov eax,ds:c_tss_ecx
    mov fs:cs_ecx,eax
;
    mov eax,ds:c_tss_edx
    mov fs:cs_edx,eax
;
    mov eax,ds:c_tss_ebx
    mov fs:cs_ebx,eax
;
    mov eax,ds:c_tss_esp    
    mov fs:cs_esp,eax
;
    mov eax,ds:c_tss_ebp    
    mov fs:cs_ebp,eax
;    
    mov eax,ds:c_tss_esi
    mov fs:cs_esi,eax
;
    mov eax,ds:c_tss_edi    
    mov fs:cs_edi,eax
;    
    mov ax,ds:c_tss_es
    mov fs:cs_es,ax
;
    mov ax,ds:c_tss_cs    
    mov fs:cs_cs,ax
;    
    mov ax,ds:c_tss_ss
    mov fs:cs_ss,ax
;
    mov ax,ds:c_tss_ds    
    mov fs:cs_ds,ax
;
    mov ax,ds:c_tss_fs    
    mov fs:cs_fs,ax
;
    mov ax,ds:c_tss_gs    
    mov fs:cs_gs,ax    
;
    mov ax,ds:c_tss_ldt
    mov fs:cs_ldt,ax
;
    mov fs:cs_fault,8
;
    mov eax,ds:c_tss_eflags
    mov fs:cs_eflags,eax
;
    mov eax,cr0
    mov fs:cs_cr0,eax
    mov eax,cr2
    mov fs:cs_cr2,eax
    mov eax,cr3
    mov fs:cs_cr3,eax
    mov eax,cr4
    mov fs:cs_cr4,eax
;
    mov eax,dr0
    mov fs:cs_dr0,eax
    mov eax,dr1
    mov fs:cs_dr1,eax
    mov eax,dr2
    mov fs:cs_dr2,eax
    mov eax,dr3
    mov fs:cs_dr3,eax
    mov eax,dr7
    mov fs:cs_dr7,eax
;
    sgdt fword ptr fs:cs_gdtr
    sidt fword ptr fs:cs_idtr
    jmp CrashHandler

crash_tss_chain:    
    mov ax,double_tss_data_sel
    mov ds,ax
    mov bx,word ptr ds:c_tss_back_link
    mov fs:cs_tr,bx
;
    mov ax,gdt_sel
    mov ds,ax
    and bx,0FFF8h
    xor ecx,ecx
    mov cl,[bx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[bx]
    inc ecx
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
;       
    AllocateGdt
    CreateDataSelector16
    mov ds,bx
    mov eax,ds:c_tss_eax
    mov fs:cs_eax,eax
;    
    mov eax,ds:c_tss_ecx
    mov fs:cs_ecx,eax
;
    mov eax,ds:c_tss_edx
    mov fs:cs_edx,eax
;
    mov eax,ds:c_tss_ebx
    mov fs:cs_ebx,eax
;
    mov eax,ds:c_tss_esp    
    mov fs:cs_esp,eax
;
    mov eax,ds:c_tss_ebp    
    mov fs:cs_ebp,eax
;    
    mov eax,ds:c_tss_esi
    mov fs:cs_esi,eax
;
    mov eax,ds:c_tss_edi    
    mov fs:cs_edi,eax
;    
    mov ax,ds:c_tss_es
    mov fs:cs_es,ax
;
    mov ax,ds:c_tss_cs    
    mov fs:cs_cs,ax
;    
    mov ax,ds:c_tss_ss
    mov fs:cs_ss,ax
;
    mov ax,ds:c_tss_ds    
    mov fs:cs_ds,ax
;
    mov ax,ds:c_tss_fs    
    mov fs:cs_fs,ax
;
    mov ax,ds:c_tss_gs    
    mov fs:cs_gs,ax    
;
    mov ax,ds:c_tss_ldt
    mov fs:cs_ldt,ax
;
    mov fs:cs_fault,8
;
    mov eax,ds:c_tss_eflags
    mov fs:cs_eflags,eax
;
    mov eax,cr0
    mov fs:cs_cr0,eax
    mov eax,cr2
    mov fs:cs_cr2,eax
    mov eax,cr3
    mov fs:cs_cr3,eax
    mov eax,cr4
    mov fs:cs_cr4,eax
;
    mov eax,dr0
    mov fs:cs_dr0,eax
    mov eax,dr1
    mov fs:cs_dr1,eax
    mov eax,dr2
    mov fs:cs_dr2,eax
    mov eax,dr3
    mov fs:cs_dr3,eax
    mov eax,dr7
    mov fs:cs_dr7,eax
;
    sgdt fword ptr fs:cs_gdtr
    sidt fword ptr fs:cs_idtr
    jmp nmi_block

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init_crashdeb
;
;           DESCRIPTION:    Module initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_crashdeb
    
init_crashdeb    PROC near
    mov ax,SEG data
    mov ds,ax
    mov ds:debug_active,0
    mov ds:curr_num,0
    mov ds:debug_core,0
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET start_crash_core
    mov edi,OFFSET start_crash_core_name
    xor cl,cl
    mov ax,start_crash_core_nr
    RegisterOsGate
;
    mov esi,OFFSET crash_gate
    mov edi,OFFSET crash_gate_name
    xor cl,cl
    mov ax,crash_gate_nr
    RegisterOsGate
;
    mov esi,OFFSET crash_fault
    mov edi,OFFSET crash_fault_name
    xor cl,cl
    mov ax,crash_fault_nr
    RegisterOsGate
;
    mov esi,OFFSET crash_tss
    mov edi,OFFSET crash_tss_name
    xor cl,cl
    mov ax,crash_tss_nr
    RegisterOsGate
;
    ret
init_crashdeb    ENDP

code    ENDS

    END
