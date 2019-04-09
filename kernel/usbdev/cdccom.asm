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

usb_cdc_port_struc       STRUC

ucp_base_struc  com_port_struc <>

ucp_device_sel      DW ?
ucp_cdc_sel         DW ?
ucp_cdc_unit_sel    DW ?

ucp_in_handle       DW ?
ucp_out_handle      DW ?

ucp_in_buffer       DW ?
ucp_out_buffer      DW ?

ucp_in_req          DW ?
ucp_out_req         DW ?

usb_cdc_port_struc       ENDS

usb_cdc_device_struc   STRUC

ucd_base_struc      com_device_struc <>

ucd_port_sel        DW ?
ucd_cdc_sel         DW ?
ucd_cdc_unit_sel    DW ?

ucd_port_offset     DD ?
ucd_port_nr         DW ?

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
    mov es,ds:[ebx]
    cmp ax,es:ucd_port_nr
    je gscpFound
;
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
    mov edx,ds
    mov eax,es
    mov ds,eax
    EnterSection ds:ucd_section
    mov ds:ucd_port_sel,dx
    LeaveSection ds:ucd_section       
;
    mov ds,ds:ucd_cdc_sel
    mov bx,ds:cdc_thread
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
    stc
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
    ret
disable_auto_rts Endp

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
;           NAME:           start_send
;
;           description:    Start send
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_send      PROC far
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
    mov bx,es:cdc_controller
    movzx ax,es:cdc_device
    xor dl,dl
    OpenUsbPipe
    ResetUsbPipe
    CloseUsbPipe
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
    mov ecx,2 * 13
    rep movs dword ptr es:[edi],cs:[esi]
;
    mov ax,ds:ucd_cdc_sel
    mov es:ucp_cdc_sel,ax
    mov ax,ds:ucd_cdc_unit_sel
    mov es:ucp_cdc_unit_sel,ax
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
    mov al,ds:cdc_device
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
;   NAME:           OpenControl
;
;   DESCRIPTION:    
;
;   PARAMETERS:     DS		CDC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenControl	Proc near
    CreateWait
    mov ds:cdc_control_wait,bx
;
    mov bx,ds:cdc_controller
    mov al,ds:cdc_device
    xor dl,dl
    OpenUsbPipe
    mov ds:cdc_control_pipe,bx
;
    mov ax,ds:cdc_control_pipe
    mov bx,ds:cdc_control_wait
    movzx ecx,bx
    AddWaitForUsbPipe
    ret
OpenControl	Endp

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
;
    mov dword ptr es:cd_create_proc,OFFSET CreateComPort
    mov dword ptr es:cd_create_proc+4,cs
;
    mov ax,ds:cdc_controller
    movzx dx,ds:cdc_device
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
    mov ds:cdc_com_dev_sel,es
;
    popad
    pop es
    pop ds
    ret
CreateComDevice	Endp

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
    ret
HandleDevice    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CDC com thread
;
;   DESCRIPTION:    
;
;   PARAMETERS:     BX      CDC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public cdc_com_thread

cdc_com_thread:
    mov ds,ebx
    call FindInterfaces
    jc tFail
;
    call CheckInterfaces
    jc tFail
;
    call OpenControl
;
    GetThread
    mov ds:cdc_thread,ax
;
    movzx ecx,ds:cdc_unit_count
    mov ebx,OFFSET cdc_unit_arr

tOpenLoop:
    mov fs,ds:[ebx]
    call CreateComDevice
;
    add ebx,2
    loop tOpenLoop
;
    int 3
    mov eax,ds
    mov es,eax
    mov ds,ds:cdc_com_dev_sel

tLoop:
    WaitForSignal
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

tFail:
    TerminateThread
        
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
