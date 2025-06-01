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
; PIC.ASM
; Legacy PIC module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\os\port.def
INCLUDE ..\os\system.def
INCLUDE ..\os\core.inc
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\os\int.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc

time_seg  STRUC

t_phys                DD ?,?
t_pit_spinlock        DW ?
t_clock_tics          DW ?
t_system_time         DD ?,?

time_seg  ENDS

data    SEGMENT byte public 'DATA'

detected_irqs       DW ?

global_int_arr      DW 16 DUP(?)

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use32 'CODE'

    assume cs:code
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           IRQ handler
;
;               DESCRIPTION:    Code for patching into IRQ handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code should not contain near jumps or references to near labels!

irq_handler_struc   STRUC

irq_linear          DD ?
irq_handler_ads     DD ?,?
irq_handler_data    DW ?
irq_chain           DW ?
irq_nr              DB ?
irq_detect_nr       DB ?

irq_handler_struc   ENDS

IrqStart1:

irq_handler1     irq_handler_struc <>

IrqEntry1:
    pushad
    push ds
    push es
    push fs
;
    xor eax,eax
    mov ds,eax
    mov es,eax
    mov fs,eax
;
    mov al,cs:irq_nr
    EnterInt
;       
    mov ax,word ptr fs:cs_curr_irq_nr
    or ax,ax
    jz IrqPrevOk1
;    
    mov ax,fs:cs_nested_irq_count
    mov bx,ax
    inc ax
    cmp ax,MAX_IRQ_NESTING
    jne IrqAddStack1
;
    int 3

IrqAddStack1:
    mov fs:cs_nested_irq_count,ax
;
    shl bx,2
    mov eax,dword ptr fs:cs_curr_irq_nr
    mov fs:[bx].cs_nested_irq_stack,eax

IrqPrevOk1: 
    movzx bx,cs:irq_nr
    mov word ptr fs:cs_curr_irq_nr,bx
    mov fs:cs_curr_irq_retries,0
;
    sti

IrqRetry1:    
    mov ds,cs:irq_handler_data
    call fword ptr cs:irq_handler_ads
;
    mov bx,OFFSET IrqEnd1 - OFFSET IrqStart1
    jmp cs:irq_chain

IrqExit1:
    cli    
;
    mov ax,word ptr fs:cs_curr_irq_nr
    or ah,ah
    jz IrqExitCountOk1
;
    mov fs:cs_curr_irq_count,0
    mov al,fs:cs_curr_irq_retries
    inc al
    mov fs:cs_curr_irq_retries,al
;    
    sti
    cmp al,100
    jne IrqRetry1
;
    int 3    
    jmp IrqRetry1
    
IrqExitCountOk1: 
    mov word ptr fs:cs_curr_irq_nr,0
    mov bx,fs:cs_nested_irq_count
    or bx,bx
    jz IrqExitNestingOk1
;
    dec bx
    mov fs:cs_nested_irq_count,bx
    shl bx,2
    mov eax,fs:[bx].cs_nested_irq_stack
    mov dword ptr fs:cs_curr_irq_nr,eax
    
IrqExitNestingOk1:
    mov al,cs:irq_nr
    add al,60h
    out INT0_CONTROL,al
    LeaveInt
;
    pop eax
    verr ax
    jz IrqExitFs1
;    
    xor eax,eax

IrqExitFs1:
    mov fs,eax
;
    pop eax
    verr ax
    jz IrqExitEs1
;    
    xor eax,eax

IrqExitEs1:
    mov es,eax
;
    pop eax
    verr ax
    jz IrqExitDs1
;    
    xor eax,eax

IrqExitDs1:
    mov ds,eax
;
    popad
    iretd

IrqDetect1:
    mov ah,1
    mov cl,cs:irq_nr
    shl ah,cl
    in al,INT0_MASK
    or al,ah
    out INT0_MASK,al
