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
INCLUDE realtime.def

.386p

data    SEGMENT byte public 'DATA'

map_sel	        DW ?
map_linear	DD ?

uni_linear      DD ?
uni_phys        DD ?

data    ENDS

code    SEGMENT byte public use32 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MapPhysical
;
;           DESCRIPTION:    Map physical address
;
;           PARAMETERS:     EDX:EBX	Physical address
;
;           RETURNS:        DS          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapPhysical     PROC near
    push eax
    push ebx
    push edx
;
    mov eax,SEG data
    mov ds,eax
    mov eax,ebx
    mov ebx,edx
    and ax,0F000h
;   
    mov edx,ds:map_linear 
    mov al,3
    SetPageEntry
;
    mov ds,ds:map_sel
;
    pop edx
    pop ebx
    pop eax
    ret
MapPhysical	Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadPhysByte
;
;           DESCRIPTION:    Read physical byte
;
;           PARAMETERS:     EDX:EBX	Physical address
;
;           RETURNS:        AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_phys_byte_name    DB 'Read Physical Byte',0

read_phys_byte     PROC far
    push ds
    push ebx
;
    call MapPhysical
    and ebx,0FFFh
    mov al,ds:[ebx]
;
    pop ebx
    pop ds
    ret
read_phys_byte     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadPhysWord
;
;           DESCRIPTION:    Read physical word
;
;           PARAMETERS:     EDX:EBX	Physical address
;
;           RETURNS:        AX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_phys_word_name    DB 'Read Physical Word',0

read_phys_word     PROC far
    push ds
    push ebx
;
    call MapPhysical
    and ebx,0FFFh
    mov ax,ds:[ebx]
;
    pop ebx
    pop ds
    ret
read_phys_word     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadPhysDword
;
;           DESCRIPTION:    Read physical dword
;
;           PARAMETERS:     EDX:EBX	Physical address
;
;           RETURNS:        EAX         Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_phys_dword_name    DB 'Read Physical Dword',0

read_phys_dword     PROC far
    push ds
    push ebx
;
    call MapPhysical
    and ebx,0FFFh
    mov eax,ds:[ebx]
;
    pop ebx
    pop ds
    ret
read_phys_dword     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReadPhysQword
;
;           DESCRIPTION:    Read physical qword
;
;           PARAMETERS:     EDX:EBX	Physical address
;
;           RETURNS:        ECX:EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_phys_qword_name    DB 'Read Physical Qword',0

read_phys_qword     PROC far
    push ds
    push ebx
;
    call MapPhysical
    and ebx,0FFFh
    mov eax,ds:[ebx]
    mov ecx,ds:[ebx+4]
;
    pop ebx
    pop ds
    ret
read_phys_qword     Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WritePhysByte
;
;           DESCRIPTION:    Write physical byte
;
;           PARAMETERS:     EDX:EBX	Physical address
;                           AL          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_phys_byte_name    DB 'Write Physical Byte',0

write_phys_byte     PROC far
    push ds
    push ebx
;
    call MapPhysical
    and ebx,0FFFh
    mov ds:[ebx],al
;
    pop ebx
    pop ds
    ret
write_phys_byte     Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WritePhysWord
;
;           DESCRIPTION:    Write physical word
;
;           PARAMETERS:     EDX:EBX	Physical address
;                           AX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_phys_word_name    DB 'Write Physical Word',0

write_phys_word     PROC far
    push ds
    push ebx
;
    call MapPhysical
    and ebx,0FFFh
    mov ds:[ebx],ax
;
    pop ebx
    pop ds
    ret
write_phys_word     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WritePhysDword
;
;           DESCRIPTION:    Write physical dword
;
;           PARAMETERS:     EDX:EBX	Physical address
;                           EAX         Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_phys_dword_name    DB 'Write Physical Dword',0

write_phys_dword     PROC far
    push ds
    push ebx
;
    call MapPhysical
    and ebx,0FFFh
    mov ds:[ebx],eax
;
    pop ebx
    pop ds
    ret
write_phys_dword     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WritePhysQword
;
;           DESCRIPTION:    Write physical qword
;
;           PARAMETERS:     EDX:EBX	Physical address
;                           ECX:EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_phys_qword_name    DB 'Write Physical Qword',0

write_phys_qword     PROC far
    push ds
    push ebx
