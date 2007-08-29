#include p16f877a.inc   

	__config 0x3FFA

#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5


; Page 0

Val:        EQU 0x20
Count:      EQU 0x21
LowTemp1:	EQU 0x22
LowTemp2:	EQU 0x23
Crc:        EQU 0x24
CmdLen:     EQU 0x25
Result:     EQU 0x26
Cmd:        EQU 0x27
LowTemp3:   EQU 0x28

; page 2, datalist

DataList:   EQU 0x110

; page 3, cmdlist

CmdList:    EQU 0x190

	org 0

	goto Reset

	org 0x5


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code starts here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleCmd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
HandleCmd:
	movf Cmd,W
	andlw 7
	addwf PCL,F
	goto Dummy          ; 0
	goto Dummy          ; 1
	goto Read24         ; 2
	goto Write24        ; 3
	goto ToggleLine     ; 4
	goto ReadLine       ; 5
	goto Dummy          ; 6
	goto Dummy          ; 7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code ends here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


Reset:
	PAGE1
	movlw 6
	movwf ADCON1
;
	clrf TRISA
;
	movlw b'11101001'
	movwf TRISB
;
	movlw b'10010001'
	movwf TRISC
;
	movlw b'00010111'
	movwf TRISE
;
	PAGE0
;
	movlw b'00111111'
	movwf PORTA
;
	movlw b'00000110'
	movwf PORTB
;
	movlw b'00000110'
	movwf PORTC
;
    movlw 1
    movwf T1CON
;
    bsf STATUS,IRP
    
HandleLoop:
	bcf PORTA, 3
	call ReadCmd
	bsf PORTA, 3
;
    call HandleSerial
;
    movf Result,W
    call SendInt
;
    movf Result,W
    btfsc STATUS,Z
    goto HandleLoop
;	
	andlw 0xF
    call SendData
    goto HandleLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Delay
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delay:
    movlw 4
    movwf LowTemp1
;
	movf TMR1H,W
	movwf LowTemp2

DelayLoop:
    movf TMR1H,W
	xorwf LowTemp2,W
    btfsc STATUS,Z
    goto DelayLoop
;
	movf TMR1H,W
	movwf LowTemp2
;
    decf LowTemp1,F
    btfss STATUS,Z
    goto DelayLoop
;
    return
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadCmd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCmd:
    bcf PORTA, 1
    bsf PORTA, 2
    movlw CmdList
    movwf FSR
	
ReadCmdLoop:
    PAGE1
	btfss TRISE,IBF
	goto ReadCmdLoop
;
    PAGE0
    movf PORTD,W
    movwf INDF
    incf FSR,F
;
    movlw 4
    xorwf PORTA,F
;
    btfss PORTB,7
    goto ReadCmdLoop
;    
    bsf PORTA, 1
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SendInt
;
;   W   Result code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
SendInt:
    movwf PORTD
    bcf PORTA,0

WaitInt:
	PAGE1
	btfsc TRISE,OBF
	goto WaitInt
;
    PAGE0        
    bsf PORTA,0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SendData
;
;  W bytes to send
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
SendData:
	movwf Count
;
    movlw DataList
    movwf FSR

SendDataLoop:        
    movf INDF,W
    movwf PORTD
;
    movlw 4
    xorwf PORTA,F
;    
	PAGE1

SendWait:
	btfsc TRISE,OBF
	goto SendWait
;
    PAGE0        
    incf FSR,F
    decfsz Count,F
    goto SendDataLoop
;    
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; OutputBit
;
;   W   bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputBit:
    movwf LowTemp1
    btfss LowTemp1,0
    goto BitClear

BitSet:
    bcf PORTC,2
    goto BitDone

BitClear:
    bsf PORTC,2

BitDone:
    call Delay
;    
    bcf PORTB,2
    call Delay
;
    bsf PORTB,2
    call Delay
;
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetInput
;
;   W   bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetInput:
    btfss Result,6
    goto GetChan1
;
    btfsc PORTB,0
    retlw 0
    retlw 1

GetChan1:
    btfss Result,7
    retlw 0
;
    btfsc PORTC,0
    retlw 0
    retlw 1
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; InputBit
;
;   W   bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InputBit:
    call Delay
    call GetInput
    movwf LowTemp3
;    
    bcf PORTB,2
    call Delay
;
    bsf PORTB,2
    call Delay
;
    movf LowTemp3,W
    return
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CheckLineStatus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckLineStatus:
    btfsc PORTB,0
    bcf Result,6    
;    
    btfsc PORTC,0
    bcf Result,7
