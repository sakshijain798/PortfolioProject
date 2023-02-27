select *
from PortfolioProject..CovidDeaths
where continent is not null
order  by 3,4

-- Select Data that we are going to be starting with

select location, date,total_cases,new_cases,total_deaths, population from 
PortfolioProject..CovidDeaths
order by 1,2

-- Total Cases vs Total Deaths

select location, date,total_cases,new_cases,total_deaths, (total_deaths/total_cases)* 100 as DeathPercentage from 
PortfolioProject..CovidDeaths
order by 1,2

-- Shows likelihood of dying if you contract covid in USA

select location, date,total_cases,total_deaths, (total_deaths/total_cases)* 100 as DeathPercentage from 
PortfolioProject..CovidDeaths
where location like '%state%'
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

select location, date,total_cases,population, (total_cases/population)* 100 as PercentPopulationInfected from 
PortfolioProject..CovidDeaths
--where location like '%state%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population
select location,population, max(total_cases) as HighestInfectionCount, max(total_cases/population)* 100 as PercentPopulationInfected from 
PortfolioProject..CovidDeaths

group by location,population
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population
select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is null
group by location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS
select  sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,
sum(cast(new_deaths as int))/sum(new_cases)*100   as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
--group by date
--order by date

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date ) as RollingPeopleVaccinated
from 
PortfolioProject..CovidDeaths dea
join
PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and 
dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

with PopvsVac (Continent, Location, Date, Population, New_Vaccination, RollingPeopleVaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date ) as RollingPeopleVaccinated
from 
PortfolioProject..CovidDeaths dea
join
PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and 
dea.date = vac.date
where dea.continent is not null
)

select *, (RollingPeopleVaccinated/Population)*100 from PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

drop table if exists #PercentPopulationVaccinated

create table #PercentPopulationVaccinated(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
Population numeric,
New_Vaccination numeric, 
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

select (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

create view PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select * from PercentPopulationVaccinated