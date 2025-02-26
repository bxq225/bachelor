*************************************************************
**** 5c iii. NH Correction: impact on aggregate real consumption 
*************************************************************

* i) with 1984 as base
use "$resrootdata/nh_percentiles_2nd_order_fisher.dta", clear
foreach i in y qu q first_order_q_fisher {
	replace `i'=exp(`i')
}
collapse (mean) y first_order_q_fisher qu q annual_bias_percent annual_bias_percent_old Lambda_rescaled, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100
gen pc_dev_real_cons_first = (qu-first_order_q_fisher)/qu*100

scatter pc_dev_real_cons ref_yr || scatter pc_dev_real_cons_first ref_yr , xtitle("Year") ytitle("Bias in Aggreate Real Consumption" "= (Nh-Naive - Nh-True)/Nh-Naive*100 ")  graphregion(color(white)) xlabel(1984(5)2019) 

rename pc_dev_real_cons pc_dev_real_cons_2nd_order
rename annual_bias_percent annual_bias_percent_2nd_order
rename annual_bias_percent_old annual_bias_percent 
rename Lambda_rescaled Lambda_rescaled_2nd_order 
foreach i in pc_dev_real_cons_2nd_order pc_dev_real_cons_first annual_bias_percent {
	rename `i' `i'_f
}

* export data we can use later for comparison with final prices as base
save "$dataroot/temp2", replace 

* before, compare to results with geometric laspeyres 
use "$resrootdata/nh_percentiles.dta", clear
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100

foreach i in y qu q pc_dev_real_cons annual_bias_percent {
	rename `i' `i'_1984prices
}

merge 1:1 ref_yr using "$dataroot/temp2"

* plot the deviation in levels
scatter pc_dev_real_cons_1984prices ref_yr || scatter pc_dev_real_cons_first_f ref_yr, msymbol(T) || scatter pc_dev_real_cons_2nd_order_f ref_yr, msymbol(D) xtitle("Year") ytitle("Bias in Average Real Consumption")  graphregion(color(white)) xlabel(1984(5)2019) legend(order(1 "First-order NH correction, Geometric Laspeyres" 2 "First-order NH correction, Fisher" 3 "Second-order NH correction, Fisher") rows(3)) 
graph export "$resrootfig/Fig6Ai.pdf", as(pdf) replace

* plot the annual bias 
foreach i in annual_bias_percent_1984prices annual_bias_percent_f annual_bias_percent_2nd_order Lambda_rescaled_2nd_order {
	replace `i'=`i'*100
	replace `i'=0 if ref_yr==1984
}

scatter annual_bias_percent_1984prices ref_yr || scatter annual_bias_percent_f ref_yr || scatter Lambda_rescaled_2nd_order ref_yr, xtitle("Year") ytitle("Annual Bias in Real Consumption Growth, %")  graphregion(color(white)) xlabel(1984(5)2019) legend(order(1 "First-order NH correction, Geometric Laspeyres" 2 "First-order NH correction, Fisher" 3 "Second-order NH correction, Fisher") rows(3)) 
graph export "$resrootfig/FigE5Ai.pdf", as(pdf) replace


* ii) results with 2019 prices as base here
use "$resrootdata/nh_percentiles_reverse_2nd_order_fisher.dta", clear

drop ref_yr
rename ref_yr_o ref_yr 

foreach i in y qu q first_order_q_fisher {
	replace `i'=exp(`i')
}
collapse (mean) y first_order_q_fisher qu q annual_bias_percent annual_bias_percent_old Lambda_rescaled, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100
gen pc_dev_real_cons_first = (qu-first_order_q_fisher)/qu*100

scatter pc_dev_real_cons ref_yr || scatter pc_dev_real_cons_first ref_yr , xtitle("Year") ytitle("Bias in Aggreate Real Consumption" "= (Nh-Naive - Nh-True)/Nh-Naive*100 ")  graphregion(color(white)) xlabel(1984(5)2019) 

rename pc_dev_real_cons pc_dev_real_cons_2nd_order
rename annual_bias_percent annual_bias_percent_2nd_order
rename annual_bias_percent_old annual_bias_percent 
rename Lambda_rescaled Lambda_rescaled_2nd_order 
foreach i in pc_dev_real_cons_2nd_order pc_dev_real_cons_first annual_bias_percent {
	rename `i' `i'_f
}

* export data we can use later for comparison with final prices as base
save "$dataroot/temp3", replace

* before, compare to results with geometric laspeyres 
use "$resrootdata/nh_percentiles_reverse.dta", clear

drop ref_yr
rename ref_yr_o ref_yr 
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100

scatter pc ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption" "= (Nh-Naive - Nh-True)/Nh-Naive*100 ")  graphregion(color(white)) xlabel(1984(5)2019) 

foreach i in y qu q pc_dev_real_cons annual_bias_percent {
	rename `i' `i'_2019prices
}

merge 1:1 ref_yr using "$dataroot/temp3"

* plot the deviation in levels
scatter pc_dev_real_cons_2019prices ref_yr || scatter pc_dev_real_cons_first_f ref_yr, msymbol(T) || scatter pc_dev_real_cons_2nd_order_f ref_yr, msymbol(D) xtitle("Year") ytitle("Bias in Average Real Consumption")  graphregion(color(white)) xlabel(1984(5)2019) legend(order(1 "First-order NH correction, Geometric Laspeyres" 2 "First-order NH correction, Fisher" 3 "Second-order NH correction, Fisher") rows(3)) 
graph export "$resrootfig/Fig6Aii.pdf", as(pdf) replace

* plot the annual bias 
foreach i in annual_bias_percent_2019prices annual_bias_percent_f annual_bias_percent_2nd_order Lambda_rescaled_2nd_order {
	replace `i'=`i'*100
	replace `i'=0 if ref_yr==2019
}

scatter annual_bias_percent_2019prices ref_yr || scatter annual_bias_percent_f ref_yr || scatter Lambda_rescaled_2nd_order ref_yr, xtitle("Year") ytitle("Annual Bias in Real Consumption Growth, %")  graphregion(color(white)) xlabel(1984(5)2019) legend(order(1 "First-order NH correction, Geometric Laspeyres" 2 "First-order NH correction, Fisher" 3 "Second-order NH correction, Fisher") rows(3)) 
graph export "$resrootfig/FigE5Aii.pdf", as(pdf) replace
