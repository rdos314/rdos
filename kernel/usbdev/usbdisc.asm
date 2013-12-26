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
INCLUDE ..\drive.inc
include ..\usbdev\usb.inc

MAX_DISCS   = 16

part_struc      STRUC

part_status         DB ?
part_start_head     DB ?
part_start_cyl_sector   DW ?
part_type           DB ?
part_end_head       DB ?
part_end_cyl_sector     DW ?
part_start_sector       DD ?
part_sectors        DD ?

part_struc      ENDS

drive_struc STRUC

drive_nr                DB ?

drive_struc ENDS

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
disc_sectors_per_unit   DW ?
disc_units              DW ?

disc_drive_arr          DW 4 DUP(?)

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

disc_device_arr     DW MAX_DISCS DUP(?)

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       CalcParam
;
;       DESCRIPTION:    Calculate various parameters
;
;       PARAMETERS:     FS      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcParam       Proc near
    pushad
;
    mov eax,1
    mov edx,fs:disc_sectors

calc_param_norm_loop:
    shl eax,1
    shr edx,1
    cmp eax,edx
    jc calc_param_norm_loop
;
    mov esi,edx
    mov ebx,esi
    mov ecx,edx

calc_param_chs_loop:
    xor edx,edx
    mov eax,fs:disc_sectors
    div esi
    cmp ecx,edx
    jc calc_param_chs_next
;       
    mov ecx,edx
    mov ebx,esi
    or edx,edx
    jz calc_param_chs_ok

calc_param_chs_next:
    inc esi
    cmp esi,eax
    jbe calc_param_chs_loop
;
    xor edx,edx
    mov eax,fs:disc_sectors
    div ebx

calc_param_chs_ok:
    mov edx,eax
    mov eax,ebx
;
    mov fs:disc_sectors_per_unit,ax
    mov fs:disc_units,dx
    mul dx
    push dx
    push ax
    pop fs:disc_sectors
;
    popad
    ret
CalcParam       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetFs
;
;   DESCRIPTION:    Check for valid file system
;
;   PARAMETERS:     CL      PARTITION TYPE
;
;   RETURNS:        NC      OK
;                   ES:EDI  FS name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fs_unknown      DB 'UNKNOWN '
fs_fat12    DB 'FAT12   '
fs_fat16    DB 'FAT16   '
fs_fat32    DB 'FAT32   '
fs_hpfs     DB 'HPFS    '
fs_rdfs     DB 'RDFS    '
fs_flashfs  DB 'FLASHFS '

