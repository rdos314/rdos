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
; DOSCOM.ASM
; DOS common functions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE dos.inc

    .386p


dir_match       STRUC

dm_name_pat         DB 13 DUP(?)
dm_search_attr  DB ?
dm_entry        DW ?
dm_dir_handle   DW ?
dm_resv         DB ?,?,?
dm_attr         DB ?
dm_time         DW ?
dm_date         DW ?
dm_size         DD ?
dm_name         DB 13 DUP(?)

dir_match       ENDS

dir_cache       STRUC

dc_attr         DB ?
dc_time         DW ?
dc_date         DW ?
dc_size         DD ?
dc_name         DB 13 DUP(?)

dir_cache       ENDS

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn get_prot_psp:near
    extrn get_prot_dta:near
    extrn get_allocation_strat:near
    extrn set_allocation_strat:near
    extrn get_find_sel:near
    extrn set_find_sel:near
    extrn reset_find_sel:near


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_SYSTEM_TIME
;
;           DESCRIPTION:    DOS function 2C
;
;           PARAMETERS:         CL          MINUTES
;                           CH          HOURS
;                           DL          1/100 SECONDS
;                           DH          SECONDS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_system_time

get_system_time PROC far
    push edx
    GetTime
    push eax
    BinaryToTime
    mov ch,ah
    pop eax
    mov edx,60
    mul edx
    mov dl,60
    mul edx
    mov dl,100
    mul edx
    mov al,dl
    pop edx
    mov dl,al
    mov dh,ch
    mov ch,bh
    mov cl,bl
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    retf32
get_system_time ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_SYSTEM_TIME
;
;           DESCRIPTION:    DOS function 2D
;
;           PARAMETERS:         CL          MINUTES
;                           CH          HOURS
;                           DL          1/100 SECONDS
;                           DH          SECONDS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public set_system_time

set_system_time PROC far
    mov ax,0FFh
    retf32
set_system_time ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_SYSTEM_DATE
;
;           DESCRIPTION:    DOS function 2A
;
;           PARAMETERS:         AL          DAY OF WEEK
;                           CX          YEAR
;                           DL          DAY
;                           DH          MONTH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_system_date

get_system_date PROC far
    push edx
    GetTime
    push edx
    BinaryToTime
    mov bx,cx
    mov cx,dx
    pop eax
    push ecx
    xor edx,edx
    mov ecx,24
    div ecx
    add eax,5
    xor dl,dl
    mov ecx,7
    div ecx
    mov [bp].vm_eax,dl
    pop ecx
    pop edx
    mov dx,bx
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    retf32
get_system_date ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_SYSTEM_DATE
;
;           DESCRIPTION:    DOS function 2B
;
;           PARAMETERS:         CX          YEAR
;                           DL          DAY
;                           DH          MONTH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public set_system_date

set_system_date PROC far
    mov ax,0FFh
    retf32
set_system_date ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           STRATEGY
;
;           DESCRIPTION:    DOS function 58
;
;           PARAMETERS:
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public strategy

strategy    PROC far
    or al,al
    jz get_strat
    cmp al,1
    jz set_strat
    or byte ptr [bp].vm_eflags,NOT 1
    retf32
get_strat:
    call get_allocation_strat
    mov bx,ax
    mov ax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
set_strat:
    mov ax,bx
    call set_allocation_strat
    mov ax,[bp].vm_eax
    retf32
strategy    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           EXIT_CODE
;
;           DESCRIPTION:    DOS function 4Dh
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public exit_code

exit_code       PROC far
    mov ebx,[bp].vm_ebx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
exit_code       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DOS_VERSION
;
;           DESCRIPTION:    DOS function 30
;
;           PARAMETERS:         AX          DOS VERSION
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public dos_version

dos_version     PROC far
    mov ah,0
    mov al,5
    xor bx,bx
    xor cx,cx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
