
--- Looking at total Covid Cases vs Total Deaths
--- Shows likelihood of death if one contracts covid in that country

select 
	location, 
	date, 
	convert(float, total_cases) as total_cases, 
	total_deaths,	
	round((convert(float, total_deaths)/total_cases)*100, 2) death_percentage
from [Portfolio Project]..CovidDeaths
order by date desc;



--- Looking at Total Cases Vs. Population
--- Shows the percentage of population diagnosed with Covid

select 
	location, 
	date, 
	convert(float, total_cases) as total_cases, 
	population, 
	round((convert(float, total_cases)/population)*100, 2) percentage_population_infected
from [Portfolio Project]..CovidDeaths;


--- Looking at countries with the highest infection rate compared to the population

select 
	location, 
	max(convert(float, total_cases)) as highest_infection_count, 
	population, 
	round(max((convert(float, total_cases)/population))*100, 2) percentage_population_infected
from [Portfolio Project]..CovidDeaths
group by location, population
order by percentage_population_infected desc;


---Showing countries with highest death count per population

select 
	location,
	max(convert(int, total_deaths)) as total_deaths
from [Portfolio Project]..CovidDeaths
where continent is not null
group by location
order by total_deaths desc;


--- Breaking things down by Continent
--- Showing continents with the highest death count per population

select 
	continent,
	max(cast(total_deaths as int)) as total_deaths,
	max(population) as population,
	round((max(cast(total_deaths as int))/max(population)*100),4) as percentage_of_deaths
from [Portfolio Project].dbo.CovidDeaths
where continent is not null
group by continent
order by percentage_of_deaths desc


--- GLOBAL NUMBERS

select  
	sum(new_cases) as total_cases, 
	sum(new_deaths) as total_deaths,
	sum(new_deaths)/sum(new_cases)*100 death_percentage
from [Portfolio Project].dbo.CovidDeaths
where continent is not null;


--- Looking at Total Population vs Vaccinations, Running Total of new vaccinations per location (country)

select dt.continent, dt.location, dt.date, dt.population, vc.new_vaccinations,
	   sum(convert(float, vc.new_vaccinations)) over (partition by dt.location order by dt.location, dt.date) as rolling_people_vaccinated
from [Portfolio Project].dbo.CovidDeaths dt
join [Portfolio Project].dbo.CovidVaccinations vc on dt.location = vc.location and dt.date = vc.date
where dt.continent is not null
order by 2,3


--- Use CTE

With Population_Vs_Vaccinations as
(
	select dt.continent, dt.location, dt.date, dt.population, vc.new_vaccinations,
		sum(convert(float, vc.new_vaccinations)) over (partition by dt.location order by dt.location, dt.date) as rolling_people_vaccinated
	from [Portfolio Project].dbo.CovidDeaths dt
	join [Portfolio Project].dbo.CovidVaccinations vc on dt.location = vc.location and dt.date = vc.date
	where dt.continent is not null
)
select *,  round((rolling_people_vaccinated/population)*100,4) rolling_vaccinated_people_percentage
from Population_Vs_Vaccinations


-- Temp Table

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
	(continent nvarchar(255),
	 location nvarchar(255),
	 date datetime,
	 population numeric,
	 new_vaccinations numeric,
	 rolling_people_vaccinated numeric)

Insert into #PercentPopulationVaccinated
	select dt.continent, dt.location, dt.date, dt.population, vc.new_vaccinations,
	   sum(convert(float, vc.new_vaccinations)) over (partition by dt.location order by dt.location, dt.date) as rolling_people_vaccinated
	from [Portfolio Project].dbo.CovidDeaths dt
	join [Portfolio Project].dbo.CovidVaccinations vc on dt.location = vc.location and dt.date = vc.date
	where dt.continent is not null
--	order by 2,3

	select *,  (rolling_people_vaccinated/population)*100 as rolling_vaccinated_people_percentage
	from #PercentPopulationVaccinated


--- Creating View to store data for later visualizations

DROP VIEW IF EXISTS PercentPopulationVaccinatedView

Create View PercentPopulationVaccinatedView as
select dt.continent, dt.location, dt.date, dt.population, vc.new_vaccinations,
	   sum(convert(float, vc.new_vaccinations)) over (partition by dt.location order by dt.location, dt.date) as rolling_people_vaccinated
	from [Portfolio Project].dbo.CovidDeaths dt
	join [Portfolio Project].dbo.CovidVaccinations vc on dt.location = vc.location and dt.date = vc.date
	where dt.continent is not null
--	order by 2,3

select * from PercentPopulationVaccinatedView