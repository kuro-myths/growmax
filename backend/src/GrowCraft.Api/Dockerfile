# GrowCraft 3D — API image (multi-stage)
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/GrowCraft.Domain/GrowCraft.Domain.csproj src/GrowCraft.Domain/
COPY src/GrowCraft.Infrastructure/GrowCraft.Infrastructure.csproj src/GrowCraft.Infrastructure/
COPY src/GrowCraft.Api/GrowCraft.Api.csproj src/GrowCraft.Api/
RUN dotnet restore src/GrowCraft.Api/GrowCraft.Api.csproj

COPY src/ src/
RUN dotnet publish src/GrowCraft.Api/GrowCraft.Api.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app .
EXPOSE 8080
ENTRYPOINT ["dotnet", "GrowCraft.Api.dll"]
