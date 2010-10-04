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
; IPCDEBUG.ASM
; IPC based kernel debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                        
        NAME ipcdebug

GateSize = 16

INCLUDE ..\driver.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ipcdebug.inc
INCLUDE kdebug.def

code    SEGMENT byte public 'CODE'

.386p

    extrn dis_ass_one:near

    extrn ReadData:near
    extrn GetIllegalOsGate:near
    extrn GetIllegalUserGate:near
    extrn GetOsCall:near
    extrn GetUserCall:near

    extrn interact_incr:near
    extrn interact_decr:near
    extrn interact_set_value:near

    extrn incdec_eax:near
    extrn incdec_ebx:near
    extrn incdec_ecx:near
    extrn incdec_edx:near
    extrn incdec_esi:near
    extrn incdec_edi:near
    extrn incdec_esp:near
    extrn incdec_ebp:near
    extrn incdec_epc:near
    extrn incdec_cs:near
    extrn incdec_ds:near
    extrn incdec_es:near
    extrn incdec_fs:near
    extrn incdec_gs:near
    extrn incdec_ss:near

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           req_tss
;
;           DESCRIPTION:    Request current TSS
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_tss PROC near
    mov cx,SIZE tss_seg
    xor di,di
    xor si,si
    rep movs byte ptr es:[di],gs:[si]
;
    mov ax,es:tss_eflags
    push ds
    mov ds,gs:tss_thread
    mov ds,ds:p_process_sel
    and ax,NOT 200h
    mov bx,ds:ms_virt_flags
    and bx,200h
    or ax,bx
    pop ds
    mov es:tss_eflags,ax
;
    mov cx,SIZE tss_seg
    xor di,di
    ReplyMailslot
    ret
req_tss Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           req_thread
;
;           DESCRIPTION:    Request current thread control block
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_thread      PROC near
    mov bx,gs:tss_thread
    xor di,di
    GetThreadTss
;
    mov cx,SIZE thread_seg
    xor di,di
    ReplyMailslot
    ret
req_thread      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           req_info
;
;           DESCRIPTION:    Request info
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_info    PROC near
    GetFreePhysical
    mov es:di_free_physical,eax
    UsedBigLinear
    mov es:di_used_big,eax
    UsedSmallLinear
    mov es:di_used_small,eax
    mov bx,es:di_thread
    UsedLocalLinearThread
    mov es:di_used_local,eax
;
    mov cx,SIZE debug_req_info_struc
    xor di,di
    ReplyMailslot
    ret
req_info    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           req_data
;
;           DESCRIPTION:    
;
;           PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_data    Proc near
    mov dx,es:dd_sel
    mov esi,es:dd_offset
    mov bx,es:dd_thread
    mov cx,es:dd_count
    mov di,SIZE debug_req_data_struc
    mov al,es:dd_vm
    or al,al
    jz req_pm_data
    jmp req_vm_data

req_pm_data:
    or cx,cx
    jz req_data_reply

req_pm_data_loop:
    ReadThreadSelector
    stosb
    mov al,0
    jc req_pm_save
;
    inc al

req_pm_save:
    stosb
    inc esi
    loop req_pm_data_loop
    jmp req_data_reply

req_vm_data:
    or cx,cx
    jz req_data_reply

req_vm_data_loop:
    ReadThreadSegment
    stosb
    mov al,0
    jc req_vm_save
;
    inc al

req_vm_save:
    stosb
    inc esi
    loop req_vm_data_loop

req_data_reply:
    mov cx,di
    xor di,di
    ReplyMailslot
    ret
req_data    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetMne
;
;           DESCRIPTION:    Get special MNE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMne  PROC near
    push si
    push di
;
    xor dl,dl
    mov bx,gs:tss_cs
    test byte ptr gs:tss_eflags+2,2
    jnz get_cs_bitness_done

get_cs_bitness_pm:
    test bx,4
    jz get_cs_bitness_gdt

get_cs_bitness_ldt:
    mov es,gs:tss_thread
    mov es,es:p_ldt_sel
    jmp get_cs_bitness_test

get_cs_bitness_gdt:
    mov ax,gdt_sel
    mov es,ax

get_cs_bitness_test:
    and bx,0FFF8h
    mov dl,es:[bx+6]
    shr dl,6
    and dl,1

get_cs_bitness_done:
    mov di,OFFSET op_in_text
    mov si,OFFSET op_in_code
;
    mov al,[si]
    cmp al,66h
    jne write_op_override_done
;
    inc si
    xor dl,1

write_op_override_done:
    mov ax,[si]
    cmp ax,0B0Fh
    jne not_illegal_op

write_illegal16:
    mov al,[si+2]
    cmp al,0CAh
    je write_illegal_osgate
;
    cmp al,0CBh
    je write_illegal_osgate
;
    cmp al,0D6h
    je write_illegal_usergate
;
    cmp al,0D7h
    je write_illegal_usergate
    jmp write_special_end

write_illegal_osgate:
    mov ax,[si+3]
    cmp ax,osgate_entries
    jnc write_special_fail
;
    shl ax,3
    mov bx,ax
    mov ax,ds
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetIllegalOsGate
    mov ds:op_size,bx
    clc
    jmp write_special_end

