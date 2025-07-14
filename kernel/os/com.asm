;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; COM.ASM
; Serial communication base class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include system.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\handle.inc
include ..\wait.inc
include com.inc

MAX_PORTS = 128

serial_wait_header      STRUC

sw_obj          wait_obj_header <>
sw_handle           DW ?

serial_wait_header      ENDS


serial_handle_seg           STRUC

serial_handle_base      handle_header <>

port_sel        DW ?

serial_handle_seg           ENDS

data    SEGMENT byte public 'DATA'

s_port_count    DW ?
s_port_arr      DW MAX_PORTS DUP(?)

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
;           NAME:           Delete_handle
;
;           DESCRIPTION:    Delete handle (called from handle module)
;
;           PARAMETERS:         BX              COM HANDLE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push es
    push ax
    push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc delete_handle_done
;
    push [ebx].port_sel
    FreeHandle
    pop ds
;
    call fword ptr ds:close_com_proc
;
    mov es,ds:send_buf
    FreeMem
    mov es,ds:rec_buf
    FreeMem
;
    mov ax,ds
    xor bx,bx
    mov ds,bx
    mov es,ax
    FreeMem
;
    mov ax,500
    WaitMilliSec

delete_handle_done:
    pop dx
    pop ax
    pop es
    pop ds
    retf32
delete_handle   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_max_com_port
;
;           description:    Get max usable com port #
;
;           RETURNS:    AL      Max port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_max_com_port_name DB 'Get Max Com Port',0

get_max_com_port    Proc far
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:s_port_count
    clc
    pop ds
    retf32
get_max_com_port    Endp    
    
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsComAvailable
;
;           description:    Check if port is available
;
;           PARAMETERS:     AL              Port #
;
;           RETURNS:        NC              Available
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_com_available_name DB 'Is Com Available',0

is_com_available    Proc far
    push ds
    push bx
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    cmp bx,ds:s_port_count
    jae is_com_avail_fail
;    
    add bx,bx
    mov ds,ds:[bx].s_port_arr
    mov al,ds:cd_open
    or al,al
    jnz is_com_avail_fail
;
    clc
    jmp is_com_avail_done

is_com_avail_fail:
    stc

is_com_avail_done:
    pop bx
    pop ds
    retf32
is_com_available Endp            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           open_com
;
;           description:    Open a serial port
;
;           PARAMETERS:         AL                  Port #
;                           AH                  # of data bits
;                           BL                  # of stop bits
;                           BH                  parity
;                           ECX                 baudrate
;                           SI                  size of transmit buffer
;                           DI                  size of receive buffer
;
;           RETURNS:        BX          port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com_name DB 'Open Com',0

open_com    Proc far
    push ds
    push es
    push dx
    push bp
;
    mov dx,SEG data
    mov ds,dx
    movzx dx,al
    cmp dx,ds:s_port_count
    jae open_com_fail
;    
    push ax
    push bx
    push ecx
;    
    mov bx,dx
    add bx,bx
    mov ds,ds:[bx].s_port_arr
    mov al,ds:cd_open
    or al,al
    jnz open_com_pop_fail
;
    inc ds:cd_open
    push ds
    call fword ptr ds:cd_create_proc
;
    mov ax,SERIAL_HANDLE
    mov cx,SIZE serial_handle_seg
    AllocateHandle
    mov [ebx].port_sel,es
    mov [ebx].hh_sign,SERIAL_HANDLE
    mov bp,[ebx].hh_handle
;
    mov ax,es
    mov ds,ax
;
    movzx eax,si
    mov ds:send_size,ax
    AllocateSmallGlobalMem
    mov ds:send_buf,es
    mov ds:send_count,0
    mov ds:send_head,0
    mov ds:send_tail,0
;
    movzx eax,di
    mov ds:rec_size,ax
    AllocateSmallGlobalMem
    mov ds:rec_buf,es
    mov ds:rec_count,0
    mov ds:rec_head,0
    mov ds:rec_tail,0
