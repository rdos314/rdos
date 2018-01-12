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
; HID.ASM
; Implements HID class for USB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
INCLUDE ..\os\protseg.def
include ..\usbdev\usb.inc
INCLUDE ..\handle.inc
include hid.inc

usb_hid_descr  STRUC

uhd_len         DB ?
uhd_type        DB ?
uhd_hid_ver     DW ?
uhd_country_code    DB ?
uhd_descr_count     DB ?
uhd_descr_arr       DB ?

usb_hid_descr  ENDS

usb_hid_arr_descr   STRUC

uhad_descr_type      DB ?
uhad_descr_len       DW ?

usb_hid_arr_descr   ENDS

hid_handle_struc       STRUC

hh_base                 handle_header <>
hh_hid_sel              DW ?
hh_control_handle       DW ?
hh_control_wait         DW ?
hh_intr_handle          DW ?
hh_intr_req             DW ?
hh_intr_buf             DW ?

hid_handle_struc       ENDS


hid_output_struc        STRUC

ho_dev          DW ?
ho_size         DW ?
ho_req_type     DB ?
ho_req          DB ?
ho_report_id    DB ?
ho_report_type  DB ?
ho_interface    DW ?
ho_report_len   DW ?
ho_buf          DB ?

hid_output_struc        ENDS

MAX_TABLES  = 32

data    SEGMENT byte public 'DATA'

hid_table_count DW ?

hid_table_arr   DD 2 * MAX_TABLES DUP(?)

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p


tv:
tv0  DD 000000000h
tv1  DD 000000001h
tv2  DD 000000003h
tv3  DD 000000007h
tv4  DD 00000000Fh
tv5  DD 00000001Fh
tv6  DD 00000003Fh
tv7  DD 00000007Fh
tv8  DD 0000000FFh
tv9  DD 0000001FFh
tv10 DD 0000003FFh
tv11 DD 0000007FFh
tv12 DD 000000FFFh
tv13 DD 000001FFFh
tv14 DD 000003FFFh
tv15 DD 000007FFFh
tv16 DD 00000FFFFh
tv17 DD 00001FFFFh
tv18 DD 00003FFFFh
tv19 DD 00007FFFFh
tv20 DD 0000FFFFFh
tv21 DD 0001FFFFFh
tv22 DD 0003FFFFFh
tv23 DD 0007FFFFFh
tv24 DD 000FFFFFFh
tv25 DD 001FFFFFFh
tv26 DD 003FFFFFFh
tv27 DD 007FFFFFFh
tv28 DD 00FFFFFFFh
tv29 DD 01FFFFFFFh
tv30 DD 03FFFFFFFh
tv31 DD 07FFFFFFFh
tv32 DD 0FFFFFFFFh

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetUnsignedValue
;
;   Description:    Get unsigned value from report
;
;   Parameters:     ES:EDI      Report data
;                   EDX         Start bit
;                   ECX         Bit count
;
;   Returns:        EAX         Value
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetUnsignedValue_

GetUnsignedValue_   Proc near
    push ecx
    push edx
    push esi
;    
    mov esi,ecx
    mov ecx,edx
    shr edx,3
    and cl,7
    mov eax,es:[edi+edx]
    shr eax,cl
    shl esi,2
    and eax,cs:[esi].tv
;
    pop esi
    pop edx
    pop ecx        
    ret
