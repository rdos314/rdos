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
; Common emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include kdebug.inc
include empage.inc
include emseg.inc
include emtss.inc

.386p
.387

code    SEGMENT byte use32 public 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadByte
;
;               DESCRIPTION:    Read one byte of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;
;               RETURNS:        AL              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReadByte

ReadByte        Proc near
    push ebx
    push ecx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_READ
    jz AccessFault
;
    mov ecx,ebx
    sub ecx,ds:[ebp+esi].d_limit
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call ReadLinearByte
;
    pop edi
    pop ecx
    pop ebx
    ret
ReadByte        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadWord
;
;               DESCRIPTION:    Read one word of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;
;               RETURNS:        AX              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadWord

ReadWord        Proc near
    push ebx
    push ecx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_READ
    jz AccessFault
;
    mov ecx,ebx
    inc ecx
    sub ecx,ds:[ebp+esi].d_limit
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call ReadLinearWord
;
    pop edi
    pop ecx
    pop ebx
    ret
ReadWord        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadDword
;
;               DESCRIPTION:    Read one dword of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;
;               RETURNS:        EAX             DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadDword

ReadDword       Proc near
    push ebx
    push ecx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_READ
    jz AccessFault
;
    mov ecx,ebx
    add ecx,3
    sub ecx,ds:[ebp+esi].d_limit
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call ReadLinearDword
;
    pop edi
    pop ecx
    pop ebx
    ret
ReadDword       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadFword
;
;               DESCRIPTION:    Read one 48-bit word of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;
;               RETURNS:        DX:EAX          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadFword

ReadFword       Proc near
    push ebx
    push ecx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_READ
    jz AccessFault
;
    mov ecx,ebx
    add ecx,5
    sub ecx,ds:[ebp+esi].d_limit
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call ReadLinearFword
;
    pop edi
    pop ecx
    pop ebx
    ret
ReadFword       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadQword
;
;               DESCRIPTION:    Read 4 word of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;
;               RETURNS:        EDX:EAX         DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadQword

ReadQword       Proc near
    push ebx
    push ecx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_READ
    jz AccessFault
;
    mov ecx,ebx
    add ecx,5
    sub ecx,ds:[ebp+esi].d_limit
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call ReadLinearQword
;
    pop edi
    pop ecx
    pop ebx
    ret
ReadQword       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadTbyte
;
;               DESCRIPTION:    Read one tbyte of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;
;               RETURNS:        CX:EDX:EAX              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadTbyte

ReadTbyte       Proc near
    push ebx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_READ
    jz AccessFault
;
    mov ecx,ebx
    add ecx,9
    sub ecx,ds:[ebp+esi].d_limit
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call ReadLinearTByte
;
    pop edi
    pop ebx
    ret
ReadTbyte       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteByte
;
;               DESCRIPTION:    Write one byte of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;                               AL              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteByte

WriteByte       Proc near
    push ebx
    push ecx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_WRITE
    jz AccessFault
;
    mov ecx,ebx
    sub ecx,ds:[ebp+esi].d_limit
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call WriteLinearByte
;
    pop edi
    pop ecx
    pop ebx
    ret
WriteByte       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteWord
;
;               DESCRIPTION:    Write one word of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;                               AX              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteWord

WriteWord       Proc near
    push ebx
    push ecx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_WRITE
    jz AccessFault
;
    mov ecx,ebx
    inc ecx
    sub ecx,ds:[ebp+esi].d_limit
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call WriteLinearWord
;
    pop edi
    pop ecx
    pop ebx
    ret
WriteWord       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteDword
;
;               DESCRIPTION:    Write one dword of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;                               EAX             DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteDword

WriteDword      Proc near
    push ebx
    push ecx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_WRITE
    jz AccessFault
;
    mov ecx,ebx
    add ecx,3
    sub ecx,ds:[ebp+esi].d_limit
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call WriteLinearDword
;
    pop edi
    pop ecx
    pop ebx
    ret
WriteDword      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteFword
;
;               DESCRIPTION:    Write one fword of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;                               DX:EAX          DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteFword

WriteFword      Proc near
    push ebx
    push ecx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_WRITE
    jz AccessFault
;
    mov ecx,ebx
    add ecx,5
    sub ecx,ds:[ebp+esi].d_limit
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call WriteLinearFword
;
    pop edi
    pop ecx
    pop ebx
    ret
WriteFword      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteQword
;
;               DESCRIPTION:    Write one qword of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;                               EDX:EAX         DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteQword

