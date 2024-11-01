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
; FILE.ASM
; File module
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

file_handle_interface    STRUC

fhi_base    handle_entry_interface <>
fhi_pos     DD ?

file_handle_interface    ENDS

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

fs_file_list    DW ?
fs_file_section     section_typ <>

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InsertFileSel
;
;           DESCRIPTION:    Insert a file selector
;
;           PARAMETERS:     BX      File selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertFileSel   Proc near
    push ds
    push es
    push eax
    push ebx
    push di
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:fs_file_section
;
    mov es,bx
    mov di,ds:fs_file_list
    or di,di
    je ins_file_sel_empty
;
    push ds
    push si
    mov ds,di
    mov si,ds:file_prev
    mov ds:file_prev,es
    mov ds,si
    mov ds:file_next,es
    mov es:file_next,di
    mov es:file_prev,si
    pop si
    pop ds
    jmp ins_file_sel_leave
    
ins_file_sel_empty:
    mov es:file_next,es
    mov es:file_prev,es
    mov ds:fs_file_list,es

ins_file_sel_leave:
    LeaveSection ds:fs_file_section
;
    pop di
    pop ebx
    pop eax
    pop es
    pop ds
    ret
InsertFileSel Endp      


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveFileSel
;
;           DESCRIPTION:    Remove a file selector
;
;           PARAMETERS:     BX      File selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveFileSel   Proc near
    push ds
    push eax
    push ebx
    push si
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:fs_file_section
;
    mov ax,ds:fs_file_list
    or ax,ax
    jz rem_file_sel_leave
;    
    mov si,ax

rem_file_sel_check:
    mov es,ax
    cmp ax,bx
    je rem_file_sel_ok
;
    mov ax,es:file_next
    cmp ax,si
    jne rem_file_sel_check
;
    jmp rem_file_sel_leave

rem_file_sel_ok:
    mov es,bx
    cmp bx,es:file_next
    je rem_file_sel_empty
;       
    push di
    push ds
    mov di,es:file_next
    mov ds:fs_file_list,di
    mov si,es:file_prev
    mov ds,di
    mov ds:file_prev,si
    mov ds,si
    mov ds:file_next,di
    pop ds
    pop di
    jmp rem_file_sel_leave

rem_file_sel_empty:     
    mov ds:fs_file_list,0

rem_file_sel_leave:
    LeaveSection ds:fs_file_section
    pop si
    pop ebx
    pop eax
    pop ds 
    ret
RemoveFileSel Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateListEntry
;
;           DESCRIPTION:    Create a new list entry
;
;           PARAMETERS:         DS              File selector
;                           EAX             Position entry
;
;           RETURNS:        EAX             Base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateListEntry Proc near
    push bx
    push ecx
    push edx
    push esi
    push edi
;
    mov esi,eax
    mov al,ds:file_drive
    mov bx,ds
    CallFileSystem fs_allocate_file_list_proc
;
    mov es:[edi].fl_usage,0
    mov es:[edi].fl_ref_count,1
    mov es:[edi].fl_size,eax
    mov es:[edi].fl_base,0
    mov es:[edi].fl_sel,ds
    mov es:[edi].fl_state, FILE_LIST_STATE_EMPTY
    mov es:[edi].fl_flags,0
    mov es:[edi].fl_prev_small,0
    mov es:[edi].fl_next_small,0
    mov es:[edi].fl_pos,esi
    mov eax,edi
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop bx
    ret
CreateListEntry Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeListEntry
;
;           DESCRIPTION:    Free a list entry
;
;           PARAMETERS:         DS              File selector
;                           EAX             Base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeListEntry   Proc near
    push eax
    push bx
    push ecx
    push edx
    push edi
;
    mov edi,eax
;
    mov eax,es:[edi].fl_pos
    mov dword ptr es:[eax],0
    mov edx,es:[edi].fl_base
    or edx,edx
    jz free_list_done
;
    mov es:[edi].fl_state, FILE_LIST_STATE_EMPTY
    mov ecx,ds:file_block_size
    cmp ecx,1000h
    jc free_small_list
;
    mov al,ds:file_drive
    mov bx,ds
    CallFileSystem fs_free_file_list_proc
    FreeLinear
    jmp free_list_done

free_small_list:
    push edi
    push esi

free_small_start_loop:
    mov esi,edi
    test dx,0FFFh
    jz free_small_start_found
;
    mov eax,es:[edi].fl_prev_small
    or eax,eax
    jz free_small_fail
;
    mov edi,eax
    mov edx,es:[edi].fl_base
    test es:[edi].fl_state, FILE_LIST_STATE_EMPTY
    je free_small_start_loop
    jmp free_small_fail

free_small_start_found:
    xchg esi,edi

free_small_end_loop:
    mov eax,es:[edi].fl_next_small
    or eax,eax
    jz free_small_do
;
    mov edi,eax
    mov eax,es:[edi].fl_base
    test ax,0FFFh
    jz free_small_do
;
    test es:[edi].fl_state, FILE_LIST_STATE_EMPTY
    jne free_small_fail
    jmp free_small_end_loop

free_small_do:
    mov edi,esi

free_small_unlink_loop:
    mov es:[edi].fl_base,0
    mov es:[edi].fl_prev_small,0
    xor eax,eax
    xchg eax,es:[edi].fl_next_small
    or eax,eax
    jz free_small_unlink_done
