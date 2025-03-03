***************************************
**** 1. Descriptive Stats Aggregate 
***************************************

* i) load data and collapse by year-category
use "$dataroot/Forbrugs_Data.dta", clear

* ii) generate aggregate expenditures and expenditure shares
collapse (sum)  expn_t, by(ref_yr kategori indkomstgruppe gns_pris_indeks inflation_t_tminus1 inflation_t_tplus1)

replace expn_t=expn_t/5
bysort ref_yr: egen double tot_expn=sum(expn_t)
gen expn_shr_t = expn_t/tot_expn

* iii) compute Laspeyres inflation
bysort ref_yr: egen laspeyres_t_tp1=sum(expn_shr_t*inflation_t_tplus1)
bysort ref_yr: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(inflation_t_tplus1))
replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)
replace laspeyres_t_tp1=geom_laspeyres_t_tp1
* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 geom_laspeyres_t_tp1
duplicates drop
* compute cumulative inflation 
gen cum_laspeyres_t_tp1 = laspeyres_t_tp1 if ref_y==2007
replace cum_laspeyres_t_tp1=cum_laspeyres_t_tp1[_n-1]*laspeyres_t_tp1 if ref_y>2007
* rescale to 100 in 1984
gen laspeyres_price_index_final=100
replace laspeyres_price_index_final = cum_laspeyres_t_tp1[_n-1]*100 if ref_y>2007 

* Figure 2a
scatter laspeyres_price_index_final ref_y, xtitle("Year") ytitle("Geometric Index (1984=100)") graphregion(color(white)) xlabel(2007(2)2022) ylabel(100(2)115)
graph export "$resrootfig/Fig2a.pdf", as(pdf) replace 

