clear all
set more off
set matsize 1000

local usuario=c(username)

if "`usuario'"=="ASUS" {
	glo mainFolder = "G:\Mi unidad\HBP SAGE SES gradient comparison"
}

if "`usuario'"=="andro" {
	glo mainFolder = "C:\Users\andro\Google Drive\Salud\SABE\HBP SAGE SES gradient comparison\"
}
if "`usuario'"=="paul.rodriguez" {
	glo mainFolder = "D:\paul.rodriguez\Google Drive\Salud\SABE\HBP SAGE SES gradient comparison\"
}

global raw     "$mainFolder\raw"
global derived "$mainFolder\derived"
global tables  "$mainFolder\tables"
global figures "$mainFolder\images"

********************************************************************************


cap program drop starG
program starG
	syntax [if] [in] , coe(real) ste(real) number(integer)
	
		scalar pval=2*(1-normal( abs(`coe'/`ste' )))
		glo star`number'=""
		if ((pval < 0.1) )  glo star`number' = "^{*}" 
		if ((pval < 0.05) ) glo star`number' = "^{**}" 
		if ((pval < 0.01) ) glo star`number' = "^{***}" 
end


********************************************************************************
* SAGE Regressions v1 (single regression)
********************************************************************************

use "$derived\HBPC_SAGECol_HBP.dta", clear
keep if popatisk!=.
keep if ragey>=60 // Age>=60

//Keep just if a person have values different to missing in controls
keep if Male!=. & ragey!=. & obese!=. &  rsmokev!=. & educL1!=. & educL2!=. & educL3!=. & urban!=. & hwealth!=. & ///
		 undetHBP!=. &  unconHBP!=.


glo controls1 "i.survey#c.Male i.survey#c.ragey y200910"
glo controls2 "$controls1 i.survey#c.obese  i.survey#c.rsmokev"
glo controls3 "$controls2 i.survey#c.educL2 i.survey#c.educL3"
glo controls  "$controls3 i.survey#c.hi_vih i.survey#c.hi_no i.survey#c.urban "

reg sysval i.survey#c.hwealth i.survey $controls3 [pweight = pweight], r cluster(ID_hogar)
	est sto rSAGE_1
* logit models ............................................................
logit undetHBP i.survey#c.hwealth i.survey $controls [pweight = pweight], or cluster(ID_hogar)
	est sto rSAGE_2
margins , dydx(hwealth) at( survey=(1 2 3 4  6 7) ) post // Without Mexico
	est sto rSAGEm_2
	
logit unconHBP i.survey#c.hwealth i.survey $controls  if rhibpe==1 [pweight = pweight], or cluster(ID_hogar)
	est sto rSAGE_3
margins , dydx(hwealth) at( survey=(1 2 3 4  6 7) ) post // Without Mexico
	est sto rSAGEm_3	
	
forval i=1(1)3 {
	logit undetHBP i.survey#c.hwealth i.survey ${controls`i'} [pweight = pweight], or cluster(ID_hogar)
		est sto rxSAGE_2_`i'
	margins , dydx(hwealth) at( survey=(1 2 3 4 5 6 7) ) post
		est sto rxSAGEm_2_`i'
		
	logit unconHBP i.survey#c.hwealth i.survey ${controls`i'}  if rhibpe==1 [pweight = pweight], or cluster(ID_hogar)
		est sto rxSAGE_3_`i'
	margins , dydx(hwealth) at( survey=(1 2 3 4 5 6 7) ) post
		est sto rxSAGEm_3_`i'	
}	
	
* Mlogit models ............................................................
gen     diag=1
replace diag=2 if undetHBP==1
replace diag=3 if unconHBP==1

mlogit diag i.survey#c.hwealth i.survey $controls3 [pweight = pweight], rrr cluster(ID_hogar) base(1)
	est sto rSAGE_4
	
* Unconditional uncontrolled .................................................

logit unconHBP i.survey#c.hwealth i.survey $controls [pweight = pweight], or cluster(ID_hogar)
	est sto rSAGE_5
margins , dydx(hwealth) at( survey=(1 2 3 4  6 7) ) post // Without Mexico
	est sto rSAGEm_5		
	
forval i=1(1)3 {
	logit unconHBP i.survey#c.hwealth i.survey ${controls`i'} [pweight = pweight], or cluster(ID_hogar)
		est sto rxSAGE_5_`i'
	margins , dydx(hwealth) at( survey=(1 2 3 4 5 6 7) ) post
		est sto rxSAGEm_5_`i'	
}		
	
	
logit unconHBP i.survey#c.hwealth i.survey $controls3  [pweight = pweight], or cluster(ID_hogar)
	est sto rSAGE_6
	
////////////////////////////////////////////////////////////////////////////////
// Table A1: alternative models
////////////////////////////////////////////////////////////////////////////////	

esttab rSAGE_1 rxSAGE_2_3 rxSAGE_3_3 rSAGE_6 rSAGE_4 , unstack star(* .1 ** .05 *** .01) se nogaps label

cd "$tables"
esttab rSAGE_1 rxSAGE_2_3 rxSAGE_3_3 rSAGE_6 rSAGE_4 using HBPC_logit ///
	, unstack star(* .1 ** .05 *** .01) se nogaps label ///
	fragment booktabs replace 

////////////////////////////////////////////////////////////////////////////////
// Table 2 (margins)
////////////////////////////////////////////////////////////////////////////////	
	
* Should be similar to this one...
esttab 	rSAGEm_2 rSAGEm_3 , unstack star(* .1 ** .05 *** .01) se nogaps label


cd "$tables"
cap texdoc close
texdoc init HBPC_margins, force replace

loc listaSAGE "China Colombia Ghana India Mexico Russia SouthAfrica"

forval r=1(1)7 {

	loc sage : word `r' of `listaSAGE'

	* *****************************************	
	
	est restore rxSAGEm_2_1
	loc b1  : disp %4.3f  _b[hwealth:`r'._at]
	loc se1 : disp %4.3f _se[hwealth:`r'._at]
	starG , coe(`b1') ste(`se1') number(1)
	
	est restore rxSAGEm_2_2
	loc b2  : disp %4.3f  _b[hwealth:`r'._at]
	loc se2 : disp %4.3f _se[hwealth:`r'._at]
	starG , coe(`b2') ste(`se2') number(2)

	est restore rxSAGEm_2_3
	loc b3  : disp %4.3f  _b[hwealth:`r'._at]
	loc se3 : disp %4.3f _se[hwealth:`r'._at]
	starG , coe(`b3') ste(`se3') number(3)	
	
	if `r'!=5 {  // Mexico is taken out of the list
		loc rr=`r'
		if `r'>5 loc rr=`r'-1 
		est restore rSAGEm_2
		loc b4  : disp %4.3f  _b[hwealth:`rr'._at]
		loc se4 : disp %4.3f _se[hwealth:`rr'._at]
		starG , coe(`b4') ste(`se4') number(4)
	}
	else {
		loc b4=""
		loc se4=""
		glo star4=""
	}
	
	
	* *****************************************
	
	est restore rxSAGEm_3_1
	loc b5  : disp %4.3f  _b[hwealth:`r'._at]
	loc se5 : disp %4.3f _se[hwealth:`r'._at]	
	starG , coe(`b5') ste(`se5') number(5)
	
	est restore rxSAGEm_3_2
	loc b6  : disp %4.3f  _b[hwealth:`r'._at]
	loc se6 : disp %4.3f _se[hwealth:`r'._at]	
	starG , coe(`b6') ste(`se6') number(6)	

	est restore rxSAGEm_3_3
	loc b7  : disp %4.3f  _b[hwealth:`r'._at]
	loc se7 : disp %4.3f _se[hwealth:`r'._at]	
	starG , coe(`b7') ste(`se7') number(7)		
	
	if `r'!=5 {  // Mexico is taken out of the list	
		loc rr=`r'
		if `r'>5 loc rr=`r'-1
		est restore rSAGEm_3
		loc b8  : disp %4.3f  _b[hwealth:`rr'._at]
		loc se8 : disp %4.3f _se[hwealth:`rr'._at]	
		starG , coe(`b8') ste(`se8') number(8)
	}
	else {
		loc b8=""
		loc se8=""
		glo star8=""
	}
	
	disp " `sage' & `b1' $ $star1 $ & `b2' $ $star2 $ & `b3' $ $star3 $ & `b4' $ $star4 $ & `b5' $ $star5 $ & `b6' $ $star6 $ & `b7' $ $star7 $ & `b8' $ $star8 $ \\ "
	disp "        & (`se1')     & (`se2')     & (`se3')     & (`se4')     & (`se5')     & (`se6')     & (`se7')     & (`se8') \\ "
	
	tex  `sage' & `b1' $ $star1 $ & `b2' $ $star2 $ & `b3' $ $star3 $ & `b4' $ $star4 $ & `b5' $ $star5 $ & `b6' $ $star6 $ & `b7' $ $star7 $ & `b8' $ $star8 $ \\
	tex         & (`se1')         & (`se2')         & (`se3')         & (`se4')         & (`se5')         & (`se6')         & (`se7')         & (`se8') \\
}

// N observations

	loc row = "Observations "
	* *****************************************		
	est restore rxSAGEm_2_1
	loc row="`row' & `: disp e(N)'"
	est restore rxSAGEm_2_2
	loc row="`row' & `: disp e(N)'"
	est restore rxSAGEm_2_3
	loc row="`row' & `: disp e(N)'"
	est restore rSAGEm_2
	loc row="`row' & `: disp e(N)'"
	* *****************************************	
	est restore rxSAGEm_3_1
	loc row="`row' & `: disp e(N)'"
	est restore rxSAGEm_3_2
	loc row="`row' & `: disp e(N)'"
	est restore rxSAGEm_3_3
	loc row="`row' & `: disp e(N)'"
	est restore rSAGEm_3
	loc row="`row' & `: disp e(N)'"
	
	tex \addlinespace
	tex `row' \\


texdoc close


////////////////////////////////////////////////////////////////////////////////
// Table 3: uncontrolled, conditional on diagnosis
////////////////////////////////////////////////////////////////////////////////

cd "$tables"
cap texdoc close
texdoc init HBPC_margins_unconditional, force replace

loc listaSAGE "China Colombia Ghana India Mexico Russia SouthAfrica"

forval r=1(1)7 {

	loc sage : word `r' of `listaSAGE'
	
	* *****************************************
	
	est restore rxSAGEm_5_1
	loc b5  : disp %4.3f  _b[hwealth:`r'._at]
	loc se5 : disp %4.3f _se[hwealth:`r'._at]	
	starG , coe(`b5') ste(`se5') number(5)
	
	est restore rxSAGEm_5_2
	loc b6  : disp %4.3f  _b[hwealth:`r'._at]
	loc se6 : disp %4.3f _se[hwealth:`r'._at]	
	starG , coe(`b6') ste(`se6') number(6)	

	est restore rxSAGEm_5_3
	loc b7  : disp %4.3f  _b[hwealth:`r'._at]
	loc se7 : disp %4.3f _se[hwealth:`r'._at]	
	starG , coe(`b7') ste(`se7') number(7)		
	
	if `r'!=5 {  // Mexico is taken out of the list	
		loc rr=`r'
		if `r'>5 loc rr=`r'-1
		est restore rSAGEm_5
		loc b8  : disp %4.3f  _b[hwealth:`rr'._at]
		loc se8 : disp %4.3f _se[hwealth:`rr'._at]	
		starG , coe(`b8') ste(`se8') number(8)
	}
	else {
		loc b8=""
		loc se8=""
		glo star8=""
	}
	
	disp " `sage' & `b5' $ $star5 $ & `b6' $ $star6 $ & `b7' $ $star7 $ & `b8' $ $star8 $ \\ "
	disp "        & (`se5')         & (`se6')         & (`se7')         & (`se8') \\ "
	
	tex  `sage' & `b5' $ $star5 $ & `b6' $ $star6 $ & `b7' $ $star7 $ & `b8' $ $star8 $ \\
	tex         & (`se5')         & (`se6')         & (`se7')         & (`se8') \\
}

// N observations

	loc row = "Observations "
	* *****************************************	
	est restore rxSAGEm_5_1
	loc row="`row' & `: disp e(N)'"
	est restore rxSAGEm_5_2
	loc row="`row' & `: disp e(N)'"
	est restore rxSAGEm_5_3
	loc row="`row' & `: disp e(N)'"
	est restore rSAGEm_5
	loc row="`row' & `: disp e(N)'"
	
	tex \addlinespace
	tex `row' \\


texdoc close



