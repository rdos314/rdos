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
; BIGNUM.ASM
; Big number support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.inc
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc

BN_FLAG_NEGATIVE = 1
BN_FLAG_INFINITE = 2

bignum_handle_seg          STRUC

bn_base         handle_header <>

bn_data         DD ?
bn_count        DD ?
bn_flags        DW ?

bignum_handle_seg          ENDS

mul_struc       STRUC

mul_in_count1    DD ?
mul_in_data1     DD ?
mul_in_count2    DD ?
mul_in_data2     DD ?
mul_out_count    DD ?
mul_out_data     DD ?

mul_struc       ENDS

div_struc       STRUC

div_divisor_count    DD ?
div_quot_count       DD ?
div_temp_count       DD ?
div_divisor_data     DD ?
div_quot_data        DD ?
div_mod_data         DD ?
div_temp_quot_data   DD ?

div_offset           DD ?
div_size             DD ?

div_struc       ENDS

pow_mod_struc       STRUC

pow_mod_div          div_struc <>

pow_mod_base_count   DD ?
pow_mod_base_data    DD ?
pow_mod_exp_count    DD ?
pow_mod_exp_data     DD ?
pow_mod_res_count    DD ?
pow_mod_res_data     DD ?
pow_mod_temp_data    DD ?

pow_mod_bits         DD ?

pow_mod_struc       ENDS

.386p

data    SEGMENT byte public 'DATA'

filler      DB ?

data    ENDS

code    SEGMENT byte public use32 'CODE'
    
    assume cs:code
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RecreateBuf
;
;           DESCRIPTION:    Recreate buffer
;
;           PARAMETERS:     DS:EBX      Handle data
;                           ECX         New entry count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecreateBuf     PROC near
    cmp ecx,ds:[ebx].bn_count
    je rbDone
;
    push eax
    push ecx
    push edx
;    
    mov eax,ds:[ebx].bn_count
    or eax,eax
    jz rbCreate
;
    push ecx
    mov ecx,eax
    shl ecx,2
    mov edx,ds:[ebx].bn_data
    FreeLinear
    pop ecx

rbCreate:
    mov ds:[ebx].bn_count,ecx
;    
    or ecx,ecx
    jz rbCreated
;    
    mov eax,ecx
    shl eax,2
    AllocateSmallLinear
    mov ds:[ebx].bn_data,edx

rbCreated:
    pop edx
    pop ecx
    pop eax

rbDone:    
    ret
RecreateBuf ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyBuf
;
;           DESCRIPTION:    Copy buffer
;
;           PARAMETERS:     DS:EBX      Handle data
;                           EDX         Buffer count
;                           ESI         Data
;                           ECX         Data count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyBuf     PROC near
    push ds
    pushad
;    
    cmp edx,ds:[ebx].bn_count
    je cbCopy
;    
    mov eax,ds:[ebx].bn_count
    or eax,eax
    jz cbCreate
;
    push ecx
    push edx
    mov ecx,eax
    shl ecx,2
    mov edx,ds:[ebx].bn_data
    FreeLinear
    pop edx
    pop ecx

cbCreate:
    mov ds:[ebx].bn_count,edx
;    
    or edx,edx
    jz cbCopy
;    
    push edx
    mov eax,edx
    shl eax,2
    AllocateSmallLinear
    mov ds:[ebx].bn_data,edx
    pop edx

cbCopy:
    or edx,edx
    jz cbDone
;
    mov edi,ds:[ebx].bn_data
;
    mov eax,flat_sel
    mov ds,eax
;
    or ecx,ecx
    jz cbZeroFill

cbCopyLoop:
    mov eax,[esi]    
    mov [edi],eax
    add esi,4
    add edi,4
    sub edx,1
    jz cbDone
;
    sub ecx,1
    jnz cbCopyLoop

cbZeroFill:
    xor eax,eax

cbZeroFillLoop:    
    mov [edi],eax
    add edi,4
    sub edx,1
    jnz cbZeroFillLoop

cbDone:
    popad        
    pop ds
    ret
CopyBuf ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GrowBuf
;
;           DESCRIPTION:    Grow buffer
;
;           PARAMETERS:     DS:EBX      Handle data
;                           ECX         Additional count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowBuf     PROC near
    push ds
    pushad
;    
    mov esi,ds:[ebx].bn_data
    mov eax,ds:[ebx].bn_count
    or eax,eax
    jnz gbSrcOk
;
    xor esi,esi

gbSrcOk:    
    push esi
    add ecx,ds:[ebx].bn_count
    mov eax,ecx
    shl eax,2
    AllocateSmallLinear
    mov edi,edx
    mov ds:[ebx].bn_data,edx
;
    mov edx,ds:[ebx].bn_count
    mov ds:[ebx].bn_count,ecx
;
    mov eax,flat_sel
    mov ds,eax
;
    or edx,edx
    jz gbCopyOk

gbCopyLoop:
    mov eax,[esi]
    mov [edi],eax
    add esi,4
    add edi,4
    sub ecx,1
    sub edx,1        
    jnz gbCopyLoop
;
    or ecx,ecx
    jz gbDone

gbCopyOk:
    xor eax,eax    

gbZeroLoop:    
    mov [edi],eax
    add edi,4
    sub ecx,1
    jnz gbZeroLoop
;    
    pop edx
    or edx,edx
    jz gbDone
;    
    xor ecx,ecx
    FreeLinear

gbDone:        
    popad
    pop ds
    ret
GrowBuf ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           OptBuf
;
;           DESCRIPTION:    Possibly shrink buffer
;
;           PARAMETERS:     DS:EBX      Handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OptBuf     PROC near
    push es
    pushad
;    
    mov esi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    or ecx,ecx
    jz obDone
;
    mov eax,flat_sel
    mov es,eax
;
    mov eax,ecx
    dec eax
    shl eax,2
    add esi,eax
    xor edx,edx

obCheckLoop:
    mov eax,es:[esi]
    or eax,eax
    jnz obCheckDone
;
    sub esi,4
    inc edx
    sub ecx,1    
    jnz obCheckLoop

obCheckDone:
    or edx,edx
    jz obDone
;
    mov ecx,ds:[ebx].bn_count
    sub ecx,edx
    mov ds:[ebx].bn_count,ecx
    jz obZero
;
    mov esi,ds:[ebx].bn_data
    push esi
    mov eax,ecx
    shl eax,2
    AllocateSmallLinear
    mov edi,edx
    mov ds:[ebx].bn_data,edx

obCopyLoop:
    mov eax,es:[esi]
    mov es:[edi],eax
    add esi,4
    add edi,4
    sub ecx,1
    jnz obCopyLoop    
;
    pop edx
    xor ecx,ecx
    FreeLinear
    jmp obDone

obZero:        
    xor ecx,ecx
    mov edx,ds:[ebx].bn_data
    FreeLinear

obDone:    
    popad
    pop es
    ret
OptBuf ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetBits
;
;           DESCRIPTION:    Get bit count in operand
;
;           PARAMETERS:     DS:ESI      Data
;                           ECX         Buffer count
;
;           RETURNS:        ECX         Bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBits     PROC near
    push eax
    push esi
;    
    or ecx,ecx
    jz gbitsDone
;
    shl ecx,2
    add esi,ecx
    dec esi
    shl ecx,3

gbitsLoop:
    mov al,[esi]
    or al,al
    jnz gbitsBitLoop
;
    sub ecx,8
    jz gbitsDone
;
    dec esi
    jmp gbitsLoop

gbitsBitLoop:
    test al,80h
    jnz gbitsDone
;
    dec ecx
    shl al,1
    jmp gbitsBitLoop    
        
gbitsDone:    
    pop esi
    pop eax
    ret
GetBits     Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyShiftLeft
;
;           DESCRIPTION:    Make a left shifted copy
;
;           PARAMETERS:     DS:ESI      Source data
;                           ECX         Source buffer count
;                           DS:EDI      Dest data
;                           EDX         Dest buffer count
;                           EBX         Shift count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyShiftLeft     PROC near
    pushad
;    
    mov eax,ebx
    shr eax,5

cslZeroLoop:    
    or eax,eax
    jz cslShiftIn
;
    mov dword ptr [edi],0
    add edi,4
    sub edx,1
    jz cslDone
;
    sub ebx,32
    sub eax,1
    jnz cslZeroLoop

cslShiftIn:
    xor eax,eax

cslShiftLoop:    
    or bl,bl
    jz cslShiftZero
;    
    push ecx
    mov cl,bl
    mov ebp,[esi]
    shl ebp,cl
    pop ecx
    or eax,ebp
    mov [edi],eax
;        
    push ecx
    mov cl,32
    sub cl,bl
    mov eax,[esi]
    shr eax,cl
    pop ecx
    jmp cslShiftNext

cslShiftZero:
    mov eax,[esi]
    mov [edi],eax
    xor eax,eax
    
cslShiftNext:
    add esi,4
    add edi,4
    sub edx,1
    jz cslDone
;
    sub ecx,1
    jnz cslShiftLoop    
;
    mov [edi],eax
    xor eax,eax

cslEndLoop:
    add edi,4
    sub edx,1
    jz cslDone
;
    mov [edi],eax        
    jmp cslEndLoop        

cslDone:   
    popad
    ret
CopyShiftLeft     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CopyShiftRight
;
;           DESCRIPTION:    Make a right shifted copy
;
;           PARAMETERS:     DS:ESI      Source data
;                           ECX         Source buffer count
;                           DS:EDI      Dest data
;                           EDX         Dest buffer count
;                           EBX         Shift count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyShiftRight     PROC near
    pushad
;    
    mov eax,ebx
    shr eax,5

csrSkipLoop:    
    or eax,eax
    jz csrShiftIn
;
    add esi,4
    sub ecx,1
    jz csrDone
;
    sub ebx,32
    sub eax,1
    jnz csrSkipLoop

csrShiftIn:
    mov ebp,edi
    mov eax,ecx
    dec eax
    shl eax,2    
    add esi,eax
    add edi,eax
    xor eax,eax

