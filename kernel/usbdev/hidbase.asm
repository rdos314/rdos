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
; HIDBASE.ASM
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

hid_output_struc        STRUC

h_dev          DW ?
h_size         DW ?
h_req_type     DB ?
h_req          DB ?
h_report_id    DB ?
h_report_type  DB ?
h_interface    DW ?
h_report_len   DW ?
h_buf          DB ?

hid_output_struc        ENDS

MAX_TABLES  = 32
MAX_CUSTOM  = 16

data    SEGMENT byte public 'DATA'

hid_table_count DW ?

hid_table_arr   DD 2 * MAX_TABLES DUP(?)

hid_custom_count DW ?

hid_custom_arr   DD 2 * MAX_CUSTOM DUP(?)

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
    add eax,OFFSET h_buf
    AllocateSmallGlobalMem
;
    mov es:h_dev,fs
    mov es:h_size,cx
;
    push ecx
    movzx ecx,cx
    mov edi,OFFSET h_buf
    xor al,al
    rep stosb    
    pop ecx
;
    mov es:h_req_type,21h
    mov es:h_req,9
    mov es:h_report_id,bl
    mov es:h_report_type,2
    movzx ax,fs:hid_interface
    mov es:h_interface,ax
    mov es:h_report_len,cx
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
;   NAME:           CreateFeatureReport
;
;   Description:    Create feature report
;
;   Parameters:     FS:ESI  Device
;                   BX      Report ID
;                   CX      Report size
;
;   Returns:        EAX     Handle
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateFeatureReport_

CreateFeatureReport_   Proc near
    push es
    push ecx
    push edi
;    
    movzx eax,cx
    add eax,4
    add eax,OFFSET h_buf
    AllocateSmallGlobalMem
;
    mov es:h_dev,fs
    mov es:h_size,cx
;
    push ecx
    movzx ecx,cx
    mov edi,OFFSET h_buf
    xor al,al
    rep stosb    
    pop ecx
;
    mov es:h_req_type,21h
    mov es:h_req,9
    mov es:h_report_id,bl
    mov es:h_report_type,3
    movzx ax,fs:hid_interface
    mov es:h_interface,ax
    mov es:h_report_len,cx
;
    mov eax,es    
;
    pop edi
    pop ecx
    pop es
    ret
CreateFeatureReport_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           FreeReport
;
;   Description:    Free report
;
;   Parameters:     EBX     Handle
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeReport_

FreeReport_   Proc near
    push es
    mov es,ebx
    FreeMem
    pop es
    ret
FreeReport_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetReportSize
;
;   Description:    Get report size
;
;   PARAMETERS:     EBX     Handle
;
;   RETURNS:        ECX     Size
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetReportSize_

GetReportSize_   Proc near
    push es
;    
    mov es,ebx
    movzx ecx,es:h_size
;
    pop es
    ret
GetReportSize_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetReportBuf
;
;   Description:    Get report buf
;
;   PARAMETERS:     EBX     Handle
;
;   RETURNS:        ES:EDI  Buffer pointer
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetReportBuf_

GetReportBuf_   Proc near
    mov es,ebx
    mov edi,OFFSET h_buf
    ret
GetReportBuf_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetReportValue
;
;   Description:    Set output value
;
;   Parameters:     EBX     Handle
;                   EDX     Start bit
;                   ECX     Bit count
;                   EAX     Value
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetReportValue_

SetReportValue_   Proc near
    push es
    pushad
;    
    mov es,ebx
    mov edi,OFFSET h_buf
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
SetReportValue_ Endp

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
    mov ds,es:h_dev
    mov bx,ds:hid_device_handle
    mov edi,OFFSET h_req_type
    mov al,es:[edi].usd_req
    mov ah,es:[edi].usd_type
    mov dx,es:[edi].usd_value
    mov si,es:[edi].usd_index
    mov cx,es:[edi].usd_len
    mov edi,OFFSET h_buf
    SendUsbDeviceControlMsg
;
    popad
    pop es
    pop ds    
    ret
SendOutputReport_ Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ReadFeatureReport
;
;   Description:    Read feature report
;
;   Parameters:     EBX     Handle
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadFeatureReport_

ReadFeatureReport_   Proc near
    push ds
    push es
    pushad
;   
    mov es,ebx
    mov ds,es:h_dev
    mov bx,ds:hid_device_handle
    mov edi,OFFSET h_req_type
    mov al,1
    mov ah,0A1h
    mov dx,es:[edi].usd_value
    mov si,es:[edi].usd_index
    mov cx,es:[edi].usd_len
    mov edi,OFFSET h_buf
    SendUsbDeviceControlMsg