GetUnsignedValue_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetSignedValue
;
;   Description:    Get signed value from report
;
;   Parameters:     ES:EDI      Report data
;                   EDX         Start bit
;                   ECX         Bit count
;
;   Returns:        EAX         Value
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sv:
sv0  DD 000000000h
sv1  DD 000000001h
sv2  DD 000000002h
sv3  DD 000000004h
sv4  DD 000000008h
sv5  DD 000000010h
sv6  DD 000000020h
sv7  DD 000000040h
sv8  DD 000000080h
sv9  DD 000000100h
sv10 DD 000000200h
sv11 DD 000000400h
sv12 DD 000000800h
sv13 DD 000001000h
sv14 DD 000002000h
sv15 DD 000004000h
sv16 DD 000008000h
sv17 DD 000010000h
sv18 DD 000020000h
sv19 DD 000040000h
sv20 DD 000080000h
sv21 DD 000100000h
sv22 DD 000200000h
sv23 DD 000400000h
sv24 DD 000800000h
sv25 DD 001000000h
sv26 DD 002000000h
sv27 DD 004000000h
sv28 DD 008000000h
sv29 DD 010000000h
sv30 DD 020000000h
sv31 DD 040000000h
sv32 DD 080000000h

    public GetSignedValue_

GetSignedValue_   Proc near
    push ecx
    push edx
    push esi
;    
    mov esi,ecx
    mov ecx,edx
    shr edx,3
    and cl,7
    mov eax,es:[edi+edx]
    shr eax,cl
    shl esi,2
    and eax,cs:[esi].tv
    test eax,cs:[esi].sv
    jz gsvDone
;
    mov edx,cs:[esi].tv
    not edx
    or eax,edx
    
gsvDone:
    pop esi
    pop edx
    pop ecx        
    ret
GetSignedValue_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetHidTableCount
;
;   Description:    Get number of hid tables
;
;   Returns:        EAX         Table entries
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetHidTableCount_

GetHidTableCount_   Proc near
    push ds
    mov eax,SEG data
    mov ds,eax
    movzx eax,ds:hid_table_count
    pop ds
    ret
GetHidTableCount_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HidBegin
;
;   Description:    Begin initialization
;
;   Parameters:     EDI     Table #
;                   FS:ESI  Report struc
;                   GS:EBX  Device
;
;   Returns:        EBX     Handle
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HidBegin_

HidBegin_   Proc near
    push ds
    push edi
;    
    push eax
    mov eax,SEG data
    mov ds,eax
    pop eax
;    
    shl edi,3
    lds edi,ds:[edi].hid_table_arr
    call fword ptr ds:[edi].hid_begin_proc
;
    pop edi    
    pop ds
    ret
HidBegin_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HidDefine
;
;   Description:    Define entry
;
;   Parameters:     EDI     Table #
;                   EBX     Handle
;                   ECX     Usage page
;                   AL      Usage ID low
;                   AH      Usage ID high
;                   EDX     Item params
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HidDefine_

HidDefine_   Proc near
    push ds
    push eax
    push ecx
    push edi
;    
    push eax
    mov eax,SEG data
    mov ds,eax
    pop eax
;    
    shl edi,3
    lds edi,ds:[edi].hid_table_arr
    call fword ptr ds:[edi].hid_define_proc
;
    pop edi    
    pop ecx
    pop eax
    pop ds
    ret
HidDefine_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HidEnd
;
;   Description:    End initialization
;
;   Parameters:     EDI     Table #
;                   EBX     Handle
;
;   Returns:        EAX     = 1, keep
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HidEnd_

HidEnd_   Proc near
    push ds
    push edi
;    
    mov eax,SEG data
    mov ds,eax
;    
    shl edi,3
    lds edi,ds:[edi].hid_table_arr
    call fword ptr ds:[edi].hid_end_proc
    jc heFail

heOk:
    mov eax,1
    jmp heDone

heFail:
    xor eax,eax

heDone:    
    pop edi    
    pop ds
    ret
HidEnd_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HidClose
;
;   Description:    Close hid
;
;   Parameters:     EDI     Table #
;                   EBX     Handle
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HidClose_

HidClose_   Proc near
    push ds
    push edi
;    
    mov eax,SEG data
    mov ds,eax
;    
    shl edi,3
    lds edi,ds:[edi].hid_table_arr
    call fword ptr ds:[edi].hid_close_proc
;    
    pop edi    
    pop ds
    ret
