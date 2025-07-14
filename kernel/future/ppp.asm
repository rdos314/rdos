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
; PPP.ASM
; PPP protocol driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\ip.inc

SEND_BUFFER_SIZE	EQU 3000
REC_BUFFER_SIZE		EQU 3000

MODE_IDLE		EQU 0
MODE_CONNECT	EQU 1
MODE_HANGUP		EQU 2
MODE_LCP		EQU 3
MODE_RUNNING	EQU 4

STATE_ACK_SENT		EQU 1
STATE_ACK_RECEIVED	EQU 2

STATUS_LINE		EQU 1
STATUS_TIMEOUT	EQU 2
STATUS_DATA		EQU 3

PROTOCOL_COMPRESS	EQU 1
HDLC_COMPRESS		EQU 2

FLAG	EQU 7Eh
ESCAPE	EQU 7Dh

GoodFcs16 EQU 0F0B8h

protocol_data	STRUC

proto_nr			DW ?
proto_id			DB ?
proto_state			DB ?
send_options		DB 64 DUP(?)

this_layer_up		DW ?
this_layer_down		DW ?

send_opt_tab		DW ?
opt_check_tab		DW ?
opt_validate_tab	DW ?
opt_accept_tab		DW ?
opt_ack_tab			DW ?
opt_nak_tab			DW ?
opt_reject_tab		DW ?

protocol_data	ENDS

hdlc_header	STRUC

hdlc_addr		DB ?
hdlc_control	DB ?
hdlc_prot		DW ?

hdlc_header	ENDS

hdlc_footer	STRUC

hdlc_fcs	DW ?

hdlc_footer	ENDS

lcp_header	STRUC

lcp_code	DB ?
lcp_id		DB ?
lcp_len		DW ?

lcp_header	ENDS

lcp_option_header	STRUC

lcp_opt_type	DB ?
lcp_opt_len		DB ?

lcp_option_header	ENDS

ppp_data	SEGMENT AT 0

base				DW ?
irq					DB ?
baud				DW ?
ppp_mode			DB ?
com_open			DB ?
thread_id			DW ?
id					DB ?
net_handle			DW ?
authent_prot		DW ?
connect_list		DW ?
usage_count			DW ?
access_section		section_typ <>
idle_timeout		DD ?,?

com_rec_count	  	DW ?
com_rec_head		DW ?
com_rec_tail		DW ?
com_rec_buf			DB 256 DUP(?)

answ_len			DW ?
answ_buf			DB 256 DUP(?)

lcp_handle			DW ?
authent_handle		DW ?
ipcp_handle			DW ?

req_accm			DD ?

ppp_dns1			DD ?
ppp_dns2			DD ?

dialnr				DB 64 DUP(?)
username			DB 64 DUP(?)
password			DB 64 DUP(?)

rec_ip				DD ?
rec_accm			DD ?
rec_escape			DB ?
rec_fcs				DW ?
rec_head			DW ?
rec_tail			DW ?
rec_curr			DW ?
rec_peek			DW ?

send_ip				DD ?
send_hdlc_len		DW ?
send_proto_len		DW ?
send_accm			DD ?
send_escape			DB ?
send_fcs			DW ?
send_head			DW ?
send_tail			DW ?
send_curr			DW ?

send_buf			DB SEND_BUFFER_SIZE DUP(?)
rec_buf				DB REC_BUFFER_SIZE DUP(?)

lcp_rec_buf			DB 512 DUP(?)
lcp_send_buf		DB 512 DUP(?)
lcp_retransmit_buf	DB 512 DUP(?)

ppp_data	ENDS

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

FcsTab16:
fcs16_00	DD	00000h,	01189h,	02312h,	0329Bh,	04624h,	057ADh,	06536h,	074BFh
fcs16_08	DD	08C48h,	09DC1h,	0AF5Ah,	0BED3h,	0CA6Ch,	0DBE5h,	0E97Eh,	0F8F7h
fcs16_10	DD	01081h,	00108h,	03393h,	0221Ah,	056A5h,	0472Ch,	075B7h,	0643Eh
fcs16_18	DD	09CC9h,	08D40h,	0BFDBh,	0AE52h,	0DAEDh,	0CB64h,	0F9FFh,	0E876h
fcs16_20	DD	02102h,	0308Bh,	00210h,	01399h,	06726h,	076AFh,	04434h,	055BDh
fcs16_28	DD	0AD4Ah,	0BCC3h,	08E58h,	09FD1h,	0EB6Eh,	0FAE7h,	0C87Ch,	0D9F5h
fcs16_30	DD	03183h,	0200Ah,	01291h,	00318h,	077A7h,	0662Eh,	054B5h,	0453Ch
fcs16_38	DD	0BDCBh,	0AC42h,	09ED9h,	08F50h,	0FBEFh,	0EA66h,	0D8FDh,	0C974h
fcs16_40	DD	04204h,	0538Dh,	06116h,	0709Fh,	00420h,	015A9h,	02732h,	036BBh
fcs16_48	DD	0CE4Ch,	0DFC5h,	0ED5Eh,	0FCD7h,	08868h,	099E1h,	0AB7Ah,	0BAF3h
fcs16_50	DD	05285h,	0430Ch,	07197h,	0601Eh,	014A1h,	00528h,	037B3h,	0263Ah
fcs16_58	DD	0DECDh,	0CF44h,	0FDDFh,	0EC56h,	098E9h,	08960h,	0BBFBh,	0AA72h
fcs16_60	DD	06306h,	0728Fh,	04014h,	0519Dh,	02522h,	034ABh,	00630h,	017B9h
fcs16_68	DD	0EF4Eh,	0FEC7h,	0CC5Ch,	0DDD5h,	0A96Ah,	0B8E3h,	08A78h,	09BF1h
fcs16_70	DD	07387h,	0620Eh,	05095h,	0411Ch,	035A3h,	0242Ah,	016B1h,	00738h
fcs16_78	DD	0FFCFh,	0EE46h,	0DCDDh,	0CD54h,	0B9EBh,	0A862h,	09AF9h,	08B70h
fcs16_80	DD	08408h,	09581h,	0A71Ah,	0B693h,	0C22Ch,	0D3A5h,	0E13Eh,	0F0B7h
fcs16_88	DD	00840h,	019C9h,	02B52h,	03ADBh,	04E64h,	05FEDh,	06D76h,	07CFFh
fcs16_90	DD	09489h,	08500h,	0B79Bh,	0A612h,	0D2ADh,	0C324h,	0F1BFh,	0E036h
fcs16_98	DD	018C1h,	00948h,	03BD3h,	02A5Ah,	05EE5h,	04F6Ch,	07DF7h,	06C7Eh
fcs16_A0	DD	0A50Ah,	0B483h,	08618h,	09791h,	0E32Eh,	0F2A7h,	0C03Ch,	0D1B5h
fcs16_A8	DD	02942h,	038CBh,	00A50h,	01BD9h,	06F66h,	07EEFh,	04C74h,	05DFDh
fcs16_B0	DD	0B58Bh,	0A402h,	09699h,	08710h,	0F3AFh,	0E226h,	0D0BDh,	0C134h
fcs16_B8	DD	039C3h,	0284Ah,	01AD1h,	00B58h,	07FE7h,	06E6Eh,	05CF5h,	04D7Ch
fcs16_C0	DD	0C60Ch,	0D785h,	0E51Eh,	0F497h,	08028h,	091A1h,	0A33Ah,	0B2B3h
fcs16_C8	DD	04A44h,	05BCDh,	06956h,	078DFh,	00C60h,	01DE9h,	02F72h,	03EFBh
fcs16_D0	DD	0D68Dh,	0C704h,	0F59Fh,	0E416h,	090A9h,	08120h,	0B3BBh,	0A232h
fcs16_D8	DD	05AC5h,	04B4Ch,	079D7h,	0685Eh,	01CE1h,	00D68h,	03FF3h,	02E7Ah
fcs16_E0	DD	0E70Eh,	0F687h,	0C41Ch,	0D595h,	0A12Ah,	0B0A3h,	08238h,	093B1h
fcs16_E8	DD	06B46h,	07ACFh,	04854h,	059DDh,	02D62h,	03CEBh,	00E70h,	01FF9h
fcs16_F0	DD	0F78Fh,	0E606h,	0D49Dh,	0C514h,	0B1ABh,	0A022h,	092B9h,	08330h
fcs16_F8	DD	07BC7h,	06A4Eh,	058D5h,	0495Ch,	03DE3h,	02C6Ah,	01EF1h,	00F78h

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MODEM
;
;		DESCRIPTION:	Modem control signal changed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

modem	Proc near
	mov dx,ds:base
	add dx,6
	in al,dx
	test al,8
	jz modem_done
	mov bx,ds:thread_id
	Signal
modem_done:
	ret
modem	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LINE_ERR
;
;		DESCRIPTION:	Line error occurred
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

line_err	PROC near
	mov dx,ds:base
	add dx,5
	in al,dx
	ret
line_err	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REC_PR
;
;		DESCRIPTION:	Received data
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rec_pr	PROC near
	mov dx,ds:base
	in al,dx
	mov ah,ds:ppp_mode
	cmp ah,MODE_LCP
	jnc rec_prot

rec_hayes:
	mov cx,ds:com_rec_count
	cmp cx,256
	je rec_done
	inc cx
	mov ds:com_rec_count,cx
	mov bx,ds:com_rec_tail
	mov ds:com_rec_buf.[bx],al
	inc bx
	cmp bx,256
	jnz rec_no_wrap
	xor bx,bx
rec_no_wrap:
	mov ds:com_rec_tail,bx
	mov bx,ds:thread_id
	Signal
	jmp rec_done

rec_prot:
	cmp al,20h
	jnc rec_not_accm
	movzx ax,al
	mov bx,OFFSET rec_accm
	bt ds:[bx],ax
	jc rec_done

rec_not_accm:
	mov bx,ds:rec_curr
	cmp bx,ds:rec_head
	jne rec_put
;
	cmp al,FLAG
	jne rec_done
	xor al,al
	mov [bx],al
	inc bx
	cmp bx,ds:rec_tail
	je rec_done
	cmp bx,OFFSET rec_buf + REC_BUFFER_SIZE
	jne rec_init_wrap1
	sub bx,REC_BUFFER_SIZE
rec_init_wrap1:
	mov [bx],al
	inc bx
	cmp bx,ds:rec_tail
	je rec_done
	cmp bx,OFFSET rec_buf + REC_BUFFER_SIZE
	jne rec_init_wrap2
	sub bx,REC_BUFFER_SIZE
rec_init_wrap2:
	mov ds:rec_fcs,-1
	mov ds:rec_curr,bx
	jmp rec_done

rec_put:
	cmp al,FLAG
	je rec_notify
	cmp al,ESCAPE
	je rec_escaped
	xor al,ds:rec_escape
	mov ds:rec_escape,0
	mov [bx],al
	inc bx
	cmp bx,ds:rec_tail
	je rec_done
	cmp bx,OFFSET rec_buf + REC_BUFFER_SIZE
	jnz rec_wrap
	sub bx,REC_BUFFER_SIZE
rec_wrap:
	mov ds:rec_curr,bx
	movzx bx,al
	mov ax,ds:rec_fcs
	xor bl,al
	shl bx,2
	shr ax,8
	xor ax,word ptr cs:[bx].FcsTab16
	mov ds:rec_fcs,ax
	jmp rec_done		

rec_escaped:
	mov ds:rec_curr,bx
	xor ds:rec_escape,20h
	jmp rec_done

rec_notify:
	mov cx,ds:rec_curr
	sub cx,ds:rec_head
	jnc rec_size_wrap
	add cx,REC_BUFFER_SIZE
rec_size_wrap:
	sub cx,2
	jz rec_done
;
	mov ax,ds:rec_fcs
	cmp ax,0F0B8h
	je rec_good_data
	mov ds:rec_fcs,-1
	mov bx,ds:rec_head
	mov ds:rec_curr,bx
	jmp rec_done

rec_good_data:
	mov ds:rec_fcs,-1
	mov bx,ds:rec_head
	mov [bx],cl
	inc bx
	cmp bx,ds:rec_tail
	je rec_done
	cmp bx,OFFSET rec_buf + REC_BUFFER_SIZE
	jne rec_len_wrap1
	sub bx,REC_BUFFER_SIZE
rec_len_wrap1:
	mov [bx],ch
	inc bx
	cmp bx,ds:rec_tail
	je rec_done
	cmp bx,OFFSET rec_buf + REC_BUFFER_SIZE
	jne rec_len_wrap2
	sub bx,REC_BUFFER_SIZE
rec_len_wrap2:
	mov bx,ds:rec_curr
	mov ds:rec_head,bx
	mov bx,ds:thread_id
	Signal

rec_done:
	sti
	ret
rec_pr	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRANS_PR
;
;		DESCRIPTION:	Transmit data
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trans_pr	PROC near
	mov dx,ds:base
	mov al,ds:ppp_mode
	cmp al,MODE_IDLE
	je trans_stop
	cmp al,MODE_CONNECT
	je trans_done
	cmp al,MODE_HANGUP
	je trans_done

trans_normal:
	mov al,ds:send_escape
	or al,al
	jne trans_escape
;
	mov bx,ds:send_head
	mov cl,[bx]
	inc bx
	cmp bx,OFFSET send_buf + SEND_BUFFER_SIZE
	jne trans_size_wrap
	sub bx,SEND_BUFFER_SIZE
trans_size_wrap:
	mov ch,[bx]
	or cx,cx
	jz trans_stop
	mov ax,ds:send_curr
	sub ax,ds:send_head
	jnc trans_dist_wrap
	add ax,SEND_BUFFER_SIZE
