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
; EMSTRING.ASM
; String functions for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        .386p

include ..\os.def
include ..\os.inc
include emulate.inc
include emcom.inc
include emmem.inc

SourceAds       MACRO
        local source32
        local done

        test byte ptr [bp].em_flags,a32
        jnz source32
;
        call MemSi
        jmp done

source32:
        call MemEsi

done:
                                ENDM

SourceByte      MACRO
        local source32
        local up16
        local done
        local up32

        push ax
        test byte ptr [bp].em_flags,a32
        jnz source32
;
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up16
;
        dec word ptr [bp].reg_esi
        jmp done

up16:
        inc word ptr [bp].reg_esi
        jmp done

source32:
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up32
;
        dec [bp].reg_esi
        jmp done

up32:
        inc [bp].reg_esi

done:
        pop ax
                                ENDM

SourceWord      MACRO
        local source32
        local up16
        local up32
        local done

        push ax
        test byte ptr [bp].em_flags,a32
        jnz source32
;
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up16
;
        sub word ptr [bp].reg_esi,2
        jmp done

up16:
        add word ptr [bp].reg_esi,2
        jmp done

source32:
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up32
;
        sub [bp].reg_esi,2
        jmp done

up32:
        add [bp].reg_esi,2

done:
        pop ax
                        ENDM


SourceDword     MACRO
        local source32
        local up16
        local up32
        local done

        push ax
        test byte ptr [bp].em_flags,a32
        jnz source32
;
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up16
;
        sub word ptr [bp].reg_esi,4
        jmp done

up16:
        add word ptr [bp].reg_esi,4
        jmp done

source32:
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up32
;
        sub [bp].reg_esi,4
        jmp done

up32:
        add [bp].reg_esi,4

done:
        pop ax
                ENDM

DestAds MACRO
        local dest32
        local done

        test byte ptr [bp].em_flags,a32
        jnz dest32
;
        mov si,OFFSET reg_es
        movzx ebx,word ptr [bp].reg_edi
        jmp done

dest32:
        mov si,OFFSET reg_es
        mov ebx,[bp].reg_edi

done:
                                ENDM

DestByte        MACRO
        local dest32
        local up16
        local done
        local up32

        push ax
        test byte ptr [bp].em_flags,a32
        jnz dest32
;
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up16
;
        dec word ptr [bp].reg_edi
        jmp done

up16:
        inc word ptr [bp].reg_edi
        jmp done

dest32:
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up32
;
        dec [bp].reg_edi
        jmp done

up32:
        inc [bp].reg_edi

done:
        pop ax
                                ENDM

DestWord        MACRO
        local dest32
        local up16
        local done
        local up32

        push ax
        test byte ptr [bp].em_flags,a32
        jnz dest32
;
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up16
;
        sub word ptr [bp].reg_edi,2
        jmp done

up16:
        add word ptr [bp].reg_edi,2
        jmp done

dest32:
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up32
;
        sub [bp].reg_edi,2
        jmp done

up32:
        add [bp].reg_edi,2

done:
        pop ax
                                ENDM

DestDword       MACRO
        local dest32
        local up16
        local done
        local up32

        push ax
        test byte ptr [bp].em_flags,a32
        jnz dest32
;
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up16
;
        sub word ptr [bp].reg_edi,4
        jmp done

up16:
        add word ptr [bp].reg_edi,4
        jmp done

dest32:
        mov al,byte ptr [bp+1].reg_eflags
        test al,4
        jz up32
;
        sub [bp].reg_edi,4
        jmp done

up32:
        add [bp].reg_edi,4

done:
                                ENDM

DecCount        MACRO
        local count32
        local done

        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jz done
;
        test byte ptr [bp].em_flags,a32
        jnz count32
;
        sub word ptr [bp].reg_ecx,1
        jmp done

count32:
        sub dword ptr [bp].reg_ecx,1

done:
                ENDM

CheckDone       MACRO
        local count32
        local done

        test byte ptr [bp].em_flags,a32
        jnz count32
;
        cmp word ptr [bp].reg_ecx,0
        jmp done

count32:
        cmp dword ptr [bp].reg_ecx,0

done:
                ENDM

CheckFlags      MACRO
        local check_repz
        local check_repnz
        local done

        test byte ptr [bp].em_flags,rep_z
        je check_repz

check_repnz:
        mov dl,byte ptr [bp].reg_eflags
        and dl,40h
        jmp done

check_repz:
        mov dl,byte ptr [bp].reg_eflags
        not dl
        and dl,40h

done:
                ENDM

code    SEGMENT byte public use16 'CODE'

        assume cs:code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmLodsb
;
;               DESCRIPTION:    EMULATE lodsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLodsb

EmLodsb Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepLodsb
;
        SourceAds
        call ReadByte
        mov byte ptr [bp].reg_eax,al
        SourceByte
        ret

RepLodsb:
        CheckDone
        jnz RepLodsbDo
        ret

RepLodsbDo:
        SourceAds
        call ReadByte
        mov byte ptr [bp].reg_eax,al
        SourceByte
        DecCount
        jnz RepLodsbMore
        ret

RepLodsbMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmLodsb Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmLodsw / EmLodsd
;
;               DESCRIPTION:    EMULATE lodsw / lodsd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmLodsw

EmLodsw Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepLodsw
;
        test byte ptr [bp].em_flags,d32
        jnz EmLodsd
;
        SourceAds
        call ReadWord
        mov word ptr [bp].reg_eax,ax
        SourceWord
        ret

EmLodsd:
        SourceAds
        call ReadDword
        mov [bp].reg_eax,eax
        SourceDword
        ret

RepLodsw:
        CheckDone
        jnz RepLodswDo
        ret

RepLodswDo:
        test byte ptr [bp].em_flags,d32
        jnz RepLodsd
;
        SourceAds
        call ReadWord
        mov word ptr [bp].reg_eax,ax
        SourceWord
        DecCount
        jnz RepLodswMore
        ret

RepLodsd:
        SourceAds
        call ReadDword
        mov [bp].reg_eax,eax
        SourceDword
        DecCount
        jnz RepLodswMore
        ret

RepLodswMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmLodsw Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmStosb
;
;               DESCRIPTION:    EMULATE stosb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmStosb

EmStosb Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepStosb
;
        DestAds
        mov al,byte ptr [bp].reg_eax
        call WriteByte
        DestByte
        ret

RepStosb:
        CheckDone
        jnz RepStosbDo
        ret

RepStosbDo:
        DestAds
        mov al,byte ptr [bp].reg_eax
        call WriteByte
        DestByte
        DecCount
        jnz RepStosbMore
        ret

RepStosbMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmStosb Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmStosw / EmStosd
;
;               DESCRIPTION:    EMULATE stosw / stosd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmStosw

EmStosw Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepStosw
;
        test byte ptr [bp].em_flags,d32
        jnz EmStosd
;
        DestAds
        mov ax,word ptr [bp].reg_eax
        call WriteWord
        DestWord
        ret

EmStosd:
        DestAds
        mov eax,[bp].reg_eax
        call WriteDword
        DestDword
        ret

RepStosw:
        CheckDone
        jnz RepStoswDo
        ret

RepStoswDo:
        test byte ptr [bp].em_flags,d32
        jnz RepStosd
;
        DestAds
        mov ax,word ptr [bp].reg_eax
        call WriteWord
        DestWord
        DecCount
        jnz RepStoswMore
        ret

RepStosd:
        DestAds
        mov eax,[bp].reg_eax
        call WriteDword
        DestDword
        DecCount
        jnz RepStoswMore
        ret

RepStoswMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmStosw Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMovsb
;
;               DESCRIPTION:    EMULATE movsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMovsb

EmMovsb Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepMovsb
;
        SourceAds
        call ReadByte
        push ax
        DestAds
        pop ax
        call WriteByte
        SourceByte
        DestByte
        ret

RepMovsb:
        CheckDone
        jnz RepMovsbDo
        ret

RepMovsbDo:
        SourceAds
        call ReadByte
        push ax
        DestAds
        pop ax
        call WriteByte
        SourceByte
        DestByte
        DecCount
        jnz RepMovsbMore
        ret

RepMovsbMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmMovsb Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmMovsw / EmMovsd
;
;               DESCRIPTION:    EMULATE movsw / movsd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmMovsw

EmMovsw Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepMovsw
;
        test byte ptr [bp].em_flags,d32
        jnz EmMovsd
;
        SourceAds
        call ReadWord
        push ax
        DestAds
        pop ax
        call WriteWord
        SourceWord
        DestWord
        ret

EmMovsd:
        SourceAds
        call ReadDword
        push eax
        DestAds
        pop eax
        call WriteDword
        SourceDword
        DestDword
        ret

RepMovsw:
        CheckDone
        jnz RepMovswDo
        ret

RepMovswDo:
        test byte ptr [bp].em_flags,d32
        jnz RepMovsd
;
        SourceAds
        call ReadWord
        push ax
        DestAds
        pop ax
        call WriteWord
        SourceWord
        DestWord
        DecCount
        jnz RepMovswMore
        ret

RepMovsd:
        SourceAds
        call ReadDword
        push eax
        DestAds
        pop eax
        call WriteDword
        SourceDword
        DestDword
        DecCount
        jnz RepMovswMore
        ret

RepMovswMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmMovsw Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmScasb
;
;               DESCRIPTION:    EMULATE scasb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmScasb

EmScasb Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepScasb
;
        DestAds
        call ReadByte
        DestByte
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub al,byte ptr [bp].reg_eax
        lahf
        mov byte ptr [bp].reg_eflags,ah
        ret

RepScasb:
        CheckDone
        jnz RepScasbDo
        ret

RepScasbDo:
        DestAds
        call ReadByte
        DestByte
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub al,byte ptr [bp].reg_eax
        lahf
        mov byte ptr [bp].reg_eflags,ah
        DecCount
        jnz RepScasbNotDone
        ret

RepScasbNotDone:
        CheckFlags
        jnz RepScasbMore
        ret

RepScasbMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmScasb Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmScasw / EmScasd
;
;               DESCRIPTION:    EMULATE scasw / scasd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmScasw

EmScasw Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepScasw
;
        test byte ptr [bp].em_flags,d32
        jnz EmScasd
;
        DestAds
        call ReadWord
        DestWord
        mov dx,ax
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub dx,word ptr [bp].reg_eax
        lahf
        mov byte ptr [bp].reg_eflags,ah
        ret

EmScasd:
        DestAds
        call ReadDword
        DestDword
        mov edx,eax
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub edx,[bp].reg_eax
        lahf
        mov byte ptr [bp].reg_eflags,ah
        ret

RepScasw:
        CheckDone
        jnz RepScaswDo
        ret

RepScaswDo:
        test byte ptr [bp].em_flags,d32
        jnz RepScasd
;
        DestAds
        call ReadWord
        DestWord
        mov dx,ax
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub dx,word ptr [bp].reg_eax
        lahf
        mov byte ptr [bp].reg_eflags,ah
        DecCount
        jnz RepScaswNotDone
        ret

RepScasd:
        DestAds
        call ReadDword
        DestDword
        mov edx,eax
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub edx,[bp].reg_eax
        lahf
        mov byte ptr [bp].reg_eflags,ah
        DecCount
        jnz RepScaswNotDone
        ret

RepScaswNotDone:
        CheckFlags
        jnz RepScaswMore
        ret

RepScaswMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmScasw Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmCmpsb
;
;               DESCRIPTION:    EMULATE cmpsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCmpsb

EmCmpsb Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepCmpsb
;
        SourceAds
        call ReadByte
        push ax
        DestAds
        call ReadByte
        SourceByte
        DestByte
        pop dx
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub dl,al
        lahf
        mov byte ptr [bp].reg_eflags,ah
        ret

RepCmpsb:
        CheckDone
        jnz RepCmpsbDo
        ret

RepCmpsbDo:
        SourceAds
        call ReadByte
        push ax
        DestAds
        call ReadByte
        SourceByte
        DestByte
        pop dx
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub dl,al
        lahf
        mov byte ptr [bp].reg_eflags,ah
        DecCount
        jnz RepCmpsbNotDone
        ret

RepCmpsbNotDone:
        CheckFlags
        jnz RepCmpsbMore
        ret

RepCmpsbMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmCmpsb Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmCmpsw / EmCmpsd
;
;               DESCRIPTION:    EMULATE cmpsw / cmpsd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmCmpsw

EmCmpsw Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepCmpsw
;
        test byte ptr [bp].em_flags,d32
        jnz EmCmpsd
;
        SourceAds
        call ReadWord
        push ax
        DestAds
        call ReadWord
        SourceWord
        DestWord
        pop bx
        mov dx,ax
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub bx,dx
        lahf
        mov byte ptr [bp].reg_eflags,ah
        ret

EmCmpsd:
        SourceAds
        call ReadDword
        push eax
        DestAds
        call ReadDword
        SourceDword
        DestDword
        pop ebx
        mov edx,eax
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub ebx,edx
        lahf
        mov byte ptr [bp].reg_eflags,ah
        ret

RepCmpsw:
        CheckDone
        jnz RepCmpswDo
        ret

RepCmpswDo:
        test byte ptr [bp].em_flags,d32
        jnz RepCmpsd
;
        SourceAds
        call ReadWord
        push ax
        DestAds
        call ReadWord
        SourceWord
        DestWord
        pop bx
        mov dx,ax
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub bx,dx
        lahf
        mov byte ptr [bp].reg_eflags,ah
        DecCount
        jnz RepCmpswNotDone
        ret

RepCmpsd:
        SourceAds
        call ReadDword
        push eax
        DestAds
        call ReadDword
        SourceDword
        DestDword
        pop ebx
        mov edx,eax
        mov ah,byte ptr [bp].reg_eflags
        sahf
        sub ebx,edx
        lahf
        mov byte ptr [bp].reg_eflags,ah
        DecCount
        jnz RepCmpswNotDone
        ret

