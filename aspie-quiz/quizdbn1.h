
struct TQuizRow
{
    long ID;
    long UserID;
    long LsbTime;
    long MsbTime;
    long FilloutTime;
    int  BirthYear;
    int  BirthMonth;
	char Gender;
    char Lang;
	char Autism;
	char Aspie;
	char ADHD;
	char Dyspraxia;
	char Dyslexia;
	char Dyscalculia;
	char OCD;
	char Bipolar;
	char Schizophrenia;
	char Social;
	int PredAutism;
	int PredAs;
	int PredAdd;
	int PredDyspraxia;
	int PredDyslexia;
	int PredDyscalculia;
	int PredOcd;
	int PredBipolar;
	int PredSchizo;
	int PredSocial;
	long AsResult;
	long NtResult;
	char Quiz[250];
	char GroupResult[ACTIVE_GROUP_COUNT];
};
