-- Test if sucessfully imported
Select *
From PortfolioProject..Covid_Deaths
where continent is not null
order by 3,4

--Select data which is going to be used
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..Covid_Deaths
where continent is not null
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows current, highest chance of dying of COVID-19 in 2021 for each country
Select location, population, max(total_cases) as HighestCases, max((total_deaths/total_cases)*100) as Death_Percentage
From PortfolioProject..Covid_Deaths
where continent is not null
and date > '20210101'
group by location, population
order by Death_Percentage desc
-- Middle East, Latinamerica and parts of Asia are high-risk countries in 2021

--When was the highest COVID-death-rate in Denmark?
Select date, max(total_cases) as HighestCases, max((total_deaths/total_cases)*100) as Death_Percentage
From PortfolioProject..Covid_Deaths
where continent is not null
and location like 'Denmark'
group by date
order by Death_Percentage desc
-- 05.05.2020 had the highest COVID-death-rate in Denmark with 5%

-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID in Denmark
Select location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..Covid_Deaths
where location like 'Denmark'
order by 1,2
-- Currently at 5,6% in Denmark

--Which location is currently the riskiest to catch Covid? Must be countries with highest infection rate compared to population.
Select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population)*100) as PercentPopulationInfected
From PortfolioProject..Covid_Deaths
where continent is not null
and date = '20210805'
group by location, population
order by PercentPopulationInfected desc
-- Andorra and the Seychelles should be avoided this holiday season. 
-- And interestingly enough, there are a lot of Eurioean places in the top 10

-- Looking at Countries with Highest Death Count per Population
Select location, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..Covid_Deaths
where continent is not null
group by location
order by TotalDeathCount desc
--- USA, Brazil and India in Top 3

-- Now break it down to continents
Select location, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..Covid_Deaths
where continent is null
group by location
order by TotalDeathCount desc
-- Europe on first place

-- Let's look at the global numbers
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(New_Cases)*100 as Deathpercentage
From PortfolioProject..Covid_Deaths
where continent is not null
order by 1,2
-- 2,12% of people worldwide that got infected actually died

-- Create Temp Table with CTE, then join Tables, look at Total Population vs Vaccinations and create rolling sum of vaccinated pop
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location order by dea.location,
dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Temp Table
Drop Table if exists #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location order by dea.location,
dea.Date) as RollingPeopleVaccinated
From PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Creating view to store data for visualizations
drop view PercentPopulationVaccinated

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location order by dea.location,
dea.Date) as RollingPeopleVaccinated
From PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null