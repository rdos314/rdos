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
; FLASH.ASM
; BUR flash programmer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME flash

.model tiny
.code
.386p

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
;		NAME:			SlowISA
;
;		DESCRIPTION:    Set slow ISA speed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SlowISA	proc near
	pushf
	cli
	mov eax,80009050h
	mov dx,0CF8h
	out dx,eax
	mov dx,0CFCh
	in al,dx
	or al,7		; set divisor to 8
	out dx,al
	popf
	ret
SlowISA	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RecIn32
;
;		DESCRIPTION:	Receive a 32-bit hex-number
;
;       RETURNS:        EAX     value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecIn32 Proc near

    xor edx,edx
    mov cx,8

rec_wait_loop:
    call SerRecWait
    jz rec_wait_loop
;
    call SerSend2
    sub al,'0'
    jc rec_in32_done
;
    cmp al,10
    jc rec_in32_add
;
    add al,'0'
    sub al,'A'
    jc rec_in32_done
;
    cmp al,6
    jnc rec_in32_done
;
    add al,10

rec_in32_add:
    shl edx,4
    or dl,al
;
    loop rec_wait_loop
    
rec_in32_done:
    call CRLF
    mov eax,edx   
    ret
RecIn32 Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MapFlash
;
;		DESCRIPTION:	Map the flash chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapFlash Proc near
    mov dx,218h
    mov al,26h
    out dx,al
    mov dx,21Ah
    mov eax,0C0000h
    out dx,eax
;
    mov dx,218h
    mov al,2Ah
    out dx,al
    mov dx,21Ah
    mov eax,1FFFFh
    out dx,eax
;
    mov dx,218h
    mov al,2Eh
    out dx,al
    mov dx,21Ah
    mov eax,0FFF40000h
    out dx,eax
;
	mov al,5Ah
	mov dx,218h
	out dx,al
	mov dx,219h
	in al,dx
	and al,011101110b
;
    push ax
	mov dx,218h
	mov al,5Ah
	out dx,al
	mov dx,219h
	pop ax
	out dx,al
;
    ret
MapFlash    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IdentifyFlash
;
;		DESCRIPTION:	Identify type of flash device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InvalidDeviceStr DB 'Unknown flash device ', 0Dh, 0Ah, 0

IdentifyFlash   Proc near
    mov esi,0C0000h
;
	mov al,0AAh
	mov si,555h SHL 1
	mov gs:[esi],al
;
	mov al,55h
	mov si,2AAh SHL 1
	mov gs:[esi],al
;
    mov al,90h
	mov si,555h SHL 1
	mov gs:[esi],al
;
    xor si,si
    mov eax,gs:[esi]
    mov byte ptr gs:[esi],0F0h
;
	cmp eax,22D80001h
	je ident_ok
;
	cmp eax,224A0001h
	je ident_ok
;
	cmp eax,22CB0001h
	je ident_ok
;
	cmp eax,22D60001h
	je ident_ok
;
	cmp eax,22580001h
	je ident_ok
;
	cmp eax,22D20001h
	je ident_ok
;
	cmp eax,22D70001h
	je ident_ok
;
	cmp eax,22560001h
	je ident_ok
;
	cmp eax,22530001h
	je ident_ok
;
	cmp eax,225F0001h
	je ident_ok
;
	call SerOut32
	call CRLF
	xor cx,cx
	push cs
	pop es
	mov di,OFFSET InvalidDeviceStr
	xor cx,cx
	call SerSend
    stc
    ret

ident_ok:
    clc
    ret
IdentifyFlash   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EraseSector
;
;		DESCRIPTION:	Erase a single 4k block
;
;       PARAMETERS:     EDX     Sector address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EraseSector   Proc near
    push edx
    mov esi,0C0000h
;
	mov al,0AAh
	mov si,555h SHL 1
	mov gs:[esi],al
;
	mov al,55h
	mov si,2AAh SHL 1
	mov gs:[esi],al
;
    mov al,80h
	mov si,555h SHL 1
	mov gs:[esi],al
;
	mov al,0AAh
	mov si,555h SHL 1
	mov gs:[esi],al
;
	mov al,55h
	mov si,2AAh SHL 1
	mov gs:[esi],al
;
    push edx
    mov dx,218h
    mov al,2Eh
    out dx,al
    pop eax
    mov dx,21Ah
    sub eax,0C0000h
    and ax,0F000h
    out dx,eax
