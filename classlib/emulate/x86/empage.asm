;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Em486 CPU emulator
; Copyright (C) 1998-2000, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage. For information on commercial usage,
; contact em486@rdos.net.
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
; EMPAGE.ASM
; Paging emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat

include \rdos\classlib\emulate\x86\emulate.inc
include \rdos\classlib\emulate\x86\emseg.inc

        extrn _ReadMemoryByte:near
        extrn _ReadMemoryWord:near
        extrn _ReadMemoryDword:near
        extrn _ReadMemoryQword:near

        extrn _WriteMemoryByte:near
        extrn _WriteMemoryWord:near
        extrn _WriteMemoryDword:near
        extrn _WriteMemoryQword:near

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           FlushTlb
;
;               description:    Flush TLB register
;
;               PARAMETERS:     EBP             CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public FlushTlb

FlushTlb        Proc near
    push ecx
    push edi
;
    mov ecx,32
    lea edi,[ebp].reg_tlb.tlb
    mov [ebp].reg_tlb.tlb_lru,0
    mov [ebp].reg_tlb.tlb_lmask,1
    mov [ebp].reg_tlb.tlb_lptr,edi
FlushTlbLoop:
    mov [edi].t_tag,-1
    add edi,SIZE tlb_entry_struc
    loop FlushTlbLoop
;
    pop edi
    pop ecx
    ret
FlushTlb        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SearchTlb32
;
;               description:    search TLB for a physical address
;
;               PARAMETERS:     EBP             CPU
;                               EBX             LINEAR ADDRESS
;
;               RETURNS:        NC              OK
;                               EAX             PHYSICAL ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SearchTlb32 Proc near
        push edi
        mov eax,ebx
        and ax,0F000h
        lea edi,[ebp].reg_tlb.tlb
        mov ecx,32
        mov edx,1
SearchTlbLoop32:
        cmp eax,[edi].t_tag
        je SearchEntryFound32
        add edi,SIZE tlb_entry_struc
        shl edx,1
        loop SearchTlbLoop32
        stc
        pop edi
        ret

SearchEntryFound32:
        mov eax,[edi].t_address
        or [ebp].reg_tlb.tlb_lru,edx
        clc
        pop edi
        ret
SearchTlb32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SearchTlb64
;
;               description:    search TLB for a physical address
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;
;               RETURNS:        NC              OK
;                               EDX:EAX         PHYSICAL ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SearchTlb64 Proc near
        push ebx
        push esi
;
        mov eax,ebx
        and ax,0F000h
        lea esi,[ebp].reg_tlb.tlb
        mov ecx,32
        mov ebx,1

SearchTlbLoop64:
        cmp eax,[esi].t_tag
        jne SearchTlbNext64
;
        cmp edi,[esi+4].t_tag
        je SearchTlbFound64

SearchTlbNext64:
        add esi,SIZE tlb_entry_struc
        shl ebx,1
        loop SearchTlbLoop64
;        
        stc
        pop esi
        pop ebx
        ret

SearchTlbFound64:
        mov eax,[esi].t_address
        mov edx,[esi+4].t_address
        or [ebp].reg_tlb.tlb_lru,ebx
        clc
        pop esi
        pop ebx
        ret
SearchTlb64       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           AllocateTlb
;
;               description:    Find a free entry in TLB
;
;               PARAMETERS:     EBP             CPU
;
;               RETURNS:        ESI              ADDRESS OF ENTRY                        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateTlb     Proc near
        push edi
        mov ecx,32
        lea esi,[ebp].reg_tlb.tlb
AllocTlbFreeLoop:
        cmp [esi].t_tag,-1
        je AllocTlbDone
        add esi,SIZE tlb_entry_struc
        loop AllocTlbFreeLoop
;
        mov esi,[ebp].reg_tlb.tlb_lptr
        mov edx,[ebp].reg_tlb.tlb_lmask

        mov eax,[ebp].reg_tlb.tlb_lru
AllocTlbStealLoop:
        test edx,eax
        jz AllocTlbStealDo
        xor eax,edx
        rol edx,1
        add esi,SIZE tlb_entry_struc
        test dl,1
        jz AllocTlbStealLoop
        lea esi,[ebp].reg_tlb.tlb
        jmp AllocTlbStealLoop

AllocTlbStealDo:
        or eax,edx
        mov [ebp].reg_tlb.tlb_lru,eax
        rol edx,1
        mov edi,esi
        add edi,SIZE tlb_entry_struc
        test dl,1
        jz AllocTlbStealSave
        lea edi,[ebp].reg_tlb.tlb

AllocTlbStealSave:
        mov [ebp].reg_tlb.tlb_lptr,edi
        mov [ebp].reg_tlb.tlb_lmask,edx

AllocTlbDone:
        pop edi
        ret
AllocateTlb     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadPhysical
;
;               description:    read from bus
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         PHYSICAL ADDRESS
;                               ESI             BUFFER
;                               ECX             NUMBER OF BYTE TO READ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPhysical Proc near
        cmp ecx,1
        je rpByte
;
        cmp ecx,2
        je rpWord
;
        cmp ecx,4
        jbe rpDword
;
        test bl,1
        jnz rpOtherByte
;
        test bl,2
        jnz rpOtherWord
;
        test bl,4
        jnz rpOtherDword

rpOtherQword:  
        push edi
        push ecx
        push ebx
;
        inc [ebp].mem_count
        push edi
        push ebx
        push ebp
        call _ReadMemoryQword
;
        pop ebx
        pop ecx
        pop edi        
        mov [esi],eax
        mov [esi+4],edx
        add esi,8
        add ebx,8
        sub ecx,8
        ja ReadPhysical
;
        ret
                      
