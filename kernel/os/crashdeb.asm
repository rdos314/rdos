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
INCLUDE irq.inc
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE proc.inc
INCLUDE crashdeb.inc

data    SEGMENT byte public 'DATA'

core_list       DW ?
curr_core       DW ?

curr_row        DW ?
curr_col        DW ?

set_val         DB ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn InitCrashKeyboardIrq:near
    extrn UpdateCrashKeyboardMode:near
    extrn GetCrashKey:near

    extrn InitCrashShow:near
    extrn ShowCrashCore:near

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
;
;           NAME:           do_inc
;
;           DESCRIPTION:    Perform inc
;
;           PARAMETERS:     GS      Core state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

do_inc    Proc near
    ret
do_inc  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_dec
;
;           DESCRIPTION:    Perform dec
;
;           PARAMETERS:     GS      Core state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

do_dec    Proc near
    ret
do_dec  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_set
;
;           DESCRIPTION:    Perform set
;
;           PARAMETERS:     GS      Core state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

do_set    Proc near
    ret
do_set  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           funcs
;
;           DESCRIPTION:    Register operators
;
;           PARAMETERS:     DI      Function callback
;                           CX      Offset within field
;                           GS      Core state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

incdec_eax  Proc near
    ret
incdec_eax  Endp

change_eax  Proc near
    ret
change_eax  Endp

incdec_ebx  Proc near
    ret
incdec_ebx  Endp

change_ebx  Proc near
    ret
change_ebx  Endp

incdec_ecx  Proc near
    ret
incdec_ecx  Endp

change_ecx  Proc near
    ret
change_ecx  Endp

incdec_edx  Proc near
    ret
incdec_edx  Endp

change_edx  Proc near
    ret
change_edx  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ExecFunc
;
;           DESCRIPTION:    Execute function
;
;           PARAMETERS:     DI      Function callback
;                           GS      Core state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_row       EQU 0
debug_col       EQU 2
debug_ant       EQU 4
debug_call      EQU 6
debug_size      EQU 8
    
;
;           row     col         size        action
;
exec_table:
meax DW     4,      1,          3,          OFFSET incdec_eax
deax DW     4,      5,          8,          OFFSET change_eax
mebx DW     4,      14,         3,          OFFSET incdec_ebx
debx DW     4,      18,         8,          OFFSET change_ebx
mecx DW     4,      27,         3,          OFFSET incdec_ecx
decx DW     4,      31,         8,          OFFSET change_ecx
medx DW     4,      40,         3,          OFFSET incdec_edx
dedx DW     4,      44,         8,          OFFSET change_edx
dend DW     0FFFFh, 0FFFFh

ExecFunc    Proc near
    mov bx,OFFSET exec_table

d_c_loop:
    mov cx,cs:[bx].debug_row
    cmp cx,0FFFFh
    je d_c_end
;    
    cmp cx,ds:curr_row
    jne not_this_entry
;
    mov cx,ds:curr_col
    sub cx,cs:[bx].debug_col
    jc not_this_entry
;    
    cmp cx,cs:[bx].debug_ant
    jnc not_this_entry
;    
    and cx,7
    call word ptr cs:[bx].debug_call
    jmp d_c_end
    
not_this_entry:
    add bx,debug_size
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
    mov di,OFFSET do_inc
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
    mov di,OFFSET do_dec
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
    mov ds:set_val,al
    mov di,OFFSET do_set
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
ft2B   DW OFFSET inc_func
ft2C   DW OFFSET no_func
ft2D   DW OFFSET dec_func
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
ft6B   DW OFFSET no_func
ft6C   DW OFFSET no_func
ft6D   DW OFFSET no_func
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
    mov bp,sp
;    
    GetProcessor
    test fs:ps_flags,PS_FLAG_NMI
    jnz nmi_ret
;
    or fs:ps_flags,PS_FLAG_NMI    
    mov ax,fs
    mov bx,SEG data    
    mov fs,bx
    mov bx,fs:core_list

nmi_core_loop:
    mov gs,bx
    cmp ax,gs:cs_proc_sel
    je nmi_core_found
;
    mov bx,gs:cs_next
    jmp nmi_core_loop    

