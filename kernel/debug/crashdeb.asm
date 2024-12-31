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
INCLUDE ..\os\core.inc
INCLUDE ..\pcdev\key.inc
INCLUDE ..\pcdev\apic.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\gate.def
INCLUDE kdebug.inc

code_page_linear  = 100000h
usb_page_linear   = 1E0000h
map_page_linear   = 1FF000h
lfb_page_linear   = 0C0000000h

data    SEGMENT byte public 'DATA'

map_linear        DD ?
mon_linear        DD ?
mon_cr3           DD ?

mon_alloc_base    DD ?
page_low_linear   DD ?
switch_proc       DD ?
switch_linear     DD ?
switch_flags      DW ?
switch_base       DD ?
switch_size       DD ?
switch_cr3        DD ?
switch_low        DD ?
pae_low           DD ?
switch_gdt        DD ?
switch_idt        DD ?
mon_data_linear   DD ?
sys_data_linear   DD ?

data    ENDS

    .686p

code    SEGMENT byte public use32 'CODE'

    assume cs:code

    extrn InitMonitorIdt:near
    extrn InitMonitorGdt:near
    extrn StartMonitor:near
    extrn CreateDataSel32:near

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
;           NAME:           CreateDataSel16
;
;           DESCRIPTION:    Create 16-bit data selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDataSel16       PROC near
    push ds
    push ax
    push bx
    push ecx
;
    mov ax,gdt_sel
    mov ds,ax
;
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae cdsBig
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    mov [bx+6],cx
    jmp cdsDone

cdsBig:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,80h
    mov [bx+6],cx

cdsDone:
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
CreateDataSel16       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCodeSel16
;
;           DESCRIPTION:    Create 16-bit code selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateCodeSel16       PROC near
    push ds
    push ax
    push bx
    push ecx
;    
    mov ax,gdt_sel
    mov ds,ax
;
    mov al,bl
    and bx,0FFF8h
    dec ecx
    cmp ecx,100000h
    jae ccsBig
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    mov [bx+6],cx
    jmp ccsDone

ccsBig:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,80h
    mov [bx+6],cx

ccsDone:
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
CreateCodeSel16       ENDP
    
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
;
    mov ax,SEG data
    mov ds,ax
    mov ds:mon_alloc_base,esi
;        
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
    mov eax,3

mlProtUnityLoop:
    mov ds:[ebx],eax
    add ebx,4
    add eax,1000h
    loop mlProtUnityLoop
;
    mov ecx,100h
    mov eax,esi
    and ax,0F000h
    mov al,3

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
;           NAME:           MapLfbProt
;
;           DESCRIPTION:    Map LFB, protected mode paging
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapLfbProt  PROC near
    push ds
    push es
    pushad
;
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:efi_acpi
    or eax,ds:efi_acpi+4
    jz meProtDone
;
    mov ax,SEG data
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;
    mov edi,ds:switch_cr3
    add edi,0C00h
;
    mov ax,system_data_sel
    mov ds,ax
;    
    movzx eax,ds:efi_height
    mov edx,ds:efi_scan_size
    mul edx
    dec eax
    shr eax,12
    inc eax
    mov ecx,eax
    or ecx,ecx
    jz meProtDone
;    
    call AllocateRam
    call ZeroPage
;
    mov eax,esi
    mov al,3
    mov es:[edi],eax
    add edi,4
;
    mov eax,ds:efi_lfb
    or al,3
        
meProtLoop:    
    mov es:[esi],eax
    add esi,4
;
    test si,0FFFh
    jnz meProtNext
;
    push eax
;        
    call AllocateRam
    call ZeroPage
;
    mov eax,esi
    mov al,3
    mov es:[edi],eax
    add edi,4
;
    pop eax

meProtNext:
    add eax,1000h
    loop meProtLoop

meProtDone:
    popad
    pop es
    pop ds        
    ret