RepCmpswNotDone:
        CheckFlags
        jnz RepCmpswMore
        ret

RepCmpswMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmCmpsw Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmInsb
;
;               DESCRIPTION:    EMULATE insb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmInsb

EmInsb  Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepInsb
;
        mov dx,word ptr [bp].reg_edx
        call InByte
        push ax
        DestAds
        pop ax
        call WriteByte
        DestByte
        ret

RepInsb:
        CheckDone
        jnz RepInsbDo
        ret

RepInsbDo:
        mov dx,word ptr [bp].reg_edx
        call InByte
        push ax
        DestAds
        pop ax
        call WriteByte
        DestByte
        DecCount
        jnz RepInsbMore
        ret

RepInsbMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmInsb  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmInsw / EmInsd
;
;               DESCRIPTION:    EMULATE insw / insd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmInsw

EmInsw  Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepInsw
;
        test byte ptr [bp].em_flags,d32
        jnz EmInsd
;
        mov dx,word ptr [bp].reg_edx
        call InWord
        push ax
        DestAds
        pop ax
        call WriteWord
        DestWord
        ret

EmInsd:
        mov dx,word ptr [bp].reg_edx
        call InDword
        push eax
        DestAds
        pop eax
        call WriteDword
        DestDword
        ret

RepInsw:
        CheckDone
        jnz RepInswDo
        ret

RepInswDo:
        test byte ptr [bp].em_flags,d32
        jnz RepInsd
;
        mov dx,word ptr [bp].reg_edx
        call InWord
        push ax
        DestAds
        pop ax
        call WriteWord
        DestWord
        DecCount
        jnz RepInswMore
        ret

RepInsd:
        mov dx,word ptr [bp].reg_edx
        call InDword
        push eax
        DestAds
        pop eax
        call WriteDword
        DestDword
        DecCount
        jnz RepInswMore
        ret

RepInswMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmInsw  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmOutsb
;
;               DESCRIPTION:    EMULATE outsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmOutsb

EmOutsb Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepOutsb
;
        SourceAds
        call ReadByte
        mov dx,word ptr [bp].reg_edx
        call OutByte
        SourceByte
        ret

RepOutsb:
        CheckDone
        jnz RepOutsbDo
        ret

RepOutsbDo:
        SourceAds
        call ReadByte
        mov dx,word ptr [bp].reg_edx
        call OutByte
        SourceByte
        DecCount
        jnz RepOutsbMore
        ret

RepOutsbMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmOutsb Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmOutsw / EmOutsd
;
;               DESCRIPTION:    EMULATE outsw / outsd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmOutsw

EmOutsw Proc near
        test byte ptr [bp].em_flags,rep_z OR rep_nz
        jnz RepOutsw
;
        test byte ptr [bp].em_flags,d32
        jnz EmOutsd
;
        SourceAds
        call ReadWord
        mov dx,word ptr [bp].reg_edx
        call OutWord
        SourceWord
        ret

EmOutsd:
        SourceAds
        call ReadDword
        mov dx,word ptr [bp].reg_edx
        call OutDword
        SourceDword
        ret

RepOutsw:
        CheckDone
        jnz RepOutswDo
        ret

RepOutswDo:
        test byte ptr [bp].em_flags,d32
        jnz RepOutsd
;
        SourceAds
        call ReadWord
        mov dx,word ptr [bp].reg_edx
        call OutWord
        SourceWord
        DecCount
        jnz RepMovswMore
        ret

RepOutsd:
        SourceAds
        call ReadDword
        mov dx,word ptr [bp].reg_edx
        call OutDword
        SourceDword
        DecCount
        jnz RepOutswMore
        ret

RepOutswMore:
        mov ebx,[bp].reg_old_ebp
        mov eax,ss:[ebx].trap_eip
        mov [bp].reg_eip,eax
        ret
EmOutsw Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   EmXlat
;
;               DESCRIPTION:    EMULATE xlat
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public EmXlat

EmXlat  Proc near
        test byte ptr [bp].em_flags,a32
        jnz EmXlat32

EmXlat16:
        call MemBx
        movzx eax,byte ptr [bp].reg_eax
        add ebx,eax
        call ReadByte
        mov byte ptr [bp].reg_eax,al
        ret

EmXlat32:
        call MemEbx
        movzx eax,byte ptr [bp].reg_eax
        add ebx,eax
        call ReadByte
        mov byte ptr [bp].reg_eax,al
        ret
EmXlat  Endp

code    ENDS

        END
