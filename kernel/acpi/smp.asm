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
; smp.asm
; smp module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\port.def
INCLUDE ..\os\system.def
INCLUDE apic.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\core.inc
INCLUDE ..\acpi\acpitab.inc
INCLUDE ..\os\realmon.def
INCLUDE ..\bios\vbe.inc

INCLUDE ..\user.def
INCLUDE ..\user.inc

ipause   MACRO
    db 0F3h
    db 90h
    ENDM

IA32_EFER       = 0C0000080h

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

data    SEGMENT byte public 'DATA'

mp_processor_sign   DD ?

vbe_desired         DW ?
vbe_width           DW ?
vbe_height          DW ?
vbe_lfb             DD ?
vbe_mode            DW ?
vbe_scan_size       DW ?

data    ENDS

code    SEGMENT byte public use32 'CODE'

    assume cs:code

    extern GetApicTable:near
    extern SetupLocalApic:near
    extern DelayMs:near
    extern GetValue:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   Tables
;
;               DESCRIPTION:    GDT for protected mode initialization of AP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0000:0F80h

table_start:

gdt0:
    dw 0
    dd 0
    dw 0
gdt8:
    dw 30h-1
    dd 92000F80h
    dw 0
gdt10:
    dw 0FFFFh
    dd 9A001400h
    dw 0
gdt18:
    dw 0FFFFh
    dd 92000000h
    dw 0CFh
gdt20:
    dw 0FFFFh
    dd 92001800h
    dw 0
gdt28:
    dw 0FFFFh
    dd 9A000000h
    dw 0AFh

table_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RealMode
;
;               DESCRIPTION:    Real mode AP processor init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0100:0000. It should contain no near jumps!

real_start:    
    db 0FAh             ; cli
;
    db 0B0h, 0Fh        ; mov al,0Fh
    db 0E6h, 70h        ; out 70h,al
    db 0EBh, 0          ; jmp short $+2
;
    db 32h, 0C0h        ; xor al,al
    db 0E6h, 71h        ; out 71h,al
    db 0EBh, 0          ; jmp short $+2
;
    db 33h, 0C0h        ; xor ax,ax
    db 8Eh, 0D8h        ; mov ds,ax
;    
    db 0BBh, 88h, 0Fh   ; mov bx,0F88h
    db 0Fh, 1, 17h      ; lgdt fword ptr ds:[bx]
;
    db 0Fh, 20h, 0C0h   ; mov eax,cr0
    db 0Ch, 1           ; or al,1
    db 0Fh, 22h, 0C0h   ; mov cr0,eax
;
    db 0EAh             ; jmp 10:0
    dw 0
    dw 10h

real_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           VbeInfo
;
;               DESCRIPTION:    Real get VBE info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0100:0000. It should contain no near jumps!

; this data is located at 1900.

vbe_req_sign = 5A4Fh
vbe_ack_sign = 65A4h

vbe_info_struc  STRUC

vbe_sign    DW ?
vbe_op      DW ?
vbe_bx      DW ?
vbe_cx      DW ?
vbe_res     DW ?
vbe_buf     DW ?

vbe_info_struc  ENDS

vbe_info_start: 
    db 0B8h, 90h, 1     ; mov ax,190h
    db 8Eh, 0C0h        ; mov es,ax
    db 0BFh
    dw OFFSET vbe_buf   ; mov di,OFFSET vbe_buf
    db 0B8h, 40h, 1     ; mov ax,140h
    db 8Eh, 0D0h        ; mov ss,ax
    db 0BCh, 0, 4       ; mov sp,400h

vbe_loop:
    db 26h, 0A1h
    dw OFFSET vbe_op    ; mov ax,es:vbe_op
    db 26h, 8Bh, 1Eh
    dw OFFSET vbe_bx    ; mov bx,es:vbe_bx
    db 26h, 8Bh, 0Eh
    dw OFFSET vbe_cx    ; mov cx,es:vbe_cx
    db 0CDh, 10h        ; int 10h
    db 26h, 0A3h
    dw OFFSET vbe_res   ; mov es:vbe_res,ax
    db 26h, 0C7h, 6
    dw OFFSET vbe_sign   
    dw vbe_ack_sign     ; mov es:vbe_sign,vbe_ack_sign

