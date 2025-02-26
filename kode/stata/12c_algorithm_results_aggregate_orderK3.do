*************************************************************
**** 12c. Bring in results with K=3
*************************************************************

* i) with 1984 as base
use "$resrootdata/nh_percentiles_orderK3.dta", clear
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons_o3 = (qu-q)/qu*100

foreach i in y qu q pc_dev_real_cons_o3 annual_bias_percent {
	rename `i' `i'_1984prices	
}

* export data we can use later for comparison with final prices as base
save "$dataroot/temp2", replace 

* ii) results 
use "$resrootdata/nh_percentiles_reverse_orderK3.dta", clear

drop ref_yr
rename ref_yr_o ref_yr 
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons_order3 = (qu-q)/qu*100

merge 1:1 ref_yr using "$dataroot/temp2"
drop _merge

save "$dataroot/temp2", replace 

*************************************************************
**** Bring in results with K=1 and plot everything
*************************************************************

* i) with 1984 as base
use "$resrootdata/nh_percentiles_orderK1.dta", clear
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100

scatter pc ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption")  graphregion(color(white)) xlabel(1984(5)2019) 

foreach i in y qu q pc_dev_real_cons annual_bias_percent {
	rename `i' `i'_1984prices	
}

merge 1:1 ref_yr using "$dataroot/temp2"
drop _merge

* export data we can use later for comparison with final prices as base
save "$dataroot/temp2", replace 

* ii) results 
use "$resrootdata/nh_percentiles_reverse_orderK1.dta", clear

drop ref_yr
rename ref_yr_o ref_yr 
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100

scatter pc ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption")  graphregion(color(white)) xlabel(1984(5)2019) 

merge 1:1 ref_yr using "$dataroot/temp2"

scatter pc_dev_real_cons_1984 ref_yr || scatter pc_dev_real_cons_o3_1984 ref_yr || ///
scatter pc_dev_real_cons ref_yr || scatter pc_dev_real_cons_order3 ref_yr , msymbol(T) xtitle("Year") ytitle("Bias in Average Real Consumption")  graphregion(color(white)) xlabel(1984(5)2019) legend(order(1 "1984 base prices, K=1" 2 "1984 base prices, K=3" 3 "2019 base prices, K=1" 4 "2019 base prices, K=3") rows(2)) ylabel(-3(0.5)0)
graph export "$resrootfig/FigE6.pdf", as(pdf) replace

