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
; CRSHOW.ASM
; Crash register dump
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\proc.inc
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\gate.def
INCLUDE kdebug.inc

code_page_linear  = 100000h
map_page_linear =   1FF000h

data    SEGMENT byte public 'DATA'

map_linear   DD ?
map_spinlock DW ?

mon_linear   DD ?
mon_cr3      DD ?

switch_proc   DD ?
switch_linear DD ?
switch_flags  DW ?
switch_base   DD ?
switch_size   DD ?
switch_cr3    DD ?
switch_low    DD ?
pae_low       DD ?
switch_gdt    DD ?
switch_idt    DD ?

data    ENDS

    .686p

code    SEGMENT byte public use32 'CODE'

    assume cs:code
    
    extrn set_monitor_data:near
    extrn set_monitor_gdt:near
    extrn set_monitor_idt:near
    extrn start_monitor:near

    extrn InitMonitorIdt:near
    extrn InitMonitorGdt:near
    extrn StartMonitor:near
    extrn CreateDataSel32:near
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateRam
;
;           DESCRIPTION:    get free ram during startup
;
;           RETURNS:        NC      ESI         address to use
;                           CY              no more free ram
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateRam     Proc near
    push ds
    push es
    push eax
;
    mov ax,flat_sel
    mov ds,ax
    mov ax,system_data_sel
    mov es,ax
    mov esi,es:alloc_base
    jmp LowRamNext

LowRamLoop:
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je RamFound

LowRamNext:
    add esi,1000h
    cmp esi,9F000h
    jc LowRamLoop
;
    mov esi,100000h
HighRamLoop:
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je RamFound

    add esi,1000h
    jmp HighRamLoop

RamFound:
    mov es:alloc_base,esi
    pop eax
    pop es
    pop ds
    ret
AllocateRam     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSelectorBase
;
;           DESCRIPTION:    Get selector base 
;
;           PARAMETERS:     BX              Selector
;
;           RETURNS:        EDX             Base
;                           ECX             Size
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSelectorBase  PROC near
    push ds
    push ax
    push bx
;    
    mov ax,gdt_sel
    mov ds,ax
;
    and bx,0FFF8h
    jz gsbError
;
    mov al,[bx+5]
    test al,80h
    jz gsbError
;
    test al,10h
    jz gsbError
