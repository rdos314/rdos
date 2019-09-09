#include p18f4550.inc   

  config PLLDIV=3,  CPUDIV = OSC2_PLL3, USBDIV = 2, FOSC = HSPLL_HS, FCMEN = OFF, IESO = OFF, PWRT = ON
  config BOR = ON, BORV = 3, VREGEN = OFF, WDT = OFF, WDTPS = 32768, CCP2MX = OFF, PBADEN = ON, LPT1OSC = ON
  config MCLRE = OFF, STVREN = ON
  config LVP = OFF, ICPRT = OFF,  XINST = OFF
  config CP0=OFF, CP1=OFF, CP2=OFF, CP3=OFF, CPB=OFF, CPD=OFF
  config WRT0=OFF, WRT1=OFF, WRT2=OFF, WRT3=OFF, WRTC=OFF, WRTB=OFF, WRTD=OFF
  config EBTR0=OFF, EBTR1=OFF, EBTR2=OFF, EBTR3=OFF, EBTRB=OFF

SER_COM_SIZE       equ 0x78
SER_USB_SIZE       equ 0x40

EP0                equ 0
EP1                equ 8
EP2                equ 0x10

ser_ram            equ 0x100
ser_buf_page       equ 1

rx_count           equ 0x100
rx_in_pos          equ 0x101
rx_out_pos         equ 0x102

tx_count           equ 0x103
tx_in_pos          equ 0x104
tx_out_pos         equ 0x105

ser_curr_count     equ 0x106
ser_rem_count      equ 0x107
ser_temp           equ 0x108

rx_buf             equ 0x110
tx_buf             equ 0x188

usb_ram            equ 0x200

usb_buf_page       equ 4

control_out_stat   equ 0x400
control_out_size   equ 0x401
control_out_low    equ 0x402
control_out_high   equ 0x403

control_in_stat    equ 0x404
control_in_size    equ 0x405
control_in_low     equ 0x406
control_in_high    equ 0x407

ser_out_stat       equ 0x408
ser_out_size       equ 0x409
ser_out_low        equ 0x40A
ser_out_high       equ 0x40B

ser_in_stat        equ 0x40C
ser_in_size        equ 0x40D
ser_in_low         equ 0x40E
ser_in_high        equ 0x40F

bus_out_stat       equ 0x410
bus_out_size       equ 0x411
bus_out_low        equ 0x412
bus_out_high       equ 0x413

bus_in_stat        equ 0x414
bus_in_size        equ 0x415
bus_in_low         equ 0x416
bus_in_high        equ 0x417

usb_cout           equ 0x420
usb_cin            equ 0x428

usb_ser_out        equ 0x430
usb_ser_in         equ 0x470

usb_bus_out        equ 0x4F0
usb_bus_in         equ 0x4F8

;
; io structure
;

io_page            equ 5

io_id              equ 0
io_state           equ 1
io_adr             equ 2
io_cmd             equ 3
io_d0              equ 4
io_d1              equ 5
io_d2              equ 6
io_d3              equ 7

io_id0             equ 0x500
io_state0          equ 0x501
io_adr0            equ 0x502
io_cmd0            equ 0x503
io_v00             equ 0x504               
io_v10             equ 0x505               
io_v20             equ 0x506               
io_v30             equ 0x507               

io_val0            equ 0x508
io_crc0            equ 0x509

io_id1             equ 0x510
io_state1          equ 0x511
io_adr1            equ 0x512
io_cmd1            equ 0x513
io_v01             equ 0x514               
io_v11             equ 0x515               
io_v21             equ 0x516               
io_v31             equ 0x517
               
io_val1            equ 0x518
io_crc1            equ 0x519

io_id2             equ 0x520
io_state2          equ 0x521
io_adr2            equ 0x522
io_cmd2            equ 0x523
io_v02             equ 0x524               
io_v12             equ 0x525               
io_v22             equ 0x526               
io_v32             equ 0x527
               
io_val2            equ 0x528
io_crc2            equ 0x529

io_id3             equ 0x530
io_state3          equ 0x531
io_adr3            equ 0x532
io_cmd3            equ 0x533
io_v03             equ 0x534               
io_v13             equ 0x535               
io_v23             equ 0x536               
io_v33             equ 0x537               

io_val3            equ 0x538
io_crc3            equ 0x539

io_chans           equ 0x540
io_init_chans      equ 0x541
io_temp1           equ 0x542
io_temp2           equ 0x543
io_count           equ 0x544
io_curr_chan       equ 0x545
io_val             equ 0x546
io_crc             equ 0x547
io_base            equ 0x548
io_curr_id         equ 0x549

;
; io buffers
;

io_buf_page        equ 6

io_buf_base        equ 0x600

;
; address mapping
;

io_adr_page        equ 7

io_adr_base        equ 0x700

SER_STATE_ACTIVE   equ 0
SER_STATE_ODD      equ 1
SER_STATE_EVEN     equ 2
SER_STATE_PAR9     equ 3
SER_STATE_IN_BUSY  equ 4
SER_STATE_OUT_BUSY equ 5

BUS_STATE_IN_BUSY  equ 0
BUS_STATE_OUT_BUSY equ 1
BUS_STATE_REQ      equ 2
BUS_STATE_REPLY    equ 3
BUS_STATE_ALL      equ 4

DESCR_FLAG_MORE    equ 0
USB_HANDLED        equ 1
DESCR_FLAG_FULL    equ 2

SET_ADDRESS        equ 5
GET_DESCRIPTOR     equ 6
SET_CONFIGURATION  equ 9

SET_BAUD           equ 1
SET_DATA_BITS      equ 2
SET_PARITY         equ 3
START_SERIAL       equ 4
STOP_SERIAL        equ 5

    org 0

    goto ProgStart

w_isr         equ 0x60
status_isr    equ 0x61
bsr_isr       equ 0x62

counter_ms    equ 0x63
counter_ds    equ 0x64

temp1         equ 0x65
temp2         equ 0x66
temp3         equ 0x67

d_curr_stat   equ 0x68
d_curr_count  equ 0x69
d_curr_low    equ 0x6A
d_curr_high   equ 0x6B

b_req_type    equ 0x6C
b_req         equ 0x6D
b_val_low     equ 0x6E
b_val_high    equ 0x6F
b_index_low   equ 0x70
b_index_high  equ 0x71
b_len_low     equ 0x72
b_len_high    equ 0x73

remain_size   equ 0x74
count         equ 0x75
usb_flags     equ 0x76
usb_stat      equ 0x77
usb_ep        equ 0x78
usb_adr       equ 0x79

ser_state     equ 0x7A
counter_dms   equ 0x7B
ser_mask      equ 0x7C
parity        equ 0x7D

bus_state     equ 0x7E

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Case
;
;  W   table entry #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Case:
   rlncf WREG,F
   rlncf WREG,F
   addwf TOSL,F
   movlw 0
   addwfc TOSH,F
   addwfc TOSU,F
   return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteOutput0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteOutput0:
    btfss io_val0,0
    goto WriteOutClear0

WriteOutSet0:
    bcf LATB,1
    return

WriteOutClear0:
    bsf LATB,1
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteOutput1
;
;   W   bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteOutput1:
    btfss io_val1,0
    goto WriteOutClear1

WriteOutSet1:
    bcf LATB,3
    return

WriteOutClear1:
    bsf LATB,3
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteOutput2
;
;   W   bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteOutput2:
    btfss io_val2,0
    goto WriteOutClear2

WriteOutSet2:
    bcf LATD,1
    return

WriteOutClear2:
    bsf LATD,1
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteOutput3
;
;   W   bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteOutput3:
    btfss io_val3,0
    goto WriteOutClear3

