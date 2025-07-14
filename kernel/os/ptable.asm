;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; PTABLE.ASM
; Page tables module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE exec.def
INCLUDE ..\serv.def
INCLUDE servdev.def

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

mmap_struc  STRUC

mmap_len    DD ?
mmap_base   DD ?,?
mmap_size   DD ?,?
mmap_type   DD ?

mmap_struc  ENDS

    extrn local_get_selector_base_size:near
    extrn local_create_data_sel16:near
    extrn local_allocate_physical:near
    extrn local_free_physical:near

    extrn AllocateRam:near
    extrn AllocateMultipleRam:near

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Procedure addresses for non-PAE/PAE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_process_proc
    public create_process_proc
    public create_long_process_proc
    public free_process_proc
    public get_page_entry_proc
    public set_page_entry_proc
    public get_sys_page_entry_proc
    public set_sys_page_entry_proc
    public get_page_dir_attrib_proc
    public fault_to_dir_proc
    public get_page_dir_proc
    public set_page_dir_proc
    public get_sys_page_dir_proc
    public set_sys_page_dir_proc
    public create_page_dir_proc
    public create_sys_page_dir_proc
    public get_serv_page_dir_proc
    public set_serv_page_dir_proc
    public create_serv_page_dir_proc
    public has_page_entry_proc
    public reserve_page_entries_proc
    public allocate_page_entries_proc
    public allocate_sys_page_entries_proc
    public allocate_and_map_sys_dir_proc
    public free_page_entries_proc
    public free_global_page_entries_proc
    public copy_page_entries_proc
    public copy_sys_page_entries_proc
    public move_page_entries_proc
    public emulate_page_proc
    public hook_page_proc
    public unhook_page_proc
    public get_thread_page_entry_proc
    public set_thread_page_entry_proc
    public get_thread_page_dir_proc
    public create_fork_proc
    public start_fork_proc
    public cow_dir_proc
    public cow_page_proc
    public detach_fork_proc
    public cleanup_fork_proc
    public delete_fork_proc

proc_start:
init_process_proc               DW OFFSET local_init_process32
create_process_proc             DW OFFSET local_create_process32
create_long_process_proc        DW OFFSET local_create_long_process32
free_process_proc               DW OFFSET local_free_process32
delete_process_proc             DW OFFSET local_delete_process32
get_page_entry_proc             DW OFFSET local_get_page_entry32
set_page_entry_proc             DW OFFSET local_set_page_entry32
get_sys_page_entry_proc         DW OFFSET local_get_sys_page_entry32
set_sys_page_entry_proc         DW OFFSET local_set_sys_page_entry32
has_page_entry_proc             DW OFFSET local_has_page_entry32
get_page_dir_attrib_proc        DW OFFSET local_get_page_dir_attrib32
fault_to_dir_proc               DW OFFSET local_fault_to_dir32
get_page_dir_proc               DW OFFSET local_get_page_dir32
set_page_dir_proc               DW OFFSET local_set_page_dir32
get_sys_page_dir_proc           DW OFFSET local_get_sys_page_dir32
set_sys_page_dir_proc           DW OFFSET local_set_sys_page_dir32
create_page_dir_proc            DW OFFSET local_create_page_dir32
create_sys_page_dir_proc        DW OFFSET local_create_sys_page_dir32
create_serv_proc                DW OFFSET local_create_serv32
get_serv_page_dir_proc          DW OFFSET local_get_serv_page_dir32
set_serv_page_dir_proc          DW OFFSET local_set_serv_page_dir32
create_serv_page_dir_proc       DW OFFSET local_create_serv_page_dir32
reserve_page_entries_proc       DW OFFSET local_reserve_page_entries32
allocate_page_entries_proc      DW OFFSET local_allocate_page_entries32
allocate_sys_page_entries_proc  DW OFFSET local_allocate_sys_page_entries32
allocate_and_map_sys_dir_proc   DW OFFSET local_allocate_and_map_sys_dir32
free_page_entries_proc          DW OFFSET local_free_page_entries32
free_global_page_entries_proc   DW OFFSET local_free_global_page_entries32
clear_page_entries_proc         DW OFFSET local_clear_page_entries32
copy_page_entries_proc          DW OFFSET local_copy_page_entries32
copy_sys_page_entries_proc      DW OFFSET local_copy_sys_page_entries32
move_page_entries_proc          DW OFFSET local_move_page_entries32
emulate_page_proc               DW OFFSET local_emulate_page32
hook_page_proc                  DW OFFSET local_hook_page32
unhook_page_proc                DW OFFSET local_unhook_page32
get_thread_page_entry_proc      DW OFFSET local_get_thread_page_entry32
set_thread_page_entry_proc      DW OFFSET local_set_thread_page_entry32
get_thread_page_dir_proc        DW OFFSET local_get_thread_page_dir32
create_fork_proc                DW OFFSET local_create_fork32
start_fork_proc                 DW OFFSET local_start_fork32
cow_dir_proc                    DW OFFSET local_cow_dir32
cow_page_proc                   DW OFFSET local_cow_page32
detach_fork_proc                DW OFFSET local_detach_fork32
cleanup_fork_proc               DW OFFSET local_cleanup_fork32
delete_fork_proc                DW OFFSET local_delete_fork32
uses_pae_proc                   DW OFFSET local_uses_pae32

p64_start:
init_process_p64                DW OFFSET local_init_process64
create_process_p64              DW OFFSET local_create_process64
create_long_process_p64         DW OFFSET local_create_long_process64
free_process_p64                DW OFFSET local_free_process64
delete_process_p64              DW OFFSET local_delete_process64
get_page_entry_p64              DW OFFSET local_get_page_entry64
set_page_entry_p64              DW OFFSET local_set_page_entry64
get_sys_page_entry_p64          DW OFFSET local_get_sys_page_entry64
set_sys_page_entry_p64          DW OFFSET local_set_sys_page_entry64
has_page_entry_p64              DW OFFSET local_has_page_entry64
get_page_dir_attrib_p64         DW OFFSET local_get_page_dir_attrib64
fault_to_dir_p64                DW OFFSET local_fault_to_dir64
get_page_dir_p64                DW OFFSET local_get_page_dir64
set_page_dir_p64                DW OFFSET local_set_page_dir64
get_sys_page_dir_p64            DW OFFSET local_get_sys_page_dir64
set_sys_page_dir_p64            DW OFFSET local_set_sys_page_dir64
create_page_dir_p64             DW OFFSET local_create_page_dir64
create_sys_page_dir_p64         DW OFFSET local_create_sys_page_dir64
create_serv_p64                 DW OFFSET local_create_serv64
get_serv_page_dir_p64           DW OFFSET local_get_serv_page_dir64
set_serv_page_dir_p64           DW OFFSET local_set_serv_page_dir64
create_serv_page_dir_p64        DW OFFSET local_create_serv_page_dir64
reserve_page_entries_p64        DW OFFSET local_reserve_page_entries64
allocate_page_entries_p64       DW OFFSET local_allocate_page_entries64
allocate_sys_page_entries_p64   DW OFFSET local_allocate_sys_page_entries64
allocate_and_map_sys_dir_p64    DW OFFSET local_allocate_and_map_sys_dir64
free_page_entries_p64           DW OFFSET local_free_page_entries64
free_global_page_entries_p64    DW OFFSET local_free_global_page_entries64
clear_page_entries_p64          DW OFFSET local_clear_page_entries64
copy_page_entries_p64           DW OFFSET local_copy_page_entries64
copy_sys_page_entries_p64       DW OFFSET local_copy_sys_page_entries64
move_page_entries_p64           DW OFFSET local_move_page_entries64
emulate_page_p64                DW OFFSET local_emulate_page64
hook_page_p64                   DW OFFSET local_hook_page64
unhook_page_p64                 DW OFFSET local_unhook_page64
get_thread_page_entry_p64       DW OFFSET local_get_thread_page_entry64
set_thread_page_entry_p64       DW OFFSET local_set_thread_page_entry64
get_thread_page_dir_p64         DW OFFSET local_get_thread_page_dir64
create_fork_p64                 DW OFFSET local_create_fork64
start_fork_p64                  DW OFFSET local_start_fork64
cow_dir_p64                     DW OFFSET local_cow_dir64
cow_page_p64                    DW OFFSET local_cow_page64
detach_fork_p64                 DW OFFSET local_detach_fork64
cleanup_fork_p64                DW OFFSET local_cleanup_fork64
delete_fork_p64                 DW OFFSET local_delete_fork64
uses_pae_p64                    DW OFFSET local_uses_pae64
p64_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_PAGE_TABLE
;
;           DESCRIPTION:    Init module syscalls
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_page_table

init_page_table     PROC near
    pusha
    push ds
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET create_serv_dir
    mov edi,OFFSET create_serv_dir_name
    xor cl,cl
    mov ax,create_serv_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_init_process
    mov edi,OFFSET notify_init_process_name
    xor cl,cl
    mov ax,notify_init_process_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_create_process
    mov edi,OFFSET notify_create_process_name
    xor cl,cl
    mov ax,notify_create_process_nr
    RegisterOsGate
;
    mov esi,OFFSET create_fork
    mov edi,OFFSET create_fork_name
    xor cl,cl
    mov ax,create_fork_nr
    RegisterOsGate
;
    mov esi,OFFSET start_fork
    mov edi,OFFSET start_fork_name
    xor cl,cl
    mov ax,start_fork_nr
    RegisterOsGate
;
    mov esi,OFFSET detach_fork
    mov edi,OFFSET detach_fork_name
    xor cl,cl
    mov ax,detach_fork_nr
    RegisterOsGate
;
    mov esi,OFFSET cleanup_fork
    mov edi,OFFSET cleanup_fork_name
    xor cl,cl
    mov ax,cleanup_fork_nr
    RegisterOsGate
;
    mov esi,OFFSET delete_fork
    mov edi,OFFSET delete_fork_name
    xor cl,cl
    mov ax,delete_fork_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_create_long_process
    mov edi,OFFSET notify_create_long_process_name
    xor cl,cl
    mov ax,notify_create_long_process_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_delete_process
    mov edi,OFFSET notify_delete_process_name
    xor cl,cl
    mov ax,notify_delete_process_nr
    RegisterOsGate
;
    mov esi,OFFSET reset_process
    mov edi,OFFSET reset_process_name
    xor cl,cl
    mov ax,reset_process_nr
    RegisterOsGate
;
    mov esi,OFFSET get_page_entry
    mov edi,OFFSET get_page_entry_name
    xor cl,cl
    mov ax,get_page_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET set_page_entry
    mov edi,OFFSET set_page_entry_name
    xor cl,cl
    mov ax,set_page_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET map_serv_entry
    mov edi,OFFSET map_serv_entry_name
    xor cl,cl
    mov ax,map_serv_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET free_serv_page_entries
    mov edi,OFFSET free_serv_page_entries_name
    xor cl,cl
    mov ax,free_serv_page_entries_nr
    RegisterOsGate
;
    mov esi,OFFSET get_sys_page_entry
    mov edi,OFFSET get_sys_page_entry_name
    xor cl,cl
    mov ax,get_sys_page_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET set_sys_page_entry
    mov edi,OFFSET set_sys_page_entry_name
    xor cl,cl
    mov ax,set_sys_page_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET has_page_entry
    mov edi,OFFSET has_page_entry_name
    xor cl,cl
    mov ax,has_page_entry_nr
    RegisterOsGate
;
    mov esi,OFFSET get_page_dir_attrib
    mov edi,OFFSET get_page_dir_attrib_name
    xor cl,cl
    mov ax,get_page_dir_attrib_nr
    RegisterOsGate
;
    mov esi,OFFSET get_page_dir
    mov edi,OFFSET get_page_dir_name
    xor cl,cl
    mov ax,get_page_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET set_page_dir
    mov edi,OFFSET set_page_dir_name
    xor cl,cl
    mov ax,set_page_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET get_sys_page_dir
    mov edi,OFFSET get_sys_page_dir_name
    xor cl,cl
    mov ax,get_sys_page_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET set_sys_page_dir
    mov edi,OFFSET set_sys_page_dir_name
    xor cl,cl
    mov ax,set_sys_page_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET create_sys_page_dir
    mov edi,OFFSET create_sys_page_dir_name
    xor cl,cl
    mov ax,create_sys_page_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET reserve_page_entries
    mov edi,OFFSET reserve_page_entries_name
    xor cl,cl
    mov ax,reserve_page_entries_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_page_entries
    mov edi,OFFSET allocate_page_entries_name
    xor cl,cl
    mov ax,allocate_page_entries_nr
    RegisterOsGate
;
    mov esi,OFFSET free_page_entries
    mov edi,OFFSET free_page_entries_name
    xor cl,cl
    mov ax,free_page_entries_nr
    RegisterOsGate
;
    mov esi,OFFSET clear_page_entries
    mov edi,OFFSET clear_page_entries_name
    xor cl,cl
    mov ax,clear_page_entries_nr
    RegisterOsGate
;
    mov esi,OFFSET copy_page_entries
    mov edi,OFFSET copy_page_entries_name
    xor cl,cl
    mov ax,copy_page_entries_nr
    RegisterOsGate
;
    mov esi,OFFSET copy_sys_page_entries
    mov edi,OFFSET copy_sys_page_entries_name
    xor cl,cl
    mov ax,copy_sys_page_entries_nr
    RegisterOsGate
;
    mov esi,OFFSET move_page_entries
    mov edi,OFFSET move_page_entries_name
    xor cl,cl
    mov ax,move_page_entries_nr
    RegisterOsGate
;
    mov esi,OFFSET set_page_emulate
    mov edi,OFFSET set_page_emulate_name
    xor cl,cl
    mov ax,set_page_emulate_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_page
    mov edi,OFFSET hook_page_name
    xor cl,cl
    mov ax,hook_page_nr
    RegisterOsGate
;
    mov esi,OFFSET unhook_page
    mov edi,OFFSET unhook_page_name
    xor cl,cl
    mov ax,unhook_page_nr
    RegisterOsGate
;    
    mov esi,OFFSET get_thread_page_entry
    mov edi,OFFSET get_thread_page_entry_name
    xor cl,cl
    mov ax,get_thread_page_entry_nr
    RegisterOsGate
;    
    mov esi,OFFSET set_thread_page_entry
    mov edi,OFFSET set_thread_page_entry_name
    xor cl,cl
    mov ax,set_thread_page_entry_nr
    RegisterOsGate
;    
    mov esi,OFFSET get_thread_page_dir
    mov edi,OFFSET get_thread_page_dir_name
    xor cl,cl
    mov ax,get_thread_page_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET has_physical64
    mov edi,OFFSET has_physical64_name
    xor dx,dx
    mov ax,has_physical64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET uses_pae
    mov edi,OFFSET uses_pae_name
    xor dx,dx
    mov ax,uses_pae_nr
    RegisterBimodalUserGate
;    
    pop ds
    popa
    ret
init_page_table     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_init_process32
;
;           DESCRIPTION:    Init process paging
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_init_process32     Proc near
    mov ax,sys_page_sel
    mov ds,ax
    mov ax,system_data_sel
    mov es,ax
    mov ecx,es:rom1_size
    or ecx,ecx
    jz ipUnmapDone1_32
;
    mov edx,es:rom1_base
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr edx,10
    shr ecx,12

ipUnmapLoop1_32:
    mov dword ptr [edx],0
    add edx,4
    loop ipUnmapLoop1_32

ipUnmapDone1_32:
    mov ecx,es:rom2_size
    or ecx,ecx
    jz ipUnmapDone2_32
;
    mov edx,es:rom2_base
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr edx,10
    shr ecx,12

ipUnmapLoop2_32:
    mov dword ptr [edx],0
    add edx,4
    loop ipUnmapLoop2_32

ipUnmapDone2_32:
    mov ax,sys_dir_sel
    mov ds,ax
    mov bx,(sys_page_linear SHR 20) AND 0FFFh
    mov ebx,[bx]
    and bx,0F000h
;
    mov ax,sys_page_sel
    mov ds,ax
    mov ax,process_page_sel
    mov es,ax
    mov edx,4

ipFreeStartupLoop32:
    mov eax,[edx]
    test al,1
    jz ipFreeStartupDone32
;
    and ax,0F000h
    cmp eax,ebx
    jae ipFreeStartupZero32
;
    xor ebx,ebx
    FreePhysical

ipFreeStartupZero32:
    xor eax,eax
    mov [edx],eax
    mov es:[edx],eax
    add edx,4
    jmp ipFreeStartupLoop32

ipFreeStartupDone32:  
    mov ax,system_data_sel
    mov es,ax
    mov eax,es:flat_base
    or eax,eax
    jnz ipFlatOk32
;    
    xor ebx,ebx
    mov [ebx],ebx

ipFlatOk32:    
    mov eax,cr3
    mov cr3,eax
    ret
local_init_process32     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Create_process32
;
;           DESCRIPTION:    Create process paging environment
;
;           RETURNS:        EAX         CR3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_process32       PROC near
    push ds
    push es
;    
    mov eax,2000h
    AllocateGlobalMem
    mov ax,sys_dir_sel
    mov ds,ax
    xor ax,ax
    xor di,di
    mov ecx,sys_page_linear
    shr ecx,22
    rep stosd
;
    mov eax,sys_page_linear
    mov esi,eax
    shr esi,20
    shr eax,22
    mov cx,400h
    sub cx,ax
    rep movsd
;
    mov ax,sys_page_sel
    mov ds,ax
    xor si,si
    mov cx,400h
    xor eax,eax
    rep movsd
;
    mov ax,gdt_sel
    mov ds,ax
    mov bx,es
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
    shr edx,10
;
    mov ax,sys_page_sel
    mov ds,ax
    mov eax,[edx+4]
    xor di,di
    mov es:[di],eax
;
    mov eax,[edx]
    mov al,7
    mov ebx,process_page_linear
    shr ebx,20
    mov es:[bx+di],eax
;
    xor ebx,ebx
    mov [edx],ebx
    mov [edx+4],ebx
    FreeMem
;    
    pop es
    pop ds
    ret
local_create_process32       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Create_long_process32
;
;           DESCRIPTION:    Create long mode process paging environment
;
;           PARAMETERS:     ES          Thread
;                           EAX         CR3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_long_process32       PROC near
    int 3
    ret
local_create_long_process32       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_free_process32
;
;           DESCRIPTION:    Free process paging
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_free_process32     Proc near
    push ds
    push es
    pushad
;
    mov bx,process_page_sel
    mov ds,bx
    mov bx,process_dir_sel
    mov es,bx
;
    GetFlatSize
    mov ecx,eax
    xor esi,esi
    shr ecx,22
    xor edi,edi

fpDirLoop32:
    mov eax,es:[edi]
    test al,1
    jz fpNextDir32
;
    test ax,800h
    jnz fpNextDir32
;
    push cx
    mov cx,400h

fpPageLoop32:
    xor eax,eax
    xchg eax,[esi]
    test al,1
    jz fpNextPage32
;
    test ax,800h
    jnz fpNextPage32
;
    xor ebx,ebx
    FreePhysical

fpNextPage32:
    add esi,4
    loop fpPageLoop32
;
    pop cx
    xor eax,eax
    xchg eax,es:[edi]
;
    xor ebx,ebx
    FreePhysical
    jmp fpNextDirPage32
    
