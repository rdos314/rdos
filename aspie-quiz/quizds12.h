
struct TQuizRow
{
    long ID;
    long userid;
    int  BirthYear;
    int  BirthMonth;
	char Gender;
    char Lang;
	char Autism;
	char Aspie;
	char ADHD;
	char TS;
	char Dyspraxia;
	char Dyslexia;
	char Dyscalculia;
	char Bipolar;
	char Schizophrenia;
	char Social;
	char Referer[100];
	long AsResult;
	long NtResult;
	long GiftedResult;
	char Quiz[250];
	char GroupResult[ACTIVE_GROUP_COUNT];
};

