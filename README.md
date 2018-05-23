Prepare data for analysis and visualisation of OpenStreeMap Brighton

Brighton and Hove is technically a unitary authority that is part of the
traditional county of East Sussex.
It is defined in OSM by [relation 114085]( https://www.openstreetmap.org/relation/114085)

```sql
SELECT osm_id FROM public.planet_osm_polygon
WHERE boundary = 'administrative'
  AND admin_level = '6'
  AND name = 'Brighton and Hove'
```

Requirements
============
Postgres database server
postgis
osm2pgsql
ogr2ogr

To Run
======
```sh
chmod a+x db-build.sh
./db-build.sh
```
