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
; VIRTBIOS.ASM
; Virtual BIOS environment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc

INCLUDE ..\os\int.def

list_entry      STRUC

list_link       DW ?
list_thread     DW ?
list_eax    DD ?
list_ebx    DD ?
list_ecx    DD ?
list_edx    DD ?
list_esi    DD ?
list_edi    DD ?
list_ebp    DD ?
list_ds     DW ?
list_es     DW ?
list_flags      DW ?
list_int    DB ?

list_entry      ENDS

data    SEGMENT byte public 'DATA'

bios_thread     DW ?
bios_list       DW ?
bios_section    section_typ <>

data    ENDS

code    SEGMENT byte public 'CODE'

.386p

    assume cs:code


;
; BIOS code
;

bios_start:
    xor bx,bx
    mov ds,bx
    mov bx,15h * 4
    mov word ptr ds:[bx],OFFSET int15
    mov word ptr ds:[bx+2],cs    
;
    mov bx,0C000h
    mov ds,bx
    mov ax,ds:[0]
    xor bx,bx
    mov ds,bx
    cmp ax,0AA55h
    jne nocall
;
    db 9Ah
    dw 3
    dw 0C000h

nocall:
    iret

default_int:
    int 3
    iret

int15:
    push bp
    mov bp,sp
;    
    cmp ah,5Fh
    je int15_err
;
    cmp ah,4Eh
    je int15_err    
;
    int 3

int15_err:
    mov ah,86h
    or byte ptr [bp+6],1
;
    pop bp
    iret    
        
bios_end:

;
; Driver code
;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       DecodeSelector
;
;       DESCRIPTION:    Decode a selector
;
;       PARAMETERS:     BX      Selector
;
;       RETURNS:    EDX     Base
;               ECX     Limit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeSelector  Proc near
    push ds
;
    test bx,7
    jnz decode_sel_fail
;
    GetSelectorBaseSize
    jc decode_sel_fail
;
    sub edx,global_page_linear
    jc decode_sel_fail
;
    cmp edx,global_page_size
    jae decode_sel_fail
;
    test dx,0FFFh
    jnz decode_sel_fail
;
    add edx,global_page_linear
    clc
    jmp decode_sel_done

decode_sel_fail:
    stc

decode_sel_done:
    pop ds
    ret
DecodeSelector  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       HandleInputSel
;
;       DESCRIPTION:    Handle input selectors
;
;       PARAMETERS:     FS      List
;
;       RETURNS:    DS,ES   BIOS selectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleInputSel  Proc near
    mov bx,fs:list_ds
    call DecodeSelector
    jc handle_input_ds_fail
;
    mov esi,edx
    mov edi,10000h
    dec ecx
    shr ecx,12
    inc ecx
    cmp ecx,10h
    jbe handle_input_ds_move
;
    mov ecx,10h

handle_input_ds_move:
    MovePageEntries
;
    mov ax,v86_bios_ds_sel
    mov ds,ax
    jmp handle_input_es

handle_input_ds_fail:
    xor ax,ax
    mov ds,ax

handle_input_es:
    mov bx,fs:list_es
    call DecodeSelector
    jc handle_input_es_fail
;
    mov esi,edx
    mov edi,20000h
    dec ecx
    shr ecx,12
    inc ecx
    cmp ecx,10h
    jbe handle_input_es_move
;
    mov ecx,10h

handle_input_es_move:
    MovePageEntries
;
    mov ax,v86_bios_es_sel
    mov es,ax
    jmp handle_input_done

handle_input_es_fail:
    xor ax,ax
    mov es,ax

handle_input_done:
    ret
HandleInputSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       HandleOutputSel
;
;       DESCRIPTION:    Handle output selectors
;
;       PARAMETERS:     FS      List
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleOutputSel Proc near
    mov ax,ds
    or ax,ax
    jz handle_output_es
;
    cmp ax,v86_bios_ds_sel
    je handle_output_ds_same
;
    mov bx,fs:list_ds
    call DecodeSelector
    jc handle_output_es
;
    mov edi,edx
;
    mov bx,ds
    push ecx
    GetSelectorBaseSize
    pop ecx
    mov esi,edx
    dec ecx
    shr ecx,12
    inc ecx
    cmp ecx,10h
    jbe handle_output_ds_copy
;
    mov ecx,10h

handle_output_ds_copy:
    CopyPageEntries
    jmp handle_output_es

