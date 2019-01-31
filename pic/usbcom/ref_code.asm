; 
; Author: Bradley A. Minch
; Organization: Franklin W. Olin College of Engineering
; Revision History: 
;     01/19/2006 - Added wait for initial SE0 condition to clear at the end
;                  of InitUSB.
;     01/13/2006 - Fixed problem with DATA OUT transfers (only worked properly
;                  with class requests) in ProcessSetupToken.  Added code to
;                  disable all EPs except EP0 on a valid SET_CONFIGURATION
;                  request.  Changed code to use BSTALL instead of EPSTALL for
;                  Request Error on EP0.  Changed CLEAR_FEATURE, SET_FEATURE
;                  and GET_STATUS requests to use BSTALL instead of EPSTALL.
;                  Changed over from the deprecated __CONFIG assembler directive 
;                  to config for setting the configuration bits.  Eliminated the
;                  initial for loop from the start of the main section.
;     06/22/2005 - Added code to disable all endpoints on USRTIF and to mask
;                  bits 0, 1, and 7 of USTAT on TRNIF in ServiceUSB.
;     04/21/2005 - Initial public release.
;
; ============================================================================
; 
; Peripheral Description:
; 
; This peripheral enumerates as a vendor-specific device. The main event loop 
; blinks an LED connected to RA1 on and off at about 2 Hz and the peripheral 
; responds to a pair of vendor-specific requests that turn on or off an LED ;
; connected to RA0.  The firmware is configured to use an external 4-MHz 
; crystal, to operate as a low-speed USB device, and to use the internal 
; pull-up resistor.
; 
; ============================================================================
;
; Software Licence Agreement:
; 
; THIS SOFTWARE IS PROVIDED IN AN "AS IS" CONDITION.  NO WARRANTIES, WHETHER 
; EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED 
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY 
; TO THIS SOFTWARE. THE AUTHOR SHALL NOT, UNDER ANY CIRCUMSTANCES, BE LIABLE 
; FOR SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
; 
#include <p18F2550.inc>
#include "usb_defs.inc"
#include "engr2210.inc"

;			__CONFIG	_CONFIG1L, _PLLDIV_1_1L & _CPUDIV_OSC1_PLL2_1L & _USBDIV_2_1L
;			__CONFIG	_CONFIG1H, _FOSC_XTPLL_XT_1H & _FCMEM_OFF_1H & _IESO_OFF_1H
;			__CONFIG	_CONFIG2L, _PWRT_OFF_2L & _BOR_ON_2L & _BORV_21_2L & _VREGEN_ON_2L
;			__CONFIG	_CONFIG2H, _WDT_OFF_2H & _WDTPS_32768_2H
;			__CONFIG	_CONFIG3H, _MCLRE_ON_3H & _LPT1OSC_OFF_3H & _PBADEN_OFF_3H & _CCP2MX_ON_3H
;			__CONFIG	_CONFIG4L, _STVREN_ON_4L & _LVP_OFF_4L & _ICPRT_OFF_4L & _XINST_OFF_4L & _DEBUG_OFF_4L
;			__CONFIG	_CONFIG5L, _CP0_OFF_5L & _CP1_OFF_5L & _CP2_OFF_5L & _CP3_OFF_5L
;			__CONFIG	_CONFIG5H, _CPB_OFF_5H & _CPD_OFF_5H
;			__CONFIG	_CONFIG6L, _WRT0_OFF_6L & _WRT1_OFF_6L & _WRT2_OFF_6L & _WRT3_OFF_6L
;			__CONFIG	_CONFIG6H, _WRTB_OFF_6H & _WRTC_OFF_6H & _WRTD_OFF_6H
;			__CONFIG	_CONFIG7L, _EBTR0_OFF_7L & _EBTR1_OFF_7L & _EBTR2_OFF_7L & _EBTR3_OFF_7L
;			__CONFIG	_CONFIG7H, _EBTRB_OFF_7H

			config PLLDIV = 1
			config CPUDIV = OSC3_PLL4
			config USBDIV = 2
			config FOSC = XTPLL_XT
;			config FCMEM = OFF
			config IESO = OFF
			config PWRT = OFF
			config BOR = ON
;			config BORV = 21
			config VREGEN = ON
			config WDT = OFF
			config WDTPS = 32768
			config MCLRE = ON
			config LPT1OSC = OFF
			config PBADEN = OFF
			config CCP2MX = ON
			config STVREN = ON
			config LVP = OFF
;			config ICPRT = OFF
			config XINST = OFF
			config DEBUG = OFF
			config CP0 = OFF
			config CP1 = OFF
			config CP2 = OFF
			config CP3 = OFF
			config CPB = OFF
			config CPD = OFF
			config WRT0 = OFF
			config WRT1 = OFF
			config WRT2 = OFF
			config WRT3 = OFF
			config WRTB = OFF
			config WRTC = OFF
			config WRTD = OFF
			config EBTR0 = OFF
			config EBTR1 = OFF
			config EBTR2 = OFF
			config EBTR3 = OFF
			config EBTRB = OFF

#define	SHOW_ENUM_STATUS

#define	SET_RA0			0x01		; vendor-specific request to set RA0 to high
#define	CLR_RA0			0x02		; vendor-specific request to set RA0 to low

