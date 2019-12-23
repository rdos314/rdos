;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
; realtime.asm
; Realtime support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.inc
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc
INCLUDE system.def
INCLUDE proc.inc
INCLUDE realtime.def
INCLUDE ..\pcdev\apic.inc

.386p

realtime_handle_struc STRUC

rh_base     handle_header <>
rh_sel      DW ?

realtime_handle_struc ENDS

realtime_struc	STRUC

rs_core_arr	DW 256 DUP(?)

realtime_struc	ENDS

data    SEGMENT byte public 'DATA'

map_sel	        DW ?
map_linear	DD ?

uni_phys_pml    DD ?,?

mon_linear      DD ?
mon_size        DD ?
mon_phys_dir    DD ?,?

mon_thread      DW ?

mon_arr         DW 256 DUP(?)

data    ENDS

code    SEGMENT byte public use32 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Realtime int (85h)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

realtime_int:
    pushad
    push ds
    push es
    push fs
;    
    EnterInt    
    mov ax,apic_mem_sel
    mov ds,eax
    xor eax,eax
    mov ds:APIC_EOI,eax
;
    mov ax,SEG data
    mov ds,eax
    mov bx,ds:mon_thread
    Signal
    LeaveInt
;    
    pop ax
    verr ax
    jz ri_fs_ok
;
    xor ax,ax

ri_fs_ok:
    mov fs,ax
;    
    pop ax
    verr ax
    jz ri_es_ok
;
    xor ax,ax

ri_es_ok:
    mov es,ax
;    
    pop ax
    verr ax
    jz ri_ds_ok
;
    xor ax,ax

ri_ds_ok:
    mov ds,ax
;    
    popad
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateMonitor
;
;           DESCRIPTION:    Create monitor
;
;           PARAMETERS:     FS          Processor sel
;                           ES          Thread sel
;
;           RETURNS:        ES          Monitor data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMonitor      Proc near
    push ds
    pushad
;
    mov eax,flat_sel
    mov es,eax
;
    mov eax,1000h
    AllocateBigLinear
    mov fs:ps_mon_linear,edx
;
    AllocatePhysical32
    mov fs:ps_cr3,eax
;
    mov al,3
    SetPageEntry
;
    mov ax,SEG data
    mov ds,eax
    mov edi,edx
;
    mov eax,ds:uni_phys_pml
    stos dword ptr es:[edi]
;
    mov eax,ds:uni_phys_pml+4
    stos dword ptr es:[edi]
;
    mov ecx,3FEh
    rep stos dword ptr es:[edi]
    mov edi,edx
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    or al,3
    mov es:[edi+0FF8h],eax
    mov es:[edi+0FFCh],ebx
    SetPageEntry
;
    AllocatePhysical64
    or al,3
    mov es:[edx],eax
    mov es:[edx+4],ebx
;
    push eax
    mov edi,edx
    add edi,8
    mov ecx,3FEh
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop eax
    SetPageEntry
;
    mov eax,ds:mon_phys_dir
    mov ebx,ds:mon_phys_dir+4
    mov es:[edx],eax
    mov es:[edx+4],ebx
;
    AllocatePhysical64
    or al,3
    mov es:[edx+8],eax
    mov es:[edx+12],ebx
;
    push eax
    mov edi,edx
    add edi,16
    mov ecx,3FCh
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop eax
    SetPageEntry
;
    mov edi,edx
    AllocatePhysical64
    or al,3
    mov es:[edi],eax
    mov es:[edi+4],ebx
    add edi,8
;
    xor eax,eax
    mov ecx,2
    rep stos dword ptr es:[edi]
;
    push edx
    mov bx,apic_mem_sel
    GetSelectorBaseSize
    GetPageEntry
    pop edx
;
    mov es:[edi],eax
    mov es:[edi+4],ebx
    add edi,8
;
    xor eax,eax
    mov ecx,2
    rep stos dword ptr es:[edi]
;
    push edx
    mov ds,fs:ps_null_thread
    mov edx,ds:p_linear
    GetPageEntry
    pop edx
;
    mov es:[edi],eax
    mov es:[edi+4],ebx
    add edi,8
;
    xor eax,eax
    mov ecx,2
    rep stos dword ptr es:[edi]
