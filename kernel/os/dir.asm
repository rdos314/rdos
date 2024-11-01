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
; DIR.ASM
; Dir module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE protseg.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.inc
INCLUDE blk.inc
INCLUDE ..\hint.inc
INCLUDE ..\fs.inc
INCLUDE ..\handle.inc
INCLUDE ..\apicheck.inc
INCLUDE gate.def
INCLUDE exec.def

dir_handle_seg  STRUC

dir_handle_base handle_header <>

dir_handle_sel  DW ?

dir_handle_seg  ENDS

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

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn RequestFileSel:near
    extrn ReleaseFileSel:near
    extrn CreateHandleObj:far

char_tab:
ct00 DB 0,          0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct08 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct10 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct18 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct20 DB ' ',    '!',    0FFh,   '#',    '$',    '%',    '&',    27h
ct28 DB '(',    ')',    0FFh,   0FFh,   0FFh,   '-',    '.',    0
ct30 DB '0',    '1',    '2',    '3',    '4',    '5',    '6',    '7'
ct38 DB '8',    '9',    0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ct40 DB '@',    'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct48 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct50 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct58 DB 'X',    'Y',    'Z',    0FFh,   0,          0FFh,   '^',    '_'
ct60 DB 60h,    'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct68 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct70 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct78 DB 'X',    'Y',    'Z',    '{',    0FFh,   '}',    7Eh,    0FFh
ct80 DB 0FFh,   0FFh,   0FFh,   0FFh,   8Eh,    0FFh,   8Fh,    0FFh
ct88 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   8Eh,    8Fh
ct90 DB 0FFh,   0FFh,   0FFh,   0FFh,   99h,    0FFh,   0FFh,   0FFh
ct98 DB 0FFh,   99h,    0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctA0 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
ctA8 DB 0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh,   0FFh
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CacheDirEntry
;
;           DESCRIPTION:    Cache dir entry structure
;
;           PARAMETERS:         BX              Dir selector
;                           EDX             Dir entry
;
;           RETURNS:        BX              Cached dir selector
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cache_dir_name DB 'Cache Dir', 0

cache_dir       PROC far
    push ds
    push es
    push fs
    push ax
    push si
    push ebp
;
    mov ds,bx
    mov ax,flat_sel
    mov es,ax
;
    mov bx,es:[edx].de_sel
    or bx,bx
    jnz cache_dir_done
;
    mov al,ds:ds_drive
    mov bx,ds
;
    mov si,fs_sys_data_sel
    mov ds,si
    movzx si,al
    add si,si
    mov si,ds:[si]
    mov ds,si
    mov ebp,ds:fs_mount_id
;
    call CreateDirSel
    CallFileSystem fs_cache_dir_proc
    mov es:[edx].de_sel,bx

cache_dir_done:
    pop ebp
    pop si
    pop ax
    pop fs
    pop es
    pop ds
    retf32
cache_dir       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InsertDirEntry
;
;           DESCRIPTION:    Insert dir entry structure
;
;           PARAMETERS:         BX              Dir selector
;                           EDX             Dir entry
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_dir_entry_name DB 'Insert Dir Entry', 0

insert_dir_entry    PROC far
    push ds
    push es
    push eax
    push ebx
;
    mov ds,bx
    mov ax,flat_sel
    mov es,ax
;
    mov es:[edx].de_sel,0
;
    mov eax,ds:ds_dir_ptr
    or eax,eax
    jne insert_dir_used

insert_dir_empty:
    mov es:[edx].de_prev,edx
    mov es:[edx].de_next,edx
    mov ds:ds_dir_ptr,edx
    jmp insert_dir_done

insert_dir_used:
    mov ebx,es:[eax].de_prev
    mov es:[eax].de_prev,edx
    mov es:[ebx].de_next,edx
    mov es:[edx].de_prev,ebx
    mov es:[edx].de_next,eax    

insert_dir_done:
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
insert_dir_entry    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InsertFileEntry
;
;           DESCRIPTION:    Insert file entry structure
;
;           PARAMETERS:         BX              Dir selector
;                           EDX             File entry
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

insert_file_entry_name DB 'Insert File Entry', 0

insert_file_entry       PROC far
    push ds
    push es
    push eax
    push ebx
;
    mov ds,bx
    mov ax,flat_sel
    mov es,ax
;
    mov eax,ds:ds_file_ptr
    or eax,eax
    jne insert_file_used

insert_file_empty:
    mov es:[edx].de_prev,edx
    mov es:[edx].de_next,edx
    mov ds:ds_file_ptr,edx
    jmp insert_file_done

insert_file_used:
    mov ebx,es:[eax].de_prev
    mov es:[eax].de_prev,edx
    mov es:[ebx].de_next,edx
    mov es:[edx].de_prev,ebx
    mov es:[edx].de_next,eax    

insert_file_done:
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
insert_file_entry       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateDirSel
;
;           DESCRIPTION:    Create a dir selector
;
;           PARAMETERS:         AL              Drive
;                           BX              Parent dir selector
;                           EDX             Parent dir entry
;                           EBP             Mount id
;
;           RETURNS:        BX              Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDirSel    PROC near
    push ds
;
    push bx
    CallFileSystem fs_allocate_dir_sel_proc
    mov ds,bx
    pop bx
;
    InitReadWriteSection ds:ds_access_section
    InitSection ds:ds_list_section
    mov ds:ds_dir_ptr,0
    mov ds:ds_file_ptr,0
    mov ds:ds_usage,0
    mov ds:ds_drive,al
    mov ds:ds_parent,bx
    mov ds:ds_handle,edx
    mov ds:ds_mount_id,ebp
    mov bx,ds
;
    pop ds
    ret
CreateDirSel    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeDirSel
;
;           DESCRIPTION:    Free dir selector
;
;           PARAMETERS:         DS              Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDirSel      PROC near
    push eax
    push bx
    push ecx
    push edx
;
    mov ax,flat_sel
    mov es,ax
;
    mov edx,ds:ds_dir_ptr
    or edx,edx
    jz free_dir_file

free_dir_dir_loop:
    mov eax,es:[edx].de_next
    mov cx,es:[edx].de_usage
    or cx,cx
    jnz free_dir_dir_next
;
    xor ecx,ecx
    FreeLinear

free_dir_dir_next:
    mov edx,eax
    cmp edx,ds:ds_dir_ptr
    jne free_dir_dir_loop

free_dir_file:
    mov edx,ds:ds_file_ptr
    or edx,edx
    jz free_dir_del

free_dir_file_loop:
    mov eax,es:[edx].de_next
    mov cx,es:[edx].de_usage
    or cx,cx
    jnz free_dir_file_next
;
    xor ecx,ecx
    FreeLinear

free_dir_file_next:
    mov edx,eax
    cmp edx,ds:ds_file_ptr
    jne free_dir_file_loop

free_dir_del:
    mov al,ds:ds_drive
    mov bx,ds
    xor dx,dx
    mov ds,dx
    CallFileSystem fs_free_dir_sel_proc
;
    pop edx
    pop ecx
    pop bx
    pop eax
    ret
FreeDirSel      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeDir
;
;           DESCRIPTION:    Free dir if idle
;
;           PARAMETERS:         BX              Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDir PROC near
    push ds
    push ax
;
    mov ds,bx
    mov ax,ds:ds_usage
    or ax,ax
    stc
    jnz free_dir_done
;
    call FreeDirSel
    clc

free_dir_done:
    pop ax
    pop ds
    ret
FreeDir Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateDirHandle
;
;           DESCRIPTION:    Create dir handle
;
;           PARAMETERS:         BX          Dir search selector
;
;           RETURNS:        BX          Dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDirHandle Proc near
    push ds
    push cx
    push si
;
    mov si,bx
    mov cx,SIZE dir_handle_seg
    AllocateHandle
    mov [ebx].dir_handle_sel,si
    mov [ebx].hh_sign,DIR_HANDLE
    mov bx,[ebx].hh_handle
;
    pop si
    pop cx
    pop ds
    ret
