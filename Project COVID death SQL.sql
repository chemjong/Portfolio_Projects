-- Purpose
	-- The purpose of this project is to complete a data analysis project using SQL. 
	-- The project includes data exploration, setting up questions, designing solutions for the problems and delivering the insights using PowerPoint. 

-- Results
	-- I was only able to achieve 30% of the project goals. Below are the reasons:
	-- The total allocated time for this project was only limited to 6 hours, which was spread out into several weeks. //My time is scarce – many projects are fighting for my time therefore it was the best I could do.
	-- It’s a new dataset therefore data exploration and setting up questions took longer than I expected. //I think this is the most important section of the project. You cannot do a data analysis project if you don’t understand the data set. Setting up questions are NOT easy. They have to make sense and solution should be within the limitation of the dataset. For e.g. finding just the number of countries in the dataset doesn’t mean anything. 


-- Data source
	--https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/CovidDeaths.xlsx
	--https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/CovidVaccinations.xlsx

-- Reference: 
	-- I got the idea of using the covid data from Alex the Analyst. However, my project codes and outcomes is very different.
	--https://www.youtube.com/watch?app=desktop&v=qfyynHBFOsM&ab_channel=AlexTheAnalyst

--  Question #1
	-- 1. Show the top 10 countries with highest confirmed covid-19 cases per population. Use the most recent cases for each countries.

-- Question #2 (NOT done)
	-- 2.	Of those top 10 countries with highest confirmed Covid-19 cases per population, show:
		-- a.	Share of people_fully_vaccinated per population.
		-- b.	Share of people who received at least one dose of vaccination. people_vaccinated
		-- c.	Share of deaths attributed to Covid-19. total_deaths


-- Solution Design #1

--1.	Show the top 10 countries with highest confirmed covid-19 cases per population. Use the most recent cases for each countries
--a.	From CovidVac table inner join Coviddeath table on iso_code and date
--i.	Arrange by iso code and date
--ii.	Insert Row number grouped by iso
--1.	  ROW_NUMBER() OVER(PARTITION BY recovery_model_desc ORDER BY name ASC)  AS Row#
--iii.	Select the most recent total_cases for each country
--1.	Remove any NULL in total_cases
--iv.	Select the top 10 countries 

--Create Master_table - From CovidVac table inner join Coviddeath table on iso_code and date

--Note: Not a good idea to rename the original columns. This must practice must be avoided in the future.

--EXEC sp_rename 'dbo.CovidDeaths.iso_code', 'iso_code_dth', 'COLUMN';
--EXEC sp_rename 'dbo.CovidDeaths.date', 'date_dth', 'COLUMN';
--EXEC sp_rename 'dbo.CovidDeaths.continent', 'continent_dth', 'COLUMN';
--EXEC sp_rename 'dbo.CovidDeaths.location', 'location_dth', 'COLUMN';

-- Create a master_cohort table.
-- Join these two tables on iso codes - CovidVaccinations & CovidDeaths
-- Insert row numbers. Group by location.
-- Insert row numbers for all observation.

DROP TABLE IF EXISTS master_cohort;
select *,
	ROW_NUMBER() over (partition by location order by date asc) as orders,
	ROW_NUMBER() over (order by location, date) as rownum
	into master_cohort
	from dbo.CovidVaccinations vacs
	inner join dbo.CovidDeaths deaths
	on vacs.iso_code = deaths.iso_code_dth and
	vacs.date = deaths.date_dth;

--The issue with above is that date column is NOT in date format therefore the order by is NOT giving the result I want.
-- I want to permanently sort the master_chort table by location, date but it is complicated. I won't spend time on this for now.

-- The below result shows that location variable contains continents when continent variable is NULL.
-- We only want to analyze contunries NOT continents.

select distinct location, continent from master_cohort order by continent;


-- select the most recent data for each country.
-- Exclude continent

DROP TABLE IF EXISTS lastDateData;
with tmp_no_null as
	(
		select *
		from dbo.master_cohort
		where continent is not null
	),
top_row as
	(
		select MAX(rownum) as rownums
		from tmp_no_null
		group by location
	)
select *
into lastDateData
from dbo.master_cohort base
inner join top_row tops
on base.rownum = tops.rownums
order by location, tops.rownums;

--select top 10 countires with highest total cases PER POPULATION (there are 210 in the lastDateDate table)

DROP TABLE IF EXISTS top10case;
with caseperpop as
	(
		select location, total_cases, population, ((total_cases/population) * 100) as totalCasePerHund, continent
		from dbo.lastDateData
	)
select top 10 totalCasePerHund, location, total_cases, population
into dbo.top10case
from caseperpop
order by totalCasePerHund desc;



-- Other notes:

--•	We have location’s ISO code
--•	Metrics could be aggregated on months instead of daily.
--•	Interesting variables for reporting:
	--o	Total cases
	--o	Total deaths
	--o	Breakdown via age group and sex
	--o	Cases admitted to hospital
	--o	cumulative number of confirmed deaths
	--o	Biweekly deaths: where are confirmed deaths increasing or falling?

--•	CovidDeaths.xlsx has interesting variables
	--o	population
	--o	total_cases
	--o	new_cases
--•	Share of people only partly vaccinated = people_vaccinated/population
--•	Check the latest data available for each countries.
	--o	Key variables data may not be available.
	--o	Presence of NULL values may differ from countries.
--•	Calculate Cumulative total
	--o	new_cases
	--o	new_deaths
--•	Already cumulative total
	--o	Icu_patients
	--o	people_vaccinated
	--o	people_fully_vaccinated
--•	Other interesting variables
	--o	stringency_index
	--o	extreme_poverty
	--o	human_development_index
