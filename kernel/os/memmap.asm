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
; MEMMAP.ASM
; Memory-mapped file module
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
INCLUDE ..\handle.inc
INCLUDE blk.inc
INCLUDE ..\hint.inc
INCLUDE ..\fs.inc
INCLUDE exec.def

memmap_seg          STRUC

memmap_base         handle_header <>

memmap_prev         DD ?
memmap_next         DD ?
memmap_sel          DW ?
view_offset         DD ?
view_base           DD ?
view_size           DD ?

memmap_seg          ENDS

mapped_struc    STRUC

map_prev        DW ?
map_next        DW ?
map_section         section_typ <>
map_owner           DW ?
map_size        DD ?
map_base        DD ?
map_users           DW ?
map_name        DB ?

mapped_struc    ENDS

data    SEGMENT byte public 'DATA'

map_list            DW ?
map_named_list      DW ?
sys_section             section_typ <>

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateUnnamed
;
;           DESCRIPTION:    EAX             Size of filemapping object
;
;           RETURNS:        ES              File mapping selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateUnnamed   Proc near
    push ax
    push edx
;
    push eax
    mov ax,SEG data
    mov ds,ax
    mov eax,OFFSET map_name
    AllocateSmallGlobalMem
    pop eax
    dec eax
    and ax,0F000h
    add eax,1000h
    mov es:map_size,eax
    AllocateBigLinear
    mov es:map_base,edx
    mov es:map_users,1
;
    push ds
    mov ax,es
    mov ds,ax
    InitSection ds:map_section
    EnterSection ds:map_section
    pop ds    
    mov es:map_owner, OFFSET map_list
;
    EnterSection ds:sys_section
    mov ax,ds:map_list
    or ax,ax
    je create_unnamed_empty
;
    push ds
    push si
    mov ds,ax
    mov si,ds:map_prev
    mov ds:map_prev,es
    mov ds,si
    mov ds:map_next,es
    mov es:map_next,ax
    mov es:map_prev,si
    pop si
    pop ds
    jmp create_unnamed_leave

create_unnamed_empty:
    mov es:map_next,es
    mov es:map_prev,es
    mov ds:map_list,es

create_unnamed_leave:
    LeaveSection ds:sys_section
;
    pop edx
    pop ax
    ret
CreateUnnamed   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateNamed
;
;           DESCRIPTION:    EAX             Size of filemapping object
;                           ES:EDI      Name
;
;           RETURNS:        ES              File mapping selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateNamed     Proc near
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    push eax
    push es
    push edi
    xor al,al
    mov ecx,100h
    repnz scas byte ptr es:[edi]
    pop esi
    pop ds
    mov eax,100h
    sub eax,ecx
    xchg eax,ecx
    mov eax,OFFSET map_name
    add eax,ecx
    AllocateSmallGlobalMem
    mov edi,OFFSET map_name
    rep movs byte ptr es:[edi],ds:[esi]
    pop eax
    dec eax
    and ax,0F000h
    add eax,1000h
    mov es:map_size,eax
    AllocateBigLinear
    mov es:map_base,edx
    mov es:map_users,1
    mov ax,es
    mov ds,ax
    InitSection ds:map_section
    EnterSection ds:map_section
    mov es:map_owner, OFFSET map_named_list
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:sys_section
    mov ax,ds:map_named_list
    or ax,ax
    je create_named_empty
;
    push ds
    push si
    mov ds,ax
    mov si,ds:map_prev
    mov ds:map_prev,es
    mov ds,si
    mov ds:map_next,es
    mov es:map_next,ax
    mov es:map_prev,si
    pop si
    pop ds
    jmp create_named_leave

create_named_empty:
    mov es:map_next,es
    mov es:map_prev,es
    mov ds:map_named_list,es

create_named_leave:
    LeaveSection ds:sys_section
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
CreateNamed     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeView
;
;           DESCRIPTION:    DS:EBX       Mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeView    Proc near
    push es
    pushad
;
    mov esi,ebx
    mov es,ds:[esi].memmap_sel
    mov edi,ds:[esi].view_offset
    and di,0F000h
    mov dx,ds:[esi].memmap_sel
    or dx,dx
    stc
    jz fw_done
;
    mov edx,ds:[esi].view_size
    or edx,edx
    stc 
    jz fw_done
;       
    xor ecx,ecx
    xchg ecx,ds:[esi].view_size
    mov edx,ds:[esi].view_base
;
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr ecx,12

fw_loop:
    GetPageEntry
    test al,1
    jz fw_next
;
    test ax,800h
    jnz fw_mark
;
    FreePhysical

