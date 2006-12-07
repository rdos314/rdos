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
; USBCOM.ASM
; USB based serial port device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME usbcom

GateSize = 16

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\os\usb.inc
include ..\os\com.inc

MAX_PORTS       = 16

DEVICE_TYPE_SIO = 1
DEVICE_TYPE_FT232AM = 2
DEVICE_TYPE_FT232BM = 3
DEVICE_TYPE_FT2232C = 4

usbcom_port_struc	STRUC

ups_base_struc  com_port_struc <>

ups_controller      DW ?
ups_device          DW ?
ups_wait_handle     DW ?
ups_control_pipe    DW ?
ups_index           DW ?

usbcom_port_struc	ENDS

usbcom_device_struc   STRUC

uds_base_struc    com_device_struc <>

uds_device_type     DW ?
uds_interface       DB ?

usbcom_device_struc   ENDS

serial_data STRUC

sd_ports    DW ?
sd_port_arr DW MAX_PORTS DUP(?)

serial_data ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

	assume cs:code

	.386c

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			open_com
;
;		description:	Open a serial port
;
;		PARAMETERS:		DS      Port selector
;		        		ES		Device selector
;						AH		# of data bits
;						BL		# of stop bits
;						BH		parity
;						ECX		baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com	Proc far
    pushad
;
    CreateWait
    mov ds:ups_wait_handle,bx
;
    mov bx,ds:ups_controller
    mov ax,ds:ups_device
    xor dl,dl
    OpenUsbPipe
    mov ds:ups_control_pipe,bx
;
    mov ax,ds:ups_control_pipe
    mov bx,ds:ups_wait_handle
    movzx ecx,bx
    AddWaitForUsbPipe
;
    call set_dtr    
    call set_rts
    call disable_cts
;
    popad
	ret
open_com	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			close_com
;
;		description:	Close serial port
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com	Proc far
    push bx
;
    call reset_rts
    call reset_dtr
;    
    mov bx,ds:ups_wait_handle
    CloseWait
;
    mov bx,ds:ups_control_pipe
    CloseUsbPipe    
;
    pop bx    
	ret
close_com	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			EnableCts
;
;		DESCRIPTION:	Enable CTS signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_cts	PROC far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,40h
    mov es:usd_value,1
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_wait_handle
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
    ret
enable_cts Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DisableCts
;
;		DESCRIPTION:	Disable CTS signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_cts	PROC far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,40h
    mov es:usd_value,0
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_wait_handle
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
    ret
disable_cts Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			EnableAutoRts
;
;		DESCRIPTION:	Enable automatic RTS on send
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_auto_rts	PROC far
    ret
enable_auto_rts Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DisableAutoRts
;
;		DESCRIPTION:	Disable automatic RTS on send
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_auto_rts	PROC far
    ret
disable_auto_rts Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FlushCom
;
;		DESCRIPTION:	Flush com
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_com	PROC far
    ret
flush_com Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			start_send
;
;		description:	Start send
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_send	PROC far
	ret
start_send	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			set_dtr
;
;		description:	Set DTR signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dtr	Proc far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,1
    mov es:usd_value,101h
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_wait_handle
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
	ret
set_dtr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			reset_dtr
;
;		description:	Reset DTR signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_dtr	Proc far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,1
    mov es:usd_value,100h
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_wait_handle
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
	ret
reset_dtr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			set_rts
;
;		description:	Set RTS signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rts	Proc far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,1
    mov es:usd_value,202h
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_wait_handle
    WaitWithTimeout
;
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
	ret
set_rts	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			reset_rts
;
;		description:	Reset RTS signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_rts	Proc far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,1
    mov es:usd_value,200h
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_wait_handle
    WaitWithTimeout
;
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
	ret
reset_rts	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        create_port
;
;		description:	Create port selector
;
;		RETURNS:		ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

port_tab:
pt00 DW OFFSET open_com,   	        usbcom_code_sel
pt01 DW OFFSET close_com,           usbcom_code_sel
pt02 DW OFFSET enable_cts,          usbcom_code_sel
pt03 DW OFFSET disable_cts,         usbcom_code_sel
pt04 DW OFFSET set_dtr,             usbcom_code_sel
pt05 DW OFFSET reset_dtr,           usbcom_code_sel
pt06 DW OFFSET set_rts,             usbcom_code_sel
pt07 DW OFFSET reset_rts,           usbcom_code_sel
pt08 DW OFFSET enable_auto_rts,     usbcom_code_sel
pt09 DW OFFSET disable_auto_rts,    usbcom_code_sel
pt10 DW OFFSET flush_com,           usbcom_code_sel
pt11 DW OFFSET start_send,          usbcom_code_sel

create_port	Proc far
    pushad
