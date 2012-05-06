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
; STDCOM.ASM
; Standard serial port device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\pcdev\pci.inc
include ..\os\com.inc
include ..\os\protseg.def

MAX_PORTS       = 16
MAX_IRQS    = 16
MAX_IRQ_SHARE   = 4

IER_BITS    = 8

FLG_ENABLE_CTS  = 1
FLG_ENABLE_AUTO_RTS  = 2

pccom_port_struc    STRUC

pps_base_struc  com_port_struc <>

char_time       DD ?
flgs        DB ?
base            DW ?
dev_handle      DW ?
baud_base       DD ?

pccom_port_struc    ENDS

pccom_device_struc   STRUC

pds_base_struc    com_device_struc <>

pds_base      DW ?
pds_handle    DW ?
pds_baud_base     DD ?
pds_line_thread   DW ?
pds_line      DB ?
pds_irq       DB ?

pccom_device_struc   ENDS

data    SEGMENT byte public 'DATA'

sd_ports    DW ?
sd_port_arr DW MAX_PORTS DUP(?)

data    ENDS


;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MODEM
;
;           DESCRIPTION:    Modem signals changed
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

modem   Proc near
    mov dx,ds:base
    add dx,6
    in al,dx
    mov ah,al
;       
    test al,10h
    jz modem_no_cts
;
    test ds:flgs, FLG_ENABLE_CTS
    jz modem_no_cts
;    
    mov cx,ds:send_count
    or cx,cx
    jz modem_no_cts
;
    mov dx,ds:base
    inc dx
    mov al,IER_BITS + 3
    out dx,al

modem_no_cts:   
    push ds
    mov ds,ds:dev_handle
    mov ds:pds_line,ah
    mov bx,ds:pds_line_thread
    pop ds
    or bx,bx
    jz modem_no_signal
;
    Signal

modem_no_signal:    
    ret
modem   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LINE_ERR
;
;           DESCRIPTION:    Line error occured
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

line_err    PROC near
    mov dx,ds:base
    add dx,5
    in al,dx
    ret
line_err    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REC_PR
;
;           DESCRIPTION:    Received data
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rec_pr  PROC near
    mov es,ds:rec_buf
    mov dx,ds:base
    RequestSpinlock ds:com_spinlock
    in al,dx
;    test ds:flgs, FLG_ENABLE_AUTO_RTS
;    jz rec_pr_save
;
;    push ax
;       mov dx,ds:base
;       add dx,4
;       in al,dx
;       test al,2
;       pop ax
;       jnz rec_exit

rec_pr_save:
    mov cx,ds:rec_count
    cmp cx,ds:rec_size
    je rec_exit
;    
    inc cx
    mov ds:rec_count,cx
    mov bx,ds:rec_tail          ; get tail pointer
    mov es:[bx],al              ; store char
    inc bx
    cmp bx,ds:rec_size
    jnz rec_no_wrap
;
    xor bx,bx
    
rec_no_wrap:
    mov ds:rec_tail,bx
    ReleaseSpinlock ds:com_spinlock
;
    mov bx,ds:avail_obj
    or bx,bx
    jz rec_done
;
    mov es,bx
    SignalWait
    mov ds:avail_obj,0
    jmp rec_done
    
rec_exit:
    ReleaseSpinlock ds:com_spinlock

rec_done:
    ret
rec_pr  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RTS_OFF
;
;           DESCRIPTION:    Delayed RTS off
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rts_off PROC far
    mov ds,cx
    mov di,ds:send_count
    or di,di
    jnz rts_off_done
;
    push ax
    push dx
    mov dx,ds:base
    add dx,5
    in al,dx
    test al,40h
    pop dx
    pop ax
    jnz rts_off_dis
;
    add eax,ds:char_time
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET rts_off
    mov bx,cx
    StartTimer
    jmp rts_off_done
    
rts_off_dis:
    mov dx,ds:base
    add dx,4
    in al,dx
    and al,NOT 2
    out dx,al

rts_off_done:
    retf32
