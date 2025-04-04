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
; CDC.ASM
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
include cdc.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

MAX_DEVICES	= 16

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

data    SEGMENT byte public 'DATA'

sd_dead_list    DW ?
sd_section      section_typ <>

sd_dev_count    DW ?
sd_dev_arr      DW MAX_DEVICES DUP(?)

data	ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           FindAnyDevice
;
;    Description:    Search for dead device
;
;    Parameters:     DS         Data seg
;                    ES   	Descriptor
;                    ESI        Vendor & product
;                    EBP	Descriptor size
;
;    Returns:        ECX	Number of matches
;                    GS         CDC sel of last match
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindAnyDevice	Proc near
    push ds
    push eax
    push ebx
    push edx
    push edi
;
    xor ecx,ecx
;
    mov bx,ds:sd_dead_list
    or bx,bx
    jz fadDone
;
    mov dx,bx

fadLoop:
    mov ds,ebx
    mov ax,ds:cdc_vendor
    shl eax,16
    mov ax,ds:cdc_product
    cmp eax,esi
    jne fadNext
;
    movzx eax,ds:cdc_dev_descr_size
    cmp eax,ebp
    jne fadNext
;
    push ecx
    push esi
;
    mov ecx,ebp
    mov esi,OFFSET cdc_dev_descr_buf
    xor edi,edi
    repe cmpsb
;
    pop esi
    pop ecx
    jnz fadNext
;
    inc ecx
    mov eax,ds
    mov gs,eax

fadNext:
    mov bx,ds:cdc_next
    cmp bx,dx
    jne fadLoop

fadDone:
    pop edi
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
FindAnyDevice	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           FindSpecificDevice
;
;    Description:    Search for dead device
;
;    Parameters:     DS      Data seg
;                    BX      Controller #
;                    AL      Port #
;
;    Returns:        NC	     Found
;                        GS  CDC sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindSpecificDevice	Proc near
    push ds
    push ecx
    push edx
;
    mov cx,ds:sd_dead_list
    or cx,cx
    stc
    jz fsdDone
;
    mov dx,cx

fsdLoop:
    mov ds,ecx
    cmp bx,ds:cdc_controller
    jne fsdNext
;
    cmp al,ds:cdc_port
    jne fsdNext
;
    mov ecx,ds
    mov gs,ecx
    clc
    jmp fsdDone

fsdNext:
    mov cx,ds:cdc_next
    cmp cx,dx
    jne fsdLoop
;
    stc

fsdDone:
    pop edx
    pop ecx    
    pop ds
    ret
FindSpecificDevice	Endp

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

    extern cdc_com_start:near
    extern cdc_com_recreate:near

cdc_name    DB 'Cdc Com ', 0

error_descr	Proc near
    stc
    ret
error_descr	Endp

header_descr	Proc near
    clc
    ret
header_descr	Endp

call_descr	Proc near
;    mov cl,es:[edi].ucdccall_cap
;    test cl,1
;    jz cdOk
;
;    stc
;    jmp cdDone

cdOk:
    clc

cdDone:
    ret
call_descr	Endp

abs_control_descr	Proc near
    mov cl,es:[edi].ucdcc_cap
    mov es:cdc_abs_control_cap,cl
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
    mov es:cdc_unit_count,cl
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
    mov gs:unit_com_sel,0
    mov gs:unit_bulk_in,0
    mov gs:unit_bulk_out,0
;
    mov es:[esi],gs
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
    mov si,es:udd_vendor
    shl esi,16
    mov si,es:udd_prod
;
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
    mov ebp,ecx
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
    mov cx,SEG data
    mov ds,ecx
    EnterSection ds:sd_section
;
    call FindAnyDevice
    or ecx,ecx
    jz uaNotDead
;
    cmp ecx,1
    je uaRecreate
;
    call FindSpecificDevice
    jc uaNotDead

uaRecreate:
    push ds
    mov si,gs
    mov di,gs:cdc_next
    cmp di,si
    mov ds:sd_dead_list,di
    mov si,gs:cdc_prev
    mov ds,di
    mov ds:cdc_prev,si
    mov ds,si
    mov ds:cdc_next,di
    pop ds
    jne uaReConfig
;    
    mov ds:sd_dead_list,0

uaReConfig:
    LeaveSection ds:sd_section
;
    ConfigUsbDevice
    jc uaFail