vbe_wait:
    db 26h, 0A1h 
    dw OFFSET vbe_sign  ; mov ax,es:vbe_sign
    db 3Dh
    dw vbe_req_sign     ; cmp ax,vbe_req_sign
    db 75h, 0F7h        ; jne short vbe_wait
;
    db 26h, 0C7h, 6
    dw OFFSET vbe_res
    dw 0FFFFh           ; mov es:vbe_res,-1
    db 26h, 0A1h
    dw OFFSET vbe_op    ; mov ax,es:vbe_op
    db 83h, 0F8h, 0FFh  ; cmp ax,-1
    db 75h, 0CCh        ; jne short vbe_loop
;
    db 0FAh             ; cli
    db 0B0h, 0Fh        ; mov al,0Fh
    db 0E6h, 70h        ; out 70h,al
    db 0EBh, 0          ; jmp short $+2
;
    db 32h, 0C0h        ; xor al,al
    db 0E6h, 71h        ; out 71h,al
    db 0EBh, 0          ; jmp short $+2
;
    db 33h, 0C0h        ; xor ax,ax
    db 8Eh, 0D8h        ; mov ds,ax
;    
    db 0BBh, 88h, 0Fh   ; mov bx,0F88h
    db 0Fh, 1, 17h      ; lgdt fword ptr ds:[bx]
;
    db 0Fh, 20h, 0C0h   ; mov eax,cr0
    db 0Ch, 1           ; or al,1
    db 0Fh, 22h, 0C0h   ; mov cr0,eax
;
    db 0EAh             ; jmp 10:0
    dw 0
    dw 10h

vbe_info_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ProtMode
;
;               DESCRIPTION:    Unpaged, protected mode AP processor init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 01400. It should contain no near jumps!
; offset 0BCh
    
prot_start:
    db 0B8h, 18h, 0     ; mov ax,18h
    db 8Eh, 0D8h        ; mov ds,ax
    db 8Eh, 0C0h        ; mov es,ax
    db 8Eh, 0E0h        ; mov fs,ax
    db 8Eh, 0E8h        ; mov gs,ax
    db 8Eh, 0D0h        ; mov ss,ax
    db 0BCh, 0, 0Fh     ; mov sp,0F00h
;
    db 0B8h, 20h, 0     ; mov ax,20h
    db 8Eh, 0C0h        ; mov es,ax
;    
    db 66h, 26h, 0A1h
    dw OFFSET ap_cr4    ; mov eax,es:ap_cr4
    db 0Fh, 22h, 0E0h   ; mov cr4,eax
;
    db 66h, 26h, 0A1h
    dw OFFSET ap_cr3    ; mov eax,es:ap_cr3
    db 0Fh, 22h, 0D8h   ;mov cr3,eax
;    
    db 66h, 26h, 0Fh, 1, 16h
    dw OFFSET ap_gdt    ; lgdt fword ptr es:ap_gdt
;    
    db 66h, 26h, 0Fh, 1, 1Eh
    dw OFFSET ap_idt    ; lidt fword ptr es:ap_idt
;
    db 66h, 26h, 8Bh, 16h
    dw OFFSET ap_stack_offset  ; mov edx,es:ap_stack_offset
    db 26h, 8Bh, 1Eh
    dw OFFSET ap_stack_sel     ; mov bx,es:ap_stack_sel
;    
    db 66h, 26h, 0A1h
    dw OFFSET ap_cr0    ; mov eax,es:ap_cr0
    db 0Fh, 22h, 0C0h   ; mov cr0,eax
;
    db 0EAh
    dw OFFSET ApInit
    dw SEG code

prot_end:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           RtMode
;
;               DESCRIPTION:    Unpaged, protected mode AP processor init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 01400. It should contain no near jumps!
    
rt_start:
    db 33h, 0C0h        ; xor ax,ax
    db 8Eh, 0D8h        ; mov ds,ax
    db 8Eh, 0E0h        ; mov fs,ax
    db 8Eh, 0E8h        ; mov gs,ax
;
    db 0B8h, 18h, 0     ; mov ax,18h
    db 8Eh, 0D0h        ; mov ss,ax
    db 66h, 0BCh
    dd OFFSET rt_end - rt_start + 1400h + 10h
                        ; mov esp,OFFSET rt_end - rt_start + 1400h + 10h