trans_dist_wrap:
	or ax,ax
	je trans_setup
	cmp ax,cx
	je trans_fcs
	sub ax,2
	cmp ax,cx
	jne trans_next
	mov al,7Eh
	out dx,al
	mov bx,ds:send_curr
	mov ds:send_head,bx
	jmp trans_done

trans_fcs:
	mov bx,ds:send_curr
	mov ax,ds:send_fcs
	not ax
	mov [bx],al
	inc bx
	cmp bx,OFFSET send_buf + SEND_BUFFER_SIZE
	jne trans_fcs_wrap
	sub bx,SEND_BUFFER_SIZE
trans_fcs_wrap:
	mov [bx],ah
	jmp trans_send_test

trans_setup:
	mov bx,ds:send_curr
	add bx,2
	cmp bx,OFFSET send_buf + SEND_BUFFER_SIZE
	jc trans_setup_wrap
	sub bx,SEND_BUFFER_SIZE
trans_setup_wrap:
	mov ds:send_fcs,-1
	mov ds:send_curr,bx
	mov al,7Eh
	out dx,al
	jmp trans_done

trans_next:
	mov bx,ds:send_curr
	mov bl,[bx]
	mov ax,ds:send_fcs
	xor bl,al
	xor bh,bh
	shl bx,2
	shr ax,8
	xor ax,word ptr cs:[bx].FcsTab16
	mov ds:send_fcs,ax
trans_send_test:
	mov bx,ds:send_curr
	mov al,[bx]
	cmp al,7Eh
	je trans_send_escape
	cmp al,7Dh
	je trans_send_escape
	cmp al,20h
	jnc trans_send
	push bx
	mov bx,OFFSET send_accm
	movzx ax,al
	bt [bx],ax
	pop bx
	jnc trans_send

trans_send_escape:
	mov al,7Dh
	out dx,al
	mov ds:send_escape,1
	jmp trans_done
	
trans_escape:
	mov bx,ds:send_curr
	mov ds:send_escape,0
	mov al,[bx]
	xor al,20h

trans_send:
	out dx,al
	inc bx
	cmp bx,OFFSET send_buf + SEND_BUFFER_SIZE
	jnz trans_next_wrap
	sub bx,SEND_BUFFER_SIZE
trans_next_wrap:
	mov ds:send_curr,bx
	jmp trans_done

trans_stop:
	mov al,0Dh
	inc dx
	out dx,al
	jmp trans_done

trans_done:
	ret
trans_pr	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			COM_INT
;
;		DESCRIPTION:	Serial port interrupt
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serial_tab:
st_mod	DW OFFSET modem
st_tx	DW OFFSET trans_pr
st_rx	DW OFFSET rec_pr
st_li	DW OFFSET line_err

com_int	Proc far
	mov dx,ds:base
	add dx,2
	in al,dx
	test al,1
	jnz com_int_end
	mov bl,al
	xor bh,bh
	and bx,6
	call word ptr cs:[bx].serial_tab
	jmp com_int
com_int_end:
	ret
com_int	Endp

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
;		NAME:			ClearCom
;
;		PARAMETERS:		Clear com buffers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearCom	Proc near
	cli
	mov ds:com_rec_count,0
	mov ds:com_rec_head,0
	mov ds:com_rec_tail,0
	sti
	ret
ClearCom	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteCharCom
;
;		PARAMETERS:		AL		Char to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCharCom	Proc near
	push dx
	mov dx,ds:base
	out dx,al
	pop dx
	ret
WriteCharCom	Endp
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SignalTimeout
;
;		description:	Sends a signal when a timeout expires
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SignalTimeout	Proc far
	mov bx,ppp_data_sel
	mov ds,bx
	mov bx,ds:thread_id
	Signal
	ret
SignalTimeout	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitForCharCom
;
;		PARAMETERS:		EAX		Timeout in ms
;
;		RETURNS:		NC		char available
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCharCom	Proc near
	push es
	push eax
	push ebx
	push edx
	push di
;
	ClearSignal
	mov bx,ds:com_rec_count
	or bx,bx
	jnz wait_for_char_done
;
	mov edx,1193
	mul edx
	push edx
	push eax
	GetSystemTime
	pop ebx
	add eax,ebx
	pop ebx
	adc edx,ebx
	mov bx,cs
	mov es,bx
	mov di,OFFSET SignalTimeout
	mov bx,ds:thread_id
	StopTimer
	StartTimer
	WaitForSignal
	StopTimer
;
	mov ax,ds:com_rec_count
wait_for_char_done:
	or ax,ax
	clc
	jnz wait_for_char_end
	stc
wait_for_char_end:	
	pop di
	pop edx
	pop ebx
	pop eax
	pop es
	ret
WaitForCharCom	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadCharCom
;
;		RETURNS:		AL		char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCharCom	Proc near
	push bx
	push cx
;
	cli
	xor al,al
	mov cx,ds:com_rec_count
	or cx,cx
	jz com_read_done
	mov bx,ds:com_rec_head
	mov al,ds:[bx].com_rec_buf
	dec cx
	mov ds:com_rec_count,cx
	inc bx
	cmp bx,256
	jnz com_read_nix_wrap
	xor bx,bx
com_read_nix_wrap:
	mov ds:com_rec_head,bx
	sti
com_read_done:
	pop cx
	pop bx
	ret
ReadCharCom	Endp
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendAndWaitForEcho
;
;		PARAMETERS:		AL		char to send
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendAndWaitForEcho	Proc near
	push eax
	push dx
;
	mov dl,al
	call WriteCharCom
	mov eax,50
	call WaitForCharCom
	jc send_and_wait_done
	call ReadCharCom
	cmp al,dl
	clc
	je send_and_wait_done
	stc
send_and_wait_done:
	pop dx
	pop eax
	ret
SendAndWaitForEcho	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReceiveAnswer
;
;		PARAMETERS:		EAX		Timeout on first char
;
;		RETURNS:		CX		Number of chars received
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveAnswer	Proc near
	push eax
	push bx
;
	xor cx,cx
	mov bx,OFFSET answ_buf
receive_answer_loop:
	call WaitForCharCom
	jc receive_answer_done
	call ReadCharCom
	cmp al,0Dh
	je receive_answer_next
	cmp al,0Ah
	je receive_answer_next
	mov [bx],al
	inc bx
	inc cx
receive_answer_next:
	mov eax,50
	cmp cx,256
	jne receive_answer_loop
receive_answer_done:
	mov ds:answ_len,cx	
;
	pop bx
	pop eax
	ret
ReceiveAnswer	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ValidateAnswer
;
;		RETURNS:		NC		valid answer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ValidateAnswer	Proc near
	push ax
	push cx
;
	mov cx,ds:answ_len
	or cx,cx
	jz validate_fail
	cmp cx,1
	je validate_num
	cmp cx,2
	jne validate_fail
;
	mov ax,word ptr ds:answ_buf
	cmp ax,'KO'
	je validate_ok
	jmp validate_fail

validate_num:
	mov al,ds:answ_buf
	cmp al,'0'
	je validate_ok

validate_fail:
	stc
	jmp validate_done

validate_ok:
	clc
validate_done:
	pop cx
	pop ax	
	ret
ValidateAnswer	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendModemCommand
;
;		PARAMETERS:		EAX		Timeout in ms for answer
;						ES:DI	address of command string
;
;		RETURNS:		NC		ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunModemCommand	Proc near
	push edx
	push di
;
	mov edx,eax
	call ClearCom
run_modem_loop:
	mov al,es:[di]
	or al,al
	jz run_modem_get_answ
	call SendAndWaitForEcho
	jc run_modem_done
	inc di
	jmp run_modem_loop

run_modem_get_answ:
	mov al,0Dh
	call SendAndWaitForEcho
	jc run_modem_done
;
	mov eax,edx
	call ReceiveAnswer
	call ValidateAnswer
		
run_modem_done:
	pop di
	pop edx
	ret
RunModemCommand	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RunDialCommand
;
;		RETURNS:		NC		ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunDialCommand	Proc near
	push es
	push eax
	push bx
	push edx
	push di
;
	mov ax,ds
	mov es,ax
	mov di,OFFSET dialnr
;
	call ClearCom
run_dial_loop:
	mov al,es:[di]
	or al,al
	jz run_dial_get_answ
	call SendAndWaitForEcho
	jc run_dial_done
	inc di
	jmp run_dial_loop

run_dial_get_answ:
	mov al,0Dh
	call SendAndWaitForEcho
	jc run_dial_done
;
	mov eax,60000
	call ReceiveAnswer
;
	mov dx,ds:base
	add dx,6
	in al,dx
	test al,80h
	clc
	jnz run_dial_done
	stc
run_dial_done:
	pop di
	pop edx
	pop bx
	pop eax
	pop es
	ret
RunDialCommand	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RunHangupCommand
;
;		RETURNS:		NC		ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HangupStr	DB 'ath',0

RunHangupCommand	Proc near
	push es
	push eax
	push cx
	push dx
	push di
;
	mov dx,ds:base
	add dx,4
	mov al,0Ah
	out dx,al				; modem control, DTR = low, RTS = high
;
	mov eax,500
	WaitMilliSec
;
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
;
	mov eax,1000
	WaitMilliSec
;
	mov cx,3
run_escape_loop:
	mov al,'+'
	call WriteCharCom
	mov eax,20
	WaitMilliSec
	loop run_escape_loop
;
	mov eax,1500
	WaitMilliSec
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET HangupStr
	call RunModemCommand
;
	mov dx,ds:base
	add dx,6
	in al,dx
	test al,80h
	clc
	jz run_hangup_command_done
	stc
run_hangup_command_done:
	pop di
	pop dx
	pop cx
	pop eax
	pop es
	ret
RunHangupCommand	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Open
;
;		description:	Open PPP serial port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Open	Proc near
	push es
	push ax
	push dx
	push di
;
	mov al,ds:irq
	mov dx,cs
	mov es,dx
	mov di,OFFSET com_int
	cli
	mov dl,1
	xchg dl,ds:com_open
	or dl,dl
	jnz open_handler_done
	RequestPrivateIrqHandler
open_handler_done:
	sti
;
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
	add dx,2
	mov al,3
	out dx,al				; set line control to 8 bits, 1 stop and no parity
;
	sub dx,2
	mov al,0Dh
	out dx,al				; enable rx ints, line and modem ints, disable tx
;
	add dx,3
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
;
	mov dx,ds:base
	in al,dx
	add dx,5
	in al,dx
	inc dx
	in al,dx
;
	pop di
	pop dx
	pop ax
	pop es
	ret
Open	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Close
;
;		description:	Close PPP serial port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Close	Proc near
	push ax
	push dx
;
	mov dx,ds:base
	mov al,0
	out dx,al				; disable rx, tx, line and modem ints
;
	add dx,4
	mov al,0Ah
	out dx,al	
;
	mov al,ds:irq
	xor dl,dl
	cli
	xchg dl,ds:com_open
	or dl,dl
	jz close_done
	ReleasePrivateIrqHandler
close_done:
	sti
;
	pop dx
	pop ax
	ret
Close	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DisconnectModem
;
;		description:	Disconnect modem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisconnectModem	Proc near
	push ax
	push dx
;
	mov ds:ppp_mode,MODE_HANGUP
	call Open
	xor ax,ax
	mov fs,ax
	call StopLcp
	call RunHangupCommand
	call Close
;
	pop dx
	pop ax
	ret
DisconnectModem	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ConnectModem
;
;		description:	Connect modem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConnectModem	Proc near
	push ax
	push dx
;
	mov ds:ppp_mode,MODE_CONNECT
	call Open
	call RunDialCommand
	jc connect_done
	call StartLcp

connect_done:
	pop dx
	pop ax
	ret
ConnectModem	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LcpSendOptTab
;
;		description:	LCP send option data
;
;		PARAMETERS:		AL			option #
;						ES:DI		buffer to put data in
;
;		RETURNS:		NC			option supported
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LcpOptUnsupported	Proc near
	stc
	ret
LcpOptUnsupported	Endp

LcpOptNoData	Proc near
	stosb
	mov byte ptr [di],2
	inc di
	clc
	ret
LcpOptNoData	Endp

LcpOptAccm	Proc near
	stosb
	push eax
	mov al,6
	stosb
	mov ax,word ptr ds:req_accm+2
	xchg al,ah
	stosw
	mov ax,word ptr ds:req_accm
	xchg al,ah
	stosw		
	pop eax
	clc
	ret
LcpOptAccm	Endp

LcpSendOptTab:
lsol DB 9
lso0 DW OFFSET LcpOptUnsupported
lso1 DW OFFSET LcpOptUnsupported
lso2 DW OFFSET LcpOptAccm
lso3 DW OFFSET LcpOptUnsupported
lso4 DW OFFSET LcpOptUnsupported
lso5 DW OFFSET LcpOptUnsupported
lso6 DW OFFSET LcpOptUnsupported
lso7 DW OFFSET LcpOptNoData
lso8 DW OFFSET LcpOptNoData

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LcpOptCheckTab
;
;		DESCRIPTION:    Check if LCP option is supported
;
;		PARAMETERS:		AL		option
;						CL		option size
;
;		RETURNS:		NC		ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LcpOptCheckUnsupported	Proc near
	stc
	ret
LcpOptCheckUnsupported	Endp

LcpOptCheckMru	Proc near
	cmp cl,4
	jne check_mru_fail
	clc
	ret
check_mru_fail:
	stc
	ret
LcpOptCheckMru	Endp

LcpOptCheckAccm	Proc near
	cmp cl,6
	jne check_accm_fail
	clc
	ret
check_accm_fail:
	stc
	ret
LcpOptCheckAccm	Endp

LcpOptCheckAuthenticate	Proc near
	clc
	ret
LcpOptCheckAuthenticate	Endp

LcpOptCheckMagic	Proc near
	cmp cl,6
	jne check_magic_fail
	clc
	ret
check_magic_fail:
	stc
	ret
LcpOptCheckMagic	Endp

LcpOptCheckProtocolCompress	Proc near
	cmp cl,2
	jne check_proto_compr_fail
	clc
	ret
check_proto_compr_fail:
	stc
	ret
LcpOptCheckProtocolCompress	Endp

LcpOptCheckHdlcCompress	Proc near
	cmp cl,2
	jne check_hdlc_compr_fail
	clc
	ret
check_hdlc_compr_fail:
	stc
	ret
LcpOptCheckHdlcCompress	Endp

LcpOptCheckTab:
locl DB 9
loc0 DW OFFSET LcpOptCheckUnsupported
loc1 DW OFFSET LcpOptCheckMru
loc2 DW OFFSET LcpOptCheckAccm
loc3 DW OFFSET LcpOptCheckAuthenticate
loc4 DW OFFSET LcpOptCheckUnsupported
loc5 DW OFFSET LcpOptCheckMagic
loc6 DW OFFSET LcpOptCheckUnsupported
loc7 DW OFFSET LcpOptCheckProtocolCompress
loc8 DW OFFSET LcpOptCheckHdlcCompress

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LcpOptValidateTab
;
;		DESCRIPTION:    Validate LCP option
;
;		PARAMETERS:		AL		option
;						CL		size of option
;						SI		option data
;
;		RETURNS:		NC		ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LcpOptValidateOk	Proc near
	clc
	ret
LcpOptValidateOk	Endp

LcpOptValidateFail	Proc near
	stc
	ret
LcpOptValidateFail	Endp

LcpOptValidateMru	Proc near
	mov ax,[si]
	xchg al,ah
	cmp ax,1500
	jnc validate_mru_done
	mov word ptr [si],1500
validate_mru_done:
	ret
LcpOptValidateMru	Endp

LcpOptValidateAuthenticate	Proc near
	mov ax,[si]
	xchg al,ah
	cmp ax,0C023h
	jne validate_authent_fail
	clc
	ret
validate_authent_fail:
	stc
	ret
LcpOptValidateAuthenticate	Endp

LcpOptValidateTab:
lovl DB 9
lov0 DW OFFSET LcpOptValidateFail
lov1 DW OFFSET LcpOptValidateMru
lov2 DW OFFSET LcpOptValidateOk
lov3 DW OFFSET LcpOptValidateAuthenticate
lov4 DW OFFSET LcpOptValidateFail
lov5 DW OFFSET LcpOptValidateOk
lov6 DW OFFSET LcpOptValidateFail
lov7 DW OFFSET LcpOptValidateOk
lov8 DW OFFSET LcpOptValidateOk

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LcpOptAcceptTab
;
;		DESCRIPTION:    Accept LCP option
;
;		PARAMETERS:		AL		option
;						CL		size of option
;						SI		option data
;
;		RETURNS:		NC		ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


LcpOptAcceptNoAction	Proc near
	ret
LcpOptAcceptNoAction	Endp

LcpOptAcceptAccm	Proc near
	mov eax,[si]
	xchg al,ah
	mov word ptr ds:rec_accm+2,ax
	shr eax,16
	xchg al,ah
	mov word ptr ds:rec_accm,ax
	ret
LcpOptAcceptAccm	Endp

LcpOptAcceptAuthenticate	Proc near
	mov ax,[si]
	xchg al,ah
	mov ds:authent_prot,ax
	ret
LcpOptAcceptAuthenticate	Endp

LcpOptAcceptTab:
loal DB 9
loa0 DW OFFSET LcpOptAcceptNoAction
loa1 DW OFFSET LcpOptAcceptNoAction
loa2 DW OFFSET LcpOptAcceptAccm
loa3 DW OFFSET LcpOptAcceptAuthenticate
loa4 DW OFFSET LcpOptAcceptNoAction
loa5 DW OFFSET LcpOptAcceptNoAction
loa6 DW OFFSET LcpOptAcceptNoAction
loa7 DW OFFSET LcpOptAcceptNoAction
loa8 DW OFFSET LcpOptAcceptNoAction

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LcpOptAckTab
;
;		DESCRIPTION:    LCP options acked
;
;		PARAMETERS:		AL		option
;						CL		size of option
;						SI		option data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LcpOptAckNoAction	Proc near
	ret
LcpOptAckNoAction	Endp

LcpOptAckAccm	Proc near
	mov eax,[si]
	xchg al,ah
	mov word ptr ds:send_accm+2,ax
	shr eax,16
	xchg al,ah
	mov word ptr ds:send_accm,ax
	ret
LcpOptAckAccm	Endp

LcpOptAckProtocolCompress	Proc near
	mov ds:send_proto_len,1
	ret
LcpOptAckProtocolCompress	Endp

LcpOptAckHdlcCompress	Proc near
	mov ds:send_hdlc_len,0
	ret
LcpOptAckHdlcCompress	Endp

LcpOptAckTab:
lool DB 9
loo0 DW OFFSET LcpOptAckNoAction
loo1 DW OFFSET LcpOptAckNoAction
loo2 DW OFFSET LcpOptAckAccm
loo3 DW OFFSET LcpOptAckNoAction
loo4 DW OFFSET LcpOptAckNoAction
loo5 DW OFFSET LcpOptAckNoAction
loo6 DW OFFSET LcpOptAckNoAction
loo7 DW OFFSET LcpOptAckProtocolCompress
loo8 DW OFFSET LcpOptAckHdlcCompress

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LcpOptNakTab
;
;		DESCRIPTION:    LCP options naked
;
;		PARAMETERS:		AL		option
;						CL		size of option
;						SI		option data
;
;		RETURNS:		NC		option modified
;						CY		not legal to nak
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LcpOptNakFatal	Proc near
	stc
	ret
LcpOptNakFatal	Endp

LcpOptNakAccm	Proc near
	mov eax,[si]
	xchg al,ah
	mov word ptr ds:req_accm+2,ax
	shr eax,16
	xchg al,ah
	mov word ptr ds:req_accm,ax
	clc
	ret
LcpOptNakAccm	Endp

LcpOptNakTab:
lonl DB 9
lon0 DW OFFSET LcpOptNakFatal
lon1 DW OFFSET LcpOptNakFatal
lon2 DW OFFSET LcpOptNakAccm
lon3 DW OFFSET LcpOptNakFatal
lon4 DW OFFSET LcpOptNakFatal
lon5 DW OFFSET LcpOptNakFatal
lon6 DW OFFSET LcpOptNakFatal
lon7 DW OFFSET LcpOptNakFatal
lon8 DW OFFSET LcpOptNakFatal

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LcpOptRejectTab
;
;		DESCRIPTION:    LCP options rejected
;
;		PARAMETERS:		AL		option
;						CL		size of option
;						SI		option data
;
;		RETURNS:		NC		option removed
;						CY		not legal to reject
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LcpOptRejectOk	Proc near
	clc
	ret
LcpOptRejectOk	Endp

LcpOptRejectFatal	Proc near
	stc
	ret
LcpOptRejectFatal	Endp

LcpOptRejectTab:
lorl DB 9
lor0 DW OFFSET LcpOptRejectOk
lor1 DW OFFSET LcpOptRejectOk
lor2 DW OFFSET LcpOptRejectOk
lor3 DW OFFSET LcpOptRejectOk
lor4 DW OFFSET LcpOptRejectOk
lor5 DW OFFSET LcpOptRejectOk
lor6 DW OFFSET LcpOptRejectOk
lor7 DW OFFSET LcpOptRejectOk
lor8 DW OFFSET LcpOptRejectOk

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LcpTable
;
;		DESCRIPTION:    LCP tables
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LcpTable:
	DW OFFSET LcpSendOptTab
	DW OFFSET LcpOptCheckTab
	DW OFFSET LcpOptValidateTab
	DW OFFSET LcpOptAcceptTab
	DW OFFSET LcpOptAckTab
	DW OFFSET LcpOptNakTab
	DW OFFSET LcpOptRejectTab

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AuthenticateSendOptTab
;
;		description:	Authenticate send option data
;
;		PARAMETERS:		AL			option #
;						ES:DI		buffer to put data in
;
;		RETURNS:		NC			option supported
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AuthenticateOptUnsupported	Proc near
	stc
	ret
AuthenticateOptUnsupported	Endp

AuthenticateOptUserId	Proc near
	push ax
	push si
;
	push di
	inc di
	mov si,OFFSET username
authent_user_id_loop:
	lods byte ptr [si]
	or al,al
	jz authent_user_id_moved
	stosb
	jmp authent_user_id_loop

authent_user_id_moved:
	mov ax,di
	pop si
	sub ax,si
	dec al
	mov [si],al
	pop si
	pop ax
	clc
	ret
AuthenticateOptUserId	Endp

AuthenticateOptPassword	Proc near
	push ax
	push si
;
	push di
	inc di
	mov si,OFFSET password
authent_passw_loop:
	lods byte ptr [si]
	or al,al
	jz authent_passw_moved
	stosb
	jmp authent_passw_loop

authent_passw_moved:
	mov ax,di
	pop si
	sub ax,si
	dec al
	mov [si],al
	pop si
	pop ax
	clc
	ret
AuthenticateOptPassword	Endp

AuthenticateSendOptTab:
asol DB 3
aso0 DW OFFSET AuthenticateOptUnsupported
aso1 DW OFFSET AuthenticateOptUserId
aso2 DW OFFSET AuthenticateOptPassword

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AuthenticateTable
;
;		DESCRIPTION:    Authenticate tables
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AuthenticateTable:
	DW OFFSET AuthenticateSendOptTab
	DW -1
	DW -1
	DW -1
	DW -1
	DW -1
	DW -1

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IpcpSendOptTab
;
;		description:	IPCP send option data
;
;		PARAMETERS:		AL			option #
;						ES:DI		buffer to put data in
;
;		RETURNS:		NC			option supported
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IpcpOptUnsupported	Proc near
	stc
	ret
IpcpOptUnsupported	Endp

IpcpOptIp	Proc near
	stosb
	push eax
	mov al,6
	stosb
	mov eax,ds:rec_ip
	stosd
	pop eax
	clc
	ret
IpcpOptIp	Endp

IpcpOptDns1	Proc near
	stosb
	push eax
	mov al,6
	stosb
	mov eax,ds:ppp_dns1
	stosd
	pop eax
	clc
	ret
IpcpOptDns1	Endp

IpcpOptDns2	Proc near
	stosb
	push eax
	mov al,6
	stosb
	mov eax,ds:ppp_dns2
	stosd
	pop eax
	clc
	ret
IpcpOptDns2	Endp