CreateDirHandle Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ParseDir
;
;           DESCRIPTION:    Parse pathname
;
;           PARAMETERS:         ES:EDI  Pathname
;
;           RETURNS:        DS          Dir selector
;                           ES:EDI  Remaining part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseDir    Proc near
    push fs
    push ax
    push bx
    push cx
    push edx
    push esi
    push ebp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_cur_dir_sel
    mov al,ds:pc_drive
    mov bx,es:[edi]
    or bl,bl
    je parse_drive_done
;
    cmp bh,':'
    jne parse_drive_done
;
    sub bl,'A'
    jc parse_dir_fail
;
    cmp bl,26
    jc parse_drive_ok
;
    sub bl,20h
    jc parse_dir_fail
;
    cmp bl,26
    jnc parse_dir_fail

parse_drive_ok:
    mov al,bl
    CheckDrive
    jc parse_dir_fail
;
    add edi,2

parse_drive_done:
    mov ah,es:[edi]
    cmp ah,'\'
    je parse_dir_abs
;
    cmp ah,'/'
    jne parse_dir_rel

parse_dir_abs:
    inc edi
    jmp parse_dir_root

parse_dir_rel:
    movzx si,al
    add si,si
    mov bx,ds:[si].pc_dir_sel_arr
    or bx,bx
    jz parse_dir_root
;
    mov ds,bx
    mov ebp,ds:ds_mount_id
    mov si,fs_sys_data_sel
    mov ds,si
    movzx si,al
    add si,si
    mov ds,ds:[si]
    cmp ebp,ds:fs_mount_id
    jne parse_dir_root
;
    EnterReadSection ds:fs_access_section
    jmp parse_dir_start

parse_dir_old:
    int 3
    mov ds,bx
    sub ds:ds_usage,1
    jnz parse_dir_old_zero
;
    call FreeDir

parse_dir_old_zero:
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_cur_dir_sel
    pop ax
    movzx si,al
    add si,si
    mov ds:[si].pc_dir_sel_arr,0

parse_dir_root:
    mov bx,fs_sys_data_sel
    mov ds,bx
    movzx si,al
    add si,si
    mov bx,ds:[si]
    or bx,bx
    jz parse_dir_fail
;
    mov ds,bx
    EnterSection ds:fs_list_section
    mov ebp,ds:fs_mount_id
    mov bx,ds:fs_root_dir_sel
    or bx,bx
    jnz parse_dir_buffered
;
    xor edx,edx
    call CreateDirSel
    CallFileSystem fs_cache_dir_proc
    mov ds:fs_root_dir_sel,bx
;
    push ds
    push ax
    mov ds,bx
    inc ds:ds_usage
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_cur_dir_sel
    mov ds:[si].pc_dir_sel_arr,bx
    pop ax
    pop ds

parse_dir_buffered:
    EnterReadSection ds:fs_access_section
    LeaveSection ds:fs_list_section

parse_dir_start:
    mov ds:fs_access_parse,1
    mov ds,bx
    mov bx,flat_sel
    mov fs,bx
    EnterReadSection ds:ds_access_section

parse_dir_tree_loop:
    mov bx,OFFSET char_tab
;
    mov al,es:[edi]
    cmp al,'.'
    je parse_dir_dot
;
    mov esi,ds:ds_dir_ptr
    or esi,esi
    jz parse_dir_ok

parse_dir_entry_loop:
    mov cx,fs:[esi].de_name_size    
    push esi
    push edi
    mov esi,fs:[esi].de_name

parse_dir_name_loop:
    mov al,es:[edi]
    xlat byte ptr cs:char_tab
    mov ah,al
    mov al,fs:[esi]
    xlat byte ptr cs:char_tab
    cmp al,ah
    jne parse_dir_next
;
    inc esi
    inc edi
    loop parse_dir_name_loop
;
    mov al,es:[edi]
    or al,al
    jz parse_dir_tree_next
;
    inc edi
    cmp al,'\'
    je parse_dir_tree_next
;
    cmp al,'/'
    je parse_dir_tree_next
    jmp parse_dir_next

parse_dir_dot:
    inc edi

parse_dir_dot_loop:
    mov al,es:[edi]
    cmp al,'.'
    jne parse_dir_dot_ended
;
    inc edi
    EnterSection ds:ds_list_section
    mov bx,ds:ds_parent
    LeaveSection ds:ds_list_section
    or bx,bx
    jz parse_dir_fail
;
    mov ax,ds
    mov ds,bx
    EnterReadSection ds:ds_access_section
    mov ds,ax
    LeaveReadSection ds:ds_access_section
    mov ds,bx
    jmp parse_dir_dot_loop

parse_dir_dot_ended:
    or al,al
    jz parse_dir_ok
;
    inc edi
    cmp al,'\'
    je parse_dir_tree_loop
;
    cmp al,'/'
    je parse_dir_tree_loop

parse_dir_dot_fail:
    LeaveReadSection ds:ds_access_section
    jmp parse_dir_fail

parse_dir_next:
    pop edi
    pop esi
    mov esi,fs:[esi].de_next
    cmp esi,ds:ds_dir_ptr
    jne parse_dir_entry_loop
    jmp parse_dir_ok

parse_dir_tree_next:
    pop esi
    pop esi
    EnterSection ds:ds_list_section
    mov bx,fs:[esi].de_sel
    or bx,bx
    jnz parse_dir_tree_cached
;
    mov al,ds:ds_drive
    mov bx,ds
    mov edx,esi
    call CreateDirSel
    CallFileSystem fs_cache_dir_proc
    mov fs:[esi].de_sel,bx

parse_dir_tree_cached:
    LeaveSection ds:ds_list_section
    mov ax,ds
    mov ds,bx
    EnterReadSection ds:ds_access_section
    mov ds,ax
    LeaveReadSection ds:ds_access_section
    mov ds,bx
    mov al,es:[edi]
    or al,al
    jnz parse_dir_tree_loop

parse_dir_ok:
    inc ds:ds_usage
    LeaveReadSection ds:ds_access_section
    clc
    jmp parse_dir_done

parse_dir_fail:
    stc

parse_dir_done:
    pop ebp
    pop esi
    pop edx
    pop cx
    pop bx
    pop ax
    pop fs
    ret
ParseDir    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ParseEnd
;
;           DESCRIPTION:    End parsing
;
;           PARAMETERS:         DS          Dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseEnd    Proc near
    push ds
    push ax
    push si
;
    movzx si,ds:ds_drive
    add si,si
    mov ax,fs_sys_data_sel
    mov ds,ax
    mov ds,ds:[si]
    cli
    mov ds:fs_access_parse,0
    LeaveReadSection ds:fs_access_section
;
    pop si
    pop ax
    pop ds
    ret
ParseEnd    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ParseFile
;
;           DESCRIPTION:    Parse pathname for a valid file
;
;           PARAMETERS:         DS          Dir selector
;                           FS          Flat sel
;                           ES:EDI  Pathname
;
;           RETURNS:        EDX         File dir entry
;                           ES:EDI  Remaining part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseFile       Proc near
    push ax
    push bx
    push cx
    push esi
;
    mov bx,OFFSET char_tab
    mov edx,ds:ds_file_ptr
    or edx,edx
    stc
    jz parse_file_done

parse_file_entry_loop:
    mov cx,fs:[edx].de_name_size    
    mov esi,fs:[edx].de_name
    push edi

parse_file_name_loop:
    mov al,es:[edi]
    xlat byte ptr cs:char_tab
    mov ah,al
    mov al,fs:[esi]
    xlat byte ptr cs:char_tab
    cmp al,ah
    jne parse_file_next
;
    inc esi
    inc edi
    loop parse_file_name_loop
;
    mov al,es:[edi]
    or al,al
    jz parse_file_ok

parse_file_next:
    pop edi
    mov edx,fs:[edx].de_next
    cmp edx,ds:ds_file_ptr
    jnz parse_file_entry_loop
;
    xor edx,edx
    stc
    jmp parse_file_done     

parse_file_ok:
    pop esi
    clc

