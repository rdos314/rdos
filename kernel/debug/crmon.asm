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
; crmon.ASM
; Crash monitor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\core.inc
INCLUDE kdebug.inc
INCLUDE emseg.inc

flat_sel = 20h

exec_s  STRUC

exec_row         DW ?
exec_col         DW ?
exec_size        DW ?
exec_reg         DD ?
exec_inc_proc    DD ?
exec_dec_proc    DD ?
exec_set_proc    DD ?

exec_s  ENDS

usb_device_descr	STRUC

udd_len		DB ?
udd_type	DB ?
udd_usb_ver	DW ?
udd_class	DB ?
udd_sub_class	DB ?
udd_proto	DB ?
udd_maxlen	DB ?
udd_vendor	DW ?
udd_prod	DW ?
udd_device	DW ?
udd_man		DB ?
udd_prodid	DB ?
udd_num		DB ?
udd_configs	DB ?

usb_device_descr	ENDS

usb_config_descr	STRUC

ucd_len	    		DB ?
ucd_type	    	DB ?
ucd_size		    DW ?
ucd_interface_count	DB ?
ucd_config_id		DB ?
ucd_config_str		DB ?
ucd_attrib  		DB ?
ucd_power	    	DB ?

usb_config_descr	ENDS

usb_endpoint_descr  STRUC

ued_len             DB ?
ued_type            DB ?
ued_address         DB ?
ued_attrib          DB ?
ued_maxsize         DW ?
ued_interval        DB ?

usb_endpoint_descr  ENDS

usb_interface_descr  STRUC

uid_len             DB ?
uid_type            DB ?
uid_id              DB ?
uid_alt_id          DB ?
uid_endpoints       DB ?
uid_class           DB ?
uid_sub_class       DB ?
uid_proto           DB ?
uid_interface_id    DB ?

usb_interface_descr  ENDS

    .386p

code    SEGMENT byte public use32 'CODE'

    assume cs:code
    
    extrn DisAsmCode:near
    extrn InitCrashKeyboard:near
    extrn GetCrashKey:near
    extrn Emulate:near

    extrn InitOhci:near
    extrn AddOhci:near
    extrn CheckOhci:near

    extrn InitEhci:near
    extrn AddEhci:near
    extrn CheckEhci:near

    extrn InitXhci:near
    extrn AddXhci:near
    extrn CheckXhci:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapUsbFunc
;
;           DESCRIPTION:    Map USB function
;
;           PARAMETERS:     EBX:EAX     physical address
;
;           RETURNS:        EDX         Linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public MapUsbFunc

MapUsbFunc       Proc near
    push ds
    push eax
    push ecx
;
    mov al,67h
    and ah,0F0h
;
    mov cx,mon_data_sel
    mov ds,cx
    mov edx,ds:mon_usb_func_linear
    push edx
;    
    mov cx,mon_process_page_sel
    mov ds,cx
;
    mov ecx,cr4
    test cl,20h
    jnz mufPae

mufProt:    
    shr edx,10
    and dl,0FCh
    mov [edx],eax
    jmp mufDone

mufPae:
    shr edx,9
    and dl,0F8h
    mov [edx],eax
    mov [edx+4],ebx

mufDone:
    mov ecx,cr3
    mov cr3,ecx
    pop edx
;    
    pop ecx
    pop eax
    pop ds
    ret
MapUsbFunc       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapPhysical
;
;           DESCRIPTION:    Map physical address
;
;           PARAMETERS:     EBX:EAX     physical address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapPhysical       Proc near
    push ds
    push eax
    push ecx
    push edx
;
    mov al,67h
    and ah,0F0h
;
    mov cx,mon_data_sel
    mov ds,cx
    mov edx,ds:mon_map_linear
;    
    mov cx,mon_process_page_sel
    mov ds,cx
;
    mov ecx,cr4
    test cl,20h
    jnz mpPae

mpProt:    
    shr edx,10
    and dl,0FCh
    mov [edx],eax
    jmp mpDone

mpPae:
    shr edx,9
    and dl,0F8h
    mov [edx],eax
    mov [edx+4],ebx

mpDone:
    mov ecx,cr3
    mov cr3,ecx
;    
    pop edx    
    pop ecx
    pop eax
    pop ds
    ret
MapPhysical       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapReadLinear
;
;           DESCRIPTION:    Map linear address for read
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                               ES:EBX  Mapping
;                           CY
;                               CL      Fault code
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapReadLinear       Proc near
    push fs
    push eax
    push edx
    push esi
;
    mov ax,mon_flat_sel
    mov es,ax    
;    
    mov ax,mon_data_sel
    mov fs,ax
;
    test dword ptr ds:[ebp].reg_cr0, CR0_PG
    jnz mrlPaged
;
    mov edx,ebx
    mov eax,ebx
    xor ebx,ebx    
    call MapPhysical
;    
    mov ebx,edx
    and ebx,0FFFh    
    add ebx,fs:mon_map_linear
    clc
    jmp mrlDone
    
mrlPaged:
    mov edx,ebx
    mov eax,ds:[ebp].reg_cr3
    xor ebx,ebx
    call MapPhysical
;
    test ds:[ebp].reg_efer,EFER_LME
    jnz mrlLong
;    
    test ds:[ebp].reg_cr4,20h
    jnz mrlPae

mrlProt:
    mov esi,edx
    shr esi,20
    and esi,0FFCh
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mrlFail
;
    xor ebx,ebx
    call MapPhysical
;
    mov esi,edx
    shr esi,10
    and esi,0FFCh
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mrlFail
;
    xor ebx,ebx
    call MapPhysical
;    
    mov ebx,edx
    and ebx,0FFFh    
    add ebx,fs:mon_map_linear
    clc
    jmp mrlDone

mrlPae:
    mov esi,edx
    shr esi,27
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mrlFail
;
    mov ebx,es:[esi+4]
    call MapPhysical
;
    mov esi,edx
    shr esi,18
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mrlFail
;
    test al,80h
    jz mrlNot2M
;
    mov ebx,edx
    and ebx,1FF000h
    or eax,ebx
    and al,7Fh  ; NOT 80h
    jmp mrlMapFinal

mrlNot2M:
    mov ebx,es:[esi+4]
    call MapPhysical
;
    mov esi,edx
    shr esi,9
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mrlFail

mrlMapFinal:
    mov ebx,es:[esi+4]
    call MapPhysical
;    
    mov ebx,edx
    and ebx,0FFFh    
    add ebx,fs:mon_map_linear
    clc
    jmp mrlDone

mrlLong:
    mov esi,edi
    shr esi,4
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mrlFail
;
    mov ebx,es:[esi+4]
    call MapPhysical
;    
    mov esi,edx
    shr esi,27
    mov eax,edi
    shl eax,5
    or si,ax
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mrlFail
;
    mov ebx,es:[esi+4]
    call MapPhysical
;
    mov esi,edx
    shr esi,18
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mrlFail
;
    mov ebx,es:[esi+4]
    call MapPhysical
;
    mov esi,edx
    shr esi,9
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mrlFail
;
    mov ebx,es:[esi+4]
    call MapPhysical
    mov ebx,edx
    and ebx,0FFFh    
    add ebx,fs:mon_map_linear
    clc
    jmp mrlDone

mrlFail:
    xor cl,cl
    stc

mrlDone: 
    pop esi
    pop edx
    pop eax
    pop fs
    ret
MapReadLinear       Endp           
            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapWriteLinear
;
;           DESCRIPTION:    Map linear address for write
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                               ES:EBX  Mapping
;                           CY
;                               CL      Fault code
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapWriteLinear       Proc near
    push fs
    push eax
    push edx
    push esi
;
    mov ax,mon_flat_sel
    mov es,ax    
;    
    mov ax,mon_data_sel
    mov fs,ax
;
    test dword ptr ds:[ebp].reg_cr0, CR0_PG
    jnz mwlPaged
;
    mov edx,ebx
    mov eax,ebx
    xor ebx,ebx    
    call MapPhysical
;    
    mov ebx,edx
    and ebx,0FFFh    
    add ebx,fs:mon_map_linear
    clc
    jmp mwlDone
    
mwlPaged:
    mov edx,ebx
    mov eax,ds:[ebp].reg_cr3
    xor ebx,ebx
    call MapPhysical
;
    test ds:[ebp].reg_efer,EFER_LME
    jnz mwlLong
;    
    test ds:[ebp].reg_cr4,20h
    jnz mwlPae

mwlProt:
    mov esi,edx
    shr esi,20
    and esi,0FFCh
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mwlFail
;
    test al,2
    jz mwlFail
;
    xor ebx,ebx
    call MapPhysical
;
    mov esi,edx
    shr esi,10
    and esi,0FFCh
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mwlFail
;
    test al,2
    jz mwlFail
;
    xor ebx,ebx
    call MapPhysical
;    
    mov ebx,edx
    and ebx,0FFFh    
    add ebx,fs:mon_map_linear
    clc
    jmp mwlDone

mwlPae:
    mov esi,edx
    shr esi,27
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mwlFail
;
    mov ebx,es:[esi+4]
    call MapPhysical
;
    mov esi,edx
    shr esi,18
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mwlFail
;
    test al,2
    jz mwlFail
;
    test al,80h
    jz mwlNot2M
;
    mov ebx,edx
    and ebx,1FF000h
    or eax,ebx
    and al,7Fh   ; NOT 80h
    jmp mwlMapFinal

mwlNot2M:
    mov ebx,es:[esi+4]
    call MapPhysical
;
    mov esi,edx
    shr esi,9
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mwlFail
;
    test al,2
    jz mwlFail

mwlMapFinal:
    mov ebx,es:[esi+4]
    call MapPhysical
;    
    mov ebx,edx
    and ebx,0FFFh    
    add ebx,fs:mon_map_linear
    clc
    jmp mwlDone

mwlLong:
    mov esi,edi
    shr esi,4
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mwlFail
;
    test al,2
    jz mwlFail
;
    mov ebx,es:[esi+4]
    call MapPhysical
;    
    mov esi,edx
    shr esi,27
    mov eax,edi
    shl eax,5
    or si,ax
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mwlFail
;
    test al,2
    jz mwlFail
;
    mov ebx,es:[esi+4]
    call MapPhysical
;
    mov esi,edx
    shr esi,18
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mwlFail
;
    test al,2
    jz mwlFail
;
    mov ebx,es:[esi+4]
    call MapPhysical
;
    mov esi,edx
    shr esi,9
    and esi,0FF8h
    add esi,fs:mon_map_linear
    mov eax,es:[esi]
    test al,1
    jz mwlFail
;
    test al,2
    jz mwlFail
;
    mov ebx,es:[esi+4]
    call MapPhysical
    mov ebx,edx
    and ebx,0FFFh    
    add ebx,fs:mon_map_linear
    clc
    jmp mwlDone

mwlFail:
    test al,1
    jz mwlNotPresent
;
    mov cl,3
    stc
    jmp mwlDone

mwlNotPresent:
    xor cl,cl
    stc

mwlDone: 
    pop esi
    pop edx
    pop eax
    pop fs
    ret
MapWriteLinear       Endp           

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondReadLinearByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                               AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondReadLinearByte   PROC near
    push es
    push ebx
    push cx
;    
    call MapReadLinear
    jc crlbDone
;    
    mov al,es:[ebx]
    clc
    
crlbDone:
    pop cx
    pop ebx
    pop es
    ret
CondReadLinearByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FaultSetCr2
;
;           DESCRIPTION:    Set CR2 and generate page fault
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           CL          Fault code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FaultSetCr2:
    mov bx,ds:[ebp].reg_cs.d_selector
    and bl,3
    cmp bl,3
    jne FaultSetCr2UserOk
;
    or cl,4

FaultSetCr2UserOk:
    pop ebx
    pop es
;
    mov ds:[ebp].reg_cr2,ebx
    mov ds:[ebp].reg_cr2+4,edi
    movzx ebx,cl
    jmp PageFault

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLinearByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadLinearByte

ReadLinearByte   PROC near
    push es
    push ebx
;    
    call MapReadLinear
    jc FaultSetCr2
;    
    mov al,es:[ebx]
;
    pop ebx
    pop es
    ret
ReadLinearByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondWriteLinearByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondWriteLinearByte   PROC near
    push es
    push ebx
    push cx
;    
    call MapWriteLinear
    jc cwlbDone
;    
    mov es:[ebx],al
    clc

cwlbDone:
    pop cx
    pop ebx
    pop es
    ret
CondWriteLinearByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLinearByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteLinearByte

WriteLinearByte   PROC near
    push es
    push ebx
;    
    push ax
    mov ax,ds:[ebp].reg_cs.d_selector
    and al,3
    cmp al,3
    pop ax
    je WriteLinearUser

WriteLinearKernel:
    call MapReadLinear
    jc FaultSetCr2
;
    jmp WriteLinearDone

WriteLinearUser:
    call MapWriteLinear
    jc FaultSetCr2

WriteLinearDone:    
    mov es:[ebx],al
;
    pop ebx
    pop es
    ret
WriteLinearByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondReadLinearWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                               AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondReadLinearWord   PROC near
    push ebx
    push esi
;
    call CondReadLinearByte
    movzx si,al
    jc crlwDone
;
    inc ebx
    call CondReadLinearByte
    jc crlwDone
;
    shl ax,8
    and ax,0FF00h
    or ax,si
    clc

crlwDone: 
    pop esi   
    pop ebx
    ret
CondReadLinearWord   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLinearWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadLinearWord

ReadLinearWord   PROC near
    push ebx
    push esi
;
    call ReadLinearByte
;
    movzx si,al
    inc ebx
    call ReadLinearByte
;
    shl ax,8
    and ax,0FF00h
    or ax,si
;
    pop esi   
    pop ebx
    ret
ReadLinearWord   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondWriteLinearWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           AX          Value
;
;           RETURNS:        NC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondWriteLinearWord   PROC near
    push eax
    push ebx
;
    call CondWriteLinearByte
    jc cwlwDone
;
    mov al,ah
    inc ebx
    call CondWriteLinearByte

cwlwDone: 
    pop ebx
    pop eax
    ret
CondWriteLinearWord   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLinearWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           AX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteLinearWord

WriteLinearWord   PROC near
    push eax
    push ebx
;
    call WriteLinearByte
;
    mov al,ah
    inc ebx
    call WriteLinearByte
;
    pop ebx
    pop eax
    ret
WriteLinearWord   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondReadLinearDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                               EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondReadLinearDword   PROC near
    push ebx
    push esi
;
    call CondReadLinearByte
    movzx esi,al
    jc crldDone
;
    inc ebx
    call CondReadLinearByte
    jc crldDone
