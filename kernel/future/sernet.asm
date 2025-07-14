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
; SERNET.ASM
; SERNETP protocol driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
						
		NAME sernet

MAX_DATA_SIZE	= 512

packet_header	STRUC

PacketMagic		DB ?
PacketType		DB ?
PacketSource	DB ?
PacketDest		DB ?

packet_header	ENDS

data_packet	STRUC

DataHeader	packet_header <>
DataSize	DW ?
DataType	DW ?
DataBytes	DB MAX_DATA_SIZE DUP(?)
DataCrc		DW ?

data_packet	ENDS

sernet_data_seg	SEGMENT AT 0

node			DB ?
irq				DB ?
port            DW ?
base			DW ?
baud			DW ?

Handle			DW ?
SendSection		section_typ <>

SendCount		DW ?
SendBytePtr		DW ?

LastMsgTime		DD ?,?
FrameBase		DD ?,?
FrameDuration	DD ?
FramePeriod		DD ?

CharTics		DD ?
MasterTics		DD ?
SlotTics		DD ?
MaxPacketTics	DD ?

DefaultFrame	DW ?
SlotCount		DB ?

Mode			DB ?

MasterNode		DB ?
CurrentNode		DB ?
NodeCount		DB ?
FrameArr		DB MAX_NODES DUP(?)

SyncHeader		packet_header <>
SyncSlotTime	DW ?
SyncCrc			DW ?

ReqHeader		packet_header <>
ReqCrc			DW ?

ReplyHeader		packet_header <>
ReplyFrame		DB ?
ReplyCount		DB ?
ReplyCrc		DW ?

SendHead		DW ?
SendTail		DW ?

SendPacket1		data_packet <>
SendPacket2		data_packet <>

RecTime			DD ?,?
RecSize			DW ?
RecCount		DW ?
RecPtr			DW ?
RecHead			DW ?
RecTail			DW ?
RecPacketHandler DW ?

RecPacket1		data_packet <>
RecPacket2		data_packet <>

sernet_data_seg	ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

	assume cs:code

	.386c

MAGIC_NUMBER	 = 9Bh

MSG_TYPE_INIT	 = 7Ch
MSG_TYPE_REQ     = 7Dh
MSG_TYPE_REPLY   = 7Eh
MSG_TYPE_DATA    = 7Fh

SOURCE_BIAS      = 2Ch
DEST_BIAS		 = 0ACh

BROADCAST_ADS	 = 0ABh
MAX_NODES		 = 40h

MAX_INIT_INTERVAL = 5 * 1193000
MAX_FRAMES        = 1000

MODE_REC_BUSY	   = 1
MODE_SEND_BUSY     = 2
MODE_ONLINE		   = 4
MODE_ENABLED	   = 8
MODE_REC_MY_PACKET = 10h
MODE_REC_DISCARD   = 20h
MODE_LEN_LOW	   = 40h
MODE_LEN_HIGH	   = 80h

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetEnvString
;
;		description:	Find an enviroment variable
;
;		PARAMETERS:		ES:DI		var name
;
;		RETURNS:		NC			found
;							DS:SI	address of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetEnvString	proc near
    push bx
;
	LockSysEnv
	mov ds,bx
	xor si,si
	mov ax,cs
find_var_str_loop:
	mov al,[si]
	or al,al
	stc
	jz find_var_str_done
	push di
find_var_char_str_loop:
	cmpsb
	jnz find_var_str_next
	mov al,es:[di]
	or al,al
	jnz find_var_char_str_loop
	mov al,[si]
	cmp al,'='
	je find_var_str_found

find_var_str_next:
	lodsb
	or al,al
	jnz find_var_str_next
	pop di
	jmp find_var_str_loop

find_var_str_found:
	pop di
	inc si
	clc
find_var_str_done:
    pushf
    UnlockSysEnv
    popf
;
    pop bx
	ret
GetEnvString	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetEnvInt
;
;		description:	Find an enviroment variable
;
;		PARAMETERS:		ES:DI		var name
;
;		RETURNS:		NC			found
;							EAX		value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetEnvInt	proc near
	push ds
	push ecx
	push edx
	push si
	call GetEnvString
	pushf
	xor eax,eax
	xor ecx,ecx
	popf
	jc get_env_int_done
