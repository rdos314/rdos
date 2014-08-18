
#DEFINE PAGE0   BCF 0x3,5
#DEFINE PAGE1   BSF 0x3,5

#DEFINE INDF 0
#DEFINE TMR0 1
#DEFINE OPTION 1
#DEFINE PCL 2
#DEFINE STATUS  3
#DEFINE FSR 4
#DEFINE PORTA 5
#DEFINE PORTB 6
#DEFINE TRISA 5
#DEFINE TRISB 6

#DEFINE W 0          ;Working
#DEFINE F 1          ;File
#DEFINE C 0          ;Carry
#DEFINE Z 2          ;Zero


#DEFINE INTCON 0xB
#DEFINE PIR1 0xC
#DEFINE TMR1L 0xE
#DEFINE TMR1H 0xF
#DEFINE T1CON 0x10

#DEFINE RCSTA 0x18
#DEFINE TXSTA 0x18  ; page1
#DEFINE TXREG 0x19
#DEFINE RCREG 0x1A
#DEFINE SPBRG 0x19  ; page1

#DEFINE CMCON 0x1F

#DEFINE PARITY_ENABLED_BIT  0
#DEFINE PARITY_EVEN_BIT     1
#DEFINE DATA_7_BIT          2
#DEFINE USE_9_BIT           3
#DEFINE OPEN_BIT            4
#DEFINE TX_BUSY_BIT         5

#DEFINE DataIn  0x20
#DEFINE BitCnt  0x21
#DEFINE Flags   0x22
#DEFINE Temp    0x24

#DEFINE RxTail  0x26
#DEFINE RxHead  0x27
#DEFINE RxCount 0x28

#DEFINE DbBits  0x29

#DEFINE RxBuf  0x30
#DEFINE RxBufSize 0x40

    org 0
    goto Start

    org 5

Start:
    clrf PORTA
;
    movlw 7
    movwf CMCON
;    
	PAGE1
	movlw 0xE7
	movwf TRISA
;
    PAGE0
    movlw 0x84
;   movlw 0x4
    movwf PORTB
;
    PAGE1
    movlw 0x7B
    movwf TRISB    

	PAGE0
    clrf Flags

HandleLoop:
    call HandleSpi
    goto HandleLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  GetBit
;
;  Returns: C  = 0
;           W    0 or 1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBit:
    bsf STATUS,C

GetBitL:
    btfss PORTA,0
    return    ; return if CTRL = 0
;
    btfsc PORTB,0
    goto GetBitH
;
    call Poll        
    goto GetBitL

GetBitH:
    btfss PORTA,0
    return    ; return if CTRL = 0
;
    bcf STATUS,C
;
    movlw 0
    btfss PORTA,1
    goto GetBitWait
;
    movlw 1

GetBitWait:
    call Poll
    btfss PORTA,0
    return    ; return if CTRL = 0
;
    btfsc PORTB,0
    goto GetBitWait
;
    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  GetByte
;
;  Returns: C  = 0
;           W    data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetByte:
    movlw 8
    movwf BitCnt
    clrf DataIn

GetByteLoop:
    call GetBit
    btfsc STATUS,C
    return
;
    movwf STATUS
    rrf DataIn,F
;
    decf BitCnt,F
    btfss STATUS,Z
    goto GetByteLoop
;
    movf DataIn,W
    bcf STATUS,C
    return   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  WriteBit0/1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteBit0:
    bcf PORTA,3
    goto WriteBitL

WriteBit1:
    bsf PORTA,3

WriteBitL:
    btfss PORTA,0
    return    ; return if CTRL = 0
;
    btfsc PORTB,0
    goto WriteBitH
;
    call Poll        
    goto WriteBitL

WriteBitH:
    btfss PORTA,0
    return    ; return if CTRL = 0

WriteBitWait:
    call Poll
    btfss PORTA,0
    return    ; return if CTRL = 0
;
    btfsc PORTB,0
    goto WriteBitWait
;
    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  HandleCmd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleCmd:
    call GetBit
    btfsc STATUS,C
    return
;
    movwf STATUS
    btfsc STATUS,C
    return
;
    call GetBit
    btfsc STATUS,C
    return
;
    movwf STATUS
    btfss STATUS,C
    goto HandleStatus
;    
    movlw 6
    movwf BitCnt
    clrf DataIn

GetCmdLoop:
    call GetBit
    btfsc STATUS,C
    return
;
    movwf STATUS
    rrf DataIn,F
;
    decf BitCnt,F
    btfss STATUS,Z
    goto GetCmdLoop
;
    bsf STATUS,C
    rrf DataIn,F
    bcf STATUS,C
    rrf DataIn,F
    movf DataIn,W    
;
	movlw 'b'
	xorwf DataIn,W
	btfss STATUS,Z
	goto NotBaud
;
    call GetByte
    btfsc STATUS,C
    return
;
    PAGE1
    movwf SPBRG
    PAGE0
    return

NotBaud:
	movlw 'p'
	xorwf DataIn,W
	btfss STATUS,Z
	goto NotParity
;
    call GetByte
    btfsc STATUS,C
    return
;
    movlw 'N'
    xorwf DataIn,W
    btfss STATUS,Z
    goto NotParNone
