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
# This is the free XML Library by Chourdakis Michael - http://www.turboirc.com
# The code was adapted to RDOS by Leif Ekblad in 2011
#
# The author of this program may be contacted at leif@rdos.net
#
# xml.cpp
# XML library
#
########################################################################*/

#include "xml.h"
#include "rdos.h"

#define _atoi64(x) atoll(x)


#pragma warning (disable:4996)

#ifndef XML_MAX_INIT_CHILDREN
#define XML_MAX_INIT_CHILDREN 20
#endif

#ifndef XML_MAX_INIT_VARIABLES
#define XML_MAX_INIT_VARIABLES 20
#endif

#ifndef XML_MAX_INIT_CONTENTS
#define XML_MAX_INIT_CONTENTS 4
#endif

#ifndef XML_MAX_INIT_COMMENTS
#define XML_MAX_INIT_COMMENTS 10
#endif

#ifndef XML_MAX_INIT_CDATAS
#define XML_MAX_INIT_CDATAS 10
#endif

#ifndef XML_MAX_INIT_COMMENTS_HEADER
#define XML_MAX_INIT_COMMENTS_HEADER 5
#endif

// Help functions    
#define MATCH_TRUE 1
#define MATCH_FALSE 0
#define MATCH_ABORT -1

#define NEGATE_CLASS
#define OPTIMIZE_JUST_STAR
#undef MATCH_TAR_PATTERN

// MIME Code
// Code from Yonat
// http://ootips.org/yonat/4dev/
#ifndef MIME_CODES_H
#define MIME_CODES_H
/******************************************************************************
 * MimeCoder -  Abstract base class for MIME filters.
 ******************************************************************************/
template <class InIter, class OutIter>
class MimeCoder
{
public:
	virtual OutIter Filter(OutIter out, InIter inBeg, InIter inEnd) = 0;
	virtual OutIter Finish(OutIter out) = 0;
};

/******************************************************************************
 * Base64
 ******************************************************************************/
template <class InIter, class OutIter>
class Base64Encoder : public MimeCoder<InIter, OutIter>
{
public:
	Base64Encoder() : its3Len(0), itsLinePos(0) {}
	virtual OutIter Filter(OutIter out, InIter inBeg, InIter inEnd);
	virtual OutIter Finish(OutIter out);
private:
	int             itsLinePos;
	unsigned char   itsCurr3[3];
	int             its3Len;
	void EncodeCurr3(OutIter& out);
};

template <class InIter, class OutIter>
class Base64Decoder : public MimeCoder<InIter, OutIter>
{
public:
	Base64Decoder() : its4Len(0), itsEnded(0) {}
	virtual OutIter Filter(OutIter out, InIter inBeg, InIter inEnd);
	virtual OutIter Finish(OutIter out);
private:
	int             itsEnded;
	unsigned char   itsCurr4[4];
	int             its4Len;
	int             itsErrNum;
	void DecodeCurr4(OutIter& out);
};

/******************************************************************************
 * Quoted-Printable
 ******************************************************************************/
template <class InIter, class OutIter>
class QpEncoder : public MimeCoder<InIter, OutIter>
{
public:
	QpEncoder() : itsLinePos(0), itsPrevCh('x') {}
	virtual OutIter Filter(OutIter out, InIter inBeg, InIter inEnd);
	virtual OutIter Finish(OutIter out);
private:
	int             itsLinePos;
	unsigned char   itsPrevCh;
};

template <class InIter, class OutIter>
class QpDecoder : public MimeCoder<InIter, OutIter>
{
public:
	QpDecoder() : itsHexLen(0) {}
	virtual OutIter Filter(OutIter out, InIter inBeg, InIter inEnd);
	virtual OutIter Finish(OutIter out);
private:
	int             itsHexLen;
	unsigned char   itsHex[2];
};
#endif // MIME_CODES_H
#define TEST_MIME_CODES
#define ___
static const int cLineLen = 72;

/******************************************************************************
 * Base64Encoder
 ******************************************************************************/
static const char cBase64Codes[] =
"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char CR = 13;
static const char LF = 10;

template <class InIter, class OutIter>
OutIter Base64Encoder<InIter, OutIter>::Filter(
	OutIter out,
	InIter inBeg,
	InIter inEnd)
{
	for (;;) {
		for (; itsLinePos < cLineLen; itsLinePos += 4) {
			for (; its3Len < 3; its3Len++) {
				if (inBeg == inEnd)
					___ ___ ___ ___ ___ return out;
				itsCurr3[its3Len] = *inBeg;
				++inBeg;
			}
			EncodeCurr3(out);
			its3Len = 0;
		} // for loop until end of line
		*out++ = CR;
		*out++ = LF;
		itsLinePos = 0;
	} // for (;;)
//    return out;
}

template <class InIter, class OutIter>
OutIter Base64Encoder<InIter, OutIter>::Finish(OutIter out)
{
	if (its3Len)
		EncodeCurr3(out);
	its3Len = 0;
	itsLinePos = 0;

	return out;
}

template <class InIter, class OutIter>
void Base64Encoder<InIter, OutIter>::EncodeCurr3(OutIter& out)
{
	if (its3Len < 3) itsCurr3[its3Len] = 0;

	*out++ = cBase64Codes[itsCurr3[0] >> 2];
	*out++ = cBase64Codes[((itsCurr3[0] & 0x3) << 4) |
		((itsCurr3[1] & 0xF0) >> 4)];
	if (its3Len == 1) *out++ = '=';
	else
		*out++ = cBase64Codes[((itsCurr3[1] & 0xF) << 2) |
		((itsCurr3[2] & 0xC0) >> 6)];
	if (its3Len < 3) *out++ = '=';
	else
		*out++ = cBase64Codes[itsCurr3[2] & 0x3F];
}

/******************************************************************************
 * Base64Decoder
 ******************************************************************************/
#define XX 127

static const unsigned char cIndex64[256] = {
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,62, XX,XX,XX,63,
	52,53,54,55, 56,57,58,59, 60,61,XX,XX, XX,XX,XX,XX,
	XX, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
	15,16,17,18, 19,20,21,22, 23,24,25,XX, XX,XX,XX,XX,
	XX,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
	41,42,43,44, 45,46,47,48, 49,50,51,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
		 XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
};

template <class InIter, class OutIter>
OutIter Base64Decoder<InIter, OutIter>::Filter(
	OutIter out,
	InIter inBeg,
	InIter inEnd)
{
	unsigned char c;
	itsErrNum = 0;

	for (;;) {
		while (its4Len < 4) {
			if (inBeg == inEnd)
				___ ___ ___ ___ return out;
			c = *inBeg;
			if ((cIndex64[c] != XX) || (c == '='))
				itsCurr4[its4Len++] = c;
			else if ((c != CR) && (c != LF)) ++itsErrNum; // error
			++inBeg;
		} // while (its4Len < 4)
		DecodeCurr4(out);
		its4Len = 0;
	} // for (;;)

//       return out;
}

template <class InIter, class OutIter>
OutIter Base64Decoder<InIter, OutIter>::Finish(OutIter out)
{
	its4Len = 0;
	if (itsEnded) return out;
	else { // error
		itsEnded = 0;
		return out;
	}
}

template <class InIter, class OutIter>
void Base64Decoder<InIter, OutIter>::DecodeCurr4(OutIter& out)
{
	if (itsEnded) {
		++itsErrNum;
		itsEnded = 0;
	}

	for (int i = 0; i < 2; i++)
		if (itsCurr4[i] == '=') {
			++itsErrNum; // error
			___ ___ ___ return;
		}
		else itsCurr4[i] = cIndex64[itsCurr4[i]];

		*out++ = (itsCurr4[0] << 2) | ((itsCurr4[1] & 0x30) >> 4);
		if (itsCurr4[2] == '=') {
			if (itsCurr4[3] == '=') itsEnded = 1;
			else ++itsErrNum;
		}
		else {
			itsCurr4[2] = cIndex64[itsCurr4[2]];
			*out++ = ((itsCurr4[1] & 0x0F) << 4) | ((itsCurr4[2] & 0x3C) >> 2);
			if (itsCurr4[3] == '=') itsEnded = 1;
			else *out++ = ((itsCurr4[2] & 0x03) << 6) | cIndex64[itsCurr4[3]];
		}
}

/******************************************************************************
 * QpEncoder
 ******************************************************************************/

// static const char cBasisHex[] = "0123456789ABCDEF";

template <class InIter, class OutIter>
OutIter QpEncoder<InIter, OutIter>::Filter(
	OutIter out,
	InIter inBeg,
	InIter inEnd)
{
	unsigned char c;

	for (; inBeg != inEnd; ++inBeg) {
		c = *inBeg;

		// line-breaks
		if (c == '\n') {
			if (itsPrevCh == ' ' || itsPrevCh == '\t') {
				*out++ = '='; // soft & hard lines
				*out++ = c;
			}
			*out++ = c;
			itsLinePos = 0;
			itsPrevCh = c;
		}

		// non-printable
		else if ((c < 32 && c != '\t')
			|| (c == '=')
			|| (c >= 127)
			// Following line is to avoid single periods alone on lines,
			// which messes up some dumb SMTP implementations, sigh...
			|| (itsLinePos == 0 && c == '.')) {
			*out++ = '=';
			*out++ = cBasisHex[c >> 4];
			*out++ = cBasisHex[c & 0xF];
			itsLinePos += 3;
			itsPrevCh = 'A'; // close enough
		}

		// printable characters
		else {
			*out++ = itsPrevCh = c;
			++itsLinePos;
		}

		if (itsLinePos > cLineLen) {
			*out++ = '=';
			*out++ = itsPrevCh = '\n';
			itsLinePos = 0;
		}
	} // for loop over all input

	return out;
}

template <class InIter, class OutIter>
OutIter QpEncoder<InIter, OutIter>::Finish(OutIter out)
{
	if (itsLinePos) {
		*out++ = '=';
		*out++ = '\n';
	}

	itsLinePos = 0;
	itsPrevCh = 'x';

	return out;
}

/******************************************************************************
 * QpDecoder
 ******************************************************************************/

/*
static const unsigned char cIndexHex[256] = {
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	 0, 1, 2, 3,  4, 5, 6, 7,  8, 9,XX,XX, XX,XX,XX,XX,
	XX,10,11,12, 13,14,15,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,10,11,12, 13,14,15,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
		 XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
	XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
};
*/

template <class InIter, class OutIter>
OutIter QpDecoder<InIter, OutIter>::Filter(
	OutIter out,
	InIter inBeg,
	InIter inEnd)
{
	unsigned char c, c1, c2;
	int errn = 0;

	for (; inBeg != inEnd; ++inBeg) {
		if (itsHexLen) {                        // middle of a Hex triplet
			if (*inBeg == '\n') itsHexLen = 0;      // soft line-break
			else {                                  // Hex code
				itsHex[itsHexLen - 1] = *inBeg;
				if (itsHexLen++ == 2) {
					if (XX == (c1 = cIndexHex[itsHex[0]])) ++errn;
					if (XX == (c2 = cIndexHex[itsHex[1]])) ++errn;
					c = (c1 << 4) | c2;
					if (c != '\r') *out++ = c;
					itsHexLen = 0;
				}
			}
		}
		else if (*inBeg == '=') itsHexLen = 1;  // beginning of a new Hex triplet
		else *out++ = *inBeg;                   // printable character
	}

	return out;
}

template <class InIter, class OutIter>
OutIter QpDecoder<InIter, OutIter>::Finish(OutIter out)
{
	if (itsHexLen) { // error
		itsHexLen = 0;
		___ ___ return out;
	}
	return out;
}
#define XML_OPTIONAL_MIME

#ifdef XML_USE_NAMESPACE
namespace XMLPP
{
#endif


	// BASE 64 Class
	// Code from Jerry Jiang
	// http://www.codeproject.com/KB/cpp/RC4-BASE64.aspx
	const unsigned char B64_offset[256] =
	{
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63,
			52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
			64, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
			15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64,
			64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
			41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
			64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
	};
	const char base64_map[] =
		"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	class CBase64
	{
	public:
		CBase64() {}

		char *Encrypt(const char * srcp, int len, char * dstp)
		{
			register int i = 0;
			char *dst = dstp;

			for (i = 0; i < len - 2; i += 3)
			{
				*dstp++ = *(base64_map + ((*(srcp + i) >> 2) & 0x3f));
				*dstp++ = *(base64_map + ((*(srcp + i) << 4) & 0x30 | (
					*(srcp + i + 1) >> 4) & 0x0f));
				*dstp++ = *(base64_map + ((*(srcp + i + 1) << 2) & 0x3C | (
					*(srcp + i + 2) >> 6) & 0x03));
				*dstp++ = *(base64_map + (*(srcp + i + 2) & 0x3f));
			}
			srcp += i;
			len -= i;

			if (len & 0x02) /* (i==2) 2 bytes left,pad one byte of '=' */
			{
				*dstp++ = *(base64_map + ((*srcp >> 2) & 0x3f));
				*dstp++ = *(base64_map + ((*srcp << 4) & 0x30 | (
					*(srcp + 1) >> 4) & 0x0f));
				*dstp++ = *(base64_map + ((*(srcp + 1) << 2) & 0x3C));
				*dstp++ = '=';
			}
			else if (len & 0x01)  /* (i==1) 1 byte left,pad two bytes of '='  */
			{
				*dstp++ = *(base64_map + ((*srcp >> 2) & 0x3f));
				*dstp++ = *(base64_map + ((*srcp << 4) & 0x30));
				*dstp++ = '=';
				*dstp++ = '=';
			}

			*dstp = '\0';

			return dst;
		}

		void* Decrypt(const char * srcp, int len, char * dstp)
		{
			register int i = 0;
			//              void *dst = dstp;

			while (i < len)
			{
				*dstp++ = (B64_offset[*(srcp + i)] << 2 |
					B64_offset[*(srcp + i + 1)] >> 4);
				*dstp++ = (B64_offset[*(srcp + i + 1)] << 4 |
					B64_offset[*(srcp + i + 2)] >> 2);
				*dstp++ = (B64_offset[*(srcp + i + 2)] << 6 |
					B64_offset[*(srcp + i + 3)]);
				i += 4;
			}
			srcp += i;

			if (*(srcp - 2) == '=')  /* remove 2 bytes of '='  padded while encoding */
			{
				*(dstp--) = '\0';
				*(dstp--) = '\0';
			}
			else if (*(srcp - 1) == '=') /* remove 1 byte of '='  padded while encoding */
				*(dstp--) = '\0';

			*dstp = '\0';

			return dstp;
		};

		size_t B64_length(size_t len)
		{
			size_t  npad = len % 3;
			// padded for multiple of 3 bytes
			size_t  size = (npad > 0) ? (len + 3 - npad) : len;
			return  (size * 8) / 6;
		}

		size_t Ascii_length(size_t len)
		{
			return  (len * 6) / 8;
		}

	};


	// Binary Data Container 
	BDC::BDC(unsigned long long s)
	{
		d = 0;
		if (s)
		{
			d = new char[(unsigned int)s];
			memset(d, 0, (size_t)s);
			ss = s;
		}
	}
	BDC::BDC()
	{
		d = 0;
		ss = 0;
	}
	BDC :: ~BDC()
	{
		if (d)
			delete[] d;
		d = 0;
	}
	BDC::BDC(const BDC& d2)
	{
		d = 0;
		ss = 0;
		operator =(d2);
	}
	bool BDC :: operator ==(const BDC& b2)
	{
		if (size() != b2.size())
			return false;
		if (memcmp(p(), b2.p(), (size_t)size()) != 0)
			return false;
		return true;
	}

	void BDC :: operator =(const BDC& d2)
	{
		if (d)
			delete[] d;
		d = 0;
		ss = 0;
		unsigned long long ns = d2.size();
		if (ns)
		{
			d = new char[(unsigned int)ns];
			memcpy(d, d2.operator char*(), (size_t)ns);
			ss = ns;
		}
	}
	BDC :: operator char*() const
	{
		return d;
	}
	BDC :: operator const char*() const
	{
		return (const char*)d;
	}
	char* BDC::p() const
	{
		return (char*)d;
	}
	unsigned long long BDC::size() const
	{
		return ss;
	}
	void BDC::clear()
	{
		memset(d, 0, (size_t)ss);
	}
	void BDC::reset()
	{
		if (d)
			delete[] d;
		d = 0;
		ss = 0;
	}
	void BDC::Ensure(unsigned long long news)
	{
		if (news < ss)
			return; // capacity is ok
		Resize(news);
	}
	void BDC::Resize(unsigned long long news)
	{
		if (news == ss)
			return; // same size

	// Create buffer to store existing BDC
		char* newd = new char[(unsigned int)news];
		unsigned long long newbs = news;
		memset((void*)newd, 0, (size_t)newbs);

		if (ss < news)
			memcpy((void*)newd, d, (size_t)ss);
		else
			// we created a smaller BDC structure
			memcpy((void*)newd, d, (size_t)news);
		delete[] d;
		d = newd;
		ss = news;
	}
	void BDC::AddResize(unsigned long long More)
	{
		Resize(ss + More);
	}


	int XML::DoMatch(const char *text, char *p, bool IsCaseSensitive)
	{
		// probably the MOST DIFFICULT FUNCTION in TurboIRC
		// Thanks to BitchX for copying this function
		//int last;
		int matched;
		//int reverse;
		int pT = 0;
		int pP = 0;

		for (; p[pP] != '\0'; pP++, pT++)
		{
			if (text[pT] == '\0' && p[pP] != '*')
				return MATCH_ABORT;
			switch (p[pP])
			{
				//         case '\\': // Match with following char
				//                pP++;
				// NO BREAK HERE

			default:
				if (IsCaseSensitive)
				{
					if (text[pT] != p[pP])
						return MATCH_FALSE;
					else
						continue;
				}
				if (toupper(text[pT]) != toupper(p[pP]))
					//         if (DMtable[text[pT]] != DMtable[p[pP]])
					return MATCH_FALSE;
				continue;

			case '?':
				continue;

			case '*':
				if (p[pP] == '*')
					pP++;
				if (p[pP] == '\0')
					return MATCH_TRUE;
				while (text[pT])
				{
					matched = DoMatch(text + pT++, p + pP);
					if (matched != MATCH_FALSE)
						return matched;
				}
				return MATCH_ABORT;

			}
		}
#ifdef MATCH_TAR_PATTERN
		if (text[pT] == '/')
			return MATCH_TRUE;
#endif
		return (text[pT] == '\0');
	}



	// This will be called from the other funcs
	bool XML::VMatching(const char *text, char *p, bool IsCaseSensitive)
	{
#ifdef OPTIMIZE_JUST_STAR
		if (p[0] == '*' && p[1] == '\0')
			return MATCH_TRUE;
#endif
		return (DoMatch(text, p, IsCaseSensitive) == MATCH_TRUE);
	}




	// XML class

	void XML::Version(XML_VERSION_INFO* x)
	{
		x->VersionLow = (XML_VERSION & 0xFF);
		x->VersionHigh = (XML_VERSION >> 8);
		strcpy(x->RDate, XML_VERSION_REVISION_DATE);
	}

	XML::XML()
	{
		Init();
	}

	XML::XML(const char* file, XML_LOAD_MODE LoadMode, class XMLTransform* eclass, class XMLTransformData* edata)
	{
		Init();
		Load(file, LoadMode, eclass, edata);
	}

	size_t XML::LoadText(const char* txt)
	{
		return Load(txt, XML_LOAD_MODE_MEMORY_BUFFER, 0, 0);
	}

	void XML::Init()
	{
		SOnClose = 0;
		hdr = 0;
		root = 0;
		f = 0;
	}

	void XML::Clear()
	{
		if (SOnClose)
			Save();
		if (root)
		{
			root->RemoveAllElements();
			delete root;
		}
		root = 0;
		// hdr
		if (hdr)
			delete hdr;
		hdr = 0;
		// item
		if (f)
			delete[] f;
		f = 0;
	}



	void XML::Lock(bool)
	{

	}

	XMLElement* XML::GetRootElement() const
	{
		return root;
	}
	void XML::SetRootElement(XMLElement* newroot)
	{
		delete root;
		root = 0;
		root = newroot;
		return;
	}

	XMLElement* XML::RemoveRootElementAndKeep()
	{
		XMLElement* x = root;
		root = new XMLElement(0, "<root/>");
		return x;
	}

	int XML::RemoveTemporalElements()
	{
		if (!root)
			return 0;
		int iN = 0;
		iN += root->RemoveTemporalElements(true);
		iN += root->RemoveTemporalVariables(true);
		return iN;
	}





	XMLHeader* XML::GetHeader()
	{
		return hdr;
	}

	void XML::SetHeader(XMLHeader* h)
	{
		if (hdr)
			delete hdr;
		hdr = 0;
		hdr = h;
	}