MapLfbProt    Endp

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
    mov eax,3
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
    mov al,3

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
;           NAME:           MapLfbPae
;
;           DESCRIPTION:    Map LFB, PAE paging
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapLfbPae  PROC near
    push ds
    push es
    pushad
;
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:efi_acpi
    or eax,ds:efi_acpi+4
    jz mePaeDone
;
    mov ax,SEG data
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;    
    call AllocateRam
    call ZeroPage
;
    mov edi,esi
    mov eax,esi
    xor ebx,ebx
    mov al,1
    mov esi,ds:switch_cr3
    mov es:[esi+24],eax
    mov es:[esi+28],ebx
;    
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:efi_lfb
    test eax,1FFFFFh
    jnz mePaeSmallPages

mePaeBigPages:
    movzx eax,ds:efi_height
    mov edx,ds:efi_scan_size
    mul edx
    dec eax
    shr eax,21
    inc eax
    mov ecx,eax
    or ecx,ecx
    jz mePaeDone
;
    mov eax,ds:efi_lfb
    mov edx,ds:efi_lfb+4
    or al,83h

mePaeBigLoop:    
    mov es:[edi],eax
    add edi,4
;
    mov es:[edi],edx
    add edi,4
;
    add eax,200000h    
    adc edx,0
    loop mePaeBigLoop
;
    jmp mePaeDone
    
mePaeSmallPages:    
    movzx eax,ds:efi_height
    mov edx,ds:efi_scan_size
    mul edx
    dec eax
    shr eax,12
    inc eax
    mov ecx,eax
    or ecx,ecx
    jz mePaeDone
;    
    call AllocateRam
    call ZeroPage
;
    mov eax,esi
    xor ebx,ebx
    mov al,3
    mov es:[edi],eax
    add edi,4
    mov es:[edi],ebx
    add edi,4
;
    mov eax,ds:efi_lfb
    mov edx,ds:efi_lfb+4
    or al,3
        
mePaeLoop:    
    mov es:[esi],eax
    add esi,4
;
    mov es:[esi],edx
    add esi,4
;
    test si,0FFFh
    jnz mePaeNext
;
    push eax
    push edx
;        
    call AllocateRam
    call ZeroPage
;
    mov eax,esi
    xor ebx,ebx
    mov al,3
    mov es:[edi],eax
    add edi,4
    mov es:[edi],ebx
    add edi,4
;
    pop edx
    pop eax

mePaeNext:
    add eax,1000h
    adc edx,0
    loop mePaeLoop

mePaeDone:
    popad
    pop es
    pop ds        
    ret
MapLfbPae    Endp

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
    mov al,3
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
    mov al,1
    xor edx,edx
    mov es:[ebx],eax
    mov es:[ebx+4],edx
;
    mov ebx,ds:pae_low
    mov eax,ds:switch_low
    mov al,3
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
    mov ax,system_data_sel
    mov ds,ax
    mov ds:mon_fixed_lfb,0
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
    or ds:switch_flags,PM_FLAG_PAE

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
    jz dfVideoAcpi
;
    or ds:switch_flags,PM_FLAG_VIDEO
    mov ax,system_data_sel
    mov ds,ax
    xor eax,eax
    mov ds:efi_acpi,eax
    mov ds:efi_acpi+4,eax
    mov ds:efi_lfb,eax
    mov ds:efi_lfb+4,eax
    jmp dfVideoOk

dfVideoAcpi:
    mov ax,system_data_sel
    mov ds,ax
    mov ds:mon_fixed_lfb,lfb_linear

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
    mov ds:mon_data_linear,esi
    mov ds:sys_data_linear,0
    push esi
    mov edx,esi
    mov es:[edx].mon_core_count,1
    mov es:[edx].mon_map_linear,map_page_linear
    mov es:[edx].mon_usb_func_linear,usb_page_linear
    mov edi,OFFSET mon_core_regs
    add edi,edx