get_env_int_loop:
	mov cl,[si]
	or cl,cl
	jz get_env_int_done
	cmp cl,'0'
	jc get_env_int_done
	cmp cl,'9'
	ja get_env_int_done
	mov cl,10
	mul ecx
	mov cl,[si]
	sub cl,'0'
	inc si
	add eax,ecx
	jmp get_env_int_loop

get_env_int_done:	
	pop si
	pop edx
	pop ecx
	pop ds
	ret
GetEnvInt	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LCalcCrc
;
;		DESCRIPTION:	CALCULATE CRC-SUM X^16 + X^12 + X^5 + 1
;
;		PARAMETERS:		DS:BX		Buffer
;						CX			Size
;
;		RESULT:			AX = CRCSUMMA
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LCalcCrc	PROC near
	push bx
	push cx
	xor ax,ax
crc_loop:
	xor ah,[bx]
	inc bx
	shl ax,1
	jnc no_xor0
	xor ax,1021h
no_xor0:
	shl ax,1
	jnc no_xor1
	xor ax,1021h
no_xor1:
	shl ax,1
	jnc no_xor2
	xor ax,1021h
no_xor2:
	shl ax,1
	jnc no_xor3
	xor ax,1021h
no_xor3:
	shl ax,1
	jnc no_xor4
	xor ax,1021h
no_xor4:
	shl ax,1
	jnc no_xor5
	xor ax,1021h
no_xor5:
	shl ax,1
	jnc no_xor6
	xor ax,1021h
no_xor6:
	shl ax,1
	jnc no_xor7
	xor ax,1021h
no_xor7:
	loop crc_loop
	pop cx
	pop bx
	ret
LCalcCrc	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartSend
;
;		DESCRIPTION:    Start sending a message
;
;		PARAMETERS:		BX		Pointer to header
;						CX		Size of data part
;
;		RETURNS:		NC		Sent
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartSend	Proc near
	test ds:Mode, MODE_REC_BUSY
	stc
	jnz start_send_done
;
	or ds:Mode, MODE_SEND_BUSY
	push ax
	push cx
	push dx
;
	add cx,SIZE packet_header
	call LCalcCrc
	xchg al,ah
	push bx
	add bx,cx
	mov [bx],ax
	pop bx
;
	add cx,2
	mov ds:SendCount,cx
	mov ds:SendBytePtr,bx
	mov dx,ds:base
	inc dx
	mov al,3
	out dx,al
;
	add dx,3
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
;
	pop dx
	pop cx
	pop ax
	clc

start_send_done:
	ret
StartSend	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendInitMsg
;
;		DESCRIPTION:    Send an init message
;
;		RETURNS:		NC	sent
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInitMsg	Proc near
	mov al,ds:node
	mov bx,OFFSET SyncHeader
	add al,SOURCE_BIAS
	mov ds:[bx].PacketSource,al
	mov ds:[bx].PacketDest,BROADCAST_ADS
	mov ds:[bx].PacketMagic,MAGIC_NUMBER
	mov ds:[bx].PacketType,MSG_TYPE_INIT
	mov ax,ds:DefaultFrame
	xchg al,ah
	mov ds:SyncSlotTime,ax
	mov cx,2
	call StartSend
	jc send_init_msg_done
;
	GetSystemTime
	and ds:Mode, NOT MODE_ENABLED
	mov ds:NodeCount,0
	mov ds:LastMsgTime,eax
	mov ds:LastMsgTime+4,edx
	mov ds:FrameBase,eax
	mov ds:FrameBase+4,edx
	mov eax,ds:SlotTics
	mov ebx,MAX_NODES + 1
	mul ebx
	add eax,ds:LastMsgTime
	adc edx,ds:LastMsgTime+4
	mov bx,cs
	mov es,bx
	mov di,OFFSET InitTimeout
	StopTimer
	xor bx,bx
	StartTimer
	clc

send_init_msg_done:
	ret
