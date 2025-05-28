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

INCLUDE ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\acpi\pci.inc
include ..\os\com.inc
include ..\os\protseg.def
include ..\os\core.inc

MAX_PORTS       = 16
MAX_IRQS    = 16
MAX_IRQ_SHARE   = 4

IER_BITS    = 8

FLG_ENABLE_CTS  = 1
FLG_ENABLE_AUTO_RTS  = 2
FLG_FINTEK     = 4

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
iopps_id              DB ?
iopps_base            DW ?
iopps_dev_handle      DW ?
iopps_baud_base       DD ?

io_com_port_struc    ENDS

io_com_device_struc   STRUC

iopds_base_struc    com_device_struc <>

iopds_base          DW ?
iopds_handle        DW ?
iopds_baud_base     DD ?
iopds_line_thread   DW ?
iopds_line          DB ?
iopds_irq           DB ?
iopds_flags         DB ?
iopds_id            DB ?
iopds_port_nr       DW ?

io_com_device_struc   ENDS

mem_com_port_struc    STRUC

mempps_base_struc  com_port_struc <>

mempps_char_time    DD ?
mempps_baud_base    DD ?
mempps_offset       DD ?
mempps_sel          DW ?
mempps_dev_handle   DW ?
mempps_flgs         DB ?

mem_com_port_struc    ENDS

mem_com_device_struc   STRUC

mempds_base_struc    com_device_struc <>

mempds_offset       DD ?
mempds_sel          DW ?
mempds_handle       DW ?
mempds_baud_base    DD ?
mempds_line_thread  DW ?
mempds_line         DB ?

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

mem_share_struc  STRUC

ms_count            DW ?
ms_dev_sel          DW ?
ms_com_dev_arr      DW 16 DUP(?)

mem_share_struc  ENDS

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
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetStdComPar
;
;   DESCRIPTION:    Get std com parame
;
;   PARAMETERS:     AL      Port #
;
;   RETURNS:        NC      OK
;                       AL  IRQ
;                       DX  IO base
;                       ECX Baud base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_std_com_par_name    DB 'Get Std Com Param', 0

get_std_com_par Proc far
    push ds
    push es
    push bx
;
    mov bx,SEG data
    mov ds,bx
    mov bx,OFFSET sd_port_arr
    mov cx,ds:sd_ports
    movzx ax,al
    or cx,cx
    jz gscpFail

gscpLoop:
    mov es,ds:[bx]
    cmp ax,es:iopds_port_nr
    je gscpFound
;
    add bx,2
    loop gscpLoop

gscpFail:
    stc
    jmp gscpDone

gscpFound:
    mov dx,es:iopds_base
    mov ecx,es:iopds_baud_base
    mov al,es:iopds_irq
    clc

gscpDone:
    pop bx
    pop es
    pop ds
    retf32
get_std_com_par     ENDP    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FullDuplex
;
;           DESCRIPTION:    Check for full duplex (always true)
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

full_duplex PROC far
    stc
    retf32
full_duplex Endp

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
    xor bx,bx
    xchg bx,ds:avail_obj
    or bx,bx
    jz io_rec_done
;
    mov es,bx
    SignalWait
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
    test ds:iopps_flgs, FLG_FINTEK
    jnz io_trans_signal_wait
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
    NotifyIrqActivity
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
    NotifyIrqActivity
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
;           NAME:           mem_modem
;
;           DESCRIPTION:    Modem signals changed, mem version
;
;           PARAMETERS:     DS      Port sel
;                           ES:EBX  Register address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_modem   Proc near
    mov al,es:[ebx].mr_msr
    mov ah,al
;       
    test al,10h
    jz mem_modem_no_cts
;
    test ds:mempps_flgs, FLG_ENABLE_CTS
    jz mem_modem_no_cts
;    
    mov cx,ds:send_count
    or cx,cx
    jz mem_modem_no_cts
;
    mov al,IER_BITS + 3
    mov es:[ebx].mr_ier,al

mem_modem_no_cts:   
    push bx
    push ds
    mov ds,ds:mempps_dev_handle
    mov ds:mempds_line,ah
    mov bx,ds:mempds_line_thread
    pop ds
    or bx,bx
    jz mem_modem_no_signal
;
    Signal

mem_modem_no_signal:    
    pop bx
    ret
mem_modem   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_line_err
;
;           DESCRIPTION:    Line error occured, mem version
;
;           PARAMETERS:     DS      Port sel
;                           ES:EBX  Register address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_line_err    PROC near
    mov al,es:[ebx].mr_lsr
    ret
mem_line_err    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_rec
;
;           DESCRIPTION:    Received data, mem version
;
;           PARAMETERS:     DS      Port sel
;                           ES:EBX  Register address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_rec  PROC near
    push es
    push bx
;    
    RequestSpinlock ds:com_spinlock
    mov al,es:[ebx]
    mov es,ds:rec_buf

