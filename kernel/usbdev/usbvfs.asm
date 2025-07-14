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
; usbvfs.ASM
; Implements VFS mass storage class for USB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
INCLUDE ..\os\protseg.def
include ..\usbdev\usb.inc
include ..\fs\dev\vfs.inc

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

disc_serv_buf           DD ?

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
;       NAME:           InitVfs
;
;       DESCRIPTION:    Init disc
;
;       PARAMETERS:     BX           Disc selector
;
;       RETURNS:        NC
;                         EDX:EAX    Sectors
;                         CX         Bytes per sector
;                         BX         Max sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitVfs   Proc far
    push ds
    push es
    push fs
;
    mov fs,bx
;
    mov eax,1000h
    AllocateBigServ
    mov fs:disc_serv_buf,edx
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

ivRetryLoop:
    push cx
;    
    call RequestSense
    jc ivRetry
;    
    call Inquiry    
    jc ivRetry
;
    call ReadCapacity
    jnc ivOk

ivRetry:
    pop cx
    sub cx,1
    jz ivClose
;
    call ResetDevice
;
    mov ax,100
    WaitMilliSec
    jmp ivRetryLoop

ivClose:
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

ivFail:
    stc
    jmp ivDone

ivOk:
    pop cx
;
    mov eax,fs:disc_sectors
    mov edx,fs:disc_sectors+4
    mov cx,fs:disc_bytes_per_sector
    mov bx,100h
    clc

ivDone:
    pop fs
    pop es
    pop ds
    retf32
InitVfs    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ExitVfs
;
;       DESCRIPTION:    Exit VFS
;
;       PARAMETERS:     BX           Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ExitVfs   Proc far
    push fs
    pushad
;
    mov fs,bx
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
;
    popad
    pop fs
    retf32
ExitVfs  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetVfsVendor
;
;       DESCRIPTION:    Get vendor
;
;       PARAMETERS:     BX           Disc selector
;                       ES:EDI       Vendor buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


GetVfsVendor   Proc far
    push fs
    pushad
;
    mov al,'U'
    stos byte ptr es:[edi]
    mov al,'S'
    stos byte ptr es:[edi]
    mov al,'B'
    stos byte ptr es:[edi]
    mov al,':'
    stos byte ptr es:[edi]
;
    mov fs,bx
    mov esi,OFFSET disc_vendor_str
    mov ecx,(16+8+4) SHR 2
    rep movs dword ptr es:[edi],fs:[esi]    
;
    xor al,al
    stos byte ptr es:[edi]
;
    popad
    pop fs
    retf32
GetVfsVendor  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetBiosVfs
;
;       DESCRIPTION:    Get BIOS VFS parameters
;
;       PARAMETERS:     BX           Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


GetBiosVfs   Proc far
    stc
    retf32
GetBiosVfs  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadVfs
;
;       DESCRIPTION:    Read using raw interface
;
;       PARAMETERS:     BX          Disc selector
;                       ECX         Sector count
;                       EDX:EAX     Start sector
;                       ES:EDI      Physical entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadVfs      Proc far
    push ds
    push es
    push fs
    push gs
    push ebx
    push esi
    push edi
    push ebp
;
    mov ebp,es
    mov gs,ebp
    mov fs,bx

rvfsRetry:
    push eax
    push ecx
    push edx
;
    mov ebp,ecx
    shl ebp,9
;
    mov es,fs:disc_bulk_out_buf    
    mov es:disc_cbw_tag,eax
    mov es:disc_cbw_transfer_len,ebp
    mov es:disc_cbw_flags,80h
    mov es:disc_cbw_cmd_len,10
    mov es:disc_cbw_cmd_data,28h
    mov es:disc_cbw_cmd_data+1,0
;
    mov ebx,eax
    xchg bl,bh
    rol ebx,16
    xchg bl,bh
    mov dword ptr es:disc_cbw_cmd_data+2,ebx
;
    mov es:disc_cbw_cmd_data+6,0
;
    mov bx,cx
    xchg bl,bh    
    mov word ptr es:disc_cbw_cmd_data+7,bx
    mov es:disc_cbw_cmd_data+9,0
;
    mov bx,fs:disc_dev_handle
    IsUsbDeviceConnected
    jc rvfsDetached
;
    call SendCbw
    jc rvfsFail
;
    mov ebp,edi

rvfsLoop:
    push ecx
    cmp ecx,8
    ja rvfsBufWhole
;
    mov eax,200h
    mul ecx
    mov ecx,eax
    jmp rvfsBufDo

rvfsBufWhole:
    mov ecx,1000h

rvfsBufDo:
    mov bx,fs:disc_dev_handle
    IsUsbDeviceConnected
    jnc rvfsRead
;
    pop ecx
    jmp rvfsDetached

rvfsRead:
    mov dl,fs:disc_bulk_in_pipe
    PostUsbRawPipe
    pop ecx
    jc rvfsFail
;
    push ecx
    cmp ecx,8
    jb rvfsSizeOk
;
    mov ecx,8

rvfsSizeOk:
    mov ds,fs:disc_bulk_in_buf    
    xor esi,esi
    mov ax,serv_flat_sel
    mov es,ax

rvfsCopyLoop:
    mov edx,fs:disc_serv_buf
    mov eax,gs:[ebp]
    mov ebx,gs:[ebp+4]
    MapServEntry
;
    push ecx
    mov edi,edx
    mov ecx,80h
    rep movs dword ptr es:[edi],ds:[esi]
    pop ecx
;
    add ebp,8
    loop rvfsCopyLoop
;
    pop ecx
    sub ecx,8
    ja rvfsLoop
