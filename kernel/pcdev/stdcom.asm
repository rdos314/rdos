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

mem_reg_struc   STRUC

mr_hr           DB ?
mr_ier          DB ?
mr_isr_fcr      DB ?
mr_lcr          DB ?
mr_mcr          DB ?
mr_lsr          DB ?
mr_msr          DB ?
mr_spr          DB ?

mem_reg_struc   ENDS

io_com_port_struc    STRUC

iopps_base_struc  com_port_struc <>

iopps_char_time       DD ?
iopps_flgs            DB ?
iopps_base            DW ?
iopps_dev_handle      DW ?
iopps_baud_base       DD ?

io_com_port_struc    ENDS

io_com_device_struc   STRUC

iopds_base_struc    com_device_struc <>

iopds_base      DW ?
iopds_handle    DW ?
iopds_baud_base     DD ?
iopds_line_thread   DW ?
iopds_line      DB ?
iopds_irq       DB ?

io_com_device_struc   ENDS

mem_com_device_struc   STRUC

mempds_base_struc    com_device_struc <>

mempds_offset   DD ?
mempds_sel      DW ?
mempds_handle    DW ?
mempds_baud_base     DD ?
mempds_line_thread   DW ?
mempds_line      DB ?

mem_com_device_struc   ENDS

ox_bar_header   STRUC

oxb_class           DD ?
oxb_uart_count      DD ?
oxb_irq_state       DD ?
oxb_irq_enable      DD ?
oxb_irq_disable     DD ?
oxb_wake_enable     DD ?
oxb_wake_disable    DD ?

ox_bar_header   ENDS

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
;           NAME:           io_modem
;
;           DESCRIPTION:    Modem signals changed, IO version
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_modem   Proc near
    mov dx,ds:iopps_base
    add dx,6
    in al,dx
    mov ah,al
;       
    test al,10h
    jz io_modem_no_cts
;
    test ds:iopps_flgs, FLG_ENABLE_CTS
    jz io_modem_no_cts
;    
    mov cx,ds:send_count
    or cx,cx
    jz io_modem_no_cts
;
    mov dx,ds:iopps_base
    inc dx
    mov al,IER_BITS + 3
    out dx,al

io_modem_no_cts:   
    push ds
    mov ds,ds:iopps_dev_handle
    mov ds:iopds_line,ah
    mov bx,ds:iopds_line_thread
    pop ds
    or bx,bx
    jz io_modem_no_signal
;
    Signal

io_modem_no_signal:    
    ret
io_modem   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           io_line_err
;
;           DESCRIPTION:    Line error occured, IO version
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_line_err    PROC near
    mov dx,ds:iopps_base
    add dx,5
    in al,dx
    ret
io_line_err    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           io_rec
;
;           DESCRIPTION:    Received data, IO version
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_rec  PROC near
    mov es,ds:rec_buf
    mov dx,ds:iopps_base
    RequestSpinlock ds:com_spinlock
    in al,dx
;    test ds:iopps_flgs, FLG_ENABLE_AUTO_RTS
;    jz rec_pr_save
;
;    push ax
;       mov dx,ds:base
;       add dx,4
;       in al,dx
;       test al,2
;       pop ax
;       jnz rec_exit

io_rec_pr_save:
    mov cx,ds:rec_count
    cmp cx,ds:rec_size
    je io_rec_exit
;    
    inc cx
    mov ds:rec_count,cx
    mov bx,ds:rec_tail          ; get tail pointer
    mov es:[bx],al              ; store char
    inc bx
    cmp bx,ds:rec_size
    jnz io_rec_no_wrap
;
    xor bx,bx
    
io_rec_no_wrap:
    mov ds:rec_tail,bx
    ReleaseSpinlock ds:com_spinlock
;
    mov bx,ds:avail_obj
    or bx,bx
    jz io_rec_done
;
    mov es,bx
    SignalWait
    mov ds:avail_obj,0
    jmp io_rec_done
    
io_rec_exit:
    ReleaseSpinlock ds:com_spinlock

