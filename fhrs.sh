#CITY="brighton-and-hove"
CITY="manchester"

# NB postgres demands that files are in its data dir to import them
PGDATA=`psql -d osm-btn -Atc "SHOW data_directory;"`

if [[ $CITY = "brighton-and-hove" ]]
then
  FHRS="FHRS875en-GB.xml"
else
  FHRS="FHRS415en-GB.xml"
fi

if [ -e "${PGDATA}/${CITY}-fhrs-$(date +'%Y-%m-%d').xml" ]
then
  echo "file already downloaded today"
else
  curl http://ratings.food.gov.uk/OpenDataFiles/${FHRS} > "${PGDATA}/${CITY}-fhrs-$(date +'%Y-%m-%d').xml"
  psql -d osm-$CITY -c "DROP TABLE fhrs"
  psql -d osm-$CITY -c "
    SELECT
      (xpath('//FHRSID/text()', myTempTable.myXmlColumn))[1]::text AS id
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
COPYSELECT="COPY
  (SELECT id as fhrs_id,
    ratingvalue,
    ratingdate,
    hygienescore,
    structuralscore,
    confidenceinmanagement,
    schemetype,
    newratingpending FROM fhrs)
  TO '${BASEDIR}/fhrs-${CITY}.csv' DELIMITER ',' CSV HEADER;"
psql -d osm-$CITY -c "${COPYSELECT}"
