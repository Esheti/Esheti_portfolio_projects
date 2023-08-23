SELECT *
FROM ['covid deaths$']
ORDER BY 3,4

--SELECT *
--FROM ['covid vaccinations$']
--ORDER BY 3,4

--Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ['covid deaths$']
ORDER BY 1,2

--Looking at total cases vs total deaths
--shows likelihood of dying from covid infection in your country


ALTER TABLE ['covid deaths$']
ALTER COLUMN total_cases float;

ALTER TABLE ['covid deaths$']
ALTER COLUMN total_deaths float;


SELECT location, date, total_cases, total_deaths, (Total_deaths/Total_cases) * 100 AS DeathPercentage
FROM ['covid deaths$']
WHERE location LIKE '%states%'
ORDER BY 1,2

--looking at total cases vs population
--shows what percentage of population get covid

SELECT location, date, population, total_cases, (total_cases/population) * 100 AS PercentOfPopulationInfected
FROM ['covid deaths$']
--WHERE location LIKE '%states%'
ORDER BY 1,2

--looking at countries with highest infection rate compared to population.

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population) * 100 as PercentOfPopulationInfected
FROM ['covid deaths$']
GROUP BY location, population
ORDER BY PercentOfPopulationInfected DESC

--SHOWING COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM ['covid deaths$']
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM ['covid deaths$']
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


--SHOWING CONTINENT WITH HIGHEST DEATH COUNT PER POPULATION

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM ['covid deaths$']
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases), 0) * 100 AS DeathPercentage
FROM ['covid deaths$']
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases), 0) * 100 AS DeathPercentage
FROM ['covid deaths$']
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

--LOOKING AT TOTAL POPULATION VS VACCINATION

ALTER TABLE ['covid vaccinations$']
ALTER COLUMN new_vaccinations float;

SELECT CDA.continent, CDA.location, CDA.date, CDA.population, CVA.new_vaccinations, 
SUM(CVA.new_vaccinations) OVER (Partition by CDA.location order by CDA.location, CDA.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
FROM ['covid deaths$'] AS CDA JOIN ['covid vaccinations$'] AS CVA ON CDA.location = CVA.location AND CDA.date = CVA.date
WHERE CDA.continent IS NOT NULL
ORDER BY 2,3

--USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT CDA.continent, CDA.location, CDA.date, CDA.population, CVA.new_vaccinations, 
SUM(CVA.new_vaccinations) OVER (Partition by CDA.location order by CDA.location, CDA.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
FROM ['covid deaths$'] AS CDA JOIN ['covid vaccinations$'] AS CVA ON CDA.location = CVA.location AND CDA.date = CVA.date
WHERE CDA.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population) * 100 AS VacPopPercentage
FROM PopvsVac

--TEMP TABLE

drop table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT CDA.continent, CDA.location, CDA.date, CDA.population, CVA.new_vaccinations, 
SUM(CVA.new_vaccinations) OVER (Partition by CDA.location order by CDA.location, CDA.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
FROM ['covid deaths$'] AS CDA JOIN ['covid vaccinations$'] AS CVA ON CDA.location = CVA.location AND CDA.date = CVA.date
--WHERE CDA.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population) * 100 AS VacPopPercentage
FROM #PercentPopulationVaccinated


-- creating view to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT CDA.continent, CDA.location, CDA.date, CDA.population, CVA.new_vaccinations, 
SUM(CVA.new_vaccinations) OVER (Partition by CDA.location order by CDA.location, CDA.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population) * 100
FROM ['covid deaths$'] AS CDA JOIN ['covid vaccinations$'] AS CVA ON CDA.location = CVA.location AND CDA.date = CVA.date
WHERE CDA.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated
