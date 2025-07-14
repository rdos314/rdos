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
# block.cpp
# Block class
#
########################################################################*/

#include <rdos.h>
#include <serv.h>
#include "block.h"

/*##########################################################################
#
#   Name       : TBlock::TBlock
#
#   Purpose....: Block constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBlock::TBlock()
{
    obj = ServCreateShareBlock();
    pos = sizeof(TShareHeader);
}
    
/*##########################################################################
#
#   Name       : TBlock::~TBlock
#
#   Purpose....: Block destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TBlock::~TBlock()
{
    ServFreeShareBlock(obj);
}
    
/*##########################################################################
#
#   Name       : TBlock::Add
#
#   Purpose....: Add new data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TBlock::Add(int size)
{
    int retpos = pos;

    pos += size;

    while (pos > (obj->PageCount << 12))
        obj = ServGrowShareBlock(obj);

    return retpos;
}
    
/*##########################################################################
#
#   Name       : TBlock::Sub
#
#   Purpose....: Sub data entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBlock::Sub(int size)
{
    pos -= size;
}
    
/*##########################################################################
#
#   Name       : TBlock::CopyOnUsed
#
#   Purpose....: Copy if block is used
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TBlock::CopyOnUsed()
{
    obj = ServForkShareBlock(obj);
}
