clear all
set more off
local usuario=c(username)

if "`usuario'"=="andro" {
	glo mainFolder = "C:\Users\andro\Google Drive\Salud\SABE\HBP SAGE SES gradient comparison\"
}
if "`usuario'"=="paul.rodriguez" {
	glo mainFolder = "D:\paul.rodriguez\Google Drive\Salud\SABE\HBP SAGE SES gradient comparison\"
}


if "`usuario'"=="maria" {
	glo mainFolder = "C:\Users\maria\Desktop\Paul_Junio2020\HBP SAGE SES gradient comparison"
}

global raw     "$mainFolder\raw"
global derived "$mainFolder\derived"
global tables  "$mainFolder\tables"
global figures "$mainFolder\images"

********************************************************************************
************ Esdadísticas descriptivas *****************************************
********************************************************************************

use "$derived\HBPC_SAGECol_HBP.dta", clear
keep if ragey>=60 //Keep just ages above or equal to 60 years old

tabstat ragey educL1 educL2 educL3 obese  rsmokev popatisk undetHBP unconHBP hwealth hi_vih hi_no, by(survey) stat(N)

********************************************************************************
******* Detección de missings **************************************************
********************************************************************************
glo controles Male ragey obese rsmokev educL1 educL2 educL3  urban hwealth  sysval  diaval y200708 y200910
egen obs_missing=rowtotal($controles)
replace obs_missing=1 if obs_missing>0 // Si tiene missing en alguna de los controles, esta observación no va a estar en la regresión
* crear variables que sean 1 si la variable es un missing
foreach variables of glo controles {
gen missing_`variables'=(`variables'==.)
}

glo missing_controls missing_Male missing_ragey missing_obese missing_rsmokev missing_educL1 missing_educL2 missing_educL3 missing_urban missing_hwealth missing_sysval missing_diaval

bys survey: mdesc $controles

reg obs_missing $controles, robust

drop missing_*

// El país con más missings en casi todos los controles es México (El porcentaje de missings en varios casos es mayor al 60%)
// Colombia tiene varios missings en las variables de interés sysval y diaval
// A nivel general, las variables con más missings en todos los países son las de obesidad y tabaquismo


//Keep just if a person have values different to missing in controls
keep if Male!=. & ragey!=. & obese!=. &  rsmokev!=. & educL1!=. & educL2!=. & educL3!=. & urban!=. & hwealth!=. & sysval!=. & diaval!=.


************************************************************************
* Figure 1: Kernel density systolic BP *********************************
************************************************************************

preserve
set scheme s2mono     
kdensity sysval if survey==1, nograph generate(x fx) bw(4) 
kdensity sysval if survey==2, nograph generate(fx2) at(x) bw(4)
kdensity sysval if survey==3, nograph generate(fx3) at(x) bw(4)
kdensity sysval if survey==4, nograph generate(fx4) at(x) bw(4)
kdensity sysval if survey==5, nograph generate(fx5) at(x) bw(4)
kdensity sysval if survey==6, nograph generate(fx6) at(x) bw(4)
kdensity sysval if survey==7, nograph generate(fx7) at(x) bw(4)

label var fx  "China"
label var fx2 "Colombia"
label var fx3 "Ghana"
label var fx4 "India"
label var fx5 "Mexico"
label var fx6 "Russia"
label var fx7 "South Africa"
line fx x, sort ytitle(Density) graphregion(color(white)) lwidth(thick) ///
     || line fx2 fx3 fx4 fx5 fx6 fx7 x , sort xline(140) lwidth(thick thick thick thick thick thick) scheme(plotplainblind)
graph export "$figures/HBPC_kdensity_sysval.pdf",as(pdf) replace
restore
	
					
************************************************************************
* Figure 2: Decomposition HBP status ***********************************
************************************************************************

preserve

keep if popatisk==1
	* En 100 para la gráfica
	foreach varDep in rhibpe  Controlled150 Controlled140 { // drugTherapy
		replace `varDep'=`varDep'*100
	}

	graph bar (mean) rhibpe (mean) Controlled140 /// // (mean) drugTherapy 
		if popatisk==1  [pw=pweight] , ///
		over(survey, label(angle(forty_five))) bargap(-100) blabel(bar, format(%3.1g)) ///
		ytitle("Respondents (%)") ylabel(0(10)100) scheme(Plotplainblind) ///
		legend(order(1 "Aware" 2 "Controlled (Systolic BP <140)" ))
	graph export "$figures\HBPC_BPgraph.pdf",as(pdf) replace

restore

