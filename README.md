# Welcome to pct-scripts

This repo contains the scripts needed to generate the input data for the Propensity to Cycle Tool.

To access it download the associated .zip or clone it as follows:

```bash
# clone the pct data creation scripts
git clone git@github.com:npct/pct-scripts.git 
```

To download the data it produces, install git lfs from [GitHub](https://git-lfs.github.com/) and run the following lines of code from an appropriate shell (e.g. bash on Linux or Windows Powershell):

```bash
git lfs install # check lfs is working
# clone the data (warning - large)
git clone git@github.com:npct/pct-inputs.git # raw input files
git clone git@github.com:npct/pct-outputs-national.git # national outputs
git clone git@github.com:npct/pct-outputs-regional-R.git # regional outputs used by pct-shiny
```

The contents of the regional outputs are used by the code in pct-shiny, which can be downloaded with:

```bash
git clone git@github.com:npct/pct-shiny.git 
```
