;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2002, Leif Ekblad
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
; SDRAM.ASM
; Setup SDRAM for BUR-loader
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        NAME  sdram

.model tiny
.code
.386p

WriteNB Macro index, data
    mov ax,index
    out 24h,ax
    mov ax,data
    out 26h,ax
        Endm

ReadNB  Macro index
    mov ax,index
    out 24h,ax
    in ax,26h
        ENDM

ReadPciDword Macro bus, device, function, index
    mov eax,80000000h OR (bus SHL 16) OR (device SHL 11) OR (function SHL 8) OR (index AND 0FFFCh)
	mov dx,0CF8h
	out dx,eax
	mov dx,0CFCh
	in eax,dx
        ENDM


WritePciDword Macro bus, device, function, index, data
    mov eax,80000000h OR (bus SHL 16) OR (device SHL 11) OR (function SHL 8) OR (index AND 0FFFCh)
	mov dx,0CF8h
	out dx,eax
    mov eax,data
	mov dx,0CFCh
    out dx,eax
	    ENDM

	org 0

Startup:
	jmp Main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Data at the end of the BUR
;
;		org	0FF00h
;
;		dw	BUR_VERSION
;		dw	VAR_START		
;		dw	offset	FarReturn
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CIRC_BUFF_SIZE	=	128
CMD_LINE_LEN	=	70
FZ_FIELD_LEN	=	11

ZT_LED_RED	=	00000010b
ZT_LED_GREEN	=	00001000b

Seg0	STRUC

CircIn		    dw	0
CircOut		    dw	0
CircBuf		    db	CIRC_BUFF_SIZE dup (0)
Handshake	    db	0	; 1 if RTS/CTS is used
SerialMode	    db	0	; 0=none 1=Serial 2=ZTAG_LEDS
CRCFreez	    db	0	; if 1, ZTEXEC will freez on CRC errors
CmdLine		    db	CMD_LINE_LEN dup (0)
Addressing	    db	0	; 0=real mode, 1=linear mode
ColonInCmd	    db	0
LastDispCmd	    dw	0	; for 'd' command: 0=ignore, entry to command otherwise
LastEDX		    dd	0	; for 'd' command
UsrCmdStart	    dw	0	; start offset of user commands area (seg=70h)
UsrCmdCount	    dw	0	; number of uploaded user-defined commands
DownloadSegment	dw	0	; segment, where the downloadable code can start
YModemHdrByte	db	0	; first byte of filename
YModemFileSize	db	FZ_FIELD_LEN dup (0)
YModemCRChi	    db	0	; received by YModem
YModemCRClo	    db	0
YModemCRChi_C	db	0	; UpdCRC routine uses these
YModemCRClo_C	db	0
YModemPktNo	    db	0
CountDown	    dw	0		
QuickIRET	    db	0	; IRET placeholder		
RomSegment	    dw	0	; Code segment of ROM		
CachedOffset	dw	0	; used for checking on code copy to cache

Seg0    ENDS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DSBX2Var
;
;		DESCRIPTION:	Get variable start
;
;       RETURNS:		DX:BX		address of variables
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DSBX2Var	proc
	push 0F000h
	pop	ds
	mov	bx, word ptr ds:[0FF02h]
	push 0
	pop	ds
	ret
DSBX2Var	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CRLF
;
;		DESCRIPTION:	Display CR/LF to the active serial output console.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CRLF	Proc near
	db 9Ah
	dw 0FF0Ah
	dw 0F000h
	ret
CRLF		endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Delay
;
;		DESCRIPTION:	Do some uncalibrated delaying
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delay		proc
	db 9Ah
	dw 0FF0Eh
	dw 0F000h
	ret
Delay		endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Parm2EDX
;
;		DESCRIPTION:	Parse command line numeric parameter to EDX
;
;       PARAMETERS:     AL		field type: 	
;							0 - byte:  0-0FFh
;							1 - word:  0-0FFFFh
;							2 - dword: 0-0FFFFFFFFh
;							3 - address: (xxxx:xxxx if real addressing,
;										      xxxxxxxx if linear addressing)
;						CL		parameter number (1=first parameter)
;
; 		RETURNS:		EDX		parsed parameter value
;						CY		success
;	 					NC		invalid parameter or parameter missing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	 
Parm2EDX	Proc near
	push ds
	push bx
;
	call DSBX2Var
	db 9Ah
	dw 0FF12h
	dw 0F000h
;		
	pop	bx
	pop	ds
	ret
Parm2EDX	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ResetCRC
;
;		DESCRIPTION:	?
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetCRC	proc
	db 9Ah
	dw 0FF16h
	dw 0F000h
	ret