*mean rhibpe Controlled150 Controlled140 Controlled90140 [pw=pweight] // drugTherapy
/*
---------------------------------------------------------------
              |       Mean   Std. Err.     [95% Conf. Interval]
--------------+------------------------------------------------

         rhibpe |    .589037   .0091027      .5711942    .6068799
  Controlled150 |   .2968783   .0083658      .2804798    .3132767
  Controlled140 |   .1954259   .0073335       .181051    .2098009
Controlled90140 |   .1601227   .0065813      .1472222    .1730232
---------------------------------------------------------------
*/


*******************************************************************
* Figure 3: Kernel density Wealth Index ***************************
*******************************************************************
preserve
set scheme s2mono     
kdensity hwealth if survey==1, nograph generate(x fx) bw(0.03)
kdensity hwealth if survey==2, nograph generate(fx2) at(x) bw(0.03)
kdensity hwealth if survey==3, nograph generate(fx3) at(x) bw(0.03)
kdensity hwealth if survey==4, nograph generate(fx4) at(x) bw(0.03)
kdensity hwealth if survey==5, nograph generate(fx5) at(x) bw(0.03)
kdensity hwealth if survey==6, nograph generate(fx6) at(x) bw(0.03)
kdensity hwealth if survey==7, nograph generate(fx7) at(x) bw(0.03)

label var fx  "China"
label var fx2 "Colombia"
label var fx3 "Ghana"
label var fx4 "India"
label var fx5 "Mexico"
label var fx6 "Russia"
label var fx7 "South Africa"
line fx x, sort ytitle(Density) graphregion(color(white)) lwidth(thick) ///
     || line fx2 fx3 fx4 fx5 fx6 fx7 x , sort xline(140) lwidth(thick thick thick thick thick thick) scheme(plotplainblind)
graph export "$figures/HBPC_kdensity_hwealth.pdf",as(pdf) replace
restore


*******************************************************************
* Figure 4: Local polynomials wealth and HBP info *****************
*******************************************************************
	
tw 	(lpoly undetHBP hwealth if survey==1 & hwealth>.19 & hwealth<.93 , lwidth(thick)) ///
	(lpoly undetHBP hwealth if survey==2 & hwealth>.23 & hwealth<.94 , lwidth(thick)) ///
	(lpoly undetHBP hwealth if survey==3 & hwealth>.03 & hwealth<.73 , lwidth(thick)) ///
	(lpoly undetHBP hwealth if survey==4 & hwealth>.01 & hwealth<.82 , lwidth(thick)) ///	
	(lpoly undetHBP hwealth if survey==5 & hwealth>.50 & hwealth<.98 , lwidth(thick)) ///	
	(lpoly undetHBP hwealth if survey==6 & hwealth>.54 & hwealth<.93 , lwidth(thick)) ///	
	(lpoly undetHBP hwealth if survey==7 & hwealth>.09 & hwealth<.90 , lwidth(thick)) ///	
	, ytitle(Undetected HBP) title("") xtitle(Wealth Index) ylabel(0(.1)1) ///
	legend(cols(4) order(1 "China" 2 "Colombia" 3 "Ghana" 4 "India" 5 "Mexico" 6 "Russia" 7 "South Africa" )) 	 ///
	name(a1, replace) scheme(Plotplainblind)
	
tw 	(lpoly unconHBP hwealth if survey==1 & hwealth>.19 & hwealth<.93 , lwidth(thick)) ///
	(lpoly unconHBP hwealth if survey==2 & hwealth>.23 & hwealth<.94 , lwidth(thick)) ///
	(lpoly unconHBP hwealth if survey==3 & hwealth>.03 & hwealth<.73 , lwidth(thick)) ///
	(lpoly unconHBP hwealth if survey==4 & hwealth>.01 & hwealth<.82 , lwidth(thick)) ///
	(lpoly unconHBP hwealth if survey==5 & hwealth>.50 & hwealth<.98 , lwidth(thick)) ///	
	(lpoly unconHBP hwealth if survey==6 & hwealth>.54 & hwealth<.93 , lwidth(thick)) ///	
	(lpoly unconHBP hwealth if survey==7 & hwealth>.09 & hwealth<.90 , lwidth(thick)) ///	
	, ytitle(Uncontrolled HBP) title("") xtitle(Wealth Index) ylabel(0(.1)1) ///
	legend(cols(4) order(1 "China" 2 "Colombia" 3 "Ghana" 4 "India" 5 "Mexico" 6 "Russia" 7 "South Africa" )) ///
	name(a2, replace) scheme(Plotplainblind)

graph close a1 a2 
grc1leg a1 a2,  scheme(Plotplainblind)
graph export "$figures/HBPC_lpoly.pdf",as(pdf) replace	
			


*******************************************************************
*Table 1 *********************************************************
*******************************************************************

*glo extras popatisk_v2 rhibpe undetHBP_v2 unconHBP_v2
glo extras ="" // This is with diastolic BP... not so different but hits sample size