fw_mark:
    xor ebx,ebx
    mov eax,2
    SetPageEntry

fw_next:
    add edx,1000h
    add edi,1000h
    loop fw_loop

fw_done:
    clc
    popad
    pop es
    ret
FreeView    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseMapped
;
;           DESCRIPTION:    ES              File mapping selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseMapped     Proc near
    sub es:map_users,1
    jnz close_mapped_done
;
    push ax
    push si
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:sys_section
    mov si,es:map_owner
    mov [si],es
    push ds
    push si
    mov ax,es:map_next
    cmp ax,[si]
    mov [si],ax
    mov si,es:map_prev
    mov ds,ax
    mov ds:map_prev,si
    mov ds,si
    mov ds:map_next,ax
    pop si
    pop ds
    jne close_mapped_leave
;
    mov word ptr [si],0

close_mapped_leave:
    LeaveSection ds:sys_section
;
    mov ecx,es:map_size
    mov edx,es:map_base
    or edx,edx
    jz close_mapped_free_sel
;
    FreeLinear

close_mapped_free_sel:
    FreeMem
    pop si
    pop ax

close_mapped_done:
    ret
CloseMapped     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FindNamed
;
;           DESCRIPTION:    ES:EDI      Name
;
;           RETURNS:        ES              File mapping selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindNamed       Proc near
    push ax
    push ebx
    push dx
    push si
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:sys_section
    mov ax,ds:map_named_list
    or ax,ax
    je find_named_fail
;
    mov dx,ax

find_named_list:
    mov ds,ax
    mov si,OFFSET map_name
    mov ebx,edi

find_named_loop:
    lodsb
    mov ah,es:[ebx]
    inc ebx
    or al,al
    jnz find_named_match
;
    or ah,ah
    jz find_named_ok
    jmp find_named_next

find_named_match:
    cmp al,ah
    je find_named_loop

find_named_next:
    mov ax,ds:map_next
    cmp ax,dx
    jne find_named_list

find_named_fail:
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:sys_section
    stc
    jmp find_named_done

find_named_ok:
    mov dx,ds
    mov es,dx
    inc es:map_users
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:sys_section
    clc

find_named_done:
    pop si
    pop dx
    pop ebx
    pop ax
    ret
FindNamed       Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateHandle
;
;           DESCRIPTION:    ES              File mapping selector
;
;           RETURNS:        BX              File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateHandle    Proc near
    push es
    push ax
    push cx
    push esi
    push edi
;
    mov cx,SIZE memmap_seg
    AllocateHandle
    mov [ebx].memmap_sel,es
    mov [ebx].view_offset,0
    mov [ebx].view_base,0
    mov [ebx].view_size,0
;
    GetThread
    mov es,ax
    mov es,es:p_prog_sel
    RequestSpinlock es:pr_memmap_spinlock
    mov edi,es:pr_memmap_list
    or edi,edi
    je create_ins_empty
;
    mov esi,[edi].memmap_prev
    mov [edi].memmap_prev,ebx
    mov [esi].memmap_next,ebx
    mov [ebx].memmap_next,edi
    mov [ebx].memmap_prev,esi
    jmp create_ins_done

create_ins_empty:
    mov [ebx].memmap_next,ebx
    mov [ebx].memmap_prev,ebx
    mov es:pr_memmap_list,ebx

create_ins_done:
    ReleaseSpinlock es:pr_memmap_spinlock
    mov [ebx].hh_sign,MEMMAP_HANDLE
    mov bx,[ebx].hh_handle
;
    pop edi
    pop esi
    pop cx
    pop ax
    pop es
    ret
CreateHandle    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateMapping
;
;           DESCRIPTION:    EAX             Size of filemapping object
;
;           RETURNS:        BX              File mapping handle
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_mapping_name DB 'Create Mapping',0

create_mapping  Proc far
    push ds
    push es
    call CreateUnnamed
    call CreateHandle
    push es
    pop ds
    LeaveSection ds:map_section
    clc
    pop es
    pop ds
    retf32
create_mapping  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateNamedMapping
;
;           DESCRIPTION:    EAX             Size of filemapping object
;                           ES;(E)DI    Name of file mapping
;
;           RETURNS:        BX              File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_named_mapping_name DB 'Create Named Mapping',0

create_named_mapping    Proc near
    push ds
    push es
    call FindNamed
    jnc create_named_ok
;
    call CreateNamed
    push ds
    push es
    pop ds
    LeaveSection ds:map_section
    pop ds

create_named_ok:
    call CreateHandle
    clc
    pop es
    pop ds
    ret
create_named_mapping    Endp