mem_rec_pr_save:
    mov cx,ds:rec_count
    cmp cx,ds:rec_size
    je mem_rec_exit
;    
    inc cx
    mov ds:rec_count,cx
    mov bx,ds:rec_tail          ; get tail pointer
    mov es:[bx],al              ; store char
    inc bx
    cmp bx,ds:rec_size
    jnz mem_rec_no_wrap
;
    xor bx,bx
    
mem_rec_no_wrap:
    mov ds:rec_tail,bx
    ReleaseSpinlock ds:com_spinlock
;
    xor bx,bx
    xchg bx,ds:avail_obj
    or bx,bx
    jz mem_rec_done
;
    mov es,bx
    SignalWait
    jmp mem_rec_done
    
mem_rec_exit:
    ReleaseSpinlock ds:com_spinlock

mem_rec_done:
    pop bx
    pop es
    ret
mem_rec  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MEM_RTS_OFF
;
;           DESCRIPTION:    Delayed RTS off, mem version
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_rts_off PROC far
    mov ds,cx
    mov di,ds:send_count
    or di,di
    jnz mem_rts_off_done
;
    mov ebx,ds:mempps_offset
    mov es,ds:mempps_sel
;
    push ax
    mov al,es:[ebx].mr_lsr
    test al,40h
    pop ax
    jnz mem_rts_off_dis
;
    add eax,ds:mempps_char_time
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET mem_rts_off
    mov bx,cx
    StartTimer
    jmp mem_rts_off_done
    
mem_rts_off_dis:
    mov al,es:[ebx].mr_mcr
    and al,NOT 2
    mov es:[ebx].mr_mcr,al

mem_rts_off_done:
    retf32
mem_rts_off Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_trans
;
;           DESCRIPTION:    Send data, mem version
;
;           PARAMETERS:     DS      Port sel
;                           ES:EBX  Register address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_trans    PROC near
    push fs
;    
    mov fs,ds:send_buf
    RequestSpinlock ds:com_spinlock
    mov cx,ds:send_count
    or cx,cx                    ;  buffer empty ?
    jnz mem_trans_not_empty

mem_trans_end:      
    mov al,IER_BITS + 1
    mov es:[ebx].mr_ier,al
    ReleaseSpinlock ds:com_spinlock
;
    test ds:mempps_flgs, FLG_ENABLE_AUTO_RTS
    jz mem_trans_signal_wait
;
    push ds
    push es
    push bx
    GetSystemTime
    add eax,ds:mempps_char_time
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET mem_rts_off
    mov bx,ds
    mov cx,bx
    StopTimer
    StartTimer
    pop bx
    pop es
    pop ds

mem_trans_signal_wait:
    push bx
    mov bx,ds:send_wait
    or bx,bx
    jz mem_trans_pop_exit
;
    Signal

mem_trans_pop_exit:
    pop bx    
    jmp mem_trans_exit
    
mem_trans_not_empty:    
    test ds:mempps_flgs, FLG_ENABLE_CTS
    jz mem_trans_send
;
    mov al,es:[ebx].mr_msr
    test al,10h
    jz mem_trans_end

mem_trans_send:
    dec cx
    mov ds:send_count,cx
    mov si,ds:send_head                 ; get head pointer
    mov al,fs:[si]                      ; get char
    mov es:[ebx],al                     ; transmitt char
    inc si
    cmp si,ds:send_size
    jnz mem_trans_not_wrap

    xor si,si
    
mem_trans_not_wrap:
    mov ds:send_head,si
    ReleaseSpinlock ds:com_spinlock

mem_trans_exit:
    pop fs
    ret
mem_trans    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           MemIntBase
;
;       DESCRIPTION:    Mem interrupt base code
;
;       PARAMETERS:     DS      Device sel
;
;       RETURNS:        CY      Handled something
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_serial_tab:
mst_mod  DW OFFSET mem_modem
mst_tx   DW OFFSET mem_trans
mst_rx   DW OFFSET mem_rec
mst_li   DW OFFSET mem_line_err

MemIntBase Proc near
    mov ebx,ds:mempds_offset
    mov es,ds:mempds_sel
;
    mov ax,ds:mempds_handle
    or ax,ax
    jz mem_com_int_inactive
;
    mov ds,ax
    mov al,es:[ebx].mr_isr_fcr
    test al,1
    jnz mem_com_int_ok

mem_com_int_loop:
    movzx si,al
    and si,6
    call word ptr cs:[si].mem_serial_tab
;    
    mov al,es:[ebx].mr_isr_fcr
    test al,1
    jnz mem_com_int_done
    jmp mem_com_int_loop

mem_com_int_inactive:
    mov al,es:[ebx].mr_isr_fcr
    test al,1
    jnz mem_com_int_ok
;   
    mov al,es:[ebx].mr_msr
    mov ds:mempds_line,al