;
    popad
    pop es
    pop ds    
    ret
ReadFeatureReport_ Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WriteFeatureReport
;
;   Description:    Write feature report
;
;   Parameters:     EBX     Handle
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteFeatureReport_

WriteFeatureReport_   Proc near
    push ds
    push es
    pushad
;   
    mov es,ebx
    mov ds,es:h_dev
    mov bx,ds:hid_device_handle
    mov edi,OFFSET h_req_type
    mov al,9
    mov ah,21h
    mov dx,es:[edi].usd_value
    mov si,es:[edi].usd_index
    mov cx,es:[edi].usd_len
    mov edi,OFFSET h_buf
    SendUsbDeviceControlMsg
;
    popad
    pop es
    pop ds    
    ret
WriteFeatureReport_ Endp

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
    push esi
;    
    mov bx,fs:hid_device_handle
    mov ah,81h
    mov al,6
    mov si,dx
    mov dx,2200h
    SendUsbDeviceControlMsg
    jc grdFail
;
    movzx eax,cx
    jmp grdDone

grdFail:
    xor eax,eax

grdDone:
    pop esi
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
    push esi
    push edi
;    
    mov bx,fs:hid_device_handle
    mov ah,21h
    mov al,0Bh
    mov dx,1
    movzx si,fs:hid_interface
    xor cx,cx
    SendUsbDeviceControlMsg
;
    pop edi
    pop esi
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
    mov bx,fs:hid_device_handle
    mov dx,ax
    mov ah,21h
    mov al,0Ah
    movzx si,fs:hid_interface
    xor cx,cx
    SendUsbDeviceControlMsg
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
;
    mov ax,es:[edi].ued_maxsize
    mov fs:hid_pipe_size,ax
    jmp ihsDescrLoop

ihsDone:    
    mov bx,fs:hid_controller
    mov al,fs:hid_port
    OpenUsbDevice
    mov fs:hid_device_handle,bx
;    
    mov fs:hid_intr_wait,0
    mov fs:hid_intr_size,0
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
    mov bx,fs:hid_device_handle
    CloseUsbDevice    
;
    mov bx,fs:hid_intr_wait
    CloseWait
;   
    push es
    mov es,fs:hid_intr_buf
    FreeMem
    pop es
;
    mov fs:hid_intr_buf,0
    mov fs:hid_device_handle,0
    mov fs:hid_control_wait,0
    mov fs:hid_intr_wait,0
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
    mov cx,fs:hid_pipe_size
    mov ax,fs:hid_intr_size
    xor dx,dx
    div cx
    add ax,8
    mov cx,ax
    mov bx,fs:hid_device_handle
    mov dl,fs:hid_intr_in
    mov ax,5
    OpenUsbPacketPipe
;
    CreateWait
    mov fs:hid_intr_wait,bx
;
    mov ax,fs:hid_device_handle
    mov dl,fs:hid_intr_in
    mov ecx,fs
    AddWaitForUsbDevicePipe
;
    movzx eax,fs:hid_intr_size
    add eax,10h
    AllocateSmallGlobalMem
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
;                           AL      Port
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
    push ax
    ConfigUsbDevice
    pop ax
;
    movzx edx,al
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
;                           AL      Port #
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
;           NAME:           register_custom_hid
;
;           DESCRIPTION:    Register custom HID
;
;           PARAMETERS:     ES:EDI      Callback procedure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_custom_hid_name     DB 'Register Custom HID',0

register_custom_hid  Proc far
    push ds
    push ebx
;
    mov ebx,SEG data
    mov ds,ebx
    movzx ebx,ds:hid_custom_count
    shl ebx,3
    mov ds:[ebx].hid_custom_arr,edi
    mov ds:[ebx+4].hid_custom_arr,es
    inc ds:hid_custom_count
;    
    pop ebx
    pop ds
    ret
register_custom_hid  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           reset_hid
;
;           DESCRIPTION:    Reset hid device
;
;           parameters:     BX      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_hid_name     DB 'Reset HID',0

reset_hid  Proc far
    push ds
    push ebx
;
    mov ds,ebx
    mov bx,ds:hid_device_handle
    ResetUsbDevice
;
    pop ebx
    pop ds
    ret
reset_hid  Endp

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
;           NAME:           GetHidDevice
;
;           DESCRIPTION:    Get HID usb device
;
;           PARAMETERS:     EAX         Device #
;
;           RETURNS:        BX          USB controller
;                           AL          USB port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_hid_device_name     DB 'Register HID Input',0

    extern GetHidController:near
    extern GetHidPort:near

