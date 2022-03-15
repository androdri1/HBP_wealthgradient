clear all
set more off

local usuario=c(username)

if "`usuario'"=="andro" {
	glo mainFolder = "C:\Users\andro\Google Drive\Salud\Bases_Internacionales\IC_SABE\HBP SAGE SES gradient comparison\"
}
if "`usuario'"=="paul.rodriguez" {
	glo mainFolder = "D:\paul.rodriguez\\Google Drive\Salud\SABE\HBP SAGE SES gradient comparison\"
}

if "`usuario'"=="maria" {
	glo mainFolder = "C:\Users\maria\Google Drive\HBP SAGE SES gradient comparison\"
}

global raw     "$mainFolder\raw"
global derived "$mainFolder\derived"
global tables  "$mainFolder\tables"
global figures "$mainFolder\images"


****************************************************************************
**** Wealth Index derivation (Assets factor analysis) **********************
****************************************************************************
cd "$raw"
use Cap3.dta, clear
merge 1:1 NumIdentificador using "Cap1.dta", nogen 

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* Option 21 Wealth index: PCA

replace P301=. if P301==0
tab P301, gen(P301_)

replace P302=. if P302==0
tab P302, gen(P302_)

replace P303=. if P303==0
tab P303, gen(techo_)

replace P304=. if P304==0
tab P304, gen(pared_ext_)


replace P305=. if P305==0
tab P305, gen(pared_int_)

replace P306=. if P306==0
tab P306, gen(pisos_)


tab ESTRATO_2, gen(ESTRATO_Nivel_)


factor P301_1 P301_2 P301_3 P301_4 P301_5 P301_6 ///
		P302_1 P302_2 P302_3 P302_4 P302_5 P302_6 P302_7 P302_8 ///
		techo_1 techo_2 techo_3 techo_4 techo_5 techo_6 techo_7 ///
		pared_ext_1 pared_ext_2 pared_ext_3 pared_ext_4 pared_ext_5 pared_ext_6 pared_ext_7 pared_ext_8 pared_ext_9 ///
		pared_int_1 pared_int_2 pared_int_3 pared_int_4 pared_int_5 pared_int_6 pared_int_7 pared_int_8 pared_int_9 ///
		pisos_1 pisos_2 pisos_3 pisos_4 pisos_5 pisos_6 pisos_7 ///
		P326_1 P326_2 P326_3 P326_4 ///
		ESTRATO_Nivel_1 ESTRATO_Nivel_2 ESTRATO_Nivel_3 ESTRATO_Nivel_4 ESTRATO_Nivel_5 ///
		P311 P315_17 P315_16 P315_14 P315_12 P315_11 P315_10 P315_8 P315_7 P315_6 P315_4 P315_3 P315_2 P315_1, pcf factors(1)
predict wealth_index_PC

label variable P311 "¿Tiene cocina?"
label variable P315_1 "Radio"
label variable P315_2 "Televisión"
label variable P315_3 "Equipo de sonido"
label variable P315_4 "DVD"
label variable P315_6 "Computador"
label variable P315_7 "Teléfono celular"
label variable P315_8 "Nevera"
label variable P315_10 "Lavadora"
label variable P315_11 "Horno eléctrico/gas"
label variable P315_12 "Horno microondas"
label variable P315_13 "Aspiradora/brilladora"
label variable P315_14 "Calentador eléctrico/ ducha electrica"
label variable P315_15 "Aire acondicionado"
label variable P315_16 "Internet"
label variable P315_17 "Televisión por cable"
label variable P301_1 "Casa"
label variable P301_2 "Apartamento"
label variable P301_3 "Cuarto inquilinato"
label variable P301_4 "Cuarto en otro tipo de estructura"
label variable P301_5 "Vivienda indígena"
label variable P301_6 "Embarcación, recurso natural, puente, etc"
label variable P302_1 "Arriendo o subarriendo"
label variable P302_2 "Vivienda propia pagando (Hipoteca)"
label variable P302_3 "Vivienda propia pagada"
label variable P302_4 "Vivienda en usufructo"
label variable P302_5 "Vivienda en empeño"
label variable P302_6 "Posesión sin título (Ocupante de hecho)"
label variable P302_7 "Propiedad Colectiva"
label variable P302_8 "Vivienda propiedad de un familiar o un tercero"
label variable wealth_index_PC "Indice de riqueza con electrodomésticos, características vivienda, estrato, etc"

* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* Option 2 Wealth index: PCA

pca P307 P308 P311 P315_2 P315_3 P315_6 P315_7 P315_8 P315_10 P315_9 P315_11 P315_12 P315_14 P315_16 P315_17 P326_1 P326_2 P326_3 P326_4 P327 P328 P329
predict wealth_index_PC2

tempfile assets
save `assets'

****************************************************************************
**** PREPARACIÓN BASE A TRABAJAR *******************************************
****************************************************************************
cd "$raw"
use "baseSABE_HBP.dta", clear

drop asset_index // Versión vieja, está desactualizada la variable
drop P121 //No se sabe si 1 es mujer o hombre
drop P231 //No se identificaron bien a los que no trabajaban 


********************************************************************************

merge 1:1 NumIdentificador using `assets', nogen
merge 1:1 NumIdentificador using "$raw\Cap1.dta", nogen
gen educ_años=P203 
sum wealth_index_PC
gen hwealth= (wealth_index_PC+(-r(min)) )/ ( r(max) -r(min) )
label variable hwealth "Wealth Index"
gen ragey=P122EDAD
label var ragey "Age"
gen ragey2=ragey^2
label variable ragey2 "Age squared"
gen Male=1 if P121==1
replace Male=0 if P121==2
label var Male "Male"

gen Married=1 if P124==1
replace Married=0 if P124==2 | P124==3 | P124==4 | P124==5

label variable rhibpe "Self reported hypertension"
//Percepción de salud atoreportada
*P807 En general, ¿diría usted que su salud en los últimos 30 días ha sido….?
gen good_health=1 if P807==1 | P807==2
replace good_health=0 if P807==3 | P807==4 | P807==5

encode RegionUT, gen(Region)
label define Region 1 "Atlántico", modify
label define Region 2 "Oriental", modify
label define Region 3 "Orinoquia y Amazonia", modify
label define Region 4 "Bogotá", modify
label define Region 5 "Central", modify
label define Region 6 "Pacífica", modify

gen obese=1 if rbmi>=30
replace obese=0 if rbmi<30

label variable obese "Obese (BMI $ \geq$ 30)"
label variable rsmokev "Smoke ever"
label variable rdrinkd "Number days/week drinks"
label variable rvigact "Vigorous sports/exercise 3+/week" 
label variable rwalksa "Some difficulty-Walking several blocks"

merge 1:1 NumIdentificador using "$raw\Cap2.dta", nogen
gen Retired=1 if P230==1
replace Retired=0 if P230==2
replace Retired=0 if P231==1 & P230==0

*Education levels
gen educ_label="Less than primary" if P204==1 | P204==2 // >Primary
replace educ_label="Primary" if P204==3 | P204==4 // Primary
replace educ_label="Secondary" if P204==5 | P204==6 | P204==8 // Secundary
replace educ_label="Technical" if P204==7
replace educ_label="Professional" if P204==9 | P204==10 
replace educ_label="Postgraduate" if P204==11

encode educ_label, gen(educ_label2)
drop educ_label
rename educ_label2 educ_label

gen educL1 = educ_label==1 if educ_label!=.
gen educL2 = educ_label==3 if educ_label!=.
gen educL3 = educ_label==2 | educ_label==4 | educ_label==5 |  educ_label==6 if educ_label!=.
label var educL1 "Education: Below Primary"
label var educL2 "Education: Primary"
label var educL3 "Education: Above Primary"