io_rec_done:
    ret
io_rec  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IO_RTS_OFF
;
;           DESCRIPTION:    Delayed RTS off, IO version
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_rts_off PROC far
    mov ds,cx
    mov di,ds:send_count
    or di,di
    jnz io_rts_off_done
;
    push ax
    push dx
    mov dx,ds:iopps_base
    add dx,5
    in al,dx
    test al,40h
    pop dx
    pop ax
    jnz io_rts_off_dis
;
    add eax,ds:iopps_char_time
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET io_rts_off
    mov bx,cx
    StartTimer
    jmp io_rts_off_done
    
io_rts_off_dis:
    mov dx,ds:iopps_base
    add dx,4
    in al,dx
    and al,NOT 2
    out dx,al

io_rts_off_done:
    retf32
io_rts_off Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           io_trans
;
;           DESCRIPTION:    Send data, IO version
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_trans    PROC near
    mov es,ds:send_buf
    mov dx,ds:iopps_base
    RequestSpinlock ds:com_spinlock
    mov cx,ds:send_count
    or cx,cx                    ;  buffer empty ?
    jnz io_trans_not_empty

io_trans_end:      
    mov al,IER_BITS + 1
    inc dx
    out dx,al
    ReleaseSpinlock ds:com_spinlock
;
    test ds:iopps_flgs, FLG_ENABLE_AUTO_RTS
    jz io_trans_signal_wait
;
    GetSystemTime
    add eax,ds:iopps_char_time
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET io_rts_off
    mov bx,ds
    mov cx,bx
    StopTimer
    StartTimer
    mov es,ds:send_buf
        
io_trans_signal_wait:
    mov bx,ds:send_wait
    or bx,bx
    jz io_trans_exit
;
    Signal
    jmp io_trans_exit
    
io_trans_not_empty:    
    test ds:iopps_flgs, FLG_ENABLE_CTS
    jz io_trans_send
;
    add dx,6
    in al,dx
    sub dx,6
    test al,10h
    jz io_trans_end

io_trans_send:
    dec cx
    mov ds:send_count,cx
    mov bx,ds:send_head                 ; get head pointer
    mov al,es:[bx]                      ; get char
    out dx,al                           ; transmitt char
    inc bx
    cmp bx,ds:send_size
    jnz io_trans_not_wrap

    xor bx,bx
    
io_trans_not_wrap:
    mov ds:send_head,bx
    ReleaseSpinlock ds:com_spinlock

io_trans_exit:
    ret
io_trans    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       IO_COM_INT
;
;       DESCRIPTION:    Serial interrupt
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_serial_tab:
ist_mod  DW OFFSET io_modem
ist_tx   DW OFFSET io_trans
ist_rx   DW OFFSET io_rec
ist_li   DW OFFSET io_line_err

io_com_int Proc far
    mov ax,ds:iopds_handle
    or ax,ax
    jz io_com_int_inactive
;
    mov ds,ax

io_com_int_loop:
    mov dx,ds:iopps_base
    add dx,2
    in al,dx
    test al,1
    jnz io_com_int_done
;   
    mov bl,al
    xor bh,bh
    and bx,6
    call word ptr cs:[bx].io_serial_tab
    jmp io_com_int_loop

io_com_int_inactive:
    mov dx,ds:iopds_base
    add dx,2
    in al,dx
    test al,1
    jnz io_com_int_done
;   
    mov dx,ds:iopds_base
    add dx,6
    in al,dx
    mov ds:iopds_line,al
;   
    mov dx,ds:iopds_base
    add dx,5
    in al,dx
;
    mov dx,ds:iopds_base
    in al,dx
;   
    mov al,IER_BITS + 1
    inc dx
    out dx,al
;   
    mov bx,ds:iopds_line_thread
    or bx,bx
    jz io_com_int_done
;
    Signal

io_com_int_done:   
    retf32
io_com_int Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       MEM_COM_INT
;
;       DESCRIPTION:    Serial interrupt
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_com_int Proc far

