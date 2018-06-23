COUNTRY="england"
# COUNTRY="scotland"
# COUNTRY="wales"

filename="$COUNTRY-$(date +'%Y-%m-%d').osm.pbf"
echo $filename
if [ -e $filename ]
then
    echo "${COUNTRY} file already downloaded today"
else
  rm -f $COUNTRY-*.osm.pbf
  curl https://download.geofabrik.de/europe/great-britain/$COUNTRY-latest.osm.pbf > $filename
  dropdb osm-$COUNTRY
  createdb osm-$COUNTRY
  psql -d osm-$COUNTRY -c 'CREATE EXTENSION postgis; CREATE EXTENSION hstore;'
  osm2pgsql -s -l --hstore --number-processes 4 --multi-geometry --keep-coastlines -d osm-$COUNTRY $filename
fi

select name,
  osm_id,
  ST_X(ST_CENTROID(way)) as longitude,
  ST_Y(ST_CENTROID(way)) as latitude,
  "addr:housename" as addr_housename,
  "addr:housenumber" as addr_housenumber,
  "addr:interpolation" as addr_interpolation,
  tags->'addr:postcode' as postcode
  from planet_osm_point
  where amenity='pub'
   and name like '%reyhoun%'
UNION
select name,
  osm_id,
  ST_X(ST_CENTROID(way)) as longitude,
  ST_Y(ST_CENTROID(way)) as latitude,
  "addr:housename" as addr_housename,
  "addr:housenumber" as addr_housenumber,
  "addr:interpolation" as addr_interpolation,
  tags->'addr:postcode' as postcode
  from planet_osm_polygon
  where amenity='pub'
   and name like '%reyhoun%'