HidClose_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HidHandleReport
;
;   Description:    Handle report
;
;   Parameters:     EDI     Table #
;                   EBX     Handle
;                   FS:ESI  Report data
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HidHandleReport_

HidHandleReport_   Proc near
    push ds
    push edi
;    
    push eax
    mov eax,SEG data
    mov ds,eax
    pop eax
;    
    shl edi,3
    lds edi,ds:[edi].hid_table_arr
    call fword ptr ds:[edi].hid_handle_report_proc
;
    pop edi    
    pop ds
    ret
HidHandleReport_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateOutputReport
;
;   Description:    Create output report
;
;   Parameters:     FS:ESI  Device
;                   BX      Report ID
;                   CX      Report size
;
;   Returns:        EAX     Handle
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateOutputReport_

CreateOutputReport_   Proc near
    push es
    push ecx
    push edi
;    
    movzx eax,cx
    add eax,4
    add eax,OFFSET ho_buf
    AllocateSmallGlobalMem
;
    mov es:ho_dev,fs
    mov es:ho_size,cx
;
    push ecx
    movzx ecx,cx
    mov edi,OFFSET ho_buf
    xor al,al
    rep stosb    
    pop ecx
;
    mov es:ho_req_type,21h
    mov es:ho_req,9
    mov es:ho_report_id,bl
    mov es:ho_report_type,2
    movzx ax,fs:hid_interface
    mov es:ho_interface,ax
    mov es:ho_report_len,cx
;
    mov eax,es    
;
    pop edi
    pop ecx
    pop es
    ret
CreateOutputReport_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           FreeOutputReport
;
;   Description:    Free output report
;
;   Parameters:     EBX     Handle
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeOutputReport_

FreeOutputReport_   Proc near
    push es
    mov es,ebx
    FreeMem
    pop es
    ret
FreeOutputReport_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetValue
;
;   Description:    Set output value
;
;   Parameters:     EBX     Handle
;                   EDX     Start bit
;                   ECX     Bit count
;                   EAX     Value
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetValue_

SetValue_   Proc near
    push es
    pushad
;    
    mov es,ebx
    mov edi,OFFSET ho_buf
;
    mov esi,ecx
    mov ecx,edx
    shr edx,3
    and cl,7
    shl esi,2
;    
    and eax,cs:[esi].tv
    shl eax,cl
;
    mov ebx,cs:[esi].tv
    not ebx
    rol ebx,cl
    and ebx,es:[edi+edx]
    or eax,ebx
    mov es:[edi+edx],eax
;
    popad
    pop es
    ret
SetValue_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SendOutputReport
;
;   Description:    Send output report
;
;   Parameters:     EBX     Handle
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SendOutputReport_

SendOutputReport_   Proc near
    push ds
    push es
    pushad
;   
    mov es,ebx
    mov ds,es:ho_dev
    mov bx,ds:hid_control_handle
;
    mov edi,OFFSET ho_req_type
    mov ecx,8
    WriteUsbControl
;
    mov edi,OFFSET ho_buf
    mov cx,ds:ho_size
    WriteUsbData
;    
    ReqUsbStatus
    StartUsbTransaction
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:hid_control_wait
    WaitWithTimeout
;    
    mov bx,ds:hid_control_handle
    WasUsbTransactionOk
;
    popad
    pop es
    pop ds    
    ret
SendOutputReport_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetReportDescr
;
;   Description:    Get report descriptor
;
;   Parameters:     FS:ESI      Hid device
;                   ES:EDI      Buffer
;                   ECX         Size
;                   EDX         Interface
;
;   Returns:        EAX         Read size
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetReportDescr_

GetReportDescr_   Proc near
    push ebx
    push ecx
    push edx
    push ebp
;    
    push es
    push ecx
    push edi