;
    mov eax,SIZE usbcom_port_struc
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
    movzx ax,ds:uds_interface
    mov es:ups_index,ax    
    mov ax,ds:cd_controller
    mov es:ups_controller,ax
    mov ax,ds:cd_device
    mov es:ups_device,ax
;        
    popad
	ret
create_port	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddPort
;
;		DESCRIPTION:    Add port to list of available ports
;
;       PARAMETERS:     AL      Device address
;                       BX      Controller id
;                       CL      Interface #
;                       DX      Device type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPort Proc near
    push ds
    push es
    pushad
;    
    push ax
    mov ax,usbcom_data_sel
    mov ds,ax
;
    mov eax,SIZE usbcom_device_struc
	AllocateSmallGlobalMem
	pop ax
    mov es:uds_interface,cl
	mov es:uds_device_type,dx
;
    mov si,ds:sd_ports
    add si,si
    mov ds:[si].sd_port_arr,es
    inc ds:sd_ports
;
    mov dx,es
    mov ds,dx
    mov dx,cs
    mov es,dx
    mov di,OFFSET create_port
    movzx dx,al
    mov ax,bx
    AddComPort
;
    popad
    pop es
    pop ds	
    ret
AddPort Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        usb_attach
;
;		description:	USB attach callback
;
;		Parameters:     BX      Controller #
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usTab:
us00	DW 0403h,	0F2D0h	; ACTZWAVE
us01	DW 0403h,	0FC60h	; IRTRANS
us02	DW 0403h,	0D070h	; IPLUS
us03	DW 0403h,	08372h	; SIO
us04	DW 0403h,	06001h	; 8U232AM
us05	DW 0403h,	06006h	; 8U232AM_ALT
us06	DW 0403h,	06010h	; 8U2232C
us07	DW 0403h,	0FA10h	; RELAIS
us08	DW 1209h,	01002h	; IOBOARD
us09	DW 1209h,	01006h	; MINI_IOBOARD
us0A	DW 0403h,	0FC08h	; XF_632
us0B	DW 0403h,	0FC09h	; XF_634
us0C	DW 0403h,	0FC0Ah	; XF_547
us0D	DW 0403h,	0FC0Bh	; XF_633
us0E	DW 0403h,	0FC0Ch	; XF_631
us0F	DW 0403h,	0FC0Dh	; XF_635
us10	DW 0403h,	0FC0Eh	; XF_640
us11	DW 0403h,	0FC0Fh	; XF_642
us12	DW 0403h,	0FC82h	; DSS20
us13	DW 0DCDh,	00001h	; NF_RIC
us14	DW 0403h,	0FE38h	; VNHCOCUSB_D
us15	DW 0403h,	0FA00h	; MTXORB_0
us16	DW 0403h,	0FA01h	; MTXORB_1
us17	DW 0403h,	0FA02h	; MTXORB_2
us18	DW 0403h,	0FA03h	; MTXORB_3
us19	DW 0403h,	0FA04h	; MTXORB_4
us1A	DW 0403h,	0FA05h	; MTXORB_5
us1B	DW 0403h,	0FA06h	; MTXORB_6
us1C	DW 0403h,	0F0C0h	; PERLE_ULTRAPORT
us1D	DW 0403h,	0F208h	; PIEGROUP
us1E	DW 0C52h,	02101h	; Sealevel
us1F	DW 0C52h,	02102h	; Sealevel
us20	DW 0C52h,	02103h	; Sealevel
us21	DW 0C52h,	02104h	; Sealevel
us22	DW 0C52h,	02211h	; Sealevel
us23	DW 0C52h,	02221h	; Sealevel
us24	DW 0C52h,	02212h	; Sealevel
us25	DW 0C52h,	02222h	; Sealevel
us26	DW 0C52h,	02213h	; Sealevel
us27	DW 0C52h,	02223h	; Sealevel
us28	DW 0C52h,	02411h	; Sealevel
us29	DW 0C52h,	02421h	; Sealevel
us2A	DW 0C52h,	02431h	; Sealevel
us2B	DW 0C52h,	02441h	; Sealevel
us2C	DW 0C52h,	02412h	; Sealevel
us2D	DW 0C52h,	02422h	; Sealevel
us2E	DW 0C52h,	02432h	; Sealevel
us2F	DW 0C52h,	02442h	; Sealevel
us30	DW 0C52h,	02413h	; Sealevel
us31	DW 0C52h,	02423h	; Sealevel
us32	DW 0C52h,	02433h	; Sealevel
us33	DW 0C52h,	02443h	; Sealevel
us34	DW 0C52h,	02811h	; Sealevel
us35	DW 0C52h,	02821h	; Sealevel
us36	DW 0C52h,	02831h	; Sealevel
us37	DW 0C52h,	02841h	; Sealevel
us38	DW 0C52h,	02851h	; Sealevel
us39	DW 0C52h,	02861h	; Sealevel
us3A	DW 0C52h,	02871h	; Sealevel
us3B	DW 0C52h,	02881h	; Sealevel
us3C	DW 0C52h,	02812h	; Sealevel
us3D	DW 0C52h,	02822h	; Sealevel
us3E	DW 0C52h,	02832h	; Sealevel
us3F	DW 0C52h,	02842h	; Sealevel
us40	DW 0C52h,	02852h	; Sealevel
us41	DW 0C52h,	02862h	; Sealevel
us42	DW 0C52h,	02872h	; Sealevel
us43	DW 0C52h,	02882h	; Sealevel
us44	DW 0C52h,	02813h	; Sealevel
us45	DW 0C52h,	02823h	; Sealevel
us46	DW 0C52h,	02833h	; Sealevel
us47	DW 0C52h,	02843h	; Sealevel
us48	DW 0C52h,	02853h	; Sealevel
us49	DW 0C52h,	02863h	; Sealevel
us50	DW 0C52h,	02873h	; Sealevel
us51	DW 0C52h,	02883h	; Sealevel
us52	DW 0ACDh,	00300h	; IDTECH_IDT1221U
us53	DW 0B39h,	00421h	; OCT_US101
us54	DW 0403h,	0FA78h	; HE_TIRA1
us55	DW 0403h,	0F850h	; USB_UIRT
us56	DW 0403h,	0FC70h	; PROTEGO_SPECIAL_1
us57	DW 0403h,	0FC71h	; PROTEGO_R2X0
us58	DW 0403h,	0FC72h	; PROTEGO_SPECIAL_3
us59	DW 0403h,	0FC73h	; PROTEGO_SPECIAL_4
us5A	DW 0403h,	0E808h	; GUDEADS
us5B	DW 0403h,	0E809h	; GUDEADS
us5C	DW 0403h,	0E80Ah	; GUDEADS
us5D	DW 0403h,	0E80Bh	; GUDEADS
us5E	DW 0403h,	0E80Ch	; GUDEADS
us5F	DW 0403h,	0E80Dh	; GUDEADS
us60	DW 0403h,	0E80Eh	; GUDEADS
us61	DW 0403h,	0E80Fh	; GUDEADS
us62	DW 0403h,	0E888h	; GUDEADS
us63	DW 0403h,	0E889h	; GUDEADS
us64	DW 0403h,	0E88Ah	; GUDEADS
us65	DW 0403h,	0E88Bh	; GUDEADS
us66	DW 0403h,	0E88Ch	; GUDEADS
us67	DW 0403h,	0E88Dh	; GUDEADS
us68	DW 0403h,	0E88Eh	; GUDEADS
us69	DW 0403h,	0E88Fh	; GUDEADS
us6A	DW 0403h,	0FB58h	; ELV_UR100
us6B	DW 0403h,	0FB5Ah	; ELV_UM100
us6C	DW 0403h,	0FB5Bh	; ELV_UO100
us6D	DW 0403h,	0F06Eh	; ELV_ALC8500
us6E	DW 0403h,	0E6C8h	; PYRAMID
us6F	DW 0403h,	0F06Fh	; FHZ1000PC
us70	DW 0403h,	0F448h	; LINX_SDMUSBQSS
us71	DW 0403h,	0F449h	; LINX_MASTERDEVEL2
us72	DW 0403h,	0F44Ah	; LINX_FUTURE_0
us73	DW 0403h,	0F44Bh	; LINX_FUTURE_1
us74	DW 0403h,	0F44Ch	; LINX_FUTURE_2
us75	DW 0403h,	0F9D0h	; CCSICDU20
us76	DW 0403h,	0F9D1h	; CCSICDU40
us77	DW 0403h,	0FAD0h	; INSIDE_ACCESSO
us78	DW 093Ch,	00601h	; INTREPID_CALUECAN
us79	DW 093Ch,	00701h	; INTREPID_NEOVI
us7A	DW 0F94h,	00001h	; FALCOM_TWIST
us7B	DW 0F94h,	00005h	; FALCOM_SAMBA
us7C	DW 0403h,	0F680h	; SUUNTO_SPORTS
us7D	DW 0403h,	0FD60h	; RM_CANVIEW
us7E	DW 0856h,	0AC01h	; BANDB
us7F	DW 0856h,	0AC02h	; BANDB
us80	DW 0856h,	0AC03h	; BANDB
us81	DW 0403h,	0E520h	; EVER_ECO_PRO
us82	DW 0403h,	08372h	; 4N_GALXY_DE_0
us83	DW 0403h,	0F3C0h	; 4N_GALXY_DE_1
us84	DW 0403h,	0F3C1h	; 4N_GALXY_DE_2
us85	DW 0403h,	0D388h	; XSENS_CONV_0
us86	DW 0403h,	0D389h	; XSENS_CONV_1
us87	DW 0403h,	0D38Ah	; XSENS_CONV_2
us88	DW 0403h,	0D38Bh	; XSENS_CONV_3
us89	DW 0403h,	0D38Ch	; XSENS_CONV_4
us8A	DW 0403h,	0D38Dh	; XSENS_CONV_5
us8B	DW 0403h,	0D38Eh	; XSENS_CONV_6
us8C	DW 0403h,	0D38Fh	; XSENS_CONV_7
us8D	DW 1342h,	00202h	; MOBILITY
us8E	DW 0403h,	0E548h	; ACTIVE_ROBOTS
us8F	DW 0403h,	0EEE8h	; MHAM_KW
us90	DW 0403h,	0EEE9h	; MHAM_YS
us91	DW 0403h,	0EEEAh	; MHAM_Y6
us92	DW 0403h,	0EEEBh	; MHAM_Y8
us93	DW 0403h,	0EEECh	; MHAM_IC
us94	DW 0403h,	0EEEDh	; MHAM_DB9
us95	DW 0403h,	0EEEEh	; MHAM_RS232
us96	DW 0403h,	0EEEFh	; MHAM_Y9
us97	DW 0403h,	0EC88h	; TERATRONIK_VCP
us98	DW 0403h,	0EC89h	; TERATRONIK_D2XX
us99	DW 0DEEEh,	00300h	; EVOLUTION
us9A	DW 0403h,	0DF28h	; ARTEMIS
us9B	DW 0403h,	0DF30h	; ATIK_ATK16
us9C	DW 0403h,	0DF32h	; ATIK_ATK16C
us9D	DW 0403h,	0DF31h	; ATIK_ATK16HR
us9E	DW 0403h,	0DF33h	; ATIK_ATK16HRC
us9F	DW 0D46h,	02020h	; KOBIL_CONV_B1
usA0	DW 0D46h,	02021h	; KOBIL_CONV_KAAN
usA1	DW 0D3Ah,	00300h	; POSIFLEX
usA2	DW 0403h,	0FF20h	; TTUSB
usA3	DW 0403h,	0EA90h	; ECLO_COM_1WIRE
usA4	DW 0403h,	0DC00h	; WESTREX_777
usA5	DW 0403h,	0DC01h	; WESTREX_8900F
usA6	DW 0403h,	0FA88h	; PCDJ_DAC2
usA7	DW 0403h,	0C7D0h	; RRCIRKITS
usA8	DW 0403h,	0C991h	; ASK_RDR400
usA9	DW 0C26h,	00004h	; ICOM_ID1
usAA	DW 5050h,	00400h	; PAPOUCH
usAB	DW 0403h,	0DD20h	; ACG_HFDUAL

