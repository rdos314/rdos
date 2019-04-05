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

cdc_struc	STRUC

cdc_control_sub_type      DB ?
cdc_control_cap           DB ?

cdc_union_sub_type        DB ?
cdc_com_class_interface   DB ?
cdc_data_class_interface  DB ?

cdc_call_sub_type         DB ?
cdc_call_cap              DB ?
cdc_data_interface        DB ?

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
    int 3    
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
    jne uaCheckNext
;
    mov cl,es:[edi].uid_sub_class
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

uaFail:
    FreeMem    
    jmp uaDone

uaFound:
    xor dh,dh
    push es
    push eax
    mov eax,SIZE cdc_struc
    AllocateSmallGlobalMem
    mov eax,es
    mov fs,eax
    pop eax
    pop es

uaDevLoop:
    mov cl,es:[edi].ucd_type
    cmp cl,24h
    jne uaDevNext
;
    lea esi,[edi+1].ucd_type    
    cmp dh,0
    je uaDevGet0
;
    cmp dh,1
    je uaDevGet1
;
    cmp dh,2
    je uaDevGet2
;
    cmp dh,3
    je uaDevGet3
;
    jmp uaFail

uaDevGet0:
    inc dh
    jmp uaDevNext

uaDevGet1:
    mov cx,es:[esi]
    mov fs:cdc_control_sub_type,cl
    mov fs:cdc_control_cap,ch
    inc dh
    jmp uaDevNext

uaDevGet2:
    mov cx,es:[esi]
    mov fs:cdc_union_sub_type,cl
    mov fs:cdc_com_class_interface,ch
    mov cl,es:[esi+2]
    mov fs:cdc_data_class_interface,cl
    inc dh
    jmp uaDevNext

uaDevGet3:
    mov cx,es:[esi]
    mov fs:cdc_call_sub_type,cl
    mov fs:cdc_call_cap,ch
    mov cl,es:[esi+2]
    mov fs:cdc_data_interface,cl
    inc dh
    jmp uaDevOk

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
