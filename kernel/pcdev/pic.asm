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
INCLUDE ..\os\proc.inc
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\os\int.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os\irq.inc

data    SEGMENT byte public 'DATA'

pit_spinlock        DW ?
clock_tics          DW ?
system_time         DD ?,?

global_int_arr      DW 16 DUP(?)

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use16 'CODE'

    assume cs:code

irqmac  MACRO nr

irq&nr:
    push bp
    mov bp,sp
    push ds
    push es
    push fs
    pushad
;

    EnterInt
    sti
;       
    mov ax,irq_sys_sel
    mov es,ax
    mov bx,OFFSET irq_arr + nr * SIZE irq_struc
    mov ax,word ptr es:[bx+4].user_handler
    or ax,ax
    jz irq_default_error&nr
;
    mov ds,es:[bx].user_data
    xor eax,eax
    mov ax,cs
    push eax
    mov ax,OFFSET irq_handle_done&nr
    push eax
    push es:[bx+4].user_handler
    push es:[bx].user_handler
    xor ax,ax
    mov es,ax
    retf32

irq_default_error&nr:
IF nr GT 7
    in al,INT1_MASK
    or al,1 SHL (nr-8)
    out INT1_MASK,al
ELSE
    in al,INT0_MASK
    or al,1 SHL nr
    out INT0_MASK,al
ENDIF
    or es:bad_irqs, 1 SHL nr

irq_handle_done&nr:
    cli
IF nr GT 7
    mov al,62h
    out INT0_CONTROL,al
    jmp short $+2
    mov al,60h + nr - 8
    out INT1_CONTROL,al
ELSE
    mov al,60h + nr
    out INT0_CONTROL,al
ENDIF       
    LeaveInt
irq_unmask_done&nr:
    popad
    pop fs
    pop es
    pop ds
    pop bp
    iretd

    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IN_CONTROL0
;
;           DESCRIPTION:    Virtualize PIC0 control port
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_control0     PROC far
    in al,20h
    retf32
in_control0     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OUT_CONTROL0
;
;           DESCRIPTION:    Virtualize PIC0 control port
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_control0    PROC far
    cmp al,20h
    jne out_control0_done
    out dx,al
out_control0_done:
    retf32
out_control0    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IN_MASK0
;
;           DESCRIPTION:    Virtualize PIC0 mask
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_mask0    PROC far
    mov bx,irq_proc_sel
    mov ds,bx
    mov al,ds:mask0
    retf32
in_mask0    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OUT_MASK0
;
;           DESCRIPTION:    Virtualize PIC0 mask
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_mask0       PROC far
    mov bx,irq_proc_sel
    mov ds,bx
    push ax
    mov ah,al
    in al,21h
    and al,ah
    out 21h,al
    pop ax
    mov ds:mask0,al
    retf32
out_mask0       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IN_CONTROL1
;
;           DESCRIPTION:    Virtualize PIC1 control port
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_control1     PROC far
    in al,0A0h
    retf32
in_control1     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OUT_CONTROL1
;
;           DESCRIPTION:    Virtualize PIC1 control port
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_control1    PROC far
    cmp al,20h
    jne out_control1_done
    out dx,al
out_control1_done:
    retf32
out_control1    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IN_MASK1
;
;           DESCRIPTION:    Virtualize PIC1 mask
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

in_mask1    PROC far
    mov bx,irq_proc_sel
    mov ds,bx
    mov al,ds:mask1
    retf32
in_mask1    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OUT_MASK1
;
;           DESCRIPTION:    Virtualize PIC1 mask
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

out_mask1       PROC far
    mov bx,irq_proc_sel
    mov ds,bx
    push ax
    mov ah,al
    in al,0A1h
    and al,ah
    out 0A1h,al
    pop ax
    mov ds:mask1,al
    retf32
out_mask1       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_PROCESS
;
;           DESCRIPTION:    Initialize per-process data
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process    PROC far
    push ds
    push ax
    mov ax,irq_proc_sel
    mov ds,ax
    mov ds:mask0,0FFh
    mov ds:mask1,0FFh
    pop ax
    pop ds
    retf32
init_process    ENDP
    
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
    push ds
    push es
    push fs
    pushad
;
    EnterInt
    sti
;       
    mov ds,cs:irq_handler_data
    call fword ptr cs:irq_handler_ads
