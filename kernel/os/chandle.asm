;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2017, Leif Ekblad
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
; CHANDLE.ASM
; C-library handle compatibility layer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE chandle.inc

MAX_HANDLES           = 256

handle_struc    STRUC

h_section       section_typ <>

h_arr           DW MAX_HANDLES DUP(?)

handle_struc    ENDS


    .386p

code    SEGMENT byte public use16 'CODE'
    
    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Create C handle
;
;           DESCRIPTION:    Create std-C handle selector
;
;           RETURNS:        AX          C handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_c_handle_name  DB 'Create C Handle', 0

create_c_handle    PROC far
    push ds
    push es
    push bx
    push cx
    push dx
    push si
    push di
;    
    mov eax,SIZE handle_struc
    AllocateSmallGlobalMem
;
    mov di,OFFSET h_arr
    mov ax,1
    stosw
;
    mov ax,2
    stosw
;    
    xor ax,ax
    mov cx,MAX_HANDLES - 2
    rep stosw
;    
    mov ax,es
    mov ds,ax
;    
    InitSection ds:h_section
    mov ax,ds
;
    pop di
    pop si
    pop dx
    pop cx
    pop bx    
    pop es
    pop ds
    retf32
create_c_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           allocate_c_handle
;
;           DESCRIPTION:    Allocate C handle
;
;           PARAMETERS:     AX          Handle type
;                           BX          Sel
;                           CX          Mode
;
;           RETURNS:        BX          Entry handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_c_handle_name  DB 'Allocate C Handle', 0

allocate_c_handle     Proc far
    push es
    push eax
    push edx
    push edi
;
    push eax
    push ebx
    push ecx
;
    mov ax,chandle_data_sel
    mov es,ax

achRetry:    
    mov cx,SYS_BITMAP_COUNT  
    xor edi,edi
    mov bx,OFFSET hd_bitmap

achLoop:
    mov eax,es:[bx]
    not eax
    bsf edx,eax
    jnz achOk
;
    add bx,4
    add edi,32
;
    loop achLoop
;
    stc
    pop ecx
    pop ebx
    pop eax
    jmp achDone    

achOk:
    add edx,edi
    bts es:hd_bitmap,edx
    jc achRetry
;    
    mov ax,SIZE handle_entry_struc
    mul dx
    mov di,ax
    add di,OFFSET hd_data
;
    pop ecx
    pop ebx
    pop eax
;
    mov es:[di].he_type,ax
    mov es:[di].he_sel,bx
    mov es:[di].he_ref_count,1
;
    mov al,cl
    and al,3
    cmp al,O_RDWR
    je achRdWr
;
    cmp al,O_RDONLY
    je achRdOnly
;
    cmp al,O_WRONLY
    je achWrOnly
;
    xor ax,ax
    jmp achAccessOk

achRdWr:
    mov ax,IO_READ OR IO_WRITE
    jmp achAccessOk

achRdOnly:
    mov ax,IO_READ
    jmp achAccessOk

achWrOnly:
    mov ax,IO_WRITE

achAccessOk:
    test cx,O_APPEND
    jz achAppendOk
;
    or ax,IO_APPEND 

achAppendOk:
    mov es:[di].he_io_mode,ax
;
    mov ax,di
    sub ax,OFFSET hd_data
    xor dx,dx
    mov cx,SIZE handle_entry_struc
    div cx
;
    mov bx,ax
    inc bx
    clc

achDone: 
    pop edi
    pop edx
    pop eax
    pop es
    retf32
allocate_c_handle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           allocate_entry
;
;           DESCRIPTION:    Allocate C entry
;
;           PARAMETERS:     DS          C handle sel
;                           AX          Handle data #
;
;           RETURNS:        BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_entry     Proc near
    push cx
    push dx
;    
    mov cx,MAX_HANDLES
    mov bx,OFFSET h_arr
    EnterSection ds:h_section

aeLoop:    
    mov dx,ds:[bx]
    or dx,dx
    jz aeFound
;
    add bx,2
    loop aeLoop
;
    LeaveSection ds:h_section
    stc
    jmp aeDone

aeFound:    
    mov ds:[bx],ax
    LeaveSection ds:h_section
;
    sub bx,OFFSET h_arr
    shr bx,1
    inc bx
    clc

aeDone:   
    pop dx
    pop cx 
    ret
allocate_entry  Endp   
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenHandle
;
;           DESCRIPTION:    Open C handle
;
;           PARAMETERS:     ES:(E)DI    Name
;                           CX          Mode
;
;           RETURNS:        BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_handle_name  DB 'Open C Handle', 0

open_handle     Proc near
    push ds
    push es
    push ax
    push cx
    push edi
;    
    OpenCFile
    jc ohDone
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds,ds:app_c_handle_sel
    mov ax,bx
    call allocate_entry
    jnc ohDone
;
    int 3    

ohDone:
    pop edi
    pop cx
    pop ax
    pop es
    pop ds
    ret
open_handle     Endp

open_handle16    PROC far
    push edi
    movzx edi,di
    call open_handle
    pop edi
    retf32
open_handle16    ENDP

open_handle32    PROC far
    call open_handle
    retf32
open_handle32    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_chandle
;
;           DESCRIPTION:    Init C handle module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_chandle

init_chandle     PROC near
    push ds
    push es
    pushad
;
    mov eax,SIZE handle_data_struc
    mov bx,chandle_data_sel
    AllocateFixedSystemMem
;
    xor di,di
    mov cx,SIZE handle_data_struc
    xor al,al
    rep stosb
;
    mov es:hd_bitmap,3
;
    mov di,OFFSET hd_data
    mov es:[di].he_sel,0
    mov es:[di].he_io_mode,IO_READ OR IO_ISTTY
    mov es:[di].he_ref_count,1
;
    add di,SIZE handle_entry_struc
    mov es:[di].he_sel,0
    mov es:[di].he_io_mode,IO_WRITE OR IO_ISTTY
    mov es:[di].he_ref_count,1
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET create_c_handle
    mov edi,OFFSET create_c_handle_name
    xor cl,cl
    mov ax,create_c_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_c_handle
    mov edi,OFFSET allocate_c_handle_name
    xor cl,cl
    mov ax,allocate_c_handle_nr
    RegisterOsGate
;
    mov ebx,OFFSET open_handle16
    mov esi,OFFSET open_handle32
    mov edi,OFFSET open_handle_name
    mov dx,virt_es_in
    mov ax,open_handle_nr
    RegisterUserGate
;
    popad
    pop es
    pop ds
    ret
init_chandle     ENDP

code    ENDS

    END
