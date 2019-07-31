
# wget https://github.com/OSGeo/gdal/raw/master/gdal/docker/ubuntu-full/Dockerfile
# 
# wget https://github.com/npct/pct-scripts/releases/download/0.0.2/school_cambridge_slc.tif
# wget https://github.com/npct/pct-scripts/releases/download/0.0.2/school_govtarget_slc.tif
# wget https://github.com/npct/pct-scripts/releases/download/0.0.2/school_dutch_slc.tif
# wget https://github.com/npct/pct-scripts/releases/download/0.0.2/school_bicycle.tif
# docker run --rm -v $(pwd):/home osgeo/gdal:ubuntu-full-latest gdalinfo /home/school_cambridge_slc.tif
docker run --rm -it -v $(pwd):/home osgeo/gdal:ubuntu-full-latest /bin/bash
cd home

# gdaldem color-relief school_bicycle_all_10.tif -nearest_color_entry -alpha colour.txt school_bicycle_all_10-coloured.tif
# gdalwarp -co TILED=YES -co COMPRESS=DEFLATE -t_srs EPSG:3857 school_bicycle_all_10-coloured.tif school_bicycle.tif
python3 /usr/bin/gdal2tiles.py school_bicycle.tif -z 5-15  --processes 5 school_bicycle  --resume


# ...
# gdaldem color-relief school_govtarget_slc_all_10.tif -nearest_color_entry -alpha colour.txt school_govtarget_slc_all_10-coloured.tif
# gdalwarp -co TILED=YES -co COMPRESS=DEFLATE -t_srs EPSG:3857 school_govtarget_slc_all_10-coloured.tif school_govtarget_slc.tif
# gdal2tiles.py school_govtarget_slc.tif -z 5-15  --processes 4 school_govtarget_slc  --resume
python3 /usr/bin/gdal2tiles.py school_govtarget_slc.tif -z 5-15  --processes 5 school_govtarget_slc  --resume

# ...
# gdaldem color-relief school_cambridge_slc_all_10.tif -nearest_color_entry -alpha colour.txt school_cambridge_slc_all_10-coloured.tif
# gdalwarp -co TILED=YES -co COMPRESS=DEFLATE -t_srs EPSG:3857 school_cambridge_slc_all_10-coloured.tif school_cambridge_slc.tif
# docker run -ti --rm -v $(pwd):/data klokantech/gdal /bin/bash
# ls
python3 /usr/bin/gdal2tiles.py school_cambridge_slc.tif -z 5-15 --processes 5 school_cambridge_slc  --resume

# 
# gdal2tiles.py school_cambridge_slc.tif -z 5-15  school_cambridge_slc  --resume
# ...
# gdaldem color-relief school_dutch_slc_all_10.tif -nearest_color_entry -alpha colour.txt school_dutch_slc_all_10-coloured.tif
# gdalwarp -co TILED=YES -co COMPRESS=DEFLATE -t_srs EPSG:3857 school_dutch_slc_all_10-coloured.tif school_dutch_slc.tif
# gdal2tiles.py school_dutch_slc.tif -z 5-15  --processes 8 school_dutch_slc  --resume

docker run --rm -v ${pwd}:/home osgeo/gdal:ubuntu-full-latest python3 /usr/bin/gdal2tiles.py school_dutch_slc.tif -z 5-15  --processes 5 school_dutch_slc  --resume