bank0		udata
USB_buffer_desc	res		4
USB_buffer_data	res		8
USB_error_flags	res 	1
USB_curr_config	res		1
USB_device_status	res	1
USB_dev_req	res			1
USB_address_pending	res	1
USB_desc_ptr	res		1
USB_bytes_left	res		1
USB_loop_index	res		1
USB_packet_length	res	1
USB_USTAT	res			1
USB_USWSTAT	res			1
COUNTER_L		res		1
COUNTER_H		res		1

STARTUP		code		0x0000
			goto		Main					; Reset vector
			nop
			nop
			goto		$						; High-priority interrupt vector trap
			nop
			nop
			nop
			nop
			nop
			nop
			goto		$						; Low-priority interrupt vector trap


USBSTUFF	code
Descriptor
			movlw		upper Descriptor_begin
			movwf		TBLPTRU, ACCESS
			movlw		high Descriptor_begin
			movwf		TBLPTRH, ACCESS
			movlw		low Descriptor_begin
			banksel		USB_desc_ptr
			addwf		USB_desc_ptr, W, BANKED
			ifset STATUS, C, ACCESS
				incf		TBLPTRH, F, ACCESS
				ifset STATUS, Z, ACCESS
					incf		TBLPTRU, F, ACCESS
				endi
			endi
			movwf		TBLPTRL, ACCESS
			tblrd*
			movf		TABLAT, W
			return

Descriptor_begin
Device
			db			0x12, DEVICE		; bLength, bDescriptorType
			db			0x10, 0x01			; bcdUSB (low byte), bcdUSB (high byte)
			db			0x00, 0x00			; bDeviceClass, bDeviceSubClass
			db			0x00, MAX_PACKET_SIZE	; bDeviceProtocol, bMaxPacketSize
			db			0xD8, 0x04			; idVendor (low byte), idVendor (high byte)
			db			0x01, 0x00			; idProduct (low byte), idProduct (high byte)
			db			0x00, 0x00			; bcdDevice (low byte), bcdDevice (high byte)
			db			0x01, 0x02			; iManufacturer, iProduct
			db			0x00, NUM_CONFIGURATIONS	; iSerialNumber (none), bNumConfigurations

Configuration1
			db			0x09, CONFIGURATION	; bLength, bDescriptorType
			db			0x12, 0x00			; wTotalLength (low byte), wTotalLength (high byte)
			db			NUM_INTERFACES, 0x01	; bNumInterfaces, bConfigurationValue
			db			0x00, 0xA0			; iConfiguration (none), bmAttributes
			db			0x32, 0x09			; bMaxPower (100 mA), bLength (Interface1 descriptor starts here)
			db			INTERFACE, 0x00		; bDescriptorType, bInterfaceNumber
			db			0x00, 0x00			; bAlternateSetting, bNumEndpoints (excluding EP0)
			db			0xFF, 0x00			; bInterfaceClass (vendor specific class code), bInterfaceSubClass
			db			0xFF, 0x00			; bInterfaceProtocol (vendor specific protocol used), iInterface (none)

String0
			db			String1-String0, STRING	; bLength, bDescriptorType
			db			0x09, 0x04			; wLANGID[0] (low byte), wLANGID[0] (high byte)
String1
			db			String2-String1, STRING	; bLength, bDescriptorType
			db			'M', 0x00			; bString
			db			'i', 0x00
			db			'c', 0x00
			db			'r', 0x00
			db			'o', 0x00
			db			'c', 0x00
			db			'h', 0x00
			db			'i', 0x00
			db			'p', 0x00
			db			' ', 0x00
			db			'T', 0x00
			db			'e', 0x00
			db			'c', 0x00
			db			'h', 0x00
			db			'n', 0x00
			db			'o', 0x00
			db			'l', 0x00
			db			'o', 0x00
			db			'g', 0x00
			db			'y', 0x00
			db			',', 0x00
			db			' ', 0x00
			db			'I', 0x00
			db			'n', 0x00
			db			'c', 0x00
			db			'.', 0x00
String2
			db			Descriptor_end-String2, STRING	; bLength, bDescriptorType
			db			'E', 0x00			; bString
			db			'N', 0x00
			db			'G', 0x00
			db			'R', 0x00
			db			' ', 0x00
			db			'2', 0x00
			db			'2', 0x00
			db			'1', 0x00
			db			'0', 0x00
			db			' ', 0x00
			db			'P', 0x00
			db			'I', 0x00
			db			'C', 0x00
			db			'1', 0x00
			db			'8', 0x00
			db			'F', 0x00
			db			'2', 0x00
			db			'4', 0x00
			db			'5', 0x00
			db			'5', 0x00
			db			' ', 0x00
			db			'U', 0x00
			db			'S', 0x00
			db			'B', 0x00
			db			' ', 0x00
			db			'F', 0x00
			db			'i', 0x00
			db			'r', 0x00
			db			'm', 0x00
			db			'w', 0x00
			db			'a', 0x00
			db			'r', 0x00
			db			'e', 0x00
Descriptor_end

InitUSB
			clrf		UIE, ACCESS				; mask all USB interrupts
			clrf		UIR, ACCESS				; clear all USB interrupt flags
			movlw		0x14
			movwf		UCFG, ACCESS			; configure USB for full-speed transfers and to use the on-chip transciever and pull-up resistor
			movlw		0x08
			movwf		UCON, ACCESS			; enable the USB module and its supporting circuitry
			banksel		USB_curr_config
			clrf		USB_curr_config, BANKED
			clrf		USB_USWSTAT, BANKED		; default to powered state
			movlw		0x01
			movwf		USB_device_status, BANKED
			movlw		NO_REQUEST
			movwf		USB_dev_req, BANKED		; No device requests in process
