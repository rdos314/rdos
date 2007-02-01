/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# quizr1.cpp
# Quiz R1 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizr1.h"
#include "file.h"
#include "quizdbr1.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizR1::TQuizR1
#
#   Purpose....: Constructor for TQuizR1
#
#   In params..: Filename to load quiz 9 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR1::TQuizR1(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9)
  : TQuiz(133),
	FDataFile(FileName)
{
	DefineCross(0, QuizI);
	DefineCross(1, QuizII);
	DefineCross(2, QuizIII);
	DefineCross(3, QuizNd);
	DefineCross(4, Quiz5);
	DefineCross(5, Quiz6);
	DefineCross(6, Quiz7);
	DefineCross(7, Quiz8);
	DefineCross(8, Quiz9);

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	LoadPopulations();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9);
//	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizR1::~TQuizR1
#
#   Purpose....: Destructor for TQuizR1
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR1::~TQuizR1()
{
}

/*##################  TQuizR1::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizR1::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuizR1::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::WriteName(TFile &File)
{
	 File.Write("R1");
}

/*##################  TQuizR1::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR1::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizR1::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::SetupTexts()
{
  Quiz[14].Reverse = TRUE;
  Quiz[15].Reverse = TRUE;
  Quiz[16].Reverse = TRUE;
  Quiz[17].Reverse = TRUE;
  Quiz[18].Reverse = TRUE;
  Quiz[20].Reverse = TRUE;
  Quiz[21].Reverse = TRUE;
  Quiz[38].Reverse = TRUE;
  Quiz[40].Reverse = TRUE;
  Quiz[41].Reverse = TRUE;
  Quiz[42].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[1].MyGroup = GROUP_MIXED;
  Quiz[2].MyGroup = GROUP_MIXED;
  Quiz[3].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[4].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[5].MyGroup = GROUP_EMOTION;
  Quiz[6].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[7].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[8].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[9].MyGroup = GROUP_EMOTION;
  Quiz[10].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[11].MyGroup = GROUP_MIXED;
  Quiz[12].MyGroup = GROUP_EMOTION;
  Quiz[13].MyGroup = GROUP_MIXED;
  Quiz[14].MyGroup = GROUP_NT_SOCIAL;
  Quiz[15].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[16].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[17].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[18].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[19].MyGroup = GROUP_NT_SOCIAL;
  Quiz[20].MyGroup = GROUP_NONVERBAL;
  Quiz[21].MyGroup = GROUP_NONVERBAL;
  Quiz[22].MyGroup = GROUP_MIXED;
  Quiz[23].MyGroup = GROUP_MIXED;
  Quiz[24].MyGroup = GROUP_NONVERBAL;
  Quiz[25].MyGroup = GROUP_MIXED;
  Quiz[26].MyGroup = GROUP_NONVERBAL;
  Quiz[27].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[28].MyGroup = GROUP_MIXED;
  Quiz[29].MyGroup = GROUP_NONVERBAL;
  Quiz[30].MyGroup = GROUP_MIXED;
  Quiz[31].MyGroup = GROUP_MIXED;
  Quiz[32].MyGroup = GROUP_MIXED;
  Quiz[33].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[34].MyGroup = GROUP_NONVERBAL;
  Quiz[35].MyGroup = GROUP_NONVERBAL;
  Quiz[36].MyGroup = GROUP_MIXED;
  Quiz[37].MyGroup = GROUP_MIXED;
  Quiz[38].MyGroup = GROUP_NONVERBAL;
  Quiz[39].MyGroup = GROUP_MIXED;
  Quiz[40].MyGroup = GROUP_NONVERBAL;
  Quiz[41].MyGroup = GROUP_NT_SOCIAL;
  Quiz[41].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[42].MyGroup = GROUP_MIXED;
  Quiz[43].MyGroup = GROUP_MIXED;
  Quiz[44].MyGroup = GROUP_MIXED;
  Quiz[46].MyGroup = GROUP_MIXED;
  Quiz[47].MyGroup = GROUP_MIXED;
  Quiz[48].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[49].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[50].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[51].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[52].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[53].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[54].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[55].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[56].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[57].MyGroup = GROUP_MIXED;
  Quiz[58].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[59].MyGroup = GROUP_REPETITION;
  Quiz[60].MyGroup = GROUP_REPETITION;
  Quiz[61].MyGroup = GROUP_MIXED;
  Quiz[62].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[63].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[64].MyGroup = GROUP_MIXED;
  Quiz[65].MyGroup = GROUP_REPETITION;
  Quiz[66].MyGroup = GROUP_REPETITION;
  Quiz[67].MyGroup = GROUP_EMOTION;
  Quiz[68].MyGroup = GROUP_REPETITION;
  Quiz[69].MyGroup = GROUP_REPETITION;
  Quiz[70].MyGroup = GROUP_REPETITION;
  Quiz[71].MyGroup = GROUP_REPETITION;
  Quiz[72].MyGroup = GROUP_MIXED;
  Quiz[73].MyGroup = GROUP_REPETITION;
  Quiz[74].MyGroup = GROUP_MIXED;
  Quiz[75].MyGroup = GROUP_MIXED;
  Quiz[76].MyGroup = GROUP_MIXED;
  Quiz[77].MyGroup = GROUP_MIXED;
  Quiz[78].MyGroup = GROUP_MIXED;
  Quiz[79].MyGroup = GROUP_MIXED;
  Quiz[80].MyGroup = GROUP_MIXED;
  Quiz[81].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[82].MyGroup = GROUP_MIXED;
  Quiz[83].MyGroup = GROUP_EMOTION;
  Quiz[84].MyGroup = GROUP_EMOTION;
  Quiz[85].MyGroup = GROUP_NT_TALENT;
  Quiz[86].MyGroup = GROUP_MIXED;
  Quiz[87].MyGroup = GROUP_MIXED;
  Quiz[88].MyGroup = GROUP_MIXED;
  Quiz[89].MyGroup = GROUP_MIXED;
  Quiz[90].MyGroup = GROUP_MIXED;
  Quiz[91].MyGroup = GROUP_NONVERBAL;
  Quiz[92].MyGroup = GROUP_NONVERBAL;
  Quiz[93].MyGroup = GROUP_MIXED;
  Quiz[94].MyGroup = GROUP_MIXED;
  Quiz[95].MyGroup = GROUP_MIXED;
  Quiz[96].MyGroup = GROUP_MIXED;
  Quiz[97].MyGroup = GROUP_MIXED;
  Quiz[98].MyGroup = GROUP_MIXED;
  Quiz[99].MyGroup = GROUP_MIXED;
  Quiz[100].MyGroup = GROUP_MIXED;
  Quiz[101].MyGroup = GROUP_MIXED;
  Quiz[102].MyGroup = GROUP_MIXED;
  Quiz[103].MyGroup = GROUP_NONVERBAL;
  Quiz[104].MyGroup = GROUP_SENSORY;
  Quiz[105].MyGroup = GROUP_SENSORY;
  Quiz[106].MyGroup = GROUP_SENSORY;
  Quiz[107].MyGroup = GROUP_SENSORY;
  Quiz[108].MyGroup = GROUP_MIXED;
  Quiz[109].MyGroup = GROUP_MIXED;
  Quiz[110].MyGroup = GROUP_MIXED;
  Quiz[111].MyGroup = GROUP_SENSORY;
  Quiz[112].MyGroup = GROUP_SENSORY;
  Quiz[113].MyGroup = GROUP_MIXED;
  Quiz[114].MyGroup = GROUP_SENSORY;
  Quiz[115].MyGroup = GROUP_MIXED;
  Quiz[116].MyGroup = GROUP_SENSORY;
  Quiz[117].MyGroup = GROUP_SENSORY;
  Quiz[118].MyGroup = GROUP_MIXED;
  Quiz[119].MyGroup = GROUP_MIXED;
  Quiz[120].MyGroup = GROUP_MIXED;
  Quiz[121].MyGroup = GROUP_MIXED;
  Quiz[122].MyGroup = GROUP_MIXED;
  Quiz[123].MyGroup = GROUP_MIXED;
  Quiz[124].MyGroup = GROUP_MIXED;

  Quiz[125].MyGroup = GROUP_ASPIE_COMM;
  Quiz[126].MyGroup = GROUP_ASPIE_COMM;
  Quiz[127].MyGroup = GROUP_MIXED;
  Quiz[128].MyGroup = GROUP_MIXED;
  Quiz[129].MyGroup = GROUP_MIXED;
  Quiz[130].MyGroup = GROUP_MIXED;
  Quiz[131].MyGroup = GROUP_MIXED;
  Quiz[132].MyGroup = GROUP_MIXED;

#ifdef ENGLISH
  Quiz[0].Text = "Have you felt different from others for most of your life?";
  Quiz[1].Text = "Do you feel much younger inside than your biological age?";
  Quiz[2].Text = "Are you sometimes fearless in situations that can be dangerous?";
  Quiz[3].Text = "Are you more of an observer than one who participates in life?";
  Quiz[4].Text = "Have you had more difficulties than others of the same age when it comes to making friendships or getting into relationships?";
  Quiz[5].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  Quiz[6].Text = "Have you had a tendency to prefer the company of those older than yourself to that of your peers?";
  Quiz[7].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[8].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[9].Text = "Have you been bullied, abused or taken advantage of in various situations?";
  Quiz[10].Text = "Do you tend to feel nervous, shy, confused and/or like you don't fit in, in various social situations?";
  Quiz[11].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[12].Text = "Have you had the feeling of playing a game to pretend to be like people around you?";
  Quiz[13].Text = "Have you had difficulties fitting into expected gender stereotypes, perhaps having interests and behaviors that are atypical for your gender?";
  Quiz[14].Text = "Is a large social network important to you?";
  Quiz[15].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[16].Text = "Are you comfortable in social situations and with new people?";
  Quiz[17].Text = "Are you energised by being in the company of others?";
  Quiz[18].Text = "Do you enjoy team sport and group endeavours?";
  Quiz[19].Text = "Is your image and social identity a priority to you?";
  Quiz[20].Text = "Are you intuitive about what people need from you?";
  Quiz[21].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[22].Text = "Can you easily remember people's names when you meet new people?";
  Quiz[23].Text = "Is it difficult or tiresome for you to talk?";
  Quiz[24].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
  Quiz[25].Text = "Do you stutter when stressed?";
  Quiz[26].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[27].Text = "Do you find it easier to communicate online than in real life?";
  Quiz[28].Text = "Do you have a habit of repeating your own or others' last words (echolalia)?";
  Quiz[29].Text = "Do you have difficulties understanding idioms, figures of speech, parodies, allegories or irony?";
  Quiz[30].Text = "If asked to describe yourself, would you do so in a detached way, as if you were describing someone else?";
  Quiz[31].Text = "Do you tend to be more blunt and straightforward than others?";
  Quiz[32].Text = "Do you tend to say or do things that are considered socially inappropriate?";
  Quiz[33].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
  Quiz[34].Text = "Do you have difficulties interpreting body language and/or facial expressions and figuring out what people feel and want, unless they tell you?";
  Quiz[35].Text = "Are you usually unaware of social rules & boundaries unless they are specifically spelled out?";
  Quiz[36].Text = "Do people think you are smiling at the wrong occasion or not smiling when you are expected to?";
  Quiz[37].Text = "Do you have problems with eye-contact (e.g. preferring to avoid it, or staring ‘too much’)?";
  Quiz[38].Text = "Can you 'read between the lines'?";
  Quiz[39].Text = "Do you find it easy to describe your feelings?";
  Quiz[40].Text = "Do you know when you are expected to offer an apology?";
  Quiz[41].Text = "Do you talk to put others at ease even if you don't have anything special to convey?";
  Quiz[42].Text = "Are you good at small talk?";
  Quiz[43].Text = "Do you look younger than your biological age??";
  Quiz[44].Text = "Were you precocious as a child?";
  Quiz[45].Text = "Was your play more directed towards sorting, building or taking things apart than towards social games with other kids?";
  Quiz[46].Text = "Are you naturally nocturnal, i.e. do you tend to be most alert at night?";
  Quiz[47].Text = "Do you find the norms of hygiene too strict?";
  Quiz[48].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[49].Text = "Do you mostly prefer playing/working/doing things on your own - in your own way and at your own pace?";
  Quiz[50].Text = "Do you find yourself more attracted to things, ideas, music, computers, animals, buildings or vehicles than to people and social exchange?";
  Quiz[51].Text = "Are you very gifted in one or more areas?";
  Quiz[52].Text = "Do you have unconventional, often unique ways of solving problems?";
  Quiz[53].Text = "Do you hyperfocus on one interest at a time and become an expert on that subject?";
  Quiz[54].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[55].Text = "Do you have excellent vocabulary and/or a fascination with words?";
  Quiz[56].Text = "Did you learn to read on your own before you were taught in school?";
  Quiz[57].Text = "Are you fascinated by dates and/or numbers?";
  Quiz[58].Text = "Do you enjoy figuring out how things work?";
  Quiz[59].Text = "Are you punctual, conscientious and a perfectionist?";
  Quiz[60].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
  Quiz[61].Text = "Have you been called a ‘know-it-all’ because you feel compelled to correct people with accurate facts?";
  Quiz[62].Text = "Do you have keen sense of ethics and a tendency to stand up for your ideals and beliefs even if they are contrary to general consensus, or if it means social or economical disadvantages?";
  Quiz[63].Text = "Do you tend to get so absorbed in your projects that you forget everything else (e.g. eating, sleeping, taking a shower, other people)?";
  Quiz[64].Text = "Do you find it hard to multi-task or shift your attention rapidly from one thing to another and therefore need to finish one task before turning to the next?";
  Quiz[65].Text = "Do you have specific routines which you need to follow?";
  Quiz[66].Text = "Does it cause chaos in you if your plans, environment or daily routines suddenly get changed?";
  Quiz[67].Text = "Do you feel stress, panic or have a brain malfunction in unfamiliar or demanding situations?";
  Quiz[68].Text = "Do you have a need for symmetry, order and/or precision?";
  Quiz[69].Text = "Do you have strong attachments to certain objects?";
  Quiz[70].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
  Quiz[71].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[72].Text = "Before doing something or going somewhere, do you need to visualize the place you’re going to or rehearse possible scenarios in your mind so as to prepare yourself?";
  Quiz[73].Text = "Do you sometimes have a need for comfort items like a blanket, stuffed animals etc?";
  Quiz[74].Text = "Do you do any of the following when you’re thinking, restless or bored: pacing; bouncing leg or foot; tapping fingers, pen or other object; doodling; fiddling with object e.g clicking pen; chewing on something?";
  Quiz[75].Text = "Do you do any of the following when you're happy: singing, humming or whistling to yourself?";
  Quiz[76].Text = "Do you do any of the following when anxious: twisting hands or fingers; rubbing hands, arms or thighs; biting lip, cheek or tongue?";
  Quiz[77].Text = "Do you do any of the following when bored: cracking joints; picking skin or scabs; peeling skin flakes; picking nose; pulling hairs;  biting nails or fingertips; pulling cuticle?";
  Quiz[78].Text = "Do you do any of the following in order to calm yourself when excited, overwhelmed or overstimulated: rocking; flapping hands; tapping ears; pressing eyes?";
  Quiz[79].Text = "Do you do any of the following for fun: spin in circles; walk on toes; watch a spinning, blinking or glittering object?";
  Quiz[80].Text = "Do you self-harm, or have you done so in the past?";
  Quiz[81].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[82].Text = "Do you have poor concept of time?";
  Quiz[83].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[84].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[85].Text = "Are you easily distracted and/or bored?";
  Quiz[86].Text = "Do you find it hard to focus on or learn things you are not interested in?";
  Quiz[87].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[88].Text = "Do you tend to be hyperactive and restless?";
  Quiz[89].Text = "Do you tend to be impatient and impulsive, e.g. having trouble waiting for your turn?";
  Quiz[90].Text = "Do you have a hyperactive mind?";
  Quiz[91].Text = "Do you have problems recognizing faces (dysphagia)?";
  Quiz[92].Text = "Do you have an odd posture or gait?";
  Quiz[93].Text = "Do you have poor balance, e.g. difficulty riding a bicycle, skating, standing on one leg?";
  Quiz[94].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[95].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[96].Text = "Do you have problems with ball sports?";
  Quiz[97].Text = "Do you have difficulties with two-handed tasks, e.g. eating with knife & fork, knitting, typing or playing an instrument?";
  Quiz[98].Text = "Do you have difficulties with activities requiring manual dexterity and precision, e.g drawing, sewing, tying shoe-laces, fastening buttons and handling small objects?";
  Quiz[99].Text = "Do you have difficulty writing by hand (dysgraphia)?";
  Quiz[100].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands and a tendency to drop, spill or break things by mistake?";
  Quiz[101].Text = "Are you easily overexcited, stressed and overwhelmed by things like noise, crowds, clutter, patterns, flicker and movement?";
  Quiz[102].Text = "Do you have extra sensitive hearing?";
  Quiz[103].Text = "Do you have difficulties filtering out background noises when talking to someone?";
  Quiz[104].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[105].Text = "Do you have a very acute sense of taste?";
  Quiz[106].Text = "Do you have to be particular about what you eat and/or how it is combined on the plate in order to be able to eat?";
  Quiz[107].Text = "Do you have a very acute sense of smell?";
  Quiz[108].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[109].Text = "Do you have poor night vision?";
  Quiz[110].Text = "Do you have a well-developed sense of colour?";
  Quiz[111].Text = "Do you have (or have you had) a problem with squinting?";
  Quiz[112].Text = "Do you feel uncomfortable in fluorescent light?";
  Quiz[113].Text = "Are you sensitive to weather changes?";
  Quiz[114].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[115].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[116].Text = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
  Quiz[117].Text = "Are you fairly insensitive to physical pain, or even enjoy some types of pain?";
  Quiz[118].Text = "Do you enjoy snuggling with people you like?";
  Quiz[119].Text = "Do you find it easy to understand and sympathise with those who function very differently from yourself?";
  Quiz[120].Text = "Have you had or would you like to have a sex-change?";
  Quiz[121].Text = "Do you dislike shaking hands due to disliking the feel of skin-contact with others?";
  Quiz[122].Text = "Do you dislike shaking hands due to germophobia?";
  Quiz[123].Text = "Do you dislike shaking hands because handshakes feel unnatural?";
  Quiz[124].Text = "Do you dislike shaking hands for other reason?";

  Quiz[125].Text = "Do you talk to yourself?";
  Quiz[126].Text = "Do you have an urge to climb?";
  Quiz[127].Text = "Do you clap your hands when excited?";
  Quiz[128].Text = "Do you grind your teeth when stressed or anxious?";
  Quiz[129].Text = "Do you clench your fists when angry?";
  Quiz[130].Text = "Do you suck your thumb for comfort?";
  Quiz[131].Text = "Do you enjoy lying on the ground looking at the sky?";
  Quiz[132].Text = "Do you wobble your hand slightly to indicate so-so?";

#endif

#ifdef SWEDISH
  Quiz[0].Text = "Har du känt dig annorlunda största delen av ditt liv?";
  Quiz[1].Text = "Känner du dig mycket yngre än din biologiska ålder?";
  Quiz[2].Text = "Händer det att du är orädd i situationer som faktiskt kan vara farliga?";
  Quiz[3].Text = "Känner du dig mer som en observatör än som en deltagare i livet?";
  Quiz[4].Text = "Har du haft svårare än dina jämnåriga att få vänner eller partners?";
  Quiz[5].Text = "Föredrar du bara att umgås med folk du känner väl, och helst på tu man hand eller i en mindre grupp?";
  Quiz[6].Text = "Har du brukat föredra att umgås människor som är äldre eller mer erfarna än du själv framför jämnåriga?";
  Quiz[7].Text = "Brukar du blir väldigt trött av att umgås med folk och efteråt behöva vila ut ifred?";
  Quiz[8].Text = "Ogillar du när folk kommer och hälsar på utan att ha blivit inbjudna?";
  Quiz[9].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad i olika situationer?";
  Quiz[10].Text = "Brukar du bli nervös, blyg, förvirrad och/eller ha svårt att passa in i olika sociala situationer?";
  Quiz[11].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[12].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[13].Text = "Har du haft svårigheter att passa in i traditionella könsroller, kanske haft intressen och uppförande som är otypiska för ditt kön?";
  Quiz[14].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[15].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[16].Text = "Känner du dig hemma i sociala situationer med nya människor?";
  Quiz[17].Text = "Får du energi av att vara i sällskap med andra?";
  Quiz[18].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
  Quiz[19].Text = "Är din image och sociala identitet väldigt viktig för dig?";
  Quiz[20].Text = "Känner du intuitivt vad folk behöver från dig?";
  Quiz[21].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[22].Text = "Har du lätt att komma ihåg vad folk heter när du möter nya människor?";
  Quiz[23].Text = "Finner du det svårt eller tröttsamt att tala?";
  Quiz[24].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
  Quiz[25].Text = "Stammar du när du blir stressad?";
  Quiz[26].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[27].Text = "Tycker du att det är lättare att kommunicera via dator än i verkliga livet?";
  Quiz[28].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt (ekolali)?";
  Quiz[29].Text = "Har du svårt att förstå talesätt, allegorier, parodier, ironi och liknande?";
  Quiz[30].Text = "Om du blev ombedd att beskriva dig själv, skulle du då göra det på objektivt sätt, som om du beskrev någon annan?";
  Quiz[31].Text = "Brukar du vara mer rak och rättfram i din kommunikation än andra?";
  Quiz[32].Text = "Brukar du säga eller göra saker som anses socialt opassande?";
  Quiz[33].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
  Quiz[34].Text = "Brukar du ha svårt att tolka kroppsspråk och ansiktsuttryck och att förstå vad andra känner och vill om de inte säger det rakt ut?";
  Quiz[35].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[36].Text = "Brukar folk tycka att du ler vid fel tillfälle eller att du inte ler när du ‘borde’?";
  Quiz[37].Text = "Har du problem med ögonkontakt (t ex föredrar att undvika det, eller stirrar ‘för mycket’)?";
  Quiz[38].Text = "Kan du 'läsa mellan raderna'?";
  Quiz[39].Text = "Är det lätt för dig att beskriva dina känslor?";
  Quiz[40].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[41].Text = "Brukar du prata för att få andra att känna sig väl till mods även om du inte har nåt speciellt att berätta?";
  Quiz[42].Text = "Är du bra på kallprat?";
  Quiz[43].Text = "Ser du yngre ut än din biologiska ålder?";
  Quiz[44].Text = "Var du \"lillgammal\" som barn?";
  Quiz[45].Text = "Brukade dina lekar mer bestå i att sortera, bygga eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[46].Text = "Är du en nattmänniska, d.v.s. brukar du vara som piggast på kvällen/natten?";
  Quiz[47].Text = "Tycker du att normerna för hygien är för strikta?";
  Quiz[48].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[49].Text = "Brukar du föredra att leka/arbeta/göra saker själv - på ditt eget sätt och i din egen takt?";
  Quiz[50].Text = "Är du i grunden mer intresserad av saker, idéer, filmer, datorer, musik, djur, hus, fordon el dyl, än av människor och social samvaro?";
  Quiz[51].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
  Quiz[52].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
  Quiz[53].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[54].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[55].Text = "Har du utmärkt vokabulär och intresse för språk?";
  Quiz[56].Text = "Lärde du dig att läsa själv innan du började skolan?";
  Quiz[57].Text = "Är du fascinerad av datum och/eller siffror?";
  Quiz[58].Text = "Tycker du om att lista ut hur saker fungerar?";
  Quiz[59].Text = "Är du punktlig, noggrann och perfektionistisk?";
  Quiz[60].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
  Quiz[61].Text = "Har du blivit kallad ‘besserwisser’ för att du känner dig manad att korrigera andra med korrekta fakta?";
  Quiz[62].Text = "Har du hög moral och en tendens att hålla fast vid dina ideal, övertygelser och principer även om de går emot det rådande synsättet och kan vara till din nackdel, t ex socialt eller ekonomiskt?";
  Quiz[63].Text = "Brukar du bli så absorberad av dina projekt att du glömmer allting annat (äta, duscha, sova, andra människor etc.)?";
  Quiz[64].Text = "Har du svårt att göra flera saker samtidigt, snabbt skifta fokus från en sak till en annan och därför har behov av att få göra klart det du håller på med innan du kan ta itu med något annat?";
  Quiz[65].Text = "Har du vissa enkla, logiska rutiner som det känns bra att följa?";
  Quiz[66].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer eller rutiner?";
  Quiz[67].Text = "Brukar du bli stressad och få panik eller kortslutning i hjärnan i nya och kravfyllda situationer?";
  Quiz[68].Text = "Har du ett behov av symmerti, ordning och/eller precision?";
  Quiz[69].Text = "Är du exceptionellt fäst vid vissa saker?";
  Quiz[70].Text = "Har du behov av att sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
  Quiz[71].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[72].Text = "Innan du gör något eller åker någonstans, behöver du ha en inre bild av platsen eller mentalt öva på tänkbara scenarier för att förbereda dig?";
  Quiz[73].Text = "Har du ibland behov av gosefilt, kramdjur eller liknande?";
  Quiz[74].Text = "Brukar du göra något av följande när du tänker, är rastlös eller uttråkad: vanka; vippa foten eller benet; trumma med fingrarna, en penna eller annat objekt; kludda; klicka penna, pilla eller tugga på något?";
  Quiz[75].Text = "Brukar du göra något av följande när du är glad: sjunga, nynna eller vissla för dig själv?";
  Quiz[76].Text = "Brukar du göra något av följande när du är orolig: vrida dina händer eller fingar; gnugga händer, överarmar eller lår; bita dig i läppen, kinden eller tungan?";
  Quiz[77].Text = "Brukar du göra något av följande när du är uttråkad: knäcka leder; pila på huden; dra hudflagor; plocka sårskorpor; peta näsan; dra ut hårstrån; bita på naglarna eller fingertopparna; dra i nagelbanden?";
  Quiz[78].Text = "Brukar du göra något av följande för att lugna ner dig när du blivit upphetsad, stressad eller överstimulerad: gunga med överkroppen, flaxa med händerna, slå på öronen, pressa händerna mot ögonen?";
  Quiz[79].Text = "Brukar du göra något av följande för att det är roligt: snurra runt, runt; gå på tå; titta på ett snurrande, blinkande eller glittrande föremål?";
  Quiz[80].Text = "Brukar du ägna dig åt självskadande beteende, eller har du gjort det tidigare?";
  Quiz[81].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och fart?";
  Quiz[82].Text = "Har du dålig tidsuppfattning?";
  Quiz[83].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[84].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[85].Text = "Blir du lätt distraherad och/eller uttråkad?";
  Quiz[86].Text = "Har du svårt att koncenterera dig på eller lära dig saker du inte är intresserad av?";
  Quiz[87].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[88].Text = "Brukar du vara hyperaktiv och rastlös?";
  Quiz[89].Text = "Brukar du vara otålig och impulsiv och t ex ha svårt att vänta på din tur?";
  Quiz[90].Text = "Är du mentalt hyperaktiv?";
  Quiz[91].Text = "Har du svårt att känna igen ansikten?";
  Quiz[92].Text = "Har du ovanlig kroppshållning eller gångstil?";
  Quiz[93].Text = "Har du dåligt balanssinne, t ex svårt att cykla, åka skridskor, stå på ett ben?";
  Quiz[94].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[95].Text = "Har du svårt att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[96].Text = "Har du problem med med bollsporter?";
  Quiz[97].Text = "Har du svårt med aktiviteter där man använder båda händerna samtidigt, t ex äta med kniv & gaffel, sticka, skriva maskin eller spela ett instrument?";
  Quiz[98].Text = "Har du svårigheter med aktiviteter som kräver finmotorisk precision, t ex att rita, sy, knyta skosnören, knäppa knappar och hantera små föremål?";
  Quiz[99].Text = "Har du svårt att skriva för hand (dysgrafi)?";
  Quiz[100].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna och en tendens att tappa, spilla eller ha sönder saker av misstag?";
  Quiz[101].Text = "Blir du lätt överstimulerad och stressad av för mycket ljud, mönster, flimmer, oreda, trängsel och rörelse?";
  Quiz[102].Text = "Här du extra känslig hörsel?";
  Quiz[103].Text = "Har du svårt att filtrera bort bakgrundsljud när du talar med någon?";
  Quiz[104].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
  Quiz[105].Text = "Har du extra känsligt smaksinne?";
  Quiz[106].Text = "Måste du vara petig med vad du äter och/eller hur maten kombineras på tallriken för att kunna äta?";
  Quiz[107].Text = "Har du extra känsligt luktsinne?";
  Quiz[108].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[109].Text = "Har du dåligt mörkerseende?";
  Quiz[110].Text = "Har du välutvecklat färgseende?";
  Quiz[111].Text = "Har du (eller har du haft) problem med skelning?";
  Quiz[112].Text = "Är du känslig för lyrsrörsljus?";
  Quiz[113].Text = "Är du känslig för väderomslag?";
  Quiz[114].Text = "Pinas du av skavande sömmar och etiketter, kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[115].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller bett om det?";
  Quiz[116].Text = "Om någon tar i dig, föredrar du då hårdare tag framför lätt beröring?";
  Quiz[117].Text = "Är du okänslig för smärta eller till och med tycker om viss sorts smärta?";
  Quiz[118].Text = "Gillar du att mysa ihop med personer du tycker om?";
  Quiz[119].Text = "Har du lätt att förstå och känna sympati även för dem som fungerar väldigt annorlunda än du själv?";
  Quiz[120].Text = "Har du genomgått eller skulle du vilja genomgå ett könsbyte?";
  Quiz[121].Text = "Ogillar du att ta i hand pga att du inte gillar känslan av hudkontakt med andra?";
  Quiz[122].Text = "Ogillar du att ta i hand pga bacillskräck?";
  Quiz[123].Text = "Ogillar du att ta i hand för att handslag känns onaturligt?";
  Quiz[124].Text = "Ogillar du att ta i hand av annan orsak?";

  Quiz[125].Text = "Pratar du med dig själv?";
  Quiz[126].Text = "Har du ett behov av att klättra?";
  Quiz[127].Text = "Klappar du med händerna när du är upprymd?";
  Quiz[128].Text = "Gnisslar du med tänderna när du är stressad eller har ångest?";
  Quiz[129].Text = "Knyter du nävarna när du är arg?";
  Quiz[130].Text = "Suger du på tummen när du behöver tröst?";
  Quiz[131].Text = "Gillar du att ligga på marken och studera himlen?";
  Quiz[132].Text = "Brukar du vippa handen lite för att indikera \"sådär\"?";

#endif
}

/*##########################################################################
#
#   Name       : TQuizR1::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::InitReferers()
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
 }

/*##########################################################################
#
#   Name       : TQuizR1::UpdateReferer
#
#   Purpose....: Update a referer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::UpdateReferer(TReferer *ref, int AsResult, int NtResult)
{
	int diff;

	ref->Count++;
	ref->AsResult += AsResult;
	ref->NtResult += NtResult;

	diff = AsResult - NtResult;

	if (diff >= 35)
		ref->ResultAs++;
	else
	{
		if (diff <= -35)
			ref->ResultNt++;
		else
			ref->ResultMixed++;
	}
}

/*##################  TQuizR1::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR1::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult);

		if (Row.Autism == 1 || Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult);

		if (Row.ADHD == 1)
			UpdateReferer(&SelfAddRef, Row.AsResult, Row.NtResult);

		if (Row.Aspie == 2 || Row.Autism == 2)
			UpdateReferer(&DxAsRef, Row.AsResult, Row.NtResult);

		if (Row.ADHD == 2)
			UpdateReferer(&DxAddRef, Row.AsResult, Row.NtResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.Gender == 1)
				UpdateReferer(&MaleAsRef, Row.AsResult, Row.NtResult);
			else
				UpdateReferer(&FemaleAsRef, Row.AsResult, Row.NtResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizR1::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::LoadPopulations()
{
	TQuizRow Row;
	int i;
	TReferer *ref;
	int aspie;

	for (i = 0; i < N; i++)
		Quiz[i].NoAnswer = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;

		}

		aspie = FALSE;

		if (Row.Autism || Row.Aspie)
			aspie = TRUE;

		All.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

			if (Row.Gender == 1)
				AsMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AsFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

			if (Row.Autism == 2 || Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.ADHD)
		{
			Add.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizR1::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("rdos.net/sv");
	DefineNt("circvsmaximvs.com");
	DefineNt("panterachat.com");
	DefineNt("kaytastrophe.com");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuizR1::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9)
{
	DefineCross(Quiz9, 0, 51);
	DefineCross(QuizII, 1, 20);
	DefineGlobalId( 2, 486);
	DefineCross(QuizI, 3, 66);
	DefineCross(Quiz9, 4, 50);
	DefineCross(QuizI, 5, 33);
	DefineCross(QuizI, 6, 32);
	DefineCross(Quiz9, 7, 55);
	DefineCross(Quiz6, 8, 118);
	DefineCross(Quiz7, 9, 119);
	DefineCross(Quiz9, 10, 54);
	DefineGlobalId( 11, 487);
	DefineCross(Quiz8, 12, 64);
	DefineGlobalId( 13, 488);
	DefineCross(Quiz9, 14, 74);
	DefineCross(Quiz8, 15, 70);
	DefineCross(Quiz9, 16, 69);
	DefineCross(Quiz9, 17, 66);
	DefineCross(Quiz9, 18, 65);
	DefineGlobalId( 19, 489);
	DefineCross(Quiz6, 20, 35);
	DefineCross(Quiz9, 21, 100);
	DefineGlobalId( 22, 490);
	DefineCross(QuizI, 23, 13);
	DefineCross(Quiz9, 24, 105);
	DefineCross(Quiz8, 25, 8);
	DefineCross(Quiz9, 26, 98);
	DefineCross(Quiz9, 27, 59);
	DefineGlobalId( 28, 491);
	DefineCross(QuizIII, 29, 32);
	DefineGlobalId( 30, 492);
	DefineGlobalId( 31, 493);
	DefineGlobalId( 32, 494);
	DefineCross(Quiz9, 33, 64);
	DefineCross(QuizIII, 34, 25);
	DefineCross(Quiz7, 35, 75);
	DefineGlobalId( 36, 495);
	DefineGlobalId( 37, 496);
	DefineCross(Quiz9, 38, 102);
	DefineGlobalId( 39, 497);
	DefineCross(Quiz9, 40, 109);
	DefineCross(Quiz7, 41, 66);
	DefineCross(QuizNd, 42, 36);
	DefineCross(QuizI, 43, 41);
	DefineGlobalId( 44, 498);
	DefineGlobalId( 45, 499);
	DefineGlobalId( 46, 500);
	DefineCross(Quiz6, 47, 139);
	DefineCross(Quiz9, 48, 61);
	DefineCross(Quiz8, 49, 69);
	DefineCross(QuizI, 50, 68);
	DefineCross(Quiz9, 51, 35);
	DefineCross(Quiz9, 52, 30);
	DefineCross(Quiz9, 53, 31);
	DefineCross(Quiz9, 54, 34);
	DefineCross(Quiz9, 55, 36);
	DefineCross(Quiz7, 56, 143);
	DefineCross(Quiz7, 57, 117);
	DefineCross(Quiz9, 58, 37);
	DefineCross(QuizII, 59, 69);
	DefineCross(Quiz9, 60, 115);
	DefineGlobalId( 61, 501);
	DefineCross(QuizI, 62, 98);
	DefineCross(Quiz8, 63, 120);
	DefineCross(QuizI, 64, 26);
	DefineCross(Quiz9, 65, 117);
	DefineCross(Quiz9, 66, 110);
	DefineCross(Quiz7, 67, 83);
	DefineCross(Quiz9, 68, 118);
	DefineCross(Quiz9, 69, 116);
	DefineCross(Quiz9, 70, 114);
	DefineCross(Quiz9, 71, 112);
	DefineGlobalId( 72, 502);
	DefineCross(Quiz7, 73, 90);
	DefineGlobalId( 74, 503);
	DefineGlobalId( 75, 504);
	DefineGlobalId( 76, 505);
	DefineGlobalId( 77, 506);
	DefineGlobalId( 78, 507);
	DefineGlobalId( 79, 508);
	DefineGlobalId( 80, 509);
	DefineCross(Quiz9, 81, 11);
	DefineCross(Quiz7, 82, 122);
	DefineCross(QuizI, 83, 31);
	DefineCross(QuizI, 84, 30);
	DefineCross(QuizII, 85, 64);
	DefineGlobalId( 86, 510);
	DefineGlobalId( 87, 511);
	DefineGlobalId( 88, 512);
	DefineGlobalId( 89, 513);
	DefineGlobalId( 90, 514);
	DefineCross(Quiz6, 91, 36);
	DefineCross(Quiz6, 92, 31);
	DefineGlobalId( 93, 515);
	DefineGlobalId( 94, 516);
	DefineGlobalId( 95, 517);
	DefineGlobalId( 96, 518);
	DefineGlobalId( 97, 519);
	DefineGlobalId( 98, 520);
	DefineCross(Quiz8, 99, 25);
	DefineGlobalId( 100, 521);
	DefineCross(QuizNd, 101, 10);
	DefineGlobalId( 102, 522);
	DefineCross(Quiz9, 103, 106);
	DefineCross(Quiz8, 104, 3);
	DefineCross(Quiz9, 105, 21);
	DefineCross(QuizI, 106, 58);
	DefineCross(Quiz9, 107, 24);
	DefineGlobalId( 108, 523);
	DefineGlobalId( 109, 524);
	DefineGlobalId( 110, 525);
	DefineCross(Quiz9, 111, 20);
	DefineCross(Quiz9, 112, 26);
	DefineGlobalId( 113, 526);
	DefineCross(Quiz8, 114, 6);
	DefineGlobalId( 115, 527);
	DefineCross(Quiz9, 116, 27);
	DefineCross(Quiz9, 117, 29);
	DefineGlobalId( 118, 528);
	DefineGlobalId( 119, 529);
	DefineGlobalId( 120, 530);
	DefineGlobalId( 121, 531);
	DefineGlobalId( 122, 532);
	DefineGlobalId( 123, 533);
	DefineGlobalId( 124, 534);
	DefineCross(Quiz9, 125, 88);
	DefineCross(Quiz9, 126, 93);
	DefineGlobalId( 127, 535);
	DefineGlobalId( 128, 536);
	DefineGlobalId( 129, 537);
	DefineGlobalId( 130, 538);
	DefineGlobalId( 131, 539);
	DefineGlobalId( 132, 540);
}

/*##########################################################################
#
#   Name       : TQuizR1::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuizRow Row;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
			pop->Add(Row.AsResult, Row.NtResult, FALSE, Row.Quiz);
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
			if (row->BirthYear >= 1980)
                return TRUE;
			else
				return FALSE;

		case PCA_TYPE_OLD:
			if (row->BirthYear <= 1965)
                return TRUE;
			else
				return FALSE;

		case PCA_TYPE_AS:
				if (row->Autism == 2 || row->Aspie == 2)
				return TRUE;
			else
                return FALSE;

    }
	return FALSE;
}

/*##################  TQuizR1::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR1::ExportExcelCase(const char *filename, int PcaType)
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

			for (i = 0; i < N; i++)
			{
				if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
				{
					if (i >= 150)
					{
					    if (i >= 154)
						{
					        switch (Row.Quiz[i])
					        {
					            case 0:
					                ival = 1;
					                break;

					            case 1:
					            case 2:
					            case 3:
					            case 4:
					                ival = 0;
					                break;

					            case 5:
								case 6:
					            case 7:
					                ival = 1;
					                break;

					            case 8:
					            case 9:
					            case 10:
					            case 11:
					                ival = 2;
					                break;
					        }
						}
					    else
    						ival = Row.Quiz[i];    				    
						
				    }
				    else
				    {
    					ival = Row.Quiz[i];
	    				if (ival)
		    				ival--;
    
						if (ival > 2)
		    				ival = 0;
                    }
                    
					sprintf(str, "\"%d\"", ival);
					file.Write(str);
					if (i != N - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizR1::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR1::ExportExcelGroups(const char *filename)
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

		strncpy(str, Group[i].Name, 35);
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

		for (i = 0; i < N; i++)
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

/*##################  TQuizR1::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR1::ImportMvsp(const char *filename, int PcaType)
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
					if (PcaType == PCA_TYPE_ALL)
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