mem_com_int_done:   
    retf32
mem_com_int Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_open_com
;
;       description:    Open a serial port, IO version
;
;       PARAMETERS:     DS      Port selector
;                       ES      Device selector
;                       AH      # of data bits
;                       BL      # of stop bits
;                       BH      parity
;                       ECX     baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_open_com    Proc far
    push ax
    push dx
    push si
;
    push ax
    RequestSpinlock ds:com_spinlock
    mov es:iopds_handle,ds
    mov ds:iopps_dev_handle,es
    mov ds:iopps_flgs,0
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
    je io_open_even
;   
    cmp bh,'O'
    je io_open_odd
;   
    jmp io_open_parity_done

io_open_even:
    inc dl
    or al,18h
    jmp io_open_parity_done

io_open_odd:
    inc dl
    or al,8

io_open_parity_done:
    push eax
    push edx
;
    push dx    
    mov eax,ds:iopps_baud_base
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
    mov ds:iopps_char_time,eax
;
    pop edx
    pop eax
;
    push ax
    or al,80h
    mov dx,ds:iopps_base
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
    jnz io_open_set_dtr
;
    or al,1

io_open_set_dtr:
    out dx,al           ; modem control, DTR = high, RTS = high
;
    mov dx,ds:iopps_base
    in al,dx
    add dx,5
    in al,dx
    inc dx
    in al,dx
;
    pop si
    pop dx
    pop ax  
    retf32
io_open_com    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_close_com
;
;       description:    Close serial port, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_close_com   Proc far
    push es
    push ax
    push dx
;
    mov dx,ds:iopps_base
    inc dx
    xor al,al
    mov ah,ds:line_reserved
    or ah,ah
    jz io_close_com_not_reserved
;   
    or al,IER_BITS

io_close_com_not_reserved:
    out dx,al           ; disable rx, tx, line and modem ints
;   
    mov es,ds:iopps_dev_handle
    mov es:iopds_handle,0
;
    pop dx
    pop ax
    pop es
    retf32
io_close_com   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           IoEnableCts
;
;       DESCRIPTION:    Enable CTS signal, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_enable_cts  PROC far
    cmp ds:line_reserved,0
    jne io_enable_cts_done
;    
    or ds:iopps_flgs,FLG_ENABLE_CTS

io_enable_cts_done:
    retf32
io_enable_cts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           IoDisableCts
;
;       DESCRIPTION:    Disable CTS signal, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_disable_cts PROC far
    and ds:iopps_flgs,NOT FLG_ENABLE_CTS
    retf32
io_disable_cts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           IoEnableAutoRts
;
;       DESCRIPTION:    Enable automatic RTS on send, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_enable_auto_rts PROC far
    push ax
    push dx
;
    or ds:iopps_flgs,FLG_ENABLE_AUTO_RTS
    mov dx,ds:iopps_base
    add dx,4
    in al,dx
    and al,NOT 2
    out dx,al
;   
    pop dx
    pop ax
    retf32
io_enable_auto_rts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           IoDisableAutoRts
;
;       DESCRIPTION:    Disable automatic RTS on send, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_disable_auto_rts    PROC far
    push ax
    push dx
;    
    and ds:iopps_flgs,NOT FLG_ENABLE_AUTO_RTS
    mov dx,ds:iopps_base
    add dx,4
    in al,dx
    or al,2
    out dx,al
;   
    pop dx
    pop ax
    retf32
io_disable_auto_rts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           IoFlushCom
;
;       DESCRIPTION:    Flush com, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_flush_com   PROC far
    push ax
    push dx
;
    RequestSpinlock ds:com_spinlock
    mov dx,ds:iopps_base
    mov al,IER_BITS + 1
    inc dx
    out dx,al
    ReleaseSpinlock ds:com_spinlock
;   
    pop dx
    pop ax
    retf32
io_flush_com Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           IoResetPort
;
;       DESCRIPTION:    Reset com, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_reset_port   PROC far
    retf32
