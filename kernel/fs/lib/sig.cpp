/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# sigdev.cpp
# Signal device class
#
########################################################################*/

#include <string.h>
#include "sig.h"

#include <rdos.h>

/*##########################################################################
#
#   Name       : TSignal::TSignal
#
#   Purpose....: Constructor for TSignal                                    
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSignal::TSignal()
{
    Init();
}

/*##########################################################################
#
#   Name       : TSignal::~TSignal
#
#   Purpose....: Destructor for TSignal                                     
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSignal::~TSignal()
{
    RdosFreeSignal(FHandle);
}

/*##########################################################################
#
#   Name       : TSignal::Init
#
#   Purpose....: Init method for class
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSignal::Init()
{
    FHandle = RdosCreateSignal();
}

/*##########################################################################
#
#   Name       : TSignal::Add
#
#   Purpose....: Add object to wait
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSignal::Add(TWait *Wait)
{
    if (FHandle)
        RdosAddWaitForSignal(Wait->GetHandle(), FHandle, (int)this);
}

/*##########################################################################
#
#   Name       : TSignal::Clear
#
#   Purpose....: Clear
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSignal::Clear()
{
    RdosResetSignal(FHandle);
}

/*##########################################################################
#
#   Name       : TSignal::IsSignalled
#
#   Purpose....: Check if signalled
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSignal::IsSignalled()
{
    return RdosIsSignalled(FHandle);
}

/*##########################################################################
#
#   Name       : TSignal::Signal
#
#   Purpose....: Signal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSignal::Signal()
{
    RdosSetSignal(FHandle);
}

/*##########################################################################
#
#   Name       : TSignal::SignalNewData
#
#   Purpose....: Signal new data is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSignal::SignalNewData()
{
}