;
    mov edi,eax
    mov eax,es:[edi].fl_base
    test ax,0FFFh
    jnz free_small_unlink_loop

free_small_unlink_done:
    mov ecx,1000h
    FreeLinear

free_small_fail:
    pop esi
    pop edi
    mov al,ds:file_drive
    mov bx,ds
    CallFileSystem fs_free_file_list_proc

free_list_done:
    pop edi
    pop edx
    pop ecx
    pop bx
    pop eax
    ret
FreeListEntry   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateListDir
;
;           DESCRIPTION:    Create a new list directory
;
;           PARAMETERS:         DS              File selector
;
;           RETURNS:        EBX             Base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateListDir   Proc near
    push ecx
    push edx
    push edi
;
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov ebx,edx
;
    pop edi
    pop edx
    pop ecx
    ret
CreateListDir   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeListDir
;
;           DESCRIPTION:    Free a list directory
;
;           PARAMETERS:         DS              File selector
;                           EBX             Base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeListDir     Proc near
    push es
    push ax
    push ebx
    push ecx
    push edx
    push edi
;
    mov ax,flat_sel
    mov es,ax
;
    mov edx,ebx
    mov cx,400h

free_list_dir_loop:
    mov eax,es:[ebx]
    or eax,eax
    jz free_list_dir_next
;
    call FreeListEntry

free_list_dir_next:
    add ebx,4
    loop free_list_dir_loop
;
    mov ecx,1000h
    FreeLinear
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop ax
    pop es
    ret
FreeListDir     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RequestFileSel
;
;           DESCRIPTION:    Request a file selector
;
;           PARAMETERS:     FS:EDX          File dir entry
;                           DS              Dir sel
;
;           RETURNS:        BX              File selector
;                           AL              Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RequestFileSel

RequestFileSel   PROC near
    push es
    push ecx
    push edx
    push esi
    push edi
;
    push ds
    mov esi,edx
    mov al,ds:ds_drive
    EnterSection ds:ds_list_section
;
    mov bx,fs:[esi].dfe_file_sel
    or bx,bx
    jnz req_file_inc
;
    mov ah,fs:[esi].de_attrib
    mov bx,ax
    test ah,80h
    jnz req_file_skip_lists
;
    mov al,bl
    push esi
    push edi
    GetDriveParam
    pop edi
    pop esi
    jnc req_file_ok_params
;
    mov eax,1000h
    mov ecx,1000h

req_file_ok_params:
    mov edx,ecx
    dec eax
    xor cl,cl

req_file_block_loop:
    inc cl
    shr eax,1
    jnz req_file_block_loop
;
    mov eax,1
    shl eax,cl
    dec edx
    add cl,10
    shr edx,cl
    inc edx
;
    push eax
    mov eax,edx
    shl eax,2
    add eax,SIZE file_data_struc - 4
    AllocateSmallGlobalMem
    mov es:file_dir_sel,ds
    InitSysHandle
;
    mov ax,es
    mov ds,ax
    pop eax
;
    mov ds:file_block_size,eax
    mov ds:file_dir_entries,dx
    mov ds:file_dir_shift,cl
    sub cl,10
    mov ds:file_entry_shift,cl
;
    mov cx,dx
    mov di,OFFSET file_entries
    xor eax,eax
    rep stosd
    jmp req_file_init

req_file_skip_lists:
    mov eax,SIZE file_data_struc - 4
    AllocateSmallGlobalMem
    mov es:file_dir_sel,ds
    InitSysHandle
;
    mov ax,es
    mov ds,ax
    mov ds:file_block_size,0
    mov ds:file_dir_entries,0

req_file_init:
    InitReadWriteSection ds:file_size_section
    InitSection ds:file_list_section
    mov ds:file_usage,1
    mov ds:file_c_handle,0
    mov ds:file_read_handle,0
    mov ds:file_drive,bl
    mov ds:file_dir_entry,esi
;
    mov ah,fs:[esi].de_attrib
    mov ds:file_attrib,bh

    mov ecx,fs:[esi].dfe_data_size
    mov ds:file_size,ecx
;
    mov bx,ds
    call InsertFileSel
;
    mov fs:[esi].dfe_file_sel,bx
    jmp req_file_leave

req_file_inc:
    mov ds,bx
    add ds:file_usage,1

req_file_leave:
    pop ds
    LeaveSection ds:ds_list_section
    mov al,ds:ds_drive
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop es
    ret
RequestFileSel   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GrowFileSel
;
;           DESCRIPTION:    Grow file selector
;
;           PARAMETERS:     BX      File selector to grow
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowFileSel     PROC near
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    movzx eax,ds:file_dir_entries
    shl eax,2
    add eax,SIZE file_data_struc
    mov ebp,eax
    AllocateSmallLinear
    mov ecx,ebp
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
;
    xor esi,esi
    sub ecx,4
    rep movs byte ptr es:[edi],ds:[esi]
    xor eax,eax
    stos dword ptr es:[edi]
    mov edi,edx
    inc es:[edi].file_dir_entries
;
    GetSelectorBaseSize
    push ecx
    push edx
;
    mov ecx,ebp
    mov edx,edi
    CreateDataSelector16
;
    mov ax,5
    WaitMilliSec
;
    pop edx
    pop ecx
    FreeLinear