rts_off Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRANS_PR
;
;           DESCRIPTION:    Send data
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trans_pr    PROC near
    mov es,ds:send_buf
    mov dx,ds:base
    RequestSpinlock ds:com_spinlock
    mov cx,ds:send_count
    or cx,cx                    ;  buffer empty ?
    jnz trans_not_empty

trans_end:      
    mov al,IER_BITS + 1
    inc dx
    out dx,al
    ReleaseSpinlock ds:com_spinlock
;
    test ds:flgs, FLG_ENABLE_AUTO_RTS
    jz trans_signal_wait
;
    GetSystemTime
    add eax,ds:char_time
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET rts_off
    mov bx,ds
    mov cx,bx
    StopTimer
    StartTimer
    mov es,ds:send_buf
        
trans_signal_wait:
    mov bx,ds:send_wait
    or bx,bx
    jz trans_exit
;
    Signal
    jmp trans_exit
    
trans_not_empty:    
    test ds:flgs, FLG_ENABLE_CTS
    jz trans_send
;
    add dx,6
    in al,dx
    sub dx,6
    test al,10h
    jz trans_end

trans_send:
    dec cx
    mov ds:send_count,cx
    mov bx,ds:send_head                 ; get head pointer
    mov al,es:[bx]                      ; get char
    out dx,al                           ; transmitt char
    inc bx
    cmp bx,ds:send_size
    jnz trans_not_wrap
    xor bx,bx
trans_not_wrap:
    mov ds:send_head,bx
    ReleaseSpinlock ds:com_spinlock

trans_exit:
    ret
trans_pr    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           COM_INT
;
;       DESCRIPTION:    Serial interrupt
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serial_tab:
st_mod  DW OFFSET modem
st_tx   DW OFFSET trans_pr
st_rx   DW OFFSET rec_pr
st_li   DW OFFSET line_err

com_int Proc far
    mov ax,ds:pds_handle
    or ax,ax
    jz com_int_inactive
;
    mov ds,ax

com_int_loop:
    mov dx,ds:base
    add dx,2
    in al,dx
    test al,1
    jnz com_int_done
;   
    mov bl,al
    xor bh,bh
    and bx,6
    call word ptr cs:[bx].serial_tab
    jmp com_int_loop

com_int_inactive:
    mov dx,ds:pds_base
    add dx,2
    in al,dx
    test al,1
    jnz com_int_done
;   
    mov dx,ds:pds_base
    add dx,6
    in al,dx
    mov ds:pds_line,al
;   
    mov dx,ds:pds_base
    add dx,5
    in al,dx
;
    mov dx,ds:pds_base
    in al,dx
;   
    mov al,IER_BITS + 1
    inc dx
    out dx,al
;   
    mov bx,ds:pds_line_thread
    or bx,bx
    jz com_int_done
;
    Signal

com_int_done:   
    retf32
com_int Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       open_com
;
;       description:    Open a serial port
;
;       PARAMETERS:     DS      Port selector
;               ES      Device selector
;               AH      # of data bits
;               BL      # of stop bits
;               BH      parity
;               ECX     baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com    Proc far
    push ax
    push dx
    push si
;
    push ax
    RequestSpinlock ds:com_spinlock
    mov es:pds_handle,ds
    mov ds:dev_handle,es
    mov ds:flgs,0
    ReleaseSpinlock ds:com_spinlock
    pop ax
;
    mov dl,ah
    inc dl
    mov al,ah    
    sub al,5
    and al,3
;
    add dl,bl
    mov ah,bl
    dec ah
    and ah,1
    shl ah,2
    or al,ah
;
    cmp bh,'E'
    je open_even
;   
    cmp bh,'O'
    je open_odd
;   
    jmp open_parity_done

open_even:
    inc dl
    or al,18h
    jmp open_parity_done

open_odd:
    inc dl
    or al,8

open_parity_done:
    push eax
    push edx
;
    push dx    
    mov eax,ds:baud_base
    xor edx,edx
    div ecx
    mov si,ax
;    
    mov eax,1193000
    xor edx,edx
    div ecx         ; eax = 1193000 / baudrate
    pop dx
;
    movzx edx,dl
    mul edx         ; eax = char tics
    mov ds:char_time,eax
;
    pop edx
    pop eax
