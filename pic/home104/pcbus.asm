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
	btfss PORTB,6
	goto WAIT
    call Output6

    goto WAIT

;;;;;;;;;;
; Delay
;;;;;;;;;;

Delay:
    movlw $FF
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
    PAGE1
	movlw $7F
	movwf TRISB
	PAGE0
;            			
    bcf PORTB,7
    clrf CRC
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
; Preamp
;;;;;;;;;;;;

Preamp:
    movlw 14
    movwf COUNT
    bsf VAL,0

PreampLoop:
    call OutputBit
    decf COUNT,F
    btfss STATUS,Z
    goto PreampLoop
;
    return

;;;;;;;;;;;;
; Output6
;;;;;;;;;;;;

Output6:
    call ReadPort
    bsf PORTA,1
    call Delay
;
    call Preamp
;
    movlw 6
    movwf COUNT

OutLoop6:
    call OutputBit
    rrf VAL,F
    decf COUNT,F
    btfss STATUS,Z
    goto OutLoop6
;
    movlw 1
    movwf VAL
    call WritePort
;
    bcf PORTA,1    
    return                                                  
            
        .END

