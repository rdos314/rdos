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
; Lowtime.ASM
; Low-level time & date manipulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                
        NAME  lowtime

        .386
        .model flat

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

        .code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Win32SwapShort
;
;               description:    Byte reverse a short int
;
;               returns:                Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _Win32SwapShort@4

_Win32SwapShort@4       Proc
        push ebp
        mov ebp,esp
        mov ax,[ebp+8]
        xchg al,ah
        pop ebp
        ret 4
_Win32SwapShort@4       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Win32SwapLong
;
;               description:    Byte reverse a long int
;
;               returns:                Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _Win32SwapLong@4

_Win32SwapLong@4        Proc
        push ebp
        mov ebp,esp
;       
    mov eax,[ebp+8]
        xchg al,ah
        rol eax,16
        xchg al,ah
;
        pop ebp
        ret 4
_Win32SwapLong@4        Endp

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

days_in_month   PROC
        push ebx
        movzx ebx,ch
        add ebx,OFFSET day_tab
        mov al,byte ptr cs:[ebx]
        cmp al,28
        jnz days_in_month_ok
        test dx,3
        jnz days_in_month_ok
        mov al,29
days_in_month_ok:
        pop ebx
        ret
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

adjust_time     PROC
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
        call days_in_month
        add cl,al
        jmp adjust_date_loop
adjust_day_pos:
        call days_in_month
        cmp cl,al
        jc adjust_day_ok
        jz adjust_day_ok
        sub cl,al
        inc ch
        jmp adjust_date_loop
adjust_day_ok:
        ret
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

passed_days     PROC
        push ebx
        movzx ebx,ch
        add bx,bx
        add ebx,OFFSET passed_days_tab
        mov ax,word ptr cs:[ebx]
        cmp ch,2
        jc passed_days_add_day
        test dx,3
        jnz passed_days_add_day
        inc ax
passed_days_add_day:
        add al,cl
        adc ah,0
        dec ax
        pop ebx
        ret
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

bin_minute      DD 04444444h
bin_second      DD 00123457h

time_to_binary  PROC
        push esi
        call adjust_time
        push ax
        push dx
        mov eax,365
        imul dx
        push dx
        push ax
        pop esi
        pop dx
        call passed_days
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
        ret
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

binary_to_time  PROC
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
        push ebx
        mov ch,1
        mov ebx,OFFSET dt1
binary_to_time_date_loop:
        mov cl,cs:[ebx]
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
        pop ebx
        pop eax
        push dx
        mov edx,60
        mul edx
        mov bl,dl
        mov dl,60
        mul edx
        mov ah,dl
        pop dx
        ret
binary_to_time  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Win32TicsToRecord
;
;               description:    Convert tics to record form
;
;               PARAMETERS:             int MSB
;                                               int LSB
;                                               int *year
;                                               int *month
;                                               int *day
;                                               int *hour
;                                               int *min
;                                               int *sec
;                                               int *milli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _Win32TicsToRecord@36

ctMSB           EQU 8
ctLSB           EQU 12
ctYear          EQU 16
ctMonth         EQU 20
ctDay           EQU 24
ctHour          EQU 28
ctMin           EQU 32
ctSec           EQU 36
ctMilli         EQU 40

_Win32TicsToRecord@36   Proc
        push ebp
        mov ebp,esp
        pushad
;
        mov edx,[ebp+ctMSB]
        mov eax,[ebp+ctLSB]
        add eax,1193 / 2
        adc edx,0
        call binary_to_time
        push edx
;
        mov esi,[ebp+ctYear]
        movzx edx,dx
        mov [esi],edx
;
        mov esi,[ebp+ctMonth]
        movzx edx,ch
        mov [esi],edx
;
        mov esi,[ebp+ctDay]
        movzx edx,cl
        mov [esi],edx
;
        mov esi,[ebp+ctHour]
        movzx edx,bh
        mov [esi],edx
;
        mov esi,[ebp+ctMin]
        movzx edx,bl
        mov [esi],edx
;
        mov esi,[ebp+ctSec]
        movzx edx,ah
        mov [esi],edx
;
        pop edx
        call time_to_binary
        mov ebx,eax
        mov eax,[ebp+ctLSB]
        sub eax,ebx
        xor edx,edx
        mov ebx,1192
        div ebx
        mov esi,[ebp+ctMilli]
        cmp ax,1000
        jne rttrSaveMs
;
        dec ax

rttrSaveMs:     
        movzx eax,ax
        mov [esi],eax
;
        popad
        pop ebp
        ret 36
_Win32TicsToRecord@36   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Win32RecordToTics
;
;               description:    Convert record form to tics
;
;               PARAMETERS:             int *MSB
;                                               int *LSB
;                                               int year
;                                               int month
;                                               int day
;                                               int hour
;                                               int min
;                                               int sec
;                                               int milli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _Win32RecordToTics@36

