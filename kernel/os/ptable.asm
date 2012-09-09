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

    extrn local_free_physical:near
    extrn local_flush_process_tlb:near

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Procedure addresses for non-PAE/PAE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_page_entry_proc
    public set_page_entry_proc
    public has_page_entry_proc
    public reserve_page_entries_proc
    public allocate_page_entries_proc
    public free_page_entries_proc
    public free_global_page_entries_proc
    public copy_page_entries_proc
    public move_page_entries_proc
    public emulate_page_proc
    public hook_page_proc
    public unhook_page_proc
    public get_thread_page_entry_proc
    public set_thread_page_entry_proc

get_page_entry_proc             DW OFFSET local_get_page_entry32
set_page_entry_proc             DW OFFSET local_set_page_entry32
has_page_entry_proc             DW OFFSET local_has_page_entry32
reserve_page_entries_proc       DW OFFSET local_reserve_page_entries32
allocate_page_entries_proc      DW OFFSET local_allocate_page_entries32
free_page_entries_proc          DW OFFSET local_free_page_entries32
free_global_page_entries_proc   DW OFFSET local_free_global_page_entries32
copy_page_entries_proc          DW OFFSET local_copy_page_entries32
move_page_entries_proc          DW OFFSET local_move_page_entries32
emulate_page_proc               DW OFFSET local_emulate_page32
hook_page_proc                  DW OFFSET local_hook_page32
unhook_page_proc                DW OFFSET local_unhook_page32
get_thread_page_entry_proc      DW OFFSET local_get_thread_page_entry32
set_thread_page_entry_proc      DW OFFSET local_set_thread_page_entry32

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
    mov esi,OFFSET has_page_entry
    mov edi,OFFSET has_page_entry_name
    xor cl,cl
    mov ax,has_page_entry_nr
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
    pop ds
    popa
    ret
init_page_table     ENDP

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
    push ebx
    push cx
;
    or ebx,ebx
    jz sppok32
;
    int 3

sppok32:    
    mov bx,process_page_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,10
    and bl,0FCh
    mov [ebx],eax
    mov cx,1
    call local_flush_process_tlb    
;
    pop cx
    pop ebx
    pop ds
    ret
local_set_page_entry32       Endp

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

code    ENDS

    END

