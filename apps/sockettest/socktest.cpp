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
#include "json.h"
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
    TString str;
    struct hostent *host;
    fd_set in_set;
    fd_set out_set;
    fd_set exc_set;
    struct timeval tv;
    TJsonDocument *json;
    TJsonObject *obj;
    TJsonCollection *col;
    TJsonCollection *root;
    double dval;
    long long val;
    TFile *file;
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

        FD_SET(STDIN_FILENO, &in_set);
        FD_SET(s, &in_set);
        ret = select(s+1, &in_set, 0, 0, 0);

        FD_SET(s, &out_set);
        FD_SET(s, &exc_set);

        ret = select(s+1, 0, &out_set, &exc_set, &tv);
        size = send(s, buf, strlen(buf), 0);
        printf("sent: %d\r\n", size);

        FD_ZERO(&in_set);
        FD_SET(s, &in_set);
        FD_SET(s, &exc_set);

        size = 0;
        ret = select(s+1, &in_set, 0, 0, &tv);
        size = recv(s, buf, 100, MSG_PEEK);

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

        ptr += 5;

        json = new TJsonDocument(ptr);
        json->Write(str);

        file = new TFile("inv.json", 0);
        file->Write(str.GetData(), str.GetSize());

        root = json->GetRoot();
        col = root->GetCollection("main");
        if (col)
        {
            dval = col->GetDouble("temp", 0.0) - 273.15;
            printf("Temp %3.1Lf (", dval);

            dval = col->GetDouble("temp_min", 0.0)  - 273.15;
            printf("%3.1Lf to ", dval);

            dval = col->GetDouble("temp_max", 0.0)  - 273.15;
            printf("%3.1Lf) C\r\n", dval);
            
            val = col->GetInt("pressure", 0);
            printf("Pressure %lld hPa\r\n", val);
        }

        col = root->GetCollection("wind");
        if (col)
        {
            dval = col->GetDouble("speed", 0.0);
            printf("Wind %3.1Lf m/s, ", dval);

            val = col->GetInt("deg", 0);
            printf("%lld deg\r\n", val);
        }

        col = root->GetCollection("clouds");
        if (col)
        {
            val = col->GetInt("all", 0);
            printf("Clouds %lld%%\r\n", val);
        }

        delete file;
        delete json;

        delete buf;

    }

    close(s);

    return 0;
}
