--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате платежа--Column_1
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа -- Column 2
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по размеру платежа от наименьшей к большей-- Column_3
--Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к
--меньшему так, чтобы платежи с одинаковым значением имели одинаковое значение номера.--Column 4
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.
select customer_id ,payment_id ,payment_date, 
row_number()over(order by payment_date) as column_1,
row_number()over(partition by customer_id order by payment_date) as column_2,
sum(amount) over (partition by customer_id order by payment_date,amount) as column_3,
dense_rank() over(partition by customer_id order by amount desc) as column_4
from payment

 --ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.
select customer_id ,payment_id ,payment_date,amount,
lag(amount,1,0.0) over (partition by customer_id order by payment_date) 
from payment



--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.
select customer_id ,payment_id ,payment_date,amount,
amount - lead(amount) over (partition by customer_id order by payment_date) as difference
from payment

--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

select customer_id ,payment_id ,payment_date,amount
from (
	select *,
		last_value(payment_id) over (partition by customer_id order by payment_date
			rows between unbounded preceding and unbounded following)
	from payment)
where payment_id = last_value

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.
with sum as (
    select 
        staff_id,
        payment_date::date as payment_date,
        sum(amount) as sum_amount
    from payment
    where payment_date >= '2005-08-01'::date
      and payment_date < '2005-09-01'::date
    group by staff_id, payment_date::date
)
select
    staff_id,
    to_char(payment_date, 'DD.MM.YYYY') as payment_date,
    sum_amount,
    sum(sum_amount) over (
        partition by staff_id
        order by payment_date
        rows between unbounded preceding and current row
    ) as sum
from sum
order by staff_id, payment_date;





--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку


select customer_id,payment_date,payment_number
from (select *,row_number()over(order by payment_date) as payment_number from payment where payment_date::date ='2005-08-20' )
where payment_number%100 = 0



--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

with customer_country as (
    select
        c.customer_id,
        c.first_name || ' ' || c.last_name as full_name,
        ct.country
    from customer c
    join address a on c.address_id = a.address_id
    join city ci on a.city_id = ci.city_id
    join country ct on ci.country_id = ct.country_id
),-- связка покупатели/страны
customer_rentals as (
    select
        r.customer_id,
        count(r.rental_id) as rental_count,
        max(r.rental_date) as last_rental_date
    from rental r
    group by r.customer_id
),--статистика по арендам
customer_payments as (
    select
        p.customer_id,
        sum(p.amount) as total_payment
    from payment p
    group by p.customer_id
),--статистика по платежам
customer_stats as (
    select
        cc.country,
        cc.customer_id,
        cc.full_name,
        cr.rental_count,
        cp.total_payment,
        cr.last_rental_date
    from customer_country cc
    left join customer_rentals cr on cc.customer_id = cr.customer_id
    left join customer_payments cp on cc.customer_id = cp.customer_id
),-- объединение по каждому покупателю
ranked_stats as (
    select
        country,
        full_name,-- в кастомер-кантри
        rental_count,-- в кастомер ренталс
        total_payment,-- в кастомер пэймент
        last_rental_date,-- в кастомер ренталс
        rank() over (partition by country order by rental_count desc nulls last) as rank_rental_count,
        rank() over (partition by country order by total_payment desc nulls last) as rank_total_payment,
        rank() over (partition by country order by last_rental_date desc nulls last) as rank_last_rental
    from customer_stats
)-- ранги по 3 критериям
select-- ИТОГОВЫЙ ВЫВОД
    country as Страна,
    max(case when rank_rental_count = 1 then full_name end) as "наибольшее колличество фильмов",
    max(case when rank_total_payment = 1 then full_name end) as "на самую большую сумму",
    max(case when rank_last_rental = 1 then full_name end) as "последний арендовавший"
from ranked_stats
group by country
order by country;