;
    mov ds,bx
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
GrowFileSel ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReleaseFileSel
;
;           DESCRIPTION:    Release file selector
;
;           PARAMETERS:     BX              File selector
;
;           RETURNS:        NC              Released
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReleaseFileSel

ReleaseFileSel     PROC near
    push ds
    push es
    push ax
    push ebx
    push ecx
    push si
    push edi
;       
    mov ds,bx
    mov ds,ds:file_dir_sel
    push ds
    EnterSection ds:ds_list_section
;
    mov ds,bx
    sub ds:file_usage,1
    jnz rel_file_fail
;
    call RemoveFileSel
;    
    mov ax,flat_sel
    mov es,ax
    mov edi,ds:file_dir_entry
    mov cx,es:[edi].de_usage
    or cx,cx
    jnz rel_file_fail
;
    mov ecx,ds:file_block_size
    or ecx,ecx
    jz rel_file_sel
;
    mov cx,ds:file_dir_entries
    mov si,OFFSET file_entries

rel_file_dir_loop:
    mov ebx,[si]
    or ebx,ebx
    jz rel_file_dir_next
;
    call FreeListDir

rel_file_dir_next:
    add si,4
    loop rel_file_dir_loop

rel_file_sel:
    mov ecx,ds:file_dir_entry
    mov ax,ds
    mov es,ax
    mov ax,flat_sel
    mov ds,ax
    mov ds:[ecx].dfe_file_sel,0
    FreeMem
;
    pop ds
    LeaveSection ds:ds_list_section
    clc
    jmp rel_file_sel_done

rel_file_fail:
    pop ds
    LeaveSection ds:ds_list_section
    stc

rel_file_sel_done:
    pop edi
    pop si
    pop ecx
    pop ebx
    pop ax
    pop es
    pop ds
    ret
ReleaseFileSel     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetFileListEntry
;
;           DESCRIPTION:    Get list entry
;
;           PARAMETERS:         BX              File selector
;                           EDX             Position
;
;           RETURNS:        EAX             List selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_list_entry_name    DB 'Get File List Entry',0

get_file_list_entry     Proc far
    push ds
    push es
    push ebx
    push cx
    push esi
;
    mov ds,bx
    mov ax,flat_sel
    mov es,ax
;
    mov eax,ds:file_size
    dec eax
    and ax,0F000h
    add eax,1000h
    cmp edx,eax
    jnc get_list_fail
;
    mov esi,edx
    mov cl,ds:file_dir_shift
    shr esi,cl

get_list_size_retry:
    cmp si,ds:file_dir_entries
    jb get_list_size_ok
;
    mov bx,ds
    call GrowFileSel
    mov ds,bx
    jmp get_list_size_retry

get_list_size_ok:
    shl si,2
    mov ebx,ds:[si].file_entries
    or ebx,ebx
    jnz get_list_check_mid
;
    call CreateListDir
    mov ds:[si].file_entries,ebx

get_list_check_mid:
    mov esi,edx
    mov cl,ds:file_entry_shift
    shr esi,cl
    shl si,2
    and esi,0FFCh
    mov eax,es:[ebx+esi]
    or eax,eax
    clc
    jnz get_list_done
;
    lea eax,[ebx+esi]
    call CreateListEntry
    mov es:[ebx+esi],eax
    clc
    jmp get_list_done

get_list_fail:
    stc

get_list_done:
    pop esi
    pop cx
    pop ebx
    pop es
    pop ds
    retf32
get_file_list_entry     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeFileListEntry
;
;           DESCRIPTION:    Free a file list entry
;
;           PARAMETERS:     BX              File selector
;                           EDI             File list entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_file_list_entry_name       DB 'Free File List Entry',0

free_file_list_entry    Proc far
    push ds
    push eax
;
    mov ds,bx
    mov eax,edi
    call FreeListEntry
;
    pop eax
    pop ds
    retf32
free_file_list_entry    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadFileListEntry
;
;           DESCRIPTION:    Read a file list entry
;
;           PARAMETERS:         DS              File selector
;                           EDI             File list entry
;                           EDX             File position                       
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadFileListEntry       Proc near
    mov eax,es:[edi].fl_base
    or eax,eax
    jnz read_file_list_do
;
    mov eax,ds:file_block_size
    cmp eax,1000h
    jc read_alloc_small
;
    push ecx
    push edx
    AllocateBigLinear
    mov es:[edi].fl_base,edx
    pop edx
    pop ecx
    jmp read_file_list_do

read_alloc_small:
    push bx
    push edx
    push esi
    push edi
;
    push ecx
    push edx
    mov eax,1000h
    AllocateBigLinear
    mov esi,edx
    pop edx
    pop ecx
;
    mov bx,ds
    mov eax,ds:file_block_size
    neg eax
    and edx,eax

read_small_start_loop:
    test dx,0FFFh
    jz read_small_start_found
;
    sub edx,ds:file_block_size
    GetFileListEntry
    mov edi,eax
    jmp read_small_start_loop

read_small_start_found:
    mov es:[edi].fl_prev_small,0

read_small_loop:
    mov es:[edi].fl_next_small,0
    mov es:[edi].fl_base,esi
    add esi,ds:file_block_size
    add edx,ds:file_block_size
    test dx,0FFFh
    jz read_small_done
