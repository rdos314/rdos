/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2006, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# datastor.h
# Datastore class
#
########################################################################*/

#ifndef DATASTOR_H
#define DATASTOR_H

#include "device.h"
#include "file.h"
#include "bindata.h"

class TDataStore : public TThread
{
public:
	TDataStore(const char *RootDir, const char *ServerName, long ServerIp, int ServerPort);
	~TDataStore();

    void (*NotifyData)(TDeviceMsg *doc);
    
protected:
    virtual void Execute();

    void CreateRootDir();
	 TFile *CreateDayFile(int year, int month, int day);
	 void HandleMsg(TDeviceMsg *doc);

    char FRootDir[256];
    long FServerIp;
    int FServerPort;

    TBinData FBin;
    int FCurrYear;
    int FCurrMonth;
    int FCurrDay;

};

#endif
