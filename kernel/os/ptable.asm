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

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

    extrn local_get_selector_base_size:near
    extrn local_create_data_sel16:near
    extrn local_allocate_physical:near
    extrn local_free_physical:near
    extrn local_flush_process_tlb:near

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
    public has_page_entry_proc
    public reserve_page_entries_proc
    public allocate_page_entries_proc
    public allocate_sys_page_entries_proc
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

proc_start:
init_process_proc               DW OFFSET local_init_process32
create_process_proc             DW OFFSET local_create_process32
free_process_proc               DW OFFSET local_free_process32
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
reserve_page_entries_proc       DW OFFSET local_reserve_page_entries32
allocate_page_entries_proc      DW OFFSET local_allocate_page_entries32
allocate_sys_page_entries_proc  DW OFFSET local_allocate_sys_page_entries32
free_page_entries_proc          DW OFFSET local_free_page_entries32
free_global_page_entries_proc   DW OFFSET local_free_global_page_entries32
copy_page_entries_proc          DW OFFSET local_copy_page_entries32
copy_sys_page_entries_proc      DW OFFSET local_copy_sys_page_entries32
move_page_entries_proc          DW OFFSET local_move_page_entries32
emulate_page_proc               DW OFFSET local_emulate_page32
hook_page_proc                  DW OFFSET local_hook_page32
unhook_page_proc                DW OFFSET local_unhook_page32
get_thread_page_entry_proc      DW OFFSET local_get_thread_page_entry32
set_thread_page_entry_proc      DW OFFSET local_set_thread_page_entry32
get_thread_page_dir_proc        DW OFFSET local_get_thread_page_dir32

IFDEF PAE

p64_start:
init_process_p64                DW OFFSET local_init_process64
create_process_p64              DW OFFSET local_create_process64
free_process_p64                DW OFFSET local_free_process64
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
reserve_page_entries_p64        DW OFFSET local_reserve_page_entries64
allocate_page_entries_p64       DW OFFSET local_allocate_page_entries64
allocate_sys_page_entries_p64   DW OFFSET local_allocate_sys_page_entries64
free_page_entries_p64           DW OFFSET local_free_page_entries64
free_global_page_entries_p64    DW OFFSET local_free_global_page_entries64
copy_page_entries_p64           DW OFFSET local_copy_page_entries64
copy_sys_page_entries_p64       DW OFFSET local_copy_sys_page_entries64
move_page_entries_p64           DW OFFSET local_move_page_entries64
emulate_page_p64                DW OFFSET local_emulate_page64
hook_page_p64                   DW OFFSET local_hook_page64
unhook_page_p64                 DW OFFSET local_unhook_page64
get_thread_page_entry_p64       DW OFFSET local_get_thread_page_entry64
set_thread_page_entry_p64       DW OFFSET local_set_thread_page_entry64
get_thread_page_dir_p64         DW OFFSET local_get_thread_page_dir64
p64_end:

ENDIF

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
    mov esi,OFFSET free_global_page_entries
    mov edi,OFFSET free_global_page_entries_name
    xor cl,cl
    mov ax,free_global_page_entries_nr
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
;           PARAMETERS:     ES          Thread
;                           EAX         CR3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_process32       PROC near
    push ds
    push es
    mov eax,3000h
    AllocateGlobalMem
    mov ax,sys_dir_sel
    mov ds,ax
    xor ax,ax
    mov di,1000h
    mov ecx,system_mem_start
    shr ecx,22
    rep stosd
    mov eax,system_mem_start
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
    mov eax,[edx+8]
    mov di,1000h
    mov es:[di],eax
;
    mov eax,[edx+4]
    mov al,7
    mov ebx,process_page_linear
    shr ebx,20
    mov es:[bx+di],eax
;
    mov dx,es
    mov fs,dx
    pop es
    pop ds
    mov es:p_cr3,eax
    mov ds:p_tss_cr3,eax
    ret
local_create_process32       ENDP

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
    mov bx,process_page_sel
    mov ds,bx
    mov bx,process_dir_sel
    mov es,bx
    xor esi,esi
    mov ecx,flat_size
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
    mov eax,flat_size
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
    ret
local_free_process32     Endp


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
    push edx
;
    or ebx,ebx
    jz sppok32
;
    int 3

sppok32:    
    mov cx,process_page_sel
    mov ds,cx
    shr edx,10
    and dl,0FCh
;
    xchg eax,[edx]
    test al,1
    jz sppDone
;
    mov cx,1
    call local_flush_process_tlb    

sppDone:
    pop edx
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
    call local_flush_process_tlb    

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
    call local_flush_process_tlb    

fgpeDone32:
    popad
    pop ds
    ret
local_free_global_page_entries32       Endp

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
    call local_flush_process_tlb    

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
    call local_flush_process_tlb    
;
    pop edx
    call local_flush_process_tlb    

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
;           DESCRIPTION:    Hook for a specified linear address range
;
;           PARAMETERS:     EAX         Size
;                           EDX         Linear base
;                           ES:DI       Callback
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
    mov ax,es
    or al,6
    mov [edx],ax
    mov [edx+2],di

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
    SimCli
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
    jnz get_thread_phys_do32
