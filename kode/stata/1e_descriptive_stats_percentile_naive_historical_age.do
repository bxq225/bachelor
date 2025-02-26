*******************************************
**** 1. Descriptive Stats by Percentile, Naive 
*******************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/cex_micro_1955_2019_final_age", clear

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation
bysort ref_yr inc_d age_d: egen laspeyres_t_tp1=sum(expn_shr_t*annual_gross_infl_tplus1_t)
bysort ref_yr inc_d age_d: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)
replace laspeyres_t_tp1 = geom_laspeyres_t_tp1 
* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 geom_laspeyres_t_tp1 inc_d age_d
duplicates drop
* compute cumulative inflation
egen id=group(inc_d age_d) 
sort id ref_yr
gen cum_laspeyres_t_tp1 = laspeyres_t_tp1 if ref_y==1955
by id: replace cum_laspeyres_t_tp1=cum_laspeyres_t_tp1[_n-1]*laspeyres_t_tp1 if ref_y>1955
* rescale to 100 in 1984
gen laspeyres_price_index_final=100
by id: replace laspeyres_price_index_final = cum_laspeyres_t_tp1[_n-1]*100 if ref_y>1955

keep if ref_yr==2019

collapse (mean) laspeyres_price_index_final , by(age_d)

* Figure 7a
twoway connected laspeyres_price_index_final age_d, xtitle("Age Decile") ytitle("Geometric Index in 2019 (1955=100)")  graphregion(color(white)) xlabel(1(1)10) 
graph export "$resrootfig/Fig7a.pdf", as(pdf) replace 