IpcpSendOptTab:
isol DB 84h
iso00 DW OFFSET IpcpOptUnsupported
iso01 DW OFFSET IpcpOptUnsupported
iso02 DW OFFSET IpcpOptUnsupported
iso03 DW OFFSET IpcpOptIp
iso04 DW OFFSET IpcpOptUnsupported
iso05 DW OFFSET IpcpOptUnsupported
iso06 DW OFFSET IpcpOptUnsupported
iso07 DW OFFSET IpcpOptUnsupported
iso08 DW OFFSET IpcpOptUnsupported
iso09 DW OFFSET IpcpOptUnsupported
iso0A DW OFFSET IpcpOptUnsupported
iso0B DW OFFSET IpcpOptUnsupported
iso0C DW OFFSET IpcpOptUnsupported
iso0D DW OFFSET IpcpOptUnsupported
iso0E DW OFFSET IpcpOptUnsupported
iso0F DW OFFSET IpcpOptUnsupported
iso10 DW OFFSET IpcpOptUnsupported
iso11 DW OFFSET IpcpOptUnsupported
iso12 DW OFFSET IpcpOptUnsupported
iso13 DW OFFSET IpcpOptUnsupported
iso14 DW OFFSET IpcpOptUnsupported
iso15 DW OFFSET IpcpOptUnsupported
iso16 DW OFFSET IpcpOptUnsupported
iso17 DW OFFSET IpcpOptUnsupported
iso18 DW OFFSET IpcpOptUnsupported
iso19 DW OFFSET IpcpOptUnsupported
iso1A DW OFFSET IpcpOptUnsupported
iso1B DW OFFSET IpcpOptUnsupported
iso1C DW OFFSET IpcpOptUnsupported
iso1D DW OFFSET IpcpOptUnsupported
iso1E DW OFFSET IpcpOptUnsupported
iso1F DW OFFSET IpcpOptUnsupported
iso20 DW OFFSET IpcpOptUnsupported
iso21 DW OFFSET IpcpOptUnsupported
iso22 DW OFFSET IpcpOptUnsupported
iso23 DW OFFSET IpcpOptUnsupported
iso24 DW OFFSET IpcpOptUnsupported
iso25 DW OFFSET IpcpOptUnsupported
iso26 DW OFFSET IpcpOptUnsupported
iso27 DW OFFSET IpcpOptUnsupported
iso28 DW OFFSET IpcpOptUnsupported
iso29 DW OFFSET IpcpOptUnsupported
iso2A DW OFFSET IpcpOptUnsupported
iso2B DW OFFSET IpcpOptUnsupported
iso2C DW OFFSET IpcpOptUnsupported
iso2D DW OFFSET IpcpOptUnsupported
iso2E DW OFFSET IpcpOptUnsupported
iso2F DW OFFSET IpcpOptUnsupported
iso30 DW OFFSET IpcpOptUnsupported
iso31 DW OFFSET IpcpOptUnsupported
iso32 DW OFFSET IpcpOptUnsupported
iso33 DW OFFSET IpcpOptUnsupported
iso34 DW OFFSET IpcpOptUnsupported
iso35 DW OFFSET IpcpOptUnsupported
iso36 DW OFFSET IpcpOptUnsupported
iso37 DW OFFSET IpcpOptUnsupported
iso38 DW OFFSET IpcpOptUnsupported
iso39 DW OFFSET IpcpOptUnsupported
iso3A DW OFFSET IpcpOptUnsupported
iso3B DW OFFSET IpcpOptUnsupported
iso3C DW OFFSET IpcpOptUnsupported
iso3D DW OFFSET IpcpOptUnsupported
iso3E DW OFFSET IpcpOptUnsupported
iso3F DW OFFSET IpcpOptUnsupported
iso40 DW OFFSET IpcpOptUnsupported
iso41 DW OFFSET IpcpOptUnsupported
iso42 DW OFFSET IpcpOptUnsupported
iso43 DW OFFSET IpcpOptUnsupported
iso44 DW OFFSET IpcpOptUnsupported
iso45 DW OFFSET IpcpOptUnsupported
iso46 DW OFFSET IpcpOptUnsupported
iso47 DW OFFSET IpcpOptUnsupported
iso48 DW OFFSET IpcpOptUnsupported
iso49 DW OFFSET IpcpOptUnsupported
iso4A DW OFFSET IpcpOptUnsupported
iso4B DW OFFSET IpcpOptUnsupported
iso4C DW OFFSET IpcpOptUnsupported
iso4D DW OFFSET IpcpOptUnsupported
iso4E DW OFFSET IpcpOptUnsupported
iso4F DW OFFSET IpcpOptUnsupported
iso50 DW OFFSET IpcpOptUnsupported
iso51 DW OFFSET IpcpOptUnsupported
iso52 DW OFFSET IpcpOptUnsupported
iso53 DW OFFSET IpcpOptUnsupported
iso54 DW OFFSET IpcpOptUnsupported
iso55 DW OFFSET IpcpOptUnsupported
iso56 DW OFFSET IpcpOptUnsupported
iso57 DW OFFSET IpcpOptUnsupported
iso58 DW OFFSET IpcpOptUnsupported
iso59 DW OFFSET IpcpOptUnsupported
iso5A DW OFFSET IpcpOptUnsupported
iso5B DW OFFSET IpcpOptUnsupported
iso5C DW OFFSET IpcpOptUnsupported
iso5D DW OFFSET IpcpOptUnsupported
iso5E DW OFFSET IpcpOptUnsupported
iso5F DW OFFSET IpcpOptUnsupported
iso60 DW OFFSET IpcpOptUnsupported
iso61 DW OFFSET IpcpOptUnsupported
iso62 DW OFFSET IpcpOptUnsupported
iso63 DW OFFSET IpcpOptUnsupported
iso64 DW OFFSET IpcpOptUnsupported
iso65 DW OFFSET IpcpOptUnsupported
iso66 DW OFFSET IpcpOptUnsupported
iso67 DW OFFSET IpcpOptUnsupported
iso68 DW OFFSET IpcpOptUnsupported
iso69 DW OFFSET IpcpOptUnsupported
iso6A DW OFFSET IpcpOptUnsupported
iso6B DW OFFSET IpcpOptUnsupported
iso6C DW OFFSET IpcpOptUnsupported
iso6D DW OFFSET IpcpOptUnsupported
iso6E DW OFFSET IpcpOptUnsupported
iso6F DW OFFSET IpcpOptUnsupported
iso70 DW OFFSET IpcpOptUnsupported
iso71 DW OFFSET IpcpOptUnsupported
iso72 DW OFFSET IpcpOptUnsupported
iso73 DW OFFSET IpcpOptUnsupported
iso74 DW OFFSET IpcpOptUnsupported
iso75 DW OFFSET IpcpOptUnsupported
iso76 DW OFFSET IpcpOptUnsupported
iso77 DW OFFSET IpcpOptUnsupported
iso78 DW OFFSET IpcpOptUnsupported
iso79 DW OFFSET IpcpOptUnsupported
iso7A DW OFFSET IpcpOptUnsupported
iso7B DW OFFSET IpcpOptUnsupported
iso7C DW OFFSET IpcpOptUnsupported
iso7D DW OFFSET IpcpOptUnsupported
iso7E DW OFFSET IpcpOptUnsupported
iso7F DW OFFSET IpcpOptUnsupported
iso80 DW OFFSET IpcpOptUnsupported
iso81 DW OFFSET IpcpOptDns1
iso82 DW OFFSET IpcpOptUnsupported
iso83 DW OFFSET IpcpOptDns2

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IpcpOptCheckTab
;
;		DESCRIPTION:    Check if IPCP option is supported
;
;		PARAMETERS:		AL		option
;						CL		option size
;
;		RETURNS:		NC		ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IpcpOptCheckUnsupported	Proc near
	stc
	ret
IpcpOptCheckUnsupported	Endp

IpcpOptCheckIp	Proc near
	cmp [bx].lcp_opt_len,4
	jne check_addr_fail
	clc
	ret
check_addr_fail:
	stc
	ret
IpcpOptCheckIp	Endp

IpcpOptCheckTab:
iocl DB 4
ioc0 DW OFFSET IpcpOptCheckUnsupported
ioc1 DW OFFSET IpcpOptCheckUnsupported
ioc2 DW OFFSET IpcpOptCheckUnsupported
ioc3 DW OFFSET IpcpOptCheckIp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IpcpOptValidateTab
;
;		DESCRIPTION:    Validate IPCP option
;
;		PARAMETERS:		AL		option
;						CL		size of option
;						SI		option data
;
;		RETURNS:		NC		ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IpcpOptValidateOk	Proc near
	clc
	ret
IpcpOptValidateOk	Endp

IpcpOptValidateFail	Proc near
	stc
	ret
IpcpOptValidateFail	Endp

IpcpOptValidateTab:
iovl DB 4
iov0 DW OFFSET IpcpOptValidateFail
iov1 DW OFFSET IpcpOptValidateFail
iov2 DW OFFSET IpcpOptValidateFail
iov3 DW OFFSET IpcpOptValidateOk

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IpcpOptAcceptTab
;
;		DESCRIPTION:    Accept IPCP option
;
;		PARAMETERS:		AL		option
;						CL		size of option
;						SI		option data
;
;		RETURNS:		NC		ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IpcpOptAcceptNoAction	Proc near
	ret
IpcpOptAcceptNoAction	Endp

IpcpOptAcceptIp	Proc near
	mov eax,[si]
	mov ds:rec_ip,eax
	ret
IpcpOptAcceptIp	Endp

IpcpOptAcceptDns1	Proc near
	mov eax,[si]
	mov ds:ppp_dns1,eax
	ret
IpcpOptAcceptDns1	Endp

IpcpOptAcceptDns2	Proc near
	mov eax,[si]
	mov ds:ppp_dns2,eax
	ret
IpcpOptAcceptDns2	Endp

IpcpOptAcceptTab:
ioal DB 84h
ioa00 DW OFFSET IpcpOptAcceptNoAction
ioa01 DW OFFSET IpcpOptAcceptNoAction
ioa02 DW OFFSET IpcpOptAcceptNoAction
ioa03 DW OFFSET IpcpOptAcceptIp
ioa04 DW OFFSET IpcpOptAcceptNoAction
ioa05 DW OFFSET IpcpOptAcceptNoAction
ioa06 DW OFFSET IpcpOptAcceptNoAction
ioa07 DW OFFSET IpcpOptAcceptNoAction
ioa08 DW OFFSET IpcpOptAcceptNoAction
ioa09 DW OFFSET IpcpOptAcceptNoAction
ioa0A DW OFFSET IpcpOptAcceptNoAction
ioa0B DW OFFSET IpcpOptAcceptNoAction
ioa0C DW OFFSET IpcpOptAcceptNoAction
ioa0D DW OFFSET IpcpOptAcceptNoAction
ioa0E DW OFFSET IpcpOptAcceptNoAction
ioa0F DW OFFSET IpcpOptAcceptNoAction
ioa10 DW OFFSET IpcpOptAcceptNoAction
ioa11 DW OFFSET IpcpOptAcceptNoAction
ioa12 DW OFFSET IpcpOptAcceptNoAction
ioa13 DW OFFSET IpcpOptAcceptNoAction
ioa14 DW OFFSET IpcpOptAcceptNoAction
ioa15 DW OFFSET IpcpOptAcceptNoAction
ioa16 DW OFFSET IpcpOptAcceptNoAction
ioa17 DW OFFSET IpcpOptAcceptNoAction
ioa18 DW OFFSET IpcpOptAcceptNoAction
ioa19 DW OFFSET IpcpOptAcceptNoAction
ioa1A DW OFFSET IpcpOptAcceptNoAction
ioa1B DW OFFSET IpcpOptAcceptNoAction
ioa1C DW OFFSET IpcpOptAcceptNoAction
ioa1D DW OFFSET IpcpOptAcceptNoAction
ioa1E DW OFFSET IpcpOptAcceptNoAction
ioa1F DW OFFSET IpcpOptAcceptNoAction
ioa20 DW OFFSET IpcpOptAcceptNoAction
ioa21 DW OFFSET IpcpOptAcceptNoAction
ioa22 DW OFFSET IpcpOptAcceptNoAction
ioa23 DW OFFSET IpcpOptAcceptNoAction
ioa24 DW OFFSET IpcpOptAcceptNoAction
ioa25 DW OFFSET IpcpOptAcceptNoAction
ioa26 DW OFFSET IpcpOptAcceptNoAction
ioa27 DW OFFSET IpcpOptAcceptNoAction
ioa28 DW OFFSET IpcpOptAcceptNoAction
ioa29 DW OFFSET IpcpOptAcceptNoAction
ioa2A DW OFFSET IpcpOptAcceptNoAction
ioa2B DW OFFSET IpcpOptAcceptNoAction
ioa2C DW OFFSET IpcpOptAcceptNoAction
ioa2D DW OFFSET IpcpOptAcceptNoAction
ioa2E DW OFFSET IpcpOptAcceptNoAction
ioa2F DW OFFSET IpcpOptAcceptNoAction
ioa30 DW OFFSET IpcpOptAcceptNoAction
ioa31 DW OFFSET IpcpOptAcceptNoAction
ioa32 DW OFFSET IpcpOptAcceptNoAction
ioa33 DW OFFSET IpcpOptAcceptNoAction
ioa34 DW OFFSET IpcpOptAcceptNoAction
ioa35 DW OFFSET IpcpOptAcceptNoAction
ioa36 DW OFFSET IpcpOptAcceptNoAction
ioa37 DW OFFSET IpcpOptAcceptNoAction
ioa38 DW OFFSET IpcpOptAcceptNoAction
ioa39 DW OFFSET IpcpOptAcceptNoAction
ioa3A DW OFFSET IpcpOptAcceptNoAction
ioa3B DW OFFSET IpcpOptAcceptNoAction
ioa3C DW OFFSET IpcpOptAcceptNoAction
ioa3D DW OFFSET IpcpOptAcceptNoAction
ioa3E DW OFFSET IpcpOptAcceptNoAction
ioa3F DW OFFSET IpcpOptAcceptNoAction
ioa40 DW OFFSET IpcpOptAcceptNoAction
ioa41 DW OFFSET IpcpOptAcceptNoAction
ioa42 DW OFFSET IpcpOptAcceptNoAction
ioa43 DW OFFSET IpcpOptAcceptNoAction
ioa44 DW OFFSET IpcpOptAcceptNoAction
ioa45 DW OFFSET IpcpOptAcceptNoAction
ioa46 DW OFFSET IpcpOptAcceptNoAction
ioa47 DW OFFSET IpcpOptAcceptNoAction
ioa48 DW OFFSET IpcpOptAcceptNoAction
ioa49 DW OFFSET IpcpOptAcceptNoAction
ioa4A DW OFFSET IpcpOptAcceptNoAction
ioa4B DW OFFSET IpcpOptAcceptNoAction
ioa4C DW OFFSET IpcpOptAcceptNoAction
ioa4D DW OFFSET IpcpOptAcceptNoAction
ioa4E DW OFFSET IpcpOptAcceptNoAction
ioa4F DW OFFSET IpcpOptAcceptNoAction
ioa50 DW OFFSET IpcpOptAcceptNoAction
ioa51 DW OFFSET IpcpOptAcceptNoAction
ioa52 DW OFFSET IpcpOptAcceptNoAction
ioa53 DW OFFSET IpcpOptAcceptNoAction
ioa54 DW OFFSET IpcpOptAcceptNoAction
ioa55 DW OFFSET IpcpOptAcceptNoAction
ioa56 DW OFFSET IpcpOptAcceptNoAction
ioa57 DW OFFSET IpcpOptAcceptNoAction
ioa58 DW OFFSET IpcpOptAcceptNoAction
ioa59 DW OFFSET IpcpOptAcceptNoAction
ioa5A DW OFFSET IpcpOptAcceptNoAction
ioa5B DW OFFSET IpcpOptAcceptNoAction
ioa5C DW OFFSET IpcpOptAcceptNoAction
ioa5D DW OFFSET IpcpOptAcceptNoAction
ioa5E DW OFFSET IpcpOptAcceptNoAction
ioa5F DW OFFSET IpcpOptAcceptNoAction
ioa60 DW OFFSET IpcpOptAcceptNoAction
ioa61 DW OFFSET IpcpOptAcceptNoAction
ioa62 DW OFFSET IpcpOptAcceptNoAction
ioa63 DW OFFSET IpcpOptAcceptNoAction
ioa64 DW OFFSET IpcpOptAcceptNoAction
ioa65 DW OFFSET IpcpOptAcceptNoAction
ioa66 DW OFFSET IpcpOptAcceptNoAction
ioa67 DW OFFSET IpcpOptAcceptNoAction
ioa68 DW OFFSET IpcpOptAcceptNoAction
ioa69 DW OFFSET IpcpOptAcceptNoAction
ioa6A DW OFFSET IpcpOptAcceptNoAction
ioa6B DW OFFSET IpcpOptAcceptNoAction
ioa6C DW OFFSET IpcpOptAcceptNoAction
ioa6D DW OFFSET IpcpOptAcceptNoAction
ioa6E DW OFFSET IpcpOptAcceptNoAction
ioa6F DW OFFSET IpcpOptAcceptNoAction
ioa70 DW OFFSET IpcpOptAcceptNoAction
ioa71 DW OFFSET IpcpOptAcceptNoAction
ioa72 DW OFFSET IpcpOptAcceptNoAction
ioa73 DW OFFSET IpcpOptAcceptNoAction
ioa74 DW OFFSET IpcpOptAcceptNoAction
ioa75 DW OFFSET IpcpOptAcceptNoAction
ioa76 DW OFFSET IpcpOptAcceptNoAction
ioa77 DW OFFSET IpcpOptAcceptNoAction
ioa78 DW OFFSET IpcpOptAcceptNoAction
ioa79 DW OFFSET IpcpOptAcceptNoAction
ioa7A DW OFFSET IpcpOptAcceptNoAction
ioa7B DW OFFSET IpcpOptAcceptNoAction
ioa7C DW OFFSET IpcpOptAcceptNoAction
ioa7D DW OFFSET IpcpOptAcceptNoAction
ioa7E DW OFFSET IpcpOptAcceptNoAction
ioa7F DW OFFSET IpcpOptAcceptNoAction
ioa80 DW OFFSET IpcpOptAcceptNoAction
ioa81 DW OFFSET IpcpOptAcceptDns1
ioa82 DW OFFSET IpcpOptAcceptNoAction
ioa83 DW OFFSET IpcpOptAcceptDns2

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IpcpOptAckTab
;
;		DESCRIPTION:    IPCP options acked
;
;		PARAMETERS:		AL		option
;						CL		size of option
;						SI		option data
;
;		RETURNS:		NC		option modified
;						CY		not legal to nak
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IpcpOptAckNoAction	Proc near
	stc
	ret