;
    push ax
    or al,80h
    mov dx,ds:base
    add dx,3
    out dx,al           ; set line control to divisor access
;
    sub dx,3
    mov ax,si
    out dx,al           ; output LSB divisor latch
;
    inc dx
    mov al,ah
    out dx,al           ; output MSB divisor latch
;
    inc dx
    mov al,1
    out dx,al           ; enable FIFOs if present
;
    pop ax
    inc dx
    out dx,al           ; set line control 
;
    sub dx,2
    mov al,IER_BITS + 1
    out dx,al           ; enable rx ints and delta ints, disable tx, line ints
;
    add dx,3
    in al,dx
    or al,0Ah
    mov ah,ds:line_reserved
    or ah,ah
    jnz open_set_dtr
;
    or al,1

open_set_dtr:
    out dx,al           ; modem control, DTR = high, RTS = high
;
    mov dx,ds:base
    in al,dx
    add dx,5
    in al,dx
    inc dx
    in al,dx
;
    pop si
    pop dx
    pop ax  
    ret
open_com    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       close_com
;
;       description:    Close serial port
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com   Proc far
    push es
    push ax
    push dx
;
    mov dx,ds:base
    inc dx
    xor al,al
    mov ah,ds:line_reserved
    or ah,ah
    jz close_com_not_reserved
;   
    or al,IER_BITS

close_com_not_reserved:
    out dx,al           ; disable rx, tx, line and modem ints
;   
    mov es,ds:dev_handle
    mov es:pds_handle,0
;
    pop dx
    pop ax
    pop es
    ret
close_com   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:       EnableCts
;
;       DESCRIPTION:    Enable CTS signal
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_cts  PROC far
    cmp ds:line_reserved,0
    jne enable_cts_done
;    
    or ds:flgs,FLG_ENABLE_CTS

enable_cts_done:
    ret
enable_cts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:       DisableCts
;
;       DESCRIPTION:    Disable CTS signal
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_cts PROC far
    and ds:flgs,NOT FLG_ENABLE_CTS
    ret
disable_cts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:       EnableAutoRts
;
;       DESCRIPTION:    Enable automatic RTS on send
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_auto_rts PROC far
    push ax
    push dx
;
    or ds:flgs,FLG_ENABLE_AUTO_RTS
    mov dx,ds:base
    add dx,4
    in al,dx
    and al,NOT 2
    out dx,al
;   
    pop dx
    pop ax
    ret
enable_auto_rts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:       DisableAutoRts
;
;       DESCRIPTION:    Disable automatic RTS on send
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_auto_rts    PROC far
    push ax
    push dx
;    
    and ds:flgs,NOT FLG_ENABLE_AUTO_RTS
    mov dx,ds:base
    add dx,4
    in al,dx
    or al,2
    out dx,al
;   
    pop dx
    pop ax
    ret
disable_auto_rts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:       FlushCom
;
;       DESCRIPTION:    Flush com
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_com   PROC far
    push ax
    push dx
;
    RequestSpinlock ds:com_spinlock
    mov dx,ds:base
    mov al,IER_BITS + 1
    inc dx
    out dx,al
    ReleaseSpinlock ds:com_spinlock
;   
    pop dx
    pop ax
    ret
flush_com Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       start_send
;
;       description:    Start send
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_send  PROC far
    push ax
    push dx
;
    test ds:flgs, FLG_ENABLE_AUTO_RTS
    jz com_send_timer_stopped
;
    mov bx,ds
    StopTimer

com_send_timer_stopped:
    RequestSpinlock ds:com_spinlock
    test ds:flgs, FLG_ENABLE_CTS
    jz com_send_enable
;
    mov dx,ds:base
    add dx,6
    in al,dx
    test al,10h
    jz com_send_ok

com_send_enable:
    test ds:flgs, FLG_ENABLE_AUTO_RTS
    jz com_send_start
;   
    mov dx,ds:base
    add dx,4
    in al,dx
    or al,2
    out dx,al

com_send_start:
    mov dx,ds:base
    inc dx
    mov al,IER_BITS + 3
    out dx,al
    
com_send_ok:
    ReleaseSpinlock ds:com_spinlock
    pop dx
    pop ax
    ret