;
    xor eax,eax
    xor ebx,ebx
    jmp get_thread_phys_done32

get_thread_phys_do32:     
    mov ax,flat_sel
    mov ds,ax
    mov eax,[ebx]
    xor ebx,ebx

get_thread_phys_done32:
    SimSti
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
    SimCli
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
    SimSti
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
;    
    mov eax,cr3
    push eax
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
;    
    pop edx
    mov cr3,edx
    sti
    xor ebx,ebx
;
    pop edx
    pop ds    
    ret
local_get_thread_page_dir32    Endp

IFDEF PAE

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
    pop bp
    int 3
    ret
local_init_process64     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Create_process64
;
;           DESCRIPTION:    Create process paging environment
;
;           PARAMETERS:     ES          Thread
;                           EAX         CR3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_process64       PROC near
    pop bp
    int 3
    ret
local_create_process64       ENDP

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
    pop bp
    int 3
    ret
local_free_process64     Endp


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
    pop bp
    int 3

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
    pop bp
    int 3
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
    pop bp
    int 3
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
    pop bp
    int 3
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
    pop bp
    int 3
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
    pop bp
    int 3
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
    pop bp
    int 3
    ret
local_get_sys_page_dir64    Endp    

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
    pop bp
    int 3
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
    shr edx,21
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
;           NAME:           local_create_page_dir64
;
;           DESCRIPTION:    Create page directory entry
;
;           PARAMETERS:     EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_create_page_dir64       Proc near
    pop bp
    int 3
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
    pop bp
    int 3
    ret
local_create_sys_page_dir64    Endp    

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
    pop bp
    int 3
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
    pop bp
    int 3
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
    pop bp
    int 3
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
    pop bp
    int 3
    ret
local_allocate_sys_page_entries64       Endp

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
    pop bp
    int 3
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
    pop bp
    int 3
    ret
local_free_global_page_entries64       Endp

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
    pop bp
    int 3
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
    pop bp
    int 3
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
    pop bp
    int 3
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
    pop bp
    int 3
    ret
local_emulate_page64    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           local_hook_page64
;
;           DESCRIPTION:    Hook for a specified linear address range
;
;           PARAMETERS:     EAX         Size
;                           EDX         Linear base
;                           ES:DI       Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_hook_page64       PROC near
    pop bp
    int 3
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
    pop bp
    int 3
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
;                           EDX         Linear address
;
;           RETURNS:        EBX:EAX     Physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_thread_page_entry64    Proc near
    pop bp
    int 3
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
;                           EDX         Linear address
;                           EBX:EAX     Physical address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_set_thread_page_entry64    Proc near
    pop bp
    int 3
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
;                           EDX         Linear address
;
;           RETURNS:        EBX:EAX     Physical address or 0                       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

local_get_thread_page_dir64    Proc near
    pop bp
    int 3
    ret
local_get_thread_page_dir64    Endp

ENDIF

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
    call cs:allocate_page_entries_proc
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
;           NAME:           FreeGlobalPageEntries
;
;           DESCRIPTION:    Free global page entries 
;
;           PARAMETERS:     EAX         free signature
;                           ECX         number of entries
;                           EDX         linear address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_global_page_entries_name  DB 'Free Global Page Entries',0

free_global_page_entries       Proc far
    call cs:free_global_page_entries_proc
    retf32
free_global_page_entries       Endp

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
;                           ES:DI       Callback
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
    mov ecx,es:ram2_size
    or ecx,ecx
    jz create_paging_done32
;
    mov edx,0A0000h
    mov ecx,100000h
    sub ecx,edx
    call map_flat_user32
    
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
    mov ds:[esi].phys_curr_header64,32
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
;           NAME:           init_physical32
;
;           DESCRIPTION:    init physical page directories & tables, 32-bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_physical32       Proc near
    mov ax,flat_sel
    mov ds,ax
    mov ax,system_data_sel
    mov fs,ax
    mov fs:phys_free_pages,0
;
    call local_get_page_dir_attrib32
    xor edi,edi

init_phys_page_pages_dir32:
    push esi    
    call AllocateRam
    mov eax,esi
    pop esi
;    
    push eax
    xor ebx,ebx
    mov edx,phys_page_linear
    add edx,edi
    or al,3
    call cs:set_sys_page_dir_proc
    pop edx
;
    push ecx
    mov cx,400h
    xor eax,eax

init_phys_page_pages32:
    mov [edx],eax
    add edx,4
    loop init_phys_page_pages32
;
    pop ecx
    add edi,esi
    loop init_phys_page_pages_dir32
;
    mov ax,sys_dir_sel
    mov es,ax
    call AllocateRam
    mov edx,esi
    mov bx,(phys_list_linear SHR 20) AND 0FFFh
    and bl,0FCh
    or si,3
    mov es:[bx],esi
;
    mov cx,400h
    xor eax,eax
    