	size_t XML::XMLEncode(const char* src, char* trg)
	{
		if (!src)
			return 0;

		size_t Y = strlen(src);

		size_t x = 0;
		for (size_t i = 0; i < Y; i++)
		{
			if (src[i] == '&' && src[i + 1] != '#')
			{
				if (trg)
					strcat(trg + x, "&amp;");
				x += 5;
				continue;
			}
			if (src[i] == '>')
			{
				if (trg)
					strcat(trg + x, "&gt;");
				x += 4;
				continue;
			}
			if (src[i] == '<')
			{
				if (trg)
					strcat(trg + x, "&lt;");
				x += 4;
				continue;
			}
			if (src[i] == '\"')
			{
				if (trg)
					strcat(trg + x, "&quot;");
				x += 6;
				continue;
			}
			if (src[i] == '\'')
			{
				if (trg)
					strcat(trg + x, "&apos;");
				x += 6;
				continue;
			}

			if (trg)
				trg[x] = src[i];
			x++;
		}
		if (trg)
			trg[x] = 0;
		return x;
	}


	int XMLHelper::pow(int P, int z)
	{
		if (z == 0)
			return 1;
		int x = P;
		for (int i = 1; i < z; i++)
			x *= P;
		return x;
	}

	size_t XML::XMLDecode(const char* src, char* trg)
	{
		size_t Y = strlen(src);
		if (!trg)
			return Y;

		size_t x = 0;
		for (size_t i = 0; i < Y; )
		{
			char* fo = strchr((char*)src + i, '&');
			if (!fo)
			{
				// end of &s
				strcpy(trg + x, src + i);
				x = strlen(trg);
				break;
			}

			if (fo)
			{
				size_t untilfo = fo - (src + i);
				strncpy(trg + x, src + i, untilfo);
				i += untilfo;
				x += untilfo;
			}

			if (src[i] == '&' && src[i + 1] == '#' && tolower(src[i + 2]) == 'x')
			{
				i += 3;
				int dig[10] = { 0 };
				int y = 0;

				while ((src[i] >= 0x30 && src[i] <= 0x39) || (src[i] >= 'a' && src[i] <= 'f') || (src[i] >= 'A' && src[i] <= 'F'))
				{
					char C = src[i];
					if (C >= 0x30 && C <= 0x39)
						C -= 0x30;
					else
						if (C >= 0x41 && C <= 0x46)
							C -= 55;
						else
							if (C >= 0x61 && C <= 0x66)
								C -= 87;

					dig[y] = C;
					y++;
					i++;
				}

				unsigned long N = 0;
				for (int z = (y - 1); z >= 0; z--)
				{
					N += dig[z] * XMLHelper::pow(16, (y - 1) - z);
				}

				// Convert result to UTF-8
				char d1[100] = { 0 };
				strcat(trg + x, d1);
				x += strlen(d1);
				i++;
				continue;
			}
			if (src[i] == '&' && src[i + 1] == '#')
			{
				i += 2;
				int dig[10] = { 0 };
				int y = 0;

				while (src[i] >= 0x30 && src[i] <= 0x39)
				{
					dig[y] = src[i] - 0x30;
					y++;
					i++;
				}

				unsigned long N = 0;
				for (int z = (y - 1); z >= 0; z--)
				{
					N += dig[z] * XMLHelper::pow(10, (y - 1) - z);
				}

				// Convert result to UTF-8
				char d1[100] = { 0 };
				strcat(trg + x, d1);
				x += strlen(d1);
				i++;
				continue;
			}


			if (src[i] == '&')
			{
				if (strncmp(src + i + 1, "amp;", 4) == 0)
				{
					i += 5;
					trg[x] = '&';
					x++;
				}
				else
					if (strncmp(src + i + 1, "quot;", 5) == 0)
					{
						i += 6;
						trg[x] = '\"';
						x++;
					}
					else
						if (strncmp(src + i + 1, "apos;", 5) == 0)
						{
							i += 6;
							trg[x] = '\'';
							x++;
						}
						else
							if (strncmp(src + i + 1, "lt;", 3) == 0)
							{
								i += 4;
								trg[x] = '<';
								x++;
							}
							else
								if (strncmp(src + i + 1, "gt;", 3) == 0)
								{
									i += 4;
									trg[x] = '>';
									x++;
								}
								else
                                                                {
									i++;
									x++; // ignore invalid symbol
                                                                }
				continue;
			}

			trg[x] = src[i];
			i++;
			x++;
		}

		trg[x] = 0;
		return strlen(trg);
	}


	size_t XML::XMLGetValue(const char* section2, const char* attr2, char* put2, size_t maxlen)
	{

		size_t y1 = XMLEncode(section2, 0);
		size_t y2 = XMLEncode(attr2, 0);

		Z<char> section(y1 + 10);
		Z<char> attr(y2 + 10);

		XMLEncode(section2, section);
		XMLEncode(attr2, attr);

		if (y1 == 0) // root
		{
			int k = root->FindVariable(attr);
			if (k == -1)
				return 0;

			XMLVariable* v = root->GetVariables()[k];

			size_t Sug = v->GetValue(0);
			Z<char> value(Sug + 10);
			v->GetValue(value);
			size_t Y = strlen(value);
			if (Y > maxlen)
				return Y;

			strcpy(put2, value);
			return Y;
		}



		// section is a\b\c\d...
		XMLElement* r = root;
		char* a2 = section.operator char *();

		for (; ; )
		{
			char* a1 = strchr(a2, '\\');
			if (a1)
				*a1 = 0;

			int y = r->FindElement(a2);
			if (y == -1)
			{
				if (a1)
					*a1 = '\\';
				return 0;
			}

			r = r->GetChildren()[y];
			if (!a1) // was last
				break;

			*a1 = '\\';
			a2 = a1 + 1;
		}

		// element with this variable is found !
		int k = r->FindVariable(attr);
		if (k == -1)
			return 0;

		XMLVariable* v = r->GetVariables()[k];

		size_t Sug = v->GetValue(0);
		Z<char> value(Sug + 10);
		v->GetValue(value);
		size_t Y = strlen(value);
		if (Y > maxlen)
			return Y;

		strcpy(put2, value);
		return Y;
	}

	void XML::XMLSetValue(const char* section2, const char* attr, char* put)
	{
		// section is a\b\c\d...
		XMLElement* r = root;
		XMLElement* rr = root;
		Z<char> section(strlen(section2) + 10);
		strcpy(section, section2);
		char* a2 = section.operator char *();

		// Also set to delete values
		// if put is NULL, delete the specified attribute
		// if attr is NULL, delete the specified section (and all subsections!)

		if (!section || strlen(section) == 0)
		{
			int k = root->FindVariable(attr);
			if (k == -1)
			{
				root->AddVariable(attr, "");
				k = root->FindVariable(attr);
			}

			if (put == 0)
			{
				// Delete this attribute
				root->RemoveVariable(k);
			}
			else
			{
				root->GetVariables()[k]->SetValue(put);
			}
			return;
		}

		int y = 0;
		for (; ; )
		{
			char* a1 = strchr(a2, '\\');
			if (a1)
				*a1 = 0;

			y = r->FindElement(a2);
			if (y == -1)
			{
				// Create this element
				r->AddElement(a2);
				y = r->FindElement(a2);
			}

			rr = r;
			r = rr->GetChildren()[y];
			if (!a1) // was last
				break;

			*a1 = '\\';
			a2 = a1 + 1;
		}

		// element with this variable is found/created!
		if (attr == 0)
		{
			// DELETE this element AND all sub-elements!!
			rr->RemoveElement(y);
			return;
		}


		int k = r->FindVariable(attr);
		if (k == -1)
		{
			r->AddVariable(attr, "");
			k = r->FindVariable(attr);
		}


		if (put == 0)
		{
			// Delete this attribute
			r->RemoveVariable(k);
		}
		else
		{
			r->GetVariables()[k]->SetValue(put);
		}
	}




	char* XMLHelper::FindXMLClose(char* s)
	{
		// For Each <!-- we must find a -->
		// For Each <?   we must find a ?>
		// For each <> , we must find a </>
		// For each <![CDATA[ we mst find a ]]>
		// For each < /> , its all ok :)

		int d = 0;
		char* a2 = s;
		bool IsComment = false;
		bool IsCData = false;

		for (;;)
		{
			//              int axy = strlen(a2);

			char* a1 = strchr(a2, '<');
			if (!a1) // duh
				return 0;

			if (*(a1 + 1) == '/')
			{
				a2 = strchr(a1, '>');
				if (!a2) // duh
					return 0;
				a2++;
				d--;
				if (!d)
					return a2;

				continue;
			}

			if ((*(a1 + 1) == '!' && strlen(a1) > 2 && *(a1 + 2) == '-' && *(a1 + 3) == '-') || *(a1 + 1) == '?')
				IsComment = true;

			if (*(a1 + 1) == '!' && strlen(a1) > 8 && strncmp(a1 + 1, "![CDATA[", 8) == 0)
				IsCData = true;

			bool Nest = 0;
			for (;;)
			{
				// Bugfix
				if (IsCData && (*(a1) != ']' || *(a1 + 1) != ']' || *(a1 + 2) != '>'))
				{
					a1++;
					continue;
				}
				if (IsCData)
				{
					a1 += 2;
					break;
				}

				if (*a1 != '/' && *a1 != '>')
				{
#ifdef ALLOW_SINGLE_QUOTE_VARIABLES
					if (*a1 == '\"' || *a1 == '\'')
						Nest = !Nest;
#else
					if (*a1 == '\"')
						Nest = !Nest;
#endif

					a1++;
					continue;
				}
				if (*a1 == '/' && Nest)
				{
					a1++;
					continue;
				}
				if (*a1 == '>' && Nest)
				{
					a1++;
					continue;
				}

				// Also continue if / and no comment/no cdata
				if (*a1 == '/' && (IsComment || IsCData))
				{
					a1++;
					continue;
				}

				// Also continue if > and cdata with no ]]
				if (*a1 == '>' && IsCData && (*(a1 - 1) != ']' || *(a1 - 2) != ']'))
				{
					a1++;
					continue;
				}

				// Also continue if > and comment with no --
				if (*a1 == '>' && IsComment && (*(a1 - 1) != '-' || *(a1 - 2) != '-'))
				{
					a1++;
					continue;
				}


				break;
			}

			d++;


			if ((*a1 == '/' || IsComment) && !IsCData) // nice, it closes
			{
				IsComment = false;
				a2 = a1 + 1;
				d--;
				if (d == 0)
					return a2; // finish !
				continue;
			}

			if (*a1 == '>' && IsCData && *(a1 - 1) == ']' && *(a1 - 2) == ']')
			{
				IsCData = false;
				a2 = a1 + 1;

				d--;
				if (d == 0)
					return a2; // finish !
				continue;
			}

			a2 = a1 + 1;
		}
	}

	void XMLHelper::AddBlankVariable(XMLElement* parent, char *a2, int Pos)
	{
		size_t Y = strlen(a2);
		if (Y == 0 || parent == 0)
			return;

		char* a1 = a2;
		while (*a1 == ' ' || *a1 == '\t' || *a1 == '\n' || *a1 == '\r')
			a1++;
		size_t Z = strlen(a1);
		if (Z == 0)
			return;
		size_t PZ = Z;

		while (a1[PZ - 1] == '\t' || a1[PZ - 1] == '\r' || a1[PZ - 1] == '\n' || a1[PZ - 1] == ' ')
			PZ--;

		if (PZ == 0)
			return;

		char CC = a1[PZ];
		a1[PZ] = 0;

		// Add this vrb
		XMLContent* x = new XMLContent(parent, Pos, a1, true);
		parent->AddContent(x, Pos);
		a1[PZ] = CC;
	}

	XMLElement* XMLHelper::ParseElementTree(XMLHeader* hdr, XMLElement* parent, char* tree, char**, XML_PARSE_STATUS& iParseStatus)
	{
		char *a1, *a2, *a3, *a4, *a5;//,*a6;
		char c1, c2;//,c3,c4,c5,c6;

		XMLElement* root = 0;

		bool IsRootCommentSecond = false;

		a2 = tree;
		for (;;)
		{
			// find
			a3 = strchr(a2, '<');
			if (!a3)
			{
				int Pos = parent ? parent->GetChildrenNum() : 0;
				XMLHelper::AddBlankVariable(parent, a2, Pos);
				break; // end/error
			}


			// Bugfix: See if a3 is cdata
			bool IsCData = false;
			if (strncmp(a3, "<![CDATA[", 8) == 0)
				IsCData = true;
			// Bugfix: See if a3 is comment
			bool IsComment = false;
			if (strncmp(a3, "<!--", 4) == 0)
				IsComment = true;

			// Between a3 and a2, add everything which isn't \r\n,space,tabs
			*a3 = 0;
			int PosV = parent ? parent->GetChildrenNum() : 0;
			XMLHelper::AddBlankVariable(parent, a2, PosV);
			*a3 = '<';

			if (IsCData == true)
				a4 = strstr(a3, "]]>");
			else
				if (IsComment == true)
					a4 = strstr(a3, "-->");
				else
					a4 = strchr(a3, '>');
			if (!a4)
				break; // end/error
			if (IsCData)
				a4 += 2; // move to '>'
			if (IsComment)
				a4 += 2; // move to '>'

			if ((*(a3 + 1) == '!' && strlen(a3 + 1) > 2 && *(a3 + 2) == '-' && *(a3 + 3) == '-') || *(a3 + 1) == '?') // comment/markup
			{
				c2 = *a4;
				*a4 = 0;
				if (parent)
				{
					//XMLElement* c = new XMLElement(parent,a3 + 1,1);
					//parent->AddElement(c);
					int Pos = parent->GetChildrenNum();
					Z<char> com(strlen(a3) + 100);
					strncpy(com, a3 + 4, strlen(a3 + 4) - 2);
					XMLComment* c = new XMLComment(parent, Pos, com);
					parent->AddComment(c, Pos);
				}
				else // It is a root comment
				{
					int Pos = IsRootCommentSecond;
					Z<char> com(strlen(a3) + 100);
					if (strlen(a3 + 4) > 1)
						strncpy(com, a3 + 4, strlen(a3 + 4) - 2);
					XMLComment* c = new XMLComment(0, Pos, com);
					hdr->AddComment(c, Pos);
				}
				*a4 = c2;
				a2 = a4 + 1;
				continue;
			}

			if ((*(a3 + 1) == '!' && strlen(a3 + 1) > 8 && strncmp(a3 + 1, "![CDATA[", 8) == 0)) // cdata
			{
				c2 = *a4;
				*a4 = 0;

				int Pos = parent->GetChildrenNum();
				Z<char> com(strlen(a3) + 100);
				strncpy(com, a3 + 9, strlen(a3 + 9) - 2);
				XMLCData* c = new XMLCData(parent, Pos, com);
				parent->AddCData(c, Pos);

				*a4 = c2;
				a2 = a4 + 1;
				continue;
			}


			if (*(a3 + 1) == '/') // bye bye from this element
			{
				if (parent && root && parent->FindElement(root) == -1)
				{
					parent->AddElement(root);
				}
				a2 = a4 + 1;
				continue;
			}


			IsRootCommentSecond = true;
			// It is an opening element
			// If < /> , all ok, Add to current and continue
			// If < > , then find relative at end, and recursive

			if (*(a4 - 1) == '/')
			{
				// Yes it is this element alone
				c2 = *a4;
				*a4 = 0;
				if (parent)
				{
					XMLElement* c = new XMLElement(parent, a3 + 1, 0);
					parent->AddElement(c);
					if (!root)
						root = c;
				}
				else
				{
					XMLElement* c = new XMLElement(0, a3 + 1);
					if (!root)
						root = c;
				}

				*a4 = c2;
				a2 = a4 + 1;
				continue;
			}



			// Now it is an < > entry
			// Find this one at end, strchr <
			a5 = XMLHelper::FindXMLClose(a3);
			if (!a5)
			{
				// ERROR in the FILE
				iParseStatus = XML_PARSE_ERROR;
				return root;
			}

			a5--; // fixes a bug when next element is rightly after closing
			while (*a5 != '<')
				a5--;
			a1 = a5;
			c1 = *a1;
			*a1 = 0;

			// Create element a3
			c2 = *(a4 + 1);
			*(a4 + 1) = 0;
			root = new XMLElement(parent, a3, 0);
			*(a4 + 1) = c2;
			char* eV = 0;
			XMLHelper::ParseElementTree(hdr, root, a4 + 1, &eV, iParseStatus);



			char* sa2 = a2;
			*a1 = c1;
			a2 = a1;
			if (eV)
				a2 = eV;
			if (a2 == sa2)
				break; // whops ? error! . Break to avoid fatal loop
			continue;
		}

		return root;
	}

	int XMLElement::RemoveAllElements()
	{
		for (int i = childrennum - 1; i >= 0; i--)
		{
			if (children[i] == 0)
			{
				// Unload 
				DeleteUnloadedElementFile(i);
			}

			bool DoDelete = true;
			for (unsigned int xi = 0; xi < NumBorrowedElements; xi++)
			{
				if (BorrowedElements[xi].Active == 0)
					continue;
				if (BorrowedElements[xi].x == children[i])
				{
					BorrowedElements[xi].Active = 0;
					DoDelete = false;
					break;
				}
			}

			if (DoDelete)
				delete children[i];
			children[i] = 0;
		}
		childrennum = 0;
		return 0;
	}

	void XMLElement::SetElementParam(unsigned long long p)
	{
		param = p;
	}

	unsigned long long XMLElement::GetElementParam()
	{
		return param;
	}


	int XMLElement::DeleteUnloadedElementFile(int i)
	{
		// Find Unique STR
		size_t si = GetElementUniqueString(0);
		Z<char> us(si);
		GetElementUniqueString(us);
		if (us[strlen(us) - 1] == '-')
			us[strlen(us) - 1] = 0;
		// Add this element
		if (strlen(us))
			sprintf(us + strlen(us), "-%u", i);
		else
			sprintf(us + strlen(us), "%u", i);
		// Extension
		strcat(us, ".xmltmp");

		return RdosDeleteFile(us);
	}

	bool XMLElement::ReplaceElement(unsigned int i, XMLElement* ne, XMLElement** prev)
	{
		if (childrennum <= i)
			return false;
		XMLElement* xu = 0;
		RemoveElementAndKeep(i, &xu);
		if (!xu)
			return false;
		if (prev)
			*prev = xu;
		else
			delete xu;
		InsertElement(i, ne);
		return true;
	}

	int XMLElement::GetElementIndex(XMLElement* e)
	{
		for (unsigned int i = 0; i < childrennum; i++)
		{
			if (children[i] == e)
				return i;
		}
		return -1;
	}

	int XMLElement::GetDeepLevel()
	{
		if (!parent)
			return 0;
		return parent->GetDeepLevel() + 1;
	}

	int XMLElement::RemoveElement(XMLElement* e)
	{
		int X = -1;
		for (unsigned int i = 0; i < childrennum; i++)
		{
			if (children[i] == e)
			{
				X = RemoveElement(i);
				break;
			}
		}
		return X;
	}

	int XMLElement::RemoveElement(unsigned int i)
	{
		if (i >= childrennum)
			return childrennum;

		if (children[i] == 0)
		{
			// Unloaded already, just delete the file
			DeleteUnloadedElementFile(i);
		}

		bool DoDelete = true;
		// Check if this item is borrowed
		for (unsigned int xi = 0; xi < NumBorrowedElements; xi++)
		{
			if (BorrowedElements[xi].Active == 0)
				continue;
			if (BorrowedElements[xi].x == children[i])
			{
				BorrowedElements[xi].Active = 0;
				DoDelete = false;
				break;
			}
		}


		if (DoDelete)
			delete children[i];

		children[i] = 0;

		for (unsigned int k = i; k < childrennum; k++)
			children[k] = children[k + 1];

		children[childrennum - 1] = 0;
		return --childrennum;
	}

	int XMLElement::RemoveElementAndKeep(unsigned int i, XMLElement** el)
	{
		if (el)
			*el = 0;

		if (i >= childrennum)
			return childrennum;

		if (children[i] == 0) // unloaded
			ReloadElement(i);

		//delete children[i];
		if (el)
			*el = children[i];
		children[i] = 0;

		for (unsigned int k = i; k < childrennum; k++)
			children[k] = children[k + 1];

		children[childrennum - 1] = 0;
		return --childrennum;
	}

	int XMLElement::UnloadElement(unsigned int i)
	{
		XMLElement* e = children[i];
		if (!e)
			return 1; // already unloaded

		e->ReloadAllElements();

		// Find Unique STR
		size_t si = GetElementUniqueString(0);
		Z<char> us(si);
		GetElementUniqueString(us);
		if (us[strlen(us) - 1] == '-')
			us[strlen(us) - 1] = 0;
		// Add this element
		if (strlen(us))
			sprintf(us + strlen(us), "-%u", i);
		else
			sprintf(us + strlen(us), "%u", i);
		// Extension
		strcat(us, ".xmltmp");



		FILE* fp = fopen(us, "rb");
		if (fp)
		{
			// file exists !
			fclose(fp);
			return 0;
		}

		fp = fopen(us, "wb");
		if (!fp)
		{
			// Failed !
			return 0;
		}

		e->Export(fp, 1, XML_SAVE_MODE_ZERO);
		fclose(fp);

		// Delete this element, but do not remove it.
		delete children[i];
		children[i] = 0;

		return 1;
	}

