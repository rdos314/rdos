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
# loadsrc.h
# Load FreeCom .lng file class
#
########################################################################*/

#ifndef _LOADSRC_H
#define _LOADSRC_H

#define MAXSTRINGS       1024

#define VERSION_MISMATCH 128
#define VALIDATION_MISMATCH 64
#define PERFORM_VALIDATION 32

typedef enum STATE
{
	LOOKING_FOR_START,
	GETTING_PROMPT_LINE_1,
	GETTING_PROMPT_LINE_2,
	GETTING_STRING
} read_state;

struct TDynString
{
	char *text;
	int length;
};

struct TLangStringIndex
{
  unsigned index;
  unsigned size;
};

struct TLangStrings
{
	int flags;				/* bitfield: #0 -> DEFAULT, #1 -> special LNG file
								meaning: present in particular file
								#5: perform printf() validation
								#6: printf() validation failed
								#7: Version mismatch */
	char *name;				/* name of string */
	char *text;				/* text of this string */
	int version;
	char *vstring;			/* validation string */
	int id;					/* resource ID start */
	int count;				/* number of ID numbers */
};

class TLang
{
public:
	TLang();
	~TLang();

	int Load(const char *fname);

	TLangStrings strg[MAXSTRINGS];
	TLangStringIndex string[MAXSTRINGS];
	int error;
	unsigned cnt;		/* current string number */
	unsigned maxCnt;	/* number of strings within array */

protected:
	void pxerror(const char *msg1, const char *msg2);
	void HandleStart();
	void HandlePrompt1(const char *fname);
	void HandlePrompt2(const char *fname);
	void HandleString();

	int in_file;
	unsigned long linenr;
	char *ldptr;
	read_state state;
	FILE *fin;
	TDynString text;			/* Current text */
	TDynString vstring;		/* Validation string */
	int version;	
	char temp[1024];
};

#endif

