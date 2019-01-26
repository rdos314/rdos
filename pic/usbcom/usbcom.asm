#include p16f1459.inc   

#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5

; Flag bits

FLAG_CMD_AVAIL_BIT:	    EQU 0


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

	goto ProgStart

	org 0x4


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Interupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Intr:	
    retfie
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code starts here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code ends here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ProgStart:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Delay
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delay:
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
    bcf PORTA,2
    call Delay
;
    bsf PORTA,2
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
    btfsc PORTA,0
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
    bcf PORTA,2
    call Delay
;
    bsf PORTA,2
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
    btfsc PORTA,0
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
    movwf FSR0
;
    clrf Crc
    movlw 4
    movwf CmdLen

InByteLoop24:
    movlw 6
    movwf Count
    clrf INDF0

InDataLoop24:
    call InputBit
    movwf Val
    call UpdateCrc
;
    rrf Val,F
    rrf Val,F
    rrf Val,W
    andlw 0x40
    iorwf INDF0,F
    rrf INDF0,F    
;    
    decf Count,F
    btfss STATUS,Z
    goto InDataLoop24
;
    movlw 0x3F
    andwf INDF0,F
    incf FSR0,F
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
    rrf INDF0,F    
;    
    decf Count,F
    btfss STATUS,Z
    goto InCrcLoop24
;
    movf INDF0,W
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
    movf INDF0,W
    movwf Val
    incf FSR0,F
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
    movwf FSR0
;    
    clrf Crc
    clrf INDF0
;    
    movlw 8
    movwf Count

ReadLineLoop:
    call InputBit
    movwf Val
    call UpdateCrc
;
    rrf Val,W
    rrf INDF0,F
;    
    decf Count,F
    btfss STATUS,Z
    goto ReadLineLoop
;
    incf FSR0,F
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
    rrf INDF0,F    
;    
    decf Count,F
    btfss STATUS,Z
    goto ReadLineCrcLoop
;
    movf INDF0,W
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
    movf INDF0,W
    andlw 0xC0
    movwf Result
;
    btfsc Result,6
	bcf PORTC,1
;
    btfsc Result,7
	bcf PORTA,1
;
    call Preamp
;        
    movf INDF0,W
    incf FSR0,F
    call Output6
    call Delay
;
    call CheckLineStatus
    movf Result,W
    btfsc STATUS,Z
    goto ExecSerialDone
;
	bcf PORTA,4
    movf INDF0,W
    movwf Cmd
    incf FSR0,F
    call Output6
    call Delay
;    
;    call ExecuteSerialCmd

ExecSerialDone:
	bsf PORTA,1
	bsf PORTC,1
    return

    end
