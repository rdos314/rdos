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
; 8255x.ASM
; Intel 8255 series network driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\acpi\pci.inc
INCLUDE ..\os\core.inc
INCLUDE ..\os\net.inc

RX_ENTRIES   EQU 20h
RX_BUF_SIZE  EQU 800h
RX_RING_SIZE EQU 10000h     ; 20h * 800h
TX_ENTRIES   EQU 80h
TX_BUF_SIZE  EQU 20h
TX_RING_SIZE EQU TX_ENTRIES * TX_BUF_SIZE

; Revision ID

MAC_82557_D100_A  = 0
MAC_82557_D100_B  = 1
MAC_82557_D100_C  = 2
MAC_82558_D101_A4 = 4
MAC_82558_D101_B0 = 5
MAC_82559_D101M   = 8
MAC_82559_D101S   = 9
MAC_82550_D102    = 12
MAC_82550_D102_C  = 13
MAC_82551_E       = 14
MAC_82551_F       = 15
MAC_82551_10      = 16

SCBStatus       = 0
SCBCommand      = 2
SCBPointer      = 4
Port        = 8
EeControl       = 0Eh
MDIControl      = 10h
RxDMASize       = 14h

; EeControl bits

EESK    = 1
EECS    = 2
EEDI    = 4
EEDO    = 8

; The EEPROM commands include the always-set leading bit.

EE_WRITE_CMD = 5
EE_READ_CMD = 6
EE_ERASE_CMD = 7

; SCBCommands

CB_NOP      = 0
CB_IAADDR   = 1
CB_CONFIG   = 2
CB_MULTI    = 3
CB_TX       = 4
CB_UCODE    = 5
CB_DUMP     = 6
CB_TX_SF    = 8

; RU commands 

RU_NOP      = 0
RU_START    = 1
RU_RESUME       = 2
RU_DMA_REDIR    = 3
RU_ABORT    = 4
RU_HDS      = 5
RU_BASE     = 6

; CU commands

CU_NOP      = 00h
CU_START    = 10h
CU_RESUME       = 20h
CU_DUMP_CNT     = 40h
CU_DUMP_STAT    = 50h
CU_BASE     = 60h
CU_DUMP_RESET   = 70h

; int bits

ACK_SW_INT      = 4
ACK_RNR         = 10h
ACK_CU_IDLE     = 20h
ACK_FRAME_RX    = 40h
ACK_CU_CMD      = 80h

; SCBStatus bits

CB_COMPLETE     = 8000h
CB_OK       = 2000h

; Cmd bits

CMD_EL      = 8000h
CMD_S       = 4000h
CMD_I       = 2000h
CMD_NC      = 20h
CMD_H       = 10h
CMD_SF      = 8

; status bits

ST_C        = 8000h
ST_OK       = 2000h

; actual count bits

AC_EOF      = 8000h
AC_F        = 4000h

cnf  STRUC

cnf_byte_count      DB ?
cnf_fifo        DB ?
cnf_adaptive_ifs    DB ?
cnf_3           DB ?
cnf_rx_dma      DB ?
cnf_tx_dma      DB ?
cnf_6           DB ?
cnf_7           DB ?
cnf_8           DB ?
cnf_9           DB ?
cnf_10          DB ?
cnf_11          DB ?
cnf_12          DB ?
cnf_13          DB ?
cnf_14          DB ?
cnf_15          DB ?
cnf_fc_delay_lo     DB ?
cnf_fc_delay_hi     DB ?
cnf_18          DB ?
cnf_19          DB ?
cnf_20          DB ?
cnf_21          DB ?
cnf_22          DB ?

cnf  ENDS

rfd     STRUC

rfd_status      DW ?
rfd_command     DW ?
rfd_link    DD ?
rfd_rbd     DD ?
rfd_actual_size DW ?
rfd_size    DW ?

rfd     ENDS

txd     STRUC

txd_status      DW ?
txd_command     DW ?
txd_link    DD ?
txd_tbd_arr     DD ?
txd_tcb_size    DW ?
txd_threshold   DB ?
txd_tbd_count   DB ?

txd     ENDS

tbd     STRUC

tbd_buf     DD ?
tbd_actual_size DW ?
tbd_el      DW ?
tbd_sel     DW ?

tbd     ENDS