;
    GetFileListEntry
    jc read_small_done
;
    mov es:[edi].fl_next_small,eax
    mov es:[eax].fl_prev_small,edi
    mov edi,eax
    jmp read_small_loop

read_small_done:
    pop edi
    pop esi
    pop edx
    pop bx
    
read_file_list_do:
    mov es:[edi].fl_state, FILE_LIST_STATE_USED
    push edx
    push ecx
    mov eax,ds:file_block_size
    mov ecx,eax
    neg eax
    and edx,eax
    push bx
    mov al,ds:file_drive
    mov bx,ds
    CallFileSystem fs_read_file_block_proc
    pop bx
    pop ecx
    pop edx
    ret
ReadFileListEntry       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           swap_file_list
;
;           DESCRIPTION:    Free file list entry, if possible
;
;           PARAMETERS:         DS      File selector
;               ES:EDI  Dir array
;               EAX     File list entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_file_list  Proc near
    inc ebp
    mov dx,es:[eax].fl_usage
    or dx,dx
    jnz swap_list_done
;
    mov dx,es:[eax].fl_ref_count
    cmp dx,4
    jbe swap_list_handle_ref
;
    mov dx,4

swap_list_handle_ref:
    dec dx
    mov es:[eax].fl_ref_count,dx
    or dx,dx
    jnz swap_list_done
;
    dec ebp
    call FreeListEntry 

swap_list_done:   
    ret
swap_file_list  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           swap_dir
;
;           DESCRIPTION:    Free physical memory in file directory
;
;           PARAMETERS:         DS      File selector
;               ES:EDI     Dir array
;
;       RETURNS:    EBP     Entry count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_dir    Proc near
    xor ebp,ebp
    mov ecx,400h

swap_dir_loop:    
    or ecx,ecx
    jz swap_dir_done
;    
    xor eax,eax
    repz scas dword ptr es:[edi]
    mov eax,es:[edi-4]
    or eax,eax
    jz swap_dir_loop
;
    call swap_file_list
    jmp swap_dir_loop

swap_dir_done:    
    ret
swap_dir    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           swap_file
;
;           DESCRIPTION:    Free physical memory in file
;
;           PARAMETERS:         DS      File selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_file   Proc near
    push es
    pushad
;    
    EnterSection ds:file_list_section
    mov ax,flat_sel
    mov es,ax
    test ds:file_attrib, FILE_ATTRIB_NOBUFFER
    jnz swap_file_done
;
    mov cx,ds:file_dir_entries
    mov si,OFFSET file_entries

swap_file_loop:    
    mov edi,ds:[si]
    or edi,edi
    jz swap_file_next
;
    push cx
    push si
    call swap_dir
    pop si
    pop cx
;    
    or ebp,ebp
    jnz swap_file_next
;
    push ecx
    xor edx,edx
    xchg edx,ds:[si]
    mov ecx,1000h    
    FreeLinear
    pop ecx
    
swap_file_next:
    add si,4
    loop swap_file_loop

swap_file_done:
    LeaveSection ds:file_list_section
;    
    popad
    pop es
    ret
swap_file   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           swap_all
;
;           DESCRIPTION:    Free physical memory in all files
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_all    Proc near
    push ds
    push es
    push ax
    push bx
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:fs_file_section
;    
    mov bx,ds:fs_file_list

swap_all_loop:  
    push ds
    mov ds,bx
    EnterWriteSection ds:file_size_section
    call swap_file
    LeaveWriteSection ds:file_size_section
    pop ds
;
    mov es,bx
    mov bx,es:file_next
    cmp bx,ds:fs_file_list
    jne swap_all_loop
;    
    xor ax,ax
    mov es,ax
    LeaveSection ds:fs_file_section
;
    pop bx
    pop ax
    pop es
    pop ds
    ret
swap_all    Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFileDirSize
;
;           DESCRIPTION:    Get size of file directory buffer
;
;           PARAMETERS:     DS         File selector
;                           ES:EDI     Dir array
;                           EBP        Size in
;
;           RETURNS:        EBP        Size out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFileDirSize    Proc near
    push eax
    push ecx
    push edi
;
    mov ecx,400h

gfdsLoop:    
    mov eax,es:[edi]
    or eax,eax
    jz gfdsNext
;
    mov eax,es:[eax].fl_base
    or eax,eax
    jz gfdsNext
;
    add ebp,ds:file_block_size

gfdsNext:
    add edi,4
    loop gfdsLoop
;
    pop edi
    pop ecx
    pop eax
    ret
GetFileDirSize    Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetOneFileCacheSize
;
;           DESCRIPTION:    Get one file cache size
;
;           PARAMETERS:     DS      File selector
;
;           RETURNS:        EAX     Cache size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetOneFileCacheSize   Proc near
    push es
    push cx
    push si
    push edi
    push ebp
;    
    xor ebp,ebp
    EnterSection ds:file_list_section
    mov ax,flat_sel
    mov es,ax
    test ds:file_attrib, FILE_ATTRIB_NOBUFFER
    jnz gfcsDone
;
    mov cx,ds:file_dir_entries
    mov si,OFFSET file_entries

gfcsLoop:    
    mov edi,ds:[si]
    or edi,edi
    jz gfcsNext
;
    call GetFileDirSize    
    add ebp,1000h    
    
gfcsNext:
    add si,4
    loop gfcsLoop