;   
    mov al,es:[ebx].mr_lsr
    mov al,es:[ebx]
;   
    mov al,IER_BITS + 1
    mov es:[ebx].mr_ier,al
;   
    mov bx,ds:mempds_line_thread
    or bx,bx
    jz mem_com_int_done
;
    Signal

mem_com_int_done:   
    stc
    jmp mem_com_int_end

mem_com_int_ok:
    clc
    
mem_com_int_end:    
    ret
MemIntBase Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       mem_msi_int
;
;       DESCRIPTION:    MSI int, mem version
;
;       PARAMETERS:     DS      Com device
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_msi_int Proc far
    call MemIntBase
    retf32
mem_msi_int Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       mem_shared_int
;
;       DESCRIPTION:    Shared IRQ, mem version
;
;       PARAMETERS:     DS      Shared mem struc
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_shared_int Proc far

msRetry:
    mov cx,ds:ms_count
    mov bx,OFFSET ms_com_dev_arr

msIdleLoop:
    push ds
    push bx
    push cx
    mov ds,ds:[bx]
    call MemIntBase
    pop cx
    pop bx
    pop ds
    jc msBusyLoop
;
    add bx,2
    loop msIdleLoop
    jmp msDone

msBusyLoop:
    push ds
    push bx
    push cx
    mov ds,ds:[bx]
    call MemIntBase
    pop cx
    pop bx
    pop ds
    add bx,2
    loop msBusyLoop
;
    NotifyIrqActivity
    jmp msRetry

msDone:
    retf32
mem_shared_int Endp


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
    mov al,es:iopds_flags
    mov ds:iopps_flgs,al
    mov al,es:iopds_id
    mov ds:iopps_id,al
    ReleaseSpinlock ds:com_spinlock
;
    test ds:iopps_flgs, FLG_FINTEK
    jz io_open_norm
;
    mov al,87h
    out 2Eh,al
    out 2Eh,al
;
    mov al,7
    out 2Eh,al
    mov al,ds:iopps_id
    out 2Fh,al
;
    mov al,0F0h
    out 2Eh,al
    xor al,al
    out 2Fh,al
;
    mov al,0AAh
    out 2Eh,al

io_open_norm:
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
    mov ax,25
    WaitMilliSec    
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
    test ds:iopps_flgs, FLG_FINTEK
    jz io_enable_auto_norm

io_enable_auto_fintek:
    mov al,87h
    out 2Eh,al
    out 2Eh,al
;
    mov al,7
    out 2Eh,al
    mov al,ds:iopps_id
    out 2Fh,al
;
    mov al,0F0h
    out 2Eh,al
    mov al,30h
    out 2Fh,al
;
    mov al,0AAh
    out 2Eh,al
    jmp io_enable_auto_done

io_enable_auto_norm:
    mov dx,ds:iopps_base
    add dx,4
    in al,dx
    and al,NOT 2
    out dx,al

io_enable_auto_done:
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
    push bx
    push dx
;
    and ds:iopps_flgs,NOT FLG_ENABLE_AUTO_RTS
    test ds:iopps_flgs, FLG_FINTEK
    jz io_disable_auto_norm

io_disable_auto_fintek:
    mov al,87h
    out 2Eh,al
    out 2Eh,al
;
    mov al,7
    out 2Eh,al
    mov al,ds:iopps_id
    out 2Fh,al
;
    mov al,0F0h
    out 2Eh,al
    xor al,al
    out 2Fh,al
;
    mov al,0AAh
    out 2Eh,al
    jmp io_disable_auto_done

io_disable_auto_norm:
    mov dx,ds:iopps_base
    add dx,4
    in al,dx
    or al,2
    out dx,al

io_disable_auto_done:   
    pop dx
    pop bx
    pop ax
    retf32
io_disable_auto_rts Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           IoIsAutoRtsOn
;
;       DESCRIPTION:    Check for automatic RTS on send, IO version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_is_auto_rts_on PROC far
    test ds:iopps_flgs,FLG_ENABLE_AUTO_RTS
    jz iiarOff

iiarOn:
    clc
    retf32

iiarOff:
    stc
    retf32
io_is_auto_rts_on Endp
    
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
    test ds:iopps_flgs, FLG_FINTEK
    jnz io_com_send_timer_stopped
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
    test ds:iopps_flgs, FLG_FINTEK
    jnz io_com_send_start
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
;       NAME:           IoSendBreak
;
;       DESCRIPTION:    Send break, IO version
;
;       PARAMETERS:     DS      Port selector
;                       AL      Break characters
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_send_break   PROC far
    retf32
io_send_break  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_open_com
;
;       description:    Open a serial port, mem version
;
;       PARAMETERS:     DS      Port selector
;                       ES      Device selector
;                       AH      # of data bits
;                       BL      # of stop bits
;                       BH      parity
;                       ECX     baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_open_com    Proc far
    push es
    push ax
    push ebx
    push dx
    push si
