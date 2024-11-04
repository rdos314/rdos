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
; FS.ASM
; Basic file system support module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE int.def
INCLUDE system.inc
INCLUDE ..\fs.inc
INCLUDE exec.def

CallFileSystem  MACRO   call_proc
    push ds
    push gs
    push ebp
    push esi
    mov si,fs_sys_data_sel
    mov ds,si
    movzx si,al
    add si,si
    mov ds,ds:[si]
    lgs ebp,fword ptr ds:fs_table
    lds esi,fword ptr ds:fs_drive_param
    call fword ptr gs:[ebp].&call_proc
    pop esi
    pop ebp
    pop gs
    pop ds
                ENDM

data    SEGMENT byte public 'DATA'

file_defs	        DB ?
file_def_pad            DB ?
file_def_arr		DD 4*32 DUP(?)

data    ENDS


code    SEGMENT byte public 'CODE'

    .386p

    assume cs:code

    extrn init_file:near
    extrn init_dir:near
    extrn init_memmap:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_FILE_SYSTEM
;
;           DESCRIPTION:    Register a file system
;
;           PARAMETERS:     DS:ESI       FILE SYSTEM NAME
;                           ES:EDI       FILE SYSTEM STRUC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_file_system_name       DB 'Register File System',0

register_file_system    Proc far
    push ds
    push ax
    push bx
    push cx
    mov cx,ds
    mov ax,SEG data
    mov ds,ax
    mov al,ds:file_defs
    mov bl,al
    xor bh,bh
    shl bx,4
    add bx,OFFSET file_def_arr
    mov [bx],esi
    mov [bx+4],cx
    mov [bx+8],edi
    mov [bx+12],es
    inc al
    mov ds:file_defs,al
    pop cx
    pop bx
    pop ax
    pop ds
    retf32
register_file_system    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DEMAND_LOAD_FILE_SYSTEM
;
;           DESCRIPTION:    Set file-system to demand-load mode
;
;           PARAMETERS:     AL              DRIVE #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

demand_load_file_system_name    DB 'Demand Load File System',0

demand_load_file_system Proc far
    push ds
    push es
    push bx
    push si
;
    mov bx,fs_sys_data_sel
    mov ds,bx
;
    movzx bx,al
    add bx,bx
    mov si,ds:[bx]
    or si,si
    jz demand_load_old_freed
;
    cmp si,-1
    je demand_load_old_freed
;
    CallFileSystem fs_dismount_proc
    mov es,si
    FreeMem

demand_load_old_freed:
    mov ds:[bx],-1
;
    pop si
    pop bx
    pop es
    pop ds
    retf32
demand_load_file_system Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFileSystem
;
;           DESCRIPTION:    Get a file system
;
;           PARAMETERS:     ES:EDI       FILE SYSTEM NAME
;
;           RETURNS:        ES:EDI       FILE SYSTEM CONTROL TABLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFileSystem   Proc near
    push ds
    push ax
    push bx
    push cx
    push esi
;
    mov cx,SEG data
    mov ds,cx
    movzx cx,ds:file_defs
    mov bx,OFFSET file_def_arr
    or cx,cx
    jz get_file_sys_fail

get_file_sys_find:
    push ds
    push edi
    lds esi,fword ptr [bx]

get_file_sys_check:
    lods byte ptr ds:[esi]
    or al,al
    jz get_file_sys_ok
;
    cmp al,es:[edi]
    jne get_file_sys_next
;
    inc edi
    jmp get_file_sys_check

get_file_sys_next:
    pop edi
    pop ds
    add bx,16
    loop get_file_sys_find
;
    jmp get_file_sys_fail

get_file_sys_ok:
    pop edi
    pop ds
    les edi,fword ptr [bx+8]
    clc
    jmp get_file_sys_done

get_file_sys_fail:
    stc

get_file_sys_done:
    pop esi
    pop cx
    pop bx
    pop ax
    pop ds
    ret
GetFileSystem   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IS_FILE_SYSTEM_AVAILABLE
;
;           DESCRIPTION:    Check if file system is available
;
;           PARAMETERS:     AL              DRIVE #
;                           ES:EDI       FILE SYSTEM NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_file_system_available_name   DB 'Is File System Available',0

is_file_system_available    Proc far
    push es
    push edi
    call GetFileSystem
    pop edi
    pop es
    retf32
is_file_system_available    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INSTALL_FILE_SYSTEM
;
;           DESCRIPTION:    Install a file system
;
;           PARAMETERS:     AL              DRIVE #
;                           DX              DRIVE UNIT #
;                           ES:EDI          FILE SYSTEM NAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_file_system_name    DB 'Install File System',0

install_file_system     Proc far
    push ds
    push es
    push ebx
    push ecx
    push esi
    push edi
;
    mov cx,fs_sys_data_sel
    mov ds,cx
    call GetFileSystem
    jc install_file_sys_done
;
    movzx bx,al
    add bx,bx
    push ds
    push es
    push eax
    mov si,ds:[bx]
    or si,si
    jz init_file_old_freed
;
    cmp si,-1
    je init_file_old_freed