nmi_core_found:
    call SaveCore
    mov eax,[bp].nmi_ebp
    mov gs:cs_ebp,eax
    mov eax,[bp].nmi_ebx
    mov gs:cs_ebx,eax
    mov eax,[bp].nmi_eax
    mov gs:cs_eax,eax
    mov eax,[bp].nmi_eip
    mov gs:cs_eip,eax
    mov ax,[bp].nmi_cs
    mov gs:cs_cs,ax
    mov ebx,[bp].nmi_efl
    mov gs:cs_eflags,ebx
    test ebx,20000h
    jnz nmi_v86
;    
    mov bx,[bp].nmi_sfs
    mov gs:cs_fs,bx
    mov bx,[bp].nmi_sgs
    mov gs:cs_gs,bx
;    
    and al,3
    or al,al
    jz nmi_kernel
;
    mov eax,[bp].nmi_esp
    mov gs:cs_esp,eax
    mov ax,[bp].nmi_ss
    mov gs:cs_ss,ax
    jmp nmi_block

nmi_kernel:
    movzx eax,bp
    add ax,nmi_esp
    mov gs:cs_esp,eax
    jmp nmi_block

nmi_v86:
    mov eax,[bp].nmi_esp
    mov gs:cs_esp,eax
    mov ax,[bp].nmi_ss
    mov gs:cs_ss,ax
    mov ax,[bp].nmi_ds
    mov gs:cs_ds,ax
    mov ax,[bp].nmi_es
    mov gs:cs_es,ax
    mov ax,[bp].nmi_fs
    mov gs:cs_fs,ax
    mov ax,[bp].nmi_gs
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
;       NAME:           abort_cores
;
;       DESCRIPTION:    Stop all cores except self
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

abort_cores:
    GetProcessor
    or fs:ps_flags,PS_FLAG_NMI    
    mov dx,fs
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:core_list

abort_loop:    
    or ax,ax
    jz nmi_block
;
    mov gs,ax
    mov ax,gs:cs_proc_sel
    cmp ax,dx
    jz abort_next
;    
    mov fs,ax
    SendNmi

abort_next:
    mov ax,gs:cs_next
    jmp abort_loop

   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           int 82
;
;       DESCRIPTION:    Shutdown interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int_gs  EQU 48
int_fs  EQU 44
int_ds  EQU 40
int_es  EQU 36
int_ss  EQU 32
int_esp EQU 28
int_efl EQU 24
int_cs  EQU 20
int_eip EQU 16
int_sfs EQU 14
int_sgs EQU 12
int_eax EQU 8
int_ebx EQU 4
int_ebp EQU 0

shutdown_handler:
    push fs
    push gs
    push eax
    push ebx
    push ebp
    mov bp,sp
;    
    GetProcessor
    mov ax,fs
    mov bx,SEG data    
    mov fs,bx
    mov bx,fs:core_list

int_core_loop:
    mov gs,bx
    cmp ax,gs:cs_proc_sel
    je int_core_found
;
    mov bx,gs:cs_next
    jmp int_core_loop    

int_core_found:
    call SaveCore
    mov eax,[bp].int_ebp
    mov gs:cs_ebp,eax
    mov eax,[bp].int_ebx
    mov gs:cs_ebx,eax
    mov eax,[bp].int_eax
    mov gs:cs_eax,eax
    mov eax,[bp].int_eip
    mov gs:cs_eip,eax
    mov ax,[bp].int_cs
    mov gs:cs_cs,ax
    mov ebx,[bp].int_efl
    mov gs:cs_eflags,ebx
    test ebx,20000h
    jnz int_v86
;    
    mov bx,[bp].int_sfs
    mov gs:cs_fs,bx
    mov bx,[bp].int_sgs
    mov gs:cs_gs,bx
;    
    and al,3
    or al,al
    jz int_kernel
;
    mov eax,[bp].int_esp
    mov gs:cs_esp,eax
    mov ax,[bp].int_ss
    mov gs:cs_ss,ax
    jmp abort_cores

int_kernel:
    movzx eax,bp
    add ax,int_esp
    mov gs:cs_esp,eax
    jmp abort_cores
    
