-- HOTEL REVENUE ANALYSIS: 12 BIGQUERY SQL QUERIES
-- Replace YOUR_PROJECT and YOUR_DATASET in every table reference with your actual values.
-- Expected table name: hotel_bookings
-- Source: Raw_Data sheet from the supplied Excel workbook.


-- 01 Overall KPIs
SELECT
  COUNT(*) AS total_bookings,
  COUNTIF(Status = 'Stayed') AS stayed_bookings,
  COUNTIF(Status = 'Cancelled') AS cancelled_bookings,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(Cancellation_Flag = 1), COUNT(*)), 2) AS cancellation_rate_pct,
  ROUND(SUM(Actual_Revenue), 2) AS total_revenue,
  ROUND(AVG(IF(Status = 'Stayed', ADR, NULL)), 2) AS avg_adr,
  SUM(Occupied_Room_Nights) AS occupied_room_nights
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`;

-- 02 Monthly Performance
SELECT
  Month,
  COUNT(*) AS bookings,
  SUM(Cancellation_Flag) AS cancellations,
  ROUND(SUM(Actual_Revenue), 2) AS revenue,
  SUM(Occupied_Room_Nights) AS occupied_room_nights,
  ROUND(SAFE_DIVIDE(SUM(Actual_Revenue), SUM(Occupied_Room_Nights)), 2) AS realized_adr
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`
GROUP BY Month
ORDER BY Month;

-- 03 Room Type Performance
SELECT
  Room_Type,
  COUNT(*) AS bookings,
  COUNTIF(Status = 'Stayed') AS stayed_bookings,
  ROUND(SUM(Actual_Revenue), 2) AS revenue,
  SUM(Occupied_Room_Nights) AS occupied_room_nights,
  ROUND(SAFE_DIVIDE(SUM(Actual_Revenue), SUM(Occupied_Room_Nights)), 2) AS realized_adr
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`
GROUP BY Room_Type
ORDER BY revenue DESC;

-- 04 Channel Performance
SELECT
  Channel,
  COUNT(*) AS bookings,
  SUM(Cancellation_Flag) AS cancellations,
  ROUND(100 * SAFE_DIVIDE(SUM(Cancellation_Flag), COUNT(*)), 2) AS cancellation_rate_pct,
  ROUND(SUM(Actual_Revenue), 2) AS revenue
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`
GROUP BY Channel
ORDER BY revenue DESC;

-- 05 Customer Segment Performance
SELECT
  Segment,
  COUNT(*) AS bookings,
  COUNTIF(Status = 'Stayed') AS stayed_bookings,
  ROUND(SUM(Actual_Revenue), 2) AS revenue,
  ROUND(100 * SAFE_DIVIDE(SUM(Cancellation_Flag), COUNT(*)), 2) AS cancellation_rate_pct
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`
GROUP BY Segment
ORDER BY revenue DESC;

-- 06 Cancellation Analysis
SELECT
  Status,
  COUNT(*) AS bookings,
  ROUND(100 * SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER()), 2) AS share_of_all_bookings_pct,
  ROUND(SUM(Actual_Revenue), 2) AS actual_revenue,
  SUM(Occupied_Room_Nights) AS occupied_room_nights
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`
GROUP BY Status
ORDER BY bookings DESC;

-- 07 Weekday vs Weekend
SELECT
  Weekend_Type,
  COUNT(*) AS bookings,
  COUNTIF(Status = 'Stayed') AS stayed_bookings,
  ROUND(SUM(Actual_Revenue), 2) AS revenue,
  SUM(Occupied_Room_Nights) AS occupied_room_nights,
  ROUND(SAFE_DIVIDE(SUM(Actual_Revenue), SUM(Occupied_Room_Nights)), 2) AS realized_adr
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`
GROUP BY Weekend_Type
ORDER BY Weekend_Type;

-- 08 Lead Time Bands
SELECT
  CASE
    WHEN Lead_Time_Days = 0 THEN 'Same day'
    WHEN Lead_Time_Days BETWEEN 1 AND 7 THEN '1-7 days'
    WHEN Lead_Time_Days BETWEEN 8 AND 30 THEN '8-30 days'
    WHEN Lead_Time_Days BETWEEN 31 AND 60 THEN '31-60 days'
    ELSE '61+ days'
  END AS lead_time_band,
  COUNT(*) AS bookings,
  SUM(Cancellation_Flag) AS cancellations,
  ROUND(100 * SAFE_DIVIDE(SUM(Cancellation_Flag), COUNT(*)), 2) AS cancellation_rate_pct,
  ROUND(SUM(Actual_Revenue), 2) AS revenue
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`
GROUP BY lead_time_band
ORDER BY CASE lead_time_band
  WHEN 'Same day' THEN 1 WHEN '1-7 days' THEN 2 WHEN '8-30 days' THEN 3
  WHEN '31-60 days' THEN 4 ELSE 5 END;

-- 09 Guest Count Analysis
SELECT
  Guests,
  COUNT(*) AS bookings,
  ROUND(SUM(Actual_Revenue), 2) AS revenue,
  SUM(Occupied_Room_Nights) AS occupied_room_nights,
  ROUND(AVG(IF(Status = 'Stayed', ADR, NULL)), 2) AS avg_adr
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`
GROUP BY Guests
ORDER BY Guests;

-- 10 Top 10 Stayed Bookings by Revenue
SELECT
  Booking_ID, Check_In, Room_Type, Channel, Segment, Nights, ADR, Actual_Revenue
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`
WHERE Status = 'Stayed'
ORDER BY Actual_Revenue DESC
LIMIT 10;

-- 11 Quarterly Performance
SELECT
  CONCAT(CAST(EXTRACT(YEAR FROM Check_In) AS STRING), '-Q',
         CAST(EXTRACT(QUARTER FROM Check_In) AS STRING)) AS Quarter,
  COUNT(*) AS bookings,
  SUM(Cancellation_Flag) AS cancellations,
  ROUND(SUM(Actual_Revenue), 2) AS revenue,
  SUM(Occupied_Room_Nights) AS occupied_room_nights
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`
GROUP BY Quarter
ORDER BY Quarter;

-- 12 Data Quality Checks
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT Booking_ID) AS distinct_booking_ids,
  COUNTIF(Booking_ID IS NULL OR TRIM(Booking_ID) = '') AS missing_booking_ids,
  COUNTIF(Booking_Date IS NULL OR Check_In IS NULL) AS missing_dates,
  COUNTIF(Nights <= 0) AS invalid_nights,
  COUNTIF(Guests <= 0) AS invalid_guest_counts,
  COUNTIF(ADR < 0 OR Room_Revenue < 0 OR Actual_Revenue < 0) AS negative_financial_values,
  COUNTIF(Status = 'Cancelled' AND
    (Actual_Revenue != 0 OR Occupied_Room_Nights != 0 OR Cancellation_Flag != 1)) AS cancelled_record_logic_issues,
  COUNTIF(Status = 'Stayed' AND
    (Cancellation_Flag != 0 OR ABS(Actual_Revenue - Room_Revenue) > 0.01
     OR Occupied_Room_Nights != Nights)) AS stayed_record_logic_issues,
  COUNTIF(ABS(Lead_Time_Days - DATE_DIFF(Check_In, Booking_Date, DAY)) > 0) AS lead_time_mismatch
FROM `YOUR_PROJECT.YOUR_DATASET.hotel_bookings`;