#ifdef SHOW_ENUM_STATUS
			clrf		TRISB, ACCESS			; set all bits of PORTB as outputs
			movlw		0x01
			movwf		PORTB, ACCESS			; set bit zero to indicate Powered status
#endif
			repeat								; do nothing...
			untilclr UCON, SE0, ACCESS			; ...until initial SE0 condition clears 
			return

ServiceUSB
			select
				caseset	UIR, UERRIF, ACCESS
					clrf		UEIR, ACCESS
					break
				caseset UIR, SOFIF, ACCESS
					bcf			UIR, SOFIF, ACCESS
					break
				caseset	UIR, IDLEIF, ACCESS
					bcf			UIR, IDLEIF, ACCESS
					bsf			UCON, SUSPND, ACCESS
#ifdef SHOW_ENUM_STATUS
					movlw		0xE0
					andwf		PORTB, F, ACCESS
					bsf			PORTB, 4, ACCESS
#endif
					break
				caseset UIR, ACTVIF, ACCESS
					bcf			UIR, ACTVIF, ACCESS
					bcf			UCON, SUSPND, ACCESS
#ifdef SHOW_ENUM_STATUS
					movlw		0xE0
					andwf		PORTB, F, ACCESS
					banksel		USB_USWSTAT
					movf		USB_USWSTAT, W, BANKED
					select
						case POWERED_STATE
							movlw	0x01
							break
						case DEFAULT_STATE
							movlw	0x02
							break
						case ADDRESS_STATE
							movlw	0x04
							break
						case CONFIG_STATE
							movlw	0x08
					ends
					iorwf		PORTB, F, ACCESS
#endif
					break
				caseset	UIR, STALLIF, ACCESS
					bcf			UIR, STALLIF, ACCESS
					break
				caseset	UIR, URSTIF, ACCESS
					banksel		USB_curr_config
					clrf		USB_curr_config, BANKED
					bcf			UIR, TRNIF, ACCESS		; clear TRNIF four times to clear out the USTAT FIFO
					bcf 		UIR, TRNIF, ACCESS
					bcf			UIR, TRNIF, ACCESS
					bcf			UIR, TRNIF, ACCESS
					clrf		UEP0, ACCESS			; clear all EP control registers to disable all endpoints
					clrf		UEP1, ACCESS
					clrf		UEP2, ACCESS
					clrf		UEP3, ACCESS
					clrf		UEP4, ACCESS
					clrf		UEP5, ACCESS
					clrf		UEP6, ACCESS
					clrf		UEP7, ACCESS
					clrf		UEP8, ACCESS
					clrf		UEP9, ACCESS
					clrf		UEP10, ACCESS
					clrf		UEP11, ACCESS
					clrf		UEP12, ACCESS
					clrf		UEP13, ACCESS
					clrf		UEP14, ACCESS
					clrf		UEP15, ACCESS
					banksel		BD0OBC
					movlw		MAX_PACKET_SIZE
					movwf		BD0OBC, BANKED
					movlw		low USB_Buffer			; EP0 OUT gets a buffer...
					movwf		BD0OAL, BANKED
					movlw		high USB_Buffer
					movwf		BD0OAH, BANKED			; ...set up its address
					movlw		0x88					; set UOWN bit (USB can write)
					movwf		BD0OST, BANKED
					movlw		low (USB_Buffer+MAX_PACKET_SIZE)	; EP0 IN gets a buffer...
					movwf		BD0IAL, BANKED
					movlw		high (USB_Buffer+MAX_PACKET_SIZE)
					movwf		BD0IAH, BANKED			; ...set up its address
					movlw		0x08					; clear UOWN bit (MCU can write)
					movwf		BD0IST, BANKED
					clrf		UADDR, ACCESS			; set USB Address to 0
					clrf		UIR, ACCESS				; clear all the USB interrupt flags
					movlw		ENDPT_CONTROL
					movwf		UEP0, ACCESS			; EP0 is a control pipe and requires an ACK
					movlw		0xFF					; enable all error interrupts
					movwf		UEIE, ACCESS
					banksel		USB_USWSTAT
					movlw		DEFAULT_STATE
					movwf		USB_USWSTAT, BANKED
					movlw		0x01
					movwf		USB_device_status, BANKED	; self powered, remote wakeup disabled
#ifdef SHOW_ENUM_STATUS
					movlw		0xE0
					andwf		PORTB, F, ACCESS
					bsf 		PORTB, 1, ACCESS		; set bit 1 of PORTB to indicate Powered state
#endif
					break
				caseset	UIR, TRNIF, ACCESS
					movlw		0x04
					movwf		FSR0H, ACCESS
					movf		USTAT, W, ACCESS
					andlw		0x7C					; mask out bits 0, 1, and 7 of USTAT
					movwf		FSR0L, ACCESS
					banksel		USB_buffer_desc
					movf		POSTINC0, W
					movwf		USB_buffer_desc, BANKED
					movf		POSTINC0, W
					movwf		USB_buffer_desc+1, BANKED
					movf		POSTINC0, W
					movwf		USB_buffer_desc+2, BANKED
					movf		POSTINC0, W
					movwf		USB_buffer_desc+3, BANKED
					movf		USTAT, W, ACCESS
					movwf		USB_USTAT, BANKED		; save the USB status register
					bcf			UIR, TRNIF, ACCESS		; clear TRNIF interrupt flag