fpNextDir32:
    add esi,1000h

fpNextDirPage32:
    add edi,4
    loop fpDirLoop32
;
    GetFlatSize
    shr eax,22
    mov cx,400h
    sub cx,ax
    mov bx,sys_dir_sel
    mov ds,bx

fpGlobalLoop32:
    mov eax,es:[edi]
    test al,1
    jz fpGlobalNext32
;
    test ax,800h
    jnz fpGlobalNext32
;
    and ax,0F000h
    mov ebx,[edi]
    and bx,0F000h
    cmp eax,ebx
    je fpGlobalNext32
;
    cmp edi,(fixed_process_linear SHR 20) AND 0FFFh
    je fpGlobalNext32
;
    cmp edi,(process_page_linear SHR 20) AND 0FFFh
    je fpGlobalNext32
;
    xor eax,eax
    xchg eax,es:[edi]
    xor ebx,ebx
    FreePhysical

fpGlobalNext32:
    add edi,4
    loop fpGlobalLoop32
;
    mov bx,process_page_sel
    mov ds,bx
    mov bx,process_dir_sel
    mov es,bx
;
    mov edi,fixed_process_linear SHR 20
    mov ecx,fixed_process_size SHR 22
    mov esi,fixed_process_linear SHR 10

fpProcDirLoop32:
    mov eax,es:[edi]
    test al,1
    jz fpProcNextDir32
;
    push cx
    mov cx,400h

fpProcPageLoop32:
    xor eax,eax
    xchg eax,[esi]
    test al,1
    jz fpProcNextPage32
;
    xor ebx,ebx
    FreePhysical

fpProcNextPage32:
    add esi,4
    loop fpProcPageLoop32
;
    pop cx
    xor eax,eax
    xchg eax,es:[edi]
;
    xor ebx,ebx
    FreePhysical
    jmp fpProcNextDirPage32
    
fpProcNextDir32:
    add esi,1000h

fpProcNextDirPage32:
    add edi,4
    loop fpProcDirLoop32
;
    popad
    pop es
    pop ds
    ret
local_free_process32     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_delete_process32
;
;           DESCRIPTION:    Delete process paging
;
;           PARAMETERS:     EAX     CR3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_delete_process32     Proc near
    push eax
    mov ax,flat_sel
    mov es,ax
    mov eax,1000h
    AllocateBigLinear
    pop eax
    xor ebx,ebx
    mov al,3
    SetPageEntry    
;
    mov ecx,1000h
    FreeLinear        
    ret
local_delete_process32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateServ32
;
;           DESCRIPTION:    Create 32-bit serv sel
;
;           RETURNS:        BX     Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_serv32       PROC near
    push es
    push eax
    push ecx
    push edi
;
    mov eax,(sys_page_linear - serv_linear) SHR 20
    add eax,OFFSET serv_dir_arr
    mov ecx,eax
    AllocateGlobalMem
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
    mov bx,es
;
    pop edi
    pop ecx
    pop eax
    pop es
    ret
local_create_serv32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_page_entry32
;
;           DESCRIPTION:    Get physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        EBX:EAX         physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_page_entry32       Proc near
    push ds
    mov ax,process_page_sel
    mov ds,ax
    mov eax,edx
    shr eax,10
    and al,0FCh
    mov eax,[eax]
    xor ebx,ebx
    pop ds
    ret
local_get_page_entry32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_page_entry32
;
;           DESCRIPTION:    Set physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_page_entry32       Proc near
    push ds
    push eax
    push ecx
;
    or ebx,ebx
    jnz sppDone
;
    push edx
    mov cx,process_page_sel
    mov ds,cx
    shr edx,10
    and dl,0FCh
    xchg eax,[edx]
    pop edx
    test al,1
    jz sppDone
;
    mov cx,1
    FlushTlb

sppDone:
    pop ecx
    pop eax
    pop ds
    ret
local_set_page_entry32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_sys_page_entry32
;
;           DESCRIPTION:    Get physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        EBX:EAX         physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_sys_page_entry32       Proc near
    push ds
    mov ax,sys_page_sel
    mov ds,ax
    mov eax,edx
    shr eax,10
    and al,0FCh
    mov eax,[eax]
    xor ebx,ebx
    pop ds
    ret
local_get_sys_page_entry32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_sys_page_entry32
;
;           DESCRIPTION:    Set physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_sys_page_entry32       Proc near
    push ds
    push eax
    push ecx
    push edx
;
    or ebx,ebx
    jz ssppok32
;
    int 3

ssppok32:    
    mov cx,sys_page_sel
    mov ds,cx
    shr edx,10
    and dl,0FCh
    mov [edx],eax
;
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
local_set_sys_page_entry32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_page_dir_attrib32
;
;           DESCRIPTION:    Get page dir attributes
;
;           RETURNS:        ESI         linear address space size per entry
;                           CX          # of entries per 32-bit page dir entries
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_page_dir_attrib32       Proc near
    mov cx,1
    mov esi,400000h
    ret
local_get_page_dir_attrib32    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_fault_to_dir32
;
;           DESCRIPTION:    Convert page fault to dir position
;
;           PARAMETERS:     EDX         Linear address
;
;           RETURNS:        EDX         Page dir address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_fault_to_dir32       Proc near
    sub edx,process_page_linear
    shl edx,10
    ret
local_fault_to_dir32    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_page_dir32
;
;           DESCRIPTION:    Get physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_page_dir32       Proc near
    push ds
    push edx
;    
    mov ax,process_dir_sel
    mov ds,ax
    shr edx,20
    and dl,0FCh
    mov eax,[edx]
    xor ebx,ebx
;    
    pop edx
    pop ds
    ret
local_get_page_dir32    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_sys_page_dir32
;
;           DESCRIPTION:    Get physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_sys_page_dir32       Proc near
    push ds
    push edx
;    
    mov ax,sys_dir_sel
    mov ds,ax
    shr edx,20
    and dl,0FCh
    mov eax,[edx]
    xor ebx,ebx
;    
    pop edx
    pop ds
    ret
local_get_sys_page_dir32    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_serv_page_dir32
;
;           DESCRIPTION:    Get serv physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           ES          thread
;
;           RETURNS:        EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_serv_page_dir32       Proc near
    push ds
    push edx
;
    mov ds,es:p_serv_sel
    sub edx,serv_linear
    shr edx,20
    and dl,0FCh
    mov eax,[edx].serv_dir_arr
    xor ebx,ebx
;
    pop edx
    pop ds
    ret
local_get_serv_page_dir32    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_page_dir32
;
;           DESCRIPTION:    Set physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_page_dir32       Proc near
    push ds
    push cx
    push edx
;    
    mov cx,process_dir_sel
    mov ds,cx
    shr edx,20
    and dl,0FCh
    mov [edx],eax
;    
    pop edx
    pop cx
    pop ds
    ret
local_set_page_dir32    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_sys_page_dir32
;
;           DESCRIPTION:    Set physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_sys_page_dir32       Proc near
    push ds
    push cx
    push edx
;    
    mov cx,sys_dir_sel
    mov ds,cx
    shr edx,20
    and dl,0FCh
    mov [edx],eax
;    
    pop edx
    pop cx
    pop ds
    ret
local_set_sys_page_dir32    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_serv_page_dir32
;
;           DESCRIPTION:    Set serv physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           ES          thread
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_serv_page_dir32       Proc near
    push ds
    push edx
;    
    mov ds,es:p_serv_sel
    sub edx,serv_linear
    shr edx,20
    and dl,0FCh
    mov [edx].serv_dir_arr,eax
;    
    pop edx
    pop ds
    ret
local_set_serv_page_dir32    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_page_dir32
;
;           DESCRIPTION:    Create page directory entry
;
;           PARAMETERS:     EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_page_dir32       Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    push edx
    mov bx,process_dir_sel
    mov ds,bx
    shr edx,20
    and dx,0FFCh
    call local_allocate_physical
    mov al,7
    mov [edx],eax    
    pop edx
;
    shr edx,10
    and dx,0F000h
    mov bx,process_page_sel
    mov ds,bx
;
    mov cx,400h
    xor ebx,ebx

cpdInit:
    mov [edx],ebx
    add edx,4
    loop cpdInit
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
local_create_page_dir32    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_sys_page_dir32
;
;           DESCRIPTION:    Create sys page directory entry
;
;           PARAMETERS:     EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_sys_page_dir32       Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    push edx
    mov bx,sys_dir_sel
    mov ds,bx
    shr edx,20
    and dx,0FFCh
    call local_allocate_physical
    mov al,7
    mov [edx],eax    
    pop edx
;
    shr edx,10
    and dx,0F000h
    mov bx,sys_page_sel
    mov ds,bx
;
    mov cx,400h
    xor ebx,ebx

cspdInit:
    mov [edx],ebx
    add edx,4
    loop cspdInit
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
local_create_sys_page_dir32    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_serv_page_dir32
;
;           DESCRIPTION:    Create serv page directory entry
;
;           PARAMETERS:     EDX         linear address
;                           ES          thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_serv_page_dir32       Proc near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    mov ds,es:p_serv_sel
    sub edx,serv_linear
    shr edx,20
    and dx,0FFCh
    call local_allocate_physical
    mov al,7
    mov [edx].serv_dir_arr,eax    
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    mov al,13h
    call local_set_page_entry32
;
    mov bx,flat_sel
    mov ds,bx
    mov cx,400h
    xor ebx,ebx
    push edx

cshpdInit:
    mov [edx],ebx
    add edx,4
    loop cshpdInit
;
    pop edx
;
    xor eax,eax
    call local_set_page_entry32
;
    mov ecx,1000h
    FreeLinear
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
local_create_serv_page_dir32    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_has_page_entry32
;
;           DESCRIPTION:    Check physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        NC          valid
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_has_page_entry32       Proc near
    push ds
    push eax
;    
    mov ax,process_page_sel
    mov ds,ax
    mov eax,edx
    shr eax,10
    and al,0FCh
    mov eax,[eax]
    test al,1
    clc
    jnz hpeDone32
;
    stc

hpeDone32:    
    pop eax    
    pop ds
    ret
local_has_page_entry32       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_reserve_page_entries32
;
;           DESCRIPTION:    Reserve page entries 
;
;           PARAMETERS:     ECX         number of entries
;                           EDX         start linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_reserve_page_entries32       Proc near
    push eax
;    
    mov ax,process_page_sel
    mov ds,ax
    shr edx,10
;
    push ecx
    push edx

rpeLoop:
    mov al,[edx]
    test al,7
    jnz rpePopFail
;    
    add edx,4
    sub ecx,1
    jnz rpeLoop
;    
    pop edx
    pop ecx
;
    push ecx    

rpeMark:
    mov eax,2
    mov [edx],eax
    add edx,4
;    
    sub ecx,1
    jnz rpeMark
;
    pop ecx
    clc
    jmp rpeDone    

rpePopFail:
    pop edx
    pop ecx
    stc

rpeDone:    
    pop eax
    ret
local_reserve_page_entries32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_allocate_page_entries32
;
;           DESCRIPTION:    Allocate page entries 
;
;           PARAMETERS:     EAX         allocate limit
;                           ECX         number of entries
;                           EDX         start linear address
;
;           RETURNS:        EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_allocate_page_entries32       Proc near
    push eax
    push ebx
    push esi
;
    mov esi,eax
    shr edx,10
    shr esi,10
;    
    mov bx,process_page_sel
    mov ds,bx
;    
    xor ebx,ebx

apeLoop:
    cmp edx,esi
    stc
    je apeFail
;
    inc ebx
    mov al,[edx]
    test al,7
    jz apeNext
;    
    xor ebx,ebx
    
apeNext:
    add edx,4
    cmp ecx,ebx
    jne apeLoop
;
    mov eax,ecx
    shl eax,2
    sub edx,eax
;
    push edx
    push ecx
;    
    mov eax,2
    
apeMark:
    mov [edx],eax
    add edx,4
    sub ecx,1
    jnz apeMark
;
    pop ecx
    pop edx
;    
    shl edx,10
    clc
    jmp apeDone

apeFail:
    stc

apeDone:
    pop esi
    pop ebx
    pop eax
    ret
local_allocate_page_entries32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_allocate_sys_page_entries32
;
;           DESCRIPTION:    Allocate sys page entries 
;
;           PARAMETERS:     EAX         allocate limit
;                           ECX         number of entries
;                           EDX         start linear address
;
;           RETURNS:        EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_allocate_sys_page_entries32       Proc near
    push eax
    push ebx
    push esi
;
    mov esi,eax
    shr edx,10
    shr esi,10
;    
    mov bx,sys_page_sel
    mov ds,bx
;    
    xor ebx,ebx

aspeLoop:
    cmp edx,esi
    stc
    je aspeFail
;
    inc ebx
    mov eax,[edx]
    or eax,eax
    jz aspeNext
;    
    xor ebx,ebx
    
aspeNext:
    add edx,4
    cmp ecx,ebx
    jne aspeLoop
;
    mov eax,ecx
    shl eax,2
    sub edx,eax
;
    push edx
    push ecx
;    
    mov eax,2
    
aspeMark:
    mov [edx],eax
    add edx,4
    sub ecx,1
    jnz aspeMark
;
    pop ecx
    pop edx
;    
    shl edx,10
    clc
    jmp aspeDone

aspeFail:
    stc

aspeDone:
    pop esi
    pop ebx
    pop eax
    ret
local_allocate_sys_page_entries32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_allocate_and_map_sys_dir32
;
;           DESCRIPTION:    Allocate and map sys dir
;
;           PARAMETERS:     ECX         allocate limit
;                           EDX         start linear address
;                           EBX:EAX     physical address
;
;           RETURNS:        EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_allocate_and_map_sys_dir32       Proc near
    or ebx,ebx
    stc
    jnz aamsdDone32
;
    push eax
    push ecx
    mov eax,ecx
    mov ecx,512
    call local_allocate_sys_page_entries32
    pop ecx
    pop eax
    jc aamsdDone32
;
    push ds
    push eax
    push ecx
    push edx
;
    and ax,0F000h
    mov al,13h
;
    mov cx,sys_page_sel
    mov ds,cx
    shr edx,10
    mov ecx,512

aamsdLoop32:
    mov [edx],eax
    add edx,4
    add eax,1000h
    loop aamsdLoop32
;
    pop edx
    pop ecx
    pop eax
    pop ds
    clc

aamsdDone32:
    ret
local_allocate_and_map_sys_dir32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_free_page_entries32
;
;           DESCRIPTION:    Free page entries 
;
;           PARAMETERS:     EAX         free signature
;                           ECX         number of entries
;                           EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_free_page_entries32       Proc near
    push ds
    pushad
;   
    or ecx,ecx
    jz fpeDone32
;
    mov esi,eax
    push ecx
    push edx
;
    mov bx,process_page_sel
    mov ds,bx
    shr edx,10
    and dl,0FCh
    
fpeLoop32:
    mov eax,[edx]
    test al,1
    jz fpeMark32
;
    test ax,800h
    jnz fpeMark32
;
    xor ebx,ebx
    FreePhysical

fpeMark32:        
    mov [edx],esi
;
    add edx,4
    sub ecx,1
    jnz fpeLoop32    
;    
    pop edx
    pop ecx
    FlushTlb

fpeDone32:
    popad
    pop ds
    ret
local_free_page_entries32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_free_global_page_entries32
;
;           DESCRIPTION:    Free global page entries 
;
;           PARAMETERS:     EAX         free signature
;                           ECX         number of entries
;                           EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_free_global_page_entries32       Proc near
    push ds
    pushad
;   
    or ecx,ecx
    jz fgpeDone32
;
    mov esi,eax
    push ecx
    push edx
;
    mov bx,sys_page_sel
    mov ds,bx
    shr edx,10
    and dl,0FCh
    
fgpeLoop32:
    mov eax,[edx]
    test al,1
    jz fgpeMark32
;
    test ax,800h
    jnz fgpeMark32
;
    xor ebx,ebx
    FreePhysical

fgpeMark32:        
    mov [edx],esi
;
    add edx,4
    sub ecx,1
    jnz fgpeLoop32    
;    
    pop edx
    pop ecx
    FlushTlb

fgpeDone32:
    popad
    pop ds
    ret
local_free_global_page_entries32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_clear_page_entries32
;
;           DESCRIPTION:    Clear page entries 
;
;           PARAMETERS:     EAX         free signature
;                           ECX         number of entries
;                           EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_clear_page_entries32       Proc near
    push ds
    pushad
;   
    or ecx,ecx
    jz lcpeDone32
;
    push ecx
    push edx
;
    mov bx,process_page_sel
    mov ds,bx
    shr edx,10
    and dl,0FCh
    
lcpeLoop32:
    mov [edx],eax
;
    add edx,4
    sub ecx,1
    jnz lcpeLoop32    
;    
    pop edx
    pop ecx
    FlushTlb

lcpeDone32:
    popad
    pop ds
    ret
local_clear_page_entries32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_copy_page_entries32
;
;           DESCRIPTION:    Copy page entries 
;
;           PARAMETERS:     ECX         number of entries
;                           ESI         source linear address
;                           EDI         dest linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_copy_page_entries32       Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz cpeDone32
;
    push ecx
    push edi
;
    mov bx,process_page_sel
    mov ds,bx
    shr esi,10
    shr edi,10
    and si,0FFFCh
    and di,0FFFCh
    
cpeLoop32:
    mov ebx,[esi]
    mov [edi],ebx
    add esi,4
    add edi,4
    sub ecx,1
    jnz cpeLoop32    
;    
    pop edx
    pop ecx
    FlushTlb

cpeDone32:
    popad
    pop ds
    ret
local_copy_page_entries32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_copy_sys_page_entries32
;
;           DESCRIPTION:    Copy page entries 
;
;           PARAMETERS:     ECX         number of entries
;                           ESI         source linear address
;                           EDI         dest linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_copy_sys_page_entries32       Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz cspeDone32
;
    mov bx,sys_page_sel
    mov ds,bx
    shr esi,10
    shr edi,10
    and si,0FFFCh
    and di,0FFFCh
    
cspeLoop32:
    mov ebx,[esi]
    mov [edi],ebx
    add esi,4
    add edi,4
    sub ecx,1
    jnz cspeLoop32    

cspeDone32:
    popad
    pop ds
    ret
local_copy_sys_page_entries32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_move_page_entries32
;
;           DESCRIPTION:    Move page entries
;
;           PARAMETERS:     ECX         number of entries
;                           ESI         source linear address
;                           EDI         dest linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_move_page_entries32       Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz mpeDone32
;
    push esi
    push edi
    push ecx
;    
    mov bx,process_page_sel
    mov ds,bx
    shr esi,10
    shr edi,10
    and si,0FFFCh
    and di,0FFFCh

mpeLoop32:    
    mov ebx,2
    xchg ebx,[esi]
    mov [edi],ebx
;
    add esi,4
    add edi,4
    sub ecx,1
    jnz mpeLoop32    
;    
    pop ecx
    pop edx
    FlushTlb
;
    pop edx
    FlushTlb

mpeDone32:
    popad
    pop ds
    ret
local_move_page_entries32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           local_emulate_page
;
;           DESCRIPTION:    Hook page to emulate contents
;
;           PARAMETERS:     EAX         Size
;                           EDX         Linear base
;                           ES:DI       Emulation callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_emulate_page32    PROC near
    push ds
    push eax
    push ecx
    push edx