;
    call MapPhysical
    and ebx,0FFFh
    mov ds:[ebx],eax
    mov ds:[ebx+4],ecx
;
    pop ebx
    pop ds
    ret
write_phys_qword     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetupUniDir
;
;           DESCRIPTION:    Setup ptr entries
;
;           PARAMETERS:     ES:EDI	Ptr entry data
;                           ESI         Ptr entry #
;                           EBX:EAX     Max address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupUniDir     PROC near
    pushad
;
    push eax
    push ebx
;
    mov eax,1000h
    AllocateBigLinear
;
    mov eax,es:[edi]
    mov ebx,es:[edi+4]
    mov al,3
    SetPageEntry
;
    pop ebx
    pop eax
;
    mov ebp,esi
    shr ebp,2
    shl esi,30
    or si,83h
;
    mov edi,edx
    mov ecx,200h

sudLoop:
    mov es:[edi],esi
    mov es:[edi+4],ebp
;
    add edi,8
    add esi,200000h
    sub eax,200000h
    sbb ebx,0
    jc sudPad
;
    loop sudLoop
    jmp sudFree

sudPad:
    sub ecx,1
    jz sudFree
;
    xor eax,eax

sudPadLoop:
    mov es:[edi],eax
    mov es:[edi+4],eax
;
    add edi,8
    loop sudPadLoop

sudFree:
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
;
    mov ecx,1000h
    FreeLinear
;
    popad
    ret
SetupUniDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetupUniPtr
;
;           DESCRIPTION:    Setup ptr entries
;
;           PARAMETERS:     ES:EDI	PML4 entry data
;                           ESI         PML4 entry #
;                           EBX:EAX     Max address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupUniPtr     PROC near
    pushad
;
    push eax
    push ebx
;
    mov eax,1000h
    AllocateBigLinear
;
    mov eax,es:[edi]
    mov ebx,es:[edi+4]
    mov al,3
    SetPageEntry
;
    pop ebx
    pop eax
;
    shl esi,9
    mov edi,edx
    mov ecx,200h

supLoop:
    push ebx
    push eax
;
    AllocatePhysical64
    mov al,3
    mov es:[edi],eax
    mov es:[edi+4],ebx
;
    pop eax
    pop ebx
    call SetupUniDir
;
    inc esi
    add edi,8
    sub eax,40000000h
    sbb ebx,0
    jc supPad
;
    loop supLoop
    jmp supFree

supPad:
    sub ecx,1
    jz supFree
;
    xor eax,eax

supPadLoop:
    mov es:[edi],eax
    mov es:[edi+4],eax
;
    add edi,8
    loop supPadLoop

supFree:
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
;
    mov ecx,1000h
    FreeLinear
;
    popad
    ret
SetupUniPtr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetupUniPml4
;
;           DESCRIPTION:    Setup plm4 entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupUniPml4     PROC near
    pushad
;
    GetHighestPhysical
;
    xor esi,esi
    mov edi,ds:uni_linear
    mov ecx,200h

sup4Loop:
    push ebx
    push eax
;    
    AllocatePhysical64
    mov al,3
    mov es:[edi],eax
    mov es:[edi+4],ebx
;
    pop eax
    pop ebx
    call SetupUniPtr
;
    inc esi
    add edi,8
    sub ebx,80h
    jc sup4Pad
;
    loop sup4Loop
    jmp sup4Done

sup4Pad:
    sub ecx,1
    jz sup4Done
;
    xor eax,eax

sup4PadLoop:
    mov es:[edi],eax
    mov es:[edi+4],eax
;
    add edi,8
    loop sup4PadLoop

sup4Done:    
    popad
    ret
SetupUniPml4	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddMonitor
;
;           DESCRIPTION:    Add and map monitor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mon_file DB 'z:/realmon.bin', 0

AddMonitor     PROC near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,eax
;
    mov eax,cs
    mov es,eax
    mov edi,OFFSET mon_file
    xor cl,cl
    OpenFile
    jc amDone
;
    mov ax,flat_sel
    mov es,eax
;
    GetFileSize
    add eax,realtime_mon_header_size
    dec eax
    and ax,0F000h
    add eax,1000h
    AllocateBigLinear
;
    push eax
    xor al,al
    mov ecx,realtime_mon_header_size
    mov edi,edx
    rep stos byte ptr es:[edi]
