***************************************
**** 0. Globals to Be Specified
***************************************

global path "C:\Users/marti/Documents/bachelor"

global dataroot "C:\Users/marti/Documents/bachelor"
global coderoot "C:\Users/marti/Documents/bachelor/kode/stata"
global resrootfig "C:\Users/marti/Documents/bachelor/data/final_data/final_figures"
global resrootdata "C:\Users/marti/Documents/bachelor/data/final_data/results"
global datarootrobustness "C:\Users/marti/Documents/bachelor/data/final_data/robustness_datasets"

***************************************
**** 0. Prepare Raw Data 
***************************************

do ${coderoot}/0a_prepare_data.do 
*do ${coderoot}/0b_prepare_historical_data.do 
*do ${coderoot}/0c_prepare_age_data.do 
*do ${coderoot}/0d_prepare_historical_age_data.do 

*******************************************************
**** 1. Descriptive Stats Aggregate & by Income Group
******************************************************
/*
do ${coderoot}/1a_descriptive_stats_agg.do
do ${coderoot}/1b_descriptive_stats_percentile_naive.do
do ${coderoot}/1c_descriptive_stats_agg_historical.do
do ${coderoot}/1d_descriptive_stats_percentile_naive_historical.do
do ${coderoot}/1e_descriptive_stats_percentile_naive_historical_age.do

*******************************************
**** 2. NH Correction - main back to 1984
*******************************************

* first period as base
do ${coderoot}/2a_i_apply_algorithm_percentile.do
do ${coderoot}/2a_ii_algorithm_results_percentile.do

* last period as base 
do ${coderoot}/2b_i_apply_reverse_algorithm_percentile.do
do ${coderoot}/2b_ii_reverse_algorithm_results_percentile.do

* aggregate results 
do ${coderoot}/2c_algorithm_results_aggregate.do

********************************************
**** 3. NH Correction with historical data
********************************************

* with 1984 as base
do ${coderoot}/3a_apply_algorithm_percentile_historical.do
* repeat with 2019 as base
do ${coderoot}/3b_apply_reverse_algorithm_percentile_historical.do
do ${coderoot}/3c_algorithm_results_aggregate_historical.do

****************************************************************
**** 4. Robustness checks for results across income percentiles
****************************************************************

* with additional controls (education, age, race)
do ${coderoot}/4a_i_apply_algorithm_percentile_controls.do
do ${coderoot}/4a_ii_apply_reverse_algorithm_percentile_controls.do
do ${coderoot}/4a_iii_algorithm_results_aggregate_controls.do
* also run with full extended set of controls
do ${coderoot}/4a_iv_apply_algorithm_percentile_fullcontrols.do
do ${coderoot}/4a_v_apply_reverse_algorithm_percentile_fullcontrols.do
do ${coderoot}/4a_vi_algorithm_results_aggregate_fullcontrols.do

* with Fisher price index in the first-order algorithm 
do ${coderoot}/5a_apply_algorithm_percentile_fisher.do
do ${coderoot}/5b_apply_reverse_algorithm_percentile_fisher.do

* with second-order approximation algorithm
do ${coderoot}/5c_i_apply_algorithm_percentile_order2.do
do ${coderoot}/5c_ii_apply_reverse_algorithm_percentile_order2.do
do ${coderoot}/5c_iii_algorithm_results_aggregate_order2.do

******************************
**** 5. Results by age groups
******************************

do ${coderoot}/6a_apply_algorithm_percentile_historical_age.do
do ${coderoot}/6b_apply_reverse_algorithm_percentile_historical_age.do
do ${coderoot}/6c_algorithm_results_aggregate_historical_age.do 

****************************************************************
**** 6. Appendix robustness checks 
****************************************************************

* robustness 1 (32 product categories)
do ${coderoot}/7a_prepare_data_robustness1.do
do ${coderoot}/7b_i_apply_algorithm_percentile_robustness1.do
do ${coderoot}/7b_ii_apply_reverse_algorithm_percentile_robustness1.do
do ${coderoot}/7c_algorithm_results_aggregate_robustness1.do

* robustness 2 (114 product categories)
do ${coderoot}/8a_prepare_data_robustness2.do
do ${coderoot}/8b_i_apply_algorithm_percentile_robustness2.do
do ${coderoot}/8b_ii_apply_reverse_algorithm_percentile_robustness2.do
do ${coderoot}/8c_algorithm_results_aggregate_robustness2.do

* robustness 3 (CPI relative importance weights)
do ${coderoot}/9a_prepare_historical_data_robustness3.do 
do ${coderoot}/9b_apply_algorithm_percentile_historical_robustness3.do
do ${coderoot}/9c_apply_reverse_algorithm_percentile_historical_robustness3.do
do ${coderoot}/9d_algorithm_results_aggregate_historical_robustness3.do

/*
* robustness 4 (Nielsen data)
do ${coderoot}/10a_prepare_data_robustness4.do
do ${coderoot}/10b_i_apply_algorithm_percentile_robustness4.do
do ${coderoot}/10b_ii_apply_reverse_algorithm_percentile_robustness4.do
do ${coderoot}/10c_algorithm_results_aggregate_robustness4.do
* run comparison to patterns with CPI for goods in the Nielsen sample, over the same time period
do ${coderoot}/10d_i_apply_algorithm_percentile_CEXCPI_robustness4.do
do ${coderoot}/10d_ii_apply_reverse_algorithm_percentile_CEXCPI_robustness4.do
do ${coderoot}/10d_iii_algorithm_results_aggregate_CEXCPI_robustness4.do
* now repeat the analysis with Nielsen data accounting for product variety
do ${coderoot}/10e_prepare_data_robustness4_prodvar.do
do ${coderoot}/10e_i_apply_algorithm_percentile_robustness4_prodvar.do
do ${coderoot}/10e_ii_apply_reverse_algorithm_percentile_robustness4_prodvar.do
do ${coderoot}/10e_iii_algorithm_results_aggregate_robustness4_prodvar.do
*/