gfcsDone:
    LeaveSection ds:file_list_section    
    mov eax,ebp
;
    pop ebp
    pop edi
    pop si
    pop cx
    pop es
    ret
GetOneFileCacheSize   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFileCacheSize
;
;           DESCRIPTION:    Get cache size for all files
;
;           RETURNS:        EAX		Size of file cache
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_file_cache_size_name        DB 'Get File Cache Size', 0

get_file_cache_size       Proc far
    push ds
    push es
    push bx
    push ebp
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:fs_file_section
;    
    mov bx,ds:fs_file_list
    xor ebp,ebp

gfcLoop:  
    push ds
    mov ds,bx
    EnterWriteSection ds:file_size_section
    call GetOneFileCacheSize
    add ebp,eax
    LeaveWriteSection ds:file_size_section
    pop ds
;
    mov es,bx
    mov bx,es:file_next
    cmp bx,ds:fs_file_list
    jne gfcLoop
;    
    xor ax,ax
    mov es,ax
    LeaveSection ds:fs_file_section
    mov eax,ebp
;

    pop ebp
    pop bx
    pop es
    pop ds
    retf32
get_file_cache_size    Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           read file
;
;           DESCRIPTION:    Reads from a file
;
;           PARAMETERS:         AL              Drive
;                           DS              File selector
;                           ECX             Size
;                           EDX             Position
;                           ES:EDI      Data buffer
;
;           RETURNS:        EAX             Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_file       Proc near
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    xor ebp,ebp
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
;    
    push edx
    GetFreePhysical
    or edx,edx
    jz read_file_low
;
    mov eax,0FFFFFFFFh

read_file_low:
    pop edx
;    
    cmp eax,100000h
    ja read_file_mem_all_ok
;
    call swap_all 

read_file_mem_all_ok:   
    EnterReadSection ds:file_size_section
    cmp edx,ds:file_size
    jnc read_file_done
;
    mov eax,edx
    add eax,ecx
    sub eax,ds:file_size
    jc read_file_size_ok
;
    sub ecx,eax

read_file_size_ok:
    or ecx,ecx
    jz read_file_done

read_file_loop:
    push edx
    GetFreePhysical
    or edx,edx
    jz read_file_loop_low
;
    mov eax,0FFFFFFFFh

read_file_loop_low:
    pop edx
    cmp eax,100000h
    ja read_file_mem_ok
;
    call swap_file

read_file_mem_ok:
    push cx
    mov esi,edx
    mov cl,ds:file_dir_shift
    shr esi,cl
    shl si,2
    EnterSection ds:file_list_section
    mov ebx,ds:[si].file_entries
    or ebx,ebx
    jnz read_file_check_mid
;
    call CreateListDir
    mov ds:[si].file_entries,ebx

read_file_check_mid:
    mov esi,edx
    mov cl,ds:file_entry_shift
    shr esi,cl
    shl si,2
    and esi,0FFCh
    pop cx
    mov eax,es:[ebx+esi]
    or eax,eax
    jnz read_file_check_base
;
    lea eax,[ebx+esi]
    call CreateListEntry
    mov es:[ebx+esi],eax

read_file_check_base:
    cmp es:[eax].fl_state, FILE_LIST_STATE_EMPTY
    jne read_file_do_first
;
    push edi
    mov edi,eax
    call ReadFileListEntry
    pop edi
    jnc read_file_do_first
;
    mov dword ptr es:[ebx+esi],0
    LeaveSection ds:file_list_section
    jmp read_file_done

read_file_do_first:
    mov esi,es:[ebx+esi]
    inc es:[esi].fl_usage
    inc es:[esi].fl_ref_count
    LeaveSection ds:file_list_section
;
    push ds
    push es
    push edx
    push esi
;
    mov ebx,ds:file_block_size
    mov esi,es:[esi].fl_base
    mov ax,fs
    mov es,ax
    mov ax,flat_sel
    mov ds,ax
;
    mov eax,ebx
    dec eax
    and edx,eax
    add esi,edx
;
    sub ebx,edx
    cmp ecx,ebx
    jnc read_file_do
;
    mov ebx,ecx

read_file_do:
    push ecx
    mov ecx,ebx
    shr ecx,2
    rep movs dword ptr es:[edi],ds:[esi]
    mov ecx,ebx
    and ecx,3
    rep movs byte ptr es:[edi],ds:[esi]
    pop ecx
;
    pop esi
    pop edx
    pop es
    pop ds
    dec es:[esi].fl_usage
;
    add edx,ebx
    add ebp,ebx
    sub ecx,ebx
    jnz read_file_loop
;
    clc

read_file_done:
    pushf
    LeaveReadSection ds:file_size_section
    popf
    mov eax,ebp
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    ret
read_file       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           read_legacy_file
;
;           DESCRIPTION:    Reads from legacy file
;
;           PARAMETERS:     BX              File selector
;                           ECX             Size
;                           EDX:EAX         Position
;                           ES:EDI          Data buffer
;
;           RETURNS:        ECX             Bytes read
;                           EDX:EAX         Update position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_legacy_file_name        DB 'Read Legacy File', 0

read_legacy_file       Proc far
    push ds
    push bx
;
    or edx,edx
    stc
    jnz rcfDone
