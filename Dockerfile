FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# First, find and copy the csproj file
COPY . .
RUN find . -name "*.csproj" -type f

# Build from the directory containing the csproj
RUN dotnet publish -c Release -o /app/out $(find . -name "*.csproj" | head -1)

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/out .
EXPOSE 5001
ENV ASPNETCORE_URLS=http://+:5001
ENTRYPOINT ["dotnet", "TodoApi.dll"]