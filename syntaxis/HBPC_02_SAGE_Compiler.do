clear all
set more off


local usuario=c(username)

if "`usuario'"=="andro" {
	glo mainFolder = "C:\Users\andro\Google Drive\Salud\SABE\HBP SAGE SES gradient comparison\"
}
if "`usuario'"=="paul.rodriguez" {
	glo mainFolder = "D:\paul.rodriguez\\Google Drive\Salud\SABE\HBP SAGE SES gradient comparison\"
}

if "`usuario'"=="maria" {
	glo mainFolder = "C:\Users\maria\Google Drive\HBP SAGE SES gradient comparison"
}

global sage    "$mainFolder\sage"
global raw     "$mainFolder\raw"
global derived "$mainFolder\derived"
global tables  "$mainFolder\tables"
global figures "$mainFolder\images"


********************************************************************************
************ Esdadísticas descriptivas *****************************************
********************************************************************************

*******************************************************************
*Table 1, Panel B: Means table per country *************************
*******************************************************************

cd "$sage"

clear
set obs 1
gen v0=1
tempfile filo
save `filo'

loc r=1
foreach country  in China Ghana india Mexico Russia SouthAfrica  {

	use "`country'INDData.dta", clear
	//recode q5002 (2=0) (8=.), gen(gotCare)	
	
	recode q0411 (2 3 = 1) (1 4 8 9=0) , gen(pop_vih)
	recode q0411 (4 = 1) (1 2 3 4 8 9=0) , gen(pop_nohi)

	foreach varDep in 	q5018 q5019 q5020 q5021 q5022 q5023 q5024  /// // Outpatient
						q5039 q5040 q5041 q5042 q5043 q5044 q5045 ///  // Inpatient
						q5053 { // general
		recode `varDep' (8 9 =.) (1=5) (2=4) (4=2) (1=5) // rescale it	
	}
	egen centredness = rowmean(	q5018 q5019 q5020 q5021 q5022 q5023 q5024 ///
								q5039 q5040 q5041 q5042 q5043 q5044 q5045 ///
								q5053) // Time waited,respect, explanation, confidentiality, ease of finding, cleanliness and satisfaction
	
	glo aggVars pop_vih pop_nohi centredness
	collapse (mean) $aggVars , by(q0105b) // gotCare
	
	//label var gotCare  "Proportion with access" No variation
	label var pop_vih  "Proprotion with VHI"
	label var pop_nohi "Proportion with no health insurance"	
	label var centredness "Mean patient-centredness"

	tempfile aggregateD
	save `aggregateD'
	
	* **************************************************************************
	** Pegar wealth_index
	use "`country'INDData.dta", clear
	gen hhid=substr(id,1,8)
	merge n:1 hhid using "wealth_index_`country'.dta", keep(match) nogen
	merge n:1 hhid using "`country'HHData.dta", keep(match) nogen
	merge n:1 q0105b using `aggregateD', keep(match) nogen
	
	** Pegar wealth index alternativo
	merge n:1 hhid using "$sage\Wealth_index_alternativo.dta", keep(match master)
	
	* Filtrar edad
	keep if q1011>=50 // Age>=50
	sum wealth_index
	gen hwealth= (wealth_index+(-r(min)) )/ ( r(max) -r(min) )

	gen     Male = q0406==1 if q0406!=. // Opcion de pregunta 2: HH roster
	replace Male = q1009==1 if q1009!=. // Opcion de pregunta 1: quest indivi
	label var Male "Male"
	
	rename q1011 ragey
	replace ragey=q0407 if q0407!=.
	label var ragey "Age"
	keep if ragey>=50
	gen rsmokev = q3001 ==1 if q3001==1 | q3001==2
	label var rsmokev "Smoke ever"
	
	* Opción de pregunta 1: quest indivi..........
	gen educL1 = q1016==0 | q1016==1 if q1016!=. & q1016!=8
	gen educL2 = q1016==2 if q1016!=. & q1016!=8
	gen educL3 = q1016==3 | q1016==4 | q1016==5 | q1016==6 if q1016!=. & q1016!=8
	
	* Opción de pregunta 2: HH roster..........
	replace educL1 = (q0409==0) | (q0409==1) 	if q0409!=. &  educL1==.
	replace educL2 = (q0409==2) 				if q0409!=. &  educL2==.
	replace educL3 = ((q0409>=3) & (q0409<8))  	if q0409!=. &  educL3==.
	
	
	label var educL1 "Education: Below Primary"
	label var educL2 "Education: Primary"
	label var educL3 "Education: Above Primary"	
	
	gen BMI= q2507/( (q2506/100)^2)
	gen obese = BMI>=30 if BMI!=.
	label variable obese "Obese (BMI $ \geq$ 30)"
	
	recode q0411 (2 3 = 1) (1 4 8 9=0) , gen(hi_vih)
	label var hi_vih "Voluntary Health Insurance (VIH)"
	
	recode q0411 (4 = 1) (1 2 3 4 8 9=0) , gen(hi_no)
	label var hi_no "No health insurance"
	
	recode q0104 (2=0) (8 9 =.), gen(urban)
	label var urban "Lives in urban area"
	
	gen rhibpe=.
	replace rhibpe=0 if q4060==2
	replace rhibpe=1 if q4060==1
	label var rhibpe "HBP Aware"
	
	replace q2502_s=. if q2502_s<50
	replace q2503_s=. if q2503_s<50

	replace q2502_d=. if q2502_d <50
	replace q2503_d=. if q2503_d <50

	gen sysval=((q2502_s+q2503_s)/2)
	replace sysval=q2502_s if "`country'"=="Mexico" // For Mexico there is no third systolic BP measurement
	label var sysval "Systolic BP (mmHg)"
	
	gen diaval=((q2502_d+q2503_d)/2)
	replace diaval=q2502_d if "`country'"=="Mexico"  // For Mexico there is no third systolic BP measurement
	label var diaval "Diastolic BP (mmHg)"	

	*gen popatisk = (rhibpe==1 | sysval>=140) if sysval!=. & rhibpe!=.
	*label var popatisk "Population at risk: aware of their HBP, or with Sys>140 mmHg"
	
	gen popatisk = (rhibpe==1 | sysval>=140 | diaval>=90) if sysval!=. & rhibpe!=.
	label var popatisk "Population at risk: aware of their HBP, or with Sys>140 mmHg or Dias>90 mmHg"
		
*	gen undetHBP = (rhibpe==0 & (sysval>=140) )  if popatisk==1
*	gen unconHBP = (rhibpe==1 & (sysval>=140) )  if popatisk==1 
	gen undetHBP = (rhibpe==0 & (sysval>=140  | diaval>=90) )  if popatisk==1
	gen unconHBP = (rhibpe==1 & (sysval>=140  | diaval>=90) )  if popatisk==1 

	label variable undetHBP "Undetected HBP"
	label variable unconHBP "Uncontrolled HBP"

	
	*gen drugTherapy = P811_1==1 if popatisk==1
	*label var drugTherapy "Treated with drug therapy"

	gen Controlled150  = sysval<150 & diaval<90 & rhibpe==1 if popatisk==1
	gen Controlled140  = sysval<140 & diaval<90 & rhibpe==1 if popatisk==1
	label var rhibpe "HBP Aware"
	label var Controlled150   "Controlled (Systolic BP $ <$ 150 and Diastolic BP $ <$ 90)"
	label var Controlled140   "Controlled (Systolic BP $ <$ 140 and Diastolic BP $ <$ 90)"
	
	
	* q2505 q2507 q2504 q2506
	gen BMIval= q2507 / ( q2506/100 )^2
	label var BMIval "BMI"
	
	label var hwealth "Wealth index"
	
	* ................................................................
	
	glo controls Male ragey hwealth obese  rsmokev educL1 educL2 educL3 wealth_index_alter
	keep 	q0006_yyyy q0002 rhibpe Controlled150 Controlled140  ///
			popatisk undetHBP unconHBP sysval diaval /// // 			popatisk_v2 undetHBP_v2 unconHBP_v2  ///
			q2000 q7527 ///
			$controls pweight q0105b ///
			hi_vih hi_no urban income quintile_c $aggVars
	gen survey=`r'
	

	append using `filo'
	save `filo', replace
	loc r= `r'+1		
	
}
append using "$derived/HBPC_SABE_Corregida.dta"

recode survey (10=2)  (2=3) (3=4) (4=5) (5=6) (6=7)

label define survey 1 "China" 2 "Colombia" 3 "Ghana" 4 "India" 5 "Mexico" 6 "Russia" 7 "South Africa"
label values survey survey
drop if v0==1
drop v0

gen ID_hogar=q0002
replace ID_hogar=NumIdentificador if survey==2 // Colombia

replace q0006_yyyy=2015 if survey==2
rename q0006_yyyy year
gen y200708 = year==2007 | year==2008
gen y200910 = year==2009 | year==2010
gen y2015 = year==2015
label var y200708 "Survey year: 2007/08"
label var y200910 "Survey year: 2009/10"
label var y2015   "Survey year: 2015"

save "$derived\HBPC_SAGECol_HBP.dta", replace