cb  STRUC

cb_status       DW ?
cb_command      DW ?
cb_link     DD ?

cb  ENDS

data    STRUC

MemBase         DD ?
FlashBase       DD ?
IoBase              DW ?
MemSel          DW ?
Handle              DW ?
WaitThread      DW ?
IntStat         DB ?
EeAdrLen        DB ?
RevID           DB ?
TxSection       section_typ <>
EthernetAddress     DB 6 DUP(?)

RxRingPhys      DD ?
RxRingLinear    DD ?
RxRingSize      DD ?
RxRingSel       DW ?
RxRingCurrPtr       DD ?

TxRingPhys      DD ?
TxRingLinear    DD ?
TxRingSize      DD ?
TxRingSel       DW ?
TxRingCurrPtr       DD ?
TxRingAckPtr    DD ?
TxRingStarted       DB ?

data    ENDS

code    SEGMENT byte public 'CODE'

    assume cs:code

.386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupAccess
;
;           DESCRIPTION:    Setup memory or IO access
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupAccess   Proc near
    pusha
;
    mov eax,ds:MemBase
    or eax,eax
    jz saIo

saMem:
    mov ds:IoBase,0
;
    mov eax,1000h
    AllocateBigLinear
;
    mov eax,ds:MemBase
    xor ebx,ebx
    or al,17h
    SetPageEntry
;
    AllocateGdt
    mov ecx,20h
    CreateDataSelector16
;
    mov ds:MemSel,bx
    jmp saDone

saIo:
    mov ds:MemSel,0

saDone:    
    popa    
    ret
SetupAccess   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Reset
;
;           DESCRIPTION:    Reset controller
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Reset   Proc near
    push es
    pusha
;
    mov ax,ds:MemSel
    or ax,ax
    jz rIo

rMem:    
    mov es,ax
    mov di,PORT
    mov eax,2
    mov es:[di],eax
;
    mov ax,20
    WaitMicroSec
;       
    mov eax,0
    mov es:[di],eax
;
    mov ax,20
    WaitMicroSec
    jmp rDone

rIo:    
    mov dx,ds:IoBase
    add dx,Port
;       
    mov eax,2
    out dx,eax
;
    mov ax,20
    WaitMicroSec
;       
    mov eax,0
    out dx,eax
;
    mov ax,20
    WaitMicroSec

rDone:
    popa 
    pop es   
    ret
Reset   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EeDelay
;
;           DESCRIPTION:    Delay for EE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EeDelay Proc near
    push ax
    mov ax,5
    WaitMicroSec
    pop ax
    ret
EeDelay Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetEeSize
;
;           DESCRIPTION:    Determine EE size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetEeSize       Proc near
    push es
    pusha
;
    mov ax,ds:MemSel
    or ax,ax
    jz gesIo

gesMem:    
    mov es,ax
    mov di,EeControl
;
    mov al,EECS OR EESK
    mov es:[di],al
    call EeDelay
;
    mov bx,EE_READ_CMD
    mov cx,3
    mov si,4

gesmCodeLoop:
    mov al,EECS
    test si,bx
    jz gesmCodeWrite
;
    or al,EEDI

gesmCodeWrite:
    mov es:[di],al
    call EeDelay
;
    or al,EESK
    mov es:[di],al
    call EeDelay    
;
    shr si,1
    loop gesmCodeLoop
;
    mov cx,16
    mov ds:EeAdrLen,0
    
gesmAddressLoop:
    mov al,EECS
    mov es:[di],al
    call EeDelay
;     
    or al,EESK
    mov es:[di],al
    call EeDelay
;
    inc ds:EeAdrLen
    mov al,es:[di]
    test al,EEDO
    jz gesiAddressDone
;
    loop gesmAddressLoop 
    stc
    jmp gesDone 

gesmAddressDone:
    mov cx,16

gesmDataLoop:
    mov al,EECS
    mov es:[di],al
    call EeDelay
;
    or al,EESK
    mov es:[di],al
    call EeDelay
;    
    mov al,es:[di]
;
    loop gesmDataLoop
;
    xor al,al
    mov es:[di],al
    call EeDelay
    clc
    jmp gesDone

gesIo:
    mov dx,ds:IoBase
    add dx,EeControl
;
    mov al,EECS OR EESK
    out dx,al
    call EeDelay