parse_file_done:
    pop esi
    pop cx
    pop bx
    pop ax
    ret
ParseFile       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ParseName
;
;           DESCRIPTION:    Parse pathname for a valid name
;
;           PARAMETERS:         FS          Flat sel
;                           ES:EDI  Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParseName       Proc near
    push ax
    push bx
    push edi
;
    mov bx,OFFSET char_tab
    mov al,es:[edi]
    or al,al
    jz parse_name_fail

parse_name_loop:
    mov al,es:[edi]
    inc edi
    xlat byte ptr cs:char_tab
    or al,al
    jz parse_name_ok
;
    add al,1
    jnc parse_name_loop

parse_name_fail:
    stc
    jmp parse_name_done

parse_name_ok:
    clc

parse_name_done:
    pop edi
    pop bx
    pop ax
    ret
ParseName       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SearchDir
;
;           DESCRIPTION:    Search dir for files
;
;           PARAMETERS:         DS          Dir selector
;                           FS          Flat sel
;
;           RETURNS:        BX          Dir search selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SearchDir       Proc near
    push es
    push eax
    push cx
    push di
;
    xor cx,cx
    mov eax,ds:ds_dir_ptr
    or eax,eax
    jz search_scan_dir_done

search_scan_dir_loop:
    inc cx
    mov eax,fs:[eax].de_next
    cmp eax,ds:ds_dir_ptr
    jne search_scan_dir_loop

search_scan_dir_done:   
    mov eax,ds:ds_file_ptr
    or eax,eax
    jz search_scan_file_done

search_scan_file_loop:
    inc cx
    mov eax,fs:[eax].de_next
    cmp eax,ds:ds_file_ptr
    jne search_scan_file_loop

search_scan_file_done:  
    movzx eax,cx
    shl eax,2
    add eax,OFFSET dhs_data
    AllocateGlobalMem
    mov es:dhs_count,cx
    mov al,ds:ds_drive
    mov es:dhs_drive,al
    mov eax,ds:ds_mount_id
    mov es:dhs_mount_id,eax
    mov di,OFFSET dhs_data
;
    mov eax,ds:ds_dir_ptr
    or eax,eax
    jz search_move_dir_done

search_move_dir_loop:
    inc fs:[eax].de_usage
    stosd
    mov eax,fs:[eax].de_next
    cmp eax,ds:ds_dir_ptr
    jne search_move_dir_loop

search_move_dir_done:
    mov eax,ds:ds_file_ptr
    or eax,eax
    jz search_move_file_done

search_move_file_loop:
    inc fs:[eax].de_usage
    stosd
    mov eax,fs:[eax].de_next
    cmp eax,ds:ds_file_ptr
    jne search_move_file_loop

search_move_file_done:  
    mov bx,es
;
    pop di
    pop cx
    pop eax
    pop es
    ret
SearchDir       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCurDirBase
;
;           DESCRIPTION:    Set current directory
;
;           PARAMETERS:         AL              Drive
;                           ES:EDI      Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCurDirBase   Proc near
    push ds
    push fs
    push eax
    push bx
    push ecx
    push edx
    push esi
;
    CheckDrive
    jc get_cur_dir_done
;
    mov bx,fs_sys_data_sel
    mov ds,bx
    movzx bx,al
    add bx,bx
    mov dx,ds:[bx]
    or dx,dx
    jnz get_cur_dir_not_vfs
;
    GetVfsCurDir
    jmp get_cur_dir_done

get_cur_dir_not_vfs:
    mov ds,dx
    EnterReadSection ds:fs_access_section
    mov ds:fs_access_parse,1
    mov edx,ds:fs_mount_id
;
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_cur_dir_sel
    pop ax
    mov si,flat_sel
    mov fs,si
    mov bx,ds:[bx].pc_dir_sel_arr
    xor ecx,ecx
    mov byte ptr es:[edi],0
    or bx,bx
    je get_cur_dir_ok
;
    mov ds,bx
    cmp edx,ds:ds_mount_id
    jne get_cur_dir_ok
;
    EnterReadSection ds:ds_access_section

get_cur_dir_loop:
    mov bx,ds:ds_parent
    or bx,bx
    jz get_cur_dir_leave
;
    mov si,ds
    mov ds,bx
    EnterReadSection ds:ds_access_section
    mov ds,si
    LeaveReadSection ds:ds_access_section
    mov ds,bx
    mov eax,ds:ds_dir_ptr

get_cur_dir_node_loop:
    cmp si,fs:[eax].de_sel
    je get_cur_dir_node_found
;
    mov eax,fs:[eax].de_next
    jmp get_cur_dir_node_loop

get_cur_dir_node_found:
    push eax
    push ecx
    push edi
    movzx eax,fs:[eax].de_name_size
    inc eax
    mov esi,edi
    add edi,eax
    add esi,ecx
    add edi,ecx
    dec esi
    dec edi
    std
    rep movs byte ptr es:[edi],es:[esi]
    cld
    pop edi
    pop ecx
    pop esi
    movzx eax,fs:[esi].de_name_size
    add ecx,eax
    inc ecx
;
    push ecx
    push edi
    mov esi,fs:[esi].de_name
    mov ecx,eax
    mov al,es:[edi]
    rep movs byte ptr es:[edi],fs:[esi]
    or al,al
    je get_cur_dir_no_slash
;
    mov al,'\'

get_cur_dir_no_slash:
    stos byte ptr es:[edi]
    pop edi
    pop ecx
    jmp get_cur_dir_loop

get_cur_dir_leave:
    LeaveReadSection ds:ds_access_section
    mov al,ds:ds_drive

get_cur_dir_ok:
    mov bx,fs_sys_data_sel
    mov ds,bx
    movzx bx,al
    add bx,bx
    mov ds,ds:[bx]
    cli
    mov ds:fs_access_parse,0
    LeaveReadSection ds:fs_access_section
    clc

get_cur_dir_done:
    pop esi
    pop edx
    pop ecx
    pop bx
    pop eax
    pop fs
    pop ds
    ret
GetCurDirBase   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetCurDirBase
;
;           DESCRIPTION:    Set current directory
;
;           PARAMETERS:         ES:EDI      Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetCurDirBase   Proc near
    UserGateForce32 is_vfs_path_nr
    jc set_cur_dir_old
;
    SetVfsCurDir
    ret

set_cur_dir_old:
    push ds
    push ax
    push edi
;
    call ParseDir
    jc set_cur_dir_done
;
    mov al,es:[edi]
    or al,al
    jne set_cur_dir_fail
;
    push es
    push bx
    push si
;
    push ax
    GetThread
    mov es,ax
    mov es,es:p_proc_sel
    mov es,es:pf_cur_dir_sel
    pop ax
;
    mov bx,ds
    mov al,ds:ds_drive
    movzx si,al
    add si,si
    xchg bx,es:[si].pc_dir_sel_arr
    or bx,bx
    jz set_cur_dir_setup
;
    push ds
    mov ds,bx
    dec ds:ds_usage 
    pop ds

set_cur_dir_setup:
    pop si
    pop bx
    pop es
    call ParseEnd
    clc
    jmp set_cur_dir_done

set_cur_dir_fail:
    call ParseEnd
    stc

set_cur_dir_done:
    pop edi
    pop ax
    pop ds
    ret
SetCurDirBase   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateDirBase
;
;           DESCRIPTION:    Create a new directory
;
;           PARAMETERS:         ES:EDI      Pathname
;
;           RETURNS:        CX              FILE ATTRIBUTE
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDirBase   Proc near
    push ds
    push fs
    push eax
    push ebx
    push edx
;
    mov bx,flat_sel
    mov fs,bx
;
    push edi
    call ParseDir
    jc create_dir_pop_failed
;
    EnterWriteSection ds:ds_access_section
    dec ds:ds_usage
    call ParseFile
    jc create_dir_check

create_dir_leave_fail:
    LeaveWriteSection ds:ds_access_section
    call ParseEnd
    jmp create_dir_pop_failed

create_dir_check:
    call ParseName
    jc create_dir_pop_failed
