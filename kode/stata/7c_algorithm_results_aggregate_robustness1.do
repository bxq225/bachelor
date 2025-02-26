*************************************************************
**** 7c NH Correction: impact on aggregate real consumption 
*************************************************************

* i) with 1984 as base
use "$resrootdata/nh_percentiles_robustness1.dta", clear
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100

scatter pc ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption" "= (Nh-Naive - Nh-True)/Nh-Naive*100 ")  graphregion(color(white)) xlabel(1984(5)2019) 

foreach i in y qu q pc_dev_real_cons annual_bias_percent {
	rename `i' `i'_1984prices	
}

* export data we can use later for comparison with final prices as base
save "$dataroot/temp2", replace 

* ii) results 
use "$resrootdata/nh_percentiles_reverse_robustness1.dta", clear

drop ref_yr
rename ref_yr_o ref_yr 
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100

merge 1:1 ref_yr using "$dataroot/temp2"

scatter pc_dev_real_cons_1984 ref_yr || scatter pc_dev_real_cons ref_yr , msymbol(T) xtitle("Year") ytitle("Bias in Average Real Consumption")  graphregion(color(white)) xlabel(1984(5)2019) legend(order(1 "1984 base prices" 2 " 2019 base prices") rows(1)) ylabel(-2.5(0.5)0)
graph export "$resrootfig/FigE10a.pdf", as(pdf) replace

foreach i in qu_1984prices q_1984prices qu q {
	replace `i'=log(`i')
}

replace annual_bias_percent_1984prices=annual_bias_percent_1984prices*100
replace annual_bias_percent=annual_bias_percent*100
replace annual_bias_percent_1984prices=0 if ref_yr==1984
replace annual_bias_percent=0 if ref_yr==2019
scatter annual_bias_percent_1984prices ref_yr || scatter annual_bias_percent ref_yr , msymbol(T) xtitle("Year") ytitle("Annual Bias in Real Consumption Growth, %")  graphregion(color(white)) xlabel(1984(5)2019) legend(order(1 "1984 base prices" 2 " 2019 base prices") rows(1)) 
graph export "$resrootfig/FigE10b.pdf", as(pdf) replace
