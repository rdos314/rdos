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
; PCSHUT.ASM
; PC platform kernel "panic" module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.def

IA32_EFER       = 0C0000080h

    .686p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;
; switch struc. Should be first.
;

pm_data   pmode_switch_struc <>

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
;           NAME:           Switch monitor
;
;           DESCRIPTION:    Switch to monitor
;
;           PARAMETERS:     EDX         Linear base of code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gdt0:
    dw 20h-1        ; real mode GDT
    dd 00000000h
    dw 0
gdt8:               ; 16-bit data selector for real mode
    dw 0FFFFh
    dd 92000000h
    dw 0
gdt10:              ; 16-bit code selector for real mode
    dw 0FFFFh
    dd 9A000000h
    dw 0
gdt18:              ; code selector for protected mode
    dw 0FFFFh
    dd 9A000000h
    dw 0
idt20:              ; real mode IDT
    dw 3FFh
    dd 00000000h
    dw 0

switch_monitor:
    cli
    mov ax,flat_sel
    mov ds,ax
;
    mov edi,OFFSET Gdt0 + 2
    mov eax,edx
    add eax,OFFSET Gdt0
    mov dword ptr ds:[edx+edi],eax
;   
    mov edi,OFFSET gdt10  + 2
    or dword ptr ds:[edx+edi],edx
;
    mov edi,OFFSET gdt18 + 2
    or dword ptr ds:[edx+edi],edx
;        
    mov edi,OFFSET real_seg
    mov eax,edx
    shr eax,4
    mov ds:[edx+edi],ax
;    
    db 0EAh
    dw OFFSET prot_enter_start
    dw shutdown_code_sel
    
prot_enter_start:
    mov eax,cr0
    and eax,7FFFFFFFh
    mov cr0,eax
;
    mov ax,cs:pm_flags
    test ax,PM_FLAG_EFER
    jz prot_efer_ok
;
    mov ecx,IA32_EFER
    rdmsr
    and eax,0FFFFFEFFh   
    wrmsr

prot_efer_ok:
    lgdt fword ptr cs:gdt0
    lidt fword ptr cs:idt20
;
    db 0EAh
    dw OFFSET real_enter
    dw 10h

real_enter:
    mov ax,8
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov ax,1000h
    mov sp,ax
;
    mov eax,cr0
    and al,NOT 1
    mov cr0,eax
;
    db 0EAh         ; jmp to real-mode selector
    dw OFFSET real_start
real_seg dw 0
    
real_start:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov sp,1000h
;   
    mov ax,cs:pm_flags
    test ax,PM_FLAG_VIDEO
    jz real_video_done
;    
    call SetupBiosPic
    call SetupBiosPit
    mov ax,3
    int 10h
    cli
;
    mov al,-1
    out 21h,al

real_video_done:
    mov bx,cs:pm_flags
    mov eax,cr4
    and al,NOT 20h
    test bx,PM_FLAG_PAE
    jz real_pae_done
;
    or al,20h

real_pae_done:
    mov cr4,eax
;
    mov eax,cs:pm_cr3
    mov cr3,eax
;    
    db 66h
    lgdt fword ptr cs:pm_gdtr
    db 66h
    lidt fword ptr cs:pm_idtr
;
    mov eax,cr0
    or al,1
    mov cr0,eax
;    
    mov ax,cs:pm_ss
    mov ss,ax
    mov esp,cs:pm_esp
;    
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
;    
    movzx eax,cs:pm_cs
    push eax
    mov eax,cs:pm_eip
    push eax
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateDataSelector
;
;           DESCRIPTION:    Create 32-bit data selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDataSelector       PROC near
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
    jae create_data32_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [bx+6],cx
    jmp create_data32_done

create_data32_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,92h
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [bx+6],cx

create_data32_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
CreateDataSelector       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCodeSelector
;
;           DESCRIPTION:    Create 32-bit code selector
;
;           PARAMETERS:     BX              DESCRIPTOR
;                           EDX             BASE
;                           ECX             LIMIT
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateCodeSelector       PROC near
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
    jae create_code32_big
;
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,40h
    mov [bx+6],cx
    jmp create_code32_done

create_code32_big:
    shr ecx,12
    mov [bx],cx
    mov [bx+2],edx
    shl al,5
    or al,9Ah
    xchg al,[bx+5]
    shr ecx,16
    and cx,0Fh
    or ch,al
    or cl,0C0h
    mov [bx+6],cx

create_code32_done:
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
CreateCodeSelector       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartDebug
;
;           DESCRIPTION:    Start debug device
;
;           PARAMETERS:     edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartDebug Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ecx,[edx].len
    sub ecx,SIZE rdos_header
    add edx,SIZE rdos_header
    mov esi,edx
    mov ebx,[esi].dev32_size
    mov edi,esi
    add edi,SIZE device32_header

sdParamLoop:
    mov al,[edi]
    inc edi
    or al,al
    jnz sdParamLoop
;       
    mov ecx,[esi].dev32_code_size
    add edx,ebx
    mov bx,[esi].dev32_code_sel
    mov bp,bx
    call CreateCodeSelector
;
    xor bx,bx
    add edx,ecx
    mov ecx,[esi].dev32_data_size
    or ecx,ecx
    jz sdDataSelOk
;
    mov bx,[esi].dev32_data_sel
    call CreateDataSelector

sdDataSelOk:
    mov edi,OFFSET switch_monitor
    mov ax,ds
    mov es,ax
    mov eax,[esi].dev32_init_ip
    mov ds,bx
    mov ebx,cs
    push ebx
    mov ebx,OFFSET sdRet
    push ebx
    push ebp
    push eax
    retf32

sdRet:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
StartDebug   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SearchDebugAdapter
;
;           DESCRIPTION:    Search for debug adapter
;
;           PARAMETERS:     edx         base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SearchDebugAdapter Proc near
    push ds
    push ax
    push bx
    push edx
    mov ax,flat_sel
    mov ds,ax

sdaLoop:
    mov ax,[edx].typ
    cmp ax,RdosDevice32
    jne sdaNext
;       
    push edx
    add edx,SIZE rdos_header
    mov dx,[edx].dev32_code_sel
    cmp dx,kdebug_code_sel
    pop edx
    jne sdaNext
;    
    call StartDebug

sdaNext:
    cmp ax,RdosEnd
    je sdaDone
;    
    add edx,[edx].len
    jmp sdaLoop

sdaDone:
    pop edx
    pop bx
    pop ax
    pop ds
    ret
SearchDebugAdapter Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    Initialize module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    push ds
    pushad
;    
    mov ax,system_data_sel
    mov ds,ax
    mov cx,ds:rom_modules
    mov bx,OFFSET rom_adapters

sdAdapterLoop:
    mov edx,[bx].adapter_base
    call SearchDebugAdapter
    add bx,SIZE adapter_typ
    loop sdAdapterLoop   
;
    popad
    pop ds
    ret
init    Endp

code    ENDS

.186

END init