;
    mov bx,EE_READ_CMD
    mov cx,3
    mov si,4

gesiCodeLoop:
    mov al,EECS
    test si,bx
    jz gesiCodeWrite
;
    or al,EEDI

gesiCodeWrite:
    out dx,al
    call EeDelay
;
    or al,EESK
    out dx,al
    call EeDelay    
;
    shr si,1
    loop gesiCodeLoop
;
    mov cx,16
    mov ds:EeAdrLen,0
    
gesiAddressLoop:
    mov al,EECS
    out dx,al
    call EeDelay
;     
    or al,EESK
    out dx,al
    call EeDelay
;
    inc ds:EeAdrLen
    in al,dx
    test al,EEDO
    jz gesiAddressDone
;
    loop gesiAddressLoop 
    stc
    jmp gesDone 

gesiAddressDone:
    mov cx,16

gesiDataLoop:
    mov al,EECS
    out dx,al
    call EeDelay
;
    or al,EESK
    out dx,al
    call EeDelay
;    
    in al,dx
;
    loop gesiDataLoop
;
    xor al,al
    out dx,al
    call EeDelay
    clc

gesDone:       
    popa
    pop es
    ret
GetEeSize       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadEe
;
;           DESCRIPTION:    Read from EE
;
;       PARAMETERS:     BX          Location
;
;           RETURNS:        AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadEe  Proc near
    push cx
    push dx
    push si
;
    mov dx,ds:IoBase
    add dx,EeControl
;
    mov al,EECS OR EESK
    out dx,al
    call EeDelay
;
    push bx
    mov bx,EE_READ_CMD
    mov cx,3
    mov si,4

reCodeLoop:
    mov al,EECS
    test si,bx
    jz reCodeWrite
;
    or al,EEDI

reCodeWrite:
    out dx,al
    call EeDelay
;
    or al,EESK
    out dx,al
    call EeDelay    
;
    shr si,1
    loop reCodeLoop
;
    pop bx
    movzx cx,ds:EeAdrLen
    mov si,1
    shl si,cl
    shr si,1
    
reAddressLoop:
    mov al,EECS
    test si,bx
    jz reAddressWrite
;
    or al,EEDI

reAddressWrite:
    out dx,al
    call EeDelay
;     
    or al,EESK
    out dx,al
    call EeDelay
;
    shr si,1
    loop reAddressLoop 
;
    xor si,si
    mov cx,16

reDataLoop:
    shl si,1
    mov al,EECS
    out dx,al
    call EeDelay
;
    or al,EESK
    out dx,al
    call EeDelay
;    
    in al,dx
    test al,EEDO
    jz reDataNext
;
    or si,1

reDataNext:
;
    loop reDataLoop
;
    xor al,al
    out dx,al
    call EeDelay
;
    mov ax,si
;    
    pop si
    pop dx
    pop cx
    ret
ReadEe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadEthernetAddress
;
;           DESCRIPTION:    Read the ethernet address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadEthernetAddress     Proc near
    xor bx,bx
    mov si,OFFSET EthernetAddress

reaReadLoop:
    call ReadEe
    mov ds:[si],ax
    add si,2
    inc bx
    cmp bx,3
    jne reaReadLoop
;
    ret
ReadEthernetAddress     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForAccept
;
;           DESCRIPTION:    Wait for RU / CU command acceptance
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForAccept   Proc near
    mov dx,ds:IoBase
    add dx,SCBCommand

wfaLoop:
    in al,dx
    or al,al
    jz wfaDone
;
    mov ax,1
    WaitMilliSec
    jmp wfaLoop    

wfaDone: 
    ret
WaitForAccept   Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitCmd
;
;           DESCRIPTION:    Init command ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitCmd Proc near
    mov ecx,TX_RING_SIZE SHR 12
    AllocateMultiplePhysical32
    jc icDone
;
    mov ds:TxRingPhys,eax
    mov eax,TX_RING_SIZE
    AllocateBigLinear
    mov ds:TxRingLinear,edx
    mov ds:TxRingSize,eax
;
    mov eax,ds:TxRingPhys
    or al,13h
    mov ecx,TX_RING_SIZE SHR 12

