--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".
explain analyze --67.50
select film_id ,title,special_features
from film 
where special_features @> array['Behind the Scenes']




--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.
explain analyze
select film_id ,title,special_features
from film 
where 'Behind the Scenes' = any(special_features)

explain analyze--67.50
select film_id ,title,special_features 
from film 
where 'Behind the Scenes' = some(special_features)

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.
explain analyze--720.76
with btsf as (
    select film_id ,title,special_features
    from film
    where special_features @> array['Behind the Scenes']
)
select
    c.customer_id,
    count(r.rental_id) as film_count
from
    customer c
    left join rental r using(customer_id)
    left join inventory i using(inventory_id)
    left join btsf  using(film_id)
where
    btsf.film_id is not null
group by
    c.customer_id
order by c.customer_id






--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.
explain analyze--720.76
select
    c.customer_id,
    count(r.rental_id) as film_count
from
    customer c
    left join rental r using (customer_id)
    left join inventory i using (inventory_id) 
    left join (
        select film_id ,title,special_features
        from film
        where special_features @> array['Behind the Scenes']
    ) bts using(film_id)
where
    bts.film_id is not null
group by
    c.customer_id
order by
    c.customer_id




--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view task_1 as 
	select
    	c.customer_id,
    	count(r.rental_id) as film_count
	from
    	customer c
   		 left join rental r using (customer_id)
    	left join inventory i using (inventory_id) 
    	left join (
        	select film_id ,title,special_features
        	from film
       	 where special_features @> array['Behind the Scenes']
   	 ) bts using(film_id)
	where
   		bts.film_id is not null
	group by
    	c.customer_id
	order by
    	c.customer_id;

refresh materialized view task_1

--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.
Оператор @> затрачивает меньше ресурсов , по анализу выходит одинаково
Подзапрос затрачивает меньше ресурсов, чем CTE 43kb против 105



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии
Слабые места:
-full outer joinы
-Использование unnest в подзапросе
-like с шаблоном %Behind the Scenes%
-Неоптимальное использование оконной функции

План:
-Последовательное сканирование таблицы film для получения всех фильмов и их special_features
-Последовательное сканирование inventory для соединения с фильмами
-Создание большой промежуточной таблицы, где каждая строка inventory соединяется с фильмом (или остаётся NULL)
-Для каждой строки разворачивается массив special_features — на каждый элемент массива создаётся отдельная строка
-Каждый элемент inventory соединяется с rental, что ещё больше увеличивает объём данных
-Итоговая таблица соединяется с customer, что приводит к огромному количеству строк, если есть пропуски
-Для каждой строки проверяется, содержит ли sfs подстроку 'Behind the Scenes'. Это приводит к перебору всех строк
-Оконная функция и DISTINCT
-Для каждой группы по customer_id считается количество, затем выбираются уникальные строки по имени
Проблемы:
Большое количество последовательных сканирований (Seq Scan).
Несколько крупных операций сортировки и хеширования.
Высокое потребление памяти и процессорного времени.
Итоговое время выполнения на больших данных может быть десятки секунд и больше
--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.
select
    sub.staff_id,
    i.film_id,
    p.amount,
    p.payment_date,
    c.last_name as customer_last_name,
    c.first_name as customer_first_name
from (
    select
        p.payment_id,
        p.staff_id,
        p.payment_date,
        row_number() over (partition by p.staff_id order by p.payment_date asc) as rn
    from payment p
) sub
join payment p using(payment_id)
join rental r using(rental_id)
join inventory i using(inventory_id)
join customer c on c.customer_id = r.customer_id
where sub.rn = 1







--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день

with rentals_per_day as (
   select
        i.store_id,
        date(r.rental_date) as day,
        count(*) as rentals_count
    from rental r
    join inventory i  using(inventory_id)
    group by i.store_id, day
),-- аренды зв день
payments_per_day as (
    select
        s.store_id,
        date(p.payment_date) as day,
        sum(p.amount) as total_amount
    from payment p
    join staff s on p.staff_id = s.staff_id
    group by s.store_id, day
),-- платежи за день
max_rentals as (
    select distinct on (store_id)
        store_id,
        day as max_rentals_day,
        rentals_count
    from rentals_per_day
    order by store_id, rentals_count desc, day
),-- максимальные аренды
min_payments as (
    select distinct on (store_id)
        store_id,
        day as min_payment_day,
        total_amount
    from payments_per_day
    order by store_id, total_amount asc, day
)--минимальные платежи
select
    mr.store_id as "ID магазина",
    mr.max_rentals_day as "больше всего фильмов",
    mr.rentals_count as "количесвтво аренд",
    mp.min_payment_day as "на наименьшую сумму",
    mp.total_amount as"сумма продаж за этот день"
from max_rentals mr
join min_payments mp on mr.store_id = mp.store_id