;
    db 0B8h, 20h, 0     ; mov ax,20h
    db 8Eh, 0C0h        ; mov es,ax
;    
    db 66h, 0B8h
    dd 12345678h        ; mov eax,12345678h
    db 66h, 26h, 87h, 6
    dw OFFSET ap_cr4    ; xchg eax,es:ap_cr4
    db 0Ch, 20h         ; or al,20h
    db 0Fh, 22h, 0E0h   ; mov cr4,eax
;
    db 66h, 0B9h
    dd IA32_EFER        ; mov ecx,IA32_EFER
    db 0Fh, 32h         ; rdmsr
    db 66h, 0Dh
    dd 101h             ; or eax,101h
    db 0Fh, 30h         ; wrmsr
;
    db 66h, 26h, 0A1h
    dw OFFSET ap_cr3    ; mov eax,es:ap_cr3
    db 0Fh, 22h, 0D8h   ; mov cr3,eax
;    
    db 0Fh, 22h, 0C0h   ; mov eax,cr0
    db 66h, 0Dh
    dd 80010008h        ; or eax,80010008h
    db 0Fh, 22h, 0C0h   ; mov cr0,eax
;
    db 66h, 26h, 8Bh, 16h
    dw OFFSET ap_stack_offset
                        ; mov edx,es:ap_stack_offset
;
    db 33h, 0C0h        ; xor ax,ax
    db 8Eh, 0C0h        ; mov es,ax
;
    db 0EAh
    dw OFFSET rt_init64 - rt_start + 1400h
    dw 28h

rt_init64:
    db 48h  ; mov rbx,0FFFFFF8000201000h
    db 0BBh
    dd 201000h
    dd 0FFFFFF80h
;  
    db 48h   ; mov rsp,rbx
    db 8Bh
    db 0E3h
;
    db 48h  ; mov rbx,0FFFFFF8000000000h
    db 0BBh
    dd 0
    dd 0FFFFFF80h
;
    db 89h  ; mov [rbx+10],edx
    db 53h
    db 0Ah
;
    db 48h   ; mov rax,[rbx+2]
    db 8Bh
    db 43h
    db 2
;
    db 48h   ; add rbx,rax
    db 3
    db 0D8h
;
    db 53h  ; push rbx
;
    db 0C3h ; ret

rt_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   Paging
;
;               DESCRIPTION:    Paging variables for AP initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 01800h. The code is relative to GDT selector 20h

page_struc  STRUC

ap_stack_offset DD ?
ap_stack_sel    DW ?
ap_cr0          DD ?
ap_cr3          DD ?
ap_cr4          DD ?
ap_gdt          DB 6 DUP(?)
ap_idt          DB 6 DUP(?)

page_struc  ENDS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           ApInit
;
;               DESCRIPTION:    Paged entry-point for AP initialization
;
;               PARAMETERS:     BX:EDX      Stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ApInit:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
;
    mov ss,bx
    mov esp,edx
;
    mov ax,SEG data
    mov ds,ax
    mov eax,12345678h
    mov ds:mp_processor_sign,eax
;
    ShutdownCore

   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           GetId
;
;               DESCRIPTION:    Get own ID
;
;       RETURNS:        EDX     Apic ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_id_name    DB 'Get Apic ID',0

get_id  Proc far
    push ds
    push eax
;    
    mov eax,apic_mem_sel
    mov ds,eax
    mov edx,ds:APIC_ID
    shr edx,24
;
    pop eax
    pop ds
    ret
get_id Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendInit
;
;               DESCRIPTION:    Send init request
;
;       PARAMETERS:     EDX     Destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInit Proc near
    push ds
    push eax
    push edx
;    
    shl edx,24
    mov ax,apic_mem_sel
    mov ds,ax
    mov ds:APIC_ICR+10h,edx
;
    mov eax,0C500h
    mov ds:APIC_ICR,eax
;    
    mov ax,1
    call DelayMs
;
    mov eax,08500h
    mov ds:APIC_ICR,eax
;
    mov ax,20
    call DelayMs
;
    pop edx
    pop eax
    pop ds    
    ret
SendInit Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SendStartup
;
;               DESCRIPTION:    Send startup request
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendStartup Proc near
    push ds
    push eax
    push ecx
    push edx
;        
    shl edx,24
    mov cx,apic_mem_sel
    mov ds,cx
    mov ds:APIC_ICR+10h,edx