;
    mov al,ds:ds_drive
    mov bx,ds
    CallFileSystem fs_create_dir_proc
    jc create_dir_leave_fail
;
    LeaveWriteSection ds:ds_access_section
    pop edi
    call ParseEnd
    clc
    jmp create_dir_done

create_dir_pop_failed:
    pop edi
    stc

create_dir_done:
    pop edx
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
CreateDirBase   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteDirBase
;
;           DESCRIPTION:    Delete a directory
;
;           PARAMETERS:         ES:EDI      Pathname
;
;           RETURNS:        NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteDirBase   Proc near
    push ds
    push es
    push fs
    push eax
    push ebx
    push ecx
    push edx
    push edi
;
    mov ax,flat_sel
    mov fs,ax
;
    call ParseDir
    jc delete_dir_done
;
    EnterWriteSection ds:ds_access_section
    dec ds:ds_usage
    mov edx,ds:ds_handle
    mov bx,ds:ds_parent
    or bx,bx
    jz delete_dir_fail
;
    mov ax,ds:ds_usage
    or ax,ax
    jnz delete_dir_fail
;
    mov eax,ds:ds_dir_ptr
    or eax,eax
    jnz delete_dir_fail
;
    mov eax,ds:ds_file_ptr
    or eax,eax
    jnz delete_dir_fail
;
    push ds
    mov ds,bx
    EnterWriteSection ds:ds_access_section
;
    mov ax,fs:[edx].de_usage
    or ax,ax
    jnz delete_dir_pop_fail
;
    push ebx
    mov eax,fs:[edx].de_next
    mov ebx,fs:[edx].de_prev
    mov fs:[ebx].de_next,eax
    mov fs:[eax].de_prev,ebx
    pop ebx
    cmp eax,edx
    jne delete_dir_unlink
;
    mov ds:ds_dir_ptr,0
    jmp delete_dir_leave

delete_dir_unlink:
    cmp edx,ds:ds_dir_ptr
    jne delete_dir_leave
;
    mov ds:ds_dir_ptr,eax
    
delete_dir_leave:
    LeaveWriteSection ds:ds_access_section
    mov al,ds:ds_drive
    CallFileSystem fs_delete_dir_proc
    pop ds
    call ParseEnd
    call FreeDirSel
    clc
    jmp delete_dir_done

delete_dir_pop_fail:
    LeaveWriteSection ds:ds_access_section
    pop ds

delete_dir_fail:
    LeaveWriteSection ds:ds_access_section
    call ParseEnd
    stc

delete_dir_done:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    ret
DeleteDirBase   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFileAttribBase
;
;           DESCRIPTION:    Get file attribute
;
;           PARAMETERS:         ES:EDI      Pathname
;
;           RETURNS:        CX              FILE ATTRIBUTE
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFileAttribBase       Proc near
    UserGateForce32 is_vfs_path_nr
    jc get_file_attrib_old
;
    push eax
    GetVfsDirEntryAttrib
    mov cx,ax
    pop eax
    ret

get_file_attrib_old:
    push ds
    push es
    push fs
    push ax
    push edx
    push edi
;
    mov ax,flat_sel
    mov fs,ax
;
    call ParseDir
    jc get_file_attrib_done
;
    EnterReadSection ds:ds_access_section
    dec ds:ds_usage
    mov al,es:[edi]
    or al,al
    je get_file_attrib_dir

get_file_attrib_file:
    call ParseFile
    jc get_file_attrib_fail
;
    movzx cx,fs:[edx].de_attrib
    jmp get_file_attrib_ok

get_file_attrib_dir:
    mov edx,ds:ds_handle
    or edx,edx
    jz get_file_attrib_root
;
    movzx cx,fs:[edx].de_attrib
    jmp get_file_attrib_ok

get_file_attrib_root:
    mov cx,FILE_ATTRIB_DIR
    jmp get_file_attrib_ok

get_file_attrib_fail:
    LeaveReadSection ds:ds_access_section
    call ParseEnd
    stc
    jmp get_file_attrib_done

get_file_attrib_ok:
    LeaveReadSection ds:ds_access_section
    call ParseEnd
    clc

get_file_attrib_done:
    pop edi
    pop edx
    pop ax
    pop fs
    pop es
    pop ds
    ret
GetFileAttribBase       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetFileAttribBase
;
;           DESCRIPTION:    Set file attributes
;
;           PARAMETERS:         ES:EDI      FILENAME
;                           CX              FILE ATTRIBUTE
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetFileAttribBase       Proc near
    push ds
    push es
    push fs
    push ax
    push edx
    push edi
;
    mov ax,flat_sel
    mov fs,ax
;
    call ParseDir
    jc set_file_attrib_done
;
    EnterWriteSection ds:ds_access_section
    dec ds:ds_usage
    mov al,es:[edi]
    or al,al
    je set_file_attrib_dir

set_file_attrib_file:
    call ParseFile
    jc set_file_attrib_fail
;
    test cl,10h
    jnz set_file_attrib_fail
;
    mov fs:[edx].de_attrib,cl
    mov al,ds:ds_drive
    CallFileSystem fs_update_file_proc
    jmp set_file_attrib_ok

set_file_attrib_dir:
    mov edx,ds:ds_handle
    test cl,10h
    jz set_file_attrib_fail
;
    mov fs:[edx].de_attrib,cl
    mov al,ds:ds_drive
    CallFileSystem fs_update_dir_proc
    jmp set_file_attrib_ok

set_file_attrib_fail:
    LeaveWriteSection ds:ds_access_section
    call ParseEnd
    stc
    jmp set_file_attrib_done

set_file_attrib_ok:
    LeaveWriteSection ds:ds_access_section
    call ParseEnd
    clc

set_file_attrib_done:
    pop edi
    pop edx
    pop ax
    pop fs
    pop es
    pop ds
    ret
SetFileAttribBase       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteFilePhysical
;
;           DESCRIPTION:    Delete file in physical file system
;
;           PARAMETERS:         EDX             Dir entry
;                           DS              Directory selector
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteFilePhysical      Proc near
    push ds
    push es
    push ax
    push bx
    push ecx
;
    call RequestFileSel
;
    push ds
    mov ds,bx
    EnterWriteSection ds:file_size_section
    pop ds
;
    push edx
    xor edx,edx
    CallFileSystem fs_set_file_size_proc
    pop edx
;
    push bx
    mov bx,ds
    CallFileSystem fs_delete_file_proc
    pop bx
;
    push ds
    mov ds,bx
    LeaveWriteSection ds:file_size_section
    pop ds
;
    call ReleaseFileSel
;
    pop ecx
    pop bx
    pop ax
    pop es
    pop ds
    ret
DeleteFilePhysical      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteFileBase
;
;           DESCRIPTION:    Delete file
;
;           PARAMETERS:         ES:EDI      FILE NAME
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteFileBase  Proc near
    push ds
    push es
    push fs
    push eax
    push edx
    push edi
;
    mov ax,flat_sel
    mov fs,ax
;
    call ParseDir
    jc delete_file_done
;
    EnterWriteSection ds:ds_access_section
    dec ds:ds_usage
    mov al,es:[edi]
    or al,al
    je delete_file_fail
;
    call ParseFile
    jc delete_file_fail
;
    mov ax,fs:[edx].de_usage
    or ax,ax
    jnz delete_file_fail
;
    push ebx
    mov eax,fs:[edx].de_next
    mov ebx,fs:[edx].de_prev
    mov fs:[ebx].de_next,eax
    mov fs:[eax].de_prev,ebx
    pop ebx
    cmp eax,edx
    jne delete_file_unlink
;
    mov ds:ds_file_ptr,0
    jmp delete_file_leave

delete_file_unlink:
    cmp edx,ds:ds_file_ptr
    jne delete_file_leave
;
    mov ds:ds_file_ptr,eax

delete_file_leave:
    LeaveWriteSection ds:ds_access_section
    call ParseEnd
;
    call DeleteFilePhysical
    jmp delete_file_done

