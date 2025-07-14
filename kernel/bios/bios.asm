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
; BIOS.ASM
; BIOS emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.inc

data    SEGMENT byte public 'DATA'

bios_vect    DD 400h DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code,ds:data

real_int15:
    ReflectPmToVm

bios_error      PROC far
    or byte ptr [ebp].trap_eflags,1
    retf32
bios_error      ENDP

device_busy     PROC far
    or al,al
    jne not_disc_busy
    mov ax,flat_sel
    mov ds,ax
    mov bx,048Eh
    cli
    mov al,[bx]
    cmp al,0FFh
    je disc_busy_ok
disc_wait_loop:
    sti
    mov ax,4
    WaitMilliSec
    cli
    mov al,[bx]
    cmp al,0FFh
    jnz disc_wait_loop
disc_busy_ok:
    sti
    mov al,90h
    mov [ebp].trap_eax,al
    and byte ptr [ebp].trap_eflags,NOT 1
    mov ax,[ebp].trap_eax
    mov bx,[ebp].trap_ebx
    mov ds,[ebp].trap_pds
    retf32
not_disc_busy:
    jmp real_int15
device_busy     ENDP

mem_size    PROC far
    xor ax,ax
    retf32
mem_size    ENDP

int15_tab:
bio00   DW OFFSET real_int15
bio01   DW OFFSET real_int15
bio02   DW OFFSET real_int15
bio03   DW OFFSET real_int15
bio04   DW OFFSET real_int15
bio05   DW OFFSET real_int15
bio06   DW OFFSET real_int15
bio07   DW OFFSET real_int15
bio08   DW OFFSET real_int15
bio09   DW OFFSET real_int15
bio0A   DW OFFSET real_int15
bio0B   DW OFFSET real_int15
bio0C   DW OFFSET real_int15
bio0D   DW OFFSET real_int15
bio0E   DW OFFSET real_int15
bio0F   DW OFFSET real_int15
bio10   DW OFFSET real_int15
bio11   DW OFFSET real_int15
bio12   DW OFFSET real_int15
bio13   DW OFFSET real_int15
bio14   DW OFFSET real_int15
bio15   DW OFFSET real_int15
bio16   DW OFFSET real_int15
bio17   DW OFFSET real_int15
bio18   DW OFFSET real_int15
bio19   DW OFFSET real_int15
bio1A   DW OFFSET real_int15
bio1B   DW OFFSET real_int15
bio1C   DW OFFSET real_int15
bio1D   DW OFFSET real_int15
bio1E   DW OFFSET real_int15
bio1F   DW OFFSET real_int15
bio20   DW OFFSET real_int15
bio21   DW OFFSET real_int15
bio22   DW OFFSET real_int15
bio23   DW OFFSET real_int15
bio24   DW OFFSET real_int15
bio25   DW OFFSET real_int15
bio26   DW OFFSET real_int15
bio27   DW OFFSET real_int15
bio28   DW OFFSET real_int15
bio29   DW OFFSET real_int15
bio2A   DW OFFSET real_int15
bio2B   DW OFFSET real_int15
bio2C   DW OFFSET real_int15
bio2D   DW OFFSET real_int15
bio2E   DW OFFSET real_int15
bio2F   DW OFFSET real_int15
bio30   DW OFFSET real_int15
bio31   DW OFFSET real_int15
bio32   DW OFFSET real_int15
bio33   DW OFFSET real_int15
bio34   DW OFFSET real_int15
bio35   DW OFFSET real_int15
bio36   DW OFFSET real_int15
bio37   DW OFFSET real_int15
bio38   DW OFFSET real_int15
bio39   DW OFFSET real_int15
bio3A   DW OFFSET real_int15
bio3B   DW OFFSET real_int15
bio3C   DW OFFSET real_int15
bio3D   DW OFFSET real_int15
bio3E   DW OFFSET real_int15
bio3F   DW OFFSET real_int15
bio40   DW OFFSET real_int15
bio41   DW OFFSET real_int15
bio42   DW OFFSET real_int15
bio43   DW OFFSET real_int15
bio44   DW OFFSET real_int15
bio45   DW OFFSET real_int15
bio46   DW OFFSET real_int15
bio47   DW OFFSET real_int15
bio48   DW OFFSET real_int15
bio49   DW OFFSET real_int15
bio4A   DW OFFSET real_int15
bio4B   DW OFFSET real_int15
bio4C   DW OFFSET real_int15
bio4D   DW OFFSET real_int15
bio4E   DW OFFSET real_int15
bio4F   DW OFFSET real_int15
bio50   DW OFFSET real_int15
bio51   DW OFFSET real_int15
bio52   DW OFFSET real_int15
bio53   DW OFFSET real_int15
bio54   DW OFFSET real_int15
bio55   DW OFFSET real_int15
bio56   DW OFFSET real_int15
bio57   DW OFFSET real_int15
bio58   DW OFFSET real_int15
bio59   DW OFFSET real_int15
bio5A   DW OFFSET real_int15
bio5B   DW OFFSET real_int15
bio5C   DW OFFSET real_int15
bio5D   DW OFFSET real_int15
bio5E   DW OFFSET real_int15
bio5F   DW OFFSET real_int15
bio60   DW OFFSET real_int15
bio61   DW OFFSET real_int15
bio62   DW OFFSET real_int15
bio63   DW OFFSET real_int15
bio64   DW OFFSET real_int15
bio65   DW OFFSET real_int15
bio66   DW OFFSET real_int15
bio67   DW OFFSET real_int15
bio68   DW OFFSET real_int15
bio69   DW OFFSET real_int15
bio6A   DW OFFSET real_int15
bio6B   DW OFFSET real_int15
bio6C   DW OFFSET real_int15
bio6D   DW OFFSET real_int15
bio6E   DW OFFSET real_int15
bio6F   DW OFFSET real_int15
bio70   DW OFFSET real_int15
bio71   DW OFFSET real_int15
bio72   DW OFFSET real_int15
bio73   DW OFFSET real_int15
bio74   DW OFFSET real_int15
bio75   DW OFFSET real_int15
bio76   DW OFFSET real_int15
bio77   DW OFFSET real_int15
bio78   DW OFFSET real_int15
bio79   DW OFFSET real_int15
bio7A   DW OFFSET real_int15
bio7B   DW OFFSET real_int15
bio7C   DW OFFSET real_int15
bio7D   DW OFFSET real_int15
bio7E   DW OFFSET real_int15
bio7F   DW OFFSET real_int15
bio80   DW OFFSET real_int15
bio81   DW OFFSET real_int15
bio82   DW OFFSET real_int15
bio83   DW OFFSET real_int15
bio84   DW OFFSET real_int15
bio85   DW OFFSET real_int15
bio86   DW OFFSET real_int15
bio87   DW OFFSET bios_error
bio88   DW OFFSET mem_size
bio89   DW OFFSET real_int15
bio8A   DW OFFSET real_int15
bio8B   DW OFFSET real_int15
bio8C   DW OFFSET real_int15
bio8D   DW OFFSET real_int15
bio8E   DW OFFSET real_int15
bio8F   DW OFFSET real_int15
bio90   DW OFFSET device_busy
bio91   DW OFFSET real_int15
bio92   DW OFFSET real_int15
bio93   DW OFFSET real_int15
bio94   DW OFFSET real_int15
bio95   DW OFFSET real_int15
bio96   DW OFFSET real_int15
bio97   DW OFFSET real_int15
bio98   DW OFFSET real_int15
bio99   DW OFFSET real_int15
bio9A   DW OFFSET real_int15
bio9B   DW OFFSET real_int15
bio9C   DW OFFSET real_int15
bio9D   DW OFFSET real_int15
bio9E   DW OFFSET real_int15
bio9F   DW OFFSET real_int15
bioA0   DW OFFSET real_int15
bioA1   DW OFFSET real_int15
bioA2   DW OFFSET real_int15
bioA3   DW OFFSET real_int15
bioA4   DW OFFSET real_int15
bioA5   DW OFFSET real_int15
bioA6   DW OFFSET real_int15
bioA7   DW OFFSET real_int15
bioA8   DW OFFSET real_int15
bioA9   DW OFFSET real_int15
bioAA   DW OFFSET real_int15
bioAB   DW OFFSET real_int15
bioAC   DW OFFSET real_int15
bioAD   DW OFFSET real_int15
bioAE   DW OFFSET real_int15
bioAF   DW OFFSET real_int15
bioB0   DW OFFSET real_int15
bioB1   DW OFFSET real_int15
bioB2   DW OFFSET real_int15
bioB3   DW OFFSET real_int15
bioB4   DW OFFSET real_int15
bioB5   DW OFFSET real_int15
bioB6   DW OFFSET real_int15
bioB7   DW OFFSET real_int15
bioB8   DW OFFSET real_int15
bioB9   DW OFFSET real_int15
bioBA   DW OFFSET real_int15
bioBB   DW OFFSET real_int15
bioBC   DW OFFSET real_int15
bioBD   DW OFFSET real_int15
bioBE   DW OFFSET real_int15
bioBF   DW OFFSET real_int15
bioC0   DW OFFSET real_int15
bioC1   DW OFFSET real_int15
bioC2   DW OFFSET real_int15
bioC3   DW OFFSET real_int15
bioC4   DW OFFSET real_int15
bioC5   DW OFFSET real_int15
bioC6   DW OFFSET real_int15
bioC7   DW OFFSET real_int15
bioC8   DW OFFSET real_int15
bioC9   DW OFFSET real_int15
bioCA   DW OFFSET real_int15
bioCB   DW OFFSET real_int15
bioCC   DW OFFSET real_int15
bioCD   DW OFFSET real_int15
bioCE   DW OFFSET real_int15
bioCF   DW OFFSET real_int15
bioD0   DW OFFSET real_int15
bioD1   DW OFFSET real_int15
bioD2   DW OFFSET real_int15
bioD3   DW OFFSET real_int15
bioD4   DW OFFSET real_int15
bioD5   DW OFFSET real_int15
bioD6   DW OFFSET real_int15
bioD7   DW OFFSET real_int15
bioD8   DW OFFSET real_int15
bioD9   DW OFFSET real_int15
bioDA   DW OFFSET real_int15
bioDB   DW OFFSET real_int15
bioDC   DW OFFSET real_int15
bioDD   DW OFFSET real_int15
bioDE   DW OFFSET real_int15
bioDF   DW OFFSET real_int15
bioE0   DW OFFSET real_int15
bioE1   DW OFFSET real_int15
bioE2   DW OFFSET real_int15
bioE3   DW OFFSET real_int15
bioE4   DW OFFSET real_int15
bioE5   DW OFFSET real_int15
bioE6   DW OFFSET real_int15
bioE7   DW OFFSET real_int15
bioE8   DW OFFSET real_int15
bioE9   DW OFFSET real_int15
bioEA   DW OFFSET real_int15
bioEB   DW OFFSET real_int15
bioEC   DW OFFSET real_int15
bioED   DW OFFSET real_int15
bioEE   DW OFFSET real_int15
bioEF   DW OFFSET real_int15
bioF0   DW OFFSET real_int15
bioF1   DW OFFSET real_int15
bioF2   DW OFFSET real_int15
bioF3   DW OFFSET real_int15
bioF4   DW OFFSET real_int15
bioF5   DW OFFSET real_int15
bioF6   DW OFFSET real_int15
bioF7   DW OFFSET real_int15
bioF8   DW OFFSET real_int15
bioF9   DW OFFSET real_int15
bioFA   DW OFFSET real_int15
bioFB   DW OFFSET real_int15
bioFC   DW OFFSET real_int15
bioFD   DW OFFSET real_int15
bioFE   DW OFFSET real_int15
bioFF   DW OFFSET real_int15