;
    CallFileSystem fs_dismount_proc
    mov es,si
    FreeMem

init_file_old_freed:
    mov eax,SIZE fs_drive_seg
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    pop eax
    pop es
    mov dword ptr ds:fs_table,edi
    mov word ptr ds:fs_table+4,es
    mov dword ptr ds:fs_drive_param,0
    mov dword ptr ds:fs_drive_param+4,0
    InitSection ds:fs_list_section
    InitReadWriteSection ds:fs_access_section
;       EnterWriteSection ds:fs_access_section
    mov ds:fs_access_parse,0
    mov ds:fs_root_dir_sel,0
    mov ds:fs_mount_id,1
    mov si,ds
    pop ds
    mov ds:[bx],si
    clc

install_file_sys_done:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop es
    pop ds
    retf32
install_file_system     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FORMAT_FILE_SYSTEM
;
;           DESCRIPTION:    Format a file system
;
;           PARAMETERS:     AL              Drive #
;                           ECX             Drive size
;                           ES:EDI          File system name
;                           FS:EDX      Format data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

format_file_system_name DB 'Format File System',0

format_file_system      Proc far
    push ds
    push es
    push ebx
    push ecx
    push esi
    push edi
;
    call GetFileSystem
    call fword ptr es:[edi].fs_format_proc
    pushf
;
    push es
    push eax
;
    movzx bx,al
    add bx,bx
;
    mov eax,SIZE fs_drive_seg
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
;
    pop eax
    pop es
;
    mov dword ptr ds:fs_table,edi
    mov word ptr ds:fs_table+4,es
    mov dword ptr ds:fs_drive_param,0
    mov dword ptr ds:fs_drive_param+4,0
    InitSection ds:fs_list_section
    InitReadWriteSection ds:fs_access_section
    mov ds:fs_access_parse,0
    mov ds:fs_root_dir_sel,0
    mov ds:fs_mount_id,1
    mov si,ds
;
    mov cx,fs_sys_data_sel
    mov ds,cx
    mov ds:[bx],si
;
    popf
;
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop es
    pop ds
    retf32
format_file_system      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           START_FILE_SYSTEM
;
;           DESCRIPTION:    Start file system
;
;           PARAMETERS:     AL              Drive #
;                           ECX             Number of sectors to mount
;                           FS:EDX      Mount data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_file_system_name  DB 'Start File System',0

start_file_system       Proc far
    push ds
    push es
    push esi
    push di
;
    mov si,fs_sys_data_sel
    mov es,si
    movzx di,al
    add di,di
    mov ds,es:[di]
    push ds
    lds esi,fword ptr ds:fs_table
    call fword ptr ds:[esi].fs_mount_proc
    pop es
    mov dword ptr es:fs_drive_param,esi
    mov word ptr es:fs_drive_param+4,ds
    mov ax,es
    mov ds,ax
;       LeaveWriteSection ds:fs_access_section
;
    pop di
    pop esi
    pop es
    pop ds
    retf32
start_file_system       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RENAME_FILE
;
;           DESCRIPTION:    Rename file
;
;           PARAMETERS:         DS:(E)SI    CURRENT NAME
;                           ES:(E)DI    NEW NAME
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rename_file_name    DB 'Rename File',0

rename_file32:
    int 3
    stc
    retf32

rename_file16   PROC far
    int 3
    stc
    retf32
rename_file16   ENDP

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


init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET register_file_system
    mov edi,OFFSET register_file_system_name
    mov ax,register_file_system_nr
    RegisterOsGate
;
    mov esi,OFFSET demand_load_file_system
    mov edi,OFFSET demand_load_file_system_name
    mov ax,demand_load_file_system_nr
    RegisterOsGate
;
    mov esi,OFFSET format_file_system
    mov edi,OFFSET format_file_system_name
    mov ax,format_file_system_nr
    RegisterOsGate
;
    mov esi,OFFSET is_file_system_available
    mov edi,OFFSET is_file_system_available_name
    mov ax,is_file_system_available_nr
    RegisterOsGate
;
    mov esi,OFFSET install_file_system
    mov edi,OFFSET install_file_system_name
    mov ax,install_file_system_nr
    RegisterOsGate
;
    mov esi,OFFSET start_file_system
    mov edi,OFFSET start_file_system_name
    mov ax,start_file_system_nr
    RegisterOsGate
;
    mov ebx,OFFSET rename_file16
    mov esi,OFFSET rename_file32
    mov edi,OFFSET rename_file_name
    mov dx,virt_ds_in OR virt_es_in
    mov ax,rename_file_nr
    RegisterUserGate
;  
    mov al,'Z' - 'A' + 1
    movzx eax,al     
    shl eax,1
    mov bx,fs_sys_data_sel
    AllocateFixedSystemMem
;
    xor di,di
    mov al,'Z' - 'A' + 1
    movzx cx,al
    xor ax,ax
    rep stosw
;
    mov ax,SEG data
    mov ds,ax
    mov ds:file_defs,0
;
    call init_dir
    call init_file
    call init_memmap
    clc
    ret
init    ENDP

code    ENDS

    END init

