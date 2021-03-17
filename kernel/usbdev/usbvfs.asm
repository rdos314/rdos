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

MAX_DISCS   = 16

drive_struc STRUC

drive_nr                DB ?

drive_struc ENDS

cbw_struc   STRUC

disc_cbw_sign           DD ?
disc_cbw_tag            DD ?
disc_cbw_transfer_len   DD ?
disc_cbw_flags          DB ?
disc_cbw_lun            DB ?
disc_cbw_cmd_len        DB ?
disc_cbw_cmd_data       DB 16 DUP(?)

cbw_struc  ENDS

csw_struc  STRUC

disc_csw_sign           DD ?
disc_csw_tag            DD ?
disc_csw_residue        DD ?
disc_csw_status         DB ?

csw_struc  ENDS

disc_struc   STRUC

disc_dev_handle         DW ?

disc_bulk_in_pipe       DB ?
disc_bulk_out_pipe      DB ?

disc_bulk_in_maxsize    DW ?
disc_bulk_out_maxsize   DW ?

disc_bulk_in_buf        DW ?
disc_bulk_out_buf       DW ?

disc_controller         DW ?
disc_port               DB ?

disc_nr                 DB ?
disc_handle             DW ?

disc_bytes_per_sector   DW ?
disc_sectors            DD ?,?

disc_serial             DB ?
disc_vendor             DW ?
disc_prod               DW ?

disc_exp_tag            DD ?
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
disc_intq_resv          DB 4 DUP(?)
disc_vendor_str         DB 8 DUP(?)
disc_prod_str           DB 16 DUP(?)
disc_rev_str            DB 4 DUP(?)

; request sense
disc_sense_data         DB 18 DUP(?)
   
disc_struc  ENDS

data    SEGMENT byte public 'DATA'

disc_device_arr     DW MAX_DISCS DUP(?)

fs_name             DB 10 DUP(?)

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
;                   ES      Bulk out sel
;                   EAX     Tag
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCbw Proc near
    pushad
;
    mov es:disc_cbw_lun,0
    mov es:disc_cbw_sign,43425355h
    mov es:disc_cbw_tag,eax
    mov fs:disc_exp_tag,eax
;
    mov ecx,31
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_out_pipe
    PostUsbRawPipe
    jc scbwDone
;
    cmp cx,31
    stc
    jnz scbwDone
;
    clc

scbwDone:
    popad
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
    pushad
;
    mov ecx,13
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    PostUsbRawPipe
    jc rcswDone
    
rcswOk:
    cmp cx,13
    stc
    jnz rcswDone
;
    mov es,fs:disc_bulk_in_buf
    mov eax,es:disc_csw_sign
    cmp eax,53425355h
    stc
    jne rcswDone
;
    mov eax,es:disc_csw_tag
    cmp eax,fs:disc_exp_tag
    stc
    jne rcswDone
;
    mov al,es:disc_csw_status
    or al,al    
    stc
    jnz rcswDone
;    
    clc

rcswDone:     
    popad   
    pop es    
    ret
ReceiveCsw Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ResetDevice
;
;   DESCRIPTION:    Reset device
;
;   PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetDevice Proc near
    pushad
;
    mov bx,fs:disc_dev_handle
    mov al,0FFh
    mov ah,21h
    xor dx,dx
    xor si,si
    xor cx,cx
    SendUsbDeviceControlMsg
;
    popad
    ret
ResetDevice     Endp

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
    push ds
    push es
;
    mov es,fs:disc_bulk_out_buf
    mov es:disc_cbw_transfer_len,36
    mov es:disc_cbw_flags,80h
    mov es:disc_cbw_cmd_len,6
    mov es:disc_cbw_cmd_data,12h
    mov es:disc_cbw_cmd_data+1,0
    mov es:disc_cbw_cmd_data+2,0
    mov es:disc_cbw_cmd_data+3,0
    mov es:disc_cbw_cmd_data+4,36
    mov es:disc_cbw_cmd_data+5,0
    mov eax,0F000FFFFh
    call SendCbw
;    
    mov es,fs:disc_bulk_in_buf
    mov ecx,36
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    PostUsbRawPipe
    jc inqDone
;    
    cmp cx,36
    jb inqDone
;
    mov ds,fs:disc_bulk_in_buf
    mov ax,fs
    mov es,ax
    xor esi,esi
    mov edi,OFFSET disc_peri
    mov ecx,36
    rep movsb
;
    call ReceiveCsw

inqDone:
    pop es
    pop ds
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
    push ds
    push es