WriteOutSet3:
    bcf LATD,3
    return

WriteOutClear3:
    bsf LATD,3
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteComOutput0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteComOutput0:
    btfss io_val,0
    goto WriteComOutClear0

WriteComOutSet0:
    bcf LATB,1
    return

WriteComOutClear0:
    bsf LATB,1
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteComOutput1
;
;   W   bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteComOutput1:
    btfss io_val,0
    goto WriteComOutClear1

WriteComOutSet1:
    bcf LATB,3
    return

WriteComOutClear1:
    bsf LATB,3
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteComOutput2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteComOutput2:
    btfss io_val,0
    goto WriteComOutClear2

WriteComOutSet2:
    bcf LATD,1
    return

WriteComOutClear2:
    bsf LATD,1
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteComOutput3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteComOutput3:
    btfss io_val,0
    goto WriteComOutClear3

WriteComOutSet3:
    bcf LATD,3
    return

WriteComOutClear3:
    bsf LATD,3
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteCurr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCurr:
    movf io_curr_chan, W
    andlw 3
    call Case
    goto WriteComOutput0
    goto WriteComOutput1
    goto WriteComOutput2
    goto WriteComOutput3
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadComInput0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadComInput0:
    bcf io_val,0
    btfss PORTD,4
    bsf io_val,0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadComInput1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadComInput1:
    bcf io_val,0
    btfss PORTD,5
    bsf io_val,0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadComInput2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadComInput2:
    bcf io_val,0
    btfss PORTD,6
    bsf io_val,0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadComInput3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadComInput3:
    bcf io_val,0
    btfss PORTD,7
    bsf io_val,0
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CheckInput0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckInput0:
    btfsc PORTD,4
    bcf io_chans,0
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CheckInput1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckInput1:
    btfsc PORTD,5
    bcf io_chans,1
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CheckInput2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckInput2:
    btfsc PORTD,6
    bcf io_chans,2
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CheckInput3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckInput3:
    btfsc PORTD,7
    bcf io_chans,3
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetClkActive0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetClkActive0:
    bcf LATB,0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetClkInactive0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetClkInactive0:
    bsf LATB,0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetClkActive1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetClkActive1:
    bcf LATB,2
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetClkInactive1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetClkInactive1:
    bsf LATB,2
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetClkActive2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetClkActive2:
    bcf LATD,0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetClkInactive2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetClkInactive2:
    bsf LATD,0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetClkActive3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetClkActive3:
    bcf LATD,2
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetClkInactive3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetClkInactive3:
    bsf LATD,2
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateCrc0
;
;   W       value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateCrc0:	
    andlw 1
    movwf io_temp1
    clrf io_temp2
    bcf STATUS, C
    rlcf io_crc0,F
    rlcf io_temp2,W
    xorwf io_temp1,W
    btfsc STATUS, Z
    return
;
    movlw 0x26
    xorwf io_crc0,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateCrc1
;
;   W       value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateCrc1:	
    andlw 1
    movwf io_temp1
    clrf io_temp2
    bcf STATUS, C
    rlcf io_crc1,F
    rlcf io_temp2,W
    xorwf io_temp1,W
    btfsc STATUS, Z
    return
;
    movlw 0x26
    xorwf io_crc1,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateCrc2
;
;   W       value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateCrc2:	
    andlw 1
    movwf io_temp1
    clrf io_temp2
    bcf STATUS, C
    rlcf io_crc2,F
    rlcf io_temp2,W
    xorwf io_temp1,W
    btfsc STATUS, Z
    return
;
    movlw 0x26
    xorwf io_crc2,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateCrc3
;
;   W       value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateCrc3:	
    andlw 1
    movwf io_temp1
    clrf io_temp2
    bcf STATUS, C
    rlcf io_crc3,F
    rlcf io_temp2,W
    xorwf io_temp1,W
    btfsc STATUS, Z
    return
;
    movlw 0x26
    xorwf io_crc3,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; OutputBit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputBit:
    movlb io_page
;
    btfsc io_chans,0
    call WriteOutput0
;
    btfsc io_chans,1
    call WriteOutput1
;
    btfsc io_chans,2
    call WriteOutput2
;
    btfsc io_chans,3
    call WriteOutput3
;
    call Delay
    movlb io_page
;
    btfsc io_chans,0
    call SetClkActive0
;
    btfsc io_chans,1
    call SetClkActive1
;
    btfsc io_chans,2
    call SetClkActive2
;
    btfsc io_chans,3
    call SetClkActive3
;
    call Delay
    movlb io_page
;
    call SetClkInactive0
    call SetClkInactive1
    call SetClkInactive2
    call SetClkInactive3
;
    call Delay
    movlb io_page
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateCrc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateCrc:
    movlb io_page
;
    movf io_val0,W
    call UpdateCrc0
;
    movf io_val1,W
    call UpdateCrc1
;
    movf io_val2,W
    call UpdateCrc2
;
    movf io_val3,W
    call UpdateCrc3
;
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; OutputActive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputActive:
    clrf io_val0
    clrf io_val1
    clrf io_val2
    clrf io_val3
    call OutputBit
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; OutputCrc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputCrc:
    movf io_crc0,W
    movwf io_val0
;
    movf io_crc1,W
    movwf io_val1
;
    movf io_crc2,W
    movwf io_val2
;
    movf io_crc3,W
    movwf io_val3
;
    movlw 6
    movwf io_count

OutCrcLoop:
    call OutputBit
;
    rrncf io_val0,F
    rrncf io_val1,F
    rrncf io_val2,F
    rrncf io_val3,F
;
    decf io_count,F
    btfss STATUS,Z
    goto OutCrcLoop
;
    call OutputActive
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateLine
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLine:
    btfsc io_chans,0
    call CheckInput0
;
    btfsc io_chans,1
    call CheckInput1
;
    btfsc io_chans,2
    call CheckInput2
;
    btfsc io_chans,3
    call CheckInput3
;
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteCom0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCom0:
    movlb io_page
;
    call WriteComOutput0
;
    call Delay
    movlb io_page
;
    call SetClkActive0
;
    call Delay
    movlb io_page
;
    call SetClkInactive0
;
    call Delay
    movlb io_page
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteCom1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCom1:
    movlb io_page
;
    call WriteComOutput1
;
    call Delay
    movlb io_page
;
    call SetClkActive1
;
    call Delay
    movlb io_page
;
    call SetClkInactive1
;
    call Delay
    movlb io_page
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteCom2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCom2:
    movlb io_page
;
    call WriteComOutput2
;
    call Delay
    movlb io_page
;
    call SetClkActive2
;
    call Delay
    movlb io_page
;
    call SetClkInactive2
;
    call Delay
    movlb io_page
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteCom3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCom3:
    movlb io_page
;
    call WriteComOutput3
;
    call Delay
    movlb io_page
;
    call SetClkActive3
;
    call Delay
    movlb io_page
;
    call SetClkInactive3
;
    call Delay
    movlb io_page
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; OutputCurrBit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputCurrBit:
    movf io_curr_chan, W
    andlw 3
    call Case
    goto WriteCom0
    goto WriteCom1
    goto WriteCom2
    goto WriteCom3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadCom0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCom0:
    call Delay
    movlb io_page
;
    call ReadComInput0
    call SetClkActive0
;
    call Delay
    movlb io_page
;
    call SetClkInactive0
;
    call Delay
    movlb io_page
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadCom1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCom1:
    call Delay
    movlb io_page
;
    call ReadComInput1
    call SetClkActive1
;
    call Delay
    movlb io_page
;
    call SetClkInactive1
;
    call Delay
    movlb io_page
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadCom2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCom2:
    call Delay
    movlb io_page