	int XMLElement::ReloadElement(unsigned int i)
	{
		if (children[i])
			return 1; // Item is already here

	// Find Unique STR
		size_t si = GetElementUniqueString(0);
		Z<char> us(si);
		GetElementUniqueString(us);
		if (us[strlen(us) - 1] == '-')
			us[strlen(us) - 1] = 0;
		// Add this element
		if (strlen(us))
			sprintf(us + strlen(us), "-%u", i);
		else
			sprintf(us + strlen(us), "%u", i);
		// Extension
		strcat(us, ".xmltmp");

		FILE* fp = fopen(us, "rb");
		if (!fp)
		{
			// file failed !
			return 0;
		}
		fclose(fp);
		XML fx(us);
		int K = fx.ParseStatus();
		if (K == 2) // Fatal error
			return 0;

		XMLElement* r = fx.RemoveRootElementAndKeep();

		// Reload element
		children[i] = r;
		r->SetParent(this);

		RdosDeleteFile(us);
		return 1;
	}

	int XMLElement::ReloadAllElements()
	{
		for (unsigned int i = 0; i < childrennum; i++)
		{
			if (children[i] == 0)
				ReloadElement(i);
		}
		return 0;
	}


	XMLElement* XMLElement::MoveElement(unsigned int i, unsigned int y)
	{
		if (i >= childrennum || y >= childrennum)
			return 0;

		XMLElement* x = children[i];

		children[i] = 0;
		for (unsigned int k = i; k < childrennum; k++)
			children[k] = children[k + 1];

		childrennum--;
		return InsertElement(y, x);
	}

	XMLElement* XMLElement::InsertElement(unsigned int y, XMLElement* x)
	{
		// leave from 0 to y
		// move from y + 1 to childrennum + 1
		// save
		// childrennum++;
		if (y >= childrennum)
			return AddElement(x);

		SpaceForElement(1);

		memmove((void*)(children + y + 1), (void*)(children + y), (childrennum - y)*sizeof(XMLElement*));
		children[y] = x;
		x->SetParent(this);
		childrennum++;
		return x;
	}

	int XMLElement::BorrowElement(XMLElement*x, unsigned int y)
	{
		// Same as Insert or Add, but no SetParent

		// put 'x' in the list of 'borrowed elements'
		if (BorrowedElements.is() <= NumBorrowedElements)
			BorrowedElements.AddResize(5);
		XMLBORROWELEMENT xb = { 0 };
		xb.Active = 1;
		xb.x = x;
		BorrowedElements[NumBorrowedElements++] = xb;

		SpaceForElement(1);
		if (y >= childrennum)
		{
			children[childrennum++] = x;
			return childrennum;
		}

		memmove((void*)(children + y + 1), (void*)(children + y), (childrennum - y)*sizeof(XMLElement*));
		children[y] = x;
		childrennum++;

		return y;
	}

	int XMLElement::ReleaseBorrowedElements()
	{
		int R = 0;
		for (unsigned int y = 0; y < NumBorrowedElements; y++)
		{
			XMLBORROWELEMENT& xb = BorrowedElements[y];
			if (xb.Active == 0)
				continue;
			for (int i = (childrennum - 1); i >= 0; i--)
			{
				if (children[i] == xb.x)
				{
					RemoveElement(i);
					xb.Active = 0;
					R++;
				}
			}
		}
		NumBorrowedElements = 0;
		return R;
	}

	int XMLElement::UpdateElement(XMLElement* e, bool UpdateVariableValues)
	{
		/*

		Formula

		Checks variables, if not existing, copies
		If existing, does nothing.
		Search is case-sensitive.

		Checks elements, if not existing, copies
		if existing, calls UpdateElement() for each element

		*/

		// Test the variables
		Z<char> vn(1000);
		for (unsigned int i = 0; i < e->GetVariableNum(); i++)
		{
			XMLVariable* v = e->GetVariables()[i];
			if (v->GetName(0) > 1000)
				vn.Resize(v->GetName(0) + 1000);
			v->GetName(vn);

			XMLVariable* tv = FindVariableZ(vn, 0);
			if (tv == 0)
			{
				// Create
				AddVariable(v);
			}
			else
			{
				if (UpdateVariableValues)
				{
					if (v->GetValue(0) > 1000)
						vn.Resize(v->GetValue(0) + 1000);
					v->GetValue(vn);
					tv->SetValue(vn);
				}
			}
		}

		// Test the elements
		for (unsigned int i = 0; i < e->GetChildrenNum(); i++)
		{
			XMLElement* c = e->GetChildren()[i];
			if (c->GetElementName(0) > 1000)
				vn.Resize(c->GetElementName(0) + 1000);
			c->GetElementName(vn);

			XMLElement* tc = FindElementZ(vn, 0);
			if (tc == 0)
			{
				// Copy
				AddElement(c->Duplicate());
			}
			else
			{
				tc->UpdateElement(c, UpdateVariableValues);
			}
		}




		return 0;
	}

	int XMLElement::RemoveTemporalVariables(bool Deep)
	{
		int iNum = 0;
		for (int i = variablesnum - 1; i >= 0; i--)
		{
			if (variables[i]->IsTemporal())
			{
				RemoveVariable(i);
				iNum++;
			}
		}
		if (Deep)
		{
			for (unsigned int i = 0; i < childrennum; i++)
			{
				iNum += children[i]->RemoveTemporalVariables();
			}
		}
		return iNum;
	}

	int XMLElement::RemoveTemporalElements(bool Deep)
	{
		int iNum = 0;
		for (int i = childrennum - 1; i >= 0; i--)
		{
			if (children[i]->IsTemporal())
			{
				RemoveElement(i);
				iNum++;
			}
		}
		if (Deep)
		{
			for (unsigned int i = 0; i < childrennum; i++)
			{
				iNum += children[i]->RemoveTemporalElements();
			}
		}
		return iNum;
	}

	int XMLElement::RemoveAllVariables()
	{
		for (int i = variablesnum - 1; i >= 0; i--)
		{
			delete variables[i];
			variables[i] = 0;
		}
		variablesnum = 0;
		return 0;
	}


	int XMLElement::RemoveVariable(XMLVariable* e)
	{
		int X = -1;
		for (unsigned int i = 0; i < variablesnum; i++)
		{
			if (variables[i] == e)
			{
				X = RemoveVariable(i);
				break;
			}
		}
		return X;
	}

	int XMLElement::RemoveVariable(unsigned int i)
	{
		if (i >= variablesnum)
			return variablesnum;

		delete variables[i];
		variables[i] = 0;

		for (unsigned int k = i; k < variablesnum; k++)
			variables[k] = variables[k + 1];

		variables[variablesnum - 1] = 0;
		return --variablesnum;
	}

	int XMLElement::RemoveVariableAndKeep(unsigned int i, XMLVariable** vr)
	{
		if (vr)
		{
			*vr = 0;
		}
		if (i >= variablesnum)
			return variablesnum;

		//delete variables[i];
		if (vr)
		{
			*vr = variables[i];
		}
		variables[i] = 0;

		for (unsigned int k = i; k < variablesnum; k++)
			variables[k] = variables[k + 1];

		variables[variablesnum - 1] = 0;
		return --variablesnum;
	}

	void XML::Export(FILE* fp, XML_SAVE_MODE SaveMode, XML_TARGET_MODE TargetMode, XMLHeader *hdr, class XMLTransform* eclass, class XMLTransformData* edata)
	{
		// Export all elements
		root->Export(fp, 1, SaveMode, TargetMode, hdr, eclass, edata);
	}

	void XML::SetExportFormatting(XMLEXPORTFORMAT* xf)
	{
		root->SetExportFormatting(xf);
	}

	XMLElement* XMLElement::GetElementInSection(const char* section2)
	{
		// From section, get the element we need
		XMLElement* r = this;
		if (strcmp(section2, "") == 0)
			return this;

		Z<char> section(strlen(section2) + 1);
		strcpy(section, section2);

		char* a2 = section.operator char *();

		for (; ; )
		{
			char* a1 = strchr(a2, '\\');
			if (a1)
				*a1 = 0;

			int y = r->FindElement(a2);
			if (y == -1)
			{
				if (a1)
					*a1 = '\\';
				return 0;
			}

			r = r->GetChildren()[y];
			if (!a1) // was last
				break;

			*a1 = '\\';
			a2 = a1 + 1;
		}


		return r;
	}


	void XMLElement::printc(FILE* fp, XMLElement* root, int deep, int ShowAll, XML_SAVE_MODE SaveMode, XML_TARGET_MODE TargetMode)
	{
		if (!root)
			return;

		root->ReloadAllElements();

		char* sp = (char*)fp;
		if (TargetMode == 1)
			sp += strlen(sp);
		unsigned int spi = 0;


		/*
		Targetmodes

		0       - Export to a FILE*
		1       - Export to memory

		*/

		char DelimiterChar[100] = { 0 };
		if (root->xfformat.UseSpace)
		{
			for (int i = 0; i < root->xfformat.nId; i++)
				strcat(DelimiterChar, " ");
		}
		else
		{
			for (int i = 0; i < root->xfformat.nId; i++)
				strcat(DelimiterChar, "\t");
		}


		size_t Sug = root->GetElementName(0, SaveMode);
		Z<char> b(Sug + deep + 100);
		for (int i = 0; i < deep; i++)
			//strcat(b,"\t");
			strcat(b, DelimiterChar);

		strcat(b, "<");
		root->GetElementName(b.operator char*() + strlen(b), SaveMode);
		if (TargetMode == 1)
		{
			spi = sprintf(sp, "%s", b.operator char*());
			sp += spi;
		}
		else
			fprintf(fp, "%s", b.operator char*());

		int iY = root->GetVariableNum();
		int iC = root->GetChildrenNum();

		// print variables if they exist
		//   XMLVariable* SaveAstVariable = 0;
		if (iY)
		{
			for (int i = 0; i < iY; i++)
			{
				XMLVariable* v = root->GetVariables()[i];
				size_t s1 = v->GetName(0, SaveMode);
				size_t s2 = v->GetValue(0, SaveMode);

				Z<char> Name(s1 + 10);
				Z<char> Value(s2 + 10);

				v->GetName(Name, SaveMode);
				v->GetValue(Value, SaveMode);

				/*              if (strcmp(Name,"*") == 0)
				SaveAstVariable = v;
				else*/
				{
					if (TargetMode == 1)
					{
						spi = sprintf(sp, " %s=", Name.operator char*());
						sp += spi;
						spi = sprintf(sp, "\"%s\"", Value.operator char*());
						sp += spi;
					}
					else
						// TM == 0
					{
						fprintf(fp, " %s=", Name.operator char*());
						fprintf(fp, "\"%s\"", Value.operator char*());
					}
				}
			}
		}

		// cdatas, comments, contents may be between children
		int TotalCDatas = root->GetCDatasNum();
		int NextCData = 0;

		int TotalComments = root->GetCommentsNum();
		int NextComment = 0;

		int TotalContents = root->GetContentsNum();
		int NextContent = 0;

		// children ?
		// close now if no children/contents/comments
		if ((!iC || ShowAll == 0) && /*SaveAstVariable == 0 &&*/ TotalContents == 0 && TotalComments == 0 && TotalCDatas == 0)
		{
			if (TargetMode == 1)
			{
				spi = sprintf(sp, "/>\r\n");
				sp += spi;
			}
			else
				if (TargetMode == 2)
					; // Nothing :)
				else
					if (TargetMode == 3)
						fwrite(L"/>\r\n", 1, 4, fp);
					else // 0
						fprintf(fp, "/>\r\n");
			return;
		}
		if (TargetMode == 1)
		{
			// check linebreak 
			if (root->xfformat.ElementsNoBreak == false && root->xfformat.ContentsNoBreak == false || TotalContents != 1 || TotalComments || TotalCDatas || iC)
			{
				spi = sprintf(sp, ">\r\n", b.operator char*());
				sp += spi;
			}
			else
			{
				spi = sprintf(sp, ">", b.operator char*());
				sp += spi;
			}
		}
		else
		{
			// Write \r\n only if ElementBreak
			if (root->xfformat.ElementsNoBreak == false && root->xfformat.ContentsNoBreak == false || TotalContents != 1 || TotalComments || TotalCDatas || iC)
			{
				if (TargetMode == 2)
					; // Nothing :)
				else
				{
					if (TargetMode == 3)
						fwrite(L">\r\n", 1, 3, fp);
					else
						fprintf(fp, ">\r\n", b.operator char*());
				}
			}
			else
			{
				if (TargetMode == 2)
					; // Nothing :)
				else
				{
					if (TargetMode == 3)
						fwrite(L">", 1, 1, fp);
					else
						fprintf(fp, ">", b.operator char*());
				}
			}
		}


		if (ShowAll)
		{
			for (int i = 0; i < iC; i++)
			{
				if (TotalComments && (NextComment < TotalComments))
				{
					while ((NextComment < TotalComments) && root->GetComments()[NextComment]->GetEP() <= i)
					{
						// print that comment now
						const char* t = root->GetComments()[NextComment]->operator const char *();
						Z<char> b(strlen(t) + deep + 200);
						for (int i = 0; i < (deep + 1); i++)
							//                               strcat(b,"\t");
							strcat(b, DelimiterChar);
						strcat(b, "<!--");
						strcat(b, t);
						strcat(b, "-->\r\n");

						if (TargetMode == 1)
						{
							spi = sprintf(sp, "%s", b.operator char*());
							sp += spi;
						}
						else
							fprintf(fp, "%s", b.operator char*());

						NextComment++;
					}
				}

				if (TotalContents && (NextContent < TotalContents))
				{
					while ((NextContent < TotalContents) && root->GetContents()[NextContent]->GetEP() <= i)
					{
						// print that content now
						//char* t = root->GetContents()[NextContent]->operator char *();
						size_t vx = root->GetContents()[NextContent]->GetValue(0);

						Z<char> b(vx + deep + 200);
						if (root->xfformat.ElementsNoBreak == false)
						{
							for (int i = 0; i < (deep + 1); i++)
								//strcat(b,"\t");
								strcat(b, DelimiterChar);
							//strcat(b,t);
						}
						root->GetContents()[NextContent]->GetValue(b.operator char*() + strlen(b), SaveMode);
						if (root->xfformat.ElementsNoBreak == false && root->xfformat.ContentsNoBreak == false)
							strcat(b, "\r\n");

						if (TargetMode == 1)
						{
							spi = sprintf(sp, "%s", b.operator char*());
							sp += spi;
						}
						else
							fprintf(fp, "%s", b.operator char*());

						NextContent++;
					}
					if (TotalCDatas && (NextCData < TotalCDatas))
					{
						while ((NextCData < TotalCDatas) && root->GetCDatas()[NextCData]->GetEP() <= i)
						{
							// print that CData now
							const char* t = root->GetCDatas()[NextCData]->operator const char *();
							Z<char> b(strlen(t) + deep + 200);
							for (int i = 0; i < (deep + 1); i++)
								//                               strcat(b,"\t");
								strcat(b, DelimiterChar);
							strcat(b, "<![CDATA[");
							strcat(b, t);
							strcat(b, "]]>\r\n");

							if (TargetMode == 1)
							{
								spi = sprintf(sp, "%s", b.operator char*());
								sp += spi;
							}
							else
								fprintf(fp, "%s", b.operator char*());

							NextCData++;
						}
					}
				}


				printc(fp, root->GetChildren()[i], deep + 1, ShowAll, SaveMode, TargetMode);
				if (TargetMode == 1)
					sp = (char*)fp + strlen((char*)fp);
			}
		}

		// Check if there are still comments
		if (TotalComments && (NextComment < TotalComments))
		{
			while (NextComment < TotalComments)
			{
				// print that comment now
				const char* t = root->GetComments()[NextComment]->operator const char *();
				Z<char> b(strlen(t) + deep + 200);
				for (int i = 0; i < (deep + 1); i++)
					//strcat(b,"\t");
					strcat(b, DelimiterChar);
				strcat(b, "<!--");
				strcat(b, t);
				strcat(b, "-->\r\n");

				if (TargetMode == 1)
				{
					spi = sprintf(sp, "%s", b.operator char*());
					sp += spi;
				}
				else
					fprintf(fp, "%s", b.operator char*());

				NextComment++;
			}
		}

		// Check if there are still cdatas
		if (TotalCDatas && (NextCData < TotalCDatas))
		{
			while (NextCData < TotalCDatas)
			{
				// print that CData now
				const char* t = root->GetCDatas()[NextCData]->operator const char *();
				//               size_t ix = strlen(t);
				Z<char> b(strlen(t) + deep + 200);
				for (int i = 0; i < (deep + 1); i++)
					//strcat(b,"\t");
					strcat(b, DelimiterChar);
				strcat(b, "<![CDATA[");
				strcat(b, t);
				strcat(b, "]]>\r\n");

				if (TargetMode == 1)
				{
					spi = sprintf(sp, "%s", b.operator char*());
					sp += spi;
				}
				else
					fprintf(fp, "%s", b.operator char*());

				NextCData++;
			}
		}


		// Check if there are still Contents
		if (TotalContents && (NextContent < TotalContents))
		{
			while (NextContent < TotalContents)
			{
				// print that content now
				//char* t = root->GetContents()[NextContent]->operator char *();
				size_t vx = root->GetContents()[NextContent]->GetValue(0);

				Z<char> b(vx + deep + 200);
				if (root->xfformat.ElementsNoBreak == false && root->xfformat.ContentsNoBreak == false)
				{
					for (int i = 0; i < (deep + 1); i++)
						//strcat(b,"\t");
						strcat(b, DelimiterChar);
				}
				//strcat(b,t);
				root->GetContents()[NextContent]->GetValue(b.operator char*() + strlen(b), SaveMode);
				if (root->xfformat.ElementsNoBreak == false && root->xfformat.ContentsNoBreak == false)
					strcat(b, "\r\n");

				if (TargetMode == 1)
				{
					spi = sprintf(sp, "%s", b.operator char*());
					sp += spi;
				}
				else
					fprintf(fp, "%s", b.operator char*());

				NextContent++;
			}
		}

		// ending
		strcpy(b, "");
		if ((root->xfformat.ElementsNoBreak == false && root->xfformat.ContentsNoBreak == false) || iC || TotalCDatas || TotalComments || TotalContents != 1)
		{
			for (int i = 0; i < deep; i++)
				//strcat(b,"\t");
				strcat(b, DelimiterChar);
		}
		strcat(b, "</");
		root->GetElementName(b.operator char*() + strlen(b));
		strcat(b, ">\r\n");

		if (TargetMode == 1)
		{
			spi = sprintf(sp, "%s", b.operator char*());
			sp += spi;
		}
		else
			fprintf(fp, "%s", b.operator char*());
	}

	void XMLElement::SetExportFormatting(XMLEXPORTFORMAT* xf)
	{
		if (xf)
			memcpy(&xfformat, xf, sizeof(XMLEXPORTFORMAT));
		if (xfformat.nId > 50)
			xfformat.nId = 50;
		for (unsigned int i = 0; i < GetChildrenNum(); i++)
			GetChildren()[i]->SetExportFormatting(xf);
	}

	void XMLElement::Export(FILE* fp, int ShowAll, XML_SAVE_MODE SaveMode, XML_TARGET_MODE TargetMode, XMLHeader* hdr, class XMLTransform* eclass, class XMLTransformData* edata)
	{
		// Export this element
		ReloadAllElements();

		if (eclass == 0)
		{
			if (hdr)
				hdr->Export(fp, 0, TargetMode, eclass, edata);
			printc(fp, this, 0, ShowAll, SaveMode, TargetMode);
			if (hdr)
				hdr->Export(fp, 1, TargetMode, eclass, edata);
		}
		else
		{
			//* save to another fp, then encrypt with eclass to this fp
			size_t S = MemoryUsage();
			Z<char> ram(S);
			XML_TARGET_MODE NewTargetMode = XML_TARGET_MODE_MEMORY;
			if (hdr)
				hdr->Export((FILE*)ram.operator char *(), 0, NewTargetMode, eclass, edata);
			printc((FILE*)ram.operator char *(), this, 0, ShowAll, SaveMode, NewTargetMode);
			if (hdr)
				hdr->Export((FILE*)ram.operator char *(), 1, NewTargetMode, eclass, edata);


			Z<char> yy(S + 100);

			// convert
			//eclass->Prepare(edata);
			S = strlen(ram);
			size_t nS = eclass->Encrypt(ram.operator char *(), S, 0, yy.operator char *(), S + 100, 0);

			// Write
			if (TargetMode == 0)
				fwrite(yy.operator char* (), 1, nS, fp);
			else
				if (TargetMode == 1)
					memcpy((char*)fp, yy.operator char *(), nS);


			/*      char* tf = ".\\a.tmp";
			FILE* fpn = fopen(tf,"wb");
			if (!fpn)
			return;

			// save
			if (hdr)
			hdr->Export(fp,0,TargetMode,eclass,edata);
			printc(fpn,this,0,ShowAll,SaveMode,TargetMode);
			if (hdr)
			hdr->Export(fp,1,TargetMode,eclass,edata);

			int S = ftell(fpn);
			fclose(fpn);

			// read a.tmp again
			Z<char>* y = XML :: ReadToZ(tf);
			XML :: Kill(tf);

			Z<char> yy(S + 100);

			// convert
			eclass->Prepare(edata);
			int nS = eclass->Encrypt((*y).operator char *(),S,0,yy.operator char *(),S + 100,0);

			fwrite(yy.operator char* (),1,nS,fp);
			delete y;
			*/
		}
	}


