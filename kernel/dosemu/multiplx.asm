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
; MULTIPLX.ASM
; Multiplex int (2F) emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.inc
INCLUDE ..\os\system.inc

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

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
    mov bx,[bp].vm_ebx
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
    mov bx,[bp].vm_ebx
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

    public init_multiplx
    
init_multiplx   PROC near
    mov ax,cs
    mov ds,ax
    mov al,2Fh
    mov edi,OFFSET int2F_vm
    HookVMInt
;
    mov al,2Fh
    mov edi,OFFSET int2F_pm
    HookProt16Int
    ret
init_multiplx   ENDP

code    ENDS

    END

