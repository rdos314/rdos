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
; USBCOM.ASM
; FTDI, PL2303 and mct_u232 based USB serial port device
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

MAX_PORTS       = 16
MAX_DEVICES     = 32
MAX_COM_UNITS   = 4

FLAG_UDS_DISCONNECT = 2
FLAG_UDS_REINIT = 4

CONTROL_DTR = 1
CONTROL_RTS = 2
CONTROL_CTS = 4
CONTROL_AUTO_RTS = 8

FLAG_CTS    = 10h
FLAG_DSR    = 20h
FLAG_RI     = 40h
FLAG_RLSD       = 80h
FLAG_DR     = 100h
FLAG_OE     = 200h
FLAG_PE     = 400h
FLAG_FE     = 800h
FLAG_BI     = 1000h
FLAG_THRE       = 2000h
FLAG_TEMT       = 4000h
FLAG_FIFO_ERR   = 8000h

DEVICE_TYPE_FTDI = 100h
DEVICE_TYPE_PL2303 = 200h
DEVICE_TYPE_MCT  = 300h

DEVICE_TYPE_SIO = DEVICE_TYPE_FTDI + 1
DEVICE_TYPE_FT232AM = DEVICE_TYPE_FTDI + 2
DEVICE_TYPE_FT232BM = DEVICE_TYPE_FTDI + 3
DEVICE_TYPE_FT2232C = DEVICE_TYPE_FTDI + 4
DEVICE_TYPE_FT4232H = DEVICE_TYPE_FTDI + 5

DEVICE_TYPE_PL_01 = DEVICE_TYPE_PL2303 + 1
DEVICE_TYPE_PL_HX = DEVICE_TYPE_PL2303 + 2

DEVICE_TYPE_MCT_SITECOM = DEVICE_TYPE_MCT + 1
DEVICE_TYPE_MCT_BELKIN = DEVICE_TYPE_MCT + 2

FLG_ENABLE_AUTO_RTS  = 1

usbcom_port_struc       STRUC

ups_base_struc  com_port_struc <>

ups_device_sel      DW ?
ups_index           DW ?
ups_device_type     DW ?
ups_divisor         DD ?
ups_data_bits       DB ?
ups_stop_bits       DB ?
ups_parity          DB ?
ups_control         DB ?

ups_pl_control      DB ?
ups_pl_buf          DB 7 DUP(?)

usbcom_port_struc       ENDS

usbcom_device_struc   STRUC

uds_base_struc      com_device_struc <>

uds_section         section_typ <>
uds_port_sel        DW ?
uds_device_type     DW ?
uds_in_size         DW ?
uds_out_size        DW ?
uds_interface       DB ?
uds_intr_in         DB ?
uds_bulk_in         DB ?
uds_bulk_out        DB ?
uds_intr_buffer     DW ?
uds_in_buffer       DW ?
uds_out_buffer      DW ?
uds_link            DW ?
uds_port_offset     DW ?
uds_intr_interval   DB ?
uds_port_nr         DW ?
uds_device_sel      DW ?
uds_wait            DW ?
uds_flags           DW ?
uds_thread          DW ?

usbcom_device_struc   ENDS

usb_com_struc   STRUC

uc_vendor               DW ?
uc_product              DW ?
uc_controller           DW ?
uc_dev_handle           DW ?
uc_dev_sel              DW ?
uc_port                 DB ?

uc_section              section_typ <>

uc_detach               DW ?

uc_dev_offset           DW ?

uc_prev                 DW ?
uc_next                 DW ?

uc_interface_count      DB ?
 
uc_unit_count           DB ?
uc_unit_arr             DW MAX_COM_UNITS DUP(?)
 
uc_dev_descr_size       DW ?
uc_dev_descr_buf        DB ?

usb_com_struc   ENDS

com_setup       STRUC

cs_dev_type_proc        DD ?,?
cs_dev_attach_proc      DD ?,?

com_setup       ENDS

data    SEGMENT byte public 'DATA'


sd_dead_list    DW ?
sd_section      section_typ <>

sd_dev_count    DW ?
sd_dev_arr      DW MAX_DEVICES DUP(?)

sd_ports        DW ?
sd_port_arr     DW MAX_PORTS DUP(?)

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
;   NAME:           GetUsbComPar
;
;   DESCRIPTION:    Get  USB com param
;
;   PARAMETERS:     AL      Port #
;
;   RETURNS:        NC      OK
;                       AX  Device type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_com_par_name    DB 'Get USB Com Param', 0

get_usb_com_par Proc far
    push ds
    push es
    push bx
    push dx
;
    mov bx,SEG data
    mov ds,bx
    mov bx,OFFSET sd_port_arr
    mov cx,ds:sd_ports
    movzx ax,al
    or cx,cx
    jz gscpFail

gscpLoop:
    mov dx,ds:[bx]
    or dx,dx
    jz gdcpNext
;    
    mov es,dx
    cmp ax,es:uds_port_nr
    je gscpFound

gdcpNext:
    add bx,2
    loop gscpLoop

gscpFail:
    stc
    jmp gscpDone

gscpFound:
    mov ax,es:uds_device_type
    clc

gscpDone:
    pop dx
    pop bx
    pop es
    pop ds
    retf32
get_usb_com_par     ENDP    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetUsbComDevice
;
;   DESCRIPTION:    Get  USB com device
;
;   PARAMETERS:     AL      Port #
;
;   RETURNS:        NC      OK
;                       BX  Controller
;                       AX  Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_com_dev_name    DB 'Get USB Com Device', 0

get_usb_com_dev Proc far
    push ds
    push es
    push dx
;
    mov bx,SEG data
    mov ds,bx
    mov bx,OFFSET sd_port_arr
    mov cx,ds:sd_ports
    movzx ax,al
    or cx,cx
    jz gscdFail

gscdLoop:
    mov dx,ds:[bx]
    or dx,dx
    jz gdcdNext
;    
    mov es,dx
    cmp ax,es:uds_port_nr
    je gscdFound

gdcdNext:
    add bx,2
    loop gscdLoop

gscdFail:
    stc
    jmp gscdDone

gscdFound:
    mov es,es:uds_device_sel
    mov bx,es:uc_controller
    movzx ax,es:uc_port
    clc

gscdDone:
    pop dx
    pop es
    pop ds
    retf32
get_usb_com_dev     ENDP    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           OpenDevHandle
;
;   DESCRIPTION:    Open device handle
;
;   PARAMETERS:     DS      Port selector
;
;   RETURNS:        NC      OK
;                   BX      Device handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenDevHandle Proc near
    push es
    push ax
;
    mov es,ds:ups_device_sel
    mov es,es:uds_device_sel
    mov bx,es:uc_controller
    mov al,es:uc_port
    OpenUsbDevice
;
    pop ax
    pop es
    ret
OpenDevHandle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CloseDevHandle
;
;   DESCRIPTION:    Close device handle
;
;   PARAMETERS:     BX      Device handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseDevHandle Proc near
    pushf
    CloseUsbDevice
    popf
    ret
CloseDevHandle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDivisorError
;
;           description:    Get baud-rate divisor, error type
;
;           PARAMETERS:         DS      Port selector
;                           ECX         baudrate
;
;       RETURNS:    ECX     Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDivisorError Proc near
    xor cx,cx
    stc
    ret
GetDivisorError Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSioDivisor
;
;           description:    Get baud-rate divisor, SIO type
;
;           PARAMETERS:         DS      Port selector
;                           ECX         baudrate
;
;       RETURNS:    ECX     Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSioDivisor Proc near
    push ax
;    
    xor al,al
    cmp ecx,300
    je gdsDone
;
    inc al
    cmp ecx,600
    je gdsDone
;
    inc al
    cmp ecx,1200
    je gdsDone
;
    inc al
    cmp ecx,2400
    je gdsDone
;
    inc al
    cmp ecx,4800
    je gdsDone
;
    inc al
    cmp ecx,9600
    je gdsDone
;
    inc al
    cmp ecx,19200
    je gdsDone
;
    inc al
    cmp ecx,38400
    je gdsDone
;
    inc al
    cmp ecx,57600
    je gdsDone
;
    inc al
    cmp ecx,115200
    je gdsDone
;
    mov al,5            

gdsDone:               
    movzx ecx,al
    clc
;
    pop ax
    ret
GetSioDivisor Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Get232AmDivisor
;
;           description:    Get baud-rate divisor, 232AM type
;
;           PARAMETERS:         DS      Port selector
;                           ECX         baudrate
;
;       RETURNS:    ECX     Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Get232AmDivisor Proc near
    push eax
    push edx
;    
    xor edx,edx
    mov eax,48000000 / 2
    div ecx
    mov ecx,eax
    and al,7
    cmp al,7
    jne get_am_not7
;
    inc ecx

get_am_not7:
    shr ecx,3
    cmp al,1
    jne get_am_not1
;
    or cx,0C000h
    jmp get_am_part_ok

get_am_not1:
    cmp al,4
    jb get_am_not4
;
    or cx,4000h
    jmp get_am_part_ok
    
get_am_not4:
    or al,al
    je get_am_part_ok
;
    or cx,8000h

get_am_part_ok: 
    cmp cx,1
    jnz get_am_done
;
    xor cx,cx

get_am_done:
    clc
;    
    pop edx
    pop eax    
    ret
Get232AmDivisor Endp
     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Get232BmDivisor
;
;           description:    Get baud-rate divisor, 232BM type
;
;           PARAMETERS:         DS      Port selector
;                           ECX         baudrate
;
;       RETURNS:    ECX     Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fractab:
bft00    DB 0
bft01    DB 3
bft02    DB 2
bft03    DB 4
bft04    DB 1
bft05    DB 5
bft06    DB 6
bft07    DB 7

Get232BmDivisor Proc near
    push eax
    push bx
    push edx
;    
    xor edx,edx
    mov eax,48000000 / 2
    div ecx
    mov ecx,eax
    shr ecx,3
;
    movzx bx,cl
    and bl,7
    movzx eax,byte ptr cs:[bx].fractab
    shl eax,14
    or ecx,eax
;
    cmp ecx,1
    jne get_bm_not1
;
    xor ecx,ecx

get_bm_not1:
    cmp ecx,4001h
    jne get_bm_not4001
;
    mov ecx,1

get_bm_not4001:        
    clc
;    
    pop edx
    pop bx
    pop eax    
    ret
Get232BmDivisor Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Get232HDivisor
;
;           description:    Get baud-rate divisor, 232H type
;
;           PARAMETERS:         DS      Port selector
;                           ECX         baudrate
;
;       RETURNS:    ECX     Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


Get232HDivisor Proc near
    push eax
    push bx
    push edx
;    
    xor edx,edx
    mov eax,8 * 120000000 / 10
    div ecx
    mov ecx,eax
    shr ecx,3
;
    movzx bx,cl
    and bl,7
    movzx eax,byte ptr cs:[bx].fractab
    shl eax,14
    or ecx,eax
;
    cmp ecx,1
    jne get_hm_not1
;
    xor ecx,ecx

get_hm_not1:
    cmp ecx,4001h
    jne get_hm_not4001
;
    mov ecx,1

get_hm_not4001:        
    or ecx,20000h
    clc
;    
    pop edx
    pop bx
    pop eax    
    ret