;
    mov ax,SEG data
    mov ds,ax
    mov bx,OFFSET detected_irqs
    movzx dx,cs:irq_detect_nr
    bts ds:[bx],dx
    retf

IrqEnd1:

IrqStart2:

irq_handler2     irq_handler_struc <>

IrqEntry2:
    pushad
    push ds
    push es
    push fs
;
    xor eax,eax
    mov ds,eax
    mov es,eax
    mov fs,eax
;
    mov al,cs:irq_nr
    EnterInt
;       
    mov ax,word ptr fs:cs_curr_irq_nr
    or ax,ax
    jz IrqPrevOk2
;    
    mov ax,fs:cs_nested_irq_count
    mov bx,ax
    inc ax
    cmp ax,MAX_IRQ_NESTING
    jne IrqAddStack2
;
    int 3

IrqAddStack2:
    mov fs:cs_nested_irq_count,ax
;
    shl bx,2
    mov eax,dword ptr fs:cs_curr_irq_nr
    mov fs:[bx].cs_nested_irq_stack,eax

IrqPrevOk2: 
    movzx ebx,cs:irq_nr
    mov word ptr fs:cs_curr_irq_nr,bx
    mov fs:cs_curr_irq_retries,0
;
    sti

IrqRetry2:    
    mov ds,cs:irq_handler_data
    call fword ptr cs:irq_handler_ads
;       
    mov ebx,OFFSET IrqEnd2 - OFFSET IrqStart2
    jmp cs:irq_chain

IrqExit2:
    cli    
;
    mov ax,word ptr fs:cs_curr_irq_nr
    or ah,ah
    jz IrqExitCountOk2
;
    mov fs:cs_curr_irq_count,0
    mov al,fs:cs_curr_irq_retries
    inc al
    mov fs:cs_curr_irq_retries,al
;    
    sti
    cmp al,100
    jne IrqRetry2
;
    int 3    
    jmp IrqRetry2
    
IrqExitCountOk2: 
    mov word ptr fs:cs_curr_irq_nr,0
    mov bx,fs:cs_nested_irq_count
    or bx,bx
    jz IrqExitNestingOk2
;
    dec bx
    mov fs:cs_nested_irq_count,bx
    shl bx,2
    mov eax,fs:[bx].cs_nested_irq_stack
    mov dword ptr fs:cs_curr_irq_nr,eax
    
IrqExitNestingOk2:
    mov al,62h
    out INT0_CONTROL,al
    jmp short $+2
;
    mov al,cs:irq_nr
    add al,60h
    out INT1_CONTROL,al
    LeaveInt
;
    pop eax
    verr ax
    jz IrqExitFs2
;    
    xor eax,eax

IrqExitFs2:
    mov fs,eax
;
    pop eax
    verr ax
    jz IrqExitEs2
;    
    xor eax,eax

IrqExitEs2:
    mov es,eax
;
    pop eax
    verr ax
    jz IrqExitDs2
;    
    xor eax,eax

IrqExitDs2:
    mov ds,eax
;
    popad
    iretd

IrqDetect2:
    mov ah,1
    mov cl,cs:irq_nr
    shl ah,cl
    in al,INT1_MASK
    or al,ah
    out INT1_MASK,al
;
    mov eax,SEG data
    mov ds,eax
    mov ebx,OFFSET detected_irqs
    movzx edx,cs:irq_detect_nr
    bts ds:[ebx],edx
    retf

IrqEnd2:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           IRQ chaining
;
;               DESCRIPTION:    Code for adding at end of IRQ handler in order to chain
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code should not contain near jumps or references to near labels!

irq_chain_struc  STRUC

irch_handler_ads     DD ?,?
irch_handler_data    DW ?
irch_chain           DW ?

irq_chain_struc ENDS

IrqChainStart:

irch_handler      irq_chain_struc <>

IrqChainEntry:
    push bx
    mov ds,cs:[bx].irch_handler_data
    call fword ptr cs:[bx].irch_handler_ads
    pop bx
