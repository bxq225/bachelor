*************************************************************
**** 18c. NH Correction: impact on aggregate real consumption 
*************************************************************

* i) with 1984 as base
use "$resrootdata/nh_percentiles_refined_order2.dta", clear
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent annual_growth_naive annual_growth_q, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100

gen annual_bias_percent_agg = (annual_growth_naive-annual_growth_q)/annual_growth_naive

gen deviation = annual_growth_naive

foreach i in y qu q pc_dev_real_cons annual_bias_percent  annual_bias_percent_agg {
	rename `i' `i'_1984p	
}

* export data we can use later for comparison with final prices as base
save "$dataroot/temp2", replace 

* ii) results 
use "$resrootdata/nh_percentiles_refined_order2_reverse.dta", clear

drop ref_yr
rename ref_yr_o ref_yr 
foreach i in y qu q {
	replace `i'=exp(`i')
}
collapse (mean) y qu q annual_bias_percent annual_growth_naive annual_growth_q, by(ref_yr)
gen pc_dev_real_cons = (qu-q)/qu*100
gen annual_bias_percent_agg = (annual_growth_naive-annual_growth_q)/annual_growth_naive

merge 1:1 ref_yr using "$dataroot/temp2"

foreach i in qu_1984p q_1984p qu q {
	replace `i'=log(`i')
}

replace annual_bias_percent_1984p=annual_bias_percent_1984p*100
replace annual_bias_percent=annual_bias_percent*100
replace annual_bias_percent_1984p=0 if ref_yr==1984
replace annual_bias_percent=0 if ref_yr==2019

* repeat with the aggregate measure of bias:
replace annual_bias_percent_agg_1984p=annual_bias_percent_agg_1984p*100
replace annual_bias_percent_agg=annual_bias_percent_agg*100
replace annual_bias_percent_agg_1984p=0 if ref_yr==1984
replace annual_bias_percent_agg=0 if ref_yr==2019

keep pc_dev_real_cons_1984 pc_dev_real_cons ref_yr
rename pc_dev_real_cons_1984 pc_dev_real_cons_1984_refined2
rename pc_dev_real_cons pc_dev_real_cons_refined2 
merge 1:1 ref_yr using "$dataroot/RCF_refined_figure" 
drop _merge 
save "$dataroot/RCF_refined_figure", replace 