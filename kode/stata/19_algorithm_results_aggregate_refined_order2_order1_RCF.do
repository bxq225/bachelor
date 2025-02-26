**********************************************************************************
**** 19. This file produces a combined figure with the results of several algorithms: 
**** RCF and refined, orders 1 and 2
**********************************************************************************

use "$dataroot/RCF_refined_figure", clear 

scatter pc_dev_real_cons_1984_RCF ref_yr, msymbol(O) msize(small) || scatter pc_dev_real_cons_RCF ref_yr, msymbol(D) msize(small) || ///
scatter pc_dev_real_cons_1984_RCF2 ref_yr, msymbol(T) msize(small) || scatter pc_dev_real_cons_RCF2 ref_yr, msymbol(S) msize(small) ///
|| scatter pc_dev_real_cons_1984_refined ref_yr, msymbol(Oh) msize(small) || scatter pc_dev_real_cons_1984_refined2 ref_yr, msymbol(Dh) msize(small) ///
|| scatter pc_dev_real_cons_refined ref_yr, msymbol(Th) msize(small) || scatter pc_dev_real_cons_refined2 ref_yr, msymbol(Sh) msize(small) ///
xtitle("Year") ytitle("Bias in Average Real Consumption")  graphregion(color(white)) xlabel(1984(5)2019) ylabel(-3(0.5)0, labsize(small)) ///
legend(size(small) order(1 "1984 base prices, RCF 1st-order" 2 "2019 base prices, RCF 1st-order" ///
3 "1984 base prices, RCF 2nd-order" 4 "2019 base prices, RCF 2nd-order" ///
5 "1984 base prices, Refined 1st-order" 6 "2019 base prices, Refined 1st-order" ///
7 "1984 base prices, Refined 2nd-order" 8 "2019 base prices, Refined 2nd-order" ))
graph export "$resrootfig/FigE7.pdf", as(pdf) replace
