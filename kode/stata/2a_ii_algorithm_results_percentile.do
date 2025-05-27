***************************************
**** 2a ii. NH Correction: plot results
***************************************

* i) load data
use "$resrootdata/nh_percentiles.dta", clear

* ii) show Laspeyres homothetic vs. corrected Laspeyres in last year 
gen p_naive = exp(y-qu)*100
gen p_full = exp(y-q)*100

twoway connected p_naive husstand if ref_yr==2022 || connected p_full husstand if ref_yr==2022, ///
   xtitle("Husstande") ///
   ytitle("Geometrisk indeks i 2022 (2003=100)")  ///
   graphregion(color(white)) ///
   xlabel(1 `" "Enlige under 60" "år uden børn" "' 2 `" "Enlig 60 år og" "over uden børn" "' 3 "Enlige med børn" 4 `" "2 voksne, hoved-" "person under 60" "år uden børn" "' 5 `" "2 voksne," "hovedperson 60 år" "og over uden børn" "' 6 "2 voksne med børn" 7 `" "Husstande med" "mindst 3 voksne" "', angle(90)) ///
   legend(order(1 "Husstand indeks" 2 "Med NH korrektion") rows(2)) ///
   xsize(10) ///
   ysize(6)
graph export "$resrootfig/FigE2i.pdf", as(pdf) replace

** iii) show annual bias correction
replace annual_bias_percent=annual_bias_percent*100

scatter annual_bias_percent husstand if ref_yr==2022 || lfit annual_bias_percent husstand if ref_yr==2022, ///
   xtitle("Husstand") ///
   ytitle("Årlig Bias i reel" "forbrugsvækst (%), 2022") ///
   graphregion(color(white)) ///
   xlabel(1 `" "Enlige under 60" "år uden børn" "' 2 `" "Enlig 60 år og" "over uden børn" "' 3 "Enlige med børn" 4 `" "2 voksne, hoved-" "person under 60" "år uden børn" "' 5 `" "2 voksne," "hovedperson 60 år" "og over uden børn" "' 6 "2 voksne med børn" 7 `" "Husstande med" "mindst 3 voksne" "', angle(90)) ///
   legend(off) ///
   ysize(6)
graph export "$resrootfig/Fig4Ai.pdf", as(pdf) replace


* plot adjustment to real consumption in level in final year
foreach i in y qu q {
	gen double `i'_level=exp(`i')
}
gen pc_dev_real_cons = (qu_level-q_level)/qu_level*100

* fig 12d
scatter pc_dev_real_cons husstand if ref_yr==2022 || lfit pc_dev_real_cons husstand if ref_yr==2022, ///
   xtitle("Husstand") ///
   ytitle("Bias i 2022 reel" "forbrugs niveau, %") ///
   graphregion(color(white)) ///
   xlabel(1 `" "Enlige under 60" "år uden børn" "' 2 `" "Enlig 60 år og" "over uden børn" "' 3 "Enlige med børn" 4 `" "2 voksne, hoved-" "person under 60" "år uden børn" "' 5 `" "2 voksne," "hovedperson 60 år" "og over uden børn" "' 6 "2 voksne med børn" 7 `" "Husstande med" "mindst 3 voksne" "', angle(90)) ///
   legend(off) ///
   ysize(6) 
graph export "$resrootfig/Fig4Bi.pdf", as(pdf) replace

* iii) depict NH adjustment to real cumulative consumption growth 
keep if ref_yr==2003 | ref_yr==2022

sort husstand ref_yr
foreach i in q qu y {
    
   by husstand: gen double growth_`i'=`i'-`i'[_n-1]
   by husstand: gen growth_`i'_pp=(exp(`i')/exp(`i'[_n-1])-1)*100
   
}

gen bias_pp=growth_qu_pp-growth_q_pp

merge 1:1 husstand ref_yr using "$dataroot/temp"
keep if _merge==3

twoway connected change_real_exp husstand || connected bias_pp husstand, ///
   xtitle("Husstand") ///
   ytitle("Bias i kumulativ reel forbrugs-" "vækst 2002-2022, pp " "(% af 2002 nominelle udgifter)") ///
   graphregion(color(white)) ///
   xlabel(1 `" "Enlige under 60" "år uden børn" "' 2 `" "Enlig 60 år og" "over uden børn" "' 3 "Enlige med børn" 4 `" "2 voksne, hoved-" "person under 60" "år uden børn" "' 5 `" "2 voksne," "hovedperson 60 år" "og over uden børn" "' 6 "2 voksne med børn" 7 `" "Husstande med" "mindst 3 voksne" "', angle(90)) ///
   legend(order(1 "Fra husstand indeks" 2 "Fra NH korrektion") rows(2)) ///
   xsize(12) ///
   ysize(8)
graph export "$resrootfig/FigE3i.pdf", as(pdf) replace
