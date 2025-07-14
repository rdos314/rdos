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
; BOOT.ASM
; Second stage boot-loader for DOS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\..\os.def
INCLUDE ..\..\os.inc
INCLUDE ..\..\driver.def
INCLUDE ..\..\os\port.def
INCLUDE ..\..\os\system.def
INCLUDE ..\..\os\system.inc

IMAGE_BASE = 121000h

mmap_struc  STRUC

mmap_len    DD ?
mmap_base   DD ?,?
mmap_size   DD ?,?
mmap_type   DD ?

mmap_struc  ENDS

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
    cmp esi,9F000h
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
    local gvDone
    mov ax,flat_sel
    mov ds,ax
    mov ebx,0B8000h
    mov ax,720h
    mov [ebx],ax
    cmp ax,[ebx]
    je gvDone
;    
    mov ebx,0B0000h
gvDone:    
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

_TEXT segment byte public use16 'code'

.386p

    extern Start:near

; make sure the first instruction is a jump to the startup-code

    jmp Start

code_size       DD ?

ExceptionText DB 'Exception Fault in Boot ',0
NoBootText DB 'No kernel to boot up',0

KernelLowError  DB 'Low Kernel Overwrite',0
KernelMidError  DB 'Mid Kernel Overwrite',0
KernelHighError DB 'High Kernel Overwrite',0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateCrcTab
;
;   DESCRIPTION:    Creates CRC table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crc_tab         DW 256 DUP(?)

CreateCrcTab    Proc near
    pusha
    mov ax,1021h
;
    xor cl,cl
    mov bx,OFFSET crc_tab
    
create_crc_loop:   
    xor dx,dx
    xor dh,cl
    shl dx,1
    jnc no_xor0
;
    xor dx,ax

no_xor0:
    shl dx,1
    jnc no_xor1
;
    xor dx,ax 

no_xor1:       
    shl dx,1
    jnc no_xor2
;
    xor dx,ax 

no_xor2:       
    shl dx,1
    jnc no_xor3
;
    xor dx,ax 

no_xor3:       
    shl dx,1
    jnc no_xor4
;
    xor dx,ax 

no_xor4:       
    shl dx,1
    jnc no_xor5
;
    xor dx,ax 

no_xor5:       
    shl dx,1
    jnc no_xor6
;
    xor dx,ax 

no_xor6:       
    shl dx,1
    jnc no_xor7
;
    xor dx,ax 

no_xor7:      
    mov cs:[bx],dx
    add bx,2
    inc cx
    or cl,cl
    jnz create_crc_loop
;
    popa
    ret
CreateCrcTab    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UpdateMemMap
;
;       DESCRIPTION:    Update memory map
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMemMap    Proc near
    push ds
    pushad
;    
    mov ax,flat_sel
    mov ds,ax
    mov ebx,9E000h
    mov ecx,ds:[ebx]
    or ecx,ecx
    jz ummDone
;
    add ebx,4

ummLoop:    
    mov eax,ds:[ebx].mmap_base
    or eax,ds:[ebx].mmap_base+4
    jnz ummNext
;
    mov ds:[ebx].mmap_size,9E000h
    jmp ummSetup
    
ummNext:
    mov eax,ds:[ebx].mmap_len
    add eax,4
    add ebx,eax
    sub ecx,eax
    jnz ummLoop

ummSetup:
    mov ebx,9E000h
    mov ebx,ds:[ebx]
;
    mov ax,system_data_sel
    mov ds,ax
;    
    mov ds:multiboot_mmap_addr,9E004h
    mov ds:multiboot_mmap_len,bx
;
    mov ds:ram2_base,100000h
    mov ds:ram2_size,0
            
ummDone:    
    popad
    pop ds
    ret
UpdateMemMap    Endp

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
    jnc no_cxor0
    xor ax,cx
no_cxor0:
    shl ax,1
    jnc no_cxor1
    xor ax,cx
no_cxor1:
    shl ax,1
    jnc no_cxor2
    xor ax,cx
no_cxor2:
    shl ax,1
    jnc no_cxor3
    xor ax,cx
no_cxor3:
    shl ax,1
    jnc no_cxor4
    xor ax,cx
no_cxor4:
    shl ax,1
    jnc no_cxor5
    xor ax,cx
no_cxor5:
    shl ax,1
    jnc no_cxor6
    xor ax,cx
no_cxor6:
    shl ax,1
    jnc no_cxor7
    xor ax,cx
no_cxor7:
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