;
    mov gs:cdc_controller,bx
    mov gs:cdc_port,al
;
    mov ebx,gs
    mov ds,ebx
    call cdc_com_recreate
    jmp uaDone

uaNotDead:
    LeaveSection ds:sd_section
;
    push eax
    push ebx
    push esi
;
    mov ebx,edi
    mov eax,es
    mov ds,eax
;
    mov eax,OFFSET cdc_dev_descr_buf
    add eax,ebp
    AllocateSmallGlobalMem
;
    mov ecx,ebp
    xor esi,esi
    mov edi,OFFSET cdc_dev_descr_buf
    rep movsb
;
    push es
    mov eax,ds
    mov es,eax
    xor eax,eax
    mov ds,eax
    FreeMem
    pop es
;
    mov es:cdc_dev_descr_size,bp
    mov edi,ebx
    add edi,OFFSET cdc_dev_descr_buf
    add ebp,OFFSET cdc_dev_descr_buf
;
    pop esi
    pop ebx
    pop eax
;
    mov es:cdc_product,si
    shr esi,16
    mov es:cdc_vendor,si
    mov es:cdc_controller,bx
    mov es:cdc_port,al
    mov es:cdc_abs_control_cap,0
    mov es:cdc_unit_count,0
    mov es:cdc_com_count,0
    mov es:cdc_flags,0
;
    mov cl,es:[edi].uid_sub_class
    mov es:cdc_sub_class,cl
;
    mov cl,es:[edi].uid_proto
    mov es:cdc_protocol,cl
    jmp uaDevNext

uaDevLoop:
    mov cl,es:[edi].ucd_type
    cmp cl,24h
    jne uaDevNext
;
    mov cl,es:[edi].ucdc_sub_type
    cmp cl,20h
    jae uaFail
;
    movzx esi,cl
    shl esi,2
    call dword ptr cs:[esi].udesc_tab
    jc uaFail

uaDevNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz uaFail
;    
    add edi,ecx
    cmp edi,ebp
    jb uaDevLoop

uaDevOk:
    mov bx,es:cdc_controller
    mov al,es:cdc_port
    ConfigUsbDevice
    jc uaFail
;
    mov edi,SEG data
    mov ds,edi
    movzx esi,ds:sd_dev_count
    add esi,esi
    mov ds:[esi].sd_dev_arr,es
    inc ds:sd_dev_count
    mov es:cdc_dev_offset,esi
;
    mov ebx,es
    mov ds,ebx
    call cdc_com_start
    jmp uaDone

uaFail:
    FreeMem

uaDone:
    popad
    pop gs
    pop es
    pop ds
    ret
usb_attach  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           usb_detach
;
;           description:    USB detach callback
;
;           Parameters:     BX      Controller #
;                           AL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extern cdc_com_detach:near

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    mov edx,SEG data
    mov ds,edx
    mov esi,OFFSET sd_dev_arr
    movzx ecx,ds:sd_dev_count
    or ecx,ecx
    jz udDone

udCheckLoop:
    mov dx,[esi]
    or dx,dx
    jz udCheckNext
;
    mov es,dx
    cmp bx,es:cdc_controller
    jne udCheckNext
;
    cmp al,es:cdc_port
    jne udCheckNext
;
    or es:cdc_flags,FLAG_CDC_DISCONNECT
    mov bx,es
    call cdc_com_detach
;
    EnterSection ds:sd_section
    mov di,ds:sd_dead_list
    or di,di
    je udInsEmpty
;
    push ds
    push si
;
    mov ds,di
    mov si,ds:cdc_prev
    mov ds:cdc_prev,es
    mov ds,si
    mov ds:cdc_next,es
    mov es:cdc_next,di
    mov es:cdc_prev,si
;
    pop si
    pop ds
    jmp udInsDone
    
udInsEmpty:
    mov es:cdc_next,es
    mov es:cdc_prev,es
    mov ds:sd_dead_list,es

udInsDone:
    LeaveSection ds:sd_section
    jmp udDone

udCheckNext:
    add esi,2    
    sub ecx,1
    jnz udCheckLoop

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

    extern init_cdc_com:near

Init    Proc far
    mov ax,SEG data
    mov ds,eax
    mov ds:sd_dev_count,0
    mov ds:sd_dead_list,0
    InitSection ds:sd_section
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
;
    call init_cdc_com
    clc
    ret
Init    Endp
        
code    ENDS

    END Init