;       
    mov ds:avail_obj,0
    mov ds:send_wait,0      
;
    pop es
    mov al,es:cd_line_reserved
    mov ds:line_reserved,al
    InitSpinlock ds:com_spinlock
;
    pop ecx
    pop bx
    pop ax
;    
    mov ds:com_device,es
    call fword ptr ds:open_com_proc
;
    mov bx,bp
    clc
    jmp open_com_done

open_com_pop_fail:
    pop ecx
    pop bx
    pop ax
    
open_com_fail:
    xor bx,bx
    stc

open_com_done:
    pop bp
    pop dx
    pop es
    pop ds
    retf32 
open_com    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           close_com
;
;           description:    Close serial port
;
;           PARAMETERS:         BX          port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com_name DB 'Close Com',0

close_com       Proc far
    push ds
    push es
    push ax
    push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc close_com_done
;
    push [ebx].port_sel
    FreeHandle
    pop ds
;
    call fword ptr ds:close_com_proc
;
    mov es,ds:send_buf
    FreeMem
    mov es,ds:rec_buf
    FreeMem
;
    mov es,ds:com_device
    dec es:cd_open      
;
    mov ax,ds
    xor bx,bx
    mov ds,bx
    mov es,ax
    FreeMem
;
    mov ax,100
    WaitMilliSec

close_com_done:
    pop dx
    pop ax
    pop es
    pop ds
    retf32
close_com       Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           EnableCts
;
;           DESCRIPTION:    Enable CTS signal
;
;           PARAMETERS:         BX      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_cts_name DB 'Enable CTS',0

enable_cts      PROC far
    push ds
    push ax
    push ebx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc enable_cts_done
;
    mov ds,[ebx].port_sel
    call fword ptr ds:enable_cts_proc

enable_cts_done:
    pop ebx
    pop ax
    pop ds
    retf32
enable_cts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DisableCts
;
;           DESCRIPTION:    Disable CTS signal
;
;           PARAMETERS:         BX      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_cts_name DB 'Disable CTS',0

disable_cts     PROC far
    push ds
    push ax
    push ebx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc disable_cts_done
;
    mov ds,[ebx].port_sel
    call fword ptr ds:disable_cts_proc

disable_cts_done:
    pop ebx
    pop ax
    pop ds
    retf32
disable_cts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           EnableAutoRts
;
;           DESCRIPTION:    Enable automatic RTS on send
;
;           PARAMETERS:         BX      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_auto_rts_name DB 'Enable Auto RTS',0

enable_auto_rts PROC far
    push ds
    push ax
    push ebx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc enable_auto_rts_done
;
    mov ds,[ebx].port_sel
    call fword ptr ds:enable_auto_rts_proc

enable_auto_rts_done:
    pop ebx
    pop ax
    pop ds
    retf32
enable_auto_rts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DisableAutoRts
;
;           DESCRIPTION:    Disable automatic RTS on send
;
;           PARAMETERS:         BX      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_auto_rts_name DB 'Disable Auto RTS',0

disable_auto_rts    PROC far
    push ds
    push ax
    push ebx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc disable_auto_rts_done
;
    mov ds,[ebx].port_sel
    call fword ptr ds:disable_auto_rts_proc

disable_auto_rts_done:
    pop ebx
    pop ax
    pop ds
    retf32
disable_auto_rts Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           is_auto_rts_on
;
;           description:    Check if auto RTS is on
;
;           PARAMETERS:     BX          Port handle
;
;           RETURNS:        CY		Auto RTS off
;                           NC          Auto RTS on
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_auto_rts_on_name DB 'Is Auto RTS On',0

is_auto_rts_on      PROC far
    push ds
    push ebx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc iaroDone
;
    mov ds,[ebx].port_sel
    call fword ptr ds:is_auto_rts_on_proc

iaroDone:
    pop ebx
    pop ds
    retf32