;
    mov es,fs:disc_bulk_out_buf
    mov es:disc_cbw_transfer_len,18
    mov es:disc_cbw_flags,80h
    mov es:disc_cbw_cmd_len,12
    mov es:disc_cbw_cmd_data,3
    mov es:disc_cbw_cmd_data+1,0
    mov es:disc_cbw_cmd_data+2,0
    mov es:disc_cbw_cmd_data+3,0
    mov es:disc_cbw_cmd_data+4,18
    mov es:disc_cbw_cmd_data+5,0
    mov es:disc_cbw_cmd_data+6,0
    mov es:disc_cbw_cmd_data+7,0
    mov es:disc_cbw_cmd_data+8,0
    mov es:disc_cbw_cmd_data+9,0
    mov es:disc_cbw_cmd_data+10,0
    mov es:disc_cbw_cmd_data+11,0
    mov es:disc_cbw_cmd_data+12,0
    mov es:disc_cbw_cmd_data+13,0
    mov es:disc_cbw_cmd_data+14,0
    mov es:disc_cbw_cmd_data+15,0
;
    mov eax,2
    call SendCbw
    jc reqsDone
;    
    mov es,fs:disc_bulk_in_buf
    mov ecx,18
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    PostUsbRawPipe
    jc reqsDone
;
    cmp cx,18
    jb reqsDone
;
    mov ds,fs:disc_bulk_in_buf
    mov ax,fs
    mov es,ax
    xor esi,esi
    mov edi,OFFSET disc_sense_data
    mov ecx,18
    rep movsb
;    
    call ReceiveCsw

reqsDone:
    pop es
    pop ds
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
    push ds
    push es
;
    mov es,fs:disc_bulk_out_buf
    mov es:disc_cbw_transfer_len,8
    mov es:disc_cbw_flags,80h
    mov es:disc_cbw_cmd_len,10
    mov es:disc_cbw_cmd_data,25h
    mov es:disc_cbw_cmd_data+1,0
    mov es:disc_cbw_cmd_data+2,0
    mov es:disc_cbw_cmd_data+3,0
    mov es:disc_cbw_cmd_data+4,0
    mov es:disc_cbw_cmd_data+5,0
    mov es:disc_cbw_cmd_data+6,0
    mov es:disc_cbw_cmd_data+7,0
    mov es:disc_cbw_cmd_data+8,0
    mov es:disc_cbw_cmd_data+9,0
;
    mov eax,0D000DDDDh
    call SendCbw
    jc rcDone
;    
    mov es,fs:disc_bulk_in_buf
    mov ecx,8
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    PostUsbRawPipe
    jc rcDone
;
    xor di,di
    mov eax,es:[di]
    mov edx,es:[di+4]
;    
    call ReceiveCsw
    jc rcDone
;
    xchg dl,dh
    rol edx,16
    xchg dl,dh
    mov fs:disc_bytes_per_sector,dx
;
    xchg al,ah
    rol eax,16
    xchg al,ah
    inc eax
    mov fs:disc_sectors,eax
    mov fs:disc_sectors+4,0
    clc

rcDone:
    pop es
    pop ds
    ret
ReadCapacity Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadRaw
;
;       DESCRIPTION:    Read using raw interface
;
;       PARAMETERS:     FS      Disc selector
;                       ESI     Disc handle array
;                       EBP     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadRaw      Proc near
    push ebp
    push esi

rwBufLoop:  
    cmp ebp,8
    ja rwBufWhole
;
    mov eax,200h
    mul ebp
    mov ecx,eax
    jmp rwBufDo

rwBufWhole:
    mov ecx,1000h

rwBufDo:
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    PostUsbRawPipe
    jc rwBufReadDone
;
    xor edx,edx

rwBufCopy:
    push es
    push ecx
    push esi
;
;    mov edi,es:[esi]
;    mov edi,es:[edi].dh_data
;    mov ecx,80h
;    mov ds,fs:disc_bulk_in_buf
;    mov esi,edx
;    rep movs dword ptr es:[edi],ds:[esi]
;    mov edx,esi
;
    pop esi
    pop ecx
    pop ds
;
    add esi,4
    sub ebp,1
    clc
    jz rwBufReadDone
;
    sub ecx,200h
    jnz rwBufCopy
    jmp rwBufLoop

rwBufReadDone:
    pop esi
    pop ebp
    ret
ReadRaw  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteRaw
;
;       DESCRIPTION:    Write using raw interface
;
;       PARAMETERS:     FS      Disc selector
;                       ESI     Disc handle array
;                       EBP     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteRaw      Proc near
    push ebp
    push esi

