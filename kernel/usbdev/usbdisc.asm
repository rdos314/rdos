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
; usbdisc.ASM
; Implements mass storage class for USB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
INCLUDE ..\os\protseg.def
include ..\usbdev\usb.inc

disc_struc   STRUC

disc_bulk_in_pipe       DB ?
disc_bulk_out_pipe      DB ?

disc_bulk_in_maxsize    DW ?
disc_bulk_out_maxsize   DW ?

disc_bulk_in_handle     DW ?
disc_bulk_out_handle    DW ?

disc_bulk_in_wait       DW ?
disc_bulk_out_wait      DW ?

disc_controller         DW ?
disc_device             DB ?

disc_nr                 DB ?
disc_handle             DW ?

disc_sectors            DD ?

disc_serial             DB ?
disc_vendor             DW ?
disc_prod               DW ?

disc_cbw_sign           DD ?
disc_cbw_tag            DD ?
disc_cbw_transfer_len   DD ?
disc_cbw_flags          DB ?
disc_cbw_lun            DB ?
disc_cbw_cmd_len        DB ?
disc_cbw_cmd_data       DB 10 DUP(?)

disc_csw_sign           DD ?
disc_csw_tag            DD ?
disc_csw_residue        DD ?
disc_csw_status         DB ?

;
; do not reorganize, connected to responses
;

; capacity
disc_cap                DD ?,?

; inquiry
disc_peri               DB ?
disc_removable          DB ?
disc_ver                DB ?
disc_resp_form          DB ?
disc_add_len            DB ?
disc_intq_resv          DB 4 DUP(?)
disc_vendor_str         DB 8 DUP(?)
disc_prod_str           DB 16 DUP(?)
disc_rev_str            DB 4 DUP(?)

; request sense
disc_sense_data         DB 18 DUP(?)
   
disc_struc  ENDS

data    SEGMENT byte public 'DATA'

filler  DB ?

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SendCbw
;
;   DESCRIPTION:    Send CBW
;
;   PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCbw Proc near
    push es
    mov ax,fs
    mov es,ax
;    
    mov bx,fs:disc_bulk_out_handle
    mov edi,OFFSET disc_cbw_sign
    mov ecx,31
    WriteUsbData
    StartUsbTransaction
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,fs:disc_bulk_out_wait
    WaitWithTimeout
;    
    mov bx,fs:disc_bulk_out_handle
    WasUsbTransactionOk
;   
    pop es    
    ret
SendCbw Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ReceiveCsw
;
;   DESCRIPTION:    Receive CSW
;
;   PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveCsw Proc near
    push es
;
    mov ax,fs
    mov es,ax
;    
    mov bx,fs:disc_bulk_in_handle
    mov edi,OFFSET disc_csw_sign
    mov ecx,13
    ReqUsbData
    StartUsbTransaction
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,fs:disc_bulk_in_wait
    WaitWithTimeout
;    
    mov bx,fs:disc_bulk_in_handle
    WasUsbTransactionOk
    jc rcswDone
;
    mov eax,fs:disc_csw_sign
    cmp eax,53425355h
    stc
    jne rcswDone
;
    mov eax,fs:disc_csw_tag
    cmp eax,fs:disc_cbw_tag
    stc
    jne rcswDone
;
    mov al,fs:disc_csw_status
    or al,al
    stc
    jnz rcswDone
;    
    clc

rcswDone:        
    pop es    
    ret
ReceiveCsw Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ReceiveData
;
;   DESCRIPTION:    Receive data
;
;   PARAMETERS:     FS      Disc sel
;                   ES:EDI  Buffer
;                   ECX     Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveData Proc near
    mov bx,fs:disc_bulk_in_handle
    ReqUsbData
    StartUsbTransaction
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,fs:disc_bulk_in_wait
    WaitWithTimeout
;    
    mov bx,fs:disc_bulk_in_handle
    WasUsbTransactionOk
    ret
ReceiveData Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           Inquiry
;
;   DESCRIPTION:    Send inquiry
;
;   PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Inquiry Proc near
    mov fs:disc_cbw_tag,0F000FFFFh
    mov fs:disc_cbw_transfer_len,36
    mov fs:disc_cbw_flags,80h
    mov fs:disc_cbw_cmd_len,6
    mov fs:disc_cbw_cmd_data,12h
    mov fs:disc_cbw_cmd_data+1,0
    mov fs:disc_cbw_cmd_data+2,0
    mov fs:disc_cbw_cmd_data+3,0
    mov fs:disc_cbw_cmd_data+4,36
    mov fs:disc_cbw_cmd_data+5,0