is_auto_rts_on      ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FlushCom
;
;           DESCRIPTION:    Flush com
;
;           PARAMETERS:         BX      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_com_name DB 'Flush Com',0

flush_com       PROC far
    push ds
    push ax
    push ebx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc flush_com_done
;
    mov ds,[ebx].port_sel
    call fword ptr ds:flush_com_proc
;       
    RequestSpinlock ds:com_spinlock
    mov ds:send_count,0
    mov ds:send_head,0
    mov ds:send_tail,0
    mov ds:rec_count,0
    mov ds:rec_head,0
    mov ds:rec_tail,0
    ReleaseSpinlock ds:com_spinlock

flush_com_done:
    pop ebx
    pop ax
    pop ds
    retf32
flush_com Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetComRecCount
;
;           DESCRIPTION:    Get bytes in receive buffer
;
;           PARAMETERS:     BX      Com handle
;
;           RETURNS:        EAX     Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_com_rec_count_name DB 'Get Com Received Count',0

get_com_rec_count       PROC far
    push ds
    push ebx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc get_com_rec_done
;
    mov ds,[ebx].port_sel
    movzx eax,ds:rec_count
    clc

get_com_rec_done:
    pop ebx
    pop ds
    retf32
get_com_rec_count Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResetCom
;
;           DESCRIPTION:    Reset com
;
;           PARAMETERS:     BX      Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_com_name DB 'Reset Com',0

reset_com       PROC far
    push ds
    push ax
    push ebx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc reset_com_done
;
    mov ds,[ebx].port_sel
    call fword ptr ds:reset_com_proc

reset_com_done:
    pop ebx
    pop ax
    pop ds
    retf32
reset_com Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           read_com
;
;           description:    Read a byte from port
;
;           PARAMETERS:         BX              Port handle
;
;           RETURNS:        AL              Received byte
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_com_name DB 'Read Com',0

read_com    PROC far
    push ds
    push es
    push ebx
    push cx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc com_read_done
;
    mov ds,[ebx].port_sel
    mov es,ds:rec_buf
;
    RequestSpinlock ds:com_spinlock
    mov cx,ds:rec_count
    or cx,cx
    jz com_read_no_char
    mov bx,ds:rec_head
    mov al,es:[bx]          ; get char from buffer
    dec cx
    mov ds:rec_count,cx
    inc bx
    cmp bx,ds:rec_size
    jnz com_read_nix_wrap
    xor bx,bx
com_read_nix_wrap:
    mov ds:rec_head,bx
    ReleaseSpinlock ds:com_spinlock
    xor ah,ah
    clc
    jmp com_read_done
com_read_no_char:
    ReleaseSpinlock ds:com_spinlock
    stc
    mov ax,-1
com_read_done:
    pop cx
    pop ebx
    pop es
    pop ds
    retf32
read_com    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_com_receive_space
;
;           description:    Get space in receive buffer
;
;           PARAMETERS:         BX              Port handle
;
;           RETURNS:        EAX     Free space
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_com_receive_space_name DB 'Get Com Receive Space',0

get_com_receive_space   PROC far
    push ds
    push ebx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc get_com_rec_space_done
;
    mov ds,[ebx].port_sel
    mov ax,ds:rec_size
    sub ax,ds:rec_count
    movzx eax,ax

get_com_rec_space_done:
    pop ebx
    pop ds
    retf32
get_com_receive_space   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           write_com
;
;           description:    Write byte to port
;
;           PARAMETERS:         BX              Port handle
;                           AL              Data
;
;           RETURNS:        0               OK
;                           -1              Buffer overflow
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_com_name DB 'Write Com',0

write_com       PROC far
    push ds
    push es
    push ebx
    push cx
    push dx
;
    push ax
    mov ax,SERIAL_HANDLE
    DerefHandle
    pop ax
    jc com_send_fail
