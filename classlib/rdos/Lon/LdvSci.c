/*
 *  Filename: LdvSci.c
 *
 *  Description:  This file contains the ARM7 ShortStack SCI driver 
 *  implementation to interface with a ShortStack Micro Server.
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

// #include "Processor.h"
#include "malloc.h"
#include "LonPlatform.h"
#include "LdvSci.h"



/*
 * Function: LdvInit
 * Initialize the serial driver.
 * 
 * Remarks:
 * This function is called to initialize the serial driver.
 * Previously named ldv_init.
 */
void LdvInit(void) 
{

 

}


void LdvReset(void) 
{

}

/*
 * Function: LdvGetMsg
 * Gets an incoming message from the serial driver.
 *
 * Parameters:
 * ppMsg - pointer to the transmit buffer pointer that contains the incoming 
 * message.
 *
 * Returns:
 * <LonApiError> - LonApiNoError if a message is available and was successfully 
 *                 returned, an appropriate error code, otherwise.
 *
 * Remarks:
 * This function gets an incoming message from the serial driver.
 * Note that the caller has a pointer into the driver memory upon a successful
 * return from the call. The caller must free the memory to the driver later 
 * by calling <LdvReleaseMsg>. 
 * Previously named ldv_get_msg.
 */
 
 

LonApiError LdvGetMsg(LonSmipMsg **ppMsg)
{
    LonApiError result = LonApiNoError;


    return result;
}

/*
 * Function: LdvReleaseMsg
 * Releases a message buffer back to the serial driver.
 *
 * Parameters:
 * pMsg - pointer to the message buffer to be released.
 *
 * Remarks:
 * This function releases a message buffer back to the serial driver.
 * Note that the driver assumes that upon return, the memory pointed 
 * to by *pMsg* has been returned to the driver. Therefore, the caller 
 * must not use this memory anymore.
 * Previously named ldv_release_msg.
 */
void LdvReleaseMsg(const LonSmipMsg *pMsg)
{
 
    
}

/*
 * Function: LdvAllocateMsg
 * Allocates a transmit buffer from the serial driver.
 *
 * Parameters:
 * ppMsg - pointer to the transmit buffer pointer that will be returned.
 *
 * Returns:
 * <LonApiError> - LonApiNoError if the message was successfully allocated, 
 *                 an appropriate error code, otherwise.
 *
 * Remarks:
 * This function allocates a transmit buffer from the serial driver.
 * Note that the caller has a pointer into the driver memory upon a successful
 * return from the call. The caller must free the memory to the driver later 
 * by calling <LdvPutMsg>. 
 * Previously named ldv_allocate_msg.
 */
LonApiError LdvAllocateMsg(LonSmipMsg **ppMsg)
{
    LonApiError result = LonApiNoError;
    unsigned char* buffer = malloc(255);
    *ppMsg = (LonSmipMsg *) buffer;
    return result;
}

/*
 * Function: LdvPutMsg
 * Sends a message downlink.
 *
 * Parameters:
 * pMsg - pointer to the message that will be sent.
 *
 * Remarks:
 * This function sends a message downlink. The message must have been allocated
 * from the transmit buffer using <LdvAllocateMsg>. Note that the driver assumes
 * that upon return, the memory pointed to by *pMsg* has been returned to 
 * the driver. Therefore, the caller must not use this memory anymore.
 * Previously named ldv_put_msg.
 */
void LdvPutMsg(const LonSmipMsg* pMsg)
{

}

/*
 * Function: LdvPutMsgBlocking
 * Sends a message downlink using a blocking call.
 *
 * Parameters:
 * pMsg - pointer to the message that will be sent.
 *
 * Returns:
 * <LonApiError> - LonApiNoError if the message was successfully sent, 
 *                 an appropriate error code, otherwise.
 *
 * Remarks:
 * This function sends a message downlink without allocating a transmit buffer 
 * from the serial driver. Note that this function blocks until the driver 
 * completes transmitting the message pointed to by *pMsg*. This function is 
 * typically used to send the initialization messages to the Micro Server.
 * Previously named ldv_put_msg_init.
 */
LonApiError LdvPutMsgBlocking(const LonSmipMsg* pMsg)
{
    LonApiError result;
    return result;
}

/*
 * Function: LdvFlushMsgs
 * Complete pending transmissions.
 *
 * Remarks:
 * This function must be called during the idle loop to complete pending 
 * transmissions.
 * Previously named ldv_flush_msgs.
 */
void LdvFlushMsgs(void)
{

}
