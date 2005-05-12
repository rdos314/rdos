;PCBUS.ASM

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

CRC:    .EQU $0F
VAL:    .EQU $10
COUNT:  .EQU $11
DELCNT: .EQU $12
TEMP:   .EQU $13
BITS:   .EQU $14
CMD:    .EQU $15
CMDLEN: .EQU $16
LINE:   .EQU $17

    .ORG 4
    .ORG 5

RESET:		
    PAGE1
    movlw $10
	movwf TRISA
;
	movlw $7F
	movwf TRISB
;
    movlw $D7
    movwf OPT
;			
    PAGE0
;			
    movlw 1
    movwf PORTA
;
    movlw $80
    movwf PORTB			
			
WAIT:
    bcf PORTA,1    
	btfss PORTB,6
	goto WAIT
;	
    bsf PORTA,1
    call Preamp
    call ReadPort
    call Output6
    call Delay
;
    movlw $1A
    btfss PORTA,4
    movlw 0   
    movwf VAL
    call WritePort
;    
    movf VAL,W
    btfsc STATUS,Z
    goto WAIT
;
    call ReadPort
    movf VAL,W
    movwf CMD
    call Output6	    
;
    movlw 1
    movwf VAL
    call WritePort
;
    call CmdProc
    goto WAIT

CmdProc:
	movf CMD,W
	andlw 7
	addwf PCL,F
	goto WAIT      ; 0
	goto WAIT      ; 1
	goto Read24    ; 2
	goto Write24   ; 3
	goto WAIT      ; 4
	goto ReadLine  ; 5
	goto WAIT      ; 6
	goto WAIT      ; 7

;;;;;;;;;;
; Delay
;;;;;;;;;;

Delay:
    movlw 10
    movwf DELCNT
;

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

;;;;;;;;;;;;
; ReadPort
;;;;;;;;;;;;

ReadPort:
    
ReadWaitLoop:
	btfss PORTB,6
	goto ReadWaitLoop

    PAGE1
	movlw $7F
	movwf TRISB
	PAGE0
;            			
    bcf PORTB,7
    movf PORTB,W
    movwf VAL
    bsf PORTB,7
;
    return

;;;;;;;;;;;;
; WritePort
;;;;;;;;;;;;

WritePort:
    PAGE1
	movlw $40
	movwf TRISB
	PAGE0
;
    movf VAL,W
    andlw $3F
    iorlw $80
    movwf PORTB 
;
    bcf PORTA,0
    nop
    nop
    bsf PORTA,0    
    return

;;;;;;;;;;;;
; OutputBit
;;;;;;;;;;;;

OutputBit:
    btfss VAL,0
    goto BitClear

BitSet:
    bsf PORTA,3
    goto BitDone

BitClear:
    bcf PORTA,3

BitDone:
    call Delay
;    
    bsf PORTA,2
    call Delay
;
    bcf PORTA,2
    call Delay
;
    return

;;;;;;;;;;;;
; InputBit
;;;;;;;;;;;;

InputBit:
    call Delay
    btfsc PORTA,4
    bsf VAL,6
;    
    bsf PORTA,2
    call Delay
;
    bcf PORTA,2
    call Delay
;
    return

;;;;;;;;;;;;
; Preamp
;;;;;;;;;;;;

Preamp:
    call Delay
    movlw 14
    movwf COUNT
    bsf VAL,0

PreampLoop:
    call OutputBit
    decf COUNT,F
    btfss STATUS,Z
    goto PreampLoop
;
    bcf VAL,0
    call OutputBit
    return

;;;;;;;;;;;;
; UpdateOutCrc
;;;;;;;;;;;;

UpdateOutCrc:	
    movf VAL,W
    andlw 1
	movwf BITS
	clrf TEMP
	bcf STATUS,C
	rlf CRC,F
	rlf TEMP,W
	xorwf BITS,W
	btfsc STATUS,Z
	return

	movlw $26
	xorwf CRC,F
	return

;;;;;;;;;;;;
; UpdateInCrc
;;;;;;;;;;;;

UpdateInCrc:
    movf VAL,W
    movwf TEMP
    rlf TEMP,F
    rlf TEMP,F
    rlf TEMP,W
    andlw 1
	movwf BITS
	clrf TEMP
	bcf STATUS,C
	rlf CRC,F
	rlf TEMP,W
	xorwf BITS,W
	btfsc STATUS,Z
	return

	movlw $26
	xorwf CRC,F
	return

;;;;;;;;;;;;
; Output6
;;;;;;;;;;;;

Output6:
    clrf CRC
;
    movlw 6
    movwf COUNT

OutDataLoop6:
    call OutputBit
    call UpdateOutCrc
    rrf VAL,F
    decf COUNT,F
    btfss STATUS,Z
    goto OutDataLoop6
