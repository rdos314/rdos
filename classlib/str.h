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
# string.h
# String class
#
########################################################################*/

#ifndef _TSTRING_H
#define _TSTRING_H

#include <stdarg.h>
#include "shareobj.h"

class TString : public TShareObject
{
friend class TStringListNode;
public:
    TString();
    TString(const TString &source);
    TString(const char *str);
    TString(const char *str, int size);
    virtual ~TString();

    const TString &operator=(const TString &src);
    const TString &operator=(const char *str);
    const TString &operator+=(const char *str);
    const TString &operator+=(char ch);
    const TString &operator+=(const TString& str);
    bool operator==(const TString &dest) const;
    bool operator!=(const TString &dest) const;
    bool operator>(const TString &dest) const;
    bool operator>=(const TString &dest) const;
    bool operator<(const TString &dest) const;
    bool operator<=(const TString &dest) const;
    char operator[](int n) const;

    int printf(const char *fmt, ...);
    int prtf(const char *frm, va_list args);

    void Reset();
    const char *GetData() const;
    int GetSize() const;

    const char *Find(char ch) const;
    const char *Find(const char *str) const;
    void Upper();
    void Lower();
    void RemoveCrLf();
    void Append(char ch);
    void Append(const char *str);
    void Append(const char *str, int size);
    void Replace(const char *src, const char *dest);

    void ConcatCopy(const char *str1, int len1, const char *str2, int len2);

    virtual int Compare(const TShareObject &str) const;

protected:

/**
 * Converts the given character to its uppercase equivalent using the
 * `toupper` function from the C standard library.
 *
 * @param ch The character to be converted to uppercase.
 * @return The uppercase equivalent of the input character, or the original
 *         character if it has no uppercase equivalent.
 */
    virtual char Upper(char ch);

/**
 * Converts a given character to its lowercase equivalent.
 *
 * This method takes a single character as input and returns its
 * lowercase equivalent using the standard library function `tolower`.
 * The function assumes the input character is in a valid range
 * for conversion to lowercase.
 *
 * @param ch The character to be converted to lowercase.
 * @return The lowercase equivalent of the input character.
 */
virtual char Lower(char ch);

/**
 * Pads the string with the specified character to the desired length.
 *
 * This function modifies the string by appending the specified number of
 * characters (`count`) from the given string (`str`) to the end of the current
 * string. It is useful for ensuring that a string reaches a desired width
 * by adding padding characters.
 *
 * @param count The number of characters to pad the string with.
 * @param str The string containing the characters to use for padding.
 *            Only the first character of this string is used for padding.
 */
void Pad(int count, const char *str);

#ifndef __RDOS__
/**
 * Converts a long integer into a string representation in a specified base,
 * with additional formatting options.
 *
 * @param num The number to be converted.
 * @param base The numerical base for conversion (e.g., 2 for binary, 10 for decimal, 16 for hexadecimal).
 *             Valid range is 2 to 36.
 * @param size The minimum field width of the resulting string. If the resulting string is shorter than this size,
 *             it is padded with spaces or zeros based on formatting flags.
 * @param precision The minimum number of digits to represent the number. If the number has fewer digits,
 *                  it is padded with zeros.
 * @param type Flags that control formatting. Possible flags include:
 *             - `ZEROPAD` for padding field-width with zeros instead of spaces.
 *             - `SIGN` to indicate signed representation and prepend '-' for negative numbers.
 *             - `PLUS` to prepend a '+' for positive numbers.
 *             - `SPACE` to prepend a space for positive numbers if `PLUS` is not set.
 *             - `LEFT` for left-justified padding.
 *             - `SPECIAL` to include a prefix for octal ('0') or hexadecimal ('0x' or '0X') bases.
 *             - `LARGE` to use uppercase letters for hexadecimal output.
 *
 * @return The number of characters appended to the string, including added padding and formatting.
 *
 * This function appends the formatted string representation of the number to the current string.
 * It supports both signed and unsigned integer formatting, as well as various alignment and padding options.
 * The function validates the base and ensures that only bases between 2 and 36 are processed.
 * Overflow of the size or precision parameters is not explicitly handled.
 */
int Number(long num, int base, int size, int precision, int type);
#endif

/**
 * Replaces the first occurrence of a substring starting at a given pointer
 * with another substring, while managing the buffer and data size.
 *
 * @param ptr Pointer to the location in the string where the replacement starts.
 * @param src The substring to be replaced.
 * @param dest The substring to replace with.
 *
 * This method handles cases where the length of the replacement string (`dest`) differs
 * from the length of the original substring (`src`). It adjusts the internal buffer
 * of the string if necessary to accommodate the new content. If the replacement string
 * is shorter, the remaining content is shifted accordingly. If the replacement string
 * is longer and exceeds the allocated buffer size, a new buffer is allocated, and
 * the content is copied and adjusted into the resized buffer.
 *
 * Note that this method modifies the internal state of the `TString` object, as it
 * updates both the buffer and the data size.
 */
void ReplaceOne(char *ptr, const char *src, const char *dest);

/**
 * Allocates memory for a substring of the current TString object and copies it to a destination TString object.
 *
 * This function copies a specified portion of the source TString object, starting at a particular index
 * and with a provided length, into the destination TString object. Additional space beyond the copied length
 * can be allocated as specified by the `ExtraLen` parameter.
 *
 * The function ensures thread safety by entering a critical section of the destination TString object during
 * memory allocation and manipulation.
 *
 * @param dest      Reference to the destination TString object where the substring will be copied.
 * @param CopyLen   The length of the substring to copy from the source TString object.
 * @param CopyIndex The starting index in the source TString object from where the copy should begin.
 * @param ExtraLen  The additional memory length to allocate beyond the size of the copied substring.
 */
void AllocCopy(TString& dest, int CopyLen, int CopyIndex, int ExtraLen) const;

/**
 * Concatenates a string in place to the current TString instance.
 *
 * This method appends the given string `str` of length `size` to the internal buffer of the TString
 * instance. It ensures thread-safety by utilizing the `FSection` object and handles memory
 * reallocation internally when necessary.
 *
 * Behavior:
 * - If `FData` is null, initializes the TString with the provided string.
 * - If the buffer already contains data, appends the provided string:
 *   - If the current TString instance is shared (reference count > 1) or insufficient memory
 *     is available in the existing buffer, performs a copy with additional allocated memory.
 *   - Otherwise, directly appends the new string to the existing buffer and updates its size.
 * - Always keeps the internal buffer null-terminated.
 *
 * Thread-safety: Ensured by entering and leaving the `FSection` critical section.
 *
 * @param str  A pointer to the character string to be concatenated.
 * @param size The length of the string to append.
 */
void ConcatInPlace(const char *str, int size);
};

TString operator+(const TString& str1, const TString& str2);
TString operator+(const TString& str, const char *cstr);
TString operator+(const char *cstr, const TString& str);

#endif