;
    call ReadComInput2
    call SetClkActive2
;
    call Delay
    movlb io_page
;
    call SetClkInactive2
;
    call Delay
    movlb io_page
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadCom3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCom3:
    call Delay
    movlb io_page
;
    call ReadComInput3
    call SetClkActive3
;
    call Delay
    movlb io_page
;
    call SetClkInactive3
;
    call Delay
    movlb io_page
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; InputCurrBit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InputCurrBit:
    movf io_curr_chan, W
    andlw 3
    call Case
    goto ReadCom0
    goto ReadCom1
    goto ReadCom2
    goto ReadCom3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateComCrc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateComCrc:
    movf io_val,W	
    andlw 1
    movwf io_temp1
    clrf io_temp2
    bcf STATUS, C
    rlcf io_crc,F
    rlcf io_temp2,W
    xorwf io_temp1,W
    btfsc STATUS, Z
    return
;
    movlw 0x26
    xorwf io_crc,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Activate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Activate:
    movlb io_page
    btfsc io_chans,0
    goto Active01
;
    btfss io_chans,1
    goto ActiveCheck23

Active01:
    bcf LATE,0

ActiveCheck23:
    btfsc io_chans,2
    goto Active23
;
    btfss io_chans,3
    return

Active23:
    bcf LATE,1
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Deactivate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Deactivate:
    bsf LATE,0
    bsf LATE,1
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Preamp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Preamp:
    call Delay
;
    movlb io_page
    movlw 14
    movwf io_count
;
    movlw 1
    movwf io_val0
    movwf io_val1
    movwf io_val2
    movwf io_val3

PreampLoop:
    call OutputBit
;
    decf io_count,F
    btfss STATUS,Z
    goto PreampLoop
;
    call OutputActive
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; OutputAdr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputAdr:
    movlb io_page
;
    movf io_adr0,W
    movwf io_val0
;
    movf io_adr1,W
    movwf io_val1
;
    movf io_adr2,W
    movwf io_val2
;
    movf io_adr3,W
    movwf io_val3
;
    clrf io_crc0
    clrf io_crc1
    clrf io_crc2
    clrf io_crc3
;
    movlw 6
    movwf io_count

OutAdrLoop:
    call OutputBit
    call UpdateCrc
;
    rrncf io_val0,F
    rrncf io_val1,F
    rrncf io_val2,F
    rrncf io_val3,F
;
    decf io_count,F
    btfss STATUS,Z
    goto OutAdrLoop
;
    call OutputActive
    call OutputCrc
    call UpdateLine
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; OutputCmd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutputCmd:
    movlb io_page
;
    movf io_cmd0,W
    movwf io_val0
;
    movf io_cmd1,W
    movwf io_val1
;
    movf io_cmd2,W
    movwf io_val2
;
    movf io_cmd3,W
    movwf io_val3
;
    clrf io_crc0
    clrf io_crc1
    clrf io_crc2
    clrf io_crc3
;
    movlw 6
    movwf io_count

OutCmdLoop:
    call OutputBit
    call UpdateCrc
;
    rrncf io_val0,F
    rrncf io_val1,F
    rrncf io_val2,F
    rrncf io_val3,F
;
    decf io_count,F
    btfss STATUS,Z
    goto OutCmdLoop
;
    call OutputActive
    call OutputCrc
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Read6
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Read6:
    movlb io_page
;
    clrf io_val
;
    movlw 6
    movwf io_count

ReadInnerLoop:
    call InputCurrBit
    call UpdateComCrc
;
    rrncf io_val,F
;
    decf io_count,F
    btfss STATUS,Z
    goto ReadInnerLoop
;
    rrncf io_val,F
    rrncf io_val,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadCrc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCrc:
    movlb io_page
;
    clrf io_val
;
    movlw 8
    movwf io_count

ReadCrcLoop:
    call InputCurrBit
;
    rrncf io_val,F
;
    decf io_count,F
    btfss STATUS,Z
    goto ReadCrcLoop
;
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Read24
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Read24:
    clrf io_crc
;
    call Read6
;
    movlw io_page
    movwf FSR2H
;
    movf io_base, W
    addlw io_d0
    movwf FSR2L
;
    movf io_val,W
    movwf INDF2
;
    call Read6
;
    movlw io_page
    movwf FSR2H
;
    movf io_base, W
    addlw io_d1
    movwf FSR2L
;
    movf io_val,W
    movwf INDF2
;
    call Read6
;
    movlw io_page
    movwf FSR2H
;
    movf io_base, W
    addlw io_d2
    movwf FSR2L
;
    movf io_val,W
    movwf INDF2
;
    call Read6
;
    movlw io_page
    movwf FSR2H
;
    movf io_base, W
    addlw io_d3
    movwf FSR2L
;
    movf io_val,W
    movwf INDF2
;
    call ReadCrc
;
    movlw 0xA5
    xorwf io_val,W
    xorwf io_crc,W
    btfss STATUS,Z
    return
;
    movf io_base, W
    addlw io_state
    movwf FSR2L
    clrf INDF2
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Write6
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Write6:
    movlb io_page
;
    movlw 6
    movwf io_count

WriteInnerLoop:
    call OutputBit
    call UpdateCrc
;
    rrncf io_val0,F
    rrncf io_val1,F
    rrncf io_val2,F
    rrncf io_val3,F
;
    decf io_count,F
    btfss STATUS,Z
    goto WriteInnerLoop
;
    call OutputActive
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Write24
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Write24:
    clrf io_crc
;
    movf io_v00,W
    movwf io_val0
;
    movf io_v01,W
    movwf io_val1
;
    movf io_v02,W
    movwf io_val2
;
    movf io_v03,W
    movwf io_val3
;
    call Write6
    call UpdateLine
;
    movf io_v10,W
    movwf io_val0
;
    movf io_v11,W
    movwf io_val1
;
    movf io_v12,W
    movwf io_val2
;
    movf io_v13,W
    movwf io_val3
;
    call Write6
    call UpdateLine
;
    movf io_v20,W
    movwf io_val0
;
    movf io_v21,W
    movwf io_val1
;
    movf io_v22,W
    movwf io_val2
;
    movf io_v23,W
    movwf io_val3
;
    call Write6
    call UpdateLine
;
    movf io_v30,W
    movwf io_val0
;
    movf io_v31,W
    movwf io_val1
;
    movf io_v32,W
    movwf io_val2
;
    movf io_v33,W
    movwf io_val3
;
    call Write6
;
    call OutputCrc
    call OutputActive
    call OutputActive
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; RunCmd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Run0:
Run1:
Run6:
Run7:
    return

ToggleLine:
    return

ReadLine:
    return

RunCmd:
    movlw io_page
    movwf FSR2H
;
    movf io_base, W
    addlw io_cmd
    movwf FSR2L
;
    movf INDF2,W
    andlw 7
    call Case
    goto Run0
    goto Run1
    goto Read24
    goto Write24
    goto ToggleLine
    goto ReadLine
    goto Run6
    goto Run7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; InitBus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitBus:
    movlb 0
    clrf bus_state
;
    clrf count
    lfsr 0,io_buf_base

InitBusReqLoop:
    clrf POSTINC0
    decfsz count,F
    goto InitBusReqLoop
;
    movlw 0x40
    movwf count
    lfsr 0,io_adr_base

InitBusAdsLoop:
    clrf POSTINC0
    decfsz count,F
    goto InitBusAdsLoop
;
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; AllocateBusReq
;
;   FSR0 = buffer start
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBusReq:
    movlb 0
    movlw 0x20
    movwf count
    lfsr 0,io_buf_base + io_cmd

AllocateBusReqLoop:
    movf INDF0,W
    btfsc STATUS,Z
    goto AllocateBusReqOk