io_reset_port  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_start_send
;
;       description:    Start send, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_start_send  PROC far
    push ax
    push dx
;
    test ds:iopps_flgs, FLG_ENABLE_AUTO_RTS
    jz io_com_send_timer_stopped
;
    mov bx,ds
    StopTimer

io_com_send_timer_stopped:
    RequestSpinlock ds:com_spinlock
    test ds:iopps_flgs, FLG_ENABLE_CTS
    jz io_com_send_enable
;
    mov dx,ds:iopps_base
    add dx,6
    in al,dx
    test al,10h
    jz io_com_send_ok

io_com_send_enable:
    test ds:iopps_flgs, FLG_ENABLE_AUTO_RTS
    jz io_com_send_start
;   
    mov dx,ds:iopps_base
    add dx,4
    in al,dx
    or al,2
    out dx,al

io_com_send_start:
    mov dx,ds:iopps_base
    inc dx
    mov al,IER_BITS + 3
    out dx,al
    
io_com_send_ok:
    ReleaseSpinlock ds:com_spinlock
    pop dx
    pop ax
    retf32
io_start_send  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_set_dtr
;
;       description:    Set DTR signal, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_set_dtr Proc far
    push ax
    push dx
;
    mov dx,ds:iopps_base
    add dx,4
    in al,dx
    or al,1
    out dx,al
;
    pop dx
    pop ax
    retf32
io_set_dtr Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_reset_dtr
;
;       description:    Reset DTR signal, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_reset_dtr   Proc far
    push ax
    push dx
;
    mov dx,ds:iopps_base
    add dx,4
    in al,dx
    and al,NOT 1
    out dx,al   
;   
    pop dx
    pop ax
    retf32
io_reset_dtr   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_set_rts
;
;       description:    Set RTS signal, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_set_rts Proc far
    push ax
    push dx
;   
    mov dx,ds:iopps_base
    add dx,4
    in al,dx
    or al,2
    out dx,al
;
    pop dx
    pop ax
    retf32
io_set_rts Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_reset_rts
;
;       description:    Reset RTS signal, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_reset_rts   Proc far
    push ax
    push dx
;
    mov dx,ds:iopps_base
    add dx,4
    in al,dx
    and al,NOT 2
    out dx,al   
;   
    pop dx
    pop ax
    retf32
io_reset_rts   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_reset_com
;
;       description:    Reset com, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_reset_com   Proc far
    retf32
io_reset_com   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_create_port
;
;       description:    Create port selector, IO version
;
;       RETURNS:        ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_port_tab:
ipt00 DD OFFSET io_open_com,        SEG code
ipt01 DD OFFSET io_close_com,       SEG code
ipt02 DD OFFSET io_enable_cts,      SEG code
ipt03 DD OFFSET io_disable_cts,     SEG code
ipt04 DD OFFSET io_set_dtr,         SEG code
ipt05 DD OFFSET io_reset_dtr,       SEG code
ipt06 DD OFFSET io_set_rts,         SEG code
ipt07 DD OFFSET io_reset_rts,       SEG code
ipt08 DD OFFSET io_enable_auto_rts, SEG code
ipt09 DD OFFSET io_disable_auto_rts,SEG code
ipt10 DD OFFSET io_flush_com,       SEG code
ipt11 DD OFFSET io_start_send,      SEG code
ipt12 DD OFFSET io_reset_port,      SEG code

io_create_port Proc far
    push eax
    push cx
    push si
    push di
;
    mov eax,SIZE io_com_port_struc
    AllocateSmallGlobalMem
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov si,OFFSET io_port_tab
    xor di,di
    mov cx,2 * 13
    rep movs dword ptr es:[di],cs:[si]
;
    mov ax,ds:iopds_base
    mov es:iopps_base,ax
    mov eax,ds:iopds_baud_base
    mov es:iopps_baud_base,eax
;    
    pop di
    pop si
    pop cx
    pop eax
    retf32
io_create_port Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_reserve_line_state
;
;       description:    Reserve line-state signals, IO version
;
;       PARAMETERS:     DS      Com device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_reserve_line_state  Proc far
    push ax
    push dx
