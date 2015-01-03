/*###########################################################################
* Em486 CPU emulator
* Copyright (C) 1998-2000, Leif Ekblad
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version. The only exception to this rule
* is for commercial usage. For information on commercial usage,
* contact em486@rdos.net.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*
* The author of this program may be contacted at leif@rdos.net
*
* EMDISP.CPP
* Remote display for simulator
*
*##########################################################################*/

#include <rdos.h>
#include <stdio.h>
#include "dispmsg.h"

char FocusKey;

/*##################  HandleFocus  ###############
*   Purpose....: Handle focus req                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void HandleFocus()
{
    RdosReplyMailslot(&FocusKey, 1);
}

/*##################  HandleVideo  ###############
*   Purpose....: Handle video req                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void HandleVideo(struct TVideoReq *req)
{
    RdosWriteAttributeString(req->Row, 0, req->Data, 80);
    RdosReplyMailslot("", 0);
}

/*##################  main  ###############
*   Purpose....: main                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void main(void)
{
    char *msg = new char[0x1000];
    int size;
    struct TBaseReq *BaseReq = (struct TBaseReq *)msg;

    FocusKey = RdosGetFocus();

    RdosDefineMailslot("emdisp", 0x1000);

    RdosWriteString("Remote screen");

    for (;;)
    {
        size = RdosReceiveMailslot(msg);
        if (size >= 4)
        {
            switch (BaseReq->MsgType)
            {
                case DISP_MSG_FOCUS:
                    HandleFocus();
                    break;

                case DISP_MSG_VIDEO:
                    HandleVideo((struct TVideoReq *)msg);
                    break;

                default:
                    RdosReplyMailslot(msg, 0);
                    break;
            }
        }
        else
            RdosReplyMailslot(msg, 0);
    }        
}