SendInitMsg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReplyTimeout
;
;		DESCRIPTION:    Send reply timeout expired
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReplyTimeout	Proc far
	mov bx,sernet_data_sel
	mov ds,bx
	mov al,ds:node
	mov bx,OFFSET ReplyHeader
	add al,SOURCE_BIAS
	mov ds:[bx].PacketSource,al
	mov al,ds:CurrentNode
	movzx si,al
	inc al
	mov ds:CurrentNode,al
	mov ds:ReplyFrame,al
	mov al,ds:[si].FrameArr
	add al,DEST_BIAS
	mov ds:[bx].PacketDest,al
	mov ds:[bx].PacketMagic,MAGIC_NUMBER
	mov ds:[bx].PacketType,MSG_TYPE_REPLY
	mov al,ds:NodeCount
	inc al
	mov ds:ReplyCount,al
	mov cx,2
	call StartSend
;
	mov al,ds:CurrentNode
	cmp al,ds:NodeCount
	je reply_timeout_enable
;
	mov eax,ds:LastMsgTime
	mov edx,ds:LastMsgTime+4
	add eax,ds:SlotTics
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET ReplyTimeout
	xor bx,bx
	StartTimer
	jmp reply_timeout_done

reply_timeout_enable:
	mov al,ds:NodeCount
	inc al
	mov ds:SlotCount,al
	movzx eax,al
	mul ds:SlotTics
	mov ds:FramePeriod,eax
;
	movzx eax,ds:SlotCount
	add eax,MAX_NODES + 1
	mul ds:SlotTics
	add eax,ds:FrameBase
	adc edx,ds:FrameBase+4
	mov bx,cs
	mov es,bx
	mov di,OFFSET DataTimeout
	StopTimer
	StartTimer
	or ds:Mode, MODE_ENABLED

reply_timeout_done:
	ret
ReplyTimeout	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitTimeout
;
;		DESCRIPTION:    Init timeout expired
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTimeout	Proc far
	mov bx,sernet_data_sel
	mov ds,bx
	mov al,ds:NodeCount
	or al,al
	jz init_timeout_done
;
	or ds:Mode, MODE_ONLINE
	mov ds:CurrentNode,0
	mov eax,ds:LastMsgTime
	mov edx,ds:LastMsgTime+4
	add eax,ds:SlotTics
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET ReplyTimeout
	xor bx,bx
	StartTimer

init_timeout_done:
	ret
InitTimeout	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DataTimeout
;
;		DESCRIPTION:    Data timeout expired
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DataTimeout	Proc far
	mov bx,sernet_data_sel
	mov ds,bx
	test ds:Mode, MODE_ENABLED
	jz data_timeout_done
;
	sub eax,ds:FrameBase
	sbb edx,ds:FrameBase+4
	cmp eax,ds:FrameDuration
	jae data_reinit
;
	add eax,ds:FrameBase
	adc edx,ds:FrameBase+4
	add eax,ds:FramePeriod
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET DataTimeout
	StartTimer
;
	test ds:Mode, MODE_REC_BUSY
	jnz data_timeout_done
;
	mov bx,ds:SendHead
	mov al,[bx]
	or al,al
	jz data_send_dummy
;
	mov cx,[bx].DataSize
	xchg cl,ch
	add cx,4
	call StartSend
	add bx,SIZE data_packet
	cmp bx,OFFSET SendPacket2
	jbe data_timeout_save
;
	mov bx,OFFSET SendPacket1

data_timeout_save:
	mov ds:SendHead,bx
	jmp data_timeout_done

data_send_dummy:
	jmp data_timeout_done
	cli
	mov dx,ds:base
	mov al,'A'
	out dx,al
;
	inc dx
	mov al,3
	out dx,al
;
	add dx,3
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
	sti
	jmp data_timeout_done

data_reinit:
	test ds:Mode, MODE_REC_BUSY OR MODE_SEND_BUSY
	jnz data_timeout_reload
;
	push eax
	push edx
	call SendInitMsg
	pop edx
	pop eax
	jnc data_timeout_done

data_timeout_reload:
	add eax,ds:FrameBase
	adc edx,ds:FrameBase+4
	add eax,ds:FramePeriod
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET DataTimeout
	StartTimer

data_timeout_done:
	ret
DataTimeout	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MasterTimeout
;
;		DESCRIPTION:    Master timeout expired
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MasterTimeout	Proc far
	mov bx,sernet_data_sel
	mov ds,bx
	GetSystemTime
	mov ecx,eax
	sub ecx,ds:LastMsgTime
	cmp ecx,ds:MasterTics
	jb master_timeout_reload
;
	and ds:Mode, NOT MODE_ONLINE
	call SendInitMsg

