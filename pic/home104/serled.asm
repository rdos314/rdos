#include p16f84a.inc

	__config 0x3FF2

;SERLED.ASM

#DEFINE PAGE0   BCF 3,5
#DEFINE PAGE1   BSF 3,5

NODEID:	EQU 0x10

PwmPeriod   EQU .50

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

LedState    EQU 0x19
LedCnt      EQU 0x1A

PwmCnt      EQU 0x1B
PwmVal0     EQU 0x1C
PwmVal1     EQU 0x1D
PwmVal2     EQU 0x1E
PwmVal3     EQU 0x1F

LightLow	EQU 0x20
LightHigh	EQU 0x21
DummyVal	EQU 0x22
Period      EQU 0x23


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Startup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	        org 4
    	    org 5

RESET:		PAGE1
			movlw 0x03
			movwf TRISA

			movlw b'11110000'
			movwf TRISB

	        movlw b'10001000' 
    	    movwf OPTION_REG    ;set timer to fosc / 4

			PAGE0
			clrf PORTA
			clrf PORTB
			bcf INTCON,2
;
			movlw 0xFF
			movwf TEMP
;
            movlw .25
            movwf Period
;
            clrf LedState
            clrf PwmCnt
            clrf PwmVal1
            clrf PwmVal2
            clrf PwmVal3
;
            movlw PwmPeriod
            movwf PwmVal0
;
            movf Period,W            
            movwf LedCnt
;
			clrf LightLow
			clrf LightHigh
			clrf DummyVal
;
			goto ILOOP

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code starts here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateLedState
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLedState:
            movf LedState,W
            addwf PCL,F
            goto UpdateLedFw0
            goto UpdateLedFw1
            goto UpdateLedFw2
            goto UpdateLedRv2
            goto UpdateLedRv1
            goto UpdateLedRv0            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleRead
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleWrite
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleWrite:
			movf CHAN,W
			addwf PCL,F
			goto WritePeriod    ; 0
			goto DummyWrite     ; 1
			goto DummyWrite     ; 2
			goto WriteLight     ; 3
			goto DummyWrite     ; 4
			goto DummyWrite     ; 5
			goto DummyWrite     ; 6
			goto DummyWrite     ; 7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DummyRead
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DummyRead:
			clrf T0
			clrf T1
			clrf T2
			return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DummyWrite
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DummyWrite:
			return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteLight
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteLight:
            movf T0,W
            movwf LightLow
            movf T1,W
            movwf LightHigh
			return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WritePeriod
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePeriod:
            movf T0,W
            movwf Period
			return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateLedFw0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLedFw0:
            incf PwmVal1,F
            decf PwmVal0,F
            btfss STATUS,Z
			return
;
            incf LedState,F			
            return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateLedFw1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLedFw1:
            incf PwmVal2,F
            decf PwmVal1,F
            btfss STATUS,Z
			return
;
            incf LedState,F			
            return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateLedFw2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLedFw2:
            incf PwmVal3,F
            decf PwmVal2,F
            btfss STATUS,Z
			return
;
            incf LedState,F			
			return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateLedRv2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLedRv2:
            incf PwmVal2,F
            decf PwmVal3,F
            btfss STATUS,Z
			return
;
            incf LedState,F			
			return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateLedRv1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLedRv1:
            incf PwmVal1,F
            decf PwmVal2,F
            btfss STATUS,Z
			return
;
            incf LedState,F			
			return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateLedRv0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLedRv0:
            incf PwmVal0,F
            decf PwmVal1,F
            btfss STATUS,Z
			return
;
            clrf LedState			
			return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; MainLoop
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
ILOOP:		call PollTimer
			btfss PORTA,0
			goto ILOOP

REMOTE:		clrf PORTA

			movlw 7
			movwf COUNT

PREAMP:		btfss PORTA,1
			goto ILOOP

			call WaitClk
			
			decfsz COUNT,F
			goto PREAMP

WAITST:		btfss PORTA,1
			goto STARTID

			call WaitClk
			goto WAITST

STARTID:	clrf CRC
			clrf VAL
			movlw 6
			movwf COUNT

IDLOOP:		call WaitClk
			call UpdateVal
			call UpdateCrc

			decfsz COUNT,F
			goto IDLOOP

IDDONE:		call WaitClk

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

IDCRCLOOP:	call WaitClk
			call UpdateVal

			decfsz COUNT,F
			goto IDCRCLOOP

IDCRCDONE:	call WaitClk

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

DEVLOOP:	call WaitClk
			call UpdateVal
			call UpdateCrc

			decfsz COUNT,F
			goto DEVLOOP

			call WaitClk

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