;
    mov cx,sys_page_sel
    mov ds,cx
    mov ecx,eax
    dec ecx
    shr ecx,12
    inc cx
    shr edx,10
    and dx,0FFFCh
    mov ax,es
    or ax,8006h
    
epMark32:
    mov [edx],ax
    mov word ptr [edx+2],di
    add edx,4
    loop epMark32
;    
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
local_emulate_page32    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           local_hook_page32
;
;           DESCRIPTION:    Loader hook for a specified linear address range
;
;           PARAMETERS:     EAX         Size
;                           EDX         Linear base
;                           ES          Loader selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_hook_page32       PROC near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    mov cx,process_page_sel
    mov ds,cx
;
    or eax,eax
    jz hpDone32
;
    mov ecx,eax
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr edx,10
    shr ecx,12

hpMark32:
    mov eax,[edx]
    test al,1
    jz hpDo32
;
    xor ebx,ebx
    call local_free_physical
;
    mov eax,cr3
    mov cr3,eax
    mov eax,2

hpDo32:
    and al,6
    jz hpNext32
;
    mov ax,6
    mov [edx],ax
    mov [edx+2],es

hpNext32:
    add edx,4
    loop hpMark32

hpDone32:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
local_hook_page32       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           local_unhook_page32
;
;           DESCRIPTION:    Unhook for a specified linear address range
;
;           PARAMETERS:     EAX         Size
;                           EDX         Linear base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_unhook_page32     PROC near
    push ds
    push eax
    push ecx
    push edx
;
    mov cx,process_page_sel
    mov ds,cx
;
    or eax,eax
    jz uhpDone32
;
    mov ecx,eax
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr edx,10
    shr ecx,12

uhpMark32:
    mov eax,[edx]
    test al,1
    jnz uhpMark32
;
    and al,6
    cmp al,6
    jne uhpNext32
;
    mov dword ptr [edx],2

uhpNext32:
    add edx,4
    loop uhpMark32

uhpDone32:
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
local_unhook_page32     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_thread_page_entry32
;
;           DESCRIPTION:    Get physical page for linear address in other thread.
;
;           PARAMETERS:     BP          Thread
;                           EDX         Linear address
;
;           RETURNS:        EBX:EAX     Physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_thread_page_entry32    Proc near
    push ds
    push es
    push edx
    push si
;
    and dx,0F000h
    mov es,bp
    mov ax,system_data_sel
    mov ds,ax
    RequestSpinlock ds:page_spinlock
;
    mov ax,es
    or ax,ax
    stc
    jz get_thread_fail32
;
    mov ax,process_dir_sel
    mov ds,ax
    mov si,(alias_linear SHR 20) AND 0FFFh
    mov eax,es:p_cr3
    or ax,803h
    mov [si],eax
    mov eax,cr3
    mov cr3,eax
;
    mov eax,alias_linear
    shr edx,10
    and dl,0FCh
    add edx,eax
    mov ebx,edx
    shr edx,10
    and dl,0FCh
    mov ax,process_page_sel
    mov ds,ax
    mov eax,[edx]
    test al,1
    jnz get_thread_phys_do32

get_thread_fail32:
    xor eax,eax
    xor ebx,ebx
    jmp get_thread_phys_done32

get_thread_phys_do32:     
    mov ax,flat_sel
    mov ds,ax
    mov eax,[ebx]
    xor ebx,ebx

get_thread_phys_done32:
    mov dx,system_data_sel
    mov ds,dx
    ReleaseSpinlock ds:page_spinlock
;
    pop si
    pop edx
    pop es
    pop ds
    ret
local_get_thread_page_entry32    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_thread_page_entry32
;
;           DESCRIPTION:    Set physical page for linear address in other thread.
;
;           PARAMETERS:     BP          Thread
;                           EDX         Linear address
;                           EBX:EAX     Physical address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_thread_page_entry32    Proc near
    push ds
    push es
    push ebx
    push edx
    push si
;
    or ebx,ebx
    jz stppok32
;
    int 3

stppok32:    
    push eax
;
    mov ax,system_data_sel
    mov ds,ax
    RequestSpinlock ds:page_spinlock
;
    mov ax,process_dir_sel
    mov ds,ax
    mov si,(alias_linear SHR 20) AND 0FFFh
    mov es,bp
    mov eax,es:p_cr3
    or ax,803h
    mov [si],eax
    mov eax,cr3
    mov cr3,eax
;
    mov eax,alias_linear
    shr edx,10
    and dl,0FCh
    add edx,eax
    mov ebx,edx
    shr edx,10
    and dl,0FCh
    mov ax,process_page_sel
    mov ds,ax
    mov eax,[edx]
    test al,1
    jnz set_thread_phys_do32
;
    pop eax
    jmp set_thread_phys_done32

set_thread_phys_do32:     
    mov ax,flat_sel
    mov ds,ax
    pop eax
    mov [ebx],eax

set_thread_phys_done32:
    mov dx,system_data_sel
    mov ds,dx
    ReleaseSpinlock ds:page_spinlock
;
    pop si
    pop edx
    pop ebx
    pop es
    pop ds
    ret
local_set_thread_page_entry32    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_thread_page_dir32
;
;           DESCRIPTION:    Get physical page directory for other thread
;
;           PARAMETERS:     BP          Thread
;                           EDX         Linear address
;
;           RETURNS:        EBX:EAX     Physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_thread_page_dir32    Proc near
    push ds
    push edx
    push esi
;    
    mov esi,cr3
;    
    mov ds,bp    
    mov eax,ds:p_cr3
    mov bx,process_dir_sel
    mov ds,bx
;
    shr edx,20
    and dl,0FCh
;
    cli
    mov cr3,eax
    mov eax,[edx]
    mov cr3,esi
    sti
    xor ebx,ebx
;
    pop esi
    pop edx
    pop ds    
    ret
local_get_thread_page_dir32    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_fork32
;
;           DESCRIPTION:    Create fork page tables
;
;           PARAMETERS:     EAX         CR3
;                           DS          Process selector
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_fork32  Proc near
    pushad
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    xor ebx,ebx
    mov al,3
    SetPageEntry    
    mov ds:pf_page_dir,edx
;
    mov eax,3000h
    AllocateBigLinear
    mov ds:pf_page_table,edx
;
    popad
    ret
local_create_fork32  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_delete_fork32
;
;           DESCRIPTION:    Create delete page table, 32-bit version
;
;           PARAMETERS:     DS          Process selector
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_delete_fork32  Proc near
    push ds
    pushad
;
    xor eax,eax
    xor ebx,ebx
    mov edx,ds:pf_page_table
    mov ecx,3

ldfTableLoop32:
    SetPageEntry
    add edx,1000h
    loop ldfTableLoop32
;
    mov edx,ds:pf_page_table
    mov ecx,3000h
    FreeLinear
;
    xor eax,eax
    xor ebx,ebx
    mov edx,ds:pf_page_dir
    SetPageEntry
;
    mov edx,ds:pf_page_dir
    mov ecx,1000h
    FreeLinear
;
    popad
    pop ds
    ret
local_delete_fork32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MergeDirEntry32
;
;           DESCRIPTION:    Merge dir entry
;
;           PARAMETERS:     DS         Source process sel
;                           ES         Destination process sel
;                           FS         Flat sel
;                           ESI        Source entry
;                           EDI        Destination entry
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MergeDirEntry32  Proc near
    pushad
;
    xor ebx,ebx
    mov eax,fs:[esi]
    mov edx,ds:pf_page_table
    SetPageEntry
    mov esi,edx
;
    mov eax,fs:[edi]
    mov edx,es:pf_page_table
    SetPageEntry
    mov edi,edx
;
    mov ecx,400h

mdeLoop32:
    mov eax,fs:[edi]
    test al,1
    jnz mdeSave32
;
    mov eax,fs:[esi]
    test al,1
    jz mdeSave32
;
    test al,2
    jz mdeSave32
;
    and al,NOT 2
    or ax,400h
    mov fs:[esi],eax

mdeSave32:
    mov fs:[edi],eax
;
    add esi,4
    add edi,4
    loop mdeLoop32
;
    popad
    ret
MergeDirEntry32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_start_fork32
;
;           DESCRIPTION:    Fork page tables
;
;           PARAMETERS:     DS         Source process sel
;                           ES         Destination process sel
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_start_fork32  Proc near
    push fs
    pushad
;
    mov esi,ds:pf_page_dir
    mov edi,es:pf_page_dir
;
    mov eax,flat_sel
    mov fs,eax
;
    mov ecx,process_page_linear SHR 22

lsfuLoop32:
    mov eax,fs:[edi]
    test al,1
    jz lsfuFree32
;
    call MergeDirEntry32
    jmp lsfuSave32

lsfuFree32:
    mov eax,fs:[esi]
    test al,1
    jz lsfuSave32
;
    test al,2
    jz lsfuSave32
;
    and al,NOT 2
    or ax,400h
    mov fs:[esi],eax

lsfuSave32:
    mov fs:[edi],eax
;
    add esi,4
    add edi,4
    loop lsfuLoop32
;
    popad
    pop fs
    ret
local_start_fork32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDirRefCount32
;
;           DESCRIPTION:    Get page dir reference count
;
;           PARAMETERS:     DS             Program sel
;                           ES             Process sel
;                           FS             Flat sel
;                           ESI            Offset within dir selector
;                           EBP            Process index
;                           EAX            Entry data
;
;           RETURNS:        ECX            References
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDirRefCount32  Proc near
    push edx
    push edi
    push ebp
;
    and ax,0F000h
;
    movzx ecx,ds:pr_page_table_count
    xor ebp,ebp
    xor edi,edi

gdrLoop32:
    mov edx,ds:[edi].pr_page_dir_arr
    mov edx,fs:[edx+esi]
    and dx,0F000h
    cmp eax,edx
    jne gdrNext32
;
    inc ebp

gdrNext32:
    add edi,4
    loop gdrLoop32
;
    mov ecx,ebp
;
    pop ebp
    pop edi
    pop edx
    ret
GetDirRefCount32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPageRefCount32
;
;           DESCRIPTION:    Get page reference count
;
;           PARAMETERS:     DS             Program sel
;                           ES             Process sel
;                           FS             Flat sel
;                           ESI            Offset within page selector
;                           EAX            Entry data
;
;           RETURNS:        ECX            References
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPageRefCount32  Proc near
    push edx
    push edi
    push ebp
;
    and ax,0F000h
;
    movzx ecx,ds:pr_page_table_count
    xor ebp,ebp
    xor edi,edi

gprLoop32:
    mov edx,ds:[edi].pr_temp_arr
    or edx,edx
    jz gprNext32
;
    mov edx,fs:[edx+esi]
    test dl,1
    jz gprNext32
;
    and dx,0F000h
    cmp eax,edx
    jne gprNext32
;
    inc ebp

gprNext32:
    add edi,4
    loop gprLoop32
;
    mov ecx,ebp
;
    pop ebp
    pop edi
    pop edx
    ret
GetPageRefCount32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupDetachTables32
;
;           DESCRIPTION:    Setup detach page tables
;
;           PARAMETERS:     DS             Program sel
;                           ES             Process sel
;                           FS             Flat sel
;                           ESI            Offset within dir selector
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDetachTables32  Proc near
    pushad
;
    movzx ecx,ds:pr_page_table_count
    xor edi,edi

sdtLoop32:
    xor ebp,ebp
;
    mov edx,ds:[edi].pr_page_dir_arr
    mov eax,fs:[edx+esi]
    test al,1
    jz sdtSave32
;
    xor ebx,ebx
    and ax,0F000h
    or al,67h
    mov edx,ds:[edi].pr_page_table_arr
    SetPageEntry
    mov ebp,edx

sdtSave32:
    mov ds:[edi].pr_temp_arr,ebp
    add edi,4
    loop sdtLoop32
;
    popad
    ret
SetupDetachTables32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoDetachTables32
;
;           DESCRIPTION:    Detach page tables
;
;           PARAMETERS:     DS             Program sel
;                           ES             Process sel
;                           FS             Flat sel
;                           EBP            Process index
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoDetachTables32  Proc near
    pushad
;
    mov ecx,1024
    xor esi,esi
    mov edi,ds:[ebp].pr_page_table_arr

ddtLoop32:
    mov eax,fs:[esi+edi]
    test al,1
    jz ddtNext32
;
    push ecx
    call GetPageRefCount32
    cmp ecx,1
    je ddtFree32
;
    ja ddtOk32
;
    int 3

ddtFree32:
    xor ebx,ebx
    FreePhysical

ddtOk32:
    pop ecx

ddtNext32:
    add esi,4
    loop ddtLoop32
;
    popad
    ret
DoDetachTables32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DetachDirEntry32
;
;           DESCRIPTION:    Detach single dir entry
;
;           PARAMETERS:     DS             Program sel
;                           ES             Process sel
;                           FS             Flat sel
;                           ESI            Offset within dir selector
;                           EBP            Process index
;                           EAX            Entry data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DetachDirEntry32  Proc near
    push ecx
    call GetDirRefCount32
    cmp ecx,1
    je ddeFree32
;
    ja ddeDone32
;
    int 3

ddeFree32:
    call SetupDetachTables32
    call DoDetachTables32
;
    xor ebx,ebx
    FreePhysical

ddeDone32:
    pop ecx
    ret
DetachDirEntry32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_detach_fork32
;
;           DESCRIPTION:    Detach current process from fork
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_detach_fork32  Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ax,flat_sel
    mov fs,eax
;
    GetThread
    mov gs,ax
    mov ds,gs:p_prog_sel
    mov es,gs:p_proc_sel
    mov edi,es:pf_page_dir
;
    xor ebp,ebp
    movzx ecx,ds:pr_page_table_count
    xor esi,esi

ldfProcLoop32:
    cmp edi,ds:[esi].pr_page_dir_arr
    jne ldfProcNext32
;
    mov ebp,esi
    jmp ldfProcDone32

ldfProcNext32:
    add esi,4
    loop ldfProcLoop32
;
    int 3

ldfProcDone32:
    mov ecx,process_page_linear SHR 22
    xor esi,esi

ldfDirLoop32:
    mov eax,fs:[esi+edi]
    test al,1
    jz ldfDirNext32
;
    call DetachDirEntry32

ldfDirNext32:
    xor eax,eax
    mov fs:[esi+edi],eax
;
    add esi,4
    loop ldfDirLoop32
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
local_detach_fork32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_cleanup_fork32
;
;           DESCRIPTION:    Cleanup fork page tables
;
;           PARAMETERS:     BX       Program ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_cleanup_fork32  Proc near
    push ds
    pushad
;
    movzx ebx,bx
    GetProgramSel
    jc cfDone32
;
    mov ds,eax
    mov esi,ds:pr_page_dir_arr
    mov eax,flat_sel
    mov ds,eax
    mov ecx,process_page_linear SHR 22

cfLoop32:
    mov eax,ds:[esi]
    test al,1
    jz cfNext32
;
    test ax,400h
    jz cfNext32
;
    and ax,NOT 400h
    or al,2
    mov ds:[esi],eax

cfNext32:
    add esi,4
    loop cfLoop32

cfDone32:
    popad
    pop ds
    ret
local_cleanup_fork32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_cow_dir32
;
;           DESCRIPTION:    Copy-on-write directory
;
;           PARAMETERS:     EDX         Linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_cow_dir32  Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,eax
;
    shr edx,20
    and dl,0FCh
;
    GetThread
    mov es,ax
    mov ds,es:p_proc_sel
    mov esi,ds:pf_page_dir
    mov esi,fs:[esi+edx]
    and si,0F000h
;
    mov ds,es:p_prog_sel
    movzx ecx,ds:pr_page_table_count
    mov ebx,OFFSET pr_page_dir_arr
    xor ebp,ebp

lcowdFind32:
    mov eax,ds:[ebx]
    mov eax,fs:[eax+edx]
    test al,1
    jz lcowdNext32
;
    and ax,0F000h
    cmp eax,esi
    jnz lcowdNext32
;
    inc ebp

lcowdNext32:
    add ebx,4
    loop lcowdFind32
;
    cmp ebp,1
    je lcowdUnmark32
;
    ja lcowdCopy32
;
    int 3

lcowdCopy32:
    push edx
;
    mov ds,es:p_proc_sel
    mov edx,ds:pf_page_table
    mov eax,esi
    or al,3
    xor ebx,ebx
    SetPageEntry
    mov esi,edx
;
    add edx,1000h
    AllocatePhysical32
    or al,67h
    SetPageEntry
    mov edi,edx
;
    mov ecx,1024
    push eax

lcowdLoop32:
    mov eax,fs:[esi]
    test al,1
    jz lcowdSave32
;
    test al,2
    jz lcowdSave32
;
    and al,NOT 2
    or ax,400h
    mov fs:[esi],eax

lcowdSave32:
    mov fs:[edi],eax
;
    add esi,4
    add edi,4
    loop lcowdLoop32
;
    pop eax
    pop edx
;
    mov esi,ds:pf_page_dir
    mov fs:[esi+edx],eax
    jmp lcowdDone32

lcowdUnmark32:
    mov ds,es:p_proc_sel
    mov esi,ds:pf_page_dir
    mov eax,fs:[esi+edx]
    and ax,NOT 400h
    or al,2
    mov fs:[esi+edx],eax

lcowdDone32:    
    popad
    pop fs
    pop es
    pop ds
    ret
local_cow_dir32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_cow_page32
;
;           DESCRIPTION:    Copy-on-write page table
;
;           PARAMETERS:     EDX         Linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_cow_page32  Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,eax
    GetThread
    mov es,ax
    mov ds,es:p_proc_sel
    mov ebp,ds:pf_page_dir
;
    mov ds,es:p_prog_sel
    movzx ecx,ds:pr_page_table_count
    xor esi,esi
    mov ds:pr_temp_ind,si

lcowpInitLoop32:
    mov ds:[esi].pr_temp_arr,0
    mov edi,ds:[esi].pr_page_dir_arr
    cmp edi,ebp
    jne lcowpNotMine32
;
    mov ds:pr_temp_ind,si

lcowpNotMine32:
    mov eax,edx
    shr eax,20
    and al,0FCh
    mov eax,fs:[edi+eax]
    test al,1
    jz lcowpInitNext32
;
    push edx
    mov edi,edx
    shr edi,10
    and edi,0FFCh
    mov edx,ds:[esi].pr_page_table_arr
    and ax,0F000h
    mov al,3
    xor ebx,ebx
    SetPageEntry
    add edi,edx
    pop edx
;
    mov ds:[esi].pr_temp_arr,edi

lcowpInitNext32:
    add esi,4
    loop lcowpInitLoop32
;
    movzx esi,ds:pr_temp_ind
    mov esi,ds:[esi].pr_temp_arr
    mov esi,fs:[esi]
    and si,0F000h
    xor ebx,ebx
    xor ebp,ebp
    movzx ecx,ds:pr_page_table_count

lcowpFindLoop32:
    mov edx,ds:[ebx].pr_temp_arr
    or edx,edx
    jz lcowpFindNext32
;
    mov eax,fs:[edx]
    test al,1
    jz lcowpFindNext32
;
    and ax,0F000h
    cmp eax,esi
    jne lcowpFindNext32
;
    inc ebp