delete_file_fail:
    LeaveWriteSection ds:ds_access_section
    call ParseEnd
    stc

delete_file_done:
    pop edi
    pop edx
    pop eax
    pop fs
    pop es
    pop ds
    ret
DeleteFileBase  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenDirBase
;
;           DESCRIPTION:    Open a directory
;
;           PARAMETERS:         ES:EDI      Pathname
;
;           RETURNS:        BX              FILE HANDLE
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenDirBase     Proc near
    push ds
    push es
    push edi
;
    call ParseDir
    jc open_dir_done
;
    EnterReadSection ds:ds_access_section
    dec ds:ds_usage
    mov al,es:[edi]
    or al,al
    je open_dir_do
;
    LeaveReadSection ds:ds_access_section
    call ParseEnd
    stc
    jmp open_dir_done

open_dir_do:
    push fs
    mov ax,flat_sel
    mov fs,ax
    call SearchDir
    mov al,ds:ds_drive
    call CreateDirHandle
    LeaveReadSection ds:ds_access_section
    call ParseEnd
    pop fs
    clc

open_dir_done:
    pop edi
    pop es
    pop ds
    ret
OpenDirBase     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadDirBase
;
;           DESCRIPTION:    Retrieves a directory entry
;
;           PARAMETERS:         BX              HANDLE TO DIR
;                           DX              ENTRY #
;                           CX              MAX SIZE OF FILENAME
;                           ES:EDI      BUFFER
;
;           RETURNS:        ECX             FILE SIZE
;                           BX              FILE ATTRIBUTE
;                           EDX:EAX     FILE TIME/DATE
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadDirBase     Proc near
    push ds
    push fs
    push esi
;
    mov ax,DIR_HANDLE
    DerefHandle
    jc read_dir_fail
;
    mov bx,[ebx].dir_handle_sel
    or bx,bx
    jz read_dir_fail
;
    mov ds,bx
    mov al,ds:dhs_drive
    mov si,fs_sys_data_sel
    mov fs,si
    movzx si,al
    add si,si
    mov si,fs:[si]
    or si,si
    jz read_dir_fail
;
    mov fs,si
    mov esi,fs:fs_mount_id
    cmp esi,ds:dhs_mount_id
    jne read_dir_fail
;
    mov ax,flat_sel
    mov fs,ax
    mov bx,dx
    cmp bx,ds:dhs_count
    jnc read_dir_fail
;
    shl bx,2
    add bx,OFFSET dhs_data
    mov esi,[bx]
    mov ax,fs:[esi].de_name_size
    cmp ax,cx
    jnc read_dir_size_ok
;
    mov cx,ax

read_dir_size_ok:
    movzx ecx,cx
    push esi
    push edi
    mov esi,fs:[esi].de_name
    rep movs byte ptr es:[edi],fs:[esi]
    xor al,al
    stos byte ptr es:[edi]
    pop edi
    pop esi
    mov edx,fs:[esi].de_time+4
    mov eax,fs:[esi].de_time
    movzx bx,fs:[esi].de_attrib
    and bx,7Fh
    test bl,10h
    jz read_dir_file
;
    xor ecx,ecx
    clc
    jmp read_dir_done

read_dir_file:
    mov ecx,fs:[esi].dfe_data_size
    clc     
    jmp read_dir_done

read_dir_fail:
    stc

read_dir_done:
    pop esi
    pop fs
    pop ds
    ret
ReadDirBase     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseDirBase
;
;           DESCRIPTION:    Close a directory
;
;           PARAMETERS:         BX              Dir search sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseDirBase    Proc near
    push es
    push fs
    push ax
    push bx
    push cx
    push edx
    push ebp
;
    mov ebp,-1
    mov es,bx
    mov al,es:dhs_drive
    mov bx,fs_sys_data_sel
    mov fs,bx
    movzx bx,al
    add bx,bx
    mov bx,fs:[bx]
    or bx,bx
    jz close_dir_do
;
    mov fs,bx
    mov ebp,fs:fs_mount_id

close_dir_do:
    mov ax,flat_sel
    mov fs,ax
    mov cx,es:dhs_count
    or cx,cx
    jz close_dir_unlock_free
;
    mov bx,OFFSET dhs_data

close_dir_unlock_loop:
    mov edx,es:[bx]
    sub fs:[edx].de_usage,1
    jnz close_dir_next
;
    cmp ebp,es:dhs_mount_id
    je close_dir_next
;
    int 3
;   FreeMem

close_dir_next:
    add bx,4
    loop close_dir_unlock_loop

close_dir_unlock_free:
    FreeMem
;
    pop ebp
    pop edx 
    pop cx
    pop bx
    pop ax
    pop fs
    pop es
    ret
CloseDirBase    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           open_legacy_file
;
;           DESCRIPTION:    Open legacy file
;
;           PARAMETERS:     ES:EDI      Filename
;                           CX          Mode
;                           
;           RETURNS:        BX          File handle entry
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_legacy_file_name  DB 'Open Legacy File',0

open_legacy_file    Proc far
    push ds
    push es
    push fs
    push ax
    push cx
    push edx
;
    mov bx,flat_sel
    mov fs,bx
;
    push edi
    call ParseDir
    jc ocfPopFailed
;
    EnterWriteSection ds:ds_access_section
    dec ds:ds_usage
    call ParseFile
    jnc ocfExists
;
    test cx,O_CREAT
    jz ocfLeaveFailed
;
    call ParseName
    jc ocfLeaveFailed
;
    push cx
    xor cl,cl
    mov al,ds:ds_drive
    mov bx,ds
    CallFileSystem fs_create_file_proc
    call RequestFileSel
    pop cx
;
    LeaveWriteSection ds:ds_access_section
    pop edi
    jmp ocfHandle

ocfExists:
    test cx,O_EXCL
    jnz ocfLeaveFailed
;
    pop edi
    call RequestFileSel
;
    test cx,O_CREAT OR O_TRUNC
    jz ocfOpen
;
    push ds
    mov ds,bx
    EnterWriteSection ds:file_size_section
    pop ds
;
    push edx
    xor edx,edx
    CallFileSystem fs_set_file_size_proc
    pop edx
;
    push ds
    mov ds,bx
    LeaveWriteSection ds:file_size_section
    pop ds

ocfOpen:
    LeaveWriteSection ds:ds_access_section

ocfHandle:
    mov es,bx
    call ParseEnd
;
    mov bx,es:file_c_handle
    or bx,bx
    jnz ocfREf

ocfAlloc:
    mov dx,es
    mov ax,C_HANDLE_FILE
    AllocateCHandle
    jnc ocfSaveHandle
;
    mov bx,es
    xor ax,ax
    mov es,ax
    call ReleaseFileSel
    jmp ocfFailed

ocfRef:
    mov dx,es
    mov ax,C_HANDLE_FILE
    RefCHandle
    jc ocfAlloc
;
    dec es:file_usage
    jmp ocfOk

ocfSaveHandle:
    mov es:file_c_handle,bx

ocfOk:
    clc
    jmp ocfDone

ocfLeaveFailed:
    LeaveWriteSection ds:ds_access_section
    call ParseEnd

ocfPopFailed:
    pop edi

ocfFailed:
    stc

ocfDone:
    pop edx
    pop cx
    pop ax
    pop fs
    pop es
    pop ds
    retf32
open_legacy_file   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           open_legacy_handle
;
;           DESCRIPTION:    Open legacy handle
;
;           PARAMETERS:     ES:EDI      Filename
;                           CX          Mode
;                           
;           RETURNS:        DS          Sys handle obj
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_legacy_handle_name  DB 'Open Legacy Handle',0

open_legacy_handle    Proc far
    push es
    push fs
    push eax
    push ebx
    push ecx
    push edx
;
    mov bx,flat_sel
    mov fs,bx
;
    push edi
    call ParseDir
    jc olhPopFailed
;
    EnterWriteSection ds:ds_access_section
    dec ds:ds_usage
    call ParseFile
    jnc olhExists
;
    test cx,O_CREAT
    jz olhLeaveFailed
