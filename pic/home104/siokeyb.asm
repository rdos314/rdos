;TEST.ASM

#DEFINE PAGE0   BCF $03,5
#DEFINE PAGE1   BSF $03,5

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

TEMP:   .EQU $0F
KSTATE: .EQU $10
TSTATE:	.EQU $11
STABLE:	.EQU $12
BIT:	.EQU $13
COUNT:	.EQU $14

	        .ORG 4
    	    .ORG 5

RESET:		PAGE1
			movlw $1C
			movwf TRISA

			movlw $FF
			movwf TRISB
			PAGE0
			clrf KSTATE
			clrf PORTA

LOOP:		movf PORTB,W
			xorwf KSTATE,W
			btfsc STATUS,Z
			goto LOOP

			call DEBOUNCE
			movwf KSTATE
			call GETBIT
			btfsc STATUS,C
			goto LOOP

			movwf BIT
			movlw 3
			movwf COUNT
			call ENABLE

SHLOOP:		rrf BIT,F
			btfss STATUS,C
			goto CLEAROUT

SETOUT:		movlw $0B
			movwf PORTA
			call DELAYMS
			movlw $0F
			movwf PORTA
			call DELAYMS
			goto NEXTBIT

CLEAROUT:	movlw $03
			movwf PORTA
			call DELAYMS
			movlw $07
			movwf PORTA
			call DELAYMS

NEXTBIT:	decfsz COUNT,F
			goto SHLOOP

			call DISABLE
			goto LOOP

DEBOUNCE:	movf PORTB,W
			movwf TSTATE
			movlw 10
			movwf STABLE

DEBLOOP:	call DELAYMS
			movf PORTB,W
			xorwf TSTATE,W
			btfss STATUS,Z
			goto DEBOUNCE
			decfsz STABLE,F
			goto DEBLOOP
			movf TSTATE,W
			return

GETBIT:		movwf TEMP
			movlw 8
			movwf BIT

SCANNEXT:	rlf TEMP,F
			btfsc STATUS,C
			goto SCANSET

SCANBL:		decfsz BIT,F
			goto SCANNEXT
			goto SCANFAIL

SCANSET:	decf BIT,W
			goto CHKBL

CHKNEXT:	rlf TEMP,F
			btfsc STATUS,C
			goto SCANFAIL

CHKBL:		decfsz BIT,F
			goto CHKNEXT

SCANOK:		bcf STATUS,C
			return

SCANFAIL:	bsf STATUS,C
			return

DELAYMS:	movlw $FF
			movwf TEMP
DELAYLOOP:	decfsz TEMP,F
			goto DELAYLOOP
			return

ENABLE:		movlw $02
			movwf PORTA
			movlw $03
			movwf PORTA
			PAGE1
			movlw $10
			movwf TRISA
			PAGE0
			return

DISABLE:	PAGE1
			movlw $1C
			movwf TRISA
			PAGE0
			clrf PORTA
			return

        .END