lcowpFindNext32:
    add ebx,4
    loop lcowpFindLoop32
;
    cmp ebp,1
    je lcowpUnmark32
;
    ja lcowpCopy32
;
    int 3

lcowpCopy32:
    movzx ebp,ds:pr_temp_ind
    mov ebp,ds:[ebp].pr_temp_arr
    mov eax,fs:[ebp]
    and ax,0F000h
    or al,67h
    xor ebx,ebx
;
    mov ds,es:p_proc_sel
    mov edx,ds:pf_page_table
    add edx,1000h
    SetPageEntry
    mov esi,edx
;
    add edx,1000h
    AllocatePhysical32
    or al,67h
    SetPageEntry
    mov edi,edx
;
    push es
    mov ecx,flat_sel
    mov es,ecx
    mov ecx,1024
    rep movs dword ptr es:[edi],es:[esi]
    pop es
;
    mov fs:[ebp],eax
    jmp lcowpDone32

lcowpUnmark32:
    movzx edx,ds:pr_temp_ind
    mov edx,ds:[edx].pr_temp_arr
    mov eax,fs:[edx]
    and ax,NOT 400h
    or al,2
    mov fs:[edx],eax

lcowpDone32:
    popad
    pop fs
    pop es
    pop ds
    ret
local_cow_page32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           uses_pae32
;
;           DESCRIPTION:    Check for PAE paging, 32-bit version
;
;           RETURNS:        NC     Uses PAE paging
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_uses_pae32  Proc near
    stc
    ret
local_uses_pae32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_init_process64
;
;           DESCRIPTION:    Init process paging
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_init_process64     Proc near
    mov ax,sys_page_sel
    mov ds,ax
    mov ax,system_data_sel
    mov es,ax
    mov ecx,es:rom1_size
    or ecx,ecx
    jz ipUnmapDone1_64
;
    mov edx,es:rom1_base
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr edx,9
    shr ecx,12

ipUnmapLoop1_64:
    mov dword ptr [edx],0
    add edx,8
    loop ipUnmapLoop1_64

ipUnmapDone1_64:
    mov ecx,es:rom2_size
    or ecx,ecx
    jz ipUnmapDone2_64
;
    mov edx,es:rom2_base
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr edx,9
    shr ecx,12

ipUnmapLoop2_64:
    mov dword ptr [edx],0
    add edx,8
    loop ipUnmapLoop2_64

ipUnmapDone2_64:
    mov ax,sys_dir_sel
    mov ds,ax
    mov bx,(sys_page_linear SHR 18) AND 3FFFh
    mov ebx,[bx]
    and bx,0F000h
;
    mov ax,sys_page_sel
    mov ds,ax
    mov ax,process_page_sel
    mov es,ax
    mov edx,8

ipFreeStartupLoop64:
    mov eax,[edx]
    test al,1
    jz ipFreeStartupDone64
;
    and ax,0F000h
    cmp eax,ebx
    jae ipFreeStartupZero64
;
    xor ebx,ebx
    FreePhysical

ipFreeStartupZero64:
    xor eax,eax
    mov [edx],eax
    mov es:[edx],eax
    add edx,8
    jmp ipFreeStartupLoop64

ipFreeStartupDone64:  
    mov ax,system_data_sel
    mov es,ax
    mov eax,es:flat_base
    or eax,eax
    jnz ipFlatOk64
;    
    xor ebx,ebx
    mov [ebx],ebx

ipFlatOk64:    
    mov eax,cr3
    mov cr3,eax
    ret
local_init_process64     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Create_process64
;
;           DESCRIPTION:    Create process paging environment
;
;           RETURNS:        EAX         CR3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_process64       PROC near
    push ds
    push es
;    
    mov eax,6000h
    AllocateGlobalMem
;   
    mov bx,es
    GetSelectorBaseSize
;
    AllocatePhysical32
    or al,3
    SetPageEntry
;    
    xor di,di
    mov cx,400h
    xor eax,eax
    rep stosd
;     
    mov ax,sys_dir_sel
    mov ds,ax
    mov di,1000h
    mov ecx,sys_page_linear
    shr ecx,20
    xor eax,eax
    rep stosd
;    
    mov eax,sys_page_linear
    mov esi,eax
    shr esi,18
    shr eax,20
    mov cx,1000h
    sub cx,ax
    rep movsd
;
    mov ax,sys_page_sel
    mov ds,ax
    xor si,si
    mov cx,400h
    xor eax,eax
    rep movsd
;    
    shr edx,9
;
    mov ax,sys_page_sel
    mov ds,ax
    mov di,1000h
    mov eax,[edx+28h]
    mov es:[di],eax
    mov eax,[edx+2Ch]
    mov es:[di+4],eax
;
    mov cx,4
    mov esi,8
    mov ebx,process_page_linear
    shr ebx,18
    add bx,di
    xor di,di

create_process_loop64:    
    mov eax,[edx+esi]
    mov al,7
    mov es:[bx],eax
    and ax,0F000h
    mov al,1
    mov es:[di],eax
;
    add esi,4
    add bx,4
    add di,4
;        
    mov eax,[edx+esi]
    mov es:[bx],eax
    mov es:[di],eax
;
    add esi,4
    add bx,4
    add di,4
;    
    loop create_process_loop64
;
    mov eax,[edx]        
    xor al,al
;
    xor ebx,ebx
    mov [edx],ebx
    mov [edx+4],ebx
;    
    mov [edx+8],ebx
    mov [edx+0Ch],ebx
;    
    mov [edx+10h],ebx
    mov [edx+14h],ebx
;
    mov [edx+18h],ebx
    mov [edx+1Ch],ebx
;
    mov [edx+20h],ebx
    mov [edx+24h],ebx
;
    mov [edx+28h],ebx
    mov [edx+2Ch],ebx
    FreeMem
;
    pop es
    pop ds
    ret
local_create_process64       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Create_long_process64
;
;           DESCRIPTION:    Create long process paging environment
;
;           RETURNS:        FS          Thread sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_long_process64       PROC near
    push ds
    push es
;    
    mov eax,8000h
    AllocateGlobalMem
    mov bx,es
    GetSelectorBaseSize
;
    add edx,7000h
    AllocatePhysical32
    or al,3
    SetPageEntry
    sub edx,7000h
    push eax
;    
    mov di,1000h
    mov cx,400h
    xor eax,eax
    rep stosd
;     
    mov ax,sys_dir_sel
    mov ds,ax
    mov di,2000h
    mov ecx,system_mem_start
    shr ecx,20
    xor eax,eax
    rep stosd               ; dir selector at 2000h
;    
    mov eax,system_mem_start
    mov esi,eax
    shr esi,18
    shr eax,20
    mov cx,1000h
    sub cx,ax
    rep movsd               ; dir ptr entries at 2000h, 3000h, 4000h, 5000h
;
    mov ax,sys_page_sel
    mov ds,ax
    xor si,si
    mov cx,400h
    xor eax,eax
    rep movsd               ; lower mem page at 6000h
;    
    shr edx,9
;
    mov ax,sys_page_sel
    mov ds,ax
    mov di,2000h
    mov eax,[edx+48]
    mov es:[di],eax
    mov eax,[edx+52]
    mov es:[di+4],eax
;
    mov cx,4
    mov esi,16
    mov ebx,process_page_linear
    shr ebx,18
    add bx,di
    mov di,1000h

create_long_process_loop64:    
    mov eax,[edx+esi]
    mov es:[bx],eax
    mov es:[di],eax
;
    add esi,4
    add bx,4
    add di,4
;        
    mov eax,[edx+esi]
    mov es:[bx],eax
    mov es:[di],eax
;
    add esi,4
    add bx,4
    add di,4
;    
    loop create_long_process_loop64
;
    mov di,7000h
    mov eax,[edx+8]          
    mov al,3
    stosd
    mov eax,[edx+12]
    stosd
;    
    mov cx,3FCh
    xor eax,eax
    rep stosd
;
    pop eax
    mov al,3
    stosd
    mov dword ptr es:[di],0    
;
    xor al,al
;
    mov dx,es
    mov fs,dx
    pop es
    pop ds
    mov es:p_cr3,eax
    ret
local_create_long_process64       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_free_process64
;
;           DESCRIPTION:    Free process paging
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_free_process64     Proc near
    push ds
    push es
    pushad
;
    mov bx,process_page_sel
    mov ds,bx
    mov bx,process_dir_sel
    mov es,bx
;
    GetFlatSize
    xor esi,esi
    mov ecx,eax
    shr ecx,21
    xor edi,edi

fpDirLoop64:
    mov eax,es:[edi]
    test al,1
    jz fpNextDir64
;
    test ax,800h
    jnz fpNextDir64
;
    push cx
    mov cx,200h

fpPageLoop64:
    xor eax,eax
    xor ebx,ebx
    xchg eax,[esi]
    add esi,4
    xchg ebx,[esi]
    add esi,4
    test al,1
    jz fpNextPage64
;
    test ax,800h
    jnz fpNextPage64
;
    FreePhysical

fpNextPage64:
    loop fpPageLoop64
;
    pop cx
    xor eax,eax
    xchg eax,es:[edi]
    xor ebx,ebx
    xchg ebx,es:[edi+4]
;
    FreePhysical
    jmp fpNextDirPage64
    
fpNextDir64:
    add esi,1000h

fpNextDirPage64:
    add edi,8
    loop fpDirLoop64
;
    GetFlatSize
    shr eax,21
    mov cx,800h
    sub cx,ax
    mov bx,sys_dir_sel
    mov ds,bx

fpGlobalLoop64:
    mov eax,es:[edi]
    test al,1
    jz fpGlobalNext64
;
    test ax,800h
    jnz fpGlobalNext64
;
    and ax,0F000h
    mov ebx,[edi]
    and bx,0F000h
    cmp eax,ebx
    jne fpGlobalTestFixed
;
    mov eax,es:[edi+4]
    cmp eax,[edi+4]
    je fpGlobalNext64

fpGlobalTestFixed:
    cmp edi,(fixed_process_linear SHR 18) AND 03FFFh
    je fpGlobalNext64
;    
    cmp edi,((fixed_process_linear SHR 18) AND 03FFFh) + 8
    je fpGlobalNext64
;
    cmp edi,(process_page_linear SHR 18) AND 03FFFh
    je fpGlobalNext64
;    
    cmp edi,((process_page_linear SHR 18) AND 03FFFh) + 8
    je fpGlobalNext64
;    
    cmp edi,((process_page_linear SHR 18) AND 03FFFh) + 16
    je fpGlobalNext64
;    
    cmp edi,((process_page_linear SHR 18) AND 03FFFh) + 24
    je fpGlobalNext64
;
    xor eax,eax
    xchg eax,es:[edi]
    xor ebx,ebx
    xchg ebx,es:[edi+4]
    FreePhysical

fpGlobalNext64:
    add edi,8
    sub cx,1
    jnz fpGlobalLoop64
;
    mov bx,process_page_sel
    mov ds,bx
    mov bx,process_dir_sel
    mov es,bx
;
    mov esi,fixed_process_linear SHR 9
    mov edi,fixed_process_linear SHR 18
    mov ecx,fixed_process_size SHR 21

fpProcDirLoop64:
    mov eax,es:[edi]
    test al,1
    jz fpProcNextDir64
;
    push cx
    mov cx,200h

fpProcPageLoop64:
    xor eax,eax
    xor ebx,ebx
    xchg eax,[esi]
    add esi,4
    xchg ebx,[esi]
    add esi,4
    test al,1
    jz fpProcNextPage64
;
    FreePhysical

fpProcNextPage64:
    loop fpProcPageLoop64
;
    pop cx
    xor eax,eax
    xchg eax,es:[edi]
    xor ebx,ebx
    xchg ebx,es:[edi+4]
;
    FreePhysical
    jmp fpProcNextDirPage64
    
fpProcNextDir64:
    add esi,1000h

fpProcNextDirPage64:
    add edi,8
    loop fpProcDirLoop64
;
    popad
    pop es
    pop ds
    ret
local_free_process64     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateServ64
;
;           DESCRIPTION:    Create 64-bit serv sel
;
;           RETURNS:        BX     Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_serv64       PROC near
    push es
    push eax
    push ecx
    push edi
;
    mov eax,(sys_page_linear - serv_linear) SHR 18
    add eax,OFFSET serv_dir_arr
    mov ecx,eax
    AllocateGlobalMem
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
    mov bx,es
;
    pop edi
    pop ecx
    pop eax
    pop es
    ret
local_create_serv64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeDirPae
;
;           DESCRIPTION:    Free page dir, PAE version
;
;           PARAMETERS:     EBX:EAX     Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDirPae     Proc near
    push edx
    push esi
;    
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
    SetPageEntry   
;
    mov ecx,512
    mov esi,edx

fdpaeLoop:
    mov eax,es:[esi]
    mov ebx,es:[esi+4]
    test al,1
    jz fdpaeNext
;
    FreePhysical

fdpaeNext:
    add esi,8    
    loop fdpaeLoop
;    
    mov ecx,1000h
    FreeLinear
;
    pop esi
    pop edx
    ret
FreeDirPae      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_delete_process64
;
;           DESCRIPTION:    Delete process paging
;
;           PARAMETERS:     EAX     CR3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_delete_process64     Proc near
    push eax
    mov ax,flat_sel
    mov es,ax
    mov eax,1000h
    AllocateBigLinear
    pop eax
    xor ebx,ebx
    mov al,3
    SetPageEntry    
;
    mov esi,edx
    mov eax,es:[esi]
    mov ebx,es:[esi+4]
    call FreeDirPae
;
    add esi,8
    mov eax,es:[esi]
    mov ebx,es:[esi+4]
    FreePhysical
;
    add esi,8
    mov eax,es:[esi]
    mov ebx,es:[esi+4]
    FreePhysical
;
    add esi,8
    mov eax,es:[esi]
    mov ebx,es:[esi+4]
    FreePhysical
;
    mov ecx,1000h
    FreeLinear        
    ret
local_delete_process64     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_page_entry64
;
;           DESCRIPTION:    Get physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        EBX:EAX         physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_page_entry64       Proc near
    push ds
    mov ax,process_page_sel
    mov ds,ax
    mov eax,edx
    shr eax,9
    and al,0F8h
    mov ebx,[eax+4]
    mov eax,[eax]
    pop ds
    ret
local_get_page_entry64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_page_entry64
;
;           DESCRIPTION:    Set physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_page_entry64       Proc near
    push ds
    push eax
    push ecx
;    
    push edx
    mov cx,process_page_sel
    mov ds,cx
    shr edx,9
    and dl,0F8h
    mov [edx+4],ebx
    xchg eax,[edx]
    pop edx
    test al,1
    jz sppDone64
;
    mov cx,1
    FlushTlb

sppDone64:
    pop ecx
    pop eax
    pop ds
    ret
local_set_page_entry64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_sys_page_entry64
;
;           DESCRIPTION:    Get physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        EBX:EAX         physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_sys_page_entry64       Proc near
    push ds
    mov ax,sys_page_sel
    mov ds,ax
    mov eax,edx
    shr eax,9
    and al,0F8h
    mov ebx,[eax+4]
    mov eax,[eax]
    pop ds
    ret
local_get_sys_page_entry64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_sys_page_entry64
;
;           DESCRIPTION:    Set physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_sys_page_entry64       Proc near
    push ds
    push eax
    push ecx
    push edx
;
    mov cx,sys_page_sel
    mov ds,cx
    shr edx,9
    and dl,0F8h
    mov [edx],eax
    mov [edx+4],ebx
;
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
local_set_sys_page_entry64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_page_dir_attrib64
;
;           DESCRIPTION:    Get page dir attributes
;
;           RETURNS:        ESI         linear address space size per entry
;                           CX          # of entries per 32-bit page dir entries
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_page_dir_attrib64       Proc near
    mov cx,2
    mov esi,200000h
    ret
local_get_page_dir_attrib64    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_fault_to_dir64
;
;           DESCRIPTION:    Convert page fault to dir position
;
;           PARAMETERS:     EDX         Linear address
;
;           RETURNS:        EDX         Page dir address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_fault_to_dir64       Proc near
    sub edx,process_page_linear
    shl edx,9
    ret
local_fault_to_dir64    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_page_dir64
;
;           DESCRIPTION:    Get physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_page_dir64       Proc near
    push ds
    push edx
;    
    mov ax,process_dir_sel
    mov ds,ax
    shr edx,18
    and dl,0F8h
    mov eax,[edx]
    mov ebx,[edx+4]
;    
    pop edx
    pop ds
    ret
local_get_page_dir64    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_sys_page_dir64
;
;           DESCRIPTION:    Get physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_sys_page_dir64       Proc near
    push ds
    push edx
;    
    mov ax,sys_dir_sel
    mov ds,ax
    shr edx,18
    and dl,0F8h
    mov eax,[edx]
    mov ebx,[edx+4]
;    
    pop edx
    pop ds
    ret
local_get_sys_page_dir64    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_serv_page_dir64
;
;           DESCRIPTION:    Get serv physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           ES          thread
;
;           RETURNS:        EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_serv_page_dir64       Proc near
    push ds
    push edx
;    
    mov ds,es:p_serv_sel
    sub edx,serv_linear
    shr edx,18
    and dl,0F8h
    mov eax,[edx].serv_dir_arr
    mov ebx,[edx+4].serv_dir_arr
;    
    pop edx
    pop ds
    ret
local_get_serv_page_dir64    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_page_dir64
;
;           DESCRIPTION:    Set physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_page_dir64       Proc near
    push ds
    push cx
    push edx
;    
    mov cx,process_dir_sel
    mov ds,cx
    shr edx,18
    and dl,0F8h
    mov [edx],eax
    mov [edx+4],ebx
;    
    pop edx
    pop cx
    pop ds
    ret
local_set_page_dir64    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_sys_page_dir64
;
;           DESCRIPTION:    Set physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_sys_page_dir64       Proc near
    push ds
    push cx
    push edx
;    
    mov cx,sys_dir_sel
    mov ds,cx
    shr edx,18
    and dl,0F8h
    mov [edx],eax
    mov [edx+4],ebx
;    
    pop edx
    pop cx
    pop ds
    ret
local_set_sys_page_dir64    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_serv_page_dir64
;
;           DESCRIPTION:    Set serv physical dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           ES          thread
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_serv_page_dir64       Proc near
    push ds
    push edx
;    
    mov ds,es:p_serv_sel
    sub edx,serv_linear
    shr edx,18
    and dl,0F8h
    mov [edx].serv_dir_arr,eax
    mov [edx+4].serv_dir_arr,ebx
;    
    pop edx
    pop ds
    ret
local_set_serv_page_dir64    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_page_dir64
;
;           DESCRIPTION:    Create page directory entry
;
;           PARAMETERS:     EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_page_dir64       Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    push edx
    mov bx,process_dir_sel
    mov ds,bx
    shr edx,18
    and dx,3FF8h
    call local_allocate_physical
    mov al,7
    mov [edx],eax    
    mov [edx+4],ebx
    pop edx
;
    shr edx,9
    and dx,0F000h
    mov bx,process_page_sel
    mov ds,bx
;
    mov cx,400h
    xor ebx,ebx

