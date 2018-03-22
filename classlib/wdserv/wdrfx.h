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
# wdrfx.h
# WD RFX support class
#
########################################################################*/

#ifndef _WDRFX_H
#define _WDRFX_H

#include "wdsuppl.h"

class TWdRfxFactory : public TWdSupplFactory
{
public:
    TWdRfxFactory(TWdSocketServerFactory *factory);
	virtual ~TWdRfxFactory();
	
	virtual TWdSupplService *Create(TWdSocketServer *server);
};

class TWdRfxService : public TWdSupplService
{
public:
    TWdRfxService(TWdSocketServer *server);
	virtual ~TWdRfxService();

    virtual void NotifyMsg();

protected:

};

#endif
