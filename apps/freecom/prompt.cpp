/*#######################################################################
# FreeCom for RDOS.
#
# This code builds on Steffen Kaiser (ska) FreeCom project
# The maintainer(s) of FreeCOM can be reached at freecom@freedos.org
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version
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
# The maintainer of this port can be contacted at leif@rdos.net
#
# Parses a string as PROMPT string and display the result onto the screen
#
########################################################################*/


#include <rdos.h>

/*################## WriteChar ##########################
*   Purpose....: Write a single char	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void WriteChar(char ch)
{
    RdosWriteChar(ch);
}

/*################## WriteString ##########################
*   Purpose....: Write a string	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void WriteString(const char *str)
{
    RdosWriteString(ch);
}

/*################## DisplayPrompt ##########################
*   Purpose....: Display prompt for user	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void DisplayPrompt(const char *pr)
{
    char *p;
    
    while (*pr)
    {
        if (*pr != '$')
            WriteChar(*pr);
        else
        {
            switch (toupper(*++pr))
            {
                case 'Q':
                    WriteChar('=');
                    break;
            
                case '$':
                    WriteChar('$');
                    break;

                case 'T':
                    p = FormatTime();            
                    if (p)
                        WriteString(p);
                    break;

                case 'D':
                    p = FormatDateLong();
                    if (p)
                        WriteString(p);
                    break;
                    
                case 'P':
		        	p = cwd(0);
                    if (p)
                        WriteString(p);
                    break;
                    
                case 'V':
                    WriteString(ShellName);
                    break;
                    
                case 'N':
                    WriteChar(GetDisk() + 'A');
                    break;
                    
                case 'G':
                    WriteChar('>');
                    break;

                case 'L':
                    WriteChar('<');
                    break;

                case 'B':
                    WriteChar('|');
                    break;
                    
                case '_':
                    WriteChar('\n');
                    break;
                    
                case 'E':
                    WriteChar(27);
                    break;
                    
                case 'H':
                    WriteChar(8);
                    break;
                    
            }
        }
        pr++;
    }
}
