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
; EMCOM.ASM
; Utility functions for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os\protseg.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\os\system.def
include ..\os\int.def

    .386p

include emulate.inc
include emseg.inc

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCsBitness
;
;           DESCRIPTION:    Get bitness of code segment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetCsBitness
    
GetCsBitness    PROC near
    mov bx,[ebp].reg_cs
    test byte ptr [ebp+2].reg_eflags,2
    clc
    jnz get_cs_bitness_done

get_cs_bitness_pm:
    test bx,4
    jz get_cs_bitness_gdt

get_cs_bitness_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp get_cs_bitness_test

get_cs_bitness_gdt:
    mov ax,gdt_sel
    mov ds,ax

get_cs_bitness_test:
    and bx,0FFF8h
    mov bl,[bx+6]
    test bl,40h
    jz get_cs_bitness_done
    or byte ptr [ebp].em_flags,cs32 OR d32 OR a32

get_cs_bitness_done:
    ret     
GetCsBitness    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetSsBitness
;
;           DESCRIPTION:    Get bitness of stack segment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetSsBitness
    
GetSsBitness    PROC near
    mov bx,[ebp].reg_ss
    test byte ptr [ebp+2].reg_eflags,2
    clc
    jnz get_ss_bitness_done

get_ss_bitness_pm:
    test bx,4
    jz get_ss_bitness_gdt

get_ss_bitness_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp get_ss_bitness_test

get_ss_bitness_gdt:
    mov ax,gdt_sel
    mov ds,ax

get_ss_bitness_test:
    and bx,0FFF8h
    mov bl,[bx+6]
    test bl,40h
    jz get_ss_bitness_done
    or byte ptr [ebp].em_flags,ss32

get_ss_bitness_done:
    ret     
GetSsBitness    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadSegmentToLinear
;
;           DESCRIPTION:    Convert segment:offset pair into linear address & size
;
;           PARAMETERS:         SI:EBX      ADDRESS
;
;           RETURNS:        EBX         LINEAR ADDRESS
;                           ECX         # OF VALID BYTES FROM LINEAR ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadSegmentToLinear

ReadSegmentToLinear     PROC near
    movzx esi,si
    mov si,[ebp+esi]
    test byte ptr [ebp+2].reg_eflags,2
    jnz read_segment_to_linear_vm

read_segment_to_linear_pm:
    test si,4
    jz read_segment_to_linear_gdt

read_segment_to_linear_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp read_segment_to_linear_check_selector

read_segment_to_linear_gdt:
    mov ax,gdt_sel
    mov ds,ax

read_segment_to_linear_check_selector:
    movzx esi,si
    and si,0FFF8h
    mov al,[si+5]
    test al,80h
    jz EmulateError
;
    test al,10h
    jz EmulateError
;
    shr al,5
    and al,3
    mov ah,byte ptr [ebp].reg_cs
    and ah,3
    cmp al,ah
    jc EmulateError
