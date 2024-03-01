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
# q8.cpp
# Analyze Q8
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#include "file.h"
#include "quizq8.h"

/*##################  main ##########################
*   Purpose....: Program entry-point                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
    TQuizQ8 Quiz;

    printf("analyse\r\n");
    Quiz.Analyse();

    printf("write no answer\r\n");
    Quiz.WriteNoAnswerStats("res\\noans.txt");

    printf("details\r\n");
    Quiz.WriteSumaryTable("res\\quizq8.htm");

    printf("rel\r\n");
    Quiz.WriteIntercorr("res\\relq8.htm");

    printf("groupcorr\r\n");
    Quiz.WriteGroupCorrTable("res\\groupq8.htm");

    printf("export\r\n");
    Quiz.ExportToPhp("res\\q8.php");
}