;
    movlw 8
    addwf FSR0L,F
;
    decfsz count,F
    goto AllocateBusReqLoop
;
    bsf STATUS,C
    return

AllocateBusReqOk:
    movlw -io_cmd
    addwf FSR0L,F
;
    bcf STATUS,C
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetBusReq
;
;   FSR0 = buffer start
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBusReq:
    movlb 0
    movlw 0x20
    movwf count
    lfsr 0,io_buf_base + io_cmd

GetBusReqLoop:
    movf INDF0,W
    btfss STATUS,Z
    goto GetBusReqOk
;
    movlw 8
    addwf FSR0L,F
;
    decfsz count,F
    goto GetBusReqLoop
;
    bsf STATUS,C
    return

GetBusReqOk:
    movlw -io_cmd
    addwf FSR0L,F
;
    bcf STATUS,C
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; RemoveBusReq
;
; W = id
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveBusReq:
    movlb 0
    movwf temp1
;
    movlw 0x20
    movwf count
    lfsr 0,io_buf_base + io_cmd

RemoveBusReqLoop:
    movf INDF0,W
    btfsc STATUS,Z
    goto RemoveBusReqNext
;
    movlw -io_cmd
    addwf FSR0L,F
    movf INDF0,W
    cpfseq temp1
    goto RemoveBusReqNextMove

RemoveBusReqDo:
    movlw 8
    movwf count

RemoveBusReqDoLoop:
    clrf POSTINC0
    decfsz count,F
    goto RemoveBusReqDoLoop
;
    return

RemoveBusReqNextMove:        
    movlw -io_id
    addwf FSR0L,F

RemoveBusReqNext:
    movlw 8
    addwf FSR0L,F
;
    decfsz count,F
    goto RemoveBusReqLoop
;
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetReqChannel
;
;   FSR0 = buffer start
;
;   W = channel (00 = not assigned)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetReqChannel:
    movlw io_adr
    addwf FSR0L,F
;
    movf INDF0,W
    lfsr 1,io_adr_base
    addwf FSR1L,F
;
    movlw -io_adr
    addwf FSR0L,F
;
    movf INDF1,W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; LinkChannel
;
;   FSR0 = buffer start
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LinkChannel:
    movf FSR0L,W
    movwf io_temp1
;
    movlw 1
    movwf io_count
;
    movlw -io_id0
    addwf io_temp1,F
;
    btfsc STATUS,Z
    goto LinkChannelDo

LinkChannelLoop:
    incf io_count,F
    movlw -0x10
    addwf io_temp1,F
;
    btfss STATUS,Z
    goto LinkChannelLoop

LinkChannelDo:
    movlw io_adr
    addwf FSR0L,F
    movf INDF0,W
;
    lfsr 1,io_adr_base
    addwf FSR1L,F
;
    movf io_count,W
    movwf INDF1
;
    movlw -io_adr
    addwf FSR0L,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UnlinkChannel
;
;   FSR0 = buffer start
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkChannel:
    movlw io_adr
    addwf FSR0L,F
    movf INDF0,W
;
    lfsr 1,io_adr_base
    addwf FSR1L,F
;
    clrf INDF1
;
    movlw -io_adr
    addwf FSR0L,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupAllReq
;
;   FSR0 = buffer start
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupAllReq:
    movlb 0
    bsf bus_state,BUS_STATE_ALL
;
    movlb io_page
;
    movf POSTINC0,W
    movwf io_id0
    movwf io_id1
    movwf io_id2
    movwf io_id3
;
    movf POSTINC0,W
    movwf io_state0
    movwf io_state1
    movwf io_state2
    movwf io_state3
;
    movf POSTINC0,W
    movwf io_adr0
    movwf io_adr1
    movwf io_adr2
    movwf io_adr3
;
    movf POSTINC0,W
    movwf io_cmd0
    movwf io_cmd1
    movwf io_cmd2
    movwf io_cmd3
;
    movf POSTINC0,W
    movwf io_v00
    movwf io_v01
    movwf io_v02
    movwf io_v03
;
    movf POSTINC0,W
    movwf io_v10
    movwf io_v11
    movwf io_v12
    movwf io_v13
;
    movf POSTINC0,W
    movwf io_v20
    movwf io_v21
    movwf io_v22
    movwf io_v23
;
    movf POSTINC0,W
    movwf io_v30
    movwf io_v31
    movwf io_v32
    movwf io_v33
;
    movlw 0xF
    movwf io_chans
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupOneReq
;
;   FSR0 = buffer start
;   W  = channel (1..4)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupOneReq:
    movlb 0
    bcf bus_state,BUS_STATE_ALL
;
    movlb io_page
    movwf io_count
    movlw 1
    movwf io_chans
    lfsr 1,io_id0

SetupOneChannelLoop:
    decfsz io_count,F
    goto SetupOneChannelNext
    goto SetupOneChannelDo

SetupOneChannelNext:
    movlw 0x10
    addwf FSR1L,F
    rlncf io_chans,F
    goto SetupOneChannelLoop

SetupOneChannelDo:
    movlw 8
    movwf io_count

SetupOneCopyLoop:
    movf POSTINC0,W
    movwf POSTINC1
;
    decfsz io_count,F
    goto SetupOneCopyLoop
;
    movf io_chans,W
    movwf io_init_chans
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CopyResult
;
;  FSR0 = source of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyResult:
    call LinkChannel
;
    movlb io_page
    movf INDF0, W
    movwf io_curr_id
;
    movlb 0
    btfss bus_state, BUS_STATE_IN_BUSY
    goto DoCopy
;
    call Poll
    goto CopyResult

DoCopy:
    movlw 8
    movwf count
    lfsr 1,usb_bus_in

CopyResultLoop:
    movf POSTINC0,W
    movwf POSTINC1
;
    decfsz count,F
    goto CopyResultLoop
;
    movlb usb_buf_page
    movlw 8
    movwf bus_in_size
;
    movlw 0x40
    xorwf bus_in_stat,W
    andlw 0x40
    iorlw 0x88
    movwf bus_in_stat
;
    movlb 0
    bsf bus_state, BUS_STATE_IN_BUSY
    call Poll
;
    movlb io_page
    movf io_curr_id, W
    call RemoveBusReq
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ProcessSingle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessSingle:
    movlb io_page
;
    lfsr 0,io_id0
    btfss io_init_chans,0
    goto ProcessSingleCheck1
;
    btfsc io_chans,0
    goto ProcessSingleOk0
;
    call UnlinkChannel
    goto ProcessSingleCheck1

ProcessSingleOk0:
    call CopyResult

ProcessSingleCheck1:
    lfsr 0,io_id1
    btfss io_init_chans,1
    goto ProcessSingleCheck2
;
    btfsc io_chans,1
    goto ProcessSingleOk1
;
    call UnlinkChannel
    goto ProcessSingleCheck2

ProcessSingleOk1:
    call CopyResult

ProcessSingleCheck2:
    lfsr 0,io_id2
    btfss io_init_chans,2
    goto ProcessSingleCheck3
;
    btfsc io_chans,2
    goto ProcessSingleOk2
;
    call UnlinkChannel
    goto ProcessSingleCheck3

ProcessSingleOk2:
    call CopyResult

ProcessSingleCheck3:
    lfsr 0,io_id3
    btfss io_init_chans,3
    return
;
    btfsc io_chans,3
    goto CopyResult
;
    goto UnlinkChannel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ProcessAll
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessAll:
    movlb io_page
;
    lfsr 0,io_id0
    btfsc io_chans,0
    goto CopyResult
;
    lfsr 0,io_id1
    btfsc io_chans,1
    goto CopyResult