;
    call AllocateRam
    call ZeroPage
    mov eax,esi
    mov es:[edi].mc_mon_linear,eax
    mov es:[edi].mc_sys_linear,eax
;
    call AllocateRam
    call ZeroPage
    mov es:[edx].mon_usb_linear,esi
;
    mov bx,mon_data_sel
    mov edx,ds:switch_gdt
    pop esi
    mov ecx,1000h
    call CreateDataSel32        
;
    call AllocateRam
    call ZeroPage
    mov bx,mon_deb_sel
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
    mov ds:mon_cr3,0
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
    call MapLfbPae
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
    call MapLfbProt
;
    mov edx,ds:switch_gdt
    mov esi,ds:switch_base
    and esi,0FFFh
    add esi,code_page_linear
    mov ecx,ds:switch_size
    mov edi,ds:switch_low
    call InitMonitorGdt

icbDone:
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET abort_pretask
    xor cl,cl
    mov bx,shutdown_pretask_gate
    call CreateCallGate
;    
    mov ax,SEG data
    mov ds,ax
    mov edx,ds:switch_linear
    mov ebx,shutdown_code_sel
    mov ecx,1000h
    call CreateCodeSel16
;    
    popad
    pop es
    pop ds    
    ret
init_crash_boot   Endp
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AliasBootPage
;
;       DESCRIPTION:    Alias boot page
;
;       PARAMETERS:     EAX     Physical address
;
;       RETURNS:        EDX     Aliased address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AliasBootPage Proc near
    push ebx
;    
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;    
    xor ebx,ebx
    mov al,3
    SetPageEntry
;
    pop ebx    
    ret
AliasBootPage Endp
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateDualPage
;
;       DESCRIPTION:    Alias page for monitor and system
;
;       RETURNS:        EAX     Monitor address
;                       EDX     System address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateDualPage Proc near
    push ds
    push es
    push ebx
    push esi
    push edi
;
    mov eax,1000h
    AllocateBigLinear
    mov esi,edx
    call ZeroPage
;
    mov ax,SEG data
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;    
    mov esi,ds:mon_alloc_base
    add esi,1000h
    mov ds:mon_alloc_base,esi
;    
    mov edi,ds:page_low_linear
    mov ax,ds:switch_flags
    test ax,PM_FLAG_PAE
    jz adpProt

adpPae:
    mov eax,esi
    shr eax,9
    add edi,eax
    GetPageEntry
;
    mov es:[edi],eax
    mov es:[edi+4],ebx
    jmp adpDone

adpProt:
    mov eax,esi
    shr eax,10
    add edi,eax
    GetPageEntry
;
    mov es:[edi],eax    

adpDone:
    mov eax,esi
;
    pop edi
    pop esi    
    pop ebx    
    pop es
    pop ds
    ret
AllocateDualPage Endp
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateMonData
;
;       DESCRIPTION:    Update monitor data selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMonData Proc near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax    
    mov ax,flat_sel
    mov es,ax
;    
    mov eax,ds:switch_low
    call AliasBootPage    
    mov ds:page_low_linear,edx
;    
    mov eax,ds:mon_data_linear
    call AliasBootPage
    mov ds:sys_data_linear,edx
    mov esi,edx
;     
    mov edi,OFFSET mon_core_regs
    add edi,edx
    mov eax,es:[edi].mc_mon_linear
    call AliasBootPage
    mov es:[edi].mc_sys_linear,edx
;
    GetCoreCount
    movzx ecx,cx
    mov es:[esi].mon_core_count,cx
    sub ecx,1
    jz umdDone
;    
    mov si,1
    add edi,8

umdCoreLoop:    
    push ecx
    mov es:[edi].mc_mon_linear,0    
    mov es:[edi].mc_sys_linear,0    
    mov ax,si
    GetCoreNumber
    jc umdCoreNext
