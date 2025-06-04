*************************************************************
**** 2c. NH Correction: impact on aggregate real consumption 
*************************************************************

* i) with 2008 as base
use "$resrootdata/nh_percentiles.dta", clear
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100

scatter pc ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption")  graphregion(color(white)) xlabel(2008(2)2022) 

foreach i in y qu q pc_dev_real_cons annual_bias_percent {
	rename `i' `i'_2008prices	
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

scatter pc ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption")  graphregion(color(white)) xlabel(2008(2)2022) 

merge 1:1 ref_yr using "$dataroot/temp2"

scatter pc_dev_real_cons_2008 ref_yr || scatter pc_dev_real_cons ref_yr , msymbol(T) xtitle("Year") ytitle("Bias in Average Real Consumption")  graphregion(color(white)) xlabel(2008(2)2022) legend(order(1 "2008 base prices" 2 " 2022 base prices") rows(2)) ylabel(-0.5(0.1)0.2)
graph export "$resrootfig/Fig3a_alder.pdf", as(pdf) replace

replace annual_bias_percent_2008prices=annual_bias_percent_2008prices*100
replace annual_bias_percent=annual_bias_percent*100
replace annual_bias_percent_2008prices=0 if ref_yr==2008
replace annual_bias_percent=0 if ref_yr==2022
scatter annual_bias_percent_2008prices ref_yr || scatter annual_bias_percent ref_yr , msymbol(T) xtitle("Year") ytitle("Annual Bias in Real Consumption Growth, %")  graphregion(color(white)) xlabel(2008(2)2022) legend(order(1 "2008 base prices" 2 " 2022 base prices") rows(2)) 
graph export "$resrootfig/Fig3b_alder.pdf", as(pdf) replace

*************************************************************
**** 3c. NH Correction: impact on aggregate real consumption 
*************************************************************

* i) with 2008 as base
use "$resrootdata/nh_percentiles.dta", clear
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100
replace annual_bias=annual_bias*100

foreach i in y qu q pc_dev_real_cons annual_bias {
	rename `i' `i'_2008prices    
}

save "$resrootdata/temp_historical.dta", replace

* ii) with 2019 as base  
use "$resrootdata/nh_percentiles_reverse.dta", clear

drop ref_yr
rename ref_yr_o ref_yr 
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100
replace annual_bias=annual_bias*100

scatter pc ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption" "= (Nh-Naive - Nh-True)/Nh-Naive*100 ")  graphregion(color(white)) xlabel(2008(5)2019) 

merge 1:1 ref_yr using "$resrootdata/temp_historical.dta"

* Fig 5a
scatter pc_dev_real_cons_2008p ref_yr, xline(2008, lwidth(thin) lcolor(blue%15) lp(dash)) || scatter pc_dev_real_cons ref_yr, msymbol(T) xline(2019, lwidth(thin) lcolor(red%15) lp(dash)) xtitle("Year") ytitle("Bias in Average Real Consumption")  graphregion(color(white)) xlabel(2008(1)2019) legend(order(1 "2008 base prices" 2 " 2019 base prices") rows(1)) 
graph export "$resrootfig/Fig5a.pdf", as(pdf) replace

foreach i in qu q qu_2008prices q_2008prices {
	replace `i'=log(`i')
}

* Fig 5b
replace annual_bias_2008price=0 if ref_yr==2008
replace annual_bias_percent=0 if ref_yr==2022
scatter annual_bias_2008prices ref_yr,  xline(2008, lwidth(thin) lcolor(blue%15) lp(dash)) || scatter annual_bias_percent ref_yr, msymbol(T) xline(2019, lwidth(thin) lcolor(red%15) lp(dash))  xtitle("Year") ytitle("Bias in Annual Real Consumption Growth, %") graphregion(color(white)) xlabel(2008(1)2019) legend(order(1 "2008 base prices" 2 " 2019 base prices") rows(1)) 
graph export "$resrootfig/Fig5b.pdf", as(pdf) replace

* Fig 5d
keep if ref_yr==2008 | ref_yr==2022
sort ref_yr
foreach i in qu q qu_2008prices q_2008prices {
	gen annualized_growth_`i' = ((exp(`i')/exp(`i'[_n-1]))^(1/(2022-2008))-1)*100
}
graph bar annualized_growth_qu annualized_growth_q_2008prices annualized_growth_q, ascategory ytitle("Annualized Growth Rate, 2008-2019, %") graphregion(color(white)) blabel(bar, position(inside) format(%9.2f) color(white))  yvar(relabel(1 "Uncorrected" 2 "Corrected, 2008 prices" 3 "Corrected, 2019 prices")) yscale(alt range(1.5 1.6))
graph export "$resrootfig/Fig5d.pdf", as(pdf) replace

* fig 5c
foreach i in qu q qu_2008prices q_2008prices {
	gen cum_growth_`i' = ((exp(`i')/exp(`i'[_n-1]))-1)*100
}
graph bar cum_growth_qu cum_growth_q_2008prices cum_growth_q, ascategory ytitle("Cumulative Growth, 2008-2019, %") graphregion(color(white)) blabel(bar, position(inside) format(%9.2f) color(white)) yvar(relabel(1 "Uncorrected" 2 "Corrected, 2008 prices" 3 "Corrected, 2019 prices")) yscale(alt range(28 30))
graph export "$resrootfig/Fig5c.pdf", as(pdf) replace
display (270-232)/232