ic_ring_loop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop ic_ring_loop
;
    mov ecx,ds:TxRingSize
    mov edx,ds:TxRingLinear
    AllocateGdt
    CreateDataSelector16
    mov ds:TxRingSel,bx
;
    mov eax,ds:TxRingPhys
    mov dx,ds:IoBase
    add dx,SCBPointer     
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,SCBCommand
    mov al,CU_BASE
    out dx,al
    call WaitForAccept    
    clc

icDone:
    ret
InitCmd Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Config
;
;           DESCRIPTION:    Configure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Config  Proc near
    mov es,ds:TxRingSel
    mov es:cb_status,0
    mov es:cb_command,CB_CONFIG OR CMD_S
    mov es:cb_link,-1
;
    mov cx,SIZE cnf
    mov di,SIZE CB
    xor al,al
    rep stosb
;
    mov di,SIZE CB
    mov es:[di].cnf_byte_count,SIZE cnf
    mov es:[di].cnf_fifo,8
    mov es:[di].cnf_6,32h
    mov es:[di].cnf_7,7
    mov es:[di].cnf_8,1
    mov es:[di].cnf_10,2Eh
    mov es:[di].cnf_12,61h
    mov es:[di].cnf_14,0F2h
    mov es:[di].cnf_15,48h
    mov es:[di].cnf_fc_delay_hi,40h
    mov es:[di].cnf_18,0F2h
    mov es:[di].cnf_19,80h
    mov es:[di].cnf_20,3Fh
    mov es:[di].cnf_21,5
;
    cmp ds:RevID,MAC_82558_D101_A4
    jc config_do
;
    or es:[di].cnf_3,1
    or es:[di].cnf_19,4

config_do:    
    ClearSignal
    xor eax,eax
    mov dx,ds:IoBase
    add dx,SCBPointer     
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,SCBCommand
    mov al,CU_START
    out dx,al
    call WaitForAccept    
    WaitForSignal
    clc
;
    ret
Config  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupEthernetAddress
;
;           DESCRIPTION:    Setup ethernet address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupEthernetAddress    Proc near
    mov es,ds:TxRingSel
    mov es:cb_status,0
    mov es:cb_command,CB_IAADDR OR CMD_S
    mov es:cb_link,-1
;
    mov cx,3
    mov si,OFFSET EthernetAddress
    mov di,SIZE CB
    rep movsw
;    
    ClearSignal
    xor eax,eax
    mov dx,ds:IoBase
    add dx,SCBPointer     
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,SCBCommand
    mov al,CU_START
    out dx,al
    call WaitForAccept    
    WaitForSignal
    clc
;
    ret
SetupEthernetAddress    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitRfd
;
;           DESCRIPTION:    Init RFD block
;
;       PARAMETERS:     ES:EDX      RFD address
;               EAX     Next RFD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitRfd Proc near
    push eax
    mov es:[edx].rfd_link,eax
    mov es:[edx].rfd_command,0
    mov es:[edx].rfd_status,0
    mov es:[edx].rfd_rbd,0
    mov ax,RX_BUF_SIZE - SIZE RFD
    mov es:[edx].rfd_size,ax
    mov es:[edx].rfd_actual_size,0
    pop eax
    ret
InitRfd Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitRx
;
;           DESCRIPTION:    Init receiver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitRx  Proc near
    mov ecx,RX_RING_SIZE SHR 12
    AllocateMultiplePhysical32
    jc irDone
;
    mov ds:RxRingPhys,eax
    mov eax,RX_RING_SIZE
    AllocateBigLinear
    mov ds:RxRingLinear,edx
    mov ds:RxRingSize,eax
;
    mov eax,ds:RxRingPhys
    or al,13h
    mov ecx,RX_RING_SIZE SHR 12

ir_rxring_loop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop ir_rxring_loop
;
    mov ecx,ds:RxRingSize
    mov edx,ds:RxRingLinear
    AllocateGdt
    CreateDataSelector16
    mov ds:RxRingSel,bx
    mov ds:RxRingCurrPtr,0
;
    mov es,bx   
    xor edx,edx
    mov eax,RX_BUF_SIZE

irInitRfd:
    call InitRfd
    mov edx,eax
    add eax,RX_BUF_SIZE
    cmp eax,RX_RING_SIZE
    jne irInitRfd
