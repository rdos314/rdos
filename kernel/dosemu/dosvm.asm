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
; DOSVM.ASM
; V86 mode DOS emulation
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

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn reset_find_sel:near

    extrn ucase_tab:near
    extrn file_ucase_tab:near
    extrn collate_tab:near

    extrn default_psp:near
    extrn get_virt_psp:near
    extrn set_virt_psp:near
    extrn get_prot_psp:near
    extrn set_prot_psp:near
    extrn get_virt_dta:near
    extrn set_virt_dta:near
    extrn get_prot_dta:near
    extrn doscallback_start:near
    extrn doscallback_end:near
    extrn case_map:near
    extrn get_allocation_strat:near

    extrn get_system_date:near
    extrn set_system_date:near
    extrn get_system_time:near
    extrn set_system_time:near
    extrn strategy:near
    extrn exit_code:near
    extrn dos_version:near
    extrn control_c_check:near
    extrn switch_char:near
    extrn dos_write_char:near
    extrn dos_read_key:near
    extrn dos_read_key_echo:near
    extrn dos_con_io:near
    extrn dos_key_state:near
    extrn ioctl:near
    extrn close_handle:near
    extrn move_pointer:near
    extrn dupl_handle:near
    extrn force_dupl_handle:near
    extrn date_time_handle:near
    extrn get_drive_allocation:near
    extrn select_drive:near
    extrn get_drive:near
    extrn find_first_file:near
    extrn find_next:near


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DOS_GET_PSP
;
;           DESCRIPTION:    DOS function 51,62
;
;           PARAMETERS:         BX              PSP
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dos_get_psp     PROC far
    call get_virt_psp
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
dos_get_psp     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DOS_SET_PSP
;
;           DESCRIPTION:    DOS function 50
;
;           PARAMETERS:         BX              PSP
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dos_set_psp     PROC far
    mov bx,[bp].vm_ebx
    call set_virt_psp
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
dos_set_psp     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_DTA
;
;           DESCRIPTION:    DOS function 2F
;
;           PARAMETERS:         ES:BX           DTA
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dta PROC far
    push dx
    call get_virt_dta
    mov [bp].vm_es,dx
    pop dx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_dta ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_DTA
;
;           DESCRIPTION:    DOS function 1A
;
;           PARAMETERS:         DS:DX           DTA
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dta PROC far
    push dx
    mov bx,dx
    mov dx,[bp].vm_ds
    call set_virt_dta
    pop dx
    mov bx,[bp].vm_ebx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
set_dta ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LOAD_PROGRAM
;
;           DESCRIPTION:    DOS function 4B
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_program    PROC far
    push si
    push di
    SimSti
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov ds,bx
    mov bx,[bp].vm_es
    SegmentToSelector
    mov es,bx
    mov si,dx
    mov di,[bp].vm_ebx
    mov bx,es:[di+4]
    mov di,es:[di+2]
    FreeSelector
    SegmentToSelector
    mov es,bx
    push es
;
    push ds
    push cx
    push si
    mov ax,es
    mov ds,ax
    mov si,di
    movzx cx,byte ptr [si]
    movzx eax,cx
    inc eax
    AllocateLocalMem
    xor di,di
    inc si
    rep movsb
    xor al,al
    stosb
    xor di,di
    pop si
    pop cx
    pop ds
    LoadExe
    jc load_fail
;
    cmp ah,3
    je load_resident
;
    FreeMem
    pop es
    FreeSelector
    mov si,ds
    mov es,si
    xor si,si
    mov ds,si
    FreeSelector
    and byte ptr [bp].vm_eflags,1
    jmp load_done

load_resident:
    add sp,2
    and byte ptr [bp].vm_eflags,1
    jmp load_done

load_fail:
    FreeMem
    pop es
    FreeSelector
    mov si,ds
    mov es,si
    xor si,si
    mov ds,si
    FreeSelector
    or byte ptr [bp].vm_eflags,1

load_done:
    pop di
    pop si
    retf32
