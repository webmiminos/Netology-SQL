--Задание 1---------------------------------------------------------------------------------------------------------------------

select 
  count(*) as "колличество договоров" 
from 
  project 
where 
  extract(
    year 
    from 
      sign_date
  ) = 2023

--Задание 2-----------------------------------------------------------------------------------------------------------------------

select 
  sum(
    age( current_date,p.birthdate)
  ) as "сумма возрастов" 
from 
  employee e 
  left join person p using (person_id) 
where 
  extract(
    year 
    from 
      e.hire_date
  ) = 2022

--Задание 3-----------------------------------------------------------------------------------------------------------------------
-- правка :Из-за ложного подзапроса отсутствует выполнение условия: Если таких сотрудников несколько, выведите одного случайного
with min_dates as (--вычисляет минимальную дату приема среди всех сотрудников с фамилией, начинающейся на "м" и длиной 8 символов
    select 
        min(e.hire_date) as min_hire_date 
    from 
        employee e 
        left join person p using (person_id) 
    where 
        p.last_name like 'М_______'
)
select 
    concat(p.first_name, ' ', p.last_name) as "Имя Фамилия",
    e.hire_date as "Дата приема"
from 
    employee e 
    left join person p using (person_id),
    min_dates 
where 
    p.last_name like 'М_______' 
    and e.hire_date = min_dates.min_hire_date
order by random()--вывод случайного 
limit 1-- одного

-- Задание 4----------------------------------------------------------------------------------------------------------------------
-- Проверять массив на null нет смысла.Потеряли руководителей проектов.
select 
  coalesce(
    avg(
      extract(
        year from age(current_date, p.birthdate)
      )
    ), 
    0
  ) as "Среднее значение возраста"
from 
  employee e
  left join person p using (person_id)
  left join project pr_manager on e.employee_id = pr_manager.project_manager_id--пытаемся найти проекты, где сотрудник — руководитель
  left join project pr_employee on e.employee_id = any(pr_employee.employees_id)--пытаемся найти проекты, где сотрудник — участник
where 
  e.dismissal_date is not null
  and pr_manager.project_id is null --не руководитель
  and pr_employee.project_id is null -- не исполнитель


 -- Задание 5-------------------------------------------------------------------------------------------------
--правка Вопрос о полученных платежах, а не всех
with cstr_if as (
  -- сводная инфа по клиенту, сделать сразу выборку нужных нам клиентов
  select 
    customer_id 
  from 
    customer 
    join address using (address_id) 
    join city ct using (city_id) 
    join country cou using (country_id) 
  where 
    ct.city_name = 'Жуковский' 
    and cou.country_name = 'Россия'
), 
spmp as (
  -- группировка и суммирование по проекту, дабы избежать джоина по неуникальному значению
  select 
    project_id, 
    sum(amount) as total_amount 
  from 
    project_payment
  where 
    fact_transaction_timestamp is not null -- добалена выборка по фактическим платежам
  group by 
    project_id
) 
select 
  sum(spmp.total_amount) as "сумма платежей" 
from 
  cstr_if 
  join project p using (customer_id) 
  join spmp using (project_id)

  

 -- Задание 6------------------------------------------------------------------------------------------------------
  -- правка Отсутствует работа со стоимостью проектов

with prem as (
  select 
    p.project_id, 
    p.project_manager_id,
    round(
      p.project_cost * 0.01,  -- 1% от стоимости проекта + работа со стоимостью проекта
      2
    ) as premia 
  from 
    project p
  where 
    p.status = 'Завершен'
), 
manager_bonus as (
  select 
    per.person_id, 
    concat(per.last_name, ' ', per.first_name, ' ', per.middle_name) as ФИО, 
    sum(prem.premia) as total_premia 
  from 
    prem
    join employee em on prem.project_manager_id = em.employee_id 
    join person per on em.person_id = per.person_id
  group by 
    per.person_id
) 
select 
  * 
from 
  manager_bonus 
where 
  total_premia = (
    select 
      max(total_premia) 
    from 
      manager_bonus
  )

  

-- Задание 7  ------------------------------------------------------------------------------------------------------
--правка: Отсутствует получение только тех дат, которые идут после преодоления отметки в 30000000, получаете все даты подряд
  with t1 as (
  select 
    plan_payment_date,
    date_trunc('month', plan_payment_date) as month,
    sum(amount) over (
      partition by date_trunc('month', plan_payment_date)
      order by plan_payment_date
      rows between unbounded preceding and current row
    ) as running_total
  from 
    project_payment
  where 
    payment_type = 'Авансовый'
),
t3 as (
  select 
    month,
    min(plan_payment_date) as threshold_date
  from 
    t1
  where 
    running_total > 30000000
  group by 
    month
)
select 
  t1.plan_payment_date as "дата платежа",
  t1.running_total as "накопительный итог"
from 
  t1
  join t3 td on t1.month = td.month --фильтруются только даты этого же месяца , которые идут после (и включая) дату превышения
