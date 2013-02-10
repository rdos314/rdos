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
# audio.h
# HD audio inspection command class
#
########################################################################*/

#ifndef _AUDIO_H
#define _AUDIO_H

#include "cmd.h"
#include "cmdfact.h"

class TAudioFactory : public TCommandFactory
{
public:
	TAudioFactory();
	virtual TCommand *Create(TSession *session, const char *param);
};

class TAudioCommand : public TCommand
{
public:
	TAudioCommand(TSession *session, const char *param);

	virtual int Execute(char *param);	

protected:
    int HasInputAmp(int dev, int codec, int node, int input);
    void WriteOutputAmp(int dev, int codec, int node, const char *init);
    void WriteInputAmp(int dev, int codec, int node, int input, const char *init);
    void WriteInputAmpCommon(int dev, int codec, int node, const char *init);
    void WriteInputList(int dev, int codec, int node);
    void WriteSelectList(int dev, int codec, int node);
    void WriteAudioOutput(int dev, int codec, int node);
    void WriteAudioInput(int dev, int codec, int node);
    void WriteAudioMixer(int dev, int codec, int node);
    void WriteAudioSelector(int dev, int codec, int node);
    void WritePinComplex(int dev, int codec, int node);
	
};

#endif