;
    push ax
    RequestSpinlock ds:com_spinlock
    mov es:mempds_handle,ds
    mov ds:mempps_dev_handle,es
    mov ds:mempps_flgs,0
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
    je mem_open_even
;   
    cmp bh,'O'
    je mem_open_odd
;   
    jmp mem_open_parity_done

mem_open_even:
    inc dl
    or al,18h
    jmp mem_open_parity_done

mem_open_odd:
    inc dl
    or al,8

mem_open_parity_done:
    push eax
    push ebx
;
    push dx    
    mov eax,ds:mempps_baud_base
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
    mov ds:mempps_char_time,eax
;
    pop edx
    pop eax
;
    mov ebx,ds:mempps_offset
    mov es,ds:mempps_sel
;
    push ax
    or al,80h
    mov es:[ebx].mr_lcr,al      ; set line control to divisor access
;
    mov ax,si
    mov es:[ebx],ax             ; output LSB divisor latch
;
    mov al,1
    mov es:[ebx].mr_isr_fcr,al  ; enable FIFOs if present
;
    pop ax
    mov es:[ebx].mr_lcr,al      ; set line control
;
    mov al,IER_BITS + 1
    mov es:[ebx].mr_ier,al      ; enable rx ints and delta ints, disable tx, line ints
;
    mov al,es:[ebx].mr_mcr
    or al,0Ah
    mov ah,ds:line_reserved
    or ah,ah
    jnz mem_open_set_dtr
;
    or al,1

mem_open_set_dtr:
    mov es:[ebx].mr_mcr,al      ; modem control, DTR = high, RTS = high
;
    mov al,es:[ebx]
    mov al,es:[ebx].mr_lsr
    mov al,es:[ebx].mr_msr
;
    pop si
    pop dx
    pop ebx
    pop ax  
    pop es
    retf32
mem_open_com    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_close_com
;
;       description:    Close serial port, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_close_com   Proc far
    push es
    push ax
    push ebx
;
    mov ebx,ds:mempps_offset
    mov es,ds:mempps_sel
;
    xor al,al
    mov ah,ds:line_reserved
    or ah,ah
    jz mem_close_com_not_reserved
;   
    or al,IER_BITS

mem_close_com_not_reserved:
    mov es:[ebx].mr_ier,al          ; disable rx, tx, line and modem ints
;   
    mov es,ds:mempps_dev_handle
    mov es:mempds_handle,0
;
    mov ax,25
    WaitMilliSec    
;
    pop ebx
    pop ax
    pop es
    retf32
mem_close_com   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           MemEnableCts
;
;       DESCRIPTION:    Enable CTS signal, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_enable_cts  PROC far
    cmp ds:line_reserved,0
    jne mem_enable_cts_done
;    
    or ds:mempps_flgs,FLG_ENABLE_CTS

mem_enable_cts_done:
    retf32
mem_enable_cts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           MemDisableCts
;
;       DESCRIPTION:    Disable CTS signal, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_disable_cts PROC far
    and ds:mempps_flgs,NOT FLG_ENABLE_CTS
    retf32
mem_disable_cts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           MemEnableAutoRts
;
;       DESCRIPTION:    Enable automatic RTS on send, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_enable_auto_rts PROC far
    push es
    push ax
    push ebx
;
    or ds:mempps_flgs,FLG_ENABLE_AUTO_RTS
    mov ebx,ds:mempps_offset
    mov es,ds:mempps_sel
    mov al,es:[ebx].mr_mcr
    and al,NOT 2
    mov es:[ebx].mr_mcr,al
;   
    pop ebx
    pop ax
    pop es
    retf32
mem_enable_auto_rts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           MemDisableAutoRts
;
;       DESCRIPTION:    Disable automatic RTS on send, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_disable_auto_rts    PROC far
    push es
    push ax
    push ebx
;    
    and ds:mempps_flgs,NOT FLG_ENABLE_AUTO_RTS
    mov ebx,ds:mempps_offset
    mov es,ds:mempps_sel
    mov al,es:[ebx].mr_mcr
    or al,2
    mov es:[ebx].mr_mcr,al
;   
    pop ebx
    pop ax
    pop es
    retf32
mem_disable_auto_rts Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           MemIsAutoRtsOn
;
;       DESCRIPTION:    Check for automatic RTS on send, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_is_auto_rts_on PROC far
    test ds:mempps_flgs,FLG_ENABLE_AUTO_RTS
    jz miarOff

miarOn:
    clc
    retf32

miarOff:
    stc
    retf32
mem_is_auto_rts_on Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           MemFlushCom
;
;       DESCRIPTION:    Flush com, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_flush_com   PROC far
    push es
    push ax
    push ebx
;
    mov ebx,ds:mempps_offset
    mov es,ds:mempps_sel
