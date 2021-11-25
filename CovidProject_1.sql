-- Selecting data

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where continent is not null
order by 1, 2

-- Looking at total deaths VS total cases
-- This table shows the likelyhood of dying if you caught it in Brazil

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
where continent is not null and location like 'Brazil'
order by 1, 2

-- Looking at total cases VS population
-- Shows likelyhood of catching it if you are in Brazil

select location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
from CovidDeaths
where continent is not null and location like 'Brazil'
order by 1, 2

-- Looking at countries with highest infection rate with respect to its population size

select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as ContaminationPercentage
from CovidDeaths
where continent is not null
group by location, population
order by 4 desc

-- Breaking down by continent
-- Continents with highest death counts

select continent, max(cast(total_deaths as int)) as HighestDeathCount
from CovidDeaths
where continent is not null
group by continent
order by 2 desc

-- Global numbers(1)

select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage
from CovidDeaths
where continent is not null
order by 1, 2

-- Deaths by continent(2)

select location, SUM(cast(new_deaths as int)) as TotalDeathCount
from CovidDeaths
where continent is null 
and location not in ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
group by location
order by TotalDeathCount desc

-- Looking at countries with highest death count (3)

select location, population, max(cast(total_deaths as int)) as HighestDeathCount, max((total_cases/population))*100 as PercentPopulationInfected
from CovidDeaths
where location not in ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
group by location, population
order by 4 desc

-- Looking at countries with highest death count over time (4)

select location, population, date, max(cast(total_deaths as int)) as HighestDeathCount, max((total_cases/population))*100 as PercentPopulationInfected
from CovidDeaths
group by location, population, date
order by 5 desc

-- Deaths by income range(5)

select location as IncomeRange, SUM(cast(new_deaths as int)) as TotalDeathCount
from CovidDeaths
where continent is null 
and location not in ('World', 'European Union', 'International', 'Europe', 'Asia', 'South America', 'North America', 'Africa', 'Oceania')
group by location
order by TotalDeathCount desc

-- Total population VS Total vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths as dea
join CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- CTE

with PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as (
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths as dea
join CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/Population) * 100 as PercentageOfVaccinatedPeople
from PopvsVac
order by 2

-- TEMP TABLE

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths as dea
join CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *, (RollingPeopleVaccinated/Population)*100 as PercentageOfVaccinatedPeople
from #PercentPopulationVaccinated
order by 1, 2, 3

-- Creating view to store date for later visualizations

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths as dea
join CovidVaccinations as vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null