;
    xor ch,ch
    mov cl,[si+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[si]
    test byte ptr [si+6],80h
    jz read_segment_to_linear_small
;
    shl ecx,12
    or cx,0FFFh

read_segment_to_linear_small:
    mov al,[si+5]
    test al,4
    jz read_segment_up

read_segment_down:
    jmp EmulateError

read_segment_up:    
    sub ecx,ebx
    jc EmulateError
;
    inc ecx
    mov edx,[si+2]
    rol edx,8
    mov dl,[si+7]
    ror edx,8
    add ebx,edx
    jmp read_segment_to_linear_done 

read_segment_to_linear_vm:
    mov ecx,0FFFFh
    sub ecx,ebx
    jc EmulateError
;
    inc ecx
    movzx edx,si
    shl edx,4
    add ebx,edx

read_segment_to_linear_done:
    ret
ReadSegmentToLinear     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteSegmentToLinear
;
;           DESCRIPTION:    Convert segment:offset pair into linear address & size
;
;           PARAMETERS:         SI:EBX      ADDRESS
;
;           RETURNS:        EBX         LINEAR ADDRESS
;                           ECX         # OF VALID BYTES FROM LINEAR ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteSegmentToLinear

WriteSegmentToLinear    PROC near
    movzx esi,si
    mov si,[ebp+esi]
    test byte ptr [ebp+2].reg_eflags,2
    jnz write_segment_to_linear_vm

write_segment_to_linear_pm:
    test si,4
    jz write_segment_to_linear_gdt

write_segment_to_linear_ldt:
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    jmp write_segment_to_linear_check_selector

write_segment_to_linear_gdt:
    mov ax,gdt_sel
    mov ds,ax

write_segment_to_linear_check_selector:
    movzx esi,si
    and si,0FFF8h
    mov al,[si+5]
    test al,80h
    jz EmulateError
;
    test al,10h
    jz EmulateError
;
    test al,8
    jnz EmulateError
;
    test al,2
    jz EmulateError
;
    shr al,5
    and al,3
    mov ah,byte ptr [ebp].reg_cs
    and ah,3
    cmp al,ah
    jc EmulateError
;
    xor ch,ch
    mov cl,[si+6]
    and cl,0Fh
    shl ecx,16
    mov cx,[si]
    test byte ptr [si+6],80h
    jz write_segment_to_linear_small
;
    shl ecx,12
    or cx,0FFFh

write_segment_to_linear_small:
    mov al,[si+5]
    test al,4
    jz write_segment_up

write_segment_down:
    jmp EmulateError

write_segment_up:    
    sub ecx,ebx
    jc EmulateError
;
    inc ecx
    mov edx,[si+2]
    rol edx,8
    mov dl,[si+7]
    ror edx,8
    add ebx,edx
    jmp write_segment_to_linear_done    

write_segment_to_linear_vm:
    mov ecx,0FFFFh
    sub ecx,ebx
    jc EmulateError
;
    inc ecx
    movzx edx,si
    shl edx,4
    add ebx,edx

write_segment_to_linear_done:
    ret
WriteSegmentToLinear    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckReadPage
;
;           DESCRIPTION:    Check if # of bytes can be read from page
;
;           PARAMETERS:         CX          Number of bytes to check
;                           EBX         Linear base address
;
;           RETURNS:        NC          Can be read, no trapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckReadPage   Proc near
    push ebx
;
    mov eax,ebx

check_read_page_loop:
    push eax
    mov edx,ebx
    GetPageEntry
    mov edx,eax
    pop eax
;
    and dl,7
    cmp dl,6
    je check_read_page_hooks
;
    test dl,1
    jz check_read_page_check_dir
;
    test dl,4
    jnz check_read_page_check_dir
;
    mov dl,byte ptr [ebp].reg_cs
    and dl,3
    cmp dl,3
    je EmulateError

check_read_page_check_dir:
    push eax
    push ebx
;
    mov edx,eax
    GetPageDir
    mov dl,al
;   
    pop ebx 
    pop eax
    test dl,4
    jnz check_read_page_next
;
    mov dl,byte ptr [ebp].reg_cs
    and dl,3
    cmp dl,3
    je EmulateError
    jmp check_read_page_next

check_read_page_hooks:
    test dh,80h
    jz check_read_page_next
;
    shr edx,16
    or dx,dx
    jz EmulateError
    stc
    jmp check_read_page_done

check_read_page_next:
    mov dx,ax
    and ax,0FFFh
    mov bx,1000h
    sub bx,ax
    sub cx,bx
    cmc
    jnc check_read_page_done
;
    mov ax,dx
    and ax,0F000h
    add eax,1000h
    mov ebx,eax
    jmp check_read_page_loop

check_read_page_done:
    pop ebx
    ret
CheckReadPage   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckWritePage
;
;           DESCRIPTION:    Check if # of bytes can be written from page
;
;           PARAMETERS:         CX          Number of bytes to check
;                           EBX         Linear base address
;
;           RETURNS:        NC          Can be written, no trapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckWritePage  Proc near
    push ebx
;
    mov eax,ebx

check_write_page_loop:
    push eax
    mov edx,ebx
    GetPageEntry
    mov edx,eax
    pop eax
;
    and dl,7
    cmp dl,6
    je check_write_page_hooks
;
    test dl,1
    jz check_write_page_check_dir
;
    test dl,2
    jz EmulateError
;
    test dl,4
    jnz check_write_page_check_dir
;
    mov dl,byte ptr [ebp].reg_cs
    and dl,3
    cmp dl,3
    je EmulateError

check_write_page_check_dir:
    push eax
    push ebx
;
    mov edx,eax
    GetPageDir
    mov dl,al
;   
    pop ebx 
    pop eax
    test dl,2
    jz EmulateError
;
    test dl,4
    jnz check_write_page_next
;
    mov dl,byte ptr [ebp].reg_cs
    and dl,3
    cmp dl,3
    je EmulateError
    jmp check_write_page_next

check_write_page_hooks:
    test dh,80h
    jz check_write_page_next
;
    shr edx,16
    or dx,dx
    jz EmulateError
    stc
    jmp check_write_page_done

check_write_page_next:
    mov dx,ax
    and ax,0FFFh
    mov bx,1000h
    sub bx,ax
    sub cx,bx
    cmc
    jnc check_write_page_done
;
    mov ax,dx
    and ax,0F000h
    add eax,1000h
    mov ebx,eax
    jmp check_write_page_loop

check_write_page_done:
    pop ebx
    ret
CheckWritePage  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadTrappedByte
;
;           DESCRIPTION:    Read trapped byte
;
;           PARAMETERS:         EBX         Linear base address
;
;           RETURNS:        AL          Data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadTrappedByte Proc near
    push ebx
;
	mov ecx,ebx
    push eax
    mov edx,ebx
    GetPageEntry
    mov edx,eax
    and al,7
    cmp al,6
    pop eax
    jne read_trapped_byte_normal
;
    test dh,80h
    jz read_trapped_byte_normal
;
    push cs
    push OFFSET read_trapped_byte_done
    and dx,7FF8h
    push dx
    shr edx,16
    push dx
    mov ebx,ecx
    clc
    retf

read_trapped_byte_normal:
    mov bx,flat_sel
    mov ds,bx
    mov al,[ecx]

read_trapped_byte_done:
    pop ebx
    ret
ReadTrappedByte Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteTrappedByte
;
;           DESCRIPTION:    Write trapped byte
;
;           PARAMETERS:         EBX         Linear base address
;                           AL          Data to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteTrappedByte    Proc near
    push ebx
;
	mov ecx,ebx
    push eax
    mov edx,ebx
    GetPageEntry
    mov edx,eax
    and al,7
    cmp al,6
    pop eax
    jne write_trapped_byte_normal
;
    test dh,80h
    jz write_trapped_byte_normal
;
    push cs
    push OFFSET write_trapped_byte_done
    and dx,7FF8h
    push dx
    shr edx,16
    push dx
    mov ebx,ecx
    stc
    retf

write_trapped_byte_normal:
    mov bx,flat_sel
    mov ds,bx
    mov [ecx],al

write_trapped_byte_done:
    pop ebx
    ret
WriteTrappedByte    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadByte
;
;           DESCRIPTION:    Read one byte of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;
;           RETURNS:        AL          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadByte

ReadByte    Proc near
    push ebx
    push ecx
    push si
;
    call ReadSegmentToLinear
;
    mov ecx,1
    call CheckReadPage
    jc read_byte_trapped
;
    mov ax,flat_sel
    mov ds,ax
    mov al,[ebx]
    jmp read_byte_done

read_byte_trapped:
    call ReadTrappedByte

read_byte_done:
    pop si
    pop ecx
    pop ebx
    ret
ReadByte    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadWord
;
;           DESCRIPTION:    Read one word of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;
;           RETURNS:        AX          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadWord

ReadWord    Proc near
    push ebx
    push ecx
    push si
;
    call ReadSegmentToLinear
    cmp ecx,2
    jc EmulateError
;
    mov ecx,2
    call CheckReadPage
    jc read_word_trapped
;
    mov ax,flat_sel
    mov ds,ax
    mov ax,[ebx]
    jmp read_word_done

read_word_trapped:
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    mov bl,al
    pop ax
    mov ah,bl

read_word_done:
    pop si
    pop ecx
    pop ebx
    ret
ReadWord    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadDword
;
;           DESCRIPTION:    Read one dword of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;
;           RETURNS:        EAX         DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadDword

ReadDword       Proc near
    push ebx
    push ecx
    push si
;
    call ReadSegmentToLinear
    cmp ecx,4
    jc EmulateError
;
    mov ecx,4
    call CheckReadPage
    jc read_dword_trapped
;
    mov ax,flat_sel
    mov ds,ax
    mov eax,[ebx]
    jmp read_dword_done

read_dword_trapped:
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    mov ah,al
    pop bx
    mov al,bl
    pop bx
    shl eax,8
    mov al,bl
    pop bx
    shl eax,8
    mov al,bl

read_dword_done:
    pop si
    pop ecx
    pop ebx
    ret
ReadDword       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadFword
;
;           DESCRIPTION:    Read one 48-bit word of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;
;           RETURNS:        DX:EAX      DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadFword

ReadFword       Proc near
    push ebx
    push ecx
    push si
;
    call ReadSegmentToLinear
    cmp ecx,6
    jc EmulateError
;
    mov ecx,6
    call CheckReadPage
    jc read_fword_trapped
;
    mov ax,flat_sel
    mov ds,ax
    mov eax,[ebx]
    mov dx,[ebx+4]
    jmp read_fword_done

read_fword_trapped:
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    mov dh,al
    pop bx
    mov dl,bl
    pop bx
    mov ah,bl
    pop bx
    mov al,bl
    pop bx
    shl eax,8
    mov al,bl
    pop bx
    shl eax,8
    mov al,bl

read_fword_done:
    pop si
    pop ecx
    pop ebx
    ret
ReadFword       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadQword
;
;           DESCRIPTION:    Read one qword of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;
;           RETURNS:        EDX:EAX     DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadQword

ReadQword       Proc near
    push ebx
    push ecx
    push si
;
    call ReadSegmentToLinear
    cmp ecx,8
    jc EmulateError
;
    mov ecx,8
    call CheckReadPage
    jc read_qword_trapped
;
    mov ax,flat_sel
    mov ds,ax
    mov eax,[ebx]
    mov edx,[ebx+4]
    jmp read_qword_done

read_qword_trapped:
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    mov dh,al
    pop bx
    mov dl,bl
    pop bx
    shl edx,8
    mov dl,bl
    pop bx
    shl edx,8
    mov dl,bl
    pop bx
    mov ah,bl
    pop bx
    mov al,bl
    pop bx
    shl eax,8
    mov al,bl
    pop bx
    shl eax,8
    mov al,bl

read_qword_done:
    pop si
    pop ecx
    pop ebx
    ret
ReadQword       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadTbyte
;
;           DESCRIPTION:    Read one tbyte of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;
;           RETURNS:        CX:EDX:EAX          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadTbyte

ReadTbyte       Proc near
    push ebx
    push si
;
    call ReadSegmentToLinear
    cmp ecx,10
    jc EmulateError
;
    mov ecx,10
    call CheckReadPage
    jc read_tbyte_trapped
;
    mov ax,flat_sel
    mov ds,ax
    mov eax,[ebx]
    mov edx,[ebx+4]
    mov cx,[ebx+8]
    jmp read_tbyte_done

read_tbyte_trapped:
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    push ax
    inc ebx
    call ReadTrappedByte
    mov ch,al
    pop bx
    mov cl,bl
    pop bx
    mov dh,bl
    pop bx
    mov dl,bl
    pop bx
    shl edx,8
    mov dl,bl
    pop bx
    shl edx,8
    mov dl,bl
    pop bx
    mov ah,bl
    pop bx
    mov al,bl
    pop bx
    shl eax,8
    mov al,bl
    pop bx
    shl eax,8
    mov al,bl

read_tbyte_done:
    pop si
    pop ebx
    ret
ReadTbyte       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteByte
;
;           DESCRIPTION:    Write one byte of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;                           AL          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteByte

WriteByte       Proc near
    push ebx
    push ecx
    push si
;
    push ax
    call WriteSegmentToLinear
;
    mov ecx,1
    call CheckWritePage
    jc write_byte_trapped
;
    mov ax,flat_sel
    mov ds,ax
    pop ax
    mov [ebx],al
    jmp write_byte_done

write_byte_trapped:
    pop ax
    call WriteTrappedByte

write_byte_done:
    pop si
    pop ecx
    pop ebx
    ret
WriteByte       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteWord
;
;           DESCRIPTION:    Write one word of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;                           AX          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteWord

WriteWord       Proc near
    push ebx
    push ecx
    push si
;
    push ax
    call WriteSegmentToLinear
    cmp ecx,2
    jc EmulateError
;
    mov ecx,2
    call CheckWritePage
    jc write_word_trapped
;
    mov ax,flat_sel
    mov ds,ax
    pop ax
    mov [ebx],ax
    jmp write_word_done

write_word_trapped:
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte

write_word_done:
    pop si
    pop ecx
    pop ebx
    ret
WriteWord       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteDword
;
;           DESCRIPTION:    Write one dword of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;                           EAX         DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteDword

WriteDword      Proc near
    push ebx
    push ecx
    push si
;
    push eax
    call WriteSegmentToLinear
    cmp ecx,4
    jc EmulateError
;
    mov ecx,4
    call CheckWritePage
    jc write_dword_trapped
;
    mov ax,flat_sel
    mov ds,ax
    pop eax
    mov [ebx],eax
    jmp write_dword_done

write_dword_trapped:
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte
    inc ebx
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte

write_dword_done:
    pop si
    pop ecx
    pop ebx
    ret
WriteDword      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteFword
;
;           DESCRIPTION:    Write one fword of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;                           DX:EAX      DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteFword

WriteFword      Proc near
    push ebx
    push ecx
    push si
;
    push dx
    push eax
    call WriteSegmentToLinear
    cmp ecx,6
    jc EmulateError
;
    mov ecx,6
    call CheckWritePage
    jc write_fword_trapped
;
    mov ax,flat_sel
    mov ds,ax
    pop eax
    mov [ebx],eax
    pop dx
    mov [ebx+4],dx
    jmp write_fword_done

write_fword_trapped:
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte
    inc ebx
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte
    inc ebx
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte

write_fword_done:
    pop si
    pop ecx
    pop ebx
    ret
WriteFword      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteQword
;
;           DESCRIPTION:    Write one qword of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;                           EDX:EAX     DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteQword

WriteQword      Proc near
    push ebx
    push ecx
    push si
;
    push edx
    push eax
    call WriteSegmentToLinear
    cmp ecx,8
    jc EmulateError
;
    mov ecx,8
    call CheckWritePage
    jc write_qword_trapped
;
    mov ax,flat_sel
    mov ds,ax
    pop eax
    mov [ebx],eax
    pop edx
    mov [ebx+4],edx
    jmp write_qword_done

write_qword_trapped:
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte
    inc ebx
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte
    inc ebx
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte
    inc ebx
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte

write_qword_done:
    pop si
    pop ecx
    pop ebx
    ret
WriteQword      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteTbyte
;
;           DESCRIPTION:    Write one tbyte of data
;
;           PARAMETERS:         SI:EBX  SEGMENT:OFFSET ADDRESS
;                           CX:EDX:EAX          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteTbyte

WriteTbyte      Proc near
    push ebx
    push si
;
    push cx
    push edx
    push eax
    call WriteSegmentToLinear
    cmp ecx,10
    jc EmulateError
;
    mov ecx,10
    call CheckWritePage
    jc write_tbyte_trapped
;
    mov ax,flat_sel
    mov ds,ax
    pop eax
    mov [ebx],eax
    pop edx
    mov [ebx+4],edx
    pop cx
    mov [ebx+8],cx
    jmp write_tbyte_done

write_tbyte_trapped:
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte
    inc ebx
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte
    inc ebx
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte
    inc ebx
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte
    inc ebx
    pop ax
    push ax
    call WriteTrappedByte
    inc ebx
    pop ax
    mov al,ah
    call WriteTrappedByte

write_tbyte_done:
    pop si
    pop ebx
    ret
WriteTbyte      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PushWord
;
;           DESCRIPTION:    push word onto stack
;
;           PARAMETERS:         AX          data to push
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PushWord

PushWord    Proc near
    test byte ptr [ebp].reg_eflags+2,2
    jnz push_word_normal
;
    test byte ptr [ebp].reg_cs,3
    jnz push_word_normal

push_word_kernel:
    cld
    push cx
    push si
    push di
    mov cx,ss
    mov es,cx
    mov si,sp
    sub sp,2
    mov     di,sp
    mov cx,word ptr [ebp].reg_esp
    add cx,18
    sub cx,si
    shr cx,1
    rep movs word ptr es:[di],es:[si]
    stosw
    pop di
    pop si
    pop cx
    sub ebp,2
    sub word ptr [ebp].reg_esp,2
    ret

push_word_normal:
    push si
    push ebx
    mov si,OFFSET reg_ss
    test byte ptr [ebp].em_flags,ss32
    jz push_word16

push_word32:
    sub dword ptr [ebp].reg_esp,2
    mov ebx,[ebp].reg_esp
    call WriteWord
    pop ebx
    pop si
    ret

push_word16:
    sub word ptr [ebp].reg_esp,2
    movzx ebx,word ptr [ebp].reg_esp
    call WriteWord
    pop ebx
    pop si
    ret
PushWord    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PushDword
;
;           DESCRIPTION:    push dword onto stack
;
;           PARAMETERS:         EAX         data to push
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PushDword

PushDword       Proc near
    test byte ptr [ebp].reg_eflags+2,2
    jnz push_dword_normal
    test byte ptr [ebp].reg_cs,3
    jnz push_dword_normal

push_dword_kernel:
    cld
    push cx
    push si
    push di
    mov cx,ss
    mov es,cx
    mov si,sp
    sub sp,4
    mov     di,sp
    mov cx,word ptr [ebp].reg_esp
    add cx,18
    sub cx,si
    shr cx,1
    rep movs word ptr es:[di],es:[si]
    stosd
    pop di
    pop si
    pop cx
    sub ebp,4
    sub word ptr [ebp].reg_esp,4

push_dword_normal:
    push si
    push ebx
    mov si,OFFSET reg_ss
    test byte ptr [ebp].em_flags,ss32
    jz push_dword16

push_dword32:
    sub dword ptr [ebp].reg_esp,4
    mov ebx,[ebp].reg_esp
    call WriteDword
    pop ebx
    pop si
    ret

push_dword16:
    sub word ptr [ebp].reg_esp,4
    movzx ebx,word ptr [ebp].reg_esp
    call WriteDword
    pop ebx
    pop si
    ret
PushDword       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PopWord
;
;           DESCRIPTION:    pop word from stack
;
;           RETURNS:        AX          data popped
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PopWord

PopWord Proc near
    test byte ptr [ebp].reg_eflags+2,2
    jnz pop_word_normal
    test byte ptr [ebp].reg_cs,3
    jnz pop_word_normal

pop_word_kernel:
    push ebx
    mov ebx,[ebp].reg_esp
    mov ax,ss:[ebx+18]
    add [ebp].reg_esp,2
    pop ebx
    ret

pop_word_normal:
    push si
    push ebx
    mov si,OFFSET reg_ss
    test byte ptr [ebp].em_flags,ss32
    jz pop_word16

pop_word32:
    mov ebx,[ebp].reg_esp
    call ReadWord
    add dword ptr [ebp].reg_esp,2
    pop ebx
    pop si
    ret

pop_word16:
    movzx ebx,word ptr [ebp].reg_esp
    call ReadWord
    add word ptr [ebp].reg_esp,2
    pop ebx
    pop si
    ret
PopWord Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PopDword
;
;           DESCRIPTION:    pop dword from stack
;
;           RETURNS:        EAX         data popped
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PopDword

PopDword    Proc near
    test byte ptr [ebp].reg_eflags+2,2
    jnz pop_dword_normal
    test byte ptr [ebp].reg_cs,3
    jnz pop_dword_normal

pop_dword_kernel:
    push ebx
    mov ebx,[ebp].reg_esp
    mov eax,ss:[ebx+18]
    add [ebp].reg_esp,4
    pop ebx
    ret

pop_dword_normal:
    push si
    push ebx
    mov si,OFFSET reg_ss
    test byte ptr [ebp].em_flags,ss32
    jz pop_dword16

pop_dword32:
    mov ebx,[ebp].reg_esp
    call ReadDword
    add dword ptr [ebp].reg_esp,4
    pop ebx
    pop si
    ret

pop_dword16:
    movzx ebx,word ptr [ebp].reg_esp
    call ReadDword
    add word ptr [ebp].reg_esp,4
    pop ebx
    pop si
    ret
PopDword    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddToStack
;
;           DESCRIPTION:    add value to stack pointer
;
;           RETURNS:        EAX         value to add to (e)sp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddToStack

AddToStack      Proc near
    test byte ptr [ebp].reg_eflags+2,2
    jnz add_to_stack_normal
    test byte ptr [ebp].reg_cs,3
    jnz add_to_stack_normal

add_to_stack_kernel:
    add word ptr [ebp].reg_esp,ax
    ret

add_to_stack_normal:
    test byte ptr [ebp].em_flags,ss32
    jz add_to_stack16

add_to_stack32:
    add dword ptr [ebp].reg_esp,eax
    ret

add_to_stack16:
    add word ptr [ebp].reg_esp,ax
    ret
AddToStack      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SubFromStack
;
;           DESCRIPTION:    sub value from stack pointer
;
;           RETURNS:        EAX         value to sub from (e)sp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SubFromStack

SubFromStack    Proc near
    test byte ptr [ebp].reg_eflags+2,2
    jnz sub_from_stack_normal
;
    test byte ptr [ebp].reg_cs,3
    jnz sub_from_stack_normal

sub_from_stack_kernel:
    cld
    push cx
    push si
    push di
    mov cx,ss
    mov es,cx
    mov esi,esp
    sub esp,eax
    mov di,sp
    mov ecx,[ebp].reg_esp
    add ecx,18
    sub ecx,esi
    shr ecx,1
    rep movs word ptr es:[edi],es:[esi]
    pop edi
    pop esi
    pop ecx
    sub ebp,eax
    sub [ebp].reg_esp,eax
    ret

sub_from_stack_normal:
    test byte ptr [ebp].em_flags,ss32
    jz sub_from_stack16

sub_from_stack32:
    sub dword ptr [ebp].reg_esp,eax
    ret

sub_from_stack16:
    sub word ptr [ebp].reg_esp,ax
    ret
SubFromStack    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadCodeByte
;
;           DESCRIPTION:    Read byte from cs:eip, update to next position
;
;           RETURNS:        AL          data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadCodeByte

ReadCodeByte    Proc near
    mov si,OFFSET reg_cs
    test word ptr [ebp].em_flags,cs32
    jz read_code_byte16

read_code_byte32:
    mov ebx,[ebp].reg_eip
    push ebx
    call ReadByte
    pop ebx
    inc ebx
    mov [ebp].reg_eip,ebx
    ret

read_code_byte16:
    movzx ebx,word ptr [ebp].reg_eip
    push bx
    call ReadByte
    pop bx
    inc bx
    mov word ptr [ebp].reg_eip,bx
    ret
ReadCodeByte    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadCodeWord
;
;           DESCRIPTION:    Read word from cs:eip, update to next position
;
;           RETURNS:        AX          data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadCodeWord

ReadCodeWord    Proc near
    mov si,OFFSET reg_cs
    test word ptr [ebp].em_flags,cs32
    jz read_code_word16

read_code_word32:
    mov ebx,[ebp].reg_eip
    push ebx
    call ReadWord
    pop ebx
    add ebx,2
    mov [ebp].reg_eip,ebx
    ret

read_code_word16:
    movzx ebx,word ptr [ebp].reg_eip
    push bx
    call ReadWord
    pop bx
    add bx,2
    mov word ptr [ebp].reg_eip,bx
    ret
ReadCodeWord    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadCodeDword
;
;           DESCRIPTION:    Read dword from cs:eip, update to next position
;
;           RETURNS:        EAX         data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadCodeDword

ReadCodeDword   Proc near
    mov si,OFFSET reg_cs
    test word ptr [ebp].em_flags,cs32
    jz read_code_dword16

read_code_dword32:
    mov ebx,[ebp].reg_eip
    push ebx
    call ReadDword
    pop ebx
    add ebx,4
    mov [ebp].reg_eip,ebx
    ret

read_code_dword16:
    movzx ebx,word ptr [ebp].reg_eip
    push bx
    call ReadDword
    pop bx
    add bx,4
    mov word ptr [ebp].reg_eip,bx
    ret
ReadCodeDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadCodeFword
;
;           DESCRIPTION:    Read fword from cs:eip, update to next position
;
;           RETURNS:        DX:EAX      data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadCodeFword

ReadCodeFword   Proc near
    mov si,OFFSET reg_cs
    test word ptr [ebp].em_flags,cs32
    jz read_code_fword16

read_code_fword32:
    mov ebx,[ebp].reg_eip
    push ebx
    call ReadFword
    pop ebx
    add ebx,6
    mov [ebp].reg_eip,ebx
    ret

read_code_fword16:
    movzx ebx,word ptr [ebp].reg_eip
    push bx
    call ReadFword
    pop bx
    add bx,6
    mov word ptr [ebp].reg_eip,bx
    ret
ReadCodeFword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Inbyte
;
;           description:    read a byte from I/O port
;
;           PARAMETERS:         SS:ebp       CPU
;                           DX              IO PORT
;
;           RETURNS:        AL              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InByte

InByte Proc near
    push bx
    push cx
    push si
;
    mov ax,hook_in_sel
    mov ds,ax
    cmp dx,400h
    jnc in_byte_real
;
    mov bx,dx
    shl bx,3
    mov ax,[bx+4]
    or ax,ax
    jz in_byte_real
;
    push ds
    call fword ptr [bx]
    pop ds
    jmp in_byte_done

in_byte_real:
    in al,dx

in_byte_done:
    pop si
    pop cx
    pop bx
    ret
InByte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InWord
;
;           description:    read a word from I/O port
;
;           PARAMETERS:         SS:ebp       CPU
;                           DX              IO PORT
;
;           RETURNS:        AX              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InWord

InWord Proc near
    push bx
    push cx
    push dx
    push si
;
    mov ax,hook_in_sel
    mov ds,ax
    cmp dx,400h
    jnc in_word_real
;
    mov bx,dx
    shl bx,3
    mov ax,[bx+4]
    or ax,[bx+12]
    jz in_word_real
;
    mov ax,[bx+4]
    or ax,ax
    jz in_word_real1
;
    push ds
    push bx
    call fword ptr [bx]
    pop bx
    pop ds
    jmp in_word_done1

in_word_real1:
    in al,dx

in_word_done1:
    add bx,8
    push ax
    inc dx
    mov ax,[bx+4]
    or ax,ax
    jz in_word_real2
;
    push ds
    call fword ptr [bx]
    pop ds
    jmp in_word_done2

in_word_real2:
    in al,dx

in_word_done2:
    mov bl,al
    pop ax
    mov ah,bl
    jmp in_word_done

in_word_real:
    in ax,dx

in_word_done:
    pop si
    pop dx
    pop cx
    pop bx
    ret
InWord  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InDword
;
;           description:    read a dword from I/O port
;
;           PARAMETERS:         SS:ebp       CPU
;                           DX              IO PORT
;
;           RETURNS:        EAX             DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InDword

InDword Proc near
    push bx
    push cx
    push dx
    push si
;
    mov ax,hook_in_sel
    mov ds,ax
    cmp dx,400h
    jnc in_dword_real
;
    mov bx,dx
    shl bx,3
    mov ax,[bx+4]
    or ax,[bx+12]
    or ax,[bx+20]
    or ax,[bx+28]
    jz in_dword_real
;
    mov ax,[bx+4]
    or ax,ax
    jz in_dword_real1
;
    push ds
    push bx
    call fword ptr [bx]
    pop bx
    pop ds
    jmp in_dword_done1

in_dword_real1:
    in al,dx

in_dword_done1:
    add bx,8
    push ax
    inc dx
    mov ax,[bx+4]
    or ax,ax
    jz in_dword_real2
;
    push ds
    push bx
    call fword ptr [bx]
    pop bx
    pop ds
    jmp in_dword_done2

in_dword_real2:
    in al,dx

in_dword_done2:
    add bx,8
    push ax
    inc dx
    mov ax,[bx+4]
    or ax,ax
    jz in_dword_real3
;
    push ds
    push bx
    call fword ptr [bx]
    pop bx
    pop ds
    jmp in_dword_done3

in_dword_real3:
    in al,dx

in_dword_done3:
    add bx,8
    push ax
    inc dx
    mov ax,[bx+4]
    or ax,ax
    jz in_dword_real4
;
    push ds
    call fword ptr [bx]
    pop ds
    jmp in_dword_done4

in_dword_real4:
    in al,dx

in_dword_done4:
    mov ah,al
    pop bx
    mov al,bl
    pop bx
    shl eax,8
    mov al,bl
    pop bx
    shl eax,8
    mov al,bl
    jmp in_dword_done

in_dword_real:
    in eax,dx

in_dword_done:
    pop si
    pop dx
    pop cx
    pop bx
    ret
InDword Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OutByte
;
;           description:    write a byte to I/O port
;
;           PARAMETERS:         SS:ebp       CPU
;                           DX              IO PORT
;                           AL              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public OutByte

OutByte Proc near
    push bx
    push cx
    push si
;
    mov bx,hook_out_sel
    mov ds,bx
    cmp dx,400h
    jnc out_byte_real
;
    mov bx,dx
    shl bx,3
    mov cx,[bx+4]
    or cx,cx
    jz out_byte_real
;
    push ds
    call fword ptr [bx]
    pop ds
    jmp out_byte_done

out_byte_real:
    out dx,al

out_byte_done:
    pop si
    pop cx
    pop bx
    ret
OutByte Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OutWord
;
;           description:    write a word to I/O port
;
;           PARAMETERS:         SS:ebp       CPU
;                           DX              IO PORT
;                           AX              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public OutWord

OutWord Proc near
    push cx
    push dx
    push si
;
    mov bx,hook_out_sel
    mov ds,bx
    cmp dx,400h
    jnc out_word_real
;
    mov bx,dx
    shl bx,3
    mov cx,[bx+4]
    or cx,[bx+12]
    jz out_word_real
;
    mov cx,[bx+4]
    or cx,cx
    jz out_word_real1
;
    push ds
    push ax
    push bx
    call fword ptr [bx]
    pop bx
    pop ax
    pop ds
    jmp out_word_done1

out_word_real1:
    out dx,al

out_word_done1:
    mov al,ah
    add bx,8
    inc dx
    mov cx,[bx+4]
    or cx,cx
    jz out_word_real2
;
    push ds
    call fword ptr [bx]
    pop ds
    jmp out_word_done

out_word_real2:
    out dx,al
    jmp out_word_done

out_word_real:
    out dx,ax

out_word_done:
    pop si
    pop dx
    pop cx
    ret
OutWord Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OutDword
;
;           description:    write a dword to I/O port
;
;           PARAMETERS:         SS:ebp       CPU
;                           DX              IO PORT
;                           EAX             DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public OutDword

OutDword Proc near
    push cx
    push dx
    push si
;
    mov bx,hook_out_sel
    mov ds,bx
    cmp dx,400h
    jnc out_dword_real
;
    mov bx,dx
    shl bx,3
    mov cx,[bx+4]
    or cx,[bx+12]
    or cx,[bx+20]
    or cx,[bx+28]
    jz out_dword_real
;
    mov cx,[bx+4]
    or cx,cx
    jz out_dword_real1
;
    push ds
    push eax
    push bx
    call fword ptr [bx]
    pop bx
    pop eax
    pop ds
    jmp out_dword_done1

out_dword_real1:
    out dx,al

out_dword_done1:
    shr eax,8
    add bx,8
    inc dx
    mov cx,[bx+4]
    or cx,cx
    jz out_dword_real2
;
    push ds
    push eax
    push bx
    call fword ptr [bx]
    pop bx
    pop eax
    pop ds
    jmp out_dword_done2

out_dword_real2:
    out dx,al

out_dword_done2:
    shr eax,8
    add bx,8
    inc dx
    mov cx,[bx+4]
    or cx,cx
    jz out_dword_real3
;
    push ds
    push ax
    push bx
    call fword ptr [bx]
    pop bx
    pop ax
    pop ds
    jmp out_dword_done3

out_dword_real3:
    out dx,al

out_dword_done3:
    mov al,ah
    add bx,8
    inc dx
    mov cx,[bx+4]
    or cx,cx
    jz out_dword_real4
;
    push ds
    call fword ptr [bx]
    pop ds
    jmp out_dword_done

out_dword_real4:
    out dx,al
    jmp out_dword_done

out_dword_real:
    out dx,eax

out_dword_done:
    pop si
    pop dx
    pop cx
    ret
OutDword    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EMULATE_FIRST_PAGE
;
;           DESCRIPTION:    EMULATE CONTENTS OF FIRST PAGE OF LINEAR ADDRESS SPACE
;
;           PARAMETERS:         EBX         LINEAR ADDRESS
;                           AL          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

emulate_first_page      PROC far
    jc write_first_page

read_first_page:
    cmp bx,400h
    jc read_int_vect_do
    cmp bx,500h
    jc read_bios_data_do
;
    mov ax,flat_sel
    mov ds,ax
    movzx ebx,bx
    mov al,[ebx].page0_linear
    jmp emulate_first_page_done

read_int_vect_do:
    mov cx,bx
    mov ax,bx
    shr ax,2
    GetVMInt
    and cx,3
    test cx,2
    jz read_int_offset

read_int_seg:
    mov ax,dx
    jmp read_int_vect_shift

read_int_offset:
    mov ax,bx
read_int_vect_shift:
    and cx,1
    shl cx,3
    shr ax,cl
    jmp emulate_first_page_done

read_bios_data_do:
    sub bx,400h
    GetBiosData
    jmp emulate_first_page_done

write_first_page:
    cmp bx,400h
    jc write_int_vect_do
    cmp bx,500h
    jc write_bios_data_do
    mov cx,flat_sel
    mov ds,cx
    movzx ebx,bx
    mov [ebx].page0_linear,al
    jmp emulate_first_page_done

write_int_vect_do:
    push ax
    mov cx,bx
    mov ax,bx
    shr ax,2
    GetVMInt
    pop ax
    push cx
    and cx,3
    test cx,2
    jz write_int_offset
write_int_seg:
    test cx,1
    jz write_int_seg_low
write_int_seg_high:
    mov dh,al
    jmp write_int_vect_save
write_int_seg_low:
    mov dl,al
    jmp write_int_vect_save
write_int_offset:
    test cx,1
    jz write_int_offset_low
write_int_offset_high:
    mov bh,al
    jmp write_int_vect_save
write_int_offset_low:
    mov bl,al
write_int_vect_save:
    pop cx
    mov ax,cx
    shr ax,2
    SetVMInt
    jmp emulate_first_page_done

write_bios_data_do:
    sub bx,400h
    SetBiosData

emulate_first_page_done:
    ret
emulate_first_page      ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EMULATE_SECOND_PAGE
;
;           DESCRIPTION:    EMULATE CONTENTS OF SECOND PAGE OF LINEAR ADDRESS SPACE
;
;           PARAMETERS:         EBX         LINEAR ADDRESS
;                           AL          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

emulate_second_page     PROC far
    jc write_second_page

read_second_page:
    mov cx,flat_sel
    mov ds,cx
    add ebx,00F00000h
    mov al,[ebx]
    ret

write_second_page:
    mov cx,flat_sel
    mov ds,cx
    add ebx,00F00000h
    mov [ebx],al
    ret
emulate_second_page     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_common
;
;           DESCRIPTION:    Init common module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_common

init_common     Proc near
    mov ax,cs
    mov es,ax
;
    mov di,OFFSET emulate_first_page
    mov eax,1000h
    xor edx,edx
    SetPageEmulate
;
    mov di,OFFSET emulate_second_page
    mov eax,20000h
    mov edx,80000h
;       SetPageEmulate
;
    mov edx,page0_linear
    mov eax,3
    xor ebx,ebx
    SetSysPageEntry
    ret
init_common     Endp

code    ENDS

    END
