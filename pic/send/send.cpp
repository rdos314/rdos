/* PROGRAM SEND.CPP by Derren Crome */
/*program to transfer object code data to pic16C84 via*/
/*printer port*/

#include <stdio.h>
#include <conio.h>
#include <iostream.h>
#include <dos.h>
#include <iomanip.h>
#include <fstream.h>
#include <ctype.h>
#include <string.h>
#include <math.h>

#include "rdos.h"

void outport(int port, char val)
{
	_asm
	{
		mov edx,port
		mov al,val
		out dx,al
	}
}

void delay(int delay)
{
	RdosWaitMilli(delay);
}

/*function to make sure extension is .obj*/
void testname(char filename[])
{
	int l=0;
	char append[]=".obj";
	do
	{
		l++;
	} while(filename[l]!='\0' && filename[l]!='.');

	filename[l]='\0';
	filename=strcat(filename,append);
}

void sendbyte(unsigned char nuofbits, unsigned char byteval)
{
	unsigned char byte, clocklow, clockhigh, loop;

	for (loop=1; loop<=nuofbits; loop++)
	{
		byte=byteval;
		clocklow=byte & 0x1;
		clockhigh=clocklow | 0x2;
		outport(0x378,clockhigh);
		delay(1);
		outport(0x378,clocklow);
		delay(1);
		byteval=byteval>>1;
	}
}

char userresponse()
{
	char respond;
	do
	{
		respond=getch();
	} while(respond !='N' && respond !='n'
		&& respond !='Y' && respond !='y');

	respond=tolower(respond);
	return respond;
}

int getresponse(int start, int end)
{
	int c;

	c=getch();

	while(c<start || c>end)
	{
		c=getch();
	}
	return c;
}

void linespace(unsigned int l)
{
	unsigned int temp;

	for(temp=1; temp<=l; temp++)
	{
		cout<<'\n';
	}
}

void send()
{
	char filename[80];
	char response;
	int count=0, l;
	unsigned char data[2100];

	outport(0x378,0);
	linespace(3);
	cout<<"Program to load and transfer object code to the PIC16C84";
	linespace(2);
	cout<<'\n'<<"Enter name of object file: ";
	cin>>filename;
	testname(filename);
	cout<<'\n'<<"Loading file:"<<filename<<'\n';
	ifstream ifile;
	ifile>>resetiosflags( ios::skipws );
	ifile.open(filename,ios::binary);

	if(ifile)
	{
		cout<<"Hex value of bytes loaded are:"<<'\n';
		ifile>>data[0];
		printf("%x ",data[0]);
		while(!ifile.eof() && count < 2100)
		{
			count++;
			ifile>>data[count];
			printf("%x ",data[count]);
		}
		ifile.close();
		if(count/2 >1020)
		{
			cout<<'\n'<<'\n'<<"WARNING: Program is larger that PIC16C84 program memory space";
			cout<<'\n'<<"Press a key..";
			getch();
		}
		else
		{
			cout<<'\n'<<"Object code loaded"<<'\n'<<'\n';
			cout<<'\n'<<"Total number of bytes received= "<<count;
			cout<<'\n'<<"Will occupy "<<count/2<<" words of PIC memory ("<<ceil((float)count/2/1020*100)<<"%)";
			cout<<'\n'<<"Do you wish to send this program? (Y/N)";
			response=userresponse();
			if (response=='y' || response=='Y')
			{
				cout<<'\n'<<"Make sure the PIC16C84 is in program mode (12V-14V on pin 4) then press a key";
				getch();
				linespace(2);
				cout<<"Sending program to PIC16C84";
				sendbyte(6,0x2);
				sendbyte(1,0);
				sendbyte(8,0x5);
				sendbyte(6,0x28);/*goto address 0005 (start of program)*/
				sendbyte(1,0);
				sendbyte(6,0x8);
				sendbyte(6,6);/*increment address by 4*/
				sendbyte(6,6);
				sendbyte(6,6);
				sendbyte(6,6);

				/*send bytes to pic*/
				for(l=0; l<count; l+=2)
				{
					sendbyte(6,2);
					sendbyte(1,0);
					sendbyte(8,data[l+1]);/*low byte first*/
					sendbyte(6,data[l]);/*high byte second*/
					sendbyte(1,0);
					sendbyte(6,8);/*program data*/
					delay(10);
					sendbyte(6,6);/*increment address by one*/
				}

				cout<<'\n'<<"Program transfer complete";
				cout<<'\n'<<'\n'<<"Return pin 4 of PIC to +5V then press reset to run program";
				cout<<'\n'<<"Press a key to return to main menu";
				getch();
			}
		}
	}
	else
	{
		cout<<'\n'<<"ERROR: cannot open file, press a key";
		getch();
	}
}