;
    lfsr 0,io_id2
    btfsc io_chans,2
    goto CopyResult
;
    lfsr 0,io_id3
    btfsc io_chans,3
    goto CopyResult
;
    lfsr 0,io_id0
    goto UnlinkChannel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ProcessResult
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessResult:
    movlb 0
    btfss bus_state,BUS_STATE_ALL
    goto ProcessSingle
    goto ProcessAll

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; RunIo
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunIo:
    call GetBusReq
    btfss STATUS,C
    goto RunIt
;
    movlb 0
    bcf bus_state, BUS_STATE_REQ
    return

RunIt:
    call GetReqChannel
    btfsc STATUS,Z
    goto RunAll

RunOne:
    call SetupOneReq
    goto RunActivate

RunAll:
    call SetupAllReq

RunActivate:
    call Activate
    call Preamp
    call OutputAdr    
    call OutputCmd
;
    movlw 0
    movwf io_base
    clrf io_curr_chan
;
    btfsc io_chans,0
    call RunCmd
;
    movlw 0x10
    movwf io_base
    incf io_curr_chan,F
;
    btfsc io_chans,1
    call RunCmd
;
    movlw 0x20
    movwf io_base
    incf io_curr_chan,F
;
    btfsc io_chans,2
    call RunCmd
;
    movlw 0x30
    movwf io_base
    incf io_curr_chan,F
;
    btfsc io_chans,3
    call RunCmd
;
    call Deactivate
    call ProcessResult
    goto RunIo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HostToIo
;
; Move req from host to IO
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HostToIo:
    call AllocateBusReq
    btfsc STATUS,C
    return
;
    movlb 0
    movlw 8
    movwf count
    lfsr 1,usb_bus_out

HostToIoMoveLoop:
    movf POSTINC1,W
    movwf POSTINC0
;
    decfsz count,F
    goto HostToIoMoveLoop
;
    movlb usb_buf_page
    movlw 8
    movwf bus_out_size
;
    movlw 0x40
    xorwf bus_out_stat,W
    andlw 0x40
    iorlw 0x88
    movwf bus_out_stat
    movlb 0
    bcf bus_state, BUS_STATE_OUT_BUSY
    bsf bus_state, BUS_STATE_REQ
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; InitUsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitUsb:
    movlb 0xF
    clrf UIE
    clrf UIR
;
    movlw 0x14
    movwf UCFG
;
    movlw 8
    movwf UCON
;
    movlb 0
    clrf usb_flags
    clrf usb_adr
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; InitSerial
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitSerial:
    movlb ser_buf_page
    clrf rx_count
    clrf rx_in_pos 
    clrf rx_out_pos
    clrf tx_count
    clrf tx_in_pos
    clrf tx_out_pos
    movlb 0
    clrf ser_state
    bsf ser_state, SER_STATE_PAR9
    movlw 0xFF
    movwf ser_mask
    clrf RCSTA
    clrf TXSTA
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleUsbError
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleUsbError:
    movlb 0xF
    clrf UEIR
    bcf UIR, UERRIF
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleUsbReset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleUsbReset:
    movlb 0xF
    bcf UIR, TRNIF
    bcf UIR, TRNIF
    bcf UIR, TRNIF
    bcf UIR, TRNIF
;
    clrf UEP0
    clrf UEP1
    clrf UEP2
    clrf UEP3
    clrf UEP4
    clrf UEP5
    clrf UEP6
    clrf UEP7
;
    movlb usb_buf_page
    movlw 8
    movwf control_out_size
    movlw low usb_cout
    movwf control_out_low
    movlw high usb_cout
    movwf control_out_high
    movlw 0x88
    movwf control_out_stat
;
    movlw 8
    movwf control_in_size
    movlw low usb_cin
    movwf control_in_low
    movlw high usb_cin
    movwf control_in_high
    movlw 0x8
    movwf control_in_stat
;
    movlw SER_USB_SIZE
    movwf ser_out_size
    movlw low usb_ser_out
    movwf ser_out_low
    movlw high usb_ser_out
    movwf ser_out_high
    movlw 0x88
    movwf ser_out_stat
;
    movlw SER_USB_SIZE
    movwf ser_in_size
    movlw low usb_ser_in
    movwf ser_in_low
    movlw high usb_ser_in
    movwf ser_in_high
    movlw 0x48
    movwf ser_in_stat
;
    movlw 0x8
    movwf bus_out_size
    movlw low usb_bus_out
    movwf bus_out_low
    movlw high usb_bus_out
    movwf bus_out_high
    movlw 0x88
    movwf bus_out_stat
;
    movlw 0x8
    movwf bus_in_size
    movlw low usb_bus_in
    movwf bus_in_low
    movlw high usb_bus_in
    movwf bus_in_high
    movlw 0x48
    movwf bus_in_stat
;
    movlb 0xF
    clrf UADDR
    clrf UIR
;
    movlw 0xFF
    movwf UIE
;
    movlw 0x16
    movwf UEP0
;
    movlw 0x1E
    movwf UEP1
;
    movlw 0x1E
    movwf UEP2
;
    movlb 0
    clrf usb_flags
    clrf usb_adr
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupDeviceDescr
;
; OUT: W size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDeviceDescr:
    movlw low DeviceDescr
    movwf TBLPTRL
    movlw high DeviceDescr
    movwf TBLPTRH
    movlw upper DeviceDescr
    movwf TBLPTRU
    tblrd *
    movf TABLAT, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupConfigDescr
;
; OUT: W size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupConfigDescr:
    movlw low ConfigTotalSize
    movwf TBLPTRL
    movlw high ConfigTotalSize
    movwf TBLPTRH
    movlw upper ConfigTotalSize
    movwf TBLPTRU
    tblrd *
;
    movlw low ConfigDescr
    movwf TBLPTRL
    movlw high ConfigDescr
    movwf TBLPTRH
    movlw upper ConfigDescr
    movwf TBLPTRU
;
    movf TABLAT, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupString0
;
; OUT: W size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupString0:
    movlw low String0
    movwf TBLPTRL
    movlw high String0
    movwf TBLPTRH
    movlw upper String0
    movwf TBLPTRU
    tblrd *
    movf TABLAT, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupString1
;
; OUT: W size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupString1:
    movlw low String1
    movwf TBLPTRL
    movlw high String1
    movwf TBLPTRH
    movlw upper String1
    movwf TBLPTRU
    tblrd *
    movf TABLAT, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupString2
;
; OUT: W size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupString2:
    movlw low String2
    movwf TBLPTRL
    movlw high String2
    movwf TBLPTRH
    movlw upper String2
    movwf TBLPTRU
    tblrd *
    movf TABLAT, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DecideSize
;
; IN:  W object size
; OUT: W used size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecideSize:
    movlb 0
    bsf usb_flags, DESCR_FLAG_MORE
    bcf usb_flags, DESCR_FLAG_FULL
    movwf temp1
    movf b_len_high, W
    btfss STATUS, Z
    goto DecideWhole
;
    movf b_len_low, w
    cpfseq temp1
    goto DecideCompLow
    goto DecideFull

DecideCompLow:
    cpfslt temp1
    goto DecideFull
    goto DecideWhole

DecideFull:
    bsf usb_flags, DESCR_FLAG_FULL
    return

DecideWhole:
    movf temp1, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DecideFragSize
;
; OUT: W used size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecideFragSize:
    movlw 8
    cpfslt remain_size
    return

DecideFragWhole:
    movf remain_size, W
    bcf usb_flags, DESCR_FLAG_MORE
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDescr:
    movlb 0
    call DecideFragSize
    movwf temp1
    movwf count
;
    movf count, W
    btfss STATUS,Z
    goto gdCopy
;
    btfsc usb_flags, DESCR_FLAG_FULL
    return
