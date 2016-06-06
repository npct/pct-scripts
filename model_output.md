---
title: "National Propensity to Cycle Tool - local results"
author: "Created by the NPCT team"
output:
  html_document:
    fig_caption: yes
    highlight: pygments
    theme: null
    toc: yes
---



## Key information 
This document provides more information about the data underlying the Propensity to Cycle Tool (PCT) for Isle-of-wight. The data was generated on 2016-06-03 and this document was created on 2016-06-03. The PCT is an open source tool for sustainable transport planning, released under the conditions of the [AGPL Licence](https://www.gnu.org/licenses/agpl-3.0).Both the [pct](https://github.com/npct/pct) and [pct-shiny](https://github.com/npct/pct-shiny) can be modified by others given attribution to the original.

This version of the PCT uses origin-destination (OD) data on travel to work from the 2011 Census. The dataset reports the number of people travelling by different modes from Middle Super Output Area ([MSOA](https://data.gov.uk/dataset/middle-layer-super-output-areas-2001-to-middle-layer-super-output-areas-2011-to-local-authority)) zones. There were
52,278 thousand
commuters in the study area from this data source.
All of these are represented in the area data produced by the PCT.  

Lines on the interactive map  represent flows between zones in Isle-of-wight. This excludes
within-zone travel (18% of commutes in Isle-of-wight), commuters travelling outside Isle-of-wight and people with no fixed place of work. 

 Within Isle-of-wight there are 0.143 between-zone OD pairs. Of these, 97% are represented as lines on the interactive map. The selection criteria used for this were (i) distance of less than 
20km and (ii) more than 10 (by any mode).
 
 The resultant 139 desire lines account for 61% of all commuters in Isle-of-wight and
100%
of between-zone commutes taking place within Isle-of-wight.

## Scenario cycling by distance

The graph and table below illustrate the % of cyclists in each scenario by each distance band.

![Rate of cycling in model scenarios. Note the total percentage cycling is equal to the area under each line.](figure/unnamed-chunk-2-1.png)

```
## NULL
```

<table>
<caption>Summary statistics of the rate of cycling by distance bands (percentages) and the total number of cycle trips per for each scenario (far right column). The first row of data provides summary statistics (e.g. % trips by each distance band) for all modes. The subsequent rows report data on cycling only.</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> Scenario </th>
   <th style="text-align:right;"> |  0 - 2 km </th>
   <th style="text-align:right;"> |  2 - 5 km </th>
   <th style="text-align:right;"> |  5 - 10 km </th>
   <th style="text-align:right;"> |  10 + km </th>
   <th style="text-align:right;"> |  N. trips/day </th>
   <th style="text-align:right;"> |  % trips cycled </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> All modes </td>
   <td style="text-align:right;"> 16.1 </td>
   <td style="text-align:right;"> 11.0 </td>
   <td style="text-align:right;"> 27.9 </td>
   <td style="text-align:right;"> 45.1 </td>
   <td style="text-align:right;"> 32071 </td>
   <td style="text-align:right;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Ebikes </td>
   <td style="text-align:right;"> 25.1 </td>
   <td style="text-align:right;"> 18.0 </td>
   <td style="text-align:right;"> 32.5 </td>
   <td style="text-align:right;"> 24.5 </td>
   <td style="text-align:right;"> 8110 </td>
   <td style="text-align:right;"> 25.3 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Go Dutch </td>
   <td style="text-align:right;"> 32.2 </td>
   <td style="text-align:right;"> 22.7 </td>
   <td style="text-align:right;"> 29.8 </td>
   <td style="text-align:right;"> 15.2 </td>
   <td style="text-align:right;"> 4544 </td>
   <td style="text-align:right;"> 14.2 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Gender Equality </td>
   <td style="text-align:right;"> 25.5 </td>
   <td style="text-align:right;"> 16.6 </td>
   <td style="text-align:right;"> 37.6 </td>
   <td style="text-align:right;"> 20.3 </td>
   <td style="text-align:right;"> 1835 </td>
   <td style="text-align:right;"> 5.7 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Government Target </td>
   <td style="text-align:right;"> 25.4 </td>
   <td style="text-align:right;"> 18.2 </td>
   <td style="text-align:right;"> 35.0 </td>
   <td style="text-align:right;"> 21.4 </td>
   <td style="text-align:right;"> 1765 </td>
   <td style="text-align:right;"> 5.5 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Current (2011) </td>
   <td style="text-align:right;"> 24.9 </td>
   <td style="text-align:right;"> 16.9 </td>
   <td style="text-align:right;"> 37.3 </td>
   <td style="text-align:right;"> 20.9 </td>
   <td style="text-align:right;"> 1056 </td>
   <td style="text-align:right;"> 3.3 </td>
  </tr>
</tbody>
</table>

## Zone information

In Isle-of-wight there are 18, compared with 6791 in England. The median area of zones is 1582 ha, compared with 300 ha across England

![The study region (thick black border), selected zones (grey), the administrative zone region (red line) and local authorities (blue line). The black straight green represents the most intensive commuting OD pairs.](figure/distance-dist-1.png)

The average hilliness of zones in Isle-of-wight is
NA
percent.

![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-1.png)
## Distance distributions

The distance distribution of trips in  Isle-of-wight is displayed in the figure below, which compares the result with the distribution of trips nationwide.

![Distance distribution of all trips in study lines (blue) compared with national average (dotted bars)](figure/unnamed-chunk-5-1.png)

From the nationwide sample of trips, 51.5% of trips are less than 5km.

In the case study area 27% of sampled trips are less than 5km.

## The flow model

To estimate the potential rate of cycling under different scenarios
regression models operating at the flow level are used.
These can be seen in the model script which is available
[online](https://github.com/npct/pct/blob/master/models/aggregate-model.R).

## Cycling in the study area

The overall rate of cycling in the OD pairs in the study area
(after subsetting for distance) is 3.3%, compared a
rate from the national data (of equally short OD pairs)
of 5.0%.

## Scenarios

![Illustration of OD pairs on travel network](figure/unnamed-chunk-6-1.png)

## Health impacts - NEEDS table

A modified
version of the 2014 [HEAT tool](http://www.euro.who.int/en/health-topics/environment-and-health/Transport-and-health/publications/2011/health-economic-assessment-tools-heat-for-walking-and-for-cycling.-methodology-and-user-guide.-economic-assessment-of-transport-infrastructure-and-policies.-2014-update)
was used.

The table below illustrates the health impacts of the different scenarios, including changes in lives lost and health economic benefits.

## CO2 emissions - NEEDS table

To calculate changes in CO2 emissions we used estimates of the reductions in driving that would result from each scenario.

The table below illustrates the estimated CO2 impacts of the different scenarios.