ResetCRC	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SeekParm
;
;		DESCRIPTION:	Seek SI to the specified command parameter number, so 
; 						parameter start would be at 0:[Variables.CmsLine+SI]
;
;       PARAMETERS:     CL		parameter number
;
;		RETURNS:		SI		offset to parameter withing command line
;						CY		successful
;						NC		unsuccessful
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SeekParm	proc
	push ds
	push bx
;
	call DSBX2Var		
	db 9Ah
	dw 0FF1Ah
	dw 0F000h
;
	pop	bx
	pop	ds
	ret
SeekParm	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SerOut8
;
;		DESCRIPTION:	Display 8-bit value in AL to active serial console as number
;
;       PARAMETERS:     AL		value to display
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SerOut8		proc
	db 9Ah
	dw 0FF1Eh
	dw 0F000h
	ret
SerOut8		endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SerOut16
;
;		DESCRIPTION:	Display 16-bit value in AL to active serial console as number
;
;       PARAMETERS:     AX		value to display
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SerOut16	proc
	db 9Ah
	dw 0FF22h
	dw 0F000h
	ret
SerOut16	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SerOut32
;
;		DESCRIPTION:	Display 32-bit value in AL to active serial console as number
;
;       PARAMETERS:     EAX		value to display
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SerOut32	proc
	db 9Ah
	dw 0FF26h
	dw 0F000h
	ret
SerOut32	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SerOutBits
;
;		DESCRIPTION:	Display 8-bit value in AL to active serial console as bits
;
;       PARAMETERS:     AL		value to display
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SerOutBits	proc
	db 9Ah
	dw 0FF2Ah
	dw 0F000h
	ret
SerOutBits	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SerRec
;
;		DESCRIPTION:	Receive character from active serial console input with no waiting
;
;       RETURNS:		AL		character received
;						ZF		if nothing was receiver
;						NZ		character is ready in AL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SerRec	Proc near
	db 9Ah
	dw 0FF2Eh
	dw 0F000h
	ret
SerRec	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SerRecWait
;
;		DESCRIPTION:	Wait 220ms for a character from active serial console input
;
;       RETURNS:		AL		character received
;						ZF		if nothing was receiver
;						NZ		character is ready in AL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SerRecWait	Proc near
	db 9Ah
	dw 0FF32h
	dw 0F000h
	ret
SerRecWait	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SerSend2
;
;		DESCRIPTION:	Send data byte to a active serial console output
;
;       PARAMETERS:     AL		byte to send
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SerSend2	Proc near
	db 9Ah
	dw 0FF36h
	dw 0F000h
	ret
SerSend2	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SerSend
;
;		DESCRIPTION:	Send string to a active serial console output
;
;       PARAMETERS:     ES:DI	string to transmit
;	 					CX		if string is not 0-terminated, this is the length to send
;								Must be 0 if string is 0-terminated
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SerSend	Proc near
	db 9Ah
	dw 0FF3Ah
	dw 0F000h
	ret
SerSend	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			YModemGetData
;
;		DESCRIPTION:	Get ymodem data
;
;       PARAMETERS:     EDI		Linear address to place data at
;
;		RETURNS:		EDI		Next byte to receive to
;						CY		Success
;						NC		Failed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

YModemGetData	Proc near
	db 9Ah
	dw 0FF42h
	dw 0F000h
	ret
YModemGetData	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			YModemGetHeader
;
;		DESCRIPTION:	Get first block of data (filename & size) in a y-modem transfer
;
;       PARAMETERS:     CY		Success
;						NC		Failed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

YModemGetHeader	Proc near
	db 9Ah
	dw 0FF46h
	dw 0F000h
	ret
YModemGetHeader	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			YModemSendData
;
;		DESCRIPTION:	Send y-modem data
;
;       PARAMETERS:     EDI		Linear address of data
;						EAX		Size of data
;
;		RETURNS:		CY		Success
;						NC		Failed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

YModemSendData	Proc near
	db 9Ah
	dw 0FF4Ah
	dw 0F000h
	ret
YModemSendData	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			YModemSendHeader
;
;		DESCRIPTION:	Send first packet of y-modem data
;
;       PARAMETERS:     EDI		Linear address of data
;						EAX		Size of data
;
;		RETURNS:		CY		Success
;						NC		Failed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

YModemSendHeader Proc near
	db 9Ah
	dw 0FF4Eh
	dw 0F000h
	ret
YModemSendHeader Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitFlatGs
;
;		DESCRIPTION:	Init flat 32-bit gs segment register
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flat_sel	EQU 8