#ifdef SHOW_ENUM_STATUS
					andlw		0x18					; extract EP bits
					select
						case EP0
							movlw		0x20
							break
						case EP1
							movlw		0x40
							break
						case EP2
							movlw		0x80
							break
					ends
					xorwf		PORTB, F, ACCESS		; toggle bit 5, 6, or 7 of PORTB to reflect EP activity
#endif
					clrf		USB_error_flags, BANKED	; clear USB error flags
					movf		USB_buffer_desc, W, BANKED
					andlw		0x3C					; extract PID bits
					select
						case TOKEN_SETUP
							call		ProcessSetupToken
							break
						case TOKEN_IN
							call		ProcessInToken
							break
						case TOKEN_OUT
							call		ProcessOutToken
							break
					ends
					banksel USB_error_flags
					ifset USB_error_flags, 0, BANKED	; if there was a Request Error...
						banksel		BD0OBC
						movlw		MAX_PACKET_SIZE
						movwf		BD0OBC				; ...get ready to receive the next Setup token...
						movlw		0x84
						movwf		BD0IST
						movwf		BD0OST				; ...and issue a protocol stall on EP0
					endi
					break
			ends
			return

ProcessSetupToken
			banksel		USB_buffer_data
			movf		USB_buffer_desc+ADDRESSH, W, BANKED
			movwf		FSR0H, ACCESS
			movf		USB_buffer_desc+ADDRESSL, W, BANKED
			movwf		FSR0L, ACCESS
			movf		POSTINC0, W
			movwf		USB_buffer_data, BANKED
			movf		POSTINC0, W
			movwf		USB_buffer_data+1, BANKED
			movf		POSTINC0, W
			movwf		USB_buffer_data+2, BANKED
			movf		POSTINC0, W
			movwf		USB_buffer_data+3, BANKED
			movf		POSTINC0, W
			movwf		USB_buffer_data+4, BANKED
			movf		POSTINC0, W
			movwf		USB_buffer_data+5, BANKED
			movf		POSTINC0, W
			movwf		USB_buffer_data+6, BANKED
			movf		POSTINC0, W
			movwf		USB_buffer_data+7, BANKED
			banksel		BD0OBC
			movlw		MAX_PACKET_SIZE
			movwf		BD0OBC, BANKED					; reset the byte count
			movwf		BD0IST, BANKED					; return the in buffer to us (dequeue any pending requests)
			banksel		USB_buffer_data+bmRequestType
			ifclr USB_buffer_data+bmRequestType, 7, BANKED
				ifl USB_buffer_data+wLength, NE, 0
            	orif USB_buffer_data+wLengthHigh, NE, 0
					movlw		0xC8
				otherwise
					movlw		0x88
				endi
			otherwise
				movlw		0x88
			endi
			banksel		BD0OST
			movwf		BD0OST, BANKED					; set EP0 OUT UOWN back to USB and DATA0/DATA1 packet according to request type
			bcf			UCON, PKTDIS, ACCESS			; assuming there is nothing to dequeue, clear the packet disable bit
			banksel		USB_dev_req
			movlw		NO_REQUEST
			movwf		USB_dev_req, BANKED				; clear the device request in process
			movf		USB_buffer_data+bmRequestType, W, BANKED
			andlw		0x60							; extract request type bits
			select
				case STANDARD
					call		StandardRequests
					break
				case CLASS
					call		ClassRequests
					break
				case VENDOR
					call		VendorRequests
					break
				default
					bsf			USB_error_flags, 0, BANKED	; set Request Error flag
			ends
			return