;
    mov si,bx
    add bx,OFFSET IrqChainEnd - OFFSET IrqChainStart
    jmp cs:[si].irch_chain

IrqChainEnd:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateIrq
;
;       DESCRIPTION:    Create new IRQ context
;
;       PARAMETERS:     AL           IRQ # 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIrq   Proc near
    push ds
    push es
    pushad
;
    cmp al,8
    jae ci2

ci1:    
    push eax
    mov eax,OFFSET IrqEnd1 - OFFSET IrqStart1
    AllocateSmallLinear
    AllocateGdt
    mov ecx,eax
    CreateCodeSelector16
;
    mov eax,cs
    mov ds,eax
    mov eax,flat_sel
    mov es,eax
    mov esi,OFFSET IrqStart1
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov es:[edx].irq_linear,edx
    mov word ptr es:[edx].irq_chain,OFFSET IrqExit1 - OFFSET IrqStart1
    mov dword ptr es:[edx].irq_handler_ads,OFFSET IrqDetect1 - OFFSET IrqStart1
    mov word ptr es:[edx].irq_handler_ads+4,bx
    mov es:[edx].irq_handler_data,0
    pop eax
;
    mov esi,SEG data
    mov ds,esi
    movzx esi,al
    shl esi,1
    mov ds:[esi].global_int_arr,bx
;    
    mov es:[edx].irq_detect_nr,al
    mov es:[edx].irq_nr,al
;
    mov ds,ebx
    mov esi,OFFSET IrqEntry1 - OFFSET IrqStart1
    add al,28h
    xor bl,bl
    SetupIntGate
    jmp ciDone

ci2:
    push eax
    mov eax,OFFSET IrqEnd2 - OFFSET IrqStart2
    AllocateSmallLinear
    AllocateGdt
    mov ecx,eax
    CreateCodeSelector16
;
    mov eax,cs
    mov ds,eax
    mov eax,flat_sel
    mov es,eax
    mov esi,OFFSET IrqStart2
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov es:[edx].irq_linear,edx
    mov word ptr es:[edx].irq_chain,OFFSET IrqExit2 - OFFSET IrqStart2
    mov dword ptr es:[edx].irq_handler_ads,OFFSET IrqDetect2 - OFFSET IrqStart2
    mov word ptr es:[edx].irq_handler_ads+4,bx
    mov es:[edx].irq_handler_data,0
    pop eax
;
    mov esi,SEG data
    mov ds,esi
    movzx esi,al
    shl esi,1
    mov ds:[esi].global_int_arr,bx
;    
    mov es:[edx].irq_detect_nr,al
    sub al,8
    mov es:[edx].irq_nr,al
;
    mov ds,ebx
    mov esi,OFFSET IrqEntry2 - OFFSET IrqStart2
    add al,38h
    xor bl,bl
    SetupIntGate

ciDone:
    popad
    pop es
    pop ds
    ret
CreateIrq   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RequestIrqHandler
;
;       DESCRIPTION:    Request an IRQ-based interrupt-handler
;
;       PARAMETERS:     DS      Data passed to handler
;                       ES:EDI  Handler address
;                       AL      Global int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

request_irq_handler_name    DB 'Request IRQ Handler',0

request_irq_handler Proc far
    push fs
    pushad
;
    movzx ebx,al
    shl ebx,1
    mov edx,SEG data
    mov fs,edx
    mov bx,fs:[ebx].global_int_arr
    or bx,bx
    jz rihDone
;
    push eax
    mov fs,ebx
    mov edx,fs:irq_linear
    mov eax,flat_sel
    mov fs,eax
;
    mov al,fs:[edx].irq_detect_nr
    cmp al,-1
    jne rihReplace

rihChain:
    push ds
    push es
    push ecx
    push esi
    push edi
;
    mov eax,flat_sel
    mov ds,eax
    mov es,eax