;    
    xor si,si
    mov al,30h
    mov gs:[esi],al
;
    mov dx,218h
    mov al,2Eh
    out dx,al
    mov dx,21Ah
    mov eax,0FFF40000h
    out dx,eax
;
    pop edx
    ret
EraseSector   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ProgramWord
;
;		DESCRIPTION:	Program a single location
;                       
;       PARAMETERS:     EDX     Address
;                       AX      Data
;
;       RETURNS:        ZR      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProgramWord   Proc near
    push edx
;
    push ax
    mov esi,0C0000h
;
	mov al,0AAh
	mov si,555h SHL 1
	mov gs:[esi],al
;
	mov al,55h
	mov si,2AAh SHL 1
	mov gs:[esi],al
;
    mov al,0A0h
	mov si,555h SHL 1
	mov gs:[esi],al
;
    push edx
    mov dx,218h
    mov al,2Eh
    out dx,al
    pop eax
    mov dx,21Ah
    mov si,ax
    and si,0FFFh
    sub eax,0C0000h
    and ax,0F000h
    out dx,eax
;
    pop ax
    push ax
    mov gs:[esi],ax
;
    mov al,gs:[esi]

wait_program_loop:
    mov ah,gs:[esi]
    xor al,ah
    test al,40h
    jz program_verify
;
    mov al,ah
    jmp wait_program_loop

program_verify:
    pop ax
    cmp ax,gs:[esi]
    pushf    
;
    mov dx,218h
    mov al,2Eh
    out dx,al
    mov dx,21Ah
    mov eax,0FFF40000h
    out dx,eax
    popf
    pop edx
    ret
ProgramWord   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitForErase
;
;		DESCRIPTION:	Wait for erase complete
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForErase   Proc near
    mov esi,0C0000h
    mov al,gs:[esi]

wait_erase_loop:
    mov ah,gs:[esi]
    xor al,ah
    test al,40h
    jz wait_erase_done
;
    mov al,ah
    jmp wait_erase_loop

wait_erase_done:
    ret
WaitForErase    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Erase
;
;		DESCRIPTION:	Erase needed sectors
;
;       PARAMETERS:     ECX     size to erase (from top)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Erase   Proc near
    push ecx
    or ecx,ecx
    jz erase_done
    test cl,1
    jz erase_even
;
    inc ecx

erase_even:
    mov edx,200000h
    sub edx,ecx
    and dx,0F000h

erase_more:
    call EraseSector
    add edx,1000h
    cmp edx,200000h
    jne erase_more
;
    call WaitForErase

erase_done:
    pop ecx
    ret
Erase   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Program
;
;		DESCRIPTION:	Program all
;
;       PARAMETERS:     ECX     size to program (from top)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProgramFailedText	DB 'Program failed at: ', 0

Program   Proc near
    or ecx,ecx
    jz program_done
;
    mov edi,2000h
    test cl,1
    jz program_even
;
    inc ecx
    dec edi

program_even:
    mov edx,200000h
    sub edx,ecx

program_more:
    mov ax,gs:[edi]
    call ProgramWord
    je program_next
;
	xor cx,cx
	push cs
	pop es
	mov di, OFFSET ProgramFailedText
	call SerSend
;
    mov eax,edx
    call SerOut32
    call CRLF
    jmp program_done    

program_next:
    add edi,2
    add edx,2
    sub ecx,2
    jnz program_more

program_done:
    ret
Program   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Main
;
;		DESCRIPTION:	main procedure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EntryText	DB 'Enter size: ', 0

Main	Proc far
	call InitFlatGs
	call SlowISA
	call MapFlash
	call IdentifyFlash
    jc done
;
	xor cx,cx
	push cs
	pop es
	mov di, OFFSET EntryText
	call SerSend
    call RecIn32
;
    mov ecx,eax
    call Erase
    call Program
;
    mov dx,218h
    mov al,26h
    out dx,al
    mov dx,21Ah
    mov eax,0C0000h
    out dx,eax
;
    mov dx,218h
    mov al,2Ah
    out dx,al
    mov dx,21Ah
    mov eax,1FFFFh
    out dx,eax
;
    mov dx,218h
    mov al,2Eh
    out dx,al
    mov dx,21Ah
    mov eax,120000h
    out dx,eax

done:
	ret
Main	Endp	

	END Startup
