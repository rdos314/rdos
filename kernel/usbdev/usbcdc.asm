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

unit_in_endp    DB ?
unit_out_endp   DB ?

unit_in_size    DW ?
unit_out_size   DW ?

unit_in_wait    DW ?
unit_out_wait   DW ?

unit_in_pipe    DW ?
unit_out_pipe   DW ?

unit_struc	ENDS

cdc_struc	STRUC

cdc_controller          DW ?
cdc_device              DB ?

cdc_sub_class		DB ?
cdc_protocol            DB ?
cdc_abs_control_cap     DB ?

cdc_control_wait        DW ?
cdc_control_pipe        DW ?

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
;   NAME:           FindInterfaces
;
;   DESCRIPTION:    
;
;   PARAMETERS:     DS      CDC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindInterfaces	Proc near
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
;
    mov bx,ds:cdc_controller
    mov al,ds:cdc_device
    xor dl,dl
    mov ecx,1000h
    xor edi,edi
    GetUsbConfig
    mov ecx,eax
    or ecx,ecx
    stc
    jz fiFail
;
    xor edi,edi
    movzx ecx,es:ucd_len
    add edi,ecx

fiDescrLoop:
    mov al,es:[edi].udd_type
    cmp al,4
    jne fiDescrNext

fiInterface:
    movzx ecx,ds:cdc_unit_count
    mov ebx,OFFSET cdc_unit_arr

fiIntLoop:
    mov fs,ds:[ebx]
    mov al,fs:unit_interface
    cmp al,es:[edi].uid_id
    je fiPipeNext
    jmp fiIntNext

fiPipeLoop:
    mov al,es:[edi].udd_type
    cmp al,4
    je fiDescrLoop
;
    cmp al,5
    jne fiPipeNext
;
    mov al,es:[edi].ued_attrib
    and al,3
    cmp al,2
    jne fiPipeNext

fiIsBulk:
    mov dl,es:[edi].ued_address
    test dl,80h
    jz fiIsBulkOut

fiIsBulkIn:
    mov fs:unit_in_endp,dl
    mov ax,es:[edi].ued_maxsize
    mov fs:unit_in_size,ax
    jmp fiPipeNext

fiIsBulkOut:
    mov fs:unit_out_endp,dl
    mov ax,es:[edi].ued_maxsize
    mov fs:unit_out_size,ax

fiPipeNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz fiOk
;
    add edi,ecx
    cmp di,es:ucd_size
    jb fiPipeLoop
    jmp fiOk

fiIntNext:
    add ebx,2
    sub ecx,1
    jnz fiIntLoop

fiDescrNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz fiOk
;
    add edi,ecx
    cmp di,es:ucd_size
    jb fiDescrLoop

fiOk:
    FreeMem
    clc
    jmp fiDone

fiFail:
    FreeMem
    stc

fiDone:
    ret
FindInterfaces	Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CheckInterfaces
;
;   DESCRIPTION:    
;
;   PARAMETERS:     DS      CDC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckInterfaces	Proc near
    movzx ecx,ds:cdc_unit_count
    mov ebx,OFFSET cdc_unit_arr

ciLoop:
    mov fs,ds:[ebx]
    mov al,fs:unit_in_endp
    or al,al
    jz ciFail
;
    mov al,fs:unit_out_endp
    or al,al
    jz ciFail
;
    add ebx,2
    loop ciLoop
;
    clc
    jmp ciDone

ciFail:
    stc

ciDone:
    ret
CheckInterfaces	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           OpenControl
;
;   DESCRIPTION:    
;
;   PARAMETERS:     DS		CDC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenControl	Proc near
    CreateWait
    mov ds:cdc_control_wait,bx
;
    mov bx,ds:cdc_controller
    mov al,ds:cdc_device
    xor dl,dl
    OpenUsbPipe
    mov ds:cdc_control_pipe,bx
;
    mov ax,ds:cdc_control_pipe
    mov bx,ds:cdc_control_wait
    movzx ecx,bx
    AddWaitForUsbPipe
    ret
