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
	TDnaSequence *ref;
	TDnaPopulation *pop;
	TDnaMutator *fastmut;
	TDnaMutator *refmut;
	TDnaEvaluator *eval;
	int i;

	randomize();
	random(1000);

	refmut = new TDnaMutator(SEQ_SIZE, 0.00001);
	fastmut = new TDnaMutator(SEQ_SIZE, 0.01);
	eval = new TDnaEvaluator(SEQ_SIZE);
	ref = eval->GetSeq();

	pop = new TDnaPopulation(fastmut, 100, SEQ_SIZE);
	pop->CreateUniform(ref, POP_SIZE);

	for (i = 0; i < 200; i++)
	{
		pop->Pairbond(10);
		pop->WritePairSumary(eval);
		pop->CreateChildren(eval, 1);
		ref->Mutate(refmut);
	}

	return 0;
}                       