;
    xor eax,eax
    call InitRfd   
    mov es:[edx].rfd_command,CMD_S
;
    mov eax,ds:RxRingPhys
    mov dx,ds:IoBase
    add dx,SCBPointer     
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,SCBCommand
    mov al,RU_BASE
    out dx,al
    call WaitForAccept    
;
    mov dx,ds:IoBase
    add dx,SCBPointer
    xor eax,eax
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,SCBCommand
    mov al,RU_START
    out dx,al     
    call WaitForAccept    
    clc

irDone:
    ret
InitRx  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitTxd
;
;           DESCRIPTION:    Init TXD block
;
;       PARAMETERS:     ES:EDX      TXD address
;               EAX     Next TXD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTxd Proc near
    push eax
    mov es:[edx].txd_link,eax
    mov es:[edx].txd_command,CB_TX OR CMD_S OR CMD_SF
    mov es:[edx].txd_status,0
    mov eax,edx
    add eax,SIZE txd
    mov es:[edx].txd_tbd_arr,eax
    mov es:[edx].txd_tcb_size,0
    mov es:[edx].txd_threshold,0E0h
    mov es:[edx].txd_tbd_count,1
;
    mov es:[eax].tbd_buf,0
    mov es:[eax].tbd_actual_size,0
    mov es:[eax].tbd_el,0    
    pop eax
    ret
InitTxd Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitTx
;
;           DESCRIPTION:    Init transmit ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTx  Proc near
    mov cx,TX_ENTRIES - 1
    mov es,ds:TxRingSel
    xor edx,edx
    mov eax,TX_BUF_SIZE

itInitTxd:
    call InitTxd
    mov edx,eax
    add eax,TX_BUF_SIZE
    loop itInitTxd
;
    xor eax,eax
    call InitTxd
;    
    mov ds:TxRingCurrPtr,0
    mov ds:TxRingAckPtr,0
    ret
InitTx  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PurgeTx
;
;           DESCRIPTION:    Remove sent packets
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PurgeTx Proc near
    push es
    push fs
    push edx
;    
    EnterSection ds:TxSection
;
    mov fs,ds:TxRingSel

ptLoop:
    mov edx,ds:TxRingAckPtr
    cmp edx,ds:TxRingCurrPtr
    je ptLeave
;
    test fs:[edx].txd_status, ST_C
    jz ptLeave
;
    mov fs:[edx].txd_status,0
    or fs:[edx].txd_command, CMD_S
;    
    push edx
    mov edx,fs:[edx].txd_tbd_arr
    mov es,fs:[edx].tbd_sel
    FreeMem
    mov fs:[edx].tbd_sel,0
    mov fs:[edx].tbd_buf,0
    mov fs:[edx].tbd_actual_size,0
    pop edx
    mov edx,fs:[edx].txd_link
    mov ds:TxRingAckPtr,edx
    jmp ptLoop

ptLeave:
    LeaveSection ds:TxSection
;
    pop edx
    pop fs
    pop es    
    ret
PurgeTx Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NetInt
;
;           DESCRIPTION:    Network card interrupt
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NetInt  Proc far
niLoop:
    mov dx,ds:IoBase
    add dx,1
    in al,dx
    or ds:IntStat,al
    out dx,al
;
    test al,ACK_FRAME_RX
    jz niNotRx
;
    mov bx,ds:Handle
    or bx,bx
    jz niNotRx
;
    push ax
    NetReceived
    pop ax
    and al,NOT ACK_FRAME_RX

niNotRx:
    or al,al
    jz niDone
;    
    mov bx,ds:WaitThread
    or bx,bx
    jz niLoop
;    
    Signal
    jmp niLoop    

niDone:    
    retf32
NetInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Preview
;
;           DESCRIPTION:    Return size of block or no more data
;
;           RETURNS:        NC          Data available
;                           ECX         Size of data (0)
;                           DX          Packet type
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Preview1:
    push ds
    push fs
    push ebx
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp preview_common
    
Preview2:
    push ds
    push fs
    push ebx
;
    mov ax,ether_data2_sel
    mov ds,ax

preview_common:
    mov fs,ds:RxRingSel

preview_loop:
    mov ebx,ds:RxRingCurrPtr
    mov ax,fs:[ebx].rfd_status
    test ax,ST_C
    stc
    jz preview_done