int15:
    SimSti
    mov bl,ah
    xor bh,bh
    add bx,bx
    push word ptr cs:[bx].int15_tab
    mov bx,[ebp].trap_ebx
    retn


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEFAULT_GET_BIOS_DATA
;
;           DESCRIPTION:    Default for GetBiosData
;
;           PARAMETERS:     AL          Value
;                           BX          Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_get_bios_data   PROC far
    push ds
    push dx
    mov dx,flat_sel
    mov ds,dx
    movzx ebx,bx
    mov al,[ebx+400h].page0_linear
    pop dx
    pop ds
    retf32
default_get_bios_data   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DEFAULT_SET_BIOS_DATA
;
;           DESCRIPTION:    Default for SetBiosData
;
;           PARAMETERS:     AL          Value
;                           BX          Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_set_bios_data   PROC far
    push ds
    push dx
    mov dx,flat_sel
    mov ds,dx
    movzx ebx,bx
    mov [ebx+400h].page0_linear,al
    pop dx
    pop ds
    retf32
default_set_bios_data   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_BIOS_DATA
;
;           DESCRIPTION:    Get BIOS data
;
;           PARAMETERS:         AL          Value
;                           BX          Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_bios_data_name      DB 'Get BIOS Data',0

get_bios_data   PROC far
    push SEG data
    pop ds
    shl bx,4
    push dword ptr [bx+4].bios_vect
    push dword ptr [bx].bios_vect
    shr bx,4
    retf32
