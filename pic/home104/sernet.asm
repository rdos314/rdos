;SERNET.ASM

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
TEMP:   .EQU $13
BITS:   .EQU $14
CMD:    .EQU $15
CMDLEN: .EQU $16
LINE:   .EQU $17

; RA0 = gen int (0)
; RA1 = packet in (1)
; RA2 = ack packet (1)
; RA3 = clear shift (0)
; RA4 = packet int (1)

; RB0 = clk in
; RB1 = data in/out (1/0)
; RB2 = data out control 0
; RB3 = data out control 1
; RB4 = data in
; RB5 = SRCK
; RB6 = RCK
; RB7 = load (0)


    .ORG 4
    .ORG 5

RESET:		
    PAGE1
    movlw $12
	movwf TRISA
;
	movlw $11
	movwf TRISB
;
    movlw $D7
    movwf OPT
;			
    PAGE0
    clrf PORTA
;
    movlw $8E
    movwf PORTB			    
;
    movlw $0D
    movwf PORTA

Wait:
    call Delay
    bsf PORTB,1
    call Delay
    bcf PORTB,1
;    
    bcf PORTA,0
    bsf PORTA,0    

WaitReq:   
    btfss PORTA,4
    goto WaitReq

AckLoop:
    bcf PORTA,2
    bsf PORTA,2
    btfsc PORTA,4
    goto AckLoop
;    
    goto Wait

;;;;;;;;;;
; Delay
;;;;;;;;;;

Delay:
    movlw 255
    movwf DELCNT

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

        .END