;
    RequestSpinlock ds:com_spinlock
    mov al,IER_BITS + 1
    mov es:[ebx].mr_ier,al
    ReleaseSpinlock ds:com_spinlock
;   
    pop ebx
    pop ax
    pop es
    retf32
mem_flush_com Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           MemResetPort
;
;       DESCRIPTION:    Reset com, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_reset_port   PROC far
    retf32
mem_reset_port  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:           MemSendBreak
;
;       DESCRIPTION:    Send break, mem version
;
;       PARAMETERS:     DS      Port selector
;                       AL      Break characters
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_send_break   PROC far
    retf32
mem_send_break  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_start_send
;
;       description:    Start send, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_start_send  PROC far
    push es
    push ax
    push ebx
;
    test ds:mempps_flgs, FLG_ENABLE_AUTO_RTS
    jz mem_com_send_timer_stopped
;
    mov bx,ds
    StopTimer

mem_com_send_timer_stopped:
    mov ebx,ds:mempps_offset
    mov es,ds:mempps_sel
;
    RequestSpinlock ds:com_spinlock
    test ds:mempps_flgs, FLG_ENABLE_CTS
    jz mem_com_send_enable
;
    mov al,es:[ebx].mr_msr
    test al,10h
    jz mem_com_send_ok

mem_com_send_enable:
    test ds:mempps_flgs, FLG_ENABLE_AUTO_RTS
    jz mem_com_send_start
;   
    mov al,es:[ebx].mr_mcr
    or al,2
    mov es:[ebx].mr_mcr,al

mem_com_send_start:
    mov al,IER_BITS + 3
    mov es:[ebx].mr_ier,al
    
mem_com_send_ok:
    ReleaseSpinlock ds:com_spinlock
    pop ebx
    pop ax
    pop es
    retf32
mem_start_send  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_set_dtr
;
;       description:    Set DTR signal, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_set_dtr Proc far
    push es
    push ax
    push ebx
;
    mov ebx,ds:mempps_offset
    mov es,ds:mempps_sel
    mov al,es:[ebx].mr_mcr
    or al,1
    mov es:[ebx].mr_mcr,al
;
    pop ebx
    pop ax
    pop es
    retf32
mem_set_dtr Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_reset_dtr
;
;       description:    Reset DTR signal, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_reset_dtr   Proc far
    push es
    push ax
    push ebx
;
    mov ebx,ds:mempps_offset
    mov es,ds:mempps_sel
    mov al,es:[ebx].mr_mcr
    and al,NOT 1
    mov es:[ebx].mr_mcr,al
;
    pop ebx
    pop ax
    pop es
    retf32
mem_reset_dtr   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_set_rts
;
;       description:    Set RTS signal, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_set_rts Proc far
    push es
    push ax
    push ebx
;
    mov ebx,ds:mempps_offset
    mov es,ds:mempps_sel
    mov al,es:[ebx].mr_mcr
    or al,2
    mov es:[ebx].mr_mcr,al
;
    pop ebx
    pop ax
    pop es
    retf32
mem_set_rts Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_reset_rts
;
;       description:    Reset RTS signal, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_reset_rts   Proc far
    push es
    push ax
    push ebx
;
    mov ebx,ds:mempps_offset
    mov es,ds:mempps_sel
    mov al,es:[ebx].mr_mcr
    and al,NOT 2
    mov es:[ebx].mr_mcr,al
;
    pop ebx
    pop ax
    pop es
    retf32
mem_reset_rts   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           mem_reset_com
;
;       description:    Reset com, mem version
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_reset_com   Proc far
    retf32
mem_reset_com   Endp


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
ipt13 DD OFFSET full_duplex,        SEG code
ipt14 DD OFFSET io_is_auto_rts_on,  SEG code
ipt15 DD OFFSET io_send_break,      SEG code

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
    mov cx,2 * 16
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
mpt00 DD OFFSET mem_open_com,        SEG code
mpt01 DD OFFSET mem_close_com,       SEG code
mpt02 DD OFFSET mem_enable_cts,      SEG code
mpt03 DD OFFSET mem_disable_cts,     SEG code
mpt04 DD OFFSET mem_set_dtr,         SEG code
mpt05 DD OFFSET mem_reset_dtr,       SEG code
mpt06 DD OFFSET mem_set_rts,         SEG code
mpt07 DD OFFSET mem_reset_rts,       SEG code
mpt08 DD OFFSET mem_enable_auto_rts, SEG code
mpt09 DD OFFSET mem_disable_auto_rts,SEG code
mpt10 DD OFFSET mem_flush_com,       SEG code
mpt11 DD OFFSET mem_start_send,      SEG code
mpt12 DD OFFSET mem_reset_port,      SEG code
mpt13 DD OFFSET full_duplex,         SEG code
mpt14 DD OFFSET mem_is_auto_rts_on,  SEG code
mpt15 DD OFFSET mem_send_break,      SEG code