;   
    mov eax,8
    AllocateSmallGlobalMem
    mov es:usd_type,81h
    mov es:usd_req,6
    mov es:usd_value,2200h
    mov es:usd_index,dx
    mov es:usd_len,cx
    xor edi,edi
    mov ebp,es
    mov bx,fs:[esi].hid_control_handle
;
    mov ecx,8
    WriteUsbControl
;    
    pop edi
    pop ecx
    pop es
;
    ReqUsbData
;    
    WriteUsbStatus
    StartUsbTransaction
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,fs:[esi].hid_control_wait
    WaitWithTimeout
;    
    mov bx,fs:[esi].hid_control_handle
    WasUsbTransactionOk
    jc grdFail
;
    GetUsbDataSize
    jmp grdUnlock

grdFail:
    xor eax,eax
    
grdUnlock:    
    push es
    mov es,ebp
    FreeMem
    pop es
;
    pop ebp
    pop edx
    pop ecx
    pop ebx
    ret
GetReportDescr_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetHidProtocol
;
;       Description:    Set HID protocol
;
;       Paramters:      FS      HID selector
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetHidProtocol   Proc near
    push es
    push eax
    push ebx
    push ecx
    push edx
    push edi
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,21h
    mov es:usd_req,0Bh
    mov es:usd_value,1
    movzx ax,fs:hid_interface
    mov es:usd_index,ax
    mov es:usd_len,0
    xor di,di
    mov bx,fs:hid_control_handle
;
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    StartUsbTransaction
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,fs:hid_control_wait
    WaitWithTimeout
;    
    mov bx,fs:hid_control_handle
    WasUsbTransactionOk
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
SetHidProtocol Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       SetIdle
;
;       Description:    Set idle value
;
;       Paramters:      FS      HID selector
;                       EBX     Report ID
;                       EAX     Idle time
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetIdle_
    
SetIdle_   Proc near
    push es
    push eax
    push ebx
    push ecx
    push edx
    push edi
;    
    mov ah,al
    mov al,bl
    push ax
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,21h
    mov es:usd_req,0Ah
    pop ax
    mov es:usd_value,ax
    movzx ax,fs:hid_interface
    mov es:usd_index,ax
    mov es:usd_len,0
    xor di,di
    mov bx,fs:hid_control_handle
;
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    StartUsbTransaction
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,fs:hid_control_wait
    WaitWithTimeout
;    
    mov bx,fs:hid_control_handle
    WasUsbTransactionOk
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
SetIdle_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       OpenHidDev
;
;           description:    Open hid descriptor
;
;           Parameters:     FS:ESI      Dev
;                           ES:EDI      First interface descriptor for device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public OpenHidDev_

OpenHidDev_ Proc near
    push ax
    push bx
    push dx
    push esi
    push edi
;
    xor esi,esi
    mov fs:hid_intr_in,0
    mov fs:hid_interface,0
    mov fs:hid_protocol,0
    mov fs:hid_country_code,0
    mov fs:hid_descr_count,0
;
    GetThread
    movzx eax,ax
    mov fs:hid_thread,eax

ihsCheckClass:
    mov esi,edi
    mov al,es:[edi].uid_sub_class
    cmp al,1
    jne ihsCheckNext
    jmp ihsFound

ihsCheckLoop: 
    mov al,es:[edi].ucd_type
    cmp al,4
    jne ihsCheckNext
;    
    mov al,es:[edi].uid_class
    cmp al,3
    je ihsCheckClass

ihsCheckNext:
    movzx ecx,es:[edi].ucd_len
    add edi,ecx
    cmp di,es:ucd_size
    jb ihsCheckLoop
;
    or si,si
    je ihsDone
;
    mov edi,esi    

ihsFound:
    mov al,es:[edi].uid_id
    mov fs:hid_interface,al
    mov al,es:[edi].uid_proto
    mov fs:hid_protocol,al

ihsDescrLoop:    
    movzx cx,es:[edi].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jnb ihsDone
;    
    mov al,es:[edi].ucd_type
    cmp al,21h
    je ihsHidDescr