StandardRequests
			movf		USB_buffer_data+bRequest, W, BANKED
			select
				case GET_STATUS
					movf		USB_buffer_data+bmRequestType, W, BANKED
					andlw		0x1F					; extract request recipient bits
					select
						case RECIPIENT_DEVICE
							banksel		BD0IAH
							movf		BD0IAH, W, BANKED
							movwf		FSR0H, ACCESS
							movf		BD0IAL, W, BANKED				; get buffer pointer
							movwf		FSR0L, ACCESS
							banksel		USB_device_status
							movf		USB_device_status, W, BANKED	; copy device status byte to EP0 buffer
							movwf		POSTINC0
							clrf		INDF0
							banksel		BD0IBC
							movlw		0x02
							movwf		BD0IBC, BANKED					; set byte count to 2
							movlw		0xC8
							movwf		BD0IST, BANKED					; send packet as DATA1, set UOWN bit
							break
						case RECIPIENT_INTERFACE
							movf		USB_USWSTAT, W, BANKED
							select
								case ADDRESS_STATE
									bsf			USB_error_flags, 0, BANKED		; set Request Error flag
									break
								case CONFIG_STATE
									ifl USB_buffer_data+wIndex, LT, NUM_INTERFACES
										banksel		BD0IAH
										movf		BD0IAH, W, BANKED
										movwf		FSR0H, ACCESS
										movf		BD0IAL, W, BANKED				; get buffer pointer
										movwf		FSR0L, ACCESS
										clrf		POSTINC0
										clrf		INDF0
										movlw		0x02
										movwf		BD0IBC, BANKED					; set byte count to 2
										movlw		0xC8
										movwf		BD0IST, BANKED					; send packet as DATA1, set UOWN bit																								
									otherwise
										bsf			USB_error_flags, 0, BANKED		; set Request Error flag
									endi
									break
							ends
							break
						case RECIPIENT_ENDPOINT
							movf		USB_USWSTAT, W, BANKED
							select
								case ADDRESS_STATE
									movf		USB_buffer_data+wIndex, W, BANKED	; get EP
									andlw		0x0F								; strip off direction bit
									ifset STATUS, Z, ACCESS							; see if it is EP0
										banksel		BD0IAH
										movf		BD0IAH, W, BANKED				; put EP0 IN buffer pointer...
										movwf		FSR0H, ACCESS
										movf		BD0IAL, W, BANKED
										movwf		FSR0L, ACCESS					; ...into FSR0
										banksel		USB_buffer_data+wIndex
										ifset USB_buffer_data+wIndex, 7, BANKED		; if the specified direction is IN...
											banksel		BD0IST
											movf		BD0IST, W, BANKED
										otherwise
											banksel		BD0OST
											movf		BD0OST, W, BANKED
										endi
										andlw		0x04							; extract the BSTALL bit
										movwf		INDF0
										rrncf		INDF0, F
										rrncf		INDF0, F						; shift BSTALL bit into the lsb position
										clrf		PREINC0
										movlw		0x02
										movwf		BD0IBC, BANKED					; set byte count to 2
										movlw		0xC8
										movwf		BD0IST, BANKED					; send packet as DATA1, set UOWN bit
									otherwise
										bsf			USB_error_flags, 0, BANKED		; set Request Error flag
									endi
									break
								case CONFIG_STATE
									banksel		BD0IAH
									movf		BD0IAH, W, BANKED					; put EP0 IN buffer pointer...
									movwf		FSR0H, ACCESS
									movf		BD0IAL, W, BANKED
									movwf		FSR0L, ACCESS						; ...into FSR0
									movlw		high UEP0							; put UEP0 address...
									movwf		FSR1H, ACCESS
									movlw		low UEP0
									movwf		FSR1L, ACCESS						; ...into FSR1
									movlw		high BD0OST							; put BDndST address...
									movwf		FSR2H, ACCESS
									banksel		USB_buffer_data+wIndex
									movf		USB_buffer_data+wIndex, W, BANKED
									andlw		0x8F								; mask out all but the direction bit and EP number
									movwf		FSR2L, ACCESS
									rlncf		FSR2L, F, ACCESS
									rlncf		FSR2L, F, ACCESS
									rlncf		FSR2L, F, ACCESS					; FSR2L now contains the proper offset into the BD table for the specified EP
									movlw		low BD0OST
									addwf		FSR2L, F, ACCESS					; ...into FSR2
									ifset STATUS, C, ACCESS
										incf		FSR2H, F, ACCESS
									endi
									movf		USB_buffer_data+wIndex, W, BANKED	; get EP and...
									andlw		0x0F								; ...strip off direction bit
									ifset USB_buffer_data+wIndex, 7, BANKED			; if the specified EP direction is IN...
									andifclr PLUSW1, EPINEN, ACCESS					; ...and the specified EP is not enabled for IN transfers...
										bsf			USB_error_flags, 0, BANKED		; ...set Request Error flag
									elsifclr USB_buffer_data+wIndex, 7, BANKED		; otherwise, if the specified EP direction is OUT...
									andifclr PLUSW1, EPOUTEN, ACCESS				; ...and the specified EP is not enabled for OUT transfers...
										bsf			USB_error_flags, 0, BANKED		; ...set Request Error flag
									otherwise
										movf		INDF2, W						; move the contents of the specified BDndST register into WREG
										andlw		0x04							; extract the BSTALL bit
										movwf		INDF0
										rrncf		INDF0, F
										rrncf		INDF0, F						; shift BSTALL bit into the lsb position
										clrf		PREINC0										
										banksel		BD0IBC
										movlw		0x02
										movwf		BD0IBC, BANKED					; set byte count to 2
										movlw		0xC8
										movwf		BD0IST, BANKED					; send packet as DATA1, set UOWN bit
									endi
									break
								default
									bsf			USB_error_flags, 0, BANKED	; set Request Error flag
							ends
							break
						default
							bsf			USB_error_flags, 0, BANKED	; set Request Error flag
					ends
					break
				case CLEAR_FEATURE
				case SET_FEATURE
					movf		USB_buffer_data+bmRequestType, W, BANKED
					andlw		0x1F					; extract request recipient bits
					select
						case RECIPIENT_DEVICE
							movf		USB_buffer_data+wValue, W, BANKED
							select
								case DEVICE_REMOTE_WAKEUP
									ifl USB_buffer_data+bRequest, EQ, CLEAR_FEATURE
										bcf			USB_device_status, 1, BANKED
									otherwise
										bsf			USB_device_status, 1, BANKED
									endi
									banksel		BD0IBC
									clrf		BD0IBC, BANKED					; set byte count to 0
									movlw		0xC8
									movwf		BD0IST, BANKED					; send packet as DATA1, set UOWN bit
									break
								default
									bsf			USB_error_flags, 0, BANKED		; set Request Error flag
							ends
							break
						case RECIPIENT_ENDPOINT
							movf		USB_USWSTAT, W, BANKED
							select
								case ADDRESS_STATE
									movf		USB_buffer_data+wIndex, W, BANKED	; get EP
									andlw		0x0F								; strip off direction bit
									ifset STATUS, Z, ACCESS							; see if it is EP0
										banksel		BD0IBC
										clrf		BD0IBC, BANKED					; set byte count to 0
										movlw		0xC8
										movwf		BD0IST, BANKED					; send packet as DATA1, set UOWN bit
									otherwise
										bsf			USB_error_flags, 0, BANKED		; set Request Error flag
									endi
									break
								case CONFIG_STATE
									movlw		high UEP0							; put UEP0 address...
									movwf		FSR0H, ACCESS
									movlw		low UEP0
									movwf		FSR0L, ACCESS						; ...into FSR0
									movlw		high BD0OST							; put BD0OST address...
									movwf		FSR1H, ACCESS
									movlw		low BD0OST
									movwf		FSR1L, ACCESS						; ...into FSR1
									movf		USB_buffer_data+wIndex, W, BANKED	; get EP
									andlw		0x0F								; strip off direction bit
									ifclr STATUS, Z, ACCESS							; if it was not EP0...
										addwf		FSR0L, F, ACCESS					; add EP number to FSR0
										ifset		STATUS, C, ACCESS
											incf		FSR0H, F, ACCESS
										endi
										rlncf		USB_buffer_data+wIndex, F, BANKED
										rlncf		USB_buffer_data+wIndex, F, BANKED
										rlncf		USB_buffer_data+wIndex, W, BANKED	; WREG now contains the proper offset into the BD table for the specified EP
										andlw		0x7C								; mask out all but the direction bit and EP number (after three left rotates)
										addwf		FSR1L, F, ACCESS					; add BD table offset to FSR1
										ifset		STATUS, C, ACCESS
											incf		FSR1H, F, ACCESS
										endi
										ifset USB_buffer_data+wIndex, 1, BANKED			; if the specified EP direction (now bit 1) is IN...
											ifset INDF0, EPINEN, ACCESS						; if the specified EP is enabled for IN transfers...
												ifl USB_buffer_data+bRequest, EQ, CLEAR_FEATURE
													clrf		INDF1					; clear the stall on the specified EP
												otherwise
													movlw		0x84
													movwf		INDF1					; stall the specified EP
												endi
											otherwise
												bsf			USB_error_flags, 0, BANKED		; set Request Error flag
											endi
										otherwise										; ...otherwise the specified EP direction is OUT, so...
											ifset INDF0, EPOUTEN, ACCESS					; if the specified EP is enabled for OUT transfers...
												ifl USB_buffer_data+bRequest, EQ, CLEAR_FEATURE
													movlw		0x88
													movwf		INDF1					; clear the stall on the specified EP													
												otherwise
													movlw		0x84
													movwf		INDF1					; stall the specified EP
												endi
											otherwise
												bsf			USB_error_flags, 0, BANKED		; set Request Error flag
											endi
										endi
									endi
									ifclr USB_error_flags, 0, BANKED	; if there was no Request Error...
										banksel		BD0IBC
										clrf		BD0IBC, BANKED			; set byte count to 0
										movlw		0xC8
										movwf		BD0IST, BANKED			; send packet as DATA1, set UOWN bit
									endi
									break
								default
									bsf			USB_error_flags, 0, BANKED	; set Request Error flag
							ends
							break
						default
							bsf			USB_error_flags, 0, BANKED	; set Request Error flag
					ends
					break
				case SET_ADDRESS
					ifset USB_buffer_data+wValue, 7, BANKED		; if new device address is illegal, send Request Error
						bsf			USB_error_flags, 0, BANKED	; set Request Error flag
					otherwise
						movlw		SET_ADDRESS
						movwf		USB_dev_req, BANKED			; processing a SET_ADDRESS request
						movf		USB_buffer_data+wValue, W, BANKED
						movwf		USB_address_pending, BANKED	; save new address
						banksel		BD0IBC
						clrf		BD0IBC, BANKED				; set byte count to 0
						movlw		0xC8
						movwf		BD0IST, BANKED				; send packet as DATA1, set UOWN bit
					endi
					break
				case GET_DESCRIPTOR
					movwf		USB_dev_req, BANKED				; processing a GET_DESCRIPTOR request
					movf		USB_buffer_data+(wValue+1), W, BANKED
					select
						case DEVICE
							movlw		low (Device-Descriptor_begin)
							movwf		USB_desc_ptr, BANKED
							call		Descriptor				; get descriptor length
							movwf		USB_bytes_left, BANKED
							ifl USB_buffer_data+(wLength+1), EQ, 0
							andiff USB_buffer_data+wLength,	LT, USB_bytes_left
								movf		USB_buffer_data+wLength, W, BANKED
								movwf		USB_bytes_left, BANKED
							endi
							call		SendDescriptorPacket
							break
						case CONFIGURATION
							movf		USB_buffer_data+wValue, W, BANKED
							select
								case 0
									movlw		low (Configuration1-Descriptor_begin)
									break
								default
									bsf			USB_error_flags, 0, BANKED	; set Request Error flag
							ends
							ifclr USB_error_flags, 0, BANKED
								addlw		0x02				; add offset for wTotalLength
								movwf		USB_desc_ptr, BANKED
								call		Descriptor			; get total descriptor length
								movwf		USB_bytes_left, BANKED
								movlw		0x02
								subwf		USB_desc_ptr, F, BANKED	; subtract offset for wTotalLength
								ifl USB_buffer_data+(wLength+1), EQ, 0
								andiff USB_buffer_data+wLength, LT, USB_bytes_left
									movf		USB_buffer_data+wLength, W, BANKED
									movwf		USB_bytes_left, BANKED
								endi
								call		SendDescriptorPacket
							endi
							break
						case STRING
							movf		USB_buffer_data+wValue, W, BANKED
							select
								case 0
									movlw		low (String0-Descriptor_begin)
									break
								case 1
									movlw		low (String1-Descriptor_begin)
									break
								case 2
									movlw		low (String2-Descriptor_begin)
									break
								default
									bsf			USB_error_flags, 0, BANKED	; Set Request Error flag
							ends
							ifclr USB_error_flags, 0, BANKED
								movwf		USB_desc_ptr, BANKED
								call		Descriptor		; get descriptor length
								movwf		USB_bytes_left, BANKED
								ifl USB_buffer_data+(wLength+1), EQ, 0
								andiff USB_buffer_data+wLength, LT, USB_bytes_left
									movf		USB_buffer_data+wLength, W, BANKED
									movwf		USB_bytes_left, BANKED
								endi
								call		SendDescriptorPacket
							endi
							break
						default
							bsf			USB_error_flags, 0, BANKED	; set Request Error flag
					ends
					break
				case GET_CONFIGURATION
					banksel		BD0IAH
					movf		BD0IAH, W, BANKED
					movwf		FSR0H, ACCESS
					movf		BD0IAL, W, BANKED
					movwf		FSR0L, ACCESS
					banksel		USB_curr_config
					movf		USB_curr_config, W, BANKED
					movwf		INDF0					; copy current device configuration to EP0 IN buffer
					banksel		BD0IBC
					movlw		0x01
					movwf		BD0IBC, BANKED			; set EP0 IN byte count to 1
					movlw		0xC8
					movwf		BD0IST, BANKED			; send packet as DATA1, set UOWN bit
					break
				case SET_CONFIGURATION
					ifl USB_buffer_data+wValue, LE, NUM_CONFIGURATIONS
						clrf		UEP1, ACCESS		; clear all EP control registers except for EP0 to disable EP1-EP15 prior to setting configuration
						clrf		UEP2, ACCESS
						clrf		UEP3, ACCESS
						clrf		UEP4, ACCESS
						clrf		UEP5, ACCESS
						clrf		UEP6, ACCESS
						clrf		UEP7, ACCESS
						clrf		UEP8, ACCESS
						clrf		UEP9, ACCESS
						clrf		UEP10, ACCESS
						clrf		UEP11, ACCESS
						clrf		UEP12, ACCESS
						clrf		UEP13, ACCESS
						clrf		UEP14, ACCESS
						clrf		UEP15, ACCESS
						movf		USB_buffer_data+wValue, W, BANKED
						movwf		USB_curr_config, BANKED
						select
							case 0
								movlw		ADDRESS_STATE
								movwf		USB_USWSTAT, BANKED