mem_create_port Proc far
    push eax
    push cx
    push si
    push di
;
    mov eax,SIZE mem_com_port_struc
    AllocateSmallGlobalMem
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov si,OFFSET mem_port_tab
    xor di,di
    mov cx,2 * 16
    rep movs dword ptr es:[di],cs:[si]
;
    mov eax,ds:mempds_offset
    mov es:mempps_offset,eax
    mov ax,ds:mempds_sel
    mov es:mempps_sel,ax
    mov eax,ds:mempds_baud_base
    mov es:mempps_baud_base,eax
;    
    pop di
    pop si
    pop cx
    pop eax
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

DetectIrqOnce   Proc near
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
    jz dioDone
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
    jz dioDone
;
    xor cx,cx
    mov ebx,1

dioGetNrLoop:
    test eax,ebx
    jnz dioGetNrDone
;
    shl ebx,1
    inc cx
    jmp dioGetNrLoop

dioGetNrDone:
    not ebx
    and eax,ebx
    stc
    jnz dioDone
;
    mov ax,cx
    clc    

dioDone:
    pop ebp
    pop cx
    pop ebx
    ret
DetectIrqOnce   Endp

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
    push bx
    push cx
    mov cx,3

diCheckLoop:
    call DetectIrqOnce
    jnc diOk
;    
    loop diCheckLoop
    stc
    jmp diDone

diOk:    
    mov bl,al
    mov cx,3

diVerLoop:
    call DetectIrqOnce
    jnc diVer
;    
    loop diVerLoop
    stc
    jmp diDone

diVer:
    cmp al,bl
    clc
    je diDone
;
    stc        

diDone:
    pop cx    
    pop bx
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
;                       AL      IRQ
;                       AH      flags
;                       BL      index
;                       ECX     Baud base
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
    mov es:iopds_flags,ah
    mov es:iopds_id,bl
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
    mov ds:iopds_port_nr,ax
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
;       NAME:           AddMsiMemPort
;
;       DESCRIPTION:    Add MSI mem port to list of available ports
;
;       PARAMETERS:     DS:EBX  Base
;                       AL      IRQ
;                       ECX     Baud base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddMsiMemPort Proc near
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
    mov edi,OFFSET mem_msi_int
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
AddMsiMemPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddIrqMemPort
;
;       DESCRIPTION:    Add IRQ mem port to list of available ports
;
;       PARAMETERS:     DS:EBX  Base
;                       AL      IRQ
;                       ECX     Baud base
;                       FS      Share mem sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIrqMemPort Proc near
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
    mov bx,fs:ms_count
    add bx,bx
    mov fs:[bx].ms_com_dev_arr,es
    inc fs:ms_count
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
AddIrqMemPort Endp

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
    xor ah,ah
    mov ecx,921600
    call AddIoPort
;
    xor ah,ah
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
    mov al,13h
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
    mov edx,ds:oxb_uart_count
    or edx,edx
    jz mem_init_pci_done        
;       
    mov al,dl
    GetPciMsiX
    jc mem_init_irq
;
    cmp dl,al
    jb mem_init_irq
;    
    EnablePciMsiX
;
    xor edx,edx

mem_msi_setup:
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc mem_init_pci_done
;    
    SetupPciMsiXEntry
;
    push ebx
    push ecx
;
    mov ebx,edx
    shl ebx,9
    add ebx,1000h        
    mov ecx,3906250
    call AddMsiMemPort
    pop ecx
    pop ebx
;
    inc edx
    cmp edx,ds:oxb_uart_count
    jne mem_msi_setup
    jmp mem_init_enable_irq

mem_init_irq: 
    GetPciIrqNr
    jc mem_init_pci_done
;
    push eax
    mov eax,SIZE mem_share_struc
    AllocateSmallGlobalMem
    pop eax
;    
    push ds
    mov bx,es
    mov ds,bx    
    mov fs,bx
    mov bx,cs
    mov es,bx
    mov ah,14h
    mov edi,OFFSET mem_shared_int
    RequestIrqHandler
    pop ds
;  
    mov fs:ms_count,0
    xor edx,edx

mem_irq_setup:
    push ebx
    push ecx
;
    mov ebx,edx
    shl ebx,9
    add ebx,1000h        
    mov ecx,3906250
    call AddIrqMemPort
    pop ecx
    pop ebx
;
    inc edx
    cmp edx,ds:oxb_uart_count
    jne mem_irq_setup

mem_init_enable_irq:
    xor eax,eax
    mov edx,ds:oxb_uart_count

mem_init_mask_loop:    
    stc
    rcl eax,1
    sub edx,1
    jnz mem_init_mask_loop
;
    mov ds:oxb_irq_enable,eax
    clc

mem_init_pci_done:
    ret