;
    call ParseName
    jc olhLeaveFailed
;
    push cx
    xor cl,cl
    mov al,ds:ds_drive
    mov bx,ds
    CallFileSystem fs_create_file_proc
    call RequestFileSel
    pop cx
;
    LeaveWriteSection ds:ds_access_section
    pop edi
    jmp olhHandle

olhExists:
    test cx,O_EXCL
    jnz olhLeaveFailed
;
    pop edi
    call RequestFileSel
;
    test cx,O_CREAT OR O_TRUNC
    jz olhOpen
;
    push ds
    mov ds,bx
    EnterWriteSection ds:file_size_section
    pop ds
;
    push edx
    xor edx,edx
    CallFileSystem fs_set_file_size_proc
    pop edx
;
    push ds
    mov ds,bx
    LeaveWriteSection ds:file_size_section
    pop ds

olhOpen:
    LeaveWriteSection ds:ds_access_section

olhHandle:
    call ParseEnd
;
    mov ds,bx
    EnterSection ds:hsi_section
;
    mov ebx,ds:hsi_index
    or ebx,ebx
    jz olhNew
;
    dec ds:file_usage
    jmp olhHandleOk

olhNew:
    mov ds:hsi_create_handle_proc,OFFSET CreateHandleObj
    mov ds:hsi_create_handle_proc+4,cs
;
    AllocateSysHandle
    mov ds:hsi_index,ebx

olhHandleOk:
    LeaveSection ds:hsi_section
    clc
    jmp olhDone

olhLeaveFailed:
    LeaveWriteSection ds:ds_access_section
    call ParseEnd

olhPopFailed:
    pop edi

olhFailed:
    stc

olhDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop es
    retf32
open_legacy_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           open_legacy_kernel_file
;
;           DESCRIPTION:    Open legacy kernel file
;
;           PARAMETERS:     ES:EDI      Filename
;                           CX          Mode
;                           
;           RETURNS:        BX          File sel
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_legacy_kernel_file_name  DB 'Open Legacy Kernel File',0

open_legacy_kernel_file    Proc far
    push ds
    push es
    push fs
    push ax
    push cx
    push edx
;
    mov bx,flat_sel
    mov fs,bx
;
    push edi
    call ParseDir
    jc okfPopFailed
;
    EnterWriteSection ds:ds_access_section
    dec ds:ds_usage
    call ParseFile
    jnc okfExists
;
    test cx,O_CREAT
    jz okfLeaveFailed
;
    call ParseName
    jc okfLeaveFailed
;
    push cx
    xor cl,cl
    mov al,ds:ds_drive
    mov bx,ds
    CallFileSystem fs_create_file_proc
    call RequestFileSel
    pop cx
;
    LeaveWriteSection ds:ds_access_section
    pop edi
    jmp okfHandle

okfExists:
    test cx,O_EXCL
    jnz okfLeaveFailed
;
    pop edi
    call RequestFileSel
;
    test cx,O_CREAT OR O_TRUNC
    jz okfOpen
;
    push ds
    mov ds,bx
    EnterWriteSection ds:file_size_section
    pop ds
;
    push edx
    xor edx,edx
    CallFileSystem fs_set_file_size_proc
    pop edx
;
    push ds
    mov ds,bx
    LeaveWriteSection ds:file_size_section
    pop ds

okfOpen:
    LeaveWriteSection ds:ds_access_section

okfHandle:
    mov es,bx
    call ParseEnd
;
    mov ebx,es
    clc
    jmp okfDone

okfLeaveFailed:
    LeaveWriteSection ds:ds_access_section
    call ParseEnd

okfPopFailed:
    pop edi

okfFailed:
    stc

okfDone:
    pop edx
    pop cx
    pop ax
    pop fs
    pop es
    pop ds
    retf32
open_legacy_kernel_file   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ref_legacy_kernel_file
;
;           DESCRIPTION:    Ref legacy file
;
;           PARAMETERS:     BX          File sel
;                           
;           RETURNS:        BX          File handle entry
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ref_legacy_kernel_file_name  DB 'Ref Legacy File',0

ref_legacy_kernel_file    Proc far
    push es
    push eax
    push ecx
    push edx
;
    mov es,bx
    mov bx,es:file_c_handle
    or bx,bx
    jnz rkfREf

rkfAlloc:
    mov edx,es
    mov ax,C_HANDLE_FILE
    AllocateCHandle
    jnc rkfSaveHandle
;
    int 3
    jmp rkfFailed

rkfRef:
    mov dx,es
    mov ax,C_HANDLE_FILE
    RefCHandle
    jc rkfAlloc
;
    dec es:file_usage
    jmp rkfOk

rkfSaveHandle:
    mov es:file_c_handle,bx

rkfOk:
    clc
    jmp rkfDone

rkfFailed:
    stc

rkfDone:
    pop edx
    pop ecx
    pop eax
    pop es
    retf32
ref_legacy_kernel_file   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_DRIVE_INFO
;
;           DESCRIPTION:    Get drive info
;
;           PARAMETERS:         AL              DRIVE NR
;
;           RETURNS:        EAX             Free units
;                           CX              Bytes per unit
;                           EDX             Total # of units
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_drive_info_name     DB 'Get Drive Info',0

get_drive_info:
    push ds
    push ebx
;
    CheckDrive
    jc get_drive_info_done
;
    mov bx,fs_sys_data_sel
    mov ds,bx
    movzx bx,al
    add bx,bx
    mov bx,ds:[bx]
    or bx,bx
    stc
    jz get_drive_info_done
;
    CallFileSystem fs_info_proc
    jc get_drive_info_done
;

get_drive_info_done:
    pop ebx
    pop ds
    retf32


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_CUR_DRIVE
;
;           DESCRIPTION:    Set current drive
;
;           PARAMETERS:         AL              DRIVE NR
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cur_drive_name      DB 'Set Current Drive',0

set_cur_drive:
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push ds
    push si
;
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_cur_dir_sel
    pop ax
    CheckDrive
    jc set_cur_drive_done
;
    mov ds:pc_drive,al

set_cur_drive_done:
    pop si
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_CUR_DRIVE
;
;           DESCRIPTION:    Get current drive
;
;           PARAMETERS:         AL              DRIVE NR. 0 = DEFAULT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cur_drive_name      DB 'Get Current Drive',0

get_cur_drive:
    push ds
    push si
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_cur_dir_sel
    pop ax
    mov al,ds:pc_drive
    clc
    pop si
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_CUR_DIR
;
;           DESCRIPTION:    Set current directory
;
;           PARAMETERS:         ES:E(DI)    PATH NAME
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cur_dir_name    DB 'Set Current Directory',0

set_cur_dir32:
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    call SetCurDirBase

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32

set_cur_dir16   PROC far
    push edi
    movzx edi,di
    call SetCurDirBase
    pop edi
    retf32
set_cur_dir16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_CUR_DIR
;
;           DESCRIPTION:    Get current directory
;
;           PARAMETERS:         ES:E(DI)    PATH NAME
;                           AL              DRIVE
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cur_dir_name    DB 'Get Current Directory',0

get_cur_dir32:
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    call GetCurDirBase

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32

get_cur_dir16   PROC far
    push edi
    movzx edi,di
    call GetCurDirBase
    pop edi
    retf32
get_cur_dir16   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MAKE_DIR
;
;           DESCRIPTION:    Create directory
;
;           PARAMETERS:         ES:(E)DI    DIRECTORY NAME
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

make_dir_name   DB 'Make Directory',0

make_dir32:
    call CreateDirBase
    retf32

make_dir16      PROC far
    push edi
    movzx edi,di
    call CreateDirBase
    pop edi
    retf32
make_dir16      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REMOVE_DIR
;
;           DESCRIPTION:    Remove directory
;
;           PARAMETERS:         ES:(E)DI    DIRECTORY NAME
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_dir_name DB 'Remove Directory',0

remove_dir32:
    call DeleteDirBase
    retf32

remove_dir16    PROC far
    push edi
    movzx edi,di
    call DeleteDirBase
    pop edi
    retf32
