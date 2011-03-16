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
; CRFUNC.ASM
; Crash monitor common aliased functions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE irq.inc
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE proc.inc

    .386p

ogate_entry      STRUC

ogate_offset             DD ?
ogate_sel                DW ?
ogate_name_offset        DD ?
ogate_name_sel           DW ?
ogate_flags              DW ?

ogate_entry      ENDS

ugate_entry      STRUC

ugate_name_offset        DD ?
ugate_name_sel           DW ?
ugate_entry_offset16     DD ?
ugate_entry_sel16        DW ?
ugate_entry_offset32     DD ?
ugate_entry_sel32        DW ?
ugate_entry_offset_v86   DD ?    
ugate_entry_sel_v86      DW ?
ugate_sel16              DW ?
ugate_sel32              DW ?
ugate_transfer           DW ?

ugate_entry      ENDS

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalCpuReset
;
;           DESCRIPTION:    Trigger a CPU reset
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LocalCpuReset

LocalCpuReset   Proc near
    cli
wait_gate1:
    in al,64h
    and al,2
    jnz wait_gate1
    mov al,0D1h
    out 64h,al
wait_gate2:
    in al,64h
    and al,2
    jnz wait_gate2
    mov al,0FEh
    out 60h,al
;
    xor eax,eax
    mov cr3,eax

reset_wait:
    jmp reset_wait
    
    retf32
LocalCpuReset   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LocalGetSelectorBaseSize
;
;       DESCRIPTION:    Get selector base + size
;
;       PARAMETERS:     GS          Core sel
;                       BX          Selector
;
;       RETURNS:        EDX         Base
;                       ECX         Limit
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LocalGetSelectorBaseSize

LocalGetSelectorBaseSize  PROC near
    push ds
    push ax
    push ebx
;
    movzx ebx,bx
    test bx,4
    jz get_selector_gdt

get_selector_ldt:
    mov ax,gs:cs_ldt
    or ax,ax
    jz get_selector_error
;
    push bx
    mov bx,ax
    call LocalGetSelectorBaseSize
    pop bx
    sub ecx,7
    cmp ebx,ecx
    ja get_selector_error
;    
    mov ebx,edx
    mov ax,flat_sel
    mov ds,ax
    jmp get_selector_check

get_selector_gdt:
    mov ax,gdt_sel
    mov ds,ax
    and bx,0FFF8h
    jz get_selector_error

get_selector_check:
    mov al,[ebx+5]
    test al,80h
    jz get_selector_error
;
    test al,10h
    jz get_selector_error