start_send  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       set_dtr
;
;       description:    Set DTR signal
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dtr Proc far
    push ax
    push dx
;
    mov dx,ds:base
    add dx,4
    in al,dx
    or al,1
    out dx,al
;
    pop dx
    pop ax
    ret
set_dtr Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       reset_dtr
;
;       description:    Reset DTR signal
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_dtr   Proc far
    push ax
    push dx
;
    mov dx,ds:base
    add dx,4
    in al,dx
    and al,NOT 1
    out dx,al   
;   
    pop dx
    pop ax
    ret
reset_dtr   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       set_rts
;
;       description:    Set RTS signal
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rts Proc far
    push ax
    push dx
;   
    mov dx,ds:base
    add dx,4
    in al,dx
    or al,2
    out dx,al
;
    pop dx
    pop ax
    ret
set_rts Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       reset_rts
;
;       description:    Reset RTS signal
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_rts   Proc far
    push ax
    push dx
;
    mov dx,ds:base
    add dx,4
    in al,dx
    and al,NOT 2
    out dx,al   
;   
    pop dx
    pop ax
    ret
reset_rts   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       create_port
;
;       description:    Create port selector
;
;       RETURNS:    ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

port_tab:
pt00 DW OFFSET open_com,        SEG code
pt01 DW OFFSET close_com,       SEG code
pt02 DW OFFSET enable_cts,      SEG code
pt03 DW OFFSET disable_cts,     SEG code
pt04 DW OFFSET set_dtr,         SEG code
pt05 DW OFFSET reset_dtr,       SEG code
pt06 DW OFFSET set_rts,         SEG code
pt07 DW OFFSET reset_rts,       SEG code
pt08 DW OFFSET enable_auto_rts,     SEG code
pt09 DW OFFSET disable_auto_rts,    SEG code
pt10 DW OFFSET flush_com,       SEG code
pt11 DW OFFSET start_send,      SEG code

create_port Proc far
    push eax
    push cx
    push si
    push di
;
    mov eax,SIZE pccom_port_struc
    AllocateSmallGlobalMem
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov si,OFFSET port_tab
    xor di,di
    mov cx,12
    rep movs dword ptr es:[di],cs:[si]
;
    mov ax,ds:pds_base
    mov es:base,ax
    mov eax,ds:pds_baud_base
    mov es:baud_base,eax
;    
    pop di
    pop si
    pop cx
    pop eax
    ret
create_port Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       reserve_line_state
;
;       description:    Reserve line-state signals
;
;       PARAMETERS:     DS      Com device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reserve_line_state  Proc far
    push ax
    push dx
;    
    mov ds:cd_line_reserved,1
;    
    mov dx,ds:pds_base
    add dx,6
    in al,dx
    mov ds:pds_line,al
;   
    mov dx,ds:pds_base
    add dx,5
    in al,dx
;
    mov dx,ds:pds_base
    in al,dx
;   
    mov al,IER_BITS + 1
    inc dx
    out dx,al
;
    pop dx
    pop ax
    ret
reserve_line_state  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       device_set_dtr
;
;       description:    Device set DTR signal
;
;       PARAMETERS:     DS      Com device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

device_set_dtr  Proc far
    push ax
    push dx
;
    mov dx,ds:pds_base
    add dx,4
    in al,dx
    or al,1
    out dx,al
;
    pop dx
    pop ax
    ret
device_set_dtr  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       device_reset_dtr
;
;       description:    Device reset DTR signal
;
;       PARAMETERS:     DS      Com device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

device_reset_dtr    Proc far
    push ax
    push dx
;
    mov dx,ds:pds_base
    add dx,4
    in al,dx
    and al,NOT 1
    out dx,al   
;   
    pop dx
    pop ax
    ret
device_reset_dtr    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       get_line_state
;
;       description:    Get current line-state change
;
;       PARAMETERS:     DS      Com device selector
;
;       RETURNS:    AL      Line-state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_line_state  Proc far
    push dx
    mov dx,ds:pds_base
    add dx,6
    in al,dx
    pop dx
;    mov al,ds:pds_line
    shr al,4
    and al,0Fh
    ret