;
    mov ah,46h
    movzx eax,ax
    mov ds:APIC_ICR,eax
;
    mov ax,1
    call DelayMs
;
    pop edx
    pop ecx
    pop eax
    pop ds    
    ret
SendStartup Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SendNmi
;
;       DESCRIPTION:    Send NMI request
;
;       PARAMETERS:     FS      Destination processor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_nmi_name   DB 'Send NMI', 0

send_nmi Proc far
    push ds
    push eax
    push edx
;    
    mov edx,fs:cs_apic
    shl edx,24
    mov eax,apic_mem_sel
    mov ds,eax
    mov ds:APIC_ICR+10h,edx
;
    mov eax,4400h
    mov ds:APIC_ICR,eax
;
    pop edx
    pop eax
    pop ds
    ret
send_nmi Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SendLockedInt
;
;       DESCRIPTION:    Send int to processor. Scheduler lock must be taken
;
;       PARAMETERS:     FS      Processor selector
;                       AL      Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_locked_int_name    DB 'Send Locked Int',0

send_locked_int  Proc far
    push ds
    push eax
    push ecx
    push edx
;    
    mov edx,fs:cs_apic
    shl edx,24
    mov ecx,apic_mem_sel
    mov ds,ecx

siLoop:
    mov ecx,ds:APIC_ICR
    test cx,1000h
    jz siDo
;
    ipause
    jmp siLoop

siDo:    
    mov ds:APIC_ICR+10h,edx
;
    mov ah,40h
    movzx eax,ax
    mov ds:APIC_ICR,eax
;
    pop edx
    pop ecx
    pop eax
    pop ds    
    ret
send_locked_int  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartCore
;
;       DESCRIPTION:    Start a new AP core
;
;       PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_core_name DB 'Start Core', 0

start_core   Proc far
    test fs:cs_flags,CS_FLAG_SHUTDOWN
    jz start_core_normal
;
    lock and fs:cs_flags,NOT CS_FLAG_SHUTDOWN

start_core_normal:    
    lock or fs:cs_flags,CS_FLAG_ACTIVE
    SendNmi
    ret
start_core   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ShutdownCore
;
;       DESCRIPTION:    Shutdown AP core
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

shutdown_core_name DB 'Shutdown Core', 0

shutdown_core:
    cli
    call SetupLocalApic
;
    GetCore
    lock and fs:cs_flags,NOT CS_FLAG_ACTIVE
;
    wbinvd
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax

sdcLoop:    
    cli
    mov ax,enter_c3_nr
    IsValidOsGate
    jc sdcHlt
;
;    EnterC3        
;    jmp sdcCheck

sdcHlt:    
    hlt

sdcCheck:    
    GetCore
    test fs:cs_flags,cS_FLAG_ACTIVE
    jz sdcLoop
;
    mov ax,start_preempt_timer_nr
    IsValidOsGate
    jc sdcCombined
;
    StartPreemptTimer
    jmp sdcDone

sdcCombined:
    StartSysPreemptTimer

sdcDone:
    RunApCore
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           BootRealtimeCore
;
;               DESCRIPTION:    Boot realtime core
;
;               PARAMETERS:     FS      Processor sel
;                               EBX     CR3
;                               ES:EDI  Realtime startup proc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

boot_realtime_core_name DB 'Boot Realtime Core', 0

boot_realtime_core    Proc far
    push ds
    push es
    push fs
    pushad
;
    mov esi,ebx
;
    xor edx,edx
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,63h
    SetPageEntry
;    
    mov edx,1000h
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,1063h
    SetPageEntry
;
    mov eax,SEG data
    mov ds,eax
;
    mov eax,flat_sel
    mov es,eax
;    
    mov edi,1800h
    mov eax,cr0
    mov es:[edi].ap_cr0,eax
    mov es:[edi].ap_cr3,esi
;
    mov eax,cr4
    mov es:[edi].ap_cr4,eax
;
    GetApicId
    mov es:[edi].ap_stack_offset,edx
;
    mov edi,0F80h
    mov esi,OFFSET table_start
    mov ecx,OFFSET table_end - OFFSET table_start
    rep movs byte ptr es:[edi],cs:[esi]