csrShiftLoop:    
    or bl,bl
    jz csrShiftZero
;    
    push ebp
    push ecx
    mov cl,bl
    mov ebp,[esi]
    shr ebp,cl
    pop ecx
    or eax,ebp
    mov [edi],eax
;        
    push ecx
    mov cl,32
    sub cl,bl
    mov eax,[esi]
    shl eax,cl
    pop ecx
    pop ebp
    jmp csrShiftNext

csrShiftZero:
    mov eax,[esi]
    mov [edi],eax
    xor eax,eax
    
csrShiftNext:
    sub esi,4
    sub edi,4
    add ebp,4
    sub edx,1
    jz csrDone
;
    sub ecx,1
    jnz csrShiftLoop    
;
    xor eax,eax

csrEndLoop:
    add ebp,4
    sub edx,1
    jz csrDone
;
    mov ds:[ebp],eax        
    jmp csrEndLoop        

csrDone:   
    popad
    ret
CopyShiftRight     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DoCompare
;
;           DESCRIPTION:    Compare numbers
;
;           PARAMETERS:     DS:ESI      Source data to subtract
;                           DS:EDI      Dest data
;                           ECX         Buffer count
;
;           RETURNS:        CY          Source larger
;                           NC          Dest larger
;                           ZR          Equal
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoCompare     PROC near
    push eax
    push ecx
    push esi
    push edi
;
    or ecx,ecx
    jz compDone
;
    mov eax,ecx
    dec eax
    shl eax,2
    add esi,eax
    add edi,eax
    
compLoop:
    mov eax,[edi]
    sub eax,[esi]
    jnz compDone
;
    sub esi,4
    sub edi,4
    sub ecx,1
    jnz compLoop    

compDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
DoCompare     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DoAdd
;
;           DESCRIPTION:    Do an add
;
;           PARAMETERS:     DS:ESI      Source data
;                           DS:EDI      Dest data
;                           ECX         Buffer count
;
;           RETURNS:        CY          overflow
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoAdd     PROC near
    push eax
    push ecx
    push esi
    push edi
;
    or ecx,ecx
    clc
    jz daDone
;
    pushf    

daLoop:
    popf
    mov eax,[esi]
    adc [edi],eax
    pushf
;
    add esi,4
    add edi,4
    sub ecx,1
    jnz daLoop        
;
    popf    
    
daDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
DoAdd     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DoSub
;
;           DESCRIPTION:    Do a sub
;
;           PARAMETERS:     DS:ESI      Source data to subtract
;                           DS:EDI      Dest data and result
;                           ECX         Buffer count
;
;           RETURNS:        CY          overflow
;                           ZR          highest dword zero
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoSub     PROC near
    push eax
    push ecx
    push esi
    push edi
;
    or ecx,ecx
    clc
    jz dsDone
;
    pushf    

dsLoop:
    popf
    mov eax,[esi]
    sbb [edi],eax
    pushf
;
    add esi,4
    add edi,4
    sub ecx,1
    jnz dsLoop        
;
    popf    
    
dsDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
DoSub     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DoNeg
;
;           DESCRIPTION:    Do a not
;
;           PARAMETERS:     DS:EDI      Dest data
;                           ECX         Buffer count
;
;           RETURNS:        CY          overflow
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoNeg     PROC near
    push eax
    push ecx
    push edi
;
    or ecx,ecx
    clc
    jz dnDone
;
    stc
    pushf    

dnLoop:
    mov eax,[edi]
    not eax
    popf
    adc eax,0
    mov [edi],eax
    pushf
;
    add edi,4    
    sub ecx,1
    jnz dnLoop        
;
    popf    
    
dnDone:
    pop edi
    pop ecx
    pop eax
    ret
DoNeg     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DoMul
;
;           DESCRIPTION:    Do a mul
;
;           PARAMETERS:     SS:EBP      Mul params
;                           DS          Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoMul     PROC near
    pushad
;
    mov ecx,[ebp].mul_out_count
    or ecx,ecx
    jz dmDone
;    
    xor eax,eax
    mov edi,[ebp].mul_out_data    

dmInitResLoop:
    mov [edi],eax
    add edi,4
    loop dmInitResLoop
;
    mov eax,[ebp].mul_in_count1
    or eax,eax
    jz dmDone
;    
    mov eax,[ebp].mul_in_count2
    or eax,eax
    jz dmDone
;
    xor ebx,ebx
    xor ecx,ecx
    mov esi,[ebp].mul_in_data1
    mov edi,[ebp].mul_in_data2

dmLoop:
    mov eax,[esi]
    mul [edi]
;
    push ebx    
    add ebx,ecx
    shl ebx,2
    add ebx,[ebp].mul_out_data
    add [ebx],eax
    adc [ebx+4],edx
    jnc dmNext
;    
    mov eax,1
    add ebx,4

dmCy:
    add ebx,4
    add [ebx],eax
    jc dmCy

dmNext:
    add esi,4
    pop ebx
    inc ebx
    cmp ebx,[ebp].mul_in_count1
    jne dmLoop
;
    mov esi,[ebp].mul_in_data1
    add edi,4
    xor ebx,ebx
    inc ecx            
    cmp ecx,[ebp].mul_in_count2
    jne dmLoop
    
dmDone:
    popad
    ret
DoMul     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DoDiv
;
;           DESCRIPTION:    Do a div
;
;           PARAMETERS:     SS:EBP      Div params
;                           DS          Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DoDiv     PROC near
    pushad
;
    mov ecx,[ebp].div_quot_count
    mov [ebp].div_temp_count,ecx
    mov edi,[ebp].div_quot_data
    xor eax,eax

ddClearLoop:
    mov [edi],eax
    add edi,4
    loop ddClearLoop
;
    mov esi,[ebp].div_mod_data
    mov ecx,[ebp].div_temp_count
    call GetBits
;
    push ecx
    mov esi,[ebp].div_divisor_data
    mov ecx,[ebp].div_divisor_count
    call GetBits
    pop ebx
    sub ebx,ecx
    jc divDone

divLoop:
    mov esi,[ebp].div_divisor_data
    mov ecx,[ebp].div_divisor_count
    mov edi,[ebp].div_temp_quot_data
    mov edx,[ebp].div_temp_count
    call CopyShiftLeft
;
    mov esi,[ebp].div_temp_quot_data
    mov edi,[ebp].div_mod_data
    mov ecx,[ebp].div_temp_count
    call DoCompare
    jz divEqual
    jc divNext
;
    mov edx,[ebp].div_quot_data
    bts [edx],ebx
;
    call DoSub
    jnz divNext
;    
    sub dword ptr [ebp].div_temp_count,1
    mov esi,[ebp].div_mod_data
    mov ecx,[ebp].div_temp_count
    call GetBits
;
    push ecx
    mov esi,[ebp].div_divisor_data
    mov ecx,[ebp].div_divisor_count
    call GetBits
    pop ebx
    sub ebx,ecx
    jnc divLoop
    jmp divDone
    
divNext:
    sub ebx,1
    jnc divLoop
    jmp divDone 
       
divEqual:
    mov edx,[ebp].div_quot_data
    bts [edx],ebx
    call DoSub

divDone:
    popad
    ret
DoDiv   ENDP    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateBigNum
;
;           DESCRIPTION:    Create big number
;
;           RETURNS:        BX          Big number handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_bignum_name    DB 'Create Big Number',0

create_bignum     PROC far
    push ds
    push es
    push eax
    push cx
;
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
    mov bx,[ebx].hh_handle
    clc
;
    pop cx
    pop eax
    pop es
    pop ds
    ret
create_bignum     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DeleteBigNum
;
;           DESCRIPTION:    Delete big num
;
;           PARAMETERS:     BX          Big num handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_bignum_name    DB 'Delete Big Number',0

delete_bignum     PROC far
    push ds
    push ebx
    push ecx
    push edx
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc cbnDone
;
    mov ecx,ds:[ebx].bn_count
    or ecx,ecx
    jz cbnFree
;
    shl ecx,2
    mov edx,ds:[ebx].bn_data
    FreeLinear    

cbnFree:    
    FreeHandle
    clc

cbnDone:
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
delete_bignum     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LoadSignedBigNum
;
;           DESCRIPTION:    Load signed big num
;
;           PARAMETERS:     BX          Big num handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_signed_bignum_name    DB 'Load Signed Big Number',0

load_signed_bignum     PROC near
    push ds
    push fs
    pushad
;
    mov eax,flat_sel
    mov fs,eax    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc lsbDone
;
    or ecx,ecx
    jnz lsbCopy
;
    xor ecx,ecx
    call RecreateBuf
    jmp lsbDone

lsbCopy:
    push ecx
    dec ecx
    shr ecx,2
    inc ecx
    call RecreateBuf
    pop ecx
;
    mov esi,ds:[ebx].bn_data
    mov edx,ds:[ebx].bn_count
    shl edx,2
;
    mov eax,edi
    add eax,ecx
    dec eax
    mov al,es:[eax]
    test al,80h
    jz lsbPos

lsbNeg:
    mov ds:[ebx].bn_flags,BN_FLAG_NEGATIVE

lsbNegCopy:
    mov al,es:[edi]
    not al
    mov fs:[esi],al
    inc esi
    inc edi
    dec edx
    loop lsbNegCopy
;
    or edx,edx
    jz lsbNegInc
;
    xor al,al

lsbNegFill:
    mov fs:[esi],al
    inc esi
    sub edx,1
    jnz lsbNegFill

lsbNegInc:
    mov esi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    xor edx,edx
    stc
    lahf

lsbNegIncLoop:
    sahf
    adc fs:[esi],edx
    lahf
    loop lsbNegIncLoop
;
    jmp lsbOpt

lsbPos:
    mov ds:[ebx].bn_flags,0

lsbPosCopy:
    mov al,es:[edi]
    mov fs:[esi],al
    inc esi
    inc edi
    dec edx
    loop lsbPosCopy
;
    or edx,edx
    jz lsbOpt