usb_attach  Proc far
    push es
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
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,0ACh
    mov bp,OFFSET usTab

uaLoop:
    cmp si,cs:[bp]
    jne uaNext
;
    cmp di,cs:[bp+2]
    je uaFound

uaNext:
    add bp,4
    loop uaLoop        
;
    jmp uaDone    

uaFound:
    mov si,es:udd_device
;    
    xor dl,dl
    mov cx,SIZE usb_config_descr
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz uaDone
;
    mov dl,es:ucd_config_id
    ConfigUsbDevice
    jc uaDone
;
    cmp si,200h
    jae uaNotSio
; 
    mov dx,DEVICE_TYPE_SIO
    xor cx,cx
    call AddPort
    jmp uaDone

uaNotSio:
    cmp si,400h
    jae uaNotAm
;
    mov dx,DEVICE_TYPE_FT232AM
    xor cx,cx
    call AddPort
    jmp uaDone

uaNotAm:
    mov cl,es:ucd_interface_count
    cmp cl,1
    ja uaMany
;
    mov dx,DEVICE_TYPE_FT232BM
    xor cx,cx
    call AddPort
    jmp uaDone

uaMany:
    mov dx,DEVICE_TYPE_FT2232C 
    xor cx,cx
    call AddPort
;
    mov cx,1
    call AddPort
    
uaDone:
    FreeMem
;
    pop es    
    ret
usb_attach  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        usb_detach
;
;		description:	USB detach callback
;
;		Parameters:     BX      Controller #
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    int 3
    ret
usb_detach  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		description:	Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
	mov bx,usbcom_code_sel
	InitDevice
;
	mov eax,SIZE serial_data
	mov bx,usbcom_data_sel
	AllocateFixedSystemMem
	mov cx,SIZE serial_data
	xor di,di
	xor al,al
	rep stosb
;	
	mov ax,cs
	mov ds,ax
	mov es,ax
;
    mov di,OFFSET usb_attach
    HookUsbAttach
;
    mov di,OFFSET usb_detach
    HookUsbDetach
;
	popa
	pop es
	pop ds	
	ret
init	Endp

code	ENDS

	END init
