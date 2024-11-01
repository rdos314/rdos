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
; DOS32.ASM
; 32-bit protected mode DOS emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\int.def
INCLUDE ..\os\system.def
INCLUDE dos.inc

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn get_virt_psp:near
    extrn set_virt_psp:near
    extrn get_prot_psp:near
    extrn set_prot_psp:near
    extrn get_prot_dta:near
    extrn set_prot_dta:near

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
    extrn get_drive_allocation:near
    extrn select_drive:near
    extrn get_drive:near
    extrn find_first_file:near
    extrn find_next:near
    extrn date_time_handle:near


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
    push es
    push edi
    mov es,[bp].pm_ds
    mov edi,edx
    movzx cx,byte ptr es:[edi]
    add edi,2
;    ReadCConsole
    dec ax
    dec edi
    mov es:[edi],al
    pop edi
    pop es
    pop cx
    mov ax,[bp].vm_eax
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
key_io  ENDP


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
;           DESCRIPTION:    DOS function 9
;
;           PARAMETERS:         DS:EDX      $ - TERMINATED STRING
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

display_string  PROC far
    push es
    push edi
    mov es,[bp].pm_ds
    mov edi,edx
    WriteDosString
    pop edi
    pop es
    and byte ptr [bp].vm_eflags, NOT 1
    retf32
display_string  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_DTA
;
;           DESCRIPTION:    DOS function 1A
;
;           PARAMETERS:         DS:EDX          DTA
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dta PROC far
    push ebx
    push dx
    mov ebx,edx
    mov dx,ds
    call set_prot_dta
    pop dx
    pop ebx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
set_dta ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_INT
;
;           DESCRIPTION:    DOS function 25
;
;           PARAMETERS:         DS:EDX      ADDRESS
;                           AL              VECTOR NR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
set_int PROC far
    push es
    push edi
    mov di,ds
    mov es,di
    mov edi,edx
    UserGateForce32 set_pm_int_nr
    pop edi
    pop es
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
set_int ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_DTA
;
;           DESCRIPTION:    DOS function 2F
;
;           PARAMETERS:         ES:EBX          DTA
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dta PROC far
    push dx
    call get_prot_dta
    mov es,dx
    pop dx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_dta ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_INDOS_FLAG
;
;           DESCRIPTION:    DOS function 34
;
;           PARAMETERS:         ES:EBX          Address to indos flag
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_indos_flag  PROC far
    mov bx,dos_vm_sel
    mov es,bx
    mov ebx,OFFSET indos_flag
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_indos_flag  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_INT
;
;           DESCRIPTION:    DOS function 35
;
;           PARAMETERS:         ES:EBX      ADDRESS
;                           AL              VECTOR NR
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_int PROC far
    push edi
    UserGateForce32 get_pm_int_nr
    mov ebx,edi
    pop edi
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_int ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MAKE_DIR
;
;           DESCRIPTION:    DOS function 39
;
;           PARAMETERS:         DS:EDX      PATH NAME
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

make_dir    PROC far
    push edi
    push es
    mov es,[bp].pm_ds
    mov edi,edx
    UserGateForce32 make_dir_nr
    pop es
    pop edi
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
;           PARAMETERS:         DS:EDX      PATH NAME
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_dir      PROC far
    push edi
    push es
    mov es,[bp].pm_ds
    mov edi,edx
    UserGateForce32 remove_dir_nr
    pop edi
    pop es
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
;           NAME:           SET_CUR_DIR
;
;           DESCRIPTION:    DOS function 3B
;
;           PARAMETERS:         DS:EDX      PATH NAME
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cur_dir     PROC far
    push edi
    push es
    mov es,[bp].pm_ds
    mov edi,edx
    UserGateForce32 set_cur_dir_nr
    pop es
    pop edi
    jnc setup_cur_do
    mov ax,3
    mov bx,[bp].vm_ebx
    or byte ptr [bp].vm_eflags,1
    retf32
setup_cur_do:
    mov ax,[bp].vm_eax
    mov bx,[bp].vm_ebx
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
set_cur_dir     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CREATE_HANDLE
;
;           DESCRIPTION:    DOS function 3C
;
;           PARAMETERS:         DS:EDX          FILENAME
;                           CX                  FILE ATTRIBUTE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_handle   PROC far
    push es
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
    push edi
    mov es,[bp].pm_ds
    mov edi,edx
    UserGateForce32 create_file_nr
    pop edi
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
    pop es
    retf32
