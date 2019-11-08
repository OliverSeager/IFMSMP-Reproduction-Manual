/*
1.9 - Measuring Firm-level Investment Responsiveness to each Series

This script measures firm-level responsiveness to the purged and unpurged versions of my daily data series and the Nakamura and Steinsson (2018) series.

*/

* Import the augmented data set created in 1.8

use "C:\Users\oseager\OneDrive\QMUL\ECN325\Scripts\Compustat_93Q1_14Q4_3.dta", clear

* Get fiscal year-quarter variable with 1960q1 = 0 per Stata default (fyq from script 1.7 is now a clocktime variable instead of an integer, so new one created)

drop fyq

gen fyq = (fyearq - 1960)*4 + fqtr - 1

* Set time series

tsset gvkey fyq, quarterly

* Create real sales growth variable

gen rsg = saleq[_n-2]/(saleq_previous*cpi_increase[_n-2]) - 1

*** DROP 3 *** (observations)

* Drop real sales growth > 1 or < -1

drop if rsg > 1 | rsg < -1

***        ***

* Impute investment for one-observation gaps in runs of investment

by gvkey: replace log_investment = (log_investment[_n-1] + log_investment[_n+1])/2 if log_investment == . & _n > 1 & _n < _N & log_investment[_n-1] != . & log_investment[_n+1] != .

* Isolate runs of existent log_investment variables of 40 quarters or longer for a given firm

gen run_count = 0

by gvkey: replace run_count = 1 if log_investment[_n-1] == . & log_investment != .

egen min_ = min(fyq)

egen max_ = max(fyq)

sca M = max_ - min_ + 1

forvalues i = 1/`=M' {

by gvkey: replace run_count = run_count[_n-1] + 1 if _n == `i' & run_count[_n-1] > 0 & run_count[_n-1] != . & log_investment != .

}

forvalues i = `=M'(-1)1 {

by gvkey: replace run_count = run_count[_n+1] if _n == `i' & run_count[_n+1] > run_count & run_count[_n+1] != . & log_investment != .

}

*** DROP 4 *** (Observation runs)

* Drop runs of observations with less than 40 consecutive quarters of investment data

drop if run_count < 40

***        ***
* Recreate Otonello & Winberry (2019)

gen ow_s_r = leverage_*s_shock_r

gen ow_s_p = leverage_*s_shock_p

gen ow_ns_r = leverage_*ns_shock_r

gen ow_ns_p = leverage_*ns_shock_p


* Create industry variable

gen industry = .

replace industry = 1 if sic < 1000

replace industry = 2 if sic >= 1000 & sic < 1400

replace industry = 3 if sic >= 1500 & sic < 1800

replace industry = 4 if sic >= 2000 & sic < 4000

replace industry = 5 if sic >= 4000 & sic < 5000

replace industry = 6 if sic >= 5000 & sic < 5200

replace industry = 7 if sic >= 5200 & sic < 6000

replace industry = 8 if sic >= 7000 & sic < 9000

* Regressions (Whole period)

reghdfe log_investment ow_s_p leverage_ rsg log_size ca_to_ta fq_1 fq_2 fq_3, absorb(gvkey industry#true_q) cluster(gvkey true_q) /*Daily Data Series, purged*/

reghdfe log_investment ow_ns_p leverage_ rsg log_size ca_to_ta fq_1 fq_2 fq_3, absorb(gvkey industry#true_q) cluster(gvkey true_q) /*Nakamura and Steinsson series, purged*/

* Regressions (pre-ZLB)

reghdfe log_investment ow_s_p leverage_ rsg log_size ca_to_ta fq_1 fq_2 fq_3 if true_q <= 195, absorb(gvkey industry#true_q) cluster(gvkey true_q) /*Daily Data Series, purged*/

reghdfe log_investment ow_ns_p leverage_ rsg log_size ca_to_ta fq_1 fq_2 fq_3 if true_q <= 195, absorb(gvkey industry#true_q) cluster(gvkey true_q)  /*Nakamura and Steinsson series, purged*/

* Regressions (ZLB)

reghdfe log_investment ow_s_p leverage_ rsg log_size ca_to_ta fq_1 fq_2 fq_3 if true_q > 195, absorb(gvkey industry#true_q) cluster(gvkey true_q)  /*Daily Data Series, purged*/

reghdfe log_investment ow_ns_p leverage_ rsg log_size ca_to_ta fq_1 fq_2 fq_3 if true_q > 195, absorb(gvkey industry#true_q) cluster(gvkey true_q) /*Nakamura and Steinsson series, purged*/
