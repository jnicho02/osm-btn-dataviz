# NB postgres demands that files are in its data dir to import them
PGDATA=`psql -d osm-btn -Atc "SHOW data_directory;"`
# Brighton
if [ -e "${PGDATA}/FHRS875en-GB-$(date +'%Y-%m-%d').xml" ]
then
  echo "file already downloaded today"
else
  curl http://ratings.food.gov.uk/OpenDataFiles/FHRS875en-GB.xml > "${PGDATA}/FHRS875en-GB-$(date +'%Y-%m-%d').xml"
fi
# Manchester
if [ -e "${PGDATA}/FHRS415en-GB-$(date +'%Y-%m-%d').xml" ]
then
  echo "file already downloaded today"
else
  curl http://ratings.food.gov.uk/OpenDataFiles/FHRS415en-GB.xml > "${PGDATA}/FHRS415en-GB-$(date +'%Y-%m-%d').xml"
fi

psql -d osm-btn -c "SELECT \
     (xpath('//FHRSID/text()', myTempTable.myXmlColumn))[1]::text AS id \
    ,(xpath('//LocalAuthorityBusinessID/text()', myTempTable.myXmlColumn))[1]::text AS LocalAuthorityBusinessID \
    ,myTempTable.myXmlColumn as myXmlElement \
FROM unnest( \
    xpath \
    (    '//EstablishmentDetail' \
        ,XMLPARSE(DOCUMENT convert_from(pg_read_binary_file('FHRS875en-GB-$(date +'%Y-%m-%d').xml'), 'UTF8')) \
    ) \
) AS myTempTable(myXmlColumn) \
;"