get_line_state  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       wait_for_line_state
;
;       description:    Wait for line-state change
;
;       PARAMETERS:     DS      Com device selector
;
;       RETURNS:    AL      Line-state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_line_state Proc far
    ClearSignal
    GetThread
    mov ds:pds_line_thread,ax
    WaitForSignal
    mov ds:pds_line_thread,0
;
    mov al,ds:pds_line
    shr al,4
    and al,0Fh
    ret
wait_for_line_state Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InitDetect
;
;       DESCRIPTION:    Init detect
;
;       PARAMETERS:     DX      Base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitDetect  Proc near
    push dx
    mov al,83h
    add dx,3
    out dx,al           ; set line control to divisor access
;
    sub dx,3
    mov al,12
    out dx,al           ; output LSB divisor latch
;
    inc dx
    mov al,0
    out dx,al           ; output MSB divisor latch
;
    inc dx
    mov al,1
    out dx,al           ; enable FIFOs if present
;
    mov al,3
    inc dx
    out dx,al           ; set line control 
;
    sub dx,2
    mov al,0
    out dx,al           ; enable rx ints and delta ints, disable tx, line ints
;
    add dx,3
    mov al,0Bh
    out dx,al           ; modem control, DTR = high, RTS = high
    pop dx
;
    push dx
    in al,dx
    add dx,2
    in al,dx
    add dx,3
    in al,dx
    inc dx
    in al,dx
    pop dx
    ret
InitDetect  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       DetectIrq
;
;       DESCRIPTION:    Detect IRQ for a serial base address
;
;       PARAMETERS:     DX      Base
;
;       RETURNS:    AL      IRQ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DetectIrq   Proc near
    push ebx
    push cx
    push ebp
;    
    SetupIrqDetect
;
    push dx
    inc dx
    mov al,IER_BITS + 2
    out dx,al           ; enable tx ints and delta ints, line ints
;
    add dx,3
    mov al,0Bh
    out dx,al           ; modem control, DTR = high, RTS = high
    pop dx
;   
    push dx
    in al,dx
    add dx,2
    in al,dx
    add dx,3
    in al,dx
    inc dx
    in al,dx
    pop dx
;
    mov ax,1
    WaitMilliSec
;
    push edx
    PollIrqDetect
    pop edx
    or eax,eax
    stc
    jz diDone
;
    mov ebp,eax
;    
    push dx
    inc dx
    xor al,al
    out dx,al
    pop dx
;
    push dx
    in al,dx
    add dx,2
    in al,dx
    add dx,2
    in al,dx
    add dx,2
    in al,dx
    pop dx
;
    mov ax,1
    WaitMilliSec
;
    SetupIrqDetect
;
    mov ax,1
    WaitMilliSec
;
    push edx
    PollIrqDetect
    pop edx
;
    not eax
    and eax,ebp
    stc
    jz diDone
;
    xor cx,cx
    mov ebx,1

diGetNrLoop:
    test eax,ebx
    jnz diGetNrDone
;
    shl ebx,1
    inc cx
    jmp diGetNrLoop

diGetNrDone:
    not ebx
    and eax,ebx
    stc
    jnz diDone
;
    mov ax,cx
    clc    

diDone:
    pop ebp
    pop cx
    pop ebx
    ret
DetectIrq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       AddPort
;
;       DESCRIPTION:    Add port to list of available ports
;
;       PARAMETERS:     DX      Base
;               AL      IRQ
;               ECX     Baud base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPort Proc near
    push ds
    push es
    pushad
;    
    push ax
    mov ax,SEG data
    mov ds,ax
;
    mov eax,SIZE pccom_device_struc
    AllocateSmallGlobalMem
    mov es:pds_base,dx
    mov es:pds_handle,0
    mov es:pds_line_thread,0
    mov es:pds_line,0
    mov es:pds_baud_base,ecx
    pop ax
    mov es:pds_irq,al
;
    mov bx,ds:sd_ports
    add bx,bx
    mov ds:[bx].sd_port_arr,es
    inc ds:sd_ports
;
    mov ax,es
    mov ds,ax
;    
    xor ax,ax
    xor dx,dx
    AddComPort