;    
    mov esi,edx
    GetSelectorBaseSize
    push ecx
    mov eax,ecx        
    add eax,OFFSET IrqChainEnd - OFFSET IrqChainStart
    AllocateSmallLinear
    push edx
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
    mov ebp,edi
;    
    xchg edx,ds:[edx].irq_linear
    xor ecx,ecx
    FreeLinear
;
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET IrqChainStart
    mov ecx,OFFSET IrqChainEnd - OFFSET IrqChainStart
    rep movs byte ptr es:[edi],ds:[esi]
;
    pop edx
    pop ecx
    add ecx,OFFSET IrqChainEnd - OFFSET IrqChainStart
    CreateCodeSelector16
;    
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
;
    mov fs:[ebp].irch_handler_data,ds
    mov fs:[ebp].irch_handler_ads,edi
    mov word ptr fs:[ebp].irch_handler_ads+4,es
;
    pop eax
    cmp al,8
    jae rihChain2

rihChain1:    
    mov eax,ebp
    sub eax,edx
    add ax,OFFSET IrqChainEntry - OFFSET IrqChainStart
    sub ax,OFFSET IrqChainEnd - OFFSET IrqChainStart
    cmp ax,OFFSET IrqEnd1 - OFFSET IrqStart1
    jae rihChainPrev
;    
    add ax,OFFSET IrqChainEnd - OFFSET IrqChainStart
    xchg ax,fs:[edx].irq_chain
    mov fs:[ebp].irch_chain,ax
    jmp rihDone

rihChain2:
    mov eax,ebp
    sub eax,edx
    add ax,OFFSET IrqChainEntry - OFFSET IrqChainStart
    sub ax,OFFSET IrqChainEnd - OFFSET IrqChainStart
    cmp ax,OFFSET IrqEnd2 - OFFSET IrqStart2
    jae rihChainPrev
;    
    add ax,OFFSET IrqChainEnd - OFFSET IrqChainStart
    xchg ax,fs:[edx].irq_chain
    mov fs:[ebp].irch_chain,ax
    jmp rihDone

rihChainPrev:
    mov edx,ebp
    sub edx,OFFSET IrqChainEnd - OFFSET IrqChainStart
    add ax,OFFSET IrqChainEnd - OFFSET IrqChainStart
    xchg ax,fs:[edx].irch_chain
    mov fs:[ebp].irch_chain,ax
    jmp rihDone
        
rihReplace:    
    pop eax
    mov fs:[edx].irq_handler_data,ds
    mov fs:[edx].irq_handler_ads,edi
    mov word ptr fs:[edx].irq_handler_ads+4,es
    mov fs:[edx].irq_detect_nr,-1

rihDone:
    popad
    pop fs    
    ret
request_irq_handler   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DisableAllIrq
;
;           description:    Disable all IRQs in PIC controller
;
;           RETURNS:        EAX     Active IRQs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_all_irq_name    DB 'Disable All IRQs', 0

disable_all_irq  Proc far
    push edx
;
    cli
    mov al,0FFh
    out 21h,al
    jmp short $+2
    out 0A1h,al
    jmp short $+2
;
    xor edx,edx
    mov al,0Bh
    out 0A0h,al
    jmp short $+2
    in al,0A0h
    mov dh,al

daiSlaveLoop:
    or al,al
    jz daiSlaveOk
;
    mov al,20h
    out 0A0h,al
    jmp short $+2
    mov al,0Bh
    out 0A0h,al
    jmp short $+2
    in al,0A0h
    jmp daiSlaveLoop

daiSlaveOk:
    mov al,0Bh
    out 20h,al
    jmp short $+2
    in al,20h
    mov dl,al

daiMasterLoop:
    or al,al
    jz daiMasterOk
;
    mov al,20h
    out 20h,al
    jmp short $+2
    mov al,0Bh
    out 20h,al
    jmp short $+2
    in al,20h
    jmp daiMasterLoop