;
    mov edi,1000h
    mov esi,OFFSET real_start
    mov ecx,OFFSET real_end - OFFSET real_start
    rep movs byte ptr es:[edi],cs:[esi]
;
    mov edi,1400h
    mov esi,OFFSET rt_start
    mov ecx,OFFSET rt_end - OFFSET rt_start
    rep movs byte ptr es:[edi],cs:[esi]
;
    mov edi,1800h
;
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    mov al,0Ah
    out 71h,al
    jmp short $+2
;
    mov edx,fs:cs_apic
    call SendInit
;
    mov eax,es:[edi].ap_cr4
    cmp eax,12345678h
    je brcDone
;    
    mov al,1
    call SendStartup
    
    mov ecx,250

brcLoop1:
    mov eax,es:[edi].ap_cr4
    cmp eax,12345678h
    je brcDone
;    
    mov ax,1
    call DelayMs
    loop brcLoop1
;
    mov al,1    
    call SendStartup
;    
    mov ecx,250

brcLoop2:
    mov eax,es:[edi].ap_cr4
    cmp eax,12345678h
    je brcDone
;    
    mov ax,1
    call DelayMs
    loop brcLoop2

brcDone:
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    xor al,al
    out 71h,al
    jmp short $+2
;
    pop ebx
    pop eax
    mov edx,1000h
    SetPageEntry
;
    pop ebx
    pop eax
    xor edx,edx
    SetPageEntry
;
    popad
    pop fs
    pop es
    pop ds
    ret
boot_realtime_core   Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           BootCore
;
;       DESCRIPTION:    Boot a new AP core, but don't activate it.
;
;       PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BootCore    Proc near
    push ds
    push es
    pushad
;
    xor edx,edx
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,63h
    SetPageEntry
;    
    mov edx,1000h
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,1063h
    SetPageEntry
;
    mov eax,flat_sel
    mov es,eax
    mov eax,cs
    mov ds,eax
;
    mov edi,0F80h
    mov esi,OFFSET table_start
    mov ecx,OFFSET table_end - OFFSET table_start
    rep movsb
;
    mov edi,1000h
    mov esi,OFFSET real_start
    mov ecx,OFFSET real_end - OFFSET real_start
    rep movsb
;
    mov edi,1400h
    mov esi,OFFSET prot_start
    mov ecx,OFFSET prot_end - OFFSET prot_start
    rep movsb
;
    mov eax,SEG data
    mov ds,eax
;    
    mov edi,1800h
    mov eax,cr0
    mov es:[edi].ap_cr0,eax
    mov eax,cr3
    mov es:[edi].ap_cr3,eax
;
    mov eax,cr4
    mov es:[edi].ap_cr4,eax
;
    db 66h
    sidt fword ptr es:[edi].ap_idt
;    
    mov ax,fs:cs_gdt_size
    dec ax
    mov word ptr es:[edi].ap_gdt,ax
    mov eax,fs:cs_gdt_base
    mov dword ptr es:[edi].ap_gdt+2,eax
;
    mov eax,fs:cs_stack_offset
    mov es:[edi].ap_stack_offset,eax
    mov ax,fs:cs_stack_sel
    mov es:[edi].ap_stack_sel,ax
;
    mov ebx,467h
    mov ax,0
    mov es:[ebx],ax
    mov ax,100h
    mov es:[ebx+2],ax
;
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    mov al,0Ah
    out 71h,al
    jmp short $+2
;
    mov ds:mp_processor_sign,0
;
    mov edx,fs:cs_apic
    call SendInit
;
    mov eax,ds:mp_processor_sign
    cmp eax,12345678h
    je bcDone
;    
    mov al,1
    call SendStartup
    
    mov ecx,250

bcLoop1:
    mov eax,ds:mp_processor_sign
    cmp eax,12345678h
    je bcDone
;    
    mov ax,1
    call DelayMs
    loop bcLoop1
;
    mov al,1    
    call SendStartup
;    
    mov ecx,250

bcLoop2:
    mov eax,ds:mp_processor_sign
    cmp eax,12345678h
    je bcDone
;    
    mov ax,1
    call DelayMs
    loop bcLoop2

bcDone:
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    xor al,al
    out 71h,al
    jmp short $+2
;
    pop ebx
    pop eax
    mov edx,1000h
    SetPageEntry
;
    pop ebx
    pop eax
    xor edx,edx
    SetPageEntry