int_v86:
    mov eax,[bp].int_esp
    mov gs:cs_esp,eax
    mov ax,[bp].int_ss
    mov gs:cs_ss,ax
    mov ax,[bp].int_ds
    mov gs:cs_ds,ax
    mov ax,[bp].int_es
    mov gs:cs_es,ax
    mov ax,[bp].int_fs
    mov gs:cs_fs,ax
    mov ax,[bp].int_gs
    mov gs:cs_gs,ax
    jmp abort_cores
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           int 83
;
;       DESCRIPTION:    Shutdown gate interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gt_fs  EQU 28
gt_efl EQU 24
gt_cs  EQU 20
gt_eip EQU 16
gt_sgs EQU 12
gt_eax EQU 8
gt_ebx EQU 4
gt_ebp EQU 0

shutdown_gate_handler:
    push fs
    push gs
    push eax
    push ebx
    push ebp
    mov bp,sp
;    
    GetProcessor
    mov ax,fs
    mov bx,SEG data    
    mov fs,bx
    mov bx,fs:core_list

gate_core_loop:
    mov gs,bx
    cmp ax,gs:cs_proc_sel
    je gate_core_found
;
    mov bx,gs:cs_next
    jmp gate_core_loop    

gate_core_found:
    call SaveCore
    mov bx,[bp].gt_ebp
;
    mov eax,ss:[bx].vm_eax
    mov gs:cs_eax,eax
    mov eax,ss:[bx].vm_ebx
    mov gs:cs_ebx,eax
;
    mov eax,ebp
    mov ax,ss:[bx]
    mov gs:cs_ebp,eax
;       
    mov eax,ss:[bx].vm_eflags
    mov gs:cs_eflags,eax
;    
    mov ax,ss:[bx].vm_cs
    mov gs:cs_cs,ax
;
    mov eax,ss:[bx].vm_eip
    mov gs:cs_eip,eax
;
    mov ax,bx
    add ax,vm_esp
    movzx eax,ax
    mov gs:cs_esp,eax
;       
    mov ax,ss:[bx].pm_ds
    mov gs:cs_ds,ax
;    
    mov bx,[bp].gt_fs
    mov gs:cs_fs,bx
;
    mov bx,[bp].gt_sgs
    mov gs:cs_gs,bx
    jmp abort_cores
   
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
    push ds
    push es
    pushad
;
    mov dx,system_data_sel
    mov ds,dx
    movzx eax,ax
    mov ecx,1193
    mul ecx
;        
    mov ecx,ds:apic_tics
    shl ecx,16
    mov cx,ds:apic_rest
    shl eax,16
    mul ecx
    inc edx
;
    mov ax,apic_mem_sel
    mov es,ax    
    mov es:APIC_INIT_COUNT,edx

dmLoop:
    mov eax,es:APIC_CURR_COUNT
    or eax,eax
    jnz dmLoop
;       
    popad
    pop es
    pop ds
    ret
DelayMs Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           SaveCore
;
;               DESCRIPTION:    Save core state
;
;       PARAMETERS:     GS      Code selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveCore Proc near
    push eax
;    
    mov gs:cs_eax,eax
    mov gs:cs_ecx,ecx
    mov gs:cs_edx,edx
    mov gs:cs_ebx,ebx
    mov gs:cs_esp,esp
    mov gs:cs_ebp,ebp
    mov gs:cs_esi,esi
    mov gs:cs_edi,edi
;
    mov gs:cs_es,es
    mov gs:cs_cs,cs
    mov gs:cs_ss,ss
    mov gs:cs_ds,ds
    mov gs:cs_fs,fs
    mov gs:cs_gs,gs
;
    pushfd
    pop gs:cs_eflags
    mov gs:cs_eip, OFFSET SaveCore
;
    mov eax,cr0
    mov gs:cs_cr0,eax
    mov eax,cr2
    mov gs:cs_cr2,eax
    mov eax,cr3
    mov gs:cs_cr3,eax
    mov eax,cr4
    mov gs:cs_cr4,eax