;
    xor al,al

lsbPosFill:
    mov fs:[esi],al
    inc esi
    sub edx,1
    jnz lsbPosFill

lsbOpt:
    call OptBuf

lsbDone: 
    popad
    pop fs
    pop ds
    ret
load_signed_bignum     ENDP

load_signed_bignum32   Proc far
    call load_signed_bignum
    ret
load_signed_bignum32   Endp

load_signed_bignum16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call load_signed_bignum
;       
    pop edi
    pop ecx
    ret
load_signed_bignum16   Endp    

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LoadUnsignedBigNum
;
;           DESCRIPTION:    Load unsigned big num
;
;           PARAMETERS:     BX          Big num handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_unsigned_bignum_name    DB 'Load Unsigned Big Number',0

load_unsigned_bignum     PROC near
    push ds
    push fs
    pushad
;
    mov eax,flat_sel
    mov fs,eax    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc lsuDone
;
    or ecx,ecx
    jnz lsuNonZero
;
    xor ecx,ecx
    call RecreateBuf
    jmp lsuDone

lsuNonZero:
    push ecx
    dec ecx
    shr ecx,2
    inc ecx
    call RecreateBuf
    pop ecx
;
    mov ds:[ebx].bn_flags,0
    mov esi,ds:[ebx].bn_data
    mov edx,ds:[ebx].bn_count
    shl edx,2

lsuCopy:
    mov al,es:[edi]
    mov fs:[esi],al
    inc esi
    inc edi
    dec edx
    loop lsuCopy
;
    or edx,edx
    jz lsuOpt
;
    xor al,al

lsuFill:
    mov fs:[esi],al
    inc esi
    sub edx,1
    jnz lsuFill

lsuOpt:
    call OptBuf

lsuDone: 
    popad
    pop fs
    pop ds
    ret
load_unsigned_bignum     ENDP

load_unsigned_bignum32   Proc far
    call load_unsigned_bignum
    ret
load_unsigned_bignum32   Endp

load_unsigned_bignum16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call load_unsigned_bignum
;       
    pop edi
    pop ecx
    ret
load_unsigned_bignum16   Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SaveSignedBigNum
;
;           DESCRIPTION:    Save signed big num
;
;           PARAMETERS:     BX          Big num handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

save_signed_bignum_name    DB 'Save Signed Big Number',0

save_signed_bignum     PROC near
    push ds
    push fs
    pushad
;
    mov eax,flat_sel
    mov fs,eax    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc ssDone
;
    or ecx,ecx
    stc
    jz ssDone
;
    push ecx
    push edi
;
    mov esi,ds:[ebx].bn_data
    mov edx,ds:[ebx].bn_count

ssCopy:
    or edx,edx
    jz ssPad
;
    mov al,fs:[esi]
    mov es:[edi],al
    inc esi
    inc edi
    sub ecx,1
    jz ssSign
;
    mov al,fs:[esi]
    mov es:[edi],al
    inc esi
    inc edi
    sub ecx,1
    jz ssSign
;
    mov al,fs:[esi]
    mov es:[edi],al
    inc esi
    inc edi
    sub ecx,1
    jz ssSign
;
    mov al,fs:[esi]
    mov es:[edi],al
    inc esi
    inc edi
    sub ecx,1
    jz ssSign
;
    sub edx,1
    jnz ssCopy

ssPad:
    xor al,al
    mov es:[edi],al
    inc edi
    sub ecx,1
    jnz ssPad

ssSign:
    pop edi
    pop ecx
;
    test ds:[ebx].bn_flags,BN_FLAG_NEGATIVE
    jz ssDone
;
    stc
    lahf

ssNegLoop:
    mov al,es:[edi]
    not al
    sahf
    adc al,0
    mov es:[edi],al
    lahf
;
    inc edi
    loop ssNegLoop

ssDone: 
    popad
    pop fs
    pop ds
    ret
save_signed_bignum     ENDP

save_signed_bignum32   Proc far
    call save_signed_bignum
    ret
save_signed_bignum32   Endp

save_signed_bignum16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call save_signed_bignum
;       
    pop edi
    pop ecx
    ret
save_signed_bignum16   Endp    

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SaveUnsignedBigNum
;
;           DESCRIPTION:    Save unsigned big num
;
;           PARAMETERS:     BX          Big num handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

save_unsigned_bignum_name    DB 'Save Unsigned Big Number',0

save_unsigned_bignum     PROC near
    push ds
    pushad
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc susDone
;
    or ecx,ecx
    stc
    jz susDone
;
    mov esi,ds:[ebx].bn_data
    mov edx,ds:[ebx].bn_count
    mov eax,flat_sel
    mov ds,eax    

susCopy:
    or edx,edx
    jz susPad
;
    mov al,[esi]
    mov es:[edi],al
    inc esi
    inc edi
    sub ecx,1
    jz susDone
;
    mov al,[esi]
    mov es:[edi],al
    inc esi
    inc edi
    sub ecx,1
    jz susDone
;
    mov al,[esi]
    mov es:[edi],al
    inc esi
    inc edi
    sub ecx,1
    jz susDone
;
    mov al,[esi]
    mov es:[edi],al
    inc esi
    inc edi
    sub ecx,1
    jz susDone
;
    sub edx,1
    jnz susCopy

susPad:
    xor al,al
    mov es:[edi],al
    inc edi
    sub ecx,1
    jnz susPad

susDone: 
    popad
    pop ds
    ret
save_unsigned_bignum     ENDP

save_unsigned_bignum32   Proc far
    call save_unsigned_bignum
    ret
save_unsigned_bignum32   Endp

save_unsigned_bignum16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call save_unsigned_bignum
;       
    pop edi
    pop ecx
    ret
save_unsigned_bignum16   Endp    

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ConvDecDigit
;
;           DESCRIPTION:    Convert decimal digit
;
;           PARAMETERS:     AL
;
;           RETURNS:        NC	Decimal digit
;                           AL  Converted value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvDecDigit  Proc near
    sub al,'0'
    jb cddFail
;
    cmp al,9
    ja cddFail
;
    clc
    ret

cddFail:
    stc
    ret
ConvDecDigit  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ConvHexDigit
;
;           DESCRIPTION:    Convert hex digit
;
;           PARAMETERS:     AL
;
;           RETURNS:        NC	Decimal digit
;                           AL  Converted value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvHexDigit  Proc near
    cmp al,'a'
    jae chdSmall
;
    cmp al,'A'
    jae chdBig

chdDec:
    sub al,'0'
    jb chdFail
;
    cmp al,9
    ja chdFail
;
    clc
    ret

chdSmall:
    sub al,'a'
    add al,10
    cmp al,10h
    jae chdFail
;
    clc
    ret

chdBig:
    sub al,'A'
    add al,10
    cmp al,10h
    jae chdFail
;
    clc
    ret

chdFail:
    stc
    ret
ConvHexDigit  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetStringStart
;
;           DESCRIPTION:    Get string start
;
;           PARAMETERS:     ES:EDI string
;
;           RETURNS:        ES:EDI start of string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetStringStart  Proc near
    mov al,es:[edi]
    cmp al,' '
    je gssAdv
;
    cmp al,'	'
    je gssAdv
;
    ret

gssAdv:
    inc edi
    jmp GetStringStart

GetStringStart  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LoadDecStrBigNum
;
;           DESCRIPTION:    Load big num from string
;
;           PARAMETERS:     BX          Big num handle
;                           ES:(E)DI    String
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_dec_str_bignum_name    DB 'Load Dec String Big Number',0

load_dec_str_bignum     PROC near
    push ebp
    sub esp,SIZE mul_struc
    mov ebp,esp
;
    push ds
    push fs
    pushad
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc ldsDone
;
    call GetStringStart
    mov ds:[ebx].bn_flags,0
    mov al,es:[edi]
    cmp al,'-'
    jne ldsPos
;
    inc edi
    mov ds:[ebx].bn_flags,BN_FLAG_NEGATIVE

ldsPos:
    push edi
    xor ecx,ecx

ldsGetSizeLoop:
    mov al,es:[edi]
    call ConvDecDigit
    jc ldsSizeOk
;
    inc edi
    inc ecx
    jmp ldsGetSizeLoop

ldsSizeOk:
    pop edi
;
    dec ecx
    shr ecx,2
    inc ecx
    call RecreateBuf
;
    mov eax,flat_sel
    mov fs,eax    
    mov esi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    or ecx,ecx
    jz ldsDone
;
    xor eax,eax

ldsClearLoop:    
    mov fs:[esi],eax
    add esi,4
    loop ldsClearLoop
;
    push ds
;
    mov eax,4
    AllocateSmallLinear
    mov [ebp].mul_in_data1,edx
    mov [ebp].mul_in_count1,1
    mov eax,10
    mov fs:[edx],eax
;
    mov eax,ds:[ebx].bn_data
    mov [ebp].mul_in_data2,eax
    mov eax,ds:[ebx].bn_count
    mov [ebp].mul_in_count2,eax
;
    mov eax,ds:[ebx].bn_count
    mov [ebp].mul_out_count,eax
    shl eax,2
    AllocateSmallLinear
    mov [ebp].mul_out_data,edx
;
    mov eax,flat_sel
    mov ds,eax

ldsConvLoop:
    mov al,es:[edi]
    call ConvDecDigit
    jc ldsConvDone
;
    push eax
    call DoMul
    pop eax
;
    push ecx
    push esi
    push edi
;
    movzx edx,al
    mov ecx,[ebp].mul_out_count
    mov esi,[ebp].mul_out_data
    mov edi,[ebp].mul_in_data2
    clc
    lahf

ldsMoveAddLoop:
    sahf
    adc edx,ds:[esi]
    mov ds:[edi],edx
    lahf
    xor edx,edx
;
    add esi,4
    add edi,4
    loop ldsMoveAddLoop
;
    pop edi
    pop esi
    pop ecx
;
    inc edi
    inc ecx
    jmp ldsConvLoop

ldsConvDone:
    pop ds