	int XMLElementfcmp(const void * a, const void * b)
	{
		XMLElement* x1 = *(XMLElement**)a;
		XMLElement* x2 = *(XMLElement**)b;

		// compare names
		size_t z1 = x1->GetElementName(0);
		size_t z2 = x2->GetElementName(0);

		Z<char> s1(z1 + 10);
		Z<char> s2(z2 + 10);
		x1->GetElementName(s1);
		x2->GetElementName(s2);

		return strcmpi(s1, s2);
	}
	int XMLVariablefcmp(const void * a, const void * b)
	{
		XMLVariable* x1 = *(XMLVariable**)a;
		XMLVariable* x2 = *(XMLVariable**)b;

		// compare names
		size_t z1 = x1->GetName(0);
		size_t z2 = x2->GetName(0);

		Z<char> s1(z1 + 10);
		Z<char> s2(z2 + 10);
		x1->GetName(s1);
		x2->GetName(s2);

		return strcmpi(s1, s2);
	}

	void XMLElement::SortElements(int(*fcmp)(const void *, const void *))
	{
		// to all elements
		XMLElement** x = GetChildren();
		int y = GetChildrenNum();
		if (!fcmp)
			qsort(x, y, sizeof(XMLElement*), XMLElementfcmp);
		else
			qsort(x, y, sizeof(XMLElement*), fcmp);
	}

	void XMLElement::SortVariables(int(*fcmp)(const void *, const void *))
	{
		// to all Variables
		XMLVariable** x = GetVariables();
		int y = GetVariableNum();
		if (!fcmp)
			qsort(x, y, sizeof(XMLVariable*), XMLVariablefcmp);
		else
			qsort(x, y, sizeof(XMLVariable*), fcmp);
	}

	// Memory usage funcs
	size_t XML::MemoryUsage()
	{
		return GetRootElement()->MemoryUsage() + GetHeader() ? GetHeader()->MemoryUsage() : 0;
	}

	void XML::CompressMemory()
	{
		GetRootElement()->CompressMemory();
		GetHeader()->CompressMemory();
	}

	bool XML::IntegrityTest()
	{
		if (!GetHeader() || !GetRootElement())
			return false;
		return (GetHeader()->IntegrityTest() && root && GetRootElement()->IntegrityTest());
	}

	int XML::Compare(XML*x)
	{
		// 2 XML = equals if headers & root elements compare ok
		int a1 = (GetRootElement()->Compare(x->GetRootElement()));
		int a2 = (GetHeader()->Compare(x->GetHeader()));
		return !(a1 == 0 && a2 == 0);
	}

	size_t XMLHeader::MemoryUsage()
	{
		size_t m = 0;

		// Our size
		m += sizeof(*this);

		// Comments
		for (unsigned int i = 0; i < commentsnum; i++)
		{
			m += GetComments()[i]->MemoryUsage();
		}
		// number of comment pointers
		m += TotalCommentPointersAvailable * 4;


		// Text
		if (hdr)
			m += strlen(hdr);

		return m;
	}

	void XMLHeader::CompressMemory()
	{
		// Remove wasted space by comments
		int P = commentsnum;
		if (P == 0)
			P = 1;
		XMLComment** oldp = new XMLComment*[P];
		if (commentsnum)
			memcpy(oldp, comments, commentsnum*sizeof(XMLComment*));

		TotalCommentPointersAvailable = P;
		delete[] comments;
		comments = oldp;
	}

	bool XMLHeader::IntegrityTest()
	{
		if (!hdr)
			return false;

		// Check comment
		for (unsigned int i = 0; i < commentsnum; i++)
		{
			if (!GetComments()[i]->IntegrityTest())
				return false;
		}
		return true;
	}

	int XMLHeader::Compare(XMLHeader* x)
	{
		// 2 Headers compare ok <=> Same text, same # comments, comments compare ok
		if (strcmp(hdr, x->hdr) != 0)
			return 1; // fail header

		unsigned int Y = GetCommentsNum();
		if (Y != x->GetCommentsNum())
			return 1;// differnet comment num

		for (unsigned int i = 0; i < Y; i++)
		{
			if (GetComments()[i]->Compare(x->GetComments()[i]) == 1)
				return 1; // different comment
		}
		return 0; // OK!
	}

	size_t XMLComment::MemoryUsage()
	{
		size_t m = 0;

		// Our size
		m += sizeof(*this);

		// Comment size
		if (c)
			m += strlen(c);

		return m;
	}

	void XMLComment::CompressMemory()
	{
	}

	bool XMLComment::IntegrityTest()
	{
		// check parent,c

		if (!c)
			return false;

		return true;
	}

	int XMLComment::Compare(XMLComment* x)
	{
		// Compare OK <=> Same Text
		if (strcmp(c, x->c) != 0)
			return 1;


		return 0;
	}


	XMLComment* XMLComment::Duplicate()
	{
		// returns a copy of myself
		return new XMLComment(parent, ep, c);
	}


	size_t XMLContent::MemoryUsage()
	{
		size_t m = 0;

		// Our size
		m += sizeof(*this);

		if (BinaryMode)
		{
			m += (size_t)bdc.size();
		}
		else
		{
			// Comment size
			if (c)
				m += strlen(c);
		}

		return m;
	}

	void XMLContent::CompressMemory()
	{
	}

	bool XMLContent::IntegrityTest()
	{
		// check parent,c

		if (BinaryMode == false)
		{
			if (!c)
				return false;
		}

		return true;
	}

	int XMLContent::Compare(XMLContent* x)
	{
		// Contents OK <=> Same text
		if (BinaryMode)
		{
			if (bdc == x->bdc)
				return 0;
			return 1;
		}
		if (strcmp(c, x->c) != 0)
			return 1;
		return 0;
	}

	XMLContent* XMLContent::Duplicate()
	{
		// returns a copy of myself
		if (BinaryMode)
		{
			XMLContent* nc = new XMLContent(parent, ep);
			nc->SetBinaryMode(true);
			nc->bdc = bdc;
			return nc;
		}

		size_t s2 = GetValue(0);
		Z<char> x2(s2 + 100);
		GetValue(x2);

		return new XMLContent(parent, ep, x2);
	}


	size_t XMLCData::MemoryUsage()
	{
		size_t m = 0;

		// Our size
		m += sizeof(*this);

		// CData size
		if (c)
			m += strlen(c);

		return m;
	}

	void XMLCData::CompressMemory()
	{
	}

	bool XMLCData::IntegrityTest()
	{
		// check parent,c

		if (!c)
			return false;

		return true;
	}

	int XMLCData::Compare(XMLCData* x)
	{
		// Compare OK <=> Same Text
		if (strcmp(c, x->c) != 0)
			return 1;
		return 0;
	}


	XMLCData* XMLCData::Duplicate()
	{
		// returns a copy of myself
		return new XMLCData(parent, ep, c);
	}





	size_t XMLVariable::MemoryUsage()
	{
		size_t m = 0;

		// Our size
		m += sizeof(*this);

		// Variable size
		m += GetName(0);
		m += GetValue(0);

		return m;
	}

	void XMLVariable::CompressMemory()
	{
	}

	bool XMLVariable::IntegrityTest()
	{
		// check vv,vn,owner
		if (!vn || !vv)
			return false;

		return true;
	}

	int XMLVariable::Compare(XMLVariable* x)
	{
		// Contents OK <=> Same value & name
		if (strcmp(vn, x->vn) != 0)
			return 1;
		size_t l1 = strlen(vv);
		size_t l2 = strlen(x->vv);
		if (l1 != l2)
			return 0;
		if (strncmp(vv, x->vv, l1) != 0)
			return 1;
		return 0;
	}

	size_t XMLElement::MemoryUsage()
	{
		size_t m = 0;
		// returns # of bytes used by this element's data

		// Our size
		m += sizeof(*this);

		// Variables of this
		for (unsigned int i = 0; i < variablesnum; i++)
		{
			m += GetVariables()[i]->MemoryUsage();
		}

		// Comments of this
		for (unsigned int i = 0; i < commentsnum; i++)
		{
			m += GetComments()[i]->MemoryUsage();
		}

		// Contents of this
		for (unsigned int i = 0; i < contentsnum; i++)
		{
			m += GetContents()[i]->MemoryUsage();
		}

		// CDatas of this
		for (unsigned int i = 0; i < cdatasnum; i++)
		{
			m += GetCDatas()[i]->MemoryUsage();
		}

		// Elements of this
		for (unsigned int i = 0; i < childrennum; i++)
		{
			if (GetChildren()[i])
				m += GetChildren()[i]->MemoryUsage();
		}

		// number of children pointers
		m += TotalChildPointersAvailable * 4;

		// number of variable pointers
		m += TotalVariablePointersAvailable * 4;

		// number of comment pointers
		m += TotalCommentPointersAvailable * 4;

		// number of content pointers
		m += TotalContentPointersAvailable * 4;

		// number of cdata pointers
		m += TotalCDataPointersAvailable * 4;

		// Element name
		m += GetElementName(0);
		return m;
	}

	void XMLElement::CompressMemory()
	{
		{
			// Remove wasted space by comments
			int PC = commentsnum;
			if (PC == 0)
				PC = 1;

			XMLComment** oldpc = new XMLComment*[PC];
			if (commentsnum)
				memcpy(oldpc, comments, commentsnum*sizeof(XMLComment*));

			TotalCommentPointersAvailable = PC;
			delete[] comments;
			comments = oldpc;
		}

		{
			// Remove wasted space by variables
			int PV = variablesnum;
			if (PV == 0)
				PV = 1;

			XMLVariable** oldpv = new XMLVariable*[PV];
			if (variablesnum)
				memcpy(oldpv, variables, variablesnum*sizeof(XMLVariable*));

			TotalVariablePointersAvailable = PV;
			delete[] variables;
			variables = oldpv;
		}

		{
			// Remove wasted space by children
			int PE = childrennum;
			if (PE == 0)
				PE = 1;

			XMLElement** oldpv = new XMLElement*[PE];
			if (childrennum)
				memcpy(oldpv, children, childrennum*sizeof(XMLElement*));

			TotalChildPointersAvailable = PE;
			delete[] children;
			children = oldpv;
		}

		// Do the same for all Contents
		for (unsigned int i = 0; i < contentsnum; i++)
		{
			contents[i]->CompressMemory();
		}

		// Do the same for all Comments
		for (unsigned int i = 0; i < commentsnum; i++)
		{
			comments[i]->CompressMemory();
		}

		// Do the same for all CDatas
		for (unsigned int i = 0; i < cdatasnum; i++)
		{
			cdatas[i]->CompressMemory();
		}

		// Do the same for all Variables
		for (unsigned int i = 0; i < variablesnum; i++)
		{
			variables[i]->CompressMemory();
		}

		// Do the same for all child elements
		for (unsigned int i = 0; i < childrennum; i++)
		{
			if (children[i])
				children[i]->CompressMemory();
		}
	}

	bool XMLElement::IntegrityTest()
	{

		// The main meat IntegrityTest

		/*

		Check

		name
		parent
		childen
		contents
		variables
		comments

		char* el; // element name
		XMLElement* parent; // one
		XMLElement** children; // many
		XMLVariable** variables; // many
		XMLComment** comments; // many
		XMLContent** contents; // many;

		*/


		// Check comment
		for (unsigned int i = 0; i < commentsnum; i++)
		{
			if (!GetComments()[i]->IntegrityTest())
				return false;
		}

		// Check content
		for (unsigned int i = 0; i < contentsnum; i++)
		{
			if (!GetContents()[i]->IntegrityTest())
				return false;
		}


		// Check comment
		for (unsigned int i = 0; i < variablesnum; i++)
		{
			if (!GetVariables()[i]->IntegrityTest())
				return false;
		}

		// Check children
		for (unsigned int i = 0; i < childrennum; i++)
		{
			if (!GetChildren()[i]->IntegrityTest())
				return false;
		}



		return true;
	}


	int XMLElement::Compare(XMLElement* x)
	{
		/*
		XMLElements match if

		Have same element name

		Have same # of variables,and they match
		Have same # of comments, and they match
		Have same # of contents, and they match
		Have same # of children, and they match
		*/

		// Test element name
		if (strcmp(el, x->el) != 0)
			return 1;

		// Test Variables
		unsigned int nV = GetVariableNum();
		if (nV != x->GetVariableNum())
			return 1;
		for (unsigned int i = 0; i < nV; i++)
		{
			if (GetVariables()[i]->Compare(x->GetVariables()[i]) != 0)
				return 1;
		}

		// Test Comments
		unsigned int nC = GetCommentsNum();
		if (nC != x->GetCommentsNum())
			return 1;
		for (unsigned int i = 0; i < nC; i++)
		{
			if (GetComments()[i]->Compare(x->GetComments()[i]) != 0)
				return 1;
		}

		// Test CDatas
		unsigned int nD = GetCDatasNum();
		if (nD != x->GetCDatasNum())
			return 1;
		for (unsigned int i = 0; i < nD; i++)
		{
			if (GetCDatas()[i]->Compare(x->GetCDatas()[i]) != 0)
				return 1;
		}

		// Test Contents
		unsigned int nT = GetContentsNum();
		if (nT != x->GetContentsNum())
			return 1;
		for (unsigned int i = 0; i < nT; i++)
		{
			if (GetContents()[i]->Compare(x->GetContents()[i]) != 0)
				return 1;
		}

		// Test Children Elements
		unsigned int nE = GetChildrenNum();
		if (nE != x->GetChildrenNum())
			return 1;
		for (unsigned int i = 0; i < nE; i++)
		{
			if (!GetChildren()[i] || !x->GetChildren()[i])
				continue;
			if (GetChildren()[i]->Compare(x->GetChildren()[i]) != 0)
				return 1;
		}

		return 0; // MATCH!
	}


	XMLElement* XML::Paste(char* txt)
	{
		if (txt)
		{
			XML* xm = new XML();
			xm->Load(txt, XML_LOAD_MODE_MEMORY_BUFFER, 0, 0);
			int K = xm->ParseStatus();
			if (K == 2) // Fatal error
			{
				delete xm;
				return 0;
			}
			if (xm->GetRootElement() == 0)
			{
				delete xm;
				return 0;
			}
			XMLElement* r = xm->GetRootElement()->Duplicate(0);
			delete xm;
			return r;
		}

		return 0;
	}

	XMLElement* XMLElement::Duplicate(XMLElement* par)
	{
		// Creates a new XML element, excact copy of myself
		/*
		Formula
		dup all variables for this element
		dup all contents  for this element
		dup all comments  for this element
		dup all cdatas    for this element
		dup all elements  in a loop

		*/

		ReloadAllElements();

		size_t z1 = GetElementName(0);
		Z<char> en(z1 + 10);
		GetElementName(en);

		XMLElement* nX = new XMLElement(par, en);

		// Add All Variables
		int y = GetVariableNum();
		for (int i = 0; i < y; i++)
		{
			nX->AddVariable(GetVariables()[i]->Duplicate());
		}

		// Add All Contents
		y = GetContentsNum();
		for (int i = 0; i < y; i++)
		{
			nX->AddContent(GetContents()[i]->Duplicate(), GetContents()[i]->GetEP());
		}

		// Add All Comments
		y = GetCommentsNum();
		for (int i = 0; i < y; i++)
		{
			nX->AddComment(GetComments()[i]->Duplicate(), GetComments()[i]->GetEP());
		}

		// Add All Cdatas
		y = GetCDatasNum();
		for (int i = 0; i < y; i++)
		{
			nX->AddCData(GetCDatas()[i]->Duplicate(), GetCDatas()[i]->GetEP());
		}

		// Recurse to add all child elements
		int c = GetChildrenNum();
		for (int i = 0; i < c; i++)
		{
			nX->AddElement(GetChildren()[i]->Duplicate(nX));
		}

		return nX;
	}

	void XML::SaveOnClose(bool S)
	{
		SOnClose = S;
	}

	int XML::Save(const char* file, XML_SAVE_MODE SaveMode, XML_TARGET_MODE TargetMode, class XMLTransform* eclass, class XMLTransformData* edata)
	{
		if (TargetMode == 1)
		{
			if (!file)
				return 0;

			// TargetMode == 1, save to memory buffer
			Export((FILE*)file, SaveMode, XML_TARGET_MODE_MEMORY, hdr, eclass, edata);
			return 1;
		}
		if (TargetMode == 2)
		{
			return 0; // We can't save to registry from XML :: Save.
		}



		if (!file)
			file = f;

		if (!file)
			return 0;

		// write this file
		// Header, and all elements
		FILE* fp = 0;
		fp = fopen(file, "wb");

		if (!fp)
			return 0;

		if (TargetMode == 3)
		{
			// Write BOM
			fwrite("\xFF\xFE", 1, 2, fp);

			// Hdr utf-16
			if (hdr)
				hdr->SetEncoding("UTF-16");
		}
		if (TargetMode == 0)
		{
			if (hdr)
				hdr->SetEncoding("UTF-8");
		}


		// Show
		Export(fp, SaveMode, TargetMode, hdr, eclass, edata);

		fclose(fp);
		return 1;
	}

	void XMLElement::SetElementName(const char* x)
	{

		if (el)
			delete[] el;
		el = 0;
		size_t Sug = XML::XMLEncode(x, 0);
		el = new char[Sug + 10];
		memset(el, 0, Sug + 10);
		XML::XMLEncode(x, el);
	}

	size_t XMLElement::GetElementName(char* x, int NoDecode)
	{
		if (!x)
		{
			if (NoDecode)
				return strlen(el);
			else
				return XML::XMLDecode(el, 0);
		}

		if (NoDecode)
			strcpy(x, el);
		else
			XML::XMLDecode(el, x);
		return strlen(x);
	}

	size_t XMLElement::GetElementFullName(char* x, int NoDecode)
	{
		Z<char> fel(5000); // full element name store here
		if (parent == 0) // this is the root element
		{
			return 0;
		}
		else
		{
			parent->GetElementFullName(fel, NoDecode);
			if (strlen(fel))
				strcat(fel, "\\");
			strcat(fel, el);
		}

		if (!x)
		{
			if (NoDecode)
				return strlen(fel);
			else
				return XML::XMLDecode(fel, 0);
		}

		if (NoDecode)
			strcpy(x, fel);
		else
			XML::XMLDecode(fel, x);
		return strlen(x);
	}

	size_t XMLElement::GetElementUniqueString(char* x)
	{
		int d = GetDeep();
		if (!x)
			return (d * 4) + 10;

		if (parent)
			parent->GetElementUniqueString(x);

		// strcat to x our position
		if (parent)
		{
			int iid = parent->FindElement(this);
			sprintf(x + strlen(x), "%i-", iid);
		}
		return strlen(x);
	}

	int XMLElement::GetType()
	{
		return type;
	}

	int XMLElement::FindElement(XMLElement* x)
	{
		for (unsigned int i = 0; i < childrennum; i++)
		{
			if (children[i] == x)
				return i;
		}
		return -1;
	}

	int XMLElement::FindElement(const char* n)
	{
		for (unsigned int i = 0; i < childrennum; i++)
		{
			if (!children[i])
				continue;
			XMLElement* cc = children[i];
			size_t Sug = cc->GetElementName(0);
			Z<char> Name(Sug + 10);
			cc->GetElementName(Name);
			if (strcmp(Name, n) == 0)
				return i;
		}
		return -1;
	}

	XMLElement *XMLElement::GetElement(const char* n)
	{
		for (unsigned int i = 0; i < childrennum; i++)
		{
			if (!children[i])
				continue;
			XMLElement* cc = children[i];
			size_t Sug = cc->GetElementName(0);
			Z<char> Name(Sug + 10);
			cc->GetElementName(Name);
			if (strcmp(Name, n) == 0)
				return cc;
		}
		return 0;
	}

	XMLElement* XMLElement::FindElementZ(XMLElement* x)
	{
		for (unsigned int i = 0; i < childrennum; i++)
		{
			if (children[i] == x)
				return children[i];
		}
		return 0;
	}

	XMLElement* XMLElement::FindElementZ(const char* n, bool ForceCreate, char* el, bool Temp)
	{
		for (unsigned int i = 0; i < childrennum; i++)
		{
			if (!children[i])
				continue;
			XMLElement* cc = children[i];
			size_t Sug = cc->GetElementName(0);
			Z<char> Name(Sug + 10);
			cc->GetElementName(Name);
			if (strcmp(Name, n) == 0)
				return cc;
		}
		if (ForceCreate == 0)
			return 0;

		// Create New Element and add
		// Force to create a new element
		XMLElement* vv = new XMLElement(this, el ? el : n, 0, Temp);
		AddElement(vv);
		return FindElementZ(vv);
	}

	int XMLElement::FindVariable(XMLVariable* x)
	{
		for (unsigned int i = 0; i < variablesnum; i++)
		{
			if (variables[i] == x)
				return i;
		}
		return -1;
	}

	XMLVariable* XMLElement::FindVariableZ(XMLVariable* x)
	{
		for (unsigned int i = 0; i < variablesnum; i++)
		{
			if (variables[i] == x)
				return variables[i];
		}
		return 0;
	}

	int XMLElement::FindVariable(const char*  x)
	{
		for (unsigned int i = 0; i < variablesnum; i++)
		{
			XMLVariable* V = variables[i];

			size_t Sug = V->GetName(0);
			Z<char> Name(Sug + 10);
			V->GetName(Name);
			if (strcmp(Name, x) == 0)
				return i;
		}
		return -1;
	}