LoadGdt:
load_gdt0:
		 	DW 0Fh
			DD OFFSET LoadGdt + 0FFFF0000h
			DW 0
load_gdt_flat:
			DW 0FFFFh
			DD 92000000h
			DW 008Fh

InitFlatGs	Proc near
	mov eax,cs
	shl eax,4
	add eax,OFFSET LoadGdt
	mov cs:dword ptr load_gdt0+2,eax
	db 66h
	lgdt fword ptr cs:load_gdt0
;
	cli
	mov eax,cr0
	or al,1
	mov cr0,eax
	jmp short $+2
;
	mov ax,flat_sel
	mov gs,ax
;
	mov eax,cr0
	and al,NOT 1
	mov cr0,eax
	sti
	xor ax,ax
	mov gs,ax
	ret
InitFlatGs	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitNB
;
;		DESCRIPTION:	Init North bridge
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitNB  Proc near
    WriteNB 20Fh, 0
    WriteNB 11Bh, 210h
    WriteNB 11Dh, 3D0h
    WriteNB 110h, 0
    WriteNB 111h, 0
    WriteNB 112h, 0
    WriteNB 113h, 0
    WriteNB 114h, 0
    WriteNB 115h, 0
    WriteNB 117h, 0
    WriteNB 118h, 0
    WriteNB 119h, 6Bh
    WriteNB 11Ah, 220h
    WriteNB 11Eh, 0
    WriteNB 11Fh, 0
    WriteNB 120h, 0
    WriteNB 200h, 0
    WriteNB 201h, 0
    WriteNB 202h, 0
    WriteNB 204h, 0FFFFh
    WriteNB 205h, 0
    WriteNB 207h, 0FFFFh
    WriteNB 208h, 0
    WriteNB 20Ah, 0FFFFh
    WriteNB 20Bh, 0
    WriteNB 20Dh, 0FFFFh
    WriteNB 20Eh, 0
    WriteNB 20Fh, 0
    WriteNB 213h, 321h
    WriteNB 214h, 0    
    ret
InitNB  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitSB
;
;		DESCRIPTION:	Init south bridge
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitSB  Proc near
    WritePciDword 0, 12h, 0, 4, 0280000Fh
;
    ReadPciDword 0, 12h, 0, 0Ch
    and ax,0FF00h
    mov edi,eax
    WritePciDword 0, 12h, 0, 4, edi
;
    ReadPciDword 0, 12h, 0, 40h
    and eax,0FF0000h
    or eax,02000019h
    mov edi,eax
    WritePciDword 0, 12h, 0, 40h, edi
;    
    WritePciDword 0, 12h, 0, 10h, 00008101h
    WritePciDword 0, 12h, 0, 50h, 029A557Bh
;
    ReadPciDword 0, 12h, 0, 58h
    and eax,0FFFFh
    or eax,28CF0000h
    mov edi,eax
    WritePciDword 0, 12h, 0, 58h, edi
;
    ReadPciDword 0, 12h, 0, 5Ch
    xor ax,ax
    mov edi,eax
    WritePciDword 0, 12h, 0, 5Ch, edi
;    
    ReadPciDword 0, 12h, 0, 80h
    mov al,1
    mov edi,eax
    WritePciDword 0, 12h, 0, 80h, edi
;    
    ReadPciDword 0, 12h, 1, 4
    xor al,al
    mov edi,eax
    WritePciDword 0, 12h, 1, 4, edi
;
    ReadPciDword 0, 12h, 2, 4
    mov al,5
    mov edi,eax
    WritePciDword 0, 12h, 2, 4, edi
;
    ReadPciDword 0, 12h, 3, 4
    mov al,3
    mov edi,eax
    WritePciDword 0, 12h, 3, 4, edi
;
    WritePciDword 0, 12h, 3, 40h, 0FFFFFFC0h
    WritePciDword 0, 12h, 3, 10h, 00008201h
;
    ReadPciDword 0, 13h, 0, 4
    mov al,7
    mov edi,eax
    WritePciDword 0, 13h, 0, 4, edi
;
    ReadPciDword 0, 13h, 0, 0Ch
    xor ax,ax
    mov edi,eax
    WritePciDword 0, 13h, 0, 0Ch, edi     
;
    WritePciDword 0, 12h, 0, 44h, 02FE0000h
    ret
InitSB  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitDram
;
;		DESCRIPTION:	Init SDRAM
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveAx  Macro
    mov bp,ax
    shl eax,16
    mov ax,bp
        Endm

SaveBx  Macro
    mov bp,bx
    shl ebx,16
    mov bx,bp
        Endm