;
    call AllocateDualPage
    mov es:[edi].mc_mon_linear,eax
    mov es:[edi].mc_sys_linear,edx

umdCoreNext:
    pop ecx
    add edi,8
    inc si
    loop umdCoreLoop

umdDone:
    popad
    pop es
    pop ds
    ret
UpdateMonData Endp

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
    mov al,7
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
    mov ebx,shutdown_code_sel
    mov edi,ds:switch_proc
    push ebx
    mov ds,bx
    xor bx,bx
    push edi
    retf
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           abort_pretask
;
;       DESCRIPTION:    Abort pretask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

abort_pretask:
    mov bx,system_data_sel
    mov ds,bx
    mov ebx,ds:efi_acpi
    or ebx,ds:efi_acpi+4
    jz apLfbDone
;
    mov ds:efi_lfb,lfb_page_linear    
    mov ds:efi_lfb+4,0
    
apLfbDone:
    mov ebx,ebp
    cmp ax,-1
    je kernel_pretask
;    
    push ax
;    
    mov ax,SEG data
    mov ds,ax
    mov ebp,ds:mon_data_linear
    add ebp,OFFSET mon_core_regs
;
    mov ax,flat_sel
    mov ds,ax
    mov ebp,ds:[ebp].mc_sys_linear
;
    pop ax
    mov ds:[ebp].fault_vect,al
;
    add esp,8
;
    pop ax
    mov ds:[ebp].reg_ds.d_selector,ax
;
    pop eax
    mov ds:[ebp].reg_ebx,eax
;
    pop eax
    mov ds:[ebp].reg_eax,eax
;
    pop bx
    mov ds:[ebp].reg_ebp,ebx
    jmp common_pretask

kernel_pretask:
    add esp,8
;    
    mov ax,SEG data
    mov ds,ax
    mov eax,ds:mon_cr3
    or eax,eax
    jz kernel_pretask_cr3_done
;
    mov cr3,eax

kernel_pretask_cr3_done:    
    mov ebp,ds:mon_data_linear
    add ebp,OFFSET mon_core_regs
;
    mov ax,flat_sel
    mov ds,ax
    mov ebp,ds:[ebp].mc_sys_linear
;
    pop ax
    mov ds:[ebp].reg_ds.d_selector,ax
;
    pop ax
    mov ds:[ebp].fault_vect,al
;
    pop eax
    mov ds:[ebp].reg_ebx,eax
;
    pop eax
    mov ds:[ebp].reg_eax,eax
;
    pop eax
    mov ds:[ebp].reg_ebp,eax

common_pretask:
    pop eax
    mov ds:[ebp].fault_error,eax
;    
    pop eax
    mov ds:[ebp].reg_eip,eax
;
    pop ebx
    mov ds:[ebp].reg_cs.d_selector,bx
;
    pop eax
    mov ds:[ebp].reg_eflags,eax
;
    test bx,3
    jz apKernelStack
;
    pop eax
    mov ds:[ebp].reg_esp,eax
;
    pop ebx
    mov ds:[ebp].reg_ss.d_selector,bx
    jmp apStackOk

apKernelStack:
    mov ds:[ebp].reg_ss.d_selector,ss            
    mov ds:[ebp].reg_esp,esp

apStackOk:
    sldt bx
    mov ds:[ebp].reg_ldt.d_selector,bx
;    
    str bx
    mov ds:[ebp].reg_tr.d_selector,bx
;
    mov ds:[ebp].reg_gs.d_selector,gs
    mov ds:[ebp].reg_fs.d_selector,fs
    mov ds:[ebp].reg_es.d_selector,es
;    
    mov ds:[ebp].reg_edi,edi
    mov ds:[ebp].reg_esi,esi
    mov ds:[ebp].reg_edx,edx
    mov ds:[ebp].reg_ecx,ecx