get_bios_data   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_BIOS_DATA
;
;           DESCRIPTION:    Set BIOS data
;
;           PARAMETERS:     AL          Value
;                           BX          Offset in BDA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_bios_data_name      DB 'Set BIOS Data',0

set_bios_data   PROC far
    push SEG data
    pop ds
    shl bx,4
    push dword ptr [bx+12].bios_vect
    push dword ptr [bx+8].bios_vect
    shr bx,4
    retf32
set_bios_data   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_GET_BIOS_DATA
;
;           DESCRIPTION:    Add hook for GetBiosData
;
;           PARAMETERS:     BX          Offset in BDA
;                           ES:EDI   Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_get_bios_data_name DB 'Hook Get BIOS Data',0

hook_get_bios_data      PROC far
    push ds
    push ax
    push bx
    mov ax,SEG data
    mov ds,ax
    shl bx,4    
    mov [bx].bios_vect,edi
    mov word ptr [bx+4].bios_vect,es
    pop bx
    pop ax
    pop ds
    retf32
hook_get_bios_data      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HOOK_SET_BIOS_DATA
;
;           DESCRIPTION:    Add hook for SetBiosData
;
;           PARAMETERS:     BX          Offset in BDA
;                           ES:EDI   Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_set_bios_data_name DB 'Hook Set BIOS Data',0

hook_set_bios_data      PROC far
    push ds
    push ax
    push bx
    mov ax,SEG data
    mov ds,ax
    shl bx,4
    mov [bx+8].bios_vect,edi
    mov word ptr [bx+12].bios_vect,es
    pop bx
    pop ax
    pop ds
    retf32
hook_set_bios_data      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           EmulateBios
;
;           DESCRIPTION:    Emulate BIOS (F000:0 F000:FFFF)
;
;           PARAMETERS:         EBX         Linear address
;                           AL          Data
;                           CY          Write access
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

emulate_bios    PROC far
    jc write_bios

read_bios:
    mov al,-1
    jmp em_bios_done

write_bios:

em_bios_done:
    retf32
emulate_bios    ENDP


multiplx_error  PROC far
    retf32
multiplx_error  ENDP

dpmi_server     PROC far
    push ax
    mov ax,query_dpmi_nr
    IsValidOsGate
    pop ax
    jc dpmi_server_done
    QueryDpmi

dpmi_server_done:
    retf32
dpmi_server     ENDP

pm16_dpmi_server    PROC far
    push ax
    mov ax,query_dpmi16_nr
    IsValidOsGate
    pop ax
    jc pm16_server_done
    QueryDpmi16
pm16_server_done:
    retf32
pm16_dpmi_server    ENDP

xms_server      PROC far
    push ax
    mov ax,query_xms_nr
    IsValidOsGate
    pop ax
    jc xms_server_done
    QueryXms
xms_server_done:
    retf32
xms_server      ENDP