create_handle   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           OPEN_HANDLE
;
;           DESCRIPTION:    DOS function 3D
;
;           PARAMETERS:         DS:EDX          FILENAME
;                           AL                  ACCESS CODE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_handle     PROC far
    push es
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
    push edi
    mov bx,ds
    mov es,bx
    mov edi,edx
    mov cl,[bp].vm_eax
    UserGateForce32 open_file_nr
    pop edi
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
    pop es
    retf32
open_handle     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           READ_HANLE
;
;           DESCRIPTION:    DOS function 3F
;
;           PARAMETERS:         DS:EDX          BUFFER
;                           BX                  FILE HANDLE
;                           ECX                 BYTES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_handle     PROC far
    push es
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
    push edi
    push bx
    mov bx,ds
    mov es,bx
    pop bx
    mov edi,edx
    UserGateForce32 read_file_nr
    pop edi
    jnc read_handle_ok
    mov ax,5
    or byte ptr [bp].vm_eflags, 1
    jmp read_handle_done
read_handle_ok:
    and byte ptr [bp].vm_eflags,NOT 1
read_handle_done:
    mov ebx,[bp].vm_ebx
    pop es
    retf32
read_handle     ENDP    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WRITE_HANLE
;
;           DESCRIPTION:    DOS function 40
;
;           PARAMETERS:         DS:EDX          BUFFER
;                           BX                  FILE HANDLE
;                           ECX                 BYTES
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_handle    PROC far
    push es
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
    or cx,cx
    jz set_file_size
    push edi
    mov di,ds
    mov es,di
    mov edi,edx
    UserGateForce32 write_file_nr
    pop edi
    jnc write_handle_ok
    mov ax,5
    or byte ptr [bp].vm_eflags, 1
    jmp write_handle_done
set_file_size:
    int 3
    GetFilePos32
    SetFileSize32
    mov eax,[bp].vm_eax
write_handle_ok:
    and byte ptr [bp].vm_eflags,NOT 1
write_handle_done:
    mov ebx,[bp].vm_ebx
    pop es
    retf32
write_handle    ENDP    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DELETE_FILE
;
;           DESCRIPTION:    DOS function 41
;
;           PARAMETERS:         DS:EDX          FILENAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_file     PROC far
    push es
    push edi
    mov es,[bp].pm_ds
    mov edi,edx
    UserGateForce32 delete_file_nr
    pop edi
    pop es
    jc delete_file_fail
    and byte ptr [bp].vm_eflags,NOT 1
    jmp delete_file_done
delete_file_fail:
    or byte ptr [bp].vm_eflags,1
delete_file_done:
    retf32
delete_file     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FILE_ATTRIBUTE
;
;           DESCRIPTION:    DOS function 43
;
;           PARAMETERS:         DS:EDX      PATH NAME
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
    push es
    push edi
    mov bx,ds
    mov es,bx
    mov edi,edx
    UserGateForce32 get_file_attribute_nr
    pop edi
    pop es
    jnc file_attrib_ok
    mov ax,2
    mov bx,[bp].vm_ebx
    or byte ptr [bp].vm_eflags,1
    retf32
set_file_attrib:
    int 3
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
;           NAME:           GET_CUR_DIR
;
;           DESCRIPTION:    DOS function 47
;
;           PARAMETERS:         DS:ESI      PATH NAME
;                           DL              DRIVE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cur_dir     PROC far
    push edi
    push es
    mov es,[bp].pm_ds
    mov edi,esi
    mov al,dl
    sub al,1
    jnc get_cur_not_default
    UserGateForce32 get_cur_drive_nr
get_cur_not_default:
    UserGateForce32 get_cur_dir_nr
    pop es
    pop edi
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
;           NAME:           ALLOCATE_MEM
;
;           DESCRIPTION:    DOS function 48
;
;           PARAMETERS:         BX              NUMBER OF PARAGRAPH
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_mem    PROC far
    push es
    movzx eax,bx
    shl eax,4
    AllocateLocalMem
    mov ax,es
    pop es
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
allocate_mem    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FREE_MEM
;
;           DESCRIPTION:    DOS function 49
;
;           PARAMETERS:         
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_mem    PROC far
    FreeMem
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
free_mem    ENDP


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
    push esi
    push edi
    SimSti
    mov esi,edx
    mov edi,[bp].vm_ebx
    UserGateForce32 load_exe_nr
    jc load_fail
    and byte ptr [bp].vm_eflags,1
    jmp load_done
