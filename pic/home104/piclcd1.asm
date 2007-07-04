
#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5

INDF:	EQU 0
PCL:    EQU 2
STATUS: EQU 3
FSR:	EQU 4
PORTA:  EQU 5
PORTB:  EQU 6
PORTC:	EQU 7
PORTD:	EQU 8
PORTE:	EQU 9
TRISA:  EQU 5
TRISB:  EQU 6
TRISC:	EQU 7
TRISD:	EQU 8
TRISE:	EQU 9

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
