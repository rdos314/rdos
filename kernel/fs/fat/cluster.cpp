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