*********** Blood Pressure variables **************************************

drop P1201T1BD P1201T1BI P1201T2BD P1201T2BI P1201T3BD P1201T3BI
merge 1:1 NumIdentificador using "$raw\Cap12.dta", nogen

foreach varo of varlist P1201T?B? P1201T?B?_1 {
	replace `varo'=. if `varo'==999 | `varo'==8888 | `varo'==0
}

replace P1201T1BI=. if P1201T1BI==999 | P1201T1BI==8888 | P1201T1BI==0
replace P1201T2BD=. if P1201T2BD==999 | P1201T2BD==8888 | P1201T2BD==0
replace P1201T2BI=. if P1201T2BI==999 | P1201T2BI==8888 | P1201T2BI==0
replace P1201T3BD=. if P1201T3BD==999 | P1201T3BD==8888 | P1201T3BD==0
replace P1201T3BI=. if P1201T3BI==999 | P1201T3BI==8888 | P1201T3BI==0
		
egen sysval=rowmean(P1201T2BD   P1201T3BD   P1201T2BI   P1201T3BI)
egen diaval=rowmean(P1201T2BD_1 P1201T3BD_1 P1201T2BI_1 P1201T3BI_1)
label var sysval "Systolic BP (mmHG)"
label var diaval "Diastolic BP (mmHG)"

gen popatisk = (rhibpe==1 | sysval>=140 | diaval>=90) if sysval!=. & rhibpe!=.
label var popatisk "Population at risk: aware of their HBP, or with Sys>140 mmHg or Dias>90 mmHg"
		
gen undetHBP = (rhibpe==0 & (sysval>=140  | diaval>=90) )  if popatisk==1
gen unconHBP = (rhibpe==1 & (sysval>=140  | diaval>=90) )  if popatisk==1 

label variable undetHBP "Undetected HBP"
label variable unconHBP "Uncontrolled HBP"

egen hi_vih= rowmax(P141A_1 P141A_2 P141A_3 P141A_4) // Poliza de hosp y cirugia, prepagada, complementaria, otra (estudiantes, ambulancia)
replace hi_vih=0 if P141==2 | P141==5 // Subsidiado o no afiliado
replace hi_vih=. if P141==9 | P141==9 // No sabe, no responde
label var hi_vih "Voluntary Health Insurance (VIH)"


gen hi_no= P141==5 if P141<8
label var hi_no "No health insurance"

recode P104  (2=0) (8 9 =.), gen(urban)
label var urban "Lives in urban area"

gen drugTherapy = P811_1==1 if popatisk==1
label var drugTherapy "Treated with drug therapy"

gen Controlled150= sysval<150 & diaval<90 & rhibpe==1 if popatisk==1
gen Controlled140= sysval<140 & diaval<90 & rhibpe==1 if popatisk==1
label var rhibpe "HBP Aware"
label var Controlled150 "Controlled (Systolic BP $ <$ 150)"
label var Controlled140 "Controlled (Systolic BP $ <$ <140)"

rename rweight pweight

gen survey=10

********************************************************************************

glo controls Male ragey hwealth obese  rsmokev educL1 educL2 educL3
keep NumIdentificador rhibpe Controlled150 Controlled140 popatisk undetHBP unconHBP sysval diaval  $controls pweight survey Region ///
		hi_vih hi_no urban 

********************************************************************************
preserve
	collapse pop_vih=hi_vih pop_nohi=hi_no , by(Region)
	label var pop_vih  "Proprotion with VHI"
	label var pop_nohi "Proportion with no health insurance"	
	
	tempfile aggregateD
	save `aggregateD'
restore
merge n:1 Region using `aggregateD' , nogen
gen q0105b=string(Region)  // Nivel de agregacion 1 del SAGE

save "$derived/HBPC_SABE_Corregida.dta", replace
