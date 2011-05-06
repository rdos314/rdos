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

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           boot_ram
;
;           DESCRIPTION:    get free ram during boot
;
;           RETURNS:        ESI         address to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

boot_ram    Proc near
    push ds
    push ax
    mov ax,system_data_sel
    mov ds,ax
    mov esi,ds:alloc_base
    mov ax,flat_sel
    mov ds,ax
    jmp LowRamNext
LowRamLoop:
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je RamFound
LowRamNext:
    add esi,1000h
    cmp esi,0A0000h
    jc LowRamLoop
    mov esi,100000h
HighRamLoop:
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je RamFound
    add esi,1000h
    jmp HighRamLoop
RamFound:
    mov ax,system_data_sel
    mov ds,ax
    mov ds:alloc_base,esi
    pop ax
    pop ds
    ret
boot_ram    Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           get_video
;
;           DESCRIPTION:    get video adapter adress
;
;           RETURNS:        BX          video selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_video       Proc near
    mov ax,flat_sel
    mov ds,ax
    mov edx,0A0000h
    mov ax,720h
get_video_loop:
    mov [edx],ax
    cmp ax,[edx]
    je get_video_sel
    add edx,1000h
    cmp edx,0C0000h
    jne get_video_loop
    mov edx,0F0000h
get_video_sel:
    mov ax,gdt_sel
    mov ds,ax
    mov bx,dosB800
    mov word ptr [bx],0FFFh
    mov [bx+2],edx
    mov byte ptr [bx+5],92h
    mov word ptr [bx+6],0
    ret
get_video       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WRITE_CHAR
;
;           DESCRIPTION:    Write a char to screen
;
;           PARAMETERS:         DL          CHAR
;                           DH          ATTRIBUTE
;                           AL          ROW
;                           AH          KOLUMN
;                           FS          BASE-ADDRESS TO SCREEN-SEG
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_char      PROC near
    push ax
    push bx
    push cx
    mov cx,ax
    mov al,80
    mul ch
    add al,cl
    adc ah,0
    add ax,ax
    mov bx,ax
    mov fs:[bx],dx
    pop cx
    pop bx
    pop ax
    ret
write_char      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SINGEL_HEX
;
;           DESCRIPTION:    Convert number to printable hex
;
;           PARAMETERS:         AL          Value
;
;           RETURNS:        AX          Hex value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

singel_hex      PROC near
hex_conv_low:
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
    add al,7
ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
    add ah,7
ok_high1:
    add ah,30h
    ret
singel_hex      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WRITE_HEX_BYTE
;
;           DESCRIPTION:    Write a hex byte to screen
;
;           PARAMETERS:         AL          HEX DATA IN
;                           CL          ATTRIBUTE
;                           DL          ROW
;                           DH          KOLUMN
;                           FS          BASE-ADDRESS TO SCREEN-SEG
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_hex_byte  PROC near
    push ax
    push cx
    push dx
    mov ah,cl
    mov cx,ax
    call singel_hex
    push ax
    xchg ax,dx
    mov dh,ch
    call write_char
    pop dx
    inc al
    mov dl,dh
    mov dh,ch
    call write_char
    pop dx
    add dl,2
    pop cx
    pop ax
    ret
write_hex_byte  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WRITE_HEX_WORD
;
;           DESCRIPTION:    Write hex word to screen
;
;           PARAMETERS:         AX          HEX DATA IN
;                           CL          ATTRIBUTE
;                           DL          ROW
;                           DH          KOLUMN
;                           FS          BASE-ADDRESS TO SCREEN-SEG
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_hex_word  PROC near
    push ax
    rol ax,8
    call write_hex_byte
    rol ax,8
    call write_hex_byte
    pop ax
    ret
write_hex_word  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WRITE_HEX_DWORD
;
;           DESCRIPTION:    Write hex dword to screen
;
;           PARAMETERS:         EAX         HEX DATA IN
;                           CL          ATTRIBUTE
;                           DL          ROW
;                           DH          KOLUMN
;                           FS          BASE-ADDRESS TO SCREEN-SEG
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_hex_dword PROC near
    push eax
    rol eax,8
    call write_hex_byte
    rol eax,8
    call write_hex_byte
    rol eax,8
    call write_hex_byte
    rol eax,8
    call write_hex_byte
    pop eax
    ret
