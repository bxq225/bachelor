*******************************************
**** 1. Descriptive Stats by Percentile, Naive 
*******************************************

* i) load data and collapse by year-category & percentile
use "$dataroot/Forbrugs_Data.dta", clear

* ii) generate aggregate expenditures and expenditure shares by decile
* => already done in initial file

* iii) compute Laspeyres inflation
bysort ref_yr husstand: egen laspeyres_t_tp1=sum(expn_shr_t*inflation_t_tplus1)
bysort ref_yr husstand: egen geom_laspeyres_t_tp1=sum(expn_shr_t*log(inflation_t_tplus1))

replace geom_laspeyres_t_tp1=exp(geom_laspeyres_t_tp1)
replace laspeyres_t_tp1 = geom_laspeyres_t_tp1 

* keep only data we need
keep ref_yr tot_expn laspeyres_t_tp1 geom_laspeyres_t_tp1 husstand
duplicates drop
* compute cumulative inflation 
sort husstand ref_yr
gen cum_laspeyres_t_tp1 = laspeyres_t_tp1 if ref_y==2002
by husstand: replace cum_laspeyres_t_tp1=cum_laspeyres_t_tp1[_n-1]*laspeyres_t_tp1 if ref_y>2002

* rescale to 100 in 2002
gen laspeyres_price_index_final=100
by husstand: replace laspeyres_price_index_final = cum_laspeyres_t_tp1[_n-1]*100 if ref_y>2002 

* Figure 2b
twoway connected laspeyres_price_index_final husstand if ref_yr==2022, ///
    xtitle("") ///
    ytitle("Geometric Index in 2022 (2002=100)") ///    
    graphregion(color(white)) ///
    xlabel(1 `" "Enlige under 60" "år uden børn" "' 2 `" "Enlig 60 år og" "over uden børn" "' 3 "Enlige med børn" 4 `" "2 voksne, hoved-" "person under 60" "år uden børn" "' 5 `" "2 voksne," "hovedperson 60 år" "og over uden børn" "' 6 "2 voksne med børn" 7 `" "Husstande med" "mindst 3 voksne" "', angle(90)) ///
    legend(off) ///
    xsize(10) ///
    ysize(8)
graph export "$resrootfig/Fig2b.pdf", as(pdf) replace 

* Figure E1v
gen laspeyres_annual_infl = ((laspeyres_price_index_final/100)^(1/(2022-2002))-1)*100 if ref_yr==2022   
twoway connected laspeyres_annual_infl  husstand if ref_yr==2022, /// 
    xtitle("Husstand") ///
    ytitle("Gennemsnitlig årlig geometrisk" "inflation, 2002-2022, %") ///
    graphregion(color(white)) ///
    xlabel(1 `" "Enlige under 60" "år uden børn" "' 2 `" "Enlig 60 år og" "over uden børn" "' 3 "Enlige med børn" 4 `" "2 voksne, hoved-" "person under 60" "år uden børn" "' 5 `" "2 voksne," "hovedperson 60 år" "og over uden børn" "' 6 "2 voksne med børn" 7 `" "Husstande med" "mindst 3 voksne" "', angle(90)) ///
    ysize(6)
graph export "$resrootfig/FigE1v.pdf", as(pdf) replace 

* prepare and save comparison file we will need for later figures (Fig D3)
gen temp=tot_expn*(ref_yr==2002)
bysort husstand: egen temp2=max(temp)
gen nominal_expenditure=tot_expn/temp2*100
drop temp temp2 

gen real_expenditure=nominal_expenditure/laspeyres_price_index_final*100
egen laspeyres_Max=max(laspeyres_price_index_final) // obtained from other do.file ("aggregate")
gen real_expenditure_naive=nominal_expenditure/laspeyres_Max*100 if ref_yr==2022
gen real_expenditure_growth=(real_expenditure/100-1)*100
gen real_expenditure_growth_naive=(real_expenditure_naive/100-1)*100
gen change_real_exp = real_expenditure_growth_naive - real_expenditure_growth

* export data we can use later for comparison with the NH correction
save "$dataroot/temp", replace 