write_illegal_usergate:
    mov eax,[si+3]
    cmp eax,usergate_entries
    jnc write_special_fail
;
    shl eax,5
    mov ebx,eax
    mov ax,ipc_debug_data_sel
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetIllegalUserGate
    mov ds:op_size,bx
    clc
    jmp write_special_end

not_illegal_op:
    cmp al,9Ah
    jne not_call_far
;
    test dl,1
    jz write_call_far16
;
    mov dx,[si+5]
    cmp dx,2
    jne not_call32
;
    mov eax,[si+1]
    cmp eax,usergate_entries
    jnc write_special_fail
;
    shl eax,5
    mov ebx,eax
    mov ax,ipc_debug_data_sel
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetIllegalUserGate
    mov ds:op_size,bx
    clc
    jmp write_special_end
    
not_call32:
    mov bx,[si+1]
    mov dx,[si+5]
    mov ax,ipc_debug_data_sel
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    jnc write_special_end
;
    mov bx,[si+1]
    mov dx,[si+5]
    mov ax,ipc_debug_data_sel
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end

write_call_far16:
    mov bx,[si+1]
    mov dx,[si+3]
    mov ax,ipc_debug_data_sel
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    jnc write_special_end
;
    mov bx,[si+1]
    mov dx,[si+3]
    mov ax,ipc_debug_data_sel
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end

not_call_far:
    cmp al,0E8h
    jne write_special_fail
;
    test dl,1
    jz write_call_near16
;
    mov ebx,[si+1]
    mov dx,gs:tss_cs
    add ebx,dword ptr gs:tss_eip
    add ebx,5
    mov ax,ipc_debug_data_sel
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end
    
write_call_near16:
    mov bx,[si+1]
    mov dx,gs:tss_cs
    add bx,gs:tss_eip
    add bx,3
    mov ax,ipc_debug_data_sel
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetOsCall
    mov ds:op_size,bx
    jnc write_special_end
;
    mov bx,[si+1]
    mov dx,gs:tss_cs
    add bx,gs:tss_eip
    add bx,3
    mov ax,ipc_debug_data_sel
    mov es,ax
    mov di,OFFSET op_in_text
    mov cx,40
    call GetUserCall
    mov ds:op_size,bx
    jmp write_special_end

write_special_fail:
    stc

write_special_end:
    pop di
    pop si
    ret
GetMne  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LoadInstr
;
;           DESCRIPTION:    Load instruction
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadInstr       PROC near
    xor di,di
    mov ax,gs:tss_eflags+2
    test ax,2
    jnz seg_size_ok
    mov bx,gs:tss_cs
    test bx,4
    jz code_in_gdt
code_in_ldt:
    and bx,0FFF8h
    xor esi,esi
    mov si,bx
    mov es,gs:tss_thread
    mov es,es:p_ldt_sel
    mov al,es:[bx+6]
    shr al,6
    and ax,1
    mov di,ax
    jmp seg_size_ok
code_in_gdt:
    mov ax,gdt_sel
    mov ds,ax
    and bx,0FFF8h
    mov al,[bx+6]
    shr al,6
    and ax,1
    mov di,ax
seg_size_ok:
    mov ax,ipc_debug_data_sel
    mov ds,ax
    mov es,gs:tss_thread
    mov dx,gs:tss_cs
    mov ebx,dword ptr gs:tss_eip
    mov dword ptr ds:op_ads,ebx
    mov si,OFFSET op_in_code
    mov cx,16
get_instr_loop:
    call ReadData
    mov [si],al
    inc ebx
    inc si
    loop get_instr_loop
    ret
LoadInstr       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           req_instr
;
;           DESCRIPTION:    Request instruction
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_instr       PROC near
    push es
    call LoadInstr
    call GetMne
    jnc req_instr_do
;
    call dis_ass_one
req_instr_do:
    pop es
;
    mov ax,ipc_debug_data_sel
    mov ds,ax
;
    mov si,OFFSET op_in_code
    mov di,OFFSET ddi_code
    mov cx,8
    rep movsw
;
    mov cx,20
    mov si,OFFSET op_in_text
    mov di,OFFSET ddi_mne
    rep movsw
;
    mov al,ds:data_good
    mov es:ddi_data_good,al
    mov eax,ds:data_off
    mov es:ddi_data_offset,eax
    mov ax,ds:data_sel
    mov es:ddi_data_sel,ax
;
    mov cx,SIZE debug_req_instr_struc
    xor di,di
    ReplyMailslot
    ret
req_instr       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DefaultReply
;
;           DESCRIPTION:    Default reply
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DefaultReply    Proc near
    mov cx,SIZE debug_req_struc
    xor di,di
    ReplyMailslot
    ret
DefaultReply    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           interact_set
;
;           DESCRIPTION:    Set value
;
;           PARAMETERS:     GS              8086 TSS
;                           CH              value
;                           DX:ESI      address to data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

interact_set      PROC near
    call interact_set_value
    inc es:db_x
    ret
interact_set      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_eax
;
;           DESCRIPTION:    Change EAX
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_eax      PROC near
    mov dx,gs
    mov esi,OFFSET tss_eax
    push di
    ret
    ret
