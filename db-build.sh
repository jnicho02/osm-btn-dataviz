filename="west-sussex-$(date +'%Y-%m-%d').osm.pbf"
if [ -e $filename ]
then
    echo "file already downloaded today"
else
  rm -f west-sussex-*.osm.pbf
  curl https://download.geofabrik.de/europe/great-britain/england/west-sussex-latest.osm.pbf > $filename
  dropdb osm-btn
  createdb osm-btn
  psql -d osm-btn -c 'CREATE EXTENSION postgis; CREATE EXTENSION hstore;'
  osm2pgsql -l --hstore --number-processes 4 --multi-geometry --keep-coastlines -d osm-btn $filename

  IN_BRIGHTON_AND_HOVE="( \
  ST_INTERSECTS(osm.way, (SELECT pol.way FROM planet_osm_polygon pol WHERE osm_id='-114085')) \
  OR \
  ST_INTERSECTS(osm.way, (SELECT pol.way FROM planet_osm_polygon pol WHERE osm_id='3451897')) \
  )"
  # delete anything not in Brighton and Hove or the Palace Pier..(although, can extend out of)
  psql -d osm-btn -c "DELETE FROM planet_osm_line osm WHERE not ${IN_BRIGHTON_AND_HOVE};"
  psql -d osm-btn -c "DELETE FROM planet_osm_point osm WHERE not ${IN_BRIGHTON_AND_HOVE};"
  psql -d osm-btn -c "DELETE FROM planet_osm_polygon osm WHERE not ${IN_BRIGHTON_AND_HOVE};"
  psql -d osm-btn -c "DELETE FROM planet_osm_roads osm WHERE not ${IN_BRIGHTON_AND_HOVE};"
  psql -d osm-btn -c "DELETE FROM planet_osm_line osm WHERE osm.boundary='administrative';"
  psql -d osm-btn -c "DELETE FROM planet_osm_polygon osm WHERE osm.boundary='administrative';"
  psql -d osm-btn -c "DELETE FROM planet_osm_roads osm WHERE osm.boundary='administrative';"
fi

BASEDIR="$( cd "$( dirname "$0" )" && pwd )"
COPYSELECT="COPY (select 'https://www.openstreetmap.org/node/'||osm_id as aaa_uri, ST_AsText(way) as geom, ST_X(way) as longitude, ST_Y(way) as latitude, * from planet_osm_point) TO '${BASEDIR}/brighton_and_hove_osm_point.csv' DELIMITER ',' CSV HEADER;"
psql -d osm-btn -c "${COPYSELECT}"

COPYSELECT="COPY (select 'https://www.openstreetmap.org/way/'||osm_id as aaa_uri, ST_AsText(way) as geom, ST_X(ST_Centroid(way)) as longitude, ST_Y(ST_Centroid(way)) as latitude, * from planet_osm_polygon) TO '${BASEDIR}/brighton_and_hove_osm_polygon.csv' DELIMITER ',' CSV HEADER;"
psql -d osm-btn -c "${COPYSELECT}"

COPYSELECT="COPY (select 'https://www.openstreetmap.org/way/'||osm_id as aaa_uri, ST_AsText(way) as geom, ST_X(ST_Centroid(way)) as longitude, ST_Y(ST_Centroid(way)) as latitude, * from planet_osm_line) TO '${BASEDIR}/brighton_and_hove_osm_line.csv' DELIMITER ',' CSV HEADER;"
psql -d osm-btn -c "${COPYSELECT}"

COLUMNS="osm_id, access, \"addr:housename\" as addr_housename, \"addr:housenumber\" as addr_housenumber, \"addr:interpolation\" as addr_interpolation, admin_level, aerialway, aeroway, amenity, area, barrier, bicycle, brand, bridge, boundary, building, construction, covered, culvert, cutting, denomination, disused, embankment, foot, \"generator:source\" as generator_source, harbour, highway, historic, horse, intermittent, junction, landuse, layer, leisure, lock, man_made, military, motorcar, name, \"natural\" as natural, office, oneway, operator, place, population, power, power_source, public_transport, railway, ref, religion, route, service, shop, sport, surface, toll, tourism, \"tower:type\" as tower_type, tunnel, water, waterway, wetland, width, wood, z_order, tags"

# tracktype, way_area, way

COPYSELECT="COPY (select 'https://www.openstreetmap.org/node/'||osm_id as aaa_uri, 'point' as source, 'Brighton' as city, ST_AsText(way) as geom, ST_X(way) as longitude, ST_Y(way) as latitude, ${COLUMNS} from planet_osm_point union select 'https://www.openstreetmap.org/way/'||osm_id as aaa_uri, 'polygon centroid' as source, 'Brighton' as city, ST_AsText(way) as geom, ST_X(ST_Centroid(way)) as longitude, ST_Y(ST_Centroid(way)) as latitude, ${COLUMNS} from planet_osm_polygon union select 'https://www.openstreetmap.org/way/'||osm_id as aaa_uri, 'line centroid' as source, 'Brighton' as city, ST_AsText(way) as geom, ST_X(ST_Centroid(way)) as longitude, ST_Y(ST_Centroid(way)) as latitude, ${COLUMNS} from planet_osm_line) TO '${BASEDIR}/brighton_and_hove_osm_point_and_polygon.csv' DELIMITER ',' CSV HEADER;"
psql -d osm-btn -c "${COPYSELECT}"

#ogr2ogr -f GeoJSON out.geojson \
#  "PG:host=localhost dbname=osm-btn" \
#  -sql "select way,name,amenity from planet_osm_point a where a.amenity is not null"