;
    goto gdSetup

gdCopy:
    lfsr 0,usb_cin

gdLoop:
    tblrd *+
    movf TABLAT,W
    movwf POSTINC0
    decf remain_size, F
;
    decfsz temp1,F
    goto gdLoop

gdSetup:
    movff count,control_in_size
;
    movlb usb_buf_page
    movlw 0x40
    xorwf control_in_stat,W
    andlw 0x40
    iorlw 0x88
    movwf control_in_stat
    movlb 0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SendEmpty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendEmpty:
    movlb usb_buf_page
    clrf control_in_size
    movlw 0xC8
    movwf control_in_stat
    movlb 0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSetAddr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSetAddr:
    btfsc b_req_type, 7
    return
;
    movf b_val_low, W
    movwf usb_adr
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleGetDeviceDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGetDeviceDescr:
    call SetupDeviceDescr
    call DecideSize
    movwf remain_size
    call GetDescr
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleGetConfigDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGetConfigDescr:
    call SetupConfigDescr
    call DecideSize
    movwf remain_size
    call GetDescr
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleGetStringDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGetStringDescr:
    movlw 0
    cpfseq b_val_low
    goto NotGetString0
;
    call SetupString0
    goto HandleSendString

NotGetString0:
    movlw 1
    cpfseq b_val_low
    goto NotGetString1
;
    call SetupString1
    goto HandleSendString

NotGetString1:
    movlw 2
    cpfseq b_val_low
    goto NotGetString2
;
    call SetupString2
    goto HandleSendString

NotGetString2:
    return

HandleSendString:
    call DecideSize
    movwf remain_size
    call GetDescr
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleGetDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGetDescr:
    btfss b_req_type, 7
    return
;
    movlw 1
    cpfseq b_val_high
    goto NotGetDeviceDescr
;
    call HandleGetDeviceDescr
    return

NotGetDeviceDescr:
    movlw 2
    cpfseq b_val_high
    goto NotGetConfigDescr
;
    call HandleGetConfigDescr
    return

NotGetConfigDescr:
    movlw 3
    cpfseq b_val_high
    goto NotGetStringDescr
;
    call HandleGetStringDescr
    return

NotGetStringDescr:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSetConfig
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSetConfig:
    btfsc b_req_type, 7
    return
;
    movlw 1
    cpfseq b_val_low
    return
;
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSetBaud
;
;  Value = ser baud
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSetBaud:
    btfsc b_req_type, 7
    return
;
    bsf BAUDCON, BRG16
    bsf TXSTA, BRGH
;
    movf b_val_low, W
    movwf SPBRG
;
    movf b_val_high, W
    movwf SPBRGH
;
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSetDataBits
;
;  Value = ser data bits (7 or 8)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSetDataBits:
    btfsc b_req_type, 7
    return
;
    movlw 7
    cpfseq b_val_low
    goto NotData7

Data7:
    movlw 0x7F
    movwf ser_mask
    bcf ser_state, SER_STATE_PAR9
    goto HandleBitsOk

NotData7:
    movlw 8
    cpfseq b_val_low
    return

Data8:
    movlw 0xFF
    movwf ser_mask
    bsf ser_state, SER_STATE_PAR9

HandleBitsOk:
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSetParity
;
;  Value = ser parity ('n', 'e', 'o')
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSetParity:
    btfsc b_req_type, 7
    return
;
    movlw 'n'
    cpfseq b_val_low
    goto NotLowerNone
    goto HandleParNone

NotLowerNone:
    movlw 'N'
    cpfseq b_val_low
    goto NotUpperNone

HandleParNone:
    bcf ser_state, SER_STATE_ODD
    bcf ser_state, SER_STATE_EVEN
    goto HandleParOk

NotUpperNone:
    movlw 'e'
    cpfseq b_val_low
    goto NotLowerEven
    goto HandleParEven

NotLowerEven:
    movlw 'E'
    cpfseq b_val_low
    goto NotUpperEven

HandleParEven:
    bcf ser_state, SER_STATE_ODD
    bsf ser_state, SER_STATE_EVEN
    goto HandleParOk

NotUpperEven:
    movlw 'o'
    cpfseq b_val_low
    goto NotLowerOdd
    goto HandleParOdd

NotLowerOdd:
    movlw 'O'
    cpfseq b_val_low
    return

HandleParOdd:
    bsf ser_state, SER_STATE_ODD
    bcf ser_state, SER_STATE_EVEN

HandleParOk:
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleStartSerial
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleStartSerial:
    btfsc b_req_type, 7
    return
;
    btfsc ser_state, SER_STATE_PAR9
    goto StartData8

StartData7:
    btfsc ser_state, SER_STATE_ODD
    goto Start8
;
    btfss ser_state, SER_STATE_EVEN
    return
    goto Start8

StartData8:
    btfsc ser_state, SER_STATE_ODD
    goto Start9
;
    btfsc ser_state, SER_STATE_EVEN
    goto Start9

Start8:
    bcf RCSTA, RX9
    bcf TXSTA, TX9
    goto StartSerial

Start9:
    bsf RCSTA, RX9
    bsf TXSTA, TX9

StartSerial:
    bsf RCSTA, SPEN
    bsf RCSTA, CREN
    bsf TXSTA, TXEN
    bsf ser_state, SER_STATE_ACTIVE
;
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleStopSerial
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleStopSerial:
    btfsc b_req_type, 7
    return
;
    call InitSerial
;
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleControlVendor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleControlVendor:
    movlw SET_BAUD
    cpfseq b_req
    goto NotSetBaud
;
    call HandleSetBaud
    return

NotSetBaud:
    movlw SET_DATA_BITS
    cpfseq b_req
    goto NotSetDataBits
;
    call HandleSetDataBits
    return

NotSetDataBits:
    movlw SET_PARITY
    cpfseq b_req
    goto NotSetParity
;
    call HandleSetParity
    return

NotSetParity:
    movlw START_SERIAL
    cpfseq b_req
    goto NotStartSerial
;
    call HandleStartSerial
    return

NotStartSerial:
    movlw STOP_SERIAL
    cpfseq b_req
    goto NotStopSerial
;
    call HandleStopSerial
    return

NotStopSerial:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleControlSetup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleControlSetup:
    btfsc b_req_type,5
    return
;
    btfsc b_req_type,6
    goto HandleControlVendor
;
    movlw SET_ADDRESS
    cpfseq b_req
    goto NotSetAddr
;
    call HandleSetAddr
    return

NotSetAddr:
    movlw GET_DESCRIPTOR
    cpfseq b_req
    goto NotGetDescr
;
    call HandleGetDescr
    return

NotGetDescr:
    movlw SET_CONFIGURATION
    cpfseq b_req
    goto NotSetConf
;
    call HandleSetConfig
    return

NotSetConf:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleControlIn
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleControlIn:
    btfss b_req_type, 7
    goto HandleControlToDevice

HandleControlFromDevice:
    bsf usb_flags, USB_HANDLED
;
    movlw GET_DESCRIPTOR
    cpfseq b_req
    goto NotGetDescrIn
;
    btfsc usb_flags, DESCR_FLAG_MORE
    call GetDescr

NotGetDescrIn:
    return

HandleControlToDevice:
    bsf usb_flags, USB_HANDLED
;
    movlw SET_ADDRESS
    cpfseq b_req
    goto NotSetAddrIn
;
    movf usb_adr, W
    movlb 0xF
    movwf UADDR
    movlb 0
    return

NotSetAddrIn:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleControlOut
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleControlOut:
    movlb usb_buf_page
    movlw 8
    movwf control_out_size
    movlw 0x88
    movwf control_out_stat
    movlb 0
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; RecControlComplete
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecControlComplete:
    btfss usb_stat, DIR
    goto RecControlOut