* robustness 5 (higher-order polynomial)
** linear
do ${coderoot}/11a_i_apply_algorithm_percentile_orderK1.do
do ${coderoot}/11b_i_apply_reverse_algorithm_percentile_orderK1.do
** third-order polynomial
do ${coderoot}/12a_i_apply_algorithm_percentile_orderK3.do
do ${coderoot}/12b_i_apply_reverse_algorithm_percentile_orderK3.do
do ${coderoot}/12c_algorithm_results_aggregate_orderK3.do

* robustness 6 (algorithm based on the indirect real consumption function) 
** first-order RCF
do ${coderoot}/13a_i_apply_algorithm_RCF_percentile.do
do ${coderoot}/13b_i_apply_reverse_algorithm_RCF_percentile.do
do ${coderoot}/13c_algorithm_results_aggregate_RCF.do
** second-order RCF
do ${coderoot}/14a_i_apply_algorithm_RCF_percentile_order2.do
do ${coderoot}/14b_i_apply_reverse_algorithm_RCF_percentile_order2.do
do ${coderoot}/14c_algorithm_results_aggregate_RCF_order2.do

* robustness 7 (controlling for state fixed effects)
do ${coderoot}/15a_apply_algorithm_percentile_fullstatecontrols.do
do ${coderoot}/15b_apply_reverse_algorithm_percentile_fullstatecontrols.do
do ${coderoot}/15c_algorithm_results_aggregate_fullstatecontrols.do

* robustness 8 (comparison to BBK algorithm)
do ${coderoot}/16_BBKM_comparison.do

* robustness 9 (refined first-order & second order algorithms)
* order 1
do ${coderoot}/17a_i_apply_algorithm_refined_order1_percentile.do
do ${coderoot}/17b_i_apply_reverse_algorithm_refined_order1_percentile.do
do ${coderoot}/17c_algorithm_results_aggregate_refined_order1.do
* order 2
do ${coderoot}/18a_i_apply_algorithm_refined_order2_percentile.do
do ${coderoot}/18b_i_apply_reverse_algorithm_refined_order2_percentile.do
do ${coderoot}/18c_algorithm_results_aggregate_refined_order2.do
* now plot alternative algorithms for final robustness figure
do ${coderoot}/19_algorithm_results_aggregate_refined_order2_order1_RCF.do