dos_version     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CONTROL_C_CHECK
;
;           DESCRIPTION:    DOS function 33
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public control_c_check

control_c_check PROC far
    mov bx,dos_vm_sel
    mov ds,bx
    or al,al
    jz control_c_get
    cmp al,1
    jz control_c_set
    mov al,0FFh
    jmp control_c_done
control_c_get:
    mov dl,ds:control_c_flag
    jmp control_c_done
control_c_set:
    mov ds:control_c_flag,dl
control_c_done:
    mov bx,[bp].vm_ebx
    retf32
control_c_check ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SWITCH_CHAR
;
;           DESCRIPTION:    DOS function 37
;
;           PARAMETERS:         DL          SWITCH CHAR
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public switch_char

switch_char     PROC far
    mov ax,[bp].vm_eax
    or al,al
    jnz switch_char_fail
    mov dl,2Fh
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
switch_char_fail:
    or byte ptr [bp].vm_eflags,1
    retf32
switch_char     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DOS_WRITE_CHAR
;
;           DESCRIPTION:    DOS function 2 
;
;           PARAMETERS:         DL          CHAR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public dos_write_char

dos_write_char  PROC far
    mov al,dl
    WriteChar
    and byte ptr [bp].vm_eflags, NOT 1
    mov ax,[bp].vm_eax
    retf32
dos_write_char  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DOS_READ_KEY
;
;           DESCRIPTION:    DOS function 7,8 
;
;           PARAMETERS:         AL          CHAR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public dos_read_key

dos_read_key    PROC far
    ReadKeyboardSerial
    and byte ptr [bp].vm_eflags, NOT 1
    retf32
dos_read_key    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DOS_READ_KEY_ECHO
;
;           DESCRIPTION:    DOS function 1
;
;           PARAMETERS:         AL          CHAR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public dos_read_key_echo

dos_read_key_echo       PROC far
    ReadKeyboardSerial
    WriteChar
    and byte ptr [bp].vm_eflags, NOT 1
    retf32
dos_read_key_echo       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DOS_CON_IO
;
;           DESCRIPTION:    DOS function 6
;
;           PARAMETERS:         AL          CHAR
;                           DL          CHAR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public dos_con_io

dos_con_io      PROC far
    cmp dl,0FFh
    je dos_con_inp
    mov al,dl
    WriteChar
dos_con_io_done:
    mov ax,[bp].vm_eax
    retf32
dos_con_inp:
    PollKeyboardSerial
    jc dos_con_nochar
    ReadKeyboardSerial
    and byte ptr [bp].vm_eflags,NOT 40h
    retf32
dos_con_nochar:
    or byte ptr [bp].vm_eflags,40h
    xor ax,ax
    retf32
dos_con_io      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DOS_KEY_STATE
;
;           DESCRIPTION:    DOS function 0B
;
;           PARAMETERS:         AL          KEY STATE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public dos_key_state

dos_key_state   PROC far
    PollKeyboardSerial
    jc dos_key_state_nochar
    mov ax,0FFh
    jmp dos_key_state_done
dos_key_state_nochar:
    xor ax,ax
dos_key_state_done:
    retf32
dos_key_state   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IOCTL
;
;           DESCRIPTION:    DOS function 44
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ioctl

ioctl   PROC far
    push es
    push cx
    push di
    or al,al
    mov ax,1
    jnz ioctl_fail
    call get_prot_psp
    mov es,bx
    mov ax,[bp].vm_ebx
    cmp ax,es:psp_handlesize
    jc get_ioctl_data_handle_inrange
    mov ax,6
    jmp ioctl_fail
get_ioctl_data_handle_inrange:
    mov bx,es:psp_handleads
    add bx,ax
    mov al,es:[bx]
    movzx bx,al
    mov ax,6
    cmp bx,0FFh
    je ioctl_fail
