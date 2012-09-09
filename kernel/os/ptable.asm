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
    public free_page_entries_proc
    public copy_page_entries_proc
    public move_page_entries_proc
    public get_thread_page_entry_proc
    public set_thread_page_entry_proc

get_page_entry_proc         DW OFFSET local_get_page_entry32
set_page_entry_proc         DW OFFSET local_set_page_entry32
has_page_entry_proc         DW OFFSET local_has_page_entry32
free_page_entries_proc      DW OFFSET local_free_page_entries32
copy_page_entries_proc      DW OFFSET local_copy_page_entries32
move_page_entries_proc      DW OFFSET local_move_page_entries32
get_thread_page_entry_proc  DW OFFSET local_get_thread_page_entry32
set_thread_page_entry_proc  DW OFFSET local_set_thread_page_entry32

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
    mov esi,OFFSET free_page_entries
    mov edi,OFFSET free_page_entries_name
    xor cl,cl
    mov ax,free_page_entries_nr
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
    push ebx
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
    pop ebx
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

