#include p16f877a.inc   

	__config 0x3FFA

#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5

	org 0

	goto Reset

	org 0x5

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
	bcf PORTA, 3

	PAGE1
WaitWrite:
	btfss TRISE,IBF
	goto WaitWrite
;
	PAGE0
	bcf PORTA, 0
	bsf PORTA, 3
;
	movf PORTD,W
	addlw 0x11
	movwf PORTD

	PAGE1

WaitRead:
	btfsc TRISE,OBF
	goto WaitRead
;
	PAGE0

	bsf PORTA, 0

	bcf PORTA,3	
	
	PAGE1
	goto WaitWrite

    end