WriteQword      Proc near
    push ebx
    push ecx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_WRITE
    jz AccessFault
;
    mov ecx,ebx
    add ecx,7
    sub ecx,ds:[ebp+esi].d_limit
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call WriteLinearQword
;
    pop edi
    pop ecx
    pop ebx
    ret
WriteQword      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           WriteTbyte
;
;               DESCRIPTION:    Write one tbyte of data
;
;               PARAMETERS:     DS:EBP  CPU
;                               DS:ESI  DESCRIPTOR
;                               EBX             OFFSET
;                               CX:EDX:EAX              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteTbyte

WriteTbyte      Proc near
    push ebx
    push edi
;
    test ds:[ebp+esi].d_access,ACCESS_WRITE
    jz AccessFault
;
    push ecx
    mov ecx,ebx
    add ecx,9
    sub ecx,ds:[ebp+esi].d_limit
    pop ecx
    ja AccessFault
;
    add ebx,ds:[ebp+esi].d_base
    xor edi,edi
    call WriteLinearTbyte
;
    pop edi
    pop ebx
    ret
WriteTbyte      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PushWord
;
;               DESCRIPTION:    Push word onto stack
;
;               PARAMETERS:     DS:EBP  CPU
;                               AX              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PushWord

PushWord        Proc near
    push esi
    push ebx
;
    mov esi,OFFSET reg_ss
    test word ptr ds:[ebp+esi].d_access,ACCESS_32
    jz push_word16

push_word32:
    mov ebx,ds:[ebp].reg_esp
    sub ebx,2
    push ebx
    call WriteWord
    pop ebx
    mov ds:[ebp].reg_esp,ebx
    jmp push_word_done

push_word16:
    movzx ebx,word ptr ds:[ebp].reg_esp
    sub bx,2
    push bx
    call WriteWord
    pop bx
    mov word ptr ds:[ebp].reg_esp,bx

push_word_done:
    pop ebx
    pop esi
    ret
PushWord        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PushDword
;
;               DESCRIPTION:    Push dword onto stack
;
;               PARAMETERS:     DS:EBP  CPU
;                               EAX             DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PushDword

PushDword       Proc near
    push esi
    push ebx
;
    mov esi,OFFSET reg_ss
    test word ptr ds:[ebp+esi].d_access,ACCESS_32
    jz push_dword16

push_dword32:
    mov ebx,ds:[ebp].reg_esp
    sub ebx,4
    push ebx
    call WriteDword
    pop ebx
    mov ds:[ebp].reg_esp,ebx
    jmp push_dword_done

push_dword16:
    movzx ebx,word ptr ds:[ebp].reg_esp
    sub bx,4
    push bx
    call WriteDword
    pop bx
    mov word ptr ds:[ebp].reg_esp,bx

push_dword_done:
    pop ebx
    pop esi
    ret
PushDword       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PushLong
;
;               DESCRIPTION:    Push dword onto stack
;
;               PARAMETERS:     DS:EBP       CPU
;                               EDX:EAX      DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PushLong

PushLong       Proc near
    push ebx
    push edi
;
    mov ebx,ds:[ebp].reg_esp
    mov edi,ds:[ebp].reg_esp+4
    sub ebx,8
    sbb edi,0
    call WriteLinearQword
    mov ds:[ebp].reg_esp,ebx
    mov ds:[ebp].reg_esp+4,edi
;
    pop edi
    pop ebx
    ret
PushLong       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PopWord
;
;               DESCRIPTION:    pop word from stack
;
;               RETURNS:        AX              data popped
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PopWord

PopWord Proc near
    push esi
    push ebx
;
    mov esi,OFFSET reg_ss
    test word ptr ds:[ebp+esi].d_access,ACCESS_32
    jz pop_word16

pop_word32:
    mov ebx,ds:[ebp].reg_esp
    push ebx
    call ReadWord
    pop ebx
    add ebx,2
    mov ds:[ebp].reg_esp,ebx
    jmp pop_word_done

pop_word16:
    movzx ebx,word ptr ds:[ebp].reg_esp
    push ebx
    call ReadWord
    pop ebx
    add bx,2
    mov word ptr ds:[ebp].reg_esp,bx

pop_word_done:
    pop ebx
    pop esi
    ret
PopWord Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PopDword
;
;               DESCRIPTION:    pop dword from stack
;
;               RETURNS:        EAX             data popped
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PopDword

PopDword        Proc near
    push esi
    push ebx
;
    mov esi,OFFSET reg_ss
    test word ptr ds:[ebp+esi].d_access,ACCESS_32
    jz pop_dword16

