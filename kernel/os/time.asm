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
; TIME.ASM
; Time conversion module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.inc

        .386p

code    SEGMENT byte public use16 'CODE'

        assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   DAYS_IN_MONTH
;
;               DESCRIPTION:    Calculate days in month
;
;               PARAMETERS:             DX              YEAR
;                                               CH              MONTH
;                                               AL              DAYS IN MONTH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

day_tab:
dt0             DB 31
dt1             DB 31
dt2             DB 28
dt3             DB 31
dt4             DB 30
dt5             DB 31
dt6             DB 30
dt7             DB 31
dt8             DB 31
dt9             DB 30
dt10    DB 31
dt11    DB 30
dt12    DB 31

days_in_month_name                      DB 'Days in month',0

days_in_month   PROC far
        push bx
        mov bl,ch
        xor bh,bh
        mov al,byte ptr cs:[bx].day_tab
        cmp al,28
        jnz days_in_month_ok
        test dx,3
        jnz days_in_month_ok
        mov al,29
days_in_month_ok:
        pop bx
        retf32
days_in_month   ENDP    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   ADJUST_TIME
;
;               DESCRIPTION:    Adjust time to normal form
;
;               PARAMETERS:             DX              YEAR
;                                               CH              MONTH
;                                               CL              DAY
;                                               BH              HOUR
;                                               BL              MINUTE
;                                               AH              SECONDS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

adjust_time_name                        DB 'Adjust time',0

adjust_time     PROC far
adjust_second_loop:
        test ah,80h
        jz adjust_second_pos
        add ah,60
        dec bl
        jmp adjust_second_loop
adjust_second_pos:
        cmp ah,60
        jc adjust_minute_loop
        sub ah,60
        inc bl
        jmp adjust_second_pos
adjust_minute_loop:
        test bl,80h
        jz adjust_minute_pos
        add bl,60
        dec bh
        jmp adjust_minute_loop
adjust_minute_pos:
        cmp bl,60
        jc adjust_hour_loop
        sub bl,60
        inc bh
        jmp adjust_minute_pos
adjust_hour_loop:
        test bh,80h
        jz adjust_hour_pos
        add bh,24
        dec cl
        jmp adjust_hour_loop
adjust_hour_pos:
        cmp bh,24
        jc adjust_date_loop
        sub bh,24
        inc cl
        jmp adjust_hour_pos
adjust_date_loop:
        test ch,80h
        jz adjust_month_pos
        add ch,12
        dec dx
        jmp adjust_date_loop
adjust_month_pos:
        cmp ch,12
        jc adjust_month_ok
        jz adjust_month_ok
        sub ch,12
        inc dx
        jmp adjust_month_pos
adjust_month_ok:
        or cl,cl
        jz adjust_day_neg
        test cl,80h
        jz adjust_day_pos
adjust_day_neg:
        dec ch
        DaysInMonth
        add cl,al
        jmp adjust_date_loop
adjust_day_pos:
        DaysInMonth
        cmp cl,al
        jc adjust_day_ok
        jz adjust_day_ok
        sub cl,al
        inc ch
        jmp adjust_date_loop
adjust_day_ok:
        retf32
adjust_time     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   PASSED_DAYS
;
;               DESCRIPTION:    Calculate passed days in year
;
;               PARAMETERS:             DX              YEAR
;                                               CH              MONTH
;                                               CL              DAY
;                                               AX              ANTAL DAGAR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

passed_days_tab:
pd0             DW 0
pd1             DW 0
pd2             DW 31
pd3             DW 59
pd4             DW 90
pd5             DW 120
pd6             DW 151
pd7             DW 181
pd8             DW 212
pd9             DW 243
pd10    DW 273
pd11    DW 304
pd12    DW 334  

passed_days_name                        DB 'Passed days',0

passed_days     PROC far
        push bx
        xor bh,bh
        mov bl,ch
        add bx,bx
        mov ax,word ptr cs:[bx].passed_days_tab
        cmp ch,2
        jbe passed_days_add_day
        test dx,3
        jnz passed_days_add_day
        inc ax
