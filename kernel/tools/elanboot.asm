;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; ELANBOOT.ASM
; Bootloader for ELAN processor from PROM
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  elanboot

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

GateSize = 16

INCLUDE \rdos\os\system.def
INCLUDE \rdos\os\protseg.def
INCLUDE \rdos\os\system.inc

DRAM_BASE		EQU 00000000h
FLASH_BASE		EQU 02000000h
PROM_BASE		EQU 03000000h

DefaultIdtEntry		MACRO
	dw OFFSET DefaultInt
	dw device_code_sel
	dw 8E00h
	dw 0
					ENDM

BootIdtEntry		MACRO Offs
	dw OFFSET Offs
	dw device_code_sel
	dw 8E00h
	dw 0
					ENDM

BootExceptionOnePar	MACRO Entry
	push bp
	mov bp,sp
	sti
	push eax
	push ebx
	push ds
	mov al,Entry
	ShutDownPreTask
				ENDM

BootExceptionNoPar	MACRO Entry
	push dword ptr 0
	push bp
	mov bp,sp
	sti
	push eax
	push ebx
	push ds
	mov al,Entry
	ShutDownPreTask
				ENDM

FindRam     MACRO
    Local RamLoop
    Local RamNext
    Local RamFound

    mov ax,flat_sel
    mov ds,ax
    jmp RamNext
RamLoop:
	mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je RamFound
RamNext:
    add esi,1000h
    cmp esi,FLASH_BASE
    jc RamLoop
	stc
RamFound:
            ENDM

.code

.386p

dt0		DT 1e1
dt1		DT 1e2
dt2		DT 1e4
dt3		DT 1e8
dt4		DT 1e16
dt5		DT 1e32
dt6		DT 1e64
dt7		DT 1e128
dt8		DT 1e256
dt9		DT 1e512
dt10	DT 1e1024
dt11	DT 1e2048
dt12	DT 1e4096

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_POWER10
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AX			Exponent
;
;		RETURNS:		ST(0)		10**AX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_power10	PROC near
	push ax
	push bx
	test ax,8000h
	pushf
	jz float_scale_pos
	neg ax
float_scale_pos:
	mov bx,OFFSET dt0
	sub bx,10
	fld1
float_scale_next:
	add bx,10
	or ax,ax
	jz float_scale_end
	clc
	rcr ax,1
	jnc float_scale_next
	fld tbyte ptr cs:[bx]
	fmulp st(1),st
	jmp float_scale_next
float_scale_end:
	popf
	jz float_scale_no_inv
	fld1
	fdivrp st(1),st
float_scale_no_inv:
	pop bx
	pop ax
	ret
float_power10	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_SPLIT
;
;		DESCRIPTION:	SPLIT NUMBER INTO 10-EXPONENT AND MANTISSA
;
;		PARAMETERS:		ST(0)		NUMBER IN, MANTISSA OUT
;						AX			EXPONENT IN NUMBER
;						DL			NUMBER OF DECIMALS
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dt_half	DT 0.5

float_split	PROC near
	pushf
	push cx
	push dx
	push si
	xor dh,dh
	mov ax,dx
	neg ax
	call float_power10
	fld cs:dt_half
	fmulp st(1),st
	faddp st(1),st
	mov si,OFFSET dt12
	mov cx,13
	xor dx,dx
	fld1
	fcomp st(1)
	fstsw ax
	sahf
	jz float_split_end
	jc float_split_no_invert
	fld1
	fdivrp st(1),st
float_split_no_invert:
	pushf
float_split_loop:
	fld tbyte ptr cs:[si]
	fcomp st(1)
	fstsw ax
	sahf
	jz float_split_lower
	jnc float_split_lower
	fld tbyte ptr cs:[si]
	fdivp st(1),st
	stc
	jmp float_split_next
float_split_lower:
	clc
float_split_next:
	rcl dx,1
	sub si,10
	loop float_split_loop
	popf
	jc float_split_end
	fld1
	fdivrp st(1),st
	neg dx
float_split_end:
	mov ax,dx
	pop si
	pop dx
	pop cx
	popf
	ret
float_split	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_CALC_POS
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AX		EXPONENT
;						CL		STRING SIZE
;						DL		NUMBER OF DECIMALS
;
;		RETURNS:		CH		NUMBER OF LEADING BLANKS
;						DH		POSITION OF DECIMAL  "."
;						BL		MANTISSA POSITION
;						NC		OK
;						CY		CANNOT DISPLAY NUMBER ON FORM
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_calc_pos	PROC near
	push ax
	mov bl,al
	neg bl
	test ax,8000h
	jz float_calc_big
	xor ax,ax
	inc bl
float_calc_big:
	or ah,ah
	jnz float_calc_exp
	mov ch,cl
	sub ch,al
	jc float_calc_exp
	sub ch,dl
	jc float_calc_exp
	sub ch,1
	jc float_calc_exp
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
	inc ch
	inc dh
	inc bl
float_calc_dot:
	clc
	pop ax
	ret
float_calc_pos	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_INIT_STRING
;
;		DESCRIPTION:	
;
;		PARAMETERS:		ES:DI	STRING
;						AX		EXPONENT
;						CL		STRING SIZE
;						DL		NUMBER OF DECIMALS
;							NC	POSITIVE NUMBER
;							CY	NEGATIVE NUMBER
;
;		RETURN:			ES:DX	OFFSET TO "."
;						ES:DI	ADDRESS WHERE TO START WRITING MANTISSA
;						ES:SI	LAST CHAR IN STRING
;							NC	OK
;							CY	FEL, TO BIG NUMBER
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_init_string	PROC near
	push cx
	push bx
	push ax
	pushf
	jnc float_istr_calc
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
	inc cl
	inc dh
	inc bl
