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
; CDCCOM.ASM
; Implements USB CDC serial port class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include usb.inc
INCLUDE ..\os\protseg.def
include ..\os\com.inc
include cdc.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

MAX_PORTS       = 32

FLAG_CDC_DISCONNECT = 2
FLAG_CDC_REINIT = 4

FLG_ENABLE_AUTO_RTS  = 1

usb_cdc_port_struc       STRUC

ucp_base_struc  com_port_struc <>

ucp_device_sel      DW ?
ucp_cdc_sel         DW ?
ucp_cdc_unit_sel    DW ?
ucp_flgs            DB ?

ucp_timer_active    DB ?

usb_cdc_port_struc       ENDS

usb_cdc_device_struc   STRUC

ucd_base_struc      com_device_struc <>

ucd_port_sel        DW ?
ucd_cdc_sel         DW ?
ucd_cdc_unit_sel    DW ?

ucd_port_offset     DD ?
ucd_port_nr         DW ?

ucd_in_buffer       DW ?
ucd_out_buffer      DW ?

ucd_wait            DW ?
ucd_thread          DW ?
ucd_detach          DW ?

ucd_section         section_typ <>

usb_cdc_device_struc   ENDS

data    SEGMENT byte public 'DATA'

sd_ports        DW ?
sd_port_arr     DW MAX_PORTS DUP(?)

data	ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetUsbCdcComPar
;
;   DESCRIPTION:    Get USB cdc com param
;
;   PARAMETERS:     AL      Port #
;
;   RETURNS:        NC      OK
;                       DX  Vendor
;                       AX  Product
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_cdc_com_par_name    DB 'Get USB CDC Com Param', 0

get_usb_cdc_com_par Proc far
    push ds
    push es
    push ebx
    push ecx
;
    mov ebx,SEG data
    mov ds,ebx
    mov ebx,OFFSET sd_port_arr
    movzx ecx,ds:sd_ports
    movzx ax,al
    or ecx,ecx
    jz gscpFail

gscpLoop:
    mov dx,ds:[ebx]
    or dx,dx
    jz gscpNext
;
    mov es,edx
    cmp ax,es:ucd_port_nr
    je gscpFound

gscpNext:
    add ebx,2
    loop gscpLoop

gscpFail:
    stc
    jmp gscpDone

gscpFound:
    mov ds,es:ucd_cdc_sel
    mov dx,ds:cdc_vendor
    mov ax,ds:cdc_product
    clc

gscpDone:
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
get_usb_cdc_com_par     ENDP    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           open_com
;
;           description:    Open a serial port
;
;           PARAMETERS:     DS          Port selector
;                           ES          Device selector
;                           AH          # of data bits
;                           BL          # of stop bits
;                           BH          parity
;                           ECX         baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com   Proc far
    push ds
    pushad
;
    mov ds:ucp_timer_active,0
;
    mov edx,ds
    mov eax,es
    mov ds,eax
    EnterSection ds:ucd_section
    mov ds:ucd_port_sel,dx
    LeaveSection ds:ucd_section       
;
    mov bx,ds:ucd_thread
    Signal    
    clc
;
    popad
    pop ds
    ret
open_com   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           close_com
;
;           description:    Close serial port
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com  Proc far
    mov al,ds:ucp_timer_active
    or al,al
    jz ccfTimerClosed
;
    mov ebx,ds
    StopTimer
    mov ds:ucp_timer_active,0

ccfTimerClosed:
    ret
close_com  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           enable_cts
;
;           DESCRIPTION:    Enable CTS signal
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_cts PROC far
    stc
    ret
enable_cts Endp
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           disable_cts
;
;           DESCRIPTION:    Disable CTS signal
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_cts    PROC far
    stc
    ret
disable_cts    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_dtr
;
;           description:    Set DTR signal
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dtr    Proc far
    stc
    ret
set_dtr    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reset_dtr
;
;           description:    Reset DTR signal
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_dtr  Proc far
    stc
    ret
reset_dtr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_rts
;
;           description:    Set RTS signal
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rts    Proc far
    stc
    ret