;
    mov edx,eax
    mov ds,bx
    mov al,ds:file_drive
    test ds:file_attrib, FILE_ATTRIB_NOBUFFER
    jz rcfBuf
;
    CallFileSystem fs_read_file_proc
    jmp rcfCheck

rcfBuf:
    call read_file

rcfCheck:    
    jc rcfDone
;
    mov ecx,eax
    add eax,edx
    xor edx,edx
    clc

rcfDone:
    pop bx
    pop ds
    retf32
read_legacy_file     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           write file
;
;           DESCRIPTION:    Write to a file
;
;           PARAMETERS:         AL              Drive
;                           DS              File selector
;                           ECX             Size
;                           EDX             Position
;                           ES:EDI      Data buffer
;
;           RETURNS:        EAX             Bytes written
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_file      Proc near
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    xor ebp,ebp
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
;    
    push edx
    GetFreePhysical
    or edx,edx
    jz write_file_low
;
    mov eax,0FFFFFFFFh

write_file_low:
    pop edx
    cmp eax,100000h
    ja write_file_mem_all_ok
;
    call swap_all 

write_file_mem_all_ok:  
    EnterWriteSection ds:file_size_section
    cmp edx,ds:file_size
    jnc write_file_extend
;
    mov eax,edx
    add eax,ecx
    sub eax,ds:file_size
    jc write_file_size_ok

write_file_extend:
    push edx
    add edx,ecx
    mov bx,ds
    mov al,ds:file_drive
    CallFileSystem fs_set_file_size_proc
    pop edx
;
    push bx
    xor bx,bx
    xchg bx,ds:file_read_handle
    or bx,bx
    jz write_file_signal_ok
;
    SignalReadHandle

write_file_signal_ok:
    pop bx

write_file_size_ok:
    or ecx,ecx
    jz write_file_done

write_file_loop:
    push edx
    GetFreePhysical
    or edx,edx
    jz write_file_loop_low
;
    mov eax,0FFFFFFFFh

write_file_loop_low:
    pop edx
    cmp eax,100000h
    ja write_file_mem_ok
;
    call swap_file

write_file_mem_ok:
    push cx
    mov esi,edx
    mov cl,ds:file_dir_shift
    shr esi,cl

write_file_retry_entry:
    cmp si,ds:file_dir_entries
    jb write_file_entries_ok
;
    mov bx,ds
    call GrowFileSel
    mov ds,bx
    jmp write_file_retry_entry

write_file_entries_ok:  
    shl si,2
    EnterSection ds:file_list_section
    mov ebx,ds:[si].file_entries
    or ebx,ebx
    jnz write_file_check_mid
;
    call CreateListDir
    mov ds:[si].file_entries,ebx

write_file_check_mid:
    mov esi,edx
    mov cl,ds:file_entry_shift
    shr esi,cl
    shl si,2
    and esi,0FFCh
    pop cx
    mov eax,es:[ebx+esi]
    or eax,eax
    jnz write_file_check_base
;
    lea eax,[ebx+esi]
    call CreateListEntry
    mov es:[ebx+esi],eax

write_file_check_base:
    cmp es:[eax].fl_state, FILE_LIST_STATE_EMPTY
    jne write_file_do_first
;
    push edi
    mov edi,eax
    call ReadFileListEntry
    pop edi
    jnc write_file_do_first
;
    mov dword ptr es:[ebx+esi],0
    LeaveSection ds:file_list_section
    jmp write_file_done

write_file_do_first:
    mov esi,es:[ebx+esi]
    inc es:[esi].fl_usage
    inc es:[esi].fl_ref_count
    LeaveSection ds:file_list_section
;
    push ds
    push es
    push edx
    push esi
    push edi
;
    mov ebx,ds:file_block_size
    mov esi,es:[esi].fl_base
    xchg esi,edi
    mov ax,fs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;
    mov eax,ebx
    dec eax
    and edx,eax
    add edi,edx
;
    sub ebx,edx
    cmp ecx,ebx
    jnc write_file_do
;
    mov ebx,ecx

write_file_do:
    push ecx
    mov ecx,ebx
    shr ecx,2
    rep movs dword ptr es:[edi],ds:[esi]
    mov ecx,ebx
    and ecx,3
    rep movs byte ptr es:[edi],ds:[esi]
    pop ecx
;
    pop edi
    pop esi
    pop edx
    pop es
    pop ds
;
    push bx
    push ecx
    push edi
    mov edi,esi
    mov ecx,ebx
    mov al,ds:file_drive
    mov bx,ds
    CallFileSystem fs_write_file_block_proc
    pop edi
    pop ecx
    pop bx  
;
    dec es:[esi].fl_usage
    add edx,ebx
    add ebp,ebx
    add edi,ebx
    sub ecx,ebx
    jnz write_file_loop
;
    clc

write_file_done:
    pushf
    LeaveWriteSection ds:file_size_section
    popf
    mov eax,ebp
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    ret
write_file      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           write_legacy_file
;
;           DESCRIPTION:    Writes to legacy file
;
;           PARAMETERS:     BX              File selector
;                           ECX             Size
;                           EDX:EAX         Position
;                           ES:EDI          Data buffer
;
;           RETURNS:        ECX             Bytes read
;                           EDX:EAX         Update position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_legacy_file_name       DB 'Write Legacy File', 0

write_legacy_file       Proc far
    push ds
    push bx