wrBufLoop:  
    cmp ebp,8
    ja wrBufWhole
;
    mov eax,200h
    mul ebp
    mov ecx,eax
    jmp wrBufDo

wrBufWhole:
    mov ecx,1000h

wrBufDo:
    push ecx
    xor edx,edx

wrBufCopy:
    push ds
    push es
    push ecx
    push esi
;
;    mov esi,es:[esi]
;    mov esi,es:[esi].dh_data
;    mov ax,es
;    mov ds,ax
;    mov ecx,80h
;    mov es,fs:disc_bulk_out_buf
;    mov edi,edx
;    rep movs dword ptr es:[edi],ds:[esi]
;    mov edx,edi
;
    pop esi
    pop ecx
    pop es
    pop ds
;
    add esi,4
    sub ebp,1
    jz wrBufWrite
;
    sub ecx,200h
    jnz wrBufCopy

wrBufWrite:
    pop ecx
;
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_out_pipe
    PostUsbRawPipe
    jc wrBufWriteDone
;
    or ebp,ebp
    jnz wrBufLoop
;
    clc

wrBufWriteDone:
    pop esi
    pop ebp
    ret
WriteRaw  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   VFS thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vfs_thread:
    int 3
    xor ax,ax
    mov es,ax
;
    mov ax,SEG data
    mov ds,ax
;
    mov si,OFFSET disc_device_arr
    mov cx,MAX_DISCS

dtInsDiscLoop:
    mov ax,ds:[si]
    or ax,ax
    jz dtInsDo
;
    add si,2
    loop dtInsDiscLoop
;
    int 3
    jmp dtDelDone

dtInsDo:
    mov ds:[si],bx
;
    mov fs,bx
;
    mov bx,fs:disc_controller
    mov al,fs:disc_port
    OpenUsbDevice
    mov fs:disc_dev_handle,bx
;
    push es
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_out_pipe
    mov cx,1000h
    mov ax,500
    OpenUsbRawPipe
    mov fs:disc_bulk_out_buf,es
    pop es
;
    push es
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    mov cx,1000h
    mov ax,1500
    OpenUsbRawPipe
    mov fs:disc_bulk_in_buf,es
    pop es
;
    mov cx,32

dtRetryLoop:
    push cx
;    
    call RequestSense
    jc dtRetry
;    
    call Inquiry    
    jc dtRetry
;
    call ReadCapacity
    jnc dtOk

dtRetry:
    pop cx
    sub cx,1
    jz dtFailed
;
    call ResetDevice
;
    mov ax,100
    WaitMilliSec
    jmp dtRetryLoop

dtOk:
    pop cx
;
    int 3
    mov eax,fs:disc_sectors
    mov edx,fs:disc_sectors+4
    mov cx,fs:disc_bytes_per_sector
    OpenDynamicVfs


dtFailed:
    mov fs:disc_handle,bx
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_in_pipe
    CloseUsbPipe
;
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_out_pipe
    CloseUsbPipe
;
    mov bx,fs:disc_dev_handle
    CloseUsbDevice

dtDelDone:
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
;   NAME:           usb_attach
;
;   description:    USB attach callback
;
;   Parameters:     BX      Controller #
;                   AL      Port #
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
    push ax
    ConfigUsbDevice
    pop ax
;
    push es
    push eax
    mov eax,SIZE disc_struc
    AllocateSmallGlobalMem
    pop eax
    mov es:disc_controller,bx
    mov es:disc_port,al
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
    or cx,cx
    jz uaDescrDone
;
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
    mov al,gs:disc_port
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;    
    xor di,di
;    
    int 3
    mov bx,gs
    mov dx,cs
    mov ds,dx
    mov esi,OFFSET vfs_thread
    StartVfs
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
;                   AL      Port #
;                   DS      USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    push gs
    pushad
;
    mov dx,SEG data
    mov ds,dx
    mov si,OFFSET disc_device_arr
    mov cx,MAX_DISCS

udCheckLoop:
    mov dx,[si]
    or dx,dx
    jz udCheckNext
;
    mov es,dx
    cmp bx,es:disc_controller
    jne udCheckNext
;
    cmp al,es:disc_port
    jne udCheckNext
;
    mov bx,es:disc_handle
    StopDiscRequest

udCheckNext:
    add si,2    
    sub cx,1
    jnz udCheckLoop
    
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
    mov cx,MAX_DISCS
    mov si,OFFSET disc_device_arr
    xor ax,ax

iArrLoop:
    mov ds:[si],ax
    add si,2
    loop iArrLoop   
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
