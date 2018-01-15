clear
clear matrix
cd "C:\Users\Anna Goodman\Dropbox\GitHub"
*cd "C:\Users\annag\Dropbox\npct"
		
global geography = "msoa" // "msoa" or "lsoa"

* create directories by purpose/geography in the path_temp_scenario file [when move this to R, do that in R]
		
	/***********************
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
		rename lad11cd lad11cd
		rename lad11nm lad_name
		keep geo_code geo_name lad11cd lad_name
		duplicates drop
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\`x'\geo_code_lookup.dta", replace		
		}
	
	***********************
	* PREPARE MSOA AND LSOA TO HAVE SAME STARTING FORMATS (INPUT 1)
	***********************
	** LSOA
	*	import delimited "pct-inputs\02_intermediate\x_temporary_files\unzip\WM12EW[CT0489]_lsoa.csv", clear		
use "C:\Users\Anna Goodman\Dropbox\1 - Phys Act_1-PA main\2015_PCT_largefiles\1a_dataoriginal\Census2011\Flow_Level\LSOA_Age_Sex_Safeguarded\WM12EW[CT0489]_lsoa.dta" , clear
		* RENAME
			rename areaofusualresidence geo_code_o
			rename areaofworkplace geo_code_d
			rename allmethods_allsexes_age16plus all
			rename workathome_allsexes_age16plus from_home
			rename underground_allsexes_age16plus light_rail
			rename train_allsexes_age16plus train
			rename bus_allsexes_age16plus bus
			rename taxi_allsexes_age16plus taxi
			rename motorcycle_allsexes_age16plus motorbike
			rename carorvan_allsexes_age16plus car_driver
			rename passenger_allsexes_age16plus car_passenger
			rename bicycle_allsexes_age16plus bicycle
			rename onfoot_allsexes_age16plus foot
			rename othermethod_allsexes_age16plus other
			rename allmethods_male_age16plus all_male
			rename allmethods_female_age16plus all_female
			rename bicycle_male_age16plus bicycle_male
			rename bicycle_female_age16plus bicycle_female		 
			order geo_code_o geo_code_d all from_home light_rail train bus taxi motorbike car_driver car_passenger bicycle foot other /*
				*/ all_male all_female bicycle_male bicycle_female
			keep geo_code_o - bicycle_female			
		* COLLAPSE OTHER (CONSISTENT LSOA-MSOA)
			gen geo_code_dtemp=substr(geo_code_d,1,1)
			replace geo_code_d="OutsideEW" if geo_code_dtemp=="S" | geo_code_dtemp=="N" | geo_code_d=="OD0000002" | geo_code_d=="OD0000004"
				* Make 'OutsideEW' if S = scotland, N = northern ireland, OD0000002 = offshore installation, OD0000004 = otherwise overseas
			drop geo_code_dtemp
			foreach var of varlist all-other all_male-bicycle_female {
			bysort geo_code_o geo_code_d: egen `var'temp=sum(`var')
			replace `var'=`var'temp
			drop `var'temp
			}
			duplicates drop
		* SAVE			
			compress
			saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lsoa\ODpairs_starting.dta", replace

	** PREPARE SEX DATA FOR MSOA
		* MERGE IN MSOA CODES
			use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lsoa\ODpairs_starting.dta", clear
			drop all - other
			rename geo_code_o lsoa11cd
			merge m:1 lsoa11cd using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\LSOA11_MSOA11_LAD11_EW_LUv2.dta", keepus(msoa11cd) nogen
			rename msoa11cd geo_code_o
			drop lsoa11cd
			rename geo_code_d lsoa11cd
			merge m:1 lsoa11cd using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\LSOA11_MSOA11_LAD11_EW_LUv2.dta", keepus(msoa11cd) nogen
			rename msoa11cd geo_code_d
			replace geo_code_d=lsoa11cd if geo_code_d==""
			drop lsoa11cd 
		* MAKE MSOA AVERAGES
			foreach var of varlist all_male-bicycle_female {
			bysort geo_code_o geo_code_d: egen `var'temp=sum(`var')
			replace `var'=`var'temp
			drop `var'temp
			}
			order geo_code_o geo_code_d all_male all_female bicycle_male bicycle_female 
			duplicates drop
			compress
			saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\msoa\t2w_sex.dta", replace
		
	** MSOA
		import delimited "pct-inputs\02_intermediate\x_temporary_files\unzip\wu03ew_V2.csv", clear
		* RENAME
			rename areaofresidence geo_code_o
			rename areaofworkplace geo_code_d
			rename allcategoriesmethodoftraveltowor all
			rename workmainlyatorfromhome from_home
			rename undergroundmetrolightrailtram light_rail
			rename busminibusorcoach bus
			rename motorcyclescooterormoped motorbike
			rename drivingacarorvan car_driver
			rename passengerinacarorvan car_passenger
			rename onfoot foot
			rename othermethodoftraveltowork other
		* COLLAPSE OTHER (CONSISTENT LSOA-MSOA)
			gen geo_code_dtemp=substr(geo_code_d,1,1)
			replace geo_code_d="OutsideEW" if geo_code_dtemp=="S" | geo_code_dtemp=="N" | geo_code_d=="OD0000002" | geo_code_d=="OD0000004"
				* Make 'OutsideEW' if S = scotland, N = northern ireland, OD0000002 = offshore installation, OD0000004 = otherwise overseas
			**replace geo_code_d="OutsideEW" if geo_code_dtemp=="S" | geo_code_dtemp=="0" | geo_code_dtemp=="1" | geo_code_dtemp=="2" | geo_code_dtemp=="3" | geo_code_dtemp=="4" | geo_code_dtemp=="5" | geo_code_dtemp=="9" | geo_code_d=="OD0000002" 
				* previous wu03bew_msoa_v1 safeguarded: Make 'OutsideEW' if S = scotland, 01-59 = foreign countries, 9xx = Northern Ireland, OD0000002 = offshore installation,
			drop geo_code_dtemp
			foreach var of varlist all-other {
			bysort geo_code_o geo_code_d: egen `var'temp=sum(`var')
			replace `var'=`var'temp
			drop `var'temp
			}
			duplicates drop
		* MERGE IN BY SEX
			merge 1:1 geo_code_o geo_code_d using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\msoa\t2w_sex.dta", nogen
			count if ( all_male+ all_female)!=all // CHECK ZERO
		* SAVE			
			compress
			saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\msoa\ODpairs_starting.dta", replace

	**********************************	
	* PREPARE HEAT MORTALITY RATE FILE (INPUT 2 - PRE-PROCESSED IN EXCEL)
	**********************************	
		foreach x in msoa lsoa {
		import excel "pct-inputs\01_raw\03_health_data\commute\LA_WeightedMortality16-74_2014.xls", sheet("LA_Cyclists_MortRate") firstrow case(lower) clear
		keep if geographycode!=""
		keep geography geographycode mortrate_govtarget mortrate_gendereq mortrate_dutch 
		* FIX PLACES WITH SMALL AREAS MERGED
			gen temp=1
			recode temp 1=2 if geography=="Cornwall,Isles of Scilly"
			recode temp 1=2 if geography=="Westminster,City of London"
			expand temp
			bysort geography: gen littlen=_n
			replace geographycode="E06000053" if geographycode=="E06000052" & littlen==2 	// ISLES OF SCILLY, NOT CORNWALL
			replace geography="Cornwall" if geographycode=="E06000052"
			replace geography="Isles of Scilly" if geographycode=="E06000053"
			replace geographycode="E09000001" if geographycode=="E09000033" & littlen==2	// CITY OF LONDON, NOT WESTMINSTER
			replace geography="Westminster" if geographycode=="E09000033"
			replace geography="City of London" if geographycode=="E09000001"
		* FIX PLACES WITH DIFFERENT CODES (2014 vs 2011 LA codes)
			replace geographycode="E07000097" if geographycode=="E07000242"
			replace geographycode="E08000020" if geographycode=="E08000037"
			replace geographycode="E06000048" if geographycode=="E06000057"
			replace geographycode="E07000100" if geographycode=="E07000240"
			replace geographycode="E07000101" if geographycode=="E07000243"
			replace geographycode="E07000104" if geographycode=="E07000241"
		rename geographycode lad11cd
		* SAVE
		merge 1:m lad11cd using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\LSOA11_MSOA11_LAD11_EW_LUv2.dta" , keepus(`x'11cd lad11nm) nogen
		tab geography if geography!=lad11nm	// CHECK NOTHING
		rename `x'11cd geo_code
		order geo_code mortrate_govtarget mortrate_gendereq mortrate_dutch
		keep geo_code - mortrate_dutch
		compress
		duplicates drop
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\`x'\mortrate.dta", replace
		}
	*/
	**********************************	
	* PREPARE CYCLE STREETS DATA - SAVE AS STATA (INPUT 3)
	**********************************	
		import delimited "pct-inputs\02_intermediate\02_travel_data\commute\\$geography\\rfrq_all_data.csv", clear
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\rfrq_all_data.dta", replace
		
	*****************
	** MERGE OD DATA
	*****************
		* OPEN AND LIMIT TO COMMUTERS
			use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\ODpairs_starting.dta", clear
			drop if geo_code_d=="OD0000001"
				* drop if work mainly at home			
				
		* MERGE IN MORT RATES (DATASETS D2)
			rename geo_code_o geo_code
			merge m:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\mortrate.dta", nogen 
			rename geo_code geo_code_o

		* MERGE IN CYCLE STREETS VARIABLES (DATASET D3)
			rename geo_code_o geo_code1
			rename geo_code_d geo_code2
			merge 1:1 geo_code1 geo_code2 using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\rfrq_all_data.dta", keepus(e_dist_km rf_dist_km rf_avslope_perc)
			drop if _merge==2
			drop _merge
			rename geo_code1 geocodetemp
			rename geo_code2 geo_code1
			rename geocodetemp geo_code2
			merge 1:1 geo_code1 geo_code2 using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\rfrq_all_data.dta", keepus(e_dist_km rf_dist_km rf_avslope_perc) update
			drop if _merge==2
			drop _merge
			rename geo_code1 geo_code_d
			rename geo_code2 geo_code_o
				
	*****************
	** STEP 1: DEFINE FLOW TYPE AND COLLAPSE TYPE 4 FLOWS TO 'OTHER'
	*****************	
		* GENERATE FLOW TYPE 
			gen flowtype=.
			gen geo_code_dtemp=substr(geo_code_d,1,1)
			recode flowtype .=1 if (geo_code_dtemp=="E" | geo_code_dtemp=="W") & rf_dist_km!=. & geo_code_o!=geo_code_d
			recode flowtype .=2 if geo_code_o==geo_code_d
			recode flowtype .=3 if geo_code_d=="OD0000003"
			recode flowtype .=4 if (geo_code_dtemp=="E" | geo_code_dtemp=="W") & rf_dist_km==. 
			recode flowtype .=4 if geo_code_d=="OutsideEW"
			label def flowtypelab 1 "England/Wales between-zone" 2 "Within zone" 3 "No fixed place" 4 "Over max dist or outside England/Wales, offshore installation", modify
			label val flowtype flowtypelab
			drop geo_code_dtemp

		* COLLAPSE 'OTHER' FLOW TYPES
			replace geo_code_d="Other" if flowtype==4
			foreach var of varlist all- other all_male-bicycle_female {
			bysort geo_code_o geo_code_d: egen `var'temp=sum(`var')
			replace `var'=`var'temp
			drop `var'temp
			}			
			duplicates drop
			
	*****************
	** STEP 2: ASSIGN VALUES IF DISTANCE/HILLINESS UNKNOWN
	*****************				
		** ASSIGN ESTIMATED HILLINESS + DISTANCE VALUES IF START AND END IN SAME PLACE
			by geo_code_o (rf_dist_km), sort: gen littlen=_n
			foreach x in rf_dist_km rf_avslope_perc {
			gen `x'temp=`x'
			replace `x'temp=. if littlen>3
			bysort geo_code_o: egen `x'temp2=mean(`x'temp)
			replace `x'=`x'temp2 if flowtype==2 & `x'==.
			}
			replace rf_dist_km=rf_dist_km/3 if flowtype==2 
				* DISTANCE = A THIRD OF THE MEAN DISTANCE OF SHORTEST 3 FLOWS
				* HILLINESS = MEAN HILLINESS OF SHORTEST 3 FLOWS
			recode rf_dist_km .=0.79 if (geo_code_o=="E02006781" | geo_code_o=="E01019077") & geo_code_o==geo_code_d 		//ISLES OF SCILLY [msoa/lsoa] - ESTIMATED FROM DISTANCE DISTRIBUTION
			recode rf_avslope_perc .=0.2 if (geo_code_o=="E02006781" | geo_code_o=="E01019077") & geo_code_o==geo_code_d //ISLES OF SCILLY [msoa/lsoa] - ESTIMATED FROM CYCLE STREET 
			replace e_dist_km=0 if flowtype==2
			drop littlen rf_dist_kmtemp rf_dist_kmtemp2 rf_avslope_perctemp rf_avslope_perctemp2 
			
		** ASSIGN DISTANCE *AMONG CYCLISTS* VALUES IF NO FIXED PLACE : MEAN DIST AMONG CYCLISTS TRAVELLING <15KM
			gen cyc_dist_km=rf_dist_km
			foreach x in 15 30 {
			gen rf_dist_km`x'=rf_dist_km
			replace rf_dist_km`x'=. if rf_dist_km>`x' | flowtype>2
			gen bicycle`x'=bicycle
			replace bicycle`x'=. if rf_dist_km`x'==.
			}
			bysort geo_code_o: egen numnrf_dist_km15=sum(rf_dist_km15*bicycle15)
			bysort geo_code_o: egen denrf_dist_km15=sum(bicycle15)
			gen meanrf_dist_km15=numnrf_dist_km15/denrf_dist_km15
			replace cyc_dist_km=meanrf_dist_km15 if flowtype==3 

		** ASSIGN DISTANCE *AMONG CYCLISTS* VALUES IF OUTSIDE ENG/WALES OR >30KM: MEAN DIST AMONG CYCLISTS TRAVELLING <30KM
			egen numnrf_dist_km30=sum(rf_dist_km30*bicycle30)
			egen denrf_dist_km30=sum(bicycle30)
			gen meanrf_dist_km30=numnrf_dist_km30/denrf_dist_km30
			replace cyc_dist_km=meanrf_dist_km30 if flowtype==4 
			replace cyc_dist_km=meanrf_dist_km30 if flowtype==3 & cyc_dist_km==.	// USE 30KM if NO LOCAL CYCLIST GOING <15KM
					
	** SAVE RELEVANT VARIABLES (USE THIS TO FIT INDIVIDUAL MODEL)
		order geo_code_o geo_code_d /*
			*/ all-other flowtype all_male- bicycle_female mortrate_govtarget mortrate_gendereq mortrate_dutch /*
			*/ e_dist_km rf_dist_km rf_avslope_perc cyc_dist_km
		keep geo_code_o-cyc_dist_km
		compress
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\ODpairs_process2.1.dta", replace	
		*use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\ODpairs_process2.1.dta", clear

	*****************
	** STEP 3A: CALCULATE PROPENSITY TO CYCLE [model derived from MSOA trips]
	*****************
		** MODEL FITTING FOR TRIPS <30KM
			* INPUT PARAMETERS
				gen rf_dist_kmsq=rf_dist_km^2
				gen rf_dist_kmsqrt=sqrt(rf_dist_km)
				gen ned_rf_avslope_perc=rf_avslope_perc-0.97 
				gen interact=rf_dist_km*ned_rf_avslope_perc
				gen interactsqrt=rf_dist_kmsqrt*ned_rf_avslope_perc
				
			* FIT REGRESSION EQUATION
				gen pred_base= /*
					*/ -3.959 + (-0.5963 * rf_dist_km) + (1.866 * rf_dist_kmsqrt) + (0.008050 * rf_dist_kmsq) + (-0.2710 * ned_rf_avslope_perc) + (0.009394 * rf_dist_km*ned_rf_avslope_perc) + (-0.05135 * rf_dist_kmsqrt*ned_rf_avslope_perc) 
				gen bdutch = 2.523+(-0.07626*rf_dist_km)					// FROM DUTCH NTS
				replace bdutch=. if flowtype==3
				gen bebike= (0.05710*rf_dist_km)+(-0.0001087*rf_dist_kmsq)	// PARAMETERISED FROM DUTCH TRAVEL SURVEY, ASSUMING NO DIFFERENCE AT 0 DISTANCE
				replace bebike=bebike+(0.1812 *ned_rf_avslope_perc)	// SWISS TRAVEL SURVEY

				gen pred_dutch= pred_base + bdutch
				gen pred_ebike= pred_dutch + bebike
				foreach x in base dutch ebike {
				replace pred_`x'=exp(pred_`x')/(1+exp(pred_`x'))
				}

		** MODEL FITTING FOR TRIPS WITH NO FIXED PLACE
			* INPUT PARAMETERS
				foreach x in pred_base bdutch bebike { // WEIGHTED AVERAGE OF COMMUTERS IN FLOWTYPE 1 & "
				gen `x'temp=`x'
				replace `x'temp=. if flowtype!=1 & flowtype!=2	// WEIGHTED AVERAGE OF COMMUTERS IN FLOWTYPE 1 & "
				gen alltemp=all
				replace alltemp=. if `x'temp==.
				bysort geo_code_o: egen nummean`x'=sum(`x'temp*alltemp)
				bysort geo_code_o: egen denmean`x'=sum(alltemp)
				gen mean`x'=nummean`x'/denmean`x'
				drop `x'temp alltemp nummean`x' denmean`x'
				}
				gen meanpred_basesq=meanpred_base^2
				gen meanpred_basesqrt=meanpred_base^0.5

			* FIT REGRESSION EQUATION
				gen pred2_base= -6.399 + (184.0 * meanpred_basesq) + (10.36 * meanpred_basesqrt) 
				gen pred2_dutch= pred2_base + meanbdutch
				gen pred2_ebike= pred2_dutch + meanbebike
				foreach x in base dutch ebike {
				replace pred2_`x'=exp(pred2_`x')/(1+exp(pred2_`x'))
				replace pred_`x'=pred2_`x' if flowtype==3
				drop pred2_`x'
				}

		** DROP INTERMEDIARY VARIABLES
			drop rf_dist_kmsq rf_dist_kmsqrt ned_rf_avslope_perc interact interactsqrt meanpred_base bdutch bebike meanbdutch meanbebike meanpred_basesq meanpred_basesqrt

	*****************
	** PART 3B: APPLY SCENARIOS TO OD DATA
	*****************
		** CALCULATE NO. CYCLISTS IN EACH SCENARIO
			gen nocyclists_slc=0
			gen nocyclists_sic=nocyclists_slc-bicycle
		
			gen govtarget_slc=bicycle+(pred_base*all)
			replace govtarget_slc=all if govtarget_slc>all & govtarget_slc!=. // MAXIMUM PERCENT CYCLISTS IS 100%
			gen govtarget_sic=govtarget_slc-bicycle
			order govtarget_slc, before(govtarget_sic)
	
			gen gendereq_slc=(bicycle_male*(1 + (all_female/all_male)))
			replace gendereq_slc=all if gendereq_slc>all & gendereq_slc!=. // [not needed] MAXIMUM PERCENT CYCLISTS IS 100%
			*tab all if female==0 | male==0		
			replace gendereq_slc=bicycle if all_female==0 	// [not needed] NO CHANGE IF NO FEMALES IN FLOW
			replace gendereq_slc=bicycle if all_male==0 	// NO CHANGE IF NO MALES IN FLOW
			replace gendereq_slc=bicycle if gendereq_slc<bicycle 	// NO CHANGE IF SLC < BASELINE
			gen gendereq_sic=gendereq_slc-bicycle
	
			foreach x in dutch ebike {
			gen `x'_slc=pred_`x'*all
			replace `x'_slc=all if `x'_slc>all & `x'_slc!=. // MAXIMUM PERCENT CYCLISTS IS 100%
			*tab all if `x'_slc<bicycle
			replace `x'_slc=bicycle if `x'_slc<bicycle 		 // MINIMUM NO. CYCLISTS IS BASELINE
			gen `x'_sic=`x'_slc-bicycle
			}
			foreach x in govtarget gendereq dutch ebike {
			replace `x'_slc=bicycle if geo_code_d=="Other"	// NO INCREASE AMONG FLOWS OUT OF SCOPE AS TOO LONG/OutsideEW ETC
			replace `x'_sic=0 if geo_code_d=="Other"
			}
	
		** CALCULATE % NON-CYCLISTS MADE CYCLISTS IN EACH SCENARIO: TURN THAT % AWAY FROM WALKING
			foreach x in nocyclists {
			gen pchange_`x'=(all-`x'_slc)/(all-bicycle) 
				/*	
					gen pcycle=bicycle/all
					gen pfoot=foot/all
					gen pcar_driver=car_driver/all
					sum pfoot pcar_driver pcycle if pcycle>0.5 & pcycle<1 [fw=all]
					disp 0.131/(1-0.5826)		// 31% NON-CYCLE FLOWS WALKING IN HIGH CYCLE AREAS
					disp 0.147/(1-0.5826)	// 35% NON-CYCLE FLOWS DRIVING IN HIGH CYCLE AREAS
					*/	
			gen `x'_slw=foot*pchange_`x'					// most flows - scale walking according to %change
			replace `x'_slw=((all-`x'_slc)*0.31) if bicycle==all	// Flows with pure bicycles at baseline - make walking 13% of new flows
			gen `x'_siw=`x'_slw-foot
			gen `x'_sld=car_driver*pchange_`x'			
			replace `x'_sld=((all-`x'_slc)*0.35) if bicycle==all	// Flows with pure bicycles at baseline - make driving 44% of new flows
			gen `x'_sid=`x'_sld-car_driver	
			order `x'_slw `x'_siw `x'_sld `x'_sid, after(`x'_sic)
			}
			
			foreach x in govtarget gendereq dutch ebike {
			gen pchange_`x'=(all-`x'_slc)/(all-bicycle) 	// % change in non-cycle modes
			recode pchange_`x' .=1 if all==bicycle 			// make 1 (i.e. no change) if everyone in the flow cycles
			gen `x'_slw=foot*pchange_`x'
			gen `x'_siw=`x'_slw-foot
			gen `x'_sld=car_driver*pchange_`x'
			gen `x'_sid=`x'_sld-car_driver
			order `x'_slw `x'_siw `x'_sld `x'_sid, after(`x'_sic)
			}
		
		** DROP INTERMEDIARY VARIABLES
			compress
			drop pred_base pred_dutch pred_ebike 
			drop pchange_nocyclists pchange_govtarget pchange_gendereq pchange_dutch pchange_ebike

	*****************
	** STEP 4: DO HEAT
	*****************
		* INPUT PARAMETERS
			gen cyclecommute_tripspertypicalweek = 7.17	
			gen cspeed = 14	
			gen wspeed = 4.8
			gen ebikespeed = 15.8
			gen ebikemetreduction = 0.648
			recode cyc_dist_km min/4.9999999=.06 5/9.9999999=.11 10/19.999999=.17 20/max=.23, gen(percentebike_dutch)
			recode cyc_dist_km min/4.9999999=.71 5/19.9999999=.92 20/max=1, gen(percentebike_ebike)	
			gen crr_heat=0.9 
			gen cdur_ref_heat=100	
			gen wrr_heat=0.89 
			gen wdur_ref_heat=168
			gen mortrate_nocyclists=mortrate_govtarget
			gen mortrate_ebike=mortrate_dutch
			gen vsl=1855315		// VALUE IN POUNDS
			
		* DURATION OF CYCLING/WALKING
			gen cdur_obs = 60*((cyc_dist_km*cyclecommute_tripspertypicalweek)/cspeed) // TIME CYCLING PER WEEK IN MINUTES AMONG NEW CYCLISTS
			gen cdur_obs_dutch=((1-percentebike_dutch)*cdur_obs)+(percentebike_dutch*cdur_obs*ebikemetreduction*(cspeed/ebikespeed))
			gen cdur_obs_ebike=((1-percentebike_ebike)*cdur_obs)+(percentebike_ebike*cdur_obs*ebikemetreduction*(cspeed/ebikespeed))
			
			gen wdur_obs = 60*((cyc_dist_km*cyclecommute_tripspertypicalweek)/wspeed) // TIME WALKING PER WEEK IN MINUTES AMONG THOSE NOW SWITCHING TO CYCLING
		*	drop cyclecommute_tripspertypicalweek cspeed wspeed ebiketimereduction ebikemetreduction percentebike_dutch percentebike_ebike
		*	compress 

		* MORTALITY PROTECTION
			gen cprotection_govtarget_heat= (1-crr_heat)*(cdur_obs/cdur_ref_heat)	// SCALE RR DEPENDING ON HOW DURATION IN THIS POP COMPARES TO REF
			gen cprotection_nocyclists_heat=cprotection_govtarget_heat
			gen cprotection_gendereq_heat=cprotection_govtarget_heat
			gen cprotection_dutch_heat= (1-crr_heat)*(cdur_obs_dutch/cdur_ref_heat)
			gen cprotection_ebike_heat= (1-crr_heat)*(cdur_obs_ebike/cdur_ref_heat)
			foreach x in nocyclists govtarget gendereq dutch ebike {			
			recode cprotection_`x'_heat 0.45/max=0.45			
			}
			gen wprotection_heat= (1-wrr_heat)*(wdur_obs/wdur_ref_heat)
			recode wprotection_heat 0.30/max=0.30		
			
		* DEATHS AND VALUES
			foreach x in nocyclists govtarget gendereq dutch ebike {
			gen `x'_sic_death_heat=`x'_sic*mortrate_`x'*cprotection_`x'_heat*-1
			gen `x'_siw_death_heat=`x'_siw*mortrate_`x'*wprotection_heat*-1
			gen `x'_sideath_heat=`x'_sic_death_heat+`x'_siw_death_heat
			gen long `x'_sivalue_heat=`x'_sideath_heat*vsl*-1
			drop `x'_sic_death_heat `x'_siw_death_heat
			}
			gen base_sldeath_heat=-1*nocyclists_sideath_heat	// BASELINE LEVEL IS INVERSE OF 'NO CYCLISTS' SCENARIO INCREASE
			gen base_slvalue_heat=-1*nocyclists_sivalue_heat			
			foreach x in govtarget gendereq dutch ebike {
			gen `x'_sldeath_heat=`x'_sideath_heat+base_sldeath_heat
			gen long `x'_slvalue_heat=`x'_sivalue_heat+base_slvalue_heat
			order `x'_sideath_heat `x'_sivalue_heat, after(`x'_slvalue_heat)
			}
		
		* DROP INTERMEDIARY VARIABLES
			drop mortrate_govtarget mortrate_gendereq mortrate_dutch cyclecommute_tripspertypicalweek - wprotection_heat
			drop nocyclists_sideath_heat nocyclists_sivalue_heat

	*****************
	** STEP 5: DO CO2 EMISSIONS CALCS 
	*****************
		gen cyclecommute_tripsperweek=5.24
		gen co2kg_km=0.186
		foreach x in nocyclists govtarget gendereq dutch ebike {
		gen long `x'_sico2=`x'_sid * cyc_dist_km * cyclecommute_tripsperweek * 52.2 * co2kg_km 	// NO CYCLISTS * DIST * COMMUTE PER DAY * CO2 EMISSIONS FACOTR
		}
		gen base_slco2=-1*nocyclists_sico2	// BASELINE LEVEL IS INVERSE OF 'NO CYCLISTS' SCENARIO INCREASE
		foreach x in govtarget gendereq dutch ebike {
		gen long `x'_slco2=`x'_sico2+base_slco2
		order `x'_sico2 , after(`x'_slco2)
		}
		drop nocyclists* cyclecommute_tripsperweek co2kg_km cyc_dist_km

	*****************
	** FINISH: MAKE BIDIRECTIONAL OD AND SAVE TEMPORARY DATASET, PRE-AGGREGATION
	*****************
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
		
		order geo_code1 geo_code2 
		compress 
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\ODpairs_process2.5.dta", replace

	*****************
	** PART 3A.1: AGGREGATE TO ZONE LEVEL
	*****************
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\ODpairs_process2.5.dta", clear
		* AGGREGATE UP AREA FIGURES
			foreach var of varlist all- other govtarget_slc- ebike_sico2 {
			bysort geo_code_o: egen a_`var'=sum(`var')
			}
		* PERCENT TRIPS AND TRIP HILLINESS
			recode rf_dist_km min/9.9999=1 10/max=0, gen(rf_u10km_dist)
			recode rf_u10km_dist .=0 if geo_code_d=="Other"
				* NB keep as missing if no fixed work place - implicitly assume they have same distribution as everyone else. This exclusion is comparable to what ONS do ()
			gen all_u10km_dist=all
			replace all_u10km_dist=. if rf_u10km_dist==.
			bysort geo_code_o: egen rf_u10km_dist_numerator=sum(rf_u10km_dist*all_u10km_dist)
			bysort geo_code_o: egen rf_u10km_dist_denominator=sum(all_u10km_dist)
			gen a_perc_rf_dist_u10km = 100*rf_u10km_dist_numerator/rf_u10km_dist_denominator
			
			gen rf_u10km_avslope_perc=rf_avslope_perc
			replace rf_u10km_avslope_perc=. if rf_u10km_dist!=1
			gen all_u10km_avslope=all
			replace all_u10km_avslope=. if rf_u10km_avslope==.
			bysort geo_code_o: egen rf_u10km_avslope_numerator=sum(rf_u10km_avslope_perc*all_u10km_avslope)
			bysort geo_code_o: egen rf_u10km_avslope_denominator=sum(all_u10km_avslope)
			gen a_avslope_perc_u10km = rf_u10km_avslope_numerator/rf_u10km_avslope_denominator
			
		* AREA FILE KEEP/RENAME + MERGE IN NAMES/LA + ORDER
			keep geo_code_o a_*
			rename geo_code_o geo_code
			rename a_* *
			drop from_home
			duplicates drop
			merge 1:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\geo_code_lookup.dta", nogen		
			order geo_code geo_name lad11cd lad_name all light_rail- other