FsTab:
fs00    DW OFFSET fs_unknown
fs01    DW OFFSET fs_fat12
fs02    DW OFFSET fs_unknown
fs03    DW OFFSET fs_unknown
fs04    DW OFFSET fs_fat16
fs05    DW OFFSET fs_unknown
fs06    DW OFFSET fs_fat16
fs07    DW OFFSET fs_hpfs
fs08    DW OFFSET fs_unknown
fs09    DW OFFSET fs_unknown
fs0A    DW OFFSET fs_unknown
fs0B    DW OFFSET fs_fat32
fs0C    DW OFFSET fs_fat32
fs0D    DW OFFSET fs_unknown
fs0E    DW OFFSET fs_unknown
fs0F    DW OFFSET fs_unknown
fs10    DW OFFSET fs_unknown
fs11    DW OFFSET fs_unknown
fs12    DW OFFSET fs_unknown
fs13    DW OFFSET fs_unknown
fs14    DW OFFSET fs_unknown
fs15    DW OFFSET fs_unknown
fs16    DW OFFSET fs_unknown
fs17    DW OFFSET fs_unknown
fs18    DW OFFSET fs_unknown
fs19    DW OFFSET fs_unknown
fs1A    DW OFFSET fs_unknown
fs1B    DW OFFSET fs_unknown
fs1C    DW OFFSET fs_unknown
fs1D    DW OFFSET fs_unknown
fs1E    DW OFFSET fs_unknown
fs1F    DW OFFSET fs_unknown
fs20    DW OFFSET fs_unknown
fs21    DW OFFSET fs_unknown
fs22    DW OFFSET fs_unknown
fs23    DW OFFSET fs_unknown
fs24    DW OFFSET fs_unknown
fs25    DW OFFSET fs_unknown
fs26    DW OFFSET fs_unknown
fs27    DW OFFSET fs_unknown
fs28    DW OFFSET fs_unknown
fs29    DW OFFSET fs_unknown
fs2A    DW OFFSET fs_unknown
fs2B    DW OFFSET fs_unknown
fs2C    DW OFFSET fs_unknown
fs2D    DW OFFSET fs_unknown
fs2E    DW OFFSET fs_unknown
fs2F    DW OFFSET fs_unknown
fs30    DW OFFSET fs_unknown
fs31    DW OFFSET fs_unknown
fs32    DW OFFSET fs_unknown
fs33    DW OFFSET fs_unknown
fs34    DW OFFSET fs_unknown
fs35    DW OFFSET fs_unknown
fs36    DW OFFSET fs_unknown
fs37    DW OFFSET fs_unknown
fs38    DW OFFSET fs_unknown
fs39    DW OFFSET fs_unknown
fs3A    DW OFFSET fs_unknown
fs3B    DW OFFSET fs_unknown
fs3C    DW OFFSET fs_unknown
fs3D    DW OFFSET fs_unknown
fs3E    DW OFFSET fs_unknown
fs3F    DW OFFSET fs_unknown
fs40    DW OFFSET fs_unknown
fs41    DW OFFSET fs_unknown
fs42    DW OFFSET fs_unknown
fs43    DW OFFSET fs_unknown
fs44    DW OFFSET fs_unknown
fs45    DW OFFSET fs_unknown
fs46    DW OFFSET fs_unknown
fs47    DW OFFSET fs_unknown
fs48    DW OFFSET fs_unknown
fs49    DW OFFSET fs_unknown
fs4A    DW OFFSET fs_unknown
fs4B    DW OFFSET fs_unknown
fs4C    DW OFFSET fs_unknown
fs4D    DW OFFSET fs_unknown
fs4E    DW OFFSET fs_unknown
fs4F    DW OFFSET fs_unknown
fs50    DW OFFSET fs_unknown
fs51    DW OFFSET fs_unknown
fs52    DW OFFSET fs_unknown
fs53    DW OFFSET fs_unknown
fs54    DW OFFSET fs_unknown
fs55    DW OFFSET fs_unknown
fs56    DW OFFSET fs_unknown
fs57    DW OFFSET fs_unknown
fs58    DW OFFSET fs_unknown
fs59    DW OFFSET fs_unknown
fs5A    DW OFFSET fs_unknown
fs5B    DW OFFSET fs_unknown
fs5C    DW OFFSET fs_unknown
fs5D    DW OFFSET fs_unknown
fs5E    DW OFFSET fs_unknown
fs5F    DW OFFSET fs_unknown
fs60    DW OFFSET fs_unknown
fs61    DW OFFSET fs_unknown
fs62    DW OFFSET fs_unknown
fs63    DW OFFSET fs_unknown
fs64    DW OFFSET fs_unknown
fs65    DW OFFSET fs_unknown
fs66    DW OFFSET fs_unknown
fs67    DW OFFSET fs_unknown
fs68    DW OFFSET fs_unknown
fs69    DW OFFSET fs_unknown
fs6A    DW OFFSET fs_unknown
fs6B    DW OFFSET fs_unknown
fs6C    DW OFFSET fs_unknown
fs6D    DW OFFSET fs_unknown
fs6E    DW OFFSET fs_unknown
fs6F    DW OFFSET fs_unknown
fs70    DW OFFSET fs_unknown
fs71    DW OFFSET fs_unknown
fs72    DW OFFSET fs_unknown
fs73    DW OFFSET fs_unknown
fs74    DW OFFSET fs_unknown
fs75    DW OFFSET fs_unknown
fs76    DW OFFSET fs_unknown
fs77    DW OFFSET fs_unknown
fs78    DW OFFSET fs_unknown
fs79    DW OFFSET fs_unknown
fs7A    DW OFFSET fs_unknown
fs7B    DW OFFSET fs_unknown
fs7C    DW OFFSET fs_unknown
fs7D    DW OFFSET fs_unknown
fs7E    DW OFFSET fs_unknown
fs7F    DW OFFSET fs_unknown
fs80    DW OFFSET fs_unknown
fs81    DW OFFSET fs_unknown
fs82    DW OFFSET fs_unknown
fs83    DW OFFSET fs_unknown
fs84    DW OFFSET fs_unknown
fs85    DW OFFSET fs_unknown
fs86    DW OFFSET fs_unknown
fs87    DW OFFSET fs_unknown
fs88    DW OFFSET fs_unknown
fs89    DW OFFSET fs_unknown
fs8A    DW OFFSET fs_unknown
fs8B    DW OFFSET fs_unknown
fs8C    DW OFFSET fs_unknown
fs8D    DW OFFSET fs_unknown
fs8E    DW OFFSET fs_unknown
fs8F    DW OFFSET fs_unknown
fs90    DW OFFSET fs_unknown
fs91    DW OFFSET fs_unknown
fs92    DW OFFSET fs_unknown
fs93    DW OFFSET fs_unknown
fs94    DW OFFSET fs_unknown
fs95    DW OFFSET fs_unknown
fs96    DW OFFSET fs_unknown
fs97    DW OFFSET fs_unknown
fs98    DW OFFSET fs_unknown
fs99    DW OFFSET fs_unknown
fs9A    DW OFFSET fs_unknown
fs9B    DW OFFSET fs_unknown
fs9C    DW OFFSET fs_unknown
fs9D    DW OFFSET fs_unknown
fs9E    DW OFFSET fs_unknown
fs9F    DW OFFSET fs_unknown
fsA0    DW OFFSET fs_unknown
fsA1    DW OFFSET fs_unknown
fsA2    DW OFFSET fs_unknown
fsA3    DW OFFSET fs_unknown
fsA4    DW OFFSET fs_unknown
fsA5    DW OFFSET fs_unknown
fsA6    DW OFFSET fs_unknown
fsA7    DW OFFSET fs_unknown
fsA8    DW OFFSET fs_unknown
fsA9    DW OFFSET fs_unknown
fsAA    DW OFFSET fs_unknown
fsAB    DW OFFSET fs_unknown
fsAC    DW OFFSET fs_unknown
fsAD    DW OFFSET fs_unknown
fsAE    DW OFFSET fs_rdfs
fsAF    DW OFFSET fs_flashfs
fsB0    DW OFFSET fs_unknown
fsB1    DW OFFSET fs_unknown
fsB2    DW OFFSET fs_unknown
fsB3    DW OFFSET fs_unknown
fsB4    DW OFFSET fs_unknown
fsB5    DW OFFSET fs_unknown
fsB6    DW OFFSET fs_unknown
fsB7    DW OFFSET fs_unknown
fsB8    DW OFFSET fs_unknown
fsB9    DW OFFSET fs_unknown
fsBA    DW OFFSET fs_unknown
fsBB    DW OFFSET fs_unknown
fsBC    DW OFFSET fs_unknown
fsBD    DW OFFSET fs_unknown
fsBE    DW OFFSET fs_unknown
fsBF    DW OFFSET fs_unknown
fsC0    DW OFFSET fs_unknown
fsC1    DW OFFSET fs_unknown
fsC2    DW OFFSET fs_unknown
fsC3    DW OFFSET fs_unknown
fsC4    DW OFFSET fs_unknown
fsC5    DW OFFSET fs_unknown
fsC6    DW OFFSET fs_unknown
fsC7    DW OFFSET fs_unknown
fsC8    DW OFFSET fs_unknown
fsC9    DW OFFSET fs_unknown
fsCA    DW OFFSET fs_unknown
fsCB    DW OFFSET fs_unknown
fsCC    DW OFFSET fs_unknown
fsCD    DW OFFSET fs_unknown
fsCE    DW OFFSET fs_unknown
fsCF    DW OFFSET fs_unknown
fsD0    DW OFFSET fs_unknown
fsD1    DW OFFSET fs_unknown
fsD2    DW OFFSET fs_unknown
fsD3    DW OFFSET fs_unknown
fsD4    DW OFFSET fs_unknown
fsD5    DW OFFSET fs_unknown
fsD6    DW OFFSET fs_unknown
fsD7    DW OFFSET fs_unknown
fsD8    DW OFFSET fs_unknown
fsD9    DW OFFSET fs_unknown
fsDA    DW OFFSET fs_unknown
fsDB    DW OFFSET fs_unknown
fsDC    DW OFFSET fs_unknown
fsDD    DW OFFSET fs_unknown
fsDE    DW OFFSET fs_unknown
fsDF    DW OFFSET fs_unknown
fsE0    DW OFFSET fs_unknown
fsE1    DW OFFSET fs_unknown
fsE2    DW OFFSET fs_unknown
fsE3    DW OFFSET fs_unknown
fsE4    DW OFFSET fs_unknown
fsE5    DW OFFSET fs_unknown
fsE6    DW OFFSET fs_unknown
fsE7    DW OFFSET fs_unknown
fsE8    DW OFFSET fs_unknown
fsE9    DW OFFSET fs_unknown
fsEA    DW OFFSET fs_unknown
fsEB    DW OFFSET fs_unknown
fsEC    DW OFFSET fs_unknown
fsED    DW OFFSET fs_unknown
fsEE    DW OFFSET fs_unknown
fsEF    DW OFFSET fs_unknown
fsF0    DW OFFSET fs_unknown
fsF1    DW OFFSET fs_unknown
fsF2    DW OFFSET fs_unknown
fsF3    DW OFFSET fs_unknown
fsF4    DW OFFSET fs_unknown
fsF5    DW OFFSET fs_unknown
fsF6    DW OFFSET fs_unknown
fsF7    DW OFFSET fs_unknown
fsF8    DW OFFSET fs_unknown
fsF9    DW OFFSET fs_unknown
fsFA    DW OFFSET fs_unknown
fsFB    DW OFFSET fs_unknown
fsFC    DW OFFSET fs_unknown
fsFD    DW OFFSET fs_unknown
fsFE    DW OFFSET fs_unknown
fsFF    DW OFFSET fs_unknown

