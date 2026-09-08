$ErrorActionPreference = "Stop"

function Require-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Comando '$name' nao encontrado. Instale/configure antes de continuar."
    }
}

Require-Command flutter

Write-Host "Flutter encontrado:"
flutter --version

$backup = Join-Path $env:TEMP ("snapgym-foundation-" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $backup | Out-Null

$preserve = @(
    "pubspec.yaml",
    "analysis_options.yaml",
    "README.md",
    ".gitignore",
    ".env.example",
    "lib",
    "test",
    "docs",
    ".github",
    "tool"
)

foreach ($item in $preserve) {
    if (Test-Path $item) {
        Copy-Item $item $backup -Recurse -Force
    }
}

Write-Host "Gerando projeto Android nativo..."
flutter create --platforms=android --org com.snapgym --project-name snapgym .

Write-Host "Restaurando fundacao SnapGym..."
foreach ($item in $preserve) {
    $source = Join-Path $backup $item
    if (Test-Path $source) {
        if (Test-Path $item) {
            Remove-Item $item -Recurse -Force
        }
        Copy-Item $source $item -Recurse -Force
    }
}

Remove-Item $backup -Recurse -Force

Write-Host "Obtendo dependencias..."
flutter pub get

Write-Host "Formatando..."
dart format lib test

Write-Host "Analisando..."
flutter analyze

Write-Host "Executando testes..."
flutter test

Write-Host ""
Write-Host "SnapGym Android foundation pronta."
Write-Host "Execute: flutter run -t lib/main_dev.dart"
