# Stop any running containers
docker stop my-project-container

# Remove any existing containers
docker rm my-project-container

# Remove any existing images
docker rmi my-project-image

# Build the project
dotnet build RabbitMQProductAPI.csproj -c Release

# Create the Docker image
docker build -t 3-management .

# Run the Docker container
docker run -d -p 8080:80 -p 8443:443 -e "ASPNETCORE_URLS=https://+;http://+" -e "ASPNETCORE_HTTPS_PORT=8443" --name rabbitmq 3-management

# Create the database (if needed)
docker exec -it my-project-container dotnet ef database update
