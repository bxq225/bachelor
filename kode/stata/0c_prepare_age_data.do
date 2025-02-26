************************
** Raw data preparation
************************

* 1/ Study trends and rescale accordingly 

* study aggregate trends in this sample:
clear
import delimited "$dataroot/Yr_UCC_IncDecileThenAgeDecile_AdjbyIncQuintile.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(annual_gross_infl_t_tminus1)
drop if missing(annual_gross_infl_tplus1_t)
* we also drop categories that correspond to "investment", namely life insurance and education (results are stable without)
drop if l3=="Life and other personal insurance"
drop if l3=="Education" 

* for now focus on post 1984 data 
drop if ref<1984 

* aggregate overall 
collapse (sum)  wgt_mean_expn [aw=avg_hh_count], by(ref_yr ucc_str inc annual_gross_infl_t_tminus1 annual_gross_infl_tplus1_t)

replace wgt_mean_expn=wgt_mean_expn/100
bysort ref_yr: egen double tot_expn=sum(wgt_mean_expn)
gen expn_shr_t = wgt_mean_expn/tot_expn

bysort ref_yr: egen double paasche_tm1_t=sum(expn_shr_t*(annual_gross_infl_t_tminus1)^(-1))
replace paasche_tm1_t=1/paasche_tm1_t
bysort ref_yr: egen double laspeyres_t_tp1=sum(expn_shr_t*annual_gross_infl_tplus1_t)
* geom laspeyres index
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
gen double expn_normalized = tot_expn/19125.827*100
scatter expn_normalized ref_y 

gen real_expn = expn_normalized/cum_geom_laspeyres_t_tp1[_n-1]

scatter real_expn ref_y 
replace real_expn = 100 if ref_yr==1984

* from this, we obtain rescaling parameters to match the increase in real consumption from PCE,
* the broadest measure of consumption from the national accounts 

merge 1:1 ref_yr using "$dataroot/benchmark_real_pce"
keep if _merge==3 
drop _merge
gen adjustment_factor = real_pce_capita/ real_expn
keep ref_yr adjustment_factor
save "$dataroot/adjustment_factor_realPCE_geomlasp_age", replace

* 2/ rescale data by age 

* prepare external benchmark 
clear
import delimited "$dataroot/year_age_benchmark.csv"
rename year ref_yr
save "$dataroot/year_age_benchmark.dta", replace

* study aggregate trends in this sample:
clear
import delimited "$dataroot/Yr_UCC_IncDecileThenAgeDecile_AdjbyIncQuintile.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(annual_gross_infl_t_tminus1)
drop if missing(annual_gross_infl_tplus1_t)
* we also drop categories that correspond to "investment", namely life insurance and education (results are stable without)
drop if l3=="Life and other personal insurance"
drop if l3=="Education" 

* for now focus on post 1984 data 
drop if ref<1984 

keep inc_decile age_decile avg_hh_count avg_age_all_memb avg_age_adult ref
duplicates drop 

* aggregate overall 
collapse (mean)  avg_age_all_memb avg_age_adult [aw=avg_hh_count], by(ref_yr)

* compare to external source 
merge 1:1 ref_yr using "$dataroot/year_age_benchmark.dta"
keep if _merge==3 
drop _merge

gen adjustment_factor_age_all_member = averageageentirepopulation/avg_age_all_memb
gen adjustment_factor_age_adult      = averageage18yearsold/avg_age_adult

keep adjustment_factor_age_all_member adjustment_factor_age_adult ref_yr 
save "$dataroot/adjustment_factor_age", replace


* 3/ now clean dataset for the analysis

clear
import delimited "$dataroot/Yr_UCC_IncDecileThenAgeDecile_AdjbyIncQuintile.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(annual_gross_infl_t_tminus1)
drop if missing(annual_gross_infl_tplus1_t)
* we also drop categories that correspond to "investment", namely life insurance and education (results are stable without)
drop if l3=="Life and other personal insurance"
drop if l3=="Education" 

drop if ref<1984

bysort ref_yr inc_decile age_decile: egen double tot_expn=sum(wgt_mean_expn)

gen double expn_shr_t = wgt_mean_expn/tot_expn
rename wgt_mean_expn expn_t 

* adjust expenditures 
merge m:1 ref_yr using "$dataroot/adjustment_factor_realPCE_geomlasp_age"
replace expn_t=expn_t*adjustment_factor
replace tot_expn=tot_expn*adjustment_factor
drop adjustment_factor 

drop _merge 
drop if ref_yr==2020

* now adjust age 
merge m:1 ref_yr using "$dataroot/adjustment_factor_age"
keep if _merge==3 
drop _merge 
replace avg_age_all_memb =  avg_age_all_memb*adjustment_factor_age_all_member
replace avg_age_adult    =  avg_age_adult*adjustment_factor_age_adult 
drop adjustment_factor*

save "$dataroot\cex_micro_1984_2019_age_final.dta", replace

