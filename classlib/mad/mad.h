/*
 * libmad - MPEG audio decoder library
 * Copyright (C) 2000-2004 Underbit Technologies, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * If you would like to negotiate alternate licensing terms, you may do
 * so by contacting: Underbit Technologies, Inc. <info@underbit.com>
 */

# ifdef __cplusplus
extern "C" {
# endif

# define FPM_INTEL



# define SIZEOF_INT 4
# define SIZEOF_LONG 4
# define SIZEOF_LONG_LONG 8


/* Id: version.h,v 1.24 2003/05/27 22:40:37 rob Exp */

# ifndef LIBMAD_VERSION_H
# define LIBMAD_VERSION_H

# define MAD_VERSION_MAJOR	0
# define MAD_VERSION_MINOR	15
# define MAD_VERSION_PATCH	1
# define MAD_VERSION_EXTRA	" (beta)"

# define MAD_VERSION_STRINGIZE(str)	#str
# define MAD_VERSION_STRING(num)	MAD_VERSION_STRINGIZE(num)

# define MAD_VERSION		MAD_VERSION_STRING(MAD_VERSION_MAJOR) "."  \
				MAD_VERSION_STRING(MAD_VERSION_MINOR) "."  \
				MAD_VERSION_STRING(MAD_VERSION_PATCH)  \
				MAD_VERSION_EXTRA

# define MAD_PUBLISHYEAR	"2000-2003"
# define MAD_AUTHOR		"Underbit Technologies, Inc."
# define MAD_EMAIL		"info@underbit.com"

extern char const mad_version[];
extern char const mad_copyright[];
extern char const mad_author[];
extern char const mad_build[];

# endif

/* Id: fixed.h,v 1.36 2003/05/28 04:36:00 rob Exp */

# ifndef LIBMAD_FIXED_H
# define LIBMAD_FIXED_H

# if SIZEOF_INT >= 4
typedef   signed int mad_fixed_t;

typedef   signed int mad_fixed64hi_t;
typedef unsigned int mad_fixed64lo_t;
# else
typedef   signed long mad_fixed_t;

typedef   signed long mad_fixed64hi_t;
typedef unsigned long mad_fixed64lo_t;
# endif

# if defined(FPM_FLOAT)
typedef double mad_sample_t;
# else
typedef mad_fixed_t mad_sample_t;
# endif

/*
 * Fixed-point format: 0xABBBBBBB
 * A == whole part      (sign + 3 bits)
 * B == fractional part (28 bits)
 *
 * Values are signed two's complement, so the effective range is:
 * 0x80000000 to 0x7fffffff
 *       -8.0 to +7.9999999962747097015380859375
 *
 * The smallest representable value is:
 * 0x00000001 == 0.0000000037252902984619140625 (i.e. about 3.725e-9)
 *
 * 28 bits of fractional accuracy represent about
 * 8.6 digits of decimal accuracy.
 *
 * Fixed-point numbers can be added or subtracted as normal
 * integers, but multiplication requires shifting the 64-bit result
 * from 56 fractional bits back to 28 (and rounding.)
 *
 * Changing the definition of MAD_F_FRACBITS is only partially
 * supported, and must be done with care.
 */

# define MAD_F_FRACBITS		28

# if MAD_F_FRACBITS == 28
#  define MAD_F(x)		((mad_fixed_t) (x##L))
# else
#  if MAD_F_FRACBITS < 28
#   warning "MAD_F_FRACBITS < 28"
#   define MAD_F(x)		((mad_fixed_t)  \
				 (((x##L) +  \
				   (1L << (28 - MAD_F_FRACBITS - 1))) >>  \
				  (28 - MAD_F_FRACBITS)))
#  elif MAD_F_FRACBITS > 28
#   error "MAD_F_FRACBITS > 28 not currently supported"
#   define MAD_F(x)		((mad_fixed_t)  \
				 ((x##L) << (MAD_F_FRACBITS - 28)))
#  endif
# endif

# define MAD_F_MIN		((mad_fixed_t) -0x80000000L)
# define MAD_F_MAX		((mad_fixed_t) +0x7fffffffL)

# define MAD_F_ONE		MAD_F(0x10000000)

# define mad_f_tofixed(x)	((mad_fixed_t)  \
				 ((x) * (double) (1L << MAD_F_FRACBITS) + 0.5))
# define mad_f_todouble(x)	((double)  \
				 ((x) / (double) (1L << MAD_F_FRACBITS)))

# define mad_f_intpart(x)	((x) >> MAD_F_FRACBITS)
# define mad_f_fracpart(x)	((x) & ((1L << MAD_F_FRACBITS) - 1))
				/* (x should be positive) */

# define mad_f_fromint(x)	((x) << MAD_F_FRACBITS)

# define mad_f_add(x, y)	((x) + (y))
# define mad_f_sub(x, y)	((x) - (y))


mad_fixed_t __stdcall MadMul32(mad_fixed_t x, mad_fixed_t y);

#   define mad_f_mul		MadMul32
#   define mad_f_scale64


/* ------------------------------------------------------------------------- */

/* default implementations */


# if !defined(MAD_F_MLA)
#  define MAD_F_ML0(hi, lo, x, y)	((lo)  = mad_f_mul((x), (y)))
#  define MAD_F_MLA(hi, lo, x, y)	((lo) += mad_f_mul((x), (y)))
#  define MAD_F_MLN(hi, lo)		((lo)  = -(lo))
#  define MAD_F_MLZ(hi, lo)		((void) (hi), (mad_fixed_t) (lo))
# endif

# if !defined(MAD_F_ML0)
#  define MAD_F_ML0(hi, lo, x, y)	MAD_F_MLX((hi), (lo), (x), (y))
# endif

# if !defined(MAD_F_MLN)
#  define MAD_F_MLN(hi, lo)		((hi) = ((lo) = -(lo)) ? ~(hi) : -(hi))
# endif

# if !defined(MAD_F_MLZ)
#  define MAD_F_MLZ(hi, lo)		mad_f_scale64((hi), (lo))
# endif

# if !defined(mad_f_scale64)
#  if defined(OPT_ACCURACY)
#   define mad_f_scale64(hi, lo)  \
    ((((mad_fixed_t)  \
       (((hi) << (32 - (MAD_F_SCALEBITS - 1))) |  \
	((lo) >> (MAD_F_SCALEBITS - 1)))) + 1) >> 1)
#  else
#   define mad_f_scale64(hi, lo)  \
    ((mad_fixed_t)  \
     (((hi) << (32 - MAD_F_SCALEBITS)) |  \
      ((lo) >> MAD_F_SCALEBITS)))
#  endif
#  define MAD_F_SCALEBITS  MAD_F_FRACBITS
# endif

/* C routines */

mad_fixed_t mad_f_abs(mad_fixed_t);
mad_fixed_t mad_f_div(mad_fixed_t, mad_fixed_t);

# endif


/* Id: timer.h,v 1.15 2003/05/27 22:40:37 rob Exp */

# ifndef LIBMAD_TIMER_H
# define LIBMAD_TIMER_H

typedef struct {
  signed long seconds;		/* whole seconds */
  unsigned long fraction;	/* 1/MAD_TIMER_RESOLUTION seconds */
} mad_timer_t;

extern mad_timer_t const mad_timer_zero;

# define MAD_TIMER_RESOLUTION	352800000UL

enum mad_units {
  MAD_UNITS_HOURS	 =    -2,
  MAD_UNITS_MINUTES	 =    -1,
  MAD_UNITS_SECONDS	 =     0,

  /* metric units */

  MAD_UNITS_DECISECONDS	 =    10,
  MAD_UNITS_CENTISECONDS =   100,
  MAD_UNITS_MILLISECONDS =  1000,

  /* audio sample units */

  MAD_UNITS_8000_HZ	 =  8000,
  MAD_UNITS_11025_HZ	 = 11025,
  MAD_UNITS_12000_HZ	 = 12000,

  MAD_UNITS_16000_HZ	 = 16000,
  MAD_UNITS_22050_HZ	 = 22050,
  MAD_UNITS_24000_HZ	 = 24000,

  MAD_UNITS_32000_HZ	 = 32000,
  MAD_UNITS_44100_HZ	 = 44100,
  MAD_UNITS_48000_HZ	 = 48000,

  /* video frame/field units */

  MAD_UNITS_24_FPS	 =    24,
  MAD_UNITS_25_FPS	 =    25,
  MAD_UNITS_30_FPS	 =    30,
  MAD_UNITS_48_FPS	 =    48,
  MAD_UNITS_50_FPS	 =    50,
  MAD_UNITS_60_FPS	 =    60,

  /* CD audio frames */

  MAD_UNITS_75_FPS	 =    75,

  /* video drop-frame units */

  MAD_UNITS_23_976_FPS	 =   -24,
  MAD_UNITS_24_975_FPS	 =   -25,
  MAD_UNITS_29_97_FPS	 =   -30,
  MAD_UNITS_47_952_FPS	 =   -48,
  MAD_UNITS_49_95_FPS	 =   -50,
  MAD_UNITS_59_94_FPS	 =   -60
};

# define mad_timer_reset(timer)	((void) (*(timer) = mad_timer_zero))

int mad_timer_compare(mad_timer_t, mad_timer_t);

# define mad_timer_sign(timer)	mad_timer_compare((timer), mad_timer_zero)

void mad_timer_negate(mad_timer_t *);
mad_timer_t mad_timer_abs(mad_timer_t);

void mad_timer_set(mad_timer_t *, unsigned long, unsigned long, unsigned long);
void mad_timer_add(mad_timer_t *, mad_timer_t);
void mad_timer_multiply(mad_timer_t *, signed long);

signed long mad_timer_count(mad_timer_t, enum mad_units);
unsigned long mad_timer_fraction(mad_timer_t, unsigned long);
void mad_timer_string(mad_timer_t, char *, char const *,
		      enum mad_units, enum mad_units, unsigned long);

# endif

# ifdef __cplusplus
}
# endif