Get232HDivisor Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBaudDivisor
;
;           description:    Get baud-rate divisor
;
;           PARAMETERS:         DS      Port selector
;                           ECX         baudrate
;
;       RETURNS:    CX     Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BaudDivisorTab:
gbd00   DW OFFSET GetDivisorError
gbd01   DW OFFSET GetSioDivisor
gbd02   DW OFFSET Get232AmDivisor
gbd03   DW OFFSET Get232BmDivisor
gbd04   DW OFFSET Get232BmDivisor
gbd05   DW OFFSET Get232HDivisor
gbdend  DW OFFSET GetDivisorError

GetBaudDivisor  Proc near
    push bx
;    
    mov bx,ds:ups_device_type
    xor bh,bh
    add bx,bx
    add bx,OFFSET BaudDivisorTab
    cmp bx,OFFSET gbdend
    jbe gbdCall
;
    mov bx,OFFSET gbdend    

gbdCall:
    call word ptr cs:[bx]
;    
    pop bx
    ret
GetBaudDivisor  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResetSio
;
;           DESCRIPTION:    Reset SIO
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_sio       PROC near
    push es
    pushad
;
    call OpenDevHandle
    mov ah,40h
    xor al,al
    xor dx,dx
    mov si,ds:ups_index
    inc si
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
reset_sio Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetLatencyTimer
;
;           DESCRIPTION:    Set latency timer
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_latency_timer       PROC near
    push es
    pushad
;
    call OpenDevHandle
    mov ah,40h
    mov al,9
    mov dx,10
    mov si,ds:ups_index
    inc si
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
set_latency_timer Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetBaud
;
;           DESCRIPTION:    Set baudrate
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_baud    PROC near
    push es
    pushad
;
    call OpenDevHandle
    mov ah,40h
    mov al,3
    mov dx,word ptr ds:ups_divisor
;
    mov si,word ptr ds:ups_divisor+2   
    cmp ds:ups_device_type,DEVICE_TYPE_FT2232C
    je set_baud_index_shift
;
    cmp ds:ups_device_type,DEVICE_TYPE_FT4232H
    je set_baud_index_shift
;
    jmp set_baud_index_ok

set_baud_index_shift:
    shl si,8
    mov di,ds:ups_index
    inc di
    or si,di

set_baud_index_ok:
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
set_baud Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetData
;
;           DESCRIPTION:    Set data format
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_data    PROC near
    push es
    pushad
;
    mov al,ds:ups_data_bits
    mov ah,ds:ups_parity
;
    cmp ah,'E'
    je set_data_even
;
    cmp ah,'O'
    je set_data_odd

set_data_none:    
    xor ah,ah
    jmp set_data_parity_ok

set_data_even:
    mov ah,2
    jmp set_data_parity_ok

set_data_odd:
    mov ah,1

set_data_parity_ok:
    mov cl,ds:ups_stop_bits
    cmp cl,2
    jb set_data_stop_ok
;
    or ah,10h

set_data_stop_ok:
    mov dx,ax
;
    call OpenDevHandle
    mov ah,40h
    mov al,4
    mov si,ds:ups_index
    inc si
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
set_data Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitComFtdi
;
;           description:    Init serial port, FTDI version
;
;           PARAMETERS:         DS      Port selector
;                       ES          Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitComFtdi     Proc near
    push ds
    pushad
;    
    call reset_sio
    jc init_ftdi_done
;
    call set_latency_timer
    jc init_ftdi_done   
;    
    call set_data
    jc init_ftdi_done
;
    call set_baud
    jc init_ftdi_done
;    
    test ds:ups_control,CONTROL_DTR
    jz init_ftdi_reset_dtr
;
    call set_dtr_ftdi    
    jmp init_ftdi_dtr_ok

init_ftdi_reset_dtr:
    call reset_dtr_ftdi

init_ftdi_dtr_ok:    
    test ds:ups_control,CONTROL_RTS
    jz init_ftdi_reset_rts
;
    call set_rts_ftdi    
    jmp init_ftdi_rts_ok

init_ftdi_reset_rts:
    call reset_rts_ftdi

init_ftdi_rts_ok:
    test ds:ups_control,CONTROL_CTS
    jz init_ftdi_disable_cts
;
    call enable_cts_ftdi    
    jmp init_ftdi_cts_ok

init_ftdi_disable_cts:
    call disable_cts_ftdi

init_ftdi_cts_ok:

init_ftdi_done:
    popad
    pop ds
    ret
InitComFtdi     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           open_com_ftdi
;
;           description:    Open a serial port, FTDI version
;
;           PARAMETERS:         DS      Port selector
;                       ES          Device selector
;                           AH          # of data bits
;                           BL          # of stop bits
;                           BH          parity
;                           ECX         baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com_ftdi   Proc far
    push ds
    pushad
;
    mov ds:ups_data_bits,ah
    mov ds:ups_stop_bits,bl
    mov ds:ups_parity,bh
;    
    mov ax,es:uds_device_type
    mov ds:ups_device_type,ax
    call GetBaudDivisor
    jc open_ftdi_done
;
    mov ds:ups_divisor,ecx
    mov ds:ups_control,CONTROL_DTR OR CONTROL_RTS
    mov ds:ups_device_sel,es
;
     
    call InitComFtdi
    jc open_ftdi_done
;    
    mov dx,ds
    mov ax,es
    mov ds,ax
    EnterSection ds:uds_section
    mov ds:uds_port_sel,dx
    LeaveSection ds:uds_section       
;
    mov bx,ds:uds_thread
    Signal    
    clc

open_ftdi_done:
    popad
    pop ds
    retf32
open_com_ftdi   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           close_com_ftid
;
;           description:    Close serial port, FTDI version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com_ftdi  Proc far
    push ds
    push bx
;
    call reset_rts_ftdi
    call reset_dtr_ftdi
;    
    mov ax,ds
    mov bx,ds:ups_device_sel
    or bx,bx
    jz ccfNoDevice
;
    mov ds,bx    
    EnterSection ds:uds_section
    mov ds:uds_port_sel,0
    LeaveSection ds:uds_section       

ccfNoDevice:    
    mov bx,ds:uds_thread
    Signal    
;
    mov ax,150
    WaitMilliSec    
;
    pop bx
    pop ds    
    retf32
close_com_ftdi  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           full_duplex
;
;           DESCRIPTION:    Chkeck for full duplex
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

full_duplex PROC near
    stc
    retf32
full_duplex Endp  


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

send_break PROC near
    retf32
send_break Endp  
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           enable_cts_ftdi
;
;           DESCRIPTION:    Enable CTS signal, FTDI version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_cts_ftdi PROC near
    push es
    pushad
;
    or ds:ups_control,CONTROL_CTS
;
    call OpenDevHandle
    mov ah,40h
    mov al,2
    xor dx,dx
    mov si,ds:ups_index
    inc si
    or si,200h
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
enable_cts_ftdi Endp

far_enable_cts_ftdi Proc far
    call enable_cts_ftdi
    retf32
far_enable_cts_ftdi Endp  
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           disable_cts_ftdi
;
;           DESCRIPTION:    Disable CTS signal, FTDI version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_cts_ftdi    PROC near
    push es
    pushad
;
    and ds:ups_control,NOT CONTROL_CTS
;
    call OpenDevHandle
    mov ah,40h
    mov al,2
    xor dx,dx
    mov si,ds:ups_index
    inc si
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
disable_cts_ftdi Endp

far_disable_cts_ftdi    Proc far
    call disable_cts_ftdi
    retf32
far_disable_cts_ftdi    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_dtr_ftdi
;
;           description:    Set DTR signal, FTDI version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dtr_ftdi    Proc near
    push es
    pushad
;    
    or ds:ups_control,CONTROL_DTR
;
    call OpenDevHandle
    mov ah,40h
    mov al,1
    mov dx,101h
    mov si,ds:ups_index
    inc si
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
set_dtr_ftdi    Endp

far_set_dtr_ftdi    Proc far
    call set_dtr_ftdi
    retf32
far_set_dtr_ftdi    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reset_dtr_ftdi
;
;           description:    Reset DTR signal, FTDI version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_dtr_ftdi  Proc near
    push es
    pushad
;
    and ds:ups_control,NOT CONTROL_DTR
;
    call OpenDevHandle
    mov ah,40h
    mov al,1
    mov dx,100h
    mov si,ds:ups_index
    inc si
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
reset_dtr_ftdi  Endp

far_reset_dtr_ftdi  Proc far
    call reset_dtr_ftdi
    retf32
far_reset_dtr_ftdi  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_rts_ftdi
;
;           description:    Set RTS signal, FTDI version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rts_ftdi    Proc near
    push es
    pushad
;
    or ds:ups_control,CONTROL_RTS
;
    call OpenDevHandle
    mov ah,40h
    mov al,1
    mov dx,202h
    mov si,ds:ups_index
    inc si
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
set_rts_ftdi    Endp

far_set_rts_ftdi    Proc far
    call set_rts_ftdi
    retf32
far_set_rts_ftdi    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reset_rts_ftdi
;
;           description:    Reset RTS signal, FTDI version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_rts_ftdi  Proc near
    push es
    pushad
;
    and ds:ups_control,NOT CONTROL_RTS
;
    call OpenDevHandle
    mov ah,40h
    mov al,1
    mov dx,200h
    mov si,ds:ups_index
    inc si
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
reset_rts_ftdi  Endp

far_reset_rts_ftdi  Proc far
    call reset_rts_ftdi
    retf32
far_reset_rts_ftdi  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Fish
;
;           description:    Some cranky stuff in the PL device
;
;           PARAMETERS:         DS      Port selector
;               AX      Value
;               DX      Index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Fish    Proc near
    push es
    pushad
;
    push bp   
    push ax
    mov bp,sp
;
    mov si,dx
    mov dx,ax
    call OpenDevHandle
    mov ax,ss
    mov es,ax
    mov ah,0C0h
    mov al,1
    mov cx,1
    mov di,bp
    SendUsbDeviceControlMsg
    call CloseDevHandle
    pop ax
    pop bp
;
    popad
    pop es    
    ret
Fish    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLineState
;
;           description:    Read current line state
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadLineState   Proc near
    push es
    pushad
;
    call OpenDevHandle
    mov ax,ds
    mov es,ax
    mov ah,0A1h
    mov al,21h
    xor dx,dx
    xor si,si
    mov cx,7
    mov edi,OFFSET ups_pl_buf
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
ReadLineState    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateLineState
;
;           description:    Update current line state after open
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLineState Proc near
    push eax
;    
    mov eax,ds:ups_divisor
    mov dword ptr ds:ups_pl_buf,eax
;    
    mov al,ds:ups_stop_bits
    add al,al
    mov ds:ups_pl_buf+4,al
;
    mov al,ds:ups_parity
    cmp al,'E'
    je ulsEven
;
    cmp al,'O'
    je ulsOdd
;
    xor al,al
    jmp ulsParity

ulsEven:
    mov al,2
    jmp ulsParity

ulsOdd:
    mov al,1

ulsParity:
    mov ds:ups_pl_buf+5,al
;
    mov al,ds:ups_data_bits
    mov ds:ups_pl_buf+6,al    
;
    pop eax          
    ret
UpdateLineState Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLineState
;
;           description:    Write current line state
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteLineState  Proc near
    push es
    pushad
;
    call OpenDevHandle
    mov ax,ds
    mov es,ax
    mov ah,21h
    mov al,20h
    xor dx,dx
    xor si,si
    mov cx,7
    mov edi,OFFSET ups_pl_buf
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
WriteLineState    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteControl
;
;           description:    Write current control state
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteControl    Proc near
    push es
    pushad