where 
  t1.plan_payment_date >= td.threshold_date
order by 
  t1.plan_payment_date

-- Задание 8-----------------------------------------------------------------------------------------------------------------
--правка :Потеряли ставки сотрудников
  with recursive r as (
  -- стартовая часть 
select 
    *, 
    0 as level 
  from 
    company_structure s 
  where 
    unit_id = 17 
  union all 
  -- рекурсивная часть
  select 
    s.*, 
    level + 1 as level 
  from 
    r 
    join company_structure s on r.unit_id = s.parent_id
) 
select 
  sum(coalesce(ep.salary, 0) * coalesce(ep.rate, 1)) as ФОТ -- нашласть ставка в rate
from 
  r 
  join position p using (unit_id) 
  join employee_position ep using (position_id);
  


--Задание 9 ---------------------------------------------------------------------------------------------------------------------
-- правка В задании не сказано о получении суммы скользящих на каждый год в отдельности.
--В задании не сказано о получении скользящих средних на каждый год в отдельности.
--Отсутствует получение стоимости проектов на каждый год

with step1 as (--Сделайте сквозную нумерацию фактических платежей по проектам 
			   --на каждый год в отдельности в порядке даты платежей
  select 
    project_id,
    amount,
    fact_transaction_timestamp,
    extract(year from fact_transaction_timestamp) as payment_year,
    row_number() over (
      partition by extract(year from fact_transaction_timestamp)
      order by fact_transaction_timestamp
    ) as payment_row_number
  from 
    project_payment
  where 
    fact_transaction_timestamp is not null
),
step2 as (--Выведите скользящее среднее размеров платежей с шагом 2 строки назад и 2 строки вперед от текущей
  select -- учтена правка без указания года
    *,
    avg(amount) over (
      order by fact_transaction_timestamp
      rows between 2 preceding and 2 following 
    ) as moving_average
  from 
    step1
  where 
    payment_row_number % 5 = 0 -- платежи с номерами, кратными 5
),
step3 as (--Получите сумму скользящих средних значений(округлил)
  select -- учтено без года
    round(sum(moving_average), 2) as total_moving_average
  from 
    step2
),
step4 as (--Получите сумму проектов на каждый год
  select 
    extract(year from sign_date) as project_year,
    sum(project_cost) as total_project_cost
  from 
    project
  group by 
    extract(year from sign_date)
)
select --Выведите в результат  
  p.project_year as год,--значение года (годов) и
  p.total_project_cost as сумма_проектов,--сумму проектов
  s.total_moving_average as сумма скользящих
  from 
  step4 p,
  step3 s 
where 
  p.total_project_cost < coalesce(s.total_moving_average, 0)--где сумма проектов меньше, чем сумма скользящих средних значений
order by 
  p.project_year;




---Задание 10 ----------------------------------------------------------------------------------------------------

create materialized view project__report as with last_payments as (
  -- дата последней фактической оплаты по проекту
  select 
    p.project_id, 
    max(pay.fact_transaction_timestamp) as last_payment_date 
  from 
    project p 
    join project_payment pay using(project_id) 
  where 
    fact_transaction_timestamp is not null 
  group by 
    p.project_id 
  order by 
    p.project_id
), 
last_payment_details as (
  -- размер последней фактической даты по проекту
  select 
    lp.project_id, 
    lp.last_payment_date, 
    pay.amount as last_payment_amount 
  from 
    last_payments lp 
    join project_payment pay on pay.project_id = lp.project_id 
    and pay.fact_transaction_timestamp = lp.last_payment_date 
  where 
    fact_transaction_timestamp is not null 
  order by 
    project_id
), 
customer_work_types_agg as (
  -- названия работ в виде строки по каждому клиенту, названия клиентов
  select 
    c.customer_id, 
    c.customer_name, 
    string_agg(
      distinct tow.type_of_work_name, ', '
    ) as work_types 
  from 
    customer c 
    join customer_type_of_work ctow using (customer_id) 
    join type_of_work tow using (type_of_work_id) 
  group by 
    c.customer_id, 
    c.customer_name
), 
manager_project as (
  -- руководители
  select 
    project_id, 
    project_manager_id, 
    pr.full_fio 
  from 
    project p 
    join employee e on p.project_manager_id = e.employee_id 
    join person pr using (person_id) 
  order by 
    project_manager_id
) 
select 
  p.project_id as "идентификатор проекта", 
  p.project_name as "название проекта", 
  lpd.last_payment_date :: date as "дата последней фактической оплаты по проекту", 
  lpd.last_payment_amount as "размер последней фактической оплаты", 
  mp.full_fio as "ФИО руководителей проектов", 
  cwta.customer_name as "Названия контрагентов", 
  cwta.work_types as "названия типов работ" 
from 
  project p 
  left join last_payment_details lpd using (project_id) 
  left join manager_project mp using (project_id) 
  left join customer_work_types_agg cwta using (customer_id) 
order by 
  p.project_id






