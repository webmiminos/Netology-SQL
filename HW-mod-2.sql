--=============== МОДУЛЬ 2. РАБОТА С БАЗАМИ ДАННЫХ =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите уникальные названия городов из таблицы городов.
select distinct(city)
from city
order by city




--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания, чтобы запрос выводил только те города,
--названия которых начинаются на “L” и заканчиваются на “a”, и названия не содержат пробелов.
select distinct(city)
from city
where city ilike 'L%a' and city not like '% %'
order by city


--ЗАДАНИЕ №3
--Получите из таблицы платежей за прокат фильмов информацию по платежам, которые выполнялись 
--в промежуток с 17 июня 2005 года по 19 июня 2005 года включительно, 
--и стоимость которых превышает 1.00.
--Платежи нужно отсортировать по дате платежа.
select *
from payment 
where (payment_date::date between '2005-06-17' and '2005-06-19') and amount > 1
order by payment_date 


--ЗАДАНИЕ №4
-- Выведите информацию о 10-ти последних платежах за прокат фильмов.
select *
from payment
where amount > 0
order by payment_date desc,payment_id desc
limit 10
-- т.к. у платежей одно время и дата, по логике я понял что надо сортировать по payment id т.к
--это номер операции(по порядку)!!!!



--ЗАДАНИЕ №5
--Выведите следующую информацию по покупателям:
--  1. Фамилия и имя (в одной колонке через пробел)
--  2. Электронная почта
--  3. Длину значения поля email
--  4. Дату последнего обновления записи о покупателе (без времени)
--Каждой колонке задайте наименование на русском языке.
select 
concat_ws(' ', last_name, first_name) as "Фамилия и имя",--1
email as "Электронная почта",--2
char_length(email) as "длинна поля email",--3
last_update::date as "Дата последнего обновления"--4
from customer 





--ЗАДАНИЕ №6
--Выведите одним запросом только активных покупателей, имена которых KELLY или WILLIE.
--Все буквы в фамилии и имени из верхнего регистра должны быть переведены в нижний регистр.
select customer_id,store_id,lower(first_name),lower(last_name),email,address_id,activebool,create_date,
last_update,active
from customer
where active = 1 and ((first_name like'KELLY') or (first_name like'WILLIE'))




--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите информацию о фильмах, у которых рейтинг “R” и стоимость аренды указана от 
--0.00 до 3.00 включительно, а также фильмы c рейтингом “PG-13” и стоимостью аренды больше или равной 4.00.
select *
from film
where (rating::text ilike 'R' and (rental_rate between 0 and 3)) or (rating::text ilike 'PG-13' and (rental_rate >= 4))
order by rental_rate 



--ЗАДАНИЕ №2
--Получите информацию о трёх фильмах с самым длинным описанием фильма.

select film_id,title,description,char_length(description) as disc_lenght,release_year,language_id,original_language_id,rental_duration,rental_rate,length,replacement_cost,rating,last_update,special_features,fulltext
from film 
order by disc_lenght desc
limit 3




--ЗАДАНИЕ №3
-- Выведите Email каждого покупателя, разделив значение Email на 2 отдельных колонки:
--в первой колонке должно быть значение, указанное до @, 
--во второй колонке должно быть значение, указанное после @.
select email,
split_part(email, '@', 1) as перфикс,
split_part(email, '@', 2) as домен
from customer




--ЗАДАНИЕ №4
--Доработайте запрос из предыдущего задания, скорректируйте значения в новых колонках: 
--первая буква строки должна быть заглавной, остальные строчными.
select email,
initcap(lower(split_part(email, '@', 1))) as перфикс,
initcap(lower(split_part(email, '@', 2))) as домен
from customer