cpdInit64:
    mov [edx],ebx
    add edx,4
    loop cpdInit64
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
local_create_page_dir64    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_sys_page_dir64
;
;           DESCRIPTION:    Create sys page directory entry
;
;           PARAMETERS:     EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_sys_page_dir64       Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    push edx
    mov bx,sys_dir_sel
    mov ds,bx
    shr edx,18
    and dx,3FF8h
    call local_allocate_physical
    mov al,7
    mov [edx],eax    
    mov [edx+4],ebx
    pop edx
;
    shr edx,9
    and dx,0F000h
    mov bx,sys_page_sel
    mov ds,bx
;
    mov cx,400h
    xor ebx,ebx

cspdInit64:
    mov [edx],ebx
    add edx,4
    loop cspdInit64
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
local_create_sys_page_dir64    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_serv_page_dir64
;
;           DESCRIPTION:    Create serv page directory entry
;
;           PARAMETERS:     EDX         linear address
;                           ES          thread
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_serv_page_dir64       Proc near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    mov ds,es:p_serv_sel
    sub edx,serv_linear
    shr edx,18
    and dx,3FF8h
    call local_allocate_physical
    mov al,7
    mov [edx].serv_dir_arr,eax    
    mov [edx+4].serv_dir_arr,ebx
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    mov al,13h
    call local_set_page_entry64
;
    mov bx,flat_sel
    mov ds,bx
    mov cx,400h
    xor ebx,ebx
    push edx

cshpdInit64:
    mov [edx],ebx
    add edx,4
    loop cshpdInit64
;
    pop edx
    xor eax,eax
    xor ebx,ebx
    call local_set_page_entry64
;
    mov ecx,1000h
    FreeLinear
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
local_create_serv_page_dir64    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_has_page_entry64
;
;           DESCRIPTION:    Check physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        NC          valid
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_has_page_entry64       Proc near
    push ds
    push eax
;    
    mov ax,process_page_sel
    mov ds,ax
    mov eax,edx
    shr eax,9
    and al,0F8h
    mov eax,[eax]
    test al,1
    clc
    jnz hpeDone64
;
    stc

hpeDone64:    
    pop eax    
    pop ds
    ret
local_has_page_entry64       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_reserve_page_entries64
;
;           DESCRIPTION:    Reserve page entries 
;
;           PARAMETERS:     ECX         number of entries
;                           EDX         start linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_reserve_page_entries64       Proc near
    push eax
;    
    mov ax,process_page_sel
    mov ds,ax
    shr edx,9
;
    push ecx
    push edx

rpeLoop64:
    mov al,[edx]
    test al,7
    jnz rpePopFail64
;    
    add edx,8
    sub ecx,1
    jnz rpeLoop64
;    
    pop edx
    pop ecx
;
    push ecx    

rpeMark64:
    mov eax,2
    mov [edx],eax
    add edx,8
;    
    sub ecx,1
    jnz rpeMark64
;
    pop ecx
    clc
    jmp rpeDone64

rpePopFail64:
    pop edx
    pop ecx
    stc

rpeDone64:    
    pop eax
    ret
local_reserve_page_entries64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_allocate_page_entries64
;
;           DESCRIPTION:    Allocate page entries 
;
;           PARAMETERS:     EAX         allocate limit
;                           ECX         number of entries
;                           EDX         start linear address
;
;           RETURNS:        EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_allocate_page_entries64       Proc near
    push eax
    push ebx
    push esi
;
    mov esi,eax
    shr edx,9
    shr esi,9
;    
    mov bx,process_page_sel
    mov ds,bx
;    
    xor ebx,ebx

apeLoop64:
    cmp edx,esi
    stc
    je apeFail64
;
    inc ebx
    mov al,[edx]
    test al,7
    jz apeNext64
;    
    xor ebx,ebx
    
apeNext64:
    add edx,8
    cmp ecx,ebx
    jne apeLoop64
;
    mov eax,ecx
    shl eax,3
    sub edx,eax
;
    push edx
    push ecx
;    
    mov eax,2
    
apeMark64:
    mov [edx],eax
    add edx,8
    sub ecx,1
    jnz apeMark64
;
    pop ecx
    pop edx
;    
    shl edx,9
    clc
    jmp apeDone64

apeFail64:
    stc

apeDone64:
    pop esi
    pop ebx
    pop eax
    ret
local_allocate_page_entries64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_allocate_sys_page_entries64
;
;           DESCRIPTION:    Allocate sys page entries 
;
;           PARAMETERS:     EAX         allocate limit
;                           ECX         number of entries
;                           EDX         start linear address
;
;           RETURNS:        EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_allocate_sys_page_entries64       Proc near
    push ds
    push es
    push eax
    push ebx
    push esi
    push edi
;
    mov esi,eax
    shr edx,9
    shr esi,9
;
    mov edi,edx
    shr edi,9
    and di,0FFF8h
;    
    mov bx,sys_page_sel
    mov ds,bx
    mov bx,sys_dir_sel
    mov es,bx
;    
    xor ebx,ebx

aspeCheckDir64:
    mov al,es:[edi]
    test al,1
    jz aspeCheckPage64
;
    test al,80h
    je aspeCheckPage64
;
    xor ebx,ebx
    add edi,8
    mov edx,edi
    shl edx,9
    jmp aspeCheckDir64

aspeLoop64:
    test edx,0FFFh
    jnz aspeCheckPage64
;
    add edi,8
    jmp aspeCheckDir64

aspeCheckPage64:
    cmp edx,esi
    stc
    je aspeFail64
;
    inc ebx
    mov eax,[edx]
    or eax,eax
    jz aspeNext64
;    
    xor ebx,ebx
    
aspeNext64:
    add edx,8
    cmp ecx,ebx
    jne aspeLoop64
;
    mov eax,ecx
    shl eax,3
    sub edx,eax
;
    push edx
    push ecx
;    
    mov eax,2
    
aspeMark64:
    mov [edx],eax
    add edx,8
    sub ecx,1
    jnz aspeMark64
;
    pop ecx
    pop edx
;    
    shl edx,9
    clc
    jmp aspeDone64

aspeFail64:
    stc

aspeDone64:
    pop edi
    pop esi
    pop ebx
    pop eax
    pop es
    pop ds
    ret
local_allocate_sys_page_entries64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_allocate_and_map_sys_dir64
;
;           DESCRIPTION:    Allocate and map sys dir
;
;           PARAMETERS:     ECX         allocate limit
;                           EDX         start linear address
;                           EBX:EAX     physical address
;
;           RETURNS:        EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_allocate_and_map_sys_dir64       Proc near
    push ds
    push eax
    push ecx
;
    push ax
    mov ax,sys_dir_sel
    mov ds,ax
    pop ax
;
    shr edx,18
    and dx,0FFF8h
    shr ecx,18
    and cx,0FFF8h

aamsdLoop:
    cmp edx,ecx
    stc
    je aamsdDone
;
    mov al,ds:[edx]
    test al,1
    jz aamsdFound
;
    add edx,8
    jmp aamsdLoop

aamsdFound:
    mov al,93h
    mov ds:[edx],eax
    mov ds:[edx+4],ebx
    shl edx,18
    clc

aamsdDone:
    pop ecx
    pop eax
    pop ds
    ret
local_allocate_and_map_sys_dir64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_free_page_entries64
;
;           DESCRIPTION:    Free page entries 
;
;           PARAMETERS:     EAX         free signature
;                           ECX         number of entries
;                           EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_free_page_entries64       Proc near
    push ds
    pushad
;   
    or ecx,ecx
    jz fpeDone64
;
    mov esi,eax
    push ecx
    push edx
;
    mov bx,process_page_sel
    mov ds,bx
    shr edx,9
    and dl,0F8h
    
fpeLoop64:
    mov eax,[edx]
    test al,1
    jz fpeMark64
;
    test ax,800h
    jnz fpeMark64
;
    mov ebx,[edx+4]
    FreePhysical

fpeMark64:        
    mov [edx],esi
;
    add edx,8
    sub ecx,1
    jnz fpeLoop64
;    
    pop edx
    pop ecx
    FlushTlb

fpeDone64:
    popad
    pop ds
    ret
local_free_page_entries64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_free_global_page_entries64
;
;           DESCRIPTION:    Free global page entries 
;
;           PARAMETERS:     EAX         free signature
;                           ECX         number of entries
;                           EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_free_global_page_entries64       Proc near
    push ds
    pushad
;   
    or ecx,ecx
    jz fgpeDone64
;
    mov esi,eax
    push ecx
    push edx
;
    mov bx,sys_page_sel
    mov ds,bx
    shr edx,9
    and dl,0F8h
    
fgpeLoop64:
    mov eax,[edx]
    test al,1
    jz fgpeMark64
;
    test ax,800h
    jnz fgpeMark64
;
    mov ebx,[edx+4]
    FreePhysical

fgpeMark64:        
    mov [edx],esi
    mov dword ptr [edx+4],0
;
    add edx,8
    sub ecx,1
    jnz fgpeLoop64
;    
    pop edx
    pop ecx
    FlushTlb

fgpeDone64:
    popad
    pop ds
    ret
local_free_global_page_entries64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_clear_page_entries64
;
;           DESCRIPTION:    Clear page entries 
;
;           PARAMETERS:     EAX         free signature
;                           ECX         number of entries
;                           EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_clear_page_entries64       Proc near
    push ds
    pushad
;   
    or ecx,ecx
    jz lcpeDone64
;
    push ecx
    push edx
;
    mov bx,process_page_sel
    mov ds,bx
    shr edx,9
    and dl,0F8h
    
lcpeLoop64:
    mov [edx],eax
;
    add edx,8
    sub ecx,1
    jnz lcpeLoop64
;    
    pop edx
    pop ecx
    FlushTlb

lcpeDone64:
    popad
    pop ds
    ret
local_clear_page_entries64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_copy_page_entries64
;
;           DESCRIPTION:    Copy page entries 
;
;           PARAMETERS:     ECX         number of entries
;                           ESI         source linear address
;                           EDI         dest linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_copy_page_entries64       Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz cpeDone64
;
    push ecx
    push edi
;
    mov bx,process_page_sel
    mov ds,bx
    shr esi,9
    shr edi,9
    and si,0FFF8h
    and di,0FFF8h
    
cpeLoop64:
    mov ebx,[esi]
    mov [edi],ebx
    mov ebx,[esi+4]
    mov [edi+4],ebx
    add esi,8
    add edi,8
    sub ecx,1
    jnz cpeLoop64
;    
    pop edx
    pop ecx
    FlushTlb

cpeDone64:
    popad
    pop ds
    ret
local_copy_page_entries64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_copy_sys_page_entries64
;
;           DESCRIPTION:    Copy page entries 
;
;           PARAMETERS:     ECX         number of entries
;                           ESI         source linear address
;                           EDI         dest linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_copy_sys_page_entries64       Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz cspeDone64
;
    mov bx,sys_page_sel
    mov ds,bx
    shr esi,9
    shr edi,9
    and si,0FFF8h
    and di,0FFF8h
    
cspeLoop64:
    mov ebx,[esi]
    mov [edi],ebx
    mov ebx,[esi+4]
    mov [edi+4],ebx
    add esi,8
    add edi,8
    sub ecx,1
    jnz cspeLoop64

cspeDone64:
    popad
    pop ds
    ret
local_copy_sys_page_entries64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_move_page_entries64
;
;           DESCRIPTION:    Move page entries
;
;           PARAMETERS:     ECX         number of entries
;                           ESI         source linear address
;                           EDI         dest linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_move_page_entries64       Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz mpeDone64
;
    push esi
    push edi
    push ecx
;    
    mov bx,process_page_sel
    mov ds,bx
    shr esi,9
    shr edi,9
    and si,0FFF8h
    and di,0FFF8h

mpeLoop64:
    mov ebx,[esi+4]
    mov [edi+4],ebx
    mov ebx,2
    xchg ebx,[esi]
    mov [edi],ebx
;
    add esi,8
    add edi,8
    sub ecx,1
    jnz mpeLoop64
;    
    pop ecx
    pop edx
    FlushTlb
;
    pop edx
    FlushTlb

mpeDone64:
    popad
    pop ds
    ret
local_move_page_entries64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           local_emulate_page64
;
;           DESCRIPTION:    Hook page to emulate contents
;
;           PARAMETERS:     EAX         Size
;                           EDX         Linear base
;                           ES:DI       Emulation callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_emulate_page64    PROC near
    push ds
    push eax
    push ecx
    push edx
;
    mov cx,sys_page_sel
    mov ds,cx
    mov ecx,eax
    dec ecx
    shr ecx,12
    inc cx
    shr edx,9
    and dx,0FFF8h
    mov ax,es
    or ax,8006h
    
epMark64:
    mov [edx],ax
    mov [edx+2],di
    mov dword ptr [edx+4],0
    add edx,8
    loop epMark64
;    
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
local_emulate_page64    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           local_hook_page64
;
;           DESCRIPTION:    Loader hook for a specified linear address range
;
;           PARAMETERS:     EAX         Size
;                           EDX         Linear base
;                           ES          Loader selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_hook_page64       PROC near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    mov cx,process_page_sel
    mov ds,cx
;
    or eax,eax
    jz hpDone64
;
    mov ecx,eax
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr edx,9
    shr ecx,12

hpMark64:
    mov eax,[edx]
    test al,1
    jz hpDo64
;
    mov ebx,[edx+4]
    call local_free_physical
;
    mov eax,cr3
    mov cr3,eax
    mov eax,2

hpDo64:
    and al,6
    jz hpNext64
;
    mov ax,6
    mov [edx],ax
    mov [edx+2],es

hpNext64:
    add edx,8
    loop hpMark64

hpDone64:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
local_hook_page64       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           local_unhook_page64
;
;           DESCRIPTION:    Unhook for a specified linear address range
;
;           PARAMETERS:     EAX         Size
;                           EDX         Linear base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_unhook_page64     PROC near
    push ds
    push eax
    push ecx
    push edx
;
    mov cx,process_page_sel
    mov ds,cx
;
    or eax,eax
    jz uhpDone64
;
    mov ecx,eax
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    shr edx,9
    shr ecx,12

uhpMark64:
    mov eax,[edx]
    test al,1
    jnz uhpMark64
;
    and al,6
    cmp al,6
    jne uhpNext64
;
    mov dword ptr [edx],2

uhpNext64:
    add edx,8
    loop uhpMark64

uhpDone64:
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
local_unhook_page64     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_thread_page_entry64
;
;           DESCRIPTION:    Get physical page for linear address in other thread.
;
;           PARAMETERS:     BP          Thread
;                           CX:EDX      Linear address
;
;           RETURNS:        EBX:EAX     Physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_thread_page_entry64    Proc near
    push ds
    push es
    push edx
    push esi
    push edi
    push ebp
;    
    and dx,0F000h
    mov es,bp
    mov ebp,edx
    mov ax,system_data_sel
    mov ds,ax
    RequestSpinlock ds:page_spinlock
;
    mov ax,es
    or ax,ax
    stc
    jz get_thread_page_fail64
;
    mov ax,process_dir_sel
    mov ds,ax
    mov eax,es:p_cr3
    xor ebx,ebx    
;
    mov di,es:p_tss_sel
    or di,di
    jz gtpLong
;
    or cx,cx
    jz gtpBaseOk
;
    stc
    jmp get_thread_page_fail64

gtpLong:
    mov si,(alias_linear SHR 18) AND 3FFFh
    or ax,803h
    mov [si],eax
    mov [si+4],ebx
    mov ebx,cr3
    mov cr3,ebx
;
    mov edi,alias_linear SHR 9
    movzx eax,cx
    shr eax,4
    and ax,0FFF8h
    add edi,eax
;    
    mov bx,process_page_sel
    mov ds,bx
    mov eax,[edi]
    mov ebx,[edi+4]
    test al,1
    stc
    jz get_thread_page_fail64
;
    mov di,process_dir_sel
    mov ds,di
    and ax,0F000h

gtpBaseOk:
    mov si,(alias_linear SHR 18) AND 3FFFh
    or ax,803h
    mov [si],eax
    mov [si+4],ebx
    mov ebx,cr3
    mov cr3,ebx
;
    mov edi,edx
    shr edi,18
    and di,0FFF8h
    add edi,alias_linear
    shr edi,9
    and di,0FFF8h
;
    movzx eax,cx
    and ax,7Fh
    shl ax,5
    add edi,eax
;    
    mov bx,process_page_sel
    mov ds,bx
    mov eax,[edi]
    test al,1
    stc
    jz get_thread_page_fail64
;
    mov ebx,[edi+4]
    mov si,process_dir_sel
    mov ds,si
    mov si,(alias_linear SHR 18) AND 3FFFh
    or ax,803h
    mov [si],eax
    mov [si+4],ebx
    mov ebx,cr3
    mov cr3,ebx
;
    mov edi,edx
    shr edi,9
    and edi,1FFFF8h
    add edi,alias_linear
    mov edx,edi
    shr edi,9
    and di,0FFF8h
    mov bx,process_page_sel
    mov ds,bx
    mov eax,[edi]
    mov ebx,[edi+4]
    test al,1
    jz get_thread_page_fail64
;
    test al,80h
    jz get_thread_page_not_2m_64
;
    and ebp,01FF000h
    or eax,ebp
    and al,7Fh
    jmp get_thread_page_done64
    
get_thread_page_not_2m_64:
    mov ax,flat_sel
    mov ds,ax
    mov eax,[edx]
    mov ebx,[edx+4]
    jmp get_thread_page_done64

get_thread_page_fail64:    
    xor eax,eax
    xor ebx,ebx

get_thread_page_done64:
    mov dx,system_data_sel
    mov ds,dx
    ReleaseSpinlock ds:page_spinlock
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop es
    pop ds
    ret
local_get_thread_page_entry64    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_set_thread_page_entry64
;
;           DESCRIPTION:    Set physical page for linear address in other thread.
;
;           PARAMETERS:     BP          Thread
;                           CX:EDX      Linear address
;                           EBX:EAX     Physical address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_thread_page_entry64    Proc near
    push ds
    push es
    push edx
    push esi
    push edi
;
    push eax
    push ebx
;
    and dx,0F000h
    mov es,bp
;
    mov ax,system_data_sel
    mov ds,ax
    RequestSpinlock ds:page_spinlock
;    
    mov ax,process_dir_sel
    mov ds,ax
    mov eax,es:p_cr3
    xor ebx,ebx    
;
    mov di,es:p_tss_sel
    or di,di
    jz stpLong
;
    or cx,cx
    jz stpBaseOk
;    
    stc
    jmp set_thread_page_fail64

stpLong:
    mov si,(alias_linear SHR 18) AND 3FFFh
    or ax,803h
    mov [si],eax
    mov [si+4],ebx
    mov ebx,cr3
    mov cr3,ebx
;
    mov edi,alias_linear SHR 9
    movzx eax,cx
    shr eax,4
    and ax,0FFF8h
    add edi,eax
;    
    mov bx,process_page_sel
    mov ds,bx
    mov eax,[edi]
    mov ebx,[edi+4]
    test al,1
    stc
    jz set_thread_page_fail64
;
    mov di,process_dir_sel
    mov ds,di
    and ax,0F000h

stpBaseOk:
    mov si,(alias_linear SHR 18) AND 3FFFh
    or ax,803h
    mov [si],eax
    mov [si+4],ebx
    mov ebx,cr3
    mov cr3,ebx
;
    mov edi,edx
    shr edi,18
    and di,0FFF8h
    add edi,alias_linear
    shr edi,9
    and di,0FFF8h
