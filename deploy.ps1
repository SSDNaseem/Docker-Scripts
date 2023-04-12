# Set the working directory to the project root
Set-Location "F:\RabbitMQImplementation"

# Load the state from the file, if it exists
if (Test-Path config.json) {
    $state = Get-Content state.json | ConvertFrom-Json
} else {
    $state = @{ database = "MyDatabase"; table = "MyTable"; data = @() }
}

# Build the .NET Core project
if ($state.lastSuccessfulCommand -le "build") {
    dotnet build .\RabbitMQProductAPI\RabbitMQProductAPI.csproj
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build the project."
        exit 1
    }
    $state.lastSuccessfulCommand = "build1"
}


# Build the .NET Core project
if ($state.lastSuccessfulCommand -le "build1") {
    dotnet build RabbitMQProductAPI.csproj 
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build the project."
        exit 1
    }
    $state.lastSuccessfulCommand = "build2"
}

# Build Docker
if ($state.lastSuccessfulCommand -le "docker build") {
    docker-compose -f .\docker-compose.yml -f .\docker-compose.override.yml up portainer  -d --build
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create the Docker image."
        exit 1
    }
    $state.lastSuccessfulCommand = "docker build"
}

# Create a Docker container
if ($state.lastSuccessfulCommand -le "docker run") {
    docker run -d -p 8080:80 --name mycontainer myimage
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create the Docker container."
        exit 1
    }
    $state.lastSuccessfulCommand = "docker run"
}

# Wait for the container to start
Start-Sleep -s 10

# Create a database
if ($state.lastSuccessfulCommand -le "create database") {
    $sqlFile = "create_table.sql"
    Set-Content -Path $sqlFile -Value "CREATE DATABASE $($state.database);"
    sqlcmd -S (LocalDB)\MSSQLLocalDb -U $state.data.name -P 123 -Q "CREATE DATABASE $state.database"
    # docker cp $sqlFile mycontainer:/create-database.sql
    # docker exec mycontainer /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Password123 -i /create-database.sql
    Remove-Item $sqlFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create the database."
        exit 1
    }
    $state.lastSuccessfulCommand = "create database"
}

# Create a table
if ($state.lastSuccessfulCommand -le "create table") {
    sqlcmd -S (LocalDB)\MSSQLLocalDb -U $state.data.name  -P 123 -d sampleDb -i create_table.sql

    # docker exec mycontainer /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Password123 -d $($state.database) -Q "CREATE TABLE $($state.table) (Id INT, Name VARCHAR(50))"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create the table."
        exit 1
    }
    $state.lastSuccessfulCommand = "create table"
}

# Insert data into the table
if ($state.lastSuccessfulCommand -le "insert data") {
    sqlcmd -S (LocalDB)\MSSQLLocalDb -U $state.data.name  -P 123 -d sampleDb -i insert_data.sql

    # foreach ($row in $state.data) {
    #     $id = $row.id
    #     $name = $row.name
    #     docker exec mycontainer /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Password123 -d $($state.database) -Q "INSERT INTO $($state.table) (Id, Name) VALUES ($id, '$name')"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to insert data into the table."
            exit 1
        }
    }
    $state.lastSuccessfulCommand = "insert data"


# Save the state to a file
$state | ConvertTo-
