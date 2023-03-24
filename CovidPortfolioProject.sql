-- This analysis will be using two tables: CovidDeaths and CovidVaccinations where
-- data will by analyze based on various factors including date, location, infections, 
-- deaths, and vaccinations

-- View sample for one table
SELECT *
FROM
	PortfolioProject..CovidDeaths
WHERE
--	continent is NOT NULL AND location like 'Asia'
	location like '%income%'
ORDER BY
	3, 4

SELECT date, people_vaccinated
FROM
	PortfolioProject..CovidVaccinations
WHERE
	people_vaccinated IS NOT NULL
GROUP BY
    date
ORDER BY
	1

-- CLEANING
-- Make sure the columns have correct and uniform datatype

-- ANALYSIS
-- Select Data that we are going to be using

SELECT 
	location, date, total_cases, new_cases, total_deaths, population
FROM
	PortfolioProject..CovidDeaths
WHERE 
	continent is NOT NULL			-- to isolate aggregated data from Asia, Europe, World, etc.
ORDER BY
	1, 2


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if a person contracts COVID in their country
SELECT
	location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS CountryDeathRate
FROM
	PortfolioProject..CovidDeaths
WHERE 
	continent is NOT NULL			-- to isolate aggregated data from Asia, Europe, World, etc.
	AND total_deaths IS NOT NULL
--WHERE
--	location LIKE 'Philippines'		-- shows sample data
ORDER BY
	1, 2


-- Looking at Total Cases vs Population by country
-- Shows the percentage of population that contracted COVID
SELECT
	location, date, total_cases, population, (total_cases / population)*100 AS CountryInfectionRate
FROM
	PortfolioProject..CovidDeaths
WHERE 
	continent is NOT NULL			-- to isolate aggregated data from Asia, Europe, World, etc.
ORDER BY
	1, 2


-- Looking at countries with the highest infection rate compared to the population by country
SELECT
	location, MAX(total_cases) AS highestInfectionCount, population, (MAX(total_cases) / population)*100 AS percentPopulationInfected
FROM
	PortfolioProject..CovidDeaths
WHERE 
	continent is NOT NULL			-- to isolate aggregated data from Asia, Europe, World, etc.
GROUP BY
	location, population
ORDER BY
	percentPopulationInfected DESC


-- Showing countries with the highest death count per population by country
SELECT
	location, MAX(total_deaths) AS totalDeathCountCountries
FROM
	PortfolioProject..CovidDeaths
WHERE 
	continent is NOT NULL			-- to isolate aggregated data from Asia, Europe, World, etc.
GROUP BY
	location, population
ORDER BY
	totalDeathCountCountries DESC


-- Showing highest death count per population by continent
SELECT
	location, MAX(total_deaths) AS totalDeathCountContinents
FROM
	PortfolioProject..CovidDeaths
WHERE 
	continent is NULL						-- to only get data from continents
	AND location NOT like '%income%'		-- to isolate data linked to income
	AND location NOT like '%union'			-- to isolate data from location European Union
	AND location NOT like 'world'			-- to isolate data from location World (can be compared to aggregate data for totalDeaths)
GROUP BY
	location
ORDER BY
	totalDeathCountContinents DESC

-- Show aggregate data for total deaths in the World
SELECT 
	SUM(totalDeathCountContinents)
FROM
	(SELECT
		location, MAX(total_deaths) AS totalDeathCountContinents
	FROM
		PortfolioProject..CovidDeaths
	WHERE 
		continent is NULL						-- to only get data from continents
		AND location NOT like '%income%'		-- to isolate aggregated data linked to income
		AND location NOT like '%union'			-- to isolate aggregated data tagged as European Union
		AND location NOT like 'world'
	GROUP BY
		location) t


-- Global numbers

-- Global infections
SELECT
		date, MAX(total_cases) AS maxCasesDate
	FROM
		PortfolioProject..CovidDeaths
	WHERE 
		continent is NULL			
		AND location like 'World'
		AND total_cases is NOT NULL
	GROUP BY
		date
	ORDER BY
		date

-- Global deaths
SELECT
		date, MAX(total_deaths) AS maxDeathsDate
	FROM
		PortfolioProject..CovidDeaths
	WHERE 
		continent is NULL			
		AND location like 'World'
		--AND total_deaths is NOT NULL
	GROUP BY
		date
	ORDER BY
		date

