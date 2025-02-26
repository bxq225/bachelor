*******************************************
**** 1. Descriptive Stats by Percentile, Naive 
*******************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/cex_micro_1955_2019_final", clear

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation
bysort ref_yr inc_percentile: egen laspeyres_t_tp1=sum(expn_shr_t*annual_gross_infl_tplus1_t)
bysort ref_yr inc_percentile: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(annual_gross_infl_tplus1_t))
replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)
replace laspeyres_t_tp1 = geom_laspeyres_t_tp1 
* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 geom_laspeyres_t_tp1 inc
duplicates drop
* compute cumulative inflation 
sort inc_p ref_yr
gen cum_laspeyres_t_tp1 = laspeyres_t_tp1 if ref_y==1955
by inc_p: replace cum_laspeyres_t_tp1=cum_laspeyres_t_tp1[_n-1]*laspeyres_t_tp1 if ref_y>1955
* rescale to 100 in 1984
gen laspeyres_price_index_final=100
by inc_p: replace laspeyres_price_index_final = cum_laspeyres_t_tp1[_n-1]*100 if ref_y>1955

* Figure 2d
twoway connected laspeyres_price_index_final inc_p if ref_yr==2019, xtitle("Pre-tax Income Percentile") ytitle("Geometric Index in 2019 (1955=100)")  graphregion(color(white)) xlabel(0(5)100) 
graph export "$resrootfig/Fig2d.pdf", as(pdf) replace 

* Figure E1vi
gen laspeyres_annual_infl = ((laspeyres_price_index_final/100)^(1/(2019-1955))-1)*100 if ref_yr==2019
twoway connected laspeyres_annual_infl  inc_percentile if ref_yr==2019, xtitle("Pre-tax Income Percentile") ytitle("Average Annual Geometric Inflation," "1955-2019, %")  graphregion(color(white)) xlabel(0(5)100) 
graph export "$resrootfig/FigE1vi.pdf", as(pdf) replace 