change_eax      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_ebx
;
;           DESCRIPTION:    Change EBX
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_ebx      PROC near
    mov dx,gs
    mov esi,OFFSET tss_ebx
    push di
    ret
    ret
change_ebx      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_ecx
;
;           DESCRIPTION:    Change ECX
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_ecx      PROC near
    mov dx,gs
    mov esi,OFFSET tss_ecx
    push di
    ret
    ret
change_ecx      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_edx
;
;           DESCRIPTION:    Change EDX
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_edx      PROC near
    mov dx,gs
    mov esi,OFFSET tss_edx
    push di
    ret
    ret
change_edx      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_esi
;
;           DESCRIPTION:    Change ESI
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_esi      PROC near
    mov dx,gs
    mov esi,OFFSET tss_esi
    push di
    ret
    ret
change_esi      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_edi
;
;           DESCRIPTION:    Change EDI
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_edi      PROC near
    mov dx,gs
    mov esi,OFFSET tss_edi
    push di
    ret
    ret
change_edi      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_esp
;
;           DESCRIPTION:    Change ESP
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_esp      PROC near
    mov dx,gs
    mov esi,OFFSET tss_esp
    push di
    ret
    ret
change_esp      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_ebp
;
;           DESCRIPTION:    Change EBP
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_ebp      PROC near
    mov dx,gs
    mov esi,OFFSET tss_ebp
    push di
    ret
    ret
change_ebp      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_epc
;
;           DESCRIPTION:    Change EIP
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_epc      PROC near
    mov dx,gs
    mov esi,OFFSET tss_eip
    push di
    ret
    ret
change_epc      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_cs
;
;           DESCRIPTION:    Change CS
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_cs       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET tss_cs
    push di
    ret
    ret
change_cs       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_ds
;
;           DESCRIPTION:    Change DS
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_ds       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET tss_ds
    push di
    ret
    ret
change_ds       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_es
;
;           DESCRIPTION:    Change ES
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_es       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET tss_es
    push di
    ret
    ret
change_es       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_fs
;
;           DESCRIPTION:    Change FS
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_fs       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET tss_fs
    push di
    ret
    ret
change_fs       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_gs
;
;           DESCRIPTION:    Change GS
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_gs       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET tss_gs
    push di
    ret
    ret
change_gs       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_ss
;
;           DESCRIPTION:    Change SS
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_ss       PROC near
    and cl,3
    mov dx,gs
    mov esi,OFFSET tss_ss
    push di
    ret
    ret
change_ss       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           toggle_cy
;
;           DESCRIPTION:    Toggle CY
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_cy       PROC near
    mov bx,OFFSET tss_eflags
    xor word ptr gs:[bx],1
    ret
toggle_cy       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           toggle_pa
;
;           DESCRIPTION:    Toggle PA
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_pa       PROC near
    mov bx,OFFSET tss_eflags
    xor word ptr gs:[bx],4
    ret
toggle_pa       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           toggle_ac
;
;           DESCRIPTION:    Toggle AC
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_ac       PROC near
    mov bx,OFFSET tss_eflags
    xor word ptr gs:[bx],10h
    ret
toggle_ac       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           toggle_zr
;
;           DESCRIPTION:    Toggle ZR
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_zr       PROC near
    mov bx,OFFSET tss_eflags
    xor word ptr gs:[bx],40h
    ret
toggle_zr       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           toggle_pl
;
;           DESCRIPTION:    Toggle PL
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_pl       PROC near
    mov bx,OFFSET tss_eflags
    xor word ptr gs:[bx],80h
    ret
toggle_pl       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           toggle_im
;
;           DESCRIPTION:    Toggle IM
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_im       PROC near
    mov bx,OFFSET tss_eflags
    xor word ptr gs:[bx],200h
    ret
toggle_im       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           toggle_dir
;
;           DESCRIPTION:    Toggle DIR
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_dir      PROC near
    mov bx,OFFSET tss_eflags
    xor word ptr gs:[bx],400h
    ret
toggle_dir      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           toggle_ov
;
;           DESCRIPTION:    Toggle OV
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_ov       PROC near
    mov bx,OFFSET tss_eflags
    xor word ptr gs:[bx],800h
    ret
toggle_ov       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           toggle_nt
;
;           DESCRIPTION:    Toggle NT
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

toggle_nt       PROC near
    mov bx,OFFSET tss_eflags
    xor word ptr gs:[bx],4000h
    ret
toggle_nt       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_do
;
;           DESCRIPTION:    Change memory
;
;           PARAMETERS:         GS              8086 TSS
;                           DX:ESI      address to data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_do  PROC near
    mov cl,es:db_x
    sub cl,cs:[bx+debug_col]
    mov bx,gs:tss_thread
mem_do_next:
    cmp cl,3
    jc mem_do_alloc
    sub cl,3
    inc esi
    jmp mem_do_next
mem_do_alloc:
    cmp cl,2
    je mem_do_end
    xor cl,1
    push cx
    push OFFSET mem_do_free
    push di
    ret
mem_do_free:
    pop cx
    or cl,cl
    jnz mem_do_end
    inc es:db_x