;
    shl ax,8
    and eax,0FF00h
    or esi,eax
;
    inc ebx
    call CondReadLinearByte
    jc crldDone
;    
    shl eax,16
    and eax,0FF0000h
    or esi,eax
;
    inc ebx
    call CondReadLinearByte
    jc crldDone
;
    shl eax,24
    and eax,0FF000000h
    or esi,eax
;
    mov eax,esi    
    clc

crlddone: 
    pop esi   
    pop ebx
    ret
CondReadLinearDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLinearDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:            EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadLinearDword

ReadLinearDword   PROC near
    push ebx
    push esi
;
    call ReadLinearByte
    movzx esi,al
;
    inc ebx
    call ReadLinearByte
;
    shl ax,8
    and eax,0FF00h
    or esi,eax
;
    inc ebx
    call ReadLinearByte
;    
    shl eax,16
    and eax,0FF0000h
    or esi,eax
;
    inc ebx
    call ReadLinearByte
;
    shl eax,24
    and eax,0FF000000h
    or esi,eax
    mov eax,esi    
;
    pop esi   
    pop ebx
    ret
ReadLinearDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondWriteLinearDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           EAX         Value
;
;           RETURNS:        NC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondWriteLinearDword   PROC near
    push eax
    push ebx
    push esi
;
    call CondWriteLinearByte
    jc cwldDone
;
    inc ebx
    shr eax,8
    call CondWriteLinearByte
    jc cwldDone
;
    inc ebx
    shr eax,8
    call CondWriteLinearByte
    jc cwldDone
;    
    inc ebx
    shr eax,8
    call CondWriteLinearByte

cwlddone: 
    pop esi   
    pop ebx
    pop eax
    ret
CondWriteLinearDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLinearDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           EAX         Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteLinearDword

WriteLinearDword   PROC near
    push eax
    push ebx
    push esi
;
    call WriteLinearByte
;
    inc ebx
    shr eax,8
    call WriteLinearByte
;
    inc ebx
    shr eax,8
    call WriteLinearByte
;    
    inc ebx
    shr eax,8
    call WriteLinearByte
;
    pop esi   
    pop ebx
    pop eax
    ret
WriteLinearDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondReadLinearFword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                             DX:EAX  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondReadLinearFword   PROC near
    push ebx
;
    call CondReadLinearDword
    jc crlfDone    
;
    mov edx,eax
    add ebx,4
    call CondReadLinearWord
    jc crlfDone
;
    xchg eax,edx
    clc

crlfDone:
    pop ebx
    ret
CondReadLinearFword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLinearFword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:          DX:EAX  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadLinearFword

ReadLinearFword   PROC near
    push ebx
;
    call ReadLinearDword
;
    mov edx,eax
    add ebx,4
    call ReadLinearWord
;
    xchg eax,edx
;
    pop ebx
    ret
ReadLinearFword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondWriteLinearFword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           DX:EAX      Value
;
;           RETURNS:        NC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondWriteLinearFword   PROC near
    push eax
    push ebx
;
    call CondWriteLinearDword
    jc cwlfDone    
;
    mov ax,dx
    add ebx,4
    call CondWriteLinearWord

cwlfDone:
    pop ebx
    pop eax
    ret
CondWriteLinearFword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLinearFword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           DX:EAX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteLinearFword

WriteLinearFword   PROC near
    push eax
    push ebx
;
    call WriteLinearDword
;
    mov ax,dx
    add ebx,4
    call WriteLinearWord
;
    pop ebx
    pop eax
    ret
WriteLinearFword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondReadLinearQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                             EDX:EAX  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondReadLinearQword   PROC near
    call CondReadLinearDword
    jc crlqDone    
;
    mov edx,eax
    add ebx,4
    call CondReadLinearDword
    jc crlqDone
;
    xchg eax,edx
    clc

crlqDone:
    ret
CondReadLinearQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLinearQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        EDX:EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadLinearQword

ReadLinearQword   PROC near
    push ebx
;
    call ReadLinearDword
;
    mov edx,eax
    add ebx,4
    call ReadLinearDword
;
    xchg eax,edx
;
    pop ebx
    ret
ReadLinearQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondWriteLinearQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           EDX:EAX     Value
;
;           RETURNS:        NC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondWriteLinearQword   PROC near
    push eax
    push ebx
;
    call CondWriteLinearDword
    jc cwlqDone    
;
    mov eax,edx
    add ebx,4
    call CondWriteLinearDword

cwlqDone:
    pop ebx
    pop eax
    ret
CondWriteLinearQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLinearQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           EDX:EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteLinearQword

WriteLinearQword   PROC near
    push eax
    push ebx
;
    call WriteLinearDword
;
    mov eax,edx
    add ebx,4
    call WriteLinearDword
;
    pop ebx
    pop eax
    ret
WriteLinearQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondReadLinearTByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        NC
;                             CX:EDX:EAX  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondReadLinearTByte   PROC near
    push ebx
    push esi
;
    call CondReadLinearDword
    jc crltDone    
;
    mov esi,eax
    add ebx,4
    call CondReadLinearDword
    jc crltDone
;
    mov edx,eax
    add ebx,4
    call CondReadLinearWord
    jc crltDone
;
    mov cx,ax
    mov eax,esi
    clc

crltDone:
    pop esi
    pop ebx
    ret
CondReadLinearTByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLinearTByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;
;           RETURNS:        CX:EDX:EAX  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadLinearTByte

ReadLinearTByte   PROC near
    push ebx
    push esi
;
    call ReadLinearDword
;
    mov esi,eax
    add ebx,4
    call ReadLinearDword
;
    mov edx,eax
    add ebx,4
    call ReadLinearWord
;
    mov cx,ax
    mov eax,esi
;
    pop esi
    pop ebx
    ret
ReadLinearTByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CondWriteLinearTByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           CX:EDX:EAX  Value
;
;           RETURNS:        NC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondWriteLinearTByte   PROC near
    push ebx
    push esi
;
    call CondWriteLinearDword
    jc cwltDone    
;
    add ebx,4
    mov eax,edx
    call CondWriteLinearDword
    jc cwltDone
;
    mov ax,cx
    add ebx,4
    call CondWriteLinearWord

cwltDone:
    pop esi
    pop ebx
    ret
CondWriteLinearTByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLinearTByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           EDI:EBX     Linear address
;                           CX:EDX:EAX  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteLinearTByte

WriteLinearTByte   PROC near
    push ebx
    push esi
;
    call WriteLinearDword
;
    add ebx,4
    mov eax,edx
    call WriteLinearDword
;
    mov ax,cx
    add ebx,4
    call WriteLinearWord
;
    pop esi
    pop ebx
    ret
WriteLinearTByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSelectorBaseSizeType
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           BX          Selector
;
;           RETURNS:        NC
;                               EDX     Base
;                               ECX     Size
;                               AL      Type (+5)
;                               AH      Big (+6)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSelectorBaseSizeType   PROC near
    push ebx
    push esi
    push edi
;
    movzx ebx,bx
    and bx,NOT 3
    or bx,bx
    jz get_info_fail
;
    test bx,4
    jz get_info_gdt

get_info_ldt:
    mov ecx,ds:[ebp].reg_ldt.d_limit
    mov eax,ds:[ebp].reg_ldt.d_base
    jmp get_info_do

get_info_gdt:
    mov ecx,ds:[ebp].reg_gdt.d_limit
    mov eax,ds:[ebp].reg_gdt.d_base

get_info_do:
    and bx,0FFF8h
    cmp ecx,ebx
    jc get_info_done
;
    movzx ebx,bx
    add ebx,eax
    xor edi,edi
    call CondReadLinearQword
;
    test dh,80h
    jz get_info_fail
;
    mov ecx,edx
    and ecx,0F0000h
    mov cx,ax
    test edx,800000h
    jz get_info_small
;
    shl ecx,12
    or cx,0FFFh

get_info_small:
    mov ebx,edx
    shr ebx,8
;    
    shr eax,16
    and eax,0FFFFh
;
    rol edx,8
    xchg dl,dh
    shl edx,16
    or edx,eax
    mov ax,bx
    clc
    jmp get_info_done

get_info_fail:
    stc

get_info_done:
    pop edi
    pop esi
    pop ebx
    ret
GetSelectorBaseSizeType   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           DX:EBX      Address
;
;           RETURNS:        NC
;                               AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadByte   PROC near
    push ebx
    push ecx
    push edx
    push edi
;    
    push ebx
    mov bx,dx
    call GetSelectorBaseSizeType
    pop ebx
    jc rbDone
;
    inc ecx
    cmp ecx,ebx
    jc rbDone
;
    add ebx,edx 
    xor edi,edi
    call CondReadLinearByte

rbDone:    
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret
ReadByte   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           DX:EBX      Address
;
;           RETURNS:        NC
;                               AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadWord   PROC near
    push ebx
    push ecx
    push edx
    push edi
;    
    push ebx
    mov bx,dx
    call GetSelectorBaseSizeType
    pop ebx
    jc rwDone
;
    add ecx,2
    cmp ecx,ebx
    jc rwDone
;
    add ebx,edx 
    xor edi,edi
    call CondReadLinearWord   

rwDone:    
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret
ReadWord   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           DX:EBX      Address
;
;           RETURNS:        NC
;                               EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadDword   PROC near
    push ebx
    push ecx
    push edx
    push edi
;    
    push ebx
    mov bx,dx
    call GetSelectorBaseSizeType
    pop ebx
    jc rdDone
;
    add ecx,4
    cmp ecx,ebx
    jc rdDone
;
    add ebx,edx 
    xor edi,edi
    call CondReadLinearDword

rdDone:    
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret
ReadDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBitness
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Registers
;                           BX          Selector
;
;           RETURNS:        NC
;                               DL      Bitness (0 = 16, 1 = 32)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBitness   PROC near
    push eax
    push ecx
;    
    call GetSelectorBaseSizeType
    jc get_bitness_done
;
    mov dl,ah
    shr dl,6
    and dl,1
    clc

get_bitness_done:
    pop ecx
    pop eax
    ret
GetBitness   ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Font8x19
;
;   DESCRIPTION:    8x19 font
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   public font8x19

