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
# cluster.cpp
# Cluster chain class
#
########################################################################*/

#include <string.h>
#include <rdos.h>
#include <serv.h>
#include "cluster.h"

/*##########################################################################
#
#   Name       : TCluster::TCluster
#
#   Purpose....: Cluster chain constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCluster::TCluster()
{
}

/*##########################################################################
#
#   Name       : TCluster::~TCluster
#
#   Purpose....: Cluster destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCluster::~TCluster()
{
}

/*##########################################################################
#
#   Name       : TCluster::Add
#
#   Purpose....: Add cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCluster::Add(unsigned int Cluster)
{
    unsigned int *chain;
    char *ptr;
    int Pos;

    Pos = TBlock::Add(sizeof(unsigned int));

    ptr = (char *)obj;
    ptr += Pos;
    chain = (unsigned int *)ptr;
    *chain = Cluster;
}

/*##########################################################################
#
#   Name       : TCluster::Sub
#
#   Purpose....: Sub cluster
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCluster::Sub()
{
    TBlock::Sub(sizeof(unsigned int));
}

/*##########################################################################
#
#   Name       : TCluster::GetSize
#
#   Purpose....: Get size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCluster::GetSize()
{
    int start = sizeof(struct TShareHeader);
    int size = pos - start;

    return size / sizeof(unsigned int);
}

/*##########################################################################
#
#   Name       : TCluster::GetChain
#
#   Purpose....: Get cluster chain
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned int *TCluster::GetChain()
{
    int start = sizeof(struct TShareHeader);
    unsigned int *chain;
    char *ptr;

    ptr = (char *)obj;
    ptr += start;
    chain = (unsigned int *)ptr;

    return chain;
}
