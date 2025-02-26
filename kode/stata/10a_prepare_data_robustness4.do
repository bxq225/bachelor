************************
** 10a. Raw data preparation
************************

* 1/ Study trends and rescale accordingly 

* study aggregate trends in this sample:
clear
import delimited "$datarootrobustness/final_database_nielsen_july2021.csv"

* we must drop categories for which price indices are not available
drop if missing(infl)

* rename variables so that we can use the same code as previously 
gen double wgt_mean_expn = total_spending*spending_share
rename year ref_yr
rename prodid ucc_str
rename decile inc 
gen double annual_gross_infl_tplus1_t = 1+inflation_ces/100

* aggregate overall 
collapse (sum)  wgt_mean_expn, by(ref_yr ucc_str inc annual_gross_infl_tplus1_t)

replace wgt_mean_expn=wgt_mean_expn/100
bysort ref_yr: egen double tot_expn=sum(wgt_mean_expn)
gen expn_shr_t = wgt_mean_expn/tot_expn

bysort ref_yr: egen double laspeyres_t_tp1=sum(expn_shr_t*annual_gross_infl_tplus1_t)
* geom laspeyres index:
bysort ref_yr: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)

keep ref_yr tot_expn laspeyres_t_tp1 geom_laspeyres_t_tp1
duplicates drop

sort ref_yr

foreach i in laspeyres geom_laspeyres {
gen double cum_`i'_t_tp1 = `i'_t_tp1 if ref_y==2004
replace cum_`i'=cum_`i'_t_tp1[_n-1]*`i'_t_tp1 if ref_y>2004
}

scatter cum_laspeyres_t_tp1 ref_y 

* normalize everything by expenditures in 2004
gen double expn_normalized = tot_expn/5380.7533*100
scatter expn_normalized ref_y 

gen double real_expn = expn_normalized/cum_geom_laspeyres_t_tp1[_n-1]

scatter real_expn ref_y 
replace real_expn = 100 if ref_yr==2004

* from this, we obtain rescaling parameters to match the increase in real consumption from PCE,
* the broadest measure of consumption from the national accounts 

merge 1:1 ref_yr using "$dataroot/benchmark_real_pce"
keep if _merge==3 
drop _merge

* normalize real pce in 2004 
replace real_pce=real_pce/161.566*100
gen adjustment_factor = real_pce_capita/ real_expn
keep ref_yr adjustment_factor
save "$dataroot/adjustment_factor_realPCE_geomlasp_nielsen", replace


* 2/ now clean dataset for the analysis

clear
import delimited "$datarootrobustness/final_database_nielsen_july2021.csv"

* we must drop categories for which price indices are not available
drop if missing(infl)
drop _merge 

* rename variables so that we can use the same code as previously 
gen double wgt_mean_expn = total_spending*spending_share
rename year ref_yr
rename prodid ucc_str
rename decile inc_percentile // note: in fact here we use deciles, not percentiles 
gen double annual_gross_infl_tplus1_t = 1+inflation_ces/100

bysort ref_yr inc_percentile: egen double tot_expn=sum(wgt_mean_expn)

gen double expn_shr_t = wgt_mean_expn/tot_expn
rename wgt_mean_expn expn_t 

merge m:1 ref_yr using "$dataroot/adjustment_factor_realPCE_geomlasp_nielsen"
replace expn_t=expn_t*adjustment_factor
replace tot_expn=tot_expn*adjustment_factor
drop adjustment_factor* 

drop _merge 

save "$dataroot/cex_micro_1984_2019_robustness4.dta", replace
