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
# ini.cpp
# Ini file class
#
########################################################################*/

#include <string.h>
#include "rdos.h"
#include "ini.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TIniFile::TIniFile
#
#   Purpose....: Constructor for TIniFile, system ini
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIniFile::TIniFile()
{
        FHandle = RdosOpenSysIni();
}

/*##########################################################################
#
#   Name       : TIniFile::TIniFile
#
#   Purpose....: Constructor for TIniFile, private ini
#
#   In params..: filename
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIniFile::TIniFile(const char *IniName)
{
        FHandle = RdosOpenIni(IniName);
}

/*##########################################################################
#
#   Name       : TIniFile::TIniFile
#
#   Purpose....: Copy constructor for TIniFile
#
#   In params..: infile to duplicate handle on
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIniFile::TIniFile(const TIniFile &ini)
{
    FHandle = RdosDupIni(ini.FHandle);
}

/*##########################################################################
#
#   Name       : TIniFile::~TIniFile
#
#   Purpose....: Destructor for TIniFile
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIniFile::~TIniFile()
{
        if (FHandle)
                RdosCloseIni(FHandle);
}

/*##########################################################################
#
#   Name       : TIniFile::GotoSection
#
#   Purpose....: Goto section in ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIniFile::GotoSection(const char *name)
{
    return RdosGotoIniSection(FHandle, name);
}

/*##########################################################################
#
#   Name       : TIniFile::DeleteSection
#
#   Purpose....: Delete current section in ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIniFile::DeleteSection(const char *name)
{
    return RdosRemoveIniSection(FHandle, name);
}

/*##########################################################################
#
#   Name       : TIniFile::ReadVar
#
#   Purpose....: Read variable in current section
#
#   In params..: var, buffer, maxsize
#   Out params.: *
#   Returns....: size read
#
##########################################################################*/
int TIniFile::ReadVar(const char *var, char *str, int maxsize)
{
    return RdosReadIni(FHandle, var, str, maxsize);
}

/*##########################################################################
#
#   Name       : TIniFile::WriteVar
#
#   Purpose....: Write variable in current section
#
#   In params..: var, buffer, maxsize
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIniFile::WriteVar(const char *var, const char *str)
{
    return RdosWriteIni(FHandle, var, str);
}

/*##########################################################################
#
#   Name       : TIniFile::DeleteVar
#
#   Purpose....: Delete variable in current section
#
#   In params..: var
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIniFile::DeleteVar(const char *var)
{
    return RdosDeleteIni(FHandle, var);
}

/*##########################################################################
#
#   Name       : TIniFile::GotoFirstVar
#
#   Purpose....: Goto first ini-var in current section
#
#   In params..: var
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIniFile::GotoFirstVar()
{
    return RdosGotoFirstIniVar(FHandle);
}

/*##########################################################################
#
#   Name       : TIniFile::GotoNextVar
#
#   Purpose....: Goto next ini-var in current section
#
#   In params..: var
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIniFile::GotoNextVar()
{
    return RdosGotoNextIniVar(FHandle);
}

/*##########################################################################
#
#   Name       : TIniFile::GetCurrVar
#
#   Purpose....: Get current variable
#
#   In params..: var
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIniFile::GetCurrVar(char *var, int maxsize)
{
    return RdosGetCurrIniVar(FHandle, var, maxsize);
}
