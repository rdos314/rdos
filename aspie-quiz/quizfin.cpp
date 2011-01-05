/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2008, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# quizfin.cpp
# Quiz class for final version
#
#######################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizfin.h"
#include "quizdbf.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

class TRace
{
public:
	TRace();
	void Add(TQuizRow *Row);
	void WriteUsRow(TFile &file, int index, const char *text);
	void WriteAllRow(TFile &file, int index, const char *text);
	void WriteEntry(TFile &file, int val, int count);

	static void WriteHeader(TFile &file);

	int UsCount[10];
	int UsAsCount[10];
	int AllCount[10];
	int AllAsCount[10];
};

/*##########################################################################
#
#   Name       : TQuizFinal::TQuizFinal
#
#   Purpose....: Constructor for TQuizFinal
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizFinal::TQuizFinal(const char *FileName)
  : TQuiz(150),
	FDataFile(FileName)
{
	SetupTexts();
	SetupCross();

	InitReferers();
	LoadReferers();
	SetupControlGroups();
	SortReferers();
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizFinal::~TQuizFinal
#
#   Purpose....: Destructor for TQuizFinal
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizFinal::~TQuizFinal()
{
}

/*##################  TQuizFinal::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizFinal::GetPcaCount()
{
	return 4;
}

/*##################  TQuizFinal::GetCatCount ##########################
*   Purpose....: Return number of categories for question  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizFinal::GetCatCount(int Question)
{
	return 3;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive or temporary questions)  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizFinal::GetQuizN()
{
	return 150;
}

/*##########################################################################
#
#   Name       : TQuizFinal::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal::WriteName(TFile &File)
{
	 File.Write("F");
}

/*##########################################################################
#
#   Name       : TQuizFinal::WriteLongName
#
#   Purpose....: Write long quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal::WriteLongName(TFile &File)
{
	 File.Write("final version");
}

/*##########################################################################
#
#   Name       : TQuizFinal::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal::SetupTexts()
{
  Quiz[14].Reverse = TRUE;
  Quiz[17].Reverse = TRUE;
  Quiz[27].Reverse = TRUE;
  Quiz[28].Reverse = TRUE;
  Quiz[29].Reverse = TRUE;
  Quiz[30].Reverse = TRUE;
  Quiz[31].Reverse = TRUE;
  Quiz[32].Reverse = TRUE;
  Quiz[51].Reverse = TRUE;
  Quiz[85].Reverse = TRUE;
  Quiz[86].Reverse = TRUE;
  Quiz[88].Reverse = TRUE;
  Quiz[89].Reverse = TRUE;
  Quiz[90].Reverse = TRUE;
  Quiz[91].Reverse = TRUE;
  Quiz[132].Reverse = TRUE;
  Quiz[134].Reverse = TRUE;
  Quiz[145].Reverse = TRUE;
  Quiz[146].Reverse = TRUE;
  Quiz[147].Reverse = TRUE;
  Quiz[148].Reverse = TRUE;
  Quiz[149].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_NT_SOCIAL;
  Quiz[1].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[2].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[3].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[4].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[5].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[6].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[7].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[8].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[9].MyGroup = GROUP_NT_TALENT;
  Quiz[10].MyGroup = GROUP_NT_TALENT;
  Quiz[11].MyGroup = GROUP_NT_TALENT;
  Quiz[12].MyGroup = GROUP_NT_TALENT;
  Quiz[13].MyGroup = GROUP_NT_TALENT;
  Quiz[14].MyGroup = GROUP_NT_TALENT;
  Quiz[15].MyGroup = GROUP_NT_TALENT;
  Quiz[16].MyGroup = GROUP_NT_TALENT;
  Quiz[17].MyGroup = GROUP_NT_TALENT;
  Quiz[18].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[19].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[20].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[21].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[22].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[23].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[24].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[25].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[26].MyGroup = GROUP_ASPIE_OBSESSION;
  Quiz[27].MyGroup = GROUP_NT_OBSESSION;
  Quiz[28].MyGroup = GROUP_NT_OBSESSION;
  Quiz[29].MyGroup = GROUP_NT_OBSESSION;
  Quiz[30].MyGroup = GROUP_NT_OBSESSION;
  Quiz[31].MyGroup = GROUP_NT_OBSESSION;
  Quiz[32].MyGroup = GROUP_NT_OBSESSION;
  Quiz[33].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[34].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[35].MyGroup = GROUP_NT_TALENT;
  Quiz[36].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[37].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[38].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[39].MyGroup = GROUP_NT_SOCIAL;
  Quiz[40].MyGroup = GROUP_NT_SOCIAL;
  Quiz[41].MyGroup = GROUP_NT_SOCIAL;
  Quiz[42].MyGroup = GROUP_NT_SOCIAL;
  Quiz[43].MyGroup = GROUP_NT_SOCIAL;
  Quiz[44].MyGroup = GROUP_NT_SOCIAL;
  Quiz[45].MyGroup = GROUP_NT_SOCIAL;
  Quiz[46].MyGroup = GROUP_NT_SOCIAL;
  Quiz[47].MyGroup = GROUP_NT_SOCIAL;
  Quiz[48].MyGroup = GROUP_NT_SOCIAL;
  Quiz[49].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[50].MyGroup = GROUP_NT_SOCIAL;
  Quiz[51].MyGroup = GROUP_NT_SOCIAL;
  Quiz[52].MyGroup = GROUP_NT_SOCIAL;
  Quiz[53].MyGroup = GROUP_ASPIE_NVC;
  Quiz[54].MyGroup = GROUP_ASPIE_NVC;
  Quiz[55].MyGroup = GROUP_ASPIE_NVC;
  Quiz[56].MyGroup = GROUP_ASPIE_NVC;
  Quiz[57].MyGroup = GROUP_ASPIE_NVC;
  Quiz[58].MyGroup = GROUP_ASPIE_NVC;
  Quiz[59].MyGroup = GROUP_ASPIE_NVC;
  Quiz[60].MyGroup = GROUP_ASPIE_NVC;
  Quiz[61].MyGroup = GROUP_ASPIE_NVC;
  Quiz[62].MyGroup = GROUP_ASPIE_NVC;
  Quiz[63].MyGroup = GROUP_ASPIE_NVC;
  Quiz[64].MyGroup = GROUP_ASPIE_NVC;
  Quiz[65].MyGroup = GROUP_ASPIE_NVC;
  Quiz[66].MyGroup = GROUP_ASPIE_NVC;
  Quiz[67].MyGroup = GROUP_ASPIE_NVC;
  Quiz[68].MyGroup = GROUP_ASPIE_NVC;
  Quiz[69].MyGroup = GROUP_ASPIE_NVC;
  Quiz[70].MyGroup = GROUP_ASPIE_NVC;
  Quiz[71].MyGroup = GROUP_ASPIE_NVC;
  Quiz[72].MyGroup = GROUP_ASPIE_NVC;
  Quiz[73].MyGroup = GROUP_ASPIE_NVC;
  Quiz[74].MyGroup = GROUP_ASPIE_NVC;
  Quiz[75].MyGroup = GROUP_ASPIE_NVC;
  Quiz[76].MyGroup = GROUP_NT_NVC;
  Quiz[77].MyGroup = GROUP_NT_NVC;
  Quiz[78].MyGroup = GROUP_NT_NVC;
  Quiz[79].MyGroup = GROUP_NT_NVC;
  Quiz[80].MyGroup = GROUP_NT_NVC;
  Quiz[81].MyGroup = GROUP_NT_NVC;
  Quiz[82].MyGroup = GROUP_NT_NVC;
  Quiz[83].MyGroup = GROUP_NT_NVC;
  Quiz[84].MyGroup = GROUP_NT_NVC;
  Quiz[85].MyGroup = GROUP_NT_NVC;
  Quiz[86].MyGroup = GROUP_NT_NVC;
  Quiz[87].MyGroup = GROUP_NT_NVC;
  Quiz[88].MyGroup = GROUP_NT_NVC;
  Quiz[89].MyGroup = GROUP_NT_NVC;
  Quiz[90].MyGroup = GROUP_NT_NVC;
  Quiz[91].MyGroup = GROUP_NT_NVC;
  Quiz[92].MyGroup = GROUP_NT_NVC;
  Quiz[93].MyGroup = GROUP_NT_SENSORY;
  Quiz[94].MyGroup = GROUP_NT_NVC;
  Quiz[95].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[96].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[97].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[98].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[99].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[100].MyGroup = GROUP_ASPIE_HUNTING;
  Quiz[101].MyGroup = GROUP_NT_HUNTING;
  Quiz[102].MyGroup = GROUP_NT_HUNTING;
  Quiz[103].MyGroup = GROUP_NT_HUNTING;
  Quiz[104].MyGroup = GROUP_NT_HUNTING;
  Quiz[105].MyGroup = GROUP_NT_HUNTING;
  Quiz[106].MyGroup = GROUP_NT_HUNTING;
  Quiz[107].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[108].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[109].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[110].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[111].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[112].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[113].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[114].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[115].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[116].MyGroup = GROUP_ASPIE_SENSORY;
  Quiz[117].MyGroup = GROUP_NT_SENSORY;
  Quiz[118].MyGroup = GROUP_NT_SENSORY;
  Quiz[119].MyGroup = GROUP_NT_SENSORY;
  Quiz[120].MyGroup = GROUP_NT_SENSORY;
  Quiz[121].MyGroup = GROUP_NT_SENSORY;
  Quiz[122].MyGroup = GROUP_NT_SENSORY;
  Quiz[123].MyGroup = GROUP_NT_SENSORY;
  Quiz[124].MyGroup = GROUP_ENVIRONMENT;
  Quiz[125].MyGroup = GROUP_ENVIRONMENT;
  Quiz[126].MyGroup = GROUP_ENVIRONMENT;
  Quiz[127].MyGroup = GROUP_ENVIRONMENT;
  Quiz[128].MyGroup = GROUP_ENVIRONMENT;
  Quiz[129].MyGroup = GROUP_ENVIRONMENT;
  Quiz[130].MyGroup = GROUP_ENVIRONMENT;
  Quiz[131].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[132].MyGroup = GROUP_NT_OBSESSION;
  Quiz[133].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[134].MyGroup = GROUP_NT_OBSESSION;
  Quiz[135].MyGroup = GROUP_NT_NVC;
  Quiz[136].MyGroup = GROUP_NT_NVC;
  Quiz[137].MyGroup = GROUP_MIXED;
  Quiz[138].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[139].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[140].MyGroup = GROUP_NT_NVC;
  Quiz[141].MyGroup = GROUP_NT_NVC;
  Quiz[142].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[143].MyGroup = GROUP_MIXED;
  Quiz[144].MyGroup = GROUP_ASPIE_NVC;

  Quiz[145].MyGroup = GROUP_NT_TALENT;
  Quiz[146].MyGroup = GROUP_NT_SOCIAL;
  Quiz[147].MyGroup = GROUP_NT_NVC;
  Quiz[148].MyGroup = GROUP_NT_SENSORY;
  Quiz[149].MyGroup = GROUP_ENVIRONMENT;

#ifdef ENGLISH

  Quiz[0].Text = "Do you often feel out-of-sync with others?";
  Quiz[1].Text = "Do you tend to get so absorbed by your special interests that you forget or ignore everything else?";
  Quiz[2].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[3].Text = "Do you focus on one interest at a time and become an expert on that subject?";
  Quiz[4].Text = "Do you or others think that you have unconventional ways of solving problems?";
  Quiz[5].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
  Quiz[6].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[7].Text = "Do you notice patterns in things all the time?";
  Quiz[8].Text = "Do you need periods of contemplation?";
  Quiz[9].Text = "Do you get confused by verbal instructions - especially several at the same time?";
  Quiz[10].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[11].Text = "Do you find it hard to multi-task or shift your attention rapidly from one thing to another and therefore need to finish one task before turning to the next?";
  Quiz[12].Text = "Do you have difficulty describing & summarising things for example events, conversations or something you've read?";
  Quiz[13].Text = "Do you need to do things yourself in order to remember them?";
  Quiz[14].Text = "If there is an interruption, can you quickly return to what you were doing before?";
  Quiz[15].Text = "Do you find it very hard to learn things that you are not interested in?";
  Quiz[16].Text = "Do you find it difficult to take notes in lectures?";
  Quiz[17].Text = "Can you easily keep track of several different people's conversations?";
  Quiz[18].Text = "Does it feel vitally important to be left undisturbed when focusing on your special interests?";
  Quiz[19].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
  Quiz[20].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[21].Text = "Do you become frustrated if an activity that is important to you gets interrupted?";
  Quiz[22].Text = "Do you get frustrated if you can't sit on your favorite seat?";
  Quiz[23].Text = "Do you have strong attachments to certain favorite objects?";
  Quiz[24].Text = "Do you have certain routines which you need to follow?";
  Quiz[25].Text = "Do you find it disturbing or upsetting when others show up either later or sooner than agreed?";
  Quiz[26].Text = "Do you need lists and schedules in order to get things done?";
  Quiz[27].Text = "Do you enjoy meeting new people?";
  Quiz[28].Text = "Are your views typical of your peer group?";
  Quiz[29].Text = "Do you enjoy hosting or arranging events?";
  Quiz[30].Text = "Do you have an interest for the current fashions?";
  Quiz[31].Text = "Do you prefer the company of those of the same generation as yourself?";
  Quiz[32].Text = "Do you enjoy gossip?";
  Quiz[33].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[34].Text = "Do you have problems starting and / or finishing projects?";
  Quiz[35].Text = "Are you easily distracted?";
  Quiz[36].Text = "Are you poor at organizing your work and / or life?";
  Quiz[37].Text = "Are you or have you been hyperactive?";
  Quiz[38].Text = "Do you tend to procrastinate?";
  Quiz[39].Text = "Do you have a tendency to become stuck when asked questions in social situation?";
  Quiz[40].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
  Quiz[41].Text = "Has it been harder for you than for others to keep friends?";
  Quiz[42].Text = "Do you avoid talking face to face with someone you don't know very well?";
  Quiz[43].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[44].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[45].Text = "Do people think you are aloof and distant?";
  Quiz[46].Text = "Do you find it hard to be emotionally close to other people?";
  Quiz[47].Text = "Do you dislike shaking hands?";
  Quiz[48].Text = "Do you prefer to do things on your own even if you could use others' help or expertise?";
  Quiz[49].Text = "Do you dislike when people walk behind you?";
  Quiz[50].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[51].Text = "Do you find it natural to wave or say 'hi' when you meet people?";
  Quiz[52].Text = "Do you dislike reading aloud?";
  Quiz[53].Text = "Do people comment on your unusual mannerisms and habits?";
  Quiz[54].Text = "Do people sometimes think you are smiling at the wrong occasion?";
  Quiz[55].Text = "Do you often have lots of thoughts that you find hard to verbalize?";
  Quiz[56].Text = "Do you often don't know where to put your arms?";
  Quiz[57].Text = "Do you tend to talk either too softly or too loudly?";
  Quiz[58].Text = "Have others commented or have you observed yourself that you make unusual facial expressions?";
  Quiz[59].Text = "Have you been accused of staring?";
  Quiz[60].Text = "Have others told you that you have an odd posture or gait?";
  Quiz[61].Text = "Do you wring your hands, rub your hands together or twirl your fingers?";
  Quiz[62].Text = "Do you rock back-&-forth or side-to-side (e.g. for comfort, to calm yourself, when excited or overstimulated)?";
  Quiz[63].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[64].Text = "In conversations, do you use small sounds that others don't seem to use?";
  Quiz[65].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
  Quiz[66].Text = "Do you tap your ears or press your eyes (e.g. when thinking, when stressed or distressed)?";
  Quiz[67].Text = "Do you fiddle with things?";
  Quiz[68].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
  Quiz[69].Text = "Do you pace (e.g. when thinking or anxious)?";
  Quiz[70].Text = "Do you stutter when stressed?";
  Quiz[71].Text = "Do you tend to look a lot at people you like and little or not at all at people you dislike?";
  Quiz[72].Text = "Do you bite your lip, cheek or tongue (e.g. when thinking, when anxious or nervous)?";
  Quiz[73].Text = "Do you talk to yourself?";
  Quiz[74].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
  Quiz[75].Text = "Do you have difficulties with pronunciation?";
  Quiz[76].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[77].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[78].Text = "Do others often misunderstand you?";
  Quiz[79].Text = "Do you tend to express your feelings in ways that may baffle others?";
  Quiz[80].Text = "Do you forget you are in a social situation when something gets your attention?";
  Quiz[81].Text = "Are you usually unaware of social rules & boundaries unless they are clearly spelled out?";
  Quiz[82].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
  Quiz[83].Text = "Do you find it difficult to work out people's intentions?";
  Quiz[84].Text = "Do you tend to say things that are considered socially inappropriate?";
  Quiz[85].Text = "Do you instinctively know when it is your turn to speak when talking on the phone?";
  Quiz[86].Text = "Are you good at returning social courtesies and gestures?";
  Quiz[87].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
  Quiz[88].Text = "Do you know when you are expected to offer an apology?";
  Quiz[89].Text = "Are you good at interpreting facial expressions?";
  Quiz[90].Text = "Do you find yourself at ease in romantic situations?";
  Quiz[91].Text = "Do you find it easy to describe your feelings?";
  Quiz[92].Text = "Do you have a monotonous voice?";
  Quiz[93].Text = "Do you have problems recognizing faces (prosopagnosia)?";
  Quiz[94].Text = "Are you so honest and sincere yourself that you assume everyone is?";
  Quiz[95].Text = "Do you enjoy watching a spinning or blinking object?";
  Quiz[96].Text = "Do you have a fascination for slowly flowing water?";
  Quiz[97].Text = "Do you sometimes have an urge to jump over things?";
  Quiz[98].Text = "Do you enjoy mimicking animal sounds?";
  Quiz[99].Text = "Do you enjoy walking on your toes?";
  Quiz[100].Text = "Have you been fascinated about making traps?";
  Quiz[101].Text = "Do you find it difficult to take messages on the telephone and pass them on correctly?";
  Quiz[102].Text = "Do you drop things when your attention is on other things?";
  Quiz[103].Text = "Do you have problems filling out forms?";
  Quiz[104].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
  Quiz[105].Text = "Do you have trouble reading clocks?";
  Quiz[106].Text = "Do you mix up digits in numbers like 95 and 59?";
  Quiz[107].Text = "Do you suddenly feel distracted by distant sounds?";
  Quiz[108].Text = "Do you notice small sounds that others don't, or feel pained by loud or irritating noise?";
  Quiz[109].Text = "Do you have difficulties filtering out background noise when talking to someone?";
  Quiz[110].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[111].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
  Quiz[112].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[113].Text = "Are you sensitive to changes in humidity and air pressure?";
  Quiz[114].Text = "Do you instinctively become frightened by the sound of a motor-bike?";
  Quiz[115].Text = "Do you dislike it when people stamp their foot in the floor?";
  Quiz[116].Text = "Does it come more natural to you to think in pictures than in words?";
  Quiz[117].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[118].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[119].Text = "Do you have poor concept of time?";
  Quiz[120].Text = "Do you find it hard to tell the age of people?";
  Quiz[121].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[122].Text = "Do you have difficulties with activities requiring manual precision, e.g sewing, tying shoe-laces, fastening buttons or handling small objects?";
  Quiz[123].Text = "Do you have problems finding your way to new places?";
  Quiz[124].Text = "Do you tend to shut down or have a meltdown when stressed or overwhelmed?";
  Quiz[125].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[126].Text = "Are you sometimes afraid in safe situations?";
  Quiz[127].Text = "Do you have difficulty accepting criticism, correction, and direction?";
  Quiz[128].Text = "Are you prone to getting depressions?";
  Quiz[129].Text = "Have you been bullied, abused or taken advantage of?";
  Quiz[130].Text = "Do you tend to be impatient and/or impulsive?";
  Quiz[131].Text = "Do you have an alternative view of what is attractive in the opposite sex?";
  Quiz[132].Text = "Do you naturally fit into the expected gender stereotypes?";
  Quiz[133].Text = "Do you have unusual sexual preferences?";
  Quiz[134].Text = "Do you find it natural that males take initiatives to start a romantic relationship?";
  Quiz[135].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
  Quiz[136].Text = "In conversations, do you need extra time to carefully think out your reply, so that there may be a pause before you answer?";
  Quiz[137].Text = "Have you had the feeling of playing a game, pretending to be like people around you?";
  Quiz[138].Text = "Do you find it easier to understand and communicate with odd & unusual people than with ordinary people?";
  Quiz[139].Text = "Do you or others think that you have unusual eating habits?";
  Quiz[140].Text = "Have you taken initiative only to find out it was not wanted?";
  Quiz[141].Text = "Do you turn words around in conversations?";
  Quiz[142].Text = "Do you have immature interests?";
  Quiz[143].Text = "If asked to describe yourself, would you do so in a detached way, as if you were describing someone else?";
  Quiz[144].Text = "Do you expect other people to know your thoughts, experiences and opinions without you having to tell them?";
  Quiz[145].Text = "Can you easily remember verbal instructions?";
  Quiz[146].Text = "Are you good at teamwork?";
  Quiz[147].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[148].Text = "Do you find it easy to estimate the age of people?";
  Quiz[149].Text = "Are you gracious about criticism, correction and direction?";

#endif

#ifdef SWEDISH

  Quiz[0].Text = "Känner du dig ofta ur fas med andra?";
  Quiz[1].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer/struntar i allting annat?";
  Quiz[2].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[3].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[4].Text = "Tycker du själv eller din omgivning att du löser problem på okonventionella sätt?";
  Quiz[5].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
  Quiz[6].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[7].Text = "Ser du mönster i saker hela tiden?";
  Quiz[8].Text = "Behöver du perioder av begrundande?";
  Quiz[9].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
  Quiz[10].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
  Quiz[11].Text = "Har du svårt att göra flera saker samtidigt, snabbt skifta fokus från en sak till en annan och därför behov av att få göra klart det du håller på med innan du kan ta itu med något annat?";
  Quiz[12].Text = "Har du svårt att sammanfatta och redogöra för t ex konversationer, händelser eller något du läst?";
  Quiz[13].Text = "Har du behov av att göra saker själv för att riktigt minnas dem?";
  Quiz[14].Text = "Om du blir avbruten, kan du snabbt återgå till vad du gjorde innan?";
  Quiz[15].Text = "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
  Quiz[16].Text = "Har du svårt att göra anteckningar under föreläsningar?";
  Quiz[17].Text = "Kan du lätt hålla koll på flera olika människors konversationer?";
  Quiz[18].Text = "Känns det livsviktigt att få vara ifred när du ägnar dig åt dina specialintressen?";
  Quiz[19].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
  Quiz[20].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[21].Text = "Blir du frustrerad om en för dig viktig aktivitet blir avbruten?";
  Quiz[22].Text = "Blir du frustrerad om du inte får sitta på din favoritplats?";
  Quiz[23].Text = "Är du exceptionellt fäst vid vissa favoritsaker?";
  Quiz[24].Text = "Har du vissa rutiner som du behöver följa?";
  Quiz[25].Text = "Blir du störd eller upprörd när andra kommer antingen för för sent eller för tidigt?";
  Quiz[26].Text = "Behöver du listor och scheman för att få saker gjorda?";
  Quiz[27].Text = "Trivs du med att möta nya människor?";
  Quiz[28].Text = "Är dina åsikter typiska för dina jämnåriga?";
  Quiz[29].Text = "Tycker du om att anordna eller vara värd för aktiviter?";
  Quiz[30].Text = "Är du intressad av nuvarande mode?";
  Quiz[31].Text = "Umgås du helst med personer ur din egen generation?";
  Quiz[32].Text = "Tycker du om skvaller?";
  Quiz[33].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[34].Text = "Har du problem att starta och / eller slutföra projekt?";
  Quiz[35].Text = "Blir du lätt distraherad?";
  Quiz[36].Text = "Är du dålig på att organisera ditt arbete och / eller liv?";
  Quiz[37].Text = "Är du eller har du varit hyperaktiv";
  Quiz[38].Text = "Brukar du skjuta upp saker in i det längsta?";
  Quiz[39].Text = "Låser det sig för dig när du får frågor i sociala situationer?";
  Quiz[40].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
  Quiz[41].Text = "Har du haft svårare än andra att behålla vänner?";
  Quiz[42].Text = "Undviker du att prata ansikte-mot-ansikte med folk du inte känner mycket väl?";
  Quiz[43].Text = "Brukar du bli utmattad av att umgås med folk och behöva vila ut ifred efteråt?";
  Quiz[44].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller har bett om det?";
  Quiz[45].Text = "Tycker folk att du är reserverad och distanserad?";
  Quiz[46].Text = "Tycker du det är svårt att vara känslomässigt nära andra människor?";
  Quiz[47].Text = "Ogillar du att behöva ta i hand?";
  Quiz[48].Text = "Föredrar du att göra saker på egen hand även om du skulle ha användning för andras hjälp och expertis?";
  Quiz[49].Text = "Ogillar du när folk går bakom dig?";
  Quiz[50].Text = "Ogillar du när folk kommer på besök oanmälda?";
  Quiz[51].Text = "Tycker du det är naturligt att vinka eller säga 'hej' när du möter folk?";
  Quiz[52].Text = "Ogillar du högläsning?";
  Quiz[53].Text = "Brukar folk kommentera ditt ovanliga uppförande och dina ovanliga vanor?";
  Quiz[54].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
  Quiz[55].Text = "Har du ofta massor av tankar som du har svårt för att formulera i ord?";
  Quiz[56].Text = "Vet du ofta inte var du ska göra av dina armar?";
  Quiz[57].Text = "Har du en tendens att tala antingen för tyst eller för högt?";
  Quiz[58].Text = "Har andra kommenterat eller har du själv observerat att du har ovanliga ansiktsuttryck?";
  Quiz[59].Text = "Har du blivit anklagad för att stirra?";
  Quiz[60].Text = "Har andra kommenterat att du har udda kroppshållning eller gångstil?";
  Quiz[61].Text = "Brukar du gnugga händer, eller vrida händerna eller fingrarna om varandra?";
  Quiz[62].Text = "Brukar du gunga fram-&-tillbaka eller i sidled (t ex för att lunga ner dig, när du är upprymd eller övertimulerad)?";
  Quiz[63].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas upp om och om igen?";
  Quiz[64].Text = "I samtal, använder du små ljud som andra inte verkar använda?";
  Quiz[65].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
  Quiz[66].Text = "Brukar du trumma på öronen eller trycka på ögonen (t ex när du tänker, när du är stressad eller upprörd)?";
  Quiz[67].Text = "Brukar du fingra på saker?";
  Quiz[68].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
  Quiz[69].Text = "Brukar du vanka av och an (t ex när du tänker eller är orolig)?";
  Quiz[70].Text = "Stammar du när du blir stressad?";
  Quiz[71].Text = "Har du en tendens att titta mycket på människor du gillar och lite eller inte alls på människor du ogillar?";
  Quiz[72].Text = "Brukar du bita dig i läppen, kinden eller tungan (t ex när du tänker, när du är orolig eller nervös)?";
  Quiz[73].Text = "Brukar du prata med dig själv?";
  Quiz[74].Text = "Blandar du ibland ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
  Quiz[75].Text = "Har du svårigheter med uttal?";
  Quiz[76].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[77].Text = "I samtal, brukar du ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[78].Text = "Blir du ofta missförstådd av andra?";
  Quiz[79].Text = "Brukar du uttrycka känslor på sätt som förbryllar andra?";
  Quiz[80].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
  Quiz[81].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[82].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
  Quiz[83].Text = "Har du svårt att räkna ut folks intentioner?";
  Quiz[84].Text = "Brukar du säga saker som anses socialt opassande?";
  Quiz[85].Text = "Känner du instinktivt på dig när det är din tur att tala när du pratar i telefon?";
  Quiz[86].Text = "Är du bra på att återgälda sociala gester och artigheter?";
  Quiz[87].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?";
  Quiz[88].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[89].Text = "Är du bra på att tolka ansiktsuttryck?";
  Quiz[90].Text = "Trivs du i romantiska situationer?";
  Quiz[91].Text = "Har du lätt att beskriva dina känslor?";
  Quiz[92].Text = "Har du en monoton röst?";
  Quiz[93].Text = "Har du svårt att känna igen ansikten?";
  Quiz[94].Text = "Är det så naturligt för dig att vara totalt ärlig att du tror alla är sådana?";
  Quiz[95].Text = "Gillar du att titta på något som snurrar eller blinkar?";
  Quiz[96].Text = "Är du fascinerad av långsamt flytande vatten?";
  Quiz[97].Text = "Brukar du ibland ha ett behov av att hoppa över saker?";
  Quiz[98].Text = "Gillar du att härma djurläten?";
  Quiz[99].Text = "Gillar du att gå på tå?";
  Quiz[100].Text = "Har du varit fascinerad av att tillverka fällor?";
  Quiz[101].Text = "Tycker du det är svårt att ta meddelenden på telefon och skicka dem vidare rätt?'";
  Quiz[102].Text = "Tappar du saker när din uppmärksamhet är på annat håll?";
  Quiz[103].Text = "Har du svårt att fylla i formulär?";
  Quiz[104].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
  Quiz[105].Text = "Har du svårigheter att läsa av klockor?";
  Quiz[106].Text = "Blandar du ihop siffor i tal som t.ex. 95 och 59?";
  Quiz[107].Text = "Blir du plötsligt distraherad av avlägsna ljud?";
  Quiz[108].Text = "Brukar du höra ljud som andra inte hör eller plågas av höga eller störande ljud?";
  Quiz[109].Text = "Har du svårt att filtrera bort störande bakgrundsljud när du talar med någon?";
  Quiz[110].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[111].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
  Quiz[112].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[113].Text = "Är du känslig för omslag i luftryck och luftfuktighet?";
  Quiz[114].Text = "Blir du instinktivt rädd för ljudet från en motorcykel?";
  Quiz[115].Text = "Ogillar du när folk stampar med foten i golvet?";
  Quiz[116].Text = "Är det mer naturligt för dig att tänka i bilder än i ord?";
  Quiz[117].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[118].Text = "Har du svårt att imitera och tajma andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[119].Text = "Har du dålig tidsuppfattning?";
  Quiz[120].Text = "Har du svårt för att bedöma andra människors ålder?";
  Quiz[121].Text = "Har du svårigheter att bedöma avstånd, höjd, djup eller fart?";
  Quiz[122].Text = "Har du svårigheter med aktiviteter som kräver finmotorisk precision, t ex att sy, knyta skosnören, knäppa knappar och hantera små föremål?";
  Quiz[123].Text = "Har du svårt att hitta till nya platser?";
  Quiz[124].Text = "Brukar du stänga av eller bryta ihop när du blir stressad eller överväldigad?";
  Quiz[125].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[126].Text = "Är du ibland rädd i ofarliga situationer?";
  Quiz[127].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
  Quiz[128].Text = "Brukar du få depressioner?";
  Quiz[129].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad?";
  Quiz[130].Text = "Brukar du vara otålig och/eller impulsiv?";
  Quiz[131].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet?";
  Quiz[132].Text = "Passar du naturligt in i de förväntade könsrollerna?";
  Quiz[133].Text = "Har du ovanliga sexuella preferenser?";
  Quiz[134].Text = "Tycker du det är naturligt att män tar initiativ till att starta ett förhållande?";
  Quiz[135].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
  Quiz[136].Text = "I samtal, brukar du behöva extra tid att noggant tänka ut vad du ska säga, så att det kan uppstå en paus innan du svarar?";
  Quiz[137].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[138].Text = "Tycker du det är lättare att förstå och kommunicera med udda & ovanliga människor än med vanliga människor?";
  Quiz[139].Text = "Tycker du själv eller din omgivning att du har ovanliga matvanor?";
  Quiz[140].Text = "Har du tagit initiativ som inte visat sig önskade?";
  Quiz[141].Text = "Blandar du om ord i konversationer?";
  Quiz[142].Text = "Har du omogna intressen?";
  Quiz[143].Text = "Om du blev ombedd att beskriva dig själv, skulle du då göra det på objektivt sätt, som om du beskrev någon annan?";
  Quiz[144].Text = "Förväntar du dig att andra ska känna till dina tankar, upplevelser och åsikter utan att du behöver berätta?";
  Quiz[145].Text = "Kommer du lätt ihåg verbala instruktioner?";
  Quiz[146].Text = "Är du bra på att arbeta i grupp?";
  Quiz[147].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[148].Text = "Har du lätt för att bedömma människors ålder?";
  Quiz[149].Text = "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";

#endif

}

/*##########################################################################
#
#   Name       : TQuizFinal::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal::InitReferers()
{
	AddReferer("livejournal.com/community/asperger", "livejournal.com/community/asperger");
	AddReferer("flashback.info", "flashback.info");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("aspergianisland.com", "aspergianisland.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("rdos.net/sv", "rdos.net/sv");
	AddReferer("aspalsta.net", "aspalsta.net/viewtopic.php?t=1951");
	AddReferer("circvsmaximvs.com", "circvsmaximvs.com/showthread.php?t=14129");
	AddReferer("panterachat.com", "panterachat.com/phpBB/viewtopic.php?t=24332");
	AddReferer("kaytastrophe.com", "kaytastrophe.com/index.php?topic=708.0");
	AddReferer("tbg.nu", "tbg.nu/news_show/109118/40");
	AddReferer("vof.se", "vof.se/forum/viewtopic.php?t=3080");
	AddReferer("autismspeaks.org", "autismspeaks.org/community/forums");
	AddReferer("nordisk.nu", "nordisk.nu/showthread.php?t=3117");
	AddReferer("swedvdr.org", "swedvdr.org/forums.php?action=viewtopic");
	AddReferer("filmtipset.se", "filmtipset.se/forum.cgi?id=1339244");
	AddReferer("tvsushi.com", "forum.tvsushi.com/index.php?showtopic=52752");
	AddReferer("smogon.com", "smogon.com/forums/showthread.php?t=29171");
	AddReferer("mommyconnection.org", "mommyconnection.org/board/index.php/topic,2840.0.html");
	AddReferer("calientemamas.com", "calientemamas.com/forum_posts.asp?TID=12136");
	AddReferer("forums.britxbox.co.uk", "forums.britxbox.co.uk/viewtopic.php?t=54722");
	AddReferer("goonfleet.com", "goonfleet.com/showthread.php?t=77152");
	AddReferer("weebls-stuff.com", "weebls-stuff.com");
	AddReferer("keithandthegirl.com", "keithandthegirl.com/forums/showthread.php?t=9785");
}

/*##########################################################################
#
#   Name       : TQuizFinal::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("rdos.net/sv");
	DefineNt("circvsmaximvs.com");
	DefineNt("panterachat.com");
	DefineNt("kaytastrophe.com");
	DefineNt("tbg.nu");
	DefineNt("vof.se");
	DefineNt("nordisk.nu");
	DefineNt("swedvdr.org");
	DefineNt("filmtipset.se");
	DefineNt("tvsushi.com");
	DefineNt("smogon.com");
	DefineNt("mommyconnection.org");
	DefineNt("calientemamas.com");
	DefineNt("forums.britxbox.co.uk");
	DefineNt("goonfleet.com");
	DefineNt("weebls-stuff.com");
	DefineNt("keithandthegirl.com");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##################  TQuizFinal::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;
	int g;
	char GroupResult[ACTIVE_GROUP_COUNT];

    for (g = 0; g < ACTIVE_GROUP_COUNT; g++)
        GroupResult[g] = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (Row.Gender == 1)
			UpdateReferer(&MaleRef, Row.AsResult, Row.NtResult, GroupResult);
        else			
			UpdateReferer(&FemaleRef, Row.AsResult, Row.NtResult, GroupResult);
	
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.Aspie == 2)
			UpdateReferer(&AsRef, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.ADHD == 2)
			UpdateReferer(&AddRef, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.OCD == 2)
			UpdateReferer(&OCDRef, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.Social == 2)
			UpdateReferer(&SocialPhobiaRef, Row.AsResult, Row.NtResult, GroupResult);

		if (Row.Aspie)
		{
			if (Row.Gender == 1)
				UpdateReferer(&MaleAsRef, Row.AsResult, Row.NtResult, GroupResult);
			else
				UpdateReferer(&FemaleAsRef, Row.AsResult, Row.NtResult, GroupResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizFinal::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal::LoadPopulations()
{
	TQuizRow Row;
	int i;
	int id;
	TReferer *ref;
	char DxArr[DX_COUNT];
	char score;
	int IdArr[MAX_QUESTIONS];
	int g;
	char GroupResult[ACTIVE_GROUP_COUNT];
	char DxResult[DX_COUNT];

	for (g = 0; g < ACTIVE_GROUP_COUNT; g++)
		GroupResult[g] = 0;

	for (g = 0; g < DX_COUNT; g++)
		DxResult[g] = 0;

	for (i = 0; i < N; i++)
	{
		Quiz[i].NoAnswer = 0;
		IdArr[i] = GetGlobalId(i);
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		BirthMonth.Add(Row.AsResult, Row.NtResult, Row.BirthMonth);
		BirthYear.Add(Row.AsResult, Row.NtResult, Row.BirthYear, Row.Gender);

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
			else
			{
				if (i < 150)
				{
					score = Row.Quiz[i] - 1;
					id = IdArr[i];

					DsmAs.Add(Row.Aspie, id, score);
					DsmAdd.Add(Row.ADHD, id, score);
					DsmSocialPhobia.Add(Row.Social, id, score);
				}
			}
		}

		for (i = 0; i < DX_COUNT; i++)
			DxArr[i] = DX_STATE_UNKNOWN;

		if (Row.Aspie == 2)
			DxArr[DX_AS] = DX_STATE_YES;

		if (Row.Aspie == 1)
			DxArr[DX_AS] = DX_STATE_SELF;

		if (Row.Aspie == 0)
			DxArr[DX_AS] = DX_STATE_NO;

		if (Row.ADHD == 2)
			DxArr[DX_ADD] = DX_STATE_YES;

		if (Row.ADHD == 1)
			DxArr[DX_ADD] = DX_STATE_SELF;

		if (Row.ADHD == 0)
			DxArr[DX_ADD] = DX_STATE_NO;

		if (Row.OCD == 2)
			DxArr[DX_OCD] = DX_STATE_YES;

		if (Row.OCD == 1)
			DxArr[DX_OCD] = DX_STATE_SELF;

		if (Row.OCD == 0)
			DxArr[DX_OCD] = DX_STATE_NO;

		if (Row.Social == 2)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_YES;

		if (Row.Social == 1)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_SELF;

		if (Row.Social == 0)
			DxArr[DX_SOCIAL_PHOBIA] = DX_STATE_NO;

		All.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

		if (Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

			if (Row.Gender == 1)
			{
				if (Row.BirthYear > 1986)
					YoungMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

				AsMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			}
			else
			{
				if (Row.BirthYear > 1986)
					YoungFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

				AsFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			}

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

			if (Row.Aspie == 1)
				AspieControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}

		if (Row.ADHD >= 2)
		{
			Add.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}

		if (Row.Social >= 2)
			SocialPhobia.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

		if (Row.OCD >= 2)
			OCD.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}
		else
		{
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
				NtControl.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
		}

	}
}

/*##########################################################################
#
#   Name       : TQuizFinal::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal::SetupCross()
{
    int i;

    for (i = 0; i < 150; i++)
	    DefineGlobalId(i, i);
}

/*##########################################################################
#
#   Name       : TQuizFinal::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizFinal::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuizRow Row;
	char DxArr[DX_COUNT];
	int g;
	char GroupResult[ACTIVE_GROUP_COUNT];
	char DxResult[DX_COUNT];

	for (g = 0; g < ACTIVE_GROUP_COUNT; g++)
		GroupResult[g] = 0;

	for (g = 0; g < DX_COUNT; g++)
		DxResult[g] = 0;

	for (i = 0; i < DX_COUNT; i++)
		DxArr[DX_COUNT] = DX_STATE_UNKNOWN;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
			pop->Add(Row.AsResult, Row.NtResult, DxArr, Row.Gender, Row.Quiz, GroupResult, DxResult);
}

/*##################  IsPca ##########################
*   Purpose....: Check quiz row against pca-type                 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static int IsPca(TQuizRow *row, int PcaType)
{
    switch (PcaType)
	{
		case PCA_TYPE_ALL:
		case PCA_TYPE_MIXED:
            return TRUE;

		case PCA_TYPE_MALE:
			if (row->Gender == 1)
                return TRUE;
			else
                return FALSE;

        case PCA_TYPE_FEMALE:
			if (row->Gender == 2)
				return TRUE;
			else
                return FALSE;

        case PCA_TYPE_YOUNG:
			if (row->BirthYear >= 1975)
				return TRUE;
			else
				return FALSE;

		case PCA_TYPE_OLD:
			if (row->BirthYear < 1975)
				return TRUE;
			else
				return FALSE;

		case PCA_TYPE_AS:
				if (row->Aspie == 2)
				return TRUE;
			else
                return FALSE;

    }
	return FALSE;
}

/*##################  TQuizFinal::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal::ExportExcelCase(const char *filename, int PcaType)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < GetQuizN(); i++)
	{
		if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
		{
			file.Write("\"");

//  	      strncpy(str, Quiz[i].Text, 35);
//      	  str[35] = 0;
			sprintf(str, "#%d", i + 1);
			file.Write(str);

			file.Write("\"");
			if (i != N - 1)
				file.Write(", ");
		}
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (IsPca(&Row, PcaType))
		{
			sprintf(str, "\"%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < GetQuizN(); i++)
			{
				if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
				{
    				ival = Row.Quiz[i];
	    			if (ival)
						ival--;
    
					if (ival > 2)
						ival = 0;
                    
					sprintf(str, "%d", ival);
					file.Write(str);
					if (i != GetQuizN() - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizFinal::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal::ExportExcelAspie(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < N; i++)
	{
		file.Write("\"");

		sprintf(str, "#%d", i + 1);
		file.Write(str);

		file.Write("\"");
		if (i != N - 1)
			file.Write(", ");
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
			sprintf(str, "\"%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < N; i++)
			{
				ival = Row.Quiz[i];

				if (ival)
				{
					if (Quiz[i].Reverse)
						ival = GetCatCount(i) - ival;
					else
						ival--;
				}


				if (ival >= GetCatCount(i))
					ival = 0;

				sprintf(str, "%d", ival);
				file.Write(str);
				if (i != N - 1)
					file.Write(", ");
			}
			file.Write("\n");
	}
}

/*##################  TQuizFinal::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal::ExportExcelGroups(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	int group;
	int ok;
	char str[80];
	TFile file(filename, 0);
	int GroupSum[GROUP_COUNT];
	int GroupCount[GROUP_COUNT];

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < GROUP_COUNT; i++)
	{
		file.Write("\"");

		strncpy(str, Group[i].PosName, 35);
		str[35] = 0;
//        sprintf(str, "#%d", i + 1);
		file.Write(str);

		file.Write("\"");
		if (i != GROUP_COUNT - 1)
			file.Write(", ");
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		for (i = 0; i < GROUP_COUNT; i++)
		{
			GroupSum[i] = 0;
			GroupCount[i] = 0;
		}

		for (i = 0; i < GetQuizN(); i++)
		{
			ival = Row.Quiz[i];

			if (ival)
			{
				if (Quiz[i].Reverse)
					ival = 3 - ival;
				else
					ival--;
				group = Quiz[i].MyGroup;
				GroupSum[group] += ival;
				GroupCount[group]++;
			}
		}

		ok = TRUE;
		for (i = 0; i < GROUP_COUNT; i++)
			if (GroupCount[i] == 0)
				ok = FALSE;

		if (ok)
		{
			sprintf(str, "\%d\", ", Row.AsResult);
			file.Write(str);

				sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < GROUP_COUNT; i++)
			{
				ival = round(100.0 * (long double)GroupSum[i] / (long double)GroupCount[i]);
				sprintf(str, "\"%d\"", ival);
				file.Write(str);
				if (i != GROUP_COUNT - 1)
					file.Write(", ");
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizFinal::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal::ImportMvsp(const char *filename, int PcaType)
{
	char buf[MAX_IN_ROW];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	int i;
	long double d1, d2, d3, d4;
	int q;
	int count;
	TFile infile(filename);

	while (size = infile.Read(buf, MAX_IN_ROW))
	{
		buf[size] = 0;
		rowstr = strstr(buf, "#");
		if (rowstr)
		{
			rowstr++;
			ptr = strstr(rowstr, "\r");
			if (ptr)
				 *ptr = 0;
			else
				 rowstr = 0;
		}

		pos += strlen(buf) + 1;
		infile.SetPos(pos);

		if (rowstr)
		{
			for (i = 0; i < strlen(rowstr); i++)
			{
				switch (rowstr[i])
				{
					case ',':
						rowstr[i] = '.';
						break;

					case 0x9:
					case 0xd:
						rowstr[i] = ' ';
						break;
				}
			}

			if (sscanf(rowstr, "%d %Lf %Lf %Lf %Lf", &q, &d1, &d2, &d3, &d4) == 5)
			{
				if (PcaType != PCA_TYPE_MIXED)
				{
					if (PcaType == PCA_TYPE_ALL || PcaType == PCA_TYPE_MALE)
						d2 = -d2;

					if (PcaType == PCA_TYPE_ALL)
						d3 = -d3;

//					if (PcaType == PCA_TYPE_ALL)
//						d4 = -d4;

//					if (d1 > 0 && d2 > 0)
//					{
//						if (d1 > d2)
//						{
//							d1 = d1 - d2;
//							d2 = 0;
//						}
//						else
//						{
//							d2 = d2 - d1;
//							d1 = 0;
//						}
//					}
				}

				switch (PcaType)
				{
					case PCA_TYPE_ALL:
						Quiz[q - 1].Pca[0] = d1;
						Quiz[q - 1].Pca[1] = d2;
						Quiz[q - 1].Pca[2] = d3;
						Quiz[q - 1].Pca[3] = d4;
						break;

					case PCA_TYPE_MALE:
						Quiz[q - 1].MalePca[0] = d1;
						Quiz[q - 1].MalePca[1] = d2;
						Quiz[q - 1].MalePca[2] = d3;
						Quiz[q - 1].MalePca[3] = d4;
						break;

					case PCA_TYPE_FEMALE:
						Quiz[q - 1].FemalePca[0] = d1;
						Quiz[q - 1].FemalePca[1] = d2;
						Quiz[q - 1].FemalePca[2] = d3;
						Quiz[q - 1].FemalePca[3] = d4;
						break;

					case PCA_TYPE_YOUNG:
						Quiz[q - 1].YoungPca[0] = d1;
						Quiz[q - 1].YoungPca[1] = d2;
						Quiz[q - 1].YoungPca[2] = d3;
						Quiz[q - 1].YoungPca[3] = d4;
						break;

					case PCA_TYPE_OLD:
						Quiz[q - 1].OldPca[0] = d1;
						Quiz[q - 1].OldPca[1] = d2;
						Quiz[q - 1].OldPca[2] = d3;
						Quiz[q - 1].OldPca[3] = d4;
						break;

					case PCA_TYPE_ASIA:
						Quiz[q - 1].AsiaPca[0] = d1;
						Quiz[q - 1].AsiaPca[1] = d2;
						Quiz[q - 1].AsiaPca[2] = d3;
						Quiz[q - 1].AsiaPca[3] = d4;
						break;

					case PCA_TYPE_AS:
						Quiz[q - 1].AsPca[0] = d1;
						Quiz[q - 1].AsPca[1] = d2;
						Quiz[q - 1].AsPca[2] = d3;
						Quiz[q - 1].AsPca[3] = d4;
						break;

					case PCA_TYPE_MIXED:
						Quiz[q - 1].MixedPca[0] = d1;
						Quiz[q - 1].MixedPca[1] = d2;
						Quiz[q - 1].MixedPca[2] = d3;
						Quiz[q - 1].MixedPca[3] = d4;
						break;
				}
			}
		}
	}
}

/*##################  round ##########################
*   Purpose....: round long double to int       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int round(long double val)
{
	return (int)(val + 0.5);
}

/*##################  WriteCenteredFieldHeader ##########################
*   Purpose....: Write centered field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteCenteredFieldHeader(TFile &File, int RelWidth)
{
	char str[80];

	sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
	File.Write(str);

	File.Write("<p align=\"center\">\n");
	File.Write("<b>\n");
}

/*##################  WriteFieldFooter ##########################
*   Purpose....: Write field footer for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteFieldFooter(TFile &File)
{
	File.Write("\n</b>\n");
	File.Write("</p>\n");

	File.Write("</td>\n");
}

/*##################  TRace::TRace ##########################
*   Purpose....: Initialize TRace                 			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TRace::TRace()
{
	int i;

	for (i = 0; i < 10; i++)
	{
		UsCount[i] = 0;
		UsAsCount[i] = 0;
		AllCount[i] = 0;
		AllAsCount[i] = 0;
	}
}

/*##################  TRace::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::Add(TQuizRow *Row)
{
	int index;
	int diff = Row->AsResult - Row->NtResult;

	index = 3;
	    
	if (Row->Ancestry == 5)
		index = 0;      // african american

	if (Row->Ancestry >= 1000 && Row->Ancestry < 2000)
		index = 0;      // black african

	if ((Row->Ancestry >= 2000 && Row->Ancestry < 3000) || Row->Ancestry == 3205)
		index = 1;      // white

	if (Row->Ancestry >= 4000)
		index = 2;      // asian

	AllCount[index]++;

	if (diff >= 35)
		AllAsCount[index]++;

	if (Row->Country == 7302)
	{
	    index = 5;
	    
		if (Row->Ancestry == 3)
			index = 0;      // american indian

		if (Row->Ancestry == 5)
			index = 1;

		if (Row->Ancestry >= 1000 && Row->Ancestry < 2000)
			index = 1;

		if (Row->Ancestry == 6)
			index = 2;      // hispanic

		if ((Row->Ancestry >= 2000 && Row->Ancestry < 3000) || Row->Ancestry == 3205)
			index = 3;      // white

		if (Row->Ancestry >= 4000)
			index = 4;      // asian

		UsCount[index]++;

		if (diff >= 35)
			UsAsCount[index]++;
	}

}

/*##################  TRace::WriteHeader ##########################
*   Purpose....: Write header in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteHeader(TFile &file)
{
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Race");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("All");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Aspie");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Interest");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("AS proportion");
	WriteFieldFooter(file);

	file.Write("</tr>");
}

/*##################  TRace::WriteEntry ##########################
*   Purpose....: Write entry in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteEntry(TFile &file, int val, int count)
{
	 char str[80];
	 long double dev;
	long double sd;
	 long double mean;
	 long double r;
	 long double rsum;
	int ival;

	 WriteCenteredFieldHeader(file, 12);

#ifdef CI

	 mean = (long double)val / (long double)count;

	 r = 1.0 - mean;
	 rsum = (long double)val * r * r;

	 r = -mean;
	 rsum += (long double)(count - val) * r * r;

	 if (count > 1 && val)
	 {
		sd = sqrt(rsum / ((long double)count - 1));

		dev = 1.96 * sd / sqrt(count);

		r = mean - dev;
		if (r < 0.0)
			r = 0.0;

		ival = round(1000.0 * r);

		sprintf(str, "%d.%01d", ival / 10, ival % 10);
		file.Write(str);

		r = mean + dev;
		if (r > 1.0)
			r = 1.0;

		ival = round(1000.0 * r);

		sprintf(str, "-%d.%01d%", ival / 10, ival % 10);
		 file.Write(str);
	}
	else
		file.Write("---");

#else
	 ival = val * 1000 / count;
	 sprintf(str, "%d.%01d%", ival / 10, ival % 10);
	 file.Write(str);
#endif

	WriteFieldFooter(file);
}

/*##################  TRace::WriteUsRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteUsRow(TFile &file, int index, const char *text)
{
	 char str[80];
	 int sum;
	 int i;

	file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
	 file.Write(text);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", UsCount[index]);
	 file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", UsAsCount[index]);
	 file.Write(str);
	WriteFieldFooter(file);

	 sum = 0;
	for (i = 0; i < 10; i++)
		  sum += UsCount[i];

	 if (sum)
	 {
		  WriteEntry(file, UsCount[index], sum);

		if (UsCount[index])
				WriteEntry(file, UsAsCount[index], UsCount[index]);
	 }
	else
		 file.Write("---");

	 file.Write("</tr>");
}

/*##################  TRace::WriteAllRow ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TRace::WriteAllRow(TFile &file, int index, const char *text)
{
	 char str[80];
	 int sum;
	 int i;

	file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
	 file.Write(text);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", AllCount[index]);
	file.Write(str);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	sprintf(str, "%d", AllAsCount[index]);
	file.Write(str);
	WriteFieldFooter(file);

	sum = 0;
	for (i = 0; i < 10; i++)
		sum += AllCount[i];

	if (sum)
	{
		WriteEntry(file, AllCount[index], sum);

		if (AllCount[index])
			WriteEntry(file, AllAsCount[index], AllCount[index]);
	}
	else
		file.Write("---");

	file.Write("</tr>");
}


/*##################  TQuizFinal::WriteRace ##########################
*   Purpose....: Write race report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizFinal::WriteRace(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	TRace race;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		race.Add(&Row);

	file.Write("<h2>US population</h2>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	TRace::WriteHeader(file);

	race.WriteUsRow(file, 0, "Native American");
	race.WriteUsRow(file, 1, "Black African");
	race.WriteUsRow(file, 2, "Hispanic");
	race.WriteUsRow(file, 3, "Caucasian");
	race.WriteUsRow(file, 4, "Asian");
	race.WriteUsRow(file, 5, "Other");

	file.Write("</table>");

	file.Write("<br><br>");

	file.Write("<h2>Total population</h2>");

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	TRace::WriteHeader(file);

	race.WriteAllRow(file, 0, "African");
	race.WriteAllRow(file, 1, "Caucasian");
	race.WriteAllRow(file, 2, "Asian");
	race.WriteAllRow(file, 3, "Other");

	file.Write("</table>");
}