daiMasterOk:
    mov eax,edx
    pop edx
    ret
disable_all_irq Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           EnableDetect
;
;   Description:    Enable IRQ detect
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnableDetect  Proc near
    push eax
;    
    xor al,al
    out 21h,al
    jmp short $+2
;       
    xor al,al
    out 0A1h,al
;
    pop eax
    ret
EnableDetect   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setup_irq_detect
;
;           description:    Setup IRQ detect
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_irq_detect_name   DB 'Setup IRQ detect',0

setup_irq_detect    Proc far
    push ds
    push eax
;       
    mov eax,SEG data
    mov ds,eax
    mov ds:detected_irqs,0
    call EnableDetect
;
    mov ax,1
    WaitMilliSec
;
    mov ds:detected_irqs,0       
;
    pop eax
    pop ds
    ret
setup_irq_detect    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           poll_irq_detect
;
;           description:    Poll detected IRQs
;
;       RETURNS:    EDX:EAX      Detected IRQs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_irq_detect_name    DB 'Poll IRQ detect',0

poll_irq_detect Proc far
    push ds
;       
    mov eax,SEG data
    mov ds,eax
    movzx eax,ds:detected_irqs
    xor edx,edx
;
    pop ds
    ret
poll_irq_detect Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendEoi
;
;           description:    Send EOI (for custom ISRs only)
;
;           PARAMETERS:     AL      Int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_eoi_name   DB 'Send EOI', 0

send_eoi   Proc far
    push eax
;
    mov ah,al
;    
    cmp al,7
    ja sePic1
;
    mov al,62h
    out INT0_CONTROL,al
    jmp short $+2

    mov al,60h - 8
    add al,ah
    out INT1_CONTROL,al
    je seDone

sePic1:
    mov al,60h
    add al,ah
    out INT0_CONTROL,al

seDone:
    pop eax
    ret
send_eoi    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyIrq
;
;           description:    Notify IRQ detected
;
;           PARAMETERS:     AL      Int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_irq_name   DB 'Notify IRQ', 0

notify_irq   Proc far
    push ds
    push eax
    push ebx
    push ecx
;   
    push eax 
    cmp al,8
    jae niDo2

niDo1:    
    mov ah,1
    mov cl,al
    shl ah,cl
    in al,INT0_MASK
    or al,ah
    out INT0_MASK,al
    jmp niUpdate

niDo2:    
    sub al,8
    mov ah,1
    mov cl,al
    shl ah,cl
    in al,INT1_MASK
    or al,ah
    out INT1_MASK,al

niUpdate:    
    mov eax,SEG data
    mov ds,eax
    pop eax
;
    mov ebx,OFFSET detected_irqs
    movzx eax,al
    bts ds:[ebx],eax
;
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
notify_irq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartSysTimer
;
;           DESCRIPTION:    Start PIT timer
;
;           RETURNS:        EAX      Update tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_pit_timer_name    DB 'Start Pit Timer', 0

start_pit_timer    Proc far
    push ds
;    
    mov eax,time_data_sel
    mov ds,eax
    mov ds:t_pit_spinlock,0
;    
    mov al,0B4h
    out TIMER_CONTROL,al
    jmp short $+2
    mov al,0
    out TIMER2,al
    jmp short $+2
    out TIMER2,al
    mov ds:t_clock_tics,0
    jmp short $+2
    mov al,0Dh
    out 61h,al
;
    mov ax,30h
    out TIMER_CONTROL,al
;
    mov ax,100h
    cli
    out TIMER0,al
    xchg ah,al
    jmp short $+2
    out TIMER0,al
    jmp short $+2
    jmp short $+2
    xor al,al
    out TIMER_CONTROL,al
    jmp short $+2
    in al,TIMER0
    mov ah,al
    jmp short $+2
    in al,TIMER0
    xchg al,ah
    neg ax
    add ax,100h
    movzx eax,ax
    add eax,eax
    add eax,eax