RecControlIn:
    call HandleControlIn
    return

RecControlOut:
    btfsc d_curr_stat,5
    goto RecControlSetup
;
    call HandleControlOut
    return

RecControlSetup:
    movff usb_cout, b_req_type
    movff usb_cout+1, b_req
    movff usb_cout+2, b_val_low
    movff usb_cout+3, b_val_high
    movff usb_cout+4, b_index_low
    movff usb_cout+5, b_index_high
    movff usb_cout+6, b_len_low
    movff usb_cout+7, b_len_high
;
    movlb usb_buf_page
    movlw 8
    movwf control_out_size
    movlw 0xC8
    movwf control_out_stat
    bcf UCON, PKTDIS
    bcf control_in_stat,6
;
    movlb 0
    call HandleControlSetup
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; BufferToUsb
;
; Move serial buffer to USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BufferToUsb:
    movlb ser_buf_page
    movf rx_count, W
    btfsc STATUS, Z
    goto btuRet
;
    lfsr 0,rx_buf
    movf rx_in_pos, W
    addwf FSR0L, F
    lfsr 1,usb_ser_in
;
    movlw SER_USB_SIZE
    movwf ser_rem_count
    clrf ser_curr_count

btuLoop:
    movf POSTINC0, W
    movwf POSTINC1
;
    incf rx_in_pos, F
    movlw SER_COM_SIZE
    cpfseq rx_in_pos
    goto btuNext
;
    lfsr 0,rx_buf
    clrf rx_in_pos

btuNext:        
    incf ser_curr_count, F
;
    decfsz rx_count, F
    goto btuMore
    goto btuDone

btuMore:
    decfsz ser_rem_count, F
    goto btuLoop

btuDone:
    movf ser_curr_count, W
    movlb usb_buf_page
    movwf ser_in_size
;
    movlw 0x40
    xorwf ser_in_stat,W
    andlw 0x40
    iorlw 0x88
    movwf ser_in_stat
;
    movlb 0
    bsf ser_state, SER_STATE_IN_BUSY
    return

btuRet:
    movlb 0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UsbToBuffer
;
; Move USB data to com buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UsbToBuffer:
    movlb ser_buf_page
    movf tx_count, W
    movwf ser_curr_count
;
    movlb usb_buf_page
    movf ser_out_size, W
    movlb ser_buf_page
    movwf ser_rem_count
    addwf ser_curr_count, F
;
    movlw SER_COM_SIZE
    cpfsgt ser_curr_count
    goto utbProcess
;
    movlb 0
    return

utbProcess:
    lfsr 0,usb_ser_out
    lfsr 1,tx_buf
    movf tx_out_pos, W
    addwf FSR1L, F

utbLoop:
    movf POSTINC0, W
    movwf POSTINC1
;
    incf tx_out_pos, F
    movlw SER_COM_SIZE
    cpfseq tx_out_pos
    goto utbNext
;
    lfsr 1,tx_buf
    clrf tx_out_pos

utbNext:        
    incf tx_count, F
    decfsz ser_rem_count, F
    goto utbLoop
;
    movlb usb_buf_page
    movlw SER_USB_SIZE
    movwf ser_out_size
;
    movlw 0x40
    xorwf ser_out_stat,W
    andlw 0x40
    iorlw 0x88
    movwf ser_out_stat
    movlb 0
    bcf ser_state, SER_STATE_OUT_BUSY
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSerialIn
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSerialIn:
    bcf ser_state, SER_STATE_IN_BUSY
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSerialOut
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSerialOut:
    bsf ser_state, SER_STATE_OUT_BUSY
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleBusIn
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleBusIn:
    bcf bus_state, BUS_STATE_IN_BUSY
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleBusOut
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleBusOut:
    bsf bus_state, BUS_STATE_OUT_BUSY
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleUsbComplete
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleUsbComplete:
    movlb 0
    bcf usb_flags, USB_HANDLED
;
    movlw usb_buf_page
    movwf FSR0H
    movf USTAT, W
    movwf usb_stat
    andlw 0x7C
    movwf FSR0L
;
    movf POSTINC0, W
    movwf d_curr_stat
;
    movf POSTINC0, W
    movwf d_curr_count
;
    movf POSTINC0, W
    movwf d_curr_low
;
    movf POSTINC0, W
    movwf d_curr_high
;
    bcf UIR, TRNIF
;
    movf usb_stat, W
    andlw 0x38
    movwf usb_ep
;
    movlw EP0
    cpfseq usb_ep
    goto HandleUsbNotControl
;
    call RecControlComplete
;
    movlb 0
    btfsc usb_flags, USB_HANDLED
    return
;
    movlb usb_buf_page
    movlw 8
    movwf control_out_size
    movlw 0x84
    movwf control_out_stat
    movwf control_in_stat
    movlb 0
    return

HandleUsbNotControl:
    movlw EP1
    cpfseq usb_ep
    goto HandleUsbNotSerial
;
    btfss usb_stat, DIR
    goto HandleSerialOut
    goto HandleSerialIn

HandleUsbNotSerial:
    movlw EP2
    cpfseq usb_ep
    goto HandleUsbNotBus
;
    btfss usb_stat, DIR
    goto HandleBusOut
    goto HandleBusIn

HandleUsbNotBus:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetSetBits
;
; Get number of set bits
;
; IN:  W value
; OUT: W set bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSetBits:
    movwf temp1
    clrf parity
;
    btfss ser_state, SER_STATE_PAR9
    goto GetBits8

GetBits9:
    btfsc temp1,0
    incf parity, F
    btfsc temp1,1
    incf parity, F
    btfsc temp1,2
    incf parity, F
    btfsc temp1,3
    incf parity, F
    btfsc temp1,4
    incf parity, F
    btfsc temp1,5
    incf parity, F
    btfsc temp1,6
    incf parity, F
    btfsc temp1,7
    incf parity, F
    movf parity, W
    return

GetBits8:
    btfsc temp1,0
    incf parity, F
    btfsc temp1,1
    incf parity, F
    btfsc temp1,2
    incf parity, F
    btfsc temp1,3
    incf parity, F
    btfsc temp1,4
    incf parity, F
    btfsc temp1,5
    incf parity, F
    btfsc temp1,6
    incf parity, F
    movf parity, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetRecParity
;
; Get received parity
;
; IN:  temp1 = RCREG
; OUT: W parity
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRecParity:
    btfss ser_state, SER_STATE_PAR9
    goto GetRecPar8

GetRecPar9:
    movlw 0
    btfss RCSTA, RX9D
    return
;
    movlw 1
    return

GetRecPar8:
    movlw 0
    btfss temp1, 7
    return
;
    movlw 1
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetSendParity
;
; Set send parity
;
; IN:  temp1 = RCREG
; IN:  W parity
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSendParity:
    btfss ser_state, SER_STATE_PAR9
    goto SetSendPar8

SetSendPar9:
    bcf TXSTA, TX9D
    btfsc parity, 0
    bsf TXSTA, TX9D
    return

SetSendPar8:
    btfsc parity, 0
    bsf temp1, 7
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSerReceive
;
; Handle serial receive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSerReceive:
    movf RCREG, W
    movwf temp1
;
    movlb ser_buf_page
    movlw SER_COM_SIZE
    cpfseq rx_count
    goto SerRecSpace
;
    movlb 0
    return

SerRecSpace:
    movlb 0
    btfsc ser_state, SER_STATE_ODD
    goto SerRecOdd
;
    btfss ser_state, SER_STATE_EVEN
    goto SerRecParOk

SerRecEven:
    movf temp1, W
    call GetSetBits
    call GetRecParity
    xorwf parity, F
    btfsc parity, 0
    return
