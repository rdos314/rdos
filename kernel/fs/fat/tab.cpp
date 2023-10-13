/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# tab.cpp
# Fat table base class
#
########################################################################*/

#include "tab.h"

/*##########################################################################
#
#   Name       : TFatTable::TFatTable
#
#   Purpose....: Fat table constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatTable::TFatTable(TPartServer *Server)
 :  FReq(Server)
{
    FAllocateCluster = 2;
    FSectorsPerCluster = 0;
    FStartSector = 0;
    FClusters = 0;
    FWrite = false;
}

/*##########################################################################
#
#   Name       : TFatTable::~TFatTable
#
#   Purpose....: Fat table destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFatTable::~TFatTable()
{
}

/*##########################################################################
#
#   Name       : TFatTable::SetAllocateCluster
#
#   Purpose....: Set start of allocation cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFatTable::SetAllocateCluster(unsigned int Cluster)
{
    FAllocateCluster = Cluster;
}

/*##########################################################################
#
#   Name       : TFatTable::IsFree
#
#   Purpose....: Check if cluster is free
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFatTable::IsFree(unsigned int Cluster)
{
    if (GetClusterLink(Cluster))
        return false;
    else
        return true;
}
