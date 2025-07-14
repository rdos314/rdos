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
; DEBCOM.ASM
; Common parts in debugger
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\system.def
INCLUDE kdebug.inc

.386p
.387

code    SEGMENT byte use32 public 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddNewLine
;
;           DESCRIPTION:    ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddNewLine
    
AddNewLine Proc near
    push eax
;    
    mov al,13
    stosb
;    
    mov al,10
    stosb
;
    pop eax
    ret
AddNewLine Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddBlank
;
;           DESCRIPTION:    Add blanks
;
;           PARAMETERS:     ES:EDI       Buffer
;                           ECX          Number of blanks to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddBlanks
    
AddBlanks   Proc near
    push eax
    push ecx
;
    mov al,' '
    rep stosb
;
    pop ecx
    pop eax
    ret
AddBlanks   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddDelimiter
;
;           DESCRIPTION:    Add delimiter
;  
;           PARAMETERS:     ES:EDI       Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddDelimiter
    
AddDelimiter       Proc near
    push eax
    push ecx
;    
    mov ecx,60
    mov al,'-'
    rep stosb
;
    mov ecx,19
    call AddBlanks
;
    call AddNewLine    
; 
    pop ecx   
    pop eax
    ret
AddDelimiter       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ToHex
;
;           DESCRIPTION:    
;
;           PARAMETERS:     AL          Number
;
;           RETURNS:        AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ToHex      PROC near

hex_conv_low:
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
;
    add al,7

ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
;    
    add ah,7

ok_high1:
    add ah,30h
    ret
ToHex      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexByte
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI       Buffer
;                           AL          Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddHexByte
    
AddHexByte    PROC near
    push eax
;    
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb add_byte_low1
;    
    add al,7

add_byte_low1:
    add al,'0'
    stosb
;
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb add_byte_high1
;
    add al,7

add_byte_high1:
    add al,'0'
    stosb
;
    pop eax
    ret
AddHexByte    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexWord
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI       Buffer
;                           AX           Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddHexWord
    
AddHexWord    PROC near
    xchg al,ah
    call AddHexByte
    xchg al,ah
    call AddHexByte
    ret
AddHexWord    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexDword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           EAX         Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddHexDword
    
AddHexDword   PROC near
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    ret
AddHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexQword
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           EDX:EAX     Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddHexQword

AddHexQword   PROC near
    push eax
;    
    push eax
    mov eax,edx
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
;
    mov al,'_'
    stosb
;
    pop eax
;    
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
    rol eax,8
    call AddHexByte
;
    pop eax    
    ret
AddHexQword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexPtr16
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           DX          Segment
;                           BX          Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddHexPtr16

AddHexPtr16   PROC near
    push ax
    mov ax,dx
    call AddHexWord
;    
    mov al,':'
    stosb
;
    mov ax,bx
    call AddHexWord
    pop ax
    ret
AddHexPtr16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexPtr32
;
;           DESCRIPTION:    
;
;           PARAMETERS:     ES:EDI      Buffer
;                           DX          Segment
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddHexPtr32

AddHexPtr32   PROC near
    push eax
    mov ax,dx
    call AddHexWord
;    
    mov al,':'
    stosb
;
    mov eax,ebx
    call AddHexDword
    pop eax
    ret
AddHexPtr32   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddHexPtr64
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DX          High offset
;                           EBX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddHexPtr64

AddHexPtr64   PROC near
    push eax
;    
    mov ax,dx
    call AddHexWord
;
    mov al,'_'
    stosb
;    
    mov eax,ebx
    call AddHexDword
;
    pop eax
    ret
AddHexPtr64   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddCodeAsciiz
;
;           DESCRIPTION:    Add asciiz string from code
;
;           PARAMETERS:     ES:EDI      Buffer
;                           CS:ESI      String to add
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddCodeAsciiz

AddCodeAsciiz   PROC near
    push ax

acaLoop:
    lods cs:[esi]
    or al,al
    jz acaDone
;
    stosb
    jmp acaLoop    

acaDone:
    pop ax
    ret
AddCodeAsciiz   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddPhysDataRow
;
;           DESCRIPTION:    
;
;           PARAMETERS:     EDX:ESI     Physical address
;                           DS:EBP      Cpu
;                           ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddPhysDataRow

AddPhysDataRow    PROC near
    mov ebx,esi
    call AddHexPtr64
;    
    mov ecx,16
    push esi

aphdhLoop:
    mov al,' '
    stosb
;
    call ds:[ebp].cpu_read_phys    
    jc aphdhInv
;
    call AddHexByte
    jmp aphdhNext

aphdhInv:
    stosb
    stosb

aphdhNext:
    inc esi
    loop aphdhLoop
;
    pop esi
    mov al,' '
    stosb
