/*  calchlp.c                                         24.08.90
**
**  helper module   
**    for calculator
**  
*/

#include "config.h"
#include "standard.h"
#include "microsft.h"
#include "mb_ctype.h"

#include "calc.h"
#include "calchlp.h"
#include "ansi_out.h"


/**************************************************************
*                                                             *
*                  I/O SUBROUTINES                            *
*                                                             *
**************************************************************/

/*
**  print string w/o newline
*/
void prints(char * s)
{
  while(*s)
    putchar(*s++);
}

/*
**  print long decimal 
*/
void printld(long val)
{
  int digit;

  if(val < 0)
    putchar('-'), val = -val;
  
  digit = (int)(val % 10);

  if (val /= 10)
    printld(val);

  putchar(digit+'0');
}

/*
**  print long hex 
*/
void printlx(unsigned long val)
{
  int digit = (int)val & 0xF;

  if (val >>= 4)
    printlx(val);

  putchar(digit+((digit >9)? 'A'-10 : '0'));
}


/**************************************************************
*                                                             *
*                  STRINGS & CONVERSION                       *
*                                                             *
**************************************************************/

/*
**  kill trailing white spaces
*/
char * rtrim(char * s)
{
  int ll=0;

  while (*s++) ll++;
  --s;
  while (ll--)
  {
    --s;
    if (iswhite(*s))
      *s = '\0';
    else
      break;
  }
  return (s);
}

/*
**  skip leading white spaces
*/
char * skipwhites(char * s)
{
  while (iswhite(*s)) s++;
  return (s);
}

/*
**  report distance to delimiter
*/
int wordlen(char * s, char * delimiter)
{
  int ii = 0;
  if (*s == '\'') /* --  special case: '<char>' */
    if ((strchr(s+1,*s)-s) == 2)
      return (3);
  if (*s == '\"') /* --  special case: "<string>" */
    return (strchr(s+1,*s)-s+1);
  while (*s)
    if (strchr(delimiter, *s++))
      break;
    else
      ++ii;
  return (ii);
}

/*
**  compare strings
**
**    returns:
**      matching length
*/
int strlcmp(char * s, char * op)
{
  int ll = 0;
  while(*op)
    if(*(op++) == *(s++)) ++ll;
    else
      return(0);
  return (ll);
}

/*
**  convert decimal ascii to binary
*/
int digit(int d)
{
  if (isdigit(d))
    return (d-'0');
  else
    return (-1);
}

/*
**  convert hex ascii to binary
*/
int xdigit(int x)
{
  if (isdigit(x))
    return (x-'0');
  if (isxdigit(x))
    return (tolower(x)-'a'+10);
  else
    return (-1);
}