load_program    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           END_PROGRAM
;
;           DESCRIPTION:    DOS function 4C
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

end_program:
    UnloadExe


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           KEEP_PROCESS
;
;           DESCRIPTION:    DOS function 31
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

keep_process:
    push ax
    call get_virt_psp
    movzx eax,dx
    shl eax,4
    movzx edx,bx
    shl edx,4
    ResizeDosLinear
    pop ax
    jc keep_fail
;
    mov ah,3
    call reset_find_sel
    mov bx,flat_sel
    mov ds,bx
    call get_virt_psp
    movzx ebx,bx
    shl ebx,4
    mov ax,[ebx].psp_parent
    call get_prot_psp
    GetSelectorBaseSize
    movzx edx,ax
    shl edx,4
    AllocateLdt
    or bx,7
    CreateDataSelector16
    call set_prot_psp
;
    xor bx,bx
    int 3
    clc
    retf32

keep_fail:
    xor ax,ax
    UnloadExe


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_INDOS_FLAG
;
;           DESCRIPTION:    DOS function 34
;
;           PARAMETERS:         ES:BX           ADDRESS TILL INDOS FLAG
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_indos_flag  PROC far
    mov bx,gdt_sel
    mov ds,bx
    mov bx,dos_vm_sel AND 0FFF8h
    mov eax,[bx+2]
    mov bx,ax
    and bx,0Fh
    add bx,OFFSET indos_flag
    shr eax,4
    mov [bp].vm_es,ax
    mov eax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_indos_flag  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           COUNTY_DATA
;
;           DESCRIPTION:    DOS function 38
;
;           PARAMETERS:         DS:DX       BUFFER
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

country_data    PROC far
    mov ax,[bp].vm_eax
    or al,al
    jnz country_data_fail
    push bx
    push di
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    mov di,dx
    mov ax,2
    stosw
    mov ax,'rk'
    stosw
    xor ax,ax
    stosw
    stosb
    stosw
    mov al,'.'
    stosw
    mov al,'-'
    stosw
    mov al,'.'
    stosw
    mov al,3
    stosb
    mov al,2
    stosb
    mov al,1
    stosb
    mov ax,dos_vm_sel
    mov ds,ax
    mov ax,OFFSET case_map
    sub ax,OFFSET doscallback_start
    stosw
    mov ax,ds:dos_callback_seg
    stosw
    mov al,','
    stosw
    FreeSelector
    pop di
    pop bx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
country_data_fail:
    mov ax,2
    or byte ptr [bp].vm_eflags,1
    retf32
country_data    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           EXTENDED_COUNTY_DATA
;
;           DESCRIPTION:    DOS function 65
;
;           PARAMETERS:         ES:DI       BUFFER
;                           AL              SUB FUNCTION #
;                           BX              CODE PAGE (IGNORED)
;                           CX              BUFFER SIZE
;                           DX              COUNTY ID (IGNORED)                         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extended_country_data   PROC far
    mov al,[bp].vm_ebx
    cmp al,1
    je extended_country_general
    cmp al,2
    je extended_country_ucase
    cmp al,4
    je extended_country_file_ucase
    cmp al,6
    je extended_country_collate
    jmp extended_country_fail

extended_country_general:
    push bx
    push dx
    mov bx,[bp].vm_es
    SegmentToSelector
    mov es,bx
    push di
    xor dx,dx
;
    sub cx,5
    jc extended_country_general_done
    mov al,1
    stosb
    mov ax,26h
    stosw
    mov ax,2
    stosw
;
    sub cx,5
    jc short extended_country_general_done
    add dx,5
    mov ax,'rk'
    stosw
    xor ax,ax
    stosw
    stosb
;
    sub cx,2
    jc extended_country_general_done
    add dx,2
    xor ax,ax
    stosw
;
    sub cx,2
    jc extended_country_general_done
    add dx,2
    mov al,'.'
    stosw
;
    sub cx,2
    jc extended_country_general_done
    add dx,2
    mov al,'-'
    stosw