mem_do_end:     
    ret
mem_do  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_ads
;
;           DESCRIPTION:    Change data memory
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_ads PROC near
    ret
mem_ads ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_cs
;
;           DESCRIPTION:    Change CS memory
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_cs  PROC near
    mov dx,gs:tss_cs
    mov si,OFFSET tss_eip
    mov esi,gs:[si]
    call mem_do
    ret
mem_cs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_ss
;
;           DESCRIPTION:    Change SS memory
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_ss  PROC near
    mov dx,gs:tss_ss
    mov si,OFFSET tss_esp
    mov esi,gs:[si]
    call mem_do
    ret
mem_ss  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_es
;
;           DESCRIPTION:    Change ES memory
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_es  PROC near
    mov dx,gs:tss_es
    xor esi,esi
    call mem_do
    ret
mem_es  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_pm
;
;           DESCRIPTION:    Change PM memory
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_pm  PROC near
    push gs:tss_eflags+2
    push ds
    mov gs:tss_eflags+2,0
    mov ds,gs:tss_thread
    mov dx,ds:p_pm_deb_sel
    mov esi,ds:p_pm_deb_offs
    pop ds
    call mem_do
    pop gs:tss_eflags+2
    ret
mem_pm  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_pm_sel
;
;           DESCRIPTION:    Change PM selector
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_pm_sel   PROC near
    push gs:tss_eflags+2
    mov gs:tss_eflags+2,0
    mov dx,gs:tss_thread
    and cl,3
    mov esi,OFFSET p_pm_deb_sel
    push cx
    push OFFSET change_pm_sel_ret
    push di
    ret
change_pm_sel_ret:
    pop cx
    or cl,cl
    jnz change_pm_sel_error
    inc es:db_x
change_pm_sel_error:
    pop gs:tss_eflags+2
    ret
change_pm_sel   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_pm_offs
;
;           DESCRIPTION:    Change PM offset
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_pm_offs  PROC near
    push gs:tss_eflags+2
    mov gs:tss_eflags+2,0
    mov dx,gs:tss_thread
    mov esi,OFFSET p_pm_deb_offs
    push cx
    push OFFSET change_pm_offs_ret
    push di
    ret
change_pm_offs_ret:
    pop cx
    or cl,cl
    jnz change_pm_offs_error
    inc es:db_x
change_pm_offs_error:
    pop gs:tss_eflags+2
    ret
change_pm_offs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_vm
;
;           DESCRIPTION:    Change VM memory
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_vm  PROC near
    push gs:tss_eflags+2
    mov gs:tss_eflags+2,2
    push ds
    mov ds,gs:tss_thread
    mov dx,ds:p_vm_deb_sel
    mov esi,ds:p_vm_deb_offs
    pop ds
    call mem_do
    pop gs:tss_eflags+2
    ret
mem_vm  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_vm_sel
;
;           DESCRIPTION:    Change VM segment
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_vm_sel   PROC near
    push gs:tss_eflags+2
    mov gs:tss_eflags+2,0
    mov dx,gs:tss_thread
    and cl,3
    mov esi,OFFSET p_vm_deb_sel
    push cx
    push OFFSET change_vm_sel_ret
    push di
    ret
change_vm_sel_ret:
    pop cx
    or cl,cl
    jnz change_vm_sel_error
    inc es:db_x
change_vm_sel_error:
    pop gs:tss_eflags+2
    ret
change_vm_sel   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           change_vm_offs
;
;           DESCRIPTION:    Change VM offset
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_vm_offs  PROC near
    push gs:tss_eflags+2
    mov gs:tss_eflags+2,0
    mov dx,gs:tss_thread
    mov esi,OFFSET p_vm_deb_offs
    push cx
    push OFFSET change_vm_offs_ret
    push di
    ret
change_vm_offs_ret:
    pop cx
    or cl,cl
    jnz change_vm_offs_error
    inc es:db_x
change_vm_offs_error:
    pop gs:tss_eflags+2
    ret