;
    test ax,ST_OK
    jnz preview_ok
;
    mov fs:[ebx].rfd_status,0
    or fs:[ebx].rfd_command,CMD_S
    mov fs:[ebx].rfd_actual_size,0
    push ebx
    sub ebx,RX_BUF_SIZE
    jnc preview_unsusp
;
    mov ebx,RX_RING_SIZE - RX_BUF_SIZE

preview_unsusp:
    mov fs:[ebx].rfd_command,0
    pop ebx
;
    add ebx,RX_BUF_SIZE
    cmp ebx,RX_RING_SIZE
    jnz preview_save_next
;
    xor ebx,ebx

preview_save_next:    
    mov ds:RxRingCurrPtr,ebx
    jmp preview_loop
    
preview_ok:    
    add ebx,SIZE RFD
    mov dx,fs:[ebx+12]      
    xchg dl,dh
    xor ecx,ecx
    clc

preview_done:
    pop ebx
    pop fs
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Receive
;
;           DESCRIPTION:    Receive data
;
;       RETURNS:        ES:EDI          data buffer
;                           ECX             size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Receive1:
    push ds
    push fs
    push bx
    push edx
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp receive_do

Receive2:
    push ds
    push fs
    push bx
    push edx
;
    mov ax,ether_data2_sel
    mov ds,ax
    
receive_do:
    mov fs,ds:RxRingSel
    mov edx,ds:RxRingCurrPtr
    mov cx,fs:[edx].rfd_actual_size
    and ecx,3FFFh
    AllocateGdt
    add edx,SIZE RFD
    add edx,ds:RxRingLinear
    CreateAliasSelector16
    mov es,bx
    NotifyEthernetPacket
    mov edi,14
    sub ecx,14
;
    pop edx
    pop bx
    pop fs
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Remove
;
;           DESCRIPTION:    Remove data from buffer ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Remove1:
    push ds
    push ebx
;
    mov bx,ether_data_sel
    mov ds,bx
    jmp remove_do

Remove2:
    push ds
    push ebx
;
    mov bx,ether_data2_sel
    mov ds,bx

remove_do:
    mov ebx,ds:RxRingCurrPtr
    mov ds,ds:RxRingSel
    and ds:[ebx].rfd_status, NOT ST_OK
;
    pop ebx
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBuffer
;
;           DESCRIPTION:    Get buffer
;
;       PARAMETERS:     ECX         size
;
;           RETURNS:        ES:EDI  data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBuffer       Proc far
    push eax
    mov eax,14
    add eax,ecx
    cmp eax,64
    jae gbSizeOk

    mov eax,64

gbSizeOk:       
    add eax,4
    AllocateGlobalMem
    mov edi,14
    pop eax
    clc
    retf32
GetBuffer       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Send
;
;           DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX         size
;                           DX          packet type
;                           DS:ESI  dest address
;                           ES:EDI  data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Send1:
    push eax
    push bx
    push ecx
    push dx
    push esi
    push edi
;
    xor di,di
    mov ax,ds:[esi]
    stosw
    mov ax,[esi+2]
    stosw
    mov ax,[esi+4]
    stosw
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp send_do

Send2:
    push eax
    push bx
    push ecx
    push dx
    push esi
    push edi
;
    xor di,di
    mov ax,ds:[esi]
    stosw
    mov ax,[esi+2]
    stosw
    mov ax,[esi+4]
    stosw
;
    mov ax,ether_data2_sel
    mov ds,ax

send_do:    
    call PurgeTx
;    
    mov ax,word ptr ds:EthernetAddress
    stosw
    mov ax,word ptr ds:EthernetAddress+2
    stosw
    mov ax,word ptr ds:EthernetAddress+4
    stosw
;
    mov ax,dx
    xchg al,ah
    stosw
    add ecx,14
;
    xor edi,edi
    NotifyEthernetPacket
    mov bx,es
    push ecx
    GetSelectorBaseSize
    pop ecx
    GetPageEntry
    and ax,0F000h
    and ecx,0FFFh
    and dx,0FFFh
    or ax,dx
;
    EnterSection ds:TxSection

send_retry_buf:
    mov edx,ds:TxRingCurrPtr
    mov es,ds:TxRingSel
    mov esi,es:[edx].txd_tbd_arr
    mov edi,es:[esi].tbd_buf
    or edi,edi
    jz send_take_buf