* DROP WALES!
gen temp=substr(geo_code,1,1)
drop if temp=="W"
drop temp
		* SAVE
			export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\z_all_attributes_unrounded.csv", replace

	*****************
	** PART 3A.1: AGGREGATE TO LA & PCT REGION LEVEL [USE LSOA]
	*****************
	** LA
		import delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lsoa\z_all_attributes_unrounded.csv", clear
		* AGGREGATE
			foreach var of varlist all- other govtarget_slc- ebike_sico2 {
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
			foreach x in base_sl govtarget_sl govtarget_si gendereq_sl gendereq_si dutch_sl dutch_si ebike_sl ebike_si{
			replace `x'value_heat=`x'value_heat/1000000 // convert to millions of pounds
			replace `x'co2=`x'co2/1000	// convert to tonnes
			}
		export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lad_all_attributes_unrounded.csv", replace
	** REGION
		import delimited "pct-inputs\01_raw\01_geographies\pct_regions\pct_regions_lad_lookup.csv", varnames(1) clear 
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\pct_regions_lad_lookup.dta", replace
		import delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lad_all_attributes_unrounded.csv", clear
		merge 1:1 lad11cd using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\pct_regions_lad_lookup.dta", keepus(region_name) nogen
		* AGGREGATE
			foreach var of varlist all- other govtarget_slc- ebike_sico2 {
			bysort region_name: egen a_`var'=sum(`var')
			}
			keep region_name a_*
			rename a_* *
			duplicates drop
		* PERCENTAGES FOR INTERFACE
			foreach var of varlist bicycle govtarget_slc gendereq_slc dutch_slc ebike_slc {
			gen `var'_perc=round(`var'*100/all, 1)
			order `var'_perc, after(`var')
			}
			keep region_name *perc
			list if bicycle_perc==. 
			drop if bicycle_perc==. // should be nothing, but temporarily is Wales
		export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\pct_regions_all_attributes.csv", replace

	*****************
	** PART 3B.1: AGGREGATE TO FLOW LEVEL 
	*****************
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\ODpairs_process2.5.dta", clear
		* IDENTIFY VARIABLES WHERE 'ALL' IS TOO SMALL (for lsoa combine <3 flows to 'under 3')
			bysort geo_code1 geo_code2: egen f_all_temp=sum(all)
			replace geo_code_d="Under 3" if f_all_temp<3 & "$geography"=="lsoa"
			replace geo_code1=geo_code_o if geo_code_d=="Under 3"
			replace geo_code2=geo_code_d if geo_code_d=="Under 3"
			foreach var of varlist e_dist_km rf_dist_km rf_avslope_perc {
			replace `var'=. if geo_code_d=="Under 3"
			}
			gen id = geo_code1+" "+geo_code2
			drop f_all_temp
		* AGGREGATE UP FLOW FIGURES
			foreach var of varlist all- other govtarget_slc- ebike_sico2 {
			bysort id: egen f_`var'=sum(`var')
			}
		* FLOW FILE KEEP/RENAME + MERGE IN NAMES/LA + ORDER
			keep id geo_code1 geo_code2 f_* e_dist_km rf_dist_km rf_avslope_perc 
			rename f_* *
			drop from_home
			duplicates drop
			forval i=1/2 {
			rename geo_code`i' geo_code
			merge m:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\geo_code_lookup.dta"
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
			order id geo_code1 geo_code2 geo_name1 geo_name2 lad11cd1 lad11cd2 lad_name1 lad_name2 all light_rail- other govtarget_slc- ebike_sico2
		* MERGE IN OTHER CS DATA (BETWEEN-LINES ONLY)
			merge 1:1 id using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\rfrq_all_data.dta"
			drop if _m==2
			count if _m!=3 & geo_code1!=geo_code2 & geo_code2!="Other" & geo_code2!="OD0000003" & geo_code2!="Under 3" // should be none
			drop _m
* DROP WALES!
gen temp=substr(geo_code1,1,1)
drop if temp=="W"
drop temp		
		* SAVE
			export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\od_all_attributes_unrounded.csv", replace
			
	*****************
	** PART 3B.2: FILE FOR RASTER WITH NUMBERS ROUNDED (BUT CORRECT TOTALS MAINTAINED), AND NO FILTERING OF LINES <3
	*****************			
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\ODpairs_process2.5.dta", clear
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
			foreach var of varlist govtarget_slc gendereq_slc dutch_slc ebike_slc {
			rename `var' `var'_orig 
			gen `var'=round(`var'_orig)
			total `var'_orig `var' if `var'_orig<1.5
			matrix A=r(table)
			gen `var'_diff = round(A[1,1]-A[1,2]) // COUNT THE DIFFERENCE BETWEEN NO CYCLISTS ROUNDED VS NOT ROUNDED AMONG THOSE WHERE NOT ROUNDED IS <1.5	
			sort `var' random
			gen littlen=_n
			recode `var' 0=1 if littlen <=`var'_diff // ROUND SOME 0 TO 1 SO THAT TOTAL NO. <1.5 IS CORRECT
			drop littlen
			total `var'_orig `var' 
			matrix A=r(table)
			di "`var': " round((100*(1-A[1,2]/A[1,1])),0.01) "%"
			}
		* LIMIT TO THOSE WITH ANY CYCLING, AND SAVE
			egen sumcycle=rowtotal(bicycle govtarget_slc gendereq_slc dutch_slc ebike_slc)
			drop if sumcycle==0
			keep id bicycle govtarget_slc gendereq_slc dutch_slc ebike_slc
			sort id
			export delimited using "pct-inputs\02_intermediate\02_travel_data\commute\\$geography\od_raster_attributes.csv", replace