;      
    cmp al,5
    je ihsEndDescr
;
    jmp ihsDone

ihsHidDescr:
    mov al,es:[edi].uhd_country_code
    mov fs:hid_country_code,al
    mov al,es:[edi].uhd_descr_count
    mov fs:hid_descr_count,al    
    jmp ihsDescrLoop

ihsEndDescr:    
    mov al,es:[edi].ued_attrib
    and al,3
    cmp al,3
    jne ihsDescrLoop
;
    mov al,es:[edi].ued_address
    test al,80h
    jz ihsDescrLoop
;
    and al,8Fh    
    mov fs:hid_intr_in,al    
    jmp ihsDescrLoop

ihsDone:    
    mov bx,fs:hid_controller
    mov al,fs:hid_device
    xor dl,dl
    OpenUsbPipe
    mov fs:hid_control_handle,bx
;
    CreateWait
    mov fs:hid_control_wait,bx
;    
    mov fs:hid_intr_handle,0
    mov fs:hid_intr_size,0
    mov fs:hid_intr_req,0
;
    call SetHidProtocol

ihsEnd:
    pop edi
    pop esi
    pop dx
    pop bx
    pop ax
    ret
OpenHidDev_  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       CloseHidDev
;
;           description:    Close hid descriptor
;
;           Parameters:     FS:ESI      Dev
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CloseHidDev_

CloseHidDev_ Proc near
    push ds
    push eax
    push ebx
;
    mov bx,fs:hid_control_handle
    CloseUsbPipe    
;
    mov bx,fs:hid_intr_handle
    CloseUsbPipe    
;    
    mov bx,fs:hid_control_wait
    CloseWait
;    
    mov bx,fs:hid_intr_req
    CloseUsbReq
    mov fs:hid_intr_req,0
    mov fs:hid_intr_buf,0
;
    mov bx,fs:hid_intr_handle
    CloseUsbPipe    
    mov fs:hid_intr_handle,0
;   
    mov fs:hid_intr_buf,0
    mov fs:hid_control_handle,0
    mov fs:hid_control_wait,0
;
    pop ebx
    pop eax
    pop ds
    ret
CloseHidDev_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       OpenIntrPipe
;
;           description:    Open intr pipe and req
;
;           Parameters:     FS:ESI      Dev
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public OpenIntrPipe_

OpenIntrPipe_ Proc near
    push es
    pushad
;    
    mov bx,fs:hid_controller
    mov al,fs:hid_device
    mov dl,fs:hid_intr_in
    OpenUsbPipe
    mov fs:hid_intr_handle,bx
;
    CreateUsbReq
    mov fs:hid_intr_req,bx
;
    mov cx,fs:hid_intr_size
    mov ax,4
    AddReadUsbDataReq
    mov fs:hid_intr_buf,es
;
    popad
    pop es
    ret
OpenIntrPipe_   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_attach
;
;           description:    USB attach callback
;
;           Parameters:     BX      Controller #
;               AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern CreateHid:near

usb_attach  Proc far
    push ds
    push es
    pushad
;    
    push ax
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop ax
    xor edi,edi
    push ax
    GetUsbDevice
    cmp ax,cx
    pop ax
    jne uaFail
;
    mov cl,es:udd_class
    or cl,cl
    je uaPossibleHid
;    
    cmp cl,3
    jne uaFail

uaPossibleHid:
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz uaFail
;
    mov dl,es:ucd_config_id
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaCheckLoop:
    mov cl,es:[di].ucd_type
    cmp cl,4
    jne uaCheckNext
;    
    mov cl,es:[di].uid_class
    cmp cl,3
    je uaFound

uaCheckNext:
    movzx cx,es:[di].ucd_len
    or cx,cx
    jz uaFail
;    
    add di,cx
    cmp di,es:ucd_size
    jb uaCheckLoop

uaFail:
    FreeMem    
    jmp uaDone