;
    sub cx,2
    jc extended_country_general_done
    add dx,2
    mov al,'.'
    stosw
;
    sub cx,1
    jc extended_country_general_done
    inc dx
    mov al,3
    stosb
;
    sub cx,1
    jc extended_country_general_done
    inc dx
    mov al,2
    stosb
;
    sub cx,1
    jc extended_country_general_done
    inc dx
    mov al,1
    stosb
;
    sub cx,4
    jc extended_country_general_done
    add dx,4
    mov ax,dos_vm_sel
    mov ds,ax
    mov ax,OFFSET case_map
    sub ax,OFFSET doscallback_start
    stosw
    mov ax,ds:dos_callback_seg
    stosw
;
    sub cx,2
    jc extended_country_general_done
    add dx,2
    xor ax,ax
    mov al,','
    stosw
;
extended_country_general_done:
    pop di
    mov es:[di+1],dx
    mov cx,dx
;
    FreeSelector
    pop dx
    pop bx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32

extended_country_ucase:
    push bx
    mov bx,[bp].vm_es
    SegmentToSelector
    mov es,bx
    push di
    mov al,2
    stosb
;
    mov ax,dos_vm_sel
    mov ds,ax
    mov ax,OFFSET ucase_tab
    sub ax,OFFSET doscallback_start
    stosw
    mov ax,ds:dos_callback_seg
    stosw
;       
    pop di
;
    FreeSelector
    pop bx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32

extended_country_file_ucase:
    push bx
    mov bx,[bp].vm_es
    SegmentToSelector
    mov es,bx
    push di
    mov al,4
    stosb
;
    mov ax,dos_vm_sel
    mov ds,ax
    mov ax,OFFSET file_ucase_tab
    sub ax,OFFSET doscallback_start
    stosw
    mov ax,ds:dos_callback_seg
    stosw
;       
    pop di
;
    FreeSelector
    pop bx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32

extended_country_collate:
    push bx
    mov bx,[bp].vm_es
    SegmentToSelector
    mov es,bx
    push di
    mov al,6
    stosb
;
    mov ax,dos_vm_sel
    mov ds,ax
    mov ax,OFFSET collate_tab
    sub ax,OFFSET doscallback_start
    stosw
    mov ax,ds:dos_callback_seg
    stosw
;       
    pop di
;
    FreeSelector
    pop bx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32

extended_country_fail:
    mov ax,2
    or byte ptr [bp].vm_eflags,1
    retf32
extended_country_data   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_MEMORY
;
;           DESCRIPTION:    DOS function 48
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_memory PROC far
    push edx
    call get_allocation_strat
    or ax,ax
    jz allocate_normal
;
    jmp allocate_normal
;
    cmp bx,40h
    jae allocate_normal
;
    movzx eax,bx
    shl eax,4
    add eax,10h
    AllocateVMLinear
    dec edx
    and dl,0F0h
    add edx,10h
    jmp allocate_mem_ok
allocate_normal:
    movzx eax,bx
    shl eax,4
    AllocateDosLinear
    jc allocate_mem_fail
allocate_mem_ok:
    shr edx,4
    mov eax,[bp].vm_eax
    mov ax,dx
    mov bx,[bp].vm_ebx
    and byte ptr [bp].vm_eflags,NOT 1
    pop edx
    retf32
allocate_mem_fail:
    push ax
    mov eax,[bp].vm_eax
    pop ax
    push eax
    AvailableDosLinear
    shr edx,4
    mov bx,dx
    pop eax 
    pop edx
    or byte ptr [bp].vm_eflags,1
    retf32
allocate_memory ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FREE_MEMORY
;
;           DESCRIPTION:    DOS function 49
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_memory     PROC far
    push ecx
    push edx
    xor edx,edx
    mov dx,[bp].vm_es
;
    call get_virt_psp
    cmp bx,dx
    je free_mem_ok
;
    shl edx,4
    mov ecx,1
    FreeLinear
    jc free_mem_fail

free_mem_ok:
    and byte ptr [bp].vm_eflags,NOT 1
    pop edx
    pop ecx
    retf32

