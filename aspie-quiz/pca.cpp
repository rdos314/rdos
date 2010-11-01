/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2005, Leif Ekblad
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
# Principal Components Analysis or the Karhunen-Loeve expansion is a
#   classical method for dimensionality reduction or exploratory data
#   analysis.  One reference among many is: F. Murtagh and A. Heck,
#   Multivariate Data Analysis, Kluwer Academic, Dordrecht, 1987 
#   (hardbound, paperback and accompanying diskette).
#
#   This program is public-domain.  If of importance, please reference 
#   the author.  Please also send comments of any kind to the author:
#
#   F. Murtagh
#   Schlossgartenweg 1          or        35 St. Helen's Road
#   D-8045 Ismaning                       Booterstown, Co. Dublin
#   W. Germany                            Ireland
#
#   Phone:        + 49 89 32006298 (work)
#                 + 49 89 965307 (home)
#   Telex:        528 282 22 eo d
#   Fax:          + 49 89 3202362
#   Earn/Bitnet:  fionn@dgaeso51,  fim@dgaipp1s,  murtagh@stsci
#   Span:         esomc1::fionn
#   Internet:     murtagh@scivax.stsci.edu
#   
#
#   A Fortran version of this program is also available.     
#
#   F. Murtagh, Munich, 6 June 1989
#
# pca.cpp
# Principal components analysis (PCA) class
#
########################################################################*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "pca.h"
#include "quiz.h"

#define SIGN(a, b) ( (b) < 0 ? -fabs(a) : fabs(a) )

/*##########################################################################
#
#   Name       : TPca::TPca
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPca::TPca()
{
    Count = 0;
}

/*##########################################################################
#
#   Name       : TPca::~TPca
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPca::~TPca()
{
}

/*##########################################################################
#
#   Name       : TPca::tred2
#
#   Purpose....: Reduce a real, symmetric matrix to a symmetric, tridiag. matrix.
#                Householder reduction of matrix a to tridiagonal form.
#                Algorithm: Martin et al., Num. Math. 11, 181-195, 1968.
#                    Ref: Smith et al., Matrix Eigensystem Routines -- EISPACK Guide
#                        Springer-Verlag, 1976, pp. 489-494.
#                        W H Press et al., Numerical Recipes in C, Cambridge U P,
#                        1988, pp. 373-374.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPca::tred2()
{
        int l, k, j, i;
        long double scale, hh, h, g, f;

    for (i = Count; i >= 2; i--)
        {
            l = i - 1;
            h = scale = 0.0;
            if (l > 1)
                {
                for (k = 1; k <= l; k++)
                            scale += fabs(Corr[i][k]);
                if (scale == 0.0)
                        Interm[i] = Corr[i][l];
                    else
                        {
                            for (k = 1; k <= l; k++)
                            {
                                    Corr[i][k] /= scale;
                            h += Corr[i][k] * Corr[i][k];
                        }
                    f = Corr[i][l];
                    g = f>0 ? -sqrt(h) : sqrt(h);
                        Interm[i] = scale * g;
                    h -= f * g;
                        Corr[i][l] = f - g;
                        f = 0.0;
                        for (j = 1; j <= l; j++)
                        {
                                Corr[j][i] = Corr[i][j]/h;
                                    g = 0.0;
                                    for (k = 1; k <= j; k++)
                                        g += Corr[j][k] * Corr[i][k];
                                    for (k = j+1; k <= l; k++)
                                            g += Corr[k][j] * Corr[i][k];
                                    Interm[j] = g / h;
                                    f += Interm[j] * Corr[i][j];
                            }
                        hh = f / (h + h);
                        for (j = 1; j <= l; j++)
                                {
                                    f = Corr[i][j];
                                    Interm[j] = g = Interm[j] - hh * f;
                                    for (k = 1; k <= j; k++)
                                            Corr[j][k] -= (f * Interm[k] + g * Corr[i][k]);
                            }
                }
        }
            else
                    Interm[i] = Corr[i][l];
        EigenVal[i] = h;
    }
    EigenVal[1] = 0.0;
    Interm[1] = 0.0;
    for (i = 1; i <= Count; i++)
    {
        l = i - 1;
        if (EigenVal[i])
            {
                for (j = 1; j <= l; j++)
                    {
                            g = 0.0;
                            for (k = 1; k <= l; k++)
                                        g += Corr[i][k] * Corr[k][j];
                            for (k = 1; k <= l; k++)
                                        Corr[k][j] -= g * Corr[k][i];
                    }
            }
            EigenVal[i] = Corr[i][i];
            Corr[i][i] = 1.0;
            for (j = 1; j <= l; j++)
                    Corr[j][i] = Corr[i][j] = 0.0;
    }
}

/*##########################################################################
#
#   Name       : TPca::tqli
#
#   Purpose....: Tridiagonal QL algorithm -- Implicit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPca::tqli()
{
        int m, l, iter, i, k;
        long double s, r, p, g, f, dd, c, b;

    for (i = 2; i <= Count; i++)
        Interm[i-1] = Interm[i];
        Interm[Count] = 0.0;
    for (l = 1; l <= Count; l++)
    {
        iter = 0;
        do
        {
            for (m = l; m <= Count - 1; m++)
            {
                dd = fabs(EigenVal[m]) + fabs(EigenVal[m+1]);
                if (fabs(Interm[m]) + dd == dd) break;
            }
            if (m != l)
            {
                        if (iter++ == 30)
                                {
                                    printf("No convergence in TLQI.");
                                        exit(0);
                            }
                g = (EigenVal[l+1] - EigenVal[l]) / (2.0 * Interm[l]);
                        r = sqrt((g * g) + 1.0);
                g = EigenVal[m] - EigenVal[l] + Interm[l] / (g + SIGN(r, g));
                s = c = 1.0;
                                p = 0.0;
                for (i = m-1; i >= l; i--)
                {
                    f = s * Interm[i];
                    b = c * Interm[i];
                    if (fabs(f) >= fabs(g))
                    {
                        c = g / f;
                        r = sqrt((c * c) + 1.0);
                        Interm[i+1] = f * r;
                        c *= (s = 1.0/r);
                    }
                    else
                    {
                                        s = f / g;
                                        r = sqrt((s * s) + 1.0);
                                            Interm[i+1] = g * r;
                                            s *= (c = 1.0/r);
                                    }
                                        g = EigenVal[i+1] - p;
                                        r = (EigenVal[i] - g) * s + 2.0 * c * b;
                                        p = s * r;
                                        EigenVal[i+1] = g + p;
                                        g = c * r - b;
                                        for (k = 1; k <= Count; k++)
                                        {
                                        f = Corr[k][i+1];
                                            Corr[k][i+1] = s * Corr[k][i] + c * f;
                                                Corr[k][i] = c * Corr[k][i] - s * f;
                                        }
                            }
                            EigenVal[l] = EigenVal[l] - p;
                            Interm[l] = g;
                            Interm[m] = 0.0;
                    }
                }  while (m != l);
    }
}

/*##########################################################################
#
#   Name       : TPca::Calculate
#
#   Purpose....: Calculate
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPca::Calculate(long double corr[MAX_QUESTIONS][MAX_QUESTIONS], int count)
{
    int i, j;
    
    Count = count;

    for (i = 0; i < count; i++)
        for (j = 0; j < count; j++)
            Corr[i + 1][j + 1] = corr[i][j];

    tred2();
    tqli();
}
