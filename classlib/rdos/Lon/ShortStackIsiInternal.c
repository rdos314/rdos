/*
 * Filename: ShortStackIsiInternal.c
 *
 * Description: This file contains the implementation for internal
 * functions used by the ShortStack ISI API.
 *
 * Copyright (c) Echelon Corporation 2008-2009.  All rights reserved.
 *
 * This file is ShortStack LonTalk Compact API Software as defined in the 
 * Software License Agreement that governs its use.
 *
 * ECHELON MAKES NO REPRESENTATION, WARRANTY, OR CONDITION OF
 * ANY KIND, EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE OR IN
 * ANY COMMUNICATION WITH YOU, INCLUDING, BUT NOT LIMITED TO,
 * ANY IMPLIED WARRANTIES OF MERCHANTABILITY, SATISFACTORY
 * QUALITY, FITNESS FOR ANY PARTICULAR PURPOSE, 
 * NONINFRINGEMENT, AND THEIR EQUIVALENTS.
 */

#include <string.h>

#include "ShortStackDev.h"
#include "ShortStackIsiApi.h"
#include "ShortStackApi.h"

static LonByte IsiSequenceNumber = 0x80;

/*
 * Internal functions 
 */
LonApiError SendDownlinkRpc(IsiDownlinkRpcCode code, LonByte param1, LonByte param2, void* pData, unsigned len);
void HandleDownlinkRpcAck(IsiRpcMessage* pMsg, LonBool bSuccess);
void HandleUplinkRpc(IsiRpcMessage* pMsg);

/*
 * SendDownlinkRpc
 *
 * This function handles making an ISI call down to the Micro Server.
 * It returns an error if a buffer can't be allocated.
 */
LonApiError SendDownlinkRpc(IsiDownlinkRpcCode code, LonByte param1, LonByte param2, void* pData, unsigned len)
{
    LonApiError result = LonApiNoError;
    IsiRpcMessage* pMsg;

    if (LdvAllocateMsg((LonSmipMsg**)&pMsg) != LonApiNoError)
        result = LonApiTxBufIsFull;
    else 
    {
        memset(pMsg, 0, sizeof(IsiRpcMessage));

        pMsg->Header.Command    = LonIsiCmd;
        pMsg->RpcCode           = code;
        pMsg->SequenceNumber    = IsiSequenceNumber ++;
        pMsg->Parameters[0]     = param1;
        pMsg->Parameters[1]     = param2;
        pMsg->RpcData.Length    = len;
        pMsg->Header.Length     = IsiRpcMessageLength(pMsg);
        if (len  &&  pData != NULL)
            memcpy(&pMsg->RpcData.Data, pData, len);
        LdvPutMsg((LonSmipMsg*) pMsg);
    }   
    return result;
}

/*
 * HandleDownlinkRpcAck
 */
void HandleDownlinkRpcAck(IsiRpcMessage* pMsg, LonBool bSuccess)
{
    LonByte param1 = pMsg->Parameters[0];
    LonByte param2 = pMsg->Parameters[1];

    if (bSuccess) 
    {
        switch (pMsg->RpcCode) 
        {
            case IsiRpcIsConnected: 
            {
                IsiIsConnectedReceived(param1, param2);
                break;
            }
            
            case IsiRpcImplementationVersion: 
            {
                IsiImplementationVersionReceived(param1);
                break;
            }
            
            case IsiRpcProtocolVersion: 
            {
                IsiProtocolVersionReceived(param1);
                break;
            }
            
            case IsiRpcIsRunning: 
            {
                IsiIsRunningReceived(param1);
                break;
            }

            case IsiRpcIsBecomingHost: 
            {
                IsiIsBecomingHostReceived(param1, param2);
                break;
            }
        }
    }
    IsiApiComplete((IsiDownlinkRpcCode) pMsg->RpcCode, pMsg->SequenceNumber, bSuccess);
}

/*
 * HandleUplinkRpc
 *
 * This routine handles the callbacks from the Micro Server to 
 * the host.  It handles all the byte swapping for the user.
 * All the routines are passed two 1 byte parameters and a single
 * data structure (or null).  All return one 1 byte value and a single data
 * structure (or null).
 */