change_vm_offs  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugCallDo
;
;           DESCRIPTION:    Modify registers
;
;           PARAMETERS:         GS              8086 TSS
;                           DI              address to debug-function
;                           ch              digit / param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
debug_table:
;
;           rad     kolumn  antal   action
;
meax DW 9,          1,          3,          OFFSET incdec_eax
deax DW 9,          5,          8,          OFFSET change_eax
mebx DW 9,          14,         3,          OFFSET incdec_ebx
debx DW 9,          18,         8,          OFFSET change_ebx
mecx DW 9,          27,         3,          OFFSET incdec_ecx
decx DW 9,          31,         8,          OFFSET change_ecx
medx DW 9,          40,         3,          OFFSET incdec_edx
dedx DW 9,          44,         8,          OFFSET change_edx
mesi DW 10,         1,          3,          OFFSET incdec_esi
desi DW 10,         5,          8,          OFFSET change_esi
medi DW 10,         14,         3,          OFFSET incdec_edi
dedi DW 10,         18,         8,          OFFSET change_edi
mesp DW 10,         27,         3,          OFFSET incdec_esp
desp DW 10,         31,         8,          OFFSET change_esp
mebp DW 10,         40,         3,          OFFSET incdec_ebp
debp DW 10,         44,         8,          OFFSET change_ebp
mepc DW 11,         1,          3,          OFFSET incdec_epc
depc DW 11,         5,          8,          OFFSET change_epc
mcs  DW 12,         1,          2,          OFFSET incdec_cs
dcs      DW 12,     4,          4,          OFFSET change_cs
mds  DW 12,         9,          2,          OFFSET incdec_ds
dds      DW 12,     12,         4,          OFFSET change_ds
mes      DW 12,     17,         2,          OFFSET incdec_es
des  DW 12,         20,         4,          OFFSET change_es
mfs      DW 12,     25,         2,          OFFSET incdec_fs
dfs  DW 12,         28,         4,          OFFSET change_fs
mgs      DW 12,     33,         2,          OFFSET incdec_gs
dgs  DW 12,         36,         4,          OFFSET change_gs
mss      DW 12,     41,         2,          OFFSET incdec_ss
dss  DW 12,         44,         4,          OFFSET change_ss
dcy  DW 13,         0,          2,          OFFSET toggle_cy
dpa  DW 13,         3,          2,          OFFSET toggle_pa
dac  DW 13,         6,          2,          OFFSET toggle_ac
dzr  DW 13,         9,          2,          OFFSET toggle_zr
dplc DW 13,         12,         2,          OFFSET toggle_pl
disf DW 13,         15,         2,          OFFSET toggle_im
ddir DW 13,         18,         2,          OFFSET toggle_dir
dov  DW 13,         21,         2,          OFFSET toggle_ov
dnt  DW 13,         24,         2,          OFFSET toggle_nt
dgo  DW 16,         0,          30,         OFFSET go_sw
dtra DW 17,         0,          40,         OFFSET trace_sw
dnex DW 17,         40,         40,         OFFSET next_sw
mdad DW 19,         14,         47,         OFFSET mem_ads
mdcs DW 20,         14,         47,         OFFSET mem_cs
mdss DW 21,         14,         47,         OFFSET mem_ss
mdes DW 22,         14,         47,         OFFSET mem_es
pms  DW 23,         0,          4,          OFFSET change_pm_sel
pmo  DW 23,         5,          8,          OFFSET change_pm_offs
pdat DW 23,         14,         47,         OFFSET mem_pm
vms  DW 24,         0,          4,          OFFSET change_vm_sel
vmo  DW 24,         5,          8,          OFFSET change_vm_offs
vdat DW 24,         14,         47,         OFFSET mem_vm
dend DW 0FFFFh, 0FFFFh

debug_row       EQU 0
debug_col       EQU 2
debug_ant       EQU 4
debug_call      EQU 6
debug_size      EQU 8

DebugCallDo     PROC near
    mov al,es:db_x
    mov ah,es:db_y
    mov bx,OFFSET debug_table

d_c_loop:
    mov cl,cs:[bx+debug_row]
    cmp cl,0FFh
    je d_c_end
    cmp cl,ah
    jne not_this_entry
    mov cl,al
    sub cl,cs:[bx+debug_col]
    cmp cl,cs:[bx+debug_ant]
    jnc not_this_entry
    xor cl,7
    and cl,7
    mov al,es:db_op
    call word ptr cs:[bx+debug_call]
    jmp d_c_end
not_this_entry:
    add bx,debug_size
    jmp d_c_loop
d_c_end:
    call DefaultReply
    ret
DebugCallDo     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           inc_sw
;
;           DESCRIPTION:    Inc 
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

inc_sw  PROC near
    mov di,OFFSET interact_incr
    call DebugCallDo
    ret
inc_sw  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dec_sw
;
;           DESCRIPTION:    Dec 
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_sw  PROC near
    mov di,OFFSET interact_decr
    call DebugCallDo
    ret
dec_sw  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setx_sw
;
;           DESCRIPTION:    Set 
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_base_sw     PROC near
    mov di,OFFSET interact_set
    call DebugCallDo
    ret
set_base_sw     ENDP

set0_sw PROC near
    mov ch,0
    call set_base_sw
    ret
set0_sw ENDP

set1_sw PROC near
    mov ch,1
    call set_base_sw
    ret
set1_sw ENDP

set2_sw PROC near
    mov ch,2
    call set_base_sw
    ret
set2_sw ENDP

set3_sw PROC near
    mov ch,3
    call set_base_sw
    ret
set3_sw ENDP

set4_sw PROC near
    mov ch,4
    call set_base_sw
    ret
set4_sw ENDP

set5_sw PROC near
    mov ch,5
    call set_base_sw
    ret
set5_sw ENDP

set6_sw PROC near
    mov ch,6
    call set_base_sw
    ret
set6_sw ENDP

set7_sw PROC near
    mov ch,7
    call set_base_sw
    ret
set7_sw ENDP

set8_sw PROC near
    mov ch,8
    call set_base_sw
    ret
set8_sw ENDP

set9_sw PROC near
    mov ch,9
    call set_base_sw
    ret
set9_sw ENDP

setA_sw PROC near
    mov ch,0Ah
    call set_base_sw
    ret