#ifdef SHOW_ENUM_STATUS
								movlw		0xE0
								andwf		PORTB, F, ACCESS
								bsf			PORTB, 2, ACCESS
#endif
								break
							default
								movlw		CONFIG_STATE
								movwf		USB_USWSTAT, BANKED
#ifdef SHOW_ENUM_STATUS
								movlw		0xE0
								andwf		PORTB, F, ACCESS
								bsf			PORTB, 3, ACCESS
#endif
						ends
						banksel		BD0IBC
						clrf		BD0IBC, BANKED			; set byte count to 0
						movlw		0xC8
						movwf		BD0IST, BANKED			; send packet as DATA1, set UOWN bit
					otherwise
						bsf			USB_error_flags, 0, BANKED	; set Request Error flag
					endi
					break
				case GET_INTERFACE
					movf		USB_USWSTAT, W, BANKED
					select
						case CONFIG_STATE
							ifl USB_buffer_data+wIndex, LT, NUM_INTERFACES
								banksel		BD0IAH
								movf		BD0IAH, W, BANKED
								movwf		FSR0H, ACCESS
								movf		BD0IAL, W, BANKED		; get buffer pointer
								movwf		FSR0L, ACCESS
								clrf		INDF0					; always send back 0 for bAlternateSetting
								movlw		0x01
								movwf		BD0IBC, BANKED			; set byte count to 1
								movlw		0xC8
								movwf		BD0IST, BANKED			; send packet as DATA1, set UOWN bit
							otherwise
								bsf			USB_error_flags, 0, BANKED	; set Request Error flag
							endi
							break
						default
							bsf			USB_error_flags, 0, BANKED	; set Request Error flag
					ends
					break
				case SET_INTERFACE
					movf		USB_USWSTAT, W, BANKED
					select
						case CONFIG_STATE
							ifl USB_buffer_data+wIndex, LT, NUM_INTERFACES
								movf		USB_buffer_data+wValue, W, BANKED
								select
									case 0									; currently support only bAlternateSetting of 0
										banksel		BD0IBC
										clrf		BD0IBC, BANKED			; set byte count to 0
										movlw		0xC8
										movwf		BD0IST, BANKED			; send packet as DATA1, set UOWN bit
										break
									default
										bsf			USB_error_flags, 0, BANKED	; set Request Error flag
								ends
							otherwise
								bsf			USB_error_flags, 0, BANKED	; set Request Error flag
							endi
							break
						default
							bsf			USB_error_flags, 0, BANKED	; set Request Error flag
					ends
					break
				case SET_DESCRIPTOR
				case SYNCH_FRAME
				default
					bsf			USB_error_flags, 0, BANKED	; set Request Error flag
					break
			ends
			return