;
    call SendCbw
    jc inqDone
;    
    mov ax,fs
    mov es,ax    
    mov edi,OFFSET disc_peri
    mov ecx,36
    call ReceiveData
    jc inqDone
;    
    call ReceiveCsw

inqDone:
    ret
Inquiry Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           RequestSense
;
;   DESCRIPTION:    Request sense data
;
;   PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RequestSense Proc near
    mov fs:disc_cbw_tag,0E000EEEEh
    mov fs:disc_cbw_transfer_len,18
    mov fs:disc_cbw_flags,80h
    mov fs:disc_cbw_cmd_len,6
    mov fs:disc_cbw_cmd_data,3
    mov fs:disc_cbw_cmd_data+1,0
    mov fs:disc_cbw_cmd_data+2,0
    mov fs:disc_cbw_cmd_data+3,0
    mov fs:disc_cbw_cmd_data+4,18
    mov fs:disc_cbw_cmd_data+5,0
;
    call SendCbw
    jc reqsDone
;    
    mov ax,fs
    mov es,ax    
    mov edi,OFFSET disc_sense_data
    mov ecx,18
    call ReceiveData
    jc reqsDone
;    
    call ReceiveCsw

reqsDone:
    ret
RequestSense Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ReadCapacity
;
;   DESCRIPTION:    Read capacity data
;
;   PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCapacity Proc near
    mov fs:disc_cbw_tag,0D000DDDDh
    mov fs:disc_cbw_transfer_len,8
    mov fs:disc_cbw_flags,80h
    mov fs:disc_cbw_cmd_len,10
    mov fs:disc_cbw_cmd_data,25h
    mov fs:disc_cbw_cmd_data+1,0
    mov fs:disc_cbw_cmd_data+2,0
    mov fs:disc_cbw_cmd_data+3,0
    mov fs:disc_cbw_cmd_data+4,0
    mov fs:disc_cbw_cmd_data+5,0
    mov fs:disc_cbw_cmd_data+6,0
    mov fs:disc_cbw_cmd_data+7,0
    mov fs:disc_cbw_cmd_data+8,0
    mov fs:disc_cbw_cmd_data+9,0
;
    call SendCbw
    jc rcDone
;    
    mov ax,fs
    mov es,ax    
    mov edi,OFFSET disc_cap
    mov ecx,8
    call ReceiveData
    jc rcDone
;    
    call ReceiveCsw
    jc rcDone
;
    mov eax,fs:disc_cap+4
    xchg al,ah
    rol eax,16
    xchg al,ah
    cmp eax,200h
    stc
    jnz rcDone
;    
    mov eax,fs:disc_cap
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov fs:disc_sectors,eax
    clc

rcDone:
    ret
ReadCapacity Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ReadSector
;
;   DESCRIPTION:    Read sector
;
;   PARAMETERS:     FS      Disc sel
;                   ES:EDI  Buffer
;                   EDX     Sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector Proc near
    push es
    pushad
;    
    mov ecx,200h
    mov fs:disc_cbw_tag,edx
    mov fs:disc_cbw_transfer_len,ecx
    mov fs:disc_cbw_flags,80h
    mov fs:disc_cbw_cmd_len,10
    mov fs:disc_cbw_cmd_data,28h
    mov fs:disc_cbw_cmd_data+1,0
;
    mov eax,edx
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov dword ptr fs:disc_cbw_cmd_data+2,eax
;
    mov fs:disc_cbw_cmd_data+6,0
;
    mov ax,1
    xchg al,ah    
    mov word ptr fs:disc_cbw_cmd_data+7,ax
;
    mov fs:disc_cbw_cmd_data+9,0
;
    push edi
    call SendCbw
    pop edi
    jc rsDone
;    
    mov ecx,200h
    call ReceiveData
    jc rsDone
;    
    call ReceiveCsw

rsDone:
    popad
    pop es
    ret
ReadSector Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UsbDiscThread
;
;           DESCRIPTION:    Disc handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_thread:
    mov fs,bx
    mov fs:disc_cbw_sign,43425355h
    mov fs:disc_cbw_lun,0
;
    mov bx,fs:disc_controller
    movzx ax,fs:disc_device
    mov dl,fs:disc_bulk_in_pipe
    OpenUsbPipe
    mov fs:disc_bulk_in_handle,bx
