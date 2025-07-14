/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