create_named_mapping32  Proc far
    call create_named_mapping
    retf32
create_named_mapping32  Endp

create_named_mapping16  Proc far
    push edi
    movzx edi,di
    call create_named_mapping
    pop edi
    retf32
create_named_mapping16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           OpenNamedMapping
;
;           DESCRIPTION:    ES;(E)DI    Name of file mapping
;
;           RETURNS:        BX              File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_named_mapping_name DB 'Open Named Mapping',0

open_named_mapping      Proc near
    push ds
    push es
    call FindNamed
    jc open_named_done
    call CreateHandle
    clc
open_named_done:
    pop es
    pop ds
    ret
open_named_mapping      Endp

open_named_mapping32    Proc far
    call open_named_mapping
    retf32
open_named_mapping32    Endp

open_named_mapping16    Proc far
    push edi
    movzx edi,di
    call open_named_mapping
    pop edi
    retf32
open_named_mapping16    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseMapping
;
;           DESCRIPTION:    BX              File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_mapping_name DB 'Close Mapping',0

close_mapping   Proc far
    push ds
    push es
    push ax
    push esi
    push edi
;
    mov ax,MEMMAP_HANDLE
    DerefHandle
    jc cfm_done
;
    call FreeView
;
    GetThread
    mov es,ax
    mov es,es:p_prog_sel
    RequestSpinlock es:pr_memmap_spinlock
    mov es:pr_memmap_list,ebx
    mov edi,[ebx].memmap_next
    cmp edi,ebx
    mov es:pr_memmap_list,edi
    mov esi,[ebx].memmap_prev
    mov [edi].memmap_prev,esi
    mov [esi].memmap_next,edi
    jne close_rem_done
;
    mov es:pr_memmap_list,0

close_rem_done:
    ReleaseSpinlock es:pr_memmap_spinlock
    mov ax,ds:[ebx].memmap_sel
    or ax,ax
    jz cfm_done
;
    mov es,ax
    call CloseMapped
    clc

cfm_done:
    FreeHandle
    pop edi
    pop esi
    pop ax
    pop es
    pop ds
    retf32
close_mapping   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           map_to_user
;
;           DESCRIPTION:    Map page from object to user memory
;
;           PARAMETERS:         EAX             Offset within object
;                           EBX             Source linear address
;                           EDX             Pagefault base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_to_user     Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    push edx
;
    mov edx,ebx
    GetPageEntry
    test al,1
    jnz map_to_user_do
;
    push es
    push edi
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
    xor eax,eax
    mov ecx,400h
    rep stos dword ptr es:[edi]     
    pop edi
    pop es
;
    GetPageEntry

map_to_user_do:
    pop edx
    or ax,807h
    SetPageEntry
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
map_to_user     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           pagefault
;
;           DESCRIPTION:    Page-fault handler for memory mapped object
;
;           PARAMETERS:         EDX         Page fault address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pagefault       Proc far
    push ds
    push eax
    push ebx
    push cx
    push edx
    push esi
;
    GetThread
    mov ds,ax
    mov es,ds:p_prog_sel
    mov ds,es:pr_handle_mem_sel
    mov ebx,es:pr_memmap_list
    or ebx,ebx
    jz map_fault_fail
;
    mov esi,ebx

map_fault_loop:
    mov ax,ds:[ebx].memmap_sel
    or ax,ax
    jz map_fault_find_next
;
    mov eax,ds:[ebx].view_size
    or eax,eax
    jz map_fault_find_next
;
    mov eax,edx     
    sub eax,ds:[ebx].view_base
    jc map_fault_find_next
;
    cmp eax,ds:[ebx].view_size
    jnc map_fault_find_next
;
    add eax,ds:[ebx].view_offset
    and ax,0F000h
    and dx,0F000h
    mov ds,ds:[ebx].memmap_sel
    EnterSection ds:map_section

map_fault_mem:
    mov ebx,ds:map_base
    add ebx,eax
    call map_to_user

map_fault_leave:
    LeaveSection ds:map_section
    jmp map_fault_done

map_fault_find_next:
    mov ebx,[ebx].memmap_next
    cmp ebx,esi
    jnz map_fault_loop

map_fault_fail:
    int 3

map_fault_done:
    pop esi
    pop edx
    pop cx
    pop ebx
    pop eax
    pop ds
    retf32
pagefault       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MapView
;
;           DESCRIPTION:    BX              File mapping handle
;                           EAX             Offset
;                           (E)CX       Size
;                           ES:(E)DI    Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_view_name DB 'Map View',0

map_view    Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edx
    push di