;
    movzx eax,cx
    and ax,7Fh
    shl ax,5
    add edi,eax
;    
    mov bx,process_page_sel
    mov ds,bx
    mov eax,[edi]
    test al,1
    stc
    jz set_thread_page_fail64
;
    mov ebx,[edi+4]
    mov si,process_dir_sel
    mov ds,si
    mov si,(alias_linear SHR 18) AND 3FFFh
    or ax,803h
    mov [si],eax
    mov [si+4],ebx
    mov ebx,cr3
    mov cr3,ebx
;
    mov edi,edx
    shr edi,9
    and edi,1FFFF8h
    add edi,alias_linear
    mov edx,edi
    shr edi,9
    and di,0FFF8h
    mov bx,process_page_sel
    mov ds,bx
    mov eax,[edi]
    mov ebx,[edi+4]
    test al,1
    jz set_thread_page_fail64
;
    mov ax,flat_sel
    mov ds,ax
;    
    pop ebx
    pop eax
    mov [edx],eax
    mov [edx+4],ebx
    jmp set_thread_page_done64

set_thread_page_fail64:
    pop ebx
    pop eax

set_thread_page_done64:
    mov dx,system_data_sel
    mov ds,dx
    ReleaseSpinlock ds:page_spinlock
;
    pop edi
    pop esi
    pop edx
    pop es
    pop ds
    ret
local_set_thread_page_entry64    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_get_thread_page_dir64
;
;           DESCRIPTION:    Get physical page directory for other thread
;
;           PARAMETERS:     BP          Thread
;                           CX:EDX      Linear address
;
;           RETURNS:        EBX:EAX     Physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_thread_page_dir64    Proc near
    push ds
    push es
    push edx
    push esi
    push edi
;
    and dx,0F000h
    mov es,bp
;
    mov ax,system_data_sel
    mov ds,ax
    RequestSpinlock ds:page_spinlock
;    
    mov ax,process_dir_sel
    mov ds,ax
    mov eax,es:p_cr3
    xor ebx,ebx    
;
    mov di,es:p_tss_sel
    or di,di
    jz gtdLong
;
    or cx,cx
    jz gtdBaseOk
;    
    stc
    jmp get_thread_dir_fail64

gtdLong:
    mov si,(alias_linear SHR 18) AND 3FFFh
    or ax,803h
    mov [si],eax
    mov [si+4],ebx
    mov ebx,cr3
    mov cr3,ebx
;
    mov edi,alias_linear SHR 9
    movzx eax,cx
    shr eax,4
    and ax,0FFF8h
    add edi,eax
;    
    mov bx,process_page_sel
    mov ds,bx
    mov eax,[edi]
    mov ebx,[edi+4]
    test al,1
    stc
    jz get_thread_dir_fail64
;
    mov di,process_dir_sel
    mov ds,di
    and ax,0F000h

gtdBaseOk:
    mov si,(alias_linear SHR 18) AND 3FFFh
    or ax,803h
    mov [si],eax
    mov [si+4],ebx
    mov ebx,cr3
    mov cr3,ebx
;
    mov edi,edx
    shr edi,18
    and di,0FFF8h
    add edi,alias_linear
    shr edi,9
    and di,0FFF8h
;
    movzx eax,cx
    and ax,7Fh
    shl ax,5
    add edi,eax
;    
    mov bx,process_page_sel
    mov ds,bx
    mov eax,[edi]
    test al,1
    stc
    jz get_thread_dir_fail64
;
    mov ebx,[edi+4]
    mov si,process_dir_sel
    mov ds,si
    mov si,(alias_linear SHR 18) AND 3FFFh
    or ax,803h
    mov [si],eax
    mov [si+4],ebx
    mov ebx,cr3
    mov cr3,ebx
;
    mov edi,edx
    shr edi,9
    and edi,1FFFF8h
    add edi,alias_linear
    shr edi,9
    and di,0FFF8h
    mov bx,process_page_sel
    mov ds,bx
    mov eax,[edi]
    mov ebx,[edi+4]
    test al,1
    jnz get_thread_dir_done64

get_thread_dir_fail64:
    xor eax,eax
    xor ebx,ebx

get_thread_dir_done64:
    mov dx,system_data_sel
    mov ds,dx
    ReleaseSpinlock ds:page_spinlock
;
    pop edi
    pop esi
    pop edx
    pop es
    pop ds
    ret
local_get_thread_page_dir64    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_create_fork64
;
;           DESCRIPTION:    Create fork page table, 64-bit version
;
;           PARAMETERS:     EAX         CR3
;                           DS          Process selector
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_fork64  Proc near
    push ds
    pushad
;
    push eax
    mov eax,3000h
    AllocateBigLinear
    pop eax
;
    xor ebx,ebx
    mov al,3
    SetPageEntry    
    mov ds:pf_page_table,edx
;
    mov esi,edx
    mov eax,4000h
    AllocateBigLinear
    mov ds:pf_page_dir,edx
;
    mov ecx,4
    mov eax,flat_sel
    mov ds,eax

lcfLoop:
    mov eax,ds:[esi]
    mov ebx,ds:[esi+4]
    mov al,3
    SetPageEntry
;
    add esi,8
    add edx,1000h
    loop lcfLoop
;
    popad
    pop ds
    ret
local_create_fork64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_delete_fork64
;
;           DESCRIPTION:    Create delete page table, 64-bit version
;
;           PARAMETERS:     DS          Process selector
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_delete_fork64  Proc near
    push ds
    pushad
;
    xor eax,eax
    xor ebx,ebx
    mov edx,ds:pf_page_table
    mov ecx,3

ldfTableLoop64:
    SetPageEntry
    add edx,1000h
    loop ldfTableLoop64
;
    mov edx,ds:pf_page_table
    mov ecx,3000h
    FreeLinear
;
    xor eax,eax
    xor ebx,ebx
    mov edx,ds:pf_page_dir
    mov ecx,4

ldelfDirLoop64:
    SetPageEntry
    add edx,1000h
    loop ldelfDirLoop64
;
    mov edx,ds:pf_page_dir
    mov ecx,4000h
    FreeLinear
;
    popad
    pop ds
    ret
local_delete_fork64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MergeDirEntry64
;
;           DESCRIPTION:    Merge dir entry
;
;           PARAMETERS:     DS         Source process sel
;                           ES         Destination process sel
;                           FS         Flat sel
;                           ESI        Source entry
;                           EDI        Destination entry
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MergeDirEntry64  Proc near
    pushad
;
    mov eax,fs:[esi]
    mov ebx,fs:[esi+4]
    mov edx,ds:pf_page_table
    SetPageEntry
    mov esi,edx
;
    mov eax,fs:[edi]
    mov ebx,fs:[edi+4]
    mov edx,es:pf_page_table
    SetPageEntry
    mov edi,edx
;
    mov ecx,200h

mdeLoop64:
    mov eax,fs:[edi]
    mov ebx,fs:[edi+4]
    test al,1
    jnz mdeSave64
;
    mov eax,fs:[esi]
    mov ebx,fs:[esi+4]
    test al,1
    jz mdeSave64
;
    test al,2
    jz mdeSave64
;
    and al,NOT 2
    or ax,400h
    mov fs:[esi],eax

mdeSave64:
    mov fs:[edi],eax
    mov fs:[edi+4],ebx
;
    add esi,8
    add edi,8
    loop mdeLoop64
;
    popad
    ret
MergeDirEntry64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_start_fork64
;
;           DESCRIPTION:    Fork page tables
;
;           PARAMETERS:     DS         Source process sel
;                           ES         Destination process sel
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_start_fork64  Proc near
    push fs
    pushad
;
    mov esi,ds:pf_page_dir
    mov edi,es:pf_page_dir
;
    mov eax,flat_sel
    mov fs,eax
;
    mov ecx,process_page_linear SHR 21

lsfuLoop64:
    mov eax,fs:[edi]
    mov ebx,fs:[edi+4]
    test al,1
    jz lsfuFree64
;
    call MergeDirEntry64
    jmp lsfuSave64

lsfuFree64:
    mov eax,fs:[esi]
    mov ebx,fs:[esi+4]
    test al,1
    jz lsfuSave64
;
    test al,2
    jz lsfuSave64
;
    and al,NOT 2
    or ax,400h
    mov fs:[esi],eax

lsfuSave64:
    mov fs:[edi],eax
    mov fs:[edi+4],ebx
;
    add esi,8
    add edi,8
    loop lsfuLoop64
;
    popad
    pop fs
    ret
local_start_fork64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDirRefCount64
;
;           DESCRIPTION:    Get page dir reference count
;
;           PARAMETERS:     DS             Program sel
;                           ES             Process sel
;                           FS             Flat sel
;                           ESI            Offset within dir selector
;                           EBP            Process index
;                           EBX:EAX        Entry data
;
;           RETURNS:        ECX            References
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDirRefCount64  Proc near
    push edx
    push edi
    push ebp
;
    and ax,0F000h
;
    movzx ecx,ds:pr_page_table_count
    xor ebp,ebp
    xor edi,edi

gdrLoop64:
    mov edx,ds:[edi].pr_page_dir_arr
    cmp ebx,fs:[edx+esi+4]
    jne gdrNext64
;
    mov edx,fs:[edx+esi]
    and dx,0F000h
    cmp eax,edx
    jne gdrNext64
;
    inc ebp

gdrNext64:
    add edi,4
    loop gdrLoop64
;
    mov ecx,ebp
;
    pop ebp
    pop edi
    pop edx
    ret
GetDirRefCount64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPageRefCount64
;
;           DESCRIPTION:    Get page reference count
;
;           PARAMETERS:     DS             Program sel
;                           ES             Process sel
;                           FS             Flat sel
;                           ESI            Offset within page selector
;                           EBX:EAX        Entry data
;
;           RETURNS:        ECX            References
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPageRefCount64  Proc near
    push edx
    push edi
    push ebp
;
    and ax,0F000h
;
    movzx ecx,ds:pr_page_table_count
    xor ebp,ebp
    xor edi,edi

gprLoop64:
    mov edx,ds:[edi].pr_temp_arr
    or edx,edx
    jz gprNext64
;
    cmp ebx,fs:[edx+esi+4]
    jne gprNext64
;
    mov edx,fs:[edx+esi]
    test dl,1
    jz gprNext64
;
    and dx,0F000h
    cmp eax,edx
    jne gprNext64
;
    inc ebp

gprNext64:
    add edi,4
    loop gprLoop64
;
    mov ecx,ebp
;
    pop ebp
    pop edi
    pop edx
    ret
GetPageRefCount64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupDetachTables64
;
;           DESCRIPTION:    Setup detach page tables
;
;           PARAMETERS:     DS             Program sel
;                           ES             Process sel
;                           FS             Flat sel
;                           ESI            Offset within dir selector
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDetachTables64  Proc near
    pushad
;
    movzx ecx,ds:pr_page_table_count
    xor edi,edi

sdtLoop64:
    xor ebp,ebp
;
    mov edx,ds:[edi].pr_page_dir_arr
    mov eax,fs:[edx+esi]
    mov ebx,fs:[edx+esi+4]
    test al,1
    jz sdtSave64
;
    and ax,0F000h
    or al,67h
    mov edx,ds:[edi].pr_page_table_arr
    SetPageEntry
    mov ebp,edx

sdtSave64:
    mov ds:[edi].pr_temp_arr,ebp
    add edi,4
    loop sdtLoop64
;
    popad
    ret
SetupDetachTables64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DoDetachTables64
;
;           DESCRIPTION:    Detach page tables
;
;           PARAMETERS:     DS             Program sel
;                           ES             Process sel
;                           FS             Flat sel
;                           EBP            Process index
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoDetachTables64  Proc near
    pushad
;
    mov ecx,512
    xor esi,esi
    mov edi,ds:[ebp].pr_page_table_arr

ddtLoop64:
    mov eax,fs:[esi+edi]
    mov ebx,fs:[esi+edi+4]
    test al,1
    jz ddtNext64
;
    push ecx
    call GetPageRefCount64
    cmp ecx,1
    je ddtFree64
;
    ja ddtOk64
;
    int 3

ddtFree64:
    FreePhysical

ddtOk64:
    pop ecx

ddtNext64:
    add esi,8
    loop ddtLoop64
;
    popad
    ret
DoDetachTables64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DetachDirEntry64
;
;           DESCRIPTION:    Detach single dir entry
;
;           PARAMETERS:     DS             Program sel
;                           ES             Process sel
;                           FS             Flat sel
;                           ESI            Offset within dir selector
;                           EBP            Process index
;                           EBX:EAX        Entry data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DetachDirEntry64  Proc near
    push ecx
    call GetDirRefCount64
    cmp ecx,1
    je ddeFree64
;
    ja ddeDone64
;
    int 3

ddeFree64:
    call SetupDetachTables64
    call DoDetachTables64
    FreePhysical

ddeDone64:
    pop ecx
    ret
DetachDirEntry64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_detach_fork64
;
;           DESCRIPTION:    Detach current process from fork
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_detach_fork64  Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ax,flat_sel
    mov fs,eax
;
    GetThread
    mov gs,ax
    mov ds,gs:p_prog_sel
    mov es,gs:p_proc_sel
    mov edi,es:pf_page_dir
;
    xor ebp,ebp
    movzx ecx,ds:pr_page_table_count
    xor esi,esi

ldfProcLoop64:
    cmp edi,ds:[esi].pr_page_dir_arr
    jne ldfProcNext64
;
    mov ebp,esi
    jmp ldfProcDone64

ldfProcNext64:
    add esi,4
    loop ldfProcLoop64
;
    int 3

ldfProcDone64:
    mov ecx,process_page_linear SHR 21
    xor esi,esi

ldfDirLoop64:
    mov eax,fs:[esi+edi]
    mov ebx,fs:[esi+edi+4]
    test al,1
    jz ldfDirNext64
;
    call DetachDirEntry64

ldfDirNext64:
    xor eax,eax
    mov fs:[esi+edi],eax
    mov fs:[esi+edi+4],eax
;
    add esi,8
    loop ldfDirLoop64
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
local_detach_fork64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_cleanup_fork64
;
;           DESCRIPTION:    Cleanup fork page tables
;
;           PARAMETERS:     BX      Program ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_cleanup_fork64  Proc near
    push ds
    pushad
;
    movzx ebx,bx
    GetProgramSel
    jc cfDone64
;
    mov ds,eax
    mov esi,ds:pr_page_dir_arr
    mov eax,flat_sel
    mov ds,eax
    mov ecx,process_page_linear SHR 21

cfLoop64:
    mov eax,ds:[esi]
    test al,1
    jz cfNext64
;
    test ax,400h
    jz cfNext64
;
    and ax,NOT 400h
    or al,2
    mov ds:[esi],eax

cfNext64:
    add esi,8
    loop cfLoop64

cfDone64:
    popad
    pop ds
    ret
local_cleanup_fork64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_cow_dir64
;
;           DESCRIPTION:    Copy-on-write for directory
;
;           PARAMETERS:     EDX         Linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_cow_dir64  Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,eax
;
    shr edx,18
    and dl,0F8h
;
    GetThread
    mov es,ax
    mov ds,es:p_proc_sel
    mov eax,ds:pf_page_dir
    mov esi,fs:[eax+edx]
    mov edi,fs:[eax+edx+4]
    and si,0F000h
;
    mov ds,es:p_prog_sel
    movzx ecx,ds:pr_page_table_count
    mov ebx,OFFSET pr_page_dir_arr
    xor ebp,ebp

lcowdFind64:
    mov eax,ds:[ebx]
    cmp edi,fs:[eax+edx+4]
    jnz lcowdNext64
;
    mov eax,fs:[eax+edx]
    test al,1
    jz lcowdNext64
;
    and ax,0F000h
    cmp eax,esi
    jnz lcowdNext64
;
    inc ebp

lcowdNext64:
    add ebx,4
    loop lcowdFind64
;
    cmp ebp,1
    je lcowdUnmark64
;
    ja lcowdCopy64
;
    int 3

lcowdCopy64:
    push edx
;
    mov ds,es:p_proc_sel
    mov edx,ds:pf_page_table
    mov eax,esi
    mov ebx,edi
    or al,67h
    SetPageEntry
    mov esi,edx
;
    add edx,1000h
    AllocatePhysical64
    or al,67h
    SetPageEntry
    mov edi,edx
;
    push ebx
    push eax
    mov ecx,512

lcowdLoop64:
    mov eax,fs:[esi]
    mov ebx,fs:[esi+4]
    test al,1
    jz lcowdSave64
;
    test al,2
    jz lcowdSave64
;
    and al,NOT 2
    or ax,400h
    mov fs:[esi],eax

lcowdSave64:
    mov fs:[edi],eax
    mov fs:[edi+4],ebx
;
    add esi,8
    add edi,8
    loop lcowdLoop64
;
    pop eax
    pop ebx
    pop edx
;
    mov esi,ds:pf_page_dir
    mov fs:[esi+edx],eax
    mov fs:[esi+edx+4],ebx
    jmp lcowdDone64

lcowdUnmark64:
    mov ds,es:p_proc_sel
    mov esi,ds:pf_page_dir
    mov eax,fs:[esi+edx]
    and ax,NOT 400h
    or al,2
    mov fs:[esi+edx],eax

lcowdDone64:    
    popad
    pop fs
    pop es
    pop ds
    ret
local_cow_dir64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_cow_page64
;
;           DESCRIPTION:    Copy-on-write page table
;
;           PARAMETERS:     EDX         Linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_cow_page64  Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,eax
    GetThread
    mov es,ax
    mov ds,es:p_proc_sel
    mov ebp,ds:pf_page_dir
;
    mov ds,es:p_prog_sel
    movzx ecx,ds:pr_page_table_count
    xor esi,esi
    mov ds:pr_temp_ind,si

lcowpInitLoop64:
    mov ds:[esi].pr_temp_arr,0
    mov edi,ds:[esi].pr_page_dir_arr
    cmp edi,ebp
    jne lcowpNotMine64
;
    mov ds:pr_temp_ind,si

lcowpNotMine64:
    mov eax,edx
    shr eax,18
    and al,0F8h
    mov ebx,fs:[edi+eax+4]
    mov eax,fs:[edi+eax]
    test al,1
    jz lcowpInitNext64
;
    push edx
    mov edi,edx
    shr edi,9
    and edi,0FF8h
    mov edx,ds:[esi].pr_page_table_arr
    and ax,0F000h
    mov al,3
    SetPageEntry
    add edi,edx
    pop edx
;
    mov ds:[esi].pr_temp_arr,edi

lcowpInitNext64:
    add esi,4
    loop lcowpInitLoop64
;
    movzx esi,ds:pr_temp_ind
    mov esi,ds:[esi].pr_temp_arr
    mov edi,fs:[esi+4]
    mov esi,fs:[esi]
    and si,0F000h
    xor ebx,ebx
    xor ebp,ebp
    movzx ecx,ds:pr_page_table_count

lcowpFindLoop64:
    mov edx,ds:[ebx].pr_temp_arr
    or edx,edx
    jz lcowpFindNext64
;
    mov eax,fs:[edx]
    test al,1
    jz lcowpFindNext64
;
    and ax,0F000h
    cmp eax,esi
    jne lcowpFindNext64