rtMSB           EQU 8
rtLSB           EQU 12
rtYear          EQU 16
rtMonth         EQU 20
rtDay           EQU 24
rtHour          EQU 28
rtMin           EQU 32
rtSec           EQU 36
rtMilli         EQU 40

_Win32RecordToTics@36   Proc
        push ebp
        mov ebp,esp
        pushad
;
        mov eax,[ebp+rtMilli]
        mov edx,1192
        mul edx
        push eax
        mov dx,[ebp+rtYear]
        mov ch,[ebp+rtMonth]
        mov cl,[ebp+rtDay]
        mov bh,[ebp+rtHour]
        mov bl,[ebp+rtMin]
        mov ah,[ebp+rtSec]
        call time_to_binary
        pop ebx
        add eax,ebx
        adc edx,0
;
        mov esi,[ebp+rtMSB]
        mov [esi],edx
;
        mov esi,[ebp+rtLSB]
        mov [esi],eax
;
        popad
        pop ebp
        ret 36
_Win32RecordToTics@36   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Win32GetTics
;
;               description:    gets system time
;
;               parameters:             windows tics
;                       MSB of tics
;                                               LSB of tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _Win32GetTics@12

rgtTick EQU 8
rgtMSB  EQU 12
rgtLSB  EQU 16

_Win32GetTics@12        Proc
        push ebp
        mov ebp,esp
        push edx
        push esi
;
    mov eax,[ebp+rgtTick]
    mov edx,1079
    mul edx
        mov esi,[ebp+rgtMSB]
        mov [esi],edx
        mov esi,[ebp+rgtLSB]
        mov [esi],eax
;
        pop esi
        pop edx
        pop ebp
        ret 12
_Win32GetTics@12        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Win32AddTics
;
;               description:    add tics to time
;
;               PARAMETERS:             long *msb
;                                               long *lsb
;                                               long tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _Win32AddTics@12

_Win32AddTics@12        Proc
        push ebp
        mov ebp,esp
        push ebx
;
        mov eax,[ebp+16]
        mov ebx,[ebp+12]
        add [ebx],eax
        mov ebx,[ebp+8]
        adc dword ptr [ebx],0   
;
        pop ebx
        pop ebp
        ret 12
_Win32AddTics@12        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Win32AddMilli
;
;               description:    add milli seconds
;
;               PARAMETERS:             long *msb
;                                               long *lsb
;                                               long milli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _Win32AddMilli@12

_Win32AddMilli@12       Proc
        push ebp
        mov ebp,esp
        push ebx
;
        mov eax,[ebp+16]
        mov edx,1193
        mul edx
        mov ebx,[ebp+12]
        add [ebx],eax
        mov ebx,[ebp+8]
        adc [ebx],edx
;
        pop ebx
        pop ebp
        ret 12
_Win32AddMilli@12       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Win32AddSec
;
;               description:    add seconds
;
;               PARAMETERS:             long *msb
;                                               long *lsb
;                                               long sec
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _Win32AddSec@12

_Win32AddSec@12 Proc
        push ebp
        mov ebp,esp
        push ebx
;
        mov eax,[ebp+16]
        mov edx,1193000
        mul edx
        mov ebx,[ebp+12]
        add [ebx],eax
        mov ebx,[ebp+8]
        adc [ebx],edx
;
        pop ebx
        pop ebp
        ret 12
_Win32AddSec@12 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Win32AddMin
;
;               description:    add minute
;
;               PARAMETERS:             long *msb
;                                               long *lsb
;                                               long min
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _Win32AddMin@12

_Win32AddMin@12 Proc
        push ebp
        mov ebp,esp
        push ebx
;
        mov eax,[ebp+16]
        mov edx,1193046*60
        mul edx
        mov ebx,[ebp+12]
        add [ebx],eax
        mov ebx,[ebp+8]
        adc [ebx],edx
;
        pop ebx
        pop ebp
        ret 12
_Win32AddMin@12 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Win32AddHour
;
;               description:    add hour
;
;               PARAMETERS:             long *msb
;                                               long *lsb
;                                               long hour
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _Win32AddHour@12

_Win32AddHour@12        Proc
        push ebp
        mov ebp,esp
        push ebx
;
        mov eax,[ebp+16]
        mov ebx,[ebp+8]
        add [ebx],eax
;
        pop ebx
        pop ebp
        ret 12
_Win32AddHour@12        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Win32AddDay
;
;               description:    add days
;
;               PARAMETERS:             long *msb
;                                               long *lsb
;                                               long day
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public _Win32AddDay@12

_Win32AddDay@12 Proc
        push ebp
        mov ebp,esp
        push ebx
;
        mov eax,[ebp+16]
        mov edx,24
        mul edx
        mov ebx,[ebp+8]
        add [ebx],eax
;
        pop ebx
        pop ebp
        ret 12
_Win32AddDay@12 Endp


        END