;
    mov ecx,16

aphdaLoop:
    mov al,'!'
    call ds:[ebp].cpu_read_phys    
    cmp al,20h
    jnc aphdaDo
;    
    mov al,' '

aphdaDo:
    stosb
    inc esi
    loop aphdaLoop
    
aphdEnd:
    ret
AddPhysDataRow    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddProtDataRow
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DX:ESI      Sel:offset
;                           DS:EBP      Cpu
;                           ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddProtDataRow

AddProtDataRow    PROC near
    mov ebx,esi
    call AddHexPtr32
;    
    mov ecx,16
    push esi

apdhLoop:
    mov al,' '
    stosb
;
    call ds:[ebp].cpu_read_mem    
    jc apdhInv
;
    call AddHexByte
    jmp apdhNext

apdhInv:
    stosb
    stosb

apdhNext:
    inc esi
    loop apdhLoop
;
    pop esi
    mov al,' '
    stosb
;
    mov ecx,16

apdaLoop:
    call ds:[ebp].cpu_read_mem    
    cmp al,20h
    jnc apdaDo
;    
    mov al,' '

apdaDo:
    stosb
    inc esi
    loop apdaLoop
    
apdEnd:
    ret
AddProtDataRow    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddLongDataRow
;
;           DESCRIPTION:    
;
;           PARAMETERS:     DX:ESI      Offset
;                           DS:EBP      Cpu
;                           ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddLongDataRow
    
AddLongDataRow    PROC near
    mov ebx,esi
    call AddHexPtr64
;
    mov ecx,16
    push esi

aldhLoop:
    mov al,' '
    stosb
;    
    call ds:[ebp].cpu_read_mem    
    jc aldhInv
;
    call AddHexByte
    jmp aldhNext

aldhInv:
    stosb
    stosb

aldhNext:
    inc esi
    loop aldhLoop
;
    pop esi
;
    mov al,' '
    stosb
;    
    mov ecx,16
    
aldaLoop:
    call ds:[ebp].cpu_read_mem    
    cmp al,20h
    jnc aldaDo
;
    mov al,' '

aldaDo:
    stosb
    inc esi
    loop aldaLoop

aldaEnd:
    ret
AddLongDataRow    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddFreeMem
;
;           DESCRIPTION:    Add free memory
;
;           PARAMETERS:     GS          Thread
;                           ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

phys_mem_comment        DB 'Physical ',0
global_mem_comment      DB '   Global ',0
local_mem_comment       DB '   Local ',0

    public AddFreeMem

AddFreeMem    PROC near
    mov esi,OFFSET phys_mem_comment
    call AddCodeAsciiz
;    
    GetFreePhysical
    call AddHexQword
;
    mov al,gs:p_realtime
    or al,al
    jnz afmDone
;
    mov esi,OFFSET global_mem_comment
    call AddCodeAsciiz
;    
    UsedBigLinear
    push edx
    push eax
    UsedSmallLinear
    pop edx
    add eax,edx
    pop edx
    call AddHexDword
;
    mov esi,OFFSET local_mem_comment
    call AddCodeAsciiz
;    
    mov bx,gs
    UsedLocalLinearThread
    call AddHexDword

afmDone:    
    call AddNewLine
    ret
AddFreeMem    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:                   FLOAT_POWER10
;
;       DESCRIPTION:    
;
;       PARAMETERS:             AX              Exponent
;
;       RETURNS:                ST(0)           10**AX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dt0  DT 1.0e+1
dt1  DT 1.0e+2
dt2  DT 1.0e+4
dt3  DT 1.0e+8
dt4  DT 1.0e+16
dt5  DT 1.0e+32
dt6  DT 1.0e+64
dt7  DT 1.0e+128
dt8  DT 1.0e+256
dt9  DT 1.0e+512
dt10 DT 1.0e+1024
dt11 DT 1.0e+2048
dt12 DT 1.0e+4096

float_power10   PROC near
    push ax
    push ebx
    test ax,8000h
    pushf
    jz float_scale_pos
;
    neg ax

float_scale_pos:
    mov ebx,OFFSET dt0
    sub ebx,10
    fld1
    
float_scale_next:
    add ebx,10
    or ax,ax
    jz float_scale_end
;
    clc
    rcr ax,1
    jnc float_scale_next
;    
    fld tbyte ptr cs:[ebx]
    fmulp st(1),st
    jmp float_scale_next

float_scale_end:
    popf
    jz float_scale_no_inv
;    
    fld1
    fdivrp st(1),st

float_scale_no_inv:
    pop ebx
    pop ax
    ret