;    GetIoctlData
    and byte ptr [bp].vm_eflags,NOT 1
    pop di
    pop cx
    pop es
    mov bx,[bp].vm_ebx
    mov ax,dx
    retf32
ioctl_fail:
    or byte ptr [bp].vm_eflags,1
    pop di
    pop cx
    pop es
    mov bx,[bp].vm_ebx
    retf32
ioctl   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CLOSE_HANDLE
;
;           DESCRIPTION:    DOS function 3E
;
;           PARAMETERS:         BX              HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public close_handle

close_handle    PROC far
    push es
    push cx
    push di
    call get_prot_psp
    mov es,bx
    mov ax,[bp].vm_ebx
    cmp ax,es:psp_handlesize
    jc close_handle_inrange
close_fail:
    mov ax,6
    or byte ptr [bp].vm_eflags, 1
    jmp close_handle_done
close_handle_inrange:
    mov bx,es:psp_handleads
    add bx,ax
    mov al,0FFh
    xchg al,es:[bx]
    movzx bx,al
    cmp bx,0FFh
    je close_fail
    mov di,es:psp_handleads
    mov cx,es:psp_handlesize
    repne scasb
    je close_handle_closed
    CloseFile
close_handle_closed:
    and byte ptr [bp].vm_eflags, NOT 1
    mov ax,[bp].vm_eax
close_handle_done:
    mov bx,[bp].vm_ebx
    pop di
    pop cx
    pop es
    retf32
close_handle    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MOVE_POINTER
;
;           DESCRIPTION:    DOS function 42
;
;           PARAMETERS:         BX              HANDLE
;                           AL              METHOD
;                           CX:DX       DISTANCE
;                           DX:AX       NEW POSITION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public move_pointer

move_pointer    PROC far
    push es
    push edx
    call get_prot_psp
    mov es,bx
    mov ax,[bp].vm_ebx
    cmp ax,es:psp_handlesize
    jc move_pointer_inrange
move_pointer_fail:
    pop edx
    mov ax,6
    or byte ptr [bp].vm_eflags, 1
    jmp move_pointer_done
move_pointer_inrange:
    mov bx,es:psp_handleads
    add bx,ax
    movzx bx,byte ptr es:[bx]
    cmp bx,0FFh
    je move_pointer_fail
    push cx
    push dx
    pop edx
    mov al,[bp].vm_eax
    or al,al
    jnz move_not_begin
    mov eax,edx
    SetFilePos32
    jnc move_pointer_ok
    jmp move_pointer_fail
move_not_begin:
    sub al,1
    jnz move_not_current
    GetFilePos32
    add eax,edx
    SetFilePos32
    jnc move_pointer_ok
    jmp move_pointer_fail
move_not_current:
    sub al,1
    jnz move_not_end
    GetFileSize32
    add eax,edx
    SetFilePos32
    jnc move_pointer_ok
    jmp move_pointer_fail
move_not_end:
    pop edx
    mov ax,1
    or byte ptr [bp].vm_eflags,1
    jmp move_pointer_done
move_pointer_ok:
    pop edx
    push eax
    mov eax,[bp].vm_eax
    pop ax
    pop dx
    and byte ptr [bp].vm_eflags,NOT 1
move_pointer_done:
    mov bx,[bp].vm_ebx
    pop es
    retf32
move_pointer    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DUPL_HANDLE
;
;           DESCRIPTION:    DOS function 45
;
;           PARAMETERS:         BX              HANDLE
;                           AX              NEW HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public dupl_handle

dupl_handle     PROC far
    push es
    push cx
    push di
    call get_prot_psp
    mov es,bx
    mov ax,[bp].vm_ebx
    cmp ax,es:psp_handlesize
    jc dupl_handle_inrange
dupl_handle_fail:
    mov ax,6
    or byte ptr [bp].vm_eflags, 1
    jmp dupl_handle_done
