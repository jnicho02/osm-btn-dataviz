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
Tableau Public

To Run
======
```sh
chmod a+x db-build.sh
./db-build.sh
```

To Use Tableau
==============
* Open brighton_and_hove_osm_point_and_polygon.csv

![Open brighton_and_hove_osm_point_and_polygon.csv](Screen%20Shot%202018-05-23%20at%205.18.55%20pm.png)

![Open brighton_and_hove_osm_point_and_polygon.csv](Screen%20Shot%202018-05-23%20at%205.19.19%20pm.png)

![Open brighton_and_hove_osm_point_and_polygon.csv](Screen%20Shot%202018-05-23%20at%205.19.39%20pm.png)

![Open brighton_and_hove_osm_point_and_polygon.csv](Screen%20Shot%202018-05-23%20at%205.19.57%20pm.png)

![Open brighton_and_hove_osm_point_and_polygon.csv](Screen%20Shot%202018-05-23%20at%205.20.36%20pm.png)

![Open brighton_and_hove_osm_point_and_polygon.csv](Screen%20Shot%202018-05-23%20at%205.21.06%20pm.png)

![Open brighton_and_hove_osm_point_and_polygon.csv](Screen%20Shot%202018-05-23%20at%205.24.11%20pm.png)

![Open brighton_and_hove_osm_point_and_polygon.csv](Screen%20Shot%202018-05-23%20at%205.24.27%20pm.png)

![Open brighton_and_hove_osm_point_and_polygon.csv](Screen%20Shot%202018-05-23%20at%205.24.47%20pm.png)