;
    popad
    pop es
    pop ds
    ret
BootCore   Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleVbe
;
;       DESCRIPTION:    Handle VBE session
;
;       PARAMETERS:     BX      Requests width
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vesa_id DB 'VESA'

HandleVbe    Proc near
    push ds
    push es
    push fs
    pushad
;
    mov eax,flat_sel
    mov ds,eax
    mov eax,SEG data
    mov fs,eax
    mov fs:vbe_width,0
    mov fs:vbe_height,0
    mov fs:vbe_lfb,0
    mov fs:vbe_mode,0
    mov fs:vbe_scan_size,0
;
    mov esi,1900h
    mov ax,ds:[esi].vbe_res
    cmp ax,4Fh
    jne hvDone
;
    add esi,OFFSET vbe_buf
    mov eax,dword ptr ds:[esi].vesa_name
    cmp eax,dword ptr cs:vesa_id
    jne hvDone
;
    movzx eax,word ptr ds:[esi].vesa_modes+2
    shl eax,4
    movzx esi,word ptr ds:[esi].vesa_modes
    add esi,eax
;
    push esi
    xor ecx,ecx

hvCountLoop:
    mov ax,ds:[esi]
    cmp ax,-1
    je hvCountOk
;
    or ax,ax
    je hvCountOk
;
    add esi,2
    inc ecx
    jmp hvCountLoop

hvCountOk:
    pop esi
;
    push ecx
    mov eax,ecx
    shl eax,1
    AllocateSmallGlobalMem
;
    xor edi,edi
    rep movs word ptr es:[edi],ds:[esi]
;
    pop ecx
;
    xor edi,edi

hvGetLoop:
    mov esi,1900h
    mov ds:[esi].vbe_op,4F01h
    mov bx,es:[edi]
    mov ds:[esi].vbe_cx,bx
    mov ds:[esi].vbe_sign,vbe_req_sign
;
    push ecx    
    mov ecx,250

hvWaitLoop:
    mov ax,ds:[esi].vbe_sign
    cmp ax,vbe_ack_sign
    je hvGetOk
;    
    mov ax,1
    call DelayMs
    loop hvWaitLoop

hvGetOk:
    pop ecx
;
    mov esi,1900h
    add esi,OFFSET vbe_buf
    mov dx,ds:[esi].vmi_mode_attrib
    and dx,MODE_ATTRIB_REQUIRED
    cmp dx,MODE_ATTRIB_REQUIRED
    jne hvGetNext
;
    mov dl,ds:[esi].vmi_memory_model
    cmp dl,MODEL_DIRECT
    jne hvGetNext
;
    pushad
    movzx ax,ds:[esi].vmi_bits_per_pixel
    mov cx,ds:[esi].vmi_x_pixels
    mov dx,ds:[esi].vmi_y_pixels
;
    cmp ax,32
    jne hvSkip
;
    mov bp,fs:vbe_desired
    cmp bp,1
    je hvHighest

hvPart:
    cmp bp,cx
    je hvSet
;
    mov eax,ds:[esi].vmi_lfb
    or eax,eax
    jz hvSkip
;    
    cmp bp,fs:vbe_width
    je hvSet
    jmp hvCmp

hvHighest:
    mov eax,ds:[esi].vmi_lfb
    or eax,eax
    jz hvSkip

hvCmp:
    cmp cx,fs:vbe_width
    jc hvSkip

hvSet:
    mov eax,ds:[esi].vmi_lfb
    mov fs:vbe_lfb,eax
    mov fs:vbe_width,cx
    mov fs:vbe_height,dx
    mov ax,ds:[esi].vmi_scan_lines
    mov fs:vbe_scan_size,ax
    mov fs:vbe_mode,bx

hvSkip:
    popad

hvGetNext:
    add edi,2
    sub ecx,1
    jnz hvGetLoop
;
    mov bx,fs:vbe_mode
    mov esi,1900h
    mov ds:[esi].vbe_op,4F02h
    mov ds:[esi].vbe_bx,bx
    mov ds:[esi].vbe_sign,vbe_req_sign
;
    push ecx    
    mov ecx,250

hvSetLoop:
    mov ax,ds:[esi].vbe_sign
    cmp ax,vbe_ack_sign
    je hvSetOk