;
    call OpenDevHandle
    mov ah,21h
    mov al,22h
    movzx dx,ds:ups_pl_control
    xor si,si
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
WriteControl    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Soup
;
;           description:    Some cranky stuff in the PL device
;
;           PARAMETERS:         DS      Port selector
;               AX      Value
;               DX      Index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Soup    Proc near
    push es
    pushad
;
    mov si,dx
    mov dx,ax
    call OpenDevHandle
    mov ah,40h
    mov al,1
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
Soup    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitComPl
;
;           description:    Init a serial port, PL2303 version
;
;           PARAMETERS:         DS      Port selector
;                       ES          Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitComPl       Proc near
    push ds
    pushad
;    
    xor dx,dx
    mov ax,8484h
    call Fish
;    
    xor dx,dx
    mov ax,404h
    call Soup
;    
    xor dx,dx
    mov ax,8484h
    call Fish
;    
    xor dx,dx
    mov ax,8383h
    call Fish
;    
    xor dx,dx
    mov ax,8484h
    call Fish
;    
    mov dx,1
    mov ax,404h
    call Soup
;    
    xor dx,dx
    mov ax,8484h
    call Fish
;    
    xor dx,dx
    mov ax,8383h
    call Fish
;    
    mov dx,1
    mov ax,0
    call Soup
;    
    mov dx,0
    mov ax,1
    call Soup
;    
    mov ax,ds:ups_device_type
    cmp ax,DEVICE_TYPE_PL_HX
    je ocpHx

ocp01:
    mov dx,24h
    mov ax,2
    call Soup
    jmp ocpInitDone

ocpHx:
    mov dx,44h
    mov ax,2
    call Soup
;
    mov dx,0
    mov ax,8
    call Soup
;
    mov dx,0
    mov ax,9
    call Soup

ocpInitDone:    
    call ReadLineState
    call UpdateLineState
    call WriteLineState
;
    mov ds:ups_pl_control,0
    call WriteControl
;    
    call ReadLineState    
;    
    test ds:ups_control,CONTROL_DTR
    jz init_pl_reset_dtr
;
    call set_dtr_pl    
    jmp init_pl_dtr_ok

init_pl_reset_dtr:
    call reset_dtr_pl

init_pl_dtr_ok:    
    test ds:ups_control,CONTROL_RTS
    jz init_pl_reset_rts
;
    call set_rts_pl    
    jmp init_pl_rts_ok

init_pl_reset_rts:
    call reset_rts_pl

init_pl_rts_ok:
    test ds:ups_control,CONTROL_CTS
    jz init_pl_disable_cts
;
    call enable_cts_pl    
    jmp init_pl_cts_ok

init_pl_disable_cts:
    call disable_cts_pl

init_pl_cts_ok:
    popad
    pop ds
    ret
InitComPl Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           open_com_pl
;
;           description:    Open a serial port, PL2303 version
;
;           PARAMETERS:         DS      Port selector
;                       ES          Device selector
;                           AH          # of data bits
;                           BL          # of stop bits
;                           BH          parity
;                           ECX         baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com_pl     Proc far
    push ds
    pushad
;
    mov ds:ups_data_bits,ah
    mov ds:ups_stop_bits,bl
    mov ds:ups_parity,bh
    mov ds:ups_divisor,ecx
    mov ds:ups_control,CONTROL_DTR OR CONTROL_RTS
    mov ds:ups_device_sel,es
;
    mov ax,es:uds_device_type
    mov ds:ups_device_type,ax
;
    call InitComPl
;    
    mov dx,ds
    mov ax,es
    mov ds,ax
    EnterSection ds:uds_section
    mov ds:uds_port_sel,dx
    LeaveSection ds:uds_section       
;
    mov bx,ds:uds_thread
    Signal    
    clc

open_pl_done:
    popad
    pop ds
    retf32
open_com_pl Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           close_com_pl
;
;           description:    Close serial port, PL2303 version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com_pl    Proc far
    push ds
    push bx
;
    call reset_rts_pl
    call reset_dtr_pl
;    
    mov ax,ds
    mov bx,ds:ups_device_sel
    or bx,bx
    jz ccpNoDevice
;
    mov ds,bx    
    EnterSection ds:uds_section
    mov ds:uds_port_sel,0
    LeaveSection ds:uds_section       

ccpNoDevice:    
    mov bx,ds:uds_thread
    Signal    
;
    mov ax,150
    WaitMilliSec    
;
    pop bx
    pop ds    
    retf32
close_com_pl    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           enable_cts_pl
;
;           DESCRIPTION:    Enable CTS signal, PL2303 version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_cts_pl   PROC near
    push es
    pushad
;
    or ds:ups_control,CONTROL_CTS
;
    call OpenDevHandle
    mov ah,40h
    mov al,1
    mov si,61h
    mov di,ds:ups_device_type
    cmp di,DEVICE_TYPE_PL_HX
    je ecpIndexOk
;
    mov si,41h

ecpIndexOk:    
    xor dx,dx
    xor cx,cx
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    popad
    pop es    
    ret
enable_cts_pl Endp

far_enable_cts_pl   Proc far
    call enable_cts_pl
    retf32
far_enable_cts_pl   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           disable_cts_pl
;
;           DESCRIPTION:    Disable CTS signal, PL2303 version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_cts_pl  PROC near
    and ds:ups_control,NOT CONTROL_CTS
    ret
disable_cts_pl Endp

far_disable_cts_pl  PROC far
    and ds:ups_control,NOT CONTROL_CTS
    retf32
far_disable_cts_pl Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_dtr_pl
;
;           description:    Set DTR signal, PL2303 version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dtr_pl      Proc near
    or ds:ups_control,CONTROL_DTR
    or ds:ups_pl_control,1
    call WriteControl
    ret
set_dtr_pl      Endp


far_set_dtr_pl      Proc far
    or ds:ups_control,CONTROL_DTR
    or ds:ups_pl_control,1
    call WriteControl
    retf32
far_set_dtr_pl      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reset_dtr_pl
;
;           description:    Reset DTR signal, PL2303 version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_dtr_pl    Proc near
    and ds:ups_control,NOT CONTROL_DTR
    and ds:ups_pl_control,NOT 1
    call WriteControl
    ret
reset_dtr_pl    Endp

far_reset_dtr_pl    Proc far
    and ds:ups_control,NOT CONTROL_DTR
    and ds:ups_pl_control,NOT 1
    call WriteControl
    retf32
far_reset_dtr_pl    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_rts_pl
;
;           description:    Set RTS signal, PL2303 version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rts_pl      Proc near
    or ds:ups_control,CONTROL_RTS
    or ds:ups_pl_control,2
    call WriteControl
    ret
set_rts_pl      Endp

far_set_rts_pl      Proc far
    or ds:ups_control,CONTROL_RTS
    or ds:ups_pl_control,2
    call WriteControl
    retf32
far_set_rts_pl      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reset_rts_pl
;
;           description:    Reset RTS signal, PL2303 version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_rts_pl    Proc near
    and ds:ups_control,NOT CONTROL_RTS
    and ds:ups_pl_control,NOT 2
    call WriteControl
    ret
reset_rts_pl    Endp

far_reset_rts_pl    Proc far
    and ds:ups_control,NOT CONTROL_RTS
    and ds:ups_pl_control,NOT 2
    call WriteControl
    retf32
far_reset_rts_pl    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       GetFixedMctDivisor
;
;           description:    Get divisor for fixed MCT rates
;
;           PARAMETERS:         ECX     Baudrate
;
;       RETURNS:    ECX     Divisor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFixedMctDivisor      Proc near
    cmp ecx,300
    jne gfmdNot300
;
    mov ecx,1
    jmp gfmdDone

gfmdNot300:
    cmp ecx,600
    jne gfmdNot600
;
    mov ecx,2
    jmp gfmdDone

gfmdNot600:
    cmp ecx,1200
    jne gfmdNot1200
;
    mov ecx,3
    jmp gfmdDone

gfmdNot1200:
    cmp ecx,2400
    jne gfmdNot2400
;
    mov ecx,4
    jmp gfmdDone

gfmdNot2400:
    cmp ecx,4800
    jne gfmdNot4800
;
    mov ecx,6
    jmp gfmdDone

gfmdNot4800:
    cmp ecx,9600
    jne gfmdNot9600
;
    mov ecx,8
    jmp gfmdDone

gfmdNot9600:
    cmp ecx,19200
    jne gfmdNot19200
;
    mov ecx,9
    jmp gfmdDone

gfmdNot19200:
    cmp ecx,38400
    jne gfmdNot38400
;
    mov ecx,10
    jmp gfmdDone

gfmdNot38400:
    cmp ecx,57600
    jne gfmdNot57600
;
    mov ecx,11
    jmp gfmdDone

gfmdNot57600:
    cmp ecx,115200
    jne gfmdNot115200
;
    mov ecx,12
    jmp gfmdDone

gfmdNot115200:
    mov ecx,8

gfmdDone:           
    ret
GetFixedMctDivisor  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       GetVariableMctDivisor
;
;           description:    Get divisor for variable MCT rates
;
;           PARAMETERS:         ECX     Baudrate
;
;       RETURNS:    ECX     Divisor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetVariableMctDivisor   Proc near
    push eax
    push edx
;
    xor edx,edx
    mov eax,115200
    div ecx
    mov ecx,eax
;
    pop edx
    pop eax        
    ret
GetVariableMctDivisor   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetBaudMct
;
;           DESCRIPTION:    Set baudrate, MCT version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetBaudMct      PROC near
    push es
    pushad
;
    push bp   
    mov eax,ds:ups_divisor
    push eax    
    mov bp,sp
;
    call OpenDevHandle
    mov ax,ss
    mov es,ax
    mov di,bp
    mov ah,40h
    mov al,5
    xor dx,dx
    xor si,si
    mov cx,4
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    pop eax
    pop bp
    popad
    pop es    
    ret
SetBaudMct Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       SendUnknownMct
;
;           description:    Send unknown message #1, MCT version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendUnknownMct  Proc near
    push es
    pushad
;
    push bp   
    xor ax,ax
    push ax    
    mov bp,sp
;
    call OpenDevHandle
    mov ax,ss
    mov es,ax
    mov di,bp
    mov ah,40h
    mov al,0Bh
    xor dx,dx
    xor si,si
    mov cx,1
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    pop ax
    pop bp
    popad
    pop es    
    ret
SendUnknownMct    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       SendCtsMct
;
;           description:    Send CTS control, MCT version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCtsMct      Proc near
    push es
    pushad
;
    push bp   
    xor ax,ax
    test ds:ups_control,CONTROL_CTS
    jz scmValOk
;
    mov al,1

scmValOk:
    push ax    
    mov bp,sp
;
    call OpenDevHandle
    mov ax,ss
    mov es,ax
    mov di,bp
    mov ah,40h
    mov al,0Ch
    xor dx,dx
    xor si,si
    mov cx,1
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    pop ax
    pop bp
    popad
    pop es    
    ret
SendCtsMct    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       SetLineControl
;
;           description:    Set line control register
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetLineControl  Proc near
    push es
    pushad
;
    push bp  
;    
    mov al,ds:ups_data_bits
    sub al,5
    and al,3
;
    mov ah,ds:ups_stop_bits
    dec ah
    and ah,1
    shl ah,2
    or al,ah
;
    mov ah,ds:ups_parity 
    cmp ah,'E'
    je slcEven
;       
    cmp ah,'O'
    je slcOdd
;
    jmp slcParityOk

slcEven:
    or al,18h
    jmp slcParityOk

slcOdd:
    or al,8

slcParityOk:
    push ax    
    mov bp,sp