;
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Preamp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Preamp:
    call Delay
    movlw 14
    movwf Count

PreampLoop:
    movlw 1
    call OutputBit
    decf Count,F
    btfss STATUS,Z
    goto PreampLoop
;
    movlw 0
    call OutputBit
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateCrc
;
;   W       value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateCrc:	
    andlw 1
	movwf LowTemp1
	clrf LowTemp2
	bcf STATUS,C
	rlf Crc,F
	rlf LowTemp2,W
	xorwf LowTemp1,W
	btfsc STATUS,Z
	return

	movlw 0x26
	xorwf Crc,F
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Output6
;
;   W       value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Output6:
    movwf Val
    clrf Crc
;
    movlw 6
    movwf Count

OutDataLoop6:
    movf Val,W
    call OutputBit
;    
    movf Val,W
    call UpdateCrc
;    
    rrf Val,F
    decf Count,F
    btfss STATUS,Z
    goto OutDataLoop6
;
    movlw 0
    call OutputBit
;
    movlw 6
    movwf Count

OutCrcLoop6:
    movf Crc,W
    call OutputBit
;    
    rrf Crc,F
    decf Count,F
    btfss STATUS,Z
    goto OutCrcLoop6
;
    movlw 0
    call OutputBit
;    
    call Delay
    return
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Dummy
;
;   INDF        Data values
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Dummy:
    clrf Result
    return
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Read24
;
;   INDF        Data values
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Read24:
    movlw DataList
    movwf FSR
;
    clrf Crc
    movlw 4
    movwf CmdLen

InByteLoop24:
    movlw 6
    movwf Count

InDataLoop24:
    call InputBit
    movwf Val
    call UpdateCrc
;
    rrf Val,F
    rrf Val,F
    rrf Val,W
    andlw 0x40
    iorwf INDF,F
    rrf INDF,F    
;    
    decf Count,F
    btfss STATUS,Z
    goto InDataLoop24
;
    movlw 0x3F
    andwf INDF,F
    incf FSR,F
;    
    incf Result,F
    decf CmdLen,F
    btfss STATUS,Z
    goto InByteLoop24
;
    movlw 0xA5
    xorwf Crc,F
    movlw 8
    movwf Count

InCrcLoop24:
    call InputBit
    movwf Val
;
    bsf STATUS,C
;    
    btfss Val,0
    bcf STATUS,C
;    
    rrf INDF,F    
;    
    decf Count,F
    btfss STATUS,Z
    goto InCrcLoop24
;
    movf INDF,W
    xorwf Crc,W
    btfss STATUS,Z
    bsf Result,5    
    return
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Write24
;
;   INDF        Data values
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Write24:
    clrf Crc
    movlw 4
    movwf CmdLen

OutByteLoop24:
    movf INDF,W
    movwf Val
    incf FSR,F
;    
    movlw 6
    movwf Count

OutDataLoop24:
    movf Val,W
    call OutputBit
;
    movf Val,W
    call UpdateCrc
;    
    rrf Val,F
    decf Count,F
    btfss STATUS,Z
    goto OutDataLoop24
;
    movlw 0
    call OutputBit
;    
    call Delay
;    
    decf CmdLen,F
    btfsc STATUS,Z
    goto OutCrc24
;
    call CheckLineStatus
;
    movf Result,W
    btfsc STATUS,Z
    return
;
    goto OutByteLoop24
    
OutCrc24:
    movf Crc,W
;
    movlw 6
    movwf Count

OutCrcLoop24:
    movf Crc,W
    call OutputBit
;    
    rrf Crc,F
    decf Count,F
    btfss STATUS,Z
    goto OutCrcLoop24
;
    movlw 0
    call OutputBit    
    call Delay
;
    movlw 0
    call OutputBit
    call Delay
;
    return

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ToggleLine
;
;   INDF        Data values
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ToggleLine:
    return
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadLine
;
;   INDF        Data values
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadLine:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSerial
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
HandleSerial:
    movlw CmdList
    movwf FSR    
;
    movf INDF,W
    andlw 0xC0
    movwf Result
;
    btfsc Result,6
	bcf PORTB,1
;
    btfsc Result,7
	bcf PORTC,1
;
    call Preamp
;        
    movf INDF,W
    incf FSR,F
    call Output6
    call Delay
;
    call CheckLineStatus
    movf Result,W
    btfsc STATUS,Z
    goto HandleDone
;
    movf INDF,W
    movwf Cmd
    incf FSR,F
    call Output6
    call Delay
;    
    call HandleCmd

HandleDone:
	bsf PORTB,1
	bsf PORTC,1
    return

    end
