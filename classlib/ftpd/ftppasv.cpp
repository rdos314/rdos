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
# ftppasv.cpp
# Pasv command class
#
########################################################################*/

#include <string.h>

#include "ftpserv.h"
#include "ftppasv.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpPasvFactory::TFtpPasvFactory
#
#   Purpose....: Constructor for TFtpPasvFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPasvFactory::TFtpPasvFactory()
  : TFtpCommandFactory("PASV")
{
}

/*##########################################################################
#
#   Name       : TFtpPasvFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommand *TFtpPasvFactory::Create(TFtpSocketServer *Server, const char *param)
{
	return new TFtpPasvCommand(Server, param);
}

/*##########################################################################
#
#   Name       : TFtpPasvCommand::TFtpPasvCommand
#
#   Purpose....: Constructor for TFtpPasvCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpPasvCommand::TFtpPasvCommand(TFtpSocketServer *Server, const char *param)
  : TFtpCommand(Server, param)
{
}

/*##########################################################################
#
#   Name       : TFtpPasvCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpPasvCommand::Execute(char *param)
{
	TFtpLangString msg;
	long IP;
	int port;
	int i;
	int arr[6];

	FServer->ListenForDataConnection(&IP, &port);

	for (i = 0; i < 4; i++)
		arr[i] = (IP >> (8 * i)) & 0xff;

	arr[4] = (port >> 8) & 0xff;
	arr[5] = port & 0xff;

	msg.printf(227, arr[0], arr[1], arr[2], arr[3], arr[4], arr[5]);

	FServer->Reply(&msg);
}

