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
; LEGFILE.ASM
; Legacy file interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc

    .386p

code    SEGMENT byte public 'CODE'
    
    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenLegacyFile
;
;           DESCRIPTION:    Open legacy file
;
;           PARAMETERS:     ES:(E)DI    File name
;                           
;           RETURNS:        BX          File handle
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_legacy_file_name  DB 'Open Legacy File',0

open_legacy_file32  Proc far
    push ecx
;
    mov cx,O_RDWR
    OpenHandle
;
    pop ecx
    ret
open_legacy_file32  Endp

open_legacy_file16     PROC far
    push ecx
    push edi
;
    movzx edi,di
    mov cx,O_RDWR
    OpenHandle
;
    pop edi
    pop ecx
    ret
open_legacy_file16     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateLegacyFile
;
;           DESCRIPTION:    Create legacy file
;
;           PARAMETERS:     ES:(E)DI        File name
;
;           RETURNS:        BX              File handle
;                           NC              Success
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_legacy_file_name    DB 'Create Legacy File',0

create_legacy_file32  Proc far
    push ecx
;
    mov cx,O_RDWR OR O_CREAT
    OpenHandle
;
    pop ecx
    ret
create_legacy_file32  Endp

create_legacy_file16   PROC far
    push ecx
    push edi
;
    movzx edi,di
    mov cx,O_RDWR OR O_CREAT
    OpenHandle
;
    pop edi
    pop ecx
    ret
create_legacy_file16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseLegacyFile
;
;           DESCRIPTION:    Close legacy file
;
;           PARAMETERS:     BX              File handle
;                           NC              Success
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_legacy_file_name DB 'Close Legacy File',0

close_legacy_file   Proc far
    CloseHandle
    ret
close_legacy_file   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DuplLegacyFile
;
;           DESCRIPTION:    Duplicate legacy file handle
;
;           PARAMETERS:     AX              Old file handle
;
;           RETURNS:        BX              New file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dupl_legacy_file_name  DB 'Dupl Legacy File',0

dupl_legacy_file  Proc far
    mov ebx,eax
    DupHandle
    ret
dupl_legacy_file  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetLegacyFileSize
;
;           DESCRIPTION:    Get legacy file size
;
;           PARAMETERS:     BX              File handle
;                   
;           RETURNS:        (EDX:)EAX       Size of file
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_legacy_file_size32_name      DB 'Get Legacy File Size 32',0
get_legacy_file_size64_name      DB 'Get Legacy File Size 64',0

get_legacy_file_size32   Proc far
    GetHandleSize32
    ret
get_legacy_file_size32   Endp

get_legacy_file_size64   Proc far
    GetHandleSize64
    ret
get_legacy_file_size64   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetLegacyFileSize
;
;           DESCRIPTION:    Set legacy file size
;
;           PARAMETERS:     BX              File handle
;                           (EDX:)EAX       Size of file
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_legacy_file_size32_name      DB 'Set Legacy File Size 32',0
set_legacy_file_size64_name      DB 'Set Legacy File Size 64',0

set_legacy_file_size32   Proc far
    SetHandleSize32
    ret
set_legacy_file_size32   Endp

set_legacy_file_size64   Proc far
    SetHandleSize64
    ret
set_legacy_file_size64   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetLegacyFilePos
;
;           DESCRIPTION:    Get legacy file position
;
;           PARAMETERS:     BX              File handle
;               
;           RETURNS:        (EDX:)EAX       File position
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_legacy_file_pos32_name       DB 'Get Legacy File Position 32',0
get_legacy_file_pos64_name       DB 'Get Legacy File Position 64',0

get_legacy_file_pos32   Proc far
    GetHandlePos32
    ret
get_legacy_file_pos32   Endp

get_legacy_file_pos64   Proc far
    GetHandlePos64
    ret
get_legacy_file_pos64   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetLegacyFilePos
;
;           DESCRIPTION:    Set legacy file position
;
;           PARAMETERS:     BX              File handle
;                           (EDX:)EAX       File position
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_legacy_file_pos32_name       DB 'Set Legacy File Position 32',0
set_legacy_file_pos64_name       DB 'Set Legacy File Position 64',0


set_legacy_file_pos32   Proc far
    SetHandlePos32
    ret
set_legacy_file_pos32   Endp

set_legacy_file_pos64   Proc far
    SetHandlePos64
    ret