handle_output_ds_same:
    mov bx,fs:list_ds
    call DecodeSelector
    jc handle_output_es
;
    mov edi,edx
    mov esi,10000h
    dec ecx
    shr ecx,12
    inc ecx
    cmp ecx,10h
    jbe handle_output_ds_move
;
    mov ecx,10h

handle_output_ds_move:
    MovePageEntrieshandle_output_es:
handle_output_es:
    mov ax,es
    or ax,ax
    jz handle_output_done
;
    cmp ax,v86_bios_es_sel
    je handle_output_es_same
;
    mov bx,fs:list_es
    call DecodeSelector
    jc handle_output_done
;
    mov edi,edx
;
    mov bx,es
    push ecx
    GetSelectorBaseSize
    pop ecx
    mov esi,edx
    dec ecx
    shr ecx,12
    inc ecx
    cmp ecx,10h
    jbe handle_output_es_copy
;
    mov ecx,10h

handle_output_es_copy:
    CopyPageEntries    
    jmp handle_output_done

handle_output_es_same:
    mov bx,fs:list_es
    call DecodeSelector
    jc handle_output_done
;
    mov edi,edx
    mov esi,20000h
    dec ecx
    shr ecx,12
    inc ecx
    cmp ecx,10h
    jbe handle_output_es_move
;
    mov ecx,10h

handle_output_es_move:
    MovePageEntries

handle_output_done:
    mov edi,10000h
    mov cx,20h

handle_output_zero:
    mov edx,edi
    GetPageEntry
;
    push eax
    push ebx
    xor ebx,ebx        
    mov eax,2
    SetPageEntry
    pop ebx
    pop eax
;
    and ax,0F000h
    or eax,eax
    jz handle_output_zero_next
;
    FreePhysical

handle_output_zero_next:
    add edi,1000h
    loop handle_output_zero
;
    ret
HandleOutputSel Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitOptionRom
;
;       DESCRIPTION:    Init option ROMs
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitOptionRom    Proc near
    mov bx,300h
    xor ax,ax
    FindPciClass
    jc iorDone
;
    mov cl,30h
    mov eax,0FFFFF000h
    WritePciDword   
    ReadPciDword
    
iorDone:
    ret
InitOptionRom   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitBios
;
;       DESCRIPTION:    Init BIOS
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitBios    Proc near
    mov ax,flat_sel
    mov es,ax    
;
    AllocatePhysical32
    xor edx,edx
    or ax,7
    SetPageEntry
;
    mov ax,0F000h
    shl eax,16
    mov ax,OFFSET default_int
    xor edi,edi
    mov ecx,100h    
    rep stos dword ptr es:[edi]
;
    xor eax,eax
    mov ecx,300h
    rep stos dword ptr es:[edi]
;
    xor ebx,ebx
    mov eax,0A0007h
    mov edx,0A0000h
    mov cx,40h

rom_loop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop rom_loop
;
    AllocatePhysical32
    mov edx,0F0000h
    or ax,7
    SetPageEntry
;
    mov edi,edx
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET bios_start
    mov ecx,OFFSET bios_end - OFFSET bios_start
    rep movs es:[edi],ds:[esi]
;
    push word ptr 0F000h
    push word ptr 0
    CallVm
;
    ret    
InitBios    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       bios_process
;
;       DESCRIPTION:    BIOS process
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bios_name       DB 'Emulated BIOS',0

bios_process:
    GetThread
    mov ds,ax
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov eax,OFFSET tss32_io_bitmap + 2000h
    mov ecx,eax
    AllocateSmallLinear
    mov edi,edx
;
    push ds
    push ecx
    push esi
;
    push ecx
    mov ecx,OFFSET tss32_io_bitmap            
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov ax,io_bitmap_sel
    mov ds,ax
    xor esi,esi
    mov ecx,80h
    rep movs byte ptr es:[edi],ds:[esi]
    pop ecx
;       
    sub ecx,80h + OFFSET tss32_io_bitmap
    xor al,al
    rep stos byte ptr es:[edi]
;
    pop esi    
    pop ecx
    pop ds
;
    mov eax,cr3
    mov es:[edx].tss32_cr3,eax
;
    mov es:[edx].tss32_esp0,esp
    mov es:[edx].tss32_ess0,ss
    mov es:[edx].tss32_bitmap, OFFSET tss32_io_bitmap        
;
    AllocateGdt
    CreateTssSelector
    xchg bx,ds:p_tss_sel    
    FreeGdt
