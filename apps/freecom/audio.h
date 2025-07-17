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
	virtual int OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg);
    void InitOptions();

    int HasInputAmp(int dev, int codec, int node);
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
    void ShowFull();
    void ShowDevices();

	int FOptD;
	
};

#endif