vm_int2F_tab:
vmlt00  DW OFFSET multiplx_error
vmlt01  DW OFFSET multiplx_error
vmlt02  DW OFFSET multiplx_error
vmlt03  DW OFFSET multiplx_error
vmlt04  DW OFFSET multiplx_error
vmlt05  DW OFFSET multiplx_error
vmlt06  DW OFFSET multiplx_error
vmlt07  DW OFFSET multiplx_error
vmlt08  DW OFFSET multiplx_error
vmlt09  DW OFFSET multiplx_error
vmlt0A  DW OFFSET multiplx_error
vmlt0B  DW OFFSET multiplx_error
vmlt0C  DW OFFSET multiplx_error
vmlt0D  DW OFFSET multiplx_error
vmlt0E  DW OFFSET multiplx_error
vmlt0F  DW OFFSET multiplx_error
vmlt10  DW OFFSET multiplx_error
vmlt11  DW OFFSET multiplx_error
vmlt12  DW OFFSET multiplx_error
vmlt13  DW OFFSET multiplx_error
vmlt14  DW OFFSET multiplx_error
vmlt15  DW OFFSET multiplx_error
vmlt16  DW OFFSET dpmi_server
vmlt17  DW OFFSET multiplx_error
vmlt18  DW OFFSET multiplx_error
vmlt19  DW OFFSET multiplx_error
vmlt1A  DW OFFSET multiplx_error
vmlt1B  DW OFFSET multiplx_error
vmlt1C  DW OFFSET multiplx_error
vmlt1D  DW OFFSET multiplx_error
vmlt1E  DW OFFSET multiplx_error
vmlt1F  DW OFFSET multiplx_error
vmlt20  DW OFFSET multiplx_error
vmlt21  DW OFFSET multiplx_error
vmlt22  DW OFFSET multiplx_error
vmlt23  DW OFFSET multiplx_error
vmlt24  DW OFFSET multiplx_error
vmlt25  DW OFFSET multiplx_error
vmlt26  DW OFFSET multiplx_error
vmlt27  DW OFFSET multiplx_error
vmlt28  DW OFFSET multiplx_error
vmlt29  DW OFFSET multiplx_error
vmlt2A  DW OFFSET multiplx_error
vmlt2B  DW OFFSET multiplx_error
vmlt2C  DW OFFSET multiplx_error
vmlt2D  DW OFFSET multiplx_error
vmlt2E  DW OFFSET multiplx_error
vmlt2F  DW OFFSET multiplx_error
vmlt30  DW OFFSET multiplx_error
vmlt31  DW OFFSET multiplx_error
vmlt32  DW OFFSET multiplx_error
vmlt33  DW OFFSET multiplx_error
vmlt34  DW OFFSET multiplx_error
vmlt35  DW OFFSET multiplx_error
vmlt36  DW OFFSET multiplx_error
vmlt37  DW OFFSET multiplx_error
vmlt38  DW OFFSET multiplx_error
vmlt39  DW OFFSET multiplx_error
vmlt3A  DW OFFSET multiplx_error
vmlt3B  DW OFFSET multiplx_error
vmlt3C  DW OFFSET multiplx_error
vmlt3D  DW OFFSET multiplx_error
vmlt3E  DW OFFSET multiplx_error
vmlt3F  DW OFFSET multiplx_error
vmlt40  DW OFFSET multiplx_error
vmlt41  DW OFFSET multiplx_error
vmlt42  DW OFFSET multiplx_error
vmlt43  DW OFFSET xms_server
vmlt44  DW OFFSET multiplx_error
vmlt45  DW OFFSET multiplx_error
vmlt46  DW OFFSET multiplx_error
vmlt47  DW OFFSET multiplx_error
vmlt48  DW OFFSET multiplx_error
vmlt49  DW OFFSET multiplx_error
vmlt4A  DW OFFSET multiplx_error
vmlt4B  DW OFFSET multiplx_error
vmlt4C  DW OFFSET multiplx_error
vmlt4D  DW OFFSET multiplx_error
vmlt4E  DW OFFSET multiplx_error
vmlt4F  DW OFFSET multiplx_error
vmlt50  DW OFFSET multiplx_error
vmlt51  DW OFFSET multiplx_error
vmlt52  DW OFFSET multiplx_error
vmlt53  DW OFFSET multiplx_error
vmlt54  DW OFFSET multiplx_error
vmlt55  DW OFFSET multiplx_error
vmlt56  DW OFFSET multiplx_error
vmlt57  DW OFFSET multiplx_error
vmlt58  DW OFFSET multiplx_error
vmlt59  DW OFFSET multiplx_error
vmlt5A  DW OFFSET multiplx_error
vmlt5B  DW OFFSET multiplx_error
vmlt5C  DW OFFSET multiplx_error
vmlt5D  DW OFFSET multiplx_error
vmlt5E  DW OFFSET multiplx_error
vmlt5F  DW OFFSET multiplx_error
vmlt60  DW OFFSET multiplx_error
vmlt61  DW OFFSET multiplx_error
vmlt62  DW OFFSET multiplx_error
vmlt63  DW OFFSET multiplx_error
vmlt64  DW OFFSET multiplx_error
vmlt65  DW OFFSET multiplx_error
vmlt66  DW OFFSET multiplx_error
vmlt67  DW OFFSET multiplx_error
vmlt68  DW OFFSET multiplx_error
vmlt69  DW OFFSET multiplx_error
vmlt6A  DW OFFSET multiplx_error
vmlt6B  DW OFFSET multiplx_error
vmlt6C  DW OFFSET multiplx_error
vmlt6D  DW OFFSET multiplx_error
vmlt6E  DW OFFSET multiplx_error
vmlt6F  DW OFFSET multiplx_error
vmlt70  DW OFFSET multiplx_error
vmlt71  DW OFFSET multiplx_error
vmlt72  DW OFFSET multiplx_error
vmlt73  DW OFFSET multiplx_error
vmlt74  DW OFFSET multiplx_error
vmlt75  DW OFFSET multiplx_error
vmlt76  DW OFFSET multiplx_error
vmlt77  DW OFFSET multiplx_error
vmlt78  DW OFFSET multiplx_error
vmlt79  DW OFFSET multiplx_error
vmlt7A  DW OFFSET multiplx_error
vmlt7B  DW OFFSET multiplx_error
vmlt7C  DW OFFSET multiplx_error
vmlt7D  DW OFFSET multiplx_error
vmlt7E  DW OFFSET multiplx_error
vmlt7F  DW OFFSET multiplx_error
vmlt80  DW OFFSET multiplx_error
vmlt81  DW OFFSET multiplx_error
vmlt82  DW OFFSET multiplx_error
vmlt83  DW OFFSET multiplx_error
vmlt84  DW OFFSET multiplx_error
vmlt85  DW OFFSET multiplx_error
vmlt86  DW OFFSET multiplx_error
vmlt87  DW OFFSET multiplx_error
vmlt88  DW OFFSET multiplx_error
vmlt89  DW OFFSET multiplx_error
vmlt8A  DW OFFSET multiplx_error
vmlt8B  DW OFFSET multiplx_error
vmlt8C  DW OFFSET multiplx_error
vmlt8D  DW OFFSET multiplx_error
vmlt8E  DW OFFSET multiplx_error
vmlt8F  DW OFFSET multiplx_error
vmlt90  DW OFFSET multiplx_error
vmlt91  DW OFFSET multiplx_error
vmlt92  DW OFFSET multiplx_error
vmlt93  DW OFFSET multiplx_error
vmlt94  DW OFFSET multiplx_error
vmlt95  DW OFFSET multiplx_error
vmlt96  DW OFFSET multiplx_error
vmlt97  DW OFFSET multiplx_error
vmlt98  DW OFFSET multiplx_error
vmlt99  DW OFFSET multiplx_error
vmlt9A  DW OFFSET multiplx_error
vmlt9B  DW OFFSET multiplx_error
vmlt9C  DW OFFSET multiplx_error
vmlt9D  DW OFFSET multiplx_error
vmlt9E  DW OFFSET multiplx_error
vmlt9F  DW OFFSET multiplx_error
vmltA0  DW OFFSET multiplx_error
vmltA1  DW OFFSET multiplx_error
vmltA2  DW OFFSET multiplx_error
vmltA3  DW OFFSET multiplx_error
vmltA4  DW OFFSET multiplx_error
vmltA5  DW OFFSET multiplx_error
vmltA6  DW OFFSET multiplx_error
vmltA7  DW OFFSET multiplx_error
vmltA8  DW OFFSET multiplx_error
vmltA9  DW OFFSET multiplx_error
vmltAA  DW OFFSET multiplx_error
vmltAB  DW OFFSET multiplx_error
vmltAC  DW OFFSET multiplx_error
vmltAD  DW OFFSET multiplx_error
vmltAE  DW OFFSET multiplx_error
vmltAF  DW OFFSET multiplx_error
vmltB0  DW OFFSET multiplx_error
vmltB1  DW OFFSET multiplx_error
vmltB2  DW OFFSET multiplx_error
vmltB3  DW OFFSET multiplx_error
vmltB4  DW OFFSET multiplx_error
vmltB5  DW OFFSET multiplx_error
vmltB6  DW OFFSET multiplx_error
vmltB7  DW OFFSET multiplx_error
vmltB8  DW OFFSET multiplx_error
vmltB9  DW OFFSET multiplx_error
vmltBA  DW OFFSET multiplx_error
vmltBB  DW OFFSET multiplx_error
vmltBC  DW OFFSET multiplx_error
vmltBD  DW OFFSET multiplx_error
vmltBE  DW OFFSET multiplx_error
vmltBF  DW OFFSET multiplx_error
vmltC0  DW OFFSET multiplx_error
vmltC1  DW OFFSET multiplx_error
vmltC2  DW OFFSET multiplx_error
vmltC3  DW OFFSET multiplx_error
vmltC4  DW OFFSET multiplx_error
vmltC5  DW OFFSET multiplx_error
vmltC6  DW OFFSET multiplx_error
vmltC7  DW OFFSET multiplx_error
vmltC8  DW OFFSET multiplx_error
vmltC9  DW OFFSET multiplx_error
vmltCA  DW OFFSET multiplx_error
vmltCB  DW OFFSET multiplx_error
vmltCC  DW OFFSET multiplx_error
vmltCD  DW OFFSET multiplx_error
vmltCE  DW OFFSET multiplx_error
vmltCF  DW OFFSET multiplx_error
vmltD0  DW OFFSET multiplx_error
vmltD1  DW OFFSET multiplx_error
vmltD2  DW OFFSET multiplx_error
vmltD3  DW OFFSET multiplx_error
vmltD4  DW OFFSET multiplx_error
vmltD5  DW OFFSET multiplx_error
vmltD6  DW OFFSET multiplx_error
vmltD7  DW OFFSET multiplx_error
vmltD8  DW OFFSET multiplx_error
vmltD9  DW OFFSET multiplx_error
vmltDA  DW OFFSET multiplx_error
vmltDB  DW OFFSET multiplx_error
vmltDC  DW OFFSET multiplx_error
vmltDD  DW OFFSET multiplx_error
vmltDE  DW OFFSET multiplx_error
vmltDF  DW OFFSET multiplx_error
vmltE0  DW OFFSET multiplx_error
vmltE1  DW OFFSET multiplx_error
vmltE2  DW OFFSET multiplx_error
vmltE3  DW OFFSET multiplx_error
vmltE4  DW OFFSET multiplx_error
vmltE5  DW OFFSET multiplx_error
vmltE6  DW OFFSET multiplx_error
vmltE7  DW OFFSET multiplx_error
vmltE8  DW OFFSET multiplx_error
vmltE9  DW OFFSET multiplx_error
vmltEA  DW OFFSET multiplx_error
vmltEB  DW OFFSET multiplx_error
vmltEC  DW OFFSET multiplx_error
vmltED  DW OFFSET multiplx_error
vmltEE  DW OFFSET multiplx_error
vmltEF  DW OFFSET multiplx_error
vmltF0  DW OFFSET multiplx_error
vmltF1  DW OFFSET multiplx_error
vmltF2  DW OFFSET multiplx_error
vmltF3  DW OFFSET multiplx_error
vmltF4  DW OFFSET multiplx_error
vmltF5  DW OFFSET multiplx_error
vmltF6  DW OFFSET multiplx_error
vmltF7  DW OFFSET multiplx_error
vmltF8  DW OFFSET multiplx_error
vmltF9  DW OFFSET multiplx_error
vmltFA  DW OFFSET multiplx_error
vmltFB  DW OFFSET multiplx_error
vmltFC  DW OFFSET multiplx_error
vmltFD  DW OFFSET multiplx_error
vmltFE  DW OFFSET multiplx_error
vmltFF  DW OFFSET multiplx_error