set_rts    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reset_rts
;
;           description:    Reset RTS signal
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_rts  Proc far
    stc
    ret
reset_rts  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           EnableAutoRts
;
;           DESCRIPTION:    Enable automatic RTS on send
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_auto_rts PROC far
    or ds:ucp_flgs,FLG_ENABLE_AUTO_RTS
    ret
enable_auto_rts Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DisableAutoRts
;
;           DESCRIPTION:    Disable automatic RTS on send
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_auto_rts    PROC far
    and ds:ucp_flgs,NOT FLG_ENABLE_AUTO_RTS
    ret
disable_auto_rts Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsAutoRtsOn
;
;           DESCRIPTION:    Check for automatic RTS on send
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_auto_rts_on PROC far
    test ds:ucp_flgs,FLG_ENABLE_AUTO_RTS
    jz iarOff

iarOn:
    clc
    ret

iarOff:
    stc
    ret
is_auto_rts_on Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FlushCom
;
;           DESCRIPTION:    Flush com
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_com       PROC far
    ret
flush_com Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           send_break
;
;           DESCRIPTION:    Send break
;
;           PARAMETERS:     DS      Port selector
;                           AL      Break characters
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_break PROC far
    ret
send_break Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           full_duplex
;
;           DESCRIPTION:    Check for full duplex
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

full_duplex PROC far
    stc
    ret
full_duplex Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           start_send
;
;           description:    Start send
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_send      PROC far
    push es
    push ax
;    
    mov ax,ds:ucp_cdc_sel
    or ax,ax
    jz ssDone
;    
    mov es,ax
    test es:cdc_flags,FLAG_CDC_DISCONNECT
    jz ssOk
;
    mov ds:send_count,0
    mov ds:send_head,0
    mov ds:send_tail,0
    jmp ssDone

ssOk:    
;    call StartSendTimer

ssDone:
    pop ax
    pop es    
    ret
start_send      Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResetPort
;
;           DESCRIPTION:    Reset com
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_port       PROC far
    push ds
    push es
    push eax
    push ecx
    push edi
;
    mov es,ds:ucp_cdc_sel
    mov bx,es:cdc_dev_handle
    ResetUsbDevice
;
    pop edi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
reset_port Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateComPort
;
;   DESCRIPTION:    
;
;   PARAMETERS:     DS		CDC selector
;                   FS          CDC unit
;
;   RETURNS:        ES          Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

com_port_tab:
cpt00 DD OFFSET open_com,           SEG code
cpt01 DD OFFSET close_com,          SEG code
cpt02 DD OFFSET enable_cts,         SEG code
cpt03 DD OFFSET disable_cts,        SEG code
cpt04 DD OFFSET set_dtr,            SEG code
cpt05 DD OFFSET reset_dtr,          SEG code
cpt06 DD OFFSET set_rts,            SEG code
cpt07 DD OFFSET reset_rts,          SEG code
cpt08 DD OFFSET enable_auto_rts,    SEG code
cpt09 DD OFFSET disable_auto_rts,   SEG code
cpt10 DD OFFSET flush_com,          SEG code
cpt11 DD OFFSET start_send,         SEG code
cpt12 DD OFFSET reset_port,         SEG code
cpt13 DD OFFSET full_duplex,        SEG code
cpt14 DD OFFSET is_auto_rts_on,     SEG code
cpt15 DD OFFSET send_break,         SEG code

CreateComPort	Proc far
    pushad
;
    mov eax,SIZE usb_cdc_port_struc
    AllocateSmallGlobalMem
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stosb
;
    mov esi,OFFSET com_port_tab
    xor edi,edi
    mov ecx,2 * 16
    rep movs dword ptr es:[edi],cs:[esi]
;
    mov ax,ds:ucd_cdc_sel
    mov es:ucp_cdc_sel,ax
    mov ax,ds:ucd_cdc_unit_sel
    mov es:ucp_cdc_unit_sel,ax
    mov es:ucp_flgs,0
;    
    popad
    ret