DEVCRCLOOP:	call WaitClk
			call UpdateVal

			decfsz COUNT,F
			goto DEVCRCLOOP

DEVCRCDONE:	call WaitClk

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
			call ReadCmd

			movlw 3
			xorwf CMD,W
			btfsc STATUS,Z
			call WriteCmd

LOOPHI:		clrf PORTA

LOOPH:		call PollTimer
			btfsc PORTA,0
			goto LOOPH
			goto ILOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PollTimer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
PollTimer:	btfss INTCON,2
			return

			bcf INTCON,2
;
            incf PwmCnt,F
            movlw PwmPeriod
            xorwf PwmCnt,W
            btfss STATUS,Z
            goto UpdatePwm
;
            decf LedCnt,F
            btfss STATUS,Z
            goto ResetPwm            
;
            movf Period,W
            movwf LedCnt
            call UpdateLedState            

ResetPwm:
            clrf PwmCnt
;            
            movf PwmVal0,W
            btfss STATUS,Z
            bsf PORTB,0            
;            
            movf PwmVal1,W
            btfss STATUS,Z
            bsf PORTB,1           
;                        
            movf PwmVal2,W
            btfss STATUS,Z
            bsf PORTB,2           
;            
            movf PwmVal3,W
            btfss STATUS,Z
            bsf PORTB,3           
            return

UpdatePwm:
            movf PwmVal0,W
            subwf PwmCnt,W
            btfsc STATUS,Z
            bcf PORTB,0
;            
            movf PwmVal1,W
            subwf PwmCnt,W
            btfsc STATUS,Z
            bcf PORTB,1
;            
            movf PwmVal2,W
            subwf PwmCnt,W
            btfsc STATUS,Z
            bcf PORTB,2
;            
            movf PwmVal3,W
            subwf PwmCnt,W
            btfsc STATUS,Z
            bcf PORTB,3
            return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateCrc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateCrc:	andlw 1
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WaitClk
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitClk:	call PollTimer
			btfsc PORTA,0
			goto WaitClk

WCLKLOW:	call PollTimer
			btfss PORTA,0
			goto WCLKLOW
			return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateVal
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateVal:  movf PORTA,W
			movwf TEMP
			btfsc TEMP,1
			goto VALSET

VALRESET:	bcf STATUS,C
			goto UPDATEDO

VALSET:		bsf STATUS,C

UPDATEDO:	rrf VAL,F
			rrf TEMP,W
			return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadCmd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCmd:	movlw .24
			movwf COUNT
			call HandleRead
			clrf CRC

RDVALLOOP:	movf T0,W
			call UpdateCrc

			rrf T2,F
			rrf T1,F
			rrf T0,F
			btfss STATUS,C
			goto RDVALRESET

RDVALSET:	bsf PORTA,2
			goto RDVALNEXT

RDVALRESET:	bcf PORTA,2

RDVALNEXT:	call WaitClk
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

RDCRCNEXT:	call WaitClk
			btfsc PORTA,1
			return

RDCRCCONT:	decfsz COUNT,F
			goto RDCRCLOOP
			return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdWrVal
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdWrVal:   movf PORTA,W
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteCmd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCmd:	clrf T0
			clrf T1
			clrf T2
			clrf CRC

			movlw 6
			movwf COUNT

WRLOOP1:	call WaitClk
			call UpdWrVal
			call UpdateCrc

			decfsz COUNT,F
			goto WRLOOP1

			call WaitClk

			btfsc PORTA,1
			return

WRNEXT1:	movlw 6
			movwf COUNT

WRLOOP2:	call WaitClk
			call UpdWrVal
			call UpdateCrc

			decfsz COUNT,F
			goto WRLOOP2

			call WaitClk

			btfsc PORTA,1
			return

WRNEXT2:	movlw 6
			movwf COUNT

WRLOOP3:	call WaitClk
			call UpdWrVal
			call UpdateCrc

			decfsz COUNT,F
			goto WRLOOP3

			call WaitClk

			btfsc PORTA,1
			return

WRNEXT3:	movlw 6
			movwf COUNT

WRLOOP4:	call WaitClk
			call UpdWrVal
			call UpdateCrc

			decfsz COUNT,F
			goto WRLOOP4

			call WaitClk

			btfsc PORTA,1
			return

WRNEXT4:	movlw 6
			movwf COUNT
			clrf VAL

WRCRCLOOP:	call WaitClk
			call UpdateVal

			decfsz COUNT,F
			goto WRCRCLOOP

WRCRCDONE:	call WaitClk

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