uaFound:
    ConfigUsbDevice
    
    movzx eax,al
    movzx ebx,bx
    call CreateHid

uaDone:
    popad
    pop es
    pop ds
    ret
usb_attach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_detach
;
;           description:    USB detach callback
;
;           Parameters:     BX      Controller #
;               AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern RemoveHid:near

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    xor ecx,ecx
    mov es,ecx
;    
    movzx eax,al
    movzx ebx,bx
    call RemoveHid
;        
    popad
    pop es
    pop ds
    ret
usb_detach  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenHid
;
;       description:    Open HID handle
;
;       parameters:     BX      Controller #
;                       AL      Device address (1..128)
;
;       RETURNS:        BX      HID handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_hid_name DB 'Open HID', 0

    extrn GetHid:near

open_hid    Proc far
    push ds
    push es
    push eax
;    
    push edx
    movzx ebx,bx
    movzx eax,al
    call GetHid
    mov bx,dx
    pop edx
    or bx,bx
    jz open_hid_done
;    
    push bx
    mov cx,SIZE hid_handle_struc
    AllocateHandle
    pop ax
    mov [ebx].hh_hid_sel,ax
    mov [ebx].hh_sign,HID_HANDLE
    mov es,ax
;    
    push bx
    mov bx,es:hid_controller
    mov al,es:hid_device
    xor dl,dl
    OpenUsbPipe
    mov ax,bx
    pop bx
    mov ds:[ebx].hh_control_handle,ax
;
    push bx
    CreateWait
    mov ax,bx
    pop bx
    mov ds:[ebx].hh_control_wait,ax
;
    push bx
    mov ax,ds:[ebx].hh_control_handle
    mov bx,ds:[ebx].hh_control_wait
    movzx ecx,bx
    AddWaitForUsbPipe
    pop bx
;    
    push bx
    mov bx,es:hid_controller
    mov al,es:hid_device
    mov dl,es:hid_intr_in
    OpenUsbPipe
    mov ax,bx
    pop bx
    mov ds:[ebx].hh_intr_handle,ax
;
    push bx
    mov bx,ds:[ebx].hh_intr_handle
    CreateUsbReq
    mov ax,bx
    pop bx
    mov ds:[ebx].hh_intr_req,ax
;
    push bx
    mov bx,ds:[ebx].hh_intr_req
    mov cx,8
    xor ax,ax
    AddReadUsbDataReq
    pop bx
    mov ds:[ebx].hh_intr_buf,es
;    
    push bx
    mov bx,ds:[ebx].hh_intr_req
    GetThread
    xor cx,cx
    StartUsbReq
    pop bx
;    
    mov bx,[ebx].hh_handle   
    clc

open_hid_done:        
    pop eax
    pop es
    pop ds
    ret
open_hid    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseHid
;
;           DESCRIPTION:    Close an HID handle
;
;           PARAMETERS:     BX          HID handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_hid_name     DB 'Close HID',0

close_hid  Proc far
    push ds
    push ax
    push ebx
;
    mov ax,HID_HANDLE
    DerefHandle
    jc chDone
;
    push bx
    mov bx,ds:[ebx].hh_control_handle
    CloseUsbPipe    
    pop bx
;
    push bx
    mov bx,ds:[ebx].hh_intr_handle
    CloseUsbPipe    
    pop bx
;    
    push bx
    mov bx,ds:[ebx].hh_intr_req
    CloseUsbReq
    pop bx
;    
    FreeHandle
    clc

chDone:
    pop ebx
    pop ax
    pop ds
    ret
close_hid  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetHidPipe
;
;           DESCRIPTION:    Get HID pipe
;
;           PARAMETERS:     BX          HID handle
;
;           RETURNS:        AX          Pipe #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_hid_pipe_name     DB 'Get HID Pipe',0

get_hid_pipe  Proc far
    push ds
    push ebx
;
    mov ax,HID_HANDLE
    DerefHandle
    jc ghpDone