;
    bcf Flags,PARITY_ENABLED_BIT
    return

NotParNone:
    movlw 'E'
    xorwf DataIn,W
    btfss STATUS,Z
    goto NotParEven
;
    bsf Flags,PARITY_ENABLED_BIT
    bsf Flags,PARITY_EVEN_BIT
    return

NotParEven:
    movlw 'O'
    xorwf DataIn,W
    btfss STATUS,Z
    return
;
    bsf Flags,PARITY_ENABLED_BIT
    bcf Flags,PARITY_EVEN_BIT
    return

NotParity:
	movlw 'd'
	xorwf DataIn,W
	btfss STATUS,Z
	goto NotDataBits
;
    call GetByte
    btfsc STATUS,C
    return
;
    movwf DbBits    
    return

NotDataBits:
	movlw 'o'
	xorwf DataIn,W
	btfss STATUS,Z
	return
;
    movlw 7
    xorwf DbBits,W
    btfss STATUS,Z
    goto Not7
;    
    bsf Flags,DATA_7_BIT
    bcf Flags,USE_9_BIT
    goto OpenDo

Not7:    
    movlw 8
    xorwf DbBits,W
    btfss STATUS,Z
    return
;
    btfsc Flags,PARITY_ENABLED_BIT
    bsf Flags,USE_9_BIT
;    
    bcf Flags,DATA_7_BIT

OpenDo:    
    movlw 0x22
    btfsc Flags,USE_9_BIT
    movlw 0x62
    PAGE1
    movwf TXSTA
    PAGE0
;    
    movlw 0x90
    btfsc Flags,USE_9_BIT
    movlw 0xD0
    movwf RCSTA
;    
    bsf Flags,OPEN_BIT
;
    movf RCREG,W
    movf RCREG,W
    movf RCREG,W
;    
    movlw RxBuf
    movwf RxTail
    movwf RxHead
    clrf RxCount
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  HandleStatus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleStatus:
    bcf PORTB,7
;
    btfss Flags,OPEN_BIT
    goto hsClosed

hsOpen:    
    call WriteBit1
    jmp hsCheckTx

hsClosed:
    call WriteBit0

hsCheckTx:
    btfss Flags,TX_BUSY_BIT
    goto hsTxIdle

hsTxBusy;
    call WriteBit1
    goto hsDone

hsTxIdle:
    call WriteBit0 

hsDone:
    bsf PORTB,7
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  HandleData
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleData:
    call GetByte
    btfsc STATUS,C
    return
;
    btfss Flags,PARITY_ENABLED_BIT
    goto TxParityOk
;
    movf DbBits,W
    movwf BitCnt
    movf DataIn,W
    movwf Temp
    movlw 0

ParityLoop:
    btfss Temp,0
    goto ParityNext
;
    addlw 1
    
ParityNext:    
    rrf Temp,F
    
    decfsz BitCnt,F
    goto ParityLoop
;
    btfss Flags,PARITY_EVEN_BIT
    addlw 1    
    movwf Temp
;
    movlw 8
    xorwf DbBits,W
    btfss STATUS,Z
    goto TxPar7
;
    rrf Temp,W
    btfss STATUS,C
    goto TxPar8Clear
;
    PAGE1
    bsf TXSTA,0 
    PAGE0
    goto TxParityOk

TxPar8Clear:
    PAGE1
    bcf TXSTA,0           
    PAGE0
    goto TxParityOk

TxPar7:
    rrf Temp,W
    btfss STATUS,C
    goto TxPar7Clear
;
    bsf DataIn,7
    goto TxParityOk

TxPar7Clear:
    bcf DataIn,7

TxParityOk:    
    movf DataIn,W
    movwf TXREG
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  HandleSpi
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSpi:
    call GetBit
    btfsc STATUS,C
    return
;    
    movwf STATUS
    btfsc STATUS,C
    goto SpiData

SpiCmd    
    call HandleCmd  ; 0 = command
    goto SpiLeave

SpiData:    
    call HandleData ; 1 = data

SpiLeave:
    call Poll
;
    btfsc PORTA,0
    goto SpiLeave
;    
    movf RxCount,W
    btfss STATUS,Z
    goto SpiHasData

SpEpmty:
    bcf PORTA,3
    return
    
SpiHasData:    
    bsf PORTA,3
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Poll
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
Poll:
    btfss Flags,OPEN_BIT
    return
;    
    btfss PIR1,5
    return
;    
    movlw RxBufSize
    xorwf RxCount,W
    btfsc STATUS,Z
    goto RxOverflow
;    
    btfss RCSTA,1
    goto PollNotOverrun
;
    bcf RCSTA,4
    bsf RCSTA,4    
    movf RCREG,W
    movf RCREG,W
    goto RxOverflow

PollNotOverrun:       
    movf RCSTA,W
    incf RxCount,F
    movf RxTail,W
    movwf FSR
    movf RCREG,W
    movwf INDF
;    
    incf RxTail,F
    movlw RxBuf + RxBufSize
    xorwf RxTail,W
    btfss STATUS,Z
    return
;
    movlw RxBuf
    movwf RxTail
    return

RxOverflow:
    movf RCREG,W
    return
             
END