;
    mov edi,edx
    mov eax,OFFSET rtm_stack + 1000h
    mov es:[edi],eax
;
    mov eax,0FFFFFF80h
    mov es:[edi+4],eax
;
    pop eax
;
    mov ecx,eax
    mov edi,edx
    add edi,realtime_mon_header_size
    ReadFile
;
    CloseFile
;
    shr ecx,12
    push ecx
    push edx
;
    mov edx,ds:uni_linear
    AllocatePhysical64
    mov al,3
    mov es:[edx+0FF8h],eax  ; pml4
    mov es:[edx+0FFCh],ebx
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    SetPageEntry
    mov edi,edx
;
    AllocatePhysical64
    mov al,3
    mov es:[edi],eax   ; ptr
    mov es:[edi+4],ebx
    add edi,8
;
    push eax
    xor eax,eax
    mov ecx,3FEh
    rep stos dword ptr es:[edi]
    pop eax
;
    SetPageEntry
    mov edi,edx
;
    AllocatePhysical64
    mov al,3
    mov es:[edi],eax   ; dir
    mov es:[edi+4],ebx
    add edi,8
;
    push eax
    xor eax,eax
    mov ecx,3FEh
    rep stos dword ptr es:[edi]
    pop eax
;
    SetPageEntry
    mov edi,edx
;
    pop edx
    pop ecx
;
    mov ebp,200h

amCopyMonLoop:    
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
    jnz amCopyMonLoop

amPadMonLoop:
    xor eax,eax
    stos dword ptr es:[edi]
    stos dword ptr es:[edi]
;
    sub ebp,1
    jnz amPadMonLoop
    
amDone:
    popad
    pop es
    pop ds
    ret
AddMonitor     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateUniMap
;
;           DESCRIPTION:    Create uni mapping
;
;           RETURNS:        EBX		CR3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateUniMap     PROC near
    push ds
    push edx
;
    mov edx,SEG data
    mov ds,edx
;
    mov edx,ds:uni_linear
    or edx,edx
    jnz cuDone
;
    push es
    push eax
    push ebx
    push ecx
    push edi
;
    mov eax,flat_sel
    mov es,eax
;
    mov eax,1000h
    AllocateBigLinear
    mov ds:uni_linear,edx
;
    AllocatePhysical32
    mov ds:uni_phys,eax
;
    mov al,3
    SetPageEntry
;    
    call SetupUniPml4
;
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop es
;
    call AddMonitor

cuDone:
    mov ebx,ds:uni_phys
;
    pop edx
    pop ds
    ret
CreateUniMap     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           EmulateRealtime
;
;           DESCRIPTION:    Emulate realtime load
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

emulate_realtime_name    DB 'Emulate Realtime',0

emulate_realtime     PROC far
    push ds
    push es
    pushad
;
    call CreateUniMap
;
    mov al,7
    BootRealtimeCore
;
    popad
    pop es
    pop ds
    ret
emulate_realtime     Endp

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
    mov ds:uni_linear,0
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
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET read_phys_byte
    mov edi,OFFSET read_phys_byte_name
    xor dx,dx
    mov ax,read_phys_byte_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_phys_word
    mov edi,OFFSET read_phys_word_name
    xor dx,dx
    mov ax,read_phys_word_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_phys_dword
    mov edi,OFFSET read_phys_dword_name
    xor dx,dx
    mov ax,read_phys_dword_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_phys_qword
    mov edi,OFFSET read_phys_qword_name
    xor dx,dx
    mov ax,read_phys_qword_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_phys_byte
    mov edi,OFFSET write_phys_byte_name
    xor dx,dx
    mov ax,write_phys_byte_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_phys_word
    mov edi,OFFSET write_phys_word_name
    xor dx,dx
    mov ax,write_phys_word_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_phys_dword
    mov edi,OFFSET write_phys_dword_name
    xor dx,dx
    mov ax,write_phys_dword_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_phys_qword
    mov edi,OFFSET write_phys_qword_name
    xor dx,dx
    mov ax,write_phys_qword_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET emulate_realtime
    mov edi,OFFSET emulate_realtime_name
    xor dx,dx
    mov ax,emulate_realtime_nr
    RegisterBimodalUserGate
    ret
init    ENDP
    

code    ENDS

    END init
