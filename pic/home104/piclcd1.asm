
#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5

INDF:	EQU 0
PCL:    EQU 2
STATUS: EQU 3
FSR:	EQU 4
PORTA:  EQU 5
PORTB:  EQU 6
TRISA:  EQU 5
TRISB:  EQU 6

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
			PAGE0
			clrf PORTA

Stop:       goto Stop

    end