void configuration()
{
	unsigned int configval=0;
	unsigned int selection,l;

	linespace(10);
	cout<<"            Program to set configuration fuses"<<'\n';
	cout<<"WARNING: Any program presently in the PIC16C84 will be erased";
	linespace(3);
	cout<<"Please enter which type of oscillator you wish the PIC16C84 to use:"<<'\n';
	cout<<'\n'<<"1... LP low power crystal oscillator (32KHz - 200KHz)"<<'\n'
	  <<"2... XT crystal oscillator (100KHz - 4MHz)"<<'\n'
	  <<"3... HS High speed crystal oscillator (4MHz - 10MHz)"<<'\n'
	  <<"4... RC Resistor capacitor oscillator"<<'\n'<<'\n';
	cout<<"Enter selection 1 to 4 ";
	selection=getresponse('1','4');

	switch((char)selection)
	{
		case '1' : cout<<"LP selected";
			break;

		case '2' : cout<<"XT selected";
			configval = configval | 1;
			break;

		case '3' : cout<<"HS selected";
			configval = configval | 2;
			break;

		case '4' : cout<<"RC selected";
			configval = configval | 3;
			break;
	 }

	linespace(2);
	cout<<"Enable watchdog timer ? "<<'\n'<<'\n';
	cout<<"enter Y or N ";
	if((char)userresponse()== 'y')
	{
		cout<<"Yes";
		configval = configval | 4;
	}
	else
		cout<<"No";

	linespace(2);
	cout<<"Enable power-up timer ? "<<'\n'<<'\n'
		<<"enter Y or N ";

	if((char)userresponse() == 'y')
	{
		cout<<" Yes";
		configval = configval | 8;
	}
	else
		cout<<"No";

	configval = configval | 16;
	linespace(2);
	cout<<"Send configuration data to PIC16C84 ? (Y/N)"<<'\n';

	if((char)userresponse() == 'y')
	{
		cout<<'\n'<<"Make sure PIC16C84 is in program mode (12V-14V on pin 4)"<<'\n'
			<<"then press a key to begin transfer";
		getch();
		sendbyte(6,0);
		sendbyte(1,0);
		sendbyte(8,configval);
		sendbyte(6,63);
		sendbyte(1,0);

		for(l=1;l<=7;l++)
			sendbyte(6,6);

		sendbyte(6,1);
		sendbyte(6,7);
		sendbyte(6,8);
		delay(10);
		sendbyte(6,1);
		sendbyte(6,7);
		cout<<'\n'<<"Configuration data sent";
		linespace(3);
		cout<<"Now reset the PIC16C84 (pin 4 low briefly), press a key";
		getch();
	}
}

void main()
{
	int selection;

	do
	{
		linespace(25);
		cout<<"PIC16C84 Programmer by Derren Crome";
		linespace(2);
		cout<<"1..... PIC16C84 configuration set-up"<<'\n'
		<<"2..... Load object code and send to PIC"<<'\n'
		<<"3..... Quit program";
		linespace(4);
		cout<<"enter option 1, 2 or 3";
		selection=getresponse((int)'1',(int)'3');
		if(selection == '1')
			configuration();
		if(selection == '2')
			send();
	}
	while(selection != '3');
}