font8x19:
f00 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f01 db 000h, 000h, 000h, 07Eh, 081h, 081h, 0A5h, 081h, 081h, 081h, 0BDh, 099h, 081h, 081h, 07Eh, 000h, 000h, 000h, 000h
f02 db 000h, 000h, 000h, 07Eh, 0FFh, 0FFh, 0DBh, 0FFh, 0FFh, 0FFh, 0C3h, 0E7h, 0FFh, 0FFh, 07Eh, 000h, 000h, 000h, 000h
f03 db 000h, 000h, 000h, 000h, 000h, 000h, 06Ch, 0FEh, 0FEh, 0FEh, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h, 000h, 000h, 000h
f04 db 000h, 000h, 000h, 000h, 000h, 000h, 010h, 038h, 07Ch, 0FEh, 0FEh, 07Ch, 038h, 010h, 000h, 000h, 000h, 000h, 000h
f05 db 000h, 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 0E7h, 0E7h, 0E7h, 0E7h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f06 db 000h, 000h, 000h, 000h, 018h, 018h, 03Ch, 07Eh, 0FFh, 0FFh, 0FFh, 07Eh, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f07 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f08 db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0E7h, 0C3h, 0C3h, 0C3h, 0E7h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
f09 db 000h, 000h, 000h, 000h, 000h, 000h, 03Ch, 066h, 042h, 042h, 042h, 066h, 03Ch, 000h, 000h, 000h, 000h, 000h, 000h
f0A db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0C3h, 099h, 0BDh, 0BDh, 0BDh, 099h, 0C3h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
f0B db 000h, 000h, 000h, 01Eh, 006h, 00Eh, 01Ah, 030h, 078h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 078h, 000h, 000h, 000h, 000h
f0C db 000h, 000h, 000h, 03Ch, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h, 018h, 000h, 000h, 000h, 000h
f0D db 000h, 000h, 000h, 03Fh, 033h, 033h, 03Fh, 030h, 030h, 030h, 030h, 030h, 070h, 0F0h, 0E0h, 000h, 000h, 000h, 000h
f0E db 000h, 000h, 000h, 07Fh, 063h, 063h, 07Fh, 063h, 063h, 063h, 063h, 063h, 067h, 0E7h, 0E6h, 0C0h, 000h, 000h, 000h
f0F db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 0DBh, 03Ch, 0E7h, 0E7h, 03Ch, 0DBh, 018h, 018h, 000h, 000h, 000h, 000h
f10 db 000h, 000h, 000h, 080h, 0C0h, 0E0h, 0F0h, 0F8h, 0FEh, 0FEh, 0F8h, 0F0h, 0E0h, 0C0h, 080h, 000h, 000h, 000h, 000h
f11 db 000h, 000h, 000h, 002h, 006h, 00Eh, 01Eh, 03Eh, 0FEh, 0FEh, 03Eh, 01Eh, 00Eh, 006h, 002h, 000h, 000h, 000h, 000h
f12 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 000h, 000h, 000h, 000h
f13 db 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 066h, 066h, 000h, 000h, 000h, 000h
f14 db 000h, 000h, 000h, 07Fh, 0DBh, 0DBh, 0DBh, 0DBh, 07Bh, 01Bh, 01Bh, 01Bh, 01Bh, 01Bh, 01Bh, 000h, 000h, 000h, 000h
f15 db 000h, 000h, 000h, 07Ch, 0C6h, 060h, 038h, 06Ch, 0C6h, 0C6h, 06Ch, 038h, 00Ch, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f16 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0FEh, 0FEh, 000h, 000h, 000h, 000h
f17 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 07Eh, 000h, 000h, 000h
f18 db 000h, 000h, 000h, 018h, 03Ch, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f19 db 000h, 000h, 000h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 03Ch, 018h, 000h, 000h, 000h, 000h
f1A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 00Ch, 0FEh, 00Ch, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1B db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 030h, 060h, 0FEh, 060h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1C db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h
f1D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 024h, 066h, 0FFh, 066h, 024h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f1E db 000h, 000h, 000h, 000h, 000h, 010h, 010h, 038h, 038h, 07Ch, 07Ch, 0FEh, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h
f1F db 000h, 000h, 000h, 000h, 000h, 0FEh, 0FEh, 07Ch, 07Ch, 038h, 038h, 010h, 010h, 000h, 000h, 000h, 000h, 000h, 000h
f20 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f21 db 000h, 000h, 000h, 018h, 03Ch, 03Ch, 03Ch, 03Ch, 018h, 018h, 018h, 018h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f22 db 000h, 000h, 066h, 066h, 066h, 024h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f23 db 000h, 000h, 000h, 06Ch, 06Ch, 06Ch, 0FEh, 06Ch, 06Ch, 06Ch, 06Ch, 0FEh, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h
f24 db 000h, 018h, 018h, 07Ch, 0C6h, 0C2h, 0C0h, 0C0h, 07Ch, 006h, 006h, 006h, 086h, 0C6h, 07Ch, 018h, 018h, 000h, 000h
f25 db 000h, 000h, 000h, 0C6h, 0C6h, 0CCh, 00Ch, 018h, 018h, 030h, 030h, 060h, 066h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f26 db 000h, 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 076h, 0DCh, 0DCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f27 db 000h, 000h, 018h, 018h, 018h, 030h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f28 db 000h, 000h, 000h, 00Ch, 018h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 018h, 00Ch, 000h, 000h, 000h, 000h
f29 db 000h, 000h, 000h, 030h, 018h, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 018h, 030h, 000h, 000h, 000h, 000h
f2A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 03Ch, 0FFh, 03Ch, 066h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f2B db 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 0FFh, 018h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 000h
f2C db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 030h, 000h, 000h, 000h
f2D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f2E db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f2F db 000h, 000h, 000h, 006h, 006h, 00Ch, 00Ch, 018h, 018h, 030h, 030h, 060h, 060h, 0C0h, 0C0h, 000h, 000h, 000h, 000h
f30 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0D6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f31 db 000h, 000h, 000h, 018h, 038h, 078h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 07Eh, 000h, 000h, 000h, 000h
f32 db 000h, 000h, 000h, 07Ch, 0C6h, 006h, 006h, 00Ch, 018h, 030h, 060h, 0C0h, 0C0h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f33 db 000h, 000h, 000h, 07Ch, 0C6h, 006h, 006h, 006h, 03Ch, 006h, 006h, 006h, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f34 db 000h, 000h, 000h, 01Ch, 01Ch, 03Ch, 03Ch, 06Ch, 06Ch, 0CCh, 0FEh, 00Ch, 00Ch, 00Ch, 01Eh, 000h, 000h, 000h, 000h
f35 db 000h, 000h, 000h, 0FEh, 0C0h, 0C0h, 0C0h, 0C0h, 0FCh, 006h, 006h, 006h, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f36 db 000h, 000h, 000h, 038h, 060h, 0C0h, 0C0h, 0C0h, 0FCh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f37 db 000h, 000h, 000h, 0FEh, 0C6h, 006h, 006h, 006h, 00Ch, 018h, 018h, 030h, 030h, 030h, 030h, 000h, 000h, 000h, 000h
f38 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f39 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 006h, 006h, 00Ch, 078h, 000h, 000h, 000h, 000h
f3A db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h
f3B db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 030h, 000h, 000h, 000h, 000h
f3C db 000h, 000h, 000h, 000h, 006h, 00Ch, 018h, 030h, 060h, 060h, 030h, 018h, 00Ch, 006h, 000h, 000h, 000h, 000h, 000h
f3D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f3E db 000h, 000h, 000h, 000h, 060h, 030h, 018h, 00Ch, 006h, 006h, 00Ch, 018h, 030h, 060h, 000h, 000h, 000h, 000h, 000h
f3F db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 006h, 006h, 00Ch, 018h, 018h, 018h, 000h, 018h, 018h, 000h, 000h, 000h, 000h
f40 db 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0DEh, 0DEh, 0DEh, 0DCh, 0C0h, 0C0h, 07Ch, 000h, 000h, 000h, 000h
f41 db 000h, 000h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f42 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 066h, 066h, 066h, 066h, 066h, 0FCh, 000h, 000h, 000h, 000h
f43 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C2h, 066h, 03Ch, 000h, 000h, 000h, 000h
f44 db 000h, 000h, 000h, 0F8h, 06Ch, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 06Ch, 0F8h, 000h, 000h, 000h, 000h
f45 db 000h, 000h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f46 db 000h, 000h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f47 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0DEh, 0C6h, 0C6h, 0C6h, 066h, 03Ah, 000h, 000h, 000h, 000h
f48 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f49 db 000h, 000h, 000h, 03Ch, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f4A db 000h, 000h, 000h, 00Fh, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f4B db 000h, 000h, 000h, 0E6h, 066h, 066h, 06Ch, 06Ch, 078h, 07Ch, 06Ch, 06Ch, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f4C db 000h, 000h, 000h, 0F0h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f4D db 000h, 000h, 000h, 0C6h, 0EEh, 0FEh, 0FEh, 0D6h, 0D6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f4E db 000h, 000h, 000h, 0C6h, 0C6h, 0E6h, 0E6h, 0F6h, 0F6h, 0DEh, 0DEh, 0CEh, 0CEh, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f4F db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
f50 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f51 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0D6h, 0DEh, 07Ch, 00Ch, 00Eh, 000h, 000h
f52 db 000h, 000h, 000h, 0FCh, 066h, 066h, 066h, 066h, 07Ch, 06Ch, 06Ch, 066h, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f53 db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C0h, 060h, 038h, 00Ch, 006h, 006h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f54 db 000h, 000h, 000h, 07Eh, 07Eh, 05Ah, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f55 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f56 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 010h, 000h, 000h, 000h, 000h
f57 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0FEh, 06Ch, 06Ch, 000h, 000h, 000h, 000h
f58 db 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 06Ch, 06Ch, 038h, 038h, 06Ch, 06Ch, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f59 db 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f5A db 000h, 000h, 000h, 0FEh, 0C6h, 086h, 006h, 00Ch, 018h, 030h, 060h, 0C0h, 0C2h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f5B db 000h, 000h, 000h, 03Ch, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 030h, 03Ch, 000h, 000h, 000h, 000h
f5C db 000h, 000h, 000h, 0C0h, 0C0h, 060h, 060h, 030h, 030h, 018h, 018h, 00Ch, 00Ch, 006h, 006h, 000h, 000h, 000h, 000h
f5D db 000h, 000h, 000h, 03Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 03Ch, 000h, 000h, 000h, 000h
f5E db 000h, 010h, 038h, 06Ch, 0C6h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f5F db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h
f60 db 000h, 000h, 030h, 018h, 00Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f61 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f62 db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 078h, 06Ch, 066h, 066h, 066h, 066h, 066h, 0DCh, 000h, 000h, 000h, 000h
f63 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f64 db 000h, 000h, 000h, 01Ch, 00Ch, 00Ch, 00Ch, 03Ch, 06Ch, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f65 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f66 db 000h, 000h, 000h, 038h, 06Ch, 064h, 060h, 060h, 0F0h, 060h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f67 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 07Ch, 00Ch, 00Ch, 0CCh, 078h, 000h
f68 db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 06Ch, 076h, 066h, 066h, 066h, 066h, 066h, 0E6h, 000h, 000h, 000h, 000h
f69 db 000h, 000h, 000h, 018h, 018h, 000h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f6A db 000h, 000h, 000h, 006h, 006h, 000h, 000h, 00Eh, 006h, 006h, 006h, 006h, 006h, 006h, 006h, 066h, 066h, 03Ch, 000h
f6B db 000h, 000h, 000h, 0E0h, 060h, 060h, 060h, 066h, 066h, 06Ch, 078h, 078h, 06Ch, 066h, 0E6h, 000h, 000h, 000h, 000h
f6C db 000h, 000h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f6D db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 0FEh, 0D6h, 0D6h, 0D6h, 0D6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f6E db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 000h, 000h, 000h
f6F db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f70 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 060h, 0F0h, 000h
f71 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 07Ch, 00Ch, 00Ch, 00Ch, 01Eh, 000h
f72 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0DCh, 076h, 066h, 060h, 060h, 060h, 060h, 0F0h, 000h, 000h, 000h, 000h
f73 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 060h, 038h, 00Ch, 006h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f74 db 000h, 000h, 000h, 010h, 030h, 030h, 030h, 0FCh, 030h, 030h, 030h, 030h, 030h, 036h, 01Ch, 000h, 000h, 000h, 000h
f75 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f76 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 000h, 000h, 000h, 000h
f77 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0D6h, 0D6h, 0D6h, 0FEh, 06Ch, 000h, 000h, 000h, 000h
f78 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 06Ch, 038h, 038h, 06Ch, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f79 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 00Ch, 078h, 000h
f7A db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0C6h, 00Ch, 018h, 030h, 060h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
f7B db 000h, 000h, 000h, 00Eh, 018h, 018h, 018h, 018h, 070h, 070h, 018h, 018h, 018h, 018h, 00Eh, 000h, 000h, 000h, 000h
f7C db 000h, 000h, 000h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f7D db 000h, 000h, 000h, 070h, 018h, 018h, 018h, 018h, 00Eh, 00Eh, 018h, 018h, 018h, 018h, 070h, 000h, 000h, 000h, 000h
f7E db 000h, 000h, 000h, 076h, 0DCh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
f7F db 000h, 000h, 000h, 000h, 000h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0FEh, 000h, 000h, 000h, 000h, 000h
f80 db 000h, 000h, 000h, 03Ch, 066h, 0C2h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C2h, 066h, 03Ch, 018h, 00Ch, 038h, 000h
f81 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f82 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f83 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f84 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f85 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f86 db 000h, 000h, 000h, 038h, 06Ch, 038h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f87 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Ch, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C6h, 07Ch, 018h, 00Ch, 038h, 000h
f88 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f89 db 000h, 000h, 000h, 000h, 0CCh, 0CCh, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f8A db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 07Ch, 0C6h, 0C6h, 0FEh, 0C0h, 0C0h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f8B db 000h, 000h, 000h, 000h, 066h, 066h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8C db 000h, 000h, 000h, 018h, 03Ch, 066h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8D db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
f8E db 0C6h, 0C6h, 000h, 010h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f8F db 038h, 06Ch, 038h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
f90 db 00Ch, 018h, 000h, 0FEh, 066h, 062h, 060h, 068h, 078h, 068h, 060h, 060h, 062h, 066h, 0FEh, 000h, 000h, 000h, 000h
f91 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0ECh, 036h, 036h, 07Eh, 0D8h, 0D8h, 0D8h, 06Eh, 000h, 000h, 000h, 000h
f92 db 000h, 000h, 000h, 03Eh, 06Ch, 0CCh, 0CCh, 0CCh, 0FEh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CEh, 000h, 000h, 000h, 000h
f93 db 000h, 000h, 000h, 010h, 038h, 06Ch, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f94 db 000h, 000h, 000h, 000h, 0C6h, 0C6h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f95 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f96 db 000h, 000h, 000h, 030h, 078h, 0CCh, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f97 db 000h, 000h, 000h, 060h, 030h, 018h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
f98 db 000h, 000h, 000h, 000h, 0C6h, 0C6h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Eh, 006h, 006h, 00Ch, 078h, 000h
f99 db 0C6h, 0C6h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
f9A db 0C6h, 0C6h, 000h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
f9B db 000h, 000h, 000h, 018h, 018h, 03Ch, 066h, 060h, 060h, 060h, 060h, 066h, 03Ch, 018h, 018h, 000h, 000h, 000h, 000h
f9C db 000h, 000h, 038h, 06Ch, 064h, 060h, 060h, 0F0h, 060h, 060h, 060h, 060h, 060h, 0E6h, 0FCh, 000h, 000h, 000h, 000h
f9D db 000h, 000h, 000h, 066h, 066h, 066h, 03Ch, 018h, 07Eh, 018h, 018h, 07Eh, 018h, 018h, 018h, 000h, 000h, 000h, 000h
f9E db 000h, 000h, 0F8h, 0CCh, 0CCh, 0CCh, 0F8h, 0C4h, 0CCh, 0DEh, 0CCh, 0CCh, 0CCh, 0CCh, 0C6h, 000h, 000h, 000h, 000h
f9F db 000h, 000h, 00Eh, 01Bh, 018h, 018h, 018h, 018h, 07Eh, 018h, 018h, 018h, 018h, 018h, 018h, 0D8h, 070h, 000h, 000h
fA0 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 078h, 00Ch, 00Ch, 07Ch, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
fA1 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 038h, 018h, 018h, 018h, 018h, 018h, 018h, 03Ch, 000h, 000h, 000h, 000h
fA2 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
fA3 db 000h, 000h, 000h, 00Ch, 018h, 030h, 000h, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 0CCh, 076h, 000h, 000h, 000h, 000h
fA4 db 000h, 000h, 000h, 000h, 076h, 0DCh, 000h, 0DCh, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 000h, 000h, 000h, 000h
fA5 db 076h, 0DCh, 000h, 0C6h, 0C6h, 0E6h, 0E6h, 0F6h, 0F6h, 0DEh, 0DEh, 0CEh, 0CEh, 0C6h, 0C6h, 000h, 000h, 000h, 000h
fA6 db 000h, 000h, 03Ch, 06Ch, 06Ch, 06Ch, 03Eh, 000h, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fA7 db 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 000h, 07Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fA8 db 000h, 000h, 000h, 030h, 030h, 000h, 030h, 030h, 030h, 060h, 0C0h, 0C0h, 0C6h, 0C6h, 07Ch, 000h, 000h, 000h, 000h
fA9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 0C0h, 0C0h, 0C0h, 0C0h, 000h, 000h, 000h, 000h, 000h, 000h
fAA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 006h, 006h, 006h, 006h, 000h, 000h, 000h, 000h, 000h, 000h
fAB db 000h, 000h, 0C0h, 0C0h, 0C0h, 0C2h, 0C6h, 0CCh, 018h, 030h, 060h, 0DCh, 0A6h, 00Ch, 018h, 030h, 03Eh, 000h, 000h
fAC db 000h, 000h, 0C0h, 0C0h, 0C0h, 0C2h, 0C6h, 0CCh, 018h, 030h, 060h, 0CCh, 09Ch, 03Ch, 07Eh, 00Ch, 00Ch, 000h, 000h
fAD db 000h, 000h, 000h, 018h, 018h, 000h, 000h, 018h, 018h, 018h, 018h, 03Ch, 03Ch, 03Ch, 018h, 000h, 000h, 000h, 000h
fAE db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 033h, 066h, 0CCh, 0CCh, 066h, 033h, 000h, 000h, 000h, 000h, 000h, 000h
fAF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0CCh, 066h, 033h, 033h, 066h, 0CCh, 000h, 000h, 000h, 000h, 000h, 000h
fB0 db 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h, 044h, 011h
fB1 db 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h, 0AAh, 055h
fB2 db 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh, 077h, 0DDh
fB3 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB4 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB6 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fB7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fB8 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 018h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fB9 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 006h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBA db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBB db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 006h, 0F6h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fBC db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F6h, 006h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBD db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FEh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBE db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 018h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fBF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0F8h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC0 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC1 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC2 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC3 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC4 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC6 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fC7 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fC8 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 030h, 03Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fC9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 03Fh, 030h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCA db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F7h, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fCB db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0F7h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCC db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 037h, 030h, 037h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCD db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fCE db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0F7h, 000h, 0F7h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fCF db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 000h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD0 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD1 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 000h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD2 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD3 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 03Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD4 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 01Fh, 018h, 01Fh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fD5 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 01Fh, 018h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD6 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 03Fh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD7 db 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 0FFh, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h, 036h
fD8 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0FFh, 018h, 0FFh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fD9 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0F8h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fDA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 01Fh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fDB db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
fDC db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
fDD db 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h, 0F0h
fDE db 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh, 00Fh
fDF db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fE0 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 0D8h, 0D8h, 0D8h, 0D8h, 0DCh, 076h, 000h, 000h, 000h, 000h
fE1 db 000h, 000h, 000h, 078h, 0CCh, 0CCh, 0CCh, 0CCh, 0D8h, 0CCh, 0C6h, 0C6h, 0C6h, 0C6h, 0DCh, 000h, 000h, 000h, 000h
fE2 db 000h, 000h, 000h, 0FEh, 0C6h, 0C6h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 0C0h, 000h, 000h, 000h, 000h
fE3 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 0FEh, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h
fE4 db 000h, 000h, 000h, 0FEh, 0C6h, 0C0h, 060h, 030h, 018h, 018h, 030h, 060h, 0C0h, 0C6h, 0FEh, 000h, 000h, 000h, 000h
fE5 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 0D8h, 070h, 000h, 000h, 000h, 000h
fE6 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 066h, 066h, 066h, 066h, 066h, 066h, 066h, 07Ch, 060h, 060h, 0C0h, 000h
fE7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 018h, 018h, 018h, 018h, 018h, 018h, 000h, 000h, 000h, 000h
fE8 db 000h, 000h, 000h, 03Ch, 018h, 03Ch, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 018h, 03Ch, 000h, 000h, 000h, 000h
fE9 db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0FEh, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 038h, 000h, 000h, 000h, 000h
fEA db 000h, 000h, 000h, 038h, 06Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 06Ch, 06Ch, 06Ch, 0EEh, 000h, 000h, 000h, 000h
fEB db 000h, 000h, 000h, 01Eh, 030h, 018h, 00Ch, 03Eh, 066h, 066h, 066h, 066h, 066h, 066h, 03Ch, 000h, 000h, 000h, 000h
fEC db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 07Eh, 0DBh, 0DBh, 0DBh, 0DBh, 07Eh, 000h, 000h, 000h, 000h, 000h, 000h
fED db 000h, 000h, 000h, 000h, 000h, 003h, 006h, 07Eh, 0CFh, 0DBh, 0DBh, 0F3h, 07Eh, 060h, 0C0h, 000h, 000h, 000h, 000h
fEE db 000h, 000h, 000h, 01Ch, 030h, 060h, 060h, 060h, 07Ch, 060h, 060h, 060h, 060h, 030h, 01Ch, 000h, 000h, 000h, 000h
fEF db 000h, 000h, 000h, 07Ch, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 0C6h, 000h, 000h, 000h, 000h
fF0 db 000h, 000h, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 0FEh, 000h, 000h, 000h, 000h, 000h
fF1 db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 018h, 07Eh, 018h, 018h, 018h, 000h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF2 db 000h, 000h, 000h, 000h, 060h, 030h, 018h, 00Ch, 006h, 00Ch, 018h, 030h, 060h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF3 db 000h, 000h, 000h, 000h, 006h, 00Ch, 018h, 030h, 060h, 030h, 018h, 00Ch, 006h, 000h, 07Eh, 000h, 000h, 000h, 000h
fF4 db 000h, 000h, 000h, 00Eh, 01Bh, 01Bh, 01Bh, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h
fF5 db 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 0D8h, 0D8h, 0D8h, 070h, 000h, 000h, 000h, 000h
fF6 db 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 07Eh, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h
fF7 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 076h, 0DCh, 000h, 000h, 076h, 0DCh, 000h, 000h, 000h, 000h, 000h, 000h
fF8 db 000h, 000h, 038h, 06Ch, 06Ch, 06Ch, 038h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fF9 db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFA db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 018h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFB db 000h, 000h, 00Fh, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 00Ch, 0ECh, 06Ch, 06Ch, 03Ch, 01Ch, 000h, 000h, 000h, 000h
fFC db 000h, 000h, 0D8h, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 06Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFD db 000h, 000h, 038h, 06Ch, 00Ch, 018h, 030h, 064h, 07Ch, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
fFE db 000h, 000h, 000h, 000h, 000h, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 07Ch, 000h, 000h, 000h, 000h, 000h
fFF db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           move_cursor
;
;           DESCRIPTION:    
;
;           PARAMETERS      CX              Column number (x)
;                           DX              Row number (y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_cursor Proc near
    push ds
    push eax
    push edx
;
    mov ax,mon_system_data_sel
    mov ds,ax
    mov ds:efi_text_row,cx
    mov ds:efi_text_col,dx    
;
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    pop ax
    jnz mcDone
;    
    mov ax,80
    mul ds:efi_text_row
    add ax,ds:efi_text_col
    mov bx,ax
;
    mov dx,3D4h
    mov al,0Eh
    out dx,al
;
    inc dx
    mov al,bh
    out dx,al
;
    dec dx
    mov al,0Fh
    out dx,al
;
    inc dx
    mov al,bl
    out dx,al

mcDone:
    pop edx
    pop eax
    pop ds
    ret
move_cursor Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowChar
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowChar Proc near
    push ds
    push es
    pushad
;   
    push eax
    mov ax,mon_system_data_sel
    mov ds,ax
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    pop eax
    jnz scLfb

scText:
    push eax
    mov ax,mon_text_sel
    mov es,ax
;
    mov ax,ds:efi_text_row
    mov cx,80
    mul cx
    add ax,ds:efi_text_col
    add ax,ax
    movzx edi,ax
    pop eax
    mov ah,7
    stosw
    jmp scUpdate

scLfb:
    push eax
    mov ax,mon_flat_sel
    mov es,ax
; 
    mov ax,ds:efi_text_row
    mov cx,19
    mul cx
    movzx eax,ax
    movzx edx,ds:efi_text_col
    shl edx,3
    xchg eax,edx
;
    push eax
    mov eax,ds:efi_scan_size
    mul edx
    mov edi,ds:mon_fixed_lfb
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
    pop eax
;
    mov ah,19
    mul ah
    movzx ebx,ax
    add ebx,OFFSET font8x19
;
    mov ecx,19

scRowLoop:    
    push ecx
    push edi
    mov ecx,8
    mov al,cs:[ebx]

scLoop:
    test al,80h
    jz scBack

scFore:
    mov edx,dword ptr ds:efi_fore_col
    mov es:[edi],edx
    jmp scNext

scBack:
    mov edx,dword ptr ds:efi_back_col
    mov es:[edi],edx

scNext:
    add edi,4
    shl al,1
;
    loop scLoop    
;
    pop edi
    pop ecx
    add edi,ds:efi_scan_size
    inc ebx
;
    loop scRowLoop    

scUpdate:
    inc ds:efi_text_col
    mov ax,ds:efi_text_col
    cmp ax,80
    jne scDone
;
    mov ds:efi_text_col,0
    inc ds:efi_text_row    

scDone:
    popad        
    pop es
    pop ds
    ret
ShowChar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InvertChar
;
;           DESCRIPTION:    CX  Col
;                           DX  Row
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
InvertChar Proc near
    push ds
    push es
    pushad
;   
    mov ax,mon_system_data_sel
    mov ds,ax
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    jz icDone

icLfb:
    mov ax,mon_flat_sel
    mov es,ax
; 
    push cx
    mov ax,dx
    mov cx,19
    mul cx
    movzx eax,ax
    pop dx
    movzx edx,dx
    shl edx,3
    xchg eax,edx
;
    push eax
    mov eax,ds:efi_scan_size
    mul edx
    mov edi,ds:mon_fixed_lfb
    add edi,eax
    pop eax
    shl eax,2
    add edi,eax
;
    mov ecx,19

icRowLoop:    
    push ecx
    push edi
    mov ecx,8

icLoop:
    mov eax,es:[edi]
    not eax
    mov es:[edi],eax
    add edi,4
    loop icLoop    
;
    pop edi
    pop ecx
    add edi,ds:efi_scan_size
;
    loop icRowLoop    

icDone:
    popad        
    pop es
    pop ds
    ret
InvertChar Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowMarker
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowMarker Proc near
    push ds
    push es
    push eax
    push ecx
    push edx
    push edi
;
    mov ax,mon_system_data_sel
    mov ds,ax
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    jnz smLfb

smText:
    mov ax,mon_text_sel
    mov es,ax
;    
    mov ax,mon_data_sel
    mov ds,ax
;
    mov ax,ds:mon_curr_row
    mov dx,80
    mul dx
    add ax,ds:mon_curr_col
    add ax,ax
    movzx edi,ax
    inc edi
    mov al,70h
    stosb
    jmp smDone

smLfb:
    mov ax,mon_data_sel
    mov ds,ax
    mov dx,ds:mon_curr_row
    mov cx,ds:mon_curr_col
    call InvertChar

smDone:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds    
    ret
ShowMarker Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HideMarker
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HideMarker Proc near
    push ds
    push es
    push eax
    push ecx
    push edx
    push edi
;
    mov ax,mon_system_data_sel
    mov ds,ax
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    jnz hmLfb

hmText:
    mov ax,mon_text_sel
    mov es,ax
;    
    mov ax,mon_data_sel
    mov ds,ax
;
    mov ax,ds:mon_curr_row
    mov dx,80
    mul dx
    add ax,ds:mon_curr_col
    add ax,ax
    movzx edi,ax
    inc edi
    mov al,7
    stosb
    jmp hmDone

hmLfb:
    mov ax,mon_data_sel
    mov ds,ax
    mov dx,ds:mon_curr_row
    mov cx,ds:mon_curr_col
    call InvertChar

hmDone:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds    
    ret
HideMarker Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Clear
;
;           DESCRIPTION:    Clear screen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Clear Proc near
    push ds
    push es
    pushad
;    
    mov ax,mon_system_data_sel
    mov ds,ax 
    mov eax,ds:mon_fixed_lfb
    or eax,eax
    jnz cLfb

cText:
    xor edi,edi
    mov ax,mon_text_sel
    mov es,ax
    mov ax,0720h
    mov ecx,80 * 24
    rep stosw
    jmp cUpdate

cLfb:
    mov ax,mon_flat_sel
    mov es,ax
;
    mov edi,ds:mon_fixed_lfb
    movzx ecx,ds:efi_height

cLoop:
    push ecx    
    mov ecx,ds:efi_scan_size    
    xor ax,ax
    rep stos byte ptr es:[edi]
    pop ecx
    loop cLoop

cUpdate:
    mov ds:efi_text_col,0
    mov ds:efi_text_row,0
;
    popad
    pop es
    pop ds    
    ret
Clear Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NewLine
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NewLine Proc near
    push ds
    push ax
    push dx
;
    mov ax,mon_system_data_sel
    mov ds,ax

nlRetry:    
    mov al,' '
    call ShowChar
;
    mov dx,ds:efi_text_col
    or dx,dx
    jnz nlRetry
;
    pop dx
    pop ax
    pop ds
    ret
NewLine Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delimiter
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delimiter       Proc near
    push ax
    push ecx
    mov ecx,60
    mov al,'-'
    
write_delim_loop:
    call ShowChar
    loop write_delim_loop
;    
    pop ecx
    call NewLine
    pop ax
    ret
Delimiter       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Blank
;
;           DESCRIPTION:    
;
;           PARAMETERS:         ECX          Number of blanks to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Blank   Proc near
    push eax
    push ecx
    mov al,' '
    
blank_loop:
    call ShowChar
    loop blank_loop
    pop ecx
    pop eax
    ret
Blank   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowCodeAsciiz
;
;           DESCRIPTION:    Show asciiz string from code
;
;           PARAMETERS:     CS:ESI      String to add
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowCodeAsciiz   PROC near
    push ax

scaLoop:
    lods cs:[esi]
    or al,al
    jz scaDone
;
    call ShowChar
    jmp scaLoop    

scaDone:
    pop ax
    ret
ShowCodeAsciiz   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowCodeSizeString
;
;           DESCRIPTION:    
;
;           PARAMETERS:     CS:ESI       String
;                           ECX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowCodeSizeString Proc near
    push eax
    push ecx
    push esi
;
    or ecx,ecx
    jz scssDone

scssLoop:
    lods byte ptr cs:[esi]
    call ShowChar
    loop scssLoop    

scssDone:
    pop esi
    pop ecx
    pop eax    
    ret
ShowCodeSizeString Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ShowPtrSizeString
;
;           DESCRIPTION:    Show string in memory
;
;           PARAMETERS:     DX:EBX       Address
;                           ECX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowPtrSizeString Proc near
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    push ebx
    push ecx
    mov bx,dx
    call GetSelectorBaseSizeType
    mov esi,ecx
    pop ecx
    pop ebx
    jc spsDone
;
    inc esi

spsLoop:    
    cmp esi,ebx
    jc spsDone
;
    push ebx
    add ebx,edx 
    xor edi,edi
    call CondReadLinearByte
    pop ebx
    jc spsDone
;
    call ShowChar
;
    inc ebx    
    loop spsLoop    
    
spsDone:    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
ShowPtrSizeString Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AL          Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    PROC near
    push ax
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb write_byte_low1
;    
    add al,7

write_byte_low1:
    add al,'0'
    call ShowChar
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb write_byte_high1
;    
    add al,7

write_byte_high1:
    add al,'0'
    call ShowChar
    pop ax
    ret
WriteHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:         AX          Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    PROC near
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
    ret
WriteHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:         EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword   PROC near
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    ret
WriteHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     EDX:EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexQword   PROC near
    push eax
;    
    push eax
    mov eax,edx
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
;
    mov al,'_'
    call ShowChar
;
    pop eax
;    
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
    rol eax,8
    call WriteHexByte
;
    pop eax    
    ret
WriteHexQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexPtr16
;
;           DESCRIPTION:    
;
;           PARAMETERS:         DX          Segment
;                           BX          Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr16   PROC near
    push ax
    mov ax,dx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov ax,bx
    call WriteHexWord
    pop ax
    ret
WriteHexPtr16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexPtr32
;
;           DESCRIPTION:    
;
;           PARAMETERS:         DX          Segment
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexPtr32   PROC near
    push eax
    mov ax,dx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov eax,ebx
    call WriteHexDword
    pop eax
    ret
WriteHexPtr32   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteEflags
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DS:EBP      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eflags_tab:
;
;           reset       set
et_cf   DB 'NC ',       'CY '
et_1    DB 0,0,0,       0,0,0
et_pf   DB 'PO ',       'PE '
et_3    DB 0,0,0,       0,0,0
et_af   DB 'NA ',       'AC '
et_5    DB 0,0,0,       0,0,0
et_zf   DB 'NZ ',       'ZR '
et_sf   DB 'PL ',       'NG '
et_tf   DB 0,0,0,       0,0,0
et_if   DB 'DI ',       'EI '
et_df   DB 'UP ',       'DN '
et_of   DB 'NV ',       'OV '
et_12   DB 0,0,0,       0,0,0
et_13   DB 0,0,0,       0,0,0
et_14   DB 'PR ' ,      'NT '
et_15   DB 0,0,0,       0,0,0
et_16   DB 0,0,0,       0,0,0
et_vm   DB 'PM ',       'VM '

iopl_text       DB ' IOPL=',0

WriteEflags     PROC near
    push eax
    push ecx
    push edx
    push esi
;    
    mov eax,dword ptr ds:[ebp].reg_eflags
    mov esi,OFFSET eflags_tab
    mov ecx,18
    
eflags_loop:
    push esi
;    
    mov dl,cs:[esi]
    or dl,dl
    je eflags_next
;
    test al,1
    jz eflags_write_one
;    
    add esi,3

eflags_write_one:
    push ecx
    mov ecx,3
    call ShowCodeSizeString
    pop ecx
    
eflags_next:
    pop esi
;
    shr eax,1
    add esi,6
;
    loop eflags_loop
;
    mov esi,OFFSET iopl_text
    call showCodeAsciiz
;    
    mov ax,word ptr ds:[ebp].reg_eflags
    shr ax,12
    and ax,3
    add al,'0'
    call ShowChar
;
    pop esi
    pop edx
    pop ecx
    pop eax    
    ret
WriteEflags     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCore
;
;           DESCRIPTION:    Write core ID
;
;           PARAMETERS:     DS:EBP      Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

proc_tab    DB 'Core=',0    

WriteCore   PROC near
    mov esi,OFFSET proc_tab
    call ShowCodeAsciiz
;
    mov ax,ds:[ebp].debug_core_id
    call WriteHexWord
;
    mov al,' '
    call ShowChar
    mov al,'('
    call ShowChar
;
    mov ax,ds:[ebp].debug_core_sel
    call WriteHexWord
;
    mov al,')'
    call ShowChar
;    
    mov al,' '
    call ShowChar
    ret
WriteCore   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteThread
;
;           DESCRIPTION:    Write current thread
;
;           PARAMETERS:     DS:EBP      Core regs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NoName DB 'No thread                       ', 0

WriteThread   PROC near
    mov ax,ds:[ebp].reg_tr.d_selector
    or ax,ax
    jz wtNoThread
;    
    mov dx,ds:[ebp].debug_core_sel
    mov ebx,OFFSET cs_curr_thread
    call ReadWord
    jc wtNoThread
;    
    or ax,ax
    jz wtNoThread
;    
    mov dx,ax
    mov ebx,OFFSET thread_name
    mov ecx,32
    call ShowPtrSizeString
    jmp wtDone

wtNoThread:
    mov esi,OFFSET NoName
    call ShowCodeAsciiz

wtDone:
    ret
WriteThread Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteTable
;
;           DESCRIPTION:    Write IDT and GDT
;
;           PARAMETERS:     DS:EBP      Core sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

table_reg_tab:
    DB ' GDT='
    DD OFFSET reg_gdt
    DB ' IDT='
    DD OFFSET reg_idt
    DB 0

WriteTable   PROC near
    mov esi,OFFSET table_reg_tab

table_write_loop:
    mov al,cs:[esi]
    or al,al
    je table_write_end
;
    mov ecx,5
    call ShowCodeSizeString
;
    add esi,5
    mov ebx,cs:[esi]
    mov eax,ds:[ebx+ebp].d_base   
    call WriteHexDword
;    
    mov al,' '
    call ShowChar
;
    mov al,'('
    call ShowChar
;
    mov eax,ds:[ebx+ebp].d_limit
    call WriteHexWord       
;
    mov al,')'
    call ShowChar
;    
    add esi,4
    jmp table_write_loop

table_write_end:
    ret
WriteTable   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteSel
;
;           DESCRIPTION:    
;
;           PARAMETERS:     CS:ESI       Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sel_reg_tr:
    DB ' TR='
    DD OFFSET reg_tr

sel_reg_ldt:
    DB ' DT='
    DD OFFSET reg_ldt

sel_reg_cs:
    DB ' CS='
    DD OFFSET reg_cs

sel_reg_ds:
    DB ' DS='
    DD OFFSET reg_ds

sel_reg_es:    
    DB ' ES='
    DD OFFSET reg_es

sel_reg_fs:    
    DB ' FS='
    DD OFFSET reg_fs

sel_reg_gs:
    DB ' GS='
    DD OFFSET reg_gs

sel_reg_ss:    
    DB ' SS='
    DD OFFSET reg_ss

sel_reg_us:    
    DB ' US='
    DD OFFSET reg_usel

ws_read  DB 'Read', 0
ws_write DB 'Write', 0
ws_16    DB '16-bit ', 0
ws_32    DB '32-bit ', 0
ws_64    DB '64-bit ', 0

WriteSelReg   PROC near
    mov ecx,4
    call ShowCodeSizeString
;
    add esi,4
    mov ebx,cs:[esi]
;    
    mov ax,ds:[ebx+ebp].d_selector
    call WriteHexWord
    mov al,' '
    call ShowChar
;    
    test ds:[ebx+ebp].d_access,ACCESS_VALID
    jz write_sel_done
;
    mov eax,ds:[ebx+ebp].d_base
    call WriteHexDword
;
    mov al,' '
    call ShowChar
    mov al,'('
    call ShowChar
;    
    mov eax,ds:[ebx+ebp].d_limit
    call WriteHexDword
;
    mov al,')'
    call ShowChar    
    mov al,' '
    call ShowChar
;
    cmp ebx,OFFSET reg_ldt
    je write_sel_done
;
    test ds:[ebx+ebp].d_access,ACCESS_64
    jnz write_sel64
;
    test ds:[ebx+ebp].d_access,ACCESS_32
    jnz write_sel32

write_sel16:
    mov esi,OFFSET ws_16
    call ShowCodeAsciiz
    jmp write_sel_access

write_sel32:    
    mov esi,OFFSET ws_32
    call ShowCodeAsciiz
    jmp write_sel_access

write_sel64:
    mov esi,OFFSET ws_64
    call ShowCodeAsciiz

write_sel_access:
    cmp ebx,OFFSET reg_tr
    je write_sel_done
;
    test ds:[ebx+ebp].d_access,ACCESS_WRITE
    jnz write_sel_write
;
    mov esi,OFFSET ws_read
    call ShowCodeAsciiz
    jmp write_sel_done

write_sel_write:    
    mov esi,OFFSET ws_write
    call ShowCodeAsciiz

write_sel_done:
    ret
WriteSelReg   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteDwordRegs
;
;           DESCRIPTION:    Write 32-bit registers
;
;           PARAMETERS:     CS:ESI       Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dword_irq_tab:
    DB ' IRQ='
    DD OFFSET curr_irq
    DW 0

dword_cr_reg_tab:
    DB ' CR0='
    DD OFFSET reg_cr0
    DB ' CR2='
    DD OFFSET reg_cr2
    DB ' CR3='
    DD OFFSET reg_cr3
    DB ' CR4='
    DD OFFSET reg_cr4
    DB 0

dword_dr_reg_tab:
    DB ' DR0='
    DD OFFSET reg_dr0
    DB ' DR1='
    DD OFFSET reg_dr1
    DB ' DR2='
    DD OFFSET reg_dr2
    DB ' DR3='
    DD OFFSET reg_dr3
    DB 0

dword_reg_tab1:
    DB ' EAX='
    DD OFFSET reg_eax
    DB ' EBX='
    DD OFFSET reg_ebx
    DB ' ECX='
    DD OFFSET reg_ecx
    DB ' EDX='
    DD OFFSET reg_edx
    DB 0

dword_reg_tab2:
    DB ' ESI='
    DD OFFSET reg_esi
    DB ' EDI='
    DD OFFSET reg_edi
    DB ' ESP='
    DD OFFSET reg_esp
    DB ' EBP='
    DD OFFSET reg_ebp
    DB 0

dword_reg_tab3:
    DB ' EPC='
    DD OFFSET reg_eip
    DB 0

WriteDwordRegs  PROC near

dword_write_loop:
    mov al,cs:[esi]
    or al,al
    je dword_write_end
;
    mov ecx,5
    call ShowCodeSizeString
    add esi,5
    mov ebx,cs:[esi]
    mov eax,ds:[ebx+ebp]
    call WriteHexDword
    add esi,4
    jmp dword_write_loop

dword_write_end:
    ret
WriteDwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteQwordRegs
;
;           DESCRIPTION:    Write 64-bit register
;
;           PARAMETERS:     CS:ESI       Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

qword_reg_tab1:
    DB ' RAX='
    DD OFFSET reg_eax
    DB ' RBX='
    DD OFFSET reg_ebx
    DB ' RCX='
    DD OFFSET reg_ecx
    DB 0

qword_reg_tab2:
    DB ' RDX='
    DD OFFSET reg_edx
    DB ' RSI='
    DD OFFSET reg_esi
    DB ' RDI='
    DD OFFSET reg_edi
    DB 0

qword_reg_tab3:
    DB '  R8='
    DD OFFSET reg_r8
    DB '  R9='
    DD OFFSET reg_r9
    DB ' R10='
    DD OFFSET reg_r10
    DB 0

qword_reg_tab4:
    DB ' R11='
    DD OFFSET reg_r11
    DB ' R12='
    DD OFFSET reg_r12
    DB ' R13='
    DD OFFSET reg_r13
    DB 0

qword_reg_tab5:
    DB ' R14='
    DD OFFSET reg_r14
    DB ' R15='
    DD OFFSET reg_r15
    DB 0

qword_reg_tab6:
    DB ' RIP='
    DD OFFSET reg_eip
    DB ' RSP='
    DD OFFSET reg_esp
    DB ' RBP='
    DD OFFSET reg_ebp
    DB 0

WriteQwordRegs  PROC near

qword_write_loop:
    mov al,cs:[esi]
    or al,al
    je qword_write_end
;
    mov ecx,5
    call ShowCodeSizeString
    add esi,5
    mov ebx,cs:[esi]
    mov eax,ds:[ebx+ebp]
    mov edx,ds:[ebx+ebp+4]
    call WriteHexQword
    add esi,4
    jmp qword_write_loop

qword_write_end:
    ret
WriteQwordRegs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteFault
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_code_tab:
ke00    DB 'Divide error            '
ke01    DB 'Single step             '
ke02    DB 'NMI                     '
ke03    DB 'Breakpoint              '
ke04    DB 'Overflow                '
ke05    DB 'Array bounds error      '
ke06    DB 'Invalid OP-code         '
ke07    DB '80387 not present       '
ke08    DB 'Double fault            '
ke09    DB '80387 overrun           '
ke0A    DB 'Invalid TSS             '
ke0B    DB 'Segment not present     '
ke0C    DB 'Stack fault             '
ke0D    DB 'Protection fault        '
ke0E    DB 'Page fault              '
ke0F    DB '                        '
ke10    DB '80387 error             '
ke11    DB 'Cannot emulate          '
ke12    DB 'Cannot emulate 80387    '
ke13    DB 'Now in real mode        '
ke14    DB '----------------------- '
ke15    DB 'Illegal int request     '
ke16    DB 'Undefined method        '
ke17    DB 'Invalid handle          '
ke18    DB 'Invalid selector        '
ke19    DB 'NMI                     '
ke1A    DB 'Crash Gate              '

WriteFault    Proc near
    mov al,' '
    call ShowChar
;
    movzx edx,ds:[ebp].fault_vect
    cmp dl,1Ah
    jbe wfDo
;
    mov dl,14h    

wfDo:
    mov ebx,edx
    add ebx,ebx
    add ebx,ebx
    add ebx,ebx
    mov ecx,ebx
    add ecx,ecx
    add ebx,ecx
    mov esi,OFFSET error_code_tab
    add esi,ebx
    mov ecx,24
    call ShowCodeSizeString
    ret
WriteFault    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteDataRow
;
;       DESCRIPTION:    Write a data row
;
;       PARAMETERS:     DS:EBP      Cpu registers
;                       BX:EDX      Address
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDataRow    Proc near
    mov ax,bx
    call WriteHexWord
    mov al,':'
    call ShowChar
    mov eax,edx
    call WriteHexDword
    mov al,' '
    call ShowChar
;    
    push edx
    call GetSelectorBaseSizeType
    mov ebx,edx    
    mov esi,ecx
    pop edx
;
    pushf
    add ebx,edx
    popf
;
    push ebx
    push esi
;    
    mov ecx,16    
    pushf

wrDataLoop:
    popf
    jc wrDataInv
;    
    cmp esi,edx
    jc wrDataInv 
;    
    push edx
;
    xor edi,edi
    call CondReadLinearByte
    jc wrDataUndef
;    
    call WriteHexByte
    jmp wrDataPop

wrDataUndef:
    mov al,'%'
    call ShowChar
    call ShowChar

wrDataPop:
    pop edx
    clc
    jmp wrDataNext

wrDataInv:
    mov al,'!'
    call ShowChar
    call ShowChar
    stc

wrDataNext:
    pushf
    mov al,' '
    call ShowChar
;   
    inc ebx
    inc edx     
    loop wrDataLoop
;
    popf    
    pop esi
    pop ebx
;    
    mov ecx,16    
    pushf

wrCharLoop:
    popf
    jc wrCharInv
;    
    cmp esi,edx
    jc wrCharInv 
;    
    push edx
;
    xor edi,edi
    call CondReadLinearByte
    jc wrCharUndef
;    
    call ShowChar
    jmp wrCharPop

wrCharUndef:
    mov al,'%'
    call ShowChar

wrCharPop:
    pop edx
    clc
    jmp wrCharNext

wrCharInv:
    mov al,'!'
    call ShowChar
    stc

wrCharNext:
    pushf
    inc ebx
    inc edx
    loop wrCharLoop
;
    popf    
    ret
WriteDataRow    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteInstr
;
;       DESCRIPTION:    Write instruction
;
;       PARAMETERS:     DS:EBP      Cpu registers
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteInstr  Proc near
    push es
    push ecx
    push esi
    push edi
;    
    mov ax,mon_data_sel
    mov es,ax
;
    mov ecx,40
    mov edi,OFFSET mon_dis_buf
    call DisAsmCode
;
    mov esi,OFFSET mon_dis_buf
    mov ecx,40

wiLoop:
    lods byte ptr es:[esi]
    call ShowChar
    loop wiLoop
;
    pop edi
    pop esi
    pop ecx
    pop es
    ret
WriteInstr      Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteCpuReg32
;
;       DESCRIPTION:    
;
;       PARAMETERS:     DS:EBP      Cpu registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg32     Proc near
    call WriteCore
    call WriteThread
    call NewLine    
;
    call WriteTable
    mov esi,OFFSET dword_irq_tab
    call WriteDwordRegs
    call NewLine    
;
    mov esi,OFFSET dword_cr_reg_tab
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET dword_dr_reg_tab
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET dword_reg_tab1
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET dword_reg_tab2
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET dword_reg_tab3
    call WriteDwordRegs
    call WriteFault
    call NewLine
;
    mov esi,OFFSET sel_reg_tr
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ldt
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_cs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ds
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_es
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_fs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_gs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ss
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_us
    call WriteSelReg
    call NewLine
;
    call WriteEflags
    call NewLine
;    
    call WriteInstr
    call NewLine
;
    call Delimiter
;
    mov al,ds:[ebp].data_valid
    or al,al
    jz wc32NoPtr
;
    mov ebx,ds:[ebp].data_sel
    mov edx,ds:[ebp].data_offset
    call WriteDataRow
    jmp wc32PtrOk

wc32NoPtr:
    mov ecx,79
    call Blank
    
wc32PtrOk:    
    call NewLine    
;
    mov bx,ds:[ebp].reg_ss.d_selector
    mov edx,ds:[ebp].reg_esp
    call WriteDataRow
    call NewLine    
;    
    mov bx,ds:[ebp].reg_cs.d_selector
    mov edx,ds:[ebp].reg_eip
    call WriteDataRow
    call NewLine    
;    
    mov bx,ds:[ebp].reg_usel.d_selector
    mov edx,ds:[ebp].reg_uoffs
    call WriteDataRow
    call NewLine    
    ret
WriteCpuReg32     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteCpuReg64
;
;       DESCRIPTION:    
;
;       PARAMETERS:     DS:EBP      Cpu registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCpuReg64     Proc near
    call WriteCore
    call WriteThread
    call NewLine    
;
    call WriteTable
    mov esi,OFFSET dword_irq_tab
    call WriteDwordRegs
    call NewLine    
;
    mov esi,OFFSET dword_cr_reg_tab
    call WriteDwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab1
    call WriteQwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab2
    call WriteQwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab3
    call WriteQwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab4
    call WriteQwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab5
    call WriteQwordRegs
    call NewLine
;
    mov esi,OFFSET qword_reg_tab6
    call WriteQwordRegs
    call NewLine
;    
    call WriteFault
    call WriteInstr
    call NewLine
;
    mov esi,OFFSET sel_reg_tr
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ldt
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_cs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ds
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_es
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_fs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_gs
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_ss
    call WriteSelReg
    call NewLine
;
    mov esi,OFFSET sel_reg_us
    call WriteSelReg
    call NewLine
;
    call WriteEflags
    call NewLine
;
    call Delimiter
;    
    mov bx,ds:[ebp].reg_ss
    mov edx,ds:[ebp].reg_esp
    call WriteDataRow
    call NewLine    
;    
    mov bx,ds:[ebp].reg_cs
    mov edx,ds:[ebp].reg_eip
    call WriteDataRow
    call NewLine    
;    
    mov bx,ds:[ebp].reg_usel
    mov edx,ds:[ebp].reg_uoffs
    call WriteDataRow
    call NewLine    
    ret
WriteCpuReg64     Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Read_mem
;
;           DESCRIPTION:    Read memory in process
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           DS:EBP      Cpu
;
;           RETURNS:        NC  AL  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_mem    Proc near
    push ebx
    push ecx
    push edx
    push edi
;
    or dx,dx
    jnz rmProt
;
    mov edx,esi
    jmp rmDo

rmProt:    
    mov bx,dx
    call GetSelectorBaseSizeType
    jc rmDone
;
    cmp ecx,esi 
    jc rmDone
;
    add edx,esi

rmDo:    
    mov ebx,edx
    xor edi,edi
    call CondReadLinearByte    

rmDone:
    pop edi
    pop edx
    pop ecx
    pop ebx
    ret
read_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Write_mem
;
;           DESCRIPTION:    Write memory in process
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           DS:EBP      Cpu
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_mem    Proc near
    push eax
    push ebx
    push ecx
    push edx
    push edi
;
    push ax
    mov bx,dx
    call GetSelectorBaseSizeType
    jc wmPop
;
    cmp ecx,esi 
    jc wmPop
;
    add edx,esi
    mov ebx,edx
    xor edi,edi
    pop ax
    call CondWriteLinearByte    
    jmp wmDone

wmPop:
    pop ax

wmDone:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
write_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateSelector
;
;           DESCRIPTION:    Update selector to descriptor
;
;           PARAMETERS:     DS:EBP      Cpu
;                           ESI         Descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateSelector      Proc near
    mov bx,ds:[ebp+esi].d_selector
;
    call GetSelectorBaseSizeType
    jc usFail
;
    mov ds:[ebp+esi].d_limit,ecx
    mov ds:[ebp+esi].d_base,edx
;
    cmp esi,OFFSET reg_tr
    je usTr
;
    cmp esi,OFFSET reg_ldt
    je usLdt        
;
    mov dx,bx
    and dx,3
;
    test al,10h
    jz usSaveAccess
;    
    mov dx,ACCESS_VALID
    test ah,40h
    jz usSizeOk
;
    or dx,ACCESS_32    

usSizeOk:
    test al,8
    jz usDataSel

usCodeSel:
    test ah,20h
    jz usLongOK
;
    or dx,ACCESS_64

usLongOk:
    test al,2
    jz usSaveAccess
;
    or dx,ACCESS_READ
    jmp usSaveAccess

usDataSel:    
    test al,4
    jz usDataDirOk
;
    or dx,ACCESS_DIR    

usDataDirOk:    
    or dx,ACCESS_READ
    test al,2
    jz usSaveAccess
;
    or dx,ACCESS_WRITE    

usSaveAccess:
    mov ds:[ebp+esi].d_access,dx
    jmp usDone

usTr:
    and al,1Fh
    cmp al,1
    je usTrSave16
;
    cmp al,3
    je usTrSave16
;        
    cmp al,9
    je usTrSave32
;
    cmp al,0Bh
    jne usFail

usTrSave32:
    mov dx,ACCESS_VALID OR ACCESS_32
    jmp usSaveAccess

usTrSave16:    
    mov dx,ACCESS_VALID
    jmp usSaveAccess

usLdt:
    and al,1Fh
    cmp al,2
    jne usFail
;
    mov dx,ACCESS_VALID
    jmp usSaveAccess

usFail:
    mov ds:[ebp+esi].d_limit,0
    mov ds:[ebp+esi].d_base,0
    mov ds:[ebp+esi].d_access,0

usDone:        
    ret
UpdateSelector      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupDescriptors
;
;           DESCRIPTION:    Setup selector descriptors
;
;           PARAMETERS:     DS:EBP      Cpu
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
SetupDescriptors Proc near
    pushad
;    
    mov ds:[ebp].cpu_read_mem,OFFSET read_mem
    mov ds:[ebp].cpu_write_mem,OFFSET write_mem
;    
    mov esi,OFFSET reg_ldt
    call UpdateSelector
;    
    mov esi,OFFSET reg_tr
    call UpdateSelector
;
    mov esi,OFFSET reg_es
    call UpdateSelector
;
    mov esi,OFFSET reg_cs
    call UpdateSelector
     
    mov esi,OFFSET reg_ss
    call UpdateSelector
;
    mov esi,OFFSET reg_ds
    call UpdateSelector
;
    mov esi,OFFSET reg_fs
    call UpdateSelector
;
    mov esi,OFFSET reg_gs
    call UpdateSelector
;
    mov ds:[ebp].reg_usel.d_selector,20h
    mov esi,OFFSET reg_usel
    call UpdateSelector
;
    popad    
    ret
SetupDescriptors        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteCpuReg
;
;       DESCRIPTION:    Write CPU registers
;
;       PARAMETERS:     DS:EBP          Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


WriteCpuReg     Proc near
    push ds
    pushad
;    
    push ds
    mov ax,mon_system_data_sel
    mov ds,ax
    mov ds:efi_text_row,0
    mov ds:efi_text_col,0
    pop ds
;    
    test ds:[ebp].debug_flags,DEBUG_FLAG_DESCR
    jnz wcSelOk
;    
    call SetupDescriptors
    or ds:[ebp].debug_flags,DEBUG_FLAG_DESCR

wcSelOk:
    test ds:[ebp].reg_cs.d_access,ACCESS_64
    jnz wc64

wc32:
    call WriteCpuReg32
    jmp wcDone

wc64:
    call WriteCpuReg64

wcDone:
    popad
    pop ds
    ret            
WriteCpuReg Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           error_sw
;
;           DESCRIPTION:    Error sw
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

go_sw:
pace_sw:
reg_sw:

error_sw Proc near
    ret
error_sw Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           trace_sw
;
;           DESCRIPTION:    Trace sw
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trace_sw  Proc near
    call Emulate
    ret
trace_sw  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ignore
;
;           DESCRIPTION:    Ignore
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ignore  Proc near
    ret
ignore  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_reg_byte
;
;           DESCRIPTION:    Perform inc on byte in core reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;                           EBX     Table entry
;                           CX      Digit #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_reg_byte    Proc near
    mov ax,cs:[ebx].exec_size
    sub ax,cx
    dec ax
    mov cl,al
    shl cl,2
    mov edx,0Fh
    shl edx,cl
;    
    mov eax,ds:[ebp+esi]
    and eax,edx
    shr eax,cl
    inc al
    and al,0Fh
    shl eax,cl
    not edx
    and edx,ds:[ebp+esi]
    or eax,edx
    mov ds:[ebp+esi],eax
    ret
inc_reg_byte  Endp

inc_sreg_byte  Proc near
    push esi
    add esi,d_selector
    call inc_reg_byte
    pop esi
;
    call UpdateSelector
    ret
inc_sreg_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_reg_byte
;
;           DESCRIPTION:    Perform dec on byte in core reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;                           EBX     Table entry
;                           CX      Digit #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_reg_byte    Proc near
    mov ax,cs:[ebx].exec_size
    sub ax,cx
    dec ax
    mov cl,al
    shl cl,2
    mov edx,0Fh
    shl edx,cl
;    
    mov eax,ds:[ebp+esi]
    and eax,edx
    shr eax,cl
    dec al
    and al,0Fh
    shl eax,cl
    not edx
    and edx,ds:[ebp+esi]
    or eax,edx
    mov ds:[ebp+esi],eax
    ret
dec_reg_byte  Endp

dec_sreg_byte  Proc near
    push esi
    add esi,d_selector
    call dec_reg_byte
    pop esi
;
    call UpdateSelector
    ret
dec_sreg_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_reg4
;
;           DESCRIPTION:    Perform dword inc on core reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_reg4    Proc near
    inc dword ptr ds:[ebp+esi]
    ret
inc_reg4  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_reg4
;
;           DESCRIPTION:    Perform dword dec on core reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_reg4    Proc near
    dec dword ptr ds:[ebp+esi]
    ret
dec_reg4  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_reg8
;
;           DESCRIPTION:    Perform qword inc on core reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_reg8    Proc near
    add dword ptr ds:[ebp+esi],1
    adc dword ptr ds:[ebp+esi+4],0
    ret
inc_reg8  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_reg8
;
;           DESCRIPTION:    Perform qword dec on core reg
;
;           PARAMETERS:     DS:EBP  Core registers
;                           ESI     Register offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_reg8    Proc near
    sub dword ptr ds:[ebp+esi],1
    sbb dword ptr ds:[ebp+esi+4],0
    ret
dec_reg8  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_reg_byte
;
;           DESCRIPTION:    Perform set on core reg
;
;           PARAMETERS:     DS:EBP  Core regs
;                           ESI     Register offset
;                           EBX     Table entry
;                           AL      Value to set
;                           CX      Digit number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_reg_byte    Proc near
    mov dx,cs:[ebx].exec_size
    sub dx,cx
    dec dx
    mov cl,dl
    shl cl,2
    mov edx,0Fh
    shl edx,cl
    not edx
    and edx,ds:[ebp+esi]
    movzx eax,al
    shl eax,cl
    or eax,edx
    mov ds:[ebp+esi],eax
;
    push ds
    mov ax,mon_data_sel
    mov ds,ax
    inc ds:mon_curr_col
    pop ds
    ret
set_reg_byte  Endp

set_sreg_byte  Proc near
    push esi
    add esi,d_selector
    call set_reg_byte
    pop esi
;
    call UpdateSelector
    ret
set_sreg_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Func32
;
;           DESCRIPTION:    Function on 32-bit regs
;
;           PARAMETERS:     DS:EBP              Registers
;                           EDI                 Function ptr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
exec_table32:
meax32  exec_s <4,  1,  3, OFFSET reg_eax,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
deax32  exec_s <4,  5,  8, OFFSET reg_eax,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mebx32  exec_s <4,  14, 3, OFFSET reg_ebx,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
debx32  exec_s <4,  18, 8, OFFSET reg_ebx,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mecx32  exec_s <4,  27, 3, OFFSET reg_ecx,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
decx32  exec_s <4,  31, 8, OFFSET reg_ecx,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
medx32  exec_s <4,  40, 3, OFFSET reg_edx,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
dedx32  exec_s <4,  44, 8, OFFSET reg_edx,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mesi32  exec_s <5,  1,  3, OFFSET reg_esi,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
desi32  exec_s <5,  5,  8, OFFSET reg_esi,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
medi32  exec_s <5,  14, 3, OFFSET reg_edi,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
dedi32  exec_s <5,  18, 8, OFFSET reg_edi,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mesp32  exec_s <5,  27, 3, OFFSET reg_esp,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
desp32  exec_s <5,  31, 8, OFFSET reg_esp,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
mebp32  exec_s <5,  40, 3, OFFSET reg_ebp,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
debp32  exec_s <5,  44, 8, OFFSET reg_ebp,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
meip32  exec_s <6,  1,  3, OFFSET reg_eip,      OFFSET inc_reg4,       OFFSET dec_reg4,        OFFSET ignore>
deip32  exec_s <6,  5,  8, OFFSET reg_eip,      OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dtr32   exec_s <7,  4,  4, OFFSET reg_tr,       OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
dldt32  exec_s <8,  4,  4, OFFSET reg_ldt,      OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
dcs32   exec_s <9,  4,  4, OFFSET reg_cs,       OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
dds32   exec_s <10, 4,  4, OFFSET reg_ds,       OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
des32   exec_s <11, 4,  4, OFFSET reg_es,       OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
dfs32   exec_s <12, 4,  4, OFFSET reg_fs,       OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
dgs32   exec_s <13, 4,  4, OFFSET reg_gs,       OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
dss32   exec_s <14, 4,  4, OFFSET reg_ss,       OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
dus32   exec_s <15, 4,  4, OFFSET reg_usel,     OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
duss32  exec_s <22, 0,  4, OFFSET reg_usel,     OFFSET inc_sreg_byte,  OFFSET dec_sreg_byte,   OFFSET set_sreg_byte>
duso32  exec_s <22, 5,  8, OFFSET reg_uoffs,    OFFSET inc_reg_byte,   OFFSET dec_reg_byte,    OFFSET set_reg_byte>
dend32 DW     0FFFFh, 0FFFFh

Func32  PROC near
    push es
    mov bx,mon_data_sel
    mov es,bx
    mov ebx,OFFSET exec_table32

f32Loop:
    mov cx,cs:[ebx].exec_row
    cmp cx,0FFFFh
    je f32Done
;    
    cmp cx,es:mon_curr_row
    jne f32Next
;
    mov cx,es:mon_curr_col
    sub cx,cs:[ebx].exec_col
    jc f32Next
;    
    cmp cx,cs:[ebx].exec_size
    jnc f32Next
;    
    mov esi,cs:[ebx].exec_reg
    call dword ptr cs:[ebx+edi]
    jmp f32Done
    
f32Next:
    add ebx,SIZE exec_s
    jmp f32Loop
    
f32Done:
    pop es
    ret
Func32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_sw32
;
;           DESCRIPTION:    32-bit inc
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_sw32  PROC near
    pushad
    mov edi,exec_inc_proc
    call Func32
    popad
    ret
inc_sw32  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_sw32
;
;           DESCRIPTION:    32-bit dec
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_sw32  PROC near
    pushad
    mov edi,exec_dec_proc
    call Func32
    popad
    ret
dec_sw32  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_base_sw32
;
;           DESCRIPTION:    32-bit set
;
;           PARAMETERS:     DS:EBP              Registers
;                           CH                  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_base_sw32   Proc near
    pushad
    mov edi,exec_set_proc
    call Func32
    popad
    ret
set_base_sw32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Func64
;
;           DESCRIPTION:    Function on 64-bit regs
;
;           PARAMETERS:     DS:EBP              Registers
;                           EDI                 Function ptr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
exec_table64:
dtr64   exec_s <10,  4,  4, OFFSET reg_tr,       OFFSET inc_sreg_byte,   OFFSET dec_sreg_byte,    OFFSET set_sreg_byte>
dldt64  exec_s <11,  4,  4, OFFSET reg_ldt,      OFFSET inc_sreg_byte,   OFFSET dec_sreg_byte,    OFFSET set_sreg_byte>
dcs64   exec_s <12,  4,  4, OFFSET reg_cs,       OFFSET inc_sreg_byte,   OFFSET dec_sreg_byte,    OFFSET set_sreg_byte>
dds64   exec_s <13, 4,  4,  OFFSET reg_ds,       OFFSET inc_sreg_byte,   OFFSET dec_sreg_byte,    OFFSET set_sreg_byte>
des64   exec_s <14, 4,  4,  OFFSET reg_es,       OFFSET inc_sreg_byte,   OFFSET dec_sreg_byte,    OFFSET set_sreg_byte>
dfs64   exec_s <15, 4,  4,  OFFSET reg_fs,       OFFSET inc_sreg_byte,   OFFSET dec_sreg_byte,    OFFSET set_sreg_byte>
dgs64   exec_s <16, 4,  4,  OFFSET reg_gs,       OFFSET inc_sreg_byte,   OFFSET dec_sreg_byte,    OFFSET set_sreg_byte>
dss64   exec_s <17, 4,  4,  OFFSET reg_ss,       OFFSET inc_sreg_byte,   OFFSET dec_sreg_byte,    OFFSET set_sreg_byte>
dus64   exec_s <18, 4,  4,  OFFSET reg_usel,     OFFSET inc_sreg_byte,   OFFSET dec_sreg_byte,    OFFSET set_sreg_byte>
duss64  exec_s <24, 0,  4,  OFFSET reg_usel,     OFFSET inc_sreg_byte,   OFFSET dec_sreg_byte,    OFFSET set_sreg_byte>
duso64  exec_s <24, 5,  8,  OFFSET reg_uoffs,    OFFSET inc_sreg_byte,   OFFSET dec_sreg_byte,    OFFSET set_sreg_byte>
dend64 DW     0FFFFh, 0FFFFh

Func64  PROC near
    push es
    mov bx,mon_data_sel
    mov es,bx
    mov ebx,OFFSET exec_table64

f64Loop:
    mov cx,cs:[ebx].exec_row
    cmp cx,0FFFFh
    je f64Done
;    
    cmp cx,es:mon_curr_row
    jne f64Next
;
    mov cx,es:mon_curr_col
    sub cx,cs:[ebx].exec_col
    jc f64Next
;    
    cmp cx,cs:[ebx].exec_size
    jnc f64Next
;    
    mov esi,cs:[ebx].exec_reg
    call dword ptr cs:[ebx+edi]
    jmp f64Done
    
f64Next:
    add ebx,SIZE exec_s
    jmp f64Loop
    
f64Done:
    pop es
    ret
Func64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_sw64
;
;           DESCRIPTION:    64-bit inc
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_sw64  PROC near
    pushad
    mov edi,exec_inc_proc
    call Func64
    popad
    ret
inc_sw64  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_sw64
;
;           DESCRIPTION:    64-bit dec
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_sw64  PROC near
    pushad
    mov edi,exec_dec_proc
    call Func64
    popad
    ret
dec_sw64  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_base_sw64
;
;           DESCRIPTION:    64-bit set
;
;           PARAMETERS:     DS:EBP              Registers
;                           CH                  Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_base_sw64   Proc near
    pushad
    mov edi,exec_set_proc
    call Func64
    popad
    ret
set_base_sw64   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setx_sw
;
;           DESCRIPTION:    Set x switch
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_sw:
    test ds:[ebp].reg_efer,EFER_LME
    jnz inc_sw64
    jmp inc_sw32

dec_sw:
    test ds:[ebp].reg_efer,EFER_LME
    jnz dec_sw64
    jmp dec_sw32

set0_sw:
    mov al,0
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

set1_sw:
    mov al,1
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

set2_sw:
    mov al,2
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

set3_sw:
    mov al,3
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

set4_sw:
    mov al,4
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

set5_sw:
    mov al,5
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

set6_sw:
    mov al,6
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

set7_sw:
    mov al,7
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

set8_sw:
    mov al,8
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

set9_sw:
    mov al,9
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

setA_sw:
    mov al,0Ah
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

setB_sw:
    mov al,0Bh
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

setC_sw:
    mov al,0Ch
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

setD_sw:
    mov al,0Dh
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

setE_sw:
    mov al,0Eh
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

setF_sw:
    mov al,0Fh
    test ds:[ebp].reg_efer,EFER_LME
    jnz set_base_sw64
    jmp set_base_sw32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           next_sw
;
;           DESCRIPTION:    Show next core
;
;           PARAMETERS:     DS:EBP              Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_sw Proc near
    push ds
    push bx
;    
    mov bx,mon_data_sel
    mov ds,bx
    
next_core:
    mov bx,ds:mon_curr_core
    inc bx
    cmp bx,ds:mon_core_count
    jb next_core_show
;
    xor bx,bx

next_core_show:
    mov ds:mon_curr_core,bx
;
    movzx ebx,bx
    shl ebx,3
    add ebx,OFFSET mon_core_regs
    mov ebp,ds:[ebx].mc_mon_linear
;
    pop bx
    pop ds
    ret
next_sw Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoFunc
;
;           DESCRIPTION:    Do function
;
;           PARAMETERS:     AL          Key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
virt_sw_func_tab:
vs_00   DD OFFSET error_sw
vs_01   DD OFFSET error_sw
vs_02   DD OFFSET error_sw
vs_03   DD OFFSET error_sw
vs_04   DD OFFSET error_sw
vs_05   DD OFFSET error_sw
vs_06   DD OFFSET error_sw
vs_07   DD OFFSET error_sw
vs_08   DD OFFSET error_sw
vs_09   DD OFFSET error_sw
vs_0A   DD OFFSET error_sw
vs_0B   DD OFFSET error_sw
vs_0C   DD OFFSET error_sw
vs_0D   DD OFFSET error_sw
vs_0E   DD OFFSET error_sw
vs_0F   DD OFFSET error_sw
vs_10   DD OFFSET error_sw
vs_11   DD OFFSET error_sw
vs_12   DD OFFSET error_sw
vs_13   DD OFFSET error_sw
vs_14   DD OFFSET error_sw
vs_15   DD OFFSET error_sw
vs_16   DD OFFSET error_sw
vs_17   DD OFFSET error_sw
vs_18   DD OFFSET error_sw
vs_19   DD OFFSET error_sw
vs_1A   DD OFFSET error_sw
vs_1B   DD OFFSET error_sw
vs_1C   DD OFFSET error_sw
vs_1D   DD OFFSET error_sw
vs_1E   DD OFFSET error_sw
vs_1F   DD OFFSET error_sw
vs_20   DD OFFSET error_sw
vs_21   DD OFFSET error_sw
vs_22   DD OFFSET error_sw
vs_23   DD OFFSET error_sw
vs_24   DD OFFSET error_sw
vs_25   DD OFFSET error_sw
vs_26   DD OFFSET error_sw
vs_27   DD OFFSET error_sw
vs_28   DD OFFSET error_sw
vs_29   DD OFFSET error_sw
vs_2A   DD OFFSET error_sw
vs_2B   DD OFFSET inc_sw
vs_2C   DD OFFSET error_sw
vs_2D   DD OFFSET dec_sw
vs_2E   DD OFFSET error_sw
vs_2F   DD OFFSET error_sw
vs_30   DD OFFSET set0_sw
vs_31   DD OFFSET set1_sw
vs_32   DD OFFSET set2_sw
vs_33   DD OFFSET set3_sw
vs_34   DD OFFSET set4_sw
vs_35   DD OFFSET set5_sw
vs_36   DD OFFSET set6_sw
vs_37   DD OFFSET set7_sw
vs_38   DD OFFSET set8_sw
vs_39   DD OFFSET set9_sw
vs_3A   DD OFFSET error_sw
vs_3B   DD OFFSET error_sw
vs_3C   DD OFFSET error_sw
vs_3D   DD OFFSET error_sw
vs_3E   DD OFFSET error_sw
vs_3F   DD OFFSET error_sw
vs_40   DD OFFSET error_sw
vs_41   DD OFFSET setA_sw
vs_42   DD OFFSET setB_sw
vs_43   DD OFFSET setC_sw
vs_44   DD OFFSET setD_sw
vs_45   DD OFFSET setE_sw
vs_46   DD OFFSET setF_sw
vs_47   DD OFFSET go_sw
vs_48   DD OFFSET error_sw
vs_49   DD OFFSET error_sw
vs_4A   DD OFFSET error_sw
vs_4B   DD OFFSET error_sw
vs_4C   DD OFFSET error_sw
vs_4D   DD OFFSET error_sw
vs_4E   DD OFFSET next_sw
vs_4F   DD OFFSET error_sw
vs_50   DD OFFSET pace_sw
vs_51   DD OFFSET error_sw
vs_52   DD OFFSET reg_sw
vs_53   DD OFFSET error_sw
vs_54   DD OFFSET trace_sw
vs_55   DD OFFSET error_sw
vs_56   DD OFFSET error_sw
vs_57   DD OFFSET error_sw
vs_58   DD OFFSET error_sw
vs_59   DD OFFSET error_sw
vs_5A   DD OFFSET error_sw
vs_5B   DD OFFSET error_sw
vs_5C   DD OFFSET error_sw
vs_5D   DD OFFSET error_sw
vs_5E   DD OFFSET error_sw
vs_5F   DD OFFSET error_sw
vs_60   DD OFFSET error_sw
vs_61   DD OFFSET setA_sw
vs_62   DD OFFSET setB_sw
vs_63   DD OFFSET setC_sw
vs_64   DD OFFSET setD_sw
vs_65   DD OFFSET setE_sw
vs_66   DD OFFSET setF_sw
vs_67   DD OFFSET go_sw
vs_68   DD OFFSET error_sw
vs_69   DD OFFSET error_sw
vs_6A   DD OFFSET error_sw
vs_6B   DD OFFSET inc_sw
vs_6C   DD OFFSET error_sw
vs_6D   DD OFFSET dec_sw
vs_6E   DD OFFSET next_sw
vs_6F   DD OFFSET error_sw
vs_70   DD OFFSET pace_sw
vs_71   DD OFFSET error_sw
vs_72   DD OFFSET reg_sw
vs_73   DD OFFSET error_sw
vs_74   DD OFFSET trace_sw
vs_75   DD OFFSET error_sw
vs_76   DD OFFSET error_sw
vs_77   DD OFFSET error_sw
vs_78   DD OFFSET error_sw
vs_79   DD OFFSET error_sw
vs_7A   DD OFFSET error_sw
vs_7B   DD OFFSET error_sw
vs_7C   DD OFFSET error_sw
vs_7D   DD OFFSET error_sw
vs_7E   DD OFFSET error_sw
vs_7F   DD OFFSET error_sw
vs_80   DD OFFSET error_sw
vs_81   DD OFFSET error_sw
vs_82   DD OFFSET error_sw
vs_83   DD OFFSET error_sw
vs_84   DD OFFSET error_sw
vs_85   DD OFFSET error_sw
vs_86   DD OFFSET error_sw
vs_87   DD OFFSET error_sw
vs_88   DD OFFSET error_sw
vs_89   DD OFFSET error_sw
vs_8A   DD OFFSET error_sw
vs_8B   DD OFFSET error_sw
vs_8C   DD OFFSET error_sw
vs_8D   DD OFFSET error_sw
vs_8E   DD OFFSET error_sw
vs_8F   DD OFFSET error_sw
vs_90   DD OFFSET error_sw
vs_91   DD OFFSET error_sw
vs_92   DD OFFSET error_sw
vs_93   DD OFFSET error_sw
vs_94   DD OFFSET error_sw
vs_95   DD OFFSET error_sw
vs_96   DD OFFSET error_sw
vs_97   DD OFFSET error_sw
vs_98   DD OFFSET error_sw
vs_99   DD OFFSET error_sw
vs_9A   DD OFFSET error_sw
vs_9B   DD OFFSET error_sw
vs_9C   DD OFFSET error_sw
vs_9D   DD OFFSET error_sw
vs_9E   DD OFFSET error_sw
vs_9F   DD OFFSET error_sw
vs_A0   DD OFFSET error_sw
vs_A1   DD OFFSET error_sw
vs_A2   DD OFFSET error_sw
vs_A3   DD OFFSET error_sw
vs_A4   DD OFFSET error_sw
vs_A5   DD OFFSET error_sw
vs_A6   DD OFFSET error_sw
vs_A7   DD OFFSET error_sw
vs_A8   DD OFFSET error_sw
vs_A9   DD OFFSET error_sw
vs_AA   DD OFFSET error_sw
vs_AB   DD OFFSET error_sw
vs_AC   DD OFFSET error_sw
vs_AD   DD OFFSET error_sw
vs_AE   DD OFFSET error_sw
vs_AF   DD OFFSET error_sw
vs_B0   DD OFFSET error_sw
vs_B1   DD OFFSET error_sw
vs_B2   DD OFFSET error_sw
vs_B3   DD OFFSET error_sw
vs_B4   DD OFFSET error_sw
vs_B5   DD OFFSET error_sw
vs_B6   DD OFFSET error_sw
vs_B7   DD OFFSET error_sw
vs_B8   DD OFFSET error_sw
vs_B9   DD OFFSET error_sw
vs_BA   DD OFFSET error_sw
vs_BB   DD OFFSET error_sw
vs_BC   DD OFFSET error_sw
vs_BD   DD OFFSET error_sw
vs_BE   DD OFFSET error_sw
vs_BF   DD OFFSET error_sw
vs_C0   DD OFFSET error_sw
vs_C1   DD OFFSET error_sw
vs_C2   DD OFFSET error_sw
vs_C3   DD OFFSET error_sw
vs_C4   DD OFFSET error_sw
vs_C5   DD OFFSET error_sw
vs_C6   DD OFFSET error_sw
vs_C7   DD OFFSET error_sw
vs_C8   DD OFFSET error_sw
vs_C9   DD OFFSET error_sw
vs_CA   DD OFFSET error_sw
vs_CB   DD OFFSET error_sw
vs_CC   DD OFFSET error_sw
vs_CD   DD OFFSET error_sw
vs_CE   DD OFFSET error_sw
vs_CF   DD OFFSET error_sw
vs_D0   DD OFFSET error_sw
vs_D1   DD OFFSET error_sw
vs_D2   DD OFFSET error_sw
vs_D3   DD OFFSET error_sw
vs_D4   DD OFFSET error_sw
vs_D5   DD OFFSET error_sw
vs_D6   DD OFFSET error_sw
vs_D7   DD OFFSET error_sw
vs_D8   DD OFFSET error_sw
vs_D9   DD OFFSET error_sw
vs_DA   DD OFFSET error_sw
vs_DB   DD OFFSET error_sw
vs_DC   DD OFFSET error_sw
vs_DD   DD OFFSET error_sw
vs_DE   DD OFFSET error_sw
vs_DF   DD OFFSET error_sw
vs_E0   DD OFFSET error_sw
vs_E1   DD OFFSET error_sw
vs_E2   DD OFFSET error_sw
vs_E3   DD OFFSET error_sw
vs_E4   DD OFFSET error_sw
vs_E5   DD OFFSET error_sw
vs_E6   DD OFFSET error_sw
vs_E7   DD OFFSET error_sw
vs_E8   DD OFFSET error_sw
vs_E9   DD OFFSET error_sw
vs_EA   DD OFFSET error_sw
vs_EB   DD OFFSET error_sw
vs_EC   DD OFFSET error_sw
vs_ED   DD OFFSET error_sw
vs_EE   DD OFFSET error_sw
vs_EF   DD OFFSET error_sw
vs_F0   DD OFFSET error_sw
vs_F1   DD OFFSET error_sw
vs_F2   DD OFFSET error_sw
vs_F3   DD OFFSET error_sw
vs_F4   DD OFFSET error_sw
vs_F5   DD OFFSET error_sw
vs_F6   DD OFFSET error_sw
vs_F7   DD OFFSET error_sw
vs_F8   DD OFFSET error_sw
vs_F9   DD OFFSET error_sw
vs_FA   DD OFFSET error_sw
vs_FB   DD OFFSET error_sw
vs_FC   DD OFFSET error_sw
vs_FD   DD OFFSET error_sw
vs_FE   DD OFFSET error_sw
vs_FF   DD OFFSET error_sw

DoFunc   PROC near
    push ds
    pushad
;    
    mov bx,mon_data_sel
    mov ds,bx  
    movzx ebx,ds:mon_curr_core
    shl ebx,3
    add ebx,OFFSET mon_core_regs
    mov ebp,ds:[ebx].mc_mon_linear
    mov bx,mon_flat_sel
    mov ds,bx
;
    movzx ebx,al
    shl ebx,2
    call dword ptr cs:[ebx].virt_sw_func_tab
;
    call HideMarker
    call WriteCpuReg
    call ShowMarker

debug_end:
    popad
    pop ds
    ret
DoFunc   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyUsb
;
;           DESCRIPTION:    Notify USB device
;
;           PARAMETERS:     ECX		PCI address
;                           AL          Interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyUsb	Proc near
    cmp al,10h
    je nuOhci
;
    cmp al,20h
    je nuEhci
;
    cmp al,30h
    je nuXhci
;
    jmp nuDone

nuOhci:
    call AddOhci
    jmp nuDone

nuEhci:
    call AddEhci
    jmp nuDone

nuXhci:
    call AddXhci
    jmp nuDone

nuDone:
    ret
NotifyUsb	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EnumPci
;
;           DESCRIPTION:    Enumerate PCI devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnumPci    Proc near
    mov ecx,80000000h

epLoop:
    mov eax,ecx
    mov dx,0CF8h
    and al,0FCh
    out dx,eax
    mov dx,0CFCh
    in eax,dx
;       
    or eax,eax
    jz epNext
;   
    cmp eax,-1
    je epNext
;   
    mov eax,ecx
    mov dx,0CF8h
    mov al,8
    out dx,eax
    mov dx,0CFCh
    in eax,dx
    mov edx,eax
    shr edx,16
    cmp dx,0C03h
    jne epNext
;
    shr eax,8
    call NotifyUsb

epNext:
    add ecx,100h
    cmp ecx,81000000h
    jne epLoop  
;
    ret
EnumPci    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckUsbDev
;
;           DESCRIPTION:    Check USB device for keyboard
;
;           PARAMETERS:     ES:EDI        Descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CheckUsbDev

CheckUsbDev    Proc near
    push eax
;
    movzx eax,es:[edi].udd_len
    cmp eax,SIZE usb_device_descr
    jb cudDone
;
    mov al,es:[edi].udd_class
    or al,al
    clc
    jz cudDone
;
    cmp al,3
    stc
    jnz cudDone
;
    mov al,es:[edi].udd_sub_class
    cmp al,1
    stc
    jnz cudDone
;
    mov al,es:[edi].udd_proto
    cmp al,1
    stc
    jnz cudDone
;
    clc

cudDone:
    pop eax
    ret
CheckUsbDev    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckUsbConfig
;
;           DESCRIPTION:    Check USB config for keyboard
;
;           PARAMETERS:     ES:EDI        Descriptor
;
;           RETURNS:        AL            Config ID
;                           ES:EDI        Interface descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CheckUsbConfig

CheckUsbConfig    Proc near
    push ecx
    push edx
    push esi
;
    mov si,es:[edi].ucd_size
    mov dl,es:[edi].ucd_config_id
    movzx ecx,es:[edi].ucd_len
    add edi,ecx
    sub si,cx
    jbe cucFail

cucCheckLoop:
    mov cl,es:[edi].ucd_type
    cmp cl,4
    jne cucCheckNext
;    
    mov cl,es:[edi].uid_class
    cmp cl,3
    jne cucCheckNext
;
    mov cl,es:[edi].uid_sub_class
    cmp cl,1
    jne cucCheckNext
;
    mov cl,es:[edi].uid_proto
    cmp cl,1
    jne cucCheckNext
;
    mov al,dl
    clc
    jmp cucDone

cucCheckNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz cucFail
;    
    add edi,ecx
    sub si,cx
    ja cucCheckLoop

cucFail:
    stc

cucDone:
    pop esi
    pop edx
    pop ecx
    ret
CheckUsbConfig    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetUsbEp
;
;           DESCRIPTION:    Get USB endpoint for keyboard
;
;           PARAMETERS:     ES:EDI        Interface descriptor
;
;           RETURNS:        ES:EDI        Endpoint descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetUsbEp

GetUsbEp    Proc near
    push ecx
    push edx
    push esi

    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz gueFail
;    
    add edi,ecx
    sub si,cx
    jbe gueFail

gueLoop:
    mov cl,es:[edi].ucd_type
    cmp cl,5
    jne gueNext
;    
    mov cl,es:[edi].ued_attrib
    and cl,3
    cmp cl,3
    jne gueNext
;
    clc
    jmp gueDone

gueNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz gueFail
;    
    add edi,ecx
    sub si,cx
    ja gueLoop

gueFail:
    stc

gueDone:
    pop esi
    pop edx
    pop ecx
    ret
GetUsbEp    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleKey
;
;           DESCRIPTION:    Handle key
;
;           PARAMETERS:     AX		Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleKey    Proc near
    test ah,80h
    jnz hkDone
;    
    cmp al,25h
    je hkLeftArrow
;
    cmp al,27h
    je hkRightArrow
;        
    cmp al,26h
    je hkUpArrow
;
    cmp al,28h
    je hkDownArrow
;
    call DoFunc
    jmp hkDone

hkUpArrow:
    mov dx,ds:mon_curr_row
    or dx,dx
    jz hkDone
;    
    call HideMarker
    dec ds:mon_curr_row
    call ShowMarker
    jmp hkDone

hkDownArrow:
    mov dx,ds:mon_curr_row
    cmp dx,24
    je hkDone
;
    call HideMarker
    inc ds:mon_curr_row
    call ShowMarker
    jmp hkDone

hkLeftArrow:
    mov dx,ds:mon_curr_col
    or dx,dx
    jz hkDone
;
    call HideMarker
    dec ds:mon_curr_col
    call ShowMarker
    jmp hkDone

hkRightArrow:
    mov dx,ds:mon_curr_col
    cmp dx,79
    je hkDone
;
    call HideMarker
    inc ds:mon_curr_col
    call ShowMarker

hkDone:
    ret
HandleKey	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PollKey
;
;           DESCRIPTION:    Poll keyboard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PollKey

PollKey	Proc near
    push ds
    push es
    pushad
;
    mov ax,mon_data_sel
    mov ds,ax
;
    call GetCrashKey
    jc pkDone
;
    call HandleKey

pkDone:
    popad
    pop es
    pop ds
    ret
PollKey	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           handle_monitor
;
;           DESCRIPTION:    Handle monitor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_monitor:
    call WriteCpuReg
    call InitCrashKeyboard
;
    call InitEhci
    call InitOhci
    call InitXhci
    call EnumPci
;
    mov bx,ds:[ebp].debug_core_id
;
    mov ax,mon_data_sel
    mov ds,ax
    mov ds:int_count,0
;
    mov ds:mon_curr_row,0
    mov ds:mon_curr_col,0
    mov ds:mon_curr_core,bx
;
    call ShowMarker

handle_loop:
    call CheckEhci
    call CheckOhci
    call CheckXhci
    jmp handle_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateDataSel32
;
;           DESCRIPTION:    Create 32-bit data selector
;
;           PARAMETERS:     BX              Descriptor
;                           EDX             Gdt linear
;                           ESI             Base
;                           ECX             Limit
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateDataSel32

CreateDataSel32       PROC near
    push ds
    push ax
    push ebx
    push ecx
;
    mov ax,flat_sel
    mov ds,ax
;        
    movzx ebx,bx
    add ebx,edx
    dec ecx
    cmp ecx,100000h
    jae cdsBig
;
    mov [ebx],cx
    mov [ebx+2],esi
    mov al,92h
    xchg al,[ebx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [ebx+6],cx
    jmp cdsDone

cdsBig:
    shr ecx,12
    mov [ebx],cx
    mov [ebx+2],esi
    mov al,92h
    xchg al,[ebx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [ebx+6],cx

cdsDone:
    pop ecx
    pop ebx
    pop ax
    pop ds
    ret
CreateDataSel32       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCodeSel32
;
;           DESCRIPTION:    Create 32-bit code selector
;
;           PARAMETERS:     BX              Descriptor
;                           EDX             Gdt linear
;                           ESI             Base
;                           ECX             Limit
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateCodeSel32       PROC near
    push ds
    push ax
    push ebx
    push ecx
;
    mov ax,flat_sel
    mov ds,ax
;        
    movzx ebx,bx
    add ebx,edx
    dec ecx
    cmp ecx,100000h
    jae ccsBig
;
    mov [ebx],cx
    mov [ebx+2],esi
    mov al,9Ah
    xchg al,[ebx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [ebx+6],cx
    jmp ccsDone

ccsBig:
    shr ecx,12
    mov [ebx],cx
    mov [ebx+2],esi
    mov al,9Ah
    xchg al,[ebx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [ebx+6],cx

ccsDone:
    pop ecx
    pop ebx
    pop ax
    pop ds
    ret
CreateCodeSel32       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          InitMonitorGdt
;
;           DESCRIPTION:   Init monitor GDT
;
;           PARAMETERS:    EDX          GDT base
;                          ECX          Code size
;                          ESI          Code base
;                          EDI          Mapping linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitMonitorGdt

InitMonitorGdt    Proc near
    mov bx,mon_code_sel
    call CreateCodeSel32    
;
    mov bx,mon_gdt_sel
    mov esi,edx
    mov ecx,800h
    call CreateDataSel32
;
    mov bx,mon_flat_sel
    xor esi,esi
    xor ecx,ecx
    call CreateDataSel32        
;
    mov bx,mon_process_page_sel 
    mov esi,edi
    mov ecx,1000h
    call CreateDataSel32    
;
    mov bx,mon_text_sel
    mov esi,0B8000h
    mov ecx,1000h
    call CreateDataSel32    
;
    ret
InitMonitorGdt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          StartMonitor
;
;           DESCRIPTION:   Start monitor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public StartMonitor

StartMonitor:
    mov ax,mon_gdt_sel
    mov ss,ax
    mov esp,800h
;
    mov ax,mon_flat_sel
    mov ds,ax
    mov es,ax
;        
    xor ax,ax
    mov fs,ax
    mov gs,ax
    jmp handle_monitor

code    ENDS

    END
