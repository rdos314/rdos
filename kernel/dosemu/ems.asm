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
; EMS.ASM
; EMS emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os.def
INCLUDE ..\user.def
INCLUDE ..\os.inc
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.inc

ems_handle_seg  STRUC

ems_page_count          DW ?
ems_handle_name         DB 8 DUP(?)
ems_handle_pages        DB ?

ems_handle_seg  ENDS

ems_process_seg STRUC

ems_handles             DW 256 DUP(?)

ems_process_size        DB ?

ems_process_seg ENDS

data    SEGMENT byte public 'DATA'

device_seg      DW ?

data    ENDS

        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code

emm_device_begin:
        dd -1
        dw 08000h
        dw OFFSET ems_strat - OFFSET emm_device_begin
        dw OFFSET ems_int - OFFSET emm_device_begin
        db 'TMMXXXX0'
        sti
        EmsHandler
        retf 2
ems_strat:
        retf
ems_int:
        retf
emm_device_end:

ems_name        DB 'Ems Handler',0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMS_GET_STATUS
;
;               DESCRIPTION:    GET EMS STATUS
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ems_get_status  PROC far
        pop bx
        mov ax,0
        ret
ems_get_status  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMS_FRANE_SEG
;
;               DESCRIPTION:    GET PAGE FRANE SEGMENT
;
;               PARAMETERS:             BX              PAGE FRAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ems_frame_seg   PROC far
        pop bx
        mov bx,ems_linear SHR 4
        mov ax,0
        ret
ems_frame_seg   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMS_GET_PAGE_COUNT
;
;               DESCRIPTION:    GET UNALLOCATED PAGE COUNT
;
;               PARAMETERS:             BX              UNALLOCATED PAGES
;                                               DX              TOTAL PAGES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ems_get_page_count      PROC far
        pop bx
        push eax
        GetFreePhysical
        shr eax,14
        mov bx,ax
        shr ax,2
        sub bx,ax
        pop eax
        mov dx,bx
        mov ax,0
        ret
ems_get_page_count      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMS_ALLOCATE
;
;               DESCRIPTION:    Allocate
;
;               PARAMETERS:             BX              NUMBER OF PAGES
;                                               DX              EMS HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ems_allocate    PROC far
        push eax
        GetFreePhysical
        shr eax,14
        mov bx,ax
        shr ax,2
        sub bx,ax
        pop eax
        mov ax,bx
        pop bx
        cmp ax,bx
        jc ems_allocate_fail
ems_allocate_do:
        push ds
        push es
        push eax
        push si
        push di
        mov ax,ems_process_sel
        mov ds,ax
        mov si,OFFSET ems_handles
        mov cx,0FFh
        add si,2
ems_allocate_search_handle:
        lodsw
        or ax,ax
        jz ems_allocate_handle
        loop ems_allocate_search_handle
        pop di
        pop si
        pop eax
        pop es
        pop ds
        mov ax,8500h
        ret
ems_allocate_handle:
        sub si,2
        movzx eax,bx
        shl eax,4
        add ax,OFFSET ems_handle_pages
        AllocateLocalMem
        xor di,di
        mov cx,ax
        xor al,al
        rep stosb
        mov es:ems_page_count,bx
        mov [si],es
        sub si,OFFSET ems_handles
        shr si,1
        mov dx,si
        pop di
        pop si
        pop eax
        pop es
        pop ds
        mov ax,0
        ret
ems_allocate_fail:
        mov ax,8700h
        ret
ems_allocate    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMS_FREE
;
;               DESCRIPTION:    Free
;
;               PARAMETERS:             DX              EMS HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ems_free        PROC far
        pop bx
        push ds
        push si
        mov ax,ems_process_sel
        mov ds,ax
        mov si,dx
        add si,si
        add si,OFFSET ems_handles
        mov ax,[si]
        or ax,ax
        jnz ems_free_do
        pop si
        pop ds
        mov ax,8300h
        ret
ems_free_do:
        mov word ptr [si],0
        push es
        mov es,ax
        mov cx,es:ems_page_count
        shl cx,2
        mov si,OFFSET ems_handle_pages
        push eax
free_ems_pages_loop:
        lodsd
        or eax,eax
        jz free_ems_pages_next
        and ax,0F000h
;
        push ebx
        xor ebx,ebx
        FreePhysical
        pop ebx
        
free_ems_pages_next:
        loop free_ems_pages_loop
        pop eax
        FreeMem
        pop es
        pop si
        pop ds
        mov ax,0
        ret
