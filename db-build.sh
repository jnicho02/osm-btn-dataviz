#CITY="brighton-and-hove"
CITY="manchester"
if [[ $CITY = "brighton-and-hove" ]]
then
  COUNTY="west-sussex"
else
  COUNTY="greater-manchester"
fi
filename="$COUNTY-$(date +'%Y-%m-%d').osm.pbf"
echo $filename
if [ -e $filename ]
then
    echo "${COUNTY} file already downloaded today"
else
  rm -f $COUNTY-*.osm.pbf
  curl https://download.geofabrik.de/europe/great-britain/england/$COUNTY-latest.osm.pbf > $filename
  dropdb osm-$CITY
  createdb osm-$CITY
  psql -d osm-$CITY -c 'CREATE EXTENSION postgis; CREATE EXTENSION hstore;'
  osm2pgsql -l --hstore --number-processes 4 --multi-geometry --keep-coastlines -d osm-$CITY $filename

  if [[ $CITY = "brighton-and-hove" ]]
  then
    IN_THE_CITY="( \
    ST_INTERSECTS(osm.way, (SELECT pol.way FROM planet_osm_polygon pol WHERE osm_id='-114085')) \
      OR \
    ST_INTERSECTS(osm.way, (SELECT pol.way FROM planet_osm_polygon pol WHERE osm_id='3451897')) \
    )"
  else
    IN_THE_CITY="( \
    ST_INTERSECTS(osm.way, (SELECT pol.way FROM planet_osm_polygon pol WHERE osm_id='-146656')) \
    )"
  fi
  echo delete non-city data from osm-$CITY
  # delete anything not in the city, although things can extend out of it)
  psql -d osm-$CITY -c "DELETE FROM planet_osm_line osm WHERE not ${IN_THE_CITY};"
  psql -d osm-$CITY -c "DELETE FROM planet_osm_point osm WHERE not ${IN_THE_CITY};"
  psql -d osm-$CITY -c "DELETE FROM planet_osm_polygon osm WHERE not ${IN_THE_CITY};"
  psql -d osm-$CITY -c "DELETE FROM planet_osm_roads osm WHERE not ${IN_THE_CITY};"
  psql -d osm-$CITY -c "DELETE FROM planet_osm_line osm WHERE osm.boundary IS NOT NULL;"
  psql -d osm-$CITY -c "DELETE FROM planet_osm_polygon osm WHERE osm.boundary IS NOT NULL;"
fi

BASEDIR="$( cd "$( dirname "$0" )" && pwd )"
# ST_AsText(way) as wkt,
COLUMNS="osm_id,
ST_X(ST_CENTROID(way)) as longitude, ST_Y(ST_CENTROID(way)) as latitude,
'${CITY}' as city,
access,
\"addr:housename\" as addr_housename, \"addr:housenumber\" as addr_housenumber, \"addr:interpolation\" as addr_interpolation,
tags->'addr:postcode' as postcode,
admin_level, aerialway, aeroway, amenity, area,
barrier, bicycle, brand, bridge, boundary, building,
construction, covered, culvert, cutting,
tags->'cuisine' as cuisine,
denomination, disused,
embankment,
foot,
substring(tags->'fhrs:id' from '\d*') as fhrs_id,
\"generator:source\" as generator_source,
harbour, highway, historic, horse,
intermittent,
junction,
landuse, layer, leisure, lock,
man_made, military, motorcar,
name, \"natural\" as natural,
office, oneway, operator,
place, population, power, power_source, public_transport,
railway, ref, religion, route,
service, shop, sport, surface,
toll, tourism, \"tower:type\" as tower_type, tunnel,
water, waterway, wetland, width, wood,
z_order,
tags"

# tracktype, way_area, way

COPYSELECT="COPY (
    SELECT 'point' AS source,
    'https://www.openstreetmap.org/node/'||osm_id AS aaa_uri,
    ${COLUMNS} FROM planet_osm_point
  UNION
    SELECT 'polygon centroid' AS source,
    'https://www.openstreetmap.org/way/'||osm_id AS aaa_uri,
    ${COLUMNS} FROM planet_osm_polygon
  UNION
    SELECT 'line centroid' AS source,
    'https://www.openstreetmap.org/way/'||osm_id AS aaa_uri,
    ${COLUMNS} FROM planet_osm_line
  )
  TO '${BASEDIR}/osm-${CITY}.csv' DELIMITER ',' CSV HEADER;"
psql -d osm-$CITY -c "${COPYSELECT}"
