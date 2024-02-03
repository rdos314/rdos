#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "httpsfact.h"
#include "ocpps.h"
#include "keyboard.h"

static void NotifyState(TOcppSslSocketServerFactory *Server, const char *state)
{
    printf("State: %s\r\n", state);
}

static void NotifyStart(TOcppSslSocketServerFactory *Server, int val)
{
    Server->LimitCurrent(1, 5.0);
    printf("Start: %d.%03d\r\n", val / 1000, val % 1000);
}

static void NotifyStop(TOcppSslSocketServerFactory *Server, int val)
{
    printf("Stop: %d.%03d\r\n", val / 1000, val % 1000);
}

static void NotifyVoltage(TOcppSslSocketServerFactory *Server, int phase, double val)
{
    printf("Voltage: L%d %2.1Lf\r\n", phase, val);
}

static void NotifyCurrent(TOcppSslSocketServerFactory *Server, int phase, double val)
{
    printf("Current: L%d %2.1Lf\r\n", phase, val);
}

static void NotifyEnergy(TOcppSslSocketServerFactory *Server, int val)
{
    printf("Energy: %d.%03d\r\n", val / 1000, val % 1000);
}

static void NotifyKey(TOcppSslSocketServerFactory *Server, const char *key, bool rdonly, const char *value)
{
    if (rdonly)
        printf(" Key: %s=%s\r\n", key, value);
    else
        printf("*Key: %s=%s\r\n", key, value);
}

void main()
{
    int port;
    int ip;
    int n0,n1,n2,n3;
    char host[80];
    int count;
    char *rbuf = new char[1025];
    char buf[80];
    TWait wait;
    TTcpSocket *sock;
    TKeyboardDevice keyboard;

    TOcppSslSocketServerFactory fact(443, 100, 0x1000);

//    THttpsSocketServerFactory fact(443, 100, 0x1000);
//    fact.RootDir = "d:/www";

    fact.SetCertificate("d:/ssl/cert.pem", "d:/ssl/privkey.pem", "d:/ssl/chain.pem");

    fact.OnState = NotifyState;
    fact.OnStart = NotifyStart;
    fact.OnStop = NotifyStop;
    fact.OnVoltage = NotifyVoltage;
    fact.OnCurrent = NotifyCurrent;
    fact.OnEnergy = NotifyEnergy;
    fact.OnKey = NotifyKey;

    for (;;)
        fact.WaitForever();


    const char *OcppName = "resi-prod-ocpp-server.azurewebsites.net";


    strcpy(host, "185.20.15.60");
//    strcpy(host, "10.8.8.240");

    if (sscanf(host, "%d.%d.%d.%d", &n3, &n2, &n1, &n0) == 4)
        ip = n3 + (n2 + (n1 + n0 * 256) * 256) * 256;
    else
        ip = 0;

    port = 443;
//    port = 6666;

    sock = new TSslSocket(ip, port, 5000, 0x1000);
    sock->WaitForConnection(7000);

    wait.Add(sock);
    wait.Add(&keyboard);

    if (sock->IsOpen())
    {
        printf("connected\r\n");
        ip = sock->GetRemoteIP();
        IpToString(buf, ip);
        printf("IP: %s\r\n", buf);
        port = sock->GetRemotePort();
        printf("Remote port: %d\r\n", port);
        port = sock->GetLocalPort();
        printf("Local port: %d\r\n", port);
    }

    while (sock->IsOpen())
    {
        wait.WaitForever();

        if (keyboard.Poll())
        {
            printf(" cmd> ");
            gets(buf);
            strcat(buf, "\r\n");
            sock->Write(buf);
            sock->Push();
        }

        count = sock->GetSize();
        if (count)
        {
            count = sock->Read(rbuf, count);
            rbuf[count] = 0;
            printf(rbuf);
        }
    }

    printf("closed\r\n");

    delete sock;


//    RdosTestGate("");
}