;
    goto SerRecParOk

SerRecOdd:
    movf temp1, W
    call GetSetBits
    call GetRecParity
    xorwf parity, F
    btfss parity, 0
    return

SerRecParOk:
    movlb 0
    movf temp1, W
    andwf ser_mask, W
    movwf temp1
;
    movlb ser_buf_page
    lfsr 0,rx_buf
    movf rx_out_pos, W
    addwf FSR0L, F
;
    movlb 0
    movf temp1, W
    movwf INDF0
;
    movlb ser_buf_page
    incf rx_out_pos, F
    movlw SER_COM_SIZE
    cpfseq rx_out_pos
    goto SerRecOutOk
;
    clrf rx_out_pos

SerRecOutOk:
    incf rx_count, F
    movlb 0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSerSend
;
; Handle serial send
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSerSend:
    movlb ser_buf_page
    movf tx_count, W
    btfsc STATUS, Z
    return
;
    bsf LATC,1
;
    lfsr 0,tx_buf
    movf tx_in_pos, W
    addwf FSR0L, F
    movf INDF0, W
;
    movlb 0
    andwf ser_mask, W
    movwf temp1
    btfsc ser_state, SER_STATE_ODD
    goto SendOdd
;
    btfss ser_state, SER_STATE_EVEN
    goto SerSendParOk

SendEven:
    movf temp1, W
    call GetSetBits
    call SetSendParity
    goto SerSendParOk

SendOdd:
    movf temp1, W
    call GetSetBits
    movlw 1
    xorwf parity,F 
    call SetSendParity

SerSendParOk:
    movf temp1, W
    movwf TXREG
;
    movlb ser_buf_page
    incf tx_in_pos, F
    movlw SER_COM_SIZE
    cpfseq tx_in_pos
    goto hssNext
;
    clrf tx_in_pos

hssNext:
    decf tx_count, F
    movlb 0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSendIdle
;
; Handle serial send idle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSendIdle:
    movlb ser_buf_page
    movf tx_count, W
    btfss STATUS, Z
    return
;
    bcf LATC,1
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Poll
;
; Poll USB & serial port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Poll:
    movff STATUS, status_isr
    movff BSR, bsr_isr
;
    movlb 0xF
    btfsc UIR, UERRIF
    call HandleUsbError
;
    btfsc UIR, SOFIF
    bcf UIR, SOFIF
;
    btfsc UIR, IDLEIF
    bcf UIR, IDLEIF
;
    btfsc UIR, ACTVIF
    bcf UIR, ACTVIF
;
    btfsc UIR, STALLIF
    bcf UIR, STALLIF
;
    btfsc UIR, URSTIF
    call HandleUsbReset
;
    btfsc UIR, TRNIF
    call HandleUsbComplete
;
    movlb 0
    btfss ser_state, SER_STATE_ACTIVE
    goto SerDone
;
    btfss ser_state, SER_STATE_IN_BUSY
    call BufferToUsb
;
    btfsc ser_state, SER_STATE_OUT_BUSY
    call UsbToBuffer
;
    btfsc PIR1, RCIF
    call HandleSerReceive
;
    btfsc PIR1, TXIF
    call HandleSerSend
;
    btfsc TXSTA,TRMT
    call HandleSendIdle

SerDone:
    btfsc bus_state, BUS_STATE_OUT_BUSY
    call HostToIo
;
    movff bsr_isr, BSR
    movff status_isr, STATUS
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Delay
;
; IO delay (1ms)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delay:
    call Poll
    btfss PIR1,TMR2IF
    bra Delay
;
    bcf PIR1,TMR2IF
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WaitMs
;
; Delay 1ms
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitMs:
    movlw 0xA
    movwf counter_dms

wmLoop:
    call Delay
;
    decfsz counter_dms,F
    bra wmLoop
;
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WaitDs
;
; Delay 0.1s
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitDs:
    movlw 0x64
    movwf counter_ms

wdLoop:
    call WaitMs
;
    decfsz counter_ms,F
    bra wdLoop
;
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Program start
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProgStart:
    movlw 0x64
    movwf counter_ms
;
    movlw 0xA
    movwf counter_ds
;
    movlw 0xFF
    movwf TRISA
;
    movlw 0xF
    movwf LATB
;
    movlw 0xF0
    movwf TRISB
;
    movlw 0x42
    movwf LATC
;
    movlw 0xBD
    movwf TRISC
;
    movlw 0xF
    movwf LATD
;
    movlw 0xF0
    movwf TRISD
;
    movlw 0x3
    movwf LATE
;
    movlw 0xFC
    movwf TRISE
;
    movlw 0
    movwf BSR
;
    movlw 0x26
    movwf T2CON
;
    movlw 0xA
    movwf PR2
;
    bcf PIR1,TMR2IF
;
    clrf temp1
;
    call InitUsb
    call InitSerial
    call InitBus
    
Loop:
    call Poll
    btfsc bus_state, BUS_STATE_REQ
    call RunIo
    goto Loop

DeviceDescr:
    db 0x12, 1     ; len + device descriptor
    db 0x10, 1     ; USB ver (full speed)
    db 0, 0        ; class + sub class
    db 0, 8        ; no device protocol + 8 byte packet size
    db 0x4D, 0x5   ; vendor id 
    db 1, 0x10     ; product id
    db 0, 1        ; version
    db 1, 2        ; manufacturer id + product id
    db 0, 1        ; no serial # + one configuration

ConfigDescr:
    db 0x9, 2      ; len + config descriptor

ConfigTotalSize:
    db ConfigEnd - ConfigDescr, 0   ; total size (must be less than 256 bytes)
    db 1, 1        ; number of interfaces + config value
    db 0, 0x80     ; config string id + bus powered
    db 0x31, 0x9   ; max 100mA + interface len
    db 4, 0        ; interface descriptor + interface #
    db 0, 4        ; alt setting + endpoint entries
    db 0xFF, 0     ; class + sub class
    db 0xFF, 0     ; vendor protocol + interface string id

Endpoint1:
    db 7, 5        ; size + endpoint 1 OUT
    db 0x1, 0x2    ; OUT endpoint 1 + bulk
    db 0x40, 0     ; max packet size (64 bytes)
    db 0, 7        ; max NAKs, endpoint 1 IN 
    db 5, 0x81     ; IN endpoint 1
    db 0x2, 0x40   ; bulk + max packet size low
    db 0, 0        ; max packet size high + max NAKs

Endpoint2:
    db 7, 5        ; size + endpoint 2 OUT
    db 0x2, 0x2    ; OUT endpoint 2 + bulk
    db 0x8, 0      ; max packet size (8 bytes)
    db 0, 7        ; max NAKs, endpoint 2 IN 
    db 5, 0x82     ; IN endpoint 2
    db 0x3, 0x8    ; interrupt + max packet size low
    db 0, 1        ; max packet size high + interval

ConfigEnd:

String0:
    db String1 - String0, 3
    db 0x9, 0xC

String1:
    db String2 - String1, 3
    db 'R', 0
    db 'D', 0
    db 'O', 0
    db 'S', 0
    db ' ', 0
    db 'D', 0
    db 'e', 0
    db 'v', 0
    db 'e', 0
    db 'l', 0
    db 'o', 0
    db 'p', 0
    db 'm', 0
    db 'e', 0
    db 'n', 0
    db 't', 0
    db '.', 0
String2:
    db String3 - String2, 3
    db 'S', 0
    db 'e', 0
    db 'r', 0
    db 'i', 0
    db 'a', 0
    db 'l', 0
    db ' ', 0
    db 'b', 0
    db 'u', 0
    db 's', 0
String3:

    end