-- Global death rise
SELECT
		date, MAX(total_cases) AS maxCasesToDate, MAX(total_deaths) AS Deaths
	FROM
		PortfolioProject..CovidDeaths
	WHERE 
		continent is NULL			
		AND location like 'World'
		AND total_cases is NOT NULL
		--AND total_deaths is NOT NULL
	GROUP BY
		date
	ORDER BY
		date

-- Global Death Rate
SELECT
	date, maxCasesDate, maxDeathsDate, (maxDeathsDate/maxCasesDate)*100 AS GlobalDeathRate
FROM
	(SELECT
		date, MAX(total_cases) AS maxCasesDate, MAX(total_deaths) AS maxDeathsDate
	FROM
		PortfolioProject..CovidDeaths
	WHERE 
		continent is NULL			
		AND location like 'World'
		AND total_cases is NOT NULL
		AND total_deaths is NOT NULL
	GROUP BY
		date
		) t
ORDER BY
	date

-- Current Death Rate
SELECT
	maxCasesDate, maxDeathsDate, (maxDeathsDate/maxCasesDate)*100 AS GlobalDeathRate
FROM
	(SELECT
		MAX(total_cases) AS maxCasesDate, MAX(total_deaths) AS maxDeathsDate
	FROM
		PortfolioProject..CovidDeaths
	WHERE 
		continent is NULL			
		AND location like 'World'
		AND total_cases is NOT NULL
		AND total_deaths is NOT NULL
		) t

-- Total Population vs Vaccinations Per Country
SELECT
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS float)) 
		OVER 
		(PARTITION BY						-- to separate values by countries
			dea.location
		ORDER BY							-- to separate values when new_vaccinations are added by date
			dea.location, dea.date
		) AS RollingVaccinationsPerCountry
FROM
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
	ON
		dea.location = vac.location
		AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
ORDER BY
	2, 3

-- Using CTE
With PopVsVac (Continent, Location, Date, Population, NewVaccinations, RollingVaccinationsPerCountry)
as
	(
	SELECT
		dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS float)) 
			OVER 
			(PARTITION BY						-- to separate values by countries
				dea.location
			ORDER BY							-- to separate values when new_vaccinations are added by date
				dea.location, dea.date
			) AS RollingVaccinationsPerCountry
	FROM
		PortfolioProject..CovidDeaths dea
	JOIN
		PortfolioProject..CovidVaccinations vac
		ON
			dea.location = vac.location
			AND dea.date = vac.date
	WHERE
		dea.continent IS NOT NULL
	)
Select
	*,
	(RollingVaccinationsPerCountry/Population)*100 AS PercentVaccinated
FROM
	PopVsVac

-- Using Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
NewVaccinations float,
RollingVaccinated float
) 

INSERT INTO #PercentPopulationVaccinated
	SELECT
		dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS float)) 
			OVER 
			(PARTITION BY						-- to separate values by countries
				dea.location
			ORDER BY							-- to separate values when new_vaccinations are added by date
				dea.location, dea.date
			) AS RollingVaccinationsPerCountry
	FROM
		PortfolioProject..CovidDeaths dea
	JOIN
		PortfolioProject..CovidVaccinations vac
		ON
			dea.location = vac.location
			AND dea.date = vac.date
	WHERE
		dea.continent IS NOT NULL

Select
	*,
	(RollingVaccinated/Population)*100 AS PercentVaccinated
FROM
	#PercentPopulationVaccinated
ORDER BY
	Location, Date

-- Global Vaccination Rate
SELECT
	--date, maxCasesDate, maxDeathsDate, (maxDeathsDate/maxCasesDate)*100 AS GlobalDeathRate,
	date, 
	population, 
	--vac.total_vaccinations,
	maxVaccinated, (maxVaccinated/population)*100 AS GlobalVaccinationRate
FROM
	(SELECT
		dea.date, MAX(CAST(vac.total_vaccinations AS float)) AS maxVaccinated, population
	FROM
		PortfolioProject..CovidDeaths dea
	JOIN
		PortfolioProject..CovidVaccinations vac
		ON
			dea.location = vac.location
			AND dea.date = vac.date
	WHERE 
		dea.continent is NULL			
		AND dea.location like 'World'
		AND vac.total_vaccinations is NOT NULL
	GROUP BY
		dea.date,
		dea.population
		) t
