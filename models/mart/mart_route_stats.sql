WITH route_metrics AS (
    -- Aggregation der KPIs pro Route (Kombination aus origin und dest)
    SELECT 
        origin,
        dest,
        COUNT(*) AS total_flights,
        
        -- Verspätungen (Abflug)
        AVG(dep_delay) AS avg_dep_delay,
        MIN(dep_delay) AS min_dep_delay,
        MAX(dep_delay) AS max_dep_delay,
        
        -- Verspätungen (Ankunft)
        AVG(arr_delay) AS avg_arr_delay,
        MIN(arr_delay) AS min_arr_delay,
        MAX(arr_delay) AS max_arr_delay,
        
        -- Flugzeiten
        AVG(actual_elapsed_time) AS avg_flight_time,
        MIN(actual_elapsed_time) AS min_flight_time,
        MAX(actual_elapsed_time) AS max_flight_time
        
    FROM {{ ref('staging_flights_one_month') }}
    GROUP BY origin, dest
),

airports AS (
    -- Metadaten der Flughäfen
    SELECT 
        faa,
        name,
        city,
        country
    FROM {{ ref('staging_airports') }}
),

final AS (
    -- Zusammenführen der Routen mit den Metadaten BEIDER Flughäfen
    SELECT 
        -- Routen-IDs
        r.origin,
        r.dest,
        
        -- Metadaten: Abflughafen (Alias: orig)
        orig.name AS origin_airport_name,
        orig.city AS origin_city,
        orig.country AS origin_country,
        
        -- Metadaten: Ankunftsflughafen (Alias: dest_ap)
        dest_ap.name AS dest_airport_name,
        dest_ap.city AS dest_city,
        dest_ap.country AS dest_country,
        
        -- Die berechneten KPIs
        r.total_flights,
        r.avg_dep_delay,
        r.min_dep_delay,
        r.max_dep_delay,
        r.avg_arr_delay,
        r.min_arr_delay,
        r.max_arr_delay,
        r.avg_flight_time,
        r.min_flight_time,
        r.max_flight_time

    FROM route_metrics r
    -- Hier passieren die zwei getrennten JOINs auf dieselbe Tabelle
    LEFT JOIN airports orig ON r.origin = orig.faa
    LEFT JOIN airports dest_ap ON r.dest = dest_ap.faa
)

SELECT * FROM final