	XMLVariable* XMLElement::GetVariable(const char*  x)
	{
		for (unsigned int i = 0; i < variablesnum; i++)
		{
			XMLVariable* V = variables[i];

			size_t Sug = V->GetName(0);
			Z<char> Name(Sug + 10);
			V->GetName(Name);
			if (strcmp(Name, x) == 0)
				return V;
		}
		return 0;
	}

	int XMLElement::GetVariableInt(const char*  x, int def)
	{
		XMLVariable* V = GetVariable(x);

		if (V)
			return V->GetValueInt();
		else
			return def;
	}

	unsigned int XMLElement::GetVariableUInt(const char*  x, unsigned int def)
	{
		XMLVariable* V = GetVariable(x);

		if (V)
			return V->GetValueUInt();
		else
			return def;
	}

	double XMLElement::GetVariableDouble(const char*  x, double def)
	{
		XMLVariable* V = GetVariable(x);

		if (V)
			return V->GetValueDouble();
		else
			return def;
	}


int XMLElement :: GetVariableHex(const char*  x, int def)
{
        XMLVariable* V = GetVariable(x);

        if (V)
            return V->GetValueHex();
        else
            return def;
}

TString XMLElement :: GetVariableString(const char*  x, const char *def)
{
        XMLVariable* V = GetVariable(x);

        if (V)
            return V->GetValueString();
        else
            return def;
}

TDateTime XMLElement :: GetVariableDateTime(const char*  x)
{
        XMLVariable* V = GetVariable(x);

        if (V)
            return V->GetValueDateTime();
        else
            return TDateTime();
}

bool XMLElement::GetVariableBoolean(const char*  x, bool def)
{
	XMLVariable* V = GetVariable(x);

	if (V)
		return V->GetValueBoolean();
	else
		return def;
}

	XMLVariable* XMLElement::FindVariableZ(const char*  x, bool ForceCreate, char* defnew, bool Temp)
	{
		for (unsigned int i = 0; i < variablesnum; i++)
		{
			XMLVariable* V = variables[i];
			size_t Sug = V->GetName(0);
			Z<char> Name(Sug + 10);
			V->GetName(Name);
			if (strcmp(Name, x) == 0)
				return V;
		}
		if (ForceCreate == 0)
			return 0;

		// Force to create a new variable
		XMLVariable* vv = new XMLVariable(x, defnew, 0, Temp);
		AddVariable(vv);
		return FindVariableZ(x, 0);
	}


	int XML::Load(const char* file, XML_LOAD_MODE LoadMode, XMLTransform* eclass, class XMLTransformData* edata)
	{
		Clear();
		Z<char>* y = 0;
		iParseStatus = XML_PARSE_OK;

		if (LoadMode == XML_LOAD_MODE_LOCAL_FILE) // local xml file
		{
			f = new char[strlen(file) + 1];
			strcpy(f, file);
			// parse this file
			y = ReadToZ(file, eclass, edata);
			if (!y)
			{
				// It is an empty XML file.
				// Create the initial data/header

				hdr = new XMLHeader("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\" ?>");
				root = new XMLElement(0, "root", 0);

				return 1;
			}
		}
		else
			if (LoadMode == XML_LOAD_MODE_MEMORY_BUFFER) // memory buffer
			{
				f = 0;
				if (!file || strlen(file) == 0)
				{
					// It is an empty XML file.
					// Create the initial data/header

					hdr = new XMLHeader("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\" ?>");
					root = new XMLElement(0, "root", 0);

					return 1;
				}
				else
				{
					size_t S = strlen(file) + 100;
					y = new Z<char>(S);
					strcpy(y->operator char *(), file);
				}
			}
			else
				if (LoadMode == XML_LOAD_MODE_URL) // url
				{
					f = 0;
				}

		// Read file in y and create all XML data
		char* d = (*y).operator char*();

		// read hdr
		char* a2 = 0;
		char c1;
		char* a1 = strstr(d, "?>");
		if (!a1)
		{
			if (f)
				delete[] f;
			f = 0;
			iParseStatus = XML_PARSE_NO_HEADER;
			hdr = new XMLHeader("\xEF\xBB\xBF<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\" ?>");
			//      root = new XMLElement(0,"root",0);
			//      delete y;
			//      return 1;
			a1 = d;
			a2 = a1;
		}
		else
		{
			a1 += 2;
			c1 = *a1;
			*a1 = 0;
			hdr = new XMLHeader(d);
			*a1 = c1;
			a2 = a1;
		}

		if (eclass)
		{
			// Delete f if was an encrypted opening
			if (f)
				delete[] f;
			f = 0;
		}

		/*
		Parse each < >
		Possible values

		<!-- -->   comment
		<>         element
		</>        end element
		<? ?>      markup

		*/


		a1 = strchr(a2, '<');

		if (a1)
			root = XMLHelper::ParseElementTree(hdr, 0, a1, 0, iParseStatus);
		else
		{
			if (f)
				delete[] f;
			f = 0;
			iParseStatus = XML_PARSE_NO_HEADER;
			root = new XMLElement(0, "<root>");
		}
		// Print all elements of this

		delete y;
		return 1;
	}

	XML_PARSE_STATUS XML::ParseStatus(int* v)
	{
		if (v)
			*v = iParseStatusPos;
		return iParseStatus;
	}

	XML :: ~XML()
	{
		Clear();
	}

	XML::XML(XML& xml)
	{
		Clear();
		Init();
		operator =(xml);
	}

	XML& XML :: operator =(XML& xml)
	{
		Clear();
		Init();
		hdr = xml.GetHeader()->Duplicate();
		root = xml.GetRootElement()->Duplicate();
		f = 0;
		iParseStatus = XML_PARSE_OK;
		SOnClose = false;
		return *this;
	}


	// XMLElement class
	void XMLElement::Reparse(const char* elm2, int Type)
	{
		RemoveAllVariables();
		RemoveAllElements();
		RemoveAllComments();
		RemoveAllContents();
		RemoveAllCDatas();

		Z<char> elm(strlen(elm2) + 1);
		strcpy(elm, elm2);

		if (Type == 1)
		{
			el = new char[strlen(elm) + 1];
			strcpy(el, elm);
			return;
		}

		char* xel = 0;
		xel = new char[strlen(elm) + 10];
		memset(xel, 0, strlen(elm) + 10);

		int x = 0;
		int i = 0;
		for (; ; i++)
		{
			if (elm[i] == '<')
				continue;
#ifdef ALLOW_SINGLE_QUOTE_VARIABLES
			if (elm[i] == ' ' || elm[i] == '/' || elm[i] == '\t' || elm[i] == '>' || elm[i] == '\"' || elm[i] == '\'' || elm[i] == 0)
				break;
#else
			if (elm[i] == ' ' || elm[i] == '/' || elm[i] == '\t' || elm[i] == '>' || elm[i] == '\"' || elm[i] == 0)
				break;
#endif
			xel[x++] = elm[i];
		}

		size_t Sug = XML::XMLEncode(xel, 0);
		char* ael = new char[Sug + 10];
		memset(ael, 0, Sug + 10);
		XML::XMLEncode(xel, ael);

		delete[] xel;
		el = ael;

		// must be variable ?
		char* a1 = (char*)elm.operator char *() + i;
		for (;;)
		{
			// seek vars
			while (*a1 == ' ' || *a1 == '\t' || *a1 == '\r' || *a1 == '\n')
				a1++;

			if (*a1 == '>' || *a1 == '/')
				return;

			char* a2 = strchr(a1, '=');
			if (!a2)
				return;

			*a2 = 0;
			char* vvn = a1;
			a1 = a2 + 1;
			// 0x132 fix for white space after =
#ifdef ALLOW_SINGLE_QUOTE_VARIABLES
			while (*a1 != '\"' && *a1 != '\'')
#else
			while (*a1 != '\"')
#endif
			{
				if (*a1 == 0) // oups
					return;
				a1++;
			}

			char VF = '\"';
#ifdef ALLOW_SINGLE_QUOTE_VARIABLES
			if (*a1 == '\"')
				a1++;
			if (*a1 == '\'')
			{
				a1++;
				VF = '\'';
			}
			char* a3 = strchr(a1, VF);
#else
			if (*a1 == '\"')
				a1++;
			char* a3 = strchr(a1, '\"');
#endif
			if (!a3)
				return;
			*a3 = 0;

			XMLVariable* v = new XMLVariable(vvn, a1, true);
			*a2 = '=';
			*a3 = VF;
			AddVariable(v);
			a1 = a3 + 1;
		}
	}

	int XMLElement::GetDeep()
	{
		int d = 0;
		XMLElement* t = this;
		while (t->GetParent() != 0)
		{
			t = t->GetParent();
			d++;
		}
		return d;
	}

	XMLElement::XMLElement(XMLElement* par, const char* elm, int Type, bool Temp)
	{

		// parent
		parent = par;

		// Temp
		Temporal = Temp;

		// type
		type = Type;

		// children
		children = new XMLElement*[XML_MAX_INIT_CHILDREN];
		memset(children, 0, sizeof(XMLElement*)*XML_MAX_INIT_CHILDREN);
		TotalChildPointersAvailable = XML_MAX_INIT_CHILDREN;
		childrennum = 0;


		// variables
		variables = new XMLVariable*[XML_MAX_INIT_VARIABLES];
		memset(variables, 0, sizeof(XMLVariable*)*XML_MAX_INIT_VARIABLES);
		TotalVariablePointersAvailable = XML_MAX_INIT_VARIABLES;
		variablesnum = 0;

		// contents
		contents = new XMLContent*[XML_MAX_INIT_CONTENTS];
		memset(contents, 0, sizeof(XMLContent*)*XML_MAX_INIT_CONTENTS);
		TotalContentPointersAvailable = XML_MAX_INIT_CONTENTS;
		contentsnum = 0;

		// comments
		comments = new XMLComment*[XML_MAX_INIT_COMMENTS];
		memset(comments, 0, sizeof(XMLComment*)*XML_MAX_INIT_COMMENTS);
		TotalCommentPointersAvailable = XML_MAX_INIT_COMMENTS;
		commentsnum = 0;

		// cdatas
		cdatas = new XMLCData*[XML_MAX_INIT_CDATAS];
		memset(cdatas, 0, sizeof(XMLCData*)*XML_MAX_INIT_CDATAS);
		TotalCDataPointersAvailable = XML_MAX_INIT_CDATAS;
		cdatasnum = 0;

		// Borrowed Elements
		NumBorrowedElements = 0;

		// Set default format
		xfformat.nId = 1;
		xfformat.UseSpace = false;
		xfformat.ElementsNoBreak = false;

		// param 0
		param = 0;

		if (elm)
			Reparse(elm, Type);
		else
			Reparse("<root />", Type);
	}


	void XMLElement::SetTemporal(bool x)
	{
		Temporal = x;
	}

	bool XMLElement::IsTemporal()
	{
		return Temporal;
	}

	void XMLElement::Clear()
	{
		RemoveAllVariables();
		RemoveAllElements();
		RemoveAllComments();
		RemoveAllContents();
		RemoveAllCDatas();
		// element
		if (el)
			delete[] el;
		el = 0;
	}

	XMLElement :: ~XMLElement()
	{
		Clear();

		if (variables)
			delete[] variables;
		variables = 0;
		variablesnum = 0;

		if (children)
			delete[] children;
		children = 0;
		childrennum = 0;

		if (comments)
			delete[] comments;
		comments = 0;
		commentsnum = 0;

		if (contents)
			delete[] contents;
		contents = 0;
		contentsnum = 0;

		if (cdatas)
			delete[] cdatas;
		cdatas = 0;
		cdatasnum = 0;
	}



	XMLElement* XMLElement::GetParent()
	{
		return parent;
	}

	void XMLElement::SetParent(XMLElement* Parent)
	{
		parent = Parent;
	}

	XMLElement** XMLElement::GetChildren()
	{
		return children;
	}

	XMLElement* XMLElement :: operator [](int i)
	{
		return GetChildren()[i];
	}


	unsigned int XMLElement::GetChildrenNum()
	{
		return childrennum;
	}

	XMLVariable** XMLElement::GetVariables()
	{
		return variables;
	}

	unsigned int XMLElement::GetVariableNum()
	{
		return variablesnum;
	}


	int XMLElement::ReserveSpaceForElements(unsigned int i)
	{
		return SpaceForElement(i);
	}

	int XMLElement::SpaceForElement(unsigned int i)
	{
		if ((TotalChildPointersAvailable - childrennum) >= i)
			return (TotalChildPointersAvailable - childrennum);

		// make more space
		Z<XMLElement*> oldp(childrennum);
		memcpy(oldp, children, childrennum*sizeof(XMLElement*));

		TotalChildPointersAvailable += XML_MAX_INIT_CHILDREN;
		if ((TotalChildPointersAvailable - childrennum) < i)
			TotalChildPointersAvailable = childrennum + i + 10;

		delete[] children;
		children = new XMLElement*[TotalChildPointersAvailable];
		memcpy(children, oldp, childrennum*sizeof(XMLElement*));
		return (TotalChildPointersAvailable - childrennum);
	}


	int XMLElement::SpaceForVariable(unsigned int i)
	{
		if ((TotalVariablePointersAvailable - variablesnum) >= i)
			return (TotalVariablePointersAvailable - variablesnum);

		Z<XMLVariable*> oldp(variablesnum);
		memcpy(oldp, variables, variablesnum*sizeof(XMLVariable*));

		TotalVariablePointersAvailable += XML_MAX_INIT_VARIABLES;

		delete[] variables;
		variables = new XMLVariable*[TotalVariablePointersAvailable];
		memcpy(variables, oldp, variablesnum*sizeof(XMLVariable*));
		return (TotalVariablePointersAvailable - variablesnum);
	}

	int XMLElement::SpaceForComment(unsigned int i)
	{
		if ((TotalCommentPointersAvailable - commentsnum) >= i)
			return (TotalCommentPointersAvailable - commentsnum);

		Z<XMLComment*> oldp(commentsnum);
		memcpy(oldp, comments, commentsnum*sizeof(XMLComment*));

		TotalCommentPointersAvailable += XML_MAX_INIT_COMMENTS;

		delete[] comments;
		comments = new XMLComment*[TotalCommentPointersAvailable];
		memcpy(comments, oldp, commentsnum*sizeof(XMLComment*));
		return (TotalCommentPointersAvailable - commentsnum);
	}
	int XMLHeader::SpaceForComment(unsigned int i)
	{
		if ((TotalCommentPointersAvailable - commentsnum) >= i)
			return (TotalCommentPointersAvailable - commentsnum);

		Z<XMLComment*> oldp(commentsnum);
		memcpy(oldp, comments, commentsnum*sizeof(XMLComment*));

		TotalCommentPointersAvailable += XML_MAX_INIT_COMMENTS;

		delete[] comments;
		comments = new XMLComment*[TotalCommentPointersAvailable];
		memcpy(comments, oldp, commentsnum*sizeof(XMLComment*));
		return (TotalCommentPointersAvailable - commentsnum);
	}

	int XMLElement::SpaceForCData(unsigned int i)
	{
		if ((TotalCDataPointersAvailable - cdatasnum) >= i)
			return (TotalCDataPointersAvailable - commentsnum);

		Z<XMLCData*> oldp(cdatasnum);
		memcpy(oldp, cdatas, cdatasnum*sizeof(XMLCData*));

		TotalCDataPointersAvailable += XML_MAX_INIT_CDATAS;

		delete[] cdatas;
		cdatas = new XMLCData*[TotalCDataPointersAvailable];
		memcpy(cdatas, oldp, cdatasnum*sizeof(XMLCData*));
		return (TotalCDataPointersAvailable - cdatasnum);
	}


	int XMLElement::SpaceForContent(unsigned int i)
	{
		if ((TotalContentPointersAvailable - contentsnum) >= i)
			return (TotalContentPointersAvailable - contentsnum);

		Z<char*> oldp(contentsnum);
		memcpy(oldp, contents, contentsnum*sizeof(char*));

		TotalContentPointersAvailable += XML_MAX_INIT_CONTENTS;

		delete[] contents;
		contents = new XMLContent*[TotalContentPointersAvailable];
		memcpy(contents, oldp, contentsnum*sizeof(XMLContent*));
		return (TotalContentPointersAvailable - contentsnum);
	}


	XMLElement* XMLElement::AddElement(XMLElement* child)
	{
		SpaceForElement(1);
		children[childrennum++] = child;
		child->SetParent(this);
		return child;
	}
	XMLElement* XMLElement::AddElement(const char* t)
	{
		XMLElement* x = new XMLElement(this, t, 0, 0);
		return AddElement(x);
	}

	int XMLElement::AddVariable(XMLVariable* v)
	{
		SpaceForVariable(1);
		variables[variablesnum++] = v;
		v->SetOwnerElement(this);
		return variablesnum;
	}
	int XMLElement::AddVariable(const char* vn, const char* vv)
	{
		XMLVariable* x = new XMLVariable(vn, vv, 0, 0);
		return AddVariable(x);
    }

	int XMLElement::AddVariableDateTime(const char* vn, const TDateTime &time)
	{
		char str[80];

		sprintf(str, "%04d-%02d-%02dT%02d:%02d:%02d", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec());

		return AddVariable(vn, str);
	}

	int XMLElement::AddVariableBool(const char* vn, int val)
	{
		char str[40];

		if (val)
			strcpy(str, "true");
		else
			strcpy(str, "false");

		return AddVariable(vn, str);
	}

	int XMLElement::AddVariableInt(const char* vn, int val)
	{
		char str[40];

		sprintf(str, "%d", val);
		return AddVariable(vn, str);
	}

	int XMLElement::AddVariableUInt(const char* vn, unsigned int val)
	{
		char str[40];

		sprintf(str, "%u", val);
		return AddVariable(vn, str);
	}

	int XMLElement::AddBinaryVariable(const char* vn, const char* vv, int S)
	{
		XMLVariable* x = new XMLVariable(vn, "");
		Z<char> tmp(S + 1);
		memcpy(tmp, vv, S);
		x->SetBinaryValue(tmp, S);
		return AddVariable(x);
	}

	int XMLElement::AddComment(XMLComment* v, int InsertBeforeElement)
	{
		SpaceForComment(1);
		comments[commentsnum++] = v;
		v->SetParent(this, InsertBeforeElement);
		return commentsnum;
	}
	int XMLElement::AddComment(const char*t, int InsertBeforeElement)
	{
		XMLComment* x = new XMLComment(this, InsertBeforeElement, t);
		return AddComment(x, InsertBeforeElement);
	}
	unsigned int XMLElement::GetCommentsNum()
	{
		return commentsnum;
	}

	XMLComment** XMLElement::GetComments()
	{
		return comments;
	}


	int XMLElement::RemoveAllComments()
	{
		for (int i = commentsnum - 1; i >= 0; i--)
		{
			delete comments[i];
			comments[i] = 0;
		}
		commentsnum = 0;
		return 0;
	}


	int XMLElement::RemoveComment(unsigned int i)
	{
		if (i >= commentsnum)
			return commentsnum;

		delete comments[i];
		comments[i] = 0;

		for (unsigned int k = i; k < commentsnum; k++)
			comments[k] = comments[k + 1];

		comments[commentsnum - 1] = 0;
		return --commentsnum;
	}


	int XMLElement::AddCData(XMLCData* v, int InsertBeforeElement)
	{
		SpaceForCData(1);
		cdatas[cdatasnum++] = v;
		v->SetParent(this, InsertBeforeElement);
		return cdatasnum;
	}
	int XMLElement::AddCData(const char*t, int InsertBeforeElement)
	{
		XMLCData* x = new XMLCData(this, InsertBeforeElement, t);
		return AddCData(x, InsertBeforeElement);
	}
	unsigned int XMLElement::GetCDatasNum()
	{
		return cdatasnum;
	}
	XMLCData** XMLElement::GetCDatas()
	{
		return cdatas;
	}
	int XMLElement::RemoveAllCDatas()
	{
		for (int i = cdatasnum - 1; i >= 0; i--)
		{
			delete cdatas[i];
			cdatas[i] = 0;
		}
		cdatasnum = 0;
		return 0;
	}
	int XMLElement::RemoveCData(unsigned int i)
	{
		if (i >= cdatasnum)
			return cdatasnum;

		delete cdatas[i];
		cdatas[i] = 0;

		for (unsigned int k = i; k < cdatasnum; k++)
			cdatas[k] = cdatas[k + 1];

		cdatas[cdatasnum - 1] = 0;
		return --cdatasnum;
	}


	// Content class
	int XMLElement::AddContent(XMLContent* v, int InsertBeforeElement)
	{
		SpaceForContent(1);
		contents[contentsnum++] = v;
		v->SetParent(this, InsertBeforeElement);
		return contentsnum;
	}

	int XMLElement::AddContent(const char* t, int InsertBeforeElement, int BinarySize)
	{
		XMLContent* x = new XMLContent(this, InsertBeforeElement, t, 0, BinarySize);
		return AddContent(x, InsertBeforeElement);
	}