rpOtherDword:  
        push edi
        push ecx
        push ebx
;
        inc [ebp].mem_count
        push edi
        push ebx
        push ebp
        call _ReadMemoryDword
;
        pop ebx
        pop ecx
        pop edi        
        mov [esi],eax
        add esi,4
        add ebx,4
        sub ecx,4
        ja ReadPhysical
;
        ret
                      
rpOtherWord:  
        push edi
        push ecx
        push ebx
;
        inc [ebp].mem_count
        push edi
        push ebx
        push ebp
        call _ReadMemoryWord
;
        pop ebx
        pop ecx
        pop edi        
        mov [esi],ax
        add esi,2
        add ebx,2
        sub ecx,2
        ja ReadPhysical
;
        ret
                                            
rpOtherByte:  
        push edi
        push ecx
        push ebx
;
        inc [ebp].mem_count
        push edi
        push ebx
        push ebp
        call _ReadMemoryByte
;
        pop ebx
        pop ecx
        pop edi        
        mov [esi],al
        inc esi
        inc ebx
        sub ecx,1
        ja ReadPhysical
;
        ret        

rpByte:
        inc [ebp].mem_count
        push edi
        push ebx
        push ebp
        call _ReadMemoryByte
        mov [esi],al
        ret

rpWord:
        test bl,1
        jnz rpWord1
;
        inc [ebp].mem_count
        push edi
        push ebx
        push ebp
        call _ReadMemoryWord
        mov [esi],ax
        ret

rpWord1:
        add [ebp].mem_count,2
        mov eax,ebx
        inc eax
        push edi
        push eax
        push ebp
;
        push edi
        push ebx
        push ebp
        call _ReadMemoryByte
        mov [esi],al
        inc esi
;
        call _ReadMemoryByte
        mov [esi],al
        ret                

rpDword:
        test bl,1
        jnz rpDword1
;
        test bl,2
        jnz rpDword2
;        
        inc [ebp].mem_count
        push edi
        push ebx
        push ebp
        call _ReadMemoryDword
        mov [esi],eax
        ret

rpDword2:
        add [ebp].mem_count,2
        mov eax,ebx
        add eax,2
        push edi
        push eax
        push ebp
;
        push edi
        push ebx
        push ebp
        call _ReadMemoryWord
        mov [esi],ax
        add esi,2
;
        call _ReadMemoryWord
        mov [esi],ax
        ret                

rpDword1:
        add [ebp].mem_count,3
        push ebx
        push edi
        push ebx
        push ebp
        call _ReadMemoryByte
        pop ebx
        mov [esi],al
;
        inc esi
        inc ebx        
;
        mov eax,ebx
        add eax,2
        push edi
        push eax
        push ebp
;
        push edi
        push ebx
        push ebp
        call _ReadMemoryWord
        mov [esi],ax
        add esi,2
;        
        call _ReadMemoryByte
        mov [esi],al
        ret        
ReadPhysical    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WritePhysical
;
;               description:    write to bus
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         PHYSICAL ADDRESS
;                               ESI             BUFFER
;                               ECX             SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePhysical Proc near
        cmp ecx,1
        je wpByte
;
        cmp ecx,2
        je wpWord         
;
        cmp ecx,4
        je wpDword
;
        test bl,1
        jnz wpOtherByte
;
        test bl,2
        jnz wpOtherWord
;
        test bl,4
        jnz wpOtherDword

wpOtherQword:  
        cmp ecx,8
        jb wpOtherDword
;        
        push edi
        push ecx
        push ebx
;
        inc [ebp].mem_count
        mov eax,[esi]
        mov edx,[esi+4]
        push edx
        push eax
        push edi
        push ebx
        push ebp
        call _WriteMemoryQword
;
        pop ebx
        pop ecx
        pop edi        
        add esi,8
        add ebx,8
        sub ecx,8
        ja WritePhysical
;
        ret
                      
wpOtherDword:  
        cmp ecx,4
        jb wpOtherWord
;        
        push edi
        push ecx
        push ebx
;
        inc [ebp].mem_count
        mov eax,[esi]
        push eax
        push edi
        push ebx
        push ebp
        call _WriteMemoryDword
;
        pop ebx
        pop ecx
        pop edi        
        add esi,4
        add ebx,4
        sub ecx,4
        ja WritePhysical
;
        ret
                      
wpOtherWord:  
        cmp ecx,2
        jb wpOtherByte
;
        push edi
        push ecx
        push ebx
;
        inc [ebp].mem_count
        mov ax,[esi]
        push eax
        push edi
        push ebx
        push ebp
        call _WriteMemoryWord
;
        pop ebx
        pop ecx
        pop edi        
        add esi,2
        add ebx,2
        sub ecx,2
        ja WritePhysical
;
        ret
                                            
wpOtherByte:  
        push edi
        push ecx
        push ebx
;
        inc [ebp].mem_count
        mov al,[esi]
        push eax
        push edi
        push ebx
        push ebp
        call _WriteMemoryByte
;
        pop ebx
        pop ecx
        pop edi        
        inc esi
        inc ebx
        sub ecx,1
        ja WritePhysical
;
        ret        

wpByte:
        inc [ebp].mem_count
        mov al,[esi]
        push eax
        push edi
        push ebx
        push ebp
        call _WriteMemoryByte
        ret

wpWord:
        test bl,1
        jnz wpWord1
;
        inc [ebp].mem_count
        mov ax,[esi]
        push eax
        push edi
        push ebx
        push ebp
        call _WriteMemoryWord
        ret

wpWord1:
        add [ebp].mem_count,2
        mov al,[esi+1]
        push eax
        mov eax,ebx
        inc eax
        push edi
        push eax
        push ebp