write_hex_dword ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WRITE_STG
;
;           DESCRIPTION:    Write string to screen
;
;           PARAMETERS:         ES:DI   ADDRESS TO STRING
;                           AH          ATTRIBUTE
;                           DH          START ROW AND END KOLUMN
;                           DL          START KOLUMN AND END KOLUMN
;                           CX          ANTAL TECKEN
;                           FS          BASE-ADDRESS TO SCREEN-SEG
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_stg       PROC near
    xchg ax,dx
    push di
    push bx
write_next:
    push ax
    mov bh,al
    mov al,ah
    mov bl,80
    mul bl
    add al,bh
    adc ah,0
    add ax,ax
    mov bx,ax
    pop ax
    mov dl,es:[di]
    cmp dl,13
    jne not_cr
    xor al,al
    jmp end_this
not_cr:
    cmp dl,10
    jne not_lf
    inc ah
    jmp end_this
not_lf:
    mov fs:[bx],dx
    inc al
end_this:
    cmp al,80
    jne no_line_shift
    inc ah
    mov al,0
no_line_shift:
    cmp ah,24
    jb no_page_shift
    mov ah,24       
no_page_shift:
    inc di
    loop write_next
    pop bx
    pop di
    xchg ax,dx
    ret
write_stg       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WRITE_DWORD_REG
;
;           DESCRIPTION:    Write 32-bit registers
;
;           PARAMETERS:         ES:DI   ADDRESS TO TABLE
;                           CL          ATTRIBUTE
;                           DH          START ROW AND END KOLUMN
;                           DL          START KOLUMN AND END KOLUMN
;                           FS          BASE-ADDRESS TO SCREEN-SEG
;                           GS          TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_dword_reg PROC near
    push cx
    mov ah,cl
    mov cx,4
    call write_stg
    pop cx
    add di,4
    mov bx,es:[di]
    mov eax,gs:[bx]
    call write_hex_dword
    add di,2
    inc dl
    mov al,es:[di]
    or al,al
    jnz write_dword_reg
    ret
write_dword_reg ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WRITE_WORD_REG
;
;           DESCRIPTION:    Write 16-bit registers
;
;           PARAMETERS:         ES:DI   ADDRESS TO TABLE
;                           CL          ATTRIBUTE
;                           DH          START ROW AND END KOLUMN
;                           DL          START KOLUMN AND END KOLUMN
;                           FS          BASE-ADDRESS TO SCREEN-SEG
;                           GS          TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_word_reg  PROC near
    push cx
    mov ah,cl
    mov cx,3
    call write_stg
    pop cx
    add di,3
    mov bx,es:[di]
    mov ax,gs:[bx]
    call write_hex_word
    add di,2
    inc dl
    mov al,es:[di]
    or al,al
    jnz write_word_reg
    ret
write_word_reg  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WRITE_EFLAGS
;
;           DESCRIPTION:    Write EFLAGS
;
;           PARAMETERS:         DH          START ROW AND END KOLUMN
;                           DL          START KOLUMN AND END KOLUMN
;                           FS          BASE-ADDRESS TO SCREEN-SEG
;                           GS          TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


eflags_tab:
;
;           reset       set
et_cf   DB 'NC ',       'CY '
et_1    DB 0,0,0,       0,0,0
et_pf   DB 'PO ',       'PE '
et_3    DB 0,0,0,       0,0,0
et_af   DB 'NA ',       'AC '
et_5    DB 0,0,0,       0,0,0
et_zf   DB 'NZ ',       'ZR '
et_sf   DB 'PL ',       'NG '
et_tf   DB 0,0,0,       0,0,0
et_if   DB 'DI ',       'EI '
et_df   DB 'UP ',       'DN '
et_of   DB 'NV ',       'OV '
et_12   DB 0,0,0,       0,0,0
et_13   DB 0,0,0,       0,0,0
et_14   DB 'PR ' ,      'NT '
et_15   DB 0,0,0,       0,0,0
et_16   DB 0,0,0,       0,0,0
et_vm   DB 'PM ',       'VM '
et_end  DB 0FFh

write_eflags    PROC near
    mov bx,OFFSET p_tss_eflags
    mov eax,gs:[bx]
    mov di,OFFSET eflags_tab
    mov cx,cs
    mov es,cx
eflags_loop:
    mov ch,es:[di]
    or ch,ch
    je eflags_next
    cmp ch,0FFh
    je eflags_done
    push di
    mov cl,10
    test ax,1
    jz eflags_pos_ok
    add di,3
    mov cl,12
eflags_pos_ok:
    push ax
    mov ah,cl
    mov cx,3
    call write_stg
    pop ax
    pop di
eflags_next:
    add di,6
    shr eax,1
    jmp eflags_loop
eflags_done:
    ret