;
    mov ds,[ebx].port_sel
    mov es,ds:send_buf
    RequestSpinlock ds:com_spinlock
    mov cx,ds:send_count
    cmp cx,ds:send_size
    je com_send_full
;       
    mov bx,ds:send_tail
    mov es:[bx],al
    inc bx
    cmp bx,ds:send_size
    jnz com_send_no_wrap
    xor bx,bx
com_send_no_wrap:
    mov ds:send_tail,bx
    or cx,cx
    jnz com_send_ok
;
    inc cx
    mov ds:send_count,cx
    ReleaseSpinlock ds:com_spinlock
    call fword ptr ds:start_send_com_proc
    jmp com_send_ok_done
    
com_send_ok:
    inc cx
    mov ds:send_count,cx
    ReleaseSpinlock ds:com_spinlock
    
com_send_ok_done:
    xor ax,ax
    jmp com_send_end
    
com_send_full:
    ReleaseSpinlock ds:com_spinlock

com_send_fail:
    mov ax,-1

com_send_end:
    pop dx
    pop cx
    pop ebx
    pop es
    pop ds
    retf32
write_com       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           wait_for_send_completed_com
;
;           description:    Wait until send buffer is empty
;
;           PARAMETERS:         BX              Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_send_completed_com_name DB 'Wait For Send Completed Com',0

wait_for_send_completed_com     PROC far
    push ds
    push ebx
    push cx
;
    push ax
    mov ax,SERIAL_HANDLE
    DerefHandle
    pop ax
    jc wait_for_send_completed_done
;
    mov ds,[bx].port_sel
    GetThread
    mov ds:send_wait,ax
;    
    ClearSignal

    mov cx,ds:send_count
    or cx,cx
    jz wait_for_send_completed_done
;
    WaitForSignal

wait_for_send_completed_done:
    pop cx
    pop ebx
    pop ds
    retf32
wait_for_send_completed_com     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_com_send_space
;
;           description:    Get space in send buffer
;
;           PARAMETERS:         BX              Port handle
;
;           RETURNS:        EAX     Free space
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_com_send_space_name DB 'Get Com Send Space',0

get_com_send_space      PROC far
    push ds
    push ebx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc get_com_send_space_done
;
    mov ds,[ebx].port_sel
    mov ax,ds:send_size
    sub ax,ds:send_count
    movzx eax,ax

get_com_send_space_done:
    pop ebx
    pop ds
    retf32
get_com_send_space      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           send_com_break
;
;           description:    Send com break
;
;           PARAMETERS:     BX              Port handle
;                           AL              Break characters
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_com_break_name DB 'Send Com Break',0

send_com_break      PROC far
    push ds
    push ebx
;
    push ax
    mov ax,SERIAL_HANDLE
    DerefHandle
    pop ax
    jc send_com_break_done
;
    mov ds,[ebx].port_sel
    call fword ptr ds:send_com_break_proc

send_com_break_done:
    pop ebx
    pop ds
    retf32
send_com_break      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           supports_full_duplex
;
;           description:    Check for support for full duplex
;
;           PARAMETERS:     BX          Port handle
;
;           RETURNS:        CY		Has full duplex
;                           NC          No full duplex support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

supports_full_duplex_name DB 'Supports Full Duplex',0

supports_full_duplex      PROC far
    push ds
    push ebx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    cmc
    jnc sfdDone
;
    mov ds,[ebx].port_sel
    call fword ptr ds:supports_full_duplex_proc

sfdDone:
    pop ebx
    pop ds
    retf32
supports_full_duplex      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_cts
;
;           description:    Get CTS signal
;
;           PARAMETERS:     BX          Port handle
;
;           RETURNS:        NC          ON
;                           CY          OFF
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cts_name DB 'Get CTS',0

get_cts Proc far
    push ds
    push ax
    push ebx
    push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc get_cts_done
