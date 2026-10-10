* SAVARESE AJ - PROJECT CODE

* HYPOTHESIS: Objects w/ larger diff. btwn 
outburst mag. & quiescent magn. will show 
higher signal-to-noise ratio

(Greater signal-to-noise ratio = stronger detectability)

Because magnitude will end up being one variable, I also plan to test some others
(Leaning towards 'd', as I can use that as a proxy for noise for SNR)


* I've been working with this code so much I just keep adding because I don't
want to accidentally delete something I need earlier;

*this is my madness :) 


* ~~~~~~
* PART 0 - IMPORTING DATA;
* ~~~~~~

;
%web_drop_table(WORK.BlackCAT);


FILENAME REFFILE '/home/u64053299/STAT 4210/FINAL PROJECT/BlackCAT.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.BlackCat;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.BlackCat; RUN;


%web_open_table(WORK.BlackCat);

proc print data = WORK.BlackCat (obs=10);
run;

*The vars I care about here to be NUM are NUM
(Mag. Quies., Magnitude Outburst, fxpeak, d)
Throwing d in as noise detection?

* ~~~~~~
* PART 1 - SETTING UP DATA;
* ~~~~~~



*I don't want to have to type out the long var names
let's shorten them for my sanity;

data CAT;
    set BlackCAT
        (rename=(
            'Mag. Quies.'n = MagQui
            'Magnitude Outburst'n = MagOut
        ));
run;

PROC CONTENTS DATA=Cat;


* My hypothesis is based on change in brightness (AKA the signal)
This var lets me pay attention to magnitude changes instead of just initial value
So let's combine magnitudes;

data CAT;
    set CAT;
    MagDiff = MagQui - MagOut;
run;

*This now let's us test hypothesis better
NOTE: Magnitude should normally be the other way around, but I'm changing
it for better interpretability;
* I don't know exactly why, it's just a weird astronomy quirk;

*And now we want to actually get to the signal detection part;

*Setting up our SNR;

data CAT;
    set CAT;

    logFx = log(Fxpeak);
    logd = log(d);
    logSNR = logFx - 2*logd;
run;

*I logged them all as this should help the data out
Also, a lot of the values are extremely small which means any change would
seem negligible overall;

* ~~~~~~
* PART 2 - ANALYZING DATA;
* ~~~~~~

;

*Summary Sats;
PROC MEANS data = WORK.CAT n mean stddev min Q1 median Q3 max maxdec=3;
  	var MagDiff Fxpeak d;
run;

*I want to note that while there were originally 73 entries,
we're really looking at less
(this is because d = 43 & MagDiff = 48 obs);

*Mag Histogram;

ods graphics on / outputfmt=svg;  
TITLE1 height=1.5 "Histogram of Differences in Magnitude (n = 48)";
Proc SGPLOT data=Cat;
histogram MagDiff/
	showbins 
	fillattrs=(color="vlipb")  
    dataskin=crisp
	boundary=upper; 
	refline 4.321 / axis=x lineattrs=(thickness=3 color=darkred pattern=dash);
	xaxis label='Magnitude Difference' labelattrs=(size=12) valueattrs=(size=12);
	yaxis label='Count' labelattrs=(size=12) valueattrs=(size=12);
run;
TITLE;
ods graphics off;


*d Hist;
ods graphics on / outputfmt=svg;  
TITLE1 height=1.5 "Histogram of Distance From Earth to Object (n = 43)";
Proc SGPLOT data=Cat;
histogram d/
	showbins 
	fillattrs=(color="vlipb")  
    dataskin=crisp
	boundary=upper;
	refline 6.074 / axis=x lineattrs=(thickness=3 color=darkred pattern=dash);
	xaxis label='Distance in Kiloparsecs (kpc)' labelattrs=(size=12) valueattrs=(size=12);
	yaxis label='Count' labelattrs=(size=12) valueattrs=(size=12);
run;
TITLE;
ods graphics off;


* ~~~~~~
* PART 3 - EXPLORING DATA;
* ~~~~~~

;


*Correlation;

PROC CORR data=Cat;
    var logFx logSNR;
    with MagDiff logd;
run;

*Magdiff & logFX does prove that
Signal relates to emission (moderate though)

*logd & logSNR is our best result here
this is really good!
Shows that distance heavily impacts detectability
(distance = noise idea correct)

*Plot corr;
proc corr data=Cat;
    var MagDiff logd logSNR;
run;

*Scatter Plot;
ods graphics on;
proc sgplot data=Cat;
  scatter x=logFx y=MagDiff /
    markerattrs=(symbol=circlefilled color=vlipb size=8);
  reg x=logFx y=MagDiff/ lineattrs=(color=black thickness=2);
  xaxis label='Log FX Peak';
  yaxis label='Magnitude Difference';
  title "Log FX Peak vs Magnitude Difference";
run;
ods graphics off;

*Signal vs Detectability;
ods graphics on;
proc sgplot data=Cat;
  scatter x=MagDiff y=logSNR /
    markerattrs=(symbol=circlefilled color="vlipb" size=8);
  reg x=MagDiff y=logSNR /
    lineattrs=(color=black thickness=2);
  xaxis label='Magnitude Difference (Signal)';
  yaxis label='Log SNR (Detectability)';
  title "Effect of Signal on Detectability";
run;
ods graphics off;

* Distance vs Detectability (IMPORTANT ONE);
ods graphics on;
proc sgplot data=Cat;
  scatter x=logd y=logSNR /
    markerattrs=(symbol=circlefilled color="vlipb" size=8);
  reg x=logd y=logSNR /
    lineattrs=(color=black thickness=2);
  xaxis label='Log Distance (Noise)';
  yaxis label='Log SNR (Detectability)';
  title "Effect of Distance on Detectability";
run;
ods graphics off;



*Multi Lin Reg;

proc reg data=CAT;
    model logSNR = MagDiff;
    title "Effect of Magnitude Difference on Detectability (SNR)";
run;

*This is basically asking if
stronger signal (MagDiff) lead to higher detectability (logSNR)?

As magdiff increases, detectability tends to increase
but the evidence is not strong enough to be stat sig (p = .0782)

Magdiff explains about 8% of the variation

Signal (Magdiff) does matter
but detectability is dominated by distance (noise);

proc reg data=CAT;
    model logFx = MagDiff logd;
    title "Flux explained by signal and distance";
run;
quit;

*bigger outbursts seem to have stronger X-ray flux
Distance strongly affects observed flux;
