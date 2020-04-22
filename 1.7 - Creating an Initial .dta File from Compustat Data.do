/*

1.7 - Creating an Initial .dta File from Compustat Data

This script starts with quarterly Compustat data between 1993 and 2014, and creates some initial control variables for the analysis in script 1.9, makes some initial drops of unusable data, and exports the abridged dataset to be used in Python in script 1.8.

*/

* Import Dataset

use "C:\Users\oseager\OneDrive\QMUL\ECN325\Scripts\Compustat_93Q1_14Q4.dta", clear

*** DROP 1 *** (Firms)

* Drop financial, insurance, real estate, public administration firms

destring sic, replace

drop if sic >= 6000 & sic < 6800

drop if sic >= 9100 & sic < 9800

* Drop firms not incorporated in the U.S.

drop if loc != "USA"

***        ***

* Create fiscal quarter indicator dummy variables (base dummy is fqtr = 4)

gen fq_1 = 0

replace fq_1 = 1 if fqtr == 1

gen fq_2 = 0

replace fq_2 = 1 if fqtr == 2

gen fq_3 = 0

replace fq_3 = 1 if fqtr == 3

* Get fiscal year-quarter variable with 1960q1 = 0 per Stata default

gen fyq = (fyearq - 1960)*4 + fqtr - 1

* Set time series

destring gvkey, replace

tsset gvkey fyq, quarterly

* Create Leverage Variable

by gvkey: gen leverage_ = (dlcq[_n-2] + dlttq[_n-2])/atq[_n-2]

* Create current assets to total assets ratio variable

gen ca_to_ta = actq[_n-2]/atq[_n-2]

* Create log firm size variable

gen log_size = ln(atq[_n-2])

* Create log difference investment variable

by gvkey: gen log_investment = ln(ppentq) - ln(ppentq[_n-1])

* Create investment rate variable

by gvkey: gen investment_rate = (ppentq - ppentq[_n-1])/ppentq[_n-1]

* Create previous quarter sales variable

by gvkey: gen saleq_previous = saleq[_n-3]

*** DROP 2 *** (Observations)

* Replace investment for observations where acquisitions larger than 5% of assets

replace log_investment = . if aqcy > 0.05*atq

* Replace investment for observations where investment rate in the top or bottom 0.5% of the distribution

_pctile investment_rate, percentiles(0.5 99.5)

replace log_investment = . if investment_rate > r(r2) | investment_rate < r(r1)

* Replace investment for observations where current-to-total-assets ratio is < -10 or > 10

replace log_investment = . if ca_to_ta < -10 | ca_to_ta > 10

* Drop if leverage > 10

replace log_investment = . if leverage_ > 10

* Drop observations for which mid-time series interpolation is not possible

by gvkey: drop if _n > 2 & _n < _N & log_investment == . & (log_investment[_n-1] == . | log_investment[_n+1] == .)

* Drop unusable data from the ends of each time series

by gvkey: drop if _n == 1

by gvkey: drop if _n == 2 & log_investment == .

by gvkey: drop if _n == _N & log_investment == .

***        ***

* Create empty purged and unpurged Nakamura and Steinsson (2018) shock variables to be filled in Python (script 1.8)

gen ns_shock_p = .

gen ns_shock_r = .

* Create empty purged and unpurged Daily Data shock variables to be filled in Python (script 1.8)

gen s_shock_p = .

gen s_shock_r = .

* Create empty quarterly CPI increase (proportional) variable to be filled in Python (script 1.8)

gen cpi_increase = .

* Create empty reported-year-quarter, true-year and true-quarter-start variables to be filled in Python (script 1.8)

gen year_quarter = .

gen true_qstart = .

gen true_y = .

* Export dataset for CPI and Shock Series Alignment in Python

save "C:\Users\oseager\OneDrive\QMUL\ECN325\Scripts\Compustat_93Q1_14Q4_2.dta", replace
