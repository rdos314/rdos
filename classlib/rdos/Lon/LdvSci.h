/*
 * Filename: LdvSci.h
 *
 * Description:  This file contains the enumerations and types required 
 * for the ARM7 ShortStack SCI driver to interface with a ShortStack Micro Server.
 *
 * Copyright (c) Echelon Corporation 2008.  All rights reserved.
 *
 * This file is Example Software as defined in the Software
 * License Agreement that governs its use.
 *
 * ECHELON MAKES NO REPRESENTATION, WARRANTY, OR CONDITION OF
 * ANY KIND, EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE OR IN
 * ANY COMMUNICATION WITH YOU, INCLUDING, BUT NOT LIMITED TO,
 * ANY IMPLIED WARRANTIES OF MERCHANTABILITY, SATISFACTORY
 * QUALITY, FITNESS FOR ANY PARTICULAR PURPOSE, 
 * NONINFRINGEMENT, AND THEIR EQUIVALENTS.
 */

#ifndef LDV_SCI_H
#define LDV_SCI_H


#include "ShortStackDev.h"
#include "ShortStackApi.h"

/******************************************************************************************
 * Define the driver's receive/transmit buffer size and count.
 *
 * LDV_RXBUFSIZE must be no less than the maximum size of possible uplink messages.
 * Choose the value according to the following formular:
 *
 *    LDV_RXBUFSIZE = minimum(input application buffer size on shortStack Micro Server,
 *                            message_size + 5 bytes of system overhead)
 *
 * If explicit addressing is used, add an additional 11 bytes of system overhead.
 *
 * For explicit messages, message_size equals 1 bytes for the message code plus the
 * number of data. For the network variables, message_size equals 2 bytes plus the 
 * number of bytes in the network variable.
 *
 * FYI: If the host application doesn't use explicit message and explicit addressing
 *        is off on the ShortStack Micro Server, configure LDV_RXBUFSIZE:
 *        
 *            LDV_RXBUFSIZE = (7+maxixum NV size in bytes)
 *        
 * LDV_TXBUFSIZE must be no less than the maximum size of possible downlink messages
 * and no more than output application buffer size defined on the ShortStack Micro Server.
 * Use the same formular above to determine the appropriate size.
 *
 * FYI: If the host application is to support LonTalk FTP, match driver's receive/transmit
 *        buffer size with input/output application buffer size defined on the ShortStack
 *        Micro Server respectively. (To support FTP, the host application will need to exploit
 *        explicit addressed explicit messages.)
 *******************************************************************************************/
#define LDV_RXBUFSIZE           LON_APP_INPUT_BUFSIZE
#define LDV_TXBUFSIZE           LON_APP_OUTPUT_BUFSIZE
#define LDV_RXBUFCOUNT          5
#define LDV_TXBUFCOUNT          5

/* The following literal selects the bit rate of the SCI communication        
 * interface on the host processor. The following table gives the bit rate    
 * selection for the ARM7 processor running on the Pyxos EV-Pilot board       
 *                                                                            
 * SS_BAUD_RATE           SCI(bps)                                            
 *        0                76 800 (default)                                   
 *        1                 9 600                                             
 *                                                                            
 * Note : The value for this literal must match the actual bit rate defined   
 *         for the ShortStack Micro Server.                                   
 */
#define SS_BAUD_RATE            0

/*
 * Specify timeout value for the receiver, and the wakeup time value 
 * for the driver. MUST adjust these values according to actual SCI baud rate.
 * Typically, set LDV_RXTIMEOUT equal to 160 times of bit time (16 bytes including 
 * start and stop bits), and LDV_DRVWAKEUPTIME a whole message time.
 * Note that these timeouts are in milliseconds.
 */
#define LDV_RXTIMEOUT       2
#define LDV_DRVWAKEUPTIME       255 

/*
 * Specify the keepalive timeout value for the serial link.
 * If there is no activity on the serial lines for an extended period of time, 
 * the driver will nudge the Micro Server to tell it that the host is still active. 
 * This isn't required by the Micro Server, but may be required by the underlying 
 * hardware (e.g., RS-232 chip)
 * Note that this timeout is in milliseconds.
 */
#define LDV_KEEPALIVETIMEOUT    20000

/*
 * Specify the put message blocking timeout value for the serial link.
 * If the driver is unable to send the message downlink for this timeout value
 * it assumes that the Micro Server isn't in a position to receive the message,
 * possibly because it is stuck or not present at all. 
 * Note that this timeout is in milliseconds.
 */
#define LDV_PUTMSGTIMEOUT       60000

/*
 * Define the ARM7 pins used for SCI communication.
 */
// #define SBR0                    AT91C_PIO_PA0
// #define SBR1                    AT91C_PIO_PA1
// #define HRDY                    AT91C_PIO_PA2
// #define RXD                     AT91C_PA5_RXD0
// #define TXD                     AT91C_PA6_TXD0
// #define RTS                     AT91C_PA7_RTS0
// #define CTS                     AT91C_PA8_CTS0
// #define NEURON_RESET            AT91C_PIO_PA23

// #define COM0                    (AT91C_BASE_US0)    /* Using USART0 channel of the ARM7 */
// #define CSR                     (COM0->US_CSR)      /* Status register */
// #define IMR                     (COM0->US_IMR)      /* Interrupt mask register */

// #define CHECK_CTS_DEASSERTED()  (AT91F_PIO_IsInputSet(AT91C_BASE_PIOA, CTS))    
// #define CHECK_CTS_ASSERTED()    (!CHECK_CTS_DEASSERTED())                       