CreateComPort	Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           FindInterfaces
;
;   DESCRIPTION:    
;
;   PARAMETERS:     DS      CDC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindInterfaces	Proc near
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
;
    mov bx,ds:cdc_controller
    mov al,ds:cdc_port
    xor dl,dl
    mov ecx,1000h
    xor edi,edi
    GetUsbConfig
    mov ecx,eax
    or ecx,ecx
    stc
    jz fiFail
;
    xor edi,edi
    movzx ecx,es:ucd_len
    add edi,ecx

fiDescrLoop:
    mov al,es:[edi].udd_type
    cmp al,4
    jne fiDescrNext

fiInterface:
    movzx ecx,ds:cdc_unit_count
    mov ebx,OFFSET cdc_unit_arr

fiIntLoop:
    mov fs,ds:[ebx]
    mov al,fs:unit_interface
    cmp al,es:[edi].uid_id
    je fiPipeNext
    jmp fiIntNext

fiPipeLoop:
    mov al,es:[edi].udd_type
    cmp al,4
    je fiDescrLoop
;
    cmp al,5
    jne fiPipeNext
;
    mov al,es:[edi].ued_attrib
    and al,3
    cmp al,2
    jne fiPipeNext

fiIsBulk:
    mov dl,es:[edi].ued_address
    test dl,80h
    jz fiIsBulkOut

fiIsBulkIn:
    mov fs:unit_bulk_in,dl
    mov ax,es:[edi].ued_maxsize
    mov fs:unit_in_size,ax
    jmp fiPipeNext

fiIsBulkOut:
    mov fs:unit_bulk_out,dl
    mov ax,es:[edi].ued_maxsize
    mov fs:unit_out_size,ax

fiPipeNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz fiOk
;
    add edi,ecx
    cmp di,es:ucd_size
    jb fiPipeLoop
    jmp fiOk

fiIntNext:
    add ebx,2
    sub ecx,1
    jnz fiIntLoop

fiDescrNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz fiOk
;
    add edi,ecx
    cmp di,es:ucd_size
    jb fiDescrLoop

fiOk:
    FreeMem
    clc
    jmp fiDone

fiFail:
    FreeMem
    stc

fiDone:
    ret
FindInterfaces	Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CheckInterfaces
;
;   DESCRIPTION:    
;
;   PARAMETERS:     DS      CDC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckInterfaces	Proc near
    movzx ecx,ds:cdc_unit_count
    mov ebx,OFFSET cdc_unit_arr

ciLoop:
    mov fs,ds:[ebx]
    mov al,fs:unit_bulk_in
    or al,al
    jz ciFail
;
    mov al,fs:unit_bulk_out
    or al,al
    jz ciFail
;
    add ebx,2
    loop ciLoop
;
    clc
    jmp ciDone

ciFail:
    stc

ciDone:
    ret
CheckInterfaces	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateComDevice
;
;   DESCRIPTION:    
;
;   PARAMETERS:     DS		CDC selector
;                   FS          CDC unit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateComDevice	Proc near
    push ds
    push es
    pushad
;
    mov eax,SIZE usb_cdc_device_struc
    AllocateSmallGlobalMem
    mov es:ucd_port_sel,0
    mov es:ucd_cdc_sel,ds
    mov es:ucd_cdc_unit_sel,fs
    mov es:ucd_in_buffer,0
    mov es:ucd_out_buffer,0
    mov es:ucd_wait,0
;
    mov dword ptr es:cd_create_proc,OFFSET CreateComPort
    mov dword ptr es:cd_create_proc+4,cs
;
    mov ax,ds:cdc_controller
    mov dl,ds:cdc_port
    mov dh,ds:cdc_com_count    
;
    push ds
    mov esi,SEG data
    mov ds,esi
    movzx esi,ds:sd_ports
    add esi,esi
    mov ds:[esi].sd_port_arr,es
    inc ds:sd_ports
    mov es:ucd_port_offset,esi
;
    mov esi,es
    mov ds,esi
    InitSection ds:ucd_section
;
    AddComPort
    mov ds:ucd_port_nr,ax
    pop ds
;
    movzx bx,ds:cdc_com_count
    shl bx,1
    mov ds:[bx].cdc_com_arr,es
    inc ds:cdc_com_count
