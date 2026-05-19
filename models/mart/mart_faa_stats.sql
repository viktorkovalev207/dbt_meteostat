WITH departures AS (
    -- Aggregation aller Abflüge pro Flughafen
    SELECT 
        origin AS airport_code,
        COUNT(DISTINCT dest) AS unique_departure_connections,
        COUNT(*) AS planned_departures,
        SUM(cancelled) AS cancelled_departures, 
        SUM(diverted) AS diverted_departures,
        SUM(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 ELSE 0 END) AS actual_departures,
        COUNT(DISTINCT tail_number) AS unique_airplanes_dep,
        COUNT(DISTINCT airline) AS unique_airlines_dep
    FROM {{ ref('staging_flights_one_month') }}
    GROUP BY origin
),

arrivals AS (
    -- Aggregation aller Ankünfte pro Flughafen
    SELECT 
        dest AS airport_code,
        COUNT(DISTINCT origin) AS unique_arrival_connections,
        COUNT(*) AS planned_arrivals,
        SUM(cancelled) AS cancelled_arrivals,
        SUM(diverted) AS diverted_arrivals,
        SUM(CASE WHEN cancelled = 0 AND diverted = 0 THEN 1 ELSE 0 END) AS actual_arrivals,
        COUNT(DISTINCT tail_number) AS unique_airplanes_arr,
        COUNT(DISTINCT airline) AS unique_airlines_arr
    FROM {{ ref('staging_flights_one_month') }}
    GROUP BY dest
),

airports AS (
    -- Metadaten der Flughäfen
    SELECT 
        faa, 
        name AS airport_name,
        city,
        country
    FROM {{ ref('staging_airports') }}
),

final AS (
    -- Alles zusammenführen und Ankünfte + Abflüge addieren
    SELECT 
        a.faa AS airport_code,
        a.airport_name,
        a.city,
        a.country,
        
        -- Eindeutige Verbindungen
        COALESCE(d.unique_departure_connections, 0) AS unique_departure_connections,
        COALESCE(r.unique_arrival_connections, 0) AS unique_arrival_connections,
        
        -- Fluganzahlen (Abflüge + Ankünfte addiert)
        COALESCE(d.planned_departures, 0) + COALESCE(r.planned_arrivals, 0) AS total_planned_flights,
        COALESCE(d.cancelled_departures, 0) + COALESCE(r.cancelled_arrivals, 0) AS total_cancelled_flights,
        COALESCE(d.diverted_departures, 0) + COALESCE(r.diverted_arrivals, 0) AS total_diverted_flights,
        COALESCE(d.actual_departures, 0) + COALESCE(r.actual_arrivals, 0) AS total_actual_flights,
        
        -- Optionale Felder: Durchschnittliche einzigartige Flugzeuge und Airlines
        (COALESCE(d.unique_airplanes_dep, 0) + COALESCE(r.unique_airplanes_arr, 0)) / 2 AS avg_unique_airplanes,
        (COALESCE(d.unique_airlines_dep, 0) + COALESCE(r.unique_airlines_arr, 0)) / 2 AS avg_unique_airlines

    FROM airports a
    LEFT JOIN departures d ON a.faa = d.airport_code
    LEFT JOIN arrivals r ON a.faa = r.airport_code
)

SELECT * FROM final