float_istr_noinc:
	xor bh,bh
	add bx,di
	mov si,bx
	mov bl,cl
	xor bh,bh
	add bx,di
	xchg bx,si
	or ch,ch
	jz float_istr_nodot
	push cx
	mov cl,ch
	xor ch,ch
	mov al,' '
	rep stosb	
	pop cx
float_istr_nodot:
	popf
	jnc float_istr_nosign
	mov al,'-'
	stosb
float_istr_nosign:
	mov cl,dl
	xor ch,ch
	sub cx,si
	neg cx
	sub cx,di
	mov al,'0'
	or cx,cx
	jz float_no_lead_zero
	rep stosb
float_no_lead_zero:
	xor ch,ch
	mov cl,dl
	or cx,cx
	jz float_no_dot
	mov dx,di
	mov al,'.'
	stosb
	mov al,'0'
	rep stosb
float_no_dot:
	mov di,bx
	clc
	jmp float_istr_end
float_istr_error:
	popf
	stc
float_istr_end:
	pop ax
	pop bx
	pop cx
	ret
float_init_string	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_STRING
;
;		DESCRIPTION:	WRITE 10-EXPONENT OCH MANTISSA TO STRING
;
;		PARAMETERS:		ST(0)		MANTISSA 0.1-1.0
;						AX			EXPONENT
;						ES:DI		STRING
;						CH			LEADING BLANKS
;						DH			POSITION OF "."
;						ES:SI		LAST CHAR IN STRING
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_string	PROC near
	mov cx,20
	inc si
	fld1
float_string_loop:
	cmp di,si
	je float_string_end
	cmp di,dx
	jne float_string_no_dot
	inc di
	cmp si,di
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
	or cx,cx
	jz float_string_save0
	dec cx
	mov al,bl
float_string_save0:
	stosb
	fld cs:dt0
	fmulp st(2),st
	cmp si,di
	jne float_string_loop
float_string_end:
	ret
float_string	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_CALC_CHAR
;
;		DESCRIPTION:	CALCULATE CHAR AT POSITION
;
;		PARAMETERS:		ST(0)		MANTISSA 0.1-1.0
;						AX			EXPONENT
;						CL			SIZE OF STRING
;						CH			POSITION IN STRING TO RETRIEVE
;						DH			POSITION OF "."
;						BL			MANTISSA POSITION
;						BH			EXPONENT
;
;		RETURNS:		AL			CHAR
;						ST(0)		TAL UT
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_calc_char	PROC near
	push bx
	push cx
	push dx
	test ax,8000h
	jz float_calc_ch_big
	fld cs:dt0
	fmulp st(1),st
float_calc_ch_big:
	mov dl,'0'
	mov cl,ch
	cmp dh,cl
	jc float_calc_before_dot
	inc cl
float_calc_before_dot:
	sub cl,bl
	jc float_calc_char_end
	xor ch,ch
	fld1
	or cx,cx
	jz float_calc_char_get
float_calc_char_loop:
	fcom st(1)
	fstsw ax
	sahf
	jz float_calc_char_next
	jc float_calc_char_sub
	jmp float_calc_char_next
float_calc_char_sub:
	fsub st(1),st
	jmp float_calc_char_loop
float_calc_char_next:
	fld cs:dt0
	fmulp st(2),st
	loop float_calc_char_loop
float_calc_char_get:
	mov dl,'0'
float_calc_char_conv_loop:
	fcom st(1)
	fstsw ax
	sahf
	jz float_calc_char_end
	jc float_calc_char_subc
	jmp float_calc_char_end
float_calc_char_subc:
	inc dl
	fsub st(1),st
	jmp float_calc_char_conv_loop
float_calc_char_end:
	mov al,dl
	pop dx
	pop cx
	push ax
	mov ah,0FFh
	mov al,dh
	sub al,ch
	jc float_calc_get_exp
	xor ah,ah
	dec ax
float_calc_get_exp:
	finit
	call float_power10
	pop ax
	pop bx
	ret
float_calc_char	ENDP

float_normal	PROC near
	pushf
	call float_split
	call float_init_string
	jc float_error_decode
	popf
	call float_string
	ret
float_error_decode:
	popf
	mov ax,cs
	mov ds,ax
	mov si,OFFSET overflow_txt
	mov cx,13
	rep movsb
	ret
float_normal	ENDP

unsuported_txt	DB 'UNSUPORTED'
nan_txt			DB 'NAN'
infinity_txt	DB 'INFINITY'
empty_txt		DB 'EMPTY'
denormal_txt	DB 'DENORMAL'
overflow_txt	DB 'TO BIG NUMBER'

float_unsuported	PROC near
	mov ax,cs
	mov ds,ax
	mov si,OFFSET unsuported_txt
	mov cx,10
	rep movsb
	ret
float_unsuported	ENDP

float_nan	PROC near
	mov ax,cs
	mov ds,ax
	mov si,OFFSET nan_txt
	mov cx,3
	rep movsb
	ret
float_nan	ENDP

float_infinity	PROC near
	mov ax,cs
	mov ds,ax
	mov si,OFFSET infinity_txt
	mov cx,8
	rep movsb
	ret
float_infinity	ENDP

float_zero	PROC near
	mov al,'0'
	stosb
	ret
float_zero	ENDP

float_empty	PROC near
	mov ax,cs
	mov ds,ax
	mov si,OFFSET empty_txt
	mov cx,5
	rep movsb
	ret
float_empty	ENDP