remove_dir16    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_FILE_ATTRIBUTE
;
;           DESCRIPTION:    Get file attributes
;
;           PARAMETERS:         ES:(E)DI    FILENAME
;
;           RETURNS:        CX              FILE ATTRIBUTE
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
get_file_attribute_name DB 'Get File Attribute',0

get_file_attrib32:
    call GetFileAttribBase
    retf32

get_file_attrib16       PROC far
    push edi
    movzx edi,di
    call GetFileAttribBase
    pop edi
    retf32
get_file_attrib16       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SET_FILE_ATTRIBUTE
;
;           DESCRIPTION:    Set file attributes
;
;           PARAMETERS:         ES:(E)DI    FILENAME
;                           CX              FILE ATTRIBUTE
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
set_file_attribute_name DB 'Set File Attribute',0

set_file_attrib32:
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    call SetFileAttribBase

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32

set_file_attrib16       PROC far
    push edi
    movzx edi,di
    call SetFileAttribBase
    pop edi
    retf32
set_file_attrib16       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DELETE_FILE
;
;           DESCRIPTION:    Delete file
;
;           PARAMETERS:         ES:(E)DI    FILE NAME
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_file_name    DB 'Delete File',0

delete_file32:
    call DeleteFileBase
    retf32

delete_file16   PROC far
    push edi
    movzx edi,di
    call DeleteFileBase
    pop edi
    retf32
delete_file16   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OPEN_DIR
;
;           DESCRIPTION:    Opens a directory
;
;           PARAMETERS:         ES:(E)DI    PATH NAME
;                           NC              SUCCESS
;
;           RETURNS:        BX              HANDLE TO DIR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_dir_name   DB 'Open Directory',0

open_dir32:
    call OpenDirBase
    retf32

open_dir16      PROC far
    push edi
    movzx edi,di
    call OpenDirBase
    pop edi
    retf32
open_dir16      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           READ_DIR
;
;           DESCRIPTION:    Retrieves a directory entry
;
;           PARAMETERS:         BX              HANDLE TO DIR
;                           DX              ENTRY #
;                           CX              MAX SIZE OF FILENAME
;                           ES:(E)DI    BUFFER
;
;           RETURNS:        ECX             FILE SIZE
;                           BX              FILE ATTRIBUTE
;                           EDX:EAX     FILE TIME/DATE
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_dir_name   DB 'Read Directory',0

read_dir32:
    call ReadDirBase
    retf32

read_dir16      PROC far
    push edi
    movzx edi,di
    call ReadDirBase
    pop edi
    retf32
read_dir16      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CLOSE_DIR
;
;           DESCRIPTION:    Close a directory
;
;           PARAMETERS:         BX              HANDLE TO DIR
;                           NC              SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_dir_name  DB 'Close Directory',0

close_dir       Proc far
    push ds
    push ax
    push ebx
    push esi
;
    mov ax,DIR_HANDLE
    DerefHandle
    jc close_dir_done
;
    mov esi,ebx
    mov bx,[ebx].dir_handle_sel
    or bx,bx
    stc
    jz close_dir_done
;
    call CloseDirBase
    mov ebx,esi
    FreeHandle
    clc

close_dir_done:
    pop esi
    pop ebx
    pop ax
    pop ds
    retf32
close_dir       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsFlushable
;
;           DESCRIPTION:    Check if directory is flushable
;
;           PARAMETERS:         BX          Dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsFlushable     Proc near
    mov fs,bx

isflush_dir_list_loop:
    mov edi,fs:ds_dir_ptr
    or edi,edi
    jz isflush_dir_list_done

isflush_dir_list_check:
    mov bx,es:[edi].de_sel
    or bx,bx
    jz isflush_dir_list_next
;
    push fs
    push edi
    call IsFlushable
    pop edi
    pop fs
    jc isflush_dir_done

isflush_dir_list_next:
    mov edi,es:[edi].de_next
    cmp edi,fs:ds_dir_ptr
    jne isflush_dir_list_check

isflush_dir_list_done:
    mov edi,fs:ds_file_ptr
    or edi,edi
    jz isflush_file_list_done

isflush_file_list_check:
    EnterSection ds:ds_list_section
;
    mov bx,es:[edi].dfe_file_sel
    or bx,bx
    jz isflush_file_list_next
;
    push es
    mov es,bx
    add es:file_usage,1
    LeaveSection ds:ds_list_section
    call ReleaseFileSel
    EnterSection ds:ds_list_section
    pop es

isflush_file_list_next:
    LeaveSection ds:ds_list_section
;
    mov edi,es:[edi].de_next
    cmp edi,fs:ds_file_ptr
    jne isflush_file_list_check

isflush_file_list_done:
    clc

isflush_dir_done:
    ret
IsFlushable     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Flush
;
;           DESCRIPTION:    Flush directory
;
;           PARAMETERS:         BX          Dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Flush   Proc near
    mov fs,bx

flush_dir_list_loop:
    mov edi,fs:ds_dir_ptr
    or edi,edi
    jz flush_dir_list_done

flush_dir_list_check:
    mov bx,es:[edi].de_sel
    or bx,bx
    jz flush_dir_list_next
;
    push fs
    push edi
    call Flush
    pop edi
    pop fs
    mov es:[edi].de_sel,0

flush_dir_list_next:
    mov edi,es:[edi].de_next
    cmp edi,fs:ds_dir_ptr
    jne flush_dir_list_check

flush_dir_list_done:
    mov bx,fs
    xor di,di
    mov fs,di
    call FreeDir

flush_dir_done:
    ret
Flush   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           STOP_FILE_SYSTEM
;
;           DESCRIPTION:    Stop file system
;
;           PARAMETERS:         AL              DRIVE NR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_file_system_name   DB 'Stop File System',0

stop_file_system    Proc far
    push ds
    push es
    push fs
    pushad
;
    mov bx,fs_sys_data_sel
    mov ds,bx
    mov bx,flat_sel
    mov es,bx
;
    movzx si,al
    add si,si
    mov bx,ds:[si]
    or bx,bx
    clc
    jz stop_leave_done
;
    mov ds,bx    
    cli
    mov cl,ds:fs_access_parse
    or cl,cl
    jz stop_file_enter
;
    sti
    stc
    jmp stop_done

stop_file_enter:
    EnterWriteSection ds:fs_access_section
;
    CallFileSystem fs_flush_proc
    jc stop_leave_done
;
    mov bx,fs_sys_data_sel
    mov ds,bx
    movzx si,al
    add si,si
    mov bx,ds:[si]
    or bx,bx
    clc
    jz stop_leave_done
;
    mov ds,bx
    push ds
    mov bx,ds:fs_root_dir_sel
    or bx,bx
    clc
    jz stop_leave_pop_done
;
    push bx
    call IsFlushable
    pop bx
    jc stop_leave_pop_done
;
    call Flush
    mov ds:fs_root_dir_sel,0
    inc ds:fs_mount_id
    clc

stop_leave_pop_done:
    pop ds

stop_leave_done:
    LeaveWriteSection ds:fs_access_section
    
stop_done:
    popad
    pop fs
    pop es
    pop ds
    retf32
stop_file_system    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete handle
;
;           DESCRIPTION:    Delete a handle (called from handle module)
;
;           PARAMETERS:         BX              HANDLE TO DIR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push ax
    push ebx
    push esi
;
    mov ax,DIR_HANDLE
    DerefHandle
    jc delete_handle_done
;
    mov esi,ebx
    mov bx,[ebx].dir_handle_sel
    or bx,bx
    stc
    jz delete_handle_done
;
    call CloseDirBase
    mov ebx,esi
    FreeHandle
    clc

delete_handle_done:
    pop esi
    pop ebx
    pop ax
    pop ds
    retf32
delete_handle   Endp
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCurDir
;
;           DESCRIPTION:    Create cur dir selector
;
;           RETURNS:        AX      Cur dir selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_cur_dir_name DB 'Create Cur Dir', 0

create_cur_dir   Proc far
    push es
    push cx
    push di