;
    mov ecx,[ebp].mul_in_count1
    shl ecx,2
    mov edx,[ebp].mul_in_data1
    FreeLinear
;
    mov ecx,[ebp].mul_out_count
    shl ecx,2
    mov edx,[ebp].mul_out_data
    FreeLinear
;
    call OptBuf

ldsDone: 
    popad
    pop fs
    pop ds
;
    add esp,SIZE mul_struc
    pop ebp
    ret
load_dec_str_bignum     ENDP

load_dec_str_bignum32   Proc far
    call load_dec_str_bignum
    ret
load_dec_str_bignum32   Endp

load_dec_str_bignum16   Proc far
    push edi
;
    movzx edi,di
    call load_dec_str_bignum
;       
    pop edi
    ret
load_dec_str_bignum16   Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LoadHexStrBigNum
;
;           DESCRIPTION:    Load big num from hex string
;
;           PARAMETERS:     BX          Big num handle
;                           ES:(E)DI    String
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_hex_str_bignum_name    DB 'Load Hex String Big Number',0

load_hex_str_bignum     PROC near
    push ds
    push fs
    pushad
;
    mov eax,flat_sel
    mov fs,eax
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc lhsDone
;
    call GetStringStart
    mov ds:[ebx].bn_flags,0
;
    push edi
    xor ecx,ecx

lhsGetSizeLoop:
    mov al,es:[edi]
    call ConvHexDigit
    jc lhsSizeOk
;
    inc edi
    inc ecx
    jmp lhsGetSizeLoop

lhsSizeOk:
    pop edi
;
    dec ecx
    shr ecx,2
    inc ecx
    call RecreateBuf
;
    mov esi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    or ecx,ecx
    jz lhsDone
;
    xor eax,eax

lhsClearLoop:    
    mov fs:[esi],eax
    add esi,4
    loop lhsClearLoop

lhsConvLoop:
    mov al,es:[edi]
    call ConvHexDigit
    jc lhsConvDone
;
    movzx edx,al
    mov esi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
;
    clc
    lahf

lhsMoveAddLoop:
    mov ebp,fs:[esi]
    shl ebp,4
    sahf
    adc edx,ebp
    lahf
;
    mov ebp,fs:[esi]
    shr ebp,28
;
    mov fs:[esi],edx
    mov edx,ebp
;
    add esi,4
    loop lhsMoveAddLoop
;
    inc edi
    jmp lhsConvLoop

lhsConvDone:
    call OptBuf

lhsDone: 
    popad
    pop fs
    pop ds
    ret
load_hex_str_bignum     ENDP

load_hex_str_bignum32   Proc far
    call load_hex_str_bignum
    ret
load_hex_str_bignum32   Endp

load_hex_str_bignum16   Proc far
    push edi
;
    movzx edi,di
    call load_hex_str_bignum
;       
    pop edi
    ret
load_hex_str_bignum16   Endp    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetDecStrSizeBigNum
;
;           DESCRIPTION:    Get big num size in base 10
;
;           PARAMETERS:     BX          Num handle
;
;           RETURNS:        ECX         Buffer size for base 10
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dec_str_size_bignum_name    DB 'Get Decimal String Size for Big Number',0

text_invalid DB 'Invalid', 0
text_infinite DB 'Infinite', 0

get_dec_str_size_bignum     PROC far
    push ebp
    sub esp,SIZE div_struc
    mov ebp,esp
;    
    push ds
    push fs
    push eax
    push ebx
    push edx
    push esi
    push edi
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc gdssFail
;    
    mov eax,ds
    mov fs,eax
;
    mov ax,ds:[ebx].bn_flags
    test ax,BN_FLAG_INFINITE
    jnz gdssInfinite
;
    mov eax,ds:[ebx].bn_count
    or eax,eax
    jz gdssZero
;    
    mov [ebp].div_quot_count,eax    
    mov eax,ds:[ebx].bn_data
    mov [ebp].div_mod_data,eax
;
    mov eax,1    
    mov [ebp].div_divisor_count,eax    
    mov ecx,eax
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_divisor_data,edx
;    
    push esi
    push edi
    mov eax,flat_sel
    mov ds,eax    
    mov eax,10
    mov ds:[edx],eax
;
    mov esi,[ebp].div_mod_data
    mov eax,[ebp].div_quot_count
    mov ecx,eax
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_mod_data,edx
    mov edi,edx

gdssCopyNomLoop:
    mov eax,[esi]
    mov [edi],eax
    add esi,4
    add edi,4
    loop gdssCopyNomLoop    

gdssCopyDone:
    pop edi
    pop esi    
;
    mov eax,[ebp].div_quot_count
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_temp_quot_data,edx
;    
    mov eax,[ebp].div_quot_count
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_quot_data,edx
;
    mov edx,1

gdssRetry:
    call DoDiv
;
    mov ecx,[ebp].div_quot_count
    mov esi,[ebp].div_quot_data
    call GetBits
    or ecx,ecx
    jz gdssOk
;
    inc edx
    mov ecx,[ebp].div_quot_count
    mov esi,[ebp].div_quot_data
    mov edi,[ebp].div_mod_data

gdssRetryLoop:
    mov eax,[esi]
    mov [edi],eax
    add esi,4
    add edi,4
    loop gdssRetryLoop
    jmp gdssRetry

gdssOk:
    mov ecx,edx
;    
    push ecx
    mov ecx,[ebp].div_quot_count
    shl ecx,2
    mov edx,[ebp].div_temp_quot_data
    FreeLinear
    pop ecx
;    
    push ecx
    mov ecx,[ebp].div_quot_count
    shl ecx,2
    mov edx,[ebp].div_quot_data
    FreeLinear
    pop ecx
;    
    push ecx
    mov ecx,[ebp].div_divisor_count
    shl ecx,2
    mov edx,[ebp].div_divisor_data
    FreeLinear
    pop ecx
;    
    push ecx
    mov ecx,[ebp].div_quot_count
    shl ecx,2
    mov edx,[ebp].div_mod_data
    FreeLinear
    pop ecx
    jmp gdssAddSign
            
gdssFail:
    mov ecx,7
    jmp gdssLeave

gdssZero:
    mov ecx,1
    jmp gdssLeave

gdssInfinite:
    mov ecx,8

gdssAddSign:
    test fs:[ebx].bn_flags,BN_FLAG_NEGATIVE
    jz gdssLeave
;
    inc ecx
    
gdssLeave:
    inc ecx
;    
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    pop fs
    pop ds
;
    add esp,SIZE div_struc
    pop ebp
    ret
get_dec_str_size_bignum  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SaveDecStrBigNum
;
;           DESCRIPTION:    Save big number as decimal string
;
;           PARAMETERS:     BX          Num handle
;                           ES:EDI      Buffer
;                           ECX         Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

save_dec_str_bignum_name    DB 'Save Decimal String Big Number',0

save_dec_str_bignum     PROC near
    push ebp
    sub esp,SIZE div_struc
    mov ebp,esp
;    
    push ds
    push fs
    pushad
;
    cmp ecx,2
    jb sdsLeave
;    
    add edi,ecx
    dec edi
    xor al,al
    mov es:[edi],al
    dec edi
;
    mov [ebp].div_offset,edi
    dec ecx
    mov [ebp].div_size,ecx
;    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc sdsFail
;    
    mov eax,ds
    mov fs,eax
;
    mov ax,ds:[ebx].bn_flags
    test ax,BN_FLAG_INFINITE
    jnz sdsInfinite
;
    mov eax,ds:[ebx].bn_count
    or eax,eax
    jz sdsZero
;    
    mov [ebp].div_quot_count,eax    
    mov eax,ds:[ebx].bn_data
    mov [ebp].div_mod_data,eax
;
    mov eax,flat_sel
    mov ds,eax    
;
    mov eax,1    
    mov [ebp].div_divisor_count,eax    
    mov ecx,eax
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_divisor_data,edx
    mov eax,10
    mov [edx],eax
;    
    push esi
    push edi
;
    mov esi,[ebp].div_mod_data
    mov eax,[ebp].div_quot_count
    mov ecx,eax
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_mod_data,edx
    mov edi,edx

sdsCopyNomLoop:
    mov eax,[esi]
    mov [edi],eax
    add esi,4
    add edi,4
    loop sdsCopyNomLoop    

sdsCopyDone:
    pop edi
    pop esi    
;
    mov eax,[ebp].div_quot_count
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_temp_quot_data,edx
;    
    mov eax,[ebp].div_quot_count
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_quot_data,edx

sdsRetry:
    call DoDiv
;
    mov edi,[ebp].div_mod_data
    mov al,[edi]
    add al,'0'
    mov edi,[ebp].div_offset
    mov es:[edi],al
    dec edi
    mov [ebp].div_offset,edi
    sub [ebp].div_size,1
    jz sdsOk
;
    mov ecx,[ebp].div_quot_count
    mov esi,[ebp].div_quot_data
    call GetBits
    or ecx,ecx
    jz sdsOk
;
    mov ecx,[ebp].div_quot_count
    mov esi,[ebp].div_quot_data
    mov edi,[ebp].div_mod_data

sdsRetryLoop:
    mov eax,[esi]
    mov [edi],eax
    add esi,4
    add edi,4
    loop sdsRetryLoop
;
    jmp sdsRetry

sdsOk:
    mov ecx,[ebp].div_quot_count
    shl ecx,2
    mov edx,[ebp].div_temp_quot_data
    FreeLinear
;    
    mov ecx,[ebp].div_quot_count
    shl ecx,2
    mov edx,[ebp].div_quot_data
    FreeLinear
;    
    mov ecx,[ebp].div_divisor_count
    shl ecx,2
    mov edx,[ebp].div_divisor_data
    FreeLinear
;    
    mov ecx,[ebp].div_quot_count
    shl ecx,2
    mov edx,[ebp].div_mod_data
    FreeLinear
;
    mov eax,[ebp].div_size
    or eax,eax
    jz sdsLeave
;    
    jmp sdsAddSign
            
