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
; WD.ASM
; Software watchdog support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
GateSize = 16

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def
INCLUDE ..\..\kernel\os\state.def

FAULT_SIGN  EQU 0AC92BE63h

fault_sector_seg STRUC

fss_sign                DD ?
fss_state               state_struc <>
fss_tss                 tss_seg <>

fault_sector_seg ENDS


data    SEGMENT byte public 'DATA'

wd_tics                 DD ?

fault_disc              DB ?
fault_start_sector      DD ?
fault_sectors           DD ?

data    ENDS

        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   WdTimeout
;
;               DESCRIPTION:    Watchdog timeout - do reset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WdTimeout:
    CpuReset
    jmp WdTimeout

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   StartWatchdog
;
;               DESCRIPTION:    Start watchdog
;
;       PARAMETERS:     EAX      Timeout in milliseconds 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_watchdog_name DB 'Start Watchdog', 0

start_watchdog   Proc far
    push es
    pushad
;   
    mov bx,SEG data
    mov es,bx
        mov edx,1193
        mul edx
        mov es:wd_tics,eax
;       
        GetSystemTime
        add eax,es:wd_tics
        adc edx,0
;
        mov bx,cs
        mov es,bx
        mov di,OFFSET WdTimeout
        mov bx,SEG data
        StartTimer
;
    popad
    pop es      
    retf32
start_watchdog   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   KickWatchdog
;
;               DESCRIPTION:    Kick watchdog
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kick_watchdog_name DB 'Kick Watchdog', 0

kick_watchdog   Proc far
    push ds
    push es
    push fs
    pushad
;        
    GetDebugThreadSel
    or ax,ax
    jz kw_kick
;
    mov bp,ax
    mov bx,SEG data
    mov fs,bx
    mov ecx,fs:fault_sectors
    or ecx,ecx
    jz kw_done
;    
    mov fs:fault_sectors,0
    mov edx,fs:fault_start_sector
;
    mov bx,fault_sector_sel
    mov es,bx
    GetDebugThreadSel

kw_save_loop:
    mov ds,ax
;
    mov es:fss_sign,FAULT_SIGN
        mov ax,ds:p_id
        mov es:fss_state.st_id,ax
;
    push cx
        mov si,OFFSET thread_name
        mov cx,32
        mov di,OFFSET fss_state.st_name
        rep movsb
;
    mov cx,32
    mov di,OFFSET fss_state.st_list
    mov al,' '
    rep stosb   
        pop cx
;       
        mov eax,ds:p_msb_tics
        mov es:fss_state.st_time,eax
        mov eax,ds:p_lsb_tics
        mov es:fss_state.st_time+4,eax
;
    mov es:fss_state.st_offs,0
    mov es:fss_state.st_sel,0
;
    mov ds,ds:p_tss_data_sel
    push cx
    mov cx,SIZE tss_seg
    xor si,si
    mov di,OFFSET fss_tss
    rep movsb
    pop cx
;
    push cx
    mov al,fs:fault_disc
    mov cx,512
    xor di,di           
    WriteDisc
    pop cx
;
    DebugNext    
    GetDebugThreadSel
    cmp ax,bp
    je kw_done
;
    inc edx
    sub ecx,1
    jnz kw_save_loop    
;
    jmp kw_done    
        
kw_kick:
        GetSystemTime
    mov bx,SEG data
    mov es,bx
        add eax,es:wd_tics
        adc edx,0
;
        mov bx,cs
        mov es,bx
        mov di,OFFSET WdTimeout
        mov bx,SEG data
        StopTimer
        StartTimer

kw_done:
    popad       
    pop fs
    pop es
    pop ds
    retf32
kick_watchdog   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   StopWatchdog
;
;               DESCRIPTION:    Stop watchdog
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_watchdog_name DB 'Stop Watchdog', 0

stop_watchdog   Proc far
    push es
    push bx    
;    
        mov bx,SEG data
        mov es,bx
        StopTimer
    mov es:wd_tics,0    
;
    pop bx
    pop es
    retf32
stop_watchdog   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetWatchdogTics
;
;               DESCRIPTION:    Get watchdog tics
;
;       RETURNS:        EAX == 0 not running
;                       EAX != 0, EAX tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_watchdog_tics_name DB 'Get Watchdog Tics', 0

get_watchdog_tics   Proc far
    push es
    push bx    
;    
        mov bx,SEG data
        mov es,bx
    mov eax,es:wd_tics
;
    pop bx
    pop es
    retf32
get_watchdog_tics   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DefineFaultSave
;
;               DESCRIPTION:    Define fault save position on disc
;
;       PARAMETERS:     AL      Disc #
;                       EDX     Start sector #
;                       ECX     Number of available sectors
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_fault_save_name  DB 'Define Fault Save',0

define_fault_save       PROC far
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    mov ds:fault_disc,al
    mov ds:fault_start_sector,edx
    mov ds:fault_sectors,ecx
;    
    pop bx
    pop ds
    retf32
define_fault_save   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ClearFaultSave
;
;               DESCRIPTION:    Clear fault save data
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_fault_save_name   DB 'Clear Fault Save',0

clear_fault_save        PROC far
    push ds
    push es
    pushad
;    
    mov ax,SEG data
    mov ds,ax
    mov ax,fault_sector_sel
    mov es,ax
    xor di,di
    mov cx,512
    xor al,al
    rep stosb
;
    mov ecx,ds:fault_sectors
    mov edx,ds:fault_start_sector

cfsLoop:
    or ecx,ecx
    jz cfsDone