pop_dword32:
    mov ebx,ds:[ebp].reg_esp
    push ebx
    call ReadDword
    pop ebx
    add ebx,4
    mov ds:[ebp].reg_esp,ebx
    jmp pop_dword_done

pop_dword16:
    movzx ebx,word ptr ds:[ebp].reg_esp
    push ebx
    call ReadDword
    pop ebx
    add bx,4
    mov word ptr ds:[ebp].reg_esp,bx

pop_dword_done:
    pop ebx
    pop esi
    ret
PopDword        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           PopLong
;
;               DESCRIPTION:    Pop qword from stack
;
;               PARAMETERS:     DS:EBP       CPU
;
;               RETURNS:        EDX:EAX      DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PopLong

PopLong       Proc near
    push ebx
    push edi
;
    mov ebx,ds:[ebp].reg_esp
    mov edi,ds:[ebp].reg_esp+4
    call ReadLinearQword
;        
    add ebx,8
    adc edi,0
    mov ds:[ebp].reg_esp,ebx
    mov ds:[ebp].reg_esp+4,edi
;
    pop edi
    pop ebx
    ret
PopLong       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           AddToStack
;
;               DESCRIPTION:    add value to stack pointer
;
;               RETURNS:        EAX             value to add to (e)sp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   public AddToStack

AddToStack      Proc near
    test word ptr ds:[ebp].reg_ss.d_access,ACCESS_32
    jz AddToStack16

AddToStack32:
    add ds:[ebp].reg_esp,eax
    ret

AddToStack16:
    add word ptr ds:[ebp].reg_esp,ax
    ret
AddToStack      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SubFromStack
;
;               DESCRIPTION:    sub value from stack pointer
;
;               RETURNS:        EAX             value to sub from (e)sp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SubFromStack

SubFromStack    Proc near
   test word ptr ds:[ebp].reg_ss.d_access,ACCESS_32
   jz SubFromStack16

SubFromStack32:
    sub ds:[ebp].reg_esp,eax
    ret

SubFromStack16:
    sub word ptr ds:[ebp].reg_esp,ax
    ret
SubFromStack    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadCodeByte
;
;               DESCRIPTION:    Read byte from cs:eip, update to next position
;
;               RETURNS:        AL              data read
;
;               USES:           All registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadCodeByte

ReadCodeByte    Proc near
    mov esi,OFFSET reg_cs
    test ds:[ebp+esi].d_access,ACCESS_READ
    jz AccessFault
;
    test word ptr ds:[ebp+esi].d_access,ACCESS_32
    jz read_code_byte16

read_code_byte32:
    mov ebx,ds:[ebp].reg_eip
    inc ds:[ebp].reg_eip
    call ReadByte
    ret

read_code_byte16:
    movzx ebx,word ptr ds:[ebp].reg_eip
    inc word ptr ds:[ebp].reg_eip
    call ReadByte
    ret
ReadCodeByte    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadCodeWord
;
;               DESCRIPTION:    Read word from cs:eip, update to next position
;
;               RETURNS:        AX              data read
;
;               USES:           All registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadCodeWord

ReadCodeWord    Proc near
    mov esi,OFFSET reg_cs
    test ds:[ebp+esi].d_access,ACCESS_READ
    jz AccessFault
;
    test word ptr ds:[ebp+esi].d_access,ACCESS_32
    jz read_code_word16

read_code_word32:
    mov ebx,ds:[ebp].reg_eip
    add ds:[ebp].reg_eip,2
    call ReadWord
    ret

read_code_word16:
    movzx ebx,word ptr ds:[ebp].reg_eip
    add word ptr ds:[ebp].reg_eip,2
    call ReadWord
    ret
ReadCodeWord    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadCodeDword
;
;               DESCRIPTION:    Read dword from cs:eip, update to next position
;
;               RETURNS:        EAX             data read
;
;               USES:           All registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadCodeDword

ReadCodeDword   Proc near
    mov esi,OFFSET reg_cs
    test ds:[ebp+esi].d_access,ACCESS_READ
    jz AccessFault
;        
    test word ptr ds:[ebp+esi].d_access,ACCESS_32
    jz read_code_dword16

read_code_dword32:
    mov ebx,ds:[ebp].reg_eip
    add ds:[ebp].reg_eip,4
    call ReadDword
    ret

read_code_dword16:
    movzx ebx,word ptr ds:[ebp].reg_eip
    add word ptr ds:[ebp].reg_eip,4
    call ReadDword
    ret
ReadCodeDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadCodeFword
;
;               DESCRIPTION:    Read fword from cs:eip, update to next position
;
;               RETURNS:        DX:EAX          data read
;
;               USES:           All registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadCodeFword

ReadCodeFword   Proc near
    mov esi,OFFSET reg_cs
    test ds:[ebp+esi].d_access,ACCESS_READ
    jz AccessFault
;        
    test word ptr ds:[ebp+esi].d_access,ACCESS_32
    jz read_code_fword16

read_code_fword32:
    mov ebx,ds:[ebp].reg_eip
    add ds:[ebp].reg_eip,6
    call ReadFword
    ret

read_code_fword16:
    movzx ebx,word ptr ds:[ebp].reg_eip
    add word ptr ds:[ebp].reg_eip,6
    call ReadFword
    ret
ReadCodeFword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadLongCodeByte
;
;               DESCRIPTION:    Read byte from rip, update to next position
;
;               RETURNS:        AL              data read
;
;               USES:           All registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadLongCodeByte

ReadLongCodeByte    Proc near
    mov ebx,ds:[ebp].reg_eip
    mov edi,ds:[ebp].reg_eip+4
    call ReadLinearByte
    ret
ReadLongCodeByte    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadLongCodeWord
;
;               DESCRIPTION:    Read word from rip, update to next position
;
;               RETURNS:        AX              data read
;
;               USES:           All registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadLongCodeWord

ReadLongCodeWord    Proc near
    mov ebx,ds:[ebp].reg_eip
    mov edi,ds:[ebp].reg_eip+4
    call ReadLinearWord
    ret
ReadLongCodeWord    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadLongCodeDword
;
;               DESCRIPTION:    Read dword from rip, update to next position
;
;               RETURNS:        EAX             data read
;
;               USES:           All registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     public ReadLongCodeDword

ReadLongCodeDword    Proc near
    mov ebx,ds:[ebp].reg_eip
    mov edi,ds:[ebp].reg_eip+4
    call ReadLinearDword
    ret
ReadLongCodeDword    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           ReadLongCodeQword
;
;               DESCRIPTION:    Read qword from rip, update to next position
;
;               RETURNS:        EDX:EAX             data read
;
;               USES:           All registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadLongCodeQword

ReadLongCodeQword    Proc near
    mov ebx,ds:[ebp].reg_eip
    mov edi,ds:[ebp].reg_eip+4
    call ReadLinearQword
    ret
ReadLongCodeQword    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           InPort
;
;               description:    read from I/O port
;
;               PARAMETERS:     DS:EBP          CPU
;                               DX              IO PORT
;                               DS:ESI          BUFFER
;                               ECX             SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InPort

InPort Proc near
    cmp ecx,1
    je ipByte
;
    cmp ecx,2
    je ipWord

ipDword:
    in eax,dx
    mov [esi],eax
    ret

ipByte:
    in al,dx
    mov [esi],al
    ret

ipWord:
    in ax,dx
    mov [esi],ax
    ret
InPort  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           OutPort
;
;               description:    write to I/O port
;
;               PARAMETERS:     DS:EBP          CPU
;                               DX              IO PORT
;                               DS:ESI          BUFFER
;                               ECX             SIZE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public OutPort

OutPort Proc near
    cmp ecx,1
    je opByte
;
    cmp ecx,2
    je opWord

opDword:
    mov eax,[esi]
    out dx,eax
    ret

opByte:        
    mov al,[esi]
    out dx,al
    ret

opWord:
    mov ax,[esi]
    out dx,ax
    ret
OutPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           Inbyte
;
;               description:    read a byte from I/O port
;
;               PARAMETERS:     DS:EBP          CPU
;                               DX              IO PORT
;
;               RETURNS:        AL                      DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InByte

InByte Proc near
    push ecx
    push esi
;
    test ds:[ebp].reg_cr0,CR0_PE
    jz InByteDo
;
    test byte ptr ds:[ebp].reg_eflags+2,2
    jnz InByteVm
;
    mov ecx,ds:[ebp].reg_eflags
    ror cx,4
    mov ch,byte ptr ds:[ebp].reg_cs.d_selector
    and cx,303h
    cmp cl,ch
    jnc InByteDo
;
    mov ecx,1
    call CheckBitmap
    jmp InByteDo

InByteVm:
    mov ecx,1
    call CheckBitmap

InByteDo:
    in al,dx
;
    pop esi
    pop ecx
    ret
