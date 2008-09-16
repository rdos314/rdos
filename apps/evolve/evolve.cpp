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

#define POP_SIZE	500
#define SEQ_SIZE	500

int main(int argc, char **argv)
{
	TDnaPopulation *pop;
	TDnaMutator *fastmut;
	TDnaEvaluator *eval;
	int i;

	randomize();
	random(1000);

	fastmut = new TDnaMutator(SEQ_SIZE, 0.01);
	eval = new TDnaEvaluator(SEQ_SIZE);

	pop = new TDnaPopulation(fastmut, 100, SEQ_SIZE);
	pop->Create(POP_SIZE);
	pop->WriteScores(eval);

	for (i = 0; i < 2000; i++)
	{
		pop->Pairbond();
		pop->WritePairSumary(eval);
		pop->CreateChildren(eval);
	}

	return 0;
}                       