;
    push cx
    mov al,ds:fault_disc
    mov cx,512
    xor di,di
    WriteDisc
    pop cx
;
    inc edx
    dec ecx
    jmp cfsLoop 

cfsDone:   
    popad
    pop es
    pop ds
    retf32
clear_fault_save   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetFaultThreadState
;
;               DESCRIPTION:    Get fault thread state
;
;       PARAMETERS:     AX          Thread #
;                       ES:E(DI)    State buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_fault_thread_state_name     DB 'Get Fault Thread State',0

get_fault_thread_state  PROC near
    push ds
    push es
    push fs
    pushad
;   
    mov bp,es
    mov fs,bp
    mov ebp,edi
;    
    movzx eax,ax
    mov bx,SEG data
    mov ds,bx
    mov bx,fault_sector_sel
    mov es,bx
;
    mov ecx,ds:fault_sectors
    cmp eax,ecx
    jae gfsFail
;
    mov edx,ds:fault_start_sector
    add edx,eax
    mov al,ds:fault_disc
    mov cx,512
    xor di,di
    ReadDisc
    mov eax,es:fss_sign
    cmp eax,FAULT_SIGN
    jne gfsFail
;
    mov ax,es
    mov ds,ax
    mov esi,OFFSET fss_state
    mov ax,fs
    mov es,ax
    mov edi,ebp
    mov ecx,SIZE state_struc
    rep movs byte ptr es:[edi],ds:[esi]
    clc
    jmp gfsEnd    
        
gfsFail:
    stc

gfsEnd:
    popad
    pop fs
    pop es
    pop ds
    ret
get_fault_thread_state   Endp

get_fault_thread_state16        Proc far
        push edi
        movzx edi,di
        call get_fault_thread_state
        pop edi
        ret
get_fault_thread_state16        Endp

get_fault_thread_state32        Proc far
        call get_fault_thread_state
        Retf32
get_fault_thread_state32        Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetFaultThreadTss
;
;               DESCRIPTION:    Get fault thread tss
;
;       PARAMETERS:     AX          Thread #
;                       ES:E(DI)    Tss buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_fault_thread_tss_name       DB 'Get Fault Thread Tss',0

get_fault_thread_tss    PROC near
    push ds
    push es
    push fs
    pushad
;   
    mov bp,es
    mov fs,bp
    mov ebp,edi
;    
    movzx eax,ax
    mov bx,SEG data
    mov ds,bx
    mov bx,fault_sector_sel
    mov es,bx
;
    mov ecx,ds:fault_sectors
    cmp eax,ecx
    jae gftFail
;
    mov edx,ds:fault_start_sector
    add edx,eax
    mov al,ds:fault_disc
    mov cx,512
    xor di,di
    ReadDisc
    mov eax,es:fss_sign
    cmp eax,FAULT_SIGN
    jne gftFail
;
    mov ax,es
    mov ds,ax
    mov esi,OFFSET fss_tss
    mov ax,fs
    mov es,ax
    mov edi,ebp
    mov ecx,SIZE tss_seg
    rep movs byte ptr es:[edi],ds:[esi]
    clc
    jmp gftEnd    
        
gftFail:
    stc

gftEnd:
    popad
    pop fs
    pop es
    pop ds
    ret
get_fault_thread_tss   Endp

get_fault_thread_tss16  Proc far
        push edi
        movzx edi,di
        call get_fault_thread_tss
        pop edi
        ret
get_fault_thread_tss16  Endp

get_fault_thread_tss32  Proc far
        call get_fault_thread_tss
        Retf32
get_fault_thread_tss32  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Init
;
;               DESCRIPTION:    Initialize module
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
        mov bx,SEG data
        mov es,bx
        mov es:wd_tics,0
        mov es:fault_sectors,0
;
        mov eax,512
        mov bx,fault_sector_sel
        AllocateFixedSystemMem
;
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov si,OFFSET start_watchdog
        mov di,OFFSET start_watchdog_name
        xor dx,dx
        mov ax,start_watchdog_nr
        RegisterBimodalUserGate
;
        mov si,OFFSET kick_watchdog
        mov di,OFFSET kick_watchdog_name
        xor dx,dx
        mov ax,kick_watchdog_nr
        RegisterBimodalUserGate
;
        mov si,OFFSET stop_watchdog
        mov di,OFFSET stop_watchdog_name
        xor dx,dx
        mov ax,stop_watchdog_nr
        RegisterBimodalUserGate
;
        mov si,OFFSET get_watchdog_tics
        mov di,OFFSET get_watchdog_tics_name
        xor dx,dx
        mov ax,get_watchdog_tics_nr
        RegisterBimodalUserGate
;
        mov si,OFFSET define_fault_save
        mov di,OFFSET define_fault_save_name
        xor dx,dx
        mov ax,define_fault_save_nr
        RegisterBimodalUserGate
;
        mov si,OFFSET clear_fault_save
        mov di,OFFSET clear_fault_save_name
        xor dx,dx
        mov ax,clear_fault_save_nr
        RegisterBimodalUserGate
;
        mov bx,OFFSET get_fault_thread_state16
        mov si,OFFSET get_fault_thread_state32
        mov di,OFFSET get_fault_thread_state_name
        mov dx,virt_es_in
        mov ax,get_fault_thread_state_nr
        RegisterUserGate
;
        mov bx,OFFSET get_fault_thread_tss16
        mov si,OFFSET get_fault_thread_tss32
        mov di,OFFSET get_fault_thread_tss_name
        mov dx,virt_es_in
        mov ax,get_fault_thread_tss_nr
        RegisterUserGate
        ret
init    Endp

code    ENDS

        END init
