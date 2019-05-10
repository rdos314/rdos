#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "serial.h"
#include "section.h"
#include "file.h"
#include "rdos.h"
#include "modbus.h"
#include "sockobj.h"
#include "websock.h"
#include "httpfact.h"
#include "json.h"
#include "xml.h"

#include <math.h>
#include "bignum.h"

#include "section.h"

#include "testlib.h"

#define FALSE 0
#define TRUE !FALSE

void HandlePay(XMLElement *elem)
{    TString result = elem->GetVariableString("result", "");;
    TString stan = elem->GetVariableString("stan", "");;
    XMLElement *tokenelem = elem->GetElement("token");
    XMLElement *recelem = elem->GetElement("receipt1");
    TString FToken;
    TString receipt;
    TString utfrec;
    TString reason;
    const char *ptr;
    long MaxAmount;
    int exp;
    int count;

    if (recelem)
        receipt = recelem->GetContentString("");

    if (tokenelem)
    {
        {
            exp = elem->GetVariableInt("exponent", 2);
            MaxAmount = elem->GetVariableInt("amount", MaxAmount);

            while (exp < 2)
            {
                MaxAmount = 10 * MaxAmount;
                exp++;
            }

            while (exp > 2)
            {
                MaxAmount = MaxAmount / 10;
                exp--;
            }
        }

        FToken = tokenelem->GetContentString("");

        if (FToken.GetSize())
        {
        }
    }
    else
    {
    }

}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void main()
{
    char *buf;
    TFile file("msg.txt");
    int size = file.GetSize();
    XML doc;
    XMLElement *root;
    char *name;

    buf = new char[size];
    file.Read(buf, size);

    doc.LoadText(buf);

    root = doc.GetRootElement();

    if (root)
    {
        size = root->GetElementName(0, TRUE);
        name = new char [size + 1];
        root->GetElementName(name, TRUE);

        HandlePay(root);
    }



    RdosTestGate("");
}