;
    mov bx,OFFSET IrqEnd1 - OFFSET IrqStart1
    jmp cs:irq_chain

IrqExit1:
    cli    
    mov al,cs:irq_nr
    add al,60h
    out INT0_CONTROL,al
    LeaveInt
;
    popad
    pop fs
    pop es
    pop ds
    iretd

IrqDetect1:
    mov ah,1
    mov cl,cs:irq_nr
    shl ah,cl
    in al,INT0_MASK
    or al,ah
    out INT0_MASK,al
;
    mov ax,irq_sys_sel
    mov ds,ax
    mov bx,OFFSET bad_irqs
    movzx dx,cs:irq_detect_nr
    bts ds:[bx],dx
    retf32

IrqEnd1:

IrqStart2:

irq_handler2     irq_handler_struc <>

IrqEntry2:
    push ds
    push es
    push fs
    pushad
;
    EnterInt
    sti
;       
    mov ds,cs:irq_handler_data
    call fword ptr cs:irq_handler_ads
;
    mov bx,OFFSET IrqEnd2 - OFFSET IrqStart2
    jmp cs:irq_chain

IrqExit2:
    cli    
    mov al,62h
    out INT0_CONTROL,al
    jmp short $+2
;
    mov al,cs:irq_nr
    add al,60h
    out INT1_CONTROL,al
    LeaveInt
;
    popad
    pop fs
    pop es
    pop ds
    iretd

IrqDetect2:
    mov ah,1
    mov cl,cs:irq_nr
    shl ah,cl
    in al,INT1_MASK
    or al,ah
    out INT1_MASK,al
;
    mov ax,irq_sys_sel
    mov ds,ax
    mov bx,OFFSET bad_irqs
    movzx dx,cs:irq_detect_nr
    bts ds:[bx],dx
    retf32

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
    push ax
    mov eax,OFFSET IrqEnd1 - OFFSET IrqStart1
    AllocateSmallLinear
    AllocateGdt
    mov ecx,eax
    CreateCodeSelector16
;
    mov ax,cs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov esi,OFFSET IrqStart1
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov es:[edx].irq_linear,edx
    mov word ptr es:[edx].irq_chain,OFFSET IrqExit1 - OFFSET IrqStart1
    mov dword ptr es:[edx].irq_handler_ads,OFFSET IrqDetect1 - OFFSET IrqStart1
    mov word ptr es:[edx].irq_handler_ads+4,bx
    mov es:[edx].irq_handler_data,0
    pop ax
;
    mov si,SEG data
    mov ds,si
    movzx si,al
    shl si,1
    mov ds:[si].global_int_arr,bx
;    
    mov es:[edx].irq_detect_nr,al
    mov es:[edx].irq_nr,al
;
    mov ds,bx
    mov esi,OFFSET IrqEntry1 - OFFSET IrqStart1
    add al,28h
    xor bl,bl
    SetupIntGate
    jmp ciDone

ci2:
    push ax
    mov eax,OFFSET IrqEnd2 - OFFSET IrqStart2
    AllocateSmallLinear
    AllocateGdt
    mov ecx,eax
    CreateCodeSelector16
;
    mov ax,cs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov esi,OFFSET IrqStart2
    mov edi,edx
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov es:[edx].irq_linear,edx
    mov word ptr es:[edx].irq_chain,OFFSET IrqExit2 - OFFSET IrqStart2
    mov dword ptr es:[edx].irq_handler_ads,OFFSET IrqDetect2 - OFFSET IrqStart2
    mov word ptr es:[edx].irq_handler_ads+4,bx
    mov es:[edx].irq_handler_data,0
    pop ax
;
    mov si,SEG data
    mov ds,si
    movzx si,al
    shl si,1
    mov ds:[si].global_int_arr,bx
;    
    mov es:[edx].irq_detect_nr,al
    sub al,8
    mov es:[edx].irq_nr,al
;
    mov ds,bx
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
    movzx bx,al
    shl bx,1
    mov dx,SEG data
    mov fs,dx
    mov bx,fs:[bx].global_int_arr
    or bx,bx
    jz rihDone