sdsFail:
    mov esi,OFFSET text_invalid
    jmp sdsWriteText

sdsZero:
    mov al,'0'
    mov edi,[ebp].div_offset
    mov es:[edi],al
    dec edi
    mov [ebp].div_offset,edi
    sub [ebp].div_size,1
    jz sdsLeave
    jmp sdsFill

sdsInfinite: 
    mov esi,OFFSET text_infinite

sdsWriteText:    
    mov edi,[ebp].div_offset
    mov ecx,[ebp].div_size
    sub edi,ecx
    inc edi
    inc ecx

sdsWriteLoop:    
    mov al,cs:[esi]
    or al,al
    jz sdsAddNull
;    
    mov es:[edi],al
    inc edi
    inc esi
    sub ecx,1
    jnz sdsWriteLoop
;
    dec edi

sdsAddNull:    
    xor al,al
    mov es:[edi],al
    jmp sdsLeave    

sdsAddSign:
    test fs:[ebx].bn_flags,BN_FLAG_NEGATIVE
    jz sdsFill
;
    mov al,'-'
    mov edi,[ebp].div_offset
    mov es:[edi],al
    dec edi
    mov [ebp].div_offset,edi
    sub [ebp].div_size,1
    jz sdsLeave

sdsFill:
    mov al,' '
    mov edi,[ebp].div_offset
    mov es:[edi],al
    dec edi
    mov [ebp].div_offset,edi
    sub [ebp].div_size,1
    jnz sdsFill
    
sdsLeave:
    popad
    pop fs
    pop ds
;
    add esp,SIZE div_struc
    pop ebp
    ret
save_dec_str_bignum     ENDP

save_dec_str_bignum32   Proc far
    call save_dec_str_bignum
    ret
save_dec_str_bignum32   Endp

save_dec_str_bignum16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call save_dec_str_bignum
;       
    pop edi
    pop ecx
    ret
save_dec_str_bignum16   Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetHexStrSizeBigNum
;
;           DESCRIPTION:    Get big num size in base 16
;
;           PARAMETERS:     BX          Num handle
;
;           RETURNS:        ECX         Buffer size for base 16
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_hex_str_size_bignum_name    DB 'Get Hex String Size for Big Number',0

get_hex_str_size_bignum     PROC far
    push ds
    push eax
    push ebx
    push edx
;    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc ghssFail
;    
    mov ax,ds:[ebx].bn_flags
    test ax,BN_FLAG_INFINITE
    jnz ghssInfinite
;
    mov ecx,ds:[ebx].bn_count
    or ecx,ecx
    jz ghssAddSign
;
    mov esi,ds:[ebx].bn_data
;
    push ds
    mov eax,flat_sel
    mov ds,eax
    call GetBits
    pop ds
;
    dec ecx
    shr ecx,2
    inc ecx
    jmp ghssAddSign
            
ghssFail:
    mov ecx,7
    jmp ghssLeave

ghssInfinite:
    mov ecx,8

ghssAddSign:
    test ds:[ebx].bn_flags,BN_FLAG_NEGATIVE
    jz ghssLeave
;
    inc ecx
    
ghssLeave:
    inc ecx
;    
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
get_hex_str_size_bignum  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SaveHexStrBigNum
;
;           DESCRIPTION:    Get big num str in base 16
;
;           PARAMETERS:     BX          Num handle
;                           ES:EDI      Buffer
;                           ECX         Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

save_hex_str_bignum_name    DB 'Save Hex String Big Number',0

ToHex   Proc near
    and al,0Fh
    cmp al,10
    jb thLow
;
    sub al,10
    add al,'A'        
    ret

thLow:
    add al,'0'
    ret    
ToHex   Endp

save_hex_str_bignum     PROC near
    push ds
    pushad
;
    cmp ecx,2
    jb shsLeave
;    
    add edi,ecx
    dec edi
    xor al,al
    mov es:[edi],al
    dec edi
    dec ecx
;    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc shsFail
;    
    mov ax,ds:[ebx].bn_flags
    test ax,BN_FLAG_INFINITE
    jnz shsInfinite
;
    mov edx,ds:[ebx].bn_count
    or edx,edx
    jz shsAddSign

    mov esi,ds:[ebx].bn_data
    mov bp,ds:[ebx].bn_flags
    mov eax,flat_sel
    mov ds,eax

shsLoop:
    mov eax,[esi]
    call ToHex
    mov es:[edi],al
    dec edi
    sub ecx,1
    jz shsLeave
;    
    mov eax,[esi]
    shr eax,4
    call ToHex
    mov es:[edi],al
    dec edi
    sub ecx,1
    jz shsLeave
;
    mov eax,[esi]
    shr eax,8
    call ToHex
    mov es:[edi],al
    dec edi
    sub ecx,1
    jz shsLeave
;    
    mov eax,[esi]
    shr eax,12
    call ToHex
    mov es:[edi],al
    dec edi
    sub ecx,1
    jz shsLeave
;
    mov eax,[esi]
    shr eax,16
    call ToHex
    mov es:[edi],al
    dec edi
    sub ecx,1
    jz shsLeave
;    
    mov eax,[esi]
    shr eax,20
    call ToHex
    mov es:[edi],al
    dec edi
    sub ecx,1
    jz shsLeave
;
    mov eax,[esi]
    shr eax,24
    call ToHex
    mov es:[edi],al
    dec edi
    sub ecx,1
    jz shsLeave
;    
    mov eax,[esi]
    shr eax,28
    call ToHex
    mov es:[edi],al
    dec edi
    sub ecx,1
    jz shsLeave
;    
    add esi,4
    sub edx,1
    jnz shsLoop
;
    jmp shsAddSign
                
shsFail:
    mov esi,OFFSET text_invalid
    jmp shsWriteText

shsZero:
    mov al,'0'
    mov es:[edi],al
    dec edi
    sub ecx,1
    jz shsLeave
    jmp shsFill

shsInfinite: 
    mov esi,OFFSET text_infinite

shsWriteText:    
    sub edi,ecx
    inc edi
    inc ecx

shsWriteLoop:    
    mov al,cs:[esi]
    or al,al
    jz shsAddNull
;    
    mov es:[edi],al
    inc edi
    inc esi
    sub ecx,1
    jnz shsWriteLoop
;
    dec edi

shsAddNull:    
    xor al,al
    mov es:[edi],al
    jmp shsLeave    

shsAddSign:
    test bp,BN_FLAG_NEGATIVE
    jz shsFill
;
    mov al,'-'
    mov es:[edi],al
    dec edi
    sub ecx,1
    jz shsLeave

shsFill:
    mov al,'0'
    mov es:[edi],al
    dec edi
    sub ecx,1
    jnz shsFill
    
shsLeave:
    popad
    pop ds
    ret
save_hex_str_bignum  ENDP

save_hex_str_bignum32   Proc far
    call save_hex_str_bignum
    ret
save_hex_str_bignum32   Endp

save_hex_str_bignum16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call save_hex_str_bignum
;       
    pop edi
    pop ecx
    ret
save_hex_str_bignum16   Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddBigNum
;
;           DESCRIPTION:    Add big num
;
;           PARAMETERS:     BX          Big num handle 1
;                           AX          Big num handle 2
;
;           RETURNS:        BX          Result big num handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_bignum_name    DB 'Add Big Number',0

add_bignum     PROC far
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    mov ax,flat_sel
    mov es,ax    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    pop ax
    jc anFail
;
    mov esi,ebx
    mov bx,ax
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc anFail
;
    mov edi,ebx
;    
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
;
    mov ax,ds:[esi].bn_flags
    xor ax,ds:[edi].bn_flags
    test ax,BN_FLAG_NEGATIVE
    jnz anSub

anAdd:
    mov ecx,ds:[esi].bn_count
    cmp ecx,ds:[edi].bn_count
    ja anAddUse2

anAddUse1:
    push esi
    push edi
;    
    mov ecx,ds:[esi].bn_count
    mov edx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoAdd
;
    pop edi
    pop esi    
    jmp anFixupAdd

anAddUse2:  
    push esi
    push edi
;      
    xchg esi,edi
    mov ecx,ds:[esi].bn_count
    mov edx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoAdd
;
    pop edi
    pop esi

anFixupAdd:
    jnc anAddSign
;
    mov ecx,1
    call GrowBuf
;
    mov edx,ds:[ebx].bn_count
    dec edx
    shl edx,2
    add edx,ds:[ebx].bn_data
    mov eax,1
    mov es:[edx],eax

anAddSign:    
    mov ax,ds:[esi].bn_flags
    or ax,ds:[edi].bn_flags
    mov ds:[ebx].bn_flags,ax
    jmp anDone

anSub:
    mov ecx,ds:[esi].bn_count
    cmp ecx,ds:[edi].bn_count
    ja anSubUse2

anSubUse1:
    push esi
    push edi
;    
    mov ecx,ds:[esi].bn_count
    mov edx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoSub
;
    pop edi
    pop esi    
    jnc anSubFixup1
;
    push edi
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoNeg
    pop edi
;
    mov ax,ds:[edi].bn_flags
    mov dx,ds:[esi].bn_flags
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;
    call OptBuf
    jmp anDone

anSubFixup1:
    mov ax,ds:[esi].bn_flags
    mov dx,ds:[edi].bn_flags
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;    
    call OptBuf
    jmp anDone

anSubUse2:  
    push esi
    push edi
;      
    xchg esi,edi
    mov ecx,ds:[esi].bn_count
    mov edx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoSub
;
    pop edi
    pop esi
    jnc anSubFixup2
;
    push edi
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoNeg
    pop edi
;
    mov ax,ds:[esi].bn_flags
    mov dx,ds:[edi].bn_flags
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;    
    call OptBuf
    jmp anDone

anSubFixup2:
    mov ax,ds:[edi].bn_flags
    mov dx,ds:[esi].bn_flags
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;    
    call OptBuf

anDone:    
    mov bx,[ebx].hh_handle
    clc
    jmp anEnd

anFail:
    xor bx,bx 
    stc   