int2F_vm:
    SimSti
    mov bl,ah
    xor bh,bh
    add bx,bx
    push word ptr cs:[bx].vm_int2F_tab
    mov bx,[ebp].trap_ebx
    retn

pm_int2F_tab:
pmlt00  DW OFFSET multiplx_error
pmlt01  DW OFFSET multiplx_error
pmlt02  DW OFFSET multiplx_error
pmlt03  DW OFFSET multiplx_error
pmlt04  DW OFFSET multiplx_error
pmlt05  DW OFFSET multiplx_error
pmlt06  DW OFFSET multiplx_error
pmlt07  DW OFFSET multiplx_error
pmlt08  DW OFFSET multiplx_error
pmlt09  DW OFFSET multiplx_error
pmlt0A  DW OFFSET multiplx_error
pmlt0B  DW OFFSET multiplx_error
pmlt0C  DW OFFSET multiplx_error
pmlt0D  DW OFFSET multiplx_error
pmlt0E  DW OFFSET multiplx_error
pmlt0F  DW OFFSET multiplx_error
pmlt10  DW OFFSET multiplx_error
pmlt11  DW OFFSET multiplx_error
pmlt12  DW OFFSET multiplx_error
pmlt13  DW OFFSET multiplx_error
pmlt14  DW OFFSET multiplx_error
pmlt15  DW OFFSET multiplx_error
pmlt16  DW OFFSET pm16_dpmi_server
pmlt17  DW OFFSET multiplx_error
pmlt18  DW OFFSET multiplx_error
pmlt19  DW OFFSET multiplx_error
pmlt1A  DW OFFSET multiplx_error
pmlt1B  DW OFFSET multiplx_error
pmlt1C  DW OFFSET multiplx_error
pmlt1D  DW OFFSET multiplx_error
pmlt1E  DW OFFSET multiplx_error
pmlt1F  DW OFFSET multiplx_error
pmlt20  DW OFFSET multiplx_error
pmlt21  DW OFFSET multiplx_error
pmlt22  DW OFFSET multiplx_error
pmlt23  DW OFFSET multiplx_error
pmlt24  DW OFFSET multiplx_error
pmlt25  DW OFFSET multiplx_error
pmlt26  DW OFFSET multiplx_error
pmlt27  DW OFFSET multiplx_error
pmlt28  DW OFFSET multiplx_error
pmlt29  DW OFFSET multiplx_error
pmlt2A  DW OFFSET multiplx_error
pmlt2B  DW OFFSET multiplx_error
pmlt2C  DW OFFSET multiplx_error
pmlt2D  DW OFFSET multiplx_error
pmlt2E  DW OFFSET multiplx_error
pmlt2F  DW OFFSET multiplx_error
pmlt30  DW OFFSET multiplx_error
pmlt31  DW OFFSET multiplx_error
pmlt32  DW OFFSET multiplx_error
pmlt33  DW OFFSET multiplx_error
pmlt34  DW OFFSET multiplx_error
pmlt35  DW OFFSET multiplx_error
pmlt36  DW OFFSET multiplx_error
pmlt37  DW OFFSET multiplx_error
pmlt38  DW OFFSET multiplx_error
pmlt39  DW OFFSET multiplx_error
pmlt3A  DW OFFSET multiplx_error
pmlt3B  DW OFFSET multiplx_error
pmlt3C  DW OFFSET multiplx_error
pmlt3D  DW OFFSET multiplx_error
pmlt3E  DW OFFSET multiplx_error
pmlt3F  DW OFFSET multiplx_error
pmlt40  DW OFFSET multiplx_error
pmlt41  DW OFFSET multiplx_error
pmlt42  DW OFFSET multiplx_error
pmlt43  DW OFFSET multiplx_error
pmlt44  DW OFFSET multiplx_error
pmlt45  DW OFFSET multiplx_error
pmlt46  DW OFFSET multiplx_error
pmlt47  DW OFFSET multiplx_error
pmlt48  DW OFFSET multiplx_error
pmlt49  DW OFFSET multiplx_error
pmlt4A  DW OFFSET multiplx_error
pmlt4B  DW OFFSET multiplx_error
pmlt4C  DW OFFSET multiplx_error
pmlt4D  DW OFFSET multiplx_error
pmlt4E  DW OFFSET multiplx_error
pmlt4F  DW OFFSET multiplx_error
pmlt50  DW OFFSET multiplx_error
pmlt51  DW OFFSET multiplx_error
pmlt52  DW OFFSET multiplx_error
pmlt53  DW OFFSET multiplx_error
pmlt54  DW OFFSET multiplx_error
pmlt55  DW OFFSET multiplx_error
pmlt56  DW OFFSET multiplx_error
pmlt57  DW OFFSET multiplx_error
pmlt58  DW OFFSET multiplx_error
pmlt59  DW OFFSET multiplx_error
pmlt5A  DW OFFSET multiplx_error
pmlt5B  DW OFFSET multiplx_error
pmlt5C  DW OFFSET multiplx_error
pmlt5D  DW OFFSET multiplx_error
pmlt5E  DW OFFSET multiplx_error
pmlt5F  DW OFFSET multiplx_error
pmlt60  DW OFFSET multiplx_error
pmlt61  DW OFFSET multiplx_error
pmlt62  DW OFFSET multiplx_error
pmlt63  DW OFFSET multiplx_error
pmlt64  DW OFFSET multiplx_error
pmlt65  DW OFFSET multiplx_error
pmlt66  DW OFFSET multiplx_error
pmlt67  DW OFFSET multiplx_error
pmlt68  DW OFFSET multiplx_error
pmlt69  DW OFFSET multiplx_error
pmlt6A  DW OFFSET multiplx_error
pmlt6B  DW OFFSET multiplx_error
pmlt6C  DW OFFSET multiplx_error
pmlt6D  DW OFFSET multiplx_error
pmlt6E  DW OFFSET multiplx_error
pmlt6F  DW OFFSET multiplx_error
pmlt70  DW OFFSET multiplx_error
pmlt71  DW OFFSET multiplx_error
pmlt72  DW OFFSET multiplx_error
pmlt73  DW OFFSET multiplx_error
pmlt74  DW OFFSET multiplx_error
pmlt75  DW OFFSET multiplx_error
pmlt76  DW OFFSET multiplx_error
pmlt77  DW OFFSET multiplx_error
pmlt78  DW OFFSET multiplx_error
pmlt79  DW OFFSET multiplx_error
pmlt7A  DW OFFSET multiplx_error
pmlt7B  DW OFFSET multiplx_error
pmlt7C  DW OFFSET multiplx_error
pmlt7D  DW OFFSET multiplx_error
pmlt7E  DW OFFSET multiplx_error
pmlt7F  DW OFFSET multiplx_error
pmlt80  DW OFFSET multiplx_error
pmlt81  DW OFFSET multiplx_error
pmlt82  DW OFFSET multiplx_error
pmlt83  DW OFFSET multiplx_error
pmlt84  DW OFFSET multiplx_error
pmlt85  DW OFFSET multiplx_error
pmlt86  DW OFFSET multiplx_error
pmlt87  DW OFFSET multiplx_error
pmlt88  DW OFFSET multiplx_error
pmlt89  DW OFFSET multiplx_error
pmlt8A  DW OFFSET multiplx_error
pmlt8B  DW OFFSET multiplx_error
pmlt8C  DW OFFSET multiplx_error
pmlt8D  DW OFFSET multiplx_error
pmlt8E  DW OFFSET multiplx_error
pmlt8F  DW OFFSET multiplx_error
pmlt90  DW OFFSET multiplx_error
pmlt91  DW OFFSET multiplx_error
pmlt92  DW OFFSET multiplx_error
pmlt93  DW OFFSET multiplx_error
pmlt94  DW OFFSET multiplx_error
pmlt95  DW OFFSET multiplx_error
pmlt96  DW OFFSET multiplx_error
pmlt97  DW OFFSET multiplx_error
pmlt98  DW OFFSET multiplx_error
pmlt99  DW OFFSET multiplx_error
pmlt9A  DW OFFSET multiplx_error
pmlt9B  DW OFFSET multiplx_error
pmlt9C  DW OFFSET multiplx_error
pmlt9D  DW OFFSET multiplx_error
pmlt9E  DW OFFSET multiplx_error
pmlt9F  DW OFFSET multiplx_error
pmltA0  DW OFFSET multiplx_error
pmltA1  DW OFFSET multiplx_error
pmltA2  DW OFFSET multiplx_error
pmltA3  DW OFFSET multiplx_error
pmltA4  DW OFFSET multiplx_error
pmltA5  DW OFFSET multiplx_error
pmltA6  DW OFFSET multiplx_error
pmltA7  DW OFFSET multiplx_error
pmltA8  DW OFFSET multiplx_error
pmltA9  DW OFFSET multiplx_error
pmltAA  DW OFFSET multiplx_error
pmltAB  DW OFFSET multiplx_error
pmltAC  DW OFFSET multiplx_error
pmltAD  DW OFFSET multiplx_error
pmltAE  DW OFFSET multiplx_error
pmltAF  DW OFFSET multiplx_error
pmltB0  DW OFFSET multiplx_error
pmltB1  DW OFFSET multiplx_error
pmltB2  DW OFFSET multiplx_error
pmltB3  DW OFFSET multiplx_error
pmltB4  DW OFFSET multiplx_error
pmltB5  DW OFFSET multiplx_error
pmltB6  DW OFFSET multiplx_error
pmltB7  DW OFFSET multiplx_error
pmltB8  DW OFFSET multiplx_error
pmltB9  DW OFFSET multiplx_error
pmltBA  DW OFFSET multiplx_error
pmltBB  DW OFFSET multiplx_error
pmltBC  DW OFFSET multiplx_error
pmltBD  DW OFFSET multiplx_error
pmltBE  DW OFFSET multiplx_error
pmltBF  DW OFFSET multiplx_error
pmltC0  DW OFFSET multiplx_error
pmltC1  DW OFFSET multiplx_error
pmltC2  DW OFFSET multiplx_error
pmltC3  DW OFFSET multiplx_error
pmltC4  DW OFFSET multiplx_error
pmltC5  DW OFFSET multiplx_error
pmltC6  DW OFFSET multiplx_error
pmltC7  DW OFFSET multiplx_error
pmltC8  DW OFFSET multiplx_error
pmltC9  DW OFFSET multiplx_error
pmltCA  DW OFFSET multiplx_error
pmltCB  DW OFFSET multiplx_error
pmltCC  DW OFFSET multiplx_error
pmltCD  DW OFFSET multiplx_error
pmltCE  DW OFFSET multiplx_error
pmltCF  DW OFFSET multiplx_error
pmltD0  DW OFFSET multiplx_error
pmltD1  DW OFFSET multiplx_error
pmltD2  DW OFFSET multiplx_error
pmltD3  DW OFFSET multiplx_error
pmltD4  DW OFFSET multiplx_error
pmltD5  DW OFFSET multiplx_error
pmltD6  DW OFFSET multiplx_error
pmltD7  DW OFFSET multiplx_error
pmltD8  DW OFFSET multiplx_error
pmltD9  DW OFFSET multiplx_error
pmltDA  DW OFFSET multiplx_error
pmltDB  DW OFFSET multiplx_error
pmltDC  DW OFFSET multiplx_error
pmltDD  DW OFFSET multiplx_error
pmltDE  DW OFFSET multiplx_error
pmltDF  DW OFFSET multiplx_error
pmltE0  DW OFFSET multiplx_error
pmltE1  DW OFFSET multiplx_error
pmltE2  DW OFFSET multiplx_error
pmltE3  DW OFFSET multiplx_error
pmltE4  DW OFFSET multiplx_error
pmltE5  DW OFFSET multiplx_error
pmltE6  DW OFFSET multiplx_error
pmltE7  DW OFFSET multiplx_error
pmltE8  DW OFFSET multiplx_error
pmltE9  DW OFFSET multiplx_error
pmltEA  DW OFFSET multiplx_error
pmltEB  DW OFFSET multiplx_error
pmltEC  DW OFFSET multiplx_error
pmltED  DW OFFSET multiplx_error
pmltEE  DW OFFSET multiplx_error
pmltEF  DW OFFSET multiplx_error
pmltF0  DW OFFSET multiplx_error
pmltF1  DW OFFSET multiplx_error
pmltF2  DW OFFSET multiplx_error
pmltF3  DW OFFSET multiplx_error
pmltF4  DW OFFSET multiplx_error
pmltF5  DW OFFSET multiplx_error
pmltF6  DW OFFSET multiplx_error
pmltF7  DW OFFSET multiplx_error
pmltF8  DW OFFSET multiplx_error
pmltF9  DW OFFSET multiplx_error
pmltFA  DW OFFSET multiplx_error
pmltFB  DW OFFSET multiplx_error
pmltFC  DW OFFSET multiplx_error
pmltFD  DW OFFSET multiplx_error
pmltFE  DW OFFSET multiplx_error
pmltFF  DW OFFSET multiplx_error

