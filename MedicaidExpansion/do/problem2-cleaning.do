
** Cleaning Excel spreadsheet of health insurance rates by state from the Census

* Note: Most of you will have cleaned and manipulated this dataset in Excel. That is  
* fine for full credit, as long as you did the analysis work in Stata or another scripting  
* language. However, it can be useful to learn how to do this kind of cleaning 
* in Stata. There are many ways to do it, and the below is an (advanced)
* example that utilizes loops, if statements, and macros.

import excel using hic04_acs.xls, clear

* This is a loop that renames each variable according to the year the variable 
* corresponds to, as found on line 4, and the type of estimator, found on line 5

foreach var of varlist C-AT {
	levelsof `var' in 4, local(line4)
	levelsof `var' in 5, local(line5)
	if "`line4'" != "" {
		local stub = `line4'
		di "`stub'"
	}
	local type = subinstr(`line5', " ", "_", .)
	ren `var' `var'_`type'_`stub'
}

* This cuts down the data, keeping column A, containing country name, column B, 
* containing the line information, and all the columns with "Percent" in the name, 
* which is what we'll need

keep A B *_Percent_*
drop in 1/5 			/* Drops the first five lines */
drop in 573/578 		/* Drops the last six lines, which contain only notes */
compress 				/* Makes the A column shrink in the viewer */ 

* Next, we need to make sure each row has state information - as you can see in the
* data, the name of the state appears once, then that state name applies for each 
* of the next 10 rows. We essentially need to "fill" downwards using a loop over
* every line

count
foreach line_no of numlist 1/`r(N)' {
	levelsof A in `line_no', clean local(colA)
	if "`colA'" != "" {
		local state = "`colA'"
	}
	else {
		replace A = "`state'" in `line_no'
	}
}

* A little cleanup

ren A state
ren B type

														   
* Renaming the Percent variables to be consistently named

foreach year of numlist 2018/2008 {
	rename *_`year' Percent`year'
}

* Now, reshaping the data to be "long" where there is one line for each state-year-type

reshape long Percent, i(state type) j(year)


* Making the Percent variable numeric 

replace Percent = "" if Percent=="N" 		 /* Delaware is missing data in 2017, 
														   per the table notes */
destring Percent, replace


save hic04_acs_clean.dta, replace