;    
    xor ecx,ecx
    mov cl,[bx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[bx]
    test byte ptr [bx+6],80h
    jz gsbSmall
;
    shl ecx,12
    or cx,0FFFh

gsbSmall:
    inc ecx
;    
    mov edx,[bx+2]
    rol edx,8
    mov dl,[bx+7]
    ror edx,8
    clc
    jmp gsbDone

gsbError:
    stc

gsbDone:
    pop bx
    pop ax
    pop ds
    ret
GetSelectorBase  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MoveSel
;
;           DESCRIPTION:    Move selector
;
;           PARAMETERS:     SI      Source sel
;                           DI      Dest sel
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveSel  PROC near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax  
    movzx edi,di
    add edi,ds:switch_gdt
;    
    mov ax,gdt_sel
    mov ds,ax
    movzx esi,si
    mov ax,flat_sel
    mov es,ax
;
    mov ecx,2
    rep movsd    
;    
    popad
    pop es
    pop ds
    ret
MoveSel Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ZeroPage
;
;           DESCRIPTION:    Zero a page
;
;           PARAMETERS:     ESI             Page
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ZeroPage  PROC near
    push es
    push eax
    push ecx
    push edi
;
    mov ax,flat_sel
    mov es,ax
    mov edi,esi
    mov ecx,400h
    xor eax,eax
    rep stosd
;
    pop edi
    pop ecx
    pop eax
    pop es
    ret
ZeroPage    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapLowProt
;
;           DESCRIPTION:    Map low 2MB, protect mode paging
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapLowProt  PROC near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov ebx,ds:switch_low
    mov esi,ds:switch_base
;    
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;
    mov ecx,100h
    mov eax,7

mlProtUnityLoop:
    mov ds:[ebx],eax
    add ebx,4
    add eax,1000h
    loop mlProtUnityLoop
;
    mov ecx,100h
    mov eax,esi
    and ax,0F000h
    mov al,7

mlProtCrashLoop:
    mov ds:[ebx],eax
    add ebx,4
    add eax,1000h
    loop mlProtCrashLoop
;
    mov edi,ebx
    mov ecx,200h
    xor eax,eax
    rep stosd        
;
    popad
    pop es
    pop ds        
    ret
MapLowProt    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapLowPae
;
;           DESCRIPTION:    Map low 2MB, PAE paging
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapLowPae  PROC near
    push ds
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov ebx,ds:switch_low
    mov esi,ds:switch_base
;    
    mov ax,flat_sel
    mov ds,ax
;
    mov ecx,100h
    mov eax,7
    xor edx,edx

mlPaeUnityLoop:
    mov ds:[ebx],eax
    add ebx,4
;
    mov ds:[ebx],edx
    add ebx,4
;
    add eax,1000h
    loop mlPaeUnityLoop
;
    mov ecx,100h
    mov eax,esi
    and ax,0F000h
    mov al,7

mlPaeCrashLoop:
    mov ds:[ebx],eax
    add ebx,4
;
    mov ds:[ebx],edx
    add ebx,4
;    
    add eax,1000h
    loop mlPaeCrashLoop
;
    popad
    pop ds        
    ret
MapLowPae    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapProt
;
;           DESCRIPTION:    Map protected mode paging structure
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapProt  PROC near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;
    mov ebx,ds:switch_cr3
    mov eax,ds:switch_low
    mov al,7
    mov es:[ebx],eax
;    
    popad
    pop es
    pop ds
    ret
MapProt Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapPae
;
;           DESCRIPTION:    Map PAE paging structure
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapPae  PROC near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;
    mov ebx,ds:switch_cr3
    mov eax,ds:pae_low
    mov al,7
    xor edx,edx
    mov es:[ebx],eax
    mov es:[ebx+4],edx
;
    mov ebx,ds:pae_low
    mov eax,ds:switch_low
    mov al,7
    mov es:[ebx],eax
    mov es:[ebx+4],edx
;
    popad
    pop es
    pop ds
    ret
MapPae Endp
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DetectFlags
;
;       DESCRIPTION:    Detect PAE and video flags
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DetectFlags Proc near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov ds:switch_flags,0
;
    pushfd
    pop eax
    mov ecx,eax
    xor eax,40000h
    push eax
    popfd
    pushfd
    pop eax
    xor eax,ecx
    jz dfProt
;
    mov eax,ecx
    xor eax,200000h
    push eax
    popfd
    pushfd
    pop eax
    xor eax,ecx
    je dfProt
;
    mov eax,1
    cpuid
    test edx,40h
    jz dfProt

dfPae:    
;    or ds:switch_flags,PM_FLAG_PAE

dfProt:
    mov ax,flat_sel
    mov es,ax
    xor eax,eax
    mov ecx,100h
    xor bx,bx

dfVectLoop:
    or eax,es:[bx]
    add bx,4
    loop dfVectLoop
;
    or eax,eax
    jz dfVideoOk
;
    or ds:switch_flags,PM_FLAG_VIDEO
    mov ax,system_data_sel
    mov ds,ax
    xor eax,eax
    mov ds:efi_acpi,eax
    mov ds:efi_acpi+4,eax
    mov ds:efi_lfb,eax
    mov ds:efi_lfb+4,eax

dfVideoOk:    
    popad
    pop es
    pop ds
    ret
DetectFlags Endp
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitMonData
;
;       DESCRIPTION:    Init monitor data selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitMonData Proc near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax    
    mov ax,flat_sel
    mov es,ax
;    
    call AllocateRam
    call ZeroPage
    push esi
    mov edx,esi
    mov es:[edx].mon_core_count,1
    mov es:[edx].mon_map_linear,map_page_linear
    mov edi,OFFSET mon_core_regs
    add edi,edx
;
    call AllocateRam
    call ZeroPage
    mov eax,esi
    mov es:[edi].mc_core_linear,0    
    mov es:[edi].mc_regs_linear,eax
;
    mov bx,mon_data_sel
    mov edx,ds:switch_gdt
    pop esi
    mov ecx,1000h
    call CreateDataSel32        
;
    popad
    pop es
    pop ds
    ret
InitMonData Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateIntGate
;
;           DESCRIPTION:    Create int gate selector
;
;           PARAMETERS:     AL          INT #
;                           BL          DPL
;                           DS:ESI      ENTRY POINT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntGate     PROC near
    push es
    push ax
    push bx
    push dx
;
    mov dx,idt_sel
    mov es,dx
;
    mov ah,bl
    movzx bx,al
    shl bx,3
    xor al,al
    shl ah,5
    or ah,8Eh
    mov es:[bx+4],ax
    mov es:[bx],esi
    mov ax,ds
    xchg ax,es:[bx+2]
    mov es:[bx+6],ax
;
    pop dx
    pop bx
    pop ax
    pop es
    ret
CreateIntGate     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCallGate
;
;           DESCRIPTION:    Create 32-bit call gate selector
;
;           PARAMETERS:     BX          DESCRIPTOR
;                           DS:ESI      ENTRY POINT
;                           CL          32-BIT WORDS TO MOVE
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateCallGate  PROC near
    push es
    push ax
    push bx
;
    mov ax,gdt_sel
    mov es,ax
;
    mov ah,bl
    and bx,0FFF8h
    mov al,cl
    and al,0Fh
    shl ah,5
    or ah,8Ch
    mov es:[bx+4],ax
    mov es:[bx],esi
    mov ax,ds
    xchg ax,es:[bx+2]
    mov es:[bx+6],ax
;
    pop bx
    pop ax
    pop es
    ret
CreateCallGate  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PRETASKING_GATE0, PRETASKING_GATE4
;
;           DESCRIPTION:    Pretasking gates
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pretask0:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,0
    push ax
    push ds
    ShutDownPreTask

pretask1:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,1
    push ax
    push ds
    ShutDownPreTask

pretask2:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,2
    push ax
    push ds
    ShutDownPreTask

pretask3:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,3
    push ax
    push ds
    ShutDownPreTask

pretask4:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,4
    push ax
    push ds
    ShutDownPreTask

pretask5:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,5
    push ax
    push ds
    ShutDownPreTask

pretask6:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,6
    push ax
    push ds
    ShutDownPreTask

pretask7:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,7
    push ax
    push ds
    ShutDownPreTask

pretask8:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,8
    push ax
    push ds
    ShutDownPreTask

pretask9:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,9
    push ax
    push ds
    ShutDownPreTask

pretask10:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,10
    push ax
    push ds
    ShutDownPreTask

pretask11:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,11
    push ax
    push ds
    ShutDownPreTask

pretask12:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,12
    push ax
    push ds
    ShutDownPreTask

pretask13:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,13
    push ax
    push ds
;    
    test byte ptr [ebp+2].trap_eflags,2
    jnz pretask_gpf_default
;
    mov ds,[ebp].trap_cs
    mov ebx,[ebp].trap_eip
    mov al,[ebx]
;
    cmp al,0CDh
    jne pretask_gpf_not_int
;
    mov al,[ebx+1]
    cmp al,66h
    je pretask_gpf_reexec
;
    cmp al,67h
    je pretask_gpf_reexec
;
    cmp al,9Ah
    je pretask_gpf_reexec
;
    jmp pretask_gpf_default
        
pretask_gpf_not_int:
    cmp al,3Eh
    je pretask_gpf_32
;
    cmp al,67h
    jne pretask_gpf_default

pretask_gpf_16:
    mov al,[ebx+2]
    cmp al,9Ah
    jne pretask_gpf_default
;
    mov ax,[ebx+7]
    or ax,ax
    jz pretask_gpf_default
;
    cmp ax,3
    ja pretask_gpf_default

pretask_kernel_gate16:
    push ecx
    push edx
;    
    push ebx
    mov bx,ds
    call GetSelectorBase
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    mov al,0CDh
    xchg al,ds:[ebx]
    pop edx
    pop ecx
    jmp pretask_gpf_reexec

pretask_gpf_32:
    mov al,[ebx+1]
    cmp al,67h
    jne pretask_gpf_default
;
    mov ax,[ebx+7]
    cmp ax,3
    ja pretask_gpf_default

pretask_kernel_gate32:
    push ecx
    push edx
;    
    push ebx
    mov bx,ds
    call GetSelectorBase
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    mov al,0CDh
    xchg al,ds:[ebx]
    pop edx
    pop ecx
    jmp pretask_gpf_reexec

pretask_gpf_default:
    ShutDownPreTask

pretask_gpf_reexec:
    pop eax
    mov ds,ax
    pop ebx
    pop eax
    and byte ptr [ebp+2].trap_eflags, NOT 1
    pop ebp
    add sp,4
    iretd

prepaging14:
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,14
    push ax
    push ds
    ShutDownPreTask

pretask16:
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
    mov ax,16
    push ax
    push ds
    ShutDownPreTask

;
; tabell offsets
;
ig_nr       EQU 0
ig_entry    EQU 4
ig_sel      EQU 8
ig_dpl      EQU 12


pretask_int_tab:
;
;               int #   Entry                   Selector        Dpl
;
pg0     DD      0,          OFFSET pretask0,        kdebug_code_sel,    0
pg1     DD      1,          OFFSET pretask1,        kdebug_code_sel,    0
pg2     DD      2,          OFFSET pretask2,        kdebug_code_sel,    0
pg3     DD      3,          OFFSET pretask3,        kdebug_code_sel,    0
pg4     DD      4,          OFFSET pretask4,        kdebug_code_sel,    0
pg5     DD      5,          OFFSET pretask5,        kdebug_code_sel,    0
pg6     DD      6,          OFFSET pretask6,        kdebug_code_sel,    0
pg7     DD      7,          OFFSET pretask7,        kdebug_code_sel,    0
pg8     DD      8,          OFFSET pretask8,        kdebug_code_sel,    0
pg9     DD      9,          OFFSET pretask9,        kdebug_code_sel,    0
pg10    DD      10,         OFFSET pretask10,       kdebug_code_sel,    0
pg11    DD      11,         OFFSET pretask11,       kdebug_code_sel,    0
pg12    DD      12,         OFFSET pretask12,       kdebug_code_sel,    0
pg13    DD      13,         OFFSET pretask13,       kdebug_code_sel,    0
pg14    DD      14,         OFFSET prepaging14,     kdebug_code_sel,    0
pg16    DD      16,         OFFSET pretask16,       kdebug_code_sel,    0
pg7_end DD      0FFFFFFFFh

InitBootInts      PROC near
    mov edi,OFFSET pretask_int_tab

ibiLoop:
    mov eax,cs:[edi]
    cmp ax,0FFFFFFFFh
    jz ibiDone
;
    mov ax,cs:[edi].ig_sel
    mov ds,ax
    mov al,cs:[edi].ig_nr
    mov bl,cs:[edi].ig_dpl
    mov esi,cs:[edi].ig_entry
    call CreateIntGate
    add edi,16
    jmp ibiLoop

ibiDone:
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET abort_pretask
    xor cl,cl
    mov bx,shutdown_pretask_gate
    call CreateCallGate
    ret
InitBootInts      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupSwitch
;
;           DESCRIPTION:    Setup switch code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupSwitch     Proc near
    push ds
    pushad
;
    mov ax,SEG data
    mov ds,ax    
    mov eax,ds:switch_linear
    mov edx,eax
    mov al,7
    xor ebx,ebx
    SetPageEntry
;    
    mov edx,ds:switch_linear
    mov ebx,shutdown_code_sel
    mov ecx,0FFFh
    CreateCodeSelector16
;
    popad
    pop ds
    ret
SetupSwitch     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SwitchToMonitor
;
;           DESCRIPTION:    Switch to monitor
;
;           PARAMETERS:     EBP         CPU offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SwitchToMonitor:
    mov ax,SEG data
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    mov edx,ds:switch_linear
    mov ax,ds:switch_flags
    mov es:[edx].pm_flags,ax
;
    mov ax,mon_code_sel
    mov es:[edx].pm_cs,ax
    mov eax,OFFSET StartMonitor
    mov es:[edx].pm_eip,eax
;
    mov ax,mon_flat_sel
    mov es:[edx].pm_ss,ax
    mov eax,1000h
    mov es:[edx].pm_esp,eax
;    
    mov eax,ds:switch_cr3
    mov es:[edx].pm_cr3,eax
;
    mov ax,800h-1
    mov word ptr es:[edx].pm_gdtr,ax
    mov eax,ds:switch_gdt
    mov dword ptr es:[edx+2].pm_gdtr,eax
;
    mov ax,800h-1
    mov word ptr es:[edx].pm_idtr,ax
    mov eax,ds:switch_idt
    mov dword ptr es:[edx+2].pm_idtr,eax
;    
    mov edi,ds:switch_proc
    push ebx
    mov ds,bx
    xor bx,bx
    push edi
    retf
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           init_crash_boot
;
;       DESCRIPTION:    Boot time initialization
;
;       PARAMETERS:     EDI     Offset to switch procedure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_crash_boot
    
init_crash_boot   Proc near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov ds:switch_proc,edi
    call DetectFlags
;    
    call AllocateRam
    mov ds:switch_linear,esi    
    mov edi,esi
;
    mov bx,shutdown_code_sel
    call GetSelectorBase
    mov esi,edx
;
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
    mov ecx,400h
    rep movs dword ptr es:[edi],ds:[esi]    
;
    mov ax,SEG data
    mov ds,ax
;
    mov bx,cs
    call GetSelectorBase
    mov ds:switch_base,edx
    mov ds:switch_size,ecx
;
    call AllocateRam
    call ZeroPage
    mov ds:switch_gdt,esi
    add esi,800h
    mov ds:switch_idt,esi
;    
    mov edx,ds:switch_idt
    call InitMonitorIdt
;
    mov si,system_data_sel
    mov di,mon_system_data_sel
    call MoveSel
;
    call InitMonData
;    
    call AllocateRam
    call ZeroPage
    mov ds:switch_cr3,esi    
    mov ds:pae_low,0
;
    mov ax,ds:switch_flags
    test ax,PM_FLAG_PAE
    jz icbProt

icbPae:
    call AllocateRam
    call ZeroPage
    mov ds:pae_low,esi
;
    call AllocateRam
    mov ds:switch_low,esi
    call MapLowPae
    call MapPae
;
    mov edx,ds:switch_gdt
    mov esi,ds:switch_base
    and esi,0FFFh
    add esi,code_page_linear
    mov ecx,ds:switch_size
    mov edi,ds:switch_low
    call InitMonitorGdt
    jmp icbDone

icbProt:
    call AllocateRam
    mov ds:switch_low,esi
    call MapLowProt
    call MapProt
;
    mov edx,ds:switch_gdt
    mov esi,ds:switch_base
    and esi,0FFFh
    add esi,code_page_linear
    mov ecx,ds:switch_size
    mov edi,ds:switch_low
    call InitMonitorGdt

icbDone:
    popad
    pop es
    pop ds    
    ret
init_crash_boot   Endp
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           check_boot
;
;       DESCRIPTION:    Check boot time init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public check_boot
    
check_boot:
    int 3   
    call SetupSwitch
    CrashGate
    call InitBootInts
    int 3
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           abort_pretask
;
;       DESCRIPTION:    Abort pretask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

abort_pretask:
    jmp SwitchToMonitor
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddCrashThread
;
;       DESCRIPTION:    Add crash thread
;
;       PARAMETERS:     FS      Core selector
;                       BX      Thread
;                       GS:EDI  Info buffer
;                       AX      State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddCrashThread   Proc near
    push es
    pushad
;    
    mov cx,gs:[edi].cls_threads
    cmp cx,MAX_LOG_THREADS
    jae actDone
;
    inc gs:[edi].cls_threads
    push ax
    mov ax,SIZE core_log_thread_struc
    mul cx
    add ax,OFFSET cls_thread_arr
    movzx eax,ax
    add edi,eax
    pop ax
;
    mov gs:[edi].clt_sel,bx
    mov gs:[edi].clt_state,ax
    mov es,bx
    mov ax,es:p_prio
    shr ax,1
    mov gs:[edi].clt_prio,ax
    mov ax,es:p_core
    mov gs:[edi].clt_core,ax
    mov ax,es:p_wanted_core
    mov gs:[edi].clt_wanted_core,ax
;
    mov ecx,8
    mov esi,OFFSET thread_name
    add edi,OFFSET clt_name

actLoop:
    mov eax,es:[esi]
    mov gs:[edi],eax
    add esi,4
    add edi,4
    loop actLoop    

actDone:
    popad
    pop es
    ret
AddCrashThread Endp

   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddCrashThreadList
;
;       DESCRIPTION:    Add crash thread list
;
;       PARAMETERS:     FS      Core selector
;                       SI      Thread list
;                       GS:EDI  Info buffer
;                       AX      State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddCrashThreadList   Proc near
    push es
    push bx
    push dx
;    
    mov bx,fs:[si]
    or bx,bx
    jz actlDone
;
    mov dx,bx

actlMore:    
    call AddCrashThread  
    mov es,bx
    mov bx,es:p_next
    cmp bx,dx
    jne actlMore  

actlDone:
    pop dx
    pop bx
    pop es
    ret
AddCrashThreadList Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddCrashSeg
;
;       DESCRIPTION:    Add crash segment
;
;       PARAMETERS:     FS      Core selector
;                       BX      Selector
;                       GS:EDI  Info buffer
;                       EAX     Selector offset
;                       DS:EBP  Register state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddCrashSeg   Proc near
    push es
    pushad
;    
    add edi,eax
    mov ds:[edi].clss_sel,bx
    mov ds:[edi].clss_flags,0
;    
    and bx,NOT 3
    or bx,bx
    jz acsDone
;
    test bx,4
    jz acsGdt

acsLdt:
    mov ecx,ds:[ebp].reg_ldt.d_limit
    mov edx,ds:[ebp].reg_ldt.d_base
    jmp acsDo

acsGdt:
    mov ecx,ds:[ebp].reg_gdt.d_limit
    mov edx,ds:[ebp].reg_gdt.d_base

acsDo:
    and bx,0FFF8h
    cmp bx,cx
    ja acsDone
;
    mov ax,flat_sel
    mov es,ax
    movzx ebx,bx
    add ebx,edx
;
    mov al,es:[ebx+5]
    movzx ax,al
    mov gs:[edi].clss_flags,ax
;
    test al,80h
    jz acsDone
;
    xor ecx,ecx
    mov cl,es:[ebx+6]
    and cl,0Fh
    shl ecx,16
    mov cx,es:[ebx]
    test byte ptr es:[ebx+6],80h
    jz acsSmall
;
    shl ecx,12
    or cx,0FFFh

acsSmall:
    mov edx,es:[ebx+2]
    rol edx,8
    mov dl,es:[ebx+7]
    ror edx,8
;
    mov gs:[edi].clss_base,edx
    mov gs:[edi].clss_size,ecx

acsDone:
    popad
    pop es
    ret
AddCrashSeg Endp
    
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddToCrashLog
;
;       DESCRIPTION:    Add dumped data to crash log
;
;       PARAMETERS:     FS      Core selector
;                       DS:EBP  Registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddToCrashLog   Proc near
    push es
    push gs
;
    mov si,fs:ps_dump_offset
    or si,si
    jz aclDone
;
    mov ax,core_image_sel
    mov gs,ax
    mov edi,gs:[si]
    mov ax,flat_sel
    mov gs,ax
;
    mov gs:[edi].cls_threads,0
    mov ax,fs
    mov gs:[edi].cls_core,ax


    mov eax,ds:[ebp].curr_irq
    mov gs:[edi].cls_irq,eax
;
    movzx eax,ds:[ebp].fault_vect
    mov gs:[edi].cls_fault,eax
;    
    mov eax,ds:[ebp].reg_cr0
    mov gs:[edi].cls_cr0,eax
;    
    mov eax,ds:[ebp].reg_cr2
    mov gs:[edi].cls_cr2,eax
;
    mov eax,ds:[ebp].reg_cr3
    mov gs:[edi].cls_cr3,eax
;
    mov eax,ds:[ebp].reg_cr4
    mov gs:[edi].cls_cr4,eax
;
    mov eax,ds:[ebp].reg_dr0
    mov gs:[edi].cls_dr0,eax
;
    mov eax,ds:[ebp].reg_dr1
    mov gs:[edi].cls_dr1,eax
;
    mov eax,ds:[ebp].reg_dr2
    mov gs:[edi].cls_dr2,eax
;
    mov eax,ds:[ebp].reg_dr3
    mov gs:[edi].cls_dr3,eax
;
    mov eax,ds:[ebp].reg_dr7
    mov gs:[edi].cls_dr7,eax
;
    mov eax,ds:[ebp].reg_eip
    mov dword ptr gs:[edi].cls_rip,eax
;
    mov eax,ds:[ebp].reg_eflags
    mov dword ptr gs:[edi].cls_rflags,eax
;
    mov eax,ds:[ebp].reg_eax
    mov dword ptr gs:[edi].cls_rax,eax
;
    mov eax,ds:[ebp].reg_ecx
    mov dword ptr gs:[edi].cls_rcx,eax
;
    mov eax,ds:[ebp].reg_edx
    mov dword ptr gs:[edi].cls_rdx,eax
;
    mov eax,ds:[ebp].reg_ebx
    mov dword ptr gs:[edi].cls_rbx,eax
;
    mov eax,ds:[ebp].reg_esp
    mov dword ptr gs:[edi].cls_rsp,eax
;
    mov eax,ds:[ebp].reg_ebp
    mov dword ptr gs:[edi].cls_rbp,eax
;
    mov eax,ds:[ebp].reg_esi
    mov dword ptr gs:[edi].cls_rsi,eax
;
    mov eax,ds:[ebp].reg_edi
    mov dword ptr gs:[edi].cls_rdi,eax
;
    mov ax,fs:ps_nesting
    mov gs:[edi].cls_nesting,ax
;
    mov bx,ds:[ebp].reg_es.d_selector
    mov eax,OFFSET cls_es
    call AddCrashSeg
;
    mov bx,ds:[ebp].reg_cs.d_selector
    mov eax,OFFSET cls_cs
    call AddCrashSeg
;
    mov bx,ds:[ebp].reg_ss.d_selector
    mov eax,OFFSET cls_ss
    call AddCrashSeg
;
    mov bx,ds:[ebp].reg_ds.d_selector
    mov eax,OFFSET cls_ds
    call AddCrashSeg
;
    mov bx,ds:[ebp].reg_fs.d_selector
    mov eax,OFFSET cls_fs
    call AddCrashSeg
;
    mov bx,ds:[ebp].reg_gs.d_selector
    mov eax,OFFSET cls_gs
    call AddCrashSeg
;
    mov bx,ds:[ebp].reg_ldt.d_selector
    mov eax,OFFSET cls_ldt
    call AddCrashSeg
;
    mov bx,ds:[ebp].reg_tr.d_selector
    mov eax,OFFSET cls_tr
    call AddCrashSeg
;
    mov ecx,ds:[ebp].reg_gdt.d_limit
    mov gs:[edi].cls_gdtr.clss_size,ecx
;
    mov edx,ds:[ebp].reg_gdt.d_base
    mov gs:[edi].cls_gdtr.clss_base,edx
;
    mov ecx,ds:[ebp].reg_idt.d_limit
    mov gs:[edi].cls_idtr.clss_size,ecx
;
    mov edx,ds:[ebp].reg_idt.d_base
    mov gs:[edi].cls_idtr.clss_base,edx
;
    mov bx,fs:ps_curr_thread
    or bx,bx
    jz aclNoCurr
;
    mov ax,LOG_CORE_THREAD_RUNNING
    call AddCrashThread
        
aclNoCurr:
    mov ax,LOG_CORE_THREAD_WAKEUP
    mov si,OFFSET ps_wakeup_list
    call AddCrashThreadList
;
    mov ax,LOG_CORE_THREAD_READY
    mov cx,256
    mov si,OFFSET ps_ptab

aclReadyLoop:
    call AddCrashThreadList
    add si,2
    loop aclReadyLoop
;
    mov ecx,gs:[edi].cls_ss.clss_size
    cmp ecx,0FFFh
    jne aclStackDone
;    
    push ds
    push es
    push esi
    push edi
;    
    mov ax,gs
    mov es,ax
    mov ds,ds:[ebp].reg_ss.d_selector
    xor esi,esi
    mov ecx,400h
    add edi,CORE_IMAGE_STACK_OFFSET
    rep movs dword ptr es:[edi],ds:[esi]
;
    pop edi
    pop esi
    pop es
    pop ds
    
aclStackDone:
    mov cx,fs:ps_log_count
    cmp cx,PROC_LOG_ENTRIES    
    jb aclLogFew

aclLogMany:
    mov fs:ps_log_count,PROC_LOG_ENTRIES
    jmp aclLogProcess

aclLogFew:
    mov fs:ps_log_entry,0    

aclLogProcess:
    mov cx,fs:ps_log_count
    or cx,cx
    jz aclLogDone
;
    cmp cx,PROC_LOG_ENTRIES
    jbe aclLogSizeOk
;
    mov cx,200h

aclLogSizeOk:    
    push ds
    push es
    push esi
    push edi
;
    mov ax,gs
    mov es,ax
    mov ds,fs:ps_log_sel
    mov bx,fs:ps_log_entry
    add edi,CORE_IMAGE_LOG_OFFSET

aclLogLoop:    
    movzx esi,bx
    shl esi,4
    push ecx
    mov ecx,4
    rep movs dword ptr es:[edi],ds:[esi]
    pop ecx
;
    inc bx
    cmp bx,PROC_LOG_ENTRIES
    jne aclLogNext
;
    xor bx,bx

aclLogNext:
    loop aclLogLoop
;
    pop edi
    pop esi
    pop es
    pop ds        

aclLogDone:    
    mov gs:[edi].cls_sign,LOG_CORE_SIGN
;
    mov bx,core_save_sel
    mov ds,bx
    mov ds:sc_sign,SAVE_CORE_SIGN
        
aclDone:        
    pop gs
    pop es
    ret
AddToCrashLog   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupBiosPic
;
;           DESCRIPTION:    Setup PIC to operate in BIOS-compatible mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupBiosPic    Proc near
    mov al,11h
    out 20h,al
    jmp short $+2
;
    mov al,8
    out 21h,al
    jmp short $+2
;
    mov al,04h
    out 21h,al
    jmp short $+2
;
    mov al,0C1h
    out 20h,AL
    jmp short $+2
;
    mov al,1
    out 21h,al
    jmp short $+2
;
    mov al,11h
    out 0A0h,al
    jmp short $+2
;
    mov al,70h
    out 0A1h,al
    jmp short $+2
;
    mov al,2
    out 0A1h,al
    jmp short $+2
;
    mov al,1
    out 0A1h,al
    jmp short $+2
;
    mov al,-1
    out 21h,al
;
    mov al,-1
    out 0A1h,al
    jmp short $+2
    ret
SetupBiosPic    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupBiosPit
;
;           DESCRIPTION:    Setup PIT to operate in BIOS-compatible mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupBiosPit    Proc near
    mov al,30h
    out 43h,al
    jmp short $+2
;
    mov al,-1
    out 40h,al
    jmp short $+2
;
    mov al,-1
    out 40h,al
    jmp short $+2    
    ret
SetupBiosPit    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartCoreDump
;
;           DESCRIPTION:    Start core dump
;
;           RETURNS:        NC
;                               DS:EBP  Cpu registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_core_dump_name    DB 'Start Core Dump', 0
    
start_core_dump Proc far
    push fs
    push eax
    push ebx
    push edx
;   
    GetCore
    test fs:ps_flags,PS_FLAG_NMI
    jnz scdFail
;
    lock or fs:ps_flags,PS_FLAG_NMI    
;
    mov ax,SEG data
    mov ds,ax
    mov edx,ds:mon_linear
    or edx,edx
    jz scdFail
;
    mov ax,flat_sel
    mov ds,ax
    mov bx,fs:ps_id
    cmp bx,ds:[edx].mon_core_count
    jae scdFail
;
    movzx ebx,bx
    shl ebx,3
    add ebx,OFFSET mon_core_regs
    mov ebp,ds:[ebx+edx].mc_regs_linear
    clc
    jmp scdDone

scdFail:
    stc

scdDone:
    pop edx
    pop ebx
    pop eax
    pop fs
    ret
start_core_dump Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendStopAndWait
;
;           DESCRIPTION:    Send NMI to single core and wait
;
;           PARAMETERS:     DS:EBP      Cpu registers
;                           FS          Core sel
;                           ECX         Check count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendStopAndWait       Proc near
    test fs:ps_flags,PS_FLAG_NMI
    jnz swCheck
;        
    SendNmi
        
swCheck:
    test fs:ps_flags,PS_FLAG_SAVED
    jnz swDone
;
    loop swCheck

swDone:        
    ret
SendStopAndWait    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendIntToAll
;
;           DESCRIPTION:    Send int 2 to all
;
;           PARAMETERS:     DS:EBP      Cpu registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendIntToAll       Proc near
    xor ax,ax

sitLoop:    
    GetCoreNumber
    jc sitDone
;
    test fs:ps_flags,PS_FLAG_NMI
    jnz sitNext
;        
    push ax
    mov al,2
    SendInt
    pop ax
        
sitNext:
    inc ax
    jmp sitLoop

sitDone:
    ret
SendIntToAll    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendNmiToAll
;
;           DESCRIPTION:    Send NMI to all
;
;           PARAMETERS:     DS:EBP      Cpu registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendNmiToAll       Proc near
    xor ax,ax

sntLoop:    
    GetCoreNumber
    jc sntDone
;
    test fs:ps_flags,PS_FLAG_NMI
    jnz sntNext
;        
    SendNmi
        
sntNext:
    inc ax
    jmp sntLoop

sntDone:
    ret
SendNmiToAll    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitSaved
;
;           DESCRIPTION:    Wait for saved states
;
;           PARAMETERS:     DS:EBP      Cpu registers
;                           ECX         Attempts
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitSaved       Proc near

wsLoop:    
    xor dx,dx
    xor ax,ax

wsCoreLoop:
    GetCoreNumber
    jc wsValidate
;
    test fs:ps_flags,PS_FLAG_SAVED
    jnz wsCoreNext
;        
    inc dx
        
wsCoreNext:
    inc ax
    jmp wsCoreLoop

wsValidate:
    or dx,dx
    clc
    jz wsDone   
;
    loop wsLoop    
;
    stc

wsDone:
    ret
WaitSaved       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyCoreDump
;
;           DESCRIPTION:    Notify core dump
;
;           PARAMETERS:     DS:EBP      Cpu registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_core_dump_name    DB 'Notify Core Dump', 0
    
notify_core_dump:
    GetCore
    mov ds:[ebp].debug_core_sel,fs
    mov ax,fs:ps_id
    mov ds:[ebp].debug_core_id,ax
;
    mov eax,cr0
    mov ds:[ebp].reg_cr0,eax
;
    mov eax,cr2
    mov ds:[ebp].reg_cr2,eax
;
    mov eax,cr3
    mov ds:[ebp].reg_cr3,eax
;
    mov eax,cr4
    mov ds:[ebp].reg_cr4,eax
;
    mov eax,dr0
    mov ds:[ebp].reg_dr0,eax               
;
    mov eax,dr1
    mov ds:[ebp].reg_dr1,eax               
;
    mov eax,dr2
    mov ds:[ebp].reg_dr2,eax               
;
    mov eax,dr6
    mov ds:[ebp].reg_dr6,eax               
;
    mov eax,dr7
    mov ds:[ebp].reg_dr7,eax               
;
    mov eax,dr0
    mov ds:[ebp].reg_dr0,eax               
;
    sgdt fword ptr ds:[ebp].temp_size
    movzx eax,ds:[ebp].temp_size
    mov ds:[ebp].reg_gdt.d_limit,eax
    mov eax,ds:[ebp].temp_base
    mov ds:[ebp].reg_gdt.d_base,eax
;
    sidt fword ptr ds:[ebp].temp_size
    movzx eax,ds:[ebp].temp_size
    mov ds:[ebp].reg_idt.d_limit,eax
    mov eax,ds:[ebp].temp_base
    mov ds:[ebp].reg_idt.d_base,eax
;    
    mov ds:[ebp].reg_ldt.d_limit,0
    mov ds:[ebp].reg_ldt.d_base,0
;    
    mov ds:[ebp].reg_tr.d_limit,0
    mov ds:[ebp].reg_tr.d_base,0
    mov ds:[ebp].reg_efer,0
    lock or ds:[ebp].debug_flags,DEBUG_FLAG_VALID
    call AddToCrashLog
    lock or fs:ps_flags,PS_FLAG_SAVED
;    
    mov ax,system_data_sel
    mov es,ax

smSpin:
    mov ax,1
    xchg ax,es:shut_spinlock
    or ax,ax
    jz smEnter

smWait:
    hlt
    jmp smWait

smEnter:
    mov ax,SEG data
    mov gs,ax
;
    test fs:ps_flags,PS_FLAG_LONG_MODE
    jz smProtMode
;
    mov ds:[ebp].reg_efer,EFER_LME
    mov eax,ds:mon_cr3
    SwitchToProtectedMode
    jmp smModeOk

smProtMode:
    mov eax,gs:mon_cr3
    mov cr3,eax

smModeOk:    
    DisableAllIrq
    SetupNmiCoreDump
    SetupLongNmiCoreDump
;
    xor ax,ax

smStopLoop:    
    GetCoreNumber
    jc smStopDone
;
    mov ecx,1000000h
    call SendStopAndWait
    inc ax
    jmp smStopLoop

smStopDone:
    mov ecx,1000h
    call WaitSaved
    jnc smSavedOk
;    
    call SendIntToAll
    mov ecx,1000h
    call WaitSaved
    jnc smSavedOk
;
    call SendNmiToAll
    mov ecx,100000h
    call WaitSaved

smSavedOk:
    mov ax,wd_code_sel
    verr ax
    jnz smMonitor
;
    FaultReset
;    
    mov ecx,100000h

smWaitReset:
    loop smWaitReset
;    
    SoftReset
    jmp smWaitReset

smMonitor:
    mov eax,es:efi_lfb
    or eax,es:efi_lfb+4
    jnz smVideoOk
;
    call SetupBiosPic
    call SetupBiosPit
    InitVideo
        
smVideoOk:    
    jmp start_monitor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setup_crash
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_crash     Proc near
    mov ax,flat_sel
    mov es,ax    
;
    mov eax,1000h
    AllocateBigLinear
;
    mov ecx,400h
    xor eax,eax
    mov edi,edx
    rep stosd
;
    GetCoreCount
    movzx ecx,cx
    mov es:[edx].mon_core_count,cx
    xor si,si
;
    push edx
    mov edi,OFFSET mon_core_regs
    add edi,edx

scCoreLoop:    
    push ecx
    mov es:[edi].mc_core_linear,0    
    mov es:[edi].mc_regs_linear,0    
    mov ax,si
    GetCoreNumber
    jc scCoreNext
;
    mov bx,fs
    GetSelectorBaseSize
    mov es:[edi].mc_core_linear,edx
;
    mov eax,SIZE cpu_struc
    AllocateBigLinear    
;
    push edi
    mov ecx,400h
    xor eax,eax
    mov edi,edx
    rep stosd
    pop edi
;
    mov es:[edi].mc_regs_linear,edx

scCoreNext:
    pop ecx
    add edi,8
    inc si
    loop scCoreLoop
;    
    pop edi
    mov eax,1000h
    AllocateBigLinear
    mov es:[edi].mon_map_linear,edx
;   
    mov ax,SEG data
    mov ds,ax
    mov ds:mon_linear,edi
;     
    mov edx,edi
    mov ecx,1000h
    call set_monitor_data
    ret
setup_crash     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           create_gdt
;
;           DESCRIPTION:    Create new GDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_gdt     Proc near
    mov eax,1000h
    AllocateBigLinear
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stosd
;
    mov ax,gdt_sel
    mov ds,ax
;
    mov esi,cs
    mov edi,mon_code_sel
    mov eax,ds:[esi]
    mov es:[edx+edi],eax
    mov eax,ds:[esi+4]
    mov es:[edx+edi+4],eax
;
    mov esi,flat_sel
    mov edi,mon_flat_sel
    mov eax,ds:[esi]
    mov es:[edx+edi],eax
    mov eax,ds:[esi+4]
    mov es:[edx+edi+4],eax
;
    mov esi,system_data_sel
    mov edi,mon_system_data_sel
    mov eax,ds:[esi]
    mov es:[edx+edi],eax
    mov eax,ds:[esi+4]
    mov es:[edx+edi+4],eax
;
    mov esi,shutdown_code_sel
    mov edi,mon_shutdown_code_sel
    mov eax,ds:[esi]
    mov es:[edx+edi],eax
    mov eax,ds:[esi+4]
    mov es:[edx+edi+4],eax
;
    mov esi,shutdown_pretask_gate
    mov edi,mon_shutdown_gate_sel
    mov eax,ds:[esi]
    mov es:[edx+edi],eax
    mov eax,ds:[esi+4]
    mov es:[edx+edi+4],eax
;
    mov esi,process_page_sel
    mov edi,mon_process_page_sel
    mov eax,ds:[esi]
    mov es:[edx+edi],eax
    mov eax,ds:[esi+4]
    mov es:[edx+edi+4],eax
;
    mov esi,dosB800
    mov edi,mon_text_sel
    mov eax,ds:[esi]
    mov es:[edx+edi],eax
    mov eax,ds:[esi+4]
    mov es:[edx+edi+4],eax
    mov ecx,1000h
    ret
create_gdt      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           create_idt
;
;           DESCRIPTION:    Create new IDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_idt     Proc near
    mov eax,1000h
    AllocateBigLinear
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stosd
    mov ecx,800h
    ret
create_idt  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_crash_tasking
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_crash_tasking

init_crash_tasking    Proc near
    push ds
    pushad
;
    call setup_crash
    call create_gdt
    call set_monitor_gdt
    call create_idt
    call set_monitor_idt    
;        
    popad
    pop ds
    ret
init_crash_tasking    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          init_crash_driver
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_crash_driver

init_crash_driver    Proc near
    mov ax,SEG data
    mov ds,ax
    mov ds:map_spinlock,0
    mov ds:mon_linear,0
    mov eax,cr3
    mov ds:mon_cr3,eax
;
    mov eax,1000h
    AllocateBigLinear
    mov ds:map_linear,edx    
    xor ebx,ebx
    mov eax,7
    SetPageEntry
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov esi,OFFSET start_core_dump
    mov edi,OFFSET start_core_dump_name
    xor cl,cl
    mov ax,start_core_dump_nr
    RegisterOsGate
;    
    mov esi,OFFSET notify_core_dump
    mov edi,OFFSET notify_core_dump_name
    xor cl,cl
    mov ax,notify_core_dump_nr
    RegisterOsGate
    ret
init_crash_driver       Endp

code    ENDS

    END