dupl_handle_inrange:
    mov bx,es:psp_handleads
    add bx,ax
    mov bl,byte ptr es:[bx]
    cmp bl,0FFh
    jz dupl_handle_fail
    mov di,es:psp_handleads
    mov cx,es:psp_handlesize
    mov al,0FFh
    repne scasb
    jz dupl_handle_found
    or byte ptr [bp].vm_eflags,1
    mov ax,4 
    jmp dupl_handle_done
dupl_handle_found:
    dec di
    mov es:[di],bl
    sub di,es:psp_handleads
    mov ax,di
    and byte ptr [bp].vm_eflags,NOT 1
dupl_handle_done:
    mov bx,[bp].vm_ebx
    pop di
    pop cx
    pop es
    retf32
dupl_handle     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FORCE_DUPL_HANDLE
;
;           DESCRIPTION:    DOS function 46
;
;           PARAMETERS:         BX              HANDLE
;                           CX              SECOND HANDLE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public force_dupl_handle

force_dupl_handle       PROC far
    push es
    push cx
    push di
    call get_prot_psp
    mov es,bx
    mov ax,[bp].vm_ebx
    cmp ax,es:psp_handlesize
    jc force_dupl_handle_inrange
force_dupl_handle_fail:
    mov ax,6
    or byte ptr [bp].vm_eflags, 1
    jmp force_dupl_handle_done
force_dupl_handle_inrange:
    mov bx,es:psp_handleads
    add bx,ax
    mov al,byte ptr es:[bx]
    cmp al,0FFh
    je force_dupl_handle_fail
    cmp cx,es:psp_handlesize
    jnc force_dupl_handle_fail
    mov bx,es:psp_handleads
    add bx,cx
    xchg al,es:[bx]
    cmp al,0FFh
    je force_dupl_handle_closed
    mov di,es:psp_handleads
    mov cx,es:psp_handlesize
    repne scasb
    je force_dupl_handle_closed
    CloseFile
force_dupl_handle_closed:
    mov ax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
force_dupl_handle_done:
    mov bx,[bp].vm_ebx
    pop di
    pop cx
    pop es
    retf32
force_dupl_handle       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DATE_TIME_HANDLE
;
;           DESCRIPTION:    DOS function 57
;
;           PARAMETERS:         BX              HANDLE
;                           CX              TIME
;                           DX              DATE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public date_time_handle

date_time_handle    PROC far
    push es
    call get_prot_psp
    mov es,bx
    mov ax,[bp].vm_ebx
    cmp ax,es:psp_handlesize
    jc date_time_handle_inrange
date_time_handle_fail:
    mov ax,6
    or byte ptr [bp].vm_eflags, 1
    jmp date_time_handle_done
date_time_handle_inrange:
    mov bx,es:psp_handleads
    add bx,ax
    mov bl,byte ptr es:[bx]
    cmp bl,0FFh
    jz date_time_handle_fail
    mov al,[bp].vm_eax
    or al,al
    jz get_date_time_handle
    sub al,1
    jz set_date_time_handle
    jmp date_time_handle_fail

date_time_handle_fail_pop:
    pop eax
    jmp date_time_handle_fail

get_date_time_handle:
    push eax
    GetFileTime
    jc date_time_handle_fail_pop
    BinaryToTime
    shl cl,3
    shr cx,3
    sub dx,1980
    mov dh,dl
    shl dh,1
    xor dl,dl
    or dx,cx
    mov al,ah
    shr al,1
    shl bl,2
    shl bx,3
    or bl,al
    mov cx,bx
    pop eax
    and byte ptr [bp].vm_eflags, NOT 1
    jmp date_time_handle_done

set_date_time_handle:
    push eax
    push edx
    push bx
    push cx
    push di
