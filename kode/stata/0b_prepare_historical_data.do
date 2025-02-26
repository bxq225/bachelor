*** 1/ study aggregate trends in this sample & define the "real adjustment factor" (using personal consumption expenditure)
clear
import delimited "$dataroot/Yr_UCC_IncPercentile_EqlExpnShrIncrem_1960_2019.csv"

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
gen double expn_normalized = tot_expn/19146.117*100
scatter expn_normalized ref_y 

* now compute real expenditures with the four price indices: 
foreach i in laspeyres paasche fisher geom_laspeyres {
gen double real_expn_`i' = expn_normalized/cum_`i'_t_tp1[_n-1]
* for 1955, take the values from 1956
replace real_expn_`i' = 47.328061 if ref_yr==1955
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
save "$dataroot/adjustment_factor_realPCE_1955_2019_by_price_index.dta", replace


*** 2/ now clean dataset for the analysis

clear
import delimited "$dataroot/Yr_UCC_IncPercentile_EqlExpnShrIncrem_1960_2019.csv"

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

merge m:1 ref_yr using "$dataroot/adjustment_factor_realPCE_1955_2019_by_price_index"
replace expn_t=expn_t*adjustment_factor_geom_laspeyres
replace tot_expn=tot_expn*adjustment_factor_geom_laspeyres
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

save "$dataroot/cex_micro_1955_2019_final.dta", replace


*** 3/ report patterns of cumulative growth with standard indices

use "$dataroot/cex_micro_1955_2019_final.dta", clear

collapse (sum)  expn_t, by(ref_yr ucc_str annual_gross_infl_t_tminus1 annual_gross_infl_tplus1_t)

bysort ref_yr: egen double tot_expn=sum(expn_t)
gen double expn_shr_t = expn_t/tot_expn

bysort ref_yr: egen double paasche_tm1_t=sum(expn_shr_t*(annual_gross_infl_t_tminus1)^(-1))
replace paasche_tm1_t=(paasche_tm1_t)^(-1)
bysort ref_yr: egen double laspeyres_t_tp1=sum(expn_shr_t*annual_gross_infl_tplus1_t)
* geom indices:
bysort ref_yr: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)

keep ref_yr tot_expn laspeyres_t_tp1 paasche_tm1_t geom_laspeyres_t_tp1
duplicates drop

* normalize by 1955 value 
replace tot_expn=tot_expn/259102.43

* now can create Fisher index (at the aggregate level)
sort ref_yr
gen double paasche_t_tp1=paasche[_n+1]
gen double fisher_t_tp1=sqrt(paasche_t_tp1*laspeyres_t_tp1)
* of course, this is missing in the last year of the data

foreach i in laspeyres paasche fisher geom_laspeyres {
gen cum_`i'_t_tp1 = `i'_t_tp1 if ref_y==1955
replace cum_`i'_t_tp1=cum_`i'_t_tp1[_n-1]*`i'_t_tp1 if ref_y>1955
}

drop if ref>2019

foreach i in laspeyres paasche fisher geom_laspeyres {
	
	gen real_expn_`i' = tot_expn/cum_`i'_t_tp1[_n-1]
	replace  real_expn_`i'= 1 if ref==1955
	
}

keep if ref==2019

foreach i in laspeyres paasche fisher geom_laspeyres {
	
	gen double cum_growth_`i'=  (real_expn_`i'-1)*100
	
}

* Fig E4.i
graph bar cum_growth_paasche cum_growth_fisher cum_growth_laspeyres, ascategory ytitle("Cumulative Growth, 1955-2019, %") graphregion(color(white)) blabel(bar, position(inside) format(%9.2f) color(white))  yvar(relabel(1 "Paasche" 2 "Fisher" 3 "Laspeyres"))
graph export "$resrootfig/FigE4i.pdf", as(pdf) replace

* Fig E4.ii
foreach i in laspeyres paasche fisher geom_laspeyres {
	gen annualized_growth_`i' = ((real_expn_`i')^(1/(2019-1955))-1)*100
}
graph bar annualized_growth_paasche annualized_growth_fisher annualized_growth_laspeyres, ascategory ytitle("Annualized Growth Rate, 1955-2019, %") graphregion(color(white)) blabel(bar, position(inside) format(%9.2f) color(white))  yvar(relabel(1 "Paasche" 2 "Fisher" 3 "Laspeyres"))
graph export "$resrootfig/FigE4ii.pdf", as(pdf) replace

