;SERDA.ASM

#DEFINE PAGE0   BCF $03,5
#DEFINE PAGE1   BSF $03,5

INDF:	.EQU 0
PCL:    .EQU 2
STATUS: .EQU 3
FSR:	.EQU 4
PORTA:  .EQU 5
PORTB:  .EQU 6
TRISA:  .EQU 5
TRISB:  .EQU 6

NODEID:	.EQU 2

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

AL:		.EQU $0F
DL:		.EQU $10
TEMP:	.EQU $11
LCNT:	.EQU $12
CHAN:	.EQU $13
VAL:	.EQU $14
COUNT:	.EQU $15
BITS:   .EQU $16
CRC:	.EQU $17
CMD:	.EQU $18
T0:		.EQU $19
T1:		.EQU $1A
T2:		.EQU $1B

VAL0:	.EQU $20
VAL1:	.EQU $21
VAL2:	.EQU $22
VAL3:	.EQU $23
VAL4:	.EQU $24
VAL5:	.EQU $25
VAL6:	.EQU $26
VAL7:	.EQU $27

	        .ORG 4
    	    .ORG 5

RESET:		PAGE1
			movlw $13
			movwf TRISA

			movlw $64
			movwf TRISB
			PAGE0
			clrf PORTA
;
			movlw $19
			movwf PORTB
;
			movlw $FF
			movwf TEMP

			clrf VAL0
			clrf VAL1
			clrf VAL2
			clrf VAL3
			clrf VAL4
			clrf VAL5
			clrf VAL6
			clrf VAL7

ILOOP:		btfss PORTA,0
			goto ILOOP

REMOTE:		clrf PORTA

			movlw 7
			movwf COUNT

PREAMP:		btfss PORTA,1
			goto ILOOP

			call WAITCLK
			
			decfsz COUNT,F
			goto PREAMP

WAITST:		btfss PORTA,1
			goto STARTID

			call WAITCLK
			goto WAITST

STARTID:	clrf CRC
			clrf VAL
			movlw 6
			movwf COUNT

IDLOOP:		call WAITCLK
			call UPDATEVAL
			call UPDATECRC

			decfsz COUNT,F
			goto IDLOOP

IDDONE:		call WAITCLK

			btfsc PORTA,1
			goto LOOPHI

			bcf STATUS,C
			rrf VAL,F
			rrf VAL,F
			movlw NODEID
			xorwf VAL,W
			btfss STATUS,Z
			goto LOOPHI

			movlw 6
			movwf COUNT
			clrf VAL

IDCRCLOOP:	call WAITCLK
			call UPDATEVAL

			decfsz COUNT,F
			goto IDCRCLOOP

IDCRCDONE:	call WAITCLK

			btfsc PORTA,1
			goto LOOPHI

			bcf STATUS,C
			rrf VAL,F
			rrf VAL,F
			movf CRC,W
			andlw $3F
			xorwf VAL,W
			btfss STATUS,Z
			goto LOOPHI

			movlw $0C
			movwf PORTA

			movlw 6
			movwf COUNT
			clrf VAL
			clrf CRC

DEVLOOP:	call WAITCLK
			call UPDATEVAL
			call UPDATECRC

			decfsz COUNT,F
			goto DEVLOOP

			call WAITCLK

			btfsc PORTA,1
			goto LOOPHI

			bcf STATUS,C
			rrf VAL,F
			rrf VAL,F

			movf VAL,W
			andlw 7
			movwf CMD

			movf VAL,W
			movwf CHAN
			rrf CHAN,F
			rrf CHAN,F
			rrf CHAN,W
			andlw 7
			movwf CHAN

			movlw 6
			movwf COUNT
			clrf VAL

DEVCRCLOOP:	call WAITCLK
			call UPDATEVAL

			decfsz COUNT,F
			goto DEVCRCLOOP

DEVCRCDONE:	call WAITCLK

			btfsc PORTA,1
			goto LOOPHI

			bcf STATUS,C
			rrf VAL,F
			rrf VAL,F
			movf CRC,W
			andlw $3F
			xorwf VAL,W
			btfss STATUS,Z
			goto LOOPHI

DEVDONE:	movlw 2
			xorwf CMD,W
			btfsc STATUS,Z
			call READCMD

			movlw 3
			xorwf CMD,W
			btfsc STATUS,Z
			call WRITECMD

LOOPHI:		clrf PORTA

LOOPH:		btfsc PORTA,0
			goto LOOPH
			goto ILOOP

DELAY:		return

OUTPUTDA:	movlw 1
			movwf AL
			movf CHAN,W
			addlw 1
			movwf TEMP
			goto CHDANEXT

CHDALOOP:	bcf STATUS,C
			rlf AL,F

CHDANEXT:	decfsz TEMP,F
			goto CHDALOOP			

			movf VAL,W
			movwf DL
;
			call DELAY
			movlw $18
			movwf PORTB
;
			call DELAY
			movlw $10
			movwf PORTB
;
			movlw 8
			movwf TEMP

CHANLOOP:	call DELAY
			movlw $10
			btfsc AL,7
			movlw $12
			movwf PORTB
