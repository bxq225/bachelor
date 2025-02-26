*************************************************************
**** 3c. NH Correction: impact on aggregate real consumption 
*************************************************************

* i) with 1984 as base
use "$resrootdata/nh_percentiles_1955_2019.dta", clear
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
use "$resrootdata/nh_percentiles_reverse_1955_2019.dta", clear

drop ref_yr
rename ref_yr_o ref_yr 
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100
replace annual_bias=annual_bias*100

scatter pc ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption" "= (Nh-Naive - Nh-True)/Nh-Naive*100 ")  graphregion(color(white)) xlabel(1955(5)2019) 

merge 1:1 ref_yr using "$resrootdata/temp_historical.dta"

* Fig 5a
scatter pc_dev_real_cons_1984p ref_yr, xline(1984, lwidth(thin) lcolor(blue%15) lp(dash)) || scatter pc_dev_real_cons ref_yr, msymbol(T) xline(2019, lwidth(thin) lcolor(red%15) lp(dash)) xtitle("Year") ytitle("Bias in Average Real Consumption")  graphregion(color(white)) xlabel(1955(5)2019) ylabel(-13(1)0) legend(order(1 "1984 base prices" 2 " 2019 base prices") rows(1)) 
graph export "$resrootfig/Fig5a.pdf", as(pdf) replace

foreach i in qu q qu_1984prices q_1984prices {
	replace `i'=log(`i')
}

* Fig 5b
replace annual_bias_1984price=0 if ref_yr==1984
replace annual_bias_percent=0 if ref_yr==2019
scatter annual_bias_1984prices ref_yr,  xline(1984, lwidth(thin) lcolor(blue%15) lp(dash)) || scatter annual_bias_percent ref_yr, msymbol(T) xline(2019, lwidth(thin) lcolor(red%15) lp(dash))  xtitle("Year") ytitle("Bias in Annual Real Consumption Growth, %") graphregion(color(white)) xlabel(1954(5)2019) ylabel(-5(5)15) legend(order(1 "1984 base prices" 2 " 2019 base prices") rows(1)) 
graph export "$resrootfig/Fig5b.pdf", as(pdf) replace

* Fig 5d
keep if ref_yr==1955 | ref_yr==2019
sort ref_yr
foreach i in qu q qu_1984prices q_1984prices {
	gen annualized_growth_`i' = ((exp(`i')/exp(`i'[_n-1]))^(1/(2019-1955))-1)*100
}
graph bar annualized_growth_qu annualized_growth_q_1984prices annualized_growth_q, ascategory ytitle("Annualized Growth Rate, 1955-2019, %") graphregion(color(white)) blabel(bar, position(inside) format(%9.2f) color(white))  yvar(relabel(1 "Uncorrected" 2 "Corrected, 1984 prices" 3 "Corrected, 2019 prices"))
graph export "$resrootfig/Fig5d.pdf", as(pdf) replace

* fig 5c
foreach i in qu q qu_1984prices q_1984prices {
	gen cum_growth_`i' = ((exp(`i')/exp(`i'[_n-1]))-1)*100
}
graph bar cum_growth_qu cum_growth_q_1984prices cum_growth_q, ascategory ytitle("Cumulative Growth, 1955-2019, %") graphregion(color(white)) blabel(bar, position(inside) format(%9.2f) color(white))  yvar(relabel(1 "Uncorrected" 2 "Corrected, 1984 prices" 3 "Corrected, 2019 prices"))
graph export "$resrootfig/Fig5c.pdf", as(pdf) replace
display (270-232)/232

