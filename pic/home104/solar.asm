#include p16f873a.inc   

#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5


; Page 0

; page 2

; page 3

	org 0

	goto Reset

	org 0x4

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code starts here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code ends here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


Reset:
	PAGE1
	movlw b'1000100'
	movwf ADCON1
;
	movlw b'11111111'
	movwf TRISA
;
	movlw b'11111111'
	movwf TRISB
;
	movlw b'11110000'
	movwf TRISC
;
	PAGE0
;
	movlw b'00000000'
	movwf PORTA
;
	movlw b'00000000'
	movwf PORTB
;
	movlw b'00001110'
	movwf PORTC
;
    movlw 1
    movwf T1CON
;
    PAGE1
;
    movlw b'11011000'
    movwf OPTION_REG
;
    PAGE0
;    
    movlw b'00000000'
    movwf INTCON      

HandleLoop:
    goto HandleLoop

    end
