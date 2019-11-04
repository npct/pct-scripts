clear
clear matrix
cd "F:\Github_Maxtor"

	/** SAVE CSV FILES IN STATA FORMAT
		import delimited "pct-inputs\02_intermediate\02_travel_data\school\lsoa\flows_2011.csv", delimiter(comma) varnames(1) clear
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\flows_2011.dta", replace
		import delimited "pct-inputs\02_intermediate\02_travel_data\school\lsoa\rfrq_all_data.csv", varnames(1) clear 
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\rfrq_all_data.dta", replace
		import delimited "pct-inputs\02_intermediate\01_geographies\lookup_urn_lsoa11.csv", varnames(1) clear 
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\lookup_urn_lsoa11.dta", replace
		*/
		
	/****************
	** METHODS TEXT
	****************
		** CHILDREN AGE 0-18 IN ENGLAND BY LSOA
			di 12011940 / 32844 // 365 - age 0-18: from PP01UK row 22 https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/2011censuspopulationestimatesbysingleyearofageandsexforlocalauthoritiesintheunitedkingdom
			di 11336875 / 32844 // 345 - age 2-18
		** DECISION TO COMBINE EARLY YEARS AND PRIMARY
			import delimited "C:\Users\Anna Goodman\Dropbox\GitHub\pct-inputs\01_raw\02_travel_data\school\lsoa\NPD_originals_PRIVATE\SLD_CENSUS_2011.txt", clear 		
			* % primary with reception/nursery
				egen numyoung=rowtotal( lea11_pt_girls_2- lea11_pt_girls_4 lea11_ft_girls_2- lea11_ft_girls_4 lea11_pt_boys_2- lea11_pt_boys_4 lea11_ft_boys_2-lea11_ft_boys_4 )
				recode numyoung 1/max=1, gen(anyyoung)
				*tab lea11_phase anyyoung, row nofreq // 92%
				di 15300/168.84 // 91%: using https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/219589/osr18-2012v2.pdf
			* % 2-4 year olds in primary rather than reception/nursery
				ta lea11_phase [fw=numyoung] // 96%
			* % not classified phase
				ta lea11_phase
				di 1304/(21523+2415) // add in independent schools
		** % PRIMARY CHILDREN AGE 2 TO 4
			import delimited "pct-inputs\02_intermediate\02_travel_data\school\lsoa\flows_2011.csv", delimiter(comma) varnames(1) clear
			egen all=rowtotal(bicycle- unknown)
			bysort urn: egen schoolsize=sum(all)
			keep urn phase secondary schoolsize age2to3_num
			duplicates drop
			total age2to3_num schoolsize if secondary==0
			di 337872/42020.63 
			
			
		*/	
	/****************
	** DEFINE SCHOOL STUDY POPULATION
	****************
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\flows_2011.dta", clear
		** PREPARATION CLEANING VARS
			egen all=rowtotal(bicycle- unknown)
			bysort urn: egen schoolsize=sum(all)
			bysort urn: gen schoolflag=_n
			recode schoolflag 2/max=0
				
		** MIN SCHOOL SIZE - OR PERHAPS NOT EXCEPT FOR SO SMALL THAT DISCLOSIVE? 
			*list schoolsize urn- secondary if schoolflag==1 & schoolsize<7
				* N=1: inpatients at the hospital (http://www.ashvilla.lincs.sch.uk/)
				* N=5: v. small primary
				* N=6, spires school: small special school
				* N=6, Holy Island: v. small primary in Lindisfarm Island
			*drop if schoolsize<5 // 1 school - don't even report in write up

		** MAX % SCHOOL BOARDING - OTHERWISE GET AT POTENTIAL/HEALTH IMPACTS WRONG [NB THOSE PUPILS WHO ARE BOARDING ARE PROBABY COMING FAR = CAN ASSUME NO CHANGE]
			gen school_boarding=(boarding_perc>=50)

		** MAX % SCHOOL WITH UNKNOWN MODE OR LSOA 
			gen unknownmodelsoa=unknown
			replace unknownmodelsoa=all if lsoa11cd=="NA"
			bysort urn: egen numunknownmodelsoa=sum(unknownmodelsoa)
			gen unknownmodelsoa_perc=numunknownmodelsoa*100/schoolsize
			*ta unknownmodelsoa_perc if schoolflag==1 
			gen school_unknown=(unknownmodelsoa_perc>25)
			
			/* 
			** 05.2 EXTRA: FIND SCHOOLS WITH TOO FEW PEOPLE 2011 BUT OK 2010: FEED BACK TO 03.2
				* URNS OF SCHOOLS WITH TOO FEW PEOPLE 2011
					keep if school_unknown==1
					keep urn
					duplicates drop
					save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\temp_schoolunknown.dta", replace
				
				* URNS OF SCHOOLS WITH TOO FEW PEOPLE 2010
					import delimited "pct-inputs\01_raw\02_travel_data\school\lsoa\NPD_originals_PRIVATE\Spring_Census_2010.txt", clear 
					bysort urn: egen schoolsize=sum(total)
					gen unknownmodelsoa=unknown
					replace unknownmodelsoa=total if llsoa_spr10==""
					bysort urn: egen numunknownmodelsoa=sum(unknownmodelsoa)
					gen unknownmodelsoa_perc=(numunknownmodelsoa*100/schoolsize)
					gen school_unknown=(unknownmodelsoa_perc>25)
					
					rename urn_spr10 urn
					keep urn unknownmodelsoa_perc school_unknown
					duplicates drop
					merge 1:1 urn using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\temp_schoolunknown.dta"
					erase "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\temp_schoolunknown.dta"
					keep if _m==3
					drop _m
					
					ta unknownmodelsoa_perc if school_unknown==0
					keep if school_unknown==0
					gen replace2011=1
					keep urn replace2011 // paste back into the file below
					* export delimited using "pct-inputs\01_raw\02_travel_data\school\lsoa\x-manual_extras\0_flowdata_missing2011_present2010.csv", replace
				*/

		** STUDYPOP: METHODS TEXT
			gen studypop=1
			recode studypop 1=0 if school_boarding==1 | school_unknown==1
				total schoolflag 
				total schoolflag if school_boarding==1
				total schoolflag if school_boarding==0 & school_unknown==1 
			total schoolflag all if studypop==1 & secondary==0
			total schoolflag all if studypop==1 & secondary==1
			tab studypop secondary [fw=all], col
				di (100-7.1)*.988 // 92% of all pupils, inc private			
			drop school_boarding numunknownmodelsoa- school_unknown
			drop if studypop==0

		** MISSING DATA: METHODS TEXT
			gen unknownmode=unknown
			gen unknownlsoa=0
			replace unknownlsoa=all if lsoa11cd=="NA"
			total unknownlsoa unknownmode all
				di 21150/74425.32
				di 16479/74425.32

	****************
	** IMPUTING UNKNOWN DATA
	****************
		** RESHAPE TO INDIVIDUAL LEVEL
			keep id lsoa11cd lsoa11nm urn schoolname phase secondary bicycle foot car other unknown
			rename bicycle numpupils1
			rename foot numpupils2
			rename car numpupils3
			rename other numpupils4
			rename unknown numpupils5
			reshape long numpupils, i(id) j(mode)
			drop if numpupils==0
			expand numpupils
			drop numpupils
			
		** IF LSOA UNKNOWN, RANDOMLY GIVE ANOTHER PUPIL'S LSOA WITH SAME MODE FROM SAME SCHOOL
			set seed 20180104
			set sortseed 2017	// otherwise gsample gives different results because of the preceeding bysort
			
			* Identify tiny no. children with no mode-school match available; for them don't match on mode
				gen nonmissinglsoa=(lsoa11cd!="NA")
				bysort urn mode : egen bigntemp=sum(nonmissinglsoa)
				count if bigntemp==0 // N=21...don't even bother to report this
				gen mode_temp=mode
				recode mode_temp 1=2 2=3 4=3 5=2 if bigntemp==0 // match cycle+unknown to walk, rest to car - fiddling around = this way gives everyone a match
				drop bigntemp
			* Generate number with that mode and non-missing LSOA
				bysort urn mode_temp : egen bign=sum(nonmissinglsoa)
				count if bign==0 // should be zero		
			* Rank within each mode
				by urn mode_temp nonmissinglsoa (lsoa11cd), sort: gen littlen=_n
			* Generate random position, by mode, to sample from
				gen littlen_lsoamatch=uniform()
				replace littlen_lsoamatch=ceil(littlen_lsoamatch*bign)
			* Save the dataset of the non-missing LSOAs
				preserve
				keep if nonmissinglsoa==1
				save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\impute_missing_lsoa.dta", replace
				restore
			* Restrict to missing LSOAs, then merge in the matched non-missing lsoa
				keep if nonmissinglsoa==0
				keep urn schoolname phase secondary mode mode_temp littlen_lsoamatch
				rename littlen_lsoamatch littlen
				merge m:1 urn mode_temp littlen using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\impute_missing_lsoa.dta", update keepus(id lsoa11cd lsoa11nm)
				drop if _m==2 
				drop _m
			* Combine datasets to give final dataset with all LSOAs imputed
				append using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\impute_missing_lsoa.dta"
				erase "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\impute_missing_lsoa.dta"
				recode nonmissinglsoa .=0
				order id lsoa11cd lsoa11nm mode urn schoolname phase secondary nonmissinglsoa
				keep id - nonmissinglsoa
	
		** IF MODE UNKNOWN, RANDOMLY GIVE ANOTHER PUPIL IN SAME LSOA FLOW
			* Generate number with that mode and non-missing mode
				gen nonmissingmode=(mode!=5)
				bysort id : egen bign=sum(nonmissingmode)
			* Rank within each id
				by id nonmissingmode (mode), sort: gen littlen=_n
			* Generate random position, by mode, to sample from
				gen littlen_modematch=uniform()
				replace littlen_modematch=ceil(littlen_modematch*bign)
			* Save the dataset of the non-missing LSOAs
				preserve
				keep if nonmissingmode==1
				save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\impute_missing_mode.dta", replace
				restore
			* Restrict to missing LSOAs, then merge in the matched non-missing lsoa
				keep if nonmissingmode==0
				keep id lsoa11cd lsoa11nm urn schoolname phase secondary littlen_modematch nonmissinglsoa
				rename littlen_modematch littlen
				merge m:1 id littlen using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\impute_missing_mode.dta", update keepus(mode)
				drop if _m==2 
				drop _m
				ta mode, mi // 6.5% not matched 
			* Combine datasets to give final dataset with all modes imputed
				append using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\impute_missing_mode.dta"
				erase "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\impute_missing_mode.dta"
				recode nonmissingmode .=0
				recode mode .=4 // .01% not matched ... impute as other
				order id lsoa11cd lsoa11nm mode urn schoolname phase secondary nonmissinglsoa nonmissingmode
				ta nonmissinglsoa nonmissingmod, mi cell
				keep id - nonmissingmode

		** RESHAPE BACK TO FLOW LEVEL
			forval i=1/4 {
			gen mode`i'=(mode==`i')
			bysort id: egen numpupils`i'=sum(mode`i')
			}
			keep id lsoa11cd lsoa11nm urn schoolname phase secondary numpupils*
			rename numpupils1 bicycle
			rename numpupils2 foot
			rename numpupils3 car
			rename numpupils4 other
			duplicates drop
			save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\ODpairs_process2.0.dta", replace