float_denormal	PROC near
	mov ax,cs
	mov ds,ax
	mov si,OFFSET denormal_txt
	mov cx,8
	rep movsb
	ret
float_denormal	ENDP

float_type_tab:
ftt0 DW OFFSET float_unsuported
ftt1 DW OFFSET float_nan
ftt2 DW OFFSET float_unsuported
ftt3 DW OFFSET float_nan
ftt4 DW OFFSET float_normal
ftt5 DW OFFSET float_infinity
ftt6 DW OFFSET float_normal
ftt7 DW OFFSET float_infinity
ftt8 DW OFFSET float_zero
ftt9 DW OFFSET float_empty
fttA DW OFFSET float_zero
fttB DW OFFSET float_empty
fttC DW OFFSET float_denormal
fttD DW OFFSET float_unsuported
fttE DW OFFSET float_denormal
fttF DW OFFSET float_unsuported

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_TO_STRING
;
;		DESCRIPTION:	
;
;		PARAMETERS:		ST(0)		NUMBER TO CONVERT
;						CL			SIZE OF STRING
;						DL			NUMBER OF DECIMALS
;						ES:DI		STRING
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

float_to_str	PROC near
	push ds
	pusha
	fxam
	fstsw ax
	test ah,2
	clc
	jz float_sign_klar
	fchs
	stc
float_sign_klar:
	pushf
	mov bl,ah
	and bl,7
	and ah,40h
	jz fl_c3_zero
	or bl,8
fl_c3_zero:
	xor bh,bh
	add bx,bx
	popf
	call word ptr cs:[bx].float_type_tab
	xor al,al
	stosb
	popa
	pop ds
	ret
float_to_str	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FLOAT_GET_CHAR
;
;		DESCRIPTION:	
;
;		PARAMETERS:		ST(0)		NUMBER TO GET CHAR IN
;						CL			SIZE OF STRING
;						CH			POSITION TO RETURN CHAR FOR
;						DL			NUMBER OF DECIMALS
;
;		RETURNS:		AL			TECKEN
;						ST(0)		NUMBER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public float_get_char

float_get_char	PROC near
	push ds
	push bx
	push cx
	push dx
	push si
	push di
	fxam
	fstsw ax
	test ah,2
	clc
	jz float_getch_pos
	fchs
float_getch_pos:
	mov bl,ah
	and bl,7
	and ah,40h
	jz float_getch_zero
	cmp bl,4
	jnz float_getch_end
float_getch_zero:
	call float_split
float_getch_calc:
	push cx
	call float_calc_pos
	pop cx
	jc float_getch_error
	mov bh,ch
	sub bh,dh
	jz float_getch_dot
	jc float_getch_norm
	dec bh
float_getch_norm:
	neg bh
	call float_calc_char
	jmp float_getch_end
float_getch_dot:
	mov al,'.' 
	jmp float_getch_end
float_getch_error:
	finit
	mov al,'E'
float_getch_end:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ds
	ret
float_get_char	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CalcCrc
;
;		DESCRIPTION:	Calculate CRC for one byte
;
;       PARAMETERS:     AX		CRC
;                       DS:ESI  Address to data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcCrc Proc near
    push cx
    mov cl,[esi]
    inc esi
	xor ah,cl
;
	mov cx,1021h
	shl ax,1
	jnc no_xor0
	xor ax,cx
no_xor0:
	shl ax,1
	jnc no_xor1
	xor ax,cx
no_xor1:
	shl ax,1
	jnc no_xor2
	xor ax,cx
no_xor2:
	shl ax,1
	jnc no_xor3
	xor ax,cx
no_xor3:
	shl ax,1
	jnc no_xor4
	xor ax,cx
no_xor4:
	shl ax,1
	jnc no_xor5
	xor ax,cx
no_xor5:
	shl ax,1
	jnc no_xor6
	xor ax,cx
no_xor6:
	shl ax,1
	jnc no_xor7
	xor ax,cx
no_xor7:
    pop cx
    ret
CalcCrc Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetRamSize
;
;		DESCRIPTION:	Get installed RAM size
;
;       RETURNS:        EAX     Size of installed RAM
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRamSize	Proc near
	mov eax,2000000h
	ret
GetRamSize	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetPromSize
;
;		DESCRIPTION:	Get installed PROM size
;
;       RETURNS:        EAX     Size of installed PROM
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPromSize	Proc near
	mov eax,20000h
	ret
GetPromSize	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetAdapter
;
;		DESCRIPTION:	Get adapter
;
;		PARAMETERS:     ESI     Adress to start search at
;
;       RETURNS:        ESI     Adapter base
;                       ECX     Size of adapter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAdapter  Proc near
	push ds
	mov ax,flat_sel
	mov ds,ax
GetAdapterSearch:
	mov eax,[esi]
	cmp eax,RdosSign
	je GetAdapterFound
GetAdapterNext:
	add esi,1000h
	or esi,esi
	jne GetAdapterSearch
	stc
	jmp GetAdapterDone
GetAdapterCorrupt:
	pop esi
	jmp GetAdapterNext
GetAdapterFound:
	push esi
	xor ecx,ecx
GetAdapterNextDriver:
	cmp [esi].sign,RdosSign
	jne GetAdapterCorrupt
;
	cmp [esi].typ,RdosEnd
	je GetAdapterOk
	mov edx,[esi].len
	add ecx,edx
	cmp ecx,1000000h
	jnc GetAdapterCorrupt
;
	xor ax,ax
	push ecx
	push esi
	mov ecx,edx
	add esi,SIZE rdos_header
	sub ecx,SIZE rdos_header
	jz GetAdapterCrcDone
