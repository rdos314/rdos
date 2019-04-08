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
; USBCDCASM
; Implements USB CDC class
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

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

MAX_CDC_UNITS =	16

usb_cdc_descr	STRUC

ucdc_len	DB ?
ucdc_type	DB ?
ucdc_sub_type	DB ?

usb_cdc_descr	ENDS

usb_cdc_control_descr	STRUC

ucdcc_len	DB ?
ucdcc_type	DB ?
ucdcc_sub_type	DB ?
ucdcc_cap       DB ?

usb_cdc_control_descr	ENDS

usb_cdc_call_descr	STRUC

ucdccall_len	   DB ?
ucdccall_type	   DB ?
ucdccall_sub_type  DB ?
ucdccall_cap       DB ?
ucdccall_interface DB ?

usb_cdc_call_descr	ENDS

unit_struc      STRUC

unit_interface  DB ?

unit_struc	ENDS

cdc_struc	STRUC

cdc_sub_class		DB ?
cdc_protocol            DB ?
cdc_abs_control_cap     DB ?

cdc_unit_count          DB ?
cdc_unit_arr            DW MAX_CDC_UNITS DUP(?)

cdc_struc	ENDS

data    SEGMENT byte public 'DATA'

tmp DB ?

data	ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

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

error_descr	Proc near
    stc
    ret
error_descr	Endp

header_descr	Proc near
    clc
    ret
header_descr	Endp

call_descr	Proc near
    mov cl,es:[edi].ucdccall_cap
    test cl,1
    jz cdOk
;
    stc
    jmp cdDone

cdOk:
    clc

cdDone:
    ret
call_descr	Endp

abs_control_descr	Proc near
    mov cl,es:[edi].ucdcc_cap
    mov fs:cdc_abs_control_cap,cl
    clc
    ret
abs_control_descr	Endp

function_union_descr	Proc near
    push gs
    push eax
    push ecx
    push esi
    push edi
;
    mov al,es:[edi+3]
    or al,al
    stc
    jnz fudDone
;
    mov cl,es:[edi].ucdc_len
    sub cl,4
    movzx ecx,cl
    or ecx,ecx
    stc
    jz fudDone
;
    mov fs:cdc_unit_count,cl
    mov esi,OFFSET cdc_unit_arr
    add edi,4

fudLoop:
    push es
    mov eax,SIZE unit_struc
    AllocateSmallGlobalMem
    mov eax,es
    mov gs,eax
    pop es
;
    mov al,es:[edi]
    mov gs:unit_interface,al
;
    mov fs:[esi],gs
    add esi,2
    loop fudLoop
;    
    clc

fudDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    pop gs
    ret
function_union_descr	Endp

udesc_tab:
udt00 DD OFFSET header_descr
udt01 DD OFFSET call_descr
udt02 DD OFFSET abs_control_descr
udt03 DD OFFSET error_descr
udt04 DD OFFSET error_descr
udt05 DD OFFSET error_descr
udt06 DD OFFSET function_union_descr
udt07 DD OFFSET error_descr
udt08 DD OFFSET error_descr
udt09 DD OFFSET error_descr
udt0A DD OFFSET error_descr
udt0B DD OFFSET error_descr
udt0C DD OFFSET error_descr
udt0D DD OFFSET error_descr
udt0E DD OFFSET error_descr
udt0F DD OFFSET error_descr
udt10 DD OFFSET error_descr
udt11 DD OFFSET error_descr
udt12 DD OFFSET error_descr
udt13 DD OFFSET error_descr
udt14 DD OFFSET error_descr
udt15 DD OFFSET error_descr
udt16 DD OFFSET error_descr
udt17 DD OFFSET error_descr
udt18 DD OFFSET error_descr
udt19 DD OFFSET error_descr
udt1A DD OFFSET error_descr
udt1B DD OFFSET error_descr
udt1C DD OFFSET error_descr
udt1D DD OFFSET error_descr
udt1E DD OFFSET error_descr
udt1F DD OFFSET error_descr

usb_attach  Proc far
    push ds
    push es
    pushad
;    
    push eax
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop eax
;
    xor edi,edi
    push ax
    GetUsbDevice
    cmp ax,cx
    pop ax
    jne uaFail
;
    mov cl,es:udd_class
    cmp cl,2
    jne uaFail

uaCdc:
    xor dl,dl
    mov ecx,1000h
    xor edi,edi
    push eax
    GetUsbConfig
    mov ecx,eax
    pop eax
    or ecx,ecx
    jz uaFail
;
    mov dl,es:ucd_config_id
    xor edi,edi
    movzx ecx,es:ucd_len
    add edi,ecx

uaCheckLoop:
    mov cl,es:[edi].ucd_type
    cmp cl,4
    jne uaCheckNext
;    
    mov cl,es:[edi].uid_class
    cmp cl,2
    je uaFound

uaCheckNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz uaFail
;    
    add edi,ecx
    cmp di,es:ucd_size
    jb uaCheckLoop

uaFound:
    int 3    
    push es
    push eax
    mov eax,SIZE cdc_struc
    AllocateSmallGlobalMem
    mov eax,es
    mov fs,eax
    pop eax
    pop es
;
    mov fs:cdc_abs_control_cap,0
    mov fs:cdc_unit_count,0
;
    mov cl,es:[edi].uid_sub_class
    mov fs:cdc_sub_class,cl
;
    mov cl,es:[edi].uid_proto
    mov fs:cdc_protocol,cl
;
    xor dl,dl
    jmp uaDevNext

uaDevLoop:
    mov cl,es:[edi].ucd_type
    cmp cl,24h
    jne uaDevNext
;
    int 3
    mov cl,es:[edi].ucdc_sub_type
    cmp cl,20h
    jae uaFreeFail
;
    movzx esi,cl
    shl esi,2
    call dword ptr cs:[esi].udesc_tab
    jc uaFreeFail
;

uaDevNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz uaFail
;    
    add edi,ecx
    cmp di,es:ucd_size
    jb uaDevLoop
    jmp uaFail

uaDevOk:
    ConfigUsbDevice

uaFreeFail:
    FreeMem
    mov eax,fs
    mov es,eax

uaFail:
    FreeMem

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

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    int 3

udDone:
    popad
    pop es
    pop ds
    ret
usb_detach  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init    Proc far
    mov ax,SEG data
    mov ds,eax
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
    clc
    ret
Init    Endp
        
code    ENDS

    END Init
