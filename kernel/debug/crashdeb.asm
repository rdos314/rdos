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

data    SEGMENT byte public 'DATA'

map_linear   DD ?
map_sel      DW ?
map_spinlock DW ?

mon_linear   DD ?
mon_cr3      DD ?

data    ENDS

    .386p

code    SEGMENT byte public use32 'CODE'

    assume cs:code
    
    extrn set_monitor_data:near
    extrn set_monitor_gdt:near
    extrn set_monitor_idt:near
    extrn start_monitor:near

   
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
;           NAME:           test_pr
;
;           DESCRIPTION:    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_name  DB 'Crash Thread', 0

deb_val DB 11

deb_code:
    mov al,cs:deb_val

test_pr:
    sti
    mov ax,41h
    EnableFocus
;
    int 3    
;    
    CrashGate
    mov esp,0
    push eax
    int 3

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
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET test_pr
    mov edi,OFFSET test_name
    mov ecx,stack0_size
    mov ax,26
    CreateProcess
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
    mov eax,67h
    SetPageEntry
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