;
    mov ds,[ebx].hh_hid_sel
    mov al,ds:hid_intr_in
    clc

ghpDone:
    pop ebx
    pop ds
    ret
get_hid_pipe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadHid
;
;           DESCRIPTION:    Read HID report
;
;           PARAMETERS:     BX          HID handle
;                           ES:(E)DI    Buffer
;                           CX          Buffer size
;                           EAX         Timeout, ms
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_hid_name     DB 'Read HID',0

read_hid    Proc near
    push fs
    push ecx
    push esi
    push edi
;    
    mov edx,1193
    mul edx
    mov esi,eax

read_hid_loop:
    push bx
    mov bx,ds:[ebx].hh_intr_req
    IsUsbReqReady
    pop bx
    jnc read_hid_get_data
;    
    push cx
    GetSystemTime
    add eax,esi
    adc edx,0
    WaitForSignalWithTimeout
    pop cx
;    
    push bx
    mov bx,ds:[ebx].hh_intr_req
    IsUsbReqReady
    pop bx
    jc read_hid_fail

read_hid_get_data:    
    push es
    push bx
    push cx
;    
    mov bx,ds:[ebx].hh_intr_req
    GetUsbReqData
;
    mov ax,cx
    pop cx
    pop bx
    pop es
    jc read_hid_fail
;
    cmp ax,8
    stc
    jnz read_hid_done
;    
    mov fs,ds:[ebx].hh_intr_buf
    mov eax,fs:[0]
    stos dword ptr es:[edi]
    mov eax,fs:[4]
    stos dword ptr es:[edi]
;    
    push es
    push bx
    push cx
;
    mov bx,ds:[ebx].hh_intr_req
    GetThread
    xor cx,cx
    StartUsbReq
;    
    pop cx
    pop bx
    pop es
;
    sub cx,8
    ja read_hid_loop
;
    clc    
    jmp read_hid_done

read_hid_fail:    
    push bx
    mov bx,ds:[ebx].hh_intr_req
    IsUsbReqStarted
    pop bx
    jnc read_hid_fail_done
;
    push es
    push bx
    push cx
;    
    mov bx,ds:[ebx].hh_intr_req
    GetThread
    xor cx,cx
    StartUsbReq
;    
    pop cx
    pop bx
    pop es

read_hid_fail_done:
    stc

read_hid_done:
    pop edi
    pop esi
    pop ecx
    pop fs
    ret
read_hid    Endp

read_hid16  Proc far
    push ds
    push eax
    push ebx
    push edx
    push edi
;
    push eax
    mov ax,HID_HANDLE
    DerefHandle
    pop eax
    jc rdDone16
;
    movzx edi,di
    call read_hid

rdDone16:
    pop edi
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
read_hid16  Endp

read_hid32  Proc far
    push ds
    push eax
    push ebx
    push edx
;
    push eax
    mov ax,HID_HANDLE
    DerefHandle
    pop eax
    jc rdDone32
;
    call read_hid

rdDone32:
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
read_hid32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteHid
;
;           DESCRIPTION:    Write HID report
;
;           PARAMETERS:     BX          HID handle
;                           ES:(E)DI    Buffer
;                           CX          Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_hid_name     DB 'Write HID',0

write_hid    Proc near
    push ecx
    push edi

write_hid_loop:
    push cx
;    
    push es
    push edi 
;    
    mov eax,8
    AllocateSmallGlobalMem
;
    mov es:usd_type,21h
    mov es:usd_req,9
    mov es:usd_value,200h
    mov es:usd_index,0
    mov es:usd_len,8
;    
    xor edi,edi
    mov ecx,8
    push bx
    mov bx,ds:[ebx].hh_control_handle
    WriteUsbControl
    pop bx
    FreeMem
;
    pop edi
    pop es    
;
    push bx
    mov bx,ds:[ebx].hh_control_handle
    mov ecx,8
    WriteUsbData
    ReqUsbStatus
    StartUsbTransaction
    pop bx