load_fail:
    or byte ptr [bp].vm_eflags,1
load_done:
    pop edi
    pop esi
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
;           NAME:           FIND_FIRST
;
;           DESCRIPTION:    DOS function 4E
;
;           PARAMETERS:         DS:EDX      PATHNAME
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
    mov ds,[bp].pm_ds
    mov esi,edx
    call find_first_file
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
;           NAME:           RENAME_FILE
;
;           DESCRIPTION:    DOS function 56
;
;           PARAMETERS:         DS:EDX          OLD FILENAME
;                           ES:EDI          NEW FILENAME
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rename_file     PROC far
    push esi
    mov ds,[bp].pm_ds
    mov esi,edx
    UserGateForce32 rename_file_nr
    jc rename_file_fail
    and byte ptr [bp].vm_eflags,NOT 1
    jmp rename_file_done
rename_file_fail:
    or byte ptr [bp].vm_eflags,1
rename_file_done:
    pop esi
    retf32
rename_file     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GET_PSP
;
;           DESCRIPTION:    DOS function 51,62
;
;           PARAMETERS:         BX              PSP
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_psp PROC far
    call get_prot_psp
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
get_psp ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SET_PSP
;
;           DESCRIPTION:    DOS function 50
;
;           PARAMETERS:         BX              PSP
;                           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_psp PROC far
    call set_prot_psp
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
set_psp ENDP


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
    je crit
crit:
    mov si,dos_vm_sel
    mov ds,si
    mov esi,OFFSET critical_flag
    and byte ptr [bp].vm_eflags,NOT 1
    retf32
dos5d   ENDP



error_dos       PROC far
    int 3
    mov bx,[bp].vm_ebx
    or byte ptr [bp].vm_eflags,1
    retf32
error_dos       ENDP

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
do25    DW OFFSET set_int
do26    DW OFFSET error_dos
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
do31    DW OFFSET error_dos
do32    DW OFFSET error_dos
do33    DW OFFSET control_c_check
do34    DW OFFSET get_indos_flag
do35    DW OFFSET get_int
do36    DW OFFSET get_drive_allocation
do37    DW OFFSET switch_char
do38    DW OFFSET error_dos
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
do48    DW OFFSET allocate_mem
do49    DW OFFSET free_mem
do4A    DW OFFSET error_dos
do4B    DW OFFSET load_program
do4C    DW OFFSET end_program
do4D    DW OFFSET exit_code
do4E    DW OFFSET find_first
do4F    DW OFFSET find_next
do50    DW OFFSET set_psp
do51    DW OFFSET get_psp
do52    DW OFFSET error_dos
do53    DW OFFSET error_dos
do54    DW OFFSET error_dos
do55    DW OFFSET error_dos
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
do62    DW OFFSET get_psp
do63    DW OFFSET error_dos
do64    DW OFFSET error_dos
do65    DW OFFSET error_dos
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
    mov bl,ah
    xor bh,bh
    add bx,bx
    cmp bx,0E0h
    jc dos_call_do
    mov bx,0E0h
dos_call_do:
    push word ptr cs:[bx].dos_tab
    mov bx,[bp].vm_ebx
    mov ds,[bp].pm_ds
    retn


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ENTER_DOS32
;
;           DESCRIPTION:    Enter 32-bit DOS
;
;           PARAMETERS:         ES          PSP SEGMENT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_dos32_name    DB 'Enter Dos32',0

enter_dos32     PROC far
    push ds
    push es
    push ax
    push bx
    push edx
    push si
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    call get_prot_psp
    or bx,bx
    jnz enter_psp_ok
    call get_virt_psp
    call set_virt_psp
    call get_prot_psp
enter_psp_ok:
    mov es,bx
    movzx edx,word ptr es:psp_enviro
    shl edx,4
    AllocateLdt
    mov word ptr [bx],0FFFFh
    mov [bx+2],edx
    mov byte ptr [bx+5],0F2h
    mov word ptr [bx+6],40h
    or bx,7
    mov es:psp_enviro,bx
    pop si
    pop edx
    pop bx
    pop ax
    pop es
    pop ds
    retf32
enter_dos32     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_DOS32
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_dos32

init_dos32      PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov al,21h
    mov edi,OFFSET int21
    HookProt32Int
;
    mov esi,OFFSET enter_dos32
    mov edi,OFFSET enter_dos32_name
    xor cl,cl
    mov ax,enter_dos32_nr
    RegisterOsGate
    ret
init_dos32      ENDP

code    ENDS

    END