;
    push eax
    in al,INT0_MASK
    and al,NOT 1
    out INT0_MASK,al
    pop eax
;    
    pop ds
    ret
start_pit_timer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReloadSysTimer
;
;           DESCRIPTION:    Reload PIT timer
;
;           PARAMETERS:         AX      Reload count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reload_pit_timer_name    DB 'Reload Pit Timer', 0

reload_pit_timer    Proc far
    push eax
;    
    mov ax,30h
    out TIMER_CONTROL,al
    pop eax
    jmp short $+2
;
    out TIMER0,al
    xchg al,ah
    jmp short $+2
    out TIMER0,al
    clc
    ret
reload_pit_timer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetSystemTime
;
;           DESCRIPTION:    Read system time
;
;           RETURNS:        EDX:EAX     System time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_system_time_name    DB 'Get System Time', 0

get_system_time  Proc far
    push ds
;
    mov eax,time_data_sel
    mov ds,eax

gstSpinLock:    
    mov ax,ds:t_pit_spinlock
    or ax,ax
    je gstGet
;
    sti
    pause
    jmp gstSpinLock

gstGet:
    cli
    inc ax
    xchg ax,ds:t_pit_spinlock
    or ax,ax
    jne gstSpinLock
;
    mov al,80h
    out TIMER_CONTROL,al
    jmp short $+2
    in al,TIMER2
    mov ah,al
    jmp short $+2
    in al,TIMER2
    xchg al,ah
    mov dx,ax
    xchg ax,ds:t_clock_tics
    sub ax,dx
    movzx eax,ax
    add ds:t_system_time,eax
    adc ds:t_system_time+4,0
;    
    mov eax,ds:t_system_time
    mov edx,ds:t_system_time+4
;
    mov ds:ut_system_time+1000h,eax
    mov ds:ut_system_time+1004h,edx
;    
    mov ds:t_pit_spinlock,0
    sti
;
    pop ds
    ret
get_system_time  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetSystemTime
;
;           DESCRIPTION:    Set system time. Must not be called after tasking is
;                           started.
;
;           PARAMETERS:         EDX:EAX     Binary time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_system_time_name    DB 'Set System Time',0

set_system_time PROC far
    push ds
    push ebx
;    
    mov ebx,time_data_sel
    mov ds,ebx
    mov ds:t_system_time,eax
    mov ds:t_system_time+4,edx
;    
    pop ebx
    pop ds
    ret
set_system_time ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TIMER_INT
;
;           DESCRIPTION:    Timer interrupt handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

timer_int:
    pushad
    push ds
    push es
    push fs
;
    mov al,-1
    EnterInt
    lock or fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    mov al,20h
    out INT0_CONTROL,al
    LeaveInt
;
    pop eax
    verr ax
    jz timer_fs_ok
;
    xor eax,eax

timer_fs_ok:
    mov fs,eax
;    
    pop eax
    verr ax
    jz timer_es_ok
;
    xor eax,eax

timer_es_ok:
    mov es,eax
;    
    pop eax
    verr ax
    jz timer_ds_ok
;
    xor eax,eax

timer_ds_ok:
    mov ds,eax
;    
    popad
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupInts
;
;           DESCRIPTION:    Setup interrupts
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts Proc near
    push ds
    pushad
;    
    mov eax,cs
    mov ds,eax
    xor bl,bl
;    
    mov al,28h
    mov esi, OFFSET timer_int
    SetupIntGate
;    
    popad
    pop ds
    ret
SetupInts Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupDefaultIrq
;
;           DESCRIPTION:    Setup default IRQs
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

irq_tab:
i0 DB 1
i1 DB 3
i2 DB 4
i3 DB 5
i4 DB 6
i5 DB 7
i6 DB 8
i7 DB 9
i8 DB 10
i9 DB 11
iA DB 12
iB DB 13
iC DB 14
iD DB 15
iE DB -1