;
    call OpenDevHandle
    mov ax,ss
    mov es,ax
    mov di,bp
    mov ah,40h
    mov al,7
    xor dx,dx
    xor si,si
    mov cx,1
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    pop ax
    pop bp
    popad
    pop es    
    ret
SetLineControl    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       WriteModemControl
;
;           description:    Write modem control register
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteModemControl       Proc near
    push es
    pushad
;
    push bp   
    mov ax,8
    test ds:ups_control,CONTROL_RTS
    jz rmcRtsOk
;
    or al,2

rmcRtsOk:
    test ds:ups_control,CONTROL_DTR
    jz rmcDtrOk
;
    or al,1

rmcDtrOk:    
    push ax    
    mov bp,sp
;
    call OpenDevHandle
    mov ax,ss
    mov es,ax
    mov di,bp
    mov ah,40h
    mov al,0Ah
    xor dx,dx
    xor si,si
    mov cx,1
    SendUsbDeviceControlMsg
    call CloseDevHandle
;
    pop ax
    pop bp
    popad
    pop es    
    ret
WriteModemControl    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitComMct
;
;           description:    Init a serial port, MCT version
;
;           PARAMETERS:         DS      Port selector
;                       ES          Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitComMct      Proc near
    push ds
    pushad
;
    call SetBaudMct
    call SendUnknownMct
    call SendCtsMct
    call SetLineControl
    call WriteModemControl
;
    popad
    pop ds
    ret
InitComMct Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           open_com_mct
;
;           description:    Open a serial port, MCT version
;
;           PARAMETERS:         DS      Port selector
;                       ES          Device selector
;                           AH          # of data bits
;                           BL          # of stop bits
;                           BH          parity
;                           ECX         baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com_mct    Proc far
    push ds
    pushad
;
    mov ds:ups_data_bits,ah
    mov ds:ups_stop_bits,bl
    mov ds:ups_parity,bh
;
    mov ax,es:uds_device_type
    mov ds:ups_device_type,ax
    cmp ax,DEVICE_TYPE_MCT_SITECOM
    je icmFixed
;
    cmp ax,DEVICE_TYPE_MCT_BELKIN
    je icmFixed
;
    call GetVariableMctDivisor
    jmp icmDivisorOk

icmFixed:
    call GetFixedMctDivisor

icmDivisorOk:  
    mov ds:ups_divisor,ecx
    mov ds:ups_control,CONTROL_DTR OR CONTROL_RTS
    mov ds:ups_device_sel,es
;
    call InitComMct
;    
    mov dx,ds
    mov ax,es
    mov ds,ax
    EnterSection ds:uds_section
    mov ds:uds_port_sel,dx
    LeaveSection ds:uds_section       
;
    mov bx,ds:uds_thread
    Signal    
    clc
;
    popad
    pop ds
    retf32
open_com_mct Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           close_com_mct
;
;           description:    Close serial port, MCT version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com_mct   Proc far
    push ds
    push bx
;
    int 3
;
    pop bx
    pop ds    
    retf32
close_com_mct   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           enable_cts_mct
;
;           DESCRIPTION:    Enable CTS signal, MCT version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_cts_mct  PROC near
    push es
    pushad
;
    or ds:ups_control,CONTROL_CTS
    call SetBaudMct
    call SendUnknownMct
    call SendCtsMct
    call SetLineControl
;
    popad
    pop es    
    ret
enable_cts_mct Endp

far_enable_cts_mct  Proc far
    call enable_cts_mct
    retf32
far_enable_cts_mct  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           disable_cts_mct
;
;           DESCRIPTION:    Disable CTS signal, MCT version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_cts_mct PROC near
    push es
    pushad
;
    and ds:ups_control,NOT CONTROL_CTS
    call SetBaudMct
    call SendUnknownMct
    call SendCtsMct
    call SetLineControl
;
    popad
    pop es    
    ret
disable_cts_mct Endp

far_disable_cts_mct Proc far
    call disable_cts_mct
    retf32
far_disable_cts_mct Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_dtr_mct
;
;           description:    Set DTR signal, MCT version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dtr_mct     Proc near
    or ds:ups_control,CONTROL_DTR
    call WriteModemControl
    ret
set_dtr_mct     Endp

far_set_dtr_mct Proc far
    or ds:ups_control,CONTROL_DTR
    call WriteModemControl
    retf32
far_set_dtr_mct Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reset_dtr_mct
;
;           description:    Reset DTR signal, MCT version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_dtr_mct   Proc near
    and ds:ups_control,NOT CONTROL_DTR
    call WriteModemControl
    ret
reset_dtr_mct   Endp

far_reset_dtr_mct   Proc far
    and ds:ups_control,NOT CONTROL_DTR
    call WriteModemControl
    retf32
far_reset_dtr_mct   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_rts_mct
;
;           description:    Set RTS signal, MCT version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rts_mct     Proc near
    or ds:ups_control,CONTROL_RTS
    call WriteModemControl
    ret
set_rts_mct     Endp

far_set_rts_mct     Proc far
    or ds:ups_control,CONTROL_RTS
    call WriteModemControl
    retf32
far_set_rts_mct     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reset_rts_mct
;
;           description:    Reset RTS signal, MCT version
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_rts_mct   Proc near
    and ds:ups_control,NOT CONTROL_RTS
    call WriteModemControl
    ret
reset_rts_mct   Endp

far_reset_rts_mct   Proc far
    and ds:ups_control,NOT CONTROL_RTS
    call WriteModemControl
    retf32
far_reset_rts_mct   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           EnableAutoRts
;
;           DESCRIPTION:    Enable automatic RTS on send
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_auto_rts PROC far
    or ds:ups_control,CONTROL_AUTO_RTS
    retf32
enable_auto_rts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DisableAutoRts
;
;           DESCRIPTION:    Disable automatic RTS on send
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_auto_rts    PROC far
    and ds:ups_control,NOT CONTROL_AUTO_RTS
    retf32
disable_auto_rts Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsAutoRtsOn
;
;           DESCRIPTION:    Check for automatic RTS on send
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_auto_rts_on    PROC far
    test ds:ups_control,CONTROL_AUTO_RTS
    jz iarOff

iarOn:
    clc
    retf32

iarOff:
    stc
    retf32
is_auto_rts_on Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FlushCom
;
;           DESCRIPTION:    Flush com
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_com       PROC far
    retf32
flush_com Endp
    
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
    push ax
    push cx
    push di
;
    call OpenDevHandle
    ResetUsbDevice
    call CloseDevHandle
;
    pop di
    pop cx
    pop ax
    pop es
    pop ds
    retf32
reset_port Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           start_send
;
;           description:    Start send
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_send      PROC far
    push es
    push ax
;    
    mov ax,ds:ups_device_sel
    or ax,ax
    jz ssDone
;    
    mov es,ax
    test es:uds_flags,FLAG_UDS_DISCONNECT
    jz ssDone
;
    mov ds:send_count,0
    mov ds:send_head,0
    mov ds:send_tail,0

ssDone:
    mov bx,es:uds_thread
    Signal    
;
    pop ax
    pop es    
    retf32
start_send      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       CreatePortFtdi
;
;           description:    Create port selector
;
;           RETURNS:        ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ftdi_port_tab:
fpt00 DD OFFSET open_com_ftdi,          SEG code
fpt01 DD OFFSET close_com_ftdi,     SEG code
fpt02 DD OFFSET far_enable_cts_ftdi,    SEG code
fpt03 DD OFFSET far_disable_cts_ftdi,       SEG code
fpt04 DD OFFSET far_set_dtr_ftdi,       SEG code
fpt05 DD OFFSET far_reset_dtr_ftdi,     SEG code
fpt06 DD OFFSET far_set_rts_ftdi,       SEG code
fpt07 DD OFFSET far_reset_rts_ftdi,     SEG code
fpt08 DD OFFSET enable_auto_rts,    SEG code
fpt09 DD OFFSET disable_auto_rts,       SEG code
fpt10 DD OFFSET flush_com,          SEG code
fpt11 DD OFFSET start_send,         SEG code
fpt12 DD OFFSET reset_port,         SEG code
fpt13 DD OFFSET full_duplex,        SEG code
fpt14 DD OFFSET is_auto_rts_on,         SEG code
fpt15 DD OFFSET send_break,         SEG code

CreatePortFtdi  Proc far
    pushad
;
    mov eax,SIZE usbcom_port_struc
    AllocateSmallGlobalMem
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov si,OFFSET ftdi_port_tab
    xor di,di
    mov cx,2 * 16
    rep movs dword ptr es:[di],cs:[si]
;
    movzx ax,ds:uds_interface
    mov es:ups_index,ax    
;    
    popad
    retf32
CreatePortFtdi  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       CreatePortPl2303
;
;           description:    Create port selector
;
;           RETURNS:        ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pl2303_port_tab:
ppt00 DD OFFSET open_com_pl,     SEG code
ppt01 DD OFFSET close_com_pl,    SEG code
ppt02 DD OFFSET far_enable_cts_pl,       SEG code
ppt03 DD OFFSET far_disable_cts_pl,      SEG code
ppt04 DD OFFSET far_set_dtr_pl,      SEG code
ppt05 DD OFFSET far_reset_dtr_pl,    SEG code
ppt06 DD OFFSET far_set_rts_pl,      SEG code
ppt07 DD OFFSET far_reset_rts_pl,    SEG code
ppt08 DD OFFSET enable_auto_rts,     SEG code
ppt09 DD OFFSET disable_auto_rts,    SEG code
ppt10 DD OFFSET flush_com,       SEG code
ppt11 DD OFFSET start_send,      SEG code
ppt12 DD OFFSET reset_port,      SEG code
ppt13 DD OFFSET full_duplex,     SEG code
ppt14 DD OFFSET is_auto_rts_on,     SEG code
ppt15 DD OFFSET send_break,     SEG code

CreatePortPl2303    Proc far
    pushad
;
    mov eax,SIZE usbcom_port_struc
    AllocateSmallGlobalMem
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov si,OFFSET pl2303_port_tab
    xor di,di
    mov cx,2 * 16
    rep movs dword ptr es:[di],cs:[si]
;
    movzx ax,ds:uds_interface
    mov es:ups_index,ax    
;    
    popad
    retf32
CreatePortPl2303    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       CreatePortMct
;
;           description:    Create port selector
;
;           RETURNS:        ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mct_port_tab:
mct00 DD OFFSET open_com_mct,           SEG code
mct01 DD OFFSET close_com_mct,      SEG code
mct02 DD OFFSET enable_cts_mct,     SEG code
mct03 DD OFFSET disable_cts_mct,    SEG code
mct04 DD OFFSET far_set_dtr_mct,        SEG code
mct05 DD OFFSET far_reset_dtr_mct,      SEG code
mct06 DD OFFSET far_set_rts_mct,        SEG code
mct07 DD OFFSET far_reset_rts_mct,      SEG code
mct08 DD OFFSET enable_auto_rts,    SEG code
mct09 DD OFFSET disable_auto_rts,       SEG code
mct10 DD OFFSET flush_com,          SEG code
mct11 DD OFFSET start_send,         SEG code
mct12 DD OFFSET reset_port,         SEG code
mct13 DD OFFSET full_duplex,        SEG code
mct14 DD OFFSET is_auto_rts_on,        SEG code
mct15 DD OFFSET send_break,         SEG code

CreatePortMct   Proc far
    pushad