GetFs    Proc near
    push ecx
;
    mov di,cs
    mov es,di
    movzx di,cl
    shl di,1
;
    mov ecx,eax
    mov di,word ptr cs:[di].FsTab
    movzx edi,di
    IsFileSystemAvailable
;
    pop ecx
    ret
GetFs   Endp 

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
;   NAME:           WriteData
;
;   DESCRIPTION:    Write data
;
;   PARAMETERS:     FS      Disc sel
;                   ES:EDI  Buffer
;                   ECX     Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteData Proc near
    mov bx,fs:disc_bulk_out_handle
    UserGateForce32 write_usb_data_nr
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
    ret
WriteData Endp

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
;   NAME:           WriteSector
;
;   DESCRIPTION:    Write sector
;
;   PARAMETERS:     FS      Disc sel
;                   ES:EDI  Buffer
;                   EDX     Sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSector Proc near
    push es
    pushad
;    
    mov ecx,200h
    mov fs:disc_cbw_tag,edx
    mov fs:disc_cbw_transfer_len,ecx
    mov fs:disc_cbw_flags,0
    mov fs:disc_cbw_cmd_len,10
    mov fs:disc_cbw_cmd_data,2Ah
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
    jc wsDone
;    
    mov ecx,200h
    call WriteData
    jc wsDone