GetAdapterCrcLoop:
	call CalcCrc
	sub ecx,1
	jnz GetAdapterCrcLoop
GetAdapterCrcDone:
	pop esi
	pop ecx
	cmp ax,[esi].crc
	jne GetAdapterCorrupt
;
	add esi,edx
	jmp GetAdapterNextDriver
GetAdapterOk:
	pop esi
	clc
GetAdapterDone:
	pop ds
	ret
GetAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AdapterCrc
;
;		DESCRIPTION:	Calculate adapter CRC
;
;		PARAMETERS:     ESI     Adapter base
;                       ECX     Size of adapter
;
;		RETURNS:		AX		Adapter CRC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AdapterCrc  Proc near
	push ds
	mov ax,flat_sel
	mov ds,ax
	xor ax,ax
	push ecx
	push esi
AdapterCrcLoop:
	call CalcCrc
	sub ecx,1
	jnz AdapterCrcLoop
	pop esi
	pop ecx
	pop ds
	ret
AdapterCrc  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddAdapter
;
;		DESCRIPTION:
;
;		PARAMETERS:     ESI     Adapter base
;						ECX     Size of adapter
;                       AX		Adapter CRC
;						BX		Current Adapter record
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddAdapter	Proc near
	push dx
	push di
	mov di,OFFSET rom_adapters
	mov dx,ds:rom_modules
AddAdapterCheck:
	or dx,dx
	jz AddAdapterDo
	cmp ecx,[di].adapter_size
	jne AddAdapterCheckNext
	cmp ax,[di].adapter_crc
	je AddAdapterEnd
AddAdapterCheckNext:
	dec dx
	add di,SIZE adapter_typ
	jmp AddAdapterCheck
AddAdapterDo:
    inc ds:rom_modules
    mov [bx].adapter_base,esi
    mov [bx].adapter_size,ecx
    mov [bx].adapter_crc,ax
    add bx,SIZE adapter_typ
AddAdapterEnd:
	pop di
	pop dx
	ret
AddAdapter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetAllAdapters
;
;		DESCRIPTION:	Get all adapters
;
;		PARAMETERS:     ESI     Adress to start search at
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAllAdapters  Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov ds:rom_modules,0
    mov bx,OFFSET rom_adapters
	mov esi,PROM_BASE
get_adapters_loop:
    call GetAdapter
    jc get_adapters_done
	call AdapterCrc
	call AddAdapter
    add esi,ecx
    dec esi
    and si,0F000h
    add esi,1000h
    jmp get_adapters_loop
get_adapters_done:
    ret
GetAllAdapters  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartShutdownDevice
;
;		DESCRIPTION:	Starts shutdown-device
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartShutDownDevice	Proc near
    mov ax,system_data_sel
    mov ds,ax
	mov ax,flat_sel
	mov es,ax
	mov cx,ds:rom_modules
	mov bx,OFFSET rom_adapters
	or cx,cx
	jz StartShutDeviceEnd
StartShutAdapterLoop:
	push bx
	push cx
	mov esi,[bx].adapter_base
StartShutDeviceLoop:
	cmp es:[esi].typ,RdosShutDown
	je StartShutDeviceDo
	cmp es:[esi].typ,RdosEnd
	je StartShutNextAdapter
	add esi,es:[esi].len
	jmp StartShutDeviceLoop
StartShutNextAdapter:
	pop cx
	pop bx
	add bx,SIZE adapter_typ
	loop StartShutAdapterLoop
	jmp StartShutDeviceEnd
StartShutDeviceDo:
	pop cx
	pop bx
;
	push ds
	push es
	pushad
	push cs
	push OFFSET StartShutDeviceInitied
	mov ax,flat_sel
	mov ds,ax
	mov bx,shutdown_code_sel
	push bx
	mov ecx,[esi].len
	add esi,SIZE rdos_header
	push word ptr [esi].init_ip
	add esi,SIZE device_header
	mov ax,gdt_sel
	mov ds,ax
	dec cx
	mov [bx],cx
	mov [bx+2],esi
	mov ah,9Ah
	xchg ah,[bx+5]
	xor al,al
	mov [bx+6],ax
	retf
StartShutDeviceInitied:
	mov ax,gdt_sel
	mov ds,ax
	mov bx,idt_sel
	mov eax,[bx+2]
	sub eax,OFFSET rom_idt
	add eax,OFFSET boot_idt
	mov [bx+2],eax
	mov al,[bx+7]
	xchg al,[bx+5]
	db 66h
	lidt [bx]
	xchg al,[bx+5]
	popad
	pop es
	pop ds
;
StartShutDeviceEnd:	
	ret
StartShutDownDevice	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetBootDevice
;
;		DESCRIPTION:	Get header of boot-device
;
;		RETURNS:		NC
;						ESI			Boot device base
;						CY			No boot device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBootDevice	Proc near
    mov ax,system_data_sel
    mov ds,ax
	mov ax,flat_sel
	mov es,ax
	mov cx,ds:rom_modules
	mov bx,OFFSET rom_adapters
	or cx,cx
	jz GetBootDeviceFail
GetBootAdapterLoop:
	push bx
	push cx
	mov esi,[bx].adapter_base
GetBootDeviceLoop:
	cmp es:[esi].typ,RdosKernel
	je GetBootDeviceOk
	cmp es:[esi].typ,RdosEnd
	je GetBootNextAdapter
	add esi,es:[esi].len
	jmp GetBootDeviceLoop
GetBootNextAdapter:
	pop cx
	pop bx
	add bx,SIZE adapter_typ
	loop GetBootAdapterLoop
	jmp GetBootDeviceFail