float_power10   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FLOAT_SPLIT
;
;       DESCRIPTION:    SPLIT NUMBER INTO 10-EXPONENT AND MANTISSA
;
;       PARAMETERS:     ST(0)           NUMBER IN, MANTISSA OUT
;                       DL              NUMBER OF DECIMALS
;
;       RETURNS:        ST(0)           MANTISSA
;                       AX              EXPONENT IN NUMBER
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dt_half DT 0.5

float_split     PROC near
    pushf
    push ecx
    push edx
    push esi
;    
    xor dh,dh
    mov ax,dx
    neg ax
    call float_power10
    fld cs:dt_half
    fmulp st(1),st
    faddp st(1),st
    mov esi,OFFSET dt12
    mov ecx,13
    xor dx,dx
    fld1
    fcomp st(1)
    fstsw ax
    sahf
    jz float_split_end    
    jc float_split_no_invert
;    
    fld1
    fdivrp st(1),st

float_split_no_invert:
    pushf
    
float_split_loop:
    fld tbyte ptr cs:[esi]
    fcomp st(1)
    fstsw ax
    sahf
    jz float_split_lower
    jnc float_split_lower
;    
    fld tbyte ptr cs:[esi]
    fdivp st(1),st
    stc
    jmp float_split_next

float_split_lower:
    clc
    
float_split_next:
    rcl dx,1
    sub esi,10
    loop float_split_loop
;
    popf
    jc float_split_end
;    
    fld1
    fdivrp st(1),st
    neg dx
    
float_split_end:
    mov ax,dx
;    
    pop esi
    pop edx
    pop ecx
    popf
    ret
float_split     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:                   FLOAT_CALC_POS
;
;       DESCRIPTION:    
;
;       PARAMETERS:             AX              EXPONENT
;                               CL              STRING SIZE
;                               DL              NUMBER OF DECIMALS
;
;       RETURNS:                CH              NUMBER OF LEADING BLANKS
;                               DH              POSITION OF DECIMAL  "."
;                               BL              MANTISSA POSITION
;                               NC              OK
;                               CY              CANNOT DISPLAY NUMBER ON FORM
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_calc_pos  PROC near
    push ax
    mov bl,al
    neg bl
    test ax,8000h
    jz float_calc_big
;    
    xor ax,ax
    inc bl
    
float_calc_big:
    or ah,ah
    jnz float_calc_exp
;    
    mov ch,cl
    sub ch,al
    jc float_calc_exp
;    
    sub ch,dl
    jc float_calc_exp
;    
    sub ch,1
    jc float_calc_exp
;
    mov dh,cl
    sub dh,dl
    dec dh
    add bl,dh
    jmp float_calc_end

float_calc_exp:
    stc
    pop ax
    ret
    
float_calc_end:
    or dl,dl
    jnz float_calc_dot
;    
    inc ch
    inc dh
    inc bl

float_calc_dot:
    clc
    pop ax
    ret
float_calc_pos  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:                   FLOAT_INIT_STRING
;
;       DESCRIPTION:    
;
;       PARAMETERS:             ES:EDI  STRING
;                               AX      EXPONENT
;                               CL      STRING SIZE
;                               DL      NUMBER OF DECIMALS
;                               NC      POSITIVE NUMBER
;                               CY      NEGATIVE NUMBER
;
;       RETURN:                 ES:EDX  OFFSET TO "."
;                               ES:EDI  ADDRESS WHERE TO START WRITING MANTISSA
;                               ES:ESI  LAST CHAR IN STRING
;                               NC      OK
;                               CY      FEL, TO BIG NUMBER
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_init_string       PROC near
    push ecx
    push ebx
    push eax
    pushf
    jnc float_istr_calc
;    
    dec cl

float_istr_calc:
    dec cl
    call float_calc_pos
    jnc float_istr_do
    jmp float_istr_error

float_istr_do:
    popf
    pushf
    jnc float_istr_noinc
;
    inc cl
    inc dh
    inc bl
    
float_istr_noinc:
    movzx ebx,bl
    add ebx,edi
    mov esi,ebx
    mov bl,cl
;
    movzx ebx,bl
    add ebx,edi
    xchg ebx,esi
    or ch,ch
    jz float_istr_nodot
;
    push ecx
    movzx ecx,ch
    mov al,' '
    rep stosb   
    pop ecx
    
float_istr_nodot:
    popf
    jnc float_istr_nosign
;    
    mov al,'-'
    stosb

float_istr_nosign:
    movzx ecx,dl
    sub ecx,esi
    neg ecx
    sub ecx,edi
    mov al,'0'
    or ecx,ecx
    jz float_no_lead_zero
;    
    rep stosb

float_no_lead_zero:
    movzx ecx,dl
    or ecx,ecx
    jz float_no_dot
;    
    mov edx,edi
    mov al,'.'
    stosb
    mov al,'0'
    rep stosb

float_no_dot:
    mov edi,ebx
    clc
    jmp float_istr_end