;
    mov ds,[ebx].port_sel
    mov ds,ds:com_device
    mov ebx,ds:cd_get_line_state_proc
    or ebx,ds:cd_get_line_state_proc+4
    clc
    jz get_cts_done
;    
    call fword ptr ds:cd_get_line_state_proc
    rcr al,1
    cmc

get_cts_done:
    pop dx
    pop ebx
    pop ax
    pop ds
    retf32
get_cts Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_dsr
;
;           description:    Get DSR signal
;
;           PARAMETERS:     BX          Port handle
;
;           RETURNS:        NC          ON
;                           CY          OFF
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dsr_name DB 'Get DSR',0

get_dsr Proc far
    push ds
    push ax
    push ebx
    push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc get_dsr_done
;
    mov ds,[ebx].port_sel
    mov ds,ds:com_device
    mov ebx,ds:cd_get_line_state_proc
    or ebx,ds:cd_get_line_state_proc+4
    clc
    jz get_dsr_done
;
    call fword ptr ds:cd_get_line_state_proc
    rcr al,2
    cmc

get_dsr_done:
    pop dx
    pop ebx
    pop ax
    pop ds
    retf32
get_dsr Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_dtr
;
;           description:    Set DTR signal
;
;           PARAMETERS:         BX          Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dtr_name DB 'Set Dtr',0

set_dtr Proc far
    push ds
    push ax
    push ebx
    push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc set_dtr_done
;
    mov ds,[ebx].port_sel
    cmp ds:line_reserved,0
    jne set_dtr_done
;
    call fword ptr ds:set_dtr_proc

set_dtr_done:
    pop dx
    pop ebx
    pop ax
    pop ds
    retf32
set_dtr Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reset_dtr
;
;           description:    Reset DTR signal
;
;           PARAMETERS:         BX          Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_dtr_name DB 'Reset Dtr',0

reset_dtr       Proc far
    push ds
    push ax
    push ebx
    push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc reset_dtr_done
;
    mov ds,[ebx].port_sel
    cmp ds:line_reserved,0
    jne reset_dtr_done
;
    call fword ptr ds:reset_dtr_proc

reset_dtr_done:
    pop dx
    pop ebx
    pop ax
    pop ds
    retf32
reset_dtr       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_rts
;
;           description:    Set RTS signal
;
;           PARAMETERS:         BX          Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rts_name DB 'Set Rts',0

set_rts Proc far
    push ds
    push ax
    push ebx
    push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc set_rts_done
;
    mov ds,[ebx].port_sel
    call fword ptr ds:set_rts_proc

set_rts_done:
    pop dx
    pop ebx
    pop ax
    pop ds
    retf32
set_rts Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reset_rts
;
;           description:    Reset RTS signal
;
;           PARAMETERS:         BX          Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_rts_name DB 'Reset Rts',0

reset_rts       Proc far
    push ds
    push ax
    push ebx
    push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc reset_rts_done
;
    mov ds,[ebx].port_sel
    call fword ptr ds:reset_rts_proc

reset_rts_done:
    pop dx
    pop ebx
    pop ax
    pop ds
    retf32
reset_rts       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reserve_com_line
;
;           description:    Reserve com line-state signals
;
;           PARAMETERS:     AL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reserve_com_line_name DB 'Reserve Com Line',0

reserve_com_line    Proc far
    push ds
    push bx
    push dx
;
    mov dx,SEG data
    mov ds,dx
    movzx dx,al
    cmp dx,ds:s_port_count
    jae reserve_line_fail
;    
    mov bx,dx
    add bx,bx
    mov ds,ds:[bx].s_port_arr
;    
    mov edx,ds:cd_reserve_line_proc
    or edx,ds:cd_reserve_line_proc+4
    jz reserve_line_fail
;
    call fword ptr ds:cd_reserve_line_proc

reserve_line_fail:
    pop dx
    pop bx
    pop ds    
    retf32
reserve_com_line    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           device_set_dtr
;
;           description:    Set DTR signal from device selector
;
;           PARAMETERS:     AL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