IpcpOptAckNoAction	Endp

IpcpOptAckIp	Proc near
	mov eax,[si]
	mov ds:send_ip,eax
	ret
IpcpOptAckIp	Endp

IpcpOptAckTab:
iool DB 4
ioo0 DW OFFSET IpcpOptAckNoAction
ioo1 DW OFFSET IpcpOptAckNoAction
ioo2 DW OFFSET IpcpOptAckNoAction
ioo3 DW OFFSET IpcpOptAckIp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IpcpOptNakTab
;
;		DESCRIPTION:    IPCP options naked
;
;		PARAMETERS:		AL		option
;						CL		size of option
;						SI		option data
;
;		RETURNS:		NC		option modified
;						CY		not legal to nak
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IpcpOptNakFatal	Proc near
	stc
	ret
IpcpOptNakFatal	Endp

IpcpOptNakIp	Proc near
	mov eax,[si]
	mov ds:rec_ip,eax
	ret
IpcpOptNakIp	Endp

IpcpOptNakDns1	Proc near
	mov eax,[si]
	mov ds:ppp_dns1,eax
	ret
IpcpOptNakDns1	Endp

IpcpOptNakDns2	Proc near
	mov eax,[si]
	mov ds:ppp_dns2,eax
	ret
IpcpOptNakDns2	Endp

IpcpOptNakTab:
ionl DB 84h
ion00 DW OFFSET IpcpOptNakFatal
ion01 DW OFFSET IpcpOptNakFatal
ion02 DW OFFSET IpcpOptNakFatal
ion03 DW OFFSET IpcpOptNakIp
ion04 DW OFFSET IpcpOptNakFatal
ion05 DW OFFSET IpcpOptNakFatal
ion06 DW OFFSET IpcpOptNakFatal
ion07 DW OFFSET IpcpOptNakFatal
ion08 DW OFFSET IpcpOptNakFatal
ion09 DW OFFSET IpcpOptNakFatal
ion0A DW OFFSET IpcpOptNakFatal
ion0B DW OFFSET IpcpOptNakFatal
ion0C DW OFFSET IpcpOptNakFatal
ion0D DW OFFSET IpcpOptNakFatal
ion0E DW OFFSET IpcpOptNakFatal
ion0F DW OFFSET IpcpOptNakFatal
ion10 DW OFFSET IpcpOptNakFatal
ion11 DW OFFSET IpcpOptNakFatal
ion12 DW OFFSET IpcpOptNakFatal
ion13 DW OFFSET IpcpOptNakFatal
ion14 DW OFFSET IpcpOptNakFatal
ion15 DW OFFSET IpcpOptNakFatal
ion16 DW OFFSET IpcpOptNakFatal
ion17 DW OFFSET IpcpOptNakFatal
ion18 DW OFFSET IpcpOptNakFatal
ion19 DW OFFSET IpcpOptNakFatal
ion1A DW OFFSET IpcpOptNakFatal
ion1B DW OFFSET IpcpOptNakFatal
ion1C DW OFFSET IpcpOptNakFatal
ion1D DW OFFSET IpcpOptNakFatal
ion1E DW OFFSET IpcpOptNakFatal
ion1F DW OFFSET IpcpOptNakFatal
ion20 DW OFFSET IpcpOptNakFatal
ion21 DW OFFSET IpcpOptNakFatal
ion22 DW OFFSET IpcpOptNakFatal
ion23 DW OFFSET IpcpOptNakFatal
ion24 DW OFFSET IpcpOptNakFatal
ion25 DW OFFSET IpcpOptNakFatal
ion26 DW OFFSET IpcpOptNakFatal
ion27 DW OFFSET IpcpOptNakFatal
ion28 DW OFFSET IpcpOptNakFatal
ion29 DW OFFSET IpcpOptNakFatal
ion2A DW OFFSET IpcpOptNakFatal
ion2B DW OFFSET IpcpOptNakFatal
ion2C DW OFFSET IpcpOptNakFatal
ion2D DW OFFSET IpcpOptNakFatal
ion2E DW OFFSET IpcpOptNakFatal
ion2F DW OFFSET IpcpOptNakFatal
ion30 DW OFFSET IpcpOptNakFatal
ion31 DW OFFSET IpcpOptNakFatal
ion32 DW OFFSET IpcpOptNakFatal
ion33 DW OFFSET IpcpOptNakFatal
ion34 DW OFFSET IpcpOptNakFatal
ion35 DW OFFSET IpcpOptNakFatal
ion36 DW OFFSET IpcpOptNakFatal
ion37 DW OFFSET IpcpOptNakFatal
ion38 DW OFFSET IpcpOptNakFatal
ion39 DW OFFSET IpcpOptNakFatal
ion3A DW OFFSET IpcpOptNakFatal
ion3B DW OFFSET IpcpOptNakFatal
ion3C DW OFFSET IpcpOptNakFatal
ion3D DW OFFSET IpcpOptNakFatal
ion3E DW OFFSET IpcpOptNakFatal
ion3F DW OFFSET IpcpOptNakFatal
ion40 DW OFFSET IpcpOptNakFatal
ion41 DW OFFSET IpcpOptNakFatal
ion42 DW OFFSET IpcpOptNakFatal
ion43 DW OFFSET IpcpOptNakFatal
ion44 DW OFFSET IpcpOptNakFatal
ion45 DW OFFSET IpcpOptNakFatal
ion46 DW OFFSET IpcpOptNakFatal
ion47 DW OFFSET IpcpOptNakFatal
ion48 DW OFFSET IpcpOptNakFatal
ion49 DW OFFSET IpcpOptNakFatal
ion4A DW OFFSET IpcpOptNakFatal
ion4B DW OFFSET IpcpOptNakFatal
ion4C DW OFFSET IpcpOptNakFatal
ion4D DW OFFSET IpcpOptNakFatal
ion4E DW OFFSET IpcpOptNakFatal
ion4F DW OFFSET IpcpOptNakFatal
ion50 DW OFFSET IpcpOptNakFatal
ion51 DW OFFSET IpcpOptNakFatal
ion52 DW OFFSET IpcpOptNakFatal
ion53 DW OFFSET IpcpOptNakFatal
ion54 DW OFFSET IpcpOptNakFatal
ion55 DW OFFSET IpcpOptNakFatal
ion56 DW OFFSET IpcpOptNakFatal
ion57 DW OFFSET IpcpOptNakFatal
ion58 DW OFFSET IpcpOptNakFatal
ion59 DW OFFSET IpcpOptNakFatal
ion5A DW OFFSET IpcpOptNakFatal
ion5B DW OFFSET IpcpOptNakFatal
ion5C DW OFFSET IpcpOptNakFatal
ion5D DW OFFSET IpcpOptNakFatal
ion5E DW OFFSET IpcpOptNakFatal
ion5F DW OFFSET IpcpOptNakFatal
ion60 DW OFFSET IpcpOptNakFatal
ion61 DW OFFSET IpcpOptNakFatal
ion62 DW OFFSET IpcpOptNakFatal
ion63 DW OFFSET IpcpOptNakFatal
ion64 DW OFFSET IpcpOptNakFatal
ion65 DW OFFSET IpcpOptNakFatal
ion66 DW OFFSET IpcpOptNakFatal
ion67 DW OFFSET IpcpOptNakFatal
ion68 DW OFFSET IpcpOptNakFatal
ion69 DW OFFSET IpcpOptNakFatal
ion6A DW OFFSET IpcpOptNakFatal
ion6B DW OFFSET IpcpOptNakFatal
ion6C DW OFFSET IpcpOptNakFatal
ion6D DW OFFSET IpcpOptNakFatal
ion6E DW OFFSET IpcpOptNakFatal
ion6F DW OFFSET IpcpOptNakFatal
ion70 DW OFFSET IpcpOptNakFatal
ion71 DW OFFSET IpcpOptNakFatal
ion72 DW OFFSET IpcpOptNakFatal
ion73 DW OFFSET IpcpOptNakFatal
ion74 DW OFFSET IpcpOptNakFatal
ion75 DW OFFSET IpcpOptNakFatal
ion76 DW OFFSET IpcpOptNakFatal
ion77 DW OFFSET IpcpOptNakFatal
ion78 DW OFFSET IpcpOptNakFatal
ion79 DW OFFSET IpcpOptNakFatal
ion7A DW OFFSET IpcpOptNakFatal
ion7B DW OFFSET IpcpOptNakFatal
ion7C DW OFFSET IpcpOptNakFatal
ion7D DW OFFSET IpcpOptNakFatal
ion7E DW OFFSET IpcpOptNakFatal
ion7F DW OFFSET IpcpOptNakFatal
ion80 DW OFFSET IpcpOptNakFatal
ion81 DW OFFSET IpcpOptNakDns1
ion82 DW OFFSET IpcpOptNakFatal
ion83 DW OFFSET IpcpOptNakDns2

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IpcpOptRejectTab
;
;		DESCRIPTION:    IPCP options rejected
;
;		PARAMETERS:		AL		option
;						CL		size of option
;						SI		option data
;
;		RETURNS:		NC		option removed
;						CY		not legal to reject
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IpcpOptRejectOk	Proc near
	clc
	ret
IpcpOptRejectOk	Endp

IpcpOptRejectFatal	Proc near
	stc
	ret
IpcpOptRejectFatal	Endp

IpcpOptRejectTab:
iorl DB 4
ior0 DW OFFSET IpcpOptRejectOk
ior1 DW OFFSET IpcpOptRejectOk
ior2 DW OFFSET IpcpOptRejectOk
ior3 DW OFFSET IpcpOptRejectFatal

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IpcpTable
;
;		DESCRIPTION:    IPCP tables
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IpcpTable:
	DW OFFSET IpcpSendOptTab
	DW OFFSET IpcpOptCheckTab
	DW OFFSET IpcpOptValidateTab
	DW OFFSET IpcpOptAcceptTab
	DW OFFSET IpcpOptAckTab
	DW OFFSET IpcpOptNakTab
	DW OFFSET IpcpOptRejectTab

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendData
;
;		description:	Send data
;
;		PARAMETERS:		DS:SI		Buffer
;						CX			Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendData	Proc near
	push es
	push ax
	push cx
	push dx
	push si
	push di
;	
	mov ax,ppp_data_sel
	mov es,ax
;
	cli
	mov di,es:send_tail
	mov ax,di
	add ax,cx
	add ax,4
	cmp ax,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_data_set_tail
	sub ax,SEND_BUFFER_SIZE
send_data_set_tail:
	mov es:send_tail,ax
	sti
	push di
	push cx
;
	add di,2
send_data_loop:
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_data_next
	sub di,SEND_BUFFER_SIZE
send_data_next:
	cmp di,es:send_head
	je send_data_done
	movsb
	loop send_data_loop
;
	xor al,al
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_pad1
	sub di,SEND_BUFFER_SIZE
send_pad1:
	cmp di,es:send_head
	je send_data_done
	stosb
;
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_pad2
	sub di,SEND_BUFFER_SIZE
send_pad2:
	cmp di,es:send_head
	je send_data_done
	stosb
	mov bx,di
;
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_pad3
	sub di,SEND_BUFFER_SIZE
