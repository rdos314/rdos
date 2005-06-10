;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; operation model
;
; baudrate = 250kb
; bittime = 4us (20 instructions)
; time frame len = 288us (72 bits)
; initialize interval = 1024 * 288us = 0.295s (1024 time frames)
; maximum of 32 nodes on network (PIC limit)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NODE_NR     .EQU 1

BIT_TIME    .EQU 20
FRAME_US_L  .EQU 32
FRAME_US_M  .EQU 1
FRAME_BITS  .EQU 72

#DEFINE PAGE0   BCF $03,5
#DEFINE PAGE1   BSF $03,5

OPT:    .EQU 1
TMR0:   .EQU 1
PCL:    .EQU 2
STATUS: .EQU 3
PORTA:  .EQU 5
PORTB:  .EQU 6
TRISA:  .EQU 5
TRISB:  .EQU 6

W:      .EQU 0          ;Working
F:      .EQU 1          ;File
C:      .EQU 0          ;Carry
Z:      .EQU 2          ;Zero

EEDATA: .EQU $08        ;eeprom data value register
EECON1: .EQU $08        ;eeprom write register 1
EEADR:  .EQU $09        ;eeprom data address register
EECON2: .EQU $09        ;eeprom write register 2

WR:     .EQU 1          ;eeprom write initiate flag
WREN:   .EQU 2          ;eeprom write enable flag
RD:     .EQU 0          ;eeprom read enable flag

INTCON: .EQU $0B

VAL:        .EQU $0F
COUNT:      .EQU $10
DELCNT:     .EQU $11
BUF:        .EQU $12
BYTENO:     .EQU $13
NODECNT:    .EQU $14
MASTER:     .EQU $15

NODEARR:    .EQU $30

; RA0 = gen int (0)
; RA1 = packet in (1)
; RA2 = ack packet (1)
; RA3 = clear shift (0)
; RA4 = packet int (1)

; RB0 = clk in
; RB1 = data in/out (1/0)
; RB2 = data out control 0
; RB3 = data out control 1
; RB4 = data in
; RB5 = SRCK
; RB6 = RCK
; RB7 = load (0)


    .ORG 4
    .ORG 5

RESET:		
    PAGE1
    movlw $12
	movwf TRISA
;
	movlw $11
	movwf TRISB
;
    movlw $D7
    movwf OPT
;			
    PAGE0
    clrf PORTA
;
    movlw $8E
    movwf PORTB			    
;
    movlw $0D
    movwf PORTA

Wait:

WaitReq:   
    btfss PORTA,4
    goto WaitReq

AckLoop:
    bcf PORTA,2
    bsf PORTA,2
    btfsc PORTA,4
    goto AckLoop
;    
    call StartSend
    call InputByte
    movwf BUF
;
    call StartReceive
    movf BUF,W
    call OutputByte
;    
    bcf PORTA,0
    bsf PORTA,0    
;    
    goto Wait

;;;;;;;;;;
; GetInitByte
;;;;;;;;;;

GetInitByte:
			movf BYTENO,W
			incf BYTENO,F
			addwf PCL,F
			retlw $9B
			retlw $7C
			retlw NODE_NR
			retlw $AB
			retlw FRAME_US_M
			retlw FRAME_US_L

;;;;;;;;;;
; GetReqByte
;;;;;;;;;;

GetReqByte:
			movf BYTENO,W
			incf BYTENO,F
			addwf PCL,F
			retlw $9B
			retlw $7D
			retlw NODE_NR

;;;;;;;;;;
; GetReplyByte
;;;;;;;;;;

GetReplyByte:
			movf BYTENO,W
			incf BYTENO,F
			addwf PCL,F
			retlw $9B
			retlw $7E
			retlw NODE_NR

;;;;;;;;;;
; Delay
;;;;;;;;;;

Delay:
    movlw 255
    movwf DELCNT

DelayYLoop:
    movlw $FF
    movwf TMR0

DelayLoop:
    movf TMR0,W
    btfss STATUS,Z
    goto DelayLoop
;
    decf DELCNT,F
    btfss STATUS,Z
    goto DelayYLoop

    return

;;;;;;;;;;
; StartReceive
;;;;;;;;;;

StartReceive:
    PAGE1
	movlw $01
	movwf TRISB
;
	PAGE0
	movlw $8E
	movwf PORTB
;
    bcf PORTA,3
    bsf PORTA,3
    return

;;;;;;;;;;
; StartSend
;;;;;;;;;;

StartSend:
    PAGE1
	movlw $11
	movwf TRISB
;
	PAGE0
	movlw $8C
	movwf PORTB
;
    bcf PORTA,3
    bsf PORTA,3
    return

;;;;;;;;;;
; StartLocal
;;;;;;;;;;

StartLocal:
    PAGE1
	movlw $01
	movwf TRISB
;
	PAGE0
	movlw $84
	movwf PORTB
;
    bcf PORTA,3
    bsf PORTA,3
    return

;;;;;;;;;;
; OutputBit
;;;;;;;;;;

OutputBit:
    btfss VAL,0
    goto BitClear

BitSet:
    bsf PORTB,4
    goto BitDone

BitClear:
    bcf PORTB,4
    goto BitDone

BitDone:
    bsf PORTB,5
    bcf PORTB,5
    rrf VAL,F
    return

;;;;;;;;;;
; OutputByte
; W = byte
;;;;;;;;;;

OutputByte:
    movwf VAL
;    
    movlw 8
    movwf COUNT

OutByteLoop:
    call OutputBit
    decf COUNT,F
    btfss STATUS,Z
    goto OutByteLoop
;
    bsf PORTB,6
    bcf PORTB,6
;
    bcf PORTB,7
    bsf PORTB,7    
    return

;;;;;;;;;;
; InputBit
;;;;;;;;;;

InputBit:
    rrf VAL,F            
    bcf VAL,7
    btfsc PORTB,0
    bsf VAL,7
    bsf PORTB,5
    bcf PORTB,5
    return

;;;;;;;;;;
; InputByte
; W = byte
;;;;;;;;;;

InputByte:
    bcf PORTB,7
;    
    movlw 8
    movwf COUNT
    clrf VAL    
;
    bsf PORTB,7    
;    
    bsf PORTB,6
    bcf PORTB,6

InByteLoop:
    call InputBit
    decf COUNT,F
    btfss STATUS,Z
    goto InByteLoop
;
    movf VAL,W    
    return

;;;;;;;;;;
; LocalByte
;;;;;;;;;;

LocalBit:
    bcf PORTB,4
    btfsc VAL,0
    bsf PORTB,4
    bsf PORTB,5
    bcf PORTB,5
    rrf VAL,F
;
    andlw 1
    movwf BITS
    clrf TEMP
	bcf STATUS,C
	rlf CRC,F
	rlf TEMP,W
	xorwf BITS,W
	btfsc STATUS,Z
	return
;
	movlw $26
	xorwf CRC,F
	return

        .END