;
    mov eax,SIZE proc_cur_dir_struc
    AllocateSmallGlobalMem
    mov es:pc_drive,'Z' - 'A'
;
    mov di,OFFSET pc_dir_sel_arr
    mov cx,256
    xor ax,ax
    rep stosw
;
    mov di,OFFSET pc_vfs_sel_arr
    mov cx,32
    xor ax,ax
    rep stosw
;
    mov di,OFFSET pc_vfs_handle_arr
    mov cx,32
    xor ax,ax
    rep stosw
;
    mov ax,es
;
    pop di
    pop cx
    pop es
    retf32
create_cur_dir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           clone_cur_dir
;
;           DESCRIPTION:    Clone cur dir
;
;           PARAMETERS:     AX          Incoming cur dir sel
;
;           RETURNS:        AX          New cur dir sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clone_cur_dir_name DB 'Clone Cur Dir', 0

clone_cur_dir   Proc far
    push ds
    push es
    push fs
    push bx
    push cx
;
    mov ds,ax
    mov eax,SIZE proc_cur_dir_struc
    AllocateSmallGlobalMem
    mov al,ds:pc_drive
    mov es:pc_drive,al
;
    CloneVfsCurDir
;
    mov cx,256
    mov bx,OFFSET pc_dir_sel_arr

ccdLoop:
    mov ax,ds:[bx]
    mov es:[bx],ax
    or ax,ax
    jz ccdNext
;
    mov fs,ax
    inc fs:ds_usage

ccdNext:
    add bx,2
    loop ccdLoop
;
    mov ax,es
;
    pop cx
    pop bx
    pop fs
    pop es
    pop ds
    retf32
clone_cur_dir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteCurDir
;
;           DESCRIPTION:    Delete cur dir
;
;           PARAMETERS:     AX       Cur dir sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_cur_dir_name DB 'Delete Cur Dir', 0

delete_cur_dir        Proc far
    push es
    push bx
    push cx
    push di
;
    mov cx,256
    mov di,OFFSET pc_dir_sel_arr
    mov es,ax

dcdLoop:
    mov bx,es:[di]
    or bx,bx
    jz dcdNext
;
    call FreeDir

dcdNext:
    add di,2
    loop dcdLoop
;
    FreeVfsCurDir
    jnc dcdFreeDone
;
    FreeMem

dcdFreeDone:
    pop di
    pop cx
    pop bx
    pop es
    retf32
delete_cur_dir        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_dir

init_dir    PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET delete_handle
    mov ax,DIR_HANDLE
    RegisterHandle
;
    mov esi,OFFSET create_cur_dir
    mov edi,OFFSET create_cur_dir_name
    mov ax,create_cur_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET clone_cur_dir
    mov edi,OFFSET clone_cur_dir_name
    mov ax,clone_cur_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET delete_cur_dir
    mov edi,OFFSET delete_cur_dir_name
    mov ax,delete_cur_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_file_system
    mov edi,OFFSET stop_file_system_name
    mov ax,stop_file_system_nr
    RegisterOsGate
;
    mov esi,OFFSET cache_dir
    mov edi,OFFSET cache_dir_name
    xor cl,cl
    mov ax,cache_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET insert_dir_entry
    mov edi,OFFSET insert_dir_entry_name
    xor cl,cl
    mov ax,insert_dir_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET insert_file_entry
    mov edi,OFFSET insert_file_entry_name
    xor cl,cl
    mov ax,insert_file_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET open_legacy_handle
    mov edi,OFFSET open_legacy_handle_name
    xor cl,cl
    mov ax,open_legacy_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET open_legacy_file
    mov edi,OFFSET open_legacy_file_name
    xor cl,cl
    mov ax,open_legacy_file_nr
    RegisterOsGate
;
    mov esi,OFFSET open_legacy_kernel_file
    mov edi,OFFSET open_legacy_kernel_file_name
    xor cl,cl
    mov ax,open_legacy_kernel_file_nr
    RegisterOsGate
;
    mov esi,OFFSET ref_legacy_kernel_file
    mov edi,OFFSET ref_legacy_kernel_file_name
    xor cl,cl
    mov ax,ref_legacy_kernel_file_nr
    RegisterOsGate
;
    mov esi,OFFSET get_drive_info
    mov edi,OFFSET get_drive_info_name
    xor dx,dx
    xor ecx,ecx
    mov ax,get_drive_info_nr
    RegisterBimodalSyscall
;
    mov esi,OFFSET set_cur_drive
    mov edi,OFFSET set_cur_drive_name
    xor dx,dx
    xor ecx,ecx
    mov ax,set_cur_drive_nr
    RegisterBimodalSyscall
;
    mov esi,OFFSET get_cur_drive
    mov edi,OFFSET get_cur_drive_name
    xor dx,dx
    xor ecx,ecx
    mov ax,get_cur_drive_nr
    RegisterBimodalSyscall
;
    mov ebx,OFFSET set_cur_dir16
    mov esi,OFFSET set_cur_dir32
    mov edi,OFFSET set_cur_dir_name
    mov dx,virt_es_in
    mov ecx,UG_SYSCALL_RD_PAR_ES_EDI
    mov ax,set_cur_dir_nr
    RegisterSyscall
;
    mov ebx,OFFSET get_cur_dir16
    mov esi,OFFSET get_cur_dir32
    mov edi,OFFSET get_cur_dir_name
    mov dx,virt_es_in
    mov ecx,UG_SYSCALL_WR_PAR_ES_EDI
    mov ax,get_cur_dir_nr
    RegisterSyscall
;
    mov ebx,OFFSET make_dir16
    mov esi,OFFSET make_dir32
    mov edi,OFFSET make_dir_name
    mov dx,virt_es_in
    mov ecx,UG_SYSCALL_RD_PAR_ES_EDI
    mov ax,make_dir_nr
    RegisterSyscall
;
    mov ebx,OFFSET remove_dir16
    mov esi,OFFSET remove_dir32
    mov edi,OFFSET remove_dir_name
    mov dx,virt_es_in
    mov ecx,UG_SYSCALL_RD_PAR_ES_EDI
    mov ax,remove_dir_nr
    RegisterSyscall
;
    mov ebx,OFFSET get_file_attrib16
    mov esi,OFFSET get_file_attrib32
    mov edi,OFFSET get_file_attribute_name
    mov dx,virt_es_in
    mov ecx,UG_SYSCALL_RD_PAR_ES_EDI
    mov ax,get_file_attribute_nr
    RegisterSyscall
;
    mov ebx,OFFSET set_file_attrib16
    mov esi,OFFSET set_file_attrib32
    mov edi,OFFSET set_file_attribute_name
    mov dx,virt_es_in
    mov ecx,UG_SYSCALL_RD_PAR_ES_EDI
    mov ax,set_file_attribute_nr
    RegisterSyscall
;
    mov ebx,OFFSET delete_file16
    mov esi,OFFSET delete_file32
    mov edi,OFFSET delete_file_name
    mov dx,virt_es_in
    mov ecx,UG_SYSCALL_RD_PAR_ES_EDI
    mov ax,delete_file_nr
    RegisterSyscall
;
    mov ebx,OFFSET open_dir16
    mov esi,OFFSET open_dir32
    mov edi,OFFSET open_dir_name
    mov dx,virt_es_in
    mov ecx,UG_SYSCALL_WR_PAR_ES_EDI
    mov ax,open_dir_nr
    RegisterSyscall
;
    mov ebx,OFFSET read_dir16
    mov esi,OFFSET read_dir32
    mov edi,OFFSET read_dir_name
    mov dx,virt_es_in
    mov ecx,UG_SYSCALL_WR_PAR_ES_EDI
    mov ax,read_dir_nr
    RegisterSyscall
;
    mov esi,OFFSET close_dir
    mov edi,OFFSET close_dir_name
    xor dx,dx
    xor ecx,ecx
    mov ax,close_dir_nr
    RegisterBimodalSyscall
;
    ret
init_dir    ENDP

code    ENDS

    END