ORDER BY
	date
--		REFLECTS DATA BUT RESULTS ARE WRONG, VACCINATED > POPULATION

-- Sample Selection/Information from both tables
SELECT 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.total_vaccinations
FROM
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
	ON
		dea.location = vac.location
		AND dea.date = vac.date
WHERE
	dea.continent is NULL			
	AND dea.location like 'World'
	AND vac.total_vaccinations is NOT NULL
ORDER BY
	date

-- Creating Views to store data for later

DROP VIEW IF EXISTS PercentVaccinatedPopulation
GO

-- Views for CountryVaccinationRate
CREATE VIEW CountryVaccinationRate AS 
	SELECT
		dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS float)) 
			OVER 
			(PARTITION BY						-- to separate values by countries
				dea.location
			ORDER BY							-- to separate values when new_vaccinations are added by date
				dea.location, dea.date
			) AS RollingVaccinationsPerCountry
	FROM
		PortfolioProject..CovidDeaths dea
	JOIN
		PortfolioProject..CovidVaccinations vac
		ON
			dea.location = vac.location
			AND dea.date = vac.date
	WHERE
		dea.continent IS NOT NULL
GO
	
SELECT
	*
FROM
	PercentVaccinatedPopulation

-- Views for Global Death Rate
CREATE VIEW GlobalDeathRate AS
	SELECT
		date, maxCasesDate, maxDeathsDate, (maxDeathsDate/maxCasesDate)*100 AS GlobalDeathRate
	FROM
		(SELECT
			date, MAX(total_cases) AS maxCasesDate, MAX(total_deaths) AS maxDeathsDate
		FROM
			PortfolioProject..CovidDeaths
		WHERE 
			continent is NULL			
			AND location like 'World'
			AND total_cases is NOT NULL
			AND total_deaths is NOT NULL
		GROUP BY
			date
			) t
GO
--Sample:
SELECT 
	*
FROM
	GlobalDeathRate

DROP VIEW IF EXISTS GlobalDeathCount
GO

-- View for global death rise
CREATE VIEW GlobalDeathCount AS
	SELECT
		date, MAX(total_cases) AS maxCasesToDate, MAX(total_deaths) AS Deaths
	FROM
		PortfolioProject..CovidDeaths
	WHERE 
		continent is NULL			
		AND location like 'World'
		AND total_cases is NOT NULL
		AND total_deaths is NOT NULL
	GROUP BY
		date
GO

-- View for death rate per country
CREATE VIEW CountryDeathRate AS
	SELECT
		location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS CountryDeathRate
	FROM
		PortfolioProject..CovidDeaths
	WHERE 
		continent is NOT NULL			-- to isolate aggregated data from Asia, Europe, World, etc.
		AND total_deaths IS NOT NULL

DROP VIEW IF EXISTS CountryInfectionRate
GO

-- View for country infection rate
CREATE VIEW CountryInfectionRate AS
	SELECT
		location, date, total_cases, population, (total_cases / population)*100 AS CountryInfectionRate
	FROM
		PortfolioProject..CovidDeaths
	WHERE 
		continent is NOT NULL			-- to isolate aggregated data from Asia, Europe, World, etc.
		AND total_cases IS NOT NULL
GO


-- View for ranking of countries with the highest death count per population
CREATE VIEW CountryDeathCount AS
	SELECT
		location, MAX(total_deaths) AS totalDeathCountCountries
	FROM
		PortfolioProject..CovidDeaths
	WHERE 
		continent is NOT NULL			-- to isolate aggregated data from Asia, Europe, World, etc.
	GROUP BY
		location, population
GO

DROP VIEW IF EXISTS GlobalInfectionCount
GO

-- View for global infections rise
CREATE VIEW GlobalInfectionCount AS
	SELECT
		date, MAX(total_cases) AS CasesCount
	FROM
		PortfolioProject..CovidDeaths
	WHERE 
		continent is NULL			
		AND location like 'World'
		AND total_cases is NOT NULL
	GROUP BY
		date