master_timeout_reload:
	mov eax,ds:LastMsgTime
	mov edx,ds:LastMsgTime+4
	add eax,ds:MasterTics
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET MasterTimeout
	xor bx,bx
	StartTimer
	ret
MasterTimeout	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReqTimeout
;
;		DESCRIPTION:    Request timeout expired
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqTimeout	Proc far
	mov bx,sernet_data_sel
	mov ds,bx
	mov bx,OFFSET ReqHeader
	mov al,ds:node
	add al,SOURCE_BIAS
	mov ds:[bx].PacketSource,al
	mov al,ds:MasterNode
	add al,DEST_BIAS
	mov ds:[bx].PacketDest,al
	mov ds:[bx].PacketMagic,MAGIC_NUMBER
	mov ds:[bx].PacketType,MSG_TYPE_REQ
	xor cx,cx
	call StartSend
	ret
ReqTimeout	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RecReset
;
;		DESCRIPTION:    Reset receive mode busy
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecReset	Proc near
	mov ds:RecCount,0
	and ds:Mode, NOT MODE_REC_BUSY
	mov bx,ds
	StopTimer
	ret
RecReset	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MODEM
;
;		DESCRIPTION:    Modem control line changed
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

modem	Proc near
	mov dx,ds:base
	add dx,6
	in al,dx
	ret
modem	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LINE_ERR
;
;		DESCRIPTION:    Line error
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

line_err	PROC near
	mov dx,ds:base
	add dx,5
	in al,dx
	test ds:Mode, MODE_REC_BUSY
	jz line_error_done
;
	call RecReset

line_error_done:
	ret
line_err	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RecTimeout
;
;		DESCRIPTION:    Timeout on receive
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecTimeout	Proc far
	mov ax,sernet_data_sel
	mov ds,ax
	mov ds:RecCount,0
	and ds:Mode, NOT MODE_REC_BUSY
	ret
RecTimeout	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HandleInit
;
;		DESCRIPTION:	Handle init packet
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleInit	Proc near
	and ds:Mode,NOT MODE_ENABLED
	or ds:Mode,MODE_ONLINE
	mov bx,ds:RecPtr
	mov al,[bx].PacketSource
	sub al,SOURCE_BIAS
	mov ds:MasterNode,al
;
	mov eax,ds:SlotTics
	movzx ebx,ds:node
	mul ebx
	mov ebx,ds:RecTime
	mov ds:FrameBase,ebx
	add eax,ebx
	mov ebx,ds:RecTime+4
	mov ds:FrameBase+4,ebx
	adc edx,ebx
	mov bx,cs
	mov es,bx
	mov di,OFFSET ReqTimeout
	StopTimer
	StartTimer
	ret
HandleInit	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HandleReq
;
;		DESCRIPTION:	Handle req packet
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleReq	Proc near
	mov bx,ds:RecPtr
	mov al,ds:[bx].PacketSource
	sub al,SOURCE_BIAS
	movzx bx,ds:NodeCount
	mov ds:[bx].FrameArr,al
	inc bl
	mov ds:NodeCount,bl
	ret
HandleReq	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HandleReply
;
;		DESCRIPTION:	Handle reply packet
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleReply	Proc near
	mov bx,ds:RecPtr
	mov al,[bx].PacketSource
	sub al,SOURCE_BIAS
	cmp al,ds:MasterNode
	jne handle_reply_done
;
	add bx,SIZE packet_header
	mov al,[bx+1]
	mov ds:SlotCount,al
	movzx eax,byte ptr [bx]
	movzx ebx,ds:SlotCount
	add eax,ebx
	add eax,MAX_NODES + 1
	mul ds:SlotTics
	add eax,ds:FrameBase
	adc edx,ds:FrameBase+4
	mov bx,cs
	mov es,bx
	mov di,OFFSET DataTimeout
	StopTimer
	StartTimer
	or ds:Mode, MODE_ENABLED
;
	movzx eax,ds:SlotCount
	mul ds:SlotTics
	mov ds:FramePeriod,eax

handle_reply_done:
	ret
HandleReply	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HandleData
;
;		DESCRIPTION:	Handle data packet
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleData	Proc near
	mov bx,ds:RecTail
	add bx,SIZE data_packet
	cmp bx,OFFSET RecPacket2
	jbe handle_data_save_tail