SetupDefaultIrq Proc near
    mov ebx,OFFSET irq_tab

sdiLoop:
    mov al,cs:[ebx]
    cmp al,-1
    je sdiDone
;
    call CreateIrq    
    inc ebx
    jmp sdiLoop

sdiDone:
    ret
SetupDefaultIrq Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PIC init
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_pic

init_pic    PROC near
    push ds
    push es
    pushad
;    
    mov eax,2000h
    AllocateBigLinear
;
    mov bx,time_data_sel
    mov ecx,2000h
    CreateDataSelector16
;
    mov es,bx
    xor di,di
    mov cx,800h
    xor eax,eax
    rep stos dword ptr es:[di]
;
    add edx,1000h
    GetPageEntry
    xor al,al
    mov es:t_phys,eax
    mov es:t_phys+4,ebx
;
    mov eax,SEG data
    mov ds,eax
    mov ds:detected_irqs,0
;
    mov ecx,16
    mov esi,OFFSET global_int_arr
    xor ax,ax

init_global_int:
    mov ds:[esi],ax
    add esi,2
    loop init_global_int
;    
    call SetupDefaultIrq
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET request_irq_handler
    mov edi,OFFSET request_irq_handler_name
    xor cl,cl
    mov ax,request_irq_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_irq_detect
    mov edi,OFFSET setup_irq_detect_name
    xor cl,cl
    mov ax,setup_irq_detect_nr
    RegisterOsGate
;
    mov esi,OFFSET poll_irq_detect
    mov edi,OFFSET poll_irq_detect_name
    xor cl,cl
    mov ax,poll_irq_detect_nr
    RegisterOsGate
;
    mov esi,OFFSET send_eoi
    mov edi,OFFSET send_eoi_name
    xor cl,cl
    mov ax,send_eoi_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_irq
    mov edi,OFFSET notify_irq_name
    xor cl,cl
    mov ax,notify_irq_nr
    RegisterOsGate
;
    mov esi,OFFSET disable_all_irq
    mov edi,OFFSET disable_all_irq_name
    xor cl,cl
    mov ax,disable_all_irq_nr
    RegisterOsGate
;
    mov esi,OFFSET start_pit_timer
    mov edi,OFFSET start_pit_timer_name
    xor cl,cl
    mov ax,start_sys_preempt_timer_nr
    RegisterOsGate
;
    mov esi,OFFSET reload_pit_timer
    mov edi,OFFSET reload_pit_timer_name
    xor cl,cl
    mov ax,reload_sys_preempt_timer_nr
    RegisterOsGate
;
    mov si,OFFSET get_system_time
    mov di,OFFSET get_system_time_name
    xor dx,dx
    mov ax,get_system_time_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET set_system_time
    mov di,OFFSET set_system_time_name
    xor cl,cl
    mov ax,set_system_time_nr
    RegisterOsGate
;
    mov eax,cs
    mov ds,eax
    xor bl,bl
;
    mov al,11h
    out INT0_CONTROL,al
    jmp short $+2
;
    mov al,28h
    out INT0_MASK,al
    jmp short $+2
;
    mov al,04h
    out INT0_MASK,al
    jmp short $+2
;
    mov al,0C1h
    out INT0_CONTROL,AL
    jmp short $+2
;
    mov al,1
    out INT0_MASK,al
    jmp short $+2
;
    mov al,NOT 4
    out INT0_MASK,al
;
    mov al,11h
    out INT1_CONTROL,al
    jmp short $+2
;
    mov al,38h
    out INT1_MASK,al
    jmp short $+2
;
    mov al,2
    jmp short $+2
    out INT1_MASK,al
    jmp short $+2
;
    mov al,1
    out INT1_MASK,al
    jmp short $+2
;
    mov al,-1
    out INT1_MASK,al
    jmp short $+2
;
    call SetupInts        
;
    popad
    pop es
    pop ds    
    ret
init_pic    ENDP

code    ENDS

    END