;
    mov eax,SIZE usbcom_port_struc
    AllocateSmallGlobalMem
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov si,OFFSET mct_port_tab
    xor di,di
    mov cx,2 * 16
    rep movs dword ptr es:[di],cs:[si]
;
    movzx ax,ds:uds_interface
    mov es:ups_index,ax    
;    
    popad
    retf32
CreatePortMct   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenPort
;
;           DESCRIPTION:    Open port
;
;       PARAMETERS:     FS      SEG data
;               DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPort    Proc near
    push es
    movzx eax,ds:uds_in_size
    AllocateSmallGlobalMem
    mov ds:uds_in_buffer,es
    pop es
;
    mov bx,es:uc_dev_handle
    mov dl,ds:uds_bulk_in
    mov cx,10
    mov ax,2
    OpenUsbPacketPipe
;
    push es
    mov bx,es:uc_dev_handle
    mov dl,ds:uds_bulk_out
    mov cx,ds:uds_out_size
    shl cx,2
    mov ax,5
    OpenUsbRawPipe
    mov ds:uds_out_buffer,es
    pop es
;
    CreateWait
    mov ds:uds_wait,bx
;
    mov ax,es:uc_dev_handle
    mov dl,ds:uds_bulk_in
    mov ecx,ds
    AddWaitForUsbDevicePipe
;
    mov dl,ds:uds_intr_in
    mov ds:uds_intr_buffer,0
    or dl,dl
    jz opDone
;
    push es
    movzx eax,ds:uds_in_size
    AllocateSmallGlobalMem
    mov ds:uds_intr_buffer,es
    pop es
;
    mov bx,es:uc_dev_handle
    mov dl,ds:uds_intr_in
    mov cx,10
    mov ax,2
    OpenUsbPacketPipe
;
    mov bx,ds:uds_wait
    mov ax,es:uc_dev_handle
    mov dl,ds:uds_intr_in
    mov ecx,ds
    AddWaitForUsbDevicePipe

opDone:        
    ret
OpenPort    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClosePort
;
;           DESCRIPTION:    Close port
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePort    Proc near
    mov ax,50
    WaitMilliSec
;
    mov bx,es:uc_dev_handle
    mov dl,ds:uds_bulk_in
    CloseUsbPipe
;
    mov bx,es:uc_dev_handle
    mov dl,ds:uds_bulk_out
    CloseUsbPipe
;    
    push es
    mov es,ds:uds_in_buffer
    FreeMem
    pop es
;
    mov bx,ds:uds_wait
    CloseWait
;
    mov dl,ds:uds_intr_in
    or dl,dl
    jz cpDone
;
    mov bx,es:uc_dev_handle
    CloseUsbPipe
;    
    push es
    mov es,ds:uds_intr_buffer
    FreeMem
    pop es

cpDone:
    mov ds:uds_in_buffer,0
    mov ds:uds_out_buffer,0
    mov ds:uds_intr_buffer,0
    mov ds:uds_wait,0
    ret
ClosePort   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReInit
;
;           DESCRIPTION:    Reinit port
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitError   Proc near
    ret
InitError   Endp

reinit_port_tab:
rpt00 DW OFFSET InitError
rpt01 DW OFFSET InitComFtdi
rpt02 DW OFFSET InitComPl

ReInit    Proc near
    push ds
    push es
    push cx
    push di
;    
    mov ax,ds
    mov es,ax
    mov ds,es:uds_port_sel
;
    mov cx,es:uds_device_type
    movzx di,ch
    add di,di
    call word ptr cs:[di].reinit_port_tab    
;
    pop di
    pop cx
    pop es
    pop ds
    ret
ReInit  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleRead
;
;       DESCRIPTION:    Handle read
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleRead    Proc near
    push ds
    push es
    push fs
    pushad
;
    mov es,ds:uds_in_buffer
    xor edi,edi
    movzx ecx,ds:uds_in_size
    GetUsbPacketPipe
    jc hdrDone
;    
    mov ax,ds:uds_device_type
    xor al,al
    xor si,si
    cmp ax,DEVICE_TYPE_PL2303
    je hdrDo
;
    mov si,2
    sub cx,2
    jbe hdrDone

hdrDo:
    or cx,cx
    jz hdrDone
;
    mov fs,ds:uds_in_buffer
    mov ax,ds:uds_port_sel
    or ax,ax
    jz hdrDone
;
    mov ds,ax
    mov es,ds:rec_buf

hdrGetLoop:
    lods byte ptr fs:[si]
    RequestSpinlock ds:com_spinlock
    mov dx,ds:rec_count
    cmp dx,ds:rec_size
    je hdrSignal
;       
    inc dx
    mov ds:rec_count,dx
    mov bx,ds:rec_tail
    mov es:[bx],al
    inc bx
    cmp bx,ds:rec_size
    jnz hdrWrapOk
;
    xor bx,bx
    
hdrWrapOk:
    mov ds:rec_tail,bx
    ReleaseSpinlock ds:com_spinlock
    loop hdrGetLoop
    jmp hdrSigRel

hdrSignal:
    ReleaseSpinlock ds:com_spinlock

hdrSigRel:
    xor bx,bx
    xchg bx,ds:avail_obj
    or bx,bx
    jz hdrDone
;
    mov es,bx
    SignalWait
    
hdrDone:
    popad
    pop fs
    pop es
    pop ds
    ret
HandleRead    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckRead
;
;       DESCRIPTION:    Check read buffer
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckRead    Proc near
    push bx
    push cx
    push dx
;
    mov bx,es:uc_dev_handle
    mov dl,ds:uds_bulk_in
    GetUsedUsbBuffers
    or cx,cx
    jz crDone
;
    call HandleRead

crDone:
    pop dx
    pop cx
    pop bx
    ret
CheckRead  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleWrite
;
;       DESCRIPTION:    Handle output-buffer
;
;       PARAMETERS:     DS      Function sel
;                       GS      Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleWrite    Proc near
    push fs
    pushad
;
    push es
;
    mov bp,ds:uds_out_size
    shl bp,2
    mov es,ds:uds_out_buffer
    xor di,di
    mov fs,gs:send_buf
;
    cmp ds:uds_device_type,DEVICE_TYPE_SIO
    jne pwLoop
;
    mov di,1

pwLoop:
    RequestSpinlock gs:com_spinlock
    mov dx,gs:send_count
    or dx,dx
    jz pwNoMore
;       
    dec dx
    mov gs:send_count,dx
    mov bx,gs:send_head
    mov al,fs:[bx]
    stosb
    inc bx
    cmp bx,gs:send_size
    jnz pwWrapOk
;       
    xor bx,bx

pwWrapOk:
    mov gs:send_head,bx
    ReleaseSpinlock gs:com_spinlock
;    
    cmp di,bp
    jb pwLoop
    jmp pwDoSend

pwNoMore:
    ReleaseSpinlock gs:com_spinlock
;
    mov cx,5

pwWaitLoop:
    call CheckRead
;
    mov ax,2
    WaitMilliSec
;
    loop pwWaitLoop
;
    mov dx,gs:send_count
    or dx,dx
    jnz pwLoop

pwDoSend:
    mov cx,di
;
    cmp ds:uds_device_type,DEVICE_TYPE_SIO
    jne pwSend
;
    mov al,cl
    shl al,2
    or al,1
    mov es:[0],al    
    inc cx

pwSend:
    pop es
;
    mov bx,es:uc_dev_handle
    mov dl,ds:uds_bulk_out
    PostUsbRawPipe
;
    push ds
    mov ds,ds:uds_port_sel
    mov bx,ds:send_wait
    pop ds
    or bx,bx
    jz pwSignalOk
;    
    Signal

pwSignalOk:
    popad
    pop fs
    ret
HandleWrite   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckWrite
;
;       DESCRIPTION:    Check output-buffer
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckWrite    Proc near
    push gs
    push dx
;
    mov dx,ds:uds_port_sel
    or dx,dx
    jz cwDone
;
    mov gs,dx
    mov dx,gs:send_count
    or dx,dx
    jz cwDone
;       
    call HandleWrite

cwDone:
    pop dx
    pop gs
    ret
CheckWrite  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           UsbComThread
;
;   DESCRIPTION:    Com-port handler thread
;
;   PARAMETERS:     BX      Device sel
;                   DL      Unit       
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_com_recreate:
    mov es,bx
    mov es:uc_detach,0
;
    movzx si,dl
    add si,si
    mov ax,es:[si].uc_unit_arr
    or ax,ax
    jz tEnd
;
    mov ds,ax
    mov ds:uds_flags,FLAG_UDS_REINIT
;
    GetThread
    mov ds:uds_thread,ax
    jmp tLoop

usb_com_create:
    mov es,bx
    mov es:uc_detach,0
;
    movzx si,dl
    add si,si
    mov ax,es:[si].uc_unit_arr
    or ax,ax
    jz tEnd
;
    mov ds,ax
    GetThread
    mov ds:uds_thread,ax

tLoop:
    mov ax,ds:uds_port_sel
    or ax,ax
    jz tClose

tOpen:
    mov bx,es:uc_dev_handle
    IsUsbDeviceConnected
    jc tExit
;
    test ds:uds_flags,FLAG_UDS_DISCONNECT
    jnz tExit
;
    test ds:uds_flags,FLAG_UDS_REINIT
    jz tInitOk
;
    EnterSection ds:uds_section
    call ReInit
    LeaveSection ds:uds_section
;
    and ds:uds_flags,NOT FLAG_UDS_REINIT

tInitOk:
    mov bx,ds:uds_in_buffer
    or bx,bx
    jnz tIsOpen
;
    EnterSection ds:uds_section
    call OpenPort    
    LeaveSection ds:uds_section

tIsOpen:
    mov bx,ds:uds_wait
    WaitWithoutTimeout
;
    mov bx,es:uc_dev_handle
    IsUsbDeviceConnected
    jc tExit
;
    test ds:uds_flags,FLAG_UDS_DISCONNECT
    jnz tExit
;
    EnterSection ds:uds_section
    call CheckWrite
    call CheckRead
    LeaveSection ds:uds_section
    jmp tLoop

tClose:
    and ds:uds_flags,NOT FLAG_UDS_REINIT
;
    mov bx,ds:uds_in_buffer
    or bx,bx
    jz tIsClosed
;
    EnterSection ds:uds_section
    call ClosePort
    LeaveSection ds:uds_section

tIsClosed:
    WaitForSignal
;
    mov bx,es:uc_dev_handle
    IsUsbDeviceConnected
    jc tExit
;
    test ds:uds_flags,FLAG_UDS_DISCONNECT
    jz tLoop

tExit:
    EnterSection ds:uds_section
    call ClosePort
;
    mov ax,ds:uds_port_sel
    or ax,ax
    jz tLeave
;
    push es
    mov es,ax
    mov es:send_count,0
    mov es:send_head,0
    mov es:send_tail,0
    pop es

tLeave:
    LeaveSection ds:uds_section
;
    mov ds:uds_thread,0
    mov bx,es:uc_detach
    Signal

tEnd:
    mov ax,200
    WaitMilliSec
    TerminateThread


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AddPort
;
;   DESCRIPTION:    Add port to list of available ports
;
;   PARAMETERS:     AL      Port #
;                   AH      Unit #
;                   BX      Controller id
;                   DX      Device type
;                   ES      Device sel
;
;   RETURNS:        DS      Unit sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePortError Proc far
    stc
    retf32
CreatePortError Endp

create_port_tab:
cpt00 DD OFFSET CreatePortError
cpt01 DD OFFSET CreatePortFtdi
cpt02 DD OFFSET CreatePortPl2303
cpt03 DD OFFSET CreatePortMct

