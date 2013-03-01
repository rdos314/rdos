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
; TIBASE.ASM
; Basic tibbo support functions not available from RDOS device-driver interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def
INCLUDE ..\..\kernel\os\proc.inc
include ..\os\com.inc

    .386p

tibbo_com_port_struc    STRUC

tp_base_struc  com_port_struc <>

tp_port      DD ?,?

tibbo_com_port_struc    ENDS


tibbo_com_device_struc   STRUC

td_base_struc    com_device_struc <>

td_port      DD ?,?

tibbo_com_device_struc   ENDS

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UdpCallback
;
;       DESCRIPTION:    UDP callback
;
;       PARAMETERS:     EDX         IP
;                       ES:EDI      UDP request data
;                       CX          UDP request size
;
;       RETURNS:        ES:EDI      UDP reply data
;                       CX          UDP reply size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn ImplUdpCallback:near

udp_callback    Proc far
    movzx ecx,cx
    call ImplUdpCallback
    xor ecx,ecx
    ret
udp_callback    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitTibboBase
;
;           DESCRIPTION:    Initialize Tibbo base
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitTibboBase_

InitTibboBase_    Proc near
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET udp_callback
    mov si,4095
    ListenUdpPort
;
    popad
    pop es
    pop ds
    ret
InitTibboBase_    Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           BroadcastCallback
;
;       DESCRIPTION:    Broadcast callback
;
;       PARAMETERS:     DS          Class selector
;                       FS          Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn ImplBroadcast:near

broadcast_callback    Proc far
    push ds
    mov eax,fs
    call ImplBroadcast
    pop ds
    ret
broadcast_callback    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitBroadcast
;
;           DESCRIPTION:    Initialize broadcast
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitBroadcast_

InitBroadcast_    Proc near
    push ds
    push es
    push fs
    pushad
;    
    mov ax,cs
    mov es,ax
    mov edi,OFFSET broadcast_callback
    NetBroadcast
;
    popad
    pop fs
    pop es
    pop ds
    ret
InitBroadcast_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           open_com
;
;   Description:    Open a serial port
;
;   PARAMETERS:     DS      Port selector
;                   ES      Device selector
;                   AH      # of data bits
;                   BL      # of stop bits
;                   BH      parity
;                   ECX     baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com    Proc far
    stc
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
    stc
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
    ret
flush_com Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   
;
;       NAME:       ResetPort
;
;       DESCRIPTION:    Reset com
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_port   PROC far
    ret
reset_port  Endp

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
    ret
reset_rts   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       reset_com
;
;       description:    Reset com
;
;       PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_com   Proc far
    ret
reset_com   Endp


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
pt00 DD OFFSET open_com,        SEG _TEXT
pt01 DD OFFSET close_com,       SEG _TEXT
pt02 DD OFFSET enable_cts,      SEG _TEXT
pt03 DD OFFSET disable_cts,     SEG _TEXT
pt04 DD OFFSET set_dtr,         SEG _TEXT
pt05 DD OFFSET reset_dtr,       SEG _TEXT
pt06 DD OFFSET set_rts,         SEG _TEXT
pt07 DD OFFSET reset_rts,       SEG _TEXT
pt08 DD OFFSET enable_auto_rts, SEG _TEXT
pt09 DD OFFSET disable_auto_rts, SEG _TEXT
pt10 DD OFFSET flush_com,       SEG _TEXT
pt11 DD OFFSET start_send,      SEG _TEXT
pt12 DD OFFSET reset_port,      SEG _TEXT

create_port Proc far
    push eax
    push ecx
    push esi
    push edi
;
    mov eax,SIZE tibbo_com_port_struc
    AllocateSmallGlobalMem
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stosb
;
    mov esi,OFFSET port_tab
    xor edi,edi
    mov ecx,2 * 13
    rep movs dword ptr es:[edi],cs:[esi]
;    
    pop edi
    pop esi
    pop ecx
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
    stc
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
    xor al,al
    stc
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
    xor al,al
    stc
    ret
wait_for_line_state Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AddPort
;
;   DESCRIPTION:    Add port to list of available ports
;
;   PARAMETERS:     ES:EDI          Port structure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPort Proc near
    push ds
    push es
    pushad
;
    mov edx,es    
    mov eax,SIZE tibbo_com_device_struc
    AllocateSmallGlobalMem
;
    mov ax,es
    mov ds,ax
    mov ds:td_port,edi
    mov ds:td_port+4,edx    
    xor ax,ax
    xor dx,dx
    AddComPort
;    
    mov dword ptr ds:cd_create_proc,OFFSET create_port
    mov dword ptr ds:cd_create_proc+4,cs
;    
    mov dword ptr ds:cd_reserve_line_proc,OFFSET reserve_line_state
    mov dword ptr ds:cd_reserve_line_proc+4,cs
;    
    mov dword ptr ds:cd_set_dtr_proc,OFFSET device_set_dtr
    mov dword ptr ds:cd_set_dtr_proc+4,cs
;    
    mov dword ptr ds:cd_reset_dtr_proc,OFFSET device_reset_dtr
    mov dword ptr ds:cd_reset_dtr_proc+4,cs
;    
    mov dword ptr ds:cd_get_line_state_proc,OFFSET get_line_state
    mov dword ptr ds:cd_get_line_state_proc+4,cs
;    
    mov dword ptr ds:cd_wait_for_line_state_proc,OFFSET wait_for_line_state
    mov dword ptr ds:cd_wait_for_line_state_proc+4,cs
;
    popad
    pop es
    pop ds  
    ret
AddPort Endp

_TEXT    ENDS

    END
