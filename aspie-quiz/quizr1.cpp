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
  : TQuiz(129),
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
    return;

	DefineID(1, 269);
	DefineID(2, 112);

#ifdef ENGLISH
	DefineText(3, "Do you consider yourself emotionally sensitive?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(3, "Är du emotionellt sensitiv?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(4, 76, "Do you tend to express your feelings in unusual ways (e.g banging your head in the wall or not showing anything at all)?");
#endif

#ifdef SWEDISH
	RedefineText(4, 76, "Brukar du uttrycka dina känslor på ovanliga sätt (t ex banka huvudet i väggen eller inte visa något alls)?");
#endif

#ifdef ENGLISH
	RedefineText(5, 139, "Are you asexual (= uninterested in sex)?");
#endif

#ifdef SWEDISH
	RedefineText(5, 139, "Är du asexuell? (= ointresserad av sex)?");
#endif

	DefineID(6, 343);

#ifdef ENGLISH
	DefineText(7, "Are you sometimes fearless in situations that can be dangerous?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(7, "Händer det att du är orädd i situationer som faktiskt kan vara farliga?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(8, 67, "Are you more of an observer than one who participates in life?");
#endif

#ifdef SWEDISH
	RedefineText(8, 67, "Känner du dig mer som en observatör än som en deltagare i livet?");
#endif

#ifdef ENGLISH
	RedefineText(9, 91, "Have you had more difficulties than others of the same age when it comes to making friendships or getting into relationships?");
#endif

#ifdef SWEDISH
	RedefineText(9, 91, "Har du haft svårare än dina jämnåriga att få vänner eller partners?");
#endif

#ifdef ENGLISH
	RedefineText(10, 34, "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?");
#endif

#ifdef SWEDISH
	RedefineText(10, 34, "Föredrar du bara att umgås med folk du känner väl, och helst på tu man hand eller i en mindre grupp?");
#endif

#ifdef ENGLISH
	RedefineText(11, 33, "Have you had a tendency to prefer the company of those older than yourself to that of your peers?");
#endif

#ifdef SWEDISH
	RedefineText(11, 33, "Har du brukat föredra att umgås människor som är äldre eller mer erfarna än du själv framför jämnåriga?");
#endif

#ifdef ENGLISH
	RedefineText(12, 66, "Do you get very tired after socializing, and need to regenerate alone?");
#endif

#ifdef SWEDISH
	RedefineText(12, 66, "Brukar du blir väldigt trött av att umgås med folk och efteråt behöva vila ut ifred?");
#endif

#ifdef ENGLISH
	RedefineText(13, 378, "Do you dislike it when people drop by to visit you uninvited?");
#endif

#ifdef SWEDISH
	RedefineText(13, 378, "Ogillar du när folk kommer och hälsar på utan att ha blivit inbjudna?");
#endif

	DefineID(14, 93);

#ifdef ENGLISH
	RedefineText(15, 81, "Do you tend to feel nervous, shy, confused and/or like you don't fit in, in various social situations?");
#endif

#ifdef SWEDISH
	RedefineText(15, 81, "Brukar du bli nervös, blyg, förvirrad och/eller ha svårt att passa in i olika sociala situationer?");
#endif

#ifdef ENGLISH
	DefineText(16, "Do you find it difficult to figure out how to behave in various situations?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(16, "Är det svårt att veta hur du ska bete dig i olika situationer?", GROUP_MIXED);
#endif

	DefineID(17, 126);

#ifdef ENGLISH
	DefineText(18, "Have you had difficulties fitting into expected gender stereotypes, perhaps having interests and behaviors that are atypical for your gender?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(18, "Har du haft svårigheter att passa in i traditionella könsroller, kanske haft intressen och uppförande som är otypiska för ditt kön?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(19, 367, "Is a large social network important to you?");
#endif

#ifdef SWEDISH
	RedefineText(19, 367, "Är ett stort socialt nätverk viktigt för dig?");
#endif

	DefineID(20, 149);
	DefineID(21, 258);
	DefineID(22, 256);
	DefineID(23, 283);

#ifdef ENGLISH
	DefineText(24, "Is your image and social identity a priority to you", GROUP_NT_SOCIAL);
#endif

#ifdef SWEDISH
	DefineText(24, "Är din image och sociala identitet väldigt viktig för dig?", GROUP_NT_SOCIAL);
#endif

#ifdef ENGLISH
	RedefineText(25, 225, "Are you intuitive about what people need from you?");
#endif

#ifdef SWEDISH
	RedefineText(25, 225, "Känner du intuitivt vad folk behöver från dig?");
#endif

#ifdef ENGLISH
	RedefineText(26, 262, "Do you have a good sense for what is the right thing to do socially?");
#endif

#ifdef SWEDISH
	RedefineText(26, 262, "Har du en bra känla för vad som är rätt socialt?");
#endif

#ifdef ENGLISH
	DefineText(27, "Can you easily remember people's names when you meet new people?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(27, "Har du lätt att komma ihåg vad folk heter när du möter nya människor?", GROUP_MIXED);
#endif

	DefineID(28, 14);
	DefineID(29, 18);

#ifdef ENGLISH
	RedefineText(30, 234, "Do you stutter when stressed?");
#endif

#ifdef SWEDISH
	RedefineText(30, 234, "Stammar du när du blir stressad?");
#endif

	DefineID(31, 83);
	DefineID(32, 365);

#ifdef ENGLISH
	DefineText(33, "Do you have a habit of repeating your own or others' last words (echolalia)?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(33, "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt (ekolali)?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(34, 87, "Do you have difficulties understanding idioms, figures of speech, parodies, allegories or irony?");
#endif

#ifdef SWEDISH
	RedefineText(34, 87, "Har du svårt att förstå talesätt, allegorier, parodier, ironi och liknande?");
#endif

#ifdef ENGLISH
	DefineText(35, "If asked to describe yourself, would you do so in a detached way, as if you were describing someone else?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(35, "Om du blev ombedd att beskriva dig själv, skulle du då göra det på objektivt sätt, som om du beskrev någon annan?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(36, "Do you tend to be more blunt and straightforward than others?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(36, "Brukar du vara mer rak och rättfram i din kommunikation än andra?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(37, "Do you tend to say or do things that are considered socially inappropriate?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(37, "Brukar du säga eller göra saker som anses socialt opassande?", GROUP_MIXED);
#endif

	DefineID(38, 98);
	DefineID(39, 88);
	DefineID(40, 82);

#ifdef ENGLISH
	DefineText(41, "Do people think you are smiling at the wrong occasion or not smiling when you are expected to?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(41, "Brukar folk tycka att du ler vid fel tillfälle eller att du inte ler när du ‘borde’?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(42, "Do you have problems with eye-contact (e.g. preferring to avoid it, or staring ‘too much’)?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(42, "Har du problem med ögonkontakt (t ex föredrar att undvika det, eller stirrar ‘för mycket’)?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(43, 285, "Can you 'read between the lines'?");
#endif

#ifdef SWEDISH
	RedefineText(43, 285, "Kan du 'läsa mellan raderna'?");
#endif

#ifdef ENGLISH
	DefineText(44, "Do you find it easy to describe your feelings?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(44, "Är det lätt för dig att beskriva dina känslor?", GROUP_MIXED);
#endif

	DefineID(45, 128);

#ifdef ENGLISH
	RedefineText(46, 345, "Do you talk to put others at ease even if you don't have anything special to convey?");
#endif

#ifdef SWEDISH
	RedefineText(46, 345, "Brukar du prata för att få andra att känna sig väl till mods även om du inte har nåt speciellt att berätta?");
#endif

	DefineID(47, 218);
	DefineID(48, 42);

#ifdef ENGLISH
	DefineText(49, "Were you precocious as a child?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(49, "Var du \"lillgammal\" som barn?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(50, "Was your play more directed towards sorting, building or taking things apart than towards social games with other kids?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(50, "Brukade dina lekar mer bestå i att sortera, bygga eller ta isär saker än i sociala lekar med andra barn?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(51, "Are you naturally nocturnal, i.e. do you tend to be most alert at night?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(51, "Är du en nattmänniska, d.v.s. brukar du vara som piggast på kvällen/natten?", GROUP_MIXED);
#endif

	DefineID(52, 155);

#ifdef ENGLISH
	RedefineText(53, 151, "Is your sense of humor different from mainstream or considered odd?");
#endif

#ifdef SWEDISH
	RedefineText(53, 151, "Är ditt sinne för humor annorlunda än andras eller ansett som udda?");
#endif

#ifdef ENGLISH
	RedefineText(54, 71, "Do you mostly prefer playing/working/doing things on your own - in your own way and at your own pace?");
#endif

#ifdef SWEDISH
	RedefineText(54, 71, "Brukar du föredra att leka/arbeta/göra saker själv - på ditt eget sätt och i din egen takt?");
#endif

#ifdef ENGLISH
	RedefineText(55, 69, "Do you find yourself more attracted to things, ideas, music, computers, animals, buildings or vehicles than to people and social exchange?");
#endif

#ifdef SWEDISH
	RedefineText(55, 69, "Är du i grunden mer intresserad av saker, idéer, filmer, datorer, musik, djur, hus, fordon el dyl, än av människor och social samvaro?");
#endif

	DefineID(56, 19);
	DefineID(57, 23);

#ifdef ENGLISH
	RedefineText(58, 20, "Do you hyperfocus on one interest at a time and become an expert on that subject?");
#endif

#ifdef SWEDISH
	RedefineText(58, 20, "Brukar du fördjupa dig i ett ämne i taget och bli expert det?");
#endif

	DefineID(59, 5);
	DefineID(60, 13);

#ifdef ENGLISH
	RedefineText(61, 419, "Did you learn to read on your own before you were taught in school?");
#endif

#ifdef SWEDISH
	RedefineText(61, 419, "Lärde du dig att läsa själv innan du började skolan?");
#endif

	DefineID(62, 8);

#ifdef ENGLISH
	RedefineText(63, 141, "Do you enjoy figuring out how things work?");
#endif

#ifdef SWEDISH
	RedefineText(63, 141, "Tycker du om att lista ut hur saker fungerar?");
#endif

#ifdef ENGLISH
	RedefineText(64, 10, "Are you punctual, conscientious and a perfectionist?");
#endif

#ifdef SWEDISH
	RedefineText(64, 10, "Är du punktlig, noggrann och perfektionistisk?");
#endif

	DefineID(65, 22);

#ifdef ENGLISH
	DefineText(66, "Have you been called a ‘know-it-all’ because you feel compelled to correct people with accurate facts?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(66, "Har du blivit kallad ‘besserwisser’ för att du känner dig manad att korrigera andra med korrekta fakta?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(67, 99, "Do you have keen sense of ethics and a tendency to stand up for your ideals and beliefs even if they are contrary to general consensus, or if it means social or economical disadvantages?");
#endif

#ifdef SWEDISH
	RedefineText(67, 99, "Har du hög moral och en tendens att hålla fast vid dina ideal, övertygelser och principer även om de går emot det rådande synsättet och kan vara till din nackdel, t ex socialt eller ekonomiskt?");
#endif

#ifdef ENGLISH
	RedefineText(68, 26, "Do you tend to get so absorbed in your projects that you forget everything else (e.g. eating, sleeping, taking a shower, other people)?");
#endif

#ifdef SWEDISH
	RedefineText(68, 26, "Brukar du bli så absorberad av dina projekt att du glömmer allting annat (äta, duscha, sova, andra människor etc.)?");
#endif

#ifdef ENGLISH
	RedefineText(69, 27, "Do you find it hard to multi-task or shift your attention rapidly from one thing to another and therefore need to finish one task before turning to the next?");
#endif

#ifdef SWEDISH
	RedefineText(69, 27, "Har du svårt att göra flera saker samtidigt, snabbt skifta fokus från en sak till en annan och därför har behov av att få göra klart det du håller på med innan du kan ta itu med något annat?");
#endif

#ifdef ENGLISH
	RedefineText(70, 36, "Do you have certain simple & logical routines which you need to follow?");
#endif

#ifdef SWEDISH
	RedefineText(70, 36, "Har du vissa enkla, logiska rutiner som det känns bra att följa? (tog bort lite i mitten så de blev mer lika)?");
#endif

#ifdef ENGLISH
	RedefineText(71, 360, "Does it cause chaos in you if your plans, environment or daily routines suddenly get changed?");
#endif

#ifdef SWEDISH
	RedefineText(71, 360, "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer eller rutiner?");
#endif

#ifdef ENGLISH
	RedefineText(72, 28, "Do you feel stress, panic or have a brain malfunction in unfamiliar or demanding situations?");
#endif

#ifdef SWEDISH
	RedefineText(72, 28, "Brukar du bli stressad och få panik eller kortslutning i hjärnan i nya och kravfyllda situationer?");
#endif

	DefineID(73, 436);

#ifdef ENGLISH
	RedefineText(74, 39, "Do you have strong attachments to certain objects?");
#endif

#ifdef SWEDISH
	RedefineText(74, 39, "Är du exceptionellt fäst vid vissa saker?");
#endif

#ifdef ENGLISH
	RedefineText(75, 38, "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?");
#endif

#ifdef SWEDISH
	RedefineText(75, 38, "Har du behov av att sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?");
#endif

	DefineID(76, 37);

#ifdef ENGLISH
	DefineText(77, "Before doing something or going somewhere, do you need to visualize the place you’re going to or rehearse possible scenarios in your mind so as to prepare yourself?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(77, "Innan du gör något eller åker någonstans, behöver du ha en inre bild av platsen eller mentalt öva på tänkbara scenarier för att förbereda dig?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(78, 35, "Do you sometimes have a need for comfort items like a blanket, stuffed animals etc?");
#endif

#ifdef SWEDISH
	RedefineText(78, 35, "Har du ibland behov av gosefilt, kramdjur eller liknande?");
#endif

#ifdef ENGLISH
	DefineText(79, "Do you do any of the following when you’re thinking, restless or bored: pacing; bouncing leg or foot; tapping fingers, pen or other object; doodling; fiddling with object e.g clicking pen; chewing on something?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(79, "Brukar du göra något av följande när du tänker, är rastlös eller uttråkad: vanka; vippa foten eller benet; trumma med fingrarna, en penna eller annat objekt; kludda; klicka penna, pilla eller tugga på något?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(80, "Do you do any of the following when you're happy: singing, humming or whistling to yourself?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(80, "Brukar du göra något av följande när du är glad: sjunga, nynna eller vissla för dig själv?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(81, "Do you do any of the following when anxious: twisting hands or fingers; rubbing hands, arms or thighs; biting lip, cheek or tongue?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(81, "Brukar du göra något av följande när du är orolig: vrida dina händer eller fingar; gnugga händer, överarmar eller lår; bita dig i läppen, kinden eller tungan?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(82, "Do you do any of the following when bored: cracking joints; picking skin or scabs; peeling skin flakes; picking nose; pulling hairs;  biting nails or fingertips; pulling cuticle?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(82, "Brukar du göra något av följande när du är uttråkad: knäcka leder; pila på huden; dra hudflagor; plocka sårskorpor; peta näsan; dra ut hårstrån; bita på naglarna eller fingertopparna; dra i nagelbanden?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(83, "Do you do any of the following in order to calm yourself when excited, overwhelmed or overstimulated: rocking; flapping hands; tapping ears; pressing eyes?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(83, "Brukar du göra något av följande för att lugna ner dig när du blivit upphetsad, stressad eller överstimulerad: gunga med överkroppen, flaxa med händerna, slå på öronen, pressa händerna mot ögonen?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(84, "Do you do any of the following for fun: spin in circles; walk on toes; watch a spinning, blinking or glittering object?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(84, "Brukar du göra något av följande för att det är roligt: snurra runt, runt; gå på tå; titta på ett snurrande, blinkande eller glittrande föremål?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(85, "Do you self-harm, or have you done so in the past?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(85, "Brukar du ägna dig åt självskadande beteende, eller har du gjort det tidigare?", GROUP_MIXED);
#endif

	DefineID(86, 46);
	DefineID(87, 50);
	DefineID(88, 32);

#ifdef ENGLISH
	RedefineText(89, 31, "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?");
#endif

#ifdef SWEDISH
	RedefineText(89, 31, "Har du haft svårare att klara dig själv än andra i samma ålder?");
#endif

#ifdef ENGLISH
	RedefineText(90, 143, "Are you easily distracted and/or bored?");
#endif

#ifdef SWEDISH
	RedefineText(90, 143, "Blir du lätt distraherad och/eller uttråkad?");
#endif

#ifdef ENGLISH
	DefineText(91, "Do you find it hard to focus on or learn things you are not interested in?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(91, "Har du svårt att koncenterera dig på eller lära dig saker du inte är intresserad av?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(92, "Are you somewhat of a daydreamer, often lost in your own thoughts?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(92, "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(93, "Do you tend to be hyperactive and restless?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(93, "Brukar du vara hyperaktiv och rastlös?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(94, "Do you tend to be impatient and impulsive, e.g. having trouble waiting for your turn?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(94, "Brukar du vara otålig och impulsiv och t ex ha svårt att vänta på din tur?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(95, "Do you have a hyperactive mind?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(95, "Är du mentalt hyperaktiv?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(96, 89,  "Do you have problems recognizing faces (dysphagia)?");
#endif

#ifdef SWEDISH
	RedefineText(96, 89, "Har du svårt att känna igen ansikten?");
#endif

	DefineID(97, 359);

#ifdef ENGLISH
	DefineText(98, "Do you have poor balance, e.g. difficulty riding a bicycle, skating, standing on one leg?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(98, "Har du dåligt balanssinne, t ex svårt att cykla, åka skridskor, stå på ett ben?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(99, "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(99, "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(100, "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(100, "Har du svårt att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(101, "Do you have problems with ball sports?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(101, "Har du problem med med bollsporter?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(102, "Do you have difficulties with two-handed tasks, e.g. eating with knife & fork, knitting, typing or playing an instrument?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(102, "Har du svårt med aktiviteter där man använder båda händerna samtidigt, t ex äta med kniv & gaffel, sticka, skriva maskin eller spela ett instrument?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(103, "Do you have difficulties with activities requiring manual dexterity and precision, e.g drawing, sewing, tying shoe-laces, fastening buttons and handling small objects?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(103, "Har du svårigheter med aktiviteter som kräver finmotorisk precision, t ex att rita, sy, knyta skosnören, knäppa knappar och hantera små föremål?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(104, 416, "Do you have difficulty writing by hand (dysgraphia)?");
#endif

#ifdef SWEDISH
	RedefineText(104, 416, "Har du svårt att skriva för hand (dysgrafi)?");
#endif

#ifdef ENGLISH
	DefineText(105, "Do you have a poor sense of how much pressure to apply when doing things with your hands and a tendency to drop, spill or break things by mistake?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(105, "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna och en tendens att tappa, spilla eller ha sönder saker av misstag?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(106, 65, "Are you easily overexcited, stressed and overwhelmed by things like noise, crowds, clutter, patterns, flicker and movement?");
#endif

#ifdef SWEDISH
	RedefineText(106, 65, "Blir du lätt överstimulerad och stressad av för mycket ljud, mönster, flimmer, oreda, trängsel och rörelse?");
#endif

#ifdef ENGLISH
	DefineText(107, "Do you have extra sensitive hearing?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(107, "Här du extra känslig hörsel?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(108, 54, "Do you have difficulties filtering out background noises when talking to someone?");
#endif

#ifdef SWEDISH
	RedefineText(108, 54, "Har du svårt att filtrera bort bakgrundsljud när du talar med någon?");
#endif

	DefineID(109, 55);
	DefineID(110, 390);

#ifdef ENGLISH
	RedefineText(111, 59, "Do you have to be particular about what you eat and/or how it is combined on the plate in order to be able to eat?");
#endif

#ifdef SWEDISH
	RedefineText(111, 59, "Måste du vara petig med vad du äter och/eller hur maten kombineras på tallriken för att kunna äta?");
#endif

	DefineID(112, 389);

#ifdef ENGLISH
	DefineText(113, "Are your eyes extra sensitive to stong light and glare?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(113, "Är dina ögon extra känsliga för starkt ljus och bländning?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(114, "Do you have poor night vision?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(114, "Har du dåligt mörkerseende?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(115, "Do you have a well-developed sense of colour?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(115, "Har du välutvecklat färgseende?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(116, 178, "Do you have (or have you had) a problem with squinting?");
#endif

#ifdef SWEDISH
	RedefineText(116, 178, "Har du (eller har du haft) problem med skelning?");
#endif

	DefineID(117, 56);

#ifdef ENGLISH
	DefineText(118, "Are you sensitive to weather changes?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(118, "Är du känslig för väderomslag?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	RedefineText(119, 61, "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?");
#endif

#ifdef SWEDISH
	RedefineText(119, 61, "Pinas du av skavande sömmar och etiketter, kläder som sitter åt eller som är gjorda i 'fel' material?");
#endif

#ifdef ENGLISH
	DefineText(120, "Do you dislike being touched or hugged unless you're prepared or have asked for it?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(120, "Ogillar du att bli tagen i eller kramad om du inte är beredd eller bett om det?", GROUP_MIXED);
#endif

	DefineID(121, 63);

#ifdef ENGLISH
	RedefineText(122, 464, "Are you fairly insensitive to physical pain, or even enjoy some types of pain?");
#endif

#ifdef SWEDISH
	RedefineText(122, 464, "Är du okänslig för smärta eller till och med tycker om viss sorts smärta?");
#endif

#ifdef ENGLISH
	DefineText(123, "Do you enjoy snuggling with people you like?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(123, "Gillar du att mysa ihop med personer du tycker om?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(124, "Do you find it easy to understand and sympathise with those who function very differently from yourself?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(124, "Har du lätt att förstå och känna sympati även för dem som fungerar väldigt annorlunda än du själv?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(125, "Have you had or would you like to have a sex-change?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(125, "Har du genomgått eller skulle du vilja genomgå ett könsbyte?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(126, "Do you dislike shaking hands due to disliking the feel of skin-contact with others?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(126, "Ogillar du att ta i hand pga att du inte gillar känslan av hudkontakt med andra?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(127, "Do you dislike shaking hands due to germophobia?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(127, "Ogillar du att ta i hand pga bacillskräck?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(128, "Do you dislike shaking hands because handshakes feel unnatural?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(128, "Ogillar du att ta i hand för att handslag känns onaturligt?", GROUP_MIXED);
#endif

#ifdef ENGLISH
	DefineText(129, "Do you dislike shaking hands for other reason?", GROUP_MIXED);
#endif

#ifdef SWEDISH
	DefineText(129, "Ogillar du att ta i hand av annan orsak?", GROUP_MIXED);
#endif

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
  Quiz[18].Reverse = TRUE;
  Quiz[19].Reverse = TRUE;
  Quiz[20].Reverse = TRUE;
  Quiz[21].Reverse = TRUE;
  Quiz[22].Reverse = TRUE;
  Quiz[24].Reverse = TRUE;
  Quiz[25].Reverse = TRUE;
  Quiz[42].Reverse = TRUE;
  Quiz[44].Reverse = TRUE;
  Quiz[45].Reverse = TRUE;
  Quiz[46].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[1].MyGroup = GROUP_MIXED;
  Quiz[2].MyGroup = GROUP_MIXED;
  Quiz[3].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[4].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[5].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[6].MyGroup = GROUP_MIXED;
  Quiz[7].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[8].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[9].MyGroup = GROUP_EMOTION;
  Quiz[10].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[11].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[12].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[13].MyGroup = GROUP_EMOTION;
  Quiz[14].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[15].MyGroup = GROUP_MIXED;
  Quiz[16].MyGroup = GROUP_EMOTION;
  Quiz[17].MyGroup = GROUP_MIXED;
  Quiz[18].MyGroup = GROUP_NT_SOCIAL;
  Quiz[19].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[20].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[21].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[22].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[23].MyGroup = GROUP_NT_SOCIAL;
  Quiz[24].MyGroup = GROUP_NONVERBAL;
  Quiz[25].MyGroup = GROUP_NONVERBAL;
  Quiz[26].MyGroup = GROUP_MIXED;
  Quiz[27].MyGroup = GROUP_MIXED;
  Quiz[28].MyGroup = GROUP_NONVERBAL;
  Quiz[29].MyGroup = GROUP_MIXED;
  Quiz[30].MyGroup = GROUP_NONVERBAL;
  Quiz[31].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[32].MyGroup = GROUP_MIXED;
  Quiz[33].MyGroup = GROUP_NONVERBAL;
  Quiz[34].MyGroup = GROUP_MIXED;
  Quiz[35].MyGroup = GROUP_MIXED;
  Quiz[36].MyGroup = GROUP_MIXED;
  Quiz[37].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[38].MyGroup = GROUP_NONVERBAL;
  Quiz[39].MyGroup = GROUP_NONVERBAL;
  Quiz[40].MyGroup = GROUP_MIXED;
  Quiz[41].MyGroup = GROUP_MIXED;
  Quiz[42].MyGroup = GROUP_NONVERBAL;
  Quiz[43].MyGroup = GROUP_MIXED;
  Quiz[44].MyGroup = GROUP_NONVERBAL;
  Quiz[45].MyGroup = GROUP_NT_SOCIAL;
  Quiz[46].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[47].MyGroup = GROUP_MIXED;
  Quiz[48].MyGroup = GROUP_MIXED;
  Quiz[49].MyGroup = GROUP_MIXED;
  Quiz[50].MyGroup = GROUP_MIXED;
  Quiz[51].MyGroup = GROUP_MIXED;
  Quiz[52].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[53].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[54].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[55].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[56].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[57].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[58].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[59].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[60].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[61].MyGroup = GROUP_MIXED;
  Quiz[62].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[63].MyGroup = GROUP_REPETITION;
  Quiz[64].MyGroup = GROUP_REPETITION;
  Quiz[65].MyGroup = GROUP_MIXED;
  Quiz[66].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[67].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[68].MyGroup = GROUP_MIXED;
  Quiz[69].MyGroup = GROUP_REPETITION;
  Quiz[70].MyGroup = GROUP_REPETITION;
  Quiz[71].MyGroup = GROUP_EMOTION;
  Quiz[72].MyGroup = GROUP_REPETITION;
  Quiz[73].MyGroup = GROUP_REPETITION;
  Quiz[74].MyGroup = GROUP_REPETITION;
  Quiz[75].MyGroup = GROUP_REPETITION;
  Quiz[76].MyGroup = GROUP_MIXED;
  Quiz[77].MyGroup = GROUP_REPETITION;
  Quiz[78].MyGroup = GROUP_MIXED;
  Quiz[79].MyGroup = GROUP_MIXED;
  Quiz[80].MyGroup = GROUP_MIXED;
  Quiz[81].MyGroup = GROUP_MIXED;
  Quiz[82].MyGroup = GROUP_MIXED;
  Quiz[83].MyGroup = GROUP_MIXED;
  Quiz[84].MyGroup = GROUP_MIXED;
  Quiz[85].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[86].MyGroup = GROUP_MIXED;
  Quiz[87].MyGroup = GROUP_EMOTION;
  Quiz[88].MyGroup = GROUP_EMOTION;
  Quiz[89].MyGroup = GROUP_NT_TALENT;
  Quiz[90].MyGroup = GROUP_MIXED;
  Quiz[91].MyGroup = GROUP_MIXED;
  Quiz[92].MyGroup = GROUP_MIXED;
  Quiz[93].MyGroup = GROUP_MIXED;
  Quiz[94].MyGroup = GROUP_MIXED;
  Quiz[95].MyGroup = GROUP_NONVERBAL;
  Quiz[96].MyGroup = GROUP_NONVERBAL;
  Quiz[97].MyGroup = GROUP_MIXED;
  Quiz[98].MyGroup = GROUP_MIXED;
  Quiz[99].MyGroup = GROUP_MIXED;
  Quiz[100].MyGroup = GROUP_MIXED;
  Quiz[101].MyGroup = GROUP_MIXED;
  Quiz[102].MyGroup = GROUP_MIXED;
  Quiz[103].MyGroup = GROUP_MIXED;
  Quiz[104].MyGroup = GROUP_MIXED;
  Quiz[105].MyGroup = GROUP_MIXED;
  Quiz[106].MyGroup = GROUP_MIXED;
  Quiz[107].MyGroup = GROUP_NONVERBAL;
  Quiz[108].MyGroup = GROUP_SENSORY;
  Quiz[109].MyGroup = GROUP_SENSORY;
  Quiz[110].MyGroup = GROUP_SENSORY;
  Quiz[111].MyGroup = GROUP_SENSORY;
  Quiz[112].MyGroup = GROUP_MIXED;
  Quiz[113].MyGroup = GROUP_MIXED;
  Quiz[114].MyGroup = GROUP_MIXED;
  Quiz[115].MyGroup = GROUP_SENSORY;
  Quiz[116].MyGroup = GROUP_SENSORY;
  Quiz[117].MyGroup = GROUP_MIXED;
  Quiz[118].MyGroup = GROUP_SENSORY;
  Quiz[119].MyGroup = GROUP_MIXED;
  Quiz[120].MyGroup = GROUP_SENSORY;
  Quiz[121].MyGroup = GROUP_SENSORY;
  Quiz[122].MyGroup = GROUP_MIXED;
  Quiz[123].MyGroup = GROUP_MIXED;
  Quiz[124].MyGroup = GROUP_MIXED;
  Quiz[125].MyGroup = GROUP_MIXED;
  Quiz[126].MyGroup = GROUP_MIXED;
  Quiz[127].MyGroup = GROUP_MIXED;
  Quiz[128].MyGroup = GROUP_MIXED;

#ifdef ENGLISH
  Quiz[0].Text = "Have you felt different from others for most of your life?";
  Quiz[1].Text = "Do you feel much younger inside than your biological age?";
  Quiz[2].Text = "Do you consider yourself emotionally sensitive?";
  Quiz[3].Text = "Do you tend to express your feelings in unusual ways (e.g banging your head in the wall or not showing anything at all)?";
  Quiz[4].Text = "Are you asexual (= uninterested in sex)?";
  Quiz[5].Text = "Do you feel awkward in romantic situations?";
  Quiz[6].Text = "Are you sometimes fearless in situations that can be dangerous?";
  Quiz[7].Text = "Are you more of an observer than one who participates in life?";
  Quiz[8].Text = "Have you had more difficulties than others of the same age when it comes to making friendships or getting into relationships?";
  Quiz[9].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  Quiz[10].Text = "Have you had a tendency to prefer the company of those older than yourself to that of your peers?";
  Quiz[11].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[12].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[13].Text = "Have you been bullied, abused or taken advantage of in various situations?";
  Quiz[14].Text = "Do you tend to feel nervous, shy, confused and/or like you don't fit in, in various social situations?";
  Quiz[15].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[16].Text = "Have you had the feeling of playing a game to pretend to be like people around you?";
  Quiz[17].Text = "Have you had difficulties fitting into expected gender stereotypes, perhaps having interests and behaviors that are atypical for your gender?";
  Quiz[18].Text = "Is a large social network important to you?";
  Quiz[19].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[20].Text = "Are you comfortable in social situations and with new people?";
  Quiz[21].Text = "Are you energised by being in the company of others?";
  Quiz[22].Text = "Do you enjoy team sport and group endeavours?";
  Quiz[23].Text = "Is your image and social identity a priority to you";
  Quiz[24].Text = "Are you intuitive about what people need from you?";
  Quiz[25].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[26].Text = "Can you easily remember people's names when you meet new people?";
  Quiz[27].Text = "Is it difficult or tiresome for you to talk?";
  Quiz[28].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
  Quiz[29].Text = "Do you stutter when stressed?";
  Quiz[30].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[31].Text = "Do you find it easier to communicate online than in real life?";
  Quiz[32].Text = "Do you have a habit of repeating your own or others' last words (echolalia)?";
  Quiz[33].Text = "Do you have difficulties understanding idioms, figures of speech, parodies, allegories or irony?";
  Quiz[34].Text = "If asked to describe yourself, would you do so in a detached way, as if you were describing someone else?";
  Quiz[35].Text = "Do you tend to be more blunt and straightforward than others?";
  Quiz[36].Text = "Do you tend to say or do things that are considered socially inappropriate?";
  Quiz[37].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
  Quiz[38].Text = "Do you have difficulties interpreting body language and/or facial expressions and figuring out what people feel and want, unless they tell you?";
  Quiz[39].Text = "Are you usually unaware of social rules & boundaries unless they are specifically spelled out?";
  Quiz[40].Text = "Do people think you are smiling at the wrong occasion or not smiling when you are expected to?";
  Quiz[41].Text = "Do you have problems with eye-contact (e.g. preferring to avoid it, or staring ‘too much’)?";
  Quiz[42].Text = "Can you 'read between the lines'?";
  Quiz[43].Text = "Do you find it easy to describe your feelings?";
  Quiz[44].Text = "Do you know when you are expected to offer an apology?";
  Quiz[45].Text = "Do you talk to put others at ease even if you don't have anything special to convey?";
  Quiz[46].Text = "Are you good at small talk?";
  Quiz[47].Text = "Do you look younger than your biological age??";
  Quiz[48].Text = "Were you precocious as a child?";
  Quiz[49].Text = "Was your play more directed towards sorting, building or taking things apart than towards social games with other kids?";
  Quiz[50].Text = "Are you naturally nocturnal, i.e. do you tend to be most alert at night?";
  Quiz[51].Text = "Do you find the norms of hygiene too strict?";
  Quiz[52].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[53].Text = "Do you mostly prefer playing/working/doing things on your own - in your own way and at your own pace?";
  Quiz[54].Text = "Do you find yourself more attracted to things, ideas, music, computers, animals, buildings or vehicles than to people and social exchange?";
  Quiz[55].Text = "Are you very gifted in one or more areas?";
  Quiz[56].Text = "Do you have unconventional, often unique ways of solving problems?";
  Quiz[57].Text = "Do you hyperfocus on one interest at a time and become an expert on that subject?";
  Quiz[58].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[59].Text = "Do you have excellent vocabulary and/or a fascination with words?";
  Quiz[60].Text = "Did you learn to read on your own before you were taught in school?";
  Quiz[61].Text = "Are you fascinated by dates and/or numbers?";
  Quiz[62].Text = "Do you enjoy figuring out how things work?";
  Quiz[63].Text = "Are you punctual, conscientious and a perfectionist?";
  Quiz[64].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
  Quiz[65].Text = "Have you been called a ‘know-it-all’ because you feel compelled to correct people with accurate facts?";
  Quiz[66].Text = "Do you have keen sense of ethics and a tendency to stand up for your ideals and beliefs even if they are contrary to general consensus, or if it means social or economical disadvantages?";
  Quiz[67].Text = "Do you tend to get so absorbed in your projects that you forget everything else (e.g. eating, sleeping, taking a shower, other people)?";
  Quiz[68].Text = "Do you find it hard to multi-task or shift your attention rapidly from one thing to another and therefore need to finish one task before turning to the next?";
  Quiz[69].Text = "Do you have certain simple & logical routines which you need to follow?";
  Quiz[70].Text = "Does it cause chaos in you if your plans, environment or daily routines suddenly get changed?";
  Quiz[71].Text = "Do you feel stress, panic or have a brain malfunction in unfamiliar or demanding situations?";
  Quiz[72].Text = "Do you have a need for symmetry, order and/or precision?";
  Quiz[73].Text = "Do you have strong attachments to certain objects?";
  Quiz[74].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
  Quiz[75].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[76].Text = "Before doing something or going somewhere, do you need to visualize the place you’re going to or rehearse possible scenarios in your mind so as to prepare yourself?";
  Quiz[77].Text = "Do you sometimes have a need for comfort items like a blanket, stuffed animals etc?";
  Quiz[78].Text = "Do you do any of the following when you’re thinking, restless or bored: pacing; bouncing leg or foot; tapping fingers, pen or other object; doodling; fiddling with object e.g clicking pen; chewing on something?";
  Quiz[79].Text = "Do you do any of the following when you're happy: singing, humming or whistling to yourself?";
  Quiz[80].Text = "Do you do any of the following when anxious: twisting hands or fingers; rubbing hands, arms or thighs; biting lip, cheek or tongue?";
  Quiz[81].Text = "Do you do any of the following when bored: cracking joints; picking skin or scabs; peeling skin flakes; picking nose; pulling hairs;  biting nails or fingertips; pulling cuticle?";
  Quiz[82].Text = "Do you do any of the following in order to calm yourself when excited, overwhelmed or overstimulated: rocking; flapping hands; tapping ears; pressing eyes?";
  Quiz[83].Text = "Do you do any of the following for fun: spin in circles; walk on toes; watch a spinning, blinking or glittering object?";
  Quiz[84].Text = "Do you self-harm, or have you done so in the past?";
  Quiz[85].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[86].Text = "Do you have poor concept of time?";
  Quiz[87].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[88].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[89].Text = "Are you easily distracted and/or bored?";
  Quiz[90].Text = "Do you find it hard to focus on or learn things you are not interested in?";
  Quiz[91].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[92].Text = "Do you tend to be hyperactive and restless?";
  Quiz[93].Text = "Do you tend to be impatient and impulsive, e.g. having trouble waiting for your turn?";
  Quiz[94].Text = "Do you have a hyperactive mind?";
  Quiz[95].Text = "Do you have problems recognizing faces (dysphagia)?";
  Quiz[96].Text = "Do you have an odd posture or gait?";
  Quiz[97].Text = "Do you have poor balance, e.g. difficulty riding a bicycle, skating, standing on one leg?";
  Quiz[98].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[99].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[100].Text = "Do you have problems with ball sports?";
  Quiz[101].Text = "Do you have difficulties with two-handed tasks, e.g. eating with knife & fork, knitting, typing or playing an instrument?";
  Quiz[102].Text = "Do you have difficulties with activities requiring manual dexterity and precision, e.g drawing, sewing, tying shoe-laces, fastening buttons and handling small objects?";
  Quiz[103].Text = "Do you have difficulty writing by hand (dysgraphia)?";
  Quiz[104].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands and a tendency to drop, spill or break things by mistake?";
  Quiz[105].Text = "Are you easily overexcited, stressed and overwhelmed by things like noise, crowds, clutter, patterns, flicker and movement?";
  Quiz[106].Text = "Do you have extra sensitive hearing?";
  Quiz[107].Text = "Do you have difficulties filtering out background noises when talking to someone?";
  Quiz[108].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[109].Text = "Do you have a very acute sense of taste?";
  Quiz[110].Text = "Do you have to be particular about what you eat and/or how it is combined on the plate in order to be able to eat?";
  Quiz[111].Text = "Do you have a very acute sense of smell?";
  Quiz[112].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[113].Text = "Do you have poor night vision?";
  Quiz[114].Text = "Do you have a well-developed sense of colour?";
  Quiz[115].Text = "Do you have (or have you had) a problem with squinting?";
  Quiz[116].Text = "Do you feel uncomfortable in fluorescent light?";
  Quiz[117].Text = "Are you sensitive to weather changes?";
  Quiz[118].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[119].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[120].Text = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
  Quiz[121].Text = "Are you fairly insensitive to physical pain, or even enjoy some types of pain?";
  Quiz[122].Text = "Do you enjoy snuggling with people you like?";
  Quiz[123].Text = "Do you find it easy to understand and sympathise with those who function very differently from yourself?";
  Quiz[124].Text = "Have you had or would you like to have a sex-change?";
  Quiz[125].Text = "Do you dislike shaking hands due to disliking the feel of skin-contact with others?";
  Quiz[126].Text = "Do you dislike shaking hands due to germophobia?";
  Quiz[127].Text = "Do you dislike shaking hands because handshakes feel unnatural?";
  Quiz[128].Text = "Do you dislike shaking hands for other reason?";
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Har du känt dig annorlunda största delen av ditt liv?";
  Quiz[1].Text = "Känner du dig mycket yngre än din biologiska ålder?";
  Quiz[2].Text = "Är du emotionellt sensitiv?";
  Quiz[3].Text = "Brukar du uttrycka dina känslor på ovanliga sätt (t ex banka huvudet i väggen eller inte visa något alls)?";
  Quiz[4].Text = "Är du asexuell? (= ointresserad av sex)?";
  Quiz[5].Text = "Känner du dig obekväm i romantiska situationer?";
  Quiz[6].Text = "Händer det att du är orädd i situationer som faktiskt kan vara farliga?";
  Quiz[7].Text = "Känner du dig mer som en observatör än som en deltagare i livet?";
  Quiz[8].Text = "Har du haft svårare än dina jämnåriga att få vänner eller partners?";
  Quiz[9].Text = "Föredrar du bara att umgås med folk du känner väl, och helst på tu man hand eller i en mindre grupp?";
  Quiz[10].Text = "Har du brukat föredra att umgås människor som är äldre eller mer erfarna än du själv framför jämnåriga?";
  Quiz[11].Text = "Brukar du blir väldigt trött av att umgås med folk och efteråt behöva vila ut ifred?";
  Quiz[12].Text = "Ogillar du när folk kommer och hälsar på utan att ha blivit inbjudna?";
  Quiz[13].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad i olika situationer?";
  Quiz[14].Text = "Brukar du bli nervös, blyg, förvirrad och/eller ha svårt att passa in i olika sociala situationer?";
  Quiz[15].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[16].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
  Quiz[17].Text = "Har du haft svårigheter att passa in i traditionella könsroller, kanske haft intressen och uppförande som är otypiska för ditt kön?";
  Quiz[18].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[19].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[20].Text = "Känner du dig hemma i sociala situationer med nya människor?";
  Quiz[21].Text = "Får du energi av att vara i sällskap med andra?";
  Quiz[22].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
  Quiz[23].Text = "Är din image och sociala identitet väldigt viktig för dig?";
  Quiz[24].Text = "Känner du intuitivt vad folk behöver från dig?";
  Quiz[25].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[26].Text = "Har du lätt att komma ihåg vad folk heter när du möter nya människor?";
  Quiz[27].Text = "Finner du det svårt eller tröttsamt att tala?";
  Quiz[28].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
  Quiz[29].Text = "Stammar du när du blir stressad?";
  Quiz[30].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[31].Text = "Tycker du att det är lättare att kommunicera via dator än i verkliga livet?";
  Quiz[32].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt (ekolali)?";
  Quiz[33].Text = "Har du svårt att förstå talesätt, allegorier, parodier, ironi och liknande?";
  Quiz[34].Text = "Om du blev ombedd att beskriva dig själv, skulle du då göra det på objektivt sätt, som om du beskrev någon annan?";
  Quiz[35].Text = "Brukar du vara mer rak och rättfram i din kommunikation än andra?";
  Quiz[36].Text = "Brukar du säga eller göra saker som anses socialt opassande?";
  Quiz[37].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
  Quiz[38].Text = "Brukar du ha svårt att tolka kroppsspråk och ansiktsuttryck och att förstå vad andra känner och vill om de inte säger det rakt ut?";
  Quiz[39].Text = "Är du oftast omedveten om outtalade sociala regler?";
  Quiz[40].Text = "Brukar folk tycka att du ler vid fel tillfälle eller att du inte ler när du ‘borde’?";
  Quiz[41].Text = "Har du problem med ögonkontakt (t ex föredrar att undvika det, eller stirrar ‘för mycket’)?";
  Quiz[42].Text = "Kan du 'läsa mellan raderna'?";
  Quiz[43].Text = "Är det lätt för dig att beskriva dina känslor?";
  Quiz[44].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[45].Text = "Brukar du prata för att få andra att känna sig väl till mods även om du inte har nåt speciellt att berätta?";
  Quiz[46].Text = "Är du bra på kallprat?";
  Quiz[47].Text = "Ser du yngre ut än din biologiska ålder?";
  Quiz[48].Text = "Var du \"lillgammal\" som barn?";
  Quiz[49].Text = "Brukade dina lekar mer bestå i att sortera, bygga eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[50].Text = "Är du en nattmänniska, d.v.s. brukar du vara som piggast på kvällen/natten?";
  Quiz[51].Text = "Tycker du att normerna för hygien är för strikta?";
  Quiz[52].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[53].Text = "Brukar du föredra att leka/arbeta/göra saker själv - på ditt eget sätt och i din egen takt?";
  Quiz[54].Text = "Är du i grunden mer intresserad av saker, idéer, filmer, datorer, musik, djur, hus, fordon el dyl, än av människor och social samvaro?";
  Quiz[55].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
  Quiz[56].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
  Quiz[57].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[58].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[59].Text = "Har du utmärkt vokabulär och intresse för språk?";
  Quiz[60].Text = "Lärde du dig att läsa själv innan du började skolan?";
  Quiz[61].Text = "Är du fascinerad av datum och/eller siffror?";
  Quiz[62].Text = "Tycker du om att lista ut hur saker fungerar?";
  Quiz[63].Text = "Är du punktlig, noggrann och perfektionistisk?";
  Quiz[64].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
  Quiz[65].Text = "Har du blivit kallad ‘besserwisser’ för att du känner dig manad att korrigera andra med korrekta fakta?";
  Quiz[66].Text = "Har du hög moral och en tendens att hålla fast vid dina ideal, övertygelser och principer även om de går emot det rådande synsättet och kan vara till din nackdel, t ex socialt eller ekonomiskt?";
  Quiz[67].Text = "Brukar du bli så absorberad av dina projekt att du glömmer allting annat (äta, duscha, sova, andra människor etc.)?";
  Quiz[68].Text = "Har du svårt att göra flera saker samtidigt, snabbt skifta fokus från en sak till en annan och därför har behov av att få göra klart det du håller på med innan du kan ta itu med något annat?";
  Quiz[69].Text = "Har du vissa enkla, logiska rutiner som det känns bra att följa? (tog bort lite i mitten så de blev mer lika)?";
  Quiz[70].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer eller rutiner?";
  Quiz[71].Text = "Brukar du bli stressad och få panik eller kortslutning i hjärnan i nya och kravfyllda situationer?";
  Quiz[72].Text = "Har du ett behov av symmerti, ordning och/eller precision?";
  Quiz[73].Text = "Är du exceptionellt fäst vid vissa saker?";
  Quiz[74].Text = "Har du behov av att sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
  Quiz[75].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[76].Text = "Innan du gör något eller åker någonstans, behöver du ha en inre bild av platsen eller mentalt öva på tänkbara scenarier för att förbereda dig?";
  Quiz[77].Text = "Har du ibland behov av gosefilt, kramdjur eller liknande?";
  Quiz[78].Text = "Brukar du göra något av följande när du tänker, är rastlös eller uttråkad: vanka; vippa foten eller benet; trumma med fingrarna, en penna eller annat objekt; kludda; klicka penna, pilla eller tugga på något?";
  Quiz[79].Text = "Brukar du göra något av följande när du är glad: sjunga, nynna eller vissla för dig själv?";
  Quiz[80].Text = "Brukar du göra något av följande när du är orolig: vrida dina händer eller fingar; gnugga händer, överarmar eller lår; bita dig i läppen, kinden eller tungan?";
  Quiz[81].Text = "Brukar du göra något av följande när du är uttråkad: knäcka leder; pila på huden; dra hudflagor; plocka sårskorpor; peta näsan; dra ut hårstrån; bita på naglarna eller fingertopparna; dra i nagelbanden?";
  Quiz[82].Text = "Brukar du göra något av följande för att lugna ner dig när du blivit upphetsad, stressad eller överstimulerad: gunga med överkroppen, flaxa med händerna, slå på öronen, pressa händerna mot ögonen?";
  Quiz[83].Text = "Brukar du göra något av följande för att det är roligt: snurra runt, runt; gå på tå; titta på ett snurrande, blinkande eller glittrande föremål?";
  Quiz[84].Text = "Brukar du ägna dig åt självskadande beteende, eller har du gjort det tidigare?";
  Quiz[85].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och fart?";
  Quiz[86].Text = "Har du dålig tidsuppfattning?";
  Quiz[87].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[88].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[89].Text = "Blir du lätt distraherad och/eller uttråkad?";
  Quiz[90].Text = "Har du svårt att koncenterera dig på eller lära dig saker du inte är intresserad av?";
  Quiz[91].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[92].Text = "Brukar du vara hyperaktiv och rastlös?";
  Quiz[93].Text = "Brukar du vara otålig och impulsiv och t ex ha svårt att vänta på din tur?";
  Quiz[94].Text = "Är du mentalt hyperaktiv?";
  Quiz[95].Text = "Har du svårt att känna igen ansikten?";
  Quiz[96].Text = "Har du ovanlig kroppshållning eller gångstil?";
  Quiz[97].Text = "Har du dåligt balanssinne, t ex svårt att cykla, åka skridskor, stå på ett ben?";
  Quiz[98].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[99].Text = "Har du svårt att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[100].Text = "Har du problem med med bollsporter?";
  Quiz[101].Text = "Har du svårt med aktiviteter där man använder båda händerna samtidigt, t ex äta med kniv & gaffel, sticka, skriva maskin eller spela ett instrument?";
  Quiz[102].Text = "Har du svårigheter med aktiviteter som kräver finmotorisk precision, t ex att rita, sy, knyta skosnören, knäppa knappar och hantera små föremål?";
  Quiz[103].Text = "Har du svårt att skriva för hand (dysgrafi)?";
  Quiz[104].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna och en tendens att tappa, spilla eller ha sönder saker av misstag?";
  Quiz[105].Text = "Blir du lätt överstimulerad och stressad av för mycket ljud, mönster, flimmer, oreda, trängsel och rörelse?";
  Quiz[106].Text = "Här du extra känslig hörsel?";
  Quiz[107].Text = "Har du svårt att filtrera bort bakgrundsljud när du talar med någon?";
  Quiz[108].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
  Quiz[109].Text = "Har du extra känsligt smaksinne?";
  Quiz[110].Text = "Måste du vara petig med vad du äter och/eller hur maten kombineras på tallriken för att kunna äta?";
  Quiz[111].Text = "Har du extra känsligt luktsinne?";
  Quiz[112].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[113].Text = "Har du dåligt mörkerseende?";
  Quiz[114].Text = "Har du välutvecklat färgseende?";
  Quiz[115].Text = "Har du (eller har du haft) problem med skelning?";
  Quiz[116].Text = "Är du känslig för lyrsrörsljus?";
  Quiz[117].Text = "Är du känslig för väderomslag?";
  Quiz[118].Text = "Pinas du av skavande sömmar och etiketter, kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[119].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller bett om det?";
  Quiz[120].Text = "Om någon tar i dig, föredrar du då hårdare tag framför lätt beröring?";
  Quiz[121].Text = "Är du okänslig för smärta eller till och med tycker om viss sorts smärta?";
  Quiz[122].Text = "Gillar du att mysa ihop med personer du tycker om?";
  Quiz[123].Text = "Har du lätt att förstå och känna sympati även för dem som fungerar väldigt annorlunda än du själv?";
  Quiz[124].Text = "Har du genomgått eller skulle du vilja genomgå ett könsbyte?";
  Quiz[125].Text = "Ogillar du att ta i hand pga att du inte gillar känslan av hudkontakt med andra?";
  Quiz[126].Text = "Ogillar du att ta i hand pga bacillskräck?";
  Quiz[127].Text = "Ogillar du att ta i hand för att handslag känns onaturligt?";
  Quiz[128].Text = "Ogillar du att ta i hand av annan orsak?";
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
  DefineGlobalId( 2, 485);
	DefineCross(QuizI, 3, 75);
	DefineCross(Quiz8, 4, 130);
	DefineCross(Quiz6, 5, 68);
  DefineGlobalId( 6, 486);
    DefineCross(QuizI, 7, 66);
    DefineCross(Quiz9, 8, 50);
    DefineCross(QuizI, 9, 33);
    DefineCross(QuizI, 10, 32);
    DefineCross(Quiz9, 11, 55);
    DefineCross(Quiz6, 12, 118);
    DefineCross(Quiz7, 13, 119);
    DefineCross(Quiz9, 14, 54);
  DefineGlobalId( 15, 487);
    DefineCross(Quiz8, 16, 64);
  DefineGlobalId( 17, 488);
    DefineCross(Quiz9, 18, 74);
    DefineCross(Quiz8, 19, 70);
    DefineCross(Quiz9, 20, 69);
    DefineCross(Quiz9, 21, 66);
    DefineCross(Quiz9, 22, 65);
  DefineGlobalId( 23, 489);
    DefineCross(Quiz6, 24, 35);
    DefineCross(Quiz9, 25, 100);
  DefineGlobalId( 26, 490);
    DefineCross(QuizI, 27, 13);
    DefineCross(Quiz9, 28, 105);
    DefineCross(Quiz8, 29, 8);
    DefineCross(Quiz9, 30, 98);
    DefineCross(Quiz9, 31, 59);
  DefineGlobalId( 32, 491);
    DefineCross(QuizIII, 33, 32);
  DefineGlobalId( 34, 492);
  DefineGlobalId( 35, 493);
  DefineGlobalId( 36, 494);
    DefineCross(Quiz9, 37, 64);
    DefineCross(QuizIII, 38, 25);
    DefineCross(Quiz7, 39, 75);
  DefineGlobalId( 40, 495);
  DefineGlobalId( 41, 496);
    DefineCross(Quiz9, 42, 102);
  DefineGlobalId( 43, 497);
    DefineCross(Quiz9, 44, 109);
    DefineCross(Quiz7, 45, 66);
	DefineCross(QuizNd, 46, 36);
    DefineCross(QuizI, 47, 41);
  DefineGlobalId( 48, 498);
  DefineGlobalId( 49, 499);
  DefineGlobalId( 50, 500);
    DefineCross(Quiz6, 51, 139);
    DefineCross(Quiz9, 52, 61);
    DefineCross(Quiz8, 53, 69);
    DefineCross(QuizI, 54, 68);
    DefineCross(Quiz9, 55, 35);
    DefineCross(Quiz9, 56, 30);
    DefineCross(Quiz9, 57, 31);
    DefineCross(Quiz9, 58, 34);
	DefineCross(Quiz9, 59, 36);
    DefineCross(Quiz7, 60, 143);
    DefineCross(Quiz7, 61, 117);
    DefineCross(Quiz9, 62, 37);
    DefineCross(QuizII, 63, 69);
    DefineCross(Quiz9, 64, 115);
  DefineGlobalId( 65, 501);
    DefineCross(QuizI, 66, 98);
    DefineCross(Quiz8, 67, 120);
    DefineCross(QuizI, 68, 26);
    DefineCross(Quiz9, 69, 117);
    DefineCross(Quiz9, 70, 110);
    DefineCross(Quiz7, 71, 83);
    DefineCross(Quiz9, 72, 118);
    DefineCross(Quiz9, 73, 116);
    DefineCross(Quiz9, 74, 114);
    DefineCross(Quiz9, 75, 112);
  DefineGlobalId( 76, 502);
    DefineCross(Quiz7, 77, 90);
  DefineGlobalId( 78, 503);
  DefineGlobalId( 79, 504);
  DefineGlobalId( 80, 505);
  DefineGlobalId( 81, 506);
  DefineGlobalId( 82, 507);
  DefineGlobalId( 83, 508);
  DefineGlobalId( 84, 509);
    DefineCross(Quiz9, 85, 11);
    DefineCross(Quiz7, 86, 122);
    DefineCross(QuizI, 87, 31);
    DefineCross(QuizI, 88, 30);
    DefineCross(QuizII, 89, 64);
  DefineGlobalId( 90, 510);
  DefineGlobalId( 91, 511);
  DefineGlobalId( 92, 512);
  DefineGlobalId( 93, 513);
  DefineGlobalId( 94, 514);
    DefineCross(Quiz6, 95, 36);
    DefineCross(Quiz6, 96, 31);
  DefineGlobalId( 97, 515);
  DefineGlobalId( 98, 516);
  DefineGlobalId( 99, 517);
  DefineGlobalId( 100, 518);
  DefineGlobalId( 101, 519);
  DefineGlobalId( 102, 520);
    DefineCross(Quiz8, 103, 25);
  DefineGlobalId( 104, 521);
    DefineCross(QuizNd, 105, 10);
  DefineGlobalId( 106, 522);
    DefineCross(Quiz9, 107, 106);
    DefineCross(Quiz8, 108, 3);
    DefineCross(Quiz9, 109, 21);
    DefineCross(QuizI, 110, 58);
    DefineCross(Quiz9, 111, 24);
  DefineGlobalId( 112, 523);
  DefineGlobalId( 113, 524);
  DefineGlobalId( 114, 525);
    DefineCross(Quiz9, 115, 20);
    DefineCross(Quiz9, 116, 26);
  DefineGlobalId( 117, 526);
    DefineCross(Quiz8, 118, 6);
  DefineGlobalId( 119, 527);
    DefineCross(Quiz9, 120, 27);
    DefineCross(Quiz9, 121, 29);
  DefineGlobalId( 122, 528);
  DefineGlobalId( 123, 529);
  DefineGlobalId( 124, 530);
  DefineGlobalId( 125, 531);
  DefineGlobalId( 126, 532);
  DefineGlobalId( 127, 533);
  DefineGlobalId( 128, 534);
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