ems_free        ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMS_VERSION
;
;               DESCRIPTION:    VERSION
;
;               PARAMETERS:             AL              VERSION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ems_version     PROC far
        pop bx
        mov ax,40h
        ret
ems_version     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMS_GET_HANDLE_PAGES
;
;               DESCRIPTION:    GET HANDLE PAGES
;
;               PARAMETERS:             DX              HANDLE
;                                               BX              NUMBER OF PAGES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ems_get_handle_pages    PROC far
        pop bx
        mov ax,8300h
        xor bx,bx
        ret
ems_get_handle_pages    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMS_GS_HANDLE_NAME
;
;               DESCRIPTION:    GET / SET HANDLE NAME
;
;               PARAMETERS:             DX              HANDLE
;                                               ES:DI   HANDLE NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ems_gs_handle_name      PROC far
        pop bx
        mov ax,8300h
        ret
ems_gs_handle_name      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EMS_ILLEGAL
;
;               DESCRIPTION:    UNDEFINED FUNCTION
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ems_illegal     PROC far
;       int 3
        pop bx
        mov ax,8400h
        ret
ems_illegal     ENDP

ems_tab:
ems40   DW OFFSET ems_get_status
ems41   DW OFFSET ems_frame_seg
ems42   DW OFFSET ems_get_page_count
ems43   DW OFFSET ems_allocate
ems44   DW OFFSET ems_illegal
ems45   DW OFFSET ems_free
ems46   DW OFFSET ems_version
ems47   DW OFFSET ems_illegal
ems48   DW OFFSET ems_illegal
ems49   DW OFFSET ems_illegal
ems4A   DW OFFSET ems_illegal
ems4B   DW OFFSET ems_illegal
ems4C   DW OFFSET ems_get_handle_pages
ems4D   DW OFFSET ems_illegal
ems4E   DW OFFSET ems_illegal
ems4F   DW OFFSET ems_illegal
ems50   DW OFFSET ems_illegal
ems51   DW OFFSET ems_illegal
ems52   DW OFFSET ems_illegal
ems53   DW OFFSET ems_gs_handle_name
ems54   DW OFFSET ems_illegal
ems55   DW OFFSET ems_illegal
ems56   DW OFFSET ems_illegal
ems57   DW OFFSET ems_illegal
ems58   DW OFFSET ems_illegal
ems59   DW OFFSET ems_illegal
ems5A   DW OFFSET ems_illegal
ems5B   DW OFFSET ems_illegal
ems5C   DW OFFSET ems_illegal
ems5D   DW OFFSET ems_illegal
ems5E   DW OFFSET ems_illegal
ems5F   DW OFFSET ems_illegal
ems60   DW OFFSET ems_illegal

ems_handler:
        push bx
        sub ah,40h
        jc ems_call_fail
        mov bl,ah
        xor bh,bh
        add bx,bx
        cmp bx,40h
        jc ems_call_do
ems_call_fail:
        mov bx,40h
ems_call_do:
        push word ptr cs:[bx].ems_tab
        retn

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   INIT_PROCESS
;
;               DESCRIPTION:    Init per process memory
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process    PROC far
        push ds
        push es
        pusha
        mov ax,SEG data
        mov ds,ax
        mov dx,ds:device_seg
        mov ax,vm_int_sel
        mov ds,ax
        mov bx,67h SHL 2
;       mov word ptr [bx],12h
;       mov [bx+2],dx
;
        mov ax,ems_process_sel
        mov es,ax
        mov cx,100h
        mov di,OFFSET ems_handles
        xor ax,ax
        rep stosw
        popa
        pop es
        pop ds
        retf32
init_process    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   INIT
;
;               DESCRIPTION:    Init device
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_ems
    
init_ems        PROC near
        mov ax,cs
        mov ds,ax
        mov bx,OFFSET emm_device_begin
        mov cx,OFFSET emm_device_end - OFFSET emm_device_begin
        RegisterDosDevice
;
        mov bx,SEG data
        mov ds,bx
        mov ds:device_seg,dx
;
        mov eax,OFFSET ems_process_size
        mov bx,ems_process_sel
        AllocateFixedProcessMem
;
        mov ax,cs
        mov ds,ax
        mov es,ax
        mov esi,OFFSET ems_handler
        mov edi,OFFSET ems_name
        mov ax,ems_handler_nr
        mov dx,virt_ds_in OR virt_es_in
        RegisterUserGate
;
        mov edi,OFFSET init_process
        HookCreateProcess
        ret
init_ems        ENDP

code    ENDS

        END