;    
    mov ds:cd_line_reserved,1
;    
    mov dx,ds:iopds_base
    add dx,6
    in al,dx
    mov ds:iopds_line,al
;   
    mov dx,ds:iopds_base
    add dx,5
    in al,dx
;
    mov dx,ds:iopds_base
    in al,dx
;   
    mov al,IER_BITS + 1
    inc dx
    out dx,al
;
    pop dx
    pop ax
    retf32
io_reserve_line_state  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_device_set_dtr
;
;       description:    Device set DTR signal, IO version
;
;       PARAMETERS:     DS      Com device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_device_set_dtr  Proc far
    push ax
    push dx
;
    mov dx,ds:iopds_base
    add dx,4
    in al,dx
    or al,1
    out dx,al
;
    pop dx
    pop ax
    retf32
io_device_set_dtr  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_device_reset_dtr
;
;       description:    Device reset DTR signal, IO version
;
;       PARAMETERS:     DS      Com device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_device_reset_dtr    Proc far
    push ax
    push dx
;
    mov dx,ds:iopds_base
    add dx,4
    in al,dx
    and al,NOT 1
    out dx,al   
;   
    pop dx
    pop ax
    retf32
io_device_reset_dtr    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_get_line_state
;
;       description:    Get current line-state change, IO version
;
;       PARAMETERS:     DS      Com device selector
;
;       RETURNS:        AL      Line-state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_get_line_state  Proc far
    push dx
    mov dx,ds:iopds_base
    add dx,6
    in al,dx
    pop dx
;    mov al,ds:iopds_line
    shr al,4
    and al,0Fh
    retf32
io_get_line_state  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           io_wait_for_line_state
;
;       description:    Wait for line-state change, IO version
;
;       PARAMETERS:     DS      Com device selector
;
;       RETURNS:        AL      Line-state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_wait_for_line_state Proc far
    ClearSignal
    GetThread
    mov ds:iopds_line_thread,ax
    WaitForSignal
    mov ds:iopds_line_thread,0
;
    mov al,ds:iopds_line
    shr al,4
    and al,0Fh
    retf32
io_wait_for_line_state Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_create_port
;
;       description:    Create port selector, mem version
;
;       RETURNS:        ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_port_tab:

mem_create_port Proc far
    int 3
    retf32
mem_create_port Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_reserve_line_state
;
;       description:    Reserve line-state signals, mem version
;
;       PARAMETERS:     DS      Com device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_reserve_line_state  Proc far
    push es
    push ax
    push ebx
;    
    int 3
    mov ds:cd_line_reserved,1
;    
    mov ebx,ds:mempds_offset
    mov es,ds:mempds_sel
    mov al,es:[ebx].mr_msr
    mov ds:mempds_line,al    
;
    mov al,es:[ebx].mr_lsr    
    mov al,es:[ebx].mr_hr    
;
    mov al,IER_BITS + 1
    mov es:[ebx].mr_ier,al
;
    pop ebx
    pop ax
    pop es
    retf32
mem_reserve_line_state  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_device_set_dtr
;
;       description:    Device set DTR signal, mem version
;
;       PARAMETERS:     DS      Com device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_device_set_dtr  Proc far
    push es
    push ax
    push ebx
;
    int 3
    mov ebx,ds:mempds_offset
    mov es,ds:mempds_sel
;
    mov al,es:[ebx].mr_mcr
    or al,1
    mov es:[ebx].mr_mcr,al    
;
    pop ebx
    pop ax
    pop es
    retf32
mem_device_set_dtr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_device_reset_dtr
;
;       description:    Device reset DTR signal, mem version
;
;       PARAMETERS:     DS      Com device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_device_reset_dtr    Proc far
    push es
    push ax
    push ebx
;
    int 3
    mov ebx,ds:mempds_offset
    mov es,ds:mempds_sel
;
    mov al,es:[ebx].mr_mcr
    and al,NOT 1
    mov es:[ebx].mr_mcr,al    