device_set_dtr_name DB 'Device Set Dtr',0

device_set_dtr  Proc far
    push ds
    push bx
    push edx
;
    mov dx,SEG data
    mov ds,dx
    movzx dx,al
    cmp dx,ds:s_port_count
    jae device_set_dtr_fail
;    
    mov bx,dx
    add bx,bx
    mov ds,ds:[bx].s_port_arr
;
    mov edx,ds:cd_set_dtr_proc
    or edx,ds:cd_set_dtr_proc+4
    jz device_set_dtr_fail
;    
    call fword ptr ds:cd_set_dtr_proc

device_set_dtr_fail:
    pop edx
    pop bx
    pop ds    
    retf32
device_set_dtr  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           device_reset_dtr
;
;           description:    Reset DTR signal from device selector
;
;           PARAMETERS:     AL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

device_reset_dtr_name DB 'Device Reset Dtr',0

device_reset_dtr    Proc far
    push ds
    push bx
    push edx
;
    mov dx,SEG data
    mov ds,dx
    movzx dx,al
    cmp dx,ds:s_port_count
    jae device_reset_dtr_fail
;    
    mov bx,dx
    add bx,bx
    mov ds,ds:[bx].s_port_arr
;
    mov edx,ds:cd_reset_dtr_proc
    or edx,ds:cd_reset_dtr_proc+4
    jz device_reset_dtr_fail
;    
    call fword ptr ds:cd_reset_dtr_proc

device_reset_dtr_fail:
    pop edx
    pop bx
    pop ds    
    retf32
device_reset_dtr    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           wait_for_line_state_change
;
;           description:    Wait for any line-state signal to change
;
;           PARAMETERS:     AL      Port #
;
;       RETURNS:    NC  AL  Current line-state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_line_state_change_name DB 'Wait For Line State Change',0

wait_for_line_state_change      Proc far
    push ds
    push bx
    push edx
;
    mov dx,SEG data
    mov ds,dx
    movzx dx,al
    cmp dx,ds:s_port_count
    jae wait_for_line_state_fail
;    
    mov bx,dx
    add bx,bx
    mov ds,ds:[bx].s_port_arr
;
    mov edx,ds:cd_wait_for_line_state_proc
    or edx,ds:cd_wait_for_line_state_proc+4
    jz wait_for_line_state_fail
;    
    call fword ptr ds:cd_wait_for_line_state_proc
    clc
    jmp wait_for_line_state_done

wait_for_line_state_fail:
    stc

wait_for_line_state_done:
    pop edx
    pop bx
    pop ds    
    retf32
wait_for_line_state_change      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_line_state
;
;           description:    Get current line-state
;
;           PARAMETERS:     AL      Port #
;
;       RETURNS:    NC  AL  Current line-state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_line_state_name DB 'Get Line State',0

get_line_state  Proc far
    push ds
    push bx
    push edx
;
    mov dx,SEG data
    mov ds,dx
    movzx dx,al
    cmp dx,ds:s_port_count
    jae get_line_state_fail
;    
    mov bx,dx
    add bx,bx
    mov ds,ds:[bx].s_port_arr
;
    mov edx,ds:cd_get_line_state_proc
    or edx,ds:cd_get_line_state_proc+4
    jz get_line_state_fail
;    
    call fword ptr ds:cd_get_line_state_proc
    clc
    jmp get_line_state_done

get_line_state_fail:
    stc

get_line_state_done:
    pop edx
    pop bx
    pop ds    
    retf32
get_line_state  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForCom
;
;           DESCRIPTION:    Start a wait for com
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_com      PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:sw_handle
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc start_wait_for_done
;
    mov ds,[ebx].port_sel
    mov ds:avail_obj,es
    mov ax,ds:rec_count
    or ax,ax
    je start_wait_for_done
;
    mov ds:avail_obj,0
    SignalWait