;
    push ax
    mov fs,bx
    mov edx,fs:irq_linear
    mov ax,flat_sel
    mov fs,ax
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
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
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
    mov ax,cs
    mov ds,ax
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
    pop ax
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
    pop ax
    mov fs:[edx].irq_handler_data,ds
    mov fs:[edx].irq_handler_ads,edi
    mov word ptr fs:[edx].irq_handler_ads+4,es
    mov fs:[edx].irq_detect_nr,-1

rihDone:
    popad
    pop fs    
    retf32
request_irq_handler   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IRQx
;
;           DESCRIPTION:    IRQ handlers
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    irqmac 3
    irqmac 4
    irqmac 6
    irqmac 7
    irqmac 8
    irqmac 9
    irqmac 13
    irqmac 14
    irqmac 15


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnableIrq
;
;           description:    Enable IRQ in PIC controller
;
;           PARAMETERS:         AL              irq nr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_irq  Proc far
    push ax
    push cx
;    
    test al,8
    jz set_pic1
set_pic2:
    sub al,8
    mov cl,al
    mov ah,1
    rol ah,cl
    not ah
    cli
    in al,0A1h
    jmp short $+2
    and al,ah
    out 0A1h,al
    sti
    jmp set_pic_done
    
set_pic1:
    mov cl,al
    mov ah,1
    rol ah,cl
    not ah
    cli
    in al,21h
    jmp short $+2
    and al,ah
    out 21h,al
    sti

set_pic_done:
    pop cx
    pop ax
    ret
enable_irq  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DisableIrq
;
;           description:    Disable IRQ in PIC controller
;
;           PARAMETERS:         AL              irq nr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_irq  Proc far
    push ax
    push cx    
;
    test al,8
    jz remove_pic1

remove_pic2:
    sub al,8
    mov cl,al
    mov ah,1
    rol ah,cl
    cli
    in al,0A1h
    or al,ah
    out 0A1h,al
    sti
    jmp remove_pic_done

remove_pic1:
    mov cl,al
    mov ah,1
    rol ah,cl
    cli
    in al,21h
    or al,ah
    out 21h,al
    sti
remove_pic_done:
    pop cx
    pop ax
    ret
disable_irq Endp

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
    retf32
disable_all_irq Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnableIrqDetect
;
;           description:    Enable IRQ detect in PIC controller
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_irq_detect  Proc far
    push ax
;    
    xor al,al
    out 21h,al
    jmp short $+2
;       
    xor al,al
    out 0A1h,al
;
    pop ax
    ret
enable_irq_detect   Endp

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
    push ax
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
    pop ax
    retf32
send_eoi    Endp    

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
    mov ax,SEG data
    mov ds,ax
    mov ds:pit_spinlock,0
;    
    mov al,0B4h
    out TIMER_CONTROL,al
    jmp short $+2
    mov al,0
    out TIMER2,al
    jmp short $+2
    out TIMER2,al
    mov ds:clock_tics,0
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
    pop ds
    retf32
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
    out TIMER0,al
    xchg al,ah
    jmp short $+2
    out TIMER0,al
    clc
    retf32
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
    mov ax,SEG data
    mov ds,ax

gstSpinLock:    
    mov ax,ds:pit_spinlock
    or ax,ax
    je gstGet
;
    sti
    pause
    jmp gstSpinLock

gstGet:
    cli
    inc ax
    xchg ax,ds:pit_spinlock
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
    xchg ax,ds:clock_tics
    sub ax,dx
    movzx eax,ax
    add ds:system_time,eax
    adc ds:system_time+4,0
;    
    mov eax,ds:system_time
    mov edx,ds:system_time+4
;    
    mov ds:pit_spinlock,0
    sti
    pop ds
    retf32
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
    push bx
    mov bx,SEG data
    mov ds,bx
    mov ds:system_time,eax
    mov ds:system_time+4,edx
    pop bx
    pop ds
    retf32
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
    push ds
    push es
    push fs
    pushad
;
    mov al,20h
    out INT0_CONTROL,al
;
    PreemptTimerExpired
;
    popad
    pop fs
    pop es
    pop ds
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

int_tab:

ii0    DW      28h,    OFFSET timer_int
ii_end DW      0FFFFh

;
; tabell offsets
;
ig_nr       EQU 0
ig_entry    EQU 2

SetupInts Proc near
    push ds
    pushad
;    
    mov ax,cs
    mov ds,ax
    xor bl,bl
    mov di,OFFSET int_tab