;
    xor ecx,ecx
    mov cl,[ebx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[ebx]
    test byte ptr [ebx+6],80h
    jz get_selector_small
;
    shl ecx,12
    or cx,0FFFh

get_selector_small:
    inc ecx
    mov edx,[ebx+2]
    rol edx,8
    mov dl,[ebx+7]
    ror edx,8
    clc
    jmp get_selector_done

get_selector_error:
    stc

get_selector_done:
    pop ebx
    pop ax
    pop ds
    ret
LocalGetSelectorBaseSize  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalSetPhysicalPage
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LocalSetPhysicalPage
    
LocalSetPhysicalPage    Proc near
    push ds
    push ebx
    mov bx,process_page_sel
    mov ds,bx
    mov ebx,edx
    shr ebx,10
    and bl,0FCh
    mov [ebx],eax
    mov ebx,cr3
    mov cr3,ebx
    pop ebx
    pop ds
    ret
LocalSetPhysicalPage Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LocalOsGate
;
;       DESCRIPTION:    Translate an os gate
;
;       PARAMETERS:     DS:EBX          Fault address
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LocalOsGate

LocalOsGate:
    sub sp,8
;
    push es
    push ecx
    push edx
    push edi
;
    mov ax,[bp].vm_bp
    mov [bp-12],ax          ; save org bp to pm_call
;
    mov eax,[bp].vm_eax
    mov [bp-16],eax         ; save org eax
;    
    mov eax,[bp].vm_eflags
    push eax
    mov eax,[bp].vm_cs
    mov [bp+14],eax         ; old eflags
    mov eax,[bp].vm_eip
    add eax,9
    mov [bp+10],eax         ; old cs
    pop eax
    mov [bp+6],eax          ; old eip
;    
    mov edi,ds:[ebx+3]
    shl edi,4
    mov ax,osgate_sel
    mov es,ax
;
    push ebx
    mov bx,ds
    call LocalGetSelectorBaseSize
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    mov ax,es:[edi].ogate_sel
    mov [bp+2],ax           ; old err
    mov eax,es:[edi].ogate_offset
    mov [bp-2],eax
;
    mov eax,es:[edi].ogate_offset
    xchg eax,ds:[ebx+3]
    mov ax,es:[edi].ogate_sel
    xchg ax,ds:[ebx+7]
    mov al,90h
    xchg al,ds:[ebx]        
;
    pop edi
    pop edx
    pop ecx
    pop es
;
    mov ds,[bp].pm_ds
    mov eax,[bp-16]
    mov ebx,[bp].vm_ebx
    sub bp,12
    mov sp,bp
    pop bp
    add sp,8
    iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LocalOldOsGate
;
;       DESCRIPTION:    Translate old 16-bit gate
;
;       PARAMETERS:     DS:EBX          Fault address
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LocalOldOsGate

LocalOldOsGate PROC near
    push es
    push ecx
    push edx
    push di
;
    mov al,ds:[ebx]
    cmp al,66h
    je odo16_has_ov
;
    mov di,ds:[ebx+1]
    jmp odo16_ov_done

odo16_has_ov:
    mov di,ds:[ebx+2]

odo16_ov_done:    
    shl di,4
    mov ax,osgate_sel
    mov es,ax
;
    push ebx
    mov bx,ds
    call LocalGetSelectorBaseSize
    pop ebx
    add     ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    mov ax,[bp].vm_eflags
    mov [bp+12],ax
    mov ax,[bp].vm_cs
    mov [bp+16],ax
    mov ax,[bp].vm_eip
    add ax,8
    mov [bp+14],ax  
;
    mov ax,es:[di].ogate_sel
    cmp ax,[bp+16]
    je odo16_direct
;
    mov ds:[ebx+3],ax
    mov [bp+10],ax
    mov eax,es:[di].ogate_offset
    mov ds:[ebx+1],ax
    mov [bp+8],ax
    mov byte ptr ds:[ebx],9Ah
    mov byte ptr ds:[ebx+5],90h
    mov word ptr ds:[ebx+6],9090h
    jmp odo16_direct_do

odo16_direct:
    mov [bp+10],ax
    mov eax,es:[di].ogate_offset
    mov [bp+8],ax
    sub ax,[bp+14]
    add ax,4
    mov ds:[ebx+2],ax
    mov word ptr ds:[ebx],0E80Eh
    mov dword ptr ds:[ebx+4],90909090h

odo16_direct_do:
    pop di
    pop edx
    pop ecx
    pop es
;
    mov ds,[bp].pm_ds
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    mov sp,bp
    pop bp
    add sp,6
    iret
LocalOldOsGate ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalUserGate
;
;           DESCRIPTION:    Execute a 16-bit user-gate
;
;           PARAMETERS:         DS:EBX      Fault address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LocalUserGate

LocalUserGate   PROC near
    push es
    push ecx
    push edx
    push edi
;
    mov edi,ds:[ebx+2]
    shl edi,5
    mov ax,usergate_sel
    mov es,ax
;
    push ebx
    mov bx,ds
    call LocalGetSelectorBaseSize
    pop ebx
    add     ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    test es:[edi].ugate_transfer, gate16_override
    jnz do_call16_direct_to32
;
    mov ax,[bp].vm_eflags
    mov [bp+12],ax
    mov ax,[bp].vm_cs
    mov [bp+16],ax
    mov ax,[bp].vm_eip
    add ax,8
    mov [bp+14],ax  
;
    mov ax,es:[edi].ugate_entry_sel16
    cmp ax,[bp+16]
    je do_call16_direct_cs16
;
    mov ds:[ebx+3],ax
    mov [bp+10],ax
    mov eax,es:[edi].ugate_entry_offset16
    mov ds:[ebx+1],ax
    mov [bp+8],ax
    mov byte ptr ds:[ebx],9Ah
    mov word ptr ds:[ebx+5],9090h
    mov byte ptr ds:[ebx+7],90h
    jmp do_call16_direct_do16

do_call16_direct_cs16:
    mov [bp+10],ax
    mov eax,es:[edi].ugate_entry_offset16
    mov [bp+8],ax
    sub ax,[bp+14]
    add ax,4
    mov ds:[ebx+2],ax
    mov word ptr ds:[ebx],0E80Eh
    mov word ptr ds:[ebx+4],9090h
    mov word ptr ds:[ebx+6],9090h

do_call16_direct_do16:
    pop edi
    pop edx
    pop ecx
    pop es
;
    mov ds,[bp].pm_ds
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    mov sp,bp
    pop bp
    add sp,6
    iret

do_call16_direct_to32:
    mov ax,[bp].vm_eflags
    mov [bp+8],ax
    movzx eax,word ptr [bp].vm_cs
    mov [bp+14],eax
    movzx eax,word ptr [bp].vm_eip
    add eax,8
    mov [bp+10],eax 
;
    mov ax,es:[edi].ugate_entry_sel32
    cmp ax,[bp+14]
    je do_call16_direct_cs32
;
    mov ds:[ebx+6],ax
    mov [bp+6],ax
    mov eax,es:[edi].ugate_entry_offset32
    mov ds:[ebx+2],eax
    mov [bp+4],ax
    mov word ptr ds:[ebx],9A66h
    jmp do_call16_direct_do32

do_call16_direct_cs32:
    mov [bp+6],ax
    mov eax,es:[edi].ugate_entry_offset32
    mov [bp+4],ax
    sub eax,[bp+10]
    mov ds:[ebx+4],eax
    mov dword ptr ds:[ebx],0E8660E66h

do_call16_direct_do32:
    pop edi
    pop edx
    pop ecx
    pop es
;
    mov ds,[bp].pm_ds
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    mov sp,bp
    pop bp
    add sp,2
    iret
LocalUserGate   ENDP


code    ENDS

    END