loc r=1
forval r=1(1)7 {
	use "$derived\HBPC_SAGECol_HBP.dta", clear
	keep if ragey>=60 //Keep just ages above or equal to 60 years old
	disp in red "Encuesta `r'"
	keep if survey==`r'

	glo controls Male ragey obese  rsmokev educL1 educL2 educL3 urban hwealth y200708 y200910
	if survey!=5 glo controls $controls  hi_vih hi_no // Mexico does not have HI
	if survey!=2 glo controls $extras $controls // Col does not have diastolic BP
	
	sum  popatisk rhibpe undetHBP unconHBP  diaval sysval pweight $controls

	mean rhibpe popatisk sysval  diaval $controls [pweight = pweight]
	mat B2_`r'= r(table)	
	mean rhibpe undetHBP unconHBP sysval diaval $controls [pweight = pweight] if popatisk==1
	mat B3_`r'= r(table)
		
	* N observations .......................................................
	egen n2=rowmiss(rhibpe popatisk sysval diaval $controls)
	qui count if n2==0
	loc na2_`r'= r(N)	
	egen n3=rowmiss(rhibpe undetHBP unconHBP sysval diaval $controls)
	qui count if n3==0 & popatisk==1
	loc na3_`r'= r(N)	
	
	* N Aware, Undetected and Uncontrolled ................................
	qui count if rhibpe==1 & n3==0
	loc nb3_`r'= r(N)		
	qui count if undetHBP==1 & n3==0
	loc nc3_`r'= r(N)		
	qui count if unconHBP==1 & n3==0
	loc nd3_`r'= r(N)		
	
	loc r= `r'+1	
}

* Generate latex table ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cd "$tables"
cap texdoc close
texdoc init HBPC_MeansSAGECol, force replace

tex \multicolumn{2}{l}{\textbf{A. Proportions and means}} \\

tex Variable & \multicolumn{2}{c}{China} & \multicolumn{2}{c}{Colombia} & \multicolumn{2}{c}{Ghana} & \multicolumn{2}{c}{India}  & \multicolumn{2}{c}{Mexico} & \multicolumn{2}{c}{Russia} & \multicolumn{2}{c}{South Africa} \\
tex & BPS & AR  & BPS & AR  & BPS & AR  & BPS & AR  & BPS & AR  & BPS & AR   & BPS & AR \\
tex \cmidrule(r){2-3} \cmidrule(r){4-5} \cmidrule(r){6-7} \cmidrule(r){8-9} \cmidrule(r){10-11} \cmidrule(r){12-13}  \cmidrule(r){14-15} 

foreach varDep in popatisk    rhibpe undetHBP    unconHBP /// //    popatisk_v2 rhibpe undetHBP_v2 unconHBP_v2 ///
				  diaval sysval ///
				  Male ragey obese  rsmokev educL1 educL2 educL3 urban hwealth hi_vih hi_no y200708 y200910 {
	loc row=""
	forval r=1(1)7  {
	
		if ("`varDep'"!="hi_vih" | "`varDep'"=="hi_no") & survey==5 {	// These variables are not available for Mexico
			loc row="`row' &  & "		
		}
		else {
			* For the population with BP ..........................	
			local whereagecol = colnumb(B2_`r',"`varDep'")
			local whereagerow = rownumb(B2_`r',"b")
			loc be2 : disp %4.2f B2_`r'[`whereagerow',`whereagecol']	
			if `be2'==. loc be2=""

			* For the population at risk ..........................	
			local whereagecol = colnumb(B3_`r',"`varDep'")
			local whereagerow = rownumb(B3_`r',"b")
			loc be3 : disp %4.2f B3_`r'[`whereagerow',`whereagecol']	
			if `be3'==. loc be3=""
		
			loc row="`row' & `be2' & `be3'"
		}
	}
	
	disp " `: variable label `varDep''  `row' \\"
	tex \, `: variable label `varDep''  `row' \\
}

tex \addlinespace
tex \multicolumn{2}{l}{\textbf{B. Number of observations}} \\

loc row="\, All "
forval r=1(1)7  {
	loc row="`row' & `na2_`r'' & `na3_`r'' "
}
tex `row' \\

loc row="\, HBP Aware   "
forval r=1(1)7  {
	loc row="`row' &  & `nb3_`r'' "
}
tex `row' \\

loc row="\, Undetected HBP "
forval r=1(1)7  {
	loc row="`row' &  & `nc3_`r'' "
}
tex `row' \\

loc row="\, Uncontrolled HBP "
forval r=1(1)7  {
	loc row="`row' &  & `nd3_`r'' "
}
tex `row' \\


texdoc close
