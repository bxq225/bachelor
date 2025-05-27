*************************************************************
**** 2c. NH Correction: impact on aggregate real consumption 
*************************************************************

* i) with 2003 as base
use "$resrootdata/nh_percentiles.dta", clear
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100

scatter pc ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption")  graphregion(color(white)) xlabel(2003(2)2022) 

foreach i in y qu q pc_dev_real_cons annual_bias_percent {
	rename `i' `i'_2003prices	
}

* export data we can use later for comparison with final prices as base
save "$dataroot/temp2", replace 

* ii) results 
use "$resrootdata/nh_percentiles_reverse.dta", clear

drop ref_yr
rename ref_yr_o ref_yr 
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100

scatter pc ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption")  graphregion(color(white)) xlabel(2003(2)2022) 

merge 1:1 ref_yr using "$dataroot/temp2"

scatter pc_dev_real_cons_2003 ref_yr || scatter pc_dev_real_cons ref_yr , msymbol(T) xtitle("Year") ytitle("Bias in Average Real Consumption")  graphregion(color(white)) xlabel(2003(2)2022) legend(order(1 "2003 base prices" 2 " 2022 base prices") rows(2)) ylabel(-0.5(0.1)0.2)
graph export "$resrootfig/Fig3a_alder.pdf", as(pdf) replace

replace annual_bias_percent_2003prices=annual_bias_percent_2003prices*100
replace annual_bias_percent=annual_bias_percent*100
replace annual_bias_percent_2003prices=0 if ref_yr==2003
replace annual_bias_percent=0 if ref_yr==2022
scatter annual_bias_percent_2003prices ref_yr || scatter annual_bias_percent ref_yr , msymbol(T) xtitle("Year") ytitle("Annual Bias in Real Consumption Growth, %")  graphregion(color(white)) xlabel(2003(2)2022) legend(order(1 "2003 base prices" 2 " 2022 base prices") rows(2)) 
graph export "$resrootfig/Fig3b_alder.pdf", as(pdf) replace