InitMemPci  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FintekStealFdc
;
;       DESCRIPTION:    Steal FDC IRQ
;
;       RETURNS:        NC              Stolen
;                           CL          IRQ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FintekStealFdc      Proc near
    mov al,7
    out 2Eh,al
    xor al,al
    out 2Fh,al
;
    mov al,70h
    out 2Eh,al
    in al,2Fh
    or al,al
    jz fsfFail
;
    mov cl,al
    mov al,30h
    out 2Eh,al
    in al,2Fh
    test al,1
    jnz fsfFail
;
    clc
    jmp fsfDone

fsfFail:
    stc

fsfDone:
    ret
FintekStealFdc      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FintekStealKbd
;
;       DESCRIPTION:    Steal KBD IRQ
;
;       RETURNS:        NC              Stolen
;                           CL          IRQ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FintekStealKbd      Proc near
    mov al,7
    out 2Eh,al
    mov al,5
    out 2Fh,al
;
    mov al,70h
    out 2Eh,al
    in al,2Fh
    or al,al
    jz fskFail
;
    mov cl,al
    mov al,30h
    out 2Eh,al
    in al,2Fh
    test al,1
    jnz fskFail
;
    clc
    jmp fskDone

fskFail:
    stc

fskDone:
    ret
FintekStealKbd      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FintekStealEpc
;
;       DESCRIPTION:    Steal EPC IRQ
;
;       RETURNS:        NC              Stolen
;                           CL          IRQ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FintekStealEpc      Proc near
    mov al,7
    out 2Eh,al
    mov al,3
    out 2Fh,al
;
    mov al,70h
    out 2Eh,al
    in al,2Fh
    or al,al
    jz fseFail
;
    mov cl,al
    mov al,30h
    out 2Eh,al
    in al,2Fh
    test al,1
    jnz fseOk
;
    mov al,30
    out 2Eh,al
    xor al,al
    out 2Fh,al

fseOk:
    clc
    jmp fsfDone

fseFail:
    stc

fseDone:
    ret
FintekStealEpc      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupFintekPort866
;
;       DESCRIPTION:    Setup Fintek port
;
;       PARAMETERS:     BL      Index (10h..15h)
;                       SI      Used IRQs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupFintekPort866      Proc near
    mov al,7
    out 2Eh,al
    mov al,bl
    out 2Fh,al
;
    mov al,60h
    out 2Eh,al
    in al,2Fh
    mov dh,al
;
    mov al,61h
    out 2Eh,al
    in al,2Fh
    mov dl,al
;    
    mov al,30h
    out 2Eh,al
    in al,2Fh
    test al,1
    jz sfpFail866
;
    mov al,70h
    out 2Eh,al
    in al,2Fh
    mov cl,al
    mov ax,1
    shl ax,cl
    test ax,si
    jz sfpAdd866
;
    call FintekStealFdc
    jc sfpEpc866
;
    mov ax,1
    shl ax,cl
    test ax,si
    jz sfpAdd866

sfpEpc866:
    call FintekStealEpc
    jc sfpFail866
;
    mov ax,1
    shl ax,cl
    test ax,si
    jnz sfpFail866

sfpAdd866:
    push bx
    push cx
    or si,ax
    mov al,cl
    mov ah,FLG_FINTEK
    mov ecx,115200   
    call AddIoPort
    call InitDetect
    pop cx
    pop bx
;
    mov al,7
    out 2Eh,al
    mov al,bl
    out 2Fh,al
;
    mov al,70h
    out 2Eh,al
    mov al,cl
    out 2Fh,al
;
    mov al,0F0h
    out 2Eh,al
    xor al,al
    out 2Fh,al
;
    mov al,0F2h
    out 2Eh,al
    xor al,al
    out 2Fh,al
;
    mov al,0F4h
    out 2Eh,al
    xor al,al
    out 2Fh,al
;
    mov al,0F5h
    out 2Eh,al
    xor al,al
    out 2Fh,al
    clc
    jmp sfpDone866

sfpFail866:
    stc

sfpDone866:    
    ret
SetupFintekPort866      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupFintek866
;
;       DESCRIPTION:    Setup Fintek controller
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupFintek866      Proc near
    xor si,si
;    
    mov bl,10h
    call SetupFintekPort866
;    
    mov bl,11h
    call SetupFintekPort866
;    
    mov bl,12h
    call SetupFintekPort866
;    
    mov bl,13h
    call SetupFintekPort866
;    
    mov bl,14h
    call SetupFintekPort866
;    
    mov bl,15h
    call SetupFintekPort866
;
    mov al,0AAh
    out 2Eh,al
    ret
SetupFintek866     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupFintekPort966
;
;       DESCRIPTION:    Setup Fintek port
;
;       PARAMETERS:     BL      Index (10h..15h)
;                       SI      Used IRQs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupFintekPort966      Proc near
    mov al,7
    out 2Eh,al
    mov al,bl
    out 2Fh,al
;
    mov al,60h
    out 2Eh,al
    in al,2Fh
    mov dh,al