;
    AllocatePhysical64
    or al,3
    mov es:[edi],eax
    mov es:[edi+4],ebx
    add edi,8
;
    push eax
    mov ecx,3F2h
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop eax
;
    SetPageEntry
;
    AllocateGdt
    mov ecx,SIZE realtime_data_struc
    CreateDataSelector32
    mov es,bx
;
    popad
    pop ds
    ret
CreateMonitor	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateRealtime
;
;           DESCRIPTION:    Create realtime handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_realtime_name    DB 'Create Realtime',0

create_realtime     PROC far
    push ds
    push es
    push eax
    push ecx
    push edi
;
    mov cx,SIZE realtime_handle_struc
    AllocateHandle
    mov ds:[ebx].hh_sign,REALTIME_HANDLE
;
    mov eax,SIZE realtime_struc
    AllocateSmallGlobalMem
    mov ds:[ebx].rh_sel,es
;
    mov ecx,256
    mov edi,OFFSET rs_core_arr
    xor ax,ax
    rep stos word ptr es:[edi]
;       
    mov bx,[ebx].hh_handle
;
    pop edi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
create_realtime     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddRealtimeCore
;
;           DESCRIPTION:    Add realtime core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_realtime_core_name    DB 'Add Realtime Core',0

add_realtime_core     PROC near
    push ds
    push es
    push fs
    push gs
    push ebx
;
    mov ax,REALTIME_HANDLE
    DerefHandle
    jc arcDone
;
    mov gs,ds:[ebx].rh_sel
;
    mov ax,SEG data
    mov ds,eax
;
    AllocateRealtimeCore
    jc arcDone
;
    GetCoreNumber
    jc arcDone
;
    mov es,fs:ps_null_thread
    mov es:p_realtime,1
    mov es:p_tss_sel,0
    call CreateMonitor
;
    movzx eax,al
    mov bx,ax
    shl bx,1
    mov es:rds_flags,0
    mov ds:[bx].mon_arr,es
    mov gs:[bx].rs_core_arr,es
;
    mov es,fs:ps_null_thread
    mov ebx,fs:ps_cr3
    mov es:p_cr3,ebx
    mov es:p_fault_vector,3
    BootRealtimeCore
    DebugRealtime
    clc

arcDone:
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    ret
add_realtime_core     Endp

add_realtime_core16	Proc far
    push edi
    movzx edi,di
    call add_realtime_core
    pop edi
    ret
add_realtime_core16	Endp

add_realtime_core32	Proc far
    call add_realtime_core
    ret
add_realtime_core32	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitMonitor
;
;           DESCRIPTION:    install monitor
;
;           PARAMETERS:     EDI         base address
;                           ECX         size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitMonitor      Proc near
    push ds
    pushad
;
    mov ax,SEG data
    mov ds,eax
;
    mov esi,edi
    mov ecx,es:[esi].rt_size
    add esi,SIZE real_time_header
    mov ebp,ecx
;
    mov eax,ecx
    dec eax
    and ax,0F000h
    add eax,1000h
    mov ds:mon_size,eax
    AllocateBigLinear
    mov ds:mon_linear,edx
;
    mov ecx,ebp
    mov edi,edx
    rep movs byte ptr es:[edi],es:[esi]
;
    mov eax,1000h
    AllocateBigLinear
    mov ds:map_linear,edx
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov ds:map_sel,bx
;
    popad
    pop ds
    ret
InitMonitor	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MapMonitor
;
;           DESCRIPTION:    Map monitor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapMonitor     PROC near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,eax
    mov ax,flat_sel
    mov es,eax
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    mov al,3
    mov ds:mon_phys_dir,eax
    mov ds:mon_phys_dir+4,ebx
;
    SetPageEntry
    mov edi,edx
;
    mov ebp,200h
    mov edx,ds:mon_linear
    mov ecx,ds:mon_size
    shr ecx,12

mmCopyMonLoop:    
    GetPageEntry
;
    mov al,3
    mov es:[edi],eax
    mov es:[edi+4],ebx
;
    dec ebp
    add edx,1000h
    add edi,8
    sub ecx,1
    jnz mmCopyMonLoop