send_pad3:
	cmp di,es:send_head
	je send_data_done
	stosb
;
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_pad4
	sub di,SEND_BUFFER_SIZE
send_pad4:
	cmp di,es:send_head
	je send_data_done
	stosb
;
	pop cx
	add cx,2
;
	pop si
	cli
	mov es:[si],cl
	inc si
	cmp si,OFFSET send_buf + SEND_BUFFER_SIZE
	jne send_data_size_wrap
	sub si,SEND_BUFFER_SIZE
send_data_size_wrap:
	mov es:[si],ch
	sti
;
	mov dx,es:base
	inc dx
	mov al,0Fh
	out dx,al
;
send_data_done:
	pop di
	pop si
	pop dx
	pop cx
	pop ax
	pop es
	ret
SendData	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendConfigureReq
;
;		description:	Send configure-request
;
;		PARARMETERS:	FS	protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendConfigureReq	Proc near
	push es
	pusha
;
	mov ax,ds
	mov es,ax
	mov di,OFFSET lcp_retransmit_buf
;
	mov [di].hdlc_addr,0FFh
	mov [di].hdlc_control,3
	add di,ds:send_hdlc_len
	mov ax,fs:proto_nr
	xchg al,ah
	stosw
;
	push di
	mov [di].lcp_code,1
	mov al,fs:proto_id
	mov [di].lcp_id,al
	add di,SIZE lcp_header
;
	xor dx,dx
	mov si,OFFSET send_options
	mov bx,fs:send_opt_tab
	mov cl,cs:[bx]
	mov ch,cl
	shr cl,3
	inc cl
	inc bx
send_config_size_loop:
	lods byte ptr fs:[si]
	or al,al
	jz send_config_size_skip
	mov ah,8
send_config_size_bit_loop:
	shr al,1
	jnc send_config_size_next_bit
	push ax
	mov al,dl
	call word ptr cs:[bx]
	pop ax
	jnc send_config_size_next_bit
	push bx
	mov bx,OFFSET send_options
	btr fs:[bx],dx
	pop bx
send_config_size_next_bit:	
	inc dx
	add bx,2
	sub ch,1
	jz send_config_size_done
	sub ah,1
	jnz send_config_size_bit_loop
	jmp send_config_size_next

send_config_size_skip:
	add dx,8
	add bx,16
	sub ch,8
	jbe send_config_size_done
send_config_size_next:
	sub cl,1
	jnz send_config_size_loop

send_config_size_done:
	mov ax,di
	mov cx,ax
	pop di
	sub ax,di
	xchg al,ah
	mov [di].lcp_len,ax
	sub cx,OFFSET lcp_retransmit_buf
	mov si,OFFSET lcp_retransmit_buf
	call SendData
;
	popa
	pop es
	ret
SendConfigureReq	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OptCheck
;
;		DESCRIPTION:    Check options, send reject if not acceptable
;
;		PARAMETERS:		DS:SI	message
;						FS		protocol selector
;
;		RETRURNS:		NC		options acceptable
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OptCheck	Proc near
	push es
	pusha
;
	mov ax,ds
	mov es,ax
	mov di,OFFSET lcp_send_buf
;
	mov [di].hdlc_addr,0FFh
	mov [di].hdlc_control,3
	add di,ds:send_hdlc_len
	mov ax,fs:proto_nr
	xchg al,ah
	stosw
;
	mov al,[si].lcp_id
	mov [di].lcp_id,al
	mov [di].lcp_code,4
	add di,SIZE lcp_header
;
	push di
	mov bx,fs:opt_check_tab
	cmp bx,-1
	je opt_check_test
	mov cx,[si].lcp_len
	xchg cl,ch
	add si,SIZE lcp_header
	sub cx,SIZE lcp_header
	jz opt_check_test
opt_check_loop:
	movzx ax,[si].lcp_opt_type
	cmp al,cs:[bx]
	jae opt_check_reject
	push bx
	push cx
	push si
	mov cl,[si].lcp_opt_len
	add si,SIZE lcp_option_header
	add bx,ax
	add bx,ax
	call word ptr cs:[bx+1]
	pop si
	pop cx
	pop bx
	jc opt_check_reject
	movzx ax,[si].lcp_opt_len
	add si,ax
	jmp opt_check_next

opt_check_reject:
	movzx ax,[si].lcp_opt_len
	push cx
	mov cx,ax
	rep movsb
	pop cx

opt_check_next:
	sub cx,ax
	jz opt_check_test
	jnc opt_check_loop

opt_check_test:
	mov ax,di
	mov cx,ax
	pop di
	sub ax,di
	clc
	jz opt_check_done
;
	sub cx,OFFSET lcp_send_buf
	add ax,SIZE lcp_header
	sub di,SIZE lcp_header
	xchg al,ah
	mov [di].lcp_len,ax
	mov si,OFFSET lcp_send_buf
	call SendData
	stc
opt_check_done:
;
	popa
	pop es
	ret
OptCheck	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OptValidate
;
;		DESCRIPTION:    Validate options, send nak if not acceptable
;
;		PARAMETERS:		DS:SI	message
;						FS		protocol selector
;
;		RETRURNS:		NC		options acceptable
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OptValidate	Proc near
	push es
	pusha
;
	mov ax,ds
	mov es,ax
	mov di,OFFSET lcp_send_buf
;
	mov [di].hdlc_addr,0FFh
	mov [di].hdlc_control,3
	add di,ds:send_hdlc_len
	mov ax,fs:proto_nr
	xchg al,ah
	stosw
;
	mov al,[si].lcp_id
	mov [di].lcp_id,al
	mov [di].lcp_code,3
	add di,SIZE lcp_header
;
	push di
	mov bx,fs:opt_validate_tab
	cmp bx,-1
	je opt_validate_test
	mov cx,[si].lcp_len
	xchg cl,ch
	add si,SIZE lcp_header
	sub cx,SIZE lcp_header
	jz opt_validate_test
opt_validate_loop:
	movzx ax,[si].lcp_opt_type
	cmp al,cs:[bx]
	jae opt_validate_nak
	push bx
	push cx
	push si
	mov cl,[si].lcp_opt_len
	add si,SIZE lcp_option_header
	add bx,ax
	add bx,ax
	call word ptr cs:[bx+1]
	pop si
	pop cx
	pop bx
	jc opt_validate_nak
	movzx ax,[si].lcp_opt_len
	add si,ax
	jmp opt_validate_next

opt_validate_nak:
	movzx ax,[si].lcp_opt_len
	push cx
	mov cx,ax
	rep movsb
	pop cx

opt_validate_next:
	sub cx,ax
	jz opt_validate_test
	jnc opt_validate_loop

opt_validate_test:
	mov ax,di
	mov cx,ax
	pop di
	sub ax,di
	clc
	jz opt_validate_done
;
	sub cx,OFFSET lcp_send_buf
	add ax,SIZE lcp_header
	sub di,SIZE lcp_header
	xchg al,ah
	mov [di].lcp_len,ax
	mov si,OFFSET lcp_send_buf
	call SendData
	stc
opt_validate_done:
;
	popa
	pop es
	ret
OptValidate	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OptAck
;
;		DESCRIPTION:    Ack IP options
;
;		PARAMETERS:		DS:SI	message
;						FS		protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OptAck	Proc near
	push es
	pusha
;
	mov ax,ds
	mov es,ax
	mov di,OFFSET lcp_send_buf
;
	mov [di].hdlc_addr,0FFh
	mov [di].hdlc_control,3
	add di,ds:send_hdlc_len
	mov ax,fs:proto_nr
	xchg al,ah
	stosw
;
	mov al,[si].lcp_id
	mov [di].lcp_id,al
	mov [di].lcp_code,2
	mov ax,[si].lcp_len
	mov [di].lcp_len,ax
	add di,SIZE lcp_header
;
	mov bx,fs:opt_accept_tab
	cmp bx,-1
	je opt_accept_done
	mov cx,[si].lcp_len
	xchg cl,ch
	add si,SIZE lcp_header
	sub cx,SIZE lcp_header
	jz opt_accept_send
opt_accept_loop:
	movzx ax,[si].lcp_opt_type
	cmp al,cs:[bx]
	jae opt_accept_copy
	push bx
	push cx
	push si
	mov cl,[si].lcp_opt_len
	add si,SIZE lcp_option_header
	add bx,ax
	add bx,ax
	call word ptr cs:[bx+1]
	pop si
	pop cx
	pop bx

opt_accept_copy:
	movzx ax,[si].lcp_opt_len
	push cx
	mov cx,ax
	rep movsb
	pop cx
;
	sub cx,ax
	jz opt_accept_send
	jnc opt_accept_loop

opt_accept_send:
	mov cx,di
	sub cx,OFFSET lcp_send_buf
	mov si,OFFSET lcp_send_buf
	call SendData
opt_accept_done:
	or fs:proto_state,STATE_ACK_SENT
	test fs:proto_state,STATE_ACK_RECEIVED
	jz opt_rec_config_end
	call fs:this_layer_up
opt_rec_config_end:
	popa
	pop es
	ret
OptAck	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RecConfigureReq
;
;		DESCRIPTION:    received configure-req
;
;		PARAMETERS:		SI		Received data
;						FS		protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecConfigureReq	Proc near
	call OptCheck
	jc rec_config_req_done
	call OptValidate
	jc rec_config_req_done
	call OptAck
rec_config_req_done:
	ret
RecConfigureReq	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RecConfigureAck
;
;		DESCRIPTION:    Received configure-ack
;
;		PARAMETERS:		SI		Received data
;						FS		protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecConfigureAck	Proc near
	pusha
;
	mov al,[si].lcp_id
	cmp al,fs:proto_id
	jne rec_config_ack_done
	mov bx,fs:opt_ack_tab
	cmp bx,-1
	je rec_config_ack_test
	mov cx,[si].lcp_len
	xchg cl,ch
	add si,SIZE lcp_header
	sub cx,SIZE lcp_header
rec_config_ack_loop:
	movzx ax,[si].lcp_opt_type
	cmp al,cs:[bx]
	jae rec_config_ack_next
	push bx
	push cx
	push si
	mov cl,[si].lcp_opt_len
	add si,SIZE lcp_option_header
	add bx,ax
	add bx,ax
	call word ptr cs:[bx+1]
	pop si
	pop cx
	pop bx

rec_config_ack_next:
	movzx ax,[si].lcp_opt_len
	add si,ax
	sub cx,ax
	jz rec_config_ack_test
	jnc rec_config_ack_loop

rec_config_ack_test:
	or fs:proto_state,STATE_ACK_RECEIVED
	cmp fs:opt_accept_tab,-1
	je rec_config_ack_up
	test fs:proto_state,STATE_ACK_SENT
	jz rec_config_ack_done
rec_config_ack_up:
	call fs:this_layer_up
rec_config_ack_done:
	popa
	ret
RecConfigureAck	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RecConfigureNak
;
;		DESCRIPTION:    Received configure-nak
;
;		PARAMETERS:		SI		Received data
;						FS		protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecConfigureNak	Proc near
	pusha
;
	mov al,[si].lcp_id
	cmp al,fs:proto_id
	jne rec_config_nak_done
	mov bx,fs:opt_nak_tab
	cmp bx,-1
	je rec_config_nak_fail
	mov cx,[si].lcp_len
	xchg cl,ch
	add si,SIZE lcp_header
	sub cx,SIZE lcp_header
rec_config_nak_loop:
	movzx ax,[si].lcp_opt_type
	cmp al,cs:[bx]
	jae rec_config_nak_fail
	push bx
	push cx
	push si
	mov cl,[si].lcp_opt_len
	add si,SIZE lcp_option_header
	add bx,ax
	add bx,ax
	call word ptr cs:[bx+1]
	pop si
	pop cx
	pop bx
	jc rec_config_nak_fail
;
	movzx ax,[si].lcp_opt_len
	add si,ax
	sub cx,ax
	jz rec_config_nak_resend
	jnc rec_config_nak_loop

rec_config_nak_resend:
	inc fs:proto_id
	call SendConfigureReq
	jmp rec_config_nak_done

rec_config_nak_fail:
	call fs:this_layer_down

rec_config_nak_done:
	popa
	ret
RecConfigureNak	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RecConfigureReject
;
;		DESCRIPTION:    Received configure-reject
;
;		PARAMETERS:		SI		Received data
;						FS		protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecConfigureReject	Proc near
	pusha
;
	mov al,[si].lcp_id
	cmp al,fs:proto_id
	jne rec_config_reject_done
	mov bx,fs:opt_reject_tab
	cmp bx,-1
	je rec_config_reject_fail
	mov cx,[si].lcp_len
	xchg cl,ch
	add si,SIZE lcp_header
	sub cx,SIZE lcp_header
rec_config_reject_loop:
	movzx ax,[si].lcp_opt_type
	cmp al,cs:[bx]
	jae rec_config_reject_next
	push bx
	push cx
	push si
	mov cl,[si].lcp_opt_len
	add si,SIZE lcp_option_header
	add bx,ax
	add bx,ax
	call word ptr cs:[bx+1]
	pop si
	pop cx
	pop bx
	jc rec_config_reject_fail
	push bx
	mov bx,OFFSET send_options
	btr fs:[bx],ax
	pop bx

rec_config_reject_next:
	movzx ax,[si].lcp_opt_len
	add si,ax
	sub cx,ax
	jz rec_config_reject_resend
	jnc rec_config_reject_loop

rec_config_reject_resend:
	inc fs:proto_id
	call SendConfigureReq
	jmp rec_config_reject_done

rec_config_reject_fail:
	call fs:this_layer_down

rec_config_reject_done:
	popa
	ret