;
    push ax
    mov ax,100
    WaitMilliSec
;
    mov dx,ds:IoBase
    add dx,SCBStatus
    in al,dx
    test al,80h
    pop ax
    jnz send_retry_buf
    jmp send_stopped

send_take_buf:
    or es:[edx].txd_command, CMD_S
    mov es:[esi].tbd_buf,eax
    mov es:[esi].tbd_actual_size,cx
    mov es:[esi].tbd_sel,bx
;
    sub edx,TX_BUF_SIZE
    jnc send_prev_buf
;
    mov edx,TX_RING_SIZE - TX_BUF_SIZE

send_prev_buf:
    and es:[edx].txd_command, NOT CMD_S
;
    mov edx,ds:TxRingCurrPtr
    add edx,TX_BUF_SIZE
    cmp edx,TX_RING_SIZE
    jne send_next_buf
;
    xor edx,edx

send_next_buf:
    mov ds:TxRingCurrPtr,edx   
;
    mov dx,ds:IoBase
    add dx,SCBStatus
    in al,dx
    test al,80h
    jz send_running

send_stopped:
    int 3
    call InitTx
    jmp send_start

send_running:
    mov al,ds:TxRingStarted
    or al,al
    jnz send_resume

send_start:
    inc ds:TxRingStarted
    xor eax,eax
    mov dx,ds:IoBase
    add dx,SCBPointer     
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,SCBCommand
    mov al,CU_START
    out dx,al
    call WaitForAccept    

send_resume:    
    mov dx,ds:IoBase
    add dx,SCBCommand
    mov al,CU_RESUME
    out dx,al
    call WaitForAccept    

send_leave:    
    xor ax,ax
    mov es,ax
    LeaveSection ds:TxSection
    mov ds,ax
;
    pop edi
    pop esi
    pop dx
    pop ecx
    pop bx
    pop eax
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetAddress
;
;           DESCRIPTION:    Get adapter address
;
;           RETURNS:        DS:ESI  address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAddress1  Proc far
    mov si,ether_data_sel
    mov ds,si
    mov esi,OFFSET EthernetAddress  
    retf32
GetAddress1     Endp

GetAddress2  Proc far
    mov si,ether_data2_sel
    mov ds,si
    mov esi,OFFSET EthernetAddress  
    retf32
GetAddress2     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPktAddress
;
;           DESCRIPTION:    Get packet addresses
;
;           PARAMETERS:         ES          Data buffer selector
;
;           RETURNS:        ES:ESI  Source address
;                           ES:EDI  Dest address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPktAddress   Proc far
    mov esi,6
    xor edi,edi
    retf32
GetPktAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       GetLinkState
;
;           DESCRIPTION:    Get link state
;
;           RETURNS:    NC  Link up
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetLinkState1  Proc far
    push ds
    push ax
;
    mov ax,ether_data_sel
    mov ds,ax
    clc
;
    pop ax
    pop ds    
    retf32
GetLinkState1     Endp

GetLinkState2  Proc far
    push ds
    push ax
;
    mov ax,ether_data2_sel
    mov ds,ax
    clc
;
    pop ax
    pop ds    
    retf32
GetLinkState2     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DispatchTable
;
;           DESCRIPTION:    Driver dispatch table
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DispTable1:
    DD OFFSET Preview1,             SEG code
    DD OFFSET Receive1,             SEG code
    DD OFFSET Remove1,              SEG code
    DD OFFSET GetBuffer,        SEG code
    DD OFFSET Send1,            SEG code
    DD OFFSET GetAddress1,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET GetLinkState1,    SEG code

DispTable2:
    DD OFFSET Preview2,             SEG code
    DD OFFSET Receive2,             SEG code
    DD OFFSET Remove2,              SEG code
    DD OFFSET GetBuffer,        SEG code
    DD OFFSET Send2,            SEG code
    DD OFFSET GetAddress2,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET GetLinkState2,    SEG code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciAdapter
;
;           DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     
;
;           RETURNS:        NC          Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DevName1     DB '8255x-1',0
DevName2     DB '8255x-2',0

