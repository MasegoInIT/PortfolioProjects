-- Looking at Total Cases vs Total Deaths
SELECT Location, 
       date, 
       total_cases, 
       total_deaths, 
       (COALESCE(total_deaths / total_cases)*100) AS DeathPercentage
FROM covid_deaths
WHERE location ILIKE '%south africa%'
ORDER BY 1, 2;

-- Looking at Total Cases vs Population
-- Shows what percentage of the population got covid
SELECT Location, 
       date, 
       total_cases, 
       population, 
       (total_cases *100 / population) AS DeathPercentage
FROM covid_deaths
WHERE location ILIKE '%south africa%'
ORDER BY 1, 2;

--Looking at which countries have the highest infection Rate compared to Population
SELECT Location, Population,
	MAX(total_cases) AS HighestInfectionCount,
	MAX(total_cases * 100 / Population) AS PercentagePopulationInfected
FROM covid_deaths
	GROUP BY location, Population
ORDER BY PercentagePopulationInfected DESC;

--Showing countruies with the highest Death Count per Population
SELECT Location,
	COALESCE (MAX(CAST(total_deaths AS int)),0) AS TotalDeathCount
	FROM covid_deaths
	WHERE continent IS NOT NULL
	GROUP BY Location
ORDER BY TotalDeathCount DESC;

--GLOBAL NUMBERS
SELECT date, 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE (SUM(CAST(new_deaths AS int)) * 100) / SUM(new_cases)
    END AS DeathPercentage
FROM covid_deaths
--WHERE location ILIKE '%south africa%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, total_cases;

--Looking at Total Population vs Vaccinations

SELECT * FROM covid_vaccination AS vac
JOIN covid_deaths AS dea
ON dea.location = vac.location
AND dea.date = vac.date;

SELECT dea.continent AS continent,
       dea.location AS location,
       dea.date AS date,
       vac.new_vaccinations AS new_vaccinations,
       dea.population AS population
FROM covid_vaccination AS vac
JOIN covid_deaths AS dea
ON dea.location = vac.location
AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
ORDER BY dea.continent, dea.location, dea.date;

SELECT dea.continent AS continent,
       dea.location AS location,
       dea.date AS date,
       vac.new_vaccinations AS new_vaccinations,
       dea.population AS population,
	SUM(CAST(vac.new_vaccinations as int)) 
	OVER (Partition by dea.Location ORDER BY dea.Location, dea.date) AS RollingPeopleVaccinated
FROM covid_vaccination AS vac
JOIN covid_deaths AS dea
ON dea.location = vac.location
AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
ORDER BY 1,2; 

--Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac AS (
    SELECT dea.continent AS continent,
           dea.location AS location,
           dea.date AS date,
           vac.new_vaccinations AS new_vaccinations,
           dea.population AS population,
           SUM(CAST(vac.new_vaccinations AS int))
           OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM covid_vaccination AS vac
    JOIN covid_deaths AS dea
    ON dea.location = vac.location
    AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *
FROM PopvsVac
ORDER BY continent, location, date;

--Using Temp Table to perform Calculation on Partition By in previous query
-- Creating the table with correct column definitions
CREATE TABLE PercentagePopulationVaccinated
(
    Continent varchar(255),
    Location varchar(255),
    Date timestamp, 
    Population numeric,
    new_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

-- Inserting data into the created table
INSERT INTO PercentagePopulationVaccinated (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
SELECT dea.continent AS continent,
       dea.location AS location,
       dea.date AS date,
       vac.new_vaccinations AS new_vaccinations,
       dea.population AS population,
       SUM(CAST(vac.new_vaccinations AS int))
       OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_vaccination AS vac
JOIN covid_deaths AS dea
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Selecting data from the created table to view the result
SELECT *
FROM PercentagePopulationVaccinated
ORDER BY continent, location, date;

--Creating view to store data for vizualisations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS int)) 
           OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
       --, (SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / dea.population) * 100 AS PercentageVaccinated
FROM covid_deaths dea
JOIN covid_vaccination vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT * FROM PercentPopulationVaccinated;





