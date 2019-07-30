# gdaldem color-relief school_bicycle_all_10.tif -nearest_color_entry -alpha colour.txt school_bicycle_all_10-coloured.tif
# gdalwarp -co TILED=YES -co COMPRESS=DEFLATE -t_srs EPSG:3857 school_bicycle_all_10-coloured.tif school_bicycle.tif
gdal2tiles.py school_bicycle.tif -z 5-15  --processes 8 school_bicycle  --resume
# ...
# gdaldem color-relief school_govtarget_slc_all_10.tif -nearest_color_entry -alpha colour.txt school_govtarget_slc_all_10-coloured.tif
# gdalwarp -co TILED=YES -co COMPRESS=DEFLATE -t_srs EPSG:3857 school_govtarget_slc_all_10-coloured.tif school_govtarget_slc.tif
gdal2tiles.py school_govtarget_slc.tif -z 5-15  --processes 8 school_govtarget_slc  --resume
# ...
# gdaldem color-relief school_cambridge_slc_all_10.tif -nearest_color_entry -alpha colour.txt school_cambridge_slc_all_10-coloured.tif
# gdalwarp -co TILED=YES -co COMPRESS=DEFLATE -t_srs EPSG:3857 school_cambridge_slc_all_10-coloured.tif school_cambridge_slc.tif
gdal2tiles.py school_cambridge_slc.tif -z 5-15  --processes 8 school_cambridge_slc  --resume
# ...
# gdaldem color-relief school_dutch_slc_all_10.tif -nearest_color_entry -alpha colour.txt school_dutch_slc_all_10-coloured.tif
# gdalwarp -co TILED=YES -co COMPRESS=DEFLATE -t_srs EPSG:3857 school_dutch_slc_all_10-coloured.tif school_dutch_slc.tif
gdal2tiles.py school_dutch_slc.tif -z 5-15  --processes 8 school_dutch_slc  --resume