free_mem_fail:
    pop edx
    pop ecx
    or byte ptr [bp].vm_eflags,1
    retf32
free_memory     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RESIZE_MEMORY
;
;           DESCRIPTION:    DOS function 4A
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

resize_memory   PROC far
    push ecx
    push edx
    xor eax,eax
    mov ax,[bp].vm_ebx
    shl eax,4
    xor edx,edx
    mov dx,[bp].vm_es
    shl edx,4
    mov ecx,1
    ResizeLinear
    jc resize_mem_fail
    and byte ptr [bp].vm_eflags,NOT 1
    mov eax,[bp].vm_eax
    mov ax,[bp].vm_es
    pop edx
    pop ecx
    retf32
resize_mem_fail:
    or byte ptr [bp].vm_eflags,1
    pop edx
    pop ecx
    retf32
resize_memory   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SYSVARS
;
;           DESCRIPTION:    DOS function 52
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sysvars PROC far
    mov bx,gdt_sel
    mov ds,bx
    mov bx,dos_vm_sel AND 0FFF8h
    mov eax,[bx+2]
    mov bx,ax
    and bx,0Fh
    add bx,OFFSET dos_first_dpb
    shr eax,4
    mov [bp].vm_es,ax
    mov eax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
sysvars ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DOS5D
;
;           DESCRIPTION:    DOS function 5D
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dos5d   PROC far
    cmp al,6
    je crit_flag
    or byte ptr [bp].vm_eflags,1
    retf32
crit_flag:
    mov bx,gdt_sel
    mov ds,bx
    mov bx,dos_vm_sel AND 0FFF8h
    mov eax,[bx+2]
    mov bx,ax
    and bx,0Fh
    add bx,OFFSET critical_flag
    shr eax,4
    mov [bp].vm_ds,ax
    mov si,bx
    mov bx,[bp].vm_ebx
    mov eax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
dos5d   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DOS_IO_FLUSH
;
;           DESCRIPTION:    DOS function 0C
;
;           PARAMETERS:         AL              KEY FUNCTION
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dos_io_flush    PROC far
    FlushKeyboard
    mov ax,[bp].vm_eax
    mov bl,al
    xor bh,bh
    mov byte ptr [bp].vm_eax,bh
    add bx,bx
    cmp bx,20h
    jnc dos_flush_end
    jmp word ptr cs:[bx].dos_tab
dos_flush_end:
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    retf32
dos_io_flush    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DISPLAY_STRING
;
;           DESCRIPTION:    DOS function 09
;
;           PARAMETERS:         DS:DX       $ - TERMINATED STRING
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

display_string  PROC far
    mov bx,[bp].vm_ds
    SegmentToSelector
    push di
    mov es,bx
    movzx edi,dx
    WriteDosString
    FreeSelector
    pop di
    and byte ptr [bp].vm_eflags, NOT 1
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    retf32
display_string  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           KEY_IO
;
;           DESCRIPTION:    DOS function 0A
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

key_io  PROC far
    push cx
    push di
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    mov di,dx
    movzx cx,byte ptr es:[di]
    add di,2
;    ReadCConsole
    dec ax
    dec di
    mov es:[di],al
    FreeSelector
    pop di
    pop cx
    mov ax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
key_io  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CREATE_HANDLE
;
;           DESCRIPTION:    DOS function 3C
;
;           PARAMETERS:         DS:DX           FILENAME
;                           CX                  FILE ATTRIBUTE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_handle   PROC far
    push di
    call get_prot_psp
    mov es,bx
    push cx
    mov di,es:psp_handleads
    mov cx,es:psp_handlesize
    mov al,0FFh
    repne scasb
    pop cx
    jz create_handle_found
    or byte ptr [bp].vm_eflags,1
    mov ax,4 
    jmp create_handle_done
create_handle_found:
    dec di
    push es
    push di
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    mov di,dx
    CreateFile
    pushf
    FreeSelector
    popf
    pop di
    pop es
    jnc create_handle_ok
    or byte ptr [bp].vm_eflags,1
    mov ax,2
    jmp create_handle_done