;
        mov al,[esi]
        push eax
        push edi
        push ebx
        push ebp
        call _WriteMemoryByte
;
        call _WriteMemoryByte
        ret                

wpDword:
        test bl,1
        jnz wpDword1
;
        test bl,2
        jnz wpDword2
;        
        inc [ebp].mem_count
        mov eax,[esi]
        push eax
        push edi
        push ebx
        push ebp
        call _WriteMemoryDword
        ret

wpDword2:
        mov ax,[esi+2]
        push eax
        mov eax,ebx
        add eax,2
        push edi
        push eax
        push ebp
;
        mov ax,[esi]
        push eax
        push edi
        push ebx
        push ebp
        call _WriteMemoryWord
;
        call _WriteMemoryWord
        ret                

wpDword1:
        add [ebp].mem_count,3
        mov al,[esi+3]
        push eax
        push edi
        mov eax,ebx
        add eax,3
        push eax
        push ebp
;        
        mov ax,[esi+1]
        push eax
        push edi
        mov eax,ebx
        add eax,1
        push eax
        push ebp
;
        mov al,[esi]
        push eax
        push edi
        push ebx
        push ebp
        call _WriteMemoryByte
        call _WriteMemoryWord
        call _WriteMemoryByte
        ret        
WritePhysical   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LinearToPhysical32
;
;               description:    Translate a linear address to a physical address
;
;               PARAMETERS:     EBP             CPU
;                               EBX             LINEAR ADDRESS
;
;               RETURNS:        EAX             PHYSICAL ADDRESS & ATTRIBUTES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LinearToPhysical32        Proc near
        push ebx
        call SearchTlb32
        jnc LinearToPhysicalDone32
;
        call AllocateTlb
        xor edi,edi
        push esi
        mov [esi].t_tag,ebx
        add esi,OFFSET t_address
        shr ebx,20
        and ebx,0FFCh
        mov eax,[ebp].reg_cr3
        and ax,0F000h
        add ebx,eax
        push ebx
        mov ecx,4
        call ReadPhysical
        pop ebx
        pop esi
;
        mov ch,byte ptr [esi].t_address
        test ch,1
        jnz LinearToPhysicalDirOk32
;
        mov eax,-1
        xchg eax,[esi].t_tag
        mov [ebp].reg_cr2,eax
        xor bx,bx
        jmp PageFault

LinearToPhysicalDirOk32:
        push ecx
        test ch,20h
        jnz LinearToPhysicalDirAccessed32
        push esi
        or byte ptr [esi].t_address,20h
        mov ecx,4
        add esi,OFFSET t_address
        call WritePhysical
        pop esi

LinearToPhysicalDirAccessed32:
        mov ebx,[esi].t_tag
        shr ebx,10
        and ebx,0FFCh
        mov eax,[esi].t_address
        and ax,0F000h
        add ebx,eax
        push esi
        add esi,OFFSET t_address
        push ebx
        mov ecx,4
        call ReadPhysical
        pop ebx
        pop esi
;
        pop ecx
        mov cl,byte ptr [esi].t_address
        test cl,1
        jnz LinearToPhysicalPageOk32
;
        mov eax,-1
        xchg eax,[esi].t_tag
        mov [ebp].reg_cr2,eax
        xor bx,bx
        jmp PageFault

LinearToPhysicalPageOk32:
        and ch,cl
        and ch,3
        and cl,NOT 3
        or cl,ch
        push ecx
        test cl,20h
        jnz LinearToPhysicalPageAccessed32
        push esi
        or byte ptr [esi].t_address,20h
        mov ecx,4
        add esi,OFFSET t_address
        call WritePhysical
        pop esi

LinearToPhysicalPageAccessed32:
        pop ecx
;
        mov eax,[esi].t_tag
        and ax,0F000h
        mov [esi].t_tag,eax
;       
        mov eax,[esi].t_address
        and ax,0F000h
        or al,cl
        mov [esi].t_address,eax

LinearToPhysicalDone32:
        pop ebx
        ret
LinearToPhysical32        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CondLinearToPhysical32
;
;               description:    Translate a linear address to a physical address
;                                               no page faults
;
;               PARAMETERS:     EBP             CPU
;                               EBX             LINEAR ADDRESS
;
;               RETURNS:        EAX             PHYSICAL ADDRESS & ATTRIBUTES
;                               NC              OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondLinearToPhysical32    Proc near
        push ebx
        call SearchTlb32
        jnc CondLinearToPhysicalDone32
;
        call AllocateTlb
        xor edi,edi
        push esi
        mov [esi].t_tag,ebx
        add esi,OFFSET t_address
        shr ebx,20
        and ebx,0FFCh
        mov eax,[ebp].reg_cr3
        and ax,0F000h
        add ebx,eax
        push ebx
        mov ecx,4
        call ReadPhysical
        pop ebx
        pop esi
;
        mov ch,byte ptr [esi].t_address
        test ch,1
        jnz CondLinearToPhysicalDirOk32
;
        mov [esi].t_tag,-1
        stc
        jmp CondLinearToPhysicalDone32

CondLinearToPhysicalDirOk32:
        push ecx
        test ch,20h
        jnz CondLinearToPhysicalDirAccessed32
        push esi
        or byte ptr [esi].t_address,20h
        mov ecx,4
        add esi,OFFSET t_address
        call WritePhysical
        pop esi

CondLinearToPhysicalDirAccessed32:
        mov ebx,[esi].t_tag
        shr ebx,10
        and ebx,0FFCh
        mov eax,[esi].t_address
        and ax,0F000h
        add ebx,eax
        push esi
        add esi,OFFSET t_address
        push ebx
        mov ecx,4
        call ReadPhysical
        pop ebx
        pop esi
