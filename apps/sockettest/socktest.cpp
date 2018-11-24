/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# socktest.cpp
# Socket test
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <sys/time.h>
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  main ##########################
*   Purpose....: Program entry-point                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
    int s;
    int ret;
    struct sockaddr_in server; /* server address                      */
    char *buf;
    char *ptr;
    char *tempptr;
    int size;
    long ip;
    int i;
    struct hostent *host;
    fd_set in_set;
    fd_set out_set;
    fd_set exc_set;
    struct timeval tv;
    char HostStr[] = "api.openweathermap.org";

    host = gethostbyname(HostStr);
    if (host)
        ip = *(long *)host->h_addr_list[0];
    else
        ip = 0;

    s = socket(AF_INET, SOCK_STREAM, 0);

    tv.tv_sec = 5;
    tv.tv_usec = 500000;

    FD_ZERO(&in_set);
    FD_ZERO(&out_set);
    FD_ZERO(&exc_set);

    server.sin_family      = AF_INET;
    server.sin_port        = htons(80);
    server.sin_addr.s_addr = ip;
    
    ret = connect(s, (struct sockaddr *)&server, sizeof(server));

    if (ret == 0 && ip)
    {
        buf = new char[1024];

        strcpy(buf, "GET /data/2.5/weather?id=2715946&appid=c88ba239c78cdbea4c1fe561ad4f7b3d HTTP/1.1\r\n");
        strcat(buf, "Host: ");
        strcat(buf, HostStr);
        strcat(buf, "\r\n");
        strcat(buf, "Connection: keep-alive\r\n");
        strcat(buf, "Accept: application/json, */*;q=0.01\r\n");
        strcat(buf, "User-Agent: RDOS\r\n");
        strcat(buf, "Accept-Encoding: gzip\r\n");
        strcat(buf, "Accept-Language: en-US,en;q=0.6\r\n");
        strcat(buf, "Cookie: lang=en\r\n");
        strcat(buf, "\r\n");

        FD_SET(s, &out_set);
        FD_SET(s, &exc_set);

        ret = select(s+1, 0, &out_set, &exc_set, &tv);
        size = send(s, buf, strlen(buf), 0);
        printf("sent: %d\r\n", size);

        FD_SET(s, &in_set);
        FD_SET(s, &exc_set);

        size = 0;
        ret = select(s+1, &in_set, 0, 0, &tv);
        size = recv(s, buf, 1000, 0);

        buf[size] = 0;

        ptr = buf;
        while (ptr[1] != 0xd)
        {
            tempptr = strchr(ptr + 1, 0xd);
            if (tempptr)
                ptr = tempptr + 1;
            else
                break;
        }

        while (*ptr == 0xa || *ptr == 0xd)
            ptr++;

        printf(ptr);

        delete buf;

    }

    close(s);

    return 0;
}