;
    popad
    pop es
    pop ds
    ret
CreateComDevice	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           Reinit
;
;   DESCRIPTION:    Reinit unit
;
;   PARAMETERS:     DS          Device selector
;                   ES		CDC selector
;                   FS          CDC unit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Reinit  Proc near
    ret
Reinit	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           OpenPort
;
;   DESCRIPTION:    Open port
;
;   PARAMETERS:     DS          Device selector
;                   ES		CDC selector
;                   FS          CDC unit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPort    Proc near
    push es
    movzx eax,fs:unit_in_size
    AllocateSmallGlobalMem
    mov ds:ucd_in_buffer,es
    pop es
;
    mov bx,es:cdc_dev_handle
    mov dl,fs:unit_bulk_in
    mov cx,10
    mov ax,2
    OpenUsbPacketPipe
;
    push es
    mov bx,es:cdc_dev_handle
    mov dl,fs:unit_bulk_out
    mov cx,fs:unit_out_size
    shl cx,2
    mov ax,5
    OpenUsbRawPipe
    mov ds:ucd_out_buffer,es
    pop es
;
    CreateWait
    mov ds:ucd_wait,bx
;
    mov bx,es:cdc_dev_handle
    mov dl,fs:unit_bulk_in
    mov ecx,ds
    AddWaitForUsbDevicePipe
    ret
OpenPort    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ClosePort
;
;   DESCRIPTION:    Close port
;
;   PARAMETERS:     DS          Device selector
;                   ES		CDC selector
;                   FS          CDC unit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePort    Proc near
    mov bx,es:cdc_dev_handle
    mov dl,fs:unit_bulk_in
    CloseUsbPipe
;
    mov bx,es:cdc_dev_handle
    mov dl,fs:unit_bulk_out
    CloseUsbPipe
;    
    push es
    mov es,ds:ucd_in_buffer
    FreeMem
    pop es
;
    mov bx,ds:ucd_wait
    CloseWait
;
    mov ds:ucd_wait,0
    mov ds:ucd_in_buffer,0
    mov ds:ucd_out_buffer,0
    ret
ClosePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           PollRead
;
;   DESCRIPTION:    Poll input-buffer
;
;   PARAMETERS:     DS          Device selector
;                   ES		CDC selector
;                   FS          CDC unit
;                   CX          Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollRead    Proc near
    push ds
    push fs
;
    xor si,si
    mov fs,ds:ucd_in_buffer
    mov ds,ds:ucd_port_sel
    mov es,ds:rec_buf
    or cx,cx
    jz prDone

prGetLoop:
    lods byte ptr fs:[si]
    RequestSpinlock ds:com_spinlock
    mov dx,ds:rec_count
    cmp dx,ds:rec_size
    je prSignal
;       
    inc dx
    mov ds:rec_count,dx
    mov bx,ds:rec_tail
    mov es:[bx],al
    inc bx
    cmp bx,ds:rec_size
    jnz prWrapOk
;
    xor bx,bx
    
prWrapOk:
    mov ds:rec_tail,bx
    ReleaseSpinlock ds:com_spinlock
    loop prGetLoop
    jmp prSigRel

prSignal:
    ReleaseSpinlock ds:com_spinlock

prSigRel:
    xor bx,bx
    xchg bx,ds:avail_obj
    or bx,bx
    jz prDone
;
    mov es,bx
    SignalWait
    
prDone:
    pop fs
    pop ds
    ret
PollRead    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           PollWrite
;
;   DESCRIPTION:    Poll output-buffer
;
;   PARAMETERS:     DS          Device selector
;                   ES		CDC selector
;                   FS          CDC unit
;
;   RETURNS:        CX          Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollWrite    Proc near
    push ds
    push fs
;   
    xor cx,cx
    mov bp,fs:unit_out_size
    mov ax,ds:ucd_out_buffer
    or ax,ax
    jz pwDone
;    
    mov es,ax
    mov ds,ds:ucd_port_sel
    mov al,ds:ucp_timer_active
    or al,al
    jnz pwDone