;   
    pop ebx
    pop ax
    pop es
    retf32
mem_device_reset_dtr    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_get_line_state
;
;       description:    Get current line-state change, mem version
;
;       PARAMETERS:     DS      Com device selector
;
;       RETURNS:        AL      Line-state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_get_line_state  Proc far
    push es
    push ebx
;    
    int 3
    mov ebx,ds:mempds_offset
    mov es,ds:mempds_sel
;
    mov al,es:[ebx].mr_msr
    shr al,4
    and al,0Fh
;
    pop ebx
    pop es    
    retf32
mem_get_line_state  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_wait_for_line_state
;
;       description:    Wait for line-state change, mem version
;
;       PARAMETERS:     DS      Com device selector
;
;       RETURNS:        AL      Line-state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_wait_for_line_state Proc far
    int 3
    ClearSignal
    GetThread
    mov ds:mempds_line_thread,ax
    WaitForSignal
    mov ds:mempds_line_thread,0
;
    mov al,ds:mempds_line
    shr al,4
    and al,0Fh
    retf32
mem_wait_for_line_state Endp

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
;       NAME:       AddIoPort
;
;       DESCRIPTION:    Add IO port to list of available ports
;
;       PARAMETERS:     DX      Base
;               AL      IRQ
;               ECX     Baud base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIoPort Proc near
    push ds
    push es
    pushad
;    
    push ax
    mov ax,SEG data
    mov ds,ax
;
    mov eax,SIZE io_com_device_struc
    AllocateSmallGlobalMem
    mov es:iopds_base,dx
    mov es:iopds_handle,0
    mov es:iopds_line_thread,0
    mov es:iopds_line,0
    mov es:iopds_baud_base,ecx
    pop ax
    mov es:iopds_irq,al
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
    mov dword ptr ds:cd_create_proc,OFFSET io_create_port
    mov dword ptr ds:cd_create_proc+4,cs
;    
    mov dword ptr ds:cd_reserve_line_proc,OFFSET io_reserve_line_state
    mov dword ptr ds:cd_reserve_line_proc+4,cs
;    
    mov dword ptr ds:cd_set_dtr_proc,OFFSET io_device_set_dtr
    mov dword ptr ds:cd_set_dtr_proc+4,cs
;    
    mov dword ptr ds:cd_reset_dtr_proc,OFFSET io_device_reset_dtr
    mov dword ptr ds:cd_reset_dtr_proc+4,cs
;    
    mov dword ptr ds:cd_get_line_state_proc,OFFSET io_get_line_state
    mov dword ptr ds:cd_get_line_state_proc+4,cs
;    
    mov dword ptr ds:cd_wait_for_line_state_proc,OFFSET io_wait_for_line_state
    mov dword ptr ds:cd_wait_for_line_state_proc+4,cs
;
    popad
    pop es
    pop ds  
    ret
AddIoPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddMemPort
;
;       DESCRIPTION:    Add mem port to list of available ports
;
;       PARAMETERS:     DS:EBX  Base
;                       AL      IRQ
;                       ECX     Baud base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddMemPort Proc near
    push ds
    push es
    pushad
;    
    push ax
    mov eax,SIZE mem_com_device_struc
    AllocateSmallGlobalMem
    mov es:mempds_sel,ds
    mov es:mempds_offset,ebx
    mov es:mempds_handle,0
    mov es:mempds_line_thread,0
    mov es:mempds_line,0
    mov es:mempds_baud_base,ecx
    mov ax,es
    mov ds,ax
    pop ax
;
    push es
    mov di,cs
    mov es,di
    mov edi,OFFSET mem_com_int
    RequestMsiHandler
    pop es
;
    mov ax,SEG data
    mov ds,ax
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
    mov dword ptr ds:cd_create_proc,OFFSET mem_create_port
    mov dword ptr ds:cd_create_proc+4,cs
;    
    mov dword ptr ds:cd_reserve_line_proc,OFFSET mem_reserve_line_state
    mov dword ptr ds:cd_reserve_line_proc+4,cs