;    
    call ReceiveCsw

wsDone:
    popad
    pop es
    ret
WriteSector Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupDrives
;
;       DESCRIPTION:    Setup drives
;
;       PARAMETERS:     FS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDrives Proc near
    mov fs:disc_drive_arr,0
    mov fs:disc_drive_arr+2,0
    mov fs:disc_drive_arr+4,0
    mov fs:disc_drive_arr+6,0
;
    mov eax,1000h
    AllocateBigLinear
    mov ax,flat_sel
    mov es,ax
    mov edi,edx    
    xor edx,edx
    call ReadSector
;
    mov bp,OFFSET disc_drive_arr
    mov esi,1BEh

sdLoop:
    mov cl,es:[esi+edi].part_type
    or cl,cl
    jz sdDone
;
    push es
    push edi
    call GetFs
    pop edi
    pop es
    jc sdNext
;    
    push es
    mov eax,SIZE drive_struc
    AllocateSmallGlobalMem
    mov fs:[bp],es
    AllocateDynamicDrive
    mov es:drive_nr,al
    pop es
;
    mov edx,es:[esi+edi].part_start_sector
    mov ecx,es:[esi+edi].part_sectors
    mov ah,fs:disc_nr
    OpenDrive
;
    push es
    push edi
    mov cl,es:[esi+edi].part_type
    call GetFs
    InstallFileSystem
    pop edi
    pop es