passed_days_add_day:
        add al,cl
        adc ah,0
        dec ax
        pop bx
        retf32
passed_days     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   TIME_TO_BINARY
;
;               DESCRIPTION:    Component to binary conversion
;
;               PARAMETERS:             DX              YEAR
;                                               CH              MONTH
;                                               CL              DAY
;                                               BH              HOUR
;                                               BL              MINUTE
;                                               AH              SECONDS
;
;               RETURNS:                EDX:EAX BINARY TIME
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

time_to_binary_name                     DB 'Time to binary',0

bin_minute      DD 04444444h
bin_second      DD 00123457h

time_to_binary  PROC far
        push esi
        AdjustTime
        push ax
        push dx
        mov eax,365
        imul dx
        push dx
        push ax
        pop esi
        pop dx
        PassedDays
        dec dx
        shr dx,2
        inc dx
        add ax,dx
        add eax,esi
        mov edx,24
        imul edx
        mov dl,bh
        add eax,edx
        mov esi,eax
        xor eax,eax
        mov al,bl
        mul cs:bin_minute
        pop dx
        push eax
        xor eax,eax
        mov al,dh
        mul cs:bin_second
        pop edx
        add eax,edx
        mov edx,esi
        pop esi
        retf32
time_to_binary  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   BINARY_TO_TIME
;
;               DESCRIPTION:    Binary to component conversion
;
;               PARAMETERS:             EDX:EAX         BINARY TIME
;
;               RETURNS:                DX              YEAR
;                                               CH              MONTH
;                                               CL              DAY
;                                               BH              HOUR
;                                               BL              MINUTE
;                                               AH              SECONDS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

binary_to_time_name                     DB 'Binary to time',0

binary_to_time  PROC far
        push eax
        mov eax,edx
        xor edx,edx
        mov ecx,24
        div ecx
        mov bh,dl
        xor edx,edx
        mov ecx,365
        div ecx
        mov cx,ax
        dec ax
        shr ax,2
        inc ax
        sub dx,ax
        mov ax,cx
binary_to_time_adjust_days:
        test dx,8000h
        jz binary_to_time_valid_days
        add dx,365
        dec ax
        test ax,3
        jnz binary_to_time_adjust_days
        inc dx
        jmp binary_to_time_adjust_days
binary_to_time_valid_days:
        xchg ax,dx
        push bx
        mov ch,1
        mov bx,OFFSET dt1
binary_to_time_date_loop:
        mov cl,cs:[bx]
        cmp ch,2
        jnz binary_to_time_date_test
        test dx,3
        jnz binary_to_time_date_test
        inc cl
binary_to_time_date_test:
        sub al,cl
        sbb ah,0
        jc binary_to_time_date_ok
        inc ch
        inc bx
        jmp binary_to_time_date_loop
binary_to_time_date_ok:
        add cl,al
        inc cl
        pop bx
        pop eax
        push dx
        mov edx,60
        mul edx
        mov bl,dl
        mov dl,60
        mul edx
        mov ah,dl
        pop dx
        retf32
binary_to_time  ENDP

    public init_time
    
init_time       PROC near
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov esi,OFFSET days_in_month
        mov edi,OFFSET days_in_month_name
        xor dx,dx
        mov ax,days_in_month_nr
        RegisterBimodalUserGate
;
        mov esi,OFFSET adjust_time
        mov edi,OFFSET adjust_time_name
        xor dx,dx
        mov ax,adjust_time_nr
        RegisterBimodalUserGate
;
        mov esi,OFFSET passed_days
        mov edi,OFFSET passed_days_name
        xor dx,dx
        mov ax,passed_days_nr
        RegisterBimodalUserGate
;
        mov esi,OFFSET time_to_binary
        mov edi,OFFSET time_to_binary_name
        xor dx,dx
        mov ax,time_to_binary_nr
        RegisterBimodalUserGate
;
        mov esi,OFFSET binary_to_time
        mov edi,OFFSET binary_to_time_name
        xor dx,dx
        mov ax,binary_to_time_nr
        RegisterBimodalUserGate
;
        ret
init_time       ENDP

code    ENDS

    END