;
        pop ecx
        mov cl,byte ptr [esi].t_address
        test cl,1
        jnz CondLinearToPhysicalPageOk32
;
        mov [esi].t_tag,-1
        stc
        jmp CondLinearToPhysicalDone32

CondLinearToPhysicalPageOk32:
        and ch,cl
        and ch,3
        and cl,NOT 3
        or cl,ch
        push ecx
        test cl,20h
        jnz CondLinearToPhysicalPageAccessed32
        push esi
        or byte ptr [esi].t_address,20h
        mov ecx,4
        add esi,OFFSET t_address
        call WritePhysical
        pop esi

CondLinearToPhysicalPageAccessed32:
        pop ecx
;
        mov eax,[esi].t_tag
        and ax,0F000h
        mov [esi].t_tag,eax
;       
        mov eax,[esi].t_address
        and ax,0F000h
        or al,cl
        mov [esi].t_address,eax
        clc

CondLinearToPhysicalDone32:
        pop ebx
        ret
CondLinearToPhysical32    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           LinearToPhysicalPae
;
;               description:    Translate a linear address to a physical address
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;
;               RETURNS:        EDX:EAX         PHYSICAL ADDRESS & ATTRIBUTES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LinearToPhysicalPae        Proc near
        push ebx
        call SearchTlb64
        jnc LinearToPhysicalDonePae
;
        call AllocateTlb
        push esi
        mov [esi].t_tag,ebx
        mov [esi].t_tag+4,edi
        add esi,OFFSET t_address
;
        xor edi,edi
        shr ebx,30
        shl ebx,3
        mov eax,[ebp].reg_cr3
        and ax,0F000h
        add ebx,eax
        mov ecx,8
        call ReadPhysical
        pop esi
;
        mov ch,byte ptr [esi].t_address
        test ch,1
        jnz LinearToPhysicalPtrOkPae
;
        mov eax,-1
        xchg eax,[esi].t_tag
        mov [ebp].reg_cr2,eax
        mov eax,-1
        xchg eax,[esi].t_tag+4
        mov [ebp].reg_cr2+4,eax
        xor bx,bx
        jmp PageFault

LinearToPhysicalPtrOkPae:
        test ch,20h
        jnz LinearToPhysicalPtrAccessedPae
;
        push esi
        or byte ptr [esi].t_address,20h
        mov ecx,1
        add esi,OFFSET t_address
        call WritePhysical
        pop esi

LinearToPhysicalPtrAccessedPae:
        mov ebx,[esi].t_tag
        shr ebx,18
        and ebx,0FF8h
        mov eax,[esi].t_address
        and ax,0F000h
        add ebx,eax
        mov edi,[esi].t_address+4
        push esi
        add esi,OFFSET t_address
        push ebx
        mov ecx,8
        call ReadPhysical
        pop ebx
        pop esi
;
        mov ch,byte ptr [esi].t_address
        test ch,1
        jnz LinearToPhysicalDirOkPae
;
        mov eax,-1
        xchg eax,[esi].t_tag
        mov [ebp].reg_cr2,eax
        mov eax,-1
        xchg eax,[esi].t_tag+4
        mov [ebp].reg_cr2+4,eax
        xor bx,bx
        jmp PageFault

LinearToPhysicalDirOkPae:
        push ecx
        test al,20h
        jnz LinearToPhysicalDirAccessedPae
;
        push esi
        or byte ptr [esi].t_address,20h
        mov ecx,1
        add esi,OFFSET t_address
        call WritePhysical
        pop esi

LinearToPhysicalDirAccessedPae:
        mov ebx,[esi].t_tag
        shr ebx,9
        and ebx,0FF8h
        mov eax,[esi].t_address
        and ax,0F000h
        add ebx,eax
        mov edi,[esi].t_address+4
        push esi
        add esi,OFFSET t_address
        push ebx
        mov ecx,8
        call ReadPhysical
        pop ebx
        pop esi
;
        pop ecx
        mov cl,byte ptr [esi].t_address
        test cl,1
        jnz LinearToPhysicalPageOkPae
;
        mov eax,-1
        xchg eax,[esi].t_tag
        mov [ebp].reg_cr2,eax
        mov eax,-1
        xchg eax,[esi].t_tag+4
        mov [ebp].reg_cr2+4,eax
        xor bx,bx
        jmp PageFault

LinearToPhysicalPageOkPae:
        mov al,cl
        and ch,cl
        and ch,3
        and cl,NOT 3
        or cl,ch
        push ecx
        test al,20h
        jnz LinearToPhysicalPageAccessedPae
;        
        push esi
        or byte ptr [esi].t_address,20h
        mov ecx,1
        add esi,OFFSET t_address
        call WritePhysical
        pop esi

LinearToPhysicalPageAccessedPae:
        pop ecx
;
        mov eax,[esi].t_tag
        and ax,0F000h
        mov [esi].t_tag,eax
;       
        mov eax,[esi].t_address
        and ax,0F000h
        or al,cl
        mov [esi].t_address,eax
        mov edx,[esi].t_address+4

LinearToPhysicalDonePae:
        pop ebx
        ret
LinearToPhysicalPae        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CondLinearToPhysicalPae
;
;               description:    Translate a linear address to a physical address
;                                               no page faults
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;
;               RETURNS:        EDX:EAX         PHYSICAL ADDRESS & ATTRIBUTES
;                               NC              OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondLinearToPhysicalPae    Proc near
        push ebx
        push ecx
        push edi
;        
        call SearchTlb64
        jnc CondLinearToPhysicalDonePae
;
        call AllocateTlb