;    
    xor di,di
    mov fs,ds:send_buf
    mov dx,ds:send_count
    or dx,dx
    jz pwDone

pwLoop:
    RequestSpinlock ds:com_spinlock
    mov dx,ds:send_count
    or dx,dx
    jz pwSend
;       
    dec dx
    mov ds:send_count,dx
    mov bx,ds:send_head
    mov al,fs:[bx]
    stosb
    inc bx
    cmp bx,ds:send_size
    jnz pwWrapOk
;       
    xor bx,bx

pwWrapOk:
    mov ds:send_head,bx
    ReleaseSpinlock ds:com_spinlock
;
    inc cx
    cmp cx,bp
    jb pwLoop
    jmp pwSendRel

pwSend:
    ReleaseSpinlock ds:com_spinlock

pwSendRel:
    mov ax,ds:send_size    
    or ax,ax
    jz pwDone
;
;    call StartSendTimer    

pwDone:
    pop fs
    pop ds    
    ret
PollWrite   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleDevice
;
;   DESCRIPTION:    Handle device
;
;   PARAMETERS:     DS          Device selector
;                   ES		CDC selector
;                   FS          CDC unit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleDevice    Proc near
    test es:cdc_flags,FLAG_CDC_DISCONNECT
    jnz hdDone

hdConn:
    mov ax,ds:ucd_port_sel
    or ax,ax
    jz hdClosed

hdOpen:
    mov bx,ds:ucd_wait
    or bx,bx
    jnz hdIsOpen
;
    call OpenPort    
;
    test es:cdc_flags,FLAG_CDC_REINIT
    jz hdIsOpen    
;
    call ReInit
    and es:cdc_flags,NOT FLAG_CDC_REINIT

hdIsOpen:    
;    mov bx,ds:ucd_in_req
;    IsUsbReqStarted
    jnc hdOpenOk
;
;    StartUsbReq

hdOpenOk:    
;    mov bx,ds:ucd_in_req
;    IsUsbReqReady
    jc hdReadDone
;
;    GetUsbReqData
    jc hdReadRestart
;    
    call PollRead

hdReadRestart:
;    mov bx,ds:ucd_in_req
;    StartUsbReq

hdReadDone:
;    mov bx,ds:ucd_out_req
;    IsUsbReqStarted
    jc hdCheckWrite
;    
;    IsUsbReqReady
    jc hdDone
;
    push ds
    mov ds,ds:ucd_port_sel
    mov bx,ds:send_wait
    pop ds
    or bx,bx
    jz hdCheckWrite
;    
    Signal

hdCheckWrite:
    call PollWrite
    or cx,cx
    jz hdDone
;
;    mov bx,ds:ucd_out_req
;    StartUsbReq
    jmp hdDone

hdClosed:
    and es:cdc_flags,NOT FLAG_CDC_REINIT
;
;    mov bx,ds:ucd_in_req
;    or bx,bx
;    jz hdDone

hdIsClosed:
    call ClosePort
    
hdDone:
    ret
HandleDevice    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CDC server thread
;
;   DESCRIPTION:    
;
;   PARAMETERS:     BX      CDC sel
;                   DL      Unit       
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cdc_server:
    int 3
    mov es,bx
    movzx bx,dl
    shl bx,1
    mov ax,es:[bx].cdc_com_arr
    or ax,ax
    jz tFail
;
    mov ds,ax

tLoop:
    WaitForSignal

tSignalled:
    test es:cdc_flags,FLAG_CDC_DISCONNECT
    jnz tExit
;
    movzx ecx,es:cdc_unit_count
    mov ebx,OFFSET cdc_unit_arr

tDevLoop:
    push es
    push ebx
    push ecx
;
    mov fs,es:[ebx]
    EnterSection ds:ucd_section
    push ds
    call HandleDevice
    pop ds
    LeaveSection ds:ucd_section
;
    pop ecx
    pop ebx
    pop es    
    add ebx,2
    loop tDevLoop
;    
    jmp tLoop

tExit:
    movzx ecx,es:cdc_unit_count
    mov ebx,OFFSET cdc_unit_arr

tCloseLoop:
    push es
    push ebx
    push ecx