;
    bcf VAL,0
    call OutputBit
;
    movf CRC,W
    movwf VAL
;
    movlw 6
    movwf COUNT

OutCrcLoop6:
    call OutputBit
    rrf VAL,F
    decf COUNT,F
    btfss STATUS,Z
    goto OutCrcLoop6
;
    bcf VAL,0
    call OutputBit
    call Delay
    return                                                  

;;;;;;;;;;;;
; Write24
;;;;;;;;;;;;

Write24:
    clrf CRC
    movlw 4
    movwf CMDLEN

OutByteLoop24:
    call ReadPort
    movlw 6
    movwf COUNT

OutDataLoop24:
    call OutputBit
    call UpdateOutCrc
    rrf VAL,F
    decf COUNT,F
    btfss STATUS,Z
    goto OutDataLoop24
;
    bcf VAL,0
    call OutputBit
    call Delay
;    
    decf CMDLEN,F
    btfsc STATUS,Z
    goto OutCrc24
;
    movlw 1
    btfss PORTA,4
    movlw 0   
    movwf VAL
    call WritePort
    movf VAL,W
    btfsc STATUS,Z
    return
    goto OutByteLoop24

OutCrc24:
    btfsc PORTA,4
    goto OutCrcDo24
;
    clrf VAL
    call WritePort
    return

OutCrcDo24:    
    movf CRC,W
    movwf VAL
;
    movlw 6
    movwf COUNT

OutCrcLoop24:
    call OutputBit
    rrf VAL,F
    decf COUNT,F
    btfss STATUS,Z
    goto OutCrcLoop24
;
    movlw 1
    btfss PORTA,4
    movlw 0   
    movwf VAL
    call WritePort
;
    bcf VAL,0
    call OutputBit
    call Delay
;
    bcf VAL,0
    call OutputBit
    call Delay
    return

;;;;;;;;;;;;
; Read24
;;;;;;;;;;;;

Read24:
    clrf CRC
    movlw 4
    movwf CMDLEN

InByteLoop24:
    movlw 6
    movwf COUNT
    call ReadPort

InDataLoop24:
    call InputBit
    call UpdateInCrc
    rrf VAL,F
    decf COUNT,F
    btfss STATUS,Z
    goto InDataLoop24
;
    movf VAL,W
    call WritePort
;    
    decf CMDLEN,F
    btfss STATUS,Z
    goto InByteLoop24
;
    call ReadPort
    movlw $A5
    xorwf CRC,F
    movlw 8
    movwf COUNT

InCrcLoop24:
    clrf VAL
    call InputBit
    rlf VAL,F
    rlf VAL,F
    rlf VAL,W
    andlw 1
    xorwf CRC,W
    andlw 1
    btfss STATUS,Z
    goto InCrcFail
;    
    rrf CRC,F
    decf COUNT,F
    btfss STATUS,Z
    goto InCrcLoop24
;
    movlw 1
    movwf VAL
    call WritePort
    return

InCrcFailLoop:
    call InputBit

InCrcFail:
    decf COUNT,F
    btfss STATUS,Z
    goto InCrcFailLoop
;
    clrf VAL
    call WritePort
    return

;;;;;;;;;;;;
; ReadLine
;;;;;;;;;;;;

ReadLine:
    call ReadPort
    clrf LINE
    movlw 8
    movwf COUNT

ReadLineLoop:
    rlf LINE,F
    clrf VAL
    call InputBit
    call UpdateInCrc
    rlf VAL,W
    andlw $80
    iorwf LINE,F
    decf COUNT,F
    btfss STATUS,Z
    goto ReadLineLoop
;
    movlw $5A
    xorwf CRC,F
    movlw 8
    movwf COUNT

ReadLineCrcLoop:
    clrf VAL
    call InputBit
    rlf VAL,F
    rlf VAL,F
    rlf VAL,W
    andlw 1
    xorwf CRC,W
    andlw 1
    btfss STATUS,Z
    goto ReadLineCrcFail
;    
    rrf CRC,F
    decf COUNT,F
    btfss STATUS,Z
    goto ReadLineCrcLoop
;
    movf LINE,W
    andlw $0F
    iorlw $30
    movwf VAL
    call WritePort
;    
    call ReadPort
    rrf LINE,F
    rrf LINE,F
    rrf LINE,F
    rrf LINE,W
    andlw $0F
    iorlw $30
    movwf VAL
    call WritePort            
    return

ReadLineCrcFailLoop:
    call InputBit

ReadLineCrcFail:
    decf COUNT,F
    btfss STATUS,Z
    goto ReadLineCrcFailLoop
;
    clrf VAL
    call WritePort
    return
            
        .END

