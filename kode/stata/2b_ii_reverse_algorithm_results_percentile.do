***************************************
**** 2b ii. NH Correction: plot results
***************************************

* i) load data
use "$resrootdata/nh_percentiles_reverse.dta", clear

* ii) show Laspeyres homothetic vs. corrected Laspeyres in last year 
gen p_naive = exp(y-qu)*100
gen p_full = exp(y-q)*100

* here can check we replicate exactly the previous price index with homothetic utility:
 gen check = 1/(p_naive/100)*100
 twoway connected check indkomstgruppe if ref_yr==2022
* this is identical to figure 7b, as desired 

* fig E2ii
twoway connected p_naive indkomstgruppe if ref_yr_o==2003 || connected p_full indkomstgruppe if ref_yr_o==2003, ///
   xtitle("") ///
   ytitle("Geometrisk indeks i 2003 (2022=100)") ///
   graphregion(color(white)) ///
   xlabel(1(1)5) ///
   legend(order(1 "Indkomstgrupper indeks" 2 "Med NH korrektion") rows(2))
graph export "$resrootfig/FigE2ii_indkomst.pdf", as(pdf) replace

** iii) show annual bias correction
replace annual_bias_percent=annual_bias_percent*100
* fig 4Aii with tendency line
twoway ///
   (scatter annual_bias_percent indkomstgruppe if ref_yr_o==2003) ///
   (lfit annual_bias_percent indkomstgruppe if ref_yr_o==2003), ///
   xtitle("") ///
   ytitle("Aarlig Bias i reel forbrugsvækst (%), 2003") ///
   xlabel(1(1)5) ///
   legend(off)
graph export "$resrootfig/Fig4Aii_indkomst.pdf", as(pdf) replace


* plot adjustment to real consumption in level in final year
foreach i in y qu q {
	gen double `i'_level=exp(`i')
}
gen pc_dev_real_cons = (qu_level-q_level)/qu_level*100

* fig 4Bii
scatter pc_dev_real_cons indkomstgruppe if ref_yr_o==2003 || lfit pc_dev_real_cons indkomstgruppe if ref_yr_o==2003, ///
   xtitle("") ///
   ytitle("Bias i 2003 reel forbrugsniveau, %") ///
   graphregion(color(white)) ///
   xlabel(1(1)5) ///
   legend(off)
graph export "$resrootfig/Fig4Bii_indkomst.pdf", as(pdf) replace


* iii) depict NH adjustment to real cumulative consumption growth 
keep if ref_yr_o==2003 | ref_yr_o==2022

sort indkomstgruppe ref_yr_o
foreach i in q qu y {
    
   by indkomstgruppe: gen double growth_`i'=`i'-`i'[_n-1]
   by indkomstgruppe: gen growth_`i'_pp=(exp(`i')/exp(`i'[_n-1])-1)*100
   
}

gen bias_pp=growth_qu_pp - growth_q_pp

drop ref_yr 
rename ref_yr_o ref_yr 

merge 1:1 indkomstgruppe ref_yr using "$dataroot/temp"
keep if _merge==3

twoway connected change_real_exp indkomstgruppe || connected bias_pp indkomstgruppe, ///
   xtitle("") ///
   ytitle("Bias i kumulativ reel forbrugsvækst" "2003-2022, pp (% af 2022 nominelle udgifter)") ///
   graphregion(color(white)) ///
   xlabel(1(1)5) ///
   legend(order(1 "Fra indkomstgrupper indeks" 2 "Fra NH korrektion") rows(2))
graph export "$resrootfig/FigE3ii_indkomst.pdf", as(pdf) replace