get_hid_device  Proc far
    push eax
    call GetHidController
    mov ebx,eax
    cmp eax,-1
    pop eax
    stc
    jz ghdDone
;
    call GetHidPort
    clc

ghdDone:
    ret
get_hid_device  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsHidConnected
;
;       description:    Is HID connected?
;
;       parameters:     FS:ESI      Device
;
;       RETURNS:        EAX         Connected = 1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public IsHidConnected_

IsHidConnected_    Proc near
    push bx
;
    mov bx,fs:hid_device_handle
    IsUsbDeviceConnected
    jc ihcFail
;
    mov eax,1
    jmp ihcDone

ihcFail:
    xor eax,eax

ihcDone:
    pop bx
    ret
IsHidConnected_   Endp

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


    extern HidGetReportSize:near

    public WaitForReport_

WaitForReport_    Proc near
    push ds
    push ebx
    push edx
    push esi
;
    mov bx,fs:hid_intr_wait
    WaitWithoutTimeout
;
    mov es,fs:hid_intr_buf
    xor edi,edi
;
    mov bx,fs:hid_device_handle
    IsUsbDeviceConnected
    jc wfrFail
;
    mov bx,fs:hid_device_handle
    mov dl,fs:hid_intr_in
    GetUsbPacketPipe
    jc wfrFail
;
    push ecx
    movzx ebx,es:[edi]
    mov edx,fs
    mov es,edx
    mov edi,esi
    call HidGetReportSize
    mov esi,ecx
    pop ecx
;
    or esi,esi
    jz wfrFail
;
    dec esi
    shr esi,3
    inc esi
;
    cmp si,cx
    jbe wfrOk
;
    mov es,fs:hid_intr_buf
    xor edi,edi
    jmp wfrHandle

wfrRead:
    mov bx,fs:hid_device_handle
    IsUsbDeviceConnected
    jc wfrFail
;
    mov bx,fs:hid_device_handle
    mov dl,fs:hid_intr_in
    GetUsbPacketPipe
    jc wfrFail

wfrHandle:
    sub si,cx
    je wfrOk
;
    cmp cx,fs:hid_pipe_size
    jne wfrFail
;
    add di,cx
;
    GetSystemTime
    add eax,1193 * 100
    adc edx,0
    mov bx,fs:hid_intr_wait
    WaitWithTimeout
    jmp wfrRead    

wfrFail:
    xor edi,edi
    mov es,edi
    jmp wfrDone

wfrOk:
    mov es,fs:hid_intr_buf
    xor edi,edi

wfrDone:
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
WaitForReport_    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HasCustomDriver
;
;           DESCRIPTION:    Check for custom driver
;
;           parameters:     FS:ESI      Device
;
;           RETURNS:        EAX         1 = use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HasCustomDriver_

HasCustomDriver_    Proc near
    push ds
    push ebx
    push ecx
;
    mov eax,SEG data
    mov ds,eax
    movzx ecx,ds:hid_custom_count
    or ecx,ecx
    jz hcdFail
;
    mov ebx,OFFSET hid_custom_arr

hcdLoop:
    call fword ptr ds:[ebx]
    jnc hcdOk
;
    add ebx,8
    loop hcdLoop
;
    jmp hcdFail

hcdOk:
    mov eax,1
    jmp hcdDone

hcdFail:
    xor eax,eax

hcdDone:
    pop ecx
    pop ebx
    pop ds
    ret
HasCustomDriver_    Endp

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
    mov ds:hid_custom_count,0
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
    mov esi,OFFSET register_custom_hid
    mov edi,OFFSET register_custom_hid_name
    xor dx,dx
    mov ax,register_custom_hid_nr
    RegisterOsGate
;
    mov esi,OFFSET register_hid_input
    mov edi,OFFSET register_hid_input_name
    xor dx,dx
    mov ax,register_hid_input_nr
    RegisterOsGate
;
    mov esi,OFFSET reset_hid
    mov edi,OFFSET reset_hid_name
    xor dx,dx
    mov ax,reset_hid_nr
    RegisterOsGate
;
    mov esi,OFFSET get_hid_device
    mov edi,OFFSET get_hid_device_name
    xor dx,dx
    mov ax,get_hid_device_nr
    RegisterBimodalUserGate
    clc
;
    popad
    pop es
    pop ds    
    ret
InitHid_    Endp

code    ENDS

    END