;
    push ax
    mov ax,MEMMAP_HANDLE
    DerefHandle
    pop ax
    jc mfm_done
;
    mov dx,ds:[ebx].memmap_sel
    or dx,dx
    stc
    jz mfm_done
;
    mov edx,ds:[ebx].view_size
    or edx,edx
    stc 
    jnz mfm_done
;
    mov ds:[ebx].view_offset,eax
    dec ecx
    and cx,0F000h
    add ecx,1000h
    mov eax,ecx
    push bx
    mov bx,es
    GetSelectorBaseSize
    pop bx
    jc mfm_done
;
    cmp ecx,eax
    jc mfm_done
;
    add edx,edi
    test dx,0FFFh
    stc
    jnz mfm_done
;
    mov ecx,eax
    mov es,ds:[ebx].memmap_sel
    cmp es:map_size,eax
    jc mfm_done
;
    mov ds:[ebx].view_base,edx
    mov ds:[ebx].view_size,ecx
    mov ax,memmap_loader_sel
    mov es,ax
    mov eax,ecx
    HookPage
    clc

mfm_done:
    pop di
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
map_view    Endp

map_view32      Proc far
    call map_view
    retf32
map_view32      Endp

map_view16      Proc far
    push ecx
    push edi
    movzx ecx,cx
    movzx edi,di
    call map_view
    pop edi
    pop ecx
    retf32
map_view16      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UnmapView
;
;           DESCRIPTION:    BX              File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unmap_view_name DB 'Unmap View',0

unmap_view      Proc far
    push ds
    push ax
    push ebx
;
    mov ax,MEMMAP_HANDLE
    DerefHandle
    jc ufm_done
;
    call FreeView
    clc

ufm_done:
    pop ebx
    pop ax
    pop ds
    retf32
unmap_view      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    BX              File mapping handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push es
    push ax
;
    mov ax,MEMMAP_HANDLE
    DerefHandle
    jc delete_handle_done
;
    call FreeView
;
    GetThread
    mov es,ax
    mov es,es:p_prog_sel
    RequestSpinlock es:pr_memmap_spinlock
    mov es:pr_memmap_list,ebx
    mov edi,[ebx].memmap_next
    cmp edi,ebx
    mov es:pr_memmap_list,edi
    mov esi,[ebx].memmap_prev
    mov [edi].memmap_prev,esi
    mov [esi].memmap_next,edi
    jne delete_handle_rem_done
;
    mov es:pr_memmap_list,0

delete_handle_rem_done:
    ReleaseSpinlock es:pr_memmap_spinlock
    mov ax,ds:[ebx].memmap_sel
    or ax,ax
    jz delete_handle_done
;
    mov es,ax
    call CloseMapped
    clc

delete_handle_done:
    FreeHandle
    pop ax
    pop es
    pop ds
    retf32
delete_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_memmap

loader_tab:
l00 DD OFFSET pagefault,                  SEG code

init_memmap     PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov eax,8
    mov bx,memmap_loader_sel
    AllocateFixedSystemMem
    xor di,di
    mov si,OFFSET loader_tab
    mov cx,8
    rep movs byte ptr es:[di],cs:[si]
;
    mov ax,MEMMAP_HANDLE
    mov edi,OFFSET delete_handle
    RegisterHandle
;
    mov esi,OFFSET create_mapping
    mov edi,OFFSET create_mapping_name
    xor dx,dx
    mov ax,create_mapping_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET create_named_mapping16
    mov esi,OFFSET create_named_mapping32
    mov edi,OFFSET create_named_mapping_name
    mov dx,virt_es_in
    mov ax,create_named_mapping_nr
    RegisterUserGate
;
    mov ebx,OFFSET open_named_mapping16
    mov esi,OFFSET open_named_mapping32
    mov edi,OFFSET open_named_mapping_name
    mov dx,virt_es_in
    mov ax,open_named_mapping_nr
    RegisterUserGate
;
    mov esi,OFFSET close_mapping
    mov edi,OFFSET close_mapping_name
    xor dx,dx
    mov ax,close_mapping_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET map_view16
    mov esi,OFFSET map_view32
    mov edi,OFFSET map_view_name
    mov dx,virt_es_in
    mov ax,map_view_nr
    RegisterUserGate
;
    mov esi,OFFSET unmap_view
    mov edi,OFFSET unmap_view_name
    xor dx,dx
    mov ax,unmap_view_nr
    RegisterBimodalUserGate
;
    mov ax,SEG data
    mov ds,ax
    mov ds:map_list,0
    mov ds:map_named_list,0
    InitSection ds:sys_section
    ret
init_memmap     ENDP

code    ENDS

    END
