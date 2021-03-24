/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2019, Leif Ekblad
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
# webroot.h
# Web root class
#
########################################################################*/

#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

#include "webroot.h"

/*##########################################################################
#
#   Name       : TRootFactory::TRootFactory
#
#   Purpose....: Web factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRootFactory::TRootFactory(const char *name)
  : THttpCustomPageFactory(name)
{
}

/*##########################################################################
#
#   Name       : TRootFactory::~TRootFactory
#
#   Purpose....: Web factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRootFactory::~TRootFactory()
{
}

/*##########################################################################
#
#   Name       : TRootFactory::Create
#
#   Purpose....: Create web page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCustomPage *TRootFactory::Create(THttpCommand *cmd)
{
    return new TRootPage(cmd);
}

/*##########################################################################
#
#   Name       : TRootPage::TRootPage
#
#   Purpose....: Web page constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRootPage::TRootPage(THttpCommand *Cmd)
  : THttpCustomPage(Cmd)
{
}

/*##########################################################################
#
#   Name       : TRootPage::~TRootPage
#
#   Purpose....: Web page destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRootPage::~TRootPage()
{
}

/*##########################################################################
#
#   Name       : TRootPage::SendAnswer
#
#   Purpose....: Send answer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRootPage::SendAnswer()
{
    char str[80];

    Write("<!DOCTYPE html>\r\n");
    Write("<html>\r\n");
    Write("<head>\r\n");
    Write(" <meta charset=\"utf-8\">\r\n");
    Write(" <title>Heat control system</title>\r\n");
    Write("</head>\r\n\r\n");
    Write("<body background=\"/blue.jpg\">\r\n");

    Write("<form method=\"POST\" action=\"/power/web\">\r\n");

    Write("<input type=\"Submit\" value=\"next\" name=\"next\">\r\n");

    Write("</form>\r\n");

    Write("</body>\r\n");
    Write("</html>\r\n");

    SendData("text/html");
}

/*##########################################################################
#
#   Name       : TRootPage::Get
#
#   Purpose....: Get page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRootPage::Get(const char *MatchName, const char *UrlName, THttpParam *Param)
{
    SendAnswer();
}

/*##########################################################################
#
#   Name       : TRootPage::Post
#
#   Purpose....: Post page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRootPage::Post(const char *MatchName, const char *UrlName, THttpParam *Param)
{
    SendAnswer();
}

/*##########################################################################
#
#   Name       : TRootPage::Post
#
#   Purpose....: Post page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRootPage::Post(const char *Var, const char *Val)
{
}