;
    mov al,61h
    out 2Eh,al
    in al,2Fh
    mov dl,al
;    
    mov al,30h
    out 2Eh,al
    in al,2Fh
    test al,1
    jz sfpFail966
;
    mov al,70h
    out 2Eh,al
    in al,2Fh
    mov cl,al
    mov ax,1
    shl ax,cl
    test ax,si
    jz sfpAdd966
;
    mov ax,1
    shl ax,cl
    test ax,si
    jz sfpAdd966
;
    call FintekStealKbd
    jc sfpEpc966
;
    mov ax,1
    shl ax,cl
    test ax,si
    jz sfpAdd966

sfpEpc966:
    call FintekStealEpc
    jc sfpFail966
;
    mov ax,1
    shl ax,cl
    test ax,si
    jnz sfpFail966

sfpAdd966:
    push bx
    push cx
    or si,ax
    mov al,cl
    mov ah,FLG_FINTEK
    mov ecx,115200   
    call AddIoPort
    call InitDetect
    pop cx
    pop bx
;
    mov al,7
    out 2Eh,al
    mov al,bl
    out 2Fh,al
;
    mov al,70h
    out 2Eh,al
    mov al,cl
    out 2Fh,al
;
    mov al,0F0h
    out 2Eh,al
    xor al,al
    out 2Fh,al
;
    mov al,0F2h
    out 2Eh,al
    xor al,al
    out 2Fh,al
;
    mov al,0F4h
    out 2Eh,al
    xor al,al
    out 2Fh,al
;
    mov al,0F5h
    out 2Eh,al
    xor al,al
    out 2Fh,al
    clc
    jmp sfpDone966

sfpFail966:
    stc

sfpDone966:    
    ret
SetupFintekPort966      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupFintek966
;
;       DESCRIPTION:    Setup Fintek controller
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupFintek966      Proc near
    xor si,si
;    
    mov bl,10h
    call SetupFintekPort966
;    
    mov bl,11h
    call SetupFintekPort966
;    
    mov bl,12h
    call SetupFintekPort966
;    
    mov bl,13h
    call SetupFintekPort966
;    
    mov bl,14h
    call SetupFintekPort966
;    
    mov bl,15h
    call SetupFintekPort966
;
    mov al,0AAh
    out 2Eh,al
    ret
SetupFintek966     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupSio
;
;       DESCRIPTION:    Setup SIO
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupSio      Proc near
    mov al,87h
    out 2Eh,al
    out 2Eh,al
;
    mov al,23h
    out 2Eh,al
    in al,2Fh
    cmp al,19h
    jne ssFail
;
    mov al,24h
    out 2Eh,al
    in al,2Fh
    cmp al,34h
    jne ssFail
;
    mov al,20h
    out 2Eh,al
    in al,2Fh
    cmp al,10h
    jne ssTry966
;
    mov al,21h
    out 2Eh,al
    in al,2Fh
    cmp al,10h
    jne ssFail
;
    call SetupFintek866
    clc
    jmp ssDone

ssTry966:
    cmp al,15h
    jne ssFail
;
    mov al,21h
    out 2Eh,al
    in al,2Fh
    cmp al,2
    jne ssFail
;
    call SetupFintek966
    clc
    jmp ssDone

ssFail:
    stc

ssDone:
    ret
SetupSio        Endp    

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
    call InitMemPci
    jnc dtdone
;
    call SetupSio
    jnc dtpci
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
    xor ah,ah
    call AddIoPort    
    call InitDetect

dt1:
    mov dx,2F8h
    call DetectIrq
    jc dt2
;
    xor ah,ah
    mov ecx,115200
    call AddIoPort
    call InitDetect

dt2:   
    mov dx,3E8h
    call DetectIrq
    jc dt3
;    
    xor ah,ah
    mov ecx,115200
    call AddIoPort
    call InitDetect

dt3:   
    mov dx,2E8h
    call DetectIrq
    jc dt4
;    
    xor ah,ah
    mov ecx,115200
    call AddIoPort
    call InitDetect

dt4:   
    mov dx,2A0h
    call DetectIrq
    jc dt5
;    
    xor ah,ah
    mov ecx,115200
    call AddIoPort
    call InitDetect

dt5:   
    mov dx,2A8h
    call DetectIrq
    jc dtpci
;    
    xor ah,ah
    mov ecx,115200
    call AddIoPort
    call InitDetect

dtpci:
    call InitPciAdapter
    call RequestIRQs

    mov ax,25
    WaitMilliSec

dtdone:
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
;
    mov esi,OFFSET get_std_com_par
    mov edi,OFFSET get_std_com_par_name
    xor dx,dx
    mov ax,get_std_com_par_nr
    RegisterBimodalUserGate
;
    mov edi,OFFSET init_pci
    HookInitPci
    clc
    ret
init    Endp

code    ENDS

    END init