anEnd:        
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret    
add_bignum     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SubBigNum
;
;           DESCRIPTION:    Sub big num
;
;           PARAMETERS:     BX          Big num handle 1
;                           AX          Big num handle 2
;
;           RETURNS:        BX          Result big num handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sub_bignum_name    DB 'Sub Big Number',0

sub_bignum     PROC far
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    mov ax,flat_sel
    mov es,ax    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    pop ax
    jc sbnFail
;
    mov esi,ebx
    mov bx,ax
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc sbnFail
;
    mov edi,ebx
;    
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
;
    mov ax,ds:[esi].bn_flags
    xor ax,ds:[edi].bn_flags
    test ax,BN_FLAG_NEGATIVE
    jz sbnSub

sbnAdd:
    mov ecx,ds:[esi].bn_count
    cmp ecx,ds:[edi].bn_count
    ja sbnAddUse2

sbnAddUse1:
    push esi
    push edi
;    
    mov ecx,ds:[esi].bn_count
    mov edx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoAdd
;
    pop edi
    pop esi    
    jmp sbnFixupAdd

sbnAddUse2:  
    push esi
    push edi
;      
    xchg esi,edi
    mov ecx,ds:[esi].bn_count
    mov edx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoAdd
;
    pop edi
    pop esi

sbnFixupAdd:
    jnc anAddSign
;
    mov ecx,1
    call GrowBuf
;
    mov edx,ds:[ebx].bn_count
    dec edx
    shl edx,2
    add edx,ds:[ebx].bn_data
    mov eax,1
    mov es:[edx],eax

sbnAddSign:    
    mov ax,ds:[esi].bn_flags
    or ax,ds:[edi].bn_flags
    xor ax,BN_FLAG_NEGATIVE
    mov ds:[ebx].bn_flags,ax
    jmp sbnDone

sbnSub:
    mov ecx,ds:[esi].bn_count
    cmp ecx,ds:[edi].bn_count
    ja sbnSubUse2

sbnSubUse1:
    push esi
    push edi
;    
    mov ecx,ds:[esi].bn_count
    mov edx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoSub
;
    pop edi
    pop esi    
    jnc sbnSubFixup1
;
    push edi
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoNeg
    pop edi
;
    mov ax,ds:[edi].bn_flags
    xor ax,BN_FLAG_NEGATIVE
    mov dx,ds:[esi].bn_flags
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;
    call OptBuf
    jmp sbnDone

sbnSubFixup1:
    mov ax,ds:[esi].bn_flags
    mov dx,ds:[edi].bn_flags
    xor dx,BN_FLAG_NEGATIVE
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;    
    call OptBuf
    jmp sbnDone

sbnSubUse2:  
    push esi
    push edi
;      
    xchg esi,edi
    mov ecx,ds:[esi].bn_count
    mov edx,ds:[edi].bn_count
    mov esi,ds:[esi].bn_data
    call CopyBuf
;    
    mov esi,ds:[edi].bn_data
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoSub
;
    pop edi
    pop esi
    jnc sbnSubFixup2
;
    push edi
    mov edi,ds:[ebx].bn_data
    mov ecx,ds:[ebx].bn_count
    call DoNeg
    pop edi
;
    mov ax,ds:[esi].bn_flags
    mov dx,ds:[edi].bn_flags
    xor dx,BN_FLAG_NEGATIVE
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;    
    call OptBuf
    jmp sbnDone

sbnSubFixup2:
    mov ax,ds:[edi].bn_flags
    xor ax,BN_FLAG_NEGATIVE
    mov dx,ds:[esi].bn_flags
    and dx,NOT BN_FLAG_NEGATIVE
    or ax,dx
    mov ds:[ebx].bn_flags,ax
;    
    call OptBuf

sbnDone:    
    mov bx,[ebx].hh_handle
    clc
    jmp sbnEnd

sbnFail:
    xor bx,bx 
    stc   

sbnEnd:        
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret    
sub_bignum     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           MulBigNum
;
;           DESCRIPTION:    Multiply big num
;
;           PARAMETERS:     BX          Big num handle 1
;                           AX          Big num handle 2
;
;           RETURNS:        BX          Result big num handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mul_bignum_name    DB 'Mul Big Number',0

mul_bignum     PROC far
    push ebp
    sub esp,SIZE mul_struc
    mov ebp,esp
;    
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    mov ax,flat_sel
    mov es,ax    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    pop ax
    jc mnFail
;
    push ax
    mov esi,ebx
    mov eax,ds:[ebx].bn_count
    mov [ebp].mul_in_count1,eax
    mov eax,ds:[ebx].bn_data
    mov [ebp].mul_in_data1,eax
    pop bx
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc mnFail
;
    mov edi,ebx
    mov eax,ds:[ebx].bn_count
    mov [ebp].mul_in_count2,eax
    mov eax,ds:[ebx].bn_data
    mov [ebp].mul_in_data2,eax
;    
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
;
    mov eax,[ebp].mul_in_count1
    add eax,[ebp].mul_in_count2
    mov [ebp].mul_out_count,eax
;
    mov ecx,eax
    call RecreateBuf
;
    mov ax,ds:[esi].bn_flags
    or ax,ds:[edi].bn_flags
    and ax,NOT BN_FLAG_NEGATIVE
    mov ds:[ebx].bn_flags,ax
;
    mov ax,ds:[esi].bn_flags
    xor ax,ds:[edi].bn_flags
    and ax,BN_FLAG_NEGATIVE
    or ds:[ebx].bn_flags,ax
;    
    mov eax,ds:[ebx].bn_data
    mov [ebp].mul_out_data,eax
;    
    call DoMul
    call OptBuf
    mov bx,[ebx].hh_handle
    clc
    jmp mnDone

mnFail:
    xor bx,bx  
    stc  

mnDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
;
    add esp,SIZE mul_struc
    pop ebp
    ret
mul_bignum  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DivBigNum
;
;           DESCRIPTION:    Divide big num
;
;           PARAMETERS:     BX          Nominator num handle
;                           AX          Divisor num handle
;
;           RETURNS:        BX          Result big num handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

div_bignum_name    DB 'Div Big Number',0

div_bignum     PROC far
    push ebp
    sub esp,SIZE div_struc
    mov ebp,esp
;    
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    mov ax,BIGNUM_HANDLE
    DerefHandle
    pop ax
    jc dnFail
;
    mov esi,ebx
    push ax
    mov eax,ds:[ebx].bn_count
    mov [ebp].div_quot_count,eax    
    mov eax,ds:[ebx].bn_data
    mov [ebp].div_mod_data,eax
    pop bx
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc dnFail
;
    mov edi,ebx
    mov eax,ds:[ebx].bn_count
    mov [ebp].div_divisor_count,eax    
    mov eax,ds:[ebx].bn_data
    mov [ebp].div_divisor_data,eax
;
    mov eax,flat_sel
    mov ds,eax
;
    push esi
    mov esi,[ebp].div_divisor_data
    mov ecx,[ebp].div_divisor_count
    call GetBits
    pop esi
    or ecx,ecx
    jz dnInfinite
;    
    push esi
    push edi
;
    mov eax,[ebp].div_quot_count
    or eax,eax
    jnz dnNotZero
;
    inc eax
    mov [ebp].div_quot_count,eax    
    mov ecx,eax
    shl eax,2
    AllocateSmallLinear
;
    mov [ebp].div_mod_data,edx
    push es
    mov eax,flat_sel
    mov es,eax
    mov edi,edx
    xor eax,eax
    stos dword ptr es:[edi]
    pop es
    jmp dnCopyDone
    
dnNotZero:
    mov esi,[ebp].div_mod_data
    mov ecx,eax
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_mod_data,edx
    mov edi,edx

dnCopyNomLoop:
    mov eax,[esi]
    mov [edi],eax
    add esi,4
    add edi,4
    loop dnCopyNomLoop    

dnCopyDone:
    pop edi
    pop esi    
;
    mov eax,[ebp].div_quot_count
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_temp_quot_data,edx
;    
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
;
    mov ax,ds:[esi].bn_flags
    or ax,ds:[edi].bn_flags
    and ax,NOT BN_FLAG_NEGATIVE
    mov ds:[ebx].bn_flags,ax
;
    mov ax,ds:[esi].bn_flags
    xor ax,ds:[edi].bn_flags
    and ax,BN_FLAG_NEGATIVE
    or ds:[ebx].bn_flags,ax
;
    mov ecx,[ebp].div_quot_count
    call RecreateBuf
    mov eax,ds:[ebx].bn_data
    mov [ebp].div_quot_data,eax
;    
    push ds
    mov eax,flat_sel
    mov ds,eax
    call DoDiv
    pop ds
;
    call OptBuf    
;
    mov ecx,[ebp].div_quot_count
    shl ecx,2
    mov edx,[ebp].div_temp_quot_data
    FreeLinear
;    
    mov ecx,[ebp].div_quot_count
    shl ecx,2
    mov edx,[ebp].div_mod_data
    FreeLinear
;
    mov bx,[ebx].hh_handle
    clc
    jmp dnLeave

dnInfinite:    
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
;
    mov ax,ds:[esi].bn_flags
    or ax,ds:[edi].bn_flags
    and ax,NOT BN_FLAG_NEGATIVE
    mov ds:[ebx].bn_flags,ax
;
    mov ax,ds:[esi].bn_flags
    xor ax,ds:[edi].bn_flags
    and ax,BN_FLAG_NEGATIVE
    or ax,BN_FLAG_INFINITE
    or ds:[ebx].bn_flags,ax
    mov bx,[ebx].hh_handle
    clc
    jmp dnLeave

dnFail:
    xor bx,bx  
    stc  

dnLeave:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
;
    add esp,SIZE div_struc
    pop ebp
    ret
div_bignum  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ModBigNum
;
;           DESCRIPTION:    Modulo big num
;
;           PARAMETERS:     BX          Nominator num handle
;                           AX          Divisor num handle
;
;           RETURNS:        BX          Result big num handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mod_bignum_name    DB 'Mod Big Number',0