;
	mov bx,OFFSET RecPacket1

handle_data_save_tail:
	cmp bx,ds:RecHead
	jne handle_data_notify
;
	mov bx,ds:RecTail

handle_data_notify:
	mov ds:RecTail,bx
	mov ds:RecPtr,bx
;
	mov bx,ds:Handle
	NetReceived
	ret
HandleData	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Type callbacks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckInitPacket	Proc near
	mov ds:RecSize,4 + SIZE packet_header
	mov ds:RecPacketHandler, OFFSET HandleInit
	ret
CheckInitPacket	Endp

CheckReqPacket	Proc near
	mov ds:RecSize,2 + SIZE packet_header
	mov ds:RecPacketHandler, OFFSET HandleReq
	ret
CheckReqPacket	Endp

CheckReplyPacket	Proc near
	mov ds:RecSize,4 + SIZE packet_header
	mov ds:RecPacketHandler, OFFSET HandleReply
	ret
CheckReplyPacket	Endp

CheckDataPacket	Proc near
	or ds:Mode,MODE_LEN_LOW OR MODE_LEN_HIGH
	mov ds:RecPacketHandler, OFFSET HandleData
	ret
CheckDataPacket	Endp

type_callb_tab:
tct7C DW OFFSET CheckInitPacket
tct7D DW OFFSET CheckReqPacket
tct7E DW OFFSET CheckReplyPacket
tct7F DW OFFSET CheckDataPacket

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Header callbacks
;
;		PARAMETERS:		AL		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckMagic	Proc near
	and ds:Mode,NOT (MODE_REC_MY_PACKET OR MODE_REC_DISCARD)
	or ds:Mode,MODE_REC_BUSY
	GetSystemTime
	sub eax,ds:CharTics
	sbb edx,0
	mov ds:RecTime,eax
	mov ds:RecTime+4,edx
	add eax,ds:MaxPacketTics
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET RecTimeout
	mov bx,ds
	StopTimer
	StartTimer
	ret
CheckMagic	Endp

CheckType	Proc near
	sub al,7Ch
	movzx bx,al	
	add bx,bx
	call word ptr cs:[bx].type_callb_tab
	ret
CheckType	Endp

CheckSource	Proc near
	sub al,SOURCE_BIAS
	cmp al,ds:node
	jne check_source_ok
;
	or ds:Mode,MODE_REC_DISCARD

check_source_ok:
	ret
CheckSource	Endp

CheckDest	Proc near
	sub al,DEST_BIAS
	cmp al,ds:node
	je check_dest_ok
;
	cmp al,-1
	jne check_dest_done

check_dest_ok:
	or ds:Mode,MODE_REC_MY_PACKET

check_dest_done:
	ret
CheckDest	Endp

header_callb_tab:
hct00 DW OFFSET CheckMagic
hct01 DW OFFSET CheckType
hct02 DW OFFSET CheckSource
hct03 DW OFFSET CheckDest

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REC_PR
;
;		DESCRIPTION:    Received data
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rec_len_tab:
rt00 DB -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
rt10 DB -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
rt20 DB -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  2,  2,  2
rt30 DB  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2
rt40 DB  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2
rt50 DB  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2
rt60 DB  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2, -1, -1, -1
rt70 DB -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  1,  1,  1,  1
rt80 DB -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
rt90 DB -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,	 0,	-1, -1, -1, -1
rtA0 DB -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  3, -1,  3,  3,  3
rtB0 DB  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3
rtC0 DB  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3
rtD0 DB  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3
rtE0 DB  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, -1, -1, -1
rtF0 DB -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1

rec_pr	PROC near
	mov dx,ds:base
	in al,dx
;
	mov cx,ds:RecCount
	cmp cx,4
	jae rec_data
;
	movzx bx,al
	mov ah,byte ptr cs:[bx].rec_len_tab
	cmp cl,ah
	jne rec_error
;
	mov bx,ds:RecPtr
	add bx,cx
	mov [bx],al
	mov bx,cx
	add bx,bx
	call word ptr cs:[bx].header_callb_tab
	inc ds:RecCount
	jmp rec_done

rec_data:
	mov bx,ds:RecPtr
	add bx,cx
	mov [bx],al
;
	test ds:Mode, MODE_LEN_HIGH
	jz rec_high_ok
