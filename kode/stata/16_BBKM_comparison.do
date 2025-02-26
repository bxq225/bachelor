************************************************************************************
** 16. This do.file analyzes the results from the BBKM algorithm, without extrapolation
************************************************************************************


clear all
set more off

*** 1. BBKM results with linear interpolation, without extrapolation  

use "$dataroot/CEX_Microdata_UCC_Base1984_Utility_log_order2_linearintrpl_guessinrange.dta", clear

* Compare to the results obtained with our algorithm
merge 1:1 ref_yr inc_percentile using "$resrootdata/nh_percentiles.dta"

drop if missing(logu)

foreach i in y qu q logu {
	replace `i'=exp(`i')
}
collapse (mean) y qu q logu, by(ref_yr)
gen pc_dev_real_cons_jl = (qu-q)/qu*100
gen pc_dev_real_cons_bbk = (qu-logu)/qu*100

scatter pc_dev_real_cons_jl ref_yr || scatter pc_dev_real_cons_bbk ref_yr, symbol(T) xtitle("Year") ytitle("Bias in Average Real Consumption") legend(order(1 "JL" 2 "BBK") rows(1))  graphregion(color(white)) xlabel(1984(5)2019) 
graph export "$resrootfig/FigE9.pdf", as(pdf) replace