create_handle_ok:
    mov es:[di],bl
    sub di,es:psp_handleads
    mov ax,di
    and byte ptr [bp].vm_eflags,NOT 1
create_handle_done:
    mov bx,[bp].vm_ebx
    pop di
    retf32
create_handle   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DELETE_FILE
;
;           DESCRIPTION:    DOS function 41
;
;           PARAMETERS:         DS:DX           FILENAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_file     PROC far
    push di
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    mov di,dx
    DeleteFile
    pushf
    FreeSelector
    popf
    jc delete_file_fail
    and byte ptr [bp].vm_eflags,NOT 1
    jmp delete_file_done
delete_file_fail:
    or byte ptr [bp].vm_eflags,1
delete_file_done:
    pop di
    retf32
delete_file     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RENAME_FILE
;
;           DESCRIPTION:    DOS function 56
;
;           PARAMETERS:         DS:DX           OLD FILENAME
;                           ES:DI           NEW FILENAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rename_file     PROC far
    push si
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov ds,bx
    mov si,dx
    mov bx,[bp].vm_es
    SegmentToSelector
    mov es,bx
    RenameFile
    pushf
    FreeSelector
    mov si,ds
    mov es,si
    xor si,si
    mov ds,si
    FreeSelector
    popf
    jc rename_file_fail
    and byte ptr [bp].vm_eflags,NOT 1
    jmp rename_file_done
rename_file_fail:
    or byte ptr [bp].vm_eflags,1
rename_file_done:
    pop si
    retf32
rename_file     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FILE_ATTRIBUTE
;
;           DESCRIPTION:    DOS function 43
;
;           PARAMETERS:         DS:DX       PATH NAME
;                           CX              ATTRIBUTE
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

file_attribute  PROC far
    or al,al
    jz get_file_attrib
    cmp al,1
    je set_file_attrib
    mov ax,1
    or byte ptr [bp].vm_eflags,1
    retf32
get_file_attrib:
    push di
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    mov di,dx
    GetFileAttribute
    pushf
    FreeSelector
    popf
    pop di
    jnc file_attrib_ok
    mov ax,3
    mov bx,[bp].vm_ebx
    or byte ptr [bp].vm_eflags,1
    retf32
set_file_attrib:
    push di
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    mov di,dx
    SetFileAttribute
    pushf
    FreeSelector
    popf
    pop di
    jnc file_attrib_ok
    mov ax,1
    or byte ptr [bp].vm_eflags,1
    retf32
file_attrib_ok:
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
file_attribute  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           OPEN_HANDLE
;
;           DESCRIPTION:    DOS function 3D
;
;           PARAMETERS:         DS:DX           FILENAME
;                           AL                  ACCESS CODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_handle     PROC far
    push cx
    push di
    call get_prot_psp
    mov es,bx
    mov di,es:psp_handleads
    mov cx,es:psp_handlesize
    mov al,0FFh
    repne scasb
    jz open_handle_found
    or byte ptr [bp].vm_eflags,1
    mov ax,4 
    jmp open_handle_done
open_handle_found:
    dec di
    push es
    push di
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    mov di,dx
    mov cl,[bp].vm_eax
    OpenFile
    pushf
    FreeSelector
    popf
    pop di
    pop es
    jnc open_handle_ok
    or byte ptr [bp].vm_eflags,1
    mov ax,2
    jmp open_handle_done
open_handle_ok:
    mov es:[di],bl
    sub di,es:psp_handleads
    mov ax,di
    and byte ptr [bp].vm_eflags,NOT 1
open_handle_done:
    mov bx,[bp].vm_eflags
    pop di
    pop cx
    retf32
open_handle     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           READ_HANLE
;
;           DESCRIPTION:    DOS function 3F
;
;           PARAMETERS:         DS:DX           BUFFER
;                           BX                  FILE HANDLE
;                           CX                  BYTES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_handle     PROC far
    call get_prot_psp
    mov es,bx
    mov ax,[bp].vm_ebx
    cmp ax,es:psp_handlesize
    jc read_handle_inrange
    mov ax,6
    or byte ptr [bp].vm_eflags, 1
    jmp read_handle_done