;
        push esi
        mov [esi].t_tag,ebx
        mov [esi].t_tag+4,edi
        add esi,OFFSET t_address
;
        xor edi,edi
        shr ebx,30
        shl ebx,3
        mov eax,[ebp].reg_cr3
        and ax,0F000h
        add ebx,eax
        mov ecx,8
        call ReadPhysical
        pop esi
;
        mov ch,byte ptr [esi].t_address
        test ch,1
        jnz CondLinearToPhysicalPtrOkPae
;
        mov [esi].t_tag,-1
        stc
        jmp CondLinearToPhysicalDonePae

CondLinearToPhysicalPtrOkPae:
        push ecx
        test ch,20h
        jnz CondLinearToPhysicalPtrAccessedPae
;
        push esi
        or byte ptr [esi].t_address,20h
        mov ecx,1
        add esi,OFFSET t_address
        call WritePhysical
        pop esi

CondLinearToPhysicalPtrAccessedPae:
        mov ebx,[esi].t_tag
        shr ebx,18
        and ebx,0FF8h
        mov eax,[esi].t_address
        and ax,0F000h
        add ebx,eax
        mov edi,[esi].t_address+4
        push esi
        add esi,OFFSET t_address
        push ebx
        mov ecx,8
        call ReadPhysical
        pop ebx
        pop esi
;
        pop ecx
        mov cl,byte ptr [esi].t_address
        test cl,1
        jnz CondLinearToPhysicalDirOkPae
;
        mov [esi].t_tag,-1
        stc
        jmp CondLinearToPhysicalDonePae

CondLinearToPhysicalDirOkPae:
        mov al,cl
        and ch,cl
        and ch,3
        and cl,NOT 3
        or ch,cl
        push ecx
        test al,20h
        jnz CondLinearToPhysicalDirAccessedPae
;
        push esi
        or byte ptr [esi].t_address,20h
        mov ecx,1
        add esi,OFFSET t_address
        call WritePhysical
        pop esi

CondLinearToPhysicalDirAccessedPae:
        mov ebx,[esi].t_tag
        shr ebx,9
        and ebx,0FF8h
        mov eax,[esi].t_address
        and ax,0F000h
        add ebx,eax
        mov edi,[esi].t_address+4
        push esi
        add esi,OFFSET t_address
        push ebx
        mov ecx,8
        call ReadPhysical
        pop ebx
        pop esi
;
        pop ecx
        mov cl,byte ptr [esi].t_address
        test cl,1
        jnz CondLinearToPhysicalPageOkPae
;
        mov [esi].t_tag,-1
        stc
        jmp CondLinearToPhysicalDonePae

CondLinearToPhysicalPageOkPae:
        mov al,cl
        and ch,cl
        and ch,3
        and cl,NOT 3
        or cl,ch
        push ecx
        test al,20h
        jnz CondLinearToPhysicalPageAccessedPae
;        
        push esi
        or byte ptr [esi].t_address,20h
        mov ecx,1
        add esi,OFFSET t_address
        call WritePhysical
        pop esi

CondLinearToPhysicalPageAccessedPae:
        pop ecx
;
        mov eax,[esi].t_tag
        and ax,0F000h
        mov [esi].t_tag,eax
;       
        mov eax,[esi].t_address
        and ax,0F000h
        or al,cl
        mov [esi].t_address,eax
        mov edx,[esi].t_address+4
        clc

CondLinearToPhysicalDonePae:
        pop edi
        pop ecx
        pop ebx
        ret
CondLinearToPhysicalPae    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadPaged32
;
;               description:    Read paged
;
;               PARAMETERS:     EBP             CPU
;                               EBX             LINEAR ADDRESS
;                               ECX             NUMBER OF BYTE TO READ
;                               ESI             Req buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPaged32       Proc near
        xor edi,edi
ReadPagedLoop32:
        push ebx
        push ecx
        push esi
;
        call LinearToPhysical32
        test al,4
        jnz ReadLinearPrivOk32
        test [ebp].em_pl,ACCESS_RPL
        jz ReadLinearPrivOk32
;
        mov [ebp].reg_cr2,ebx
        mov bx,4
        jmp PageFault

ReadLinearPrivOk32:
        and ax,0F000h
        and ebx,0FFFh
        or eax,ebx
        mov ebx,eax
        pop esi
        pop ecx
;
        push ecx
        push esi
        not eax
        and eax,0FFFh
        inc eax
        cmp ecx,eax
        jbe ReadPagedWhole32
        mov ecx,eax
ReadPagedWhole32:
        push ecx
        call ReadPhysical
        pop eax
        pop esi
        pop ecx
        pop ebx
        sub ecx,eax
        jz ReadPagedDone32
;
        add esi,eax
        add ebx,eax
        jmp ReadPagedLoop32

ReadPagedDone32:
        ret
ReadPaged32       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WritePaged32
;
;               description:    Write paged
;
;               PARAMETERS:     EBP             CPU
;                               EBX             LINEAR ADDRESS
;                               ECX             NUMBER OF BYTE TO WRITE
;                               ESI             Req buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePaged32      Proc near
        xor edi,edi
WritePagedLoop32:
        push ebx
        push ecx
        push esi
;
        call LinearToPhysical32
        test al,4
        jnz WritePagedUserOk32
        test [ebp].em_pl,ACCESS_RPL
        jz WritePagedUserOk32
;
        mov [ebp].reg_cr2,ebx
        mov bx,4
        jmp PageFault

WritePagedUserOk32:
        test al,2
        jnz WritePagedPrivOk32
        test [ebp].em_pl,ACCESS_RPL
        jnz WritePagedPrivFault32
        test [ebp].reg_cr0,CR0_WP
        jz WritePagedPrivOk32