GetBootDeviceOk:
	pop cx
	pop bx
	clc
	jmp GetBootDeviceEnd
GetBootDeviceFail:	
	stc
GetBootDeviceEnd:
	ret
GetBootDevice	Endp

DefaultInt:
	hlt

rom_gdt:
gdt0:
	dw 0
	dd 0
	dw 0
gdt8:
	dw 10h*8-1
	dd 92FF0000h + OFFSET rom_idt
	dw 0FF00h
gdt10:
	dw 28h-1
	dd 92FF0000h + OFFSET rom_gdt
	dw 0FF00h
gdt18:
	dw 0FFFFh
	dd 9AFF0000h
	dw 0FF00h
gdt20:
	dw 0FFFFh
	dd 92000000h
	dw 8Fh

rom_idt:
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry

Boot0:
	BootExceptionNoPar 0

Boot1:
	BootExceptionNoPar 1

Boot2:
	BootExceptionNoPar 2

Boot3:
	BootExceptionNoPar 3

Boot4:
	BootExceptionNoPar 4

Boot5:
	BootExceptionNoPar 5

Boot6:
	BootExceptionNoPar 6

Boot7:
	BootExceptionNoPar 7

Boot8:
	BootExceptionNoPar 8

Boot9:
	BootExceptionNoPar 9

BootA:
	BootExceptionNoPar 0Ah

BootB:
	BootExceptionOnePar 0Bh

BootC:
	BootExceptionOnePar 0Ch

BootD:
	BootExceptionOnePar 0Dh

BootE:
	BootExceptionNoPar 0Eh

BootF:
	BootExceptionNoPar 0Fh

boot_idt:
	BootIdtEntry Boot0
	BootIdtEntry Boot1
	BootIdtEntry Boot2
	BootIdtEntry Boot3
	BootIdtEntry Boot4
	BootIdtEntry Boot5
	BootIdtEntry Boot6
	BootIdtEntry Boot7
	BootIdtEntry Boot8
	BootIdtEntry Boot9
	BootIdtEntry BootA
	BootIdtEntry BootB
	BootIdtEntry BootC
	BootIdtEntry BootD
	BootIdtEntry BootE
	BootIdtEntry BootF

idt_reg:
	dw 10h*8-1
	dd 0FFFF0000h + OFFSET rom_idt

gdt_reg:
	dw 28h-1
	dd 0FFFF0000h + OFFSET rom_gdt

;		mask	value