PciVendorTab:
pci00   DW 8086h, 1029h
pci01   DW 8086h, 1030h
pci02   DW 8086h, 103Ah
pci03   DW 8086h, 1059h
pci04   DW 8086h, 1209h
pci05   DW 8086h, 1229h
pci06   DW 8086h, 100Eh
pci07   DW 0,     0

InitPciAdapter   Proc near
    mov ax,cs
    mov es,ax
    mov ax,ether_data_sel
    mov ds,ax
    mov si,OFFSET PciVendorTab
    xor bx,bx
    mov edi,OFFSET DevName1
    mov ebp,OFFSET DispTable1

init_pci_loop:
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz init_pci_done
;
    FindPciDeviceHandle
    jnc init_pci_found
;
    xor bx,bx
    add si,4
    jmp init_pci_loop

init_pci_found:
    LockPciHandle
    jc init_pci_loop
;
    mov cl,PCI_revisionID
    ReadPciConfigByte
    mov ds:RevID,al
;       
    xor al,al
    GetPciBarPhys
    jc init_io_dev
;
    mov ds:MemBase,eax

init_io_dev:
    mov al,1
    GetPciBarIo
    jc init_flash_dev
;       
    mov ds:IoBase,dx

init_flash_dev:
    mov al,2
    GetPciBarPhys
    jc init_setup
       
    mov ds:FlashBase,eax

init_setup:
    int 3
    call SetupAccess
    call Reset
;    
    call GetEeSize
    jc init_pci_done
;    
    GetThread
    mov ds:WaitThread,ax
    mov ds:IntStat,0
;    
;    GetPciIrqNr
;    mov ah,14h
;    mov bx,cs
;    mov es,bx
;    mov di,OFFSET NetInt    
;    RequestIrqHandler
;
    push ebx
;
    call ReadEthernetAddress
    call InitCmd
    call Config
    call SetupEthernetAddress
    call InitRx
    mov ds:WaitThread,0
    call InitTx
;
    push ds
    push esi
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,ebp
    mov al,1
    mov dx,0
    mov ecx,1600
    RegisterNetDriver
;
    pop esi
    pop ds
    mov ds:Handle,bx
;       
    mov al,ds:IntStat
    test al,ACK_FRAME_RX
    jz init_pci_ok
;
    mov bx,ds:Handle
    NetReceived

init_pci_ok:
    pop ebx

init_pci_next:
    mov ax,ds
    cmp ax,ether_data_sel
    jne init_pci_done
;
    mov ax,ether_data2_sel
    mov ds,ax
    mov edi,OFFSET DevName2
    mov ebp,OFFSET DispTable2
    jmp init_pci_loop

init_pci_done:
    ret
InitPciAdapter   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMacAddress
;
;       DESCRIPTION:    Get Mac address
;
;       PARAMETERS:     ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_mac_address_name    DB 'Get Mac Address', 0

get_mac_address Proc near
    push ds
    push esi
    push ecx
;    
    mov si,ether_data_sel
    mov ds,si
    mov esi,OFFSET EthernetAddress  
    mov ecx,3
    rep movs word ptr es:[edi],ds:[esi]
    clc
;
    pop ecx
    pop esi
    pop ds
    ret
get_mac_address Endp    

get_mac_address32   Proc far
    push edi
    call get_mac_address
    pop edi
    retf32
get_mac_address32   Endp

get_mac_address16   Proc far
    push edi
    movzx edi,di
    call get_mac_address
    pop edi
    retf32
get_mac_address16   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_net
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_net    Proc far
    push ds
    push es
    pusha
;
    call InitPciAdapter
;
    popa
    pop es
    pop ds
    retf32
init_net    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ebx,OFFSET get_mac_address16
    mov esi,OFFSET get_mac_address32
    mov edi,OFFSET get_mac_address_name
    mov dx,virt_es_in
    mov ax,get_mac_address_nr
    RegisterUserGate
;
    mov eax,SIZE data
    mov bx,ether_data_sel
    AllocateFixedSystemMem
    mov ds,bx
    mov es,bx
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
    InitSection ds:TxSection
;
    mov eax,SIZE data
    mov bx,ether_data2_sel
    AllocateFixedSystemMem
    mov ds,bx
    mov es,bx
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
    InitSection ds:TxSection
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_net
    HookInitPci
    clc
    ret
Init    Endp

code ENDS

    END init
