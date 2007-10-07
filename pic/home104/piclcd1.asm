#include p16f877a.inc   

	__config 0x3FFA

#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5

; Flag bits

FLAG_CMD_AVAIL_BIT:	    EQU 0
FLAG_DATA_AVAIL_BIT:    EQU 1


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

InPtr:      EQU 0x29
OutPtr:     EQU 0x2A

OutCount:   EQU 0x2B

Flags:      EQU 0x2C

AdcCount:   EQU 0x2E
AdcControl: EQU 0x2F


; common area

IntW:       EQU 0x70
IntStatus:  EQU 0x71
IntFSR:     EQU 0x72
IntTemp:    EQU 0x73

; page 2, datalist

DataList:   EQU 0x110

; page 3, cmdlist

CmdList:    EQU 0x190

	org 0

	goto Reset

	org 0x4


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Interupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Intr:	
    movwf IntW
    swapf STATUS,W
    movwf IntStatus
    movf FSR,W
    movwf IntFSR
;
;    btfss PIR1,PSPIF
;    goto IntrNotPSP

IntrPspInLoop:
    bsf STATUS,IRP
    PAGE1
    btfss TRISE,IBF
    goto IntrNoPspIn

    PAGE0
;    
    movf PORTD,W
    movwf IntTemp
;
    btfsc Flags,FLAG_CMD_AVAIL_BIT    
    goto IntrNoPspIn
;
    incf IntTemp,W
    btfss STATUS,Z
    goto IntrPspInMore
;    
    bsf Flags,FLAG_CMD_AVAIL_BIT
    bcf Flags,FLAG_DATA_AVAIL_BIT
;    
    movlw CmdList
    movwf InPtr    
    goto IntrNoPspIn    

IntrPspInMore:
    movf InPtr,W
    movwf FSR
;
    movf IntTemp,W    
    movwf INDF
;
    incf InPtr,F    
    goto IntrPspInLoop

IntrNoPspIn:
    PAGE0
;    
    btfss Flags,FLAG_DATA_AVAIL_BIT
	goto IntrNoPspOut
;
    PAGE1
    btfsc TRISE,OBF
    goto IntrNoPspOut
;
    PAGE0
    movf OutPtr,W
    movwf FSR
;
    movf INDF,W
    movwf PORTD
    incf OutPtr,F
;
    decfsz OutCount,F
    goto IntrNoPspIn
;
    bcf Flags,FLAG_DATA_AVAIL_BIT
    movlw DataList
    movwf OutPtr

IntrNoPspOut:
    PAGE0
    bcf PIR1,PSPIF
    
IntrNotPSP:
    movf IntFSR,W
    movwf FSR
    swapf IntStatus,W
    movwf STATUS
    swapf IntW,F
    swapf IntW,W    
    retfie
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code starts here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetAdcControl
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
GetAdcControl:
    rrf Cmd,F
    rrf Cmd,F
    rrf Cmd,W
    andlw 3
	addwf PCL,F
    retlw b'10001000'   ; chan 0
    retlw b'10011000'   ; chan 1
    retlw b'10101000'   ; chan 2
    retlw b'10111000'   ; chan 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ExecuteSerialCmd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
ExecuteSerialCmd:
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ExecuteCmd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
ExecuteCmd:
    movlw CmdList
    movwf FSR    
;
    btfsc INDF,7
    goto ExecuteNormal
;
    btfss INDF,6
    goto ExecuteAdc

ExecuteNormal:    
    movf INDF,W
    andlw 0xC0
    btfss STATUS,Z
    goto ExecuteSerial
;
    movf INDF,W
    movwf LowTemp1
    rrf LowTemp1,F
    rrf LowTemp1,F
    rrf LowTemp1,W
    andlw 7
	addwf PCL,F
	goto Dummy          ; 0
	goto ReadData       ; 1
 	goto Dummy          ; 2
	goto Dummy          ; 3
	goto Dummy          ; 4
	goto Dummy          ; 5
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
	movlw b'01101110'
	movwf PORTC
;
    movlw 1
    movwf T1CON
;
    PAGE1
    movlw 0x80
    movwf PIE1
    movlw 0
    movwf PIE2
    PAGE0
;    
    movlw 0xC0
    movwf INTCON      
;
    clrf Flags
    movlw CmdList
    movwf InPtr
    movlw DataList
    movwf OutPtr
;    
    bsf STATUS,IRP
    
HandleLoop:
	bsf PORTA, 3
	bsf PORTA, 4
	bsf PORTA, 5
    bcf Flags,FLAG_CMD_AVAIL_BIT

WaitCmdLoop:
    btfss Flags,FLAG_CMD_AVAIL_BIT
    goto WaitCmdLoop