;    
    mov dword ptr ds:cd_set_dtr_proc,OFFSET mem_device_set_dtr
    mov dword ptr ds:cd_set_dtr_proc+4,cs
;    
    mov dword ptr ds:cd_reset_dtr_proc,OFFSET mem_device_reset_dtr
    mov dword ptr ds:cd_reset_dtr_proc+4,cs
;    
    mov dword ptr ds:cd_get_line_state_proc,OFFSET mem_get_line_state
    mov dword ptr ds:cd_get_line_state_proc+4,cs
;    
    mov dword ptr ds:cd_wait_for_line_state_proc,OFFSET mem_wait_for_line_state
    mov dword ptr ds:cd_wait_for_line_state_proc+4,cs
;
    popad
    pop es
    pop ds  
    ret
AddMemPort Endp

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
    mov edi,OFFSET io_com_int
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
    mov al,ds:iopds_irq
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
    call AddIoPort
;
    add dx,8
    call AddIoPort    
    clc

init_pci_done:
    ret
InitPciAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitMemPci
;
;       DESCRIPTION:    Init memory-based PCI adapter if found
;
;       PARAMETERS:     
;
;       RETURNS:        NC      Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemPciVendorTab:
mpci00  DW 1415h, 0C208h
mpci01  DW 0,     0

InitMemPci  Proc near
    mov si,OFFSET MemPciVendorTab

mem_init_pci_loop:
    xor ax,ax
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz mem_init_pci_done
;
    FindPciDevice
    jnc mem_init_pci_found
;
    add si,4
    jmp mem_init_pci_loop

mem_init_pci_found:
    push cx
    mov eax,2000h
    AllocateBigLinear
    pop cx
;
    mov cl,10h
    ReadPciDword
    and al,0F0h
;
    push ebx
    push ecx
;    
    xor ebx,ebx
    mov al,67h
    SetPageEntry
;
    add eax,1000h
    add edx,1000h    
    SetPageEntry
    sub edx,1000h
;
    AllocateGdt
    mov ecx,2000h
    CreateDataSelector16
    mov ds,bx
;
    pop ecx
    pop ebx
;
    mov eax,ds:oxb_uart_count
    or eax,eax
    jz mem_init_pci_done        
;       
    GetPciMsiX
    jc mem_init_pci_done    
;
    cmp dl,al
    jb mem_init_pci_done
;    
    EnablePciMsiX
;
    xor edx,edx

mem_init_pci_setup:
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc mem_init_pci_done
;    
    SetupPciMsiXEntry
;
    push ecx
    mov ecx,3906250
    call AddMemPort
    pop ecx
;
    inc edx
    cmp edx,ds:oxb_uart_count
    jne mem_init_pci_setup
    clc

mem_init_pci_done:
    ret
InitMemPci  Endp
    

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
    mov dx,2A0h
    call InitDetect
; 
    mov dx,2A8h
    call InitDetect
; 
    mov dx,3F8h
    call DetectIrq
    jc dt1
;
    mov ecx,115200
    call AddIoPort    
    call InitDetect

dt1:
    mov dx,2F8h
    call DetectIrq
    jc dt2
;
    mov ecx,115200
    call AddIoPort
    call InitDetect

dt2:   
    mov dx,3E8h
    call DetectIrq
    jc dt3
;    
    mov ecx,115200
    call AddIoPort
    call InitDetect

dt3:   
    mov dx,2E8h
    call DetectIrq
    jc dt4
;    
    mov ecx,115200
    call AddIoPort
    call InitDetect

dt4:   
    mov dx,2A0h
    call DetectIrq
    jc dt5
;    
    mov ecx,115200
    call AddIoPort
    call InitDetect

dt5:   
    mov dx,2A8h
    call DetectIrq
    jc dtpci
;    
    mov ecx,115200
    call AddIoPort
    call InitDetect

dtpci:
    call InitPciAdapter
    call RequestIRQs
    call InitMemPci
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