RecConfigureReject	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RecCodeReject
;
;		description:	received unknown code
;
;		PARARMETERS:	SI		Received data
;						FS		protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCodeReject	Proc near
	push es
	pusha
;
	mov ax,ds
	mov es,ax
	mov al,[si].lcp_code
	cmp al,7
	je send_code_reject_done
	mov di,OFFSET lcp_send_buf
;
	mov [di].hdlc_addr,0FFh
	mov [di].hdlc_control,3
	add di,ds:send_hdlc_len
	mov ax,fs:proto_nr
	xchg al,ah
	stosw
;
	push di
	mov [di].lcp_code,7
	mov al,fs:proto_id
	inc al
	stosb
	mov fs:proto_id,al
	add di,SIZE lcp_header
	mov cx,[si].lcp_len
	xchg cl,ch
	rep movsb
	mov ax,di
	mov cx,ax
	pop di
;
	sub ax,di
	xchg al,ah
	mov [di].lcp_len,ax
	sub cx,OFFSET lcp_send_buf
	mov si,OFFSET lcp_send_buf
	call SendData
send_code_reject_done:
;
	popa
	pop es
	ret
SendCodeReject	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ProtocolReceived
;
;		DESCRIPTION:    received data from protocol
;
;		PARAMETERS:		BX		offset to data in rec_buffer
;						CX		size of packet
;						FS		Protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProtocolRecTab:
prt0	DW OFFSET SendCodeReject
prt1	DW OFFSET RecConfigureReq
prt2	DW OFFSET RecConfigureAck
prt3	DW OFFSET RecConfigureNak
prt4	DW OFFSET SendCodeReject
prt5	DW OFFSET SendCodeReject

ProtocolReceived	Proc near
	mov ax,ds
	mov es,ax
	mov si,bx
	mov di,OFFSET lcp_rec_buf
rec_copy_loop:
	movsb
	cmp si,OFFSET rec_buf + REC_BUFFER_SIZE
	jne rec_copy_next
	sub si,REC_BUFFER_SIZE
rec_copy_next:
	loop rec_copy_loop
	mov ds:rec_tail,si
;
	mov si,OFFSET lcp_rec_buf	
	movzx bx,[si].lcp_code
	cmp bx,5
	jc prot_rec_handle
	mov bx,5
prot_rec_handle:
	add bx,bx
	call word ptr cs:[bx].ProtocolRecTab
	ret
ProtocolReceived	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Retransmit
;
;		description:	Retransmit timeout
;
;		PARAMETERS:		CX				Offset to protocol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Retransmit	Proc far
	mov ax,ppp_data_sel
	mov ds,ax
	mov di,cx
	mov ax,[di]
	or ax,ax
	jz retransmit_done
	mov fs,ax
	mov dx,ds:base
	add dx,6
	in al,dx
	test al,80h
	jz retransmit_done

retransmit_do:
	test fs:proto_state,STATE_ACK_RECEIVED
	jnz retransmit_done
	call SendConfigureReq
;
	mov ax,cs
	mov es,ax
	GetSystemTime
	add eax,1193*1000
	adc edx,0
	mov di,OFFSET Retransmit
	mov bx,ds:thread_id
	StopTimer
	StartTimer
retransmit_done:
	ret
Retransmit	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenProtocol
;
;		DESCRIPTION:    Creates a new protocol
;
;		PARAMETERS:		DX		protocol id
;						BX		offset to tables
;						CX		protocol handle
;						SI		offset to this-layer-up callback
;						DI		offset to this-layer-down callback
;
;		RETURNS:		FS		protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenProtocol	Proc near
	push es
	pusha
;
	mov eax,SIZE protocol_data
	AllocateSmallGlobalMem
	mov es:proto_nr,dx
	mov es:proto_id,1
	mov es:proto_state,0
	mov es:this_layer_up,si
	mov es:this_layer_down,di
	push cx
;
	mov di,OFFSET send_options
	mov al,-1
	mov cx,64
	rep stosb
;
	mov si,bx
	mov di,OFFSET send_opt_tab
	mov cx,7
	rep movs word ptr es:[di],cs:[si]	
;
	pop di
	mov ds:[di],es
	mov ax,es
	mov fs,ax
	call SendConfigureReq
;
	mov ax,cs
	mov es,ax
	GetSystemTime
	add eax,1193*1000
	adc edx,0
	mov cx,di
	mov di,OFFSET Retransmit
	mov bx,ds:thread_id
	StopTimer
	StartTimer
;
	popa
	pop es	
	ret
OpenProtocol	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CloseProtocol
;
;		DESCRIPTION:    Closes a protocol
;
;		PARAMETERS:		FS		protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseProtocol	Proc near
	push es
	push bx
	mov bx,fs
	mov es,bx
	xor bx,bx
	mov fs,bx
	FreeMem
	pop bx
	pop es
	ret
CloseProtocol	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckConnect
;
;		description:	Start Dial if neccesary
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckConnect	Proc near
	push ds
	push es
	pushad
;
check_connect_loop:
	mov ax,ds:usage_count
	or ax,ax
	jnz check_connected
	GetSystemTime
	sub eax,ds:idle_timeout
	sbb edx,ds:idle_timeout+4
	jnc check_disconnected
;
	mov bx,ds:thread_id
	StopTimer
;
	mov dx,ds:base
	add dx,6
	in al,dx
	test al,80h
	jz check_connect_done
;
	mov eax,ds:idle_timeout
	mov edx,ds:idle_timeout+4
	mov bx,cs
	mov es,bx
	mov di,OFFSET SignalTimeout
	StartTimer	
	jmp check_connect_done

check_connected:
	mov dx,ds:base
	add dx,6
	in al,dx
	test al,80h
	jnz check_connect_done
	call ConnectModem
	jmp check_connect_loop

check_disconnected:
	mov dx,ds:base
	add dx,6
	in al,dx
	test al,80h
	jz check_connect_done
	call DisconnectModem
	jmp check_connect_loop

check_connect_done:
	popad
	pop es
	pop ds
	ret
CheckConnect	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StopLcp
;
;		description:	Stop LCP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopLcp	Proc near
	push fs
;
	mov ax,ds:lcp_handle
	or ax,ax
	jz stop_lcp_closed
	mov ds:lcp_handle,0
	mov fs,ax
	call CloseProtocol
stop_lcp_closed:
	mov ax,ds:authent_handle
	or ax,ax
	jz stop_authent_closed
	mov ds:authent_handle,0
	mov fs,ax
	call CloseProtocol
stop_authent_closed:
	mov ax,ds:ipcp_handle
	or ax,ax
	jz stop_ipcp_closed
	mov ds:ipcp_handle,0
	mov fs,ax
	call CloseProtocol
stop_ipcp_closed:
	pop fs
	ret
StopLcp	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartLcp
;
;		description:	Start LCP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartLcp	Proc near
	mov ds:ppp_mode,MODE_LCP
	mov ds:id,1
	mov ds:rec_ip,0
	mov ds:ppp_dns1,0
	mov ds:ppp_dns2,0
	mov ds:rec_accm,-1
	mov ds:req_accm,0A0000h
	mov ds:rec_escape,0
	mov ds:rec_curr,OFFSET rec_buf
	mov ds:rec_head,OFFSET rec_buf
	mov ds:rec_tail,OFFSET rec_buf
;
	mov ds:send_ip,0
	mov ds:send_hdlc_len,2
	mov ds:send_proto_len,2
	mov ds:send_accm,-1
	mov ds:send_escape,0
	mov ds:send_curr,OFFSET send_buf
	mov ds:send_head,OFFSET send_buf
	mov ds:send_tail,OFFSET send_buf
;
	mov ax,ds:lcp_handle
	or ax,ax
	jnz start_lcp_done
	mov dx,0C021h
	mov bx,OFFSET LcpTable
	mov cx,OFFSET lcp_handle
	mov si,OFFSET StartAuthenticate
	mov di,OFFSET HangupLine
	call OpenProtocol
start_lcp_done:
	ret
StartLcp	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartAuthenticate
;
;		description:	Start Authentication
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartAuthenticate	Proc near
	mov ax,ds:authent_handle
	or ax,ax
	jnz start_authent_done
	mov dx,0C023h
	mov bx,OFFSET AuthenticateTable
	mov cx,OFFSET authent_handle
	mov si,OFFSET StartNcp
	mov di,OFFSET HangupLine
	call OpenProtocol
start_authent_done:
	ret
StartAuthenticate	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartNcp
;
;		description:	Start NCP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartNcp	Proc near
	mov ax,ds:ipcp_handle
	or ax,ax
	jnz start_ncp_done
	mov dx,8021h
	mov bx,OFFSET IpcpTable
	mov cx,OFFSET ipcp_handle
	mov si,OFFSET StartNetwork
	mov di,OFFSET HangupLine
	call OpenProtocol
start_ncp_done:
	ret
StartNcp	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartNetwork
;
;		description:	Start Network
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartNetwork	Proc near
	mov ds:ppp_mode,MODE_RUNNING
	mov bx,ds:thread_id
	StopTimer
	mov si,OFFSET connect_list
start_network_wake:
	mov ax,[si]
	or ax,ax
	jz start_network_done
	Wake
	jmp start_network_wake
start_network_done:
	ret
StartNetwork	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitForConnect
;
;		description:	Wait for a connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForConnect	proc near
	push ds
	push ax
	mov ax,ppp_data_sel
	mov ds,ax
;
	OpenPpp
wait_for_connect_loop:
	cli
	cmp ds:ppp_mode,MODE_RUNNING
	je wait_for_connect_done
	push di
	mov di,OFFSET connect_list
	Sleep
	pop di
	jmp wait_for_connect_loop

wait_for_connect_done:
	sti
	ClosePpp
;
	pop ax
	pop ds
	ret
WaitForConnect	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetPppIP
;
;		description:	Get PPP IP address
;
;		RETURNS:		NC		Valid
;						EDX		My Internet IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ppp_ip_name	DB 'Get PPP IP',0

get_ppp_ip	Proc far
	push ds
	push ax
;
	mov ax,ppp_data_sel
	mov ds,ax
	call WaitForConnect
	mov edx,ds:send_ip
;
	pop ax
	pop ds
	retf32
get_ppp_ip	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDns
;
;		description:	Get Internet DNS IP address
;
;		RETURNS:		EAX		Primary DNS IP address
;						EDX		Secondary DNS IP address
;						CX		Number of valid DNS addresses (0, 1 or 2)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ppp_dns_name	DB 'Get PPP DNS',0

get_ppp_dns	Proc far
	push ds
;
	mov ax,ppp_data_sel
	mov ds,ax
	call WaitForConnect
	mov eax,ds:ppp_dns1
	mov edx,ds:ppp_dns2
;
	pop ds
	retf32
get_ppp_dns	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenPpp
;
;		description:	Open PPP connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_ppp_name	DB 'Open PPP',0

open_ppp	Proc far
	push ds
	push ax
	push bx
;
	mov ax,ppp_data_sel
	mov ds,ax
	add ds:usage_count,1
	mov bx,ds:thread_id
	Signal
;
	pop bx
	pop ax
	pop ds
	retf32
open_ppp	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ClosePpp
;
;		description:	Close PPP connection, done at a timeout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_ppp_name	DB 'Close PPP',0

close_ppp	Proc far
	push ds
	push es
	push ax
	push bx
;
	mov ax,ppp_data_sel
	mov ds,ax
	mov es,ax
	sub ds:usage_count,1
	jnz close_ppp_done
;
	push eax
	push edx
	push di
	mov ax,cs
	mov es,ax
	mov di,OFFSET SignalTimeout
	GetSystemTime
	add eax,1193*60000
	adc edx,0
	mov ds:idle_timeout,eax
	mov ds:idle_timeout+4,edx
	mov bx,ds:thread_id
	StopTimer
	StartTimer
	pop di
	pop edx
	pop eax

close_ppp_done:
	pop bx
	pop ax
	pop es
	pop ds
	retf32
close_ppp	Endp

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
	push ax
	push si
;
	mov si,ppp_data_sel
	mov ds,si
poll_loop:
	mov si,ds:rec_tail
	cmp si,ds:rec_head
	stc
	je poll_done
	mov dx,800h
	xor ecx,ecx
	mov cl,[si]
	inc si
	cmp si,OFFSET rec_buf + REC_BUFFER_SIZE
	jne poll_size_wrap1
	sub si,REC_BUFFER_SIZE
poll_size_wrap1:
	mov ch,[si]
	inc si
	cmp si,OFFSET rec_buf + REC_BUFFER_SIZE
	jne poll_size_wrap2
	sub si,REC_BUFFER_SIZE
poll_size_wrap2:
	mov al,[si]
	cmp al,-1
	jne poll_proto_field
	inc si
	sub cx,1
	jz poll_next
	cmp si,OFFSET rec_buf + REC_BUFFER_SIZE
	jne poll_addr_wrap
	sub si,REC_BUFFER_SIZE
poll_addr_wrap:
	mov al,[si]
	cmp al,3
	jne poll_next
	inc si
	sub cx,1
	jz poll_next
	cmp si,OFFSET rec_buf + REC_BUFFER_SIZE
	jne poll_proto_field
	sub si,REC_BUFFER_SIZE

poll_proto_field:
	xor ah,ah
	lodsb
	sub cx,1
	jz poll_next
	cmp si,OFFSET rec_buf + REC_BUFFER_SIZE
	jne poll_proto_wrap1
	sub si,REC_BUFFER_SIZE
poll_proto_wrap1:
	test al,1
	jnz poll_proto_found
	mov ah,al
	lodsb
	sub cx,1
	jz poll_next
	cmp si,OFFSET rec_buf + REC_BUFFER_SIZE
	jne poll_proto_found
	sub si,REC_BUFFER_SIZE
