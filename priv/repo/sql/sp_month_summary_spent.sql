-- contains the summary spent of the month
CREATE OR REPLACE FUNCTION kachingko_month_summary_spent(
  p_user_id INTEGER,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  day_date date,
  spent_pct NUMERIC,
  daily_spent json
) AS $$
BEGIN
    RETURN QUERY
  
	with days as (
		SELECT generate_series(
      p_start_date::date,
      p_end_date::date,
      '1 day'::interval
		)::date AS day
	), txns as (
		select
		TRUNC(m.amount / 100.0, 2) amount,
		(t.sale_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Manila')::date as sale_date 
		from transaction t
		left join transaction_meta m
		on m.transaction_id = t.id
		
		where t.user_id = p_user_id
		and m.details <> 'PAYMENT'
	), new_amt as (
		select sum(amount) from txns where txns.sale_date between p_start_date and p_end_date
	), prev_amt as (
		select sum(amount) from txns
		where txns.sale_date between p_start_date - '1 month'::interval and p_start_date - '1 day'::interval
	)

select
	p_start_date,
	trunc(((select * from new_amt) - (select * from prev_amt)) / (select * from prev_amt) * 100, 2)::numeric,
	(
		select json_agg(t) from (
			select
        days.day day_date,
        sum(coalesce(amount, 0)) amount
			from days
			left join txns on txns.sale_date::date = days.day::date
			where days.day::date >= p_start_date::date and days.day::date < p_start_date + '1 month'::interval
			group by days.day
			order by days.day
		) t
	)
	
;END;
$$ LANGUAGE plpgsql;