csc_tab:
csc00	DB 0,	0
csc01	DB 0,	0
csc02	DB 0,	0
csc03	DB 0,	0
csc04	DB 0DFh,5Ch
csc05	DB 7Fh, 40h
csc06	DB 0FFh,00h
csc07	DB 0Fh,	00h
csc08	DB 0,	0
csc09	DB 0,	0
csc0A	DB 0,	0
csc0B	DB 0,	0
csc0C	DB 0,	0
csc0D	DB 0,	0
csc0E	DB 0,	0
csc0F	DB 0,	0
csc10	DB 0,	0
csc11	DB 7Fh,	00h
csc12	DB 0,	0
csc13	DB 1Fh,	00h
csc14	DB 0FFh,10h
csc15	DB 0,	0
csc16	DB 0,	0
csc17	DB 0,	0
csc18	DB 0,	0
csc19	DB 0,	0
csc1A	DB 0,	0
csc1B	DB 0,	0
csc1C	DB 0,	0
csc1D	DB 0,	0
csc1E	DB 0,	0
csc1F	DB 0,	0
csc20	DB 0,	0
csc21	DB 0FFh,90h
csc22	DB 0FFh,0F0h
csc23	DB 0,	0
csc24	DB 0,	0
csc25	DB 0,	0
csc26	DB 0,	0
csc27	DB 0,	0
csc28	DB 0,	0
csc29	DB 0,	0
csc2A	DB 0,	0
csc2B	DB 0,	0
csc2C	DB 0,	0
csc2D	DB 0,	0
csc2E	DB 0,	0
csc2F	DB 0,	0
csc30	DB 0,	0
csc31	DB 0,	0
csc32	DB 0,	0
csc33	DB 0,	0
csc34	DB 0,	0
csc35	DB 0,	0
csc36	DB 0,	0
csc37	DB 0,	0
csc38	DB 0DFh,1Fh
csc39	DB 7Fh,	00h
csc3A	DB 03h,	00h
csc3B	DB 0,	0
csc3C	DB 0,	0
csc3D	DB 0,	0
csc3E	DB 0,	0
csc3F	DB 0,	0
csc40	DB 0,	0
csc41	DB 0,	0
csc42	DB 0,	0
csc43	DB 0,	0
csc44	DB 0,	0
csc45	DB 0,	0
csc46	DB 0,	0
csc47	DB 0,	0
csc48	DB 0,	0
csc49	DB 0,	0
csc4A	DB 0,	0
csc4B	DB 0,	0
csc4C	DB 0,	0
csc4D	DB 0,	0
csc4E	DB 0,	0
csc4F	DB 0,	0
csc50	DB 0Fh,	00h
csc51	DB 0,	0
csc52	DB 0,	0
csc53	DB 0,	0
csc54	DB 0,	0
csc55	DB 0,	0
csc56	DB 0,	0
csc57	DB 0,	0
csc58	DB 0,	0
csc59	DB 0,	0
csc5A	DB 0,	0
csc5B	DB 0,	0
csc5C	DB 0,	0
csc5D	DB 0,	0
csc5E	DB 0,	0
csc5F	DB 0,	0
csc60	DB 0,	0
csc61	DB 0,	0
csc62	DB 0,	0
csc63	DB 0,	0
csc64	DB 0,	0
csc65	DB 0,	0
csc66	DB 0,	0
csc67	DB 0,	0
csc68	DB 0,	0
csc69	DB 0,	0
csc6A	DB 0,	0
csc6B	DB 0,	0
csc6C	DB 0,	0
csc6D	DB 0,	0
csc6E	DB 0,	0
csc6F	DB 0,	0
csc70	DB 0,	0
csc71	DB 0,	0
csc72	DB 0,	0
csc73	DB 0,	0
csc74	DB 0,	0
csc75	DB 0,	0
csc76	DB 0,	0
csc77	DB 0,	0
csc78	DB 0,	0
csc79	DB 0,	0
csc7A	DB 0,	0
csc7B	DB 0,	0
csc7C	DB 0,	0
csc7D	DB 0,	0
csc7E	DB 0,	0
csc7F	DB 0,	0
csc80	DB 1Fh,	04h
csc81	DB 0,	0
csc82	DB 7Fh,	21h
csc83	DB 0Fh,	08h
csc84	DB 0,	0
csc85	DB 0,	0
csc86	DB 0,	0
csc87	DB 0,	0
csc88	DB 0,	0
csc89	DB 0,	0
csc8A	DB 0,	0
csc8B	DB 0,	0
csc8C	DB 0,	0
csc8D	DB 0,	0
csc8E	DB 0,	0
csc8F	DB 0,	0
csc90	DB 0FFh,00h
csc91	DB 0FFh,00h
csc92	DB 1Fh,	00h
csc93	DB 0FFh,00h
csc94	DB 0FFh,00h
csc95	DB 0FFh,00h
csc96	DB 3Fh,	00h
csc97	DB 0FFh,00h
csc98	DB 0FFh,00h
csc99	DB 1Fh,	00h
csc9A	DB 7Fh,	00h
csc9B	DB 1Fh,	00h
csc9C	DB 7Fh,	00h
csc9D	DB 03h,	00h
csc9E	DB 0,	0
csc9F	DB 0,	0
cscA0	DB 0FFh,00h
cscA1	DB 0FFh,00h
cscA2	DB 0FFh,00h
cscA3	DB 0FFh,00h
cscA4	DB 0FFh,00h
cscA5	DB 0FFh,00h
cscA6	DB 0,	0
cscA7	DB 0,	0
cscA8	DB 0,	0
cscA9	DB 0,	0
cscAA	DB 0,	0
cscAB	DB 0,	0
cscAC	DB 0,	0
cscAD	DB 0,	0
cscAE	DB 0FFh,0FFh
cscAF	DB 0FFh,0FFh
cscB0	DB 1Fh,	0Fh
cscB1	DB 0FFh,0FFh
cscB2	DB 0FFh,0FFh
cscB3	DB 0FFh,0FFh
cscB4	DB 0,	0
cscB5	DB 0,	0
cscB6	DB 0,	0
cscB7	DB 0,	0
cscB8	DB 0,	0
cscB9	DB 0,	0
cscBA	DB 0,	0
cscBB	DB 0,	0
cscBC	DB 0,	0
cscBD	DB 0,	0
cscBE	DB 0,	0
cscBF	DB 0,	0
cscC0	DB 0FFh,06h
cscC1	DB 7Fh,	00h
cscC2	DB 0,	0
cscC3	DB 0,	0
cscC4	DB 0,	0
cscC5	DB 0,	0
cscC6	DB 0,	0
cscC7	DB 0FFh,0FFh
cscC8	DB 0FFh,0FFh
cscC9	DB 0FFh,0FFh
cscCA	DB 0,	0
cscCB	DB 0,	0
cscCC	DB 0,	0
cscCD	DB 0,	0
cscCE	DB 0,	0
cscCF	DB 0,	0
cscD0	DB 3Fh,	02h
cscD1	DB 0Fh,	01h
cscD2	DB 0,	0
cscD3	DB 0C0h,80h
cscD4	DB 0FFh,00h
cscD5	DB 0FFh,00h
cscD6	DB 0FFh,00h
cscD7	DB 0FFh,00h
cscD8	DB 0F7h,40h
cscD9	DB 0,	0
cscDA	DB 0,	0
cscDB	DB 0FFh,00h
cscDC	DB 0Fh,	00h
cscDD	DB 0FFh,00h
cscDE	DB 0,	0
cscDF	DB 0,	0
cscE0	DB 7Fh,	00h
cscE1	DB 0,	0
cscE2	DB 0,	0
cscE3	DB 0EFh,00h
cscE4	DB 0,	0
cscE5	DB 0,	0
cscE6	DB 0,	0
cscE7	DB 0,	0
cscE8	DB 0,	0
cscE9	DB 0,	0
cscEA	DB 0,	0
cscEB	DB 0,	0
cscEC	DB 0,	0
cscED	DB 0,	0
cscEE	DB 0,	0
cscEF	DB 0,	0
cscF0	DB 0,	0
cscF1	DB 0F3h,00h
cscF2	DB 0,	0
cscF3	DB 0,	0
cscF4	DB 0,	0
cscF5	DB 0,	0
cscF6	DB 0,	0
cscF7	DB 0,	0
cscF8	DB 0,	0
cscF9	DB 0,	0
cscFA	DB 0,	0
cscFB	DB 0,	0
cscFC	DB 0,	0
cscFD	DB 0,	0
cscFE	DB 0,	0
cscFF	DB 0,	0

;		mask	value