setA_sw ENDP

setB_sw PROC near
    mov ch,0Bh
    call set_base_sw
    ret
setB_sw ENDP

setC_sw PROC near
    mov ch,0Ch
    call set_base_sw
    ret
setC_sw ENDP

setD_sw PROC near
    mov ch,0Dh
    call set_base_sw
    ret
setD_sw ENDP

setE_sw PROC near
    mov ch,0Eh
    call set_base_sw
    ret
setE_sw ENDP

setF_sw PROC near
    mov ch,0Fh
    call set_base_sw
    ret
setF_sw ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           go_sw
;
;           DESCRIPTION:    Go
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

go_sw   PROC near
    DebugGo
    call DefaultReply
    ret
go_sw   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           trace_sw
;
;           DESCRIPTION:    Trace
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trace_sw    PROC near
    DebugTrace
    call DefaultReply
    ret
trace_sw    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           pace_sw
;
;           DESCRIPTION:    Pace 
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pace_sw PROC near
    DebugPace
    call DefaultReply
    ret
pace_sw ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           reg_sw
;
;           DESCRIPTION:    Return registers switch
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reg_sw  PROC near
    call DefaultReply
    ret
reg_sw  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           next_sw
;
;           DESCRIPTION:    Next thread switch
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

next_sw PROC near
    DebugNext
    call DefaultReply
    ret
next_sw ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           error_sw
;
;           DESCRIPTION:    Undefined switch
;
;           PARAMETERS:         GS              8086 TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_sw    PROC near
    call DefaultReply
    ret
