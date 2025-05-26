--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.
select 
  c.customer_id, 
  a.address as адрес, 
  ct.city as город, 
  c2.country as страна 
from 
  customer c 
  join address a using(address_id) 
  join city ct using (city_id) 
  join country c2 using (country_id);



--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.
select 
  store_id, 
  count(customer_id) as "Колличество покупателей" 
from 
  customer 
group by 
  store_id



--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

select 
  store_id, 
  count(customer_id) as "Колличество покупателей" 
from 
  customer 
group by 
  store_id 
having 
  count(customer_id) > 300



-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.
select 
  s.store_id, 
  count(customer_id) as "Колличество покупателей", 
  c.city as Город, 
  concat(s2.last_name, ' ', s2.first_name) as "Имя Сотрудника" 
from 
  customer 
  join store s using (store_id) 
  join address a on s.address_id = a.address_id 
  join city c on a.city_id = c.city_id 
  join staff s2 on s.manager_staff_id = s2.staff_id 
group by 
  s.store_id, 
  c.city, 
  s2.first_name, 
  s2.last_name 
having 
  count(customer_id) > 300


--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов
select 
  concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя", 
  count(rental_id) as "Количество фильмов" 
from 
  rental r 
  join customer c using (customer_id) 
group by 
  customer_id 
order by 
  count(rental_id) desc 
limit 
  5



--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

select 
  concat(c.last_name, ' ', c.first_name) as "Фамилия и имя покупателя", 
  count(inventory_id) as "Количество фильмов", 
  round(
    sum(p.amount), 
    0
  ) as "Общая стоимость платежей", 
  min(p.amount) as "Минимальная стоимость платежа", 
  max(p.amount) as "Максимальная стоимость платежа" 
from 
  rental r 
  join customer c using (customer_id) 
  join payment p using (rental_id) 
group by 
  c.customer_id




--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.
select 
  c.city as "Город 1", 
  c2.city as "Город 2" 
from
  city c, 
  city c2 
where 
  c.city <> c2.city





--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и 
--дате возврата (поле return_date), вычислите для каждого покупателя среднее количество 
--дней, за которые он возвращает фильмы. В результате должны быть дробные значения, а не интервал.
select 
  customer_id as "ID покупателя", 
  round(
    avg(
      return_date :: date - rental_date :: date
    ), 
    2
  ) as "Среднее колличество дней на возврат" 
from 
  rental 
where 
  return_date is not null 
group by 
  customer_id 
order by 
  customer_id

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.
select 
  f.title as "Название фильма", 
  f.rating as "Рейтинг", 
  c.name as "Жанр", 
  f.release_year as "Год выпуска", 
  l.name as "Язык", 
  count(inventory_id) as "Количество аренд", 
  sum(p.amount) as "Общая стоимость аренды" 
from 
  inventory i 
  join rental r using (inventory_id) 
  join film f using (film_id) 
  join language l using(language_id) 
  join film_category fc using (film_id) 
  join category c using (category_id) 
  join payment p using (rental_id) 
group by 
  film_id, 
  l.name, 
  c.name 
order by 
  film_id

--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые отсутствуют на dvd дисках.
select 
  f.title as "Название фильма", 
  f.rating as "Рейтинг", 
  c.name as "Жанр", 
  f.release_year as "Год выпуска", 
  l.name as "Язык", 
  COUNT(i.inventory_id) as "Количество аренд", 
  SUM(p.amount) as "Общая стоимость аренды" 
from 
  film f 
  left join inventory i using(film_id) 
  left join rental r using(inventory_id)
  left join payment p using(rental_id)
  join language l using(language_id) 
  join film_category fc using(film_id) 
  join category c using(category_id) 
where  
  i.inventory_id IS NULL 
group by 
  f.film_id, 
  f.title, 
  f.rating, 
  c.name, 
  f.release_year, 
  l.name 
order by 
  f.film_id



--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

select 
  s.staff_id, 
  count(p.payment_id) AS "Количество продаж", 
  case when count(p.payment_id) > 7300 then 'Да' else 'Нет' end as "Премия" 
from 
  staff s 
  join payment p USING (staff_id) 
group by 
  s.staff_id 
order by 
  s.staff_id