read_handle_inrange:
    mov bx,es:psp_handleads
    add bx,ax
    movzx bx,byte ptr es:[bx]
    cmp bx,0FFh
    jne read_handle_read
    mov ax,6
    or byte ptr [bp].vm_eflags, 1
    jmp read_handle_done
read_handle_read:
    push es
    push di
    push bx
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    pop bx
    mov di,dx
    ReadFile
    pushf
    FreeSelector
    popf
    pop di
    pop es
    jnc read_handle_ok
    mov ax,5
    or byte ptr [bp].vm_eflags, 1
    jmp read_handle_done
read_handle_ok:
    and byte ptr [bp].vm_eflags,NOT 1
read_handle_done:
    mov ebx,[bp].vm_ebx
    retf32
read_handle     ENDP    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WRITE_HANLE
;
;           DESCRIPTION:    DOS function 40
;
;           PARAMETERS:         DS:DX           Buffer
;                           BX                  FILE HANDLE
;                           CX                  Bytes
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_handle    PROC far
    call get_prot_psp
    mov es,bx
    mov ax,[bp].vm_ebx
    cmp ax,es:psp_handlesize
    jc write_handle_inrange
    mov ax,6
    or byte ptr [bp].vm_eflags, 1
    jmp write_handle_done
write_handle_inrange:
    mov bx,es:psp_handleads
    add bx,ax
    movzx bx,byte ptr es:[bx]
    cmp bx,0FFh
    jne write_handle_write
    mov ax,6
    or byte ptr [bp].vm_eflags, 1
    jmp write_handle_done
write_handle_write:
    cmp bx,4
    jc write_handle_nobreak
write_handle_nobreak:
    or cx,cx
    jz set_file_size
    push es
    push di
    push bx
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    pop bx
    mov di,dx
    WriteFile
    pushf
    FreeSelector
    popf
    pop di
    pop es
    jnc write_handle_ok
    mov ax,5
    or byte ptr [bp].vm_eflags, 1
    jmp write_handle_done
set_file_size:
    GetFilePos32
    SetFileSize32
    mov eax,[bp].vm_eax
    xor ax,ax
write_handle_ok:
    and byte ptr [bp].vm_eflags,NOT 1
write_handle_done:
    mov ebx,[bp].vm_ebx
    retf32
write_handle    ENDP    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_CUR_DIR
;
;           DESCRIPTION:    DOS function 3B
;
;           PARAMETERS:         DS:DX       PATH NAME
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cur_dir     PROC far
    push di
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    mov di,dx
    SetCurDir
    pushf
    FreeSelector
    popf
    pop di
    jnc setup_cur_do
    mov ax,3
    mov bx,[bp].vm_ebx
    or byte ptr [bp].vm_eflags,1
    retf32
setup_cur_do:
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    retf32
set_cur_dir     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_CUR_DIR
;
;           DESCRIPTION:    DOS function 47
;
;           PARAMETERS:         DS:DX       PATH NAME
;                           DL              DRIVE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cur_dir     PROC far
    push di
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    mov di,si
    mov al,dl
    sub al,1
    jnc get_cur_not_default
    GetCurDrive
get_cur_not_default:
    GetCurDir
    pushf
    FreeSelector
    popf
    pop di
    mov bx,[bp].vm_ebx
    jc get_cur_dir_fail
    mov ax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_cur_dir_fail:
    mov ax,15
    or byte ptr [bp].vm_eflags,1
    retf32
get_cur_dir     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MAKE_DIR
;
;           DESCRIPTION:    DOS function 39
;
;           PARAMETERS:         DS:DX       PATH NAME
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

make_dir    PROC far
    push di
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    mov di,dx
    MakeDir
    pushf
    FreeSelector
    popf
    pop di
    jnc make_dir_done
    mov ax,3
    mov bx,[bp].vm_ebx
    or byte ptr [bp].vm_eflags,1
    retf32
