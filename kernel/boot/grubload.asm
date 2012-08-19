;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; GRUBLOAD.ASM
; GRUB dummy kernel (OS loader)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        NAME  grubload

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\port.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc

MY_OFFSET       = 40h

MB_FLAG_MEM     =    1
MB_FLAG_DEV =    2
MB_FLAG_CMDLINE= 4
MB_FLAG_MODULE = 8

Multiboot_struc STRUC

mb_flags        DD ?
mb_mem_lower    DD ?
mb_mem_upper    DD ?
mb_boot_dev         DD ?
mb_cmdline          DD ?
mb_module_count DD ?
mb_module_ads   DD ?

Multiboot_struc ENDS

Module_struc    STRUC

m_start         DD ?
m_end           DD ?
m_param         DD ?
m_reserved          DD ?

Module_struc    ENDS

DefaultIdtEntry     MACRO
    dw OFFSET DefaultInt
    dw device_code_sel
    dw 8E00h
    dw 0
                    ENDM

BootIdtEntry        MACRO Offs
    dw OFFSET Offs
    dw device_code_sel
    dw 8E00h
    dw 0
                    ENDM

BootExceptionOnePar     MACRO Entry
    push bp
    mov bp,sp
    sti
    push eax
    push ebx
    push ds
    mov al,Entry
    ShutDownPreTask
                ENDM

BootExceptionNoPar      MACRO Entry
    push dword ptr 0
    push bp
    mov bp,sp
    sti
    push eax
    push ebx
    push ds
    mov al,Entry
    ShutDownPreTask
                ENDM

FindRam     MACRO
    Local LowRamLoop
    Local HighRamLoop
    Local LowRamNext
    Local RamFound
    mov ax,flat_sel
    mov ds,ax
    jmp LowRamNext
LowRamLoop:
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je RamFound
LowRamNext:
    add esi,1000h
    cmp esi,09F000h
    jc LowRamLoop
    mov esi,100000h
HighRamLoop:
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je RamFound
    add esi,1000h
    jmp HighRamLoop
RamFound:
        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetVideo
;
;           DESCRIPTION:
;
;           PARAMETERS:         DS:EBX  SCREEN BASE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetVideo    MACRO
    LOCAL GetVideoLoop
    LOCAL GetVideoSel
    mov ax,flat_sel
    mov ds,ax
    mov ebx,0B8000h
    mov ax,720h
GetVideoLoop:
    mov [ebx],ax
    cmp ax,[ebx]
    je GetVideoSel
    mov ebx,0B0000h
GetVideoSel:
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteChar
;
;           DESCRIPTION:
;
;           PARAMETERS:         AL          CHAR
;                           DL          ROW
;                           DH          KOLUMN
;                           DS:EBX  SCREEN BASE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteChar       MACRO
    mov bp,ax
    mov cx,dx
    mov al,80
    mul ch
    add al,cl
    adc ah,0
    add ax,ax
    movzx eax,ax
    mov cx,bp
    mov ch,7
    mov [eax+ebx],cx
    inc dl
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SingleHex
;
;           DESCRIPTION:
;
;           PARAMETERS:         AL          Value in
;                           AX          Value out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SingleHex       MACRO
    LOCAL ok_low1
    LOCAL ok_high1
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
    add al,7
ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
    add ah,7
ok_high1:
    add ah,30h
    ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexByte
;
;           DESCRIPTION:
;
;           PARAMETERS:         AL          HEX DATA IN
;                           DL          ROW
;                           DH          KOLUMN
;                           DS:EBX  BASE-ADDRESS TO SCREEN-SEG
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    MACRO
    SingleHex
    mov di,ax
    mov al,ah
    WriteChar
    mov ax,di
    WriteChar
        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHexWord
;
;           DESCRIPTION:
;
;           PARAMETERS:         AX          HEX DATA IN
;                           DL          ROW
;                           DH          KOLUMN
;               DS:EBX  Screen Base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord    MACRO
    mov si,ax
    shr ax,8
    SingleHex
    mov di,ax
    WriteChar
    mov ax,di
    mov al,ah
    WriteChar
    mov ax,si
    SingleHex
    mov di,ax
    WriteChar
    mov ax,di
    mov al,ah
    WriteChar
        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteRomString
;
;           DESCRIPTION:
;
;           PARAMETERS:     SI      OFFSET TO STRING
;               DL          ROW
;                           DH          KOLUMN
;               DS:EBX  Screen Base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteRomString  MACRO
    Local WriteRomStringLoop
    Local WriteRomStringDone
WriteRomStringLoop:
    mov al,cs:[si]
    or al,al
    jz WriteRomStringDone
    WriteChar
    inc si
    jmp WriteRomStringLoop
WriteRomStringDone:
        ENDM

.386p

code SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CalcCrc
;
;           DESCRIPTION:    Calculate CRC for a byte
;
;       PARAMETERS:     AL      CRC
;               DS:ESI  Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcCrc Proc near
    push cx
    mov cl,[esi]
    inc esi
    xor ah,cl
;
    mov cx,1021h
    shl ax,1
    jnc no_xor0
    xor ax,cx
no_xor0:
    shl ax,1
    jnc no_xor1
    xor ax,cx
no_xor1:
    shl ax,1
    jnc no_xor2
    xor ax,cx
no_xor2:
    shl ax,1
    jnc no_xor3
    xor ax,cx
no_xor3:
    shl ax,1
    jnc no_xor4
    xor ax,cx
no_xor4:
    shl ax,1
    jnc no_xor5
    xor ax,cx
no_xor5:
    shl ax,1
    jnc no_xor6
    xor ax,cx
no_xor6:
    shl ax,1
    jnc no_xor7
    xor ax,cx
no_xor7:
    pop cx
    ret
CalcCrc Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetAdapter
;
;           DESCRIPTION:
;
;           PARAMETERS:     ESI     Adress to start search at
;                           EDI         Max address to search at
;
;       RETURNS:    ESI     Adapter base
;               ECX     Size of adapter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SignError       DB 'Rdos Signature Not Found ',0
SizeError       DB 'To Large Adapter ',0

GetAdapter  Proc near
    push ds
    mov ax,flat_sel
    mov ds,ax
GetAdapterSearch:
    mov eax,[esi]
    cmp eax,RdosSign
    je GetAdapterFound
GetAdapterNext:
    add esi,1000h
    cmp esi,edi
    jb GetAdapterSearch
    stc
    jmp GetAdapterDone
GetAdapterCorrupt:
    pop esi
    jmp GetAdapterNext
GetAdapterFound:
    push esi
    xor ecx,ecx
GetAdapterNextDriver:
    cmp [esi].sign,RdosSign
    je GetAdapterSignOk
    GetVideo
    mov si,OFFSET SignError
    mov dh,20
    mov dl,0
    WriteRomString
    jmp GetAdapterCorrupt
GetAdapterSignOk:
    cmp [esi].typ,RdosEnd
    je GetAdapterOk
    mov edx,[esi].len
    add ecx,edx
    cmp ecx,1000000h
    jc GetAdapterSizeOk
    GetVideo
    mov si,OFFSET SizeError
    mov dh,20
    mov dl,0
    WriteRomString
    jmp GetAdapterCorrupt
GetAdapterSizeOk:
    xor ax,ax
    push ecx
    push esi
    mov ecx,edx
    add esi,SIZE rdos_header
    sub ecx,SIZE rdos_header
    jz GetAdapterCrcDone
GetAdapterCrcLoop:
    call CalcCrc
    sub ecx,1
    jnz GetAdapterCrcLoop
GetAdapterCrcDone:
    pop esi
    pop ecx
    cmp ax,[esi].crc
    je GetAdapterCrcOk
    jmp GetAdapterCorrupt
GetAdapterCrcOk:
    add esi,edx
    jmp GetAdapterNextDriver
GetAdapterOk:
    pop esi
    clc
GetAdapterDone:
    pop ds
    ret
GetAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AdapterCrc
;
;           DESCRIPTION:
;
;           PARAMETERS:     ESI     Adapter base
;               ECX     Size of adapter
;
;           RETURNS:        AX          Adapter CRC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AdapterCrc  Proc near
    push ds
    mov ax,flat_sel
    mov ds,ax
    xor ax,ax
    push ecx
    push esi
AdapterCrcLoop:
    call CalcCrc
    sub ecx,1
    jnz AdapterCrcLoop
    pop esi
    pop ecx
    pop ds
    ret
AdapterCrc  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddAdapter
;
;           DESCRIPTION:
;
;           PARAMETERS:     ESI     Adapter base
;                           ECX     Size of adapter
;               AX          Adapter CRC
;                           BX          Current Adapter record
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddAdapter      Proc near
    push dx
    push di
    add ecx,SIZE rdos_header
    mov di,OFFSET rom_adapters
    mov dx,ds:rom_modules
AddAdapterCheck:
    or dx,dx
    jz AddAdapterDo
    cmp ecx,[di].adapter_size
    jne AddAdapterCheckNext
    cmp ax,[di].adapter_crc
    je AddAdapterEnd
AddAdapterCheckNext:
    dec dx
    add di,SIZE adapter_typ
    jmp AddAdapterCheck
AddAdapterDo:
    inc ds:rom_modules
    mov [bx].adapter_base,esi
    mov [bx].adapter_size,ecx
    mov [bx].adapter_crc,ax
    add bx,SIZE adapter_typ
AddAdapterEnd:
    pop di
    pop dx
    ret
AddAdapter      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetAllAdapters
;
;           DESCRIPTION:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAllAdapters  Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov esi,ds:rom1_base
    mov edi,ds:rom1_size
    add edi,esi
    mov ds:rom_modules,0
    mov bx,OFFSET rom_adapters
get_adapters_loop:
    call GetAdapter
    jc get_adapters_done
    call AdapterCrc
    call AddAdapter
    add esi,ecx
    dec esi
    and si,0F000h
    add esi,1000h
    jmp get_adapters_loop
get_adapters_done:
    ret
GetAllAdapters  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartShutdownDevice
;
;           DESCRIPTION:    Starts shutdown-device
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartShutDownDevice     Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters
    or cx,cx
    jz StartShutDeviceEnd
StartShutAdapterLoop:
    push bx
    push cx
    mov esi,[bx].adapter_base
StartShutDeviceLoop:
    cmp es:[esi].typ,RdosShutDown
    je StartShutDeviceDo
    cmp es:[esi].typ,RdosEnd
    je StartShutNextAdapter
    add esi,es:[esi].len
    jmp StartShutDeviceLoop
StartShutNextAdapter:
    pop cx
    pop bx
    add bx,SIZE adapter_typ
    loop StartShutAdapterLoop
    jmp StartShutDeviceEnd
StartShutDeviceDo:
    pop cx
    pop bx
;
    push ds
    push es
    pushad
    push cs
    push OFFSET StartShutDeviceInitied
    mov ax,flat_sel
    mov ds,ax
    mov bx,shutdown_code_sel
    push bx
    mov ecx,[esi].len
    add esi,SIZE rdos_header
    push word ptr [esi].init_ip
    add esi,SIZE simple_device_header
    mov ax,gdt_sel
    mov ds,ax
    dec cx
    mov [bx],cx
    mov [bx+2],esi
    mov ah,9Ah
    xchg ah,[bx+5]
    xor al,al
    mov [bx+6],ax
    retf
StartShutDeviceInitied:
    mov ax,gdt_sel
    mov ds,ax
    mov bx,idt_sel
    mov eax,OFFSET boot_idt
    mov [bx+2],eax
    mov byte ptr [bx+5],92h
    lidt fword ptr [bx]
    popad
    pop es
    pop ds
;
StartShutDeviceEnd:     
    ret
StartShutDownDevice     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBootDevice
;
;           DESCRIPTION:    Get header of boot-device
;
;           RETURNS:        NC
;                           ESI             Boot device base
;                           CY              No boot device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBootDevice   Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters
    or cx,cx
    jz GetBootDeviceFail