start_wait_for_done:
    pop ebx
    pop ax
    pop ds
    retf32
start_wait_for_com Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForCom
;
;           DESCRIPTION:    Stop a wait for com
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_com       PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:sw_handle
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc stop_wait_done
;
    mov ds,[ebx].port_sel
    mov ds:avail_obj,0

stop_wait_done:
    pop ebx
    pop ax
    pop ds
    retf32
stop_wait_for_com Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearCom
;
;           DESCRIPTION:    Clear com
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_com       PROC far
    retf32
clear_com Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsComIdle
;
;           DESCRIPTION:    Check if com is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_com_idle     PROC far
    push ds
    push ax
    push ebx
;
    mov bx,es:sw_handle
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc is_idle_done
;
    mov ds,[ebx].port_sel
    mov ax,ds:rec_count
    or ax,ax
    clc
    je is_idle_done
;
    stc

is_idle_done:
    pop ebx
    pop ax
    pop ds
    retf32
is_com_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForCom
;
;           DESCRIPTION:    Add a wait for serial port
;
;           PARAMETERS:         AX      Serial handle
;               BX      Wait handle
;               ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_com_name   DB 'Add Wait For Com',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_com,   SEG code
aw1 DD OFFSET stop_wait_for_com,    SEG code
aw2 DD OFFSET clear_com,            SEG code
aw3 DD OFFSET is_com_idle,          SEG code

add_wait_for_com    PROC far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov ax,cs
    mov es,ax
    mov ax,SIZE serial_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_done
;
    mov es:sw_handle,ax

add_wait_done:
    pop edi
    pop eax
    pop es
    pop ds
    retf32
add_wait_for_com    ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddComPort
;
;           DESCRIPTION:    Add a serial port
;
;           PARAMETERS:     AX      Controller #
;                           DX      Device #
;                           DS      Com device selector
;
;           RETURNS:        AX      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_com_port_name       DB 'Add Com Port',0

add_com_port    Proc far
    push ds
    push es
    push bx
;    
    mov bx,SEG data
    mov es,bx
    mov bx,es:s_port_count
    cmp bx,MAX_PORTS
    je add_com_port_done
;
    mov ds:cd_set_dtr_proc,0
    mov ds:cd_set_dtr_proc+4,0
    mov ds:cd_reset_dtr_proc,0
    mov ds:cd_reset_dtr_proc+4,0
    mov ds:cd_wait_for_line_state_proc,0
    mov ds:cd_wait_for_line_state_proc+4,0
    mov ds:cd_get_line_state_proc,0
    mov ds:cd_get_line_state_proc+4,0
    mov ds:cd_line_reserved,0
    mov ds:cd_controller,ax
    mov ds:cd_device,dx
    mov ds:cd_open,0
    mov ds:cd_com_port,bl
;
    mov ax,bx
    add bx,bx
    mov es:[bx].s_port_arr,ds
    inc es:s_port_count

add_com_port_done:
    pop bx
    pop es
    pop ds    
    retf32
add_com_port    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET delete_handle
    mov ax,SERIAL_HANDLE
    RegisterHandle
;
    mov esi,OFFSET add_com_port
    mov edi,OFFSET add_com_port_name
    xor cl,cl
    mov ax,add_com_port_nr
    RegisterOsGate
;
    mov esi,OFFSET reserve_com_line
    mov edi,OFFSET reserve_com_line_name
    xor cl,cl
    mov ax,reserve_com_line_nr
    RegisterOsGate
;
    mov esi,OFFSET device_set_dtr
    mov edi,OFFSET device_set_dtr_name
    xor cl,cl
    mov ax,device_set_dtr_nr
    RegisterOsGate
;
    mov esi,OFFSET device_reset_dtr
    mov edi,OFFSET device_reset_dtr_name
    xor cl,cl
    mov ax,device_reset_dtr_nr
    RegisterOsGate