;    
    mov ax,1
    call DelayMs
    loop hvSetLoop

hvSetOk:
    pop ecx
;
    mov ds:[esi].vbe_op,-1
    mov ds:[esi].vbe_sign,vbe_req_sign
;
    mov ax,1
    call DelayMs
;
    mov eax,system_data_sel
    mov es,eax 
;
    mov ax,fs:vbe_width
    mov es:efi_width,ax
;
    mov ax,fs:vbe_height
    mov es:efi_height,ax
;
    movzx eax,fs:vbe_scan_size
    mov es:efi_scan_size,eax
;
    movzx edx,fs:vbe_scan_size
    movzx eax,fs:vbe_height
    mul edx
    shl eax,2
    AllocateBigLinear
;
    mov eax,fs:vbe_lfb
    xor ebx,ebx
    mov al,6Bh
    mov es:efi_lfb,edx
    mov es:mon_fixed_lfb,edx
;
    mov es:fixed_lfb_phys,eax
    mov es:fixed_lfb_phys+4,ebx
    mov es:fixed_lfb_linear,edx

hvSetupLoop:
    SetPageEntry
    add edx,1000h
    add eax,1000h
    loop hvSetupLoop
;
    mov es:efi_fore_col,0FFFFFFh
    mov es:efi_back_col,0

hvDone:
    popad
    pop fs
    pop es
    pop ds
    ret
HandleVbe   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           BootVbeCore
;
;       DESCRIPTION:    Boot a new AP core to collect VBE info
;
;       PARAMETERS:     FS      Core selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BootVbeCore    Proc near
    push ds
    push es
    pushad
;
    xor edx,edx
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,63h
    SetPageEntry
;    
    mov edx,1000h
    GetPageEntry
    push eax
    push ebx
;    
    mov eax,1063h
    SetPageEntry
;
    mov eax,flat_sel
    mov es,eax
    mov eax,cs
    mov ds,eax
;
    mov edi,0F80h
    mov esi,OFFSET table_start
    mov ecx,OFFSET table_end - OFFSET table_start
    rep movsb
;
    mov edi,1000h
    mov esi,OFFSET vbe_info_start
    mov ecx,OFFSET vbe_info_end - OFFSET vbe_info_start
    rep movsb
;
    mov edi,1400h
    mov esi,OFFSET prot_start
    mov ecx,OFFSET prot_end - OFFSET prot_start
    rep movsb
;
    mov eax,SEG data
    mov ds,eax
;    
    mov edi,1800h
    mov eax,cr0
    mov es:[edi].ap_cr0,eax
    mov eax,cr3
    mov es:[edi].ap_cr3,eax
;
    mov eax,cr4
    mov es:[edi].ap_cr4,eax
;
    db 66h
    sidt fword ptr es:[edi].ap_idt
;    
    mov ax,fs:cs_gdt_size
    dec ax
    mov word ptr es:[edi].ap_gdt,ax
    mov eax,fs:cs_gdt_base
    mov dword ptr es:[edi].ap_gdt+2,eax
;
    mov eax,fs:cs_stack_offset
    mov es:[edi].ap_stack_offset,eax
    mov ax,fs:cs_stack_sel
    mov es:[edi].ap_stack_sel,ax
;
    mov edi,1900h
    mov es:[edi].vbe_sign,vbe_req_sign
    mov es:[edi].vbe_op,4F00h
    mov es:[edi].vbe_cx,0
;
    mov ebx,467h
    mov ax,0
    mov es:[ebx],ax
    mov ax,100h
    mov es:[ebx+2],ax
;
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    mov al,0Ah
    out 71h,al
    jmp short $+2
;
    mov edx,fs:cs_apic
    call SendInit
;
    mov ax,es:[edi].vbe_sign
    cmp ax,vbe_ack_sign
    je bvcDone
;    
    mov al,1
    call SendStartup
    
    mov ecx,250

bvcLoop1:
    mov ax,es:[edi].vbe_sign
    cmp ax,vbe_ack_sign
    je bvcDone
;    
    mov ax,1
    call DelayMs
    loop bvcLoop1
;
    mov al,1    
    call SendStartup
;    
    mov ecx,250

bvcLoop2:
    mov ax,es:[edi].vbe_sign
    cmp ax,vbe_ack_sign
    je bvcDone
