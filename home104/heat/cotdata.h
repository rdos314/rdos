/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2006, Leif Ekblad
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
# cotdata.h
# Common data-type for cot data exchange
#
########################################################################*/

#ifndef COTDATA_H
#define COTDATA_H

#define COT_SIGN        0xABEF1456
#define MAX_MSG_SIZE    0x10000

#define LOG_TAG_HEADER      50
#define LOG_TAG_RAD         51
#define LOG_TAG_INDOOR      52
#define LOG_TAG_OUTDOOR     53
#define LOG_TAG_RAIN        54
#define LOG_TAG_CIRC        55
#define LOG_TAG_VP          56
#define LOG_TAG_TANK        57
#define LOG_TAG_HEAT        58

#define LOG_VAR_Address     100
#define LOG_VAR_MsbTime     101
#define LOG_VAR_LsbTime     102
#define LOG_VAR_Ref         103
#define LOG_VAR_Temp        104
#define LOG_VAR_Motor       105
#define LOG_VAR_Light       106
#define LOG_VAR_AuxTemp     107
#define LOG_VAR_Humidity    108
#define LOG_VAR_Dewpoint    109
#define LOG_VAR_Windchill   110
#define LOG_VAR_Windspeed   111
#define LOG_VAR_Winddir     112
#define LOG_VAR_Pressure    113
#define LOG_VAR_Rain        114
#define LOG_VAR_On          115
#define LOG_VAR_P           116

#endif