	int XMLElement::RemoveContent(unsigned int i)
	{
		if (i >= contentsnum)
			return contentsnum;

		delete contents[i];
		contents[i] = 0;

		for (unsigned int k = i; k < contentsnum; k++)
			contents[k] = contents[k + 1];

		contents[contentsnum - 1] = 0;
		return --contentsnum;
	}

	void XMLElement::RemoveAllContents()
	{
		for (int i = contentsnum - 1; i >= 0; i--)
		{
			delete contents[i];
			contents[i] = 0;
		}
		contentsnum = 0;
	}

	XMLContent** XMLElement::GetContents()
	{
		return contents;
	}

	unsigned int XMLElement::GetContentsNum()
	{
		return contentsnum;
	}

	TString XMLElement::GetContentString(const char *def)
	{
            if (contentsnum == 0)
                return TString(def);
            else
            {
                int len = contents[0]->GetValue(0);
                char *str = new char[len + 1];
                contents[0]->GetValue(str);
                TString ret(str);
                delete str;                
                return ret;
            }
	}

	TDateTime XMLElement::GetContentDateTime(TDateTime &def)
	{
            if (contentsnum == 0)
                return def;
            else
            {
                int year, month, day;
                int hour, min, sec;
                int count;
                int len = contents[0]->GetValue(0);
                char *str = new char[len + 1];

                year = 1970;
                month = 1;
                day = 1;
                hour = 0;
                min = 0;
                sec = 0;

                contents[0]->GetValue(str);

                count = sscanf(str, "%04d-%02d-%02dT%02d:%02d:%02d", &year, &month, &day, &hour, &min, &sec);
                TDateTime ret(year, month, day, hour, min, sec);
                delete str;                
                return ret;
            }
	}

	int XMLElement::GetContentInt(int def)
	{
            int val = def;

            if (contentsnum)
            {
                int len = contents[0]->GetValue(0);
                char *str = new char[len + 1];

                contents[0]->GetValue(str);
		val = atoi(str);
                delete str;                
            }
            return val;
	}

	unsigned int XMLElement::GetContentUInt(unsigned int def)
	{
            unsigned int x = def;

            if (contentsnum)
            {
                int len = contents[0]->GetValue(0);
                char *str = new char[len + 1];

                x = 0;
                contents[0]->GetValue(str);
		sscanf(str, "%u", &x);
                delete str;                
            }
            return x;
	}

	double XMLElement::GetContentDouble(double def)
	{
            double val = def;

            if (contentsnum)
            {
                int len = contents[0]->GetValue(0);
                char *str = new char[len + 1];

                contents[0]->GetValue(str);
		val = atof(str);
                delete str;                
            }
            return val;
	}

	long long XMLElement::GetContentInt64(long long def)
	{
            long long x = def;

            if (contentsnum)
            {
                int len = contents[0]->GetValue(0);
                char *str = new char[len + 1];

		x = 0;
                contents[0]->GetValue(str);
		sscanf(str, "%lld", &x);
                delete str;                
            }
            return x;
	}

	unsigned long long XMLElement::GetContentUInt64(unsigned long long def)
	{
            unsigned long long x = def;

            if (contentsnum)
            {
                int len = contents[0]->GetValue(0);
                char *str = new char[len + 1];

		x = 0;
                contents[0]->GetValue(str);
		sscanf(str, "%llud", &x);
                delete str;                
            }
            return x;
	}

	bool XMLElement::GetContentBoolean(bool def)
	{
            bool val = def;

            if (contentsnum)
            {
                int len = contents[0]->GetValue(0);
                char *str = new char[len + 1];

                contents[0]->GetValue(str);
                if (!strcmp(str, "true"))
                    val = true;
                else
                    val = atoi(str);
                delete str;                
            }
            return val;
	}

	TString XMLElement::GetContentString(const char *tag, const char *def)
	{
            XMLElement *elem = GetElement(tag);

            if (elem)
                return elem->GetContentString(def);
            else
                return TString(def);
	}

	TDateTime XMLElement::GetContentDateTime(const char *tag, TDateTime &def)
	{
            XMLElement *elem = GetElement(tag);

            if (elem)
                return elem->GetContentDateTime(def);
            else
                return TDateTime();
	}

	int XMLElement::GetContentInt(const char *tag, int def)
	{
            XMLElement *elem = GetElement(tag);

            if (elem)
                return elem->GetContentInt(def);
            else
                return def;
	}

	unsigned int XMLElement::GetContentUInt(const char *tag, unsigned int def)
	{
            XMLElement *elem = GetElement(tag);

            if (elem)
                return elem->GetContentUInt(def);
            else
                return def;
	}

	double XMLElement::GetContentDouble(const char *tag, double def)
	{
            XMLElement *elem = GetElement(tag);

            if (elem)
                return elem->GetContentDouble(def);
            else
                return def;
	}

	long long XMLElement::GetContentInt64(const char *tag, long long def)
	{
            XMLElement *elem = GetElement(tag);

            if (elem)
                return elem->GetContentInt64(def);
            else
                return def;
	}

	unsigned long long XMLElement::GetContentUInt64(const char *tag, unsigned long long def)
	{
            XMLElement *elem = GetElement(tag);

            if (elem)
                return elem->GetContentUInt64(def);
            else
                return def;
	}

	bool XMLElement::GetContentBoolean(const char *tag, bool def)
	{
            XMLElement *elem = GetElement(tag);

            if (elem)
                return elem->GetContentBoolean(def);
            else
                return def;
	}


	void XMLElement::AddContentString(TString str)
	{
                AddContent(str.GetData(), -1, 0);
	}

	void XMLElement::AddContentInt(int val)
	{
		char str[40];

                sprintf(str, "%d", val);
                AddContent(str, -1, 0);
	}

	void XMLElement::AddContentDouble(double val, int decimals)
	{
		double temp;
		int digits;
		char str[80];
		char formstr[40];

		if (decimals < 0)
		        decimals = 0;

	        temp = val;

	        if (temp < 0)
        	{
	            digits = 2;
        	    temp = -temp;
	        }
        	else
	            digits = 1;

	        if (temp >= 1e+16)
		{
			sprintf(str, "%Lf", val);
	        }
		else
		{
			while (temp >= 10.0)
			{
				digits++;
				temp = temp / 10.0;
			}

			sprintf(formstr, "%%%d.%dLf", digits + decimals + 1, decimals);
			sprintf(str, formstr, val);
		}
                AddContent(str, -1, 0);
	}

	void XMLElement::AddContentUInt(unsigned int val)
	{
		char str[40];

                sprintf(str, "%u", val);
                AddContent(str, -1, 0);
	}

	void XMLElement::AddContentInt64(long long val)
	{
		char str[40];

                sprintf(str, "%lld", val);
                AddContent(str, -1, 0);
	}

	void XMLElement::AddContentUInt64(unsigned long long val)
	{
		char str[40];

                sprintf(str, "%llu", val);
                AddContent(str, -1, 0);
	}

	void XMLElement::AddContentBoolean(bool val)
	{
		char str[40];

                sprintf(str, "%d", val);
                AddContent(str, -1, 0);
	}

	void XMLElement::AddContentDateTime(const TDateTime &time)
	{
		char str[80];

		sprintf(str, "%04d-%02d-%02dT%02d:%02d:%02d", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec());
                AddContent(str, -1, 0);
	}



	XMLElement *XMLElement::AddContentString(const char *tag, TString str)
	{
                XMLElement *elem = AddElement(tag);
                elem->AddContentString(str);
		return elem;
	}

	XMLElement *XMLElement::AddContentInt(const char *tag, int val)
	{
                XMLElement *elem = AddElement(tag);
                elem->AddContentInt(val);
		return elem;
	}

	XMLElement *XMLElement::AddContentUInt(const char *tag, unsigned int val)
	{
                XMLElement *elem = AddElement(tag);
                elem->AddContentUInt(val);
		return elem;
	}

	XMLElement *XMLElement::AddContentDouble(const char *tag, double val, int decimals)
	{
                XMLElement *elem = AddElement(tag);
                elem->AddContentDouble(val, decimals);
		return elem;
	}

	XMLElement *XMLElement::AddContentInt64(const char *tag, long long val)
	{
                XMLElement *elem = AddElement(tag);
                elem->AddContentInt64(val);
		return elem;
	}

	XMLElement *XMLElement::AddContentUInt64(const char *tag, unsigned long long val)
	{
                XMLElement *elem = AddElement(tag);
                elem->AddContentUInt64(val);
		return elem;
	}

	XMLElement *XMLElement::AddContentBoolean(const char *tag, bool val)
	{
                XMLElement *elem = AddElement(tag);
                elem->AddContentBoolean(val);
		return elem;
	}

	XMLElement *XMLElement::AddContentDateTime(const char *tag, const TDateTime &time)
	{
                XMLElement *elem = AddElement(tag);
                elem->AddContentDateTime(time);
		return elem;
	}

	unsigned int XMLElement::GetAllChildren(XMLElement** x, unsigned int deep)
	{
		int C = 0;
		for (unsigned int i = 0; i < childrennum && deep != 0; i++)
		{
			if (!children[i])
				continue;
			XMLElement* ch = children[i];
			C += ch->GetAllChildren(x + C, deep == 0xFFFFFFFF ? deep : (deep - 1));
			x[C++] = ch;
		}

		return C;
	}

	unsigned int XMLElement::GetAllChildrenNum(unsigned int deep)
	{
		int C = 0;
		for (unsigned int i = 0; i < childrennum && deep != 0; i++)
		{
			if (!children[i])
				continue;
			C += children[i]->GetAllChildrenNum(deep == 0xFFFFFFFF ? deep : (deep - 1));
		}
		C += childrennum;
		return C;
	}


	// XMLComment class
	XMLComment::XMLComment(XMLElement* p, int ElementPosition, const char* ht)
	{
		parent = p;
		ep = ElementPosition;
		if (!ht)
			ht = " ";
		c = new char[strlen(ht) + 1];
		strcpy(c, ht);
	}

	XMLComment::XMLComment(const XMLComment& h)
	{
		operator =(h);
	}

	XMLComment& XMLComment :: operator =(const XMLComment& h)
	{
		if (c)
			delete[] c;
		c = 0;

		parent = h.parent;
		ep = h.GetEP();
		const char* ht = h.operator const char*();
		c = new char[strlen(ht) + 1];
		strcpy(c, ht);
		return *this;
	}


	XMLComment :: ~XMLComment()
	{
		if (c)
			delete[] c;
		c = 0;
	}

	XMLComment :: operator const char*() const
	{
		return c;
	}


	void XMLComment::SetComment(const char* ht)
	{
		if (c)
			delete[] c;
		c = new char[strlen(ht) + 1];
		strcpy(c, ht);
	}

	void XMLComment::SetParent(XMLElement* p, int epp)
	{
		parent = p;
		ep = epp;
	}

	int XMLComment::GetEP() const
	{
		return ep;
	}


	// XMLCData class
	XMLCData::XMLCData(XMLElement* p, int ElementPosition, const char* ht)
	{
		parent = p;
		ep = ElementPosition;
		c = new char[strlen(ht) + 1];
		strcpy(c, ht);
	}

	XMLCData::XMLCData(const XMLCData& h)
	{
		operator =(h);
	}

	XMLCData& XMLCData :: operator =(const XMLCData& h)
	{
		if (c)
			delete[] c;
		c = 0;
		parent = h.parent;
		ep = h.GetEP();
		const char* ht = h.operator const char*();
		c = new char[strlen(ht) + 1];
		strcpy(c, ht);
		return *this;
	}


	XMLCData :: ~XMLCData()
	{
		if (c)
			delete[] c;
		c = 0;
	}

	XMLCData :: operator const char*() const
	{
		return c;
	}


	void XMLCData::SetCData(const char* ht)
	{
		if (c)
			delete[] c;
		size_t nht = strlen(ht);
		c = new char[nht + 1];
		strcpy(c, ht);
	}

	void XMLCData::SetParent(XMLElement* p, int epp)
	{
		parent = p;
		ep = epp;
	}

	int XMLCData::GetEP() const
	{
		return ep;
	}


	// XMLContent class
	XMLContent::XMLContent(XMLElement* p, int ElementPosition, const char* ht, int NoDecode, int BinarySize)
	{
		parent = p;
		ep = ElementPosition;
		c = 0;
		BinaryMode = 0;
		if (ht)
			SetValue(ht, NoDecode, BinarySize);
	}

	void XMLContent::SetBinaryMode(bool bm)
	{
		BinaryMode = bm;
	}
	bool XMLContent::IsInBinaryMode() const
	{
		return BinaryMode;
	}


	XMLContent::XMLContent(const XMLContent& h)
	{
		operator =(h);
	}

	XMLContent& XMLContent :: operator =(const XMLContent& h)
	{
		if (c)
			delete[] c;
		c = 0;
		bdc.clear();
		BinaryMode = false;

		parent = h.parent;
		ep = h.GetEP();
		if (h.IsInBinaryMode())
		{
			BinaryMode = true;
			bdc = h.bdc;
			return *this;
		}

		size_t k = h.GetValue(0, true);
		Z<char> vv(k + 10);
		h.GetValue(vv, true);
		SetValue(vv, true);
		return *this;
	}


	XMLContent :: ~XMLContent()
	{
		if (c)
			delete[] c;
		c = 0;
		bdc.clear();
	}

	bool XMLContent::GetBinaryValue(char**o, unsigned int* len)
	{
		if (BinaryMode)
		{
			if (!o || !len)
				return false;
			char* oo = new char[(unsigned int)(bdc.size() + 1)];
			memcpy(oo, bdc.p(), (size_t)bdc.size());
			*len = (unsigned int)bdc.size();
			return true;
		}
		if (!o || !len)
			return false;

		const char* d = 0;
		int ll = 0;
		d = c;
		if (!d)
			return false;
		ll = (int)strlen(d);

		char* a = new char[ll * 5 + 1000];
		memset(a, 0, ll * 5 + 1000);

		char *oo;
		MimeCoder<char*, char*>* e;
		e = new Base64Decoder<char*, char*>;
		oo = e->Filter(a, (char*)d, (char*)d + ll);
		oo = e->Finish(oo);
		*oo = 0;                  // Put a zero to the end
		delete e;

		*o = a;
		int newlen = (int)(oo - a);
		*len = newlen;
		return true;
	}

	size_t XMLContent::GetValue(char* x, int NoDecode) const
	{
		if (BinaryMode)
			return 0;

		if (!x)
		{
			if (NoDecode)
				return strlen(c);
			else
				return XML::XMLDecode(c, 0);
		}

		if (NoDecode)
			strcpy(x, c);
		else
			XML::XMLDecode(c, x);
		return strlen(x);
	}


	void XMLContent::SetValue(const char* VV, int NoDecode, int BinarySize)
	{
		if (BinaryMode)
		{
			if (!VV)
				return;

			if (BinarySize == 0)
				BinarySize = (int)strlen(VV);
			bdc.Resize(BinarySize);
			if (BinarySize)
				memcpy(bdc.p(), VV, BinarySize);
			return;
		}

		if (BinarySize)
		{
			// Add binary data, do base64


			// Sets value using MIME
			char* a = new char[BinarySize * 5 + 1000];
			memset(a, 0, BinarySize * 5 + 1000);

			char *oo;
			MimeCoder<char*, char*>* e;
			e = new Base64Encoder<char*, char*>;
			oo = e->Filter(a, (char*)VV, (char*)VV + BinarySize);
			oo = e->Finish(oo);
			*oo = 0;                  // Put a zero to the end
			delete e;

			SetValue(a, true, 0);
			delete[] a;
			return;
		}

		if (c)
			delete[] c;
		size_t Sug = XML::XMLEncode(VV, 0);

		c = new char[Sug + 10];
		memset(c, 0, Sug + 10);

		if (NoDecode)
			strcpy(c, VV);
		else
			XML::XMLEncode(VV, c);

	}

	void XMLContent::SetParent(XMLElement* p, int epp)
	{
		parent = p;
		ep = epp;
	}

	int XMLContent::GetEP() const
	{
		return ep;
	}



	// XMLHeader class
	XMLHeader::XMLHeader(const char* ht)
	{
		if (ht)
		{
			hdr = new char[strlen(ht) + 1];
			strcpy(hdr, ht);
		}
		else
		{
			hdr = new char[100];
			memset(hdr, 0, 100);
		}

		// comments
		comments = new XMLComment*[XML_MAX_INIT_COMMENTS_HEADER];
		memset(comments, 0, sizeof(XMLComment*)*XML_MAX_INIT_COMMENTS_HEADER);
		TotalCommentPointersAvailable = XML_MAX_INIT_COMMENTS_HEADER;
		commentsnum = 0;
	}

	XMLHeader::XMLHeader(XMLHeader& h)
	{
		operator =(h);
	}

	void XMLHeader::Clear()
	{
		if (hdr)
			delete[] hdr;
		hdr = 0;

		RemoveAllComments();
		if (comments)
			delete[] comments;
		comments = 0;
		commentsnum = 0;
	}

	XMLHeader& XMLHeader :: operator =(XMLHeader& h)
	{
		Clear();

		const char*ht = h.operator const char*();
		hdr = new char[strlen(ht) + 1];
		strcpy(hdr, ht);

		// comments
		comments = new XMLComment*[XML_MAX_INIT_COMMENTS_HEADER];
		memset(comments, 0, sizeof(XMLComment*)*XML_MAX_INIT_COMMENTS_HEADER);
		TotalCommentPointersAvailable = XML_MAX_INIT_COMMENTS_HEADER;
		commentsnum = 0;
		// Add comments from h
		int yC = h.GetCommentsNum();
		for (int i = 0; i < yC; i++)
		{
			AddComment(h.GetComments()[i]->Duplicate(), h.GetComments()[i]->GetEP());
		}

		return *this;
	}


	XMLHeader :: ~XMLHeader()
	{
		Clear();
	}

	XMLHeader :: operator const char*()
	{
		return hdr;
	}

	void XMLHeader::SetEncoding(const char* e)
	{
		// 
		Z<char> nt(1000);
		sprintf(nt, "<?xml version=\"1.0\" encoding=\"%s\" standalone=\"yes\" ?>", e); // IFSF	
		size_t sl = strlen(nt) + 1;
		delete[] hdr;
		hdr = new char[sl];
		memset(hdr, 0, sl);
		strcpy(hdr, nt);
	}
	void XMLHeader::SetVersion(const char* e)
	{
		// 
		Z<char> nt(1000);
		sprintf(nt, "<?xml version=\"%s\"?>", e); // TST
		size_t sl = strlen(nt) + 1;
		delete[] hdr;
		hdr = new char[sl];
		memset(hdr, 0, sl);
		strcpy(hdr, nt);
	}

	XMLHeader* XMLHeader::Duplicate()
	{
		XMLHeader* hz = new XMLHeader(hdr);
		// Add All Comments
		int y = GetCommentsNum();
		for (int i = 0; i < y; i++)
		{
			hz->AddComment(GetComments()[i]->Duplicate(), GetComments()[i]->GetEP());
		}


		return hz;
	}

	int XMLHeader::AddComment(XMLComment* v, int pos)
	{
		SpaceForComment(1);
		comments[commentsnum++] = v;
		v->SetParent(0, pos);
		return commentsnum;
	}


	unsigned int XMLHeader::GetCommentsNum()
	{
		return commentsnum;
	}

	XMLComment** XMLHeader::GetComments()
	{
		return comments;
	}


	int XMLHeader::RemoveAllComments()
	{
		for (int i = commentsnum - 1; i >= 0; i--)
		{
			delete comments[i];
			comments[i] = 0;
		}
		commentsnum = 0;
		return 0;
	}


	int XMLHeader::RemoveComment(unsigned int i)
	{
		if (i >= commentsnum)
			return commentsnum;

		delete comments[i];
		comments[i] = 0;

		for (unsigned int k = i; k < commentsnum; k++)
			comments[k] = comments[k + 1];

		comments[commentsnum - 1] = 0;
		return --commentsnum;
	}


	void XMLHeader::Export(FILE* fp, int HeaderMode, XML_TARGET_MODE TargetMode, class XMLTransform* eclass, class XMLTransformData* edata)
	{
		if (TargetMode == 1)
		{
			if (HeaderMode == 0)
				sprintf((char*)fp, "%s\r\n", hdr);
			for (unsigned int i = 0; i < commentsnum; i++)
			{
				if (comments[i]->GetEP() == HeaderMode)
					sprintf((char*)fp, "<!--%s-->\r\n", comments[i]->operator const char *());
			}
			return;
		}

		if (TargetMode == 2)
		{
			return;

		}

		if (TargetMode == 0) // UTF-8
		{
			if (HeaderMode == 0)
				fprintf(fp, "%s\r\n", hdr);
			for (unsigned int i = 0; i < commentsnum; i++)
			{
				if (comments[i]->GetEP() == HeaderMode)
					fprintf(fp, "<!--%s-->\r\n", comments[i]->operator const char *());
			}
		}
	}



	// XMLVariable class
	void XMLVariable::SetName(const char* VN, int NoDecode)
	{
		if (vn)
			delete[] vn;
		size_t Sug = XML::XMLEncode(VN, 0);
		vn = new char[Sug + 10];
		memset(vn, 0, Sug + 10);
		if (NoDecode)
			strcpy(vn, VN);
		else
			XML::XMLEncode(VN, vn);

		// 0x132 fix for white space at the end of the variable
		while (vn[strlen(vn) - 1] == ' ')
			vn[strlen(vn) - 1] = 0;
	}

