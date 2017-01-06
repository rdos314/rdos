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

;
; iomode constants
;

IO_READ         = 1
IO_WRITE        = 2
IO_EOF          = 10h
IO_BINARY       = 40h
IO_APPEND       = 80h
IO_FBF          = 100h
IO_LBF          = 200h
IO_NBF          = 400h
IO_ISTTY        = 1000h

;
; open constants
;

O_RDONLY        = 0
O_WRONLY        = 1
O_RDWR          = 2
O_APPEND        = 10h
O_CREAT         = 20h
O_TRUNC         = 40h
O_NOINHERIT     = 80h
O_TEXT          = 100h
O_BINARY        = 200h
O_EXCL          = 400h

HANDLE_ENTRY_SIZE     = 16
MAX_HANDLES           = 256

handle_entry_struc    STRUC

he_file_sel      DW ?
he_file_drive    DB ?
he_resv          DB ?
he_io_mode       DW ?
he_ref_count     DW ?
he_close_proc    DW ?
he_dup_proc      DW ?
he_read_proc     DW ?
he_write_proc    DW ?

handle_entry_struc    ENDS

handle_struc    STRUC

h_section       section_typ <>

h_sel           DW ?
h_bitmap        DD ?,?

h_arr           DW MAX_HANDLES DUP(?)

handle_struc    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'
    
    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Close std in
;
;           DESCRIPTION:    Close std in
;
;           PARAMETERS:     ES:BX               Handle entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseStdIn     Proc near
    ret
CloseStdIn     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Dup std in
;
;           DESCRIPTION:    Dup std in
;
;           PARAMETERS:     ES:BX               Handle entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DupStdIn     Proc near
    ret
DupStdIn     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Read std in
;
;           DESCRIPTION:    Read std in
;
;           PARAMETERS:     ES:BX               Handle entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadStdIn     Proc near
    ret
ReadStdIn     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Write std in
;
;           DESCRIPTION:    Write std in
;
;           PARAMETERS:     ES:BX               Handle entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteStdIn     Proc near
    ret
WriteStdIn     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Close std out
;
;           DESCRIPTION:    Close std out
;
;           PARAMETERS:     ES:BX               Handle entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseStdOut     Proc near
    ret
CloseStdOut     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Dup std out
;
;           DESCRIPTION:    Dup std out
;
;           PARAMETERS:     ES:BX               Handle entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DupStdOut     Proc near
    ret
DupStdOut     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Read std out
;
;           DESCRIPTION:    Read std out
;
;           PARAMETERS:     ES:BX               Handle entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadStdOut     Proc near
    ret
ReadStdOut     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Write std out
;
;           DESCRIPTION:    Write std out
;
;           PARAMETERS:     ES:BX               Handle entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteStdOut     Proc near
    ret
WriteStdOut     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           close_file
;
;           DESCRIPTION:    Close file
;
;           PARAMETERS:     FS:BX               Handle entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_file     Proc near
    ret
close_file     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dup_file
;
;           DESCRIPTION:    Dup file
;
;           PARAMETERS:     FS:BX               Handle entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dup_file     Proc near
    ret
dup_file     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           read_file
;
;           DESCRIPTION:    Read file
;
;           PARAMETERS:     FS:BX               Handle entry
;                           ES:EDI              Buffer
;                           ECX                 Size
;
;           RETURNS:        EAX                 Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_file     Proc near
    ret
read_file     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           write_file
;
;           DESCRIPTION:    Write file
;
;           PARAMETERS:     FS:BX               Handle entry
;                           ES:EDI              Buffer
;                           ECX                 Size
;
;           RETURNS:        EAX                 Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_file     Proc near
    ret
write_file     Endp

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
    mov ds:h_bitmap,3    
    mov ds:h_bitmap+4,0
;
    mov eax,1000h
    AllocateGlobalMem
    mov ds:h_sel,es
;
    xor di,di
    mov es:[di].he_file_sel,0
    mov es:[di].he_io_mode,IO_READ OR IO_ISTTY
    mov es:[di].he_ref_count,1
    mov es:[di].he_close_proc,OFFSET CloseStdIn
    mov es:[di].he_dup_proc,OFFSET DupStdIn
    mov es:[di].he_read_proc,OFFSET ReadStdIn
    mov es:[di].he_write_proc,OFFSET WriteStdIn