GetBootAdapterLoop:
    push bx
    push cx
    mov esi,[bx].adapter_base
GetBootDeviceLoop:
    cmp es:[esi].typ,RdosKernel
    je GetBootDeviceOk
    cmp es:[esi].typ,RdosEnd
    je GetBootNextAdapter
    add esi,es:[esi].len
    jmp GetBootDeviceLoop
GetBootNextAdapter:
    pop cx
    pop bx
    add bx,SIZE adapter_typ
    loop GetBootAdapterLoop
    jmp GetBootDeviceFail
GetBootDeviceOk:
    pop cx
    pop bx
    clc
    jmp GetBootDeviceEnd
GetBootDeviceFail:      
    stc
GetBootDeviceEnd:
    ret
GetBootDevice   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Initial GDT & IDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExceptionText DB 'Exception Fault in Boot ',0
NoBootText DB 'No kernel to boot up',0
MemFail DB 'Multiboot without memflag',0
ModuleFail DB 'No module loaded',0
TestText DB 'Test reached',0

DefaultInt:
    GetVideo
    mov dh,23
    mov dl,0
    mov si,OFFSET ExceptionText
    WriteRomString
Stop:
    jmp Stop

    public gdt8
    public gdt10

rom_gdt:
gdt0:
    dw 0
    dd 0
    dw 0
gdt8:
    dw 10h*8-1
    dd 110000h + OFFSET rom_idt + MY_OFFSET
    dw 0
gdt10:
    dw 28h-1
    dd 110000h + OFFSET rom_gdt + MY_OFFSET
    dw 0
gdt18:
    dw 0FFFFh
    dd 9A110000h + MY_OFFSET
    dw 0
gdt20:
    dw 0FFFFh
    dd 92000000h
    dw 8Fh

rom_idt:
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry
    DefaultIdtEntry

Boot0:
    BootExceptionNoPar 0

Boot1:
    BootExceptionNoPar 1

Boot2:
    BootExceptionNoPar 2

Boot3:
    BootExceptionNoPar 3

Boot4:
    BootExceptionNoPar 4

Boot5:
    BootExceptionNoPar 5

Boot6:
    BootExceptionNoPar 6

Boot7:
    BootExceptionNoPar 7

Boot8:
    BootExceptionNoPar 8

Boot9:
    BootExceptionNoPar 9

BootA:
    BootExceptionNoPar 0Ah

BootB:
    BootExceptionOnePar 0Bh

BootC:
    BootExceptionOnePar 0Ch

BootD:
    BootExceptionOnePar 0Dh

BootE:
    BootExceptionNoPar 0Eh

BootF:
    BootExceptionNoPar 0Fh

boot_idt:
    BootIdtEntry Boot0
    BootIdtEntry Boot1
    BootIdtEntry Boot2
    BootIdtEntry Boot3
    BootIdtEntry Boot4
    BootIdtEntry Boot5
    BootIdtEntry Boot6
    BootIdtEntry Boot7
    BootIdtEntry Boot8
    BootIdtEntry Boot9
    BootIdtEntry BootA
    BootIdtEntry BootB
    BootIdtEntry BootC
    BootIdtEntry BootD
    BootIdtEntry BootE
    BootIdtEntry BootF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           prot_init
;
;           DESCRIPTION:    16-bit entry point
;
;           PARAMETERS:         EBX         Multiboot info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public prot_init

prot_init:
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
;
    xor esi,esi
    FindRam
    mov edx,esi
    mov edi,esi
    mov esi,OFFSET rom_gdt
    mov ax,cs
    mov ds,ax
    mov ecx,2*5
    rep movs dword ptr es:[edi],ds:[esi]
    mov ax,flat_sel
    mov ds,ax
;
    mov esi,edx
    mov edi,gdt_sel
    add edi,esi
    mov word ptr ds:[edi],0FFFh
    mov [edi+2],esi
    lgdt fword ptr ds:[edi]
;
    mov byte ptr ds:[edi+5],92h
    mov word ptr ds:[edi+6],0
