***************************************
**** 1. Descriptive Stats Aggregate 
***************************************

* i) load data and collapse by year-category
use "$dataroot/cex_micro_1984_2019_final", clear
collapse (sum)  expn_t , by(ref_yr ucc_str annual_gross_infl_tplus1_t)
* correct value since we summed from percentile-level data:
replace  expn_t= expn_t/100

* ii) generate aggregate expenditures and expenditure shares
bysort ref_yr: egen double tot_expn=sum(expn_t)
gen expn_shr_t = expn_t/tot_expn

* iii) compute Laspeyres inflation
bysort ref_yr: egen laspeyres_t_tp1=sum(expn_shr_t*annual_gross_infl_tplus1_t)
bysort ref_yr: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)
replace laspeyres_t_tp1=geom_laspeyres_t_tp1
* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 geom_laspeyres_t_tp1
duplicates drop
* compute cumulative inflation 
gen cum_laspeyres_t_tp1 = laspeyres_t_tp1 if ref_y==1984
replace cum_laspeyres_t_tp1=cum_laspeyres_t_tp1[_n-1]*laspeyres_t_tp1 if ref_y>1984
* rescale to 100 in 1984
gen laspeyres_price_index_final=100
replace laspeyres_price_index_final = cum_laspeyres_t_tp1[_n-1]*100 if ref_y>1984 

* Figure 2a
scatter laspeyres_price_index_final ref_y, xtitle("Year") ytitle("Geometric Index (1984=100)") graphregion(color(white)) xlabel(1984(5)2019) ylabel(100(20)240)
graph export "$resrootfig/Fig2a.pdf", as(pdf) replace 

