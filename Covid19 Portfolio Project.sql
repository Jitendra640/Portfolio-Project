SELECT * FROM CovidDeaths 
ORDER BY 3,4

--SELECT * FROM Vaccination
--ORDER BY 3,4

--lets select the data that we are going to use

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM CovidDeaths 
ORDER BY 1,2

--looking at total cases vs total deaths

SELECT location,date,total_cases,total_deaths, ROUND((total_deaths/total_cases)*100,2) as DeathPercentage
FROM CovidDeaths 
WHERE location LIKE '%states%'
ORDER BY 1,2

--looking at total cases Vs population
--Shows what percentage of population of india got covid 
SELECT location,date,total_cases,population, (total_cases/population)*100 AS CasesPercentage 
FROM CovidDeaths
WHERE location like '%india%'

--looking contries with highest infection rates compared to population
SELECT location,population,MAX(total_cases) as HighlyInfected,
MAX(total_cases/population)*100 AS InfectedPercentage 
FROM CovidDeaths
GROUP BY location,population
ORDER BY InfectedPercentage DESC


--due to some accuracy problem, we have to change the data type of total_deaths column from varchar to integer

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths int

--Countries With Highest Deathpercentage

SELECT location,population, MAX(total_deaths) as DeathCount,
MAX(total_deaths/population)*100 as DeathPercentage FROM CovidDeaths
GROUP BY location,population 
ORDER BY 4 DESC

--Countries With highest Death Counts

SELECT location, MAX(total_deaths) as DeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

-- Lets break the things by continent
SELECT continent,MAX(total_deaths) AS DeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC


ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths int




--GLOBAL NUMBERS
SELECT date, 
       SUM(new_cases) AS TotalNewCases, 
       SUM(new_deaths) AS TotalDeaths, 
       (SUM(new_deaths) / SUM(new_cases)) * 100 AS TotalDeathPer
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY TotalDeathPer DESC;


--Total World Population deaths cases and death percentage

SELECT 
       SUM(new_cases) AS TotalNewCases, 
       SUM(new_deaths) AS TotalDeaths, 
       (SUM(new_deaths) / SUM(new_cases)) * 100 AS TotalDeathPer
FROM CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY TotalDeathPer DESC;

--looking at total population vs vaccination

ALTER TABLE vaccination
ALTER COLUMN new_vaccinations int

SELECT cd.continent,cd.location,cd.date,cd.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER (PARTITION BY cd.location
ORDER BY cd.location,cd.date) as RollingPeopleVaccinated
FROM
--,(RollingPeopleVaccinated/population)*100 --We can use this for this operation, we can use temp table or CTE for that
CovidDeaths AS cd
JOIN Vaccination AS v
ON cd.location = v.location
AND cd.date = v.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3


--USE CTE

WITH PopvsVac (continent,location,date,population,new_vacciations,RollingPeopleVaccinated)
AS
(SELECT cd.continent,cd.location,cd.date,cd.population, v.new_vaccinations,
SUM(v.new_vaccinations) OVER (PARTITION BY cd.location
ORDER BY cd.location,cd.date) as RollingPeopleVaccinated
FROM
--,(RollingPeopleVaccinated/population)*100 --We can use this for this operation, we can use temp table or CTE for that
CovidDeaths AS cd
JOIN Vaccination AS v
ON cd.location = v.location
AND cd.date = v.date
WHERE cd.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac


--TEMP table

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join Vaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Creating view to store data for later viz.

CREATE VIEW PercentPopulationVaccinated
as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join Vaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3


SELECT * FROM PercentPopulationVaccinated