;
    mov eax,fs:[edx+4]
    cmp eax,edi
    jne lcowpFindNext64
;
    inc ebp

lcowpFindNext64:
    add ebx,4
    loop lcowpFindLoop64
;
    cmp ebp,1
    je lcowpUnmark64
;
    ja lcowpCopy64
;
    int 3

lcowpCopy64:
    movzx eax,ds:pr_temp_ind
    mov ebp,ds:[eax].pr_temp_arr
    mov eax,fs:[ebp]
    mov ebx,fs:[ebp+4]
    and ax,0F000h
    or al,67h
;
    mov ds,es:p_proc_sel
    mov edx,ds:pf_page_table
    add edx,1000h
    SetPageEntry
    mov esi,edx
;
    add edx,1000h
    AllocatePhysical64
    or al,67h
    SetPageEntry
    mov edi,edx
;
    push es
    mov ecx,flat_sel
    mov es,ecx
    mov ecx,1024
    rep movs dword ptr es:[edi],es:[esi]
    pop es
;
    mov fs:[ebp],eax
    mov fs:[ebp+4],ebx
    jmp lcowpDone64

lcowpUnmark64:
    movzx edx,ds:pr_temp_ind
    mov edx,ds:[edx].pr_temp_arr
    mov eax,fs:[edx]
    and ax,NOT 400h
    or al,2
    mov fs:[edx],eax

lcowpDone64:
    popad
    pop fs
    pop es
    pop ds
    ret
local_cow_page64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           local_uses_pae64
;
;           DESCRIPTION:    Check for PAE paging, 64-bit version
;
;           RETURNS:        NC      Uses PAE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_uses_pae64  Proc near
    clc
    ret
local_uses_pae64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyInitProcess
;
;           DESCRIPTION:    Notify init process
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_init_process_name  DB 'Notify Init Process',0

notify_init_process       Proc far
    call cs:init_process_proc
    retf32
notify_init_process       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyCreateProcess
;
;           DESCRIPTION:    Notify create process
;
;           PARAMETERS:     ES          Thread
;                           EAX         CR3
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_create_process_name  DB 'Notify Create Process',0

notify_create_process       Proc far
    call cs:create_process_proc
    retf32
notify_create_process       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateServDir
;
;           DESCRIPTION:    Create serv dir
;
;           PARAMETERS:     BX     Serv sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_serv_dir_name  DB 'Create Server Dir',0

create_serv_dir       Proc far
    call cs:create_serv_proc
    retf32
create_serv_dir       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateFork
;
;           DESCRIPTION:    Create fork page tables
;
;           PARAMETERS:     EAX         CR3
;                           DS          Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_fork_name  DB 'Create Fork',0

create_fork       Proc far
    call cs:create_fork_proc
    retf32
create_fork       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteFork
;
;           DESCRIPTION:    Delete fork page tables
;
;           PARAMETERS:     DS          Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_fork_name  DB 'Delete Fork',0

delete_fork       Proc far
    call cs:delete_fork_proc
    retf32
delete_fork       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartFork
;
;           DESCRIPTION:    Start fork page tables
;
;           PARAMETERS:     DS          Source process sel
;                           ES          Destination process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_fork_name  DB 'Start Fork',0

start_fork       Proc far
    call cs:start_fork_proc
    retf32
start_fork       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DetachFork
;
;           DESCRIPTION:    Detach current process from fork
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

detach_fork_name  DB 'Detach Fork',0

detach_fork       Proc far
    call cs:detach_fork_proc
    retf32
detach_fork       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CleanupFork
;
;           DESCRIPTION:    Cleanup fork page tables
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cleanup_fork_name  DB 'Cleanup Fork',0

cleanup_fork       Proc far
    call cs:cleanup_fork_proc
    retf32
cleanup_fork       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyCreateLongProcess
;
;           DESCRIPTION:    Notify create long process
;
;           PARAMETERS:     ES          Thread
;                           EAX         CR3
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_create_long_process_name  DB 'Notify Create Long Process',0

notify_create_long_process       Proc far
    call cs:create_long_process_proc
    retf32
notify_create_long_process       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyDeleteProcess
;
;           DESCRIPTION:    Notify delete process
;
;           PARAMETERS:     EAX         CR3
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_delete_process_name  DB 'Notify Delete Process',0

notify_delete_process       Proc far
    call cs:delete_process_proc
    retf32
notify_delete_process       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetProcess
;
;           DESCRIPTION:    Free user page of process
;
;           PARAMETERS:     EAX         CR3
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_process_name  DB 'Reset Process',0

reset_process       Proc far
    call cs:free_process_proc
    retf32
reset_process       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPageEntry
;
;           DESCRIPTION:    Get physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        EBX:EAX         physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_page_entry_name  DB 'Get Page Entry',0

get_page_entry       Proc far
    call cs:get_page_entry_proc
    retf32
get_page_entry       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetPageEntry
;
;           DESCRIPTION:    Set physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_page_entry_name  DB 'Set Page Entry',0

set_page_entry       Proc far
    call cs:set_page_entry_proc
    retf32
set_page_entry       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapServEntry
;
;           DESCRIPTION:    Map physical page to server flat sel
;
;           PARAMETERS:     EDX         offset in serv_flat_sel
;                           EBX:EAX     physical address                       
;
;           RETURN:         EDX         Updated offset to match physical address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_serv_entry_name  DB 'Map Serv Entry',0

map_serv_entry       Proc far
    push ax
    push cx
;
    mov cx,ax
    and ax,0F000h
    or ax,803h
    and dx,0F000h
;
    push edx
    add edx,serv_linear
    call cs:set_page_entry_proc
    pop edx
;
    and cx,0FFFh
    or dx,cx
;
    pop cx
    pop ax
    retf32
map_serv_entry       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeServPageEntries
;
;           DESCRIPTION:    Free server entries
;
;           PARAMETERS:     EAX         free signature
;                           ECX         number of entries
;                           EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_serv_page_entries_name  DB 'Free Serv Page Entries',0

free_serv_page_entries       Proc far
    call cs:free_page_entries_proc
    retf32
free_serv_page_entries       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSysPageEntry
;
;           DESCRIPTION:    Get physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        EBX:EAX         physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_sys_page_entry_name  DB 'Get Sys Page Entry',0

get_sys_page_entry       Proc far
    call cs:get_sys_page_entry_proc
    retf32
get_sys_page_entry       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetSysPageEntry
;
;           DESCRIPTION:    Set physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_sys_page_entry_name  DB 'Set Sys Page Entry',0

set_sys_page_entry       Proc far
    call cs:set_sys_page_entry_proc
    retf32
set_sys_page_entry       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HasPageEntry
;
;           DESCRIPTION:    Check physical page for linear address
;
;           PARAMETERS:     EDX         linear address
;
;           RETURNS:        NC          valid
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_page_entry_name  DB 'Has Page Entry',0

has_page_entry       Proc far
    call cs:has_page_entry_proc
    retf32
has_page_entry       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPageDirAttrib
;
;           DESCRIPTION:    Get page dir attributes
;
;           RETURNS:        ESI         linear address space size per entry
;                           CX          # of entries per 32-bit page dir entries
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_page_dir_attrib_name  DB 'Get Page Dir Attrib',0

get_page_dir_attrib       Proc far
    call cs:get_page_dir_attrib_proc
    retf32
get_page_dir_attrib       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPageDir
;
;           DESCRIPTION:    Get physical page dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           
;           RETURNS:        EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_page_dir_name  DB 'Get Page Dir',0

get_page_dir       Proc far
    call cs:get_page_dir_proc
    retf32
get_page_dir       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetPageDir
;
;           DESCRIPTION:    Set physical page dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_page_dir_name  DB 'Set Page Dir',0

set_page_dir       Proc far
    call cs:set_page_dir_proc
    retf32
set_page_dir       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSysPageDir
;
;           DESCRIPTION:    Get sys physical page dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           
;           RETURNS:        EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_sys_page_dir_name  DB 'Get Sys Page Dir',0

get_sys_page_dir       Proc far
    call cs:get_sys_page_dir_proc
    retf32
get_sys_page_dir       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetSysPageDir
;
;           DESCRIPTION:    Set physical page dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           EBX:EAX     physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_sys_page_dir_name  DB 'Set Sys Page Dir',0

set_sys_page_dir       Proc far
    call cs:set_sys_page_dir_proc
    retf32
set_sys_page_dir       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSysPageDir
;
;           DESCRIPTION:    Create sys physical page dir for linear address
;
;           PARAMETERS:     EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_sys_page_dir_name  DB 'Create Sys Page Dir',0

create_sys_page_dir       Proc far
    call cs:create_sys_page_dir_proc
    retf32
create_sys_page_dir       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReservePageEntries
;
;           DESCRIPTION:    Reserve page entries 
;
;           PARAMETERS:     ECX         number of entries
;                           EDX         start linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reserve_page_entries_name  DB 'Reserve Page Entries',0

reserve_page_entries       Proc far
    call cs:reserve_page_entries_proc
    retf32
reserve_page_entries       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocatePageEntries
;
;           DESCRIPTION:    Allocate page entries 
;
;           PARAMETERS:     EAX         allocate limit
;                           ECX         number of entries
;                           EDX         start linear address
;
;           RETURNS:        EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_page_entries_name  DB 'Allocate Page Entries',0

allocate_page_entries       Proc far
    push ds
    call cs:allocate_page_entries_proc
    pop ds
    retf32
allocate_page_entries       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreePageEntries
;
;           DESCRIPTION:    Free page entries 
;
;           PARAMETERS:     EAX         free signature
;                           ECX         number of entries
;                           EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_page_entries_name  DB 'Free Page Entries',0

free_page_entries       Proc far
    call cs:free_page_entries_proc
    retf32
free_page_entries       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClearPageEntries
;
;           DESCRIPTION:    Clear page entries 
;
;           PARAMETERS:     EAX         free signature
;                           ECX         number of entries
;                           EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_page_entries_name  DB 'Clear Page Entries',0

clear_page_entries       Proc far
    call cs:clear_page_entries_proc
    retf32
clear_page_entries       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CopyPageEntries
;
;           DESCRIPTION:    Copy page entries 
;
;           PARAMETERS:     ECX         number of entries
;                           ESI         source linear address
;                           EDI         dest linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy_page_entries_name  DB 'Copy Page Entries',0

copy_page_entries       Proc far
    call cs:copy_page_entries_proc
    retf32
copy_page_entries       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CopySysPageEntries
;
;           DESCRIPTION:    Copy sys page entries 
;
;           PARAMETERS:     ECX         number of entries
;                           ESI         source linear address
;                           EDI         dest linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy_sys_page_entries_name  DB 'Copy Sys Page Entries',0

copy_sys_page_entries       Proc far
    call cs:copy_sys_page_entries_proc
    retf32
copy_sys_page_entries       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MovePageEntries
;
;           DESCRIPTION:    Move page entries
;
;           PARAMETERS:     ECX         number of entries
;                           ESI         source linear address
;                           EDI         dest linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

move_page_entries_name  DB 'Move Page Entries',0

move_page_entries       Proc far
    call cs:move_page_entries_proc
    retf32
move_page_entries       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           EmulatePage
;
;           DESCRIPTION:    Hook for a specified linear address range
;
;           PARAMETERS:     EAX         Size
;                           EDX         Linear base
;                           ES:DI       Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_page_emulate_name  DB 'Emulate Page',0

set_page_emulate       Proc far
    call cs:emulate_page_proc
    retf32
set_page_emulate       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HookPage
;
;           DESCRIPTION:    Hook for a specified linear address range
;
;           PARAMETERS:     EAX         Size
;                           EDX         Linear base
;                           ES          Loader selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_page_name  DB 'Hook Page',0

hook_page       Proc far
    call cs:hook_page_proc
    retf32
hook_page       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UnhookPage
;
;           DESCRIPTION:    Unhook for a specified linear address range
;
;           PARAMETERS:     EAX         Size
;                           EDX         Linear base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unhook_page_name  DB 'Unhook Page',0

unhook_page       Proc far
    call cs:unhook_page_proc
    retf32
unhook_page       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetThreadPageEntry
;
;           DESCRIPTION:    Get physical page for linear address in other thread.
;
;           PARAMETERS:     BP          Thread
;                           EDX         Linear address
;
;           RETURNS:        EBX:EAX     Physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_page_entry_name   DB 'Get Thread Page Entry',0

get_thread_page_entry    Proc far
    call cs:get_thread_page_entry_proc
    retf32
get_thread_page_entry    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetThreadPageEntry
;
;           DESCRIPTION:    Set physical page for linear address in other thread.
;
;           PARAMETERS:     BP          Thread
;                           EDX         Linear address
;                           EBX:EAX     Physical address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_thread_page_entry_name   DB 'Set Thread Page Entry',0

set_thread_page_entry    Proc far
    call cs:set_thread_page_entry_proc
    retf32
set_thread_page_entry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetThreadPageDir
;
;           DESCRIPTION:    Get physical page dir for linear address in other thread.
;
;           PARAMETERS:     BP          Thread
;                           EDX         Linear address
;
;           RETURNS:        EBX:EAX     Physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_page_dir_name   DB 'Get Thread Page Dir',0

get_thread_page_dir    Proc far
    call cs:get_thread_page_dir_proc
    retf32
get_thread_page_dir    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Has64
;
;           DESCRIPTION:    Check for 64-bit address
;
;           RETURNS:        NC      Has 64-bit addresses
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_physical64_name   DB 'Has Physical64',0

has_physical64    Proc far
    push ds
    push ax
;
    mov ax,system_data_sel
    mov ds,ax
    mov al,ds:has_phys64
    or al,al
    stc
    jz hp64Done
;
    clc    

hp64Done:
    pop ax
    pop ds
    retf32
has_physical64    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UsesPae
;
;           DESCRIPTION:    Check for PAE paging
;
;           RETURNS:        NC      Uses PAE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uses_pae_name   DB 'Uses Pae',0

uses_pae    Proc far
    call cs:uses_pae_proc
    retf32
uses_pae    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_flat_dir32
;
;           DESCRIPTION:    Setup flat (identity) mapped page-tables, 32 bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_flat_dir32   Proc near
    push ds
    push eax
    push bx
    push cx
    push edx
;
    mov bx,sys_dir_sel
    mov ecx,1000h
    mov edx,cr3
    and dx,0F000h
    call local_create_data_sel16
;
    mov ds,bx
    xor eax,eax
    mov cx,400h
    xor bx,bx

init_empty_dir32:
    mov [bx],eax
    add bx,4
    loop init_empty_dir32
;
    pop edx
    pop cx
    pop bx
    pop eax
    pop ds
    ret
init_flat_dir32  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           map_dir32
;
;           DESCRIPTION:    Map dir selectors, 32-bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_dir32 Proc near
    mov ax,sys_dir_sel
    mov ds,ax
    mov eax,cr3
    mov bx,(sys_page_linear SHR 20) AND 0FFFh
    mov al,3
    mov [bx],eax
    mov bx,(process_page_linear SHR 20) AND 0FFFh
    mov [bx],eax
    ret
map_dir32 Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           map_flat32
;
;           DESCRIPTION:    Map a page flat
;
;           PARAMETERS:         EDX             Linear base address
;                           ECX             Number of bytes to map
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_flat32    Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz map_flat_done32

map_flat_more32:
    mov bx,sys_dir_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,22
    shl bx,2
    mov edi,[bx]
    or edi,edi
    jnz map_flat_do32
;
    call AllocateRam
    mov edi,esi
    or si,3
    mov [bx],esi
;
    mov ax,flat_sel
    mov ds,ax
    push cx
    mov cx,400h
    xor eax,eax

map_flat_init_loop32:
    mov [edi],eax
    add edi,4
    loop map_flat_init_loop32
;
    sub edi,1000h
    pop cx

map_flat_do32:
    mov ax,flat_sel
    mov ds,ax
    mov ebx,edx
    shr ebx,12
    and ebx,3FFh
    mov eax,400h
    shr ecx,12
    sub eax,ebx
    sub ecx,eax
    jnc map_flat_start32
;
    add ecx,eax
    mov eax,ecx
    xor ecx,ecx

map_flat_start32:
    shl bx,2
    shl ecx,12
    push ecx
    mov cx,ax
    and dx,0F000h
    or dx,803h
    and di,0F000h
    or di,bx

map_flat_loop32:
    mov [edi],edx
    add edi,4
    add edx,1000h
    loop map_flat_loop32
    pop ecx
    or ecx,ecx
    jnz map_flat_more32

map_flat_done32:
    popad
    pop ds
    ret
map_flat32    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           map_flat_user32
;
;           DESCRIPTION:    Map a page flat, user access, 32-bit version
;
;           PARAMETERS:         EDX             Linear base address
;                           ECX             Number of bytes to map
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_flat_user32   Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz map_flat_user_done32

map_flat_user_more32:
    mov bx,sys_dir_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,22
    shl bx,2
    mov edi,[bx]
    or edi,edi
    jnz map_flat_user_do32
;
    call AllocateRam
    mov edi,esi
    or si,7
    mov [bx],esi
;
    mov ax,flat_sel
    mov ds,ax
    push cx
    mov cx,400h
    xor eax,eax

map_flat_user_init_loop32:
    mov [edi],eax
    add edi,4
    loop map_flat_user_init_loop32
;    
    sub edi,1000h
    pop cx

map_flat_user_do32:
    mov ax,flat_sel
    mov ds,ax
    mov ebx,edx
    shr ebx,12
    and ebx,3FFh
    mov eax,400h
    shr ecx,12
    sub eax,ebx
    sub ecx,eax
    jnc map_flat_user_start32
;
    add ecx,eax
    mov eax,ecx
    xor ecx,ecx

map_flat_user_start32:
    shl bx,2
    shl ecx,12
    push ecx
    mov cx,ax
    and dx,0F000h
    or dx,807h
    and di,0F000h
    or di,bx

map_flat_user_loop32:
    mov [edi],edx
    add edi,4
    add edx,1000h
    loop map_flat_user_loop32
;    
    pop ecx
    or ecx,ecx
    jnz map_flat_user_more32

map_flat_user_done32:
    popad
    pop ds
    ret
map_flat_user32   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           map_user32
;
;           DESCRIPTION:    Map a page, user access, 32-bit version
;
;           PARAMETERS:     EDX             Linear base address
;                           ECX             Number of bytes to map
;                           EAX             Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_user32   Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz map_user_done32
;
    mov ebp,eax
    sub ebp,edx

map_user_more32:
    mov bx,sys_dir_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,22
    shl bx,2
    mov edi,[bx]
    or edi,edi
    jnz map_user_do32
;
    call AllocateRam
    mov edi,esi
    or si,7
    mov [bx],esi
;
    mov ax,flat_sel
    mov ds,ax
    push cx
    mov cx,400h
    xor eax,eax

map_user_init_loop32:
    mov [edi],eax
    add edi,4
    loop map_user_init_loop32
;    
    sub edi,1000h
    pop cx

map_user_do32:
    mov ax,flat_sel
    mov ds,ax
    mov ebx,edx
    shr ebx,12
    and ebx,3FFh
    mov eax,400h
    shr ecx,12
    sub eax,ebx
    sub ecx,eax
    jnc map_user_start32
;
    add ecx,eax
    mov eax,ecx
    xor ecx,ecx