;
    CreateWait
    mov fs:disc_bulk_in_wait,bx
;    
    mov ax,fs:disc_bulk_in_handle
    mov bx,fs:disc_bulk_in_wait
    movzx ecx,bx
    AddWaitForUsbPipe
;
    mov bx,fs:disc_controller
    movzx ax,fs:disc_device
    mov dl,fs:disc_bulk_out_pipe
    OpenUsbPipe
    mov fs:disc_bulk_out_handle,bx
;
    CreateWait
    mov fs:disc_bulk_out_wait,bx
;    
    mov ax,fs:disc_bulk_out_handle
    mov bx,fs:disc_bulk_out_wait
    movzx ecx,bx
    AddWaitForUsbPipe
;
    call Inquiry    
    jc dtEnd
;    
    call RequestSense
    jc dtEnd
;
    call ReadCapacity
    jc dtEnd
;
    int 3    
    mov bx,fs
    mov ecx,10000h
    InstallDisc
    mov fs:disc_nr,al
    mov fs:disc_handle,bx
;
    mov eax,1000h
    AllocateBigLinear
    mov ax,flat_sel
    mov es,ax
    mov edi,edx    
    xor edx,edx
    call ReadSector

dtEnd: 
    int 3   
           
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
;   NAME:           usb_attach
;
;   description:    USB attach callback
;
;   Parameters:     BX      Controller #
;                   AL      Device address
;                   DS      USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_name    DB 'Usb Disc ', 0

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
    xor di,di
    push ax
    GetUsbDevice
    cmp ax,cx
    pop ax
    jne uaFail
;
    mov cx,es:udd_vendor
    push cx
    mov cx,es:udd_prod
    push cx
    movzx cx,es:udd_num
    push cx
;    
    mov cl,es:udd_class
    or cl,cl
    je uaPossible
;    
    cmp cl,8
    jne uaFailPop

uaPossible:
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz uaFailPop
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
    cmp cl,8
    je uaFound

uaCheckNext:
    movzx cx,es:[di].ucd_len
    or cx,cx
    jz uaFailPop
;    
    add di,cx
    cmp di,es:ucd_size
    jb uaCheckLoop

uaFailPop:
    pop cx    
    pop cx    
    pop cx    

uaFail:
    FreeMem    
    jmp uaDone

uaFound:
    mov cl,es:[di].uid_sub_class
    cmp cl,6
    jne uaFail
;
    mov cl,es:[di].uid_proto
    cmp cl,50h
    jne uaFail
;        
    ConfigUsbDevice
;
    push es
    push eax
    mov eax,SIZE disc_struc
    AllocateSmallGlobalMem
    pop eax
    mov es:disc_controller,bx
    mov es:disc_device,al
    mov ax,es
    mov gs,ax
    pop es
;
    pop cx
    mov gs:disc_serial,cl
;
    pop cx
    mov gs:disc_prod,cx
;
    pop cx
    mov gs:disc_vendor,cx
;        
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne uaDescrNext
;
    mov cl,es:[di].ued_address
    test cl,80h    
    jnz uaBulkIn

uaDescrBulkOut:
    and cl,0Fh
    mov gs:disc_bulk_out_pipe,cl
    mov bx,es:[di].ued_maxsize
    mov gs:disc_bulk_out_maxsize,bx
    jmp uaDescrNext

uaBulkIn:
    and cl,8Fh
    mov gs:disc_bulk_in_pipe,cl
    mov bx,es:[di].ued_maxsize
    mov gs:disc_bulk_in_maxsize,bx
    
uaDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb uaDescrLoop    

uaDescrDone:
    xor di,di
    mov si,OFFSET disc_name

uaCopyDev:
    mov al,cs:[si]
    inc si
    or al,al
    jz uaCopyDone
;
    stosb
    jmp uaCopyDev

uaCopyDone:
    mov ax,gs:disc_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,gs:disc_device
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;    
    mov bx,gs
    xor di,di
;    
    mov dx,cs
    mov ds,dx
    mov esi,OFFSET disc_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    FreeMem

uaDone:    
    popad
    pop es
    pop ds
    retf32
usb_attach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           usb_detach
;
;   description:    USB detach callback
;
;   Parameters:     BX      Controller #
;                   AL      Device address
;                   DS      USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    push gs
    pushad
    
udDone:    
    popad
    pop gs
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
    mov ds,bx
;       
    mov ax,cs
    mov ds,ax
    mov es,ax
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