sdNext:
    add bp,2
    add si,10h
    cmp si,1FEh
    jne sdLoop

sdDone:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
    ret
SetupDrives Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Start thread
;
;   BX      Disc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_thread_name   DB 'Start Usb Disc', 0

start_thread:
    mov fs,bx
    mov bx,fs:disc_handle
    StartDisc
    TerminateThread
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       read_drive
;
;       DESCRIPTION:    Read drive
;
;       PARAMETERS:     FS      Disc selector
;               ESI     Disc handle array
;               ECX     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_drive      Proc near

rdLoop:    
    push ecx
    mov edi,es:[esi]
;
    movzx edx,es:[edi].dh_unit
    movzx eax,fs:disc_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    mov ebx,edx
    mov ebp,1
;
    push esi    

rdSizeLoop:
    cmp ecx,ebp
    jbe rdDoTrans
;
    add esi,4
    mov edi,es:[esi]
;
    push ebx
    movzx edx,es:[edi].dh_unit
    movzx eax,fs:disc_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
    pop ebx
;
    inc ebx
    cmp ebx,edx
    jne rdDoTrans
;
    inc ebp
    jmp rdSizeLoop            

rdDoTrans:
    pop esi
;    
    mov edi,es:[esi]
    movzx edx,es:[edi].dh_unit
    movzx eax,fs:disc_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
;    
    shl ebp,9
    mov fs:disc_cbw_tag,edx
    mov fs:disc_cbw_transfer_len,ebp
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
    shr ebp,9
    mov ax,bp
    xchg al,ah    
    mov word ptr fs:disc_cbw_cmd_data+7,ax
    mov fs:disc_cbw_cmd_data+9,0
;
    call SendCbw
    jc rdFail
;    
    push ebp
    push esi

rdBufLoop:  
    mov edi,es:[esi]
    mov edi,es:[edi].dh_data
    mov ecx,200h
    mov bx,fs:disc_bulk_in_handle
    ReqUsbData
;
    add esi,4
    sub ebp,1
    jnz rdBufLoop
;
    pop esi
    pop ebp
;
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
    jc rdFail
;    
    call ReceiveCsw
    jnc rdOk
    
rdFail:
    int 3
    pop ecx

rdFailLoop:    
    mov edi,es:[esi]
    mov eax,es:[edi].dh_data
    mov es:[eax].dh_state,STATE_BAD
    mov bx,fs:disc_handle
    DiscRequestCompleted
    add esi,4
    sub ecx,1
    sub ebp,1
    jnz rdFailLoop
;    
    jmp rdNext

rdOk:
    pop ecx

rdOkLoop:
    mov edi,es:[esi]
    mov eax,es:[edi].dh_data
    mov es:[edi].dh_state,STATE_USED
    mov bx,fs:disc_handle
    DiscRequestCompleted
    add esi,4
    sub ecx,1
    sub ebp,1
    jnz rdOkLoop

rdNext:
    or ecx,ecx
    jnz rdLoop
;
    ret
read_drive      Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       write_drive
;
;       DESCRIPTION:    Perform a write request
;
;       PARAMETERS:     FS      Disc selector
;               ESI     Disc handle array
;               ECX     Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive     Proc near

