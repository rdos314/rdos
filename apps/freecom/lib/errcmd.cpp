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
# errcmd.cpp
# Error command class
#
########################################################################*/

#include <string.h>

#include "rdos.h"
#include "errcmd.h"
#include "cmdhelp.h"
#include "lang.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TErrorCommand::TErrorCommand
#
#   Purpose....: Constructor for TErrorCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TErrorCommand::TErrorCommand(TSession *session, const char *name)
  : TCommand(session, "")
{
	FMsg.printf(TEXT_ERROR_BADCOMMAND, name);
}

/*##########################################################################
#
#   Name       : TErrorCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TErrorCommand::Execute(char *param)
{
	Write(FMsg.GetData());
	return 1;
}