;    
    FindRam
    mov ax,gdt_sel
    mov ds,ax
    mov di,system_data_sel
    mov word ptr ds:[di],0FFFh
    mov ds:[di+2],esi
    mov byte ptr ds:[di+5],92h
    mov word ptr ds:[di+6],0
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:alloc_base,esi
    mov edx,es:[ebx].mb_flags
    test dl,MB_FLAG_MEM
    jnz MbMemOk
;
    GetVideo
    mov dh,23
    mov dl,0
    mov si,OFFSET MemFail
    WriteRomString
    jmp DoStop

MbMemOk:
    mov eax,es:[ebx].mb_mem_lower
    shl eax,10
    and ax,0F000h
    mov ds:ram1_size,eax
    mov ds:ram2_base,100000h
    mov eax,es:[ebx].mb_mem_upper
    shl eax,10
    mov edx,eax
    shr edx,10
    cmp edx,es:[ebx].mb_mem_upper
    je MbBelow4G
;
    mov ds:ram2_size,0FFF00000h
;
    mov eax,es:[ebx].mb_mem_upper
    mov edx,1024
    mul edx
    sub eax,0FFF00000h
    sbb edx,0
    mov ds:ram64_size,eax
    mov ds:ram64_size+4,edx
    jmp MbUpperOk

MbBelow4G:    
    mov ds:ram2_size,eax

MbUpperOk:
    mov edx,es:[ebx].mb_flags
    test dl,MB_FLAG_MODULE
    jnz MbModuleOk

MbModuleFail:
    GetVideo
    mov dh,23
    mov dl,0
    mov si,OFFSET ModuleFail
    WriteRomString
    jmp DoStop

MbModuleOk:
    mov ecx,es:[ebx].mb_module_count
    or ecx,ecx
    jz MbModuleFail
;
    mov esi,-1
    xor edi,edi
    mov edx,es:[ebx].mb_module_ads

MbModuleLoop:
    cmp esi,es:[edx].m_start
    jc MbModuleTestEnd
;
    mov esi,es:[edx].m_start

MbModuleTestEnd:
    cmp edi,es:[edx].m_end
    jnc MbModuleNext
;
    mov edi,es:[edx].m_end

MbModuleNext:
    add edx,16
    loop MbModuleLoop
;
    and si,0F000h
    mov ds:rom1_base,esi
    dec edi
    and di,0F000h
    add edi,1000h
    mov eax,edi
    sub eax,esi
    mov ds:rom1_size,eax
    mov ds:rom2_size,0
    mov ds:rom_shadow,0
    add eax,ds:rom1_base
    sub eax,ds:ram2_base
    sub ds:ram2_size,eax
    add ds:ram2_base,eax
;
    mov ax,gdt_sel
    mov ss,ax
    mov sp,1000h
;
    call GetAllAdapters
    call StartShutDownDevice
    call GetBootDevice
    jnc DoBoot
    GetVideo
    mov dh,23
    mov dl,0
    mov si,OFFSET NoBootText
    WriteRomString
DoStop:
    jmp DoStop
DoBoot:
    push esi
    mov ax,flat_sel
    mov ds,ax
    mov ax,gdt_sel
    mov es,ax
;
    mov ebx,0B8000h
    mov ax,720h
;
    mov [ebx],ax
    cmp ax,[ebx]
    je GetBootVideoSel

    mov ebx,0B0000h

GetBootVideoSel:
    mov si,dosB800
    mov word ptr es:[si],0FFFh
    mov es:[si+2],ebx
    mov byte ptr es:[si+5],92h
    mov word ptr es:[si+6],0

GetVideoDone:
    pop esi
    push word ptr kernel_code
    mov ecx,[esi].len
    add esi,SIZE rdos_header
    push word ptr [esi].init_ip
    add esi,SIZE simple_device_header
    mov ax,gdt_sel
    mov ds,ax
    dec cx
    mov bx,kernel_code
    mov [bx],cx
    mov [bx+2],esi
    mov ah,9Ah
    xchg ah,[bx+5]
    xor al,al
    mov [bx+6],ax
    retf

pad DB 16 DUP  (0FFh)

code    ENDS

    END
