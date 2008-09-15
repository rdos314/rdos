#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dnapop.h"
#include "dnaseq.h"
#include "dnamut.h"
#include "dnaind.h"
#include "dnaeval.h"

#define FALSE	0
#define	TRUE	!FALSE

int main(int argc, char **argv)
{
	TDnaPopulation *pop;
	TDnaMutator *fastmut;
	TDnaEvaluator *eval;
	int i;

	randomize();
	random(1000);

	fastmut = new TDnaMutator(500, 0.1);
	eval = new TDnaEvaluator(500);

	pop = new TDnaPopulation(fastmut, 100, 500);
	pop->Create(200);
	pop->WriteScores(eval);

	for (i = 0; i < 500; i++)
	{
		pop->Pairbond();
		pop->CreateChildren(eval);
	}

	pop->Pairbond();
	pop->WritePairs(eval);

	pop->CreateChildren(eval);
	pop->WriteScores(eval);

	return 0;
}