;
    mov di,10h    
    mov es:[di].he_file_sel,0
    mov es:[di].he_io_mode,IO_WRITE OR IO_ISTTY
    mov es:[di].he_ref_count,1
    mov es:[di].he_close_proc,OFFSET CloseStdOut
    mov es:[di].he_dup_proc,OFFSET DupStdOut
    mov es:[di].he_read_proc,OFFSET ReadStdOut
    mov es:[di].he_write_proc,OFFSET WriteStdOut
;
    mov di,20h    
    xor ax,ax
    mov cx,7F0h
    rep stosw
;    
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
;           NAME:           allocate_handle
;
;           DESCRIPTION:    Allocate C handle
;
;           PARAMETERS:     DS          Handle sel
;                           ES          Handle data sel
;
;           RETURNS:        DI          Handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_handle     Proc near
    push eax
    push ecx

ahRetry:    
    mov eax,ds:h_bitmap
    not eax
    bsf ecx,eax
    jnz ahOk
;
    mov eax,ds:h_bitmap
    not eax
    bsf ecx,eax
    stc
    jz ahDone
;    
    add ecx,32

ahOk:
    bts ds:h_bitmap,ecx
    jc ahRetry
;    
    mov di,cx
    shl di,4
    clc

ahDone: 
    pop ecx
    pop eax
    ret
allocate_handle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           allocate_entry
;
;           DESCRIPTION:    Allocate C entry
;
;           PARAMETERS:     DS          Handle sel
;                           ES          Handle data sel
;                           DI          Handle data
;
;           RETURNS:        BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_entry     Proc near
    push ax
    push cx
;    
    mov cx,MAX_HANDLES
    mov bx,OFFSET h_arr
    EnterSection ds:h_section

aeLoop:    
    mov ax,ds:[bx]
    or ax,ax
    jz aeFound
;
    add bx,2
    loop aeLoop
;
    LeaveSection ds:h_section
    stc
    jmp aeDone

aeFound:    
    mov ax,di
    shr ax,4
    inc ax
    mov ds:[bx],ax
    LeaveSection ds:h_section
;
    sub bx,OFFSET h_arr
    shr bx,1
    inc bx
    clc

aeDone:   
    pop cx 
    pop ax
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
    push di
;    
    test cx,O_CREAT
    jz ohOpen
;
    test cx,O_EXCL
    jz ohCreate

ohExcl:
    push cx
    xor cl,cl
    UserGateForce32 open_file_nr
    pop cx
    jc ohCreate
;    
    CloseFile
    stc
    jmp ohDone

ohCreate:
    push cx
    xor cx,cx
    UserGateForce32 create_file_nr
    pop cx
    jc ohDev
;
    jmp ohHandle

ohOpen:
    push cx
    xor cl,cl
    UserGateForce32 open_file_nr
    pop cx
    jnc ohHandle

ohDev:
    int 3

ohHandle:
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds,ds:app_c_handle_sel
    mov es,ds:h_sel
    call allocate_handle
    jnc ohHandleOk
;
    CloseFile
    stc
    jmp ohDone

ohHandleOk:
    push cx
    FileToCHandle
    mov es:[di].he_file_sel,ax
    mov es:[di].he_file_drive,cl
    pop cx
;    
    mov es:[di].he_ref_count,1
    mov es:[di].he_close_proc,OFFSET close_file
    mov es:[di].he_dup_proc,OFFSET dup_file
    mov es:[di].he_read_proc,OFFSET read_file
    mov es:[di].he_write_proc,OFFSET write_file
;
    mov al,cl
    and al,3
    cmp al,O_RDWR
    je ohRdWr
;
    cmp al,O_RDONLY
    je ohRdOnly
;
    cmp al,O_WRONLY
    je ohWrOnly
;
    xor ax,ax
    jmp ohAccessOk

ohRdWr:
    mov ax,IO_READ OR IO_WRITE
    jmp ohAccessOk

ohRdOnly:
    mov ax,IO_READ
    jmp ohAccessOk

ohWrOnly:
    mov ax,IO_WRITE

ohAccessOk:
    test cx,O_APPEND
    jz ohAppendOk
;
    or ax,IO_APPEND 

ohAppendOk:
    mov es:[di].he_io_mode,ax
    call allocate_entry
    jnc ohDone
;
    int 3    

ohDone:
    pop di
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
