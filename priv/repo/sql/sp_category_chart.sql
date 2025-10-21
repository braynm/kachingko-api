CREATE OR REPLACE FUNCTION kachingko_dashboard_category_chart(
  p_user_id INTEGER,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  categories json,
  prev_month_total_amount numeric,
  cur_month_total_amount numeric,
  cur_month_txns json
) AS $$
BEGIN
	RETURN QUERY
	WITH txns as (
		select
			t.id,
			(t.posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Manila')::date posted_date,
			(t.sale_date AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Manila')::date sale_date,
			m.amount / 100 amount,
			m.details,
			t.category,
			concat(c.bank, ' ', c.name) card
		from "transaction" t
		left join "transaction_meta" m
		on m.transaction_id = t.id

		left join "card_statement" cs
		on cs.id = t.statement_id

		left join "card" c
		on c.id = cs.card_id
	
		where t.user_id = p_user_id
		and t.sale_date::date >= p_start_date - '1 month'::interval
		and t.sale_date <= p_end_date
		and m.details <> 'PAYMENT'
	)


	select
		(
			select json_agg(t) from (
				select category, sum(amount) amount from txns
				where txns.sale_date between p_start_date and p_end_date
				group by category
			) t
		),
		(
			select SUM(txns.amount) FROM txns
			WHERE txns.sale_date >= p_start_date - '1 month'::interval
			AND txns.sale_date <= (p_end_date - '1 month'::interval)
		)::numeric,
		(
			select SUM(txns.amount) FROM txns
			WHERE txns.sale_date >= p_start_date
			AND txns.sale_date <= p_end_date
		)::numeric,
		(
			select json_agg(t) from (
				select * 
				from txns
        where txns.sale_date between p_start_date and p_end_date
				order by txns.sale_date
				
			) t
		)
;END;
$$ LANGUAGE plpgsql;