make_dir_done:
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
make_dir    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           REMOVE_DIR
;
;           DESCRIPTION:    DOS function 3A
;
;           PARAMETERS:         DS:DX       PATH NAME
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_dir      PROC far
    push di
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov es,bx
    mov di,dx
    RemoveDir
    pushf
    FreeSelector
    popf
    pop di
    jnc remove_dir_done
    mov ax,3
    mov bx,[bp].vm_ebx
    or byte ptr [bp].vm_eflags,1
    retf32
remove_dir_done:
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
remove_dir      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FIND_FIRST
;
;           DESCRIPTION:    DOS function 4E
;
;           PARAMETERS:         DS:DX       PATHNAME
;                           CX              ATTRIBUTE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_first      PROC far
    push esi
    push edi
    push dx
    call get_prot_dta
    mov es,dx
    mov edi,ebx
    pop dx
    mov bx,[bp].vm_ds
    SegmentToSelector
    mov ds,bx
    movzx esi,dx
    call find_first_file
    pushf
    mov si,ds
    mov es,si
    xor si,si
    mov ds,si
    FreeSelector
    popf
    pop edi
    pop esi
    mov bx,[bp].vm_ebx
    jnc find_first_done
    mov ax,18
    or byte ptr [bp].vm_eflags,1
    retf32
find_first_done:
    mov ax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
find_first      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CREATE_PSP
;
;           DESCRIPTION:    DOS function 26H
;
;           PARAMETERS:         DX          SEGMENT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_psp      PROC far
    GetPspSel
    mov es,bx
    mov ax,es:psp_enviro
    mov bx,dx
    SegmentToSelector
    mov es,bx
    call default_psp
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    FreeSelector
    and byte ptr [bp].vm_eflags, NOT 1
    retf32
create_psp      ENDP

error_dos       PROC far
    or byte ptr [bp].vm_eflags,1
    retf32
error_dos       ENDP

get_dos_int     PROC far
    cmp al,2Eh
    jne get_dos_int_default
;
    GetPsp
    mov [bp].vm_es,bx
    xor bx,bx
    jmp get_dos_int_done
    
get_dos_int_default:
    push dx
    GetVMInt
    mov [bp].vm_es,dx
    pop dx

get_dos_int_done:
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_dos_int     ENDP
    
set_dos_int     PROC far
    push bx
    push dx
    mov bx,dx
    mov dx,[bp].vm_ds
    SetVMInt
    pop dx
    pop bx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
set_dos_int     ENDP

    public dos_tab