;
    push cx
    mov ax,dx
    shr dx,9
    add dx,1980
    mov cx,ax
    shr cx,5
    mov ch,cl
    and ch,0Fh
    mov cl,al
    and cl,1Fh
    pop di
    mov bx,di
    shr bx,11
    mov bh,bl
    mov ax,di
    shr ax,5
    and al,3Fh
    mov bl,al
    mov ax,di
    mov ah,al
    add ah,ah
    and ah,3Fh
    TimeToBinary
    pop di
    pop cx
    pop bx
    SetFileTime
    pop edx
    pop eax
    jc date_time_handle_fail
    and byte ptr [bp].vm_eflags, NOT 1

date_time_handle_done:
    mov bx,[bp].vm_ebx
    pop es
    retf32
date_time_handle    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_DRIVE_ALLOCATION
;
;           DESCRIPTION:    DOS function 36
;
;           PARAMETERS:         AL                  DRIVE NUMBER
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_drive_allocation

get_drive_allocation    PROC far
    mov al,dl
    sub al,1
    jnc get_drive_alloc_not_default
    GetCurDrive
get_drive_alloc_not_default:
    GetDriveInfo
    mov bx,1
get_drive_norm_loop:
    cmp edx,10000h
    jc get_drive_norm_done
    shl bx,1
    shr edx,1
    shr eax,1
    cmp bx,40h
    jc get_drive_norm_loop
;
    cmp eax,10000h
    jc get_drive_ax_ok
;
    mov eax,0FFFFh

get_drive_ax_ok:
    cmp edx,10000h
    jc get_drive_norm_done
;
    mov edx,0FFFFh

get_drive_norm_done:
    xchg ax,bx
    and byte ptr [bp].vm_eflags, NOT 1
    retf32
get_drive_allocation    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SELECT_DRIVE
;
;           DESCRIPTION:    DOS function 0E
;
;           PARAMETERS:         DL                  DRIVE NUMBER
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public select_drive

select_drive    PROC far
    mov al,dl
    SetCurDrive
    jnc select_drive_ok
    mov ax,15
    or byte ptr [bp].vm_eflags, 1
    retf32
select_drive_ok:
    and byte ptr [bp].vm_eflags,NOT 1
    mov ax,[bp].vm_eax
    retf32
select_drive    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_DRIVE
;
;           DESCRIPTION:    DOS function 19H
;
;           PARAMETERS:         AL                  DRIVE NUMBER
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_drive

get_drive       PROC far
    GetCurDrive
    and byte ptr [bp].vm_eflags, NOT 1
    retf32
get_drive       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       OpenFileSearch
;
;       DESCRIPTION:    Open file search
;
;           PARAMETERS:         DS:ESI      File to search for
;
;           RETURNS:        BX              Dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

default_dir     DB 0

OpenFileSearch  Proc near
    push es
    push eax
    push ecx
    push edx
    push edi
;
    xor ecx,ecx
    push esi
ofsSizeLoop:
    lods byte ptr [esi]
    or al,al
    jz ofsSizeFound
    inc ecx
    jmp ofsSizeLoop
ofsSizeFound:
    or ecx,ecx
    je ofsDirFound
    mov edi,ecx
ofsDirLoop:
    dec esi
    mov al,[esi]
    cmp al,'\'
    je ofsDirFound
    sub ecx,1
    jne ofsDirLoop
    pop esi
    mov ax,cs
    mov es,ax
    mov di,OFFSET default_dir
    OpenLegacyDir
    jmp ofsDone

ofsDirFound:
    pop esi
    mov eax,ecx
    add eax,4
    AllocateLocalMem
    push eax
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]
    or di,di
    jz ofsDirNotRoot
;
    mov al,es:[di-1]
    cmp al,':'
    jne ofsDirNotRoot
;
    mov al,'\'
    stosb

ofsDirNotRoot:
    xor al,al
    stosb
    xor di,di
    OpenLegacydir
    pop eax
    pushf
    inc esi
    FreeMem
    popf
