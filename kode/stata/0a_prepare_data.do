************************
** Raw data preparation
************************

* 1/ Study trends and rescale accordingly 

* study aggregate trends in this sample:
clear
import delimited "$dataroot/data.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(inflation_t_tminus1)
drop if missing(inflation_t_tplus1)

* aggregate overall 
collapse (sum)  forbrug, by(ref_yr kategori indkomstgruppe gns_pris_indeks inflation_t_tminus1 inflation_t_tplus1)

replace forbrug=forbrug/5
bysort ref_yr: egen double tot_expn=sum(forbrug)
gen expn_shr_t = forbrug/tot_expn

bysort ref_yr: egen double paasche_tm1_t=sum(expn_shr_t*(inflation_t_tminus1)^(-1))
replace paasche_tm1_t=1/paasche_tm1_t
bysort ref_yr: egen double laspeyres_t_tp1=sum(expn_shr_t*inflation_t_tplus1)
* geom laspeyres index:
bysort ref_yr: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(inflation_t_tplus1))
replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)

keep ref_yr tot_expn laspeyres_t_tp1 geom_laspeyres_t_tp1 paasche_tm1_t
duplicates drop

sort ref_yr
gen double paasche_t_tp1 = paasche_tm1_t[_n+1]
gen double fisher_t_tp1=sqrt(paasche_t_tp1*laspeyres_t_tp1) 
* set to missing in the last year of the data
drop paasche_tm1_t

foreach i in laspeyres geom_laspeyres paasche fisher {
gen double cum_`i'_t_tp1 = `i'_t_tp1 if ref_y==2007
replace cum_`i'=cum_`i'_t_tp1[_n-1]*`i'_t_tp1 if ref_y>2007
}

scatter cum_laspeyres_t_tp1 ref_y 

scatter tot_expn ref_y 

gen double real_expn = tot_expn/cum_geom_laspeyres_t_tp1[_n-1]
scatter real_expn ref_y
* also keep track of results with fisher index for robustness analysis
gen double real_expn_fisher = tot_expn/cum_fisher_t_tp1[_n-1]

* from this, we obtain rescaling parameters to match the increase in real consumption from PCE,
* the broadest measure of consumption from the national accounts 

merge 1:1 ref_yr using "$dataroot/prisindeks.dta"
keep if _merge==3 
drop _merge
gen prisindeks_num = prisindeks
gen adjustment_factor = prisindeks_num/ real_expn
gen adjustment_factor_fisher = prisindeks_num/ real_expn_fisher
keep ref_yr adjustment_factor
save "$dataroot/adjustment_factor_PrisIndeks_geomlasp", replace


* 2/ now clean dataset for the analysis

clear
import delimited "$dataroot/data.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(inflation_t_tminus1)
drop if missing(inflation_t_tplus1)


bysort ref_yr indkomstgruppe: egen double tot_expn=sum(forbrug)

gen double expn_shr_t = forbrug/tot_expn
rename forbrug expn_t 

merge m:1 ref_yr using "$dataroot/adjustment_factor_PrisIndeks_geomlasp"
replace expn_t=expn_t*adjustment_factor
replace tot_expn=tot_expn*adjustment_factor
drop adjustment_factor* 

save "$dataroot/Forbrugs_Data.dta", replace

* 3/ also save a version of the dataset with the Fisher price index 

clear
import delimited  "$dataroot/Data.csv"

* we must drop categories for which price indices are not available
* namely: pensions & social security + life & personal insurance 
drop if missing(inflation_t_tminus1)
drop if missing(inflation_t_tplus1)


bysort ref_yr indkomstgruppe: egen double tot_expn=sum(forbrug)

gen double expn_shr_t = forbrug/tot_expn
rename forbrug expn_t 

merge m:1 ref_yr using "$dataroot/adjustment_factor_PrisIndeks_geomlasp"
replace expn_t=expn_t*adjustment_factor
replace tot_expn=tot_expn*adjustment_factor
drop adjustment_factor* 



save "$dataroot/Forbrugs_Data.dta", replace