pccard_tab:
pcc00	DB 0,	0
pcc01	DB 0,	0
pcc02	DB 0FFh,00h
pcc03	DB 0FFh,00h
pcc04	DB 0,	0
pcc05	DB 0FFh,00h
pcc06	DB 0FFh,00h
pcc07	DB 0FFh,00h
pcc08	DB 0,	0
pcc09	DB 0,	0
pcc0A	DB 0,	0
pcc0B	DB 0,	0
pcc0C	DB 0,	0
pcc0D	DB 0,	0
pcc0E	DB 0,	0
pcc0F	DB 0,	0
pcc10	DB 0,	0
pcc11	DB 0,	0
pcc12	DB 0,	0
pcc13	DB 0,	0
pcc14	DB 0,	0
pcc15	DB 0,	0
pcc16	DB 0,	0
pcc17	DB 0,	0
pcc18	DB 0,	0
pcc19	DB 0,	0
pcc1A	DB 0,	0
pcc1B	DB 0,	0
pcc1C	DB 0,	0
pcc1D	DB 0,	0
pcc1E	DB 0,	0
pcc1F	DB 0,	0
pcc20	DB 0,	0
pcc21	DB 0,	0
pcc22	DB 0,	0
pcc23	DB 0,	0
pcc24	DB 0,	0
pcc25	DB 0,	0
pcc26	DB 0,	0
pcc27	DB 0,	0
pcc28	DB 0,	0
pcc29	DB 0,	0
pcc2A	DB 0,	0
pcc2B	DB 0,	0
pcc2C	DB 0,	0
pcc2D	DB 0,	0
pcc2E	DB 0,	0
pcc2F	DB 0,	0
pcc30	DB 0,	0
pcc31	DB 0,	0
pcc32	DB 0,	0
pcc33	DB 0,	0
pcc34	DB 0,	0
pcc35	DB 0,	0
pcc36	DB 0,	0
pcc37	DB 0,	0
pcc38	DB 0,	0
pcc39	DB 0,	0
pcc3A	DB 0,	0
pcc3B	DB 0,	0
pcc3C	DB 0,	0
pcc3D	DB 0,	0
pcc3E	DB 0,	0
pcc3F	DB 0,	0
pcc40	DB 0,	0
pcc41	DB 0,	0
pcc42	DB 0FFh,00h
pcc43	DB 0FFh,00h
pcc44	DB 0,	0
pcc45	DB 0FFh,00h
pcc46	DB 0FFh,00h
pcc47	DB 0FFh,00h
pcc48	DB 0,	0
pcc49	DB 0,	0
pcc4A	DB 0,	0
pcc4B	DB 0,	0
pcc4C	DB 0,	0
pcc4D	DB 0,	0
pcc4E	DB 0,	0
pcc4F	DB 0,	0
pcc50	DB 0,	0
pcc51	DB 0,	0
pcc52	DB 0,	0
pcc53	DB 0,	0
pcc54	DB 0,	0
pcc55	DB 0,	0
pcc56	DB 0,	0
pcc57	DB 0,	0
pcc58	DB 0,	0
pcc59	DB 0,	0
pcc5A	DB 0,	0
pcc5B	DB 0,	0
pcc5C	DB 0,	0
pcc5D	DB 0,	0
pcc5E	DB 0,	0
pcc5F	DB 0,	0
pcc60	DB 0,	0
pcc61	DB 0,	0
pcc62	DB 0,	0
pcc63	DB 0,	0
pcc64	DB 0,	0
pcc65	DB 0,	0
pcc66	DB 0,	0
pcc67	DB 0,	0
pcc68	DB 0,	0
pcc69	DB 0,	0
pcc6A	DB 0,	0
pcc6B	DB 0,	0
pcc6C	DB 0,	0
pcc6D	DB 0,	0
pcc6E	DB 0,	0
pcc6F	DB 0,	0
pcc70	DB 0,	0
pcc71	DB 0,	0
pcc72	DB 0,	0
pcc73	DB 0,	0
pcc74	DB 0,	0
pcc75	DB 0,	0
pcc76	DB 0,	0
pcc77	DB 0,	0
pcc78	DB 0,	0
pcc79	DB 0,	0
pcc7A	DB 0,	0
pcc7B	DB 0,	0
pcc7C	DB 0,	0
pcc7D	DB 0,	0
pcc7E	DB 0,	0
pcc7F	DB 0,	0

dram_col_table:
	DB 8, 0
	DB 9, 8
	DB 10,9
	DB 11,10
	DB 12,11
	DB 0, 12

dram_row_table:
	DB 22,0
	DB 13,9
	DB 24,10
	DB 23,11
	DB 12,12
	DB 0, 13

dram_ctrl_tab:
	DB 12, 12, 06h
	DB 11, 13, 16h 
	DB 11, 12, 05h
	DB 11, 11, 04h
	DB 10, 13, 15h
	DB 10, 12, 14h
	DB 10, 11, 03h
	DB 10, 10, 02h
	DB 9,  12, 13h
	DB 9,  10, 11h
	DB 9,  9,  00h
	DB 8,  12, 12h
	DB -1, -1, 00h

val1	DQ 0.5665
val2	DQ -3.0
val3	DQ -34.56

val	DT 4.566
float_str	DB 256 DUP(?)

init:
	finit
	fld tbyte ptr cs:val
	mov ax,cs
	mov es,ax
	mov di,OFFSET float_str
	mov dl,18
	mov cl,100
	call float_to_str
	cli
	in al,0EEh
	db 66h
	lgdt fword ptr gdt_reg
	db 66h
    lidt fword ptr idt_reg
	xor ax,ax
	lahf
	mov ebx,cr0
	or bl,1
	mov cr0,ebx
	db 0EAh
	dw OFFSET prot_init
	dw device_code_sel