;    
    mov bx,fs:disc_dev_handle
    IsUsbDeviceConnected
    jc rvfsDetached
;
    call ReceiveCsw
    jc rvfsFail
;
    pop edx
    pop ecx
    pop eax
    jmp rvfsDone
    
rvfsFail:
    mov bx,fs:disc_dev_handle
    IsUsbDeviceConnected
    jc rvfsDetached
;
    call ResetDevice
;
    pop edx
    pop ecx
    pop eax
    jmp rvfsRetry

rvfsDetached:
    pop edx
    pop ecx
    pop eax

rvfsDone:
    pop ebp
    pop edi
    pop esi
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    retf32
ReadVfs  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteVfs
;
;       DESCRIPTION:    Write using raw interface
;
;       PARAMETERS:     BX          Disc selector
;                       CX          Sector count
;                       EDX:EAX     Start sector
;                       ES:EDI      Physical entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteVfs      Proc far
    push ds
    push es
    push fs
    push gs
    push ebx
    push esi
    push edi
    push ebp
;
    mov ebp,es
    mov gs,ebp
    mov fs,bx

wvfsRetry:
    push eax
    push ecx
    push edx
;
    mov ebp,ecx
    shl ebp,9
;
    mov es,fs:disc_bulk_out_buf    
    mov es:disc_cbw_tag,eax
    mov es:disc_cbw_transfer_len,ebp
    mov es:disc_cbw_flags,0
    mov es:disc_cbw_cmd_len,10
    mov es:disc_cbw_cmd_data,2Ah
    mov es:disc_cbw_cmd_data+1,0
;    
    mov ebx,eax
    xchg bl,bh
    rol ebx,16
    xchg bl,bh
    mov dword ptr es:disc_cbw_cmd_data+2,ebx
;
    mov es:disc_cbw_cmd_data+6,0
;
    mov bx,cx
    xchg bl,bh    
    mov word ptr es:disc_cbw_cmd_data+7,bx
    mov es:disc_cbw_cmd_data+9,0
;
    mov bx,fs:disc_dev_handle
    IsUsbDeviceConnected
    jc wvfsDetached
;
    call SendCbw
    jc wvfsFail
;
    mov ebp,edi

wvfsLoop:
    push ecx
    push edi
;
    cmp ecx,8
    jb wvfsSizeOk
;
    mov ecx,8

wvfsSizeOk:
    mov es,fs:disc_bulk_out_buf    
    xor edi,edi
    mov ax,serv_flat_sel
    mov ds,ax

wvfsCopyLoop:
    mov edx,fs:disc_serv_buf
    mov eax,gs:[ebp]
    mov ebx,gs:[ebp+4]
    MapServEntry
;
    push ecx
    mov esi,edx
    mov ecx,80h
    rep movs dword ptr es:[edi],ds:[esi]
    pop ecx
;
    add ebp,8
    loop wvfsCopyLoop
;
    pop edi
    pop ecx
;
    push ecx
    cmp ecx,8
    ja wvfsBufWhole
;
    mov eax,200h
    mul ecx
    mov ecx,eax
    jmp wvfsBufDo

wvfsBufWhole:
    mov ecx,1000h

wvfsBufDo:
    mov bx,fs:disc_dev_handle
    IsUsbDeviceConnected
    jnc wvfsWrite
;
    pop ecx
    jmp wvfsDetached

wvfsWrite:
    mov esi,ecx
    mov bx,fs:disc_dev_handle
    mov dl,fs:disc_bulk_out_pipe
    PostUsbRawPipe
    pop ecx
    jc wvfsFail
;
    sub ecx,8
    ja wvfsLoop
;    
    call ReceiveCsw
    jc wvfsFail
;
    pop edx
    pop ecx
    pop eax
    jmp wvfsDone

wvfsFail:
    int 3
    mov bx,fs:disc_dev_handle
    IsUsbDeviceConnected
    jc wvfsDetached
;
    call ResetDevice
;
    pop edx
    pop ecx
    pop eax
    jmp wvfsRetry

wvfsDetached:
    pop edx
    pop ecx
    pop eax

wvfsDone:
    pop ebp
    pop edi
    pop esi
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    retf32
WriteVfs  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsStaticVfs
;
;       DESCRIPTION:    Check for static disc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsStaticVfs      Proc far
    stc
    retf32
IsStaticVfs      Endp
               
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

vfs_tab:
vfs00   DD OFFSET InitVfs,        DD SEG code
vfs01   DD OFFSET GetVfsVendor,   DD SEG code
vfs02   DD OFFSET ExitVfs,        DD SEG code
vfs03   DD OFFSET GetBiosVfs,     DD SEG code
vfs04   DD OFFSET ReadVfs,        DD SEG code
vfs05   DD OFFSET WriteVfs,       DD SEG code
vfs06   DD OFFSET IsStaticVfs,    DD SEG code

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
    mov bx,gs
    mov dx,cs
    mov ds,dx
    mov esi,OFFSET vfs_tab
    StartVfs
;
    mov gs:disc_handle,bx
;
    mov ax,SEG data
    mov ds,ax
;
    mov si,OFFSET disc_device_arr
    mov cx,MAX_DISCS

uaInsDiscLoop:
    mov ax,ds:[si]
    or ax,ax
    jz uaInsDo
;
    add si,2
    loop uaInsDiscLoop
;
    mov bx,gs:disc_handle
    StopVfs
    jmp uaFree

uaInsDo:
    mov ds:[si],gs

uaFree:
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
    xor dx,dx
    mov [si],dx
;
    mov bx,es:disc_handle
    StopVfs

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