void HandleUplinkRpc(IsiRpcMessage* pMsg)
{
    LonByte returnValue = 0;
    LonSmipCmd returnCommand = LonIsiAck;
    LonByte param1 = pMsg->Parameters[0];
    LonByte param2 = pMsg->Parameters[1];
    IsiRpcMessage* pResp;
    
    if (!(pMsg->RpcCode & IsiRpcUnacknowledged)) 
    {
        /* If a response needs to be send, we need to make sure that we send it
           because there isn't a retry mechanism built into the Micro Server.
           So, if a transmit buffer is not available in the driver, keep calling 
           LonEventHandler() which will process both incoming and outgoing
           messages and help freeing up transmit buffers.
         */
        while (LdvAllocateMsg((LonSmipMsg**)&pResp) != LonApiNoError)
            LonEventHandler();
        memset(pResp, 0, sizeof(IsiRpcMessage));
    }

    switch (pMsg->RpcCode) 
    {
        #ifdef ISI_HOST_CREATEPERIODICMSG
        case IsiRpcCreatePeriodicMsg:
            returnValue = IsiCreatePeriodicMsg();
            break;
        #endif

        #ifdef ISI_HOST_UPDATEUSERINTERFACE
        case IsiRpcUpdateUserInterface:
            IsiUpdateUserInterface((IsiEvent) param1, param2);
            break;
        #endif

        #ifdef ISI_HOST_CREATECSMO
        case IsiRpcCreateCsmo:
        {
            IsiCsmoData csmo;
            IsiCreateCsmo(param1, &csmo);
            memcpy(pResp->RpcData.Data, &csmo, sizeof(IsiCsmoData));
            pResp->RpcData.Length = sizeof(IsiCsmoData);
            break;
        }
        #endif

        #ifdef ISI_HOST_GETPRIMARYGROUP
        case IsiRpcGetPrimaryGroup:
            returnValue = IsiGetPrimaryGroup(param1);
            break;
        #endif

        #ifdef ISI_HOST_GETASSEMBLY
        case IsiRpcGetAssembly: 
            returnValue = IsiGetAssembly((IsiCsmoData*) &((pMsg->RpcData).Data), param1);
            break;
        #endif

        #ifdef ISI_HOST_GETNEXTASSEMBLY
        case IsiRpcGetNextAssembly: 
            returnValue = IsiGetNextAssembly((IsiCsmoData*) &(pMsg->RpcData.Data), param1, param2);
            break;
        #endif

        #ifdef ISI_HOST_GETNVINDEX
        case IsiRpcGetNvIndex:
            returnValue = IsiGetNvIndex(param1, param2);
            break;
        #endif

        #ifdef ISI_HOST_GETNEXTNVINDEX
        case IsiRpcGetNextNvIndex:
            returnValue = IsiGetNextNvIndex(param1, param2, pMsg->RpcData.Data[0]);
            break;
        #endif

        #ifdef ISI_HOST_GETPRIMARYDID
        case IsiRpcGetPrimaryDid:
        {
            const LonByte* p;
            p = (LonByte*) IsiGetPrimaryDid((unsigned*) &returnValue);
            memcpy(&(pResp->RpcData.Data), p, returnValue);
            pResp->RpcData.Length = returnValue;
            break;
        }
        #endif

        #ifdef ISI_HOST_GETWIDTH
        case IsiRpcGetWidth:
            returnValue = IsiGetWidth(param1);
            break;
        #endif

        case IsiRpcGetNvValue:
        {
            const void* p;
            p = IsiGetNvValue(param1, &returnValue);
            memcpy(&(pResp->RpcData.Data), p, returnValue);
            pResp->RpcData.Length = returnValue;
            break;
        }
        
        #ifdef ISI_HOST_CONNECTIONTABLE
        case IsiRpcGetConnTabSize:
            returnValue = IsiGetConnectionTableSize();
            break;
        
        case IsiRpcGetConnection:
        {
            const LonByte* p;
            p = (LonByte*) IsiGetConnection(param1);
            memcpy(&(pResp->RpcData.Data), p, sizeof(IsiConnection));
            pResp->RpcData.Length = sizeof(IsiConnection);
            break;
        }
        
        case IsiRpcSetConnection: 
            IsiSetConnection((IsiConnection*) &(pMsg->RpcData.Data), param1);
            break;
        #endif
            
        #ifdef ISI_HOST_QUERYHEARTBEAT
        case IsiRpcQueryHeartbeat:
            returnValue = IsiQueryHeartbeat(param1);
            break;
        #endif

        #ifdef ISI_HOST_GETREPEATCOUNT
        case IsiRpcGetRepeatCount:
            returnValue = IsiGetRepeatCount();
            break;
        #endif
            
        case IsiRpcUserCommand:
            returnValue = IsiUserCommand(param1, param2, (pMsg->RpcData).Data, (pMsg->RpcData).Length);
            if (returnValue == 0xFF)
                returnCommand = LonIsiNack;
            break;

        default: 
            returnCommand = LonIsiNack;
            break;
    }

    /*
     * Send a response if necessary.  Note that if the response can't be sent,
     * we simply drop it.  It is up to the ShortStack Micro Server to retry.
     */
    if (!(pMsg->RpcCode & IsiRpcUnacknowledged)) 
    {
        pResp->Header.Command = returnCommand;
        pResp->RpcCode = pMsg->RpcCode;
        pResp->SequenceNumber = pMsg->SequenceNumber;
        pResp->Parameters[0] = returnValue;
        pResp->Header.Length = IsiRpcMessageLength(pResp);
        LdvPutMsg((LonSmipMsg*) pResp);
    }
}
