filename="west-sussex-$(date +'%Y-%m-%d').osm.pbf"
if [ -e $filename ]
then
    echo "file already downloaded today"
else
  rm -f west-sussex-*.osm.pbf
  curl https://download.geofabrik.de/europe/great-britain/england/west-sussex-latest.osm.pbf > $filename
fi
#dropdb osm-btn
#createdb osm-btn
#psql -d osm-btn -c 'CREATE EXTENSION postgis; CREATE EXTENSION hstore;'
#sm2pgsql -l --hstore --number-processes 4 --multi-geometry --keep-coastlines -d osm-btn $filename

# delete anything not in Brighton and Hove..(although, can extend out of)
#psql -d osm-btn -c "DELETE FROM planet_osm_line osm WHERE not ST_INTERSECTS(osm.way, (SELECT pol.way FROM planet_osm_polygon pol WHERE osm_id='-114085'));"
#psql -d osm-btn -c "DELETE FROM planet_osm_point osm WHERE not ST_WITHIN(osm.way, (SELECT pol.way FROM planet_osm_polygon pol WHERE osm_id='-114085'));"
#psql -d osm-btn -c "DELETE FROM planet_osm_polygon osm WHERE not ST_INTERSECTS(osm.way, (SELECT pol.way FROM planet_osm_polygon pol WHERE osm_id='-114085'));"
#psql -d osm-btn -c "DELETE FROM planet_osm_roads osm WHERE not ST_INTERSECTS(osm.way, (SELECT pol.way FROM planet_osm_polygon pol WHERE osm_id='-114085'));"
#psql -d osm-btn -c "DELETE FROM planet_osm_roads osm WHERE osm.boundary='administrative';"

BASEDIR="$( cd "$( dirname "$0" )" && pwd )"
COPYSELECT="COPY (select ST_AsText(way) as geom, ST_X(way) as longitude, ST_Y(way) as latitude, * from planet_osm_point) TO '${BASEDIR}/planet_osm_point.csv' DELIMITER ',' CSV HEADER;"
psql -d osm-btn -c "${COPYSELECT}"
#ogr2ogr -f GeoJSON out.geojson \
#  "PG:host=localhost dbname=osm-btn" \
#  -sql "select way,name,amenity from planet_osm_point a where a.amenity is not null"