;    
    push bx
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:[ebx].hh_control_wait
    WaitWithTimeout
    pop bx
;    
    pop cx
;
    add edi,8
    sub cx,8
    ja write_hid_loop
;
    clc

write_hid_done:    
    pop edi
    pop ecx    
    ret
write_hid    Endp

write_hid16  Proc far
    push ds
    push fs
    push eax
    push ebx
    push edx
    push edi
;
    push eax
    mov ax,HID_HANDLE
    DerefHandle
    pop eax
    jc wrDone16
;
    movzx edi,di
    call write_hid

wrDone16:
    pop edi
    pop edx
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
write_hid16  Endp

write_hid32  Proc far
    push ds
    push fs
    push eax
    push ebx
    push edx
;
    push eax
    mov ax,HID_HANDLE
    DerefHandle
    pop eax
    jc wrDone32
;
    call write_hid

wrDone32:
    pop edx
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
write_hid32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    BX       HID handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push ax
    push ebx
;
    mov ax,HID_HANDLE
    DerefHandle
    jc delete_handle_done
;
    FreeHandle
    clc

delete_handle_done:
    pop ebx
    pop ax
    pop ds
    ret
delete_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           register_hid_input
;
;           DESCRIPTION:    Register HID input
;
;           PARAMETERS:     ES:EDI      Callback table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_hid_input_name     DB 'Register HID Input',0

register_hid_input  Proc far
    push ds
    push ebx
;
    mov ebx,SEG data
    mov ds,ebx
    movzx ebx,ds:hid_table_count
    shl ebx,3
    mov ds:[ebx].hid_table_arr,edi
    mov ds:[ebx+4].hid_table_arr,es
    inc ds:hid_table_count
;    
    pop ebx
    pop ds
    ret
register_hid_input  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitForReport
;
;       description:    Wait for report
;
;       parameters:     FS:ESI      Device
;
;       RETURNS:        ES:EDI      Report data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WaitForReport_

WaitForReport_    Proc near
    push ds
    push bx
;
    mov bx,fs:hid_intr_req
    GetThread
    StartUsbReq
    WaitForSignal
;       
    IsUsbReqReady
    jc wfrFail
;    
    GetUsbReqData
    jnc wfrOk

wfrFail:
    xor edi,edi
    mov es,edi
    jmp wfrDone

wfrOk:    
    mov es,fs:hid_intr_buf
    xor edi,edi

wfrDone:
    pop bx
    pop ds
    ret
WaitForReport_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitHid_

InitHid_    Proc near
    push ds
    push es
    pushad
;       
    mov eax,SEG data
    mov ds,eax
    mov ds:hid_table_count,0
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov ax,HID_HANDLE
    mov edi,OFFSET delete_handle
    RegisterHandle
;
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
;
    mov esi,OFFSET register_hid_input
    mov edi,OFFSET register_hid_input_name
    xor dx,dx
    mov ax,register_hid_input_nr
    RegisterOsGate
;
    mov esi,OFFSET open_hid
    mov edi,OFFSET open_hid_name
    xor dx,dx
    mov ax,open_hid_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_hid
    mov edi,OFFSET close_hid_name
    xor dx,dx
    mov ax,close_hid_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_hid_pipe
    mov edi,OFFSET get_hid_pipe_name
    xor dx,dx
    mov ax,get_hid_pipe_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET read_hid16
    mov esi,OFFSET read_hid32
    mov edi,OFFSET read_hid_name
    mov dx,virt_es_in
    mov ax,read_hid_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_hid16
    mov esi,OFFSET write_hid32
    mov edi,OFFSET write_hid_name
    mov dx,virt_es_in
    mov ax,write_hid_nr
    RegisterUserGate
    clc
;
    popad
    pop es
    pop ds    
    ret
InitHid_    Endp

code    ENDS

    END
