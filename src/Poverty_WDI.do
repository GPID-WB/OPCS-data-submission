********************************************************************************
/*
DOWNLOAD POVERTY AT $2.15/DAY AN $6.85/DAY FROM WDI and save as:
1. country-level
2. select aggregates (FCS, IDA, Region, Income groups)
*/
********************************************************************************

// use class data file for current FCV and IDA status
// Source: https://github.com/GPID-WB/Class
use "Class.dta", clear
bys code: gen tag = (_n==_N)							// keep the latest year
keep if tag==1
drop tag
tempfile classdata
save 	`classdata'


cap ssc install wbopendata
wbopendata, indicator(si.pov.dday; si.pov.umic) clear 							// download poverty at IPL and the UMIC lines
keep countrycode countryname regionname incomelevelname indicator* yr*
ren countrycode code
merge m:1 code using `classdata', keep(1 3) keepusing(fcv_current ida_current) nogen 

label var code		 		"Country"
label var countryname		"Country Name"
label var regionname 		"Region"
label var incomelevelname 	"Income Group Current"
label var ida_current		"IDA Current"
label var fcv_current		"FCV Status Current"
label var indicatorcode		"Series"
label var indicatorname 	"Series Name"

foreach var of varlis yr* {
	local lab "`: var label `var''"
	label var `var' "YR`lab'"
}

order code countryname regionname incomelevelname ida_current fcv_current indicatorcode indicatorname yr*


// country-level data all years
preserve
drop if regionname=="Aggregates"												// Drop all regional aggregates
drop if missing(regionname)														// Drop Africa East and West aggregates as well
export excel using "csc_version_indicator_poverty_all_years.xlsx", first(varlabel) replace
restore

// country-level data 
preserve
drop if regionname=="Aggregates"												// Drop all regional aggregates
drop if missing(regionname)														// Drop Africa East and West aggregates as well
reshape long yr, i( code-indicatorname) j(year)
drop if missing(yr)
bys code indicatorcode (year): keep if _n==_N
label var yr "Poverty headcount rate, %"
label var year "Year"
export excel using "csc_version_indicator_poverty_latest_year.xlsx", first(varlabel) replace
restore


// aggreagates by region
keep if inlist(code,"AFE","AFW","EAP","ECA","LAC") | inlist(code,"MNA","SAS","SSA","WLD") | ///
		inlist(code,"FCS","IBD","IDA","IDB") | ///
		inlist(code,"LIC","LMC","UMC","HIC")	
keep countryname indicatorcode indicatorname yr*
label var countryname "Region"		
export excel using "csc_version_indicator_poverty_aggregates.xlsx", first(varlabel) replace

********************************************************************************
exit