;
			call DELAY
			movlw $11
			btfsc AL,7
			movlw $13
			movwf PORTB
;
			rlf AL,F
			decfsz TEMP,F
			goto CHANLOOP
;
			movlw 8
			movwf TEMP

VALLOOP:	call DELAY
			movlw $10
			btfsc DL,7
			movlw $12
			movwf PORTB
;
			call DELAY
			movlw $11
			btfsc DL,7
			movlw $13
			movwf PORTB
;
			rlf DL,F
			decfsz TEMP,F
			goto VALLOOP
;
			call DELAY
			movlw $10
			movwf PORTB
;
			call DELAY
			movlw $18
			movwf PORTB
;
			call DELAY
			movlw $19
			movwf PORTB
;
			call DELAY
			return						

UPDATECRC:	andlw 1
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

WAITCLK:	btfsc PORTA,0
			goto WAITCLK

WCLKLOW:	btfss PORTA,0
			goto WCLKLOW
			return

UPDATEVAL:  movf PORTA,W
			movwf TEMP
			btfsc TEMP,1
			goto VALSET

VALRESET:	bcf STATUS,C
			goto UPDATEDO

VALSET:		bsf STATUS,C

UPDATEDO:	rrf VAL,F
			rrf TEMP,W
			return

READCMD:	movlw 24
			movwf COUNT

			movf CHAN,W
			addlw VAL0
			movwf FSR
			movf INDF,W
			movwf T2
			clrf T1
			clrf T0

			bcf STATUS,C
			rrf T2,F
			rrf T1,F
			rrf T0,F

			clrf CRC

RDVALLOOP:	movf T0,W
			call UPDATECRC

			rrf T2,F
			rrf T1,F
			rrf T0,F
			btfss STATUS,C
			goto RDVALRESET

RDVALSET:	bsf PORTA,2
			goto RDVALNEXT

RDVALRESET:	bcf PORTA,2

RDVALNEXT:	call WAITCLK
			btfsc PORTA,1
			return

RDVALCONT:	decfsz COUNT,F
			goto RDVALLOOP

			movlw 8
			movwf COUNT

			movlw $A5
			xorwf CRC,F

RDCRCLOOP:	movf CRC,W
			rrf CRC,F
			btfss STATUS,C
			goto RDCRCRESET

RDCRCSET:	bsf PORTA,2
			goto RDCRCNEXT

RDCRCRESET:	bcf PORTA,2

RDCRCNEXT:	call WAITCLK
			btfsc PORTA,1
			return

RDCRCCONT:	decfsz COUNT,F
			goto RDCRCLOOP
			return

UPDWRVAL:   movf PORTA,W
			movwf TEMP
			btfsc TEMP,1
			goto UPDWRSET

UPDWRCLR:	bcf STATUS,C
			goto UPDWRDO

UPDWRSET:	bsf STATUS,C

UPDWRDO:	rrf T2,F
			rrf T1,F
			rrf T0,F
			rrf TEMP,W
			return

WRITECMD:	clrf T0
			clrf T1
			clrf T2
			clrf CRC

			movlw 6
			movwf COUNT

WRLOOP1:	call WAITCLK
			call UPDWRVAL
			call UPDATECRC

			decfsz COUNT,F
			goto WRLOOP1

			call WAITCLK

			btfsc PORTA,1
			return

WRNEXT1:	movlw 6
			movwf COUNT

WRLOOP2:	call WAITCLK
			call UPDWRVAL
			call UPDATECRC

			decfsz COUNT,F
			goto WRLOOP2

			call WAITCLK

			btfsc PORTA,1
			return

WRNEXT2:	movlw 6
			movwf COUNT

WRLOOP3:	call WAITCLK
			call UPDWRVAL
			call UPDATECRC

			decfsz COUNT,F
			goto WRLOOP3

			call WAITCLK

			btfsc PORTA,1
			return

WRNEXT3:	movlw 6
			movwf COUNT

WRLOOP4:	call WAITCLK
			call UPDWRVAL
			call UPDATECRC

			decfsz COUNT,F
			goto WRLOOP4

			call WAITCLK

			btfsc PORTA,1
			return

WRNEXT4:	movlw 6
			movwf COUNT
			clrf VAL

WRCRCLOOP:	call WAITCLK
			call UPDATEVAL

			decfsz COUNT,F
			goto WRCRCLOOP

WRCRCDONE:	call WAITCLK

			btfsc PORTA,1
			return

WRCRCCONT:	bcf STATUS,C
			rrf VAL,F
			rrf VAL,F
			movf CRC,W
			andlw $3F
			xorwf VAL,W
			btfss STATUS,Z
			return

WRCRCOK:	movf CHAN,W
			addlw VAL0
			movwf FSR
;
			bcf STATUS,C
			rlf T0,F
			rlf T1,F
			rlf T2,F
			btfss STATUS,C
			goto WRPOSVAL

			clrf INDF
			clrf VAL
			goto WRVALDO

WRPOSVAL:	movf T2,W
			movwf INDF
			movwf VAL

WRVALDO:	call OUTPUTDA
			return

        .END
