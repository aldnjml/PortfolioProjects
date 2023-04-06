-- Select all data from CovidDeaths table and sort by total_cases and new_cases
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY total_cases, new_cases;

-- Select data to use for analysis and sort by location and date
SELECT Location, date, total_cases, new_cases, total_deaths, Population 
FROM PortfolioProject..CovidDeaths
ORDER BY Location, date;

-- Looking at Total cases vs Total Deaths
-- Shows the likelihood of dying if you contract Covid in each country
SELECT Location, date, total_cases, total_deaths, 
    CASE 
        WHEN total_cases = 0 THEN 0
        ELSE CAST(total_deaths AS decimal(18,2))/CAST(total_cases AS decimal(18,2))*100 
    END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY Location, date;

-- Looking at the Total Cases vs Population
-- Shows what percentage of population got Covid in each country
SELECT Location, date, total_cases, Population, 
    CASE 
        WHEN Population = 0 THEN 0
        ELSE CAST(total_cases AS decimal(18,2))/CAST(Population AS decimal(18,2))*100 
    END AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY Location, date;

-- Looking at Countries with Highest Infection Rate compared to Population
SELECT Location, MAX(total_cases) AS HighestInfectionCount, 
    MAX((CAST(total_cases AS decimal(18,2))/CAST(Population AS decimal(18,2)))*100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY Location;

-- Showing countries with Highest Death Count per Population
SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Let's break things down by continent

-- Showing the continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global Numbers 
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, 
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE SUM(cast(new_deaths as int))/SUM(new_cases)*100 
    END AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date 
ORDER BY date;

-- Total Cases
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, 
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE SUM(cast(new_deaths as int))/SUM(new_cases)*100 
    END AS DeathPercentage 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;

-- Looking at Total Population vs Vaccinations 
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       CONVERT(BIGINT, vac.new_vaccinations) AS Vaccinations,
       SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
	 --  , (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea 
JOIN PortfolioProject..CovidVaccinations vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
    AND vac.new_vaccinations IS NOT NULL -- exclude null values
ORDER BY 1, 2, 3;


-- USE CTE

WITH PopVsVacc (Continent, Location, Date, Population, New_Vaccinations, RollingPopulation, RollingPeopleVaccinated)
AS
(
	SELECT 
		dea.continent, 
		dea.location, 
		dea.date, 
		dea.population,
		vac.new_vaccinations,
		SUM(dea.population) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPopulation,
		SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
	FROM 
		PortfolioProject..CovidDeaths dea
		JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE
		dea.continent IS NOT NULL
)
SELECT 
	Continent, 
	Location, 
	Date, 
	Population, 
	RollingPopulation,
	New_Vaccinations, 
	RollingPeopleVaccinated
FROM 
	PopVsVacc
ORDER BY 
	Location, 
	Date;




-- TEMP TABLE 
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime, 
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea 
    JOIN PortfolioProject..CovidVaccinations vac 
        ON dea.location = vac.location
        AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL 
    AND vac.new_vaccinations IS NOT NULL -- exclude null values
ORDER BY 
    1, 
    2, 
    3;
