#include p16f877a.inc   

	__config 0x3FFA

#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5

	org 0

	goto Reset

	org 0x5

W:      EQU 0          ;Working
F:      EQU 1          ;File
C:      EQU 0          ;Carry
Z:      EQU 2          ;Zero

Reset:	    PAGE1
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

			bcf PORTA, 3

Stop:       goto Stop

    end
