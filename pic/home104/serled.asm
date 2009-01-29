#include p16f84a.inc

	__config 0x3FF2

;SERLED.ASM

#DEFINE PAGE0   BCF 3,5
#DEFINE PAGE1   BSF 3,5

NODEID:	EQU 0x10
DELAY_TICS:	EQU .200

AL:			EQU 0x0C
DL:			EQU 0x0D
TEMP:		EQU 0x0E
LCNT:		EQU 0x0F
CHAN:		EQU 0x10
VAL:		EQU 0x11
COUNT:		EQU 0x12
BITS:   	EQU 0x13
CRC:		EQU 0x14
CMD:		EQU 0x15
T0:			EQU 0x16
T1:			EQU 0x17
T2:			EQU 0x18
TMRCNT		EQU 0x19
CLKCNT		EQU 0x1A
STATE		EQU 0x1B
BIT			EQU 0x1C
FLREG		EQU 0x1D
SEC			EQU 0x1E
FLVAL  	 	EQU 0x1F

LightLow	EQU 0x20
LightHigh	EQU 0x21
DummyVal	EQU 0x22


	        org 4
    	    org 5

RESET:		PAGE1
			movlw 0x03
			movwf TRISA

			movlw b'11110000'
			movwf TRISB

	        movlw b'10000100' ;move ratio value into W
    	    movwf OPTION_REG    ;set timer ratio to 1:32 (TMR0 rate)

			PAGE0
			clrf PORTA
			clrf PORTB
;
			movlw .152
			movwf TMRCNT
			bcf INTCON,2
;
			movlw 0xFF
			movwf TEMP
;
			movlw DELAY_TICS
			movwf CLKCNT

			clrf STATE
			clrf SEC
;
			clrf LightLow
			clrf LightHigh
			clrf DummyVal
;
            movlw 1
            movwf PORTB			
;
			goto ILOOP


HandleRead:
			movf CHAN,W
			addwf PCL,F
			goto DummyRead      ; 0
			goto DummyRead      ; 1
			goto DummyRead      ; 2
			goto DummyRead      ; 3
			goto DummyRead      ; 4
			goto DummyRead      ; 5
			goto DummyRead      ; 6
			goto DummyRead      ; 7

HandleWrite:
			movf CHAN,W
			addwf PCL,F
			goto DummyWrite       ; 0
			goto DummyWrite     ; 1
			goto DummyWrite     ; 2
			goto WriteLight     ; 3
			goto DummyWrite     ; 4
			goto DummyWrite     ; 5
			goto DummyWrite     ; 6
			goto DummyWrite     ; 7

DummyRead:
			clrf T0
			clrf T1
			clrf T2
			return

DummyWrite:
			return

WriteLight:
            movf T0,W
            movwf LightLow
            movf T1,W
            movwf LightHigh
			return
			
ILOOP:		call POLLTIMER
			btfss PORTA,0
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
			andlw 0x3F
			xorwf VAL,W
			btfss STATUS,Z
			goto LOOPHI

			movlw 0x0C
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
			andlw 0x3F
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

LOOPH:		call POLLTIMER
			btfsc PORTA,0
			goto LOOPH
			goto ILOOP
			
POLLTIMER:	decfsz CLKCNT,F
			return
;
			movlw DELAY_TICS
			movwf CLKCNT

POLLTIM:	btfss INTCON,2
			return

			bcf INTCON,2
;
			decfsz TMRCNT,F
			goto DoIdle
			goto DoSec

DoIdle:
			return

DoSec:
			movlw DELAY_TICS
			movwf CLKCNT
			
			movlw .153
			movwf TMRCNT
;
			bsf SEC,7
			return

DELAY:		return

UPDATECRC:	andlw 1
			movwf BITS
			clrf TEMP
			bcf STATUS,C
			rlf CRC,F
			rlf TEMP,W
			xorwf BITS,W
			btfsc STATUS,Z
			return

			movlw 0x26
			xorwf CRC,F
			return

WAITCLK:	call POLLTIMER
			btfsc PORTA,0
			goto WAITCLK

WCLKLOW:	call POLLTIMER
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

READCMD:	movlw .24
			movwf COUNT
			call HandleRead
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

			movlw 0xA5
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
			andlw 0x3F
			xorwf VAL,W
			btfss STATUS,Z
			return

WRCRCOK:	call HandleWrite
			return

        end