mod_bignum     PROC far
    push ebp
    sub esp,SIZE div_struc
    mov ebp,esp
;    
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    mov ax,BIGNUM_HANDLE
    DerefHandle
    pop ax
    jc mbnFail
;
    mov esi,ebx
    push ax
    mov eax,ds:[ebx].bn_count
    mov [ebp].div_quot_count,eax    
    mov eax,ds:[ebx].bn_data
    mov [ebp].div_mod_data,eax
    pop bx
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc mbnFail
;
    mov edi,ebx
    mov eax,ds:[ebx].bn_count
    mov [ebp].div_divisor_count,eax    
    mov eax,ds:[ebx].bn_data
    mov [ebp].div_divisor_data,eax
;
    mov eax,flat_sel
    mov ds,eax
;
    push esi
    mov esi,[ebp].div_divisor_data
    mov ecx,[ebp].div_divisor_count
    call GetBits
    pop esi
    or ecx,ecx
    jz mbnInfinite
;    
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
;    
    push esi
    push edi
;
    mov eax,[ebp].div_quot_count
    or eax,eax
    jnz mbnNotZero
;
    mov ecx,1
    mov [ebp].div_quot_count,ecx    
    call RecreateBuf
;
    push es
    mov eax,flat_sel
    mov es,eax
    mov eax,ds:[ebx].bn_data
    mov [ebp].div_mod_data,eax
    mov edi,eax
    xor eax,eax
    stos dword ptr es:[edi]
    pop es
    jmp mbnCopyDone
    
mbnNotZero:
    mov ecx,[ebp].div_quot_count
    mov esi,[ebp].div_mod_data
    call RecreateBuf
    mov eax,ds:[ebx].bn_data
    mov [ebp].div_mod_data,eax
    mov edi,eax
;
    push ds
    mov eax,flat_sel
    mov ds,eax

mbnCopyNomLoop:
    mov eax,[esi]
    mov [edi],eax
    add esi,4
    add edi,4
    loop mbnCopyNomLoop    
;
    pop ds

mbnCopyDone:
    pop edi
    pop esi    
;
    mov eax,[ebp].div_quot_count
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_temp_quot_data,edx
;
    mov eax,[ebp].div_quot_count
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_quot_data,edx
;
    mov ax,ds:[esi].bn_flags
    or ax,ds:[edi].bn_flags
    and ax,NOT BN_FLAG_NEGATIVE
    mov ds:[ebx].bn_flags,ax
;
    mov ax,ds:[esi].bn_flags
    xor ax,ds:[edi].bn_flags
    and ax,BN_FLAG_NEGATIVE
    or ds:[ebx].bn_flags,ax
;    
    push ds
    mov eax,flat_sel
    mov ds,eax
    call DoDiv
    pop ds
;
    call OptBuf    
;
    mov ecx,[ebp].div_quot_count
    shl ecx,2
    mov edx,[ebp].div_temp_quot_data
    FreeLinear
;    
    mov ecx,[ebp].div_quot_count
    shl ecx,2
    mov edx,[ebp].div_quot_data
    FreeLinear
;
    mov bx,[ebx].hh_handle
    clc
    jmp mbnLeave

mbnInfinite:    
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
;
    mov ax,ds:[esi].bn_flags
    or ax,ds:[edi].bn_flags
    and ax,NOT BN_FLAG_NEGATIVE
    mov ds:[ebx].bn_flags,ax
;
    mov ax,ds:[esi].bn_flags
    xor ax,ds:[edi].bn_flags
    and ax,BN_FLAG_NEGATIVE
    or ax,BN_FLAG_INFINITE
    or ds:[ebx].bn_flags,ax
    mov bx,[ebx].hh_handle
    clc
    jmp mbnLeave

mbnFail:
    xor bx,bx  
    stc  

mbnLeave:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
;
    add esp,SIZE div_struc
    pop ebp
    ret
mod_bignum  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           PowModBigNum
;
;           DESCRIPTION:    Power modulo big num (base ^ exp % mod)
;
;           PARAMETERS:     BX          Base
;                           AX          Exp
;                           DX          Mod
;
;           RETURNS:        BX          Result big num handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pow_mod_bignum_name    DB 'Power Modulo Big Number',0

pow_mod_bignum     PROC far
    push ebp
    sub esp,SIZE pow_mod_struc
    mov ebp,esp
;    
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    push ax
    mov ax,flat_sel
    mov es,ax    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    pop ax
    jc pmFail
;
    push ax
    mov eax,ds:[ebx].bn_count
    mov [ebp].pow_mod_base_count,eax    
    mov [ebp].div_quot_count,eax
    mov eax,ds:[ebx].bn_data
    mov [ebp].pow_mod_base_data,eax
;
    pop bx
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc pmFail
;
    mov eax,ds:[ebx].bn_count
    mov [ebp].pow_mod_exp_count,eax    
    mov eax,ds:[ebx].bn_data
    mov [ebp].pow_mod_exp_data,eax
;
    mov bx,dx
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc pmFail
;
    mov eax,ds:[ebx].bn_count
    mov [ebp].div_divisor_count,eax    
    mov eax,ds:[ebx].bn_data
    mov [ebp].div_divisor_data,eax        
;
    mov esi,[ebp].pow_mod_base_data
    mov eax,[ebp].pow_mod_base_count
    mov ecx,eax
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_mod_data,edx
    mov edi,edx

pmCopyBaseLoop:
    mov eax,es:[esi]
    mov es:[edi],eax
    add esi,4
    add edi,4
    loop pmCopyBaseLoop    
;
    mov eax,[ebp].pow_mod_base_count
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_temp_quot_data,edx
;
    mov eax,[ebp].pow_mod_base_count
    shl eax,2
    AllocateSmallLinear
    mov [ebp].div_quot_data,edx
;
    call DoDiv
;
    mov eax,[ebp].div_divisor_count
    add eax,eax
    mov [ebp].div_quot_count,eax
;    
    mov eax,[ebp].div_divisor_count
    mov ecx,eax
    shl eax,2
    AllocateSmallLinear
    mov [ebp].pow_mod_temp_data,edx
    mov edi,edx
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    mov ecx,[ebp].pow_mod_base_count
    cmp ecx,[ebp].div_divisor_count
    jbe pmCopyInitBase
;
    mov ecx,[ebp].div_divisor_count

pmCopyInitBase:    
    mov edi,edx    
    mov esi,[ebp].div_mod_data
    rep movs dword ptr es:[edi],es:[esi]
;
    mov eax,[ebp].div_divisor_count
    add eax,eax
    cmp eax,[ebp].pow_mod_base_count
    je pmBufInitOk
;
    mov ecx,[ebp].pow_mod_base_count
    shl ecx,2
    mov edx,[ebp].div_temp_quot_data
    FreeLinear
;    
    mov eax,[ebp].div_divisor_count
    shl eax,3
    AllocateSmallLinear
    mov [ebp].div_temp_quot_data,edx
;
    mov ecx,[ebp].pow_mod_base_count
    shl ecx,2
    mov edx,[ebp].div_quot_data
    FreeLinear
;
    mov eax,[ebp].div_divisor_count
    shl eax,3
    AllocateSmallLinear
    mov [ebp].div_quot_data,edx

pmBufInitOk:
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
;
    mov ecx,[ebp].div_divisor_count
    mov [ebp].pow_mod_res_count,ecx
    call RecreateBuf
    mov eax,ds:[ebx].bn_data
    mov [ebp].pow_mod_res_data,eax
;
    mov edi,eax
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov eax,1
    mov edi,[ebp].pow_mod_res_data
    mov es:[edi],eax
;
    mov eax,[ebp].pow_mod_base_count
    shl eax,2
    mov edx,[ebp].div_mod_data
    FreeLinear
;
    mov eax,[ebp].div_divisor_count
    shl eax,3
    AllocateSmallLinear
    mov [ebp].div_mod_data,edx
;
    mov esi,[ebp].pow_mod_exp_data
    mov ecx,[ebp].pow_mod_exp_count
    call GetBits
    xor edx,edx
    or ecx,ecx
    jz pmCalcDone

pmCalcLoop:
    push ecx
    push edx
;
    mov esi,[ebp].pow_mod_exp_data
    bt es:[esi],edx
    jnc pmCalcNext
;    
    mov esi,[ebp].pow_mod_res_data
    mov edi,[ebp].pow_mod_temp_data
    mov edx,[ebp].div_mod_data
    mov ecx,[ebp].div_divisor_count
    push ebp
    sub esp,SIZE mul_struc
    mov ebp,esp
    mov [ebp].mul_in_count1,ecx
    mov [ebp].mul_in_data1,esi
    mov [ebp].mul_in_count2,ecx
    mov [ebp].mul_in_data2,edi
    add ecx,ecx
    mov [ebp].mul_out_count,ecx
    mov [ebp].mul_out_data,edx
    call DoMul
    add esp,SIZE mul_struc
    pop ebp
;    
    call DoDiv
;
    mov ecx,[ebp].div_divisor_count
    mov esi,[ebp].div_mod_data
    mov edi,[ebp].pow_mod_res_data
    rep movs dword ptr es:[edi],es:[esi]

pmCalcNext:
    mov esi,[ebp].pow_mod_temp_data
    mov edi,[ebp].div_mod_data
    mov ecx,[ebp].div_divisor_count
    push ebp
    sub esp,SIZE mul_struc
    mov ebp,esp
    mov [ebp].mul_in_count1,ecx
    mov [ebp].mul_in_data1,esi
    mov [ebp].mul_in_count2,ecx
    mov [ebp].mul_in_data2,esi
    add ecx,ecx
    mov [ebp].mul_out_count,ecx
    mov [ebp].mul_out_data,edi
    call DoMul
    add esp,SIZE mul_struc
    pop ebp
;    
    call DoDiv
;
    mov ecx,[ebp].div_divisor_count
    mov esi,[ebp].div_mod_data
    mov edi,[ebp].pow_mod_temp_data
    rep movs dword ptr es:[edi],es:[esi]
