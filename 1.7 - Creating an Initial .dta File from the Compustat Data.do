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

* Create Leverage Variable

gen leverage_ = (dlcq + dlttq)/atq

* Create current assets to total assets ratio variable

gen ca_to_ta = actq/atq

* Create log firm size variable

gen log_size = ln(atq)

* Get fiscal year-quarter variable with 1960q1 = 0 per Stata default

gen fyq = (fyearq - 1960)*4 + fqtr - 1

* Set time series

destring gvkey, replace

tsset gvkey fyq, quarterly

* Create log difference investment variable

by gvkey: gen log_investment = ln(ppentq) - ln(ppentq[_n-1])

* Create investment rate variable

by gvkey: gen investment_rate = (ppentq - ppentq[_n-1])/ppentq[_n-1]

* Create previous quarter sales variable

by gvkey: gen saleq_previous = saleq[_n-1]

*** DROP 2 *** (Observations)

* Replace investment for observations where acquisitions larger than 5% of assets

replace log_investment = . if aqcy > 0.05*atq

* Replace investment for observations where investment rate in the top or bottom 0.5% of the distribution

_pctile investment_rate, percentiles(0.5 99.5)

replace log_investment = . if investment_rate > r(r2) | investment_rate < r(r1)

* Replace investment for observations where current-to-total-assets ratio is < -10 or > 10

replace log_investment = . if ca_to_ta < -10 | ca_to_ta > 10

* Drop observations for which mid-time series interpolation is not possible

by gvkey: drop if _n > 2 & _n < _N & log_investment == . & (log_investment[_n-1] == . | log_investment[_n+1] == .)

* Drop unusable data from the ends of each time series

by gvkey: drop if _n == 1

by gvkey: drop if _n == 2 & log_investment == .

by gvkey: drop if _n == _N & log_investment == .

***        ***

* Export dataset for CPI and Shock Series Alignment in Python

save "C:\Users\oseager\OneDrive\QMUL\ECN325\Scripts\Compustat_93Q1_14Q4_2.dta", replace