InByte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           InWord
;
;               description:    read a word from I/O port
;
;               PARAMETERS:     DS:EBP          CPU
;                               DX              IO PORT
;
;               RETURNS:        AX              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InWord

InWord Proc near
    push ecx
    push esi
;
    test ds:[ebp].reg_cr0,CR0_PE
    jz InWordDo
;
    test byte ptr ds:[ebp].reg_eflags+2,2
    jnz InWordVm
;
    mov ecx,ds:[ebp].reg_eflags
    ror cx,4
    mov ch,byte ptr ds:[ebp].reg_cs.d_selector
    and cx,303h
    cmp cl,ch
    jnc InWordDo
;
    mov ecx,2
    call CheckBitmap
    jmp InWordDo

InWordVm:
    mov ecx,2
    call CheckBitmap

InWordDo:
    in ax,dx
;
    pop esi
    pop ecx
    ret
InWord  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           InDword
;
;               description:    read a dword from I/O port
;
;               PARAMETERS:     DS:EBP          CPU
;                               DX              IO PORT
;
;               RETURNS:        EAX             DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InDword

InDword Proc near
    push ecx
    push esi
;
    test ds:[ebp].reg_cr0,CR0_PE
    jz InDwordDo
;
    test byte ptr ds:[ebp].reg_eflags+2,2
    jnz InDwordVm
;
    mov ecx,ds:[ebp].reg_eflags
    ror cx,4
    mov ch,byte ptr ds:[ebp].reg_cs.d_selector
    and cx,303h
    cmp cl,ch
    jnc InDwordDo
;
    mov ecx,4
    call CheckBitmap
    jmp InDwordDo

InDwordVm:
    mov ecx,4
    call CheckBitmap

InDwordDo:
    in eax,dx
;
    pop esi
    pop ecx
    ret
InDword Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           OutByte
;
;               description:    write a byte to I/O port
;
;               PARAMETERS:     DS:EBP          CPU
;                               DX              IO PORT
;                               AL              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public OutByte

OutByte Proc near
    push ecx
    push esi
;
    test ds:[ebp].reg_cr0,CR0_PE
    jz OutByteDo
;
    test byte ptr ds:[ebp].reg_eflags+2,2
    jnz OutByteVm
;
    mov ecx,ds:[ebp].reg_eflags
    ror cx,4
    mov ch,byte ptr ds:[ebp].reg_cs.d_selector
    and cx,303h
    cmp cl,ch
    jnc OutByteDo
;
    mov ecx,1
    call CheckBitmap
    jmp OutByteDo

OutByteVm:
    mov ecx,1
    call CheckBitmap

OutByteDo:
    out dx,al
;
    pop esi
    pop ecx
    ret
OutByte Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           OutWord
;
;               description:    write a word to I/O port
;
;               PARAMETERS:     DS:EBP          CPU
;                               DX              IO PORT
;                               AX              DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public OutWord

OutWord Proc near
    push ecx
    push esi
;
    test ds:[ebp].reg_cr0,CR0_PE
    jz OutWordDo
;
    test byte ptr ds:[ebp].reg_eflags+2,2
    jnz OutWordVm
;
    mov ecx,ds:[ebp].reg_eflags
    ror cx,4
    mov ch,byte ptr ds:[ebp].reg_cs.d_selector
    and cx,303h
    cmp cl,ch
    jnc OutWordDo
;
    mov ecx,2
    call CheckBitmap
    jmp OutWordDo

OutWordVm:
    mov ecx,2
    call CheckBitmap

OutWordDo:
    out dx,ax
;
    pop esi
    pop ecx
    ret
OutWord Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           OutDword
;
;               description:    write a dword to I/O port
;
;               PARAMETERS:     DS:EBP          CPU
;                               DX              IO PORT
;                               EAX             DATA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public OutDword

OutDword Proc near
    push ecx
    push esi
;
    test ds:[ebp].reg_cr0,CR0_PE
    jz OutDwordDo
;
    test byte ptr ds:[ebp].reg_eflags+2,2
    jnz OutDwordVm
;
    mov ecx,ds:[ebp].reg_eflags
    ror cx,4
    mov ch,byte ptr ds:[ebp].reg_cs.d_selector
    and cx,303h
    cmp cl,ch
    jnc OutDwordDo
;
    mov ecx,4
    call CheckBitmap
    jmp OutDwordDo

OutDwordVm:
    mov ecx,4
    call CheckBitmap

OutDwordDo:
    out dx,eax
;
    pop esi
    pop ecx
    ret
OutDword        Endp

code    Ends

        END