int2F_pm:
    mov bl,ah
    xor bh,bh
    add bx,bx
    push word ptr cs:[bx].pm_int2F_tab
    mov bx,[ebp].trap_ebx
    retn


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init driver
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_bios
    
init_bios       PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov al,15h
    mov edi,OFFSET int15
    HookVMInt
;
    mov ax,cs
    mov ds,ax
    mov al,2Fh
    mov edi,OFFSET int2F_vm
    HookVMInt
;
    mov al,2Fh
    mov edi,OFFSET int2F_pm
    HookProt16Int
;
    mov esi,OFFSET get_bios_data
    mov edi,OFFSET get_bios_data_name
    xor cl,cl
    mov ax,get_bios_data_nr
    RegisterOsGate
;
    mov esi,OFFSET set_bios_data
    mov edi,OFFSET set_bios_data_name
    xor cl,cl
    mov ax,set_bios_data_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_get_bios_data
    mov edi,OFFSET hook_get_bios_data_name
    xor cl,cl
    mov ax,hook_get_bios_data_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_set_bios_data
    mov edi,OFFSET hook_set_bios_data_name
    xor cl,cl
    mov ax,hook_set_bios_data_nr
    RegisterOsGate
;
    mov bx,SEG data
    mov ds,bx
    mov bx,OFFSET bios_vect
    mov cx,100h
init_bios_data_loop:
    mov dword ptr [bx],OFFSET default_get_bios_data
    mov [bx+4],cs
    mov dword ptr [bx+8],OFFSET default_set_bios_data
    mov [bx+12],cs
    add bx,16
    loop init_bios_data_loop
;
    mov ax,cs
    mov es,ax
;
    mov di,OFFSET emulate_bios
    mov eax,010000h
    mov edx,0F0000h
    SetPageEmulate
    ret
init_bios       ENDP

code    ENDS

    END