WritePagedPrivFault32:
        mov [ebp].reg_cr2,ebx
        mov bx,2
        jmp PageFault
        
WritePagedPrivOk32:
        and ax,0F000h
        and ebx,0FFFh
        or eax,ebx
        mov ebx,eax
        pop esi
        pop ecx
;
        push ecx
        push esi
        not eax
        and eax,0FFFh
        inc eax
        cmp ecx,eax
        jbe WritePagedWhole32
        mov ecx,eax
WritePagedWhole32:
        push ecx
        call WritePhysical
        pop eax
        pop esi
        pop ecx
        pop ebx
        sub ecx,eax
        jz WritePagedDone32
        add esi,eax
        add ebx,eax
        jmp WritePagedLoop32

WritePagedDone32:
        ret
WritePaged32      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadPagedPae
;
;               description:    Read paged
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;                               ECX             NUMBER OF BYTE TO READ
;                               ESI             Req buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPagedPae       Proc near

ReadPagedLoopPae:
        push edi
        push ebx
        push edx
        push ecx
        push esi
;
        call LinearToPhysicalPae
        test al,4
        jnz ReadLinearPrivOkPae
        test [ebp].em_pl,ACCESS_RPL
        jz ReadLinearPrivOkPae
;
        mov [ebp].reg_cr2,ebx
        mov [ebp].reg_cr2+4,edi
        mov bx,4
        jmp PageFault

ReadLinearPrivOkPae:
        and ax,0F000h
        and ebx,0FFFh
        or eax,ebx
        mov ebx,eax
        mov edi,edx
        pop esi
        pop ecx
;
        push ecx
        push esi
        not eax
        and eax,0FFFh
        inc eax
        cmp ecx,eax
        jbe ReadPagedWholePae

        mov ecx,eax
        
ReadPagedWholePae:
        push ecx
        call ReadPhysical
        pop eax
        pop esi
        pop ecx
        pop edx
        pop ebx
        pop edi
        sub ecx,eax
        jz ReadPagedDonePae
;
        add esi,eax
        add ebx,eax
        adc edi,0        
        jmp ReadPagedLoopPae

ReadPagedDonePae:
        ret
ReadPagedPae       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WritePagedPae
;
;               description:    Write paged
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;                               ECX             NUMBER OF BYTE TO WRITE
;                               ESI             Req buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePagedPae      Proc near

WritePagedLoopPae:
        push edi
        push ebx
        push edx
        push ecx
        push esi
;
        call LinearToPhysicalPae
        test al,4
        jnz WritePagedUserOkPae
;
        test [ebp].em_pl,ACCESS_RPL
        jz WritePagedUserOkPae
;
        mov [ebp].reg_cr2,ebx
        mov [ebp].reg_cr2+4,edi
        mov bx,4
        jmp PageFault

WritePagedUserOkPae:
        test al,2
        jnz WritePagedPrivOkPae
        test [ebp].em_pl,ACCESS_RPL
        jnz WritePagedPrivFaultPae
        test [ebp].reg_cr0,CR0_WP
        jz WritePagedPrivOkPae

WritePagedPrivFaultPae:
        mov [ebp].reg_cr2,ebx
        mov [ebp].reg_cr2+4,edi
        mov bx,2
        jmp PageFault
        
WritePagedPrivOkPae:
        and ax,0F000h
        and ebx,0FFFh
        or eax,ebx
        mov ebx,eax
        mov edi,edx
        pop esi
        pop ecx
;
        push ecx
        push esi
        not eax
        and eax,0FFFh
        inc eax
        cmp ecx,eax
        jbe WritePagedWholePae
        mov ecx,eax

WritePagedWholePae:
        push ecx
        call WritePhysical
        pop eax
        pop esi
        pop ecx
        pop edx
        pop ebx
        pop edi
        sub ecx,eax
        jz WritePagedDonePae
        add esi,eax
        add ebx,eax
        adc edi,0
        jmp WritePagedLoopPae

WritePagedDonePae:
        ret
WritePagedPae      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadLinear
;
;               description:    read from linear memory
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;                               ECX             NUMBER OF BYTE TO READ
;                               ESI             Req buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReadLinear

ReadLinear Proc near
        test [ebp].reg_cr0,CR0_PG
        jz ReadLinearReal
;        
        test [ebp].reg_cr4,20h
        jz ReadLinear32
;
        test [ebp].reg_efer,EFER_LME        
        jz ReadLinearPae

ReadLinear64:
        int 3
        ret

ReadLinearPae:
        call ReadPagedPae
        ret

ReadLinear32:        
        call ReadPaged32
        ret

ReadLinearReal:
        xor edi,edi
        call ReadPhysical
        ret
ReadLinear      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteLinear
;
;               description:    write to linear address
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         PHYSICAL ADDRESS
;                               ECX             SIZE
;                               ESI             Req buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteLinear Proc near
        test [ebp].reg_cr0,CR0_PG
        jz WriteLinearReal
;        
        test [ebp].reg_cr4,20h
        jz WriteLinear32
;
        test [ebp].reg_efer,EFER_LME        
        jz WriteLinearPae

WriteLinear64:
        int 3
        ret

WriteLinearPae:
        call WritePagedPae
        ret       

WriteLinear32:        
        call WritePaged32
        ret

WriteLinearReal:
        xor edi,edi
        lea esi,[ebp].req_buf
        call WritePhysical
        ret
WriteLinear     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           FlushTlbEntry
;
;               description:    Flush TLB entry
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FlushTlbEntry

FlushTlbEntry Proc near
        test [ebp].reg_cr0,CR0_PG
        jnz FlushTlbPaging
;
        ret        