init_phys_list_pages32:
    mov [edx],eax
    add edx,4
    loop init_phys_list_pages32
;
    xor ebx,ebx
    xor ebp,ebp

init_free_dir_loop32:
    call AllocateRam
    jc init_free_done32
;
    mov di,(phys_page_linear SHR 20) AND 0FFFh
    mov edx,es:[di]
    xor dl,dl
;
    push esi
    or si,3
    mov [ebx+edx],esi
;
    call AllocateRam
    jc init_free_done32
;
    mov edi,(phys_list_linear SHR 20) AND 0FFFh
    mov edx,es:[di]
    xor dl,dl
;
    push esi
    or si,3
    mov [ebx+edx],esi
;
    pop edx
    pop edi
    mov cx,400h

init_free_page_loop32:
    call AllocateRam
    jc init_free_done32
;
    or si,3
    mov [edi],esi
    add ebp,4
    mov [edx],ebp
    add edx,4
    add edi,4
;
    inc fs:phys_free_pages
    loop init_free_page_loop32
;       
    add ebx,4
    jmp init_free_dir_loop32

init_free_done32:
    mov fs:unused_phys_list,-1
    mov fs:free_phys_list,0
    mov fs:free_dma_phys_list,0
    ret
init_physical32       Endp

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

    public start_paging32

start_paging32    Proc near
    call create_paging32
    call init_phys_bitmap32
    call init_physical32
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

IFDEF PAE

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
    mov ecx,es:ram2_size
    or ecx,ecx
    jz create_paging_done64
;
    mov edx,0A0000h
    mov ecx,100000h
    sub ecx,edx
    call map_flat_user64
    
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
;           NAME:           init_physical64
;
;           DESCRIPTION:    init physical page directories & tables, 64-bit version
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_physical64       Proc near
    mov ax,flat_sel
    mov ds,ax
    mov ax,system_data_sel
    mov fs,ax
    mov fs:phys_free_pages,0
    jmp init_free_done64
;
    call local_get_page_dir_attrib64
    xor edi,edi

init_phys_page_pages_dir64:
    push esi    
    call AllocateRam
    mov eax,esi
    pop esi
;    
    push eax
    xor ebx,ebx
    mov edx,phys_page_linear
    add edx,edi
    or al,3
    call cs:set_sys_page_dir_proc
    pop edx
;
    push ecx
    mov cx,400h
    xor eax,eax

init_phys_page_pages64:
    mov [edx],eax
    add edx,4
    loop init_phys_page_pages64
;
    pop ecx
    add edi,esi
    loop init_phys_page_pages_dir64
;
    mov ax,sys_dir_sel
    mov es,ax
    call AllocateRam
    mov edx,esi
    mov bx,(phys_list_linear SHR 21) AND 3FFFh
    and bl,0F8h
    or si,3
    mov es:[bx],esi
;
    mov cx,400h
    xor eax,eax
    
init_phys_list_pages64_1:
    mov [edx],eax
    add edx,4
    loop init_phys_list_pages64_1
;
    mov ax,sys_dir_sel
    mov es,ax
    call AllocateRam
    mov edx,esi
    mov bx,(phys_list_linear SHR 21) AND 3FFFh
    and bl,0F8h
    add bx,8
    or si,3
    mov es:[bx],esi
;
    mov cx,400h
    xor eax,eax
    
init_phys_list_pages64_2:
    mov [edx],eax
    add edx,4
    loop init_phys_list_pages64_2
;
    xor ebx,ebx
    xor ebp,ebp

init_free_dir_loop64:
    call AllocateRam
    jc init_free_done64
;
    mov di,(phys_page_linear SHR 21) AND 3FFFh
    mov edx,es:[di]
    xor dl,dl
;
    push esi
    or si,3
    mov [ebx+edx],esi
;
    call AllocateRam
    jc init_free_done64
;
    mov edi,(phys_list_linear SHR 21) AND 3FFFh
    mov edx,es:[di]
    xor dl,dl
;
    push esi
    or si,3
    mov [ebx+edx],esi
;
    pop edx
    pop edi
    mov cx,200h

init_free_page_loop64:
    call AllocateRam
    jc init_free_done64
;
    or si,3
    xor eax,eax
    mov [edi],esi
    mov [edi+4],eax
    add ebp,8
    mov [edx],ebp
    mov [edx+4],eax
    add edx,8
    add edi,8
;
    inc fs:phys_free_pages
    loop init_free_page_loop64
;       
    add ebx,8
    jmp init_free_dir_loop64

init_free_done64:
    mov fs:unused_phys_list,-1
    mov fs:free_phys_list,0
    mov fs:free_dma_phys_list,0
    ret
init_physical64       Endp


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

    public start_paging64

start_paging64    Proc near
    call create_paging64
    call setup_proc64
    call init_physical64
;
    mov eax,cr4
    or eax,20h
    mov cr4,eax
;    
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
;
    mov ax,system_data_sel
    mov ds,ax
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

ENDIF

code    ENDS

    END