ofsDone:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
OpenFileSearch  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       CheckAttrib
;
;       DESCRIPTION:    Check attribute of file
;
;           PARAMETERS:         DL          Search attribute
;                           DH          File attribute
;
;           RETURNS:        NC          Attribute is ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckAttrib     Proc near
    and dl,NOT 21h
    and dh,NOT 21h
    or dh,dh
    jz caFile
;
    test dh,10h
    jnz caDir
;
    test dh,8
    jnz caVolume
;
    and dh,6
    and dl,6
    cmp dl,dh
    je caOk
    jmp caFail

caVolume:
    test dl,8
    jnz caOk
    jmp caFail

caDir:
    test dl,10h
    jnz caOk
    jmp caFail

caFile:
    cmp dl,8
    jne caOk

caFail:
    stc
    ret

caOk:
    clc
    ret
CheckAttrib     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       GetMatchingFiles
;
;       DESCRIPTION:    Get all matching files
;
;           PARAMETERS:         DS:ESI  Filename
;                           CX          Attribute
;                           BX          Handle to dir
;
;           RETURNS:        ES          Entries array
;                           CX          Number of entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MatchTab:
ct00 DB 0,          0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct08 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct10 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct18 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct20 DB ' ',    '!',    0FFh,   '#',    '$',    '%',    '&',    27h
ct28 DB '(',    ')',    '*',    0FFh,   0FFh,   '-',    '.',    0
ct30 DB '0',    '1',    '2',    '3',    '4',    '5',    '6',    '7'
ct38 DB '8',    '9',    0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   '?'
ct40 DB '@',    'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct48 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct50 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct58 DB 'X',    'Y',    'Z',    0FFh,   0,          0FFh,   '^',    '_'
ct60 DB 60h,    'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct68 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct70 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct78 DB 'X',    'Y',    'Z',    '{',    0FFh,   '}',    '~',    0FFh
ct80 DB 0FFh,   9Ah,    90h,    0FFh,   'é',    0FFh,   'è',    0FFh
ct88 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   'é',    'è'
ct90 DB 0FFh,   0FFh,   0FFh,   0FFh,   'ô',    0FFh,   0FFh,   0FFh
ct98 DB 0FFh,   'ô',    9Ah,    9Bh,    9Ch,    9Dh,    9Eh,    9Fh
ctA0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0A5h,   0A5h,   0A6h,   0A7h
ctA8 DB 0A8h,   0A9h,   0AAh,   0ABh,   0ACh,   0ADh,   0AEh,   0AFh
ctB0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctB8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctC0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctC8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctD0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctD8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctE0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctE8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctF0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctF8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh

gmfEntry        EQU -2
gmfHandle           EQU -4
gmfCurrBase         EQU -6
gmfEntries          EQU -8
gmfSearchAttrib EQU -10
gmfFileAttrib   EQU -12

GetMatchingFiles Proc near
    push bp
    mov bp,sp
    sub sp,12
    push eax
    push bx
    push di
;
    mov [bp].gmfSearchAttrib,cx
    mov eax,10000h
    AllocateLocalMem
    xor di,di
    mov [bp].gmfCurrBase,di
    mov word ptr [bp].gmfEntries,0
    mov word ptr [bp].gmfEntry,-1
    mov [bp].gmfHandle,bx

gmfLoop:
    mov bx,[bp].gmfHandle
    mov dx,[bp].gmfEntry
    inc dx
    mov [bp].gmfEntry,dx
    mov cx,14
    mov di,[bp].gmfCurrBase
    ReadLegacyDir
    jc gmfDone
;
    mov [bp].gmfFileAttrib,bx
    push esi
    mov bx,OFFSET MatchTab
gmfTestBase:
    mov al,[esi]
    cmp al,'*'
    je gmfStarExt
    cmp al,'.'
    je gmfDotFound
    cmp al,'?'
    je gmfBaseCharOk
    xlat byte ptr cs:MatchTab
    mov ah,al
    mov al,es:[di]
    xlat byte ptr cs:MatchTab
    cmp al,ah
    jne gmfNext
    mov al,ah