set_legacy_file_pos64   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetLegacyFileTime
;
;           DESCRIPTION:    Get legacy file time & date
;
;           PARAMETERS:     BX              File handle
;               
;           RETURNS:        EDX:EAX         File time & date
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_legacy_file_time_name      DB 'Get Legacy File Time',0

get_legacy_file_time   Proc far
    GetHandleModifyTime
    ret
get_legacy_file_time   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetLegacyFileTime
;
;           DESCRIPTION:    Set legacy file time & date
;
;           PARAMETERS:     BX              File handle
;                           EDX:EAX         Time & date
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_legacy_file_time_name      DB 'Set Legacy File Time',0

set_legacy_file_time   Proc far
    SetHandleModifyTime
    ret
set_legacy_file_time   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLegacyFile
;
;           DESCRIPTION:    Read legacy file
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        (E)AX       Bytes read
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_legacy_file_name  DB 'Read Legacy File',0

read_legacy_file32   Proc far
    ReadHandle
    ret
read_legacy_file32   Endp

read_legacy_file16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    ReadHandle
;
    pop edi
    pop ecx
    ret
read_legacy_file16   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLegacyFile
;
;           DESCRIPTION:    Write legacy file
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        (E)AX       Bytes written
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_legacy_file_name DB 'Write Legacy File',0

write_legacy_file32   Proc far
    WriteHandle
    ret
write_legacy_file32   Endp

write_legacy_file16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    WriteHandle
;
    pop edi
    pop ecx
    ret
write_legacy_file16   Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_legacy
;
;           DESCRIPTION:    Init legacy file module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_legacy

init_legacy     PROC near
    push ds
    push es
    pushad
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov ebx,OFFSET open_legacy_file16
    mov esi,OFFSET open_legacy_file32
    mov edi,OFFSET open_legacy_file_name
    mov dx,virt_es_in
    mov ax,open_file_nr
    RegisterUserGate
;
    mov ebx,OFFSET create_legacy_file16
    mov esi,OFFSET create_legacy_file32
    mov edi,OFFSET create_legacy_file_name
    mov dx,virt_es_in
    mov ax,create_file_nr
    RegisterUserGate
;
    mov esi,OFFSET close_legacy_file
    mov edi,OFFSET close_legacy_file_name
    xor dx,dx
    mov ax,close_file_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET dupl_legacy_file
    mov edi,OFFSET dupl_legacy_file_name
    xor dx,dx
    mov ax,dupl_file_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_legacy_file_size32
    mov edi,OFFSET get_legacy_file_size32_name
    xor dx,dx
    mov ax,get_file_size32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_legacy_file_size64
    mov edi,OFFSET get_legacy_file_size64_name
    xor dx,dx
    mov ax,get_file_size64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_legacy_file_size32
    mov edi,OFFSET set_legacy_file_size32_name
    xor dx,dx
    mov ax,set_file_size32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_legacy_file_size64
    mov edi,OFFSET set_legacy_file_size64_name
    xor dx,dx
    mov ax,set_file_size64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_legacy_file_pos32
    mov edi,OFFSET get_legacy_file_pos32_name
    xor dx,dx
    mov ax,get_file_pos32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_legacy_file_pos64
    mov edi,OFFSET get_legacy_file_pos64_name
    xor dx,dx
    mov ax,get_file_pos64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_legacy_file_pos32
    mov edi,OFFSET set_legacy_file_pos32_name
    xor dx,dx
    mov ax,set_file_pos32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_legacy_file_pos64
    mov edi,OFFSET set_legacy_file_pos64_name
    xor dx,dx
    mov ax,set_file_pos64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_legacy_file_time
    mov edi,OFFSET get_legacy_file_time_name
    xor dx,dx
    mov ax,get_file_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_legacy_file_time
    mov edi,OFFSET set_legacy_file_time_name
    xor dx,dx
    mov ax,set_file_time_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET read_legacy_file16
    mov esi,OFFSET read_legacy_file32
    mov edi,OFFSET read_legacy_file_name
    mov dx,virt_es_in
    mov ax,read_file_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_legacy_file16
    mov esi,OFFSET write_legacy_file32
    mov edi,OFFSET write_legacy_file_name
    mov dx,virt_es_in
    mov ax,write_file_nr
    RegisterUserGate
;
    popad
    pop es
    pop ds
    ret
init_legacy     ENDP

code    ENDS

    END
