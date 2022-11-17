#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build

ARG assemblyInformationalVersion=1.0.0

WORKDIR /src
COPY ["nuget.config", "."]
COPY ["src/ShoppingApp.SiloHost/ShoppingApp.SiloHost.csproj", "src/ShoppingApp.SiloHost/"]
COPY ["src/ShoppingApp.Grains/ShoppingApp.Grains.csproj", "src/ShoppingApp.Grains/"]
COPY ["src/ShoppingApp.Abstractions/ShoppingApp.Abstractions.csproj", "src/ShoppingApp.Abstractions/"]
RUN dotnet restore "src/ShoppingApp.SiloHost/ShoppingApp.SiloHost.csproj"
COPY . .
WORKDIR "/src/src/ShoppingApp.SiloHost"
RUN dotnet build "ShoppingApp.SiloHost.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "ShoppingApp.SiloHost.csproj" -c Release -o /app/publish /p:UseAppHost=false /p:AssemblyInformationalVersion=$assemblyInformationalVersion

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ShoppingApp.SiloHost.dll"]