map_user_start32:
    shl bx,2
    shl ecx,12
    push ecx
    mov cx,ax
    and dx,0F000h
    or dx,807h
    and di,0F000h
    or di,bx

map_user_loop32:
    mov eax,edx
    add eax,ebp
    mov [edi],eax
    add edi,4
    add edx,1000h
    loop map_user_loop32
;    
    pop ecx
    or ecx,ecx
    jnz map_user_more32

map_user_done32:
    popad
    pop ds
    ret
map_user32   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           create_paging32
;
;           DESCRIPTION:    Create initial paging for system process, 32-bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_paging32     PROC near
    mov ax,system_data_sel
    mov es,ax
;
    call init_flat_dir32
    call map_dir32
;
    xor edx,edx
    mov ecx,es:alloc_base
    add ecx,1000h
    call map_flat32
;
    mov edx,es:rom1_base
    mov ecx,es:rom1_size
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    call map_flat32
;
    mov edx,es:rom2_base
    mov ecx,es:rom2_size
    or ecx,ecx
    jz create_paging_ram32
;
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    call map_flat32

create_paging_ram32:
    mov edx,es:efi_acpi
    or edx,es:efi_acpi+4
    jnz create_paging_efi32
;    
    mov edx,0A0000h
    mov ecx,100000h
    sub ecx,edx
    call map_flat_user32
    jmp create_paging_done32
    
create_paging_efi32:
    mov edx,es:efi_scan_size
    movzx eax,es:efi_height
    mul edx
    shl eax,2
    mov ecx,eax
    mov eax,es:efi_lfb
    mov edx,boot_efi_linear
    call map_user32
    
create_paging_done32:
    ret
create_paging32     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_phys_bitmap32
;
;           DESCRIPTION:    init physical bitmaps, 32-bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_phys_bitmap32       Proc near
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;    
    call AllocateRam
    mov edi,esi
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]    
;        
    mov eax,esi
    mov edi,esi
    xor ebx,ebx
    or al,3
    mov edx,phys_bitmap_linear
    call local_set_sys_page_dir32
;
    call AllocateRam
    mov eax,esi
    or al,3
    mov ds:[edi],eax
;
    mov ds:[esi].phys_curr_header32,1
    mov ds:[esi].phys_curr_header64,0
    mov ds:[esi].phys_bitmap_count,1
;
    mov ebx,esi
    add ebx,phys_header_start
    mov ds:[ebx].phys_bitmap_free,0
    mov ds:[ebx].phys_bitmap_pos,0
;
    call AllocateRam
    mov eax,esi
    or al,3
    add edi,phys_bitmap_start SHR 10
    mov ds:[edi],eax
;
    mov edi,esi
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov edi,esi
;
    mov ax,system_data_sel
    mov ds,ax

init_phys_alloc_loop32:
    mov esi,ds:alloc_base
    cmp esi,ds:ram1_size
    jae init_phys_alloc_done32
;    
    cmp esi,40000h
    jae init_phys_alloc_done32
;
    call AllocateRam
    mov ecx,esi
    shr ecx,12
    bts es:[edi],ecx
    inc es:[ebx].phys_bitmap_free
    jmp init_phys_alloc_loop32

init_phys_alloc_done32:
    ret
init_phys_bitmap32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           start_paging32
;
;           DESCRIPTION:    Start paging hardware, 32-bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_paging32    Proc near
    call create_paging32
    call init_phys_bitmap32
;
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
;
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:cpu_feature_flags
    test ax,2000h
    jz start_paging_global_done32
;    
;    db 0Fh
;    db 20h
;    db 0E0h     ; mov eax,cr4
;
;    or ax,80h   ; enable global pages
;
;    db 0Fh
;    db 22h
;    db 0E0h     ; mov cr4,eax

start_paging_global_done32:
    mov bx,sys_dir_sel
    mov ecx,1000h
    mov edx,sys_page_linear
    shr edx,10
    add edx,sys_page_linear
    call local_create_data_sel16
;
    mov bx,sys_page_sel
    mov edx,sys_page_linear
    mov ecx,400000h
    call local_create_data_sel16
;
    mov bx,process_dir_sel
    mov ecx,1000h
    mov edx,process_page_linear
    shr edx,10
    add edx,process_page_linear
    call local_create_data_sel16
;
    mov bx,process_page_sel
    mov edx,process_page_linear
    mov ecx,400000h
    call local_create_data_sel16
;
    mov bx,phys_bit_sel
    mov ecx,800000h
    mov edx,phys_bitmap_linear
    call local_create_data_sel16
    ret
start_paging32    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_flat_dir64
;
;           DESCRIPTION:    Setup flat (identity) mapped page-tables, 64 bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_flat_dir64   Proc near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    mov ecx,4
    call AllocateMultipleRam
;
    mov edx,esi
    mov bx,sys_dir_sel
    mov ecx,4000h
    call local_create_data_sel16
;
    mov ax,flat_sel
    mov ds,ax
    mov ebx,cr3
    and bx,0F000h
;
    mov cx,4
    mov eax,edx
    or al,1

init_flat_loop64:
    mov [ebx],eax
    mov dword ptr [ebx+4],0
    add ebx,8
    add eax,1000h
    loop init_flat_loop64
;
    mov ax,sys_dir_sel
    mov ds,ax
    xor eax,eax
    mov cx,1000h
    xor bx,bx

init_empty_dir64:
    mov [bx],eax
    add bx,4
    loop init_empty_dir64
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
init_flat_dir64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           map_dir64
;
;           DESCRIPTION:    Map dir selectors, 64-bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_dir64 Proc near
    mov ax,flat_sel
    mov ds,ax
    mov ax,sys_dir_sel   
    mov es,ax
;    
    mov ebx,cr3
    mov di,(sys_page_linear SHR 18) AND 3FFFh
    mov cx,4

map_sys_dir_loop64:    
    mov eax,[ebx]
    mov al,3
    mov es:[di],eax
    mov dword ptr es:[di+4],0
    add ebx,8
    add di,8
    loop map_sys_dir_loop64
;    
    mov ebx,cr3
    mov di,(process_page_linear SHR 18) AND 3FFFh
    mov cx,4

map_proc_dir_loop64:    
    mov eax,[ebx]
    mov al,3
    mov es:[di],eax
    mov dword ptr es:[di+4],0
    add bx,8
    add di,8
    loop map_proc_dir_loop64
;
    ret
map_dir64 Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           map_flat64
;
;           DESCRIPTION:    Map a page flat
;
;           PARAMETERS:     EDX             Linear base address
;                           ECX             Number of bytes to map
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_flat64    Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz map_flat_done64

map_flat_more64:
    mov bx,sys_dir_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,21
    shl bx,3
    mov edi,[bx]
    or edi,edi
    jnz map_flat_do64
;
    call AllocateRam
    mov edi,esi
    or si,3
    mov [bx],esi
;
    mov ax,flat_sel
    mov ds,ax
    push cx
    mov cx,400h
    xor eax,eax

map_flat_init_loop64:
    mov [edi],eax
    add edi,4
    loop map_flat_init_loop64
;
    sub edi,1000h
    pop cx

map_flat_do64:
    mov ax,flat_sel
    mov ds,ax
    mov ebx,edx
    shr ebx,12
    and ebx,1FFh
    mov eax,200h
    shr ecx,12
    sub eax,ebx
    sub ecx,eax
    jnc map_flat_start64
;
    add ecx,eax
    mov eax,ecx
    xor ecx,ecx

map_flat_start64:
    shl bx,3
    shl ecx,12
    push ecx
    mov cx,ax
    and dx,0F000h
    or dx,803h
    and di,0F000h
    or di,bx

map_flat_loop64:
    mov [edi],edx
    mov dword ptr [edi+4],0
    add edi,8
    add edx,1000h
    loop map_flat_loop64
    pop ecx
    or ecx,ecx
    jnz map_flat_more64

map_flat_done64:
    popad
    pop ds
    ret
map_flat64    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           map_flat_user64
;
;           DESCRIPTION:    Map a page flat in user-space
;
;           PARAMETERS:     EDX             Linear base address
;                           ECX             Number of bytes to map
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_flat_user64    Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz map_flat_user_done64

map_flat_user_more64:
    mov bx,sys_dir_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,21
    shl bx,3
    mov edi,[bx]
    or edi,edi
    jnz map_flat_user_do64
;
    call AllocateRam
    mov edi,esi
    or si,7
    mov [bx],esi
;
    mov ax,flat_sel
    mov ds,ax
    push cx
    mov cx,400h
    xor eax,eax

map_flat_user_init_loop64:
    mov [edi],eax
    add edi,4
    loop map_flat_user_init_loop64
;
    sub edi,1000h
    pop cx

map_flat_user_do64:
    mov ax,flat_sel
    mov ds,ax
    mov ebx,edx
    shr ebx,12
    and ebx,1FFh
    mov eax,200h
    shr ecx,12
    sub eax,ebx
    sub ecx,eax
    jnc map_flat_user_start64
;
    add ecx,eax
    mov eax,ecx
    xor ecx,ecx

map_flat_user_start64:
    shl bx,3
    shl ecx,12
    push ecx
    mov cx,ax
    and dx,0F000h
    or dx,807h
    and di,0F000h
    or di,bx

map_flat_user_loop64:
    mov [edi],edx
    mov dword ptr [edi+4],0
    add edi,8
    add edx,1000h
    loop map_flat_user_loop64
    pop ecx
    or ecx,ecx
    jnz map_flat_user_more64

map_flat_user_done64:
    popad
    pop ds
    ret
map_flat_user64    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           map_user64
;
;           DESCRIPTION:    Map a page in user-space
;
;           PARAMETERS:     EDX             Linear base address
;                           ECX             Number of bytes to map
;                           EAX             Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_user64    Proc near
    push ds
    pushad
;
    or ecx,ecx
    jz map_user_done64
;    
    mov ebp,eax
    sub ebp,edx

map_user_more64:
    mov bx,sys_dir_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,21
    shl bx,3
    mov edi,[bx]
    or edi,edi
    jnz map_user_do64
;
    call AllocateRam
    mov edi,esi
    or si,7
    mov [bx],esi
;
    mov ax,flat_sel
    mov ds,ax
    push cx
    mov cx,400h
    xor eax,eax

map_user_init_loop64:
    mov [edi],eax
    add edi,4
    loop map_user_init_loop64
;
    sub edi,1000h
    pop cx

map_user_do64:
    mov ax,flat_sel
    mov ds,ax
    mov ebx,edx
    shr ebx,12
    and ebx,1FFh
    mov eax,200h
    shr ecx,12
    sub eax,ebx
    sub ecx,eax
    jnc map_user_start64
;
    add ecx,eax
    mov eax,ecx
    xor ecx,ecx

map_user_start64:
    shl bx,3
    shl ecx,12
    push ecx
    mov cx,ax
    and dx,0F000h
    or dx,807h
    and di,0F000h
    or di,bx

map_user_loop64:
    mov eax,edx
    add eax,ebp
    mov [edi],eax
    mov dword ptr [edi+4],0
    add edi,8
    add edx,1000h
    loop map_user_loop64
    pop ecx
    or ecx,ecx
    jnz map_user_more64

map_user_done64:
    popad
    pop ds
    ret
map_user64    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           create_paging64
;
;           DESCRIPTION:    Create initial paging for system process, 64-bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_paging64     PROC near
    mov ax,system_data_sel
    mov es,ax
;
    call init_flat_dir64
    call map_dir64
;
    mov ax,system_data_sel
    mov es,ax
    xor edx,edx
    mov ecx,es:alloc_base
    add ecx,1000h
    call map_flat64
;
    mov edx,es:rom1_base
    mov ecx,es:rom1_size
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    call map_flat64
;
    mov edx,es:rom2_base
    mov ecx,es:rom2_size
    or ecx,ecx
    jz create_paging_ram64
;
    add ecx,edx
    and dx,0F000h
    dec ecx
    and cx,0F000h
    add ecx,1000h
    sub ecx,edx
    call map_flat64

create_paging_ram64:
    mov edx,es:efi_acpi
    or edx,es:efi_acpi+4
    jnz create_paging_efi64
;    
    mov edx,0A0000h
    mov ecx,100000h
    sub ecx,edx
    call map_flat_user64
    jmp create_paging_done64
    
create_paging_efi64:
    mov edx,es:efi_scan_size
    movzx eax,es:efi_height
    mul edx
    shl eax,2
    mov ecx,eax
    mov eax,es:efi_lfb
    mov edx,boot_efi_linear
    call map_user64
    
create_paging_done64:
    ret
create_paging64     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setup_proc64
;
;           DESCRIPTION:    Setup 64-bit interface
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_proc64     PROC near
    mov bx,cs
    call local_get_selector_base_size
;
    mov esi,edx
    add esi,OFFSET p64_start
;    
    mov edi,edx
    add edi,OFFSET proc_start
;
    mov cx,OFFSET p64_end - OFFSET p64_start
    shr cx,1    
;
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
    rep movs word ptr es:[edi],[esi]
    ret
setup_proc64    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_phys_bitmap64
;
;           DESCRIPTION:    init physical bitmaps, 64-bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_phys_bitmap64       Proc near
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;    
    call AllocateRam
    mov edi,esi
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]    
;        
    mov eax,esi
    mov edi,esi
    xor ebx,ebx
    or al,3
    mov edx,phys_bitmap_linear
    call local_set_sys_page_dir64
;
    call AllocateRam
    mov eax,esi
    or al,3
    mov ds:[edi],eax
    xor eax,eax
    mov ds:[edi+4],eax
;
    mov ds:[esi].phys_curr_header32,1
    mov ds:[esi].phys_curr_header64,0
    mov ds:[esi].phys_bitmap_count,1
;
    mov ebx,esi
    add ebx,phys_header_start
    mov ds:[ebx].phys_bitmap_free,0
    mov ds:[ebx].phys_bitmap_pos,0
;
    call AllocateRam
    mov eax,esi
    or al,3
    add edi,phys_bitmap_start SHR 9
    mov ds:[edi],eax
    xor eax,eax
    mov ds:[edi+4],eax
;
    mov edi,esi
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov edi,esi
;
    mov ax,system_data_sel
    mov ds,ax

init_phys_alloc_loop64:
    mov esi,ds:alloc_base
    cmp esi,ds:ram1_size
    jae init_phys_alloc_done64
;    
    cmp esi,40000h
    jae init_phys_alloc_done64
;
    call AllocateRam
    mov ecx,esi
    shr ecx,12
    bts es:[edi],ecx
    inc es:[ebx].phys_bitmap_free
    jmp init_phys_alloc_loop64

init_phys_alloc_done64:
    ret
init_phys_bitmap64  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           start_paging64
;
;           DESCRIPTION:    Start paging hardware, 64-bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_paging64    Proc near
    call create_paging64
    call setup_proc64
    call init_phys_bitmap64
;
    mov eax,cr4
    or eax,20h
    mov cr4,eax
;    
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
;
    mov eax,cr3
    mov cr3,eax
;    
    mov ax,system_data_sel
    mov ds,ax
;
    mov ds:long_base,long_map_linear
    mov ds:long_size,long_map_size
;    
    mov eax,ds:cpu_feature_flags
    test ax,2000h
    jz start_paging_global_done64
;    
;    db 0Fh
;    db 20h
;    db 0E0h     ; mov eax,cr4
;
;    or ax,80h   ; enable global pages
;
;    db 0Fh
;    db 22h
;    db 0E0h     ; mov cr4,eax

start_paging_global_done64:
    mov bx,sys_dir_sel
    mov ecx,4000h
    mov edx,sys_page_linear
    shr edx,9
    add edx,sys_page_linear
    call local_create_data_sel16
;
    mov bx,sys_page_sel
    mov edx,sys_page_linear
    mov ecx,800000h
    call local_create_data_sel16
;
    mov bx,process_dir_sel
    mov ecx,4000h
    mov edx,process_page_linear
    shr edx,9
    add edx,process_page_linear
    call local_create_data_sel16
;
    mov bx,process_page_sel
    mov edx,process_page_linear
    mov ecx,800000h
    call local_create_data_sel16
;
    mov bx,phys_bit_sel
    mov ecx,800000h
    mov edx,phys_bitmap_linear
    call local_create_data_sel16
    ret
start_paging64    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           has_adapter_long_mode
;
;           DESCRIPTION:    Check adapter for long mode
;
;           PARAMETERS:     EDX     base address
;
;           RETURNS:        NC      Has long mode driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_adapter_long_mode Proc near
    push ds
    push ax
    push edx
;    
    mov ax,flat_sel
    mov ds,ax

has_adapter_loop:
    mov ax,[edx].typ
    cmp ax,RdosEnd
    je has_adapter_fail
;    
    cmp ax,RdosLongMode
    je has_adapter_ok
;    
    add edx,[edx].len
    jmp has_adapter_loop

has_adapter_fail:
    stc
    jmp has_adapter_done    

has_adapter_ok:
    clc
    
has_adapter_done:
    pop edx
    pop ax
    pop ds
    ret
has_adapter_long_mode Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           has_long_mode
;
;           DESCRIPTION:    Check for long mode driver
;
;           RETURNS:        NC      Has long mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_long_mode   Proc near
    push ds
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax
;
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters

has_long_loop:
    mov edx,[bx].adapter_base
    call has_adapter_long_mode
    jnc has_long_ok
;    
    add bx,SIZE adapter_typ
    loop has_long_loop   
;
    stc 

has_long_ok:
    popad
    pop ds 
    ret
has_long_mode   Endp  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           local_has64
;
;           DESCRIPTION:    Check for 64-bit physical address
;
;           RETURNS:        NC      Has 64-bit address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_has64   PROC near
    push ds
    pushad
;
    mov ax,system_data_sel
    mov ds,ax
;
    mov eax,ds:ram2_size
    or eax,eax
    jnz h64Fail
;
    movzx ecx,ds:multiboot_mmap_len
    mov esi,ds:multiboot_mmap_addr
    or ecx,ecx
    jz h64Fail
;
    mov ax,flat_sel
    mov ds,ax    

h64Loop:
    mov eax,ds:[esi].mmap_type
    cmp eax,1
    jne h64Next
;
    mov eax,ds:[esi].mmap_base
    mov ebx,ds:[esi].mmap_base+4
    add eax,ds:[esi].mmap_size
    adc ebx,ds:[esi].mmap_size+4
    sub eax,1
    sbb ebx,0
    or ebx,ebx
    jnz h64Ok

h64Next:    
    mov eax,ds:[esi].mmap_len
    add eax,4
    add esi,eax
    sub ecx,eax
    ja h64Loop

h64Fail:
    stc
    jmp h64Done

h64Ok:        
    mov ax,system_data_sel
    mov ds,ax
    mov ds:has_phys64,1
    clc

h64Done:            
    popad
    pop ds
    ret
local_has64   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           start_paging
;
;           DESCRIPTION:    Start paging hardware
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public start_paging

start_paging:
    mov ax,system_data_sel
    mov ds,ax
    InitSpinlock ds:page_spinlock
;
    mov ds:long_base,0
    mov ds:long_size,0
    mov ds:has_phys64,0
;    
    mov eax,ds:cpu_feature_flags
    test al,40h
    jz start_paging32
;    
    call local_has64    
    jnc start_paging64        
;
    call has_long_mode
    jnc start_paging64        
;
    jmp start_paging32

code    ENDS

    END

