#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>


void cdecl main()
{
	unsigned long Temp;
	char buf[513];
	int n0,n1,n2,n3;
	long Node;
	int Handle;
	int count;

	for (;;)
	{
		printf("Input host to browse> ");
		buf[0] = 0;
		scanf("%s", buf);
		printf("\r\n");
		if (strlen(buf))
		{
			if (isdigit(buf[0]))
			{
				if (sscanf(buf, "%d.%d.%d.%d", &n3, &n2, &n1, &n0) == 4)
					Node = n3 + (n2 + (n1 + n0 * 256) * 256) * 256;
				else
				{
					Node = 0;
					printf("Not a legal IP address\r\n");
				}
			}
			else
			{
				Node = RdosNameToIp(buf);
				if (Node == 0)
					printf("Cannot locate host\r\n");
			}

			if (Node)
			{
				Temp = (unsigned long)Node;
				n3 = Temp & 0xFF;
				Temp = Temp >> 8;
				n2 = Temp & 0xFF;
				Temp = Temp >> 8;
				n1 = Temp & 0xFF;
				Temp = Temp >> 8;
				n0 = Temp & 0xFF;
				printf("Browsing node %d.%d.%d.%d", n3, n2, n1, n0);

				count = RdosIpToName(Node, buf, 256);
				if (count)
				{
					buf[count] = 0;
					printf(" (%s)", buf);
				}
				printf("\r\n");

				Handle = RdosOpenTcpConnection(Node, 0, 80, 6000, 0x4000);
				if (Handle)
				{
					printf("Connected\r\n");
					while (!RdosIsTcpConnectionClosed(Handle))
					{
						printf("enter command> ");
						scanf("%s", buf);
						if (strlen(buf) == 0)
							RdosCloseTcpConnection(Handle);
						else
						{
							strcat(buf, "\r\n\r\n");
							RdosWriteTcpConnection(Handle, buf, strlen(buf));
							RdosPushTcpConnection(Handle);
							do
							{
								count = RdosReadTcpConnection(Handle, buf, 512);
								buf[count] = 0;
								printf(buf);
							}
							while (count);
							printf("\r\n");
							RdosCloseTcpConnection(Handle);
						}
					}
					RdosDeleteTcpConnection(Handle);
				}
				else
					printf("No connection\r\n");
			}
		}
	}
}