;
    mov ds:[ebp].debug_core_sel,0
    mov ds:[ebp].debug_core_id,0
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
    mov si,fs:cs_dump_offset
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
    mov ax,fs:cs_nesting
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
    mov bx,fs:cs_curr_thread
    or bx,bx
    jz aclNoCurr
;
    mov ax,LOG_CORE_THREAD_RUNNING
    call AddCrashThread
        
aclNoCurr:
;    mov ax,LOG_CORE_THREAD_WAKEUP
;    mov si,OFFSET cs_wakeup_list
;    call AddCrashThreadList
;
    mov ax,LOG_CORE_THREAD_READY
    mov cx,256
    mov si,OFFSET cs_ptab

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
    mov cx,fs:cs_log_count
    cmp cx,CORE_LOG_ENTRIES    
    jb aclLogFew

aclLogMany:
    mov fs:cs_log_count,CORE_LOG_ENTRIES
    jmp aclLogProcess

aclLogFew:
    mov fs:cs_log_entry,0    

aclLogProcess:
    mov cx,fs:cs_log_count
    or cx,cx
    jz aclLogDone
;
    cmp cx,CORE_LOG_ENTRIES
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
    mov ds,fs:cs_log_sel
    mov bx,fs:cs_log_entry
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
    cmp bx,CORE_LOG_ENTRIES
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
    test fs:cs_flags,CS_FLAG_NMI
    jnz scdFail
;
    lock or fs:cs_flags,CS_FLAG_NMI    
;
    mov ax,SEG data
    mov ds,ax
    mov edx,ds:sys_data_linear
    or edx,edx
    jz scdFail
;
    mov ax,flat_sel
    mov ds,ax
    mov bx,fs:cs_id
    cmp bx,ds:[edx].mon_core_count
    jae scdFail
;
    movzx ebx,bx
    shl ebx,3
    add ebx,OFFSET mon_core_regs
    mov ebp,ds:[ebx+edx].mc_sys_linear
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
    test fs:cs_flags,CS_FLAG_NMI
    jnz swCheck
;        
    SendNmi
        
swCheck:
    test fs:cs_flags,CS_FLAG_SAVED
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
    test fs:cs_flags,CS_FLAG_NMI
    jnz sitNext
;        
    push ax
    mov al,2
    SendLockedInt
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
    test fs:cs_flags,CS_FLAG_NMI
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
    test fs:cs_flags,CS_FLAG_SAVED
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
    mov ax,fs:cs_id
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
    lock or fs:cs_flags,CS_FLAG_SAVED
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
    test fs:cs_flags,CS_FLAG_LONG_MODE
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
    mov ax,SEG data
    mov ds,ax
;    
    mov edx,ds:switch_linear
    mov eax,edx
    xor ebx,ebx
    mov al,3
    SetPageEntry
;    
    mov edx,ds:sys_data_linear    
    mov ax,flat_sel
    mov ds,ax
    mov bx,ds:[ebp].debug_core_id
    movzx ebx,bx
    shl ebx,3
    add ebx,OFFSET mon_core_regs
    mov ebp,ds:[ebx+edx].mc_mon_linear
    jmp SwitchToMonitor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartSmpCoreDump
;
;           DESCRIPTION:    Start SMP core dump
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_smp_core_dump_name    DB 'Start Smp Core Dump', 0
    
start_smp_core_dump     Proc far
    call UpdateMonData
    ret
start_smp_core_dump     Endp

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
    mov ds:mon_linear,0
    mov eax,cr3
    mov ds:mon_cr3,eax
;
    mov eax,1000h
    AllocateBigLinear
    mov ds:map_linear,edx    
    xor ebx,ebx
    mov eax,3
    SetPageEntry
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov esi,OFFSET start_smp_core_dump
    mov edi,OFFSET start_smp_core_dump_name
    xor cl,cl
    mov ax,start_smp_core_dump_nr
    RegisterOsGate
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
