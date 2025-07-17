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
# font.cpp
# Font class
#
########################################################################*/

#include "rdos.h"
#include "font.h"

/*##########################################################################
#
#   Name       : TFont::TFont
#
#   Purpose....: Constructor for TFont                                    
#
#   In params..: Height         requested font height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFont::TFont(int height)
{
    FFontHandle = RdosOpenFont(0, height);
    FId = 0;
    FHeight = height;
}

/*##########################################################################
#
#   Name       : TFont::TFont
#
#   Purpose....: Constructor for TFont                                    
#
#   In params..: ID             font ID
#                Height         requested font height
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFont::TFont(int id, int height)
{
    FFontHandle = RdosOpenFont(id, height);
    FId = id;
    FHeight = height;
}

/*##########################################################################
#
#   Name       : TFont::TFont
#
#   Purpose....: Copy constructor for TFont                                       
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFont::TFont(const TFont &src)
{
    FId = src.FId;
    FHeight = src.FHeight;
    FFontHandle = RdosOpenFont(FId, FHeight);
}

/*##########################################################################
#
#   Name       : TFont::operator=
#
#   Purpose....: Assignment operator for TFont                                    
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFont &TFont::operator=(const TFont &src)
{
    if (this != &src)
    {
        FId = src.FId;
        FHeight = src.FHeight;
        FFontHandle = RdosOpenFont(FId, FHeight);
    }
    return *this;
}

/*##########################################################################
#
#   Name       : TFont::~TFont
#
#   Purpose....: Destructor for TFont                                     
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFont::~TFont()
{
    RdosCloseFont(FFontHandle);
}

/*##########################################################################
#
#   Name       : TFont::GetStringMetrics
#
#   Purpose....: Get string metrics                                       
#
#   In params..: str        string to meassure                
#   Out params.: width      width of string
#              : height     height of string       
#   Returns....: *
#
##########################################################################*/
void TFont::GetStringMetrics(const char *str, int *width, int *height)
{
    RdosGetStringMetrics(FFontHandle, str, width, height);
}

/*##########################################################################
#
#   Name       : TFont::GetId
#
#   Purpose....: Get ID of font
#
#   In params..: 
#   Returns....: *
#
##########################################################################*/
int TFont::GetId()
{
    return FId;
}

/*##########################################################################
#
#   Name       : TFont::GetHeight
#
#   Purpose....: Get height of font
#
#   In params..: 
#   Returns....: *
#
##########################################################################*/
int TFont::GetHeight()
{
    return FHeight;
}