;
	inc ds:RecCount
	and ds:Mode, NOT MODE_LEN_HIGH
	mov byte ptr ds:RecSize+1,al
	jmp rec_done

rec_high_ok:
	test ds:Mode, MODE_LEN_LOW
	jz rec_not_data_size
;
	inc ds:RecCount
	and ds:Mode, NOT MODE_LEN_LOW
	mov ah,byte ptr ds:RecSize+1
	cmp ax,MAX_DATA_SIZE
	ja rec_error
;
	add ax,6 + SIZE packet_header
	mov ds:RecSize,ax
	jmp rec_done

rec_not_data_size:
	inc cx
	mov ds:RecCount,cx
	cmp cx,ds:RecSize
	jne rec_done
;
	test ds:Mode, MODE_REC_MY_PACKET
	jz rec_error
;
	test ds:Mode, MODE_REC_DISCARD
	jnz rec_error
;
	sub cx,2
	mov bx,ds:RecPtr
	call LCalcCrc
	xchg al,ah
	add bx,cx
	cmp ax,[bx]
	jne rec_error
;
	call ds:RecPacketHandler

rec_error:
	call RecReset

rec_done:
	ret
rec_pr	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RtsTimeout
;
;		DESCRIPTION:    RTS timeout expired
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RtsTimeout	Proc far
	mov bx,sernet_data_sel
	mov ds,bx
	mov dx,ds:base
	add dx,4
	mov al,9
	out dx,al				; modem control, DTR = high, RTS = low
	and ds:Mode, NOT MODE_SEND_BUSY
	ret
RtsTimeout	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRANS_PR
;
;		DESCRIPTION:    Transmit data
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trans_pr	PROC near
	mov dx,ds:base
	mov cx,ds:SendCount
	or cx,cx
	jnz trans_not_empty
;
	mov al,1
	inc dx
	out dx,al
;
	GetSystemTime
	add eax,ds:CharTics
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET RtsTimeout
	xor bx,bx
	StartTimer
	jmp trans_exit

trans_not_empty:
	dec cx
	mov ds:SendCount,cx
	mov bx,ds:SendBytePtr
	xor al,al
	xchg al,[bx]
	out dx,al
	inc bx
	mov ds:SendBytePtr,bx

trans_exit:
	ret
trans_pr	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ComInt
;
;		DESCRIPTION:    Serial port interrupt
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serial_tab:
st_mod	DW OFFSET modem
st_tx	DW OFFSET trans_pr
st_rx	DW OFFSET rec_pr
st_li	DW OFFSET line_err

ComInt	Proc far
	GetSystemTime
	mov ds:LastMsgTime,eax
	mov ds:LastMsgTime+4,edx
;
	mov dx,ds:base
	add dx,2
	in al,dx
	test al,1
	jnz com_int_end
;
	mov bl,al
	xor bh,bh
	and bx,6
	call word ptr cs:[bx].serial_tab
	jmp ComInt

com_int_end:
	ret
ComInt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Preview
;
;		DESCRIPTION:    Return size of block or no more data
;
;		RETURNS:		NC		Data available
;						ECX		Size of data
;						DX		Packet type
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Preview	Proc far
	push ds
	push bx
;
	mov bx,sernet_data_sel
	mov ds,bx
	mov bx,ds:RecHead
	cmp bx,ds:RecTail
	stc
	je prev_done
;
	mov dx,ds:[bx].DataType
	xchg dl,dh
	movzx ecx,ds:[bx].DataSize
	xchg cl,ch
	clc

prev_done:
	pop bx
	pop ds
	retf32
Preview	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Receive
;
;		DESCRIPTION:    Receive data
;
;       PARAMETERS:     ES:EDI		data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Receive	Proc far
	push ds
	push ecx
	push esi
	push edi
;
	mov si,sernet_data_sel
	mov ds,si
	movzx esi,ds:RecHead
	movzx ecx,ds:[si].DataSize
	xchg cl,ch
	add esi,OFFSET DataBytes
	push cx
	shr cx,2
	rep movs dword ptr es:[edi],ds:[esi]
	pop cx
	and cx,3
	rep movs byte ptr es:[edi],ds:[esi]
;
	pop edi
	pop esi
	pop ecx
	pop ds
	retf32
Receive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Remove
;
;		DESCRIPTION:    Remove data from buffer ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Remove	Proc far
	push ds
	push bx