;
    mov esi,OFFSET wait_for_line_state_change
    mov edi,OFFSET wait_for_line_state_change_name
    xor cl,cl
    mov ax,wait_for_line_state_nr
    RegisterOsGate
;
    mov esi,OFFSET get_line_state
    mov edi,OFFSET get_line_state_name
    xor cl,cl
    mov ax,get_line_state_nr
    RegisterOsGate
;
    mov esi,OFFSET add_wait_for_com
    mov edi,OFFSET add_wait_for_com_name
    xor dx,dx
    mov ax,add_wait_for_com_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_max_com_port
    mov edi,OFFSET get_max_com_port_name
    xor dx,dx
    mov ax,get_max_com_port_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_com_available
    mov edi,OFFSET is_com_available_name
    xor dx,dx
    mov ax,is_com_available_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_com
    mov edi,OFFSET open_com_name
    xor dx,dx
    mov ax,open_com_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_com
    mov edi,OFFSET close_com_name
    xor dx,dx
    mov ax,close_com_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET flush_com
    mov edi,OFFSET flush_com_name
    xor dx,dx
    mov ax,flush_com_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_com_rec_count
    mov edi,OFFSET get_com_rec_count_name
    xor dx,dx
    mov ax,get_com_rec_count_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET reset_com
    mov edi,OFFSET reset_com_name
    xor dx,dx
    mov ax,reset_com_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_com
    mov edi,OFFSET read_com_name
    xor dx,dx
    mov ax,read_com_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_com
    mov edi,OFFSET write_com_name
    xor dx,dx
    mov ax,write_com_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET wait_for_send_completed_com
    mov edi,OFFSET wait_for_send_completed_com_name
    xor dx,dx
    mov ax,wait_for_send_completed_com_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET enable_cts
    mov edi,OFFSET enable_cts_name
    xor dx,dx
    mov ax,enable_cts_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET disable_cts
    mov edi,OFFSET disable_cts_name
    xor dx,dx
    mov ax,disable_cts_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET enable_auto_rts
    mov edi,OFFSET enable_auto_rts_name
    xor dx,dx
    mov ax,enable_auto_rts_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET disable_auto_rts
    mov edi,OFFSET disable_auto_rts_name
    xor dx,dx
    mov ax,disable_auto_rts_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_auto_rts_on
    mov edi,OFFSET is_auto_rts_on_name
    xor dx,dx
    mov ax,is_auto_rts_on_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_cts
    mov edi,OFFSET get_cts_name
    xor dx,dx
    mov ax,get_cts_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_dsr
    mov edi,OFFSET get_dsr_name
    xor dx,dx
    mov ax,get_dsr_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_dtr
    mov edi,OFFSET set_dtr_name
    xor dx,dx
    mov ax,set_dtr_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET reset_dtr
    mov edi,OFFSET reset_dtr_name
    xor dx,dx
    mov ax,reset_dtr_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_rts
    mov edi,OFFSET set_rts_name
    xor dx,dx
    mov ax,set_rts_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET reset_rts
    mov edi,OFFSET reset_rts_name
    xor dx,dx
    mov ax,reset_rts_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_com_receive_space
    mov edi,OFFSET get_com_receive_space_name
    xor dx,dx
    mov ax,get_com_receive_space_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_com_send_space
    mov edi,OFFSET get_com_send_space_name
    xor dx,dx
    mov ax,get_com_send_space_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET supports_full_duplex
    mov edi,OFFSET supports_full_duplex_name
    xor dx,dx
    mov ax,supports_full_duplex_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET send_com_break
    mov edi,OFFSET send_com_break_name
    xor dx,dx
    mov ax,send_com_break_nr
    RegisterBimodalUserGate
;
    mov bx,SEG data
    mov es,bx
    mov cx,2 + 2 * MAX_PORTS
    xor di,di
    xor al,al
    rep stosb
    clc
    ret
init    Endp


code    ENDS

    END init