AddPort Proc near
    push es
    pushad
;
    push dx
    push di
    push bx
    xor bx,bx
    xor bp,bp
    xor dx,dx
    xor si,si
    movzx cx,es:[di].uid_len
    add di,cx

apDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne apDescrDone
;
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,3
    je apDescrIntr
;    
    cmp cl,2
    jne apDescrNext
;
    mov cl,es:[di].ued_address
    test cl,80h    
    jnz apBulkIn

apDescrBulkOut:
    and cl,0Fh
    mov dl,cl
    mov bx,es:[di].ued_maxsize
    jmp apDescrNext

apDescrIntr:
    mov cl,es:[di].ued_address
    or bp,bp
    jz apIntrGetSize
;
    or si,si
    jz apIntrGetIntr
;
    cmp bp,2
    je apBulkIn
;
    push cx
    mov cx,si
    mov dh,cl
    pop cx
    jmp apIntrGetIntr

apIntrGetSize:
    mov bp,es:[di].ued_maxsize

apIntrGetIntr:    
    and cl,8Fh
    mov ch,es:[di].ued_interval
    mov si,cx
    jmp apDescrNext

apBulkIn:
    and cl,8Fh
    mov dh,cl
    mov bp,es:[di].ued_maxsize
    
apDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    mov cx,OFFSET uc_dev_descr_buf
    add cx,es:uc_dev_descr_size
    cmp di,cx
    jb apDescrLoop    
    
apDescrDone:
    shl ebp,16
    mov bp,bx    
    pop bx
;    
    mov cx,dx
    pop di
    pop dx
;    
    or cl,cl
    jz apDone
;
    or ch,ch
    jz apDone
;
    push cx
    mov cl,es:[di].uid_id
    push ax
    mov eax,SIZE usbcom_device_struc
    AllocateSmallGlobalMem
    pop ax
    mov es:uds_interface,cl
    mov es:uds_device_type,dx
    pop dx
    mov es:uds_port_sel,0
    mov es:uds_bulk_in,dh
    mov es:uds_bulk_out,dl
    mov es:uds_flags,0
;
    mov dx,si
    mov es:uds_intr_in,dl
    mov es:uds_intr_interval,dh
;       
    mov es:uds_out_size,bp
    shr ebp,16
    mov es:uds_in_size,bp
    mov es:uds_in_buffer,0
    mov es:uds_out_buffer,0
    mov es:uds_intr_buffer,0
    InitSection es:uds_section
;
    mov si,SEG data
    mov ds,si
    mov si,ds:sd_ports
    add si,si
    mov ds:[si].sd_port_arr,es
    inc ds:sd_ports
    mov es:uds_port_offset,si
;
    mov cx,es:uds_device_type
    movzx edi,ch
    shl edi,2
    mov edi,dword ptr cs:[edi].create_port_tab    
    mov dx,es
    mov ds,dx
    mov dword ptr ds:cd_create_proc,edi
    mov dword ptr ds:cd_create_proc+4,cs
;    
    mov dx,ax
    mov ax,bx
    AddComPort
    mov ds:uds_port_nr,ax

apDone:
    popad
    pop es
    ret
AddPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AddUnit
;
;   DESCRIPTION:    Add unit
;
;   PARAMETERS:     DX      Device type
;                   ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddUnit Proc near
    push ds
    push ax
    push bx
    push si
;
    mov bx,es:uc_controller
    mov al,es:uc_port
    mov ah,es:uc_unit_count
    call AddPort
;
    mov ds:uds_device_sel,es
    movzx si,es:uc_unit_count
    shl si,1
    add si,OFFSET uc_unit_arr
    mov es:[si],ds
    inc es:uc_unit_count
;
    pop si
    pop bx
    pop ax
    pop ds
    ret
AddUnit Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           IsFTDI
;
;    Description:    Check for FTDI device
;
;    Parameters:     ES         Device descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ftTab:
ft00    DW 0403h,       0F2D0h  ; ACTZWAVE
ft01    DW 0403h,       0FC60h  ; IRTRANS
ft02    DW 0403h,       0D070h  ; IPLft
ft03    DW 0403h,       08372h  ; SIO
ft04    DW 0403h,       06001h  ; 8U232AM
ft05    DW 0403h,       06006h  ; 8U232AM_ALT
ft06    DW 0403h,       06010h  ; 8U2232C
ft07    DW 0403h,       0FA10h  ; RELAIS
ft08    DW 1209h,       01002h  ; IOBOARD
ft09    DW 1209h,       01006h  ; MINI_IOBOARD
ft0A    DW 0403h,       0FC08h  ; XF_632
ft0B    DW 0403h,       0FC09h  ; XF_634
ft0C    DW 0403h,       0FC0Ah  ; XF_547
ft0D    DW 0403h,       0FC0Bh  ; XF_633
ft0E    DW 0403h,       0FC0Ch  ; XF_631
ft0F    DW 0403h,       0FC0Dh  ; XF_635
ft10    DW 0403h,       0FC0Eh  ; XF_640
ft11    DW 0403h,       0FC0Fh  ; XF_642
ft12    DW 0403h,       0FC82h  ; DSS20
ft13    DW 0DCDh,       00001h  ; NF_RIC
ft14    DW 0403h,       0FE38h  ; VNHCOCftB_D
ft15    DW 0403h,       0FA00h  ; MTXORB_0
ft16    DW 0403h,       0FA01h  ; MTXORB_1
ft17    DW 0403h,       0FA02h  ; MTXORB_2
ft18    DW 0403h,       0FA03h  ; MTXORB_3
ft19    DW 0403h,       0FA04h  ; MTXORB_4
ft1A    DW 0403h,       0FA05h  ; MTXORB_5
ft1B    DW 0403h,       0FA06h  ; MTXORB_6
ft1C    DW 0403h,       0F0C0h  ; PERLE_ULTRAPORT
ft1D    DW 0403h,       0F208h  ; PIEGROUP
ft1E    DW 0C52h,       02101h  ; Sealevel
ft1F    DW 0C52h,       02102h  ; Sealevel
ft20    DW 0C52h,       02103h  ; Sealevel
ft21    DW 0C52h,       02104h  ; Sealevel
ft22    DW 0C52h,       02211h  ; Sealevel
ft23    DW 0C52h,       02221h  ; Sealevel
ft24    DW 0C52h,       02212h  ; Sealevel
ft25    DW 0C52h,       02222h  ; Sealevel
ft26    DW 0C52h,       02213h  ; Sealevel
ft27    DW 0C52h,       02223h  ; Sealevel
ft28    DW 0C52h,       02411h  ; Sealevel
ft29    DW 0C52h,       02421h  ; Sealevel
ft2A    DW 0C52h,       02431h  ; Sealevel
ft2B    DW 0C52h,       02441h  ; Sealevel
ft2C    DW 0C52h,       02412h  ; Sealevel
ft2D    DW 0C52h,       02422h  ; Sealevel
ft2E    DW 0C52h,       02432h  ; Sealevel
ft2F    DW 0C52h,       02442h  ; Sealevel
ft30    DW 0C52h,       02413h  ; Sealevel
ft31    DW 0C52h,       02423h  ; Sealevel
ft32    DW 0C52h,       02433h  ; Sealevel
ft33    DW 0C52h,       02443h  ; Sealevel
ft34    DW 0C52h,       02811h  ; Sealevel
ft35    DW 0C52h,       02821h  ; Sealevel
ft36    DW 0C52h,       02831h  ; Sealevel
ft37    DW 0C52h,       02841h  ; Sealevel
ft38    DW 0C52h,       02851h  ; Sealevel
ft39    DW 0C52h,       02861h  ; Sealevel
ft3A    DW 0C52h,       02871h  ; Sealevel
ft3B    DW 0C52h,       02881h  ; Sealevel
ft3C    DW 0C52h,       02812h  ; Sealevel
ft3D    DW 0C52h,       02822h  ; Sealevel
ft3E    DW 0C52h,       02832h  ; Sealevel
ft3F    DW 0C52h,       02842h  ; Sealevel
ft40    DW 0C52h,       02852h  ; Sealevel
ft41    DW 0C52h,       02862h  ; Sealevel
ft42    DW 0C52h,       02872h  ; Sealevel
ft43    DW 0C52h,       02882h  ; Sealevel
ft44    DW 0C52h,       02813h  ; Sealevel
ft45    DW 0C52h,       02823h  ; Sealevel
ft46    DW 0C52h,       02833h  ; Sealevel
ft47    DW 0C52h,       02843h  ; Sealevel
ft48    DW 0C52h,       02853h  ; Sealevel
ft49    DW 0C52h,       02863h  ; Sealevel
ft50    DW 0C52h,       02873h  ; Sealevel
ft51    DW 0C52h,       02883h  ; Sealevel
ft52    DW 0ACDh,       00300h  ; IDTECH_IDT1221U
ft53    DW 0B39h,       00421h  ; OCT_ft101
ft54    DW 0403h,       0FA78h  ; HE_TIRA1
ft55    DW 0403h,       0F850h  ; ftB_UIRT
ft56    DW 0403h,       0FC70h  ; PROTEGO_SPECIAL_1
ft57    DW 0403h,       0FC71h  ; PROTEGO_R2X0
ft58    DW 0403h,       0FC72h  ; PROTEGO_SPECIAL_3
ft59    DW 0403h,       0FC73h  ; PROTEGO_SPECIAL_4
ft5A    DW 0403h,       0E808h  ; GUDEADS
ft5B    DW 0403h,       0E809h  ; GUDEADS
ft5C    DW 0403h,       0E80Ah  ; GUDEADS
ft5D    DW 0403h,       0E80Bh  ; GUDEADS
ft5E    DW 0403h,       0E80Ch  ; GUDEADS
ft5F    DW 0403h,       0E80Dh  ; GUDEADS
ft60    DW 0403h,       0E80Eh  ; GUDEADS
ft61    DW 0403h,       0E80Fh  ; GUDEADS
ft62    DW 0403h,       0E888h  ; GUDEADS
ft63    DW 0403h,       0E889h  ; GUDEADS
ft64    DW 0403h,       0E88Ah  ; GUDEADS
ft65    DW 0403h,       0E88Bh  ; GUDEADS
ft66    DW 0403h,       0E88Ch  ; GUDEADS
ft67    DW 0403h,       0E88Dh  ; GUDEADS
ft68    DW 0403h,       0E88Eh  ; GUDEADS
ft69    DW 0403h,       0E88Fh  ; GUDEADS
ft6A    DW 0403h,       0FB58h  ; ELV_UR100
ft6B    DW 0403h,       0FB5Ah  ; ELV_UM100
ft6C    DW 0403h,       0FB5Bh  ; ELV_UO100
ft6D    DW 0403h,       0F06Eh  ; ELV_ALC8500
ft6E    DW 0403h,       0E6C8h  ; PYRAMID
ft6F    DW 0403h,       0F06Fh  ; FHZ1000PC
ft70    DW 0403h,       0F448h  ; LINX_SDMftBQSS
ft71    DW 0403h,       0F449h  ; LINX_MASTERDEVEL2
ft72    DW 0403h,       0F44Ah  ; LINX_FUTURE_0
ft73    DW 0403h,       0F44Bh  ; LINX_FUTURE_1
ft74    DW 0403h,       0F44Ch  ; LINX_FUTURE_2
ft75    DW 0403h,       0F9D0h  ; CCSICDU20
ft76    DW 0403h,       0F9D1h  ; CCSICDU40
ft77    DW 0403h,       0FAD0h  ; INSIDE_ACCESSO
ft78    DW 093Ch,       00601h  ; INTREPID_CALUECAN
ft79    DW 093Ch,       00701h  ; INTREPID_NEOVI
ft7A    DW 0F94h,       00001h  ; FALCOM_TWIST
ft7B    DW 0F94h,       00005h  ; FALCOM_SAMBA
ft7C    DW 0403h,       0F680h  ; SUUNTO_SPORTS
ft7D    DW 0403h,       0FD60h  ; RM_CANVIEW
ft7E    DW 0856h,       0AC01h  ; BANDB
ft7F    DW 0856h,       0AC02h  ; BANDB
ft80    DW 0856h,       0AC03h  ; BANDB
ft81    DW 0403h,       0E520h  ; EVER_ECO_PRO
ft82    DW 0403h,       08372h  ; 4N_GALXY_DE_0
ft83    DW 0403h,       0F3C0h  ; 4N_GALXY_DE_1
ft84    DW 0403h,       0F3C1h  ; 4N_GALXY_DE_2
ft85    DW 0403h,       0D388h  ; XSENS_CONV_0
ft86    DW 0403h,       0D389h  ; XSENS_CONV_1
ft87    DW 0403h,       0D38Ah  ; XSENS_CONV_2
ft88    DW 0403h,       0D38Bh  ; XSENS_CONV_3
ft89    DW 0403h,       0D38Ch  ; XSENS_CONV_4
ft8A    DW 0403h,       0D38Dh  ; XSENS_CONV_5
ft8B    DW 0403h,       0D38Eh  ; XSENS_CONV_6
ft8C    DW 0403h,       0D38Fh  ; XSENS_CONV_7
ft8D    DW 1342h,       00202h  ; MOBILITY
ft8E    DW 0403h,       0E548h  ; ACTIVE_ROBOTS
ft8F    DW 0403h,       0EEE8h  ; MHAM_KW
ft90    DW 0403h,       0EEE9h  ; MHAM_YS
ft91    DW 0403h,       0EEEAh  ; MHAM_Y6
ft92    DW 0403h,       0EEEBh  ; MHAM_Y8
ft93    DW 0403h,       0EEECh  ; MHAM_IC
ft94    DW 0403h,       0EEEDh  ; MHAM_DB9
ft95    DW 0403h,       0EEEEh  ; MHAM_RS232
ft96    DW 0403h,       0EEEFh  ; MHAM_Y9
ft97    DW 0403h,       0EC88h  ; TERATRONIK_VCP
ft98    DW 0403h,       0EC89h  ; TERATRONIK_D2XX
ft99    DW 0DEEEh,      00300h  ; EVOLUTION
ft9A    DW 0403h,       0DF28h  ; ARTEMIS
ft9B    DW 0403h,       0DF30h  ; ATIK_ATK16
ft9C    DW 0403h,       0DF32h  ; ATIK_ATK16C
ft9D    DW 0403h,       0DF31h  ; ATIK_ATK16HR
ft9E    DW 0403h,       0DF33h  ; ATIK_ATK16HRC
ft9F    DW 0D46h,       02020h  ; KOBIL_CONV_B1
ftA0    DW 0D46h,       02021h  ; KOBIL_CONV_KAAN
ftA1    DW 0D3Ah,       00300h  ; POSIFLEX
ftA2    DW 0403h,       0FF20h  ; TTftB
ftA3    DW 0403h,       0EA90h  ; ECLO_COM_1WIRE
ftA4    DW 0403h,       0DC00h  ; WESTREX_777
ftA5    DW 0403h,       0DC01h  ; WESTREX_8900F
ftA6    DW 0403h,       0FA88h  ; PCDJ_DAC2
ftA7    DW 0403h,       0C7D0h  ; RRCIRKITS
ftA8    DW 0403h,       0C991h  ; ASK_RDR400
ftA9    DW 0C26h,       00004h  ; ICOM_ID1
ftAA    DW 5050h,       00400h  ; PAPOUCH
ftAB    DW 0403h,       0DD20h  ; ACG_HFDUAL
ftAC    DW 0856h,       0AC27h  ; 232USB9M
ftAD    DW 0403h,       06015h  ; Vera
ftAE    DW 0403h,       06011h  ; FT4232H