gmfBaseCharOk:
    or al,al
    je short gmfOk
    inc esi
    inc di
    jmp gmfTestBase

gmfStarExt:
    inc esi
gmfParseStar:
    mov al,[esi]
    inc esi
    cmp al,'.'
    je gmfStarFile
    or al,al    
    je gmfOk
    jmp gmfParseStar
gmfStarFile:
    mov al,es:[di]
    inc di
    or al,al
    je gmfParseEndFile
    cmp al,'.'
    je gmfTestExt
    jmp gmfStarFile

gmfDotFound:
    inc esi
gmfParseExt:
    mov al,es:[di]
    or al,al
    je gmfParseEndFile
    cmp al,'.'
    jne gmfNext
    inc di
    jmp gmfTestExt

gmfParseEndFile:
    mov al,[esi]
    cmp al,'*'
    je gmfOk
    or al,al
    je gmfOk
    cmp al,'?'
    jne gmfNext
    inc esi
    jmp gmfParseEndFile

gmfTestExt:
    mov al,[esi]
    cmp al,'*'
    je gmfOk
    cmp al,'?'
    je gmfExtCharOk
    xlat byte ptr cs:MatchTab
    mov ah,al
    mov al,es:[di]
    xlat byte ptr cs:MatchTab
    cmp al,ah
    jne gmfNext
    mov al,ah
gmfExtCharOk:
    or al,al
    je gmfOk
    inc esi
    inc di
    jmp gmfTestExt

gmfOk:
    mov dl,[bp].gmfSearchAttrib
    mov dh,[bp].gmfFileAttrib
    call CheckAttrib
    jc gmfNext

gmfAttribOk:
    mov di,[bp].gmfCurrBase
    mov ax,[bp].gmfEntry
    stosw
    mov [bp].gmfCurrBase,di
    inc word ptr [bp].gmfEntries

gmfNext:
    pop esi
    jmp gmfLoop

gmfDone:
    mov cx,[bp].gmfEntries
    pop di
    pop bx
    pop eax
    add sp,12
    pop bp
    ret
GetMatchingFiles    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       GetAllFiles
;
;       DESCRIPTION:    Get all files
;
;           PARAMETERS:         CX          Attribute
;                           BX          Handle to dir
;
;           RETURNS:        ES          Entries array
;                           CX          Number of entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAllFiles Proc near
    push eax
    push bx
    push edx
    push si
    push di
;
    mov si,cx
    mov eax,10000h
    AllocateLocalMem
    xor di,di
    xor ax,ax
    xor cx,cx

gafLoop:
    push ax
    push bx
    push cx
    mov cx,14
    ReadLegacyDir
    mov dx,si
    mov dh,bl
    pop cx
    pop bx
    pop ax
    jc gafDone
;
    inc ax
    mov dl,[bp].gmfSearchAttrib
    mov dh,[bp].gmfFileAttrib
    call CheckAttrib
    jc gafLoop

gafAttribOk:
    dec ax
    stosw
    inc ax
    inc cx
    jmp gafLoop

gafDone:
    pop di
    pop si
    pop edx
    pop bx
    pop eax
    ret
GetAllFiles     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:       CreateSearchCache
;
;       DESCRIPTION:    Create a cache for search
;
;           PARAMETERS:         BX          Handle to dir
;                           ES          Entries array
;                           CX          Number of entries
;
;           RETURNS:        ES          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSearchCache Proc near
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    mov ax,es
    mov ds,ax
    movzx ecx,cx
    mov eax,SIZE dir_cache
    mul ecx
    add eax,12
    AllocateLocalMem
    xor esi,esi
    xor edi,edi
;
    stosd
    sub eax,12
    stosd
    xor eax,eax
    stosd

cscLoop:
    push bx
    push ecx