;    
    push ebx
    push ecx
    push esi
    mov ecx,edx
    add esi,SIZE rdos_header
    sub ecx,SIZE rdos_header
    jz GetAdapterCrcDone
;
    xor ebx,ebx

GetAdapterCrcLoop:
    mov bl,ds:[esi]
    xor bl,ah
    shl ax,8
    xor ax,cs:[2*ebx].crc_tab
    inc esi
    sub ecx,1
    jnz GetAdapterCrcLoop

GetAdapterCrcDone:
    pop esi
    pop ecx
    pop ebx
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
    call GetAdapter
    jc get_adapters_done
;
    call AddAdapter

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
    mov eax,[bx+2]
    sub eax,OFFSET rom_idt
    add eax,OFFSET boot_idt
    mov [bx+2],eax
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

DefaultInt:
    GetVideo
    mov dh,23
    mov dl,0
    mov si,OFFSET ExceptionText
    WriteRomString
Stop:
    jmp Stop

rom_gdt:
gdt0:
    dw 0
    dd 0
    dw 0
gdt8:
    dw 10h*8-1
    dd 920F0000h + OFFSET rom_idt
    dw 0
gdt10:
    dw 28h-1
    dd 920F0000h + OFFSET rom_gdt
    dw 0
gdt18:
    dw 0FFFFh
    dd 9A0F0000h
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

    public init

init:
    cli    
    mov cs:code_size,ecx
    mov al,0FFh
    out INT0_MASK,al
IF INT1_MASK NE -1
    mov al,0FFh
    out INT1_MASK,al
ENDIF
    call CreateCrcTab
;
    mov ax,cs
    mov ds,ax
;
    mov bx,OFFSET rom_gdt + idt_sel
    movzx edx,ax
    shl edx,4
    add edx,OFFSET rom_idt
    mov [bx+2],edx
;
    mov bx,OFFSET rom_gdt + gdt_sel
    movzx edx,ax
    shl edx,4
    add edx,OFFSET rom_gdt
    mov [bx+2],edx
;
    mov bx,OFFSET rom_gdt + device_code_sel
    movzx edx,ax
    shl edx,4
    or edx,9A000000h
    mov [bx+2],edx
;
    lgdt fword ptr ds:gdt10
    lidt fword ptr ds:gdt8
;
    mov ax,cs
    mov bx,OFFSET rom_gdt + idt_sel
    movzx edx,ax
    shl edx,4
    or edx,92000000h
    add edx,OFFSET rom_idt
    mov [bx+2],edx
;
    mov bx,OFFSET rom_gdt + gdt_sel
    movzx edx,ax
    shl edx,4
    or edx,92000000h
    add edx,OFFSET rom_gdt
    mov [bx+2],edx
;
    xor ax,ax
    lahf
    mov ebx,cr0
    and bl,NOT 2
    or bl,4
    or bl,1
    mov cr0,ebx
    db 0EAh
    dw OFFSET prot_init
    dw device_code_sel

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
    xor esi,esi
    mov ax,gdt_sel
    mov ds,ax
    mov ecx,2*5
    rep movs dword ptr es:[edi],ds:[esi]
    mov ax,flat_sel
    mov ds,ax
    mov esi,edx
    mov ebx,gdt_sel
    add ebx,esi
    mov word ptr [ebx],0FFFh
    mov [ebx+2],esi
    lgdt fword ptr ds:[ebx]
;
    mov byte ptr [ebx+5],92h
    mov word ptr [ebx+6],0
;    
    FindRam
    mov ax,gdt_sel
    mov ds,ax
    mov bx,system_data_sel
    mov word ptr [bx],0FFFh
    mov [bx+2],esi
    mov byte ptr [bx+5],92h
    mov word ptr [bx+6],0
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:alloc_base,esi
;
    mov ds:ram1_size,09E000h
;
    mov eax,cs:code_size
    add eax,IMAGE_BASE
    mov ds:ram2_base,eax
    mov ds:ram2_size,20000000h  ; temporary test
;    
    mov ds:rom1_base,IMAGE_BASE
    mov eax,cs:code_size
    mov ds:rom1_size,eax
    mov ds:rom2_size,0
    mov ds:rom_shadow,0
;
    mov ax,gdt_sel
    mov ss,ax
    mov sp,1000h
;
    call UpdateMemMap
    call GetAllAdapters
    call StartShutDownDevice
    call GetBootDevice
    jnc DoBoot
;
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
    je GetVideoSel
;
    mov ebx,0B0000h

GetVideoSel:
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

_TEXT   ends    

    END
