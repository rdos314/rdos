/****************************************************************************
 *
 *  Filename: LonPlatform.h
 *
 *  Copyright (c) Echelon Corporation 2002-2009.  All rights reserved.
 *
 *  ECHELON MAKES NO REPRESENTATION, WARRANTY, OR CONDITION OF
 *  ANY KIND, EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE OR IN
 *  ANY COMMUNICATION WITH YOU, INCLUDING, BUT NOT LIMITED TO,
 *  ANY IMPLIED WARRANTIES OF MERCHANTABILITY, SATISFACTORY
 *  QUALITY, FITNESS FOR ANY PARTICULAR PURPOSE,
 *  NONINFRINGEMENT, AND THEIR EQUIVALENTS.
 *
 *  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *  PLEASE MAKE SURE TO READ THE INFORMATION IN THIS FILE CAREFULLY, BECAUSE 
 *  IT CONTAINS IMPORTANT PORTING CONSIDERATIONS.
 *  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 *
 *  Description:  This file contains platform dependant flags
 *  and basic data types.  All data types of LonTalk Interface Developer 
 *  generated code and the Pyxos API are derived from the basic data types of 
 *  this file, unless standard C types are used.
 *
 *  (See the ShortStack, FTXL, or Pyxos API documentation for more detailed  
 *  discussion of these data types.)
 *
 *  Below this header, which contains further discussion and background
 *  information about the issues addressed by this file, there are a
 *  set of C-language 'typedef' expressions and preprocessor macro 
 *  definitions. These 'platform-preferences' are grouped together by a 
 *  preprocessor macro that indicates the compiler in use, and possibly 
 *  the target platform in use. 
 *
 *  If you are developing an FTXL Nios II application, your project should 
 *  define GCC_NIOS to select the correct definitions in this file.  Otherwise,
 *  if you are developing a ShortStack or Pyxos application, you must make sure
 *  to examine the base data types defined in this file, and modify them 
 *  as appropriate for your operating system, compiler, and CPU.
 *
 *  If this file does not include definitions that are appropriate for your 
 *  host and development environment, it is recommended that you derive your 
 *  own set of platform properties by copying the example set for the COSMIC C 
 *  Compiler (_COSMIC) and modifying them as needed. 
 *
 *  You must make sure the correct compiler identifier (such as "_COSMIC") 
 *  is defined at compile time; failure to do so will result in an error
 *  during compilation.
 *
 *  -------- Portability Enhancements -----
 *  Many portability enhancements have been made in ShortStack 2.1 and FTXL 1.0 
 *  to eliminate the need for bit fields. Now, bit fields are defined with their 
 *  enclosing bytes, and macros are provided to extract or manipulate the bit 
 *  field information. See the <LON_GET_ATTRIBUTE> and <LON_SET_ATTRIBUTE> 
 *  macros.
 *
 *  As an example, instead of
 *  typedef struct 
 *  {
 *  #ifdef BITF_BIG_ENDIAN
 *      unsigned alpha : 1;
 *      unsigned beta : 3;
 *      unsigned : 0;
 *  #else
 *      unsigned : 4;
 *      unsigned beta : 3;
 *      unsigned alpha : 1;
 *  #endif
 *      …
 *  } Example;
 *
 *  we will say
 *  #define LON_ALPHA_MASK  0x80
 *  #define LON_ALPHA_SHIFT 7
 *  #define LON_ALPHA_FIELD flags_1
 *  #define LON_BETA_MASK   0x70
 *  #define LON_BETA_SHIFT  4
 *  #define LON_BETA_FIELD  flags_1
 *  
 *  typedef struct 
 *  {
 *      unsigned char flags_1;  // contains alpha, beta 
 *      …
 *  } Example;
 *
 *  Another change is the replacement of multiple-byte values in a structure 
 *  with multi-byte scalars. This eliminates the concern of endianness among 
 *  bytes. Macros such as <LON_GET_UNSIGNED_WORD> and <LON_SET_UNSIGNED_WORD> 
 *  are provided to convert these scalars to multiple-byte values and back 
 *  again.
 *
 *  For example, instead of 
 *  typedef struct 
 *  {
 *      Word    alpha;
 *      …
 *  } Example;
 *
 *  we will say
 *  typedef struct 
 *  {
 *      LonWord alpha;
 *      …
 *  } Example;
 *
 *  where LonWord is defined as follows:
 *  typedef LON_STRUCT_BEGIN(LonWord) 
 *  {
 *      unsigned char  msb;    
 *      unsigned char  lsb;    
 *  } LON_STRUCT_END(LonWord);
 *
 ***************************************************************************/
#ifndef _LON_PLATFORM_H
#define _LON_PLATFORM_H
     
    /*
     * Compiler-dependent types for signed and unsigned 8-bit, 16-bit scalars, 
     * and 32-bit scalars. All LonTalk Interface Developer-Builder generated 
     * types use NEURON C equivalent types which are based on the following 
     * type definitions.
     *
     * To enhance portability between different platforms, no aggregate shall 
     * contain multi-byte scalars, but shall use multiple byte-sized scalars 
     * instead. We will define only the basic type unsigned char and the rest 
     * (LonWord, LonDoubleWord) derive from it.
     *
     * Note that "float" type variables are handled through a "float_type" 
     * equivalent structure. See the ShortStack or FTXL documentation 
     * for more details about Builder-generated type definitions including 
     * details about "float" type handling.  
     */

typedef int bool;

#define TRUE    1
#define FALSE   0


#endif  /* _LON_PLATFORM_H */
