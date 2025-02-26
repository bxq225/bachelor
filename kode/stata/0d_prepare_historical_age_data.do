*** 1/ study aggregate trends in this sample & define the "real adjustment factor" (using personal consumption expenditure)
clear
import delimited "$dataroot/Yr_UCC_IncDecileThenAgeDecile_AdjbyIncQuintile_EqlExpnShrIncrem_1960_2020.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(annual_gross_infl_t_tminus1)
drop if missing(annual_gross_infl_tplus1_t)
* we also drop categories that correspond to "investment", namely life insurance and education (results are stable without)
drop if l3=="Life and other personal insurance"
drop if l3=="Education" 

* aggregate overall (rather than working with percentiles)
replace wgt_mean_expn=wgt_mean_expn/100 // to compute aggregate expenditure we must take into account that each bin is just 100th of the total
collapse (sum)  wgt_mean_expn, by(ref_yr ucc_str annual_gross_infl_t_tminus1 annual_gross_infl_tplus1_t)

bysort ref_yr: egen double tot_expn=sum(wgt_mean_expn)
gen double expn_shr_t = wgt_mean_expn/tot_expn

bysort ref_yr: egen double paasche_tm1_t=sum(expn_shr_t*(annual_gross_infl_t_tminus1)^(-1))
replace paasche_tm1_t=(paasche_tm1_t)^(-1)
bysort ref_yr: egen double laspeyres_t_tp1=sum(expn_shr_t*annual_gross_infl_tplus1_t)
* geom indices:
bysort ref_yr: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)

keep ref_yr tot_expn laspeyres_t_tp1 paasche_tm1_t geom_laspeyres_t_tp1
duplicates drop

* now can create Fisher index (at the aggregate level)
sort ref_yr
gen double paasche_t_tp1=paasche[_n+1]
gen double fisher_t_tp1=sqrt(paasche_t_tp1*laspeyres_t_tp1)

foreach i in laspeyres paasche fisher geom_laspeyres {
gen cum_`i'_t_tp1 = `i'_t_tp1 if ref_y==1955
replace cum_`i'_t_tp1=cum_`i'_t_tp1[_n-1]*`i'_t_tp1 if ref_y>1955
}

scatter cum_laspeyres_t_tp1 ref_y || scatter cum_fisher_t_tp1 ref_y || scatter cum_paasche_t_tp1 ref_y

* normalize relative to 1984 level
gen double expn_normalized = tot_expn/19121.435*100
scatter expn_normalized ref_y 

* now compute real expenditures with the four price indices: 
foreach i in laspeyres paasche fisher geom_laspeyres {
gen double real_expn_`i' = expn_normalized/cum_`i'_t_tp1[_n-1]
}

* now, we re-normalize everything with 1984 as base 100, for comparability with previous code
foreach i in laspeyres paasche fisher geom_laspeyres {
	gen double temp = real_expn_`i' if ref_yr==1984
	egen double temp2=max(temp)
	replace real_expn_`i'=real_expn_`i'/temp2*100
	drop temp temp2
}


* from this, we obtain rescaling parameters to match the increase in real consumption from PCE,
* the broadest measure of consumption from the national accounts 

merge 1:1 ref_yr using "$dataroot/benchmark_real_pce_1955_2019.dta"
keep if _merge==3 
drop _merge
foreach i in laspeyres paasche fisher geom_laspeyres {
gen double adjustment_factor_`i' = real_pce_per_capita/ real_expn_`i'
}
keep ref_yr adjustment_factor*
save "$dataroot\adjustment_factor_realPCE_1955_2019_by_price_index_age.dta", replace


*** 2/ Rescale age trends in this sample to match benchmark:
clear
import delimited "$dataroot/Yr_UCC_IncDecileThenAgeDecile_AdjbyIncQuintile_EqlExpnShrIncrem_1960_2020.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(annual_gross_infl_t_tminus1)
drop if missing(annual_gross_infl_tplus1_t)
* we also drop categories that correspond to "investment", namely life insurance and education (results are stable without)
drop if l3=="Life and other personal insurance"
drop if l3=="Education" 

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
save "$dataroot/adjustment_factor_age_all", replace


*** 3/ now clean dataset for the analysis

clear
import delimited "$dataroot/Yr_UCC_IncDecileThenAgeDecile_AdjbyIncQuintile_EqlExpnShrIncrem_1960_2020.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(annual_gross_infl_t_tminus1)
drop if missing(annual_gross_infl_tplus1_t)
* we also drop categories that correspond to "investment", namely life insurance and education (results are stable without)
drop if l3=="Life and other personal insurance"
drop if l3=="Education" 

bysort ref_yr inc_decile age_decile: egen double tot_expn=sum(wgt_mean_expn)

gen double expn_shr_t = wgt_mean_expn/tot_expn
rename wgt_mean_expn expn_t 

merge m:1 ref_yr using "$dataroot\adjustment_factor_realPCE_1955_2019_by_price_index_age"
replace expn_t=expn_t*adjustment_factor_geom_laspeyres
replace tot_expn=tot_expn*adjustment_factor_geom_laspeyres
drop adjustment_factor*
drop _merge

* now adjust age 
merge m:1 ref_yr using "$dataroot/adjustment_factor_age_all"
keep if _merge==3 
drop _merge 
replace avg_age_all_memb		     =  avg_age_all_memb*adjustment_factor_age_all_member
replace avg_age_adult  =  avg_age_adult*adjustment_factor_age_adult 
drop adjustment_factor*

save "$dataroot/cex_micro_1955_2019_final_age.dta", replace

