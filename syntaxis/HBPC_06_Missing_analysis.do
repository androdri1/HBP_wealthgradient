clear all
set more off
set matsize 1000

* Needs: ssc install mdesc
*ssc install outtable

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

**************************
* Count of missing values 
**************************

use "$derived\HBPC_SAGECol_HBP.dta", clear
keep if popatisk!=.
keep if ragey>=60 // Age>=60

// Count number of missings
glo var_interes Male  ragey obese rsmokev educL1  educL2 educL3 urban hwealth rhibpe undetHBP  unconHBP


* Dejar labels en las filas
local rows 
foreach var of glo var_interes {
local this = strtoname("`: variable label `var''") 
local rows `rows' `this'
}


local num : word count $var_interes
dis `num'
mat TT = J(`num' , 3, .)
mat colname TT =  	"Missing" "Total" "Percent Missing"
mat rownames TT =  `rows'


local i 0
foreach variables of glo var_interes {
	local ++i
	mdesc `variables'
	mat TT[`i',1]=r(miss)
	mat TT[`i',2]=r(total)
	mat TT[`i',3]=round(r(percent), .01)
}

outtable using "$tables/Missings_count", replace mat(TT) caption(Count of missings values) nobox clabel(tab:missings_count) f(%15.0fc %15.0fc %15.2fc)

***************************************
* Detection with regression analysis ** 
***************************************
glo controles Male  ragey obese rsmokev  educL2 educL3 urban y200910 i.survey

foreach var_principales in hwealth undetHBP  unconHBP {
	gen `var_principales'_missing=(`var_principales'==.)
}

est drop _all
logit hwealth_missing $controles, cluster(ID_hogar)
margins, dydx($controles) post
est store r1
logit undetHBP_missing $controles, cluster(ID_hogar)
margins, dydx($controles) post
est store r2
logit unconHBP_missing $controles, cluster(ID_hogar)
margins, dydx($controles) post
est store r3

esttab r1 r2 r3 , star(* .1 ** .05 *** .01) se label

cd "$tables"
esttab r1 r2 r3 using Missings_detection_probit ///
	, star(* .1 ** .05 *** .01) se nogaps label ///
	fragment booktabs replace 