;    
    mov ax,1
    call DelayMs
    loop bvcLoop2

bvcDone:
    call HandleVbe
;
    mov al,0Fh
    out 70h,al
    jmp short $+2
;
    xor al,al
    out 71h,al
    jmp short $+2
;
    pop ebx
    pop eax
    mov edx,1000h
    SetPageEntry
;
    pop ebx
    pop eax
    xor edx,edx
    SetPageEntry
;
    popad
    pop es
    pop ds
    ret
BootVbeCore   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DoCreteCore
;
;       DESCRIPTION:    Create a CPU core
;
;       RETURNS:        FS          Processor sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoCreateCore   Proc near    
    push es
    push eax
    push cx
    push edx
;    
    CreateCoreGdt
    CreateCore
    mov es:cs_gdt_base,edx
    mov es:cs_gdt_size,cx
    mov cx,es
    mov fs,cx
;
    pop edx
    pop cx
    pop eax
    pop es
    ret
DoCreateCore   Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           start smp
;
;               DESCRIPTION:    Startup application cores
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

max_cores_name  DB 'CORES', 0
vbe_name        DB 'VBE', 0

    public start_smp

start_smp    Proc near
    push ds
    push es
    pushad
;    
    mov eax,cs
    mov es,eax
    mov edi,OFFSET vbe_name
    call GetValue
    mov bx,ax
    mov eax,SEG data
    mov es,eax
    mov es:vbe_desired,bx
;
    mov eax,cs
    mov es,eax
    mov edi,OFFSET max_cores_name
    call GetValue
    mov si,ax
    call GetApicTable
;
    mov edi,OFFSET apic_entries
    movzx ecx,es:act_size
    sub ecx,OFFSET apic_entries - OFFSET apic_phys
    xor bp,bp

init_core_loop:
    mov al,es:[edi].apic_type
    or al,al
    jnz init_core_next    
;    
    or bp,bp
    jnz init_ap_proc

init_boot_proc:
    GetCore
    movzx edx,es:[edi].ap_apic_id
    mov fs:cs_apic,edx
;
    mov al,es:[edi].ap_acpi_id
    mov fs:cs_acpi,al
    inc bp
    jmp init_core_next

init_ap_proc:
    cmp si,bp
    je init_core_done
;    
    mov eax,es:[edi].ap_flags
    test al,1
    jz init_core_next
;    
    call DoCreateCore    
    movzx edx,es:[edi].ap_apic_id
    mov fs:cs_apic,edx
    mov al,es:[edi].ap_acpi_id
    mov fs:cs_acpi,al
    or bx,bx
    jz init_ap_boot
;
    call BootVbeCore
    xor bx,bx
    jmp init_ap_done

init_ap_boot:
    call BootCore

init_ap_done:
    inc bp

init_core_next:
    movzx eax,es:[edi].apic_len
    add edi,eax
    sub ecx,eax
    ja init_core_loop

init_core_done:
    popad
    pop es
    pop ds
    ret
start_smp   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:           Init SMP
;
;               DESCRIPTION:    Init smp module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_smp
        
init_smp    PROC near
    push ds
    push es
    pushad
;    
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET start_core
    mov edi,OFFSET start_core_name
    xor cl,cl
    mov ax,start_core_nr
    RegisterOsGate
;
    mov esi,OFFSET shutdown_core
    mov edi,OFFSET shutdown_core_name
    xor cl,cl
    mov ax,shutdown_core_nr
    RegisterOsGate
;
    mov esi,OFFSET boot_realtime_core
    mov edi,OFFSET boot_realtime_core_name
    xor cl,cl
    mov ax,boot_realtime_core_nr
    RegisterOsGate
;
    mov esi,OFFSET get_id
    mov edi,OFFSET get_id_name
    xor cl,cl
    mov ax,get_apic_id_nr
    RegisterOsGate
;
    mov esi,OFFSET send_locked_int
    mov edi,OFFSET send_locked_int_name
    xor cl,cl
    mov ax,send_locked_int_nr
    RegisterOsGate
;
    mov esi,OFFSET send_nmi
    mov edi,OFFSET send_nmi_name
    xor cl,cl
    mov ax,send_nmi_nr
    RegisterOsGate
;
    popad
    pop es
    pop ds    
    ret
init_smp    ENDP

code    ENDS

    END
    
