/*###########################################################################
* RDOS operating system
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
* VIDEO.H
* Video emulation
*
*##########################################################################*/

#ifndef	_VIDEO_H
#define _VIDEO_H

#include "bus.h"

class TVideo : public TBusFunction
{
public:
	TVideo(TBus *Bus);
	~TVideo();

	virtual int GetSize();

    virtual void WriteMemoryByte(int Num, unsigned long Offset, char val);
    virtual void WriteMemoryWord(int Num, unsigned long Offset, short int val);
    virtual void WriteMemoryDword(int Num, unsigned long Offset, long val);
    virtual void WriteMemoryQword(int Num, unsigned long Offset, long long val);

    char *GetRow(int Row);

    void (*OnTextChange)(TVideo *Video, int Row);

private:
	char *FData;
};

#endif