float_istr_error:
    popf
    stc
    
float_istr_end:
    pop eax
    pop ebx
    pop ecx
    ret
float_init_string       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FLOAT_STRING
;
;       DESCRIPTION:    WRITE 10-EXPONENT OCH MANTISSA TO STRING
;
;       PARAMETERS:     ST(0)           MANTISSA 0.1-1.0
;                       AX              EXPONENT
;                       ES:EDI          STRING
;                       CH              LEADING BLANKS
;                       DH              POSITION OF "."
;                       ES:ESI          LAST CHAR IN STRING
;
;       RETURNS:        ES:EDI          Next pos
;                                               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_string    PROC near
    mov ecx,20
    inc esi
    fld1
    
float_string_loop:
    cmp edi,esi
    je float_string_end
;    
    cmp edi,edx
    jne float_string_no_dot
;    
    inc edi
    cmp esi,edi
    je float_string_end

float_string_no_dot:
    mov bl,'0'

float_string_one_loop:
    fcom st(1)
    fstsw ax
    sahf
    jz float_string_next
    jc float_string_one
    jmp float_string_next

float_string_one:
    inc bl
    fsub st(1),st
    jmp float_string_one_loop

float_string_next:
    mov al,'0'
    or ecx,ecx
    jz float_string_save0
;    
    dec ecx
    mov al,bl

float_string_save0:
    stosb
    fld cs:dt0
    fmulp st(2),st
    cmp esi,edi
    jne float_string_loop

float_string_end:
    ret
float_string    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_normal
;
;        DESCRIPTION:           Normal float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

overflow_txt    DB 'TOO BIG NUMBER'

float_normal    PROC near
    pushf
    call float_split
    call float_init_string
    jc float_error_decode
;
    popf
    call float_string
    ret
    
float_error_decode:
    popf
    mov esi,OFFSET overflow_txt
    mov ecx,14
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_normal    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_unsupported
;
;        DESCRIPTION:           Unsupported float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unsupported_txt DB 'UNSUPPORTED'

float_unsuported        PROC near
    mov esi,OFFSET unsupported_txt
    mov ecx,11
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_unsuported        ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_nan
;
;        DESCRIPTION:           NAN float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nan_txt                 DB 'NAN'

float_nan       PROC near
    mov esi,OFFSET nan_txt
    mov ecx,3
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_nan       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_infinity
;
;        DESCRIPTION:           Infinite float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

infinity_txt    DB 'INFINITY'

float_infinity  PROC near
    mov esi,OFFSET infinity_txt
    mov ecx,8
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_infinity  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_zero
;
;        DESCRIPTION:           Zero float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_zero      PROC near
    mov al,'0'
    stosb
    ret
float_zero      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_empty
;
;        DESCRIPTION:           Empty float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

empty_txt               DB 'EMPTY'

float_empty     PROC near
    mov esi,OFFSET empty_txt
    mov ecx,5
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_empty     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 float_denormal
;
;        DESCRIPTION:           Denormal float
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;                               CF              Sign
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

denormal_txt    DB 'DENORMAL'

float_denormal  PROC near
    mov esi,OFFSET denormal_txt
    mov ecx,8
    rep movs byte ptr es:[edi],cs:[esi]
    ret
float_denormal  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;         NAME:                 FloadToString
;
;        DESCRIPTION:   
;
;        PARAMETERS:            ST(0)           NUMBER TO CONVERT
;                               CL              SIZE OF STRING
;                               DL              NUMBER OF DECIMALS
;                               ES:EDI          STRING
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_type_tab:
ftt0 DD OFFSET float_unsuported
ftt1 DD OFFSET float_nan
ftt2 DD OFFSET float_unsuported
ftt3 DD OFFSET float_nan
ftt4 DD OFFSET float_normal
ftt5 DD OFFSET float_infinity
ftt6 DD OFFSET float_normal
ftt7 DD OFFSET float_infinity
ftt8 DD OFFSET float_zero
ftt9 DD OFFSET float_empty
fttA DD OFFSET float_zero
fttB DD OFFSET float_empty
fttC DD OFFSET float_denormal
fttD DD OFFSET float_unsuported
fttE DD OFFSET float_denormal
fttF DD OFFSET float_unsuported

    public FloatToString

FloatToString   PROC near
    fxam
    fstsw ax
    test ah,2
    clc
    jz ftsSignOk
;    
    fchs
    stc

ftsSignOk:
    pushf
    mov bl,ah
    and bl,7
    and ah,40h
    jz ftsC3Zero
;    
    or bl,8

ftsC3Zero:
    movzx ebx,bl
    shl ebx,2
    popf
    call dword ptr cs:[ebx].float_type_tab
;
    finit    
    ret
FloatToString   ENDP
    
code    ENDS

    END