write_eflags    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WRITE_FAULT
;
;           DESCRIPTION:    Write fault string
;
;           PARAMETERS:         DH          START ROW AND END KOLUMN
;                           DL          START KOLUMN AND END KOLUMN
;                           FS          BASE-ADDRESS TO SCREEN-SEG
;                           GS          TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ft_idt  DB 'Idt '
ft_ldt  DB 'Ldt '
ft_gdt  DB 'Gdt '

write_fault     PROC near
    mov ax,cs
    mov es,ax
    mov ax,gs:tss_error_code
    test ax,2
    jz fault_not_idt
    mov di,OFFSET ft_idt
    jmp write_fault_reason
fault_not_idt:
    mov di,OFFSET ft_gdt
    test ax,4
    jz write_fault_reason
    mov di,OFFSET ft_ldt
write_fault_reason:
    mov ah,11
    mov cx,4
    call write_stg
    mov ax,gs:tss_error_code
    and ax,0FFF8h
    mov cl,11
    call write_hex_word
write_fault_end:
    ret
write_fault     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ABORT_PR
;
;           DESCRIPTION:    Abort app and display dump
;
;           PARAMETERS:         FS          Screen
;                           DS          Readable TSS for thread
;                           ES          Readable GDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_code_tab:
ke00    DB 'Divide error        '
ke01    DB 'Single step         '
ke02    DB 'NMI             '
ke03    DB 'Breakpoint          '
ke04    DB 'Overflow        '
ke05    DB 'Array bounds error      '
ke06    DB 'Invalid OP-code     '
ke07    DB '80387 not present       '
ke08    DB 'Double fault        '
ke09    DB '80387 overrun       '
ke0A    DB 'Invalid TSS         '
ke0B    DB 'Segment not present     '
ke0C    DB 'Stack fault         '
ke0D    DB 'Protection fault    '
ke0E    DB 'Page fault          '
ke0F    DB 'Unknown Fault       '
ke10    DB '80387 error         '
ke11    DB 'Cannot emulate      '
ke12    DB 'Cannot emulate 80387    '
ke13    DB 'Now in real mode    '
ke14    DB '----------------------- '
ke15    DB 'Illegal int request     '
ke16    DB 'Undefined method    '
ke17    DB 'Invalid handle      '
ke18    DB 'Invalid selector    '

dword_reg_tab1:
    DB 'EAX='
    DW OFFSET p_tss_eax
    DB 'EBX='
    DW OFFSET p_tss_ebx
    DB 'ECX='
    DW OFFSET p_tss_ecx
    DB 'EDX='
    DW OFFSET p_tss_edx
    DB 'ESI='
    DW OFFSET p_tss_esi
    DB 'EDI='
    DW OFFSET p_tss_edi
    DB 0
dword_reg_tab2:
    DB 'EPC='
    DW OFFSET p_tss_eip
    DB 'ESP='
    DW OFFSET p_tss_esp
    DB 'EBP='
    DW OFFSET p_tss_ebp
    DB 0
word_reg_tab:
    DB 'CS='
    DW OFFSET p_tss_cs
    DB 'SS='
    DW OFFSET p_tss_ss
    DB 'DS='
    DW OFFSET p_tss_ds
    DB 'ES='
    DW OFFSET p_tss_es
    DB 'FS='
    DW OFFSET p_tss_fs
    DB 'GS='
    DW OFFSET p_tss_gs
    DB 0

pm_es   EQU -12

abort_pretask:
    cli
    cld
;
    mov ax,system_data_sel
    mov ds,ax
    mov ax,1
    xchg ax,ds:shut_spinlock
    or ax,ax
    jz abort_pretask_do

abort_pretask_block:
    jmp abort_pretask_block    

abort_pretask_do:    
    push es
    movzx bx,al
;
    mov ax,system_data_sel
    mov es,ax
    mov eax,[bp].vm_eip
    mov es:p_tss_eip,eax
    mov eax,[bp].vm_eflags
    mov es:p_tss_eflags,eax
    mov eax,[bp].vm_eax
    mov es:p_tss_eax,eax
    mov es:p_tss_ecx,ecx
    mov es:p_tss_edx,edx
    mov eax,[bp].vm_ebx
    mov es:p_tss_ebx,eax
    movzx eax,bp
    add eax,18
    mov es:p_tss_esp,eax
    mov es:p_tss_esi,esi
    mov es:p_tss_edi,edi
    mov ax,[bp].vm_cs
    mov es:p_tss_cs,ax
    mov es:p_tss_ss,ss
    mov ax,[bp].pm_ds
    mov es:p_tss_ds,ax
    mov ax,[bp].pm_es
    mov es:p_tss_es,ax
    mov es:p_tss_fs,fs
    mov es:p_tss_gs,gs
    mov bp,[bp].vm_bp
    mov es:p_tss_ebp,ebp
    sldt ax
    mov es:p_tss_ldt,ax       
    mov ax,es
    mov gs,ax