IsFTDI  Proc near
    push cx
    push si
    push di
    push bp
;
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,0AFh
    mov bp,OFFSET ftTab

iftLoop:
    cmp si,cs:[bp]
    jne iftNext
;
    cmp di,cs:[bp+2]
    clc
    je iftDone

iftNext:
    add bp,4
    loop iftLoop    
;
    stc

iftDone:
    pop bp
    pop di
    pop si
    pop bp
    ret
IsFTDI  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetFTDIType
;
;   Description:    Get FTDI device type
;
;   Parameters:     ES      Device descritor
;
;   Returns:        SI      Device type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFTDIType  Proc far
    mov si,es:udd_device
    retf32
GetFTDIType  Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AttachFTDI
;
;   Description:    Attach FTDI devices
;
;   Parameters:     ES      Device sel
;                   SI      Device type
;                   BX      Controller #
;                   AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AttachFTDI  Proc far
    pushad
;
    mov di,OFFSET uc_dev_descr_buf
    mov bp,es:uc_dev_descr_size
    add bp,di
    jmp aftDescrNext

aftDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,4
    jne aftDescrNext
;
    cmp si,200h
    jae aftNotSio
; 
    mov dx,DEVICE_TYPE_SIO
    call AddUnit
    jmp aftDone

aftNotSio:
    cmp si,400h
    jae aftNotAm
;
    mov dx,DEVICE_TYPE_FT232AM
    call AddUnit
    jmp aftDone

aftNotAm:
    mov cl,es:uc_interface_count
    cmp cl,1
    ja aftMore
;
    mov dx,DEVICE_TYPE_FT232BM
    call AddUnit
    jmp aftDone

aftMore:
    cmp cl,2
    ja aft4
;
    mov dx,DEVICE_TYPE_FT2232C 
    call AddUnit
    jmp aftDescrNext

aft4:
    mov dx,DEVICE_TYPE_FT4232H 
    call AddUnit

aftDescrNext:
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,bp
    jb aftDescrLoop    
    
aftDone:
    clc
    popad
    retf32
AttachFTDI  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           IsPL2303
;
;    Description:    Check for PL2303 device
;
;    Parameters:     ES         Device descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

plTab:
pl00    DW 06FBh,       02303h  ; PL2303
pl01    DW 06FBh,       004BBh  ; PL2303
pl02    DW 06FBh,       0AAA0h  ; PL2303
pl03    DW 06FBh,       0AAA2h  ; PL2303
pl04    DW 0557h,       02008h  ; ATEN
pl05    DW 0547h,       02008h  ; ATEN
pl06    DW 04BBh,       00A03h  ; ATEN
pl07    DW 056Eh,       05003h  ; ELCOM
pl08    DW 056Eh,       05004h  ; ELCOM
pl09    DW 0EBAh,       01080h  ; ITEGNO
pl0A    DW 0EBAh,       02080h  ; ITEGNO
pl0B    DW 0DF7h,       00620h  ; MA620
pl0C    DW 0584h,       0B000h  ; RATOC
pl0D    DW 2478h,       02008h  ; TRIPP
pl0E    DW 1453h,       04026h  ; RADIOSHACK
pl0F    DW 0731h,       00528h  ; DCU10
pl10    DW 6189h,       02068h  ; SITECOM
pl11    DW 11F7h,       002DFh  ; ALCATEL
pl12    DW 04E8h,       08001h  ; SAMSUNG
pl13    DW 11F5h,       00001h  ; SIEMENS
pl14    DW 11F5h,       00003h  ; SIEMENS
pl15    DW 11F5h,       00004h  ; SIEMENS
pl16    DW 0745h,       00001h  ; SYNTECH
pl17    DW 078Bh,       01234h  ; NOKIA
pl18    DW 10B5h,       0AC70h  ; CA-42
pl19    DW 079Bh,       00027h  ; SAGEM
pl1A    DW 0413h,       02101h  ; LEADTEK
pl1B    DW 0E55h,       0110Bh  ; SPEEDDRAGON
pl1C    DW 0EA0h,       06858h  ; OTI
pl1D    DW 067Bh,       02303h  ; PL2303

IsPL2303        Proc near
    push cx
    push si
    push di
    push bp
;
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,01Eh
    mov bp,OFFSET plTab

iplLoop:
    cmp si,cs:[bp]
    jne iplNext
;
    cmp di,cs:[bp+2]
    clc
    je iplDone

iplNext:
    add bp,4
    loop iplLoop    
;
    stc

iplDone:
    pop bp
    pop di
    pop si
    pop bp
    ret
IsPL2303        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetPL2303Type
;
;   Description:    Attach PL2303 devices
;
;   Parameters:     ES      Device descritor
;
;   Returns:        SI      Device type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
GetPL2303Type  Proc far
    mov cl,es:udd_class
    cmp cl,2
    je gplDescrType01
;
    mov cl,es:udd_maxlen
    cmp cl,40h
    jne gplDescrType01
;    
    mov si,DEVICE_TYPE_PL_HX
    jmp gplDescrDeviceOk    

gplDescrType01:
    mov si,DEVICE_TYPE_PL_01

gplDescrDeviceOk:    
    retf32
GetPL2303Type  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AttachPL2303
;
;   Description:    Attach PL2303 devices
;
;   Parameters:     ES:DI   Config descritor
;                   CX      Descriptor size
;                   SI      Device type
;                   BX      Controller #
;                   AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
AttachPL2303  Proc far
    pushad
;
    mov di,OFFSET uc_dev_descr_buf
    mov bp,es:uc_dev_descr_size
    add bp,di
    jmp aplDescrNext

aplDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,4
    jne aplDescrNext
; 
    mov dx,si
    call AddUnit
    jmp aplDone

aplDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,bp
    jb aplDescrLoop    
    
aplDone:
    clc
    popad
    retf32
AttachPL2303  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           IsMct
;
;   Description:    Check for MCT device
;
;   Parameters:     ES          Device descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mctTab:
mc00    DW 0711h,       0210h   ; Original
mc01    DW 0711h,       0230h   ; Sitecom
mc02    DW 0711h,       0200h   ; D-link
mc03    DW 050Dh,       0109h   ; Belkin

IsMct   Proc near
    push cx
    push di
    push bp
;
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,4
    mov bp,OFFSET mctTab

imctLoop:
    cmp si,cs:[bp]
    jne imctNext
;
    cmp di,cs:[bp+2]
    clc
    jne imctDone

imctNext:
    add bp,4
    loop imctLoop    
;
    stc

imctDone:
    pop bp
    pop di
    pop bp
    ret
IsMct   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetMctType
;
;   Description:    Get MCT type
;
;   Parameters:     ES      Device descritor
;
;   Returns:        SI      Device type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMctType  Proc far
    push di
;
    mov si,es:udd_vendor
    mov di,es:udd_prod
;
    cmp si,50Dh
    je gmctBelkin
;    
    mov si,DEVICE_TYPE_MCT
    cmp di,230h
    jne gmctDeviceOk
;
    mov si,DEVICE_TYPE_MCT_SITECOM
    jmp gmctDeviceOk

gmctBelkin:
    mov si,DEVICE_TYPE_MCT_BELKIN

gmctDeviceOk:
    pop di
    retf32