SaveCx  Macro
    mov bp,cx
    shl ecx,16
    mov cx,bp
        Endm

SaveDx  Macro
    mov bp,dx
    shl edx,16
    mov dx,bp
        Endm

RestoreAx   Macro
    shr eax,16
        Endm

RestoreBx   Macro
    shr ebx,16
        Endm

RestoreCx   Macro
    shr ecx,16
        Endm

RestoreDx   Macro
    shr edx,16
        Endm
        
InitDram	Proc near
    push es
    push ebp
;
    WriteNB 4, 2
    WriteNB 239h, 1249h
    WriteNB 11Ch, 0000h
;
    ReadNB 11Ah
    mov bx,ax
    or bx,7
    WriteNB 11Ah, bx
;
    xor bx,bx
    mov cx,4

check_bank_loop:
    ReadNB 119h
    mov di,ax
    and di,0FFEh
    WriteNB 119h, di
;
    WriteNB 20Fh, 0000h
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    mov bx,80h
    shl bx,cl
;
    ReadNB 20Fh
    or bx,ax
    WriteNB 20Fh, bx
;
    WriteNB 214h, 0000h
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;    
    SaveAx
    SaveCx
    xor ch,ch
    dec cl
    mov ax,3
    mul cx
    xchg ax,dx
    add dx,202h
    RestoreAx
    RestoreCx
    WriteNB dx, 0000h
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    dec cx
    mov ax,3
    mul cx
;
    xchg ax,bx
    add bx,204h
    WriteNB bx, 0FC71h        
;
    mov bx,cx
    shl bx,1
    or bx,221h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,229h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,221h
;
    mov cx,8

check_mode_loop:
    and bx,0FFE7h
    WriteNB 213h, bx
;
    or bx,18h
    WriteNB 213h, bx
    loop check_mode_loop
;
    and bx,6
    or bx,231h    
    WriteNB 213h, bx
;
    and bx,6
    or bx,220h
    WriteNB 213h, bx
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;    
    mov esi,00800000h    
    mov dword ptr gs:[esi],5A5A5A5Ah
    mov dword ptr gs:[esi+100h],0
    mov eax,gs:[esi]
    cmp eax,5A5A5A5Ah
    jz init_dram_cont
;
    WriteNB 20Fh, 0
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    mov bx,8000h
    rol bx,cl
    ReadNB 20Fh
    or bx,ax
    WriteNB 20Fh, bx
;
    WriteNB 214h, 1
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;
    SaveAx
    SaveCx
    xor ch,ch
    dec cl
    mov ax,3
    mul cx
    xchg ax,dx
    add dx,202h
    RestoreAx
    RestoreCx
;    
    WriteNB dx, 0008
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    dec cx
    mov ax,3
    mul cx
    xchg ax,bx
    add bx,204h
    WriteNB bx, 0FC71h
;
    mov bx,cx
    shl bx,1
    or bx,221h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,229h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,221h
;
    mov cx,8

l3bd:
    and bx,0FFE7h
    WriteNB 213h, bx
;
    or bx,18h
    WriteNB 213h, bx
    loop l3bd 
;
    and bx,6
    or bx,231h
    WriteNB 213h, bx
;
    and bx,6
    or bx,220h
    WriteNB 213h, bx
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;
    mov esi,00800000h    
    mov dword ptr gs:[esi],5A5A5A5Ah
    mov dword ptr gs:[esi+100h],0
    mov eax,gs:[esi]
    cmp eax,5A5A5A5Ah
    jz init_dram_cont
;
    dec cx
    jnz check_bank_loop       
;   
    jmp check_bank_done

init_dram_cont:
    ReadNB 119h
    or ax,1
    mov di,ax
    WriteNB 119h, di
;
    ReadNB 20Fh
    or bx,ax
;
    SaveAx
    SaveCx
    xor ch,ch
    dec cl
    mov ax,3
    mul cx
    xchg ax,dx
    add dx,202h
    RestoreAx
    RestoreCx
;
    ReadNB dx
    or ax,2A00h
    mov di,ax
;
    mov esi,4
        
check_bank_col_loop:
    WriteNB dx, di

check_bank_mem_loop:
    mov ebp,00800000h    
    mov dword ptr gs:[ebp],1A56E2C6h
    mov dword ptr gs:[esi+ebp],5A5A5A5Ah
    mov eax,gs:[ebp]
    cmp eax,1A56E2C6h
    jnz check_bank_first_failed
;
    mov eax,gs:[esi+ebp]
    cmp eax,5A5A5A5Ah
    jnz check_bank_next
