*************************************************************
**** 9d. NH Correction: impact on aggregate real consumption 
*************************************************************

* i) with 1984 as base
use "$resrootdata/nh_percentiles_1955_2019_robustness3.dta", clear
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100
replace annual_bias=annual_bias*100

foreach i in y qu q pc_dev_real_cons annual_bias {
	rename `i' `i'_1984prices    
}

save "$resrootdata/temp_historical.dta", replace

* ii) with 2019 as base  
use "$resrootdata/nh_percentiles_reverse_1955_2019_robustness3.dta", clear

drop ref_yr
rename ref_yr_o ref_yr 
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100
replace annual_bias=annual_bias*100

merge 1:1 ref_yr using "$resrootdata/temp_historical.dta"

* Fig E15a
scatter pc_dev_real_cons_1984p ref_yr, xline(1984, lwidth(thin) lcolor(blue%15) lp(dash)) || scatter pc_dev_real_cons ref_yr, msymbol(T) xline(2019, lwidth(thin) lcolor(red%15) lp(dash)) xtitle("Year") ytitle("Bias in Average Real Consumption")  graphregion(color(white)) xlabel(1955(5)2019) ylabel(-13(1)0) legend(order(1 "1984 base prices" 2 " 2019 base prices") rows(1)) 
graph export "$resrootfig/FigE15a.pdf", as(pdf) replace

* Fig E15b
replace annual_bias_1984price=0 if ref_yr==1984
replace annual_bias_percent=0 if ref_yr==2019
scatter annual_bias_1984prices ref_yr,  xline(1984, lwidth(thin) lcolor(blue%15) lp(dash)) || scatter annual_bias_percent ref_yr, msymbol(T) xline(2019, lwidth(thin) lcolor(red%15) lp(dash))  xtitle("Year") ytitle("Bias in Annual Real Consumption Growth, %") graphregion(color(white)) xlabel(1954(5)2019) ylabel(-5(5)15) legend(order(1 "1984 base prices" 2 " 2019 base prices") rows(1)) 
graph export "$resrootfig/FigE15b.pdf", as(pdf) replace