;
    mov fs,es:[ebx]
    EnterSection ds:ucd_section
    push ds
    mov ax,ds:ucd_port_sel
    or ax,ax
    jz udPortHandleOk
;
    call ClosePort

udPortHandleOk:    
    pop ds
    LeaveSection ds:ucd_section
;
    pop ecx
    pop ebx
    pop es    
    add ebx,2
    loop tCloseLoop
;    

tFail:
    TerminateThread
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HexToAscii
;
;   DESCRIPTION:    
;
;   PARAMETERS:     AL      Number to convert
;
;   RETURNS:        AX      Ascii result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HexToAscii      PROC near
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
;
    add al,7

ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
;
    add ah,7

ok_high1:
    add ah,30h
    ret
HexToAscii      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateServerThread
;
;   Description:    Create server thread
;
;   PARAMETERS:     DS		CDC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

com_name  DB 'CDC Com ', 0

CreateServerThread    Proc near
    push ds
    push es
    pushad
;
    mov bx,ds:cdc_controller
    mov al,ds:cdc_port
    OpenUsbDevice
    mov ds:cdc_dev_handle,bx
;
    mov eax,100h
    AllocateSmallGlobalMem
;
    mov bx,ds
    xor dl,dl
    cmp dl,ds:cdc_com_count
    jz cstFree

cstUnitLoop:
    xor edi,edi
    mov esi,OFFSET com_name

cstCopyLoop:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz cstCopyDone
;
    stosb
    jmp cstCopyLoop

cstCopyDone:
    mov ax,ds:cdc_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,ds:cdc_port
    call HexToAscii
    stosw
;
    mov al,'-'
    stosb
;
    mov al,dl
    add al,'0'
    stosb
;
    xor al,al
    stosb
;
    push ds
;
    xor edi,edi
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET cdc_server
    mov eax,3
    mov ecx,stack0_size
    CreateThread
;
    pop ds
;
    inc dl
    cmp dl,ds:cdc_com_count
    jne cstUnitLoop

cstFree:
    FreeMem
;
    popad
    pop es
    pop ds
    ret
CreateServerThread   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CDC com threads
;
;   DESCRIPTION:    
;
;   PARAMETERS:     DS      CDC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public cdc_com_recreate

cdc_com_recreate  Proc near
    call FindInterfaces
    jc ccrFail
;
    call CheckInterfaces
    jc ccrFail
;
    or ds:cdc_flags,FLAG_CDC_REINIT
    and ds:cdc_flags,NOT FLAG_CDC_DISCONNECT
    call CreateServerThread

ccrFail:
    ret
cdc_com_recreate Endp

    public cdc_com_start

cdc_com_start  Proc near
    call FindInterfaces
    jc ccsFail
;
    call CheckInterfaces
    jc ccsFail
;
    mov ds:cdc_com_count,0
;
    movzx ecx,ds:cdc_unit_count
    mov ebx,OFFSET cdc_unit_arr

ccsCreateLoop:
    mov fs,ds:[ebx]
    call CreateComDevice
;
    add ebx,2
    loop ccsCreateLoop

ccsStart:
    call CreateServerThread

ccsFail:
    ret
cdc_com_start Endp
                
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CDC com detach
;
;   DESCRIPTION:    
;
;   PARAMETERS:     BX      CDC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public cdc_com_detach

cdc_com_detach	Proc near
    push ds
    push eax
    push ebx
;
    mov bx,ds:cdc_dev_handle
    CloseUsbDevice
;
    pop ebx
    pop eax
    pop ds
    ret
cdc_com_detach	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InitCdcCom
;
;   DESCRIPTION:    Init CDC com
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_cdc_com

init_cdc_com	Proc near
    mov eax,SEG data
    mov ds,eax
    mov ds:sd_ports,0
;
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET get_usb_cdc_com_par
    mov edi,OFFSET get_usb_cdc_com_par_name
    xor dx,dx
    mov ax,get_usb_cdc_com_par_nr
    RegisterBimodalUserGate
    ret
init_cdc_com	Endp
        
code    ENDS

    END