wdLoop:    
    push ecx
    push esi
;    
    mov edi,es:[esi]
;
    movzx edx,es:[edi].dh_unit
    movzx eax,fs:disc_sectors_per_unit
    mul edx
    movzx ebx,es:[edi].dh_sector
    add eax,ebx
    mov edx,eax
;    
    push edi
    mov edi,es:[edi].dh_data
;    
    mov ecx,200h
    mov fs:disc_cbw_tag,edx
    mov fs:disc_cbw_transfer_len,ecx
    mov fs:disc_cbw_flags,0
    mov fs:disc_cbw_cmd_len,10
    mov fs:disc_cbw_cmd_data,2Ah
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
    jc wdCont
;    
    mov ecx,200h
    call WriteData
    jc wdCont
;    
    call ReceiveCsw

wdCont:
    pop edi
    jnc wdOk 
    
wdFail:
    int 3
    mov es:[edi].dh_state,STATE_BAD
    mov bx,fs:disc_handle
    DiscRequestCompleted
    jmp wdNext

wdOk:
    mov eax,es:[edi].dh_data
    mov es:[edi].dh_state,STATE_USED
    mov bx,fs:disc_handle
    DiscRequestCompleted

wdNext:
    pop esi
    pop ecx  
    add esi,4  
    sub ecx,1
    jnz wdLoop
;
    ret
write_drive     Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       perform_one
;
;       DESCRIPTION:    Perform one request
;
;       PARAMETERS:     FS      Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_one     Proc near

perform_one_loop:
    mov ecx,255
    GetDiscRequestArray
    jc perform_one_done
;
    mov edi,es:[esi]
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je perform_one_read
;
    cmp al,STATE_DIRTY
    je perform_one_write
;
    cmp al,STATE_SEQ
    jne perform_one_done

perform_one_write:
    call write_drive
    jmp perform_one_loop

perform_one_read:
    call read_drive
    jmp perform_one_loop

perform_one_done:
    ret
perform_one     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Disc thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_thread:

dtCheckCompleted:
    CondBeginDiscHandler
    jnc dtStart
;
    mov ax,50
    WaitMilliSec
    jmp dtCheckCompleted

dtStart:
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
    jc dtFailed
;    
    call RequestSense
    jc dtFailed
;
    call ReadCapacity
    jc dtFailed
;
    mov bx,fs
    mov ecx,10000h
    InstallDisc
    mov fs:disc_nr,al
    mov fs:disc_handle,bx
;
    call CalcParam
    mov ax,fs:disc_sectors_per_unit
    mov dx,fs:disc_units
    mov cx,512
    mov si,-1
    mov di,-1
    mov bx,fs:disc_handle
    SetDiscParam
;
    call SetupDrives
    EndDiscHandler
;       
    mov bx,fs
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET start_thread
    mov edi,OFFSET start_thread_name
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    mov ax,flat_sel
    mov es,ax
    mov bx,fs:disc_handle

discbuf_thread_loop:
    WaitForDiscRequest
    jc dtEnd
;    
    call perform_one
    jmp discbuf_thread_loop

dtFailed:
    EndDiscHandler    
    
dtEnd: 
    mov bx,fs:disc_bulk_in_wait
    CloseWait
;
    mov bx,fs:disc_bulk_in_handle
    CloseUsbPipe
;
    mov bx,fs:disc_bulk_out_wait
    CloseWait
;
    mov bx,fs:disc_bulk_out_handle
    CloseUsbPipe
;
    mov bx,fs:disc_handle
    StopDisc    
;    
    mov bx,fs
    mov es,bx
    xor ax,ax
    mov fs,ax
    mov ax,SEG data
    mov ds,ax
;    
    mov si,OFFSET disc_device_arr
    mov cx,MAX_DISCS

dtDelDiscLoop:
    cmp bx,ds:[si]
    je dtDelDo
;
    add si,2
    loop dtDelDiscLoop
;
    jmp dtDelDone

dtDelDo:
    mov word ptr ds:[si],0

dtDelDone:
    mov es,bx
    FreeMem        
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
    cmp al,es:disc_device
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
