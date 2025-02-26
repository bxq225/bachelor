*************************************************************
**** 6c. NH Correction: impact on aggregate real consumption 
*************************************************************

* i) with 1984 as base
use "$resrootdata/nh_percentiles_1955_2019_age.dta", clear
foreach i in y qu q q_noGam {
	replace `i'=exp(`i')
}
collapse (mean) y qu q q_noGam annual_bias_percent, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100
gen pc_dev_real_cons_Gam = (q_noGam-q)/q_noGam*100

foreach i in y qu q pc_dev_real_cons annual_bias pc_dev_real_cons_Gam {
	rename `i' `i'_1984prices    
}

save "$resrootdata/temp_historical.dta", replace

* ii) with 2019 as base  
use "$resrootdata/nh_percentiles_reverse_1955_2019_age.dta", clear

drop ref_yr
rename ref_yr_o ref_yr 
foreach i in y qu q q_noGam {
	replace `i'=exp(`i')
}
collapse (mean) y qu q q_noGam annual_bias_percent avg_age_adult avg_age_all, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100
gen pc_dev_real_cons_Gam = (q_noGam-q)/q_noGam*100

scatter pc_dev_real_cons ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption" "= (Nh-Naive - Nh-True)/Nh-Naive*100 ")  graphregion(color(white)) xlabel(1955(5)2019) 

scatter pc_dev_real_cons_Gam ref_yr, xtitle("Year") ytitle("Bias in Aggreate Real Consumption" "= (Nh-Naive - Nh-True)/Nh-Naive*100 ")  graphregion(color(white)) xlabel(1955(5)2019) 


merge 1:1 ref_yr using "$resrootdata/temp_historical.dta"

* age correction 
scatter pc_dev_real_cons_Gam_1984p ref_yr, xline(1984, lwidth(thin) lcolor(blue%15) lp(dash)) || scatter pc_dev_real_cons_Gam ref_yr, msymbol(T) xline(2019, lwidth(thin) lcolor(red%15) lp(dash)) xtitle("Year") ytitle("Bias in Average Real Consumption")  graphregion(color(white)) xlabel(1955(5)2019) ylabel(-0.25(0.25)1.25) legend(order(1 "1984 base prices" 2 " 2019 base prices") rows(1))
graph export "$resrootfig/Fig7B.pdf", as(pdf) replace
