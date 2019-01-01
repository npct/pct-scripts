clear
clear matrix
cd "C:\Users\Anna Goodman\Dropbox\GitHub"
		
*!* change 'commute_microsim' folders (in various places) to 'commute' when actually implement this
x

	/***********************
	* PREPARE THE INPUT INDIVIDUAL-LEVEL SYNTHETIC POP FROM CENSUS [overlap with metahit work] (INPUT 1)
	***********************
		** RAW INPUTS TO MAKE 'Census2011EW_AllAdults.dta' [all safe-guarded]
			* LSOA-level Age*Sex*T2!: WICID WM12EW[CT0489]_lsoa.csv 
			* Ethnicity, all flows: WICID wu08cew_msoa_v1.csv
			* Ethnicity * T2W, selected flows: WICID CT0600.xls --> use to make CT0600_edit.xls editting top rows
			* Car ownership, all flows: WICID wu09buk_msoa_v1.csv
			* Car ownership * T2W, selected flows: WICID CT0599.xls --> use to make CT0599_edit.xls editting top rows
			* Individual-level data 5% sample, regional level: UKDA, 'isg_regionv2.dta' from https://discover.ukdataservice.ac.uk/catalogue/?sn=7605&type=Data%20catalogue
			* Individual-level data 5% sample, LA level: UKDA, 'recodev12.dta' from https://discover.ukdataservice.ac.uk/catalogue/?sn=7682&type=Data%20catalogue
			* Area-level Index Multiple Deprivation 2015 (Eng)/2014 (Wales)
			* Area-level Rural Urban Classification 2011

		** DO FILES TO MAKE 'Census2011EW_AllAdults.dta':
			* "..\1 - Phys Act_1-PA main\2017_MetaHIT_analysis\2_program\0.1a_CensusCommuteSP_build_180306.do" 
			* "..\1 - Phys Act_1-PA main\2017_MetaHIT_analysis\2_program\0.1b_CensusNonCommuteSP_build_180306.do" 
		
	***********************
	* PREPARE GEOG LOOK UP FILES 
	***********************
		import delimited "pct-inputs\02_intermediate\x_temporary_files\unzip\OA11_LSOA11_MSOA11_LAD11_EW_LUv2.csv", varnames(1) clear 
		drop oa11cd
		duplicates drop
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\LSOA11_MSOA11_LAD11_EW_LUv2.dta", replace
		
		foreach x in msoa lsoa {
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\LSOA11_MSOA11_LAD11_EW_LUv2.dta", clear
		rename lso11anm lsoa11nm
		rename `x'11cd geo_code
		rename `x'11nm geo_name
		rename lad11nm lad_name
		keep geo_code geo_name lad11cd lad_name
		duplicates drop
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\`x'\geo_code_lookup.dta", replace		
		}
		
	***************************
	** MORTALITY DATA FOR COMMUTERS (INPUT 2)
	***************************
		import excel "pct-inputs\01_raw\03_health_data\commute_microsim\LA_WeightedMortality16plus_2016.xls", sheet("Commuters_MortRate") clear firstrow
		* FIX GEOGRAPHIES
			gen temp=1
			recode temp 1=2 if geography=="Cornwall,Isles of Scilly"
			recode temp 1=2 if geography=="Westminster,City of London"
			expand temp
			bysort geography: gen littlen=_n
			* FIX PLACES WITH SMALL AREAS MERGED
				replace geographycode="E06000053" if geographycode=="E06000052" & littlen==2 	// ISLES OF SCILLY, NOT CORNWALL
				replace geography="Cornwall" if geographycode=="E06000052"
				replace geography="Isles of Scilly" if geographycode=="E06000053"
				replace geographycode="E09000001" if geographycode=="E09000033" & littlen==2	// CITY OF LONDON, NOT WESTMINSTER
				replace geography="Westminster" if geographycode=="E09000033"
				replace geography="City of London" if geographycode=="E09000001"
			* FIX PLACES WITH 2014 NOT 2011 LA CODES
				replace geographycode="E06000048" if geographycode=="E06000057"
				replace geographycode="E07000100" if geographycode=="E07000240"
				replace geographycode="E07000104" if geographycode=="E07000241"
				replace geographycode="E07000097" if geographycode=="E07000242"
				replace geographycode="E07000101" if geographycode=="E07000243"
				replace geographycode="E08000020" if geographycode=="E08000037"
			drop temp littlen
				
		* RENAME
			rename *16to24* *age1*
			rename *25to34* *age2*
			rename *35to49* *age3*
			rename *50to64* *age4*
			rename *65to74* *age5*
			rename *75plus* *age6*
			rename *fem* *sex2*
			rename *mal* *sex1*
			rename mort* mortrate1*
			rename *_sex* *0*
			rename *_age* *0*
			
		* RESHAPE
			gen littlen=_n
			reshape long mortrate,i(littlen) j(celltype) 
			tostring celltype, gen(typestring)
			gen sex=substr(typestring,3,1)
			gen agecat=substr(typestring,5,1)
			destring sex agecat, replace
			gen female=sex-1
			
			rename geographycode home_lad11cd
			order home_lad11cd female agecat mortrate
			keep home_lad11cd-mortrate
			compress
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\0temp\mortrate_individual_CommuteSP.dta", replace

	**********************************	
	* PREPARE CYCLE STREETS DATA - SAVE AS STATA (INPUT 3)
	**********************************	
		import delimited "pct-inputs\02_intermediate\02_travel_data\commute\msoa\rfrq_all_data.csv", clear
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\msoa\rfrq_all_data.dta", replace
		import delimited "pct-inputs\02_intermediate\02_travel_data\commute\lsoa\rfrq_all_data.csv", clear
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\lsoa\rfrq_all_data.dta", replace
	*/	

	*****************
	** MERGE OD DATA
	*****************
	use "..\1 - Phys Act_1-PA main\2017_MetaHIT_analysis\1b_datacreated\Census2011EW_AllAdults.dta", clear
			drop census_id ecactivity commute_distcat commute_bicycle12- commute_bus12
			
		* DROP WORK FROM HOME OR NON-COMMUTERS
			drop if work_lsoa=="OD0000001" | work_lsoa==""
					
		* MERGE IN MORT RATES
			merge m:1 home_lad11cd agecat female using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\0temp\mortrate_individual_CommuteSP.dta", nogen

		* MERGE IN CYCLE STREETS VARIABLES
			rename home_lsoa geo_code1
			rename work_lsoa geo_code2
			merge m:1 geo_code1 geo_code2 using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\lsoa\rfrq_all_data.dta", keepus(rf_dist_km rf_avslope_perc)
			drop if _merge==2
			drop _merge
			rename geo_code1 geocodetemp
			rename geo_code2 geo_code1
			rename geocodetemp geo_code2
			merge m:1 geo_code1 geo_code2 using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\lsoa\rfrq_all_data.dta", keepus(rf_dist_km rf_avslope_perc) update
			drop if _merge==2
			drop _merge
			rename geo_code1 work_lsoa
			rename geo_code2 home_lsoa
				
	*****************
	** STEP 1: GENERATE FLOW TYPE
	*****************
		gen work_lsoatemp=substr(work_lsoa,1,1)
		replace work_lsoa="OutsideEW" if work_lsoatemp=="S" | work_lsoatemp=="N" | work_lsoa=="OD0000002" | work_lsoa=="OD0000004"
			* Make 'other' if S = scotland, N = northern ireland, OD0000002 = offshore installation, OD0000004 = otherwise overseas

		gen flowtype=.
		recode flowtype .=1 if (work_lsoatemp=="E" | work_lsoatemp=="W") & rf_dist_km!=. & home_lsoa!=work_lsoa
		recode flowtype .=2 if home_lsoa==work_lsoa
		recode flowtype .=3 if work_lsoa=="OD0000003"
		recode flowtype .=4 if (work_lsoatemp=="E" | work_lsoatemp=="W") & rf_dist_km==. 
		recode flowtype .=4 if work_lsoa=="OutsideEW"
		label def flowtypelab 1 "England/Wales between-zone" 2 "Within zone" 3 "No fixed place" 4 "Over max dist or outside England/Wales, offshore installation", modify
		label val flowtype flowtypelab
		drop work_lsoatemp
		
		replace work_lsoa="Other" if flowtype==4
		replace work_msoa="Other" if flowtype==4
			
		/** COUNT NO PEOPLE PER FLOWTYPE - TABLE 1 IN MANUAL C1
			ta flowtype // % commuters
			ta flowtype if commute_mainmode9==1 // % cyclists
		*/
		
	*****************
	** STEP 2: ASSIGN VALUES IF DISTANCE/HILLINESS UNKNOWN
	*****************				
		** ASSIGN ESTIMATED HILLINESS + DISTANCE VALUES IF START AND END IN SAME PLACE
			by home_lsoa work_lsoa, sort: gen littlen1=_n
			by littlen1 home_lsoa (rf_dist_km), sort: gen littlen2=_n
			foreach x in rf_dist_km rf_avslope_perc {
			gen `x'temp=`x'
			replace `x'temp=. if littlen2>3 | littlen1>1
			bysort home_lsoa: egen `x'temp2=mean(`x'temp)
			replace `x'=`x'temp2 if flowtype==2 & `x'==.
			}
			replace rf_dist_km=rf_dist_km/3 if flowtype==2 
				* DISTANCE = A THIRD OF THE MEAN DISTANCE OF SHORTEST 3 FLOWS
				* HILLINESS = MEAN HILLINESS OF SHORTEST 3 FLOWS
			recode rf_dist_km .=0.79 if (home_lsoa=="E02006781" | home_lsoa=="E01019077") & home_lsoa==work_lsoa 		//ISLES OF SCILLY [msoa/lsoa] - ESTIMATED FROM DISTANCE DISTRIBUTION
			recode rf_avslope_perc .=0.2 if (home_lsoa=="E02006781" | home_lsoa=="E01019077") & home_lsoa==work_lsoa //ISLES OF SCILLY [msoa/lsoa] - ESTIMATED FROM CYCLE STREET 
			drop littlen1 littlen2 rf_dist_kmtemp rf_dist_kmtemp2 rf_avslope_perctemp rf_avslope_perctemp2 
			
		** ASSIGN DISTANCE *AMONG CYCLISTS* VALUES IF NO FIXED PLACE : MEAN DIST AMONG CYCLISTS TRAVELLING <15KM
			gen cyc_dist_km=rf_dist_km
			foreach x in 15 30 {
			gen rf_dist_km`x'=rf_dist_km
			replace rf_dist_km`x'=. if rf_dist_km>`x' | flowtype>2
			gen bicycle`x'=(commute_mainmode9==1)
			replace bicycle`x'=. if rf_dist_km`x'==.
			}
			bysort home_lsoa: egen numnrf_dist_km15=sum(rf_dist_km15*bicycle15)
			bysort home_lsoa: egen denrf_dist_km15=sum(bicycle15)
			gen meanrf_dist_km15=numnrf_dist_km15/denrf_dist_km15
			replace cyc_dist_km=meanrf_dist_km15 if flowtype==3 

		** ASSIGN DISTANCE *AMONG CYCLISTS* VALUES IF OUTSIDE ENG/WALES OR >30KM: MEAN DIST AMONG CYCLISTS TRAVELLING <30KM
			egen numnrf_dist_km30=sum(rf_dist_km30*bicycle30)
			egen denrf_dist_km30=sum(bicycle30)
			gen meanrf_dist_km30=numnrf_dist_km30/denrf_dist_km30
			replace cyc_dist_km=meanrf_dist_km30 if flowtype==4 
			replace cyc_dist_km=meanrf_dist_km30 if flowtype==3 & cyc_dist_km==.	// USE 30KM if NO LOCAL CYCLIST GOING <15KM
		
		order home_lsoa- work_msoa flowtype rf_dist_km rf_avslope_perc cyc_dist_km mortrate commute_mainmode9 female agecat nonwhite nocar urbancat5 sparse incomedecile
		keep home_lsoa-incomedecile
		compress
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\0temp\CommuteSPTemp1.dta", replace
		
	*****************
	** STEP 3A: CALCULATE PROPENSITY TO CYCLE
	*****************
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\0temp\CommuteSPTemp1.dta", clear
		** INPUT PARAMETERS FLOW TYPE 1+2
			recode commute_mainmode9 2/max=0,gen(bicycle)
			recode agecat 6=5, gen(agecat5)
			recode agecat 1/3=.,gen(agecat_old)
			recode agecat 1/3=1 4/6=2, gen(femagecat)
			replace femagecat=(femagecat+10) if female==1
			label def femagecatlab 1 "Male 16 to 49" 2 "Male 50+" 11 "Female 16 to 49" 12 "Female 50+" 
			label val femagecat femagecatlab
			recode incomedecile 1/2=1 3/4=2 5/6=3 7/8=4 9/10=5,gen(incomefifth)
			recode urbancat5 1/2=. ,gen(urbancat5_3only)
			
			gen rf_dist_kmsq=rf_dist_km^2
			gen rf_dist_kmsqrt=sqrt(rf_dist_km)			
			gen ned_rf_avslope_perc=rf_avslope_perc-0.97 // CENTRE ON 13TH PERCENTILE, AS DUTCH AVERAGE HILLINESS EQUAL TO 13TH PERCENTILE AREAS ENGLAND	
			gen interact=rf_dist_km*ned_rf_avslope_perc
			gen interactsqrt=rf_dist_kmsqrt*ned_rf_avslope_perc
			
		** FIT REGRESSION EQUATION - FLOW TYPE 1+2 - GOV TARGET, DUTCH, EBIKE [model derived from MSOA trips]
			gen pred_basegt= /*
				*/ -3.959 + (-0.5963 * rf_dist_km) + (1.866 * rf_dist_kmsqrt) + (0.008050 * rf_dist_kmsq) + (-0.2710 * ned_rf_avslope_perc) + (0.009394 * rf_dist_km*ned_rf_avslope_perc) + (-0.05135 * rf_dist_kmsqrt*ned_rf_avslope_perc) 
			gen bdutch = 2.550+(-0.08036*rf_dist_km)					// FROM DUTCH NTS [could in future do this by age/sex? each time comparing total Eng/Wales pop to a specific Dutch pop]
			replace bdutch=. if flowtype==3
			gen bebike= (0.05509*rf_dist_km)+(-0.000295*rf_dist_kmsq)	// PARAMETERISED FROM DUTCH TRAVEL SURVEY, ASSUMING NO DIFFERENCE AT 0 DISTANCE
			replace bebike=bebike+(0.1812 *ned_rf_avslope_perc)	// SWISS TRAVEL SURVEY

			gen pred_dutch= pred_basegt + bdutch
			gen pred_ebike= pred_dutch + bebike
			
		/** NEAR MARKET MODELLING DECISIONS: DIST DECAY BY AGE AND GENDER: APPENDIX 2 FIGURE/NUM IN TEXT
			gen rf_dist_kmround2=(floor(rf_dist_km/2))*2
			gen rf_avslope_percround2=floor(rf_avslope_perc)
			recode rf_avslope_percround2 6/max=6 // top 1%
			count if flowtype<=2 
			table rf_dist_kmround2 femagecat if flowtype<=2 , c(mean bicycle)
			table rf_avslope_percround2 femagecat if flowtype<=2 , c(mean bicycle)
			table home_gordet nocar , c(mean bicycle)
			*/
			
		/** IDENTIFY REGRESSION EQUATION - FLOW TYPE 1+2 - NEAR MARKET. Paste to 'pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\1logfiles\NearMarket_flow1+2.xls'
			log using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\1logfiles\NearMarket_flow12.smcl", replace
			foreach x in 1 11 {
			forval i=1/9 {
			disp "femagecat `x' in region `i'"
			xi: logit bicycle i.agecat nonwhite nocar i.incomefifth i.urbancat5 sparse rf_dist_km rf_dist_kmsqrt rf_dist_kmsq ned_rf_avslope_perc interact interactsqrt /*
				*/ if femagecat==`x' & home_gordet==`i' & flowtype <=2 
			}
			forval i=10/11 { // SW and Wales = only larger cities
			disp "femagecat `x' in region `i'"
			xi: logit bicycle i.agecat nonwhite nocar i.incomefifth i.urbancat5_3only sparse rf_dist_km rf_dist_kmsqrt rf_dist_kmsq ned_rf_avslope_perc interact interactsqrt /*
				*/ if femagecat==`x' & home_gordet==`i' & flowtype <=2 
			}
			}
			foreach x in 2 12 { // older ages = agecat_old
			forval i=1/9 {
			disp "femagecat `x' in region `i'"
			xi: logit bicycle i.agecat_old nonwhite nocar i.incomefifth i.urbancat5 sparse rf_dist_km rf_dist_kmsqrt rf_dist_kmsq ned_rf_avslope_perc interact interactsqrt /*
				*/ if femagecat==`x' & home_gordet==`i' & flowtype <=2 
			}
			forval i=10/11 { // SW and Wales = only larger cities
			disp "femagecat `x' in region `i'"
			xi: logit bicycle i.agecat_old nonwhite nocar i.incomefifth i.urbancat5_3only sparse rf_dist_km rf_dist_kmsqrt rf_dist_kmsq ned_rf_avslope_perc interact interactsqrt /*
				*/ if femagecat==`x' & home_gordet==`i' & flowtype <=2 
			}
			}
			log close
		*/

		** FIT REGRESSION EQUATION - FLOW TYPE 1+2 - NEAR MARKET
			tab agecat, gen(agecat_)
			tab incomefifth, gen(incomefifth_)
			tab urbancat5, gen(urbancat5_)
			
			gen pred_basenmorig=.
			replace pred_basenmorig = ((.289 * agecat_2) + (.524 * agecat_3) + (-.945 * nonwhite) + (.753 * nocar) + (-.051 * incomefifth_2) + (.037 * incomefifth_3) + (.037 * incomefifth_4) + (.099 * incomefifth_5) + (-.075 * urbancat5_3) + (-.193 * urbancat5_4) + (-.421 * urbancat5_5) + (.425 * sparse) + (-.660 * rf_dist_km) + (2.130 * rf_dist_kmsqrt) + (.009 * rf_dist_kmsq) + (-.149 * ned_rf_avslope_perc) + (.014 * interact) + (-.075 * interactsqrt) + -4.588) if flowtype<=2 & femagecat==1 & home_gordet==1
			replace pred_basenmorig = ((.266 * agecat_2) + (.465 * agecat_3) + (-.930 * nonwhite) + (.790 * nocar) + (.076 * incomefifth_2) + (.053 * incomefifth_3) + (.106 * incomefifth_4) + (.043 * incomefifth_5) + (.298 * urbancat5_3) + (.395 * urbancat5_4) + (.228 * urbancat5_5) + (.178 * sparse) + (-.643 * rf_dist_km) + (2.087 * rf_dist_kmsqrt) + (.008 * rf_dist_kmsq) + (-.169 * ned_rf_avslope_perc) + (.023 * interact) + (-.103 * interactsqrt) + -4.585) if flowtype<=2 & femagecat==1 & home_gordet==2
			replace pred_basenmorig = ((.249 * agecat_2) + (.448 * agecat_3) + (-.994 * nonwhite) + (.807 * nocar) + (.078 * incomefifth_2) + (.127 * incomefifth_3) + (.232 * incomefifth_4) + (.326 * incomefifth_5) + (.116 * urbancat5_2) + (.619 * urbancat5_3) + (.227 * urbancat5_4) + (.253 * urbancat5_5) + (.138 * sparse) + (-.756 * rf_dist_km) + (2.350 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.348 * ned_rf_avslope_perc) + (-.012 * interact) + (.092 * interactsqrt) + -4.790) if flowtype<=2 & femagecat==1 & home_gordet==3
			replace pred_basenmorig = ((.160 * agecat_2) + (.345 * agecat_3) + (-.941 * nonwhite) + (.882 * nocar) + (-.041 * incomefifth_2) + (.056 * incomefifth_3) + (.101 * incomefifth_4) + (.155 * incomefifth_5) + (-.164 * urbancat5_2) + (-.302 * urbancat5_3) + (-.442 * urbancat5_4) + (-.546 * urbancat5_5) + (-.109 * sparse) + (-.712 * rf_dist_km) + (2.203 * rf_dist_kmsqrt) + (.010 * rf_dist_kmsq) + (-.166 * ned_rf_avslope_perc) + (.038 * interact) + (-.167 * interactsqrt) + -3.622) if flowtype<=2 & femagecat==1 & home_gordet==4
			replace pred_basenmorig = ((.247 * agecat_2) + (.433 * agecat_3) + (-1.172 * nonwhite) + (.889 * nocar) + (.028 * incomefifth_2) + (.067 * incomefifth_3) + (.015 * incomefifth_4) + (.018 * incomefifth_5) + (.382 * urbancat5_3) + (.328 * urbancat5_4) + (.307 * urbancat5_5) + (-.136 * sparse) + (-.762 * rf_dist_km) + (2.345 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.110 * ned_rf_avslope_perc) + (.024 * interact) + (-.120 * interactsqrt) + -4.552) if flowtype<=2 & femagecat==1 & home_gordet==5
			replace pred_basenmorig = ((.286 * agecat_2) + (.392 * agecat_3) + (-.568 * nonwhite) + (.929 * nocar) + (.068 * incomefifth_2) + (.238 * incomefifth_3) + (.224 * incomefifth_4) + (.472 * incomefifth_5) + (.680 * urbancat5_3) + (.399 * urbancat5_4) + (.308 * urbancat5_5) + (.189 * sparse) + (-.844 * rf_dist_km) + (2.606 * rf_dist_kmsqrt) + (.012 * rf_dist_kmsq) + (-.315 * ned_rf_avslope_perc) + (.007 * interact) + (-.060 * interactsqrt) + -4.822) if flowtype<=2 & femagecat==1 & home_gordet==6
			replace pred_basenmorig = ((.467 * agecat_2) + (.514 * agecat_3) + (-.930 * nonwhite) + (.012 * nocar) + (.169 * incomefifth_2) + (.123 * incomefifth_3) + (-.100 * incomefifth_4) + (-.230 * incomefifth_5) + (-.611 * rf_dist_km) + (2.506 * rf_dist_kmsqrt) + (.005 * rf_dist_kmsq) + (.205 * ned_rf_avslope_perc) + (.078 * interact) + (-.450 * interactsqrt) + -4.565) if flowtype<=2 & femagecat==1 & home_gordet==7
			replace pred_basenmorig = ((.483 * agecat_2) + (.678 * agecat_3) + (-1.192 * nonwhite) + (.394 * nocar) + (.149 * incomefifth_2) + (.197 * incomefifth_3) + (.295 * incomefifth_4) + (.463 * incomefifth_5) + (-.580 * urbancat5_3) + (-.184 * urbancat5_4) + (-.456 * urbancat5_5) + (-.387 * rf_dist_km) + (1.462 * rf_dist_kmsqrt) + (.003 * rf_dist_kmsq) + (-.264 * ned_rf_avslope_perc) + (.006 * interact) + (-.003 * interactsqrt) + -4.348) if flowtype<=2 & femagecat==1 & home_gordet==8
			replace pred_basenmorig = ((.246 * agecat_2) + (.393 * agecat_3) + (-.645 * nonwhite) + (.753 * nocar) + (.012 * incomefifth_2) + (.108 * incomefifth_3) + (.142 * incomefifth_4) + (.166 * incomefifth_5) + (.278 * urbancat5_3) + (.145 * urbancat5_4) + (.182 * urbancat5_5) + (-.716 * rf_dist_km) + (2.234 * rf_dist_kmsqrt) + (.010 * rf_dist_kmsq) + (-.229 * ned_rf_avslope_perc) + (-.003 * interact) + (-.016 * interactsqrt) + -4.205) if flowtype<=2 & femagecat==1 & home_gordet==9
			replace pred_basenmorig = ((.325 * agecat_2) + (.482 * agecat_3) + (-.433 * nonwhite) + (.564 * nocar) + (.110 * incomefifth_2) + (.096 * incomefifth_3) + (.234 * incomefifth_4) + (.295 * incomefifth_5) + (-.290 * urbancat5_4) + (-.405 * urbancat5_5) + (-.061 * sparse) + (-.775 * rf_dist_km) + (2.422 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.218 * ned_rf_avslope_perc) + (-.004 * interact) + (.055 * interactsqrt) + -4.099) if flowtype<=2 & femagecat==1 & home_gordet==10
			replace pred_basenmorig = ((.405 * agecat_2) + (.624 * agecat_3) + (-.355 * nonwhite) + (.789 * nocar) + (-.019 * incomefifth_2) + (.029 * incomefifth_3) + (.189 * incomefifth_4) + (.172 * incomefifth_5) + (-.014 * urbancat5_4) + (-.293 * urbancat5_5) + (.391 * sparse) + (-.707 * rf_dist_km) + (2.390 * rf_dist_kmsqrt) + (.009 * rf_dist_kmsq) + (-.007 * ned_rf_avslope_perc) + (.035 * interact) + (-.206 * interactsqrt) + -4.963) if flowtype<=2 & femagecat==1 & home_gordet==11
			replace pred_basenmorig = ((.524 * agecat_2) + (.564 * agecat_3) + (-.427 * nonwhite) + (.629 * nocar) + (.051 * incomefifth_2) + (.235 * incomefifth_3) + (.283 * incomefifth_4) + (.472 * incomefifth_5) + (-.206 * urbancat5_3) + (-.238 * urbancat5_4) + (-.421 * urbancat5_5) + (.439 * sparse) + (-.921 * rf_dist_km) + (2.702 * rf_dist_kmsqrt) + (.015 * rf_dist_kmsq) + (-.677 * ned_rf_avslope_perc) + (-.029 * interact) + (.211 * interactsqrt) + -6.728) if flowtype<=2 & femagecat==11 & home_gordet==1
			replace pred_basenmorig = ((.443 * agecat_2) + (.452 * agecat_3) + (-.599 * nonwhite) + (.802 * nocar) + (.149 * incomefifth_2) + (.079 * incomefifth_3) + (.194 * incomefifth_4) + (.150 * incomefifth_5) + (.307 * urbancat5_3) + (.276 * urbancat5_4) + (.315 * urbancat5_5) + (.880 * sparse) + (-.786 * rf_dist_km) + (2.457 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.372 * ned_rf_avslope_perc) + (.039 * interact) + (-.166 * interactsqrt) + -6.520) if flowtype<=2 & femagecat==11 & home_gordet==2
			replace pred_basenmorig = ((.484 * agecat_2) + (.660 * agecat_3) + (-.769 * nonwhite) + (.732 * nocar) + (.089 * incomefifth_2) + (.162 * incomefifth_3) + (.367 * incomefifth_4) + (.528 * incomefifth_5) + (.349 * urbancat5_2) + (1.199 * urbancat5_3) + (.625 * urbancat5_4) + (.531 * urbancat5_5) + (.083 * sparse) + (-.973 * rf_dist_km) + (2.670 * rf_dist_kmsqrt) + (.018 * rf_dist_kmsq) + (-.889 * ned_rf_avslope_perc) + (-.093 * interact) + (.473 * interactsqrt) + -6.541) if femagecat==11 & home_gordet==3
			replace pred_basenmorig = ((.375 * agecat_2) + (.525 * agecat_3) + (-1.003 * nonwhite) + (.728 * nocar) + (.067 * incomefifth_2) + (.168 * incomefifth_3) + (.212 * incomefifth_4) + (.128 * incomefifth_5) + (-.007 * urbancat5_2) + (-.162 * urbancat5_3) + (-.348 * urbancat5_4) + (-.308 * urbancat5_5) + (-.152 * sparse) + (-.846 * rf_dist_km) + (2.300 * rf_dist_kmsqrt) + (.014 * rf_dist_kmsq) + (-.524 * ned_rf_avslope_perc) + (.027 * interact) + (-.109 * interactsqrt) + -4.967) if flowtype<=2 & femagecat==11 & home_gordet==4
			replace pred_basenmorig = ((.463 * agecat_2) + (.488 * agecat_3) + (-.965 * nonwhite) + (.777 * nocar) + (.191 * incomefifth_2) + (.333 * incomefifth_3) + (.249 * incomefifth_4) + (.210 * incomefifth_5) + (.619 * urbancat5_3) + (.400 * urbancat5_4) + (.714 * urbancat5_5) + (.223 * sparse) + (-.849 * rf_dist_km) + (2.375 * rf_dist_kmsqrt) + (.014 * rf_dist_kmsq) + (-.306 * ned_rf_avslope_perc) + (.021 * interact) + (-.091 * interactsqrt) + -6.392) if flowtype<=2 & femagecat==11 & home_gordet==5
			replace pred_basenmorig = ((.464 * agecat_2) + (.431 * agecat_3) + (-.501 * nonwhite) + (.920 * nocar) + (.279 * incomefifth_2) + (.519 * incomefifth_3) + (.483 * incomefifth_4) + (.839 * incomefifth_5) + (1.379 * urbancat5_3) + (.949 * urbancat5_4) + (.939 * urbancat5_5) + (.381 * sparse) + (-1.026 * rf_dist_km) + (3.009 * rf_dist_kmsqrt) + (.017 * rf_dist_kmsq) + (-.379 * ned_rf_avslope_perc) + (.044 * interact) + (-.304 * interactsqrt) + -6.820) if flowtype<=2 & femagecat==11 & home_gordet==6
			replace pred_basenmorig = ((.631 * agecat_2) + (.517 * agecat_3) + (-1.034 * nonwhite) + (.009 * nocar) + (.150 * incomefifth_2) + (.089 * incomefifth_3) + (-.059 * incomefifth_4) + (-.201 * incomefifth_5) + (-.893 * rf_dist_km) + (3.409 * rf_dist_kmsqrt) + (.010 * rf_dist_kmsq) + (.197 * ned_rf_avslope_perc) + (.084 * interact) + (-.513 * interactsqrt) + -5.968) if flowtype<=2 & femagecat==11 & home_gordet==7
			replace pred_basenmorig = ((.805 * agecat_2) + (.769 * agecat_3) + (-1.290 * nonwhite) + (.556 * nocar) + (.248 * incomefifth_2) + (.318 * incomefifth_3) + (.380 * incomefifth_4) + (.680 * incomefifth_5) + (-.727 * urbancat5_3) + (-.528 * urbancat5_4) + (-.290 * urbancat5_5) + (-.497 * rf_dist_km) + (1.887 * rf_dist_kmsqrt) + (.003 * rf_dist_kmsq) + (-.292 * ned_rf_avslope_perc) + (.014 * interact) + (-.059 * interactsqrt) + -6.181) if flowtype<=2 & femagecat==11 & home_gordet==8
			replace pred_basenmorig = ((.467 * agecat_2) + (.444 * agecat_3) + (-.614 * nonwhite) + (.813 * nocar) + (.168 * incomefifth_2) + (.383 * incomefifth_3) + (.416 * incomefifth_4) + (.427 * incomefifth_5) + (.560 * urbancat5_3) + (.130 * urbancat5_4) + (.243 * urbancat5_5) + (-.976 * rf_dist_km) + (2.825 * rf_dist_kmsqrt) + (.016 * rf_dist_kmsq) + (-.269 * ned_rf_avslope_perc) + (.010 * interact) + (-.104 * interactsqrt) + -6.147) if flowtype<=2 & femagecat==11 & home_gordet==9
			replace pred_basenmorig = ((.543 * agecat_2) + (.489 * agecat_3) + (-.335 * nonwhite) + (.555 * nocar) + (.136 * incomefifth_2) + (-.018 * incomefifth_3) + (.209 * incomefifth_4) + (.260 * incomefifth_5) + (-.520 * urbancat5_4) + (-.392 * urbancat5_5) + (.187 * sparse) + (-1.052 * rf_dist_km) + (3.020 * rf_dist_kmsqrt) + (.018 * rf_dist_kmsq) + (-.338 * ned_rf_avslope_perc) + (-.016 * interact) + (.122 * interactsqrt) + -5.591) if flowtype<=2 & femagecat==11 & home_gordet==10
			replace pred_basenmorig = ((.551 * agecat_2) + (.344 * agecat_3) + (-.160 * nonwhite) + (.748 * nocar) + (.050 * incomefifth_2) + (.056 * incomefifth_3) + (.742 * incomefifth_4) + (.506 * incomefifth_5) + (-.268 * urbancat5_4) + (-.379 * urbancat5_5) + (.608 * sparse) + (-1.162 * rf_dist_km) + (3.752 * rf_dist_kmsqrt) + (.016 * rf_dist_kmsq) + (-.149 * ned_rf_avslope_perc) + (.076 * interact) + (-.329 * interactsqrt) + -7.354) if flowtype<=2 & femagecat==11 & home_gordet==11
			replace pred_basenmorig = ((-.626 * agecat_5) + (-.342 * agecat_6) + (-1.253 * nonwhite) + (1.078 * nocar) + (.027 * incomefifth_2) + (.078 * incomefifth_3) + (.092 * incomefifth_4) + (.222 * incomefifth_5) + (-.033 * urbancat5_3) + (-.102 * urbancat5_4) + (-.234 * urbancat5_5) + (.438 * sparse) + (-.600 * rf_dist_km) + (1.862 * rf_dist_kmsqrt) + (.008 * rf_dist_kmsq) + (-.288 * ned_rf_avslope_perc) + (.018 * interact) + (-.054 * interactsqrt) + -4.326) if flowtype<=2 & femagecat==2 & home_gordet==1
			replace pred_basenmorig = ((-.609 * agecat_5) + (-.378 * agecat_6) + (-1.081 * nonwhite) + (1.084 * nocar) + (.124 * incomefifth_2) + (.114 * incomefifth_3) + (.165 * incomefifth_4) + (.176 * incomefifth_5) + (.415 * urbancat5_3) + (.568 * urbancat5_4) + (.375 * urbancat5_5) + (.307 * sparse) + (-.596 * rf_dist_km) + (1.747 * rf_dist_kmsqrt) + (.008 * rf_dist_kmsq) + (-.284 * ned_rf_avslope_perc) + (.011 * interact) + (-.025 * interactsqrt) + -4.200) if flowtype<=2 & femagecat==2 & home_gordet==2
			replace pred_basenmorig = ((-.600 * agecat_5) + (-.451 * agecat_6) + (-.882 * nonwhite) + (1.103 * nocar) + (.034 * incomefifth_2) + (.127 * incomefifth_3) + (.188 * incomefifth_4) + (.404 * incomefifth_5) + (.261 * urbancat5_2) + (.910 * urbancat5_3) + (.538 * urbancat5_4) + (.317 * urbancat5_5) + (.099 * sparse) + (-.753 * rf_dist_km) + (2.066 * rf_dist_kmsqrt) + (.013 * rf_dist_kmsq) + (-.527 * ned_rf_avslope_perc) + (-.033 * interact) + (.193 * interactsqrt) + -4.418) if flowtype<=2 & femagecat==2 & home_gordet==3
			replace pred_basenmorig = ((-.594 * agecat_5) + (-.182 * agecat_6) + (-1.080 * nonwhite) + (1.185 * nocar) + (.110 * incomefifth_2) + (.126 * incomefifth_3) + (.239 * incomefifth_4) + (.269 * incomefifth_5) + (.178 * urbancat5_2) + (.083 * urbancat5_3) + (-.159 * urbancat5_4) + (-.355 * urbancat5_5) + (.238 * sparse) + (-.635 * rf_dist_km) + (1.667 * rf_dist_kmsqrt) + (.010 * rf_dist_kmsq) + (-.341 * ned_rf_avslope_perc) + (.022 * interact) + (-.058 * interactsqrt) + -3.357) if flowtype<=2 & femagecat==2 & home_gordet==4
			replace pred_basenmorig = ((-.629 * agecat_5) + (-.378 * agecat_6) + (-1.215 * nonwhite) + (1.212 * nocar) + (.056 * incomefifth_2) + (.140 * incomefifth_3) + (.127 * incomefifth_4) + (.201 * incomefifth_5) + (.493 * urbancat5_3) + (.473 * urbancat5_4) + (.263 * urbancat5_5) + (.158 * sparse) + (-.768 * rf_dist_km) + (2.139 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.176 * ned_rf_avslope_perc) + (.030 * interact) + (-.117 * interactsqrt) + -4.263) if flowtype<=2 & femagecat==2 & home_gordet==5
			replace pred_basenmorig = ((-.491 * agecat_5) + (-.478 * agecat_6) + (-.615 * nonwhite) + (1.292 * nocar) + (.136 * incomefifth_2) + (.214 * incomefifth_3) + (.207 * incomefifth_4) + (.451 * incomefifth_5) + (.704 * urbancat5_3) + (.449 * urbancat5_4) + (.328 * urbancat5_5) + (.493 * sparse) + (-.787 * rf_dist_km) + (2.177 * rf_dist_kmsqrt) + (.012 * rf_dist_kmsq) + (-.368 * ned_rf_avslope_perc) + (-.015 * interact) + (.018 * interactsqrt) + -4.210) if flowtype<=2 & femagecat==2 & home_gordet==6
			replace pred_basenmorig = ((-.751 * agecat_5) + (-.456 * agecat_6) + (-1.088 * nonwhite) + (.126 * nocar) + (.257 * incomefifth_2) + (.322 * incomefifth_3) + (.243 * incomefifth_4) + (.062 * incomefifth_5) + (-.560 * rf_dist_km) + (2.238 * rf_dist_kmsqrt) + (.005 * rf_dist_kmsq) + (.195 * ned_rf_avslope_perc) + (.021 * interact) + (-.308 * interactsqrt) + -4.363) if flowtype<=2 & femagecat==2 & home_gordet==7
			replace pred_basenmorig = ((-.778 * agecat_5) + (-.397 * agecat_6) + (-1.313 * nonwhite) + (.685 * nocar) + (.063 * incomefifth_2) + (.236 * incomefifth_3) + (.316 * incomefifth_4) + (.475 * incomefifth_5) + (-.461 * urbancat5_3) + (-.268 * urbancat5_4) + (.033 * urbancat5_5) + (-.452 * rf_dist_km) + (1.437 * rf_dist_kmsqrt) + (.005 * rf_dist_kmsq) + (-.357 * ned_rf_avslope_perc) + (.008 * interact) + (-.002 * interactsqrt) + -3.877) if flowtype<=2 & femagecat==2 & home_gordet==8
			replace pred_basenmorig = ((-.551 * agecat_5) + (-.402 * agecat_6) + (-.623 * nonwhite) + (1.084 * nocar) + (.047 * incomefifth_2) + (.157 * incomefifth_3) + (.230 * incomefifth_4) + (.206 * incomefifth_5) + (.301 * urbancat5_3) + (.062 * urbancat5_4) + (-.081 * urbancat5_5) + (-.659 * rf_dist_km) + (1.853 * rf_dist_kmsqrt) + (.010 * rf_dist_kmsq) + (-.261 * ned_rf_avslope_perc) + (.011 * interact) + (-.057 * interactsqrt) + -3.723) if flowtype<=2 & femagecat==2 & home_gordet==9
			replace pred_basenmorig = ((-.708 * agecat_5) + (-.491 * agecat_6) + (-.454 * nonwhite) + (.863 * nocar) + (.078 * incomefifth_2) + (.160 * incomefifth_3) + (.220 * incomefifth_4) + (.281 * incomefifth_5) + (-.205 * urbancat5_4) + (-.390 * urbancat5_5) + (-.229 * sparse) + (-.713 * rf_dist_km) + (1.939 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.258 * ned_rf_avslope_perc) + (.000 * interact) + (.039 * interactsqrt) + -3.345) if flowtype<=2 & femagecat==2 & home_gordet==10
			replace pred_basenmorig = ((-.613 * agecat_5) + (-.272 * agecat_6) + (-.350 * nonwhite) + (1.065 * nocar) + (-.093 * incomefifth_2) + (.021 * incomefifth_3) + (.197 * incomefifth_4) + (.260 * incomefifth_5) + (.006 * urbancat5_4) + (-.330 * urbancat5_5) + (.361 * sparse) + (-.542 * rf_dist_km) + (1.549 * rf_dist_kmsqrt) + (.008 * rf_dist_kmsq) + (-.214 * ned_rf_avslope_perc) + (.009 * interact) + (-.045 * interactsqrt) + -3.943) if flowtype<=2 & femagecat==2 & home_gordet==11
			replace pred_basenmorig = ((-.278 * agecat_5) + (.499 * agecat_6) + (-1.193 * nonwhite) + (.488 * nocar) + (.069 * incomefifth_2) + (.008 * incomefifth_3) + (.048 * incomefifth_4) + (.215 * incomefifth_5) + (.047 * urbancat5_3) + (.010 * urbancat5_4) + (.041 * urbancat5_5) + (.642 * sparse) + (-.879 * rf_dist_km) + (2.544 * rf_dist_kmsqrt) + (.015 * rf_dist_kmsq) + (-.491 * ned_rf_avslope_perc) + (.032 * interact) + (-.133 * interactsqrt) + -6.161) if flowtype<=2 & femagecat==12 & home_gordet==1
			replace pred_basenmorig = ((.016 * agecat_5) + (.493 * agecat_6) + (-.571 * nonwhite) + (.716 * nocar) + (.104 * incomefifth_2) + (.081 * incomefifth_3) + (.191 * incomefifth_4) + (.215 * incomefifth_5) + (.790 * urbancat5_3) + (.721 * urbancat5_4) + (1.129 * urbancat5_5) + (.585 * sparse) + (-.605 * rf_dist_km) + (1.469 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.667 * ned_rf_avslope_perc) + (-.016 * interact) + (.093 * interactsqrt) + -5.383) if flowtype<=2 & femagecat==12 & home_gordet==2
			replace pred_basenmorig = ((-.234 * agecat_5) + (.376 * agecat_6) + (-.927 * nonwhite) + (.551 * nocar) + (.050 * incomefifth_2) + (-.009 * incomefifth_3) + (.108 * incomefifth_4) + (.201 * incomefifth_5) + (.679 * urbancat5_2) + (1.672 * urbancat5_3) + (1.322 * urbancat5_4) + (1.068 * urbancat5_5) + (.093 * sparse) + (-.867 * rf_dist_km) + (2.011 * rf_dist_kmsqrt) + (.018 * rf_dist_kmsq) + (-1.075 * ned_rf_avslope_perc) + (-.087 * interact) + (.487 * interactsqrt) + -5.370) if flowtype<=2 & femagecat==12 & home_gordet==3
			replace pred_basenmorig = ((-.153 * agecat_5) + (.418 * agecat_6) + (-1.371 * nonwhite) + (.675 * nocar) + (.108 * incomefifth_2) + (.159 * incomefifth_3) + (.253 * incomefifth_4) + (.172 * incomefifth_5) + (1.111 * urbancat5_2) + (1.247 * urbancat5_3) + (1.269 * urbancat5_4) + (1.130 * urbancat5_5) + (.227 * sparse) + (-.788 * rf_dist_km) + (1.780 * rf_dist_kmsqrt) + (.015 * rf_dist_kmsq) + (-.797 * ned_rf_avslope_perc) + (.007 * interact) + (.019 * interactsqrt) + -5.140) if flowtype<=2 & femagecat==12 & home_gordet==4
			replace pred_basenmorig = ((-.034 * agecat_5) + (.769 * agecat_6) + (-.961 * nonwhite) + (.575 * nocar) + (.085 * incomefifth_2) + (.262 * incomefifth_3) + (.230 * incomefifth_4) + (.276 * incomefifth_5) + (.956 * urbancat5_3) + (1.121 * urbancat5_4) + (1.088 * urbancat5_5) + (.192 * sparse) + (-.784 * rf_dist_km) + (1.784 * rf_dist_kmsqrt) + (.014 * rf_dist_kmsq) + (-.442 * ned_rf_avslope_perc) + (.040 * interact) + (-.133 * interactsqrt) + -5.297) if flowtype<=2 & femagecat==12 & home_gordet==5
			replace pred_basenmorig = ((-.138 * agecat_5) + (.298 * agecat_6) + (-.708 * nonwhite) + (.741 * nocar) + (.125 * incomefifth_2) + (.292 * incomefifth_3) + (.172 * incomefifth_4) + (.440 * incomefifth_5) + (1.369 * urbancat5_3) + (1.349 * urbancat5_4) + (1.229 * urbancat5_5) + (.733 * sparse) + (-.813 * rf_dist_km) + (1.894 * rf_dist_kmsqrt) + (.015 * rf_dist_kmsq) + (-.553 * ned_rf_avslope_perc) + (.011 * interact) + (-.114 * interactsqrt) + -4.993) if flowtype<=2 & femagecat==12 & home_gordet==6
			replace pred_basenmorig = ((-.630 * agecat_5) + (-.301 * agecat_6) + (-1.178 * nonwhite) + (.080 * nocar) + (.445 * incomefifth_2) + (.573 * incomefifth_3) + (.536 * incomefifth_4) + (.392 * incomefifth_5) + (-.781 * rf_dist_km) + (2.885 * rf_dist_kmsqrt) + (.010 * rf_dist_kmsq) + (-.241 * ned_rf_avslope_perc) + (-.083 * interact) + (.121 * interactsqrt) + -5.753) if flowtype<=2 & femagecat==12 & home_gordet==7
			replace pred_basenmorig = ((-.637 * agecat_5) + (-.025 * agecat_6) + (-1.435 * nonwhite) + (.650 * nocar) + (.367 * incomefifth_2) + (.430 * incomefifth_3) + (.598 * incomefifth_4) + (1.043 * incomefifth_5) + (-.298 * urbancat5_3) + (.065 * urbancat5_4) + (-.999 * urbancat5_5) + (-.647 * rf_dist_km) + (1.835 * rf_dist_kmsqrt) + (.010 * rf_dist_kmsq) + (-.665 * ned_rf_avslope_perc) + (.007 * interact) + (.029 * interactsqrt) + -5.364) if flowtype<=2 & femagecat==12 & home_gordet==8
			replace pred_basenmorig = ((-.131 * agecat_5) + (.516 * agecat_6) + (-.659 * nonwhite) + (.770 * nocar) + (.144 * incomefifth_2) + (.262 * incomefifth_3) + (.332 * incomefifth_4) + (.351 * incomefifth_5) + (.496 * urbancat5_3) + (.362 * urbancat5_4) + (.415 * urbancat5_5) + (-.769 * rf_dist_km) + (1.789 * rf_dist_kmsqrt) + (.014 * rf_dist_kmsq) + (-.462 * ned_rf_avslope_perc) + (.021 * interact) + (-.088 * interactsqrt) + -4.530) if flowtype<=2 & femagecat==12 & home_gordet==9
			replace pred_basenmorig = ((-.253 * agecat_5) + (.524 * agecat_6) + (-.483 * nonwhite) + (.431 * nocar) + (.160 * incomefifth_2) + (.044 * incomefifth_3) + (.250 * incomefifth_4) + (.330 * incomefifth_5) + (-.127 * urbancat5_4) + (-.073 * urbancat5_5) + (-.186 * sparse) + (-.827 * rf_dist_km) + (1.826 * rf_dist_kmsqrt) + (.016 * rf_dist_kmsq) + (-.601 * ned_rf_avslope_perc) + (-.027 * interact) + (.210 * interactsqrt) + -3.842) if flowtype<=2 & femagecat==12 & home_gordet==10
			replace pred_basenmorig = ((-.480 * agecat_5) + (.705 * agecat_6) + (-.337 * nonwhite) + (.710 * nocar) + (-.066 * incomefifth_2) + (-.141 * incomefifth_3) + (.299 * incomefifth_4) + (.296 * incomefifth_5) + (.260 * urbancat5_4) + (-.339 * urbancat5_5) + (.779 * sparse) + (-.775 * rf_dist_km) + (2.035 * rf_dist_kmsqrt) + (.012 * rf_dist_kmsq) + (-.565 * ned_rf_avslope_perc) + (.020 * interact) + (.014 * interactsqrt) + -5.443) if flowtype<=2 & femagecat==12 & home_gordet==11
			
		**CONVERT LOG-ODDS TO PROBABILITIES		
			foreach x in basegt dutch ebike basenmorig {
			replace pred_`x'=exp(pred_`x')/(1+exp(pred_`x'))
			}
			
		/** UPDATED DUTCH AND EBIKES - FIG 3 IN USER MANUAL C
			gen rf_dist_kmround=(floor(rf_dist_km))
			gen rf_avslope_percround=floor(rf_avslope_perc*10)/10
			recode rf_avslope_percround 4/max=4 
			table rf_dist_kmround if flowtype<=2 , c(mean bicycle mean pred_dutch mean pred_ebike)
			table rf_avslope_percround if flowtype<=2 , c(mean bicycle mean pred_dutch mean pred_ebike)
		*/

		** INPUT PARAMETERS FLOW 3 (NO FIXED PLACE)
			foreach x in pred_basegt pred_basenmorig bdutch bebike { // WEIGHTED AVERAGE OF COMMUTERS IN FLOWTYPE 1 & "
			gen `x'temp=`x'
			replace `x'temp=. if flowtype!=1 & flowtype!=2	// WEIGHTED AVERAGE OF COMMUTERS IN FLOWTYPE 1 & "
			gen alltemp=1
			replace alltemp=. if `x'temp==.
			bysort home_lsoa: egen nummean`x'=sum(`x'temp*alltemp)
			bysort home_lsoa: egen denmean`x'=sum(alltemp)
			gen mean`x'=nummean`x'/denmean`x'
			drop `x'temp alltemp nummean`x' denmean`x'
			}
			gen meanpred_basegtsq=meanpred_basegt^2
			gen meanpred_basegtsqrt=meanpred_basegt^0.5
			gen meanpred_basenmorigsq=meanpred_basenmorig^2
			gen meanpred_basenmorigsqrt=meanpred_basenmorig^0.5

		** FIT REGRESSION EQUATION - FLOW 3 - GOV TARGET, DUTCH, EBIKE
			gen pred2_basegt= -6.399 + (184.0 * meanpred_basegtsq) + (10.36 * meanpred_basegtsqrt) 
			gen pred2_dutch= pred2_basegt + meanbdutch
			gen pred2_ebike= pred2_dutch + meanbebike

		/* IDENTIFY REGRESSION EQUATION - FLOW TYPE 1+2 - NEAR MARKET. Paste to 'pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\1logfiles\NearMarket_flow3.xls'
			log using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\1logfiles\NearMarket_flow3.smcl", replace
			forval i=1/11 {
			disp "region `i'"
			xi: logit bicycle meanpred_basenmorigsq meanpred_basenmorigsqrt if flowtype==3 & home_gordet==`i' 
			}
			log close	
			*/
		** FIT REGRESSION EQUATION - FLOW 3 - NEAR MARKET
			gen pred2_basenmorig=.
			replace pred2_basenmorig = ((394.6 * meanpred_basenmorigsq) + (17.42 * meanpred_basenmorigsqrt) + -7.25) if flowtype==3 & home_gordet==1
			replace pred2_basenmorig = ((-521.4 * meanpred_basenmorigsq) + (26.64 * meanpred_basenmorigsqrt) + -8.21) if flowtype==3 & home_gordet==2
			replace pred2_basenmorig = ((21.1 * meanpred_basenmorigsq) + (10.25 * meanpred_basenmorigsqrt) + -6.25) if flowtype==3 & home_gordet==3
			replace pred2_basenmorig = ((-189.2 * meanpred_basenmorigsq) + (20.02 * meanpred_basenmorigsqrt) + -7.78) if flowtype==3 & home_gordet==4
			replace pred2_basenmorig = ((213.6 * meanpred_basenmorigsq) + (7.83 * meanpred_basenmorigsqrt) + -5.92) if flowtype==3 & home_gordet==5
			replace pred2_basenmorig = ((62.3 * meanpred_basenmorigsq) + (6.04 * meanpred_basenmorigsqrt) + -5.74) if flowtype==3 & home_gordet==6
			replace pred2_basenmorig = ((-142.3 * meanpred_basenmorigsq) + (25.95 * meanpred_basenmorigsqrt) + -9.12) if flowtype==3 & home_gordet==7
			replace pred2_basenmorig = ((125.5 * meanpred_basenmorigsq) + (18.70 * meanpred_basenmorigsqrt) + -7.40) if flowtype==3 & home_gordet==8
			replace pred2_basenmorig = ((123.0 * meanpred_basenmorigsq) + (7.69 * meanpred_basenmorigsqrt) + -5.99) if flowtype==3 & home_gordet==9
			replace pred2_basenmorig = ((-71.0 * meanpred_basenmorigsq) + (14.74 * meanpred_basenmorigsqrt) + -7.03) if flowtype==3 & home_gordet==10
			replace pred2_basenmorig = ((186.1 * meanpred_basenmorigsq) + (14.16 * meanpred_basenmorigsqrt) + -6.82) if flowtype==3 & home_gordet==11
						
		** COMBINE FLOW 3+4 WITH 1+2
			foreach x in basegt dutch ebike basenmorig {
			replace pred2_`x'=exp(pred2_`x')/(1+exp(pred2_`x'))
			replace pred_`x'=pred2_`x' if flowtype==3
			drop pred2_`x'
			replace pred_`x'=0 if flowtype==4
			}
			
		** SCALE BY REGION TO BE EQIVALENT TO GOV TARGET. Paste to 'pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\1logfiles\NearMarket_gtscale.xls'
			table home_gordet , c(mean bicycle mean pred_basegt mean pred_basenmorig)
			gen gtscaling=. // pred_basegt divided by pred_basenmorig
			recode gtscaling .=1.736 if home_gordet==1
			recode gtscaling .=1.520 if home_gordet==2
			recode gtscaling .=1.035 if home_gordet==3
			recode gtscaling .=1.049 if home_gordet==4
			recode gtscaling .=1.388 if home_gordet==5
			recode gtscaling .=0.822 if home_gordet==6
			recode gtscaling .=0.584 if home_gordet==7
			recode gtscaling .=1.395 if home_gordet==8
			recode gtscaling .=0.902 if home_gordet==9
			recode gtscaling .=0.664 if home_gordet==10
			recode gtscaling .=1.426 if home_gordet==11
			gen pred_basenm=pred_basenmorig*gtscaling
			*table home_gordet , c(mean bicycle mean pred_basegt mean pred_basenmorig mean pred_basenm)
			
		** SAVE
			keep home_lsoa- incomedecile bicycle pred_basegt pred_basenmorig pred_basenm pred_dutch pred_ebike 
			compress
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\0temp\CommuteSPTemp2.dta", replace
				
	*****************
	** PART 3B: APPLY SCENARIOS TO DATA: SLC AND SIC
	*****************
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\0temp\CommuteSPTemp2.dta", clear
		* NO CYCLISTS	
			gen nocyclists_slc=0
			gen nocyclists_sic=nocyclists_slc-bicycle
		
		* GOV TARGET, NEAR MARKET - CALC SIC THEN ADD TO BASELINE FOR SLC
			foreach x in basegt basenm {
			bysort home_lsoa work_lsoa: egen odcyclist_all`x'=sum(pred_`x') // NO. PREDICTED NEW CYCLISTS IN FLOW IN SCENARIO IN TOTAL
			bysort home_lsoa work_lsoa: egen odcyclist_noncyclist`x'=sum((1-bicycle)*pred_`x') // NO. PREDICTED NEW CYCLISTS IN FLOW IN SCENARIO IF RESTRICTED TO CURRENT NONCYCLISTS	
			gen `x'_sic=pred_`x'*(odcyclist_all`x'/odcyclist_noncyclist`x') // SCALING FACTOR - INCREASE THE SIC AMONG NON-CYCLISTS SO THAT CAN BE ZERO IN CURRENT CYCLISTS
			replace `x'_sic=0 if bicycle==1	// NO SIC IN CYCLISTS
			recode `x'_sic 1/max=1 		// A SMALL NUMBER OF FLOWS WHICH ARE ALMOST ALL CYCLISTS OTHERWISE HAVE THIS >1
			gen `x'_slc=`x'_sic+bicycle
			drop odcyclist_all`x' odcyclist_noncyclist`x'
			}
			rename basegt* govtarget*
			rename basenm* govnearmkt*			
			
		* GENDER EQ	
			bysort home_lsoa work_lsoa: egen bicycle_all=sum(bicycle)
			bysort home_lsoa work_lsoa: egen bicycle_male=sum((1-female)*bicycle)
			bysort home_lsoa work_lsoa: egen bicycle_female=sum((female)*bicycle)
			bysort home_lsoa work_lsoa: egen female_all=sum((female))
			bysort home_lsoa work_lsoa: egen male_all=sum((1-female))
			gen gendereq_totalslc=(bicycle_male*(1 + (female_all/male_all))) // SLC IN FLOW AS WHOLE
			gen gendereq_sic=(gendereq_totalslc-bicycle_all)/(female_all-bicycle_female)	// SIC PER FEMALE NON-CYCLIST
			replace gendereq_sic = 0 if female_all==bicycle_female // NO CHANGE IF ALL WOMEN ALREADY CYCLE			
			replace gendereq_sic = 0 if gendereq_totalslc<=bicycle_all // NO CHANGE IF SLC<=BASELINE
			replace gendereq_sic = 0 if bicycle_male==0	// NO CHANGE IF NO MALE CYCLISTS IN FLOW
			replace	gendereq_sic = 0 if female==0 | bicycle==1 // NO CHANGE AMONG MALES OR AMONG FEMALE CYCLISTS
			gen gendereq_slc=gendereq_sic+bicycle
			drop bicycle_all- male_all gendereq_totalslc
	
		* DUTCH + EBIKE - CALC SLC, THEN MINUS BASELINE TO GET SIC
			foreach x in dutch ebike {
			bysort home_lsoa work_lsoa: egen odcyclist_all`x'=sum(pred_`x') // NO. PREDICTED NEW CYCLISTS IN FLOW IN SCENARIO IN TOTAL
			bysort home_lsoa work_lsoa: egen odcyclist_cyclist`x'=sum(bicycle*(bicycle-pred_`x')) // NO. CYCLISTS ALREADY HAVE AMONG EXISTING OVER AND ABOVE THEIR PREDICTIONS
			gen `x'_slc=pred_`x'*((odcyclist_all`x'-odcyclist_cyclist`x')/odcyclist_all`x') // SCALING FACTOR - DECREASE THE SLC AMONG NON-CYCLISTS SO THAT CAN BE 1 IN CURRENT CYCLISTS
			replace `x'_slc=1 if bicycle==1	// SLC = BASELINE CYCLING IN CYCLISTS
			replace `x'_slc=bicycle if `x'_slc<=bicycle 	// NO CHANGE IF SLC < BASELINE
			gen `x'_sic=`x'_slc-bicycle
			drop odcyclist_all`x' odcyclist_cyclist`x'
			}
			
		* NO INCREASE IN FLOW TYPE 4 (TOO LONG/OUTSIDE EW)
			foreach x in govtarget govnearmkt gendereq dutch ebike {
			replace `x'_slc=bicycle if flowtype==4	
			replace `x'_sic=0 if flowtype==4
			}

	*****************
	** PART 3C: MODE SHIFT
	*****************			
			recode commute_mainmode9 1=0 2=1 3/max=0,gen(foot)
			recode commute_mainmode9 1/2=0 3=1 4/max=0,gen(car_driver)
			bysort home_lsoa work_lsoa: gen od_all=_N
			bysort home_lsoa work_lsoa: egen od_bicycle=sum(bicycle)
			bysort home_lsoa work_lsoa: egen od_foot=sum(foot)
			bysort home_lsoa work_lsoa: egen od_car_driver=sum(car_driver)

		* NO CYCLISTS
			gen nocyclists_slw=foot
			replace nocyclists_slw=od_foot/(od_all-od_bicycle) if bicycle==1	// Cyclists get walk mode share equal to flow mode share among non-cyclists
			replace nocyclists_slw=0.31 if od_bicycle==od_all	// Flows with pure bicycles at baseline - make walking 31% of new flows [from Lovelae 2017, based on MSOA mode pairs with 50%-99% cycling]
			gen nocyclists_siw=nocyclists_slw-foot
			
			gen nocyclists_sld=car_driver
			replace nocyclists_sld=od_car_driver/(od_all-od_bicycle) if bicycle==1	// Cyclists get walk mode share equal to flow mode share among non-cyclists
			replace nocyclists_sld=0.35 if od_bicycle==od_all	// Flows with pure bicycles at baseline - make driving 35% of new flows [from Lovelae 2017, based on MSOA mode pairs with 50%-99% cycling]
			gen nocyclists_sid=nocyclists_sld-car_driver
			
		* BY SCENARIO
			foreach x in govtarget govnearmkt gendereq dutch ebike {
			gen `x'_siw=foot*`x'_sic*-1
			gen `x'_slw=foot+`x'_siw
			gen `x'_sid=car_driver*`x'_sic*-1
			gen `x'_sld=car_driver+`x'_sid
			}
		* ORDER + DROP EXCESS VARIABLES
			drop pred_basegt pred_dutch pred_ebike pred_basenmorig pred_basenm
			drop bicycle foot- od_car_driver
			foreach x in ebike dutch gendereq govnearmkt govtarget nocyclists {
			order `x'_slc `x'_sic `x'_slw `x'_siw `x'_sld `x'_sid, after(incomedecile)
			}
			
	*****************
	** STEP 4: DO HEAT AND CARBON
	*****************
		** INPUT PARAMETERS HEAT + CARBON [APPENDIX TABLE]
			gen cyclecommute_tripspertypicalweek = .
				replace cyclecommute_tripspertypicalweek = 7.24 if female==0 & agecat<=3
				replace cyclecommute_tripspertypicalweek = 7.32 if female==0 & agecat>=4
				replace cyclecommute_tripspertypicalweek = 6.31 if female==1 & agecat<=3
				replace cyclecommute_tripspertypicalweek = 7.23 if female==1 & agecat>=4
			gen cspeed = 14	
			gen wspeed = 4.8
			gen ebikespeed = 16.4
			gen ebikemetreduction = 0.648
			recode cyc_dist_km min/4.9999999=.07 5/9.9999999=.13 10/19.999999=.23 20/max=.23, gen(percentebike_dutch)
			recode cyc_dist_km min/4.9999999=.71 5/9.9999999=.91 10/19.999999=.93 20/max=1, gen(percentebike_ebike)	
			gen crr_heat=0.9 
			gen cdur_ref_heat=100	
			gen wrr_heat=0.89 
			gen wdur_ref_heat=168
			gen vsl= 1888675		// VALUE IN POUNDS [TAB 'A4.1.1', AFTER SETTING YEAR AS 2017 IN 'USER PARAMETERS' IN WEBTAG BOOK]

			gen cyclecommute_tripsperweek = .
				replace cyclecommute_tripsperweek = 5.46 if female==0 & agecat<=3
				replace cyclecommute_tripsperweek = 5.23 if female==0 & agecat>=4
				replace cyclecommute_tripsperweek = 4.13 if female==1 & agecat<=3
				replace cyclecommute_tripsperweek = 4.88 if female==1 & agecat>=4
			gen co2kg_km=0.182
	
		** DURATION OF CYCLING/WALKING [THE DUTCH/EBIKE DURATION INCORPORATES LOWER INTENSITY]
			gen cdur_obs = 60*((cyc_dist_km*cyclecommute_tripspertypicalweek)/cspeed) // TIME CYCLING PER WEEK IN MINUTES AMONG NEW CYCLISTS
			gen cdur_obs_dutch=((1-percentebike_dutch)*cdur_obs)+(percentebike_dutch*cdur_obs*ebikemetreduction*(cspeed/ebikespeed))
			gen cdur_obs_ebike=((1-percentebike_ebike)*cdur_obs)+(percentebike_ebike*cdur_obs*ebikemetreduction*(cspeed/ebikespeed))
			gen wdur_obs = 60*((cyc_dist_km*cyclecommute_tripspertypicalweek)/wspeed) // TIME WALKING PER WEEK IN MINUTES AMONG THOSE NOW SWITCHING TO CYCLING

		** MORTALITY PROTECTION
			gen cprotection_govtarget= (1-crr_heat)*(cdur_obs/cdur_ref_heat)	// SCALE RR DEPENDING ON HOW DURATION IN THIS POP COMPARES TO REF
			gen cprotection_nocyclists=cprotection_govtarget
			gen cprotection_govnearmkt=cprotection_govtarget
			gen cprotection_gendereq=cprotection_govtarget
			gen cprotection_dutch= (1-crr_heat)*(cdur_obs_dutch/cdur_ref_heat) // GO DUTCH AND EBIKE USE SCALING INCORPORATING FACT SOME EBIKES
			gen cprotection_ebike= (1-crr_heat)*(cdur_obs_ebike/cdur_ref_heat)
			foreach x in nocyclists govtarget govnearmkt gendereq dutch ebike {			
			recode cprotection_`x' 0.45/max=0.45			
			}
			gen wprotection_heat= (1-wrr_heat)*(wdur_obs/wdur_ref_heat)
			recode wprotection_heat 0.30/max=0.30		

		** DEATHS AND VALUES
			foreach x in nocyclists govtarget govnearmkt gendereq dutch ebike {			
			gen `x'_sic_death=`x'_sic*mortrate*cprotection_`x'*-1
			gen `x'_siw_death=`x'_siw*mortrate*wprotection*-1
			gen `x'_sideath_heat=`x'_sic_death+`x'_siw_death
			gen `x'_sivalue_heat=`x'_sideath_heat*vsl*-1 // here and for CO2, not 'gen long' as individual
			drop `x'_sic_death `x'_siw_death
			}
			gen base_sldeath_heat=-1*nocyclists_sideath_heat	// BASELINE LEVEL IS INVERSE OF 'NO CYCLISTS' SCENARIO INCREASE
			gen base_slvalue_heat=-1*nocyclists_sivalue_heat			
			foreach x in govtarget govnearmkt gendereq dutch ebike {			
			gen `x'_sldeath_heat=`x'_sideath_heat+base_sldeath_heat
			gen `x'_slvalue_heat=`x'_sivalue_heat+base_slvalue_heat
			order `x'_sideath_heat `x'_sivalue_heat, after(`x'_slvalue_heat)
			}
			
		** CO2
			foreach x in nocyclists govtarget govnearmkt gendereq dutch ebike {
			gen `x'_sicartrips	=`x'_sid * cyclecommute_tripsperweek * 52.2 	// NO. CYCLISTS * COMMUTE PER DAY 
			gen `x'_sico2		=`x'_sid * cyclecommute_tripsperweek * 52.2 * cyc_dist_km * co2kg_km 	// NO. CAR TRIPS * DIST * CO2 EMISSIONS FACTOR
			}
			gen base_slco2=-1*nocyclists_sico2	// BASELINE LEVEL IS INVERSE OF 'NO CYCLISTS' SCENARIO INCREASE
			order base_slco2, before(govtarget_sicartrips)
			foreach x in govtarget govnearmkt gendereq dutch ebike {
			gen `x'_slco2=`x'_sico2+base_slco2
			order `x'_sicartrips `x'_slco2 , before(`x'_sico2)
			}
			drop mortrate nocyclists* cyclecommute_tripspertypicalweek- wprotection_heat
			
		** SAVE
			compress
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\CommuteSP_individual.dta", replace

		
	***********************************
	** SET GEOGRAPHY [ONCE FOR EACH]
	***********************************
		global geography = "lsoa" // "msoa" or "lsoa"
	
	*****************
	** PART pre5: PREPARE INDIVID FOR AGGREGATION [LSOA AND MSOA]
	*****************			
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\CommuteSP_individual.dta", clear	
		* PREPARE FOR AGGREGATION
			rename home_$geography geo_code_o 
			rename work_$geography geo_code_d
			gen all=1
			gen bicycle=(commute_mainmode9==1)
			gen foot=(commute_mainmode9==2)
			gen car_driver=(commute_mainmode9==3)
			gen car_passenger=(commute_mainmode9==4)
			gen motorbike=(commute_mainmode9==5)
			gen train_tube=(commute_mainmode9==6)
			gen bus=(commute_mainmode9==7)
			gen taxi_other=(commute_mainmode9==8)
			
			drop home*soa work*soa home_lad11cd home_laname home_gor // home_gordet
			drop flowtype commute_mainmode9- incomedecile
		* MAKE BIDIRECTIONAL OD AND SAVE TEMPORARY DATASET, PRE-AGGREGATION
			gen osub1=substr(geo_code_o,1,1)
			gen dsub1=substr(geo_code_d,1,1)
			gen osub2=substr(geo_code_o,2,.)
			gen dsub2=substr(geo_code_d,2,.)
			destring osub2 dsub2, replace force
			gen homefirst=.
			recode homefirst .=1 if (osub1=="E" & dsub1!="E")
			recode homefirst .=1 if (osub1=="W" & dsub1!="E" & dsub1!="W")
			recode homefirst .=0 if (osub1=="W" & dsub1=="E")
			recode homefirst .=1 if (osub1=="E" & dsub1=="E" & osub2<= dsub2)
			recode homefirst .=1 if (osub1=="W" & dsub1=="W" & osub2<= dsub2)
			recode homefirst .=0 if (osub1=="E" & dsub1=="E" & osub2>dsub2)
			recode homefirst .=0 if (osub1=="W" & dsub1=="W" & osub2>dsub2)
			gen geo_code1=geo_code_o
			replace geo_code1=geo_code_d if homefirst==0
			gen geo_code2=geo_code_d
			replace geo_code2=geo_code_o if homefirst==0
			drop osub1 dsub1 osub2 dsub2 homefirst
		* MAKE DATASET OF GORDET
			preserve
			keep geo_code_o home_gordet
			rename geo_code_o geo_code
			rename home_gordet gordet
			duplicates drop
			save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\geo_code_gordet.dta", replace
			restore
			drop home_gordet
		
		order geo_code1 geo_code2 geo_code_o geo_code_d all- taxi_other
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\CommuteSP_preaggregate_temp.dta", replace

	*****************
	** PART 5A: AGGREGATE TO ZONE LEVEL [LSOA AND MSOA]
	*****************	
		forval reg=1/11 {
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\CommuteSP_preaggregate_temp.dta", clear
		* RESTRICT TO HOME REGION
			rename geo_code_o geo_code
			merge m:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\geo_code_gordet.dta", nogen
			rename geo_code geo_code_o
			keep if gordet==`reg'
		* AGGREGATE UP AREA FIGURES
			foreach var of varlist all- taxi_other govtarget_slc- ebike_sico2 {
			bysort geo_code_o: egen a_`var'=sum(`var')
			}
		* PERCENT TRIPS AND TRIP HILLINESS
			recode rf_dist_km min/9.9999=1 10/max=0, gen(rf_u10km_dist)
			recode rf_u10km_dist .=0 if geo_code_d=="Other"
				* NB keep as missing if no fixed work place - implicitly assume they have same distribution as everyone else. This exclusion is comparable to what ONS do
			bysort geo_code_o: egen a_perc_rf_dist_u10km=mean(rf_u10km_dist*100)
			gen rf_u10km_avslope_perc=rf_avslope_perc
			replace rf_u10km_avslope_perc=. if rf_u10km_dist!=1
			bysort geo_code_o: egen a_avslope_perc_u10km=mean(rf_u10km_avslope_perc)
		* AREA FILE KEEP/RENAME + MERGE IN NAMES/LA + ORDER
			keep geo_code_o a_*
			rename geo_code_o geo_code
			rename a_* *
			duplicates drop
			merge 1:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\geo_code_lookup.dta"
			drop if _m==2
			drop _m
			order geo_code geo_name lad11cd lad_name all bicycle- taxi_other
		* SAVE + APPEND
			save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\z_all_reg`reg'.dta", replace
		}
			use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\z_all_reg1.dta", replace
			forval reg=2/11 {
			append using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\z_all_reg`reg'.dta"
			}
			export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\z_all_attributes_unrounded.csv", replace
			forval reg=1/11 {
			erase "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\z_all_reg`reg'.dta"
			}		
	
	*****************
	** PART 5B: AGGREGATE TO FLOW LEVEL [LSOA AND MSOA]
	*****************
		forval reg=1/11 {
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\CommuteSP_preaggregate_temp.dta", clear
			drop *cartrips	
		* RESTRICT TO STARTING ZONE REGION
			rename geo_code1 geo_code
			merge m:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\geo_code_gordet.dta", nogen
			rename geo_code geo_code1
			keep if gordet==`reg'
		* IDENTIFY VARIABLES WHERE 'ALL' IS TOO SMALL (for lsoa combine <3 flows to 'under 3')
			bysort geo_code1 geo_code2: gen f_all_temp=_N
			replace geo_code_d="Under 3" if f_all_temp<3 & "$geography"=="lsoa"
			replace geo_code1=geo_code_o if geo_code_d=="Under 3"
			replace geo_code2=geo_code_d if geo_code_d=="Under 3"
			foreach var of varlist rf_dist_km rf_avslope_perc {
			replace `var'=. if geo_code_d=="Under 3"
			}
			gen id = geo_code1+" "+geo_code2
			drop f_all_temp
		* AGGREGATE UP FLOW FIGURES
			foreach var of varlist all- taxi_other govtarget_slc- ebike_sico2 {
			bysort id: egen f_`var'=sum(`var')
			}
			foreach var of varlist rf_dist_km rf_avslope_perc {
			bysort id: egen f_`var'=mean(`var') // redundant for lsoa, useful for msoa
			}
		* FLOW FILE KEEP/RENAME + MERGE IN NAMES/LA + ORDER
			keep id geo_code1 geo_code2 f_* 
			rename f_* *
			duplicates drop
			forval i=1/2 {
			rename geo_code`i' geo_code
			merge m:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\geo_code_lookup.dta"
			drop if _m==2
			drop _m
			foreach x in geo_code geo_name lad11cd lad_name {
			rename `x' `x'`i'
			}
			}
			foreach x in geo_name2 lad11cd2 lad_name2 {
			replace `x'="No fixed place" if geo_code2=="OD0000003"
			replace `x'="Other" if geo_code2=="Other"
			replace `x'="Under 3" if geo_code2=="Under 3"
			}
			order id geo_code1 geo_code2 geo_name1 geo_name2 lad11cd1 lad11cd2 lad_name1 lad_name2 all bicycle- taxi_other govtarget_slc- ebike_sico2
		* MERGE IN OTHER CS DATA (BETWEEN-LINES ONLY)
			merge 1:1 id using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\rfrq_all_data.dta"
			recode e_dist_km .=0 if geo_code1==geo_code2 // within-zone
			order e_dist_km, before(rf_dist_km)
			drop if _m==2
			count if _m!=3 & geo_code1!=geo_code2 & geo_code2!="Other" & geo_code2!="OD0000003" & geo_code2!="Under 3" // should be none
			drop _m		
		* SAVE + APPEND
			save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\od_all_reg`reg'.dta", replace
		}
			use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\od_all_reg1.dta", replace
			forval reg=2/11 {
			append using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\od_all_reg`reg'.dta"
			}
			export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\od_all_attributes_unrounded.csv", replace
			forval reg=1/11 {
			erase "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\od_all_reg`reg'.dta"
			}
	
	*****************
	** PART 5C: AGGREGATE TO LA & PCT REGION LEVEL [LSOA ONLY]
	*****************
	** LA
		import delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\lsoa\z_all_attributes_unrounded.csv", clear
		drop *cartrips
		* AGGREGATE
			foreach var of varlist all- taxi_other govtarget_slc- ebike_sico2 {
			bysort lad11cd: egen a_`var'=sum(`var')
			}
			foreach var of varlist perc_rf_dist_u10km avslope_perc_u10km {
			bysort lad11cd: egen temp_`var'=sum(`var'*all)
			gen a_`var'=temp_`var'/a_all
			}
			keep lad11cd lad_name a_*
			rename a_* *
			duplicates drop
		* CHANGE UNITS
			foreach x in base_sl govtarget_sl govtarget_si govnearmkt_sl govnearmkt_si gendereq_sl gendereq_si dutch_sl dutch_si ebike_sl ebike_si{
			replace `x'value_heat=`x'value_heat/1000000 // convert to millions of pounds
			replace `x'co2=`x'co2/1000	// convert to tonnes
			}
		export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\lad_all_attributes_unrounded.csv", replace
	** REGION
		import delimited "pct-inputs\01_raw\01_geographies\pct_regions\pct_regions_lad_lookup.csv", varnames(1) clear 
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\pct_regions_lad_lookup.dta", replace
		import delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\lad_all_attributes_unrounded.csv", clear
		merge 1:1 lad11cd using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\pct_regions_lad_lookup.dta", keepus(region_name) nogen
		* AGGREGATE
			foreach var of varlist all- taxi_other govtarget_slc- ebike_sico2 {
			bysort region_name: egen a_`var'=sum(`var')
			}
			keep region_name a_*
			rename a_* *
			duplicates drop
		* PERCENTAGES FOR INTERFACE
			foreach var of varlist bicycle govtarget_slc govnearmkt_slc gendereq_slc dutch_slc ebike_slc {
			gen `var'_perc=round(`var'*100/all, 1)
			order `var'_perc, after(`var')
			}
			keep region_name *perc
			list if bicycle_perc==. 
			drop if bicycle_perc==. // should be nothing
		export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\pct_regions_all_attributes.csv", replace

	*****************
	** PART 5D: FILE FOR RASTER WITH NUMBERS ROUNDED (BUT CORRECT TOTALS MAINTAINED), AND NO FILTERING OF LINES <3 [LSOA ONLY]
	*****************			
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\lsoa\CommuteSP_preaggregate_temp.dta", clear
		* SUBSET BY DISTANCE AND TO SCENARIO VARIABLES
			keep if rf_dist_km<20 & geo_code1!=geo_code2
			gen id = geo_code1+" "+geo_code2
			keep id bicycle *_slc	
		* AGGREGATE UP FLOW FIGURES
			foreach var of varlist bicycle- ebike_slc {
			bysort id: egen f_`var'=sum(`var')
			}
			keep id f_*
			rename f_* *
			duplicates drop
		* ROUND + MOVE SOME CYCLISTS 0 TO 1, TO GET TOTAL CORRECT NUMBER	
			set seed 20170121
			gen random=uniform()
			foreach var of varlist govtarget_slc govnearmkt_slc gendereq_slc dutch_slc ebike_slc {
			rename `var' `var'_orig 
			gen `var'=round(`var'_orig)
			total `var'_orig `var'
			matrix A=r(table)
			di "`var': " round((100*(1-A[1,2]/A[1,1])),0.01) "%"
			}
			foreach var of varlist govtarget_slc govnearmkt_slc dutch_slc ebike_slc {	// not needed gendereq, as similar with/without rounding
			total `var'_orig `var' if `var'_orig<1.5
			matrix A=r(table)
			gen `var'_diff = round(A[1,1]-A[1,2]) // COUNT THE DIFFERENCE BETWEEN NO CYCLISTS ROUNDED VS NOT ROUNDED AMONG THOSE WHERE NOT ROUNDED IS <1.5	
			sort `var' random
			gen littlen=_n
			recode `var' 0=1 if littlen <=`var'_diff // ROUND SOME 0 TO 1 SO THAT TOTAL NO. <1.5 IS CORRECT
			drop littlen
			}
			foreach var of varlist govtarget_slc govnearmkt_slc gendereq_slc dutch_slc ebike_slc {			
			total `var'_orig `var' 
			matrix A=r(table)
			di "`var': " round((100*(1-A[1,2]/A[1,1])),0.01) "%"
			}
		* LIMIT TO THOSE WITH ANY CYCLING, AND SAVE
			egen sumcycle=rowtotal(bicycle govtarget_slc govnearmkt_slc gendereq_slc dutch_slc ebike_slc)
			drop if sumcycle==0
			keep id bicycle govtarget_slc govnearmkt_slc gendereq_slc dutch_slc ebike_slc
			sort id
			export delimited using "pct-inputs\02_intermediate\02_travel_data\commute_microsim\lsoa\od_raster_attributes.csv", replace

	erase "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute_microsim\\$geography\CommuteSP_preaggregate_temp.dta"

x

		* GM DESCRIPTIVES, TABLE 2 IN APPENDIX 1
			use "..\1 - Phys Act_1-PA main\2017_MetaHIT_analysis\1b_datacreated\Census2011EW_AllAdults.dta", clear
			keep if commute_mainmode9<9 // exclude non-commuters or work from home
			rename home_lad11cd lad11cd
			merge m:1 lad11cd using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\pct_regions_lad_lookup.dta", keepus(region_name) nogen
			keep if region_name=="greater-manchester"
			tab commute_mainmode9 nocar, col
			tab commute_mainmode9 nonwhite, col
			recode commute_mainmode9 2/max=0, gen(cycle)
			table agecat female if nonwhite==0, c(mean cycle)
			table agecat female if nonwhite==1, c(mean cycle)			

