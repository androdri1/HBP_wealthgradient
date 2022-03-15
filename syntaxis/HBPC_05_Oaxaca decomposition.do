* Needs: ssc install egenmore
*        ssc install oaxaca
*        ssc install regsave
*		ssc install blindschemes, replace all
clear all
set more off

local usuario=c(username)

if "`usuario'"=="ASUS" {
	global directorio "G:\Mi unidad\HBP SAGE SES gradient comparison"
}
if "`usuario'"=="paul.rodriguez" {
	glo directorio = "D:\paul.rodriguez\Google Drive\Salud\SABE\HBP SAGE SES gradient comparison\"
}

global derived "$directorio\derived"
global images  "$directorio\images"
global tables  "$directorio\tables"
global oaxaca  "$directorio\Oaxaca"

cd "$derived"

foreach variable_HBP in undetHBP unconHBP {
foreach poor in Pobre_Quintil1 {
	use HBPC_SAGECol_HBP.dta, clear
	* For testing purposes....
	*loc variable_HBP = "undetHBP"
	*loc poor="Pobre_Quintil1"

	keep if ragey>=60

	//Keep just if a person have values different to missing in controls
	keep if Male!=. & ragey!=. & obese!=. &  rsmokev!=. & educL1!=. & educL2!=. & educL3!=. & urban!=. & hwealth!=. & sysval!=. & diaval!=.


	//Quintiles
	bys survey: egen quintil_hwealth=xtile(hwealth), nq(5)

	*Utilizando como medida de pobraza estar en el primer quintil
	gen Pobre_Quintil1=0 if hwealth!=.
	bys survey: replace Pobre_Quintil1=1 if quintil_hwealth==1

	// Oaxaca
	forvalue Pais=1(1)7 {
		local nom_survey 
		if `Pais'==1 local nom_survey="China" 
		if `Pais'==2 local nom_survey="Colombia" 
		if `Pais'==3 local nom_survey="Ghana"
		if `Pais'==4 local nom_survey="India" 
		if `Pais'==5 local nom_survey="Mexico" 
		if `Pais'==6 local nom_survey="Russia"
		if `Pais'==7 local nom_survey="South_Africa"

		tempfile coef_`nom_survey'

		preserve
		keep if survey==`Pais'
		loc cont=""
		if (survey==1 | survey ==6) loc cont y200910
		loc conda=""
		if ("`variable_HBP'"=="unconHBP") loc conda=" & rhibpe==1 "
		oaxaca `variable_HBP' ragey Male rsmokev obese urban educL2 educL3 `cont' if 1==1 `conda', by(`poor') pooled relax
		regsave using `coef_`nom_survey'', replace
		restore
	}

	//Merge
	forvalue Pais=1(1)7 {
		local nom_survey 
		if `Pais'==1 local nom_survey="China" 
		if `Pais'==2 local nom_survey="Colombia" 
		if `Pais'==3 local nom_survey="Ghana"
		if `Pais'==4 local nom_survey="India" 
		if `Pais'==5 local nom_survey="Mexico" 
		if `Pais'==6 local nom_survey="Russia"
		if `Pais'==7 local nom_survey="South_Africa"

		preserve
		use `coef_`nom_survey'', clear
		foreach variables in * {
			rename `variables' `variables'_`nom_survey'
			rename var_`nom_survey' compare_groups
			save `coef_`nom_survey'', replace
		}
		restore
	}

	use `coef_China', replace
	merge 1:1 compare_groups using `coef_Colombia', nogen
	merge 1:1 compare_groups using `coef_Ghana', nogen
	merge 1:1 compare_groups using `coef_India', nogen
	merge 1:1 compare_groups using `coef_Mexico', nogen
	merge 1:1 compare_groups using `coef_Russia', nogen
	merge 1:1 compare_groups using `coef_South_Africa', nogen
	keep compare_groups coef*

	reshape long coef_, i(compare_groups) j(country) string
	split compare_groups, p(:)
	rename compare_groups2 variable
	cap drop compare_groups2
	keep if compare_groups1=="explained" | compare_groups=="overall:difference" | compare_groups=="overall:explained" | compare_groups=="overall:unexplained"
	replace country="South Africa" if country=="South_Africa"
	encode country, gen(Country)
	drop country
	cap drop compare_groups compare_groups1

	reshape wide coef_, i(Country) j(variable) string 

	//Dividir en categorías los coeficientes
	gen behavioral_risks=coef_rsmokev+coef_obese
	gen demographic_risk=coef_Male+coef_ragey
	gen education=coef_educL2+coef_educL3

	//Gráfica con categorías de Behavioral risks, Demographic risks, Urban and Unexplained component
	local legend_ejeY
	if "`variable_HBP'"~="undetHBP" local legend_ejeY=`"Proportion uncontrolled HBP"'
	if "`variable_HBP'"~="unconHBP" local legend_ejeY=`"Proportion undetected HBP"'
	 
	*set scheme plotplainblind    
	graph bar behavioral_risks demographic_risk education coef_urban coef_unexplained, over(Country, label(angle(forty_five) labsize(small))) ylabel(,labsize(small)) stack graphregion(color(white)) bgcolor(white) legend(label(1 "Behavioral risks") label(2 "Demographic risks") label(3 "Education") label (4 "Urban") label(5 "Unexplained component") row(2)) legend(region(lcolor(white))) name(Oaxaca_`poor'`variable_HBP', replace) ytitle(`legend_ejeY') scheme(Plotplainblind) ylabel(-0.25(0.05)0.2)
}
}

grc1leg Oaxaca_Pobre_Quintil1undetHBP  Oaxaca_Pobre_Quintil1unconHBP,  graphregion(color(white)) ycommon
graph play "$oaxaca\total_difference_graph"
graph export "$oaxaca\Oxaca_decomposition.pdf", as(pdf) replace


//Tablas con los resultados de las regresiones ................................................

foreach variable_HBP in undetHBP unconHBP {
	use HBPC_SAGECol_HBP.dta, clear
	//Keep just if a person have values different to missing in controls
	keep if Male!=. & ragey!=. & obese!=. &  rsmokev!=. & educL1!=. & educL2!=. & educL3!=. & urban!=. & hwealth!=. & sysval!=. & diaval!=.

	bys survey: egen quintil_hwealth=xtile(hwealth), nq(5) //generar quintiles
	*Utilizando como medida estar en el primer quintil
	gen Pobre_Quintil1=0 if hwealth!=.
	bys survey: replace Pobre_Quintil1=1 if quintil_hwealth==1

	
	
	est drop _all
	forvalue Pais=1(1)7 {
		loc cont=""
		if (survey==1 | survey ==6) loc cont y200910
		loc conda=""
		if ("`variable_HBP'"=="unconHBP") loc conda=" & rhibpe==1 "
		oaxaca `variable_HBP' ragey Male rsmokev obese urban educL2 educL3 `cont' if survey==`Pais' `conda' , by(Pobre_Quintil1) pooled cluster(ID_hogar) relax
		est store r`Pais'
	}
	esttab r* using "$oaxaca\oaxaca_`variable_HBP'.tex", star(* .1 ** .05 *** .01) se nogaps label	///
	fragment booktabs replace 
	
	esttab r* using "$oaxaca\oaxaca_`variable_HBP'.csv", star(* .1 ** .05 *** .01) se nogaps label	///
	fragment booktabs replace 

}

*****************************************************************************************************
************** DIFERENCIANDO ENTRE RURAL Y URBANO ***************************************************
*****************************************************************************************************
cd "$derived"
foreach ubicacion in Rural Urban {
foreach variable_HBP in unconHBP undetHBP {

	use HBPC_SAGECol_HBP.dta, clear
	//Keep just if a person have values different to missing in controls
	keep if Male!=. & ragey!=. & obese!=. &  rsmokev!=. & educL1!=. & educL2!=. & educL3!=. & urban!=. & hwealth!=. & sysval!=. & diaval!=.

	* Crear variable de rural
	cap gen Rural=(urban==0) if urban!=.
	rename urban Urban

	keep if `ubicacion'==1

	//Quintiles
	bys survey: egen quintil_hwealth=xtile(hwealth), nq(5)

	*Utilizando como medida estar en el primer quintil
	gen Pobre_Quintil1=0 if hwealth!=.
	bys survey: replace Pobre_Quintil1=1 if quintil_hwealth==1

	// Oaxaca
	forvalue Pais=1(1)7 {
		local nom_survey 
		if `Pais'==1 local nom_survey="China" 
		if `Pais'==2 local nom_survey="Colombia" 
		if `Pais'==3 local nom_survey="Ghana"
		if `Pais'==4 local nom_survey="India" 
		if `Pais'==5 local nom_survey="Mexico" 
		if `Pais'==6 local nom_survey="Russia"
		if `Pais'==7 local nom_survey="South_Africa"

		tempfile coef_`nom_survey'
		preserve
		keep if survey==`Pais'
		loc cont=""
		if (survey==1 | survey ==6) loc cont y200910	
		loc conda=""
		if ("`variable_HBP'"=="unconHBP") loc conda=" & rhibpe==1 "
		cap oaxaca `variable_HBP' ragey Male rsmokev obese educL2 educL3 `cont' if 1==1 `conda', by(Pobre_Quintil) pooled relax
		cap regsave using "`coef_`nom_survey''", replace
		restore
	}

	//Merge
	forvalue Pais=1(1)7 {
		local nom_survey 
		if `Pais'==1 local nom_survey="China" 
		if `Pais'==2 local nom_survey="Colombia" 
		if `Pais'==3 local nom_survey="Ghana"
		if `Pais'==4 local nom_survey="India" 
		if `Pais'==5 local nom_survey="Mexico" 
		if `Pais'==6 local nom_survey="Russia"
		if `Pais'==7 local nom_survey="South_Africa"

		preserve
		use "`coef_`nom_survey''", clear
		foreach variables in * {
			rename `variables' `variables'_`nom_survey'
			rename var_`nom_survey' compare_groups
			save "`coef_`nom_survey''", replace
		}
		restore
	}

	*tempfile Resultados_Oaxaca_`poor'`variable_HBP'
	use "`coef_China'", replace
	merge 1:1 compare_groups using "`coef_Colombia'", nogen
	merge 1:1 compare_groups using "`coef_Ghana'", nogen
	merge 1:1 compare_groups using "`coef_India'", nogen
	merge 1:1 compare_groups using "`coef_Mexico'", nogen
	merge 1:1 compare_groups using "`coef_Russia'", nogen
	merge 1:1 compare_groups using "`coef_South_Africa'", nogen
	*save "$oaxaca\`Resultados_Oaxaca_`poor'`variable_HBP''.dta", replace
	keep compare_groups coef*

	reshape long coef_, i(compare_groups) j(country) string
	split compare_groups, p(:)
	rename compare_groups2 variable
	cap drop compare_groups2
	keep if compare_groups1=="explained" | compare_groups=="overall:difference" | compare_groups=="overall:explained" | compare_groups=="overall:unexplained"
	replace country="South Africa" if country=="South_Africa"
	encode country, gen(Country)
	drop country
	cap drop compare_groups compare_groups1

	reshape wide coef_, i(Country) j(variable) string 

	//Dividir en categorías los coeficientes
	gen behavioral_risks=coef_rsmokev+coef_obese
	gen demographic_risk=coef_Male+coef_ragey
	gen Education=coef_educL2+coef_educL3

	//Gráfica con categorías de Behavioral risks, Demographic risks, Urban and Unexplained component
	local legend_ejeY
	if "`variable_HBP'"~="undetHBP" local legend_ejeY=`"Proportion uncontrolled HBP"'
	if "`variable_HBP'"~="unconHBP" local legend_ejeY=`"Proportion undetected HBP"'
	 
	*set scheme plotplainblind    
	graph bar behavioral_risks demographic_risk Education coef_unexplained, over(Country, label(angle(forty_five) labsize(vsmall))) ylabel(,labsize(small)) stack graphregion(color(white)) bgcolor(white) legend(label(1 "Behavioral risks") label(2 "Demographic risks") label(3 "Education") label(4 "Unexplained component") row(2)) legend(region(lcolor(white))) ytitle(`legend_ejeY', size(vsmall))  name(`variable_HBP'`ubicacion', replace) title(`ubicacion', size(small)) scheme(Plotplainblind) ylabel(-0.25(0.05)0.2) ylabel(,labsize(vsmall)) legend(size(vsmall))

	*graph export "$oaxaca\Oaxaca_`variable_HBP'`ubicacion'.pdf", as(pdf) replace

	use HBPC_SAGECol_HBP.dta, clear
}
}

// Combinar gráficas
grc1leg undetHBPRural undetHBPUrban unconHBPRural unconHBPUrban,  graphregion(color(white)) ycommon rows(2) name(ALL_GRAPHS, replace)
graph display ALL_GRAPHS, ysize(15) xsize(13)
graph play "$oaxaca\total_difference_graph_urban_rural"
graph export "$oaxaca\Differences_between_urban_rural.pdf", as(pdf) replace