;
    shl esi,1
    cmp esi,ebp
    jnz check_bank_mem_loop
;
    shr esi,1
    jmp check_bank_next

check_bank_first_failed:
    mov eax,esi
    cmp eax,1000000h
    ja check_bank_next
;
    shl eax,1    
    test bx,0FFh
    jz check_bank_col_ok
;
    shl eax,1

check_bank_col_ok:
    and ax,3000h
    and di,0CFFFh
    or di,ax
    mov esi,4
    jmp check_bank_col_loop

check_bank_next:
    shr esi,17
    bsf eax,esi
    dec ax
    shl ax,9
    and di,0F1FFh
    or di,ax
;
    WriteNB 20Fh, 0
;
    and si,0FFh
    or di,si
    WriteNB dx, di
;
    dec cl
    jnz check_bank_loop

check_bank_done:
    call CRLF
;
    ReadNB 119h
    or ax,1
    mov di,ax
    WriteNB 119h, di
;
    WriteNB 20Fh, 0000h
;
    mov cx,1
    mov di,1
    xor dx,dx
    mov es,dx

setup_bank_loop:
    mov ch,cl
    test bx,cx
    jz l622
;
    xchg cx,di
    SaveAx
    SaveCx
    xor ch,ch
    dec cl
    mov ax,3
    mul cx
    xchg ax,dx
    add dx,202h
    RestoreAx
    RestoreCx 
    xchg cx,di
    ReadNB dx
;           
    mov si,ax
    and si,000FFh
    and ax,0FF00h
    mov dx,es
    add ax,dx
    add dx,si
    mov es,dx
    mov si,ax
;
    xchg cx,di
    SaveAx
    SaveCx
    xor ch,ch
    dec cl
    mov ax,3
    mul cx
    xchg ax,dx
    add dx,202h
    RestoreAx
    RestoreCx
    xchg cx,di
    WriteNB dx, si

l622:
    cmp di,4
    jz l62d
;
    shl cl,1
    inc di
    jmp setup_bank_loop

l62d:
    mov cx,1
    mov di,1

l633:
    test bl,cl
    jz l7b2
;
    xchg cx,di
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    mov bx,8000h
    rol bx,cl
;
    ReadNB 20Fh
    or bx,ax
    WriteNB 20Fh, bx
;
    WriteNB 214h, 0001h
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    dec cx
    mov ax,3
    mul cx
    xchg ax,bx
    add bx,204h
    WriteNB bx, 0FC71h
;
    mov bx,cx
    shl bx,1
    or bx,221h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,229h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,221h
;
    mov cx,8

l763:
    and bx,0FFE7h
    WriteNB 213h, bx
; 
    or bx,18h
    WriteNB 213h, bx
    loop l763
;
    and bx,6
    or bx,231h
    WriteNB 213h, bx
;
    and bx,6
    or bx,220h
    WriteNB 213h, bx
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
    xchg cx,di
    jmp l92e

l7b2:
    test cl,bh
    jz l92e
;
    xchg cx,di
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    mov bx,80h
    rol bx,cl
;
    ReadNB 20Fh
    or bx,ax
    WriteNB 20Fh, bx
;
    WriteNB 214h, 0000h
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    dec cx
    mov ax,3
    mul cx
    xchg ax,bx
    add bx,204h
    WriteNB bx, 0FC71h
;
    mov bx,cx
    shl bx,1
    or bx,221h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,229h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,221h
;
    mov cx,8

l8e2:
    and bx,0FFE7h
    WriteNB 213h, bx
; 
    or bx,18h
    WriteNB 213h, bx
    loop l8e2
;
    and bx,6
    or bx,231h
    WriteNB 213h, bx
;
    and bx,6
    or bx,220h
    WriteNB 213h, bx
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
    xchg cx,di

l92e:
    cmp di,4
    jz l939
;
    shl cl,1
    inc di
    jmp l633

l939:
    SaveAx
    SaveCx
;
    WriteNB 211h, 0000h
;
    mov cx,-1
    
init_dram_delay:   
    loop init_dram_delay
;
    RestoreAx
    RestoreCx
;
    ReadNB 21Ah
    and ax,0FFF8h
    mov di,ax
    WriteNB 21Ah, di
;
    ReadNB 20Fh
    call SerOut16
    call CRLF
;
    pop ebp
    pop es
    ret
InitDram	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Main
;
;		DESCRIPTION:	main procedure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Main	Proc far
	call InitFlatGs
;
    call InitNB
    call InitSB
	call InitDram
	ret
Main	Endp	

	END Startup