;
    or edx,edx
    stc
    jnz wcfDone
;
    mov edx,eax
    mov ds,bx
    cmp edx,ds:file_size
    jbe wcfDo
;
    push es
    push edi
    push ecx
    push edx
;
    mov eax,1000h
    AllocateGlobalMem
;
    xor di,di
    mov cx,400h
    xor eax,eax
    rep stosd
    xor edi,edi
;
    mov ecx,edx
    sub ecx,ds:file_size
    mov edx,ds:file_size

wcfFillLoop:
    push ecx
;
    cmp ecx,1000h
    jbe wcfFillDo
;
    mov ecx,1000h

wcfFillDo:
    mov al,ds:file_drive
    test ds:file_attrib, FILE_ATTRIB_NOBUFFER
    jz wcfFillBuf
;
    CallFileSystem fs_write_file_proc
    jmp wcfFillCheck

wcfFillBuf:
    call write_file

wcfFillCheck:
    mov eax,ecx
;
    pop ecx
    add edx,eax
    sub ecx,eax
    jnz wcfFillLoop
;       
    FreeMem
;
    pop edx
    pop ecx
    pop edi
    pop es

wcfDo:
    mov al,ds:file_drive
;
    push es
    push edx
;
    push eax
    push esi
    mov ax,flat_sel
    mov es,ax
    mov esi,ds:file_dir_entry
    GetTime
    mov es:[esi].de_time,eax
    mov es:[esi].de_time+4,edx
    mov edx,esi
    pop esi
    pop eax
;
    CallFileSystem fs_update_file_proc
;
    pop edx
    pop es
;
    mov al,ds:file_drive
    test ds:file_attrib, FILE_ATTRIB_NOBUFFER
    jz wcfDoBuf
;
    CallFileSystem fs_write_file_proc
    jmp wcfDoCheck

wcfDoBuf:
    call write_file

wcfDoCheck:
    jc wcfDone
;
    mov ecx,eax
    add eax,edx
    xor edx,edx
    clc

wcfDone:
    pop bx
    pop ds
    retf32
write_legacy_file    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           close_legacy_file
;
;           DESCRIPTION:    Close legacy file
;
;           PARAMETERS:     BX              File selector
;                           NC              Success
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_legacy_file_name DB 'Close Legacy File',0

close_legacy_file    Proc far
    push ds
;
    or bx,bx
    stc
    jz ccfDone
;
    mov ds,bx
    mov ds:file_c_handle,0
;
    call ReleaseFileSel
    clc

ccfDone:
    pop ds
    retf32
close_legacy_file    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_legacy_file_size
;
;           DESCRIPTION:    Get legacy file size
;
;           PARAMETERS:     BX              File selector
;                   
;           RETURNS:        EDX:EAX             Size
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_legacy_file_size_name      DB 'Get Legacy File Size',0

get_legacy_file_size Proc far
    push ds
;
    or bx,bx
    stc
    jz gcfsDone
;
    mov ds,bx
    EnterReadSection ds:file_size_section
    mov eax,ds:file_size
    xor edx,edx
    LeaveReadSection ds:file_size_section
    clc

gcfsDone:
    pop ds
    retf32
get_legacy_file_size Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_legacy_file_size
;
;           DESCRIPTION:    Set legacy file size
;
;           PARAMETERS:     BX              File selector
;                           EAX             New size
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_legacy_file_size_name      DB 'Set Legacy File Size',0

set_legacy_file_size Proc far
    push ds
    push eax
    push edx
;
    or bx,bx
    stc
    jz scfsDone
;
    mov edx,eax
    mov ds,bx
    mov al,ds:file_drive
    EnterWriteSection ds:file_size_section
    CallFileSystem fs_set_file_size_proc
    LeaveWriteSection ds:file_size_section

scfsDone:
    pop edx
    pop eax
    pop ds
    retf32
set_legacy_file_size Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_legacy_file_time
;
;           DESCRIPTION:    Get C file time & date
;
;           PARAMETERS:     BX          File sel
;               
;           RETURNS:        EDX:EAX     File time
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_legacy_file_time_name      DB 'Get Legacy File Time',0

get_legacy_file_time Proc far
    push ds
    push es
;
    or bx,bx
    stc
    jz gftDone
;
    mov ds,bx
    mov dx,flat_sel
    mov es,dx
    mov edx,ds:file_dir_entry
    mov eax,es:[edx].de_time
    mov edx,es:[edx].de_time+4
    clc

gftDone:
    pop es
    pop ds
    retf32
get_legacy_file_time Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           set_legacy_file_time
;
;           DESCRIPTION:    Set C file time & date
;
;           PARAMETERS:     BX          File selector
;                           EDX:EAX     New time & date
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_legacy_file_time_name      DB 'Set Legacy File Time',0

set_legacy_file_time Proc far
    push ds
    push es
    push fs
    push ax
    push ebx
    push ecx
    push edx
    push edi
;
    mov cx,flat_sel
    mov es,cx
    mov ecx,eax
;
    or bx,bx
    stc
    jz sftDone
;
    mov fs,bx
    mov al,fs:file_drive
    mov edi,fs:file_dir_entry
    mov es:[edi].de_time,ecx
    mov es:[edi].de_time+4,edx
    mov edx,edi
    CallFileSystem fs_update_file_proc
    clc