;    
    mov word ptr ds:cd_create_proc,OFFSET create_port
    mov word ptr ds:cd_create_proc+2,cs
;    
    mov word ptr ds:cd_reserve_line_proc,OFFSET reserve_line_state
    mov word ptr ds:cd_reserve_line_proc+2,cs
;    
    mov word ptr ds:cd_set_dtr_proc,OFFSET device_set_dtr
    mov word ptr ds:cd_set_dtr_proc+2,cs
;    
    mov word ptr ds:cd_reset_dtr_proc,OFFSET device_reset_dtr
    mov word ptr ds:cd_reset_dtr_proc+2,cs
;    
    mov word ptr ds:cd_get_line_state_proc,OFFSET get_line_state
    mov word ptr ds:cd_get_line_state_proc+2,cs
;    
    mov word ptr ds:cd_wait_for_line_state_proc,OFFSET wait_for_line_state
    mov word ptr ds:cd_wait_for_line_state_proc+2,cs
;
    popad
    pop es
    pop ds  
    ret
AddPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       RequestIRQs
;
;       DESCRIPTION:    Request IRQs for all ports
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RequestIRQs Proc near
    push ds
    push es
    pushad
;    
    mov ax,SEG data
    mov ds,ax
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET com_int
;    
    mov cx,ds:sd_ports
    or cx,cx
    jz riDone
;    
    mov bx,OFFSET sd_port_arr

riLoop:
    mov dx,[bx]
    or dx,dx
    jz riNext
;    
    push ds
    mov ds,dx
    mov al,ds:pds_irq
    mov ah,18h
    RequestIrqHandler
    pop ds

riNext:
    add bx,2
    loop riLoop

riDone:
    popad
    pop es
    pop ds  
    ret
RequestIRQs Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InitPciAdapter
;
;       DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     
;
;       RETURNS:    NC      Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DriverName  DB 'SerialPCI',0

PciVendorTab:
pci00   DW 1409h, 7168h
pci01   DW 13FEh, 1600h
pci02   DW 13FEh, 16FFh
pci03   DW 0,     0

InitPciAdapter  Proc near
    mov si,OFFSET PciVendorTab
init_pci_loop:
    xor ax,ax
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz init_pci_done
;
    FindPciDevice
    jnc init_pci_found
;
    add si,4
    jmp init_pci_loop

init_pci_found:
    xor ch,ch
    mov cl,PCI_command_reg
    ReadPciWord
    or al,PCI_command_IO OR PCI_command_busmstr
    WritePciWord
;
    mov cl,10h
    ReadPciDword
    mov dx,ax
    and dx,0FF00h
;
    xor ch,ch
    mov cl,PCI_interrupt_line
    ReadPciByte
;
    mov ecx,921600
    call AddPort
;
    add dx,8
    call AddPort    
    clc

init_pci_done:
    ret
InitPciAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       Init_pci
;
;       DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;       RETURNS:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init_pci    Proc far
    push ds
    push es
    pusha
;
    mov ax,25
    WaitMilliSec
; 
    mov dx,3F8h
    call InitDetect
; 
    mov dx,2F8h
    call InitDetect
; 
    mov dx,3E8h
    call InitDetect
; 
    mov dx,2E8h
    call InitDetect
; 
    mov dx,3F8h
    call DetectIrq
    jc dt1
;
    mov ecx,115200
    call AddPort    
    call InitDetect

dt1:
    mov dx,2F8h
    call DetectIrq
    jc dt2
;
    mov ecx,115200
    call AddPort
    call InitDetect

dt2:   
    mov dx,3E8h
    call DetectIrq
    jc dt3
;    
    mov ecx,115200
    call AddPort
    call InitDetect

dt3:   
    mov dx,2E8h
    call DetectIrq
    jc dtpci
;    
    mov ecx,115200
    call AddPort
    call InitDetect

dtpci:
    call InitPciAdapter
    call RequestIRQs
;    mov ax,SEG data
;    mov ds,ax
;    mov cx,ds:sd_ports
;
    popa
    pop es
    pop ds
    retf32
init_pci    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       init
;
;       description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET init_pci
    HookInitPci
    clc
    ret
init    Endp

code    ENDS

    END init