;
    push edi
    lods word ptr [esi]
    mov dx,ax
    add edi,OFFSET dc_name
    mov ecx,12
    UserGateForce32 read_legacy_dir_nr
    mov byte ptr es:[edi+12],0
    pop edi
;
    mov es:[edi].dc_size,ecx
    mov es:[edi].dc_attr,bl
    BinaryToTime
    shl cl,3
    shr cx,3
    sub dx,1980
    mov dh,dl
    shl dh,1
    xor dl,dl
    or dx,cx
    mov es:[edi].dc_date,dx
    mov al,ah
    shr al,1
    shl bl,2
    shl bx,3
    or bl,al
    mov es:[edi].dc_time,bx
;
    add edi,SIZE dir_cache
    pop ecx
    pop bx
    loop cscLoop
;
    UserGate close_legacy_dir_nr
    push es
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem
    pop es
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
CreateSearchCache Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FIND_FIRST_FILE
;
;           DESCRIPTION:    Find first file
;
;           PARAMETERS:         ES:EDI      Dta
;                           DS:ESI      File names to search for
;                           CX              Attributes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public find_first_file

find_first_file PROC near
    push eax
    push bx
    push ecx
    push edx
;
    push ds
    push es
    push esi
    push edi
    call reset_find_sel
;
    mov ax,ds
    mov es,ax
    mov edi,esi
;       UserGateForce32 open_legacy_dir_nr
;       jc fffSearch
;
;       call GetAllFiles
;       or cx,cx
;       jz fffNoMatch
;       jmp fffFirst

fffSearch:
    call OpenFileSearch
    jc fffFailed
    call GetMatchingFiles
    or cx,cx
    jz fffNoMatch
    
fffFirst:
    call CreateSearchCache
    mov bx,es
    call set_find_sel
    pop edi
    pop esi
    pop es
    pop ds
;
    push ds
    push ecx
    push esi
    push edi
;
    mov ds,bx
    mov esi,12
    add edi, OFFSET dm_attr
    mov ecx, SIZE dir_cache
    rep movs byte ptr es:[edi],ds:[esi]
    mov ds:[8],esi
;
    pop edi
    pop esi
    pop ecx
    pop ds
    clc
    jmp fffDone

fffNoMatch:
    FreeMem
    CloseLegacyDir
    pop edi
    pop esi
    pop es
    pop ds
    stc
    jmp fffDone

fffFailed:
    pop edi
    pop esi
    pop es
    pop ds
    stc

fffDone:
    pop edx
    pop ecx
    pop bx
    pop eax
    ret
find_first_file Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FIND_NEXT_FILE
;
;           DESCRIPTION:    Find next file
;
;           PARAMETERS:         ES:EDI      DTA
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_next_file  Proc near
    push ds
    push eax
    push bx
    push ecx
    push esi
    push edi
;
    call get_find_sel
    or bx,bx
    jz fnfFail
;
    mov ds,bx
    xor esi,esi
    sub dword ptr [esi+4],SIZE dir_cache
    ja fnfOk

fnfFail:
    stc
    jmp fnfDone

fnfOk:
    mov esi,[esi+8]
    mov ecx,SIZE dir_cache
    add edi,OFFSET dm_attr
    rep movsb
    mov ds:[8],esi
    clc

fnfDone:
    pop edi
    pop esi
    pop ecx
    pop bx
    pop eax
    pop ds
    ret
find_next_file  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FIND_NEXT
;
;           DESCRIPTION:    DOS function 4F
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public find_next

find_next       PROC far
    push es
    push di
    push dx
    call get_prot_dta
    mov es,dx
    mov edi,ebx
    pop dx
    call find_next_file
    pop di
    pop es
    mov bx,[bp].vm_ebx
    jnc find_next_done
    mov ax,18
    or byte ptr [bp].vm_eflags,1
    ret
find_next_done:
    mov ax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    ret
find_next       ENDP

code    ENDS

    END