prot_init:
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
	mov dx,22h
	xor cl,cl
	mov bx,OFFSET csc_tab
init_csc_loop:
	mov ah,cs:[bx]
	or ah,ah
	jz init_csc_next
;
	mov al,cl
	out dx,al
	inc dx
	not ah
	in al,dx
	and al,ah
	or al,cs:[bx+1]
	out dx,al
	in al,dx
	dec dx

init_csc_next:
	add bx,2
	inc cl	
	or cl,cl
	jnz init_csc_loop
;
	mov dx,3E0h
	xor cl,cl
	mov bx,OFFSET pccard_tab
init_pccard_loop:
	mov ah,cs:[bx]
	or ah,ah
	jz init_pccard_next
;
	mov al,cl
	out dx,al
	not ah
	inc dx
	in al,dx
	and al,ah
	or al,cs:[bx+1]
	out dx,al
	dec dx

init_pccard_next:
	add bx,2
	inc cl	
	test cl,80h
	jz init_pccard_loop
;
	int 3
;
	mov	ax,8600h
	out	23h,ax
;
	mov	ax,1005h
	out	22h,ax
;
	xor edi,edi
	mov	dword ptr [edi],55AA55AAh
	mov	eax,[edi]
;
	mov	ax,0DC04h
	out	22h,ax
;
	mov	ebx,[edi]
;
	mov	ax,05C04h
	out	22h,ax
;
	mov	ax,4005h
	out	22h,ax
;
	xor al,al
	out 22h,al
;
	mov	eax,[edi]
	cmp	eax,55AA55AAh
	jnz	Failed
;
	cmp	eax,ebx
	jnz	dram_edo_done
;
	mov	al,0A6h
	out	23h,al

dram_edo_done:
	mov	bx,OFFSET dram_col_table
	mov eax,3ABC3478h
	mov ebp,45AC65BCh

dram_col_loop:
	mov	cx,cs:[bx]
	inc	bx
	inc	bx
	or	cl,cl
	jz	dram_col_exit
;
	xor esi,esi
	mov [esi],ebp
	mov edi,1
	shl	edi,cl
	mov	[edi],eax
	cmp	ebp,[esi]
	jnz	dram_col_exit
;
	cmp	eax,[edi]
	jz	dram_col_loop

dram_col_exit:
	mov	dx,cx
;
	in	al,23h
	or	al,10h
	out	23h,al
;
	mov	al,3
	out	22h,al
	in	al,23h
	or	al,80h
	out	23h,al
;
	mov	bx,OFFSET dram_row_table
	mov eax,3ABC3478h
	mov ebp,45AC65BCh

dram_row_loop:
	mov	cx,cs:[bx]
	inc	bx
	inc	bx
	or	cl,cl
	jz	dram_row_exit
;
	xor esi,esi
	mov [esi],ebp
	mov edi,1
	shl	edi,cl
	mov	[edi],eax
	cmp	ebp,[esi]
	jnz	dram_row_exit
;
	cmp	eax,[edi]
	jz	dram_row_loop

dram_row_exit:
	mov	al,3
	out	22h,al
	in	al,23h
	and	al,7Fh
	out	23h,al
	xor al,al
	out	22h,al
;
	mov	cl,dh
	mov	bx,OFFSET dram_ctrl_tab

dram_size_loop:
	mov	ax,cs:[bx]
	add	bx,3
	cmp	al,cl
	jg	dram_size_loop
;
	cmp	ah,ch
	jg	dram_size_loop
;
	cmp	ax,cx
	jnz	Failed
;
	in	al,23h
	and	al,0E0h
	or	al,cs:[bx-1]
	out	23h,al
;
    xor esi,esi
    FindRam
    mov edx,esi
    mov edi,esi
    xor esi,esi
    mov ax,gdt_sel
    mov ds,ax
    mov ecx,2*5
    rep movs dword ptr es:[edi],[esi]
    mov ax,flat_sel
    mov ds,ax
    mov esi,edx
    mov ebx,gdt_sel
    add ebx,esi
    mov word ptr [ebx],0FFFh
    mov [ebx+2],esi
    mov byte ptr [ebx+5],92h
    mov word ptr [ebx+6],0
    lgdt [esi+gdt_sel]
;
    FindRam
    mov ax,gdt_sel
    mov ds,ax
    mov bx,system_data_sel
    mov word ptr [bx],0FFFh
    mov [bx+2],esi
    mov byte ptr [bx+5],92h
    mov word ptr [bx+6],0
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:alloc_base,esi
;
    mov ax,gdt_sel
    mov ss,ax
    mov sp,1000h
;
    call GetAllAdapters
	call StartShutDownDevice
	call GetBootDevice
	jnc DoBoot

Failed:
	hlt
DoBoot:
	mov ax,system_data_sel
	mov ds,ax
	call GetRamSize
	mov ds:ram1_size,eax
	mov ds:ram2_size,0
	mov ds:rom_base,PROM_BASE
	call GetPromSize
	mov ds:rom_size,eax
;
	mov ax,flat_sel
	mov ds,ax
	push kernel_code
	mov ecx,[esi].len
	add esi,SIZE rdos_header
	push [esi].init_ip
	add esi,SIZE device_header
	mov ax,gdt_sel
	mov ds,ax
	dec cx
	mov bx,kernel_code
	mov [bx],cx
	mov [bx+2],esi
	mov ah,9Ah
	xchg ah,[bx+5]
	xor al,al
	mov [bx+6],ax
	retf

	END init