ClassRequests
			movf		USB_buffer_data+bRequest, W, BANKED
			select
				default
					bsf			USB_error_flags, 0, BANKED	; set Request Error flag
			ends
			return

VendorRequests
			movf		USB_buffer_data+bRequest, W, BANKED
			select
				case SET_RA0
					bsf			PORTA, 0, ACCESS		; set RA0 high
					banksel		BD0IBC
					clrf		BD0IBC, BANKED			; set byte count to 0
					movlw		0xC8
					movwf		BD0IST, BANKED			; send packet as DATA1, set UOWN bit
					break
				case CLR_RA0
					bcf			PORTA, 0, ACCESS		; set RA0 low
					banksel		BD0IBC
					clrf		BD0IBC, BANKED			; set byte count to 0
					movlw		0xC8
					movwf		BD0IST, BANKED			; send packet as DATA1, set UOWN bit
					break
				default
					bsf			USB_error_flags, 0, BANKED	; set Request Error flag
			ends
			return

ProcessInToken
			banksel		USB_USTAT
			movf		USB_USTAT, W, BANKED
			andlw		0x18		; extract the EP bits
			select
				case EP0
					movf		USB_dev_req, W, BANKED
					select
						case SET_ADDRESS
							movf		USB_address_pending, W, BANKED
							movwf		UADDR, ACCESS
							select
								case 0
									movlw		DEFAULT_STATE
									movwf		USB_USWSTAT, BANKED
