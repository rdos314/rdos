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
; AR-B1320.ASM
; AR-B1320 module support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
        NAME arb1320
        
GateSize = 16

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def


	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CalcCrc
;
;		DESCRIPTION:	Calculate CRC for a byte
;
;       PARAMETERS:     AL      CRC
;                       DS:ESI  Data
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
;		NAME:			GetAdapter
;
;		DESCRIPTION:
;
;		PARAMETERS:     ESI     Adress to start search at
;						EDI		Max address to search at
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
	cmp esi,edi
	jb GetAdapterSearch
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
	je GetAdapterSignOk
	jmp GetAdapterCorrupt
GetAdapterSignOk:
	cmp [esi].typ,RdosEnd
	je GetAdapterOk
	mov edx,[esi].len
	add ecx,edx
	cmp ecx,1000000h
	jc GetAdapterSizeOk
	jmp GetAdapterCorrupt
GetAdapterSizeOk:
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
	je GetAdapterCrcOk
	jmp GetAdapterCorrupt
GetAdapterCrcOk:
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
;		DESCRIPTION:
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
	add ecx,SIZE rdos_header
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
;		DESCRIPTION:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAllAdapters  Proc near
	mov bx,flash_disc_sel
	GetSelectorBaseSize
	mov esi,edx
	mov edi,edx
	add edi,ecx
;
    mov ax,system_data_sel
    mov ds,ax
    mov ax,ds:rom_modules
    mov bx,SIZE adapter_typ
    mul bx
    mov bx,ax
    add bx,OFFSET rom_adapters
    
get_adapters_loop:
    call GetAdapter
    jc get_adapters_done
;
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			test_pr
;
;		DESCRIPTION:	Test thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_name	DB 'Flash thread',0

test_pr Proc far
	sti
	int 3
;    	
	ret
test_pr Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_thread
;
;		DESCRIPTION:	Init threads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread	PROC far
	push ds
	push es
	pusha
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET test_pr
	mov di,OFFSET test_name
	mov cx,500
	mov ax,4
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:	Initialize module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
;
	mov bx,flash_disc_code_sel
	InitDevice
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET init_thread
	HookInitTasking
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
    mov eax,80000h
    AllocateBigLinear
    mov bx,flash_disc_sel
    mov ecx,eax
    CreateDataSelector32
;
    mov ax,flat_sel
    mov ds,ax
;
    mov ax,flash_disc_sel
    mov es,ax 
    xor edi,edi
;   
    mov dx,210h
    mov bl,80h
    mov cx,40h

load_loop:
    mov al,bl
    out dx,al
;
    push ecx
    mov ecx,800h
    mov esi,0C8000h    
    rep movs dword ptr es:[edi],[esi]
    pop ecx
;
    inc bl
    loop load_loop
;
    xor al,al
    out dx,al 
;
    call GetAllAdapters
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
