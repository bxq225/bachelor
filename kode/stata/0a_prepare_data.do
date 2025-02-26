************************
** Raw data preparation
************************

* 1/ Study trends and rescale accordingly 

* study aggregate trends in this sample:
clear
import delimited "$dataroot/Yr_UCC_IncPercentile.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(annual_gross_infl_t_tminus1)
drop if missing(annual_gross_infl_tplus1_t)
* we also drop categories that correspond to "investment", namely life insurance and education (results are stable without)
drop if l3=="Life and other personal insurance"
drop if l3=="Education" 

* aggregate overall 
collapse (sum)  wgt_mean_expn, by(ref_yr ucc_str inc annual_gross_infl_t_tminus1 annual_gross_infl_tplus1_t)

replace wgt_mean_expn=wgt_mean_expn/100
bysort ref_yr: egen double tot_expn=sum(wgt_mean_expn)
gen expn_shr_t = wgt_mean_expn/tot_expn

bysort ref_yr: egen double paasche_tm1_t=sum(expn_shr_t*(annual_gross_infl_t_tminus1)^(-1))
replace paasche_tm1_t=1/paasche_tm1_t
bysort ref_yr: egen double laspeyres_t_tp1=sum(expn_shr_t*annual_gross_infl_tplus1_t)
* geom laspeyres index:
bysort ref_yr: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)

keep ref_yr tot_expn laspeyres_t_tp1 geom_laspeyres_t_tp1 paasche_tm1_t
duplicates drop

sort ref_yr
gen double paasche_t_tp1 = paasche_tm1_t[_n+1]
gen double fisher_t_tp1=sqrt(paasche_t_tp1*laspeyres_t_tp1) 
* set to missing in the last year of the data
drop paasche_tm1_t

foreach i in laspeyres geom_laspeyres paasche fisher {
gen double cum_`i'_t_tp1 = `i'_t_tp1 if ref_y==1984
replace cum_`i'=cum_`i'_t_tp1[_n-1]*`i'_t_tp1 if ref_y>1984
}

scatter cum_laspeyres_t_tp1 ref_y 

* normalize everything by expenditures in 1984
gen double expn_normalized = tot_expn/19146.117*100
scatter expn_normalized ref_y 

gen double real_expn = expn_normalized/cum_geom_laspeyres_t_tp1[_n-1]

scatter real_expn ref_y 
replace real_expn = 100 if ref_yr==1984

* also keep track of results with fisher index for robustness analysis
gen double real_expn_fisher = expn_normalized/cum_fisher_t_tp1[_n-1]

* from this, we obtain rescaling parameters to match the increase in real consumption from PCE,
* the broadest measure of consumption from the national accounts 

merge 1:1 ref_yr using "$dataroot/benchmark_real_pce"
keep if _merge==3 
drop _merge
gen adjustment_factor = real_pce_capita/ real_expn
gen adjustment_factor_fisher = real_pce_capita/ real_expn_fisher
keep ref_yr adjustment_factor
save "$dataroot/adjustment_factor_realPCE_geomlasp", replace


* 2/ now clean dataset for the analysis

clear
import delimited "$dataroot/Yr_UCC_IncPercentile.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(annual_gross_infl_t_tminus1)
drop if missing(annual_gross_infl_tplus1_t)
* we also drop categories that correspond to "investment", namely life insurance and education (results are stable without)
drop if l3=="Life and other personal insurance"
drop if l3=="Education" 

bysort ref_yr inc_percentile: egen double tot_expn=sum(wgt_mean_expn)

gen double expn_shr_t = wgt_mean_expn/tot_expn
rename wgt_mean_expn expn_t 

merge m:1 ref_yr using "$dataroot/adjustment_factor_realPCE_geomlasp"
replace expn_t=expn_t*adjustment_factor
replace tot_expn=tot_expn*adjustment_factor
drop adjustment_factor* 

* here generate identifiers for quintiles and deciles 
gen decile=.
replace decile =1 if inc<11
foreach i of numlist 2(1)10 {
replace decile=`i' if missing(decile) & inc<`i'*10+1
}

gen quintile=.
replace quintile =1 if inc<21
foreach i of numlist 2(1)5 {
replace quintile=`i' if missing(quintile) & inc<`i'*20+1
}

drop _merge 
drop if ref_yr==2020

save "$dataroot/cex_micro_1984_2019_final.dta", replace

* 3/ also save a version of the dataset with the Fisher price index 

clear
import delimited  "$dataroot/Yr_UCC_IncPercentile.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(annual_gross_infl_t_tminus1)
drop if missing(annual_gross_infl_tplus1_t)
* we also drop categories that correspond to "investment", namely life insurance and education (results are stable without)
drop if l3=="Life and other personal insurance"
drop if l3=="Education" 

bysort ref_yr inc_percentile: egen double tot_expn=sum(wgt_mean_expn)

gen double expn_shr_t = wgt_mean_expn/tot_expn
rename wgt_mean_expn expn_t 

merge m:1 ref_yr using "$dataroot/adjustment_factor_realPCE_geomlasp"
replace expn_t=expn_t*adjustment_factor
replace tot_expn=tot_expn*adjustment_factor
drop adjustment_factor* 

* here generate identifiers for quintiles and deciles 
gen decile=.
replace decile =1 if inc<11
foreach i of numlist 2(1)10 {
replace decile=`i' if missing(decile) & inc<`i'*10+1
}

gen quintile=.
replace quintile =1 if inc<21
foreach i of numlist 2(1)5 {
replace quintile=`i' if missing(quintile) & inc<`i'*20+1
}

drop _merge 
drop if ref_yr==2020

save "$dataroot/cex_micro_1984_2019_final_fisher.dta", replace