;
abort_fatal_write:
    push bx
    call get_video
    mov es,bx
    mov fs,bx
    xor di,di
    xor dx,dx
    mov cx,80*25
    xor ax,ax
    rep stosw
    pop bx
;
    mov di,bx
    shl di,3
    mov ax,di
    add ax,ax
    add di,ax
    mov ax,cs
    mov es,ax
    add di,OFFSET error_code_tab
    mov cx,24
    mov ah,11
    call write_stg
    add dl,2
    call write_fault
    inc dh
    xor dl,dl
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET dword_reg_tab1
    mov cl,10
    xor dl,dl
    call write_dword_reg
    inc dh
    xor dl,dl
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET dword_reg_tab2
    mov cl,10
    xor dl,dl
    call write_dword_reg
    call write_eflags
    inc dh
    xor dl,dl
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET word_reg_tab
    mov cl,10
    xor dl,dl
    call write_word_reg
halt_sys:
    jmp halt_sys
    
abort_task:
    cli
    cld
;
    mov ax,system_data_sel
    mov ds,ax
    mov ax,1
    xchg ax,ds:shut_spinlock
    or ax,ax
    jz abort_task_do

abort_task_block:
    jmp abort_task_block    

abort_task_do:    
    mov ax,gdt_sel
    mov ds,ax
    mov bx,dosB800
    mov edx,[bx+2]
    and edx,0FFFFFFh
    shr edx,12
    mov ecx,edx
    shl ecx,12
    or cl,7
    shl edx,2
    mov ax,process_page_sel
    mov ds,ax
    mov [edx],ecx   
    mov ax,sys_page_sel
    mov ds,ax
    mov [edx],ecx
    mov ecx,cr3
    mov cr3,ecx
;
    mov ax,dosB800
    mov es,ax
    mov fs,ax
    xor di,di
    mov cx,80*25
    mov ax,0
    rep stosw
;
    xor dx,dx
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
remove_next_waiting:
    mov ax,[si]
    or ax,ax
    jz abort_system
    push si
    mov es,[si]
    push di
    push ds
    mov di,es:p_prev
    cmp di,[si]
    mov [si],di
    mov si,es:p_next
    mov ds,di
    mov ds:p_next,si
    mov ds,si
    mov ds:p_prev,di
    pop ds
    pop di
    pop si
    jne not_empty_r
    mov word ptr [si],0
not_empty_r:
    push ds
    push si
    mov ax,es
    mov cl,11
    call write_hex_word
;
    add dl,2
    mov di,OFFSET thread_name
    mov cx,30
    mov ah,11
    call write_stg
;
    mov di,es:p_error_code
    mov gs,es:p_tss_data_sel
    shl di,3
    mov ax,di
    add ax,ax
    add di,ax
    mov ax,cs
    mov es,ax
    add di,OFFSET error_code_tab
    mov cx,24
    mov ah,11
    call write_stg
    add dl,2
    call write_fault
    inc dh
    xor dl,dl
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET dword_reg_tab1
    mov cl,10
    xor dl,dl
    call write_dword_reg
    inc dh
    xor dl,dl
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET dword_reg_tab2
    mov cl,10
    xor dl,dl
    call write_dword_reg
    call write_eflags
    inc dh
    xor dl,dl
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET word_reg_tab
    mov cl,10
    xor dl,dl
    call write_word_reg
    xor dl,dl
;
    pop si
    pop ds
    add dh,2
    jmp remove_next_waiting

abort_system:
    jmp abort_system


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
    mov ax,system_data_sel
    mov ds,ax
    mov ds:shut_spinlock,0
;
    mov ax,gdt_sel
    mov ds,ax
;
    mov bx,shutdown_pretask_gate
    mov word ptr [bx],OFFSET abort_pretask
    mov [bx+2],cs
    mov word ptr [bx+4],8400h
    mov word ptr [bx+6],0
;
    mov bx,shutdown_task_gate
    mov word ptr [bx],OFFSET abort_task
    mov [bx+2],cs
    mov word ptr [bx+4],8400h
    mov word ptr [bx+6],0
    ret
init    Endp

code    ENDS

.186

END init