	void XMLVariable::SetValue(const char* VV, int NoDecode)
	{
		if (vv)
			delete[] vv;
		size_t Sug = XML::XMLEncode(VV, 0);
		vv = new char[Sug + 10];
		memset(vv, 0, Sug + 10);
		if (NoDecode)
			strcpy(vv, VV);
		else
			XML::XMLEncode(VV, vv);
	}

	XMLVariable::XMLVariable(const char* VN, const char* VV, int NoDecode, bool Temp)
	{
		vn = 0;
		vv = 0;
		owner = 0;
		Temporal = Temp;
		SetName(VN, NoDecode);
		SetValue(VV, NoDecode);
	}

	void XMLVariable::SetTemporal(bool x)
	{
		Temporal = x;
	}

	bool XMLVariable::IsTemporal()
	{
		return Temporal;
	}

	XMLElement* XMLVariable::SetOwnerElement(XMLElement* o)
	{
		XMLElement* oldowner = owner;
		owner = o;
		return oldowner;
	}

	XMLElement* XMLVariable::GetOwnerElement()
	{
		return owner;
	}

	void XMLVariable::Clear()
	{
		if (vn)
			delete[] vn;
		vn = 0;

		if (vv)
			delete[] vv;
		vv = 0;
	}

	XMLVariable :: ~XMLVariable()
	{
		Clear();
	}

	XMLVariable::XMLVariable(const XMLVariable& h)
	{
		operator =(h);
	}

	XMLVariable& XMLVariable :: operator =(const XMLVariable& h)
	{
		Clear();

		owner = h.owner;
		Temporal = h.Temporal;

		size_t n = h.GetName(0, true);
		Z<char> nn(n + 10);
		h.GetName(nn, true);
		SetName(nn, true);

		size_t k = h.GetValue(0, true);
		Z<char> vv(k + 10);
		h.GetValue(vv, true);
		SetValue(vv, true);
		return *this;
	}


	size_t XMLVariable::GetName(char* x, int NoDecode) const
	{
		if (!x)
		{
			if (NoDecode)
				return strlen(vn);
			else
				return XML::XMLDecode(vn, 0);
		}

		if (NoDecode)
			strcpy(x, vn);
		else
			XML::XMLDecode(vn, x);
		return strlen(x);
	}

	size_t XMLVariable::GetValue(char* x, int NoDecode) const
	{
		if (!x)
		{
			if (NoDecode)
				return strlen(vv);
			else
				return XML::XMLDecode(vv, 0);
		}
		if (NoDecode)
			strcpy(x, vv);
		else
			XML::XMLDecode(vv, x);
		return strlen(x);
	}

	int XMLVariable::GetValueInt()
	{
		size_t p = GetValue(0);
		Z<char> d(p + 10);
		GetValue(d);
		return atoi(d);
	}

	unsigned int XMLVariable::GetValueUInt()
	{
		size_t p = GetValue(0);
		Z<char> d(p + 10);
		GetValue(d);
		unsigned long x = 0;
		sscanf(d, "%u", &x);
		return x;
	}

	double XMLVariable::GetValueDouble()
	{
		size_t p = GetValue(0);
		Z<char> d(p + 10);
		GetValue(d);
		return atof(d);
	}


	long long XMLVariable::GetValueInt64()
	{
		size_t p = GetValue(0);
		Z<char> d(p + 10);
		GetValue(d);
		long long x = 0;
		sscanf(d, "%I64i", &x);
		return x;
	}

	unsigned long long XMLVariable::GetValueUInt64()
	{
		size_t p = GetValue(0);
		Z<char> d(p + 10);
		GetValue(d);
		unsigned long long x = 0;
		sscanf(d, "%I64u", &x);
		return x;
	}

int XMLVariable :: GetValueHex()
        {
        int count = 0;
        int val;
        size_t p = GetValue(0);
        Z<char> d(p + 10);
        GetValue(d);

        char str[10];
        int pos = 8 - p;
        int i;

        if (pos >= 0)
        {
            memcpy(&str[pos], d, p);
            str[8] = 0;

            for (i = 0; i < pos; i++)
                str[i] = '0';
             
            count = sscanf(str, "%08lXu", &val);
        }

        if (count)
            return val;
        else
            return 0;
        }

TString XMLVariable :: GetValueString()
        {
        int count = 0;
        int len = GetValue(0);
        char *str = new char[len + 1];
        GetValue(str);

        TString ret(str);
        delete str;                
        return ret;
	}

	TDateTime XMLVariable::GetValueDateTime()
	{
            int year, month, day;
            int hour, min, sec;
            int count;
            int len = GetValue(0);
            char *str = new char[len + 1];

            GetValue(str);

            year = 1970;
            month = 1;
            day = 1;
            hour = 0;
            min = 0;
            sec = 0;

            count = sscanf(str, "%04d-%02d-%02dT%02d:%02d:%02d", &year, &month, &day, &hour, &min, &sec);
            
            TDateTime ret(year, month, day, hour, min, sec);
            delete str;                
            return ret;
	}

	bool XMLVariable::GetValueBoolean()
	{
		size_t p = GetValue(0);
		Z<char> d(p + 10);
		GetValue(d);
                if (!strcmp(d, "true"))
                    return true;
                else
    		    return atoi(d);
	}


	void XMLVariable::SetValueInt(int V)
	{
		char t[50] = { 0 };
		sprintf(t, "%i", V);
		SetValue(t);
	}
	void XMLVariable::SetValueUInt(unsigned int V)
	{
		char t[50] = { 0 };
		sprintf(t, "%u", V);
		SetValue(t);
	}

	void XMLVariable::SetValueInt64(long long V)
	{
		char t[50] = { 0 };
		sprintf(t, "%I64i", V);
		SetValue(t);
	}

	void XMLVariable::SetValueUInt64(unsigned long long V)
	{
		char t[50] = { 0 };
		sprintf(t, "%I64u", V);
		SetValue(t);
	}

	float XMLVariable::GetValueFloat()
	{
		size_t p = GetValue(0);
		Z<char> d(p + 10);
		GetValue(d);
		return (float)atof(d);
	}

	void XMLVariable::SetFormattedValue(const char* fmt, ...)
	{
		va_list args;
		va_start(args, fmt);
		Z<char> data(10000);
		vsprintf(data, fmt, args);
		SetValue(data);
		va_end(args);
	}




	void XMLVariable::SetValueFloat(float V)
	{
		//      char t[50] = {0};
		//      sprintf(t,"%f",V);
		//      SetValue(t);
		SetValueX(V, "%f");
	}

	template <typename T> void XMLVariable::SetValueX(T ty, const char* fmt)
	{
		char t[50] = { 0 };
		sprintf(t, fmt, ty);
		SetValue(t);
	}

	template <typename T> T XMLVariable::GetValueX(const char* fmt)
	{
		char t[50] = { 0 };
		GetValue(t);
		T ty;
		sscanf(t, fmt, &ty);
		return ty;
	}


	void XMLVariable::Copy()
	{
	}

	XMLVariable* XMLVariable::Duplicate()
	{
		// returns a copy of myself
		size_t s1 = GetName(0);
		size_t s2 = GetValue(0);
		Z<char> x1(s1 + 100);
		Z<char> x2(s2 + 100);
		GetName(x1);
		GetValue(x2);

		return new XMLVariable(x1, x2, 0);
	}


	size_t XMLVariable::SetBinaryValue(char* data, int len)
	{
		// Sets value using MIME
		char* a = new char[len * 5 + 1000];
		memset(a, 0, len * 5 + 1000);

		char *oo;
		MimeCoder<char*, char*>* e;
		e = new Base64Encoder<char*, char*>;
		oo = e->Filter(a, data, data + len);
		oo = e->Finish(oo);
		*oo = 0;                  // Put a zero to the end
		delete e;

		//      CBase64 b;
		//      b.Encrypt(data,len,a);
		size_t I = strlen(a);
		for (size_t i = 0; I > 0 && i < (I - 1); i++)
		{
			if (a[i] == '\r' && a[i + 1] == '\n')
			{
				a[i] = '_';
				a[i + 1] = '_';
			}
		}
		SetValue(a, false);

		delete[] a;
		return I;
	}

	size_t XMLVariable::GetBinaryValue(char* data)
	{
		size_t aL = GetValue(0);
		if (!aL)
			return 0;

		Z<char> bdata(aL + 100);
		GetValue(bdata);

		for (unsigned int i = 0; i < (strlen(bdata) - 1); i++)
		{
			if (bdata[i] == '_' && bdata[i + 1] == '_')
			{
				bdata[i] = '\r';
				bdata[i + 1] = '\n';
			}
		}


		Z<char> oout(aL + 1000);


		char *oo;
		MimeCoder<char*, char*>* e;
		e = new Base64Decoder<char*, char*>;
		oo = e->Filter(oout, bdata.operator char*(), bdata.operator char*() + aL);
		oo = e->Finish(oo);
		*oo = 0;                  // Put a zero to the end
		delete e;
		size_t S = oo - oout.operator char*();

		//      CBase64 b;
		//      char* dstp = (char*)b.Decrypt(bdata,aL,oout);
		//      size_t S = dstp - oout;

		if (!data)
		{
			return S;
		}
		else
		{
			memcpy(data, oout, S);
			return S;
		}
	}


	bool XMLElement::EncryptElement(unsigned int i, char* pwd)
	{
		if (i >= GetChildrenNum())
			return false;
		XMLElement* j = children[i];
		XMLElement* nj = j->Encrypt(pwd);
		if (!nj)
			return false;
		RemoveElement(i);
		InsertElement(0, nj);
		return true;
	}
	bool XMLElement::DecryptElement(unsigned int i, char* pwd)
	{
		if (i >= GetChildrenNum())
			return false;
		XMLElement* j = children[i];
		XMLElement* nj = j->Decrypt(pwd);
		if (!nj)
			return false;
		RemoveElement(i);
		InsertElement(0, nj);
		return true;
	}

	XMLElement* XMLElement::Encrypt(const char* pwd)
	{
		return false;
	}
	XMLElement* XMLElement::Decrypt(const char* pwd)
	{
		return false;
	}


	bool XML::TestMatch(const char* item1, const char* comp, const char* item2)
	{
		Z<char> iitem2(1000);
		if (item2[0] == '\"')
		{
			strcpy(iitem2, item2 + 1);
			if (strlen(iitem2))
				iitem2[strlen(iitem2) - 1] = 0;

			if (strcmp(comp, "==") == 0)
				return VMatching((char*)item1, (char*)iitem2);
			if (strcmp(comp, "!=") == 0)
				return !VMatching((char*)item1, (char*)iitem2);
		}
		else // integer
		{
			// Fix: Check if items are integers
			if (atoi(item1) == 0 && item1[0] != '0')
				return false;
			if (atoi(item2) == 0 && item2[0] != '0')
				return false;


			if (strcmp(comp, "==") == 0)
				return (atoi(item1) == atoi(item2));

			if (strcmp(comp, "!=") == 0)
				return (atoi(item1) != atoi(item2));

			if (strcmp(comp, ">=") == 0)
				return (atoi(item1) >= atoi(item2));

			if (strcmp(comp, "<=") == 0)
				return (atoi(item1) <= atoi(item2));

			if (strcmp(comp, "<") == 0)
				return (atoi(item1) < atoi(item2));

			if (strcmp(comp, ">") == 0)
				return (atoi(item1) > atoi(item2));
		}


		return true;
	}

	int XML::XMLQuery(const char* rootsection, const char* expression, XMLElement** rv, unsigned int deep)
	{
		XMLElement* r = root->GetElementInSection(rootsection);
		if (!r)
			return 0;
		return r->XMLQuery(expression, rv, deep);
	}

	int XMLElement::XMLQuery(const char* expression2, XMLElement** rv, unsigned int deep)
	{
		Z<char> expression(strlen(expression2) + 1);
		strcpy(expression, expression2);
		// Executes query based on expression of variables
		/*

		Valid expressions

		<item1> <comparator> <item2>[<expr> ...]

		<item1> is a variable name, or * if any variable can match or ? if it is to match
		the element name or ! if it is to match the full element name
		or ~ to match the content name

		<item2> can be either integers, or strings, or strings with ? and *
		<comparator> can be
		==
		!=
		>=
		>
		<
		<=

		MUST HAVE SPACES
		EXAMPLES

		v == "xa*"
		a >= 5


		*/

		XMLElement* r = this;

		// r is the base section
		// get all its elements
		int C = r->GetAllChildrenNum(deep);
		Z<XMLElement*> allelements(C + 10);
		r->GetAllChildren(allelements, deep);
		Z<int> positives(C + 10);
		for (int i = 0; i < C; i++)
			positives[i] = 1;

		char* a = expression.operator char *();
		for (;; )
		{
			// Parse the expression

			// Get item 1
			char* a1 = strchr(a, ' ');
			if (!a1)
				break;
			Z<char> item1(300);
			*a1 = 0;
			strcpy(item1, a);
			*a1 = ' ';
			a = a1 + 1;

			// Get comparator
			a1 = strchr(a, ' ');
			if (!a1)
				break;
			Z<char> comp(100);
			*a1 = 0;
			strcpy(comp, a);
			*a1 = ' ';
			a = a1 + 1;

			// Get item 2
			if (*a == '\"')
			{
				a1 = strchr(a + 1, '\"');
				if (a1)
					a1++;
			}
			else
				a1 = strchr(a, ' ');
			Z<char> item2(300);
			if (a1)
				*a1 = 0;
			strcpy(item2, a);
			if (a1)
			{
				*a1 = ' ';
				a = a1 + 1;
			}


			// Test this expression against all elements
			for (int y = 0; y < C; y++)
			{
				Z<char> ItemToMatch(1000);

				if (allelements[y] == 0)
					continue;


				if (strcmp(item1, "?") == 0)
				{
					allelements[y]->GetElementName(ItemToMatch, 0);
					if (XML::TestMatch(ItemToMatch, comp, item2) == 0)
						positives[y] = 0;
				}
				else
					if (strcmp(item1, "!") == 0)
					{
						allelements[y]->GetElementFullName(ItemToMatch, 0);
						if (XML::TestMatch(ItemToMatch, comp, item2) == 0)
							positives[y] = 0;
					}
					else
						if (strncmp(item1, "~", 1) == 0)
						{
							unsigned int iC = atoi(item1.operator char*() + 1);
							if (allelements[y]->GetContentsNum() > iC)
								allelements[y]->GetContents()[iC]->GetValue(ItemToMatch);

							if (XML::TestMatch(ItemToMatch, comp, item2) == 0)
								positives[y] = 0;
						}
						else
						{
							int V = allelements[y]->FindVariable(item1);
							if (V == -1)
								strcpy(ItemToMatch, "");
							else
								allelements[y]->GetVariables()[V]->GetValue(ItemToMatch, 0);
							if (XML::TestMatch(ItemToMatch, comp, item2) == 0)
								positives[y] = 0;
						}
			}

			// Testing finished.
			if (!a1)
				break;


		}

		int N = 0;
		for (int i = 0; i < C; i++)
		{
			if (positives[i])
			{
				if (rv)
					rv[N] = allelements[i];
				N++;
			}
		}
		return N;
	}



	// Global functions
	Z<char>* XML::ReadToZ(const char* file, XMLTransform* eclass, class XMLTransformData* edata, bool IsU)
	{
		FILE* fp = 0;
		fp = fopen(file, "rb");
		if (!fp)
			return 0;

		fseek(fp, 0, SEEK_END);
		int S = ftell(fp);
		fseek(fp, 0, SEEK_SET);

		Z<char>* y = 0;
		if (eclass == 0)
		{
			y = new Z<char>(S + 32);
			fread((*y).operator char *(), 1, S, fp);
			fclose(fp);
		}
		else
		{
			Z<char> yy(S + 32);
			y = new Z<char>(S + 32);
			fread(yy.operator char *(), 1, S, fp);
			fclose(fp);

			//eclass->Prepare(edata);
			eclass->Decrypt(yy.operator char *(), S, 0, (*y).operator char *(), S, 0);
		}


		return y;
	}

	// Binary Functions

	bool XMLContent::ImportFromBinary(const BDC& b)
	{
		// Validate it
		unsigned long long bs = b.size();
		char* ptr = b.p();
		if (bs < sizeof(XMLBINARYHEADER))
			return false; // Invalid
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		if (xbh->v != 0)
			return false;
		if (xbh->t != 6) // Content
			return false;
		if (xbh->tv != 0)
			return false;
		unsigned int ContentSize = xbh->s;
		if ((ContentSize + sizeof(XMLBINARYHEADER)) != bs)
			return false;
		int RemainingSize = ContentSize;
		ptr += sizeof(XMLBINARYHEADER);


		if (RemainingSize < 4)
			return false;
		ep = *(int*)ptr;
		ptr += 4;
		RemainingSize -= 4;

		if (RemainingSize < 4)
			return false;
		BinaryMode = *(bool*)ptr;
		ptr += 4;
		RemainingSize -= 4;

		if (RemainingSize < 4)
			return false;
		int DataSize = *(int*)ptr;
		ptr += 4;
		RemainingSize -= 4;

		// The data (RemainingSize)
		if (RemainingSize < DataSize)
			return false;
		if (BinaryMode)
			SetValue(ptr, 1, DataSize);
		else
		{
			Z<char> txt(DataSize + 10);
			memcpy(txt, ptr, DataSize);
			SetValue(txt, 1);
		}
		ptr += DataSize;
		RemainingSize -= DataSize;

		return true;
	}

	BDC XMLContent::ExportToBinary()
	{
		BDC b;

		/*
				Save:
						header
						ep                                      4
						binary mode                     4
						data size                       4
						data                            xxx
		*/

		unsigned int bs = sizeof(XMLBINARYHEADER) + 4 + 4 + 4;
		unsigned int ds = 0;
		if (BinaryMode)
			ds = (unsigned int)bdc.size();
		else
		{
			if (c)
				ds = (unsigned int)strlen(c);
		}

		bs += ds;
		b.Resize(bs);
		char* ptr = b.p();

		// Header
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		xbh->v = 0;
		xbh->t = 6; // Content
		xbh->tv = 0;
		xbh->s = bs - sizeof(XMLBINARYHEADER);
		ptr += sizeof(XMLBINARYHEADER);

		// ep
		int* pep = (int*)ptr;
		*pep = ep;
		ptr += 4;

		// Binary Mode
		bool* bm = (bool*)ptr;
		*bm = BinaryMode;
		ptr += 4;

		// Data size
		int*pds = (int*)ptr;
		*pds = ds;
		ptr += 4;

		if (BinaryMode)
			memcpy(ptr, bdc.p(), ds);
		else
		{
			if (c)
				memcpy(ptr, c, ds);
		}
		ptr += ds;

		return b;
	}


	bool XMLComment::ImportFromBinary(const BDC& b)
	{
		// Validate it
		unsigned long long bs = b.size();
		char* ptr = b.p();
		if (bs < sizeof(XMLBINARYHEADER))
			return false; // Invalid
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		if (xbh->v != 0)
			return false;
		if (xbh->t != 4) // Comment
			return false;
		if (xbh->tv != 0)
			return false;
		unsigned int ContentSize = xbh->s;
		if ((ContentSize + sizeof(XMLBINARYHEADER)) != bs)
			return false;
		int RemainingSize = ContentSize;
		ptr += sizeof(XMLBINARYHEADER);

		if (RemainingSize < 4)
			return false;
		ep = *(int*)ptr;
		ptr += 4;
		RemainingSize -= 4;

		if (RemainingSize < 4)
			return false;
		int DataSize = *(int*)ptr;
		ptr += 4;
		RemainingSize -= 4;

		// The data (RemainingSize)
		if (RemainingSize < DataSize)
			return false;
		Z<char> txt(DataSize + 10);
		memcpy(txt, ptr, DataSize);
		SetComment(txt);
		ptr += DataSize;
		RemainingSize -= DataSize;

		return true;
	}


	BDC XMLComment::ExportToBinary()
	{
		BDC b;

		/*
				Save:
						header
						ep                                      4
						data size                       4
						data                            xxx
		*/

		unsigned int bs = sizeof(XMLBINARYHEADER) + 4 + 4;
		unsigned int ds = 0;
		if (c)
			ds = (unsigned int)strlen(c);

		bs += ds;
		b.Resize(bs);
		char* ptr = b.p();

		// Header
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		xbh->v = 0;
		xbh->t = 4; // Comment
		xbh->tv = 0;
		xbh->s = bs - sizeof(XMLBINARYHEADER);
		ptr += sizeof(XMLBINARYHEADER);

		// ep
		int* pep = (int*)ptr;
		*pep = ep;
		ptr += 4;

		// Data size
		int*pds = (int*)ptr;
		*pds = ds;
		ptr += 4;

		if (c)
			memcpy(ptr, c, ds);
		ptr += ds;

		return b;
	}