;
    pop edx
    pop ecx
    inc edx
    sub ecx,1
    jnz pmCalcLoop   

pmCalcDone:
    mov ecx,[ebp].div_divisor_count
    shl ecx,3
    mov edx,[ebp].div_temp_quot_data
    FreeLinear
;
    mov ecx,[ebp].div_divisor_count
    shl ecx,3
    mov edx,[ebp].div_quot_data
    FreeLinear
;
    mov ecx,[ebp].div_divisor_count
    shl ecx,3
    mov edx,[ebp].pow_mod_temp_data
    FreeLinear
;
    mov ecx,[ebp].div_divisor_count
    shl ecx,3
    mov edx,[ebp].div_mod_data
    FreeLinear


;
    call OptBuf    
    mov bx,[ebx].hh_handle
    jmp pmLeave

pmFail:
    xor bx,bx  
    stc  

pmLeave:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
;
    add esp,SIZE pow_mod_struc
    pop ebp
    ret
pow_mod_bignum  ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateRandomBigNum
;
;           DESCRIPTION:    Create random big number
;
;           PARAMETERS:     ECX         Number of bits
;
;           RETURNS:        BX          Big number handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_random_bignum_name    DB 'Create Random Big Number',0

create_random_bignum     PROC far
    push ds
    push es
    push eax
    push ecx
;
    mov ax,flat_sel
    mov es,ax
;    
    push ecx
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
    pop ecx
    or ecx,ecx
    jz crbDone
;
    mov edx,ecx
    dec ecx
    shr ecx,5
    inc ecx
    call RecreateBuf
;    
    mov edi,ds:[ebx].bn_data

crbLoop:    
    GetRandom
    sub ecx,1
    jz crbPartial

crbFull:
    mov es:[edi],eax
    add edi,4
    sub edx,32
    jmp crbLoop

crbPartial:
    and dl,1Fh
    jz crbAll
;
    stc
    rcr eax,1
    mov cl,32
    sub cl,dl
    shr eax,cl
    mov es:[edi],eax
    jmp crbDone

crbAll:
    stc
    rcr eax,1
    mov es:[edi],eax

crbDone:    
    mov bx,[ebx].hh_handle
    clc
;
    pop ecx
    pop eax
    pop es
    pop ds
    ret
create_random_bignum     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateRandomOddBigNum
;
;           DESCRIPTION:    Create random odd big number
;
;           PARAMETERS:     CX          Number of bits
;
;           RETURNS:        BX          Big number handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_random_odd_bignum_name    DB 'Create Random Odd Big Number',0

create_random_odd_bignum     PROC far
    push ds
    push es
    push eax
    push ecx
;
    mov ax,flat_sel
    mov es,ax
;    
    push ecx
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
    pop ecx
    or ecx,ecx
    stc
    jz crobEnd
;
    mov edx,ecx
    dec ecx
    shr ecx,5
    inc ecx
    call RecreateBuf
;    
    mov edi,ds:[ebx].bn_data

crobLoop:    
    GetRandom
    sub ecx,1
    jz crobPartial

crobFull:
    mov es:[edi],eax
    add edi,4
    sub edx,32
    jmp crobLoop

crobPartial:
    and dl,1Fh
    jz crobAll
;
    stc
    rcr eax,1
    mov cl,32
    sub cl,dl
    shr eax,cl
    mov es:[edi],eax
    jmp crobDone

crobAll:
    stc
    rcr eax,1
    mov es:[edi],eax

crobDone:    
    mov edi,ds:[ebx].bn_data
    or byte ptr es:[edi],1
;
    mov bx,[ebx].hh_handle
    clc

crobEnd:
    pop ecx
    pop eax
    pop es
    pop ds
    ret
create_random_odd_bignum     ENDP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FactorPow2BigNum
;
;           DESCRIPTION:    Express number as d x 2 ^ r
;
;           PARAMETERS:     BX          Number to factor
;
;           RETURNS:        BX          Result big num handle (d)
;                           ECX         r
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

factor_pow2_bignum_name    DB 'Factor Power 2 Big Number',0

factor_pow2_bignum     PROC far
    push ds
    push es
    push eax
    push edx
    push esi
    push edi
;
    push ax
    mov ax,flat_sel
    mov es,ax    
    mov ax,BIGNUM_HANDLE
    DerefHandle
    pop ax
    jc fp2Done
;
    mov ecx,ds:[ebx].bn_count
    mov esi,ds:[ebx].bn_data
;
    push ecx
    mov cx,SIZE bignum_handle_seg
    AllocateHandle
    mov ds:[ebx].bn_count,0
    mov ds:[ebx].bn_data,0
    mov ds:[ebx].bn_flags,0
    mov [ebx].hh_sign,BIGNUM_HANDLE
    pop ecx
;
    or ecx,ecx
    jz fp2Zero
;
    call RecreateBuf
;
    mov edx,ds:[ebx].bn_count
    mov edi,ds:[ebx].bn_data
    mov ebx,1
    call CopyShiftRight

fp2Zero:
    xor ecx,ecx
    mov bx,[ebx].hh_handle
    clc

fp2Done:
    pop edi
    pop esi
    pop edx
    pop eax
    pop es
    pop ds
    ret
factor_pow2_bignum	ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    Delete syslog handle
;
;           PARAMETERS:     BX          Syslog handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle     PROC far
    push ds
    push ebx
    push ecx
    push edx
;
    mov ax,BIGNUM_HANDLE
    DerefHandle
    jc dbnDone
;
    mov ecx,ds:[ebx].bn_count
    or ecx,ecx
    jz dbnFree
;
    shl ecx,2
    mov edx,ds:[ebx].bn_data
    FreeLinear    

dbnFree:       
    FreeHandle
    clc

dbnDone:
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
delete_handle     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov ax,BIGNUM_HANDLE
    mov edi,OFFSET delete_handle
    RegisterHandle
;
    mov esi,OFFSET create_bignum
    mov edi,OFFSET create_bignum_name
    xor dx,dx
    mov ax,create_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET delete_bignum
    mov edi,OFFSET delete_bignum_name
    xor dx,dx
    mov ax,delete_bignum_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET load_signed_bignum16
    mov esi,OFFSET load_signed_bignum32
    mov edi,OFFSET load_signed_bignum_name
    mov dx,virt_es_in
    mov ax,load_signed_bignum_nr
    RegisterUserGate
;
    mov ebx,OFFSET load_unsigned_bignum16
    mov esi,OFFSET load_unsigned_bignum32
    mov edi,OFFSET load_unsigned_bignum_name
    mov dx,virt_es_in
    mov ax,load_unsigned_bignum_nr
    RegisterUserGate
;
    mov ebx,OFFSET save_signed_bignum16
    mov esi,OFFSET save_signed_bignum32
    mov edi,OFFSET save_signed_bignum_name
    mov dx,virt_es_in
    mov ax,save_signed_bignum_nr
    RegisterUserGate
;
    mov ebx,OFFSET save_unsigned_bignum16
    mov esi,OFFSET save_unsigned_bignum32
    mov edi,OFFSET save_unsigned_bignum_name
    mov dx,virt_es_in
    mov ax,save_unsigned_bignum_nr
    RegisterUserGate
;
    mov ebx,OFFSET load_dec_str_bignum16
    mov esi,OFFSET load_dec_str_bignum32
    mov edi,OFFSET load_dec_str_bignum_name
    mov dx,virt_es_in
    mov ax,load_dec_str_bignum_nr
    RegisterUserGate
;
    mov ebx,OFFSET load_hex_str_bignum16
    mov esi,OFFSET load_hex_str_bignum32
    mov edi,OFFSET load_hex_str_bignum_name
    mov dx,virt_es_in
    mov ax,load_hex_str_bignum_nr
    RegisterUserGate
;
    mov esi,OFFSET add_bignum
    mov edi,OFFSET add_bignum_name
    xor dx,dx
    mov ax,add_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET sub_bignum
    mov edi,OFFSET sub_bignum_name
    xor dx,dx
    mov ax,sub_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET mul_bignum
    mov edi,OFFSET mul_bignum_name
    xor dx,dx
    mov ax,mul_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET div_bignum
    mov edi,OFFSET div_bignum_name
    xor dx,dx
    mov ax,div_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET mod_bignum
    mov edi,OFFSET mod_bignum_name
    xor dx,dx
    mov ax,mod_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET pow_mod_bignum
    mov edi,OFFSET pow_mod_bignum_name
    xor dx,dx
    mov ax,pow_mod_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_dec_str_size_bignum
    mov edi,OFFSET get_dec_str_size_bignum_name
    xor dx,dx
    mov ax,get_dec_str_size_bignum_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET save_dec_str_bignum16
    mov esi,OFFSET save_dec_str_bignum32
    mov edi,OFFSET save_dec_str_bignum_name
    mov dx,virt_es_in
    mov ax,save_dec_str_bignum_nr
    RegisterUserGate
;
    mov ebx,OFFSET save_hex_str_bignum16
    mov esi,OFFSET save_hex_str_bignum32
    mov edi,OFFSET save_hex_str_bignum_name
    mov dx,virt_es_in
    mov ax,save_hex_str_bignum_nr
    RegisterUserGate
;
    mov esi,OFFSET get_hex_str_size_bignum
    mov edi,OFFSET get_hex_str_size_bignum_name
    xor dx,dx
    mov ax,get_hex_str_size_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_random_bignum
    mov edi,OFFSET create_random_bignum_name
    xor dx,dx
    mov ax,create_random_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_random_odd_bignum
    mov edi,OFFSET create_random_odd_bignum_name
    xor dx,dx
    mov ax,create_random_odd_bignum_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET factor_pow2_bignum
    mov edi,OFFSET factor_pow2_bignum_name
    xor dx,dx
    mov ax,factor_pow2_bignum_nr
    RegisterBimodalUserGate
;
    ret
init    ENDP
    

code    ENDS

    END init
