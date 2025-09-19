CREATE OR REPLACE FUNCTION kachingko_totals(
  p_user_id INTEGER,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  ytd_amount numeric,
  monthly_avg numeric,
  highest_purchase numeric,
  overall_amount numeric,
  monthly_expenses json,
  top_expenses json
) AS $$
BEGIN
    RETURN QUERY
	with months as (
		SELECT generate_series(
      p_start_date::date,
      p_end_date::date,
      '1 month'::interval
		)::date AS month
	), txns as (
		select
		TRUNC(m.amount / 100.0, 2) amount,
		m.details,
		(t.sale_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Manila')::date as sale_date,
    concat(c.bank, ' ', c.name) card_name

		from transaction t
		left join transaction_meta m
		on m.transaction_id = t.id

    left join card_statement st
		on t.statement_id = st.id

		left join card c
		on st.card_id = c.id
		
		where t.user_id = p_user_id
		and m.details <> 'PAYMENT'
	)

select
	(
		SELECT
			coalesce(SUM(amount), 0)::numeric
		FROM txns
		WHERE txns.sale_date::date BETWEEN p_start_date::date AND p_end_date
	) ytd_amount,
	(
	SELECT AVG(amount) from (
	select
	date_trunc('month', txns.sale_date)::date sale_date,
	COALESCE(SUM(amount), 0) amount
		FROM txns
		WHERE txns.sale_date::date BETWEEN p_start_date::date AND p_end_date
		GROUP BY date_trunc('month', txns.sale_date)
	) t
	) monthly_avg,
	(
		SELECT amount from txns
		order by amount desc
		limit 1
	) highest_purchase,
	(
		SELECT COALESCE(SUM(amount), 0) from txns
	) overall_amt,
	(
		SELECT json_agg(t) from (
      SELECT
        COALESCE(SUM(txns.amount), 0) amount,
        COUNT(txns.sale_date) "total_txns",
        months.month,
        txns.card_name name
      FROM months
      LEFT JOIN txns
      ON date_trunc('month', txns.sale_date) = months.month
      GROUP BY months.month, txns.card_name
      ORDER BY months.month

		) t
	) monthly_expenses,
	(
		SELECT json_agg(t) FROM (
      SELECT
        txns.details,
        sale_date::date,
        coalesce(amount, 0) amount
      FROM txns
      ORDER BY amount desc
      LIMIT 10
		) t
	) top_expenses
	
;END;
$$ LANGUAGE plpgsql;
