# Propensity to Cycle Tool - data loading

This repository generates data hosted in [pct-data](https://github.com/npct/pct-data).

It was originally cloned from [pct](https://github.com/npct/pct).

The main script on this repo is [load.Rmd](https://github.com/npct/pct-load/blob/master/load.Rmd).
This script runs the R code contained within while creating a summary of the data generating process.
It even reports summary statistics from the data as it is created.

To run `load.Rmd` you should be able to simply hit 'Knit HTML' while loaded RStudio.
There are other dependencies, listed below.

**Note: `rq.Rds` and `rf.Rds` must be downloaded from here before the build: https://github.com/npct/pct-bigdata/releases **

## Relationship to other pct- folders

The purpose of this repo is to build the data used by [pct-shiny](https://github.com/npct/pct-shiny).
To do this it creates new folders and creates files in [pct-data](https://github.com/npct/pct-data).
It relies on open data hosted on [pct-bigdata](https://github.com/npct/pct-bigdata/).

**Each of the these folder should be 'siblings' in the same folder.**
All of the folders needed to run the Propensity to Cycle Tool, and modify the input data it uses (e.g. to create new scenarios), can be created with the following shell commands:


```bash
# clone the pct data creation scripts
git clone git@github.com:npct/pct-load.git 

# clone the data (warning - large)
git clone git@github.com:npct/pct-data.git --depth 1

# clone the shiny online visualisation framework
git clone git@github.com:npct/pct-shiny.git 

# clone the national level input data
git clone git@github.com:npct/pct-bigdata.git --depth 1
```

The other dependencies are described below.
If you have issues with any of these, please report them as an [issue](https://github.com/npct/pct-load/issues).

## Set the `CS_API_KEY` Environment variable

Some of the examples pull data from the
[CycleStreets.net API](http://www.cyclestreets.net/api/).
Once you have a token, you can add it to R by
adding the following line
to your `.Renviron` file in your home directory:


```bash
CYCLESTREET=xxx
```

where `xxx` is the api key.

If the file does not yet exist, you can create it.
This can also be made available to other programs,
a session variable using the following in your terminal (tested in Ubuntu):


```bash
echo "export CS_API_KEY='my_token'" >> ~/.profile
```

or system wide variable


```bash
sudo echo "export CS_API_KEY='my_token'" > /etc/profile.d/cyclestreet.sh
```

## Set up rgdal

The version of gdal needs to be newer than 1.11

```r
rgdal::getGDALVersionInfo()
```

```
## [1] "GDAL 1.11.2, released 2015/02/10"
```

```r
# Should return GDAL 1.11.2, released 2015/02/10 (or newer)
```

It is possible to use the following Personal Package Archive (PPA) to get the latest version of gdal on Ubuntu.


```bash
sudo add-apt-repository ppa:ubuntugis/ubuntugis-unstable && sudo apt-get update
sudo apt-get install gdal-bin libgdal-dev
```


### WIndows Install

Does not install easily on windows 

Stplanr requires

chron, RJSONIO, bitops,  R.oo, R.methodss3, installr, 