FlushTlbPaging:        
        test [ebp].reg_cr4,20h
        jz FlushTlb32

FlushTlb64:
        push eax
        push ebx
        push ecx
        push esi
;
        mov eax,ebx
        and ax,0F000h
        lea esi,[ebp].reg_tlb.tlb
        mov ecx,32

FlushTlbLoop64:
        cmp eax,[esi].t_tag
        jne FlushTlbNext64
;
        cmp edi,[esi+4].t_tag
        je FlushTlbFound64

FlushTlbNext64:
        add esi,SIZE tlb_entry_struc
        shl ebx,1
        loop FlushTlbLoop64
        jmp FlushTlbDone64

FlushTlbFound64:
        mov eax,-1
        mov [esi].t_tag,eax
        mov [esi].t_tag+4,eax

FlushTlbDone64:        
        pop esi
        pop ecx
        pop ebx
        pop eax
        ret

FlushTlb32:        
        push eax
        push ecx
        push edi
;        
        mov eax,ebx
        and ax,0F000h
        lea edi,[ebp].reg_tlb.tlb
        mov ecx,32

FlushTlbLoop32:
        cmp eax,[edi].t_tag
        je FlushTlbFound32
;
        add edi,SIZE tlb_entry_struc
        shl edx,1
        loop FlushTlbLoop32
;
        jmp FlushTlbDone32        

FlushTlbFound32:
        mov eax,-1
        mov [esi].t_tag,eax
        mov [esi].t_tag+4,eax

FlushTlbDone32:
        pop edi
        pop ecx
        pop eax        
        ret
FlushTlbEntry      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CondReadPaged32
;
;               description:    Read paged without page faults
;
;               PARAMETERS:     EBP             CPU
;                               EBX             LINEAR ADDRESS
;                               ECX             NUMBER OF BYTE TO READ
;
;               RETURNS:        ECX             NUBER OF BYTES READ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondReadPaged32   Proc near
        xor edi,edi
        lea esi,[ebp].req_buf
CondReadPagedLoop32:
        push ebx
        push ecx
        push esi
;
        call CondLinearToPhysical32
        jc CondReadPagedFailed32
;
        test al,4
        jnz CondReadLinearPrivOk32
        test [ebp].reg_cs.d_access,ACCESS_RPL
        jz CondReadLinearPrivOk32
        jmp CondReadPagedFailed32

CondReadLinearPrivOk32:
        and ax,0F000h
        and ebx,0FFFh
        or eax,ebx
        mov ebx,eax
        pop esi
        pop ecx
;
        push ecx
        push esi
        not eax
        and eax,0FFFh
        inc eax
        cmp ecx,eax
        jbe CondReadPagedWhole32
        mov ecx,eax
CondReadPagedWhole32:
        push ecx
        call ReadPhysical
        pop eax
        pop esi
        pop ecx
        pop ebx
        add esi,eax
        add ebx,eax
        sub ecx,eax
        jz CondReadPagedDone32
        jmp CondReadPagedLoop32

CondReadPagedFailed32:
        pop esi
        pop ecx
        pop ebx

CondReadPagedDone32:
        mov ecx,esi
        lea esi,[ebp].req_buf
        sub ecx,esi
        ret
CondReadPaged32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CondReadPagedPae
;
;               description:    Read paged without page faults
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;                               ECX             NUMBER OF BYTE TO READ
;
;               RETURNS:        ECX             NUBER OF BYTES READ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondReadPagedPae   Proc near
        lea esi,[ebp].req_buf

CondReadPagedLoopPae:
        push edi
        push ebx
        push edx
        push ecx
        push esi
;
        call CondLinearToPhysicalPae
        jc CondReadPagedFailedPae
;
        test al,4
        jnz CondReadLinearPrivOkPae
        test [ebp].reg_cs.d_access,ACCESS_RPL
        jz CondReadLinearPrivOkPae
        jmp CondReadPagedFailedPae

CondReadLinearPrivOkPae:
        and ax,0F000h
        and ebx,0FFFh
        or eax,ebx
        mov ebx,eax
        mov edi,edx
        pop esi
        pop ecx
;
        push ecx
        push esi
        not eax
        and eax,0FFFh
        inc eax
        cmp ecx,eax
        jbe CondReadPagedWholePae
        mov ecx,eax
CondReadPagedWholePae:
        push ecx
        call ReadPhysical
        pop eax
        pop esi
        pop ecx
        pop edx
        pop ebx
        pop edi
        add esi,eax
        add ebx,eax
        adc edi,0
        sub ecx,eax
        jz CondReadPagedDonePae
        jmp CondReadPagedLoopPae

CondReadPagedFailedPae:
        pop esi
        pop ecx
        pop edx
        pop ebx
        pop edi

CondReadPagedDonePae:
        mov ecx,esi
        lea esi,[ebp].req_buf
        sub ecx,esi
        ret
CondReadPagedPae   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CondReadLinear
;
;               description:    conditional read from linear memory
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;                               ECX             NUMBER OF BYTE TO READ
;
;               RETURNS:        ECX             NUMBER OF VALID BYTES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public CondReadLinear

CondReadLinear Proc near
        test [ebp].reg_cr0,CR0_PG
        jz CondReadLinearReal
;        
        test [ebp].reg_cr4,20h
        jz CondReadLinear32
;
        test [ebp].reg_efer,EFER_LME        
        jz CondReadLinearPae

CondReadLinear64:
        int 3
        ret

CondReadLinearPae:
        call CondReadPagedPae 
        ret       

CondReadLinear32:        
        call CondReadPaged32
        ret

CondReadLinearReal:
        xor edi,edi
        lea esi,[ebp].req_buf
        push ecx
        call ReadPhysical
        pop ecx
        ret