*/	
	****************
	** GENERATE AND APPLY PROPENSITY EQUATIONS AT FLOW LEVEL [REDO AFTER NAT BUILD]
	****************
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\ODpairs_process2.0.dta", clear
		* RENAME AND GEN VARS
			rename lsoa11cd geo_code_o
			rename lsoa11nm geo_name_o
			egen all=rowtotal( bicycle foot car other)
			order all, before(bicycle)
		
		* MERGE IN CYCLE STREETS VARIABLES & GEN FLOWTYPE
			merge 1:1 id using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\rfrq_all_data.dta"
				drop if _m==2 // _m=2 are schools excluded from analysis. _m=1 are schools too far from centroids
				recode _m 1=2 3=1, gen (flowtype)
				recode flowtype 1=2 if secondary==0 & rf_dist_km>=5
				recode flowtype 1=2 if secondary==1 & rf_dist_km>=10
				label def flowtypelab 1 "Under max distance" 2 "over max distance", modify
				label val flowtype flowtypelab
				drop _m geo_code1 geo_code2

		* IF DISTANCE OVER MAXIMUM, THEN ASSIGN NATIONAL DISTANCE *AMONG CYCLISTS* TRAVELLING UNDER MIN DISTANCE
			gen cyc_dist_km=rf_dist_km
			forval i=0/1 {
			sum rf_dist_km if flowtype==1 & secondary==`i' [fw=bicycle]
			replace cyc_dist_km=`r(mean)' if flowtype==2 & secondary==`i'
			}

		* SAVE RELEVANT VARIABLES (USE THIS TO FIT INDIVIDUAL MODEL)
			order id geo_code_o - secondary /*
				*/ all-other flowtype /*
				*/ e_dist_km rf_dist_km rf_avslope_perc cyc_dist_km
			keep id-cyc_dist_km
			compress
			saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\ODpairs_process2.1.dta", replace	
			* FIT INDIVIDUAL MODEL FOR ENGLISH AND GO DUTCH/CAMB PARAMS IN '0.2d_NatModelSchoolLSOA_parameterise.do'


		* MODEL FITTING FOR FLOWTYPE 1 TRIPS
			use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\ODpairs_process2.1.dta", clear
				gen rf_dist_kmsq=rf_dist_km^2
				gen rf_dist_kmsqrt=sqrt(rf_dist_km)
				gen ned_rf_avslope_perc=rf_avslope_perc-0.63 
				gen interact=rf_dist_km*ned_rf_avslope_perc
				
				gen pred_base= /*
					*/ -4.813 + (0.9743 * rf_dist_km) + (-0.2401 * rf_dist_kmsq) + (-0.4245 * ned_rf_avslope_perc)
				replace pred_base= /*
					*/ -7.178 + (-1.870 * rf_dist_km) + (5.961 * rf_dist_kmsqrt) + (-0.5290 * ned_rf_avslope_perc) if secondary==1
				replace pred_base=. if flowtype==2
								
				gen bcambridge = 2.334 + (0.2789 * rf_dist_km)
				replace bcambridge = 3.049 if secondary==1 
				gen pred_cambridge= pred_base + bcambridge

				gen bdutch = 3.642
				replace bdutch = 3.574 + (0.3438 * rf_dist_km) if secondary==1 
				gen pred_dutch= pred_base + bdutch
				
				foreach x in base cambridge dutch {
				replace pred_`x'=exp(pred_`x')/(1+exp(pred_`x'))
				}
				drop rf_dist_kmsq rf_dist_kmsqrt ned_rf_avslope_perc interact bcambridge bdutch
		
				/* FIGURE 1
					gen pcycle=bicycle/all
					gen rf_dist_kmcat=floor(rf_dist_km*2)/2
					recode rf_dist_kmcat 12/max=12
					gen rf_avslope_perccat=floor(rf_avslope_perc*4)/4
					recode rf_avslope_perccat 0=0.25 5/max=5
					table rf_dist_kmcat if secondary==0 & flowtype==1 [fw=all], c(mean pcycle mean pred_base mean pred_dutch)
					table rf_avslope_perccat if secondary==0 & flowtype==1 [fw=all], c(mean pcycle mean pred_base mean pred_dutch)
					table rf_dist_kmcat if secondary==1 & flowtype==1 [fw=all], c(mean pcycle mean pred_base mean pred_dutch)
					table rf_avslope_perccat if secondary==1 & flowtype==1 [fw=all], c(mean pcycle mean pred_base mean pred_dutch)
					drop pcycle		
								
				** NUMBER FOR APPENDIX TEXT: GO DUTCH EST TRIPS 2KM
					table secondary if flowtype==1 & rf_dist_km>=2 & rf_dist_km<3 [fw=all], c(mean pred_dutch)
				
				** NUMBER FOR TEXT: AVERAGE DISTANCES
					recode rf_dist_km .=35, gen(rf_dist_kmlimit)
					sum rf_dist_kmlimit if secondary==0 [fw=all], det
					sum rf_dist_kmlimit if secondary==1 [fw=all], det
					ta flowtype [fw=bicycle]
					ta flowtype [fw=foot]
					ta flowtype [fw=car]
					ta flowtype [fw=other]
					total rf_dist_kmlimit [fw=car]
					total rf_dist_kmlimit if flowtype==2 [fw=car]
				*/
					
	****************
	** APPLY SCENARIOS TO OD DATA, INC MODE SHIFT
	*****************
		** CALCULATE NO. CYCLISTS IN EACH SCENARIO
			gen nocyclists_slc=0
			gen nocyclists_sic=nocyclists_slc-bicycle
		
			gen govtarget_slc=bicycle+(pred_base*all)
			replace govtarget_slc=all if govtarget_slc>all & govtarget_slc!=. // MAXIMUM PERCENT CYCLISTS IS 100%
			gen govtarget_sic=govtarget_slc-bicycle
			order govtarget_slc, before(govtarget_sic)

			foreach x in cambridge dutch {
			gen `x'_slc=pred_`x'*all
			replace `x'_slc=all if `x'_slc>all & `x'_slc!=. // MAXIMUM PERCENT CYCLISTS IS 100%
			replace `x'_slc=bicycle if `x'_slc<bicycle 		 // MINIMUM NO. CYCLISTS IS BASELINE
			gen `x'_sic=`x'_slc-bicycle
			}
			foreach x in govtarget cambridge dutch {
			replace `x'_slc=bicycle if flowtype==2	// NO INCREASE AMONG FLOWS OUT OF SCOPE AS TOO LONG
			replace `x'_sic=0 if flowtype==2
			}
	
		** CALCULATE % NON-CYCLISTS MADE CYCLISTS IN EACH SCENARIO: TURN THAT % AWAY FROM WALKING
			foreach x in nocyclists {
			gen pchange_`x'=(all-`x'_slc)/(all-bicycle) 
				/*	
					gen pcycle=bicycle/all
					gen pfoot=foot/all
					gen pcar=car/all
					gen pother=other/all
					count if pcycle==1 // no. OD pairs 50%-99%
					count if pcycle>0.5 & pcycle<1 // no. OD pairs 50%-99%
					sum pfoot pcar pother pcycle if pcycle>0.5 & pcycle<1 [fw=all]
					disp 0.171/(1-0.6508)	// 49% NON-CYCLE FLOWS WALKING IN HIGH CYCLE AREAS
					disp 0.108/(1-0.6508)	// 31% NON-CYCLE FLOWS DRIVING IN HIGH CYCLE AREAS
					disp 0.0703/(1-0.6508)	// 20% NON-CYCLE FLOWS OTHER IN HIGH CYCLE AREAS
					*/	
			gen `x'_slw=foot*pchange_`x'					// most flows - scale walking according to %change
			replace `x'_slw=((all-`x'_slc)*0.49) if bicycle==all	// Flows with pure bicycles at baseline - make walking 13% of new flows
			gen `x'_siw=`x'_slw-foot
			gen `x'_sld=car*pchange_`x'			
			replace `x'_sld=((all-`x'_slc)*0.31) if bicycle==all	// Flows with pure bicycles at baseline - make driving 44% of new flows
			gen `x'_sid=`x'_sld-car	
			order `x'_slw `x'_siw `x'_sld `x'_sid, after(`x'_sic)
			}
			
			foreach x in govtarget cambridge dutch {
			gen pchange_`x'=(all-`x'_slc)/(all-bicycle) 	// % change in non-cycle modes
			recode pchange_`x' .=1 if all==bicycle 			// make 1 (i.e. no change) if everyone in the flow cycles
			gen `x'_slw=foot*pchange_`x'
			gen `x'_siw=`x'_slw-foot
			gen `x'_sld=car*pchange_`x'
			gen `x'_sid=`x'_sld-car
			order `x'_slw `x'_siw `x'_sld `x'_sid, after(`x'_sic)
			}
		
			compress
			drop pred_base pred_cambridge pred_dutch 
			drop pchange_nocyclists pchange_govtarget pchange_cambridge pchange_dutch

	*****************
	** ESTIMATE CHANGE IN MET HOURS
	*****************
		* INPUT PARAMETERS FROM NTS
			gen cycleeduc_cycletripsperweek = 2.3						// primary school: cycle trips/week if usual main mode cycling
			replace cycleeduc_cycletripsperweek = 5.1 if secondary==1	// secondary school	
			gen cycleeduc_walktripsperweek = 3.1						// walk trips if cycle usual main mode
			replace cycleeduc_walktripsperweek = 1.2 if secondary==1		
			gen walkeduc_cycletripsperweek = 0.04						
			replace walkeduc_cycletripsperweek = 0.07 if secondary==1	
			gen walkeduc_walktripsperweek = 5.2						
			replace walkeduc_walktripsperweek = 5.3 if secondary==1	
			gen carothereduc_cycletripsperweek = 0.01						
			replace carothereduc_cycletripsperweek = 0.03 if secondary==1	
			gen carothereduc_walktripsperweek = 0.51						
			replace carothereduc_walktripsperweek = 0.35 if secondary==1	
			
			gen cspeed = 6.6	
			replace cspeed = 9.6 if secondary==1	
			gen wspeed = 3.8
			replace wspeed = 4.0 if secondary==1
			
		* INPUT PARAMETERS ON METS
				* http://nccor.org/tools-youthcompendium/met-view-all-categories/
				* cycling = code 25140X; walking = code 80180X 
			gen cmmets = 4.6 - 1			
			replace cmmets = 5.8 - 1 if secondary==1
			gen wmmets = 3.3 - 1
			replace wmmets = 3.6 - 1 if secondary==1
			
		* MMET HOURS OF CYCLING/WALKING IN HOURS PER PERSON PER WEEK , AMONG THOSE SWITCHED TO CYCLING
			gen cdur_trip = (cyc_dist_km/cspeed) // HOURS CYCLING PER WEEK AMONG NEW CYCLISTS IN A FLOW		
			gen cmmets_week=cmmets * cycleeduc_cycletripsperweek * cdur_trip
			gen wdur_trip = (cyc_dist_km/wspeed) // HOURS WALKING PER WEEK AMONG THOSE NOW SWITCHING TO CYCLING IN A FLOW
			gen wmmets_week=wmmets * cycleeduc_cycletripsperweek * wdur_trip	
					
		* CALCULATE BASELINE AMOUNT OF AT IN FLOW [need to add in for car/other]
			gen baseline_at_mmet= /*
				*/ (bicycle * cmmets * cycleeduc_cycletripsperweek * cdur_trip) + /*
				*/ (bicycle * wmmets * cycleeduc_walktripsperweek * wdur_trip) + /*
				*/ (foot * cmmets * walkeduc_cycletripsperweek * cdur_trip) + /*
				*/ (foot * wmmets * walkeduc_walktripsperweek * wdur_trip) + /*
				*/ ((car+other) * cmmets * carothereduc_cycletripsperweek * cdur_trip) + /*
				*/ ((car+other) * wmmets * carothereduc_walktripsperweek * wdur_trip)

		* CALCULATE CHANGE AT FLOW LEVEL IN METS PER WEEK
			foreach x in nocyclists govtarget cambridge dutch {
			gen `x'_sic_mmet=`x'_sic*cmmets_week
			gen `x'_siw_mmet=`x'_siw*wmmets_week
			gen `x'_simmet=`x'_sic_mmet+`x'_siw_mmet
			drop `x'_sic_mmet `x'_siw_mmet
			}
	
			gen base_slmmet=-1*nocyclists_simmet	// BASELINE LEVEL IS INVERSE OF 'NO CYCLISTS' SCENARIO INCREASE
			foreach x in govtarget cambridge dutch {
			gen `x'_slmmet=`x'_simmet+base_slmmet
			order `x'_simmet , after(`x'_slmmet)
			}
		
		* CHANGE FROM TOTAL METS TO *AVERAGE* METS PER *CHILD*
			* remove this part if go for flow-level total, rather than an average - ditto change when aggregate to be total not average in zone/destination			
			replace baseline_at_mmet=baseline_at_mmet/all
			replace base_slmmet=base_slmmet/all
			foreach x in govtarget cambridge dutch {
			foreach y in slmmet simmet {
			replace `x'_`y' = `x'_`y'/all
			}
			}
			
		/* NUMBER IN MAIN TEXT: CALCULATE % CHILDREN GETTING HALF PA FROM SCHOOL AT
			gen met_if_bicycle=(cmmets * cycleeduc_cycletripsperweek * cdur_trip)+(wmmets * cycleeduc_walktripsperweek * wdur_trip)
			gen met_if_walk=(cmmets * walkeduc_cycletripsperweek * cdur_trip)+(wmmets * walkeduc_walktripsperweek * wdur_trip)
			recode met_if_bicycle min/6.9999999=0 7/max=1 // make binary - get half or not?
			recode met_if_walk min/6.9999999=0 7/max=1
			gen base_numchild_palevel=(met_if_bicycle*bicycle) + (met_if_walk*foot) // what N. children are getting half in each flow?
			gen govtarget_numchild_palevel=(met_if_bicycle*govtarget_slc) + (met_if_walk*govtarget_slw)
			gen dutch_numchild_palevel=(met_if_bicycle*dutch_slc) + (met_if_walk*dutch_slw)
			total base_numchild_palevel govtarget_numchild_palevel dutch_numchild_palevel all
				di 593617/74425.32
				di 630599.7/74425.32
				di 1569469/74425.32
			total base_numchild_palevel govtarget_numchild_palevel dutch_numchild_palevel all if secondary==0
				di 149543/41887.69
				di 153595.1/41887.69
				di 254897.8/41887.69
			total base_numchild_palevel govtarget_numchild_palevel dutch_numchild_palevel all if secondary==1
				di 444074/32537.63
				di 477004.6/32537.63
				di 1314572/32537.63
			drop met_if_bicycle met_if_walk base_numchild_palevel govtarget_numchild_palevel dutch_numchild_palevel
			*/
		
		* DROP INTERMEDIARY VARIABLES
			drop cspeed wspeed cmmets wmmets cdur_trip cmmets_week wdur_trip wmmets_week
			drop nocyclists_simmet 

	*****************
	** DO CO2 EMISSIONS CALCS
	*****************
		* Calculate the average number of education escort car driver trips per child education trips by car.
		* NB this ranges up to a maximum of 2: if an adult drives a single child to school and back then they are making two car trips for each one trip made by the child. But if e.g. they drive the charter school and then go on to work, only the first trip is counted. And if there are several children in the household driven at the same time, the number of adult trips per child is reduced
		gen cardrivertrips_perchildcaruser=1.2
		gen co2kg_km=0.182
				
		foreach x in nocyclists govtarget cambridge dutch {
		gen long `x'_sicartrips = `x'_sid * cycleeduc_cycletripsperweek * cardrivertrips_perchildcaruser * 52.2 	// NO DRIVERS CHANGED * CHILD TRIPS/WEEK * ADULT CAR DRIVER ESCORT TRIPS PER CHILD TRIP 
		gen long `x'_sicarkm = `x'_sid * cycleeduc_cycletripsperweek * cardrivertrips_perchildcaruser * 52.2 * cyc_dist_km  	// NO TRIPS CHANGED * DIST 
		gen long `x'_sico2 = `x'_sicarkm * co2kg_km 	// NO TRIPS CHANGED * DIST * CO2 EMISSIONS FACOTR
		}
		gen base_slcarkm=-1*nocyclists_sicarkm	// BASELINE LEVEL IS INVERSE OF 'NO CYCLISTS' SCENARIO INCREASE
		gen base_slco2=-1*nocyclists_sico2	// BASELINE LEVEL IS INVERSE OF 'NO CYCLISTS' SCENARIO INCREASE
		foreach x in govtarget cambridge dutch {
		gen long `x'_slco2=`x'_sico2+base_slco2
		order `x'_sicartrips `x'_sicarkm , before(`x'_slco2)
		order `x'_sico2, after(`x'_slco2)
		}
		drop nocyclists* cycleeduc_cycletripsperweek- carothereduc_walktripsperweek cardrivertrips_perchildcaruser co2kg_km 
		
		compress
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\ODpairs_process2.5.dta", replace

	*****************
	** AGGREGATE TO ZONE LEVEL
	*****************
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\ODpairs_process2.5.dta", clear
		drop *cartrips
		* AGGREGATE UP AREA FIGURES
			foreach var of varlist all- other govtarget_slc-dutch_sid {
			bysort geo_code_o: egen a_`var'=sum(`var')
			}
			foreach var of varlist baseline_at_mmet base_slmmet - dutch_simmet {
			bysort geo_code_o: egen temp_`var'=sum(`var'*all)
			gen a_`var'=temp_`var'/a_all
			}
			foreach var of varlist base_slcarkm- dutch_sico2 {
			bysort geo_code_o: egen a_`var'=sum(`var')
			}
		* PERCENT TRIPS AND TRIP HILLINESS
			recode rf_dist_km min/4.9999=1 5/max=0, gen(rf_u5km_dist)
			gen all_u5km_dist=all
			replace all_u5km_dist=. if rf_u5km_dist==.
			bysort geo_code_o: egen rf_u5km_dist_numerator=sum(rf_u5km_dist*all_u5km_dist)
			bysort geo_code_o: egen rf_u5km_dist_denominator=sum(all_u5km_dist)
			gen a_perc_rf_dist_u5km = 100*rf_u5km_dist_numerator/rf_u5km_dist_denominator
			
			gen rf_u5km_avslope_perc=rf_avslope_perc
			replace rf_u5km_avslope_perc=. if rf_u5km_dist!=1
			gen all_u5km_avslope=all
			replace all_u5km_avslope=. if rf_u5km_avslope==.
			bysort geo_code_o: egen rf_u5km_avslope_numerator=sum(rf_u5km_avslope_perc*all_u5km_avslope)
			bysort geo_code_o: egen rf_u5km_avslope_denominator=sum(all_u5km_avslope)
			gen a_avslope_perc_u5km = rf_u5km_avslope_numerator/rf_u5km_avslope_denominator
			
		* AREA FILE KEEP/RENAME + MERGE IN NAMES/LA + ORDER
			keep geo_code_o a_*
			rename geo_code_o geo_code
			rename a_* *
			duplicates drop
			merge 1:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lsoa\geo_code_lookup.dta" 
			order geo_code geo_name lad11cd lad_name all 
		
		* DROP WALES, IMPUTE FOR MISSING ENGLAND	
			gen country=substr(geo_code,1,1)
			drop if country=="W" // don't show results for Wales, though a few border areas do contribute some kids
			foreach var of varlist all - dutch_sico2 {
			recode `var' .=0 if _m==2
			}
			drop country _m
		* SAVE FULL VERSION
			export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\z_all_attributes_private_unrounded.csv", replace

		
	*****************
	** AGGREGATE TO SCHOOL LEVEL
	*****************
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\ODpairs_process2.5.dta", clear
		drop *cartrips
		* AGGREGATE UP AREA FIGURES
			foreach var of varlist all- other govtarget_slc-dutch_sid {
			bysort urn: egen a_`var'=sum(`var')
			}
			foreach var of varlist baseline_at_mmet base_slmmet - dutch_simmet {
			bysort urn: egen temp_`var'=sum(`var'*all)
			gen a_`var'=temp_`var'/a_all
			}
			foreach var of varlist base_slcarkm- dutch_sico2 {
			bysort urn: egen a_`var'=sum(`var')
			}
		* PERCENT TRIPS AND TRIP HILLINESS
			recode rf_dist_km min/4.9999=1 5/max=0, gen(rf_u5km_dist)
			gen all_u5km_dist=all
			replace all_u5km_dist=. if rf_u5km_dist==.
			bysort urn: egen rf_u5km_dist_numerator=sum(rf_u5km_dist*all_u5km_dist)
			bysort urn: egen rf_u5km_dist_denominator=sum(all_u5km_dist)
			gen a_perc_rf_dist_u5km = 100*rf_u5km_dist_numerator/rf_u5km_dist_denominator
			
			gen rf_u5km_avslope_perc=rf_avslope_perc
			replace rf_u5km_avslope_perc=. if rf_u5km_dist!=1
			gen all_u5km_avslope=all
			replace all_u5km_avslope=. if rf_u5km_avslope==.
			bysort urn: egen rf_u5km_avslope_numerator=sum(rf_u5km_avslope_perc*all_u5km_avslope)
			bysort urn: egen rf_u5km_avslope_denominator=sum(all_u5km_avslope)
			gen a_avslope_perc_u5km = rf_u5km_avslope_numerator/rf_u5km_avslope_denominator
			
		* AREA FILE KEEP/RENAME 
			keep urn schoolname phase secondary a_*
			rename a_* *
			duplicates drop
			
		* MERGE IN GEOGRAPHY
			merge 1:1 urn using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\lookup_urn_lsoa11.dta"
			drop if _m==2 // excluded schools
			drop _m
			gen geo_code=lsoa11cd
			merge m:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lsoa\geo_code_lookup.dta" 
			drop if _m==2 // LSOAs with no school
			drop _m
			gen lsoa11nm = geo_name
			order urn schoolname phase secondary lsoa11cd lsoa11nm lad11cd lad_name
			drop geo_code geo_name
		* SAVE FULL VERSION
			export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\d_all_attributes_private_unrounded.csv", replace

			
	*****************
	** SAVE SDC-COMPLIANT PUBLIC VERSION FOR SCHOOL AND ZONE
	*****************
		foreach layer in z d {
			import delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\\`layer'_all_attributes_private_unrounded.csv", clear
			* SET SMALL CELL LIMITS
				gen zmax=2 // 'local results' = suppress if <=2, 0 allowed
				gen dmax=5 // 'school results' = suppress if <=5, 0 allowed
			* AVERAGE SMALL CELL VALUES, FOR IMPUTING...ALL ARE CLOSE TO 1.5 FOR z, SO JUST USE THAT
				foreach x in all bicycle foot car {
				sum `x' if (`x'>0 & `x'<=`layer'max)
				}
				gen zimpute=1.5 // NB all ARE CLOSE TO 1.5 FOR z, SO JUST USE THAT
				gen dimpute=3
			* IDENTIFY SMALL CELLS
				gen sdcflag_c=(bicycle>0 & bicycle<=`layer'max)
				gen sdcflag_w=(foot>0 & foot<=`layer'max)
				gen sdcflag_d=(car>0 & car<=`layer'max)		
			* SUPPRESS SMALL CELLS FOR PUBLIC VERSION
				replace all=. if (all>0 & all<=`layer'max) // NB if size of zone is 2 & those were different modes, could work that the true no. was all=2 out...but actually only 1 zone has all=2 [E01033656] and it has just 1 mode
				replace bicycle=. if sdcflag_c==1
				replace foot=. if sdcflag_w==1
				replace car=. if sdcflag_d==1
				foreach y in c w d {
				foreach x in govtarget cambridge dutch {
				replace `x'_sl`y'=. if sdcflag_`y'==1
				}
				}
				drop zmax dmax sdcflag*
				export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\\`layer'_all_attributes_unrounded.csv", replace
		}
			
	*****************
	** AGGREGATE TO LA & PCT REGION LEVEL BY WHERE CHILDREN LIVE
	*****************
	** LA
		import delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\z_all_attributes_private_unrounded.csv", clear
		* AGGREGATE
			foreach var of varlist all- other govtarget_slc-dutch_sid {
			bysort lad11cd: egen a_`var'=sum(`var')
			}
			foreach var of varlist baseline_at_mmet govtarget_slmmet- dutch_simmet {
			bysort lad11cd: egen temp_`var'=sum(`var'*all)
			gen a_`var'=temp_`var'/a_all
			}
			foreach var of varlist base_slcarkm- dutch_sico2 {
			bysort lad11cd: egen a_`var'=sum(`var')
			}		
			foreach var of varlist perc_rf_dist_u5km avslope_perc_u5km {
			bysort lad11cd: egen temp_`var'=sum(`var'*all)
			gen a_`var'=temp_`var'/a_all
			}
			keep lad11cd lad_name a_*
			rename a_* *
			duplicates drop
		* CHANGE UNITS
			foreach x in base_sl govtarget_si dutch_si {
			replace `x'carkm=`x'carkm/1000	// convert to thousands km
			replace `x'co2=`x'co2/1000	// convert to tonnes
			}
		export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lad_all_attributes_unrounded.csv", replace
	** REGION
		import delimited "pct-inputs\01_raw\01_geographies\pct_regions\pct_regions_lad_lookup.csv", varnames(1) clear 
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\pct_regions_lad_lookup.dta", replace
		import delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lad_all_attributes_unrounded.csv", clear
		merge 1:1 lad11cd using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\pct_regions_lad_lookup.dta", keepus(region_name) nogen
		* AGGREGATE
			foreach var of varlist all- other govtarget_slc- dutch_sico2 {
			bysort region_name: egen a_`var'=sum(`var')
			}
			keep region_name a_*
			rename a_* *
			duplicates drop
		* PERCENTAGES FOR INTERFACE
			foreach var of varlist bicycle govtarget_slc cambridge_slc dutch_slc {
			gen `var'_perc=round(`var'*100/all, 1)
			order `var'_perc, after(`var')
			}
			keep region_name *perc
			list if bicycle_perc==. 
			drop if bicycle_perc==. // Wales
		export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\pct_regions_all_attributes.csv", replace
x
	*****************
	** FILE FOR 1) RNET and 2) RASTER WITH NUMBERS ROUNDED (BUT CORRECT TOTALS MAINTAINED), AND NO FILTERING OF LINES <3
	*****************			
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\ODpairs_process2.5.dta", clear
		
		* SUBSET BY DISTANCE AND TO SCENARIO VARIABLES
			keep if flowtype==1
			order id geo_code_o urn all bicycle *_slc
			keep id - dutch_slc
			export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\school\lsoa\rnet_all_attributes.csv", replace
			
		* RASTER
			keep id bicycle *_slc	
			set seed 20170121
			gen random=uniform()
			foreach var of varlist govtarget_slc cambridge_slc dutch_slc {
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
			egen sumcycle=rowtotal(bicycle govtarget_slc cambridge_slc dutch_slc)
			drop if sumcycle==0
			keep id bicycle govtarget_slc cambridge_slc dutch_slc
			sort id
			export delimited using "pct-inputs\02_intermediate\02_travel_data\school\lsoa\od_raster_attributes.csv", replace