#ifdef SHOW_ENUM_STATUS
									movlw		0xE0
									andwf		PORTB, F, ACCESS
									bsf			PORTB, 1, ACCESS
#endif
									break
								default
									movlw		ADDRESS_STATE
									movwf		USB_USWSTAT, BANKED
#ifdef SHOW_ENUM_STATUS
									movlw		0xE0
									andwf		PORTB, F, ACCESS
									bsf			PORTB, 2, ACCESS
#endif
							ends
							break
						case GET_DESCRIPTOR
							call		SendDescriptorPacket
							break
					ends
					break
				case EP1
					break
				case EP2
					break
			ends
			return

ProcessOutToken
			banksel		USB_USTAT
			movf		USB_USTAT, W, BANKED
			andlw		0x18		; extract the EP bits
			select
				case EP0
					banksel		BD0OBC
					movlw		MAX_PACKET_SIZE
					movwf		BD0OBC, BANKED
					movlw		0x88
					movwf		BD0OST, BANKED
					clrf		BD0IBC, BANKED		; set byte count to 0
					movlw		0xC8
					movwf		BD0IST, BANKED		; send packet as DATA1, set UOWN bit
					break
				case EP1
					break
				case EP2
					break
			ends
			return

SendDescriptorPacket
			banksel		USB_bytes_left
			ifl USB_bytes_left, LT, MAX_PACKET_SIZE
				movlw		NO_REQUEST
				movwf		USB_dev_req, BANKED		; sending a short packet, so clear device request
				movf		USB_bytes_left, W, BANKED
			otherwise
				movlw		MAX_PACKET_SIZE
			endi
			subwf		USB_bytes_left, F, BANKED
			movwf		USB_packet_length, BANKED
			banksel		BD0IBC
			movwf		BD0IBC, BANKED			; set EP0 IN byte count with packet size
			movf		BD0IAH, W, BANKED		; put EP0 IN buffer pointer...
			movwf		FSR0H, ACCESS
			movf		BD0IAL, W, BANKED
			movwf		FSR0L, ACCESS			; ...into FSR0
			banksel		USB_loop_index
			forlf USB_loop_index, 1, USB_packet_length
				call		Descriptor			; get next byte of descriptor being sent
				movwf		POSTINC0			; copy to EP0 IN buffer, and increment FSR0
				incf		USB_desc_ptr, F, BANKED	; increment the descriptor pointer
			next USB_loop_index
			banksel		BD0IST
			movlw		0x40
			xorwf		BD0IST, W, BANKED		; toggle the DATA01 bit
			andlw		0x40					; clear the PIDs bits
			iorlw		0x88					; set UOWN and DTS bits
			movwf		BD0IST, BANKED
			return

APPLICATION	code
Main
			clrf		PORTA, ACCESS
			movlw		0x0F
			movwf		ADCON1, ACCESS			; set up PORTA to be digital I/Os
			clrf		TRISA, ACCESS			; set up all PORTA pins to be digital outputs
			call		InitUSB					; initialize the USB registers and serial interface engine
			repeat
				call		ServiceUSB			; service USB requests...
				banksel		USB_USWSTAT
			until USB_USWSTAT, EQ, CONFIG_STATE	; ...until the host configures the peripheral
			bsf			PORTA, 0, ACCESS		; set RA0 high
			banksel		COUNTER_L
			clrf		COUNTER_L, BANKED
			clrf		COUNTER_H, BANKED
			repeat
				banksel		COUNTER_L
				incf		COUNTER_L, F, BANKED
				ifset STATUS, Z, ACCESS
					incf		COUNTER_H, F, BANKED
				endi
				ifset COUNTER_H, 7, BANKED
					bcf			PORTA, 1, ACCESS
				otherwise
					bsf			PORTA, 1, ACCESS
				endi
				call		ServiceUSB
			forever

			end