;    
    mov ax,1
    WaitMilliSec
;
    mov ax,flat_sel
    mov ds,ax
    mov bx,10h * 4
    push dword ptr ds:[bx]
    mov ax,3
    CallVm

bios_bitmap_done:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:bios_thread,ax
    jmp bios_proc_check

bios_proc_loop:
    WaitForSignal
    mov ax,SEG data
    mov ds,ax

bios_proc_check:
    mov ax,ds:bios_list
    or ax,ax
    jz bios_proc_loop
;
    EnterSection ds:bios_section
    mov fs,ds:bios_list
    mov ax,fs:list_link
    mov ds:bios_list,ax
    LeaveSection ds:bios_section
;
    mov ax,flat_sel
    mov ds,ax
    movzx bx,fs:list_int
    shl bx,2
    push dword ptr [bx]
;
    call HandleInputSel
    push fs:list_flags
    mov eax,cr3
    mov cr3,eax
    mov eax,fs:list_eax
    mov ebx,fs:list_ebx
    mov ecx,fs:list_ecx
    mov edx,fs:list_edx
    mov esi,fs:list_esi
    mov edi,fs:list_edi
    mov ebp,fs:list_ebp
    popf
    CallVm
;
    pushf
    pop fs:list_flags
    mov fs:list_eax,eax
    mov fs:list_ebx,ebx
    mov fs:list_ecx,ecx
    mov fs:list_edx,edx
    mov fs:list_esi,esi
    mov fs:list_edi,edi
    mov fs:list_ebp,ebp
    call HandleOutputSel
;
    mov bx,fs:list_thread
    xor ax,ax
    mov fs,ax
    Signal
    jmp bios_proc_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       V86BiosInt
;
;       DESCRIPTION:    Run int in real BIOS
;
;       PARAMETERS:     Stack   Int #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

v86_bios_int_name       DB 'V86 BIOS Int',0

V86_bios_int    Proc far
    push ds
    push es
;
    push eax
    pushf
    mov eax,SIZE list_entry
    AllocateSmallGlobalMem
    pop es:list_flags
    pop es:list_eax
    pop es:list_es
    pop es:list_ds
    mov es:list_ebx,ebx
    mov es:list_ecx,ecx
    mov es:list_edx,edx
    mov es:list_esi,esi
    mov es:list_edi,edi
    mov es:list_ebp,ebp
    mov bp,sp
    mov al,[bp+8]
    mov es:list_int,al      
;
    GetThread
    mov es:list_thread,ax
    mov ax,SEG data
    mov ds,ax
;
    ClearSignal
    EnterSection ds:bios_section
    mov ax,ds:bios_list
    mov es:list_link,ax
    mov ds:bios_list,es
    LeaveSection ds:bios_section
;
    mov bx,ds:bios_thread
    Signal
    WaitForSignal
;
    mov eax,es:list_eax
    mov ebx,es:list_ebx
    mov ecx,es:list_ecx
    mov edx,es:list_edx
    mov esi,es:list_esi
    mov edi,es:list_edi
    mov ebp,es:list_ebp
    push es:list_ds
    push es:list_es
    push es:list_flags
    FreeMem
    popf
;
    pop es
    pop ds
    Retf32Pop 2
v86_bios_int    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       init_process
;
;       DESCRIPTION:    init BIOS process
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process    PROC far
    push ds
    push es
    pusha
;
    call InitBios
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET bios_process
    mov edi,OFFSET bios_name
    mov ecx,stack0_size
    mov ax,5
    CreateThread
;    
    popa
    pop es
    pop ds
    retf32
init_process    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   INIT
;
;               DESCRIPTION:    Init driver
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov bx,SEG data
    mov ds,bx
    InitSection ds:bios_section
    mov ds:bios_list,0
    mov ds:bios_thread,0
;
    mov bx,v86_bios_ds_sel
    mov edx,10000h
    mov ecx,10000h
    CreateDataSelector16
;
    mov bx,v86_bios_es_sel
    mov edx,20000h
    mov ecx,10000h
    CreateDataSelector16
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET init_process
    HookInitAcpi
;
    mov esi,OFFSET v86_bios_int
    mov edi,OFFSET v86_bios_int_name
    mov cl,1
    mov ax,v86_bios_int_nr
    RegisterOsGate
    clc
    ret
init   ENDP

code    ENDS

    END init