dos_tab:
do00    DW OFFSET error_dos
do01    DW OFFSET dos_read_key_echo
do02    DW OFFSET dos_write_char
do03    DW OFFSET error_dos
do04    DW OFFSET error_dos
do05    DW OFFSET error_dos
do06    DW OFFSET dos_con_io
do07    DW OFFSET dos_read_key
do08    DW OFFSET dos_read_key
do09    DW OFFSET display_string
do0A    DW OFFSET key_io
do0B    DW OFFSET dos_key_state
do0C    DW OFFSET dos_io_flush
do0D    DW OFFSET error_dos
do0E    DW OFFSET select_drive
do0F    DW OFFSET error_dos
do10    DW OFFSET error_dos
do11    DW OFFSET error_dos
do12    DW OFFSET error_dos
do13    DW OFFSET error_dos
do14    DW OFFSET error_dos
do15    DW OFFSET error_dos
do16    DW OFFSET error_dos
do17    DW OFFSET error_dos
do18    DW OFFSET error_dos
do19    DW OFFSET get_drive
do1A    DW OFFSET set_dta
do1B    DW OFFSET error_dos
do1C    DW OFFSET error_dos
do1D    DW OFFSET error_dos
do1E    DW OFFSET error_dos
do1F    DW OFFSET error_dos
do20    DW OFFSET error_dos
do21    DW OFFSET error_dos
do22    DW OFFSET error_dos
do23    DW OFFSET error_dos
do24    DW OFFSET error_dos
do25    DW OFFSET set_dos_int
do26    DW OFFSET create_psp
do27    DW OFFSET error_dos
do28    DW OFFSET error_dos
do29    DW OFFSET error_dos
do2A    DW OFFSET get_system_date
do2B    DW OFFSET set_system_date
do2C    DW OFFSET get_system_time
do2D    DW OFFSET set_system_time
do2E    DW OFFSET error_dos
do2F    DW OFFSET get_dta
do30    DW OFFSET dos_version
do31    DW OFFSET keep_process
do32    DW OFFSET error_dos
do33    DW OFFSET control_c_check
do34    DW OFFSET get_indos_flag
do35    DW OFFSET get_dos_int
do36    DW OFFSET get_drive_allocation
do37    DW OFFSET switch_char
do38    DW OFFSET country_data
do39    DW OFFSET make_dir
do3A    DW OFFSET remove_dir
do3B    DW OFFSET set_cur_dir
do3C    DW OFFSET create_handle
do3D    DW OFFSET open_handle
do3E    DW OFFSET close_handle
do3F    DW OFFSET read_handle
do40    DW OFFSET write_handle
do41    DW OFFSET delete_file
do42    DW OFFSET move_pointer
do43    DW OFFSET file_attribute
do44    DW OFFSET ioctl
do45    DW OFFSET dupl_handle
do46    DW OFFSET force_dupl_handle
do47    DW OFFSET get_cur_dir
do48    DW OFFSET allocate_memory
do49    DW OFFSET free_memory
do4A    DW OFFSET resize_memory
do4B    DW OFFSET load_program
do4C    DW OFFSET end_program
do4D    DW OFFSET exit_code
do4E    DW OFFSET find_first
do4F    DW OFFSET find_next
do50    DW OFFSET dos_set_psp
do51    DW OFFSET dos_get_psp
do52    DW OFFSET sysvars
do53    DW OFFSET error_dos
do54    DW OFFSET error_dos
do55    DW OFFSET create_psp
do56    DW OFFSET rename_file
do57    DW OFFSET date_time_handle
do58    DW OFFSET strategy
do59    DW OFFSET error_dos
do5A    DW OFFSET error_dos
do5B    DW OFFSET error_dos
do5C    DW OFFSET error_dos
do5D    DW OFFSET dos5d
do5E    DW OFFSET error_dos
do5F    DW OFFSET error_dos
do60    DW OFFSET error_dos
do61    DW OFFSET error_dos
do62    DW OFFSET dos_get_psp
do63    DW OFFSET error_dos
do64    DW OFFSET error_dos
do65    DW OFFSET extended_country_data
do66    DW OFFSET error_dos
do67    DW OFFSET error_dos
do68    DW OFFSET error_dos
do69    DW OFFSET error_dos
do6A    DW OFFSET error_dos
do6B    DW OFFSET error_dos
do6C    DW OFFSET error_dos
do6D    DW OFFSET error_dos
do6E    DW OFFSET error_dos
do6F    DW OFFSET error_dos
doend   DW OFFSET error_dos

int21:
    SimSti
    mov bl,ah
    xor bh,bh
    add bx,bx
    cmp bx,0E0h
    jc dos_call_do
    mov bx,0E0h
dos_call_do:
    push word ptr cs:[bx].dos_tab
    mov bx,[bp].vm_ebx
    retn


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INT12
;
;           DESCRIPTION:    INT 12
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int12   Proc far
    SimSti
    mov ax,280h
    retf32
int12   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INT22
;
;           DESCRIPTION:    INT 22
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int22:
    UnloadExe


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_dosvm
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_dosvm

init_dosvm      PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov al,12h
    mov edi,OFFSET int12
    HookVMInt
;
    mov al,21h
    mov edi,OFFSET int21
    HookVMInt
;
    mov al,22h
    mov edi,OFFSET int22
    HookVMInt
;
    ret
init_dosvm      ENDP

code    ENDS

    END

