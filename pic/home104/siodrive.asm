;TEST.ASM

#DEFINE PAGE0   BCF $03,5
#DEFINE PAGE1   BSF $03,5

PCL:    .EQU 2
STATUS: .EQU 3
PORTA:  .EQU 5
PORTB:  .EQU 6
TRISA:  .EQU 5
TRISB:  .EQU 6

NODEID:	.EQU 1

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

COUNT:  .EQU $0F
BITS:   .EQU $10
TEMP:	.EQU $11
CRC:	.EQU $12
VAL:	.EQU $13
CMD:	.EQU $14
CHAN:	.EQU $15
ATTENT:	.EQU $16

	        .ORG 4
    	    .ORG 5

RESET:		PAGE1
			movlw $13
			movwf TRISA

			clrf TRISB
			PAGE0
			clrf ATTENT
			clrf TEMP
			clrf PORTA
			call READEE

LOOP:		call UPDATEREQ
			btfsc PORTA,4
			goto LOCAL

			btfss PORTA,0
			goto LOOP

			clrf PORTA

			movlw 7
			movwf COUNT

PREAMP:		btfss PORTA,1
			goto LOOP

			call WAITCLK

			btfsc PORTA,4
			goto LOCAL
			
			decfsz COUNT,F
			goto PREAMP

WAITST:		btfss PORTA,1
			goto STARTID

			call WAITCLK
			btfsc PORTA,4
			goto LOCAL
			goto WAITST

STARTID:	clrf CRC
			clrf VAL
			movlw 6
			movwf COUNT

IDLOOP:		call WAITCLK
			btfsc PORTA,4
			goto LOCAL

			call UPDATEVAL
			call UPDATECRC

			decfsz COUNT,F
			goto IDLOOP

IDDONE:		call WAITCLK
			btfsc PORTA,4
			goto LOCAL

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
			btfsc PORTA,4
			goto LOCAL

			call UPDATEVAL

			decfsz COUNT,F
			goto IDCRCLOOP

IDCRCDONE:	call WAITCLK
			btfsc PORTA,4
			goto LOCAL

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
			btfsc PORTA,4
			goto LOCAL

			call UPDATEVAL
			call UPDATECRC

			decfsz COUNT,F
			goto DEVLOOP

			call WAITCLK
			btfsc PORTA,4
			goto LOCAL

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
			btfsc PORTA,4
			goto LOCAL

			call UPDATEVAL

			decfsz COUNT,F
			goto DEVCRCLOOP

DEVCRCDONE:	call WAITCLK
			btfsc PORTA,4
			goto LOCAL

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

DEVDONE:	movlw 4
			xorwf CMD,W
			btfsc STATUS,Z
			call TOGGLECMD

			movlw 5
			xorwf CMD,W
			btfsc STATUS,Z
			call READCMD

LOOPW:		btfsc PORTA,4
			goto LOCAL

			btfsc PORTA,0
			goto LOOPW

LOOPHI:		clrf PORTA

LOOPH:		btfsc PORTA,4
			goto LOCAL

			btfsc PORTA,0
			goto LOOPH
			goto LOOP

LOCAL:		movlw 3
			movwf COUNT
			clrf BITS

CLKLOW:		btfss PORTA,4
			goto LOOP

			btfss PORTA,0
			goto CLKLOW

			btfss PORTA,1
			goto BITCLEAR

BITSET:		bsf BITS,2
			goto BITNEXT

BITCLEAR:	bcf BITS,2

BITNEXT:	decfsz COUNT,F
			goto BITROT
			goto SAVEBIT

BITROT:		rrf BITS,F

CLKHI:		btfss PORTA,4
			goto LOOP

			btfsc PORTA,0
			goto CLKHI
			goto CLKLOW

SAVEBIT:	movf BITS,W
			andlw 7
			call TOGGLEBIT
			call WRITEEE

			movlw $08
			movwf PORTA
			movlw $0C
			movwf PORTA
			movwf ATTENT

LOOP2:		btfss PORTA,4
			goto LOOP
			goto LOOP2

READEE:		clrf EEADR
        	PAGE1
        	bsf EECON1,RD
    	    PAGE0
	        movf EEDATA,W
			movwf PORTB
			return

WRITEEE:	clrf EEADR
			PAGE1
	        bsf EECON1,WREN
	        PAGE0
    	    movf PORTB,W
	        movwf EEDATA

		 	PAGE1
     		movlw $55
	        movwf EECON2
	        movlw $AA
	        movwf EECON2
       	   	bsf EECON1,WR

CHKWRT:		btfss EECON1,4
	        goto CHKWRT

    	    bcf EECON1,WREN 
	        bcf EECON1,4
 	        PAGE0
        	bcf INTCON,6
			return
			
TOGGLEBIT:	movwf COUNT
			incf COUNT,F
			clrf BITS
			bsf STATUS,C

BITLOOP:	rlf BITS,F
			decfsz COUNT,F
			goto BITLOOP

			movf BITS,W
			xorwf PORTB,F
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

WAITCLK:	btfsc PORTA,4
			return

			btfsc PORTA,0
			goto WAITCLK

WCLKLOW:	btfsc PORTA,4
			return

			btfss PORTA,0
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

DECODEBITS: movwf COUNT
			incf COUNT,F
			clrf BITS
			bsf STATUS,C

DECBITLOOP:	rlf BITS,F
			decfsz COUNT,F
			goto DECBITLOOP

			movf BITS,W
			return

TOGGLECMD:	movf CHAN,W
			call DECODEBITS
			xorwf PORTB,F
			call WRITEEE
			return

READCMD:	clrf ATTENT

			movlw 8
			movwf COUNT
			movf PORTB,W
			movwf VAL
			clrf CRC

RDVALLOOP:	movf VAL,W
			call UPDATECRC

			rrf VAL,F
			btfss STATUS,C
			goto RDVALRESET

RDVALSET:	bsf PORTA,2
			goto RDVALNEXT

RDVALRESET:	bcf PORTA,2

RDVALNEXT:	call WAITCLK
			btfsc PORTA,4
			return

			btfsc PORTA,1
			return

			decfsz COUNT,F
			goto RDVALLOOP

			movlw 8
			movwf COUNT

			movlw $5A
			xorwf CRC,F

RDCRCLOOP:	movf CRC,W
			rrf CRC,F
			btfss STATUS,C
			goto RDCRCRESET

RDCRCSET:	bsf PORTA,2
			goto RDCRCNEXT

RDCRCRESET:	bcf PORTA,2

RDCRCNEXT:	call WAITCLK
			btfsc PORTA,4
			return

			btfsc PORTA,1
			return

			decfsz COUNT,F
			goto RDCRCLOOP
			
			return

UPDATEREQ:	movf ATTENT,W
			btfss STATUS,Z
			goto UPDATEACT

			clrf PORTA
			return

UPDATEACT:	movlw $0C
			movwf PORTA
			return

        .END