intLoop:
    mov ax,cs:[di]
    cmp ax,0FFFFh
    jz intDone
;
    mov al,cs:[di].ig_nr
    movzx esi, word ptr cs:[di].ig_entry
    SetupIntGate
    add di,4
    jmp intLoop
    
intDone:
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
    mov bx,OFFSET irq_tab

sdiLoop:
    mov al,cs:[bx]
    cmp al,-1
    je sdiDone
;
    call CreateIrq    
    inc bx
    jmp sdiLoop

sdiDone:
    ret
SetupDefaultIrq Endp
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           Test gate
;
;               DESCRIPTION:    Test gate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_gate_name    DB 'Test Gate',0

test_gate_pr  Proc far
    retf32
test_gate_pr    Endp

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

init    PROC far
    mov ax,SEG data
    mov ds,ax
    mov ds:system_time,0
    mov ds:system_time+4,0
;
    mov cx,16
    mov si,OFFSET global_int_arr
    xor ax,ax

init_global_int:
    mov ds:[si],ax
    add si,2
    loop init_global_int
;    
    call SetupDefaultIrq
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET request_irq_handler
    mov edi,OFFSET request_irq_handler_name
    xor cl,cl
    mov ax,request_irq_handler_nr
    RegisterOsGate
;
    mov esi,OFFSET send_eoi
    mov edi,OFFSET send_eoi_name
    xor cl,cl
    mov ax,send_eoi_nr
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
    mov esi,OFFSET test_gate_pr
    mov edi,OFFSET test_gate_name
    xor dx,dx
    mov ax,test_gate_nr
    RegisterBimodalUserGate
;
    mov si,OFFSET set_system_time
    mov di,OFFSET set_system_time_name
    xor cl,cl
    mov ax,set_system_time_nr
    RegisterOsGate
;
    mov edi,OFFSET init_process
    HookCreateProcess
;
    mov edi,OFFSET in_control0
    mov dx,20h
    HookIn
;
    mov edi,OFFSET out_control0
    mov dx,20h
    HookOut
;
    mov edi,OFFSET in_mask0
    mov dx,21h
    HookIn
;
    mov edi,OFFSET out_mask0
    mov dx,21h
    HookOut
;
    mov edi,OFFSET in_control1
    mov dx,0A0h
    HookIn
;
    mov edi,OFFSET out_control1
    mov dx,0A0h
    HookOut
;
    mov edi,OFFSET in_mask1
    mov dx,0A1h
    HookIn
;
    mov edi,OFFSET out_mask1
    mov dx,0A1h
    HookOut
;
    mov ax,cs
    mov ds,ax
    xor bl,bl
;
    mov al,2Bh
    mov esi,OFFSET irq3
    SetupIntGate
;
    mov al,2Ch
    mov esi,OFFSET irq4
    SetupIntGate
;
    mov al,2Eh
    mov esi,OFFSET irq6
    SetupIntGate
;
    mov al,2Fh
    mov esi,OFFSET irq7
    SetupIntGate
;
    mov al,38h
    mov esi,OFFSET irq8
    SetupIntGate
;
    mov al,39h
    mov esi,OFFSET irq9
    SetupIntGate
;
    mov al,3Dh
    mov esi,OFFSET irq13
    SetupIntGate
;
    mov al,3Eh
    mov esi,OFFSET irq14
    SetupIntGate
;
    mov al,3Fh
    mov esi,OFFSET irq15
    SetupIntGate
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
    mov bx,irq_sys_sel
    mov ds,bx
;       
    mov word ptr ds:irq_detect_proc,OFFSET enable_irq_detect
    mov word ptr ds:irq_detect_proc+2,cs
;    
    mov cx,16
    mov bx,OFFSET irq_arr
    xor eax,eax

init_irq_loop:
    mov word ptr ds:[bx].irq_enable_proc,OFFSET enable_irq
    mov word ptr ds:[bx].irq_enable_proc+2,cs
;
    mov word ptr ds:[bx].irq_disable_proc,OFFSET disable_irq
    mov word ptr ds:[bx].irq_disable_proc+2,cs
;
    add bx,SIZE irq_struc
    loop init_irq_loop
;
    call SetupInts        
    ret
init    ENDP

code    ENDS

    END init