CondReadLinear  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadLinearByte
;
;               DESCRIPTION:    Read one byte of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;
;               RETURNS:        AL              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReadLinearByte

ReadLinearByte  Proc near
        push ebx
        push ecx
        push edx
        push esi
;
        mov ecx,1
        lea esi,[ebp].req_buf
        call ReadLinear
        lea esi,[ebp].req_buf
        mov al,[esi]
;       
        pop esi
        pop edx
        pop ecx
        pop ebx
        ret
ReadLinearByte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadLinearWord
;
;               DESCRIPTION:    Read one word of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;
;               RETURNS:        AX              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReadLinearWord

ReadLinearWord  Proc near
        push ebx
        push ecx
        push edx
        push esi
;
        mov ecx,2
        lea esi,[ebp].req_buf
        call ReadLinear
        lea esi,[ebp].req_buf
        mov ax,[esi]
;
        pop esi
        pop edx
        pop ecx
        pop ebx
        ret
ReadLinearWord  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadLinearDword
;
;               DESCRIPTION:    Read one dword of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX             LINEAR ADDRESS
;
;               RETURNS:        EAX             DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReadLinearDword

ReadLinearDword Proc near
        push ebx
        push ecx
        push edx
        push esi
;
        mov ecx,4
        lea esi,[ebp].req_buf
        call ReadLinear
        lea esi,[ebp].req_buf
        mov eax,[esi]
;
        pop esi
        pop edx
        pop ecx
        pop ebx
        ret
ReadLinearDword Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadLinearFword
;
;               DESCRIPTION:    Read one fword of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;
;               RETURNS:        DX:EAX          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReadLinearFword

ReadLinearFword Proc near
        push ebx
        push ecx
        push esi
;
        mov ecx,6
        lea esi,[ebp].req_buf
        call ReadLinear
        lea esi,[ebp].req_buf
        mov eax,[esi]
        mov dx,[esi+4]
;
        pop esi
        pop ecx
        pop ebx
        ret
ReadLinearFword Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadLinearQword
;
;               DESCRIPTION:    Read one qword of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;
;               RETURNS:        EDX:EAX         DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReadLinearQword

ReadLinearQword Proc near
        push ebx
        push ecx
        push esi
;
        mov ecx,8
        lea esi,[ebp].req_buf
        call ReadLinear
        lea esi,[ebp].req_buf
        mov eax,[esi]
        mov edx,[esi+4]
;
        pop esi
        pop ecx
        pop ebx
        ret
ReadLinearQword Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadLinearTbyte
;
;               DESCRIPTION:    Read one tbyte of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;
;               RETURNS:        CX:EDX:EAX      DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReadLinearTbyte

ReadLinearTbyte Proc near
        push ebx
        push esi
;
        mov ecx,10
        lea esi,[ebp].req_buf
        call ReadLinear
        lea esi,[ebp].req_buf
        mov eax,[esi]
        mov edx,[esi+4]
        mov cx,[esi+8]
;
        pop esi
        pop ebx
        ret
ReadLinearTbyte Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteLinearByte
;
;               DESCRIPTION:    write one byte of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;                               AL              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public WriteLinearByte

WriteLinearByte Proc near
        push eax
        push ebx
        push ecx
        push edx
        push esi
;
        lea esi,[ebp].req_buf
        mov [esi],al
        mov ecx,1
        call WriteLinear
;
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
WriteLinearByte Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteLinearWord
;
;               DESCRIPTION:    Write one word of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;                               AX              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public WriteLinearWord

WriteLinearWord Proc near
        push eax
        push ebx
        push ecx
        push edx
        push esi
;
        lea esi,[ebp].req_buf
        mov [esi],ax
        mov ecx,2
        call WriteLinear
;
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
WriteLinearWord Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteLinearDword
;
;               DESCRIPTION:    Write one dword of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;                               EAX             DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public WriteLinearDword

WriteLinearDword        Proc near
        push eax
        push ebx
        push ecx
        push edx
        push esi
;
        lea esi,[ebp].req_buf
        mov [esi],eax
        mov ecx,4
        call WriteLinear
;
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
WriteLinearDword        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteLinearFword
;
;               DESCRIPTION:    Write one fword of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;                               DX:EAX          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public WriteLinearFword

WriteLinearFword        Proc near
        push eax
        push ebx
        push ecx
        push edx
        push esi
;
        lea esi,[ebp].req_buf
        mov [esi],eax
        mov [esi+4],dx
        mov ecx,6
        call WriteLinear
;
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
WriteLinearFword        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteLinearQword
;
;               DESCRIPTION:    Write one qword of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;                               EDX:EAX         DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public WriteLinearQword

WriteLinearQword        Proc near
        push eax
        push ebx
        push ecx
        push edx
        push esi
;
        lea esi,[ebp].req_buf
        mov [esi],eax
        mov [esi+4],edx
        mov ecx,8
        call WriteLinear
;
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
WriteLinearQword        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteLinearTbyte
;
;               DESCRIPTION:    Write one tbyte of data
;
;               PARAMETERS:     EBP             CPU
;                               EDI:EBX         LINEAR ADDRESS
;                               CX:EDX:EAX      DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public WriteLinearTbyte

WriteLinearTbyte        Proc near
        push eax
        push ebx
        push ecx
        push edx
        push esi
;
        lea esi,[ebp].req_buf
        mov [esi],eax
        mov [esi+4],edx
        mov [esi+8],cx
        mov ecx,10
        call WriteLinear
;
        pop esi
        pop edx
        pop ecx
        pop ebx
        pop eax
        ret
WriteLinearTbyte        Endp

        END
