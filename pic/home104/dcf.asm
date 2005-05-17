;DCF.ASM

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

VAL:    .EQU $0F

    .ORG 4
    .ORG 5

RESET:		
    PAGE1
    movlw $16
	movwf TRISA
;
	movlw $00
	movwf TRISB
;			
    PAGE0
;			
    movlw 1
    movwf PORTA
;
    movlw $00
    movwf PORTB			
			
WAITL:
	btfss PORTA,4
	goto WAITL
;	
    movlw $5A
    call WritePort

WAITH:
    btfsc PORTA,4
    goto WAITH

    goto WAITL

;;;;;;;;;;;;
; WritePort
;;;;;;;;;;;;

WritePort:
    movwf PORTB 
;
    bcf PORTA,0
    nop
    nop
    bsf PORTA,0    
    return
            
        .END

