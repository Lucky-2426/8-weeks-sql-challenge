-- Active: 1706953706370@@localhost@3306@foodie_fi
-- Distinct customer_id in the dataset

SELECT count(distinct(customer_id)) AS 'distinct customers'
FROM subscriptions;
	

--Selecting the following random customer_id's from the subscriptions table to view their onboarding journey.
--Checking the following customer_id's : 1,21,73,87,99,193,290,400

---------  Customer 1

SELECT customer_id,
       plan_id,
       plan_name,
       start_date
FROM subscriptions
JOIN plans USING (plan_id)
WHERE customer_id =1;


/*Customer started the free trial on 1 August 2020  
They subscribed to the basic monthly during the seven day the trial period to continue the subscription*/

---------  Customer 21

```sql
SELECT customer_id,
       plan_id,
       plan_name,
       start_date
FROM subscriptions
JOIN plans USING (plan_id)
WHERE customer_id =21;



- Customer started the free trial on 4 Feb 202 and subscribed to the basic monthly during the seven day the trial period to continue the subscription
- They then upgraded to the pro monthly plan after 4 months
- Customer cancelled their subscription and churned on 27 September 2020 


---------  Customer 73

sql
SELECT customer_id,
       plan_id,
       plan_name,
       start_date
FROM subscriptions
JOIN plans USING (plan_id)
WHERE customer_id =73;


- Customer started the free trial on 24 March 2020 and subscribed to the basic monthly after the seven day the trial period to continue the subscription
- They then upgraded to the pro monthly plan after 2 months
- They then  upgraded to the pro annual plan in October 2020

---------  Customer 87

sql
SELECT customer_id,
       plan_id,
       plan_name,
       start_date
FROM subscriptions
JOIN plans USING (plan_id)
WHERE customer_id =87;

- Customer started the free trial on 8 August 2020 
- They may have chosen to continue with the pro monthly after the seven day the trial period
- They then upgraded to the pro annual plan in September 2020
***

---------  Customer 99

sql
SELECT customer_id,
       plan_id,
       plan_name,
       start_date
FROM subscriptions
JOIN plans USING (plan_id)
WHERE customer_id =99;

- Customer started the free trial on 5 December 2020
- They chose not to continue with paid subscription and decided to cancel on the last day of the trial period.
***

---------  Customer 290

sql
SELECT customer_id,
       plan_id,
       plan_name,
       start_date
FROM subscriptions
JOIN plans USING (plan_id)
WHERE customer_id =290;



- Customer started the free trial on 10 January 2020
- They subscribed to the basic monthly plan during the seven day the trial period to continue the subscription
``` 