	bool XMLCData::ImportFromBinary(const BDC& b)
	{
		// Validate it
		unsigned long long bs = b.size();
		char* ptr = b.p();
		if (bs < sizeof(XMLBINARYHEADER))
			return false; // Invalid
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		if (xbh->v != 0)
			return false;
		if (xbh->t != 5) // CData
			return false;
		if (xbh->tv != 0)
			return false;
		unsigned int ContentSize = xbh->s;
		if ((ContentSize + sizeof(XMLBINARYHEADER)) != bs)
			return false;
		int RemainingSize = ContentSize;
		ptr += sizeof(XMLBINARYHEADER);

		if (RemainingSize < 4)
			return false;
		ep = *(int*)ptr;
		ptr += 4;
		RemainingSize -= 4;

		if (RemainingSize < 4)
			return false;
		int DataSize = *(int*)ptr;
		ptr += 4;
		RemainingSize -= 4;

		// The data (RemainingSize)
		if (RemainingSize < DataSize)
			return false;
		Z<char> txt(DataSize + 10);
		memcpy(txt, ptr, DataSize);
		SetCData(txt);
		ptr += DataSize;
		RemainingSize -= DataSize;

		return true;
	}


	BDC XMLCData::ExportToBinary()
	{
		BDC b;

		/*
				Save:
						header
						ep                                      4
						data size                       4
						data                            xxx
		*/

		unsigned int bs = sizeof(XMLBINARYHEADER) + 4 + 4;
		unsigned int ds = 0;
		if (c)
			ds = (unsigned int)strlen(c);

		bs += ds;
		b.Resize(bs);
		char* ptr = b.p();

		// Header
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		xbh->v = 0;
		xbh->t = 5; // CData
		xbh->tv = 0;
		xbh->s = bs - sizeof(XMLBINARYHEADER);
		ptr += sizeof(XMLBINARYHEADER);

		// ep
		int* pep = (int*)ptr;
		*pep = ep;
		ptr += 4;

		// Data size
		int*pds = (int*)ptr;
		*pds = ds;
		ptr += 4;

		if (c)
			memcpy(ptr, c, ds);
		ptr += ds;

		return b;
	}


	bool XMLVariable::ImportFromBinary(const BDC& b)
	{
		// Validate it
		unsigned long long bs = b.size();
		char* ptr = b.p();
		if (bs < sizeof(XMLBINARYHEADER))
			return false; // Invalid
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		if (xbh->v != 0)
			return false;
		if (xbh->t != 3) // Variable
			return false;
		if (xbh->tv != 0)
			return false;
		unsigned int ContentSize = xbh->s;
		if ((ContentSize + sizeof(XMLBINARYHEADER)) != bs)
			return false;
		int RemainingSize = ContentSize;
		ptr += sizeof(XMLBINARYHEADER);

		// The Name
		if (RemainingSize < 4)
			return false;
		int ds1 = *(int*)ptr;
		ptr += 4;
		RemainingSize -= 4;

		if (RemainingSize < ds1)
			return false;
		Z<char> tn(ds1 + 10);
		memcpy(tn.p(), ptr, ds1);
		SetName(tn, 1);
		ptr += ds1;
		RemainingSize -= ds1;

		// The Value
		if (RemainingSize < 4)
			return false;
		int ds2 = *(int*)ptr;
		ptr += 4;
		RemainingSize -= 4;

		if (RemainingSize < ds2)
			return false;
		Z<char> tv(ds2 + 10);
		memcpy(tv.p(), ptr, ds2);
		SetValue(tv, 1);
		ptr += ds2;
		RemainingSize -= ds2;

		return true;
	}


	BDC XMLVariable::ExportToBinary()
	{
		BDC b;

		/*
				Save:
						header
						ns                                      4
						n                                       xxx
						vs                                      4
						v
		*/

		unsigned int bs = sizeof(XMLBINARYHEADER) + 4 + 4;
		unsigned int ds1 = 0;
		unsigned int ds2 = 0;
		if (vn)
			ds1 = (unsigned int)strlen(vn);
		if (vv)
			ds2 = (unsigned int)strlen(vv);

		bs += ds1;
		bs += ds2;
		b.Resize(bs);
		char* ptr = b.p();

		// Header
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		xbh->v = 0;
		xbh->t = 3; // Variable
		xbh->tv = 0;
		xbh->s = bs - sizeof(XMLBINARYHEADER);
		ptr += sizeof(XMLBINARYHEADER);

		// Name
		int*pds1 = (int*)ptr;
		*pds1 = ds1;
		ptr += 4;

		if (vn)
			memcpy(ptr, vn, ds1);
		ptr += ds1;

		// Value
		int*pds2 = (int*)ptr;
		*pds2 = ds2;
		ptr += 4;

		if (vn)
			memcpy(ptr, vv, ds2);
		ptr += ds2;


		return b;
	}

	bool XMLHeader::ImportFromBinary(const BDC& b)
	{
		// Validate it
		unsigned long long bs = b.size();
		char* ptr = b.p();
		if (bs < sizeof(XMLBINARYHEADER))
			return false; // Invalid
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		if (xbh->v != 0)
			return false;
		if (xbh->t != 1) // Variable
			return false;
		if (xbh->tv != 0)
			return false;
		unsigned int ContentSize = xbh->s;
		if ((ContentSize + sizeof(XMLBINARYHEADER)) != bs)
			return false;
		int RemainingSize = ContentSize;
		ptr += sizeof(XMLBINARYHEADER);


		if (RemainingSize < 4)
			return false;
		int DataSize = *(int*)ptr;
		ptr += 4;
		RemainingSize -= 4;

		// The data (RemainingSize)
		if (RemainingSize < DataSize)
			return false;
		Z<char> txt(DataSize + 10);
		memcpy(txt, ptr, DataSize);

		Clear();

		if (hdr)
			delete[] hdr;
		hdr = 0;
		hdr = new char[DataSize + 1];
		strcpy(hdr, txt);
		RemainingSize -= DataSize;
		ptr += DataSize;

		// If there are any remaining sizes, there are comments
		for (;;)
		{
			if (RemainingSize < sizeof(XMLBINARYHEADER))
				break;
			XMLBINARYHEADER* x = (XMLBINARYHEADER*)ptr;

			unsigned int ds = x->s + sizeof(XMLBINARYHEADER);
			BDC co;
			co.Resize(ds);
			memcpy(co.p(), ptr, ds);
			XMLComment* nc = new XMLComment();
			if (nc->ImportFromBinary(co))
				AddComment(nc, -1);
			else
				delete nc;

			ptr += ds;
			RemainingSize -= ds;
		}
		return true;
	}


	BDC XMLHeader::ExportToBinary()
	{
		BDC b;

		/*
				Save:
						header
						data size                       4
						data                            xxx
						comment #0,comment #1 etc
		*/

		unsigned int bs = sizeof(XMLBINARYHEADER) + 4;
		unsigned int ds = 0;
		if (hdr)
			ds = (unsigned int)strlen(hdr);

		bs += ds;

		// All comments
		unsigned int numComments = 0;
		numComments = commentsnum;
		Z<BDC> CommentsData(commentsnum);
		for (unsigned int i = 0; i < commentsnum; i++)
		{
			CommentsData[i] = comments[i]->ExportToBinary();
			bs += (unsigned int)CommentsData[i].size();
		}



		b.Resize(bs);
		char* ptr = b.p();

		// Header
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		xbh->v = 0;
		xbh->t = 1; // Header
		xbh->tv = 0;
		xbh->s = bs - sizeof(XMLBINARYHEADER);
		ptr += sizeof(XMLBINARYHEADER);

		// Data size
		int*pds = (int*)ptr;
		*pds = ds;
		ptr += 4;

		if (hdr)
			memcpy(ptr, hdr, ds);
		ptr += ds;

		// All comments
		for (unsigned int i = 0; i < numComments; i++)
		{
			memcpy(ptr, CommentsData[i].p(), (size_t)CommentsData[i].size());
			ptr += CommentsData[i].size();
		}

		return b;
	}

	bool XMLElement::ImportFromBinary(const BDC& b)
	{
		// Validate it
		unsigned long long bs = b.size();
		char* ptr = b.p();
		if (bs < sizeof(XMLBINARYHEADER))
			return false; // Invalid
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		if (xbh->v != 0)
			return false;
		if (xbh->t != 2) // Element
			return false;
		if (xbh->tv != 0)
			return false;
		unsigned int ContentSize = xbh->s;
		if ((ContentSize + sizeof(XMLBINARYHEADER)) != bs)
			return false;
		int RemainingSize = ContentSize;
		ptr += sizeof(XMLBINARYHEADER);

		// Remove all existing
		Clear();

		if (RemainingSize < 4)
			return false;
		int NameSize = *(int*)ptr;
		ptr += 4;
		RemainingSize -= 4;

		// The name (RemainingSize)
		if (RemainingSize < NameSize)
			return false;
		Z<char> txt(NameSize + 10);
		memcpy(txt, ptr, NameSize);

		SetElementName(txt);

		RemainingSize -= NameSize;
		ptr += NameSize;



		// If there are any remaining sizes, there are items
		for (;;)
		{
			if (RemainingSize < sizeof(XMLBINARYHEADER))
				break;
			XMLBINARYHEADER* x = (XMLBINARYHEADER*)ptr;
			if (x->v != 0)
				break;

			unsigned int ds = x->s + sizeof(XMLBINARYHEADER);
			BDC co;
			co.Resize(ds);
			memcpy(co.p(), ptr, ds);

			//Children, Variables, Contents, Cdatas, Comments
			if (x->t == 2) //Element
			{
				XMLElement* h = new XMLElement();
				if (h->ImportFromBinary(co))
					AddElement(h);
				else
					delete h;
			}

			if (x->t == 3) // Variable
			{
				XMLVariable* h = new XMLVariable();
				if (h->ImportFromBinary(co))
					AddVariable(h);
				else
					delete h;
			}

			if (x->t == 4) // Comment
			{
				XMLComment* h = new XMLComment();
				if (h->ImportFromBinary(co))
					AddComment(h, -1);
				else
					delete h;
			}

			if (x->t == 5) // CData
			{
				XMLCData* h = new XMLCData();
				if (h->ImportFromBinary(co))
					AddCData(h, -1);
				else
					delete h;
			}

			if (x->t == 6) // Content
			{
				XMLContent* h = new XMLContent();
				if (h->ImportFromBinary(co))
					AddContent(h, -1);
				else
					delete h;
			}

			ptr += ds;
			RemainingSize -= ds;
		}

		return true;
	}


	BDC XMLElement::ExportToBinary()
	{
		BDC b;

		/*
				Save:
						header
						name s+d
						all variables
						all contents
						all cdatas
						all comments
						all children


		*/

		unsigned int bs = sizeof(XMLBINARYHEADER) + 4;

		// All data (V,CH,CT,CO,CD)
		int pI = 0;
		unsigned int iMoreData = commentsnum + contentsnum + variablesnum + cdatasnum + childrennum;
		if (el)
			bs += (unsigned int)strlen(el);




		Z<BDC> MoreData(iMoreData);

		// Variables
		for (unsigned int i = 0; i < variablesnum; i++)
		{
			MoreData[pI++] = variables[i]->ExportToBinary();
		}
		// Children
		for (unsigned int i = 0; i < childrennum; i++)
		{
			MoreData[pI++] = children[i]->ExportToBinary();
		}
		// Contents
		for (unsigned int i = 0; i < contentsnum; i++)
		{
			MoreData[pI++] = contents[i]->ExportToBinary();
		}
		// Comments
		for (unsigned int i = 0; i < commentsnum; i++)
		{
			MoreData[pI++] = comments[i]->ExportToBinary();
		}
		// CDATAs
		for (unsigned int i = 0; i < cdatasnum; i++)
		{
			MoreData[pI++] = cdatas[i]->ExportToBinary();
		}

		// Get the sizes
		for (unsigned int i = 0; i < iMoreData; i++)
		{
			bs += (unsigned int)MoreData[i].size();
		}


		b.Resize(bs);
		char* ptr = b.p();

		// Header
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		xbh->v = 0;
		xbh->t = 2; // Element
		xbh->tv = 0;
		xbh->s = bs - sizeof(XMLBINARYHEADER);
		ptr += sizeof(XMLBINARYHEADER);

		// Name size
		int*pns = (int*)ptr;
		if (el)
			*pns = (unsigned int)strlen(el);
		ptr += 4;

		if (el)
		{
			memcpy(ptr, el, strlen(el));
			ptr += strlen(el);
		}

		// All data
		for (unsigned int i = 0; i < iMoreData; i++)
		{
			size_t sz = (size_t)MoreData[i].size();
			memcpy(ptr, MoreData[i].p(), sz);
			ptr += sz;
		}

		return b;
	}

	bool XML::ImportFromBinary(const BDC& b)
	{
		// Validate it
		unsigned long long bs = b.size();
		char* ptr = b.p();
		if (bs < sizeof(XMLBINARYHEADER))
			return false; // Invalid
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		if (xbh->v != 0)
			return false;
		if (xbh->t != 0) // XML
			return false;
		if (xbh->tv != 0)
			return false;
		unsigned int ContentSize = xbh->s;
		if ((ContentSize + sizeof(XMLBINARYHEADER)) != bs)
			return false;
		int RemainingSize = ContentSize;
		ptr += sizeof(XMLBINARYHEADER);

		// Header, Element
		for (;;)
		{
			if (RemainingSize < sizeof(XMLBINARYHEADER))
				break;
			XMLBINARYHEADER* x = (XMLBINARYHEADER*)ptr;
			if (x->v != 0)
				break;

			unsigned int ds = x->s + sizeof(XMLBINARYHEADER);
			BDC co;
			co.Resize(ds);
			memcpy(co.p(), ptr, ds);
			ptr += ds;
			RemainingSize -= ds;

			if (x->t == 1) // header
			{
				XMLHeader* h = new XMLHeader();
				if (h->ImportFromBinary(co))
					SetHeader(h);
				else
					delete h;
			}

			if (x->t == 2) // root element
			{
				XMLElement* h = new XMLElement();
				if (h->ImportFromBinary(co))
					SetRootElement(h);
				else
					delete h;
			}
		}

		return true;
	}


	BDC XML::ExportToBinary()
	{
		BDC b;

		/*
				Save:
						header
						root element
		*/

		unsigned int bs = sizeof(XMLBINARYHEADER);

		BDC h;
		if (GetHeader())
			h = GetHeader()->ExportToBinary();

		BDC r;
		if (GetRootElement())
			r = GetRootElement()->ExportToBinary();

		bs += (unsigned int)h.size();
		bs += (unsigned int)r.size();

		b.Resize(bs);
		char* ptr = b.p();

		// Header
		XMLBINARYHEADER* xbh = (XMLBINARYHEADER*)ptr;
		xbh->v = 0;
		xbh->t = 0; // XML
		xbh->tv = 0;
		xbh->s = bs - sizeof(XMLBINARYHEADER);
		ptr += sizeof(XMLBINARYHEADER);

		memcpy(ptr, h.p(), (size_t)h.size());
		ptr += h.size();
		memcpy(ptr, r.p(), (size_t)r.size());
		ptr += r.size();

		return b;
	}


	size_t XMLGetString(const char* section, const char* Tattr, const char* defv, char*out, const size_t maxlen, const char* xml, XML* af)
	{
		size_t Z = 0;
		if (!af)
		{
			XML f(xml);
			Z = f.XMLGetValue((char*)section, (char*)Tattr, out, maxlen);
		}
		else
		{
			Z = af->XMLGetValue((char*)section, (char*)Tattr, out, maxlen);
		}

		if (Z)
			return Z;
		strcpy(out, defv);
		return strlen(defv);
	}

	int XMLSetString(const char* section, const char* Tattr, char*out, const char* xml, XML* af)
	{
		if (!af)
		{
			XML f(xml);
			f.XMLSetValue((char*)section, (char*)Tattr, out);
			f.Save();
		}
		else
		{
			af->XMLSetValue((char*)section, (char*)Tattr, out);
		}
		return 1;
	}


	int XMLRenameElement(const char* section, const char* newname, const char* xml, XML* af)
	{
		bool C = false;
		if (!af)
		{
			C = true;
			af = new XML(xml);
		}

		XMLElement* r = af->GetRootElement();
		XMLElement* e = r->GetElementInSection(section);
		if (!e)
			return 0; // no items under this one

		e->SetElementName(newname);

		if (C)
		{
			delete af;
			af = 0;
		}
		return 1;
	}


	unsigned int XMLGetUInt(const char* item, const char* attr, const unsigned int defv, const char* xml, XML* af)
	{
		Z<char> i(100);
		Z<char> id(100);
		sprintf(id, "%u", defv);
		XMLGetString(item, attr, id, i, 100, xml, af);
		unsigned int x = 0;
		sscanf(i, "%u", &x);
		return x;
	}

	int XMLGetInt(const char* item, const char* attr, const int defv, const char* xml, XML* af)
	{
		Z<char> i(100);
		Z<char> id(100);
		sprintf(id, "%i", defv);
		XMLGetString(item, attr, id, i, 100, xml, af);
		return atoi(i);
	}


	float XMLGetFloat(const char* item, const char* attr, const float defv, const char* xml, XML* af)
	{
		Z<char> a1(30);
		sprintf(a1, "%f", defv);

		Z<char> a2(30);
		XMLGetString(item, attr, a1, a2, 30, xml, af);

		return (float)atof(a2);
	}

	size_t XMLGetBinaryData(const char* item, const char* attr, const char* defv, char*out, const size_t maxlen, const char* xml, XML* af)
	{
		Z<char> bdata(maxlen * 5 + 5000);
		size_t len = XMLGetString(item, attr, defv, bdata, maxlen * 5 + 5000, xml, af);
		if (!len)
			return 0;

		for (unsigned int i = 0; i < (strlen(bdata) - 1); i++)
		{
			if (bdata[i] == '_' && bdata[i + 1] == '_')
			{
				bdata[i] = '\r';
				bdata[i + 1] = '\n';
			}
		}



		Z<char> oout(maxlen * 5 + 5000);

		char *oo;
		MimeCoder<char*, char*>* e;
		e = new Base64Decoder<char*, char*>;
		oo = e->Filter(oout, bdata.operator char*(), bdata.operator char*() + len);
		oo = e->Finish(oo);
		*oo = 0;                  // Put a zero to the end
		delete e;


		size_t S = oo - oout.operator char*();
		if (S > maxlen)
		{
			memcpy(out, oout, maxlen);
			return maxlen;
		}
		else
		{
			memcpy(out, oout, S);
			return S;
		}
	}

	int XMLSetUInt(const char* section, const char* attr, unsigned int v, const char* xml, XML* af)
	{
		char a[20] = { 0 };
		sprintf(a, "%u", v);
		return XMLSetString(section, attr, a, xml, af);
	}
	int XMLSetInt(const char* section, const char* attr, int v, const char* xml, XML* af)
	{
		char a[20] = { 0 };
		sprintf(a, "%i", v);
		return XMLSetString(section, attr, a, xml, af);
	}


	int    XMLSetFloat(const char* section, const char* attr, float v, const char* xml, XML* af)
	{
		char a[20] = { 0 };
		sprintf(a, "%f", v);
		return XMLSetString(section, attr, a, xml, af);
	}

	int    XMLSetBinaryData(const char* section, const char* attr, char* data, int len, const char* xml, XML* af)
	{
		char* a = new char[len * 5 + 1000];
		memset(a, 0, len * 5 + 1000);

		char *oo;
		MimeCoder<char*, char*>* e;
		e = new Base64Encoder<char*, char*>;
		oo = e->Filter(a, data, data + len);
		oo = e->Finish(oo);
		*oo = 0;                  // Put a zero to the end
		delete e;


		for (unsigned int i = 0; i < strlen(a) - 1; i++)
		{
			if (a[i] == '\r' && a[i + 1] == '\n')
			{
				a[i] = '_';
				a[i + 1] = '_';
			}
		}

		int I = XMLSetString(section, attr, a, xml, af);
		delete[] a;
		return I;
	}

	// vector based things
#ifndef __SYMBIAN32__


	int XMLGetAllVariables(const char* section, char** vnames, char** vvalues, const char*xml)
	{
		XML f(xml);

		XMLElement* r = f.GetRootElement();
		XMLElement* e = r->GetElementInSection(section);
		if (!e)
			return 0; // no items under this one

		int Y = e->GetVariableNum();
		for (int i = 0; i < Y; i++)
		{
			size_t yS = e->GetVariables()[i]->GetName(0);
			char* d = new char[yS + 10];
			memset(d, 0, yS + 10);
			e->GetVariables()[i]->GetName(d);
			vnames[i] = d;

			yS = e->GetVariables()[i]->GetValue(0);
			char* d2 = new char[yS + 10];
			memset(d2, 0, yS + 10);
			e->GetVariables()[i]->GetValue(d2);
			vvalues[i] = d2;
		}
		return Y;
	}

	int XMLGetAllItems(const char* section, char** vnames, const char*xml)
	{
		XML f(xml);

		XMLElement* r = f.GetRootElement();
		XMLElement* e = r->GetElementInSection(section);
		if (!e)
			return 0; // no items under this one

		int Y = e->GetChildrenNum();
		for (int i = 0; i < Y; i++)
		{
			size_t yS = e->GetChildren()[i]->GetElementName(0);
			char* d = new char[yS + 10];
			memset(d, 0, yS + 10);
			e->GetChildren()[i]->GetElementName(d);
			vnames[i] = d;
		}
		return Y;
	}


#endif



#ifdef XML_USE_NAMESPACE
};
#endif