;
	mov bx,sernet_data_sel
	mov ds,bx
;
	mov bx,ds:RecHead
	cmp bx,ds:RecTail
	je remove_done
;
	add bx,SIZE data_packet
	cmp bx,OFFSET RecPacket2
	jbe remove_save
;
	mov bx,OFFSET RecPacket1

remove_save:
	mov ds:RecHead,bx

remove_done:
	pop bx
	pop ds
	retf32
Remove	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Send
;
;		DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX		size
;						DX		packet type
;						DS:ESI	dest address
;						ES:EDI	data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Send	Proc far
	push ds
	push eax
	push bx
	push dx
	push edi
;
	mov ah,[esi]
	mov bx,sernet_data_sel
	mov ds,bx
	EnterSection ds:SendSection

send_try_loop:
	test ds:Mode, MODE_ONLINE
	jz send_done
;
	mov bx,ds:SendTail
	mov al,ds:[bx]
	or al,al
	jz send_free_found
;
	push ax
	mov ax,10
	WaitMilliSec
	pop ax
	jmp send_try_loop

send_free_found:
	mov ds:[bx].PacketType,MSG_TYPE_DATA
	add ah,DEST_BIAS
	mov ds:[bx].PacketDest,ah
	mov al,ds:node
	add al,SOURCE_BIAS
	mov ds:[bx].PacketSource,al
	xchg cl,ch
	mov ds:[bx].DataSize,cx
	xchg cl,ch
	xchg dl,dh
	mov ds:[bx].DataType,dx
	push bx
;
	add bx,OFFSET DataBytes

send_copy_loop:
	mov al,es:[edi]
	mov [bx],al
	inc edi
	inc bx
	sub cx,1
	ja send_copy_loop
;
	pop bx
	mov ds:[bx].PacketMagic,MAGIC_NUMBER
	add bx,SIZE data_packet
	cmp bx,OFFSET SendPacket2
	jbe send_copy_save_tail
;
	mov bx,OFFSET SendPacket1

send_copy_save_tail:
	mov ds:SendTail,bx

send_done:
	LeaveSection ds:SendSection
;
	pop edi
	pop dx
	pop bx
	pop eax
	pop ds
	retf32
Send	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetAddress
;
;		DESCRIPTION:    Get adapter address
;
;		RETURNS:		DS:ESI	address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAddress	Proc far
	mov si,sernet_data_sel
	mov ds,si
	mov esi,OFFSET node	
	retf32
GetAddress	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_net
;
;		DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DriverName	DB 'SERNET',0

DispatchTable:
	DD OFFSET Preview,		 	sernet_code_sel
	DD OFFSET Receive,			sernet_code_sel
	DD OFFSET Remove,			sernet_code_sel
	DD OFFSET Send,				sernet_code_sel
	DD OFFSET GetAddress,		sernet_code_sel

init_net	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov esi,OFFSET DispatchTable
	mov es,ax
	mov edi,OFFSET DriverName
	mov al,100
	mov dx,0
	mov ecx,512
	RegisterNetDriver
;
	mov ax,sernet_data_sel
	mov ds,ax
	mov ds:Handle,bx
;
	mov al,ds:irq
	mov dx,cs
	mov es,dx
	mov di,OFFSET ComInt
	RequestPrivateIrqHandler
;
    mov ax,start_com_port_nr
    IsValidOsGate
    jc init_net_open
;
    mov ax,ds:port
    mov dx,ds:base
    StartComPort

init_net_open:    
   	mov cx,ds:baud
	mov dx,ds:base
	add dx,3
	mov al,83h
	out dx,al				; set line control to divisor access
;
	sub dx,3
	mov al,cl
	out dx,al				; output LSB divisor latch
;
	inc dx
	mov al,ch
	out dx,al				; output MSB divisor latch
;
	inc dx
	mov al,1
	out dx,al				; enable FIFO, 1 bit trig level.
;
	inc dx
	mov al,3
	out dx,al				; set line control to 8 bits, 1 stop and no parity
;
	sub dx,2
	mov al,0Dh
	out dx,al				; enable rx ints, line and modem ints, disable tx
;
	add dx,3
	mov al,9
	out dx,al				; modem control, DTR = high, RTS = low