error_sw    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleMsg
;
;           DESCRIPTION:    Handle a message
;
;           PARAMETERS:         ES          Message buffer
;                           CX          Message size
;
;           RETURNS:        CX          Reply size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
virt_sw_func_tab:
vs_00   DW OFFSET req_tss
vs_01   DW OFFSET req_thread
vs_02   DW OFFSET req_data
vs_03   DW OFFSET req_info
vs_04   DW OFFSET req_instr
vs_05   DW OFFSET error_sw
vs_06   DW OFFSET error_sw
vs_07   DW OFFSET error_sw
vs_08   DW OFFSET error_sw
vs_09   DW OFFSET error_sw
vs_0A   DW OFFSET error_sw
vs_0B   DW OFFSET error_sw
vs_0C   DW OFFSET error_sw
vs_0D   DW OFFSET error_sw
vs_0E   DW OFFSET error_sw
vs_0F   DW OFFSET error_sw
vs_10   DW OFFSET error_sw
vs_11   DW OFFSET error_sw
vs_12   DW OFFSET error_sw
vs_13   DW OFFSET error_sw
vs_14   DW OFFSET error_sw
vs_15   DW OFFSET error_sw
vs_16   DW OFFSET error_sw
vs_17   DW OFFSET error_sw
vs_18   DW OFFSET error_sw
vs_19   DW OFFSET error_sw
vs_1A   DW OFFSET error_sw
vs_1B   DW OFFSET error_sw
vs_1C   DW OFFSET error_sw
vs_1D   DW OFFSET error_sw
vs_1E   DW OFFSET error_sw
vs_1F   DW OFFSET error_sw
vs_20   DW OFFSET error_sw
vs_21   DW OFFSET error_sw
vs_22   DW OFFSET error_sw
vs_23   DW OFFSET error_sw
vs_24   DW OFFSET error_sw
vs_25   DW OFFSET error_sw
vs_26   DW OFFSET error_sw
vs_27   DW OFFSET error_sw
vs_28   DW OFFSET error_sw
vs_29   DW OFFSET error_sw
vs_2A   DW OFFSET error_sw
vs_2B   DW OFFSET inc_sw
vs_2C   DW OFFSET error_sw
vs_2D   DW OFFSET dec_sw
vs_2E   DW OFFSET error_sw
vs_2F   DW OFFSET error_sw
vs_30   DW OFFSET set0_sw
vs_31   DW OFFSET set1_sw
vs_32   DW OFFSET set2_sw
vs_33   DW OFFSET set3_sw
vs_34   DW OFFSET set4_sw
vs_35   DW OFFSET set5_sw
vs_36   DW OFFSET set6_sw
vs_37   DW OFFSET set7_sw
vs_38   DW OFFSET set8_sw
vs_39   DW OFFSET set9_sw
vs_3A   DW OFFSET error_sw
vs_3B   DW OFFSET error_sw
vs_3C   DW OFFSET error_sw
vs_3D   DW OFFSET error_sw
vs_3E   DW OFFSET error_sw
vs_3F   DW OFFSET error_sw
vs_40   DW OFFSET error_sw
vs_41   DW OFFSET setA_sw
vs_42   DW OFFSET setB_sw
vs_43   DW OFFSET setC_sw
vs_44   DW OFFSET setD_sw
vs_45   DW OFFSET setE_sw
vs_46   DW OFFSET setF_sw
vs_47   DW OFFSET go_sw
vs_48   DW OFFSET error_sw
vs_49   DW OFFSET error_sw
vs_4A   DW OFFSET error_sw
vs_4B   DW OFFSET error_sw
vs_4C   DW OFFSET error_sw
vs_4D   DW OFFSET error_sw
vs_4E   DW OFFSET next_sw
vs_4F   DW OFFSET error_sw
vs_50   DW OFFSET pace_sw
vs_51   DW OFFSET error_sw
vs_52   DW OFFSET reg_sw
vs_53   DW OFFSET error_sw
vs_54   DW OFFSET trace_sw
vs_55   DW OFFSET error_sw
vs_56   DW OFFSET error_sw
vs_57   DW OFFSET error_sw
vs_58   DW OFFSET error_sw
vs_59   DW OFFSET error_sw
vs_5A   DW OFFSET error_sw
vs_5B   DW OFFSET error_sw
vs_5C   DW OFFSET error_sw
vs_5D   DW OFFSET error_sw
vs_5E   DW OFFSET error_sw
vs_5F   DW OFFSET error_sw
vs_60   DW OFFSET error_sw
vs_61   DW OFFSET setA_sw
vs_62   DW OFFSET setB_sw
vs_63   DW OFFSET setC_sw
vs_64   DW OFFSET setD_sw
vs_65   DW OFFSET setE_sw
vs_66   DW OFFSET setF_sw
vs_67   DW OFFSET go_sw
vs_68   DW OFFSET error_sw
vs_69   DW OFFSET error_sw
vs_6A   DW OFFSET error_sw
vs_6B   DW OFFSET error_sw
vs_6C   DW OFFSET error_sw
vs_6D   DW OFFSET error_sw
vs_6E   DW OFFSET next_sw
vs_6F   DW OFFSET error_sw
vs_70   DW OFFSET pace_sw
vs_71   DW OFFSET error_sw
vs_72   DW OFFSET reg_sw
vs_73   DW OFFSET error_sw
vs_74   DW OFFSET trace_sw
vs_75   DW OFFSET error_sw
vs_76   DW OFFSET error_sw
vs_77   DW OFFSET error_sw
vs_78   DW OFFSET error_sw
vs_79   DW OFFSET error_sw
vs_7A   DW OFFSET error_sw
vs_7B   DW OFFSET error_sw
vs_7C   DW OFFSET error_sw
vs_7D   DW OFFSET error_sw
vs_7E   DW OFFSET error_sw
vs_7F   DW OFFSET error_sw
vs_80   DW OFFSET error_sw
vs_81   DW OFFSET error_sw
vs_82   DW OFFSET error_sw
vs_83   DW OFFSET error_sw
vs_84   DW OFFSET error_sw
vs_85   DW OFFSET error_sw
vs_86   DW OFFSET error_sw
vs_87   DW OFFSET error_sw
vs_88   DW OFFSET error_sw
vs_89   DW OFFSET error_sw
vs_8A   DW OFFSET error_sw
vs_8B   DW OFFSET error_sw
vs_8C   DW OFFSET error_sw
vs_8D   DW OFFSET error_sw
vs_8E   DW OFFSET error_sw
vs_8F   DW OFFSET error_sw
vs_90   DW OFFSET error_sw
vs_91   DW OFFSET error_sw
vs_92   DW OFFSET error_sw
vs_93   DW OFFSET error_sw
vs_94   DW OFFSET error_sw
vs_95   DW OFFSET error_sw
vs_96   DW OFFSET error_sw
vs_97   DW OFFSET error_sw
vs_98   DW OFFSET error_sw
vs_99   DW OFFSET error_sw
vs_9A   DW OFFSET error_sw
vs_9B   DW OFFSET error_sw
vs_9C   DW OFFSET error_sw
vs_9D   DW OFFSET error_sw
vs_9E   DW OFFSET error_sw
vs_9F   DW OFFSET error_sw
vs_A0   DW OFFSET error_sw
vs_A1   DW OFFSET error_sw
vs_A2   DW OFFSET error_sw
vs_A3   DW OFFSET error_sw
vs_A4   DW OFFSET error_sw
vs_A5   DW OFFSET error_sw
vs_A6   DW OFFSET error_sw
vs_A7   DW OFFSET error_sw
vs_A8   DW OFFSET error_sw
vs_A9   DW OFFSET error_sw
vs_AA   DW OFFSET error_sw
vs_AB   DW OFFSET error_sw
vs_AC   DW OFFSET error_sw
vs_AD   DW OFFSET error_sw
vs_AE   DW OFFSET error_sw
vs_AF   DW OFFSET error_sw
vs_B0   DW OFFSET error_sw
vs_B1   DW OFFSET error_sw
vs_B2   DW OFFSET error_sw
vs_B3   DW OFFSET error_sw
vs_B4   DW OFFSET error_sw
vs_B5   DW OFFSET error_sw
vs_B6   DW OFFSET error_sw
vs_B7   DW OFFSET error_sw
vs_B8   DW OFFSET error_sw
vs_B9   DW OFFSET error_sw
vs_BA   DW OFFSET error_sw
vs_BB   DW OFFSET error_sw
vs_BC   DW OFFSET error_sw
vs_BD   DW OFFSET error_sw
vs_BE   DW OFFSET error_sw
vs_BF   DW OFFSET error_sw
vs_C0   DW OFFSET error_sw
vs_C1   DW OFFSET error_sw
vs_C2   DW OFFSET error_sw
vs_C3   DW OFFSET error_sw
vs_C4   DW OFFSET error_sw
vs_C5   DW OFFSET error_sw
vs_C6   DW OFFSET error_sw
vs_C7   DW OFFSET error_sw
vs_C8   DW OFFSET error_sw
vs_C9   DW OFFSET error_sw
vs_CA   DW OFFSET error_sw
vs_CB   DW OFFSET error_sw
vs_CC   DW OFFSET error_sw
vs_CD   DW OFFSET error_sw
vs_CE   DW OFFSET error_sw
vs_CF   DW OFFSET error_sw
vs_D0   DW OFFSET error_sw
vs_D1   DW OFFSET error_sw
vs_D2   DW OFFSET error_sw
vs_D3   DW OFFSET error_sw
vs_D4   DW OFFSET error_sw
vs_D5   DW OFFSET error_sw
vs_D6   DW OFFSET error_sw
vs_D7   DW OFFSET error_sw
vs_D8   DW OFFSET error_sw
vs_D9   DW OFFSET error_sw
vs_DA   DW OFFSET error_sw
vs_DB   DW OFFSET error_sw
vs_DC   DW OFFSET error_sw
vs_DD   DW OFFSET error_sw
vs_DE   DW OFFSET error_sw
vs_DF   DW OFFSET error_sw
vs_E0   DW OFFSET error_sw
vs_E1   DW OFFSET error_sw
vs_E2   DW OFFSET error_sw
vs_E3   DW OFFSET error_sw
vs_E4   DW OFFSET error_sw
vs_E5   DW OFFSET error_sw
vs_E6   DW OFFSET error_sw
vs_E7   DW OFFSET error_sw
vs_E8   DW OFFSET error_sw
vs_E9   DW OFFSET error_sw
vs_EA   DW OFFSET error_sw
vs_EB   DW OFFSET error_sw
vs_EC   DW OFFSET error_sw
vs_ED   DW OFFSET error_sw
vs_EE   DW OFFSET error_sw
vs_EF   DW OFFSET error_sw
vs_F0   DW OFFSET error_sw
vs_F1   DW OFFSET error_sw
vs_F2   DW OFFSET error_sw
vs_F3   DW OFFSET error_sw
vs_F4   DW OFFSET error_sw
vs_F5   DW OFFSET error_sw
vs_F6   DW OFFSET error_sw
vs_F7   DW OFFSET error_sw
vs_F8   DW OFFSET error_sw
vs_F9   DW OFFSET error_sw
vs_FA   DW OFFSET error_sw
vs_FB   DW OFFSET error_sw
vs_FC   DW OFFSET error_sw
vs_FD   DW OFFSET error_sw
vs_FE   DW OFFSET error_sw
vs_FF   DW OFFSET error_sw