;
    call ExecuteCmd
;
    movf Result,W
    andlw 0xF
    movwf OutCount
;
    btfss STATUS,Z
    bsf Flags,FLAG_DATA_AVAIL_BIT
;
    movf Result,W
    call SendInt
    goto HandleLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Delay
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delay:
    movlw 2
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
; AdcDelay
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AdcDelay:
    movlw 0x10
    movwf LowTemp1

AdcDelayLoop:
    decf LowTemp1,F
    btfss STATUS,Z
    goto AdcDelayLoop
;
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
; ReadData
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
ReadData:
    movf INDF,W
    andlw 7
    addlw DataList
    movwf FSR
;
    movf INDF,W
    movwf PORTD
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
    btfsc PORTC,0
    retlw 0
    retlw 1

GetChan1:
    btfss Result,7
    retlw 0
;
    btfsc PORTB,0
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
    btfsc PORTC,0
    bcf Result,6    
;    
    btfsc PORTB,0
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
    clrf INDF

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
    clrf Result
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
    movlw DataList
    movwf FSR
;    
    clrf Crc
    clrf INDF
;    
    movlw 8
    movwf Count

ReadLineLoop:
    call InputBit
    movwf Val
    call UpdateCrc
;
    rrf Val,W
    rrf INDF,F
;    
    decf Count,F
    btfss STATUS,Z
    goto ReadLineLoop
;
    incf FSR,F
    incf Result,F
;    
    movlw 0x5A
    xorwf Crc,F
    movlw 8
    movwf Count

ReadLineCrcLoop:
    call InputBit
    movwf Val
;
    bsf STATUS,C
;    
    btfss Val,0
    bcf STATUS,C
    rrf INDF,F    
;    
    decf Count,F
    btfss STATUS,Z
    goto ReadLineCrcLoop
;
    movf INDF,W
    xorwf Crc,W
    btfss STATUS,Z    
    clrf Result
    return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ExecuteSerial
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExecuteSerial:
  	bcf PORTA, 3
;  	
    movf INDF,W
    andlw 0xC0
    movwf Result
;
    btfsc Result,6
	bcf PORTC,1
;
    btfsc Result,7
	bcf PORTB,1
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
    goto ExecSerialDone
;
	bcf PORTA,4
    movf INDF,W
    movwf Cmd
    incf FSR,F
    call Output6
    call Delay
;    
    call ExecuteSerialCmd

ExecSerialDone:
	bsf PORTB,1
	bsf PORTC,1
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ExecuteAdc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExecuteAdc:
  	bcf PORTA, 5
;  	
    movf INDF,W
    andlw 0xC0
    movwf Result
;    
    incf FSR,F
    movf INDF,W
    movwf Cmd
;
    call GetAdcControl
    movwf AdcControl
;
    movlw 7
    movwf AdcCount
;
; CS = RC6
; DOUT = RC5
; CLK = RC3
; DIN = RC4
;
    bsf PORTC,3
    bsf PORTC,5
    bcf PORTC,6       
    call AdcDelay

AdcControlLoop:
    bcf PORTC,3
;    
    btfss AdcControl,7
    goto AdcResetControlBit
    
AdcSetControlBit:
    bsf PORTC,5
    goto AdcNextControlBit

AdcResetControlBit:
    bcf PORTC,5
        
AdcNextControlBit:
    rlf AdcControl,F
    call AdcDelay
;        
    bsf PORTC,3
    call AdcDelay    
;
    decfsz AdcCount,F
    goto AdcControlLoop
;    
    bcf PORTC,3
    call AdcDelay
;    
    movlw DataList
	addlw 1
    movwf FSR   
;
    clrf INDF
    movlw 6
    movwf AdcCount 

AdcMsbLoop:
    bsf PORTC,3
    call AdcDelay
;
    bcf STATUS,C
    rlf INDF,F  
;
    btfsc PORTC,4
    bsf INDF,0 
;
    bcf PORTC,3
    call AdcDelay
;
    decfsz AdcCount,F
    goto AdcMsbLoop 
;
    decf FSR,F
    clrf INDF
    movlw 6
    movwf AdcCount 

AdcLsbLoop:
    bsf PORTC,3
    call AdcDelay
;
    bcf STATUS,C
    rlf INDF,F  
;
    btfsc PORTC,4
    bsf INDF,0 
;
    bcf PORTC,3
    call AdcDelay
;
    decfsz AdcCount,F
    goto AdcLsbLoop 
;
    bsf PORTC,6
    bsf PORTC,3
    bsf PORTC,5
    call AdcDelay
;
    movlw 0xC2    
    movwf Result
;    
    return

    end