// #define DEASSERT_RTS()          (AT91F_PIO_SetOutput(AT91C_BASE_PIOA, RTS))     
// #define ASSERT_RTS()            (AT91F_PIO_ClearOutput(AT91C_BASE_PIOA, RTS))   
// #define CHECK_RTS_DEASSERTED()  (AT91F_PIO_IsOutputSet(AT91C_BASE_PIOA, RTS))   

// #define DEASSERT_HRDY()         (AT91F_PIO_SetOutput(AT91C_BASE_PIOA, HRDY))    
// #define ASSERT_HRDY()           (AT91F_PIO_ClearOutput(AT91C_BASE_PIOA, HRDY))  

// #define ENABLE_RX_INT()         (AT91F_US_EnableIt(COM0, AT91C_US_RXRDY | AT91C_US_OVRE | AT91C_US_FRAME | AT91C_US_PARE))        
// #define DISABLE_RX_INT()        (AT91F_US_DisableIt(COM0, AT91C_US_RXRDY | AT91C_US_OVRE | AT91C_US_FRAME | AT91C_US_PARE))        

// #define ENABLE_TX_INT()         (AT91F_US_EnableIt(COM0, AT91C_US_TXRDY))                    
// #define DISABLE_TX_INT()        (AT91F_US_DisableIt(COM0, AT91C_US_TXRDY))                   

/* SCI transmitter state    */
typedef enum LdvTxStates
{
    LdvTxIdle       = 0,    /* Transmitter is idle */
    LdvTxCmd,               /* The command byte needs to be transmitted */
    LdvTxHandShake,         /* Need to perform another handshake */
    LdvTxInfo_1,            /* The first info byte needs to be transmitted */
    LdvTxInfo_2,            /* The second info byte needs to be transmitted */
    LdvTxPayload,           /* Transmitter is in the middle of sending the message payload */
    LdvTxDone               /* Have completed sending the entire message */
} LdvTxStates;

/* SCI receiver state    */
typedef enum LdvRxStates
{
    LdvRxIdle       = 0,    /* Receiver is idle */
    LdvRxPayload,           /* The length byte has been received, waiting for the rest of the message */
    LdvRxIgnore             /* Ignore the rest of the message */
} LdvRxStates;

/* Serial driver state    */
typedef enum LdvDriverState
{
    LdvDriverSleep   = 0,        /* The driver is disabled */
    LdvDriverNormal  = 1         /* The driver is ready to receive and transmit messages */
} LdvDriverState;

/* Serial driver status    */
typedef struct LdvDriverStatus
{
    LdvDriverState      DriverState;
    LdvRxStates         RxState;
    unsigned char             RxBufferReadyIndex;     /* Receive buffer index which contains an incoming message */
    unsigned char             RxBufferReceiveIndex;   /* Receive buffer index which is in the process of receiving 
                                                 * an incoming message */
    unsigned char             RxNextFree;             /* Position into the receive buffer where the next incoming
                                                 * byte will be stored */
    unsigned char             RxPayloadLen;           /* Size of the incoming message payload */
    LdvTxStates         TxState;
    LdvTxStates         TxNextState;
    unsigned char             TxBufferEmptyIndex;     /* Transmit buffer index which is empty */
    unsigned char             TxBufferTransmitIndex;  /* Transmit buffer index which is in the process of
                                                 * transmitting an outgoing message */
    unsigned char             TxNextChar;             /* Position into the transmit buffer where the next byte to be
                                                 * transmitted is stored */
    unsigned char             TxPayloadLen;           /* Size of the outgoing message payload */
    const unsigned char*      pTxMsg;                 /* Pointer to the message being transmitted or to be transmitted */
    unsigned char             RxTimeout;              /* Receiver timer. If the receiver timer expires while waiting
                                                 * for an incoming message, abort the ongoing receive transaction
                                                 * and reset the SCI */
    unsigned char             DrvWakeupTime;          /* A period of time the driver waits before bringing the SCI back
                                                 * to normal after resetting the SCI */
    unsigned long          KeepAliveTimeout;       /* Keep-alive timer. If there is no activity on the serial lines for
                                                 * an extended period of time, nudge the Micro Server to tell it that the 
                                                 * host is still active. This isn't required by the Micro Server, but
                                                 * may be required by the underlying hardware (e.g., RS-232 chip) */
    unsigned long          PutMsgTimeout;          /* Put message blocking timeout. */
} LdvDriverStatus;

/* Receive buffer state    */
typedef enum LdvRxBufferState
{
    LdvRxBufferEmpty,        /* Buffer is empty */
    LdvRxBufferReceiving,    /* Buffer is being used by driver for receiving */
    LdvRxBufferReady,        /* Buffer is ready for processing */
    LdvRxBufferProcessing    /* Buffer is being processed by the API */
} LdvRxBufferState;

/* Definition of receive buffer    */
typedef struct LdvSysRxBuffer
{
    LdvRxBufferState    State;
    unsigned char             Data[LDV_RXBUFSIZE];
} LdvSysRxBuffer;

/* Transmit buffer state    */
typedef enum LdvTxBufferState
{
    LdvTxBufferEmpty,        /* Buffer is empty */
    LdvTxBufferFilling,      /* Buffer is being filled by the API */
    LdvTxBufferReady,        /* Buffer is ready for transmitting */
    LdvTxBufferTransmitting  /* Buffer is being transmitted by the driver */
} LdvTxBufferState;

/* Definition of transmit buffer    */
typedef struct LdvSysTxBuffer
{
    LdvTxBufferState    State;
    unsigned char             Data[LDV_TXBUFSIZE];
} LdvSysTxBuffer;

/* Types of index used for incrementing. See function CyclicIncrement */
typedef enum LdvIndexType
{
    LdvIndexRxBufferReady,
    LdvIndexRxBufferReceive,
    LdvIndexTxBufferEmpty,
    LdvIndexTxBufferTransmit
} LdvIndexType;

#endif