GetMctType  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AttachMct
;
;   Description:    Attach MCT devices
;
;   Parameters:     ES:DI   Config descritor
;                   CX      Descriptor size
;                   SI      Device type
;                   BX      Controller #
;                   AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AttachMct  Proc far
    pushad
;
    mov di,OFFSET uc_dev_descr_buf
    mov bp,es:uc_dev_descr_size
    add bp,di
    jmp amctDescrNext

amctDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,4
    jne amctDescrNext
; 
    mov dx,si
    call AddUnit
    jmp amctDone

amctDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,bp
    jb amctDescrLoop    
    
amctDone:
    clc
    popad
    retf32
AttachMct  Endp
        
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
;   Parameters:     ES      Device sel
;                   EBP     Thread start
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

com_name  DB 'USB Com ', 0

CreateServerThread    Proc near
    push ds
    push es
    pushad
;
    mov bx,es
    mov ds,bx
;
    push es
    push bx
    mov bx,ds:uc_controller
    mov al,ds:uc_port
    OpenUsbDevice
    mov ds:uc_dev_handle,bx
    GetUsbDeviceSel
    mov ds:uc_dev_sel,es
    pop bx
    pop es
;
    mov eax,100h
    AllocateSmallGlobalMem
;
    xor dl,dl

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
    mov ax,ds:uc_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,ds:uc_port
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
    mov esi,ebp
    mov eax,3
    mov ecx,stack0_size
    CreateThread
;
    pop ds
;
    inc dl
    cmp dl,ds:uc_unit_count
    jne cstUnitLoop
;
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
;   NAME:           InsertDevice
;
;   Description:    Insert device
;
;   Parameters:     DS      Data segment
;                   ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertDevice    Proc near
    push si
;
    mov si,ds:sd_dev_count
    add si,si
    mov ds:[si].sd_dev_arr,es
    inc ds:sd_dev_count
    mov es:uc_dev_offset,si
;
    pop si
    ret
InsertDevice   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           CheckDevice
;
;    Description:    Search device
;
;    Parameters:     DS         Device sel
;                    ES         Descriptor
;                    ESI        Vendor & product
;                    BP         Descriptor size
;
;    Returns:        NC         Match
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckDevice     Proc near
    push eax
;
    mov ax,ds:uc_vendor
    shl eax,16
    mov ax,ds:uc_product
    cmp eax,esi
    jne chdFail
;
    mov ax,ds:uc_dev_descr_size
    cmp ax,bp
    jne chdFail
;
    push cx
    push si
;
    mov cx,bp
    mov si,OFFSET uc_dev_descr_buf
    xor di,di
    repe cmpsb
;
    pop si
    pop cx
    clc
    jz chdDone

chdFail:
    stc

chdDone:
    pop eax
    ret
CheckDevice     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           FindAnyDevice
;
;    Description:    Search for dead device
;
;    Parameters:     DS         Data seg
;                    ES         Descriptor
;                    ESI        Vendor & product
;                    BP         Descriptor size
;
;    Returns:        ECX        Number of matches
;                    GS         Device sel of last match
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindAnyDevice   Proc near
    push ds
    push eax
    push ebx
    push edx
    push edi
;
    xor ecx,ecx
;
    mov bx,ds:sd_dead_list
    or bx,bx
    jz fadDone
;
    mov dx,bx

fadLoop:
    mov ds,bx
    call CheckDevice
    jc fadNext
;
    inc cx
    mov ax,ds
    mov gs,ax

fadNext:
    mov bx,ds:uc_next
    cmp bx,dx
    jne fadLoop

fadDone:
    pop edi
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
FindAnyDevice   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           FindSpecificDevice
;
;    Description:    Search for dead device
;
;    Parameters:     DS      Data seg
;                    BX      Controller #
;                    AH      Port #
;                    AL      Device address
;
;    Returns:        NC      Found
;                        GS  Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindSpecificDevice      Proc near
    push ds
    push ecx
    push edx
;
    mov cx,ds:sd_dead_list
    or cx,cx
    stc
    jz fsdDone
;
    mov dx,cx

fsdLoop:
    mov ds,cx
    cmp bx,ds:uc_controller
    jne fsdNext
;
    cmp al,ds:uc_port
    jne fsdNext
;
    call CheckDevice
    jc fsdNext
;
    mov cx,ds
    mov gs,cx
    clc
    jmp fsdDone

fsdNext:
    mov cx,ds:uc_next
    cmp cx,dx
    jne fsdLoop
;
    stc

fsdDone:
    pop edx
    pop ecx    
    pop ds
    ret
FindSpecificDevice      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ConfigDevice
;
;   Description:    USB attach callback
;
;   Parameters:     DS      Data segment
;                   ES      Descriptor buffer
;                   BX      Controller #
;                   AH      Port #
;                   AL      Device address
;                   ESI     Vendor + device
;                   FS:EBP  Device table
;
;   Returns:        ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigDevice  Proc near
    push gs
    pushad
;    
    call fword ptr fs:[ebp].cs_dev_type_proc
;
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    stc
    jz cdDone
;
    push ax
    mov dl,es:ucd_config_id
    ConfigUsbDevice
    pop ax
    jc cdDone
;
    push ebp
;
    EnterSection ds:sd_section
    mov bp,cx
    call FindAnyDevice
    or cx,cx
    jz cdAdd
;
    cmp cx,1
    je cdRecreate
;
    call FindSpecificDevice
    jnc cdRecreate

cdAdd:
    push ds
    push eax
    push ebx
    push edx
    push esi
;
    movzx ebp,es:ucd_size
    mov dl,es:ucd_interface_count
    mov ax,es
    mov ds,ax
;
    mov eax,OFFSET uc_dev_descr_buf
    add eax,ebp
    AllocateSmallGlobalMem
;
    mov cx,bp
    xor si,si
    mov di,OFFSET uc_dev_descr_buf
    rep movsb
;
    push es
    mov eax,ds
    mov es,eax
    xor eax,eax
    mov ds,eax
    FreeMem
    pop es
;
    mov es:uc_dev_descr_size,bp
    mov es:uc_interface_count,dl
;
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds
;
    pop ebp
;
    InitSection es:uc_section
    mov es:uc_product,si
    shr esi,16
    mov es:uc_vendor,si
    mov es:uc_controller,bx
    mov es:uc_port,al
    mov es:uc_unit_count,0
;
    call InsertDevice
    LeaveSection ds:sd_section
;
    call fword ptr fs:[ebp].cs_dev_attach_proc
;
    mov ebp,OFFSET usb_com_create
    call CreateServerThread
    clc
    jmp cdDone

cdRecreate:
    push ds
    mov si,gs
    mov di,gs:uc_next
    cmp di,si
    mov ds:sd_dead_list,di
    mov si,gs:uc_prev
    mov ds,di
    mov ds:uc_prev,si
    mov ds,si
    mov ds:uc_next,di
    pop ds
    jne cdDeadOk
;    
    mov ds:sd_dead_list,0

cdDeadOk:
    pop ebp
;
    LeaveSection ds:sd_section
;
    mov cx,gs
    mov es,cx
    mov es:uc_controller,bx
    mov es:uc_port,al
;
    mov ebp,OFFSET usb_com_recreate
    call CreateServerThread
    clc

cdDone:
    popad
    pop gs
    ret
ConfigDevice  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           usb_attach
;
;   Description:    USB attach callback
;
;   Parameters:     BX      Controller #
;                   AL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ftdi_attach_tab:
fa00  DD OFFSET GetFTDIType, SEG code
fa01  DD OFFSET AttachFTDI,  SEG code

pl2303_attach_tab:
pla00  DD OFFSET GetPL2303Type, SEG code
pla01  DD OFFSET AttachPL2303,  SEG code

mct_attach_tab:
mcta00  DD OFFSET GetMctType, SEG code
mcta01  DD OFFSET AttachMct,  SEG code

usb_attach  Proc far
    push ds
    push es
    push fs
    pushad
;
    mov cx,SEG data
    mov ds,cx
;
    push ax
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop ax
    xor di,di
    push ax
    GetUsbDevice
    cmp ax,cx
    pop ax
    jne uaDone
;
    call IsFTDI
    jnc uaFTDI
;
    call IsPL2303
    jnc uaPL2303
;
    call IsMct
    jnc uaMct

uaFail:
    FreeMem
    jmp uaDone

uaFTDI:
    mov si,cs
    mov fs,si
    mov ebp,OFFSET ftdi_attach_tab
    jmp uaConfig

uaPL2303:
    mov si,cs
    mov fs,si
    mov ebp,OFFSET pl2303_attach_tab
    jmp uaConfig

uaMCT:
    mov si,cs
    mov fs,si
    mov ebp,OFFSET mct_attach_tab

uaConfig:
    mov si,es:udd_vendor
    shl esi,16
    mov si,es:udd_prod
    call ConfigDevice

uaDone:
    popad
    pop fs
    pop es
    pop ds
    retf32
usb_attach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_detach
;
;           description:    USB detach callback
;
;           Parameters:     BX      Controller #
;                           AL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    mov dx,SEG data
    mov ds,dx
    mov si,OFFSET sd_dev_arr
    mov cx,ds:sd_dev_count
    or cx,cx
    jz udDone

udCheckLoop:
    mov dx,[si]
    or dx,dx
    jz udCheckNext
;
    mov es,dx
    cmp bx,es:uc_controller
    jne udCheckNext
;
    cmp al,es:uc_port
    jne udCheckNext
;
    GetThread
    mov es:uc_detach,ax

udRetry:
    xor dl,dl
    xor dh,dh

udDisLoop:
    movzx si,dl
    add si,si
    mov ds,es:[si].uc_unit_arr
;
    or ds:uds_flags,FLAG_UDS_DISCONNECT
    mov bx,ds:uds_thread
    or bx,bx
    jz udDisNext
;
    Signal
    inc dh

udDisNext:
    inc dl
    cmp dl,es:uc_unit_count
    jne udDisLoop
;
    or dh,dh
    jz udUnlink
;
    WaitForSignal
    jmp udRetry

udUnlink:
    mov bx,es:uc_dev_handle
    CloseUsbDevice
;
    mov dx,SEG data
    mov ds,dx
;
    EnterSection ds:sd_section
    mov di,ds:sd_dead_list
    or di,di
    je udInsEmpty
;
    push ds
    push si
;
    mov ds,di
    mov si,ds:uc_prev
    mov ds:uc_prev,es
    mov ds,si
    mov ds:uc_next,es
    mov es:uc_next,di
    mov es:uc_prev,si
;
    pop si
    pop ds
    jmp udInsDone
    
udInsEmpty:
    mov es:uc_next,es
    mov es:uc_prev,es
    mov ds:sd_dead_list,es

udInsDone:
    LeaveSection ds:sd_section
    jmp udDone

udCheckNext:
    add esi,2    
    sub ecx,1
    jnz udCheckLoop

udDone:
    popad
    pop es
    pop ds
    retf32
usb_detach  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov bx,SEG data
    mov es,bx
    mov es:sd_ports,0
    mov es:sd_dev_count,0
    mov es:sd_dead_list,0
    InitSection ds:sd_section
;       
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_usb_com_par
    mov edi,OFFSET get_usb_com_par_name
    xor dx,dx
    mov ax,get_usb_com_par_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_usb_com_dev
    mov edi,OFFSET get_usb_com_dev_name
    xor dx,dx
    mov ax,get_usb_com_dev_nr
    RegisterBimodalUserGate
;
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
    clc
    ret
init    Endp

code    ENDS

    END init
