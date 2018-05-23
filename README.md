Prepare OpenStreetMap Brighton and Hove data for analysis and visualisation
===========================================================================
Brighton and Hove is technically a unitary authority that is part of the
traditional county of East Sussex.
It is defined in OSM by [relation 114085]( https://www.openstreetmap.org/relation/114085)

To Use Tableau
==============
I have a [download of the data](https://s3.eu-west-2.amazonaws.com/openplaques/brighton_and_hove_osm_point_and_polygon.csv) in AWS for now.

* Open brighton_and_hove_osm_point_and_polygon.csv
![Open brighton_and_hove_osm_point_and_polygon.csv](Screen%20Shot%202018-05-23%20at%205.18.55%20pm.png)

* Click on 'Sheet 1'
![Click on 'Sheet 1'](Screen%20Shot%202018-05-23%20at%205.19.19%20pm.png)

* Drag Longitude to Columns and Latitude to Rows
![Drag Longitude to Columns and Latitude to Rows](Screen%20Shot%202018-05-23%20at%205.19.39%20pm.png)

* Right-click and change Longitude and Latitude into Dimensions
![Right-click and change Longitude and Latitude into Dimensions](Screen%20Shot%202018-05-23%20at%205.19.57%20pm.png)

* Drag the Amenity Dimension to Filters. Exclude Nulls
![Drag the Amenity Dimension to Filters. Exclude Nulls](Screen%20Shot%202018-05-23%20at%205.20.36%20pm.png)

* Drag (another) Amenity Dimension to Columns
![Drag (another) Amenity Dimension to Columns](Screen%20Shot%202018-05-23%20at%205.21.06%20pm.png)

* Right-click on a point to View Data
![Right-click on a point to View Data](Screen%20Shot%202018-05-23%20at%205.24.11%20pm.png)

* In the Full Data tab copy the OSM uri
![In the Full Data tab copy the OSM uri](Screen%20Shot%202018-05-23%20at%205.24.27%20pm.png)

* Paste the uri in a web browser
![Paste the uri in a web browser](Screen%20Shot%202018-05-23%20at%205.24.47%20pm.png)

To prepare the data yourself
============================

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

To query the database
=====================
I recommend installing pg_admin. Then you can do queries like:

```sql
SELECT osm_id FROM public.planet_osm_polygon
WHERE boundary = 'administrative'
  AND admin_level = '6'
  AND name = 'Brighton and Hove'
```