sftDone:
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop ax
    pop fs
    pop es
    pop ds
    retf32
set_legacy_file_time Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartReadLegacyFile
;
;       DESCRIPTION:    Start read file
;
;       PARAMETERS;     IN  BX        File selector
;                       IN  AX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_read_legacy_file_name DB 'Start Read Legacy File', 0

start_read_legacy_file    Proc far
    push ds
;
    or bx,bx
    jz srcfDone
;
    mov ds,bx
    mov ds:file_read_handle,ax
    jmp srcfDone

srcfSignal:
    SignalReadHandle

srcfDone:
    pop ds
    retf32
start_read_legacy_file    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StopReadLegacyFile
;
;       DESCRIPTION:    Stop read file
;
;       PARAMETERS;     IN  BX        File selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_read_legacy_file_name DB 'Stop Read Legacy File', 0

stop_read_legacy_file    Proc far
    push ds
;
    or bx,bx
    stc
    jz ercfDone
;
    mov ds,bx
    mov ds:file_read_handle,0

ercfDone:
    pop ds
    retf32
stop_read_legacy_file    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           swap_proc
;
;           DESCRIPTION:    Free physical memory in file buffers
;
;           PARAMETERS:         AL      Swapper run level (0 = free all, 15 = preventive)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_proc       Proc far
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:fs_file_section
;    
    mov bx,ds:fs_file_list

swap_loop:      
    push ds
    mov ds,bx
    EnterWriteSection ds:file_size_section
    call swap_file
    LeaveWriteSection ds:file_size_section
    pop ds
;
    mov es,bx
    mov bx,es:file_next
    cmp bx,ds:fs_file_list
    jne swap_loop
;    
    xor ax,ax
    mov es,ax
    LeaveSection ds:fs_file_section
    retf32
swap_proc       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteHandleObj
;
;           DESCRIPTION:    Delete handle obj
;
;           PARAMETERS:     DS     Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DeleteHandleObj   Proc far
    clc
    retf32
DeleteHandleObj   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateHandleObj
;
;           DESCRIPTION:    Create new handle obj
;
;           PARAMETERS:     DS     Sys interface
;
;           RETURNS:        AX     Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateHandleObj

CreateHandleObj   Proc far
    push es
    push ebx
    push ecx
;
    mov eax,SIZE file_handle_interface
    AllocateSmallLinear
;
    push ds
    AllocateLdt
    pop ds
;
    or bx,4
    mov ecx,eax
    CreateDataSelector32
    mov es,bx
;
    InitHandle
    mov es:fhi_pos,0
;
    mov es:hei_delete_proc,OFFSET DeleteHandleObj
    mov es:hei_delete_proc+4,cs
;
    mov ax,es
;
    pop ecx
    pop ebx
    pop es
    retf32
CreateHandleObj   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_file

init_file       PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET swap_proc
    RegisterSwapProc
;
    mov esi,OFFSET get_file_list_entry
    mov edi,OFFSET get_file_list_entry_name
    xor cl,cl
    mov ax,get_file_list_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET free_file_list_entry
    mov edi,OFFSET free_file_list_entry_name
    xor cl,cl
    mov ax,free_file_list_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET close_legacy_file
    mov edi,OFFSET close_legacy_file_name
    xor cl,cl
    mov ax,close_legacy_file_nr
    RegisterOsGate
;
    mov esi,OFFSET read_legacy_file
    mov edi,OFFSET read_legacy_file_name
    xor cl,cl
    mov ax,read_legacy_file_nr
    RegisterOsGate
;
    mov esi,OFFSET write_legacy_file
    mov edi,OFFSET write_legacy_file_name
    xor cl,cl
    mov ax,write_legacy_file_nr
    RegisterOsGate
;
    mov esi,OFFSET get_legacy_file_size
    mov edi,OFFSET get_legacy_file_size_name
    xor cl,cl
    mov ax,get_legacy_file_size_nr
    RegisterOsGate
;
    mov esi,OFFSET set_legacy_file_size
    mov edi,OFFSET set_legacy_file_size_name
    xor cl,cl
    mov ax,set_legacy_file_size_nr
    RegisterOsGate
;
    mov esi,OFFSET get_legacy_file_time
    mov edi,OFFSET get_legacy_file_time_name
    xor cl,cl
    mov ax,get_legacy_file_time_nr
    RegisterOsGate
;
    mov esi,OFFSET set_legacy_file_time
    mov edi,OFFSET set_legacy_file_time_name
    xor cl,cl
    mov ax,set_legacy_file_time_nr
    RegisterOsGate
;
    mov esi,OFFSET start_read_legacy_file
    mov edi,OFFSET start_read_legacy_file_name
    xor cl,cl
    mov ax,start_read_legacy_file_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_read_legacy_file
    mov edi,OFFSET stop_read_legacy_file_name
    xor cl,cl
    mov ax,stop_read_legacy_file_nr
    RegisterOsGate
;
    mov esi,OFFSET get_file_cache_size
    mov edi,OFFSET get_file_cache_size_name
    xor dx,dx
    xor ecx,ecx
    mov ax,get_file_cache_size_nr
    RegisterBimodalSyscall
;
    mov ax,SEG data
    mov ds,ax   
    mov ds:fs_file_list,0
    InitSection ds:fs_file_section
    ret
init_file       ENDP

code    ENDS

    END