OpenControl	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           OpenInterface
;
;   DESCRIPTION:    
;
;   PARAMETERS:     DS		CDC selector
;                   FS		Interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenInterface	Proc near
    pushad
;
    CreateWait
    mov fs:unit_in_wait,bx
;
    mov bx,ds:cdc_controller
    mov al,ds:cdc_device
    mov dl,fs:unit_in_endp
    OpenUsbPipe
    mov fs:unit_in_pipe,bx
;
    mov ax,fs:unit_in_pipe
    mov bx,fs:unit_in_wait
    movzx ecx,bx
    AddWaitForUsbPipe
;
    CreateWait
    mov fs:unit_out_wait,bx
;
    mov bx,ds:cdc_controller
    mov al,ds:cdc_device
    mov dl,fs:unit_out_endp
    OpenUsbPipe
    mov fs:unit_out_pipe,bx
;
    mov ax,fs:unit_out_pipe
    mov bx,fs:unit_out_wait
    movzx ecx,bx
    AddWaitForUsbPipe
;
    popad
    ret
OpenInterface	Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CDC Thread
;
;   DESCRIPTION:    
;
;   PARAMETERS:     BX      CDC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cdc_thread_handler:
    int 3
    mov ds,ebx
    call FindInterfaces
    jc tFail
;
    call CheckInterfaces
    jc tFail
;
    call OpenControl
;
    movzx ecx,ds:cdc_unit_count
    mov ebx,OFFSET cdc_unit_arr

tOpenLoop:
    mov fs,ds:[ebx]
    call OpenInterface
;
    add ebx,2
    loop tOpenLoop
;

tFail:
        
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
;           NAME:       usb_attach
;
;           description:    USB attach callback
;
;           Parameters:     BX      Controller #
;               AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cdc_name    DB 'Usb Cdc ', 0

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
    mov gs:unit_in_endp,0
    mov gs:unit_out_endp,0
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
    push fs
    push gs
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
    push es
    push eax
    mov eax,SIZE cdc_struc
    AllocateSmallGlobalMem
    mov eax,es
    mov fs,eax
    pop eax
    pop es
;
    mov fs:cdc_controller,bx
    mov fs:cdc_device,al
    mov fs:cdc_abs_control_cap,0
    mov fs:cdc_unit_count,0
;
    mov cl,es:[edi].uid_sub_class
    mov fs:cdc_sub_class,cl
;
    mov cl,es:[edi].uid_proto
    mov fs:cdc_protocol,cl
    jmp uaDevNext

uaDevLoop:
    mov cl,es:[edi].ucd_type
    cmp cl,24h
    jne uaDevNext
;
    mov cl,es:[edi].ucdc_sub_type
    cmp cl,20h
    jae uaFreeFail
;
    movzx esi,cl
    shl esi,2
    call dword ptr cs:[esi].udesc_tab
    jc uaFreeFail

uaDevNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz uaFreeFail
;    
    add edi,ecx
    cmp di,es:ucd_size
    jb uaDevLoop

uaDevOk:
    mov bx,fs:cdc_controller
    mov al,fs:cdc_device
    ConfigUsbDevice
    jc uaFreeFail
;
    FreeMem
;
    mov eax,100h
    AllocateSmallGlobalMem
    xor di,di
    mov si,OFFSET cdc_name

uaCopyCdc:
    mov al,cs:[si]
    inc si
    or al,al
    jz uaCopyDone
;
    stosb
    jmp uaCopyCdc

uaCopyDone:
    mov ax,fs:cdc_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,fs:cdc_device
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;            
    mov ebx,fs
    xor edi,edi
    mov edx,cs
    mov ds,edx
    mov esi,OFFSET cdc_thread_handler
    mov eax,3
    mov ecx,stack0_size
    CreateThread
;
    FreeMem
    jmp uaDone

uaFreeFail:
    FreeMem
    mov eax,fs
    mov es,eax

uaFail:
    FreeMem

uaDone:
    popad
    pop gs
    pop fs
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