DebugFunc       Proc near
    push gs
    push di
;
    mov al,es:db_op
    cmp al,'n'
    je debug_next
;
    cmp al,'N'
    je debug_next 
;
    push ax
    GetDebugThread
    mov bx,ax
    pop ax

debug_do:
    or bx,bx
    jz debug_err
;
    mov ds,bx
    mov dx,ds:p_tss_data_sel
    mov ds,dx
    mov gs,dx

debug_next:
    movzx bx,al
    add bx,bx
    call word ptr cs:[bx].virt_sw_func_tab
    jmp debug_end

debug_err:
    call DefaultReply

debug_end:
    pop di
    pop gs
    ret
DebugFunc       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DebugThread
;
;           DESCRIPTION:    IPC Debug thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_thread_name           DB 'IPC Debug',0
mailslot_name           DB 'Debug',0

debug_thread_pr:
    mov ax,cs
    mov es,ax
    mov di,OFFSET mailslot_name
    mov cx,1000h
    DefineMailslot
;
    movzx eax,cx
    AllocateGlobalMem

debug_thread_loop:
    xor di,di
    ReceiveMailslot
    call DebugFunc
    jmp debug_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           free_thread
;
;           DESCRIPTION:    Free thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_thread     Proc far
    GetThread
    mov bx,ax
    mov ax,ipc_debug_data_sel
    mov ds,ax
    mov ax,ds:debug_thread
    cmp ax,bx
    jne free_thread_done
;
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov bx,[si]
    mov ax,ipc_debug_data_sel
    mov ds,ax
    mov ds:debug_thread,bx

free_thread_done:
    ret
free_thread     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_system
;
;           DESCRIPTION:    Init system
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_system     PROC far
    push ds
    push es
    pusha
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET debug_thread_pr
    mov di,OFFSET debug_thread_name
    mov cx,512
    mov ax,26
    CreateThread
    popa
    pop es
    pop ds
    ret
init_system     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_ipc_debug
    
init_ipc_debug  PROC near
    mov bx,ipc_debug_data_sel
    mov eax,SIZE debug_seg
    AllocateFixedSystemMem
    mov es:debug_thread,0
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET init_system
    HookInitTasking
;
    mov di,OFFSET free_thread
    HookTerminateThread
    ret
init_ipc_debug    ENDP

code    ENDS

    END