;
    mov eax,dr0
    mov gs:cs_dr0,eax
    mov eax,dr1
    mov gs:cs_dr1,eax
    mov eax,dr2
    mov gs:cs_dr2,eax
    mov eax,dr3
    mov gs:cs_dr3,eax
    mov eax,dr7
    mov gs:cs_dr7,eax
;
    sldt gs:cs_ldt
    str gs:cs_tr
    sgdt fword ptr gs:cs_gdtr
    sidt fword ptr gs:cs_idtr
;        
    pop eax
    ret
SaveCore Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddDebugCore
;
;           DESCRIPTION:    Add a new debug core
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_debug_core_name     DB 'Add Debug Core', 0

add_debug_core  Proc far
    push es
    push fs
    push gs
    pushad
;    
    mov eax,1000h
    AllocateGlobalMem
    mov ax,es
    mov gs,ax    
    mov gs:cs_usel,flat_sel
    mov gs:cs_uoffs,0
;
    GetProcessor
    mov gs:cs_proc_sel,fs    
;
    call SaveCore
;
    mov ax,SEG data
    mov es,ax
    mov ax,es:core_list
    mov gs:cs_next,ax
    mov es:core_list,gs
    mov es:curr_core,gs
;
    popad
    pop gs
    pop fs
    pop es
    ret
add_debug_core  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SmpDebug
;
;           DESCRIPTION:    SMP debug procedure
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_smp_debug_name    DB 'Start SMP Debug', 0

start_smp_debug:
    mov ax,250
    call DelayMs
;    
    call InitCrashShow
    call InitCrashKeyboardIrq
    sti
;
    mov ax,SEG data
    mov ds,ax
    mov ds:curr_row,0
    mov ds:curr_col,0
    mov gs,ds:core_list

handle_loop:
    hlt
    call GetCrashKey
    jc handle_next
;    
    test ah,80h
    jnz handle_next
;
    cmp al,1Bh
    je handle_abort
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
    mov ax,gs:cs_next
    or ax,ax
    jnz handle_next_set
;
    mov ax,ds:core_list

handle_next_set:
    mov gs,ax
    xor ax,ax

handle_func:
    call HideMarker
    call DoFunc
    call ShowCrashCore
    call ShowMarker
    jmp handle_next

handle_abort:
    mov ax,ds:core_list

handle_abort_loop:    
    or ax,ax
    jz handle_func
;
    mov gs,ax
    mov fs,gs:cs_proc_sel
    SendNmi
;
    mov ax,gs:cs_next
    jmp handle_abort_loop

handle_next:        
    call UpdateCrashKeyboardMode
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
;           NAME:           SmpDebThread
;
;           DESCRIPTION:    SMP debug thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

smp_deb_thread_name     DB 'SMP debug', 0

smp_deb_thread:
    int 3
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:core_list

smp_abort_loop:    
    or ax,ax
    jz smp_abort_done
;
    mov gs,ax
    mov fs,gs:cs_proc_sel
    SendNmi
;
    mov ax,gs:cs_next
    jmp smp_abort_loop

smp_abort_done:
    int 3 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_task
;
;           DESCRIPTION:    Init task
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_task     Proc far
    push ds
    push es
    pushad
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov si,OFFSET smp_deb_thread
    mov di,OFFSET smp_deb_thread_name
    mov ax,1
    mov cx,256
    CreateThread
;
    popad
    pop es
    pop ds
    ret
init_task     Endp

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
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov al,2
    xor bl,bl
    mov esi,OFFSET nmi_handler
    CreateIntGateSelector
;
    mov al,82h
    mov esi,OFFSET shutdown_handler
    CreateIntGateSelector
;
    mov al,83h
    mov esi,OFFSET shutdown_gate_handler
    CreateIntGateSelector
;
    mov esi,OFFSET start_smp_debug
    mov edi,OFFSET start_smp_debug_name
    xor cl,cl
    mov ax,start_smp_debug_nr
    RegisterOsGate
;
    mov esi,OFFSET add_debug_core
    mov edi,OFFSET add_debug_core_name
    xor cl,cl
    mov ax,add_debug_core_nr
    RegisterOsGate
;
;    mov di,OFFSET init_task
;    HookInitTasking
;
    AddDebugCore
;
    ret
init_crashdeb    ENDP

code    ENDS

    END
