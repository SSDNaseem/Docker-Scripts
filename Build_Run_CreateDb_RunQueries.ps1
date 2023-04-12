# Build the project
dotnet build RabbitMQProductAPI.csproj -c Release


# Create the Docker image
docker build -t my-project-image .

# Run the Docker container
docker run -d -p 8080:80 -p 8443:443 -e "ASPNETCORE_URLS=https://+;http://+" -e "ASPNETCORE_HTTPS_PORT=8443" --name my-project-container my-project-image

# Create the database
docker exec -it my-project-container dotnet ef database update

# Run queries
docker exec -it my-project-container dotnet ef dbcontext info
docker exec -it my-project-container dotnet ef migrations list
