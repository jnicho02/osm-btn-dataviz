CITY="brighton-and-hove"
#CITY="manchester"
if [[ $CITY = "brighton-and-hove" ]]
then
  COUNTY="west-sussex" # have requested that it be in East Sussex
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

# Food Hygeine Rating Service

if [[ $CITY = "brighton-and-hove" ]]
then
  FHRS="FHRS875en-GB.xml"
else
  FHRS="FHRS415en-GB.xml"
fi

# NB postgres demands that files are in its data_directory to import them
PGDATA=`psql -d osm-${CITY} -Atc "SHOW data_directory;"`
if [ -e "${PGDATA}/${CITY}-fhrs-$(date +'%Y-%m-%d').xml" ]
then
  echo "${CITY}-fhrs file already downloaded today"
else
  curl http://ratings.food.gov.uk/OpenDataFiles/${FHRS} > "${PGDATA}/${CITY}-fhrs-$(date +'%Y-%m-%d').xml"
  psql -d osm-$CITY -c "DROP TABLE IF EXISTS fhrs"
  psql -d osm-$CITY -c "
    SELECT
      (xpath('//FHRSID/text()', myTempTable.myXmlColumn))[1]::text AS fhrs_id
      ,(xpath('//LocalAuthorityBusinessID/text()', myTempTable.myXmlColumn))[1]::text AS LocalAuthorityBusinessID
      ,(xpath('//BusinessName/text()', myTempTable.myXmlColumn))[1]::text AS BusinessName
      ,(xpath('//BusinessType/text()', myTempTable.myXmlColumn))[1]::text AS BusinessType
      ,(xpath('//BusinessTypeID/text()', myTempTable.myXmlColumn))[1]::text AS BusinessTypeID
      ,(xpath('//AddressLine1/text()', myTempTable.myXmlColumn))[1]::text AS AddressLine1
      ,(xpath('//AddressLine2/text()', myTempTable.myXmlColumn))[1]::text AS AddressLine2
      ,(xpath('//PostCode/text()', myTempTable.myXmlColumn))[1]::text AS PostCode
      ,(xpath('//RatingValue/text()', myTempTable.myXmlColumn))[1]::text AS RatingValue
      ,(xpath('//RatingKey/text()', myTempTable.myXmlColumn))[1]::text AS RatingKey
      ,(xpath('//RatingDate/text()', myTempTable.myXmlColumn))[1]::text AS RatingDate
      ,(xpath('//LocalAuthorityCode/text()', myTempTable.myXmlColumn))[1]::text AS LocalAuthorityCode
      ,(xpath('//LocalAuthorityName/text()', myTempTable.myXmlColumn))[1]::text AS LocalAuthorityName
      ,(xpath('//LocalAuthorityWebSite/text()', myTempTable.myXmlColumn))[1]::text AS LocalAuthorityWebSite
      ,(xpath('//LocalAuthorityEmailAddress/text()', myTempTable.myXmlColumn))[1]::text AS LocalAuthorityEmailAddress
      ,(xpath('//Scores/Hygiene/text()', myTempTable.myXmlColumn))[1]::text AS HygieneScore
      ,(xpath('//Scores/Structural/text()', myTempTable.myXmlColumn))[1]::text AS StructuralScore
      ,(xpath('//Scores/ConfidenceInManagement/text()', myTempTable.myXmlColumn))[1]::text AS ConfidenceInManagement
      ,(xpath('//SchemeType/text()', myTempTable.myXmlColumn))[1]::text AS SchemeType
      ,(xpath('//NewRatingPending/text()', myTempTable.myXmlColumn))[1]::text AS NewRatingPending
      ,(xpath('//Geocode/Longitude/text()', myTempTable.myXmlColumn))[1]::text AS Longitude
      ,(xpath('//Geocode/Latitude/text()', myTempTable.myXmlColumn))[1]::text AS Latitude
    INTO fhrs
    FROM unnest(
      xpath
      ('//EstablishmentDetail'
        ,XMLPARSE(DOCUMENT convert_from(pg_read_binary_file('${CITY}-fhrs-$(date +'%Y-%m-%d').xml'), 'UTF8'))
      )) AS myTempTable(myXmlColumn)
  ;"
fi

BASEDIR="$( cd "$( dirname "$0" )" && pwd )"
FHRS_COLUMNS="
  fhrs_id,
  ratingvalue,
  ratingdate,
  hygienescore,
  structuralscore,
  confidenceinmanagement,
  schemetype,
  newratingpending
"

COPYSELECT="COPY
  (SELECT ${FHRS_COLUMNS} FROM fhrs)
  TO '${BASEDIR}/fhrs-${CITY}.csv' DELIMITER ',' CSV HEADER;"

psql -d osm-$CITY -c "${COPYSELECT}"


# ST_AsText(way) as wkt,
COLUMNS="
  osm_id,
  ST_X(ST_CENTROID(way)) as longitude,
  ST_Y(ST_CENTROID(way)) as latitude,
  '${CITY}' as city,
  access,
  \"addr:housename\" as addr_housename,
  \"addr:housenumber\" as addr_housenumber,
  \"addr:interpolation\" as addr_interpolation,
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
  tags
"

# removed: tracktype, way_area, way

COPYSELECT="COPY (
    SELECT 'point' AS source,
    'https://www.openstreetmap.org/node/'||osm_id AS aaa_uri,
    ${COLUMNS},
    ${FHRS_COLUMNS}
    FROM planet_osm_point osm
    LEFT OUTER JOIN fhrs
    ON (substring(osm.tags->'fhrs:id' from '\d*') = fhrs_id)
  UNION
    SELECT 'polygon centroid' AS source,
    'https://www.openstreetmap.org/way/'||osm_id AS aaa_uri,
    ${COLUMNS},
    ${FHRS_COLUMNS}
    FROM planet_osm_polygon osm
    LEFT OUTER JOIN fhrs
    ON (substring(osm.tags->'fhrs:id' from '\d*') = fhrs_id)
  UNION
    SELECT 'line centroid' AS source,
    'https://www.openstreetmap.org/way/'||osm_id AS aaa_uri,
    ${COLUMNS},
    ${FHRS_COLUMNS}
    FROM planet_osm_line osm
    LEFT OUTER JOIN fhrs
    ON (substring(osm.tags->'fhrs:id' from '\d*') = fhrs_id)
  )
  TO '${BASEDIR}/osm-${CITY}.csv' DELIMITER ',' CSV HEADER;"

psql -d osm-$CITY -c "${COPYSELECT}"

## Bike Share
COLUMNS="
  osm_id,
  ref,
  name,
  ST_X(ST_CENTROID(way)) as longitude,
  ST_Y(ST_CENTROID(way)) as latitude
"

if [[ $CITY = "brighton-and-hove" ]]
then
  SCHEME="
    AND tags->'network'='btnbikeshare'
  "
else
  SCHEME=""
fi

COPYSELECT="COPY (
  SELECT ${COLUMNS}
  FROM planet_osm_point
  WHERE amenity='bicycle_rental'
  ${SCHEME}
  ORDER BY ref ASC
  )
  TO '${BASEDIR}/bikeshare-${CITY}.csv' DELIMITER ',' CSV HEADER;"

psql -d osm-$CITY -c "${COPYSELECT}"