mmPadMonLoop:
    xor eax,eax
    stos dword ptr es:[edi]
    stos dword ptr es:[edi]
;
    sub ebp,1
    jnz mmPadMonLoop
    
mmDone:
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
;
    mov ecx,1000h
    FreeLinear
;
    popad
    pop es
    pop ds
    ret
MapMonitor     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetupUniPml4
;
;           DESCRIPTION:    Setup plm4 entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupUniPml4     PROC near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,eax
    mov ax,flat_sel
    mov es,eax
;
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    xor esi,esi
;    
    AllocatePhysical64
    mov al,3
    mov es:[edi],eax
    mov es:[edi+4],ebx
;
    mov ds:uni_phys_pml,eax
    mov ds:uni_phys_pml+4,ebx
;
    push eax
    add edi,8
    mov ecx,3FEh
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop eax
;
    SetPageEntry
;
    mov edi,edx
    AllocatePhysical64
    mov al,3
    mov es:[edi],eax
    mov es:[edi+4],ebx
;
    push eax
    add edi,8
    mov ecx,3FEh
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop eax
;
    SetPageEntry
;
    mov edi,edx
    mov eax,83h
    mov es:[edi],eax
;
    xor eax,eax
    mov es:[edi+4],eax
;
    add edi,8
    mov ecx,3FEh
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
;
    mov ecx,1000h
    FreeLinear
;
    popad
    pop es
    pop ds
    ret
SetupUniPml4	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           load_adapter_monitor
;
;           DESCRIPTION:    install adapter monitor
;
;           PARAMETERS:     edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_adapter_monitor      Proc near
    push ds
    push ax
    push bx
    push edx
;    
    mov ax,flat_sel
    mov ds,ax

load_adapter_mon_loop:
    mov ax,[edx].typ
    cmp ax,RdosRealTime
    jne not_install_mon
;
    push ds
    push es
    push ecx
;
    mov ecx,[edx].len
    mov ax,ds
    mov es,ax
    mov edi,edx
    add edi,SIZE rdos_header
    sub ecx,SIZE rdos_header
    call InitMonitor
    call MapMonitor
    call SetupUniPml4
;
    pop ecx
    pop es
    pop ds
    jmp load_adapter_mon_done

not_install_mon:
    cmp ax,RdosEnd
    je load_adapter_mon_done

load_adapter_mon_next:
    add edx,[edx].len
    jmp load_adapter_mon_loop

load_adapter_mon_done:
    pop edx
    pop bx
    pop ax
    pop ds
    ret
load_adapter_monitor      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_realtime_handle
;
;           DESCRIPTION:    BX              Realtime handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_realtime_handle       Proc far
    push ds
    push ax
    push ebx
;
    mov ax,REALTIME_HANDLE
    DerefHandle
    jc delete_realtime_handle_done
;

delete_realtime_handle_done:
    pop ebx
    pop ax
    pop ds
    ret
delete_realtime_handle       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov eax,SEG data
    mov ds,eax
    mov es,eax
    mov ds:mon_linear,0
    mov ds:mon_size,0
    mov ds:map_linear,0
    mov ds:map_sel,0
    mov ds:mon_thread,0
;
    mov edi,OFFSET mon_arr
    mov ecx,256
    xor ax,ax
    rep stos word ptr es:[edi]
;
    mov ax,system_data_sel
    mov ds,ax
    movzx ecx,ds:rom_modules
    mov bx,OFFSET rom_adapters

init_mon_loop:
    mov edx,[bx].adapter_base
    call load_adapter_monitor
    add bx,SIZE adapter_typ
    loop init_mon_loop     
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov al,85h
    mov esi,OFFSET realtime_int
    SetupIntGate
;    
    mov ax,REALTIME_HANDLE
    mov edi,OFFSET delete_realtime_handle
    RegisterHandle
;
    mov esi,OFFSET create_realtime
    mov edi,OFFSET create_realtime_name
    xor dx,dx
    mov ax,create_realtime_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET add_realtime_core16
    mov esi,OFFSET add_realtime_core32
    mov edi,OFFSET add_realtime_core_name
    mov dx,virt_es_in
    mov ax,add_realtime_core_nr
    RegisterUserGate
    ret
init    ENDP
    

code    ENDS

    END init