poll_proto_found:
	mov ds:rec_peek,si
	clc
	jmp poll_done

poll_next:
	add si,cx
	cmp si,OFFSET rec_buf + REC_BUFFER_SIZE
	jne poll_next_set
	sub si,REC_BUFFER_SIZE
poll_next_set:
	mov ds:rec_tail,si
	jmp poll_loop

poll_done:
	pop si
	pop ax
	pop ds
	ret
Preview	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Receive
;
;		DESCRIPTION:    Receive data
;
;       PARAMETERS:     ES		data selector
;						ECX		Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Receive	Proc far
	push ds
	push ax
	push cx
	push si
	push di
;
	mov ax,ppp_data_sel
	mov ds,ax
	mov si,ds:rec_peek
	cmp si,OFFSET rec_buf + REC_BUFFER_SIZE
	jne receive_header_wrap
	sub si,REC_BUFFER_SIZE
receive_header_wrap:
	xor di,di
receive_copy_loop:
	movsb
	cmp si,OFFSET rec_buf + REC_BUFFER_SIZE
	jne receive_copy_next
	sub si,REC_BUFFER_SIZE
receive_copy_next:
	loop receive_copy_loop
;
	pop di
	pop si
	pop cx
	pop ax
	pop ds
	ret
Receive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Remove
;
;		DESCRIPTION:    Remove data from buffer
;
;       PARAMETERS:     ES		data selector
;						ECX		Size of data
;						DS:ESI	Source address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Remove	Proc far
	push ds
	push ax
	push si
;
	mov ax,ppp_data_sel
	mov ds,ax
	mov si,ds:rec_peek
	add si,cx
	cmp si,OFFSET rec_buf + REC_BUFFER_SIZE
	jb remove_mark
	sub si,REC_BUFFER_SIZE
remove_mark:
	mov ds:rec_tail,si
;
	pop si
	pop ax
	pop ds
	ret
Remove	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetBuffer
;
;		DESCRIPTION:    Get a buffer
;
;       PARAMETERS:     ECX		size
;
;		RETURNS			ES:EDI	data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBuffer	Proc far
	push eax
	mov eax,ecx
	add eax,2
	AllocateSmallGlobalMem
	mov edi,2
	pop eax
	ret
GetBuffer	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Send
;
;		DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX		size
;						ES		data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Send	Proc far
	push ds
	push es
	push ax
	push cx
	push dx
	push si
	push di
;
	mov ax,ppp_data_sel
	mov ds,ax
	EnterSection ds:access_section
	mov di,ds:send_tail
	mov ax,di
	add ax,cx
	add ax,ds:send_hdlc_len
	add ax,ds:send_proto_len
	add ax,4
	cmp ax,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_set_tail
	sub ax,SEND_BUFFER_SIZE
send_set_tail:
	mov ds:send_tail,ax
	LeaveSection ds:access_section
;
	mov ax,es
	mov ds,ax
	mov ax,ppp_data_sel
	mov es,ax
;
	push di
	push cx
;
	mov si,2
	add di,2
;
	mov ax,es:send_hdlc_len
	or ax,ax
	jz send_hdlc_done
;
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_hdlc_pad1
	sub di,SEND_BUFFER_SIZE
send_hdlc_pad1:
	cmp di,es:send_head
	je send_done_pop
	mov al,0FFh
	stosb
;
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_hdlc_pad2
	sub di,SEND_BUFFER_SIZE
send_hdlc_pad2:
	cmp di,es:send_head
	je send_done_pop
	mov al,3
	stosb
;
send_hdlc_done:
	mov ax,es:send_proto_len
	cmp ax,2
	jne send_proto2
;
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_proto_pad1
	sub di,SEND_BUFFER_SIZE
send_proto_pad1:
	cmp di,es:send_head
	je send_done_pop
	xor al,al
	stosb

send_proto2:
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_proto_pad2
	sub di,SEND_BUFFER_SIZE
send_proto_pad2:
	cmp di,es:send_head
	je send_done_pop
	mov al,21h
	stosb

send_loop:
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_next
	sub di,SEND_BUFFER_SIZE
send_next:
	cmp di,es:send_head
	je send_done_pop
	movsb
	loop send_loop
;
	xor al,al
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_xpad1
	sub di,SEND_BUFFER_SIZE
send_xpad1:
	cmp di,es:send_head
	je send_done_pop
	stosb
;
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_xpad2
	sub di,SEND_BUFFER_SIZE
send_xpad2:
	cmp di,es:send_head
	je send_done_pop
	stosb
	mov bx,di
;
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_xpad3
	sub di,SEND_BUFFER_SIZE
send_xpad3:
	cmp di,es:send_head
	je send_done_pop
	stosb
;
	cmp di,OFFSET send_buf + SEND_BUFFER_SIZE
	jc send_xpad4
	sub di,SEND_BUFFER_SIZE
send_xpad4:
	cmp di,es:send_head
	je send_done_pop
	stosb
;
	pop cx
	add cx,es:send_hdlc_len
	add cx,es:send_proto_len
	add cx,2
;
	pop si
	cli
	mov es:[si],cl
	inc si
	cmp si,OFFSET send_buf + SEND_BUFFER_SIZE
	jne send_size_wrap
	sub si,SEND_BUFFER_SIZE
send_size_wrap:
	mov es:[si],ch
	sti
;
	mov dx,es:base
	inc dx
	mov al,0Fh
	out dx,al
	jmp send_done

send_done_pop:
	pop cx
	pop si

send_done:
	pop di
	pop si
	pop dx
	pop cx
	pop ax
	pop es
	pop ds
	ret
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
	mov si,ppp_data_sel
	mov ds,si
	mov esi,OFFSET send_ip
	ret
GetAddress	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DispatchTable
;
;		DESCRIPTION:    Driver dispatch table
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DispatchTable:
	DW OFFSET Preview,	 	ppp_code_sel
	DW OFFSET Receive,		ppp_code_sel
	DW OFFSET Remove,		ppp_code_sel
	DW OFFSET GetBuffer,	ppp_code_sel
	DW OFFSET Send,			ppp_code_sel
	DW OFFSET GetAddress,	ppp_code_sel

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HangupLine
;
;		DESCRIPTION:    Hangup line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HangupLine	Proc near
	ret	
HangupLine	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ppp_thread
;
;		DESCRIPTION:    thread for handling PPP connection
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ppp_thread_name	DB 'PPP',0

ppp_thread	proc far
	mov ax,ppp_data_sel
	mov ds,ax
	GetThread
	mov ds:thread_id,ax
wait_offline:
	WaitForSignal
	call CheckConnect
	mov dx,ds:base
	add dx,6
	in al,dx
	test al,80h
	jz wait_offline
;
wait_online:
	WaitForSignal
poll_online:
	call CheckConnect
	mov dx,ds:base
	add dx,6
	in al,dx
	test al,80h
	jz wait_offline
;
	mov bx,ds:rec_tail
	cmp bx,ds:rec_head
	je wait_online
	mov cl,[bx]
	inc bx
	cmp bx,OFFSET rec_buf + REC_BUFFER_SIZE
	jne rec_size_wrap1
	sub bx,REC_BUFFER_SIZE
rec_size_wrap1:
	mov ch,[bx]
	inc bx
	cmp bx,OFFSET rec_buf + REC_BUFFER_SIZE
	jne rec_size_wrap2
	sub bx,REC_BUFFER_SIZE
rec_size_wrap2:
	mov al,[bx]
	cmp al,-1
	jne rec_proto_field
	inc bx
	sub cx,1
	jz rec_discard
	cmp bx,OFFSET rec_buf + REC_BUFFER_SIZE
	jne rec_addr_wrap
	sub bx,REC_BUFFER_SIZE
rec_addr_wrap:
	mov al,[bx]
	cmp al,3
	jne rec_discard
	inc bx
	sub cx,1
	jz rec_discard
	cmp bx,OFFSET rec_buf + REC_BUFFER_SIZE
	jne rec_proto_field
	sub bx,REC_BUFFER_SIZE

rec_proto_field:
	xor ah,ah
	mov al,[bx]
	inc bx
	sub cx,1
	jz rec_discard
	cmp bx,OFFSET rec_buf + REC_BUFFER_SIZE
	jne rec_proto_wrap1
	sub bx,REC_BUFFER_SIZE
rec_proto_wrap1:
	test al,1
	jnz rec_proto_found
	mov ah,al
	mov al,[bx]
	inc bx
	sub cx,1
	jz rec_discard
	cmp bx,OFFSET rec_buf + REC_BUFFER_SIZE
	jne rec_proto_found
	sub bx,REC_BUFFER_SIZE

rec_proto_found:
	cmp ax,21h
	je rec_ip_data
	cmp ax,0C021h
	je rec_lcp
	cmp ax,0C023h
	je rec_authent
	cmp ax,8021h
	je rec_ipcp
	jmp rec_discard

rec_ip_data:
	mov al,ds:ppp_mode
	cmp al,MODE_RUNNING
	jne rec_discard
	mov bx,ds:net_handle
	NetReceived
	jmp poll_online

rec_lcp:
	mov ax,ds:lcp_handle
	or ax,ax
	jz rec_discard
	mov fs,ax
	call ProtocolReceived
	jmp poll_online

rec_authent:
	mov ax,ds:authent_handle
	or ax,ax
	jz rec_discard
	mov fs,ax
	call ProtocolReceived
	jmp poll_online

rec_ipcp:
	mov ax,ds:ipcp_handle
	or ax,ax
	jz rec_discard
	mov fs,ax
	call ProtocolReceived
	jmp poll_online
	
rec_discard:
	add bx,cx
	mov ds:rec_tail,bx
	jmp poll_online

ppp_thread_end:
	ret
ppp_thread	Endp

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

init_net	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET DispatchTable
	RegisterPppDriver
	mov ax,ppp_data_sel
	mov ds,ax
	mov ds:net_handle,bx
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET ppp_thread
	mov di,OFFSET ppp_thread_name
	mov ax,4
	mov cx,256
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_net	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:    inits device
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

port_str		DB 'PPP.PORT',0
irq_str			DB 'PPP.IRQ',0
baud_str		DB 'PPP.BAUD',0
dial_str		DB 'PPP.DIAL',0
username_str	DB 'PPP.USERNAME',0
password_str	DB 'PPP.PASSWORD',0

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
	mov bx,ppp_code_sel
	InitDevice
;
	mov eax,SIZE ppp_data
	mov bx,ppp_data_sel
	AllocateFixedSystemMem
	mov ds,bx
	mov es,bx
	mov cx,ax
	xor di,di
	xor al,al
	rep stosb
;
    InitSection ds:access_section	
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET dial_str
	call GetEnvString
	jc init_done
	mov ax,ppp_data_sel
	mov es,ax
	mov di,OFFSET dialnr
	mov al,'a'
	stosb
	mov al,'t'
	stosb
	mov al,'d'
	stosb
ppp_move_dial_loop:
	lodsb
	or al,al
	jz ppp_move_dial_done
	stosb
	jmp ppp_move_dial_loop

ppp_move_dial_done:
	xor al,al
	stosb
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET username_str
	call GetEnvString
	jc init_done
	mov ax,ppp_data_sel
	mov es,ax
	mov di,OFFSET username
ppp_move_user_loop:
	lodsb
	or al,al
	jz ppp_move_user_done
	stosb
	jmp ppp_move_user_loop

ppp_move_user_done:
	stosb
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET password_str
	call GetEnvString
	jc init_done
	mov ax,ppp_data_sel
	mov es,ax
	mov di,OFFSET password
ppp_move_passw_loop:
	lodsb
	or al,al
	jz ppp_move_passw_done
	stosb
	jmp ppp_move_passw_loop

ppp_move_passw_done:
	stosb
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET port_str
	call GetEnvInt
	or eax,eax
	jz init_done
	dec eax
	cmp eax,4
	jnc init_done
	mov bx,ax
	push word ptr cs:[bx].IrqTab
	add bx,bx
;
	mov ax,ppp_data_sel
	mov ds,ax
	mov ax,word ptr cs:[bx].BaseTab
	mov ds:base,ax
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET irq_str
	call GetEnvInt
	pop cx
	or eax,eax
	jz init_irq_ok
	mov cx,ax
	cmp cx,16
	jnc init_done

init_irq_ok:
	mov ax,ppp_data_sel
	mov ds,ax
	mov ds:irq,cl
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET baud_str
	call GetEnvInt
	mov cx,3
	or eax,eax
	jz init_baud_ok
	mov ecx,eax
	xor edx,edx
	mov eax,115200
	div ecx
	mov cx,ax
init_baud_ok:
	mov ax,ppp_data_sel
	mov ds,ax
	mov ds:baud,cx
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET init_net
	HookInitTasking
;
	mov si,OFFSET get_ppp_ip
	mov di,OFFSET get_ppp_ip_name
	xor cl,cl
	mov ax,get_ppp_ip_nr
	RegisterOsGate
;
	mov si,OFFSET get_ppp_dns
	mov di,OFFSET get_ppp_dns_name
	xor dx,dx
	mov ax,get_ppp_dns_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET open_ppp
	mov di,OFFSET open_ppp_name
	xor cl,cl
	mov ax,open_ppp_nr
	RegisterOsGate
;
	mov si,OFFSET close_ppp
	mov di,OFFSET close_ppp_name
	xor cl,cl
	mov ax,close_ppp_nr
	RegisterOsGate

init_done:
	popa
	pop es
	pop ds
	ret
Init	Endp

code	ENDS

	END init