;
	mov dx,ds:base
	in al,dx
	add dx,5
	in al,dx
	inc dx
	in al,dx
;
	movzx eax,ds:node
	mov edx,18641		; 1 / 64 second
	mul edx
	mov ebx,eax	
	add ebx,ds:FrameDuration
	sub ebx,ds:SlotTics	; duration + 1 / 64 * node ID before master selection
	mov ds:MasterTics,ebx
;
	GetSystemTime
	mov ds:LastMsgTime,eax
	mov ds:LastMsgTime+4,edx
	add eax,ebx
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET MasterTimeout
	xor bx,bx
	StartTimer
;
	popa
	pop es
	pop ds
	ret
	ret
init_net	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

node_str		DB 'SERNET.NODE',0
port_str		DB 'SERNET.PORT',0
irq_str			DB 'SERNET.IRQ',0
baud_str		DB 'SERNET.BAUD',0

BaseTab:
b1	DW 3F8h
b2	DW 2F8h
b3	DW 3E8h
b4	DW 2E8h

IrqTab:
i1	DB 4
i2	DB 3
i3	DB 4
i4	DB 3

Init	Proc far
	push ds
	push es
	pusha
	mov bx,sernet_code_sel
	InitDevice
;
	mov eax,SIZE sernet_data_seg
	mov bx,sernet_data_sel
	AllocateFixedSystemMem
	mov ds,bx
	mov es,bx
	mov cx,ax
	xor di,di
	xor al,al
	rep stosb
;	
	InitSection ds:SendSection
;
	mov ds:RecCount,0
	mov ds:Mode,0
	mov ds:RecPtr, OFFSET RecPacket1
	mov ds:RecHead, OFFSET RecPacket1
	mov ds:RecTail, OFFSET RecPacket1
	mov ds:RecPacket1.DataHeader.PacketMagic,0
	mov ds:RecPacket2.DataHeader.PacketMagic,0
;
	mov ds:SendHead, OFFSET SendPacket1
	mov ds:SendTail,OFFSET SendPacket1
	mov ds:SendPacket1.DataHeader.PacketMagic,0
	mov ds:SendPacket2.DataHeader.PacketMagic,0
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET node_str
	call GetEnvInt
	or eax,eax
	jz init_done
;
	cmp eax,64
	ja init_done
;
	mov bx,sernet_data_sel
	mov ds,bx
	mov ds:node,al
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET port_str
	call GetEnvInt
	or eax,eax
	jz init_done
;
	dec eax
	cmp eax,4
	jnc init_done
;
	mov bx,ax
	push word ptr cs:[bx].IrqTab
	add bx,bx
;
	mov ax,sernet_data_sel
	mov ds,ax
	mov ax,word ptr cs:[bx].BaseTab
	mov ds:base,ax
	mov ds:port,bx
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET irq_str
	call GetEnvInt
	pop cx
	or eax,eax
	jz init_irq_ok
;
	mov cx,ax
	cmp cx,16
	jnc init_done

init_irq_ok:
	mov ax,sernet_data_sel
	mov ds,ax
	mov ds:irq,cl
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET baud_str
	call GetEnvInt
	cmp eax,1200
	jb init_done
;
	mov ecx,eax
	mov eax,11930000
	xor edx,edx
	div ecx
	mov ds:CharTics,eax
;
	mov eax,90000000
	xor edx,edx
	div ecx
	mov ds:DefaultFrame,ax
;
	mov ebx,1193000
	mul ebx
	mov ebx,1000000
	div ebx
	mov ds:SlotTics,eax
;
	mov ebx,MAX_DATA_SIZE SHR 3
	mul ebx
	mov ds:MaxPacketTics,eax
;
	mov eax,ds:SlotTics
	mov edx,MAX_FRAMES
	mul edx
	cmp eax,MAX_INIT_INTERVAL
	jc init_duration_ok
;
	mov eax,MAX_INIT_INTERVAL

init_duration_ok:
	sub eax,ds:SlotTics
	mov ds:FrameDuration,eax
;
	xor edx,edx
	mov eax,115200
	div ecx
	mov cx,ax
;
	mov ax,sernet_data_sel
	mov ds,ax
	mov ds:baud,cx
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET init_net
	HookInitTasking

init_done:
	popa
	pop es
	pop ds
	ret
Init	Endp


ENDS

	END init

